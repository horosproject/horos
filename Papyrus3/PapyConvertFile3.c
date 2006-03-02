/********************************************************************************/
/*		 								*/
/*	Project  : P A P Y R U S  Toolkit				        */
/*	File     : PapyConvertFile3.c				    	        */
/*	Function : contains all the Convertion function			        */
/*      Authors  : Marianne Logean                                              */
/*										*/
/*	History  : 12.1999      version 1.0                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                 11.2001      Modify T1_taille for RGB                        */
/*								   		*/
/* 	(C) 1999-2001  The University Hospital of Geneva			*/      
/*		  All Rights Reserved					        */
/*									 	*/
/********************************************************************************/


/* ------------------------- includes ---------------------------------------*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


#define CHECK_MEMORY
#define HAVE_BOOLEAN

#include "jpegless.h"       	/* interface for JPEG lossless */
#include "jpeglib.h"	    	/* interface for JPEG lossy */

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif


struct color /* a color is defined by its red, green and blue intensity */
{
  int r; 
  int g; 
  int b;
};


/********************************************************************************/
/*									 	*/
/*	ExtractSelection : 						        */
/*	return : 				                                */
/*										*/
/********************************************************************************/

PapyUShort *
ExtractSelection(PapyUShort *image_buffer, int image_width,
		 int depth, int x1, int y1, int x2, int y2)
{
  PapyUShort	 i, j, decal;
  PapyULong      sel_dim;	


  sel_dim = (PapyULong)((PapyULong)(x2 - x1) * (y2 - y1));
  decal = image_width * y1;

  if (depth == 8)
  {
    PapyUChar	 *sel_bufferC, *bufferC, *imageChar;
    PapyUChar	 *image = (PapyUChar *) emalloc3 ((PapyULong) sel_dim + 1L);
    sel_bufferC = image;
    
    /*bufferC = (PapyUChar *) image_buffer;
    bufferC += decal;

    for (i = y1; i < y2; i++)
    {
      bufferC += x1;
      for (j = x1; j < x2; j++)
      {
        *sel_bufferC++ = *bufferC++;
      }
      bufferC += (image_width - x2);
    }*/

    imageChar = (PapyUChar *) image_buffer;
    for (j = 0; j < (y2 - y1); j++)
    {
      bufferC = imageChar + ((long)x1 + image_width * (y1 + j));
      for (i = 0; i < (x2 - x1); i++)
	*sel_bufferC++ = *bufferC++;
    }/* endfor */
  
    return ((PapyUShort *) image);
  }
  else 
  {
    PapyUShort	 *sel_bufferS, *bufferS;
    PapyUShort	 *image = (PapyUShort *) emalloc3 ((PapyULong) sel_dim * sizeof (PapyUShort) + 1L);
    sel_bufferS = image;
    
    /*bufferS = (PapyUShort *) image_buffer;
    bufferS += decal;

    for (i = y1; i < y2; i++)
    {
      bufferS += x1;
      for (j = x1; j < x2; j++)
      {
         *sel_bufferS++ = *bufferS++;
      }
      bufferS += (image_width - x2);
    }*/

    for (j = 0; j < (y2 - y1); j++)
    {
      bufferS = image_buffer + ((long)x1 + image_width * (y1 + j));
      for (i = 0; i < (x2 - x1); i++)
	*sel_bufferS++ = *bufferS++;
    }/* endfor */
  
    return ((PapyUShort *) image);
  }

} /* endof ExtractSelection */


/********************************************************************************/
/*									 	*/
/*	GetPapyFileType : 						        */
/*	return :          the format of the given file                          */
/*										*/
/********************************************************************************/

int GetPapyFileType (char *filename, int *imageNb, int *imageNo, enum EModality *modality)
{ 
  /* verify if it is Papyrus3 or dicom file or Papyrus2 */
  PapyShort     file;
  int           fileKind;
  PapyShort	theErr;
  int		theElemType;
  PapyULong	theNbVal;
  UValue_T	*theValP;
  SElement	*theGroup20P; 
    
  if ((file = Papy3FileOpen (filename, (PAPY_FILE) 0, TRUE, 0)) >= 0)
  {
    *imageNb = (int) Papy3GetNbImages (file);

    *modality =  (enum EModality) Papy3GetModality (file);

    /* if it is a DICOM file: search the dicom image number from the serie */
    if (gIsPapyFile [file] == DICOM10 || gIsPapyFile [file] == DICOM_NOT10)
    {
      /* Image no in Dicom serie */
      *imageNo = 0;
      Papy3GotoNumber (file, 1, DataSetID);

      /* goto group 0x0020 */
      if ((theErr = Papy3GotoGroupNb (file, 0x0020)) == 0)
      {
        /* read group 0x0020 from the file */
        if ((theErr = Papy3GroupRead (file, &theGroup20P)) > 0)
        {
          /* ACQUISITION NUMBER */
          theValP = Papy3GetElement (theGroup20P, papAcquisitionNumberGr, &theNbVal, &theElemType);
          if (theValP != NULL)
            *imageNo = atoi(theValP->a);
        
          /* IMAGE NUMBER */
          theValP = Papy3GetElement (theGroup20P, papImageNumberGr, &theNbVal, &theElemType);
          if (theValP != NULL)
            *imageNo = atoi(theValP->a);


          /* free the group 20 */
          theErr = Papy3GroupFree (&theGroup20P, TRUE);

        }/* read group 0x0020 */
      }/* goto group 0x0020 */
    }/* if it is a DICOM file */
    
    /* close the file a la Papyrus 3 */
    Papy3FileClose (file, TRUE);
   
    fileKind = Papy3GetFileKind (file);
    if (fileKind == 1)
      return PAPYRUS3;
    if (fileKind == 0 || fileKind == 2)
      return DICOM10;
    else if (fileKind == 3)
      return other;
  }
  else return file;

} /* endof GetPapyFileType */


/********************************************************************************/
/*									 	*/
/*	TI_taille : 	resize the original image   		                */
/*	return :                                                                */
/*										*/
/********************************************************************************/

unsigned char* TI_taille(unsigned char *ori, int orix, int oriy, int dstx, int dsty, 
                         int depth, int numPlans, long *taille)
{		
  int             n, i, j, k, l, m, linescanned, dstimx, dstimy, diffx, diffy;
  float           nf;
  long            oritaille;
  unsigned char   *tmp;		
  unsigned char   *oriplane;

  if (orix > oriy)
    nf=(float)((float)orix/dstx);	  
  else
    nf=(float)((float)oriy/dsty);
  n = (int) nf;
  /* use round when divide result is not an integer */
  if ((nf - n) > 0) n++;
  dstimx = orix/n;
  dstimy = oriy/n;

  /* bords de l'image a remplir */
  diffx = (dstx - dstimx) / 2;
  diffy = (dsty - dstimy) / 2;

  oritaille = (long)orix * (long)oriy;
  *taille = (long)dstx * (long)dsty;
  tmp = (unsigned char *) emalloc3 (*taille * (long) numPlans * sizeof(unsigned char));    	
  
  /*for (i=0;i<dstx;i++)     		
    for(j=0;j<dsty;j++)	
      tmp[i+j*dstx]=ori[i*n+j*n*orix];
  */
  
  /* image RGB contient trois plans entrelacés: numPlans = 3 */
  oriplane = (unsigned char *) ori;
    
  /* top of the image */
  for (i = 0, l = 0; l < diffy; l++)
    for (j = 0; j < dstx; j++) 
      for (m = 0; m < numPlans; m++) tmp [i++] = 0;
  
  for (linescanned = 0,j=0, k=0; i<*taille * (long) numPlans; )   
  {
    /* left side */
    if (j == 0)
      for (j = 0; j < diffx; j++) 
        for (m = 0; m < numPlans; m++)  tmp [i++] = 0;
    /* right side */
    if (j == dstimx + diffx)
    {
      for (j = dstimx + diffx; j < dstx; j++) 
        for (m = 0; m < numPlans; m++)  tmp [i++] = 0;
      /* eof line :   j == dstx  */
      j = 0;    
      linescanned += n;
      k = linescanned * orix * numPlans;
    } 
    else if (k < oritaille * (long) numPlans)
    {
      for (m = 0; m < numPlans; m++) tmp[i++] = oriplane[k + m];        
      k += n * (long) numPlans;         
      j++;
    }
    /* bottom of the image */
    else for (m = 0; m < numPlans; m++) tmp [i++] = 0;
  }

  efree3((void**)&ori);
  ori = (unsigned char*) emalloc3 (*taille*(long)numPlans*sizeof(unsigned char));
  (void) memcpy(ori,tmp,*taille*(long)numPlans*sizeof(unsigned char));

  efree3((void**)&tmp);

  return(ori);

} /* endof TI_taille */


/********************************************************************************/
/*									 	*/
/*	Compute8bitsImage : 						        */
/*	return : 				                                */
/*										*/
/********************************************************************************/

PapyUChar *Compute8bitsImage (PapyUShort *inPixmap, int inRows, int inColumns,  
                              int inDepth, int inMin, int inMax)
{
  long 		i, size;
  PapyUShort    *p16b;				/* pixels of image */
  PapyUChar     *newPixmap, *p8b;
  
  
  /* ======================== NEW ORealImage ================================= */
  /* as we do not want to write separate zoom algorithms                       */
  /* for 8 bit and 16 bit images, we just work on 16 bit images                */
  /* so in case of a 16 bit image, just take the pointer on it                 */
  /* in case of an 8 bit image, create a new 16 bit pixmap                     */
  
  /* get original color fork min and max                                       */
  /*forkMin = fOriginalImage->GetColorManager()->FromCalibratedToRaw (fOriginalImage->GetColorManager()->fMinForkCalib);
  forkMax = fOriginalImage->GetColorManager()->FromCalibratedToRaw (fOriginalImage->GetColorManager()->fMaxForkCalib);
  */
  

  /* ============================ 8BITS IMAGE ================================ */
      
  size = inColumns * inRows;

  newPixmap = (PapyUChar *) emalloc3 ((PapyULong) size);
  p8b = newPixmap;
  p16b = inPixmap;
      
  if (inDepth > 8)
  {
    /* conversion to 8 bit image
       convert the 16 bit image into 8 bit image */
    unsigned short *tab; /* conversion array */
    unsigned short dminmax = inMax - inMin;
    int min = inMin;
    int max = inMax;
    if (min < 0) min = 0;
    if (max < 0) max = 0;
    	 
    tab = (unsigned short *) emalloc3 (65535L * sizeof(unsigned short));   /* conversion array */	     
    for (i=min; i<=max;  i++) 
      tab [i] = (unsigned short) (((long)(i - min)) * 255 / dminmax);
    for (i=0;   i<min;   i++)
      tab [i] = 0;
    for (i=max; i<65535; i++)
      tab [i] = 255;
  
    for (i=0; i<size; i++)
      *p8b++ = (unsigned char) tab [*p16b++];
    efree3 ( (void **) &tab);

  }/* endif  */  
  else
  {
    /* just copy the pixmap */
    for (i=0; i<size; i++) 
      *p8b++ = (unsigned char) *p16b++;
  }/* endelse */
      
  return newPixmap;  

} /* endof Compute8bitsImage */




/********************************************************************************/
/*									 	*/
/*	InitClut : initialize clut 						*/
/*	return : 				                                */
/*										*/
/********************************************************************************/

void InitClut (int val, struct color thisClut[])
{
  int i;
  
  if (val < 0)
    for (i=0; i<256; i++)
    {
      thisClut[i].r = i; 
      thisClut[i].g = i;
      thisClut[i].b = i;
    }/* endfor */
  else
    for (i=0; i<256; i++)
    {
      thisClut[i].r = val; 
      thisClut[i].g = val;
      thisClut[i].b = val;
    } /* endfor */
  
}/* endof InitClut */


/********************************************************************************/
/*                                                                              */
/*	Papyrus2Papyrus : convert Papyrus3 file into Papyrus3 format            */
/*	return :                                                                */
/*                                                                              */
/********************************************************************************/

int Papyrus2Papyrus (char *inPapyrusFilename, char *outPapyrusFilename,
                     PAPY_FILE aRefNum, int nbImages, int *tabImage)
{ 
  PapyShort       fp, fpOrig, nbElemInModule;
  int             nbImagesOrig, imageNo, *tabIm, moduleCreated;
  Item		  *dataSet;
  Module	  *module;
  SElement	  *gr, *group;
  PapyUShort      *ipModulevalUS, bitsAllocated, rows, columns, selectedrows, selectedcolumns;
  int		  loop, err;
  enum EModality  mod;
  char		  myString [256], *myStringPtr;
  Data_Set	  *wrkDS;  
  UValue_T	  *val;
  int 		  valType, isOpenOrClose;
  PapyULong	  nbVal;
  int             leftcolumns, toprows, rightcolumns, bottomrows;
  enum ETransf_Syntax syntax;
  PapyUShort      *selectedImage;

  /* initialize */
  myStringPtr = myString;
  
  tabIm = tabImage;

  /* open the original file a la Papyrus 3 */
  fpOrig = Papy3FileOpen (inPapyrusFilename, (PAPY_FILE) 0, TRUE, 0);  
  /* test if the file has been opened correctly */
  if (fpOrig < 0) return (int) fpOrig;

  nbImagesOrig = (int) Papy3GetNbImages (fpOrig); 

  mod =  (enum EModality) Papy3GetModality (fpOrig);

/* enum EPap_Compression	{NONE, JPEG_LOSSLESS, JPEG_LOSSY, RLE}; */ 
  syntax = LITTLE_ENDIAN_EXPL;

#ifdef Mac
  isOpenOrClose = FALSE;
#else
  isOpenOrClose = TRUE;
  aRefNum = (PAPY_FILE)1;
#endif

  fp = Papy3FileCreate (outPapyrusFilename, aRefNum, 
                        (PapyUShort) nbImages, syntax, gCompression,
                        mod, isOpenOrClose, PAPYRUS3, NULL);
  if (fp < 0) { PAPY3PRINTERRMSG (); return -1;}

  /* get a pointer to the group 2 (File Meta Information) */
  gr = Papy3GetGroup2 (fp);
  
  /* fill the necessary elements of this group */
  /* SOP instance UID of this data set */
  strcpy (myStringPtr, "64.572.218.916");
  Papy3PutElement (gr, papMediaStorageSOPInstanceUIDGr, &myStringPtr);
  
  /* who is the creator of this wonderfull file ? */
  strcpy (myStringPtr, "PAPYRUS 3.0");
  Papy3PutElement (gr, papSourceApplicationEntityTitleGr, &myStringPtr);
 
  /* loop on the images */
  for (imageNo = 1; imageNo <= nbImagesOrig, *tabIm == 1; imageNo++, tabIm++) 
  { 
    /* creation of the data set object for this image */
    dataSet = Papy3CreateDataSet (fp);
    
    /* loop on the modules building a image */
    wrkDS = gArrModalities [mod];
    nbElemInModule = Papy3GetNbElemInModule (mod);
    for (loop = 0; loop < nbElemInModule; loop++)
    {
      moduleCreated = FALSE;
      /* get the module from the original file but it could be blank ... */
      module = Papy3GetModule (fpOrig, (short) imageNo, wrkDS->moduleName);
      if (module == NULL)
      {
        /* we have to create the module */
        module = Papy3CreateModule (dataSet, wrkDS->moduleName);
        moduleCreated = TRUE;
      } /* if ...an error occured (bad DICOM file ?) */
      
      /* depending on the module add the modified elements */
      switch (wrkDS->moduleName)
      {
        case Patient :
          /* if we dont want to save the patient name (anonymous file) */
          /*if (hidePatName == TRUE) 
	  {    
            err = Papy3ClearElement (module, papPatientsNameP, TRUE);
            strcpy (myStringPtr, "Anonymous");
            Papy3PutElement (module, papPatientsNameP, &myStringPtr);
            
            err = Papy3ClearElement (module, papOtherPatientNamesP, TRUE);
          }*/ /* if ...hide patient name */
	  break;
	  
	case GeneralStudy :
    	  /* build a foo Study Instance UID */
    	  if (module [papStudyInstanceUIDGS].nb_val == 0)
    	  {
    	    strcpy (myStringPtr, "1.2.756.9999.999.99.9");
    	    Papy3PutElement (module, papStudyInstanceUIDGS, &myStringPtr);
    	  } /* if */
	  break;
	  
	case GeneralSeries :
    	  /* build a foo Series Instance UID */
    	  if (module [papSeriesInstanceUIDGS].nb_val == 0)
    	  {
    	    strcpy (myStringPtr, "1.2.756.9999.999.99.9");
    	    Papy3PutElement (module, papSeriesInstanceUIDGS, &myStringPtr);
          } /* if */
	  break;
	  
	case FrameOfReference :
	  if (module [papFrameofReferenceUID].nb_val == 0L)
	  {
	    strcpy (myStringPtr, "41.22.333.444.555.666.00.1");
    	    Papy3PutElement (module, papFrameofReferenceUID, &myStringPtr);
    	  } /* if */
    	  break;
  
	case GeneralImage :
          if (gCompression == NONE)
            strcpy (myStringPtr, "00");
          else
            strcpy (myStringPtr, "01");
          Papy3PutElement (module, papLossyImageCompressionGI, &myStringPtr);
	  break;
	  
	case ImagePixel : 
	{ 	  
          Papy3ClearElement (module, papSamplesperPixelIP, TRUE);
          
          valUS = 1;
          Papy3PutElement (module, papSamplesperPixelIP, &valUS);

          if (module [papPixelRepresentationIP].nb_val == 0)
	  {
            valUS = 0;
            Papy3PutElement (module, papPixelRepresentationIP, &valUS);
          } 

	  val = Papy3GetElement (module, papRows, &nbVal, &valType);
          rows = val->us;
	  val = Papy3GetElement (module, papColumns, &nbVal, &valType);
	  columns = val->us;
    
	  leftcolumns = (int) (gLeftX*columns);
	  toprows = (int) (gTopY*rows);
	  rightcolumns = (int) (gRightX*columns);
	  bottomrows = (int) (gBottomY*rows);

	  Papy3ClearElement (module, papRows, TRUE);
          selectedrows = (unsigned short) (bottomrows - toprows);
	  Papy3PutElement (module, papRows, &selectedrows);
     
	  Papy3ClearElement (module, papColumns, TRUE);      
	  selectedcolumns = (unsigned short) (rightcolumns - leftcolumns);
	  Papy3PutElement (module, papColumns, &selectedcolumns);
      
    	  /* bits allocated and stored */
	  val = Papy3GetElement (module, papBitsAllocatedIP, &nbVal, &valType);
	  bitsAllocated = val->us;
          /* min and max pixel value in the image */
/*	  valUS = (PapyUShort) newRealImage->GetMinImage ();
	  Papy3PutElement (module, papSmallestImagePixelValue, &valUS);
	  valUS = (PapyUShort) newRealImage->GetMaxImage ();
	  Papy3PutElement (module, papLargestImagePixelValue, &valUS);
*/	  
          /* PIXEL DATA */
          /*image = (PapyUShort *)Papy3GetPixelData (fpOrig, imageNo, module, ImagePixel);*/

          Papy3GotoNumber (fpOrig, imageNo, DataSetID);
  
	  /* then goto group 0x7FE0 */
          Papy3GotoGroupNb (fpOrig, 0x7FE0);
          Papy3GroupRead (fpOrig, &group);
   
          /* get the original image because image not present in the module */
          /* with Papy3GetModule ()   */
          image = (PapyUShort *)Papy3GetPixelData (fpOrig, imageNo, group, ImagePixel);

          selectedImage = ExtractSelection (image, columns, bitsAllocated, 
					    leftcolumns, toprows, 
					    rightcolumns, bottomrows);
          efree3 ((void **) &image);
    
          /* put the image */
          Papy3PutImage ((PapyShort)fp, module, papPixelData, selectedImage,
		     (PapyUShort) selectedrows, (PapyUShort) selectedcolumns,
		     (PapyUShort) bitsAllocated, 0L);

	  Papy3GotoNumber (fpOrig, imageNo, DataSetID);
      
	}
	break;
		
	case CTImage:
	  {
            Papy3ClearElement (module, papReconstructionDiameterCTI, TRUE);
/*          if (!strncmp (fMedStudy->GetPixelSizeUnit (), "mm", 2)) 
            {
              float pixelSize = fMedStudy->GetPixelSize ();
              pixelSize = pixelSize * 100 / fParam->zoomFactor;
              sprintf (myStringPtr, "%.5f", (float) (pixelSize * selectedcolumns));
              Papy3PutElement (module, papReconstructionDiameterCTI, &myStringPtr);
            } */ /* if ...image has been callibrated */
     
     	  }
	  break;
	
	case VOILUT : 
	{
          /* compute the WW and WL of the image */
/*          int WW = fSaveImage->GetForkMax () - fSaveImage->GetForkMin () + 1;
          int WL = (int) ((WW / 2) + fSaveImage->GetForkMin ());
*/  	  
  	  /* clear any previous value */
   	  Papy3ClearElement (module, papWindowCenter, TRUE);
    	  Papy3ClearElement (module, papWindowWidth,   TRUE);
    	  
    	  /* then put the new one */
/*    	  IntToString (WL, myStringPtr);
    	  Papy3PutElement (module, papWindowCenter, &myStringPtr);
    	  IntToString (WW, myStringPtr);
    	  Papy3PutElement (module, papWindowWidth,  &myStringPtr);
*/	}
	break;
        
	default :
	  break;
      
      } /* switch ...add the modified elements */
      
      
      /* link the read module to the list of modules of the data set to write */
      if (!moduleCreated)
	Papy3LinkModuleToDS (dataSet, module, wrkDS->moduleName);
      
      wrkDS++;
           
    } /* for ...loop on the modules of the CT images */
    
  
    /* close the data set and frees the modules */
    err = Papy3CloseDataSet (fp, dataSet, TRUE, TRUE);

  } /* endfor ...loop on the images */
  
  /* close the original file */
  err = (int) Papy3FileClose (fpOrig, TRUE);
 
  /* close the file */
  err = Papy3WriteAndCloseFile (fp, TRUE);
  if (err < 0) { PAPY3PRINTERRMSG (); return -1;}

} /* endof Papyrus2Papyrus */


/********************************************************************************/
/*									 	*/
/*	Papyrus2Dicom : convert Papyrus3 file into DICOM format                 */
/*	return : 				                                */
/*										*/
/********************************************************************************/

int Papyrus2Dicom (char *inPapyrusFilename, char *outDicomFilename, PAPY_FILE aRefNum,
                   int nbImages, int *tabImage)
{ 
  PapyShort	  fp, fpOrig;
  int             nbImagesOrig, imageNo, *tabIm;
  /* PapyUShort      *image, bitsAllocated, rows, columns; */
  enum EModality  mod;
  char		  myString [256], *myStringPtr;
  int 		  isOpenOrClose;
  /*int             leftcolumns, toprows, rightcolumns, bottomrows; */
  enum ETransf_Syntax syntax;
  /* PapyUShort      *selectedImage; */
  PapyShort	  theErr = 0;
  long 	          theFileSize;  
  PAPY_FILE       thePapyFile;


  /* initialize */
  myStringPtr = myString;
  
  tabIm = tabImage;

  /* open the original file a la Papyrus 3 */
  fpOrig = Papy3FileOpen (inPapyrusFilename, (PAPY_FILE) 0, TRUE, 0);  
  /* test if the file has been opened correctly */
  if (fpOrig < 0) return (int) fpOrig;

  thePapyFile = (PAPY_FILE) Papy3GetFile (fpOrig);

  /* get the fileSize */
  theErr = Papy3FSeek (thePapyFile, SEEK_END, 0L);
  theErr = Papy3FTell (thePapyFile, (PapyLong *) &theFileSize);
  theErr = Papy3FSeek (thePapyFile, SEEK_SET, 0L);       

  nbImagesOrig = (int) Papy3GetNbImages (fpOrig); 

  mod =  (enum EModality) Papy3GetModality (fpOrig);

/* enum EPap_Compression	{NONE, JPEG_LOSSLESS, JPEG_LOSSY, RLE}; */ 
  syntax = LITTLE_ENDIAN_EXPL;

#ifdef Mac
  isOpenOrClose = FALSE;
#else
  isOpenOrClose = TRUE;
  aRefNum = (PAPY_FILE) 1;
#endif

  SetCompression (Papy3GetCompression (fpOrig));


  fp = Papy3FileCreate (outDicomFilename, aRefNum, 
                        (PapyUShort) nbImages, syntax, gCompression,
                        mod, isOpenOrClose, DICOM10, NULL);
  
  if (fp < 0) { PAPY3PRINTERRMSG (); return -1;}

  
  /* loop on the images */
  for (imageNo = 1; imageNo <= nbImagesOrig, *tabIm == 1; imageNo++, tabIm++) 
  { 
    PAPY_FILE	theFp;
    PapyULong	theBufSize, theMetaInfoSize;
    unsigned char *theBuffP;
    void	*theVoidP;

    /* create the temporary file that will contain the given data set */
    if ((theErr = CreateTmpFile3 (fp, &theFp, &theVoidP)) < 0)
      RETURN (papFileCreationFailed);
  
    /* if the file is a DICOM one, then put the DICOM header to the temp file */
    /* in order to get a real DICOM file part 10 compliant */
    theErr = WriteDicomHeader3 (theFp, fp, &theMetaInfoSize);
  

    if (imageNo == nbImagesOrig)
      /* compute DataSet size for this image */
      theBufSize = theFileSize - *(gRefImagePointer [fpOrig] + imageNo - 1);
    else
      /* compute DataSet size for this image */
      theBufSize = *(gRefImagePointer [fpOrig] + imageNo) - 
                    *(gRefImagePointer [fpOrig] + imageNo - 1);

    /* alloc the buffer that will contain the ready to write group */
    theBuffP = (unsigned char *) emalloc3 ((PapyULong) theBufSize);

    /* position the file pointer to the begining of the data set */
    theErr = Papy3GotoNumber (fpOrig, imageNo, DataSetID);
    
    theErr = (PapyShort) Papy3FRead (gPapyFile [fpOrig], &theBufSize, 1L, theBuffP);
  
    /* write the buffer to the temporary file */
    if ((theErr = WriteGroup3 (theFp, theBuffP, theBufSize)) < 0)
      RETURN (theErr);  
    
    /* frees the allocated buffer */
    efree3 ((void **) &theBuffP);
    
    /* close the file */
    Papy3FClose (&theFp);
   
  } /* loop on the images */

} /* endof Papyrus2Dicom */


/********************************************************************************/
/*									 	*/
/*	ReadDicomFile :    					                */
/*	return : 				                                */
/*										*/
/********************************************************************************/
/* we assume it is a single frame file !!!!!!!!! */
int ReadDicomFile (char *inDicomFilename, PapyShort inPapyrusFilePointer)
{
  enum EModality  mod;
  PapyShort       dicomFilePointer;
  Data_Set	  *wrkDS;  
  pModule	  *module;
  Item            *dataSet;
  int		  moduleCreated, loop, err = 0;
  PapyUShort      *image, bitsAllocated, rows, columns, samplesPerPixel;
  UValue_T	  *val;
  int 		  valType;
  PapyULong	  nbVal;
  SElement        *group;

  /* open the original file a la Papyrus 3 */
  dicomFilePointer = Papy3FileOpen (inDicomFilename, (PAPY_FILE) 0, TRUE, 0);  

  /* test if the file has been opened correctly */
  if (dicomFilePointer < 0) return (int) dicomFilePointer;

  mod =  (enum EModality) Papy3GetModality (dicomFilePointer);

  /* same MODALITY */
  if (mod != gFileModality [inPapyrusFilePointer]) return (-1);

  /* creation of the data set object for this image */
  dataSet = Papy3CreateDataSet (inPapyrusFilePointer);
    
  /* loop on the modules */
  wrkDS = gArrModalities [mod];
  for (loop = 0; loop < gArrModuleNb [mod]; loop++)
  {
    moduleCreated = FALSE;

    /* get the module from the original file but it could be blank ... */
    module = Papy3GetModule (dicomFilePointer, (short) 1, wrkDS->moduleName);
     
    /*if (module == NULL)
    {
      /* we have to create the module */
  /*    module = Papy3CreateModule (dataSet, wrkDS->moduleName);
      moduleCreated = TRUE;
    } /* if ...an error occured (bad DICOM file ?) */
      
      /* depending on the module add the modified elements */
      switch (wrkDS->moduleName)
      {
        case ImagePixel : 
	{ 	  
          val = Papy3GetElement (module, papRows, &nbVal, &valType);
          rows = val->us;
	  val = Papy3GetElement (module, papColumns, &nbVal, &valType);
	  columns = val->us;
     /*
	  leftcolumns = (int) (leftX*columns);
	  toprows = (int) (topY*rows);
	  rightcolumns = (int) (rightX*columns);
	  bottomrows = (int) (bottomY*rows);

	  Papy3ClearElement (module, papRows, TRUE);
          selectedrows = (unsigned short) (bottomrows - toprows);
	  Papy3PutElement (module, papRows, &selectedrows);
     
	  Papy3ClearElement (module, papColumns, TRUE);      
	  selectedcolumns = (unsigned short) (rightcolumns - leftcolumns);
	  Papy3PutElement (module, papColumns, &selectedcolumns);
      */
    	  /* bits allocated and stored */
	  val = Papy3GetElement (module, papBitsAllocatedIP, &nbVal, &valType);
	  bitsAllocated = val->us;

        /* samples per pixel */
	  val = Papy3GetElement (module, papSamplesperPixelIP, &nbVal, &valType);
	  samplesPerPixel = val->us;

        /* min and max pixel value in the image */
        /*
        valUS = (PapyUShort) newRealImage->GetMinImage ();
	  Papy3PutElement (module, papSmallestImagePixelValue, &valUS);
	  valUS = (PapyUShort) newRealImage->GetMaxImage ();
	  Papy3PutElement (module, papLargestImagePixelValue, &valUS);
*/	  
          /* PIXEL DATA */
          /*image = (PapyUHShort *)Papy3GetPixelData (fpOrig, imageNb, module, ImagePixel);*/

          Papy3GotoNumber (dicomFilePointer, 1, DataSetID);
  
	  /* then goto group 0x7FE0 */
          Papy3GotoGroupNb (dicomFilePointer, 0x7FE0);
          Papy3GroupRead (dicomFilePointer, &group);
   
          /* get the original image because image not present in the module */
          /* with Papy3GetModule ()   */
          image = (PapyUShort *)Papy3GetPixelData (dicomFilePointer, 1, group, ImagePixel);

          /*selectedImage = ExtractSelection (image, columns, bitsAllocated, 
					    leftcolumns, toprows, 
					    rightcolumns, bottomrows);
          efree3 ((void **) &image);
    
          /* put the image */
          /*Papy3PutImage ((PapyShort)inPapyrusFilePointer, module, papPixelData, selectedImage,
		     (PapyUShort) selectedrows, (PapyUShort) selectedcolumns,
		     (PapyUShort) bitsAllocated, 0L);*/

          Papy3PutImage ((PapyShort)inPapyrusFilePointer, module, papPixelData, image,
		     (PapyUShort) rows, (PapyUShort) columns,
		     (PapyUShort) (bitsAllocated * samplesPerPixel), 0L);

	  Papy3GotoNumber (dicomFilePointer, 1, DataSetID);
      
	}
	break;

        default :
	  break;
      
     } /* switch ...add the modified elements */
      
      
     /* link the read module to the list of modules of the data set to write */
     /*if (!moduleCreated)*/
     if (module != NULL)
       Papy3LinkModuleToDS (dataSet, module, wrkDS->moduleName);
          
    wrkDS++;
           
  } /* for ...loop on the modules of the image */

  /* close the data set and frees the modules */
  err = Papy3CloseDataSet (inPapyrusFilePointer, dataSet, TRUE, FALSE);

   /* close the original file */
  err = (int) Papy3FileClose (dicomFilePointer, TRUE);
 
} /* endof ReadDicomFile */


/********************************************************************************/
/*									 	*/
/*	Dicom2Papyrus :   convert DICOM serie into a single papyrus file        */
/*	return : 				                                */
/*										*/
/********************************************************************************/

int Dicom2Papyrus (char *outPapyrusFilename, int inNbDicomImages, char **inDicomFilename, 
                   int inIsSerie, enum EModality modality)
{

  int             i, isOpenOrClose, err = 0;
  PAPY_FILE       aRefNum;
  PapyShort       papyrusFilePointer;
  char            *dicomPath;
  enum ETransf_Syntax syntax;
  SElement        *gr;
  char            myString [256], *myStringPtr;

  /* initialize */
  myStringPtr = myString;


  /* get the number of files in this directory */
  /*Papy3DGetNbFiles (dicomPath, &nbImagesInSerie);*/


/* enum EPap_Compression	{NONE, JPEG_LOSSLESS, JPEG_LOSSY, RLE}; */ 
  syntax = LITTLE_ENDIAN_EXPL;

  isOpenOrClose = TRUE;
  aRefNum = (PAPY_FILE)1;

  papyrusFilePointer = Papy3FileCreate (outPapyrusFilename, aRefNum, 
                                        (PapyUShort) inNbDicomImages, syntax, gCompression,
                                        modality, isOpenOrClose, PAPYRUS3, NULL);

  if (papyrusFilePointer < 0) { PAPY3PRINTERRMSG (); return -1;}

  /* get a pointer to the group 2 (File Meta Information) */
  gr = Papy3GetGroup2 (papyrusFilePointer);
  
  /* fill the necessary elements of this group */
  /* SOP instance UID of this data set */
  strcpy (myStringPtr, "64.572.218.916");
  Papy3PutElement (gr, papMediaStorageSOPInstanceUIDGr, &myStringPtr);
  
  /* who is the creator of this wonderfull file ? */
  strcpy (myStringPtr, "PAPYRUS 3.0");
  Papy3PutElement (gr, papSourceApplicationEntityTitleGr, &myStringPtr);
 
  for (i = 1; i <= inNbDicomImages; i++)
    ReadDicomFile (inDicomFilename[i], papyrusFilePointer);   

  /* close the file */
  err = Papy3WriteAndCloseFile (papyrusFilePointer, TRUE);
  if (err < 0) { PAPY3PRINTERRMSG (); return -1;}

  /* efree3 ((void **)&dicomPath);*/


} /* endof Dicom2Papyrus */


/********************************************************************************/
/*									 	*/
/*	Papyrus2Jpeg :   convert Papyrus3 file into Jpeg format                 */
/*	return : 				                                */
/*										*/
/********************************************************************************/

int Papyrus2Jpeg (char *inPapyrusFilename, char *outJpegBaseFilename, short aRefNum,
                  int *inTabImage, int inJpegWidth, int inJpegHeight,
                  enum EPap_Compression inCompression, int inQuality)
{ 
  char          jpegFilename[512];
  PapyUChar     *theCompPixP, *image;
  PapyUShort    *pixel, *rgbPixel;
  int           imageHeight, imageWidth, imageDepth, isSigned, planarConf;
  float         pixOffset = 0.0, pixSlope = 1.0;
  int           pixMin = 0, pixMax = 0, windowWidth = 1, windowLevel = 0;
  int           pixMinCalib = 0, pixMaxCalib = 0;
  PapyShort     fpOrig;
  int           nbImagesOrig, noImage, numPlans = 1;
  UValue_T	*val, *tmpVal;
  int 		err, valType;
  PapyULong	i, j, nbVal, imageSize, bytesInImage;
  SElement      *group;
  long          longWW, longWL;
  struct color  thisClut[256];
  
  /* open the original file a la Papyrus 3 */
  fpOrig = Papy3FileOpen (inPapyrusFilename, (PAPY_FILE) 0, TRUE, 0);  

  /* test if the file has been opened correctly */
  if (fpOrig < 0) return (int) fpOrig;

  nbImagesOrig = (int) Papy3GetNbImages (fpOrig); 

  for (noImage = 1; noImage <= nbImagesOrig; noImage++)
  {
    /* selected image */
    if (inTabImage[noImage - 1] == 1)
    {
      /* goto the image */
      Papy3GotoNumber (fpOrig, noImage, DataSetID);
  
      /* then goto group 0x0028 */
      if ((err = Papy3GotoGroupNb (fpOrig, 0x0028)) == 0)
      {
        /* read group 0x0028 from the file */
        if ((err = Papy3GroupRead (fpOrig, &group)) > 0)
        {  
          /* rows */
          val = Papy3GetElement (group, papRowsGr, &nbVal, &valType);
          imageHeight = (int) val->us;
          if (inJpegHeight == 0) inJpegHeight = imageHeight;

          /* columns */
          val = Papy3GetElement (group, papColumnsGr, &nbVal, &valType);
          imageWidth = (int) val->us;
          if (inJpegWidth == 0) inJpegWidth = imageWidth;

          /* depth */
          val = Papy3GetElement (group, papBitsAllocatedGr, &nbVal, &valType);
          imageDepth = (int) val->us;

          /* image size */
          imageSize = (PapyULong)imageHeight * (PapyULong)imageWidth;
          bytesInImage = imageSize * ((long) imageDepth / 8L);

          /* pixel representation */
          val = Papy3GetElement (group, papPixelRepresentationGr, &nbVal, &valType);
          if (val != NULL && val->us == 1) isSigned = TRUE;

          /* planar configuration */
          val = Papy3GetElement (group, papPlanarConfigurationGr, &nbVal, &valType);
          if (val != NULL) planarConf = (int) val->us;

          /* pixmin */
          val = Papy3GetElement (group, papSmallestImagePixelValueGr, &nbVal, &valType);
          if (val != NULL) 
          {
            pixMin = (int) val->us;
            if (imageDepth == 8 && pixMin > 255) pixMin = 255;
          }
  
          /* pixmax */
          val = Papy3GetElement (group, papLargestImagePixelValueGr, &nbVal, &valType);
          if (val != NULL) 
          {
            pixMax = (int) val->us;
            if (imageDepth == 8 && pixMax > 255) pixMax = 255;
          }
 
          /* offset */
          val = Papy3GetElement (group, papRescaleInterceptGr, &nbVal, &valType);
          if (val != NULL)
          {
            tmpVal = val;
            /* get the last offset of the image */
            for (i = 1L; i < nbVal; i++) tmpVal++;
            pixOffset = (float)atof ((char *)(tmpVal->a));
            if (pixOffset < 0) pixOffset = -(pixOffset);
          }
  
          /* slope */
          val = Papy3GetElement (group, papRescaleSlopeGr, &nbVal, &valType);
          if (val != NULL)
          {
            tmpVal = val;
            /* get the last slope of the image */
            for (i = 1L; i < nbVal; i++) tmpVal++;
            pixSlope = (float)atof ((char *)(tmpVal->a));
          }

          /* window level */
          val = Papy3GetElement (group, papWindowCenterGr, &nbVal, &valType);
          if (val != NULL)
          {
            tmpVal = val;
            /* get the last window level of the image */
            for (i = 1L; i < nbVal; i++) tmpVal++;
            longWL = (long)atof (tmpVal->a);
      
            /* compute the calibrated value */
            windowLevel = (int)((longWL * pixSlope) - pixOffset);   

          } /* if ...val not NULL */

          /* window width */
          val = Papy3GetElement (group, papWindowWidthGr, &nbVal, &valType);
          if (val != NULL)
          {
            tmpVal = val;
            /* get the last window width of the image */
            for (i = 1L; i < nbVal; i++) tmpVal++;
            longWW = (long)atof (tmpVal->a);
        
            windowWidth = (int)longWW;
	    
          } /* if ...val not NULL */

          /* look for the presence of an eventual Color Palette */
          if (gArrPhotoInterpret [fpOrig] == PALETTE)
          {
            PapyUShort	clutEntryR, clutEntryG, clutEntryB;
            PapyUShort	clutDepthR, clutDepthG, clutDepthB;
        
            /* initialisation */
            clutEntryR = clutEntryG = clutEntryB = 0;
            clutDepthR = clutDepthG = clutDepthB = 0;
         
            InitClut (0, thisClut);

            /* read the RED descriptor of the color lookup table */
            val = Papy3GetElement (group, papRedPaletteColorLookupTableDescriptorGr, &nbVal, &valType);
            tmpVal = val;
            if (val != NULL)
            {
              clutEntryR = tmpVal->us;
              tmpVal++;tmpVal++;
              clutDepthR = tmpVal->us;
            } /* if ...read Red palette color descriptor */
        
            /* read the GREEN descriptor of the color lookup table */
            val = Papy3GetElement (group, papGreenPaletteColorLookupTableDescriptorGr, &nbVal, &valType);
            if (val != NULL)
            {
              clutEntryG = val->us;
              tmpVal     = val + 2;
              clutDepthG = tmpVal->us;
            } /* if ...read Green palette color descriptor */
        
            /* read the BLUE descriptor of the color lookup table */
            val = Papy3GetElement (group, papBluePaletteColorLookupTableDescriptorGr, &nbVal, &valType);
            if (val != NULL)
            {
              clutEntryB = val->us;
              tmpVal     = val + 2;
              clutDepthB = tmpVal->us;
            } /* if ...read Blue palette color descriptor */
        
            /* EXTRACT THE PALETTE data only if there is 256 entries and depth is 16 bits */
            if (clutEntryR == 256 && clutEntryG == 256 && clutEntryB == 256 &&
                clutDepthR == 16  && clutDepthG == 16  && clutDepthB == 16)
            {
              /* extract the RED palette clut data */
              val = Papy3GetElement (group, papRedPaletteCLUTDataGr, &nbVal, &valType);
              if (val != NULL)
              {
                for (j = 0, tmpVal = val; j < clutEntryR; j++, tmpVal++)
                  (thisClut[j]).r = (int) (tmpVal->us/256);
              } /* endif */
          
              /* extract the GREEN palette clut data */
              val = Papy3GetElement (group, papGreenPaletteCLUTDataGr, &nbVal, &valType);
              if (val != NULL)
                for (j = 0, tmpVal = val; j < clutEntryG; j++, tmpVal++)
                  (thisClut[j]).g = (int) (tmpVal->us/256);
            
              /* extract the BLUE palette clut data */
              val = Papy3GetElement (group, papBluePaletteCLUTDataGr, &nbVal, &valType);
              if (val != NULL)
                for (j = 0, tmpVal = val; j < clutEntryB; j++, tmpVal++)
                  (thisClut[j]).b = (int) (tmpVal->us/256);
              
            } /* if ...the palette has 256 entries and thus we extract the clut datas */
          } /* endif ...extraction of the color palette */
          else
            InitClut (-1, thisClut);

          /* free group 28 */
          err = Papy3GroupFree (&group, TRUE);

        } /* endif ...group 28 read */
      } /* endif ...group 28 found */ 

      /* goto the image */
      Papy3GotoNumber (fpOrig, noImage, DataSetID);
  
      /* then goto group 0x7FE0 */
      if ((err = Papy3GotoGroupNb (fpOrig, 0x7FE0)) == 0)
      {
        /* read group 0x7FE0 from the file */
        if ((err = Papy3GroupRead (fpOrig, &group)) > 0) 
        {
          /* PIXEL DATA */
          pixel = (PapyUShort *)Papy3GetPixelData (fpOrig, noImage, group, ImagePixel);
  
          /* if it is a YBR image convert it to a RGB image */
          if (gArrPhotoInterpret [fpOrig] == YBR_FULL ||
              gArrPhotoInterpret [fpOrig] == YBR_FULL_422 ||
              gArrPhotoInterpret [fpOrig] == YBR_PARTIAL_422)
          {    
            rgbPixel = (PapyUShort *) ConvertYbrToRgb ( (PapyUChar *) pixel, imageWidth,
        				                imageHeight, gArrPhotoInterpret [fpOrig], 
        				                (char) planarConf);
            efree3 ((void **) &pixel);
            pixel = rgbPixel;	
            numPlans = 3;
          } /* if ...YBR image */
  
          /* if it is a RGB or a converted to RGB image, convert it to an indexed image */
          if (gArrPhotoInterpret [fpOrig] == RGB ||
              gArrPhotoInterpret [fpOrig] == YBR_FULL ||
              gArrPhotoInterpret [fpOrig] == YBR_FULL_422 ||
              gArrPhotoInterpret [fpOrig] == YBR_PARTIAL_422)
          {
            numPlans = 3;
            /* make the rgbPixel point to what it needs to */
            /*rgbPixel = pixel;*/
    
            /* allocate room for the indexed resulting image */
            /*pixel = (PapyUShort *) ecalloc3 ((PapyULong)imageSize, (PapyULong) sizeof (PapyUShort));
 */
      
            /* interlaced image */
            if (planarConf == 0 || 
                gArrPhotoInterpret [fpOrig] == YBR_FULL ||
                gArrPhotoInterpret [fpOrig] == YBR_FULL_422 ||
                gArrPhotoInterpret [fpOrig] == YBR_PARTIAL_422)
              /* SetRGBImage ((PapyUChar *) rgbPixel, imageWidth, imageHeight, TRUE); */
              ;/*ConvertRGBToIndexed((PapyUChar *) pixel, (PapyUChar *) rgbPixel, imageWidth, imageHeight, thisClut); */
            /* contiguous plane */
            else 
            {
              PapyUChar *Rplane, *Gplane, *Bplane;
          
              Rplane = (PapyUChar *) rgbPixel;
              Gplane = Rplane + (imageWidth * imageHeight);
              Bplane = Gplane + (imageWidth * imageHeight);
          
             /* SetRGBImage (Rplane, Gplane, Bplane, imageWidth, imageHeight, TRUE); */
              ;/*ConvertRGBPixToIndexed((PapyUChar *) pixel, Rplane, Gplane, Bplane, 
                                    imageWidth, imageHeight, thisClut);*/
            } /* else ...contiguous plane */
    
            /* frees the no more needed memory */
            /*efree3 ((void **) &rgbPixel);*/

          } /* endif ...RGB image */
    
          /* **************** 8 bits image **************** */
          if (imageDepth == 8)
          {
            /* if min and max values of the image not in the file : computes them */
            if (pixMin == pixMax || isSigned)
            {
              pixMin = 0;
              pixMax = 255;
            }/* endif ...compute min and max val of the image */
          
            /* if ww and wl not in the file, computes them */
            if (windowWidth == 1 && windowLevel == 0)
            {
              windowWidth = 256;
              windowLevel = windowWidth / 2;
            } /* if ...we have to compute ww and wl      */     

            /* test if the image is stored with inverted pixel values */
            if (gArrPhotoInterpret [fpOrig] == MONOCHROME1)
            {     
              PapyULong theLLoop;
              PapyUChar *theUCharPix;
              PapyUShort invertPix;

              theUCharPix = (PapyUChar *) pixel;
              invertPix=(PapyUShort)pixMax+(PapyUShort)pixMin;

              for (theLLoop = 0L; theLLoop < imageSize; theLLoop++)
              {
                *theUCharPix = invertPix- *theUCharPix;
              
                theUCharPix++;
              } /* for ...image inversion */
            } /* endif ...inversion de l'image  */ 
        
          } /* then ...8 bits images */
  
  
          /* **************** 12 or 16 bits image **************** */
          else if (imageDepth == 12 || imageDepth == 16)
          {
            /* if no min and max image value in the file */
            if (pixMin == pixMax || isSigned)
            {    
              /* compute the max allowed value of the pixel given the bits stored */
              long maxPixValAllowed = 1;
              for (i = 0; i < imageDepth; i++) maxPixValAllowed *= 2;
              maxPixValAllowed -= 1;
          
              /* different ways of computing the values given the pixel representation field */
              if (isSigned)
              {
                PapyShort	*signImage;
                PapyShort	*tmpSh;
                PapyUShort	*tmpUSh;
         
                if (maxPixValAllowed > 32766) maxPixValAllowed = 32766;
      
                signImage = (PapyShort *) pixel;
                tmpSh     = signImage;
         
                pixMin = (int) *signImage;
         
                if (*signImage > maxPixValAllowed)
                {
                  pixMax = maxPixValAllowed;
                  pixMin = maxPixValAllowed;
                }/* endif */
                else 
                {
                  pixMax = (int) *signImage;
                  pixMin = pixMax;
                }/* else */
         
                for (nbVal = 0L; nbVal < imageSize; nbVal++, tmpSh++)
                {
                  /* cut the too big values */
                  if ((int) *tmpSh > maxPixValAllowed) *tmpSh = (short)maxPixValAllowed;
           
                  /* look for the min and max pixel values */
                  if ((int) *tmpSh < pixMin && (int) *tmpSh <= maxPixValAllowed) 
                    pixMin = (int) *tmpSh;
             
                  if ((int) *tmpSh > pixMax && (int) *tmpSh <= maxPixValAllowed)
                    pixMax = (int) *tmpSh;
                } /* for ...extract min and max val from the file */
        
                /* we can set a correct offset to have positiv pixel values */
                pixOffset += (float) -pixMin;

                /* then offset all the pixel values to get a positiv image */
                for (nbVal = 0, tmpSh = signImage, tmpUSh = pixel; 
                     nbVal < imageSize; 
                     nbVal++, tmpSh++, tmpUSh++)
                  *tmpUSh = (PapyUShort) ((PapyShort) *tmpSh - pixMin);
         
                pixMax -= pixMin;
                pixMin = 0;

              } /* endif ...signed pixel values */
      
              /* else unsigned pixel values */
              else
              {
                PapyUShort *tmpSh;
        
                tmpSh = pixel;
         
                if (*pixel > (PapyUShort) maxPixValAllowed) 
                {
                  pixMax = (int) maxPixValAllowed;
                  pixMin = (int) maxPixValAllowed;
                } /* endif */
                else 
                {
                  pixMax = (int) *pixel;
                  pixMin = pixMax;
                } /* else */
         
                for (nbVal = 0L; nbVal < imageSize; nbVal++, tmpSh++)
                {
                  /* cut the too big values */
                  if (*tmpSh > (unsigned short) maxPixValAllowed) 
                    *tmpSh = (unsigned short) maxPixValAllowed;
           
                  /* look for the min and max pixel values */
                  if ((int) *tmpSh < pixMin && (long) *tmpSh <= maxPixValAllowed)  
                    pixMin = (int) *tmpSh;
             
                  if ((int) *tmpSh > pixMax && (long) *tmpSh <= maxPixValAllowed)
                    pixMax = (int) *tmpSh;
                } /* for ...extract min and max val from the file */
        
              } /* else ...unsigned pixel values */
          
            } /* endif ...have to compute min and max values from the file */
  
    
            /* if ww and wl not in the file, computes them */
            if (windowWidth == 1 && windowLevel == 0)
            {    
              pixMinCalib = (int) (((float) pixMin * pixSlope) - pixOffset);
              pixMaxCalib = (int) (((float) pixMax * pixSlope) - pixOffset);             
              windowWidth = pixMaxCalib - pixMinCalib + 1;
              windowLevel = ((windowWidth / 2) + pixMinCalib);
            } /* if ...we have to compute ww and wl */
        
        
            /* test if the image is stored with inverted pixel values */
            if (gArrPhotoInterpret [fpOrig] == MONOCHROME1)
            {   
              PapyULong   theLLoop;
              PapyUShort  *theUShortPix = pixel;
              PapyUShort  fInvertPix =  (PapyUShort)pixMax+(PapyUShort)pixMin;
              for (theLLoop = 0L; theLLoop < imageSize; theLLoop++)
              {
                *theUShortPix =  fInvertPix - *theUShortPix;
                theUShortPix++;
              } /* for ...image inversion */
            } /* endif ...inversion de l'image  */

      
          } /* else ...12 or 16 bits images */
  
          /* free group 7FE0 */
          err = Papy3GroupFree (&group, TRUE);

        } /* endif ...group 7FE0 read */

      } /* endif ...group 7FE0 found */


      /* we do allow only to compress 8bits images.
         so if 16 bits, please convert first        */
      if (imageDepth > 8 && inCompression == JPEG_LOSSY)
      {
        image = Compute8bitsImage ((PapyUShort *)pixel, imageHeight, imageWidth, imageDepth, 
                                    pixMin, pixMax);
        imageDepth = 8;
      }
      else
        image = (PapyUChar *)pixel;

      /* Attention voir pour resize 16 bits  et 3 * 8 bits*/
      /* resize image */
      if (imageHeight != inJpegHeight || imageWidth != inJpegWidth)
        image=TI_taille(image, imageWidth, imageHeight, inJpegWidth, inJpegHeight, 
                        imageDepth, numPlans, &bytesInImage);

      sprintf(jpegFilename,"%s.%d_%d.jpg",outJpegBaseFilename, inJpegWidth, noImage);
      
      if (inCompression == JPEG_LOSSY)
        JPEGLossyEncodeImage (fpOrig, inQuality, (PapyUChar *) jpegFilename, (PapyUChar *) image, 
                              (PapyUChar **) &theCompPixP, (PapyULong *) &bytesInImage, 
                              (int) inJpegHeight, (int) inJpegWidth, 8, TRUE);	
    
      else if (inCompression == JPEG_LOSSLESS)
        JPEGLosslessEncodeImage ((PapyUShort *) image, (PapyUChar **) &theCompPixP,
			         (PapyULong *) &bytesInImage, (int) inJpegWidth, (int) inJpegHeight, 
                                 (int) imageDepth);
#ifdef MAYO_WAVE
      else if (inCompression == MAYO_WAVELET)
        if (WaveletEncodeImage (10, 5, (PapyUChar *) image, (PapyUChar **) &theCompPixP, 
		                (PapyULong *) &bytesInImage,(int) inJpegHeight, (int) inJpegWidth, 
                                (int) imageDepth, (enum EModality) gFileModality[inFileNb] ) != 0)
             return (-1); 
#endif /* MAYO_WAVE */

    } /* if selected image */
  }/* loop on all images of the papyrus or dicom file */

} /* endof Papyrus2Jpeg */


