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
    unsigned curImage;       // the image (1 based) we are registering
    unsigned numImages;      // the number of images
    unsigned curLevel;       // the level in the image pyramid
    double curMetric;        // the metric at this iteration
    double curStepSize;      // the step size at tis iteration
    NSString* curStage;      // Rigid or Deformable
    unsigned curIteration;   // current iteration number
    unsigned maxIterations;  // the maximum number of iterations
}

@property (assign) unsigned curImage;
@property (assign) unsigned numImages;
@property (assign) unsigned curLevel;
@property (assign) double curMetric;
@property (assign) double curStepSize;
@property (copy) NSString* curStage;
@property (assign) unsigned curIteration;
@property (assign) unsigned maxIterations;  

@end
