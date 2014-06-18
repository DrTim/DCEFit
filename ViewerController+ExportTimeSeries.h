//
//  ViewerController+ExportTimeSeries.h
//  DCEFit
//
//  Created by Tim Allman on 2014-01-23.
//
//

#import <OsiriXAPI/ViewerController.h>

@interface ViewerController(ExportTimeSeries)

/**
 * Exports all of the 4D series to the OsiriX database. This is done as a
 * category because ViewerController (in OsiriX) does not have this functionality.
 * @param seriesDescription The new series description.
 */
- (void)exportAllImages4D:(NSString*)seriesDescription;

@end
