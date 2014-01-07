//
//  DCEFitFilter.m
//  DCEFit
//
//  Copyright (c) 2013 Tim. All rights reserved.
//

#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMAttribute.h"
#import "OsiriX/DCMAttributeTag.h"
#import "OsiriX/DCMCalendarDate.h"

#import "ProjectDefs.h"
#import "SetupLogger.h"
#import "DCEFitFilter.h"
#import "DialogController.h"
#import "OsirixStackItem.h"

@implementation DCEFitFilter

@synthesize dialogController;
//@synthesize stackArray;

- (id)init
{
    NSLog(@"DCEFitFilter.init");
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void)dealloc
{
    [logger_ release];
    [super dealloc];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".DCEFitFilter"];
    logger_ = [[Logger newInstance:loggerName] retain];
}


- (void) initPlugin
{
    NSLog(@"DCEFitFilter.initPlugin");
    [self setupSystemLogger];
}

- (long) filterImage:(NSString*) menuName
{
    NSLog(@"DCEFitFilter.filterImage:%@", menuName);

    // Before anything else, we check to see if either we are in a 4D viewer
    // or the time series consists of 2D images. We cannot continue if the
    // user has loaded a time series of 3D images in the 2D viewer.

//    if ([viewerController maxMovieIndex] == 1)
//    {
//        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//
//        [alert addButtonWithTitle:@"Close"];
//        [alert setMessageText:@"Not a 2D time series."];
//        [alert setInformativeText:@"This is a time series of 3D images."
//         " Please reopen the series in the 4D viewer."];
//        [alert setAlertStyle:NSCriticalAlertStyle];
//        [alert beginSheetModalForWindow:viewerController.window
//                          modalDelegate:self
//                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
//                            contextInfo:nil];
//
//        LOG4M_ERROR(logger_, @"This is a time series of 3D images."
//                    " Please reopen the series in the 4D viewer.");
//        return 1;
//    }
//

    // get some information about what's on the stack
    //unsigned timeImageSlices = [[viewerController pixList] count];
    //timeImageSlices *= [viewerController maxMovieIndex];
    //    stackArray = [NSArray init];

    //    if ([viewerController maxMovieIndex] > 1)
    {
        // We are inside a 2D viewer so we have to be sure that all of the
        // slices are in the same position. we use the DICOM attribute
        // ImagePositionPatient to check this.
        //NSArray* firstIPP = nil;
        NSTimeInterval firstTime = 0.0;
        for (unsigned timeIdx = 0; timeIdx < [viewerController maxMovieIndex]; ++timeIdx)
        {
            NSLog(@"******** timeIdx = %u ***************", timeIdx);
            NSArray* pixList = [viewerController pixList];
            for (unsigned slice = 0; slice < [pixList count]; ++slice)
            {
                DCMPix* curPix = [pixList objectAtIndex:slice];
                NSString* file_path = [curPix sourceFile];
                DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:file_path decodingPixelData:NO];
                DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"ImagePositionPatient"];
                DCMAttribute* attr = [dcmObj attributeForTag:tag];
                NSArray* ippValues = [attr values];
                NSLog(@"IPP = %@", ippValues);
                tag = [DCMAttributeTag tagWithName:@"AcquisitionTime"];
                attr = [dcmObj attributeForTag:tag];
                NSTimeInterval value = [[attr value] timeIntervalSinceReferenceDate];
                //if (timeIdx == 0)
                if (slice == 0)
                    firstTime = value;
                NSLog(@"AcqTime = %f", value - firstTime);

                // Get the IPP of the first slice and complain if any subsequent ones differ.
//                if ((time == 0) && (slice == 0))
//                    firstIPP = [NSArray arrayWithArray:values];
//                else if (![values isEqualToArray:firstIPP])
//                {
//                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//
//                    [alert addButtonWithTitle:@"Close"];
//                    [alert setMessageText:@"Not a 2D time series."];
//                    [alert setInformativeText:@"This is a time series of 3D images."
//                     " Please reopen the series in the 4D viewer."];
//                    [alert setAlertStyle:NSCriticalAlertStyle];
//                    [alert beginSheetModalForWindow:viewerController.window
//                                      modalDelegate:self
//                                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
//                                        contextInfo:nil];
//
//                    LOG4M_ERROR(logger_, @"This is a time series of 3D images."
//                                " Please reopen the series in the 4D viewer.");
//                    return 1;
//                }
            }
        }
    }

//    long            curSlice = [[viewerController imageView] curImage];
//
//    DCMPix          *curPix = [pixList objectAtIndex: curSlice];
//
//    NSString        *dicomTag = @"SeriesDescription";
//
//    DCMObject       *dcmObj = [DCMObject objectWithContentsOfFile:file_path decodingPixelData:NO];
//
//    DCMAttributeTag *tag = [DCMAttributeTag tagWithName:dicomTag];
//    if (!tag) tag = [DCMAttributeTag tagWithTagString:dicomTag];
//
//    NSString        *val = 0;
//    DCMAttribute    *attr;
//
//    if (tag && tag.group && tag.element)
//    {
//        attr = [dcmObj attributeForTag:tag];
//        val = [[attr value] description];
//
//    }
//
//    NSRunInformationalAlertPanel(@"Metadata",
//                                 [NSString stringWithFormat:
//                                  @"Tag Name:%@\nTag ID:%04x,%04x\nTag VR:%@\nValue:%@",
//                                  tag.name, tag.group, tag.element, tag.vr, val],
//                                 @"OK", 0L, 0L);

    if (dialogController == nil)
    {
        dialogController = [[DialogController alloc] init];
        dialogController.parentFilter = self;
        dialogController.keyIdx = -1;
        dialogController.viewerController1 = viewerController;
        //[dialogController connectToViewer:dialogController.viewerController1;
        //[dialogController setupControlsFromParams];

        [dialogController.window setFrameAutosaveName:@"DCEFitMainDialog"];
        [dialogController.window makeKeyAndOrderFront:nil];
    }
    
    return 0;
}

/**
	Sets up the Log4m logger.
 */
- (void)setupSystemLogger
{
    // Now the Log4m logger
    SetupLogger(LOGGER_NAME, LOG4M_LEVEL_DEBUG);
}

- (void)awakeFromNib
{
    // dialogController is created from xib
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    return;
}


- (ViewerController*)copy4DViewerWindow
{
    // each pixel contains either a 32-bit float or a 32-bit ARGB value
    const int ELEMENT_SIZE = 4;

    ViewerController* new4DViewer = nil;
    float* volumePtr = nil;

    // We will read our current series and duplicate it by creating a new series
    for (unsigned timeIdx = 0; timeIdx < viewerController.maxMovieIndex; timeIdx++)
    {
        // First calculate the amount of memory needed for the new series
        NSArray* pL = [viewerController pixList: timeIdx];
        DCMPix* curPix = nil;
        size_t memSize = 0;

        for( int i = 0; i < [pL count]; i++)
        {
            curPix = [pL objectAtIndex: i];
            memSize += [curPix pheight] * [curPix pwidth] * ELEMENT_SIZE;
        }

        if (memSize > 0)
        {
            // use malloc for allocating memory because the NSData instance will use free.
            volumePtr = (float*)malloc(memSize);

            // Copy the source series in the new one !
            memcpy(volumePtr, [viewerController volumePtr: timeIdx], memSize);


            // Create a NSData object to control the new pointer
            NSData *volumeData = [[[NSData alloc] initWithBytesNoCopy:volumePtr length:memSize freeWhenDone:YES] autorelease];


            // Now copy the DCMPix with the new volumePtr
            NSMutableArray *newPixList = [NSMutableArray array];
            for( int i = 0; i < [pL count]; i++)
            {
                curPix = [[[pL objectAtIndex: i] copy] autorelease];
                unsigned offset = [curPix pheight] * [curPix pwidth] * ELEMENT_SIZE * i;
                float* fImage = volumePtr + offset;
                [curPix setfImage: fImage];
                [newPixList addObject: curPix];
            }

            // We don't need to duplicate the DicomFile array, because it is identical!
            // A 2D Viewer window needs 3 things:
            // A mutable array composed of DCMPix objects
            // A mutable array composed of DicomFile objects
            // Number of DCMPix and DicomFile has to be EQUAL !
            // NSData volumeData contains the images, represented in the DCMPix objects
            NSMutableArray* fileList = [viewerController fileList:timeIdx];
            if( new4DViewer == nil)
            {
                new4DViewer = [viewerController newWindow:newPixList :fileList :volumeData];
                [new4DViewer roiDeleteAll: self];
            }
            else
                [new4DViewer addMovieSerie:newPixList :fileList :volumeData];
        }
    }
    
    return new4DViewer;
}


/**
	Duplicates a 4D viewer.
	@returns The new 4D viewer instance
 */
- (ViewerController*)copyCurrent4DViewerWindow
{
    // each pixel contains either a 32-bit float or a 32-bit ARGB value
    const int ELEMENT_SIZE = 4;

    ViewerController *new4DViewer = nil;
    float* volumePtr = nil;

    // We will read our current series, and duplicate it by creating a new series!
    for (unsigned timeIdx = 0; timeIdx < viewerController.maxMovieIndex; timeIdx++)
    {
        // First calculate the amount of memory needed for the new series
        NSArray* pixList = [viewerController pixList:timeIdx];
        DCMPix* curPix = nil;
        size_t memSize = 0;

        for (int i = 0; i < [pixList count]; i++)
        {
            curPix = [pixList objectAtIndex:i];
            memSize += [curPix pheight] * [curPix pwidth] * ELEMENT_SIZE;
        }

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
                unsigned offset = [curPix pheight] * [curPix pwidth] * ELEMENT_SIZE * i;
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
                //NSMutableArray* fileList = [viewerController fileList:timeIdx];
                new4DViewer = [viewerController newWindow:newPixList :fileList :volData];
                [new4DViewer roiDeleteAll:self];
            }
            else
                [new4DViewer addMovieSerie:newPixList :fileList :volData];
        }
    }
    
    return new4DViewer;
}

@end
