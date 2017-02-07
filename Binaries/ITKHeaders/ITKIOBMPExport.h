
#ifndef ITKIOBMP_EXPORT_H
#define ITKIOBMP_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOBMP_EXPORT
#  define ITKIOBMP_HIDDEN
#else
#  ifndef ITKIOBMP_EXPORT
#    ifdef ITKIOBMP_EXPORTS
        /* We are building this library */
#      define ITKIOBMP_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOBMP_EXPORT 
#    endif
#  endif

#  ifndef ITKIOBMP_HIDDEN
#    define ITKIOBMP_HIDDEN 
#  endif
#endif

#ifndef ITKIOBMP_DEPRECATED
#  define ITKIOBMP_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOBMP_DEPRECATED_EXPORT
#  define ITKIOBMP_DEPRECATED_EXPORT ITKIOBMP_EXPORT ITKIOBMP_DEPRECATED
#endif

#ifndef ITKIOBMP_DEPRECATED_NO_EXPORT
#  define ITKIOBMP_DEPRECATED_NO_EXPORT ITKIOBMP_HIDDEN ITKIOBMP_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOBMP_NO_DEPRECATED
#endif

#endif
