
#ifndef ITKIONRRD_EXPORT_H
#define ITKIONRRD_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIONRRD_EXPORT
#  define ITKIONRRD_HIDDEN
#else
#  ifndef ITKIONRRD_EXPORT
#    ifdef ITKIONRRD_EXPORTS
        /* We are building this library */
#      define ITKIONRRD_EXPORT 
#    else
        /* We are using this library */
#      define ITKIONRRD_EXPORT 
#    endif
#  endif

#  ifndef ITKIONRRD_HIDDEN
#    define ITKIONRRD_HIDDEN 
#  endif
#endif

#ifndef ITKIONRRD_DEPRECATED
#  define ITKIONRRD_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIONRRD_DEPRECATED_EXPORT
#  define ITKIONRRD_DEPRECATED_EXPORT ITKIONRRD_EXPORT ITKIONRRD_DEPRECATED
#endif

#ifndef ITKIONRRD_DEPRECATED_NO_EXPORT
#  define ITKIONRRD_DEPRECATED_NO_EXPORT ITKIONRRD_HIDDEN ITKIONRRD_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIONRRD_NO_DEPRECATED
#endif

#endif
