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
: numImages(params.numImages),
  slicesPerImage(params.slicesPerImage),
  fixedImageNumber(params.fixedImageNumber),
  flippedData(params.flippedData),
  seriesName([params.seriesDescription UTF8String]),
  rigidRegEnabled(params.rigidRegEnabled),
  rigidLevels(params.rigidRegMultiresLevels),
  rigidRegMetric(params.rigidRegMetric),
  rigidRegOptimiser(params.rigidRegOptimizer),
  rigidMaxIter(params.rigidRegMultiresLevels),

  deformRegEnabled(params.deformRegEnabled),
  deformShowField(params.deformShowField),
  deformLevels(params.deformRegMultiresLevels),
  deformRegMetric(params.deformRegMetric),
  deformRegOptimiser(params.deformRegOptimizer),

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

        // Deformable registration
        NSArray* gridSizes = [NSArray arrayWithArray:[params.deformRegGridSizeArray objectAtIndex:level]];
        for (unsigned dim = 0; dim < 3; ++dim)
        {
            num = [gridSizes objectAtIndex:dim];
            deformGridSizes(level, dim) = [num unsignedIntValue];
        }

        num = [params.deformRegMMIHistogramBins objectAtIndex:level];
        deformMMINumBins[level] = [num unsignedIntValue];
        num = [params.deformRegMMISampleRate objectAtIndex:level];
        deformMMISampleRate[level] = [num floatValue];
        num = [params.deformRegLBFGSBCostConvergence objectAtIndex:level];
        deformLBFGSBCostConvergence[level] = [num floatValue];
        num = [params.deformRegLBFGSBGradientTolerance objectAtIndex:level];
        deformLBFGSBGradientTolerance[level] = [num floatValue];
        num = [params.deformRegLBFGSGradientConvergence objectAtIndex:level];
        deformLBFGSGradientConvergence[level] = [num floatValue];
        num = [params.deformRegLBFGSDefaultStepSize objectAtIndex:level];
        deformLBFGSDefaultStepSize[level] = [num floatValue];
        num = [params.deformRegRSGDMinStepSize objectAtIndex:level];
        deformRSGDMinStepSize[level] = [num floatValue];
        num = [params.deformRegRSGDMaxStepSize objectAtIndex:level];
        deformRSGDMaxStepSize[level] = [num floatValue];
        num = [params.deformRegRSGDRelaxationFactor objectAtIndex:level];
        deformRSGDRelaxationFactor[level] = [num floatValue];
        num = [params.deformRegMaxIter objectAtIndex:level];
        deformMaxIter[level] = [num unsignedIntValue];
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

    if (rigidRegEnabled)
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

    if (deformRegEnabled)
    {
        str << "Deformable registration enabled\n";
        str << "  Pyramid levels: " << deformLevels << "\n";
        str << "  Grid size: " << deformGridSizes << "\n";
        str << "  Bspline order: " << BSPLINE_ORDER << "\n";
        str << "  Metric: ";

        if (deformShowField)
            str << "Showing deformation field.\n";
            
        switch (deformRegMetric)
        {
            case MeanSquares:
                str << "Mean squares\n";
                break;
            case MattesMutualInformation:
                str << "Mattes mutual information\n";
                str << "  Number of bins: " << deformMMINumBins << "\n";
                str << "  Sample rate: " << std::fixed << std::setprecision(2)
                                         << deformMMISampleRate << "\n";
                break;
            default:;
        }
        str << "  Optimiser: ";
        switch (deformRegOptimiser)
        {
            case LBFGSB:
                str << "LBFGSB\n";
                str << "  LBFGSB Convergence: " << std::scientific << std::setprecision(2)
                                                << deformLBFGSBCostConvergence << "\n";
                break;
            case LBFGS:
                str << "LBFGS\n";
                str << "  LBFGS Convergence: " << std::scientific << std::setprecision(2)
                                               << deformLBFGSGradientConvergence << "\n";
                break;
            case RSGD:
                str << "RSGD\n";
                str << "  RSGD Min. step size: " << std::scientific << std::setprecision(2)
                                                 << deformRSGDMinStepSize << "\n";
                str << "  RSGD Max. step size: " << std::scientific << std::setprecision(2)
                                                 << deformRSGDMaxStepSize << "\n";
                str << "  RSGD Relaxation factor: " << std::fixed << std::setprecision(2)
                                                    << deformRSGDRelaxationFactor << "\n";
                break;
            default:;
        }


        str << "  Max. iterations: " << deformMaxIter << "\n";
    }
    else
    {
        str << "Deformable registration disabled.\n";
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
