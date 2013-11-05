//
//  RegistrationManager.h
//  DCEFit
//
//  Created by Tim Allman on 2013-05-02.
//
//

#import <Foundation/Foundation.h>

#import "ItkTypedefs.h"
#import "RegistrationObserver.h"

#include "ImageSlicer.h"

#include "ItkRegistrationParams.h"

@class RegistrationParams;
@class ViewerController;
@class ProgressWindowController;
@class ImageImporter;
@class RegisterImageOp;

@interface RegistrationManager : NSObject
{
    Logger* logger_;

    RegistrationParams* params;
    ItkRegistrationParams* itkParams;
    ImageSlicer* slicer;
    ViewerController* viewer;
    ProgressWindowController* progressController_;
    ImageImporter* imageImporter;
    Image2DType::RegionType registrationRegion;
    NSOperationQueue* opQueue;
    RegisterImageOp* op;
}

@property (readonly, assign) ItkRegistrationParams* itkParams;
@property (readonly, assign) ProgressWindowController* progressController;

- (id)initWithViewer:(ViewerController *)viewerController
              Params:(RegistrationParams*)regParams
      ProgressWindow:(ProgressWindowController*)progController;

- (Image3DType::Pointer)getImage;

- (void)insertSliceIntoViewer:(Image2DType::Pointer)slice SliceIndex:(unsigned)sliceIndex;

//- (void)insertCroppedSliceIntoViewer:(Image2DType::Pointer)slice SliceIndex:(unsigned)sliceIndex;

- (Image2DType::Pointer)getSliceFromImage:(unsigned)sliceIndex;

//- (Image2DType::Pointer)getCroppedSliceFromImage:(unsigned)sliceIndex;

- (void)doRegistration;

- (void)cancelRegistration;


@end
