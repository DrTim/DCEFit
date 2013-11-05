/*
 * File:   RegisterOneImageMultiResDeformable2D.h
 * Author: tim
 *
 * Created on January 25, 2013, 9:13 AM
 */

#ifndef REGISTERONEIMAGEMULTIRESDEFORMABLE2D_H
#define	REGISTERONEIMAGEMULTIRESDEFORMABLE2D_H

#include "RegisterOneImage2D.h"

/**
 * Performs a multiresolution deformable registration of one image
 */
class RegisterOneImageMultiResDeformable2D : public RegisterOneImage2D
{
public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImageMultiResDeformable2D(ProgressWindowController* progressController,
                Image2DType::Pointer fixedImage, const ItkRegistrationParams& params);

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @return The registered moving image.
     */
    virtual Image2DType::Pointer registerImage(Image2DType::Pointer movingImage, ResultCode& code);
};

#endif	/* REGISTERONEIMAGEMULTIRESDEFORMABLE2D_H */

