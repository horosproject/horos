/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


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
+ (NSArray*) allSupportedSyntaxes;

+ (NSString *)verificationClassUID;
+ (BOOL)isVerification:(NSString *)sopClassUID ;
+ (BOOL)isMultiframe:(NSString*)sopClassUID;

+ (NSString *)computedRadiographyImageStorage;
+ (NSString *)digitalXRayImageStorageForPresentation;
+ (NSString *)digitalXRayImageStorageForProcessing;
+ (NSString *)digitalMammographyXRayImageStorageForPresentation;
+ (NSString *)digitalMammographyXRayImageStorageForProcessing;
+ (NSString *)digitalIntraoralXRayImageStorageForPresentation;
+ (NSString *)digitalIntraoralXRayImageStorageForProcessing;
+ (NSString *)CTImageStorage;
+ (NSString *)enhancedCTImageStorage;
+ (NSString *)enhancedPETImageStorage;
+ (NSString *)ultrasoundMultiframeImageStorageRetired;
+ (NSString *)ultrasoundMultiframeImageStorage;
+ (NSString *)MRImageStorage;
+ (NSString *)enhancedMRImageStorage;
+ (NSString *)nuclearMedicineImageStorageRetired;
+ (NSString *)ultrasoundImageStorageRetired;
+ (NSString *)ultrasoundImageStorage;
+ (NSString *)enhancedUSVolumeStorage;
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
+ (NSString *)EnhancedXAImageStorage;
+ (NSString *)XrayAngiographicImageStorage;
+ (NSString *)XrayRadioFlouroscopicImageStorage;
+ (NSString *)EnhancedXRFImageStorage;
+ (NSString *)XrayAngiographicBiplaneImageStorage;
+ (NSString *)XRay3DAngiographicImageStorage;
+ (NSString *)XRay3DCraniofacialImageStorage;
+ (NSString *)PETImageStorage;
+ (NSString *)RTImageStorage;
+ (BOOL)isImageStorage:(NSString *)sopClassUID;
+ (NSArray *)imageSyntaxes;
+ (NSArray *)hiddenImageSyntaxes;
+ (BOOL) isHiddenImageStorage:(NSString *)sopClassUID;
+ (BOOL) isSupportedPrivateClasses:(NSString *)sopClassUID;
+ (NSArray*) supportedPrivateClasses;
+ (NSString *)mediaStorageDirectoryStorage;
+ (BOOL) isDirectory:(NSString *) sopClassUID;

+ (NSString *)basicTextSRStorage;
+ (NSString *)enhancedSRStorage;
+ (NSString *)comprehensiveSRStorage;
+ (NSString *)mammographyCADSRStorage;
+ (NSString *)keyObjectSelectionDocumentStorage;
+ (BOOL) isKeyObjectDocument:(NSString *)sopClassUID;
+ (BOOL) isStructuredReport:(NSString *)sopClassUID;
+ (NSArray*) structuredReportSyntaxes;

+ (NSString *)grayscaleSoftcopyPresentationStateStorage;
+(NSArray*) presentationStateSyntaxes;
+ (BOOL) isPresentationState:(NSString *)sopClassUID;

+ (NSString *)twelveLeadECGStorage;
+ (NSString *)generalECGStorage;
+ (NSString *)ambulatoryECGStorage;
+ (NSString *)hemodynamicWaveformStorage;
+ (NSString *)cardiacElectrophysiologyWaveformStorage;
+ (NSString *)basicVoiceStorage;
+ (NSArray*) waveformSyntaxes;
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
+(NSArray*) radiotherapySyntaxes;

+ (NSString *)MRSpectroscopyStorage;
+ (BOOL) isSpectroscopy:(NSString *)sopClassUID;

+ (NSString *)rawDataStorage;
+ (BOOL) isRawData:(NSString *)sopClassUID ;

+ (BOOL) isNonImageStorage:(NSString *)sopClassUID;

+ (BOOL) isQuery:(NSString *)sopClassUID;

+ (NSString *)studyRootQueryRetrieveInformationModelFind;
+ (NSString *)studyRootQueryRetrieveInformationModelMove;

+ (NSString *)pdfStorageClassUID;
+ (NSString *)EncapsulatedCDAStorage;

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
