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

void ImageSlicer::SetImage(typename Image3DType::Pointer image)
{
    image_ = image;
}

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

