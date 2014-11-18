//
//  ROIInfo.h
//  DCEFit
//
//  Created by Tim Allman on 2014-10-03.
//
//

#import <Foundation/Foundation.h>

@class ROI;
@class DCMPix;
@class Logger;

@interface ROIInfo : NSObject
{
    Logger* logger_;
    NSUInteger imageIdx_;
    NSUInteger sliceNum_;
    ROI* roi_;
    DCMPix* pix_;
    NSArray* coordinates_;
}

@property (readonly) NSUInteger imageIdx;
@property (readonly) NSUInteger sliceNum;
@property (readonly) ROI* roi;
@property (readonly) NSArray* pixelCoordinates;

- (id)initWithSlice:(DCMPix*)pix roi:(ROI*)roi imageIndex:(NSUInteger)imageIdx sliceNumber:(NSUInteger)sliceNum;

- (void)dealloc;

- (NSString*)displayString;

- (NSString*)description;

@end
