//
//  SeriesInfo.h
//  DCEFit
//
//  Created by Tim Allman on 2014-01-20.
//
//

#import <Foundation/Foundation.h>

@class ViewerController;
@class ROI;
@class ROIInfo;
@class Logger;
@class LoadingImagesWindowController;

@interface SeriesInfo : NSObject
{
    Logger* logger_;
    ViewerController* viewerController;
    unsigned numTimeSamples;
    unsigned sliceHeight;
    unsigned sliceWidth;
    unsigned slicesPerImage;
    BOOL flippedData;
    
    int roiImageIdx;
    int roiSliceIdx;
    ROI* regROI;
    //ROI* pcaROI;
    //ROI* selectedROI;
    //NSArray* selectedROIs;
    NSArray* roiInfoArray;
    NSMutableArray* acqTimeArray;
    NSMutableArray* acqTimeStringArray;
}

@property (assign) unsigned numTimeSamples; ///< The number of images in the time series.
@property (assign) unsigned sliceHeight;    ///< The height in pixels of a slice.
@property (assign) unsigned sliceWidth;     ///< The width in pixels of a slice.
@property (assign) unsigned slicesPerImage; ///< The number of slices in an image.
@property (assign) BOOL flippedData;          ///< Osirix numbers images backwards if true.
@property (assign) int roiImageIdx;     ///< The time image index containing the registration ROI.
@property (assign) int roiSliceIdx;     ///< The slice index in the image of the registration ROI.
@property (assign) ROI* regROI;             ///< The first ROI defining the registration region.
//@property (assign) ROI* pcaROI;
//@property (assign) ROI* selectedROI;
//@property (assign) NSArray* selectedROIs;
@property (retain) NSArray* roiInfoArray;


/**
 * Init with current ViewerController.
 * @param viewer The current ViewerCintroller instance.
 */
- (id)initWithViewer:(ViewerController*)viewer;

/**
 * Load the information in the viewer.
 * @param progWindow A progress window. This may be nil. Otherwise it should be 
 * an initialised instance.
 */
- (void)extractSeriesInfo:(LoadingImagesWindowController*)progWindow;

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

/**
 * Convert 1-based OsiriX slice number to 0-based index, taking into account
 * the OsiriX 'flippedData' flag.
 * @param number The visible slice number
 * @return The index of the slice in memory.
 */
- (unsigned)sliceNumberToIndex:(unsigned)number;

/**
 * Convert to 0-based index to 1-based OsiriX slice number, taking into account
 * the OsiriX 'flippedData' flag.
 * @param index The index of the slice in memory.
 * @return The visible slice number.
 */
- (unsigned)indexToSliceNumber:(unsigned int)index;

/**
 * Find the index of an ROI in the roiInfoArray.
 * @param roi The ROI we wish to find.
 * @return The index of the ROI or -1 if not found.
 */
- (int)findIndexOfRoi:(ROI*)roi;

/**
 * Determines whether the ROI is selected in the viewer. This works by comparing pointer 
 * values as opposed to comparing for equality.
 * @param roi The ROI to test.
 * @param viewer The viewer that may or may not be showing the selected (or not) ROI.
 * @return YES if the ROI is selected, NO otherwise.
 */
+ (BOOL)roiIsSelected:(ROI*)roi viewerController:(ViewerController*)viewer;

@end
