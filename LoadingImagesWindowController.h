//
//  LoadingImagesWindowController.h
//  DCEFit
//
//  Created by Tim Allman on 2014-02-01.
//
//

#import <Cocoa/Cocoa.h>

@interface LoadingImagesWindowController : NSWindowController
{
    NSProgressIndicator *progresssIndicator;
}

@property (assign) IBOutlet NSProgressIndicator *progresssIndicator;

- (void)setNumImages:(unsigned)numImages;

- (void)incrementIndicator;

@end
