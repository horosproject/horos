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

#import "DefaultsOsiriX.h"
#import "PluginManager.h"
#import "NSUserDefaults+OsiriX.h"
#import "DCMAbstractSyntaxUID.h"
#import <AVFoundation/AVFoundation.h>

#ifdef OSIRIX_VIEWER
#import "DCMNetServiceDelegate.h"
#endif

#include <IOKit/graphics/IOGraphicsLib.h>

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>

#import "url.h"

//static BOOL isHcugeCh = NO, isUnigeCh = NO, testIsHugDone = NO, testIsUniDone = NO;
//static NSString *hostName = @"";
static NSHost *currentHost = nil;

@implementation DefaultsOsiriX

+(NSHost*) currentHost
{
	@synchronized( NSApp)
	{
		if( currentHost == nil)
			currentHost = [[NSHost currentHost] retain];
	}
	return currentHost;
}

// Test if the computer is in the HUG (domain name == hcuge.ch)
//+ (NSString*) hostName
//{
//	return hostName;
//}

//+ (BOOL) isHUG
//{
//	if( testIsHugDone == NO)
//	{
////		NSArray	*names = [[DefaultsOsiriX currentHost] names];
////		int i;
////		for( i = 0; i < [names count] && !isHcugeCh; i++)
////		{
////			int len = [[names objectAtIndex: i] length];
////			if ( len < 8 ) continue;  // Fixed out of bounds error in following line when domainname is short.
////			NSString *domainName = [[names objectAtIndex: i] substringFromIndex: len - 8];
////
////			if([domainName isEqualToString: @"hcuge.ch"])
////			{
////				isHcugeCh = YES;
////				hostName = [[names objectAtIndex: i] retain];
////			}
////		}
//		
//		char s[_POSIX_HOST_NAME_MAX+1];
//		gethostname(s,_POSIX_HOST_NAME_MAX);
//		NSString *c = [NSString stringWithUTF8String:s encoding:NSUTF8StringEncoding];
//		
//		if( [c length] > 8 )
//		{
//			NSString *domainName = [c substringFromIndex: [c length] - 8];
//
//			if([domainName isEqualToString: @"hcuge.ch"])
//			{
//				isHcugeCh = YES;
//				hostName = [c retain];
//			}
//		}
//		
//		testIsHugDone = YES;
//	}
//	return isHcugeCh;
//}

//+ (BOOL) isUniGE
//{
//	if( testIsUniDone == NO)
//	{
////		NSArray	*names = [[DefaultsOsiriX currentHost] names];
////		int i;
////		for( i = 0; i < [names count] && !isUnigeCh; i++)
////		{
////			int len = [[names objectAtIndex: i] length];
////			if ( len < 8 ) continue;  // Fixed out of bounds error in following line when domainname is short.
////			NSString *domainName = [[names objectAtIndex: i] substringFromIndex: len - 8];
////
////			if([domainName isEqualToString: @"unige.ch"])
////			{
////				isUnigeCh = YES;
////				hostName = [[names objectAtIndex: i] retain];
////			}
////		}
//		
//		char s[_POSIX_HOST_NAME_MAX+1];
//		gethostname(s,_POSIX_HOST_NAME_MAX);
//		NSString *c = [NSString stringWithUTF8String:s encoding:NSUTF8StringEncoding];
//		
//		if( [c length] > 8 )
//		{
//			NSString *domainName = [c substringFromIndex: [c length] - 8];
//
//			if([domainName isEqualToString: @"unige.ch"])
//			{
//				isUnigeCh = YES;
//				hostName = [c retain];
//			}
//		}
//		
//		testIsUniDone = YES;
//	}
//	return isUnigeCh;
//}

//+ (BOOL) isLAVIM
//{
//	#ifdef OSIRIX_VIEWER
//	if( [self isHUG])
//	{
//		int i;
//		
//		for( i = 0; i < [[PluginManager preProcessPlugins] count]; i++)
//		{
//			id filter = [[PluginManager preProcessPlugins] objectAtIndex:i];
//			
//			if( [[filter className] isEqualToString:@"LavimAnonymize"]) return YES;
//		}
//	}
//	else if([self isUniGE])
//	{
//		if ([hostName isEqualToString:@"lavimcmu1.unige.ch"]) return YES;
//	}
//	#endif
//	
//	return NO;
//}

+ (void) addCLUT: (NSString*) filename dictionary: (NSMutableDictionary*) clutValues
{
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"]];
	
	if( d)
		[clutValues setObject: d forKey: filename];
	else
		NSLog(@"CLUT plist not found: %@", filename);
}

+ (void) addConvolutionFilter: (short) size :(short*) vals :(NSString*) name :(NSMutableDictionary*) convValues
{
	long				i;
	NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
	NSMutableArray		*valArray = [NSMutableArray array];

	[aConvFilter setObject:[NSNumber numberWithLong:size] forKey:@"Size"];
	
	long norm = 0;
	for( i = 0; i < size*size; i++) norm += vals[i];
	[aConvFilter setObject:[NSNumber numberWithLong:norm] forKey:@"Normalization"];
	
	for( i = 0; i < size*size; i++) [valArray addObject:[NSNumber numberWithLong:vals[i]]];
	[aConvFilter setObject:valArray forKey:@"Matrix"];
	
	[convValues setObject:aConvFilter forKey:name];
}

+ (mach_vm_size_t) GPUModelVRAMInfo
{
    io_iterator_t Iterator;
    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOPCIDevice"), &Iterator);
    if (err != KERN_SUCCESS)
    {
        NSLog(@"IOServiceGetMatchingServices failed: %u\n", err);
        return -1;
    }
    
    for (io_service_t Device; IOIteratorIsValid(Iterator) && (Device = IOIteratorNext(Iterator)); IOObjectRelease(Device))
    {
        CFStringRef Name = IORegistryEntrySearchCFProperty(Device, kIOServicePlane, CFSTR("IOName"), kCFAllocatorDefault, kNilOptions);
        if (Name)
        {
            if (CFStringCompare(Name, CFSTR("display"), 0) == kCFCompareEqualTo)
            {
                CFDataRef Model = IORegistryEntrySearchCFProperty(Device, kIOServicePlane, CFSTR("model"), kCFAllocatorDefault, kNilOptions);
                if (Model)
                {
                    _Bool ValueInBytes = TRUE;
                    CFTypeRef VRAMSize = IORegistryEntrySearchCFProperty(Device, kIOServicePlane, CFSTR("VRAM,totalsize"), kCFAllocatorDefault, kIORegistryIterateRecursively); //As it could be in a child
                    if (!VRAMSize)
                    {
                        ValueInBytes = FALSE;
                        VRAMSize = IORegistryEntrySearchCFProperty(Device, kIOServicePlane, CFSTR("VRAM,totalMB"), kCFAllocatorDefault, kIORegistryIterateRecursively); //As it could be in a child
                    }
                    
                    if (VRAMSize)
                    {
                        mach_vm_size_t Size = 0;
                        CFTypeID Type = CFGetTypeID(VRAMSize);
                        if (Type == CFDataGetTypeID())
                            Size = (CFDataGetLength(VRAMSize) == sizeof(uint32_t) ? (mach_vm_size_t)*(const uint32_t*)CFDataGetBytePtr(VRAMSize)
                                    : *(const uint64_t*)CFDataGetBytePtr(VRAMSize));
                        else if (Type == CFNumberGetTypeID())
                            CFNumberGetValue(VRAMSize, kCFNumberSInt64Type, &Size);
                        
                        if (ValueInBytes)
                            Size >>= 20;
                        
                        NSLog(@"Graphics: %s, %lluMB", CFDataGetBytePtr(Model), Size);
                        
                        CFRelease(Model);
                        return Size;
                    }
                    else
                        NSLog(@"%s : Unknown VRAM Size\n", CFDataGetBytePtr(Model));
                    
                    
                    CFRelease(Model);
                } // if Model
            }
            
            CFRelease(Name);
        } // if Name
    } // for
    
    return 0;
}

+ (long) vramSize
{
	int					i = 0;
	short				MAXDISPLAYS = 8;
	io_service_t		dspPorts[MAXDISPLAYS];
	CGDirectDisplayID   displays[MAXDISPLAYS];
	CFTypeRef			typeCode;
	CGDisplayCount		displayCount = 0;
	
	// First we're going to grab the online displays
	CGGetOnlineDisplayList(MAXDISPLAYS, displays, &displayCount);
	
    if( displayCount <= 0)
        return 0;
    
	// Now we iterate through them
	for(i = 0; i < displayCount; i++)
		dspPorts[i] = CGDisplayIOServicePort(displays[i]);

	// Ask for the physical size of VRAM of the primary display
	typeCode = IORegistryEntryCreateCFProperty(dspPorts[0], CFSTR("IOFBMemorySize"), kCFAllocatorDefault, kNilOptions);
	
	// Validate our data and make sure we're getting the right type
	if(typeCode)
	{
		SInt32 vramStorage = 0;
		// Convert this to a useable number
		
		if( CFGetTypeID(typeCode) == CFNumberGetTypeID())
			CFNumberGetValue(typeCode, kCFNumberSInt32Type, &vramStorage);
		
		CFRelease( typeCode);
		
		return vramStorage;
	}
	
	return 0;
}

+ (NSMutableDictionary*) getDefaults
{
	long i;
	
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	// ** WLWW PRESETS
	float iww, iwl;
	
	NSMutableDictionary *wlwwValues = [NSMutableDictionary dictionary];
	
	iww = 1400;          iwl = -500;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:@"CT - Pulmonary"];
	
	iww = 1500;          iwl = 300;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:@"CT - Bone"];
	
	iww = 100;          iwl = 50;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:@"CT - Brain"];
	
	iww = 350;          iwl = 40;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:@"CT - Abdomen"];
	
	iww = 700;          iwl = -300;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:@"VR - Endoscopy"];
	
	[defaultValues setObject:wlwwValues forKey:@"WLWW3"];
	
	// ** CONVOLUTION PRESETS
	
	NSMutableDictionary *convValues = [NSMutableDictionary dictionary];
	
	// --
	{
		NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*valArray = [NSMutableArray array];
		short				vals[9] = {-1, -1, -1, -1, 9, -1, -1, -1, -1};
		
		[aConvFilter setObject:[NSNumber numberWithLong:3] forKey:@"Size"];
		[aConvFilter setObject:[NSNumber numberWithLong:1] forKey:@"Normalization"];
		for( i = 0; i < 9; i++) [valArray addObject: [NSNumber numberWithLong:vals[i]]];
		[aConvFilter setObject:valArray forKey:@"Matrix"];
		[convValues setObject:aConvFilter forKey:@"Bone Filter 3x3"];
	}
	// --
	// --
	{
		NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*valArray = [NSMutableArray array];
		short				vals[25] = {	1, 1, 1, 1, 1,
			1, 4, 4, 4, 1,
			1, 4, 12, 4, 1,
			1, 4, 4, 4, 1,
			1, 1, 1, 1, 1};
		
		[aConvFilter setObject:[NSNumber numberWithLong:5] forKey:@"Size"];
		[aConvFilter setObject:[NSNumber numberWithLong:60] forKey:@"Normalization"];
		for( i = 0; i < 25; i++) [valArray addObject:[NSNumber numberWithLong:vals[i]]];
		[aConvFilter setObject:valArray forKey:@"Matrix"];
		[convValues setObject:aConvFilter forKey:@"Basic Smooth 5x5"];
	}
	{
		short				vals[9] = {1, 2, 1, 2, 4, 2, 1, 2, 1};
		[self addConvolutionFilter:3 :vals :@"Blur 3x3" :convValues];
	}
	{
		short				vals[25] = {1, 1, 2, 1, 1, 1, 2, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 2, 1, 1, 1, 2, 1, 1};
		[self addConvolutionFilter:5 :vals :@"Blur 5x5" :convValues];
	}
	{
		short				vals[25] = {3, 3, 2, 3, 3, 3, 2, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 2, 3, 3, 3, 2, 3, 3};
		[self addConvolutionFilter:5 :vals :@"Inverted blur" :convValues];
	}
	{
		short				vals[25] = {0, 0, -1, 0, 0, 0, -1, -2, -1, 0, -1, -2, -3, -2, -1, 0, -1, -2, -1, 0, 0, 0, -1, 0, 0};
		[self addConvolutionFilter:5 :vals :@"Negative blur" :convValues];
	}
	{
		short				vals[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};
		[self addConvolutionFilter:3 :vals :@"Emboss north" :convValues];
	}
	{
		short				vals[9] = {1, 0, -1, 2, 0, -2, 1, 0, -1};
		[self addConvolutionFilter:3 :vals :@"Emboss west" :convValues];
	}
	{
		short				vals[9] = {0, 1, 0, -1, 0, 1, 0, -1, 0};
		[self addConvolutionFilter:3 :vals :@"Emboss diagonal" :convValues];
	}
	{
		short				vals[9] = {-1, -1, -1, -1, 8, -1, -1, -1, -1};
		[self addConvolutionFilter:3 :vals :@"Laplacian 8" :convValues];
	}
	{
		short				vals[9] = {0, -1, 0, -1, 4, -1, 0, -1, 0};
		[self addConvolutionFilter:3 :vals :@"Laplacian 4" :convValues];
	}	
	{
		short				vals[9] = {-1, 0, -1, 0, 7, 0, -1, 0, -1};
		[self addConvolutionFilter:3 :vals :@"Sharpen 3x3" :convValues];
	}
	{
		short				vals[9] = {-1, 0, 0, 0, 0, 0, 0, 0, 1};
		[self addConvolutionFilter:3 :vals :@"Emboss" :convValues];
	}
	{
		short				vals[9] = {-1, -1, 0, -1, 0, 1, 0, 1, 1};
		[self addConvolutionFilter:3 :vals :@"Emboss heavy" :convValues];
	}
	{
		short				vals[9] = {1, 1, 1, 1, 1, 1, 1, 1, 1};
		[self addConvolutionFilter:3 :vals :@"Lowpass" :convValues];
	}
	{
		short				vals[9] = {1, -2, 1, -2, 4, -2, 1, -2, 1};
		[self addConvolutionFilter:3 :vals :@"Edge 3x3" :convValues];
	}
	{
		short				vals[25] = {0, -1, -1, -1, 0, -1, 2, -4, 2, -1, -1, -4, 13, -4, -1, -1, 2, -4, 2, -1, 0, -1, -1, -1, 0};
		[self addConvolutionFilter:5 :vals :@"Highpass 5x5" :convValues];
	}
	{
		short				vals[25] = {1, 1, 2, 1, 1, 1, 2, 4, 2, 1, 2, 4, 8, 4, 2, 1, 2, 4, 2, 1, 1, 1, 2, 1, 1};
		[self addConvolutionFilter:5 :vals :@"Gaussian blur" :convValues];
	}
	{
		short				vals[25] = {0,  0, -1,  0,  0, 0, -1, -2, -1,  0, -1, -2, 16, -2, -1, 0, -1, -2, -1,  0, 0,   0,  -1,   0,   0};
		[self addConvolutionFilter:5 :vals :@"Hat" :convValues];
	}
	{
		short				vals[25] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 24, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
		[self addConvolutionFilter:5 :vals :@"Laplacian" :convValues];
	}
	{
		short				vals[25] = {-1, -1, -1, -1, -1, -1, 2, 2, 2, -1, -1, 2, 8, 2, -1, -1, 2, 2, 2, -1, -1, -1, -1, -1, -1};
		[self addConvolutionFilter:5 :vals :@"Sharpen 5x5" :convValues];
	}
	{
		short				vals[9] = {1, 1, 1, 1, -7, 1, 1, 1, 1};
		[self addConvolutionFilter:3 :vals :@"Excessive edges" :convValues];
	}
	
	// --
	
	[defaultValues setObject:convValues forKey:@"Convolution"];
	
	// ** OPACITY TABLES
	NSMutableDictionary *opacityValues = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *aOpacityFilter = [NSMutableDictionary dictionary];
	NSMutableArray *points = [NSMutableArray array];
	
	for( i = 0; i < 256; i++)
	{
		NSPoint pt;
		//math.h
		pt.x = 1000+i;
		pt.y = log10( 1. + (i/255.)*9.);
		
		[points addObject: NSStringFromPoint( pt)];
	}
	
	[aOpacityFilter setObject:points forKey:@"Points"];
	[opacityValues setObject:aOpacityFilter forKey:@"Logarithmic Table"];
	
	// Log Inverse
	
	aOpacityFilter = [NSMutableDictionary dictionary];
	points = [NSMutableArray array];
	
	for( i = 0; i < 256; i++)
	{
		NSPoint pt;
		//math.h
		pt.x = 1000+i;
		pt.y = 1. - log10( 1. + ((255-i)/255.)*9.);
		
		[points addObject: NSStringFromPoint( pt)];
	}
	
	[aOpacityFilter setObject:points forKey:@"Points"];
	[opacityValues setObject:aOpacityFilter forKey:@"Logarithmic Inverse Table"];
	
	// Smooth CT
	
	aOpacityFilter = [NSMutableDictionary dictionary];
	points = [NSMutableArray array];
	
	{
		NSPoint pt;
		pt.x = 1000+180;
		pt.y = 0.05;
		
		[points addObject: NSStringFromPoint( pt)];
	}
	
	[aOpacityFilter setObject:points forKey:@"Points"];
	[opacityValues setObject:aOpacityFilter forKey:@"Smooth Table"];
	
	[defaultValues setObject:opacityValues forKey:@"OPACITY"];
	
	// ** CLUT PRESETS
	NSMutableDictionary *clutValues = [NSMutableDictionary dictionary];
	
	// --
	{
	//    NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
	//	NSMutableArray		*rArray = [NSMutableArray array];
	//	for( i = 0; i < 256; i++)
	//	{
	//		[rArray addObject: [NSNumber numberWithLong:i]];
	//	}
	//	[aCLUTFilter setObject:rArray forKey:@"Red"];
	//	
	//	NSMutableArray		*gArray = [NSMutableArray array];
	//	for( i = 0; i < 256; i++)
	//	{
	//		[gArray addObject: [NSNumber numberWithLong:0]];
	//	}
	//	[aCLUTFilter setObject:gArray forKey:@"Green"];
	//	
	//	NSMutableArray		*bArray = [NSMutableArray array];
	//	for( i = 0; i < 256; i++)
	//	{
	//		[bArray addObject: [NSNumber numberWithLong:0]];
	//	}
	//	[aCLUTFilter setObject:bArray forKey:@"Blue"];
	//	
	//	[clutValues setObject:aCLUTFilter forKey:@"Red CLUT"];
	}
	
	// --
	{
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*rArray = [NSMutableArray array];
		for( i = 0; i < 128; i++) [rArray addObject: [NSNumber numberWithLong:i*2]];
		for( i = 128; i < 256; i++) [rArray addObject: [NSNumber numberWithLong:255]];
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		
		NSMutableArray		*gArray = [NSMutableArray array];
		for( i = 0; i < 128; i++) [gArray addObject: [NSNumber numberWithLong:0]];
		for( i = 128; i < 192; i++) [gArray addObject: [NSNumber numberWithLong: (i-128)*4]];
		for( i = 192; i < 256; i++) [gArray addObject: [NSNumber numberWithLong: 255]];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		
		NSMutableArray		*bArray = [NSMutableArray array];
		for( i = 0; i < 192; i++) [bArray addObject: [NSNumber numberWithLong:0]];
		for( i = 192; i < 256; i++) [bArray addObject: [NSNumber numberWithLong:(i-192)*4]];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray array], *points = [NSMutableArray array];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 128]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 192]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], nil]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"PET"];
	}
	
	// --
	{
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*rArray = [NSMutableArray array];
		for( i = 0; i < 256; i++) [rArray addObject: [NSNumber numberWithLong:255-i]];
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		
		NSMutableArray		*gArray = [NSMutableArray array];
		for( i = 0; i < 256; i++) [gArray addObject: [NSNumber numberWithLong:255-i]];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		
		NSMutableArray		*bArray = [NSMutableArray array];
		for( i = 0; i < 256; i++) [bArray addObject: [NSNumber numberWithLong:255-i]];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray array], *points = [NSMutableArray array];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], nil]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"B/W Inverse"];
	}
	
	{
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*rArray = [NSMutableArray array];
		NSMutableArray		*gArray = [NSMutableArray array];
		NSMutableArray		*bArray = [NSMutableArray array];
		for( i = 0; i < 256; i++)  {
			[bArray addObject: [NSNumber numberWithLong:(195 - (i * 0.26))]];
			[gArray addObject: [NSNumber numberWithLong:(187 - (i *0.26))]];
			[rArray addObject: [NSNumber numberWithLong:(240 + (i * 0.02))]];
		}
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray array], *points = [NSMutableArray array];
		[points addObject:[NSNumber numberWithLong: 0]];
		[points addObject:[NSNumber numberWithLong: 255]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], nil]];
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];

		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"Endoscopy"];
	}
    
    {
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
        
        int r[ 256] = {0,0,2,4,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,32,34,36,36,38,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,38,36,36,34,32,32,30,28,28,26,24,24,22,20,20,18,16,16,14,12,12,10,10,10,8,8,8,6,6,6,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,148,168,176,184,192,200,208,214,220,224,226,248,250,252,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,252,250,250,248,246,246,242,240,238,236,234,232,230,228,226,224,220,218,216,214,214,214,214,214,214,214,214,214,214,214,214,214,214,214,214,214,214,216,216,216,218,216,216,214,214,214,214,212,212,212,210,210,210,208,208,208,206,206,206,206,206,206,206,206,206,206,206,206,206,206,206,206,206,206,206,204,204,204,204,204,204,204,204,204,206,208,210,210,214,216,218,222,226,230,232,236,238,240,240,240,240,240,240,240,240,240};
        
        int g[ 256] = {0,2,4,6,8,10,12,14,16,18,20,22,24,28,30,32,36,38,40,44,46,48,52,54,56,60,62,64,68,70,72,76,78,80,84,86,88,92,94,96,100,102,104,108,110,112,116,118,120,124,126,128,132,134,136,140,142,144,146,148,150,152,154,156,158,160,162,162,162,162,162,162,162,162,162,162,160,158,158,156,154,154,152,150,150,148,146,146,144,142,142,140,140,140,130,128,128,126,126,126,126,126,126,128,128,130,130,134,138,142,148,152,158,164,168,174,180,184,190,196,202,206,212,218,222,228,234,238,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,226,218,210,202,194,186,178,170,162,154,146,138,130,122,114,106,98,90,82,74,66,58,50,42,34,26,18,10,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,4,4,4,6,6,6,8,8,8,10,10,10,12,14,14,16,18,18,62,34,42,50,58,66,74,82,90,98,106,114,122,130,138,144,152,160,168,176,184,192,200,208,216,224,232,240,248,254};
        
        int b[ 256] = {0,6,10,16,20,24,30,34,38,44,48,54,58,62,68,72,76,82,86,92,96,100,106,110,114,120,124,130,134,138,144,148,152,152,152,150,148,146,144,142,140,138,136,134,132,130,128,128,126,126,124,122,122,120,118,118,116,114,114,112,110,110,108,106,106,106,104,102,98,96,94,90,88,86,84,82,80,78,76,74,72,70,68,66,64,62,58,56,54,48,40,38,38,36,36,36,36,36,26,24,18,16,12,10,8,6,6,4,4,2,2,2,4,4,4,6,6,6,8,8,8,10,10,10,12,12,12,14,14,14,14,48,60,60,60,60,60,60,60,60,60,60,60,60,56,52,44,36,28,20,12,8,4,4,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,4,4,6,6,6,8,8,24,32,122,124,126,128,130,132,134,136,138,140,142,144,146,148,150,152,154,156,158,158,160,160,162,162,164,164,164,164,164,164,164,164,164,164,164,164,164,246,248,248,250,250,252,252,244,248,252,254,254,254,254,254,254,254,254};
        
		NSMutableArray		*rArray = [NSMutableArray array];
		NSMutableArray		*gArray = [NSMutableArray array];
		NSMutableArray		*bArray = [NSMutableArray array];
		for( i = 0; i < 256; i++)
        {
			[bArray addObject: [NSNumber numberWithLong: r[ i]]];
			[gArray addObject: [NSNumber numberWithLong: g[ i]]];
			[rArray addObject: [NSNumber numberWithLong: b[ i]]];
		}
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray array], *points = [NSMutableArray array];
		[points addObject:[NSNumber numberWithLong: 0]];
		[points addObject:[NSNumber numberWithLong: 255]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], nil]];
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
        
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"French"];
	}
    
    {
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
        
        int r[ 256] = {0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,6,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,6,8,10,14,16,18,22,24,26,28,32,34,36,40,42,44,48,50,52,54,58,60,62,66,68,70,74,76,78,80,84,86,88,92,94,96,98,102,104,106,110,112,114,118,120,122,124,128,130,132,136,138,140,144,146,148,150,154,156,158,162,164,166,168,172,174,176,180,182,184,188,190,192,194,198,200,202,206,208,210,214,216,218,220,224,226,228,232,234,236,240,242,244,246,250,252,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254};
        
        int g[ 256] = {0,6,8,10,12,14,14,16,18,20,22,22,24,26,28,30,30,32,34,36,38,38,40,42,44,46,46,48,50,52,54,54,56,58,60,62,62,64,66,68,70,70,72,74,76,78,78,76,78,76,76,74,74,72,72,70,68,68,66,66,64,64,62,60,60,58,58,56,56,54,52,52,50,50,48,48,46,46,44,42,42,40,40,38,38,36,34,34,32,32,30,30,28,26,26,24,24,22,22,20,18,18,16,16,14,14,12,12,10,8,8,6,6,4,4,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,4,6,10,12,14,18,20,22,26,28,30,34,36,38,42,44,46,50,52,54,58,60,62,66,68,70,74,76,78,82,84,86,90,92,94,98,100,102,106,108,110,114,116,118,122,124,126,130,132,134,138,140,142,146,148,150,154,156,158,162,164,166,170,172,174,178,180,182,186,188,190,194,196,198,202,204,206,210,212,214,218,220,222,226,228,230,234,236,238,242,244,246,250,252,254};
        
        int b[ 256] = {0,6,12,16,22,26,32,36,42,46,52,56,62,68,72,78,82,88,92,98,102,108,112,118,122,128,134,138,144,148,154,158,164,168,174,178,184,188,194,200,204,210,214,220,224,230,234,240,244,250,252,250,246,244,240,238,234,232,230,226,224,220,218,214,212,210,206,204,200,198,194,192,190,186,184,180,178,174,172,170,166,164,160,158,154,152,150,146,144,140,138,134,132,130,126,124,120,118,114,112,110,106,104,100,98,94,92,90,86,84,80,78,74,72,70,66,64,60,58,54,52,50,46,44,40,38,34,32,30,26,24,20,18,14,12,10,6,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,14,28,42,56,68,82,96,110,124,136,150,164,178,190};
        
		NSMutableArray		*rArray = [NSMutableArray array];
		NSMutableArray		*gArray = [NSMutableArray array];
		NSMutableArray		*bArray = [NSMutableArray array];
		for( i = 0; i < 256; i++)
        {
			[bArray addObject: [NSNumber numberWithLong: r[ i]]];
			[gArray addObject: [NSNumber numberWithLong: g[ i]]];
			[rArray addObject: [NSNumber numberWithLong: b[ i]]];
		}
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray array], *points = [NSMutableArray array];
		[points addObject:[NSNumber numberWithLong: 0]];
		[points addObject:[NSNumber numberWithLong: 255]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], nil]];
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
        
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"Perfusion"];
	}
	
	#ifdef OSIRIX_VIEWER
	[DefaultsOsiriX addCLUT: @"VR Muscles-Bones" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"VR Bones" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"VR Red Vessels" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"BlackBody" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Flow" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"GEcolor" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Spectrum" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"NIH" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"HotIron" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"GrayRainbow" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"UCLA" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Stern" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Ratio" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Rainbow3" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Rainbow2" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Rainbow" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"ired" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Hue1" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"Hue2" dictionary: clutValues];		
	[DefaultsOsiriX addCLUT: @"HotMetal" dictionary: clutValues];	
	[DefaultsOsiriX addCLUT: @"HotGreen" dictionary: clutValues];	
	[DefaultsOsiriX addCLUT: @"Jet" dictionary: clutValues];
    [DefaultsOsiriX addCLUT: @"PPU Inferno" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"PPU Magma" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"PPU Plasma" dictionary: clutValues];
	[DefaultsOsiriX addCLUT: @"PPU Viridis" dictionary: clutValues];
	
	[defaultValues setObject: clutValues forKey: @"CLUT"];
	#endif
	
	// ** PREFERENCES - SERVERS
	
	NSMutableArray *serversValues = [NSMutableArray array];
	
	NSMutableDictionary *aServer = [[NSMutableDictionary alloc] init];
    [aServer setObject:@"1" forKey:@"Activated"];
	[aServer setObject:@"127.0.0.1" forKey: @"Address"];
	[aServer setObject:@"Horos" forKey: @"AETitle"];
	[aServer setObject:@"4444" forKey: @"Port"];
	[aServer setObject:[NSNumber numberWithInt:0] forKey:@"TransferSyntax"];
	[aServer setObject:NSLocalizedString(@"This is an example", nil) forKey:@"Description"];
	
	[serversValues addObject:aServer];
	[aServer release];
	
	[defaultValues setObject:serversValues forKey:@"SERVERS"];
	
	serversValues = [NSMutableArray array];
	[defaultValues setObject:serversValues forKey:@"OSIRIXSERVERS"];
	
	//routing calendars
	[defaultValues setObject:[NSMutableArray arrayWithObject:@"Osirix"] forKey:@"ROUTING CALENDARS"];
	
	// ** AETITLE
	if( [defaultValues objectForKey:@"AETITLE"] == nil)
	{
		#ifdef OSIRIX_VIEWER
		char s[_POSIX_HOST_NAME_MAX+1];
		gethostname(s,_POSIX_HOST_NAME_MAX);
		NSString *c = [NSString stringWithUTF8String:s];
		NSRange range = [c rangeOfString: @"."];
		if( range.location != NSNotFound) c = [c substringToIndex: range.location];
	
		if( [c length] > 16)
			c = [c substringToIndex: 16];
			
		[defaultValues setObject: c forKey:@"AETITLE"];
		#endif
	}
    
    if( [defaultValues objectForKey:@"AETITLE"] == nil)
        [defaultValues setObject:@"OSIRIX" forKey:@"AETITLE"];
    
	[defaultValues setObject:@"11112" forKey:@"AEPORT"];

	[defaultValues setObject:@"1" forKey:@"points3DcolorRed"];
	[defaultValues setObject:@"0" forKey:@"points3DcolorGreen"];
	[defaultValues setObject:@"0" forKey:@"points3DcolorBlue"];
	[defaultValues setObject:@"1" forKey:@"points3DcolorAlpha"];
	[defaultValues setObject:@"1" forKey:@"MagneticWindows"];
	[defaultValues setObject:@"0" forKey:@"MPR2DViewsPosition"];
	
	[defaultValues setObject:@"1" forKey:@"StoreThumbnailsInDB"];
	[defaultValues setObject:@"1" forKey:@"DisplayDICOMOverlays"];
	[defaultValues setObject:@"0" forKey:@"ALLOWDICOMEDITING"];
	[defaultValues setObject:@"/~Documents/FolderToBurn" forKey:@"SupplementaryBurnPath"];
    
	NSMutableArray *presets = [NSMutableArray array];
	NSDictionary	*shading;
	
	shading = [NSMutableDictionary dictionary];
	[shading setValue: @"Default" forKey: @"name"];
	[shading setValue: @"0.15" forKey: @"ambient"];
	[shading setValue: @"0.9" forKey: @"diffuse"];
	[shading setValue: @"0.3" forKey: @"specular"];
	[shading setValue: @"15" forKey: @"specularPower"];
	[presets addObject: shading];
	
	shading = [NSMutableDictionary dictionary];
	[shading setValue: @"Glossy Vascular" forKey: @"name"];
	[shading setValue: @"0.15" forKey: @"ambient"];
	[shading setValue: @"0.28" forKey: @"diffuse"];
	[shading setValue: @"1.42" forKey: @"specular"];
	[shading setValue: @"50" forKey: @"specularPower"];
	[presets addObject: shading];
	
	shading = [NSMutableDictionary dictionary];
	[shading setValue: @"Glossy Bone" forKey: @"name"];
	[shading setValue: @"0.15" forKey: @"ambient"];
	[shading setValue: @"0.24" forKey: @"diffuse"];
	[shading setValue: @"1.17" forKey: @"specular"];
	[shading setValue: @"6.98" forKey: @"specularPower"];
	[presets addObject: shading];
	
	shading = [NSMutableDictionary dictionary];
	[shading setValue: @"Endoscopy" forKey: @"name"];
	[shading setValue: @"0.12" forKey: @"ambient"];
	[shading setValue: @"0.64" forKey: @"diffuse"];
	[shading setValue: @"0.73" forKey: @"specular"];
	[shading setValue: @"50" forKey: @"specularPower"];
	[presets addObject: shading];
	
	[defaultValues setObject:presets forKey:@"shadingsPresets"];
	[defaultValues setObject:@"0" forKey:@"UseDelaunayFor3DRoi"];
	[defaultValues setObject:@"1" forKey:@"EJECTCDDVD"];
	[defaultValues setObject:@"1" forKey:@"automaticWorkspaceLoad"];
	[defaultValues setObject:@"1" forKey:@"automaticWorkspaceSave"];
	[defaultValues setObject:@"1" forKey:@"includeAllTiledViews"];
	[defaultValues setObject:@"0" forKey:@"AUTOCLEANINGDATE"];
	[defaultValues setObject:@"0" forKey:@"AUTOCLEANINGDATEPRODUCED"];
	[defaultValues setObject:@"0" forKey:@"AUTOCLEANINGDATEOPENED"];
	[defaultValues setObject:@"0" forKey:@"IndependentCRWLWW"];
	[defaultValues setObject:@"90" forKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"];
	[defaultValues setObject:@"90" forKey:@"AUTOCLEANINGDATEOPENEDDAYS"];
	[defaultValues setObject:@"1" forKey:@"SEPARATECARDIAC4D"];
	[defaultValues setObject:@"0" forKey:@"DEFAULTPETFUSION"];
	[defaultValues setObject:@"0" forKey:@"DEFAULTPETWLWW"];
	[defaultValues setObject:@"0" forKey:@"PETWLWWFROM"];
	[defaultValues setObject:@"100" forKey:@"PETWLWWTO"];
	[defaultValues setObject:@"0" forKey:@"PETWLWWFROMSUV"];
	[defaultValues setObject:@"6" forKey:@"PETWLWWTOSUV"];
	[defaultValues setObject:@"0" forKey:@"EXPORTMATRIXFOR3D"];
	[defaultValues setObject:@"0" forKey:@"ROITEXTNAMEONLY"];
	[defaultValues setObject:@"0" forKey:@"DEFAULTLEFTTOOL"];	// WL TOOL
	[defaultValues setObject:@"2" forKey:@"DEFAULTRIGHTTOOL"];	// ZOOM TOOL
	[defaultValues setObject:@"1" forKey:@"AUTOCLEANINGSPACE"];
//	[defaultValues setObject:@"1" forKey:@"AUTOCLEANINGSPACEPRODUCED"];
//	[defaultValues setObject:@"1" forKey:@"AUTOCLEANINGSPACEOPENED"];
    [defaultValues setObject:@"2" forKey:@"AutocleanSpaceMode"];
	[defaultValues setObject:@"1024" forKey:@"AUTOCLEANINGSPACESIZE"];
	[defaultValues setObject:@"0" forKey:@"PETMinimumValue"];
	[defaultValues setObject:@"1" forKey:@"PETWindowingMode"];
	[defaultValues setObject:@"1" forKey:@"PETOpacityTable"];
	[defaultValues setObject:@"Logarithmic Table" forKey: @"PET Default Opacity Table"];
	[defaultValues setObject:@"0" forKey: @"OpacityTableNM"];
	[defaultValues setObject:@"B/W Inverse" forKey:@"PET Clut Mode"];
	[defaultValues setObject:@"PET" forKey: @"PET Default CLUT"];
	[defaultValues setObject:@"PET" forKey: @"PET Blending CLUT"];
	[defaultValues setObject:@"0" forKey:@"NETWORKLOGS"];
	[defaultValues setObject:@"+xi" forKey:@"AETransferSyntax"];
	[defaultValues setObject:@"" forKey:@"STORESCPEXTRA"];
	[defaultValues setObject:@"0" forKey:@"ROITEXTIFSELECTED"];
	[defaultValues setObject:@"1" forKey: @"STORESCP"];
	[defaultValues setObject:@"1" forKey: @"DCMPRINT_Interval"];
	[defaultValues setObject:@"3" forKey: @"LISTENERCHECKINTERVAL"];
	[defaultValues setObject:@"1" forKey: @"AUTOTILING"];
	[defaultValues setObject:@"1" forKey: @"USEALWAYSTOOLBARPANEL2"];
	[defaultValues setObject:@"1" forKey: @"SquareWindowForPrinting"];
	[defaultValues setObject:@"Softw Tissue CT" forKey: @"LAST_3D_PRESET"];
	[defaultValues setObject:@"0" forKey:@"HIDEPATIENTNAME"];
	[defaultValues setObject:@"1" forKey:@"onlyDICOM"];
	[defaultValues setObject:@"0" forKey:@"CheckForMultipleVolumesInSeries"];
	[defaultValues setObject:@"3000" forKey:@"MAXWindowSize"];
	[defaultValues setObject:@"1" forKey:@"ScreenCaptureSmartCropping"];
	[defaultValues setObject:@"1" forKey:@"checkForUpdatesPlugins"];
    [defaultValues setObject:@"0" forKey:@"DoNotDeleteCrashingPlugins"];
	[defaultValues setObject:@"1" forKey:@"magnifyingLens"];
	[defaultValues setObject:@"12" forKey:@"LabelFONTSIZE"];
	[defaultValues setObject:@"Geneva" forKey:@"LabelFONTNAME"];
	[defaultValues setObject:@"1" forKey:@"EmptyNameForNewROIs"];
	[defaultValues setObject:@"1" forKey:@"nextSeriesToAllViewers"];
	[defaultValues setObject:@"1" forKey:@"dontDeleteStudiesWithComments"];
	[defaultValues setObject:@"1" forKey:@"displaySamePatientWithColorBackground"];
	[defaultValues setObject:@"Exported Series" forKey:@"default2DViewerSeriesName"];
	[defaultValues setObject:@"10000" forKey:@"DefaultFolderSizeForDB"];
	[defaultValues setObject:@"10000" forKey:@"maxNumberOfFilesForCheckIncoming"];
	[defaultValues setObject:@"0" forKey:@"useSoundexForName"];
	[defaultValues setObject:@"1" forKey:@"printAt100%Minimum"];
	[defaultValues setObject:@"1" forKey:@"allowSmartCropping"];
	[defaultValues setObject:@"1" forKey:@"useDCMTKForAnonymization"];
	[defaultValues setObject:@"1" forKey:@"useDCMTKForDicomExport"];
    [defaultValues setObject:@"1" forKey:@"SupportQRModalitiesinStudy"];
    [defaultValues setObject:@"1" forKey:@"CapitalizedString"];
    [defaultValues setObject:@"1" forKey:@"hasFULL32BITPIPELINE"];
    [defaultValues setObject:@"1" forKey:@"FULL32BITPIPELINE"];
    [defaultValues setObject:@"4" forKey:@"MAXNUMBEROF32BITVIEWERS"];
    [defaultValues setObject:@"1" forKey:@"CFINDCommentsAndStatusSupport"];
    [defaultValues setObject:@"1" forKey:@"restorePasswordWebServer"];
    [defaultValues setObject:@"comment" forKey:@"commentFieldForAutoFill"];
    [defaultValues setObject:[NSString stringWithFormat:@"%d", syncroRatio] forKey:@"DefaultModeForNonVolumicSeries"];
	[defaultValues setObject:@"2" forKey:@"drawerState"]; // NSDrawerOpenState
    /*
    if( [[NSProcessInfo processInfo] processorCount] >= 4)
        [defaultValues setObject:@"2.0" forKey:@"superSampling"];
    else
        [defaultValues setObject:@"1.4" forKey:@"superSampling"];
    */
     
    [defaultValues setObject:@"3.5" forKey:@"superSampling"];
    float superSampling = [[NSUserDefaults standardUserDefaults] floatForKey: @"superSampling"];
    if (superSampling < [[defaultValues objectForKey:@"superSampling"] floatValue])
    {
        superSampling = [[defaultValues objectForKey:@"superSampling"] floatValue];
        [[NSUserDefaults standardUserDefaults] setFloat:superSampling forKey:@"superSampling"];
    }
    
	
    [defaultValues setObject:@"200" forKey: @"FetchLimitForWebPortal"];
    
	// ** DELETEFILELISTENER
	[defaultValues setObject:@"1" forKey:@"DELETEFILELISTENER"];
    
    [defaultValues setObject:@"1" forKey:@"UseFloatingThumbnailsList"];
    [defaultValues setObject:@"0.2" forKey: @"MinimumTitledGantryTolerance"]; // in degrees
    
//
	long	pVRAM;
//
	pVRAM = [self vramSize]  / (1024L * 1024L);
//	NSLog(@"VRAM: %d MB", pVRAM);
	
	// ** MAX3DTEXTURE
	// ** MAX3DTEXTURESHADING
	if( pVRAM >= 512)
	{	
		[defaultValues setObject:@"256" forKey:@"MAX3DTEXTURE"];
		[defaultValues setObject:@"128" forKey:@"MAX3DTEXTURESHADING"];
	}
	else if( pVRAM >= 256)
	{
		[defaultValues setObject:@"128" forKey:@"MAX3DTEXTURE"];
		[defaultValues setObject:@"64" forKey:@"MAX3DTEXTURESHADING"];
	}
	else if( pVRAM >= 128)
	{
		[defaultValues setObject:@"128" forKey:@"MAX3DTEXTURE"];
		[defaultValues setObject:@"32" forKey:@"MAX3DTEXTURESHADING"];
	}
	else
	{
		[defaultValues setObject:@"32" forKey:@"MAX3DTEXTURE"];
		[defaultValues setObject:@"32" forKey:@"MAX3DTEXTURESHADING"];
	}
			
	// ** BESTRENDERING
	#if __ppc__
	[defaultValues setObject:@"1.6" forKey:@"BESTRENDERING"];
	#else
	[defaultValues setObject:@"1.2" forKey:@"BESTRENDERING"];
	#endif

    [defaultValues setObject:@"120" forKey:@"DatabaseRefreshInterval"];
    
    [defaultValues setObject:@"1" forKey:@"ShowAlbumOnlyIfNotEmpty"];
	[defaultValues setObject:@"0" forKey:@"UseFrameofReferenceUID"];
	[defaultValues setObject:@"1" forKey:@"savedCommentsAndStatusInDICOMFiles"];
	[defaultValues setObject:@"1" forKey:@"CommentsFromDICOMFiles"];
	[defaultValues setObject:@"1" forKey:@"OPENVIEWER"];
	[defaultValues setObject: @"0" forKey: @"ConvertPETtoSUVautomatically"];
	[defaultValues setObject: @"0" forKey: @"SURVEYDONE3"];
	[defaultValues setObject: @"20" forKey: @"stackThickness"];
	[defaultValues setObject: @"20" forKey: @"stackThicknessOrthoMPR"];
	[defaultValues setObject:@"0" forKey:@"AUTOROUTINGACTIVATED"];
	[defaultValues setObject:@"0" forKey:@"httpXMLRPCServer"];
	[defaultValues setObject:@"8080" forKey:@"httpXMLRPCServerPort"];
	[defaultValues setObject:@"0" forKey:OsirixWebPortalEnabledDefaultsKey];
	[defaultValues setObject:@"3333" forKey:OsirixWebPortalPortNumberDefaultsKey];
	[defaultValues setObject:@"1" forKey:@"StrechWindows"];
	[defaultValues setObject:@"0" forKey:@"ROUTINGACTIVATED"];
	[defaultValues setObject: @"0" forKey: @"AUTOHIDEMATRIX"];
	[defaultValues setObject: @"0" forKey: @"AutoPlayAnimation"];
	[defaultValues setObject: @"1" forKey: @"KeepStudiesOfSamePatientTogether"];
	[defaultValues setObject: @"1" forKey: @"KeepStudiesOfSamePatientTogetherAndGrouped"];
	[defaultValues setObject: @"1" forKey: @"USEPAPYRUSDCMPIX4"];
	[defaultValues setObject: @"2" forKey: @"TOOLKITPARSER4"];	// 0:DCM Framework 1:Papyrus 2:DCMTK
	[defaultValues setObject: @"1" forKey: @"PREFERPAPYRUSFORCD"];
    [defaultValues setObject: @"20" forKey: @"maximumNumberOfConcurrentDICOMAssociations"];
    [defaultValues setObject: @"10000" forKey: @"maximumNumberOfCFindObjects"];
    [defaultValues setObject: @"0" forKey: @"TryIMAGELevelDICOMRetrieveIfLocalImages"];
	[defaultValues setObject: @"1" forKey: @"SingleProcessMultiThreadedListener"];
	[defaultValues setObject: @"0" forKey: @"AUTHENTICATION"];
	[defaultValues setObject: @"1" forKey: @"CheckHorosUpdates"];
	[defaultValues setObject: @"-1" forKey:@"MOUNT"];
	[defaultValues setObject: @"1" forKey:@"CDDVDEjectAfterAutoCopy"];
//	[defaultValues setObject: @"1" forKey:@"UNMOUNT"];
	[defaultValues setObject: @"1" forKey: @"UseDICOMDIRFileCD"];
	[defaultValues setObject: @"1" forKey: @"SAVEROIS"];
	[defaultValues setObject: @"1" forKey: @"NOLOCALIZER"];
	[defaultValues setObject: @"0" forKey: @"TRANSITIONEFFECT"];
	[defaultValues setObject: @"0" forKey:@"NOINTERPOLATION"];
    [defaultValues setObject: @"0" forKey:@"MultipleAssociationsRetrieve"];
    [defaultValues setObject: @"3" forKey:@"NoOfMultipleAssociationsRetrieve"];
	[defaultValues setObject: @"0" forKey: @"WINDOWSIZEVIEWER"];
	[defaultValues setObject: @"1" forKey: @"UseOpenJpegForJPEG2000"];
//	[defaultValues setObject: @"0" forKey: @"UseKDUForJPEG2000"];
	[defaultValues setObject: @"0" forKey: @"KeepStudiesTogetherOnSameScreen"];
	[defaultValues setObject: @"1" forKey: @"ShowErrorMessagesForAutorouting"];
	[defaultValues setObject: @"1" forKey: @"SAMESTUDY"];
	[defaultValues setObject: @"0" forKey: @"recomputePatientUID"];
	[defaultValues setObject: @"1" forKey: @"ReserveScreenForDB"];
	[defaultValues setObject: @"1" forKey: @"notificationsEmailsInterval"];
    [defaultValues setObject: @"1" forKey: @"automaticallyRetrievePartialStudies"];
	NSDateFormatter	*dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateStyle: NSDateFormatterShortStyle];
	[defaultValues setObject: [dateFormat dateFormat] forKey:@"DBDateOfBirthFormat2"];
	[dateFormat setDateStyle: NSDateFormatterShortStyle];
	[dateFormat setTimeStyle: NSDateFormatterShortStyle];
	[defaultValues setObject: [dateFormat dateFormat] forKey:@"DBDateFormat2"];
	
	NSDictionary *defaultAnnotations = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"AnnotationsDefault" ofType:@"plist"]];
	if( defaultAnnotations)
		[defaultValues setObject: defaultAnnotations forKey:@"CUSTOM_IMAGE_ANNOTATIONS"];
	[defaultValues setObject:@"0" forKey:@"SERIESORDER"];
	[defaultValues setObject:@"40" forKey:@"DICOMTimeout"];
    [defaultValues setObject:@"10" forKey:@"DICOMConnectionTimeout"];
	[defaultValues setObject:@"1" forKey:@"NSWindowsSetFrameAnimate"];
	[defaultValues setObject: @"0" forKey: @"TRANSITIONTYPE"];
	#ifndef OSIRIX_LIGHT
	[defaultValues setObject: @"1" forKey: @"COPYDATABASE"];
	#else
	[defaultValues setObject: @"0" forKey: @"COPYDATABASE"];
	#endif
	[defaultValues setObject: @"0" forKey: @"SUVCONVERSION"];
	[defaultValues setObject: @"1" forKey: @"NoImageTilingInFullscreen"];
	[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGCOMMENTS"];
	[defaultValues setObject: @"" forKey: @"AUTOCLEANINGCOMMENTSTEXT"];
	[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGDONTCONTAIN"];
	[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGDELETEORIGINAL"];
	[defaultValues setObject: @"0" forKey: @"COMMENTSAUTOFILL"];
	[defaultValues setObject: @"http://list.dicom.dcm/DICOMNodes.plist" forKey: @"syncDICOMNodesURL"];
	[defaultValues setObject: @"http://list.dicom.dcm/OsiriXDB.plist" forKey: @"syncOsiriXDBURL"];
	[defaultValues setObject: @"1" forKey: @"BurnOsirixApplication"];
	[defaultValues setObject: @"1" forKey: @"BurnHtml"];
	[defaultValues setObject: @"0" forKey: @"BurnSupplementaryFolder"];
	[defaultValues setObject: @"1" forKey: @"splineForROI"];
	[defaultValues setObject:@"0" forKey:@"ThreeDViewerOnAnotherScreen"];
	[defaultValues setObject:@"512" forKey:@"SOFTWAREINTERPOLATION_MAX"];
	[defaultValues setObject:@"1" forKey:@"SOFTWAREINTERPOLATION"];
	[defaultValues setObject:@"0" forKey:@"DATABASEINDEX"];
	[defaultValues setObject: @"2" forKey: @"ANNOTATIONS"];
	[defaultValues setObject: @"0" forKey :@"CLUTBARS"];
	[defaultValues setObject: @"60" forKey: @"temporaryUserDuration"];
	[defaultValues setObject:@"3" forKey:@"COPYDATABASEMODE"];
	[defaultValues setObject:@"7" forKey:@"LOGCLEANINGDAYS"];
	[defaultValues setObject:@"1" forKey:@"AUTOMATIC FUSE"];
	[defaultValues setObject:@"0" forKey:@"DEFAULT_DATABASELOCATION"];
	[defaultValues setObject:@"" forKey:@"DEFAULT_DATABASELOCATIONURL"];
	[defaultValues setObject: @"0" forKey: @"DATABASELOCATION"];
	[defaultValues setObject: @"" forKey: @"DATABASELOCATIONURL"];
	[defaultValues setObject: @"Geneva" forKey: @"FONTNAME"];
	[defaultValues setObject: @"1" forKey: @"DICOMSENDALLOWED"];
	[defaultValues setObject: @"14.0" forKey: @"FONTSIZE"];
	[defaultValues setObject: @"2" forKey: @"REPORTSMODE"];
	[defaultValues setObject: URL_HOROS_VIEWER@"/internet.dcm" forKey: @"LASTURL"];
	[defaultValues setObject: @"0" forKey: @"MAPPERMODEVR"];
	[defaultValues setObject: @"1" forKey: @"STARTCOUNT"];
	[defaultValues setObject: @"1" forKey: @"editingLevel"];
	[defaultValues setObject: @"1" forKey: @"publishDICOMBonjour"];
	[defaultValues setObject: @"1" forKey: @"searchDICOMBonjour"];
	[defaultValues setObject: @"1" forKey: @"autorotate3D"];
	[defaultValues setObject: @"1" forKey: @"preferencesModificationsEnabled"];
	[defaultValues setObject: @"0" forKey: @"Compression Mode for Export"];
	[defaultValues setObject: @"0" forKey: @"ORIGINALSIZE"];
	[defaultValues setObject: @"1" forKey: @"Scroll Wheel Reversed"];
	[defaultValues setObject: @"Horos" forKey: @"ALBUMNAME"];
	[defaultValues setObject: @"1" forKey: @"DisplayCrossReferenceLines"];
	[defaultValues setObject: @"0" forKey: @"AlwaysScaleToFit"];
	[defaultValues setObject:@"0" forKey: @"VRDefaultViewSize"];
	[defaultValues setObject:@"0" forKey: @"RunListenerOnlyIfActive"];
	[defaultValues setObject:@"0" forKey: @"UseShutter"];
	[defaultValues setObject:@"1" forKey: @"UseVOILUT"];
	[defaultValues setObject:@"0" forKey: @"replaceAnonymize"];
	[defaultValues setObject:@"0" forKey: @"anonymizedBeforeBurning"];
	[defaultValues setObject:@"0" forKey: @"ZoomWithHorizonScroll"];
	[defaultValues setObject:@"1" forKey: @"dcmExportFormat"];
    [defaultValues setObject:@"0" forKey: @"CFINDBodyPartExaminedSupport"];
	[defaultValues setObject:@"2" forKey: @"preferredSyntaxForIncoming"]; // 2 = EXS_LittleEndianExplicit See dcmqrsrv.mm
	[defaultValues setObject:@"ISO_IR 100" forKey: @"STRINGENCODING"];
	[defaultValues setObject:@"1" forKey:@"syncPreviewList"];
	[defaultValues setObject:@"1" forKey:@"openPDFwithPreview"];
	[defaultValues setObject:@"1" forKey:@"ROIArrowThickness"];
	[defaultValues setObject:@"1" forKey:@"loopScrollWheel"];
	[defaultValues setObject:@"1" forKey:@"UseJPEGColorSpace"];
	[defaultValues setObject:@"0" forKey:@"displayCobbAngle"];
	[defaultValues setObject:@"0" forKey:@"onlyDisplayImagesOfSamePatient"];
	[defaultValues setObject:@"1" forKey:@"activateCGETSCP"];
    [defaultValues setObject:@"1" forKey:@"activateCFINDSCP"];
	[defaultValues setObject:@"0" forKey:@"notificationsEmails"];
	[defaultValues setObject:@"0" forKey:@"validateFilesBeforeImporting"];
	[defaultValues setObject:@"10" forKey:@"defaultFrameRate"];
    [defaultValues setObject:@"10" forKey:@"defaultMovieRate"];
	[defaultValues setObject:@"10" forKey:@"quicktimeExportRateValue"];
    [defaultValues setObject:AVVideoCodecJPEG forKey:@"selectedMenuAVFoundationExport"];
	[defaultValues setObject:@"0" forKey:@"32bitDICOMAreAlwaysIntegers"];
	[defaultValues setObject:@"1" forKey:@"archiveReportsAndAnnotationsAsDICOMSR"];
	[defaultValues setObject:@"1" forKey:@"SelectWindowScrollWheel"];
	[defaultValues setObject:@"1" forKey:@"useDCMTKForJP2K"];
	[defaultValues setObject:@"1" forKey:@"MouseClickZoomCentered"];
	[defaultValues setObject:@"1" forKey:@"exportOrientationIn3DExport"];
	[defaultValues setObject:@"600" forKey:@"WADOTimeout"];
	[defaultValues setObject:@"10" forKey:@"WADOMaximumConcurrentDownloads"];
	[defaultValues setObject:@"1" forKey:@"autoSelectSourceCDDVD"];
	[defaultValues setObject:@"1" forKey:@"ScanDiskIfDICOMDIRZero"];
	[defaultValues setObject:@"1" forKey:@"WebServerTagUploadedStudiesWithUsername"];
    [defaultValues setObject:@"20" forKey:@"MaxNumberOfRetrieveForAutoQR"];
    [defaultValues setObject:@"1800" forKey:@"WebServerTimeOut"]; // = 30*60 = 30 min 120*60 = 2 hours
    [defaultValues setObject:@"400" forKey:@"MaxNumberOfFramesForWebPortalMovies"];
    [defaultValues setObject:@"880" forKey:@"WebServerMaxWidthForMovie"];
    [defaultValues setObject:@"880" forKey:@"WebServerMaxWidthForStillImage"];
    [defaultValues setObject:@"512" forKey:@"WebServerMinWidthForMovie"];
    [defaultValues setObject:@"1" forKey:@"WebServerUseMailAppForEmails"];
    [defaultValues setObject:@"1" forKey:@"DICOMQueryAllowFutureQuery"];
    [defaultValues setObject:@"1" forKey:@"SeriesListVisible"];
    [defaultValues setObject:@"1" forKey:@"RescaleDuring3DResampling"];
    [defaultValues setObject:@"1" forKey:@"listPODComparativesIn2DViewer"];
    [defaultValues setObject:@"1" forKey:@"OVERFLOWLINES"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_name"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_id"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_accession_number"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_birthdate"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_description"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_referring_physician"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_comments"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_institution"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_status"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_study_date"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_modality"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_blank_query"];
    [defaultValues setObject:@"1" forKey:@"allow_qr_custom_dicom_field"];
    [defaultValues setObject:@"2" forKey:@"MaxConcurrentPODRetrieves"];
	[defaultValues setObject:@"1" forKey:@"QRRemoveDuplicateEntries"];
    [defaultValues setObject:@"1" forKey:@"tileWindowsOrderByStudyDate"];
    [defaultValues setObject:@"1" forKey:@"AllowPluginAuthenticationForWebPortal"];
	[defaultValues setObject:@"1" forKey:@"UsePatientBirthDateForUID"];
    [defaultValues setObject:@"1" forKey:@"UsePatientIDForUID"];
	[defaultValues setObject:@"1" forKey:@"UsePatientNameForUID"];
    [defaultValues setObject:@"1" forKey:@"putSrcAETitleInSourceApplicationEntityTitle"];
    [defaultValues setObject:@"0" forKey:@"putDstAETitleInPrivateInformationCreatorUID"];
    [defaultValues setObject:@"1" forKey:@"wadoRequestRequireValidToken"];
    [defaultValues setObject:@"1024" forKey: @"DicomImageScreenCaptureWidth"];
    [defaultValues setObject:@"1024" forKey: @"DicomImageScreenCaptureHeight"];
    [defaultValues setObject:@"30" forKey: @"WebPortalMaximumNumberOfRecentStudies"];
    [defaultValues setObject:@"10" forKey: @"WebPortalMaximumNumberOfDaysForRecentStudies"];
    [defaultValues setObject:@"2" forKey:@"yearOldDatabaseDisplay"];
    [defaultValues setObject:@"1" forKey:@"SendControllerConcurrentThreads"];
    [defaultValues setObject:@"4" forKey:@"MaximumSendControllerConcurrentThreads"];
    [defaultValues setObject:@"4" forKey:@"MaximumSendGlobalControllerConcurrentThreads"];
    [defaultValues setObject:@"1" forKey:@"COMMENTSAUTOFILLStudyLevel"];
    [defaultValues setObject:@"1" forKey:@"ROIDrawPlainEdge"];
    [defaultValues setObject:@"1" forKey:@"PACSOnDemandForSearchField"];
    [defaultValues setObject:@"1" forKey:@"CloseAllWindowsBeforeXMLRPCOpen"];
    
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeries"];
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeriesForCR"];
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeriesForMG"];
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeriesForRF"];
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeriesForDR"];
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeriesForDX"];
    [defaultValues setObject:@"1" forKey:@"scrollThroughSeriesForOT"];
    
    [defaultValues setObject:@"0.01" forKey:@"PARALLELPLANETOLERANCE"]; //It's radians: 0.01 = about 0.5 degree
    [defaultValues setObject:@"0.1" forKey:@"PARALLELPLANETOLERANCE-Sync"];
    
    [defaultValues setObject:@"1" forKey:@"bringOsiriXToFrontAfterReceivingMessage"];
    
	#ifdef MACAPPSTORE
	[defaultValues setObject:@"1" forKey:@"MACAPPSTORE"];
	#else
	[defaultValues setObject:@"0" forKey:@"MACAPPSTORE"];
	#endif
	
	[defaultValues setObject: [NSArray arrayWithObjects: [DCMAbstractSyntaxUID MRSpectroscopyStorage], nil] forKey:@"additionalDisplayedStorageSOPClassUIDArray"];
	
	
	// ** ROI Default
	[defaultValues setObject:[NSNumber numberWithFloat: 2] forKey:@"ROIThickness"];
	[defaultValues setObject:[NSNumber numberWithFloat: 3] forKey:@"ROITextThickness"];
	[defaultValues setObject:[NSNumber numberWithFloat: 1.0] forKey:@"ROIOpacity"];
	[defaultValues setObject:[NSNumber numberWithFloat: 0.3 * 65535.] forKey:@"ROIColorR"];
	[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROIColorG"];
	[defaultValues setObject:[NSNumber numberWithFloat: 0.3 * 65535.] forKey:@"ROIColorB"];
	[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROITextColorR"];
	[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROITextColorG"];
	[defaultValues setObject:[NSNumber numberWithFloat: 0.0 * 65535.] forKey:@"ROITextColorB"];
	[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROIRegionColorR"];
	[defaultValues setObject:[NSNumber numberWithFloat: 0.0 * 65535.] forKey:@"ROIRegionColorG"];
	[defaultValues setObject:[NSNumber numberWithFloat: 0.0 * 65535.] forKey:@"ROIRegionColorB"];
	[defaultValues setObject:[NSNumber numberWithFloat: 0.5] forKey:@"ROIRegionOpacity"];
	[defaultValues setObject:[NSNumber numberWithFloat: 5] forKey:@"ROIRegionThickness"];
	
	// **HANGING PROTOCOLS
	NSMutableDictionary *defaultHangingProtocols = [NSMutableDictionary dictionary];
	NSArray *modalities = [NSArray arrayWithObjects:NSLocalizedString(@"CR", nil), NSLocalizedString(@"CT", nil), NSLocalizedString(@"DX", nil), NSLocalizedString(@"ES", nil), NSLocalizedString(@"MG", nil), NSLocalizedString(@"MR", nil), NSLocalizedString(@"NM", nil), NSLocalizedString(@"OT", nil),NSLocalizedString(@"PT", nil),NSLocalizedString(@"RF", nil),NSLocalizedString(@"SC", nil),NSLocalizedString(@"US", nil),NSLocalizedString(@"XA", nil), nil];
    
	for (NSString *modality in modalities)
    {
		NSMutableDictionary *protocol = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects: NSLocalizedString( @"Default", nil), [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], nil] forKeys:[NSArray arrayWithObjects:@"Study Description", @"WindowsTiling", @"ImageTiling", nil]];
        
        if( [modality isEqualToString: @"MG"])
        {
            [protocol setObject: @5 forKey: @"WindowsTiling"]; // 2 x 2
            [protocol setObject: @"R CC,L CC,R MLO,L MLO" forKey: @"SeriesOrder"];
            [protocol setObject: [NSNumber numberWithInt: 4] forKey: @"NumberOfSeriesPerComparative"];
        }
		[defaultHangingProtocols setObject: [NSMutableArray arrayWithObject:protocol] forKey:modality];
	}
	[defaultValues setObject: defaultHangingProtocols forKey: @"HANGINGPROTOCOLS"];
	
	// ** COLUMNSDATABASE
	NSMutableDictionary *defaultDATABASECOLUMNS = [NSMutableDictionary dictionary];
	[defaultValues setObject: defaultDATABASECOLUMNS forKey: @"COLUMNSDATABASE"];
	
	// **
	[defaultValues setObject: @"20" forKey: @"MaxNumberOfRecentStudies"];
    
    [defaultValues setObject: @"1" forKey: @"noPropagateInSeriesForCR"];
    [defaultValues setObject: @"1" forKey: @"noPropagateInSeriesForDR"];
    [defaultValues setObject: @"1" forKey: @"noPropagateInSeriesForDX"];
    [defaultValues setObject: @"1" forKey: @"noPropagateInSeriesForRF"];
    [defaultValues setObject: @"1" forKey: @"noPropagateInSeriesForXA"];
    
	[defaultValues setObject: @"1" forKey: @"COPYSETTINGS"];
	[defaultValues setObject: @"1" forKey: @"USESTORESCP"];
	[defaultValues setObject: @"1" forKey: @"splitMultiEchoMR"];
	[defaultValues setObject: @"0" forKey: @"useSeriesDescription"];
	[defaultValues setObject: @"1" forKey: @"combineProjectionSeries"];
	[defaultValues setObject: @"1" forKey: @"combineProjectionSeriesMode"];
	[defaultValues setObject: @"0" forKey: @"ListenerCompressionSettings"];
	[defaultValues setObject: @"localizer,scout,survey,locator,tracker" forKey: @"NOLOCALIZER_Strings"];
	
	//hot key prefs
	NSMutableDictionary *hotkeys = [NSMutableDictionary dictionary];
	
	NSString *stringValue;
	NSArray *array = [NSArray arrayWithObjects:
						@"~",	//DefaultWWWLHotKeyAction
						@"0",	//FullDynamicWWWLHotKeyAction
						@"1",	//Preset1WWWLHotKeyAction
						@"2",	//Preset2WWWLHotKeyAction
						@"3",	//Preset3WWWLHotKeyAction
						@"4",	//Preset4WWWLHotKeyAction
						@"5",	//Preset5WWWLHotKeyAction
						@"6",	//Preset6WWWLHotKeyAction
						@"7",	//Preset7WWWLHotKeyAction
						@"8",	//Preset8WWWLHotKeyAction
						@"9",	//Preset9WWWLHotKeyAction
						@"v",	//FlipVerticalHotKeyAction
						@"h",	//FlipHorizontalHotKeyAction
						@"w",	//WWWLToolHotKeyAction
						@"m",	//MoveHotKeyAction
						@"z",	//ZoomHotKeyAction
						@"i",	//RotateHotKeyAction
						@"",	//ScrollHotKeyAction
						@"l",	//LengthHotKeyAction
						@"a",	//AngleHotKeyAction
						@"",	//RectangleHotKeyAction
						@"e",	//OvalHotKeyAction
						@"t",	//TextHotKeyAction
						@"q",	//ArrowHotKeyAction
						@"o",	//OpenPolygonHotKeyAction
						@"c",	//ClosedPolygonHotKeyAction
						@"d",	//PencilHotKeyAction
						@"p",	//ThreeDPointHotKeyAction
						@"b",	//PlainToolHotKeyAction
						@"x",	//BoneRemovalHotKeyAction
						@"[",	//Rotate3DHotKeyAction
						@"]",	//Camera3DotKeyAction
						@"\\",	//scissors3DHotKeyAction
						@"r",	//RepulsorHotKeyAction
						@"s",	//SelectorHotKeyAction
						@",",	//EmptyHotKeyAction
						@".",	//UnreadHotKeyAction
						@"/",	//ReviewedHotKeyAction
						@"\\",	//DictatedHotKeyAction
                        @"",	//ValidatedHotKeyAction
						@"y",	//OrthoMPRCrossTool
                      @"",	//Preset1OpacityLHotKeyAction
                      @"",	//Preset2OpacityLHotKeyAction
                      @"",	//Preset3OpacityLHotKeyAction
                      @"",	//Preset4OpacityLHotKeyAction
                      @"",	//Preset5OpacityLHotKeyAction
                      @"",	//Preset6OpacityLHotKeyAction
                      @"",	//Preset7OpacityLHotKeyAction
                      @"",	//Preset8OpacityLHotKeyAction
                      @"",	//Preset9OpacityLHotKeyAction
                      @"dbl-click",	//FullScreenAction
                      @"dbl-click + alt",	//Sync3DAction
                      @"dbl-click + cmd",	//SetKeyImageAction
						nil];						
	
	for( int x = 0; x < [array count]; x++)
	{
		stringValue = [array objectAtIndex:x];
		[hotkeys setObject:[NSNumber numberWithInt:x] forKey:stringValue];
//		[hotkeysModifiers setObject:[NSNumber numberWithInt:0] forKey:stringValue];
	}
	[defaultValues setObject:hotkeys forKey:@"HOTKEYS"];
	
	NSArray *compressionSettings = [NSArray arrayWithObjects: 
							[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", @"3", @"compression", @"1", @"quality", nil], 
							[NSDictionary dictionaryWithObjectsAndKeys: @"CR", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"CT", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"DX", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"ES", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"MG", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"MR", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"NM", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"OT", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"PT", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"RF", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"SC", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"US", @"modality", @"0", @"compression", @"1", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"XA", @"modality", @"0", @"compression", @"1", @"quality", nil],
							nil]; 
	
	[defaultValues setObject: @"512" forKey: @"CompressionResolutionLimit"];
	
	[defaultValues setObject: compressionSettings forKey:@"CompressionSettings"];
	
	NSArray *compressionSettingsLowRes = [NSArray arrayWithObjects: 
							[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", @"3", @"compression", @"0", @"quality", nil], 
							[NSDictionary dictionaryWithObjectsAndKeys: @"CR", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"CT", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"DX", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"ES", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"MG", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"MR", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"NM", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"OT", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"PT", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"RF", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"SC", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"US", @"modality", @"0", @"compression", @"0", @"quality", nil],
							[NSDictionary dictionaryWithObjectsAndKeys: @"XA", @"modality", @"0", @"compression", @"0", @"quality", nil],
							nil]; 
	
	[defaultValues setObject: compressionSettingsLowRes forKey:@"CompressionSettingsLowRes"];
	
	
	// Comparison Body Regions
//	NSArray *headRegions = [NSArray arrayWithObjects: 
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HEAD", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"BRAIN", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"FACE", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ORBIT", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ORBITS", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"IAC", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"PITUITARY", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"SINUS", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"MAXILLOFACIAL", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"TEMPORAL BONE", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"MANDIBLE", nil), @"region",
//									nil],
//								nil];
//								
//		NSArray *neckRegions = [NSArray arrayWithObjects: 
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"NECK", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CERVICAL", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CAROTID", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"THYROID", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"C SPINE", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"BRACHIAL", nil), @"region",
//									nil],
//								nil];
//								
//		NSArray *chestRegions = [NSArray arrayWithObjects: 
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CHEST", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"LUNG", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"THORAX", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"THORACIC", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"PULMONARY", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"MEDIASTINUM", nil), @"region",
//									[NSNumber numberWithBool:YES], @"isLeaf",
//									[NSNumber numberWithInt:0], @"count",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HEART", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CARDIAC", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"T SPINE", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"STERNUM", nil), @"region",
//									nil],
//								nil];
//								
//		NSArray *abdomenRegions = [NSArray arrayWithObjects: 
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ABDOMEN", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ABD", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"LIVER", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"PANCREAS", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"KIDNEY", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"RENAL", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ADRENAL", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"IVP", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"L SPINE", nil), @"region",
//									nil],
//								nil];
//								
//			NSArray *pelvisRegions = [NSArray arrayWithObjects: 
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"PELVIS", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"PELVIC", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"BLADDER", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"APPENDIX", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HIP", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HIPS", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"UTERUS", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"OVARY", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"OVARIES", nil), @"region",
//									nil],
//								[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"PROSTATE", nil), @"region",
//									nil],
//								nil];
//			
//			NSArray *thighRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"THIGH", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"FEMUR", nil), @"region",
//									nil],
//							nil];
//			NSArray *kneeRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"KNEE", nil), @"region",
//									nil],
//							nil];
//			NSArray *lowerLegRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"LOWER LEG", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"TIBIA", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"FIBULA", nil), @"region",
//									nil],
//							nil];
//			NSArray *footRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"FOOT", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ANKLE", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"TOE", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"TOES", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HEEL", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CALCANEUS", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"OS CALCIS", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"TALUS", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HALLUX", nil), @"region",
//									nil],
//							nil];
//							
//			NSArray *shoulderRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"SHOULDER", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CLAVICLE", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"AC JOINT", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ACROMIAL", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"SCAPULA", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"BICEPS", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ROTATOR CUFF", nil), @"region",
//									nil],
//							nil];
//			NSArray *armRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HUMERUS", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"UPPER ARM", nil), @"region",
//									nil],
//							nil];
//			NSArray *elbowRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ELBOW", nil), @"region",
//									nil],
//							nil];
//			NSArray *forearmRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"FOREARM", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"RADIUS", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"ULNA", nil), @"region",
//									nil],
//							nil];
//		
//			NSArray *handRegions = [NSArray arrayWithObjects:	
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"HAND", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"WRIST", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"THUMB", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"FINGER", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"CARPAL", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"NAVICULAR", nil), @"region",
//									nil],
//							[NSDictionary dictionaryWithObjectsAndKeys:
//									NSLocalizedString(@"SCAPHOID", nil), @"region",
//									nil],
//							nil];									
//												
//	
//	 NSDictionary *headRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"HEAD", nil), @"region",
//				headRegions, @"keywords",
//				nil];
//	NSDictionary *neckRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"NECK", nil), @"region",
//				neckRegions, @"keywords",
//				nil];
//	NSDictionary *chestRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"CHEST", nil), @"region",
//				chestRegions, @"keywords",
//				nil];
//	NSDictionary *abdomenRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"ABDOMEN", nil), @"region",
//				abdomenRegions, @"keywords",
//				nil];
//	NSDictionary *pelvisRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"PELVIS", nil), @"region",
//				pelvisRegions, @"keywords",
//				nil];
//	NSDictionary *thighRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"THIGH", nil), @"region",
//				thighRegions, @"keywords",
//				nil];
//	NSDictionary *kneeRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"KNEE", nil), @"region",
//				kneeRegions, @"keywords",
//				nil];
//	NSDictionary *lowerLegRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"LOWER LEG", nil), @"region",
//				lowerLegRegions, @"keywords",
//				nil];
//	NSDictionary *footRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"FOOT", nil), @"region",
//				footRegions, @"keywords",
//				nil];
//	NSDictionary *shoulderRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"SHOULDER", nil), @"region",
//				shoulderRegions, @"keywords",
//				nil];
//	NSDictionary *armRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"UPPER ARM", nil), @"region",
//				armRegions, @"keywords",
//				nil];
//	NSDictionary *elbowRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"ELBOW", nil), @"region",
//				elbowRegions, @"keywords",
//				nil];
//	NSDictionary *forearmRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"FOREARM", nil), @"region",
//				forearmRegions, @"keywords",
//				nil];
//	NSDictionary *handRegion = [NSDictionary dictionaryWithObjectsAndKeys:
//				NSLocalizedString(@"HAND", nil), @"region",
//				handRegions, @"keywords",
//				nil];
//	
//	NSArray *bodyRegions = [NSArray arrayWithObjects:
//				headRegion,
//				neckRegion,
//				chestRegion,
//				abdomenRegion,
//				pelvisRegion,
//				shoulderRegion,
//				armRegion,
//				elbowRegion,
//				forearmRegion,
//				handRegion,
//				thighRegion,
//				kneeRegion,
//				lowerLegRegion,
//				footRegion,
//				nil];
//	
//	[defaultValues setObject:bodyRegions forKey:@"bodyRegions"];
	
	// ITK Segmentation Defaults
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"growingRegionType"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"growingRegionAlgorithm"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"previewGrowingRegion"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"preview3DGrowingRegion"];
	[defaultValues setObject:[NSNumber numberWithInt:100] forKey:@"growingRegionInterval"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"growingRegionLowerThreshold"];
	[defaultValues setObject:[NSNumber numberWithInt:100] forKey:@"growingRegionUpperThreshold"];
	[defaultValues setObject:[NSNumber numberWithInt:2] forKey:@"growingRegionRadius"];
	[defaultValues setObject:[NSNumber numberWithFloat:2.5] forKey:@"growingRegionMultiplier"];
	[defaultValues setObject:[NSNumber numberWithInt:5] forKey:@"growingRegionIterations"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"growingRegionROIType"];
	[defaultValues setObject:[NSNumber numberWithInt:20] forKey:@"growingRegionPointCount"];
	[defaultValues setObject:NSLocalizedString(@"Growing Region", nil) forKey:@"growingRegionROIName"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"displayCalciumScore"];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"CalciumScoreCTType"];
    [defaultValues setObject: @YES forKey: @"defaultShading"];
    [defaultValues setObject: @YES forKey: @"dontDeleteStudiesIfInAlbum"];
		
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:OsirixWadoServiceEnabledDefaultsKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:OsirixWebPortalUsesWeasisDefaultsKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:OsirixWebPortalPrefersFlashDefaultsKey];
	
	return defaultValues;
}
@end
