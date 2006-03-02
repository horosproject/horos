/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                           */
/*	File     : TestWrite.c                                                      */
/*	Function : Main for write testing the Papyrus toolkit 3.0.                  */
/*	Authors  : Christian Girard                                                 */
/*	           Marianne Logean                                                  */
/*	History  : 06.1994	version 3.0                                             */
/*             10.1998  version 3.5                                             */
/*             04.2001  version 3.7                                             */
/*                                                                              */
/*	(C) 1994-2001 The University Hospital of Geneva                            */
/*		       All Rights Reserved                                                */
/*                                                                              */
/********************************************************************************/

#include <stdio.h>
#include "Papyrus3.h"


main (int argc, char *argv[])
{
  PapyShort	      fp;
  PapyUShort	    us;
  Item		        *dataSet1, *dataSet2;
  pModule	        *module;
  SElement	      *gr2;
  enum VR_T       theVR;
  char 		        *myChar;
  unsigned short  *image, *imWrk;
  unsigned char   *imageC, *imWrkC;
  int		          i;
    
    
  argv [0] = wildname (argv [0]);
    
  /* initialisation of the Papyrus 3.0 toolkit */
  Papy3Init ();

  /* creation of the test file */
  fp = Papy3FileCreate ("test.papy", 0, 2, LITTLE_ENDIAN_EXPL, JPEG_LOSSLESS, 
			                  CR_IM, TRUE, PAPYRUS3, NULL);

  if (fp < 0) wildexit("test.papy already exist");
  
  /* get a pointer to the group 2 */
  gr2 = Papy3GetGroup2 (fp);
  
  /* fill in the necessary elements of group 2 */
  
  /* SOP instance UID of the media storage */
  myChar = (char *) ecalloc3 ((size_t) 255, (size_t) sizeof (char));
  strcpy (myChar, "some Media Storage SOP Instance UID");
  Papy3PutElement (gr2, papMediaStorageSOPInstanceUIDGr, (void *)&myChar);
  
  /* who is the creator of this wonderfull file ? */
  strcpy (myChar, "PAPYRUS 3.0");
  Papy3PutElement (gr2, papSourceApplicationEntityTitleGr, &myChar);
    
  /* create the first data set object */
  dataSet1 = Papy3CreateDataSet (fp);

/* -------- creation of the Patient module -------- */
  module = Papy3CreateModule (dataSet1, Patient);
  
  /* put some necessary elements in this module */
  strcpy (myChar, "Schiffer^Claudia");
  Papy3PutElement (module, papPatientsNameP, &myChar);
  
  strcpy (myChar, "65 60 90 123");
  Papy3PutElement (module, papPatientIDP, &myChar);
  
  strcpy (myChar, "19650623");
  Papy3PutElement (module, papPatientsBirthDateP, &myChar);
  
  strcpy (myChar, "F");
  Papy3PutElement (module, papPatientsSexP, &myChar);
  
/* -------- creation of the General Study module -------- */
  module = Papy3CreateModule (dataSet1, GeneralStudy);
  
  /* fill some element of the General Study module */
  strcpy (myChar, "41.22.333.444.555.666.00.1");
  Papy3PutElement (module, papStudyInstanceUIDGS, &myChar);
  
  strcpy (myChar, "19940623");
  Papy3PutElement (module, papStudyDateGS, &myChar);
  
  strcpy (myChar, "174042");
  Papy3PutElement (module, papStudyTimeGS, &myChar);
  
  /* IMPORTANT!! This is an example of putting a multiple value to a PAPYRUS file!! */
  strcpy (myChar, "Girard^Christian");
  Papy3PutElement (module, papReferringPhysiciansNameGS, &myChar);
  strcpy (myChar, "Einstein^Albert");
  Papy3PutElement (module, papReferringPhysiciansNameGS, &myChar);
  
/* -------- creation of the General Series module -------- */
  module = Papy3CreateModule (dataSet1, GeneralSeries);

  /* fill some element of the General Series module */
  strcpy (myChar , "CR");
  Papy3PutElement (module, papModalityGS, &myChar);

  strcpy (myChar , "This is the series identifier...");
  Papy3PutElement (module, papSeriesInstanceUIDGS, &myChar);

  strcpy (myChar , "10");
  Papy3PutElement (module, papSeriesNumberGS, &myChar);
  
/* -------- creation of the CR Series module -------- */
  module = Papy3CreateModule (dataSet1, CRSeries);

  /* fill some element of the CR Series module */
  strcpy (myChar , "BREAST");
  Papy3PutElement (module, papBodyPartExaminedCRS, &myChar);

  strcpy (myChar , "AP");
  Papy3PutElement (module, papViewPosition, &myChar);
  
/* -------- creation of the general equipment module -------- */
  module = Papy3CreateModule (dataSet1, GeneralEquipment);

  /* fill some element of the general equipment module */
  strcpy (myChar , "Si mince....");
  Papy3PutElement (module, papManufacturerGE, &myChar);
  
/* -------- creation of the general image module -------- */
  module = Papy3CreateModule (dataSet1, GeneralImage);

  /* fill some element of the general image module */
  strcpy (myChar , "1");
  Papy3PutElement (module, papInstanceNumberGI, &myChar);
  
/* -------- creation of the image pixel module -------- */
  module = Papy3CreateModule (dataSet1, ImagePixel);

  /* fill some element of the image pixel module */
  us = 1;
  Papy3PutElement (module, papSamplesperPixelIP, &us);
 
  strcpy (myChar , "MONOCHROME2");
  Papy3PutElement (module, papPhotometricInterpretationIP, &myChar);

  us = 64;
  Papy3PutElement (module, papRows, &us);
  Papy3PutElement (module, papColumns, &us);
  
  us = 16;
  Papy3PutElement (module, papBitsAllocatedIP, &us);
  Papy3PutElement (module, papBitsStoredIP, &us);
  Papy3PutElement (module, papHighBitIP, &us);
  
  us = 0;
  Papy3PutElement (module, papSmallestImagePixelValue, &us);
  us = 4095;
  Papy3PutElement (module, papLargestImagePixelValue, &us);
  
  us = 0;
  Papy3PutElement (module, papPixelRepresentationIP, &us);
  
  /* creation of the test image */
  image = (unsigned short *) ecalloc3 ((PapyULong) 4096, (PapyULong) (sizeof (unsigned short)));
  imWrk = image;
  for (i = 0; i < 4096; i++)
  {
    *imWrk = i;
    imWrk++;
  } /* for */

  Papy3PutImage (fp, module, papPixelData, (PapyUShort *) image, 
		 64, 64, 16, 0L);
  
/* -------- creation of the CR image module -------- */
  module = Papy3CreateModule (dataSet1, CRImage);

  /* fill some element of the CR image module */
  strcpy (myChar , "plate ID");
  Papy3PutElement (module, papPlateID, &myChar);
   
/* -------- creation of the SOP Common module -------- */
  module = Papy3CreateModule (dataSet1, SOPCommon);

  /* fill some element of the CR image module */
  strcpy (myChar , "1.2.840.10008.5.1.4.1.1.1");
  Papy3PutElement (module, papSOPClassUID, &myChar);

  strcpy (myChar , "1.2.840.10008.5.1.4.1.1.1.333.444.55");
  Papy3PutElement (module, papSOPInstanceUID, &myChar);
  
/* -------- close the data set and frees the modules -------- */
  Papy3CloseDataSet (fp, dataSet1, TRUE, FALSE);
  
  /* free the allocated image */
  efree3 ((void **)&image);
 
/******************************************************/

  /* create the second data set object */
  dataSet2 = Papy3CreateDataSet (fp);

/* -------- creation of the Patient module -------- */
  module = Papy3CreateModule (dataSet2, Patient);
  
  /* put some necessary elements in this module */
  strcpy (myChar, "Schiffer^Claudia");
  Papy3PutElement (module, papPatientsNameP, &myChar);
  
  strcpy (myChar, "65 60 90 123");
  Papy3PutElement (module, papPatientIDP, &myChar);
  
  strcpy (myChar, "19650623");
  Papy3PutElement (module, papPatientsBirthDateP, &myChar);
  
  strcpy (myChar, "F");
  Papy3PutElement (module, papPatientsSexP, &myChar);
  
/* -------- creation of the General Study module -------- */
  module = Papy3CreateModule (dataSet2, GeneralStudy);
  
  /* fill some element of the General Study module */
  strcpy (myChar, "41.22.333.444.555.666.00.1");
  Papy3PutElement (module, papStudyInstanceUIDGS, &myChar);
  
  strcpy (myChar, "19940623");
  Papy3PutElement (module, papStudyDateGS, &myChar);
  
  strcpy (myChar, "174042");
  Papy3PutElement (module, papStudyTimeGS, &myChar);
  
  /* IMPORTANT!! This is an example of putting a multiple value to a PAPYRUS file!! */
  strcpy (myChar, "Girard^Christian");
  Papy3PutElement (module, papReferringPhysiciansNameGS, &myChar);
  strcpy (myChar, "Einstein^Albert");
  Papy3PutElement (module, papReferringPhysiciansNameGS, &myChar);
  
/* -------- creation of the General Series module -------- */
  module = Papy3CreateModule (dataSet2, GeneralSeries);

  /* fill some element of the General Series module */
  strcpy (myChar , "CR");
  Papy3PutElement (module, papModalityGS, &myChar);

  strcpy (myChar , "This is the series identifier...");
  Papy3PutElement (module, papSeriesInstanceUIDGS, &myChar);

  strcpy (myChar , "10");
  Papy3PutElement (module, papSeriesNumberGS, &myChar);
  
/* -------- creation of the CR Series module -------- */
  module = Papy3CreateModule (dataSet2, CRSeries);

  /* fill some element of the CR Series module */
  strcpy (myChar , "BREAST");
  Papy3PutElement (module, papBodyPartExaminedCRS, &myChar);

  strcpy (myChar , "AP");
  Papy3PutElement (module, papViewPosition, &myChar);
  
/* -------- creation of the general equipment module -------- */
  module = Papy3CreateModule (dataSet2, GeneralEquipment);

  /* fill some element of the general equipment module */
  strcpy (myChar , "Si mince....");
  Papy3PutElement (module, papManufacturerGE, &myChar);
  
/* -------- creation of the general image module -------- */
  module = Papy3CreateModule (dataSet2, GeneralImage);

  /* fill some element of the general image module */
  strcpy (myChar , "2");
  Papy3PutElement (module, papInstanceNumberGI, &myChar);
  
/* -------- creation of the image pixel module -------- */
  module = Papy3CreateModule (dataSet2, ImagePixel);

  /* fill some element of the image pixel module */
  us = 1;
  Papy3PutElement (module, papSamplesperPixelIP, &us);
 
  strcpy (myChar , "MONOCHROME2");
  Papy3PutElement (module, papPhotometricInterpretationIP, &myChar);

  us = 64;
  Papy3PutElement (module, papRows, &us);
  Papy3PutElement (module, papColumns, &us);
  
  us = 8;
  Papy3PutElement (module, papBitsAllocatedIP, &us);
  Papy3PutElement (module, papBitsStoredIP, &us);
  Papy3PutElement (module, papHighBitIP, &us);
  
  us = 0;
  Papy3PutElement (module, papSmallestImagePixelValue, &us);
  us = 255;
  Papy3PutElement (module, papLargestImagePixelValue, &us);
  
  us = 0;
  Papy3PutElement (module, papPixelRepresentationIP, &us);
  
  /* creation of the test image */
  imageC = (unsigned char *) ecalloc3 ((PapyULong) 4096, (PapyULong) (sizeof (unsigned char)));
  imWrkC = imageC;
  for (i = 0; i < 4096; i++)
  {
    *imWrkC = 250;
    imWrkC++;
  } /* for */

  Papy3PutImage (fp, module, papPixelData, (PapyUShort *) imageC, 
		 64, 64, 8, 0L);
  
/* -------- creation of the CR image module -------- */
  module = Papy3CreateModule (dataSet2, CRImage);

  /* fill some element of the CR image module */
  strcpy (myChar , "plate ID");
  Papy3PutElement (module, papPlateID, &myChar);
   
/* -------- creation of the SOP Common module -------- */
  module = Papy3CreateModule (dataSet2, SOPCommon);

  /* fill some element of the CR image module */
  strcpy (myChar , "1.2.840.10008.5.1.4.1.1.1");
  Papy3PutElement (module, papSOPClassUID, &myChar);

  strcpy (myChar , "1.2.840.10008.5.1.4.1.1.1.333.444.55");
  Papy3PutElement (module, papSOPInstanceUID, &myChar);
  
/* -------- close the data set and frees the modules -------- */
  Papy3CloseDataSet (fp, dataSet2, TRUE, FALSE);
  
  /* free the allocated image */
  efree3 ((void **)&imageC);
 


   
/* -------- close and free the file and the associated allocated memory -------- */
  Papy3WriteAndCloseFile (fp, TRUE);
    
} /* end of main */
