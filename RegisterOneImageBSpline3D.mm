/*
 * File:   RegisterOneImageBSpline3D.mm
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#include "RegisterOneImageBSpline3D.h"
#include "ItkTypedefs.h"
#include "OptimizerUtils.h"
#include "RegistrationObserverBSpline.h"
#include "ParseITKException.h"
#include "ImageTagger.h"

#import "ProgressWindowController.h"

#include <log4cplus/loggingmacros.h>

RegisterOneImageBSpline3D::RegisterOneImageBSpline3D(
    ProgressWindowController* progressController, Image3D::Pointer fixedImage,
    const ItkRegistrationParams& params)
    : RegisterOneImage<Image3D>(progressController, fixedImage, params)
{
    std::string name = std::string(LOGGER_NAME) + ".RegisterOneImageBSpline3D";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");

    // don't do anything if this is turned off
    if (itkParams_.bsplineLevels == 0)
    {
        LOG4CPLUS_FATAL(logger_, "B-spline deformable registration levels == 0.");
        throw itk::InvalidArgumentError();
    }
}

Image3D::Pointer RegisterOneImageBSpline3D::registerImage(Image3D::Pointer movingImage, ResultCode& code)
{
    LOG4CPLUS_TRACE(logger_, "Enter");

    // Assume the best to start.
    code = SUCCESS;
    
    // Set the resolution schedule
    // We use reduced resolution in the plane of the slices but not in the other dimension
    // because it is small to begin with in DCE images.
    MultiResRegistrationMethod3D::ScheduleType resolutionSchedule(itkParams_.bsplineLevels, Image3D::ImageDimension);
    itk::SizeValueType factor = itk::Math::Round<itk::SizeValueType,
                double>(std::pow(2.0, static_cast<double>(itkParams_.bsplineLevels - 1)));
    for (unsigned level = 0; level < resolutionSchedule.rows(); ++level)
    {
        for (unsigned dim = 0; dim < resolutionSchedule.cols(); ++dim)
        {
            if (dim == 2)
                resolutionSchedule[level][dim] = 1;
            else
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
    RegistrationObserverBSpline<Image3D>::Pointer observer = RegistrationObserverBSpline<Image3D>::New();
    observer->SetNumberOfLevels(itkParams_.bsplineLevels);
    observer->SetGridSizeSchedule(itkParams_.bsplineGridSizes);
    observer->SetProgressWindowController(progController_);
    [progController_ setObserver:observer];

    //
    // Set up the BSplineTransform.
    // This needs to be set up here rather than in the observer because the registration
    // method PreparePyramids expects to have a working transform so that it can know the number of
    // parameters needed.
    BSplineTransform3D::Pointer transform = BSplineTransform3D::New();
    BSplineTransform3D::MeshSizeType meshSize;
    for (unsigned dim = 0; dim < Image3D::ImageDimension; ++dim)
        meshSize[dim] = itkParams_.bsplineGridSizes(0, dim) - BSPLINE_ORDER;

    BSplineTransformInitializer3D::Pointer transformInitializer = BSplineTransformInitializer3D::New();
    transformInitializer->SetTransform(transform);
    transformInitializer->SetImage(fixedImage_);
    transformInitializer->SetTransformDomainMeshSize(meshSize);
    transformInitializer->InitializeTransform();
    //LOG4CPLUS_DEBUG(logger_, "Initial transform params:" << transform->GetParameters());

    const itk::SizeValueType numberOfParameters = transform->GetNumberOfParameters();
    BSplineTransform3D::ParametersType parameters(numberOfParameters);
    parameters.Fill(0.0);
    transform->SetParameters(parameters);

    /*
     * Set up the metric
     * We can set up those things which will not change between levels here and
     * leave the rest for the first IterationEvent in the observer.
     */
    MMIImageToImageMetric3D::Pointer mmiMetric;
    MSImageToImageMetric3D::Pointer msMetric;
    ImageToImageMetric3D::Pointer metric;
    switch (itkParams_.bsplineMetric)
    {
        case MattesMutualInformation:
            mmiMetric = MMIImageToImageMetric3D::New();
            mmiMetric->UseExplicitPDFDerivativesOn();  // Best for large number of parameters
            mmiMetric->SetUseCachingOfBSplineWeights(true); // default == true
            mmiMetric->ReinitializeSeed(76926294);
            observer->SetMMISchedules(itkParams_.bsplineMMINumBins, itkParams_.bsplineMMISampleRate);
            metric = mmiMetric;
            break;
        case MeanSquares:
            msMetric = MSImageToImageMetric3D::New();
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

    SingleValuedNonLinearOptimizer::ScalesType optimizerScales(transform->GetNumberOfParameters());
    optimizerScales.Fill(1.0);
    optimizer->SetScales(optimizerScales);

    // We use the same observer object for both the registration object and the optimizer
    optimizer->AddObserver(itk::IterationEvent(), observer);
    optimizer->AddObserver(itk::EndEvent(), observer);

    //
    // Set up the interpolator
    // This does not change during registration
    LinearInterpolator3D::Pointer interpolator = LinearInterpolator3D::New();
    //BSplineInterpolator3D::Pointer interpolator = BSplineInterpolator3D::New();
    //interpolator->SetSplineOrder(BSPLINE_ORDER);

    // The image pyramids
    // These will be set up by the registration object.
    ImagePyramid3D::Pointer fixedImagePyramid = ImagePyramid3D::New();
    fixedImagePyramid->SetNumberOfLevels(itkParams_.bsplineLevels);

    ImagePyramid3D::Pointer movingImagePyramid = ImagePyramid3D::New();
    movingImagePyramid->SetNumberOfLevels(itkParams_.bsplineLevels);

    // Set up the registration
    Image3D::RegionType reg = fixedImage_->GetLargestPossibleRegion();
    Image3D::RegionType regRegion = Create3DRegion(itkParams_.fixedImageRegion, reg.GetSize(2u));

    MultiResRegistrationMethod3D::Pointer registration = MultiResRegistrationMethod3D::New();
    registration->AddObserver(itk::IterationEvent(), observer);
    registration->SetInterpolator(interpolator);
    registration->SetMetric(metric);
    registration->SetOptimizer(optimizer);
    registration->SetTransform(transform);
    registration->SetFixedImage(fixedImage_);
    registration->SetMovingImage(movingImage);
    registration->SetFixedImagePyramid(fixedImagePyramid);
    registration->SetMovingImagePyramid(movingImagePyramid);
    registration->SetFixedImageRegion(regRegion);
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
        ImageTagger<Image3D> tagImage(10);
        tagImage(*(movingImage.GetPointer()));
    }

    ResampleFilter3D::Pointer resampler = ResampleFilter3D::New();
    resampler->SetTransform(transform);
    resampler->SetInterpolator(interpolator);
    resampler->SetInput(movingImage);
    resampler->SetSize(fixedImage_->GetLargestPossibleRegion().GetSize());
    resampler->SetOutputOrigin(fixedImage_->GetOrigin());
    resampler->SetOutputSpacing(fixedImage_->GetSpacing());
    resampler->SetOutputDirection(fixedImage_->GetDirection());
    resampler->SetDefaultPixelValue(0.0);
    resampler->Update();

    Image3D::Pointer result = resampler->GetOutput();

    return result;
}

Image3D::RegionType RegisterOneImageBSpline3D::Create3DRegion(const Image2D::RegionType& region2D, unsigned numSlices)
{
    Image3D::RegionType region;

    for (unsigned idx = 0; idx < 2u; ++idx)
    {
        region.SetIndex(idx, region2D.GetIndex(idx));
        region.SetSize(idx, region2D.GetSize(idx));
    }
    region.SetIndex(2u, 0);
    region.SetSize(2u, numSlices);

    return region;
}

