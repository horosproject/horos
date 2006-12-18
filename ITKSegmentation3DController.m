/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "ITKSegmentation3D.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"

#import "ITKSegmentation3DController.h"

@implementation ITKSegmentation3DController

+(id) segmentationControllerForViewer:(ViewerController*) v
{
	NSArray *winList = [NSApp windows];
	long	x;
	
	for( x = 0; x < [winList count]; x++)
	{
		if( [[[[winList objectAtIndex:x] windowController] windowNibName] isEqualToString:@"ITKSegmentation"])
		{
			if( [[[winList objectAtIndex:x] windowController] viewer] == v)
			{
				return [[winList objectAtIndex:x] windowController];
			}
		}
	}
	
	return 0L;
}

-(void) dealloc
{
	NSLog(@"ITKSegmentation3DController dealloc");
	[algorithms release];
	[parameters release];
	[defaultsParameters release];
	[urlHelp release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[viewer roiDeleteWithName:@"Segmentation Preview"];
	
	NSLog(@"windowWillClose");
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self release];
}

- (NSPoint) startingPoint
{
	return startingPoint;
}

- (ViewerController*) viewer
{
	return viewer;
}

- (id) initWithViewer:(ViewerController*) v
{
	// Is it already available for this viewer??
	id seg = [ITKSegmentation3DController segmentationControllerForViewer: v];
	if( seg) return seg;
	
	// Else create a new one !

	self = [super initWithWindowNibName:@"ITKSegmentation"];
	
	viewer = v;
	resultsViewer = 0L;
	startingPoint = NSMakePoint(0, 0);
	
	algorithms = [NSArray arrayWithObjects:	NSLocalizedString( @"Threshold (interval)", 0L),
											NSLocalizedString( @"Threshold (lower/upper bounds)", 0L),
											NSLocalizedString( @"Neighborhood", 0L),
											NSLocalizedString( @"Confidence", 0L),
											nil];
	[algorithms retain];
	
	parameters = [NSArray arrayWithObjects:	[NSArray arrayWithObjects:NSLocalizedString( @"Interval", 0L), nil],
											[NSArray arrayWithObjects:NSLocalizedString( @"Lower Threshold", 0L), NSLocalizedString( @"Upper Threshold", 0L), nil],
											[NSArray arrayWithObjects:NSLocalizedString( @"Lower Threshold", 0L), NSLocalizedString( @"Upper Threshold", 0L), NSLocalizedString( @"Radius (pix.)", 0L), nil],
											[NSArray arrayWithObjects:NSLocalizedString( @"Multiplier", 0L), NSLocalizedString( @"Num. of Iterations", 0L), NSLocalizedString( @"Initial Radius (pix.)", 0L), nil],
											nil];
	[parameters retain];
	
	defaultsParameters = [NSArray arrayWithObjects:	[NSArray arrayWithObjects:@"100", nil],
											[NSArray arrayWithObjects:@"", @"", nil],
											[NSArray arrayWithObjects:@"", @"", @"2", nil],
											[NSArray arrayWithObjects:@"2.5", @"5", @"2", nil],
											nil];
	[defaultsParameters retain];
	
	urlHelp = [NSArray arrayWithObjects:	@"http://www.itk.org/Doxygen16/html/classitk_1_1ConnectedThresholdImageFilter.html#_details",
											@"http://www.itk.org/Doxygen16/html/classitk_1_1ConnectedThresholdImageFilter.html#_details",
											@"http://www.itk.org/Doxygen16/html/classitk_1_1NeighborhoodConnectedImageFilter.html#_details",
											@"http://www.itk.org/Doxygen16/html/classitk_1_1ConfidenceConnectedImageFilter.html#_details",
											nil];
	[urlHelp retain];
	
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(mouseViewerDown:)
               name: @"mouseDown"
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];
	
	[nc addObserver: self
			selector: @selector(drawStartingPoint:)
               name: @"PLUGINdrawObjects"
             object: nil];
	
	return self;
}

-(void) CloseViewerNotification:(NSNotification*) note
{
	if( [note object] == resultsViewer) resultsViewer = 0L;
	
	if( [note object] == viewer)
	{
		[self close];
	}
}

- (void) drawStartingPoint:(NSNotification*) note
{
	if([note object] == [viewer imageView])
	{
		if( startingPoint.x != 0 && startingPoint.y != 0)
		{
			NSDictionary	*userInfo = [note userInfo];
			
			glColor3f (0.0f, 1.0f, 0.5f);
			glLineWidth(2.0);
			glBegin(GL_LINES);
			
			float crossx, crossy, scaleValue = [[userInfo valueForKey:@"scaleValue"] floatValue];
			
			crossx = startingPoint.x - [[userInfo valueForKey:@"offsetx"] floatValue];
			crossy = startingPoint.y - [[userInfo valueForKey:@"offsety"] floatValue];
			
			glVertex2f( scaleValue * (crossx - 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx - 5), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 5), scaleValue*(crossy));
			
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-40));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+40));
			glEnd();
		}
	}
}

- (void) mouseViewerDown:(NSNotification*) note
{
	if([note object] == viewer)
	{
		int xpx, ypx, zpx; // coordinate in pixels
		float xmm, ymm, zmm; // coordinate in millimeters
		
		xpx = [[[note userInfo] objectForKey:@"X"] intValue];
		ypx = [[[note userInfo] objectForKey:@"Y"] intValue];
		zpx = [[viewer imageView] curImage];
		
		float location[3];
		[[[viewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location];
		xmm = location[0];
		ymm = location[1];
		zmm = location[2];
		
		[startingPointPixelPosition setStringValue:[NSString stringWithFormat:NSLocalizedString(@"px:\t\tx:%d y:%d", 0L), xpx, ypx]];
		[startingPointWorldPosition setStringValue:[NSString stringWithFormat:NSLocalizedString(@"mm:\t\tx:%2.2f y:%2.2f z:%2.2f", 0L), xmm, ymm, zmm]];
		[startingPointValue setStringValue:[NSString stringWithFormat:NSLocalizedString(@"value:\t%2.2f", 0L), [[[viewer imageView] curDCM] getPixelValueX: xpx Y:ypx]]];
		startingPoint = NSMakePoint(xpx, ypx);
		
		[self preview: self];
	}
}

- (ViewerController*) duplicateCurrent2DViewerWindow
{
	long							i;
	ViewerController				*new2DViewer;
	unsigned char					*fVolumePtr;
	
	// We will read our current series, and duplicate it by creating a new series!
	
	// First calculate the amount of memory needed for the new serie
	NSArray		*pixList = [viewer pixList];		
	DCMPix		*curPix;
	long		mem = 0;
	
	for( i = 0; i < [pixList count]; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	
	fVolumePtr = malloc( mem);	// ALWAYS use malloc for allocating memory !
	if( fVolumePtr)
	{
		// Copy the source series in the new one !
		memcpy( fVolumePtr, [viewer volumePtr], mem);
		
		// Create a NSData object to control the new pointer
		NSData		*volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new fVolumePtr
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[pixList objectAtIndex: i] copy];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * 4 * i)];
			[newPixList addObject: curPix];
		}
		
		// We don't need to duplicate the DicomFile array, because it is identical!
		
		// A 2D Viewer window needs 3 things:
		// A mutable array composed of DCMPix objects
		// A mutable array composed of DicomFile objects
		// Number of DCMPix and DicomFile has to be EQUAL !
		// NSData volumeData contains the images, represented in the DCMPix objects
		new2DViewer = [viewer newWindow:newPixList :[viewer fileList] :volumeData];
		
		[new2DViewer roiDeleteAll:self];
		
		return new2DViewer;
	}
	
	return 0L;
}

- (void) windowDidLoad
{
	[self fillAlgorithmPopup];
	[self changeAlgorithm:self];
}

-(IBAction) preview:(id) sender
{
	BOOL parametersProvided = YES;
	int p;
	
	[viewer roiDeleteWithName:@"Segmentation Preview"];
	
	if( [previewCheck state] != NSOnState) return;
	
	for(p=0;p<[params numberOfRows]; p++)
	{
		parametersProvided = parametersProvided && (![[[params cellAtRow:p column:0] stringValue] isEqualToString:@""]);
	}
	
	if (!parametersProvided)
	{
		return;
	}
	
	if ( startingPoint.x == 0 && startingPoint.y == 0)
	{
		return;
	}

	long				slice;
	
	slice = [[viewer imageView] curImage];
	
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[viewer pixList] :[viewer volumePtr] :slice];
	if( itk)
	{
		// an array for the parameters
		int algo = [[algorithmPopup selectedItem] tag];
		int parametersCount = [[parameters objectAtIndex:algo] count];
		NSMutableArray *parametersArray = [[NSMutableArray alloc] initWithCapacity:parametersCount];
		int i;
		for(i=0; i<parametersCount; i++)
		{
			[parametersArray addObject:[NSNumber numberWithFloat:[[params cellAtRow:i column:0] floatValue]]];
		}
				
		[itk regionGrowing3D	: viewer
								: 0L
								: slice
								: startingPoint
								: algo //[[params cellAtIndex: 1] floatValue]
								: parametersArray //[[params cellAtIndex: 2] floatValue]
								: [[pixelsSet cellWithTag:0] state]==NSOnState
								: [[pixelsValue cellWithTag:0] floatValue]
								: [[pixelsSet cellWithTag:1] state]==NSOnState
								: [[pixelsValue cellWithTag:1] floatValue]
								: [[outputROIType selectedCell] tag]
								: ((long)[roiResolution maxValue] + 1) - [roiResolution intValue]
								: @"Segmentation Preview"];
		
		[itk release];
	}
}

-(IBAction) compute:(id) sender
{
	BOOL parametersProvided = YES;
	int p;
	
	for(p=0;p<[params numberOfRows]; p++)
	{
		parametersProvided = parametersProvided && (![[[params cellAtRow:p column:0] stringValue] isEqualToString:@""]);
	}
	
	if (!parametersProvided)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segmentation Error", nil), NSLocalizedString(@"Please provide a value for each parameter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	if ( startingPoint.x == 0 && startingPoint.y == 0)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segmentation Error", nil), NSLocalizedString(@"Select a starting point by clicking in the image.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	[viewer roiDeleteWithName:@"Segmentation Preview"];
	
	long				slice;
	
	if( [[growingMode selectedCell] tag] == 1)
	{
		slice = -1;
	}
	else slice = [[viewer imageView] curImage];

	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[viewer pixList] :[viewer volumePtr] :slice];
	if( itk)
	{
		ViewerController	*v = 0L;
		
		if( [[outputResult selectedCell] tag] == 1)
		{
			if( resultsViewer == 0L)
			{
				long currentImageIndex = [[viewer imageView] curImage];
				resultsViewer = [self duplicateCurrent2DViewerWindow];
				[[viewer imageView] setIndex:currentImageIndex];
				
				if( [[pixelsSet cellWithTag:1] state] == NSOnState)	// FILL THE IMAGE WITH THE VALUE
				{
					long	i, x, y, z;
					float	*dstImage, *srcImage, value = [[pixelsValue cellWithTag:1] floatValue];
					
					for( i = 0; i < [[resultsViewer pixList] count]; i++)
					{
						DCMPix	*curPix = [[resultsViewer pixList] objectAtIndex: i];
						dstImage = [curPix fImage];
						long tot = [curPix pwidth] * [curPix pheight];
						
						for( x = 0; x < tot; x++) 
						{
							*dstImage++ = value;
						}
					}
				}
			}
			
			v = resultsViewer;
		}
		
		// an array for the parameters
		int algo = [[algorithmPopup selectedItem] tag];
		int parametersCount = [[parameters objectAtIndex:algo] count];
		NSMutableArray *parametersArray = [[NSMutableArray alloc] initWithCapacity:parametersCount];
		int i;
		for(i=0; i<parametersCount; i++)
		{
			[parametersArray addObject:[NSNumber numberWithFloat:[[params cellAtRow:i column:0] floatValue]]];
		}
				
		[itk regionGrowing3D	: viewer
								: v
								: slice
								: startingPoint
								: algo //[[params cellAtIndex: 1] floatValue]
								: parametersArray //[[params cellAtIndex: 2] floatValue]
								: [[pixelsSet cellWithTag:0] state]==NSOnState
								: [[pixelsValue cellWithTag:0] floatValue]
								: [[pixelsSet cellWithTag:1] state]==NSOnState
								: [[pixelsValue cellWithTag:1] floatValue]
								: [[outputROIType selectedCell] tag]
								: ((long)[roiResolution maxValue] + 1) - [roiResolution intValue]
								: [newName stringValue]];
				
		if( v)
		{
			float wl, ww;
			
			[v needsDisplayUpdate];
			[[viewer imageView] getWLWW:&wl :&ww];
			[[v imageView] setWLWW:wl :ww];
		}
		
		[itk release];
	}
}

- (void) fillAlgorithmPopup
{
	int i;
	NSMenu *items = [[NSMenu alloc] initWithTitle:@""];

	for (i=0; i<[algorithms count]; i++)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];				
		[item setTitle: [algorithms objectAtIndex: i]];
		[item setTag:i];
		[items addItem:item];
	}
	[algorithmPopup removeAllItems];
	[algorithmPopup setMenu:items];
}

- (IBAction) changeAlgorithm: (id) sender
{
	[self setNumberOfParameters: [[parameters objectAtIndex:[[algorithmPopup selectedItem] tag]] count]];
	int i;
	
	for(i=0; i<[[parameters objectAtIndex:[[algorithmPopup selectedItem] tag]] count]; i++)
	{
		[[params cellAtRow:i column:0] setTitleWidth:-1];
		[[params cellAtRow:i column:0] setTitle:[[parameters objectAtIndex:[[algorithmPopup selectedItem] tag]] objectAtIndex:i]];
		[[params cellAtRow:i column:0] setStringValue:[[defaultsParameters objectAtIndex:[[algorithmPopup selectedItem] tag]] objectAtIndex:i]];
	}
	
	[self preview: self];
}

- (void) setNumberOfParameters: (int) n
{
	NSRect frameBefore = [params frame];
	// change the number of field in the matrix
	while (!([params numberOfRows]==0))
		[params removeRow:0];
	while (!([params numberOfRows]==n))
		[params addRow];
	// adjust the size of the matrix
	[params sizeToCells];
	NSRect frameAfter = [params frame];
	float deltaY = frameBefore.size.height - frameAfter.size.height;
	frameAfter.origin.y = frameBefore.origin.y + deltaY;
	[params setFrame:frameAfter];
	
	//adjust the size of the parameters box
	NSRect parametersBoxFrameBefore = [parametersBox frame];
	[parametersBox setContentViewMargins:NSMakeSize(14, 10)];
	[parametersBox sizeToFit];
	
	// frames
	NSRect parametersBoxFrame = [parametersBox frame];
	NSRect resultsBoxFrame = [resultsBox frame];
	NSRect computeButtonFrame = [computeButton frame];
	
	//adjust the size & position of the window
	NSRect windowFrame = [[self window] frame];
	float newWindowHeight = parametersBoxFrame.size.height+resultsBoxFrame.size.height+computeButtonFrame.size.height+20+15;
	float deltaHeight = newWindowHeight-windowFrame.size.height;
	windowFrame.origin.y -= deltaHeight;
	windowFrame.size.height = newWindowHeight;
	[[self window] setFrame:windowFrame display:NO];
	
	//adjust the position of the parameters box
	parametersBoxFrame.origin.y = windowFrame.size.height - parametersBoxFrame.size.height - 20;
	[parametersBox setFrame:parametersBoxFrame];

	//adjust the position of the results box and the compute button
	resultsBoxFrame.origin.y = parametersBoxFrame.origin.y - resultsBoxFrame.size.height - 5;
	[resultsBox setFrame:resultsBoxFrame];
	computeButtonFrame.origin.y = resultsBoxFrame.origin.y - computeButtonFrame.size.height - 5;
	[computeButton setFrame:computeButtonFrame];
	
	[[self window] display];
}

- (IBAction) changeROItype: (id) sender
{
	if ([[outputROIType selectedCell] tag]==18)
	{
		// if the user choose the Brush ROI type, then the number of point slider should be desactivated
		[numberOfPointsSlider setEnabled:NO];
	}
	else if ([[outputROIType selectedCell] tag]==11)
	{
		[numberOfPointsSlider setEnabled:YES];
	}
	
	[self preview: self];
}

- (IBAction) algorithmGetHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlHelp objectAtIndex:[[algorithmPopup selectedItem] tag]]]];
}

@end
