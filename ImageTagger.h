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
    ImageTagger(unsigned gridSize)
    {
        gridSize_ = gridSize;
    }

    void operator()(TImage& image);

private:
    unsigned gridSize_;
};

#endif /* defined(__DCEFit__ImageTagger__) */
