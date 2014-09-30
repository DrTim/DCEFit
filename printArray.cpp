//
//  PrintArray.cpp
//  princomp
//
//  Created by Tim Allman on 2014-09-19.
//  Copyright (c) 2014 Tim Allman. All rights reserved.
//

#include "printArray.h"

#include <string>
#include <complex>
#include <sstream>
#include <iomanip>


std::string printArray(const Eigen::MatrixXf& array, const std::string& name)
{
    std::stringstream str;

    str << name << " = \n\n";

    for (unsigned rowIdx = 0; rowIdx < array.rows(); ++rowIdx)
    {
        for (unsigned colIdx = 0; colIdx < array.cols(); ++colIdx)
            str << std::setprecision(5) << std::setw(10) << std::fixed
                << array(rowIdx, colIdx) << ", ";
        str << "\n";
    }
    str << std::endl;

    return str.str();
}
