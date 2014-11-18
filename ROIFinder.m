//
//  ROIFinder.m
//  DCEFit
//
//  Created by Tim Allman on 2014-10-20.
//
//

#import "ROIFinder.h"
#import "ROIInfo.h"
#import "SeriesInfo.h"
#import "IndexConverter.h"

#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>

@implementation ROIFinder

- (id)initWithViewer:(ViewerController *)viewerController
{
    self = [super init];
    if (self)
    {
        viewer = viewerController;
    }
    return self;
}

// Extract the values and coordinates for the ROIs in one slice
- (NSArray*)extractRoiInfo:(NSArray*)roiList inSlice:(DCMPix*)pix imageIndex:(NSUInteger)imageIdx
                              sliceIndex:(NSUInteger)sliceIdx
{
    
    NSMutableArray* retVal = [NSMutableArray array];

    unsigned sliceNum = [IndexConverter indexToSliceNumber:sliceIdx viewerController:viewer];

    for (ROI* roi in roiList)
    {
        // These ROI types do not define regions so we ignore them
        if ((roi.type != tText) && (roi.type != tMesure) && (roi.type != tArrow) && (roi.type != t2DPoint))
        {
            ROIInfo* ri = [[ROIInfo alloc] initWithSlice:pix roi:roi imageIndex:imageIdx
                                             sliceNumber:sliceNum];
            [retVal addObject:ri];
            [ri release];
        }
    }

    return retVal;
}

// Extract the values and coordinates for the ROIs in one image, potentially
// with more than one slice.
- (NSArray *)extractRoiInfo:(NSArray *)roiListList inImage:(NSArray *)pixList imageIndex:(NSUInteger)imageIdx
{
    NSMutableArray* retVal = [NSMutableArray array];

    int sliceIdx = 0;
    for (NSUInteger idx = 0; idx < roiListList.count; ++idx)
    {
        NSArray* roiList = [roiListList objectAtIndex:idx];
        if (roiList.count != 0)
        {
            DCMPix* curPix = [pixList objectAtIndex:idx];
            NSArray* array = [self extractRoiInfo:roiList inSlice:curPix imageIndex:imageIdx
                                                     sliceIndex:sliceIdx];
            [retVal addObjectsFromArray:array];
        }
        ++sliceIdx;
    }

    return retVal;
}

// Extract the values and coordinates for the ROIs in the whole series.
- (NSArray*)extractRoiInfoInSeries
{
    NSMutableArray* retVal = [NSMutableArray array];

    unsigned numTimeImages = (unsigned)[viewer maxMovieIndex];

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        // The ROIs and slices for this image.
        NSArray* roiListList = [viewer roiList:timeIdx];
        NSArray* pixList = [viewer pixList:timeIdx];

        // See if there are any ROIs in this image.
        BOOL roiFound = NO;
        for (NSArray* array in roiListList)
        {
            if (array.count != 0)
                roiFound = YES;
        }

        // Process image only if there is one or more ROIs.
        if (roiFound)
        {
            NSArray* array = [self extractRoiInfo:roiListList inImage:pixList imageIndex:timeIdx];
            [retVal addObjectsFromArray:array];
        }
    }
    
    return retVal;
}

@end
