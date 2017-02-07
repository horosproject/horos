
#ifndef ITKIOMRC_EXPORT_H
#define ITKIOMRC_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOMRC_EXPORT
#  define ITKIOMRC_HIDDEN
#else
#  ifndef ITKIOMRC_EXPORT
#    ifdef ITKIOMRC_EXPORTS
        /* We are building this library */
#      define ITKIOMRC_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOMRC_EXPORT 
#    endif
#  endif

#  ifndef ITKIOMRC_HIDDEN
#    define ITKIOMRC_HIDDEN 
#  endif
#endif

#ifndef ITKIOMRC_DEPRECATED
#  define ITKIOMRC_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOMRC_DEPRECATED_EXPORT
#  define ITKIOMRC_DEPRECATED_EXPORT ITKIOMRC_EXPORT ITKIOMRC_DEPRECATED
#endif

#ifndef ITKIOMRC_DEPRECATED_NO_EXPORT
#  define ITKIOMRC_DEPRECATED_NO_EXPORT ITKIOMRC_HIDDEN ITKIOMRC_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOMRC_NO_DEPRECATED
#endif

#endif
