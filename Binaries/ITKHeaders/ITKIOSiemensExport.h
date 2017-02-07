
#ifndef ITKIOSiemens_EXPORT_H
#define ITKIOSiemens_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOSiemens_EXPORT
#  define ITKIOSiemens_HIDDEN
#else
#  ifndef ITKIOSiemens_EXPORT
#    ifdef ITKIOSiemens_EXPORTS
        /* We are building this library */
#      define ITKIOSiemens_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOSiemens_EXPORT 
#    endif
#  endif

#  ifndef ITKIOSiemens_HIDDEN
#    define ITKIOSiemens_HIDDEN 
#  endif
#endif

#ifndef ITKIOSIEMENS_DEPRECATED
#  define ITKIOSIEMENS_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOSIEMENS_DEPRECATED_EXPORT
#  define ITKIOSIEMENS_DEPRECATED_EXPORT ITKIOSiemens_EXPORT ITKIOSIEMENS_DEPRECATED
#endif

#ifndef ITKIOSIEMENS_DEPRECATED_NO_EXPORT
#  define ITKIOSIEMENS_DEPRECATED_NO_EXPORT ITKIOSiemens_HIDDEN ITKIOSIEMENS_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOSIEMENS_NO_DEPRECATED
#endif

#endif
