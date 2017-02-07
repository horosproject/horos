//:
// \file
// This source file is configured from vxl/core/vnl/vnl_config.h.in to
// vxl-build/core/vnl/vnl_config.h by vxl's configuration process.
#ifndef vnl_config_h_
#define vnl_config_h_

//: Set to 0 to disable bounds checks in vnl_matrix<T>::operator() and vnl_vector<T>::operator().
// Note that operator[] never performs bounds checks.
// This is not intended to also control *size* checks when doing matrix-vector arithmetic.
#define VNL_CONFIG_CHECK_BOUNDS   1

//: Set to 1 to enable the deprecated methods vnl_vector<T>::set_[xyzt]().
#define VNL_CONFIG_LEGACY_METHODS 0

//: Set to 0 if you don't need thread safe code (and use a more efficient alloc).
#define VNL_CONFIG_THREAD_SAFE    1

//: Set to 0 if you don't have SSE2 support on your target platform
#define VNL_CONFIG_ENABLE_SSE2    0

//: Set to 0 if you don't want to use SSE2 instructions to implement rounding, floor, and ceil functions.
#define VNL_CONFIG_ENABLE_SSE2_ROUNDING 1

#endif
