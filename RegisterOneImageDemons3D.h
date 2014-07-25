/*
 * File:   RegisterOneImageDemons3D.h
 * Author: tim
 *
 * Created on January 25, 2013, 9:13 AM
 */

#ifndef RegisterOneImageDemons3D_H
#define	RegisterOneImageDemons3D_H

#include "RegisterOneImage.h"

/**
 * Performs a multiresolution deformable registration of one image
 */
class RegisterOneImageDemons3D : public RegisterOneImage<Image3D>
{
public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImageDemons3D(ProgressWindowController* progressController,
                Image3D::Pointer fixedImage, const ItkRegistrationParams& params);

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @return The registered moving image.
     */
    virtual Image3D::Pointer registerImage(Image3D::Pointer movingImage, ResultCode& code);
};

#endif	/* RegisterOneImageDemons3D_H */

