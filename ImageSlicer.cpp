//
//  ImageSlicer.cpp
//  DCEFit
//
//  Created by Tim Allman on 2013-09-12.
//
//

#include "ImageSlicer.h"

#include <stdexcept>

#include <boost/lexical_cast.hpp>

ImageSlicer::ImageSlicer()
{
    SetupLogger();
}

void ImageSlicer::AddImage(typename Image3D::Pointer image)
{
    images_.push_back(image);
}

typename Image2D::Pointer
        ImageSlicer::GetSlice2D(unsigned imageIdx, unsigned sliceIdx)
{
    if (imageIdx >= images_.size())
    {
        std::string msg = "ImageSlicer::GetSlice2D, ";
        msg += "imageNum = " + boost::lexical_cast<std::string>(imageIdx);
        msg += ", maximum value = " + boost::lexical_cast<std::string>(images_.size());
        throw std::range_error(msg);
    }

    // Instantiate a filter to effect dimensional reduction
    ExtractSliceFilter::Pointer filter = ExtractSliceFilter::New();

    // Get the start and size of the 3D image
    typename Image3D::RegionType sliceRegion = images_[imageIdx]->GetLargestPossibleRegion();
    unsigned numSlices = sliceRegion.GetSize(2);
    if (sliceIdx >= numSlices)
    {
        std::string msg = "ImageSlicer::GetSlice2D, ";
        msg += "sliceIdx = " + boost::lexical_cast<std::string>(sliceIdx);
        msg += ", maximum value = " + boost::lexical_cast<std::string>(numSlices);
        throw std::range_error(msg);
    }

    // Change the region to reflect what we want
    sliceRegion.SetSize(2, 0);             // triggers dimension reduction
    sliceRegion.SetIndex(2, sliceIdx);     // Get this slice

    // tell the filter about it
    filter->SetDirectionCollapseToIdentity();
    filter->SetExtractionRegion(sliceRegion);
    filter->SetInput(images_[imageIdx]);

    // Get the slice
    typename Image2D::Pointer slice = filter->GetOutput();
    filter->Update();

    return slice;
}

void ImageSlicer::SetSlice2D(typename Image2D::Pointer sliceImage,
                                unsigned imageIdx, unsigned sliceIdx)
{
    if (imageIdx >= images_.size())
    {
        std::string msg = "ImageSlicer::SetSlice2D, ";
        msg += "imageIdx = " + boost::lexical_cast<std::string>(imageIdx);
        msg += ", maximum value = " + boost::lexical_cast<std::string>(images_.size());
        throw std::range_error(msg);
    }

    // Get the dimensions of the image in pixels
    Image3D::SizeType dims = images_[imageIdx]->GetLargestPossibleRegion().GetSize();
    unsigned numSlices = dims[2];
    if (sliceIdx >= numSlices)
    {
        std::string msg = "ImageSlicer::SetSlice2D, ";
        msg += "sliceIdx = " + boost::lexical_cast<std::string>(sliceIdx);
        msg += ", maximum value = " + boost::lexical_cast<std::string>(numSlices);
        throw std::range_error(msg);
    }

    // number of pixels in one slice
    unsigned numPixels = dims[0] * dims[1];

    // offset (in pixels) where the slice starts in the data buffer
    unsigned offset = dims[0] * dims[1] * sliceIdx;

    // the source buffer
    const Image2D::PixelType* srcBuffer = sliceImage->GetBufferPointer();

    // the destination slice in the destination buffer.
    Image3D::PixelType* dstBuffer = images_[imageIdx]->GetBufferPointer() + offset;

    // copy the data
    size_t numBytes = numPixels * sizeof(Image3D::PixelType);
    memcpy(dstBuffer, srcBuffer, numBytes);
}

typename Image3D::Pointer ImageSlicer::GetImage(unsigned imageIdx)
{
    if (imageIdx >= images_.size())
    {
        std::string msg = "ImageSlicer::GetImage, ";
        msg += "imageIdx = " + boost::lexical_cast<std::string>(imageIdx);
        msg += ", maximum value = " + boost::lexical_cast<std::string>(images_.size());
        throw std::range_error(msg);
    }

    return images_[imageIdx];
}

void ImageSlicer::SetImage(typename Image3D::Pointer image, unsigned imageIdx)
{
    if (imageIdx >= images_.size())
    {
        std::string msg = "ImageSlicer::SetImage, ";
        msg += "imageIdx = " + boost::lexical_cast<std::string>(imageIdx);
        msg += ", maximum value = " + boost::lexical_cast<std::string>(images_.size());
        throw std::range_error(msg);
    }

    images_[imageIdx] = image;
}

void ImageSlicer::SetupLogger()
{
    std::string name = LOGGER_NAME;
    name += ".ImageSlicer";
    logger_ = log4cplus::Logger::getInstance(name);
}

