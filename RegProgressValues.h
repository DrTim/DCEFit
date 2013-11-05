//
//  RegProgressValues.h
//  DCEFit
//
//  Created by Tim Allman on 2013-05-23.
//
//

#import <Foundation/Foundation.h>

@interface RegProgressValues : NSObject
{
    unsigned curSlice;       // the slice (1 based) we are registering
    unsigned curLevel;       // the level in the image pyramid
    double curMetric;        // the metric at this iteration
    double curStepSize;         // the step size at tis iteration
    NSString* curStage;      // Rigid or Deformable
    unsigned curIteration;   // current iteration number
    unsigned maxIterations;  // the maximum number of iterations
}

@property unsigned curSlice;
@property unsigned curLevel;
@property double curMetric;
@property double curStepSize;
@property (copy) NSString* curStage;
@property unsigned curIteration;
@property unsigned maxIterations;  

@end
