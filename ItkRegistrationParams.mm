//
//  ItkRegistrationParams.m
//  DCEFit
//
//  Created by Tim Allman on 2013-06-04.
//
//


#import "ItkRegistrationParams.h"
#import "Region2D.h"

#include <itkContinuousIndex.h>

ItkRegistrationParams::ItkRegistrationParams(const RegistrationParams* params)
: regSequence(params.regSequence),
  numImages(params.numImages),
  slicesPerImage(params.slicesPerImage),
  fixedImageNumber(params.fixedImageNumber),
  flippedData(params.flippedData),
  seriesName([params.seriesDescription UTF8String]),
  //rigidRegEnabled(params.rigidRegEnabled),
  rigidLevels(params.rigidRegMultiresLevels),
  rigidRegMetric(params.rigidRegMetric),
  rigidRegOptimiser(params.rigidRegOptimizer),
  rigidMaxIter(params.rigidRegMultiresLevels),

  deformShowField(params.deformShowField),

  //bsplineRegEnabled(params.bsplineRegEnabled),
  bsplineLevels(params.bsplineRegMultiresLevels),
  bsplineMetric(params.bsplineRegMetric),
  bsplineOptimiser(params.bsplineRegOptimizer),

  //demonsRegEnabled(params.demonsRegEnabled),
  demonsLevels(params.demonsRegMultiresLevels),
  demonsHistogramBins(params.demonsRegHistogramBins),
  demonsHistogramMatchPoints(params.demonsRegHistogramMatchPoints),
  demonsStandardDeviations(params.demonsRegStandardDeviations),

  objcParams(params)
{
    std::string name = std::string(LOGGER_NAME) + ".ItkRegistrationParams";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");

    //[params retain];
    
    setRegion(params.fixedImageRegion);
    //    createFixedImageMask(params.fixedImageMask);
    
    for (unsigned level = 0; level < MAX_REGISTRATION_LEVELS; ++level)
    {
        // Rigid registration
        NSNumber* num = [params.rigidRegMMIHistogramBins objectAtIndex:level];
        rigidMMINumBins[level] = [num unsignedIntValue];
        num = [params.rigidRegMMISampleRate objectAtIndex:level];
        rigidMMISampleRate[level] = [num floatValue];
        num = [params.rigidRegLBFGSBCostConvergence objectAtIndex:level];
        rigidLBFGSBCostConvergence[level] = [num floatValue];
        num = [params.rigidRegLBFGSBGradientTolerance objectAtIndex:level];
        rigidLBFGSBGradientTolerance[level] = [num floatValue];
        num = [params.rigidRegLBFGSGradientConvergence objectAtIndex:level];
        rigidLBFGSGradientConvergence[level] = [num floatValue];
        num = [params.rigidRegLBFGSDefaultStepSize objectAtIndex:level];
        rigidLBFGSDefaultStepSize[level] = [num floatValue];

        num = [params.rigidRegRSGDMinStepSize objectAtIndex:level];
        rigidRSGDMinStepSize[level] = [num floatValue];
        num = [params.rigidRegRSGDMaxStepSize objectAtIndex:level];
        rigidRSGDMaxStepSize[level] = [num floatValue];
        num = [params.rigidRegRSGDRelaxationFactor objectAtIndex:level];
        rigidRSGDRelaxationFactor[level] = [num floatValue];

        num = [params.rigidRegVersorOptTransScale objectAtIndex:level];
        rigidVersorOptTransScale[level] = [num floatValue];
        num = [params.rigidRegVersorOptMinStepSize objectAtIndex:level];
        rigidVersorOptMinStepSize[level] = [num floatValue];
        num = [params.rigidRegVersorOptMaxStepSize objectAtIndex:level];
        rigidVersorOptMaxStepSize[level] = [num floatValue];
        num = [params.rigidRegVersorOptRelaxationFactor objectAtIndex:level];
        rigidVersorOptRelaxationFactor[level] = [num floatValue];

        num = [params.rigidRegMaxIter objectAtIndex:level];
        rigidMaxIter[level] = [num unsignedIntValue];

        // Bspline registration
        num = [params.bsplineRegMaxIter objectAtIndex:level];
        bsplineMaxIter[level] = [num unsignedIntValue];
        NSArray* gridSizes = [NSArray arrayWithArray:[params.bsplineRegGridSizeArray objectAtIndex:level]];
        for (unsigned dim = 0; dim < 3; ++dim)
        {
            num = [gridSizes objectAtIndex:dim];
            bsplineGridSizes(level, dim) = [num unsignedIntValue];
        }

        num = [params.bsplineRegMMIHistogramBins objectAtIndex:level];
        bsplineMMINumBins[level] = [num unsignedIntValue];
        num = [params.bsplineRegMMISampleRate objectAtIndex:level];
        bsplineMMISampleRate[level] = [num floatValue];
        num = [params.bsplineRegLBFGSBCostConvergence objectAtIndex:level];
        bsplineLBFGSBCostConvergence[level] = [num floatValue];
        num = [params.bsplineRegLBFGSBGradientTolerance objectAtIndex:level];
        bsplineLBFGSBGradientTolerance[level] = [num floatValue];
        num = [params.bsplineRegLBFGSGradientConvergence objectAtIndex:level];
        bsplineLBFGSGradientConvergence[level] = [num floatValue];
        num = [params.bsplineRegLBFGSDefaultStepSize objectAtIndex:level];
        bsplineLBFGSDefaultStepSize[level] = [num floatValue];
        num = [params.bsplineRegRSGDMinStepSize objectAtIndex:level];
        bsplineRSGDMinStepSize[level] = [num floatValue];
        num = [params.bsplineRegRSGDMaxStepSize objectAtIndex:level];
        bsplineRSGDMaxStepSize[level] = [num floatValue];
        num = [params.bsplineRegRSGDRelaxationFactor objectAtIndex:level];
        bsplineRSGDRelaxationFactor[level] = [num floatValue];

        num = [params.demonsRegMaxRMSError objectAtIndex:level];
        demonsMaxRMSError[level] = [num floatValue];
        num = [params.demonsRegMaxIter objectAtIndex:level];
        demonsMaxIter[level] = [num unsignedIntValue];
    }
}

ItkRegistrationParams::~ItkRegistrationParams()
{
    //[ocParams release];
}

unsigned ItkRegistrationParams::sliceNumberToIndex(unsigned number)
{
    if (flippedData)
        return slicesPerImage - number;
    else
        return number - 1;
}

unsigned ItkRegistrationParams::indexToSliceNumber(unsigned index)
{
    if (flippedData)
        return slicesPerImage - index;
    else
        return index + 1;
}

std::string ItkRegistrationParams::Print() const
{
    
    std::stringstream str;

    str << "ItkRegistrationParams\n";
    str << "Number of images: " << numImages << "\n";
    str << "Slices per image: " << slicesPerImage << "\n";
    str << "Flipped data: " << (flippedData ? "Yes" : "No") << "\n";
    str << "Fixed image number: " << fixedImageNumber << "\n";
    str << "Series name: " << seriesName << "\n";

    str << "Region: " << fixedImageRegion << "\n";

    if (isRigidRegEnabled())
    {
        str << "Rigid registration enabled.\n";
        str << "  Pyramid levels: " << rigidLevels << "\n";
        str << "  Metric: ";
        switch (rigidRegMetric)
        {
            case MeanSquares:
                str << "Mean squares\n";
                break;
            case MattesMutualInformation:
                str << "Mattes mutual information\n";
                str << "  Number of bins: " << rigidMMINumBins << "\n";
                str << "  Sample rate: " << std::setprecision(2) << rigidMMISampleRate << "\n";
                break;
            default:;
        }
        str << "  Optimiser: ";
        switch (rigidRegOptimiser)
        {
            case LBFGSB:
                str << "LBFGSB\n";
                str << "  LBFGSB Convergence: " << std::scientific << std::setprecision(2)
                                                << rigidLBFGSBCostConvergence << "\n";
                break;
            case LBFGS:
                str << "LBFGS\n";
                str << "  LBFGS Convergence: " << std::scientific << std::setprecision(2)
                                               << rigidLBFGSGradientConvergence << "\n";
                break;
            case RSGD:
                str << "RSGD\n";
                str << "  RSGD Min. step size: " << std::scientific << std::setprecision(2)
                << rigidRSGDMinStepSize << "\n";
                str << "  RSGD Max. step size: " << std::scientific << std::setprecision(2)
                << rigidRSGDMaxStepSize << "\n";
                str << "  RSGD Relaxation factor: " << std::fixed << std::setprecision(2)
                << rigidRSGDRelaxationFactor << "\n";
                break;
            case Versor:
                str << "Versor\n";
                str << "  Versor translation scale: " << std::scientific << std::setprecision(2)
                << rigidVersorOptTransScale << "\n";
                str << "  Versor Min. step size: " << std::scientific << std::setprecision(2)
                << rigidVersorOptMinStepSize << "\n";
                str << "  Versor Max. step size: " << std::scientific << std::setprecision(2)
                << rigidVersorOptMaxStepSize << "\n";
                str << "  Versor Relaxation factor: " << std::fixed << std::setprecision(2)
                << rigidVersorOptRelaxationFactor << "\n";
                break;
            default:;
        }

        str << "  Max. iterations: " << rigidMaxIter << "\n";
    }
    else
    {
        str << "Rigid registration disabled\n";
    }

    if (isBSplineRegEnabled())
    {
        str << "B-spline deformable registration enabled.\n";
        if (deformShowField)
            str << "  Showing deformation field.\n";
        str << "  Max. iterations: " << bsplineMaxIter << "\n";
        str << "  Pyramid levels: " << bsplineLevels << "\n";
        str << "  Grid size: " << bsplineGridSizes << "\n";
        str << "  Bspline order: " << BSPLINE_ORDER << "\n";
        str << "  Metric: ";
        
        switch (bsplineMetric)
        {
            case MeanSquares:
                str << "Mean squares\n";
                break;
            case MattesMutualInformation:
                str << "Mattes mutual information\n";
                str << "  Number of bins: " << bsplineMMINumBins << "\n";
                str << "  Sample rate: " << std::fixed << std::setprecision(2)
                << bsplineMMISampleRate << "\n";
                break;
            default:;
        }
        str << "  Optimizer: ";
        switch (bsplineOptimiser)
        {
            case LBFGSB:
                str << "LBFGSB\n";
                str << "  LBFGSB Convergence: " << std::scientific << std::setprecision(2)
                << bsplineLBFGSBCostConvergence << "\n";
                break;
            case LBFGS:
                str << "LBFGS\n";
                str << "  LBFGS Convergence: " << std::scientific << std::setprecision(2)
                    << bsplineLBFGSGradientConvergence << "\n";
                break;
            case RSGD:
                str << "RSGD\n";
                str << "  RSGD Min. step size: " << std::scientific << std::setprecision(2)
                    << bsplineRSGDMinStepSize << "\n";
                str << "  RSGD Max. step size: " << std::scientific << std::setprecision(2)
                    << bsplineRSGDMaxStepSize << "\n";
                str << "  RSGD Relaxation factor: " << std::fixed << std::setprecision(2)
                    << bsplineRSGDRelaxationFactor << "\n";
                break;
            default:;
        }
    }
    else
    {
        str << "B-spline deformable registration disabled.\n";
    }

    if (isDemonsRegEnabled())
    {
        str << "Demons registration enabled.\n";
        if (deformShowField)
            str << "  Showing deformation field.\n";
        str << "  Pyramid levels: " << demonsLevels << "\n";
        str << "  Max. iterations: " << demonsMaxIter << "\n";
        str << "  Max. RMS error: " << demonsMaxRMSError << "\n";
        str << "  Histogram bins: " << demonsHistogramBins << "\n";
        str << "  Histogram match points: " << demonsHistogramMatchPoints << "\n";
        str << "  Standard deviations: " << demonsStandardDeviations << "\n";
    }
    else
    {
        str << "Demons registration disabled.\n";
    }

    return str.str();
}

void ItkRegistrationParams::setRegion(const Region2D* reg)
{
    // Set the registration region
    Image2D::RegionType::IndexType index;
    index.SetElement(0, reg.x);
    index.SetElement(1, reg.y);
    Image2D::SizeType size;
    size.SetElement(0, reg.width);
    size.SetElement(1, reg.height);
    fixedImageRegion.SetIndex(index);
    fixedImageRegion.SetSize(size);
}

void ItkRegistrationParams::createFixedImageMask(Image2D::Pointer image)
{
    
    if ([objcParams.fixedImageMask count] == 0)
        return;

    SpatialMask2D::PointListType points;
    unsigned len = [objcParams.fixedImageMask count];
    for(unsigned int idx = 0; idx < len; idx += 2)
    {
        float x = [(NSNumber*)[objcParams.fixedImageMask objectAtIndex:idx] floatValue];
        float y = [(NSNumber*)[objcParams.fixedImageMask objectAtIndex:idx+1] floatValue];

        itk::ContinuousIndex<double, 2> itkIndex;
        itkIndex[0] = x;
        itkIndex[1] = y;
        
        Image2D::PointType physicalPoint;
        image->TransformContinuousIndexToPhysicalPoint(itkIndex, physicalPoint);

        SpatialMask2D::BlobPointType point;
        point.SetPosition(physicalPoint[0], physicalPoint[1]);
        points.push_back(point);
    }

    fixedImageMask = SpatialMask2D::New();
    fixedImageMask->SetPoints(points);

    unsigned len1 = points.size();
    LOG4CPLUS_INFO(logger_, "ITK fixed image mask set.");
    for (unsigned idx = 0; idx < len1; ++idx)
    {
        SpatialMask2D::PointType point = points[idx].GetPosition();
        LOG4CPLUS_DEBUG(logger_, "    " << std::fixed << point);
    }

    return;
}

bool ItkRegistrationParams::isRigidRegEnabled() const
{
    return ((regSequence == Rigid) || (regSequence == RigidBSpline));
}

bool ItkRegistrationParams::isBSplineRegEnabled() const
{
    return ((regSequence == BSpline) || (regSequence == RigidBSpline));
}

bool ItkRegistrationParams::isDemonsRegEnabled() const
{
    return (regSequence == Demons);
}


