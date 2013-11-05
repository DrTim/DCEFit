/*
 * File:   RegisterOneImageMultiResDeformable2D.mm
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#include "RegisterOneImageMultiResDeformable2D.h"
#include "OptimizerUtils.h"
#include "RegistrationObserver.h"
#include "ParseITKException.h"
#include "ImageTagger.h"

#import "ProgressWindowController.h"

#include <itkBSplineTransformInitializer.h>

#include <log4cplus/loggingmacros.h>

RegisterOneImageMultiResDeformable2D::RegisterOneImageMultiResDeformable2D(
    ProgressWindowController* progressController, Image2DType::Pointer fixedImage,
    const ItkRegistrationParams& params)
    : RegisterOneImage2D(progressController, fixedImage, params)
{
    std::string name = std::string(LOGGER_NAME) + ".RegisterOneImageMultiResDeformable2D";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");
    
    // don't do anything if this is turned off
    if (itkParams_.deformLevels == 0)
    {
        LOG4CPLUS_FATAL(logger_, "Deformable registration levels == 0.");
        throw itk::InvalidArgumentError();
        return;
    }
}

Image2DType::Pointer RegisterOneImageMultiResDeformable2D::registerImage(
                                Image2DType::Pointer movingImage, ResultCode& code)
{
    LOG4CPLUS_TRACE(logger_, "Enter");

    // Assume the best to start.
    code = SUCCESS;
    
    // typedefs for ITK classes
    typedef itk::ResampleImageFilter<Image2DType, Image2DType> ResampleFilterType;
    typedef itk::BSplineTransformInitializer<BSplineTransform, Image2DType> TransformInitializerType;
    typedef itk::BSplineInterpolateImageFunction<Image2DType> InterpolatorType;

    // Set the resolution schedule
    MultiResRegistration::ScheduleType resolutionSchedule(itkParams_.deformLevels,
                                                          Image2DType::ImageDimension);
    itk::SizeValueType factor = itk::Math::Round<itk::SizeValueType,
                double>(std::pow(2.0, static_cast<double>(itkParams_.deformLevels - 1)));
    for (unsigned level = 0; level < resolutionSchedule.rows(); ++level)
    {
        for (unsigned dim = 0; dim < resolutionSchedule.cols(); ++dim)
        {
            resolutionSchedule[level][dim] = factor;
            LOG4CPLUS_DEBUG(logger_, "    Resolution schedule: level " << level << ", dim "
                            << dim << " = " << factor);
        }

        factor /= 2;
        if (factor < 1)
            factor = 1;
    }

    LOG4CPLUS_DEBUG(logger_, "Shrink factors = " << resolutionSchedule);

    // Set up the observer
    RegistrationObserver::Pointer observer = RegistrationObserver::New();
    observer->SetNumberOfLevels(itkParams_.deformLevels);
    observer->SetGridSizeSchedule(itkParams_.deformGridSizes);
    observer->SetProgressWindowController(progController_);
    [progController_ setObserver:observer];

    //
    // Set up the BSplineTransform.
    // This needs to be set up here rather than in the observer because the registration
    // method PreparePyramids expects to have a working transform so that it can know the number of
    // parameters needed.
    BSplineTransform::Pointer transform = BSplineTransform::New();
    BSplineTransform::MeshSizeType meshSize;
    unsigned int numberOfGridNodesInOneDimension = itkParams_.deformGridSizes[0];
    meshSize.Fill(numberOfGridNodesInOneDimension - BSPLINE_ORDER);

    TransformInitializerType::Pointer transformInitializer = TransformInitializerType::New();
    transformInitializer->SetTransform(transform);
    transformInitializer->SetImage(fixedImage_);
    transformInitializer->SetTransformDomainMeshSize(meshSize);
    transformInitializer->InitializeTransform();
    //LOG4CPLUS_DEBUG(logger_, "Initial transform params:" << transform->GetParameters());

    const itk::SizeValueType numberOfParameters = transform->GetNumberOfParameters();
    BSplineTransform::ParametersType parameters(numberOfParameters);
    parameters.Fill(0.0);
    transform->SetParameters(parameters);

    /*
     * Set up the metric
     * We can set up those things which will not change between levels here and
     * leave the rest for the first IterationEvent in the observer.
     */
    MMIImageToImageMetric::Pointer mmiMetric;
    MSImageToImageMetric::Pointer msMetric;
    ImageToImageMetric::Pointer metric;
    switch (itkParams_.deformRegMetric)
    {
        case MattesMutualInformation:
            mmiMetric = MMIImageToImageMetric::New();
            mmiMetric->UseExplicitPDFDerivativesOff();
            mmiMetric->SetUseCachingOfBSplineWeights(true); // default == true
            mmiMetric->ReinitializeSeed(76926294);
            mmiMetric->SetNumberOfThreads(1);
            observer->SetMMISchedules(itkParams_.deformMMINumBins, itkParams_.deformMMISampleRate);
            metric = mmiMetric;
            break;
        case MeanSquares:
            msMetric = MSImageToImageMetric::New();
            msMetric->SetNumberOfThreads(1);
            metric = msMetric;
            break;
        default:
            break;
    }

//    itkParams_.createFixedImageMask(fixedImage_);
//    if (itkParams_.fixedImageMask.IsNotNull())
//        metric->SetFixedImageMask(itkParams_.fixedImageMask);

    // Set up the optimizer. We are using the Bspline transform so there is no scaling needed.
    SingleValuedNonLinearOptimizer::Pointer optimizer;
    switch (itkParams_.deformRegOptimiser)
    {
        case LBFGSB:
            optimizer = GetLBFGSBOptimizer(transform->GetNumberOfParameters(), 1e9, 0.0, 300, 100);
            observer->SetLBFGSBSchedules(itkParams_.deformLBFGSBCostConvergence,
                                         itkParams_.deformLBFGSBGradientTolerance,
                                         itkParams_.deformMaxIter);
            break;
        case LBFGS:
            optimizer = GetLBFGSOptimizer(1e-5, 0.1, 300);
            observer->SetLBFGSSchedules(itkParams_.deformLBFGSGradientConvergence,
                                        itkParams_.deformLBFGSDefaultStepSize,
                                        itkParams_.deformMaxIter);
            break;
        case RSGD:
            optimizer = GetRSGDOptimizer(1.0, 1.0, 0.5, 1e-4, 300);
            observer->SetRSGDSchedules(itkParams_.deformRSGDMinStepSize,
                                       itkParams_.deformRSGDMaxStepSize,
                                       itkParams_.deformRSGDRelaxationFactor,
                                       itkParams_.deformMaxIter);
        default:
            break;
    }

    // We use the same observer object for both the registration object and the optimizer
    optimizer->AddObserver(itk::IterationEvent(), observer);
    optimizer->AddObserver(itk::EndEvent(), observer);

    //
    // Set up the interpolator
    // This does not change during registration
    InterpolatorType::Pointer interpolator = InterpolatorType::New();
    interpolator->SetSplineOrder(BSPLINE_ORDER);
    interpolator->SetNumberOfThreads(1);

    //
    // The image pyramids
    // These will be set up by the registration object.
    ImagePyramid::Pointer fixedImagePyramid = ImagePyramid::New();
    fixedImagePyramid->SetNumberOfLevels(itkParams_.deformLevels);

    ImagePyramid::Pointer movingImagePyramid = ImagePyramid::New();
    movingImagePyramid->SetNumberOfLevels(itkParams_.deformLevels);

    // Set up the registration
    MultiResRegistration::Pointer registration = MultiResRegistration::New();
    registration->AddObserver(itk::IterationEvent(), observer);
    registration->SetNumberOfThreads(1);
    registration->SetInterpolator(interpolator);
    registration->SetMetric(metric);
    registration->SetOptimizer(optimizer);
    registration->SetTransform(transform);
    registration->SetFixedImage(fixedImage_);
    registration->SetMovingImage(movingImage);
    registration->SetFixedImagePyramid(fixedImagePyramid);
    registration->SetMovingImagePyramid(movingImagePyramid);
    registration->SetFixedImageRegion(itkParams_.fixedImageRegion);
    //registration->SetFixedImageRegion(fixedImage_->GetBufferedRegion());
    registration->SetSchedules(resolutionSchedule, resolutionSchedule);

    //  We now pass the parameters of the current transform as the initial
    //  parameters to be used when the registration process starts.
    registration->SetInitialTransformParameters(transform->GetParameters());
    //registration->SetDebug(true);

    //    std::stringstream str;
    //    registration->Print(str);
    //    LOG4CPLUS_DEBUG(logger_, str.str());

    try
    {
        registration->Update();
    }
    catch (itk::ExceptionObject& err)
    {
        code = DISASTER;
        LOG4CPLUS_ERROR(logger_, "Severe error in registration. " << ParseITKException(err));
    }

    std::string stopCondition = optimizer->GetStopConditionDescription();

    LOG4CPLUS_INFO(logger_, "Optimizer stop condition = " << stopCondition);
    LOG4CPLUS_INFO(logger_, "Optimizer best metric = " << std::scientific
                   << std::setprecision(6) << GetOptimizerValue(optimizer));

    SingleValuedNonLinearOptimizer::ParametersType finalParameters =
        registration->GetLastTransformParameters();

    //LOG4CPLUS_DEBUG(logger_, finalParameters);
    
    transform->SetParameters(finalParameters);

    if (itkParams_.deformShowField)
    {
        ImageTagger<Image2DType> tagImage(10);
        tagImage(*(movingImage.GetPointer()));
    }

    ResampleFilterType::Pointer resampler = ResampleFilterType::New();
    resampler->SetTransform(transform);
    resampler->SetInput(movingImage);
    resampler->SetSize(fixedImage_->GetLargestPossibleRegion().GetSize());
    resampler->SetOutputOrigin(fixedImage_->GetOrigin());
    resampler->SetOutputSpacing(fixedImage_->GetSpacing());
    resampler->SetOutputDirection(fixedImage_->GetDirection());
    resampler->SetDefaultPixelValue(0.0);
    resampler->Update();

    Image2DType::Pointer result = resampler->GetOutput();

    return result;
}
