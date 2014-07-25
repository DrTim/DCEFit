//
//  RegistrationObserverBSpline.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#import "RegistrationObserverBSpline.h"
#import "RegProgressValues.h"
#import "ProgressWindowController.h"

#include "OptimizerUtils.h"

#include <itkCommand.h>
#include <itkBSplineTransform.h>
#include <itkBSplineTransformParametersAdaptor.h>

#include <log4cplus/loggingmacros.h>

template <class TImage>
void RegistrationObserverBSpline<TImage>::Execute(itk::Object* caller, const itk::EventObject& event)
{
    // The first event caller is always the registration object. We use this
    // opportunity to set up the optimiser pointers and to make it safe to call
    // multiresReg->StopRegistration()
    itk::MultiResolutionImageRegistrationMethod<TImage, TImage>* mrr;
    mrr = dynamic_cast<itk::MultiResolutionImageRegistrationMethod<TImage, TImage>*>(caller);
    if (mrr != 0)
    {
        multiResReg = mrr;
        LBFGSBOpt = dynamic_cast<LBFGSBOptimizer*>(multiResReg->GetOptimizer());
        LBFGSOpt = dynamic_cast<LBFGSOptimizer*>(multiResReg->GetOptimizer());
        RSGDOpt = dynamic_cast<RSGDOptimizer*>(multiResReg->GetOptimizer());
        versorOpt = dynamic_cast<VersorOptimizer*>(multiResReg->GetOptimizer());
    }

    std::string eventName = event.GetEventName();
    
    // Check that we have the right kind of event.
    if (eventName == "IterationEvent")
    {
        LOG4CPLUS_TRACE(logger_, event.GetEventName());

        if (mrr != 0)  // the caller is the multires registration object
        {
            // Change levels
            iteration = 0;

            unsigned level = multiResReg->GetCurrentLevel();
            std::string transformClassName = multiResReg->GetTransform()->GetNameOfClass();
            if (transformClassName.find("Rigid") != std::string::npos)
            {
                LOG4CPLUS_INFO(logger_, "Multiresolution Rigid Registration level = " << level);
                [progressWindowController performSelectorOnMainThread:@selector(setCurStage:)
                                                           withObject:@"Rigid" waitUntilDone:YES];
            }
            else
            {
                LOG4CPLUS_INFO(logger_, "Multiresolution Deformable Registration level = " << level);
                [progressWindowController performSelectorOnMainThread:@selector(setCurStage:)
                                                           withObject:@"Deformable" waitUntilDone:YES];
            }

            // Set the parameters for the current level.
            CalcMultiResRegistrationParameters();

            [progressWindowController performSelectorOnMainThread:@selector(setMaxIterations:)
                                                       withObject:[NSNumber numberWithUnsignedInt:maxIterSchedule[level]]
                                                    waitUntilDone:YES];
            
            [progressWindowController performSelectorOnMainThread:@selector(setCurLevel:)
                        withObject:[NSNumber numberWithUnsignedInt:level+1] waitUntilDone:YES];
        }
        else if (LBFGSBOpt != 0) // the caller is the LBFGSB optimizer
        {
            // Log the iteration
            unsigned curIteration = LBFGSBOpt->GetCurrentIteration();
            if (iteration != curIteration)
            {
                if ((iteration != 0) && (gradientCalls != 0))
                {
                    LOG4CPLUS_TRACE(logger_, "Gradient evaluations: " << gradientCalls);
                    gradientCalls = 0;
                }

                iteration = curIteration;
                double metricValue = LBFGSBOpt->GetValue();

                [progressWindowController performSelectorOnMainThread:@selector(setCurMetric:)
                        withObject:[NSNumber numberWithDouble:metricValue] waitUntilDone:YES];

                LOG4CPLUS_DEBUG(logger_, "** " << iteration << " [" << std::fixed
                                << metricValue << "] ");

                if (multiResReg->GetTransform()->GetNumberOfParameters() < 20)
                    LOG4CPLUS_DEBUG(logger_, "Current position: "
                                    << std::fixed << std::setprecision(4)
                                    << multiResReg->GetTransform()->GetParameters());
            }
        }
        else if (RSGDOpt != 0) // the caller is the RSGD optimizer
        {
            // Log the iteration
            unsigned curIteration = GetOptimizerIteration(RSGDOpt);
            if (iteration != curIteration)
            {
                if ((iteration != 0) && (gradientCalls != 0))
                {
                    LOG4CPLUS_DEBUG(logger_, "Gradient evaluations: " << gradientCalls);
                    gradientCalls = 0;
                }

                iteration = curIteration;
                double metricValue = RSGDOpt->GetValue();
                [progressWindowController performSelectorOnMainThread:@selector(setCurMetric:)
                                                           withObject:[NSNumber numberWithDouble:metricValue] waitUntilDone:YES];
                double stepSize = RSGDOpt->GetCurrentStepLength();
                [progressWindowController performSelectorOnMainThread:@selector(setCurStepSize:)
                                                           withObject:[NSNumber numberWithDouble:stepSize] waitUntilDone:YES];

                LOG4CPLUS_DEBUG(logger_, "** " << iteration
                                << " [metric: " << std::fixed << metricValue
                                << ", step: " << std::fixed << stepSize << "]");

                if (multiResReg->GetTransform()->GetNumberOfParameters() < 20)
                    LOG4CPLUS_DEBUG(logger_, "Current position: " << std::fixed
                                    << multiResReg->GetTransform()->GetParameters());
            }
        }
        else if (versorOpt != 0) // the caller is the Versor optimizer
        {
            // Log the iteration
            unsigned curIteration = GetOptimizerIteration(versorOpt);
            if (iteration != curIteration)
            {
                if ((iteration != 0) && (gradientCalls != 0))
                {
                    LOG4CPLUS_DEBUG(logger_, "Gradient evaluations: " << gradientCalls);
                    gradientCalls = 0;
                }

                iteration = curIteration;
                double metricValue = versorOpt->GetValue();
                [progressWindowController performSelectorOnMainThread:@selector(setCurMetric:)
                                                           withObject:[NSNumber numberWithDouble:metricValue] waitUntilDone:YES];
                double stepSize = versorOpt->GetCurrentStepLength();
                [progressWindowController performSelectorOnMainThread:@selector(setCurStepSize:)
                                                           withObject:[NSNumber numberWithDouble:stepSize] waitUntilDone:YES];

                LOG4CPLUS_DEBUG(logger_, "** " << iteration
                                << " [metric: " << std::fixed << metricValue
                                << ", step: " << std::fixed << stepSize << "]");

                if (multiResReg->GetTransform()->GetNumberOfParameters() < 20)
                    LOG4CPLUS_DEBUG(logger_, "Current position: " << std::fixed
                                    << multiResReg->GetTransform()->GetParameters());
            }
        }

        [progressWindowController performSelectorOnMainThread:@selector(setCurIteration:)
                                                   withObject:[NSNumber numberWithUnsignedInt:iteration] waitUntilDone:YES];
    }
    else if (eventName == "FunctionAndGradientEvaluationIterationEvent")
    {
        ++gradientCalls;
        // GetValue and GetCachedValue seem always to return the same thing.
        // multiResReg->GetLastTransformParameters() does not return anything useful during optimisation.
        //        itk::NumberToString<double> makeStr;
        //        std::string valueStr = makeStr(GetOptimizerValue(multiResReg->GetOptimizer()));
        //        LOG4CPLUS_DEBUG(logger_, "Gradient call:" << gradientCalls << "\n"
        //                        << valueStr << " " << multiResReg->GetTransform()->GetParameters());
        if (LBFGSOpt != 0) // the caller is the LBFGS optimizer
        {
            //            vnl_lbfgs* vnlopt = LBFGSOpt->GetOptimizer();
            //            vnlopt->set_trace(true);
            //            vnlopt->set_verbose(true);

            // Log the iteration
            unsigned curIteration = LBFGSOpt->GetOptimizer()->get_num_iterations();
            if (iteration != curIteration)
            {
                if ((iteration != 0) && (gradientCalls != 0))
                {
                    LOG4CPLUS_DEBUG(logger_, "Gradient evaluations: " << gradientCalls);
                    gradientCalls = 0;
                }

                iteration = curIteration;
                double metricValue = LBFGSOpt->GetValue();
                [progressWindowController performSelectorOnMainThread:@selector(setCurMetric:)
                                                           withObject:[NSNumber numberWithDouble:metricValue] waitUntilDone:YES];
                LOG4CPLUS_DEBUG(logger_, "** " << iteration
                                << " [" << std::fixed << metricValue << "] ");
                if (multiResReg->GetTransform()->GetNumberOfParameters() < 20)
                    LOG4CPLUS_DEBUG(logger_, "Current position: " << std::fixed
                                    << multiResReg->GetTransform()->GetParameters());
            }

            [progressWindowController performSelectorOnMainThread:@selector(setCurIteration:)
                    withObject:[NSNumber numberWithUnsignedInt:iteration] waitUntilDone:YES];
        }
    }
    else if (eventName == "EndEvent")
    {
        if (LBFGSBOpt != 0)
        {
            std::string stopConditionDesc = LBFGSBOpt->GetStopConditionDescription();
            NSString* stopCondDesc = [NSString stringWithUTF8String:stopConditionDesc.c_str()];
            [progressWindowController performSelectorOnMainThread:@selector(setStopCondition:)
                                                       withObject:stopCondDesc waitUntilDone:YES];

        }
        else if (LBFGSOpt != 0)
        {
            // This optimizer always returns -1 (Failure) unless it hits the maximum number of
            // iterations so we deal with that here.
            std::string stopConditionDesc;
            vnl_nonlinear_minimizer::ReturnCodes code = LBFGSOpt->GetOptimizer()->get_failure_code();
            if (code == vnl_nonlinear_minimizer::ERROR_FAILURE)
            {
                //char codeStr[10];
                //snprintf(codeStr, 10, "%d\n", code);
                //stopConditionDesc =  "Stop flag: ";
                //stopConditionDesc += codeStr;
                stopConditionDesc = "Probably converged.";
            }
            else
            {
                stopConditionDesc = LBFGSOpt->GetStopConditionDescription();
            }
            NSString* stopCondDesc = [NSString stringWithUTF8String:stopConditionDesc.c_str()];
            [progressWindowController performSelectorOnMainThread:@selector(setStopCondition:)
                                                       withObject:stopCondDesc waitUntilDone:YES];
        }
        else if (RSGDOpt != 0)
        {
            RSGDOptimizer::StopConditionType stopCondEnum = RSGDOpt->GetStopCondition();
            std::string stopConditionDesc =  "Stop flag: ";
            switch (stopCondEnum)
            {
                case RSGDOptimizer::GradientMagnitudeTolerance:
                    stopConditionDesc += "GradientMagnitudeTolerance\n";
                    break;
                case RSGDOptimizer::StepTooSmall:
                    stopConditionDesc += "StepTooSmall\n";
                    break;
                case RSGDOptimizer::ImageNotAvailable:
                    stopConditionDesc += "ImageNotAvailable\n";
                    break;
                case RSGDOptimizer::CostFunctionError:
                    stopConditionDesc += "CostFunctionError\n";
                    break;
                case RSGDOptimizer::MaximumNumberOfIterations:
                    stopConditionDesc += "MaximumNumberOfIterations\n";
                    break;
                case RSGDOptimizer::Unknown:
                    stopConditionDesc += "Unknown\n";
                    break;
            }
            stopConditionDesc += RSGDOpt->GetStopConditionDescription();
            NSString* stopCondDesc = [NSString stringWithUTF8String:stopConditionDesc.c_str()];
            [progressWindowController performSelectorOnMainThread:@selector(setStopCondition:)
                                                       withObject:stopCondDesc waitUntilDone:YES];
        }
        else if (versorOpt != 0)
        {
            VersorOptimizer::StopConditionType stopCondEnum = versorOpt->GetStopCondition();
            std::string stopConditionDesc =  "Stop flag: ";
            switch (stopCondEnum)
            {
                case VersorOptimizer::GradientMagnitudeTolerance:
                    stopConditionDesc += "GradientMagnitudeTolerance\n";
                    break;
                case VersorOptimizer::StepTooSmall:
                    stopConditionDesc += "StepTooSmall\n";
                    break;
                case VersorOptimizer::ImageNotAvailable:
                    stopConditionDesc += "ImageNotAvailable\n";
                    break;
                case VersorOptimizer::CostFunctionError:
                    stopConditionDesc += "CostFunctionError\n";
                    break;
                case VersorOptimizer::MaximumNumberOfIterations:
                    stopConditionDesc += "MaximumNumberOfIterations\n";
                    break;
                case VersorOptimizer::Unknown:
                    stopConditionDesc += "Unknown\n";
                    break;
            }
            stopConditionDesc += versorOpt->GetStopConditionDescription();
            NSString* stopCondDesc = [NSString stringWithUTF8String:stopConditionDesc.c_str()];
            [progressWindowController performSelectorOnMainThread:@selector(setStopCondition:)
                                                       withObject:stopCondDesc waitUntilDone:YES];

        }
        else
        {
            LOG4CPLUS_WARN(logger_, "Unexpected EndEvent. Caller: " << caller->GetNameOfClass());
        }

    }
    else
    {
        LOG4CPLUS_WARN(logger_, "Unexpected event: " << event.GetEventName());
    }
}

template <class TImage>
void RegistrationObserverBSpline<TImage>::CalcMultiResRegistrationParameters()
{
    LOG4CPLUS_TRACE(logger_, "Enter");

    typedef itk::BSplineTransform<double, TImage::ImageDimension, BSPLINE_ORDER> BSplineTransform;
    typedef itk::MattesMutualInformationImageToImageMetric<TImage, TImage> MMIMetric;

    BSplineTransform* bsplineTransform = dynamic_cast<BSplineTransform*>(multiResReg->GetTransform());
    MMIMetric* mmiMetric = dynamic_cast<MMIMetric*>(multiResReg->GetMetric());
    
    // for logging information below
    std::ostringstream stream;
    
    // These are needed every pass
    unsigned level = multiResReg->GetCurrentLevel();
    unsigned numberOfParameters = multiResReg->GetTransform()->GetNumberOfParameters();
    LOG4CPLUS_DEBUG(logger_, "Registration level = " << level);

    // If this is the first pass (ie level == 0) the transform has partially
    // already been set up because it is used by the registration object to
    // set up the image pyramids before this event is created. Other objects
    // such as the fixed and moving images, the regions, the pyramids and
    // the schedules have beeen created and attached to the registration object
    // at this point.
    
    if (bsplineTransform != 0)
    {
        // Reset the transform based upon the grid size for this level.
        typename BSplineTransform::MeshSizeType meshSize;
        unsigned dims = meshSize.GetSizeDimension();
        unsigned order = bsplineTransform->SplineOrder;
        for (unsigned dim = 0; dim < dims; ++dim)
            meshSize[dim] = gridSizeSchedule(level, dim) - order;

        typedef itk::BSplineTransformParametersAdaptor<BSplineTransform> TransformAdaptorType;
        typename TransformAdaptorType::Pointer adaptor = TransformAdaptorType::New();
        adaptor->SetTransform(bsplineTransform);
        adaptor->SetRequiredTransformDomainOrigin(bsplineTransform->GetTransformDomainOrigin());
        adaptor->SetRequiredTransformDomainDirection(bsplineTransform->GetTransformDomainDirection());
        adaptor->SetRequiredTransformDomainPhysicalDimensions(bsplineTransform->GetTransformDomainPhysicalDimensions());
        adaptor->SetRequiredTransformDomainMeshSize(meshSize);
        adaptor->AdaptTransformParameters();
        
        // Update this since we have changed the transform
        numberOfParameters = bsplineTransform->GetNumberOfParameters();

        // Start this level off where the last one ended
        multiResReg->SetInitialTransformParametersOfNextLevel(bsplineTransform->GetParameters());
    }
    
    // Set the optimizer termination criterion
    if (LBFGSBOpt != 0)
    {
        LBFGSBOpt->SetCostFunctionConvergenceFactor(lbfgsbConvergenceSchedule[level]);
        LBFGSBOpt->SetProjectedGradientTolerance(lbfgsbGradientToleranceSchedule[level]);
        LBFGSBOpt->SetMaximumNumberOfIterations(maxIterSchedule[level]);
        LBFGSBOpt->SetMaximumNumberOfEvaluations(maxIterSchedule[level]);

        LOG4CPLUS_DEBUG(logger_, "Convergence factor set to "
                        << LBFGSBOpt->GetCostFunctionConvergenceFactor());
        LOG4CPLUS_DEBUG(logger_, "Gradient tolerance set to "
                        << LBFGSBOpt->GetProjectedGradientTolerance());
        LOG4CPLUS_DEBUG(logger_, "Max. iterations set to "
                        << LBFGSBOpt->GetMaximumNumberOfIterations());

        // Update bounds arrays to reflect new parameter length
        LBFGSBOptimizer::BoundSelectionType boundSelect(numberOfParameters);
        LBFGSBOptimizer::BoundValueType upperBound(numberOfParameters);
        LBFGSBOptimizer::BoundValueType lowerBound(numberOfParameters);
        boundSelect.Fill(0);
        upperBound.Fill(0.0);
        lowerBound.Fill(0.0);
        LBFGSBOpt->SetBoundSelection(boundSelect);
        LBFGSBOpt->SetUpperBound(upperBound);
        LBFGSBOpt->SetLowerBound(lowerBound);
    }
    else if (LBFGSOpt != 0)
    {
        LBFGSOpt->SetGradientConvergenceTolerance(lbfgsGradientConvergenceSchedule[level]);
        LBFGSOpt->SetDefaultStepLength(lbfgsDefaultStepSizeSchedule[level]);
        LBFGSOpt->SetMaximumNumberOfFunctionEvaluations(maxIterSchedule[level]);
        LOG4CPLUS_DEBUG(logger_, "Gradient convergence set to "
                        << LBFGSOpt->GetGradientConvergenceTolerance());
        LOG4CPLUS_DEBUG(logger_, "Initial step size set to "
                        << LBFGSOpt->GetDefaultStepLength());
        LOG4CPLUS_DEBUG(logger_, "Max. iterations set to "
                        << LBFGSOpt->GetMaximumNumberOfFunctionEvaluations());
        if (bsplineTransform != 0)
        {
            LBFGSOptimizer::ScalesType scales(bsplineTransform->GetNumberOfParameters());
            scales.Fill(1.0);
            LBFGSOpt->SetScales(scales);
        }
    }
    else if (RSGDOpt != 0)
    {
        RSGDOpt->SetMinimumStepLength(rsgdMinStepSizeSchedule[level]);
        RSGDOpt->SetMaximumStepLength(rsgdMaxStepSizeSchedule[level]);
        RSGDOpt->SetRelaxationFactor(rsgdRelaxationFactorSchedule[level]);
        RSGDOpt->SetNumberOfIterations(maxIterSchedule[level]);
        LOG4CPLUS_DEBUG(logger_, "Min. step size set to "
                        << RSGDOpt->GetMinimumStepLength());
        LOG4CPLUS_DEBUG(logger_, "Max. step size set to "
                        << RSGDOpt->GetMaximumStepLength());
        LOG4CPLUS_DEBUG(logger_, "Relaxation factor set to "
                        << RSGDOpt->GetRelaxationFactor());
        LOG4CPLUS_DEBUG(logger_, "Max. iterations set to "
                        << RSGDOpt->GetNumberOfIterations());
        if (bsplineTransform != 0)
        {
            RSGDOptimizer::ScalesType scales(bsplineTransform->GetNumberOfParameters());
            scales.Fill(1.0);
            RSGDOpt->SetScales(scales);
        }
    }
    else if (versorOpt != 0)
    {
        versorOpt->SetMinimumStepLength(versorMinStepSizeSchedule[level]);
        versorOpt->SetMaximumStepLength(versorMaxStepSizeSchedule[level]);
        versorOpt->SetRelaxationFactor(versorRelaxationFactorSchedule[level]);

        // here we change only the translation scaling
        VersorOptimizer::ScalesType scales = versorOpt->GetScales();
        scales[3] = scales[4] = scales[5] = versorScaleFactorSchedule[level];
        versorOpt->SetScales(scales);

        versorOpt->SetNumberOfIterations(maxIterSchedule[level]);
        LOG4CPLUS_DEBUG(logger_, "Min. step size set to "
                        << versorOpt->GetMinimumStepLength());
        LOG4CPLUS_DEBUG(logger_, "Max. step size set to "
                        << versorOpt->GetMaximumStepLength());
        LOG4CPLUS_DEBUG(logger_, "Relaxation factor set to "
                        << versorOpt->GetRelaxationFactor());
        LOG4CPLUS_DEBUG(logger_, "Translation scale factors set to "
                        << versorOpt->GetScales()[3] << ", "
                        << versorOpt->GetScales()[4] << ", "
                        << versorOpt->GetScales()[5]);
        LOG4CPLUS_DEBUG(logger_, "Max. iterations set to "
                        << versorOpt->GetNumberOfIterations());
    }

    // Mattes et al eq 19 (sort of)
    // We need to calculate the number of pixels in the current registration
    // region for calculations below. We will just use the fixed image region
    // and divide it by the appropriate values from the schedule. We will assume
    // that the fixed and moving images are the same size.
    if (mmiMetric != 0)
    {
        typename RegistrationMethod::ScheduleType pyramidSchedule =
                                       multiResReg->GetFixedImagePyramidSchedule();
        unsigned numPixels = multiResReg->GetFixedImageRegion().GetNumberOfPixels();
        unsigned numSamples = numPixels;
        
        if (mmiSampleRateSchedule[level] > 0.999)
            mmiMetric->UseAllPixelsOn();
        else
        {
            float columnFactor = pyramidSchedule[level][0];   // linear factor in column dimension
            float rowFactor = pyramidSchedule[level][1];      // linear factor in row dimension
            numSamples /= columnFactor * rowFactor;           // use floats to avoid integer division
            numSamples *= mmiSampleRateSchedule[level];          // apply user setting for sample rate
            mmiMetric->SetNumberOfSpatialSamples(numSamples);
        }

        mmiMetric->SetNumberOfHistogramBins(mmiNumBinsSchedule[level]);

        LOG4CPLUS_DEBUG(logger_, "Mattes MI parameters");
        LOG4CPLUS_DEBUG(logger_, "   Multiresolution level  = " << level);
        LOG4CPLUS_DEBUG(logger_, "   Column shrink factor   = " << pyramidSchedule[level][0]);
        LOG4CPLUS_DEBUG(logger_, "   Row shrink factor      = " << pyramidSchedule[level][1]);
        LOG4CPLUS_DEBUG(logger_, "   Number of pixels       = " << numPixels);
        if (mmiMetric->GetUseAllPixels())
            LOG4CPLUS_DEBUG(logger_, "   Using all pixels.");
        else
            LOG4CPLUS_DEBUG(logger_, "   Number of samples      = "
                            << mmiMetric->GetNumberOfSpatialSamples());
        LOG4CPLUS_DEBUG(logger_, "   Number of bins         = "
                        << mmiMetric->GetNumberOfHistogramBins());
    }
    
//    stream.str("");
//    stream << "Transform in CalcMultiResRegistrationParameters" << std::endl;
//    stream << "==============================" << std::endl;
//    multiReg->GetTransform()->Print(stream);
//    stream << "==============================" << std::endl;
//    LOG4CPLUS_TRACE(logger_, stream.str());
}
