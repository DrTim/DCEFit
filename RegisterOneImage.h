//
//  RegisterOneImage.h
//  DCEFit
//
//  Created by Tim Allman on 2013-08-03.
//
//

#ifndef __DCEFit__RegisterOneImage__
#define __DCEFit__RegisterOneImage__

#include "ItkTypedefs.h"
#include "ProjectDefs.h"
#include "ItkRegistrationParams.h"

#import "ProgressWindowController.h"

#include <log4cplus/logger.h>

/**
 * Abstract base class for performing a multiresolution registration of one image
 */
template <class TImage>
class RegisterOneImage
{
  public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImage(ProgressWindowController* progressController,
                       typename TImage::Pointer fixedImage,
                       const ItkRegistrationParams& itkParams)
    : progController_(progressController), fixedImage_(fixedImage), itkParams_(itkParams)
    {

    }

    virtual ~RegisterOneImage()
    {
        [progController_ setObserver:0];
    }

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @param code The result of the registration.
     * @return The registered moving image.
     */
    virtual typename TImage::Pointer registerImage(typename TImage::Pointer movingImage,
                                               ResultCode& code) = 0;

protected:
    log4cplus::Logger logger_;
    ProgressWindowController* progController_;
    typename TImage::Pointer fixedImage_;
    ItkRegistrationParams itkParams_;
};

#endif /* defined(__DCEFit__RegisterOneImage__) */
