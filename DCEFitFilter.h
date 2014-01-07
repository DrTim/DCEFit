//
//  DCEFitFilter.h
//  DCEFit
//
//  Copyright (c) 2013 Tim. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OsiriXAPI/PluginFilter.h"

@class DialogController;
@class Logger;

/**
 * This is the class that OsiriX will load. It is this class which provides the link
 * between OsiriX and DCEFit.
 */
@interface DCEFitFilter : PluginFilter
{
    DialogController* dialogController;
    Logger* logger_;
    //NSArray* stackArray;
}


/**
	The main dialog for the plugin.
 */
@property (assign) DialogController* dialogController;
//@property (assign, readonly) NSArray* stackArray;


/**
	Default init method.
	@returns Initialised instance.
 */
- (id)init;

- (void)dealloc;

/**
	Required method which is called by OsiriX.
	@param menuName The text for the menu item.
	@returns 0L for success. Anything else for failure.
 */
- (long)filterImage:(NSString*)menuName;

/**
	Optional initialisation method called by OsiriX.
 */
- (void)initPlugin;

- (ViewerController *)copyCurrent4DViewerWindow;

//- (ViewerController*)copy4DViewerWindow;

@end
