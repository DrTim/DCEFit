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
#import <princomp/Princomp.h>
#import <princomp/PrintArray.h>

#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMAttribute.h>

@implementation Pca3TpAnal

@synthesize pcaCoeffs = pcaCoeffs_;
@synthesize roiCoordinates = coordinates_;

- (id)initWithViewer:(ViewerController *)vc Roi:(ROI *)r andSliceIdx:(unsigned)sliceIdx
{
    self = [super init];
    if (self)
    {
        roi_ = r;
        viewer_ = vc;
        sliceIndex_ = sliceIdx;
        [self setupLogger];
    }
    return self;
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".Pca3TpAnal"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (void)dealloc
{
    [logger_ release];
    [super dealloc];
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
        LOG4M_ERROR(logger_, @"ROI named %@ does not define a region.", name);
        return retVal;
    }

    /*
     * getROIValue is declared in DCMPix.h.
     * 'data' is an array of float with 'size' elements allocated with malloc.
     * 'coords' is an array of float with 'size*2' elements allocated with
     * malloc. The fractional part is always .00000
     * The arrays should be freed by the user.
     */
    float* coords = 0;
    long size = 0;

    /*
     * DCMPix* curPix = [[roi curView] curDCM];
     *
     * We should be able to do this but Osirix neglects to store the DCMView properly
     * when it propagates ROIs. As a result we have to keep track of the current DCMPix
     * separately. Should this ever change the handling of the DCMPix arrays can be stripped
     * from the code.
     */
    float* data = [curPix getROIValue:&size :roi :&coords];

    Eigen::Map<Eigen::VectorXf, 0, Eigen::InnerStride<1> > coordMap(coords, size);
    std::cout << printArray(coordMap, "CoordData");

    Eigen::Map<Eigen::VectorXf, 0, Eigen::InnerStride<1> > dataMap(data, size / 2);
    std::cout << printArray(dataMap, "RoiData");


    for (int idx = 0; idx < (int)size; idx+=2)
    {
        PixelPos* pp = [[PixelPos alloc] initWithX:(int)coords[idx] Y:(int)coords[idx+1]];
        LOG4M_DEBUG(logger_, @"%@", pp);
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
    Matrix image(nRows, nCols);
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

/**
 * Make the data matrix from the data vectors. The elements of each vector are the 
 * corresponding points in the ROI through the time series.
 * @param sliceIdx Each potentially 3D image is composed of one or more slices. This
 * is the index of the slice in each image that will be used.
 * @return SUCCESS if successful, DISASTER otherwise.
 */
- (int)assembleDataMatrix:(unsigned)sliceIdx
{
    LOG4M_TRACE(logger_, @"Enter");

    unsigned numTimeImages = (unsigned)[viewer_ maxMovieIndex];

    if (numTimeImages == 1)  // we have a 2D viewer
    {
        LOG4M_ERROR(logger_, @"Viewer is a 2D viewer. A 4D viewer is required.");
        return DISASTER;
    }

    NSArray* firstImage = [viewer_ pixList:0];
    DCMPix* firstPix = [firstImage objectAtIndex:0];
    int sliceHeight = [firstPix pheight];
    int sliceWidth = [firstPix pwidth];
    LOG4M_DEBUG(logger_, @"Slice height = %u, width = %u", sliceHeight, sliceWidth);

    // Resize the data matrix to fit. It must have as many rows as there are images and
    // as many columns as there are points in the ROI.
    self.roiCoordinates = [self extractRoiCoordinates:roi_ from:firstPix];
    dataMatrix_.resize(numTimeImages, coordinates_.count);

    for (unsigned timeIdx = 0; timeIdx < numTimeImages; ++timeIdx)
    {
        // Array of slices.
        NSArray* pixList = [viewer_ pixList:timeIdx];

        // The slice we want.
        DCMPix* curPix = [pixList objectAtIndex:sliceIndex_];

        // Get a pointer to the slice data and map them as a matrix
        float* data = curPix.fImage;
        Eigen::Map<RowMatrix, 0, Eigen::OuterStride<> > dataMap(data, sliceHeight, sliceWidth,
                                                                Eigen::OuterStride<>(sliceWidth));

        int cols = coordinates_.count;
        for (int idx = 0; idx < cols; ++idx)
        {
            PixelPos* pp = [coordinates_ objectAtIndex:idx];
            float datum = dataMap(pp.x, pp.y);
            dataMatrix_.row(timeIdx)(idx) = datum;
        }
    }

    return SUCCESS;
}

- (void)calculateCoeffs
{
    [self assembleDataMatrix:sliceIndex_];
    
    // Generate the PC analysis
    Princomp<float> pc(dataMatrix_);

    pcaCoeffs_ = pc.getCoeffs();
}


@end
