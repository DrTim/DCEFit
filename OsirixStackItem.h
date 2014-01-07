//
//  OsirixStackItem.h
//  DCEFit
//
//  Created by Tim Allman on 2013-12-23.
//
//

#import <Foundation/Foundation.h>

@interface OsirixStackItem : NSObject
{
    unsigned stackIndex;
    NSArray* ipp;
    float timeIndex;
}

- (id)initWithStackIndex:(unsigned)index Position:(NSArray*)position Time:(float)time;

@property (assign) unsigned stackIndex;
@property (copy) NSArray* ipp;
@property (assign) float timeIndex;

@end
