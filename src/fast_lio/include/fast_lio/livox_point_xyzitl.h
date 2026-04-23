
#ifndef FAST_LIO_LIVOX_POINT_XYZITL_H

#define FAST_LIO_LIVOX_POINT_XYZITL_H



#include <pcl/point_types.h>



namespace fast_lio {



struct LivoxPointXyzitl

{

    PCL_ADD_POINT4D;

    float intensity;

    double timestamp;

    uint16_t line;

    EIGEN_MAKE_ALIGNED_OPERATOR_NEW

} EIGEN_ALIGN16;



} // namespace fast_lio



POINT_CLOUD_REGISTER_POINT_STRUCT(fast_lio::LivoxPointXyzitl,

    (float, x, x)

    (float, y, y)

    (float, z, z)

    (float, intensity, intensity)

    (double, timestamp, timestamp)

    (uint16_t, line, line)

)



#endif // FAST_LIO_LIVOX_POINT_XYZITL_H

