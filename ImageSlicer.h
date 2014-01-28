//
//  ImageSlicer.h
//  DCEFit
//
//  Created by Tim Allman on 2013-09-12.
//
//

#ifndef __DCEFit__ImageSlicer__
#define __DCEFit__ImageSlicer__

#include <log4cplus/loggingmacros.h>

#include "ItkTypedefs.h"

#include <itkImage.h>
#include <itkImageSliceConstIteratorWithIndex.h>
#include <itkImageSliceIteratorWithIndex.h>
#include <itkImageLinearIteratorWithIndex.h>
#include <itkImageRegionIteratorWithIndex.h>
#include <itkExceptionObject.h>

#include <vector>

/**
 * This class takes an image and stores a region of it. Primarily it is
 * designed to allow easy access to slices which can be retrieved and
 * stored.
 */
class ImageSlicer
{
public:
    /**
     * Default constructor.
     */
    ImageSlicer();

    /**
     * Constructor with image and region. The image contained in the instance
     * is the part of the passed image contained in the region.
     * @param image The 3D image we want to work with.
     * @param region The 2D region that we will be extracting and inserting.
     */
    ImageSlicer(typename Image3D::Pointer inputImage);

    /**
     * Sets an image that we wish to slice.
     * @param image A 3D image.
     * @param imageNum The time
     */
    void AddImage(typename Image3D::Pointer image);

    /**
     * Get a copy of a slice of the image.
     * @param imageIdx The index of the image.
     * @param sliceIdx The index of the slice in the image.
     * @returns A copy of the data in the image slice.
     */
    typename Image2D::Pointer GetSlice2D(unsigned imageIdx, unsigned sliceIdx);

    /**
     * Store the slice back into the image.
     * @param sliceImage The 2D slice to store.
     * @param imageIdx The index of the image.
     * @param sliceIdx The index of the slice in the image.
     */
    void SetSlice2D(typename Image2D::Pointer sliceImage, unsigned imageIdx, unsigned sliceIdx);

    /**
     * Get a pointer to a stored 3D image.
     * @returns Pointer to the stored 3D image.
     */
    typename Image3D::Pointer GetImage(unsigned imageNum);
    
    /**
     * Copy an image into the slicer
     * @param image The 3D image
     * @param imageIndex The index of the image
    */
   void SetImage(typename Image3D::Pointer image, unsigned imageIndex);

    /**
     * Set up the log4cplus logger for this class
     */
    void SetupLogger();

private:
    log4cplus::Logger logger_;            /**< The logger. */
    std::vector<typename Image3D::Pointer> images_; /**< The contained image. */
};

#endif /* defined(__DCEFit__ImageSlicer__) */
