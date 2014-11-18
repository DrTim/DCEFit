//
//  IndexConverter.h
//  DCEFit
//
//  Created by Tim Allman on 2014-10-28.
//
//

@class ViewerController;

@interface IndexConverter : NSObject

/**
 * Convert 1-based OsiriX slice number to 0-based index, taking into account
 * the OsiriX 'flippedData' flag.
 * @param number The visible slice number
 * @param viewerController The ViewerController instance.
 * @return The index of the slice in memory.
 */
+ (unsigned)sliceNumberToIndex:(unsigned)number viewerController:(ViewerController*)viewer;

/**
 * Convert to 0-based index to 1-based OsiriX slice number, taking into account
 * the OsiriX 'flippedData' flag.
 * @param index The index of the slice in memory.
 * @param viewerController The ViewerController instance.
 * @return The visible slice number.
 */
+ (unsigned)indexToSliceNumber:(unsigned)index viewerController:(ViewerController*)viewer;

@end
