
#ifndef ITKIOTIFF_EXPORT_H
#define ITKIOTIFF_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOTIFF_EXPORT
#  define ITKIOTIFF_HIDDEN
#else
#  ifndef ITKIOTIFF_EXPORT
#    ifdef ITKIOTIFF_EXPORTS
        /* We are building this library */
#      define ITKIOTIFF_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOTIFF_EXPORT 
#    endif
#  endif

#  ifndef ITKIOTIFF_HIDDEN
#    define ITKIOTIFF_HIDDEN 
#  endif
#endif

#ifndef ITKIOTIFF_DEPRECATED
#  define ITKIOTIFF_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOTIFF_DEPRECATED_EXPORT
#  define ITKIOTIFF_DEPRECATED_EXPORT ITKIOTIFF_EXPORT ITKIOTIFF_DEPRECATED
#endif

#ifndef ITKIOTIFF_DEPRECATED_NO_EXPORT
#  define ITKIOTIFF_DEPRECATED_NO_EXPORT ITKIOTIFF_HIDDEN ITKIOTIFF_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOTIFF_NO_DEPRECATED
#endif

#endif
