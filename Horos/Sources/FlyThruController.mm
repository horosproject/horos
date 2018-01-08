/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "FlyThruController.h"
#import "VRController.h"
#import "EndoscopyVRController.h"
#import "VRView.h"
#import "DICOMExport.h"
#import "Window3DController.h"
#import "Wait.h"
#import "BrowserController.h"
#import "VRControllerVPRO.h"
#import "Notifications.h"
#import "DicomDatabase.h"

@implementation FlyThruController

@synthesize stepsArrayController;
@synthesize curMovieIndex;
@synthesize flyThru;
@synthesize hidePlayBox;
@synthesize hideComputeBox;
@synthesize hideExportBox;
@synthesize exportFormat;
@synthesize dcmSeriesName;
@synthesize levelOfDetailType;
@synthesize exportSize;
@synthesize FTAdapter, tabIndex;

- (void)setWindow3DController:(Window3DController*) w3Dc
{
	if( controller3D == w3Dc) return;
	
	[controller3D release];
	controller3D = [w3Dc retain];
	
	if( [controller3D isKindOfClass: [EndoscopyVRController class]])
	{
		[MatrixSize setHidden: YES];
		[MatrixSizePopup setHidden: YES];
	}
}

- (Window3DController*)window3DController
{
	return controller3D;
}


- (id) initWithFlyThruAdapter:(FlyThruAdapter*)aFlyThruAdapter
{
	self = [super initWithWindowNibName:@"FlyThru"];
	[self setupController];
	self.FTAdapter = aFlyThruAdapter;

	
	return self;
}

- (void)setupController {
	controller3D = nil;
	
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
//	[[self window] setBackgroundColor:[NSColor blackColor]];
	[[self window] setAlphaValue:0.75];
	[self loadWindow];
	
	self.flyThru = [[[FlyThru alloc] init] autorelease];
	self.hidePlayBox = YES;
	self.hideComputeBox = NO;
	self.hideExportBox = YES;
	self.exportFormat = 0;
	self.levelOfDetailType = 1;
	self.dcmSeriesName = NSLocalizedString(@"FlyThru", nil);
	self.exportSize = 0;
	
	boxPlayOrigin = [boxPlay frame].origin;
	windowFrame =[[self window] frame];
	
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(Window3DClose:)
											name: OsirixWindow3dCloseNotification
											object: nil];
}

- (void) Window3DClose: (NSNotification *)notification
{
	if( [notification object] == controller3D)	//The 3D window will be released.... Kill ourself
	{
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
	[[self window] setDelegate:nil];
    
	[self autorelease];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[[self window] setAlphaValue:1.0];
}
- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[[self window] setAlphaValue:0.5];
}

- (void) dealloc
{
	NSLog(@"FlyThruController released");
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[FTAdapter release];
	[flyThru release];
	[controller3D release];
	[dcmSeriesName release];
	
	[super dealloc];
}


- (void) keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
	unichar	c = [[theEvent characters] characterAtIndex:0];
	if (c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
	{
		[stepsArrayController  keyDown:(NSEvent *)theEvent];
	}
	else
	{
		[super keyDown:theEvent];
	}
}

- (void) setCurrentView
{
	if ([[flyThru steps] count]>0)
	{
		int index = [FTview selectedRow];
		[FTAdapter setCurrentViewToCamera:[[flyThru steps] objectAtIndex:index]];
		[framesSlider setIntValue:[[[flyThru stepsPositionInPath] objectAtIndex:index] intValue]];
	}
}

- (IBAction) flyThruSetCurrentView:(id) sender
{
	[self setCurrentView];
}


- (IBAction) flyThruCompute:(id) sender
{
	int minSteps = (flyThru.loop)?2:3; // for the spline, 3 points are needed. (in the case of a loop, the 3rd point is added in the 'computePath' method of the FlyThru)
	int userChoice = 1;
	
	if( [flyThru.steps count] < 2)
	{
		NSRunAlertPanel(NSLocalizedString(@"Error",nil), NSLocalizedString(@"Add at least 2 frames for a Fly Thru.",nil), nil, nil, nil);
		return;
	}
	
	if ([flyThru interpolationMethod] == 1 && [flyThru.steps count] < minSteps)
	{
		userChoice = NSRunAlertPanel(NSLocalizedString(@"Spline Interpolation Error", nil), NSLocalizedString(@"The Spline Interpolation needs at least 3 points to be run.", nil), NSLocalizedString(@"Use Linear Interpollation", nil), NSLocalizedString(@"Cancel", nil), nil);
		if(userChoice == 1)
		{
			flyThru.interpolationMethod = 2; // changing the method
			// selection of the right radio button
			//[[methodChooser cellWithTag:1] setState: NSOffState]; 
			//[[methodChooser cellWithTag:2] setState: NSOnState];
		}
	}
	
	if(userChoice == 1)
	{
		int v = [numberOfFramesTextField intValue];
		
		if( v < 2) v = 2;
		if( v > 5000) v = 5000;
		
		[numberOfFramesTextField setIntValue: v];
		[numberOfFramesTextField selectText: self];
		
		flyThru.numberOfFrames = v;
		[flyThru computePath];
		
		// 4D
		if([controller3D is4D])
		{
			NSArray *pathCameras = [flyThru pathCameras];
			int i;
			long previousIndex = [[pathCameras objectAtIndex:0] movieIndexIn4D];
			BOOL sameIndexes = YES;
			for(i=1; i<[pathCameras count] && sameIndexes; i++)
			{
				sameIndexes = sameIndexes && (previousIndex == [[pathCameras objectAtIndex:i] movieIndexIn4D]);
				previousIndex = [[pathCameras objectAtIndex:i] movieIndexIn4D];
			}
			if(sameIndexes)
			{
				NSLog(@"sameIndexes");
				long movieFrames = [controller3D movieFrames];
				int j = 0;
				for(i=0; i<[pathCameras count]; i++)
				{
					[[pathCameras objectAtIndex:i] setMovieIndexIn4D:j];
					j = (j+1) % movieFrames;
					NSLog(@"j : %d", j);
				}
			}
		}

		
		self.hidePlayBox = NO;
		self.hideExportBox = NO;
		
	//	[nbFramesTextField setStringValue: [NSString stringWithFormat:@"%d",[flyThru numberOfFrames]]];
		
		[framesSlider setMaxValue: flyThru.numberOfFrames - 1];
		
		if( [controller3D isKindOfClass: [VRController class]] == NO || [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 1)	// Only the VR supports LOD versus Best rendering mode if ray casting is used
		{
			self.levelOfDetailType =  0;
			[[LOD cellWithTag: 1] setEnabled: NO];
		}
		else
		{
			[[LOD cellWithTag: 1] setEnabled: YES];
		}
	}
}



- (IBAction) flyThruSetCurrentViewToSliderPosition:(id) sender
{
	if ([[flyThru pathCameras] count]>0)
	{
		int index = [framesSlider intValue];
		if (index > flyThru.pathCameras.count) index = (long)flyThru.pathCameras.count - 1;
		[FTAdapter setCurrentViewToCamera:[flyThru.pathCameras objectAtIndex:index]];
	}
}

- (void) flyThruPlayStop:(id) sender
{
	//self.curMovieIndex = [framesSlider intValue];
	
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
        
        [playButton setTitle: @"Play"];
		
		[FTAdapter setCurrentViewToCamera:[[flyThru pathCameras] objectAtIndex:curMovieIndex]];
		

		self.hideComputeBox = NO;
		self.hideExportBox = NO;
//		// resize the window to the original size (with the 3 box)
//
//		NSPoint upperLeftCorner = [[self window] frame].origin;
//		upperLeftCorner.y += [[self window] frame].size.height;
//
//		NSPoint newUpperLeftCorner = windowFrame.origin;
//		newUpperLeftCorner.y += windowFrame.size.height;
//
//		NSPoint translation; // if the user moved the window when it was reduced, we will keep this translation
//		translation.x = upperLeftCorner.x - newUpperLeftCorner.x;
//		translation.y = upperLeftCorner.y - newUpperLeftCorner.y;
//		
//		windowFrame.origin.x += translation.x;
//		windowFrame.origin.y += translation.y;
//		
//		[[self window] setFrame:windowFrame display:YES animate:NO];
//		[boxPlay setFrameOrigin: boxPlayOrigin];
//		
//		[[self window] display]; // to refresh the window
//		[[self window] becomeKeyWindow];
	}
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
    
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
        
        [playButton setTitle: NSLocalizedString(@"Stop", nil)];
		
		self.hideComputeBox = YES;
        self.hideExportBox = YES;
        
//		// resize the window
//		NSPoint newOrigin = [boxExport frame].origin;

//		boxPlayOrigin = [boxPlay frame].origin;
//		
//		windowFrame = [[self window] frame];
//		
//		[[self window] setFrame:NSMakeRect(	windowFrame.origin.x,
//											windowFrame.origin.y+[boxCompute frame].size.height+[boxExport frame].size.height,
//											windowFrame.size.width,
//											windowFrame.size.height-[boxCompute frame].size.height-[boxExport frame].size.height)
//						display:YES animate:NO];
//										
//		[boxPlay setFrameOrigin: newOrigin];
//		
//		[[self window] display]; // to refresh the window
//		[[self window] resignKeyWindow];
    }
}

- (void) performMovieAnimation:(id) sender
{
	NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
	short           val;
    
	val = curMovieIndex;
	val ++;
	
	if( val < 0) val = 1;
	if( val > flyThru.numberOfFrames) val = 1;
	
	self.curMovieIndex = val;
	
	if( [[self window3DController] movieFrames] > 1)
	{	
		short movieIndex = curMovieIndex - 1;
		
		while( movieIndex >= [[self window3DController] movieFrames]) movieIndex -= [[self window3DController] movieFrames];
		if( movieIndex < 0) movieIndex = 0;
		
		[[self window3DController] setMovieFrame: movieIndex];
	}
	
	//[framesSlider setIntValue:curMovieIndex];
	[FTAdapter setCurrentViewToLowResolutionCamera:[[flyThru pathCameras] objectAtIndex:curMovieIndex - 1]];
	
	lastMovieTime = thisTime;
}

- (IBAction) flyThruQuicktimeExport :(id) sender
{
	[numberOfFramesTextField selectText: self];
	
	[FTAdapter prepareMovieGenerating];

	if( exportFormat == 0)
	{
		long numberOfFrames = flyThru.numberOfFrames;
		
		if( [[self window3DController] movieFrames] > 1)
		{
			numberOfFrames /= [[self window3DController] movieFrames];
			numberOfFrames *= [[self window3DController] movieFrames];
		}
		
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame:maxFrame:) :numberOfFrames];	
		[mov createMovieQTKit: YES  :NO :[[[[self window3DController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		[mov release];
	}
	else
	{
		long			i;
		DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
		long numberOfFrames = flyThru.numberOfFrames;
		
		NSMutableArray *producedFiles = [NSMutableArray array];
		
		if( [[self window3DController] movieFrames] > 1)
		{
			numberOfFrames /= [[self window3DController] movieFrames];
			numberOfFrames *= [[self window3DController] movieFrames];
		}
		
		Wait *progress = [[Wait alloc] initWithString: NSLocalizedString( @"Creating series", nil)];
		[progress showWindow:self];
		[[progress progress] setMaxValue: numberOfFrames];
		
		[dcmSequence setSeriesNumber:8500 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
		[dcmSequence setSeriesDescription: dcmSeriesName];
		[dcmSequence setSourceFile: [[[controller3D pixList] objectAtIndex:0] srcFile]];
				
		for( i = 0; i < numberOfFrames; i++)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			if( [[self window3DController] movieFrames] > 1)
			{	
				short movieIndex = i;
		
				while( movieIndex >= [[self window3DController] movieFrames]) movieIndex -= [[self window3DController] movieFrames];
				if( movieIndex < 0) movieIndex = 0;
		
				[[self window3DController] setMovieFrame: movieIndex];
			}
			
			[FTAdapter setCurrentViewToCamera:[[flyThru pathCameras] objectAtIndex: i]];
			[FTAdapter getCurrentCameraImage: levelOfDetailType];
			
			long	width, height, spp, bpp;
			
			unsigned char *dataPtr = [[controller3D view] getRawPixels:&width :&height :&spp :&bpp :YES :YES];
			float	o[ 9];
			
			if( dataPtr)
			{
				[dcmSequence setPixelData: dataPtr samplesPerPixel:spp bitsPerSample:bpp width: width height: height];
				
				[[controller3D view] getOrientation: o];
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportOrientationIn3DExport"])
					[dcmSequence setOrientation: o];
				
				if( [controller3D isKindOfClass: [VRController class]])		//||  [controller3D isKindOfClass: [VRPROController class]])
				{
					float resolution = [[controller3D view] getResolution];
					
					if( resolution)
						[dcmSequence setPixelSpacing: resolution :resolution];
				}
				
				NSString *f = [dcmSequence writeDCMFile: nil];
				if( f)
					[producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
				
				free( dataPtr);
				
				[progress incrementBy: 1];
			}
			
			[pool release];
		}
		
		[progress close];
		[progress autorelease];
		
		[dcmSequence release];
		
		if( [producedFiles count])
		{
			NSArray *objects = [BrowserController.currentBrowser.database addFilesAtPaths: [producedFiles valueForKey: @"file"]
                                                                        postNotifications: YES
                                                                                dicomOnly: YES
                                                                      rereadExistingItems: YES
                                                                        generatedByOsiriX: YES];
			
            objects = [BrowserController.currentBrowser.database objectsWithIDs: objects];
            
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"])
				[[BrowserController currentBrowser] selectServer: objects];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"])
			{
				for( NSManagedObject *im in objects)
					[im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
			}
		}
	}
	
	[FTAdapter endMovieGenerating];
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] != -1)
	{
		if( [[self window3DController] movieFrames] > 1)
		{	
			short movieIndex = [cur intValue];
		
			while( movieIndex >= [[self window3DController] movieFrames]) movieIndex -= [[self window3DController] movieFrames];
			if( movieIndex < 0) movieIndex = 0;
		
			[[self window3DController] setMovieFrame: movieIndex];
		}
	
		[FTAdapter setCurrentViewToCamera:[[flyThru pathCameras] objectAtIndex: [cur intValue]]];
		return [FTAdapter getCurrentCameraImage: levelOfDetailType];
	}
	else
	{
		[FTAdapter setCurrentViewToCamera:[[flyThru pathCameras] objectAtIndex: 0]];
		return [FTAdapter getCurrentCameraImage: levelOfDetailType];
	}
}

-(void) updateThumbnails
{
	NSArray *stepsCameras = [flyThru steps];
	NSEnumerator *enumerator = [stepsCameras objectEnumerator];
	id cam;
	NSImage * im;
	while ((cam = [enumerator nextObject]))
	{
		[FTAdapter setCurrentViewToCamera:cam];
		im = [FTAdapter getCurrentCameraImage: NO];
		[cam setPreviewImage:im];
	}
}

- (NSButton*) exportButtonOption;
{
	return exportButtonOption;
}

- (int)curMovieIndex{
	return curMovieIndex;
}

- (void)setCurMovieIndex:(int)index{
	if ([flyThru.pathCameras count] > 0)
	{
		[FTAdapter setCurrentViewToCamera:[flyThru.pathCameras objectAtIndex:index - 1]];
	}
	curMovieIndex = index;
}

- (Camera *)currentCamera{
	return [FTAdapter getCurrentCamera];
}

@end
