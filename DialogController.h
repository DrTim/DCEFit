//
//  DialogController.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-18.
//
//

#import <Foundation/Foundation.h>

@class SeriesInfo;
@class Logger;
@class RegistrationParams;
@class RegistrationManager;
@class ProgressWindowController;
@class LBFGSBConfigWindowController;
@class DCEFitFilter;
@class DCMObject;
@class ViewerController;  // OsiriX 2D viewer
@class DicomSeries;

@interface DialogController : NSWindowController
    <NSWindowDelegate, NSTabViewDelegate, NSTextFieldDelegate,
     NSTableViewDelegate, NSTableViewDataSource,
     NSComboBoxDataSource, NSComboBoxDelegate>
{
    Logger* logger_;

    NSWindow* openSheet_; // scratch variable for sheet management

    DCEFitFilter* parentFilter;

    IBOutlet RegistrationParams *regParams;

    ProgressWindowController* progressWindowController;
    ViewerController* viewerController1;      // original viewer
    ViewerController* viewerController2;      // copy for registered image

    RegistrationManager* registrationManager; // The object which does the registration
    SeriesInfo* seriesInfo;

    // Main dialog
    //
    // Top box
    IBOutlet NSTextField *seriesDescriptionTextField;
    IBOutlet NSComboBox *fixedImageComboBox;

    // Rigid registration box
    IBOutlet NSButton *rigidRegEnableCheckBox;
    IBOutlet NSComboBox *rigidRegLevelsComboBox;
    IBOutlet NSTextField *rigidRegOptimizerLabel;
    IBOutlet NSButton *rigidRegOptimizerConfigButton;
    IBOutlet NSMatrix *rigidRegMetricRadioMatrix;
    IBOutlet NSButton *rigidRegMetricConfigButton;

    // Deformable registration box
    IBOutlet NSButton *deformRegEnableCheckBox;
    IBOutlet NSButton *deformShowFieldCheckBox;
    IBOutlet NSComboBox *deformRegLevelsComboBox;
    IBOutlet NSMatrix *deformRegOptimizerRadioMatrix;
    IBOutlet NSButton *deformRegOptimizerConfigButton;
    IBOutlet NSMatrix *deformRegMetricRadioMatrix;
    IBOutlet NSButton *deformRegMetricConfigButton;
    IBOutlet NSTableView *deformRegGridSizeTableView;

    // Bottom box buttons
    IBOutlet NSButton *regCloseButton;
    IBOutlet NSComboBox *loggingLevelComboBox;
    IBOutlet NSComboBox *numberOfThreadsComboBox;
    NSButton *useDefaultNumberOfThreadsCheckBox;
    IBOutlet NSButton *regStartButton;

    // Optimizer and metric configuration sheets
    IBOutlet NSPanel *rigidRegLBFGSBOptimizerConfigPanel;
    IBOutlet NSPanel *rigidRegLBFGSOptimizerConfigPanel;
    IBOutlet NSPanel *rigidRegRSGDOptimizerConfigPanel;
    IBOutlet NSPanel *rigidVersorOptimizerConfigPanel;
    IBOutlet NSPanel *rigidRegMMIMetricConfigPanel;
    IBOutlet NSPanel *deformRegLBFGSBOptimizerConfigPanel;
    IBOutlet NSPanel *deformRegLBFGSOptimizerConfigPanel;
    IBOutlet NSPanel *deformRegRSGDOptimizerConfigPanel;
    IBOutlet NSPanel *deformRegMMIMetricConfigPanel;

    // Tables in the configuration sheets
    IBOutlet NSTableView *rigidRegLBFGSBOptimizerTableView;
    IBOutlet NSTableView *rigidRegLBFGSOptimizerTableView;
    IBOutlet NSTableView *rigidRegRSGDOptOptimizerTableView;
    IBOutlet NSTableView *rigidRegVersorOptimizerTableView;
    IBOutlet NSTableView *rigidRegMMIMetricTableView;
    IBOutlet NSTableView *deformRegLBFGSBOptimizerTableView;
    IBOutlet NSTableView *deformRegLBFGSOptimizerTableView;
    IBOutlet NSTableView *deformRegRSGDOptimizerTableView;
    IBOutlet NSTableView *deformRegMMIMetricTableView;
}

// properties associated with non-outlet members
@property (assign) DCEFitFilter* parentFilter;
@property (assign) ViewerController* viewerController1;
@property (assign) ViewerController* viewerController2;
@property (assign) ProgressWindowController* progressWindowController;
@property (readonly) RegistrationParams* regParams;
@property (assign) SeriesInfo* seriesInfo;

// properties associated with outlet members
@property (assign) IBOutlet NSComboBox *fixedImageComboBox;
@property (assign) IBOutlet NSTextField *seriesDescriptionTextField;

@property (assign) IBOutlet NSButton *rigidRegEnableCheckBox;
@property (assign) IBOutlet NSComboBox *rigidRegLevelsComboBox;
@property (assign) IBOutlet NSTextField* rigidRegOptimizerLabel;
@property (assign) IBOutlet NSMatrix *rigidRegMetricRadioMatrix;

@property (assign) IBOutlet NSButton *deformRegEnableCheckBox;
@property (assign) IBOutlet NSComboBox *deformRegLevelsComboBox;
@property (assign) IBOutlet NSTableView *deformRegGridSizeTableView;

@property (assign) IBOutlet NSMatrix *deformRegMetricRadioMatrix;
@property (assign) IBOutlet NSMatrix *deformRegOptimizerRadioMatrix;
@property (assign) IBOutlet NSButton *deformShowFieldCheckBox;

@property (assign) IBOutlet NSButton *regStartButton;
@property (assign) IBOutlet NSButton *regCloseButton;

// Program defaults
@property (assign) IBOutlet NSComboBox *loggingLevelComboBox;
@property (assign) IBOutlet NSComboBox *numberOfThreadsComboBox;
@property (assign) IBOutlet NSButton *useDefaultNumberOfThreadsCheckBox;

// Actions
//
// Main dialog
- (IBAction)rigidRegEnableChanged:(NSButton *)sender;
- (IBAction)rigidRegMetricChanged:(NSMatrix *)sender;
- (IBAction)rigidRegOptimizerConfigButtonPressed:(NSButton *)sender;
- (IBAction)rigidRegMetricConfigButtonPressed:(NSButton *)sender;
- (IBAction)deformRegEnableChanged:(NSButton *)sender;
- (IBAction)deformRegMetricChanged:(NSMatrix *)sender;
- (IBAction)deformRegOptimizerConfigButtonPressed:(NSButton *)sender;
- (IBAction)deformRegMetricConfigButtonPressed:(NSButton *)sender;

- (IBAction)regStartButtonPressed:(NSButton *)sender;
- (IBAction)regCloseButtonPressed:(NSButton *)sender;

// Configuration sheets
//
// Close buttons
- (IBAction)rigidRegLBFGSBConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)rigidRegLBFGSConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)rigidRegRSGDConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)rigidRegVersorConfigCloseButtonPressed:(NSButton*)sender;
- (IBAction)rigidRegMMIMetricCloseButtonPressed:(NSButton *)sender;

- (IBAction)deformRegLBFGSBConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)deformRegLBFGSConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)deformRegRSGDConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)deformRegMMIConfigCloseButtonPressed:(NSButton *)sender;

// Class methods
/**
 * Initialise with the OsiriX 2D viewer controller
 * @param viewerController The OsiriX 2D viewer object
 * @param filter The class derived from OsiriX's PluginFilter.
 * @return The instance (self).
 */
- (id)initWithViewerController:(ViewerController*)viewerController
                        Filter:(DCEFitFilter*)filter;

- (void)registrationEnded:(BOOL)saveData;

// NSTabViewDelegate methods
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

// NSTextFieldDelegate methods
//
// Posts a notification that the text is about to begin editing
// to the default notification center.
- (void)textDidBeginEditing:(NSNotification*)aNotification;

// Posts a notification that the text has changed and forwards
// this message to the receiver’s cell if it responds.
- (void)textDidChange:(NSNotification*)aNotification;

// Handles an end of editing.
- (void)textDidEndEditing:(NSNotification*)aNotification;

// NSTableDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row;

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

// NSComboboxDelegate methods
- (void)comboBoxSelectionDidChange:(NSNotification *)notification;

// NSComboboxDatasource methods
- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index;

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox;

@end
