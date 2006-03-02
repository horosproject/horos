/********************************************************************************/
/*									      	*/
/*	Project  : P A P Y R U S  Toolkit (DicomDir library)		 	*/
/*	File     : DicomdirEnumRecords.h					*/
/*	Function : contains the declarations of the Directory Records.		*/
/*	Authors  : Marianne Logean					      	*/
/*								   		*/
/*	History  : 05.1997	version 3.51				      	*/
/*		   02.1999	version 3.6					*/
/*								   	      	*/
/*	(C) 1997 The University Hospital of Geneva			      	*/
/*	All Rights Reserved				      	                */
/*									      	*/
/********************************************************************************/


#ifndef DicomdirEnumRecordsH 
#define DicomdirEnumRecordsH



/*	Directory Record : Patient				*/

enum {
papOffsetofNextDirectoryRecordP,
papRecordInuseP,
papOffsetofReferencedLowerLevelDirectoryEntityP,
papDirectoryRecordTypeP,
papPrivateRecordUIDP,
papReferencedFileIDP,
papMRDRDirectoryRecordOffsetP,
papReferencedSOPClassUIDinFileP,
papReferencedSOPInstanceUIDinFileP,
papReferencedTransferSyntaxUIDinFileP,
papSpecificCharacterSetDRP,
papPatientsNameDR,
papPatientIDDR,
papEndPatientR
};


/*	Directory Record : Study				*/

enum {
papOffsetofNextDirectoryRecordS,
papRecordInuseS,
papOffsetofReferencedLowerLevelDirectoryEntityS,
papDirectoryRecordTypeS,
papPrivateRecordUIDS,
papReferencedFileIDS,
papMRDRDirectoryRecordOffsetS,
papReferencedSOPClassUIDinFileS,
papReferencedSOPInstanceUIDinFileS,
papReferencedTransferSyntaxUIDinFileS,
papSpecificCharacterSetDRS,
papStudyDateDRS,
papStudyTimeDRS,
papStudyDescriptionDRS,
papStudyInstanceUIDDRS,
papStudyIDDRS,
papAccessionNumberDRS,
papEndStudyR
};


/*	Directory Record : Series				*/

enum {
papOffsetofNextDirectoryRecordSE,
papRecordInuseSE,
papOffsetofReferencedLowerLevelDirectoryEntitySE,
papDirectoryRecordTypeSE,
papPrivateRecordUIDSE,
papReferencedFileIDSE,
papMRDRDirectoryRecordOffsetSE,
papReferencedSOPClassUIDinFileSE,
papReferencedSOPInstanceUIDinFileSE,
papReferencedTransferSyntaxUIDinFileSE,
papSpecificCharacterSetDRSE,
papModalityDRSE,
papSeriesInstanceUIDDRSE,
papSeriesNumberDRSE,
papIconImageSequenceDRSE,
papEndSeriesR
};


/*	Directory Record : Image				*/

enum {
papOffsetofNextDirectoryRecordI,
papRecordInuseI,
papOffsetofReferencedLowerLevelDirectoryEntityI,
papDirectoryRecordTypeI,
papPrivateRecordUIDI,
papReferencedFileIDI,
papMRDRDirectoryRecordOffsetI,
papReferencedSOPClassUIDinFileI,
papReferencedSOPInstanceUIDinFileI,
papReferencedTransferSyntaxUIDinFileI,
papSpecificCharacterSetDRI,
papImageNumberDRI,
papIconImageSequenceDRI,
papEndImageR
};


/*	Directory Record : Overlay				*/

enum {
papOffsetofNextDirectoryRecordO,
papRecordInuseO,
papOffsetofReferencedLowerLevelDirectoryEntityO,
papDirectoryRecordTypeO,
papPrivateRecordUIDO,
papReferencedFileIDO,
papMRDRDirectoryRecordOffsetO,
papReferencedSOPClassUIDinFileO,
papReferencedSOPInstanceUIDinFileO,
papReferencedTransferSyntaxUIDinFileO,
papSpecificCharacterSetDRO,
papOverlayNumberDRO,
papIconImageSequenceDRO,
papEndOverlayR
};


/*	Directory Record : ModalityLUT				*/

enum {
papOffsetofNextDirectoryRecordM,
papRecordInuseM,
papOffsetofReferencedLowerLevelDirectoryEntityM,
papDirectoryRecordTypeM,
papPrivateRecordUIDM,
papReferencedFileIDM,
papMRDRDirectoryRecordOffsetM,
papReferencedSOPClassUIDinFileM,
papReferencedSOPInstanceUIDinFileM,
papReferencedTransferSyntaxUIDinFileM,
papSpecificCharacterSetDRM,
papLUTNumberDRM,
papEndModalityLUTR
};


/*	Directory Record : VOILUT			*/

enum {
papOffsetofNextDirectoryRecordV,
papRecordInuseV,
papOffsetofReferencedLowerLevelDirectoryEntityV,
papDirectoryRecordTypeV,
papPrivateRecordUIDV,
papReferencedFileIDV,
papMRDRDirectoryRecordOffsetV,
papReferencedSOPClassUIDinFileV,
papReferencedSOPInstanceUIDinFileV,
papReferencedTransferSyntaxUIDinFileV,
papSpecificCharacterSetDRV,
papLUTNumberDRV,
papEndVOILUTR
};


/*	Directory Record : Curve			*/

enum {
papOffsetofNextDirectoryRecordC,
papRecordInuseC,
papOffsetofReferencedLowerLevelDirectoryEntityC,
papDirectoryRecordTypeC,
papPrivateRecordUIDC,
papReferencedFileIDC,
papMRDRDirectoryRecordOffsetC,
papReferencedSOPClassUIDinFileC,
papReferencedSOPInstanceUIDinFileC,
papReferencedTransferSyntaxUIDinFileC,
papSpecificCharacterSetDRC,
papCurveNumberDRC,
papEndCurveR
};


/*	Directory Record : Topic			*/

enum {
papOffsetofNextDirectoryRecordT,
papRecordInuseT,
papOffsetofReferencedLowerLevelDirectoryEntityT,
papDirectoryRecordTypeT,
papPrivateRecordUIDT,
papReferencedFileIDT,
papMRDRDirectoryRecordOffsetT,
papReferencedSOPClassUIDinFileT,
papReferencedSOPInstanceUIDinFileT,
papReferencedTransferSyntaxUIDinFileT,
papSpecificCharacterSetDRT,
papTopicTitleDRT,
papTopicSubjectDRT,
papTopicAuthorDRT,
papTopicKeyWordsDRT,
papEndTopic
};


/*	Directory Record : Visit			*/

enum {
papOffsetofNextDirectoryRecordVI,
papRecordInuseVI,
papOffsetofReferencedLowerLevelDirectoryEntityVI,
papDirectoryRecordTypeVI,
papPrivateRecordUIDVI,
papReferencedFileIDVI,
papMRDRDirectoryRecordOffsetVI,
papReferencedSOPClassUIDinFileVI,
papReferencedSOPInstanceUIDinFileVI,
papReferencedTransferSyntaxUIDinFileVI,
papAdmittingDateDRVI,
papAdmissionIDDRVI,
papInstitutionNameDRVI,
papSpecificCharacterSetDRVI,
papEndVisit
};



/*	Directory Record : Result			*/

enum {
papOffsetofNextDirectoryRecordR,
papRecordInuseR,
papOffsetofReferencedLowerLevelDirectoryEntityR,
papDirectoryRecordTypeR,
papPrivateRecordUIDR,
papReferencedFileIDR,
papMRDRDirectoryRecordOffsetR,
papReferencedSOPClassUIDinFileR,
papReferencedSOPInstanceUIDinFileR,
papReferencedTransferSyntaxUIDinFileR,
papResultsIDDRR,
papInstanceCreationDateDRR,
papSpecificCharacterSetDRR,
papEndResult
};



/*	Directory Record : Interpretation			*/

enum {
papOffsetofNextDirectoryRecordIN,
papRecordInuseIN,
papOffsetofReferencedLowerLevelDirectoryEntityIN,
papDirectoryRecordTypeIN,
papPrivateRecordUIDIN,
papReferencedFileIDIN,
papMRDRDirectoryRecordOffsetIN,
papReferencedSOPClassUIDinFileIN,
papReferencedSOPInstanceUIDinFileIN,
papReferencedTransferSyntaxUIDinFileIN,
papSpecificCharacterSetDRIN,
papInterpretationTranscriptionDateDRIN,
papInterpretationAuthorDRIN,
papInterpretationDiagnosisDescriptionDRIN,
papDiagnosisCodeSequenceDRIN,
papInterpretationIDDRIN,
papInterpretationTypeIDDRIN,
papInterpretationStatusIDDRIN,
papEndInterpretation
};



/*	Directory Record : StudyComponent			*/

enum {
papOffsetofNextDirectoryRecordSC,
papRecordInuseSC,
papOffsetofReferencedLowerLevelDirectoryEntitySC,
papDirectoryRecordTypeSC,
papPrivateRecordUIDSC,
papReferencedFileIDSC,
papMRDRDirectoryRecordOffsetSC,
papReferencedSOPClassUIDinFileSC,
papReferencedSOPInstanceUIDinFileSC,
papReferencedTransferSyntaxUIDinFileSC,
papSpecificCharacterSetDRSC,
papModalityDRSC,
papStudyDescriptionDRSC,
papProcedureCodeSequenceDRSC,
papPerformingPhysiciansNameDRSC,
papEndStudyComponentR
};



/*	Directory Record : PrintQueue			*/

enum {
papOffsetofNextDirectoryRecordPQ,
papRecordInusePQ,
papOffsetofReferencedLowerLevelDirectoryEntityPQ,
papDirectoryRecordTypePQ,
papPrivateRecordUIDPQ,
papReferencedFileIDPQ,
papMRDRDirectoryRecordOffsetPQ,
papReferencedSOPClassUIDinFilePQ,
papReferencedSOPInstanceUIDinFilePQ,
papReferencedTransferSyntaxUIDinFilePQ,
papPrintQueueIDDRPQ,
papSpecificCharacterSetDRPQ,
papPrinterNameDRPQ,
papEndPrintQueue
};



/*	Directory Record : FilmSession			*/

enum {
papOffsetofNextDirectoryRecordFS,
papRecordInuseFS,
papOffsetofReferencedLowerLevelDirectoryEntityFS,
papDirectoryRecordTypeFS,
papPrivateRecordUIDFS,
papReferencedFileIDFS,
papMRDRDirectoryRecordOffsetFS,
papReferencedSOPClassUIDinFileFS,
papReferencedSOPInstanceUIDinFileFS,
papReferencedTransferSyntaxUIDinFileFS,
papSpecificCharacterSetDRFS,
papFilmSessionLabelDRFS,
papExecutionStatusDRFS,
papEndFilmSession
};



/*	Directory Record : BasicFilmBox			*/

enum {
papOffsetofNextDirectoryRecordBFB,
papRecordInuseBFB,
papOffsetofReferencedLowerLevelDirectoryEntityBFB,
papDirectoryRecordTypeBFB,
papPrivateRecordUIDBFB,
papReferencedFileIDBFB,
papMRDRDirectoryRecordOffsetBFB,
papReferencedSOPClassUIDinFileBFB,
papReferencedSOPInstanceUIDinFileBFB,
papReferencedTransferSyntaxUIDinFileBFB,
papSpecificCharacterSetDRBFB,
papExecutionStatusDRBFB,
papEndBasicFilmBox
};


/*	Directory Record : BasicImageBox		*/

enum {
papOffsetofNextDirectoryRecordBIB,
papRecordInuseBIB,
papOffsetofReferencedLowerLevelDirectoryEntityBIB,
papDirectoryRecordTypeBIB,
papPrivateRecordUIDBIB,
papReferencedFileIDBIB,
papMRDRDirectoryRecordOffsetBIB,
papReferencedSOPClassUIDinFileBIB,
papReferencedSOPInstanceUIDinFileBIB,
papReferencedTransferSyntaxUIDinFileBIB,
papSpecificCharacterSetDRBIB,
papImagePosition2020DRBIB,
papEndBasicImageBox
};


#endif	    /* DicomdirEnumRecordsH */
