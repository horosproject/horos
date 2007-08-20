/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyEalloc3.h                                                */
/*	Function : declaration of the fct of emalloc3                           */
/*	Authors  : Matthieu Funk                                                */
/*                 Christian Girard                                             */
/*                 Jean-Francois Vurlod                                         */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 12.1990	version 1.0                                     */
/*                 04.1991	version 1.1                                     */
/*                 12.1991	version 1.2                                     */
/*                 06.1993	version 2.0                                     */
/*                 06.1994	version 3.0                                     */
/*                 06.1995	version 3.1                                     */
/*                 02.1996	version 3.3                                     */
/*                 02.1999	version 3.6                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                                                                              */
/* 	(C) 1990-2001 The University Hospital of Geneva                         */
/*	         All Rights Reserved                                            */
/*                                                                              */
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
extern void *erealloc3 (void *, PapyULong, PapyULong);
extern void  efree3    (void **);
#endif

//#ifdef _WINDOWS     
#ifdef __cplusplus
}
#endif
//#endif

#endif /* PapyEalloc3H */
