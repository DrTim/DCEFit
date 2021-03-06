//
//  RegisterImage.m
//  DCEFit
//
//  Created by Tim Allman on 2013-06-04.
//
//

#import "RegisterImageOp.h"

#include "RegisterOneImageRigid2D.h"
#include "RegisterOneImageRigid3D.h"
#include "RegisterOneImageBSpline2D.h"
#include "RegisterOneImageBSpline3D.h"
#include "RegisterOneImageDemons2D.h"
#include "RegisterOneImageDemons3D.h"

#import "SeriesInfo.h"

#import <Log4m/Logger.h>
#import <Log4m/LoggingMacros.h>

// used in register2dSeries
//static Image2D::Pointer reduceTo2D(Image3D::Pointer image3d);

@implementation RegisterImageOp

- (id)initWithManager:(RegistrationManager *)regManager
   ProgressController:(ProgressWindowController *)controller
{
    self = [super init];

    if (self)
    {
        NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                                stringByAppendingString:@".RegisterImageOp"];
        logger_ = [[Logger newInstance:loggerName] retain];

        finished_ = NO;
        executing_ = NO;
        waitingForAnswer_ = NO;

        manager = regManager;
        progController = controller;
        params = manager.itkParams;
    }

    return self;
}

- (void)dealloc
{
    [logger_ release];
    [super dealloc];
}

- (void)cancel
{
    [super cancel];
}

- (BOOL)isFinished
{
    return finished_;
}

- (BOOL)isExecuting
{
    return executing_;
}

- (BOOL)isConcurrent
{
    return [super isConcurrent];
}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    executing_ = YES;
    [self didChangeValueForKey:@"isExecuting"];

    if (manager.seriesInfo.slicesPerImage == 1)
    {
        [self register2dSeries];
    }
    else
    {
        [self register3dSeries];
    }

    [self willChangeValueForKey:@"isFinished"];
    finished_ = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    executing_ = NO;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)queryContinue
{
    waitingForAnswer_ = YES;

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Continue"];
    [alert setMessageText:@"Cancel or continue registration?"];
    [alert setInformativeText:@"There was a severe error during registration of this slice."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:progController.window modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
        [self cancel];
    
    waitingForAnswer_ = NO;
}

- (void)register2dSeries
{
    unsigned numImages = params->numImages;
    ResultCode resultCode = SUCCESS;
    waitingForAnswer_ = NO;

    [progController performSelectorOnMainThread:@selector(setNumImages:)
                                     withObject:[NSNumber numberWithUnsignedInt:numImages]
                                  waitUntilDone:NO];

    // Extract the slice to be used as the fixed image
    unsigned fixedImageIdx = params->fixedImageNumber - 1;
    const Image2D::Pointer fixedImage = [manager slice:0 FromImage:fixedImageIdx];

    // We iterate over the image number that the user sees.
    for (unsigned imageNum = 1; imageNum <= numImages; ++imageNum)
    {
        resultCode = SUCCESS;
        unsigned imageIdx = imageNum - 1;

        // Set progress window to current slice.
        [progController performSelectorOnMainThread:@selector(setCurImage:)
                                         withObject:[NSNumber numberWithUnsignedInt:imageNum]
                                      waitUntilDone:YES];

        // No need to register the fixed image
        if (imageIdx == fixedImageIdx)
        {
            NSString* msg = [NSString stringWithFormat:@"Skipping fixed image %u.", imageNum];
            [progController performSelectorOnMainThread:@selector(setStopCondition:)
                                             withObject:msg
                                          waitUntilDone:YES];
            LOG4M_INFO(logger_, @"Skipping fixed image: %u (index = %u)", imageNum, imageIdx);
            [manager insertSliceIntoViewer:fixedImage ImageIndex:imageIdx SliceIndex:0];
            continue;
        }
        else
        {
            NSString* msg = [NSString stringWithFormat:@"Registering image %u.", imageNum];
            [progController performSelectorOnMainThread:@selector(setStopCondition:)
                                             withObject:msg
                                          waitUntilDone:YES];
            LOG4M_INFO(logger_, @"Registering image %u (index = %u)", imageNum, imageIdx);
        }

        if ([self isCancelled])
            break;

        // Pull the image from the 4D series.
        Image2D::Pointer movingImage = [manager slice:0 FromImage:imageIdx];

        // Do this so that the deformable registration will get the moving
        // image even if rigid registration is disabled.
        Image2D::Pointer regImage = movingImage;

        if (params->isRigidRegEnabled())
        {
            RegisterOneImageRigid2D rigidReg(progController, fixedImage, *params);
            regImage = rigidReg.registerImage(movingImage, resultCode);
        }

        if (resultCode == DISASTER)
        {
            [self performSelectorOnMainThread:@selector(queryContinue) withObject:nil waitUntilDone:NO];
            while (waitingForAnswer_)
                sleep(1);
        }

        if ([self isCancelled])
            break;

        if (params->isBSplineRegEnabled())
        {
            RegisterOneImageBSpline2D bsplineReg(progController, fixedImage, *params);
            regImage = bsplineReg.registerImage(regImage, resultCode);
        }
        else if (params->isDemonsRegEnabled())
        {
            RegisterOneImageDemons2D demonsReg(progController, fixedImage, *params);
            regImage = demonsReg.registerImage(regImage, resultCode);
        }

        if (resultCode == DISASTER)
        {
            [self queryContinue];
            [self performSelectorOnMainThread:@selector(queryContinue) withObject:nil waitUntilDone:NO];

            while (waitingForAnswer_)
                sleep(1);
        }

        if ([self isCancelled])
            break;

        [manager insertSliceIntoViewer:regImage ImageIndex:imageIdx SliceIndex:0];
    }
}

- (void)register3dSeries
{
    unsigned numImages = params->numImages;
    ResultCode resultCode = SUCCESS;
    waitingForAnswer_ = NO;

    [progController performSelectorOnMainThread:@selector(setNumImages:)
                                     withObject:[NSNumber numberWithUnsignedInt:numImages]
                                  waitUntilDone:NO];

    // Extract the slice to be used as the fixed image
    unsigned fixedImageIdx = params->fixedImageNumber - 1;
    const Image3D::Pointer fixedImage = [manager imageAtIndex:fixedImageIdx];

    // We iterate over the image number that the user sees.
    for (unsigned imageNum = 1; imageNum <= numImages; ++imageNum)
    {
        resultCode = SUCCESS;
        unsigned imageIdx = imageNum - 1;

        // Set progress window to current slice.
        [progController performSelectorOnMainThread:@selector(setCurImage:)
                                         withObject:[NSNumber numberWithUnsignedInt:imageNum]
                                      waitUntilDone:YES];

        // No need to register the fixed image
        if (imageIdx == fixedImageIdx)
        {
            NSString* msg = [NSString stringWithFormat:@"Skipping fixed image %u.", imageNum];
            [progController performSelectorOnMainThread:@selector(setStopCondition:)
                                             withObject:msg
                                          waitUntilDone:YES];
            LOG4M_INFO(logger_, @"Skipping fixed image: %u (index = %u)", imageNum, imageIdx);
            continue;
        }
        else
        {
            NSString* msg = [NSString stringWithFormat:@"Registering image %u.", imageNum];
            [progController performSelectorOnMainThread:@selector(setStopCondition:)
                                             withObject:msg
                                          waitUntilDone:YES];
            LOG4M_INFO(logger_, @"Registering image %u (index = %u)", imageNum, imageIdx);
        }

        if ([self isCancelled])
            break;

        // Pull the 3D volume from the time series.
        Image3D::Pointer movingImage = [manager imageAtIndex:imageIdx];

        // Do this so that the deformable registration will get the moving
        // image even if rigid registration is disabled.
        Image3D::Pointer regImage = movingImage;

        if (params->isRigidRegEnabled())
        {
            RegisterOneImageRigid3D rigidReg(progController, fixedImage, *params);
            regImage = rigidReg.registerImage(movingImage, resultCode);
        }

        if (resultCode == DISASTER)
        {
            [self performSelectorOnMainThread:@selector(queryContinue) withObject:nil waitUntilDone:YES];
            while (waitingForAnswer_)
                sleep(1);
        }

        if ([self isCancelled])
            break;

        if (params->isBSplineRegEnabled())
        {
            RegisterOneImageBSpline3D bsplineReg(progController, fixedImage, *params);
            regImage = bsplineReg.registerImage(regImage, resultCode);
        }
        else if (params->isDemonsRegEnabled())
        {
            RegisterOneImageDemons3D demonsReg(progController, fixedImage, *params);
            regImage = demonsReg.registerImage(regImage, resultCode);
        }

        if (resultCode == DISASTER)
        {
            [self performSelectorOnMainThread:@selector(queryContinue) withObject:nil waitUntilDone:NO];
            while (waitingForAnswer_)
                sleep(1);

            while (waitingForAnswer_)
                sleep(1);
        }

        if ([self isCancelled])
            break;

        [manager insertImageIntoViewer:regImage Index:imageIdx];
    }

    [self willChangeValueForKey:@"isFinished"];
    finished_ = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    executing_ = NO;
    [self didChangeValueForKey:@"isExecuting"];
}

@end

