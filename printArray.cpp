//
//  PrintArray.cpp
//  princomp
//
//  Created by Tim Allman on 2014-09-19.
//  Copyright (c) 2014 Tim Allman. All rights reserved.
//

#include "printArray.h"

#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/fwd.hpp>

#include <string>
#include <complex>
#include <sstream>
#include <iomanip>

std::string printArray(const boost::numeric::ublas::matrix<double>& array, const std::string& name)
{
    std::stringstream str;

    str << name << " = \n\n";

    for (unsigned rowIdx = 0; rowIdx < array.size1(); ++rowIdx)
    {
        for (unsigned colIdx = 0; colIdx < array.size2(); ++colIdx)
            str << std::setprecision(5) << std::setw(10) << std::fixed << array(rowIdx, colIdx) << ", ";
        str << "\n";
    }
    str << std::endl;

    return str.str();
}


std::string printArray(const boost::numeric::ublas::vector<double>& array, const std::string& name)
{
    std::stringstream str;

    str << name << " = \n\n";

    for (unsigned idx = 0; idx < array.size(); ++idx)
    {
        str << std::setprecision(5) << std::setw(10) << std::fixed << array(idx) << "\n";
    }
    str << std::endl;

    return str.str();
}
