//
//  DialogController.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-04-18.
//
//

#import "DialogController.h"
#import "DCEFitFilter.h"
#import "ProgressWindowController.h"
#import "RegistrationParams.h"
#import "RegistrationManager.h"
#import "UserDefaults.h"

#import "OsiriXAPI/ViewerController.h"
#import "OsiriXAPI/DCMPix.h"
#import "OsiriXAPI/PluginFilter.h"
#import "OsiriXAPI/DicomSeries.h"

#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMAttributeTag.h"

@implementation DialogController;

@synthesize progressWindowController;
@synthesize regParams;
@synthesize parentFilter;
@synthesize viewerController1;
@synthesize viewerController2;

@synthesize fixedImageComboBox;
@synthesize seriesDescriptionTextField;

@synthesize rigidRegEnableCheckBox;
@synthesize rigidRegLevelsComboBox;
@synthesize rigidRegMetricRadioMatrix;
@synthesize rigidRegOptimizerRadioMatrix;
@synthesize deformRegEnableCheckBox;
@synthesize deformRegLevelsComboBox;
@synthesize deformRegGridSizeTableView;
@synthesize deformRegMetricRadioMatrix;
@synthesize deformRegOptimizerRadioMatrix;
@synthesize deformShowFieldCheckBox;
@synthesize regCloseButton;

@synthesize regStartButton;
@synthesize numSlices;
@synthesize keyIdx;

/**
 * Tags for the tables in the parameter panels.
 * This is to help keep track of the tags for the parameter tables.
 * They must be coordinated with the tags in the DCEFitDialog.xib file.
 */
enum TableTags
{
	RigidLBFGSBOptimizerTag = 0,
	RigidLBFGSOptimizerTag = 1,
	RigidRSGDOptimizerTag = 2,
	DeformLBFGSBOptimizerTag = 3,
	DeformLBFGSOptimizerTag = 4,
	DeformRSGDOptimizerTag = 5,
    RigidMattesMIMetricTag = 6,
    DeformMattesMIMetricTag = 7,
    DeformBsplineGridSizeTag = 8,
};

- (id)init
{
    self = [super initWithWindowNibName:@"MainDialog"];
    if (self)
    {
        [self setupLogger];
        LOG4M_TRACE(logger_, @"");
        openSheet_ = nil;
    }
    return self;
}

- (void)dealloc
{
    [logger_ release];
    [super dealloc];
}

- (void)awakeFromNib
{
    LOG4M_TRACE(logger_, @"Enter");

 //    for(int y = 0; y < [viewerController1 maxMovieIndex]; y++)
//    {
//        NSArray* pixList = [viewerController1 pixList];
//        for(int x = 0; x < [pixList[y] count]; x++)
//        {
//            for(int i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
//            {
//                ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
//
//                [curROI setName: [roiRenameName stringValue]];
//
//                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
//            }
//        }
//    }

    // Catch the viewer closing event. We cannot continue without the viewer.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewerWillClose:)
                                                 name:@"CloseViewerNotification"
                                               object:viewerController1];
    

    [self connectToViewer:viewerController1];
    [self setupControlsFromParams];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".DialogController"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (void)connectToViewer:(ViewerController *)viewer 
{
    viewerController1 = viewer;
    keyIdx = -1;  // -1 flags that key image is not found
    regParams.flippedData = [[viewerController1 imageView] flippedData];
}

- (void)setupControlsFromParams
{
    LOG4M_TRACE(logger_, @"Enter");

    // set things up based upon the OsiriX viewer controller
    NSArray* pixList = [viewerController1 pixList];
    self.numSlices = [pixList count];
    regParams.numImages = self.numSlices;
    
    // Find the first key image and assume that it is the desired fixed slice.
    keyIdx = -1;
    for (unsigned idx = 0; idx < self.numSlices; ++idx)
    {
        if ([viewerController1 isKeyImage:idx])
        {
            keyIdx = idx;
            break;
        }
    }

    if (keyIdx == -1)
    {
        regParams.fixedImageNumber = 1;
        LOG4M_INFO(logger_, @"No key image found. ");
        LOG4M_INFO(logger_, @"Fixed image set to image: %d", regParams.fixedImageNumber);
    }
    else
    {
        regParams.fixedImageNumber = [regParams indexToImageNumber:keyIdx];
        LOG4M_INFO(logger_, @"Fixed image set to key image: %d", regParams.fixedImageNumber);
    }

    [self setupRegionFromFixedImage];
    [self setupMaskFromFixedImage];
    
    NSInteger index = regParams.fixedImageNumber - 1;
    [fixedImageComboBox selectItemAtIndex:index];
    [fixedImageComboBox setObjectValue:[self comboBox:fixedImageComboBox
                            objectValueForItemAtIndex:index]];
    [fixedImageComboBox reloadData];
    
    // enable the controls based upon the parameters
    [self enableControls];
}

- (NSString*)makeSeriesName
{
    // Get the current series desc. so that we can append to it.
    // Note. This is stored as the property seriesName in OsiriX's DicomSeries.
    NSString* dicomTag = @"SeriesDescription";

    DCMAttributeTag* tag = [DCMAttributeTag tagWithName:dicomTag];
    if (!tag)
        tag = [DCMAttributeTag tagWithTagString:dicomTag];

    DCMObject* dcmObject = [self dicomObjectForViewer:viewerController1];
    NSString* seriesDesc = nil;
    if (tag && tag.group && tag.element)
    {
        DCMAttribute* attr = [dcmObject attributeForTag:tag];
        seriesDesc = [[attr value] description];
    }

    NSString* newSeriesName = nil;
    
    // Set the new series name as the concatenation of the current one plus the one in regParams
    if (seriesDesc != nil)
        newSeriesName = [seriesDesc stringByAppendingFormat:@" - %@", regParams.seriesDescription];
    else
        newSeriesName = [[regParams.seriesDescription copy] autorelease];

    LOG4M_INFO(logger_, @"newSeriesName = %@", newSeriesName);

    return newSeriesName;
}

- (void)setupRegionFromFixedImage
{
    // If there is a key image we will use it as the fixed image. We will also look for
    // a region of interest (ROI). If there are more than one ROI we pick the one named "Reg".
    // If none is named "Reg" we take the first one on the list.
    // look for entry named "Reg"
    ROI* regRoi = nil;      // ROI which defines our itk::ImageRegion

    // Now see if there is a ROI associated with this image
    // This is a list of NSMutableArrays one for each image. The array element
    // corresponding to the image is the array of ROIs.
    NSArray* roiList = [viewerController1 roiList];

    // Array of ROIs for key image
    unsigned index = [regParams imageNumberToIndex:regParams.fixedImageNumber];

    NSMutableArray* rois = [roiList objectAtIndex:index];
    if ([rois count] != 0)
    {
        // Take the first one
        regRoi = [rois objectAtIndex:0];
        LOG4M_DEBUG(logger_, @"Using ROI named \'%@\' on key image as registration region.",
                    [regRoi name]);
        if ([rois count] > 1)
            LOG4M_WARN(logger_, @"More than one ROI on key image. Using ROI named \'%@\'.",
                       [regRoi name]);
    }

    if (regRoi != nil)
    {
        // we create the rectangle which just encloses the ROI
        CGFloat xmin = MAXFLOAT, xmax = -MAXFLOAT, ymin = MAXFLOAT, ymax = -MAXFLOAT;

        // MyPoint is a wrapper class for NSRect defined in OsiriX.
        for (MyPoint* point in [regRoi points])
        {
            if (point.x < xmin)
                xmin = point.x;
            if (point.x > xmax)
                xmax = point.x;
            if (point.y < ymin)
                ymin = point.y;
            if (point.y > ymax)
                ymax = point.y;
        }

        regParams.fixedImageRegion = [[[Region alloc]
                             initWithX:(unsigned)round(xmin) Y:(unsigned)round(ymin)
                             W:(unsigned)round(xmax - xmin) H:(unsigned)round(ymax - ymin)]
                            autorelease];

        LOG4M_INFO(logger_, @"Registration region set to [x:%ld y:%ld w:%ld h:%ld]",
                   regParams.fixedImageRegion.x, regParams.fixedImageRegion.y,
                   regParams.fixedImageRegion.width, regParams.fixedImageRegion.height);
    }
    else
    {
        // Set the region to be the entire image
        NSArray* pixList = [viewerController1 pixList];
        DCMPix* firstPix = [pixList objectAtIndex:0];
        regParams.fixedImageRegion.x = 0;
        regParams.fixedImageRegion.y = 0;
        regParams.fixedImageRegion.width = [firstPix pwidth];
        regParams.fixedImageRegion.height = [firstPix pheight];

        LOG4M_INFO(logger_, @"Registration region set to full image: [x:%ld y:%ld w:%ld h:%ld]",
                   regParams.fixedImageRegion.x, regParams.fixedImageRegion.y, regParams.fixedImageRegion.width,
                   regParams.fixedImageRegion.height);
    }
}

- (void)setupMaskFromFixedImage
{
    // If there is a key image we will use it as the fixed image. We will also look for
    // a region of interest (ROI). If there are more than one ROI we pick the one named "Reg".
    // If none is named "Reg" we take the first one on the list.
    // look for entry named "Reg"
    ROI* regRoi = nil;      // ROI which defines our itk::ImageRegion

    // Now see if there is a ROI associated with this image
    // This is a list of NSMutableArrays one for each image. The array element
    // corresponding to the image is the array of ROIs.
    NSArray* roiList = [viewerController1 roiList];

    // Array of ROIs for key image
    unsigned index = [regParams imageNumberToIndex:regParams.fixedImageNumber];

    NSMutableArray* rois = [roiList objectAtIndex:index];
    if ([rois count] != 0)
    {
        // Take the first one
        regRoi = [rois objectAtIndex:0];
        LOG4M_DEBUG(logger_, @"Using ROI named \'%@\' on key image as fixed mask.",
                    [regRoi name]);
        if ([rois count] > 1)
            LOG4M_WARN(logger_, @"More than one ROI on key image. Using ROI named \'%@\'.",
                       [regRoi name]);
    }

    if (regRoi != nil)
    {
        NSNumber* maskPoint;

        // MyPoint is a wrapper class for NSRect defined in OsiriX.
        for (MyPoint* point in [regRoi points])
        {
            maskPoint = [NSNumber numberWithFloat:point.x];
            [regParams.fixedImageMask addObject:maskPoint];
            maskPoint = [NSNumber numberWithFloat:point.y];
            [regParams.fixedImageMask addObject:maskPoint];
        }

        LOG4M_INFO(logger_, @"Fixed image mask set.");
        unsigned len = [regParams.fixedImageMask count];
        for (unsigned idx = 0; idx < len; idx += 2)
        {
            LOG4M_DEBUG(logger_, @"    [%f, %f]",
                        [(NSNumber*)[regParams.fixedImageMask objectAtIndex:idx] floatValue],
                        [(NSNumber*)[regParams.fixedImageMask objectAtIndex:idx + 1] floatValue]);
        }
    }
    else
    {
        LOG4M_INFO(logger_, @"Fixed image mask not set.");
    }
}

- (DCMObject*)dicomObjectForViewer:(ViewerController*)viewer
{
    DCMPix *firstPix = [[viewer pixList] objectAtIndex:0];

    // file containing first slice
    NSString* filePath = [firstPix sourceFile];

    return [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];
}

- (DicomSeries*)dicomSeriesForViewer:(ViewerController*)viewer
{
    DCMPix *firstPix = [[viewer pixList] objectAtIndex:0];

    return (DicomSeries*)[firstPix seriesObj];
}

// Called in response to notifications from OsiriX
- (void) viewerWillClose:(NSNotification*)notification
{
    LOG4M_TRACE(logger_, @"sender = %@", [notification name]);

    // We are interested only in the closing of our two viewers. Should another
    // one close we will ignore it
    if ([notification object] == viewerController1)
    {
        LOG4M_ERROR(logger_, @"The source image viewer has closed. Stopping.");

        NSRunCriticalAlertPanel(@"DCEFit cannot continue.",
                                @"The source image viewer is closing.",
                                @"Close", nil, nil);
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        parentFilter.dialogController = nil;

        [self close];
        [self autorelease];
    }
    else if ([notification object] == viewerController2)
    {
        LOG4M_ERROR(logger_, @"The destination image viewer has closed. Stopping.");

        NSRunCriticalAlertPanel(@"DCEFit cannot continue.",
                                @"The destination image viewer is closing.",
                                @"Close", nil, nil);
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        [progressWindowController close];
        [progressWindowController autorelease];
        progressWindowController = nil;
    }
}

// Alert panel delegate methods
- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
         contextInfo:(void *)contextInfo
{
    LOG4M_TRACE(logger_, @"returnCode = %ld", (long)returnCode);
    return;
}

- (IBAction)regStartButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"%@", [sender title]);

    //[self setupRegionFromKeyImage];
    [self disableControls];

    progressWindowController = [[ProgressWindowController alloc] initWithDialogController:self];
    
    [progressWindowController setProgressMinimum:0.0 andMaximum:numSlices + 1];
    [progressWindowController showWindow:self];

    // Show the panel as a sheet.
    // It is closed in ProgressWindowController -(IBAction)stopButtonPressed:(NSButton*)sender
    //[NSApp beginSheet:progressWindowController.window modalForWindow:self.window modalDelegate:nil
    //   didEndSelector:nil contextInfo:nil];

    // Copy the current dataset and viewer. We will work only with the new one.
 	viewerController2 = [parentFilter duplicateCurrent2DViewerWindow];
    if (viewerController2 == nil)
    {
        LOG4M_ERROR(logger_, @"Failed to duplicate current 2D viewer.");
        NSRunCriticalAlertPanel(@"DCEFit Plugin", @"Failed to duplicate current 2D viewer.",
                                @"Close", nil, nil);
        return;
    }

    [viewerController2 setPostprocessed:TRUE];

    // We want the flippedData flag to be the same in each viewer.
    if ([viewerController2 imageView].flippedData != [viewerController1 imageView].flippedData)
        [viewerController2 flipDataSeries:nil];

    registrationManager = [[RegistrationManager alloc]
                           initWithViewer:viewerController2 Params:regParams
                           ProgressWindow:progressWindowController];

    [registrationManager doRegistration];
}

- (IBAction)regCloseButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"%@", [sender title]);

    [[UserDefaults sharedInstance] save:regParams];

    parentFilter.dialogController = nil;
    [self.window close];
    [self autorelease];
}

- (IBAction)rigidRegOptimizerConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    //[self enableConfigButtons:NO];
    switch (regParams.rigidRegOptimizer)
    {
        case LBFGSB:
            openSheet_ = rigidRegLBFGSBOptimizerConfigPanel;
            break;
        case LBFGS:
            openSheet_ = rigidRegLBFGSOptimizerConfigPanel;
            break;
        case RSGD:
            openSheet_ = rigidRegRSGDOptimizerConfigPanel;
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:self
       didEndSelector:nil contextInfo:nil];
}

- (IBAction)deformRegOptimizerConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    //[self enableConfigButtons:NO];
    switch (regParams.deformRegOptimizer)
    {
        case LBFGSB:
            openSheet_ = deformRegLBFGSBOptimizerConfigPanel;
            break;
        case LBFGS:
            openSheet_ = deformRegLBFGSOptimizerConfigPanel;
            break;
        case RSGD:
            openSheet_ = deformRegRSGDOptimizerConfigPanel;
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:nil
       didEndSelector:nil contextInfo:nil];
}

- (IBAction)rigidRegMetricConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    //[self enableConfigButtons:NO];
    switch (regParams.rigidRegMetric)
    {
        case MeanSquares:
            break;
        case MattesMutualInformation:
            openSheet_ = rigidRegMMIMetricConfigPanel;
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:nil
       didEndSelector:nil contextInfo:nil];
}

- (IBAction)deformRegMetricConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    //[self enableConfigButtons:NO];
    switch (regParams.deformRegMetric)
    {
        case MeanSquares:
            break;
        case MattesMutualInformation:
            openSheet_ = deformRegMMIMetricConfigPanel;
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:nil
       didEndSelector:nil contextInfo:nil];
}

- (void)closeSheet
{
    [NSApp endSheet:openSheet_];
    [openSheet_ orderOut:self];
    openSheet_ = nil;
}

- (IBAction)rigidRegLBFGSBConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)rigidRegLBFGSConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)rigidRegRSGDConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)rigidRegMMIMetricCloseButtonPressed:(NSButton *)sender
{
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)deformRegLBFGSBConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)deformRegLBFGSConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)deformRegRSGDConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

- (IBAction)deformRegMMIConfigCloseButtonPressed:(NSButton *)sender
{
    [self closeSheet];
    //[self enableConfigButtons:YES];
}

// NSWindowDelegate methods

- (BOOL)windowShouldClose:(id)sender
{
    LOG4M_TRACE(logger_, @"sender = %@", sender);
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    LOG4M_TRACE(logger_, @"sender = %@", [notification name]);
    id window = [notification object];
    
    if (window == self)
    {
        LOG4M_DEBUG(logger_, @"Closing window: %@", [window autosaveName]);
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[UserDefaults sharedInstance] save:regParams];
    }
}

// NSTabViewDelegate methods
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    LOG4M_TRACE(logger_, @"tabViewItem = %@", [tabViewItem label]);
}

// NSTextFieldDelegate Methods
- (void)textDidBeginEditing:(NSNotification*)aNotification
{
    LOG4M_DEBUG(logger_, @"Notification: name = %@, object = %@, userInfo = %@",
                aNotification.name,
                aNotification.object != nil ? aNotification.object : @"nil",
                aNotification.userInfo != nil ? aNotification.userInfo : @"nil");
}

// Posts a notification that the text has changed and forwards
// this message to the receiver’s cell if it responds.
- (void)textDidChange:(NSNotification*)aNotification
{
    LOG4M_DEBUG(logger_, @"Notification: name = %@, object = %@, userInfo = %@",
                aNotification.name,
                aNotification.object != nil ? aNotification.object : @"nil",
                aNotification.userInfo != nil ? aNotification.userInfo : @"nil");
}

// Handles an end of editing.
- (void)textDidEndEditing:(NSNotification*)aNotification
{
    LOG4M_DEBUG(logger_, @"Notification: name = %@, object = %@, userInfo = %@",
                aNotification.name,
                aNotification.object != nil ? aNotification.object : @"nil",
                aNotification.userInfo != nil ? aNotification.userInfo : @"nil");
}

// NSTableViewDelegate methods
- (BOOL)tableView:(NSTableView *)tableView
   shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return YES;
}

// NSTableViewDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    LOG4M_TRACE(logger_, @"Enter");

    NSInteger tag = [tableView tag];
    NSInteger retVal = -1;

    //LOG4M_DEBUG(logger_, @"numberOfRowsInTableView tag = %ld", (long)[tableView tag]);

    switch (tag)
    {
        case RigidLBFGSBOptimizerTag:
        case RigidLBFGSOptimizerTag:
        case RigidRSGDOptimizerTag:
        case RigidMattesMIMetricTag:
            retVal = regParams.rigidRegMultiresLevels;
            break;
        case DeformLBFGSBOptimizerTag:
        case DeformLBFGSOptimizerTag:
        case DeformRSGDOptimizerTag:
        case DeformMattesMIMetricTag:
        case DeformBsplineGridSizeTag:
            retVal = regParams.deformRegMultiresLevels;
            break;
        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld in numberOfRowsInTableView", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in numberOfRowsInTableView", (long)tag];
    }

    LOG4M_DEBUG(logger_, @"numberOfRowsInTableView = %ld tag = %ld", (long)retVal, (long)tag);
    return retVal;
}

// This populates the tables by returning the object needed for a cell.
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row
{
    LOG4M_TRACE(logger_, @"Enter");

    // This could be any of the tables so we again use their tags to select the data provided
    NSInteger tag = [tableView tag];
    NSString* colIdent = [tableColumn identifier];

    LOG4M_DEBUG(logger_, @"objectValueForTableColumn tag = %ld, column ident = %@, row = %ld",
                (long)tag, colIdent, row);

    id retVal = nil;

    [tableColumn setEditable:YES];

    switch (tag)
    {
        case RigidLBFGSBOptimizerTag:  // rigid LBFGSB parameters
            if ([colIdent isEqualToString:@"convergence"])
            {
                retVal = [regParams.rigidRegLBFGSBCostConvergence objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"gradient"])
            {
                retVal = [regParams.rigidRegLBFGSBGradientTolerance objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                retVal = [regParams.rigidRegMaxIter objectAtIndex:row];
            }
            break;
        case RigidLBFGSOptimizerTag:  // rigid LBFGS parameters
            if ([colIdent isEqualToString:@"convergence"])
            {
                retVal = [regParams.rigidRegLBFGSGradientConvergence objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                retVal = [regParams.rigidRegLBFGSDefaultStepSize objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                retVal = [regParams.rigidRegMaxIter objectAtIndex:row];
            }
            break;
        case RigidRSGDOptimizerTag:  // rigid RSGD parameters
            if ([colIdent isEqualToString:@"minstepsize"])
            {
                retVal = [regParams.rigidRegRSGDMinStepSize objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                retVal = [regParams.rigidRegRSGDMaxStepSize objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"relaxation"])
            {
                retVal = [regParams.rigidRegRSGDRelaxationFactor objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                retVal = [regParams.rigidRegMaxIter objectAtIndex:row];
            }
            break;
        case DeformLBFGSBOptimizerTag:  // deformable LBFGSB parameters
            if ([colIdent isEqualToString:@"convergence"])
            {
                retVal = [regParams.deformRegLBFGSBCostConvergence objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"gradient"])
            {
                retVal = [regParams.deformRegLBFGSBGradientTolerance objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                retVal = [regParams.deformRegMaxIter objectAtIndex:row];
            }
            break;
        case DeformLBFGSOptimizerTag:  // deformable LBFGS parameters
            if ([colIdent isEqualToString:@"convergence"])
            {
                retVal = [regParams.deformRegLBFGSGradientConvergence objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                retVal = [regParams.deformRegLBFGSDefaultStepSize objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                retVal = [regParams.deformRegMaxIter objectAtIndex:row];
            }
            break;
        case DeformRSGDOptimizerTag:  // deformable RSGD parameters
            if ([colIdent isEqualToString:@"minstepsize"])
            {
                retVal = [regParams.deformRegRSGDMinStepSize objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                retVal = [regParams.deformRegRSGDMaxStepSize objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"relaxation"])
            {
                retVal = [regParams.deformRegRSGDRelaxationFactor objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                retVal = [regParams.deformRegMaxIter objectAtIndex:row];
            }
            break;
        case RigidMattesMIMetricTag:  // rigid MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
            {
                retVal = [regParams.rigidRegMMIHistogramBins objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"samplerate"])
            {
                retVal = [regParams.rigidRegMMISampleRate objectAtIndex:row];
            }
            break;
        case DeformMattesMIMetricTag:  // rigid MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
            {
                retVal = [regParams.deformRegMMIHistogramBins objectAtIndex:row];
            }
            else if ([colIdent isEqualToString:@"samplerate"])
            {
                retVal = [regParams.deformRegMMISampleRate objectAtIndex:row];
            }
            break;
        case DeformBsplineGridSizeTag:  // deformable grid size
            if ([colIdent isEqualToString:@"gridsize"])
                retVal = [regParams.deformRegGridSize objectAtIndex:row];
            break;
        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld in objectValueForTableColumn", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in ", (long)tag];
    }

    LOG4M_DEBUG(logger_, @"objectValueForTableColumn = %@", retVal);

    return retVal;
}

// This gets the value for a cell that has just been edited
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LOG4M_TRACE(logger_, @"Enter");

    // This could be any of the tables so we again use their tags to select the data provided
    NSInteger tag = [tableView tag];
    NSString* colIdent = [tableColumn identifier];

    LOG4M_DEBUG(logger_, @"setObjectValue:forTableColumn tag = %ld, column ident = %@, object = %@",
                (long)tag, colIdent, object);
    
    switch (tag)
    {
         case RigidLBFGSBOptimizerTag:  // rigid Optimizer parameters
            if ([colIdent isEqualToString:@"convergence"])
            {
                [regParams.rigidRegLBFGSBCostConvergence replaceObjectAtIndex:row
                                                                   withObject:object];
            }
            else if ([colIdent isEqualToString:@"gradient"])
            {
                [regParams.rigidRegLBFGSBGradientTolerance replaceObjectAtIndex:row
                                                                     withObject:object];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                [regParams.rigidRegMaxIter replaceObjectAtIndex:row withObject:object];
            }
            break;
        case RigidLBFGSOptimizerTag:
            if ([colIdent isEqualToString:@"convergence"])
            {
                [regParams.rigidRegLBFGSGradientConvergence replaceObjectAtIndex:row
                                                                      withObject:object];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                [regParams.rigidRegLBFGSDefaultStepSize replaceObjectAtIndex:row
                                                                  withObject:object];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                [regParams.rigidRegMaxIter replaceObjectAtIndex:row withObject:object];
            }
            break;
        case RigidRSGDOptimizerTag:
            if ([colIdent isEqualToString:@"minstepsize"])
            {
                [regParams.rigidRegRSGDMinStepSize replaceObjectAtIndex:row
                                                             withObject:object];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                [regParams.rigidRegRSGDMaxStepSize replaceObjectAtIndex:row
                                                             withObject:object];
            }
            else if ([colIdent isEqualToString:@"relaxation"])
            {
                [regParams.rigidRegRSGDRelaxationFactor replaceObjectAtIndex:row
                                                                   withObject:object];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                [regParams.rigidRegMaxIter replaceObjectAtIndex:row withObject:object];
            }
            break;

            // deformable Optimizer parameters
        case DeformLBFGSBOptimizerTag:
            if ([colIdent isEqualToString:@"convergence"])
            {
                [regParams.deformRegLBFGSBCostConvergence replaceObjectAtIndex:row
                                                                   withObject:object];
            }
            else if ([colIdent isEqualToString:@"gradient"])
            {
                [regParams.deformRegLBFGSBGradientTolerance replaceObjectAtIndex:row
                                                                     withObject:object];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                [regParams.deformRegMaxIter replaceObjectAtIndex:row withObject:object];
            }
            break;
        case DeformLBFGSOptimizerTag:
            if ([colIdent isEqualToString:@"convergence"])
            {
                [regParams.deformRegLBFGSGradientConvergence replaceObjectAtIndex:row
                                                                      withObject:object];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                [regParams.deformRegLBFGSDefaultStepSize replaceObjectAtIndex:row
                                                                  withObject:object];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                [regParams.deformRegMaxIter replaceObjectAtIndex:row withObject:object];
            }
            break;
        case DeformRSGDOptimizerTag:
            if ([colIdent isEqualToString:@"minstepsize"])
            {
                [regParams.deformRegRSGDMinStepSize replaceObjectAtIndex:row
                                                             withObject:object];
            }
            else if ([colIdent isEqualToString:@"initstepsize"])
            {
                [regParams.deformRegRSGDMaxStepSize replaceObjectAtIndex:row
                                                              withObject:object];
            }
            else if ([colIdent isEqualToString:@"relaxation"])
            {
                [regParams.deformRegRSGDRelaxationFactor replaceObjectAtIndex:row
                                                              withObject:object];
            }
            else if ([colIdent isEqualToString:@"iterations"])
            {
                [regParams.deformRegMaxIter replaceObjectAtIndex:row
                                                      withObject:object];
            }
            break;
        case RigidMattesMIMetricTag:  // rigid MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
            {
                [regParams.rigidRegMMIHistogramBins replaceObjectAtIndex:row
                                                              withObject:object];
            }
            else if ([colIdent isEqualToString:@"samplerate"])
            {
                [regParams.rigidRegMMISampleRate replaceObjectAtIndex:row
                                                           withObject:object];
            }
            break;
        case DeformMattesMIMetricTag:  // deformable MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
            {
                [regParams.deformRegMMIHistogramBins replaceObjectAtIndex:row
                                                               withObject:object];
            }
            else if ([colIdent isEqualToString:@"samplerate"])
            {
                [regParams.deformRegMMISampleRate replaceObjectAtIndex:row
                                                            withObject:object];
            }
            break;
        case DeformBsplineGridSizeTag:  // deformable grid size
            [regParams.deformRegGridSize replaceObjectAtIndex:row withObject:object];
            break;
        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld in tableView:setObjectValue:forTableColumn:row", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in tableView:setObjectValue:forTableColumn:row", (long)tag];
    }

    // This is done because the rigidRegMaxIter and deformRegMaxIter properties
    // in the regParams instance are shared among the tables.
    [self reloadAllTables];
}

- (void)reloadAllTables
{
    LOG4M_TRACE(logger_, @"Enter");

    [rigidRegLBFGSBOptimizerTableView reloadData];
    [rigidRegLBFGSOptimizerTableView reloadData];
    [rigidRegRSGDOptOptimizerTableView reloadData];
    [rigidRegMMIMetricTableView reloadData];
    [deformRegLBFGSBOptimizerTableView reloadData];
    [deformRegLBFGSOptimizerTableView reloadData];
    [deformRegRSGDOptimizerTableView reloadData];
    [deformRegMMIMetricTableView reloadData];
    [deformRegGridSizeTableView reloadData];
}

// NSComboboxDelegate methods
- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    LOG4M_TRACE(logger_, @"Enter: %@", [notification name]);
    NSComboBox* cb = (NSComboBox*)[notification object];
    long tag = [cb tag];

    LOG4M_DEBUG(logger_, @"comboBoxSelectionDidChange tag = %ld", tag);
    
    // Use the tag of the combo box to select the parameter to set
    // These tags are hard wired in the XIB file.
    NSInteger idx = [cb indexOfSelectedItem];
    NSNumber* value = [self comboBox:cb objectValueForItemAtIndex:idx];
    switch (tag)
    {
        case 0:
            regParams.fixedImageNumber = [value unsignedIntValue];
            break;

        case 1:
            regParams.rigidRegMultiresLevels = [value unsignedIntValue];
            [rigidRegLBFGSBOptimizerTableView reloadData];
            [rigidRegLBFGSOptimizerTableView reloadData];
            [rigidRegRSGDOptOptimizerTableView reloadData];
            [rigidRegMMIMetricTableView reloadData];
            break;

        case 2:
            regParams.deformRegMultiresLevels = [value unsignedIntValue];
            [deformRegLBFGSBOptimizerTableView reloadData];
            [deformRegLBFGSOptimizerTableView reloadData];
            [deformRegRSGDOptimizerTableView reloadData];
            [deformRegMMIMetricTableView reloadData];
            [deformRegGridSizeTableView reloadData];
            break;

        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in comboBoxSelectionDidChange:notification", (long)tag];
    }
}

// NSComboboxDatasource methods
- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index
{
    LOG4M_TRACE(logger_, @"%ld", (long)index);
    long tag = [comboBox tag];

    LOG4M_DEBUG(logger_, @"comboBox:objectValueForItemAtIndex tag = %ld, index = %ld", tag, index);

    id retVal;

    unsigned idx = (unsigned)index;
    
    switch (tag)
    {
        case 0:  // fixed image number
            retVal = [NSNumber numberWithUnsignedInt:idx + 1];
            break;

        case 1:  // rigid levels
            retVal = [NSNumber numberWithUnsignedInt:idx + 1];
            break;

        case 2:  // deformable levels
            retVal = [NSNumber numberWithUnsignedInt:idx + 1];
            break;

        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in comboBox:objectValueForItemAtIndex:", (long)tag];
            return nil;
    }
    
    LOG4M_DEBUG(logger_, @"returning %@", retVal);
    
    return retVal;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
    //LOG4M_TRACE(logger_, @"Enter");
    long tag = [comboBox tag];

    LOG4M_DEBUG(logger_, @"numberOfItemsInComboBox tag = %ld", tag);

    NSInteger retVal;
    
    switch (tag)
    {
        case 0:  // fixed image number
            retVal = (NSInteger)regParams.numImages;
            break;

        case 1:  // rigid levels
            retVal = (NSInteger)MAX_ARRAY_PARAMS;
            break;

        case 2:  // deformable levels
            retVal = (NSInteger)MAX_ARRAY_PARAMS;
            break;

         default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in numberOfItemsInComboBox:", (long)tag];
            return (NSInteger)-1;
    }
    
    LOG4M_DEBUG(logger_, @"returning %ld", retVal);

    return retVal;
}

// Actions
- (IBAction)rigidRegEnableChanged:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"rigidRegEnableChanged: %ld", (long)[sender state]);
    
    [rigidRegLevelsComboBox setEnabled:regParams.rigidRegEnabled];
    [rigidRegMetricRadioMatrix setEnabled:regParams.rigidRegEnabled];
    [rigidRegMetricConfigButton setEnabled:regParams.rigidRegEnabled];
    [rigidRegOptimizerRadioMatrix setEnabled:regParams.rigidRegEnabled];
    [rigidRegOptimizerConfigButton setEnabled:regParams.rigidRegEnabled];

    if (regParams.rigidRegEnabled)
    {
        switch (regParams.rigidRegMetric)
        {
            case MattesMutualInformation:
                [rigidRegMetricConfigButton setEnabled:YES];
                break;
            default:
                [rigidRegMetricConfigButton setEnabled:NO];
                break;
        }
    }
}

- (IBAction)rigidRegMetricChanged:(NSMatrix *)sender
{
    LOG4M_DEBUG(logger_, @"rigidMetricChanged tag = %ld", (long)[[sender selectedCell] tag]);
    
    switch (regParams.rigidRegMetric)
    {
        case MattesMutualInformation:
            [rigidRegMetricConfigButton setEnabled:YES];
            break;
        default:
            [rigidRegMetricConfigButton setEnabled:NO];
            break;
    }
}

- (IBAction)deformRegEnableChanged:(NSButton *)sender
{
    LOG4M_DEBUG(logger_, @"deformRegEnableChanged state = %ld", (long)[sender state]);
    
    [deformRegLevelsComboBox setEnabled:regParams.deformRegEnabled];
    [deformRegGridSizeTableView setEnabled:regParams.deformRegEnabled];
    [deformRegMetricRadioMatrix setEnabled:regParams.deformRegEnabled];
    [deformRegMetricConfigButton setEnabled:regParams.deformRegEnabled];
    [deformRegOptimizerRadioMatrix setEnabled:regParams.deformRegEnabled];
    [deformRegOptimizerConfigButton setEnabled:regParams.deformRegEnabled];

    if (regParams.deformRegEnabled)
    {
        switch (regParams.deformRegMetric)
        {
            case MattesMutualInformation:
                [deformRegMetricConfigButton setEnabled:YES];
                break;
            default:
                [deformRegMetricConfigButton setEnabled:NO];
                break;
        }
    }
}

- (IBAction)deformRegMetricChanged:(NSMatrix *)sender
{
    LOG4M_DEBUG(logger_, @"deformMetricChanged tag = %ld", (long)[[sender selectedCell] tag]);
    
    switch (regParams.deformRegMetric)
    {
        case MattesMutualInformation:
            [deformRegMetricConfigButton setEnabled:YES];
            break;
        default:
            [deformRegMetricConfigButton setEnabled:NO];
            break;
    }
}

- (void)disableControls
{
    LOG4M_TRACE(logger_, @"Enter");

    [seriesDescriptionTextField setEnabled:NO];
    [fixedImageComboBox setEnabled:NO];

    [rigidRegEnableCheckBox setEnabled:NO];
    [rigidRegLevelsComboBox setEnabled:NO];
    [rigidRegOptimizerRadioMatrix setEnabled:NO];
    [rigidRegOptimizerConfigButton setEnabled:NO];
    [rigidRegMetricRadioMatrix setEnabled:NO];
    [rigidRegMetricConfigButton setEnabled:NO];

    [deformRegEnableCheckBox setEnabled:NO];
    [deformRegLevelsComboBox setEnabled:NO];
    [deformRegGridSizeTableView setEnabled:NO];
    [deformRegOptimizerRadioMatrix setEnabled:NO];
    [deformRegOptimizerConfigButton setEnabled:NO];
    [deformRegMetricRadioMatrix setEnabled:NO];
    [deformRegMetricConfigButton setEnabled:NO];

    [regCloseButton setEnabled:NO];
    [regStartButton setEnabled:NO];
}

- (void)enableControls
{
    LOG4M_TRACE(logger_, @"Enter");

    // turn off everything to start
    [self disableControls];

    // These are always enabled
    [seriesDescriptionTextField setEnabled:YES];
    [fixedImageComboBox setEnabled:YES];
    [rigidRegEnableCheckBox setEnabled:YES];
    [deformRegEnableCheckBox setEnabled:YES];
    [regCloseButton setEnabled:YES];
    [regStartButton setEnabled:YES];

    // selectively turn things on as needed
    [rigidRegLevelsComboBox setEnabled:regParams.rigidRegEnabled];
    [rigidRegMetricRadioMatrix setEnabled:regParams.rigidRegEnabled];
    [rigidRegOptimizerConfigButton setEnabled:regParams.rigidRegEnabled];
    [rigidRegOptimizerRadioMatrix setEnabled:regParams.rigidRegEnabled];
    [rigidRegMetricConfigButton setEnabled:regParams.rigidRegEnabled];
    if (regParams.rigidRegEnabled)
    {
        switch (regParams.rigidRegMetric)
        {
            case MattesMutualInformation:
                [rigidRegMetricConfigButton setEnabled:YES];
                break;
            default:
                [rigidRegMetricConfigButton setEnabled:NO];
        }
    }

    [deformRegLevelsComboBox setEnabled:regParams.deformRegEnabled];
    [deformShowFieldCheckBox setEnabled:regParams.deformRegEnabled];
    [deformRegGridSizeTableView setEnabled:regParams.deformRegEnabled];
    [deformRegOptimizerRadioMatrix setEnabled:regParams.deformRegEnabled];
    [deformRegMetricRadioMatrix setEnabled:regParams.deformRegEnabled];
    [deformRegOptimizerConfigButton setEnabled:regParams.deformRegEnabled];
    [deformRegMetricConfigButton setEnabled:regParams.deformRegEnabled];
    if (regParams.deformRegEnabled)
    {
        if (regParams.deformRegMetric == MattesMutualInformation)
        {
            [deformRegMetricConfigButton setEnabled:YES];
        }
        else
        {
            [deformRegMetricConfigButton setEnabled:NO];
        }
    }

}

- (void)registrationEnded:(BOOL)saveData
{
    LOG4M_TRACE(logger_, @"Enter");

    if (saveData)
    {
        NSString* seriesName = [self makeSeriesName];
        LOG4M_DEBUG(logger_, @"Exporting series description: %@", seriesName);
        [viewerController2 exportAllImages:seriesName];
    }
    else
        LOG4M_DEBUG(logger_, @"Closing without saving.");

    [self enableControls];
}

@end
