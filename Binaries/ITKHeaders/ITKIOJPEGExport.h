
#ifndef ITKIOJPEG_EXPORT_H
#define ITKIOJPEG_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOJPEG_EXPORT
#  define ITKIOJPEG_HIDDEN
#else
#  ifndef ITKIOJPEG_EXPORT
#    ifdef ITKIOJPEG_EXPORTS
        /* We are building this library */
#      define ITKIOJPEG_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOJPEG_EXPORT 
#    endif
#  endif

#  ifndef ITKIOJPEG_HIDDEN
#    define ITKIOJPEG_HIDDEN 
#  endif
#endif

#ifndef ITKIOJPEG_DEPRECATED
#  define ITKIOJPEG_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOJPEG_DEPRECATED_EXPORT
#  define ITKIOJPEG_DEPRECATED_EXPORT ITKIOJPEG_EXPORT ITKIOJPEG_DEPRECATED
#endif

#ifndef ITKIOJPEG_DEPRECATED_NO_EXPORT
#  define ITKIOJPEG_DEPRECATED_NO_EXPORT ITKIOJPEG_HIDDEN ITKIOJPEG_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOJPEG_NO_DEPRECATED
#endif

#endif
