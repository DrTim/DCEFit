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
}

/**
 * Initialise with the OsiriX viewer controller.
 * @param viewerController The OsiriX viewer controller.
 * @return The instance (self).
 */
- (id)initWithViewerController:(ViewerController*)viewerController;

/**
 * Get the OsiriX image in ITK format. This image will not contain all of
 * the metadata. OsiriX should be queried for those.
 * This function is intended mainly to get the data for further processing.
 * @returns The ITK image;
 */
- (Image3D::Pointer)getImageAtIndex:(unsigned)imageNum;

@end
