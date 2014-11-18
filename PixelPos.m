//
//  PixelPos.m
//  DCEFit
//
//  Created by Tim Allman on 2014-09-24.
//
//

#import "PixelPos.h"

@implementation PixelPos

@synthesize x;
@synthesize y;

- (id)init
{
    self = [super init];
    if (self)
    {
        x = 0;
        y = 0;
    }
    return self;
}

- (id)initWithX:(int)xCoord Y:(int)yCoord
{
    self = [super init];
    if (self)
    {
        x = xCoord;
        y = yCoord;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    PixelPos* pl = [[PixelPos allocWithZone:zone] initWithX:x Y:y];
    return pl;
}

- (NSString *)description
{
    NSString* str = [NSString stringWithFormat:@"{%d, %d}", x, y];
    return str;
}

@end
