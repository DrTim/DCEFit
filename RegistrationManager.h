//
//  RegistrationManager.h
//  DCEFit
//
//  Created by Tim Allman on 2013-05-02.
//
//

#import <Foundation/Foundation.h>

#import "ItkTypedefs.h"
#import "RegistrationObserverBSpline.h"

#include "ImageSlicer.h"

#include "ItkRegistrationParams.h"

@class RegistrationParams;
@class ViewerController;
@class ProgressWindowController;
@class ImageImporter;
@class RegisterImageOp;
@class SeriesInfo;

@interface RegistrationManager : NSObject
{
    Logger* logger_;

    RegistrationParams* params;
    ItkRegistrationParams* itkParams;
    ImageSlicer* slicer;
    ViewerController* viewer;
    ProgressWindowController* progressController_;
    ImageImporter* imageImporter;
    Image2D::RegionType registrationRegion;
    NSOperationQueue* opQueue;
    RegisterImageOp* op;
    SeriesInfo* seriesInfo_;
}

@property (readonly) ItkRegistrationParams* itkParams;
@property (readonly) ProgressWindowController* progressController;
@property (readonly) ViewerController* viewer;
@property (readonly) SeriesInfo* seriesInfo;

- (id)initWithViewer:(ViewerController *)viewerController
              Params:(RegistrationParams*)regParams
      ProgressWindow:(ProgressWindowController*)progController
          SeriesInfo:(SeriesInfo*)seriesInfo;

- (Image3D::Pointer)imageAtIndex:(unsigned)imageIdx;

- (void)insertImageIntoViewer:(Image3D::Pointer)image Index:(unsigned)imageIndex;

- (void)insertSliceIntoViewer:(Image2D::Pointer)slice ImageIndex:(unsigned)imageIndex
                   SliceIndex:(unsigned)sliceIndex;

- (Image2D::Pointer)slice:(unsigned)sliceIndex FromImage:(unsigned)imageIndex;

- (void)doRegistration;

- (void)cancelRegistration;

@end
