//
//  RegistrationObserverBSpline.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#ifndef __DCEFit__RegistrationObserverBSpline__
#define __DCEFit__RegistrationObserverBSpline__

#include "ItkRegistrationParams.h"

#include "RegistrationObserverBase.h"

#include <log4cplus/logger.h>

class MultiResRegistration;

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
template <class TImage>
class RegistrationObserverBSpline: public RegistrationObserverBase
{
public:
    typedef RegistrationObserverBSpline Self;
    typedef itk::Command Superclass;
    typedef itk::SmartPointer<Self> Pointer;
    itkNewMacro(Self);
    
    typedef double CoordinateRepType;
    typedef TImage ImageType;
    typedef itk::MultiResolutionImageRegistrationMethod<TImage, TImage> RegistrationMethod;
    
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
     * The schedule of grid sizes to use as the resolution increases in
     * multiresolution registrations.
     * The length of shedule must be the same
     * as the number of levels in the registration object.
     * @param schedule The list of grid sizes to use.
     */
    void SetGridSizeSchedule(const ParamMatrix<unsigned>& schedule)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
            for (unsigned dim = 0; dim < 3; ++dim)
                gridSizeSchedule(numLevels - idx - 1, dim) = schedule(idx, dim);
    }
    
    /**
     * Set the multilevel schedules for the MMI metric.
     * @param bins The number of bins in the histogram.
     * @param sampleRate The fraction of the image to sample. 0 < sampleRate <= 1.
     */
    void SetMMISchedules(const ParamVector<unsigned>& bins,
                         const ParamVector<float>& sampleRate)
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
     * Set the multilevel schedules for the Versor optimizer.
     * @param minStepSize The metric convergence schedule.
     * @param maxStepSize The gradient tolerance schedule.
     * @param relaxationFactor The relaxation factor schedule.
     * @param scaleFactor The translation scale factor.
     * @param iterations The maximum number of iterations schedule.
     */
    void SetVersorSchedules(const ParamVector<float>& minStepSize,
                          const ParamVector<float>& maxStepSize,
                            const ParamVector<float>& relaxationFactor,
                            const ParamVector<float>& scaleFactor,
                          const ParamVector<unsigned>& iterations)
    {
        for (unsigned idx = 0; idx < numLevels; ++idx)
        {
            versorMinStepSizeSchedule[numLevels - idx - 1] = minStepSize[idx];
            versorMaxStepSizeSchedule[numLevels - idx - 1] = maxStepSize[idx];
            versorRelaxationFactorSchedule[numLevels - idx - 1] = relaxationFactor[idx];
            versorScaleFactorSchedule[numLevels - idx - 1] = scaleFactor[idx];
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

        if (LBFGSBOpt != 0)
            LBFGSBOpt->SetMaximumNumberOfIterations(1);
        else if (LBFGSOpt != 0)
            LBFGSOpt->SetMaximumNumberOfFunctionEvaluations(1);
        else if (RSGDOpt != 0)
            RSGDOpt->SetNumberOfIterations(1);
        else if (versorOpt != 0)
            versorOpt->SetNumberOfIterations(1);
    }

protected:
   /**
    * Default constructor.
    * Constructor is not public to conform to ITK style.
    */
    RegistrationObserverBSpline()
    : multiResReg(0), gradientCalls(0)
    {
        std::string name = std::string(LOGGER_NAME) + ".RegistrationObserverBSpline";
        logger_ = log4cplus::Logger::getInstance(name);
        LOG4CPLUS_TRACE(logger_, "Enter");
    }

    /**
     * Recalculates the registration parameters at each level of a
     * multi-resolution registration.
     */
    void CalcMultiResRegistrationParameters();
    
private:
    /// The registration method object
    itk::MultiResolutionImageRegistrationMethod<TImage, TImage>* multiResReg;

    /// The optimizers. Only one will be set but we need this to terminate
    /// a registration early
    LBFGSBOptimizer* LBFGSBOpt;
    LBFGSOptimizer* LBFGSOpt;
    RSGDOptimizer* RSGDOpt;
    VersorOptimizer* versorOpt;

    // counts gradient evaluation calls between iterations.
    unsigned gradientCalls;

    /// schedule for multiresolution grid size
    ParamMatrix<unsigned> gridSizeSchedule;
    
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

    /// schedules for Versor optimization
    ParamVector<float> versorMinStepSizeSchedule;
    ParamVector<float> versorMaxStepSizeSchedule;
    ParamVector<float> versorRelaxationFactorSchedule;
    ParamVector<float> versorScaleFactorSchedule;

    /// schedule for multiresolution maximum number of iterations for
    ParamVector<unsigned> maxIterSchedule;
};

// Explictly instantiate these classes
template class RegistrationObserverBSpline<Image2D>;
template class RegistrationObserverBSpline<Image3D>;

typedef RegistrationObserverBSpline<Image2D> RegistrationObserverBSpline2D;
typedef RegistrationObserverBSpline<Image3D> RegistrationObserverBSpline3D;

#endif /* defined(__DCEFit__RegistrationObserverBSpline__) */
