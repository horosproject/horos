/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit					*/
/*	File     : PapyEalloc3.c						*/
/*	Function : contains all the allocating stuff		     		*/
/********************************************************************************/


/* ------------------------- includes ---------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif
#include  "PapyWild3.h"



/********************************************************************************/
/*										*/
/*	checkvp3 : check if the new allocated did not failed			*/
/*	return : the validated pointer if OK				 	*/
/*		 else exit the program						*/
/*									 	*/
/********************************************************************************/

static inline void *
checkvp3 (void *pointer)
{
	if (pointer == NULL)
		wildrexit ("allocating memory");
		
	return pointer;
	
} /* endof checkvp3 */


/********************************************************************************/
/*										*/
/*	emalloc3 : checked version of malloc				 	*/
/*	return : the validated pointer if OK				  	*/
/*										*/
/********************************************************************************/

void *
emalloc3 (PapyULong size)
{
	return checkvp3 (malloc ((size_t) size));
} /* endof emalloc3 */


/********************************************************************************/
/*										*/
/*	ecalloc3 : checked version of calloc					*/
/*	return : the validated pointer if OK					*/
/*										*/
/********************************************************************************/

void *
ecalloc3 (PapyULong nelem, PapyULong elsize)
{
	return checkvp3 (calloc ((size_t) nelem, (size_t) elsize));
} /* endof ecalloc3 */


/********************************************************************************/
/*										*/
/*	erealloc3 : checked version of realloc					*/
/*	return : the validated pointer if OK					*/
/*										*/
/********************************************************************************/

void *
erealloc3 (void *ptr, PapyULong size,PapyULong size2)
{
  return checkvp3 (realloc ((char *)ptr, (size_t) size));

} /* endof erealloc3 */


/********************************************************************************/
/*										*/
/*	efree3 : free the allocated memory and put the pointer to NULL		*/
/*									 	*/
/********************************************************************************/

/* modify it to have the pointer on the pointer to really put it to NULL */

void
efree3 (void **p)
{
    if (*p) free((char *)*p);
    *p = NULL;
    
} /* endof efree3 */

