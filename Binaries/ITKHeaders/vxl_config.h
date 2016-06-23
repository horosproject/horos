#ifndef vxl_config_h_
#define vxl_config_h_

/* this file either is or was generated from vxl_config.h.in */

/* -------------------- machine word characteristics */

/* machine byte order */
#if defined(__APPLE__)
/* All compilers that support Mac OS X define either __BIG_ENDIAN__ or
   __LITTLE_ENDIAN__ to match the endianness of the architecture being
   compiled for. This is not necessarily the same as the architecture
   of the machine doing the building. In order to support Universal
   Binaries on Mac OS X, we prefer those defines to decide the
   endianness.  Elsewhere use the platform check result.  */
# if defined(__BIG_ENDIAN__)
#  define VXL_BIG_ENDIAN 1
#  define VXL_LITTLE_ENDIAN 0
# elif defined(__LITTLE_ENDIAN__)
#  define VXL_BIG_ENDIAN 0
#  define VXL_LITTLE_ENDIAN 1
# else
#  error "Cannot determine machine byte order!"
# endif
#else
/* these are 0 or 1, never empty. */
# define VXL_LITTLE_ENDIAN 1
# define VXL_BIG_ENDIAN    0
#endif

/* we can't just use typedefs, because on systems where there are   */
/* no 64bit integers we have to #define vxl_int_64 to `void' in     */
/* order to catch illegitimate uses. However, typedefs are superior */
/* to #defines, especially for the two keyword types, so we use     */
/* typedefs for the valid cases.                                    */

#define VXL_HAS_BYTE 1
#define VXL_BYTE_STRING "char"
#if 1
  typedef   signed char  vxl_sbyte;
  typedef unsigned char  vxl_byte;
#else
# define vxl_sbyte  void
# define vxl_byte  void
#endif

#define VXL_HAS_INT_8 1
#define VXL_INT_8_STRING "char"
#if 1
  typedef          char  vxl_int_8;
  typedef   signed char  vxl_sint_8;
  typedef unsigned char  vxl_uint_8;
#else
# define vxl_int_8   void
# define vxl_sint_8  void
# define vxl_uint_8  void
#endif

#define VXL_HAS_INT_16 1
#define VXL_INT_16_STRING "short"
#if 1
  typedef          short vxl_int_16;
  typedef   signed short vxl_sint_16;
  typedef unsigned short vxl_uint_16;
#else
# define vxl_int_16  void
# define vxl_sint_16 void
# define vxl_uint_16 void
#endif

#define VXL_HAS_INT_32 1
#define VXL_INT_32_STRING "int"
#if 1
  typedef          int vxl_int_32;
  typedef   signed int vxl_sint_32;
  typedef unsigned int vxl_uint_32;
#else
# define vxl_int_32  void
# define vxl_sint_32 void
# define vxl_uint_32 void
#endif

/* Mac OS X Universal binary support requires a preprocessor test.  */
#if defined(__APPLE__)
# define VXL_HAS_INT_64 1
# if __LONG_MAX__ == 0x7fffffff
#  define VXL_INT_64_STRING "long long"
  typedef          long long vxl_int_64;
  typedef   signed long long vxl_sint_64;
  typedef unsigned long long vxl_uint_64;
#  define VXL_INT_64_IS_LONG 0
# elif __LONG_MAX__>>32 == 0x7fffffff
#  define VXL_INT_64_STRING "long"
  typedef          long vxl_int_64;
  typedef   signed long vxl_sint_64;
  typedef unsigned long vxl_uint_64;
#  define VXL_INT_64_IS_LONG 1
# else
#  error "Cannot determine sizeof(long) from __LONG_MAX__."
# endif
#else
# define VXL_HAS_INT_64 1
# define VXL_INT_64_STRING "long"
# if 1
  typedef          long vxl_int_64;
  typedef   signed long vxl_sint_64;
  typedef unsigned long vxl_uint_64;
# else
#  define vxl_int_64  void
#  define vxl_sint_64 void
#  define vxl_uint_64 void
# endif
# define VXL_INT_64_IS_LONG 1
#endif

#define VXL_HAS_IEEE_32 1
#define VXL_IEEE_32_STRING "float"
#if 1
  typedef float vxl_ieee_32;
#else
# define vxl_ieee_32 void
#endif

#define VXL_HAS_IEEE_64 1
#define VXL_IEEE_64_STRING "double"
#if 1
  typedef double vxl_ieee_64;
#else
# define vxl_ieee_64 void
#endif

#define VXL_HAS_IEEE_96 0
#define VXL_IEEE_96_STRING "void"
#if 0
  typedef void vxl_ieee_96;
#else
# define vxl_ieee_96 void
#endif

#define VXL_HAS_IEEE_128 1
#define VXL_IEEE_128_STRING "long double"
#if 1
  typedef long double vxl_ieee_128;
#else
# define vxl_ieee_128 void
#endif

#define VXL_ADDRESS_BITS  64

/* -------------------- operating system services */

#define VXL_HAS_PTHREAD_H         1
#define VXL_HAS_SEMAPHORE_H       1
#define VXL_HAS_DBGHELP_H         0

/* -------------------- library quirks */

/* these should be 1 if the symbol in question is declared */
/* in the relevant header file and 0 otherwise. */

#define VXL_UNISTD_HAS_USECONDS_T 1
#define VXL_UNISTD_HAS_INTPTR_T   1
#define VXL_UNISTD_HAS_UALARM     1
#define VXL_UNISTD_HAS_USLEEP     1
#define VXL_UNISTD_HAS_LCHOWN     1
#define VXL_UNISTD_HAS_PREAD      1
#define VXL_UNISTD_HAS_PWRITE     1
#define VXL_UNISTD_HAS_TELL       0
#define VXL_UNISTD_HAS_GETPID     1

/* true if <stdlib.h> declares qsort() */
#define VXL_STDLIB_HAS_QSORT      1

/* true if <stdlib.h> declares lrand48() */
#define VXL_STDLIB_HAS_LRAND48    1

/* true if <stdlib.h> declares drand48() */
#define VXL_STDLIB_HAS_DRAND48    1

/* true if <stdlib.h> declares srand48() */
#define VXL_STDLIB_HAS_SRAND48    1

/* true if <ieeefp.h> declares finite() */
#define VXL_IEEEFP_HAS_FINITE     0

/* true if <math.h> declares finitef() */
#define VXL_C_MATH_HAS_FINITEF     0

/* true if <math.h> declares finite() */
#define VXL_C_MATH_HAS_FINITE     1

/* true if <math.h> declares finitel() */
#define VXL_C_MATH_HAS_FINITEL     0

/* true if <math.h> declares sqrtf() for the C compiler */
#define VXL_C_MATH_HAS_SQRTF      1

/* true if <math.h> declares lround() */
#define VXL_C_MATH_HAS_LROUND      1

/* true if usleep() returns void */
#define VXL_UNISTD_USLEEP_IS_VOID 0

/* true if gettime() takes two arguments */
#define VXL_TWO_ARG_GETTIME       0

/* true if <ieeefp.h> is available */
#define VXL_HAS_IEEEFP_H          0

#ifdef __APPLE__
/* true if in OsX <math.h> declares __isnand() */
#define VXL_APPLE_HAS_ISNAND 0
#endif 

/* true if <emmintrin.h> is available */
#define VXL_HAS_EMMINTRIN_H   1

/* true if _mm_malloc and _mm_free are defined */
#define VXL_HAS_MM_MALLOC 1

/* true if _aligned_malloc and _aligned_free are defined */
#define VXL_HAS_ALIGNED_MALLOC 0

/* true if __mingw_aligned_malloc and __mingw_aligned_free are defined */
#define VXL_HAS_MINGW_ALIGNED_MALLOC 0

/* true if memalign is defined */
#define VXL_HAS_POSIX_MEMALIGN 0

/* true if wchar_t overloading functions are supported on Windows */
#define VXL_USE_WIN_WCHAR_T 

#endif /* vxl_config_h_ */
