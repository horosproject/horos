
#ifndef ITKIONIFTI_EXPORT_H
#define ITKIONIFTI_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIONIFTI_EXPORT
#  define ITKIONIFTI_HIDDEN
#else
#  ifndef ITKIONIFTI_EXPORT
#    ifdef ITKIONIFTI_EXPORTS
        /* We are building this library */
#      define ITKIONIFTI_EXPORT 
#    else
        /* We are using this library */
#      define ITKIONIFTI_EXPORT 
#    endif
#  endif

#  ifndef ITKIONIFTI_HIDDEN
#    define ITKIONIFTI_HIDDEN 
#  endif
#endif

#ifndef ITKIONIFTI_DEPRECATED
#  define ITKIONIFTI_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIONIFTI_DEPRECATED_EXPORT
#  define ITKIONIFTI_DEPRECATED_EXPORT ITKIONIFTI_EXPORT ITKIONIFTI_DEPRECATED
#endif

#ifndef ITKIONIFTI_DEPRECATED_NO_EXPORT
#  define ITKIONIFTI_DEPRECATED_NO_EXPORT ITKIONIFTI_HIDDEN ITKIONIFTI_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIONIFTI_NO_DEPRECATED
#endif

#endif
