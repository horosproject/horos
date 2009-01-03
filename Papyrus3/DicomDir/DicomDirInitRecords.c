/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit (Dicomdir library)			*/
/*	File     : DicomdirInitRecords.c				        */
/*	Function : contains the Directory record initialisation functions	*/
/********************************************************************************/


/* ------------------------- includes ---------------------------------------*/

#include <stdio.h>

#ifndef DicomdirH 
#include "DicomDir.h"
#endif


/********************************************************************************/
/*										*/
/*	init_PatientR : initializes the elements of the Directory Record	*/
/*	Patient 								*/
/*										*/
/********************************************************************************/

void
init_PatientR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP 		= &ioElem [papOffsetofNextDirectoryRecordP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UL;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papRecordInuseP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= USS;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UL;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papDirectoryRecordTypeP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= CS;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papPrivateRecordUIDP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UI;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papReferencedFileIDP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= CS;
  theWrkP->vm 		= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papMRDRDirectoryRecordOffsetP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UL;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papReferencedSOPClassUIDinFileP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UI;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papReferencedSOPInstanceUIDinFileP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UI;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papReferencedTransferSyntaxUIDinFileP];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UI;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papSpecificCharacterSetDRP];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length	 = 0L;
  theWrkP->vr 		= CS;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papPatientsNameDR];
  theWrkP->group 	= 0x0010;
  theWrkP->element 	= 0x0010;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= PN;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP 		= &ioElem [papPatientIDDR];
  theWrkP->group 	= 0x0010;
  theWrkP->element 	= 0x0020;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= LO;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
} /* endof init_PatientR */


/********************************************************************************/
/*										*/
/*	init_StudyR : initializes the elements of the Directory Record		*/
/*	Study 									*/
/*										*/
/********************************************************************************/

void
init_StudyR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP 		= &ioElem [papOffsetofNextDirectoryRecordS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= UL;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 		= USS;
  theWrkP->vm 		= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRS];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papStudyDateDRS];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0020;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= DA;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papStudyTimeDRS];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0030;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= TM;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
  theWrkP		= &ioElem [papStudyDescriptionDRS];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x1030;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papStudyInstanceUIDDRS];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x000D;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papStudyIDDRS];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0010;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SH;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papAccessionNumberDRS];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0050;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SH;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_StudyR */



/********************************************************************************/
/*										*/
/*	init_SeriesR : initializes the elements of the Directory Record		*/
/*	Series 									*/
/*										*/
/********************************************************************************/

void
init_SeriesR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntitySE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileSE];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRSE];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papModalityDRSE];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0060;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSeriesInstanceUIDDRSE];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x000E;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSeriesNumberDRSE];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0011;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= IS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
  theWrkP		= &ioElem [papIconImageSequenceDRSE];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0200;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SQ;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T3;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_SeriesR */



/********************************************************************************/
/*										*/
/*	init_ImageR : initializes the elements of the Directory Record		*/
/*	Image 									*/
/*										*/
/********************************************************************************/

void
init_ImageR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRI];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papImageNumberDRI];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0013;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= IS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papIconImageSequenceDRI];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0200;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SQ;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T3;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_ImageR */



/********************************************************************************/
/*										*/
/*	init_OverlayR : initializes the elements of the Directory Record	*/
/*	Overlay 								*/
/*										*/
/********************************************************************************/

void
init_OverlayR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileO];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRO];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOverlayNumberDRO];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0022;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= IS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papIconImageSequenceDRO];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0200;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SQ;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T3;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_OverlayR */



/********************************************************************************/
/*										*/
/*	init_ModalityLUTR : initializes the elements of the Directory Record	*/
/*	Modality LUT 								*/
/*										*/
/********************************************************************************/

void
init_ModalityLUTR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileM];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRM];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papLUTNumberDRM];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0026;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= IS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
} /* endof init_ModalityLUTR */



/********************************************************************************/
/*										*/
/*	init_VOILUTR : initializes the elements of the Directory Record		*/
/*	VOILUT 									*/
/*										*/
/********************************************************************************/

void
init_VOILUTR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileV];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRV];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papLUTNumberDRV];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0026;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= IS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
} /* endof init_VOILUTR */



/********************************************************************************/
/*										*/
/*	init_CurveR : initializes the elements of the Directory Record		*/
/*	Curve 									*/
/*										*/
/********************************************************************************/

void
init_CurveR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRC];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papCurveNumberDRC];
  theWrkP->group 	= 0x0020;
  theWrkP->element 	= 0x0024;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= IS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_CurveR */



/********************************************************************************/
/*										*/
/*	init_Topic : initializes the elements of the Directory Record		*/
/*	Topic 									*/
/*										*/
/********************************************************************************/

void
init_Topic (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileT];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRT];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papTopicTitleDRT];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0904;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papTopicSubjectDRT];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0906;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= ST;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papTopicAuthorDRT];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0910;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papTopicKeyWordsDRT];
  theWrkP->group 	= 0x0088;
  theWrkP->element 	= 0x0912;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1-32";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
  
} /* endof init_Topic */



/********************************************************************************/
/*										*/
/*	init_Visit : initializes the elements of the Directory Record		*/
/*	Visit 									*/
/*										*/
/********************************************************************************/

void
init_Visit (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileVI];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papAdmittingDateDRVI];
  theWrkP->group 	= 0x0038;
  theWrkP->element 	= 0x0020;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= DA;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;


  theWrkP		= &ioElem [papAdmissionIDDRVI];
  theWrkP->group 	= 0x0038;
  theWrkP->element 	= 0x0010;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
  theWrkP		= &ioElem [papInstitutionNameDRVI];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0080;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;
 
  theWrkP		= &ioElem [papSpecificCharacterSetDRVI];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_Visit */


/********************************************************************************/
/*										*/
/*	init_Result : initializes the elements of the Directory Record		*/
/*	Result 									*/
/*										*/
/********************************************************************************/

void
init_Result (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileR];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papResultsIDDRR];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0040;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SH;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInstanceCreationDateDRR];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0012;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= DA;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRR];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_Result */


/********************************************************************************/
/*										*/
/*	init_Interpretation : initializes the elements of the Directory Record	*/
/*	Interpretation 								*/
/*										*/
/********************************************************************************/

void
init_Interpretation (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileIN];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRIN];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInterpretationTranscriptionDateDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0108;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= DA;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInterpretationAuthorDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x010C;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= PN;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInterpretationDiagnosisDescriptionDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0115;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LT;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDiagnosisCodeSequenceDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0117;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SQ;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInterpretationIDDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0200;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SH;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInterpretationTypeIDDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0210;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papInterpretationStatusIDDRIN];
  theWrkP->group 	= 0x4008;
  theWrkP->element 	= 0x0212;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_Interpretation */


/********************************************************************************/
/*										*/
/*	init_StudyComponentR : initializes the elements of the Directory Record	*/
/*	Study Component 							*/
/*										*/
/********************************************************************************/

void
init_StudyComponentR (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntitySC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileSC];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRSC];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papModalityDRSC];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0060;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papStudyDescriptionDRSC];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x1030;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papProcedureCodeSequenceDRSC];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x1032;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SQ;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPerformingPhysiciansNameDRSC];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x1050;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= PN;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_StudyComponentR */


/********************************************************************************/
/*										*/
/*	init_PrintQueue : initializes the elements of the Directory Record	*/
/*	Print Queue 								*/
/*										*/
/********************************************************************************/

void
init_PrintQueue (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordPQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInusePQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityPQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypePQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDPQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDPQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetPQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFilePQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFilePQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFilePQ];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrintQueueIDDRPQ];
  theWrkP->group 	= 0x2110;
  theWrkP->element 	= 0x0099;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= SH;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRPQ];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrinterNameDRPQ];
  theWrkP->group 	= 0x2110;
  theWrkP->element 	= 0x0030;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_PrintQueue */


/********************************************************************************/
/*										*/
/*	init_FilmSession : initializes the elements of the Directory Record	*/
/*	Film Session 								*/
/*										*/
/********************************************************************************/

void
init_FilmSession (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileFS];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRFS];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papFilmSessionLabelDRFS];
  theWrkP->group 	= 0x2000;
  theWrkP->element 	= 0x0050;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= LO;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T2;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papExecutionStatusDRFS];
  theWrkP->group 	= 0x2100;
  theWrkP->element 	= 0x0020;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_FilmSession */



/********************************************************************************/
/*										*/
/*	init_BasicFilmBox : initializes the elements of the Directory Record	*/
/*	Basic Film Box								*/
/*										*/
/********************************************************************************/

void
init_BasicFilmBox (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileBFB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRBFB];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papExecutionStatusDRBFB];
  theWrkP->group 	= 0x2100;
  theWrkP->element 	= 0x0020;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_BasicFilmBox */


/********************************************************************************/
/*										*/
/*	init_BasicImageBox : initializes the elements of the Directory Record	*/
/*	Basic Image Box 							*/
/*										*/
/********************************************************************************/

void
init_BasicImageBox (SElement ioElem [])
{
  SElement	*theWrkP;

  theWrkP		= &ioElem [papOffsetofNextDirectoryRecordBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1400;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papRecordInuseBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1410;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papOffsetofReferencedLowerLevelDirectoryEntityBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1420;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papDirectoryRecordTypeBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1430;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papPrivateRecordUIDBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1432;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedFileIDBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1500;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1-n";
  theWrkP->type_t 	= T2C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papMRDRDirectoryRecordOffsetBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1504;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UL;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPClassUIDinFileBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1510;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedSOPInstanceUIDinFileBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1511;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papReferencedTransferSyntaxUIDinFileBIB];
  theWrkP->group 	= 0x0004;
  theWrkP->element 	= 0x1512;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= UI;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papSpecificCharacterSetDRBIB];
  theWrkP->group 	= 0x0008;
  theWrkP->element 	= 0x0005;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= CS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1C;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

  theWrkP		= &ioElem [papImagePosition2020DRBIB];
  theWrkP->group 	= 0x2020;
  theWrkP->element 	= 0x0010;
  theWrkP->length 	= 0L;
  theWrkP->vr 	 	= USS;
  theWrkP->vm 	 	= "1";
  theWrkP->type_t 	= T1;
  theWrkP->nb_val 	= 0;
  theWrkP->value 	= NULL;

} /* endof init_BasicImageBox */


