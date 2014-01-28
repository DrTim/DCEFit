//
//  ProgressWindowController.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#if __OBJC__

#import <Foundation/Foundation.h>

@class DialogController;
@class RegProgressValues;
@class RegistrationManager;
@class Logger;

extern const NSString* RegistrationStageRigid;
extern const NSString* RegistrationStageDeformable;
extern NSString* StopRegistrationNotification;

@interface ProgressWindowController : NSWindowController <NSWindowDelegate>
{
    Logger* logger_;
    void* observer_;
    unsigned observerDims_;

    BOOL registrationCancelled;
    BOOL registrationFinished;
    IBOutlet RegProgressValues *progressValues;
    DialogController* parentController_;
    RegistrationManager* regManager;

    NSProgressIndicator *progressIndicator;
    NSTextField *imageTextField;
    NSTextField *stageTextField;
    NSTextField *levelTextField;
    NSTextField *iterationTextField;
    NSTextField *metricTextField;
    NSTextField *stepSizeTextField;
    NSTextField *stepSizeLabel;
    NSTextField *maxIterLabel;
    NSButton *stopButton;
    NSButton *saveButton;
    NSButton *quitButton;
    NSTextView *stopConditionTextView;

    NSTextField *statusTextField;
}

@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *imageTextField;
@property (assign) IBOutlet NSTextField *stageTextField;
@property (assign) IBOutlet NSTextField *levelTextField;
@property (assign) IBOutlet NSTextField *iterationTextField;
@property (assign) IBOutlet NSTextField *metricTextField;
@property (assign) IBOutlet NSTextField *stepSizeTextField;
@property (assign) IBOutlet NSTextField *stepSizeLabel;

@property (assign) IBOutlet NSTextField *maxIterLabel;
@property (assign) IBOutlet NSButton *stopButton;
@property (assign) IBOutlet NSButton *saveButton;
@property (assign) IBOutlet NSButton *quitButton;


@property (assign) IBOutlet NSTextView *stopConditionTextView;

@property (readonly) IBOutlet RegProgressValues* progressValues;

//@property (assign) RegistrationObserver* observer;

- (id)initWithDialogController:(DialogController*)parent;

- (IBAction)stopButtonPressed:(NSButton*)sender;

- (IBAction)saveButtonPressed:(id)sender;

- (IBAction)quitButtonPressed:(NSButton *)sender;

- (void)registrationEnded;

- (void)setProgressMinimum:(double)minVal andMaximum:(double)maxVal;

- (void)setCurImage:(NSNumber*)imageIdx;

- (void)incrCurImage;

- (void)setCurLevel:(NSNumber*)level;

- (void)setCurMetric:(NSNumber*)metric;

- (void)setCurStepSize:(NSNumber*)stepSize;

- (void)setCurStage:(NSString*)stage;

- (void)setCurIteration:(NSNumber*)iteration;

- (void)setMaxIterations:(NSNumber*)iterations;

- (void)setStopCondition:(NSString*)stopCondition;

- (void)setManager:(RegistrationManager*)manager;

- (void)setObserver:(void*)observer;

- (void)stopRegistration;

@end

#else

typedef void ProgressWindowController;

#endif