//
//  ProjectDefs.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-26.
//
//

#ifndef DCEFit_ProjectDefs_h
#define DCEFit_ProjectDefs_h

/*
 * This file contains only C compatible definitions, #defines etc that are
 * used throughout the program. This ensures that they are usable by any
 * module be it C, C++, Obj-C or Obj-C++.
 */

// These values must be synchronised with the values of the
// tags of the radio button cells.
enum MetricType
{
    MeanSquares = 0,
    MattesMutualInformation = 1
};

// Used as a selector for the optimizer to use
enum OptimizerType
{
    LBFGSB = 0,
    LBFGS = 1,
    RSGD = 2,
    Versor = 3
};

/**
 * Values to use to return the results of the registration.
 */
enum ResultCode
{
    SUCCESS = 0,   /// All went well.
    FAILURE = 1,   /// Registration was suboptimal but we can continue.
    DISASTER = 2   /// Complete failure resulting in an exception being thrown by ITK.
};

// The size of the arrays containing registration pyramid parameters.
#define MAX_ARRAY_PARAMS 4
#define BSPLINE_ORDER 3

// The name of the logger used through this plugin.
#define LOGGER_NAME "ca.brasscats.osirix.DCEFit"

// The name of the rolling file log that we place in ~/Library/Logs
#define LOG_FILE_NAME LOGGER_NAME;

// The most thhreads we will ever ask for.
#ifdef __i386__
#define MAX_THREADS 4
#else
#define MAX_THREADS 8
#endif

#endif
