//
//  ImageSlicer.cpp
//  DCEFit
//
//  Created by Tim Allman on 2013-09-12.
//
//

#include "ImageSlicer.h"

ImageSlicer::ImageSlicer()
{
    SetupLogger();
}


ImageSlicer::ImageSlicer(typename Image3DType::Pointer inputImage)
: image_(inputImage)
{
    SetupLogger();
}

//ImageSlicer::ImageSlicer(typename Image3DType::Pointer inputImage,
//                         const typename Image2DType::RegionType& region)
//: image_(inputImage), region_(region)
//{
//    SetupLogger();
//}

void ImageSlicer::SetImage(typename Image3DType::Pointer image)
{
    image_ = image;
}

//void ImageSlicer::SetRegion(const typename Image2DType::RegionType& region)
//{
//    region_ = region;
//}

typename ImageSlicer::Image2DType::Pointer
        ImageSlicer::GetSlice2D(unsigned sliceNum)
{
    // Instantiate a filter to effect dimensional reduction
    ExtractSliceFilterType::Pointer filter = ExtractSliceFilterType::New();

    // Get the start and size of the 3D image
    typename Image3DType::RegionType sliceRegion = image_->GetLargestPossibleRegion();

    // Change the region to reflect what we want
    sliceRegion.SetSize(2, 0);             // triggers dimension reduction
    sliceRegion.SetIndex(2, sliceNum);     // Get this slice

    // tell the filter about it
    filter->SetDirectionCollapseToIdentity();
    filter->SetExtractionRegion(sliceRegion);
    filter->SetInput(image_);

    // Get the slice
    typename Image2DType::Pointer slice = filter->GetOutput();
    filter->Update();

    /*
    // Reset the origin to (0.0, 0.0) for internal use
    typename Image2DType::PointType sliceOrigin;
    for (unsigned idx = 0; idx < slice->GetImageDimension(); ++idx)
        sliceOrigin[idx] = 0.0;
    slice->SetOrigin(sliceOrigin);
     */
    
    //slice->Print(std::cout);

    return slice;
}

void ImageSlicer::SetSlice2D(typename Image2DType::Pointer sliceImage,
                                 unsigned sliceNum)
{
    // Get the dimensions of the image in pixels
    Image3DType::SizeType dims = image_->GetLargestPossibleRegion().GetSize();

    // number of pixels in one slice
    unsigned numPixels = dims[0] * dims[1];

    // offset (in pixels) where the slice starts in the data buffer
    unsigned offset = dims[0] * dims[1] * sliceNum;

    // the source buffer
    const Image2DType::PixelType* srcBuffer = sliceImage->GetBufferPointer();

    // the destination slice in the destination buffer.
    Image3DType::PixelType* dstBuffer = image_->GetBufferPointer() + offset;

    // copy the data
    size_t numBytes = numPixels * sizeof(Image3DType::PixelType);
    memcpy(dstBuffer, srcBuffer, numBytes);
}

/* Test before using. *************************************
typename ImageSlicer::Image2DType::Pointer
        ImageSlicer::GetCroppedSlice2D(unsigned sliceNum)
{
    // Take a slice from the contained 3D image. If the region is the same, just return it.
    typename Image2DType::Pointer fullSlice = GetFullSlice2D(sliceNum);
    if (region_ == fullSlice->GetLargestPossibleRegion())
        return fullSlice;

    // Make a new image the size of this->region to return
    typename Image2DType::Pointer slice = Image2DType::New();
    typename Image2DType::RegionType largestRegion = fullSlice->GetLargestPossibleRegion();

    // Make sure that the cropping region is inside the full image.
    // Note the backward (or at least awkward) syntax of IsInside().
    if (!largestRegion.IsInside(region_))
    {
        itk::InvalidArgumentError ex;
        ex.SetDescription("Registration region not inside image slice.");
        LOG4CPLUS_FATAL(logger_, "Registration region not inside image slice.");
        throw ex;
    }

    // Allocate memory for the new data
    typename Image2DType::RegionType outputRegion;
    outputRegion.SetSize(region_.GetSize());
    slice->SetRegions(outputRegion);
    slice->Allocate();

    // Adjust the new origin to reflect the cropping
    //typename Image2DType::PointType inputOrigin = fullSlice->GetOrigin();
    typename Image2DType::SpacingType inputSpacing = fullSlice->GetSpacing();
    typename Image2DType::PointType sliceOrigin;
    for (unsigned idx = 0; idx < fullSlice->GetImageDimension(); ++idx)
        sliceOrigin[idx] = 0.0;
    slice->SetSpacing(inputSpacing);
    slice->SetOrigin(sliceOrigin);
    slice->FillBuffer(static_cast<TPixel>(0));

    // Set the source iterator to traverse the crop region of the full slice and
    // set the destination iterator to traverse the whole cropped slice.
    ConstImageRegionIterator2DType sourceIter(fullSlice, region_);
    ImageRegionIterator2DType destIter(slice, slice->GetBufferedRegion());

    // Copy the data
    for (sourceIter.GoToBegin(), destIter.GoToBegin(); !sourceIter.IsAtEnd();
         ++sourceIter, ++destIter)
    {
        destIter.Set(sourceIter.Get());
    }

    return slice;
}
*/

/* Test before using. ******************************************
void ImageSlicer::SetCroppedSlice2D(typename Image2DType::Pointer sliceImage, unsigned sliceNum)
{
    // Create a 3D ImageRegion that corresponds to the 2D slice region
    typename Image2DType::IndexType regionIndex = region_.GetIndex();
    typename Image3DType::IndexType sliceIndex;
    sliceIndex[0] = regionIndex[0];
    sliceIndex[1] = regionIndex[1];
    sliceIndex[2] = sliceNum;

    typename Image2DType::SizeType regionSize = region_.GetSize();
    typename Image3DType::SizeType sliceSize;
    sliceSize[0] = regionSize[0];
    sliceSize[1] = regionSize[1];
    sliceSize[2] = 1;

    typename Image3DType::RegionType region3d;
    region3d.SetIndex(sliceIndex);
    region3d.SetSize(sliceSize);

    // Set the source iterator to traverse the whole 2D image and
    // set the destination iterator to traverse the region inside the selected slice
    // inside the 3D image.
    ConstImageRegionIterator2DType sourceIter(sliceImage, sliceImage->GetBufferedRegion());
    ImageRegionIterator3DType destIter(image_, region3d);

    // Copy the data
    for (sourceIter.GoToBegin(), destIter.GoToBegin(); !sourceIter.IsAtEnd();
         ++sourceIter, ++destIter)
    {
        destIter.Set(sourceIter.Get());
    }

    //    image->Print(std::cout);
}
*/

typename ImageSlicer::Image3DType::Pointer ImageSlicer::GetImage()
{
    return image_;
}


unsigned ImageSlicer::GetNumSlices2D()
{
    return image_->GetBufferedRegion().GetSize()[2];
}


void ImageSlicer::SetupLogger()
{
    std::string name = LOGGER_NAME;
    name += ".ImageSlicer";
    logger_ = log4cplus::Logger::getInstance(name);
}

