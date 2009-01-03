/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyInitGroups3.c                                            */
/*	Function : contains the groups initialisation functions                 */
/********************************************************************************/

#ifdef Mac
#pragma segment papy3InitGroup
#endif

/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif



/********************************************************************************/
/*										*/
/*	init_group2 : initializes the elements of the group 2			*/
/*										*/
/********************************************************************************/

void
init_group2 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFileMetaInformationVersionGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0001;
  theWrkP->length = 0L;
  theWrkP->vr = OB;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMediaStorageSOPClassUIDGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMediaStorageSOPInstanceUIDGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransferSyntaxUIDGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImplementationClassUIDGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImplementationVersionNameGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSourceApplicationEntityTitleGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrivateInformationCreatorUIDGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrivateInformationGr];
  theWrkP->group = 0x0002;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = OB;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2 */


/********************************************************************************/
/*										*/
/*	init_group4 : initializes the elements of the group 4			*/
/*										*/
/********************************************************************************/

void
init_group4 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilesetIDGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFileIDofFilesetDescriptorFileGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1141;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-8";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFormatofFilesetDescriptorFileGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1142;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOffsetofTheFirstDirectoryRecordGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOffsetofTheLastDirectoryRecordGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilesetConsistencyFlagGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1212;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDirectoryRecordSequenceGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOffsetofNextDirectoryRecordGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRecordInuseGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1410;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1420;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDirectoryRecordTypeGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1430;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrivateRecordUIDGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1432;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFileIDGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1500;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-8";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMRDRDirectoryRecordOffsetGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1504;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPClassUIDinFileGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1510;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPInstanceUIDinFileGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1511;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedTransferSyntaxUIDinFileGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1512;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfReferencesGr];
  theWrkP->group = 0x0004;
  theWrkP->element = 0x1600;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group4 */


/********************************************************************************/
/*										*/
/*	init_group8 : initializes the elements of the group 8			*/
/*										*/
/********************************************************************************/

void
init_group8 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLengthtoEndGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0001;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecificCharacterSetGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTypeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRecognitionCodeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceCreationDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceCreationTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceCreatorUIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSOPClassUIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSOPInstanceUIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0018;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0023;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0025;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDatetimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x002A;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveTimeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0035;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataSetTypeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataSetSubtypeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0041;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNuclearMedicineSeriesTypeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAccessionNumberGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papQueryRetrieveLevelGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRetrieveAETitleGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0054;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstanceAvailabilityGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0056;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFailedSOPInstanceUIDListGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0058;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModalityGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModalitiesInStudyGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConversionTypeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0064;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationIndentTypeGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0068;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papManufacturerGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionAddressGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionCodeSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansAddressGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0092;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferringPhysiciansTelephoneNumbersGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0094;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCodeValueGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCodingSchemeDesignatorGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCodingSchemeVersionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCodeMeaningGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0104;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMappingResourceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContextGroupVersionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0106;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContextgroupLocalVersionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0107;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCodeSetExtensionFlagGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x010B;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrivateCodingSchemeCreatorUIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x010C;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCodeSetExtensionCreatorUIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x010D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContextIdentifierGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x010F;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimezoneOffsetFromUTCGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x0201;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNetworkIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStationNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyDescriptionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papProcedureCodeSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1032;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesDescriptionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x103E;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInstitutionalDepartmentNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysiciansOfRecordGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1048;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformingPhysiciansNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNameofPhysiciansReadingStudyGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOperatorsNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingDiagnosesDescriptionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingDiagnosisCodeSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1084;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papManufacturersModelNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedResultsSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudySequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStudyComponentSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSeriesSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1115;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPatientSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedVisitSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1125;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedCurveSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1145;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPClassUID8Gr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPInstanceUID8Gr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1155;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSOPClassesSupporedGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x115A;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFrameNumberGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1160;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedCalibrationSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1170;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransactionUIDGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1195;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFailureReasonGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1197;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFailedSOPSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1198;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x1199;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompression8Gr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDerivationDescriptionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2111;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSourceImageSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2112;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStageNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2120;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStageNumberGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2122;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofStagesGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2124;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewNameGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2127;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewNumberGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2128;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofEventTimersGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2129;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofViewsinStageGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x212A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEventElapsedTimesGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2130;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEventTimerNamesGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2132;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStartTrimGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2142;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStopTrimGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2143;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRecommendedDisplayFrameRateGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2144;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerPositionGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2200;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerOrientationGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2204;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicStructureGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2208;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2218;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicRegionModifierSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2228;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnatomicStructureSpaceOrRegionSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2229;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryAnatomicStructureModifierSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2230;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerPositionSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2240;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerPositionModifierSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2242;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerOrientationSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2244;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerOrientationModifierSequenceGr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x2246;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papComments8Gr];
  theWrkP->group = 0x0008;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
	// Sup.49
	
 theWrkP = &ioElem [papFrameType];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9007;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "4";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papReferencedRawDataSequence];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9121;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCreatorVersionUID];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9123;
 theWrkP->length = 0L;
 theWrkP->vr = UI;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDerivationImageSequence];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9124;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papReferringImageEvidenceSequence];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9092;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSourceImageEvidenceSequence];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9154;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPixelPresentation];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9205;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVolumetricProperties];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9206;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVolumeBasedCalculationTechnique];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9207;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papComplexImageComponent];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9208;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papAcquisitionContrast];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9209;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDerivationCodeSequence];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9215;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papReferencedGrayscalePresentationStateSequence];
 theWrkP->group = 0x0008;
 theWrkP->element = 0x9237;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;
  

} /* endof init_group8 */


/********************************************************************************/
/*										*/
/*	init_group10 : initializes the elements of the group 10			*/
/*										*/
/********************************************************************************/

void
init_group10 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsNameGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientIDGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIssuerofPatientIDGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthDateGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthTimeGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSexGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsInsurancePlanCodeSequenceGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherPatientIDsGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherPatientNamesGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsBirthNameGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1005;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsAgeGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = AS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsSizeGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsWeightGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsAddressGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInsurancePlanIdentificationGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsMothersBirthNameGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMilitaryRankGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBranchofServiceGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1081;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMedicalRecordLocatorGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMedicalAlertsGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastAllergiesGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountryofResidenceGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2150;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionofResidenceGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2152;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsTelephoneNumbersGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2154;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEthnicGroupGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOccupationGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x2180;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmokingStatusGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21A0;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdditionalPatientHistoryGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21B0;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPregnancyStatusGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21C0;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLastMenstrualDateGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21D0;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsReligiousPreferenceGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x21F0;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientCommentsGr];
  theWrkP->group = 0x0010;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group10 */


/********************************************************************************/
/*										*/
/*	init_group18 : initializes the elements of the group 18			*/
/*										*/
/********************************************************************************/

void
init_group18 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusAgentGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusAgentSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusAdministrationRouteSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBodyPartExaminedGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanningSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSequenceVariantGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanOptionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMRAcquisitionTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0023;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSequenceNameGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngioFlagGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0025;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugInformationSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugStopTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0027;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugDoseGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugCodeSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0029;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdditionalDrugSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x002A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadionuclideGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowCenterlineGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowTotalWidthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugNameGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionDrugStartTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0035;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionalTherapySequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0036;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTherapyTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0037;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterventionalStatusGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0038;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTherapyDescriptionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0039;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCineRateGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceThicknessGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papKVPGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountsAccumulatedGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTerminationConditionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEffectiveSeriesDurationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0072;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionStartConditionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0073;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionStartConditionDataGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0074;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTerminationConditionDataGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0075;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRepetitionTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEchoTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInversionTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofAveragesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0083;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagingFrequencyGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0084;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagedNucleusGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0085;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEchoNumbersGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0086;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMagneticFieldStrengthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0087;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpacingBetweenSlicesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0088;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPhaseEncodingStepsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0089;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataCollectionDiameterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEchoTrainLengthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0091;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPercentSamplingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0093;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPercentPhaseFieldofViewGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0094;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelBandwidthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x0095;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceSerialNumberGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlateIDGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceIDGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHardcopyCreationDeviceIDGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1011;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateofSecondaryCaptureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1012;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeofSecondaryCaptureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1014;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceManufacturerGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1016;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHardcopyDeviceManufacturerGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1017;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceManufacturersModelNameGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1018;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCaptureDeviceSoftwareVersionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1019;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHardcopyDeviceSoftwareVersionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x101A;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHardcopyDeviceManufacturersModelNameGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x101B;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftwareVersionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVideoImageFormatAcquiredGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1022;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDigitalImageFormatAcquiredGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1023;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papProtocolNameGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusRouteGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusVolumeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusStartTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1042;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusStopTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1043;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusTotalDoseGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSyringecountsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1045;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastFlowRatesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1046;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastFlowDurationsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1047;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusIngredientGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1048;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastBolusIngredientConcentrationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1049;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpatialResolutionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerSourceorTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1061;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNominalIntervalGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1062;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1063;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFramingTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1064;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameTimeVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1065;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameDelayGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1066;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTriggerDelayGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1067;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMultiplexgroupTimeOffsetGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1068;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerTimeOffsetGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1069;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSynchronizationTriggerGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x106A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSynchronizationChannelGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x106C;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerSamplePositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x106E;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalRouteGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalVolumeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1071;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalStartTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1072;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalStopTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1073;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadionuclideTotalDoseGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1074;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadionuclideHalfLifeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1075;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadionuclidePositronFractionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1076;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalSpecificactivityGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1077;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBeatRejectionFlagGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLowRRValueGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1081;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighRRValueGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1082;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalsAcquiredGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1083;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalsRejectedGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1084;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPVCRejectionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1085;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSkipBeatsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1086;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHeartRateGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1088;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCardiacNumberofImagesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerWindowGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1094;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionDiameterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoDetectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoPatientGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1111;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEstimatedRadiographicMagnificationFactorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1114;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGantryDetectorTiltGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1120;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGantryDetectorSlewGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1121;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableHeightGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1130;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableTraverseGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1131;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableMotionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1134;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableVerticalIncrementGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1135;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableLateralIncrementGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1136;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableLongitudinalIncrementGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1137;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1138;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x113A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationDirectionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1140;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngularPositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1141;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadialPositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1142;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanArcGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1143;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngularStepGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1144;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCenterofRotationOffsetGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1145;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationOffsetGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1146;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewShapeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1147;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewDimensionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1149;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1150;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXrayTubeCurrentGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1151;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureinmAsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1153;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAveragePulseWidthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1154;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiationSettingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1155;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRectificationTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1156;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiationModeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x115A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageAreaDoseProductGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x115E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofFiltersGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1161;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntensifierSizeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1162;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagerPixelSpacingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1164;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1166;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGeneratorPowerGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1170;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorgridNameGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1180;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1181;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocalDistanceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1182;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXFocusCenterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1183;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papYFocusCenterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1184;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocalSpotsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1190;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnodeTargetMaterialGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1191;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBodyPartThicknessGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x11A0;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompressionForceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x11A2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateofLastCalibrationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeofLastCalibrationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConvolutionKernelGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1210;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papUpperLowerPixelValuesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1240;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papActualFrameDurationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1242;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountRateGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1243;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreferredPlaybackSequencingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1244;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReceivingCoilGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1250;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransmittingCoilGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1251;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlateTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1260;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhosphorTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1261;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanVelocityGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1300;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWholeBodyTechniqueGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1301;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScanLengthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1302;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionMatrixGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1310;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "4";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseEncodingDirectionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1312;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFlipAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1314;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVariableFlipAngleFlagGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1315;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSARGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1316;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papdBdtGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1318;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingDescriptionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionDeviceProcessingCodeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1401;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCassetteOrientationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1402;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCassetteSizeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1403;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposuresonPlateGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1404;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRelativeXrayExposureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1405;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColumnAngulationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1450;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoLayerHeightGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1460;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1470;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1480;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1490;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTornoClassGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1491;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTornosynthesisSourceImagesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1495;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerMotionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1500;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1508;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerPrimaryAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1510;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerSecondaryAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1511;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerPrimaryAngleIncrementGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1520;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionerSecondaryAngleIncrementGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1521;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorPrimaryAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1530;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorSecondaryAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1531;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterShapeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1600;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterLeftVerticalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1602;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterRightVerticalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1604;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterUpperHorizontalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1606;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterLowerHorizontalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1608;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCenterofCircularShutterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1610;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiusofCircularShutterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1612;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerticesofthePolygonalShutterGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1620;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterPaddingValueGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1622;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papShutterOverlayGroupGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1623;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorShapeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1700;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorLeftVerticalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1702;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorRightVerticalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1704;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorUpperHorizontalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1706;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollimatorLowerHorizontalEdgeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1708;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCenterofCircularCollimatorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1710;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiusofCircularCollimatorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1712;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerticesofthePolygonalCollimatorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1720;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionTimeSynchronizedGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1800;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSourceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1801;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeDistributionProtocolGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x1802;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPageNumberVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2001;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameLabelVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFramePrimaryAngleVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2003;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameSecondaryAngleVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2004;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceLocationVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2005;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDisplayWindowLabelVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2006;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNominalScannedPixelSpacingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2010;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDigitizingDeviceTransportDirectionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationOfScannedFilmGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x2030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papComments18Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOutputPowerGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5000;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerDataGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFocusDepthGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreprocessingFunctionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPostprocessingFunctionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5021;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMechanicalIndexGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papThermalIndexGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5024;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCranialThermalIndexGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftTissueThermalIndexGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5027;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftTissuefocusThermalIndexGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftTissuesurfaceThermalIndexGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5029;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDynamicRangeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5030;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTotalGainGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5040;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDepthofScanFieldGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5050;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientPositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewPositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5101;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papProjectionEponymousNameCodeSequenceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5104;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTransformationMatrixGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5210;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "6";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageTranslationVectorGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x5212;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSensitivityGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6000;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSequenceofUltrasoundRegionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6011;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionSpatialFormatGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6012;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionDataTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6014;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionFlagsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6016;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMinX0Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6018;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMinY0Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x601A;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMaxX1Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x601C;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRegionLocationMaxY1Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x601E;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencePixelX0Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6020;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencePixelY0Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6022;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalUnitsXDirectionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6024;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalUnitsYDirectionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6026;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencePixelPhysicalValueXGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6028;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencePixelPhysicalValueYGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x602A;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalDeltaXGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x602C;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicalDeltaYGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x602E;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerFrequencyGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6030;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransducerTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6031;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPulseRepetitionFrequencyGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6032;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDopplerCorrectionAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6034;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSterringAngleGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6036;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDopplerSampleVolumeXPositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6038;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDopplerSampleVolumeYPositionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x603A;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTMLinePositionX0Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x603C;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTMLinePositionY0Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x603E;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTMLinePositionX1Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6040;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTMLinePositionY1Gr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6042;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelComponentOrganizationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6044;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelComponentMaskGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6046;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelComponentRangeStartGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6048;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelComponentRangeStopGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x604A;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelComponentPhysicalUnitsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x604C;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelComponentDataTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x604E;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTableBreakPointsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6050;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableofXBreakPointsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6052;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableofYBreakPointsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6054;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTableEntriesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6056;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableofPixelValuesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x6058;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTableofParameterValuesGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x605A;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorConditionsNominalFlagGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7000;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorTemperatureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7001;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorTypeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorConfigurationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7005;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorDescriptionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7006;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorModeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7008;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorIDGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x700A;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateofLastDetectorCalibrationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x700C;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeofLastDetectorCalibrationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x700E;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposuresonDetectorSinceLastCalibrationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7010;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposuresonDetectorSinceManufacturedGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7011;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorTimeSinceLastExposureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveTimeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7014;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActivationOffsetFromExposureGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7016;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorBinningGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x701A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorElementPhysicalSizeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7020;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorElementSpacingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveShapeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7024;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveDimensionsGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorActiveOriginGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewOriginGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewRotationGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFieldofViewHorizontalFlipGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7034;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridAbsorbingMaterialGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7040;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridSpacingMaterialGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7041;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridThicknessGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7042;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridPitchGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridAspectRatioGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7046;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridPeriodGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7048;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGridFocalDistanceGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x704C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterMaterialGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7050;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterThicknessMinimumGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterThicknessMaximumGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7054;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureControlModeGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureControlModeDescriptionGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7062;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureStatusGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7064;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhototimerSettingGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x7065;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposureTimeInMSGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x8150;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXRayTubeCurrentInMAGr];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x8151;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

	// sup.49

 theWrkP = &ioElem [papContentQualification];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9004;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPulseSequenceName];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9005;
 theWrkP->length = 0L;
 theWrkP->vr = SH;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRImagingModifierSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9006;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papEchoPulseSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9008;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papInversionRecovery];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9009;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFlowCompensation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9010;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMultipleSpinEcho];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9011;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMultiPlanarExcitation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9012;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPhaseContrast];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9014;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTimeOfFlightContrast];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9015;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpoiling];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9016;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSteadyStatePulseSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9017;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papEchoPlanarPulseSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9018;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTagAngleFirstAxis];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9019;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMagnetizationTransfer];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9020;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papT2Preparation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9021;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papBloodSignalNulling];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9022;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSaturationRecovery];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9024;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectrallySelectedSuppression];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9025;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectrallySelectedExcitation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9026;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpatialPreSaturation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9027;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTagging];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9028;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papOversamplingPhase];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9029;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTagSpacingFirstDimension];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9030;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papGeometryOfKSpaceTraversal];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9032;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSegmentedKSpaceTraversal];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9033;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRectilinearPhaseEncodeReordering];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9034;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTagThickness];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9035;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPartialFourierDirection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9036;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papGatingSynchronizationTechnique];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9037;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papReceiveCoilManufacturerName];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9041;
 theWrkP->length = 0L;
 theWrkP->vr = LO;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRReceiveCoilSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9042;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papReceiveCoilType];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9043;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papQuadratureReceiveCoil];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9044;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMultiCoilDefinitionSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9045;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMultiCoilConfiguration];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9046;
 theWrkP->length = 0L;
 theWrkP->vr = LO;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMultiCoilElementName];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9047;
 theWrkP->length = 0L;
 theWrkP->vr = SH;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMultiCoilElementUsed];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9048;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRTransmitCoilSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9049;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTransmitCoilManufacturerName];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9050;
 theWrkP->length = 0L;
 theWrkP->vr = LO;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTransmitCoilType];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9051;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectralWidth];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9052;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papChemicalShiftReference];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9053;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVolumeLocalizationTechnique];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9054;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRAcquisitionFrequencyEncodingSteps];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9058;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDecoupling];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9059;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDecoupledNucleus];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9060;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDecouplingFrequency];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9061;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDecouplingMethod];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9062;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDecouplingChemicalShiftReference];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9063;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papKSpaceFiltering];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9064;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTimeDomainFiltering];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9065;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papNumberOfZeroFills];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9066;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papBaselineCorrection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9067;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCardiacRRIntervalSpecified];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9070;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papAcquisitionDuration];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9073;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameAcquisitionDatetime];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9074;
 theWrkP->length = 0L;
 theWrkP->vr = DT;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDiffusionDirectionality];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9075;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDiffusionGradientDirectionSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9076;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papParallelAcquisition];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9077;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papParallelAcquisitionTechnique];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9078;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papInversionTimes];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9079;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-n";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMetaboliteMapDescription];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9080;
 theWrkP->length = 0L;
 theWrkP->vr = ST;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPartialFourier];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9081;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papEffectiveEchoTime];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9082;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papChemicalShiftSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9084;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCardiacSignalSource];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9085;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDiffusionBValue];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9087;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDiffusionGradientOrientation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9089;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "3";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVelocityEncodingDirection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9090;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "3";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVelocityEncodingMinimumValue];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9091;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papNumberOfKSpaceTrajectories];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9093;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCoverageOfKSpace];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9094;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectroscopyAcquisitionPhaseRows];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9095;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papParallelReductionFactorInPlane];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9096;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTransmitterFrequency];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9098;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papResonantNucleus];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9100;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrequencyCorrection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9101;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRSpectroscopyFOVGeometrySequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9103;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSlabThickness];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9104;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSlabOrientation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9105;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "3";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMidSlabPosition];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9106;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "3";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRSpatialSaturationSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9107;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRTimingAndRelatedParametersSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9112;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMREchoSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9114;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRModifierSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9115;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRDiffusionSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9117;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCardiacTriggerSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9118;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRAveragesSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9119;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRFOVGeometrySequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9125;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectroscopyAcquisitionDataColumns];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9127;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVolumeLocalizationSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9126;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDiffusionAnisotropyType];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9147;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameReferenceDatetime];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9151;
 theWrkP->length = 0L;
 theWrkP->vr = DT;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMetaboliteMapSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9152;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papParallelReductionFactorOutOfPlane];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9155;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectroscopyAcquisitionOutOfPlanePhaseSteps];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9159;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papBulkMotionStatus];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9166;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papParallelReductionFactorSecondInPlane];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9168;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCardiacBeatRejectionTechnique];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9169;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRespiratoryMotionCompensation];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9170;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRespiratorySignalSource];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9171;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papBulkMotionCompensationTechnique];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9172;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papBulkMotionSignal];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9173;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papApplicableSafetyStandardAgency];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9174;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papApplicableSafetyStandardVersion];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9175;
 theWrkP->length = 0L;
 theWrkP->vr = LO;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papOperationModeSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9176;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papOperatingModeType];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9177;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papOperationMode];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9178;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpecificAbsorptionRateDefinition];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9179;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papGradientOutputType];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9180;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpecificAbsorptionRateValue];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9181;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papGradientOutput];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9182;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFlowCompensationDirection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9183;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTaggingDelay];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9184;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papChemicalShiftsMinimumIntegrationLimit];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9195;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papChemicalShiftsMaximumIntegrationLimit];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9196;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRVelocityEncodingSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9197;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFirstOrderPhaseCorrection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9198;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papWaterReferencedPhaseCorrection];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9199;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRSpectroscopyAcquisitionType];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9200;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRespiratoryMotionStatus];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9214;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papVelocityEncodingMaximumValue];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9217;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTagSpacingSecondDimension];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9218;
 theWrkP->length = 0L;
 theWrkP->vr = SS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTagAngleSecondAxis];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9219;
 theWrkP->length = 0L;
 theWrkP->vr = SS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameAcquisitionDuration];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9220;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRImageFrameTypeSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9226;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRSpectroscopyFrameTypeSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9227;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRAcquisitionPhaseEncodingStepsInPlane];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9231;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papMRAcquisitionPhaseEncodingStepsOutOfPlane];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9232;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpectroscopyAcquisitionPhaseColumns];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9234;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papCardiacMotionStatus];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9236;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSpecificAbsorptionRateSequence];
 theWrkP->group = 0x0018;
 theWrkP->element = 0x9239;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

  theWrkP = &ioElem [papRevolutionTime];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x9305;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSingleCollimationWidth];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x9306;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTotalCollimationWidth];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x9307;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableSpeed];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x9309;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableFeedPerRotation];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x9310;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSpiralPitchFactor];
  theWrkP->group = 0x0018;
  theWrkP->element = 0x9311;
  theWrkP->length = 0L;
  theWrkP->vr = FD;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
} /* endof init_group18 */


/********************************************************************************/
/*										*/
/*	init_group20 : initializes the elements of the group 20			*/
/*										*/
/********************************************************************************/

void
init_group20 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyInstanceUIDGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesInstanceUIDGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyIDGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIsotopeNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntervalNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSlotNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0017;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngleNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0018;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papItemNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0019;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientationGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLUTNumberGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagePosition20Gr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagePositionPatientGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageOrientationGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0035;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageOrientationPatientGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0037;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "6";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLocationGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameofReferenceUIDGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLateralityGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageLateralityGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageGeometryTypeGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskingImageGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemporalPositionIdentifierGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTemporalPositionsGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemporalResolutionGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSeriesinStudyGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionsinSeriesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagesinAcquisitionGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1002;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagesinSeriesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1003;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "0";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitioninStudyGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagesinStudyGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1005;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "0";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferenceGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPositionReferenceIndicatorGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceLocationGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherStudyNumbersGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPatientRelatedStudiesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPatientRelatedSeriesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPatientRelatedImagesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1204;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofStudyRelatedSeriesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1206;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofStudyRelatedImagesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1208;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofSeriesRelatedImagesGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x1209;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSourceImageIDsGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3100;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifyingDeviceIDGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3401;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifiedImageIDGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3402;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifiedImageDateGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3403;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifyingDeviceManufacturerGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3404;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifiedImageTimeGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3405;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifiedImageDescriptionGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x3406;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageCommentsGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOriginalImageIdentificationGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x5000;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOriginalImageIdentificationNomenclatureGr];
  theWrkP->group = 0x0020;
  theWrkP->element = 0x5002;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

	// SUP.49

 theWrkP = &ioElem [papStackID];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9056;
 theWrkP->length = 0L;
 theWrkP->vr = SH;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papInStackPositionNumber];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9057;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameAnatomySequence];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9071;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameLaterality];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9072;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameContentSequence];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9111;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPlanePositionSequence];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9113;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPlaneOrientationSequence];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9116;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTemporalPositionIndex];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9128;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papTriggerDelayTime];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9153;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameAcquisitionNumber];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9156;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDimensionIndexValues];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9157;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1-n";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameComments];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9158;
 theWrkP->length = 0L;
 theWrkP->vr = LT;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papConcatenationUID];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9161;
 theWrkP->length = 0L;
 theWrkP->vr = UI;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papInConcatenationNumber];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9162;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papInConcatenationTotalNumber];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9163;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDimensionOrganizationUID];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9164;
 theWrkP->length = 0L;
 theWrkP->vr = UI;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDimensionIndexPointer];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9165;
 theWrkP->length = 0L;
 theWrkP->vr = AT;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFunctionalGroupSequencePointer];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9167;
 theWrkP->length = 0L;
 theWrkP->vr = AT;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDimensionIndexPrivateCreator];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9213;
 theWrkP->length = 0L;
 theWrkP->vr = LO;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDimensionOrganizationSequence];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9221;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDimensionSequence];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9222;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papConcatenationFrameOffsetNumber];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9228;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFunctionalGroupPrivateCreator];
 theWrkP->group = 0x0020;
 theWrkP->element = 0x9238;
 theWrkP->length = 0L;
 theWrkP->vr = LO;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;
  
} /* endof init_group20 */



/********************************************************************************/
/*										*/
/*	init_group28 : initializes the elements of the group 28			*/
/*										*/
/********************************************************************************/

void
init_group28 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplesperPixelGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhotometricInterpretationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageDimensionsGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlanarConfigurationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofFramesGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameIncrementPointerGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRowsGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColumnsGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlanesGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papUltrasoundColorDataPresentGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelSpacingGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papZoomFactorGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papZoomCenterGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelAspectRatioGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageFormatGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papManipulatedImageGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCorrectedImageGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompressionCodeGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsAllocatedGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitsStoredGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHighBitGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelRepresentationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmallestValidPixelValueGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0104;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestValidPixelValueGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmallestImagePixelValueGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0106;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestImagePixelValueGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0107;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmallestPixelValueinSeriesGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0108;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestPixelValueinSeriesGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0109;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmallestImagePixelValueinPlaneGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLargestImagePixelValueinPlaneGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelPaddingValueGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageLocationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = SS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papQualityControlImageGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBurnedInAnnotationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x0301;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelIntensityRelationshipGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelIntensityRelationshipSignGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = SS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWindowCenterGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWindowWidthGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1051;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleInterceptGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleSlopeGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRescaleTypeGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1054;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWindowCenterWidthExplanationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1055;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGrayScaleGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRecommendedViewingModeGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1090;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGrayLookupTableDescriptorGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteColorLookupTableDescriptorGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteColorLookupTableDescriptorGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteColorLookupTableDescriptorGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPaletteColorLookupTableUIDGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1199;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGrayLookupTableDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRedPaletteCLUTDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGreenPaletteCLUTDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBluePaletteCLUTDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSegmentedRedPaletteColorLookupTableDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1221;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSegmentedGreenPaletteColorLookupTableDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1222;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSegmentedBluePaletteColorLookupTableDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1223;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImplantPresentGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1300;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPartialViewGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1350;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPartialViewDescriptionGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x1351;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLossyImageCompressionGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papLossyImageCompressionRatioGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x2112;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papModalityLUTSequenceGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLUTDescriptorGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLUTExplanationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3003;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModalityLUTTypeGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3004;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papLUTDataGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3006;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVOILUTSequenceGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSoftcopyVOILUTSequenceGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x3110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papComments28Gr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBiPlaneAcquisitionSequenceGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x5000;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRepresentativeFrameNumberGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameNumbersofInterestGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6020;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFramesofInterestDescriptionGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6022;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskPointersGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6030;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRWavePointerGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6040;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskSubtractionSequenceGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskOperationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6101;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papApplicableFrameRangeGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskFrameNumbersGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6110;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContrastFrameAveragingGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6112;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskSubpixelShiftGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6114;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTIDOffsetGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6120;
  theWrkP->length = 0L;
  theWrkP->vr = SS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskOperationExplanationGr];
  theWrkP->group = 0x0028;
  theWrkP->element = 0x6190;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
	// SUP.49
	
 theWrkP = &ioElem [papDataPointRows];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9001;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDataPointColumns];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9002;
 theWrkP->length = 0L;
 theWrkP->vr = UL;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSignalDomain];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9003;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1-2";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papLargestMonochromePixelValue];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9099;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papDataRepresentation];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9108;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPixelMatrixSequence];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9110;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papFrameVOILUTSequence];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9132;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPixelValueTransformationSequence];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9145;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papSignalDomainRows];
 theWrkP->group = 0x0028;
 theWrkP->element = 0x9235;
 theWrkP->length = 0L;
 theWrkP->vr = CS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;
 
} /* endof init_Group28 */


/********************************************************************************/
/*										*/
/*	init_group32 : initializes the elements of the group 32			*/
/*										*/
/********************************************************************************/

void
init_group32 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyStatusIDGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyPriorityIDGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyIDIssuerGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyVerifiedDateGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyVerifiedTimeGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyReadDateGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyReadTimeGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x0035;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStartDateGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStartTimeGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStopDateGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyStopTimeGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1011;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyLocationGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStudyLocationAETitlesGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1021;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReasonforStudyGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestingPhysicianGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1032;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestingServiceGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1033;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyArrivalDateGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyArrivalTimeGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyCompletionDateGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyCompletionTimeGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1051;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyComponentStatusIDGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1055;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureDescriptionGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureCodeSequenceGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1064;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedContrastAgentGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStudyCommentsGr];
  theWrkP->group = 0x0032;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group32 */


/********************************************************************************/
/*										*/
/*	init_group38 : initializes the elements of the group 38			*/
/*										*/
/********************************************************************************/

void
init_group38 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPatientAliasSequenceGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVisitStatusIDGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmissionIDGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIssuerofAdmissionIDGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRouteofAdmissionsGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledAdmissionDateGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001A;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledAdmissionTimeGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001B;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledDischargeDateGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001C;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledDischargeTimeGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001D;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledPatientInstitutionResidenceGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x001E;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingDateGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdmittingTimeGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDischargeDateGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDischargeTimeGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDischargeDiagnosisDescriptionGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDischargeDiagnosisCodeSequenceGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0044;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecialNeedsGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurrentPatientLocationGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientsInstitutionResidenceGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0400;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientStateGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVisitCommentsGr];
  theWrkP->group = 0x0038;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group38 */


/********************************************************************************/
/*										*/
/*	init_group3A : initializes the elements of the group 3A 		*/
/*										*/
/********************************************************************************/

void
init_group3A (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformOriginalityGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfWaveformChannelsGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfWaveformSamplesGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSamplingFrequencyGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x001A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMultiplexGroupLabelGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelDefinitionSequenceGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformChannelNumberGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelLabelGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0203;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelStatusGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0205;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelSourceSequenceGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0208;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelSourceModifiersSequenceGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0209;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSourceWaveformSequenceGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x020A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelDerivationDescriptionGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x020C;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelSensitivityGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0210;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelSensitivityUnitsSequenceGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0211;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelSensitivityCorrectionFactorGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0212;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelBaselineGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0213;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelTimeSkewGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0214;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelSampleSkewGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0215;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelOffsetGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0218;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformBitsStoredGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x021A;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterLowFrequencyGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0220;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilterHighFrequencyGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0221;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNotchFilterFrequencyGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0222;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNotchFilterBandwidthGr];
  theWrkP->group = 0x003A;
  theWrkP->element = 0x0223;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group3A */


/********************************************************************************/
/*										*/
/*	init_group40 : initializes the elements of the group 40 		*/
/*										*/
/********************************************************************************/

void
init_group40 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStationAETitleGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0001;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepStartDateGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepStartTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepEndDateGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepEndTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledPerformingPhysiciansNameGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepDescriptionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0007;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledActionItemCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepIDGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStageCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStationNameGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepLocationGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreMedicationGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x00012;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepStatusGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x00020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledProcedureStepSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStandaloneSOPInstanceSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedStationAETitleGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0241;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedStationNameGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0242;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedLocationGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0243;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepStartDateGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0244;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepStartTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0245;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepEndDateGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0250;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepEndTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0251;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepStatusGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0252;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepIDGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0253;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepDescriptionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0254;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureStepTypeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0255;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedActionItemSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0260;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScheduledStepAttributesSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0270;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedAttributesSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0275;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCommentsOnThePerformedProcedureStepsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0280;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papQuantitySequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0293;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papQuantityGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0294;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMeasuringUnitsSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0295;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBillingItemSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0296;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTotalTimeOfFluoroscopyGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTotalNumberOfExposuresGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0301;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEntranceDoseGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0302;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExposedAreaGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0303;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoEntranceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0306;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistanceSourcetoSupportGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0307;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCommentsonRadiationDoseGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0310;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXRayOutputGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0312;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHalfValueLayerGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0314;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrganDoseGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0316;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrganExposedGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0318;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBillingProcedureStepSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0320;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmConsumptionSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0321;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBillingSuppliesAndDevicesSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0324;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedProcedureStepSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0330;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedSeriesSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0340;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCommentsontheScheduledProcedureStepGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0400;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecimenAccessionNumberGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x050A;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecimenSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0550;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecimenIdentifierGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0551;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionContextSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0555;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAcquisitionContextDescriptionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x0556;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSpecimenTypeCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x059A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSlideIdentifierGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x06FA;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageCenterPointCoordinatesSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x071A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papXOffsetInSlideCoordinateSystemGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x072A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papYOffsetInSlideCoordinateSystemGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x073A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papZOffsetInSlideCoordinateSystemGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x074A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelSpacingSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x08D8;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoordinateSystemAxisCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x08DA;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMeasurementUnitsCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x08EA;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureIDGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReasonfortheRequestedProcedureGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1002;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedurePriorityGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1003;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientTransportArrangementsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureLocationGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1005;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlacerOrderNumberProcedureGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1006;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFillerOrderNumberProcedureGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1007;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConfidentialityCodeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1008;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReportingPriorityGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1009;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNamesofIntendedRecipientsofResultsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedProcedureCommentsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReasonfortheImagingServiceRequestGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2001;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIssueDateofImagingServiceRequestGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2004;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIssueTimeofImagingServiceRequestGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2005;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrderEnteredByGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2008;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrderEnterersLocationGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2009;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrderCallbackPhoneNumberGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2010;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPlacerOrderNumberImagingServiceRequestGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2016;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFillerOrderNumberImagingServiceRequestGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2017;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagingServiceRequestCommentsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x2400;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConfidentialityConstraintonPatientDataDescriptionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x3001;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEntranceDoseInMyGyGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0x8302;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRelationshipTypeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA010;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerifyingOrganizationGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA027;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerificationDateTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA030;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papObservationDateTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA032;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papValueTypeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConceptNameCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA043;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContinuityOfContentGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA050;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerifyingObserverSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA073;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerifyingObserverNameGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA075;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerifyingObserverIdentificationCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA088;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedWaveformChannelsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA0B0;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA120;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDateGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA121;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA122;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPersonNameGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA123;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papUIDGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA124;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemporalRangeTypeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA130;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSamplePositionsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA132;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencesFrameNumbersGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA136;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedTimeOffsetsGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA138;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedDatetimeGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA13A;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTextValueGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA160;
  theWrkP->length = 0L;
  theWrkP->vr = UT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConceptCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA168;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationGroupNumberGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA180;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papModifierCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA195;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMeasuredValueSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA300;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumericValueGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA30A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPredecessorDocumentsSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA360;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedRequestSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA370;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPerformedProcedureCodeSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA372;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurentRequestedProcedureEvidenceSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA375;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPertinentOtherEvidenceSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA385;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompletionFlagGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA491;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompletionFlagDescriptionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA492;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papVerificationFlagGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA493;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContentTemplateSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA504;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIdenticalDocumentsSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA525;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papContentSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xA730;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationSequenceGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xB020;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemplateIdentifierGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB00;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemplateVersionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB06;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemplateLocalVersionGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB07;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTemplateExtensionFlagGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB0B;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [paptemplateExtensionOrganizationUIDGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB0C;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [paptemplateExtensionCreatorUIDGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB0D;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedContentItemIdentifierGr];
  theWrkP->group = 0x0040;
  theWrkP->element = 0xDB73;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

 theWrkP = &ioElem [papRealWorldValueMappingSequence];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9096;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papLUTLabel];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9210;
 theWrkP->length = 0L;
 theWrkP->vr = SS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRealWorldValueLUTLastValueMapped];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9211;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRealWorldValueLUTData];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9212;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1-n";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRealWorldValueLUTFirstValueMapped];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9216;
 theWrkP->length = 0L;
 theWrkP->vr = USS;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRealWorldValueIntercept];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9224;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papRealWorldValueSlope];
 theWrkP->group = 0x0040;
 theWrkP->element = 0x9225;
 theWrkP->length = 0L;
 theWrkP->vr = FD;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;
 
} /* endof init_group40 */


/********************************************************************************/
/*										*/
/*	init_group41 : initializes the elements of the group 41			*/
/*										*/
/********************************************************************************/

void
init_group41 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOwnerIDGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 1;
  theWrkP->value = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
  theWrkP->value->a = (char *) ecalloc3 ((PapyULong) 12, (PapyULong) sizeof (char));
  strcpy (theWrkP->value->a, "PAPYRUS 3.0");

  theWrkP = &ioElem [papComments41Gr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPointerSequenceGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagePointerGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1011;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelOffsetGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1012;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageIdentifierSequenceGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1013;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExternalPAPYRUSFileReferenceSequenceGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1014;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofimagesGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1015;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPClassUID41Gr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1021;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedSOPInstanceUID41Gr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1022;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFileNameGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1031;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFilePathGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1032;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSOPClassUIDGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1041;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageSOPInstanceUIDGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1042;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageSequenceGr];
  theWrkP->group = 0x0041;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group41 */


/********************************************************************************/
/*										*/
/*	init_group50 : initializes the elements of the group 50			*/
/*										*/
/********************************************************************************/

void
init_group50 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCalibrationObjectGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceSequenceGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceLengthGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceDiameterGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceDiameterUnitsGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0017;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceVolumeGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0018;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIntermarkerDistanceGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0019;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeviceDescriptionGr];
  theWrkP->group = 0x0050;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group50 */
  
  
/********************************************************************************/
/*										*/
/*	init_group54 : initializes the elements of the group 54 		*/
/*										*/
/********************************************************************************/

void
init_group54 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofEnergyWindowsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowRangeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0013;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowLowerLimitGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowUpperLimitGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResidualSyringeCountsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0017;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowNameGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0018;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofDetectorsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPhasesGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0031;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofFramesinPhaseGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhaseDelayGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0036;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPauseBetweenFramesGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0038;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofRotationsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRotationInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofFramesinRotationGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0053;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRRIntervalVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofRRIntervalsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGatedInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0063;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSlotVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTimeSlotsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSlotInformationSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0072;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSlotTimeGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0073;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofSlicesGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAngularViewVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTimeSliceVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfTimeSlicesGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStartAngleGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofDetectorMotionGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTriggerVectorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0210;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofTriggersinPhaseGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0211;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papViewModifierCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0222;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadionuclideCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAdministrationRouteCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0302;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRadiopharmaceuticalCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0304;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCalibrationDataSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0306;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEnergyWindowNumberGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0308;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T1C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageIDGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0400;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientationCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0410;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientOrientationModifierCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0412;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPatientGantryRelationshipCodeSequenceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x0414;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T2;
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

  theWrkP = &ioElem [papUnitsGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountsSourceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReprojectionMethodGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRandomsCorrectionMethodGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAttenuationCorrectionMethodGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDecayCorrectionGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReconstructionMethodGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorLinesOfResponseUsedGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1104;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScatterCorrectionMethodGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1105;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxialAcceptanceGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxialMashGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTransverseMashGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDetectorElementSizeGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoincidenceWindowWidthGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1210;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCountsTypeGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1220;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFrameReferenceTimeGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1300;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrimaryCountsAccumulatedGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1310;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSecondaryCountsAccumulatedGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1311;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSliceSensitivityFactorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1320;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDecayFactorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1321;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDoseCalibrationFactorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1322;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papScatterFractionFactorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1323;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeadTimeFactorGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1324;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageIndexGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1330;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCountsIncludedGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1400;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDeadTimeCorrectionFlagGr];
  theWrkP->group = 0x0054;
  theWrkP->element = 0x1401;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_Group54 */

 
/********************************************************************************/
/*										*/
/*	init_group60 : initializes the elements of the group 60 		*/
/*										*/
/********************************************************************************/

void
init_group60 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papHistogramSequenceGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papHistogramNumberofBinsGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHistogramFirstBinValueGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3004;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHistogramLastBinValueGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3006;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHistogramBinWidthGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3008;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHistogramExplanationGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3010;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papHistogramDataGr];
  theWrkP->group = 0x0060;
  theWrkP->element = 0x3020;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group60 */
   
  
/********************************************************************************/
/*										*/
/*	init_group88 : initializes the elements of the group 70			*/
/*										*/
/********************************************************************************/

void
init_group70 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicAnnotationSequenceGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0001;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicLayerGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBoundingBoxAnnotationUnitsGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnchorPointAnnotationUnitsGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicAnnotationUnitsGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papUnformattedTexValueGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTextObjectSequenceGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBoundingBoxTopLeftHandCornerGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBoundingBoxBottomRightHandCornerGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBoundingBoxTextHorizontalJustificationGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnchorPoint70Gr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnchorPointVisibilityGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicDimensionsGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfGraphicPointsGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicDataGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "2-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicTypeGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0023;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicFilledGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageHorizontalFlipGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0041;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageRotationGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDisplayedAreaTopLeftHandCornerGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDisplayedAreaBottomRightHandCornerGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0053;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDisplayedAreaSelectionSequenceGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x005A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicLayerSequenceGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicLayerOrderGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicLayerRecommendedDisplayGrayscaleValueGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0066;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicLayerRecommendedDisplayRGBValueGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0067;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papGraphicLayerDescriptionGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0068;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationLabelGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationDescriptionGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0081;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationCreationDateGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationCreationTimeGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0083;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationCreatorsNameGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0084;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationSizeModeGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationPixelSpacingGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationPixelAspectRationGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationPixelMagnificationRatioGr];
  theWrkP->group = 0x0070;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group70 */
   
  
/********************************************************************************/
/*										*/
/*	init_group88 : initializes the elements of the group 88			*/
/*										*/
/********************************************************************************/

void
init_group88 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStorageMediaFilesetIDGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papStorageMediaFilesetUIDGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T2C;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIconImageSequenceGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTopicTitleGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0904;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTopicSubjectGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0906;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTopicAuthorGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0910;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTopicKeyWordsGr];
  theWrkP->group = 0x0088;
  theWrkP->element = 0x0912;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-32";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_group88 */

/********************************************************************************/
/*										*/
/*	init_group100 : initializes the elements of the group 100		*/
/*										*/
/********************************************************************************/

void
init_group100 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x0100;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSOPInstanceStatusGr];
  theWrkP->group = 0x0100;
  theWrkP->element = 0x0410;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papSOPAuthorizationDateAndTimeGr];
  theWrkP->group = 0x0100;
  theWrkP->element = 0x0420;
  theWrkP->length = 0L;
  theWrkP->vr = DT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSOPAuthorizationCommentGr];
  theWrkP->group = 0x0100;
  theWrkP->element = 0x0424;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAuthorizationEquipmentCertificationNumberGr];
  theWrkP->group = 0x0100;
  theWrkP->element = 0x0426;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
} /* endof init_group100 */


/********************************************************************************/
/*										*/
/*	init_group2000 : initializes the elements of the group 2000		*/
/*										*/
/********************************************************************************/

void
init_group2000 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfCopiesGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterConfigurationSequenceGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x001E;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintPriorityGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMediumTypeGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmDestinationGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmSessionLabelGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMemoryAllocationGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaximumMemoryAllocationGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0061;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papColorImagePrintingFlagGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCollationFlagGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0063;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationFlagGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0065;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageOverlayFlagGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0067;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationLUTFlagGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0069;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageBoxPresentationLUTFlagGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x006A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMemoryBitDepthGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintingBitDepthGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x00A1;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMediaInstalledSequenceGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x00A2;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherMediaInstalledSequenceGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x00A4;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSupportedImageDisplayFormatsSequenceGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x00A8;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFilmBoxSequenceGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedStoredPrintSequenceGr];
  theWrkP->group = 0x2000;
  theWrkP->element = 0x0510;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2000 */


/********************************************************************************/
/*										*/
/*	init_group2010 : initializes the elements of the group 2010		*/
/*										*/
/********************************************************************************/

void
init_group2010 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageDisplayFormatGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationDisplayFormatIDGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmOrientationGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmSizeIDGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMagnificationTypeGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSmoothingTypeGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDefaultMagnificationTypeGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x00A6;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherMagnificationTypesAvailableGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x00A7;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDefaultSmoothingTypeGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x00A8;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOtherSmoothingTypesAvailableGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x00A9;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBorderDensityGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papEmptyImageDensityGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMinDensityGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaxDensityGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTrimGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConfigurationInformationGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0150;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papConfigurationInformationDescriptionGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0152;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaximumCollatedFilmsGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0154;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papIlluminationGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x015E;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReflectedAmbientLightGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0160;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterPixelSpacingGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0376;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedFilmSessionSequenceGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageBoxSequence2010Gr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0510;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedBasicAnnotationBoxSequenceGr];
  theWrkP->group = 0x2010;
  theWrkP->element = 0x0520;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2010 */


/********************************************************************************/
/*										*/
/*	init_group2020 : initializes the elements of the group 2020		*/
/*										*/
/********************************************************************************/

void
init_group2020 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImagePosition2020Gr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPolarityGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedImageSizeGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedDecimateCropBehaviorGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedResolutionIDGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRequestedImageSizeFlagGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDecimateCropResultGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x00A2;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreformattedGrayscaleImageSequenceGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPreformattedColorImageSequenceGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageOverlayBoxSequenceGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedVOILUTBoxSequenceGr];
  theWrkP->group = 0x2020;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2020 */


/********************************************************************************/
/*										*/
/*	init_group2030 : initializes the elements of the group 2030		*/
/*										*/
/********************************************************************************/

void
init_group2030 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2030;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationPositionGr];
  theWrkP->group = 0x2030;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTextStringGr];
  theWrkP->group = 0x2030;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2030 */


/********************************************************************************/
/*										*/
/*	init_group2040 : initializes the elements of the group 2040		*/
/*										*/
/********************************************************************************/

void
init_group2040 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlayPlaneSequenceGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlayPlaneGroupsGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-99";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayPixelDataSequenceGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayMagnificationTypeGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayMagnificationGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaySmoothingTypeGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayOrImageMagnificationGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0072;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMagnifyToNumberOfColumnsGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0074;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayForegroundDensityGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayBackgroundDensityGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayModeGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papThresholdDensityGr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedImageBoxSequence2040Gr];
  theWrkP->group = 0x2040;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2040 */


/********************************************************************************/
/*										*/
/*	init_group2050 : initializes the elements of the group 2050		*/
/*										*/
/********************************************************************************/

void
init_group2050 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papPresentationLUTSequenceGr];
  theWrkP->group = 0x2050;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationLUTShapeGr];
  theWrkP->group = 0x2050;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPresentationLUTSequenceGr];
  theWrkP->group = 0x2050;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2050 */

 
/********************************************************************************/
/*										*/
/*	init_group2100 : initializes the elements of the group 2100		*/
/*										*/
/********************************************************************************/

void
init_group2100 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExecutionStatusGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papExecutionStatusInfoGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCreationDateGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCreationTimeGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOriginatorGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDestinationAEGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = AE;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOwnerIDGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0160;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberOfFilmsGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0170;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedPrintJobSequenceGr];
  theWrkP->group = 0x2100;
  theWrkP->element = 0x0500;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2100 */


/********************************************************************************/
/*										*/
/*	init_group2110 : initializes the elements of the group 2110		*/
/*										*/
/********************************************************************************/

void
init_group2110 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterStatusGr];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterStatusInfoGr];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrinterNameGr];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintQueueIDGr];
  theWrkP->group = 0x2110;
  theWrkP->element = 0x0099;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2110 */


/********************************************************************************/
/*										*/
/*	init_group2120 : initializes the elements of the group 2120		*/
/*										*/
/********************************************************************************/

void
init_group2120 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2120;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papQueueStatusGr];
  theWrkP->group = 0x2120;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintJobDescriptionSequenceGr];
  theWrkP->group = 0x2120;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papreferencedPrintJobSequenceGr];
  theWrkP->group = 0x2120;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2120 */


/********************************************************************************/
/*										*/
/*	init_group2130 : initializes the elements of the group 2130		*/
/*										*/
/********************************************************************************/

void
init_group2130 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintManagementCapabilitiesSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPrintCharacteristicsSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papFilmBoxContentSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageBoxContentSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAnnotationContentSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageOverlayBoxContentSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPresentationLUTContentSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papProposedStudySequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOrigianlImageSequenceGr];
  theWrkP->group = 0x2130;
  theWrkP->element = 0x00C0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group2130 */


/********************************************************************************/
/*										*/
/*	init_group3002 : initializes the elements of the group 3002		*/
/*										*/
/********************************************************************************/

void
init_group3002 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRTImageLabelGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageNameGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageDescriptionGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReportedValuesOriginGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImagePlaneGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papXRayImageReceptortranslationGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000D;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papXRayImageReceptorAngleGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageOrientationGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "6";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papImagePlanePixelSpacingGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImagePositionGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationMachineNameGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationMachineSADGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationMachineSSDGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTImageSIDGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoReferenceObjectDistanceGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFractionNumberGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0029;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papExposureSequenceGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papMetersetExposureGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDiaphragmPositionGr];
  theWrkP->group = 0x3002;
  theWrkP->element = 0x0034;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "4";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
} /* endof init_group3002 */


/********************************************************************************/
/*										*/
/*	init_group3004 : initializes the elements of the group 3004		*/
/*										*/
/********************************************************************************/

void
init_group3004 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDVHTypeGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0001;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseUnitsGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseTypeGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseCommentGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNormalizationPointGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseSummationTypeGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papGridFrameOffsetVectorGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseGridScalingGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTDoseROISequenceGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseValueGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHNormalizationPointGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHNormalizationDoseValueGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHSequenceGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHDoseScalingGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHVolumeUnitsGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0054;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHNumberofBinsGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0056;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHDataGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0058;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHReferencedROISequenceGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHROIContributionTypeGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHMinimumDoseGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHMaximumDoseGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0072;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDVHMeanDoseGr];
  theWrkP->group = 0x3004;
  theWrkP->element = 0x0074;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  

} /* endof init_group3004 */


/********************************************************************************/
/*										*/
/*	init_group3006 : initializes the elements of the group 3006		*/
/*										*/
/********************************************************************************/

void
init_group3006 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papStructureSetLabelGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetNameGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetDescriptionGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetDateGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetTimeGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedFrameofReferenceSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTReferencedStudySequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTReferencedSeriesSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourImageSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStructureSetROISequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROINumberGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedFrameofReferenceUIDGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROINameGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIDescriptionGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0028;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIDisplayColorGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x002A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIVolumeGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x002C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTRelatedROISequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTROIRelationshipGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIGenerationAlgorithmGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0036;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIGenerationDescriptionGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0038;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIContourSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0039;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourGeometricTypeGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourSlabThicknessGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourOffsetVectorGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0045;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofContourPointsGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0046;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourNumberGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0048;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papAttachedContoursGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0049;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourDataGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3-3n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTROIObservationsSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papObservationNumberGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedROINumberGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0084;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIObservationLabelGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0085;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTROIIdentificationCodeSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0086;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIObservationDescriptionGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x0088;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRelatedRTROIObservationsSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTROIInterpretedTypeGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00A4;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIInterpreterGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00A6;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIPhysicalPropertiesSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00B0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIPhysicalPropertyGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00B2;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papROIPhysicalPropertyValueGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00B4;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFrameofReferenceRelationshipSequenceGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00C0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRelatedFrameofReferenceUIDGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00C2;
  theWrkP->length = 0L;
  theWrkP->vr = UI;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFrameofReferenceTransformationTypeGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00C4;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFrameofReferenceTransformationMatrixGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00C6;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "16";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFrameofReferenceTransformationCommentGr];
  theWrkP->group = 0x3006;
  theWrkP->element = 0x00C8;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL; 
  
} /* endof init_group3006 */


/********************************************************************************/
/*										*/
/*	init_group3008 : initializes the elements of the group 3008		*/
/*										*/
/********************************************************************************/

void
init_group3008 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMeasuredDoseReferenceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papMeasuredDoseDescriptionGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papMeasuredDoseTypeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papMeasuredDoseValueGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentSessionBeamSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCurrentFractionNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentControlPointDateGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0024;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentControlPointTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0025;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentControlTerminationStatusGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x002A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentControlTerminationCodeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x002B;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentVerificationStatusGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x002C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedTreatmentRecordSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedPrimaryMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0032;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedSecondaryMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0033;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredPrimaryMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0036;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredSecondaryMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0037;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedTreatmentTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x003A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredTreatmentTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x003B;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papControlPointDeliverySequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDoseRateDeliveredGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0048;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentSummaryCalculatedDoseReferenceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCumulativeDoseToDoseReferenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papFirstTreatmentDateGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0054;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papMostRecentTreatmentDateGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0056;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papNumberOfFractionsDeliveredGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x005A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papOverrideSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papOverrideParameterPointerGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0062;
  theWrkP->length = 0L;
  theWrkP->vr = AT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papMeasuredDoseReferenceNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0064;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papOverrideReasonGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0066;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCalculatedDoseReferenceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCalculatedDoseReferenceNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0072;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCalculatedDoseReferenceDescriptionGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0074;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCalculatedDoseReferenceDoseValueGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0076;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papStartMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0078;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papEndMetersetGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x007A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedMeasuredDoseReferenceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedMeasuredDoseReferenceNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedCalculatedDoseReferenceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0090;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedCalculatedDoseReferenceNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0092;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papBeamLimitingDeviceLeafPairsSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedWedgeSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x00B0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedCompensatorSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x00C0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedBlockSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x00D0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedSourceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSourceSerialNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentSessionApplicationSetupSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papApplicationSetupCheckGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0116;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedBrachyAccessoryDeviceSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papreferencedBrachyAccessoryDeviceNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0122;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedChannelSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedChannelTotalTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0132;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredChannelTotalTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0134;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedNumberOfPulsesGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0136;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredNumberOfPulsesGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0138;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSpecifiedPulseRepetitionIntervalGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x013A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papDeliveredPulseRepetitionIntervalGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x013C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedSourceApplicatorSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0140;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedSourceApplicatorNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0142;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papRecordedChannelShieldSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0150;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedCahnnelShieldNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0152;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papBrachyControlPointDeliveredSequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0160;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSafePositionExitDateGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0162;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSafePositionExitTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0164;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSafePositionReturnDateGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0166;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papSafePositionReturnTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0168;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papCurrentTreatmentStatusGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentStatusCommentGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papFractionGropSummarySequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0220;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papReferencedFractionNumberGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0223;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papFractionGroupTypeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0224;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papBeamStopperPositionGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0230;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papFractionStatusSummarySequenceGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0240;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentDateGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0250;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

  theWrkP = &ioElem [papTreatmentTimeGr];
  theWrkP->group = 0x3008;
  theWrkP->element = 0x0251;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;  

} /* endof init_group3008 */


/********************************************************************************/
/*										*/
/*	init_group300A : initializes the elements of the group 300A		*/
/*										*/
/********************************************************************************/

void
init_group300A (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papRTPlanLabelGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0003;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanDateGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanTimeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0007;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentProtocolsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentIntentGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentSitesGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000B;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanGeometryGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPrescriptionDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferenceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferenceNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferenceStructureTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0014;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNominalBeamEnergyUnitGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferenceDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0016;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferencePointCoordinatesGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0018;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNominalPriorDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x001A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseReferenceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papConstraintWeightGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0021;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDeliveryWarningDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDeliveryMaximumDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0023;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTargetMinimumDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0025;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTargetPrescriptionDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0026;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTargetMaximumDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0027;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTargetUnderdoseVolumeFractionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0028;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papOrganatRiskFullvolumeDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x002A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papOrganatRiskLimitDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x002B;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papOrganatRiskMaximumDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x002C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papOrganatRiskOverdoseVolumeFractionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x002D;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papToleranceTableSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papToleranceTableNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papToleranceTableLabelGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0043;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papGantryAngleToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0044;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDeviceAngleToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0046;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDeviceToleranceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0048;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDevicePositionToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x004A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientSupportAngleToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x004C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopEccentricAngleToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x004E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopVerticalPositionToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLongitudinalPositionToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLateralPositionToleranceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0053;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTPlanRelationshipGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0055;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFractionGroupSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0070;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFractionGroupNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0071;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofFractionsPlannedGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0078;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofFractionsPerDayGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0079;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRepeatFractionCycleLengthGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x007A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFractionPatternGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x007B;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofBeamsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamDoseSpecificationPointGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0082;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0084;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamMetersetGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0086;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofBrachyApplicationSetupsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyApplicationSetupDoseSpecificationPointGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00A2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyApplicationSetupDoseGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00A4;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentMachineNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B2;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPrimaryDosimeterUnitGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B3;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceAxisDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B4;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDeviceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B6;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRTBeamLimitingDeviceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00B8;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoBeamLimitingDeviceDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00BA;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofLeafJawPairsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00BC;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papLeafPositionBoundariesGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00BE;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C2;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C3;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C4;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papRadiationTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C6;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papHighDoseTechniqueTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C7;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferenceImageNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00C8;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPlannedVerificationImageSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00CA;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papImagingDeviceSpecificAcquisitionParametersGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00CC;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentDeliveryTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00CE;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofWedgesGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D1;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D2;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D3;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D4;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeAngleGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D5;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeFactorGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D6;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgeOrientationGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00D8;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoWedgeTrayDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00DA;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofCompensatorsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papMaterialIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E1;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTotalCompensatorTrayFactorGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E3;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E4;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E5;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoCompensatorTrayDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E6;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorRowsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E7;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorColumnsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E8;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorPixelSpacingGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00E9;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00EA;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorTransmissionDataGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00EB;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorThicknessDataGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00EC;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofBoliGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00ED;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCompensatorTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00EE;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofBlocksGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00F0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTotalBlockTrayFactorGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00F2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00F4;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockTrayIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00F5;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoBlockTrayDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00F6;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00F8;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockDivergenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00FA;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00FC;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x00FE;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockThicknessGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockTransmissionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockNumberofPointsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0104;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBlockDataGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0106;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicatorSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0107;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicatorIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0108;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicatorTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0109;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicatorDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x010A;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCumulativeDoseReferenceCoefficientGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x010C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFinalCumulativeMetersetWeightGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x010E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofControlPointsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papControlPointSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papControlPointIndexGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0112;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNominalBeamEnergyGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0114;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papDoseRateSetGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0115;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgePositionSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0116;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papWedgePositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0118;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDevicePositionSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x011A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papLeafJawPositionsGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x011C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "2-2n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papGantryAngleGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x011E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papGantryRotationDirectionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x011F;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDeviceAngleGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0120;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBeamLimitingDeviceRotationDirectionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0121;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientSupportAngleGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0122;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientSupportRotationDirectionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0123;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopEccentricAxisDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0124;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopEccentricAngleGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0125;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopEccentricRotationDirectionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0126;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopVerticalPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0128;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLongitudinalPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0129;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLateralPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x012A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papIsocenterPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x012C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSurfaceEntryPointGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x012E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourcetoSurfaceDistanceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0130;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCumulativeMetersetWeightGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0134;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientSetupSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0180;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientSetupNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0182;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPatientAdditionalPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0184;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFixationDeviceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0190;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFixationDeviceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0192;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFixationDeviceLabelGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0194;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFixationDeviceDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0196;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFixationDevicePositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0198;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papShieldingDeviceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01A0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papShieldingDeviceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01A2;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papShieldingDeviceLabelGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01A4;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papShieldingDeviceDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01A6;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papShieldingDevicePositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01A8;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupTechniqueGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01B0;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupTechniqueDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01B2;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupDeviceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01B4;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupDeviceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01B6;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupDeviceLabelGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01B8;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupDeviceDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01BA;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupDeviceParameterGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01BC;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSetupReferenceDescriptionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01D0;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopVerticalSetupDisplacementGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01D2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLongitudinalSetupDisplacementGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01D4;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTableTopLateralSetupDisplacementGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x01D6;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyTreatmentTechniqueGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyTreatmentTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTreatmentMachineSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0206;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0210;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0212;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0214;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceManufacturerGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0216;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papActiveSourceDiameterGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0218;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papActiveSourceLengthGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x021A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceEncapsulationNominalThicknessGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0222;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceEncapsulationNominalTransmissionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0224;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceIsotopeNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0226;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceIsotopeHalfLifeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0228;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferenceAirKermaRateGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x022A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papAirKermaRateReferenceDateGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x022C;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papAirKermaRateReferenceTimeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x022E;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicationSetupSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0230;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicationSetupTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0232;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicationSetupNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0234;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicationSetupNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0236;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papApplicationSetupManufacturerGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0238;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTemplateNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0240;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTemplateTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0242;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTemplateNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0244;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTotalReferenceAirKermaGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0250;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0260;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0262;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0263;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0264;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0266;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceNominalThicknessGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x026A;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyAccessoryDeviceNominalTransmissionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x026C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0280;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0282;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelLengthGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0284;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelTotalTimeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0286;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceMovementTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0288;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papNumberofPulsesGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x028A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papPulseRepetitionIntervalGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x028C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0290;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0291;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorTypeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0292;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0294;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorLengthGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0296;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorManufacturerGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x0298;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorWallNominalThicknessGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x029C;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorWallNominalTransmissionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x029E;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSourceApplicatorStepSizeGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02A0;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTransferTubeNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02A2;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papTransferTubeLengthGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02A4;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelShieldSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02B0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelShieldNumberGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02B2;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelShieldIDGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02B3;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelShieldNameGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02B4;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelShieldNominalThicknessGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02B8;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papChannelShieldNominalTransmissionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02BA;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papFinalCumulativeTimeWeightGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02C8;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyControlPointSequenceGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02D0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papControlPointRelativePositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02D2;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papControlPoint3DPositionGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02D4;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "3";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papCumulativeTimeWeightGr];
  theWrkP->group = 0x300A;
  theWrkP->element = 0x02D6;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  

} /* endof init_group300A */


/********************************************************************************/
/*										*/
/*	init_group300C : initializes the elements of the group 300C		*/
/*										*/
/********************************************************************************/

void
init_group300C (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papReferencedRTPlanSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBeamSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBeamNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0006;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedReferenceImageNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0007;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papStartCumulativeMetersetWeightGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papEndCumulativeMetersetWeightGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0009;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBrachyApplicationSetupSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x000A;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBrachyApplicationSetupNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x000C;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedSourceNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x000E;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedFractionGroupSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedFractionGroupNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedVerificationImageSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedReferenceImageSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedDoseReferenceSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedDoseReferenceNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papBrachyReferencedDoseReferenceSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0055;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedStructureSetSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedPatientSetupNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x006A;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedDoseSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x0080;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedToleranceTableNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x00A0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBolusSequenceGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x00B0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedWedgeNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x00C0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedCompensatorNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x00D0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedBlockNumberGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x00E0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReferencedControlPointIndexGr];
  theWrkP->group = 0x300C;
  theWrkP->element = 0x00F0;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  

} /* endof init_group300C */


/********************************************************************************/
/*										*/
/*	init_group300E : initializes the elements of the group 300E		*/
/*										*/
/********************************************************************************/

void
init_group300E (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papApprovalStatusGr];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0002;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReviewDateGr];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0004;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReviewTimeGr];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papReviewerNameGr];
  theWrkP->group = 0x300E;
  theWrkP->element = 0x0008;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  

} /* endof init_group300E */


/********************************************************************************/
/*										*/
/*	init_group4000 : initializes the elements of the group 4000		*/
/*										*/
/********************************************************************************/

void
init_group4000 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x4000;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papArbitraryGr];
  theWrkP->group = 0x4000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCommentsGr];
  theWrkP->group = 0x4000;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = RET;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group4000 */


/********************************************************************************/
/*										*/
/*	init_group4008 : initializes the elements of the group 4008		*/
/*										*/
/********************************************************************************/

void
init_group4008 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsIDGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsIDIssuerGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0042;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedInterpretationSequenceGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationRecordedDateGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationRecordedTimeGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0101;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationRecorderGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencetoRecordedSoundGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTranscriptionDateGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0108;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTranscriptionTimeGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0109;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTranscriberGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x010A;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTextGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x010B;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationAuthorGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x010C;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationApproverSequenceGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0111;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationApprovalDateGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0112;
  theWrkP->length = 0L;
  theWrkP->vr = DA;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationApprovalTimeGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0113;
  theWrkP->length = 0L;
  theWrkP->vr = TM;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPhysicianApprovingInterpretationGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0114;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationDiagnosisDescriptionGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0115;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDiagnosisCodeSequenceGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0117;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsDistributionListSequenceGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0118;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "0-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistributionNameGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0119;
  theWrkP->length = 0L;
  theWrkP->vr = PN;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDistributionAddressGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x011A;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationIDGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationIDIssuerGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0202;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationTypeIDGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0210;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInterpretationStatusIDGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0212;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImpressionsGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x0300;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papResultsCommentsGr];
  theWrkP->group = 0x4008;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = ST;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group4008 */


/********************************************************************************/
/*										*/
/*	init_group5000 : initializes the elements of the group 5000		*/
/*										*/
/********************************************************************************/

void
init_group5000 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDimensionsGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0005;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofPointsGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTypeofDataGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0020;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDescriptionGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxisUnitsGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0030;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAxisLabelsGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papDataValueRepresentationGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMinimumCoordinateValueGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0104;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaximumCoordinateValueGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0105;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveRangeGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0106;
  theWrkP->length = 0L;
  theWrkP->vr = SH;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDataDescriptorGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoordinateStartValueGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0112;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCoordinateStepValueGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x0114;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveActivationLayerGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioTypeGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2000;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioSampleFormatGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2002;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofChannelsGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2004;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofSamplesGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2006;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papSampleRateGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2008;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papTotalTimeGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x200A;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioSampleDataGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x200C;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papAudioCommentsGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x200E;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveLabelGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2500;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlaySequence5000Gr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2600;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papReferencedOverlayGroupGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x2610;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCurveDataGr];
  theWrkP->group = 0x5000;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group5000 */

/********************************************************************************/
/*										*/
/*	init_group5200 : initializes the elements of the group 5200		*/
/*										*/
/********************************************************************************/

void
init_group5200 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x5200;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

 theWrkP = &ioElem [papSharedFunctionalGroupsSequence];
 theWrkP->group = 0x5200;
 theWrkP->element = 0x9229;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;

 theWrkP = &ioElem [papPerFrameFunctionalGroupsSequence];
 theWrkP->group = 0x5200;
 theWrkP->element = 0x9230;
 theWrkP->length = 0L;
 theWrkP->vr = SQ;
 theWrkP->vm = "1";
 theWrkP->type_t = T3;
 theWrkP->nb_val = 0;
 theWrkP->value = NULL;
 
} /* endof init_group5200 */

/********************************************************************************/
/*										*/
/*	init_group5400 : initializes the elements of the group 5400		*/
/*										*/
/********************************************************************************/

void
init_group5400 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformSequenceGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelMinimumValueGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = OB;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papChannelMaximumValueGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x0112;
  theWrkP->length = 0L;
  theWrkP->vr = OB;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformBitsAllocatedGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x1004;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformSampleInterpretationGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x1006;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformPaddingValueGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x100A;
  theWrkP->length = 0L;
  theWrkP->vr = OB;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papWaveformDataGr];
  theWrkP->group = 0x5400;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = OB;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group5400 */

//void
//init_group5600 (SElement ioElem [])
//{
//  SElement	*theWrkP;
//
//  theWrkP = &ioElem [papGroupLength];
//  theWrkP->group = 0x5600;
//  theWrkP->element = 0x0000;
//  theWrkP->length = 0L;
//  theWrkP->vr = UL;
//  theWrkP->vm = "1";
//  theWrkP->type_t = RET;
//  theWrkP->nb_val = 0;
//  theWrkP->value = NULL;
//
// theWrkP = &ioElem [papFirstOrderPhaseCorrectionAngle];
// theWrkP->group = 0x5600;
// theWrkP->element = 0x0010;
// theWrkP->length = 0L;
// theWrkP->vr = OF;
// theWrkP->vm = "1";
// theWrkP->type_t = T3;
// theWrkP->nb_val = 0;
// theWrkP->value = NULL;
//
// theWrkP = &ioElem [papSpectroscopyData];
// theWrkP->group = 0x5600;
// theWrkP->element = 0x0020;
// theWrkP->length = 0L;
// theWrkP->vr = OF;
// theWrkP->vm = "1";
// theWrkP->type_t = T3;
// theWrkP->nb_val = 0;
// theWrkP->value = NULL;
// 
// } /* endof init_group5600 */

/********************************************************************************/
/*										*/
/*	init_group6000 : initializes the elements of the group 6000		*/
/*										*/
/********************************************************************************/

void
init_group6000 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayRows6000Gr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayColumns6000Gr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayPlanesGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0012;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papNumberofFramesinOverlayGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0015;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptionGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0022;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayTypeGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0040;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaySubtypeGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0045;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOriginGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0050;
  theWrkP->length = 0L;
  theWrkP->vr = SS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papImageFrameOriginGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0051;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayPlaneOriginGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0052;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papCompressionCode6000Gr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0060;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "2";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayBitsAllocatedGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papBitPositionGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayFormatGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0110;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayLocationGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x0200;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayActivationLayerGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = CS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorGrayGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1100;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorRedGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1101;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorGreenGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1102;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDescriptorBlueGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1103;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysGrayGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1200;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysRedGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1201;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysGreenGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1202;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlaysBlueGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1203;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papROIAreaGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1301;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papROIMeanGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1302;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papROIStandardDeviationGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1303;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayLabelGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x1500;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papOverlayDataGr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x3000;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papComments6000Gr];
  theWrkP->group = 0x6000;
  theWrkP->element = 0x4000;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group6000 */

/********************************************************************************/
/*										*/
/*	init_group7053 : initializes the elements of the group 7053		*/
/*										*/
/********************************************************************************/

void
init_group7053 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x7053;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papSUVFactor7053Gr];
  theWrkP->group = 0x7053;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = DS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group7053 */


/******************************************************************************/
/*									      */
/*	init_uinoverlay : initializes the elements of the group 6XXX (odd)    */
/*									      */
/******************************************************************************/
    		  
void
init_uinoverlay (SElement ioElem [])
{
  SElement	*theWrkP;
 
  /* group 6XXX (odd) */
  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOwnerIDGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 1;
  theWrkP->value = (UValue_T *) emalloc3 ((PapyULong) sizeof (UValue_T));
  theWrkP->value->a = (char *) ecalloc3 ((PapyULong) 12, (PapyULong) sizeof (char));
  strcpy (theWrkP->value->a, "PAPYRUS 3.0");
 
  theWrkP = &ioElem [papOverlayIdGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1000;
  theWrkP->length = 0L;
  theWrkP->vr = IS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papLinkedOverlaysGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1001;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T2;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayRowsGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1010;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayColumnsGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1011;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papUINOverlayTypeGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1040;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayOriginGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1050;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papEditableGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1060;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayFontGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1070;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayStyleGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1072;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayFontSizeGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1074;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayColorGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1076;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papShadowSizeGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1078;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papFillPatternGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1080;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papOverlayPenSizeGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x1082;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papLabelGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10A0;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papPostItTextGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10A2;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papAnchorPointGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10A4;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papRoiTypeGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10B0;
  theWrkP->length = 0L;
  theWrkP->vr = LO;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papAttachedAnnotationGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10B2;
  theWrkP->length = 0L;
  theWrkP->vr = LT;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInfoIntGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10B3;
  theWrkP->length = 0L;
  theWrkP->vr = SL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papInfoFloatGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10B4;
  theWrkP->length = 0L;
  theWrkP->vr = FL;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
  
  theWrkP = &ioElem [papContourPointsGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10BA;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papMaskDataGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10BC;
  theWrkP->length = 0L;
  theWrkP->vr = USS;
  theWrkP->vm = "1-n";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;
 
  theWrkP = &ioElem [papUINOverlaySequenceGr];
  theWrkP->group = 0x6001;
  theWrkP->element = 0x10C0;
  theWrkP->length = 0L;
  theWrkP->vr = SQ;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_uinoverlay */


/********************************************************************************/
/*										*/
/*	init_group7FE0 : initializes the elements of the group 7FE0		*/
/*										*/
/********************************************************************************/

void
init_group7FE0 (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP = &ioElem [papGroupLength];
  theWrkP->group = 0x7FE0;
  theWrkP->element = 0x0000;
  theWrkP->length = 0L;
  theWrkP->vr = UL;
  theWrkP->vm = "1";
  theWrkP->type_t = RET;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

  theWrkP = &ioElem [papPixelDataGr];
  theWrkP->group = 0x7FE0;
  theWrkP->element = 0x0010;
  theWrkP->length = 0L;
  theWrkP->vr = OW;
  theWrkP->vm = "1";
  theWrkP->type_t = T3;
  theWrkP->nb_val = 0;
  theWrkP->value = NULL;

} /* endof init_group7FE0 */

