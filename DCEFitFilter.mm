//
//  DCEFitFilter.m
//  DCEFit
//
//  Copyright (c) 2013 Tim. All rights reserved.
//

#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/ROI.h>

#import "ViewerController+ExportTimeSeries.h"

#import "ProjectDefs.h"
#import "SetupLogger.h"
#import "DCEFitFilter.h"
#import "DialogController.h"
#import "SeriesInfo.h"
#import "LoadingImagesWindowController.h"

@implementation DCEFitFilter

@synthesize dialogController;
@synthesize seriesInfo;

- (id)init
{
    NSLog(@"DCEFitFilter.init");
    self = [super init];
    if (self)
    {
        seriesInfo = [[SeriesInfo alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [seriesInfo release];
    [logger_ release];
    [super dealloc];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".DCEFitFilter"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (void) initPlugin
{
    NSLog(@"DCEFitFilter.initPlugin");
    [self setupSystemLogger];
    [self setupLogger];
}

- (long) filterImage:(NSString*) menuName
{
    NSLog(@"DCEFitFilter.filterImage:%@", menuName);

    // Before anything else, we check to see if either we are in a 4D viewer.
    // We cannot continue if the user has loaded a time series of images in
    // the 2D viewer.
    if ([viewerController maxMovieIndex] == 1) // test for 2D viewer
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];

        [alert addButtonWithTitle:@"Close"];
        [alert setMessageText:@"DCEFit plugin."];
        [alert setInformativeText:@"This is a time series of images."
         " Please reopen the series in the 4D viewer in order to analyse it with DCEFit."];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:viewerController.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];

        LOG4M_ERROR(logger_, @"This is a time series of 2D or 3D images."
                    " Please reopen the series in the 4D viewer.");
        return 1;
    }

    //[self parseDataSet];  // show structure of data, debugging only

    LoadingImagesWindowController* liwc = [[[LoadingImagesWindowController alloc]
                                           initWithWindowNibName:@"LoadingImagesWindow"]
                                           autorelease];
    [liwc.window makeKeyAndOrderFront:self];
    [self extractSeriesInfo:seriesInfo withProgressWindow:liwc];
    [liwc close];

    LOG4M_DEBUG(logger_, @"seriesInfo: %@", seriesInfo);

    if (dialogController == nil)
    {
        dialogController = [[DialogController alloc] initWithViewerController:viewerController
                                                                       Filter:self
                                                                   SeriesInfo:seriesInfo];

        [dialogController.window setFrameAutosaveName:@"DCEFitMainDialog"];
        [dialogController.window makeKeyAndOrderFront:nil];
    }
    
    return 0;
}

/**
	Sets up the Log4m logger.
 */
- (void)setupSystemLogger
{
    // Now the Log4m logger
    SetupLogger(LOGGER_NAME, LOG4M_LEVEL_TRACE);
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    return;
}

/**
 * Duplicates a 4D viewer.
 * @returns The new 4D viewer instance
 */
- (ViewerController*)copyCurrent4DViewerWindow
{
    LOG4M_TRACE(logger_, @"Enter");

    // each pixel contains either a 32-bit float or a 32-bit ARGB value
    const int ELEMENT_SIZE = 4;

    ViewerController *new4DViewer = nil;
    float* volumePtr = nil;

    // First calculate the amount of memory needed for the new series
    NSArray* pixList0 = [viewerController pixList:0];
    DCMPix* pix0 = [pixList0 objectAtIndex:0];
    size_t memSize = [pix0 pheight] * [pix0 pwidth] * [pixList0 count] * ELEMENT_SIZE ;

    // We will read our current series, and duplicate it by creating a new series!
    unsigned numImages = viewerController.maxMovieIndex;
    for (unsigned timeIdx = 0; timeIdx < numImages; timeIdx++)
    {
        // First calculate the amount of memory needed for the new series
        NSArray* pixList = [viewerController pixList:timeIdx];
        DCMPix* curPix = nil;

        if (memSize > 0)
        {
            volumePtr = (float*)malloc(memSize);// use malloc for allocating memory !

            // Copy the source series in the new one !
            memcpy(volumePtr, [viewerController volumePtr:timeIdx], memSize);

            // Create a NSData object to control the new pointer.
            // Assumes that malloc has been used to allocate memory.
            NSData *volData = [[[NSData alloc]initWithBytesNoCopy:volumePtr
                                                           length:memSize
                                                     freeWhenDone:YES] autorelease];

            // Now copy the DCMPix with the new volumePtr
            NSMutableArray *newPixList = [NSMutableArray array];
            for (unsigned i = 0; i < [pixList count]; i++)
            {
                curPix = [[[pixList objectAtIndex:i] copy] autorelease];
                unsigned offset = [curPix pheight] * [curPix pwidth] * i;//ELEMENT_SIZE * i;
                float* fImage = volumePtr + offset;
                [curPix setfImage:fImage];
                [newPixList addObject: curPix];
            }

            // We don't need to duplicate the DicomFile array, because it is identical.

            // A 2D Viewer window needs 3 things:
            //     a mutable array composed of DCMPix objects
            //     a mutable array composed of DicomFile objects
            //         (The number of DCMPix and DicomFile has to be EQUAL.)
            //     volumeData containing the images, represented in the DCMPix objects
            NSMutableArray* fileList = [viewerController fileList:timeIdx];
            if (new4DViewer == nil)
            {
                new4DViewer = [viewerController newWindow:newPixList :fileList :volData];
                [new4DViewer roiDeleteAll:self];
            }
            else
            {
                [new4DViewer addMovieSerie:newPixList :fileList :volData];
            }
        }
    }

    return new4DViewer;
}

- (void)extractSeriesInfo:(SeriesInfo*)info
       withProgressWindow:(LoadingImagesWindowController*)progWindow
{
    LOG4M_TRACE(logger_, @"Enter");


    BOOL keyFound = NO;  // used for finding first key image below
    unsigned numTimeImages = (unsigned)[viewerController maxMovieIndex];
    NSTimeInterval firstTime = 0.0;

    info.numTimeSamples = numTimeImages;
    info.slicesPerImage = [[viewerController pixList] count];
    info.isFlipped = [[viewerController imageView] flippedData];

    if (numTimeImages == 1)  // we have a 2D viewer
    {
        LOG4M_DEBUG(logger_, @"******** 2D viewer with %u slices. ***************", info.slicesPerImage);
    }
    else // we have a 4D viewer
    {
        LOG4M_DEBUG(logger_, @"******** 4D viewer with %u images and %u slices per image. ***************",
              info.numTimeSamples, info.slicesPerImage);
    }

    // initialise the progress indicator
    [progWindow setNumImages:info.numTimeSamples];

    NSArray* firstImage = [viewerController pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];

    info.sliceHeight = [firstPix pheight];
    info.sliceWidth = [firstPix pwidth];

    LOG4M_DEBUG(logger_, @"******** Slice height = %u, width = %u, size = %u pixels. ***************",
          info.sliceHeight, info.sliceWidth, info.sliceHeight * info.sliceWidth);

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        LOG4M_DEBUG(logger_, @"******** timeIdx = %u ***************", timeIdx);

        // Bump the progress indicator
        [progWindow incrementIndicator];

        // The ROIs for this image.
        NSArray* roiList = [viewerController roiList:timeIdx];

        // The array of slices in the image.
        NSArray* pixList = [viewerController pixList:timeIdx];

        // The list of DicomImage instances corresponding to the slices.
        NSArray* fileList = [viewerController fileList:timeIdx];

        unsigned numSlices = info.slicesPerImage;
        for (unsigned sliceIdx = 0; sliceIdx < numSlices; ++sliceIdx)
        {
            // DCMPix instance containing this slice
            DCMPix* curPix = [pixList objectAtIndex:sliceIdx];

            // The DicomImage instance containing this slice.
            DicomImage* curSlice = [fileList objectAtIndex:sliceIdx];
            BOOL isKey = [[curSlice isKeyImage] boolValue];
            if ((isKey) && (!keyFound))
            {
                // Image may be displayed flipped. We need the real index.
                info.keySliceIdx = sliceIdx;

                info.keyImageIdx = timeIdx;
                LOG4M_DEBUG(logger_, @"Key image index: %u (slice index %u)",
                            info.keyImageIdx, info.keySliceIdx);

                // The list of ROIs in this slice. Pick out either the first one named "Reg"
                // or the first one in the list
                NSArray* curRoiList = [roiList objectAtIndex:sliceIdx];
                if ((curRoiList != nil) && ([curRoiList count] > 0))
                {
                    ROI* roi = [curRoiList objectAtIndex:0];  // default
                    BOOL found = NO;
                    for (ROI* r in curRoiList)
                    {
                        if ((!found) && ([[r name] isEqualToString:@"Reg"]))
                        {
                            found = YES;
                            roi = r;
                        }
                    }

                    info.firstROI = roi;

                    LOG4M_DEBUG(logger_, @"Using ROI named \'%@\' to generate registration region.",
                                [info.firstROI name]);
                    LOG4M_DEBUG(logger_, @"ROI points: \'%@\'.", [info.firstROI points]);
                }
            }

            NSString* filePath = [curPix sourceFile];
            DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];

            DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"AcquisitionTime"];
            DCMAttribute* attr = [dcmObj attributeForTag:tag];
            NSTimeInterval acqTime = [[attr value] timeIntervalSinceReferenceDate];
            if ((timeIdx == 0) && (sliceIdx == 0))
                firstTime = acqTime;

            if (sliceIdx == 0) // do this once per time increment
            {
                NSTimeInterval normalisedTime = acqTime - firstTime;
                [info addAcqTime:normalisedTime];
                LOG4M_DEBUG(logger_, @"Normalised time of acquisition = %f", normalisedTime);
            }
        }
    }
}

- (void)parseDataSet
{
    LOG4M_TRACE(logger_, @"Enter");

    unsigned numTimeImages = (unsigned)[viewerController maxMovieIndex];
    NSTimeInterval firstTime = 0.0;
    unsigned slicesPerImage = [[viewerController pixList] count];

    if (numTimeImages == 1)  // we have a 2D viewer
    {
        LOG4M_DEBUG(logger_, @"******** 2D viewer with %u slices. ***************", slicesPerImage);
    }
    else // we have a 4D viewer
    {
        LOG4M_DEBUG(logger_, @"******** 4D viewer with %u images and %u slices per image. ***************",
              numTimeImages, slicesPerImage);
    }

    NSArray* firstImage = [viewerController pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];
    unsigned sliceHeight = [firstPix pheight];
    unsigned sliceWidth = [firstPix pwidth];
    unsigned sliceSize = sliceHeight * sliceWidth;
    LOG4M_DEBUG(logger_, @"******** Slice height = %u, width = %u, size = %u pixels. ***************",
          sliceHeight, sliceWidth, sliceSize);

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        LOG4M_DEBUG(logger_, @"******** timeIdx = %u ***************", timeIdx);

        float* imageBuff = [viewerController volumePtr:timeIdx];
        LOG4M_DEBUG(logger_, @"******** volumePtr = %p. ***************", imageBuff);

        NSArray* roiList = [viewerController roiList:timeIdx];
        NSArray* pixList = [viewerController pixList:timeIdx];
        NSArray* fileList = [viewerController fileList:timeIdx];

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

@end
