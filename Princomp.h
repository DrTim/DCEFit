//
//  Princomp.h
//  princomp
//
//  Created by Tim Allman on 2014-09-02.
//  Copyright (c) 2014 Tim Allman. All rights reserved.
//

#ifndef __princomp__Princomp__
#define __princomp__Princomp__

#include "printArray.h"

#include <Eigen/Dense>

#include <iostream>

/**
 * Calculate the principle components (PC) of a matrix. The logic is based upon Octave's
 * princomp.m https://www.gnu.org/software/octave . This is Matlab compatible. See
 * http://www.mathworks.com/help/stats/princomp.html for more information.
 */

class Princomp
{
public:
    /**
     * Convenient typedef for the matrices we will use. By default the matrices are column major order.
     */
    typedef Eigen::MatrixXf MatrixType;
    typedef Eigen::VectorXf VectorType;
    /**
     * Constructor with matrix. The constructor will do all of the calculations
     * the results of which can be accessed with the accessors. The matrix is n
     * rows by p columns where the each row represents one experiment and each
     * column is one variable type.
     * @param Data The matrix of interest. It is passed by value because the
     * copy is modified.
     */
    Princomp(const MatrixType& data)
    : mRows(data.rows()), mCols(data.cols()), mCentredData(data), mCoeffs(mCols, mCols),
    mScores(mRows, mCols), mEigenValues(std::min(mRows, mCols)), mTSquare(mRows),
    mSingVals(std::min(mRows, mCols))
    {

        std::cerr << printArray(data, "data");

        // Subtract the mean of each column
        for (MatrixType::Index col = 0; col < mCols; ++col)
        {
            float mean = mCentredData.col(col).mean();
            for (MatrixType::Index idx = 0; idx < mRows; ++idx)
                mCentredData(idx, col) -= mean;
        }

        std::cerr << printArray(mCentredData, "data zero mean");

        int opts = Eigen::ComputeThinU | Eigen::ComputeThinV;

        if (mCols >= mRows)  // The case where there are more variables than observations
        {
            Eigen::JacobiSVD<MatrixType> svd(mCentredData, opts);
            mU = svd.matrixU();
            mSingVals = svd.singularValues();
            mCoeffs = svd.matrixV();
        }
        else
        {
            Eigen::JacobiSVD<MatrixType> svd(mCentredData.transpose(), opts);
            mCoeffs = svd.matrixU();
            mSingVals = svd.singularValues();
            mV = svd.matrixV();
        }

        for (VectorType::Index idx = 0; idx < mSingVals.size(); ++idx)
        {
            double val = mSingVals(idx);
            mEigenValues(idx) = (val * val) / (mRows - 1);
        }

        std::cout << printArray(data, "data");
        std::cout << printArray(mCentredData, "mCentredData");
        std::cout << printArray(mCoeffs, "mCoeffs");
        std::cout << printArray(mSingVals, "mSingVals");
        std::cout << printArray(mEigenValues, "mEigenValues");
        std::cout << printArray(mV, "mV");
        std::cout << printArray(mU, "mU");

        mScores = mCentredData * mCoeffs;
        std::cout << printArray(mScores, "mScores");
    }


    /**
     * Get the principle component coefficients (loadings).
     * @return p x p matrix of coefficients in which each column represents one PC.
     */
    MatrixType getCoeffs()
    {
        return mCoeffs;
    }

    /**
     * Get the principal component scores, the representation of Data
     * in the principal component space.
     * @return
     */
    MatrixType getScores()
    {
        return mScores;
    }

    /**
     * Get the principal component variances. That is the eigenvalues of the
     * covariance matrix Data.
     * @return
     */
    VectorType getEigenValues()
    {
        return mEigenValues;
    }

    /**
     * Hotelling's T-squared Statistic for each observation in Data
     * @return Hotelling's T-squared Statistic for each observation in Data.
     */
    VectorType getTSquare()
    {
        return mTSquare;
    }

private:
    MatrixType::Index mRows;
    MatrixType::Index mCols;

    MatrixType mCentredData;
    MatrixType mCoeffs;
    MatrixType mScores;
    VectorType mEigenValues;
    VectorType mTSquare;
    VectorType mSingVals;
    MatrixType mU;
    MatrixType mV;
};

#endif /* defined(__princomp__Princomp__) */
