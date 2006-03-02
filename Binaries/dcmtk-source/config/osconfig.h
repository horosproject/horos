#ifndef OSCONFIG_H
#define OSCONFIG_H

/*
** Define enclosures for include files with C linkage (mostly system headers)
*/
#ifdef __cplusplus
#define BEGIN_EXTERN_C extern "C" {
#define END_EXTERN_C }
#else
#define BEGIN_EXTERN_C
#define END_EXTERN_C
#endif


/*
** This head includes an OS/Compiler specific configuration header.
** Add entries for specific non-unix OS/Compiler environments.
** Under unix the default <cfunix.h> should be used.
**
*/


#include "cfunix.h"



#endif /* !OSCONFIG_H*/
