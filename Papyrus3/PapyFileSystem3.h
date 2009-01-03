/********************************************************************************/
/*		                                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyFileSystem3.h                                            */
/*	Function : contains machine specific calls to the different file systems*/
/********************************************************************************/

#ifndef PapyFileSystem3H
#define PapyFileSystem3H

/* ------------------------- includes ------------------------------------------*/

/*#ifndef FILENAME83		 this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif
#ifndef PapyError3H
#include "PapyError3.h"
#endif

/*#else				  FILENAME83 defined for the DOS machines */
/*
#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif
#ifndef PapyError3H
#include "PAPERR3.h"
#endif

#endif
*/

/* ------------------------- functions definition ------------------------------*/

#ifdef _NO_PROTO
extern int		Papy3FCreate ();
extern PapyShort	Papy3FOpen   ();
extern int		Papy3FClose  ();
extern int		Papy3FDelete ();
extern PapyShort 	Papy3FRead   ();
extern PapyShort 	Papy3FWrite  ();
extern int		Papy3FTell   ();
extern int		Papy3FSeek   ();
extern void		Papy3FPrint  ();
extern int              Papy3DGetNbFiles ();
#else
extern int		Papy3FCreate (char *, PAPY_FILE, PAPY_FILE *, void **);
extern PapyShort        Papy3FOpen   (char *, char, PAPY_FILE, PAPY_FILE *, void *);
extern int 		Papy3FClose  (PAPY_FILE *);
extern int		Papy3FDelete (char *, void *);
extern PapyShort 	Papy3FRead   (PAPY_FILE, PapyULong *, PapyULong, void *);
extern PapyShort 	Papy3FWrite  (PAPY_FILE, PapyULong *, PapyULong, void *);
extern int		Papy3FTell   (PAPY_FILE, PapyLong *);
extern int		Papy3FSeek   (PAPY_FILE, int, PapyLong);
extern void		Papy3FPrint  (char *, char *, int);
extern int              Papy3DGetNbFiles (char *, int *);	
#endif

#endif /* PapyFileSystem3H */
