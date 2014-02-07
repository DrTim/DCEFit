//
//  OptimizerUtils.cpp
//  DCEFit
//
//  Created by Tim Allman on 2013-09-19.
//
//

#include "OptimizerUtils.h"

#include <log4cplus/loggingmacros.h>

LBFGSBOptimizer::Pointer GetLBFGSBOptimizer(unsigned numberOfParameters,
            double convergenceFactor, double gradientTolerance, unsigned maxIterations,
            unsigned maxEvaluations)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".GetLBFGSBOptimizer";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Function entry.");

    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName),
                    "numberOfParameters = " << numberOfParameters
                    << ", convergenceFactor = "
                    << std::setprecision(4) << std::scientific
                    << convergenceFactor << ", gradientTolerance = " << gradientTolerance
                    << ", maxIterations = " << maxIterations << ", maxEvaluations = "
                    << maxEvaluations);

    LBFGSBOptimizer::Pointer optimizer = LBFGSBOptimizer::New();
    LBFGSBOptimizer::BoundSelectionType boundSelect(numberOfParameters);
    LBFGSBOptimizer::BoundValueType upperBound(numberOfParameters);
    LBFGSBOptimizer::BoundValueType lowerBound(numberOfParameters);

    // turn off bounds checking
    boundSelect.Fill(0);
    upperBound.Fill(0.0);
    lowerBound.Fill(0.0);

    optimizer->SetBoundSelection(boundSelect);
    optimizer->SetUpperBound(upperBound);
    optimizer->SetLowerBound(lowerBound);

    // default 1e7, 1e12 for low accuracy, 1e1 for high
    optimizer->SetCostFunctionConvergenceFactor(convergenceFactor);
    optimizer->SetProjectedGradientTolerance(gradientTolerance); //default 1e-5
    optimizer->SetMaximumNumberOfIterations(maxIterations);
    optimizer->SetMaximumNumberOfEvaluations(maxEvaluations);
    
    return optimizer;
}

LBFGSOptimizer::Pointer GetLBFGSOptimizer(double gradientConvergenceTolerance,
                                          double defaultStepLength,
                                          unsigned maxIterations)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".GetLBFGSOptimizer";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Entry.");

    LBFGSOptimizer::Pointer optimizer = LBFGSOptimizer::New();
    //optimizer->TraceOn();
    optimizer->SetGradientConvergenceTolerance(gradientConvergenceTolerance);
    optimizer->SetMaximumNumberOfFunctionEvaluations(maxIterations);
    optimizer->SetLineSearchAccuracy(0.9); // max 1.0, default 0.9, min 1e-4
    optimizer->SetDefaultStepLength(defaultStepLength);  // default = 1.0

    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName),
                    "GradientConvergenceTolerance = " << std::setprecision(4) << std::scientific
                    << optimizer->GetGradientConvergenceTolerance()
                    << ", MaximumNumberOfFunctionEvaluations = "
                    << optimizer->GetMaximumNumberOfFunctionEvaluations()
                    << std::setprecision(4) << std::scientific
                    << ", LineSearchAccuracy = " << optimizer->GetLineSearchAccuracy()
                    << std::setprecision(4) << std::scientific
                    << ", DefaultStepLength = " << optimizer->GetDefaultStepLength());

    
    return optimizer;
}

RSGDOptimizer::Pointer GetRSGDOptimizer(double maximumStepLength,
                                        double minimumStepLength, double relaxationFactor, double gradientTolerance,
                                        unsigned maxIterations)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".GetRSGDOptimizer";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Entry.");

    RSGDOptimizer::Pointer optimizer = RSGDOptimizer::New();
    optimizer->SetRelaxationFactor(relaxationFactor);
    optimizer->SetGradientMagnitudeTolerance(gradientTolerance);
    optimizer->SetMaximumStepLength(maximumStepLength);
    optimizer->SetMinimumStepLength(minimumStepLength);
    optimizer->SetNumberOfIterations(maxIterations);

    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName),
                    "RelaxationFactor = "
                    << std::setprecision(4) << std::scientific
                    << optimizer->GetRelaxationFactor()
                    << ", GradientMagnitudeTolerance = "
                    << optimizer->GetGradientMagnitudeTolerance()
                    << ", MaxStepLength = " << optimizer->GetMaximumStepLength()
                    << ", MinStepLength = " << optimizer->GetMinimumStepLength()
                    << ", MaxIterations = " << optimizer->GetNumberOfIterations());
    
    return optimizer;
}

VersorOptimizer::Pointer GetVersorOptimizer(double maximumStepLength,
                                          double minimumStepLength, double relaxationFactor,
                                          double gradientTolerance, unsigned maxIterations)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".GetVersorOptimizer";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Entry.");

    VersorOptimizer::Pointer optimizer = VersorOptimizer::New();
    optimizer->SetRelaxationFactor(relaxationFactor);
    optimizer->SetGradientMagnitudeTolerance(gradientTolerance);
    optimizer->SetMaximumStepLength(maximumStepLength);
    optimizer->SetMinimumStepLength(minimumStepLength);
    optimizer->SetNumberOfIterations(maxIterations);

    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName),
                    "RelaxationFactor = "
                    << std::setprecision(4) << std::scientific
                    << optimizer->GetRelaxationFactor()
                    << ", GradientMagnitudeTolerance = "
                    << optimizer->GetGradientMagnitudeTolerance()
                    << ", MaxStepLength = " << optimizer->GetMaximumStepLength()
                    << ", MinStepLength = " << optimizer->GetMinimumStepLength()
                    << ", MaxIterations = " << optimizer->GetNumberOfIterations());
    
    return optimizer;
}

/**
 * Unfortunately the ITK classes deal with the iteration number differently
 * so this function is needed to sort it out.
 *
 * @param optimizer The optimizer.
 * @return The current iteration.
 */
unsigned GetOptimizerIteration(SingleValuedNonLinearOptimizer::Pointer optimizer)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".GetOptimizerIteration";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Function entry.");

    std::string className = optimizer->GetNameOfClass();
    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName), "Optimizer name = " << className);

    unsigned retVal = 0;

    if (className == "LBFGSBOptimizer")
    {
        retVal = dynamic_cast<LBFGSBOptimizer*>(optimizer.GetPointer())->GetCurrentIteration();
    }
    else if (className == "LBFGSOptimizer")
    {
        retVal = dynamic_cast<LBFGSOptimizer*>(optimizer.GetPointer())->GetOptimizer()->get_num_iterations();
    }
    else if (className == "RegularStepGradientDescentOptimizer")
    {
        retVal = dynamic_cast<RSGDOptimizer*>(optimizer.GetPointer())->GetCurrentIteration();
    }
    else if (className == "GradientDescentOptimizer")
    {
        retVal = dynamic_cast<GDOptimizer*>(optimizer.GetPointer())->GetCurrentIteration();
    }
    else if (className == "VersorRigid3DTransformOptimizer")
    {
        retVal = dynamic_cast<VersorOptimizer*>(optimizer.GetPointer())->GetCurrentIteration();
    }
    else
    {
        LOG4CPLUS_FATAL(log4cplus::Logger::getInstance(loggerName),
                        "Invalid optimizer: " << className);
    }

    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName), "iteration = " << retVal);

    return retVal;
}

double GetOptimizerValue(SingleValuedNonLinearOptimizer::Pointer optimizer)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".GetOptimizerValue";
    log4cplus::Logger logger = log4cplus::Logger::getInstance(loggerName);

    std::string className = optimizer->GetNameOfClass();
    LOG4CPLUS_DEBUG(log4cplus::Logger::getInstance(loggerName), "Optimizer name = " << className);

    double retVal = 0.0;

    if (className == "LBFGSOptimizer")
    {
        retVal = dynamic_cast<LBFGSOptimizer*>(optimizer.GetPointer())->GetCachedValue();
    }
    else if (className == "LBFGSBOptimizer")
    {
        retVal = dynamic_cast<LBFGSBOptimizer*>(optimizer.GetPointer())->GetCachedValue();
    }
    else if (className == "RegularStepGradientDescentOptimizer")
    {
        retVal = dynamic_cast<RSGDOptimizer*>(optimizer.GetPointer())->GetValue();
    }
    else if (className == "VersorRigid3DTransformOptimizer")
    {
        retVal = dynamic_cast<VersorOptimizer*>(optimizer.GetPointer())->GetValue();
    }
    else
    {
        LOG4CPLUS_FATAL(logger, "Invalid optimizer: " << className);
    }

    return retVal;
}
