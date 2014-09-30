//
//  Pca3TpAnal.h
//  DCEFit
//
//  Created by Tim Allman on 2014-09-22.
//
//

#import <Foundation/Foundation.h>

#include <Eigen/Dense>

@class ROI;
@class DCMPix;
@class Logger;
@class ViewerController;

typedef Eigen::MatrixXf MatrixType;
typedef Eigen::VectorXf VectorType;
typedef Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> RowMatrixType;

/*
 1. Select ROI (select from combobox containing time index, time, slice, name)
 2. Create data matrix from one slice in each of time series images.
 3. Do PCA
 */
@interface Pca3TpAnal : NSObject
{
    Logger* mLogger;
    ROI* mRoi;
    ViewerController* mViewer;
    int mSliceIndex;
    NSArray* mCoordinates;

    MatrixType dataMatrix;
}

/**
 * Initialiser with parameters
 * @param viewer The 4D viewer controller with the time series of interest.
 * @param roi The ROI we will be analysing.
 * @param sliceIdx The index of the slice within the image.
 * @return Instance of this class.
 */
- (id)initWithViewer:(ViewerController *)viewer Roi:(ROI *)roi andSliceIdx:(unsigned)sliceIdx;

@end
