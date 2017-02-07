
#ifndef ITKIOStimulate_EXPORT_H
#define ITKIOStimulate_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOStimulate_EXPORT
#  define ITKIOStimulate_HIDDEN
#else
#  ifndef ITKIOStimulate_EXPORT
#    ifdef ITKIOStimulate_EXPORTS
        /* We are building this library */
#      define ITKIOStimulate_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOStimulate_EXPORT 
#    endif
#  endif

#  ifndef ITKIOStimulate_HIDDEN
#    define ITKIOStimulate_HIDDEN 
#  endif
#endif

#ifndef ITKIOSTIMULATE_DEPRECATED
#  define ITKIOSTIMULATE_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOSTIMULATE_DEPRECATED_EXPORT
#  define ITKIOSTIMULATE_DEPRECATED_EXPORT ITKIOStimulate_EXPORT ITKIOSTIMULATE_DEPRECATED
#endif

#ifndef ITKIOSTIMULATE_DEPRECATED_NO_EXPORT
#  define ITKIOSTIMULATE_DEPRECATED_NO_EXPORT ITKIOStimulate_HIDDEN ITKIOSTIMULATE_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOSTIMULATE_NO_DEPRECATED
#endif

#endif
