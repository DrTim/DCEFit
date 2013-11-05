//
//  RegisterImage.m
//  DCEFit
//
//  Created by Tim Allman on 2013-06-04.
//
//

#import "RegisterImageOp.h"

#include "RegisterOneImageMultiResRigid2D.h"
#include "RegisterOneImageMultiResDeformable2D.h"
#include "itkImageRegionIteratorWithIndex.h"
#include "itkImageRegionConstIteratorWithIndex.h"

#import <Log4m/Logger.h>
#import <Log4m/LoggingMacros.h>

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
        image = [manager getImage];
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

    unsigned numImages = params->numImages;
    RegisterOneImage2D::ResultCode resultCode = RegisterOneImage2D::SUCCESS;
    waitingForAnswer_ = NO;
    
    // Extract the slice to be used as the fixed image
    unsigned fixedImageIdx = params->imageNumberToIndex(params->fixedImageNumber);
    const Image2DType::Pointer fixedImage = [manager getSliceFromImage:fixedImageIdx];

   // We iterate over the image number that the user sees.
    for (unsigned imageNum = 1; imageNum <= numImages; ++imageNum)
    {
        resultCode = RegisterOneImage2D::SUCCESS;
        unsigned index = params->imageNumberToIndex(imageNum);

        // Set progress window to current slice.
        [progController performSelectorOnMainThread:@selector(setCurSlice:)
                                         withObject:[NSNumber numberWithUnsignedInt:imageNum]
                                      waitUntilDone:YES];

        // No need to register the fixed image
        if (index == fixedImageIdx)
        {
            NSString* msg = [NSString stringWithFormat:@"Skipping fixed slice %u.", imageNum];
            [progController performSelectorOnMainThread:@selector(setStopCondition:)
                                             withObject:msg
                                          waitUntilDone:YES];
            LOG4M_INFO(logger_, @"Skipping fixed image: %u (index = %u)", imageNum, index);
            continue;
        }
        else
        {
            NSString* msg = [NSString stringWithFormat:@"Registering slice %u.", imageNum];
            [progController performSelectorOnMainThread:@selector(setStopCondition:)
                                             withObject:msg
                                          waitUntilDone:YES];
            LOG4M_INFO(logger_, @"Registering image %u (index = %u)", imageNum, index);
        }
        
        if ([self isCancelled])
            break;

        // Pull the 2D slice from the 3D volume.
        Image2DType::Pointer movingImage = [manager getSliceFromImage:index];

        // Do this so that the deformable registration will get the moving
        // image even if rigid registration is disabled.
        Image2DType::Pointer regImage = movingImage;

        if (params->rigidRegEnabled)
        {
            RegisterOneImageMultiResRigid2D rigidReg(progController, fixedImage, *params);
            regImage = rigidReg.registerImage(movingImage, resultCode);
        }

        if (resultCode == RegisterOneImage2D::DISASTER)
        {
            [self performSelectorOnMainThread:@selector(queryContinue) withObject:nil waitUntilDone:YES];
            while (waitingForAnswer_)
                sleep(1);
        }

        if ([self isCancelled])
            break;

        if (params->deformRegEnabled)
        {
            RegisterOneImageMultiResDeformable2D deformReg(progController, fixedImage, *params);
            regImage = deformReg.registerImage(regImage, resultCode);
        }

        if (resultCode == RegisterOneImage2D::DISASTER)
        {
            [self queryContinue];
            while (waitingForAnswer_)
                sleep(1);
        }

        if ([self isCancelled])
            break;


        @synchronized(self)
        {
            [manager insertSliceIntoViewer:regImage SliceIndex:index];
        }
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

@end
