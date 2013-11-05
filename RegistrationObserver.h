//
//  RegistrationObserver.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#ifndef __DCEFit__RegistrationObserver__
#define __DCEFit__RegistrationObserver__

#include <log4cplus/logger.h>

#import "ProgressWindowController.h"

#include "ItkTypedefs.h"
#include "ItkRegistrationParams.h"

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
class RegistrationObserver: public itk::Command
{
public:
    typedef RegistrationObserver Self;
    typedef itk::Command Superclass;
    typedef itk::SmartPointer<Self> Pointer;
    itkNewMacro(Self);
    
    typedef double CoordinateRepType;
    
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
     * Const caller version of the above Execute function.
     * @param caller Pointer to the caller
     * @param event Reference to an EventObject. May be any kind of event.
     */
    void Execute(const itk::Object* caller, const itk::EventObject& event);


    /**
     * The number of levels in this registration.
     * @param levels The number of levels in this registration.
     */
    void SetNumberOfLevels(unsigned levels)
    {
        numLevels = levels;
    }

    /**
     * The schedule of grid sizes to use as the resolution increases in
     * multiresolution registrations.
     * The length of shedule must be the same
     * as the number of levels in the registration object.
     * @param schedule The list of grid sizes to use.
     */
    void SetGridSizeSchedule(const ParamVector<unsigned>& schedule)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
            gridSizeSchedule[numLevels - idx - 1] = schedule[idx];
    }
    
    /**
     * Set the multilevel schedules for the MMI metric.
     * @param bins The number of bins in the histogram.
     * @param sampleRate The fraction of the image to sample. 0 < sampleRate <= 1.
     */
    void SetMMISchedules(const ParamVector<unsigned>& bins,
                         const ParamVector<unsigned>& sampleRate)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            mmiNumBinsSchedule[numLevels - idx - 1] = bins[idx];
            mmiSampleRateSchedule[numLevels - idx - 1] = sampleRate[idx];
        }
    }
    
    /**
     * Set the multilevel schedules for the LBFGSB optimizer.
     * @param convergence The metric convergence schedule.
     * @param gradientTolerance The gradient tolerance schedule.
     * @param iterations The maximum number of iterations schedule.
     */
    void SetLBFGSBSchedules(const ParamVector<float>& convergence,
                            const ParamVector<float>& gradientTolerance,
                            const ParamVector<unsigned>& iterations)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            lbfgsbConvergenceSchedule[numLevels - idx - 1] = convergence[idx];
            lbfgsbGradientToleranceSchedule [numLevels - idx - 1] = gradientTolerance[idx];
            maxIterSchedule[numLevels - idx - 1] = iterations[idx];
        }
    }

    /**
     * Set the multilevel schedules for the LBFGS optimizer.
     * @param gradientConvergence The gradient convergence schedule.
     * @param defaultStepSize The initial step size schedule.
     * @param iterations The maximum number of iterations schedule.
     */
    void SetLBFGSSchedules(const ParamVector<float>& gradientConvergence,
                           const ParamVector<float>& defaultStepSize,
                           const ParamVector<unsigned>& iterations)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            lbfgsGradientConvergenceSchedule[numLevels - idx - 1] = gradientConvergence[idx];
            lbfgsDefaultStepSizeSchedule [numLevels - idx - 1] = defaultStepSize[idx];
            maxIterSchedule[numLevels - idx - 1] = iterations[idx];
        }
    }

    /**
     * Set the multilevel schedules for the RSGD optimizer.
     * @param minStepSize The metric convergence schedule.
     * @param maxStepSize The gradient tolerance schedule.
     * @param relaxationFactor The relaxation factor schedule.
     * @param iterations The maximum number of iterations schedule.
     */
    void SetRSGDSchedules(const ParamVector<float>& minStepSize,
                          const ParamVector<float>& maxStepSize,
                          const ParamVector<float>& relaxationFactor,
                          const ParamVector<unsigned>& iterations)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            rsgdMinStepSizeSchedule[numLevels - idx - 1] = minStepSize[idx];
            rsgdMaxStepSizeSchedule[numLevels - idx - 1] = maxStepSize[idx];
            rsgdRelaxationFactorSchedule[numLevels - idx - 1] = relaxationFactor[idx];
            maxIterSchedule[numLevels - idx - 1] = iterations[idx];
        }
    }

    /**
     *	Terminates the registration.
     */
    void StopRegistration();
        
    /**
     * Recalculates the registration parameters at each level of a
     * multi-resolution registration.
     * @param multiReg The multi-resolution registration object.
     */
    void CalcMultiResRegistrationParameters(MultiResRegistration* multiReg);

    /**
     * Sets the pointer to the progress window controller.
     * @param pointer to the ProgressWindowController instance.
     */
    void SetProgressWindowController(ProgressWindowController* controller)
    {
        progressWindowController = controller;
    }

protected:
   /**
    * Default constructor.
    * Constructor is not public to conform to ITK style.
    */
    RegistrationObserver();

private:
    log4cplus::Logger logger_;

    /// Stops the registration when set.
    bool stopReg;

    /// The registration method object
    MultiResRegistration* multiResReg;

    /// The optimizers. Only one will be set but we need this to terminate
    /// a registration early
    LBFGSBOptimizer* LBFGSBOpt;
    LBFGSOptimizer* LBFGSOpt;
    RSGDOptimizer* RSGDOpt;

    /// current iteration. The optimizer classes don't do this very well
    unsigned iteration;

    // counts gradient evaluation calls between iterations.
    unsigned gradientCalls;

    /// Number of levels for this registration.
    unsigned numLevels;
    
    /// schedule for multiresolution grid size
    ParamVector<unsigned> gridSizeSchedule;
    
    /// schedule for multiresolution number of bins for
    /// Mattes mutual information metric
    ParamVector<unsigned> mmiNumBinsSchedule;

    /// schedule for multiresolution sample size (number of pixels to sample) for
    /// Mattes mutual information metric
    ParamVector<float> mmiSampleRateSchedule;

    /// schedules for LBFGSB optimization
    ParamVector<float> lbfgsbConvergenceSchedule;
    ParamVector<float> lbfgsbGradientToleranceSchedule;

    /// schedules for LBFGS optimization
    ParamVector<float> lbfgsGradientConvergenceSchedule;
    ParamVector<float> lbfgsDefaultStepSizeSchedule;

    /// schedules for RSGD optimization
    ParamVector<float> rsgdMinStepSizeSchedule;
    ParamVector<float> rsgdMaxStepSizeSchedule;
    ParamVector<float> rsgdRelaxationFactorSchedule;

    /// schedule for multiresolution maximum number of iterations for
    /// Mattes mutual information metric
    ParamVector<unsigned> maxIterSchedule;

    // Used for displaying progress in GUI
    ProgressWindowController* progressWindowController;
};

#endif /* defined(__DCEFit__RegistrationObserver__) */
