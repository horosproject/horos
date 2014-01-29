/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyEalloc3.h                                                */
/*	Function : declaration of the fct of emalloc3                           */
/********************************************************************************/

#ifndef PapyEalloc3H
#define PapyEalloc3H

#include <stddef.h>
#ifdef UNIX
#include <malloc.h>
#endif


#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif


//#ifdef _WINDOWS     
#ifdef __cplusplus
extern "C" 
{
#endif /*__cplusplus */
//#endif /* _WINDOWS */

#ifdef _NO_PROTO
extern void *emalloc3	();
extern void *ecalloc3	();
extern void *erealloc3	();
extern void  efree3	();
#else
extern void *emalloc3  (PapyULong);
extern void *ecalloc3  (PapyULong, PapyULong);
extern void *erealloc3 (void *, PapyULong);
extern void  efree3    (void **);
#endif

//#ifdef _WINDOWS     
#ifdef __cplusplus
}
#endif
//#endif

#endif /* PapyEalloc3H */
