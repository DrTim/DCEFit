//
//  IndexConverter.m
//  DCEFit
//
//  Created by Tim Allman on 2014-10-28.
//
//

#import "IndexConverter.h"

#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/DCMView.h>

@implementation IndexConverter

+ (unsigned)sliceNumberToIndex:(unsigned)number viewerController:(ViewerController*)viewer
{
    unsigned slicesPerImage = [[viewer pixList] count];
    BOOL flippedData = [[viewer imageView] flippedData];

    if (flippedData)
        return slicesPerImage - number;
    else
        return number - 1;
}

+ (unsigned)indexToSliceNumber:(unsigned int)index viewerController:(ViewerController*)viewer
{
    unsigned slicesPerImage = [[viewer pixList] count];
    BOOL flippedData = [[viewer imageView] flippedData];

    if (flippedData)
        return slicesPerImage - index;
    else
        return index + 1;
}

@end
