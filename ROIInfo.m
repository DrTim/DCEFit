//
//  ROIInfo.m
//  DCEFit
//
//  Created by Tim Allman on 2014-10-03.
//
//

#import "ROIInfo.h"
#import "IndexConverter.h"
#import "LoggerUtils.h"
#include "PixelPos.h"

#import <OsiriXAPI/ROI.h>
#import <OsirixAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>

@implementation ROIInfo

@synthesize imageIdx = imageIdx_;
@synthesize sliceNum = sliceNum_;
@synthesize roi = roi_;
@synthesize pixelCoordinates = coordinates_;

/*
 * DCMPix* curPix = [[roi curView] curDCM];
 *
 * We should be able to do the above to extract the slice (DCMPix instance) but Osirix neglects to 
 * store the DCMView properly when it propagates ROIs. As a result we have to keep track of the 
 * current DCMPix explicitely. Should this ever change the handling of the DCMPix arrays can be stripped
 * from the code.
 */
- (id)initWithSlice:(DCMPix *)pix roi:(ROI *)roi imageIndex:(NSUInteger)imageIdx sliceNumber:(NSUInteger)sliceNum
{
    self = [super init];
    if (self)
    {
        pix_ = pix;
        roi_ = roi;
        imageIdx_ = imageIdx;
        sliceNum_ = sliceNum;
        coordinates_ = [self setPixelCoordinates];
    }
    return self;
}

- (void)dealloc
{
    [coordinates_ release];

    [super dealloc];
}

- (NSArray *)setPixelCoordinates
{
    NSMutableArray* coordArray = [[NSMutableArray array] retain];

    /*
     * getROIValue is declared in DCMPix.h.
     * 'data' is an array of float with 'size' elements allocated with malloc.
     * 'coords' is an array of float with 'size*2' elements allocated with
     * malloc. The fractional part is always .00000
     * The arrays should be freed by the user.
     */
    long numValues = 0;
    float* coords;
    float* values = [pix_ getROIValue:&numValues :roi_ :&coords];
    for (int idx = 0; idx < numValues; idx += 2)
    {
        PixelPos* pp = [[PixelPos alloc] initWithX:coords[idx] Y:coords[idx+1]];
        [coordArray addObject:pp];
    }

    free(values);
    free(coords);

    return coordArray;
}

- (NSString *)displayString
{
    NSString* retVal = [NSString stringWithFormat:
                        @"%@: Image:%u Slice:%u", self.roi.name, self.imageIdx, self.sliceNum];
    return retVal;

}

- (NSString *)description
{
    NSString* retval = [NSString stringWithFormat:@"{\n%@\n\timageIdx = %d\nsliceNum = %d\n}",
                        self.roi.description, (int)self.imageIdx, (int)self.sliceNum];
    return retval;
}

@end
