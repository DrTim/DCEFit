//
//  OptimizerUtils.h
//  DCEFit
//
//  Created by Tim Allman on 2013-09-19.
//
//

#ifndef __DCEFit__OptimizerUtils__
#define __DCEFit__OptimizerUtils__

#include "ItkTypedefs.h"

/**
 * Create and initialise an instance of itk::LBFGSBOptimizer
 *
 * @param numberOfParameters The number of variable parameters, determined by the transform
 * @param convergenceFactor Typical values, 1e12 for low accuracy, 1e7 for moderate accuracy
 * 1e1 for extremely high accuracy. This corresponds to the parameter "factr" in the fortran
 * routine. LBFGSBOptimizer::SetCostFunctionConvergenceFactor() throws an exception if an
 * attempt to set the value to something less than 1.0. However, the fortran routine
 * accepts zero as a flag not to use this parameter as a termination criterion.
 * @param gradientTolerance Default value is 1e-5. Setting to zero turns off using
 * this parameter as a termination criterion.
 * @param maxIterations Maximum number iterations allowed before termination.
 * @param maxEvaluations Not sure.
 *
 * @return A smart pointer to an instance of itk::LBFGSBOptimizer
 */
LBFGSBOptimizer::Pointer GetLBFGSBOptimizer(unsigned numberOfParameters, double convergenceFactor,
                                            double gradientTolerance, unsigned maxIterations,
                                            unsigned maxEvaluations);

/**
 * Create and initialise an instance of itk::LBFGSOptimizer
 *
 * @param gradientConvergence Typical value 0.05
 * @param defaultStepLength The initial step length.
 * @param maxIterations Maximum number iterations allowed before termination.
 *
 * @return A smart pointer to an instance of itk::LBFGSBOptimizer
 */
LBFGSOptimizer::Pointer GetLBFGSOptimizer(double gradientConvergence, double defaultStepLength,
                                          unsigned maxIterations);

/**
 * Create an itk::RegularStepGradientDescentOptimizer instance
 * @param maximumStepLength The maximum step length allowed.
 * @param minimumStepLength Terminate when this minimum step length is reached.
 * @param relaxationFactor Determines how much to decrease step length when the
 * direction changes in parameter space. (0.6 to 1.0 for noisy data, 0.5 default)
 * @param maxIterations Terminate after this many iterations.
 *
 * @return Smart pointer to an instance of the class.
 */
RSGDOptimizer::Pointer GetRSGDOptimizer(double maximumStepLength,
            double minimumStepLength, double relaxationFactor, double gradientTolerance,
            unsigned maxIterations);

/**
 * Get the iteration from the optimizer. The virtual function GetCurrentIteration()
 * is not declared in the base class itk::SingleValuedNonLinearOptimizer so the type
 * of optimizer must be determined and then the function called.
 *
 * @param optimizer An optimizer that is a subclass of itk::SingleValuedNonLinearOptimizer
 * @return The current value.
 */
unsigned GetOptimizerIteration(SingleValuedNonLinearOptimizer::Pointer optimizer);

/**
 * Get the final value from the optimizer. The virtual function GetValue() is not declared
 * in the base class itk::SingleValuedNonLinearOptimizer so the type of optimizer
 * must be determined and then the function called.
 *
 * @param optimizer An optimizer that is a subclass of itk::SingleValuedNonLinearOptimizer
 * @return The current value.
 */
double GetOptimizerValue(SingleValuedNonLinearOptimizer::Pointer optimizer);


#endif /* defined(__DCEFit__OptimizerUtils__) */
