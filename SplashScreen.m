/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
*****************************************************************/

#import "SplashScreen.h"

#include <mach/mach.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>
#include <mach/machine.h>
#include <sys/sysctl.h>



BOOL IsPPC()

{
   host_basic_info_data_t hostInfo;
   mach_msg_type_number_t infoCount;

   infoCount = HOST_BASIC_INFO_COUNT;
   host_info(mach_host_self(), HOST_BASIC_INFO, 
(host_info_t)&hostInfo, &infoCount);

	return (hostInfo.cpu_type == CPU_TYPE_POWERPC);
} 

int GetAltiVecTypeAvailable( void )
{

int sels[2] = { CTL_HW, HW_VECTORUNIT };
int vType = 0; //0 == scalar only
size_t length = sizeof(vType);
int error = sysctl(sels, 2, &vType, &length, NULL, 0);
if( 0 == error ) return vType;

return 0;

}

long vramSize()
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


BOOL useQuartz() {
	return NO;				// Disable quartz about screen:  DDP (060224)
	
	
	if (vramSize() >= 32)
		return YES;
	else 
		return NO;
		
	if (!IsPPC())
		return YES;
		
	return GetAltiVecTypeAvailable();
}
@implementation SplashScreen

- (void)windowDidLoad
{ 
	[[self window] center];
	versionType  = YES;
	[self switchVersion: self];
		
	[[self window] setDelegate:self];
	[[self window] setAlphaValue:0.0];
//	if (useQuartz())	
//		[view setAutostartsRendering:YES];
}

- (IBAction) switchVersion:(id) sender
{
	NSMutableString *currVersionNumber = 0L;
	
	if( versionType)
	{
		currVersionNumber = [NSMutableString stringWithString:[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleGetInfoString"]];
		if( sizeof(long) == 8)
			[currVersionNumber appendString:@" 64-bit"];
		else
			[currVersionNumber appendString:@" 32-bit"];
	}
	else
	{
		currVersionNumber = [NSMutableString stringWithString:[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]];
		[currVersionNumber insertString:@"Revision " atIndex:0];
	}
	
	[version setTitle: currVersionNumber];

	versionType = !versionType;
}

- (IBAction)showWindow:(id)sender{
	[super showWindow:sender];	
//	if (useQuartz())
//		[self startRendering];
	//
	//NSLog(@"show Splash screen");
}

//- (void)startRendering
//{
//	NSString *path = [[NSBundle mainBundle] pathForResource:@"About" ofType:@"qtz"];
//	[view loadCompositionFromFile:path];
//	[view setAutostartsRendering:YES];
//	[view startRendering];
//}

- (void) affiche
{
	timerIn = [[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(fadeIn:) userInfo:nil repeats:YES] retain];
//	[[NSRunLoop currentRunLoop] addTimer:timerIn forMode:NSModalPanelRunLoopMode];
//	[[NSRunLoop currentRunLoop] addTimer:timerIn forMode:NSEventTrackingRunLoopMode];
}

-(id) init
{
	if (useQuartz())
		self = [super initWithWindowNibName:@"SplashQtz"];
	else
		self = [super initWithWindowNibName:@"Splash"];
 
 
 return self;
}

- (BOOL)windowShouldClose:(id)sender
{
	[timerIn invalidate];
	[timerIn release];
	timerIn = nil;
	
    // Set up our timer to periodically call the fade: method.
    timerOut = [[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
//	[[NSRunLoop currentRunLoop] addTimer:timerOut forMode:NSModalPanelRunLoopMode];
//	[[NSRunLoop currentRunLoop] addTimer:timerOut forMode:NSEventTrackingRunLoopMode];

//	[timer fire];
	
    // Don't close just yet.
    return NO;
}

- (void)fade:(NSTimer *)theTimer
{
    if ([[self window] alphaValue] > 0.0)
	{
        [[self window] setAlphaValue:[[self window] alphaValue] - 0.1];
    }
	else
	{
        [timerOut invalidate];
        [timerOut release];
        timerOut = nil;
		
        [[self window] close];
    }
}

- (void)fadeIn:(NSTimer *)theTimer
{
	if ([[self window] alphaValue] < 1.0)
	{
        [[self window] setAlphaValue:[[self window] alphaValue] + 0.1];
    }
	else
	{
        [timerIn invalidate];
        [timerIn release];
        timerIn = nil;
		
		[[self window] setAlphaValue:1.0];
    }
}


@end
