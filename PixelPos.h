//
//  PixelPos.h
//  DCEFit
//
//  Created by Tim Allman on 2014-09-24.
//
//

#import <Foundation/Foundation.h>

@interface PixelPos : NSObject
{
    int x;
    int y;
}

@property int x;
@property int y;

- (id)init;

- (id)initWithX:(int)xCoord Y:(int)yCoord;

- (id)copyWithZone:(NSZone *)zone;

- (NSString*)asString;

@end
