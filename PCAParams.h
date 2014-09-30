//
//  PCAParams.h
//  DCEFit
//
//  Created by Tim Allman on 2014-09-27.
//
//

#import <Foundation/Foundation.h>

@class ROI;

@interface PCAParams : NSObject
{
    Logger* mLogger;

    /// Series description in generated parametric images
    NSString* seriesDescription;

    ROI* roi;                        ///< The ROI we will use.
    unsigned numImages;              ///< Number of images in time series.
    unsigned slicesPerImage;         ///< Number of slices in each image.
    BOOL flippedData;                ///< True if Osirix 'flipped' flag is set.


}

@end
