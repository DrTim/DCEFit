/*
 * File:   RegisterOneImageDemons2D.mm
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#include "ProjectDefs.h"
#include "RegisterOneImageDemons2D.h"
#include "ItkTypedefs.h"
#include "RegistrationObserverDemons.h"
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
    if (itkParams_.demonsLevels == 0)
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

    // Set up the observer
    typedef RegistrationObserverDemons<Image2D, DemonsDisplacementField2D> ObserverType;
    ObserverType::Pointer observer = ObserverType::New();
    observer->SetNumberOfLevels(itkParams_.demonsLevels);
    observer->SetOptimizerSchedule(itkParams_.demonsMaxRMSError);
    observer->SetIterationSchedule(itkParams_.demonsMaxIter);
    observer->SetProgressWindowController(progController_);
    [progController_ setObserver:observer];

    // Match the histograms between source and target
    MatchingFilterType2D::Pointer matcher = MatchingFilterType2D::New();
    matcher->SetInput(movingImage);
    matcher->SetReferenceImage(fixedImage_);
    matcher->SetNumberOfHistogramLevels(itkParams_.demonsHistogramBins);
    matcher->SetNumberOfMatchPoints(itkParams_.demonsHistogramMatchPoints);
    matcher->ThresholdAtMeanIntensityOn();

    // setup the deformation filter
    DemonsRegistrationFilter2D::Pointer filter = DemonsRegistrationFilter2D::New();
    filter->SetStandardDeviations(itkParams_.demonsStandardDeviations);
    filter->AddObserver(itk::IterationEvent(), observer);
    observer->SetRegistrationFilter(filter);

    DemonsMultiResRegistration2D::Pointer multires = DemonsMultiResRegistration2D::New();
    multires->SetRegistrationFilter(filter);
    multires->SetNumberOfLevels(itkParams_.demonsLevels);
    multires->SetFixedImage(fixedImage_);
    multires->SetMovingImage(matcher->GetOutput());
    unsigned maxIter[MAX_REGISTRATION_LEVELS];
    for (int idx = 0; idx < itkParams_.demonsLevels; idx++)
        maxIter[idx] = itkParams_.demonsMaxIter[itkParams_.demonsLevels - idx - 1];
    multires->SetNumberOfIterations(maxIter);

    multires->AddObserver(itk::IterationEvent(), observer);
    multires->AddObserver(itk::EndEvent(), observer);
    observer->SetRegistrationMethod(multires);

    // This compensates for a logic flaw in the MultiResolutionPDEDeformableRegistration class.
    multires->InvokeEvent(itk::MultiResolutionIterationEvent());

    // Do the registration
    try
    {
        multires->Update();
    }
    catch (itk::ExceptionObject& err)
    {
        code = DISASTER;
        LOG4CPLUS_ERROR(logger_, "Severe error in registration. " << ParseITKException(err));

        return movingImage;
    }

    std::string stopCondition;
    if (observer->RegistrationWasCancelled())
    {
        stopCondition = "Registration cancelled by user.";
        LOG4CPLUS_INFO(logger_, "Optimizer stop condition = " << stopCondition);
        
        return movingImage;
    }
    else
    {
        
    }
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
