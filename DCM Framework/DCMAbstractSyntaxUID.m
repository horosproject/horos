/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMAbstractSyntaxUID.h"

static NSArray *imagesSyntaxes = nil;
static NSArray *hiddenImagesSyntaxes = nil;
static NSMutableArray *allSupportedSyntaxes = nil;

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
    static NSString *EnhancedUSVolumeStorage = @"1.2.840.10008.5.1.4.1.1.6.2";
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
	static NSString *EnhancedXAImageStorage = @"1.2.840.10008.5.1.4.1.1.12.1.1";
	/***/
	static NSString *XrayRadioFlouroscopicImageStorage = @"1.2.840.10008.5.1.4.1.1.12.2";
	static NSString *EnhancedXRFImageStorage = @"1.2.840.10008.5.1.4.1.1.12.2.1";
	/***/
	static NSString *XRay3DAngiographicImageStorage = @"1.2.840.10008.5.1.4.1.1.13.1.1";
	static NSString *XRay3DCraniofacialImageStorage = @"1.2.840.10008.5.1.4.1.1.13.1.2";
    static NSString *BreastTomosynthesisImageStorage = @"1.2.840.10008.5.1.4.1.1.13.1.3";
    /***/
	static NSString *GE3DModelStorage = @"1.2.840.113619.4.26";
	static NSString *GECollageStorage = @"1.2.528.1.1001.5.1.1.1";
	static NSString *GEeNTEGRAProtocolOrNMGenieStorage = @"1.2.840.113619.4.27";
	static NSString *GEPETRawDataStorage = @"1.2.840.113619.4.30";
    /***/
    static NSString *Philips3DObject2Storage = @"1.3.46.670589.5.0.2.1";
    static NSString *Philips3DObjectStorage = @"1.3.46.670589.5.0.2";
    static NSString *Philips3DPresentationStateStorage = @"1.3.46.670589.2.5.1.1";
    static NSString *PhilipsCompositeObjectStorage = @"1.3.46.670589.5.0.4";
    static NSString *PhilipsCTSyntheticImageStorage = @"1.3.46.670589.5.0.9";
    static NSString *PhilipsCXImageStorage = @"1.3.46.670589.2.4.1.1";
    static NSString *PhilipsCXSyntheticImageStorage = @"1.3.46.670589.5.0.12";
    static NSString *PhilipsLiveRunStorage = @"1.3.46.670589.7.8.1618510092";
    static NSString *PhilipsMRCardio2Storage = @"1.3.46.670589.5.0.8.1";
    static NSString *PhilipsMRCardioAnalysis2Storage = @"1.3.46.670589.5.0.11.1";
    static NSString *PhilipsMRCardioAnalysisStorage = @"1.3.46.670589.5.0.11";
    static NSString *PhilipsMRCardioProfileStorage = @"1.3.46.670589.5.0.7";
    static NSString *PhilipsMRCardioStorage = @"1.3.46.670589.5.0.8";
    static NSString *PhilipsMRColorImageStorage = @"1.3.46.670589.11.0.0.12.3";
    static NSString *PhilipsMRExamcardStorage = @"1.3.46.670589.11.0.0.12.4";
    static NSString *PhilipsMRSeriesDataStorage = @"1.3.46.670589.11.0.0.12.2";
    static NSString *PhilipsMRSpectrumStorage = @"1.3.46.670589.11.0.0.12.1";
    static NSString *PhilipsMRSyntheticImageStorage = @"1.3.46.670589.5.0.10";
    static NSString *PhilipsPerfusionImageStorage = @"1.3.46.670589.5.0.14";
    static NSString *PhilipsPerfusionStorage = @"1.3.46.670589.5.0.13";
    static NSString *PhilipsPrivateXRayMFStorage = @"1.3.46.670589.7.8.1618510091";
    static NSString *PhilipsReconstructionStorage = @"1.3.46.670589.7.8.16185100130";
    static NSString *PhilipsRunStorage = @"1.3.46.670589.7.8.16185100129";
    static NSString *PhilipsSpecialisedXAStorage = @"1.3.46.670589.2.3.1.1";
    static NSString *PhilipsSurface2Storage = @"1.3.46.670589.5.0.3.1";
    static NSString *PhilipsSurfaceStorage = @"1.3.46.670589.5.0.3";
    static NSString *PhilipsVolume2Storage = @"1.3.46.670589.5.0.1.1";
    static NSString *PhilipsVolumeSetStorage = @"1.3.46.670589.2.11.1.1";
    static NSString *PhilipsVolumeStorage = @"1.3.46.670589.5.0.1";
    static NSString *PhilipsVRMLStorage = @"1.3.46.670589.2.8.1.1";    
	static NSString *PhilipsPrivatePrefixStorage = @"1.3.46.670589"; // Prefix

    static NSString *SiemensCSAPrivateNonImageStorage = @"1.3.12.2.1107.5.9.1";
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
	static NSString *ProcedureLogStorage = @"1.2.840.10008.5.1.4.1.1.88.40";
	static NSString *MammographyCADSRStorage = @"1.2.840.10008.5.1.4.1.1.88.50";
	static NSString *ChestCADSR = @"1.2.840.10008.5.1.4.1.1.88.65";
	static NSString *XRayRadiationDoseSR = @"1.2.840.10008.5.1.4.1.1.88.67";
	/***/
	static NSString *KeyObjectSelectionDocumentStorage = @"1.2.840.10008.5.1.4.1.1.88.59";

	// Presentation State ...

	/***/
	static NSString *GrayscaleSoftcopyPresentationStateStorage = @"1.2.840.10008.5.1.4.1.1.11.1";
	static NSString *ColorSoftcopyPresentationStateStorage = @"1.2.840.10008.5.1.4.1.1.11.2";
	static NSString *PseudoColorSoftcopyPresentationStateStorage = @"1.2.840.10008.5.1.4.1.1.11.3";
	static NSString *BlendingSoftcopyPresentationStateStorage = @"1.2.840.10008.5.1.4.1.1.11.4";
	
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
	static NSString *EncapsulatedCDAStorage = @"1.2.840.10008.5.1.4.1.1.104.2";
	
	//Printing
	static NSString *BasicGrayscalePrintManagementMetaSOPClassUID = @"1.2.840.10008.5.1.1.9";
	static NSString *BasicColorPrintManagementMetaSOPClassUID = @".2.840.10008.5.1.1.18";
	
	//some misc UIDs that I'm not using yet
	
	static NSString *StorageService = @"1.2.840.10008.4.2";
//	static NSString *MediaCreationManagement = @"1.2.840.10008.5.1.4.1.1.2.1";
	static NSString *SpatialRegistrationStorage = @"1.2.840.10008.5.1.4.1.1.66.1";
	static NSString *SpatialFiducialsStorage = @"1.2.840.10008.5.1.4.1.1.66.2";
	static NSString *OphthalmicPhotography8BitImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.1";
	static NSString *OphthalmicPhotography16BitImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.2";
	static NSString *FujiPrivateCR = @"1.2.392.200036.9125.1.1.2";
	static NSString *StereometricRelationshipStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.3";
	static NSString *OphthalmicTomographyImageStorage = @"1.2.840.10008.5.1.4.1.1.77.1.5.4";
	static NSString *InstanceAvailabilityNotification = @"1.2.840.10008.5.1.4.33";
	static NSString *GeneralRelevantPatientInformationQuerySOP = @"1.2.840.10008.5.1.4.37.1"; 
	static NSString *BreastImagingRelevantPatientInformationQuery = @"1.2.840.10008.5.1.4.37.2";
	static NSString	*CardiacRelevantPatientInformationQuery = @"1.2.840.10008.5.1.4.37.3";

@implementation DCMAbstractSyntaxUID

+ (NSArray*) allSupportedSyntaxes
{
    if( allSupportedSyntaxes == nil)
    {
        allSupportedSyntaxes = [NSMutableArray array];
        
        [allSupportedSyntaxes addObjectsFromArray: [DCMAbstractSyntaxUID imageSyntaxes]];
        [allSupportedSyntaxes addObjectsFromArray: [DCMAbstractSyntaxUID radiotherapySyntaxes]];
        [allSupportedSyntaxes addObjectsFromArray: [DCMAbstractSyntaxUID structuredReportSyntaxes]];
        [allSupportedSyntaxes addObject: KeyObjectSelectionDocumentStorage];
        [allSupportedSyntaxes addObjectsFromArray: [DCMAbstractSyntaxUID presentationStateSyntaxes]];
        [allSupportedSyntaxes addObjectsFromArray: [DCMAbstractSyntaxUID supportedPrivateClasses]];
        [allSupportedSyntaxes addObjectsFromArray: [DCMAbstractSyntaxUID waveformSyntaxes]];
        [allSupportedSyntaxes addObjectsFromArray: hiddenImagesSyntaxes];
        
        [allSupportedSyntaxes retain]; 
    }
    
    return  allSupportedSyntaxes;
}

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

+ (NSString *)EnhancedXAImageStorage{
	return EnhancedXAImageStorage;
}

+ (NSString *)XrayAngiographicImageStorage{
	return XrayAngiographicImageStorage;
}

+ (NSString *)XrayRadioFlouroscopicImageStorage{
	return XrayRadioFlouroscopicImageStorage;
}

+ (NSString *)EnhancedXRFImageStorage{
	return EnhancedXRFImageStorage;
}

+ (NSString *)XrayAngiographicBiplaneImageStorage{
	return XrayAngiographicBiplaneImageStorage;
}

+ (NSString *)XRay3DAngiographicImageStorage{
	return XRay3DAngiographicImageStorage;
}

+ (NSString *)XRay3DCraniofacialImageStorage{
	return XRay3DCraniofacialImageStorage;
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

+ (NSString *)enhancedUSVolumeStorage{
	return EnhancedUSVolumeStorage;
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

/*
 these are also multiframe, says DCMTK 
 compare(mediaSOPClassUID, UID_XRayFluoroscopyImageStorage) ||
 compare(mediaSOPClassUID, UID_NuclearMedicineImageStorage) ||
 compare(mediaSOPClassUID, UID_RTImageStorage) ||
 compare(mediaSOPClassUID, UID_RTDoseStorage) ||
 compare(mediaSOPClassUID, UID_VideoEndoscopicImageStorage) ||
 compare(mediaSOPClassUID, UID_VideoMicroscopicImageStorage) ||
 compare(mediaSOPClassUID, UID_VideoPhotographicImageStorage) ||
 compare(mediaSOPClassUID, UID_OphthalmicPhotography8BitImageStorage) ||
 compare(mediaSOPClassUID, UID_OphthalmicPhotography16BitImageStorage);
*/
+(BOOL)isMultiframe:(NSString*)sopClassUID {
    return [sopClassUID isEqualToString:[DCMAbstractSyntaxUID enhancedMRImageStorage]]
        || [sopClassUID isEqualToString:UltrasoundMultiframeImageStorage]
        || [sopClassUID isEqualToString:EnhancedCTImageStorage]
        || [sopClassUID isEqualToString:MultiframeSingleBitSecondaryCaptureImageStorage]
        || [sopClassUID isEqualToString:MultiframeGrayscaleByteSecondaryCaptureImageStorage]
        || [sopClassUID isEqualToString:MultiframeGrayscaleWordSecondaryCaptureImageStorage]
        || [sopClassUID isEqualToString:MultiframeTrueColorSecondaryCaptureImageStorage]
        || [sopClassUID isEqualToString:EnhancedXAImageStorage]
        || [sopClassUID isEqualToString:XrayAngiographicImageStorage]
        || [sopClassUID isEqualToString:XrayRadioFlouroscopicImageStorage]
        || [sopClassUID isEqualToString:EnhancedXRFImageStorage]
        || [sopClassUID isEqualToString:XrayAngiographicBiplaneImageStorage]
        || [sopClassUID isEqualToString:XRay3DAngiographicImageStorage]
        || [sopClassUID isEqualToString:XRay3DCraniofacialImageStorage]
        || [sopClassUID isEqualToString:EnhancedPETImageStorage]
        || [sopClassUID isEqualToString:BreastTomosynthesisImageStorage]
        || [sopClassUID isEqualToString:UltrasoundMultiframeImageStorageRetired];
}

+ (BOOL)isImageStorage:(NSString *)sopClassUID
{
	if( sopClassUID)
	{
		for( NSString *sopUID in [DCMAbstractSyntaxUID imageSyntaxes])
		{
			if( [sopClassUID isEqualToString: sopUID])
                return YES;
		}
	}
	
	return NO;
}

+ (BOOL) isHiddenImageStorage:(NSString *)sopClassUID
{
    if( sopClassUID)
	{
		for( NSString *sopUID in [DCMAbstractSyntaxUID hiddenImageSyntaxes])
		{
			if( [sopClassUID isEqualToString: sopUID]) return YES;
		}
	}
	
	return NO;
}

+ (NSArray *)hiddenImageSyntaxes
{
    return hiddenImagesSyntaxes;
}

+ (NSArray *)imageSyntaxes
{
	if( imagesSyntaxes == nil)
	{
		imagesSyntaxes = [NSArray arrayWithObjects:
            ComputedRadiographyImageStorage ,
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
            EnhancedUSVolumeStorage,
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
            EncapsulatedCDAStorage,
			OphthalmicPhotography8BitImageStorage,
			OphthalmicPhotography16BitImageStorage,
			OphthalmicTomographyImageStorage,
			FujiPrivateCR,
			EnhancedXAImageStorage,
			EnhancedXRFImageStorage,
			XRay3DAngiographicImageStorage,
			XRay3DCraniofacialImageStorage,
            PhilipsPrivateXRayMFStorage,
            PhilipsCTSyntheticImageStorage,
            PhilipsCXImageStorage,
            PhilipsCXSyntheticImageStorage,
            PhilipsMRColorImageStorage,
            PhilipsMRSyntheticImageStorage,
            PhilipsPerfusionImageStorage,
            BreastTomosynthesisImageStorage,
			nil];
		
		@try 
		{
			if( [[NSUserDefaults standardUserDefaults] arrayForKey: @"additionalDisplayedStorageSOPClassUIDArray"])
				imagesSyntaxes = [imagesSyntaxes arrayByAddingObjectsFromArray: [[NSUserDefaults standardUserDefaults] arrayForKey: @"additionalDisplayedStorageSOPClassUIDArray"]];
		}
		@catch (NSException * e) 
		{
            NSLog(@"Exception in %s: %@", __PRETTY_FUNCTION__, e.reason);
		}
        
        @try 
		{
			if( [[NSUserDefaults standardUserDefaults] arrayForKey: @"hiddenDisplayedStorageSOPClassUIDArray"])
            {
                [hiddenImagesSyntaxes release];
                hiddenImagesSyntaxes = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"hiddenDisplayedStorageSOPClassUIDArray"] retain];
                
                NSMutableArray *mutableArray = [NSMutableArray arrayWithArray: imagesSyntaxes];
                
				[mutableArray removeObjectsInArray: hiddenImagesSyntaxes];
                
                imagesSyntaxes = mutableArray;
            }
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		[imagesSyntaxes retain];
	}
	
	return imagesSyntaxes;
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

+ (BOOL) isKeyObjectDocument:(NSString *)sopClassUID 
{
	return (sopClassUID != nil && [sopClassUID isEqualToString: KeyObjectSelectionDocumentStorage]);
}

+ (NSArray*) structuredReportSyntaxes
{
    return [NSArray arrayWithObjects: BasicTextSRStorage, EnhancedSRStorage, ComprehensiveSRStorage, MammographyCADSRStorage, ProcedureLogStorage, ChestCADSR, XRayRadiationDoseSR, nil];
}

+ (BOOL) isStructuredReport:(NSString *)sopClassUID
{
		if( sopClassUID != nil && [[DCMAbstractSyntaxUID structuredReportSyntaxes] containsObject: sopClassUID])
			return YES;
		
	return NO;
}

	// Presentation State ...
+ (NSString *)grayscaleSoftcopyPresentationStateStorage{
	return GrayscaleSoftcopyPresentationStateStorage;
}

+(NSArray*) presentationStateSyntaxes
{
    return [NSArray arrayWithObjects: GrayscaleSoftcopyPresentationStateStorage, ColorSoftcopyPresentationStateStorage, PseudoColorSoftcopyPresentationStateStorage, BlendingSoftcopyPresentationStateStorage, nil];
}

+ (BOOL) isPresentationState:(NSString *)sopClassUID {
		return sopClassUID != nil && [[DCMAbstractSyntaxUID presentationStateSyntaxes] containsObject: sopClassUID];
}

+ (NSArray*) supportedPrivateClasses
{
    return [NSArray arrayWithObjects:
            MRSpectroscopyStorage,
            RawDataStorage,
            PhilipsPrivatePrefixStorage,
            SiemensCSAPrivateNonImageStorage,
            GE3DModelStorage,
            GECollageStorage,
            GEeNTEGRAProtocolOrNMGenieStorage,
            GEPETRawDataStorage,
            nil];
}

+ (BOOL) isSupportedPrivateClasses:(NSString *)sopClassUID
{
    if( sopClassUID != nil)
    {
        for( NSString *s in [DCMAbstractSyntaxUID supportedPrivateClasses])
        {
            if( [sopClassUID hasPrefix: s])
                return YES;
        }
    }
	return NO; 
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

+ (NSArray*) waveformSyntaxes
{
    return [NSArray arrayWithObjects: TwelveLeadECGStorage, GeneralECGStorage, AmbulatoryECGStorage, HemodynamicWaveformStorage,CardiacElectrophysiologyWaveformStorage, BasicVoiceStorage, nil];
}

+ (BOOL) isWaveform:(NSString *)sopClassUID {
		return sopClassUID != nil && [[DCMAbstractSyntaxUID waveformSyntaxes] containsObject: sopClassUID];
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

+(NSArray*) radiotherapySyntaxes
{
    return [NSArray arrayWithObjects: RTDoseStorage, RTStructureSetStorage, RTBeamsTreatmentRecordStorage, RTPlanStorage, RTBrachyTreatmentRecordStorage, RTTreatmentSummaryRecordStorage, nil];
}

+ (BOOL)isRadiotherapy: (NSString *)sopClassUID
{
		return sopClassUID != nil && [[DCMAbstractSyntaxUID radiotherapySyntaxes] containsObject: sopClassUID];
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
            || [DCMAbstractSyntaxUID isHiddenImageStorage:sopClassUID]
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

+ (NSString *)EncapsulatedCDAStorage{
	return EncapsulatedCDAStorage;
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
	if ([_type isEqualToString: @"ImageStorage"])
		return YES;
	return NO;
}
- (BOOL) isDirectory{
if ([_type isEqualToString: @"Directory"])
		return YES;
	return NO;
}
- (BOOL) isStructuredReport{
	if ([_type isEqualToString: @"StructuredReport"])
		return YES;
	return NO;
}

- (BOOL) isPresentationState{
	if ([_type isEqualToString: @"PresentationState"])
		return YES;
	return NO;
}

- (BOOL) isWaveform{
	if ([_type isEqualToString: @"Waveform"])
		return YES;
	return NO;
}

- (BOOL) isStandalone{
	if ([_type isEqualToString: @"Standalone"])
		return YES;
	return NO;
}

- (BOOL)  isRadiotherapy{
	if ([_type isEqualToString: @"Radiotherapy"])
		return YES;
	return NO;
}

- (BOOL) isSpectroscopy{
	if ([_type isEqualToString: @"Spectroscopy"])
		return YES;
	return NO;
}

- (BOOL) isRawData{
	if ([_type isEqualToString: @"RawData"])
		return YES;
	return NO;
}

- (BOOL) isNonImageStorage{
	if ([_type isEqualToString: @"ImageStorage"])
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
