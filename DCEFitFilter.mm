//
//  DCEFitFilter.m
//  DCEFit
//
//  Copyright (c) 2013 Tim. All rights reserved.
//

#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMAttribute.h"
#import "OsiriX/DCMAttributeTag.h"

#import "ProjectDefs.h"
#import "SetupLogger.h"
#import "DCEFitFilter.h"
#import "DialogController.h"

@implementation DCEFitFilter

@synthesize dialogController;

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
    [super dealloc];
}

- (void) initPlugin
{
    NSLog(@"DCEFitFilter.initPlugin");
    [self setupSystemLogger];
}

- (long) filterImage:(NSString*) menuName
{
    NSLog(@"DCEFitFilter.filterImage:%@", menuName);

    id value;
    DCMAttribute* attr;
    NSArray* pixList = [viewerController pixList: 0];
    NSString* file_path;
    for (unsigned slice = 0; slice < [pixList count]; ++slice)
    {
        DCMPix* curPix = [pixList objectAtIndex:slice];
        file_path = [curPix sourceFile];
        DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:file_path decodingPixelData:NO];
        DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"AcquisitionTime"];
        attr = [dcmObj attributeForTag:tag];
        value = [[attr value] description];
        NSArray* pathComponents = [file_path pathComponents];
        NSString* fileName = [pathComponents objectAtIndex:[pathComponents count]-1];
        NSLog(@"%u %@ - Tag Name:%@; ID:%04x,%04x; vr:%@; Value:%@",
              slice, fileName, tag.name, tag.group, tag.element, tag.vr, value);
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

@end
