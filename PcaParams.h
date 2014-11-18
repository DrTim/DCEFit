//
//  PcaParams.h
//  DCEFit
//
//  Created by Tim Allman on 2014-09-27.
//
//

#import <Foundation/Foundation.h>

@class ROI;

@interface PcaParams : NSObject
{
    Logger* mLogger;

    /// Series description in generated parametric images
    NSString* seriesDescription;

    NSInteger roiIndex;
    unsigned numImages;
    unsigned slicesPerImage;
    unsigned sliceIndex;
    BOOL flippedData;                
}

@property (copy) NSString* seriesDescription;
@property (assign) NSInteger roiIndex;       ///< The ROI we will use.Index of ROI in SeriesInfo.roiInfoArray
@property (assign) unsigned numImages;              ///< Number of images in time series.
@property (assign) unsigned slicesPerImage;         ///< Number of slices in each image.
@property (assign) unsigned sliceIndex;             ///< The index of the slice of interest. 
@property (assign) BOOL flippedData;                ///< True if Osirix 'flipped' flag is set.

@end
