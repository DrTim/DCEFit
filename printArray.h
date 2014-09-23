//
//  PrintArray.h
//  princomp
//
//  Created by Tim Allman on 2014-09-19.
//  Copyright (c) 2014 Tim Allman. All rights reserved.
//

#ifndef __princomp__printArray__
#define __princomp__printArray__

#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/matrix.hpp>

#include <string>
#include <complex>
#include <iomanip>

//std::string printArray(const boost::numeric::ublas::matrix<float>& array, const std::string& name)
//{
//    {
//        std::stringstream str;
//
//        str << name << " = \n\n";
//
//        for (unsigned rowIdx = 0; rowIdx < array.size1(); ++rowIdx)
//        {
//            for (unsigned colIdx = 0; colIdx < array.size2(); ++colIdx)
//                str << std::setprecision(5) << std::setw(10) << std::fixed << array(rowIdx, colIdx) << ", ";
//            str << "\n\n";
//        }
//        
//        return str.str();
//    }
//}
//
std::string printArray(const boost::numeric::ublas::matrix<double>& array, const std::string& name);

std::string printArray(const boost::numeric::ublas::vector<double>& array, const std::string& name);

//std::string printArray(const boost::numeric::ublas::matrix<std::complex<double> >& array, const std::string& name);


#endif /* defined(__princomp__printArray__) */
