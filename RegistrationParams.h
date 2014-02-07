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
    NSMutableArray* rigidRegVersorOptTransScale;   // contains NSNumbers (float)
    NSMutableArray* rigidRegVersorOptMinStepSize;
    NSMutableArray* rigidRegVersorOptMaxStepSize;
    NSMutableArray* rigidRegVersorOptRelaxationFactor;

    NSMutableArray* rigidRegMaxIter;           // contains NSNumbers (unsigned)

    // deformable regitration parameters
    BOOL deformRegEnabled;
    BOOL deformShowField;
    unsigned deformRegMultiresLevels;
    enum MetricType deformRegMetric;
    enum OptimizerType deformRegOptimizer;
    NSMutableArray* deformRegGridSizeArray;     // contains arrays of NSNumbers (unsigned)
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
@property (assign) unsigned numImages;          ///< The number of images (2D or 3D) in the series.
@property (assign) unsigned fixedImageNumber;   ///< What the user sees, ie 1,2,3.
@property (assign) unsigned slicesPerImage;     ///< Number of 2D slices in each image.
@property (assign) BOOL flippedData;            ///< OsiriX flippedData flag.
@property (copy) NSString* seriesDescription;   ///< Description to save with new series.
@property (copy) Region2D* fixedImageRegion;    ///< Registration region in plane of the slices.
@property (retain) NSMutableArray* fixedImageMask;  ///< Spatial object registration. mask.

// rigid registration parameters
@property (assign) BOOL rigidRegEnabled;             /**< Rigid registration enabled if true. */
@property (assign) unsigned rigidRegMultiresLevels;  /**< Number of levels to use (0 - 4). */
@property (assign) enum MetricType rigidRegMetric;   /**< The metric to use. (enum value) */
@property (assign) enum OptimizerType rigidRegOptimizer;     /**< The optimizer to use. (enum value) */
@property (retain) NSMutableArray* rigidRegMMIHistogramBins; /**< Number of bins for MMI metric. */
@property (retain) NSMutableArray* rigidRegMMISampleRate; /**< Fraction of voxels to sample for MMI. */
@property (retain) NSMutableArray* rigidRegLBFGSBCostConvergence;  /**< LBFGSB termination criterion. */
@property (retain) NSMutableArray* rigidRegLBFGSBGradientTolerance; /**< LBFGSB termination criterion. */
@property (retain) NSMutableArray* rigidRegLBFGSGradientConvergence; /**< LBFGS termination criterion. */
@property (retain) NSMutableArray* rigidRegLBFGSDefaultStepSize;  /**< LBFGS initial step size. */
@property (retain) NSMutableArray* rigidRegRSGDMinStepSize;       /**< RSGD termination criterion. */
@property (retain) NSMutableArray* rigidRegRSGDMaxStepSize;       /**< RSGD initial step size. */
@property (retain) NSMutableArray* rigidRegRSGDRelaxationFactor;  /**< RSGD tuning (~0.0 - 1.0). */
@property (retain) NSMutableArray* rigidRegVersorOptTransScale;  /**< Scaling for translation params (~0.001). */
@property (retain) NSMutableArray* rigidRegVersorOptMinStepSize;  /**< VersorOpt termination criterion. */
@property (retain) NSMutableArray* rigidRegVersorOptMaxStepSize;  /**< VersorOpt initial step size. */
@property (retain) NSMutableArray* rigidRegVersorOptRelaxationFactor;/**< VersorOpt tuning (~0.0 - 1.0). */
@property (retain) NSMutableArray* rigidRegMaxIter;        /**< Last resort termination criterion. */

// deformable regitration parameters
@property (assign) BOOL deformRegEnabled;              /**< Deformable registration enabled if true. */
@property (assign) BOOL deformShowField;               /**< Show the displacement field. */
@property (assign) unsigned deformRegMultiresLevels;   /**< Number of levels to use (0 - 4). */
@property (assign) enum MetricType deformRegMetric;    /**< The metric to use. (enum value) */
@property (assign) enum OptimizerType deformRegOptimizer; /**< The optimizer to use. (enum value) */
@property (retain) NSMutableArray* deformRegGridSizeArray; /**< Num of Bspline nodes in each dimension. */
@property (retain) NSMutableArray* deformRegMMIHistogramBins;   /**< Number of bins for MMI metric. */
@property (retain) NSMutableArray* deformRegMMISampleRate;      /**< Fraction of voxels to sample for MMI. */
@property (retain) NSMutableArray* deformRegLBFGSBCostConvergence;   /**< LBFGSB termination criterion. */         
@property (retain) NSMutableArray* deformRegLBFGSBGradientTolerance; /**< LBFGSB termination criterion. */         
@property (retain) NSMutableArray* deformRegLBFGSGradientConvergence;/**< LBFGS termination criterion. */          
@property (retain) NSMutableArray* deformRegLBFGSDefaultStepSize;    /**< LBFGS initial step size. */              
@property (retain) NSMutableArray* deformRegRSGDMinStepSize;         /**< RSGD termination criterion. */           
@property (retain) NSMutableArray* deformRegRSGDMaxStepSize;         /**< RSGD initial step size. */               
@property (retain) NSMutableArray* deformRegRSGDRelaxationFactor;    /**< RSGD tuning (~0.0 - 1.0). */             
@property (retain) NSMutableArray* deformRegMaxIter;             /**< Last resort termination criterion. */

/**
 * Standard init.
 */
- (id)init;

/**
 * Grab the values in the plugin's UserDefaults instance and fill this instance.
 */
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
