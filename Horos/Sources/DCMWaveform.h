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


#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

@class DCMWaveformSequence;

@interface DCMWaveform : NSObject {
    NSMutableArray* _sequences;
}

- (DCMWaveformSequence*)newSequence;
- (NSArray*)sequences;

@end
    
typedef enum {
    DCMWaveformOriginalityOriginal,
    DCMWaveformOriginalityDerived
} DCMWaveformOriginality;

@class DCMWaveformChannelDefinition;

typedef enum {
    DCMWaveformSampleInterpretationSB,
    DCMWaveformSampleInterpretationUB,
    DCMWaveformSampleInterpretationMB,
    DCMWaveformSampleInterpretationAB,
    DCMWaveformSampleInterpretationSS,
    DCMWaveformSampleInterpretationUS
} DCMWaveformSampleInterpretation;

@interface DCMWaveformSequence : NSObject {
    CGFloat _multiplexgroupTimeOffset;                              // (0018,1068) MultiplexgroupTimeOffset 1C DS [1]
    CGFloat _triggerTimeOffset;                                     // (0018,1069) TriggerTimeOffset 1C DS [1]
    unsigned int _triggerSamplePosition;                            // (0018,106E) TriggerSamplePosition 3 UL [1]
    DCMWaveformOriginality _waveformOriginality;                    // (003A,0004) WaveformOriginality 1 CS [1]
    unsigned short _numberOfWaveformChannels;                       // (003A,0005) NumberOfWaveformChannels 1 US [1]
    unsigned int _numberOfWaveformSamples;                          // (003A,0010) NumberOfWaveformSamples 1 UL [1]
    CGFloat _samplingFrequency;                                     // (003A,001A) SamplingFrequency 1 DS [1]
    NSString* _multiplexGroupLabel;                                 // (003A,0020) MultiplexGroupLabel 3 SH [1]
    NSMutableArray* _channelDefinitions;                            // (003A,0200) ChannelDefinitionSequence 1 SQ [1] (1+)
    unsigned short _waveformBitsAllocated;                          // (5400,1004) WaveformBitsAllocated 1 US [1]
    DCMWaveformSampleInterpretation _waveformSampleInterpretation;  // (5400,1006) WaveformSampleInterpretation 1 CS [1]
    NSData* _waveformPaddingValue;                                  // (5400,100A) WaveformPaddingValue 1C OB/OW [1]
    NSData* _waveformData;                                          // (5400,1010) WaveformData 1 OB/OW [1]
    // internals...
    NSMutableData* _buffer;
}

@property CGFloat multiplexgroupTimeOffset;
@property CGFloat triggerTimeOffset;
@property unsigned int triggerSamplePosition;
@property DCMWaveformOriginality waveformOriginality;
@property unsigned short numberOfWaveformChannels;
@property unsigned int numberOfWaveformSamples;
@property CGFloat samplingFrequency;
@property(retain) NSString* multiplexGroupLabel;
@property(retain,readonly) NSArray* channelDefinitions;
@property unsigned short waveformBitsAllocated;
@property DCMWaveformSampleInterpretation waveformSampleInterpretation;

- (void)setWaveformOriginalityCS:(char*)cs;
- (void)setWaveformSampleInterpretationCS:(char*)cs;
- (void)setWaveformPaddingValue:(void*)data length:(size_t)length;
- (void)setWaveformData:(void*)data length:(size_t)length;

- (DCMWaveformChannelDefinition*)newChannelDefinition;

- (CGFloat*)getValues:(NSUInteger*)numberOfValues;

@end
    
typedef enum {
    DCMWaveformChannelStatusOk,
    DCMWaveformChannelStatusTestData,
    DCMWaveformChannelStatusDisconnected,
    DCMWaveformChannelStatusQuestionable,
    DCMWaveformChannelStatusInvalid,
    DCMWaveformChannelStatusUncalibrated,
    DCMWaveformChannelStatusUnzeroed
} DCMWaveformChannelStatus;

@class DCMWaveformChannelSource;
@class DCMWaveformChannelSourceModifier;
@class DCMWaveformSourceWaveform;
@class DCMWaveformChannelSensitivityUnit;
    
@interface DCMWaveformChannelDefinition : NSObject {
    NSInteger _waveformChannelNumber;                           // (003A,0202) WaveformChannelNumber 3 IS [1]
    NSString* _channelLabel;                                    // (003A,0203) ChannelLabel 3 SH [1]
    DCMWaveformChannelStatus _channelStatus;                    // (003A,0205) ChannelStatus 3 CS [1-n]
    DCMWaveformChannelSource* _channelSource;                   // (003A,0208) ChannelSourceSequence 1 SQ [1] (1)
    NSMutableArray* _channelSourceModifiers;                    // (003A,0209) ChannelSourceModifiersSequence 1C SQ [1] (1+)
    NSMutableArray* _sourceWaveforms;                           // (003A,020A) SourceWaveformSequence 3 SQ [1] (1+)
    NSString* _channelDerivationDescription;                    // (003A,020C) ChannelDerivationDescription 3 LO [1]
    CGFloat _channelSensitivity;                                // (003A,0210) ChannelSensitivity 1C DS [1]
    DCMWaveformChannelSensitivityUnit* _channelSensitivityUnit; // (003A,0211) ChannelSensitivityUnitsSequence 1C SQ [1] (1)
    CGFloat _channelSensitivityCorrectionFactor;                // (003A,0212) ChannelSensitivityCorrectionFactor 1C DS [1]
    CGFloat _channelBaseline;                                   // (003A,0213) ChannelBaseline 1C DS [1]
    CGFloat _channelTimeSkew;                                   // (003A,0214) ChannelTimeSkew 1C DS [1]
    CGFloat _channelSampleSkew;                                 // (003A,0215) ChannelSampleSkew 1C DS [1]
    CGFloat _channelOffset;                                     // (003A,0218) ChannelOffset 3 DS [1]
    unsigned short _waveformBitsStored;                         // (003A,021A) WaveformBitsStored 1 US [1]
    CGFloat _filterLowFrequency;                                // (003A,0220) FilterLowFrequency 3 DS [1]
    CGFloat _filterHighFrequency;                               // (003A,0221) FilterHighFrequency 3 DS [1]
    CGFloat _notchFilterFrequency;                              // (003A,0222) NotchFilterFrequency 3 DS [1]
    CGFloat _notchFilterBandwidth;                              // (003A,0223) NotchFilterBandwidth 3 DS [1]
    NSData* _channelMinimumValue;                               // (5400,0110) ChannelMinimumValue 3 OB/OW [1]
    NSData* _channelMaximumValue;                               // (5400,0112) ChannelMaximumValue 3 OB/OW [1]
    // internals...
    CGFloat _min, _max;
}

@property NSInteger waveformChannelNumber;
@property(retain) NSString* channelLabel;
@property DCMWaveformChannelStatus channelStatus;
@property(retain,readonly) DCMWaveformChannelSource* channelSource;
@property(retain,readonly) NSArray* channelSourceModifiers;
@property(retain,readonly) NSArray* sourceWaveforms;
@property(retain) NSString* channelDerivationDescription;
@property CGFloat channelSensitivity;
@property(retain,readonly) DCMWaveformChannelSensitivityUnit* channelSensitivityUnit;
@property CGFloat channelSensitivityCorrectionFactor;
@property CGFloat channelBaseline;
@property CGFloat channelTimeSkew;
@property CGFloat channelSampleSkew;
@property CGFloat channelOffset;
@property unsigned short waveformBitsStored;
@property CGFloat filterLowFrequency;
@property CGFloat filterHighFrequency;
@property CGFloat notchFilterFrequency;
@property CGFloat notchFilterBandwidth;

- (void)setChannelStatusCS:(char*)cs;
- (void)setChannelMinimumValue:(void*)data length:(size_t)length;
- (void)setChannelMaximumValue:(void*)data length:(size_t)length;

- (DCMWaveformChannelSource*)newChannelSource; // 1
- (DCMWaveformChannelSourceModifier*)newChannelSourceModifier;
- (DCMWaveformSourceWaveform*)newSourceWaveform;
- (DCMWaveformChannelSensitivityUnit*)newChannelSensitivityUnit; // 1

- (void)getValuesMin:(CGFloat*)min max:(CGFloat*)max;
- (void)setValuesMin:(CGFloat)min max:(CGFloat)max;

@end

typedef enum {
    DCMMappingResourceDCMR, // DICOM Content Mapping Resource
    DCMMappingResourceSDM // SNOMED DICOM Microglossary (Retired)
} DCMMappingResource;
    
typedef enum {
    DCMContextGroupExtensionFlagY,
    DCMContextGroupExtensionFlagN
} DCMContextGroupExtensionFlag;
    
@interface DCMCodeSequenceMacro : NSObject {
    NSString* _codeValue; // (0008,0100) CodeValue 1 SH [1]
    NSString* _codingSchemeDesignator; // (0008,0102) CodingSchemeDesignator 1 SH [1]
    NSString* _codingSchemeVersion; // (0008,0103) CodingSchemeVersion 1C SH [1]
    NSString* _codeMeaning; // (0008,0104) CodeMeaning 1  LO [1]
    NSString* _contextIdentifier; // (0008,010F) ContextIdentifier 3 CS [1] // TODO: maybe this should be an enum...
    NSString* _contextUID; // (0008,0117) ContextUID 3 UI [1]
    DCMMappingResource _mappingResource; // (0008,0105) MappingResource 1C CS [1]
    NSDate* _contextGroupVersion; // (0008,0106) ContextGroupVersion 1C DT [1]
    DCMContextGroupExtensionFlag _contextGroupExtensionFlag; // (0008,010B) ContextGroupExtensionFlag 3 CS [1]
    NSDate* _contextGroupLocalVersion; // (0008,0107) ContextGroupLocalVersion 1C DT [1]
    NSString* _contextGroupExtensionCreatorUID; // (0008,010D) ContextGroupExtensionCreatorUID 1C UI [1]
}

@property(retain) NSString* codeValue;
@property(retain) NSString* codingSchemeDesignator;
@property(retain) NSString* codingSchemeVersion;
@property(retain) NSString* codeMeaning;
@property(retain) NSString* contextIdentifier;
@property(retain) NSString* contextUID;
@property DCMMappingResource mappingResource;
@property(retain) NSDate* contextGroupVersion;
@property DCMContextGroupExtensionFlag contextGroupExtensionFlag;
@property(retain) NSDate* contextGroupLocalVersion;
@property(retain) NSString* contextGroupExtensionCreatorUID;

- (void)setMappingResourceCS:(char*)cs;
- (void)setContextGroupExtensionFlagCS:(char*)cs;

@end
    
@interface DCMSOPInstanceReferenceMacro : NSObject {
    NSString* _referencedSOPClassUID; // (0008,1150) ReferencedSOPClassUID 1 UI [1]
    NSString* _referencedSOPInstanceUID; // (0008,1155) ReferencedSOPInstanceUID 1 UI [1]
}

@property(retain) NSString* referencedSOPClassUID;
@property(retain) NSString* referencedSOPInstanceUID;

@end

@interface DCMWaveformChannelSource : DCMCodeSequenceMacro {
    
}

@end
    
@interface DCMWaveformChannelSourceModifier : DCMCodeSequenceMacro {
    
}

@end

@interface DCMWaveformSourceWaveform : DCMSOPInstanceReferenceMacro {
    unsigned short _referencedWaveformChannels; // (0040,A0B0) ReferencedWaveformChannels 1 US [2-2n]
}

@property unsigned short referencedWaveformChannels;

@end
    
@interface DCMWaveformChannelSensitivityUnit : DCMCodeSequenceMacro {
    
}

@end
    
#ifdef __cplusplus
}
#endif

























