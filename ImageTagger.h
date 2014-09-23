//
//  ImageTagger.h
//  DCEFit
//
//  Created by Tim Allman on 2013-10-21.
//
//

#ifndef __DCEFit__ImageTagger__
#define __DCEFit__ImageTagger__

#include "ItkTypedefs.h"

template <class TImage>
class ImageTagger
{
public:
    ImageTagger(unsigned gridSize, float pixelValue = 2048.0)
    : mGridSize(gridSize), mPixelValue(pixelValue)
    {
    }

    void operator()(TImage& image);

private:
    unsigned mGridSize;
    const float mPixelValue;
};

#endif /* defined(__DCEFit__ImageTagger__) */
