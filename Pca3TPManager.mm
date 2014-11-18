//
//  Pca3TPManager.m
//  DCEFit
//
//  Created by Tim Allman on 2014-10-29.
//
//
//#include <Eigen/Dense>

#import <OsiriXAPI/ROI.h>

#import "Pca3TPManager.h"
#import "Pca3TpAnal.h"
#import "PcaParams.h"
#import "ROIInfo.h"

@implementation Pca3TPManager

/*

 */
- (id)initWithViewer:(ViewerController *)vc roiInfoArray:(NSArray*)roiInfo params:(PcaParams *)pcparams
{
    self = [super init];
    if (self)
    {
        viewerController = vc;
        pcaParams = pcparams;
        roiInfoArray = roiInfo;
    }
    return self;
}

- (int)doAnalysis
{
    ROIInfo* ri = [roiInfoArray objectAtIndex:pcaParams.roiIndex];
    ROI* roi = ri.roi;
    unsigned sliceIdx = pcaParams.sliceIndex;

    Pca3TpAnal* pcaObj = [[Pca3TpAnal alloc] initWithViewer:viewerController Roi:roi andSliceIdx:sliceIdx];
    
    [pcaObj calculateCoeffs];

    pcaCoeffs = pcaObj.pcaCoeffs;
    [pcaObj release];
    return SUCCESS;
}

@end
