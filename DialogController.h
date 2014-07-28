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
    // Main tab view
    IBOutlet NSTabView *mainTabView;
    
    // Tab view for the registration parameters
    IBOutlet NSTabView *registrationParametersTabView;

    // Top box
    IBOutlet NSTextField *seriesDescriptionTextField;
    IBOutlet NSComboBox *fixedImageComboBox;
    IBOutlet NSMatrix *registrationSelectionRadioMatrix;

    // Rigid registration tab
    IBOutlet NSComboBox *rigidRegLevelsComboBox;
    IBOutlet NSTextField *rigidRegOptimizerLabel;
    IBOutlet NSButton *rigidRegOptimizerConfigButton;
    IBOutlet NSMatrix *rigidRegMetricRadioMatrix;
    IBOutlet NSButton *rigidRegMetricConfigButton;

    // B-spline deformable registration tab
    //IBOutlet NSButton *bsplineShowFieldCheckBox;
    IBOutlet NSComboBox *bsplineRegLevelsComboBox;
    IBOutlet NSMatrix *bsplineRegOptimizerRadioMatrix;
    IBOutlet NSButton *bsplineRegOptimizerConfigButton;
    IBOutlet NSMatrix *bsplineRegMetricRadioMatrix;
    IBOutlet NSButton *bsplineRegMetricConfigButton;
    IBOutlet NSTableView *bsplineRegGridSizeTableView;

    // Demons deformable registration tab
    IBOutlet NSComboBox *demonsRegLevelsComboBox;
    IBOutlet NSButton *demonsRegOptimizerConfigButton;

    // Bottom box buttons
    IBOutlet NSButton *regCloseButton;
    IBOutlet NSButton *regStartButton;

    //
    IBOutlet NSComboBox *numberOfThreadsComboBox;
    IBOutlet NSComboBox *loggingLevelComboBox;

    // Optimizer and metric configuration sheets
    IBOutlet NSPanel *rigidRegRSGDOptimizerConfigPanel;
    IBOutlet NSPanel *rigidVersorOptimizerConfigPanel;
    IBOutlet NSPanel *rigidRegMMIMetricConfigPanel;
    IBOutlet NSPanel *bsplineRegLBFGSBOptimizerConfigPanel;
    IBOutlet NSPanel *bsplineRegLBFGSOptimizerConfigPanel;
    IBOutlet NSPanel *bsplineRegRSGDOptimizerConfigPanel;
    IBOutlet NSPanel *bsplineRegMMIMetricConfigPanel;
    IBOutlet NSPanel *demonsRegOptimizerConfigPanel;

    // Tables in the configuration sheets
    IBOutlet NSTableView *rigidRegRSGDOptOptimizerTableView;
    IBOutlet NSTableView *rigidRegVersorOptimizerTableView;
    IBOutlet NSTableView *rigidRegMMIMetricTableView;
    IBOutlet NSTableView *bsplineRegLBFGSBOptimizerTableView;
    IBOutlet NSTableView *bsplineRegLBFGSOptimizerTableView;
    IBOutlet NSTableView *bsplineRegRSGDOptimizerTableView;
    IBOutlet NSTableView *bsplineRegMMIMetricTableView;
    IBOutlet NSTableView *demonsRegOptimizerTableView;
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

@property (assign) IBOutlet NSComboBox *rigidRegLevelsComboBox;
@property (assign) IBOutlet NSTextField* rigidRegOptimizerLabel;
@property (assign) IBOutlet NSMatrix *rigidRegMetricRadioMatrix;

@property (assign) IBOutlet NSComboBox *bsplineRegLevelsComboBox;
@property (assign) IBOutlet NSTableView *bsplineRegGridSizeTableView;

@property (assign) IBOutlet NSMatrix *bsplineRegMetricRadioMatrix;
@property (assign) IBOutlet NSMatrix *bsplineRegOptimizerRadioMatrix;
//@property (assign) IBOutlet NSButton *bsplineShowFieldCheckBox;

@property (assign) IBOutlet NSButton *regStartButton;
@property (assign) IBOutlet NSButton *regCloseButton;

// Program defaults
@property (assign) IBOutlet NSComboBox *loggingLevelComboBox;
@property (assign) IBOutlet NSComboBox *numberOfThreadsComboBox;

// Actions
//
// Main dialog

- (IBAction)registrationSelectionRadioMatrixChanged:(NSMatrix *)sender;

- (IBAction)rigidRegMetricChanged:(NSMatrix *)sender;
- (IBAction)rigidRegOptimizerConfigButtonPressed:(NSButton *)sender;
- (IBAction)rigidRegMetricConfigButtonPressed:(NSButton *)sender;

- (IBAction)bsplineRegMetricChanged:(NSMatrix *)sender;
- (IBAction)bsplineRegOptimizerConfigButtonPressed:(NSButton *)sender;
- (IBAction)bsplineRegMetricConfigButtonPressed:(NSButton *)sender;

- (IBAction)demonsRegOptimizerConfigButtonPressed:(NSButton *)sender;

- (IBAction)regStartButtonPressed:(NSButton *)sender;
- (IBAction)regCloseButtonPressed:(NSButton *)sender;

// Configuration sheets
//
// Close buttons
- (IBAction)rigidRegRSGDConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)rigidRegVersorConfigCloseButtonPressed:(NSButton*)sender;
- (IBAction)rigidRegMMIMetricCloseButtonPressed:(NSButton *)sender;

- (IBAction)bsplineRegLBFGSBConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)bsplineRegLBFGSConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)bsplineRegRSGDConfigCloseButtonPressed:(NSButton *)sender;
- (IBAction)bsplineRegMMIConfigCloseButtonPressed:(NSButton *)sender;

- (IBAction)demonsRegOptimizerCloseButtonPressed:(NSButton *)sender;

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
