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

#import "DCMTransferSyntax.h"
#import "DCM.h"
//#import "DCMUIDs.h"

static NSString *DCM_ExplicitVRBigEndian = @"1.2.840.10008.1.2.2";
static NSString *DCM_ExplicitVRLittleEndian = @"1.2.840.10008.1.2.1";
static NSString *DCM_ImplicitVRLittleEndian = @"1.2.840.10008.1.2";
static NSString *DCM_JPEG1012Retired = @"1.2.840.10008.1.2.4.55";
static NSString *DCM_JPEG1113Retired = @"1.2.840.10008.1.2.4.56";
static NSString *DCM_JPEG1618Retired = @"1.2.840.10008.1.2.4.59";
static NSString *DCM_JPEG1719Retired = @"1.2.840.10008.1.2.4.60";
static NSString *DCM_JPEG2000Lossless = @"1.2.840.10008.1.2.4.90";
static NSString *DCM_JPEG2000Lossy = @"1.2.840.10008.1.2.4.91";
static NSString *DCM_JPEG2022Retired = @"1.2.840.10008.1.2.4.61";
static NSString *DCM_JPEG2123Retired = @"1.2.840.10008.1.2.4.62";
static NSString *DCM_JPEG2426Retired = @"1.2.840.10008.1.2.4.63";
static NSString *DCM_JPEG2527Retired = @"1.2.840.10008.1.2.4.64";
static NSString *DCM_JPEG29Retired = @"1.2.840.10008.1.2.4.66";
static NSString *DCM_JPEG68Retired = @"1.2.840.10008.1.2.4.53";
static NSString *DCM_JPEG79Retired = @"1.2.840.10008.1.2.4.54";
static NSString *DCM_JPEGBaseline = @"1.2.840.10008.1.2.4.50";
static NSString *DCM_JPEGExtended = @"1.2.840.10008.1.2.4.51";
static NSString *DCM_JPEGExtended35Retired = @"1.2.840.10008.1.2.4.52";
static NSString *DCM_JPEGLoRetired = @"1.2.840.10008.1.2.4.65";
static NSString *DCM_JPEGLossless = @"1.2.840.10008.1.2.4.70";
static NSString *DCM_JPEGLossless14 = @"1.2.840.10008.1.2.4.57";
static NSString *DCM_JPEGLossless15Retired = @"1.2.840.10008.1.2.4.58";
static NSString *DCM_JPEGLSLossless = @"1.2.840.10008.1.2.4.80";
static NSString *DCM_JPEGLSLossy = @"1.2.840.10008.1.2.4.81";
static NSString *DCM_RLELossless = @"1.2.840.10008.1.2.5";
static NSString *DCM_MPEG2Main = @"1.2.840.10008.1.2.4.100";

@implementation DCMTransferSyntax

@synthesize transferSyntax, name;
@synthesize isEncapsulated, isLittleEndian, isExplicit;

+(id)ExplicitVRLittleEndianTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_ExplicitVRLittleEndian] autorelease];
}

+(id)ImplicitVRLittleEndianTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_ImplicitVRLittleEndian] autorelease];
}

+(id)ExplicitVRBigEndianTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_ExplicitVRBigEndian] autorelease];
}
+(id)JPEG2000LosslessTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEG2000Lossless] autorelease];
}

+(id)JPEG2000LossyTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEG2000Lossy] autorelease];
}

+(id)JPEGBaselineTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEGBaseline] autorelease];
}

+(id)JPEGExtendedTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEGExtended] autorelease];
}

+(id)JPEGLosslessTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEGLossless] autorelease];
}

+(id)JPEGLossless14TransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEGLossless14] autorelease];
}

+(id)JPEGLSLosslessTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEGLSLossless] autorelease];
}

+(id)JPEGLSLossyTransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_JPEGLSLossy] autorelease];
}

+(id)RLETransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_RLELossless] autorelease];
}

+(id)MPEG2TransferSyntax{
	return [[[DCMTransferSyntax alloc] initWithTS:DCM_MPEG2Main] autorelease];
}

static NSMutableDictionary *gTransferSyntaxes = nil;

- (id)initWithTS:(NSString *)ts
{
    if( ts.length == 0)
    {
        [self autorelease];
        return nil;
    }
    
	if (self = [super init])
    {
        if( !gTransferSyntaxes)
        {
            NSArray *tsSyntaxes = [NSArray arrayWithObjects:
                               DCM_ExplicitVRBigEndian,
                               DCM_ExplicitVRLittleEndian,
                               DCM_ImplicitVRLittleEndian,
                               DCM_JPEG1012Retired,
                               DCM_JPEG1113Retired,
                               DCM_JPEG1618Retired,
                               DCM_JPEG1719Retired,
                               DCM_JPEG2000Lossless,
                               DCM_JPEG2000Lossy,
                               DCM_JPEG2022Retired,
                               DCM_JPEG2123Retired,
                               DCM_JPEG2426Retired,
                               DCM_JPEG2527Retired,
                               DCM_JPEG29Retired,
                               DCM_JPEG68Retired,
                               DCM_JPEG79Retired,
                               DCM_JPEGBaseline,
                               DCM_JPEGExtended,
                               DCM_JPEGExtended35Retired,
                               DCM_JPEGLoRetired,
                               DCM_JPEGLossless,
                               DCM_JPEGLossless14,
                               DCM_JPEGLossless15Retired,
                               DCM_JPEGLSLossless,
                               DCM_JPEGLSLossy,
                               DCM_RLELossless,
                               nil];
            
            NSArray *tsNames = [NSArray arrayWithObjects:
                            @"ExplicitVRBigEndian",
                            @"ExplicitVRLittleEndian",
                            @"ImplicitVRLittleEndian",
                            @"JPEG1012Retired",
                            @"JPEG1113Retired",
                            @"JPEG1618Retired",
                            @"JPEG1719Retired",
                            @"JPEG2000Lossless",
                            @"JPEG2000Lossy",
                            @"JPEG2022Retired",
                            @"JPEG2123Retired",
                            @"JPEG2426Retired",
                            @"JPEG2527Retired",
                            @"JPEG29Retired",
                            @"JPEG68Retired",
                            @"JPEG79Retired",
                            @"JPEGBaseline",
                            @"JPEGExtended",
                            @"JPEGExtended35Retired",
                            @"JPEGLoRetired",
                            @"JPEGLossless",
                            @"JPEGLossless14",
                            @"JPEGLossless15Retired",
                            @"JPEGLSLossless",
                            @"JPEGLSLossy",
                            @"RLELossless",
                            nil];
            
            gTransferSyntaxes = [[NSMutableDictionary alloc] init];
            
            for ( unsigned int i = 0; i < tsSyntaxes.count; i++ ) {
                NSString *key = [tsSyntaxes objectAtIndex: i ];
                NSString *aName = [tsNames objectAtIndex: i];
                BOOL encapsulated = YES;
                BOOL littleEndian = YES;
                BOOL explicitValue = YES;
                //only Big Endian in ExplictVRBE
                if ([key isEqualToString:DCM_ExplicitVRBigEndian])
                    littleEndian = NO;
                //unencasualted TSs
                if ([key isEqualToString:DCM_ExplicitVRBigEndian] ||					
                    [key isEqualToString:DCM_ExplicitVRLittleEndian] ||
                    [key isEqualToString:DCM_ImplicitVRLittleEndian])
                    encapsulated = NO;
                //implicit TSs
                if ([key isEqualToString:DCM_ImplicitVRLittleEndian]) 
                    explicitValue = NO;
                NSMutableDictionary *syntax = [NSMutableDictionary dictionary];
                [syntax setObject:[NSNumber numberWithBool:encapsulated] forKey:@"isEncapsulated"];
                [syntax setObject:[NSNumber numberWithBool:littleEndian] forKey:@"isLittleEndian"];
                [syntax setObject:[NSNumber numberWithBool:explicitValue] forKey:@"isExplicit"];
                [syntax setObject:key forKey:@"TransferSyntax"];
                [syntax setObject:aName forKey:@"Name"];
                [gTransferSyntaxes setObject:syntax forKey:key];
            }
		}
        
		transferSyntaxDict = [[gTransferSyntaxes objectForKey: ts] retain];
		transferSyntax = [ts retain];
		if (transferSyntaxDict) {			
			isEncapsulated = [[transferSyntaxDict objectForKey:@"isEncapsulated"] boolValue];
			isLittleEndian = [[transferSyntaxDict objectForKey:@"isLittleEndian"] boolValue];
			isExplicit = [[transferSyntaxDict objectForKey:@"isExplicit"] boolValue];
			name = [[transferSyntaxDict objectForKey:@"Name"] retain];
		}
		else{
			isEncapsulated = YES;
			isLittleEndian = YES;
			isExplicit = YES;
			name = @"Unknown Syntax";
			[name retain];
		}
	}

	if (ts)
		return self;
	else
    {
        [self autorelease];
		return nil;
    }
}


- (id)initWithTS:(NSString *)ts isEncapsulated:(BOOL)encapsulated  isLittleEndian:(BOOL)endian  isExplicit:(BOOL)explicitValue name:(NSString *)aName{
	return self;
}

- (id)initWithTransferSyntax:(DCMTransferSyntax *)ts{
/*
	transferSyntax = [[ts transferSyntax] copy];
	isEncapsulated = [ts isEncapsulated];
	isLittleEndian = [ts isLittleEndian];
	isExplicit = [ts isExplicit];
	name = [[ts name] copy];
*/
//	NSLog(@"initWithTransferSyntax");
	return [self initWithTS:[ts transferSyntax]];
	
}

- (id)copyWithZone:(NSZone *)zone{
	return [[DCMTransferSyntax allocWithZone:zone] initWithTransferSyntax:self];
}


- (void)dealloc{
//	if (DCMDEBUG)
//		NSLog(@"Release DCMTransferSyntax %@", [super description]);
	[transferSyntaxDict release];
	[transferSyntax release];
	[name release];
	[super dealloc];
}

- (BOOL)isEqualToTransferSyntax:(DCMTransferSyntax *)ts{
	return [transferSyntax isEqualToString:[ts transferSyntax]];
}

- (BOOL)isEqual:(id)object{
	return [self isEqualToTransferSyntax:object];
}

- (NSString*) description
{
	return name;
}

@end
