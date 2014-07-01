/*
 * File:   RegisterOneImageDemons2D.mm
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#include "RegisterOneImageDemons2D.h"
#include "ItkTypedefs.h"
#include "OptimizerUtils.h"
#include "RegistrationObserver.h"
#include "ParseITKException.h"
#include "ImageTagger.h"

#import "ProgressWindowController.h"

#include <log4cplus/loggingmacros.h>

RegisterOneImageDemons2D::RegisterOneImageDemons2D(
    ProgressWindowController* progressController, Image2D::Pointer fixedImage,
    const ItkRegistrationParams& params)
    : RegisterOneImage<Image2D>(progressController, fixedImage, params)
{
    std::string name = std::string(LOGGER_NAME) + ".RegisterOneImageDemons2D";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");
    
    // don't do anything if this is turned off
    if (itkParams_.deformLevels == 0)
    {
        LOG4CPLUS_FATAL(logger_, "Deformable registration levels == 0.");
        throw itk::InvalidArgumentError();
    }
}

Image2D::Pointer RegisterOneImageDemons2D::registerImage(Image2D::Pointer movingImage, ResultCode& code)
{
    LOG4CPLUS_TRACE(logger_, "Enter");

    // Assume the best to start.
    code = SUCCESS;

    // Match the histograms between source and target
    MatchingFilterType2D::Pointer matcher = MatchingFilterType2D::New();
    matcher->SetInput(movingImage);
    matcher->SetReferenceImage(fixedImage_);
    matcher->SetNumberOfHistogramLevels(1024);
    matcher->SetNumberOfMatchPoints(7);
    matcher->ThresholdAtMeanIntensityOn();

    // setup the deformation filter
    DemonsRegistrationFilter2D::Pointer filter = DemonsRegistrationFilter2D::New();
    filter->SetStandardDeviations(1.0);

    // Set up the observer
    RegistrationObserver2D::Pointer observer = RegistrationObserver2D::New();
    observer->SetNumberOfLevels(itkParams_.deformLevels);
    observer->SetProgressWindowController(progController_);
    [progController_ setObserver:observer];

    DemonsMultiResRegistration2D::Pointer multires = DemonsMultiResRegistration2D::New();
    multires->SetRegistrationFilter(filter);
    multires->SetNumberOfLevels(itkParams_.deformLevels);
    multires->SetFixedImage(fixedImage_);
    multires->SetMovingImage(movingImage);
    multires->SetNumberOfIterations(itkParams_.deformMaxIter.GetDataPointer());

    // Do the registration
    try
    {
        multires->Update();
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

//    stopCondition = multires->Get optimizer->GetStopConditionDescription();
//
//    LOG4CPLUS_INFO(logger_, "Optimizer stop condition = " << stopCondition);
//    LOG4CPLUS_INFO(logger_, "Optimizer best metric = " << std::scientific
//                   << std::setprecision(6) << GetOptimizerValue(optimizer));

    // compute the output (warped) image
    DemonsWarper2D::Pointer warper = DemonsWarper2D::New();
    LinearInterpolator2D::Pointer interpolator = LinearInterpolator2D::New();

    warper->SetInput(movingImage);
    warper->SetInterpolator(interpolator);
    warper->SetOutputSpacing(movingImage->GetSpacing());
    warper->SetOutputOrigin(movingImage->GetOrigin());
    warper->SetOutputDirection(movingImage->GetDirection());
    warper->SetDisplacementField(multires->GetOutput());

    if (itkParams_.deformShowField)
    {
        ImageTagger<Image2D> tagImage(10);
        tagImage(*(movingImage.GetPointer()));
    }


//    itkParams_.createFixedImageMask(fixedImage_);
//    if (itkParams_.fixedImageMask.IsNotNull())
//        metric->SetFixedImageMask(itkParams_.fixedImageMask);

    try
    {
        warper->Update();
    }
    catch(itk::ExceptionObject& err)
    {
        code = DISASTER;
        LOG4CPLUS_ERROR(logger_, "Severe error in Demons warper. " << ParseITKException(err));
    }

    Image2D::Pointer result = warper->GetOutput();

    return result;
}
