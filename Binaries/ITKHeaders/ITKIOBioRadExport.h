
#ifndef ITKIOBioRad_EXPORT_H
#define ITKIOBioRad_EXPORT_H

#ifdef ITK_STATIC
#  define ITKIOBioRad_EXPORT
#  define ITKIOBioRad_HIDDEN
#else
#  ifndef ITKIOBioRad_EXPORT
#    ifdef ITKIOBioRad_EXPORTS
        /* We are building this library */
#      define ITKIOBioRad_EXPORT 
#    else
        /* We are using this library */
#      define ITKIOBioRad_EXPORT 
#    endif
#  endif

#  ifndef ITKIOBioRad_HIDDEN
#    define ITKIOBioRad_HIDDEN 
#  endif
#endif

#ifndef ITKIOBIORAD_DEPRECATED
#  define ITKIOBIORAD_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef ITKIOBIORAD_DEPRECATED_EXPORT
#  define ITKIOBIORAD_DEPRECATED_EXPORT ITKIOBioRad_EXPORT ITKIOBIORAD_DEPRECATED
#endif

#ifndef ITKIOBIORAD_DEPRECATED_NO_EXPORT
#  define ITKIOBIORAD_DEPRECATED_NO_EXPORT ITKIOBioRad_HIDDEN ITKIOBIORAD_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 0
#if DEFINE_NO_DEPRECATED
# define ITKIOBIORAD_NO_DEPRECATED
#endif

#endif
