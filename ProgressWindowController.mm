//
//  ProgressWindowController.m
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#import <CoreFoundation/CoreFoundation.h>

#import "ProgressWindowController.h"
#import "DialogController.h"
#import "RegProgressValues.h"
#import "RegistrationManager.h"

#include "RegistrationObserverBSpline.h"
#include "RegistrationObserverDemons.h"

#include <Log4m/LoggingMacros.h>

const NSString* RegistrationStageRigid = @"Rigid";
const NSString* RegistrationStageDeformable = @"Deformable";

NSString* CloseProgressPanelNotification = @"CloseProgressPanelNotification";


@implementation ProgressWindowController

@synthesize progressIndicator;
@synthesize imageTextField;
@synthesize stageTextField;
@synthesize levelTextField;
@synthesize iterationTextField;
@synthesize metricTextField;
@synthesize metricLabel;
@synthesize stepSizeTextField;
@synthesize stepSizeLabel;
@synthesize numImagesLabel;
@synthesize statusTextField;
@synthesize maxIterLabel;
@synthesize stopButton;
@synthesize saveButton;
@synthesize quitButton;
@synthesize stopConditionTextView;
@synthesize progressValues;

- (id)initWithDialogController:(DialogController *)parent
{
    self = [super initWithWindowNibName:@"ProgressWindow"];
    if (self)
    {
        [self setupLogger];
        LOG4M_TRACE(logger_, @"init");
        parentController_ = parent;
        registrationCancelled = NO;
    }

    return self;
}

- (void)dealloc
{
    [logger_ release];
    [super dealloc];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".ProgressWindowController"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (void)awakeFromNib
{
	LOG4M_TRACE(logger_, @"Enter");

    [progressIndicator setMinValue:0.0];
    [progressIndicator setMaxValue:100.0];
    [progressIndicator setDoubleValue:1];
    [imageTextField setIntegerValue:1];
    [stageTextField setStringValue:(NSString*)RegistrationStageRigid];
    [levelTextField setIntegerValue:1];
    [iterationTextField setIntegerValue:0];
    [metricTextField setDoubleValue:0.0];
    [statusTextField setStringValue:@"Performing registration."];
    [numImagesLabel setIntValue:-1];
    [maxIterLabel setIntValue:-1];
    [stopButton setEnabled:YES];
    [saveButton setEnabled:NO];
    [quitButton setEnabled:NO];
}

- (void)setCurImage:(NSNumber *)imageNum
{
    progressValues.curImage = [imageNum unsignedIntValue];
    [imageTextField setIntegerValue:progressValues.curImage];
    [progressIndicator setDoubleValue:(double)progressValues.curImage];
}

- (void)incrCurImage
{
    ++progressValues.curImage;
    [imageTextField setIntegerValue:progressValues.curImage];
    [progressIndicator setDoubleValue:(double)progressValues.curImage];
}

- (void)setCurLevel:(NSNumber*)level
{
    progressValues.curLevel = [level unsignedIntValue];
    [levelTextField setIntegerValue:progressValues.curLevel];
}

- (void)setCurMetric:(NSNumber*)metric
{
    progressValues.curMetric = [metric doubleValue];
    [metricTextField setFloatValue:progressValues.curMetric];
}

- (void)setCurStepSize:(NSNumber *)stepSize
{
    progressValues.curStepSize = [stepSize doubleValue];
    [stepSizeTextField setFloatValue:progressValues.curStepSize];
}

- (void)setCurStage:(NSString*)stage
{
    progressValues.curStage = stage;
    [stageTextField setStringValue:stage];

    if ([stage isEqualToString:@"Rigid"])
    {
        OptimizerType optType = parentController_.regParams.rigidRegOptimizer;
        if ((optType == RSGD) || (optType == Versor))
        {
            [stepSizeTextField setHidden:NO];
            [stepSizeLabel setHidden:NO];
        }
        else
        {
            [stepSizeTextField setHidden:YES];
            [stepSizeLabel setHidden:YES];
        }
    }
}

- (void)setCurIteration:(NSNumber*)iteration
{
    progressValues.curIteration = [iteration unsignedIntValue];
    [iterationTextField setIntegerValue:progressValues.curIteration];
}

- (void)setObserver:(void*)observer
{
    // observer may be 0 so we catch this first.
    if (observer == 0)
    {
        observer_ = 0;
        return;
    }

    // This is an effort to shoehorn namespaces and templates into Obj-C.
    itk::Command* obs = static_cast<itk::Command*>(observer);
    observer_ = obs;
    observerDims_ = 0;

    if (dynamic_cast<RegistrationObserverBSpline<Image2D>*>(obs) != 0)
        observerDims_ = 2;
    else if (dynamic_cast<RegistrationObserverBSpline<Image3D>*>(obs) != 0)
        observerDims_ = 3;
    else if (dynamic_cast<RegistrationObserverDemons<Image2D, DemonsDisplacementField2D>*>(obs) != 0)
        observerDims_ = 2;
    else if (dynamic_cast<RegistrationObserverDemons<Image3D, DemonsDisplacementField3D>*>(obs) != 0)
        observerDims_ = 3;

    // If none of the above worked, observerDims_ will still be 0
    NSAssert(((observerDims_ == 2) || (observerDims_ == 3)),
        @"Argument 'observer' not an instantiation of RegistrationObserver");
}

- (void)setMaxIterations:(NSNumber*)iterations
{
    progressValues.maxIterations = [iterations unsignedIntValue];
    [maxIterLabel setIntegerValue:progressValues.maxIterations];
}

- (void)setNumImages:(NSNumber *)images
{
    progressValues.numImages = [images unsignedIntValue];
    [numImagesLabel setIntValue:progressValues.numImages];
}

- (void)setStopCondition:(NSString *)stopCondition
{
    NSString* text = [stopConditionTextView string];

    text = [text stringByAppendingFormat:@"%@\n", stopCondition];
    [stopConditionTextView setString:text];
}

- (IBAction)stopButtonPressed:(NSButton*)sender
{
    LOG4M_TRACE(logger_, @"%@", [sender title]);

    NSInteger i = NSRunAlertPanel(@"DCE-Fit", @"Stop registration?", @"Yes", @"No", nil);
    if (i == NSAlertDefaultReturn)
    {
        [self stopRegistration];
    }
}

- (IBAction)saveButtonPressed:(NSButton*)sender
{
    // Close after registration is done and save results
    [parentController_ registrationEnded:YES];
    [self closePanel];
}

- (IBAction)quitButtonPressed:(NSButton*)sender
{
    // Close after registration is done but do not save results
    [parentController_ registrationEnded:NO];
    [self closePanel];
}

- (void)registrationEnded
{
    LOG4M_TRACE(logger_, @"Enter");

    NSString* msg;

    if (registrationCancelled)
        msg = @"Registration cancelled by user.";
    else
        msg = @"Registration finished normally.";

    [statusTextField setStringValue:msg];
    [self setStopCondition:msg];
    registrationFinished = YES;
    [stopButton setEnabled:NO];
    [saveButton setEnabled:YES];
    [quitButton setEnabled:YES];
}

- (BOOL)windowShouldClose:(id)sender
{
	LOG4M_TRACE(logger_, @"%@", [sender description]);
    
    return YES;
}

- (void)closePanel
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CloseProgressPanelNotification object:self];
    [self close];
    [self autorelease];
}

- (void)setProgressMinimum:(double)minVal andMaximum:(double)maxVal
{
	LOG4M_TRACE(logger_, @"Enter");
	LOG4M_DEBUG(logger_, @"minVal = %f, maxVal = %f.", minVal, maxVal);

    [progressIndicator setMinValue:minVal];
    [progressIndicator setMaxValue:maxVal];
}

- (void)setManager:(RegistrationManager *)manager
{
    regManager = manager;
}

- (void)stopRegistration
{
    RegistrationObserverBase* obs = static_cast<RegistrationObserverBase*>(observer_);

    obs->StopRegistration();

    [regManager cancelRegistration];
    [statusTextField setStringValue:@"Waiting for termination."];
    registrationCancelled = YES;
    [stopButton setEnabled:NO];
}

@end
