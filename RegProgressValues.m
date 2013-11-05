//
//  RegProgressValues.m
//  DCEFit
//
//  Created by Tim Allman on 2013-05-23.
//
//

#import "RegProgressValues.h"

@implementation RegProgressValues

@synthesize curIteration;
@synthesize curLevel;
@synthesize curMetric;
@synthesize curStepSize;
@synthesize curSlice;
@synthesize curStage;
@synthesize maxIterations;

- (id)init
{
    self = [super init];
    if (self)
    {
        curIteration = 0;
        curLevel = 0;
        curMetric = 0.0;
        curStepSize = 0.0;
        curSlice = 0;
        curStage = @"None";
        maxIterations = 0;
    }
    return self;
}

- (void)dealloc
{
    [curStage release];
    [super dealloc];
}

@end
