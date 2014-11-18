//
//  SeriesInfo.m
//  DCEFit
//
//  Created by Tim Allman on 2014-01-20.
//
//

#import "SeriesInfo.h"
#import "LoadingImagesWindowController.h"
#import "ROIInfo.h"
#import "ROIFinder.h"

#import <Log4m/Log4m.h>

#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/ROI.h>

#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMCalendarDate.h>

@implementation SeriesInfo

@synthesize numTimeSamples;
@synthesize sliceHeight;
@synthesize sliceWidth;
@synthesize slicesPerImage;
@synthesize flippedData;
@synthesize roiImageIdx;
@synthesize roiSliceIdx;
@synthesize regROI;
//@synthesize pcaROI;
//@synthesize selectedROI;
//@synthesize selectedROIs;
@synthesize roiInfoArray;

- (id)initWithViewer:(ViewerController*)viewer
{
    self = [super init];
    if (self)
    {
        [self setupLogger];
        viewerController = viewer;
        roiImageIdx = -1;
        roiSliceIdx = -1;
        acqTimeArray = [[NSMutableArray array] retain];
        acqTimeStringArray = [[NSMutableArray array] retain];
        roiInfoArray = [[NSMutableArray array] retain];
    }

    return self;
}

- (void)dealloc
{
    [acqTimeArray release];
    [acqTimeStringArray release];
    [roiInfoArray release];

    [super dealloc];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".SeriesInfo"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (void)extractSeriesInfo:(LoadingImagesWindowController*)progWindow
{
    LOG4M_TRACE(logger_, @"Enter");

    // This is a public function which may be called multiple times.
    [acqTimeArray removeAllObjects];
    [acqTimeStringArray removeAllObjects];

    numTimeSamples = (unsigned)[viewerController maxMovieIndex];

    // initialise the progress indicator
    [progWindow setNumImages:numTimeSamples];

    NSTimeInterval firstTime = 0.0;

    slicesPerImage = [[viewerController pixList] count];
    flippedData = [[viewerController imageView] flippedData];

    if (numTimeSamples == 1)  // we have a 2D viewer
    {
        LOG4M_DEBUG(logger_, @"2D viewer with %u slices.", slicesPerImage);
    }
    else // we have a 4D viewer
    {
        LOG4M_DEBUG(logger_, @"4D viewer with %u images and %u slices per image.",
                    numTimeSamples, slicesPerImage);
    }

    NSArray* firstImage = [viewerController pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];

    sliceHeight = [firstPix pheight];
    sliceWidth = [firstPix pwidth];

    LOG4M_DEBUG(logger_, @"Slice height = %u, width = %u, size = %u pixels.",
                sliceHeight, sliceWidth, sliceHeight * sliceWidth);

    //selectedROI = viewerController.selectedROI;
    //selectedROIs = viewerController.selectedROIs;

    for (unsigned timeIdx = 0; timeIdx < numTimeSamples; ++timeIdx)
    {
        LOG4M_DEBUG(logger_, @"******** timeIdx = %u ***************", timeIdx);

        // Bump the progress indicator
        [progWindow incrementIndicator];

        // The ROIs for this image.
        NSArray* roiList = [viewerController roiList:timeIdx];

        // The array of slices in the image.
        NSArray* pixList = [viewerController pixList:timeIdx];

        // The list of DicomImage instances corresponding to the slices.
        //NSArray* fileList = [viewerController1 fileList:timeIdx];

        unsigned numSlices = slicesPerImage;
        for (unsigned sliceIdx = 0; sliceIdx < numSlices; ++sliceIdx)
        {
            // DCMPix instance containing this slice
            DCMPix* curPix = [pixList objectAtIndex:sliceIdx];

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
                        regROI = r;
                        roiSliceIdx = sliceIdx;
                        roiImageIdx = timeIdx;
                        LOG4M_DEBUG(logger_, @"ROI image index: %u (slice index %u)",
                                    roiImageIdx, roiSliceIdx);
                    }
                }

                LOG4M_DEBUG(logger_, @"Using ROI named \'%@\' to generate registration region.",
                            [regROI name]);
                LOG4M_DEBUG(logger_, @"ROI points: \'%@\'.", [regROI points]);
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
                [self addAcqTimeString:dateStr];
                LOG4M_DEBUG(logger_, @"Acquisition time = %@", dateStr);

                NSTimeInterval normalisedTime = acqTime - firstTime;
                [self addAcqTime:normalisedTime];
                LOG4M_DEBUG(logger_, @"Normalised acquisition time = %fs", normalisedTime);
            }
        }
    }

    // Grab the list of ROIs.
    ROIFinder* rf = [[ROIFinder alloc] initWithViewer:viewerController];
    self.roiInfoArray = [rf extractRoiInfoInSeries];
    [rf release];
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:@"numTimeSamples:%u\n"
                      "sliceHeight: %u\n"
                      "sliceWidth: %u\n"
                      "slicesPerImage: %u\n"
                      "roiImageIdx: %d\n"
                      "roiSliceIdx: %d\n"
                      "regROI: %@\n"
                      "acqTimeArray: %@"
                      @"acqTimeStringArray: %@",
                      numTimeSamples, sliceHeight, sliceWidth,
                      slicesPerImage, roiImageIdx, roiSliceIdx,
                      regROI, acqTimeArray, acqTimeStringArray];
    return desc;
}


- (void)addAcqTime:(float)time
{
    NSNumber* num = [NSNumber numberWithFloat:time];
    [acqTimeArray addObject:num];
}

- (float)acqTime:(unsigned)index
{
    return [[acqTimeArray objectAtIndex:index] floatValue];
}

- (void)addAcqTimeString:(NSString*)timeStr
{
    [acqTimeStringArray addObject:timeStr];
}

- (NSString*)acqTimeString:(unsigned)index
{
    return [acqTimeStringArray objectAtIndex:index];
}

- (unsigned)sliceNumberToIndex:(unsigned)number
{
    if (flippedData)
        return slicesPerImage - number;
    else
        return number - 1;
}

- (unsigned)indexToSliceNumber:(unsigned int)index
{
    if (flippedData)
        return slicesPerImage - index;
    else
        return index + 1;
}

- (int)findIndexOfRoi:(ROI *)roi
{
    for (int idx = 0; idx < roiInfoArray.count; ++idx)
    {
        ROIInfo* ri = [roiInfoArray objectAtIndex:idx];
        if (roi == ri.roi)
            return idx;
    }

    return -1;
}

+ (BOOL)roiIsSelected:(ROI*)roi viewerController:(ViewerController *)viewer
{
    for (ROI* r in viewer.selectedROIs)
        if (r == roi)
            return YES;

    return NO;
}

@end
