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
using ParamVector = itk::FixedArray<TValueType, MAX_REGISTRATION_LEVELS>;

template <typename TValueType>
using ParamMatrix = itk::Matrix<TValueType, MAX_REGISTRATION_LEVELS, 3>;

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
    unsigned numImages;                      ///< Number of images (time samples) in series, 2D or 3D.
    unsigned slicesPerImage;                 ///< Number of slices (2D) per time sample.
    unsigned fixedImageNumber;               ///< Number of fixed image, 1 based as in OsiriX.
    bool flippedData;                        ///< OsiriX flag. If true, slice #1 is last slice.
    std::string seriesName;                  ///< Series description to save data with.
    Image2D::RegionType fixedImageRegion;    ///< Region to register.
    SpatialMask2D::Pointer fixedImageMask;   ///< Spatial mask for registration.

    bool rigidRegEnabled;                    ///< Do rigid step first if  true.
    unsigned rigidLevels;                    ///< Number of multi-res levels to use (max 4).
    MetricType rigidRegMetric;               ///< Type of metric to use.
    OptimizerType rigidRegOptimiser;         ///< Optimiser to use.

    ParamVector<unsigned> rigidMMINumBins;            ///< MMI bins. See ITK docs.
    ParamVector<float> rigidMMISampleRate;            ///< Fraction of image for MMI metric to sample.
    ParamVector<float> rigidLBFGSBCostConvergence;    ///< Stop criterion. See ITK docs.
    ParamVector<float> rigidLBFGSBGradientTolerance;  ///< Stop criterion. See ITK docs.
    ParamVector<float> rigidLBFGSGradientConvergence; ///< Stop criterion. See ITK docs.
    ParamVector<float> rigidLBFGSDefaultStepSize;     ///< Initial step size. See ITK docs.
    ParamVector<float> rigidRSGDMinStepSize;          ///< Stop criterion. See ITK docs.
    ParamVector<float> rigidRSGDMaxStepSize;          ///< Initial step size. See ITK docs.
    ParamVector<float> rigidRSGDRelaxationFactor;     ///< RSGD tuning. See ITK docs.

    ParamVector<float> rigidVersorOptTransScale;   ///< Versor optim translation scale factor.
    ParamVector<float> rigidVersorOptMinStepSize;  ///< Stop criterion. See ITK docs.
    ParamVector<float> rigidVersorOptMaxStepSize;  ///< Initial step size. See ITK docs.
    ParamVector<float> rigidVersorOptRelaxationFactor; ///< RSGD tuning. See ITK docs.

    ParamVector<unsigned> rigidMaxIter;          ///< Stop at this number of iterations if no convergence.

    bool deformRegEnabled;                     ///< True if deform. reg. is enabled.
    enum DeformableRegistrationType deformRegType; ///< Which type of def. reg. to do if enabled.
    bool deformShowField;                   ///< Show displacement field on image if true.
    unsigned deformLevels;                  ///< Number of multi-res levels to use (max 4).
    ParamVector<unsigned> deformMaxIter; ///< Stop at this number of iterations if no convergence.

    bool bsplineRegEnabled;                  ///< Do Bspline reg if true.
    MetricType bsplineMetric;             ///< Type of metric to use.
    OptimizerType bsplineOptimiser;       ///< Optimiser to use.
    ParamMatrix<unsigned> bsplineGridSizes;    ///< Sizes of BSpline grids to use.
    ParamVector<unsigned> bsplineMMINumBins;   ///< MMI bins. See ITK docs.
    ParamVector<float> bsplineMMISampleRate;   ///< Fraction of image for MMI metric to sample.
    ParamVector<float> bsplineLBFGSBCostConvergence;    ///< Stop criterion. See ITK docs.
    ParamVector<float> bsplineLBFGSBGradientTolerance;  ///< Stop criterion. See ITK docs.
    ParamVector<float> bsplineLBFGSGradientConvergence; ///< Stop criterion. See ITK docs.
    ParamVector<float> bsplineLBFGSDefaultStepSize;     ///< Initial step size. See ITK docs.
    ParamVector<float> bsplineRSGDMinStepSize;          ///< Stop criterion. See ITK docs.
    ParamVector<float> bsplineRSGDMaxStepSize;          ///< Initial step size. See ITK docs.
    ParamVector<float> bsplineRSGDRelaxationFactor;     ///< RSGD tuning. See ITK docs.

    // Demons specific parameters
    bool demonsRegEnabled;
    ParamVector<unsigned> demonsMaxRMSError;     // contains NSNumbers (float)
    unsigned demonsHistogramBins;
    unsigned demonsHistogramMatchPoints;
    float demonsStandardDeviations;

    void createFixedImageMask(Image2D::Pointer image); ///< Create spatial object mask.

private:
    log4cplus::Logger logger_;             ///< The instance logger.
    void setRegion(const Region2D* reg);   ///< Make ITK region from Obj-C region.
    const RegistrationParams* objcParams;  ///< Obj-C params we construct from.
};


#endif
