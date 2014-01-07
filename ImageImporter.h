//
//  ImageImporter.h
//  DCEFit
//
//  Created by Tim Allman on 2013-05-02.
//
//

#import <Foundation/Foundation.h>

@class ViewerController;

#include "ItkTypedefs.h"

@interface ImageImporter : NSObject
{
    Logger* logger_;
    ViewerController* viewer;
    unsigned slicesPerTimeIncr;
    float timeIncrement;
}

/**
 * Initialise with the OsiriX viewer controller.
 * @param viewerController The OsiriX viewer controller.
 * @return The instance (self).
 */
- (id)initWithViewerController:(ViewerController*)viewerController;

/**
 * Get the ITK image. This image will not contain all of the metadata.
 * OsiriX should be queried for those.
 * This function is intended mainly to get the data for further processing.
 * @returns The ITK image;
 */
- (Image3DType::Pointer)getImage;


/**
 * Get the number of 2D slices in a time increment. A value of 1 indicates
 * one 2D slice per time. A value >1 indicates that the time slices
 * are 3D volumes.
 *
 * @returns The number of 2D slices in a time increment.
 */
- (unsigned)slicesPerTimeIncrement;

/**
 * Get time increment in the 4D series.
 *
 * @returns The time increment in the 4D series in seconds.
 */
- (float)timeIncrement;

@end
