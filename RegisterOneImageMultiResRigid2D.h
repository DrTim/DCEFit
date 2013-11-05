/*
 * File:   RegisterOneImageMultiResRigid2D.h
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#ifndef REGISTERONEIMAGEMULTIRESRIGID2D_H
#define	REGISTERONEIMAGEMULTIRESRIGID2D_H

#include "RegisterOneImage2D.h"

/**
 * Performs a multiresolution rigid registration of one image
 */
class RegisterOneImageMultiResRigid2D : public RegisterOneImage2D
{
public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImageMultiResRigid2D(ProgressWindowController* progressController,
                Image2DType::Pointer fixedImage, const ItkRegistrationParams& itkParams);

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @return The registered moving image.
     */
    virtual Image2DType::Pointer registerImage(Image2DType::Pointer movingImage, ResultCode& code);
};

#endif	/* REGISTERONEIMAGEMULTIRESRIGID_H */

