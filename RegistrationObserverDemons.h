//
//  RegistrationObserverDemons.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#ifndef __DCEFit__RegistrationObserverDemons__
#define __DCEFit__RegistrationObserverDemons__

#include "ItkTypedefs.h"
#include "ItkRegistrationParams.h"

#include "RegistrationObserverBase.h"

#include <log4cplus/logger.h>

class MultiResRegistration;

#ifdef __OBJC__
@class ProgressWindowController;
typedef ProgressWindowController* ProgressWindowControllerPtr;
#else
typedef void* ProgressWindowControllerPtr;
#endif

/**
 * Observer class for demons registrations.
 * This class is an event observer that is called after each iteration of the
 * registration process. It responds to IterationEvents from instances of
 * itk::ImageRegistrationMethod, itk::MultiResolutionImageRegistrationMethod and
 * itk::LBFGSBOptimizer.
 *
 * During multiresolution registrations it updates the registration parameters
 * at each resolution change.
 */
template <class TImage, class TDisplacementField>
class RegistrationObserverDemons: public RegistrationObserverBase
{
public:
    typedef RegistrationObserverDemons Self;
    typedef itk::Command Superclass;
    typedef itk::SmartPointer<Self> Pointer;
    itkNewMacro(Self);
    
    typedef float CoordinateRepType;
    typedef TImage ImageType;
    typedef itk::DemonsRegistrationFilter<TImage, TImage, TDisplacementField> RegistrationFilter;
    typedef itk::MultiResolutionPDEDeformableRegistration<TImage, TImage, TDisplacementField> RegistrationMethod;
    
    /**
     * Called by the registration or optimisation object after each iteration.
     * The caller could be one of two registration types or an optimiser
     * type. This is sorted out with attemts to dynamic_cast the itk::Object
     * pointer.
     * @param caller Pointer to the caller
     * @param event Reference to an EventObject. Should only be an IterationEvent object.
     */
    void Execute(itk::Object* caller, const itk::EventObject& event);
    
    /**
     * Set the multilevel schedules for the LBFGSB optimizer.
     * @param convergence The metric convergence schedule.
     * @param gradientTolerance The gradient tolerance schedule.
     * @param iterations The maximum number of iterations schedule.
     */
    void SetOptimizerSchedule(const ParamVector<float>& convergence)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            optimizerConvergenceSchedule[numLevels - idx - 1] = convergence[idx];
        }
    }

    /**
     * Set the multilevel iteration schedule for the optimizer.
     * @param iterations The maximum number of iterations schedule.
     */
    void SetIterationSchedule(const ParamVector<unsigned>& iterations)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            maxIterSchedule[numLevels - idx - 1] = iterations[idx];
        }
    }

    /**
     *	Terminates the registration.
     */
    void StopRegistration()
    {
        stopReg = true;
        LOG4CPLUS_DEBUG(logger_, "Registration stopped. Exiting.");
        multiResReg->StopRegistration();

        //        else if (versorOpt != 0)
        //            versorOpt->SetNumberOfIterations(1);
    }

    std::string GetStopCondition()
    {
        return stopCondition;
    }

    void SetRegistrationMethod(typename RegistrationMethod::Pointer reg)
    {
        multiResReg = reg;
    }

    void SetRegistrationFilter(typename RegistrationFilter::Pointer filter)
    {
        regFilter = filter;
    }

protected:
   /**
    * Default constructor.
    * Constructor is not public to conform to ITK style.
    */
    RegistrationObserverDemons()
    : multiResReg(0), regFilter(0)
    {
        std::string name = std::string(LOGGER_NAME) + ".RegistrationObserverDemons";
        logger_ = log4cplus::Logger::getInstance(name);
        LOG4CPLUS_TRACE(logger_, "Enter");
    }

    std::string stopCondition;

private:
    log4cplus::Logger logger_;

    /// The registration method object
    RegistrationMethod* multiResReg;
    RegistrationFilter* regFilter;

    /// schedules for optimization
    ParamVector<float> optimizerConvergenceSchedule;

    /// schedule for multiresolution maximum number of iterations for
    ParamVector<unsigned> maxIterSchedule;
};

// Explictly instantiate these classes
template class RegistrationObserverDemons<Image2D, DemonsDisplacementField2D>;
template class RegistrationObserverDemons<Image3D, DemonsDisplacementField3D>;

#endif /* defined(__DCEFit__RegistrationObserverDemons__) */
