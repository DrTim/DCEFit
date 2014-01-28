//
//  RegistrationParams.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-11.
//
//

#import <Foundation/Foundation.h>

#include "ProjectDefs.h"
#include "Region2D.h"

@interface RegistrationParams : NSObject
{
    Logger* logger_;
    
    // General registration parameters
    unsigned numImages;
    unsigned fixedImageNumber;
    unsigned slicesPerImage;
    BOOL flippedData;
    NSString* seriesDescription;

    // Rectangular region to be used in either
    // itk::ImageRegistrationRegion::SetFixedImageRegion() or
    // itk::ImageToImageMetric::SetFixedImageRegion()
    Region2D* fixedImageRegion;

    // Arbitrary list of points taken from the OsiriX ROI to be used
    // to create an itk::BlobSpatialObject<2> which will become the
    // fixed image mask. The points are listed as x0, y0, x1, y1, ...
    NSMutableArray* fixedImageMask;

    // rigid registration parameters
    BOOL rigidRegEnabled;
    unsigned rigidRegMultiresLevels;
    enum MetricType rigidRegMetric;
    enum OptimizerType rigidRegOptimizer;
    NSMutableArray* rigidRegMMIHistogramBins;  // contains NSNumbers (unsigned)
    NSMutableArray* rigidRegMMISampleRate;     // contains NSNumbers (float)
    NSMutableArray* rigidRegLBFGSBCostConvergence;
    NSMutableArray* rigidRegLBFGSBGradientTolerance;
    NSMutableArray* rigidRegLBFGSGradientConvergence;
    NSMutableArray* rigidRegLBFGSDefaultStepSize;
    NSMutableArray* rigidRegRSGDMinStepSize;
    NSMutableArray* rigidRegRSGDMaxStepSize;
    NSMutableArray* rigidRegRSGDRelaxationFactor;
    NSMutableArray* rigidRegMaxIter;           // contains NSNumbers (unsigned)

    // deformable regitration parameters
    BOOL deformRegEnabled;
    BOOL deformShowField;
    unsigned deformRegMultiresLevels;
    enum MetricType deformRegMetric;
    enum OptimizerType deformRegOptimizer;
    NSMutableArray* deformRegGridSize;          // contains NSNumbers (unsigned)
    NSMutableArray* deformRegMMIHistogramBins;  // contains NSNumbers (unsigned)
    NSMutableArray* deformRegMMISampleRate;     // contains NSNumbers (float)
    NSMutableArray* deformRegLBFGSBCostConvergence;
    NSMutableArray* deformRegLBFGSBGradientTolerance;
    NSMutableArray* deformRegLBFGSGradientConvergence;
    NSMutableArray* deformRegLBFGSDefaultStepSize;
    NSMutableArray* deformRegRSGDMinStepSize;
    NSMutableArray* deformRegRSGDMaxStepSize;
    NSMutableArray* deformRegRSGDRelaxationFactor;
    NSMutableArray* deformRegMaxIter;           // contains NSNumbers (unsigned)
}

// General registration parameters
@property (assign) unsigned numImages;
@property (assign) unsigned fixedImageNumber;   // what the user sees, ie 1,2,3
@property (assign) unsigned slicesPerImage;
@property (assign) BOOL flippedData;
@property (copy) NSString* seriesDescription;
@property (copy) Region2D* fixedImageRegion;
@property (retain) NSMutableArray* fixedImageMask;

// rigid registration parameters
@property (assign) BOOL rigidRegEnabled;
@property (assign) unsigned rigidRegMultiresLevels;
@property (assign) enum MetricType rigidRegMetric;
@property (assign) enum OptimizerType rigidRegOptimizer;
@property (retain) NSMutableArray* rigidRegMMIHistogramBins;
@property (retain) NSMutableArray* rigidRegMMISampleRate;
@property (retain) NSMutableArray* rigidRegLBFGSBCostConvergence;
@property (retain) NSMutableArray* rigidRegLBFGSBGradientTolerance;
@property (retain) NSMutableArray* rigidRegLBFGSGradientConvergence;
@property (retain) NSMutableArray* rigidRegLBFGSDefaultStepSize;
@property (retain) NSMutableArray* rigidRegRSGDMinStepSize;
@property (retain) NSMutableArray* rigidRegRSGDMaxStepSize;
@property (retain) NSMutableArray* rigidRegRSGDRelaxationFactor;
@property (retain) NSMutableArray* rigidRegMaxIter;

// deformable regitration parameters
@property (assign) BOOL deformRegEnabled;
@property (assign) BOOL deformShowField;
@property (assign) unsigned deformRegMultiresLevels;
@property (assign) enum MetricType deformRegMetric;
@property (assign) enum OptimizerType deformRegOptimizer;
@property (retain) NSMutableArray* deformRegGridSize;
@property (retain) NSMutableArray* deformRegMMIHistogramBins;
@property (retain) NSMutableArray* deformRegMMISampleRate;
@property (retain) NSMutableArray* deformRegLBFGSBCostConvergence;
@property (retain) NSMutableArray* deformRegLBFGSBGradientTolerance;
@property (retain) NSMutableArray* deformRegLBFGSGradientConvergence;
@property (retain) NSMutableArray* deformRegLBFGSDefaultStepSize;
@property (retain) NSMutableArray* deformRegRSGDMinStepSize;
@property (retain) NSMutableArray* deformRegRSGDMaxStepSize;
@property (retain) NSMutableArray* deformRegRSGDRelaxationFactor;
@property (retain) NSMutableArray* deformRegMaxIter;

- (id)init;

- (void)setFromUserDefaults;

/**
 * Convert the 1 based slice number that the user sees in osirix to a
 * 0 based slice index.
 */
- (unsigned)sliceNumberToIndex:(unsigned)number;

/**
 * Convert the 0 based slice index to a 1 based image number that
 * the user sees in osirix.
 */
- (unsigned)indexToSliceNumber:(unsigned)index;

@end
