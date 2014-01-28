//
//  Region.m
//  DCEFit
//
//  Created by Tim Allman on 2013-07-03.
//
//

#import "Region2D.h"

@implementation Region2D

@synthesize x = x_;
@synthesize y = y_;
@synthesize width = width_;
@synthesize height = height_;

- (id)init
{
    self = [super init];
    if (self)
    {
        x_ = 0;
        y_ = 0;
        width_ = 0;
        height_ = 0;
    }
    return self;
}

- (id)initWithX:(unsigned)x Y:(unsigned)y W:(unsigned)w H:(unsigned)h
{
    self = [super init];
    if (self)
    {
        x_ = x;
        y_ = y;
        width_ = w;
        height_ = h;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    Region2D* r = [[Region2D allocWithZone:zone] initWithX:x_ Y:y_ W:width_ H:height_];
    return r;
}

- (NSString *)asString
{
    NSString* str = [NSString stringWithFormat:@"{{%u, %u}, {%u, %u}}", x_, y_, width_, height_];
    return str;
}

+ (Region2D *)regionFromString:(NSString *)string
{
    NSScanner* scanner = [NSScanner scannerWithString:string];
    NSCharacterSet* skipThese = [NSCharacterSet characterSetWithCharactersInString:@"{}, "];
    [scanner setCharactersToBeSkipped:skipThese];

    int x, y, w, h;
    [scanner scanInt:&x];
    [scanner scanInt:&y];
    [scanner scanInt:&w];
    [scanner scanInt:&h];
   
    Region2D* region = [[[Region2D alloc] initWithX:(unsigned)x Y:(unsigned)y
                                              W:(unsigned)w H:(unsigned)h] autorelease];
    return region;
}

@end

