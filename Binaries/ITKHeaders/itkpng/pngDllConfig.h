#ifndef _pngDllConfig_h
#define _pngDllConfig_h

/* #undef PNG_STATIC */
/* #undef PNG_NO_MODULEDEF */

#if defined(_WIN32) && !defined(PNG_STATIC) && !defined(PNG_BUILD_DLL)
#  define PNG_USE_DLL
#endif

#endif
