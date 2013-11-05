//
//  ImageImporter.mm
//  DCEFit
//
//  Created by Tim Allman on 2013-05-02.
//
//

#import "ImageImporter.h"

#include "ItkTypedefs.h"

#import "OsirixAPI/ViewerController.h"
#import "OsirixAPI/DCMPix.h"
#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMAttributeTag.h"

@implementation ImageImporter

- (ImageImporter*)initWithViewerController:(ViewerController*)viewerController
{
    self = [super init];
    if (self)
    {
        viewer = viewerController;
        [self setupLogger];
        LOG4M_TRACE(logger_, @"ImageImporter.initWithViewerController");
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
                            stringByAppendingString:@".ImageImporter"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (Image3DType::Pointer)getImage
{
    LOG4M_TRACE(logger_, @"Enter");
    ImportImageFilterType::Pointer importFilter = ImportImageFilterType::New();
    ImportImageFilterType::SizeType size;
    ImportImageFilterType::IndexType start;
    ImportImageFilterType::SpacingType spacing;
    ImportImageFilterType::RegionType region;
    ImportImageFilterType::OriginType origin;
    ImportImageFilterType::DirectionType direction;

    //importFilter->DebugOn();

    //
    // Extract the needed information from OsiriX
    //
    // pointer to the first slice (i.e. start of buffer)
    NSMutableArray* pixList = [viewer pixList];
    DCMPix* firstPix = [pixList objectAtIndex:0];

    // start of the image in pixels
    start[0] = 0;
	start[1] = 0;
    start[2] = 0;
    LOG4M_DEBUG(logger_, @"  Start = %d, %d, %d", start[0], start[1], start[2]);

    // size of the image in pixels
    size[0] = [firstPix pwidth];
	size[1] = [firstPix pheight];
    size[2] = [[viewer pixList] count];
    LOG4M_DEBUG(logger_, @"  Size = %d, %d, %d", size[0], size[1], size[2]);

    // origin in mm
    origin[0] = [firstPix originX];
	origin[1] = [firstPix originY];
	origin[2] = [firstPix originZ];
    LOG4M_DEBUG(logger_, @"  Origin = %f, %f, %f", origin[0], origin[1], origin[2]);

    // pixel spacing in mm
	spacing[0] = [firstPix pixelSpacingX];
	spacing[1] = [firstPix pixelSpacingY];
	spacing[2] = [firstPix sliceInterval];

    // The slice interval may be 0 if there is only one slice per DCMPix object but
    // ITK does not allow 0 spacings so ...
    if (fabs(spacing[2]) < 1e-6)
        spacing[2] = 1.0;
    LOG4M_DEBUG(logger_, @"  Spacing = %f, %f, %f", spacing[0], spacing[1], spacing[2]);


//    // file containing first slice
//    NSString* filePath = [firstPix sourceFile];
//
//    // The Dicom Object
//    DCMObject* dcmObject = [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];
//
//    // take direction from DICOM Image Orientation (Patient) (0020,0037)
//    NSArray *imageOrientation = [dcmObject attributeArrayWithName: @"ImageOrientationPatient"];
//    float orients[9];
//    for (unsigned int i = 0; i < 6; i++)
//        orients[i] = [[imageOrientation objectAtIndex:i] floatValue];
//
//    // calculate the normal vector (cross product of the other two)
//    orients[6] = orients[1]*orients[5] - orients[2]*orients[4];
//    orients[7] = orients[2]*orients[3] - orients[0]*orients[5];
//    orients[8] = orients[0]*orients[4] - orients[1]*orients[3];

    // get the DICOM ImageOrientationPatient
//    float orients[9];
//    [firstPix orientation:orients];
//    
//    for (int i = 0, k = 0; i < 3; ++i)
//        for (int j = 0; j < 3; ++j)
//            direction(i, j) =  orients[k++];
//
//    // TODO - just construct transpose in the first place.
//    direction = direction.GetTranspose();

    // For our purposes the DICOM orientation vectors get in the way.
    // We will just set this up so that the image appears to be axial.
    // This means that the upper left corner of the screen is the origin
    // with X increasing horizontally, Y increasing down the screen and
    // Z going into the screen.
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j)
        {
            if (i == j)
                direction(i, j) = 1.0;
            else
                direction(i, j) = 0.0;
        }

    LOG4M_DEBUG(logger_, @"itk::Image::direction = \n     [%3.4f, %3.4f, %3.4f]\n     [%3.4f, %3.4f, %3.4f]\n     [%3.4f, %3.4f, %3.4f]",
                direction(0, 0), direction(0, 1), direction(0, 2),
                direction(1, 0), direction(1, 1), direction(1, 2),
                direction(2, 0), direction(2, 1), direction(2, 2));

    // the size of the buffer
    long bufferSize = size[0] * size[1] * size[2];

    // Region to import -- the whole image
    region.SetIndex(start);
	region.SetSize(size);

    // pointer to the data
    float* data = [viewer volumePtr];
	importFilter->SetRegion(region);
	importFilter->SetOrigin(origin);
	importFilter->SetSpacing(spacing);
    importFilter->SetDirection(direction);

    // set this so that the filter does not own the data, OsiriX does
	importFilter->SetImportPointer(data, bufferSize, false);

    Image3DType::Pointer image = importFilter->GetOutput();
	image->Update();

    return image;
}

@end
