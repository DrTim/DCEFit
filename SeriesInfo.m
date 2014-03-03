//
//  SeriesInfo.m
//  DCEFit
//
//  Created by Tim Allman on 2014-01-20.
//
//

#import "SeriesInfo.h"

@implementation SeriesInfo

@synthesize numTimeSamples;
@synthesize sliceHeight;
@synthesize sliceWidth;
@synthesize slicesPerImage;
@synthesize isFlipped;
@synthesize keyImageIdx;
@synthesize keySliceIdx;
@synthesize firstROI;

- (id)init
{
    self = [super init];
    if (self)
    {
        keyImageIdx = -1;
        keySliceIdx = -1;
        acqTimeArray = [[NSMutableArray array] retain];
        acqTimeStringArray = [[NSMutableArray array] retain];
    }

    return self;
}

- (void)dealloc
{
    [acqTimeArray release];
    [acqTimeStringArray release];
    [super dealloc];
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:@"numTimeSamples:%u\n"
                      "sliceHeight: %u\n"
                      "sliceWidth: %u\n"
                      "slicesPerImage: %u\n"
                      "keyImageIdx: %d\n"
                      "keySliceIdx: %d\n"
                      "firstROI: %@\n"
                      "acqTimeArray: %@"
                      @"acqTimeStringArray: %@",
                      numTimeSamples, sliceHeight, sliceWidth,
                      slicesPerImage, keyImageIdx, keySliceIdx,
                      firstROI, acqTimeArray, acqTimeStringArray];
    return desc;
}

- (void)addAcqTime:(float)time
{
    NSNumber* num = [NSNumber numberWithFloat:time];
    [acqTimeArray addObject:num];
}

- (float)acqTime:(unsigned)index
{
    return [[acqTimeArray objectAtIndex:index] floatValue];
}

- (void)addAcqTimeString:(NSString*)timeStr
{
    [acqTimeStringArray addObject:timeStr];
}

- (NSString*)acqTimeString:(unsigned)index
{
    return [acqTimeStringArray objectAtIndex:index];
}


@end
