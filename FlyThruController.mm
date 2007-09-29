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




/*

MODIFICATION HISTORY

	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).

  
*/


#import "FlyThruController.h"
#import "VRController.h"
#import "EndoscopyVRController.h"
#import "VRView.h"
#import "DICOMExport.h"
#import "Window3DController.h"
#import "Wait.h"

#import "VRControllerVPRO.h"

@implementation FlyThruController

@synthesize flyThru = FT;
@synthesize currentMovieIndex = curMovieIndex;
@synthesize hidePlayBox;
@synthesize hideComputeBox;
@synthesize hideExportBox;
@synthesize exportFormat;
@synthesize dcmSeriesName;
@synthesize levelOfDetailType;
@synthesize exportSize;

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
	
	controller3D = 0L;
	
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
//	[[self window] setBackgroundColor:[NSColor blackColor]];
	[[self window] setAlphaValue:0.75];
	[self loadWindow];
	
	[FTview setDataSource:self];
	self.flyThru = [[[FlyThru alloc] init] autorelease];
	self.hidePlayBox = YES;
	self.hideComputeBox = NO;
	self.hideExportBox = YES;
	self.exportFormat = 0;
	self.levelOfDetailType = 1;
	self.dcmSeriesName = NSLocalizedString(@"FlyThru", nil);
	self.exportSize = 0;
	FTAdapter = [aFlyThruAdapter retain];
	
	boxPlayOrigin = [boxPlay frame].origin;
	windowFrame =[[self window] frame];
	
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(Window3DClose:)
											name: @"Window3DClose"
											object: nil];
	
	return self;
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
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
	[[self window] setDelegate:nil];
	[self release];
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
	[FT release];
	[controller3D release];
	
	[super dealloc];
}

//Getting values
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[FT steps] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableColumn==colCamNumber)
	{
		return [NSString stringWithFormat:@"%d", (rowIndex+1)];
	}
//	else if (aTableColumn==colCamSymbol)
//	{
//		if (rowIndex==0)
//		{
//			//return @"Start";
//			return [NSImage imageNamed: @"FlyThruStart"];
//		}
//		else if (rowIndex==[[FT steps] count]-1)
//		{
//			//return @"End";
//			return [NSImage imageNamed: @"FlyThruEnd"];
//		}
//		else
//		{
//			//return @"Via";
//			return [NSImage imageNamed: @"FlyThruVia"];
//		}
//	}
	else if (aTableColumn==colCamPreview)
	{
		return [[[FT steps] objectAtIndex:rowIndex] previewImage];
	}
//	else if (aTableColumn==colCamDescription)
//	{
//		return [[[FT steps] objectAtIndex:rowIndex] description];
//	}
}

- (int) selectedRow
{
	return [FTview selectedRow];
}

- (void) selectRowAtIndex:(int)index
{
	[FTview selectRowIndexes: [NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[FTview scrollRowToVisible: index];
	[self setCurrentView];
}

- (void) keyDown:(NSEvent *)theEvent
{
	unichar	c = [[theEvent characters] characterAtIndex:0];
	if (c == NSDeleteCharacter)
	{
		int index = [self selectedRow];
		[self removeRowAtIndex:index];
	}
	else
	{
		[super keyDown:theEvent];
	}
}

- (void) removeRowAtIndex:(int)index
{
	[FT removeCameraAtIndex: index];
	
	if (index==[[FT steps] count])
	{	
		index = [[FT steps] count]-1; 
	}

	[self selectRowAtIndex:index];
	[self setCurrentView];
	[FTview reloadData];
	
	self.hidePlayBox = YES;
	self.hideExportBox = YES;
}

- (void) flyThruTag:(int) x
{
	switch( x)
	{
		case 0:	// ADD
		{
			int selectedRow = [self selectedRow];
			if (selectedRow<[[FT steps] count]-1)
			{
				[FT addCamera: [FTAdapter getCurrentCamera] atIndex: selectedRow+1];
			}
			else
			{
				[FT addCamera: [FTAdapter getCurrentCamera]];
			}
			[FTview reloadData];
			
		//	[self selectRowAtIndex:(selectedRow+1)];
			[FTview selectRowIndexes: [NSIndexSet indexSetWithIndex:selectedRow+1] byExtendingSelection:NO];
			[FTview scrollRowToVisible: selectedRow+1];
			
			self.hidePlayBox = YES;
			self.hideExportBox = YES;
		}
		break;
		
		case 1: //REMOVE
		{
			int index = [self selectedRow];
			[self removeRowAtIndex:index];
//			[FT removeCameraAtIndex: index];
//			
//			if (index==[[FT steps] count])
//			{	
//				index = [[FT steps] count]-1; 
//			}
//
//			[self selectRowAtIndex:index];
//			[self setCurrentView];
//			[FTview reloadData];
//			
//			[boxPlay setHidden:YES];
//			[boxExport setHidden:YES];
		}
		break;
		
		case 2:	//RESET
		{
			[FT removeAllCamera];
			[FTview reloadData];
			self.hidePlayBox = YES;
			self.hideExportBox = YES;
		}
		break;
		
		case 3:	//IMPORT
		{
			NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
			[oPanel setAllowsMultipleSelection:NO];
			[oPanel setCanChooseDirectories:NO];
			int result = [oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"xml"]];

			if (result == NSOKButton) 
			{	
				NSDictionary* stepsDictionary = [[NSDictionary alloc] initWithContentsOfFile: [[oPanel filenames] objectAtIndex:0]];
				[FT setFromDictionary: stepsDictionary];
				[stepsDictionary release];
				
				[self updateThumbnails];
				[FTview reloadData];
			}
		}
		break;
		
		case 4: //SAVE
		{
			NSSavePanel     *panel = [NSSavePanel savePanel];

			[panel setCanSelectHiddenExtension:NO];
			[panel setRequiredFileType:@"xml"];

			if( [panel runModalForDirectory:0L file:@"OsiriX Fly Through"] == NSFileHandlingPanelOKButton)
			{
				NSMutableDictionary *xml;
				xml = [FT exportToXML];
				[xml writeToFile:[panel filename] atomically: TRUE];
				//[xml release];
			}
		}
		break;
	}
}

- (IBAction) flyThruButton:(id) sender
{
	[self flyThruTag: [sender selectedSegment]];
}

- (void) setCurrentView
{
	if ([[FT steps] count]>0)
	{
		int index = [FTview selectedRow];
		[FTAdapter setCurrentViewToCamera:[[FT steps] objectAtIndex:index]];
		[framesSlider setIntValue:[[[FT stepsPositionInPath] objectAtIndex:index] intValue]];
	}
}

- (IBAction) flyThruSetCurrentView:(id) sender
{
	[self setCurrentView];
}


- (IBAction) flyThruCompute:(id) sender
{
	int minSteps = (FT.loop)?2:3; // for the spline, 3 points are needed. (in the case of a loop, the 3rd point is added in the 'computePath' method of the FlyThru)
	int userChoice = 1;
	
	if( [FT.steps count] < 2)
	{
		NSRunAlertPanel(NSLocalizedString(@"Error",nil), NSLocalizedString(@"Add at least 2 frames for a Fly Thru.",nil), nil, nil, nil);
		return;
	}
	
	if ([FT interpolationMethod] == 1 && [FT.steps count] < minSteps)
	{
		userChoice = NSRunAlertPanel(NSLocalizedString(@"Spline Interpolation Error", nil), NSLocalizedString(@"The Spline Interpolation needs at least 3 points to be run.", nil), NSLocalizedString(@"Use Linear Interpollation", nil), NSLocalizedString(@"Cancel", nil), nil);
		if(userChoice == 1)
		{
			FT.interpolationMethod = 2; // changing the method
			// selection of the right radio button
			//[[methodChooser cellWithTag:1] setState: NSOffState]; 
			//[[methodChooser cellWithTag:2] setState: NSOnState];
		}
	}
	
	if(userChoice == 1)
	{
		int v = FT.numberOfFrames;
	
		if( v < 2) v = 2;
		if( v > 2000) v = 2000;
	
		FT.numberOfFrames = v;
		[FT computePath];
		
		// 4D
		if([controller3D is4D])
		{
			NSArray *pathCameras = [FT pathCameras];
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
		
	//	[nbFramesTextField setStringValue: [NSString stringWithFormat:@"%d",[FT numberOfFrames]]];
		
		[framesSlider setMaxValue: [FT numberOfFrames]-1];
		
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
	if ([[FT pathCameras] count]>0)
	{
		int index = [framesSlider intValue];
		if (index > FT.pathCameras.count) index = FT.pathCameras.count - 1;
		[FTAdapter setCurrentViewToCamera:[FT.pathCameras objectAtIndex:index]];
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
		
		[FTAdapter setCurrentViewToCamera:[[FT pathCameras] objectAtIndex:curMovieIndex]];
		
		// resize the window to the original size (with the 3 box)
		self.hideComputeBox = NO;
		self.hideExportBox = NO;
		
		NSPoint upperLeftCorner = [[self window] frame].origin;
		upperLeftCorner.y += [[self window] frame].size.height;

		NSPoint newUpperLeftCorner = windowFrame.origin;
		newUpperLeftCorner.y += windowFrame.size.height;

		NSPoint translation; // if the user moved the window when it was reduced, we will keep this translation
		translation.x = upperLeftCorner.x - newUpperLeftCorner.x;
		translation.y = upperLeftCorner.y - newUpperLeftCorner.y;
		
		windowFrame.origin.x += translation.x;
		windowFrame.origin.y += translation.y;
		
		[[self window] setFrame:windowFrame display:YES animate:NO];
		[boxPlay setFrameOrigin: boxPlayOrigin];
		
		[[self window] display]; // to refresh the window
		[[self window] becomeKeyWindow];
	}
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
    
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
        
        [playButton setTitle: NSLocalizedString(@"Stop", nil)];
		

		// resize the window
		NSPoint newOrigin = [boxExport frame].origin;
		self.hideComputeBox = YES;
		boxPlayOrigin = [boxPlay frame].origin;
		
		windowFrame = [[self window] frame];
		
		[[self window] setFrame:NSMakeRect(	windowFrame.origin.x,
											windowFrame.origin.y+[boxCompute frame].size.height+[boxExport frame].size.height,
											windowFrame.size.width,
											windowFrame.size.height-[boxCompute frame].size.height-[boxExport frame].size.height)
						display:YES animate:NO];
										
		[boxPlay setFrameOrigin: newOrigin];
		
		[[self window] display]; // to refresh the window
		[[self window] resignKeyWindow];
    }
}

- (void) performMovieAnimation:(id) sender
{
	NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
	short           val;
    
	val = curMovieIndex;
	val ++;
	
	if( val < 0) val = 1;
	if( val > FT.numberOfFrames) val = 1;
	
	self.currentMovieIndex = val;
	
	if( [[self window3DController] movieFrames] > 1)
	{	
		short movieIndex = curMovieIndex - 1;
		
		while( movieIndex >= [[self window3DController] movieFrames]) movieIndex -= [[self window3DController] movieFrames];
		if( movieIndex < 0) movieIndex = 0;
		
		[[self window3DController] setMovieFrame: movieIndex];
	}
	
	//[framesSlider setIntValue:curMovieIndex];
	[FTAdapter setCurrentViewToLowResolutionCamera:[[FT pathCameras] objectAtIndex:curMovieIndex - 1]];
	
	lastMovieTime = thisTime;
}

- (IBAction) flyThruQuicktimeExport :(id) sender
{
	[FTAdapter prepareMovieGenerating];

	if( exportFormat == 0)
	{
		long numberOfFrames = FT.numberOfFrames;
		
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
		long numberOfFrames = FT.numberOfFrames;
		
		if( [[self window3DController] movieFrames] > 1)
		{
			numberOfFrames /= [[self window3DController] movieFrames];
			numberOfFrames *= [[self window3DController] movieFrames];
		}
		
		Wait *progress = [[Wait alloc] initWithString:@"Creating a DICOM series"];
		[progress showWindow:self];
		[[progress progress] setMaxValue: numberOfFrames];
		
		[dcmSequence setSeriesNumber:8500 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
		[dcmSequence setSeriesDescription: dcmSeriesName];
		[dcmSequence setSourceFile: [[[controller3D pixList] objectAtIndex:0] sourceFile]];
				
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
			
			[FTAdapter setCurrentViewToCamera:[[FT pathCameras] objectAtIndex: i]];
			[FTAdapter getCurrentCameraImage: levelOfDetailType];
			
			long	width, height, spp, bpp, err;
			
			unsigned char *dataPtr = [[controller3D view] getRawPixels:&width :&height :&spp :&bpp :YES :NO];
			float	o[ 9];
			
			if( dataPtr)
			{
				[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
				[[controller3D view] getOrientation: o];
				[dcmSequence setOrientation: o];
				
				if( [controller3D isKindOfClass: [VRController class]] ||  [controller3D isKindOfClass: [VRPROController class]])
				{
					float resolution = [[controller3D view] getResolution];
					
					if( resolution)
						[dcmSequence setPixelSpacing: resolution :resolution];
				}
				
				err = [dcmSequence writeDCMFile: 0L];
				
				free( dataPtr);
				
				[progress incrementBy: 1];
			}
			
			[pool release];
		}
		
		[progress close];
		[progress release];
		
		[dcmSequence release];
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
	
		[FTAdapter setCurrentViewToCamera:[[FT pathCameras] objectAtIndex: [cur intValue]]];
		return [FTAdapter getCurrentCameraImage: levelOfDetailType];
	}
	else
	{
		[FTAdapter setCurrentViewToCamera:[[FT pathCameras] objectAtIndex: 0]];
		return [FTAdapter getCurrentCameraImage: levelOfDetailType];
	}
}




-(void) updateThumbnails
{
	NSArray *stepsCameras = [FT steps];
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


- (int)currentMovieIndex{
	return curMovieIndex;
}

- (void)setCurrentMovieIndex:(int)index{
	if ([FT.pathCameras count] > 0)
	{
		[FTAdapter setCurrentViewToCamera:[FT.pathCameras objectAtIndex:index - 1]];
	}
	curMovieIndex = index;
}

@end
