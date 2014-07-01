/*
 * File:   RegisterOneImageBSpline2D.h
 * Author: tim
 *
 * Created on January 25, 2013, 9:13 AM
 */

#ifndef RegisterOneImageBSpline2D_H
#define	RegisterOneImageBSpline2D_H

#include "RegisterOneImage.h"

/**
 * Performs a multiresolution deformable registration of one image
 */
class RegisterOneImageBSpline2D : public RegisterOneImage<Image2D>
{
public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImageBSpline2D(ProgressWindowController* progressController,
                Image2D::Pointer fixedImage, const ItkRegistrationParams& params);

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @return The registered moving image.
     */
    virtual Image2D::Pointer registerImage(Image2D::Pointer movingImage, ResultCode& code);
};

#endif	/* REGISTERONEIMAGEMULTIRESDEFORMABLE2D_H */

