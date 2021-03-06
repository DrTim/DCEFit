/*
 * File:   RegisterOneImageBSpline2D.mm
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#include "RegisterOneImageBSpline2D.h"
#include "ItkTypedefs.h"
#include "OptimizerUtils.h"
#include "RegistrationObserverBSpline.h"
#include "ParseITKException.h"
#include "ImageTagger.h"

#import "ProgressWindowController.h"

#include <log4cplus/loggingmacros.h>

RegisterOneImageBSpline2D::RegisterOneImageBSpline2D(
    ProgressWindowController* progressController, Image2D::Pointer fixedImage,
    const ItkRegistrationParams& params)
    : RegisterOneImage<Image2D>(progressController, fixedImage, params)
{
    std::string name = std::string(LOGGER_NAME) + ".RegisterOneImageBSpline2D";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");
    
    // don't do anything if this is turned off
    if (itkParams_.bsplineLevels == 0)
    {
        LOG4CPLUS_FATAL(logger_, "B-spline deformable registration levels == 0.");
        throw itk::InvalidArgumentError();
    }
}

Image2D::Pointer RegisterOneImageBSpline2D::registerImage(Image2D::Pointer movingImage, ResultCode& code)
{
    LOG4CPLUS_TRACE(logger_, "Enter");

    // Assume the best to start.
    code = SUCCESS;

    // Set the resolution schedule
    MultiResRegistrationMethod2D::ScheduleType resolutionSchedule(itkParams_.bsplineLevels, 2u);
    itk::SizeValueType factor = itk::Math::Round<itk::SizeValueType,
                double>(std::pow(2.0, static_cast<double>(itkParams_.bsplineLevels - 1)));
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
    RegistrationObserverBSpline2D::Pointer observer = RegistrationObserverBSpline2D::New();
    observer->SetNumberOfLevels(itkParams_.bsplineLevels);
    observer->SetGridSizeSchedule(itkParams_.bsplineGridSizes);
    observer->SetProgressWindowController(progController_);
    [progController_ setObserver:observer];

    //
    // Set up the BSplineTransform.
    // This needs to be set up here rather than in the observer because the registration
    // method PreparePyramids expects to have a working transform so that it can know the number of
    // parameters needed.
    BSplineTransform2D::Pointer transform = BSplineTransform2D::New();
    BSplineTransform2D::MeshSizeType meshSize;
    for (unsigned dim = 0; dim < Image2D::GetImageDimension(); ++dim)
        meshSize[dim] = itkParams_.bsplineGridSizes(0, dim) - BSPLINE_ORDER;
    
    BSplineTransformInitializer2D::Pointer transformInitializer = BSplineTransformInitializer2D::New();
    transformInitializer->SetTransform(transform);
    transformInitializer->SetImage(fixedImage_);
    transformInitializer->SetTransformDomainMeshSize(meshSize);
    transformInitializer->InitializeTransform();
    //LOG4CPLUS_DEBUG(logger_, "Initial transform params:" << transform->GetParameters());

    const itk::SizeValueType numberOfParameters = transform->GetNumberOfParameters();
    BSplineTransform2D::ParametersType parameters(numberOfParameters);
    parameters.Fill(0.0);
    transform->SetParameters(parameters);

    /*
     * Set up the metric
     * We can set up those things which will not change between levels here and
     * leave the rest for the first IterationEvent in the observer.
     */

    MMIImageToImageMetric2D::Pointer mmiMetric;
    MSImageToImageMetric2D::Pointer msMetric;
    ImageToImageMetric2D::Pointer metric;
    switch (itkParams_.bsplineMetric)
    {
        case MattesMutualInformation:
            mmiMetric = MMIImageToImageMetric2D::New();
            mmiMetric->UseExplicitPDFDerivativesOn();  // Best for large number of parameters
            mmiMetric->SetUseCachingOfBSplineWeights(true); // default == true
            mmiMetric->ReinitializeSeed(76926294);
            observer->SetMMISchedules(itkParams_.bsplineMMINumBins, itkParams_.bsplineMMISampleRate);
            metric = mmiMetric;
            break;
        case MeanSquares:
            msMetric = MSImageToImageMetric2D::New();
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
    switch (itkParams_.bsplineOptimiser)
    {
        case LBFGSB:
            optimizer = GetLBFGSBOptimizer(transform->GetNumberOfParameters(), 1e9, 0.0, 300, 100);
            observer->SetLBFGSBSchedules(itkParams_.bsplineLBFGSBCostConvergence,
                                         itkParams_.bsplineLBFGSBGradientTolerance,
                                         itkParams_.bsplineMaxIter);
            break;
        case LBFGS:
            optimizer = GetLBFGSOptimizer(1e-5, 0.1, 300);
            observer->SetLBFGSSchedules(itkParams_.bsplineLBFGSGradientConvergence,
                                        itkParams_.bsplineLBFGSDefaultStepSize,
                                        itkParams_.bsplineMaxIter);
            break;
        case RSGD:
            optimizer = GetRSGDOptimizer(1.0, 1.0, 0.5, 1e-4, 300);
            observer->SetRSGDSchedules(itkParams_.bsplineRSGDMinStepSize,
                                       itkParams_.bsplineRSGDMaxStepSize,
                                       itkParams_.bsplineRSGDRelaxationFactor,
                                       itkParams_.bsplineMaxIter);
        default:
            break;
    }

    // We use the same observer object for both the registration object and the optimizer
    optimizer->AddObserver(itk::IterationEvent(), observer);
    optimizer->AddObserver(itk::EndEvent(), observer);

    //
    // Set up the interpolator
    // This does not change during registration
    BSplineInterpolator2D::Pointer interpolator = BSplineInterpolator2D::New();
    interpolator->SetSplineOrder(BSPLINE_ORDER);

    //
    // The image pyramids
    // These will be set up by the registration object.
    ImagePyramid2D::Pointer fixedImagePyramid = ImagePyramid2D::New();
    fixedImagePyramid->SetNumberOfLevels(itkParams_.bsplineLevels);

    ImagePyramid2D::Pointer movingImagePyramid = ImagePyramid2D::New();
    movingImagePyramid->SetNumberOfLevels(itkParams_.bsplineLevels);

    // Set up the registration
    MultiResRegistrationMethod2D::Pointer registration = MultiResRegistrationMethod2D::New();
    registration->AddObserver(itk::IterationEvent(), observer);
    registration->SetInterpolator(interpolator);
    registration->SetMetric(metric);
    registration->SetOptimizer(optimizer);
    registration->SetTransform(transform);
    registration->SetFixedImage(fixedImage_);
    registration->SetMovingImage(movingImage);
    registration->SetFixedImagePyramid(fixedImagePyramid);
    registration->SetMovingImagePyramid(movingImagePyramid);
    registration->SetFixedImageRegion(itkParams_.fixedImageRegion);
    registration->SetSchedules(resolutionSchedule, resolutionSchedule);

    //  We now pass the parameters of the current transform as the initial
    //  parameters to be used when the registration process starts.
    registration->SetInitialTransformParameters(transform->GetParameters());

    try
    {
        registration->Update();
    }
    catch (itk::ExceptionObject& err)
    {
        code = DISASTER;
        LOG4CPLUS_ERROR(logger_, "Severe error in registration. " << ParseITKException(err));
    }

    std::string stopCondition;
    if (observer->RegistrationWasCancelled())
    {
        stopCondition = "Registration cancelled by user.";
        return movingImage;
    }

    stopCondition = optimizer->GetStopConditionDescription();

    LOG4CPLUS_INFO(logger_, "Optimizer stop condition = " << stopCondition);
    LOG4CPLUS_INFO(logger_, "Optimizer best metric = " << std::scientific
                   << std::setprecision(6) << GetOptimizerValue(optimizer));

    SingleValuedNonLinearOptimizer::ParametersType finalParameters =
        registration->GetLastTransformParameters();

    transform->SetParameters(finalParameters);

    if (itkParams_.deformShowField)
    {
        ImageTagger<Image2D> tagImage(10);
        tagImage(*(movingImage.GetPointer()));
    }

    ResampleFilter2D::Pointer resampler = ResampleFilter2D::New();
    resampler->SetTransform(transform);
    resampler->SetInterpolator(interpolator);
    resampler->SetInput(movingImage);
    resampler->SetSize(fixedImage_->GetLargestPossibleRegion().GetSize());
    resampler->SetOutputOrigin(fixedImage_->GetOrigin());
    resampler->SetOutputSpacing(fixedImage_->GetSpacing());
    resampler->SetOutputDirection(fixedImage_->GetDirection());
    resampler->SetDefaultPixelValue(0.0);
    resampler->Update();

    Image2D::Pointer result = resampler->GetOutput();

    return result;
}
