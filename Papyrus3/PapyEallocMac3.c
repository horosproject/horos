/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyEalloc3.c                                                */
/*	Function : contains all the allocating stuff                            */
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
/* 	(C) 1990-2001  The University Hospital of Geneva                        */
/*	          All Rights Reserved                                           */
/*                                                                              */
/********************************************************************************/

/* ------------------------- includes ---------------------------------------*/

#include <Memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif



/********************************************************************************/
/*										*/
/*	checkvp3 : check if the new allocated did not failed			*/
/*	return : the validated pointer if OK				 	*/
/*		 else exit the program						*/
/*									 	*/
/********************************************************************************/

static void *
checkvp3 (void *ioPointer)
{
  if (ioPointer == NULL)
    wildrexit ("allocating memory");
		
  return ioPointer;
	
} /* endof checkvp3 */


/********************************************************************************/
/*										*/
/*	emalloc3 : checked version of malloc				 	*/
/*	return : the validated pointer if OK				  	*/
/*										*/
/********************************************************************************/

void *
emalloc3 (PapyULong inElemSize)
{
  return checkvp3 (NewPtr ((size_t) inElemSize));
} /* endof emalloc3 */


/********************************************************************************/
/*										*/
/*	ecalloc3 : checked version of calloc					*/
/*	return : the validated pointer if OK					*/
/*										*/
/********************************************************************************/

void *
ecalloc3 (PapyULong inNelem, PapyULong inElemSize)
{
  return checkvp3 (NewPtr (((size_t) inNelem * (size_t) inElemSize)));
} /* endof ecalloc3 */


/********************************************************************************/
/*										*/
/*	erealloc3 : checked version of realloc					*/
/*	return : the validated pointer if OK					*/
/*										*/
/********************************************************************************/

void *
erealloc3 (void *inPtr, PapyULong inNewSize, PapyULong inOldSize)
{
/*	return checkvp3 (realloc ((char *) ptr, (size_t) size));*/  
  void	*theP;
  Size	thePtrSize;
  
  
  inOldSize = inOldSize; /* dummy instruction for dummy programmers... */
  
  theP = NewPtr (inNewSize);
  thePtrSize = GetPtrSize (inPtr);
  memmove (theP, inPtr, (size_t) thePtrSize);
  DisposePtr ((Ptr) inPtr);
  
  return theP;

} /* endof erealloc3 */


/********************************************************************************/
/*										*/
/*	efree3 : free the allocated memory and put the pointer to NULL		*/
/*									 	*/
/********************************************************************************/

/* modify it to have the pointer on the pointer to really put it to NULL */

void
efree3 (void **ioPtr)
{
  if ((*ioPtr) != NULL) 
    DisposePtr ((Ptr) *ioPtr);
    
  *ioPtr = NULL;
    
} /* endof efree3 */

