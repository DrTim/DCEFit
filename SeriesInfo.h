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
    NSMutableArray* acqTimeStringArray;
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
 * Append the normalised acquisition time for image.
 * @param time The time at which image was acquired. First image time == 0.0.
 */
- (void)addAcqTime:(float)time;

/**
 * Retrieve the normalised acq. time for image at index.
 * @param index The index of the time image.
 */
- (float)acqTime:(unsigned)index;

/**
 * Append the acquisition time string for image.
 * @param timeStr The image acquisition time stamp as a string.
 */
- (void)addAcqTimeString:(NSString*)timeStr;

/**
 * Retrieve the image acquisition time stamp as a string at index.
 * @param index The index of the image.
 */
- (NSString*)acqTimeString:(unsigned)index;

@end
