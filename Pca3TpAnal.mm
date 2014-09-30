//
//  Pca3TpAnal.mm
//  DCEFit
//
//  Created by Tim Allman on 2014-09-22.
//
//

#import <Log4m/Log4m.h>

#import "Pca3TpAnal.h"
#import "PixelPos.h"

#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMAttribute.h>

@implementation Pca3TpAnal

- (id)initWithViewer:(ViewerController *)viewer Roi:(ROI *)roi andSliceIdx:(unsigned)sliceIdx
{
    self = [super init];
    if (self)
    {
        mRoi = roi;
        mViewer = viewer;
        mSliceIndex = sliceIdx;
        [self setupLogger];
    }
    return self;
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".Pca3TpAnal"];
    mLogger = [[Logger newInstance:loggerName] retain];
}

/**
 * Get the coordinates of all of the pixels inside the ROI in one slice.
 * @param roi The ROI. Must be of a type that defines a region.
 * @param curPix The DCMPix instance containing the slice.
 * @return An array the coordinates of all of the pixels contained in the ROI.
 */
- (NSArray*)extractRoiCoordinates:(ROI*)roi from:(DCMPix*)curPix
{

    // return value
    NSMutableArray* retVal = [NSMutableArray array];
    NSString* name = [roi name];

    // These ROI types do not define regions
    if ((roi.type == tText) || (roi.type == tMesure) ||
        (roi.type == tArrow) || (roi.type == t2DPoint))
    {
        LOG4M_ERROR(mLogger, @"ROI named %@ does not define a region.", name);
        return retVal;
    }

    /*
     * getROIValue is declared in DCMPix.h.
     * 'data' is an array of float with 'size' elements allocated with malloc.
     * 'coords' is an array of float with 'size*2' elements allocated with
     * malloc. The fractional part is always .00000
     * The arrays should be freed by the user.
     */
    float* coords;
    long size;

    /*
     * DCMPix* curPix = [[roi curView] curDCM];
     * We should be able to do this but Osirix neglects to store the DCMView properly
     * when it propagates ROIs. As a result we have to keep track of the current DCMPix
     * separately. Should this ever change the handling of the DCMPix arrays can be stripped
     * from the code.
     */
    float* data = [curPix getROIValue:&size :roi :&coords];

    for (int idx = 0; idx < (int)size; idx+=2)
    {
        PixelPos* pp = [[PixelPos alloc] initWithX:(int)coords[idx] Y:(int)coords[idx+1]];
        [retVal addObject:pp];
        [pp release];
    }

    free(coords);
    free(data);
    
    return retVal;
}

/**
 * Get the coordinates of all of the pixels inside the ROI in one slice.
 * @param coords The coordinates of the pixels in the ROI.
 * @param curPix The DCMPix instance containing the slice.
 * @return An array the values as NSNumbers of all of the pixels contained in the ROI.
 */
- (NSArray*)extractRoiValues:(NSArray*)coords from:(DCMPix*)curPix
{
    // get the size of the image
    int nRows = [curPix pheight];
    int nCols = [curPix pwidth];

    // copy the image data to a matrix that we can index easily
    float* data = curPix.fImage;
    MatrixType image(nRows, nCols);
    for (int row = 0; row < nRows; ++row)
        for (int col = 0; col < nCols; ++col)
            image(row, col) = *(data + row * nCols + col);

    // Create a vector of pixel values
    int len = coords.count;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:len];
    for (int idx = 0; idx < len; ++idx)
    {
        PixelPos* pos = [coords objectAtIndex:idx];
        NSNumber* val = [NSNumber numberWithFloat:image(pos.x, pos.y)];
        [array addObject:val];
    }

    return array;
}

- (int)assembleDataMatrix
{
    LOG4M_TRACE(mLogger, @"Enter");

    unsigned numTimeImages = (unsigned)[mViewer maxMovieIndex];
    unsigned slicesPerImage = [[mViewer pixList] count];

    if (numTimeImages == 1)  // we have a 2D viewer
    {
        LOG4M_ERROR(mLogger, @"Viewer is a 2D viewer. A 4D viewer is required.");
        return DISASTER;
    }
    else // we have a 4D viewer
    {
        LOG4M_DEBUG(mLogger, @"******** 4D viewer with %u images and %u slices per image."
                    "***************", numTimeImages, slicesPerImage);
    }

    NSArray* firstImage = [mViewer pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];
    int sliceHeight = [firstPix pheight];
    int sliceWidth = [firstPix pwidth];
    int sliceSize = sliceHeight * sliceWidth;
    LOG4M_DEBUG(mLogger, @"******** Slice height = %u, width = %u, size = %u pixels."
                " ***************", sliceHeight, sliceWidth, sliceSize);

    // Resize the data matrix to fit.
    dataMatrix.resize(numTimeImages, mCoordinates.count);

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        LOG4M_DEBUG(mLogger, @"******** timeIdx = %u ***************", timeIdx);

        // Array of slices.
        NSArray* pixList = [mViewer pixList:timeIdx];

        // The slice we want.
        DCMPix* curPix = [pixList objectAtIndex:mSliceIndex];

        // Get a pointer to the data and map them as a matrix
        float* data = curPix.fImage;
        Eigen::Map<RowMatrixType, 0, Eigen::OuterStride<> > dataMap(data, sliceHeight, sliceWidth, Eigen::OuterStride<>(sliceWidth));

        for (int idx = 0; idx < mCoordinates.count; ++idx)
        {
            PixelPos* pp = [mCoordinates objectAtIndex:idx];
            float datum = dataMap(pp.x, pp.y);
            dataMatrix.col(timeIdx)(idx) = datum;
        }
    }

    return SUCCESS;
}



@end
