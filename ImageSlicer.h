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

/**
 * This class takes an image and stores a region of it. Primarily it is
 * designed to allow easy access to slices which can be retrieved and
 * stored.
 */
class ImageSlicer
{
public:
    typedef itk::Image<TPixel, 3u > Image3DType; /**< Convenient typedef for arbitrary 3D image */
    typedef itk::Image<TPixel, 2u > Image2DType; /**< Convenient typedef for arbitrary 2D image */

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
    ImageSlicer(typename Image3DType::Pointer inputImage);
    //    ImageSlicer(typename Image3DType::Pointer inputImage,
    //                const typename Image2DType::RegionType& region);

    /**
     * Sets the image that we wish to slice.
     * @param image The 3D image.
     */
    void SetImage(typename Image3DType::Pointer image);

    /**
     * Sets the region of the image to use in Get/SetCroppedSlice2D.
     * @param region THe rectangular region in pixels.
     */
    //void SetRegion(const typename Image2DType::RegionType& region);

    /**
     * Get a copy of a slice of the image. The image is not cropped to the region.
     * @param sliceNum The index of the slice required.
     * @param region The region of the slice that we want.
     * @returns A copy of the data in the image slice.
     */
    typename Image2DType::Pointer GetSlice2D(unsigned sliceNum);

    /**
     * Store the slice back into the image.
     * @param sliceImage The 2D slice to store.
     * @param sliceNum The index of the slice.
     */
    void SetSlice2D(typename Image2DType::Pointer sliceImage, unsigned sliceNum);

    /**
     * Get a copy of a slice of the image. The image is cropped to the region.
     * @param sliceNum The index of the slice required.
     * @returns A copy of the data in the image slice, cropped to the region.
     */
    //typename Image2DType::Pointer GetCroppedSlice2D(unsigned sliceNum);

    /**
     * Store the slice back into the image.
     * @param sliceImage The 2D slice to store.
     * @param sliceNum The index of the slice.
     * @param region The region of the slice that the input image represents.
     */
    //void SetCroppedSlice2D(typename Image2DType::Pointer sliceImage, unsigned sliceNum);

    /**
     * Get a pointer to the stored 3D image.
     * @returns Pointer to the stored 3D image.
     */
    typename Image3DType::Pointer GetImage();
    
    /**
     * Get the number of slices in the image.
     * @returns The number of 2D slices in the 3D image.
     */
    unsigned GetNumSlices2D();

    /**
     * Set up the log4cplus logger for this class
     */
    void SetupLogger();

private:
    //    typedef itk::ImageRegionConstIteratorWithIndex<Image2DType> ConstImageRegionIterator2DType;
    //    typedef itk::ImageRegionIteratorWithIndex<Image2DType> ImageRegionIterator2DType;
    //    typedef itk::ImageRegionConstIteratorWithIndex<Image3DType> ConstImageRegionIterator3DType;
    //    typedef itk::ImageRegionIteratorWithIndex<Image3DType> ImageRegionIterator3DType;

    log4cplus::Logger logger_;
    typename Image3DType::Pointer image_;
    //typename Image2DType::RegionType region_;
    MetaDataDictionaryArrayType metaDataDictionary_;
    itk::Vector<float> sliceSpacing;
};

#endif /* defined(__DCEFit__ImageSlicer__) */
