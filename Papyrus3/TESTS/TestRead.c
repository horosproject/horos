/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                           */
/*	File     : TestRead.c                                                       */
/*	Function : Main for read testing the Papyrus toolkit 3.0.                   */
/*	Authors  : Christian Girard                                                 */
/*             Marianne Logean                                                  */
/*                                                                              */
/*	History  : 07.1994	version 3.0                                             */
/*             03.1999  version 3.6                                             */
/*             04.2001  version 3.7                                             */
/*                                                                              */
/*	(C) 1994-2001 The University Hospital of Geneva                             */
/*		       All Rights Reserved                                                */
/*                                                                              */
/********************************************************************************/
#define MAIN

#include <stdio.h>
#include "Papyrus3.h"


main (int argc, char *argv[])
{
  char          patName[256], firstPhysician [256], secondPhysician [256];
  int           itemType;
  PapyUShort	  *theImage;
  PapyShort	    fileNb, imageNb, err;
  PapyULong     nbVal, i;
  pModule	      *module;    
  UValue_T      *val, *tmp;
  SElement      *group;

  /* initialisation of the Papyrus toolkit v3.6 */
  Papy3Init ();

  /* open the test file */
  fileNb = Papy3FileOpen (argv [1], (PAPY_FILE) 0, TRUE, 0);
  if (fileNb < 0)
  {
    PAPY3PRINTERRMSG ();
    exit(1);
  }
  
  imageNb = 1; /* first image */


  /* get the Patient module */
  module = Papy3GetModule (fileNb, (PapyShort)imageNb, Patient);
  
  /* get the patients name */
  val = Papy3GetElement (module, papPatientsNameP, &nbVal, &itemType);
  if (val != NULL)
    strcpy (patName, val->a);

  /* free the module and the associated sequences */
  Papy3ModuleFree (&module, Patient, TRUE);
  
  /* get the General Study module */
  module = Papy3GetModule (fileNb, (PapyShort)imageNb, GeneralStudy);
  
  /* IMPORTANT!!: this is an example of how to get multiple values!! */
  val = Papy3GetElement (module, papReferringPhysiciansNameGS, &nbVal, &itemType);
  if (val != NULL)
  {
    strcpy (firstPhysician, val->a);
    /* this allows to get the next value */
    tmp = val;
    /* get the second Physician Name */
    for (i = 1L; i < nbVal; i++) tmp ++;
    strcpy (secondPhysician, tmp->a);
  }

  /* free the module and the associated sequences */
  Papy3ModuleFree (&module, GeneralStudy, TRUE);
  
  /* position the file pointer to the begining of the data set */
  err = Papy3GotoNumber (fileNb, (PapyShort)imageNb, DataSetID);

  /* then goto group 0x7FE0 */
  if ((err = Papy3GotoGroupNb (fileNb, 0x7FE0)) == 0)
  {
    /* read group 0x7FE0 from the file */
    if ((err = Papy3GroupRead (fileNb, &group)) > 0) 
    {
      /* PIXEL DATA */
      theImage = (PapyUShort *)Papy3GetPixelData (fileNb, imageNb, group, ImagePixel);

      /* free group 7FE0 */
      err = Papy3GroupFree (&group, TRUE);

    } /* endif ...group 7FE0 read */

  } /* endif ...group 7FE0 found */

    
  /* close and free the file and the associated allocated memory */
  Papy3FileClose (fileNb, TRUE);
    
} /* end of main */
