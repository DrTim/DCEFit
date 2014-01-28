/*
 * File:   RegisterOneImageRigid2D.h
 * Author: tim
 *
 * Created on January 28, 2013, 12:47 PM
 */

#ifndef REGISTERONEIMAGERIGID2D_H
#define	REGISTERONEIMAGERIGID2D_H

#include "RegisterOneImage.h"

/**
 * Performs a multiresolution rigid registration of one image
 */
class RegisterOneImageRigid2D : public RegisterOneImage<Image2D>
{
public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImageRigid2D(ProgressWindowController* progressController,
                Image2D::Pointer fixedImage, const ItkRegistrationParams& itkParams);

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @return The registered moving image.
     */
    virtual Image2D::Pointer registerImage(Image2D::Pointer movingImage, ResultCode& code);
};

#endif	/* REGISTERONEIMAGEMULTIRESRIGID_H */

