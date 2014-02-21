//
//  RegistrationDefs.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#ifndef DCEFit_RegistrationDefs_h
#define DCEFit_RegistrationDefs_h

#include <itkMacro.h>
#include <itkImage.h>
#include <itkGDCMSeriesFileNames.h>
#include <itkImageSeriesReader.h>
#include <itkImageToImageMetric.h>
#include <itkMattesMutualInformationImageToImageMetric.h>
#include <itkMeanSquaresImageToImageMetric.h>
#include <itkSingleValuedNonLinearOptimizer.h>
#include <itkLBFGSOptimizer.h>
#include <itkLBFGSBOptimizer.h>
#include <itkGradientDescentOptimizer.h>
#include <itkRegularStepGradientDescentOptimizer.h>
#include <itkVersorRigid3DTransformOptimizer.h>
#include <itkBSplineTransform.h>
#include <itkCenteredRigid2DTransform.h>
#include <itkVersorRigid3DTransform.h>
#include <itkCenteredTransformInitializer.h>
#include <itkCenteredVersorTransformInitializer.h>
#include <itkBSplineTransformInitializer.h>
#include <itkBSplineInterpolateImageFunction.h>
#include <itkMultiResolutionImageRegistrationMethod.h>
#include <itkMultiResolutionPyramidImageFilter.h>
#include <itkImportImageFilter.h>
#include <itkExtractImageFilter.h>
#include <itkBlobSpatialObject.h>

#include "ProjectDefs.h"

/// The working pixel type
typedef float TPixel;

// Describe the slices that we will register
typedef itk::Image<TPixel, 2u> Image2D;

// The 3D image that we read in
typedef itk::Image<TPixel, 3u> Image3D;

// Image IO support
typedef itk::GDCMSeriesFileNames DicomNameGenerator;
typedef itk::ImageSeriesReader<Image3D> SeriesReader;

// Metadata dictionaries
typedef itk::MetaDataDictionary MetaDataDictionary;
typedef SeriesReader::DictionaryArrayType MetaDataDictionaryArray;

// The registration object types
typedef itk::MultiResolutionImageRegistrationMethod<Image2D, Image2D> Registration2D;
typedef itk::MultiResolutionPyramidImageFilter<Image2D, Image2D> ImagePyramid2D;
typedef itk::MultiResolutionImageRegistrationMethod<Image3D, Image3D> Registration3D;
typedef itk::MultiResolutionPyramidImageFilter<Image3D, Image3D> ImagePyramid3D;

// Typedefs of metrics we will be selecting
typedef itk::ImageToImageMetric<Image2D, Image2D> ImageToImageMetric2D;
typedef itk::MattesMutualInformationImageToImageMetric<Image2D, Image2D> MMIImageToImageMetric2D;
typedef itk::MeanSquaresImageToImageMetric<Image2D, Image2D> MSImageToImageMetric2D;
typedef itk::ImageToImageMetric<Image3D, Image3D> ImageToImageMetric3D;
typedef itk::MattesMutualInformationImageToImageMetric<Image3D, Image3D> MMIImageToImageMetric3D;
typedef itk::MeanSquaresImageToImageMetric<Image3D, Image3D> MSImageToImageMetric3D;

// Typedefs for the optimizers
typedef itk::SingleValuedNonLinearOptimizer SingleValuedNonLinearOptimizer;
typedef itk::LBFGSOptimizer LBFGSOptimizer;
typedef itk::LBFGSBOptimizer LBFGSBOptimizer;
typedef itk::GradientDescentOptimizer GDOptimizer;
typedef itk::RegularStepGradientDescentOptimizer RSGDOptimizer;
typedef itk::VersorRigid3DTransformOptimizer VersorOptimizer;

// Typedefs for transforms
typedef itk::CenteredRigid2DTransform<double> CenteredRigid2DTransform;
typedef itk::VersorRigid3DTransform<double> VersorTransform3D;
typedef itk::BSplineTransform<double, 3u, BSPLINE_ORDER> BSplineTransform3D;
typedef itk::BSplineTransform<double, 2u, BSPLINE_ORDER> BSplineTransform2D;

// Typedefs for transform initialisers
typedef itk::CenteredTransformInitializer<CenteredRigid2DTransform, Image2D, Image2D>
        CenteredTransformInitializer2D;
typedef itk::CenteredVersorTransformInitializer<Image3D, Image3D>
        CenteredVersorTransformInitializer3D;
typedef itk::BSplineTransformInitializer<BSplineTransform2D, Image2D> BSplineTransformInitializer2D;
typedef itk::BSplineTransformInitializer<BSplineTransform3D, Image3D> BSplineTransformInitializer3D;

// Typedefs for interpolators
typedef itk::LinearInterpolateImageFunction<Image2D, double> LinearInterpolator2D;
typedef itk::LinearInterpolateImageFunction<Image3D, double> LinearInterpolator3D;
typedef itk::BSplineInterpolateImageFunction<Image2D, double> BSplineInterpolator2D;
typedef itk::BSplineInterpolateImageFunction<Image3D, double> BSplineInterpolator3D;

// Typedefs for resamplers
typedef itk::ResampleImageFilter<Image2D, Image2D> ResampleFilter2D;
typedef itk::ResampleImageFilter<Image3D, Image3D> ResampleFilter3D;

// Typedef for the registration spatial object mask
typedef itk::BlobSpatialObject<2u> SpatialMask2D;
typedef itk::BlobSpatialObject<3u> SpatialMask3D;

// Filter to import the OsiriX image to itk
typedef itk::ImportImageFilter<TPixel, 3u> ImportImageFilter3D;

// Filter to extract 2D slice from 3D image.
typedef itk::ExtractImageFilter<Image3D, Image2D> ExtractSliceFilter;

// Continuous indices
typedef itk::ContinuousIndex<double, 2u> ContinuousIndex2D;
typedef itk::ContinuousIndex<double, 3u> ContinuousIndex3D;

#endif
