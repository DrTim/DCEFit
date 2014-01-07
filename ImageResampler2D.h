//
//  ImageResampler2D.h
//  DCEFit
//
//  Created by Tim Allman on 2013-12-19.
//
//

#ifndef __DCEFit__ImageResampler2D__
#define __DCEFit__ImageResampler2D__

#include <itkResampleImageFilter.h>
#include <itkTransform.h>
#include <itk

template <class ImageType, typename ScalarType>
class ImageResampler2D
{
    ImageResampler2D(const itk::Array<ScalarType>& parameters,
                     const typename itk::Transform<ScalarType, ImageType::ImageDimension,
                     ImageType::ImageDimension>& transform,
                     const typename ImageType::Pointer movingImage)
    : m_parameters(parameters), m_transform(transform), image(movingImage)
    {

    }

    ImageType::Pointer resample()

  private:
    const itk::Array<ScalarType>& m_parameters;
    itk::Transform<class TScalarType>& m_transform;
    ImageType& image;
//
//    transform->SetParameters(finalParameters);
//
//    if (itkParams_.deformShowField)
//    {
//        ImageTagger<Image2DType> tagImage(10);
//        tagImage(*(movingImage.GetPointer()));
//    }
//
//    ResampleFilterType::Pointer resampler = ResampleFilterType::New();
//    resampler->SetTransform(transform);
//    resampler->SetInput(movingImage);
//    resampler->SetSize(fixedImage_->GetLargestPossibleRegion().GetSize());
//    resampler->SetOutputOrigin(fixedImage_->GetOrigin());
//    resampler->SetOutputSpacing(fixedImage_->GetSpacing());
//    resampler->SetOutputDirection(fixedImage_->GetDirection());
//    resampler->SetDefaultPixelValue(0.0);
//    resampler->Update();
//
//    Image2DType::Pointer result = resampler->GetOutput();
//
//    return result;

};

#endif /* defined(__DCEFit__ImageResampler2D__) */
