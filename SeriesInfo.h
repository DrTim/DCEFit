//
//  SeriesInfo.h
//  DCEFit
//
//  Created by Tim Allman on 2014-01-20.
//
//

#import <Foundation/Foundation.h>

@class ROI;

@interface SeriesInfo : NSObject
{
    unsigned numTimeSamples;
    unsigned sliceHeight;
    unsigned sliceWidth;
    unsigned slicesPerImage;
    BOOL isFlipped;
    
    int keyImageIdx;
    int keySliceIdx;
    ROI* firstROI;
    NSMutableArray* acqTimeArray;
}

@property (assign) unsigned numTimeSamples; // The number of images in the time series.
@property (assign) unsigned sliceHeight;    // The height in pixels of a slice.
@property (assign) unsigned sliceWidth;     // The width in pixels of a slice.
@property (assign) unsigned slicesPerImage; // The number of slices in an image.
@property (assign) BOOL isFlipped;          // Osirix numbers images backwards if true.
@property (assign) int keyImageIdx;         // The time image index containing the key slice.
@property (assign) int keySliceIdx;         // The slice index in the image of the key slice.
@property (assign) ROI* firstROI;           // The first ROI in the key slice.

/**
 * Append the acquisition time for image.
 * @param time The time at which image was acquired. First image time == 0.0.
 */
- (void)addAcqTime:(float)time;

/**
 * Retrieve the acq. time for image at index.
 * @param index The index of the time image.
 */
- (float)acqTime:(unsigned)index;

@end
