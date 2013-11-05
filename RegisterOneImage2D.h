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

#include <log4cplus/logger.h>

#import "ProgressWindowController.h"

/**
 * Abstract base class for performing a multiresolution registration of one image
 */
class RegisterOneImage2D
{
public:
    /**
     * Values to use to return the results of the registration.
     */
    enum ResultCode
    {
        SUCCESS = 0,   /// All went well.
        FAILURE = 1,   /// Registration was suboptimal but we can continue.
        DISASTER = 2   /// Complete failure resulting in an exception being thrown by ITK.
    };

    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImage2D(ProgressWindowController* progressController,
                       Image2DType::Pointer fImage,
                       const ItkRegistrationParams& itkParms)
    : progController_(progressController), fixedImage_(fImage), itkParams_(itkParms)
    {

    }

    virtual ~RegisterOneImage2D()
    {
        [progController_ setObserver:0];
    }

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @param code The result of the registration.
     * @return The registered moving image.
     */
    virtual Image2DType::Pointer registerImage(Image2DType::Pointer movingImage,
                                               ResultCode& code) = 0;

protected:
    log4cplus::Logger logger_;
    ProgressWindowController* progController_;
    Image2DType::Pointer fixedImage_;
    ItkRegistrationParams itkParams_;
};

#endif /* defined(__DCEFit__RegisterOneImage__) */
