/*
 * File:   RegisterOneImageRigid3D.mm
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#include "RegisterOneImageRigid3D.h"
#include "OptimizerUtils.h"
#include "RegistrationObserver.h"
#include "ParseITKException.h"
#include "ImageTagger.h"

#import "ProgressWindowController.h"

#include <itkCenteredTransformInitializer.h>
#include <itkLinearInterpolateImageFunction.h>

#include <log4cplus/loggingmacros.h>

RegisterOneImageRigid3D::RegisterOneImageRigid3D(
    ProgressWindowController* progressController, Image3D::Pointer fixedImage,
    const ItkRegistrationParams& itkParams)
    : RegisterOneImage<Image3D>(progressController, fixedImage, itkParams)
{
    std::string name = std::string(LOGGER_NAME) + ".RegisterOneImageRigid3D";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");

    // don't do anything if this is turned off
    if (itkParams_.rigidLevels == 0)
    {
        LOG4CPLUS_FATAL(logger_, "Rigid registration levels == 0.");
        throw itk::InvalidArgumentError();
        return;
    }
}

Image3D::Pointer RegisterOneImageRigid3D::registerImage(Image3D::Pointer movingImage, ResultCode& code)
{
    LOG4CPLUS_TRACE(logger_, "Enter");
    
    // Assume the best to start.
    code = SUCCESS;

    // typedefs for ITK classes
//    typedef itk::ResampleImageFilter<Image2D, Image2D> ResampleFilterType;
//    typedef itk::CenteredTransformInitializer<CenteredRigid2DTransform, Image2D, Image2D>
//            TransformInitializerType;
//    typedef itk::BSplineInterpolateImageFunction<Image2D> BSplineInterpolatorType;
//    typedef itk::LinearInterpolateImageFunction<Image2D> LinearInterpolatorType;

    // Set the resolution schedule
    Registration3D::ScheduleType resolutionSchedule(itkParams_.rigidLevels,
                                                          Image2D::ImageDimension);
    itk::SizeValueType factor = itk::Math::Round<itk::SizeValueType,
                    double>(std::pow(2.0, static_cast<double>(itkParams_.rigidLevels - 1)));
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
    RegistrationObserver<Image3D>::Pointer observer = RegistrationObserver<Image3D>::New();
    observer->SetProgressWindowController(progController_);
    observer->SetNumberOfLevels(itkParams_.rigidLevels);
    [progController_ setObserver:observer];

    std::stringstream str;
//    str << "Fixed Image ***************\n";
//    fixedImage_->Print(str);
//    LOG4CPLUS_DEBUG(logger_, str.str());
//    str.str("");
//    str << "Moving Image ***************\n";
//    movingImage->Print(str);
//    LOG4CPLUS_DEBUG(logger_, str.str());

    // Set up the rigid transform
    // This needs to be set up here rather than in the observer because the registration
    // method PreparePyramids expects to have a working transform so that it can know the number of
    // parameters needed.
    /* The serialization of the optimizable parameters is an array of 5 elements
     * ordered as follows:
     * p[0] = angle
     * p[1] = x coordinate of the centre
     * p[2] = y coordinate of the centre
     * p[3] = x component of the translation
     * p[4] = y component of the translation
     *
     * Use the initializer to set up the transform
     */
    VersorTransform3D::Pointer transform = VersorTransform3D::New();
    CenteredVersorTransformInitializer3D::Pointer transformInitializer =
            CenteredVersorTransformInitializer3D::New();
    transformInitializer->SetTransform(transform);
    transformInitializer->SetFixedImage(fixedImage_);
    transformInitializer->SetMovingImage(movingImage);
    transformInitializer->GeometryOn();
    transformInitializer->InitializeTransform();
    LOG4CPLUS_DEBUG(logger_, "Initial transform params:" << transform->GetParameters());

    /*
     * Set up the metric
     * We can set up those things which will not change between levels here and
     *leave the rest for the first IterationEvent in the observer.
     */
    
    MMIImageToImageMetric3D::Pointer MMImetric;
    MSImageToImageMetric3D::Pointer MSMetric;
    ImageToImageMetric3D::Pointer metric;
    switch (itkParams_.rigidRegMetric)
    {
        case MattesMutualInformation:
            MMImetric = MMIImageToImageMetric3D::New();
            MMImetric->UseExplicitPDFDerivativesOff();
            MMImetric->SetUseCachingOfBSplineWeights(true); // default == true
            MMImetric->SetNumberOfThreads(1);
            MMImetric->ReinitializeSeed(8370276);
            observer->SetMMISchedules(itkParams_.rigidMMINumBins,
                                      itkParams_.rigidMMISampleRate);
            metric = MMImetric;
            break;
        case MeanSquares:
            MSMetric = MSImageToImageMetric3D::New();
            MSMetric->SetNumberOfThreads(1);
            metric = MSMetric;
            break;
        default:
            break;
    }

//    itkParams_.createFixedImageMask(fixedImage_);
//    if (itkParams_.fixedImageMask.IsNotNull())
//        metric->SetFixedImageMask(itkParams_.fixedImageMask);

    // This is independent of the type of optimizer except that the LBFGSB
    // optimizer does not accept scaling.
    typedef SingleValuedNonLinearOptimizer::ScalesType OptimizerScalesType;
    OptimizerScalesType optimizerScales(transform->GetNumberOfParameters());
    optimizerScales[0] = 0.01;  // reduce the rotation scale because it's in radians
    optimizerScales[1] = 1.0;   // these are the translation scales in mm
    optimizerScales[2] = 1.0;
    optimizerScales[3] = 1.0;
    optimizerScales[4] = 1.0;
    LOG4CPLUS_DEBUG(logger_, "  optimizerScales = "
                        << std::fixed << std::setprecision(4) << optimizerScales);

    SingleValuedNonLinearOptimizer::Pointer optimizer;
    switch (itkParams_.rigidRegOptimiser)
    {
        case LBFGSB:
            optimizer = GetLBFGSBOptimizer(transform->GetNumberOfParameters(),
                                           1.0e9, 0.0, 300, 300);
            observer->SetLBFGSBSchedules(itkParams_.rigidLBFGSBCostConvergence,
                                         itkParams_.rigidLBFGSBGradientTolerance,
                                         itkParams_.rigidMaxIter);
            break;
        case LBFGS:
            optimizer = GetLBFGSOptimizer(1.0e-2, 0.1, 300);
            optimizer->SetScales(optimizerScales);
            observer->SetLBFGSSchedules(itkParams_.rigidLBFGSGradientConvergence,
                                        itkParams_.rigidLBFGSDefaultStepSize,
                                        itkParams_.rigidMaxIter);
            break;
        case RSGD:
            optimizer = GetRSGDOptimizer(1.0, 0.01, 0.9, 1e-4, 300);
            optimizer->SetScales(optimizerScales);
            observer->SetRSGDSchedules(itkParams_.rigidRSGDMinStepSize,
                                       itkParams_.rigidRSGDMaxStepSize,
                                       itkParams_.rigidRSGDRelaxationFactor,
                                       itkParams_.rigidMaxIter);
        default:
            break;
    }

    // We use the same observer object for both the registration object and the optimizer
    optimizer->AddObserver(itk::IterationEvent(), observer);
    optimizer->AddObserver(itk::EndEvent(), observer);

    //
    // Set up the interpolator
    // This does not change during registration
    LinearInterpolator3D::Pointer interpolator = LinearInterpolator3D::New();
    //interpolator->SetSplineOrder(BSPLINE_ORDER);
    //interpolator->SetNumberOfThreads(1);

    //
    // The image pyramids
    // These will be set up by the registration object.
    ImagePyramid3D::Pointer fixedImagePyramid = ImagePyramid3D::New();
    fixedImagePyramid->SetNumberOfLevels(itkParams_.rigidLevels);

    ImagePyramid3D::Pointer movingImagePyramid = ImagePyramid3D::New();
    movingImagePyramid->SetNumberOfLevels(itkParams_.rigidLevels);

    // Set up the registration
    Image3D::RegionType reg = fixedImage_->GetLargestPossibleRegion();
    Image3D::RegionType regRegion = Create3DRegion(itkParams_.fixedImageRegion, reg.GetSize(2u));

    Registration3D::Pointer registration = Registration3D::New();
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
    registration->SetFixedImageRegion(regRegion);
    registration->SetSchedules(resolutionSchedule, resolutionSchedule);

    //  We now pass the parameters of the current transform as the initial
    //  parameters to be used when the registration process starts.
    registration->SetInitialTransformParameters(transform->GetParameters());
    //    registration->SetDebug(true);
    //    registration->Print(std::cout);

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

    SingleValuedNonLinearOptimizer::ParametersType finalParameters =
        registration->GetLastTransformParameters();

    const double finalAngle = finalParameters[0];
    const double finalCentreX = finalParameters[1];
    const double finalCentreY = finalParameters[2];
    const double finalTranslationX = finalParameters[3];
    const double finalTranslationY = finalParameters[4];
    const double bestValue = GetOptimizerValue(optimizer);

    // Print out results
    const double finalAngleInDegrees = finalAngle * 180.0 / vnl_math::pi;

    str.str("");
    str << std::fixed << std::setprecision(4)
    << " Angle (radians) = " << finalAngle << "\n"
    << " Angle (degrees) = " << finalAngleInDegrees << "\n"
    << " Centre X        = " << finalCentreX << "\n"
    << " Centre Y        = " << finalCentreY << "\n"
    << " Translation X   = " << finalTranslationX << "\n"
    << " Translation Y   = " << finalTranslationY << "\n"
    << " Best metric     = " << bestValue;

    LOG4CPLUS_DEBUG(logger_, "Last Transform Parameters\n" << str.str());
    
    // Apply the transform to the movong image
    transform->SetParameters(finalParameters);

    /*
     ImageTagger<Image2D> tagImage(10);
     tagImage(*(movingImage.GetPointer()));
     */

    ResampleFilter3D::Pointer resampler = ResampleFilter3D::New();
    resampler->SetTransform(transform);
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

Image3D::RegionType RegisterOneImageRigid3D::Create3DRegion(const Image2D::RegionType& region2D, unsigned numSlices)
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

