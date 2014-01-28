/*
 * File:   RegisterOneImageDeformable3D.h
 * Author: tim
 *
 * Created on January 25, 2013, 9:13 AM
 */

#ifndef REGISTERONEIMAGEDEFORMABLE3D_H
#define	REGISTERONEIMAGEDEFORMABLE3D_H

#include "RegisterOneImage.h"

/**
 * Performs a multiresolution deformable registration of one image
 */
class RegisterOneImageDeformable3D : public RegisterOneImage<Image3D>
{
public:
    /**
     * Constructor.
     * @param progressController ProgressController for updates and registration mamagement.
     * @param fixedImage The fixed image.
     * @param params The registration parameters.
     */
    RegisterOneImageDeformable3D(ProgressWindowController* progressController,
                Image3D::Pointer fixedImage, const ItkRegistrationParams& params);

    /**
     * Do the registration.
     * @param movingImage The moving image to be registered.
     * @return The registered moving image.
     */
    virtual Image3D::Pointer registerImage(Image3D::Pointer movingImage, ResultCode& code);

    /**
     * Set up the registration region. The region will be a 3D region defined by the 2D region
     * in the plane of the slices and the full thickness of the image.
     *
     * @param region2D The 2D region in the plane of the slices
     * @param numSlices The thickness of the image in slices.
     * @return The 3D region.
     */
    Image3D::RegionType Create3DRegion(const Image2D::RegionType& region2D, unsigned numSlices);

};

#endif	/* REGISTERONEIMAGEMULTIRESDEFORMABLE3D_H */

