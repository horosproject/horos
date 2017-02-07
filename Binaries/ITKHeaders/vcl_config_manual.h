#ifndef vcl_config_manual_h_
#define vcl_config_manual_h_
//:
// \file
// This file either is or was generated from vcl_config_manual.h.in
// \brief manual options


//: VCL_USE_NATIVE_STL
// Whether to use the compiler's STL.
#define VCL_USE_NATIVE_STL 1

// Whether new additions to the C++0x standard are available
// and where they are found
#define VCL_INCLUDE_CXX_0X 0
#define VCL_MEMORY_HAS_SHARED_PTR 0
#define VCL_TR1_MEMORY_HAS_SHARED_PTR 1


//: VCL_USE_NATIVE_COMPLEX
// Whether to use the compiler's complex type.
#define VCL_USE_NATIVE_COMPLEX 1
// Used to be set from VCL_USE_NATIVE_STL, which worked fine.
// If you don't use the stl flag's setting you're on your own.
// #define VCL_USE_NATIVE_COMPLEX VCL_USE_NATIVE_STL


//: VCL_USE_IMPLICIT_TEMPLATES
// Whether to use implicit template instantiation.
#define VCL_USE_IMPLICIT_TEMPLATES 1

//: VCL_USE_ATOMIC_COUNT
// Whether to use the atomic_count implemenation in vcl.
#define VCL_USE_ATOMIC_COUNT 1

#endif // vcl_config_manual_h_
