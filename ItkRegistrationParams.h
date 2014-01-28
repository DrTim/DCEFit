//
//  ItkRegistrationParams.h
//  DCEFit
//
//  Created by Tim Allman on 2013-06-04.
//
//

#ifndef ITK_REGISTRATION_PARAMS_H
#define ITK_REGISTRATION_PARAMS_H

#import <Foundation/Foundation.h>

#include <log4cplus/loggingmacros.h>

#include <itkImageRegion.h>

#import "RegistrationParams.h"
#include "ProjectDefs.h"
#include "ItkTypedefs.h"

// Essentially a C11 typedef 
template <typename TValueType>
using ParamVector = itk::FixedArray<TValueType, MAX_ARRAY_PARAMS>;

/**
 * This is a class that provides a way of passing the Obj-C based parameters
 * to ITK as C++ parameters.
 * Because this is mostly a POD container, public access is allowed to the members
 * rather than using getters and setters to do the same thing.
 */
class ItkRegistrationParams
{
public:
    ItkRegistrationParams(const RegistrationParams* params);

    virtual ~ItkRegistrationParams();
    
    std::string Print() const;
    unsigned sliceNumberToIndex(unsigned number);
    unsigned indexToSliceNumber(unsigned index);

public:
    unsigned numImages;
    unsigned slicesPerImage;
    unsigned fixedImageNumber;
    bool flippedData;
    std::string seriesName;
    Image2D::RegionType fixedImageRegion;
    SpatialMask2D::Pointer fixedImageMask;

    bool rigidRegEnabled;
    unsigned rigidLevels;
    MetricType rigidRegMetric;
    OptimizerType rigidRegOptimiser;

    ParamVector<unsigned> rigidMMINumBins;
    ParamVector<float> rigidMMISampleRate;
    ParamVector<float> rigidLBFGSBCostConvergence;
    ParamVector<float> rigidLBFGSBGradientTolerance;
    ParamVector<float> rigidLBFGSGradientConvergence;
    ParamVector<float> rigidLBFGSDefaultStepSize;
    ParamVector<float> rigidRSGDMinStepSize;
    ParamVector<float> rigidRSGDMaxStepSize;
    ParamVector<float> rigidRSGDRelaxationFactor;
    ParamVector<unsigned> rigidMaxIter;

    bool deformRegEnabled;
    bool deformShowField;
    unsigned deformLevels;
    MetricType deformRegMetric;
    OptimizerType deformRegOptimiser;
    ParamVector<unsigned> deformGridSizes;
    ParamVector<unsigned> deformMMINumBins;
    ParamVector<float> deformMMISampleRate;
    ParamVector<float> deformLBFGSBCostConvergence;
    ParamVector<float> deformLBFGSBGradientTolerance;
    ParamVector<float> deformLBFGSGradientConvergence;
    ParamVector<float> deformLBFGSDefaultStepSize;
    ParamVector<float> deformRSGDMinStepSize;
    ParamVector<float> deformRSGDMaxStepSize;
    ParamVector<float> deformRSGDRelaxationFactor;
    ParamVector<unsigned> deformMaxIter;

    void createFixedImageMask(Image2D::Pointer image);

private:
    log4cplus::Logger logger_;
    void setRegion(const Region2D* reg);
    const RegistrationParams* objcParams;
};


#endif
