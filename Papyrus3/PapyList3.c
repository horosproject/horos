/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyList3.c                                                  */
/*	Function : Generic list handler for handling the list of modules,       */
/* 	           objects and sequences in Papyrus 3                           */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>
#include <memory.h>


#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif



/********************************************************************************/
/*										*/
/*	InsertFirstInList : Create a new Item at the first place in the list 	*/
/*	and insert the givenpObjectt in it.					*/
/*	return : The created cell if OK, NULL otherwise				*/
/*										*/
/********************************************************************************/

Papy_List *
InsertFirstInList (Papy_List **ioListP, papObject *inElemToInsertP)
{
  Papy_List	*theNewCellP;


  /* create the new cell and put the pObject in */
  if ((theNewCellP = (Papy_List *) emalloc3 ((PapyULong) sizeof (Papy_List))) == NULL)
    return NULL;
  theNewCellP->object = inElemToInsertP;
  theNewCellP->next   = (*ioListP);
  
  /* change the head pointer */
  *ioListP = theNewCellP;
  
  return theNewCellP;
  
} /* endof InsertFirstInList */



/********************************************************************************/
/*										*/
/*	InsertLastInList : Create a new Item at the last place in the list 	*/
/*	and insert the given pObject in it.					*/
/*	return : The created cell if OK, NULL otherwise				*/
/*										*/
/********************************************************************************/

Papy_List *
InsertLastInList (Papy_List **ioListP, papObject *inElemToInsertP)
{
  Papy_List	*theWrkP, *theNewCellP;
  
  
  /* create the new cell and put the pObject in */
  if ((theNewCellP = (Papy_List *) emalloc3 ((PapyULong) sizeof (Papy_List))) == NULL)
    return NULL;
  theNewCellP->object = inElemToInsertP;
  theNewCellP->next   = NULL;
  
  /* if the ioListP is empty */
  if (*ioListP == NULL)
    *ioListP = theNewCellP;
  else
  {
    /* look for the last cell */
    theWrkP = *ioListP;
    while (theWrkP->next != NULL) theWrkP = theWrkP->next;
  
    /* insert the new element */
    theWrkP->next = theNewCellP;
  } /* else */
  
  return theNewCellP;
  
} /* endof InsertLastInList */



/********************************************************************************/
/*										*/
/*	InsertInListAt : Create a new Item after the specified cell in the list	*/
/*	and insert the given pObject in it.					*/
/*	return : The created cell if OK, NULL otherwise				*/
/*										*/
/********************************************************************************/

Papy_List *
InsertInListAt (Papy_List **ioListP, papObject *inElemToInsertP, PapyShort inPos)
{
  Papy_List	*theWrkP, *theNewCellP;
  PapyShort	i;
  
  
  /* create the new cell and put the pObject in */
  if ((theNewCellP = (Papy_List *) emalloc3 ((PapyULong) sizeof (Papy_List))) == NULL)
    return NULL;
  theNewCellP->object = inElemToInsertP;
  theNewCellP->next   = NULL;
  
  /* if the ioListP is empty */
  if (*ioListP == NULL || inPos == 0)
  {
    theNewCellP->next = NULL;
    *ioListP          = theNewCellP;
  }
  else 
  {
    /* look for the insertion point */
    theWrkP = *ioListP;
    for (i = 1; i < inPos; i++)
    {
      if (theWrkP == NULL) return NULL;
      theWrkP = theWrkP->next;
    } /* for */
  
    /* insert the new element */
    theNewCellP->next = theWrkP->next;
    theWrkP->next     = theNewCellP;
  } /* else */
  
  return theNewCellP;
  
} /* endof InsertInListAt */



/********************************************************************************/
/*										*/
/*	InsertGroupInList : Create a new Item containing a group. The insertion	*/
/* 	criteria is that the group numbers are increasing.			*/ 
/*	return : The created cell if OK, NULL otherwise				*/
/*										*/
/********************************************************************************/

Papy_List *
InsertGroupInList (Papy_List **ioListP, papObject *inElemToInsertP)
{
  Papy_List	*theWrk1P, *theWrk2P, *theNewCellP;
  
  
  
  /* verify it is a group */
  if (inElemToInsertP->whoAmI != papGroup) return NULL;

  /* create the new cell and put the pObject in */
  if ((theNewCellP = (Papy_List *) emalloc3 ((PapyULong) sizeof (Papy_List))) == NULL)
    return NULL;
  theNewCellP->object = inElemToInsertP;
  theNewCellP->next   = NULL;
  
  /* if the ioListP is empty */
  if ((*ioListP == NULL) || 
      ((*ioListP)->object->group->group > theNewCellP->object->group->group))
  {
    theNewCellP->next = *ioListP;
    *ioListP          = theNewCellP;
  }
  else 
  {
    /* look for the insertion point, i.e. compares the group numbers */
    theWrk1P = *ioListP;
    theWrk2P = *ioListP;
    while ((theWrk1P != NULL) && 
    	   (theWrk1P->object->group->group < theNewCellP->object->group->group))
    {
      theWrk2P = theWrk1P;
      theWrk1P = theWrk1P->next;
    } /* while */
  
    /* insert the new element */
    theNewCellP->next = theWrk1P;
    theWrk2P->next    = theNewCellP;
    
  } /* else */
  
  return theNewCellP;
  
} /* endof InsertGroupInList */



/********************************************************************************/
/*										*/
/*	FreeCell : Deletes the given item as well as its content. Deletes the 	*/
/* 	content selectively depending on the values of the parameters.This 	*/
/*	allows to reuse the modules, the groups and the sequences in multiple 	*/
/*	data sets.								*/
/*	return : papNoError if OK, standard error message otherwise.		*/
/*										*/
/********************************************************************************/

PapyShort
FreeCell (PapyShort inFileNb, Papy_List **ioToFreeP, int inDelAll, int inDelGroup, int inDelSeq)
{
  PapyShort	theErr = 0;
  
  
  /* free the content of the cell if the toDel parameter is set to TRUE */
  if (inDelAll)
    switch ((*ioToFreeP)->object->whoAmI)
    {
      case papItem :
        DeleteList (inFileNb, (Papy_List **) &((*ioToFreeP)->object->item), inDelAll, inDelGroup, inDelSeq);
        break;
      case papModule :
        theErr = Papy3ModuleFree (&((*ioToFreeP)->object->module), 
        		          (*ioToFreeP)->object->objID, inDelSeq);
        if (theErr < 0) RETURN (theErr);
        break;
      case papRecord :
        theErr = Papy3RecordFree (&((*ioToFreeP)->object->record), 
        		          (*ioToFreeP)->object->objID, inDelSeq);
        if (theErr < 0) RETURN (theErr);
        break;
      case papGroup :
        if (inDelGroup)
          if ((theErr = Papy3GroupFree (&((*ioToFreeP)->object->group), inDelSeq)) < 0)
            RETURN (theErr);
        break;
      case papTmpFile :
	      {
	        char *tmpFilename, myStr [32];
	        /* build the name of the temp file containing the data set */
	        /* it will look like <<filenameXXXX.dcm>> */
	        tmpFilename = (char *) ecalloc3 ((PapyULong) 256, (PapyULong) sizeof (char));
	        strcpy (tmpFilename, gPapFilename [inFileNb]);
	        Papy3FPrint (myStr, "%d", (*ioToFreeP)->object->objID);
	        strcat (myStr, ".dcm");
	        strcat (myStr, "\0");
	        if ((*ioToFreeP)->object->objID      < 10)
		      strcat (tmpFilename, "000");
	        else if ((*ioToFreeP)->object->objID < 100)
		      strcat (tmpFilename, "00");
	        else if ((*ioToFreeP)->object->objID < 1000)
		      strcat (tmpFilename, "0");
	        strcat (tmpFilename, myStr);
		      
	        /* delete the tmp file only if the result is a PAPYRUS file  */
	        if (gIsPapyFile [inFileNb] == PAPYRUS3)
	        {
	          if ((theErr = Papy3FDelete (tmpFilename, (*ioToFreeP)->object->file)) != 0)
	          RETURN (papDeleteFile);
	        } /* if ...PAPYRUS file */
	        efree3 ((void **) &tmpFilename);
	        
	        if ((*ioToFreeP)->object->file != NULL)
	          efree3 ((void **) &((*ioToFreeP)->object->file));
	      }
        break;
      default :
        break;
    } /* switch ...type of the content of the object */
  
  /* make all the pointers of the object point to NULL */
  (*ioToFreeP)->object->item          = NULL;
  (*ioToFreeP)->object->module        = NULL;
  (*ioToFreeP)->object->group         = NULL;
  (*ioToFreeP)->object->tmpFileLength = 0L;
  
  /* free the cell */  
  efree3 ((void **) &((*ioToFreeP)->object));
  efree3 ((void **) ioToFreeP);
  
  RETURN (theErr);

} /* endof FreeCell */



/********************************************************************************/
/*										*/
/*	DeleteFirstInList : Deletes the first element of the list.		*/
/*	return : papNoError if OK, listError in case of an error.		*/
/*										*/
/********************************************************************************/

PapyShort
DeleteFirstInList (PapyShort inFileNb, Papy_List **ioListP, int inDelAll, int inDelGroup, int inDelSeq)
{
  Papy_List	*theWrkP;
  PapyShort	theErr = 0;


  if (*ioListP == NULL) return theErr;
  
  /* change the head pointer */
  theWrkP  = *ioListP;
  *ioListP = (*ioListP)->next;
  
  /* free the cell and its content */
  theErr = FreeCell (inFileNb, &theWrkP, inDelAll, inDelGroup, inDelSeq);
  
  RETURN (theErr);
  
} /* endof DeleteFirstInList */



/********************************************************************************/
/*										*/
/*	DeleteLastInList : Deletes the last element of the list.		*/
/*	return : papNoError if OK, listError in case of an error.		*/
/*										*/
/********************************************************************************/

PapyShort
DeleteLastInList (PapyShort inFileNb, Papy_List **ioListP, int inDelAll, int inDelGroup, int inDelSeq)
{
  Papy_List	*theWrk1P, *theWrk2P;
  PapyShort	theErr = 0;


  if (*ioListP == NULL) return theErr;
  
  /* search the last cell of the list */
  theWrk1P = *ioListP;
  theWrk2P = NULL;
  while (theWrk1P->next != NULL) 
  {
    theWrk2P = theWrk1P;
    theWrk1P = theWrk1P->next;
  } /* while */
  
  if (theWrk2P != NULL) theWrk2P->next = NULL;
  else *ioListP = NULL;
  
  /* free the cell and its content */
  theErr = FreeCell (inFileNb, &theWrk1P, inDelAll, inDelGroup, inDelSeq);
  
  RETURN (theErr);
  
} /* endof DeleteLastInList */



/********************************************************************************/
/*										*/
/*	DeleteList : Deletes the list as well as its elements. Begins by the 	*/
/*	first element and loop to the end of the list.				*/
/*	return : papNoError if OK, listError in case of an error.		*/
/*										*/
/********************************************************************************/

PapyShort
DeleteList (PapyShort inFileNb, Papy_List **ioListP, int inDelAll, int inDelGroup, int inDelSeq)
{
  Papy_List	*toFree, *theWrkP;
  PapyShort	theErr = 0;


  if (*ioListP == NULL) return theErr;
  
  /* loop on the elements of the list and frees them begining by the first one */
  toFree = *ioListP;
  while (toFree != NULL)
  {
    theWrkP = toFree->next;
    
    /* free the cell and its content */
    if ((theErr = FreeCell (inFileNb, &toFree, inDelAll, inDelGroup, inDelSeq)) < 0) RETURN (theErr);
       
    toFree = theWrkP;
    
  } /* while ...loop on the elements of the list */
  
  *ioListP = NULL;
  
  RETURN (theErr);
  
} /* endof DeleteList */
