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
#include <itkBSplineTransform.h>
#include <itkCenteredRigid2DTransform.h>
#include <itkMultiResolutionImageRegistrationMethod.h>
#include <itkMultiResolutionPyramidImageFilter.h>
#include <itkImportImageFilter.h>
#include <itkExtractImageFilter.h>
#include <itkBlobSpatialObject.h>

#include "ProjectDefs.h"

/// The working pixel type
typedef float TPixel;

// Describe the slices that we will register
const unsigned int SliceDimension = 2;
typedef itk::Image<TPixel, SliceDimension> Image2DType;

// The 3D image that we read in
const unsigned int InputImageDimension = 3;
typedef itk::Image<TPixel, InputImageDimension> Image3DType;

// The image written to disk
const unsigned int OutputImageDimension = 3;
typedef unsigned short OutputPixelType;
typedef itk::Image<OutputPixelType, OutputImageDimension> OutputImageType;

typedef itk::GDCMSeriesFileNames DicomNameGeneratorType;
typedef itk::ImageSeriesReader<Image3DType> SeriesReaderType;

typedef itk::MetaDataDictionary MetaDataDictionaryType;
typedef SeriesReaderType::DictionaryArrayType MetaDataDictionaryArrayType;

// The registration object types
typedef itk::MultiResolutionImageRegistrationMethod<Image2DType, Image2DType> MultiResRegistration;
typedef itk::MultiResolutionPyramidImageFilter<Image2DType, Image2DType> ImagePyramid;

// We need some global typedefs for the types of metrics we will be selecting
typedef itk::ImageToImageMetric<Image2DType, Image2DType> ImageToImageMetric; // base class for all that follow
typedef itk::MattesMutualInformationImageToImageMetric<Image2DType, Image2DType> MMIImageToImageMetric;
typedef itk::MeanSquaresImageToImageMetric<Image2DType, Image2DType> MSImageToImageMetric;

// We need global typedefs for the optimizers
typedef itk::SingleValuedNonLinearOptimizer SingleValuedNonLinearOptimizer;
typedef itk::LBFGSOptimizer LBFGSOptimizer;
typedef itk::LBFGSBOptimizer LBFGSBOptimizer;
typedef itk::GradientDescentOptimizer GDOptimizer;
typedef itk::RegularStepGradientDescentOptimizer RSGDOptimizer;

// Typedefs for transforms
typedef itk::CenteredRigid2DTransform<double> CenteredRigid2DTransform;
typedef itk::BSplineTransform<double, 2u, BSPLINE_ORDER> BSplineTransform;

// Typedef for the registration spatial object mask
typedef itk::BlobSpatialObject<2u> Mask2DType;

// Filter to import the OsiriX image to itk
typedef itk::ImportImageFilter<TPixel, 3u> ImportImageFilterType;

// Filter to extract 2D slice from 3D ITK image.
typedef itk::ExtractImageFilter<Image3DType, Image2DType> ExtractSliceFilterType;

//
typedef itk::ContinuousIndex<double, 2u> ContinuousIndexType;
#endif
