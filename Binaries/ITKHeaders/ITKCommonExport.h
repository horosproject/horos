
#ifndef ITKCommon_EXPORT_H
#define ITKCommon_EXPORT_H

#ifdef ITK_STATIC
#  define ITKCommon_EXPORT
#  define ITKCommon_HIDDEN
#else
#  ifndef ITKCommon_EXPORT
#    ifdef ITKCommon_EXPORTS
        /* We are building this library */
#      define ITKCommon_EXPORT 
#    else
        /* We are using this library */
#      define ITKCommon_EXPORT 
#    endif
#  endif

#  ifndef ITKCommon_HIDDEN
#    define ITKCommon_HIDDEN 
#  endif
#endif

#ifndef ITKCOMMON_DEPRECATED
#  define ITKCOMMON_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKCOMMON_DEPRECATED_EXPORT
#  define ITKCOMMON_DEPRECATED_EXPORT ITKCommon_EXPORT ITKCOMMON_DEPRECATED
#endif

#ifndef ITKCOMMON_DEPRECATED_NO_EXPORT
#  define ITKCOMMON_DEPRECATED_NO_EXPORT ITKCommon_HIDDEN ITKCOMMON_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKCOMMON_NO_DEPRECATED
#endif

#endif
