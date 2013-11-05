//
//  Region.h
//  DCEFit
//
//  Created by Tim Allman on 2013-07-03.
//
//

#import <Foundation/Foundation.h>

/**
 * This class represents a rectangle in pixel space. It uses integers to represent
 * the region unlike NSRect which uses doubles.
 */
@interface Region : NSObject <NSCopying>
{
    unsigned x_;
    unsigned y_;
    unsigned width_;
    unsigned height_;
}

@property unsigned x;
@property unsigned y;
@property unsigned width;
@property unsigned height;

- (id)init;

- (id)initWithX:(unsigned)x Y:(unsigned)y W:(unsigned)w H:(unsigned)h;

- (id)copyWithZone:(NSZone *)zone;

- (NSString*)asString;

+ (Region*)regionFromString:(NSString*)string;

@end

