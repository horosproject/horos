/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyEnumImagesModules3.h                                     */
/*	Function : contains the declarations of the modules needed for the  	*/
/*		   image objects .                                              */
/********************************************************************************/

#ifndef PapyEnumImagesModulesH 
#define PapyEnumImagesModulesH



/*pModulee : Acquisition Context	        */

enum {
papAcquisitionContextSequenceAC,
papAcquisitionContextDescriptionAC,
papEndAcquisitionContext
};


/*	pModule : Approval			*/

enum {
papApprovalStatus,
papReviewDate,
papReviewTime,
papReviewerName,
papEndApproval
};


/*	pModule : Audio			        */

enum {
papAudioType,
papAudioSampleFormat,
papNumberofChannels,
papNumberofSamples,
papSampleRate,
papTotalTime,
papAudioSampleData,
papReferencedImageSequenceAudio,
papAudioComments,
papEndAudio
};


/*	pModule : Basic Annotation Presentation	*/

enum {
papAnnotationPosition,
papTextString,
papEndBasicAnnotationPresentation
};


/*	pModule : Basic Film Box Presentation	*/

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


/*	pModule : Basic Film Box Relationship	*/

enum {
papReferencedFilmSessionSequence,
papReferencedImageBoxSequenceBFBR,
papReferencedBasicAnnotationBoxSequence,
papEndBasicFilmBoxRelationship
};


/*	pModule : Basic Film Session Presentation */

enum {
papNumberofCopies,
papPrintPriorityBFSP,
papMediumType,
papFilmDestination,
papFilmSessionLabel,
papMemoryAllocation,
papMaximumMemoryAllocation,
papEndBasicFilmSessionPresentation
};


/*	pModule : Basic Film Session Relationship */

enum {
papReferencedFilmBoxSequence,
papEndBasicFilmSessionRelationship
};


/*	pModule : BiPlane Image			*/

enum {
papSmallestImagePixelValueinPlane,
papLargestImagePixelValueinPlane,
papEndBiPlaneImage
};


/*	pModule : BiPlane Overlay		*/

enum {
papOverlayPlanes,
papOverlayPlaneOrigin,
papEndBiPlaneOverlay
};


/*	pModule : BiPlane Sequence		*/

enum {
papPlanes,
papBiPlaneAcquisitionSequence,
papEndBiPlaneSequence
};


/*	pModule : Cine				*/

enum {
papPreferredPlaybackSequencing,
papFrameTimeC,
papFrameTimeVector,
papStartTrim,
papStopTrim,
papRecommendedDisplayFrameRate,
papCineRate,
papFrameDelay,
papEffectiveDuration,
papActualFrameDurationC,
papEndCine
};


/*	pModule : Contrast Bolus			*/

enum {
papContrastBolusAgent,
papContrastBolusAgentSequence,
papContrastBolusRoute,
papContrastBolusAdministrationRouteSequence,
papContrastBolusVolume,
papContrastBolusStartTime,
papContrastBolusStopTime,
papContrastBolusTotalDose,
papContrastFlowRates,
papContrastFlowDurations,
papContrastBolusIngredient,
papContrastBolusIngredientConcentration,
papEndContrastBolus
};


/*	pModule : CR Image			*/

enum {
papKVPCRI,
papPlateID,
papDistanceSourcetoDetectorCRI,
papDistanceSourcetoPatientCRI,
papExposureTimeCRI,
papXrayTubeCurrentCRI,
papExposureCRI,
papImagerPixelSpacingCRI,
papGeneratorPowerCRI,
papAcquisitionDeviceProcessingDescription,
papAcquisitionDeviceProcessingCode,
papCassetteOrientation,
papCassetteSize,
papExposuresonPlate,
papRelativeXrayExposure,
papSensitivity,
papEndCRImage
};


/*	pModule : CR Series			*/

enum {
papBodyPartExaminedCRS,
papViewPosition,
papFilterTypeCRS,
papCollimatorgridnameCRS,
papFocalSpotCRS,
papPlateType,
papPhosphorType,
papEndCRSeries
};


/*	pModule : CT Image			*/

enum {
papImageTypeCTI,
papSamplesperPixelCTI,
papPhotometricInterpretationCTI,
papBitsAllocatedCTI,
papBitsStoredCTI,
papHighBitCTI,
papRescaleInterceptCTI,
papRescaleSlopeCTI,
papKVPCTI,
papAcquisitionNumberCTI,
papScanOptionsCTI,
papDataCollectionDiameter,
papReconstructionDiameterCTI,
papDistanceSourcetoDetectorCTI,
papDistanceSourcetoPatientCTI,
papGantryDetectorTiltCTI,
papTableHeightCTI,
papRotationDirectionCTI,
papExposureTimeCTI,
papXrayTubeCurrentCTI,
papExposureCTI,
papFilterTypeCTI,
papGeneratorPowerCTI,
papFocalSpotCTI,
papConvolutionKernelCTI,
papEndCTImage
};


/*	pModule : Curve				*/

enum {
papCurveDimensions,
papNumberofPoints,
papTypeofData,
papDataValueRepresentation,
papCurveData,
papCurveDescription,
papAxisUnits,
papAxisLabels,
papMinimumCoordinateValue,
papMaximumCoordinateValue,
papCurveRange,
papCurveDataDescriptor,
papCoordinateStartValue,
papCoordinateStepValue,
papCurveLabel,
papReferencedOverlaySequence5000,
papEndCurve
};


/*	pModule : Curve Identification		*/

enum {
papCurveNumber,
papCurveDate,
papCurveTime,
papReferencedImageSequenceCI,
papReferencedOverlaySequenceCI,
papReferencedCurveSequenceCI,
papEndCurveIdentification
};


/*	pModule : Device				*/

enum {
papDeviceSequence,
papEndDevice
};


/*	pModule : Directory Information	        */

enum {
papOffsetofTheFirstDirectoryRecord,
papOffsetofTheLastDirectoryRecord,
papFilesetConsistencyFlag,
papDirectoryRecordSequence,
papEndDirectoryInformation
};


/*	pModule : Display Shutter		*/

enum {
papShutterShapeDS,
papShutterLeftVerticalEdgeDS,
papShutterRightVerticalEdgeDS,
papShutterUpperHorizontalEdgeDS,
papShutterLowerHorizontalEdgeDS,
papCenterofCircularShutterDS,
papRadiusofCircularShutterDS,
papVerticesofthePolygonalShutterDS,
papEndDisplayShutter
};


/*	pModule : DX Anatomy Imaged	        */

enum {
papImageLateralityDXAI,
papAnatomicRegionSequenceDXAI,
papPrimaryAnatomicStructureSequenceDXAI,
papEndDXAnatomyImaged
};


/*	pModule : DX Image			*/

enum {
papImageTypeDXI,
papSamplesperPixelDXI,
papPhotometricInterpretationDXI,
papBitsAllocatedDXI,
papBitsStoredDXI,
papHighBitDXI,
papPixelRepresentationDXI,
papPixelIntensityRelationshipDXI,
papPixelIntensityRelationshipSignDXI,
papRescaleInterceptDXI,
papRescaleSlopeDXI,
papRescaleTypeDXI,
papPresentationLUTShapeDXI,
papLossyImageCompressionDXI,
papLossyImageCompressionRatioDXI,
papDerivationDescriptionDXI,
papAcquisitionDeviceProcessingDescriptionDXI,
papAcquisitionDeviceProcessingCodeDXI,
papPatientOrientationDXI,
papCalibrationObjectDXI,
papBurnedInAnnotationDXI,
papEndDXImage
};


/*	pModule : DX Detector			*/

enum {
papDetectorTypeDXD,
papDetectorConfigurationDXD,
papDetectorDescriptionDXD,
papDetectorModeDXD,
papDetectorIDDXD,
papDateofLastDetectorCalibrationDXD,
papTimeofLastDetectorCalibrationDXD,
papExposuresonDetectorSinceLastCalibrationDXD,
papExposuresonDetectorSinceManufacturedDXD,
papDetectorTimeSinceLastExposureDXD,
papDetectorActiveTimeDXD,
papDetectorActivationOffsetFromExposureDXD,
papDetectorBinningDXD,
papDetectorConditionsNominalFlagDXD,
papDetectorTemperatureDXD,
papSensitivityDXD,
papFieldofViewShapeDXD,
papFieldofViewDimensionsDXD,
papFieldofViewOriginDXD,
papFieldofViewRotationDXD,
papFieldofViewHorizontalFlipDXD,
papImagerPixelSpacingDXD,
papDetectorElementPhysicalSizeDXD,
papDetectorElementSpacingDXD,
papDetectorActiveShapeDXD,
papDetectorActiveDimensionsDXD,
papDetectorActiveOriginDXD,
papEndDXDetector
};


/*	pModule : DX Positioning			*/

enum {
papProjectionEponymousNameCodeSequenceDXP,
papPatientPositionDXP,
papViewPositionDXP,
papViewCodeSequenceDXP,
papViewModifierCodeSequenceDXP,
papPatientOrientationCodeSequenceDXP,
papPatientOrientationModifierCodeSequenceDXP,
papPatientGantryRelationshipCodeSequenceDXP,
papDistanceSourcetoPatientDXP,
papDistanceSourcetoDetectorDXP,
papEstimatedRadiographicMagnificationFactorDXP,
papPositionerTypeDXP,
papPositionerPrimaryAngleDXP,
papPositionerSecondaryAngleDXP,
papDetectorPrimaryAngleDXP,
papDetectorSecondaryAngleDXP,
papColumnAngulationDXP,
papTableTypeDXP,
papTableAngleDXP,
papBodyPartThicknessDXP,
papCompressionForceDXP,
papEndDXPositioning
};


/*	pModule : DX Series			*/

enum {
papModalityDX,
papReferencedStudyComponentSequence,
papPresentationIndentType,
papEndDXSeries
};


/*	pModule : External Papyrus_File Reference Sequence */

enum {
papExternalPAPYRUSFileReferenceSequence,
papEndExternalPapyrus_FileReferenceSequence
};


/*	pModule : External Patient File Reference Sequence */

enum {
papReferencedPatientSequenceEPFRS,
papEndExternalPatientFileReferenceSequence
};


/*	pModule : External Study File Reference Sequence	*/

enum {
papReferencedStudySequenceESFRS,
papEndExternalStudyFileReferenceSequence
};


/*	pModule : External Visit Reference Sequence	*/

enum {
papReferencedVisitSequenceEVRS,
papEndExternalVisitReferenceSequence
};


/*	pModule : File Reference			*/

enum {
papReferencedSOPClassUID,
papReferencedSOPInstanceUID,
papReferencedFileName,
papReferencedFilePath,
papEndFileReference
};


/*	pModule : File Set Identification	*/

enum {
papFilesetID,
papFileIDofFilesetDescriptorFile,
papFormatofFilesetDescriptorFile,
papEndFileSetIdentification
};


/*	pModule : Frame Of Reference		*/

enum {
papFrameofReferenceUID,
papPositionReferenceIndicator,
papEndFrameOfReference
};


/*	pModule : Frame Pointers			*/

enum {
papRepresentativeFrameNumber,
papFrameNumbersofInterest,
papFramesofInterestDescription,
papEndFramePointers
};


/*	pModule : General Equipment		*/

enum {
papManufacturerGE,
papInstitutionNameGE,
papInstitutionAddressGE,
papStationName,
papInstitutionalDepartmentName,
papManufacturersModelName,
papDeviceSerialNumberGE,
papSoftwareVersionsGE,
papSpatialResolution,
papDateofLastCalibration,
papTimeofLastCalibration,
papPixelPaddingValue,
papEndGeneralEquipment
};


/*	pModule : General Image			*/

enum {
papInstanceNumberGI,
papPatientOrientation,
papImageDate,
papImageTime,
papImageTypeGI,
papAcquisitionNumberGI,
papAcquisitionDate,
papAcquisitionTime,
papReferencedImageSequenceGI,
papDerivationDescription,
papSourceImageSequence,
papImagesinAcquisition,
papImageComments,
papLossyImageCompressionGI,
papEndGeneralImage
};


/*	pModule : General Patient Summary	*/

enum {
papPatientsNameGPS,
papPatientsID,
papPatientsBirthDateGPS,
papPatientsSexGPS,
papPatientsHeight,
papPatientsWeightGPS,
papEndGeneralPatientSummary
};


/*	pModule : General Series			*/

enum {
papModalityGS,
papSeriesInstanceUIDGS,
papSeriesNumberGS,
papLaterality,
papSeriesDate,
papSeriesTime,
papPerformingPhysiciansNameGS,
papProtocolName,
papSeriesDescription,
papOperatorsName,
papReferencedStudyComponentSequenceGS,
papBodyPartExaminedGS,
papPatientPosition,
papSmallestPixelValueinSeries,
papLargestPixelValueinSeries,
papEndGeneralSeries
};


/*	pModule : General Series Summary		*/

enum {
papModalityGSS,
papSeriesInstanceUIDGSS,
papSeriesNumberGSS,
papNumberofimages,
papEndGeneralSeriesSummary
};


/*	pModule : General Study			*/

enum {
papStudyInstanceUIDGS,
papStudyDateGS,
papStudyTimeGS,
papReferringPhysiciansNameGS,
papStudyIDGS,
papAccessionNumberGS,
papStudyDescriptionGS,
papPhysiciansOfRecordGS,
papNameofPhysiciansReadingStudyGS,
papReferencedStudySequenceGS,
papEndGeneralStudy
};


/*	pModule : General Study Summary		*/

enum {
papStudyDateGSS,
papStudyTimeGSS,
papStudyUID,
papStudyIDGSS,
papAccessionnumberGSS,
papReferringPhysiciansNameGSS,
papEndGeneralStudySummary
};


/*	pModule : General Visit Summary		*/

enum {
papCurrentPatientLocationGVS,
papPatientsInstitutionResidenceGVS,
papInstitutionNameVS,
papEndGeneralVisitSummary
};


/*	pModule : Icon Image			*/

enum {
papSamplesperPixelII,
papPhotometricInterpretationII,
papRowsII,
papColumnsII,
papBitsAllocatedII,
papBitsStoredII,
papHighBitII,
papPixelRepresentationII,
papRedPaletteColorLookupTableDescriptors,
papBluePaletteColorLookupTableDescriptors,
papGreenPaletteColorLookupTableDescriptors,
papRedPaletteColorLookupTableDataII,
papBluePaletteColorLookupTableDataII,
papGreenPaletteColorLookupTableDataII,
papPixelDataII,
papEndIconImage
};


/*	pModule : Identifying Image Sequence	*/

enum {
papImageIdentifierSequence,
papEndIdentifyingImageSequence
};


/*	pModule : Image Box Pixel Presentation	*/

enum {
papImagePosition,
papPolarity,
papMagnificationTypeIBPP,
papSmoothingTypeIBPP,
papRequestedImageSize,
papPreformattedGrayscaleImageSequence,
papPreformattedColorImageSequence,
papReferencedImageOverlayBoxSequenceIBP,
papReferencedSOPClassUID8,
papReferencedSOPInstanceUID8,
papEndImageBoxPixelPresentation
};


/*	pModule : Image Box Relationship		*/

enum {
papReferencedImageSequenceBR,
papReferencedImageOverlayBoxSequence,
papReferencedVOILUTSequence,
papEndImageBoxRelationship
};


/*	pModule : Image Histogram		*/

enum {
papHistogramSequenceIH,
papEndImageHistogram
};


/*	pModule : Image Identification		*/

enum {
papReferencedImageSOPClassUIDII,
papReferencedImageSOPInstanceUID,
papImageNumberII,
papEndImageIdentification
};


/*	pModule : Image Overlay Box Presentation	*/

enum {
papReferencedOverlayPlaneSequence,
papOverlayMagnificationType,
papOverlaySmoothingType,
papOverlayForegroundDensity,
papOverlayMode,
papThresholdDensity,
papEndImageOverlayBoxPresentation
};


/*	pModule : Image Overlay Box Relationship	*/

enum {
papReferencedImageBoxSequenceOBR,
papEndImageOverlayBoxRelationship
};


/*	pModule : Image Pixel			*/

enum {
papSamplesperPixelIP,
papPhotometricInterpretationIP,
papRows,
papColumns,
papBitsAllocatedIP,
papBitsStoredIP,
papHighBitIP,
papPixelRepresentationIP,
papPixelData,
papPlanarConfiguration,
papPixelAspectRatio,
papSmallestImagePixelValue,
papLargestImagePixelValue,
papRedPaletteColorLookupTableDescriptor,
papGreenPaletteColorLookupTableDescriptor,
papBluePaletteColorLookupTableDescriptor,
papRedPaletteColorLookupTableData,
papGreenPaletteColorLookupTableData,
papBluePaletteColorLookupTableData,
papEndImagePixel
};


/*	pModule : Image Plane			*/

enum {
papPixelSpacing,
papImageOrientationPatient,
papImagePositionPatient,
papSliceThickness,
papSliceLocation,
papEndImagePlane
};


/*	pModule : Image Pointer			*/

enum {
papImagePointer,
papEndImagePointer
};


/*	pModule : Image Sequence			*/

enum {
papImageSequence,
papEndImageSequence
};


/*	pModule : Internal Image Pointer Sequence */

enum {
papPointerSequence,
papEndInternalImagePointerSequence
};


/*	pModule : Interpretation Approval	*/

enum {
papInterpretationApproverSequence,
papInterpretationDiagnosisDescription,
papInterpretationDiagnosisCodesSequence,
papResultsDistributionListSequence,
papEndInterpretationApproval
};


/*	pModule : Interpretation Identification	*/

enum {
papInterpretationID,
papInterpretationIDIssuer,
papEndInterpretationIdentification
};


/*	pModule : Interpretation Recording	*/

enum {
papInterpretationRecordedDate,
papInterpretationRecordedTime,
papInterpretationRecorder,
papReferencetoRecordedSound,
papEndInterpretationRecording
};


/*	pModule : Interpretation Relationship	*/

enum {
papReferencedResultsSequenceIR,
papEndInterpretationRelationship
};


/*	pModule : Interpretation State		*/

enum {
papInterpretationTypeID,
papInterpretationStatusID,
papEndInterpretationState
};


/*	pModule : Interpretation Transcription	*/

enum {
papInterpretationTranscriptionDate,
papInterpretationTranscriptionTime,
papInterpretationTranscriber,
papInterpretationText,
papInterpretationAuthor,
papEndInterpretationTranscription
};


/*	pModule : Intra Oral Image		*/

enum {
papPositionerTypeIOI,
papImageLateralityIOI,
papAnatomicRegionSequenceIOI,
papAnatomicRegionModifierSequenceIOI,
papPrimaryAnatomicStructureSequenceIOI,
papEndIntraOralImage
};


/*	pModule : Intra Oral Series		*/

enum {
papModalityIOS,
papEndIntraOralSeries
};


/*	pModule : LUT Identification		*/

enum {
papLUTNumber,
papReferencedImageSequenceLI,
papEndLUTIdentification
};


/*	pModule : Mammography Image		*/

enum {
papPositionerTypeMI,
papPositionerPrimaryAngleMI,
papPositionerSecondaryAngleMI,
papImageLateralityMI,
papOrganExposedMI,
papAnatomicRegionSequenceMI,
papViewCodeSequenceMI,
papViewModifierCodeSequenceMI,
papEndMammographyImage
};


/*	pModule : Mammography Series		*/

enum {
papModalityMS,
papEndMammographySeries
};


/*	pModule : Mask				*/

enum {
papMaskSubtractionSequence,
papRecommendedViewingMode,
papEndMask
};


/*	pModule : Modality LUT		        */

enum {
papModalityLUTSequence,
papRescaleInterceptML,
papRescaleSlopeML,
papRescaleType,
papEndModalityLUT
};


/*	pModule : MR Image			*/

enum {
papImageTypeMRI,
papSamplesperPixelMRI,
papPhotometricInterpretationMRI,
papBitsAllocatedMRI,
papScanningSequence,
papSequenceVariant,
papScanOptionsMRI,
papMRAcquisitionTypeMRI,
papRepetitionTime,
papEchoTime,
papEchoTrainLength,
papInversionTime,
papTriggerTimeMRI,
papSequenceName,
papAngioFlag,
papNumberofAverages,
papImagingFrequency,
papImagedNucleus,
papEchoNumber,
papMagneticFieldStrength,
papSpacingBetweenSlices,
papNumberofPhaseEncodingSteps,
papPercentSampling,
papPercentPhaseFieldofView,
papPixelBandwidth,
papNominalIntervalMRI,
papBeatRejectionFlagMRI,
papLowRRValueMRI,
papHighRRValueMRI,
papIntervalsAcquiredMRI,
papIntervalsRejectedMRI,
papPVCRejectionMRI,
papSkipBeatsMRI,
papHeartRateMRI,
papCardiacNumberofImagesMRI,
papTriggerWindow,
papReconstructionDiameterMRI,
papReceivingCoil,
papTransmittingCoil,
papAcquisitionMatrix,
papPhaseEncodingDirection,
papFlipAngle,
papSAR,
papVariableFlipAngleFlag,
papdBdt,
papTemporalPositionIdentifier,
papNumberofTemporalPositions,
papTemporalResolution,
papEndMRImage
};


/*	pModule : Multi_Frame			*/

enum {
papNumberofFrames,
papFrameIncrementPointerMF,
papEndMulti_Frame
};


/*	pModule : Multi_frame Overlay		*/

enum {
papNumberofFramesinOverlay,
papImageFrameOrigin,
papEndMulti_frameOverlay
};


/*	pModule : NM Detector			*/

enum {
papDetectorInformationSequence,
papEndNMDetector
};


/*	pModule : NM Image			*/

enum {
papImageType,
papImageID,
papLossyImageCompressionNMI,
papCountsAccumulated,
papAcquisitionTerminationCondition,
papTableHeightNMI,
papTableTraverseNMI,
papActualFrameDurationNMI,
papCountRate,
papPreprocessingFunctionNMI,
papCorrectedImage,
papWholeBodyTechnique,
papScanVelocity,
papScanLength,
papReferencedOverlaySequenceNMI,
papReferencedCurveSequenceNMI,
papTriggerSourceorType,
papAnatomicRegionSequence,
papPrimaryAnatomicStructureSequence,
papEndNMImage
};


/*	pModule : NM Image Pixel			*/

enum {
papSamplesperPixel,
papPhotometricInterpretation,
papBitsAllocated,
papBitsStored,
papHighBit,
papPixelSpacingNM,
papEndNMImagePixel
};


/*	pModule : NM Isotope	  	        */

enum {
papEnergyWindowInformationSequence,
papRadiopharmaceuticalInformationSequence,
papInterventionDrugInformationSequence,
papEndNMIsotope
};
  

/*	pModule : NM Multi Frame			*/

enum {
papFrameIncrementPointer,
papEnergyWindowVector,
papNumberofEnergyWindows,
papDetectorVector,
papNumberofDetectors,
papPhaseVector,
papNumberofPhases,
papRotationVector,
papNumberofRotations,
papRRIntervalVector,
papNumberofRRIntervals,
papTimeSlotVector,
papNumberofTimeSlots,
papSliceVector,
papNumberofSlices,
papAngularViewVector,
papTimeSliceVector,
papEndNMMultiFrame
};


/*	pModule : NM Multi_gated Acquisition Image */

enum {
papBeatRejectionFlagNMAI,
papPVCRejectionNMAI,
papSkipBeatsNMAI,
papHeartRateNMAI,
papGatedInformationSequenceNMAI,
papEndNMMulti_gatedAcquisitionImage
};


/*	pModule : NM Phase	                */

enum {
papPhaseInformationSequence,
papEndNMPhase
};


/*	pModule : NM Reconstruction	        */

enum {
papSpacingBetweenSlicesNM,
papReconstructionDiameter,
papConvolutionKernel,
papSliceThicknessNM,
papSliceLocationNM,
papEndNMReconstruction
};


/*	pModule : NM Series			*/

enum {
papPatientOrientationCodeSequence,
papPatientGantryRelationshipCodeSequence,
papEndNMSeries
};


/*	pModule : NM Tomo Acquisition		*/

enum {
papRotationInformationSequence,
papTypeofDetectorMotion,
papEndNMTomoAcquisition
};


/*	pModule : Overlay Identification		*/

enum {
papOverlayNumber,
papOverlayDate,
papOverlayTime,
papReferencedImageSequenceOI,
papEndOverlayIdentification
};


/*	pModule : Overlay Plane			*/

enum {
papRowsOP,
papColumnsOP,
papOverlayType,
papOrigin,
papBitsAllocatedOP,
papBitPosition,
papOverlayData,
papOverlayDescription,
papOverlaySubtypeOP,
papOverlayLabel,
papROIArea,
papROIMean,
papROIStandardDeviation,
papOverlayDescriptorGray,
papOverlayDescriptorRed,
papOverlayDescriptorGreen,
papOverlayDescriptorBlue,
papOverlaysGray,
papOverlaysRed,
papOverlaysGreen,
papOverlaysBlue,
papEndOverlayPlane
};


/*	pModule : Palette Color Lookup	         */

enum {
papRedPaletteColorLookupTableDescriptorPCL,
papGreenPaletteColorLookupTableDescriptorPCL,
papBluePaletteColorLookupTableDescriptorPCL,
papPaletteColorLookupTableUID,
papRedPaletteCLUTData,
papGreenPaletteCLUTData,
papBluePaletteCLUTData,
papSegmentedRedPaletteColorLookupTableData,
papSegmentedGreenPaletteColorLookupTableData,
papSegmentedBluePaletteColorLookupTableData,
papEndPaletteColorLookup
};


/*	pModule : Patient			*/

enum {
papPatientsNameP,
papPatientIDP,
papPatientsBirthDateP,
papPatientsSexP,
papReferencedPatientSequenceP,
papPatientsBirthTimeP,
papOtherPatientID,
papOtherPatientNamesP,
papEthnicGroupP,
papPatientCommentsP,
papEndPatient
};


/*	pModule : Patient Demographic		*/

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


/*	pModule : Patient Identification		*/

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


/*	pModule : Patient Medical		*/

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


/*	pModule : Patient Relationship		*/

enum {
papReferencedVisitSequencePR,
papReferencedStudySequencePR,
papReferencedPatientAliasSequence,
papEndPatientRelationship
};


/*	pModule : Patient Study			*/

enum {
papAdmittingDiagnosesDescription,
papPatientsAge,
papPatientsSizePS,
papPatientsWeightPS,
papOccupation,
papAdditionalPatientsHistory,
papEndPatientStudy
};


/*	pModule : Patient Summary		*/

enum {
papPatientsNamePS,
papPatientIDPS,
papEndPatientSummary
};


/*	pModule : PET Curve		*/

enum {
papCurveDimensionsPC,
papTypeofDataPC,
papCurveDataPC,
papAxisUnitsPC,
papDeadTimeCorrectionFlag,
papCountsIncluded,
papPreprocessingFunction,
papEndPETCurve
};


/*	pModule : PET Image		*/

enum {
papImageTypePI,
papSamplesPerPixelPI,
papPhotometricInterpretationPI,
papBitsAllocatedPI,
papBitsStoredPI,
papHighBitPI,
papRescaleInterceptPI,
papRescaleSlopePI,
papFrameReferenceTime,
papTriggerTime,
papFrameTime,
papLowRRValue,
papHighRRValue,
papLossyImageCompression,
papImageIndex,
papAcquisitionDatePI,
papAcquisitionTimePI,
papActualFrameDuration,
papNominalInterval,
papIntervalsAcquired,
papIntervalsRejected,
papPrimaryCountsAccumulated,
papSecondaryCountsAccumulated,
papSliceSensitivityFactor,
papDecayFactor,
papDoseCalibrationFactor,
papScatterFractionFactor,
papDeadTimeFactor,
papReferencedOverlaySequence,
papReferencedCurveSequence,
papAnatomicRegionSequencePI,
papPrimaryAnatomicStructureSequencePI,
papEndPETImage
};


/*	pModule : PET Isotope		*/

enum {
papRadiopharmaceuticalInformationSequencePI,
papInterventionDrugInformationSequencePI,
papEndPETIsotope
};


/*	pModule : PET Multi-gated Acquisition	*/

enum {
papBeatRejectionFlag,
papTriggerSourceOrType,
papPVCRejection,
papSkipBeats,
papHeartRate,
papFramingType,
papEndPETMultiGatedAcquisition
};


/*	pModule : PET Series			*/

enum {
papSeriesDatePET,
papSeriesTimePET,
papUnits,
papCountsSource,
papSeriesType,
papReprojectionMethod,
papNumberofRRIntervalsPET,
papNumberofTimeSlotsPET,
papNumberofSlicesPET,
papNumberofRotationsPET,
papRandomsCorrectionMethod,
papAttenuationCorrectionMethod,
papScatterCorrectionMethod,
papDecayCorrection,
papReconstructionDiameterPET,
papConvolutionKernelPET,
papReconstructionMethod,
papDetectorLinesOfResponseUsed,
papAcquisitionStartCondition,
papAcquisitionStartConditionData,
papAcquisitionTerminationConditionPET,
papAcquisitionTerminationConditionData,
papFieldofViewShape,
papFieldofViewDimensions,
papGantryDetectorTilt,
papGantryDetectorSlew,
papTypeofDetectorMotionPET,
papCollimatorType,
papCollimatorgridName,
papAxialAcceptance,
papAxialMash,
papTransverseMash,
papDetectorElementSize,
papCoincidenceWindowWidth,
papEnergyWindowRangeSequence,
papEnergyWindowLowerLimit,
papEnergyWindowUpperLimit,
papSecondaryCountsType,
papEndPETSeries
};


/*	pModule : Pixel Offset			*/

enum {
papPixelOffset,
papEndPixelOffset
};


/*	pModule : Printer			*/

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


/*	pModule : Print Job			*/

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


/*	pModule : Result Identification		*/

enum {
papResultsID,
papResultsIDIssuer,
papEndResultIdentification
};


/*	pModule : Results Impression		*/

enum {
papImpressions,
papResultsComments,
papEndResultsImpression
};


/*	pModule : Result Relationship		*/

enum {
papReferencedStudySequenceRR,
papReferencedInterpretationSequence,
papEndResultRelationship
};


/*	pModule : RF Tomography Acquisition	*/

enum {
papTornoLayerHeight,
papTornoAngle,
papTornoTime,
papEndRFTomographyAcquisition
};


/*	pModule : ROI Contour			*/

enum {
papROIContourSequence,
papContourNumber,
papAttachedContours,
papEndROIContour
};


/*	pModule : RT Beams			*/

enum {
papBeamSequence,
papHighDoseTechniqueType,
papCompensatorNumber,
papCompensatorType,
papEndRTBeams
};


/*	pModule : RT Brachy Application Setups   */

enum {
papBrachyTreatmentTechnique,
papBrachyTreatmentType,
papTreatmentMachineSequence,
papSourceSequence,
papApplicationSetupSequence,
papEndRTBrachyApplicationSetups
};


/*	pModule : RT Dose			*/

enum {
papSamplesperPixelRTD,
papPhotometricInterpretationRTD,
papBitsAllocatedRTD,
papBitsStoredRTD,
papHighBitRTD,
papPixelRepresentationRTD,
papDoseUnitsRTD,
papDoseTypeRTD,
papInstanceNumber,
papDoseCommentRTD,
papNormalizationPointRTD,
papDoseSummationTypeRTD,
papReferencedRTPlanSequenceRTD,
papGridFrameOffsetVectorRTD,
papDoseGridScalingRTD,
papEndRTDose
};


/*	pModule : RT Dose ROI		        */

enum {
papRTDoseROISequence,
papEndRTDoseROI
};


/*	pModule : RT DVH			        */

enum {
papReferencedStructureSetSequence,
papDVHNormalizationPoint,
papDVHNormalizationDoseValue,
papDVHSequence,
papEndRTDVH
};


/*	pModule : RT Fraction Scheme		*/

enum {
papFractionGroupSequence,
papEndRTFractionScheme
};


/*	pModule : RT General Plan		*/

enum {
papRTPlanLabel,
papRTPlanName,
papRTPlanDescription,
papRTPlanInstanceNumber,
papOperatorsNameRTGP,
papRTPlanDate,
papRTPlanTime,
papTreatmentProtocols,
papTreatmentIntent,
papTreatmentSites,
papRTPlanGeometry,
papReferencedStructureSetSequenceRTGP,
papReferencedDoseSequence,
papReferencedRTPlanSequence,
papEndRTGeneralPlan
};


/*	pModule : RT Image			*/

enum {
papSamplesperPixelRTI,
papPhotometricInterpretationRTI,
papBitsAllocatedRTI,
papBitsStoredRTI,
papHighBitRTI,
papPixelRepresentationRTI,
papRTImageLabelRTI,
papRTImageNameRTI,
papRTImageDescriptionRTI,
papOperatorsNameRTI,
papImageTypeRTI,
papConversionTypeRTI,
papReportedValuesOriginRTI,
papRTImagePlaneRTI,
papXRayImageReceptortranslation,
papXRayImageReceptorAngleRTI,
papRTImageOrientationRTI,
papImagePlanePixelSpacingRTI,
papRTImagePositionRTI,
papRadiationMachineNameRTI,
papPrimaryDosimeterUnitRTI,
papRadiationMachineSADRTI,
papRadiationMachineSSDRTI,
papRTImageSIDRTI,
papSourcetoReferenceObjectDistanceRTI,
papReferencedRTPlanSequenceRTI,
papReferencedBeamNumberRTI,
papReferencedFractionGroupNumberRTI,
papFractionNumberRTI,
papStartCumulativeMetersetWeightRTI,
papEndCumulativeMetersetWeightRTI,
papExposureSequenceRTI,
papGantryAngleRTI,
papDiaphragmPosition,
papBeamLimitingDeviceAngleRTI,
papPatientSupportAngleRTI,
papTableTopEccentricAxisDistanceRTI,
papTableTopEccentricAngleRTI,
papTableTopVerticalPositionRTI,
papTableTopLongitudinalPositionRTI,
papTableTopLateralPositionRTI,
papEndRTImage
};


/*	pModule : RT Patient Setup               */

enum {
papPatientSetupSequence,
papEndRTPatientSetup
};


/*	pModule : RT Prescription		*/

enum {
papPrescriptionDescription,
papDoseReferenceSequence,
papEndRTPrescription
};


/*	pModule : RT ROI Observations		*/

enum {
papRTROIObservationsSequence,
papEndRTROIObservations
};


/*	pModule : RT Series			*/

enum {
papModalityRTS,
papSeriesInstanceUIDRTS,
papSeriesNumberRTS,
papSeriesDescriptionRTS,
papReferencedStudyComponentSequenceRTS,
papEndRTSeries
};


/*	pModule : RT Tolerance Tables		*/

enum {
papToleranceTableSequence,
papEndRTToleranceTables
};


/*	pModule : Structure Set			*/

enum {
papStructureSetLabel,
papStructureSetName,
papStructureSetDescription,
papStructureSetDate,
papStructureSetTime,
papReferencedFrameofReferenceSequence,
papStructureSetROISequence,
papEndStructureSet
};



/*	pModule : SC Image				*/

enum {
papDateofSecondaryCapture,
papTimeofSecondaryCapture,
papEndSCImage
};


/*	pModule : SC Image Equipment			*/

enum {
papConversionType,
papModalitySIE,
papSecondaryCaptureDeviceID,
papSecondaryCaptureDeviceManufacturer,
papSecondaryCaptureDeviceManufacturersModelName,
papSecondaryCaptureDeviceSoftwareVersion,
papVideoImageFormatAcquired,
papDigitalImageFormatAcquired,
papEndSCImageEquipment
};


/*	pModule : SC Multi-Frame Image				*/

enum {
papZoomFactor,
papPresentationLUTShape,
papIllumination,
papReflectedAmbientLight,
papRescaleIntercept,
papRescaleSlope,
papRescaleTypeSCMF,
papFrameIncrementPointerSCMF,
papNominalScannedPixelSpacing,
papDigitizingDeviceTransportDirection,
papRotationOfScannedFilm,
papEndSCMultiFrameImage
};


/*	pModule : SC Multi-Frame Vector				*/

enum {
papFrameTimeVectorSCMFV,
papPageNumberVector,
papFrameLabelVector,
papFramePrimaryAngleVector,
papFrameSecondaryAngleVector,
papSliceLocationVector,
papDisplayWindowLabelVector,
papEndSCMultiFrameVector
};


/*	pModule : Slide Coordinates				*/

enum {
papImageCenterPointCoordinatesSequence,
papXOffsetInSlideCoordinateSystem,
papYOffsetInSlideCoordinateSystem,
papZOffsetInSlideCoordinateSystem,
papPixelSpacingSequence,
papEndSlideCoordinates
};


/*	pModule : SOP Common				*/

enum {
papSOPClassUID,
papSOPInstanceUID,
papSpecificCharacterSet,
papInstanceCreationDate,
papInstanceCreationTime,
papInstanceCreatorUID,
papTimezoneOffsetFromUTC,
papEndSOPCommon
};


/*	pModule : Specimen Identification				*/

enum {
papSpecimenAccessionNumber,
papSpecimenSequence,
papEndSpecimenIdentification
};


/*	pModule : Study Acquisition			*/

enum {
papStudyArrivalDate,
papStudyArrivalTime,
papStudyDateSA,
papStudyTimeSA,
papModalitiesInStudy,
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


/*	pModule : Study Component			*/

enum {
papStudyIDSC,
papStudyInstanceUIDSC,
papReferencedSeriesSequenceSC,
papEndStudyComponent
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


/*	pModule : Therapy			        */

enum {
papInterventionalTherapySequenceTH,
papEndTherapy
};


/*	pModule : UIN Overlay Sequence			*/

enum {
papOwnerID,
papUINOverlaySequence,
papEndUINOverlaySequence
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


/*	pModule : US Image				*/

enum {
papSamplesperPixelUSI,
papPhotometricInterpretationUSI,
papBitsAllocatedUSI,
papBitsStoredUSI,
papHighBitUSI,
papPlanarConfigurationUSI,
papPixelRepresentationUSI,
papFrameIncrementPointerUSI,
papImageTypeUSI,
papLossyImageCompressionUSI,
papNumberofStages,
papNumberofViewsinStage,
papUltrasoundColorDataPresent,
papReferencedOverlaySequenceUSI,
papReferencedCurveSequenceUSI,
papStageName,
papStageCodeSequence,
papStageNumber,
papViewName,
papViewNumber,
papNumberofEventTimers,
papEventElapsedTimes,
papEventTimerNames,
papAnatomicRegionSequenceUSI,
papPrimaryAnatomicStructureSequenceUSI,
papTransducerPositionSequence,
papTransducerOrientationSequence,
papTriggerTimeUSI,
papNominalIntervalUSI,
papBeatRejectionFlagUSI,
papLowRRValueUSI,
papHighRRValueUSI,
papHeartRateUSI,
papOutputPower,
papTransducerData,
papTransducerType,
papFocusDepth,
papPreprocessingFunctionUSI,
papMechanicalIndex,
papBoneThermalIndex,
papCranialThermalIndex,
papSoftTissueThermalIndex,
papSoftTissuefocusThermalIndex,
papSoftTissuesurfaceThermalIndex,
papDepthofScanField,
papImageTransformationMatrix,
papImageTranslationVector,
papOverlaySubtype,
papEndUSImage
};


/*	pModule : US Region Calibration			*/

enum {
papSequenceofUltrasoundRegions,
papEndUSRegionCalibration
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

/*	pModule : VL Image				*/

enum {
papImageTypeVL,
papPhotometricInterpretationVL,
papBitsAllocatedVL,
papBitsStoredVL,
papHighBitVL,
papPixelRepresentationVL,
papSamplesperPixelVL,
papPlanarConfigurationVL,
papImageTimeVL,
papLossyImageCompressionVL,
papReferencedImageSequenceVL,
papEndVLImage
};


/*	pModule : VOI LUT				*/

enum {
papVOILUTSequence,
papWindowCenter,
papWindowWidth,
papWindowCenterWidthExplanation,
papEndVOILUT
};


/*	pModule : XRay Acquisition			*/

enum {
papKVP,
papRadiationSetting,
papXrayTubeCurrent,
papExposureTime,
papExposure,
papGrid,
papAveragePulseWidth,
papRadiationMode,
papTypeofFilters,
papIntensifierSize,
papFieldofViewShapeXRA,
papFieldofViewDimensionsXRA,
papImagerPixelSpacing,
papFocalSpots,
papImageAreaDoseProduct,
papEndXRayAcquisition
};


/*	pModule : XRay Acquisition Dose			*/

enum {
papKVPXRAD,
papXrayTubeCurrentXRAD,
papExposureTimeXRAD,
papExposureXRAD,
papDistanceSourcetoDetectorXRAD,
papDistanceSourcetoPatientXRAD,
papImageAreaDoseProductXRAD,
papBodyPartThicknessXRAD,
papEntranceDoseXRAD,
papExposedAreaXRAD,
papDistanceSourcetoEntranceXRAD,
papCommentsonRadiationDoseXRAD,
papXRayOutputXRAD,
papHalfValueLayerXRAD,
papOrganDoseXRAD,
papOrganExposedXRAD,
papAnodeTargetMaterialXRAD,
papFilterMaterialXRAD,
papFilterThicknessMinimumXRAD,
papFilterThicknessMaximumXRAD,
papRectificationTypeXRAD,
papEndXRayAcquisitionDose
};


/*	pModule : XRay Collimator			*/

enum {
papCollimatorShape,
papCollimatorLeftVerticalEdge,
papCollimatorRightVerticalEdge,
papCollimatorUpperHorizontalEdge,
papCollimatorLowerHorizontalEdge,
papCenterofCircularCollimator,
papRadiusofCircularCollimator,
papVerticesofthePolygonalCollimator,
papEndXRayCollimator
};


/*	pModule : XRay Filtration				*/

enum {
papFilterTypeXRF,
papFilterMaterialXRF,
papFilterThicknessMinimumXRF,
papFilterThicknessMaximumXRF,
papEndXRayFiltration
};


/*	pModule : XRay Generation				*/

enum {
papKVPXRG,
papXrayTubeCurrentXRG,
papExposureTimeXRG,
papExposureXRG,
papExposureinmAsXRG,
papExposureControlModeXRG,
papExposureControlModeDescriptionXRG,
papExposureStatusXRG,
papPhototimerSettingXRG,
papFocalSpotsXRG,
papAnodeTargetMaterialXRG,
papRectificationTypeXRG,
papEndXRayGeneration
};


/*	pModule : XRay Grid				*/

enum {
papGridXRG,
papGridAbsorbingMaterialXRG,
papGridSpacingMaterialXRG,
papGridThicknessXRG,
papGridPitchXRG,
papGridAspectRatioXRG,
papGridPeriodXRG,
papGridFocalDistanceXRG,
papEndXRayGrid
};


/*	pModule : XRay Image				*/

enum {
papFrameIncrementPointerXR,
papLossyImageCompressionXR,
papImageTypeXR,
papPixelIntensityRelationshipXR,
papSamplesperPixelXR,
papPhotometricInterpretationXR,
papBitsAllocatedXR,
papBitsStoredXR,
papHighBitXR,
papPixelRepresentationXR,
papScanOptionsXR,
papAnatomicRegionSequenceXR,
papPrimaryAnatomicStructureSequenceXR,
papRWavePointerXR,
papReferencedImageSequenceXR,
papDerivationDescriptionXR,
papAcquisitionDeviceProcessingDescriptionXR,
papCalibrationObjectXR,
papEndXRayImage
};


/*	pModule : XRay Table			*/

enum {
papTableMotion,
papTableVerticalIncrement,
papTableLongitudinalIncrement,
papTableLateralIncrement,
papTableAngle,
papEndXRayTable
};


/*	pModule : XRay Tomography Acquisition	*/

enum {
papTornoTypeXRTA,
papTornoClassXRTA,
papTornoLayerHeightXRTA,
papTornoAngleXRTA,
papTornoTimeXRTA,
papNumberofTornosynthesisSourceImagesXRTA,
papEndXRayTomographyAcquisition
};


/*	pModule : XRF Positioner	*/

enum {
papDistanceSourceToDetector,
papDistanceSourcetoPatient,
papEstimatedRadiographicMagnificationFactor,
papColumnAngulation,
papEndXRFPositioner
};





#endif	    /* PapyEnumImagesModulesH */
