/********************************************************************************/
/*		                                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyUtils3.c                                                 */
/*	Function : contains all the utility functions                           */
/*	Authors  : Matthieu Funk                                                */
/*                 Christian Girard                                             */
/*                Jean-Francois Vurlod                                          */
/*                Marianne Logean                                               */
/*                                                                              */
/*	History  : 12.1990      version 1.0                                     */
/*                 04.1991      version 1.1                                     */
/*                 12.1991      version 1.2                                     */
/*                 06.1993      version 2.0                                     */
/*                 06.1994      version 3.0                                     */
/*                 06.1995      version 3.1                                     */
/*                 02.1996      version 3.3                                     */
/*                 02.1999      version 3.6                                     */
/*                 04.2001      version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                 10.2001      version 3.71 MAJ Dicom par CHG                  */
/*                                                                              */
/* 	(C) 1990-2001                                                           */
/*	The University Hospital of Geneva                                       */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>
#include <string.h>

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif	  
  



/********************************************************************************/
/*									 	*/
/*	Papy3SetIconSize : set the size of the icon pixel data. The icon is 	*/
/*	square.							  		*/
/*									      	*/
/********************************************************************************/

void CALLINGCONV
Papy3SetIconSize (PapyUShort inSize)
{
  gIconSize = inSize;
} /* endof Papy3SetIconSize */
  



/********************************************************************************/
/*									 	*/
/*	Papy3GetIconSize : get the size of the icon pixel data. The icon is 	*/
/*	square.							  		*/
/*									      	*/
/********************************************************************************/

PapyUShort CALLINGCONV
Papy3GetIconSize ()
{
  return gIconSize;
} /* endof Papy3GetIconSize */



/********************************************************************************/
/*										*/
/*	PapyStrDup : home made duplification of a string			*/
/* 	return : the pointer on the duplicated string				*/
/*										*/
/********************************************************************************/


char *
PapyStrDup (char *inS)
{
  char *theStr;
  
  if (inS != NULL)
  {
    theStr = (char *) emalloc3 ((PapyULong) (strlen (inS) + 1));
    strcpy (theStr, inS);
  }
  else
    theStr = NULL;

  return theStr;
    
} /* endof PapyStrDup */



/********************************************************************************/
/*									 	*/
/*	Papy3GotoUID : goto the specified data set or the image given the UID	*/
/*	nota : the images are referenced from 1 to nb_images.			*/
/*	return : 0 if there is no error						*/
/*		 papUIDUnknow if the UID is unknow				*/
/*									 	*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GotoUID (PapyShort inFileNb, char *inUIDP, enum EDataSet_Image inDSorIM)

/*int			inFileNb;		           file pointer */
/*char			*inUIDP;		 Data Set IDentificator */
/*enum EDataSet_Image	inDSorIM;	 is it a Data Set or an Image ? */
{
  char			**theUIDP;
  int 			theNumber = 1;		/* corresponding number */
  
  
  theUIDP = gImageSOPinstUID [inFileNb];
  if (*theUIDP == NULL) 
    RETURN (papProblemInValue);
  
  while (theNumber <= gArrNbImages [inFileNb] && strcmp (*theUIDP, inUIDP) != 0)
  {
    theUIDP++;
    theNumber++;
  } /* while */
  
  if (theNumber > gArrNbImages [inFileNb])
    RETURN (papUIDUnknow)
  else
    RETURN (Papy3GotoNumber (inFileNb, theNumber, inDSorIM));
    
} /* endof Papy3GotoUID */



/********************************************************************************/
/*										*/
/*	Papy3GotoNumber : goto the data set or the image from its number 	*/
/* 	nota : the first image has a number of 1.				*/
/* 	return : 0 if all is OK							*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3GotoNumber (PapyShort inFileNb, PapyShort inNb, enum EDataSet_Image inDSorIM)

/*PapyShort		inNb;	    the position of the offset in the list */
/*enum EDataSet_Image	inDSorIM;	    is it a Data Set or an Image ? */
{
  PapyULong		theOffset;

  
  if (inDSorIM == DataSetID)
    theOffset = *(gRefImagePointer [inFileNb] + inNb - 1);
  else
    theOffset = *(gRefPixelOffset [inFileNb]  + inNb - 1);

  /* move the file pointer */
  if (Papy3FSeek (gPapyFile [inFileNb], (int) SEEK_SET, (PapyLong) theOffset) < 0)
    RETURN (papPositioning);
  
  RETURN (papNoError);
  
} /* endof Papy3GotoNumber */



/********************************************************************************/
/*										*/
/*	Papy3CheckValidOwnerId : check if the present code can read the current	*/
/* 	range of element of the shadow group (i.e.: are we the owner of this 	*/
/*	range ?). It extracts the value of the element, and if necessary change */
/*	the group definition for the given range.				*/
/* 	return : TRUE if we are the owner of the element (i.e.: we can read it)	*/
/*		 FALSE if we are not the owner,or if we dont know this element	*/
/*									       	*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3CheckValidOwnerId (PapyShort inFileNb, unsigned char *inBuffP, PapyULong *ioBufPosP,
			PapyUShort inElemNb, PapyULong inElemLength, SElement *inGroupP)

/*unsigned char	*inBuffP;	   	   	 the buffer to read from */
/*PapyULong	*ioBufPosP;		   	 the position in the read buffer */
/*PapyULong	 inElemLength;		   	 the length of the element */
/*SElement	*inGroupP;		   	 the pointer to the group */
{
  int 		i, found = FALSE;
  SShadowOwner	*theShOwP;
  SElement	*theElemP;
  char		*theStringP, *theP;
  unsigned char	*theTmpP;
  PapyUShort	theDefElemNb, theOldNb;
  PapyULong	ii, theGrSize;
  
  
  /* extract the element value (string value) we know it has a VM = 1 */
  /*char_val = extract_char (buff, ioBufPosP, inElemLength);*/
		  			       /* 1 for the string terminator */
  theStringP = (char *) emalloc3 ((PapyULong) (inElemLength + 1));
  theP = theStringP;
  theTmpP = inBuffP;
  /* extract the element from the buffer */
  for (ii = 0L; ii < inElemLength; ii++, (*ioBufPosP)++) 
  {
    *(theP++) = theTmpP [(int) *ioBufPosP];
  }
    
  theStringP [ii] = '\0';	/* string terminator */
  
  /* see if this version of PAPYRUS knows the definition of this range */
  for (i = 0, theShOwP = gShadowOwner [inFileNb]; i < gNbShadowOwner [inFileNb]; i++, theShOwP++)
  {
    /* compares the read value with the known values */
    if (strncmp (theStringP, theShOwP->str_value, strlen (theShOwP->str_value)) == 0)
    { /* we own this range of elements */
      /* find this element in the group definition */
      theElemP = inGroupP;
      theGrSize = gArrGroup [Papy3ToEnumGroup (inGroupP->group)].size;
      ii = 0L;
      while ((ii < theGrSize) && !found)
      {
        if (theElemP->value != NULL && theElemP->value->a != NULL && theElemP->vr != SS &&
	    theElemP->vr    != USS  && theElemP->vr != AT         && theElemP->vr != OW && 
	    theElemP->vr    != SL   && theElemP->vr != UL         && theElemP->vr != FL &&
	    theElemP->vr    != FD   && theElemP->vr != SQ         &&
            (strncmp (theElemP->value->a, theStringP, strlen (theShOwP->str_value)) == 0)) found = TRUE;
        else 
        {
          theElemP++;
          ii++;
        } /* else */
      } /* while */
      
      if (!found) {efree3 ((void **) &theStringP); return FALSE;}	/* error ...! */

      /* BEWARE : it is not necessary to assign the value to the element as */
      /* the right value has been introduced during the initialisation step */
            
      /* different element number => set the element numbers for the whole group */
      if (theElemP->element != inElemNb)
      {        
        theDefElemNb = theElemP->element;  /* originaly defined range */
        
        /* change the definition of the creator... */
        theElemP->element = inElemNb;
        
        theElemP = inGroupP;
        /* loop on the elements of the group */
        for (ii = 0L; ii < theGrSize; ii++, theElemP++)
        {
          /* we have to change this elements definition */
          if (theElemP->element >> 8 == theDefElemNb)
          {
            theOldNb       = theElemP->element;
            /* this deletes the range information and keeps only the element one */
            theOldNb	   = theOldNb << 8;  
            theOldNb	   = theOldNb >> 8;
            
            /* assign the new element number given the extracted range */
            theElemP->element  = inElemNb << 8;
            theElemP->element |= theOldNb;
          } /* if ...change element definition */
        } /* for ...loop on the elements of the group */
      } /* if ...element numbers must be changed */
      
      efree3 ((void **) &theStringP);
    
      return TRUE; /* exits the research loop and the procedure */
    } /* if ...we are the owner of this range of elements */
  } /* for */
  
  efree3 ((void **) &theStringP);
  
  return FALSE;	 /* if we have reached this point we dont know this element */
  
} /* endof Papy3CheckValidOwnerId */



/********************************************************************************/
/*										*/
/*	Papy3ToEnumGroup : given the real number (short) of the group returns	*/
/* 	the enum_place of this group (as it is defined in "PapyInitGroups3.h")	*/
/*	return : positive number (= enumeration place) if we were successful	*/
/*		 standard error message otherwise			  	*/
/*									 	*/
/********************************************************************************/

int CALLINGCONV
Papy3ToEnumGroup (PapyUShort inPapyrusNb)

/*PapyUShort inPapyrusNb;		         the Papyrus defined number */
{
  int i, theEnumPlace;
  
  theEnumPlace = -1;
  			/* there could be more than one OVERLAY in a group, */
  				/* but all have the same enumeration number */
  if (inPapyrusNb >= 0x6000 && inPapyrusNb <= 0x6FFF)
    if (inPapyrusNb % 2 == 0) return Group6000;
    else return UINOVERLAY;
  else
    for (i = 0; i < END_GROUP; i ++)
    {
      if (gArrGroup[i].number == inPapyrusNb) return i;
    } /* for */
  
  RETURN (papEnumGroup)
  
} /* endof Papy3ToEnumGroup */



/********************************************************************************/
/*										*/
/*	Papy3EnumToElemNb : given the enum name of an element find the element	*/
/*	number in the group definition. This is especially usefull with the 	*/
/* 	odd number groups (private data elements).				*/
/*	return : positive number (= elem nb) if we were successful		*/
/*									 	*/
/********************************************************************************/

PapyUShort CALLINGCONV
Papy3EnumToElemNb (SElement *inElemP, int inEnumNb)
{
  SElement	*theElemP;
  
  
  /* look for the pointer to the begining of the group */
  theElemP = inElemP;
  while (theElemP->element != 0x0000) theElemP--;
  
  /* now goto the desired element */
  theElemP += inEnumNb;
  
  return theElemP->element;
      
} /* endof Papy3EnumToElemNb */



/********************************************************************************/
/*										*/
/*	Papy3ElemTagToEnumNb : given the elem tag (gr, elem) look for the enum	*/
/*	number in the group definition.						*/
/*	return : positive number (= elem nb) if we were successful		*/
/*									 	*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3ElemTagToEnumNb (PapyUShort inGrTag, PapyUShort inElemTag, int *outEnumGrP, 
		      int *outEnumElemP)
{
  SElement	*theElemP, *theGroupP;
  
  
  /* first convert the gr tag to enum position */
  *outEnumGrP = Papy3ToEnumGroup (inGrTag);
  
  /* create the group in order to scan it */
  theGroupP = Papy3GroupCreate (*outEnumGrP);
  
  /* look for the element in the group */
  theElemP = theGroupP;
  
  for (*outEnumElemP = 0; *outEnumElemP < (int) gArrGroup [*outEnumGrP].size; (*outEnumElemP)++, theElemP++)
    if (theElemP->element == inElemTag)
      break;
      
  /* delete the group */
  Papy3GroupFree (&theGroupP, TRUE);
  
  /* not found */
  if (*outEnumElemP == (int) gArrGroup [*outEnumGrP].size)
    RETURN (papNotFound);
  
  /* found */
  return 0;
        
} /* endof Papy3ElemTagToEnumNb */


/********************************************************************************/
/*									 	*/
/*	ExtractDicomdirFromPath : Papyrus function to extract the DICOMDIR	*/
/*	name from a whole file path.						*/
/*										*/
/********************************************************************************/

void
ExtractDicomdirFromPath (char *inFilePathP, char *outExtrNameP)
{
  int 		length;
  int		toExtract = 8;			/* length of the DICOMDIR string */
  int 		i;
  
  
  /* first check that the file path is not NULL */
  if (inFilePathP == NULL)
  {
    outExtrNameP [0] = '\0';
    return;
  } /* if ...file path NULL */
  
  /* initialization */
  length = (int) strlen (inFilePathP);
  
  /* one more if ISO 9XXXX encoding */
  if (inFilePathP [length - 1] == '.')
    toExtract++;

  /* it is not necessary to get any further */
  if (length < toExtract)
  {
    outExtrNameP [0] = '\0';
    return;
  } /* if ...file path smaller than DICOMDIR name */
  
  /* copy the last toExtract chars from the file path */
  for (i = 0; i < toExtract; i++)
  {
    outExtrNameP [i] = inFilePathP [(length - (toExtract)) + i];
  } /* for */

  outExtrNameP [toExtract] = '\0';
        
} /* endof ExtractDicomdirFromPath */


/********************************************************************************/
/*									 	*/
/*	ExtractModality : Papyrus function to extract the modality	        */
/*										*/
/********************************************************************************/

void
ExtractModality (UValue_T *inValP, PapyShort inFileNb)
{
  int           i;
  char		theModality [8];
        

  /* is there a value ? */
  if (inValP != NULL)
  {
    strcpy (theModality, inValP->a);
    switch (theModality [0])
    {
      case 'A' :
        i = (int) CR_IM;
        break;
      case 'B' :
        i = (int) MR_IM;
        break;
      case 'C' :
        switch (theModality [1])
        {
          case 'R' :
            i = (int) CR_IM;
            break;
          case 'T' :
            i = (int) CT_IM;
            break;
          case 'D' :
            i = (int) US_IM;
            break;
          case 'F' :
            i = (int) CR_IM;
            break;
          case 'P' :
            i = (int) SEC_CAPT_IM;
            break;
          case 'S' :
            i = (int) SEC_CAPT_IM;
            break;
        } /* switch */
        break;
      case 'D' :
        switch (theModality [1])
        {
          case 'S' :
            i = (int) CR_IM;
            break;
          case 'D' :
            i = (int) US_IM;
            break;
          case 'F' :
            i = (int) CR_IM;
            break;
          case 'G' :
            i = (int) SEC_CAPT_IM;
            break;
          case 'M' :
            i = (int) SEC_CAPT_IM;
            break;
          case 'X' :
            i = (int) DX_IM;
            break;
        } /* switch */
        break;
      case 'E' :
        switch (theModality [1])
        {
          case 'C' :
            i = (int) CR_IM;
            break;
          case 'S' :
            i = (int) SEC_CAPT_IM;
            break;
        } /* switch */
        break;
      case 'F' :
        switch (theModality [1])
        {
          case 'A' :
            i = (int) SEC_CAPT_IM;
            break;
          case 'S' :
            i = (int) SEC_CAPT_IM;
            break;
        } /* switch */
        break;
      case 'I' :
        switch (theModality [1])
        {
          case 'O' :
            i = (int) IO_IM;
            break;
        } /* switch */
        break;
      case 'L' :
        switch (theModality [1])
        {
          case 'P' :
            i = (int) SEC_CAPT_IM;
            break;
          case 'S' :
            i = (int) SEC_CAPT_IM;
            break;
        } /* switch */
        break;
      case 'M' :
        switch (theModality [1])
        {
          case 'A' :
            i = (int) MR_IM;
            break;
          case 'G' :
            i = (int) MG_IM;
            break;
          case 'R' :
            i = (int) MR_IM;
            break;
          case 'S' :
            i = (int) MR_IM;
            break;
          default :
            switch (theModality [2])
            {
              case 'S' : i = (int) MFSBSC_IM;
              case 'T' : i = (int) MFTCSC_IM;
              case 'G' : 
                switch (theModality [3])
                {
                  case 'B' : i = (int) MFGBSC_IM;
                  case 'W' : i = (int) MFGWSC_IM;
                } /* switch ...modality [3] */
                break;
            }/* switch ...modality [2] */
        } /* switch */
        break;
      case 'N' :
        i = (int) NM_IM;
        break;
      case 'O' :
        i = (int) SEC_CAPT_IM;
        break;
      case 'P' :
        switch (theModality [1])
        {
          case 'E' :
            i = (int) PET_IM;
            break;
          case 'X' :
            i = (int) PX_IM;
            break;
          default :
            i = (int) NM_IM;
            break;
        } /* switch */
        break;
      case 'R' :
        switch (theModality [1])
        {
          case 'F' :
            i = (int) RF_IM;
            break;
          default :
            i = (int) CR_IM;
            break;
        } /* switch */
        break;
      case 'S' :
        i = (int) NM_IM;
        break;
      case 'T' :
        i = (int) SEC_CAPT_IM;
        break;
      case 'U' :
        i = (int) US_IM;
        break;
      case 'V' :
        switch (theModality [2])
        {
          case 'E' :
            i = (int) VLE_IM;
            break;
          case 'M' :
            i = (int) VLM_IM;
            break;
          case 'S' :
            i = (int) VLS_IM;
            break;
          case 'P' :
            i = (int) VLP_IM;
            break;
          default :
            i = (int) SEC_CAPT_IM;
            break;
        } /* switch */
        break;
      case 'X' :
        i = (int) CR_IM;
        break;
      default :
        i = (int) SEC_CAPT_IM;
        break;
    } /* switch ...first char of the modality */

    /* set the modality of the file */
    gFileModality [inFileNb] = i;

  } /* if ...inValP not NULL */
  

} /* endof ExtractModality */



/********************************************************************************/
/*										*/
/*	Pap2ToPap3Date : convert the Date from Papyrus2 format to               */
/*      Papyrus3(DICOM) format			                                */
/*									 	*/
/********************************************************************************/
     
void 
Pap2ToPap3Date (char *pap2Date, char *pap3Date)
{
  int	theEnd = FALSE;
  char	*tmp2, *tmp3;
  
  /* initialisation of work ptrs */
  tmp2 = pap2Date;
  tmp3 = pap3Date;
  
  /* loop on the chars of the Papyrus 2 date string */
  while (theEnd == FALSE)
  {
    if (*tmp2 != '.')
    {
      *tmp3 = *tmp2;
      tmp3++;
    } /* if */
    if (*tmp2 == '\0') theEnd = TRUE;
    else tmp2++;
  } /* while */
  
} /* endof Pap2ToPap3Date */



/********************************************************************************/
/*										*/
/*	Pap2ToPap3Time : convert the date from Papyrus2 format to               */
/*      Papyrus3(DICOM) format			                                */
/*									 	*/
/********************************************************************************/

void 
Pap2ToPap3Time (char *pap2Time, char *pap3Time)
{
  int	theEnd = FALSE;
  char	*tmp2, *tmp3;
  
  
  /* initialisation of work ptrs */
  tmp2 = pap2Time;
  tmp3 = pap3Time;
  
  /* loop on the chars of the Papyrus 2 date string */
  while (theEnd == FALSE)
  {
    if (*tmp2 != ':')
    {
      *tmp3 = *tmp2;
      tmp3++;
    } /* if */
    if (*tmp2 == '\0') theEnd = TRUE;
    else tmp2++;
  } /* while */
  
} /* endof Pap2ToPap3Time */



/********************************************************************************/
/*										*/
/*	Pap2ToPap3Name : convert the Name from Papyrus2 format to               */
/*      Papyrus3(DICOM) format			                                */
/*									 	*/
/********************************************************************************/

void 
Pap2ToPap3Name (char *pap2Name, char *pap3Name)
{
  int	theEnd = FALSE;
  char	*tmp2, *tmp3;
  
  
  /* initialisation of work ptrs */
  tmp2 = pap2Name;
  tmp3 = pap3Name;
  
  /* loop on the chars of the Papyrus 2 name string */
  while (theEnd == FALSE)
  {
    if (*tmp2 != ' ')
      *tmp3 = *tmp2;
    else
      *tmp3 = '^';
    
    if (*tmp2 == '\0') theEnd = TRUE;
    else 
    {
      tmp2++;
      tmp3++;
    } /* else */
    
  } /* while */
  
} /* endof Pap2ToPap3Name */



/********************************************************************************/
/*										*/
/*	ConvertYbrToRgb : Convert a YBR_FULL, a YBR_FULL_422 or a               */
/*      YBR_422_PARTIAL image to a RGB image.                                   */
/*	return : 		                                                */
/*									 	*/
/********************************************************************************/

PapyUChar *
ConvertYbrToRgb (PapyUChar *ybrImage, int width, int height, 
	         enum EPhoto_Interpret theKind, char planarConfig)
{
  PapyULong		loop, size;
  PapyUChar		*pYBR, *pRGB;
  PapyUChar		*theRGB;
  int			y, b, r;
  
  
  /* the planar configuration should be set to 0 whenever
     YBR_FULL_422 or YBR_PARTIAL_422 is used              */
  if (theKind != YBR_FULL && planarConfig == 1)
    return NULL;

  size = (PapyULong) width * (PapyULong) height;

  /* allocate room for the RGB image */
  theRGB = (PapyUChar *) emalloc3 (size * 3L);
  if (theRGB == NULL) return NULL;
  pRGB = theRGB;
  
  switch (planarConfig)
  {
    case 0 : /* all pixels stored one after the other */
      switch (theKind)
      {
        case YBR_FULL :		/* YBR_FULL */
          /* loop on the pixels of the image */
          for (loop = 0L, pYBR = ybrImage; loop < size; loop++, pYBR += 3)
          {
            /* get the Y, B and R channels from the original image */
            y = (int) pYBR [0];
            b = (int) pYBR [1];
            r = (int) pYBR [2];
            
            /* red */
            *pRGB = (PapyUChar) (y + (1.402 *  r));
            pRGB++;	/* move the ptr to the Green */
            
            /* green */
            *pRGB = (PapyUChar) (y - (0.344 * b) - (0.714 * r));
            pRGB++;	/* move the ptr to the Blue */
            
            /* blue */
            *pRGB = (PapyUChar) (y + (1.772 * b));
            pRGB++;	/* move the ptr to the next Red */
            
          } /* for ...loop on the elements of the image to convert */
          break; /* YBR_FULL */
        

        case YBR_FULL_422 :	/* YBR_FULL_422 */
        case YBR_PARTIAL_422 :	/* YBR_PARTIAL_422 */
          /* loop on the pixels of the image */
          for (loop = 0L, pYBR = ybrImage; loop < size; loop++)
          {
            /* get the Y, B and R channels from the original image */
            y = (int) pYBR [0];
            /* the Cb and Cr values are sampled horizontally at half the Y rate */
            if (loop % 2 == 0)
            {
              b = (int) pYBR [1];
              r = (int) pYBR [2];
            } /* endif */
            
            /* red */
            *pRGB = (PapyUChar) ((1.1685 * y) + (0.0389 * b) + (1.596 * r));
            pRGB++;	/* move the ptr to the Green */
            
            /* green */
            *pRGB = (PapyUChar) ((1.1685 * y) - (0.401 * b) - (0.813 * r));
            pRGB++;	/* move the ptr to the Blue */
            
            /* blue */
            *pRGB = (PapyUChar) ((1.1685 * y) + (2.024 * b));
            pRGB++;	/* move the ptr to the next Red */
            

            /* the Cb and Cr values are sampled horizontally at half the Y rate */
            if (loop % 2 == 0) 
              pYBR += 3;
            else
              pYBR++;
            
          } /* for ...loop on the elements of the image to convert */
          break; /* YBR_FULL_422 and YBR_PARTIAL_422 */
                
        default :
          /* none...  */
          break;
      } /* switch ...kind of YBR */
      break;
    
    case 1 : /* each plane is stored separately (only allowed for YBR_FULL) */
    {
      PapyUChar *pY, *pB, *pR;	/* ptr to Y, Cb and Cr channels of the original image */
        
      /* points to the begining of each channel in memory */
      pY = ybrImage;
      pB = (PapyUChar *) (pY + size);
      pR = (PapyUChar *) (pB + size);
        
      /* loop on the pixels of the image */
      for (loop = 0L; loop < size; loop++, pY++, pB++, pR++)
      {
        /* red */
        *pRGB = (PapyUChar) ((int) *pY + (1.402 *  (int) *pR) - 179.448);
        pRGB++;	/* move the ptr to the Green */
            
        /* green */
        *pRGB = (PapyUChar) ((int) *pY - (0.344 * (int) *pB) - (0.714 * (int) *pR) + 135.45);
        pRGB++;	/* move the ptr to the Blue */
            
        /* blue */
        *pRGB = (PapyUChar) ((int) *pY + (1.772 * (int) *pB) - 226.8);
        pRGB++;	/* move the ptr to the next Red */
            
      } /* for ...loop on the elements of the image to convert */
      break;
    } /* case 1 */
    
    default :
      /* none */
      break;
  
  } /* switch EPhoto_Interpret */
    
  return theRGB;
  
} /* endof ConvertYbrToRgb */

