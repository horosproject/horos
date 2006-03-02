/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyInitModules3.c                                           */
/*	Function : declaration of the init fct.declaration of the init fct.     */
/*	Authors  : Christian Girard                                             */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 06.1994	version 3.0                                     */
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
#pragma segment papy3InitModule
#endif

/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif


/********************************************************************************/
/*										*/
/*	init_AcquisitionContext : initializes the elements of the module	*/
/*	Acquisition Context 							*/
/*										*/
/********************************************************************************/

void
init_AcquisitionContext (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papAcquisitionContextSequenceAC];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0555;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionContextDescriptionAC];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0556;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_Acquisition Context */


/********************************************************************************/
/*										*/
/*	init_Approval : initializes the elements of the module	*/
/*	Approval 							*/
/*										*/
/********************************************************************************/

void
init_Approval (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papApprovalStatus];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReviewDate];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReviewTime];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReviewerName];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_Approval */


/********************************************************************************/
/*										*/
/*	init_Audio : initializes the elements of the module			*/
/*	Audio 									*/
/*										*/
/********************************************************************************/

void
init_Audio (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papAudioType];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2000;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioSampleFormat];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofChannels];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2004;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofSamples];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2006;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSampleRate];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2008;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTotalTime];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x200A;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioSampleData];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x200C;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceAudio];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioComments];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x200E;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Audio */


/********************************************************************************/
/*										*/
/*	init_BasicAnnotationPresentation : initializes the elements of the module*/
/*	Basic Annotation Presentation 						*/
/*										*/
/********************************************************************************/

void
init_BasicAnnotationPresentation (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papAnnotationPosition];
  theWrkP->group = 0x2030;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTextString];
  theWrkP->group = 0x2030;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Basic Annotation Presentation */


/********************************************************************************/
/*										*/
/*	init_BasicFilmBoxPresentation : initializes the elements of the module	*/
/*	Basic Film Box Presentation 						*/
/*										*/
/********************************************************************************/

void
init_BasicFilmBoxPresentation (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageDisplayFormat];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationDisplayFormatID];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmOrientation];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmSizeID];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMagnificationTypeBFBP];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmoothingTypeBFBP];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBorderDensity];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEmptyImageDensity];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMinDensity];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaxDensity];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTrim];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConfigurationInformation];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0150;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Basic Film Box Presentation */


/********************************************************************************/
/*										*/
/*	init_BasicFilmBoxRelationship : initializes the elements of the module	*/
/*	Basic Film Box Relationship 						*/
/*										*/
/********************************************************************************/

void
init_BasicFilmBoxRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedFilmSessionSequence];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageBoxSequenceBFBR];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0510;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedBasicAnnotationBoxSequence];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0520;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Basic Film Box Relationship */


/********************************************************************************/
/*										*/
/*	init_BasicFilmSessionPresentation : initializes the elements of the module*/
/*	Basic File Session Presentation 					*/
/*										*/
/********************************************************************************/

void
init_BasicFilmSessionPresentation (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papNumberofCopies];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintPriorityBFSP];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMediumType];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmDestination];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmSessionLabel];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMemoryAllocation];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaximumMemoryAllocation];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Basic Film Session Presentation */


/********************************************************************************/
/*										*/
/*	init_BasicFilmSessionRelationship : initializes the elements of the module */
/*	Basic Film Session Relationship 					*/
/*										*/
/********************************************************************************/

void
init_BasicFilmSessionRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedFilmBoxSequence];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0L;
  theWrkP->value = NULL;

} /* endof init_Basic Film Session Relationship */


/********************************************************************************/
/*										*/
/*	init_BiPlaneImage : initializes the elements of the module              */
/*	Bi-Plane Image					                        */
/*										*/
/********************************************************************************/

void
init_BiPlaneImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSmallestImagePixelValueinPlane];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestImagePixelValueinPlane];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_BiPlaneImage */


/********************************************************************************/
/*										*/
/*	init_BiPlaneOverlay : initializes the elements of the module	*/
/*	Bi-Plane Overlay 							*/
/*										*/
/********************************************************************************/

void
init_BiPlaneOverlay (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papOverlayPlanes];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayPlaneOrigin];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_BiPlane Overlay */


/********************************************************************************/
/*										*/
/*	init_BiPlaneSequence : initializes the elements of the module           */
/*	Bi-Plane Sequence					*/
/*										*/
/********************************************************************************/

void
init_BiPlaneSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPlanes];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBiPlaneAcquisitionSequence];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x5000;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_BiPlaneSequence */


/********************************************************************************/
/*										*/
/*	init_Cine : initializes the elements of the module			*/
/*	Cine 									*/
/*										*/
/********************************************************************************/

void
init_Cine (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPreferredPlaybackSequencing];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1244;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameTimeC];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1063;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameTimeVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1065;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStartTrim];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2142;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStopTrim];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2143;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRecommendedDisplayFrameRate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2144;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCineRate];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameDelay];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1066;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEffectiveDuration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0072;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papActualFrameDurationC];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1242;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Cine */


/********************************************************************************/
/*										*/
/*	init_ContrastBolus : initializes the elements of the module		*/
/*	Contrast Bolus 								*/
/*										*/
/********************************************************************************/

void
init_ContrastBolus (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papContrastBolusAgent];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusAgentSequence];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusRoute];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusAdministrationRouteSequence];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusVolume];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusStartTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1042;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusStopTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1043;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusTotalDose];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastFlowRates];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1046;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastFlowDurations];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1047;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusIngredient];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1048;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusIngredientConcentration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1049;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Contrast Bolus */


/********************************************************************************/
/*										*/
/*	init_CRImage : initializes the elements of the module			*/
/*	CR Image 								*/
/*										*/
/********************************************************************************/

void
init_CRImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papKVPCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlateID];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoDetectorCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoPatientCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTimeCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXrayTubeCurrentCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1151;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagerPixelSpacingCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1164;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGeneratorPowerCRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1170;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingDescription];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingCode];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1401;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCassetteOrientation];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1402;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCassetteSize];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1403;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposuresonPlate];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1404;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRelativeXrayExposure];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1405;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSensitivity];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6000;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_CR Image */


/********************************************************************************/
/*										*/
/*	init_CRSeries : initializes the elements of the module			*/
/*	CR Series 								*/
/*										*/
/********************************************************************************/

void
init_CRSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papBodyPartExaminedCRS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewPosition];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5101;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterTypeCRS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorgridnameCRS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1180;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocalSpotCRS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1190;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlateType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1260;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhosphorType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1261;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_CR Series */


/********************************************************************************/
/*										*/
/*	init_CTImage : initializes the elements of the module			*/
/*	CT Image 								*/
/*										*/
/********************************************************************************/

void
init_CTImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageTypeCTI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesperPixelCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleInterceptCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleSlopeCTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papKVPCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionNumberCTI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanOptionsCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataCollectionDiameter];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionDiameterCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoDetectorCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoPatientCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGantryDetectorTiltCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableHeightCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationDirectionCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTimeCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXrayTubeCurrentCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1151;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterTypeCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGeneratorPowerCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1170;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocalSpotCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1190;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConvolutionKernelCTI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1210;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_CT Image */


/********************************************************************************/
/*										*/
/*	init_Curve : initializes the elements of the module			*/
/*	Curve 									*/
/*										*/
/********************************************************************************/

void
init_Curve (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papCurveDimensions];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPoints];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofData];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataValueRepresentation];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveData];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDescription];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxisUnits];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxisLabels];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMinimumCoordinateValue];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0104;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaximumCoordinateValue];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveRange];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0106;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDataDescriptor];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoordinateStartValue];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0112;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoordinateStepValue];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0114;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveLabel];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2500;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequence5000];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2600;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_Curve */


/********************************************************************************/
/*										*/
/*	init_CurveIdentification : initializes the elements of the module	*/
/*	Curve Identification 							*/
/*										*/
/********************************************************************************/

void
init_CurveIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papCurveNumber];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0025;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveTime];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0035;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceCI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequenceCI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedCurveSequenceCI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1145;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Curve Identification */


/********************************************************************************/
/*										*/
/*	init_Device : initializes the elements of the module		        */
/*	Device 								        */
/*										*/
/********************************************************************************/

void
init_Device (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papDeviceSequence];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_Device */


/********************************************************************************/
/*										*/
/*	init_DirectoryInformation : initializes the elements of the module 	*/
/*	Directory Information		 					*/
/*										*/
/********************************************************************************/

void
init_DirectoryInformation (SElement ioElem [])
{
  SElement	*theWrkP;
 
  theWrkP = &ioElem [papOffsetofTheFirstDirectoryRecord];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOffsetofTheLastDirectoryRecord];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilesetConsistencyFlag];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1212;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDirectoryRecordSequence];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Directory Information */


/********************************************************************************/
/*										*/
/*	init_DisplayShutter : initializes the elements of the module	        */
/*	Display Shutter 				      	                */
/*										*/
/********************************************************************************/

void
init_DisplayShutter (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papShutterShapeDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1600;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-3";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterLeftVerticalEdgeDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1602;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterRightVerticalEdgeDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1604;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterUpperHorizontalEdgeDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1606;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterLowerHorizontalEdgeDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1608;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCenterofCircularShutterDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1610;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiusofCircularShutterDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1612;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerticesofthePolygonalShutterDS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1620;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_Display Shutter */


/********************************************************************************/
/*										*/
/*	init_DXAnatomyImaged : initializes the elements of the module           */
/*	DX Anatomy Imaged 				                        */
/*										*/
/********************************************************************************/

void
init_DXAnatomyImaged (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageLateralityDXAI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequenceDXAI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequenceDXAI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_DX Anatomy Imaged */


/********************************************************************************/
/*										*/
/*	init_DXDetector : initializes the elements of the module                */
/*	DX Detector				                                */
/*										*/
/********************************************************************************/

void
init_DXDetector (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papDetectorTypeDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorConfigurationDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7005;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorDescriptionDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7006;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorModeDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7008;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorIDDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x700A;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateofLastDetectorCalibrationDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x700C;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeofLastDetectorCalibrationDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x700E;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposuresonDetectorSinceLastCalibrationDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7010;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposuresonDetectorSinceManufacturedDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7011;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorTimeSinceLastExposureDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveTimeDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7014;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActivationOffsetFromExposureDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7016;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorBinningDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x701A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorConditionsNominalFlagDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7000;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorTemperatureDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7001;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSensitivityDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6000;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewShapeDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1147;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewDimensionsDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1149;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewOriginDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewRotationDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewHorizontalFlipDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7034;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagerPixelSpacingDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1164;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorElementPhysicalSizeDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7020;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorElementSpacingDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveShapeDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7024;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveDimensionsDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveOriginDXD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_DX Detector */


/********************************************************************************/
/*										*/
/*	init_DXImage : initializes the elements of the module                   */
/*	DX Image				                                */
/*										*/
/********************************************************************************/

void
init_DXImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageTypeDXI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesperPixelDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelIntensityRelationshipDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelIntensityRelationshipSignDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = SS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleInterceptDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleSlopeDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleTypeDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1054;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationLUTShapeDXI];
  theWrkP->group = 0x2050;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papLossyImageCompressionDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papLossyImageCompressionRatioDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2112;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDerivationDescriptionDXI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2111;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingDescriptionDXI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingCodeDXI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1401;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientationDXI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCalibrationObjectDXI];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBurnedInAnnotationDXI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0301;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_DX Image */


/********************************************************************************/
/*										*/
/*	init_DXPositioning : initializes the elements of the module             */
/*	DX Positioning 				                                */
/*										*/
/********************************************************************************/

void
init_DXPositioning (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papProjectionEponymousNameCodeSequenceDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5104;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientPositionDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewPositionDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5101;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewCodeSequenceDXP];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewModifierCodeSequenceDXP];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0222;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientationCodeSequenceDXP];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0410;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientationModifierCodeSequenceDXP];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0412;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientGantryRelationshipCodeSequenceDXP];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0414;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoPatientDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoDetectorDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEstimatedRadiographicMagnificationFactorDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1114;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerTypeDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1508;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerPrimaryAngleDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1510;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerSecondaryAngleDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1511;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorPrimaryAngleDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1530;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorSecondaryAngleDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1531;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papColumnAngulationDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1450;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableTypeDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x113A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableAngleDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1138;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBodyPartThicknessDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x11A0;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompressionForceDXP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x11A2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_DX Positioning */


/********************************************************************************/
/*										*/
/*	init_DXSeries : initializes the elements of the module                  */
/*	DX Series 				                                */
/*										*/
/********************************************************************************/

void
init_DXSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityDX];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudyComponentSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationIndentType];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0068;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_DX Series */


/********************************************************************************/
/*										*/
/*	init_ExternalPapyrus_FileReferenceSequence : initializes the elements   */
/*      of the module External Papyrus_File Reference Sequence 		        */
/*										*/
/********************************************************************************/

void
init_ExternalPapyrus_FileReferenceSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papExternalPAPYRUSFileReferenceSequence];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1014;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_External Papyrus_File Reference Sequence */


/********************************************************************************/
/*										*/
/*	init_ExternalPatientFileReferenceSequence : initializes the elements of the module*/
/*	External Patient File Reference Sequence 				*/
/*										*/
/********************************************************************************/

void
init_ExternalPatientFileReferenceSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedPatientSequenceEPFRS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_External Patient File Reference Sequence */


/********************************************************************************/
/*										*/
/*	init_ExternalStudyFileReferenceSequence : initializes the elements of the module*/
/*	External Study File Reference Sequence 					*/
/*										*/
/********************************************************************************/

void
init_ExternalStudyFileReferenceSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedStudySequenceESFRS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_External Study File Reference Sequence */


/********************************************************************************/
/*										*/
/*	init_ExternalVisitReferenceSequence : initializes the elements of the module*/
/*	External Visit Reference Sequence 					*/
/*										*/
/********************************************************************************/

void
init_ExternalVisitReferenceSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedVisitSequenceEVRS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1125;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_External Visit Reference Sequence */


/********************************************************************************/
/*										*/
/*	init_FileReference : initializes the elements of the module		*/
/*	File Reference 								*/
/*										*/
/********************************************************************************/

void
init_FileReference (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedSOPClassUID];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1021;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPInstanceUID];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1022;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFileName];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1031;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFilePath];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1032;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_File Reference */


/********************************************************************************/
/*										*/
/*	init_FileSetIdentification : initializes the elements of the module 	*/
/*	File Set Identification		 					*/
/*										*/
/********************************************************************************/

void
init_FileSetIdentification (SElement ioElem [])
{
  SElement	*theWrkP;
 
  theWrkP = &ioElem [papFilesetID];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFileIDofFilesetDescriptorFile];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1141;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFormatofFilesetDescriptorFile];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1142;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0L;
  theWrkP->value = NULL;


} /* endof init_File Set Identification */


/********************************************************************************/
/*										*/
/*	init_FrameOfReference : initializes the elements of the module		*/
/*	Frame Of Reference 							*/
/*										*/
/********************************************************************************/

void
init_FrameOfReference (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papFrameofReferenceUID];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionReferenceIndicator];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Frame Of Reference */


/********************************************************************************/
/*										*/
/*	init_FramePointers : initializes the elements of the module		*/
/*	Frame Pointers 								*/
/*										*/
/********************************************************************************/

void
init_FramePointers (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRepresentativeFrameNumber];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameNumbersofInterest];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6020;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFramesofInterestDescription];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6022;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_FramePointers */


/********************************************************************************/
/*										*/
/*	init_GeneralEquipment : initializes the elements of the module		*/
/*	General Equipment 							*/
/*										*/
/********************************************************************************/

void
init_GeneralEquipment (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papManufacturerGE];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionNameGE];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionAddressGE];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStationName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionalDepartmentName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papManufacturersModelName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceSerialNumberGE];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftwareVersionsGE];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpatialResolution];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateofLastCalibration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeofLastCalibration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelPaddingValue];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Equipment */


/********************************************************************************/
/*										*/
/*	init_GeneralImage : initializes the elements of the module		*/
/*	General Image 								*/
/*										*/
/********************************************************************************/

void
init_GeneralImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInstanceNumberGI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientation];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "2";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageDate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0023;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTime];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTypeGI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionNumberGI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTime];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceGI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDerivationDescription];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2111;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSourceImageSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2112;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagesinAcquisition];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1002;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageComments];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompressionGI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Image */


/********************************************************************************/
/*										*/
/*	init_GeneralPatientSummary : initializes the elements of the module	*/
/*	General Patient Summary 						*/
/*										*/
/********************************************************************************/

void
init_GeneralPatientSummary (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientsNameGPS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsID];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthDateGPS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSexGPS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsHeight];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsWeightGPS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Patient Summary */


/********************************************************************************/
/*										*/
/*	init_GeneralSeries : initializes the elements of the module		*/
/*	General Series 								*/
/*										*/
/********************************************************************************/

void
init_GeneralSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesInstanceUIDGS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesNumberGS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLaterality];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesDate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesTime];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformingPhysiciansNameGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papProtocolName];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesDescription];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x103E;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOperatorsName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudyComponentSequenceGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBodyPartExaminedGS];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientPosition];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmallestPixelValueinSeries];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0108;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestPixelValueinSeries];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0109;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Series */


/********************************************************************************/
/*										*/
/*	init_GeneralSeriesSummary : initializes the elements of the module	*/
/*	General Series Summary 							*/
/*										*/
/********************************************************************************/

void
init_GeneralSeriesSummary (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityGSS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesInstanceUIDGSS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesNumberGSS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofimages];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1015;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Series Summary */


/********************************************************************************/
/*										*/
/*	init_GeneralStudy : initializes the elements of the module		*/
/*	General Study 								*/
/*										*/
/********************************************************************************/

void
init_GeneralStudy (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyInstanceUIDGS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyDateGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyTimeGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansNameGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyIDGS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAccessionNumberGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyDescriptionGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysiciansOfRecordGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1048;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNameofPhysiciansReadingStudyGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudySequenceGS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Study */


/********************************************************************************/
/*										*/
/*	init_GeneralStudySummary : initializes the elements of the module	*/
/*	General Study Summary 							*/
/*										*/
/********************************************************************************/

void
init_GeneralStudySummary (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyDateGSS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyTimeGSS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyUID];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyIDGSS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAccessionnumberGSS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansNameGSS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Study Summary */


/********************************************************************************/
/*										*/
/*	init_GeneralVisitSummary : initializes the elements of the module	*/
/*	General Visit Summary 							*/
/*										*/
/********************************************************************************/

void
init_GeneralVisitSummary (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papCurrentPatientLocationGVS];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsInstitutionResidenceGVS];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionNameVS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_General Visit Summary */


/********************************************************************************/
/*										*/
/*	init_IconImage : initializes the elements of the module			*/
/*	Icon Image 								*/
/*										*/
/********************************************************************************/

void
init_IconImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSamplesperPixelII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRowsII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColumnsII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteColorLookupTableDescriptors];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteColorLookupTableDescriptors];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteColorLookupTableDescriptors];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteColorLookupTableDataII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteColorLookupTableDataII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteColorLookupTableDataII];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelDataII];
  theWrkP->group = 0x7FE0;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Icon Image */


/********************************************************************************/
/*										*/
/*	init_IdentifyingImageSequence : initializes the elements of the module	*/
/*	Identifying Image Sequence 						*/
/*										*/
/********************************************************************************/

void
init_IdentifyingImageSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageIdentifierSequence];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1013;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* end of init_Identifying Image Sequence */


/********************************************************************************/
/*										*/
/*	init_ImageBoxPixelPresentation : initializes the elements of the module	*/
/*	Image Box Pixel Presentation 						*/
/*										*/
/********************************************************************************/

void
init_ImageBoxPixelPresentation (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImagePosition];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPolarity];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMagnificationTypeIBPP];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmoothingTypeIBPP];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedImageSize];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreformattedGrayscaleImageSequence];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreformattedColorImageSequence];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageOverlayBoxSequenceIBP];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPClassUID8];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPInstanceUID8];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1155;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Box Pixel Presentation */


/********************************************************************************/
/*										*/
/*	init_ImageBoxRelationship : initializes the elements of the module	*/
/*	Image Box Relationship 							*/
/*										*/
/********************************************************************************/

void
init_ImageBoxRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedImageSequenceBR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageOverlayBoxSequence];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedVOILUTSequence];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Box Relationship */



/********************************************************************************/
/*										*/
/*	init_ImageHistogram : initializes the elements of the module	        */
/*	Image Histogram 							*/
/*										*/
/********************************************************************************/

void
init_ImageHistogram (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papHistogramSequenceIH];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_Image Histogram */


 
/********************************************************************************/
/*										*/
/*	init_ImageIdentification : initializes the elements of the module	*/
/*	Image Identification 							*/
/*										*/
/********************************************************************************/

void
init_ImageIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedImageSOPClassUIDII];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSOPInstanceUID];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1042;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageNumberII];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Identification */


/********************************************************************************/
/*										*/
/*	init_ImageOverlayBoxPresentation : initializes the elements of the module*/
/*	Image Overlay Box Presentation 						*/
/*										*/
/********************************************************************************/

void
init_ImageOverlayBoxPresentation (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedOverlayPlaneSequence];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayMagnificationType];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaySmoothingType];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayForegroundDensity];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayMode];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papThresholdDensity];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Overlay Box Presentation */



/********************************************************************************/
/*										*/
/*	init_ImageOverlayBoxRelationship : initializes the elements of the module*/
/*	Image Overlay Box Relationship 						*/
/*										*/
/********************************************************************************/

void
init_ImageOverlayBoxRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedImageBoxSequenceOBR];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0510;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_Image Overlay Box Relationship */



/********************************************************************************/
/*										*/
/*	init_ImagePixel : initializes the elements of the module		*/
/*	Image Pixel 								*/
/*										*/
/********************************************************************************/

void
init_ImagePixel (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSamplesperPixelIP];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationIP];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRows];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColumns];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedIP];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredIP];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitIP];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationIP];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelData];
  theWrkP->group = 0x7FE0;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlanarConfiguration];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelAspectRatio];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmallestImagePixelValue];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0106;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestImagePixelValue];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0107;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteColorLookupTableDescriptor];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteColorLookupTableDescriptor];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteColorLookupTableDescriptor];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteColorLookupTableData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteColorLookupTableData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteColorLookupTableData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Pixel */



/********************************************************************************/
/*										*/
/*	init_ImagePlane : initializes the elements of the module		*/
/*	Image Plane 								*/
/*										*/
/********************************************************************************/

void
init_ImagePlane (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPixelSpacing];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageOrientationPatient];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0037;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "6";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagePositionPatient];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceThickness];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceLocation];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Plane */


/********************************************************************************/
/*										*/
/*	init_ImagePointer : initializes the elements of the module		*/
/*	Image Pointer 								*/
/*										*/
/********************************************************************************/

void
init_ImagePointer (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImagePointer];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1011;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Pointer */


/********************************************************************************/
/*										*/
/*	init_ImageSequence : initializes the elements of the module		*/
/*	Image Sequence 								*/
/*										*/
/********************************************************************************/

void
init_ImageSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageSequence];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Image Sequence */


/********************************************************************************/
/*										*/
/*	init_InternalImagePointerSequence : initializes the elements of the module*/
/*	Internal Image Pointer Sequence 					*/
/*										*/
/********************************************************************************/

void
init_InternalImagePointerSequence (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPointerSequence];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "M";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Internal Image Pointer Sequence */


/********************************************************************************/
/*										*/
/*	init_InterpretationApproval : initializes the elements of the module	*/
/*	Interpretation Approval 						*/
/*										*/
/********************************************************************************/

void
init_InterpretationApproval (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInterpretationApproverSequence];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationDiagnosisDescription];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0115;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationDiagnosisCodesSequence];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0117;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsDistributionListSequence];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0118;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Interpretation Approval */


/********************************************************************************/
/*										*/
/*	init_InterpretationIdentification : initializes the elements of the module*/
/*	Interpretation Identification 						*/
/*										*/
/********************************************************************************/

void
init_InterpretationIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInterpretationID];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationIDIssuer];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Interpretation Identification */


/********************************************************************************/
/*										*/
/*	init_InterpretationRecording : initializes the elements of the module	*/
/*	Interpretation Recording 						*/
/*										*/
/********************************************************************************/

void
init_InterpretationRecording (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInterpretationRecordedDate];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationRecordedTime];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationRecorder];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencetoRecordedSound];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Interpretation Recording */


/********************************************************************************/
/*										*/
/*	init_InterpretationRelationship : initializes the elements of the module*/
/*	Interpretation Relationship 						*/
/*										*/
/********************************************************************************/

void
init_InterpretationRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedResultsSequenceIR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Interpretation Relationship */


/********************************************************************************/
/*										*/
/*	init_InterpretationState : initializes the elements of the module	*/
/*	Interpretation State 							*/
/*										*/
/********************************************************************************/

void
init_InterpretationState (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInterpretationTypeID];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0210;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationStatusID];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0212;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Interpretation State */


/********************************************************************************/
/*										*/
/*	init_InterpretationTranscription : initializes the elements of the module*/
/*	Interpretation Transcription 						*/
/*										*/
/********************************************************************************/

void
init_InterpretationTranscription (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInterpretationTranscriptionDate];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0108;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTranscriptionTime];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0109;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTranscriber];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x010A;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationText];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x010B;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationAuthor];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x010C;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Interpretation Transcription */


/********************************************************************************/
/*										*/
/*	init_IntraOralImage : initializes the elements of the module		*/
/*	Intra-Oral Image 							*/
/*										*/
/********************************************************************************/

void
init_IntraOralImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPositionerTypeIOI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1508;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageLateralityIOI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequenceIOI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionModifierSequenceIOI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequenceIOI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_IntraOral Image */

  
/********************************************************************************/
/*										*/
/*	init_IntraOralSeries : initializes the elements of the module		*/
/*	Intra-Oral Series 							*/
/*										*/
/********************************************************************************/

void
init_IntraOralSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityIOS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_IntraOral Series */

  
/********************************************************************************/
/*										*/
/*	init_LUTIdentification : initializes the elements of the module		*/
/*	LUT Identification 							*/
/*										*/
/********************************************************************************/

void
init_LUTIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papLUTNumber];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceLI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_LUT Identification */


/********************************************************************************/
/*										*/
/*	init_MammographyImage : initializes the elements of the module		        */
/*	Mammography Image 								        */
/*										*/
/********************************************************************************/

void
init_MammographyImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPositionerTypeMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1508;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerPrimaryAngleMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1510;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerSecondaryAngleMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1511;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageLateralityMI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrganExposedMI];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0318;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequenceMI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewCodeSequenceMI];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewModifierCodeSequenceMI];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0222;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;


} /* endof init_Mammography Image */


/********************************************************************************/
/*										*/
/*	init_MammographySeries : initializes the elements of the module		        */
/*	Mammography Series 								        */
/*										*/
/********************************************************************************/

void
init_MammographySeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityMS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;


} /* endof init_Mammography Series */


/********************************************************************************/
/*										*/
/*	init_Mask : initializes the elements of the module		        */
/*	Mask 								        */
/*										*/
/********************************************************************************/

void
init_Mask (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papMaskSubtractionSequence];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRecommendedViewingMode];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Mask */


/********************************************************************************/
/*										*/
/*	init_ModalityLUT : initializes the elements of the module		*/
/*	Modality LUT 								*/
/*										*/
/********************************************************************************/

void
init_ModalityLUT (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityLUTSequence];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleInterceptML];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleSlopeML];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleType];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1054;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Modality LUT */


/********************************************************************************/
/*										*/
/*	init_MRImage : initializes the elements of the module			*/
/*	MR Image 								*/
/*										*/
/********************************************************************************/

void
init_MRImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageTypeMRI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesperPixelMRI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationMRI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedMRI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanningSequence];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSequenceVariant];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanOptionsMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMRAcquisitionTypeMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0023;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRepetitionTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEchoTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEchoTrainLength];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0091;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInversionTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerTimeMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSequenceName];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngioFlag];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0025;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofAverages];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0083;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagingFrequency];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0084;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagedNucleus];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0085;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEchoNumber];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0086;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMagneticFieldStrength];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0087;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpacingBetweenSlices];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0088;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPhaseEncodingSteps];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0089;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPercentSampling];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0093;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPercentPhaseFieldofView];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0094;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelBandwidth];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0095;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNominalIntervalMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1062;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBeatRejectionFlagMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLowRRValueMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1081;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighRRValueMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1082;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalsAcquiredMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1083;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalsRejectedMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1084;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPVCRejectionMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1085;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSkipBeatsMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1086;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHeartRateMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1088;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCardiacNumberofImagesMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerWindow];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1094;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionDiameterMRI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReceivingCoil];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1250;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransmittingCoil];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1251;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionMatrix];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1310;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "4";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseEncodingDirection];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1312;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFlipAngle];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1314;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSAR];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1316;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVariableFlipAngleFlag];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1315;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papdBdt];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1318;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemporalPositionIdentifier];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTemporalPositions];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemporalResolution];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_MR Image */


/********************************************************************************/
/*										*/
/*	init_Multi_Frame : initializes the elements of the module		*/
/*	Multi_Frame 								*/
/*										*/
/********************************************************************************/

void
init_Multi_Frame (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papNumberofFrames];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameIncrementPointerMF];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Multi_Frame */


/********************************************************************************/
/*										*/
/*	init_Multi_frameOverlay : initializes the elements of the module	*/
/*	Mult_frame Overlay 							*/
/*										*/
/********************************************************************************/

void
init_Multi_frameOverlay (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papNumberofFramesinOverlay];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageFrameOrigin];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Multi_frame Overlay */


/********************************************************************************/
/*										*/
/*	init_NMDetector : initializes the elements of the module		*/
/*	NM Detector 								*/
/*										*/
/********************************************************************************/

void
init_NMDetector (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papDetectorInformationSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM Detector */


/********************************************************************************/
/*										*/
/*	init_NMImage : initializes the elements of the module			*/
/*	NM Image 								*/
/*										*/
/********************************************************************************/

void
init_NMImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageType];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageID];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0400;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompressionNMI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCountsAccumulated];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTerminationCondition];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableHeightNMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableTraverseNMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1131;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papActualFrameDurationNMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1242;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountRate];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1243;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreprocessingFunctionNMI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCorrectedImage];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWholeBodyTechnique];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1301;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanVelocity];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1300;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanLength];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1302;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequenceNMI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedCurveSequenceNMI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1145;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerSourceorType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1061;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papAnatomicRegionSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM Image */


/********************************************************************************/
/*										*/
/*	init_NMImagePixel : initializes the elements of the module		*/
/*	NM Image Pixel 								*/
/*										*/
/********************************************************************************/

void
init_NMImagePixel (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSamplesperPixel];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretation];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocated];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStored];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBit];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelSpacingNM];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_NM Image Pixel*/


/********************************************************************************/
/*										*/
/*	init_NMIsotope : initializes the elements of the module		        */
/*	NM Isotope 								*/
/*										*/
/********************************************************************************/

void
init_NMIsotope (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papEnergyWindowInformationSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalInformationSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugInformationSequence];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_NM Isotope*/


/********************************************************************************/
/*										*/
/*	init_NMMultiFrame : initializes the elements of the module		*/
/*	NM Multi Frame								*/
/*										*/
/********************************************************************************/

void
init_NMMultiFrame (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papFrameIncrementPointer];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;

  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofEnergyWindows];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofDetectors];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPhases];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofRotations];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRRIntervalVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofRRIntervals];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSlotVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTimeSlots];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofSlices];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngularViewVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSliceVector];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_NM Multi Frame */


/********************************************************************************/
/*										*/
/*	init_NMMulti_gatedAcquisitionImage : initializes the elements of the module*/
/*	NM Multi_gated Acquisition Image 					*/
/*										*/
/********************************************************************************/

void
init_NMMulti_gatedAcquisitionImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papBeatRejectionFlagNMAI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPVCRejectionNMAI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1085;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSkipBeatsNMAI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1086;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHeartRateNMAI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1088;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGatedInformationSequenceNMAI];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM Multi_gated Acquisition Image */


/********************************************************************************/
/*										*/
/*	init_NMPhase : initializes the elements of the module		        */
/*	NM Phase 								*/
/*										*/
/********************************************************************************/

void
init_NMPhase (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPhaseInformationSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM Phase */


/********************************************************************************/
/*										*/
/*	init_NMReconstruction : initializes the elements of the module		        */
/*	NM Reconstruction 								*/
/*										*/
/********************************************************************************/

void
init_NMReconstruction (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSpacingBetweenSlicesNM];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0088;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionDiameter];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConvolutionKernel];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1210;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceThicknessNM];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceLocationNM];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM Reconstruction */


/********************************************************************************/
/*										*/
/*	init_NMSeries : initializes the elements of the module			*/
/*	NM Series 								*/
/*										*/
/********************************************************************************/

void
init_NMSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientOrientationCodeSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0410;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientGantryRelationshipCodeSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0414;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM Series */



/********************************************************************************/
/*										*/
/*	init_NMTomoAcquisition : initializes the elements of the module		*/
/*	NM Tomo Acquisition 							*/
/*										*/
/********************************************************************************/

void
init_NMTomoAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRotationInformationSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofDetectorMotion];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_NM TomoAcquisition */



/********************************************************************************/
/*										*/
/*	init_OverlayIdentification : initializes the elements of the module	*/
/*	Overlay Identification 							*/
/*										*/
/********************************************************************************/

void
init_OverlayIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papOverlayNumber];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayTime];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceOI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Overlay Identification */


/********************************************************************************/
/*										*/
/*	init_OverlayPlane : initializes the elements of the module		*/
/*	Overlay Plane 								*/
/*										*/
/********************************************************************************/

void
init_OverlayPlane (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRowsOP];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColumnsOP];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayType];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrigin];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedOP];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitPosition];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayData];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescription];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaySubtypeOP];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0045;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayLabel];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1500;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papROIArea];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1301;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papROIMean];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1302;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papROIStandardDeviation];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1303;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorGray];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorRed];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorGreen];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorBlue];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysGray];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysRed];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysGreen];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysBlue];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Overlay Plane */


/********************************************************************************/
/*										*/
/*	init_PaletteColorLookup : initializes the elements of the module	*/
/*	Palette Color Lookup 							*/
/*										*/
/********************************************************************************/

void
init_PaletteColorLookup (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRedPaletteColorLookupTableDescriptorPCL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteColorLookupTableDescriptorPCL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteColorLookupTableDescriptorPCL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPaletteColorLookupTableUID];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1199;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteCLUTData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteCLUTData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteCLUTData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSegmentedRedPaletteColorLookupTableData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1221;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSegmentedGreenPaletteColorLookupTableData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1222;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSegmentedBluePaletteColorLookupTableData];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1223;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_Palette Color Lookup */


/********************************************************************************/
/*										*/
/*	init_Patient : initializes the elements of the module			*/
/*	Patient 								*/
/*										*/
/********************************************************************************/

void
init_Patient (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientsNameP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientIDP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthDateP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSexP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPatientSequenceP];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthTimeP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherPatientID];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherPatientNamesP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEthnicGroupP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientCommentsP];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient */


/********************************************************************************/
/*										*/
/*	init_PatientDemographic : initializes the elements of the module	*/
/*	Patient Demographic 							*/
/*										*/
/********************************************************************************/

void
init_PatientDemographic (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientsAddress];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionofResidence];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2152;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountryofResidence];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2150;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsTelephoneNumbers];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2154;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthDatePD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthTimePD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEthnicGroupPD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSexPD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSizePD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsWeightPD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMilitaryRank];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBranchofService];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1081;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsInsurancePlanCodeSequence];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsReligiousPreference];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21F0;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientCommentsPD];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient Demographic */


/********************************************************************************/
/*										*/
/*	init_PatientIdentification : initializes the elements of the module	*/
/*	Patient Identification 							*/
/*										*/
/********************************************************************************/

void
init_PatientIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientsNamePI];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientIDPI];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIssuerofPatientID];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherPatientIDs];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherPatientNamesPI];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthName];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1005;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsMothersBirthName];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMedicalRecordLocator];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient Identification */


/********************************************************************************/
/*										*/
/*	init_PatientMedical : initializes the elements of the module		*/
/*	Patient Medical 							*/
/*										*/
/********************************************************************************/

void
init_PatientMedical (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientState];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPregnancyStatus];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21C0;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMedicalAlerts];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastAllergies];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecialNeeds];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLastMenstrualDate];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21D0;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmokingStatus];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21A0;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdditionalPatientHistory];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21B0;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient Medical */


/********************************************************************************/
/*										*/
/*	init_PatientRelationship : initializes the elements of the module	*/
/*	Patient Relationship 							*/
/*										*/
/********************************************************************************/

void
init_PatientRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedVisitSequencePR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1125;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudySequencePR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPatientAliasSequence];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient Relationship */


/********************************************************************************/
/*										*/
/*	init_PatientStudy : initializes the elements of the module		*/
/*	Patient Study 								*/
/*										*/
/********************************************************************************/

void
init_PatientStudy (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papAdmittingDiagnosesDescription];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsAge];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = AS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSizePS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsWeightPS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOccupation];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2180;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdditionalPatientsHistory];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21B0;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient Study */


/********************************************************************************/
/*										*/
/*	init_PETCurve : initializes the elements of the module		*/
/*	PET Curve							*/
/*										*/
/********************************************************************************/

void
init_PETCurve (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papCurveDimensionsPC];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofDataPC];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDataPC];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxisUnitsPC];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeadTimeCorrectionFlag];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1401;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountsIncluded];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreprocessingFunction];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_PETCurve */


/********************************************************************************/
/*										*/
/*	init_PETImage : initializes the elements of the module		*/
/*	PET Image							*/
/*										*/
/********************************************************************************/

void
init_PETImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageTypePI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesPerPixelPI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationPI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedPI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredPI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitPI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleInterceptPI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleSlopePI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameReferenceTime];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1300;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1063;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLowRRValue];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1081;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighRRValue];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1082;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompression];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageIndex];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1330;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDatePI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTimePI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papActualFrameDuration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1242;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNominalInterval];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1062;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalsAcquired];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1083;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalsRejected];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1084;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryCountsAccumulated];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1310;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCountsAccumulated];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1311;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceSensitivityFactor];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1320;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDecayFactor];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1321;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDoseCalibrationFactor];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1322;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScatterFractionFactor];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1323;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeadTimeFactor];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1324;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedCurveSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1145;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequencePI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequencePI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_PETImage */


/********************************************************************************/
/*										*/
/*	init_PETIsotope : initializes the elements of the module		*/
/*	PET Isotope							*/
/*										*/
/********************************************************************************/

void
init_PETIsotope (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRadiopharmaceuticalInformationSequencePI];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugInformationSequencePI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_PETIsotope */


/********************************************************************************/
/*										*/
/*	init_PETMultiGatedAcquisition : initializes the elements of the module		*/
/*	PET Multi-gated Acquisition							*/
/*										*/
/********************************************************************************/

void
init_PETMultiGatedAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papBeatRejectionFlag];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerSourceOrType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1061;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPVCRejection];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1085;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSkipBeats];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1086;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHeartRate];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1088;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFramingType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1064;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_PETMultiGatedAcquisition */


/********************************************************************************/
/*										*/
/*	init_PatientSummary : initializes the elements of the module		*/
/*	Patient Summary 							*/
/*										*/
/********************************************************************************/

void
init_PatientSummary (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientsNamePS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientIDPS];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Patient Summary */


/********************************************************************************/
/*										*/
/*	init_PETSeries : initializes the elements of the module		*/
/*	PET Series 								*/
/*										*/
/********************************************************************************/

void
init_PETSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSeriesDatePET];
  theWrkP->group = 0x00081;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesTimePET];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papUnits];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountsSource];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesTypeGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReprojectionMethod];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofRRIntervalsPET];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTimeSlotsPET];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofSlicesPET];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofRotationsPET];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRandomsCorrectionMethod];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAttenuationCorrectionMethod];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScatterCorrectionMethod];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1105;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDecayCorrection];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionDiameterPET];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConvolutionKernelPET];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1210;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionMethod];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorLinesOfResponseUsed];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1104;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionStartCondition];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0073;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionStartConditionData];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0074;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTerminationConditionPET];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTerminationConditionData];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0075;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewShape];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1147;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewDimensions];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1149;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGantryDetectorTilt];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGantryDetectorSlew];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1121;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofDetectorMotionPET];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1181;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorgridName];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1180;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxialAcceptance];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxialMash];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransverseMash];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorElementSize];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoincidenceWindowWidth];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1210;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowRangeSequence];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowLowerLimit];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowUpperLimit];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCountsType];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1220;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_PETSeries */



/********************************************************************************/
/*										*/
/*	init_PixelOffset : initializes the elements of the module		*/
/*	Pixel Offset 								*/
/*										*/
/********************************************************************************/

void
init_PixelOffset (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPixelOffset];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1012;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Pixel Offset */


/********************************************************************************/
/*										*/
/*	init_Printer : initializes the elements of the module			*/
/*	Printer 								*/
/*										*/
/********************************************************************************/

void
init_Printer (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPrinterStatus];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterStatusInfo];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterNameP];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papManufacturerP];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papManufacturerModelName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceSerialNumberP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftwareVersionsP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateOfLastCalibration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeOfLastCalibration];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Printer */


/********************************************************************************/
/*										*/
/*	init_PrintJob : initializes the elements of the module			*/
/*	Print Job 								*/
/*										*/
/********************************************************************************/

void
init_PrintJob (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papExecutionStatus];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExecutionStatusInfo];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCreationDate];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCreationTime];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintPriorityPJ];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterNamePJ];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOriginator];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Print Job */


/********************************************************************************/
/*										*/
/*	init_ResultIdentification : initializes the elements of the module	*/
/*	Result Identification 							*/
/*										*/
/********************************************************************************/

void
init_ResultIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papResultsID];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsIDIssuer];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Result Identification */


/********************************************************************************/
/*										*/
/*	init_ResultsImpression : initializes the elements of the module		*/
/*	Results Impression 							*/
/*										*/
/********************************************************************************/

void
init_ResultsImpression (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImpressions];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsComments];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Results Impression */


/********************************************************************************/
/*										*/
/*	init_ResultRelationship : initializes the elements of the module	*/
/*	Result Relationship 							*/
/*										*/
/********************************************************************************/

void
init_ResultRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedStudySequenceRR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedInterpretationSequence];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Result Relationship */


/********************************************************************************/
/*										*/
/*	init_RFTomographyAcquisition : initializes the elements of the module	*/
/*	RF Tomography Acquisition module 					*/
/*										*/
/********************************************************************************/

void
init_RFTomographyAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papTornoLayerHeight];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1460;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoAngle];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1470;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1480;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  
} /* endof init_RFTomographyAcquisition */


/********************************************************************************/
/*										*/
/*	init_ROIContour : initializes the elements of the module		*/
/*	ROI Contour 								*/
/*										*/
/********************************************************************************/

void
init_ROIContour (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papROIContourSequence];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0039;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourNumber];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0048;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papAttachedContours];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0049;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  
} /* endof init_ROI Contour */


/********************************************************************************/
/*										*/
/*	init_RTBeams : initializes the elements of the module			*/
/*	RT Beams								*/
/*										*/
/********************************************************************************/

void
init_RTBeams (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papBeamSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papHighDoseTechniqueType];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C7;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorNumber];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E4;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompensatorType];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00EE;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  
} /* endof init_RT Beams */


/********************************************************************************/
/*										*/
/*	init_RTBrachyApplicationSetups : initializes the elements of the module	*/
/*	RT Brachy Application Setups							*/
/*										*/
/********************************************************************************/

void
init_RTBrachyApplicationSetups (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papBrachyTreatmentTechnique];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyTreatmentType];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentMachineSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0206;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0210;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicationSetupSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0230;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  

} /* endof init_RT Brachy Application Setups */


/********************************************************************************/
/*										*/
/*	init_RTDose : initializes the elements of the module	*/
/*	RT Dose							*/
/*										*/
/********************************************************************************/

void
init_RTDose (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSamplesperPixelRTD];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationRTD];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedRTD];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredRTD];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitRTD];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationRTD];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDoseUnitsRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseTypeRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papInstanceNumber];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseCommentRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNormalizationPointRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseSummationTypeRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedRTPlanSequenceRTD];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papGridFrameOffsetVectorRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseGridScalingRTD];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_RT Dose*/


/********************************************************************************/
/*										*/
/*	init_RTDoseROI : initializes the elements of the module	*/
/*	RT Dose ROI							*/
/*										*/
/********************************************************************************/

void
init_RTDoseROI (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRTDoseROISequence];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_RT Dose ROI*/


/********************************************************************************/
/*										*/
/*	init_RTDVH : initializes the elements of the module	*/
/*	RT DVH							*/
/*										*/
/********************************************************************************/

void
init_RTDVH (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedStructureSetSequence];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHNormalizationPoint];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHNormalizationDoseValue];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHSequence];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_RT DVH*/


/********************************************************************************/
/*										*/
/*	init_RTFractionScheme : initializes the elements of the module	*/
/*	RT Fraction Scheme							*/
/*										*/
/********************************************************************************/

void
init_RTFractionScheme (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papFractionGroupSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_RT Fraction Scheme*/


/********************************************************************************/
/*										*/
/*	init_RTGeneralPlan : initializes the elements of the module	*/
/*	RT General Plan							*/
/*										*/
/********************************************************************************/

void
init_RTGeneralPlan (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRTPlanLabel];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanName];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanDescription];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanInstanceNumber];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOperatorsNameRTGP];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRTPlanDate];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanTime];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0007;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentProtocols];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTreatmentIntent];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentSites];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000B;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanGeometry];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStructureSetSequenceRTGP];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedDoseSequence];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedRTPlanSequence];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_RT General Plan*/


/********************************************************************************/
/*										*/
/*	init_RTImage : initializes the elements of the module	*/
/*	RT Image							*/
/*										*/
/********************************************************************************/

void
init_RTImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSamplesperPixelRTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationRTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedRTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredRTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitRTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationRTI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRTImageLabelRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageNameRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageDescriptionRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papOperatorsNameRTI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTypeRTI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConversionTypeRTI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0064;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReportedValuesOriginRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImagePlaneRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papXRayImageReceptortranslation];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papXRayImageReceptorAngleRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageOrientationRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "6";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papImagePlanePixelSpacingRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImagePositionRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationMachineNameRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPrimaryDosimeterUnitRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B3;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationMachineSADRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationMachineSSDRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRTImageSIDRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoReferenceObjectDistanceRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedRTPlanSequenceRTI];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBeamNumberRTI];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedFractionGroupNumberRTI];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFractionNumberRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0029;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStartCumulativeMetersetWeightRTI];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papEndCumulativeMetersetWeightRTI];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papExposureSequenceRTI];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papGantryAngleRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x011E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDiaphragmPosition];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "4";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBeamLimitingDeviceAngleRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientSupportAngleRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0122;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopEccentricAxisDistanceRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0124;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopEccentricAngleRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0125;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopVerticalPositionRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0128;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLongitudinalPositionRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0129;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLateralPositionRTI];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x012A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_RT Image*/


/********************************************************************************/
/*										*/
/*	init_RTPatientSetup : initializes the elements of the module	*/
/*	RT Patient Setup							*/
/*										*/
/********************************************************************************/

void
init_RTPatientSetup (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPatientSetupSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0180;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_RT Patient Setup*/


/********************************************************************************/
/*										*/
/*	init_RTPrescription : initializes the elements of the module	*/
/*	RT Prescription							*/
/*										*/
/********************************************************************************/

void
init_RTPrescription (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPrescriptionDescription];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferenceSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_RT Prescription*/


/********************************************************************************/
/*										*/
/*	init_RTROIObservations : initializes the elements of the module	*/
/*	RT ROI Observations							*/
/*										*/
/********************************************************************************/

void
init_RTROIObservations (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRTROIObservationsSequence];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_RT ROI Observations*/


/********************************************************************************/
/*										*/
/*	init_RTSeries : initializes the elements of the module	*/
/*	RT Series							*/
/*										*/
/********************************************************************************/

void
init_RTSeries (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalityRTS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesInstanceUIDRTS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesNumberRTS];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesDescriptionRTS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x103E;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudyComponentSequenceRTS];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_RT Series*/


/********************************************************************************/
/*										*/
/*	init_RTToleranceTables : initializes the elements of the module	*/
/*	RT Tolerance Tables							*/
/*										*/
/********************************************************************************/

void
init_RTToleranceTables (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papToleranceTableSequence];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_RT Tolerance Tables*/


/********************************************************************************/
/*										*/
/*	init_StructureSet : initializes the elements of the module	*/
/*	Structure Set							*/
/*										*/
/********************************************************************************/

void
init_StructureSet (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStructureSetLabel];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetName];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetDescription];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetDate];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetTime];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedFrameofReferenceSequence];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetROISequence];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Structure Set*/


/********************************************************************************/
/*										*/
/*	init_SCImage : initializes the elements of the module			*/
/*	SC Image 								*/
/*										*/
/********************************************************************************/

void
init_SCImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papDateofSecondaryCapture];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1012;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeofSecondaryCapture];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1014;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_SC Image */


/********************************************************************************/
/*										*/
/*	init_SCImageEquipment : initializes the elements of the module		*/
/*	SC Image Equipment 							*/
/*										*/
/********************************************************************************/

void
init_SCImageEquipment (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papConversionType];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0064;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModalitySIE];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceID];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceManufacturer];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1016;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceManufacturersModelName];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1018;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceSoftwareVersion];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1019;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVideoImageFormatAcquired];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1022;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDigitalImageFormatAcquired];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1023;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_SC Image Equipment */


/********************************************************************************/
/*										*/
/*	init_SCMultiFrameImage : initializes the elements of the module			*/
/*	SC Multi-Frame Image pModule 								*/
/*										*/
/********************************************************************************/

void
init_SCMultiFrameImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papZoomFactor];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationLUTShape];
  theWrkP->group = 0x2050;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIllumination];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x015E;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReflectedAmbientLight];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0160;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleIntercept];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleSlope];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleTypeSCMF];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1054;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameIncrementPointerSCMF];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNominalScannedPixelSpacing];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2010;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDigitizingDeviceTransportDirection];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationOfScannedFilm];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_SCMultiFrameImage */


/********************************************************************************/
/*										*/
/*	init_SCMultiFrameVector : initializes the elements of the module			*/
/*	SC Multi-Frame Vector pModule 								*/
/*										*/
/********************************************************************************/

void
init_SCMultiFrameVector (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papFrameTimeVectorSCMFV];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1065;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPageNumberVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2001;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameLabelVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFramePrimaryAngleVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2003;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameSecondaryAngleVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2004;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceLocationVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2005;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDisplayWindowLabelVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2006;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_SCMultiFrameVector */


/********************************************************************************/
/*										*/
/*	init_SlideCoordinates : initializes the elements of the module			*/
/*	Slide Coordinates 								*/
/*										*/
/********************************************************************************/

void
init_SlideCoordinates (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageCenterPointCoordinatesSequence];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x071A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXOffsetInSlideCoordinateSystem];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x072A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papYOffsetInSlideCoordinateSystem];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x073A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papZOffsetInSlideCoordinateSystem];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x074A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelSpacingSequence];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x08D8;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_SlideCoordinates */


/********************************************************************************/
/*										*/
/*	init_SOPCommon : initializes the elements of the module			*/
/*	SOP Common 								*/
/*										*/
/********************************************************************************/

void
init_SOPCommon (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSOPClassUID];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSOPInstanceUID];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0018;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecificCharacterSet];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceCreationDate];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceCreationTime];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceCreatorUID];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimezoneOffsetFromUTC];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0201;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_SOP Common */


/********************************************************************************/
/*										*/
/*	init_SpecimenIdentification : initializes the elements of the module	*/
/*	Specimen Identification							*/
/*										*/
/********************************************************************************/

void
init_SpecimenIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSpecimenAccessionNumber];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x050A;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecimenSequence];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0550;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;


} /* endof init_Specimen Identification */


/********************************************************************************/
/*										*/
/*	init_StudyAcquisition : initializes the elements of the module		*/
/*	Study Acquisition 							*/
/*										*/
/********************************************************************************/

void
init_StudyAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyArrivalDate];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyArrivalTime];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyDateSA];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyTimeSA];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModalitiesInStudy];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyCompletionDate];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyCompletionTime];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1051;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyVerifiedDate];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyVerifiedTime];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesinStudy];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionsinStudy];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Acquisition */


/********************************************************************************/
/*										*/
/*	init_StudyClassification : initializes the elements of the module	*/
/*	Study Classification 							*/
/*										*/
/********************************************************************************/

void
init_StudyClassification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyStatusID];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyPriorityID];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyComments];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Classification */


/********************************************************************************/
/*										*/
/*	init_StudyComponent : initializes the elements of the module		*/
/*	Study Component 							*/
/*										*/
/********************************************************************************/

void
init_StudyComponent (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyIDSC];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyInstanceUIDSC];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSeriesSequenceSC];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1115;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Component */


/********************************************************************************/
/*										*/
/*	init_StudyComponentAcquisition : initializes the elements of the module	*/
/*	Study Component Acquisition 						*/
/*										*/
/********************************************************************************/

void
init_StudyComponentAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papModalitySCA];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyDescriptionSCA];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papProcedureCodeSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1032;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformingPhysiciansNameSCA];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyComponentStatusID];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1055;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Component Acquisition */


/********************************************************************************/
/*										*/
/*	init_StudyComponentRelationship : initializes the elements of the module*/
/*	Study Component Relationship 						*/
/*										*/
/********************************************************************************/

void
init_StudyComponentRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedStudySequenceSCR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Component Relationship */


/********************************************************************************/
/*										*/
/*	init_StudyContent : initializes the elements of the module		*/
/*	Study Content 								*/
/*										*/
/********************************************************************************/

void
init_StudyContent (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyIDSCt];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyInstanceUIDSCt];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSeriesSequenceSCt];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1115;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Content */


/********************************************************************************/
/*										*/
/*	init_StudyIdentification : initializes the elements of the module	*/
/*	Study Identification 							*/
/*										*/
/********************************************************************************/

void
init_StudyIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStudyIDSI];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyIDIssuer];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherStudyNumbers];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Identification */


/********************************************************************************/
/*										*/
/*	init_StudyRead : initializes the elements of the module			*/
/*	Study Read 								*/
/*										*/
/********************************************************************************/

void
init_StudyRead (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papNameofPhysiciansReadingStudySR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyReadDate];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyReadTime];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0035;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Read */


/********************************************************************************/
/*										*/
/*	init_StudyRelationship : initializes the elements of the module		*/
/*	Study Relationship 							*/
/*										*/
/********************************************************************************/

void
init_StudyRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedVisitSequenceSR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1125;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPatientSequenceSR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedResultsSequenceSR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudyComponentSequenceSR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyInstanceUIDSR];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAccessionNumberSR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Relationship */


/********************************************************************************/
/*										*/
/*	init_StudyScheduling : initializes the elements of the module		*/
/*	Study Scheduling 							*/
/*										*/
/********************************************************************************/

void
init_StudyScheduling (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papScheduledStudyStartDate];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStartTime];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStopDate];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStopTime];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1011;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyLocation];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyLocationAETitle];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1021;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReasonforStudy];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestingPhysician];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1032;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestingService];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1033;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureDescription];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureCodeSequence];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1064;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedContrastAgent];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Study Scheduling */


/********************************************************************************/
/*										*/
/*	init_Therapy: initializes the elements of the module	                */
/*	Therapy 				      	                        */
/*										*/
/********************************************************************************/

void
init_Therapy (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInterventionalTherapySequenceTH];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0036;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  
} /* endof init_Therapy */


/********************************************************************************/
/*										*/
/*	init_UINOverlaySequence : initializes the elements of the module 	*/
/*	UIN Overlay Sequence		 					*/
/*										*/
/********************************************************************************/

void
init_UINOverlaySequence (SElement ioElem [])
{
  SElement	*theWrkP;
 
  theWrkP = &ioElem [papOwnerID];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 1L;
  theWrkP->value = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
  theWrkP->value->a = (char *) ecalloc3 ((PapyULong) 12, (PapyULong) sizeof (char));
  strcpy (theWrkP->value->a, "PAPYRUS 3.0");

  theWrkP = &ioElem [papUINOverlaySequence];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10C0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0L;
  theWrkP->value = NULL;

} /* endof init_UIN Overlay Sequence */


/********************************************************************************/
/*										*/
/*	init_USFrameofReference : initializes the elements of the module	*/
/*	USS Frame of Reference 							*/
/*										*/
/********************************************************************************/

void
init_USFrameofReference (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papRegionLocationMinx0];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6018;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMiny0];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x601A;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMaxx1];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x601C;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMaxy1];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x601E;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalUnitsXDirection];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6024;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalUnitsYDirection];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6026;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalDeltaX];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x602C;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalDeltaY];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x602E;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencePixelx0];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6020;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencePixely0];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6022;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRefPixelPhysicalValueX];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6028;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRefPixelPhysicalValueY];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x602A;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_US Frame of Reference */


/********************************************************************************/
/*										*/
/*	init_USImage : initializes the elements of the module			*/
/*	USS Image 								*/
/*										*/
/********************************************************************************/

void
init_USImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSamplesperPixelUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlanarConfigurationUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameIncrementPointerUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTypeUSI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompressionUSI];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofStages];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2124;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofViewsinStage];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x212A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papUltrasoundColorDataPresent];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequenceUSI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedCurveSequenceUSI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1145;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStageName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2120;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStageCodeSequence];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStageNumber];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2122;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewName];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2127;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewNumber];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2128;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofEventTimers];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2129;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEventElapsedTimes];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2130;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEventTimerNames];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2132;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequenceUSI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequenceUSI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerPositionSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2240;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerOrientationSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2244;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerTimeUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNominalIntervalUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1062;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBeatRejectionFlagUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLowRRValueUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1081;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighRRValueUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1082;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHeartRateUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1088;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOutputPower];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5000;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerData];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerType];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6031;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocusDepth];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreprocessingFunctionUSI];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMechanicalIndex];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBoneThermalIndex];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5024;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCranialThermalIndex];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftTissueThermalIndex];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5027;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftTissuefocusThermalIndex];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftTissuesurfaceThermalIndex];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5029;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDepthofScanField];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5050;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTransformationMatrix];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5210;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "6";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTranslationVector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5212;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaySubtype];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0045;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_US Image */


/********************************************************************************/
/*										*/
/*	init_USRegionCalibration : initializes the elements of the module	*/
/*	USS Region Calibration 							*/
/*										*/
/********************************************************************************/

void
init_USRegionCalibration (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papSequenceofUltrasoundRegions];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6011;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_US Region Calibration */


/********************************************************************************/
/*										*/
/*	init_VisitAdmission : initializes the elements of the module		*/
/*	Visit Admission 							*/
/*										*/
/********************************************************************************/

void
init_VisitAdmission (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papAdmittingDate];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingTime];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRouteofAdmissions];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingDiagnosisDescription];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingDiagnosisCodeSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1084;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansNameVA];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAddress];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0092;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansPhoneNumbers];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0094;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Visit Admission */


/********************************************************************************/
/*										*/
/*	init_VisitDischarge : initializes the elements of the module		*/
/*	Visit Discharge 							*/
/*										*/
/********************************************************************************/

void
init_VisitDischarge (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papDischargeDate];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDischargeTime];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDescription];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDischargeDiagnosisCodeSequence];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0044;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Visit Discharge */


/********************************************************************************/
/*										*/
/*	init_VisitIdentification : initializes the elements of the module	*/
/*	Visit Identification 							*/
/*										*/
/********************************************************************************/

void
init_VisitIdentification (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papInstitutionNameVI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionAddressVI];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionCodeSequence];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmissionID];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIssuerofAdmissionID];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Visit Identification */


/********************************************************************************/
/*										*/
/*	init_VisitRelationship : initializes the elements of the module		*/
/*	Visit Relationship 							*/
/*										*/
/********************************************************************************/

void
init_VisitRelationship (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedStudySequenceVR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPatientSequenceVR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Visit Relationship */


/********************************************************************************/
/*										*/
/*	init_VisitScheduling : initializes the elements of the module		*/
/*	Visit Scheduling 							*/
/*										*/
/********************************************************************************/

void
init_VisitScheduling (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papScheduledAdmissionDate];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001A;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledAdmissionTime];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001B;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledDischargeDate];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001C;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledDischargeTime];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001D;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledPatientInstitutionResidence];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001E;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Visit Scheduling */


/********************************************************************************/
/*										*/
/*	init_VisitStatus : initializes the elements of the module		*/
/*	Visit Status 								*/
/*										*/
/********************************************************************************/

void
init_VisitStatus (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papVisitStatusID];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurrentPatientLocationVS];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsInstitutionResidenceVS];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0400;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVisitComments];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Visit Status */


/********************************************************************************/
/*										*/
/*	init_VLImage : initializes the elements of the module			*/
/*	VL Image 								*/
/*										*/
/********************************************************************************/

void
init_VLImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papImageTypeVL];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesperPixelVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlanarConfigurationVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTimeVL];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompressionVL];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceVL];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_VLImage */


/********************************************************************************/
/*										*/
/*	init_VOILUT : initializes the elements of the module			*/
/*	VOI LUT 								*/
/*										*/
/********************************************************************************/

void
init_VOILUT (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papVOILUTSequence];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWindowCenter];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWindowWidth];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1051;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWindowCenterWidthExplanation];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1055;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_VOI LUT */


/********************************************************************************/
/*										*/
/*	init_XRayAcquisition : initializes the elements of the module			*/
/*	XRay Acquisition 								*/
/*										*/
/********************************************************************************/

void
init_XRayAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papKVP];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiationSetting];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1155;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXrayTubeCurrent];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1151;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposure];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGrid];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1166;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAveragePulseWidth];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1154;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiationMode];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x115A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofFilters];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1161;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntensifierSize];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1162;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewShapeXRA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1147;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewDimensionsXRA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1149;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagerPixelSpacing];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1164;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocalSpots];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1190;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageAreaDoseProduct];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x115E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_XRay Acquisition */


/********************************************************************************/
/*										*/
/*	init_XRayAcquisitionDose : initializes the elements of the module	*/
/*	XRay Acquisition Dose							*/
/*										*/
/********************************************************************************/

void
init_XRayAcquisitionDose (SElement ioElem [])
{
  SElement	*theWrkP;
  
  theWrkP = &ioElem [papKVPXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXrayTubeCurrentXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1151;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTimeXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoDetectorXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoPatientXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageAreaDoseProductXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x115E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBodyPartThicknessXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x11A0;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEntranceDoseXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0302;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposedAreaXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0303;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoEntranceXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0306;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCommentsonRadiationDoseXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0310;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXRayOutputXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0312;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHalfValueLayerXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0314;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrganDoseXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0316;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrganExposedXRAD];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0318;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnodeTargetMaterialXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1191;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterMaterialXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7050;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterThicknessMinimumXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterThicknessMaximumXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7054;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRectificationTypeXRAD];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1156;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_XRay Acquisition Dose */


/********************************************************************************/
/*										*/
/*	init_XRayCollimator : initializes the elements of the module		*/
/*	XRay Collimator 							*/
/*										*/
/********************************************************************************/

void
init_XRayCollimator (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papCollimatorShape];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1700;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-3";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorLeftVerticalEdge];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1702;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorRightVerticalEdge];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1704;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorUpperHorizontalEdge];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1706;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorLowerHorizontalEdge];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1708;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCenterofCircularCollimator];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1710;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiusofCircularCollimator];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1712;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerticesofthePolygonalCollimator];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1720;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Collimator */


/********************************************************************************/
/*										*/
/*	init_XRayFiltration : initializes the elements of the module		*/
/*	XRay Filtration 							*/
/*										*/
/********************************************************************************/

void
init_XRayFiltration (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papFilterTypeXRF];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterMaterialXRF];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7050;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterThicknessMinimumXRF];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterThicknessMaximumXRF];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7054;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Filtration */


/********************************************************************************/
/*										*/
/*	init_XRayGeneration : initializes the elements of the module		*/
/*	XRay Generation 							*/
/*										*/
/********************************************************************************/

void
init_XRayGeneration (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papKVPXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXrayTubeCurrentXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1151;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTimeXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureinmAsXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1153;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureControlModeXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureControlModeDescriptionXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7062;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureStatusXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7064;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhototimerSettingXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7065;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocalSpotsXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1190;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnodeTargetMaterialXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1191;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRectificationTypeXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1156;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Generation */


/********************************************************************************/
/*										*/
/*	init_XRayGrid : initializes the elements of the module		        */
/*	XRay Grid 							        */
/*										*/
/********************************************************************************/

void
init_XRayGrid (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGridXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1166;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridAbsorbingMaterialXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7040;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridSpacingMaterialXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7041;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridThicknessXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7042;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridPitchXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridAspectRatioXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7046;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridPeriodXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7048;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridFocalDistanceXRG];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x704C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Grid */


/********************************************************************************/
/*										*/
/*	init_XRayImage : initializes the elements of the module			*/
/*	XRay Image 								*/
/*										*/
/********************************************************************************/

void
init_XRayImage (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papFrameIncrementPointerXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompressionXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papImageTypeXR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelIntensityRelationshipXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesperPixelXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanOptionsXR];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequenceXR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequenceXR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRWavePointerXR];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6040;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceXR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDerivationDescriptionXR];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2111;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingDescriptionXR];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCalibrationObjectXR];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Image */


/********************************************************************************/
/*										*/
/*	init_XRayTable : initializes the elements of the module		*/
/*	XRay Table 							*/
/*										*/
/********************************************************************************/

void
init_XRayTable (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papTableMotion];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1134;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableVerticalIncrement];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1135;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableLongitudinalIncrement];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1137;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableLateralIncrement];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1136;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableAngle];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1138;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Table */


/********************************************************************************/
/*										*/
/*	init_XRayTomographyAcquisition : initializes the elements of the module	*/
/*	XRay Tomography Acquisition 						*/
/*										*/
/********************************************************************************/

void
init_XRayTomographyAcquisition (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papTornoTypeXRTA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1490;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoClassXRTA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1491;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoLayerHeightXRTA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1460;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoAngleXRTA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1470;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoTimeXRTA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1480;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTornosynthesisSourceImagesXRTA];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1495;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRay Tomography Acquisition */


/********************************************************************************/
/*										*/
/*	init_XRFPositioner : initializes the elements of the module	*/
/*	XRF Positioner pModule 						*/
/*										*/
/********************************************************************************/

void
init_XRFPositioner (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papDistanceSourceToDetector];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoPatient];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEstimatedRadiographicMagnificationFactor];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1114;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColumnAngulation];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1450;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_XRFPositioner */


