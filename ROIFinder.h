//
//  ROIFinder.h
//  DCEFit
//
//  Created by Tim Allman on 2014-10-20.
//
//

#import <Foundation/Foundation.h>

@class ViewerController;
@class ROI;
@class DCMPix;

@interface ROIFinder : NSObject
{
    ViewerController* viewer;
}

- (id)initWithViewer:(ViewerController*)viewerController;

// Extract the values and coordinates for the ROIs in one slice
- (NSArray*)extractRoiInfo:(NSArray*)roiList inSlice:(DCMPix*)pixList imageIndex:(NSUInteger)imageIdx
                       sliceIndex:(NSUInteger)sliceIdx;

// Extract the values and coordinates for the ROIs in one image, potentially
// with more than one slice.
- (NSArray*)extractRoiInfo:(NSArray*)roiListList inImage:(NSArray*)pixListList imageIndex:(NSUInteger)imageIdx;

// Extract the values and coordinates for the ROIs in the whole series.
- (NSArray*)extractRoiInfoInSeries;


@end
