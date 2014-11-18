//
//  Pca3TpAnal.h
//  DCEFit
//
//  Created by Tim Allman on 2014-09-22.
//
//

#import <Foundation/Foundation.h>

#include <Eigen/Dense>
#include <vector>

@class ROI;
@class DCMPix;
@class Logger;
@class ViewerController;

/* Use these typedefs to set the type of calculation done in the PCA analysis. Any
 * module using these matrix types should import this file. The obvious MatrixType 
 * is not used because it appears in the ITK libraries.
 */
typedef Eigen::MatrixXf Matrix;
typedef Eigen::VectorXf Vector;
typedef Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> RowMatrix;

/*
 1. Select ROI (select from combobox containing time index, time, slice, name)
 2. Create data matrix from one slice in each of time series images.
 3. Do PCA
 */
@interface Pca3TpAnal : NSObject
{
    Logger* logger_;
    ROI* roi_;
    ViewerController* viewer_;
    int sliceIndex_;
    NSArray* coordinates_;

    Matrix dataMatrix_;
    Matrix pcaCoeffs_;
}

@property (readonly) Matrix pcaCoeffs; ///< The matrix of PCA coefficients.
@property (retain) NSArray* roiCoordinates;

/**
 * Initialiser with parameters
 * @param viewer The 4D viewer controller with the time series of interest.
 * @param roi The ROI we will be analysing.
 * @param sliceIdx The index of the slice within the image.
 * @return Instance of this class.
 */
- (id)initWithViewer:(ViewerController *)viewer Roi:(ROI *)roi andSliceIdx:(unsigned)sliceIdx;

/**
 * Calculate the PCA coefficients, storing them in pcaCoeffs;
 */
- (void)calculateCoeffs;

@end
