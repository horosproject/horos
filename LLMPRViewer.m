//
//  LLMPRViewer.m
//  OsiriX
//
//  Created by Joris Heuberger on 08/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

#include <Accelerate/Accelerate.h>
#import "LLMPRViewer.h"
#import "LLSubtraction.h"
#import "LLMPRView.h"
#import "LLDCMView.h"
#import "ITKSegmentation3D.h"
#import "AppController.h"
#import "VRController.h"
#import "VRControllerVPRO.h"

#define BONEVALUE 250

@class Window3DController;

extern  AppController	*appController;

static NSString* 	LLMPRToolbarIdentifier					= @"Lower Limbs MPR Viewer Toolbar Identifier";
static NSString*	ToolsToolbarItemIdentifier				= @"Tools";
static NSString*	WLWWToolbarItemIdentifier				= @"WLWW";
static NSString*	ThickSlabToolbarItemIdentifier			= @"ThickSlab";
static NSString*	Produce2DResultToolbarItemIdentifier	= @"Axial";
static NSString*	Produce3DResultToolbarItemIdentifier	= @"MIP";
static NSString*	ParameterPanelToolbarItemIdentifier		= @"3D";

@implementation LLMPRViewer

- (id) initWithPixList: (NSMutableArray*) pix : (NSMutableArray*) pixToSubstract :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC :(LLScoutViewer*)sV;
{
	[super initWithWindowNibName:@"LLMPR"];

	viewer = [vC retain]; // released in super-class
	notInjectedViewer = [bC retain];
	scoutViewer = sV;

	[[self window] setDelegate:self];
	[[self window] setShowsResizeIndicator:YES];
	[[self window] performZoom:self];
	
	NSRect selfWindowRect = [[self window] frame];
	NSRect scoutWindowRect = [[scoutViewer window] frame];
	selfWindowRect.size.width -= scoutWindowRect.size.width;
	selfWindowRect.origin.x = scoutWindowRect.size.width;
	[[self window] setFrame:selfWindowRect display:YES animate:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:@"CloseViewerNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resliceFromNotification:) name:@"LLMPRReslice" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeWLWW:) name:@"changeWLWW" object:nil];

	[splitView setDelegate:self];

	// [self updateToolbarItems];
	// initialisations
	[injectedMPRController initWithPixList: pix : files : vData : vC : nil: self];
	[(LLMPRController*)controller initWithPixList: pixToSubstract : files : vData : bC : nil: self];
	
	isFullWindow = NO;
	displayResliceAxes = 1;
	
	// thick slab
	[thickSlabTextField setStringValue:[NSString stringWithFormat:@"%d",2]];
	[thickSlabSlider setMinValue:2];
	//NSLog(@"maxValue : %d",[controller maxThickSlab]);
//	[thickSlabSlider setMaxValue:[controller maxThickSlab]];
//	[thickSlabSlider setMaxValue:40];
	
	// CLUT Menu
//	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
//	[nc addObserver: self
//           selector: @selector(UpdateCLUTMenu:)
//               name: @"UpdateCLUTMenu"
//             object: nil];
//	[nc postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
//
//	// WL/WW Menu	
	curWLWWMenu = NSLocalizedString(@"Other", nil);
	[nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	[nc postNotificationName: @"UpdateWLWWMenu" object:curWLWWMenu userInfo:0L];
		
	subtractedOriginalBuffer = 0L;
	subtractedXReslicedBuffer = 0L;
	subtractedYReslicedBuffer = 0L;
	
	xShift = 0;
	yShift = 0;
	zShift = 0;
	
	[self setInitialDefaultParametersValues];
		
	closingRadius = 2;
	displayBones = NO;
	bonesThreshold = 200;
	
	return self;
}

-(void)setPixListRange:(NSRange)range;
{
	pixListRange = range;
	[injectedMPRController setPixListRange:range];
	[(LLMPRController*)controller setPixListRange:range];
}

- (void)dealloc
{	
	//NSLog(@"LLMPRViewer dealloc");
	if(subtractedOriginalBuffer)
	{
		free(subtractedOriginalBuffer);
		subtractedOriginalBuffer = 0L;
	}
	if(subtractedXReslicedBuffer)
	{
		free(subtractedXReslicedBuffer);
		subtractedXReslicedBuffer = 0L;
	}
	if(subtractedYReslicedBuffer)
	{
		free(subtractedYReslicedBuffer);
		subtractedYReslicedBuffer = 0L;
	}
	
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[notInjectedViewer release];
	//[scoutViewer release];
	[super dealloc];
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	[injectedMPRController showViews:sender];
	[[injectedMPRController originalView] setFusion:0 :1];
	[[controller originalView] setFusion:0 :1];
	[self refreshSubtractedViews];
}

- (IBAction)changeTool:(id)sender
{
	[super changeTool:sender];
	[injectedMPRController setCurrentTool: [[sender selectedCell] tag]];
}

- (void)toggleDisplayResliceAxes
{
	if(!isFullWindow)
	{
		displayResliceAxes++;
		if( displayResliceAxes >= 3) displayResliceAxes = 0;
		[controller toggleDisplayResliceAxes:self];
		[injectedMPRController toggleDisplayResliceAxes:self];
	}
}

- (void)blendingPropagate:(LLDCMView*)sender;
{
	//NSLog(@"LLMPRViewer blendingPropagate");
	if ([sender isEqual:subtractedOriginalView])
	{	
		[self blendingPropagateOriginal:sender];
	}
	else if ([sender isEqual:subtractedXReslicedView])
	{
		[self blendingPropagateX:sender];
	}
	else if ([sender isEqual:subtractedYReslicedView])
	{
		[self blendingPropagateY:sender];
	}
}

- (void)blendingPropagateOriginal:(OrthogonalMPRView*)sender
{
	// MPR Views
	[controller blendingPropagateOriginal: sender];
	[injectedMPRController blendingPropagateOriginal: sender];

	// Subtracted Views
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[subtractedOriginalView setScaleValue: fValue * [subtractedOriginalView pixelSpacing]];
	[subtractedOriginalView setRotation: [sender rotation]];
	[subtractedOriginalView setOrigin: [sender origin]];
	[subtractedOriginalView setOriginOffset: [sender originOffset]];
	
	NSPoint		pt;
	
	// X - Views
	[subtractedXReslicedView setScaleValue: fValue * [subtractedXReslicedView pixelSpacing]];
	
	pt.y = [subtractedXReslicedView origin].y;
	pt.x = [sender origin].x;
	[subtractedXReslicedView setOrigin: pt];

	pt.y = [subtractedXReslicedView originOffset].y;
	pt.x = [sender originOffset].x;
	[subtractedXReslicedView setOriginOffset: pt];
	
	// Y - Views
	[subtractedYReslicedView setScaleValue: fValue * [subtractedYReslicedView pixelSpacing]];
	
	pt.y = [subtractedYReslicedView origin].y;
	pt.x = -[sender origin].y;
	[subtractedYReslicedView setOrigin: pt];

	pt.y = [subtractedYReslicedView originOffset].y;
	pt.x = -[sender originOffset].y;
	[subtractedYReslicedView setOriginOffset: pt];
	
	[subtractedOriginalView setNeedsDisplay:YES];
}

- (void)blendingPropagateX:(OrthogonalMPRView*)sender
{
	// MPR Views
	[controller blendingPropagateX: sender];
	[injectedMPRController blendingPropagateX: sender];
	
	// Subtracted Views
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[subtractedXReslicedView setScaleValue: fValue * [subtractedXReslicedView pixelSpacing]];
	[subtractedXReslicedView setRotation: [sender rotation]];
	[subtractedXReslicedView setOrigin: [sender origin]];
	[subtractedXReslicedView setOriginOffset: [sender originOffset]];
	
	NSPoint		pt;
	
	// X - Views
	[subtractedOriginalView setScaleValue: fValue * [subtractedOriginalView pixelSpacing]];
	
	pt.y = [subtractedOriginalView origin].y;
	pt.x = [sender origin].x;
	[subtractedOriginalView setOrigin: pt];

	pt.y = [subtractedOriginalView originOffset].y;
	pt.x = [sender originOffset].x;
	[subtractedOriginalView setOriginOffset: pt];

	// Y - Views
	[subtractedYReslicedView setScaleValue: fValue * [subtractedYReslicedView pixelSpacing]];
	
	pt.x = [subtractedYReslicedView origin].x;
	pt.y = [sender origin].y;
	[subtractedYReslicedView setOrigin: pt];

	pt.x = [subtractedYReslicedView originOffset].x;
	pt.y = [sender originOffset].y;
	[subtractedYReslicedView setOriginOffset: pt];
	
	[subtractedXReslicedView setNeedsDisplay:YES];
}

- (void) blendingPropagateY:(OrthogonalMPRView*) sender
{
	// MPR Views
	[controller blendingPropagateY: sender];
	[injectedMPRController blendingPropagateY: sender];
	
	// Subtracted Views
	float fValue = [sender scaleValue] / [sender pixelSpacing];
	[subtractedYReslicedView setScaleValue: fValue * [subtractedYReslicedView pixelSpacing]];
	[subtractedYReslicedView setRotation: [sender rotation]];
	[subtractedYReslicedView setOrigin: [sender origin]];
	[subtractedYReslicedView setOriginOffset: [sender originOffset]];
	
	NSPoint		pt;
	
	// X - Views
	[subtractedOriginalView setScaleValue: fValue * [subtractedOriginalView pixelSpacing]];
	
	pt.x = [subtractedOriginalView origin].x;
	pt.y = -[sender origin].x;
	[subtractedOriginalView setOrigin: pt];

	pt.x = [subtractedOriginalView originOffset].x;
	pt.y = -[sender originOffset].x;
	[subtractedOriginalView setOriginOffset: pt];

	// Y - Views
	[subtractedXReslicedView setScaleValue: fValue * [subtractedXReslicedView pixelSpacing]];
	
	pt.x = [subtractedXReslicedView origin].x;
	pt.y = [sender origin].y;
	[subtractedXReslicedView setOrigin: pt];

	pt.x = [subtractedXReslicedView originOffset].x;
	pt.y = [sender originOffset].y;
	[subtractedXReslicedView setOriginOffset: pt];
	
	[subtractedYReslicedView setNeedsDisplay:YES];
}

- (void)changeWLWW:(NSNotification*)note;
{
//	if([[[injectedMPRController originalView] dcmPixList] count]==0 || [[[injectedMPRController xReslicedView] dcmPixList] count]==0 || [[[injectedMPRController yReslicedView] dcmPixList] count]==0) return;
//	if([[[controller originalView] dcmPixList] count]==0 || [[[controller xReslicedView] dcmPixList] count]==0 || [[[controller yReslicedView] dcmPixList] count]==0) return;
//	if([[subtractedOriginalView dcmPixList] count]==0 || [[subtractedXReslicedView dcmPixList] count]==0 || [[subtractedYReslicedView dcmPixList] count]==0) return;
	
	DCMPix	*otherPix = [note object];
		
	if( [[controller originalDCMPixList] containsObject: otherPix] || [[injectedMPRController originalDCMPixList] containsObject: otherPix] || [[subtractedOriginalView dcmPixList] containsObject: otherPix] || [[subtractedXReslicedView dcmPixList] containsObject: otherPix] || [[subtractedYReslicedView dcmPixList] containsObject: otherPix])
	{
		float iwl, iww;		
		iww = [otherPix ww];
		iwl = [otherPix wl];
																					
		if( iww != [[[controller originalView] curDCM] ww] || iwl != [[[controller originalView] curDCM] wl])
			[controller setWLWW: iwl :iww];
		if( iww != [[[injectedMPRController originalView] curDCM] ww] || iwl != [[[injectedMPRController originalView] curDCM] wl])
			[injectedMPRController setWLWW: iwl :iww];
		if( iww != [[subtractedOriginalView curDCM] ww] || iwl != [[subtractedOriginalView curDCM] wl])
			[subtractedOriginalView setWLWW: iwl :iww];
		if( iww != [[subtractedXReslicedView curDCM] ww] || iwl != [[subtractedXReslicedView curDCM] wl])
			[subtractedXReslicedView setWLWW: iwl :iww];
		if( iww != [[subtractedYReslicedView curDCM] ww] || iwl != [[subtractedYReslicedView curDCM] wl])
			[subtractedYReslicedView setWLWW: iwl :iww];
	}
}

- (IBAction) resetImage:(id) sender
{
	[injectedMPRController resetImage];
	[super resetImage:sender];
	[self refreshSubtractedViews];
}


- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == viewer || [note object] == notInjectedViewer)
	{
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[self window] setDelegate:nil];
	[self release];
}

#pragma mark-
#pragma mark MPR

- (void) resliceFromNotification: (NSNotification*) notification;
{
//NSLog(@"LLMPRViewer resliceFromNotification");
	if(injectedMPRController==nil) return;
	if(controller==nil) return;
	
	if([injectedMPRController thickSlab]!=[controller thickSlab] || [injectedMPRController thickSlabMode]!=[controller thickSlabMode])
		return;
	
	[injectedMPRController resliceFromNotification: notification];
	[(LLMPRController*)controller resliceFromNotification: notification];

	if([[[injectedMPRController originalView] dcmPixList] count]==0 || [[[injectedMPRController xReslicedView] dcmPixList] count]==0 || [[[injectedMPRController yReslicedView] dcmPixList] count]==0)
		return;
	if([[[controller originalView] dcmPixList] count]==0 || [[[controller xReslicedView] dcmPixList] count]==0 || [[[controller yReslicedView] dcmPixList] count]==0)
		return;
	[self refreshSubtractedViews];
}

- (void)refreshSubtractedViews;
{
	NSAutoreleasePool *tempPool;
	
	DCMPix *curPix;
	int width, height;
	float pixelSpacingX, pixelSpacingY;
	
	float *buffer, *resampledBuffer;
	long byteCount;
	float fValue;
	NSMutableArray *axialPixList, *coronalPixList, *sagitalPixList;
	int i, minI, maxI;

	// axial
	if(thickSlabMode != 0)
	{
		minI = [[injectedMPRController originalView] curImage];
		maxI = minI + thickSlab;
		
		minI = (minI<0)? 0: minI;
		//maxI = (maxI>=[[[injectedMPRController originalView] curDCM] pheight])? [[[injectedMPRController originalView] curDCM] pheight]-1 : maxI;
		maxI = (maxI>=[[[injectedMPRController originalView] dcmPixList] count])? [[[injectedMPRController originalView] dcmPixList] count]-1 : maxI;
	}
	else
	{
		minI = [[injectedMPRController originalView] curImage];
		maxI = minI + 1;
	}

	axialPixList = [[NSMutableArray alloc] initWithCapacity:maxI-minI];
	DCMPix *newAxialPix;
	
	width = [[[[injectedMPRController originalView] dcmPixList] objectAtIndex:0] pwidth];
	height = [[[[injectedMPRController originalView] dcmPixList] objectAtIndex:0] pheight];
	pixelSpacingX = [[[[injectedMPRController originalView] dcmPixList] objectAtIndex:0] pixelSpacingX];
	pixelSpacingY = [[[[injectedMPRController originalView] dcmPixList] objectAtIndex:0] pixelSpacingY];
	
	BOOL resample = (xShift%4 != 0) || (yShift%4 != 0);
	
	//tempPool = [[NSAutoreleasePool alloc] init];
	for(i=minI; i<maxI; i++)
	{
		curPix = [[[injectedMPRController originalView] dcmPixList] objectAtIndex:i];
		buffer = [curPix fImage];
		byteCount = width*height*sizeof(float);
		
		if(subtractedOriginalBuffer)
		{	
			free(subtractedOriginalBuffer);
			subtractedOriginalBuffer = 0L;
		}
		subtractedOriginalBuffer = malloc(byteCount);

		memcpy(subtractedOriginalBuffer,buffer,byteCount);
		
		if(resample)
		{
			resampledBuffer = malloc(byteCount*16);
			[self resampleBuffer:subtractedOriginalBuffer withWidth:width height:height factor:4.0 inNewBuffer:resampledBuffer];
			[self applyShiftX:xShift y:yShift toBuffer:resampledBuffer withWidth:width*4 height:height*4];
			[self resampleBuffer:resampledBuffer withWidth:width*4 height:height*4 factor:0.25 inNewBuffer:subtractedOriginalBuffer];
			free(resampledBuffer);
		}
		else
		{
			[self applyShiftX:xShift/4 y:yShift/4 toBuffer:subtractedOriginalBuffer withWidth:width height:height];
		}
		//newAxialPix = [[[DCMPix alloc] initwithdata:subtractedOriginalBuffer :32 :width :height :pixelSpacingX :pixelSpacingY :[curPix originX] :[curPix originY] :[curPix originZ]] autorelease];
		newAxialPix = [[DCMPix alloc] initwithdata:subtractedOriginalBuffer :32 :width :height :pixelSpacingX :pixelSpacingY :[curPix originX] :[curPix originY] :[curPix originZ]];
		[LLSubtraction subtractDCMPix:[[[controller originalView] dcmPixList] objectAtIndex:i] to:newAxialPix minValueA:injectedMinValue maxValueA:injectedMaxValue minValueB:notInjectedMinValue maxValueB:notInjectedMaxValue minValueSubtraction:subtractionMinValue maxValueSubtraction:subtractionMaxValue displayBones:displayBones bonesThreshold:bonesThreshold];// subtraction
		[LLSubtraction dilate:[newAxialPix fImage] withWidth:width height:height structuringElementRadius:dilatationRadius];
		[LLSubtraction close:[newAxialPix fImage] withWidth:width height:height structuringElementRadius:closingRadius];
		//[LLSubtraction removeSmallConnectedPartDCMPix:newAxialPix];
				
		[axialPixList addObject:newAxialPix];
		[newAxialPix release];
	}
	//[tempPool release];

	[subtractedOriginalView setDCM:axialPixList :nil :nil :0 :'i' :YES];
	
	for( i = 0; i < [axialPixList count]; i++)
	{
		[[axialPixList objectAtIndex: i] setArrayPix: axialPixList :i];
	}
	[subtractedOriginalView setFusion:thickSlabMode :thickSlab];
	
	fValue = [[controller originalView] scaleValue] / [[controller originalView] pixelSpacing];
	[subtractedOriginalView setScaleValue: fValue * [subtractedOriginalView pixelSpacing]];
	[subtractedOriginalView setRotation: [[controller originalView] rotation]];
	[subtractedOriginalView setOrigin: [[controller originalView] origin]];
	[subtractedOriginalView setOriginOffset: [[controller originalView] originOffset]];
	
	[axialPixList release];
//	[newAxialPix release];

	// coronal
	if(thickSlabMode != 0)
	{
		minI = [[injectedMPRController originalView] crossPositionY]-floor((float)[(LLMPRView*)[injectedMPRController xReslicedView] thickSlabX]/2.0);
		maxI = [[injectedMPRController originalView] crossPositionY]+ceil((float)[(LLMPRView*)[injectedMPRController xReslicedView] thickSlabX]/2.0);
					
		minI = (minI<0)? 0: minI;
		maxI = (maxI>=[[[injectedMPRController originalView] curDCM] pheight])? [[[injectedMPRController originalView] curDCM] pheight]-1 : maxI;
	}
	else
	{
		minI = 0;
		maxI = 1;
	}

	coronalPixList = [[NSMutableArray alloc] initWithCapacity:maxI-minI];
	DCMPix *newCoronalPix;
	
	width = [[[[injectedMPRController xReslicedView] dcmPixList] objectAtIndex:0] pwidth];
	height = [[[[injectedMPRController xReslicedView] dcmPixList] objectAtIndex:0] pheight];
	pixelSpacingX = [[[[injectedMPRController xReslicedView] dcmPixList] objectAtIndex:0] pixelSpacingX];
	pixelSpacingY = [[[[injectedMPRController xReslicedView] dcmPixList] objectAtIndex:0] pixelSpacingY];
	
	resample = (xShift%4 != 0) || (zShift%4 != 0);
	
	//tempPool = [[NSAutoreleasePool alloc] init];
	//for(i=0; i<[[[injectedMPRController xReslicedView] dcmPixList] count]; i++)
	for(i=0; i<maxI-minI; i++)
	{
		curPix = [[[injectedMPRController xReslicedView] dcmPixList] objectAtIndex:i];
		buffer = [curPix fImage];
		byteCount = [curPix pwidth]*[curPix pheight]*sizeof(float);
		
		if(subtractedXReslicedBuffer)
		{
			free(subtractedXReslicedBuffer);
			subtractedXReslicedBuffer = 0L;
		}
		subtractedXReslicedBuffer = malloc(byteCount);
		
		memcpy(subtractedXReslicedBuffer,buffer,byteCount);
		
		if(resample)
		{
			resampledBuffer = malloc(byteCount*16);
			[self resampleBuffer:subtractedXReslicedBuffer withWidth:width height:height factor:4.0 inNewBuffer:resampledBuffer];
			[self applyShiftX:xShift y:zShift toBuffer:resampledBuffer withWidth:width*4 height:height*4];
			[self resampleBuffer:resampledBuffer withWidth:width*4 height:height*4 factor:0.25 inNewBuffer:subtractedXReslicedBuffer];
			free(resampledBuffer);
		}
		else
		{
			[self applyShiftX:xShift/4 y:zShift/4 toBuffer:subtractedXReslicedBuffer withWidth:width height:height];
		}
		//newCoronalPix = [[[DCMPix alloc] initwithdata :subtractedXReslicedBuffer :32 :width :height :pixelSpacingX :pixelSpacingY :[curPix originX] :[curPix originY] :[curPix originZ]] autorelease];
		newCoronalPix = [[DCMPix alloc] initwithdata :subtractedXReslicedBuffer :32 :width :height :pixelSpacingX :pixelSpacingY :[curPix originX] :[curPix originY] :[curPix originZ]];
		[LLSubtraction subtractDCMPix:[[[controller xReslicedView] dcmPixList] objectAtIndex:i] to:newCoronalPix minValueA:injectedMinValue maxValueA:injectedMaxValue minValueB:notInjectedMinValue maxValueB:notInjectedMaxValue minValueSubtraction:subtractionMinValue maxValueSubtraction:subtractionMaxValue displayBones:displayBones bonesThreshold:bonesThreshold];// subtraction
		[LLSubtraction dilate:[newCoronalPix fImage] withWidth:width height:height structuringElementRadius:dilatationRadius];
		[LLSubtraction close:[newCoronalPix fImage] withWidth:width height:height structuringElementRadius:closingRadius];
		//[LLSubtraction removeSmallConnectedPartDCMPix:newCoronalPix];
		
		[coronalPixList addObject:newCoronalPix];
		[newCoronalPix release];
	}
	//[tempPool release];

	[subtractedXReslicedView setDCM:coronalPixList :nil :nil :[[injectedMPRController xReslicedView] curImage] :'i' :YES];
	
	for( i = 0; i < [coronalPixList count]; i++)
	{
		[[coronalPixList objectAtIndex: i] setArrayPix: coronalPixList :i];
	}
	[subtractedXReslicedView setFusion:thickSlabMode :[(LLMPRView*)[injectedMPRController xReslicedView] thickSlabX]];
	
	fValue = [[controller xReslicedView] scaleValue] / [[controller xReslicedView] pixelSpacing];
	[subtractedXReslicedView setScaleValue: fValue * [subtractedXReslicedView pixelSpacing]];
	[subtractedXReslicedView setRotation: [[controller xReslicedView] rotation]];
	[subtractedXReslicedView setOrigin: [[controller xReslicedView] origin]];
	[subtractedXReslicedView setOriginOffset: [[controller xReslicedView] originOffset]];
		
	[coronalPixList release];
//	[newCoronalPix release];

	// sagital
		
	if(thickSlabMode != 0)
	{
		minI = [[injectedMPRController originalView] crossPositionX]-floor((float)[(LLMPRView*)[injectedMPRController yReslicedView] thickSlabX]/2.0);
		maxI = [[injectedMPRController originalView] crossPositionX]+ceil((float)[(LLMPRView*)[injectedMPRController yReslicedView] thickSlabX]/2.0);
					
		minI = (minI<0)? 0: minI;
		maxI = (maxI>=[[[injectedMPRController originalView] curDCM] pwidth])? [[[injectedMPRController originalView] curDCM] pwidth]-1 : maxI;
	}
	else
	{
		minI = 0;
		maxI = 1;
	}
	
	sagitalPixList = [[NSMutableArray alloc] initWithCapacity:maxI-minI];
	DCMPix *newSagitalPix;

	width = [[[[injectedMPRController yReslicedView] dcmPixList] objectAtIndex:0] pwidth];
	height = [[[[injectedMPRController yReslicedView] dcmPixList] objectAtIndex:0] pheight];
	pixelSpacingX = [[[[injectedMPRController yReslicedView] dcmPixList] objectAtIndex:0] pixelSpacingX];
	pixelSpacingY = [[[[injectedMPRController yReslicedView] dcmPixList] objectAtIndex:0] pixelSpacingY];
	
	resample = (yShift%4 != 0) || (zShift%4 != 0);
	
	//tempPool = [[NSAutoreleasePool alloc] init];
	//for(i=0; i<[[[injectedMPRController yReslicedView] dcmPixList] count]; i++)
	for(i=0; i<maxI-minI; i++)
	{
		curPix = [[[injectedMPRController yReslicedView] dcmPixList] objectAtIndex:i];
		buffer = [curPix fImage];
		byteCount = [curPix pwidth]*[curPix pheight]*sizeof(float);
		
		if(subtractedYReslicedBuffer)
		{
			free(subtractedYReslicedBuffer);
			subtractedYReslicedBuffer = 0L;
		}
		subtractedYReslicedBuffer = malloc(byteCount);
	
		memcpy(subtractedYReslicedBuffer,buffer,byteCount);

		if(resample)
		{
			resampledBuffer = malloc(byteCount*16);
			[self resampleBuffer:subtractedYReslicedBuffer withWidth:width height:height factor:4.0 inNewBuffer:resampledBuffer];
			[self applyShiftX:yShift y:zShift toBuffer:resampledBuffer withWidth:width*4 height:height*4];
			[self resampleBuffer:resampledBuffer withWidth:width*4 height:height*4 factor:0.25 inNewBuffer:subtractedYReslicedBuffer];
			free(resampledBuffer);
		}
		else
		{
			[self applyShiftX:yShift/4 y:zShift/4 toBuffer:subtractedYReslicedBuffer withWidth:width height:height];
		}
		//newSagitalPix = [[[DCMPix alloc] initwithdata :subtractedYReslicedBuffer :32 :width :height :pixelSpacingX :pixelSpacingY :[curPix originX] :[curPix originY] :[curPix originZ]] autorelease];
		newSagitalPix = [[DCMPix alloc] initwithdata :subtractedYReslicedBuffer :32 :width :height :pixelSpacingX :pixelSpacingY :[curPix originX] :[curPix originY] :[curPix originZ]];
		[LLSubtraction subtractDCMPix:[[[controller yReslicedView] dcmPixList] objectAtIndex:i] to:newSagitalPix minValueA:injectedMinValue maxValueA:injectedMaxValue minValueB:notInjectedMinValue maxValueB:notInjectedMaxValue minValueSubtraction:subtractionMinValue maxValueSubtraction:subtractionMaxValue displayBones:displayBones bonesThreshold:bonesThreshold];// subtraction
		[LLSubtraction dilate:[newSagitalPix fImage] withWidth:width height:height structuringElementRadius:dilatationRadius];
		[LLSubtraction close:[newSagitalPix fImage] withWidth:width height:height structuringElementRadius:closingRadius];
		//[LLSubtraction removeSmallConnectedPartDCMPix:newSagitalPix];
		
		[sagitalPixList addObject:newSagitalPix];
		[newSagitalPix release];
	}
	//[tempPool release];

	[subtractedYReslicedView setDCM:sagitalPixList :nil :nil :[[injectedMPRController yReslicedView] curImage] :'i' :YES];

	for( i = 0; i < [sagitalPixList count]; i++)
	{
		[[sagitalPixList objectAtIndex: i] setArrayPix: sagitalPixList :i];
	}
	[subtractedYReslicedView setFusion:thickSlabMode :[(LLMPRView*)[injectedMPRController yReslicedView] thickSlabX]];
	
	fValue = [[controller yReslicedView] scaleValue] / [[controller yReslicedView] pixelSpacing];
	[subtractedYReslicedView setScaleValue: fValue * [subtractedYReslicedView pixelSpacing]];
	[subtractedYReslicedView setRotation: [[controller yReslicedView] rotation]];
	[subtractedYReslicedView setOrigin: [[controller yReslicedView] origin]];
	[subtractedYReslicedView setOriginOffset: [[controller yReslicedView] originOffset]];

	[sagitalPixList release];
//	[newSagitalPix release];
	
	float iwl, iww;
	[[injectedMPRController originalView] getWLWW:&iwl :&iww];
	
	[subtractedOriginalView discretelySetWLWW: iwl : iww];
	[subtractedXReslicedView discretelySetWLWW: iwl : iww];
	[subtractedYReslicedView discretelySetWLWW: iwl : iww];
}

#pragma mark-
#pragma mark Thick Slab

- (IBAction)setThickSlabMode:(id)sender;
{
	[self _setThickSlabMode:[[sender selectedItem] tag]];
}

- (void)_setThickSlabMode:(int)mode;
{
	thickSlabMode = mode;
	
	if(mode==0)
	{
		[thickSlabSlider setIntValue:0];
		[thickSlabTextField setIntValue:2];
		[thickSlabSlider setEnabled:NO];
		thickSlab = [thickSlabSlider intValue];
		[injectedMPRController setThickSlab:0];
		[controller setThickSlab:0];
	}
	else
	{
		thickSlab = [thickSlabSlider intValue];
		[injectedMPRController setThickSlab: [thickSlabSlider intValue]];
		[controller setThickSlab: [thickSlabSlider intValue]];
		[thickSlabSlider setEnabled:YES];
	}
	
	[injectedMPRController setThickSlabMode : mode];
	[controller setThickSlabMode : mode];
	[thickSlabModePopUp selectItemWithTag:mode];
	
	[self refreshSubtractedViews];
}

- (IBAction)setThickSlab:(id)sender;
{
	[injectedMPRController setThickSlab:[sender intValue]];
	[super setThickSlab: sender];
	thickSlab = [sender intValue];
	[self refreshSubtractedViews];
}

#pragma mark-
#pragma mark NSToolbar Related Methods

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: LLMPRToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
   
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton: YES];
	[[[self window] toolbar] setVisible: YES];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	ToolsToolbarItemIdentifier,
										WLWWToolbarItemIdentifier,
										Produce2DResultToolbarItemIdentifier,
										Produce3DResultToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarSeparatorItemIdentifier,
										WLWWToolbarItemIdentifier,
										ToolsToolbarItemIdentifier,
										ThickSlabToolbarItemIdentifier,
										Produce2DResultToolbarItemIdentifier,
										Produce3DResultToolbarItemIdentifier,
										ParameterPanelToolbarItemIdentifier,
										nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
	if([itemIdent isEqual: ToolsToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"Change the mouse function",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: toolsView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	else if([itemIdent isEqualToString: WLWWToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"WL/WW & CLUT", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Modify WL/WW & CLUT", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: WLWWView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];

		[[wlwwPopup cell] setUsesItemFromMenu:YES];
	}
	else if([itemIdent isEqual: ThickSlabToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: ThickSlabView];
	//	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]), NSHeight([ThickSlabView frame]))];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]) + 200, NSHeight([ThickSlabView frame]))];
    }
	else if([itemIdent isEqual: Produce2DResultToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"2D Result", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"2D Result", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"2D Result",nil)];
		[toolbarItem setImage: [NSImage imageNamed: Produce2DResultToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(produceResultInMemory:)];
    }
	else if([itemIdent isEqual: Produce3DResultToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"3D Result", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Result", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"3D Result",nil)];
		[toolbarItem setImage: [NSImage imageNamed: Produce3DResultToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(produce3DResult:)];
    }
	else if([itemIdent isEqual: ParameterPanelToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Parameters", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Parameters", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Parameters",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ParameterPanelToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showParametersPanel:)];
    }	
    else
	{
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
     return [toolbarItem autorelease];
}

- (void) setWLWW:(float) iwl :(float) iww
{
	[super setWLWW:iwl :iww];
	[injectedMPRController setWLWW: iwl : iww];
	[injectedMPRController setCurWLWWMenu:curWLWWMenu];
//	curWLWWMenu = NSLocalizedString(@"Other", 0L);
}

-(void) windowDidBecomeKey:(NSNotification *)aNotification
{
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	//[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
}

#pragma mark-
#pragma mark Shift

- (int)xShift { return xShift; }
- (int)yShift { return yShift; }
- (int)zShift { return zShift; }

- (void)shiftSubtractionX:(int)deltaX y:(int)deltaY z:(int)deltaZ;
{
	xShift += deltaX;
	yShift += deltaY;
	zShift += deltaZ;
	//NSLog(@"shiftSubtractionX : %d, %d, %d", xShift, yShift, zShift);
	[xShiftTextField setIntValue:xShift];
	[yShiftTextField setIntValue:yShift];
	[zShiftTextField setIntValue:zShift];
}

- (void)applyShiftX:(int)x y:(int)y toBuffer:(float*)buffer withWidth:(int)width height:(int)height;
{
	if(x==0 && y==0) return;
	
	float *tempBuffer = malloc(width*height*sizeof(float));
	
	if(tempBuffer)
	{
		int i,j;
		
		// shift Y
		if(y > 0)
		{
			for(i=0; i<y*width; i++)
			{
				tempBuffer[i] = -1000;
			}
			memcpy(tempBuffer+y*width, buffer, (height-y)*width*sizeof(float));
			memcpy(buffer, tempBuffer, height*width*sizeof(float));
		}
		else if (y < 0)
		{
			memcpy(tempBuffer, buffer-y*width, (height+y)*width*sizeof(float));
			for(i=(height+y)*width; i<height*width; i++)
			{
				tempBuffer[i] = -1000;
			}
			memcpy(buffer, tempBuffer, height*width*sizeof(float));
		}

		// shift X
		if(x > 0)
		{
			for(i=0; i<height; i++)
			{
				for(j=0; j<x; j++)
					tempBuffer[i*width+j] = -1000;
				memcpy(tempBuffer+i*width+x, buffer+i*width, (width-x)*sizeof(float));
			}
		}
		else if(x < 0)
		{
			for(i=0; i<height; i++)
			{
				memcpy(tempBuffer+i*width, buffer+i*width-x, (width+x)*sizeof(float));
				for(j=width+x; j<width; j++)
					tempBuffer[i*width+j] = -1000;
			}
		}
		
		memcpy(buffer, tempBuffer, height*width*sizeof(float));
		free(tempBuffer);
	}
}

- (void)applyShiftZ:(int)z toDCMPixList:(NSMutableArray*)pixList;
{
	if(z==0) return;
	
	int n, width, height, byteCount, i, j;
	float *newBuffer;
	
	DCMPix *firstPix = [pixList objectAtIndex: 0];
	width = [firstPix pwidth];
	height = [firstPix pheight];
	byteCount = width*height*sizeof(float);
	
	n = abs(z);
	while(n-->=0)
	{
		// create an "empty" slice (black)
		newBuffer = malloc(byteCount);
		if(newBuffer)
		{
			for(i=0; i<height; i++)
				for(j=0; j<width; j++)
					newBuffer[i*width+j] = -1000;
			DCMPix *newDCMPix = [[DCMPix alloc] initwithdata:newBuffer :32 :width :height :[firstPix pixelSpacingX] :[firstPix pixelSpacingY] :[firstPix originX] :[firstPix originY] :[firstPix originZ]];
			float o[9];
			[firstPix orientation: o];
			[newDCMPix setOrientation:o];
			[newDCMPix setSliceThickness:[firstPix sliceThickness]];
			[newDCMPix setSliceInterval:[firstPix sliceInterval]];
			
			if(z<0)
			{
				[pixList removeLastObject];
				[pixList insertObject:newDCMPix atIndex:0];
			}
			else
			{
				[pixList removeObjectAtIndex:0];
				[pixList addObject:newDCMPix];
			}
			[newDCMPix release];
			free(newBuffer);
		}
	}
}

- (void)resampleBuffer:(float*)buffer withWidth:(int)width height:(int)height factor:(float)factor inNewBuffer:(float*)newBuffer;
{
	vImage_Buffer	srcVimage, dstVimage;
	
	srcVimage.data = buffer;
	srcVimage.height =  height;
	srcVimage.width = width;
	srcVimage.rowBytes = width*4;
	
	dstVimage.data = newBuffer;
	dstVimage.height =  height*factor;
	dstVimage.width = width*factor;
	dstVimage.rowBytes = width*factor*4;
	
	vImageScale_PlanarF(&srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
}

#pragma mark-
#pragma mark Bones removal

- (void)removeBonesAtX:(int)x y:(int)y z:(int)z;
{
	#if !__LP64__
	QDDisplayWaitCursor( true);
	#endif
	
	[[injectedMPRController reslicer] freeYCache];
	
	[injectedMPRController saveCrossPositions];
	
	NSLog( @">>>> Bone Removal Start");
	
	long seed[3];
	
	seed[0] = (long) x;
	seed[1] = (long) y;
	seed[2] = (long) z;
	NSLog( @"seed : %d, %d, %d", x, y, z);
	NSMutableDictionary	*roiList =	[ITKSegmentation3D fastGrowingRegionWithVolume:		[notInjectedViewer volumePtr]
																			width:		[[[notInjectedViewer pixList] objectAtIndex: 0] pwidth]
																			height:		[[[notInjectedViewer pixList] objectAtIndex: 0] pheight]
																			depth:		[[notInjectedViewer pixList] count]
																		seedPoint:		seed
																			from:		BONEVALUE
																		pixList:		[notInjectedViewer pixList]];		
	NSLog( @">>>> Growing3D");
	// Dilatation
	NSLog( @"dilate");
	[notInjectedViewer applyMorphology: [roiList allValues] action:@"dilate" radius: 10 sendNotification:NO];
	NSLog( @"erode");
	[notInjectedViewer applyMorphology: [roiList allValues] action:@"erode" radius: 6 sendNotification:NO];
	
	// Bone Removal
	NSNumber		*nsnewValue	= [NSNumber numberWithFloat: -1000];
	NSNumber		*nsminValue	= [NSNumber numberWithFloat: -99999];
	NSNumber		*nsmaxValue	= [NSNumber numberWithFloat: 99999];
	NSNumber		*nsoutside	= [NSNumber numberWithBool: NO];
	NSMutableArray	*roiToProceed = [NSMutableArray array];
	NSArray			*keys = [roiList allKeys];
	int				i;

	for( i = 0 ; i < [keys count]; i++)
	{
		NSLog( @"i : %d", i);
		NSLog( @"keys : %@", [keys objectAtIndex: i]);
	}


	NSLog( @"for");
	for( i = 0 ; i < [keys count]; i++)
	{
		NSLog( @"i : %d", i);
		NSLog( @"[keys objectAtIndex: i] : %@", [keys objectAtIndex: i]);
		NSLog( @"[[notInjectedViewer pixList] indexOfObject: [keys objectAtIndex: i]] : %d", [[notInjectedViewer pixList] indexOfObject: [keys objectAtIndex: i]]);
		DCMPix	*injectedDCM = [[viewer pixList] objectAtIndex: [[notInjectedViewer pixList] indexOfObject: [keys objectAtIndex: i]]];
		
		[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [roiList objectForKey: [keys objectAtIndex: i]], @"roi", injectedDCM, @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", 0L]];
	}
	NSLog( @"end for");
	[viewer roiSetStartScheduler: roiToProceed];
	
	// Update views
	[injectedMPRController restoreCrossPositions];

	[self refreshSubtractedViews];
	
	#if !__LP64__
	QDDisplayWaitCursor( true);
	#endif
}

#pragma mark-
#pragma mark 2D/3D Result
- (void)produceResultData:(NSMutableData**)volumeData pixList:(NSMutableArray*)pix;
{
	long				i;
	float				*fVolumePtr;
	
	// First calculate the amount of memory needed for the new serie
	NSMutableArray	*pixList = [injectedMPRController originalDCMPixList];		
	DCMPix			*curPix;
	long			mem = 0;
	
	int maxI = ([[controller originalDCMPixList] count] > [pixList count]) ? [pixList count] : [[controller originalDCMPixList] count] ;
	//NSLog(@"maxI: %d", maxI);
	for( i = 0; i < maxI; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	
	fVolumePtr = malloc(mem);
	//NSLog(@"mem: %d", mem);

	if( fVolumePtr)
	{		
		DCMPix *newAxialPix;
		float *buffer, *resampledBuffer;
		int curWidth, curHeight, byteCount;
		float o[9];
		
		curWidth = [[pixList objectAtIndex: 0] pwidth];
		curHeight = [[pixList objectAtIndex: 0] pheight];
		
		NSMutableArray	*pixListTemp = [NSMutableArray arrayWithArray:pixList];

		if(pixListTemp)
		{
			[self applyShiftZ:zShift toDCMPixList:pixListTemp];
			pixList = pixListTemp;
		}
		
		BOOL resample = (xShift%4 != 0) || (yShift%4 != 0);
		
		// Create a scheduler
		id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
		
		// Create the work units.
		NSMutableSet *unitsSet = [NSMutableSet set];
		for(i=0; i<maxI; i++)
		{
			curPix = [pixList objectAtIndex: i];
			newAxialPix = [curPix copy];
			[pix addObject: newAxialPix];
			[newAxialPix setArrayPix: pix :i];
			[newAxialPix release];
		
			[unitsSet addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: i], @"slice", pixList, @"pixList", pix, @"pix", [NSValue valueWithPointer:fVolumePtr + i*curWidth*curHeight], @"volumePtr", 0L]];
		}
		
		// Perform work schedule
		[sched performScheduleForWorkUnits:unitsSet];
		
		while( [sched numberOfDetachedThreads] > 0)
		{
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
		
		[sched release];
		
//		for(i=0; i<maxI; i++)
//		{
//			curPix = [pixList objectAtIndex: i];
//			buffer = [curPix fImage];
//			byteCount = curWidth*curHeight*sizeof(float);
//			
//			BlockMoveData(buffer,fVolumePtr,byteCount);
//			
//			if(resample)
//			{
//				resampledBuffer = malloc(byteCount*16);
//				[self resampleBuffer:fVolumePtr withWidth:curWidth height:curHeight factor:4.0 inNewBuffer:resampledBuffer];
//				[self applyShiftX:xShift y:yShift toBuffer:resampledBuffer withWidth:curWidth*4 height:curHeight*4];
//				[self resampleBuffer:resampledBuffer withWidth:curWidth*4 height:curHeight*4 factor:0.25 inNewBuffer:fVolumePtr];
//				free(resampledBuffer);
//			}
//			else
//			{
//				[self applyShiftX:xShift/4 y:yShift/4 toBuffer:resampledBuffer withWidth:curWidth height:curHeight];
//			}
//			//newAxialPix = [[DCMPix alloc] initwithdata:fVolumePtr :32 :curWidth :curHeight :[curPix pixelSpacingX] :[curPix pixelSpacingY] :[curPix originX] :[curPix originY] :[curPix originZ] :YES];
//			
//			newAxialPix = [curPix copy];
//			[newAxialPix setfImage: fVolumePtr];
//			
//			[LLSubtraction subtractDCMPix:[[controller originalDCMPixList] objectAtIndex: i] to:newAxialPix minValueA:injectedMinValue maxValueA:injectedMaxValue minValueB:notInjectedMinValue maxValueB:notInjectedMaxValue minValueSubtraction:subtractionMinValue maxValueSubtraction:subtractionMaxValue displayBones:displayBones bonesThreshold:bonesThreshold];// subtraction
//			[LLSubtraction dilate:[newAxialPix fImage] withWidth:curWidth height:curHeight structuringElementRadius:dilatationRadius];
//			[LLSubtraction close:[newAxialPix fImage] withWidth:curWidth height:curHeight structuringElementRadius:closingRadius];
//			[LLSubtraction removeSmallConnectedPartDCMPix:newAxialPix];
//			
//			[pix addObject: newAxialPix];
//			[newAxialPix setArrayPix: pix :i];
//			[newAxialPix release];
//			
//			fVolumePtr += byteCount/4;
//		}
		
		// Create a NSData object to control the new pointer
		*volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES]; 
	}
	
	if([*volumeData length]< mem || [pix count]==0)
	{
		//NSLog(@"Not enough memory");
		NSRunCriticalAlertPanel(@"Memory Error", @"Not enough memory", @"OK", nil, nil);
	}
	else
	{
		//NSLog(@"[volumeData length] : %d", [*volumeData length]);
		//NSLog(@"[pix count] : %d", [pix count]);
	}
}

-(void) performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator			*enumerator = [workUnits objectEnumerator];
	NSDictionary			*object;
	
	while (object = [enumerator nextObject])
	{
		DCMPix			*newAxialPix, *curPix;
		float			*buffer, *resampledBuffer, *fVolumePtr;
		int				i, curWidth, curHeight, byteCount;
		NSArray			*pixList;
		NSMutableArray	*pix;
		
		i = [[object objectForKey:@"slice"] intValue];
		pixList = [object objectForKey:@"pixList"];
		pix = [object objectForKey:@"pix"];
		fVolumePtr = [[object objectForKey:@"volumePtr"] pointerValue];
		
		curPix = [pixList objectAtIndex: i];
		curWidth = [curPix pwidth];
		curHeight = [curPix pheight];
		
		buffer = [curPix fImage];
		byteCount = curWidth*curHeight*sizeof(float);
		
		memcpy(fVolumePtr,buffer,byteCount);
		
		BOOL resample = (xShift%4 != 0) || (yShift%4 != 0);
		
		if(resample)
		{
			resampledBuffer = malloc(byteCount*16);
			[self resampleBuffer:fVolumePtr withWidth:curWidth height:curHeight factor:4.0 inNewBuffer:resampledBuffer];
			[self applyShiftX:xShift y:yShift toBuffer:resampledBuffer withWidth:curWidth*4 height:curHeight*4];
			[self resampleBuffer:resampledBuffer withWidth:curWidth*4 height:curHeight*4 factor:0.25 inNewBuffer:fVolumePtr];
			free(resampledBuffer);
		}
		else
		{
			[self applyShiftX:xShift/4 y:yShift/4 toBuffer:resampledBuffer withWidth:curWidth height:curHeight];
		}
		//newAxialPix = [[DCMPix alloc] initwithdata:fVolumePtr :32 :curWidth :curHeight :[curPix pixelSpacingX] :[curPix pixelSpacingY] :[curPix originX] :[curPix originY] :[curPix originZ] :YES];
		
		newAxialPix = [pix objectAtIndex: i];
		[newAxialPix setfImage: fVolumePtr];
		
		[LLSubtraction subtractDCMPix:[[controller originalDCMPixList] objectAtIndex: i] to:newAxialPix minValueA:injectedMinValue maxValueA:injectedMaxValue minValueB:notInjectedMinValue maxValueB:notInjectedMaxValue minValueSubtraction:subtractionMinValue maxValueSubtraction:subtractionMaxValue displayBones:displayBones bonesThreshold:bonesThreshold];// subtraction
		[LLSubtraction dilate:[newAxialPix fImage] withWidth:curWidth height:curHeight structuringElementRadius:dilatationRadius];
		[LLSubtraction close:[newAxialPix fImage] withWidth:curWidth height:curHeight structuringElementRadius:closingRadius];
		//[LLSubtraction removeSmallConnectedPartDCMPix:newAxialPix];
	}
}


- (void)produceResultInMemory:(id)sender;
{
	[self _setThickSlabMode:0];
	if(parametersPanel) [parametersPanel close];
	
	NSMutableData *volumeData = [[NSMutableData alloc] initWithLength:0];
	NSMutableArray *pix = [[NSMutableArray alloc] initWithCapacity:0];
	[self produceResultData:&volumeData pixList:pix];
	
	if([volumeData length]==0 || [pix count]==0) return;
	
	NSMutableArray * newFileArray = [NSMutableArray arrayWithArray:[[[self viewer] fileList] subarrayWithRange:NSMakeRange(0,[pix count])]];
	
	//NSLog(@"new2DViewer");
	ViewerController *new2DViewer;
	new2DViewer = [[self viewer] newWindow:pix :newFileArray :volumeData];
	
	[pix release];
	[volumeData release];
	
	[new2DViewer roiDeleteAll:self];
}

- (void)produce3DResult:(id)sender;
{
	[self _setThickSlabMode:0];	
	if(parametersPanel) [parametersPanel close];
	
	Window3DController *vrPanel;
//	if( [VRPROController available])
//	{
//		vrPanel = [appController FindViewer :@"VRVPRO" :pix];
//	}
//	else
//	{
//		vrPanel = [appController FindViewer :@"VRPanel" :pix];
//	}
//	
//	if( vrPanel)
//	{
//		[[vrPanel window] makeKeyAndOrderFront:self];
//	}
//	else
//	{
		NSMutableData *volumeData = [[NSMutableData alloc] initWithLength:0];
		NSMutableArray *pix = [[NSMutableArray alloc] initWithCapacity:0];
		[self produceResultData:&volumeData pixList:pix];
		
//		NSLog(@"[volumeData length] : %d", [volumeData length]);
//		NSLog(@"[pix count] : %d", [pix count]);
		
		if([volumeData length]==0 || [pix count]==0) return;
		
		NSArray * newFileArray = [NSArray arrayWithArray:[[[self viewer] fileList] subarrayWithRange:NSMakeRange(0,[pix count])]];
						
		if( [VRPROController available])
			vrPanel = [[VRPROController alloc] initWithPix:pix :newFileArray :(NSData*)volumeData :nil :viewer mode:@"VR"];
		else
			vrPanel = [[VRController alloc] initWithPix:pix :newFileArray :(NSData*)volumeData :nil :viewer style:@"standard" mode:@"VR"];
		
		[pix release];		
		[volumeData release];
		
		//			for( i = 1; i < maxMovieIndex; i++)
		//			{
		//				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
		//			}
		
		[vrPanel load3DState];
		[vrPanel ApplyOpacityString:NSLocalizedString(@"Logarithmic Inverse Table", nil)];
		
		[[vrPanel view] setMode: 0];
		[[vrPanel view] coView:self];
		float   iwl, iww;
		[subtractedOriginalView getWLWW:&iwl :&iww];
		[vrPanel setWLWW:iwl :iww];
		
		[vrPanel showWindow:self];
		[[vrPanel window] makeKeyAndOrderFront:self];
		[[vrPanel window] display];
		[[vrPanel window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
//	}
}

#pragma mark-
#pragma mark Subtraction Parameters

- (void)showParametersPanel:(id)sender;
{
	[parametersPanel orderFront:sender];
}

- (IBAction)setParameterValue:(id)sender;
{
	[self setInjectedMinValue:[injectedMinValueSlider intValue]];
	[self setInjectedMaxValue:[injectedMaxValueSlider intValue]];
	[self setNotInjectedMinValue:[notInjectedMinValueSlider intValue]];
	[self setNotInjectedMaxValue:[notInjectedMaxValueSlider intValue]];
	[self setSubtractionMinValue:[subtractionMinValueSlider intValue]];
	[self setSubtractionMaxValue:[subtractionMaxValueSlider intValue]];
	
	[injectedMinValueTextField setStringValue:[NSString stringWithFormat:@"%d", [injectedMinValueSlider intValue]]];
	[injectedMaxValueTextField setStringValue:[NSString stringWithFormat:@"%d", [injectedMaxValueSlider intValue]]];
	[notInjectedMinValueTextField setStringValue:[NSString stringWithFormat:@"%d", [notInjectedMinValueSlider intValue]]];
	[notInjectedMaxValueTextField setStringValue:[NSString stringWithFormat:@"%d", [notInjectedMaxValueSlider intValue]]];
	[subtractionMinValueTextField setStringValue:[NSString stringWithFormat:@"%d", [subtractionMinValueSlider intValue]]];
	[subtractionMaxValueTextField setStringValue:[NSString stringWithFormat:@"%d", [subtractionMaxValueSlider intValue]]];
	
	[self refreshSubtractedViews];
}

- (IBAction)resetParametersSliders:(id)sender;
{
	[injectedMinValueSlider setIntValue:[injectedMinValueSlider minValue]];
	[injectedMaxValueSlider setIntValue:[injectedMaxValueSlider maxValue]];
	[notInjectedMinValueSlider setIntValue:[notInjectedMinValueSlider minValue]];
	[notInjectedMaxValueSlider setIntValue:[notInjectedMaxValueSlider maxValue]];
	[subtractionMinValueSlider setIntValue:[subtractionMinValueSlider minValue]];
	[subtractionMaxValueSlider setIntValue:[subtractionMaxValueSlider maxValue]];
	
	[injectedMinValueSlider setNeedsDisplay:YES];
	[injectedMaxValueSlider setNeedsDisplay:YES];
	[notInjectedMinValueSlider setNeedsDisplay:YES];
	[notInjectedMaxValueSlider setNeedsDisplay:YES];
	[subtractionMinValueSlider setNeedsDisplay:YES];
	[subtractionMaxValueSlider setNeedsDisplay:YES];
	
	[self setParameterValue:self];
}

- (IBAction)defaultValuesParametersSliders:(id)sender;
{
	NSDictionary *defaultValues = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"LLSubtractionParametersValues"];
	[injectedMinValueSlider setIntValue:[[defaultValues objectForKey:@"injectedMinValue"] intValue]];
	[injectedMaxValueSlider setIntValue:[[defaultValues objectForKey:@"injectedMaxValue"] intValue]];
	[notInjectedMinValueSlider setIntValue:[[defaultValues objectForKey:@"notInjectedMinValue"] intValue]];
	[notInjectedMaxValueSlider setIntValue:[[defaultValues objectForKey:@"notInjectedMaxValue"] intValue]];
	[subtractionMinValueSlider setIntValue:[[defaultValues objectForKey:@"subtractionMinValue"] intValue]];
	[subtractionMaxValueSlider setIntValue:[[defaultValues objectForKey:@"subtractionMaxValue"] intValue]];
	
	[injectedMinValueSlider setNeedsDisplay:YES];
	[injectedMaxValueSlider setNeedsDisplay:YES];
	[notInjectedMinValueSlider setNeedsDisplay:YES];
	[notInjectedMaxValueSlider setNeedsDisplay:YES];
	[subtractionMinValueSlider setNeedsDisplay:YES];
	[subtractionMaxValueSlider setNeedsDisplay:YES];
	
	[self setParameterValue:self];
}

- (IBAction)saveParametersValuesAsDefault:(id)sender;
{
	NSMutableDictionary *parametersValues = [NSMutableDictionary dictionary];
	
	[parametersValues setValue:[NSNumber numberWithInt:[injectedMinValueSlider intValue]] forKey:@"injectedMinValue"];
	[parametersValues setValue:[NSNumber numberWithInt:[injectedMaxValueSlider intValue]] forKey:@"injectedMaxValue"];
	[parametersValues setValue:[NSNumber numberWithInt:[notInjectedMinValueSlider intValue]] forKey:@"notInjectedMinValue"];
	[parametersValues setValue:[NSNumber numberWithInt:[notInjectedMaxValueSlider intValue]] forKey:@"notInjectedMaxValue"];
	[parametersValues setValue:[NSNumber numberWithInt:[subtractionMinValueSlider intValue]] forKey:@"subtractionMinValue"];
	[parametersValues setValue:[NSNumber numberWithInt:[subtractionMaxValueSlider intValue]] forKey:@"subtractionMaxValue"];
	
	[[NSUserDefaults standardUserDefaults] setObject:parametersValues forKey:@"LLSubtractionParametersValues"];
}

- (void)setInitialDefaultParametersValues;
{
	injectedMinValue = 10;
	injectedMaxValue = 500;
	notInjectedMinValue = -30;
	notInjectedMaxValue = 100;
	subtractionMinValue = 20;
	subtractionMaxValue = 500;

	if([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"LLSubtractionParametersValues"])
		return;
		
	NSMutableDictionary *parametersValues = [NSMutableDictionary dictionary];
	
	[parametersValues setValue:[NSNumber numberWithInt:injectedMinValue] forKey:@"injectedMinValue"];
	[parametersValues setValue:[NSNumber numberWithInt:injectedMaxValue] forKey:@"injectedMaxValue"];
	[parametersValues setValue:[NSNumber numberWithInt:notInjectedMinValue] forKey:@"notInjectedMinValue"];
	[parametersValues setValue:[NSNumber numberWithInt:notInjectedMaxValue] forKey:@"notInjectedMaxValue"];
	[parametersValues setValue:[NSNumber numberWithInt:subtractionMinValue] forKey:@"subtractionMinValue"];
	[parametersValues setValue:[NSNumber numberWithInt:subtractionMaxValue] forKey:@"subtractionMaxValue"];
	
	[[NSUserDefaults standardUserDefaults] setObject:parametersValues forKey:@"LLSubtractionParametersValues"];
}

- (int)injectedMinValue;
{
	return injectedMinValue;
}

- (int)injectedMaxValue;
{
	return injectedMaxValue;
}

- (int)notInjectedMinValue;
{
	return notInjectedMinValue;
}

- (int)notInjectedMaxValue;
{
	return notInjectedMaxValue;
}

- (int)subtractionMinValue;
{
	return subtractionMinValue;
}

- (int)subtractionMaxValue;
{
	return subtractionMaxValue;
}

- (void)setInjectedMinValue:(int)v;
{
	injectedMinValue = v;
}

- (void)setInjectedMaxValue:(int)v;
{
	injectedMaxValue = v;
}

- (void)setNotInjectedMinValue:(int)v;
{
	notInjectedMinValue = v;
}

- (void)setNotInjectedMaxValue:(int)v;
{
	notInjectedMaxValue = v;
}

- (void)setSubtractionMinValue:(int)v;
{
	subtractionMinValue = v;
}

- (void)setSubtractionMaxValue:(int)v;
{
	subtractionMaxValue = v;
}

#pragma mark-
#pragma mark Bones Display

- (IBAction)toggleDisplayBones:(id)sender;
{
	if([sender state]==NSOffState)
	{
		displayBones=NO;
		[bonesThresholdSlider setEnabled:NO];
	}
	else if([sender state]==NSOnState)
	{
		displayBones=YES;
		[bonesThresholdSlider setEnabled:YES];
	}
	[self refreshSubtractedViews];
}

- (IBAction)setBonesThreshold:(id)sender;
{
	if(!displayBones) return;
	bonesThreshold = [sender intValue];
	[bonesThresholdTextField setIntValue:bonesThreshold];
	[self refreshSubtractedViews];
}

#pragma mark-
#pragma mark Math Morphology

- (IBAction)setDilatationRadius:(id)sender;
{
	dilatationRadius = [sender intValue];
	[dilatationRadiusTextField setIntValue:dilatationRadius-1];
	//NSLog(@"setDilatationRadius : %d", dilatationRadius);
	[self refreshSubtractedViews];
}

- (IBAction)setClosingRadius:(id)sender;
{
	closingRadius = [sender intValue];
	[closingRadiusTextField setIntValue:closingRadius-1];
	//NSLog(@"setClosingRadius : %d", closingRadius);
	[self refreshSubtractedViews];
}

@end
