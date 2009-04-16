/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMAbstractSyntaxUID.h"

static NSString *DCM_Verification = @"1.2.840.10008.1.1";

// Images ...

	/***/
	static NSString *ComputedRadiographyImageStorage = @"1.2.840.10008.5.1.4.1.1.1";
	/***/
	static NSString *DigitalXRayImageStorageForPresentation = @"1.2.840.10008.5.1.4.1.1.1.1";
	/***/
	static NSString *DigitalXRayImageStorageForProcessing = @"1.2.840.10008.5.1.4.1.1.1.1.1";
	/***/
	static NSString *DigitalMammographyXRayImageStorageForPresentation = @"1.2.840.10008.5.1.4.1.1.1.2";
	/***/
	static NSString *DigitalMammographyXRayImageStorageForProcessing = @"1.2.840.10008.5.1.4.1.1.1.2.1";
	/***/
	static NSString *DigitalIntraoralXRayImageStorageForPresentation = @"1.2.840.10008.5.1.4.1.1.1.3";
	/***/
	static NSString *DigitalIntraoralXRayImageStorageForProcessing = @"1.2.840.10008.5.1.4.1.1.1.3.1";
	/***/
	static NSString *CTImageStorage = @"1.2.840.10008.5.1.4.1.1.2";
	/***/
	static NSString *EnhancedCTImageStorage = @"1.2.840.10008.5.1.4.1.1.2.1";
	/***/
	static NSString *EnhancedPETImageStorage = @"1.2.840.10008.5.1.4.1.1.130";
	/***/
	static NSString *UltrasoundMultiframeImageStorageRetired = @"1.2.840.10008.5.1.4.1.1.3";
	/***/
	static NSString *UltrasoundMultiframeImageStorage = @"1.2.840.10008.5.1.4.1.1.3.1";
	/***/
	static NSString *MRImageStorage = @"1.2.840.10008.5.1.4.1.1.4";
	/***/
	static NSString *EnhancedMRImageStorage = @"1.2.840.10008.5.1.4.1.1.4.1";
	/***/
	static NSString *NuclearMedicineImageStorageRetired = @"1.2.840.10008.5.1.4.1.1.5";
	/***/
	static NSString *UltrasoundImageStorageRetired = @"1.2.840.10008.5.1.4.1.1.6";
	/***/
	static NSString *UltrasoundImageStorage = @"1.2.840.10008.5.1.4.1.1.6.1";
	/***/
	static NSString *SecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7";
	/***/
	static NSString *MultiframeSingleBitSecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7.1";
	/***/
	static NSString *MultiframeGrayscaleByteSecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7.2";
	/***/
	static NSString *MultiframeGrayscaleWordSecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7.3";
	/***/
	static NSString *MultiframeTrueColorSecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7.4";
	/***/
	static NSString *XrayAngiographicImageStorage = @"1.2.840.10008.5.1.4.1.1.12.1";
	/***/
	static NSString *XrayRadioFlouroscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.12.2";
	/***/
	static NSString *XrayAngiographicBiplaneImageStorage = @"1.2.840.10008.5.1.4.1.1.12.3";
	/***/
	static NSString *NuclearMedicineImageStorage = @"1.2.840.10008.5.1.4.1.1.20";
	/***/
	static NSString *VisibleLightDraftImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1";
	/***/
	static NSString *VisibleLightMultiFrameDraftImageStorage = @"1.2.840.10008.5.1.4.1.1.77.2";
	/***/
	static NSString *VisibleLightEndoscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.1";
	/***/
	static NSString *VideoEndoscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.1.1";
	/***/
	static NSString *VisibleLightMicroscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.2";
	/***/
	static NSString *VideoMicroscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.2.1";
	/***/
	static NSString *VisibleLightSlideCoordinatesMicroscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.3";
	/***/
	static NSString *VisibleLightPhotographicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.4";
	/***/
	static NSString *VideoPhotographicImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.4.1";
	/***/
	static NSString *PETImageStorage = @"1.2.840.10008.5.1.4.1.1.128";
	/***/
	static NSString *RTImageStorage = @"1.2.840.10008.5.1.4.1.1.481.1";
	
		// Directory ...

	/***/
	static NSString *MediaStorageDirectoryStorage = @"1.2.840.10008.1.3.10";
	
	// Structured Report ...

	/***/
	static NSString *BasicTextSRStorage = @"1.2.840.10008.5.1.4.1.1.88.11";
	/***/
	static NSString *EnhancedSRStorage = @"1.2.840.10008.5.1.4.1.1.88.22";
	/***/
	static NSString *ComprehensiveSRStorage = @"1.2.840.10008.5.1.4.1.1.88.33";
	/***/
	static NSString *MammographyCADSRStorage = @"1.2.840.10008.5.1.4.1.1.88.50";
	/***/
	static NSString *KeyObjectSelectionDocumentStorage = @"1.2.840.10008.5.1.4.1.1.88.59";

	// Presentation State ...

	/***/
	static NSString *GrayscaleSoftcopyPresentationStateStorage = @"1.2.840.10008.5.1.4.1.1.11.1";
	
		// Waveforms ...

	/***/
	static NSString *TwelveLeadECGStorage = @"1.2.840.10008.5.1.4.1.1.9.1.1";
	/***/
	static NSString *GeneralECGStorage = @"1.2.840.10008.5.1.4.1.1.9.1.2";
	/***/
	static NSString *AmbulatoryECGStorage = @"1.2.840.10008.5.1.4.1.1.9.1.3";
	/***/
	static NSString *HemodynamicWaveformStorage = @"1.2.840.10008.5.1.4.1.1.9.2.1";
	/***/
	static NSString *CardiacElectrophysiologyWaveformStorage = @"1.2.840.10008.5.1.4.1.1.9.3.1";
	/***/
	static NSString *BasicVoiceStorage = @"1.2.840.10008.5.1.4.1.1.9.4.1";
	
		// Standalone ...

	/***/
	static NSString *StandaloneOverlayStorage = @"1.2.840.10008.5.1.4.1.1.8";
	/***/
	static NSString *StandaloneCurveStorage = @"1.2.840.10008.5.1.4.1.1.10";
	/***/
	static NSString *StandaloneModalityLUTStorage = @"1.2.840.10008.5.1.4.1.1.10";
	/***/
	static NSString *StandaloneVOILUTStorage = @"1.2.840.10008.5.1.4.1.1.11";
	/***/
	static NSString *StandalonePETCurveStorage = @"1.2.840.10008.5.1.4.1.1.129";
	
		// Radiotherapy ...

	/***/
	static NSString *RTDoseStorage = @"1.2.840.10008.5.1.4.1.1.481.2";
	/***/
	static NSString *RTStructureSetStorage = @"1.2.840.10008.5.1.4.1.1.481.3";
	/***/
	static NSString *RTBeamsTreatmentRecordStorage = @"1.2.840.10008.5.1.4.1.1.481.4";
	/***/
	static NSString *RTPlanStorage = @"1.2.840.10008.5.1.4.1.1.481.5";
	/***/
	static NSString *RTBrachyTreatmentRecordStorage = @"1.2.840.10008.5.1.4.1.1.481.6";
	/***/
	static NSString *RTTreatmentSummaryRecordStorage = @"1.2.840.10008.5.1.4.1.1.481.7";
	
		// Spectroscopy ...
	
	/***/
	static NSString *MRSpectroscopyStorage = @"1.2.840.10008.5.1.4.1.1.4.2";
	
	
		// Raw Data ...
	
	/***/
	static NSString *RawDataStorage = @"1.2.840.10008.5.1.4.1.1.66";
	
		// Query-Retrieve SOP Classes ...

	/***/
	static NSString *StudyRootQueryRetrieveInformationModelFind = @"1.2.840.10008.5.1.4.1.2.2.1";
	/***/
	static NSString *StudyRootQueryRetrieveInformationModelMove = @"1.2.840.10008.5.1.4.1.2.2.2";
	
	// PDF storage
	static NSString *PDFStorageClassUID = @"1.2.840.10008.5.1.4.1.1.104.1";
	
	
	//Printing
	static NSString *BasicGrayscalePrintManagementMetaSOPClassUID = @"1.2.840.10008.5.1.1.9";
	static NSString *BasicColorPrintManagementMetaSOPClassUID = @".2.840.10008.5.1.1.18";
	
	//some misc UIDs that I'm not using yet
	
	static NSString *StorageService = @"1.2.840.10008.4.2";
	static NSString *MediaCreationManagement = @"1.2.840.10008.5.1.4.1.1.2.1";
	static NSString *SpatialRegistrationStorage = @"1.2.840.10008.5.1.4.1.1.66.1";
	static NSString *SpatialFiducialsStorage = @"1.2.840.10008.5.1.4.1.1.66.2";
	static NSString *OphthalmicPhotography8BitImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.1";
	static NSString *OphthalmicPhotography16BitImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.2";
	static NSString *FujiPrivateCR = @"1.2.392.200036.9125.1.1.2";
	static NSString *StereometricRelationshipStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.3";
	static NSString *ProcedureLogStorage = @"1.2.840.10008.5.1.4.1.1.88.40";
	static NSString *InstanceAvailabilityNotification = @"1.2.840.10008.5.1.4.33";
	static NSString *GeneralRelevantPatientInformationQuerySOP = @"1.2.840.10008.5.1.4.37.1"; 
	static NSString *BreastImagingRelevantPatientInformationQuery = @"1.2.840.10008.5.1.4.37.2";
	static NSString	*CardiacRelevantPatientInformationQuery = @"1.2.840.10008.5.1.4.37.3";




	



@implementation DCMAbstractSyntaxUID

+ (NSString *)verificationClassUID{
	return DCM_Verification;
}

+ (NSString *)computedRadiographyImageStorage{
	return ComputedRadiographyImageStorage;
}

+ (NSString *)digitalXRayImageStorageForPresentation{
	return DigitalXRayImageStorageForPresentation;
}

+ (NSString *)digitalXRayImageStorageForProcessing{
	return DigitalXRayImageStorageForProcessing;
}

+ (NSString *)digitalMammographyXRayImageStorageForPresentation{
	return DigitalMammographyXRayImageStorageForPresentation;
}

+ (NSString *)digitalMammographyXRayImageStorageForProcessing{
	return DigitalMammographyXRayImageStorageForProcessing;
}

+ (NSString *)digitalIntraoralXRayImageStorageForPresentation{
	return DigitalIntraoralXRayImageStorageForPresentation;
}


+ (NSString *)digitalIntraoralXRayImageStorageForProcessing{
	return DigitalIntraoralXRayImageStorageForProcessing;
}

+ (NSString *)CTImageStorage{
	return CTImageStorage;
}

+ (NSString *)enhancedCTImageStorage{
	return EnhancedCTImageStorage;
}

+ (NSString *)enhancedPETImageStorage{
	return EnhancedPETImageStorage;
}

+ (NSString *)ultrasoundMultiframeImageStorageRetired{
	return UltrasoundMultiframeImageStorageRetired;
}

+ (NSString *)ultrasoundMultiframeImageStorage{
	return UltrasoundMultiframeImageStorage;
}

+ (NSString *)MRImageStorage{
	return MRImageStorage;
}


+ (NSString *)enhancedMRImageStorage{
	return EnhancedMRImageStorage;
}

+ (NSString *)nuclearMedicineImageStorageRetired{
	return NuclearMedicineImageStorageRetired;
}

+ (NSString *)ultrasoundImageStorageRetired{
	return UltrasoundImageStorageRetired;
}

+ (NSString *)ultrasoundImageStorage{
	return UltrasoundImageStorage;
}

+ (NSString *)secondaryCaptureImageStorage{
	return SecondaryCaptureImageStorage;
}

+ (NSString *)multiframeSingleBitSecondaryCaptureImageStorage{
	return MultiframeSingleBitSecondaryCaptureImageStorage;
}

+ (NSString *)multiframeGrayscaleByteSecondaryCaptureImageStorage{
	return MultiframeGrayscaleByteSecondaryCaptureImageStorage;
}

+ (NSString *)multiframeGrayscaleWordSecondaryCaptureImageStorage{
	return MultiframeGrayscaleWordSecondaryCaptureImageStorage;
}

+ (NSString *)multiframeTrueColorSecondaryCaptureImageStorage{
	return MultiframeTrueColorSecondaryCaptureImageStorage;
}

+ (NSString *)xrayAngiographicImageStorage{
	return XrayAngiographicImageStorage;
}

+ (NSString *)xrayRadioFlouroscopicImageStorage{
	return XrayRadioFlouroscopicImageStorage;
}

+ (NSString *)xrayAngiographicBiplaneImageStorage{
	return XrayAngiographicBiplaneImageStorage;
}

+ (NSString *)nuclearMedicineImageStorage{
	return NuclearMedicineImageStorage;
}

+ (NSString *)visibleLightDraftImageStorage{
	return VisibleLightDraftImageStorage;
}

+ (NSString *)visibleLightMultiFrameDraftImageStorage{
	return VisibleLightMultiFrameDraftImageStorage;
}

+ (NSString *)visibleLightEndoscopicImageStorage{
	return VisibleLightEndoscopicImageStorage;
}

+ (NSString *)videoEndoscopicImageStorage{
	return VideoEndoscopicImageStorage;
}

+ (NSString *)visibleLightMicroscopicImageStorage{
	return VisibleLightMicroscopicImageStorage;
}

+ (NSString *)videoMicroscopicImageStorage{
	return VideoMicroscopicImageStorage;
}

+ (NSString *)visibleLightSlideCoordinatesMicroscopicImageStorage{
	return VisibleLightSlideCoordinatesMicroscopicImageStorage;
}

+ (NSString *)visibleLightPhotographicImageStorage{
	return VisibleLightPhotographicImageStorage;
}

+ (NSString *)videoPhotographicImageStorage{
	return VideoPhotographicImageStorage;
}

+ (NSString *)PETImageStorage{
	return PETImageStorage;
}

+ (NSString *)RTImageStorage{
	return RTImageStorage;
}

+ (BOOL)isVerification:(NSString *)sopClassUID
{
		return sopClassUID != nil && (
		       [sopClassUID isEqualToString:DCM_Verification]
		);
	}

+ (BOOL)isImageStorage:(NSString *)sopClassUID
{
	if( sopClassUID)
	{
		for( NSString *sopUID in [DCMAbstractSyntaxUID imageSyntaxes])
		{
			if( [sopClassUID isEqualToString: sopUID]) return YES;
		}
	}
	
	return NO;
}

+ (NSArray *)imageSyntaxes{
		return [NSArray arrayWithObjects:ComputedRadiographyImageStorage ,
		    DigitalXRayImageStorageForPresentation ,
		    DigitalXRayImageStorageForProcessing ,
		    DigitalMammographyXRayImageStorageForPresentation ,
		    DigitalMammographyXRayImageStorageForProcessing ,
		    DigitalIntraoralXRayImageStorageForPresentation ,
		    DigitalIntraoralXRayImageStorageForProcessing ,
		    CTImageStorage ,
		    EnhancedCTImageStorage ,
			EnhancedPETImageStorage,
		    UltrasoundMultiframeImageStorageRetired ,
		    UltrasoundMultiframeImageStorage ,
		    MRImageStorage ,
		    EnhancedMRImageStorage ,
		    NuclearMedicineImageStorageRetired ,
		    UltrasoundImageStorageRetired ,
		    UltrasoundImageStorage ,
		    SecondaryCaptureImageStorage ,
		    MultiframeSingleBitSecondaryCaptureImageStorage ,
		    MultiframeGrayscaleByteSecondaryCaptureImageStorage ,
		    MultiframeGrayscaleWordSecondaryCaptureImageStorage ,
		    MultiframeTrueColorSecondaryCaptureImageStorage,
		    XrayAngiographicImageStorage ,
		    XrayRadioFlouroscopicImageStorage ,
		    XrayAngiographicBiplaneImageStorage ,
		    NuclearMedicineImageStorage ,
		    VisibleLightDraftImageStorage ,
			VideoEndoscopicImageStorage,
		    VisibleLightMultiFrameDraftImageStorage ,
		    VisibleLightEndoscopicImageStorage ,
		    VisibleLightMicroscopicImageStorage ,
		    VisibleLightSlideCoordinatesMicroscopicImageStorage ,
		    VisibleLightPhotographicImageStorage ,
		    PETImageStorage ,
		    RTImageStorage ,
			PDFStorageClassUID ,
			OphthalmicPhotography8BitImageStorage,
			OphthalmicPhotography16BitImageStorage,
			FujiPrivateCR,
			MRSpectroscopyStorage,
			RawDataStorage,
			nil];
	}



	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches the Media Storage Directory Storage SOP Class (used for the DICOMDIR)
	 */
	 
+ (NSString *)mediaStorageDirectoryStorage{
	return MediaStorageDirectoryStorage;
}

+ (BOOL) isDirectory:(NSString *) sopClassUID {
		return sopClassUID != nil && (
		       [sopClassUID isEqualToString:MediaStorageDirectoryStorage]
		);
	}
	
		// Structured Report ...


+ (NSString *)basicTextSRStorage{
	return BasicTextSRStorage;
}

+ (NSString *)enhancedSRStorage{
	return EnhancedSRStorage;
}

+ (NSString *)comprehensiveSRStorage{
	return ComprehensiveSRStorage;
}

+ (NSString *)mammographyCADSRStorage{
	return MammographyCADSRStorage;
}

+ (NSString *)keyObjectSelectionDocumentStorage{
	return KeyObjectSelectionDocumentStorage;
}

+ (BOOL) isKeyObjectDocument:(NSString *)sopClassUID  {
	return (sopClassUID != nil && [sopClassUID isEqualToString:KeyObjectSelectionDocumentStorage]);
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known standard generic or specific Structured Report Storage SOP Classes (not including Key Object)
	 */
+ (BOOL) isStructuredReport:(NSString *)sopClassUID
{
		if( sopClassUID != nil && (
		       [sopClassUID isEqualToString:BasicTextSRStorage]
		    || [sopClassUID isEqualToString:EnhancedSRStorage]
		    || [sopClassUID isEqualToString:ComprehensiveSRStorage]
		    || [sopClassUID isEqualToString:MammographyCADSRStorage]
		//    || [sopClassUID isEqualToString:KeyObjectSelectionDocumentStorage]
		))
		{
			return YES;
		}
		
	return NO;
}

	// Presentation State ...
+ (NSString *)grayscaleSoftcopyPresentationStateStorage{
	return GrayscaleSoftcopyPresentationStateStorage;
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known standard Presentation State Storage SOP Classes (currently just the Grayscale Softcopy Presentation State Storage SOP Class)
	 */
+ (BOOL) isPresentationState:(NSString *)sopClassUID {
		return sopClassUID != nil && (
		       [sopClassUID isEqualToString:GrayscaleSoftcopyPresentationStateStorage]
		);
}

		// Waveforms ...
+ (NSString *)twelveLeadECGStorage {
	return TwelveLeadECGStorage;
}

+ (NSString *)generalECGStorage{
	return GeneralECGStorage;
}

+ (NSString *)ambulatoryECGStorage{
	return AmbulatoryECGStorage;
}

+ (NSString *)hemodynamicWaveformStorage{
	return HemodynamicWaveformStorage;
}

+ (NSString *)cardiacElectrophysiologyWaveformStorage{
	return CardiacElectrophysiologyWaveformStorage;
}

+ (NSString *)basicVoiceStorage{
	return BasicVoiceStorage;
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known standard Waveform Storage SOP Classes
	 */
+ (BOOL) isWaveform:(NSString *)sopClassUID {
		return sopClassUID != nil && (
		       [sopClassUID isEqualToString:TwelveLeadECGStorage]
		    || [sopClassUID isEqualToString:GeneralECGStorage]
		    || [sopClassUID isEqualToString:AmbulatoryECGStorage]
		    || [sopClassUID isEqualToString:HemodynamicWaveformStorage]
		    || [sopClassUID isEqualToString:CardiacElectrophysiologyWaveformStorage]
		    || [sopClassUID isEqualToString:BasicVoiceStorage]
		);
}
	
		// Standalone ...
+ (NSString *)standaloneOverlayStorage{
	return StandaloneOverlayStorage;
}

+ (NSString *)standaloneCurveStorage{
	return StandaloneCurveStorage;
}

+ (NSString *)standaloneModalityLUTStorage{
	return StandaloneModalityLUTStorage;
}

+ (NSString *)standaloneVOILUTStorage{
	return StandaloneVOILUTStorage;
}

+ (NSString *)standalonePETCurveStorage{
	return StandalonePETCurveStorage;
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known standard Standalone Storage SOP Classes (overlay, curve (including PET curve), and LUTs)
	 */
+ (BOOL) isStandalone:(NSString *)sopClassUID {
		return sopClassUID != nil && (
		       [sopClassUID isEqualToString:StandaloneOverlayStorage]
		    || [sopClassUID isEqualToString:StandaloneCurveStorage]
		    || [sopClassUID isEqualToString:StandaloneModalityLUTStorage]
		    || [sopClassUID isEqualToString:StandaloneVOILUTStorage]
		    || [sopClassUID isEqualToString:StandalonePETCurveStorage]
		);
	}

// Radiotherapy ...
+ (NSString *)RTDoseStorage{
	return RTDoseStorage;
}

+ (NSString *)RTStructureSetStorage{
	return RTStructureSetStorage;
}

+ (NSString *)RTBeamsTreatmentRecordStorage{
	return RTBeamsTreatmentRecordStorage;
}

+ (NSString *)RTPlanStorage{
	return RTPlanStorage;
}

+ (NSString *)RTBrachyTreatmentRecordStorage{
	return RTBrachyTreatmentRecordStorage;
}

+ (NSString *)RTTreatmentSummaryRecordStorage{
	return RTTreatmentSummaryRecordStorage;
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known standard RT non-image Storage SOP Classes (dose, structure set, plan and treatment records)
	 */
+ (BOOL)isRadiotherapy: (NSString *)sopClassUID{
		return sopClassUID != nil && (
		       [sopClassUID  isEqualToString:RTDoseStorage]
		    || [sopClassUID  isEqualToString:RTStructureSetStorage]
		    || [sopClassUID  isEqualToString:RTBeamsTreatmentRecordStorage]
		    || [sopClassUID  isEqualToString:RTPlanStorage]
		    || [sopClassUID  isEqualToString:RTBrachyTreatmentRecordStorage]
		    || [sopClassUID  isEqualToString:RTTreatmentSummaryRecordStorage]
		);

}

// Spectroscopy ...
+ (NSString *)MRSpectroscopyStorage{
	return MRSpectroscopyStorage;
}


	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known standard Spectroscopy Storage SOP Classes (currently just the MR Spectroscopy Storage SOP Class)
	 */
+ (BOOL) isSpectroscopy:(NSString *)sopClassUID {
		return sopClassUID != nil && (
		       [sopClassUID  isEqualToString:MRSpectroscopyStorage]
		);
	}


// Raw Data ...
+ (NSString *)rawDataStorage{
	return RawDataStorage;
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches the Raw Data Storage SOP Class
	 */
+ (BOOL) isRawData:(NSString *)sopClassUID {
		return sopClassUID != nil && (
		       [sopClassUID  isEqualToString:RawDataStorage]
		);
}

	/**
	 * @param	sopClassUID	UID of the SOP Class, as a String without trailing zero padding
	 * @return			true if the UID argument matches one of the known non-image Storage SOP Classes (directory, SR, presentation state, waveform, standalone, RT, spectroscopy or raw data)
	 */
+ (BOOL) isNonImageStorage:(NSString *)sopClassUID {
		return [DCMAbstractSyntaxUID isDirectory:sopClassUID] 
		    || [DCMAbstractSyntaxUID isStructuredReport:sopClassUID] 
		    || [DCMAbstractSyntaxUID isPresentationState:sopClassUID]
		    || [DCMAbstractSyntaxUID isWaveform:sopClassUID]
		    || [DCMAbstractSyntaxUID isStandalone:sopClassUID]
		    || [DCMAbstractSyntaxUID isRadiotherapy:sopClassUID]
		    || [DCMAbstractSyntaxUID isSpectroscopy:sopClassUID]
		    || [DCMAbstractSyntaxUID isRawData:sopClassUID]
			|| [DCMAbstractSyntaxUID isPDF:sopClassUID]
		;
	}
	
+ (BOOL) isQuery:(NSString *)sopClassUID{
	return  ([sopClassUID isEqualToString:StudyRootQueryRetrieveInformationModelFind] ||
		[sopClassUID isEqualToString:StudyRootQueryRetrieveInformationModelMove]);
}
	


// Query-Retrieve SOP Classes ...
+ (NSString *)studyRootQueryRetrieveInformationModelFind{
	return StudyRootQueryRetrieveInformationModelFind;
}

+ (NSString *)studyRootQueryRetrieveInformationModelMove{
	return StudyRootQueryRetrieveInformationModelMove;
}

+ (NSString *)pdfStorageClassUID{
	return PDFStorageClassUID;
}
 
+ (BOOL)isPDF:(NSString *)sopClassUID{
	return [sopClassUID isEqualToString:PDFStorageClassUID];
}

- (id)initWithUID:(NSString *)uid  name:(NSString *)name  type:(NSString *)type{
	if (self = [super init]) {
		_uid = [uid retain];
		_name = [name retain];
		_type = [type retain];
	}
	return self;
}

- (void)dealloc{
	[_uid release];
	[_name release];
	[_type release];
	[super dealloc];
}
	
- (NSString *)uid{
	return _uid;
}
- (NSString *)name{
	return _name;
}
- (NSString *)type{
	return _type;
}
- (BOOL)isImageStorage{
	if (_type == @"ImageStorage")
		return YES;
	return NO;
}
- (BOOL) isDirectory{
if (_type == @"Directory")
		return YES;
	return NO;
}
- (BOOL) isStructuredReport{
	if (_type == @"StructuredReport")
		return YES;
	return NO;
}

- (BOOL) isPresentationState{
	if (_type == @"PresentationState")
		return YES;
	return NO;
}

- (BOOL) isWaveform{
	if (_type == @"Waveform")
		return YES;
	return NO;
}

- (BOOL) isStandalone{
	if (_type == @"Standalone")
		return YES;
	return NO;
}

- (BOOL)  isRadiotherapy{
	if (_type == @"Radiotherapy")
		return YES;
	return NO;
}

- (BOOL) isSpectroscopy{
	if (_type == @"Spectroscopy")
		return YES;
	return NO;
}

- (BOOL) isRawData{
	if (_type == @"RawData")
		return YES;
	return NO;
}

- (BOOL) isNonImageStorage{
	if (_type == @"ImageStorage")
		return NO;
	return YES;
}

	//Printing
+ (NSString *)basicGrayscalePrintManagementMetaSOPClassUID{
	return 	BasicGrayscalePrintManagementMetaSOPClassUID;
}

+ (NSString *)basicColorPrintManagementMetaSOPClassUID{
	return BasicColorPrintManagementMetaSOPClassUID;
}



- (NSString *)description{
	return [NSString stringWithFormat:@"Abstract Syntax:%@  name:%@  type:%@", _uid, _name, _type];
}



@end
