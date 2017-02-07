
#ifndef ITKIOLSM_EXPORT_H
#define ITKIOLSM_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOLSM_EXPORT
#  define ITKIOLSM_HIDDEN
#else
#  ifndef ITKIOLSM_EXPORT
#    ifdef ITKIOLSM_EXPORTS
        /* We are building this library */
#      define ITKIOLSM_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOLSM_EXPORT 
#    endif
#  endif

#  ifndef ITKIOLSM_HIDDEN
#    define ITKIOLSM_HIDDEN 
#  endif
#endif

#ifndef ITKIOLSM_DEPRECATED
#  define ITKIOLSM_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOLSM_DEPRECATED_EXPORT
#  define ITKIOLSM_DEPRECATED_EXPORT ITKIOLSM_EXPORT ITKIOLSM_DEPRECATED
#endif

#ifndef ITKIOLSM_DEPRECATED_NO_EXPORT
#  define ITKIOLSM_DEPRECATED_NO_EXPORT ITKIOLSM_HIDDEN ITKIOLSM_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOLSM_NO_DEPRECATED
#endif

#endif
