//
//  ItkRegistrationParams.m
//  DCEFit
//
//  Created by Tim Allman on 2013-06-04.
//
//


#import "ItkRegistrationParams.h"
#import "Region.h"

#include <itkContinuousIndex.h>

ItkRegistrationParams::ItkRegistrationParams(const RegistrationParams* params)
: numImages(params.numImages),
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

  ocParams(params)
{
    std::string name = std::string(LOGGER_NAME) + ".ItkRegistrationParams";
    logger_ = log4cplus::Logger::getInstance(name);
    LOG4CPLUS_TRACE(logger_, "");

    //[params retain];
    
    setRegion(params.fixedImageRegion);
    //    createFixedImageMask(params.fixedImageMask);
    
    for (unsigned idx = 0; idx < MAX_ARRAY_PARAMS; ++idx)
    {
        // Rigid registration
        NSNumber* num = [params.rigidRegMMIHistogramBins objectAtIndex:idx];
        rigidMMINumBins[idx] = [num unsignedIntValue];
        num = [params.rigidRegMMISampleRate objectAtIndex:idx];
        rigidMMISampleRate[idx] = [num floatValue];
        num = [params.rigidRegLBFGSBCostConvergence objectAtIndex:idx];
        rigidLBFGSBCostConvergence[idx] = [num floatValue];
        num = [params.rigidRegLBFGSBGradientTolerance objectAtIndex:idx];
        rigidLBFGSBGradientTolerance[idx] = [num floatValue];
        num = [params.rigidRegLBFGSGradientConvergence objectAtIndex:idx];
        rigidLBFGSGradientConvergence[idx] = [num floatValue];
        num = [params.rigidRegLBFGSDefaultStepSize objectAtIndex:idx];
        rigidLBFGSDefaultStepSize[idx] = [num floatValue];
        num = [params.rigidRegRSGDMinStepSize objectAtIndex:idx];
        rigidRSGDMinStepSize[idx] = [num floatValue];
        num = [params.rigidRegRSGDMaxStepSize objectAtIndex:idx];
        rigidRSGDMaxStepSize[idx] = [num floatValue];
        num = [params.rigidRegRSGDRelaxationFactor objectAtIndex:idx];
        rigidRSGDRelaxationFactor[idx] = [num floatValue];
        num = [params.rigidRegMaxIter objectAtIndex:idx];
        rigidMaxIter[idx] = [num unsignedIntValue];

        // Deformable registration
        num = [params.deformRegGridSize objectAtIndex:idx];
        deformGridSizes[idx] = [num unsignedIntValue];
        num = [params.deformRegMMIHistogramBins objectAtIndex:idx];
        deformMMINumBins[idx] = [num unsignedIntValue];
        num = [params.deformRegMMISampleRate objectAtIndex:idx];
        deformMMISampleRate[idx] = [num floatValue];
        num = [params.deformRegLBFGSBCostConvergence objectAtIndex:idx];
        deformLBFGSBCostConvergence[idx] = [num floatValue];
        num = [params.deformRegLBFGSBGradientTolerance objectAtIndex:idx];
        deformLBFGSBGradientTolerance[idx] = [num floatValue];
        num = [params.deformRegLBFGSGradientConvergence objectAtIndex:idx];
        deformLBFGSGradientConvergence[idx] = [num floatValue];
        num = [params.deformRegLBFGSDefaultStepSize objectAtIndex:idx];
        deformLBFGSDefaultStepSize[idx] = [num floatValue];
        num = [params.deformRegRSGDMinStepSize objectAtIndex:idx];
        deformRSGDMinStepSize[idx] = [num floatValue];
        num = [params.deformRegRSGDMaxStepSize objectAtIndex:idx];
        deformRSGDMaxStepSize[idx] = [num floatValue];
        num = [params.deformRegRSGDRelaxationFactor objectAtIndex:idx];
        deformRSGDRelaxationFactor[idx] = [num floatValue];
        num = [params.deformRegMaxIter objectAtIndex:idx];
        deformMaxIter[idx] = [num unsignedIntValue];
    }
}

ItkRegistrationParams::~ItkRegistrationParams()
{
    //[ocParams release];
}

unsigned ItkRegistrationParams::imageNumberToIndex(unsigned number)
{
    if (flippedData)
        return numImages - number;
    else
        return number - 1;
}

unsigned ItkRegistrationParams::indexToImageNumber(unsigned index)
{
    if (flippedData)
        return numImages - index;
    else
        return index + 1;
}

std::string ItkRegistrationParams::Print() const
{
    
    std::stringstream str;

    str << "ItkRegistrationParams\n";
    str << "Number of images: " << numImages << "\n";
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

void ItkRegistrationParams::setRegion(const Region* reg)
{
    // Set the registration region
    Image2DType::RegionType::IndexType index;
    index.SetElement(0, reg.x);
    index.SetElement(1, reg.y);
    Image2DType::SizeType size;
    size.SetElement(0, reg.width);
    size.SetElement(1, reg.height);
    fixedImageRegion.SetIndex(index);
    fixedImageRegion.SetSize(size);
}

void ItkRegistrationParams::createFixedImageMask(Image2DType::Pointer image)
{
    
    if ([ocParams.fixedImageMask count] == 0)
        return;

    Mask2DType::PointListType points;
    unsigned len = [ocParams.fixedImageMask count];
    for(unsigned int idx = 0; idx < len; idx += 2)
    {
        float x = [(NSNumber*)[ocParams.fixedImageMask objectAtIndex:idx] floatValue];
        float y = [(NSNumber*)[ocParams.fixedImageMask objectAtIndex:idx+1] floatValue];

        itk::ContinuousIndex<double, 2> itkIndex;
        itkIndex[0] = x;
        itkIndex[1] = y;
        
        Image2DType::PointType physicalPoint;
        image->TransformContinuousIndexToPhysicalPoint(itkIndex, physicalPoint);

        Mask2DType::BlobPointType point;
        point.SetPosition(physicalPoint[0], physicalPoint[1]);
        points.push_back(point);
    }

    fixedImageMask = Mask2DType::New();
    fixedImageMask->SetPoints(points);

    unsigned len1 = points.size();
    LOG4CPLUS_INFO(logger_, "ITK fixed image mask set.");
    for (unsigned idx = 0; idx < len1; ++idx)
    {
        Mask2DType::PointType point = points[idx].GetPosition();
        LOG4CPLUS_DEBUG(logger_, "    " << std::fixed << point);
    }

    return;
}
