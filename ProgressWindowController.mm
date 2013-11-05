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

#include "RegistrationObserver.h"

#include <Log4m/LoggingMacros.h>

const NSString* RegistrationStageRigid = @"Rigid";
const NSString* RegistrationStageDeformable = @"Deformable";
NSString* StopRegistrationNotification = @"StopRegistrationNotification";


@implementation ProgressWindowController

@synthesize progressIndicator;
@synthesize sliceTextField;
@synthesize stageTextField;
@synthesize levelTextField;
@synthesize iterationTextField;
@synthesize metricTextField;
@synthesize stepSizeTextField;
@synthesize stepSizeLabel;
@synthesize maxIterLabel;
@synthesize stopButton;
@synthesize saveButton;
@synthesize quitButton;
@synthesize stopConditionTextView;
@synthesize progressValues;
@synthesize observer;

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
    [sliceTextField setIntegerValue:1];
    [stageTextField setStringValue:(NSString*)RegistrationStageRigid];
    [levelTextField setIntegerValue:1];
    [iterationTextField setIntegerValue:0];
    [metricTextField setDoubleValue:0.0];
    [statusTextField setStringValue:@"Performing registration."];
    [stopButton setEnabled:YES];
    [saveButton setEnabled:NO];
    [quitButton setEnabled:NO];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(registrationCancelled)
//                                                 name:StopRegistrationNotification
//                                               object:nil];
}

- (void)setCurSlice:(NSNumber*)slice
{
    progressValues.curSlice = [slice unsignedIntValue];
    [sliceTextField setIntegerValue:progressValues.curSlice];
    [progressIndicator setDoubleValue:(double)progressValues.curSlice];
}

- (void)incrCurSlice
{
    ++progressValues.curSlice;
    [sliceTextField setIntegerValue:progressValues.curSlice];
    [progressIndicator setDoubleValue:(double)progressValues.curSlice];
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
        if (optType == RSGD)
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

- (void)setMaxIterations:(NSNumber*)iterations
{
    progressValues.maxIterations = [iterations unsignedIntValue];
    [maxIterLabel setIntegerValue:progressValues.maxIterations];
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
        observer->StopRegistration();
        [regManager cancelRegistration];
        [statusTextField setStringValue:@"Waiting for termination."];
        registrationCancelled = YES;
        [stopButton setEnabled:NO];
    }
}

- (IBAction)saveButtonPressed:(NSButton*)sender
{
    // Close after registration is done and save results
    [parentController_ registrationEnded:YES];
    [self close];
    [self autorelease];
}

- (IBAction)quitButtonPressed:(NSButton*)sender
{
    // Close after registration is done but do not save results
    [parentController_ registrationEnded:NO];
    [self close];
    [self autorelease];
}

- (void)registrationEnded
{
    LOG4M_TRACE(logger_, @"Enter");

    if (registrationCancelled)
        [statusTextField setStringValue:@"Terminated by user."];
    else
        [statusTextField setStringValue:@"Registration finished normally."];

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

- (void)windowWillClose:(NSNotification *)notification
{
	LOG4M_TRACE(logger_, @"%@", [notification name]);
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	//[self autorelease];
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

//- (void)registrationCancelled
//{
//	LOG4M_TRACE(logger_, @"Enter");
//    [self.window close];
//	[self autorelease];
//}

@end
