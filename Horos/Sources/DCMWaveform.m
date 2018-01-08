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

#import "DCMWaveform.h"

@implementation DCMWaveform

- (id)init {
    if ((self = [super init])) {
        _sequences = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_sequences release];
    [super dealloc];
}

- (DCMWaveformSequence*)newSequence {
    DCMWaveformSequence* s = [[[DCMWaveformSequence alloc] init] autorelease];
    [_sequences addObject:s];
    return s;
}

- (NSArray*)sequences {
    return _sequences;
}


@end

@interface DCMWaveformSequence ()

@property(retain,readwrite) NSArray* channelDefinitions;
@property(retain) NSData* waveformPaddingValue;
@property(retain) NSData* waveformData;

@property(retain) NSMutableData* buffer;

@end

@implementation DCMWaveformSequence

@synthesize multiplexgroupTimeOffset = _multiplexgroupTimeOffset;
@synthesize triggerTimeOffset = _triggerTimeOffset;
@synthesize triggerSamplePosition = _triggerSamplePosition;
@synthesize waveformOriginality = _waveformOriginality;
@synthesize numberOfWaveformChannels = _numberOfWaveformChannels;
@synthesize numberOfWaveformSamples = _numberOfWaveformSamples;
@synthesize samplingFrequency = _samplingFrequency;
@synthesize channelDefinitions = _channelDefinitions;
@synthesize multiplexGroupLabel = _multiplexGroupLabel;
@synthesize waveformBitsAllocated = _waveformBitsAllocated;
@synthesize waveformSampleInterpretation = _waveformSampleInterpretation;
@synthesize waveformPaddingValue = _waveformPaddingValue;
@synthesize waveformData = _waveformData;
@synthesize buffer = _buffer;

- (id)init {
    if ((self = [super init])) {
        self.channelDefinitions = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc {
    self.waveformData = nil;
    self.waveformPaddingValue = nil;
    self.multiplexGroupLabel = nil;
    self.channelDefinitions = nil;
    self.buffer = nil;
    [super dealloc];
}

- (void)setWaveformOriginalityCS:(char*)cs {
    if (strcmp(cs, "ORIGINAL") == 0)
        self.waveformOriginality = DCMWaveformOriginalityOriginal;
    else if (strcmp(cs, "DERIVED") == 0)
        self.waveformOriginality = DCMWaveformOriginalityDerived;
    else
        [NSException raise:NSGenericException format:@"Invalid Waveform Originality value: %s", cs];
}

- (DCMWaveformChannelDefinition*)newChannelDefinition {
    DCMWaveformChannelDefinition* cd = [[[DCMWaveformChannelDefinition alloc] init] autorelease];
    [_channelDefinitions addObject:cd];
    return cd;
}

- (void)setWaveformSampleInterpretationCS:(char*)cs {
    if (strcmp(cs, "SB") == 0)
        self.waveformSampleInterpretation = DCMWaveformSampleInterpretationSB;
    else if (strcmp(cs, "UB") == 0)
        self.waveformSampleInterpretation = DCMWaveformSampleInterpretationUB;
    else if (strcmp(cs, "MB") == 0)
        self.waveformSampleInterpretation = DCMWaveformSampleInterpretationMB;
    else if (strcmp(cs, "AB") == 0)
        self.waveformSampleInterpretation = DCMWaveformSampleInterpretationAB;
    else if (strcmp(cs, "SS") == 0)
        self.waveformSampleInterpretation = DCMWaveformSampleInterpretationSS;
    else if (strcmp(cs, "US") == 0)
        self.waveformSampleInterpretation = DCMWaveformSampleInterpretationUS;
    else
        [NSException raise:NSGenericException format:@"Invalid Waveform Sample Interpretation value: %s", cs];
}

- (void)setWaveformPaddingValue:(void*)data length:(size_t)length {
    self.waveformPaddingValue = [NSData dataWithBytes:data length:length];
}

- (void)setWaveformData:(void*)data length:(size_t)length {
    self.waveformData = [NSData dataWithBytes:data length:length];
}

- (CGFloat*)getValues:(NSUInteger*)numberOfValues {
    if (!_buffer) {
        DCMWaveformSampleInterpretation sampleInterpretation = self.waveformSampleInterpretation;
        size_t bytesPerSample = self.waveformBitsAllocated/8;
        
        size_t numberOfChannels = self.numberOfWaveformChannels;
        NSUInteger numberOfSamplesPerChannel = self.numberOfWaveformSamples;
        
        // data size should be equal to numberOfChannels * numberOfSamplesPerChannel * bytesPerSample
        if (numberOfChannels * numberOfSamplesPerChannel * bytesPerSample != self.waveformData.length)
            return nil;
        
        uint8_t* op = (void*)self.waveformData.bytes;
        
        CGFloat* mm = (CGFloat*)malloc(sizeof(CGFloat)*2*numberOfChannels);
        memset(mm, 0, sizeof(CGFloat)*2*numberOfChannels);
        
        NSUInteger il = numberOfChannels * numberOfSamplesPerChannel;
        self.buffer = [NSMutableData dataWithCapacity:il*sizeof(CGFloat)];
        CGFloat* fp = (CGFloat*)self.buffer.mutableBytes;
        for (NSUInteger i = 0; i < il; ++i, ++fp, op += bytesPerSample) { // TODO: parallelize...
            switch (sampleInterpretation) {
                case DCMWaveformSampleInterpretationSB: // signed 8bit linear
                    *fp = 1.*(*(int8_t*)op);
                    break;
                case DCMWaveformSampleInterpretationUB: // unsigned 8bit linear
                    *fp = 1.*(*op);
                    break;
                case DCMWaveformSampleInterpretationMB: { // 8bit µ-law
                    static int16_t pcm_u2lin[256] = { -32124,-31100,-30076,-29052,-28028,-27004,-25980,-24956,-23932,-22908,-21884, -20860,-19836,-18812,-17788,-16764,-15996,-15484,-14972,-14460,-13948,-13436, -12924,-12412,-11900,-11388,-10876,-10364, -9852, -9340, -8828, -8316, -7932, -7676, -7420, -7164, -6908, -6652, -6396, -6140, -5884, -5628, -5372, -5116, -4860, -4604, -4348, -4092, -3900, -3772, -3644, -3516, -3388, -3260, -3132, -3004, -2876, -2748, -2620, -2492, -2364, -2236, -2108, -1980, -1884, -1820, -1756, -1692, -1628, -1564, -1500, -1436, -1372, -1308, -1244, -1180, -1116, -1052, -988, -924, -876, -844, -812, -780, -748, -716, -684, -652, -620, -588, -556, -524, -492, -460, -428, -396, -372, -356, -340, -324, -308, -292, -276, -260, -244, -228, -212, -196, -180, -164, -148, -132, -120, -112, -104, -96, -88, -80, -72, -64, -56, -48, -40, -32, -24, -16, -8, 0, 32124, 31100, 30076, 29052, 28028, 27004, 25980, 24956, 23932, 22908, 21884, 20860, 19836, 18812, 17788, 16764, 15996, 15484, 14972, 14460, 13948, 13436, 12924, 12412, 11900, 11388, 10876, 10364, 9852, 9340, 8828, 8316, 7932, 7676, 7420, 7164, 6908, 6652, 6396, 6140, 5884, 5628, 5372, 5116, 4860, 4604, 4348, 4092, 3900, 3772, 3644, 3516, 3388, 3260, 3132, 3004, 2876, 2748, 2620, 2492, 2364, 2236, 2108, 1980, 1884, 1820, 1756, 1692, 1628, 1564, 1500, 1436, 1372, 1308, 1244, 1180, 1116, 1052, 988, 924, 876, 844, 812, 780, 748, 716, 684, 652, 620, 588, 556, 524, 492, 460, 428, 396, 372, 356, 340, 324, 308, 292, 276, 260, 244, 228, 212, 196, 180, 164, 148, 132, 120, 112, 104, 96, 88, 80, 72, 64, 56, 48, 40, 32, 24, 16, 8, 0 };
                    *fp = 1.*pcm_u2lin[*(uint8_t*)op];
                } break;
                case DCMWaveformSampleInterpretationAB: { // 8bit A-law
                    static int16_t pcm_A2lin[256] = { -5504, -5248, -6016, -5760, -4480, -4224, -4992, -4736, -7552, -7296, -8064, -7808, -6528, -6272, -7040, -6784, -2752, -2624, -3008, -2880, -2240, -2112, -2496, -2368, -3776, -3648, -4032, -3904, -3264, -3136, -3520, -3392,-22016, -20992,-24064,-23040,-17920,-16896,-19968,-18944,-30208,-29184,-32256,-31232, -26112,-25088,-28160,-27136,-11008,-10496,-12032,-11520, -8960, -8448, -9984, -9472,-15104,-14592,-16128,-15616,-13056,-12544,-14080,-13568, -344, -328, -376, -360, -280, -264, -312, -296, -472, -456, -504, -488, -408, -392, -440, -424, -88, -72, -120, -104, -24, -8, -56, -40, -216, -200, -248, -232, -152, -136, -184, -168, -1376, -1312, -1504, -1440, -1120, -1056, -1248, -1184, -1888, -1824, -2016, -1952, -1632, -1568, -1760, -1696, -688, -656, -752, -720, -560, -528, -624, -592, -944, -912, -1008, -976, -816, -784, -880, -848, 5504, 5248, 6016, 5760, 4480, 4224, 4992, 4736, 7552, 7296, 8064, 7808, 6528, 6272, 7040, 6784, 2752, 2624, 3008, 2880, 2240, 2112, 2496, 2368, 3776, 3648, 4032, 3904, 3264, 3136, 3520, 3392, 22016, 20992, 24064, 23040, 17920, 16896, 19968, 18944, 30208, 29184, 32256, 31232, 26112, 25088, 28160, 27136, 11008, 10496, 12032, 11520, 8960, 8448, 9984, 9472, 15104, 14592, 16128, 15616, 13056, 12544, 14080, 13568, 344, 328, 376, 360, 280, 264, 312, 296, 472, 456, 504, 488, 408, 392, 440, 424, 88, 72, 120, 104, 24, 8, 56, 40, 216, 200, 248, 232, 152, 136, 184, 168, 1376, 1312, 1504, 1440, 1120, 1056, 1248, 1184, 1888, 1824, 2016, 1952, 1632, 1568, 1760, 1696, 688, 656, 752, 720, 560, 528, 624, 592, 944, 912, 1008, 976, 816, 784, 880, 848 };
                    *fp = 1.*pcm_A2lin[*(uint8_t*)op];
                } break;
                case DCMWaveformSampleInterpretationSS: // 16bit signed
                    *fp = 1.*(*(int16_t*)op);
                    break;
                case DCMWaveformSampleInterpretationUS: // 16bit unsigned
                    *fp = 1.*(*(uint16_t*)op);
                    break;
            }
            
            if (i < numberOfChannels)
                mm[i*2] = mm[i*2+1] = *fp;
            else {
                NSUInteger ii = i%numberOfChannels;
                mm[ii*2] = MIN(mm[ii*2], *fp);
                mm[ii*2+1] = MAX(mm[ii*2+1], *fp);
            }
        }
        
        for (size_t i = 0; i < numberOfChannels; ++i)
            [[self.channelDefinitions objectAtIndex:i] setValuesMin:mm[i*2] max:mm[i*2+1]];
        
        free(mm);
    }
    
    *numberOfValues = _buffer.length/sizeof(CGFloat);
    return (CGFloat*)_buffer.bytes;
}

@end

@interface DCMWaveformChannelDefinition ()

@property(retain,readwrite) DCMWaveformChannelSource* channelSource;
@property(retain,readwrite) DCMWaveformChannelSensitivityUnit* channelSensitivityUnit;
@property(retain,readwrite) NSArray* channelSourceModifiers;
@property(retain,readwrite) NSArray* sourceWaveforms;
@property(retain) NSData* channelMinimumValue;
@property(retain) NSData* channelMaximumValue;

@end

@implementation DCMWaveformChannelDefinition

@synthesize waveformChannelNumber = _waveformChannelNumber;
@synthesize channelLabel = _channelLabel;
@synthesize channelStatus = _channelStatus;
@synthesize channelSource = _channelSource;
@synthesize channelDerivationDescription = _channelDerivationDescription;
@synthesize channelSensitivity = _channelSensitivity;
@synthesize channelSensitivityUnit = _channelSensitivityUnit;
@synthesize channelSensitivityCorrectionFactor = _channelSensitivityCorrectionFactor;
@synthesize channelBaseline = _channelBaseline;
@synthesize channelTimeSkew = _channelTimeSkew;
@synthesize channelSampleSkew = _channelSampleSkew;
@synthesize channelOffset = _channelOffset;
@synthesize waveformBitsStored = _waveformBitsStored;
@synthesize filterLowFrequency = _filterLowFrequency;
@synthesize filterHighFrequency = _filterHighFrequency;
@synthesize notchFilterFrequency = _notchFilterFrequency;
@synthesize notchFilterBandwidth = _notchFilterBandwidth;
@synthesize channelSourceModifiers = _channelSourceModifiers;
@synthesize sourceWaveforms = _sourceWaveforms;
@synthesize channelMinimumValue = _channelMinimumValue;
@synthesize channelMaximumValue = _channelMaximumValue;

- (id)init {
    if ((self = [super init])) {
        self.channelSourceModifiers = [NSMutableArray array];
        self.sourceWaveforms = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc {
    self.channelLabel = nil;
    self.channelSource = nil;
    self.channelSourceModifiers = nil;
    self.sourceWaveforms = nil;
    self.channelDerivationDescription = nil;
    self.channelSensitivityUnit = nil;
    self.channelMinimumValue = nil;
    self.channelMaximumValue = nil;
    [super dealloc];
}

- (void)setChannelStatusCS:(char*)cs {
    if (strcmp(cs, "OK") == 0)
        self.channelStatus = DCMWaveformChannelStatusOk;
    else if (strcmp(cs, "TEST DATA") == 0)
        self.channelStatus = DCMWaveformChannelStatusTestData;
    else if (strcmp(cs, "DISCONNECTED") == 0)
        self.channelStatus = DCMWaveformChannelStatusDisconnected;
    else if (strcmp(cs, "QUESTIONABLE") == 0)
        self.channelStatus = DCMWaveformChannelStatusQuestionable;
    else if (strcmp(cs, "INVALID") == 0)
        self.channelStatus = DCMWaveformChannelStatusInvalid;
    else if (strcmp(cs, "UNCALIBRATED") == 0)
        self.channelStatus = DCMWaveformChannelStatusUncalibrated;
    else if (strcmp(cs, "UNZEROED") == 0)
        self.channelStatus = DCMWaveformChannelStatusUnzeroed;
    else
        [NSException raise:NSGenericException format:@"Invalid Channel Status value: %s", cs];
}

- (void)setChannelMinimumValue:(void*)data length:(size_t)length {
    self.channelMinimumValue = [NSData dataWithBytes:data length:length];
}

- (void)setChannelMaximumValue:(void*)data length:(size_t)length {
    self.channelMaximumValue = [NSData dataWithBytes:data length:length];
}

- (DCMWaveformChannelSource*)newChannelSource {
    if (self.channelSource)
        [NSException raise:NSGenericException format:@"Waveform Channel Definition Sequence can only contain one Channel Source Sequence item"];
    return (self.channelSource = [[[DCMWaveformChannelSource alloc] init] autorelease]);
}

- (DCMWaveformChannelSourceModifier*)newChannelSourceModifier {
    DCMWaveformChannelSourceModifier* cd = [[[DCMWaveformChannelSourceModifier alloc] init] autorelease];
    [_channelSourceModifiers addObject:cd];
    return cd;
}

- (DCMWaveformSourceWaveform*)newSourceWaveform {
    DCMWaveformSourceWaveform* cd = [[[DCMWaveformSourceWaveform alloc] init] autorelease];
    [_sourceWaveforms addObject:cd];
    return cd;
}

- (DCMWaveformChannelSensitivityUnit*)newChannelSensitivityUnit {
    if (self.channelSensitivityUnit)
        [NSException raise:NSGenericException format:@"Waveform Channel Definition Sequence can only contain one Channel Sensitivity Units Sequence item"];
    return (self.channelSensitivityUnit = [[[DCMWaveformChannelSensitivityUnit alloc] init] autorelease]);
}

- (void)getValuesMin:(CGFloat*)min max:(CGFloat*)max {
    *min = _min;
    *max = _max;
}

- (void)setValuesMin:(CGFloat)min max:(CGFloat)max {
    _min = min;
    _max = max;
}

@end

@implementation DCMCodeSequenceMacro

@synthesize codeValue = _codeValue;
@synthesize codingSchemeDesignator = _codingSchemeDesignator;
@synthesize codingSchemeVersion = _codingSchemeVersion;
@synthesize codeMeaning = _codeMeaning;
@synthesize contextIdentifier = _contextIdentifier;
@synthesize contextUID = _contextUID;
@synthesize mappingResource = _mappingResource;
@synthesize contextGroupVersion = _contextGroupVersion;
@synthesize contextGroupExtensionFlag = _contextGroupExtensionFlag;
@synthesize contextGroupLocalVersion = _contextGroupLocalVersion;
@synthesize contextGroupExtensionCreatorUID = _contextGroupExtensionCreatorUID;

- (void)dealloc {
    self.codeValue = nil;
    self.codingSchemeDesignator = nil;
    self.codingSchemeVersion = nil;
    self.codeMeaning = nil;
    self.contextIdentifier = nil;
    self.contextUID = nil;
    self.contextGroupVersion = nil;
    self.contextGroupLocalVersion = nil;
    self.contextGroupExtensionCreatorUID = nil;
    [super dealloc];
}

- (void)setMappingResourceCS:(char*)cs {
    if (strcmp(cs, "DCMR") == 0)
        self.mappingResource = DCMMappingResourceDCMR;
    else if (strcmp(cs, "SDM") == 0)
        self.mappingResource = DCMMappingResourceSDM;
    else
        [NSException raise:NSGenericException format:@"Invalid Mapping Resource value: %s", cs];
}

- (void)setContextGroupExtensionFlagCS:(char*)cs {
    if (strcmp(cs, "Y") == 0)
        self.contextGroupExtensionFlag = DCMContextGroupExtensionFlagY;
    else if (strcmp(cs, "N") == 0)
        self.contextGroupExtensionFlag = DCMContextGroupExtensionFlagN;
    else
        [NSException raise:NSGenericException format:@"Invalid Context Group Extension Flag value: %s", cs];
}

@end

@implementation DCMSOPInstanceReferenceMacro

@synthesize referencedSOPClassUID = _referencedSOPClassUID;
@synthesize referencedSOPInstanceUID = _referencedSOPInstanceUID;

- (void)dealloc {
    self.referencedSOPClassUID = nil;
    self.referencedSOPInstanceUID = nil;
    [super dealloc];
}

@end

@implementation DCMWaveformChannelSource;
@end

@implementation DCMWaveformChannelSourceModifier;
@end

@implementation DCMWaveformSourceWaveform;

@synthesize referencedWaveformChannels = _referencedWaveformChannels;

@end

@implementation DCMWaveformChannelSensitivityUnit;
@end























