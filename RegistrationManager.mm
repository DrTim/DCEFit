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
#import "ProgressWindowController.h"
#import "SeriesInfo.h"

#import "OsiriXAPI/ViewerController.h"

@implementation RegistrationManager

@synthesize itkParams;
@synthesize progressController = progressController_;
@synthesize viewer;
@synthesize seriesInfo = seriesInfo_;

- (id)initWithViewer:(ViewerController *)viewerController
              Params:(RegistrationParams*)regParams
      ProgressWindow:(ProgressWindowController*)progController
          SeriesInfo:(SeriesInfo *)seriesInfo

{
    self = [super init];
    if (self)
    {
        [self setupLogger];
        LOG4M_TRACE(logger_, @"Enter");

        params = regParams;
        viewer = viewerController;
        progressController_ = progController;
        seriesInfo_ = seriesInfo;

        // Copy the Objective-C params to itk params
        itkParams = new ItkRegistrationParams(params);
        LOG4M_DEBUG(logger_, [NSString stringWithUTF8String:itkParams->Print().c_str()]);

        // Get the data from OsiriX
        slicer = new ImageSlicer();
        imageImporter = [[ImageImporter alloc] initWithViewerController:viewer];

        unsigned numImages = itkParams->numImages;
        for (unsigned idx = 0; idx < numImages; ++idx)
        {
            Image3D::Pointer image = [imageImporter getImageAtIndex:idx];
            slicer->AddImage(image);
        }

        opQueue = [[NSOperationQueue alloc] init];

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

- (Image3D::Pointer)imageAtIndex:(unsigned int)imageIdx
{
    return slicer->GetImage(imageIdx);
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

        [progressController_ stopRegistration];
        [self cancelRegistration];
    }
}

- (void)insertSliceIntoViewer:(Image2D::Pointer)slice ImageIndex:(unsigned int)imageIndex SliceIndex:(unsigned int)sliceIndex
{
    // Do this to get back the full sized (uncropped) slice to reinsert into OsiriX
    slicer->SetSlice2D(slice, imageIndex, sliceIndex);
    //Image2D::Pointer fullSlice = slicer->GetSlice2D(imageIndex, sliceIndex);

    // calculate the offset of this slice in the data block in OsiriX
    // and the number of bytes to copy
    float* data = [viewer volumePtr:imageIndex];
    Image2D::SizeType size = slice->GetLargestPossibleRegion().GetSize();
    unsigned long numFloats = size[0] * size[1];
    unsigned long offset = numFloats * sliceIndex;
    data += offset;
    size_t numBytes = numFloats * sizeof(float);

    // copy the data into the OsiriX data block
    float* imageData = slice->GetPixelContainer()->GetBufferPointer();
    memcpy(data, imageData, numBytes);

    [viewer performSelectorOnMainThread:@selector(needsDisplayUpdate) withObject:nil
                          waitUntilDone:YES];
    
}

- (void)insertImageIntoViewer:(Image3D::Pointer)image Index:(unsigned)imageIndex
{
    slicer-> SetImage(image, imageIndex);

    // Get the data block inside OsiriX
    float* data = [viewer volumePtr:imageIndex];

    // Calculate the number of bytes to copy
    Image3D::SizeType size = image->GetLargestPossibleRegion().GetSize();
    unsigned long numFloats = size[0] * size[1] * size[2];
    size_t numBytes = numFloats * sizeof(float);

    // copy the ITK image data into the OsiriX data block
    float* imageData = image->GetPixelContainer()->GetBufferPointer();
    memcpy(data, imageData, numBytes);

    [viewer performSelectorOnMainThread:@selector(needsDisplayUpdate) withObject:nil
                          waitUntilDone:YES];
    
}

- (Image2D::Pointer)slice:(unsigned int)sliceIndex FromImage:(unsigned int)imageIndex
{
    Image2D::Pointer slice = slicer->GetSlice2D(imageIndex, sliceIndex);

    return slice;
}

- (void)doRegistration
{
    LOG4M_TRACE(logger_, @"Enter");

    // Catch the viewer closing event. We cannot continue without the viewer.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewerWillClose:)
                                                 name:@"CloseViewerNotification"
                                               object:viewer];
    
    LOG4M_INFO(logger_, @"Starting registration.");
    
    unsigned numImages = itkParams->numImages;
    [progressController_ setProgressMinimum:(double)0 andMaximum:(double)numImages];

    if (itkParams->regSequence == RigidBSpline)
    {
        LOG4M_INFO(logger_, @"Registration with %u rigid and %u B-spline deformable levels.",
                   itkParams->rigidLevels, itkParams->bsplineLevels);
    }
    else if (itkParams->regSequence == Rigid)
    {
        LOG4M_INFO(logger_, @"Registration with %u rigid levels.",
                   itkParams->rigidLevels);
    }
    else if (itkParams->regSequence == Demons)
    {
        LOG4M_INFO(logger_, @"Registration with %u Demons deformable levels.",
                   itkParams->demonsLevels);
    }

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
}

@end
