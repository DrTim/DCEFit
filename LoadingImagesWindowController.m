//
//  LoadingImagesWindowController.m
//  DCEFit
//
//  Created by Tim Allman on 2014-02-01.
//
//

#import "LoadingImagesWindowController.h"

@implementation LoadingImagesWindowController

@synthesize progresssIndicator;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self)
    {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [progresssIndicator setMinValue:1];
    [progresssIndicator setDoubleValue:1];
}

- (void)setNumImages:(unsigned int)numImages
{
    [progresssIndicator setMaxValue:numImages];
}

- (void)incrementIndicator
{
    [progresssIndicator incrementBy:1];
}

@end
