//
//  RegistrationObserverDemons.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#import "RegistrationObserverDemons.h"
#import "RegProgressValues.h"
#import "ProgressWindowController.h"

#include <itkCommand.h>

#include <log4cplus/loggingmacros.h>

template <class TImage, class TDisplacementField>
void RegistrationObserverDemons<TImage, TDisplacementField>::Execute(itk::Object* caller,
                                                                     const itk::EventObject& event)
{
    LOG4CPLUS_TRACE(logger_, event.GetEventName());

    // Get a useful pointer to the calling instance
    RegistrationMethod* mrr = dynamic_cast<RegistrationMethod*>(caller);
    RegistrationFilter* regFilt = dynamic_cast<RegistrationFilter*>(caller);

    if (((mrr != 0) && (mrr != multiResReg)) || ((regFilt != 0) && (regFilt != regFilter)))
    {
        LOG4CPLUS_ERROR(logger_, "RegistrationObserverDemons::Execute called with invalid object: " <<
                        caller->GetNameOfClass());
        throw itk::InvalidArgumentError(__FILE__, __LINE__);
    }

    std::string eventName = event.GetEventName();

    // Check that we have the right kind of event.
    if (eventName == "MultiResolutionIterationEvent")
    {
        unsigned level = multiResReg->GetCurrentLevel();

        // This compensates for a logic flaw in the MultiResolutionPDEDeformableRegistration class.
        if (level >= multiResReg->GetNumberOfLevels())
            return;

        if (mrr != 0)  // the caller is the multires registration object
        {
            LOG4CPLUS_INFO(logger_, "Multiresolution Demons Registration level = " << level);

            // Set the parameters for the current level.
            regFilter->SetMaximumRMSError(optimizerConvergenceSchedule[level]);

            LOG4CPLUS_DEBUG(logger_, "  RMS error set to "
                            << std::fixed << std::setprecision(4) << regFilter->GetMaximumRMSError());

            [progressWindowController performSelectorOnMainThread:@selector(setCurLevel:)
                                                       withObject:[NSNumber numberWithUnsignedInt:level+1] waitUntilDone:YES];
            [progressWindowController performSelectorOnMainThread:@selector(setCurStage:)
                                                       withObject:@"Demons" waitUntilDone:YES];
            [progressWindowController performSelectorOnMainThread:@selector(setMaxIterations:)
                                                       withObject:[NSNumber numberWithUnsignedInt:maxIterSchedule[level]]
                                                    waitUntilDone:YES];
        }
    }
    else if (eventName == "IterationEvent")
    {
        if (regFilt != 0) // the caller is the registration filter
        {
            // Log the iteration
            unsigned iteration = regFilter->GetElapsedIterations();
            //double metricValue = regFilter->GetMetric();
            double diff = regFilter->GetRMSChange();

            [progressWindowController performSelectorOnMainThread:@selector(setCurMetric:)
                                                       withObject:[NSNumber numberWithDouble:diff] waitUntilDone:YES];

            [progressWindowController performSelectorOnMainThread:@selector(setCurIteration:)
                                                       withObject:[NSNumber numberWithUnsignedInt:iteration] waitUntilDone:YES];

            LOG4CPLUS_DEBUG(logger_, "** Iteration: " << iteration
                            << " [" << std::fixed << std::setprecision(4) << diff << "] ");

        }
    }
    else if (eventName == "EndEvent")
    {
        unsigned iteration = regFilter->GetElapsedIterations();
        float metricValue = regFilter->GetMetric();
        double rmsDiff = regFilter->GetRMSChange();

        std::stringstream str;

        unsigned nLevels = multiResReg->GetNumberOfLevels();
        if (iteration < maxIterSchedule[nLevels-1])
        {
            str << "Registration converged"
                << ", Metric: " << std::fixed << std::setprecision(6) << metricValue
                << ", RMS error: " << std::fixed << std::setprecision(4) << rmsDiff;
        }
        else
        {
            str << "Registration stopped at maximum number of iterations, "
                << "RMS error: " << std::fixed << std::setprecision(4) << rmsDiff;
        }

        stopCondition = str.str();

        NSString* stopCondDesc = [NSString stringWithUTF8String:stopCondition.c_str()];
        [progressWindowController performSelectorOnMainThread:@selector(setStopCondition:)
                                                   withObject:stopCondDesc waitUntilDone:YES];
        LOG4CPLUS_DEBUG(logger_, str.str());
    }
    else
    {
        std::string className = caller->GetNameOfClass();
        LOG4CPLUS_INFO(logger_, "Unexpected Event: "
                       << eventName << ". Caller: " << className);
    }
}
