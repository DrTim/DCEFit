//
//  OsirixStackItem.m
//  DCEFit
//
//  Created by Tim Allman on 2013-12-23.
//
//

#import "OsirixStackItem.h"

@implementation OsirixStackItem

@synthesize stackIndex;
@synthesize ipp;
@synthesize timeIndex;

-(id)initWithStackIndex:(unsigned int)index Position:(NSArray *)position Time:(float)time
{
    self = [super init];
    if (self)
    {
        stackIndex = index;
        ipp = [[NSArray alloc] initWithArray:position copyItems:YES];
        timeIndex = time;
    }
    return self;
}

@end
