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

    // Plugin configuration parameters
    int loggerLevel;
    unsigned numberOfThreads;
    unsigned maxNumberOfThreads;
    BOOL useDefaultNumberOfThreads;

    // General registration parameters
    enum RegistrationSequenceType regSequence;
    unsigned numImages;
    unsigned fixedImageNumber;
    unsigned slicesPerImage;
    BOOL flippedData;

    // Series description in DICOM file
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
    //BOOL rigidRegEnabled;
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

    // general deformable registration parameters
    BOOL deformShowField;

    // B-spline specific parameters
    //BOOL bsplineRegEnabled;
    enum MetricType bsplineRegMetric;
    enum OptimizerType bsplineRegOptimizer;
    NSMutableArray* bsplineRegGridSizeArray;     // contains arrays of NSNumbers (unsigned)
    NSMutableArray* bsplineRegMMIHistogramBins;  // contains NSNumbers (unsigned)
    NSMutableArray* bsplineRegMMISampleRate;     // contains NSNumbers (float)
    NSMutableArray* bsplineRegLBFGSBCostConvergence;
    NSMutableArray* bsplineRegLBFGSBGradientTolerance;
    NSMutableArray* bsplineRegLBFGSGradientConvergence;
    NSMutableArray* bsplineRegLBFGSDefaultStepSize;
    NSMutableArray* bsplineRegRSGDMinStepSize;
    NSMutableArray* bsplineRegRSGDMaxStepSize;
    NSMutableArray* bsplineRegRSGDRelaxationFactor;
    unsigned bsplineRegMultiresLevels;
    NSMutableArray* bsplineRegMaxIter;           // contains NSNumbers (unsigned)

    // Demons specific parameters
    //BOOL demonsRegEnabled;
    NSMutableArray* demonsRegMaxRMSError;     // contains NSNumbers (float)
    unsigned demonsRegHistogramBins;
    unsigned demonsRegHistogramMatchPoints;
    float demonsRegStandardDeviations;
    unsigned demonsRegMultiresLevels;
    NSMutableArray* demonsRegMaxIter;           // contains NSNumbers (unsigned)
}

// Plugin configuration parameters
@property (assign) int loggerLevel;
@property (assign) unsigned numberOfThreads;
@property (assign) unsigned maxNumberOfThreads;
@property (assign) BOOL useDefaultNumberOfThreads;

// General registration parameters
@property (assign) enum RegistrationSequenceType regSequence; ///<
@property (assign) unsigned numImages;          ///< The number of images (2D or 3D) in the series.
@property (assign) unsigned fixedImageNumber;   ///< What the user sees, ie 1,2,3.
@property (assign) unsigned slicesPerImage;     ///< Number of 2D slices in each image.
@property (assign) BOOL flippedData;            ///< OsiriX flippedData flag.
@property (copy) NSString* seriesDescription;   ///< Description to save with new series.
@property (copy) Region2D* fixedImageRegion;    ///< Registration region in plane of the slices.
@property (retain) NSMutableArray* fixedImageMask;  ///< Spatial object registration. mask.

// rigid registration parameters
//@property (assign) BOOL rigidRegEnabled;             /**< Rigid registration enabled if true. */
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
@property (retain) NSMutableArray* rigidRegVersorOptTransScale;  /**< Scaling for translation params. */
@property (retain) NSMutableArray* rigidRegVersorOptMinStepSize;  /**< VersorOpt termination criterion. */
@property (retain) NSMutableArray* rigidRegVersorOptMaxStepSize;  /**< VersorOpt initial step size. */
@property (retain) NSMutableArray* rigidRegVersorOptRelaxationFactor;/**< VersorOpt tuning (~0.0 - 1.0). */
@property (retain) NSMutableArray* rigidRegMaxIter;        /**< Last resort termination criterion. */

// general deformable registration parameters
@property (assign) BOOL deformShowField;               /**< Show the displacement field. */

// B-spline specific deformable registration parameters
//@property (assign) BOOL bsplineRegEnabled;              /**< B-spline registration enabled if true. */
@property (assign) unsigned bsplineRegMultiresLevels;   /**< Number of levels to use (0 - 4). */
@property (assign) enum MetricType bsplineRegMetric;    /**< The metric to use. (enum value) */
@property (assign) enum OptimizerType bsplineRegOptimizer; /**< The optimizer to use. (enum value) */
@property (retain) NSMutableArray* bsplineRegGridSizeArray; /**< Num of Bspline nodes in each dimension. */
@property (retain) NSMutableArray* bsplineRegMMIHistogramBins; /**< Number of bins for MMI metric. */
@property (retain) NSMutableArray* bsplineRegMMISampleRate;    /**< Fraction of voxels to sample for MMI. */
@property (retain) NSMutableArray* bsplineRegLBFGSBCostConvergence;   /**< LBFGSB termination criterion. */         
@property (retain) NSMutableArray* bsplineRegLBFGSBGradientTolerance; /**< LBFGSB termination criterion. */         
@property (retain) NSMutableArray* bsplineRegLBFGSGradientConvergence;/**< LBFGS termination criterion. */          
@property (retain) NSMutableArray* bsplineRegLBFGSDefaultStepSize;    /**< LBFGS initial step size. */              
@property (retain) NSMutableArray* bsplineRegRSGDMinStepSize;         /**< RSGD termination criterion. */           
@property (retain) NSMutableArray* bsplineRegRSGDMaxStepSize;         /**< RSGD initial step size. */               
@property (retain) NSMutableArray* bsplineRegRSGDRelaxationFactor;    /**< RSGD tuning (~0.0 - 1.0). */             
@property (retain) NSMutableArray* bsplineRegMaxIter;             /**< Last resort termination criterion. */

// Demons specific parameters
//@property (assign) BOOL demonsRegEnabled;              /**< Demons registration enabled if true. */
@property (assign) unsigned demonsRegMultiresLevels;   /**< Number of levels to use (0 - 4). */
@property (retain) NSMutableArray* demonsRegMaxRMSError;     // contains NSNumbers (float)
@property (assign) unsigned demonsRegHistogramBins;
@property (assign) unsigned demonsRegHistogramMatchPoints;
@property (assign) float demonsRegStandardDeviations;
@property (retain) NSMutableArray* demonsRegMaxIter;     /**< Last resort termination criterion. */

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

- (BOOL)isRigidRegEnabled;

- (BOOL)isBsplineRegEnabled;

- (BOOL)isDemonsRegEnabled;

@end
