//
//  DialogController.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-04-18.
//
//

#include <itkVersion.h>
#include <itkMultiThreader.h>

#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/ROI.h>

#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMCalendarDate.h>

#import "ViewerController+ExportTimeSeries.h"
#import "DialogController.h"
#import "DCEFitFilter.h"
#import "ProgressWindowController.h"
#import "RegistrationParams.h"
#import "RegistrationManager.h"
#import "UserDefaults.h"
#import "SeriesInfo.h"
#import "LoadingImagesWindowController.h"

#import "LoggerUtils.h"


@implementation DialogController;

@synthesize progressWindowController;
@synthesize regParams;
@synthesize parentFilter;
@synthesize viewerController1;
@synthesize viewerController2;
@synthesize seriesInfo;

@synthesize fixedImageComboBox;
@synthesize seriesDescriptionTextField;

@synthesize rigidRegLevelsComboBox;
@synthesize rigidRegMetricRadioMatrix;
@synthesize rigidRegOptimizerLabel;

@synthesize bsplineRegLevelsComboBox;
@synthesize bsplineRegGridSizeTableView;
@synthesize bsplineRegMetricRadioMatrix;
@synthesize bsplineRegOptimizerRadioMatrix;
//@synthesize deformShowFieldCheckBox;
@synthesize regCloseButton;
@synthesize regStartButton;
@synthesize loggingLevelComboBox;
@synthesize numberOfThreadsComboBox;

/**
 * Tags for the tables in the parameter panels.
 * This is to help keep track of the tags for the parameter tables.
 * They must be coordinated with the tags in the DCEFitDialog.xib file.
 */
enum TableTags
{
	RigidRSGDOptimizerTag = 2,
	BSplineLBFGSBOptimizerTag = 3,
	BSplineLBFGSOptimizerTag = 4,
	BSplineRSGDOptimizerTag = 5,
    RigidMattesMIMetricTag = 6,
    BSplineMattesMIMetricTag = 7,
    BsplineGridSizeTag = 8,
	RigidVersorOptimizerTag = 9,
    DemonsOptimizerTag = 10
};

- (id)initWithViewerController:(ViewerController *)viewerController
                        Filter:(DCEFitFilter *)filter;
{
    self = [super initWithWindowNibName:@"MainDialog"];
    if (self)
    {
        openSheet_ = nil;
        viewerController1 = viewerController;
        parentFilter = filter;
        seriesInfo = [[SeriesInfo alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [logger_ release];
    [seriesInfo release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

- (void)awakeFromNib
{
    // Get the version from the bundle that contains this class
    NSBundle* bundle = [NSBundle bundleForClass:[DialogController class]];
    NSDictionary* infoDict = [bundle infoDictionary];
    NSString* bundleVersion = [infoDict objectForKey:@"CFBundleVersion"];
    NSString* bundleName = [infoDict objectForKey:@"CFBundleName"];

    // Put the version onto the main window.
    NSString* title = [bundleName stringByAppendingFormat:@" %@", bundleVersion];
    [self.window setTitle:title];

    // Catch the viewer closing event. We cannot continue without the viewer.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewerWillClose:)
                                                 name:OsirixCloseViewerNotification
                                               object:viewerController1];

    [self setupSystemLogger];
    [self setupLogger];
    [self setupProgramDefaults];

    LoadingImagesWindowController* progressWindow =
        [[LoadingImagesWindowController alloc] initWithWindowNibName:@"LoadingImagesWindow"];
    [progressWindow.window makeKeyAndOrderFront:self];
    [self extractSeriesInfo:seriesInfo withProgressWindow:progressWindow];
    [progressWindow close];
    [progressWindow release];

    [self setupControlsFromParams];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".DialogController"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

/**
 Sets up the Log4m logger.
 */
- (void)setupSystemLogger
{
    UserDefaults* defaults = [UserDefaults sharedInstance];

    regParams.loggerLevel = [defaults integerForKey:LoggerLevelKey];
    SetupLogger(LOGGER_NAME, regParams.loggerLevel);
}

- (void)setupProgramDefaults
{
    LOG4M_INFO(logger_, @"Using ITK version %d.%d.%d", itk::Version::GetITKMajorVersion(),
               itk::Version::GetITKMinorVersion(), itk::Version::GetITKBuildVersion());

    // Set up the default threading. This can be changed later.
    [self setNumberOfThreads:0];
}

- (void)saveDefaults
{
    UserDefaults* defaults = [UserDefaults sharedInstance];
    [defaults saveRegParams:regParams];
}

- (void)setNumberOfThreads:(unsigned)requested
{
    LOG4M_DEBUG(logger_, @"ITK threads: default = %d, max = %d",
               itk::MultiThreader::GetGlobalDefaultNumberOfThreads(),
               itk::MultiThreader::GetGlobalMaximumNumberOfThreads());

    // Threading
    // We want to set this up so that we maximise the use of the machine. If we are running
    // 32 bit code, there isn't enough memory to run many threads so we cap it at MAX_32_BIT_THREADS
    // If we are running in a 64 bit environment we can load up the processors.
    // itk::MultiThreader::GetGlobalDefaultNumberOfThreads() gives a best guess at an optimal
    // number and we will use this as the default and maximum.
    UserDefaults* defaults = [UserDefaults sharedInstance];

    // Cap the number of threads at ITK's best guess
#ifdef __x86_64__
    unsigned maxThreads = itk::MultiThreader::GetGlobalMaximumNumberOfThreads();
    LOG4M_INFO(logger_, @"64 bit environment. Max threads = %u", maxThreads);
#else
#ifdef __i386__
    unsigned maxThreads = MAX_32BIT_THREADS;
    LOG4M_INFO(logger_, @"32 bit environment. Max threads = %u", maxThreads);
#endif
#endif

#ifdef __x86_64__
    unsigned defaultThreads = itk::MultiThreader::GetGlobalDefaultNumberOfThreads();
    LOG4M_INFO(logger_, @"64 bit environment. Default threads = %u", defaultThreads);
#else
#ifdef __i386__
    unsigned defaultThreads = DEFAULT_32BIT_THREADS;
    LOG4M_INFO(logger_, @"32 bit environment. Default threads = %u", defaultThreads);
#endif
#endif

    // First guess at the number we will use, ensuring it is not too many.
    unsigned numThreads = [defaults unsignedIntegerForKey:NumberOfThreadsKey];
    numThreads = std::min(numThreads, maxThreads);

    // Use the ITK (64 bit) or the 32 bit default if this is true
    BOOL useDefaultNumThreads = [defaults booleanForKey:UseDefaultNumberOfThreadsKey];
    if (useDefaultNumThreads)
        numThreads = defaultThreads;

    // if requested is > 0 we will honour the request. This comes from the combobox so it
    // is alread range checked.
    if (requested > 0)
        numThreads = requested;

    // Set the global max for ITK
    itk::MultiThreader::SetGlobalDefaultNumberOfThreads(numThreads);
    itk::MultiThreader::SetGlobalMaximumNumberOfThreads(numThreads);

    regParams.maxNumberOfThreads = maxThreads;
    regParams.numberOfThreads = numThreads;

    LOG4M_INFO(logger_, @"Number of ITK threads set to = %u", numThreads);
}

- (void)extractSeriesInfo:(SeriesInfo*)info withProgressWindow:(LoadingImagesWindowController*)progWindow
{
    LOG4M_TRACE(logger_, @"Enter");

    unsigned numTimeImages = (unsigned)[viewerController1 maxMovieIndex];
    NSTimeInterval firstTime = 0.0;

    info.numTimeSamples = numTimeImages;
    info.slicesPerImage = [[viewerController1 pixList] count];
    info.isFlipped = [[viewerController1 imageView] flippedData];

    if (numTimeImages == 1)  // we have a 2D viewer
    {
        LOG4M_DEBUG(logger_, @"2D viewer with %u slices.", info.slicesPerImage);
    }
    else // we have a 4D viewer
    {
        LOG4M_DEBUG(logger_, @"4D viewer with %u images and %u slices per image.",
                    info.numTimeSamples, info.slicesPerImage);
    }

    // initialise the progress indicator
    [progWindow setNumImages:info.numTimeSamples];

    NSArray* firstImage = [viewerController1 pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];

    info.sliceHeight = [firstPix pheight];
    info.sliceWidth = [firstPix pwidth];

    LOG4M_DEBUG(logger_, @"Slice height = %u, width = %u, size = %u pixels.",
                info.sliceHeight, info.sliceWidth, info.sliceHeight * info.sliceWidth);

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        LOG4M_DEBUG(logger_, @"******** timeIdx = %u ***************", timeIdx);

        // Bump the progress indicator
        [progWindow incrementIndicator];

        // The ROIs for this image.
        NSArray* roiList = [viewerController1 roiList:timeIdx];

        // The array of slices in the image.
        NSArray* pixList = [viewerController1 pixList:timeIdx];

        // The list of DicomImage instances corresponding to the slices.
        //NSArray* fileList = [viewerController1 fileList:timeIdx];

        unsigned numSlices = info.slicesPerImage;
        for (unsigned sliceIdx = 0; sliceIdx < numSlices; ++sliceIdx)
        {
            // DCMPix instance containing this slice
            DCMPix* curPix = [pixList objectAtIndex:sliceIdx];

            // The DicomImage instance containing this slice.
            //DicomImage* curSlice = [fileList objectAtIndex:sliceIdx];

            // Image may be displayed flipped. We need the real index.
            // The list of ROIs in this slice. Pick out either the first one named "DCEFit"
            // or the first one in the list
            NSArray* curRoiList = [roiList objectAtIndex:sliceIdx];
            if ((curRoiList != nil) && ([curRoiList count] > 0))
            {
                BOOL found = NO;
                for (ROI* r in curRoiList)
                {
                    NSString* name = r.name;
                    if ((!found) &&
                        ([name compare:@"DCEFit" options:NSCaseInsensitiveSearch] == NSOrderedSame))
                        {
                            found = YES;
                            info.regROI = r;
                            info.roiSliceIdx = sliceIdx;
                            info.roiImageIdx = timeIdx;
                            LOG4M_DEBUG(logger_, @"ROI image index: %u (slice index %u)",
                                        info.roiImageIdx, info.roiSliceIdx);
                        }
                }

                LOG4M_DEBUG(logger_, @"Using ROI named \'%@\' to generate registration region.",
                                [info.regROI name]);
                LOG4M_DEBUG(logger_, @"ROI points: \'%@\'.", [info.regROI points]);
            }

            NSString* filePath = [curPix sourceFile];
            DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];

            DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"AcquisitionTime"];
            DCMAttribute* attr = [dcmObj attributeForTag:tag];
            DCMCalendarDate* dcmDate = attr.value;
            NSTimeInterval acqTime = [dcmDate timeIntervalSinceReferenceDate];

            // do this once per series
            if ((timeIdx == 0) && (sliceIdx == 0))
                firstTime = acqTime;

            // do this once per time increment
            if (sliceIdx == 0)
            {
                NSString* dateStr = [dcmDate descriptionWithCalendarFormat:@"%H:%M:%S"];
                [info addAcqTimeString:dateStr];
                LOG4M_DEBUG(logger_, @"Acquisition time = %@", dateStr);

                NSTimeInterval normalisedTime = acqTime - firstTime;
                [info addAcqTime:normalisedTime];
                LOG4M_DEBUG(logger_, @"Normalised acquisition time = %fs", normalisedTime);
            }
        }
    }
    
    [progWindow close];
}

- (void)parseDataSet
{
    LOG4M_TRACE(logger_, @"Enter");

    unsigned numTimeImages = (unsigned)[viewerController1 maxMovieIndex];
    NSTimeInterval firstTime = 0.0;
    unsigned slicesPerImage = [[viewerController1 pixList] count];

    if (numTimeImages == 1)  // we have a 2D viewer
    {
        LOG4M_DEBUG(logger_, @"******** 2D viewer with %u slices. ***************", slicesPerImage);
    }
    else // we have a 4D viewer
    {
        LOG4M_DEBUG(logger_, @"******** 4D viewer with %u images and %u slices per image. ***************",
                    numTimeImages, slicesPerImage);
    }

    NSArray* firstImage = [viewerController1 pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];
    unsigned sliceHeight = [firstPix pheight];
    unsigned sliceWidth = [firstPix pwidth];
    unsigned sliceSize = sliceHeight * sliceWidth;
    LOG4M_DEBUG(logger_, @"******** Slice height = %u, width = %u, size = %u pixels. ***************",
                sliceHeight, sliceWidth, sliceSize);

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        LOG4M_DEBUG(logger_, @"******** timeIdx = %u ***************", timeIdx);

        float* imageBuff = [viewerController1 volumePtr:timeIdx];
        LOG4M_DEBUG(logger_, @"******** volumePtr = %p. ***************", imageBuff);

        NSArray* roiList = [viewerController1 roiList:timeIdx];
        NSArray* pixList = [viewerController1 pixList:timeIdx];
        NSArray* fileList = [viewerController1 fileList:timeIdx];

        unsigned numSlices = [pixList count];
        for (unsigned sliceIdx = 0; sliceIdx < numSlices; ++sliceIdx)
        {
            DCMPix* curPix = [pixList objectAtIndex:sliceIdx];
            size_t offset = [curPix fImage] - imageBuff;
            LOG4M_DEBUG(logger_, @"sliceIdx = %u, offset = %lu", sliceIdx, offset / sliceSize);
            LOG4M_DEBUG(logger_, @"Source file: %@", [curPix sourceFile]);

            DicomImage* curSlice = [fileList objectAtIndex:sliceIdx];
            BOOL isKey = [[curSlice isKeyImage] boolValue];
            if (isKey)
            {
                LOG4M_DEBUG(logger_, @"Key image");
            }

            NSArray* curRoiList = [roiList objectAtIndex:sliceIdx];
            if ((curRoiList != nil) && ([curRoiList count] > 0))
            {
                for (ROI* r in curRoiList)
                    LOG4M_DEBUG(logger_, @"ROI named \"%@\" found.", [r name]);
            }

            NSString* file_path = [curPix sourceFile];
            DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:file_path decodingPixelData:NO];

            DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"ImagePositionPatient"];
            DCMAttribute* attr = [dcmObj attributeForTag:tag];
            NSArray* ippValues = [attr values];
            LOG4M_DEBUG(logger_, @"IPP = %@", ippValues);

            tag = [DCMAttributeTag tagWithName:@"AcquisitionTime"];
            attr = [dcmObj attributeForTag:tag];
            NSTimeInterval acqTime = [[attr value] timeIntervalSinceReferenceDate];
            if ((timeIdx == 0) && (sliceIdx == 0))
                firstTime = acqTime;
            
            if (sliceIdx == 0) // do this once per time increment
            {
                NSTimeInterval normalisedTime = acqTime - firstTime;
                LOG4M_DEBUG(logger_, @"AcqTime = %f", normalisedTime);
            }
        }
    }
}

- (void)setupControlsFromParams
{
    LOG4M_TRACE(logger_, @"Enter");

    // First the program defaults
    NSInteger logIdx = regParams.loggerLevel / 10000;
    [loggingLevelComboBox selectItemAtIndex:logIdx];
    [loggingLevelComboBox setObjectValue:[self comboBox:loggingLevelComboBox
                              objectValueForItemAtIndex:logIdx]];
    [loggingLevelComboBox reloadData];

    NSInteger threadIdx = regParams.numberOfThreads - 1;
    [numberOfThreadsComboBox selectItemAtIndex:threadIdx];
    [numberOfThreadsComboBox setObjectValue:[self comboBox:numberOfThreadsComboBox
                                 objectValueForItemAtIndex:threadIdx]];
    [numberOfThreadsComboBox reloadData];

    // set things up based upon the image series information
    regParams.slicesPerImage = seriesInfo.slicesPerImage;
    regParams.numImages = seriesInfo.numTimeSamples;
    regParams.rigidRegOptimizer = regParams.slicesPerImage == 1 ? RSGD : Versor;
    regParams.flippedData = [[viewerController1 imageView] flippedData];
    if (regParams.slicesPerImage == 1)
    {
        NSArray* cols = [bsplineRegGridSizeTableView tableColumns];
        NSInteger zColNum = [bsplineRegGridSizeTableView columnWithIdentifier:@"z"];
        NSTableColumn* zCol = [cols objectAtIndex:zColNum];
        [zCol setHidden:YES];
    }

    // Find the first key image and assume that it is the desired fixed slice.
    if (seriesInfo.roiImageIdx == -1)
    {
        if (regParams.fixedImageNumber > regParams.numImages)
            regParams.fixedImageNumber = 1;
        LOG4M_INFO(logger_, @"No image with ROI named \"DCEFit\" found.");
        LOG4M_INFO(logger_, @"Fixed image set to image: %d", regParams.fixedImageNumber);
    }
    else
    {
        regParams.fixedImageNumber = seriesInfo.roiImageIdx + 1;
        LOG4M_INFO(logger_, @"Fixed image set to image: %d", regParams.fixedImageNumber);
    }

    [self setupRegionFromFixedImage];

    // This function needs to be rewritten before using.
    //[self setupMaskFromFixedImage];

    // Set up combobox to reflect number of images in series
    // The number of items in a cb is set very early in the initialisation,
    // well before we know how many images we have so we have to tell the cb
    // that it needs to reset itself.
    [fixedImageComboBox noteNumberOfItemsChanged];
    NSInteger index = regParams.fixedImageNumber - 1;
    [fixedImageComboBox selectItemAtIndex:index];
    [fixedImageComboBox setObjectValue:[self comboBox:fixedImageComboBox
                            objectValueForItemAtIndex:index]];
    [fixedImageComboBox reloadData];

    // ComboBoxes for the registration levels
    NSInteger levelIdx = regParams.rigidRegMultiresLevels - 1;
    [rigidRegLevelsComboBox selectItemAtIndex:levelIdx];
    [rigidRegLevelsComboBox setObjectValue:[self comboBox:rigidRegLevelsComboBox
                                objectValueForItemAtIndex:levelIdx]];
    [rigidRegLevelsComboBox reloadData];

    levelIdx = regParams.bsplineRegMultiresLevels - 1;
    [bsplineRegLevelsComboBox selectItemAtIndex:levelIdx];
    [bsplineRegLevelsComboBox setObjectValue:[self comboBox:bsplineRegLevelsComboBox
                                  objectValueForItemAtIndex:levelIdx]];
    [bsplineRegLevelsComboBox reloadData];
    
    levelIdx = regParams.demonsRegMultiresLevels - 1;
    [demonsRegLevelsComboBox selectItemAtIndex:levelIdx];
    [demonsRegLevelsComboBox setObjectValue:[self comboBox:demonsRegLevelsComboBox
                                  objectValueForItemAtIndex:levelIdx]];
    [demonsRegLevelsComboBox reloadData];
    
    // Set up label to reflect number of dimensions in images
    if (regParams.slicesPerImage == 1)
        [rigidRegOptimizerLabel setStringValue:@"Regular Step Gradient Descent"];
    else
        [rigidRegOptimizerLabel setStringValue:@"Versor Rigid 3D"];

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
    // ROI which defines our itk::ImageRegion
    ROI* regRoi = seriesInfo.regROI;

    if (regRoi != nil)
    {
        LOG4M_DEBUG(logger_, @"Using ROI named \"%@\" as registration region.", [regRoi name]);

        // we create the rectangle which just encloses the ROI
        float xmin = MAXFLOAT, xmax = -MAXFLOAT, ymin = MAXFLOAT, ymax = -MAXFLOAT;

        // MyPoint is a wrapper class for NSRect defined in OsiriX.
        NSArray* roiPoints = [regRoi points];
        for (MyPoint* point in roiPoints)
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

        regParams.fixedImageRegion = [[[Region2D alloc]
                             initWithX:(unsigned)round(xmin) Y:(unsigned)round(ymin)
                             W:(unsigned)round(xmax - xmin) H:(unsigned)round(ymax - ymin)]
                            autorelease];

        LOG4M_INFO(logger_, @"Registration region set to [x:%u y:%u w:%u h:%u]",
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

        LOG4M_INFO(logger_,
                   @"Registration region set to full image: [x:%u y:%u w:%u h:%u]",
                   regParams.fixedImageRegion.x, regParams.fixedImageRegion.y,
                   regParams.fixedImageRegion.width, regParams.fixedImageRegion.height);
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
    unsigned index = regParams.fixedImageNumber - 1;

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

- (void) progressPanelWillClose:(NSNotification*)notification
{
    LOG4M_TRACE(logger_, @"Notification = %@; object class = %@",
                [notification name], NSStringFromClass([[notification object] class]));

    progressWindowController = nil;
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

        [progressWindowController close];
        [progressWindowController autorelease];
        progressWindowController = nil;

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

    
    if ((regParams.regSequence != Rigid) && (regParams.regSequence != RigidBSpline) &&
        (regParams.regSequence != BSpline) && (regParams.regSequence != Demons))
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];

        [alert addButtonWithTitle:@"Close"];
        [alert setMessageText:@"DCEFit plugin."];
        [alert setInformativeText:@"Both rigid and deformable registrations are disabled."
             " You must enable at least one to continue."];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
        LOG4M_INFO(logger_, @"Both rigid and deformable registrations are disabled."
                   " You must enable at least one to continue.");

        return;
    }

    [self saveDefaults];
    [self disableControls];

    progressWindowController = [[ProgressWindowController alloc] initWithDialogController:self];
    [progressWindowController setProgressMinimum:0.0 andMaximum:seriesInfo.numTimeSamples + 1];
    [progressWindowController showWindow:self];
    if (regParams.regSequence == Demons)
        [progressWindowController.metricLabel setStringValue:@"RMS Diff."];
    else
        [progressWindowController.metricLabel setStringValue:@"Metric"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(progressPanelWillClose:)
                                                 name:CloseProgressPanelNotification
                                               object:progressWindowController];

    // Copy the current dataset and viewer. We will work only with the new one.
 	viewerController2 = [parentFilter copyCurrent4DViewerWindow];

    if (viewerController2 == nil)
    {
        LOG4M_ERROR(logger_, @"Failed to duplicate current 4D viewer.");
        NSRunCriticalAlertPanel(@"DCEFit Plugin", @"Failed to duplicate current 4D viewer.",
                                @"Close", nil, nil);
        return;
    }

    [viewerController2 setPostprocessed:TRUE];

    // We want the flippedData flag to be the same in each viewer.
    if ([viewerController2 imageView].flippedData !=
        [viewerController1 imageView].flippedData)
        [viewerController2 flipDataSeries:nil];

    registrationManager = [[RegistrationManager alloc]
                           initWithViewer:viewerController2 Params:regParams
                           ProgressWindow:progressWindowController
                           SeriesInfo:seriesInfo];

    [registrationManager doRegistration];
}

- (IBAction)regCloseButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"%@", [sender title]);

    [self saveDefaults];

    parentFilter.dialogController = nil;
    [self.window close];
    [self autorelease];
}

- (IBAction)rigidRegOptimizerConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    switch (regParams.rigidRegOptimizer)
    {
        case RSGD:
            openSheet_ = rigidRegRSGDOptimizerConfigPanel;
            break;
        case Versor:
            openSheet_ = rigidVersorOptimizerConfigPanel;
            break;
        default:
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:self
       didEndSelector:nil contextInfo:nil];
}

- (IBAction)bsplineRegOptimizerConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    switch (regParams.bsplineRegOptimizer)
    {
        case LBFGSB:
            openSheet_ = bsplineRegLBFGSBOptimizerConfigPanel;
            break;
        case LBFGS:
            openSheet_ = bsplineRegLBFGSOptimizerConfigPanel;
            break;
        case RSGD:
            openSheet_ = bsplineRegRSGDOptimizerConfigPanel;
            break;
        default:
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:nil
       didEndSelector:nil contextInfo:nil];
}

- (IBAction)rigidRegMetricConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

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

- (IBAction)bsplineRegMetricConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    switch (regParams.bsplineRegMetric)
    {
        case MeanSquares:
            break;
        case MattesMutualInformation:
            openSheet_ = bsplineRegMMIMetricConfigPanel;
            break;
    }

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:nil
       didEndSelector:nil contextInfo:nil];
}

- (IBAction)demonsRegOptimizerConfigButtonPressed:(NSButton *)sender
{
    LOG4M_TRACE(logger_, @"sender: %@", [sender title]);

    openSheet_ = demonsRegOptimizerConfigPanel;

    [NSApp beginSheet:openSheet_ modalForWindow:self.window modalDelegate:nil
       didEndSelector:nil contextInfo:nil];
}

- (void)closeSheet
{
    [NSApp endSheet:openSheet_];
    [openSheet_ orderOut:self];
    openSheet_ = nil;
}

- (IBAction)rigidRegRSGDConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
}

- (IBAction)rigidRegMMIMetricCloseButtonPressed:(NSButton *)sender
{
    [self closeSheet];
}

- (IBAction)rigidRegVersorConfigCloseButtonPressed:(NSButton *)sender
{
    [self closeSheet];
}

- (IBAction)bsplineRegLBFGSBConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
}

- (IBAction)bsplineRegLBFGSConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
}

- (IBAction)bsplineRegRSGDConfigCloseButtonPressed:(NSButton *)sender
{
    // Do nothing but close the panel because the data have already been stored.
    [self closeSheet];
}

- (IBAction)bsplineRegMMIConfigCloseButtonPressed:(NSButton *)sender
{
    [self closeSheet];
}

- (IBAction)demonsRegOptimizerCloseButtonPressed:(NSButton *)sender
{
    [self closeSheet];
}

// NSWindowDelegate methods

- (BOOL)windowShouldClose:(id)sender
{
    LOG4M_TRACE(logger_, @"sender = %@", sender);
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    LOG4M_TRACE(logger_, @"Notification = %@; object class = %@",
                [notification name], NSStringFromClass([[notification object] class]));
    id window = [notification object];
    
    if (window == self)
    {
        LOG4M_DEBUG(logger_, @"Closing window: %@", [window autosaveName]);
        [self saveDefaults];
        //[[UserDefaults sharedInstance] save:regParams];
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

    switch (tag)
    {
        case RigidRSGDOptimizerTag:
        case RigidMattesMIMetricTag:
        case RigidVersorOptimizerTag:
            retVal = regParams.rigidRegMultiresLevels;
            break;
        case BSplineLBFGSBOptimizerTag:
        case BSplineLBFGSOptimizerTag:
        case BSplineRSGDOptimizerTag:
        case BSplineMattesMIMetricTag:
        case BsplineGridSizeTag:
            retVal = regParams.bsplineRegMultiresLevels;
            break;
        case DemonsOptimizerTag:
            retVal = regParams.demonsRegMultiresLevels;
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
        case RigidRSGDOptimizerTag:  // rigid RSGD parameters
            if ([colIdent isEqualToString:@"minstepsize"])
                retVal = [regParams.rigidRegRSGDMinStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"initstepsize"])
                retVal = [regParams.rigidRegRSGDMaxStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"relaxation"])
                retVal = [regParams.rigidRegRSGDRelaxationFactor objectAtIndex:row];
            else if ([colIdent isEqualToString:@"iterations"])
                retVal = [regParams.rigidRegMaxIter objectAtIndex:row];
            break;
        case RigidVersorOptimizerTag:  // rigid Versor optim. parameters
            if ([colIdent isEqualToString:@"minstepsize"])
                retVal = [regParams.rigidRegVersorOptMinStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"initstepsize"])
                retVal = [regParams.rigidRegVersorOptMaxStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"relaxation"])
                retVal = [regParams.rigidRegVersorOptRelaxationFactor objectAtIndex:row];
            else if ([colIdent isEqualToString:@"transscaling"])
                retVal = [regParams.rigidRegVersorOptTransScale objectAtIndex:row];
            else if ([colIdent isEqualToString:@"iterations"])
                retVal = [regParams.rigidRegMaxIter objectAtIndex:row];
            break;
        case BSplineLBFGSBOptimizerTag:  // deformable LBFGSB parameters
            if ([colIdent isEqualToString:@"convergence"])
                retVal = [regParams.bsplineRegLBFGSBCostConvergence objectAtIndex:row];
            else if ([colIdent isEqualToString:@"gradient"])
                retVal = [regParams.bsplineRegLBFGSBGradientTolerance objectAtIndex:row];
            else if ([colIdent isEqualToString:@"iterations"])
                retVal = [regParams.bsplineRegMaxIter objectAtIndex:row];
            break;
        case BSplineLBFGSOptimizerTag:  // deformable LBFGS parameters
            if ([colIdent isEqualToString:@"convergence"])
                retVal = [regParams.bsplineRegLBFGSGradientConvergence objectAtIndex:row];
            else if ([colIdent isEqualToString:@"initstepsize"])
                retVal = [regParams.bsplineRegLBFGSDefaultStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"iterations"])
                retVal = [regParams.bsplineRegMaxIter objectAtIndex:row];
            break;
        case BSplineRSGDOptimizerTag:  // deformable RSGD parameters
            if ([colIdent isEqualToString:@"minstepsize"])
                retVal = [regParams.bsplineRegRSGDMinStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"initstepsize"])
                retVal = [regParams.bsplineRegRSGDMaxStepSize objectAtIndex:row];
            else if ([colIdent isEqualToString:@"relaxation"])
                retVal = [regParams.bsplineRegRSGDRelaxationFactor objectAtIndex:row];
            else if ([colIdent isEqualToString:@"iterations"])
                retVal = [regParams.bsplineRegMaxIter objectAtIndex:row];
            break;
        case RigidMattesMIMetricTag:  // rigid MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
                retVal = [regParams.rigidRegMMIHistogramBins objectAtIndex:row];
            else if ([colIdent isEqualToString:@"samplerate"])
                retVal = [regParams.rigidRegMMISampleRate objectAtIndex:row];
            break;
        case BSplineMattesMIMetricTag:  // rigid MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
                retVal = [regParams.bsplineRegMMIHistogramBins objectAtIndex:row];
            else if ([colIdent isEqualToString:@"samplerate"])
                retVal = [regParams.bsplineRegMMISampleRate objectAtIndex:row];
            break;
        case BsplineGridSizeTag:  // deformable grid size
            if ([colIdent isEqualToString:@"x"])
                retVal = [[regParams.bsplineRegGridSizeArray objectAtIndex:row] objectAtIndex:0];
            else if ([colIdent isEqualToString:@"y"])
                retVal = [[regParams.bsplineRegGridSizeArray objectAtIndex:row] objectAtIndex:1];
            else if ([colIdent isEqualToString:@"z"])
                retVal = [[regParams.bsplineRegGridSizeArray objectAtIndex:row] objectAtIndex:2];
            break;
        case DemonsOptimizerTag:
            if ([colIdent isEqualToString:@"convergence"])
                retVal = [regParams.demonsRegMaxRMSError objectAtIndex:row];
            else if ([colIdent isEqualToString:@"iterations"])
                retVal = [regParams.demonsRegMaxIter objectAtIndex:row];
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
        case RigidRSGDOptimizerTag:
            if ([colIdent isEqualToString:@"minstepsize"])
                [regParams.rigidRegRSGDMinStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"initstepsize"])
                [regParams.rigidRegRSGDMaxStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"relaxation"])
                [regParams.rigidRegRSGDRelaxationFactor replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"iterations"])
                [regParams.rigidRegMaxIter replaceObjectAtIndex:row withObject:object];
            break;
        case RigidVersorOptimizerTag:
            if ([colIdent isEqualToString:@"minstepsize"])
                [regParams.rigidRegVersorOptMinStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"initstepsize"])
                [regParams.rigidRegVersorOptMaxStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"relaxation"])
                [regParams.rigidRegVersorOptRelaxationFactor replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"transscaling"])
                [regParams.rigidRegVersorOptTransScale replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"iterations"])
                [regParams.rigidRegMaxIter replaceObjectAtIndex:row withObject:object];
            break;

            // deformable Optimizer parameters
        case BSplineLBFGSBOptimizerTag:
            if ([colIdent isEqualToString:@"convergence"])
                [regParams.bsplineRegLBFGSBCostConvergence replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"gradient"])
                [regParams.bsplineRegLBFGSBGradientTolerance replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"iterations"])
                [regParams.bsplineRegMaxIter replaceObjectAtIndex:row withObject:object];
            break;
        case BSplineLBFGSOptimizerTag:
            if ([colIdent isEqualToString:@"convergence"])
                [regParams.bsplineRegLBFGSGradientConvergence replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"initstepsize"])
                [regParams.bsplineRegLBFGSDefaultStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"iterations"])
                [regParams.bsplineRegMaxIter replaceObjectAtIndex:row withObject:object];
            break;
        case BSplineRSGDOptimizerTag:
            if ([colIdent isEqualToString:@"minstepsize"])
                [regParams.bsplineRegRSGDMinStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"initstepsize"])
                [regParams.bsplineRegRSGDMaxStepSize replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"relaxation"])
                [regParams.bsplineRegRSGDRelaxationFactor replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"iterations"])
                [regParams.bsplineRegMaxIter replaceObjectAtIndex:row withObject:object];
            break;
        case RigidMattesMIMetricTag:  // rigid MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
                [regParams.rigidRegMMIHistogramBins replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"samplerate"])
                [regParams.rigidRegMMISampleRate replaceObjectAtIndex:row withObject:object];
            break;
        case BSplineMattesMIMetricTag:  // deformable MMI metric parameters
            if ([colIdent isEqualToString:@"bins"])
                [regParams.bsplineRegMMIHistogramBins replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"samplerate"])
                [regParams.bsplineRegMMISampleRate replaceObjectAtIndex:row withObject:object];
            break;
        case BsplineGridSizeTag:  // deformable grid size
            if ([colIdent isEqualToString:@"x"])
                [[regParams.bsplineRegGridSizeArray objectAtIndex:row]replaceObjectAtIndex:0
                                                                               withObject:object];
            else if ([colIdent isEqualToString:@"y"])
                [[regParams.bsplineRegGridSizeArray objectAtIndex:row] replaceObjectAtIndex:1
                                                                                withObject:object];
            if ([colIdent isEqualToString:@"z"])
                [[regParams.bsplineRegGridSizeArray objectAtIndex:row] replaceObjectAtIndex:2
                                                                                withObject:object];
            break;
        case DemonsOptimizerTag:  // rigid Optimizer parameters
            if ([colIdent isEqualToString:@"convergence"])
                [regParams.demonsRegMaxRMSError replaceObjectAtIndex:row withObject:object];
            else if ([colIdent isEqualToString:@"iterations"])
                [regParams.demonsRegMaxIter replaceObjectAtIndex:row withObject:object];
            break;

        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld in tableView:setObjectValue:forTableColumn:row", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in tableView:setObjectValue:forTableColumn:row", (long)tag];
    }

    // This is done because the rigidRegMaxIter and bsplineRegMaxIter properties
    // in the regParams instance are shared among the tables.
    [self reloadAllTables];
}

- (void)reloadAllTables
{
    LOG4M_TRACE(logger_, @"Enter");

    [rigidRegRSGDOptOptimizerTableView reloadData];
    [rigidRegVersorOptimizerTableView reloadData];
    [rigidRegMMIMetricTableView reloadData];
    [bsplineRegLBFGSBOptimizerTableView reloadData];
    [bsplineRegLBFGSOptimizerTableView reloadData];
    [bsplineRegRSGDOptimizerTableView reloadData];
    [bsplineRegMMIMetricTableView reloadData];
    [bsplineRegGridSizeTableView reloadData];
    [demonsRegOptimizerTableView reloadData];
}

// NSComboboxDelegate methods
- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    LOG4M_TRACE(logger_, @"Enter: %@", [notification name]);
    NSComboBox* cb = (NSComboBox*)[notification object];
    long tag = [cb tag];
    NSInteger idx = [cb indexOfSelectedItem];
    id value = [self comboBox:cb objectValueForItemAtIndex:idx];

    LOG4M_DEBUG(logger_, @"comboBoxSelectionDidChange tag = %ld, idx = %ld, value = %@", tag, idx, value);
    
    // Use the tag of the combo box to select the parameter to set
    // These tags are hard wired in the XIB file.
    switch (tag)
    {
        case 0:
            regParams.fixedImageNumber = idx+1;
            //regParams.fixedImageNumber = [value unsignedIntValue];
            break;

        case 1:
            regParams.rigidRegMultiresLevels = [value unsignedIntValue];
            [rigidRegRSGDOptOptimizerTableView reloadData];
            [rigidRegVersorOptimizerTableView reloadData];
            [rigidRegMMIMetricTableView reloadData];
            break;

        case 2:
            regParams.bsplineRegMultiresLevels = [value unsignedIntValue];
            [bsplineRegLBFGSBOptimizerTableView reloadData];
            [bsplineRegLBFGSOptimizerTableView reloadData];
            [bsplineRegRSGDOptimizerTableView reloadData];
            [bsplineRegMMIMetricTableView reloadData];
            [bsplineRegGridSizeTableView reloadData];
            break;

        case 3:
            // This depends upon the enum in ProjectDefs.h.
            // value is a string, we need the index to set the level
            regParams.loggerLevel = idx * 10000;
            ResetLoggerLevel(LOGGER_NAME, regParams.loggerLevel);
            break;

        case 4:
            regParams.numberOfThreads = [value intValue];
            [self setNumberOfThreads:regParams.numberOfThreads];
            break;

        case 5:
            regParams.demonsRegMultiresLevels = [value unsignedIntValue];
            [demonsRegOptimizerTableView reloadData];
            break;

        default:
            LOG4M_FATAL(logger_, @"Invalid tag %ld.", (long)tag);
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid tag %ld in comboBoxSelectionDidChange:notification", (long)tag];
    }
}

// NSComboboxDatasource methods
// This fills the combo box.
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
            retVal = [NSString stringWithFormat:@"%3u - [%@]", idx + 1, [seriesInfo acqTimeString:idx]];
            //retVal = [NSNumber numberWithUnsignedInt:idx + 1];
            break;

        case 1:  // rigid levels
            retVal = [NSNumber numberWithUnsignedInt:idx + 1];
            break;

        case 2:  // B-spline deformable levels
            retVal = [NSNumber numberWithUnsignedInt:idx + 1];
            break;

        case 3: // Logging level
            switch (idx)
            {
                case 0:
                    retVal = @"Trace";
                    break;
                case 1:
                    retVal = @"Debug";
                    break;
                case 2:
                    retVal = @"Info";
                    break;
                case 3:
                    retVal = @"Warn";
                    break;
                case 4:
                    retVal = @"Error";
                    break;
                case 5:
                    retVal = @"Fatal";
                    break;
                case 6:
                    retVal = @"Off";
                    break;
                default:
                    LOG4M_FATAL(logger_, @"Invalid tag %ld.", (long)tag);
                    [NSException raise:NSInternalInconsistencyException
                                format:@"Invalid tag %ld in comboBox:objectValueForItemAtIndex:", (long)tag];
                    return nil;
            }
            break;

        case 4:  // number of threads
            retVal = [NSNumber numberWithInt:idx + 1];
            break;

        case 5:  // demons levels
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
            retVal = (NSInteger)seriesInfo.numTimeSamples;
            break;

        case 1:  // rigid levels
            retVal = (NSInteger)MAX_REGISTRATION_LEVELS;
            break;

        case 2:  // B-spline deformable levels
            retVal = (NSInteger)MAX_REGISTRATION_LEVELS;
            break;

        case 3:  // logging level
            retVal = 7;  // There are 7 logging levels.
            break;

        case 4: // number of threads
            retVal = regParams.maxNumberOfThreads;
            break;

        case 5:  // demons deformable levels
            retVal = (NSInteger)MAX_REGISTRATION_LEVELS;
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
//- (IBAction)rigidRegEnableChanged:(NSButton *)sender
//{
//    LOG4M_TRACE(logger_, @"rigidRegEnableChanged: %ld", (long)[sender state]);
//    
//    [rigidRegLevelsComboBox setEnabled:regParams.isRigidRegEnabled];
//    [rigidRegMetricRadioMatrix setEnabled:regParams.isRigidRegEnabled];
//    [rigidRegMetricConfigButton setEnabled:regParams.isRigidRegEnabled];
//    [rigidRegOptimizerLabel setEnabled:regParams.isRigidRegEnabled];
//    [rigidRegOptimizerConfigButton setEnabled:regParams.isRigidRegEnabled];
//
//    if (regParams.isRigidRegEnabled)
//    {
//        switch (regParams.rigidRegMetric)
//        {
//            case MattesMutualInformation:
//                [rigidRegMetricConfigButton setEnabled:YES];
//                break;
//            default:
//                [rigidRegMetricConfigButton setEnabled:NO];
//                break;
//        }
//    }
//}

- (IBAction)registrationSelectionRadioMatrixChanged:(NSMatrix *)sender
{
    long tag = [[sender selectedCell] tag];
    LOG4M_DEBUG(logger_, @"registrationSelectionRadioMatrixChanged tag = %ld", tag);

//    switch (regParams.regSequence)
//    {
//        case Rigid:
//            regParams.regSequence = Rigid;
//            break;
//        case BSpline:
//            regParams.regSequence = BSpline;
//            break;
//        case RigidBSpline:
//            regParams.regSequence = RigidBSpline;
//            break;
//        case Demons:
//            regParams.regSequence = Demons;
//            break;
//    }
}

- (IBAction)rigidRegMetricChanged:(NSMatrix *)sender
{
    LOG4M_DEBUG(logger_, @"rigidMetricChanged tag = %ld", (long)[[sender selectedCell] tag]);
    
//    switch (regParams.rigidRegMetric)
//    {
//        case MattesMutualInformation:
//            [rigidRegMetricConfigButton setEnabled:YES];
//            break;
//        default:
//            [rigidRegMetricConfigButton setEnabled:NO];
//            break;
//    }
}

//- (IBAction)bsplineRegEnableChanged:(NSButton *)sender
//{
//    LOG4M_DEBUG(logger_, @"bsplineRegEnableChanged state = %ld", (long)[sender state]);
//    
//    [bsplineRegLevelsComboBox setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegGridSizeTableView setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegMetricRadioMatrix setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegMetricConfigButton setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegOptimizerRadioMatrix setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegOptimizerConfigButton setEnabled:regParams.bsplineRegEnabled];
//
//    if (regParams.bsplineRegEnabled)
//    {
//        switch (regParams.bsplineRegMetric)
//        {
//            case MattesMutualInformation:
//                [bsplineRegMetricConfigButton setEnabled:YES];
//                break;
//            default:
//                [bsplineRegMetricConfigButton setEnabled:NO];
//                break;
//        }
//    }
//}

- (IBAction)bsplineRegMetricChanged:(NSMatrix *)sender
{
    LOG4M_DEBUG(logger_, @"deformMetricChanged tag = %ld", (long)[[sender selectedCell] tag]);
    
//    switch (regParams.bsplineRegMetric)
//    {
//        case MattesMutualInformation:
//            [bsplineRegMetricConfigButton setEnabled:YES];
//            break;
//        default:
//            [bsplineRegMetricConfigButton setEnabled:NO];
//            break;
//    }
}

- (void)disableControls
{
    LOG4M_TRACE(logger_, @"Enter");

//    [seriesDescriptionTextField setEnabled:NO];
//    [fixedImageComboBox setEnabled:NO];
//
//    [rigidRegLevelsComboBox setEnabled:NO];
//    [rigidRegOptimizerLabel setEnabled:NO];
//    [rigidRegOptimizerConfigButton setEnabled:NO];
//    [rigidRegMetricRadioMatrix setEnabled:NO];
//    [rigidRegMetricConfigButton setEnabled:NO];
//
//    [bsplineRegLevelsComboBox setEnabled:NO];
//    [bsplineRegGridSizeTableView setEnabled:NO];
//    [bsplineRegOptimizerRadioMatrix setEnabled:NO];
//    [bsplineRegOptimizerConfigButton setEnabled:NO];
//    [bsplineRegMetricRadioMatrix setEnabled:NO];
//    [bsplineRegMetricConfigButton setEnabled:NO];
//
//    [regCloseButton setEnabled:NO];
//    [regStartButton setEnabled:NO];
}

- (void)enableControls
{
    LOG4M_TRACE(logger_, @"Enter");

    // turn off everything to start
//    [self disableControls];
//
//    // These are always enabled
//    [seriesDescriptionTextField setEnabled:YES];
//    [fixedImageComboBox setEnabled:YES];
//    [regCloseButton setEnabled:YES];
//    [regStartButton setEnabled:YES];
//
//    // selectively turn things on as needed
//    [rigidRegLevelsComboBox setEnabled:regParams.rigidRegEnabled];
//    [rigidRegMetricRadioMatrix setEnabled:regParams.rigidRegEnabled];
//    [rigidRegOptimizerConfigButton setEnabled:regParams.rigidRegEnabled];
//    [rigidRegOptimizerLabel setEnabled:regParams.rigidRegEnabled];
//    [rigidRegMetricConfigButton setEnabled:regParams.rigidRegEnabled];
//    if (regParams.rigidRegEnabled)
//    {
//        switch (regParams.rigidRegMetric)
//        {
//            case MattesMutualInformation:
//                [rigidRegMetricConfigButton setEnabled:YES];
//                break;
//            default:
//                [rigidRegMetricConfigButton setEnabled:NO];
//        }
//    }
//
//    [bsplineRegLevelsComboBox setEnabled:regParams.bsplineRegEnabled];
//    //[deformShowFieldCheckBox setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegGridSizeTableView setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegOptimizerRadioMatrix setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegMetricRadioMatrix setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegOptimizerConfigButton setEnabled:regParams.bsplineRegEnabled];
//    [bsplineRegMetricConfigButton setEnabled:regParams.bsplineRegEnabled];
//    if (regParams.bsplineRegEnabled)
//    {
//        if (regParams.bsplineRegMetric == MattesMutualInformation)
//        {
//            [bsplineRegMetricConfigButton setEnabled:YES];
//        }
//        else
//        {
//            [bsplineRegMetricConfigButton setEnabled:NO];
//        }
//    }
}

- (void)registrationEnded:(BOOL)saveData
{
    LOG4M_TRACE(logger_, @"Enter");

    if (saveData)
    {
        NSString* seriesName = [self makeSeriesName];
        LOG4M_DEBUG(logger_, @"Exporting series description: %@", seriesName);
        [viewerController2 exportAllImages4D:seriesName];
    }
    else
        LOG4M_DEBUG(logger_, @"Closing without saving.");

    [self enableControls];
}

@end
