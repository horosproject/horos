/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyInit3.c                                                  */
/*	Function : contains all the initialisation functions                    */
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
/*                 10.2001      version 3.71 MAJ Dicom par CHG                  */
/*                                                                              */
/* 	(C) 1990-2001 The University Hospital of Geneva                         */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3
#endif

/* ------------------------- includes -----------------------------------------*/

#include <stdio.h>

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif

#ifndef PapyInitModules3H
#ifndef FILENAME83		/* this is for the normal machines ... */
#include "PapyInitModules3.h"
#else				/* FILENAME83 defined for the DOS machines */
#include "PAPINIM3.h"
#endif
#endif 				/* FILENAME83 defined */



/********************************************************************************/
/*										*/
/*	Papy3AddOwner : this function creates or enlarges the allowed elements	*/
/*	of the shadow-groups that we are able to read				*/
/*	return : always return 0						*/
/*										*/
/********************************************************************************/

PapyShort CALLINGCONV
Papy3AddOwner (PapyShort inFileNb, char *inValueP)
{
  SShadowOwner	 *theShOwP;
  
  
  gNbShadowOwner [inFileNb] ++;
  if (gNbShadowOwner [inFileNb] == 1)			/* first value */
  {
    gShadowOwner [inFileNb] = (SShadowOwner *) emalloc3 ((PapyULong) sizeof (SShadowOwner));
    theShOwP = gShadowOwner [inFileNb];
  } /* then */
  else				/* multiple value => need to be enlarged */
  { 
    gShadowOwner [inFileNb] = (SShadowOwner *) erealloc3 (gShadowOwner [inFileNb], 
    		(PapyULong) ((gNbShadowOwner [inFileNb]) * sizeof (SShadowOwner)),
                (PapyULong) ((gNbShadowOwner [inFileNb] - 1L) * sizeof (SShadowOwner))); /* OLB */
    theShOwP = gShadowOwner [inFileNb] + gNbShadowOwner [inFileNb] - 1;
  } /* else */
  
  theShOwP->str_value = inValueP;
  
  return 0;

} /* endof Papy3AddOwner */
  



/********************************************************************************/
/*									 	*/
/*	Papy3Init : initializes the PAPYRUS toolkit		  		*/
/*	return : always return 0					      	*/
/*									      	*/
/********************************************************************************/

PapyShort CALLINGCONV Papy3Init ()
{
  PapyShort	i;
  
  
  /* test to see wether the toolkit has been initialised or not */
  if  (gIsPapy3Inited == 21) return 0;
  else gIsPapy3Inited = 21;
  
  /* initialize the version number of the PAPYRUS toolkit */
  strcpy (gPapyrusVersion, "3.7");
  
  /* initialize the compatibility flag */
  strcpy (gPapyrusCompatibility, "2");
  
  /* initialize the group numbers and the number of elements in the groups */
  InitGroupNbAndSize3 ();
  
  /* initialize the number of elements in the modules */
  InitModuleSize3 ();

  /* for each kind of data set give the modules and their usage */
  InitDataSetModules3 ();
  
  /* for each modality stores the associated UID */
  InitUIDs3 ();
  
  /* initialize all the labels associated to the module name and their elements */
  InitModulesLabels3 ();
 
/*  Modif DRD  
  gCurrFile = -1; */

  /* initialize some pointers to NULL */
  for (i = 0; i < kMax_file_open; i++) 
  {
	gPapSOPInstanceUID [i] = NULL;
    gCurrTmpFilename	[i] = 1;
    gPapFilename	[i] = NULL;
    gArrMemFile		[i] = NULL;
    gPapyFile		[i] = 0;
    gArrIcons 		[i] = NULL;
    gPatientSummaryItem	[i] = NULL;
    gPtrSequenceItem 	[i] = NULL;
    gImageSequenceItem 	[i] = NULL;
    gArrGroup41		[i] = NULL;
    
    gRefSOPClassUID	[i] = NULL;
    gRefImagePointer	[i] = NULL;
    gRefPixelOffset	[i] = NULL;
    gPosImagePointer	[i] = NULL;
    gPosPixelOffset	[i] = NULL;
    gImageSOPinstUID	[i] = NULL;

    gx0028BitsAllocated [i] = 0;
  } /* for */
  
  gRefSOPInstanceUID	    = NULL;
  gRefImageNb 		    = NULL;
  gRefPixelData		    = NULL;
  
  /* the default size of an icon is 64 */
  Papy3SetIconSize ((PapyUShort) 64);
  
  return 0;
  
 } /* endof Papy3Init */



/********************************************************************************/
/*									 	*/
/*	Dicom2PapyInit : initializes the global values for the format           */
/*                       conversion in the toolkit		                */
/*	return : always return 0					    	*/
/*									      	*/
/********************************************************************************/

PapyShort CALLINGCONV Dicom2PapyInit ()
{
  /* initialize the different conversion factors */
  gCompression        = NONE;
  gCompressionFactor  = 1;
  gZoomFactor         = 1.0;
  gWindowWidth        = 0;
  gWindowLevel        = 0;
  gSubSamplingFactor  = 1.0;

  /* initialize gCropingRect(X1, Y1, X2, Y2)  */
  SetCropingPoints (0.0, 0.0, 1.0, 1.0);

  return 0;
  
} /* endof Dicom2PapyInit */



/******************************************************************************
* Name: SetModality
*
* Purpose: 
******************************************************************************/


enum EModality SetModality (char *modality)
/* CR_IM, CT_IM, MR_IM, NM_IM, US_IM, US_MF_IM, 
   SEC_CAPT_IM, DX_IM, MG_IM, IO_IM, RF_IM, PET_IM, PX_IM, VLE_IM, VLM_IM, VLS_IM,
   VLP_IM, MFSBSC_IM, MFGBSC_IM, MFGWSC_IM, MFTCSC_IM,  END_MODALITY */
{
  if (modality != NULL)
  {    
    switch (modality [0])
    {
      case 'C' :
        switch (modality [1])
        {
          case 'T' : return (CT_IM);
          case 'R' : 
          default  : return (CR_IM);
        }/* switch */
        break;
      case 'D' :
	return (DX_IM);
      case 'E' :
      case 'L' :
	return (CT_IM);
      case 'I' :
	return (IO_IM);
      case 'M' :
        switch (modality [2])
        {
          case 'S' : return (MFSBSC_IM);
          case 'T' : return (MFTCSC_IM);
          case 'G' : 
            switch (modality [3])
            {
              case 'B' : return (MFGBSC_IM);
              case 'W' : return (MFGWSC_IM);
            } /* switch */
            break;
        }/* switch */
	return (MR_IM);
      case 'P' :
        return (PET_IM);
      case 'R' :
        return (RF_IM);
      case 'N' :
      case 'S' : 
	return (NM_IM);
      case 'U' : 
	return (US_IM);
      case 'V' :
        switch (modality [2])
        {
          case 'E' : return (VLE_IM);
          case 'M' : return (VLM_IM);
          case 'S' : return (VLS_IM);
          case 'P' : return (VLP_IM);
        }/* switch */
        break;
      default:
        return (SEC_CAPT_IM);
    } /* switch */
  } /* endif ...there is a modality */

} /* endof SetModality */



/********************************************************************************/
/*									 	*/
/*	SetCompression : 		                                */
/*	return : 					      	*/
/*									      	*/
/********************************************************************************/

void SetCompression (enum EPap_Compression inCompression)
{ 
  
  /* initialize gCompression */
  gCompression = inCompression;
  
  
} /* endof SetCompression */



/********************************************************************************/
/*									 	*/
/*	SetCompressionFactor : 		                                */
/*	return : 					      	*/
/*									      	*/
/********************************************************************************/

void SetCompressionFactor (int inCompressionFactor)
{ 
  
  /* initialize gCompressionFactor */
  gCompressionFactor = inCompressionFactor;
  
  
} /* endof SetCompressionFactor */



/********************************************************************************/
/*									 	*/
/*	SetZoomFactor : 		                                */
/*	return : 					      	*/
/*									      	*/
/********************************************************************************/

void SetZoomFactor (float inZoomFactor)
{ 
  
  /* initialize gZoomFactor */
  gZoomFactor = inZoomFactor;
  
  
} /* endof SetZoomFactor */



/********************************************************************************/
/*									 	*/
/*	SetWindowingValue : 		                                */
/*	return : 					      	*/
/*									      	*/
/********************************************************************************/

void SetWindowingValue (int inWindowLevel, int inWindowWidth)
{ 
  
  /* initialize gWindowWidth and gWindowLevel */
  gWindowWidth = inWindowWidth;
  gWindowLevel = inWindowLevel;
  
  
} /* endof SetWindowingValue */



/********************************************************************************/
/*									 	*/
/*	SetSubSamplingFactor :  	                                */
/*	return : 					      	*/
/*									      	*/
/********************************************************************************/

void SetSubSamplingFactor (float inSubSamplingFactor)
{ 
  
  /* initialize gSubSamplingFactor */
  gSubSamplingFactor = inSubSamplingFactor;
  

} /* endof SetSubSamplingFactor */



/********************************************************************************/
/*									 	*/
/*	SetCropingPoints : 		                                */
/*	return : 					      	*/
/*									      	*/
/********************************************************************************/

void SetCropingPoints (float X1, float Y1, float X2, float Y2)
{ 
  
  /* initialize gCropingPoints */
  gLeftX    = X1;
  gTopY     = Y1;
  gRightX   = X2;
  gBottomY  = Y2;
			

} /* endof SetCropingPoints */


/********************************************************************************/
/*										*/
/*	InitGroupNbAndSize3 : initializes the number and the number of elements */
/*	for each defined group.							*/
/*									      	*/
/********************************************************************************/

void
InitGroupNbAndSize3 ()
{
  /* matching of enum-place and real number of the groups names */

  gArrGroup [(int) Group2].number	= 0x0002;
  gArrGroup [(int) Group2].size		= papEndGroup2;

  gArrGroup [(int) Group4].number	= 0x0004;
  gArrGroup [(int) Group4].size		= papEndGroup4;

  gArrGroup [(int) Group8].number	= 0x0008;
  gArrGroup [(int) Group8].size		= papEndGroup8;

  gArrGroup [(int) Group10].number	= 0x0010;
  gArrGroup [(int) Group10].size	= papEndGroup10;

  gArrGroup [(int) Group18].number	= 0x0018;
  gArrGroup [(int) Group18].size	= papEndGroup18;

  gArrGroup [(int) Group20].number	= 0x0020;
  gArrGroup [(int) Group20].size	= papEndGroup20;

  gArrGroup [(int) Group28].number	= 0x0028;
  gArrGroup [(int) Group28].size	= papEndGroup28;

  gArrGroup [(int) Group32].number	= 0x0032;
  gArrGroup [(int) Group32].size	= papEndGroup32;

  gArrGroup [(int) Group38].number	= 0x0038;
  gArrGroup [(int) Group38].size	= papEndGroup38;

  gArrGroup [(int) Group3A].number	= 0x003A;
  gArrGroup [(int) Group3A].size	= papEndGroup3A;

  gArrGroup [(int) Group40].number	= 0x0040;
  gArrGroup [(int) Group40].size	= papEndGroup40;

  gArrGroup [(int) Group41].number	= 0x0041;
  gArrGroup [(int) Group41].size	= papEndGroup41;

  gArrGroup [(int) Group50].number	= 0x0050;
  gArrGroup [(int) Group50].size	= papEndGroup50;

  gArrGroup [(int) Group54].number	= 0x0054;
  gArrGroup [(int) Group54].size	= papEndGroup54;

  gArrGroup [(int) Group60].number	= 0x0060;
  gArrGroup [(int) Group60].size	= papEndGroup60;

  gArrGroup [(int) Group70].number	= 0x0070;
  gArrGroup [(int) Group70].size	= papEndGroup70;

  gArrGroup [(int) Group88].number	= 0x0088;
  gArrGroup [(int) Group88].size	= papEndGroup88;

  gArrGroup [(int) Group100].number	= 0x00100;
  gArrGroup [(int) Group100].size	= papEndGroup100;

  gArrGroup [(int) Group2000].number	= 0x2000;
  gArrGroup [(int) Group2000].size	= papEndGroup2000;

  gArrGroup [(int) Group2010].number	= 0x2010;
  gArrGroup [(int) Group2010].size	= papEndGroup2010;

  gArrGroup [(int) Group2020].number	= 0x2020;
  gArrGroup [(int) Group2020].size	= papEndGroup2020;

  gArrGroup [(int) Group2030].number	= 0x2030;
  gArrGroup [(int) Group2030].size	= papEndGroup2030;

  gArrGroup [(int) Group2040].number	= 0x2040;
  gArrGroup [(int) Group2040].size	= papEndGroup2040;

  gArrGroup [(int) Group2050].number	= 0x2050;
  gArrGroup [(int) Group2050].size	= papEndGroup2050;

  gArrGroup [(int) Group2100].number	= 0x2100;
  gArrGroup [(int) Group2100].size	= papEndGroup2100;

  gArrGroup [(int) Group2110].number	= 0x2110;
  gArrGroup [(int) Group2110].size	= papEndGroup2110;

  gArrGroup [(int) Group2120].number	= 0x2120;
  gArrGroup [(int) Group2120].size	= papEndGroup2120;

  gArrGroup [(int) Group2130].number	= 0x2130;
  gArrGroup [(int) Group2130].size	= papEndGroup2130;

  gArrGroup [(int) Group3002].number	= 0x3002;
  gArrGroup [(int) Group3002].size	= papEndGroup3002;

  gArrGroup [(int) Group3004].number	= 0x3004;
  gArrGroup [(int) Group3004].size	= papEndGroup3004;

  gArrGroup [(int) Group3006].number	= 0x3006;
  gArrGroup [(int) Group3006].size	= papEndGroup3006;

  gArrGroup [(int) Group3008].number	= 0x3008;
  gArrGroup [(int) Group3008].size	= papEndGroup3008;

  gArrGroup [(int) Group300A].number	= 0x300A;
  gArrGroup [(int) Group300A].size	= papEndGroup300A;

  gArrGroup [(int) Group300C].number	= 0x300C;
  gArrGroup [(int) Group300C].size	= papEndGroup300C;

  gArrGroup [(int) Group300E].number	= 0x300E;
  gArrGroup [(int) Group300E].size	= papEndGroup300E;

  gArrGroup [(int) Group4000].number	= 0x4000;
  gArrGroup [(int) Group4000].size	= papEndGroup4000;

  gArrGroup [(int) Group4008].number	= 0x4008;
  gArrGroup [(int) Group4008].size	= papEndGroup4008;

  gArrGroup [(int) Group5000].number	= 0x5000;
  gArrGroup [(int) Group5000].size	= papEndGroup5000;
  
  gArrGroup [(int) Group5200].number	= 0x5200;
  gArrGroup [(int) Group5200].size	= papEndGroup5200;

  gArrGroup [(int) Group5400].number	= 0x5400;
  gArrGroup [(int) Group5400].size	= papEndGroup5400;

  gArrGroup [(int) Group6000].number	= 0x6000;
  gArrGroup [(int) Group6000].size	= papEndGroup6000;
 
  gArrGroup [(int) UINOVERLAY].number 	= 0x6001;
  gArrGroup [(int) UINOVERLAY].size	= papEndUINOverlay;

  gArrGroup [(int) Group7FE0].number	= 0x7FE0;
  gArrGroup [(int) Group7FE0].size	= papEndGroup7FE0;


} /* endof InitGroupNbAndSize3 */ 



/********************************************************************************/
/*										*/
/*	InitModuleSize3 : initializes the number of element for each defined	*/
/*	module.									*/
/*										*/
/********************************************************************************/

void
InitModuleSize3 ()
{
  
  /* initialization of the modules length */


  gArrModule [(int) AcquisitionContext]			= papEndAcquisitionContext;

  gArrModule [(int) Approval]				= papEndApproval;

  gArrModule [(int) Audio]				= papEndAudio;

  gArrModule [(int) BasicAnnotationPresentation] 	= papEndBasicAnnotationPresentation;

  gArrModule [(int) BasicFilmBoxPresentation]	 	= papEndBasicFilmBoxPresentation;

  gArrModule [(int) BasicFilmBoxRelationship]	 	= papEndBasicFilmBoxRelationship;

  gArrModule [(int) BasicFilmSessionPresentation]	= papEndBasicFilmSessionPresentation;

  gArrModule [(int) BasicFilmSessionRelationship]	= papEndBasicFilmSessionRelationship;

  gArrModule [(int) BiPlaneSequence]    		= papEndBiPlaneSequence;

  gArrModule [(int) BiPlaneImage]       		= papEndBiPlaneImage;

  gArrModule [(int) BiPlaneOverlay]     		= papEndBiPlaneOverlay;

  gArrModule [(int) Cine]				= papEndCine;

  gArrModule [(int) ContrastBolus]			= papEndContrastBolus;

  gArrModule [(int) CRImage]				= papEndCRImage;

  gArrModule [(int) CRSeries]				= papEndCRSeries;

  gArrModule [(int) CTImage]				= papEndCTImage;

  gArrModule [(int) Curve]				= papEndCurve;

  gArrModule [(int) CurveIdentification]		= papEndCurveIdentification;

  gArrModule [(int) Device]	        		= papEndDevice;

  gArrModule [(int) DirectoryInformation]		= papEndDirectoryInformation;

  gArrModule [(int) DisplayShutter]     		= papEndDisplayShutter;

  gArrModule [(int) DXAnatomyImaged]    		= papEndDXAnatomyImaged;

  gArrModule [(int) DXImage]            		= papEndDXImage;

  gArrModule [(int) DXDetector]         		= papEndDXDetector;

  gArrModule [(int) DXPositioning]     		 	= papEndDXPositioning;

  gArrModule [(int) DXSeries]           		= papEndDXSeries;

  gArrModule [(int) ExternalPapyrus_FileReferenceSequence]= papEndExternalPapyrus_FileReferenceSequence;

  gArrModule [(int) ExternalPatientFileReferenceSequence] = papEndExternalPatientFileReferenceSequence;

  gArrModule [(int) ExternalStudyFileReferenceSequence]	= papEndExternalStudyFileReferenceSequence;

  gArrModule [(int) ExternalVisitReferenceSequence] 	= papEndExternalVisitReferenceSequence;

  gArrModule [(int) FileReference]			= papEndFileReference;

  gArrModule [(int) FileSetIdentification] 		= papEndFileSetIdentification;

  gArrModule [(int) FrameOfReference]			= papEndFrameOfReference;

  gArrModule [(int) FramePointers]			= papEndFramePointers;

  gArrModule [(int) GeneralEquipment]			= papEndGeneralEquipment;

  gArrModule [(int) GeneralImage]			= papEndGeneralImage;

  gArrModule [(int) GeneralPatientSummary] 		= papEndGeneralPatientSummary;

  gArrModule [(int) GeneralSeries]			= papEndGeneralSeries;

  gArrModule [(int) GeneralSeriesSummary]		= papEndGeneralSeriesSummary;

  gArrModule [(int) GeneralStudy]			= papEndGeneralStudy;

  gArrModule [(int) GeneralStudySummary]		= papEndGeneralStudySummary;

  gArrModule [(int) GeneralVisitSummary]		= papEndGeneralVisitSummary;

  gArrModule [(int) IconImage]				= papEndIconImage;

  gArrModule [(int) IdentifyingImageSequence]   	= papEndIdentifyingImageSequence;

  gArrModule [(int) ImageBoxPixelPresentation]		= papEndImageBoxPixelPresentation;

  gArrModule [(int) ImageBoxRelationship]		= papEndImageBoxRelationship;

  gArrModule [(int) ImageHistogram]			= papEndImageHistogram;

  gArrModule [(int) ImageIdentification]		= papEndImageIdentification;

  gArrModule [(int) ImageOverlayBoxPresentation]	= papEndImageOverlayBoxPresentation;

  gArrModule [(int) ImageOverlayBoxRelationship]	= papEndImageOverlayBoxRelationship;

  gArrModule [(int) ImagePixel]				= papEndImagePixel;

  gArrModule [(int) ImagePlane]				= papEndImagePlane;

  gArrModule [(int) ImagePointer]			= papEndImagePointer;

  gArrModule [(int) ImageSequencePap]			= papEndImageSequence;

  gArrModule [(int) InternalImagePointerSequence]	= papEndInternalImagePointerSequence;

  gArrModule [(int) InterpretationApproval]      	= papEndInterpretationApproval;
  
  gArrModule [(int) InterpretationIdentification]	= papEndInterpretationIdentification;

  gArrModule [(int) InterpretationRecording]     	= papEndInterpretationRecording;

  gArrModule [(int) InterpretationRelationship]  	= papEndInterpretationRelationship;

  gArrModule [(int) InterpretationState]		= papEndInterpretationState;

  gArrModule [(int) InterpretationTranscription] 	= papEndInterpretationTranscription;

  gArrModule [(int) IntraOralImage]			= papEndIntraOralImage;
  
  gArrModule [(int) IntraOralSeries]			= papEndIntraOralSeries;
  
  gArrModule [(int) LUTIdentification]			= papEndLUTIdentification;
  
  gArrModule [(int) MammographyImage]			= papEndMammographyImage;
  
  gArrModule [(int) MammographySeries]			= papEndMammographySeries;
  
  gArrModule [(int) Mask]	        		= papEndMask;

  gArrModule [(int) ModalityLUT]			= papEndModalityLUT;

  gArrModule [(int) MRImage]	        		= papEndMRImage;

  gArrModule [(int) Multi_frameOverlay]			= papEndMulti_frameOverlay;

  gArrModule [(int) Multi_Frame]			= papEndMulti_Frame;

  gArrModule [(int) NMDetector]  			= papEndNMDetector;

  gArrModule [(int) NMImage]	        		= papEndNMImage;

  gArrModule [(int) NMImagePixel]        		= papEndNMImagePixel;

  gArrModule [(int) NMIsotope]	        		= papEndNMIsotope;

  gArrModule [(int) NMMultiFrame]        		= papEndNMMultiFrame;

  gArrModule [(int) NMMulti_gatedAcquisitionImage]	= papEndNMMulti_gatedAcquisitionImage;

  gArrModule [(int) NMPhase]	        		= papEndNMPhase;

  gArrModule [(int) NMReconstruction]			= papEndNMReconstruction;

  gArrModule [(int) NMSeries]	        		= papEndNMSeries;

  gArrModule [(int) NMTomoAcquisition]   		= papEndNMTomoAcquisition;

  gArrModule [(int) OverlayIdentification] 		= papEndOverlayIdentification;

  gArrModule [(int) OverlayPlane]			= papEndOverlayPlane;

  gArrModule [(int) PaletteColorLookup]  		= papEndPaletteColorLookup;

  gArrModule [(int) PatientDemographic]			= papEndPatientDemographic;

  gArrModule [(int) PatientIdentification] 		= papEndPatientIdentification;

  gArrModule [(int) PatientMedical]			= papEndPatientMedical;

  gArrModule [(int) Patient]				= papEndPatient;

  gArrModule [(int) PatientRelationship]		= papEndPatientRelationship;

  gArrModule [(int) PatientStudy]			= papEndPatientStudy;

  gArrModule [(int) PatientSummary]			= papEndPatientSummary;

  gArrModule [(int) PETCurve]				= papEndPETCurve;

  gArrModule [(int) PETImage]				= papEndPETImage;

  gArrModule [(int) PETIsotope]				= papEndPETIsotope;

  gArrModule [(int) PETMultiGatedAcquisition]		= papEndPETMultiGatedAcquisition;

  gArrModule [(int) PETSeries]				= papEndPETSeries;

  gArrModule [(int) PixelOffset]			= papEndPixelOffset;

  gArrModule [(int) Printer]				= papEndPrinter;

  gArrModule [(int) PrintJob]				= papEndPrintJob;

  gArrModule [(int) ResultIdentification]		= papEndResultIdentification;

  gArrModule [(int) ResultsImpression]			= papEndResultsImpression;

  gArrModule [(int) ResultRelationship]			= papEndResultRelationship;

  gArrModule [(int) RFTomographyAcquisition]		= papEndRFTomographyAcquisition;

  gArrModule [(int) ROIContour]	        		= papEndROIContour;

  gArrModule [(int) RTBeams]	        		= papEndRTBeams;

  gArrModule [(int) RTBrachyApplicationSetups] 		= papEndRTBrachyApplicationSetups;

  gArrModule [(int) RTDose]	        		= papEndRTDose;

  gArrModule [(int) RTDoseROI]	        		= papEndRTDoseROI;

  gArrModule [(int) RTDVH]	        		= papEndRTDVH;

  gArrModule [(int) RTFractionScheme]			= papEndRTFractionScheme;

  gArrModule [(int) RTGeneralPlan]			= papEndRTGeneralPlan;

  gArrModule [(int) RTImage]	        		= papEndRTImage;

  gArrModule [(int) RTPatientSetup]			= papEndRTPatientSetup;

  gArrModule [(int) RTPrescription]			= papEndRTPrescription;

  gArrModule [(int) RTROIObservations]			= papEndRTROIObservations;

  gArrModule [(int) RTSeries]	        		= papEndRTSeries;

  gArrModule [(int) RTToleranceTables]			= papEndRTToleranceTables;

  gArrModule [(int) SCImage]				= papEndSCImage;

  gArrModule [(int) SCImageEquipment]			= papEndSCImageEquipment;

  gArrModule [(int) SCMultiFrameImage]			= papEndSCMultiFrameImage;

  gArrModule [(int) SCMultiFrameVector]			= papEndSCMultiFrameVector;

  gArrModule [(int) SOPCommon]				= papEndSOPCommon;

  gArrModule [(int) SpecimenIdentification]		= papEndSpecimenIdentification;

  gArrModule [(int) StructureSet]			= papEndStructureSet;

  gArrModule [(int) StudyAcquisition]			= papEndStudyAcquisition;

  gArrModule [(int) StudyClassification]		= papEndStudyClassification;

  gArrModule [(int) StudyComponentAcquisition] 		= papEndStudyComponentAcquisition;

  gArrModule [(int) StudyComponent]			= papEndStudyComponent;

  gArrModule [(int) StudyComponentRelationship] 	= papEndStudyComponentRelationship;

  gArrModule [(int) StudyContent]			= papEndStudyContent;

  gArrModule [(int) StudyIdentification]		= papEndStudyIdentification;

  gArrModule [(int) StudyRead]				= papEndStudyRead;

  gArrModule [(int) StudyRelationship]			= papEndStudyRelationship;

  gArrModule [(int) StudyScheduling]			= papEndStudyScheduling;

  gArrModule [(int) Therapy]	        		= papEndTherapy;

  gArrModule [(int) UINOverlaySequence] 		= papEndUINOverlaySequence;
  
  gArrModule [(int) USImage]				= papEndUSImage;

  gArrModule [(int) USFrameofReference]			= papEndUSFrameofReference;

  gArrModule [(int) USRegionCalibration]		= papEndUSRegionCalibration;

  gArrModule [(int) VisitAdmission]			= papEndVisitAdmission;

  gArrModule [(int) VisitDischarge]			= papEndVisitDischarge;

  gArrModule [(int) VisitIdentification]		= papEndVisitIdentification;

  gArrModule [(int) VisitRelationship]			= papEndVisitRelationship;

  gArrModule [(int) VisitScheduling]			= papEndVisitScheduling;

  gArrModule [(int) VisitStatus]			= papEndVisitStatus;

  gArrModule [(int) VLImage]				= papEndVLImage;

  gArrModule [(int) VOILUT]				= papEndVOILUT;
	
  gArrModule [(int) XRayAcquisition]			= papEndXRayAcquisition;

  gArrModule [(int) XRayAcquisitionDose]		= papEndXRayAcquisitionDose;

  gArrModule [(int) XRayCollimator]			= papEndXRayCollimator;

  gArrModule [(int) XRayFiltration]			= papEndXRayFiltration;

  gArrModule [(int) XRayGeneration]			= papEndXRayGeneration;

  gArrModule [(int) XRayGrid]	        		= papEndXRayGrid;

  gArrModule [(int) XRayImage]	        		= papEndXRayImage;

  gArrModule [(int) XRayTable]	        		= papEndXRayTable;

  gArrModule [(int) XRayTomographyAcquisition]		= papEndXRayTomographyAcquisition;

  gArrModule [(int) XRFPositioner]			= papEndXRFPositioner;
  
} /* endof InitModuleSize3 */
  


/********************************************************************************/
/*										*/
/*	InitDataSetModules3 : For each imaging modality give the list of modules*/
/*	associated as well as their usage (M, C, U).				*/
/*									      	*/
/********************************************************************************/

void
InitDataSetModules3 ()
{
  Data_Set	*theWrkP;
  
  
  /* allocate room for storing the modules for each kind of imaging modality */
  gArrModuleNb   [CR_IM] 	= 16;
  gArrModalities [CR_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [CR_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [CT_IM] 	= 14;
  gArrModalities [CT_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [CT_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [MR_IM] 	= 14;
  gArrModalities [MR_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [MR_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [NM_IM] 	= 25;
  gArrModalities [NM_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [NM_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [US_IM] 	= 20;
  gArrModalities [US_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [US_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [US_MF_IM] 	= 20;
  gArrModalities [US_MF_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [US_MF_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [SEC_CAPT_IM] 	= 14;
  gArrModalities [SEC_CAPT_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [SEC_CAPT_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [DX_IM] 	= 31;
  gArrModalities [DX_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [DX_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [MG_IM] 	= 33;
  gArrModalities [MG_IM] 	= (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [MG_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [IO_IM]        = 33;
  gArrModalities [IO_IM]        = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [IO_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [RF_IM]        = 28;
  gArrModalities [RF_IM]        = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [RF_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [PET_IM]       = 18;
  gArrModalities [PET_IM]       = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [PET_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [VLE_IM]       = 12;
  gArrModalities [VLE_IM]       = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [VLE_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [VLM_IM]       = 13;
  gArrModalities [VLM_IM]       = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [VLM_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [VLS_IM]       = 15;
  gArrModalities [VLS_IM]       = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [VLS_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [VLP_IM]       = 13;
  gArrModalities [VLP_IM]       = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [VLP_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [MFSBSC_IM]    = 16;
  gArrModalities [MFSBSC_IM]    = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [MFSBSC_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [MFGBSC_IM]    = 17;
  gArrModalities [MFGBSC_IM]    = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [MFGBSC_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [MFGWSC_IM]    = 17;
  gArrModalities [MFGWSC_IM]    = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [MFGWSC_IM], 
  							 (PapyULong) sizeof (Data_Set));
  gArrModuleNb   [MFTCSC_IM]    = 16;
  gArrModalities [MFTCSC_IM]    = (Data_Set *) ecalloc3 ((PapyULong) gArrModuleNb   [MFTCSC_IM], 
  							 (PapyULong) sizeof (Data_Set));
 
  /* make the list of modules building the CR images */
  theWrkP = gArrModalities [CR_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) CRSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;   /* added for image calibration */
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) CRImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ModalityLUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the CT images */
  theWrkP = gArrModalities [CT_IM];
  theWrkP->moduleName = Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = FrameOfReference;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePlane;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ContrastBolus;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = CTImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the MR images */
  theWrkP = gArrModalities [MR_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) MRImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the NM images */
  theWrkP = gArrModalities [NM_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = M;   
  theWrkP++;
  theWrkP->moduleName = (int) NMMultiFrame;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMIsotope;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMDetector;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMTomoAcquisition;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) NMMulti_gatedAcquisitionImage;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) NMPhase;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) NMReconstruction;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_frameOverlay;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the US images */
  theWrkP = gArrModalities [US_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) USFrameofReference;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PaletteColorLookup;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) USRegionCalibration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) USImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) CurveIdentification;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Audio;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the US_MF images */
  theWrkP = gArrModalities [US_MF_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) USFrameofReference;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Cine;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) USRegionCalibration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) USImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) CurveIdentification;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Audio;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the SEC_CAPT images */
  theWrkP = gArrModalities [SEC_CAPT_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImageEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SCImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ModalityLUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the DX_IM (XRay) images */
  theWrkP = gArrModalities [DX_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SpecimenIdentification;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) DisplayShutter;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Device;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Therapy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayCollimator;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayTomographyAcquisition;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayAcquisitionDose;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayGeneration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayFiltration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayGrid;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) DXAnatomyImaged;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXDetector;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXPositioning;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) ImageHistogram;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;

  /* make the list of modules building the MG_IM (Mammography) images */
  theWrkP = gArrModalities [MG_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SpecimenIdentification;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) MammographySeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) DisplayShutter;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Device;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Therapy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayCollimator;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayTomographyAcquisition;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayAcquisitionDose;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayGeneration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayFiltration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayGrid;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) DXAnatomyImaged;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXDetector;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXPositioning;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) MammographyImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) ImageHistogram;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;

  /* make the list of modules building the (INTRAORALX) IO_IM images */
  theWrkP = gArrModalities [IO_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SpecimenIdentification;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) IntraOralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) DisplayShutter;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Device;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Therapy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayCollimator;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayTomographyAcquisition;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayAcquisitionDose;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayGeneration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayFiltration;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayGrid;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) DXAnatomyImaged;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXDetector;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) DXPositioning;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) IntraOralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) ImageHistogram;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the RF images */
  theWrkP = gArrModalities [RF_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;   /* added for image calibration */
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ContrastBolus;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Cine;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) FramePointers;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Mask;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) DisplayShutter;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Therapy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) XRayAcquisition;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) XRayCollimator;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRayTable;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) XRFPositioner;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) RFTomographyAcquisition;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_frameOverlay;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ModalityLUT;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the PET images */
  theWrkP = gArrModalities [PET_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) NMSeries;	/* is called NM_PETPatientOrientation in the DICOM std */
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PETSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PETIsotope;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PETMultiGatedAcquisition;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) FrameOfReference;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;   /* added for image calibration */
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PETImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) Curve;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Visible Light Endoscopic images */
  theWrkP = gArrModalities [VLE_IM];
  theWrkP->moduleName = Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePlane;	/* added for callibration purpose */
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = VLImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Visible Light Microscopic images */
  theWrkP = gArrModalities [VLM_IM];
  theWrkP->moduleName = Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = SpecimenIdentification;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePlane;	/* added for callibration purpose */
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = VLImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Visible Light Slide Coordinates Microscopic images */
  theWrkP = gArrModalities [VLS_IM];
  theWrkP->moduleName = Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = SpecimenIdentification;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = FrameOfReference;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePlane;	/* added for callibration purpose */
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = VLImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = SlideCoordinates;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Visible Light Photographic images */
  theWrkP = gArrModalities [VLP_IM];
  theWrkP->moduleName = Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = SpecimenIdentification;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePlane;	/* added for callibration purpose */
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = AcquisitionContext;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = VLImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = OverlayPlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Multi_Frame Single Bit SEC_CAPT images */
  theWrkP = gArrModalities [MFSBSC_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImageEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Cine;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FramePointers;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImage;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameVector;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Multi_Frame Grayscale Byte SEC_CAPT images */
  theWrkP = gArrModalities [MFGBSC_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImageEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Cine;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FramePointers;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImage;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameVector;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Multi_Frame Grayscale Word SEC_CAPT images */
  theWrkP = gArrModalities [MFGWSC_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImageEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Cine;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FramePointers;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImage;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameVector;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) VOILUT;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
  /* make the list of modules building the Multi_Frame True Color SEC_CAPT images */
  theWrkP = gArrModalities [MFGWSC_IM];
  theWrkP->moduleName = (int) Patient;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralSeries;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) PatientStudy;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralStudy;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralEquipment;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImageEquipment;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) GeneralImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePlane;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) ImagePixel;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) Cine;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) Multi_Frame;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) FramePointers;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCImage;
  theWrkP->usage = U;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameImage;
  theWrkP->usage = M;
  theWrkP++;
  theWrkP->moduleName = (int) SCMultiFrameVector;
  theWrkP->usage = C;
  theWrkP++;
  theWrkP->moduleName = (int) SOPCommon;
  theWrkP->usage = M;
  
} /* endof InitDataSetModules3 */
  



/********************************************************************************/
/*										*/
/*	InitUIDs3 : For each imaging modality give the associated UID		*/
/*									      	*/
/********************************************************************************/

void
InitUIDs3 ()
{
  PapyShort	i;
  
  /* allocates room for the storage of the UIDs */
  for (i = 0; i < END_MODALITY; i++)
    gArrUIDs [i] = (char *) ecalloc3 ((PapyULong) 30, (PapyULong) sizeof (char));
  
  /* stores the UIDs for each known imaging modality */
  strcpy (gArrUIDs [CR_IM],         "1.2.840.10008.5.1.4.1.1.1"); 
  strcpy (gArrUIDs [CT_IM],         "1.2.840.10008.5.1.4.1.1.2"); 
  strcpy (gArrUIDs [MR_IM],         "1.2.840.10008.5.1.4.1.1.4"); 
  strcpy (gArrUIDs [NM_IM],         "1.2.840.10008.5.1.4.1.1.20"); 
  strcpy (gArrUIDs [US_IM],         "1.2.840.10008.5.1.4.1.1.6.1"); 
  strcpy (gArrUIDs [US_MF_IM],      "1.2.840.10008.5.1.4.1.1.3.1"); 
  strcpy (gArrUIDs [SEC_CAPT_IM],   "1.2.840.10008.5.1.4.1.1.7"); 
  strcpy (gArrUIDs [PX_IM],         "1.2.840.10008.5.1.4.1.1.1.1"); 
  strcpy (gArrUIDs [DX_IM],         "1.2.840.10008.5.1.4.1.1.1.1"); 
  strcpy (gArrUIDs [MG_IM],         "1.2.840.10008.5.1.4.1.1.1.2"); 
  strcpy (gArrUIDs [IO_IM],         "1.2.840.10008.5.1.4.1.1.1.3"); 
  strcpy (gArrUIDs [RF_IM],         "1.2.840.10008.5.1.4.1.1.12.2"); 
  strcpy (gArrUIDs [PET_IM],        "1.2.840.10008.5.1.4.1.1.128"); 
  strcpy (gArrUIDs [VLE_IM],        "1.2.840.10008.5.1.4.1.1.77.1.1"); 
  strcpy (gArrUIDs [VLM_IM],        "1.2.840.10008.5.1.4.1.1.77.1.2"); 
  strcpy (gArrUIDs [VLS_IM],        "1.2.840.10008.5.1.4.1.1.77.1.3"); 
  strcpy (gArrUIDs [VLP_IM],        "1.2.840.10008.5.1.4.1.1.77.1.4"); 
  strcpy (gArrUIDs [MFSBSC_IM],     "1.2.840.10008.5.1.4.1.1.7.1"); 
  strcpy (gArrUIDs [MFGBSC_IM],     "1.2.840.10008.5.1.4.1.1.7.2"); 
  strcpy (gArrUIDs [MFGWSC_IM],     "1.2.840.10008.5.1.4.1.1.7.3"); 
  strcpy (gArrUIDs [MFTCSC_IM],     "1.2.840.10008.5.1.4.1.1.7.4"); 
  
} /* endof InitUIDs3 */
  
 
/********************************************************************************/
/*										*/
/*	Papy3GroupCreate : allocates memory for the elements of the groups 	*/
/* 	return : a pointer to the created group					*/
/*										*/
/********************************************************************************/
 
SElement * CALLINGCONV
Papy3GroupCreate (int inGroupNb)
{
   SElement *theGrP;
   
   
   theGrP = (SElement *) ecalloc3 ((PapyULong) gArrGroup [inGroupNb].size, 
   			      (PapyULong) sizeof (SElement));
   
   (void) InitGroup3 (inGroupNb, theGrP);
   
   return theGrP;
   
} /* endof Papy3GroupCreate */
  
 
/********************************************************************************/
/*										*/
/*	CreateModule3 : allocates memory for the elements of the module and fill*/
/*	in the description of the elements of the module.			*/
/* 	return : a pointer to the created module			 	*/
/*										*/
/********************************************************************************/
 
pModule*
CreateModule3 (int inModuleID)
{
   pModule *theModuleP;
   
   theModuleP = (pModule *) ecalloc3 ((PapyULong) gArrModule [inModuleID], 
   			     	 (PapyULong) sizeof (pModule));
   
   (void) InitModule3 (inModuleID, theModuleP);
   
   return theModuleP;
   
} /* endof CreateModule3 */
  
  

/********************************************************************************/
/*										*/
/*	Papy3ClearElement : Clears an element of a given group or module 	*/
/*	specified by its number						 	*/
/*	The delSeq specifies if the sequence has to be deleted or not		*/
/*	return : return 0 if no error						*/
/*		 standard error message otherwise				*/
/*										*/
/********************************************************************************/
  
PapyShort CALLINGCONV
Papy3ClearElement (SElement *inGrOrModP, PapyShort inElement, int inDelSeq)
{
  SElement	*theElemP;
  UValue_T	*theTmpValP;
  PapyULong	i;
  
  
  theElemP = inGrOrModP + inElement;
  
  if (theElemP->nb_val > 0L)
  {
    theTmpValP = theElemP->value;
    for (i = 0L; i < theElemP->nb_val; i++)
    {
      /*if (theTmpValP == NULL && !(theElemP->group == 0x0041 && 
          (theElemP->inElement == Papy3EnumToElemNb (theElemP, papPointerSequenceGr) ||
           theElemP->inElement == Papy3EnumToElemNb (theElemP, papImageSequenceGr))))*/
      if (theTmpValP == NULL && !(theElemP->group == 0x0041 && 
          (theElemP->element == Papy3EnumToElemNb (theElemP, papPointerSequenceGr) ||
           theElemP->element == Papy3EnumToElemNb (theElemP, papImageSequenceGr)))  &&
          !(theElemP->group == 0x0088 && 
            theElemP->element == Papy3EnumToElemNb (theElemP, papIconImageSequenceGr)))
            RETURN (papProblemInValue);
    
      switch (theElemP->vr)
      {
        case AE :
        case AS :
        case CS :
        case DA :
        case DS :
        case DT :
        case IS :
        case LO :
        case LT :
        case PN :
        case SH :
        case ST :
        case TM :
        case UI :
        case UN :
        case UT :
          if (theTmpValP->a == NULL) 
            break;
          efree3 ((void **) &(theTmpValP->a));
          break;
	      case OB :
	        if (theTmpValP->a == NULL) 
	          break;
	        efree3 ((void **) &(theTmpValP->a));
	        break;
	      case OW :
	        if (theTmpValP->ow == NULL) 
	          break;
          efree3 ((void **) &(theTmpValP->ow));
          /* efree3 ((void **) &theTmpValP); */
	        break;
	      case SQ :
          if ((theTmpValP == NULL || theTmpValP->sq == NULL) && 
              !(theElemP->group == 0x0041 && 
                (theElemP->element == Papy3EnumToElemNb (theElemP, papPointerSequenceGr) ||
                 theElemP->element == Papy3EnumToElemNb (theElemP, papImageSequenceGr))) &&
              !(theElemP->group == 0x0088 && 
                theElemP->element == Papy3EnumToElemNb (theElemP, papIconImageSequenceGr)))
            RETURN (papProblemInValue);
        
	        if (inDelSeq)
	        {
            if (!(theElemP->group == 0x0041 && 
                  (theElemP->element == Papy3EnumToElemNb (theElemP, papPointerSequenceGr) ||
                   theElemP->element == Papy3EnumToElemNb (theElemP, papImageSequenceGr))) &&
                !(theElemP->group == 0x0088 && 
                  theElemP->element == Papy3EnumToElemNb (theElemP, papIconImageSequenceGr)))
	          {
	            /* we have to delete the whole sequence CHG */
	            if (DeleteList (0, &(theTmpValP->sq), TRUE, TRUE, TRUE) < 0) 
                RETURN (papProblemInValue);
	            /*efree3 ((void **) &(theTmpValP->sq));*/
            }
	          else if (theTmpValP != NULL) theTmpValP->sq = NULL;
	        } /* if ...deletes the sequence */
	        else if (theTmpValP != NULL) theTmpValP->sq = NULL;
	          break;
	      default :
	        break;
      } /* switch */

      theTmpValP++;

    } /* for ...loop on the values */
       

    theElemP->nb_val = 0L;
    efree3 ((void **) &(theElemP->value));
    
  } /* if ...nb_val > 0 */
  
  RETURN (papNoError);
  
} /* endof Papy3ClearElement */
  
  
 
/********************************************************************************/
/*										*/
/*	Papy3GroupFree : Frees a previously allocated group			*/
/*	return : standard error message if a problem occur			*/
/*		 zero otherwise 						*/
/*										*/
/********************************************************************************/
  
PapyShort CALLINGCONV
Papy3GroupFree (SElement **ioGroupP, int inDelSeq)
{
    SElement 		*theElemP;
    PapyShort  	theGrSize, i, theErr, theEnumPlace;
    
    
    if (*ioGroupP == NULL) RETURN (papNoError)
    
    if ((*ioGroupP)->group < 0x6000 || (*ioGroupP)->group > 0x6FFF)
    {
      theEnumPlace = Papy3ToEnumGroup ((*ioGroupP)->group);
      if (theEnumPlace < 0) RETURN (theEnumPlace)
      theGrSize = (short) gArrGroup [theEnumPlace].size;
    } /* then */ 
    else
    {
      if ((*ioGroupP)->group % 2 == 0)	     /* group with even group number */
    				      /* overlays groups are from 0x6000 to 0x601E */
        theGrSize = (short) gArrGroup [Group6000].size;
      else		                               /* group with odd group number = shadow group */
      				    /* UINOverlays are from 0x6001 to 0x6FFF */
	      theGrSize = (short) gArrGroup [UINOVERLAY].size;
    } /* else */

    if ((*ioGroupP)->group == 0x5000)
    {
      for (i = 0; i < theGrSize; i++)
        if (i != papCurveDataGr)
        {
          if ((theErr = Papy3ClearElement (*ioGroupP, i, inDelSeq)) < 0) RETURN (theErr);
        } /* if */
        else
        {
          theElemP = *ioGroupP + i;
          if (theElemP->value != NULL)
          {
            switch (theElemP->vr)	/* puts the value of the curve data element */
            {      			/* to NULL but do not free the memory !!!  */
              case OB :
                theElemP->value->a = NULL;
                break;
              case OW :
                theElemP->value->ow = NULL;
                break;
            } /* switch */
      
            efree3 ((void **) &(theElemP->value));
          } /* if ...theElemP->value <> NULL */
        } /* else */
    } /* if ... gropup 0x5000 */
    else if ((*ioGroupP)->group != 0x7FE0) 
    {
      for (i = 0; i < theGrSize; i++)
        if ((theErr = Papy3ClearElement (*ioGroupP, i, inDelSeq)) < 0) RETURN (theErr);
    } /* if ...group not 0x7FE0 */
    else /* group = 7FE0 */
    {
      theErr = Papy3ClearElement (*ioGroupP, 0, TRUE);
      if (theErr < 0) RETURN (theErr)
      
      theElemP = *ioGroupP + 1;
      if (theElemP->value != NULL)
      {
        switch (theElemP->vr)	/* puts the value of the pixel data element */
        {      			/* to NULL but do not free the memory !!!  */
          case OB :
            theElemP->value->a = NULL;
            break;
          case OW :
            theElemP->value->ow = NULL;
            break;
        } /* switch */
      
        efree3 ((void **) &(theElemP->value));
      } /* if ...theElemP->value <> NULL */
    } /* else ... group 7FE0 */
    
    efree3 ((void **) ioGroupP);

    RETURN (papNoError)
    
} /* endof Papy3GroupFree */
  
  
 
/********************************************************************************/
/*										*/
/*	Papy3FreeSQElement : Frees unused SQ from the group			*/
/*	return : standard error message if a problem occur			*/
/*		 zero otherwise 						*/
/*										*/
/********************************************************************************/
  
PapyShort CALLINGCONV
Papy3FreeSQElement (SElement **ioGroupP, pModule *inModuleP, int inModuleID)
{
    int         j, found;
    PapyShort  	theGrSize, i, theErr, theEnumGrNb;
    pModule	    *theElemP;
    SElement    *theArrElemP;


    if (*ioGroupP == NULL) RETURN (papNoError)
    
    if ((*ioGroupP)->group < 0x6000 || (*ioGroupP)->group > 0x6FFF)
    {
      theEnumGrNb = Papy3ToEnumGroup ((*ioGroupP)->group);  /* gr_nb papyrus -> enum */
      if (theEnumGrNb < 0) RETURN (theEnumGrNb)
      theGrSize = (short) gArrGroup [theEnumGrNb].size;
    } /* then */ 
    else
    {
      if ((*ioGroupP)->group % 2 == 0)	     /* group with even group number */
    				/* overlays groups are from 0x6000 to 0x601E */
        theGrSize = (short) gArrGroup [Group6000].size;
      else		                               /* group with odd group number = shadow group */
      			/* UINOverlays are from 0x6001 to 0x6FFF */
	      theGrSize = (short) gArrGroup [UINOVERLAY].size;
    } /* else */

  
    if ((*ioGroupP)->group != 0x7FE0) 
    {
      for (i = 0, theArrElemP = *ioGroupP; i < theGrSize; i++, theArrElemP++)
      {
        found = FALSE;
        if ((theArrElemP->value != NULL)  && (theArrElemP->vr == SQ))
        {
          /* detect now if this sequence exist in the module. If not, delete it */
          theElemP = inModuleP;
        
          /* test each element of the module to see if it belongs to the group */
          for (j = 0; j < gArrModule [inModuleID]; j++, theElemP++)
          {
            /* does the element belongs to the group ? */
            if ((theElemP->group == theArrElemP->group)
                && (theElemP->element == theArrElemP->element))
            {
                found = TRUE;
            } /* if ...the element exists */
          } /* for ...loop on the elements of the module  */
          if (!found)
            if ((theErr = Papy3ClearElement (*ioGroupP, i, TRUE)) < 0) RETURN (theErr);
          /* if ...the element is a SQ */
        } /* if (theValP != NULL) */
      } /* for ...loop on the elements of the group  */     
    } /* if ...group not 0x7FE0 */     
    
    RETURN (papNoError)
    
} /* endof Papy3FreeSQElement */
  
  
 
/********************************************************************************/
/*										*/
/*	Papy3ModuleFree : Frees a previously allocated module.			*/
/*	return : standard error message if a problem occur			*/
/*		 zero otherwise 						*/
/*										*/
/********************************************************************************/
  
PapyShort CALLINGCONV
Papy3ModuleFree (SElement **ioModuleP, int inModuleID, int inDelSeq)
{
    SElement 	*theElemP;
    PapyShort  	theModuleSize, i, theErr;
    
    
    if (*ioModuleP == NULL) RETURN (papNoError);
    
    if (inModuleID < 0) RETURN (papEnumGroup);
    
    theModuleSize = gArrModule [inModuleID];
    if (theModuleSize < 0) RETURN (papGroupErr);
    
    /* free the elements of the module */
    for (i = 0, theElemP = *ioModuleP; i < theModuleSize; i++, theElemP++)
    { 
      if ((inModuleID == ImagePixel    && i == papPixelData)   ||
      	  (inModuleID == IconImage     && i == papPixelDataII) ||
          (inModuleID == Curve         && i == papCurveData)   ||
          (inModuleID == OverlayPlane  && i == papOverlayData)) 
      {
        if (theElemP->value != NULL)
        {
          switch (theElemP->vr)	/* puts the value of the pixel data element */
          {      		/* to NULL but do not free the memory !!!   */
            case OB :
              theElemP->value->a = NULL;
              break;
            case OW :
              theElemP->value->ow = NULL;
              break;
          } /* switch */
      
          efree3 ((void **) &(theElemP->value));
        } /* if ...elem->value <> NULL */
      } /* if ... pixel data */
      
      else if ((theErr = Papy3ClearElement (*ioModuleP, i, inDelSeq)) < 0) RETURN (theErr);
    
    } /* for */  
    
    efree3 ((void **) ioModuleP);

    RETURN (papNoError)
    
} /* endof Papy3ModuleFree */


/********************************************************************************/
/*										*/
/*	Papy3ImageFree : Frees a previously allocated image			*/
/*	return : 0 if OK else standard error message				*/
/*										*/
/********************************************************************************/
  
PapyShort CALLINGCONV
Papy3ImageFree (SElement *inGrOrModP)
{
  PapyShort	theErr = 0;
    
    
  if (inGrOrModP == NULL) RETURN (papGroupErr)

  theErr = Papy3ClearElement (inGrOrModP, papPixelData, TRUE);
    
  RETURN (theErr)
    
} /* endof Papy3ImageFree */


/********************************************************************************/
/*										*/
/*	InitGroup3 : initializes the selected group 				*/
/*										*/
/********************************************************************************/
 
void
InitGroup3 (int inGroupEnum, SElement *ioElemP)
{
  switch (inGroupEnum)
  {
    case Group2 :	
      init_group2 (ioElemP);
      break;
    case Group4 :
      init_group4 (ioElemP);
      break;
    case Group8 :
      init_group8 (ioElemP);
      break;
    case Group10 :
      init_group10 (ioElemP);
      break;
    case Group18 :
      init_group18 (ioElemP);
      break;
    case Group20 :
      init_group20 (ioElemP);
      break;
    case Group28 :
      init_group28 (ioElemP);
      break;
    case Group32 :
      init_group32 (ioElemP);
      break;
    case Group38 :
      init_group38 (ioElemP);
      break;
    case Group3A :
      init_group3A (ioElemP);
      break;
    case Group40 :
      init_group40 (ioElemP);
      break;
    case Group41 :
      init_group41 (ioElemP);
      break;
    case Group50 :
      init_group50 (ioElemP);
      break;
    case Group54 :
      init_group54 (ioElemP);
      break;
    case Group60 :
      init_group60 (ioElemP);
      break;
    case Group70 :
      init_group70 (ioElemP);
      break;
    case Group88 :
      init_group88 (ioElemP);
      break;
    case Group100 :
      init_group100 (ioElemP);
      break;
    case Group2000 :
      init_group2000 (ioElemP);
      break;
    case Group2010 :
      init_group2010 (ioElemP);
      break;
    case Group2020 :
      init_group2020 (ioElemP);
      break;
    case Group2030 :
      init_group2030 (ioElemP);
      break;
    case Group2040 :
      init_group2040 (ioElemP);
      break;
    case Group2050 :
      init_group2050 (ioElemP);
      break;
    case Group2100 :
      init_group2100 (ioElemP);
      break;
    case Group2110 :
      init_group2110 (ioElemP);
      break;
    case Group2120 :
      init_group2120 (ioElemP);
      break;
    case Group2130 :
      init_group2130 (ioElemP);
      break;
    case Group3002 :
      init_group3002 (ioElemP);
      break;
    case Group3004 :
      init_group3004 (ioElemP);
      break;
    case Group3006 :
      init_group3006 (ioElemP);
      break;
    case Group3008 :
      init_group3008 (ioElemP);
      break;
    case Group300A :
      init_group300A (ioElemP);
      break;
    case Group300C :
      init_group300C (ioElemP);
      break;
    case Group300E :
      init_group300E (ioElemP);
      break;
    case Group4000 :
      init_group4000 (ioElemP);
      break;
    case Group4008 :
      init_group4008 (ioElemP);
      break;
    case Group5000 :
      init_group5000 (ioElemP);
      break;
	case Group5200 :
      init_group5200 (ioElemP);
      break;
    case Group5400 :
      init_group5400 (ioElemP);
      break;
    case Group6000 :
      init_group6000 (ioElemP);
      break;
    case Group7FE0 :
      init_group7FE0 (ioElemP);
      break;
    case UINOVERLAY :
      init_uinoverlay (ioElemP);
      break;
    default :
      break;
  } /* end switch */

} /* endof InitGroup3 */


/********************************************************************************/
/*										*/
/*	InitModule3 : initializes the selected module 				*/
/*										*/
/********************************************************************************/
 
void
InitModule3 (int inModuleEnum, SElement *ioElemP)
{
  switch (inModuleEnum)
  {
    case AcquisitionContext :
      init_AcquisitionContext (ioElemP);
      break;
    case Approval :
      init_Approval (ioElemP);
      break;
    case Audio :
      init_Audio (ioElemP);
      break;
    case BasicAnnotationPresentation :
      init_BasicAnnotationPresentation (ioElemP);
      break;
    case BasicFilmBoxPresentation :
      init_BasicFilmBoxPresentation (ioElemP);
      break;
    case BasicFilmBoxRelationship :
      init_BasicFilmBoxRelationship (ioElemP);
      break;
    case BasicFilmSessionPresentation :
      init_BasicFilmSessionPresentation (ioElemP);
      break;
    case BasicFilmSessionRelationship :
      init_BasicFilmSessionRelationship (ioElemP);
      break;
    case BiPlaneImage :
      init_BiPlaneImage (ioElemP);
      break;
    case BiPlaneOverlay :
      init_BiPlaneOverlay (ioElemP);
      break;
    case BiPlaneSequence :
      init_BiPlaneSequence (ioElemP);
      break;
    case Cine :
      init_Cine (ioElemP);
      break;
    case ContrastBolus :
      init_ContrastBolus (ioElemP);
      break;
    case CRImage :
      init_CRImage (ioElemP);
      break;
    case CRSeries :
      init_CRSeries (ioElemP);
      break;
    case CTImage :
      init_CTImage (ioElemP);
      break;
    case Curve :
      init_Curve (ioElemP);
      break;
    case CurveIdentification :
      init_CurveIdentification (ioElemP);
      break;
    case Device :
      init_Device (ioElemP);
      break;
    case DirectoryInformation :
      init_DirectoryInformation (ioElemP);
      break;
    case DisplayShutter :
      init_DisplayShutter (ioElemP);
      break;
    case DXAnatomyImaged :
      init_DXAnatomyImaged (ioElemP);
      break;
    case DXImage :
      init_DXImage (ioElemP);
      break;
    case DXDetector :
      init_DXDetector (ioElemP);
      break;
    case DXPositioning :
      init_DXPositioning (ioElemP);
      break;
    case DXSeries :
      init_DXSeries (ioElemP);
      break;
    case ExternalPapyrus_FileReferenceSequence :
      init_ExternalPapyrus_FileReferenceSequence (ioElemP);
      break;
    case ExternalPatientFileReferenceSequence :
      init_ExternalPatientFileReferenceSequence (ioElemP);
      break;
    case ExternalStudyFileReferenceSequence :
      init_ExternalStudyFileReferenceSequence (ioElemP);
      break;
    case ExternalVisitReferenceSequence :
      init_ExternalVisitReferenceSequence (ioElemP);
      break;
    case FileReference :
      init_FileReference (ioElemP);
      break;
    case FileSetIdentification :
      init_FileSetIdentification (ioElemP);
      break;
    case FrameOfReference :
      init_FrameOfReference (ioElemP);
      break;
    case FramePointers :
      init_FramePointers (ioElemP);
      break;
    case GeneralEquipment :
      init_GeneralEquipment (ioElemP);
      break;
    case GeneralImage :
      init_GeneralImage (ioElemP);
      break;
    case GeneralPatientSummary :
      init_GeneralPatientSummary (ioElemP);
      break;
    case GeneralSeries :
      init_GeneralSeries (ioElemP);
      break;
    case GeneralSeriesSummary :
      init_GeneralSeriesSummary (ioElemP);
      break;
    case GeneralStudy :
      init_GeneralStudy (ioElemP);
      break;
    case GeneralStudySummary :
      init_GeneralStudySummary (ioElemP);
      break;
    case GeneralVisitSummary :
      init_GeneralVisitSummary (ioElemP);
      break;
    case IconImage :
      init_IconImage (ioElemP);
      break;
    case IdentifyingImageSequence :
      init_IdentifyingImageSequence (ioElemP);
      break;
    case ImageBoxPixelPresentation :
      init_ImageBoxPixelPresentation (ioElemP);
      break;
    case ImageBoxRelationship :
      init_ImageBoxRelationship (ioElemP);
      break;
    case ImageHistogram :
      init_ImageHistogram (ioElemP);
      break;
    case ImageIdentification :
      init_ImageIdentification (ioElemP);
      break;
    case ImageOverlayBoxPresentation :
      init_ImageOverlayBoxPresentation (ioElemP);
      break;
    case ImageOverlayBoxRelationship :
      init_ImageOverlayBoxRelationship (ioElemP);
      break;
    case ImagePixel :
      init_ImagePixel (ioElemP);
      break;
    case ImagePlane :
      init_ImagePlane (ioElemP);
      break;
    case ImagePointer :
      init_ImagePointer (ioElemP);
      break;
    case ImageSequencePap :
      init_ImageSequence (ioElemP);
      break;
    case InternalImagePointerSequence :
      init_InternalImagePointerSequence (ioElemP);
      break;
    case InterpretationApproval :
      init_InterpretationApproval (ioElemP);
      break;
    case InterpretationIdentification :
      init_InterpretationIdentification (ioElemP);
      break;
    case InterpretationRecording :
      init_InterpretationRecording (ioElemP);
      break;
    case InterpretationRelationship :
      init_InterpretationRelationship (ioElemP);
      break;
    case InterpretationState :
      init_InterpretationState (ioElemP);
      break;
    case InterpretationTranscription :
      init_InterpretationTranscription (ioElemP);
      break;
    case IntraOralImage :
      init_IntraOralImage (ioElemP);
      break;
    case IntraOralSeries :
      init_IntraOralSeries (ioElemP);
      break;
    case LUTIdentification :
      init_LUTIdentification (ioElemP);
      break;
    case MammographyImage :
      init_MammographyImage (ioElemP);
      break;
    case MammographySeries :
      init_MammographySeries (ioElemP);
      break;
    case Mask :
      init_Mask (ioElemP);
      break;
    case ModalityLUT :
      init_ModalityLUT (ioElemP);
      break;
    case MRImage :
      init_MRImage (ioElemP);
      break;
    case Multi_frameOverlay :
      init_Multi_frameOverlay (ioElemP);
      break;
    case Multi_Frame :
      init_Multi_Frame (ioElemP);
      break;
    case NMDetector :
      init_NMDetector (ioElemP);
      break;
    case NMImage :
      init_NMImage (ioElemP);
      break;
    case NMImagePixel :
      init_NMImagePixel (ioElemP);
      break;
    case NMIsotope :
      init_NMIsotope (ioElemP);
      break;
    case NMMultiFrame :
      init_NMMultiFrame (ioElemP);
      break;
    case NMMulti_gatedAcquisitionImage :
      init_NMMulti_gatedAcquisitionImage (ioElemP);
      break;
    case NMPhase :
      init_NMPhase (ioElemP);
      break;
    case NMReconstruction :
      init_NMReconstruction (ioElemP);
      break;
    case NMSeries :
      init_NMSeries (ioElemP);
      break;
    case NMTomoAcquisition :
      init_NMTomoAcquisition (ioElemP);
      break;
    case OverlayIdentification :
      init_OverlayIdentification (ioElemP);
      break;
    case OverlayPlane :
      init_OverlayPlane (ioElemP);
      break;
    case PaletteColorLookup :
      init_PaletteColorLookup (ioElemP);
      break;
    case PatientDemographic :
      init_PatientDemographic (ioElemP);
      break;
    case PatientIdentification :
      init_PatientIdentification (ioElemP);
      break;
    case PatientMedical :
      init_PatientMedical (ioElemP);
      break;
    case Patient :
      init_Patient (ioElemP);
      break;
    case PatientRelationship :
      init_PatientRelationship (ioElemP);
      break;
    case PatientStudy :
      init_PatientStudy (ioElemP);
      break;
    case PatientSummary :
      init_PatientSummary (ioElemP);
      break;
    case PETCurve :
      init_PETCurve (ioElemP);
      break;
    case PETImage :
      init_PETImage (ioElemP);
      break;
    case PETIsotope :
      init_PETIsotope (ioElemP);
      break;
    case PETMultiGatedAcquisition :
      init_PETMultiGatedAcquisition (ioElemP);
      break;
    case PETSeries :
      init_PETSeries (ioElemP);
      break;
    case PixelOffset :
      init_PixelOffset (ioElemP);
      break;
    case Printer :
      init_Printer (ioElemP);
      break;
    case PrintJob :
      init_PrintJob (ioElemP);
      break;
    case ResultIdentification :
      init_ResultIdentification (ioElemP);
      break;
    case ResultsImpression :
      init_ResultsImpression (ioElemP);
      break;
    case ResultRelationship :
      init_ResultRelationship (ioElemP);
      break;
    case RFTomographyAcquisition :
      init_RFTomographyAcquisition (ioElemP);
      break;
    case ROIContour :
      init_ROIContour (ioElemP);
      break;
    case RTBeams :
      init_RTBeams (ioElemP);
      break;
    case RTBrachyApplicationSetups :
      init_RTBrachyApplicationSetups (ioElemP);
      break;
    case RTDose :
      init_RTDose (ioElemP);
      break;
    case RTDoseROI :
      init_RTDoseROI (ioElemP);
      break;
    case RTDVH :
      init_RTDVH (ioElemP);
      break;
    case RTFractionScheme :
      init_RTFractionScheme (ioElemP);
      break;
    case RTGeneralPlan :
      init_RTGeneralPlan (ioElemP);
      break;
    case RTImage :
      init_RTImage (ioElemP);
      break;
    case RTPatientSetup :
      init_RTPatientSetup (ioElemP);
      break;
    case RTPrescription :
      init_RTPrescription (ioElemP);
      break;
    case RTROIObservations :
      init_RTROIObservations (ioElemP);
      break;
    case RTSeries :
      init_RTSeries (ioElemP);
      break;
    case RTToleranceTables :
      init_RTToleranceTables (ioElemP);
      break;
    case SCImageEquipment :
      init_SCImageEquipment (ioElemP);
      break;
    case SCImage :
      init_SCImage (ioElemP);
      break;
    case SCMultiFrameImage :
      init_SCMultiFrameImage (ioElemP);
      break;
    case SCMultiFrameVector :
      init_SCMultiFrameVector (ioElemP);
      break;
    case SlideCoordinates :
      init_SlideCoordinates (ioElemP);
      break;
    case SOPCommon :
      init_SOPCommon (ioElemP);
      break;
    case SpecimenIdentification :
      init_SpecimenIdentification (ioElemP);
      break;
    case StructureSet :
      init_StructureSet (ioElemP);
      break;
    case StudyAcquisition :
      init_StudyAcquisition (ioElemP);
      break;
    case StudyClassification :
      init_StudyClassification (ioElemP);
      break;
    case StudyComponentAcquisition :
      init_StudyComponentAcquisition (ioElemP);
      break;
    case StudyComponent :
      init_StudyComponent (ioElemP);
      break;
    case StudyComponentRelationship :
      init_StudyComponentRelationship (ioElemP);
      break;
    case StudyContent :
      init_StudyContent (ioElemP);
      break;
    case StudyIdentification :
      init_StudyIdentification (ioElemP);
      break;
    case StudyRead :
      init_StudyRead (ioElemP);
      break;
    case StudyRelationship :
      init_StudyRelationship (ioElemP);
      break;
    case StudyScheduling :
      init_StudyScheduling (ioElemP);
      break;
    case Therapy :
      init_Therapy (ioElemP);
      break;
    case UINOverlaySequence :
      init_UINOverlaySequence (ioElemP);
      break;
    case USImage :
      init_USImage (ioElemP);
      break;
    case USFrameofReference :
      init_USFrameofReference (ioElemP);
      break;
    case USRegionCalibration :
      init_USRegionCalibration (ioElemP);
      break;
    case VisitAdmission :
      init_VisitAdmission (ioElemP);
      break;
    case VisitDischarge :
      init_VisitDischarge (ioElemP);
      break;
    case VisitIdentification :
      init_VisitIdentification (ioElemP);
      break;
    case VisitRelationship :
      init_VisitRelationship (ioElemP);
      break;
    case VisitScheduling :
      init_VisitScheduling (ioElemP);
      break;
    case VisitStatus :
      init_VisitStatus (ioElemP);
      break;
    case VLImage :
      init_VLImage (ioElemP);
      break;
    case VOILUT :
      init_VOILUT (ioElemP);
      break;
    case XRayAcquisition :
      init_XRayAcquisition (ioElemP);
      break;
    case XRayAcquisitionDose :
      init_XRayAcquisitionDose (ioElemP);
      break;
    case XRayCollimator :
      init_XRayCollimator (ioElemP);
      break;
    case XRayFiltration :
      init_XRayFiltration (ioElemP);
      break;
    case XRayGeneration :
      init_XRayGeneration (ioElemP);
      break;
    case XRayGrid :
      init_XRayGrid (ioElemP);
      break;
    case XRayImage :
      init_XRayImage (ioElemP);
      break;
    case XRayTable :
      init_XRayTable (ioElemP);
      break;
    case XRayTomographyAcquisition :
      init_XRayTomographyAcquisition (ioElemP);
      break;
    case XRFPositioner :
      init_XRFPositioner (ioElemP);
      break;
    
    default :
      break;
  } /* end switch */

} /* endof InitModule3 */



/********************************************************************************/
/*										*/
/*	InitModulesLabels3 : initializes the labels for the module names and    */
/*	their elements.							        */
/*										*/
/********************************************************************************/

void 
InitModulesLabels3 ()
{
  /* initialization of the module names */

  sModule_Acquisition_Context        =  "pModule ACQUISITION CONTEXT";
  sModule_Approval                   =  "pModule APPROVAL";
  sModule_Audio                      =  "pModule AUDIO";
  sModule_Basic_Annotation_Presentation =  "pModule BASIC ANNOTATION PRESENTATION";
  sModule_Basic_Film_Box_Presentation   =  "pModule BASIC FILM BOX PRESENTATION";
  sModule_Basic_Film_Box_Relationship   =  "pModule BASIC FILM BOX RELATIONSHIP";
  sModule_Basic_Film_Session_Presentation   =  "pModule BASIC FILM SESSION PRESENTATION";
  sModule_Basic_Film_Session_Relationship   =  "pModule BASIC FILM SESSION RELATIONSHIP";
  sModule_BiPlane_Image              =  "pModule BI-PLANE IMAGE";
  sModule_BiPlane_Overlay            =  "pModule BI-PLANE OVERLAY";
  sModule_BiPlane_Sequence           =  "pModule BI-PLANE Sequence";
  sModule_Cine                       =  "pModule CINE";
  sModule_Contrast_Bolus             =  "pModule CONTRAST BOLUS";
  sModule_CR_Image                   =  "pModule CR IMAGE";
  sModule_CR_Series                  =  "pModule CR SERIES";
  sModule_CT_Image                   =  "pModule CT IMAGE";
  sModule_Curve                      =  "pModule CURVE";
  sModule_Curve_Identification       =  "pModule CURVE IDENTIFICATION";
  sModule_Device                     =  "pModule DEVICE";
  sModule_Directory_Information	    =  "pModule DIRECTORY INFORMATION";
  sModule_Display_Shutter	    =  "pModule DISPLAY SHUTTER";
  sModule_DX_Anatomy_Imaged	    =  "pModule DX ANATOMY IMAGED";
  sModule_DX_Image	            =  "pModule DX IMAGE";
  sModule_DX_Detector	            =  "pModule DX DETECTOR";
  sModule_DX_Positioning	            =  "pModule DX POSITIONING";
  sModule_DX_Series	            =  "pModule DX SERIES";
  sModule_External_Papyrus_File_Reference_Sequence   =  "pModule EXTERNAL PAPYRUS FILE REFERENCE Sequence";
  sModule_External_Patient_File_Reference_Sequence   =  "pModule EXTERNAL PATIENT FILE REFERENCE SEQUENCE";
  sModule_External_Study_File_Reference_Sequence	 =  "pModule EXTERNAL STUDY FILE REFERENCE SEQUENCE";
  sModule_External_Visit_Reference_Sequence	 =  "pModule EXTERNAL VISIT REFERENCE SEQUENCE";
  sModule_File_Reference	            =  "pModule FILE REFERENCE";
  sModule_File_Set_Identification    =  "pModule FILE SET IDENTIFICATION";
  sModule_Frame_Of_Reference         =  "pModule FRAME OF REFERENCE";
  sModule_Frame_Pointers             =  "pModule FRAME POINTERS";
  sModule_General_Equipment          =  "pModule GENERAL EQUIPMENT";
  sModule_General_Image              =  "pModule GENERAL IMAGE";
  sModule_General_Patient_Summary    =  "pModule GENERAL PATIENT SUMMARY";
  sModule_General_Series             =  "pModule GENERAL SERIES";
  sModule_General_Series_Summary     =  "pModule GENERAL SERIES SUMMARY";
  sModule_General_Study              =  "pModule GENERAL STUDY";
  sModule_General_Study_Summary      =  "pModule GENERAL STUDY SUMMARY";
  sModule_General_Visit_Summary      =  "pModule GENERAL VISIT SUMMARY";
  sModule_Icon_Image                 =  "pModule ICON IMAGE";
  sModule_Identifying_Image_Sequence =  "pModule IDENTIFYING IMAGE SEQUENCE";
  sModule_Image_Box_Pixel_Presentation =  "pModule IMAGE BOX PIXEL PRESENTATION";
  sModule_Image_Box_Relationship     =  "pModule IMAGE BOX RELATIONSHIP";
  sModule_Image_Histogram            =  "pModule IMAGE HISTOGRAM";
  sModule_Image_Identification       =  "pModule IMAGE IDENTIFICATION";
  sModule_Image_Overlay_Box_Presentation =  "pModule IMAGE OVERLAY BOX PRESENTATION";
  sModule_Image_Overlay_Box_Relationship =  "pModule IMAGE OVERLAY BOX RELATIONSHIP";
  sModule_Image_Pixel                =  "pModule IMAGE PIXEL";
  sModule_Image_Plane                =  "pModule IMAGE PLANE";
  sModule_Image_Pointer              =  "pModule IMAGE POINTER";
  sModule_Image_Sequence             =  "pModule IMAGE SEQUENCE";
  sModule_Internal_Image_Pointer_Sequence =  "pModule INTERNAL IMAGE POINTER SEQUENCE";
  sModule_Interpretation_Approval    =  "pModule INTERPRETATION APPROVAL";  
  sModule_Interpretation_Identification    =  "pModule INTERPRETATION IDENTIFICATION";  
  sModule_Interpretation_Recording   =  "pModule INTERPRETATION RECORDING";  
  sModule_Interpretation_Relationship    =  "pModule INTERPRETATION RELATIONSHIP";  
  sModule_Interpretation_Transcription   =  "pModule INTERPRETATION TRANSCRIPTION";  
  sModule_Intra_Oral_Image           =  "pModule INTRA-ORAL IMAGE";  
  sModule_Intra_Oral_Series          =  "pModule INTRA-ORAL SERIES";  
  sModule_LUT_Identification         =  "pModule LUT IDENTIFICATION";  
  sModule_Mammography_Image          =  "pModule MAMMOGRAPHY IMAGE";  
  sModule_Mammography_Series         =  "pModule MAMMOGRAPHY SERIES";  
  sModule_Mask                       =  "pModule MASK";
  sModule_Modality_LUT               =  "pModule MODALITY LUT";
  sModule_MR_Image                   =  "pModule MR IMAGE";
  sModule_Multi_Frame                =  "pModule MULTI_FRAME";
  sModule_Multi_frame_Overlay        =  "pModule MULTI_FRAME OVERLAY";
  sModule_NM_Detector                =  "pModule NM DETECTOR";
  sModule_NM_Image                   =  "pModule NM IMAGE";
  sModule_NM_Image_Pixel             =  "pModule NM IMAGE PIXEL";
  sModule_NM_Isotope                 =  "pModule NM ISOTOPE";
  sModule_NM_Multi_Frame             =  "pModule NM MULTI FRAME";
  sModule_NM_Multi_gated_Acquisition_Image =  "pModule NM MULTI_GATED ACQUISITION IMAGE";
  sModule_NM_Phase                   =  "pModule NM PHASE";
  sModule_NM_Reconstruction          =  "pModule NM RECONSTRUCTION";
  sModule_NM_Series                  =  "pModule NM SERIES";
  sModule_NM_Tomo_Acquisition        =  "pModule NM TOMO ACQUISITION";
  sModule_Overlay_Identification     =  "pModule OVERLAY IDENTIFICATION";
  sModule_Overlay_Plane              =  "pModule OVERLAY PLANE";
  sModule_Palette_Color_Lookup       =  "pModule PALETTE COLOR LOOKUP";
  sModule_Patient                    =  "pModule PATIENT";
  sModule_Patient_Demographic        =  "pModule PATIENT DEMOGRAPHIC";
  sModule_Patient_Identification     =  "pModule PATIENT IDENTIFICATION";
  sModule_Patient_Medical            =  "pModule PATIENT MEDICAL";
  sModule_Patient_Relationship       =  "pModule PATIENT RELATIONSHIP";
  sModule_Patient_Study              =  "pModule PATIENT STUDY";
  sModule_Patient_Summary            =  "pModule PATIENT SUMMARY";
  sModule_PET_Curve	             =  "pModule PET CURVE";
  sModule_PET_Image	             =  "pModule PET IMAGE";
  sModule_PET_Isotope	             =  "pModule PET ISOTOPE";
  sModule_PET_Multi_Gated_Acquisition=  "pModule PET MULTI_GATED ACQUISITION";
  sModule_PET_Series	             =  "pModule PET SERIES";
  sModule_Pixel_Offset               =  "pModule PIXEL OFFSET";
  sModule_Printer                    =  "pModule PRINTER";
  sModule_Print_Job                  =  "pModule PRINT JOB";
  sModule_Result_Identification      =  "pModule RESULT IDENTIFICATION";
  sModule_Results_Impression         =  "pModule RESULTS IMPRESSION";
  sModule_Result_Relationship        =  "pModule RESULT RELATIONSHIP";
  sModule_RF_Tomography_Acquisition  =  "pModule RF TOMOGRAPHY ACQUISITION";
  sModule_ROI_Contour                =  "pModule ROI CONTOUR";
  sModule_RT_Beams                   =  "pModule RT BEAMS";
  sModule_RT_Brachy_Application_Setups  =  "pModule RT BRACHY APPLICATION SETUPS";
  sModule_RT_Dose                    =  "pModule RT DOSE";
  sModule_RT_Dose_ROI                =  "pModule RT DOSE ROI";
  sModule_RT_DVH                     =  "pModule RT DVH";
  sModule_RT_Fraction_Scheme         =  "pModule RT FRACTION SCHEME";
  sModule_RT_General_Plan            =  "pModule RT GENERAL PLAN";
  sModule_RT_Image                   =  "pModule RT IMAGE";
  sModule_RT_Patient_Setup           =  "pModule RT PATIENT SETUP";
  sModule_RT_Prescription            =  "pModule RT PRESCRIPTION";
  sModule_RT_ROI_Observations        =  "pModule RT ROI OBSERVATIONS";
  sModule_RT_Series                  =  "pModule RT SERIES";
  sModule_RT_Tolerance_Tables        =  "pModule RT TOLERANCE TABLES";
  sModule_SC_Image                   =  "pModule SC IMAGE";
  sModule_SC_Image_Equipment         =  "pModule SC IMAGE EQUIPMENT";
  sModule_SC_Multi_Frame_Image       =  "pModule SC MULTI_FRAME_IMAGE";
  sModule_SC_Multi_Frame_Vector      =  "pModule SC MULTI_FRAME_VECTOR";
  sModule_Slice_Coordinates	     =  "pModule SLICE COORDINATES";
  sModule_SOP_Common                 =  "pModule SOP COMMON";
  sModule_Specimen_Identification    =  "pModule SPECIMEN IDENTIFICATION";
  sModule_Structure_Set              =  "pModule STRUCTURE SET";
  sModule_Study_Acquisition          =  "pModule STUDY ACQUISITION";
  sModule_Study_Classification       =  "pModule STUDY CLASSIFICATION";
  sModule_Study_Component            =  "pModule STUDY COMPONENT";
  sModule_Study_Component_Acquisition   =  "pModule STUDY COMPONENT ACQUISITION";
  sModule_Study_Component_Relationship  =  "pModule STUDY COMPONENT RELATIONSHIP";
  sModule_Study_Content              =  "pModule STUDY CONTENT";
  sModule_Study_Identification       =  "pModule STUDY IDENTIFICATION";
  sModule_Study_Read                 =  "pModule STUDY READ";
  sModule_Study_Relationship         =  "pModule STUDY RELATIONSHIP";
  sModule_Study_Scheduling           =  "pModule STUDY SCHEDULING";
  sModule_Therapy                    =  "pModule THERAPY";
  sModule_UIN_Overlay_Sequence	     =  "pModule UIN OVERLAY SEQUENCE";
  sModule_US_Frame_of_Reference	     =  "pModule US FRAME OF REFERENCE";
  sModule_US_Image                   =  "pModule US IMAGE";
  sModule_US_Region_Calibration      =  "pModule US REGION CALIBRATION";
  sModule_Visit_Admission            =  "pModule VISIT ADMISSION";
  sModule_Visit_Discharge            =  "pModule VISIT DISCHARGE";
  sModule_Visit_Identification       =  "pModule VISIT IDENTIFICATION";
  sModule_Visit_Relationship         =  "pModule VISIT RELATIONSHIP";
  sModule_Visit_Scheduling           =  "pModule VISIT SCHEDULING";
  sModule_Visit_Status               =  "pModule VISIT STATUS";
  sModule_VL_Image                   =  "pModule VL IMAGE";
  sModule_VOI_LUT                    =  "pModule VOI LUT";
  sModule_XRay_Acquisition           =  "pModule XRAY ACQUISITION";
  sModule_XRay_Acquisition_Dose      =  "pModule XRAY ACQUISITION DOSE";
  sModule_XRay_Collimator            =  "pModule XRAY COLLIMATOR";
  sModule_XRay_Filtration            =  "pModule XRAY FILTRATION";
  sModule_XRay_Generation            =  "pModule XRAY GENERATION";
  sModule_XRay_Grid                  =  "pModule XRAY GRID";
  sModule_XRay_Image                 =  "pModule XRAY IMAGE";
  sModule_XRay_Table                 =  "pModule XRAY TABLE";
  sModule_XRay_Tomography_Acquisition  =  "pModule XRAY TOMOGRAPHY ACQUISITION";
  sModule_XRF_Positioner             =  "pModule XRF POSITIONER";



  /* initialization of the sLabels names */

  /*	pModule : Acquisition Context					*/

  sLabel_Acquisition_Context [ 0 ] = "Acquisition Context Sequence";
  sLabel_Acquisition_Context [ 1 ] = "Acquisition Context Description";
  

  /*	pModule : Audio					*/

  sLabel_Audio [ 0 ] = "Audio Type";
  sLabel_Audio [ 1 ] = "Audio Sample Format";
  sLabel_Audio [ 2 ] = "Number of Channels";
  sLabel_Audio [ 3 ] = "Number of Samples";
  sLabel_Audio [ 4 ] = "Sample Rate";
  sLabel_Audio [ 5 ] = "Total Time";
  sLabel_Audio [ 6 ] = "Audio Sample Data";
  sLabel_Audio [ 7 ] = "Referenced Image Sequence";
  sLabel_Audio [ 8 ] = "Audio Comments";


  /*	pModule : Basic Annotation Presentation					*/

  sLabel_BasicAnnotationPresentation [ 0 ] = "Annotation Position";
  sLabel_BasicAnnotationPresentation [ 1 ] = "Text String";
  
 
  /*	pModule : Basic Film Box Presentation		*/

  /*??????????????????????????*/


  /*	pModule : Basic Film Box Relationship		*/

  /*??????????????????????????*/


  /*	pModule : Basic Film Session Presentation	*/

  /*??????????????????????????*/


  /*	pModule : Basic Film Session Relationship	*/

  /*??????????????????????????*/


  /*	pModule : BiPlane Image				*/

  /*??????????????????????????*/


  /*	pModule : BiPlane Overlay			*/

  /*??????????????????????????*/


  /*	pModule : BiPlane Sequence			*/

  /*??????????????????????????*/


  /*	pModule : Cine					*/

  sLabel_Cine [ 0 ] = "Preferred Playback Sequencing";
  sLabel_Cine [ 1 ] = "Frame Time";
  sLabel_Cine [ 2 ] = "Frame Time Vector";
  sLabel_Cine [ 3 ] = "Start Trim";
  sLabel_Cine [ 4 ] = "Stop Trim";
  sLabel_Cine [ 5 ] = "Recommended Display Frame Rate";
  sLabel_Cine [ 6 ] = "Cine Rate";
  sLabel_Cine [ 7 ] = "Frame Delay";
  sLabel_Cine [ 8 ] = "Effective Duration";
  sLabel_Cine [ 9 ] = "Actual Frame Duration";


  /*	pModule : Contrast Bolus				*/

  sLabel_Contrast_Bolus [ 0 ] = "Contrast/Bolus Agent";
  sLabel_Contrast_Bolus [ 1 ] = "Contrast/Bolus Agent Sequence";
  sLabel_Contrast_Bolus [ 2 ] = "Contrast/Bolus Route";
  sLabel_Contrast_Bolus [ 3 ] = "Contrast/Bolus Administration Route Sequence";
  sLabel_Contrast_Bolus [ 4 ] = "Contrast/Bolus Volume";
  sLabel_Contrast_Bolus [ 5 ] = "Contrast/Bolus Start Time";
  sLabel_Contrast_Bolus [ 6 ] = "Contrast/Bolus Stop Time";
  sLabel_Contrast_Bolus [ 7 ] = "Contrast/Bolus Total Dose";
  sLabel_Contrast_Bolus [ 8 ] = "Contrast Flow Rates";
  sLabel_Contrast_Bolus [ 9 ] = "Contrast Flow Durations";
  sLabel_Contrast_Bolus [ 10 ] = "Contrast/Bolus Ingredient";
  sLabel_Contrast_Bolus [ 11 ] = "Contrast/Bolus Ingredient Concentration";
  

  /*	pModule : CR Image				*/

  sLabel_CR_Image [ 0 ] = "KVP";
  sLabel_CR_Image [ 1 ] = "Plate ID";
  sLabel_CR_Image [ 2 ] = "Distance Source to Detector";
  sLabel_CR_Image [ 3 ] = "Distance Source to Patient";
  sLabel_CR_Image [ 4 ] = "Exposure Time";
  sLabel_CR_Image [ 5 ] = "X-ray Tube Current";
  sLabel_CR_Image [ 6 ] = "Exposure";
  sLabel_CR_Image [ 7 ] = "Generator Power";
  sLabel_CR_Image [ 8 ] = "Acquisition Device Processing Description";
  sLabel_CR_Image [ 9 ] = "Acquisition Device Processing Code";
  sLabel_CR_Image [ 10 ] = "Cassette Orientation";
  sLabel_CR_Image [ 11 ] = "Cassette Size";
  sLabel_CR_Image [ 12 ] = "Exposures on Plate";
  sLabel_CR_Image [ 13 ] = "Relative X-ray Exposure";
  sLabel_CR_Image [ 14 ] = "Sensitivity";


  /*	pModule : CR Series				*/

  sLabel_CR_Series [ 0 ] = "Body Part Examined";
  sLabel_CR_Series [ 1 ] = "View Position";
  sLabel_CR_Series [ 2 ] = "Filter Type";
  sLabel_CR_Series [ 3 ] = "Collimator/grid name";
  sLabel_CR_Series [ 4 ] = "Focal Spot";
  sLabel_CR_Series [ 5 ] = "Plate Type";
  sLabel_CR_Series [ 6 ] = "Phosphor Type";


  /*	pModule : CT Image				*/

  sLabel_CT_Image [ 0 ] = "Image Type";
  sLabel_CT_Image [ 1 ] = "Samples per Pixel";
  sLabel_CT_Image [ 2 ] = "Photometric Interpretation";
  sLabel_CT_Image [ 3 ] = "Bits Allocated";
  sLabel_CT_Image [ 4 ] = "Bits Stored";
  sLabel_CT_Image [ 5 ] = "High Bit";
  sLabel_CT_Image [ 6 ] = "Rescale Intercept";
  sLabel_CT_Image [ 7 ] = "Rescale Slope";
  sLabel_CT_Image [ 8 ] = "KVP";
  sLabel_CT_Image [ 9 ] = "Acquisition Number";
  sLabel_CT_Image [ 10 ] = "Scan Options";
  sLabel_CT_Image [ 11 ] = "Data Collection Diameter";
  sLabel_CT_Image [ 12 ] = "Reconstruction Diameter";
  sLabel_CT_Image [ 13 ] = "Distance Source to Detector";
  sLabel_CT_Image [ 14 ] = "Distance Source to Patient";
  sLabel_CT_Image [ 15 ] = "Gantry/Detector Tilt";
  sLabel_CT_Image [ 16 ] = "Table Height";
  sLabel_CT_Image [ 17 ] = "Rotation Direction";
  sLabel_CT_Image [ 18 ] = "Exposure Time";
  sLabel_CT_Image [ 19 ] = "X-ray Tube Current";
  sLabel_CT_Image [ 20 ] = "Exposure";
  sLabel_CT_Image [ 21 ] = "Filter Type";
  sLabel_CT_Image [ 22 ] = "Generator Power";
  sLabel_CT_Image [ 23 ] = "Focal Spot";
  sLabel_CT_Image [ 24 ] = "Convolution Kernel";


  /*	pModule : Curve					*/

  sLabel_Curve [ 0 ] = "Curve Dimensions";
  sLabel_Curve [ 1 ] = "Number of Points";
  sLabel_Curve [ 2 ] = "Type of Data";
  sLabel_Curve [ 3 ] = "Data Value Representation";
  sLabel_Curve [ 4 ] = "Curve Data";
  sLabel_Curve [ 5 ] = "Curve Description";
  sLabel_Curve [ 6 ] = "Axis Units";
  sLabel_Curve [ 7 ] = "Axis Labels";
  sLabel_Curve [ 8 ] = "Minimum Coordinate Value";
  sLabel_Curve [ 9 ] = "Maximum Coordinate Value";
  sLabel_Curve [ 10 ] = "Curve Range";
  sLabel_Curve [ 11 ] = "Curve Data Descriptor";
  sLabel_Curve [ 12 ] = "Coordinate Start Value";
  sLabel_Curve [ 13 ] = "Coordinate Step Value";
  sLabel_Curve [ 14 ] = "Curve Label";
  sLabel_Curve [ 15 ] = "Referenced Overlay Sequence";


  /*	pModule : Curve Identification			*/

  sLabel_Curve_Identification [ 0 ] = "Curve Number";
  sLabel_Curve_Identification [ 1 ] = "Curve Date";
  sLabel_Curve_Identification [ 2 ] = "Curve Time";
  sLabel_Curve_Identification [ 3 ] = "Referenced Image Sequence";
  sLabel_Curve_Identification [ 4 ] = "Referenced Overlay Sequence";
  sLabel_Curve_Identification [ 5 ] = "Referenced Curve Sequence";

  /*	pModule : Device				        */

  sLabel_Device [ 0 ] = "Device Sequence";


  /*	pModule : Directory Information			*/

  sLabel_Directory_Information [ 0 ] = "Offset of the First Dir Record";
  sLabel_Directory_Information [ 1 ] = "Offset of the Last Dir Record";
  sLabel_Directory_Information [ 2 ] = "File-set consistency Flag";
  sLabel_Directory_Information [ 3 ] = "Directory Record Sequence";

 
  /*	pModule : Display Shutter			*/

  sLabel_Display_Shutter [ 0 ] = "Shutter Shape";
  sLabel_Display_Shutter [ 1 ] = "Shutter Left Vertical Edge";
  sLabel_Display_Shutter [ 2 ] = "Shutter Right Vertical Edge";
  sLabel_Display_Shutter [ 3 ] = "Shutter Upper Horizontal Edge";
  sLabel_Display_Shutter [ 4 ] = "Shutter Lower Horizontal Edge";
  sLabel_Display_Shutter [ 5 ] = "Center of Circular Shutter";
  sLabel_Display_Shutter [ 6 ] = "Radius of Circular Shutter";
  sLabel_Display_Shutter [ 7 ] = "Vertices of the Polygonal Shutter";

 
  /*	pModule : DX Anatomy Imaged			*/

  sLabel_DX_Anatomy_Imaged [ 0 ] = "Image Laterality";
  sLabel_DX_Anatomy_Imaged [ 1 ] = "Anatomic Region Sequence";
  sLabel_DX_Anatomy_Imaged [ 2 ] = "Primary Anatomic Structure Sequence";
  
 
  /*	pModule : DX Detector				*/

  sLabel_DX_Detector [ 0 ] = "Detector Type";
  sLabel_DX_Detector [ 1 ] = "Detector Configuration";
  sLabel_DX_Detector [ 2 ] = "Detector Description";
  sLabel_DX_Detector [ 3 ] = "Detector Mode";
  sLabel_DX_Detector [ 4 ] = "Detector ID";
  sLabel_DX_Detector [ 5 ] = "Date of Last Detector Calibration";
  sLabel_DX_Detector [ 6 ] = "Time of Last Detector Calibration";
  sLabel_DX_Detector [ 7 ] = "Exposures on Detector Since Last Calibration";
  sLabel_DX_Detector [ 8 ] = "Exposures on Detector Since Manufactured";
  sLabel_DX_Detector [ 9 ] = "Detector Time Since Last Exposure";
  sLabel_DX_Detector [ 10 ] = "Detector Active Time";
  sLabel_DX_Detector [ 11 ] = "Detector Activation Offset From Exposure";
  sLabel_DX_Detector [ 12 ] = "Detector Binning";
  sLabel_DX_Detector [ 13 ] = "Detector Conditions Nominal Flag";
  sLabel_DX_Detector [ 14 ] = "Detector Temperature";
  sLabel_DX_Detector [ 15 ] = "Sensitivity";
  sLabel_DX_Detector [ 16 ] = "Field of View Shape";
  sLabel_DX_Detector [ 17 ] = "Field of View Dimensions";
  sLabel_DX_Detector [ 18 ] = "Field of View Origin";
  sLabel_DX_Detector [ 19 ] = "Field of View Rotation";
  sLabel_DX_Detector [ 20 ] = "Field of View Horizontal Flip";
  sLabel_DX_Detector [ 21 ] = "Imager Pixel Spacing";
  sLabel_DX_Detector [ 22 ] = "Detector Element Physical Size";
  sLabel_DX_Detector [ 23 ] = "Detector Element Spacing";
  sLabel_DX_Detector [ 24 ] = "Detector Active Shape";
  sLabel_DX_Detector [ 25 ] = "Detector Active Dimensions";
  sLabel_DX_Detector [ 26 ] = "Detector Active Origin";
  

  /*	pModule : DX Image				*/

  sLabel_DX_Image [ 0 ] = "Image Type";
  sLabel_DX_Image [ 1 ] = "Samples per Pixel";
  sLabel_DX_Image [ 2 ] = "Photometric Interpretation";
  sLabel_DX_Image [ 3 ] = "Bits Allocated";
  sLabel_DX_Image [ 4 ] = "Bits Stored";
  sLabel_DX_Image [ 5 ] = "High Bit";
  sLabel_DX_Image [ 6 ] = "Pixel Representation";
  sLabel_DX_Image [ 7 ] = "Pixel Intensity Relationship";
  sLabel_DX_Image [ 8 ] = "Pixel Intensity Relationship Sign";
  sLabel_DX_Image [ 9 ] = "Rescale Intercept";
  sLabel_DX_Image [ 10 ] = "Rescale Slope";
  sLabel_DX_Image [ 11 ] = "Rescale Type";
  sLabel_DX_Image [ 12 ] = "Presentation LUT Shape";
  sLabel_DX_Image [ 13 ] = "Lossy Image Compression";
  sLabel_DX_Image [ 14 ] = "Lossy Image Compression Ratio";
  sLabel_DX_Image [ 15 ] = "Derivation Description";
  sLabel_DX_Image [ 16 ] = "Acquisition Device Processing Description";
  sLabel_DX_Image [ 17 ] = "Acquisition Device Processing Code";
  sLabel_DX_Image [ 18 ] = "Patient Orientation";
  sLabel_DX_Image [ 19 ] = "CalibrationpObjectt";
  sLabel_DX_Image [ 20 ] = "Burned In Annotation";


  /*	pModule : DX Positioning				*/

  sLabel_DX_Positioning [ 0 ] = "Projection Eponymous Name Code Sequence";
  sLabel_DX_Positioning [ 1 ] = "Patient Position";
  sLabel_DX_Positioning [ 2 ] = "View Position";
  sLabel_DX_Positioning [ 3 ] = "View Code Sequence";
  sLabel_DX_Positioning [ 4 ] = "View Modifier Code Sequence";
  sLabel_DX_Positioning [ 5 ] = "Patient Orientation Code Sequence";
  sLabel_DX_Positioning [ 6 ] = "Patient Orientation Modifier Code Sequence";
  sLabel_DX_Positioning [ 7 ] = "Patient Gantry Relationship Code Sequence";
  sLabel_DX_Positioning [ 8 ] = "Distance Source to Patient";
  sLabel_DX_Positioning [ 9 ] = "Distance Source to Detector";
  sLabel_DX_Positioning [ 10 ] = "Estimated Radiographic Magnification Factor";
  sLabel_DX_Positioning [ 11 ] = "Positioner Type";
  sLabel_DX_Positioning [ 12 ] = "Positioner Primary Angle";
  sLabel_DX_Positioning [ 13 ] = "Positioner Secondary Angle";
  sLabel_DX_Positioning [ 14 ] = "Detector Primary Angle";
  sLabel_DX_Positioning [ 15 ] = "Detector Secondary Angle";
  sLabel_DX_Positioning [ 16 ] = "Column Angulation";
  sLabel_DX_Positioning [ 17 ] = "Table Type";
  sLabel_DX_Positioning [ 18 ] = "Table Angle";
  sLabel_DX_Positioning [ 19 ] = "Body Part Thickness";
  sLabel_DX_Positioning [ 20 ] = "Compression Force";

  

  /*	pModule : DX Series				*/

  sLabel_DX_Series [ 0 ] = "Modality";
  sLabel_DX_Series [ 1 ] = "Referenced Study Component Sequence";
  sLabel_DX_Series [ 2 ] = "Presentation Indent Type";
  

  /*	pModule : External Papyrus_File Reference Sequence*/
  
  /*??????????????????????????*/


  /*	pModule : External Patient File Reference Sequence*/
   
  /*??????????????????????????*/


  /*	pModule : External Study File Reference Sequence	*/
  
  /*??????????????????????????*/


  /*	pModule : External Visit Reference Sequence	*/
  
  /*??????????????????????????*/


  /*	pModule : File Reference				*/

  /*??????????????????????????*/

  
  /*	pModule : File Set Identification		*/

  sLabel_File_Set_Identification [ 0 ] = "File-set ID";
  sLabel_File_Set_Identification [ 1 ] = "File ID of File-set Descriptor";
  sLabel_File_Set_Identification [ 2 ] = "Format of the File-set Descriptor File";


  /*	pModule : Frame Of Reference			*/

  sLabel_Frame_Of_Reference [ 0 ] = "Frame of Reference UID";
  sLabel_Frame_Of_Reference [ 1 ] = "Position Reference Indicator";


  /*	pModule : Frame Pointers				*/

  /*??????????????????????????*/

  
  /*	pModule : General Equipment			*/

  sLabel_General_Equipment [ 0 ] = "Manufacturer";
  sLabel_General_Equipment [ 1 ] = "Institution Name";
  sLabel_General_Equipment [ 2 ] = "Institution Address";
  sLabel_General_Equipment [ 3 ] = "Station Name";
  sLabel_General_Equipment [ 4 ] = "Institutional Department Name";
  sLabel_General_Equipment [ 5 ] = "Manufacturer's Model Name";
  sLabel_General_Equipment [ 6 ] = "Device Serial Number";
  sLabel_General_Equipment [ 7 ] = "Software Versions";
  sLabel_General_Equipment [ 8 ] = "Spatial Resolution";
  sLabel_General_Equipment [ 9 ] = "Date of Last Calibration";
  sLabel_General_Equipment [ 10 ] = "Time of Last Calibration";
  sLabel_General_Equipment [ 11 ] = "Pixel Padding Value";


  /*	pModule : General Image				*/

  sLabel_General_Image [ 0 ] = "Image Number";
  sLabel_General_Image [ 1 ] = "Patient Orientation";
  sLabel_General_Image [ 2 ] = "Image Date";
  sLabel_General_Image [ 3 ] = "Image Time";
  sLabel_General_Image [ 4 ] = "Image Type";
  sLabel_General_Image [ 5 ] = "Acquisition Number";
  sLabel_General_Image [ 6 ] = "Acquisition Date";
  sLabel_General_Image [ 7 ] = "Acquisition Time";
  sLabel_General_Image [ 8 ] = "Referenced Image Sequence";
  sLabel_General_Image [ 9 ] = "Derivation Description";
  sLabel_General_Image [ 10 ] = "Source Image Sequence";
  sLabel_General_Image [ 11 ] = "Images in Acquisition";
  sLabel_General_Image [ 12 ] = "Image Comments";
  sLabel_General_Image [ 13 ] = "Lossy Image Compression";


  /*	pModule : General Patient Summary		*/

  /*??????????????????????????*/


  /*	pModule : General Series				*/

  sLabel_General_Series [ 0 ] = "Modality";
  sLabel_General_Series [ 1 ] = "Series Instance UID";
  sLabel_General_Series [ 2 ] = "Series Number";
  sLabel_General_Series [ 3 ] = "Laterality";
  sLabel_General_Series [ 4 ] = "Series Date";
  sLabel_General_Series [ 5 ] = "Series Time";
  sLabel_General_Series [ 6 ] = "Performing Physicians Name";
  sLabel_General_Series [ 7 ] = "Protocol Name";
  sLabel_General_Series [ 8 ] = "Series Description";
  sLabel_General_Series [ 9 ] = "Operators' Name";
  sLabel_General_Series [ 10 ] = "Referenced Study Component Sequence";
  sLabel_General_Series [ 11 ] = "Body Part Examined";
  sLabel_General_Series [ 12 ] = "Patient Position";
  sLabel_General_Series [ 13 ] = "Smallest Pixel Value in Series";
  sLabel_General_Series [ 14 ] = "Largest Pixel Value in Series";

  
  /*	pModule : General Series Summary			*/

  /*??????????????????????????*/


  /*	pModule : General Study				*/

  sLabel_General_Study [ 0 ] = "Study Instance UID" ;
  sLabel_General_Study [ 1 ] = "Study Date" ;
  sLabel_General_Study [ 2 ] = "Study Time" ;
  sLabel_General_Study [ 3 ] = "Referring Physician's Name" ;
  sLabel_General_Study [ 4 ] = "Study ID" ;
  sLabel_General_Study [ 5 ] = "Accession Number" ;
  sLabel_General_Study [ 6 ] = "Study Description" ;
  sLabel_General_Study [ 7 ] = "Physicians Of Record" ;
  sLabel_General_Study [ 8 ] = "Name of  Physician(s) Reading Study" ;
  sLabel_General_Study [ 9 ] = "Referenced Study Sequence" ;

  
  /*	pModule : General Study Summary			*/

  /*??????????????????????????*/


  /*	pModule : General Visit Summary			*/

  /*??????????????????????????*/


  /*	pModule : Icon Image				*/

  sLabel_Icon_Image [ 0 ] = "Samples per Pixel";
  sLabel_Icon_Image [ 1 ] = "Photometric Interpretation";
  sLabel_Icon_Image [ 2 ] = "Rows";
  sLabel_Icon_Image [ 3 ] = "Columns";
  sLabel_Icon_Image [ 4 ] = "Bits Allocated";
  sLabel_Icon_Image [ 5 ] = "Bits Stored";
  sLabel_Icon_Image [ 6 ] = "High Bit";
  sLabel_Icon_Image [ 7 ] = "Pixel Representation";
  sLabel_Icon_Image [ 8 ] = "Red Palette Color Lookup Table Descriptors";
  sLabel_Icon_Image [ 9 ] = "Green Palette Color Lookup Table Descriptors";
  sLabel_Icon_Image [ 10 ] = "Blue Palette Color Lookup Table Descriptors";
  sLabel_Icon_Image [ 11 ] = "Red Palette Color Lookup Table Data";
  sLabel_Icon_Image [ 12 ] = "Green Palette Color Lookup Table Data";
  sLabel_Icon_Image [ 13 ] = "Blue Palette Color Lookup Table Data";
  sLabel_Icon_Image [ 14 ] = "Pixel Data";

  

  /*	pModule : Identifying Image Sequence		*/
  
  /*??????????????????????????*/


  /*	pModule : Image Box Pixel Presentation		*/
  
  /*??????????????????????????*/


  /*	pModule : Image Box Relationship			*/

  /*??????????????????????????*/


  /*	pModule : Image Identification			*/

  /*??????????????????????????*/


  /*	pModule : Image Overlay Box Presentation		*/

  /*??????????????????????????*/


  /*	pModule : Image Overlay Box Relationship		*/

  /*??????????????????????????*/


  /*	pModule : Image Pixel				*/

  sLabel_Image_Pixel [ 0 ] = "Samples per Pixel";
  sLabel_Image_Pixel [ 1 ] = "Photometric Interpretation";
  sLabel_Image_Pixel [ 2 ] = "Rows";
  sLabel_Image_Pixel [ 3 ] = "Columns";
  sLabel_Image_Pixel [ 4 ] = "Bits Allocated";
  sLabel_Image_Pixel [ 5 ] = "Bits Stored";
  sLabel_Image_Pixel [ 6 ] = "High Bit";
  sLabel_Image_Pixel [ 7 ] = "Pixel Representation";
  sLabel_Image_Pixel [ 8 ] = "Pixel Data";
  sLabel_Image_Pixel [ 9 ] = "Planar Configuration";
  sLabel_Image_Pixel [ 10 ] = "Pixel Aspect Ratio";
  sLabel_Image_Pixel [ 11 ] = "Smallest Image Pixel Value";
  sLabel_Image_Pixel [ 12 ] = "Largest Image Pixel Value";
  sLabel_Image_Pixel [ 13 ] = "Red Palette Color Lookup Table Descriptor";
  sLabel_Image_Pixel [ 14 ] = "Green Palette Color Lookup Table Descriptor";
  sLabel_Image_Pixel [ 15 ] = "Blue Palette Color Lookup Table Descriptor";
  sLabel_Image_Pixel [ 16 ] = "Red Palette Color Lookup Table Data";
  sLabel_Image_Pixel [ 17 ] = "Green Palette Color Lookup Table Data";
  sLabel_Image_Pixel [ 18 ] = "Blue Palette Color Lookup Table Data";


  /*	pModule : Image Plane				*/

  sLabel_Image_Plane [ 0 ] = "Pixel Spacing";
  sLabel_Image_Plane [ 1 ] = "Image Orientation(Patient)";
  sLabel_Image_Plane [ 2 ] = "Image Position(Patient)";
  sLabel_Image_Plane [ 3 ] = "Slice Thickness";
  sLabel_Image_Plane [ 4 ] = "Slice Location";


  /*	pModule : Image Pointer				*/

  /*??????????????????????????*/


  /*	pModule : Image Sequence				*/

  /*??????????????????????????*/


  /*	pModule : Internal Image Pointer Sequence	*/

  /*??????????????????????????*/


  /*	pModule : Interpretation Approval		*/

  /*??????????????????????????*/


  /*	pModule : Interpretation Identification		*/

  /*??????????????????????????*/


  /*	pModule : Interpretation Recording		*/

  /*??????????????????????????*/


  /*	pModule : Interpretation Relationship		*/

  /*??????????????????????????*/


  /*	pModule : Interpretation State			*/

  /*??????????????????????????*/


  /*	pModule : Interpretation Transcription		*/

  /*??????????????????????????*/

  
  /*	pModule : Intra_Oral Image			*/

  sLabel_Intra_Oral_Image [ 0 ] = "Positioner Type";
  sLabel_Intra_Oral_Image [ 1 ] = "Image Laterality";
  sLabel_Intra_Oral_Image [ 2 ] = "Anatomic Region Sequence";
  sLabel_Intra_Oral_Image [ 3 ] = "Anatomic Region Modifier Sequence";
  sLabel_Intra_Oral_Image [ 4 ] = "Primary Anatomic Structure Sequence";
  
  
  /*	pModule : Intra_Oral Series			*/

  sLabel_Intra_Oral_Series [ 0 ] = "Modality";
  
  
  /*	pModule : LUT Identification			*/

  /*??????????????????????????*/


  /*	pModule : Mammography Image			*/

  sLabel_Mammography_Image [ 0 ] = "Positioner Type";
  sLabel_Mammography_Image [ 1 ] = "Positioner Primary Angle";
  sLabel_Mammography_Image [ 2 ] = "Positioner Secondary Angle";
  sLabel_Mammography_Image [ 3 ] = "Image Laterality";
  sLabel_Mammography_Image [ 4 ] = "Organ Exposed";
  sLabel_Mammography_Image [ 5 ] = "Anatomic Region Sequence";
  sLabel_Mammography_Image [ 6 ] = "View Code Sequence";
  sLabel_Mammography_Image [ 7 ] = "View Modifier Code Sequence";


  /*	pModule : Mammography Series			*/

  sLabel_Mammography_Series [ 0 ] = "Modality";
  

  /*	pModule : Mask				        */

  sLabel_Mask [ 0 ] = "Mask Subtraction Sequence";
  sLabel_Mask [ 1 ] = "Recommended Viewing Mode";



  /*	pModule : Modality LUT				*/

  sLabel_Modality_LUT [ 0 ] = "Modality LUT Sequence";
  sLabel_Modality_LUT [ 1 ] = "Rescale Intercept";
  sLabel_Modality_LUT [ 2 ] = "Rescale Slope";
  sLabel_Modality_LUT [ 3 ] = "Rescale Type";

  /*  sLabel_Modality_LUT [  ] = "LUT Descriptor";
  sLabel_Modality_LUT [  ] = "LUT Explanation";
  sLabel_Modality_LUT [  ] = "Modality LUT Type";
  sLabel_Modality_LUT [  ] = "LUT Data";*/


  /*	pModule : MR Image				*/

  sLabel_MR_Image [ 0 ] = "Image Type";
  sLabel_MR_Image [ 1 ] = "Samples per Pixel";
  sLabel_MR_Image [ 2 ] = "Photometric Interpretation";
  sLabel_MR_Image [ 3 ] = "Bits Allocated";
  sLabel_MR_Image [ 4 ] = "Scanning Sequence";
  sLabel_MR_Image [ 5 ] = "Sequence Variant";
  sLabel_MR_Image [ 6 ] = "Scan Options";
  sLabel_MR_Image [ 7 ] = "MR Acquisition Type";
  sLabel_MR_Image [ 8 ] = "Repetition Time";
  sLabel_MR_Image [ 9 ] = "Echo Time";
  sLabel_MR_Image [ 10 ] = "Echo Train Length";
  sLabel_MR_Image [ 11 ] = "Inversion Time";
  sLabel_MR_Image [ 12 ] = "Trigger Time";
  sLabel_MR_Image [ 13 ] = "Sequence Name";
  sLabel_MR_Image [ 14 ] = "Angio Flag";
  sLabel_MR_Image [ 15 ] = "Number of Averages";
  sLabel_MR_Image [ 16 ] = "Imaging Frequency";
  sLabel_MR_Image [ 17 ] = "Imaged Nucleus";
  sLabel_MR_Image [ 18 ] = "Echo Number";
  sLabel_MR_Image [ 19 ] = "Magnetic Field Strength";
  sLabel_MR_Image [ 20 ] = "Spacing Between Slices";
  sLabel_MR_Image [ 21 ] = "Number of Phase Encoding Steps";
  sLabel_MR_Image [ 22 ] = "Percent Sampling";
  sLabel_MR_Image [ 23 ] = "Percent Phase Field of View";
  sLabel_MR_Image [ 24 ] = "Pixel Bandwidth";
  sLabel_MR_Image [ 25 ] = "Nominal Interval";
  sLabel_MR_Image [ 26 ] = "Beat Rejection Flag";
  sLabel_MR_Image [ 27 ] = "Low R-R Value";
  sLabel_MR_Image [ 28 ] = "High R-R Value";
  sLabel_MR_Image [ 29 ] = "Intervals Acquired";
  sLabel_MR_Image [ 30 ] = "Intervals Rejected";
  sLabel_MR_Image [ 31 ] = "PVC Rejection";
  sLabel_MR_Image [ 32 ] = "Skip Beats";
  sLabel_MR_Image [ 33 ] = "Heart Rate";
  sLabel_MR_Image [ 34 ] = "Cardiac Number of Images";
  sLabel_MR_Image [ 35 ] = "Trigger Window";
  sLabel_MR_Image [ 36 ] = "Reconstruction Diameter";
  sLabel_MR_Image [ 37 ] = "Receiving Coil";
  sLabel_MR_Image [ 38 ] = "Transmitting Coil";
  sLabel_MR_Image [ 39 ] = "Acquisition Matrix";
  sLabel_MR_Image [ 40 ] = "Phase Encoding Direction";
  sLabel_MR_Image [ 41 ] = "Flip Angle";
  sLabel_MR_Image [ 42 ] = "SAR";
  sLabel_MR_Image [ 43 ] = "Variable Flip Angle Flag";
  sLabel_MR_Image [ 44 ] = "dB/dt";
  sLabel_MR_Image [ 45 ] = "Temporal Position Identifier";
  sLabel_MR_Image [ 46 ] = "Number of Temporal Positions";
  sLabel_MR_Image [ 47 ] = "Temporal Resolution";



  /*	pModule : Multi_Frame				*/

  sLabel_Multi_Frame [ 0 ] = "Number of Frames";
  sLabel_Multi_Frame [ 1 ] = "Frame Increment Pointer";


  /*	pModule : Multi_frame Overlay			*/

  sLabel_Multi_frame_Overlay [ 0 ] = "Number of Frames in Overlay";
  sLabel_Multi_frame_Overlay [ 1 ] = "Image Frame Origin";


  /*	pModule : NM Detector				*/

  sLabel_NM_Detector [ 0 ] = "Detector Information Sequence";
 

  /*	pModule : NM Image				*/
  
  sLabel_NM_Image [ 0 ] = "Image Type";
  sLabel_NM_Image [ 1 ] = "Image ID";
  sLabel_NM_Image [ 2 ] = "Lossy Image Compression";
  sLabel_NM_Image [ 3 ] = "Counts Accumulated";
  sLabel_NM_Image [ 4 ] = "Acquisition Termination Condition";
  sLabel_NM_Image [ 5 ] = "Table Height";
  sLabel_NM_Image [ 6 ] = "Reconstruction Diameter";
  sLabel_NM_Image [ 7 ] = "Distance Source to Detector";
  sLabel_NM_Image [ 8 ] = "Table Height";
  sLabel_NM_Image [ 9 ] = "Table Traverse";
  sLabel_NM_Image [ 10 ] = "Actual Frame Duration";
  sLabel_NM_Image [ 11 ] = "Count Rate";
  sLabel_NM_Image [ 12 ] = "Preprocessing Function";
  sLabel_NM_Image [ 13 ] = "Corrected Image";
  sLabel_NM_Image [ 14 ] = "Whole Body Technique";
  sLabel_NM_Image [ 15 ] = "Scan Velocity";
  sLabel_NM_Image [ 16 ] = "Scan Length";
  sLabel_NM_Image [ 17 ] = "Referenced Overlay Sequence";
  sLabel_NM_Image [ 18 ] = "Referenced Curve Sequence";
  sLabel_NM_Image [ 19 ] = "Trigger Source or Type";
  sLabel_NM_Image [ 20 ] = "Anatomic Region Sequence";
  sLabel_NM_Image [ 21 ] = "Primary Anatomic Structure Sequence";

  /*  sLabel_NM_Image [  ] = "Referenced SOP Class UID";
  sLabel_NM_Image [  ] = "Referenced SOP Instance UID";*/

  /*  sLabel_NM_Image [  ] = "Referenced SOP Class UID";
  sLabel_NM_Image [  ] = "Referenced SOP Instance UID";*/


  /*	pModule : NM Image Pixel				*/

  sLabel_NM_Image_Pixel [ 0 ] = "Samples per Pixel";
  sLabel_NM_Image_Pixel [ 1 ] = "Photometric Interpretation";
  sLabel_NM_Image_Pixel [ 2 ] = "Bits Allocated";
  sLabel_NM_Image_Pixel [ 3 ] = "Bits Stored";
  sLabel_NM_Image_Pixel [ 4 ] = "High Bit";
  sLabel_NM_Image_Pixel [ 5 ] = "Pixel Spacing";


  /*	pModule : NM Isotope		                */

  sLabel_NM_Isotope [ 0 ] = "Energy Window Information Sequence";
  sLabel_NM_Isotope [ 1 ] = "Radiopharmaceutical Information Sequence";
  sLabel_NM_Isotope [ 2 ] = "Intervention Drug Information Sequence";


  /*	pModule : NM Multi Frame				*/

  sLabel_NM_Multi_Frame [ 0 ] = "Frame Increment Pointer";
  sLabel_NM_Multi_Frame [ 1 ] = "Energy Window Vector";
  sLabel_NM_Multi_Frame [ 2 ] = "Number of Energy Windows";
  sLabel_NM_Multi_Frame [ 3 ] = "Detector Vector";
  sLabel_NM_Multi_Frame [ 4 ] = "Number of Detectors";
  sLabel_NM_Multi_Frame [ 5 ] = "Phase Vector";
  sLabel_NM_Multi_Frame [ 6 ] = "Number of Phases";
  sLabel_NM_Multi_Frame [ 7 ] = "Rotation Vector";
  sLabel_NM_Multi_Frame [ 8 ] = "Number of Rotations";
  sLabel_NM_Multi_Frame [ 9 ] = "RR Interval Vector";
  sLabel_NM_Multi_Frame [ 10 ] = "Number of RR Intervals";
  sLabel_NM_Multi_Frame [ 11 ] = "Time Slot Vector";
  sLabel_NM_Multi_Frame [ 12 ] = "Number of Time Slots";
  sLabel_NM_Multi_Frame [ 13 ] = "Slice Vector";
  sLabel_NM_Multi_Frame [ 14 ] = "Number of Slices";
  sLabel_NM_Multi_Frame [ 15 ] = "Angular View Vector";
  sLabel_NM_Multi_Frame [ 16 ] = "Time Slice Vector";


  /*	pModule : NM Multi_gated Acquisition Image	*/

  sLabel_NM_Multi_gated_Acquisition_Image [ 0 ] = "Beat Rejection Flag";
  sLabel_NM_Multi_gated_Acquisition_Image [ 1 ] = "PVC Rejection";
  sLabel_NM_Multi_gated_Acquisition_Image [ 2 ] = "Skip Beats";
  sLabel_NM_Multi_gated_Acquisition_Image [ 3 ] = "Heart Rate";
  sLabel_NM_Multi_gated_Acquisition_Image [ 4 ] = "Gated Information Sequence";
  


  /*	pModule : NM Phase	                        */
  
  /*??????????????????????????*/


  
  /*	pModule : NM Reconstruction	                */

  /*??????????????????????????*/



  /*	pModule : NM Series				*/

  sLabel_NM_Series [ 0 ] = "Patient Orientation Code Sequence";
  sLabel_NM_Series [ 1 ] = "Patient Gantry Relationship Code Sequence";


  /*	pModule : NM Tomo Acquisition			*/

  /*??????????????????????????*/


  /*	pModule : Overlay Identification			*/

  sLabel_Overlay_Identification [ 0 ] = "Overlay Number";
  sLabel_Overlay_Identification [ 1 ] = "Overlay Date";
  sLabel_Overlay_Identification [ 2 ] = "Overlay Time";
  sLabel_Overlay_Identification [ 3 ] = "Referenced Image Sequence";

  /*  sLabel_Overlay_Identification [  ] = "Referenced SOP Class UID";
  sLabel_Overlay_Identification [  ] = "Referenced SOP Instance UID";*/


  /*	pModule : Overlay Plane				*/

  sLabel_Overlay_Plane [ 0 ] = "Rows";
  sLabel_Overlay_Plane [ 1 ] = "Columns";
  sLabel_Overlay_Plane [ 2 ] = "Overlay Type";
  sLabel_Overlay_Plane [ 3 ] = "Origin";
  sLabel_Overlay_Plane [ 4 ] = "Bits Allocated";
  sLabel_Overlay_Plane [ 5 ] = "Bit Position";
  sLabel_Overlay_Plane [ 6 ] = "Overlay Data";
  sLabel_Overlay_Plane [ 7 ] = "Overlay Description";
  sLabel_Overlay_Plane [ 8 ] = "Overlay Subtype";
  sLabel_Overlay_Plane [ 9 ] = "Overlay Label";
  sLabel_Overlay_Plane [ 10 ] = "ROI Area";
  sLabel_Overlay_Plane [ 11 ] = "ROI Mean";
  sLabel_Overlay_Plane [ 12 ] = "ROI Standard Deviation";
  sLabel_Overlay_Plane [ 13 ] = "Overlay Descriptor Gray";
  sLabel_Overlay_Plane [ 14 ] = "Overlay Descriptor Red";
  sLabel_Overlay_Plane [ 15 ] = "Overlay Descriptor Green";
  sLabel_Overlay_Plane [ 16 ] = "Overlay Descriptor Blue";
  sLabel_Overlay_Plane [ 17 ] = "Overlays-Gray";
  sLabel_Overlay_Plane [ 18 ] = "Overlays-Red";
  sLabel_Overlay_Plane [ 19 ] = "Overlays-Green";
  sLabel_Overlay_Plane [ 20 ] = "Overlays-Blue";
  

  /*	pModule : Palette Color Lookup				*/

  /*??????????????????????????*/


  /*	pModule : Patient				*/

  sLabel_Patient [ 0 ] = "Patient's Name" ;
  sLabel_Patient [ 1 ] = "Patient ID" ;
  sLabel_Patient [ 2 ] = "Patient's Birth Date" ;
  sLabel_Patient [ 3 ] = "Patient's Sex" ;
  sLabel_Patient [ 4 ] = "Referenced Patient Sequence" ;
  sLabel_Patient [ 5 ] = "Patient's Birth Time" ;
  sLabel_Patient [ 6 ] = "Other Patient ID" ;
  sLabel_Patient [ 7 ] = "Other Patient Names" ;
  sLabel_Patient [ 8 ] = "Ethnic Group" ;
  sLabel_Patient [ 9 ] = "Patient Comments";

  /*  sLabel_Patient [ 5 ] = "Referenced SOP Class UID" ;
  sLabel_Patient [ 6 ] = "Referenced SOP Instance UID" ;*/


  /*	pModule : Patient Demographic			*/

  /*??????????????????????????*/


  /*	pModule : Patient Identification			*/

  /*??????????????????????????*/


  /*	pModule : Patient Medical			*/

  /*??????????????????????????*/


  /*	pModule : Patient Relationship			*/

  /*??????????????????????????*/


  /*	pModule : Patient Study				*/

  sLabel_Patient_Study [ 0 ] = "Admitting Diagnoses Description";
  sLabel_Patient_Study [ 1 ] = "Patient's Age";
  sLabel_Patient_Study [ 2 ] = "Patient's Size";
  sLabel_Patient_Study [ 3 ] = "Patient's Weight";
  sLabel_Patient_Study [ 4 ] = "Occupation";
  sLabel_Patient_Study [ 5 ] = "Additional Patients History";


  /*	pModule : Patient Summary			*/

  /*??????????????????????????*/


  /*	pModule : Pixel Offset				*/
  
  /*??????????????????????????*/


  /*	pModule : Printer				*/

  /*??????????????????????????*/


  /*	pModule : Print Job				*/

  /*??????????????????????????*/


  /*	pModule : Result Identification			*/

  /*??????????????????????????*/


  /*	pModule : Results Impression			*/

  /*??????????????????????????*/


  /*	pModule : Result Relationship			*/

  /*??????????????????????????*/


  /*	pModule : SC Image				*/

  sLabel_SC_Image [ 0 ] = "Date of Secondary Capture";
  sLabel_SC_Image [ 1 ] = "Time of Secondary Capture";


  /*	pModule : SC Image Equipment			*/

  sLabel_SC_Image_Equipment [ 0 ] = "Conversion Type";
  sLabel_SC_Image_Equipment [ 1 ] = "Modality";
  sLabel_SC_Image_Equipment [ 2 ] = "Secondary Capture Device ID";
  sLabel_SC_Image_Equipment [ 3 ] = "Secondary Capture Device Manufacturer";
  sLabel_SC_Image_Equipment [ 4 ] = "Secondary Capture Device Manufacturer's Model Name";
  sLabel_SC_Image_Equipment [ 5 ] = "Secondary Capture Device Software";
  sLabel_SC_Image_Equipment [ 6 ] = "Video Image Format Acquired";
  sLabel_SC_Image_Equipment [ 7 ] = "Digital Image Format Acquired";


  /*	pModule : SOP Common				*/

  sLabel_SOP_Common [ 0 ] = "SOP Class UID";
  sLabel_SOP_Common [ 1 ] = "SOP Instance UID";
  sLabel_SOP_Common [ 2 ] = "Specific Character Set";
  sLabel_SOP_Common [ 3 ] = "Instance Creation Date";
  sLabel_SOP_Common [ 4 ] = "Instance Creation Time";
  sLabel_SOP_Common [ 5 ] = "Instance Creator UID";


  /*	pModule : Study Acquisition			*/

  /*??????????????????????????*/


  /*	pModule : Study Classification			*/

  /*??????????????????????????*/


  /*	pModule : Study Component			*/

  /*??????????????????????????*/


  /*	pModule : Study Component Acquisition		*/

  /*??????????????????????????*/


  /*	pModule : Study Component Relationship		*/

  /*??????????????????????????*/


  /*	pModule : Study Content				*/

  /*??????????????????????????*/


  /*	pModule : Study Identification			*/

  /*??????????????????????????*/


  /*	pModule : Study Read				*/

  /*??????????????????????????*/


  /*	pModule : Study Relationship			*/

  /*??????????????????????????*/


  /*	pModule : Study Scheduling			*/

  /*??????????????????????????*/


  /*	pModule : UIN Overlay Sequence			*/

  sLabel_UIN_Overlay_Sequence [ 0 ] = "Owner ID";
  sLabel_UIN_Overlay_Sequence [ 1 ] = "UIN overlay sequence";


  /*	pModule : US Frame of Reference			*/

  /*??????????????????????????*/


  /*	pModule : US Image				*/

  sLabel_US_Image [ 0 ] = "Samples per Pixel";
  sLabel_US_Image [ 1 ] = "Photometric Interpretation";
  sLabel_US_Image [ 2 ] = "Bits Allocated";
  sLabel_US_Image [ 3 ] = "Bits Stored";
  sLabel_US_Image [ 4 ] = "High Bit";
  sLabel_US_Image [ 5 ] = "Planar Configuration";
  sLabel_US_Image [ 6 ] = "Pixel Representation";
  sLabel_US_Image [ 7 ] = "Frame Increment Pointer";
  sLabel_US_Image [ 8 ] = "Image Type";
  sLabel_US_Image [ 9 ] = "Lossy Image Compression";
  sLabel_US_Image [ 10 ] = "Number of Stages";
  sLabel_US_Image [ 11 ] = "Number of Views in Stage";
  sLabel_US_Image [ 12 ] = "Ultrasound Color Data Present";
  sLabel_US_Image [ 13 ] = "Referenced Overlay Sequence";
  sLabel_US_Image [ 14 ] = "Referenced Curve Sequence";
  sLabel_US_Image [ 15 ] = "Stage Name";
  sLabel_US_Image [ 16 ] = "Stage Number";
  sLabel_US_Image [ 17 ] = "View Number";
  sLabel_US_Image [ 18 ] = "Number of Event Timers";
  sLabel_US_Image [ 19 ] = "Event Elapsed Time(s)";
  sLabel_US_Image [ 20 ] = "Event Timer Name(s)";
  sLabel_US_Image [ 21 ] = "Anatomic Region Sequence";
  sLabel_US_Image [ 22 ] = "Primary Anatomic Structure Sequence";
  sLabel_US_Image [ 23 ] = "Transducer Position Sequence";
  sLabel_US_Image [ 24 ] = "Transducer Orientation Sequence";
  sLabel_US_Image [ 25 ] = "Trigger Time";
  sLabel_US_Image [ 26 ] = "Nominal Interval";
  sLabel_US_Image [ 27 ] = "Beat Rejection Flag";
  sLabel_US_Image [ 28 ] = "Low RR Value";
  sLabel_US_Image [ 29 ] = "High RR Value";
  sLabel_US_Image [ 30 ] = "Heart Rate";
  sLabel_US_Image [ 31 ] = "Output Power";
  sLabel_US_Image [ 32 ] = "Transducer Data";
  sLabel_US_Image [ 33 ] = "Transducer Type";
  sLabel_US_Image [ 34 ] = "Focus Depth";
  sLabel_US_Image [ 35 ] = "Preprocessing Function";
  sLabel_US_Image [ 36 ] = "Mechanical Index";
  sLabel_US_Image [ 37 ] = "Bone Thermal Index";
  sLabel_US_Image [ 38 ] = "Cranial Thermal Index";
  sLabel_US_Image [ 39 ] = "Soft Tissue Thermal Index";
  sLabel_US_Image [ 40 ] = "Soft Tissue focus Thermal Index";
  sLabel_US_Image [ 41 ] = "Soft Tissue surface Thermal Index";
  sLabel_US_Image [ 42 ] = "Depth of Scan Field";
  sLabel_US_Image [ 43 ] = "Image Transformation Matrix";
  sLabel_US_Image [ 44 ] = "Image Translation Vector";
  sLabel_US_Image [ 45 ] = "Overlay Subtype";


  /*	pModule : US Region Calibration			*/

  sLabel_US_Region_Calibration [ 0 ] = "Sequence of Ultrasound Regions";

  /*  sLabel_US_Region_Calibration [  ] = "Region Location Min x0";
  sLabel_US_Region_Calibration [  ] = "Region Location Min y0";
  sLabel_US_Region_Calibration [  ] = "Region Location Max x1";
  sLabel_US_Region_Calibration [  ] = "Region Location Max y1";
  sLabel_US_Region_Calibration [  ] = "Physical Units X Direction";
  sLabel_US_Region_Calibration [  ] = "Physical Units Y Direction";
  sLabel_US_Region_Calibration [  ] = "Physical Delta X";
  sLabel_US_Region_Calibration [  ] = "Physical Delta Y";
  sLabel_US_Region_Calibration [  ] = "Reference Pixel x0";
  sLabel_US_Region_Calibration [  ] = "Reference Pixel y0";
  sLabel_US_Region_Calibration [  ] = "Ref. Pixel Physical Value X";
  sLabel_US_Region_Calibration [  ] = "Ref. Pixel Physical Value Y";
  sLabel_US_Region_Calibration [  ] = "Region Spatial Format";
  sLabel_US_Region_Calibration [  ] = "Region Data Type";
  sLabel_US_Region_Calibration [  ] = "Region Flags";
  sLabel_US_Region_Calibration [  ] = "Pixel Component Organization";
  sLabel_US_Region_Calibration [  ] = "Pixel Component Mask";
  sLabel_US_Region_Calibration [  ] = "Pixel Component Range Start";
  sLabel_US_Region_Calibration [  ] = "Pixel Component Range Stop";
  sLabel_US_Region_Calibration [  ] = "Pixel Component Physical Units";
  sLabel_US_Region_Calibration [  ] = "Pixel Component Data Type";
  sLabel_US_Region_Calibration [  ] = "Number of Table Break Points";
  sLabel_US_Region_Calibration [  ] = "Table of X Break Points";
  sLabel_US_Region_Calibration [  ] = "Table of Y Break Points";
  sLabel_US_Region_Calibration [  ] = "Transducer Frequency";
  sLabel_US_Region_Calibration [  ] = "Pulse Repetition Frequency";
  sLabel_US_Region_Calibration [  ] = "Doppler Correction Angle";
  sLabel_US_Region_Calibration [  ] = "Steering Angle";
  sLabel_US_Region_Calibration [  ] = "Doppler Sample Volume X Position";
  sLabel_US_Region_Calibration [  ] = "Doppler Sample Volume Y Position";
  sLabel_US_Region_Calibration [  ] = "TM-Line Position x0";
  sLabel_US_Region_Calibration [  ] = "TM-Line Position y0";
  sLabel_US_Region_Calibration [  ] = "TM-Line Position x1";
  sLabel_US_Region_Calibration [  ] = "TM-Line Position y1";*/


  /*	pModule : Visit Admission			*/

  /*??????????????????????????*/


  /*	pModule : Visit Discharge			*/

  /*??????????????????????????*/


  /*	pModule : Visit Identification			*/

  /*??????????????????????????*/


  /*	pModule : Visit Relationship			*/

  /*??????????????????????????*/


  /*	pModule : Visit Scheduling			*/

  /*??????????????????????????*/


  /*	pModule : Visit Status				*/

  /*??????????????????????????*/


  /*	pModule : VOI LUT				*/
 
  sLabel_VOI_LUT [ 0 ] = "VOI LUT Sequence";
  sLabel_VOI_LUT [ 1 ] = "Window Center";
  sLabel_VOI_LUT [ 2 ] = "Window Width";
  sLabel_VOI_LUT [ 3 ] = "Window Center & Width Explanation";

  /*  sLabel_VOI_LUT [  ] = "LUT Descriptor";
  sLabel_VOI_LUT [  ] = "LUT Explanation";
  sLabel_VOI_LUT [  ] = "LUT  Data";*/


  /*	pModule : XRay Acquisition			*/

  sLabel_XRay_Acquisition [ 0 ] = "KVP";
  sLabel_XRay_Acquisition [ 1 ] = "Radiation Setting";
  sLabel_XRay_Acquisition [ 2 ] = "Xray Tube Current";
  sLabel_XRay_Acquisition [ 3 ] = "Exposure Time";
  sLabel_XRay_Acquisition [ 4 ] = "Exposure";
  sLabel_XRay_Acquisition [ 5 ] = "Grid";
  sLabel_XRay_Acquisition [ 6 ] = "Average Pulse Width";
  sLabel_XRay_Acquisition [ 7 ] = "Radiation Mode";
  sLabel_XRay_Acquisition [ 8 ] = "Type of Filters";
  sLabel_XRay_Acquisition [ 9 ] = "Intensifier Size";
  sLabel_XRay_Acquisition [ 10 ] = "Field of View Shape";
  sLabel_XRay_Acquisition [ 11 ] = "Field of View Dimensions";
  sLabel_XRay_Acquisition [ 12 ] = "Imager Pixel Spacing";
  sLabel_XRay_Acquisition [ 13 ] = "Focal Spots";
  sLabel_XRay_Acquisition [ 14 ] = "Image Area Dose Product";


  /*	pModule : XRay Acquisition Dose			*/

  sLabel_XRay_Acquisition_Dose [ 0 ] = "KVP";
  sLabel_XRay_Acquisition_Dose [ 1 ] = "Xray Tube Current";
  sLabel_XRay_Acquisition_Dose [ 2 ] = "Exposure Time";
  sLabel_XRay_Acquisition_Dose [ 3 ] = "Exposure";
  sLabel_XRay_Acquisition_Dose [ 4 ] = "Distance Source to Detector";
  sLabel_XRay_Acquisition_Dose [ 5 ] = "Distance Source to Patient";
  sLabel_XRay_Acquisition_Dose [ 6 ] = "Image Area Dose Product";
  sLabel_XRay_Acquisition_Dose [ 7 ] = "Body Part Thickness";
  sLabel_XRay_Acquisition_Dose [ 8 ] = "Entrance Dose";
  sLabel_XRay_Acquisition_Dose [ 9 ] = "Exposed Area";
  sLabel_XRay_Acquisition_Dose [ 10 ] = "Distance Source to Entrance";
  sLabel_XRay_Acquisition_Dose [ 11 ] = "Comments on Radiation Dose";
  sLabel_XRay_Acquisition_Dose [ 12 ] = "XRay Output";
  sLabel_XRay_Acquisition_Dose [ 13 ] = "Half Value Layer";
  sLabel_XRay_Acquisition_Dose [ 14 ] = "Organ Dose";
  sLabel_XRay_Acquisition_Dose [ 15 ] = "Organ Exposed";
  sLabel_XRay_Acquisition_Dose [ 16 ] = "Anode Target Material";
  sLabel_XRay_Acquisition_Dose [ 17 ] = "Filter Material";
  sLabel_XRay_Acquisition_Dose [ 18 ] = "Filter Thickness Minimum";
  sLabel_XRay_Acquisition_Dose [ 19 ] = "Filter Thickness Maximum";
  sLabel_XRay_Acquisition_Dose [ 20 ] = "Rectification Type";
  

  /*	pModule : XRay Collimator			*/

  sLabel_XRay_Collimator [ 0 ] = "Collimator Shape";
  sLabel_XRay_Collimator [ 1 ] = "Collimator Left Vertical Edge";
  sLabel_XRay_Collimator [ 2 ] = "Collimator Right Vertical Edge";
  sLabel_XRay_Collimator [ 3 ] = "Collimator Upper Horizontal Edge";
  sLabel_XRay_Collimator [ 4 ] = "Collimator Lower Horizontal Edge";
  sLabel_XRay_Collimator [ 5 ] = "Center of Circular Collimator";
  sLabel_XRay_Collimator [ 6 ] = "Radius of Circular Collimator";
  sLabel_XRay_Collimator [ 7 ] = "Vertices of the Polygonal Collimator";


  /*	pModule : XRay Image				*/

  sLabel_XRay_Image [ 0 ] = "Frame Increment Pointer";
  sLabel_XRay_Image [ 1 ] = "Lossy Image Compression";
  sLabel_XRay_Image [ 2 ] = "Image Type";
  sLabel_XRay_Image [ 3 ] = "Pixel Intensity Relationship";
  sLabel_XRay_Image [ 4 ] = "Samples per Pixel";
  sLabel_XRay_Image [ 5 ] = "Photometric Interpretation";
  sLabel_XRay_Image [ 6 ] = "Bits Allocated";
  sLabel_XRay_Image [ 7 ] = "Bits Stored";
  sLabel_XRay_Image [ 8 ] = "High Bit";
  sLabel_XRay_Image [ 9 ] = "Pixel Representation";
  sLabel_XRay_Image [ 10 ] = "Scan Options";
  sLabel_XRay_Image [ 11 ] = "Anatomic Region Sequence";
  sLabel_XRay_Image [ 12 ] = "Primary Anatomic Structure Sequence";
  sLabel_XRay_Image [ 13 ] = "RWave Pointer";
  sLabel_XRay_Image [ 14 ] = "Referenced Image Sequence";
  sLabel_XRay_Image [ 15 ] = "Derivation Description";
  sLabel_XRay_Image [ 16 ] = "Acquisition Device Processing Description";
  sLabel_XRay_Image [ 17 ] = "Calibration pObject";
  


  /*	pModule : XRay Table			*/

  /*??????????????????????????*/


} /* endof InitLabels3 */
