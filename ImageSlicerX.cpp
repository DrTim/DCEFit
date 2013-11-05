//
//  ImageSlicer.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-09-11.
//
//

#include "ImageSlicer.h"

template <class TPixel>
ImageSlicer<TPixel>::ImageSlicer()
{
    SetupLogger();
}

template <class TPixel>
ImageSlicer<TPixel>::ImageSlicer(typename Image3DType::Pointer inputImage,
                                 const typename Image2DType::RegionType& region)
: ImageSlicer(), image(inputImage), region(region)
{
}

template <class TPixel>
void ImageSlicer<TPixel>::SetImage(typename Image3DType::Pointer image)
{
    this->image = image;
}

template <class TPixel>
void ImageSlicer<TPixel>::SetRegion(const typename Image2DType::RegionType& region)
{
    this->region = region;
}

template <class TPixel>
typename ImageSlicer<TPixel>::Image2DType::Pointer ImageSlicer<TPixel>::GetFullSlice2D(unsigned sliceNum)
{
    // Instantiate a filter to effect dimensional reduction
    ExtractSliceFilterType::Pointer filter = ExtractSliceFilterType::New();

    // Get the start and size of the 3D image
    typename Image3DType::RegionType sliceRegion = image->GetLargestPossibleRegion();

    // Change the region to reflect what we want
    sliceRegion.SetSize(2, 0);             // triggers dimension reduction
    sliceRegion.SetIndex(2, sliceNum);     // Get this slice

    // tell the filter about it
    filter->SetDirectionCollapseToIdentity();
    filter->SetExtractionRegion(sliceRegion);
    filter->SetInput(image);

    // Get the slice
    typename Image2DType::Pointer slice = filter->GetOutput();
    filter->Update();

    slice->Print(std::cout);

    return slice;
}

template <class TPixel>
typename ImageSlicer<TPixel>::Image2DType::Pointer ImageSlicer<TPixel>::GetCroppedSlice2D(unsigned sliceNum)
{
    // Take a slice from the contained 3D image. If the region is the same, just return it.
    typename Image2DType::Pointer fullSlice = GetFullSlice(sliceNum);
    if (region == fullSlice->GetLargestPossibleRegion())
        return fullSlice;

    // Make a new image the size of this->region to return
    typename Image2DType::Pointer slice = Image2DType::New();
    typename Image2DType::RegionType largestRegion = fullSlice->GetLargestPossibleRegion();

    // Make sure that the cropping region is inside the full image.
    // Note the backward (or at least awkward) syntax of IsInside().
    if (!largestRegion.IsInside(region))
    {
        itk::InvalidArgumentError ex;
        ex.SetDescription("Registration region not inside image slice.");
        LOG4CPLUS_FATAL(logger_, "Registration region not inside image slice.");
        throw ex;
    }

    // Allocate memory for the new data
    typename Image2DType::RegionType outputRegion;
    outputRegion.SetSize(region.GetSize());
    slice->SetRegions(outputRegion);
    slice->Allocate();

    // Adjust the new origin to reflect the cropping
    typename Image2DType::PointType inputOrigin = fullSlice->GetOrigin();
    typename Image2DType::SpacingType inputSpacing = fullSlice->GetSpacing();
    typename Image2DType::PointType sliceOrigin;

    for (unsigned idx = 0; idx < fullSlice->GetImageDimension(); ++idx)
        sliceOrigin[idx] = inputOrigin[idx] + inputSpacing[idx] * region.GetIndex()[idx];

    slice->SetSpacing(inputSpacing);
    slice->SetOrigin(sliceOrigin);
    slice->FillBuffer(static_cast<TPixel>(0));

    // Set the source iterator to traverse the crop region of the full slice and
    // set the destination iterator to traverse the whole cropped slice.
    ConstImageRegionIterator2DType sourceIter(fullSlice, region);
    ImageRegionIterator2DType destIter(slice, slice->GetBufferedRegion());

    // Copy the data
    for (sourceIter.GoToBegin(), destIter.GoToBegin(); !sourceIter.IsAtEnd(); ++sourceIter, ++destIter)
    {
        destIter.Set(sourceIter.Get());
    }

    return slice;
}

template <class TPixel>
void ImageSlicer<TPixel>::SetFullSlice2D(typename Image2DType::Pointer sliceImage, unsigned sliceNum)
{
    //sliceImage->Print(std::cout);

    // Set up the source iterator. The source is the argument "sliceImage".
    typedef itk::ImageLinearIteratorWithIndex<Image2DType> Iterator2DType;
    Iterator2DType sourceIter(sliceImage, sliceImage->GetBufferedRegion());
    sourceIter.SetDirection(0);

    // Set up the destination iterator. The destination is the member "image"
    typedef itk::ImageSliceIteratorWithIndex<Image3DType> Iterator3DType;
    Iterator3DType destIter(image, image->GetBufferedRegion());
    destIter.SetFirstDirection(0);
    destIter.SetSecondDirection(1);

    // This describes the beginning of the destination slice in the 3D image
    typename Image3DType::IndexType sliceIndex;
    sliceIndex[0] = 0;
    sliceIndex[1] = 0;
    sliceIndex[2] = sliceNum;

    // Initialise iterator locations and do the copying
    sourceIter.GoToBegin();
    destIter.SetIndex(sliceIndex);
    destIter.GoToBegin();
    while (!destIter.IsAtEndOfSlice())
    {
        while (!destIter.IsAtEndOfLine())
        {
             destIter.Set(sourceIter.Get());
            ++sourceIter;
            ++destIter;
        }
        sourceIter.NextLine();
        destIter.NextLine();
    }
}

template <class TPixel>
typename Image3DType::Pointer ImageSlicer<TPixel>::GetImage()
{
    return image;
}

template <class TPixel>
unsigned ImageSlicer<TPixel>::GetNumSlices2D()
{
    return image->GetBufferedRegion().GetSize()[2];
}

template <class TPixel>
void ImageSlicer<TPixel>::SetupLogger()
{
    std::string name = LOGGER_NAME;
    name += ".ImageSlicer";
    logger_ = log4cplus::Logger::getInstance(name);
}

template <class TPixel>
void ImageSlicer<TPixel>::SetSlice(typename Image2DType::Pointer sliceImage, unsigned sliceNum)
{
    // Create a 3D ImageRegion that corresponds to the 2D slice region
    typename Image2DType::IndexType regionIndex = region.GetIndex();
    typename Image3DType::IndexType sliceIndex;
    sliceIndex[0] = regionIndex[0];
    sliceIndex[1] = regionIndex[1];
    sliceIndex[2] = sliceNum;

    typename Image2DType::SizeType regionSize = region.GetSize();
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
    ImageRegionIterator3DType destIter(image, region3d);

    // Copy the data
    for (sourceIter.GoToBegin(), destIter.GoToBegin(); !sourceIter.IsAtEnd(); ++sourceIter, ++destIter)
    {
        destIter.Set(sourceIter.Get());
    }
    
    //    image->Print(std::cout);
}

