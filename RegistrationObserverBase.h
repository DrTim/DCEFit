//
//  RegistrationObserverBase.h
//  DCEFit
//
//  Created by Tim Allman on 2014-07-15.
//
//

#ifndef DCEFit_RegistrationObserverBase_h
#define DCEFit_RegistrationObserverBase_h

#include "ItkRegistrationParams.h"

#include <itkCommand.h>

#include <log4cplus/logger.h>

class MultiResRegistration;

#ifdef __OBJC__
@class ProgressWindowController;
typedef ProgressWindowController* ProgressWindowControllerPtr;
#else
typedef void* ProgressWindowControllerPtr;
#endif

/**
 * Observer class for deformable registrations.
 * This class is an event observer that is called after each iteration of the
 * registration process. It responds to IterationEvents from instances of
 * itk::ImageRegistrationMethod, itk::MultiResolutionImageRegistrationMethod and
 * itk::LBFGSBOptimizer.
 *
 * During multiresolution registrations it updates the registration parameters
 * at each resolution change.
 */
class RegistrationObserverBase: public itk::Command
{
public:
    typedef RegistrationObserverBase Self;
    typedef itk::Command Superclass;
    typedef itk::SmartPointer<Self> Pointer;

    typedef double CoordinateRepType;

    /**
     * Called by the registration or optimisation object after each iteration.
     * The caller could be one of two registration types or an optimiser
     * type. This is sorted out with attemts to dynamic_cast the itk::Object
     * pointer.
     * @param caller Pointer to the caller
     * @param event Reference to an EventObject. Should only be an IterationEvent object.
     */
    virtual void Execute(itk::Object* caller, const itk::EventObject& event) = 0;

    /**
     * Const caller version of the above Execute function.
     * @param caller Pointer to the caller
     * @param event Reference to an EventObject. May be any kind of event.
     */
    virtual void Execute(const itk::Object* caller, const itk::EventObject& event)
    {
        LOG4CPLUS_WARN(logger_, "Unexpected const object event: " << event.GetEventName());
    }

    /**
     * The number of levels in this registration.
     * @param levels The number of levels in this registration.
     */
    virtual void SetNumberOfLevels(unsigned levels)
    {
        numLevels = levels;
    }

    /**
     *	Terminates the registration.
     */
    virtual void StopRegistration() = 0;

    /**
     * Use this to query whether the registration was cancelled.
     * @return true if the registration was cancelled, false otherwise.
     */
    virtual bool RegistrationWasCancelled()
    {
        return stopReg;
    }

    /**
     * Get the stop condition for the registration. Override this if the optimiser
     * does not give useful information.
     * @return std::string containing information about why the registration ended.
     */
    virtual std::string GetStopCondition()
    {
        return "Stop condition not set.";
    }

    /**
     * Sets the pointer to the progress window controller.
     * @param pointer to the ProgressWindowController instance.
     */
    virtual void SetProgressWindowController(ProgressWindowController* controller)
    {
        progressWindowController = controller;
    }

protected:
    /**
     * Default constructor.
     * Constructor is not public to conform to ITK style.
     */
    RegistrationObserverBase()
    : stopReg(false), iteration(0), numLevels(0)
    {
    }

    log4cplus::Logger logger_;

    /// Stops the registration when set.
    bool stopReg;

    /// current iteration. The optimizer classes don't do this very well
    unsigned iteration;

    /// Number of levels for this registration.
    unsigned numLevels;

    // Used for displaying progress in GUI
    ProgressWindowControllerPtr progressWindowController;
};

#endif
