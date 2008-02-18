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

#import <Cocoa/Cocoa.h>


@interface DCMAbstractSyntaxUID : NSObject {
	NSString *_uid;
	NSString *_name;
	NSString *_type;
}

+ (NSString *)verificationClassUID;
+ (BOOL)isVerification:(NSString *)sopClassUID ;

+ (NSString *)computedRadiographyImageStorage;
+ (NSString *)digitalXRayImageStorageForPresentation;
+ (NSString *)digitalXRayImageStorageForProcessing;
+ (NSString *)digitalMammographyXRayImageStorageForPresentation;
+ (NSString *)digitalMammographyXRayImageStorageForProcessing;
+ (NSString *)digitalIntraoralXRayImageStorageForPresentation;
+ (NSString *)digitalIntraoralXRayImageStorageForProcessing;
+ (NSString *)CTImageStorage;
+ (NSString *)enhancedCTImageStorage;
+ (NSString *)ultrasoundMultiframeImageStorageRetired;
+ (NSString *)ultrasoundMultiframeImageStorage;
+ (NSString *)MRImageStorage;
+ (NSString *)enhancedMRImageStorage;
+ (NSString *)nuclearMedicineImageStorageRetired;
+ (NSString *)ultrasoundImageStorageRetired;
+ (NSString *)ultrasoundImageStorage;
+ (NSString *)secondaryCaptureImageStorage;
+ (NSString *)multiframeSingleBitSecondaryCaptureImageStorage;
+ (NSString *)multiframeGrayscaleByteSecondaryCaptureImageStorage;
+ (NSString *)multiframeGrayscaleWordSecondaryCaptureImageStorage;
+ (NSString *)multiframeTrueColorSecondaryCaptureImageStorage;
+ (NSString *)xrayAngiographicImageStorage;
+ (NSString *)xrayRadioFlouroscopicImageStorage;
+ (NSString *)xrayAngiographicBiplaneImageStorage;
+ (NSString *)nuclearMedicineImageStorage;
+ (NSString *)visibleLightDraftImageStorage;
+ (NSString *)visibleLightMultiFrameDraftImageStorage;
+ (NSString *)visibleLightEndoscopicImageStorage;
+ (NSString *)videoEndoscopicImageStorage;
+ (NSString *)visibleLightMicroscopicImageStorage;
+ (NSString *)videoMicroscopicImageStorage;
+ (NSString *)visibleLightSlideCoordinatesMicroscopicImageStorage;
+ (NSString *)visibleLightPhotographicImageStorage;
+ (NSString *)videoPhotographicImageStorage;
+ (NSString *)PETImageStorage;
+ (NSString *)RTImageStorage;
+ (BOOL)isImageStorage:(NSString *)sopClassUID;
+ (NSArray *)imageSyntaxes;

+ (NSString *)mediaStorageDirectoryStorage;
+ (BOOL) isDirectory:(NSString *) sopClassUID;

+ (NSString *)basicTextSRStorage;
+ (NSString *)enhancedSRStorage;
+ (NSString *)comprehensiveSRStorage;
+ (NSString *)mammographyCADSRStorage;
+ (NSString *)keyObjectSelectionDocumentStorage;
+ (BOOL) isKeyObjectDocument:(NSString *)sopClassUID;
+ (BOOL) isStructuredReport:(NSString *)sopClassUID;

+ (NSString *)grayscaleSoftcopyPresentationStateStorage;
+ (BOOL) isPresentationState:(NSString *)sopClassUID;

+ (NSString *)twelveLeadECGStorage;
+ (NSString *)generalECGStorage;
+ (NSString *)ambulatoryECGStorage;
+ (NSString *)hemodynamicWaveformStorage;
+ (NSString *)cardiacElectrophysiologyWaveformStorage;
+ (NSString *)basicVoiceStorage;
+ (BOOL) isWaveform:(NSString *)sopClassUID;

+ (NSString *)standaloneOverlayStorage;
+ (NSString *)standaloneCurveStorage;
+ (NSString *)standaloneModalityLUTStorage;
+ (NSString *)standaloneVOILUTStorage;
+ (NSString *)standalonePETCurveStorage;
+ (BOOL) isStandalone:(NSString *)sopClassUID;

+ (NSString *)RTDoseStorage;
+ (NSString *)RTStructureSetStorage;
+ (NSString *)RTBeamsTreatmentRecordStorage;
+ (NSString *)RTPlanStorage;
+ (NSString *)RTBrachyTreatmentRecordStorage;
+ (NSString *)RTTreatmentSummaryRecordStorage;
+ (BOOL)  isRadiotherapy:(NSString *)sopClassUID;

+ (NSString *)MRSpectroscopyStorage;
+ (BOOL) isSpectroscopy:(NSString *)sopClassUID;

+ (NSString *)rawDataStorage;
+ (BOOL) isRawData:(NSString *)sopClassUID ;

+ (BOOL) isNonImageStorage:(NSString *)sopClassUID;

+ (BOOL) isQuery:(NSString *)sopClassUID;

+ (NSString *)studyRootQueryRetrieveInformationModelFind;
+ (NSString *)studyRootQueryRetrieveInformationModelMove;

+ (NSString *)pdfStorageClassUID;

- (id)initWithUID:(NSString *)uid  name:(NSString *)name  type:(NSString *)type;
- (NSString *)uid;
- (NSString *)name;
- (NSString *)type;
- (BOOL)isImageStorage;
- (BOOL) isDirectory;
- (BOOL) isStructuredReport;
- (BOOL) isPresentationState;
- (BOOL) isWaveform;
- (BOOL) isStandalone;
- (BOOL)  isRadiotherapy;
- (BOOL) isSpectroscopy;
- (BOOL) isRawData;
- (BOOL) isNonImageStorage;
+ (BOOL)isPDF:(NSString *)sopClassUID;
+ (NSString *)basicGrayscalePrintManagementMetaSOPClassUID;
+ (NSString *)basicColorPrintManagementMetaSOPClassUID;













@end
