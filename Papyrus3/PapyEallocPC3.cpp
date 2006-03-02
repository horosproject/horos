/********************************************************************************/
/*									        */
/*	Project  : P A P Y R U S  Toolkit				        */
/*	File     : PapyEalloc3.c					        */
/*	Function : contains all the allocating stuff		     	        */
/*	Authors  : Matthieu Funk					        */
/*		   Christian Girard					        */
/*		   Jean-Francois Vurlod					        */
/*		   Marianne Logean						*/
/*                 Olivier Baujard                                              */
/*								   	      	*/
/*	History  : 06.1995	version 3.1				        */
/*                 02.1996	version 3.3                                     */
/*                 02.1999	version 3.6                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001	version 3.7   on CVS                            */
/*                 10.2001      version 3.71  MAJ Dicom par CHG                 */
/*                                                                              */
/*								   	        */
/*	(C) 1995-2001  The University Hospital of Geneva                        */
/*		       All Rights Reserved				        */
/*									        */
/********************************************************************************/


/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>


#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif
extern "C" {
#include  "PapyWild3.h"
}

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif
#include "PAPWILD3.h"

#endif 				/* FILENAME83 defined */

#include <windows.h>

#ifdef DLL

#define __huge

#define __far

#define GB_ALLOC

#endif


/*******************************************************************************/
/*									       */
/*	efree3 : free the allocated memory and put the pointer to NULL	       */
/*									       */
/*******************************************************************************/

/* modify it to have the pointer on the pointer to really put it to NULL */

extern "C" void efree3 (void **p)
{
#ifdef GB_ALLOC
    HGLOBAL hglb;
    DWORD dw;
	
    if (*p == NULL)
      return;
    hglb = GlobalHandle (*p);
    GlobalUnlock (hglb);
    GlobalFree (hglb);
    *p = NULL;
#else
/*   free (*p); */
	char* ptr=(char*)*p;
	delete [] ptr;
    *p = NULL;
#endif

} /* endof efree3 */


/*******************************************************************************/
/*									       */
/*	checkvp3 : check if the new allocated did not failed		       */
/*	return : the validated pointer if OK				       */
/*		 else exit the program					       */
/*									       */
/*******************************************************************************/

extern "C" void * checkvp3 (void *pointer)
{
	if (pointer == NULL)
		wildrexit ("allocating memory");
		
	return pointer;
	
} /* endof checkvp3 */


/*******************************************************************************/
/*									       */
/*	emalloc3 : checked version of malloc				       */
/*	return : the validated pointer if OK				       */
/*									       */
/*******************************************************************************/

extern "C" void *emalloc3 (PapyULong size)
{
#ifdef GB_ALLOC
    void __huge* ptr;
    HGLOBAL hglb;
	
    hglb = GlobalAlloc (GHND, size); 

    assert (hglb != NULL);
    ptr = GlobalLock (hglb);
    return checkvp3 (ptr); 
#else
/*    return checkvp3 (malloc ((size_t)size)); */
    char* pp=new char[size];
    memset(pp,0,size);
    return checkvp3((void*)pp);
#endif
} /* endof emalloc3 */


/*******************************************************************************/
/*									       */
/*	ecalloc3 : checked version of calloc				       */
/*	return : the validated pointer if OK				       */
/*									       */
/*******************************************************************************/

extern "C" void *ecalloc3 (PapyULong nelem, PapyULong elsize)
{
#ifdef GB_ALLOC
  void __far* ptr;
	HGLOBAL hglb;
	unsigned long size;
	
	size = nelem * elsize;
        if (size == 0L) return NULL;

	hglb = GlobalAlloc (GHND, size);

	assert (hglb != NULL);
	ptr = GlobalLock (hglb);
	return checkvp3 (ptr);
#else
/*	return checkvp3 (calloc ((size_t)nelem, (size_t)elsize)); */
        char* pp=new char[nelem*elsize];
        memset(pp,0,nelem*elsize);
	return checkvp3((void*)pp);
#endif
} /* endof ecalloc3 */


/*******************************************************************************/
/*									       */
/*	erealloc3 : checked version of realloc				       */
/*	return : the validated pointer if OK				       */
/*									       */
/*******************************************************************************/

extern "C" void *erealloc3 (void* ptr, PapyULong size,PapyULong size2)
{
#ifdef GB_ALLOC
    HGLOBAL hglb;
	DWORD dw;
	hglb = GlobalHandle (ptr);
	GlobalUnlock (hglb);
	hglb = GlobalReAlloc (hglb, size, GMEM_ZEROINIT | GMEM_MOVEABLE);
	ptr = GlobalLock (hglb);
	return checkvp3 (ptr);
#else
/*	return checkvp3 (realloc (ptr, (size_t)size));  */
	char* p=new char[(unsigned int)size];
        memset(p,0,size);
	memcpy(p,(char*)ptr,size2);
	efree3(&ptr);
	return checkvp3 ((void*)p);
#endif
} /* endof erealloc3 */

