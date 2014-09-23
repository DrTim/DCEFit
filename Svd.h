//
//  Svd.h
//  princomp
//
//  Created by Tim Allman on 2014-09-17.
//  Copyright (c) 2014 Tim Allman. All rights reserved.
//

#ifndef __princomp__Svd__
#define __princomp__Svd__

#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/fwd.hpp>

#include <Accelerate/Accelerate.h>

/**
 * Truncate the svd according to the truncation type desired.
 */
enum SvdTruncType
{
    LA_SVD_TSVD, /**< Traditional method. Use threshold value of sing. val. */
    LA_SVD_TSCM, /**< Rust's method based upon value of |Utb| */
    LA_SVD_CR    /**< Cont. reg. JMR 100 598-603 (1992) */
};

// From cgesdd.f
// Setting JOBZ to 'S' seems to give the expected dimensionality of U(m,n) and
// V(n,n) so we default the call to 'S' or LA_SVD_SOME
//
// *  JOBZ    (input) CHARACTER*1
// *          Specifies options for computing all or part of the matrix U:
// *          = 'A':  all M columns of U and all N rows of V**H are
// *                  returned in the arrays U and VT;
// *          = 'S':  the first min(M,N) columns of U and the first
// *                  min(M,N) rows of V**H are returned in the arrays U
// *                  and VT;
// *          = 'O':  If M >= N, the first N columns of U are overwritten
// *                  on the array A and all rows of V**H are returned in
// *                  the array VT;
// *                  otherwise, all columns of U are returned in the
// *                  array U and the first M rows of V**H are overwritten
// *                  in the array VT;
// *          = 'N':  no columns of U or rows of V**H are computed.
// *

/*
 * This class represents the singular value decomposition of the array passed
 * to the constructor.
 */
//template <typename T>
class Svd
{
public:
    /**
     * These values correspond to the different values allowed in the parameter
     * jobz described in the comments in sgesdd.c. Because the array to be factored
     * is passed by value we do not accept JOB = 'O'.
     */
    enum OptsType
    {
        All,                 /**< JOB = 'A' */
        Some,                /**< JOB = 'S' */
        None                 /**< JOB = 'N' */
    };
    
    typedef boost::numeric::ublas::matrix<double, boost::numeric::ublas::column_major> MatrixType;
    typedef boost::numeric::ublas::vector<double> VectorType;

    /**
     * Constructor. The calculation is done during construction so the result
     * should be checked bfor errors by calling getInfo() immediately after
     * the constructor returns.
     *
     * @param Array The input matrix of arbitrary dimensionality.
     * @param Option what to calculate. @see SvdOptsType.
     */
    Svd(const MatrixType& array, OptsType optU, OptsType optVt)
    : mArray(array), mOptU(optU), mOptVt(optVt), mM(array.size1()), mN(array.size2()),
      mMin_mn(std::min(mM, mN)), mLda(mM), mLdu(1), mLdvt(1), mLwork(0), mInfo(0)
    {
        __CLPK_integer uCols = 1;   // Number of columns in U
        __CLPK_integer vtCols = 1;  // Number of columns in Vt

        // figure out the dimensions from the options
        switch (mOptU)
        {
            case All:
                mJobU = 'A';
                uCols = mM;
                mLdu = mM;
                break;
            case Some:
                mJobU = 'S';
                uCols = mMin_mn;
                mLdu = mM;
                break;
            case None:
                mJobU = 'N';
                //uCols = 1;
                //mLdu = 1;
                break;
        };

        switch (mOptVt)
        {
            case All:
                mJobVt = 'A';
                vtCols = mN;
                mLdvt = mN;
                break;
            case Some:
                mJobVt = 'S';
                vtCols = mN;
                mLdvt = mMin_mn;
                break;
            case None:
                mJobVt = 'N';
                //vtCols = mN;
                //mLdvt = 1;
                break;
        };

        // Size the containers properly
        mU.resize(mLdu, uCols);
        mVt.resize(mLdvt, vtCols);
        mS.resize(mMin_mn);

        // first we make a work space query
        calcWorkspace();

        // Then do the work.
        calcSvd();

    }

    /**
     * Get the left singular vector matrix.
     * @return the left singular vector (U) matrix.
     */
    MatrixType getU() const
    {
        return mU;
    }

    /**
     * Get the right singular vector matrix, transposed.
     * @return the right singular vector (Vt) matrix.
     */
    MatrixType getVt() const
    {
        return mVt;
    }

    /**
     * Get the singular values vector.
     * @return the singular values (S) vector.
     */
    VectorType getS() const
    {
        return mS;
    }

    /**
     * Get the return value from the lapack svd routine.
     * @return the return value from the lapack svd routine.
     */
    int getInfo() const
    {
        return (int)mInfo;
    }

private:
    /**
     * Calculate the optimal workspace needed by the lapack routine.
     */
    void calcWorkspace()
    {
        double work;
        mLwork = -1;
        dgesvd_(&mJobU, &mJobVt, &mM, &mN, mArray.data().begin(), &mLda, mS.data().begin(), mU.data().begin(),
                &mLdu, mVt.data().begin(), &mLdvt, &work, &mLwork, &mInfo);
        mLwork = (__CLPK_integer)work;
        mWork.resize(mLwork);
    }

    /**
     * Do the svd calculation.
     */
    void calcSvd()
    {
        dgesvd_(&mJobU, &mJobVt, &mM, &mN, mArray.data().begin(), &mLda, mS.data().begin(), mU.data().begin(),
                &mLdu, mVt.data().begin(), &mLdvt, mWork.data().begin(), &mLwork, &mInfo);
    }

    /**
     * Copy constructor. Deliberately not implemented.
     *
     * @param Other The other instance.
     */
    Svd(const Svd &Other);

    /**
     * Assignment operator. Deliberately not implemented.
     *
     * @param Other The other instance.
     *
     * @return Reference to *this.
     */
    Svd &operator=(const Svd &Other);

    // Whe use of __CLPK_integer gives 32/64 bit compatibility.
    MatrixType mArray;
    OptsType mOptU;          // The passed option for the U matrix calculation
    OptsType mOptVt;         // The passed option for the Vt matrix calculation
    __CLPK_integer mM;       // Number of rows in input array
    __CLPK_integer mN;       // Number of columns in input array
    __CLPK_integer mMin_mn;  // minimum of the two dims.
    __CLPK_integer mLda;
    __CLPK_integer mLdu;
    __CLPK_integer mLdvt;
    __CLPK_integer mLwork;
    __CLPK_integer mInfo;

    char mJobU;
    char mJobVt;

    MatrixType mU;
    MatrixType mVt;
    VectorType mS;
    VectorType mWork;
    
};

#endif /* defined(__princomp__Svd__) */
