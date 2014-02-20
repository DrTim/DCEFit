//
//  DCEFitFilter.m
//  DCEFit
//
//  Copyright (c) 2013 Tim. All rights reserved.
//

//#import <OsiriX/DCMObject.h>
//#import <OsiriX/DCMAttribute.h>
//#import <OsiriX/DCMAttributeTag.h>
//#import <OsiriX/DCMCalendarDate.h>
//#import <OsiriXAPI/DicomImage.h>
//#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/ViewerController.h>
#import "ViewerController+ExportTimeSeries.h"
//
//#import "ProjectDefs.h"
#import "DCEFitFilter.h"
#import "DialogController.h"
//#import "SeriesInfo.h"
//#import "LoadingImagesWindowController.h"
//#import "UserDefaults.h"

@implementation DCEFitFilter

@synthesize dialogController;

- (id)init
{
    NSLog(@"DCEFitFilter.init");
    self = [super init];
    if (self)
    {
        //seriesInfo = [[SeriesInfo alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) initPlugin
{
    NSLog(@"DCEFitFilter.initPlugin");
}

- (long) filterImage:(NSString*) menuName
{
    NSLog(@"DCEFitFilter.filterImage:%@", menuName);

    // Before anything else, we check to see if either we are in a 4D viewer.
    // We cannot continue if the user has loaded a time series of images in
    // the 2D viewer.
    if ([viewerController maxMovieIndex] == 1) // test for 2D viewer
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];

        [alert addButtonWithTitle:@"Close"];
        [alert setMessageText:@"DCEFit plugin."];
        [alert setInformativeText:@"This is a time series of images."
         " Please reopen the series in the 4D viewer in order to analyse it with DCEFit."];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:viewerController.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];

        NSLog(@"This is a time series of 2D or 3D images. Please reopen the series in the 4D viewer.");

        // return 0 to suppress the OsiriX failure alert.
        return 0;
    }

    if (dialogController == nil)
    {
        dialogController = [[DialogController alloc] initWithViewerController:viewerController
                                                                       Filter:self];

        [dialogController.window setFrameAutosaveName:@"DCEFitMainDialog"];
        //[dialogController.window makeKeyAndOrderFront:nil];
    }
    
    return 0;
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    return;
}

/**
 * Duplicates a 4D viewer.
 * @returns The new 4D viewer instance
 */
- (ViewerController*)copyCurrent4DViewerWindow
{
    NSLog(@"Entering copyCurrent4DViewerWindow");

    // each pixel contains either a 32-bit float or a 32-bit ARGB value
    const int ELEMENT_SIZE = 4;

    ViewerController *new4DViewer = nil;
    float* volumePtr = nil;

    // First calculate the amount of memory needed for the new series
    NSArray* pixList0 = [viewerController pixList:0];
    DCMPix* pix0 = [pixList0 objectAtIndex:0];
    size_t memSize = [pix0 pheight] * [pix0 pwidth] * [pixList0 count] * ELEMENT_SIZE ;

    // We will read our current series, and duplicate it by creating a new series!
    unsigned numImages = viewerController.maxMovieIndex;
    for (unsigned timeIdx = 0; timeIdx < numImages; timeIdx++)
    {
        // First calculate the amount of memory needed for the new series
        NSArray* pixList = [viewerController pixList:timeIdx];
        DCMPix* curPix = nil;

        if (memSize > 0)
        {
            volumePtr = (float*)malloc(memSize);// use malloc for allocating memory !

            // Copy the source series in the new one !
            memcpy(volumePtr, [viewerController volumePtr:timeIdx], memSize);

            // Create a NSData object to control the new pointer.
            // Assumes that malloc has been used to allocate memory.
            NSData *volData = [[[NSData alloc]initWithBytesNoCopy:volumePtr
                                                           length:memSize
                                                     freeWhenDone:YES] autorelease];

            // Now copy the DCMPix with the new volumePtr
            NSMutableArray *newPixList = [NSMutableArray array];
            for (unsigned i = 0; i < [pixList count]; i++)
            {
                curPix = [[[pixList objectAtIndex:i] copy] autorelease];
                unsigned offset = [curPix pheight] * [curPix pwidth] * i;//ELEMENT_SIZE * i;
                float* fImage = volumePtr + offset;
                [curPix setfImage:fImage];
                [newPixList addObject: curPix];
            }

            // We don't need to duplicate the DicomFile array, because it is identical.

            // A 2D Viewer window needs 3 things:
            //     a mutable array composed of DCMPix objects
            //     a mutable array composed of DicomFile objects
            //         (The number of DCMPix and DicomFile has to be EQUAL.)
            //     volumeData containing the images, represented in the DCMPix objects
            NSMutableArray* fileList = [viewerController fileList:timeIdx];
            if (new4DViewer == nil)
            {
                new4DViewer = [viewerController newWindow:newPixList :fileList :volData];
                [new4DViewer roiDeleteAll:self];
            }
            else
            {
                [new4DViewer addMovieSerie:newPixList :fileList :volData];
            }
        }
    }

    return new4DViewer;
}


@end
