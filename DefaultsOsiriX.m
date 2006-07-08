//
//  Defaults.m
//  OsiriX
//
//  Created by Antoine Rosset on 20.06.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DefaultsOsiriX.h"

extern		NSMutableArray			*preProcessPlugins;

static BOOL isHcugeCh = NO, testDone = NO;
static NSString *hostName = @"";

@implementation DefaultsOsiriX

// Test if the computer is in the HUG (domain name == hcuge.ch)
+ (NSString*) hostName
{
	return hostName;
}

+ (BOOL) isHUG
{
	if( testDone == NO)
	{
		NSArray	*names = [[NSHost currentHost] names];
		int i;
		for( i = 0; i < [names count] && !isHcugeCh; i++)
		{
			int len = [[names objectAtIndex: i] length];
			if ( len < 8 ) continue;  // Fixed out of bounds error in following line when domainname is short.
			NSString *domainName = [[names objectAtIndex: i] substringFromIndex: len - 8];

			if([domainName isEqualToString: @"hcuge.ch"])
			{
				isHcugeCh = YES;
				hostName = [names objectAtIndex: i];
				//NSLog(@"hostName : %@", hostName);
			}
		}
		testDone = YES;
	}
	return isHcugeCh;
}

+ (BOOL) isLAVIM
{
	if( [self isHUG])
	{
		int i;
		
		for( i = 0; i < [preProcessPlugins count]; i++)
		{
			id filter = [preProcessPlugins objectAtIndex:i];
			
			if( [[filter className] isEqualToString:@"LavimAnonymize"]) return YES;
		}
	}
	
	return NO;
}

+ (void) addCLUT: (NSString*) filename dictionary: (NSMutableDictionary*) clutValues
{
	if( [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"])
		[clutValues setObject:[NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"]] forKey: filename];
	else
	{
		NSLog(@"CLUT plist not found: %@", filename);
	}
}

+ (void) addConvolutionFilter: (short) size :(short*) vals :(NSString*) name :(NSMutableDictionary*) convValues
{
	long				i;
	NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
	NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];

	[aConvFilter setObject:[NSNumber numberWithLong:size] forKey:@"Size"];
	
	long norm = 0;
	for( i = 0; i < size*size; i++) norm += vals[i];
	[aConvFilter setObject:[NSNumber numberWithLong:norm] forKey:@"Normalization"];
	
	for( i = 0; i < size*size; i++) [valArray addObject:[NSNumber numberWithLong:vals[i]]];
	[aConvFilter setObject:valArray forKey:@"Matrix"];
	
	[convValues setObject:aConvFilter forKey:name];
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
	
	// Now we iterate through them
	for(i = 0; i < displayCount; i++)
		dspPorts[i] = CGDisplayIOServicePort(displays[i]);

	// Ask for the physical size of VRAM of the primary display
	typeCode = IORegistryEntryCreateCFProperty(dspPorts[0], CFSTR("IOFBMemorySize"), kCFAllocatorDefault, kNilOptions);
	
	// Validate our data and make sure we're getting the right type
	if(typeCode && CFGetTypeID(typeCode) == CFNumberGetTypeID())
	{
		long vramStorage = 0;
		// Convert this to a useable number
		CFNumberGetValue(typeCode, kCFNumberSInt32Type, &vramStorage);
		// If we get something other than 0, we'll use it
		if(vramStorage > 0)
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
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Pulmonary"];
	
	iww = 1500;          iwl = 300;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Bone"];
	
	iww = 100;          iwl = 50;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Brain"];
	
	iww = 350;          iwl = 40;
	[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Abdomen"];
	
	[defaultValues setObject:wlwwValues forKey:@"WLWW3"];
	
	// ** CONVOLUTION PRESETS
	
	NSMutableDictionary *convValues = [NSMutableDictionary dictionary];
	
	// --
	{
		NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];
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
		NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];
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
		[self addConvolutionFilter:3 :vals :@"Edge north" :convValues];
	}
	{
		short				vals[9] = {1, 0, -1, 2, 0, -2, 1, 0, -1};
		[self addConvolutionFilter:3 :vals :@"Edge west" :convValues];
	}
	{
		short				vals[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};
		[self addConvolutionFilter:3 :vals :@"Edge diagonal" :convValues];
	}
	{
		short				vals[9] = {0, 1, 0, -1, 0, 1, 0, -1, 0};
		[self addConvolutionFilter:3 :vals :@"Edge north" :convValues];
	}
	{
		short				vals[9] = {-1, -1, -1, -1, 8, -1, -1, -1, -1};
		[self addConvolutionFilter:3 :vals :@"Laplacian 8" :convValues];
	}
	{
		short				vals[9] = {-1, 0, -1, 0, 7, 0, -1, 0, -1};
		[self addConvolutionFilter:3 :vals :@"Laplacian 7" :convValues];
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
		[self addConvolutionFilter:3 :vals :@"Highpass" :convValues];
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
		short				vals[25] = {0, -1, -1, -1, 0, -1, 2, -4, 2, -1, -1, -4, 13, -4, -1, -1, 2, -4, 2, -1, 0, -1, -1, -1, 0};
		[self addConvolutionFilter:5 :vals :@"highpass" :convValues];
	}
	{
		short				vals[9] = {-1, -1, -1, -1, 9, -1, -1, -1, -1};
		[self addConvolutionFilter:3 :vals :@"Sharpen" :convValues];
	}
	{
		short				vals[9] = {1, 1, 1, 1, -7, 1, 1, 1, 1};
		[self addConvolutionFilter:3 :vals :@"Excessive edges" :convValues];
	}
	{
		short				vals[25] = {-1, -1, -1, -1, -1, -1, 2, 2, 2, -1, -1, 2, 8, 2, -1, -1, 2, 2, 2, -1, -1, -1, -1, -1, -1};
		[self addConvolutionFilter:5 :vals :@"5x5 sharpen" :convValues];
	}

	// --
	
	[defaultValues setObject:convValues forKey:@"Convolution"];
	
	// ** OPACITY TABLES
	NSMutableDictionary *opacityValues = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *aOpacityFilter = [NSMutableDictionary dictionary];
	NSMutableArray *points = [NSMutableArray arrayWithCapacity:0];
	
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
	points = [NSMutableArray arrayWithCapacity:0];
	
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
	points = [NSMutableArray arrayWithCapacity:0];
	
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
	//	NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
	//	for( i = 0; i < 256; i++)
	//	{
	//		[rArray addObject: [NSNumber numberWithLong:i]];
	//	}
	//	[aCLUTFilter setObject:rArray forKey:@"Red"];
	//	
	//	NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
	//	for( i = 0; i < 256; i++)
	//	{
	//		[gArray addObject: [NSNumber numberWithLong:0]];
	//	}
	//	[aCLUTFilter setObject:gArray forKey:@"Green"];
	//	
	//	NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
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
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 128; i++) [rArray addObject: [NSNumber numberWithLong:i*2]];
		for( i = 128; i < 256; i++) [rArray addObject: [NSNumber numberWithLong:255]];
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 128; i++) [gArray addObject: [NSNumber numberWithLong:0]];
		for( i = 128; i < 192; i++) [gArray addObject: [NSNumber numberWithLong: (i-128)*4]];
		for( i = 192; i < 256; i++) [gArray addObject: [NSNumber numberWithLong: 255]];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 192; i++) [bArray addObject: [NSNumber numberWithLong:0]];
		for( i = 192; i < 256; i++) [bArray addObject: [NSNumber numberWithLong:(i-192)*4]];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];
		[points addObject:[NSNumber numberWithLong: 128]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], 0L]];
		[points addObject:[NSNumber numberWithLong: 192]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], 0L]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"PET"];
	}
	
	// --
	{
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 256; i++) [rArray addObject: [NSNumber numberWithLong:255-i]];
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 256; i++) [gArray addObject: [NSNumber numberWithLong:255-i]];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 256; i++) [bArray addObject: [NSNumber numberWithLong:255-i]];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], 0L]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		[clutValues setObject:aCLUTFilter forKey:@"B/W Inverse"];
	}
	
	[self addCLUT: @"VR Muscles-Bones"  dictionary: clutValues];
	[self addCLUT: @"VR Bones"  dictionary: clutValues];
	[self addCLUT: @"VR Red Vessels"  dictionary: clutValues];
	[self addCLUT: @"BlackBody"  dictionary: clutValues];	
	[self addCLUT: @"Flow"  dictionary: clutValues];		
	[self addCLUT: @"GEcolor"  dictionary: clutValues];	
	[self addCLUT: @"Spectrum"  dictionary: clutValues];	
	[self addCLUT: @"NIH"  dictionary: clutValues];	
	[self addCLUT: @"HotIron"  dictionary: clutValues];	
	[self addCLUT: @"GrayRainbow"  dictionary: clutValues];	

	[self addCLUT: @"UCLA"  dictionary: clutValues];			
	[self addCLUT: @"Stern"  dictionary: clutValues];		
	[self addCLUT: @"Ratio"  dictionary: clutValues];		
	[self addCLUT: @"Rainbow3"  dictionary: clutValues];		
	[self addCLUT: @"Rainbow2"  dictionary: clutValues];		
	[self addCLUT: @"Rainbow"  dictionary: clutValues];	
	[self addCLUT: @"ired"  dictionary: clutValues];		
	[self addCLUT: @"Hue1"  dictionary: clutValues];		
	[self addCLUT: @"Hue2"  dictionary: clutValues];		
	[self addCLUT: @"HotMetal"  dictionary: clutValues];	
	[self addCLUT: @"HotGreen"  dictionary: clutValues];	

	[defaultValues setObject:clutValues forKey:@"CLUT"];
	
	// ** PREFERENCES - SERVERS
	
	NSMutableArray *serversValues = [NSMutableArray arrayWithCapacity:0];
	
	NSMutableDictionary *aServer = [[NSMutableDictionary alloc] init];
	[aServer setObject:@"127.0.0.1" forKey: @"Address"];
	[aServer setObject:@"OsiriX" forKey: @"AETitle"];
	[aServer setObject:@"4444" forKey: @"Port"];
	[aServer setObject:[NSNumber numberWithInt:0] forKey:@"Transfer Syntax"];
	[aServer setObject:NSLocalizedString(@"This is an example", nil) forKey:@"Description"];
	
	[serversValues addObject:aServer];
	[aServer release];
	
	[defaultValues setObject:serversValues forKey:@"SERVERS"];
	
	serversValues = [NSMutableArray arrayWithCapacity:0];
	[defaultValues setObject:serversValues forKey:@"OSIRIXSERVERS"];
	
	//routing calendars
	[defaultValues setObject:[NSMutableArray arrayWithObject:@"Osirix"] forKey:@"ROUTING CALENDARS"];
	
	// ** AETITLE
	NSString *userName = [NSUserName() uppercaseString];
	if ([userName length] > 4)
		userName = [userName substringToIndex:4];
	NSString *computerName = [[[NSHost currentHost] name] uppercaseString];
	if ([computerName length] > 4)
		computerName = [computerName substringToIndex:4];
	NSString *suggestedAE = [NSString stringWithFormat:@"OSIRIX_%@_%@", computerName, userName];
	[defaultValues setObject: suggestedAE forKey: @"AETITLE"];
	//[defaultValues setObject:@"OSIRIX" forKey:@"AETITLE"];

	[defaultValues setObject:@"1.0" forKey:@"points3DcolorRed"];
	[defaultValues setObject:@"0" forKey:@"points3DcolorGreen"];
	[defaultValues setObject:@"0" forKey:@"points3DcolorBlue"];
	[defaultValues setObject:@"1.0" forKey:@"points3DcolorAlpha"];
	
	
	[defaultValues setObject:@"1" forKey:@"StoreThumbnailsInDB"];
	[defaultValues setObject:@"1" forKey:@"DisplayDICOMOverlays"];
	
	
	// *************
	// AUTO-CLEANING
	// *************
	
	[defaultValues setObject:@"0" forKey:@"AUTOCLEANINGDATE"];
	[defaultValues setObject:@"0" forKey:@"AUTOCLEANINGDATEPRODUCED"];
	[defaultValues setObject:@"0" forKey:@"AUTOCLEANINGDATEOPENED"];
	
	[defaultValues setObject:@"90" forKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"];
	[defaultValues setObject:@"90" forKey:@"AUTOCLEANINGDATEOPENEDDAYS"];
	
	[defaultValues setObject:@"2" forKey:@"DEFAULTRIGHTTOOL"];	//ZOOM TOOL
	
	[defaultValues setObject:@"1" forKey:@"AUTOCLEANINGSPACE"];
	[defaultValues setObject:@"1" forKey:@"AUTOCLEANINGSPACEPRODUCED"];
	[defaultValues setObject:@"1" forKey:@"AUTOCLEANINGSPACEOPENED"];
	
	[defaultValues setObject:@"100" forKey:@"AUTOCLEANINGSPACESIZE"];
	
	[defaultValues setObject:@"0" forKey:@"PETMinimumValue"];
	[defaultValues setObject:@"1" forKey:@"PETWindowingMode"];
	
	[defaultValues setObject:@"B/W Inverse" forKey:@"PET Clut Mode"];
	[defaultValues setObject:@"PET" forKey: @"PET Default CLUT"];
	[defaultValues setObject:@"PET" forKey: @"PET Blending CLUT"];
	
	// ** NETWORKLOGS
	[defaultValues setObject:@"0" forKey:@"NETWORKLOGS"];
	
	// ** PORT
	[defaultValues setObject:@"4096" forKey:@"AEPORT"];
	
	// ** SYNTAX
	[defaultValues setObject:@"+xi" forKey:@"AETransferSyntax"];
	
	// ** STORESCPEXTRA
	[defaultValues setObject:@"" forKey:@"STORESCPEXTRA"];
	
	// ** ROITEXTIFSELECTED
//		[defaultValues setObject:@"0" forKey:@"ROITEXTIFSELECTED"];
	
	// ** STORESCP
	[defaultValues setObject:@"1" forKey: @"STORESCP"];
	
	// ** USEALWAYSTOOLBARPANEL
	[defaultValues setObject:@"0" forKey: @"USEALWAYSTOOLBARPANEL"];
	
	// ** HIDEPATIENTNAME
	[defaultValues setObject:@"0" forKey:@"HIDEPATIENTNAME"];
	
	// ** DELETEFILELISTENER
	[defaultValues setObject:@"1" forKey:@"DELETEFILELISTENER"];
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

	// ** OPENVIEWER
	[defaultValues setObject:@"1" forKey:@"OPENVIEWER"];
	
	// ** ANONYMIZELISTENER
	[defaultValues setObject:@"0" forKey:@"ANONYMIZELISTENER"];
	
	// ** ConvertPETtoSUVautomatically
	[defaultValues setObject: @"1" forKey: @"ConvertPETtoSUVautomatically"];
	
	// ** SURVEYDONE
	[defaultValues setObject: @"0" forKey: @"SURVEYDONE3"];
	
	// ** stackThickness
	[defaultValues setObject: @"20" forKey: @"stackThickness"];
	[defaultValues setObject: @"20" forKey: @"stackThicknessOrthoMPR"];
	
	// ** ROUTINGACTIVATED
	[defaultValues setObject:@"0" forKey:@"ROUTINGACTIVATED"];
	
	// ** AUTOHIDEMATRIX
	[defaultValues setObject: @"0" forKey: @"AUTOHIDEMATRIX"];

	// ** AutoPlay
	[defaultValues setObject: @"1" forKey: @"AutoPlayAnimation"];
	
	// ** KeepStudiesOfSamePatientTogether
	[defaultValues setObject: @"1" forKey: @"KeepStudiesOfSamePatientTogether"];
	
	// ** USEPAPYRUSDCMPIX
	[defaultValues setObject: @"1" forKey: @"USEPAPYRUSDCMPIX"];
	
	// ** TOOLKITPARSER
	[defaultValues setObject: @"2" forKey: @"TOOLKITPARSER"];	// 0:DCM Framework 1:Papyrus 2:DCMTK
	
	// ** SINGLEPROCESS
	[defaultValues setObject: @"0" forKey: @"SINGLEPROCESS"];
	
	// ** DCMTKJPEG
	[defaultValues setObject: @"0" forKey: @"DCMTKJPEG"];
	
	// ** AUTHENTICATION
	[defaultValues setObject: @"0" forKey: @"AUTHENTICATION"];
	
	// ** CHECKUPDATES
	[defaultValues setObject: @"1" forKey: @"CHECKUPDATES"];
	
	// ** MOUNT/UNMOUNT
	[defaultValues setObject:@"1" forKey:@"MOUNT"];
	[defaultValues setObject:@"1" forKey:@"UNMOUNT"];
	
	// ** USEDICOMDIR
	[defaultValues setObject: @"1" forKey: @"USEDICOMDIR"];
	
	// ** SAVEROIS
	[defaultValues setObject: @"1" forKey: @"SAVEROIS"];
	
	// ** NOLOCALIZER
	[defaultValues setObject: @"1" forKey: @"NOLOCALIZER"];
	
	// ** TRANSITIONEFFECT
	[defaultValues setObject: @"0" forKey: @"TRANSITIONEFFECT"];
	
	// ** NOINTERPOLATION
	[defaultValues setObject:@"0" forKey:@"NOINTERPOLATION"];
	
	// ** WINDOWSIZEVIEWER
	[defaultValues setObject: @"0" forKey: @"WINDOWSIZEVIEWER"];
	
	// ** STILLMOVIEMODE
	[defaultValues setObject: @"0" forKey: @"STILLMOVIEMODE"];
	
	// ** ReserveScreenForDB
	[defaultValues setObject: @"1" forKey: @"ReserveScreenForDB"];
	
	// ** SERIESORDER
	[defaultValues setObject:@"0" forKey:@"SERIESORDER"];
	
	// ** TRANSITIONTYPE
	[defaultValues setObject: @"0" forKey: @"TRANSITIONTYPE"];
	
	// ** COPYDATABASE
	[defaultValues setObject: @"0" forKey: @"COPYDATABASE"];
	
	// ** SUVCONVERSION
	[defaultValues setObject: @"0" forKey: @"SUVCONVERSION"];
	
	// ** AUTOCLEANINGCOMMENTS
	[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGCOMMENTS"];
	
	// ** AUTOCLEANINGCOMMENTSTEXT
	[defaultValues setObject: @"" forKey: @"AUTOCLEANINGCOMMENTSTEXT"];
	
	// ** AUTOCLEANINGDONTCONTAIN
	[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGDONTCONTAIN"];
	
	// ** AUTOCLEANINGDELETEORIGINAL
	[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGDELETEORIGINAL"];
	
	// ** COMMENTSAUTOFILL
	[defaultValues setObject: @"0" forKey: @"COMMENTSAUTOFILL"];
	
	// ** COMMENTSGROUP
	[defaultValues setObject: @"0008" forKey: @"COMMENTSGROUP"];
	
	// ** COMMENTSELEMENT
	[defaultValues setObject: @"0008" forKey: @"COMMENTSELEMENT"];
	
	// ** Burn Osirix Application	
	[defaultValues setObject: @"1" forKey: @"Burn Osirix Application"];
	
	// ** Burn Supplementary Folder	
	[defaultValues setObject: @"0" forKey: @"Burn Supplementary Folder"];
	
	// ** Supplementary Burn Path	
	[defaultValues setObject: @"" forKey: @"Supplementary Burn Path"];
	
	// ** DATABASEINDEX
	[defaultValues setObject:@"0" forKey:@"DATABASEINDEX"];
	
	// ** ANNOTATIONS
	[defaultValues setObject: @"2" forKey: @"ANNOTATIONS"];
	
	// ** CLUT BARS
	[defaultValues setObject: @"3" forKey :@"CLUTBARS"];
	
	// ** COPYDATABASEMODE
	[defaultValues setObject:@"0" forKey:@"COPYDATABASEMODE"];
	
	// ** LOGCLEANINGDAYS
	[defaultValues setObject:@"7" forKey:@"LOGCLEANINGDAYS"];
	
	// ** DATABASELOCATION
	[defaultValues setObject:@"0" forKey:@"DATABASELOCATION"];
	
	// ** FONTNAME
	[defaultValues setObject: @"Geneva" forKey: @"FONTNAME"];
	
	// ** DICOMSENDALLOWED
	[defaultValues setObject: @"1" forKey: @"DICOMSENDALLOWED"];
	
	// ** FONTSIZE
	[defaultValues setObject: @"14.0" forKey: @"FONTSIZE"];
	
	// ** DATABASELOCATIONURL
	[defaultValues setObject: @"" forKey: @"DATABASELOCATIONURL"];
	
	// ** REPORTSMODE
	if( [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Microsoft Word"])
		[defaultValues setObject: @"0" forKey: @"REPORTSMODE"];
	else
		[defaultValues setObject: @"1" forKey: @"REPORTSMODE"];
	
	// ** LASTURL
	[defaultValues setObject: @"http://homepage.mac.com/rossetantoine/internet.dcm" forKey: @"LASTURL"];
	
	// ** MAPPERMODEVR
	[defaultValues setObject: @"0" forKey: @"MAPPERMODEVR"];
	
	// ** STARTCOUNT
	[defaultValues setObject: @"0" forKey: @"STARTCOUNT"];
	
	// ** ORIGINALSIZE
	[defaultValues setObject: @"0" forKey: @"ORIGINALSIZE"];
	
	// ** Scroll Wheel Reversed
	[defaultValues setObject: @"1" forKey: @"Scroll Wheel Reversed"];
	
	// ** ALBUMNAME
	[defaultValues setObject: @"OsiriX" forKey: @"ALBUMNAME"];
	
	//IMAGE TILING
	[defaultValues setObject:@"1" forKey: @"IMAGEROWS"];
	[defaultValues setObject:@"1" forKey: @"IMAGECOLUMNS"];
	
	// ** STRINGENCODING
	[defaultValues setObject :@"ISO_IR 100" forKey: @"STRINGENCODING"];

	// ** ROI Default
	[defaultValues setObject:[NSNumber numberWithFloat: 2] forKey:@"ROIThickness"];
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
	NSEnumerator *enumerator = [modalities objectEnumerator];
	NSString *modality;
	while (modality = [enumerator nextObject]) {
		//NSLog(@"Modality %@", modality);
		NSMutableDictionary *protocol = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Default", [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil] forKeys:[NSArray arrayWithObjects:@"Study Description", @"Rows", @"Columns",@"Image Rows", @"Image Columns", nil]];
		NSMutableArray *protocols = [NSMutableArray arrayWithObject:protocol];
		[defaultHangingProtocols setObject:protocols forKey:modality];
	}
	[defaultValues setObject: defaultHangingProtocols forKey: @"HANGINGPROTOCOLS"];
	
	// ** COLUMNSDATABASE
	NSMutableDictionary *defaultDATABASECOLUMNS = [NSMutableDictionary dictionary];
	[defaultValues setObject: defaultDATABASECOLUMNS forKey: @"COLUMNSDATABASE"];
	
	// **
	
	[defaultValues setObject: @"1" forKey: @"COPYSETTINGS"];
	
	[defaultValues setObject: @"1" forKey: @"USESTORESCP"];
	// Parsing Series Objects
	[defaultValues setObject:@"1" forKey:@"splitMultiEchoMR"];
	[defaultValues setObject:@"1" forKey:@"combineProjectionSeries"];
	
	return defaultValues;
}
@end
