
#ifndef ITKIOImageBase_EXPORT_H
#define ITKIOImageBase_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOImageBase_EXPORT
#  define ITKIOImageBase_HIDDEN
#else
#  ifndef ITKIOImageBase_EXPORT
#    ifdef ITKIOImageBase_EXPORTS
        /* We are building this library */
#      define ITKIOImageBase_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOImageBase_EXPORT 
#    endif
#  endif

#  ifndef ITKIOImageBase_HIDDEN
#    define ITKIOImageBase_HIDDEN 
#  endif
#endif

#ifndef ITKIOIMAGEBASE_DEPRECATED
#  define ITKIOIMAGEBASE_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOIMAGEBASE_DEPRECATED_EXPORT
#  define ITKIOIMAGEBASE_DEPRECATED_EXPORT ITKIOImageBase_EXPORT ITKIOIMAGEBASE_DEPRECATED
#endif

#ifndef ITKIOIMAGEBASE_DEPRECATED_NO_EXPORT
#  define ITKIOIMAGEBASE_DEPRECATED_NO_EXPORT ITKIOImageBase_HIDDEN ITKIOIMAGEBASE_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOIMAGEBASE_NO_DEPRECATED
#endif

#endif
