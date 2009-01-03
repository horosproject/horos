/********************************************************************************/
/*     		                                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyEnumMiscModules3.h                                       */
/*	Function : contains the declarations of the modules that are not	*/
/*		   in the image modules                                         */
/********************************************************************************/


#ifndef PapyEnumMiscModulesH 
#define PapyEnumMiscModulesH



/*pModulee : Basic Annotation Presentation		*/

enum {
papAnnotationPosition,
papTextString,
papEndBasicAnnotationPresentation
};




/*	pModule : Basic Film Box Presentation		*/

enum {
papImageDisplayFormat,
papAnnotationDisplayFormatID,
papFilmOrientation,
papFilmSizeID,
papMagnificationTypeBFBP,
papSmoothingTypeBFBP,
papBorderDensity,
papEmptyImageDensity,
papMinDensity,
papMaxDensity,
papTrim,
papConfigurationInformation,
papEndBasicFilmBoxPresentation
};




/*	pModule : Basic Film Box Relationship		*/

enum {
papReferencedFilmSessionSequence,
papReferencedImageBoxSequenceBFBR,
papReferencedBasicAnnotationBoxSequence,
papEndBasicFilmBoxRelationship
};




/*	pModule : Basic Film Session Presentation	*/

enum {
papNumberofCopies,
papPrintPriorityBFSP,
papMediumType,
papFilmDestination,
papFilmSessionLabel,
papMemoryAllocation,
papEndBasicFilmSessionPresentation
};




/*	pModule : File Reference				*/

enum {
papReferencedSOPClassUID,
papReferencedSOPInstanceUID,
papReferencedFileName,
papReferencedFilePath,
papEndFileReference
};



/*	pModule : Identifying Image Sequence		*/

enum {
papImageIdentifierSequence,
papEndIdentifyingImageSequence
};




/*	pModule : LUT Identification			*/

enum {
papLUTNumber,
papReferencedImageSequenceLI,
papEndLUTIdentification
};




/*	pModule : Patient Demographic			*/

enum {
papPatientsAddress,
papRegionofResidence,
papCountryofResidence,
papPatientsTelephoneNumbers,
papPatientsBirthDatePD,
papPatientsBirthTimePD,
papEthnicGroupPD,
papPatientsSexPD,
papPatientsSizePD,
papPatientsWeightPD,
papMilitaryRank,
papBranchofService,
papPatientsInsurancePlanCodeSequence,
papPatientsReligiousPreference,
papPatientCommentsPD,
papEndPatientDemographic
};




/*	pModule : Patient Identification			*/

enum {
papPatientsNamePI,
papPatientIDPI,
papIssuerofPatientID,
papOtherPatientIDs,
papOtherPatientNamesPI,
papPatientsBirthName,
papPatientsMothersBirthName,
papMedicalRecordLocator,
papEndPatientIdentification
};




/*	pModule : Patient Medical			*/

enum {
papPatientState,
papPregnancyStatus,
papMedicalAlerts,
papContrastAllergies,
papSpecialNeeds,
papLastMenstrualDate,
papSmokingStatus,
papAdditionalPatientHistory,
papEndPatientMedical
};




/*	pModule : Patient Relationship			*/

enum {
papReferencedVisitSequencePR,
papReferencedStudySequencePR,
papReferencedPatientAliasSequence,
papEndPatientRelationship
};




/*	pModule : Patient Summary			*/

enum {
papPatientsNamePS,
papPatientIDPS,
papEndPatientSummary
};





/*	pModule : Printer				*/

enum {
papPrinterStatus,
papPrinterStatusInfo,
papPrinterNameP,
papManufacturerP,
papManufacturerModelName,
papDeviceSerialNumberP,
papSoftwareVersionsP,
papDateOfLastCalibration,
papTimeOfLastCalibration,
papEndPrinter
};




/*	pModule : Print Job				*/

enum {
papExecutionStatus,
papExecutionStatusInfo,
papCreationDate,
papCreationTime,
papPrintPriorityPJ,
papPrinterNamePJ,
papOriginator,
papEndPrintJob
};




/*	pModule : Result Identification			*/

enum {
papResultsID,
papResultsIDIssuer,
papEndResultIdentification
};




/*	pModule : Results Impression			*/

enum {
papImpressions,
papResultsComments,
papEndResultsImpression
};




/*	pModule : Result Relationship			*/

enum {
papReferencedStudySequenceRR,
papReferencedInterpretationSequence,
papEndResultRelationship
};




/*	pModule : Study Acquisition			*/

enum {
papStudyArrivalDate,
papStudyArrivalTime,
papStudyDateSA,
papStudyTimeSA,
papStudyCompletionDate,
papStudyCompletionTime,
papStudyVerifiedDate,
papStudyVerifiedTime,
papSeriesinStudy,
papAcquisitionsinStudy,
papEndStudyAcquisition
};




/*	pModule : Study Classification			*/

enum {
papStudyStatusID,
papStudyPriorityID,
papStudyComments,
papEndStudyClassification
};




/*	pModule : Study Component Acquisition		*/

enum {
papModalitySCA,
papStudyDescriptionSCA,
papProcedureCodeSequence,
papPerformingPhysiciansNameSCA,
papStudyComponentStatusID,
papEndStudyComponentAcquisition
};




/*	pModule : Study Component			*/

enum {
papStudyIDSC,
papStudyInstanceUIDSC,
papReferencedSeriesSequenceSC,
papEndStudyComponent
};




/*	pModule : Study Component Relationship		*/

enum {
papReferencedStudySequenceSCR,
papEndStudyComponentRelationship
};




/*	pModule : Study Content				*/

enum {
papStudyIDSCt,
papStudyInstanceUIDSCt,
papReferencedSeriesSequenceSCt,
papEndStudyContent
};




/*	pModule : Study Identification			*/

enum {
papStudyIDSI,
papStudyIDIssuer,
papOtherStudyNumbers,
papEndStudyIdentification
};




/*	pModule : Study Read				*/

enum {
papNameofPhysiciansReadingStudySR,
papStudyReadDate,
papStudyReadTime,
papEndStudyRead
};




/*	pModule : Study Relationship			*/

enum {
papReferencedVisitSequenceSR,
papReferencedPatientSequenceSR,
papReferencedResultsSequenceSR,
papReferencedStudyComponentSequenceSR,
papStudyInstanceUIDSR,
papAccessionNumberSR,
papEndStudyRelationship
};




/*	pModule : Study Scheduling			*/

enum {
papScheduledStudyStartDate,
papScheduledStudyStartTime,
papScheduledStudyStopDate,
papScheduledStudyStopTime,
papScheduledStudyLocation,
papScheduledStudyLocationAETitle,
papReasonforStudy,
papRequestingPhysician,
papRequestingService,
papRequestedProcedureDescription,
papRequestedProcedureCodeSequence,
papRequestedContrastAgent,
papEndStudyScheduling
};




/*	pModule : US Frame of Reference			*/

enum {
papRegionLocationMinx0,
papRegionLocationMiny0,
papRegionLocationMaxx1,
papRegionLocationMaxy1,
papPhysicalUnitsXDirection,
papPhysicalUnitsYDirection,
papPhysicalDeltaX,
papPhysicalDeltaY,
papReferencePixelx0,
papReferencePixely0,
papRefPixelPhysicalValueX,
papRefPixelPhysicalValueY,
papEndUSFrameofReference
};




/*	pModule : Visit Admission			*/

enum {
papAdmittingDate,
papAdmittingTime,
papRouteofAdmissions,
papAdmittingDiagnosisDescription,
papAdmittingDiagnosisCodeSequence,
papReferringPhysiciansNameVA,
papAddress,
papReferringPhysiciansPhoneNumbers,
papEndVisitAdmission
};




/*	pModule : Visit Discharge			*/

enum {
papDischargeDate,
papDischargeTime,
papDescription,
papDischargeDiagnosisCodeSequence,
papEndVisitDischarge
};




/*	pModule : Visit Identification			*/

enum {
papInstitutionNameVI,
papInstitutionAddressVI,
papInstitutionCodeSequence,
papAdmissionID,
papIssuerofAdmissionID,
papEndVisitIdentification
};




/*	pModule : Visit Relationship			*/

enum {
papReferencedStudySequenceVR,
papReferencedPatientSequenceVR,
papEndVisitRelationship
};




/*	pModule : Visit Scheduling			*/

enum {
papScheduledAdmissionDate,
papScheduledAdmissionTime,
papScheduledDischargeDate,
papScheduledDischargeTime,
papScheduledPatientInstitutionResidence,
papEndVisitScheduling
};




/*	pModule : Visit Status				*/

enum {
papVisitStatusID,
papCurrentPatientLocationVS,
papPatientsInstitutionResidenceVS,
papVisitComments,
papEndVisitStatus
};




/*	pModule : Interpretation Approval		*/

enum {
papInterpretationApproverSequence,
papInterpretationDiagnosisDescription,
papInterpretationDiagnosisCodesSequence,
papResultsDistributionListSequence,
papEndInterpretationApproval
};




/*	pModule : Interpretation Transcription		*/

enum {
papInterpretationTranscriptionDate,
papInterpretationTranscriptionTime,
papInterpretationTranscriber,
papInterpretationText,
papInterpretationAuthor,
papEndInterpretationTranscription
};




/*	pModule : Interpretation State			*/

enum {
papInterpretationTypeID,
papInterpretationStatusID,
papEndInterpretationState
};




/*	pModule : Interpretation Recording		*/

enum {
papInterpretationRecordedDate,
papInterpretationRecordedTime,
papInterpretationRecorder,
papReferencetoRecordedSound,
papEndInterpretationRecording
};




/*	pModule : Interpretation Identification		*/

enum {
papInterpretationID,
papInterpretationIDIssuer,
papEndInterpretationIdentification
};




/*	pModule : Interpretation Relationship		*/

enum {
papReferencedResultsSequenceIR,
papEndInterpretationRelationship
};





/*	pModule : Image Overlay Box Relationship		*/

enum {
papReferencedImageBoxSequenceOBR,
papEndImageOverlayBoxRelationship
};




/*	pModule : Image Box Relationship			*/

enum {
papReferencedImageSequenceBR,
papReferencedImageOverlayBoxSequence,
papReferencedVOILUTSequence,
papEndImageBoxRelationship
};




/*	pModule : Image Box Pixel Presentation		*/

enum {
papImagePosition,
papPolarity,
papMagnificationTypeIBPP,
papSmoothingTypeIBPP,
papRequestedImageSize,
papPreformattedGrayscaleImageSequence,
papPreformattedColorImageSequence,
papEndImageBoxPixelPresentation
};




/*	pModule : Image Overlay Box Presentation		*/

enum {
papReferencedOverlayPlaneSequence,
papOverlayMagnificationType,
papOverlaySmoothingType,
papOverlayForegroundDensity,
papOverlayMode,
papThresholdDensity,
papEndImageOverlayBoxPresentation
};




/*	pModule : External Visit Reference Sequence	*/

enum {
papReferencedVisitSequenceEVRS,
papEndExternalVisitReferenceSequence
};




/*	pModule : External Study File Reference Sequence	*/

enum {
papReferencedStudySequenceESFRS,
papEndExternalStudyFileReferenceSequence
};




/*	pModule : External Patient File Reference Sequence*/

enum {
papReferencedPatientSequenceEPFRS,
papEndExternalPatientFileReferenceSequence
};




/*	pModule : External Papyrus_File Reference Sequence*/

enum {
papExternalPAPYRUSFileReferenceSequence,
papEndExternalPapyrus_FileReferenceSequence
};




/*	pModule : Basic Film Session Relationship	*/

enum {
papReferencedFilmBoxSequence,
papEndBasicFilmSessionRelationship
};


#endif	    /* PapyEnumMiscModulesH */
