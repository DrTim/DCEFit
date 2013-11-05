//
//  RegistrationManager.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-05-02.
//
//


#import "RegistrationManager.h"
#import "ImageImporter.h"
#import "RegisterImageOp.h"

#import "OsiriXAPI/ViewerController.h"

@implementation RegistrationManager

@synthesize itkParams;
@synthesize progressController = progressController_;

- (id)initWithViewer:(ViewerController *)viewerController
                                Params:(RegistrationParams*)regParams
                        ProgressWindow:(ProgressWindowController*)progController
{
    self = [super init];
    if (self)
    {
        [self setupLogger];
        LOG4M_TRACE(logger_, @"Enter");

        params = regParams;
        viewer = viewerController;
        progressController_ = progController;

        // Copy the Objective-C params to itk params
        itkParams = new ItkRegistrationParams(params);
        LOG4M_DEBUG(logger_, [NSString stringWithUTF8String:itkParams->Print().c_str()]);

        // Get the data from OsiriX
        imageImporter = [[ImageImporter alloc] initWithViewerController:viewer];
        Image3DType::Pointer image = [imageImporter getImage];
        //typename Image2DType::RegionType region = itkParams->fixedImageRegion;
        
        slicer = new ImageSlicer();
        slicer->SetImage(image);
        //slicer->SetRegion(region);

        opQueue = [[NSOperationQueue alloc] init];
        //[opQueue setMaxConcurrentOperationCount:1];

        [progController setManager:self];
    }
    return self;
}

- (void)dealloc
{
    delete itkParams;
    delete slicer;
    
    [opQueue release];
    [imageImporter release];
    [logger_ release];
    
    [super dealloc];
}

- (void)setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".RegistrationManager"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (Image3DType::Pointer)getImage
{
    return slicer->GetImage();
}

- (void)setupRegistration
{
    LOG4M_TRACE(logger_, @"Enter");

}

- (void) viewerWillClose:(NSNotification*)notification
{
    LOG4M_TRACE(logger_, @"sender = %@", [notification name]);

    // We are interested only in the closing of our viewer. Should another
    // one close we will ignore it
    if ([notification object] == viewer)
    {
        LOG4M_ERROR(logger_, @"The registered image viewer has closed. Stopping.");

        NSRunCriticalAlertPanel(@"DCEFit cannot continue.",
                                @"The registered image viewer is closing.",
                                @"Close", nil, nil);

        // Remove ourselves because the viewer is no longer valid and we must close.
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        progressController_.observer->StopRegistration();
        [self cancelRegistration];
    }
}

- (void)insertSliceIntoViewer:(Image2DType::Pointer)slice SliceIndex:(unsigned)sliceIndex
{
    // Do this to get back the full sized (uncropped) slice to reinsert into OsiriX
    slicer->SetSlice2D(slice, sliceIndex);
    Image2DType::Pointer fullSlice = slicer->GetSlice2D(sliceIndex);
    
    // calculate the offset of this slice in the data block in OsiriX
    // and the number of bytes to copy
    float* data = [viewer volumePtr];
    Image2DType::SizeType size = fullSlice->GetLargestPossibleRegion().GetSize();
    unsigned long numFloats = size[0] * size[1];
    unsigned long offset = numFloats * sliceIndex;
    data += offset;
    size_t numBytes = numFloats * sizeof(float);

    // copy the data into the OsiriX data block
    float* imageData = fullSlice->GetPixelContainer()->GetBufferPointer();
    memcpy(data, imageData, numBytes);

    [viewer performSelectorOnMainThread:@selector(needsDisplayUpdate) withObject:nil
                          waitUntilDone:YES];
    
}

//- (void)insertCroppedSliceIntoViewer:(Image2DType::Pointer)slice SliceIndex:(unsigned)sliceIndex
//{
//    // Do this to get back the full sized (uncropped) slice to reinsert into OsiriX
//    slicer->SetSlice2D(slice, sliceIndex);
//    Image2DType::Pointer fullSlice = slicer->GetSlice2D(sliceIndex);
//
//    // calculate the offset of this slice in the data block in OsiriX
//    // and the number of bytes to copy
//    float* data = [viewer volumePtr];
//    Image2DType::SizeType size = fullSlice->GetLargestPossibleRegion().GetSize();
//    unsigned long numFloats = size[0] * size[1];
//    unsigned long offset = numFloats * sliceIndex;
//    data += offset;
//    size_t numBytes = numFloats * sizeof(float);
//
//    // copy the data into the OsiriX data block
//    float* imageData = fullSlice->GetPixelContainer()->GetBufferPointer();
//    memcpy(data, imageData, numBytes);
//
//    [viewer performSelectorOnMainThread:@selector(needsDisplayUpdate) withObject:nil
//                          waitUntilDone:YES];
//    
//}

- (Image2DType::Pointer)getSliceFromImage:(unsigned)sliceNumber
{
    Image2DType::Pointer slice = slicer->GetSlice2D(sliceNumber);

    return slice;
}

//- (Image2DType::Pointer)getCroppedSliceFromImage:(unsigned)sliceNumber
//{
//    Image2DType::Pointer slice = slicer->GetCroppedSlice2D(sliceNumber);
//
//    return slice;
//}

- (void)doRegistration
{
    LOG4M_TRACE(logger_, @"Enter");

    // Catch the viewer closing event. We cannot continue without the viewer.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewerWillClose:)
                                                 name:@"CloseViewerNotification"
                                               object:viewer];
    [self setupRegistration];
    
    LOG4M_INFO(logger_, @"Starting registration.");
    
    unsigned numImages = itkParams->numImages;
    [progressController_ setProgressMinimum:(double)0 andMaximum:(double)numImages];
    
    unsigned rigidLevels = itkParams->rigidLevels;
    if (!itkParams->rigidRegEnabled)
        rigidLevels = 0;

    unsigned deformLevels = itkParams->deformLevels;
    if (!itkParams->deformRegEnabled)
        deformLevels = 0;

    LOG4M_INFO(logger_, @"Registration with %u rigid and %u deformable levels.",
             rigidLevels, deformLevels);

    // The operation.
    op = [[RegisterImageOp alloc] initWithManager:self ProgressController:progressController_];

    [op setCompletionBlock:^{
        [progressController_ registrationEnded];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        LOG4M_INFO(logger_, @"Ended registration");
    }];

    [opQueue addOperation:op];
}

- (void)cancelRegistration
{
	LOG4M_INFO(logger_, @"Registration Cancelled.");
    
    [op cancel];
//    NSLog(@"[op isFinished] = %d", [op isFinished]);
//    NSLog(@"[op isExecuting] = %d", [op isExecuting]);
}

@end
