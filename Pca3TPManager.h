//
//  Pca3TPManager.h
//  DCEFit
//
//  Created by Tim Allman on 2014-10-29.
//
//

#import <Foundation/Foundation.h>

#import "Pca3TpAnal.h"

@class ViewerController;
@class PcaParams;

@interface Pca3TPManager : NSObject
{
    ViewerController* viewerController;
    PcaParams* pcaParams;
    NSArray* roiInfoArray;
    Matrix pcaCoeffs;
}

- (id)initWithViewer:(ViewerController*)vc roiInfoArray:(NSArray*)roiInfo params:(PcaParams*)pcparams;

- (int)doAnalysis;

@end
