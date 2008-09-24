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

#if !__LP64__
#define USE3DCONNEXION 1
#else
#define USE3DCONNEXION 0
#endif

#import "SRView.h"
#import "SRController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "DCMCursor.h"
#import "DICOMExport.h"
#import "wait.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#include "vtkImageFlip.h"
#import "QuicktimeExport.h"
#import "AppController.h"
#include "vtkRIBExporter.h"
#include "vtkIVExporter.h"
#include "vtkOBJExporter.h"
#include "vtkSTLWriter.h"
#include "vtkVRMLExporter.h"
#include "vtkInteractorStyleFlight.h"

#include "vtkAbstractPropPicker.h"
#include "vtkInteractorStyle.h"
#include "vtkWorldPointPicker.h"

#include "vtkSphereSource.h"
#include "vtkAssemblyPath.h"

#include "vtkVectorText.h"
#include "vtkFollower.h"

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

#if USE3DCONNEXION
#include <3DConnexionClient/ConnexionClientAPI.h>
extern "C" 
{
	extern OSErr InstallConnexionHandlers(ConnexionMessageHandlerProc messageHandler, ConnexionAddedHandlerProc addedHandler, ConnexionRemovedHandlerProc removedHandler) __attribute__((weak_import));
}
#endif

static SRView	*snSRView = 0L;

typedef struct _xyzArray
{
	short x;
	short y;
	short z;
} xyzArray;

//static void startRendering(vtkObject*,unsigned long c, void* ptr, void*)
//{
//	SRView* mipv = (SRView*) ptr;
//	
//	//vtkRenderWindow
//	//[self renderWindow] SetAbortRender( true);
//	if( c == vtkCommand::StartEvent)
//	{
//		[mipv newStartRenderingTime];
//	}
//	
//	if( c == vtkCommand::EndEvent)
//	{
//		[mipv stopRendering];
//		[[mipv startRenderingTime] release];
//	}
//	
//	if( c == vtkCommand::AbortCheckEvent)
//	{
////		if( [[NSDate date] timeIntervalSinceDate:[mipv startRenderingTime]] > 2.0)
////		{
////			[mipv startRendering];
////			[mipv runRendering];
////		}
//	}
//}

@implementation SRView

- (void) print:(id) sender
{
	[controller print: sender];
}

-(void) restoreViewSizeAfterMatrix3DExport
{
	[self setFrame: savedViewSizeFrame];
}

- (NSRect) centerRect: (NSRect) smallRect
               inRect: (NSRect) bigRect
{
    NSRect centerRect;
    centerRect.size = smallRect.size;

    centerRect.origin.x = (bigRect.size.width - smallRect.size.width) / 2.0;
    centerRect.origin.y = (bigRect.size.height - smallRect.size.height) / 2.0;

    return (centerRect);
}

-(void) setViewSizeToMatrix3DExport
{
	savedViewSizeFrame = [self frame];
	
	NSRect windowFrame;
	
	windowFrame.origin.x = 0;
	windowFrame.origin.y = 0;
	windowFrame.size.width = [[[self window] contentView] frame].size.width;
	windowFrame.size.height = [[[self window] contentView] frame].size.height - 10;
	
	switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"EXPORTMATRIXFOR3D"])
	{
		case 0:
		break;
		
		case 1:		[self setFrame: [self centerRect: NSMakeRect(0,0,512,512) inRect: windowFrame]];	break;
		case 2:		[self setFrame: [self centerRect: NSMakeRect(0,0,768,768) inRect: windowFrame]];	break;
	}
	
	[self display];
}

- (void)getOrientationText:(char *) orientation : (float *) vector :(BOOL) inv {
	
	NSString *orientationX;
	NSString *orientationY;
	NSString *orientationZ;

	NSMutableString *optr = [NSMutableString string];
	
	if( inv)
	{
		orientationX = -vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
		orientationY = -vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
		orientationZ = -vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
	}
	else
	{
		orientationX = vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
		orientationY = vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
		orientationZ = vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
	}
	
	float absX = fabs( vector[ 0]);
	float absY = fabs( vector[ 1]);
	float absZ = fabs( vector[ 2]);
	
	// get first 3 AXIS
	for ( int i=0; i < 3; ++i) {
		if (absX>.2 && absX>=absY && absX>=absZ)
		{
			[optr appendString: orientationX]; absX=0;
		}
		else if (absY>.2 && absY>=absX && absY>=absZ)	{
			[optr appendString: orientationY]; absY=0;
		} else if (absZ>.2 && absZ>=absX && absZ>=absY) {
			[optr appendString: orientationZ]; absZ=0;
		} else break;
	}
	
	strcpy( orientation, [optr UTF8String]);
}

//- (void) getOrientationText:(char *) string : (float *) vector :(BOOL) inv
//{
//	char orientationX;
//	char orientationY;
//	char orientationZ;
//
//	char *optr = string;
//	*optr = 0;
//	
//	if( inv)
//	{
//		orientationX = -vector[ 0] < 0 ? 'R' : 'L';
//		orientationY = -vector[ 1] < 0 ? 'A' : 'P';
//		orientationZ = -vector[ 2] < 0 ? 'I' : 'S';
//	}
//	else
//	{
//		orientationX = vector[ 0] < 0 ? 'R' : 'L';
//		orientationY = vector[ 1] < 0 ? 'A' : 'P';
//		orientationZ = vector[ 2] < 0 ? 'I' : 'S';
//	}
//	
//	float absX = fabs( vector[ 0]);
//	float absY = fabs( vector[ 1]);
//	float absZ = fabs( vector[ 2]);
//	
//	int i; 
//	for (i=0; i<1; ++i)
//	{
//		if (absX>.0001 && absX>absY && absX>absZ)
//		{
//			*optr++=orientationX; absX=0;
//		}
//		else if (absY>.0001 && absY>absX && absY>absZ)
//		{
//			*optr++=orientationY; absY=0;
//		} else if (absZ>.0001 && absZ>absX && absZ>absY)
//		{
//			*optr++=orientationZ; absZ=0;
//		} else break; *optr='\0';
//	}
//}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
//	if( [cur intValue] != -1) [self Azimuth: [self rotation] / [max floatValue]];
//	return [self nsimageQuicktime];

	if( [cur intValue] != -1)
	{
		switch( rotationOrientation)
		{
			case 0:
				[self Azimuth: [self rotation] / [max floatValue]];
			break;
		
			case 1:
				[self Vertical: [self rotation] / [max floatValue]];
			break;
		}
	}
	return [self nsimageQuicktime];
}

-(NSImage*) imageForFrameVR:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] == -1)
	{
		aCamera->GetPosition( camPosition);
		aCamera->GetViewUp( camFocal);
		
		return [self nsimageQuicktime];
	}
	
	if( [max intValue] > 36)
	{
		if( [cur intValue] % numberOfFrames == 0 && [cur intValue] != 0)
		{
			aCamera->Azimuth( 360 / numberOfFrames);
			[self Vertical: - 360 / numberOfFrames];
		}
		else if([cur intValue] != 0) aCamera->Azimuth( 360 / numberOfFrames);
	}
	else
	{
		if([cur intValue] != 0) aCamera->Azimuth( 360 / numberOfFrames);
	}
	
	aCamera->OrthogonalizeViewUp();
	aCamera->ComputeViewPlaneNormal();
	
	return [self nsimageQuicktime];
}

-(IBAction) endQuicktimeSettings:(id) sender
{
	[export3DWindow orderOut:sender];
	
	[NSApp endSheet:export3DWindow returnCode:[sender tag]];
	
	numberOfFrames = [framesSlider intValue];
	
	if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [sender tag])
	{
		[self setViewSizeToMatrix3DExport];
		
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
		
		[mov createMovieQTKit: YES  :NO  :[[[[[self window] windowController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];
		
		[self restoreViewSizeAfterMatrix3DExport];
	}
}

-(float) rotation {return rotationValue;}
-(float) numberOfFrames {return numberOfFrames;}

-(void) Azimuth:(float) a
{
	aCamera->Azimuth( a);
	aCamera->OrthogonalizeViewUp();
}

-(void) Vertical:(float) a
{
	aCamera->Elevation( a);
	aCamera->OrthogonalizeViewUp();
}

- (IBAction) export3DFileFormat :(id) sender
{
	NSSavePanel     *panel = [NSSavePanel savePanel];
	
	[panel setCanSelectHiddenExtension:YES];
	
	switch( [sender tag])
	{
		case 1: [panel setRequiredFileType:@"rib"];	break;
		case 2: [panel setRequiredFileType:@"wrl"];	break;
		case 3: [panel setRequiredFileType:@"iv"];	break;
		case 4: [panel setRequiredFileType:@"obj"];	break;
		case 5: [panel setRequiredFileType:@"stl"];	break;
	}
	
	if( [panel runModalForDirectory:0L file:@"3DFile"] == NSFileHandlingPanelOKButton)
	{
		BOOL orientationSwitch = NO;
		
		if( orientationWidget)
		{
			if( orientationWidget->GetEnabled())
			{
				orientationSwitch= YES;
				[self switchOrientationWidget: self];
			}
		}
		
		WaitRendering *splashExport = [[WaitRendering alloc] init:@"Exporting..."];
		[splashExport showWindow:self];
		
		switch( [sender tag])
		{
			case 1:
			{
				vtkRIBExporter  *exporter = vtkRIBExporter::New();
				
				exporter->SetInput( [self renderWindow]);
				exporter->SetFilePrefix( [[[panel filename] stringByDeletingPathExtension] UTF8String]);
				exporter->Write();
				
				exporter->Delete();
			}
			break;
			
			case 2:
			{
				vtkVRMLExporter  *exporter = vtkVRMLExporter::New();
				
				exporter->SetInput( [self renderWindow]);
				exporter->SetFileName( [[panel filename] UTF8String]);
				exporter->Write();
				
				exporter->Delete();
			}
			break;
			
			case 3:
			{
				vtkIVExporter  *exporter = vtkIVExporter::New();
				
				exporter->SetInput( [self renderWindow]);
				exporter->SetFileName( [[panel filename] UTF8String]);
				exporter->Write();
				
				exporter->Delete();
			}
			break;
			
			case 4:
			{
				vtkOBJExporter  *exporter = vtkOBJExporter::New();
				
				exporter->SetInput( [self renderWindow]);
				exporter->SetFilePrefix( [[[panel filename] stringByDeletingPathExtension] UTF8String]);
				exporter->Write();
				
				exporter->Delete();
			}
			break;
			
			case 5:
			{
				vtkSTLWriter  *exporter = vtkSTLWriter::New();
				
				if (isoMapper[0]!=Nil)							// DDP (050326): added sanity check to avoid crashing bug.
					exporter->SetInput(isoMapper[0]->GetInput());
				else if (isoMapper[1]!=Nil)						// Can you export both surfaces to the same file ????
					exporter->SetInput(isoMapper[1]->GetInput());
				else
					exporter->SetInput(Nil);
				exporter->SetFileName( [[[panel filename] stringByDeletingPathExtension] UTF8String]);
				exporter->Write();
				
				exporter->Delete();
			}
			break;
		}
		
		[splashExport close];
		[splashExport release];
		
		if( orientationSwitch)
		{
			[self switchOrientationWidget: self];
		}

	}
}

-(IBAction) endQuicktimeVRSettings:(id) sender
{
	[export3DVRWindow orderOut:sender];
	
	[NSApp endSheet:export3DVRWindow returnCode:[sender tag]];
	
	numberOfFrames = [[VRFrames selectedCell] tag];
	
	rotationValue = 360;
	
	if( [sender tag])
	{
		NSString			*path, *newpath;
		FSRef				fsref;
		FSSpec				spec, newspec;
		QuicktimeExport		*mov;
		
		[self setViewSizeToMatrix3DExport];
		
		if( numberOfFrames == 10 || numberOfFrames == 20)
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
		else
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
		
		//[mov setCodec:kJPEGCodecType :codecHighQuality];
		
		path = [mov createMovieQTKit: NO  :NO :[[[[[self window] windowController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		if( path)
		{
			if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames*numberOfFrames];
			else
				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames];
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			[[NSFileManager defaultManager] movePath: newpath  toPath: path handler: nil];
			
			[[NSWorkspace sharedWorkspace] openFile:path];
		}
		
		[mov release];
		
		[self restoreViewSizeAfterMatrix3DExport];
	}
}

-(IBAction) exportQuicktime3DVR:(id) sender
{
	[NSApp beginSheet: export3DVRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

- (IBAction) exportQuicktime :(id) sender
{
	long i;
	
    [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
  
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }
    // Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
	}
}

- (IBAction) setCurrentdcmExport:(id) sender
{
	if( [[sender selectedCell] tag] == 1) [self checkView: dcmBox :YES];
	else [self checkView: dcmBox :NO];
}

#define DATABASEPATH @"/DATABASE.noindex/"
-(IBAction) endDCMExportSettings:(id) sender
{
	[exportDCMWindow orderOut:sender];
	
	[NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
	
	numberOfFrames = [dcmframesSlider intValue];
//	bestRenderingMode = [[dcmquality selectedCell] tag];
	if( [[dcmrotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [[dcmorientation selectedCell] tag] == 1) rotationOrientation = 1;
	else rotationOrientation = 0;
	
	if( [sender tag])
	{
		[self setViewSizeToMatrix3DExport];
		
		// CURRENT image only
		if( [[dcmExportMode selectedCell] tag] == 0)
		{
			long	width, height, spp, bpp, err;
			float	cwl, cww;
			float	o[ 9];
			
			if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
			
			//[self renderImageWithBestQuality: bestRenderingMode waitDialog: NO];
			unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
			//[self endRenderImageWithBestQuality];
			
			if( dataPtr)
			{
				[exportDCM setSourceFile: [firstObject sourceFile]];
				[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
				[exportDCM setSeriesNumber:5500];
				[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
				[self getOrientation: o];
				[exportDCM setOrientation: o];
				
//				if( aCamera->GetParallelProjection())
//					[exportDCM setPixelSpacing: [self getResolution] :[self getResolution]];
				
				NSString *f = [exportDCM writeDCMFile: 0L];
				if( f == 0L) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", 0L),  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
				
				free( dataPtr);
			}
		}
		else // A 3D sequence
		{
			long			i;
			float			o[ 9];
			DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
			
			Wait *progress = [[Wait alloc] initWithString:@"Creating a DICOM series"];
			[progress showWindow:self];
			[[progress progress] setMaxValue: numberOfFrames];
			
			[dcmSequence setSeriesNumber:5500 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			[dcmSequence setSeriesDescription: [dcmSeriesName stringValue]];
			[dcmSequence setSourceFile: [firstObject sourceFile]];
			
			//if( croppingBox->GetEnabled()) croppingBox->Off();
			
			BOOL wasPresent = NO;
	
			if( aRenderer->GetActors()->IsItemPresent( outlineRect))
			{
				aRenderer->RemoveActor( outlineRect);
				wasPresent = YES;
			}
			
			aRenderer->RemoveActor(textX);
			[self display];
			for( i = 0; i < numberOfFrames; i++)
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				
			//	[self renderImageWithBestQuality: bestRenderingMode waitDialog: NO];
				long	width, height, spp, bpp, err;
				
				unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
				
				if( dataPtr)
				{
					[self getOrientation: o];
					[dcmSequence setOrientation: o];
					
					[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
//					if( aCamera->GetParallelProjection())
//						[dcmSequence setPixelSpacing: [self getResolution] :[self getResolution]];
					
					NSString *f = [dcmSequence writeDCMFile: 0L];
					
					free( dataPtr);
				}
				
				switch( rotationOrientation)
				{
					case 0:
						[self Azimuth: (float) rotationValue / (float) numberOfFrames];
					break;
					
					case 1:
						[self Vertical: (float) rotationValue / (float) numberOfFrames];
					break;
				}
				[self display];
				[progress incrementBy: 1];
				
				[pool release];
			}
			
			if( wasPresent)
				aRenderer->AddActor(outlineRect);
			
			aRenderer->AddActor(textX);
			
//			[self endRenderImageWithBestQuality];
			
			[progress close];
			[progress release];
			
			[dcmSequence release];
		}
		
		[[BrowserController currentBrowser] checkIncoming: self];
		
		[self restoreViewSizeAfterMatrix3DExport];
	}
}

- (void) exportDICOMFile:(id) sender
{
	[self setCurrentdcmExport: dcmExportMode];
	//if( [[[self window] windowController] movieFrames] > 1) [[dcmExportMode cellWithTag:2] setEnabled: YES];
	//else [[dcmExportMode cellWithTag:2] setEnabled: NO];
	[NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	return YES;
}

-(void) runRendering
{
	if( noWaitDialog == NO)
	{
		if( [splash run] == NO)
		{
			[self renderWindow]->SetAbortRender( true);
		}
	}
}

- (NSDate*) startRenderingTime
{
	return startRenderingTime;
}

- (void) newStartRenderingTime
{
	startRenderingTime = [[NSDate date] retain];
}

-(void) startRendering
{
	if( noWaitDialog == NO)
	{
		[splash start];
	}
}

-(void) stopRendering
{
	if( noWaitDialog == NO)
	{
		[splash end];
	}
}

- (IBAction) resetImage:(id) sender
{
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
	aCamera->Dolly(1.5);
	
	aRenderer->ResetCamera();
	[self saView:self];
    [self setNeedsDisplay:YES];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == blendingController) // our blended serie is closing itself....
	{
		[self setBlendingPixSource:0L];
	}
}

# pragma mark-

- (long) getTool: (NSEvent*) event
{
	long tool;
	
	if( [event type] == NSRightMouseDown || [event type] == NSRightMouseDragged || [event type] == NSRightMouseUp) tool = tZoom;
	else if( [event type] == NSOtherMouseDown || [event type] == NSOtherMouseDragged || [event type] == NSOtherMouseUp) tool = tTranslate;
	else tool = currentTool;
	
	if (([event modifierFlags] & NSControlKeyMask))  tool = tRotate;
	if (([event modifierFlags] & NSShiftKeyMask))  tool = tZoom;
	if (([event modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
	if (([event modifierFlags] & NSAlternateKeyMask))  tool = tWL;
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSControlKeyMask))  tool = tCamera3D;
	
	return tool;
}

- (void) flagsChanged:(NSEvent *)event
{
	if( [event modifierFlags])
	{
		long tool = [self getTool: event];
		[self setCursorForView: tool];
		if( cursorSet) [cursor set];
	}
	
	[super flagsChanged: event];
}

-(id)initWithFrame:(NSRect)frame
{
	NSLog(@"SRView initWithFrame");
    if ( self = [super initWithFrame:frame] )
    {
		NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: 0L] autorelease];
		
		[self addTrackingArea: cursorTracking];
		
		splash = [[WaitRendering alloc] init:@"Rendering..."];
//		[[splash window] makeKeyAndOrderFront:self];
		
		cursor = 0L;
		isoExtractor[ 0] = isoExtractor[ 1] = 0L;
		isoResample = 0L;
		
		BisoExtractor[ 0] = BisoExtractor[ 1] = 0L;
		BisoResample = 0L;
		
		currentTool = t3DRotate;
		[self setCursorForView: currentTool];
		
		blendingController = 0L;
		blendingFactor = 0.5;
		blendingReader = 0L;
//		cbStart = 0L;
		
		exportDCM = 0L;
		
		noWaitDialog = NO;
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
			 
		point3DActorArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DPositionsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DRadiusArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DColorsArray = [[NSMutableArray alloc] initWithCapacity:0];
		
		point3DDisplayPositionArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DTextArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DPositionsStringsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DTextColorsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DTextSizesArray = [[NSMutableArray alloc] initWithCapacity:0];
		
		display3DPoints = YES;
		[self load3DPointsDefaultProperties];
		
		[self connect2SpaceNavigator];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: 0L];
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
	}
}

-(void)dealloc
{
	long i;
	
    NSLog(@"Dealloc SRView");
	
	[splash close];
	[splash release];
	[exportDCM release];
	
	if([firstObject isRGB]) free( dataFRGB);
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];

	[self setBlendingPixSource: 0L];
	
	for( i = 0 ; i < 2; i++)
	{
		[self deleteActor:i];
		[self BdeleteActor:i];
	}
	
	if( flip) flip->Delete();
	
	if( isoResample) isoResample->Delete();
	if( BisoResample) BisoResample->Delete();
	
//	cbStart->Delete();
	matrice->Delete();
	
	outlineData->Delete();
	mapOutline->Delete();
	outlineRect->Delete();
	
	reader->Delete();
    aCamera->Delete();
	textX->Delete();
	if( orientationWidget)
		orientationWidget->Delete();
	for( i = 0; i < 4; i++) oText[ i]->Delete();
	//	aRenderer->Delete();
	
    [pixList release];
    pixList = 0L;
	
	[point3DActorArray release];
	[point3DPositionsArray release];
	[point3DRadiusArray release];
	[point3DColorsArray release];
	
	[point3DDisplayPositionArray release];
	[point3DTextArray release];
	[point3DPositionsStringsArray release];
	[point3DTextColorsArray release];
	[point3DTextSizesArray release];
	
	[cursor release];
	
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	
	[destinationImage release];
		
	// 3D Connexion SpaceNavigator: Make sure the framework is installed
	#if USE3DCONNEXION
	if(InstallConnexionHandlers != NULL)
	{
		// 3D Connexion SpaceNavigator: Unregister our client and clean up all handlers
		if(snConnexionClientID) UnregisterConnexionClient(snConnexionClientID);
		CleanupConnexionHandlers();
	}
	#endif
		
    [super dealloc];
}
# pragma mark-


- (void)rightMouseDown:(NSEvent *)theEvent
{	
	noWaitDialog = YES;
	[self mouseDown:theEvent];
	noWaitDialog = NO;
}

- (void) getOrientation: (float*) o 
{
	long			i, j;
	vtkMatrix4x4	*matrix;
	
	matrix = aCamera->GetViewTransformMatrix();
	
	for( i = 0; i < 3; i++)
		for( j = 0; j < 3; j++)
			o[ 3*i + j] = matrix->GetElement( i , j);
			
	o[ 3] = -o[ 3];
	o[ 4] = -o[ 4];
	o[ 5] = -o[ 5];
}

- (void) computeOrientationText
{
	long			i, j;
	char			string[ 10];
	float			vectors[ 9];
	
	[self getOrientation: vectors];
	
	[self getOrientationText:string :vectors :YES];
	oText[ 0]->SetInput( string);
	
	[self getOrientationText:string :vectors :NO];
	oText[ 1]->SetInput( string);
	
	[self getOrientationText:string :vectors+3 :NO];
	oText[ 2]->SetInput( string);
	
	[self getOrientationText:string :vectors+3 :YES];
	oText[ 3]->SetInput( string);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	int tool = [self getTool: theEvent];
	[self setCursorForView: tool];
	
	[super otherMouseDown: theEvent];
}


- (void)mouseDragged:(NSEvent *)theEvent{
	if (_dragInProgress == NO && ([theEvent deltaX] != 0 || [theEvent deltaY] != 0)) {
			[self deleteMouseDownTimer];
		}
	if (_dragInProgress == YES) return;
	
	if (_resizeFrame){
		NSRect	newFrame = [self frame];
		NSRect	beforeFrame = [self frame];;
		NSPoint mouseLoc = [theEvent locationInWindow];	//[self convertPoint: [theEvent locationInWindow] fromView:nil];
		
		if( [theEvent modifierFlags] & NSShiftKeyMask)
		{
			newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
			newFrame.size.height = newFrame.size.width;
			
			mouseLoc.x = ([[[self window] contentView] frame].size.width - newFrame.size.width) / 2;
			mouseLoc.y = ([[[self window] contentView] frame].size.height - newFrame.size.height) / 2;
		}
		
		if( [[[self window] contentView] frame].size.width - mouseLoc.x*2 < 100)
			mouseLoc.x = ([[[self window] contentView] frame].size.width - 100) / 2;
		
		if( [[[self window] contentView] frame].size.height - mouseLoc.y*2 < 100)
			mouseLoc.y = ([[[self window] contentView] frame].size.height - 100) / 2;
		
		if( mouseLoc.x < 10)
			mouseLoc.x = 10;
		
		if( mouseLoc.y < 10)
			mouseLoc.y = 10;
			
		newFrame.origin.x = mouseLoc.x;
		newFrame.origin.y = mouseLoc.y;
		
		newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
		newFrame.size.height = [[[self window] contentView] frame].size.height - mouseLoc.y*2;
		
		[self setFrame: newFrame];
		
		aCamera->Zoom( beforeFrame.size.height / newFrame.size.height);
		
		[[self window] display];

		
		[self setNeedsDisplay:YES];
	}	
	else{
		int shiftDown;
		int controlDown;
		NSPoint mouseLocPre;
		NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];		
		switch (_tool) {
			case tRotate:
				shiftDown  = 0;
				controlDown = 1;
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self computeOrientationText];
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case t3DRotate:
				shiftDown  = 0;
				controlDown = 0;		
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self computeOrientationText];
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case tTranslate:
				shiftDown  = 1;
				controlDown = 0;
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case tZoom:				
				[self rightMouseDragged:theEvent];
				break;
			case tCamera3D:

				aCamera->Yaw( -(mouseLoc.x - _mouseLocStart.x) / 5.);
				aCamera->Pitch( (mouseLoc.y - _mouseLocStart.y) / 5.);
				aCamera->ComputeViewPlaneNormal();
				aCamera->OrthogonalizeViewUp();
				aRenderer->ResetCameraClippingRange();
				[self computeOrientationText];
				_mouseLocStart = mouseLoc;
				[self setNeedsDisplay:YES];
				break;
			default:
				break;
		}
	}	
}

- (void)rightMouseDragged:(NSEvent *)theEvent{
	int shiftDown, controlDown;
	float distance;
	NSPoint		mouseLoc,  mouseLocPre;
	mouseLocPre = mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	switch (_tool) {
		case tZoom:
			if( projectionMode != 2){
				shiftDown = 0;
				controlDown = 1;				
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
			}
			else{
				distance = aCamera->GetDistance();
				aCamera->Dolly( 1.0 + ( mouseLocPre.y - _mouseLocStart.y) / 1200.);
				aCamera->SetDistance( distance);
				aCamera->ComputeViewPlaneNormal();
				aCamera->OrthogonalizeViewUp();
				aRenderer->ResetCameraClippingRange();
				_mouseLocStart = mouseLoc;
				[self setNeedsDisplay:YES];
			}
			break;
	}

}

- (void)mouseUp:(NSEvent *)theEvent{
	[self deleteMouseDownTimer];
	
	switch (_tool) {
		case tRotate:
		case t3DRotate:
		case tTranslate:
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
			break;
		case tZoom:
			[self rightMouseUp:theEvent];
			break;
		default:
			break;
	}
		
	[super mouseUp:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent{
	NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];	
	if (_tool == tZoom && ( projectionMode != 2)) {
		int shiftDown = 0;
		int controlDown = 1;
		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
	}
		
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL		keepOn = YES;
    NSPoint		mouseLoc, mouseLocStart, mouseLocPre;
	short		tool;
	
	noWaitDialog = YES;
	tool = currentTool;
		
	if( snCloseEventTimer)
	{
		[snCloseEventTimer fire];
	}
	snStopped = YES;

	if ([theEvent type] == NSLeftMouseDown) {
		if (_mouseDownTimer) {
			[self deleteMouseDownTimer];
		}
		_mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self   selector:@selector(startDrag:) userInfo:theEvent  repeats:NO] retain];
	}

		
	mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
	_mouseLocStart = mouseLocStart;
	
	if( mouseLocStart.x < 10 && mouseLocStart.y < 10)
	{
		_resizeFrame = YES;
		return;
		/*
		NSRect	newFrame = [self frame];
		NSRect	beforeFrame;
		
		do
		{
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			
			mouseLoc = [theEvent locationInWindow];	//[self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			switch ([theEvent type])
			{
				case NSLeftMouseDragged:
					beforeFrame = [self frame];
				
					if( [[[self window] contentView] frame].size.width - mouseLoc.x*2 < 100)
						mouseLoc.x = ([[[self window] contentView] frame].size.width - 100) / 2;
					
					if( [[[self window] contentView] frame].size.height - mouseLoc.y*2 < 100)
						mouseLoc.y = ([[[self window] contentView] frame].size.height - 100) / 2;
					
					if( mouseLoc.x < 10)
						mouseLoc.x = 10;
					
					if( mouseLoc.y < 10)
						mouseLoc.y = 10;
						
					newFrame.origin.x = mouseLoc.x;
					newFrame.origin.y = mouseLoc.y;
					
					newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
					newFrame.size.height = [[[self window] contentView] frame].size.height - mouseLoc.y*2;
					
					[self setFrame: newFrame];
					
					aCamera->Zoom( beforeFrame.size.height / newFrame.size.height);
					
					[[self window] display];
					
				//	NSLog(@"%f", aCamera->GetParallelScale());
				//	NSLog(@"%f", aCamera->GetViewAngle());
				break;
				
				case NSLeftMouseUp:
					noWaitDialog = NO;
					keepOn = NO;
				break;
					
				case NSPeriodic:
					
				break;
					
				default:
				
				break;
			}
		}while (keepOn);
		
		[self setNeedsDisplay:YES];
		*/
	}
	else
	{
		if( [theEvent clickCount] > 1 && (tool != t3Dpoint))
		{
			long	pix[ 3];
			float	pos[ 3], value;
			
			vtkWorldPointPicker *picker = vtkWorldPointPicker::New();
			
			picker->Pick(mouseLocStart.x, mouseLocStart.y, 0.0, aRenderer);
			
			double wXYZ[3];
			picker->GetPickPosition(wXYZ);
			picker->Delete();
			
			double dc[3], sc[3];
			dc[0] = wXYZ[0];
			dc[1] = wXYZ[1];
			dc[2] = wXYZ[2];
			
			[self convert3Dto2Dpoint:dc :sc];
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: sc[0]*[firstObject pixelSpacingX]], @"x", [NSNumber numberWithInt: sc[1]*[firstObject pixelSpacingY]], @"y", [NSNumber numberWithInt: sc[2]], @"z",
																				0L];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"Display3DPoint" object:pixList  userInfo: dict];
			
			return;
		}
	
		_resizeFrame = NO;
		tool = [self getTool: theEvent];
		_tool = tool;
		[self setCursorForView: tool];
		
		if( tool == tRotate)
		{
			int shiftDown = 0;
			int controlDown = 1;

			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			
			/*
			do {
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					break;
				case NSLeftMouseUp:
					noWaitDialog = NO;
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					keepOn = NO;
					break;
				case NSPeriodic:
					[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
					break;
				default:
					break;
				}
			}while (keepOn);
			*/
		}
		else if( tool == t3DRotate)
		{
			int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
			int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);

			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			/*			
			do {
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
				switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					break;
				case NSLeftMouseUp:
					noWaitDialog = NO;
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					keepOn = NO;
					break;
				case NSPeriodic:
					NSLog(@"NSPeriodic 3D rotate");
					[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
					break;
				default:
					break;
				}
			}while (keepOn);
			*/
		}
		else if( tool == tTranslate)
		{
			int shiftDown = 1;
			int controlDown = 0;

			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			/*
			do {
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					break;
				case NSLeftMouseUp:
					noWaitDialog = NO;
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					keepOn = NO;
					break;
				case NSPeriodic:
					[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
					break;
				default:
					break;
				}
			}while (keepOn);
			*/
		}
		else if( tool == tZoom)
		{
			if( projectionMode != 2)
			{
				int shiftDown = 0;
				int controlDown = 1;

				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
				/*
				do {
					theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
					mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					switch ([theEvent type]) {
					case NSLeftMouseDragged:
					case NSRightMouseDragged:
						[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
						break;
					case NSLeftMouseUp:
					case NSRightMouseUp:
						noWaitDialog = NO;
						[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
						keepOn = NO;
						break;
					case NSPeriodic:
						[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
						break;
					default:
						break;
					}
				}while (keepOn);
				*/
			}
			else
			{
				// vtkCamera
				mouseLocPre = mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				//if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*3);
				/*
				do
				{
					theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
					mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
					switch ([theEvent type])
					{
					case NSLeftMouseDragged:
					case NSRightMouseDragged:
					{
						float distance = aCamera->GetDistance();
						aCamera->Dolly( 1.0 + (mouseLoc.y - mouseLocPre.y) / 1200.);
						aCamera->SetDistance( distance);
						aCamera->ComputeViewPlaneNormal();
						aCamera->OrthogonalizeViewUp();
						aRenderer->ResetCameraClippingRange();
						
						[self setNeedsDisplay:YES];
					}
					break;
					
					case NSLeftMouseUp:
					case NSRightMouseUp:
						noWaitDialog = NO;
						keepOn = NO;
						break;
						
					case NSPeriodic:
						
						break;
						
					default:
						break;
					}
					
					mouseLocPre = mouseLoc;
				}while (keepOn);
				*/
				//if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
				
				[self setNeedsDisplay:YES];
			}
		}
		else if( tool == tCamera3D)
		{
			// vtkCamera
			mouseLocPre = mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
//			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*3);
//			if( textureMapper) textureMapper->SetMaximumNumberOfPlanes( 512 / 10);
			/*
			do
			{
				
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				switch ([theEvent type])
				{
				case NSLeftMouseDragged:
				{
					aCamera->Yaw( -(mouseLoc.x - mouseLocPre.x) / 5.);
					aCamera->Pitch( (mouseLoc.y - mouseLocPre.y) / 5.);
					aCamera->ComputeViewPlaneNormal();
					aCamera->OrthogonalizeViewUp();
					aRenderer->ResetCameraClippingRange();
					
					[self computeOrientationText];
					
					[self setNeedsDisplay:YES];
				}
				break;
				
				case NSLeftMouseUp:
					noWaitDialog = NO;
					keepOn = NO;
					break;
					
				case NSPeriodic:
					
					break;
					
				default:
					break;
				}
				mouseLocPre = mouseLoc;
			}while (keepOn);
			*/
			
//			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
//			if( textureMapper) textureMapper->SetMaximumNumberOfPlanes( (int) (512 / LOD));
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == t3Dpoint)
		{
			NSEvent *artificialPKeyDown = [NSEvent keyEventWithType:NSKeyDown
												location:[theEvent locationInWindow]
												modifierFlags:nil
												timestamp:[theEvent timestamp]
												windowNumber:[theEvent windowNumber]
												context:[theEvent context]
												characters:@"p"
												charactersIgnoringModifiers:nil
												isARepeat:NO
												keyCode:112
												];
			[self keyDown:artificialPKeyDown];
			
			if (![self isAny3DPointSelected])
			{
				// add a point on the surface under the mouse click
				[self throw3DPointOnSurface: mouseLocStart.x : mouseLocStart.y];
				[self setNeedsDisplay:YES];
			}
			else
			{
				[point3DRadiusSlider setFloatValue: [[point3DRadiusArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
				[point3DColorWell setColor: [point3DColorsArray objectAtIndex:[self selected3DPointIndex]]];
				[point3DPositionTextField setStringValue:[point3DPositionsStringsArray objectAtIndex:[self selected3DPointIndex]]];
				
				//point3DDisplayPositionArray
				[point3DDisplayPositionButton setState:[[point3DDisplayPositionArray objectAtIndex:[self selected3DPointIndex]] intValue]];
				[point3DTextSizeSlider setFloatValue: [[point3DTextSizesArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
				[point3DTextColorWell setColor: [point3DTextColorsArray objectAtIndex:[self selected3DPointIndex]]];
				
				if ([theEvent clickCount]==2)
				{
					NSPoint mouseLocationOnScreen = [[controller window] convertBaseToScreen:[theEvent locationInWindow]];
					//[point3DInfoPanel setAlphaValue:0.8];
					[point3DInfoPanel	setFrame:	NSMakeRect(	mouseLocationOnScreen.x - [point3DInfoPanel frame].size.width/2.0, 
																mouseLocationOnScreen.y-[point3DInfoPanel frame].size.height-20.0,
																[point3DInfoPanel frame].size.width,
																[point3DInfoPanel frame].size.height)
										display:YES animate: NO];
					[point3DInfoPanel orderFront:self];
				}
			}
		}
		else if (_tool == tWL) {
			NSLog(@"WL do nothing");
		}
			
		else [super mouseDown:theEvent];
		
	//	croppingBox->SetHandleSize( 0.005);
	}

	noWaitDialog = NO;
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
	
	if( c == ' ')
	{
		if( aRenderer->GetActors()->IsItemPresent( outlineRect))
			aRenderer->RemoveActor( outlineRect);
		else
			aRenderer->AddActor( outlineRect);
			
		[self setNeedsDisplay: YES];
	}
	else if( c == 27)
	{
		[[[self window] windowController] offFullScreen];
	}
	else if(c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter)
	{
		if([self isAny3DPointSelected])
		{
			[self removeSelected3DPoint];
		}
		else [self yaw:-90.0];
	}
	else [super keyDown:event];
}

-(void) setCurrentTool:(short) i
{
	if(currentTool==t3Dpoint && currentTool!=i)
	{
		[self unselectAllActors];
		if ([point3DInfoPanel isVisible]) [point3DInfoPanel performClose:self];
		[self setNeedsDisplay:YES];
	}
	
    currentTool = i;
	
	if( currentTool != t3DRotate)
	{
		//if( croppingBox->GetEnabled()) croppingBox->Off();
	}
	
	[self setCursorForView: currentTool];
}

-(void) setBlendingFactor:(float) a
{
	long	i;
	float   val, ii;
	double  alpha[ 256];
	
	blendingFactor = a;
	
	if( a <= 0)
	{
		a += 256;
		
		for(i=0; i < 256; i++) 
		{
			ii = i;
			val = (a * ii) / 256.;
			
			if( val > 255) val = 255;
			if( val < 0) val = 0;
			
			alpha[ i] = val / 255.;
		}
	}
	else
	{
		if( a == 256)
		{
			for(i=0; i < 256; i++)
			{
				alpha[ i] = 1.0;
			}
		}
		else
		{
			for(i=0; i < 256; i++) 
			{
				ii = i;
				val = (256. * ii)/(256 - a);
				
				if( val > 255) val = 255;
				if( val < 0) val = 0;
				
				alpha[ i] = val / 255.0;
			}
		}
	}
		
	[self setNeedsDisplay: YES];
}

-(void) axView:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
//	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();	
	[self setNeedsDisplay:YES];
}

-(void) saView:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
//	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();	
	[self setNeedsDisplay:YES];
}

-(void) saViewOpposite:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (-1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
//	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();
	
	[self setNeedsDisplay:YES];
}

-(void) coView:(id) sender
{
	float distance = aCamera->GetDistance();
//	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, -1, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
//	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();
	
	[self setNeedsDisplay:YES];
}


-(void) setBlendingPixSource:(ViewerController*) bC
{
    long i;
	
	blendingController = bC;
	
	if( blendingController)
	{
		blendingPixList = [bC pixList];
		[blendingPixList retain];
		
		blendingData = [bC volumePtr];
		
		blendingFirstObject = [blendingPixList objectAtIndex:0];
		blendingLastObject = [blendingPixList lastObject];
		
		float blendingSliceThickness = ([blendingFirstObject sliceInterval]);
		
		if( blendingSliceThickness == 0)
		{
			NSLog(@"Blending slice interval = slice thickness!");
			blendingSliceThickness = [blendingFirstObject sliceThickness];
		}
		NSLog(@"slice: %0.2f", blendingSliceThickness);
		
		// PLAN 
		[blendingFirstObject orientation:blendingcosines];
				
		blendingReader = vtkImageImport::New();
		blendingReader->SetWholeExtent(0, [blendingFirstObject pwidth]-1, 0, [blendingFirstObject pheight]-1, 0, [blendingPixList count]-1);
		blendingReader->SetDataExtentToWholeExtent();
		blendingReader->SetDataScalarTypeToFloat();
//		blendingReader->SetDataOrigin(  [blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);
		blendingReader->SetImportVoidPointer(blendingData);
		blendingReader->SetDataSpacing( [blendingFirstObject pixelSpacingX], [blendingFirstObject pixelSpacingY], fabs( blendingSliceThickness));
		
		if( blendingSliceThickness < 0 )
		{
			blendingFlip = vtkImageFlip::New();
			blendingFlip->SetInput( blendingReader->GetOutput());
			blendingFlip->SetFlipAboutOrigin( TRUE);
			blendingFlip->SetFilteredAxis(2);
		}
		else blendingFlip = 0L;
		
		matriceBlending = vtkMatrix4x4::New();
		matriceBlending->Element[0][0] = blendingcosines[0];			matriceBlending->Element[1][0] = blendingcosines[1];			matriceBlending->Element[2][0] = blendingcosines[2];			matriceBlending->Element[3][0] = 0;
		matriceBlending->Element[0][1] = blendingcosines[3];			matriceBlending->Element[1][1] = blendingcosines[4];			matriceBlending->Element[2][1] = blendingcosines[5];			matriceBlending->Element[3][1] = 0;
		matriceBlending->Element[0][2] = blendingcosines[6];			matriceBlending->Element[1][2] = blendingcosines[7];			matriceBlending->Element[2][2] = blendingcosines[8];			matriceBlending->Element[3][2] = 0;
		matriceBlending->Element[0][3] = 0;								matriceBlending->Element[1][3] = 0;								matriceBlending->Element[2][3] = 0;								matrice->Element[3][3] = 1;

	}
	else
	{
		if( blendingReader)
		{
			matriceBlending->Delete();
			if( blendingFlip) blendingFlip->Delete();
			blendingReader->Delete();
			blendingReader = 0L;
			[blendingPixList release];
		}
	}
}

- (void) drawRect:(NSRect)aRect
{
	try
	{
		[self computeOrientationText];
		[super drawRect:aRect];
	}
	
	catch (...)
	{
		NSLog( @"Exception during drawRect... not enough memory?");
		
		if( NSRunAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.\r\rUpgrade to OsiriX 64-bit to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
			[[AppController sharedAppController] osirix64bit: self];
		
		[[self window] performSelector:@selector(performClose:) withObject:self afterDelay: 1.0];
	}
}

- (void) deleteActor:(long) actor
{
	if( isoExtractor[ actor])
	{
		aRenderer->RemoveActor( iso[ actor]);
		
		isoExtractor[ actor]->Delete();
		isoNormals[ actor]->Delete();
		isoMapper[ actor]->Delete();
		iso[ actor]->Delete();
		
		if( isoSmoother[ actor]) isoSmoother[ actor]->Delete();
		isoSmoother[ actor] = 0L;
		
		if( isoDeci[ actor]) isoDeci[ actor]->Delete();
		isoDeci[ actor] = 0L;
	}
	
	isoExtractor[ actor] = 0L;
}

- (void) BdeleteActor:(long) actor
{
	if( BisoExtractor[ actor])
	{
		aRenderer->RemoveActor( Biso[ actor]);
		
		BisoExtractor[ actor]->Delete();
		BisoNormals[ actor]->Delete();
		BisoMapper[ actor]->Delete();
		Biso[ actor]->Delete();
		if(BisoSmoother[ actor]) BisoSmoother[ actor]->Delete();
		BisoSmoother[ actor] = 0L;
		
		if(BisoDeci[ actor]) BisoDeci[ actor]->Delete();
		BisoDeci[ actor] = 0L;
	}
	
	BisoExtractor[ actor] = 0L;
}

- (void) changeActor:(long) actor :(float) resolution :(float) transparency :(float) r :(float) g :(float) b :(float) isocontour :(BOOL) useDecimate :(float) decimateVal :(BOOL) useSmooth :(long) smoothVal
{
//	[splash setCancel:YES];
	
	try
	{
	
	NSLog(@"ChangeActor IN");
		
	// RESAMPLE IMAGE ?
	
	if( resolution == 1.0)
	{
		if( isoResample) isoResample->Delete();
		isoResample = 0L;
	}
	else
	{
		if( isoResample)
		{
			if( isoResample->GetAxisMagnificationFactor( 0) != resolution)
			{
				isoResample->SetAxisMagnificationFactor(0, resolution);
				isoResample->SetAxisMagnificationFactor(1, resolution);
			}
		}
		else
		{
			isoResample = vtkImageResample::New();
			if( flip) isoResample->SetInput( flip->GetOutput());
			else isoResample->SetInput( reader->GetOutput());
			isoResample->SetAxisMagnificationFactor(0, resolution);
			isoResample->SetAxisMagnificationFactor(1, resolution);
		}
	}
	
	[self deleteActor: actor];
	
	if( isoResample)
	{
		isoExtractor[ actor] = vtkContourFilter::New();
		isoExtractor[ actor]->SetInput( isoResample->GetOutput());
		isoExtractor[ actor]->SetValue(0, isocontour);
	}
	else
	{
		isoExtractor[ actor] = vtkContourFilter::New();
		if( flip) isoExtractor[ actor]->SetInput( flip->GetOutput());
		else isoExtractor[ actor]->SetInput( reader->GetOutput());
		isoExtractor[ actor]->SetValue(0, isocontour);
	}
	
	vtkPolyData* previousOutput = isoExtractor[ actor]->GetOutput();
	
	if( useDecimate)
	{
		isoDeci[ actor] = vtkDecimatePro::New();
		isoDeci[ actor]->SetInput( previousOutput);
		isoDeci[ actor]->SetTargetReduction(decimateVal);
		isoDeci[ actor]->SetPreserveTopology( TRUE);
		
//		isoDeci[ actor]->SetFeatureAngle(60);
//		isoDeci[ actor]->SplittingOff();
//		isoDeci[ actor]->AccumulateErrorOn();
//		isoDeci[ actor]->SetMaximumError(0.3);
		
		isoDeci[ actor]->Update();
		
		previousOutput = isoDeci[ actor]->GetOutput();
		
		NSLog(@"Use Decimate : %f", decimateVal);
	}
	
	if( useSmooth)
	{
		isoSmoother[ actor] = vtkSmoothPolyDataFilter::New();
		isoSmoother[ actor]->SetInput( previousOutput);
		isoSmoother[ actor]->SetNumberOfIterations( smoothVal);
//		isoSmoother[ actor]->SetRelaxationFactor(0.05);
		
		isoSmoother[ actor]->Update();
		
		previousOutput = isoSmoother[ actor]->GetOutput();
		
		NSLog(@"Use Smooth: %d", smoothVal);
	}


	isoNormals[ actor] = vtkPolyDataNormals::New();
    isoNormals[ actor]->SetInput( previousOutput);
    isoNormals[ actor]->SetFeatureAngle(120);
	
	isoMapper[ actor] = vtkPolyDataMapper::New();
    isoMapper[ actor]->SetInput( isoNormals[ actor]->GetOutput());
    isoMapper[ actor]->ScalarVisibilityOff();
	
//	isoMapper[ actor]->GlobalImmediateModeRenderingOff();
//	isoMapper[ actor]->SetResolveCoincidentTopologyToPolygonOffset();
//	isoMapper[ actor]->SetResolveCoincidentTopologyToShiftZBuffer();
//	isoMapper[ actor]->SetResolveCoincidentTopologyToOff();
	
	iso[ actor] = vtkActor::New();
    iso[ actor]->SetMapper( isoMapper[ actor]);
    iso[ actor]->GetProperty()->SetDiffuseColor( r, g, b);
    iso[ actor]->GetProperty()->SetSpecular( .3);
    iso[ actor]->GetProperty()->SetSpecularPower( 20);
    iso[ actor]->GetProperty()->SetOpacity( transparency);
	
	iso[ actor]->SetOrigin(		[firstObject originX], [firstObject originY], [firstObject originZ]);
	iso[ actor]->SetPosition(	[firstObject originX] * matrice->Element[0][0] + [firstObject originY] * matrice->Element[1][0] + [firstObject originZ]*matrice->Element[2][0],
								[firstObject originX] * matrice->Element[0][1] + [firstObject originY] * matrice->Element[1][1] + [firstObject originZ]*matrice->Element[2][1],
								[firstObject originX] * matrice->Element[0][2] + [firstObject originY] * matrice->Element[1][2] + [firstObject originZ]*matrice->Element[2][2]);
	iso[ actor]->SetUserMatrix( matrice);

	iso[ actor]->PickableOff();

    aRenderer->AddActor( iso[ actor]);
	
	 [self setNeedsDisplay:YES];
	
	NSLog(@"ChangeActor OUT");
	
	}
	catch (...)
	{
		if( NSRunAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.\r\rUpgrade to OsiriX 64-bit to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
			[[AppController sharedAppController] osirix64bit: self];
	}
}

- (void) BchangeActor:(long) actor :(float) resolution :(float) transparency :(float) r :(float) g :(float) b :(float) isocontour :(BOOL) useDecimate :(float) decimateVal :(BOOL) useSmooth :(long) smoothVal
{
	NSLog(@"BLENDING ChangeActor IN");
//	[splash setCancel:YES];
	
	// RESAMPLE IMAGE ?
	
	if( resolution == 1.0)
	{
		if( BisoResample) BisoResample->Delete();
		
		BisoResample = 0L;
	}
	else
	{
		if( BisoResample)
		{
			if( BisoResample->GetAxisMagnificationFactor( 0) != resolution)
			{
				BisoResample->SetAxisMagnificationFactor(0, resolution);
				BisoResample->SetAxisMagnificationFactor(1, resolution);
			}
		}
		else
		{
			BisoResample = vtkImageResample::New();
			if( blendingFlip) BisoResample->SetInput( blendingFlip->GetOutput());
			else BisoResample->SetInput( blendingReader->GetOutput());
			BisoResample->SetAxisMagnificationFactor(0, resolution);
			BisoResample->SetAxisMagnificationFactor(1, resolution);
		}
	}
	
	[self BdeleteActor: actor];
	
	if( BisoResample)
	{
		BisoExtractor[ actor] = vtkContourFilter::New();
		BisoExtractor[ actor]->SetInput( BisoResample->GetOutput());
		BisoExtractor[ actor]->SetValue(0, isocontour);
	}
	else
	{
		BisoExtractor[ actor] = vtkContourFilter::New();
		if( blendingFlip) BisoExtractor[ actor]->SetInput( blendingFlip->GetOutput());
		else BisoExtractor[ actor]->SetInput( blendingReader->GetOutput());
		BisoExtractor[ actor]->SetValue(0, isocontour);
	}
	
	vtkPolyData* previousOutput = BisoExtractor[ actor]->GetOutput();
	
	if( useDecimate)
	{
		BisoDeci[ actor] = vtkDecimatePro::New();
		BisoDeci[ actor]->SetInput( previousOutput);
		BisoDeci[ actor]->SetTargetReduction(decimateVal);
		BisoDeci[ actor]->SetPreserveTopology( TRUE);
	
		BisoDeci[ actor]->Update();
		
		previousOutput = BisoDeci[ actor]->GetOutput();
		
		NSLog(@"Use Decimate");
	}
	
	if( useSmooth)
	{
		BisoSmoother[ actor] = vtkSmoothPolyDataFilter::New();
		BisoSmoother[ actor]->SetInput( BisoDeci[ actor]->GetOutput());
		BisoSmoother[ actor]->SetNumberOfIterations( smoothVal);
		
		BisoSmoother[ actor]->Update();
		
		previousOutput = BisoSmoother[ actor]->GetOutput();
		
		NSLog(@"Use Smooth");
	}
	
	BisoNormals[ actor] = vtkPolyDataNormals::New();
	BisoNormals[ actor]->SetInput( previousOutput); // set skinSmooth as new Input
	BisoNormals[ actor]->SetFeatureAngle(120);
	
	BisoMapper[ actor] = vtkPolyDataMapper::New();
    BisoMapper[ actor]->SetInput( BisoNormals[ actor]->GetOutput());
    BisoMapper[ actor]->ScalarVisibilityOff();
	
	Biso[ actor] = vtkActor::New();
    Biso[ actor]->SetMapper( BisoMapper[ actor]);
    Biso[ actor]->GetProperty()->SetDiffuseColor( r, g, b);
    Biso[ actor]->GetProperty()->SetSpecular( .3);
    Biso[ actor]->GetProperty()->SetSpecularPower( 20);
    Biso[ actor]->GetProperty()->SetOpacity( transparency);
	
	Biso[ actor]->SetOrigin(	[blendingFirstObject originX], [blendingFirstObject originY], [blendingFirstObject originZ]);
	
	Biso[ actor]->SetPosition(	[blendingFirstObject originX] * matriceBlending->Element[0][0] + [blendingFirstObject originY] * matriceBlending->Element[1][0] + [blendingFirstObject originZ]*matriceBlending->Element[2][0],
								[blendingFirstObject originX] * matriceBlending->Element[0][1] + [blendingFirstObject originY] * matriceBlending->Element[1][1] + [blendingFirstObject originZ]*matriceBlending->Element[2][1],
								[blendingFirstObject originX] * matriceBlending->Element[0][2] + [blendingFirstObject originY] * matriceBlending->Element[1][2] + [blendingFirstObject originZ]*matriceBlending->Element[2][2]);
	Biso[ actor]->SetUserMatrix( matriceBlending);
	
    aRenderer->AddActor( Biso[ actor]);
	
	 [self setNeedsDisplay:YES];
	
	NSLog(@"BLENDING ChangeActor OUT");
}

- (short) setPixSource:(NSMutableArray*)pix :(float*) volumeData
{
	short   error = 0;
	
	try
	{
		
		long	i;
		
		[pix retain];
		pixList = pix;
		
		projectionMode = 0;
		
		data = volumeData;
		
		aRenderer = [self renderer];
	//	cbStart = vtkCallbackCommand::New();
	//	cbStart->SetCallback( startRendering);
	//	cbStart->SetClientData( self);
		
	//	[self renderWindow]->AddObserver(vtkCommand::StartEvent, cbStart);
	//	[self renderWindow]->AddObserver(vtkCommand::EndEvent, cbStart);
	//	[self renderWindow]->AddObserver(vtkCommand::AbortCheckEvent, cbStart);
		
	//	aRenderer->AddObserver(vtkCommand::StartEvent, cbStart);
	//	aRenderer->AddObserver(vtkCommand::EndEvent, cbStart);

		firstObject = [pixList objectAtIndex:0];
		float sliceThickness = [firstObject sliceInterval]; //[[pixList objectAtIndex:1] sliceLocation] - [firstObject sliceLocation];
		
		if( sliceThickness == 0)
		{
			NSLog(@"slice interval = slice thickness!");
			sliceThickness = [firstObject sliceThickness];
		}
		
		NSLog(@"sliceThickness: %2.2f", sliceThickness);
		
		// Convert float to char
		
		if( [firstObject isRGB])
		{
			// Convert RGB to BW... We could add support for RGB later if needed by users....
			
			long	i, size, val;
			unsigned char	*srcPtr = (unsigned char*) data;
			float   *dstPtr;
			
			size = [firstObject pheight] * [pix count];
			size *= [firstObject pwidth];
			size *= sizeof( float);
			
			dataFRGB = (float*) malloc( size);
			
			size /= 4;
			
			dstPtr = dataFRGB;
			for( i = 0 ; i < size; i++)
			{
				srcPtr++;
				val = *srcPtr++;
				val += *srcPtr++;
				val += *srcPtr++;
				*dstPtr++ = val/3;
			}
			
			data = dataFRGB;
		}
		
		reader = vtkImageImport::New();
		reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
		reader->SetDataExtentToWholeExtent();
		reader->SetDataScalarTypeToFloat();
		reader->SetImportVoidPointer(data);
	//	reader->SetDataOrigin(  [firstObject originX],
	//							[firstObject originY],
	//							[firstObject originZ]);
		reader->SetDataSpacing( [firstObject pixelSpacingX], [firstObject pixelSpacingY], fabs( sliceThickness)); 

		if( sliceThickness < 0 )
		{
			flip = vtkImageFlip::New();
			flip->SetInput( reader->GetOutput());
			flip->SetFlipAboutOrigin( TRUE);
			flip->SetFilteredAxis(2);
		}
		else flip = 0L;
			
		// PLANE
		
		[firstObject orientation:cosines];
		
		matrice = vtkMatrix4x4::New();
		matrice->Element[0][0] = cosines[0];		matrice->Element[1][0] = cosines[1];		matrice->Element[2][0] = cosines[2];		matrice->Element[3][0] = 0;
		matrice->Element[0][1] = cosines[3];		matrice->Element[1][1] = cosines[4];		matrice->Element[2][1] = cosines[5];		matrice->Element[3][1] = 0;
		matrice->Element[0][2] = cosines[6];		matrice->Element[1][2] = cosines[7];		matrice->Element[2][2] = cosines[8];		matrice->Element[3][2] = 0;
		matrice->Element[0][3] = 0;					matrice->Element[1][3] = 0;					matrice->Element[2][3] = 0;					matrice->Element[3][3] = 1;
		
		outlineData = vtkOutlineFilter::New();
		if( flip) outlineData->SetInput((vtkDataSet *) flip->GetOutput());
		else outlineData->SetInput((vtkDataSet *) reader->GetOutput());
		
		mapOutline = vtkPolyDataMapper::New();
		mapOutline->SetInput(outlineData->GetOutput());
		
		outlineRect = vtkActor::New();
		outlineRect->SetMapper(mapOutline);
		outlineRect->GetProperty()->SetColor(0,1,0);
		outlineRect->GetProperty()->SetOpacity(0.5);
		outlineRect->SetUserMatrix( matrice);
		outlineRect->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
		outlineRect->SetPosition(	[firstObject originX] * matrice->Element[0][0] + [firstObject originY] * matrice->Element[1][0] + [firstObject originZ]*matrice->Element[2][0],
									[firstObject originX] * matrice->Element[0][1] + [firstObject originY] * matrice->Element[1][1] + [firstObject originZ]*matrice->Element[2][1],
									[firstObject originX] * matrice->Element[0][2] + [firstObject originY] * matrice->Element[1][2] + [firstObject originZ]*matrice->Element[2][2]);
		outlineRect->PickableOff();
		
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontShow3DCubeOrientation"] == NO)
		{
			vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
			cube->SetXPlusFaceText ( [NSLocalizedString( @"L", @"L: Left") UTF8String] );		
			cube->SetXMinusFaceText( [NSLocalizedString( @"R", @"R: Right") UTF8String] );
			cube->SetYPlusFaceText ( [NSLocalizedString( @"P", @"P: Posterior") UTF8String] );
			cube->SetYMinusFaceText( [NSLocalizedString( @"A", @"A: Anterior") UTF8String] );
			cube->SetZPlusFaceText ( [NSLocalizedString( @"S", @"S: Superior") UTF8String] );
			cube->SetZMinusFaceText( [NSLocalizedString( @"I", @"I: Inferior") UTF8String] );
			cube->SetFaceTextScale( 0.67 );


			vtkProperty* property = cube->GetXPlusFaceProperty();
			property->SetColor(0, 0, 1);
			property = cube->GetXMinusFaceProperty();
			property->SetColor(0, 0, 1);
			property = cube->GetYPlusFaceProperty();
			property->SetColor(0, 1, 0);
			property = cube->GetYMinusFaceProperty();
			property->SetColor(0, 1, 0);
			property = cube->GetZPlusFaceProperty();
			property->SetColor(1, 0, 0);
			property = cube->GetZMinusFaceProperty();
			property->SetColor(1, 0, 0);

			cube->SetTextEdgesVisibility( 1);
			cube->SetCubeVisibility( 1);
			cube->SetFaceTextVisibility( 1);

			orientationWidget = vtkOrientationMarkerWidget::New();
			orientationWidget->SetOrientationMarker( cube );
			orientationWidget->SetInteractor( [self getInteractor] );
			orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
			orientationWidget->SetEnabled( 1 );
			orientationWidget->InteractiveOff();
			cube->Delete();
		}


	//	croppingBox = vtkBoxWidget::New();
	//	croppingBox->GetHandleProperty()->SetColor(0, 1, 0);
	//	
	//	croppingBox->SetProp3D(skin);
	//	croppingBox->SetPlaceFactor( 1.0);
	//	croppingBox->SetHandleSize( 0.005);
	//	croppingBox->PlaceWidget();
	//    croppingBox->SetInteractor( [self renderWindowInteractor]);
	//	croppingBox->SetInsideOut( true);
	//	croppingBox->OutlineCursorWiresOff();
	//	cropcallback = vtkMyCallback::New();
	//	cropcallback->setBlendingVolume( 0L);
	//	croppingBox->AddObserver(vtkCommand::InteractionEvent, cropcallback);
		
	/*	planeWidget = vtkPlaneWidget::New();
		
		planeWidget->GetHandleProperty()->SetColor(0, 0, 1);
		planeWidget->SetHandleSize( 0.005);
		planeWidget->SetProp3D(volume);
		planeWidget->SetResolution( 1);
		planeWidget->SetPoint1(-50, -50, -50);
		planeWidget->SetPoint2(50, 50, 50);
		planeWidget->PlaceWidget();
		planeWidget->SetRepresentationToWireframe();
		planeWidget->SetInteractor( [self renderWindowInteractor]);
		planeWidget->On();
		vtkPlaneCallback *planecallback = vtkPlaneCallback::New();
		planeWidget->AddObserver(vtkCommand::InteractionEvent, planecallback);
	*/	
		textX = vtkTextActor::New();
		textX->SetInput( "X");
		textX->SetScaledText( false);
		textX->GetPositionCoordinate()->SetCoordinateSystemToViewport();
		textX->GetPositionCoordinate()->SetValue( 2., 2.);
		aRenderer->AddActor2D(textX);
		
		for( i = 0; i < 4; i++)
		{
			oText[ i]= vtkTextActor::New();
			oText[ i]->SetInput( "X");
			oText[ i]->SetScaledText( false);
			oText[ i]->GetPositionCoordinate()->SetCoordinateSystemToNormalizedViewport();
			oText[ i]->GetTextProperty()->SetFontSize( 16);
			oText[ i]->GetTextProperty()->SetBold( true);
			oText[ i]->GetTextProperty()->SetShadow( true);
			oText[ i]->GetTextProperty()->SetShadowOffset(1, 1);
			
			aRenderer->AddActor2D( oText[ i]);
		}
		oText[ 0]->GetPositionCoordinate()->SetValue( 0.01, 0.5);
		oText[ 1]->GetPositionCoordinate()->SetValue( 0.99, 0.5);
		oText[ 1]->GetTextProperty()->SetJustificationToRight();
		
		oText[ 2]->GetPositionCoordinate()->SetValue( 0.5, 0.03);
		oText[ 2]->GetTextProperty()->SetVerticalJustificationToTop();
		oText[ 3]->GetPositionCoordinate()->SetValue( 0.5, 0.97);
		aCamera = vtkCamera::New();
		aCamera->SetViewUp (0, 1, 0);
		aCamera->SetFocalPoint (0, 0, 0);
		aCamera->SetPosition (0, 0, 1);
		aCamera->SetRoll(180);

	//    aCamera->ComputeViewPlaneNormal();    
		
		aCamera->Dolly(1.5);

		
		aRenderer->AddActor( outlineRect);

		aRenderer->SetActiveCamera(aCamera);
		
		aCamera->SetFocalPoint (0, 0, 0);
		aCamera->SetPosition (1, 0, 0);
		aCamera->ComputeViewPlaneNormal();
		aCamera->SetViewUp(0, 0, 1);
		aCamera->OrthogonalizeViewUp();
		aCamera->Dolly(1.5);
		aRenderer->ResetCamera();

		[self saView:self];

		GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
		[self getVTKRenderWindow]->MakeCurrent();
		[[NSOpenGLContext currentContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];

		[self setNeedsDisplay:YES];
		
	}
	catch (...)
	{
		NSLog( @"setPixSource C++ exception SRView.m");
		return -1;
	}

    return error;
}

-(void) switchOrientationWidget:(id) sender
{
	long i;
	
	if( orientationWidget)
	{
		if( orientationWidget->GetEnabled())
		{
			orientationWidget->Off();
			for( i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
		}
		else if( [self renderWindow]->GetStereoRender() == false)
		{
			orientationWidget->On();
			for( i = 0; i < 4; i++) aRenderer->AddActor2D( oText[ i]);
		}
	}
	
	[self setNeedsDisplay:YES];
}

-(IBAction) SwitchStereoMode :(id) sender
{
	long i;
	
	if( [self renderWindow]->GetStereoRender() == false)
	{
		[self renderWindow]->StereoRenderOn();
		[self renderWindow]->SetStereoTypeToRedBlue();
		
		if( orientationWidget)
			orientationWidget->Off();
		for( i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
	}
	else
	{
		[self renderWindow]->StereoRenderOff();
	}
	
	[self setNeedsDisplay:YES];
}

-(IBAction) switchProjection:(id) sender
{
	NSLog(@"switchProjection");
	projectionMode = [[sender selectedCell] tag];
	
	switch( projectionMode)
	{
		case 0:
			//aCamera->SetParallelProjection( false);
			aCamera->SetViewAngle( 30);
		break;
		
		case 2:
			//aCamera->SetParallelProjection( false);
			aCamera->SetViewAngle( 60);
		break;
		
//		case 1:
//			aCamera->SetParallelProjection( true);
//			aCamera->SetViewAngle( 30);
//		break;
	}
//	
//	if( aCamera->GetParallelProjection())
//	{
//		[[[[[self window] windowController] toolsMatrix] cellWithTag: tMesure] setEnabled: YES];
//	}
//	else
//	{
//		[[[[[self window] windowController] toolsMatrix] cellWithTag: tMesure] setEnabled: NO];
//		
//		if( currentTool == tMesure)
//		{
//			[self setCurrentTool: t3DRotate];
//			[[[[self window] windowController] toolsMatrix] selectCellWithTag: t3DRotate];
//		}
//	}	
	[self setNeedsDisplay:YES];
}

-(NSImage*) nsimageQuicktime
{
	NSImage *theIm;
	BOOL wasPresent = NO;
	
	if( aRenderer->GetActors()->IsItemPresent( outlineRect))
	{
		aRenderer->RemoveActor( outlineRect);
		wasPresent = YES;
	}
	
	[self display];
	
	theIm = [self nsimage:YES];
	
	if( wasPresent)
		aRenderer->AddActor(outlineRect);
	
	return theIm;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	unsigned char	*buf = 0L;
	long			i;
	
//	if( screenCapture)	// Pixels displayed in current window -> only RGB 8 bits data
	{
		NSRect size = [self bounds];
		
		*width = (long) size.size.width;
		*width/=4;
		*width*=4;
		*height = (long) size.size.height;
		*spp = 3;
		*bpp = 8;
		
		buf = (unsigned char*) malloc( *width * *height * 4 * *bpp/8);
		if( buf)
		{
			[self getVTKRenderWindow]->MakeCurrent();
//			[[NSOpenGLContext currentContext] flushBuffer];
			
			glReadBuffer(GL_FRONT);
			
			#if __BIG_ENDIAN__
				glReadPixels(0, 0, *width, *height, GL_RGB, GL_UNSIGNED_BYTE, buf);
			#else
				glReadPixels(0, 0, *width, *height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, buf);
				i = *width * *height;
				unsigned char	*t_argb = buf;
				unsigned char	*t_rgb = buf;
				while( i-->0)
				{
					*((int*) t_rgb) = *((int*) t_argb);
					t_argb+=4;
					t_rgb+=3;
				}
			#endif
			
			long rowBytes = *width**spp**bpp/8;
			
			{
				unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
				
				for( i = 0; i < *height/2; i++)
				{
					memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
					memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
					memcpy( buf + i*rowBytes, tempBuf, rowBytes);
				}
				
				free( tempBuf);
			}
			
//			[[NSOpenGLContext currentContext] flushBuffer];
			[NSOpenGLContext clearCurrentContext];
		}
	}
//	else NSLog(@"Err getRawPixels...");
		
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	NSBitmapImageRep	*rep;
	long				width, height, i, x, spp, bpp;
	NSString			*colorSpace;
	unsigned char		*dataPtr;
	
	dataPtr = [self getRawPixels :&width :&height :&spp :&bpp :!originalSize : YES];
	
	if( spp == 3) colorSpace = NSCalibratedRGBColorSpace;
	else colorSpace = NSCalibratedWhiteColorSpace;
	
	rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:0L
						   pixelsWide:width
						   pixelsHigh:height
						bitsPerSample:bpp
					  samplesPerPixel:spp
							 hasAlpha:NO
							 isPlanar:NO
					   colorSpaceName:colorSpace
						  bytesPerRow:width*bpp*spp/8
						 bitsPerPixel:bpp*spp] autorelease];
	
	memcpy( [rep bitmapData], dataPtr, height*width*bpp*spp/8);
	
	//Add the small OsiriX logo at the bottom right of the image
	NSImage				*logo = [NSImage imageNamed:@"SmallLogo.tif"];
	NSBitmapImageRep	*TIFFRep = [[NSBitmapImageRep alloc] initWithData: [logo TIFFRepresentation]];
	
	for( i = 0; i < [TIFFRep pixelsHigh]; i++)
	{
		unsigned char	*srcPtr = ([TIFFRep bitmapData] + i*[TIFFRep bytesPerRow]);
		unsigned char	*dstPtr = ([rep bitmapData] + (height - [TIFFRep pixelsHigh] + i)*[rep bytesPerRow] + ((width-10)*3 - [TIFFRep bytesPerRow]));
		
		x = [TIFFRep bytesPerRow]/3;
		while( x-->0)
		{
			if( srcPtr[ 0] != 0 || srcPtr[ 1] != 0 || srcPtr[ 2] != 0)
			{
				dstPtr[ 0] = srcPtr[ 0];
				dstPtr[ 1] = srcPtr[ 1];
				dstPtr[ 2] = srcPtr[ 2];
			}
			
			dstPtr += 3;
			srcPtr += 3;
		}
	}
	
	[TIFFRep release];
	
     NSImage *image = [[[NSImage alloc] init] autorelease];
     [image addRepresentation:rep];
     
	 free( dataPtr);
	 
    return image;
}

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    NSImage *im;
    
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    
    im = [self nsimage:NO];
    
    [pb setData: [im TIFFRepresentation] forType:NSTIFFPboardType];
}

// joris' modifications for fly thru

- (Camera*) camera
{
	// data extraction from the vtkCamera
	double pos[3], focal[3], vUp[3];
	aCamera->GetPosition(pos);
	aCamera->GetFocalPoint(focal);
	aCamera->GetViewUp(vUp);
	double clippingRange[2];
	aCamera->GetClippingRange(clippingRange);
	double viewAngle, eyeAngle, parallelScale;
	viewAngle = aCamera->GetViewAngle();
	eyeAngle = aCamera->GetEyeAngle();
	parallelScale = aCamera->GetParallelScale();
	
	// creation of the Camera
	Camera *cam = [[Camera alloc] init];
	[cam setPosition: [[[Point3D alloc] initWithValues:pos[0] :pos[1] :pos[2]] autorelease]];
	[cam setFocalPoint: [[[Point3D alloc] initWithValues:focal[0] :focal[1] :focal[2]] autorelease]];
	[cam setViewUp: [[[Point3D alloc] initWithValues:vUp[0] :vUp[1] :vUp[2]] autorelease]];
	[cam setClippingRangeFrom: clippingRange[0] To: clippingRange[1]];
	[cam setViewAngle: viewAngle];
	[cam setEyeAngle: eyeAngle];
	[cam setParallelScale: parallelScale];
	
	[cam setPreviewImage: [self nsimage:TRUE]];
	
	return [cam autorelease];
}

- (void) setCamera: (Camera*) cam
{	
	double pos[3], focal[3], vUp[3];
	pos[0] = [[cam position] x];
	pos[1] = [[cam position] y];
	pos[2] = [[cam position] z];
	focal[0] = [[cam focalPoint] x];
	focal[1] = [[cam focalPoint] y];
	focal[2] = [[cam focalPoint] z];	
	vUp[0] = [[cam viewUp] x];
	vUp[1] = [[cam viewUp] y];
	vUp[2] = [[cam viewUp] z];
	double clippingRange[2];
	clippingRange[0] = [cam clippingRangeNear];
	clippingRange[1] = [cam clippingRangeFar];
	double viewAngle, eyeAngle, parallelScale;
	viewAngle = [cam viewAngle];
	eyeAngle = [cam eyeAngle];
	parallelScale = [cam parallelScale];

	aCamera->SetPosition(pos);
	aCamera->SetFocalPoint(focal);
	aCamera->SetViewUp(vUp);
	//aCamera->SetClippingRange(clippingRange);
	aCamera->SetViewAngle(viewAngle);
	aCamera->SetEyeAngle(eyeAngle);
	aCamera->SetParallelScale(parallelScale);
	aRenderer->ResetCameraClippingRange();
}


- (IBAction)changeColor:(id)sender
{	
	if( [backgroundColor isActive])
	{
		NSColor *color=  [[(NSColorPanel*)sender color]  colorUsingColorSpaceName: NSDeviceRGBColorSpace];
		aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		[self setNeedsDisplay:YES];
	}
}

- (void) convert3Dto2Dpoint:(double*) pt3D :(double*) pt2D
{
	vtkTransform *Transform = vtkTransform::New();
			
	Transform->SetMatrix( matrice);
	Transform->Push();
	
	Transform->Inverse();
	
	Transform->TransformPoint( pt3D, pt2D);
	
	double vPos[ 3];
	
	iso[ 0]->GetPosition( vPos);
	
	pt2D[ 0] -= vPos[ 0];
	pt2D[ 1] -= vPos[ 1];
	pt2D[ 2] -= vPos[ 2];
	
	pt2D[0] /= [firstObject pixelSpacingX];
	pt2D[1] /= [firstObject pixelSpacingY];
	pt2D[2] /= [firstObject sliceInterval];
						
	Transform->Delete();
}

// 3D points
#pragma mark-
#pragma mark 3D Points

#pragma mark add
- (void) add3DPoint: (double) x : (double) y : (double) z : (float) radius : (float) r : (float) g : (float) b
{
	//Sphere
	vtkSphereSource *sphereSource = vtkSphereSource::New();
	sphereSource->SetRadius(radius);
	sphereSource->SetCenter(x, y, z);
	//Mapper
	vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
	mapper->SetInputConnection(sphereSource->GetOutputPort());
	sphereSource->Delete();
	//Actor
	vtkActor *sphereActor = vtkActor::New();
	sphereActor->SetMapper(mapper);
	mapper->Delete();
	sphereActor->GetProperty()->SetColor(r,g,b);
	sphereActor->DragableOn();
	sphereActor->PickableOn();

	double center[3];
	center[0]=x;
	center[1]=y;
	center[2]=z;
	[point3DPositionsArray addObject:[NSValue value:center withObjCType:@encode(double[3])]];
	[point3DRadiusArray addObject:[NSNumber numberWithFloat:radius]];
	[point3DColorsArray addObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0]];

	[point3DDisplayPositionArray addObject:[NSNumber numberWithInt:0]];
	[point3DPositionsStringsArray addObject:[NSString stringWithFormat:@"x: %0.3f mm\ny: %0.3f mm\nz: %0.3f mm", x, y, z]];
	[point3DTextColorsArray addObject:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
	[point3DTextSizesArray addObject:[NSNumber numberWithFloat:4.0]];
	
	[self add3DPointActor: sphereActor];
	
	// point annotations
//	vtkVectorText *aText = vtkVectorText::New();
	
//	const char *bufferPosition = [[NSString stringWithFormat:@"x: %0.3f mm, y: %0.3f mm, z: %0.3f mm", x, y, z] UTF8String];
//	char *bufferName = "Name\n";
//	char *bufferAnnotation = (char *)malloc((strlen(bufferPosition) + strlen(bufferName) + 1)*sizeof(char));
//	strcat(bufferAnnotation, bufferName);
//	strcat(bufferAnnotation, bufferPosition);
//	
	[self setAnnotation: "" for3DPointAtIndex:[point3DPositionsArray count]-1];
	
//	aText->SetText(bufferAnnotation);
//	
//	vtkPolyDataMapper *textMapper = vtkPolyDataMapper::New();
//	textMapper->SetInput(aText->GetOutput());
//	
//		// text
//	vtkFollower *text = vtkFollower::New();
//	text->SetMapper(textMapper);
//	text->SetScale(4,4,4);
//	text->SetPosition(x+radius,y+radius,z+radius);
//	text->GetProperty()->SetColor(1, 1, 1);
	
		// shadow
//	vtkFollower *textShadow = vtkFollower::New();
//	textShadow->SetMapper(textMapper);
//	textShadow->SetScale(4.3,4.3,4.3);
//	textShadow->SetPosition(x+radius-.1,y+radius,z+radius);
//	textShadow->GetProperty()->SetColor(0, 0, 0);
//
//	aRenderer->AddActor(textShadow);
//	textShadow->SetCamera(aCamera);
//	aRenderer->AddActor(text);
//	text->SetCamera(aCamera);
//
//	void* textPointer = text;
//	[point3DTextArray addObject:[NSValue valueWithPointer:textPointer]];
}

- (void) add3DPoint: (double) x : (double) y : (double) z
{
	[self add3DPoint: x : y : z : point3DDefaultRadius : point3DDefaultColorRed : point3DDefaultColorGreen : point3DDefaultColorBlue];
}

- (void) add3DPointActor: (vtkActor*) actor
{
	void* actorPointer = actor;
	[point3DActorArray addObject:[NSValue valueWithPointer:actorPointer]];
	aRenderer->AddActor(actor);
	//actor->Delete();
}

- (void) addRandomPoints: (int) n : (int) r
{
	long i;
	// add some random points
	for(i=0; i<n ; i++)
	{
		[self add3DPoint: ((double)(random()/(pow(2,31)-1))*2.0-1.0)*(double)r // x coordinate
						: ((double)(random()/(pow(2,31)-1))*2.0-1.0)*(double)r // y
						: ((double)(random()/(pow(2,31)-1))*2.0-1.0)*(double)r // z
						: 2.0 // radius
						: 1.0 // red
						: 0.0 // green
						: 0.0 // blue
		];
	}
}

- (void) throw3DPointOnSurface: (double) x : (double) y
{
	vtkWorldPointPicker *picker = vtkWorldPointPicker::New();
	
	picker->Pick(x, y, 0.0, aRenderer);
	double wXYZ[3];
	picker->GetPickPosition(wXYZ);
	[self add3DPoint: wXYZ[0] : wXYZ[1] : wXYZ[2]];
	[controller add2DPoint: wXYZ[0] : wXYZ[1] : wXYZ[2]];
	
	picker->Delete();
}

#pragma mark display
- (void) setDisplay3DPoints: (BOOL) on
{
	display3DPoints = on;
	
	NSEnumerator *enumeratorPoint = [point3DActorArray objectEnumerator];
	NSEnumerator *enumeratorText = [point3DTextArray objectEnumerator];
	id objectPoint, objectText;
	vtkActor *actor;
	vtkFollower* text;
		
	while (objectPoint = [enumeratorPoint nextObject])
	{
		actor = (vtkActor*)[objectPoint pointerValue];
		objectText = [enumeratorText nextObject];
		text = (vtkFollower*)[objectText pointerValue];
		if(on)
		{
			aRenderer->AddActor(actor);
			aRenderer->AddActor(text);
		}
		else
		{
			aRenderer->RemoveActor(actor);
			aRenderer->RemoveActor(text);
		}	
	}
	[self unselectAllActors];
	[self setNeedsDisplay:YES];
}

- (void) toggleDisplay3DPoints
{
	[self setDisplay3DPoints:!display3DPoints];
}

#pragma mark selection
- (BOOL) isAny3DPointSelected
{
	BOOL boo = NO;
	
	if(((vtkAbstractPropPicker*)aRenderer->GetRenderWindow()->GetInteractor()->GetPicker())->GetViewProp()!=NULL)
	{
		// a vtkObject is selected, let's check if it is one of our 3D Points
		if([self selected3DPointIndex] < [point3DActorArray count])
		{
			boo = YES;
		}
	}

	return boo;
}

- (unsigned int) selected3DPointIndex
{
	vtkProp *pickedProp = ((vtkAbstractPropPicker*)aRenderer->GetRenderWindow()->GetInteractor()->GetPicker())->GetPath()->GetFirstNode()->GetViewProp();
	
	void *pickedPropPointer = pickedProp;
	
	NSEnumerator *enumerator = [point3DActorArray objectEnumerator];
	id object;
	void *actorPointer;
	unsigned int i = 0;
	
	while (object = [enumerator nextObject])
	{
		actorPointer = [object pointerValue];
		if(pickedPropPointer==actorPointer)
		{
			return i;
		}
		i++;
	}
	return i; // if no point is selected, returns [point3DActorArray count], i.e. out of bounds...
}

- (void) unselectAllActors
{
	((vtkInteractorStyle*)aRenderer->GetRenderWindow()->GetInteractor()->GetInteractorStyle())->HighlightProp3D(NULL);
}

#pragma mark remove
- (void) remove3DPointAtIndex: (unsigned int) index
{
	// point to remove
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	// remove from Renderer
	aRenderer->RemoveActor(actor);
	// remove the highlight bounding box
	[self unselectAllActors];
	// remove from list
	[point3DActorArray removeObjectAtIndex:index];
	[point3DPositionsArray removeObjectAtIndex:index];
	[point3DRadiusArray removeObjectAtIndex:index];
	[point3DColorsArray removeObjectAtIndex:index];
	
	
	vtkFollower *text = (vtkFollower*)[[point3DTextArray objectAtIndex:index] pointerValue];
	aRenderer->RemoveActor(text);
	text->Delete();
	[point3DTextArray removeObjectAtIndex:index];
	[point3DPositionsStringsArray removeObjectAtIndex:index];
	[point3DTextColorsArray removeObjectAtIndex:index];
	[point3DTextSizesArray removeObjectAtIndex:index];
	// refresh display
	[self setNeedsDisplay:YES];
}

- (void) removeSelected3DPoint
{
	if([self isAny3DPointSelected])
	{
		// remove 2D Point
		double position[3];
		NSLog(@"[point3DPositionsArray count]: %d", [point3DPositionsArray count]);
		[[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:position];
		[controller remove2DPoint: position[0] : position[1] : position[2]];
		// remove 3D Point
		// the 3D Point is removed through notification (sent in [controller remove2DPoint..)
		//[self remove3DPointAtIndex:[self selected3DPointIndex]];
	}
}

#pragma mark modify 3D point appearence

- (IBAction) IBSetSelected3DPointColor: (id) sender
{
	if([point3DPropagateToAll state])
	{
		[self setAll3DPointsColor: [sender color]];
		[self setAll3DPointsRadius: [point3DRadiusSlider floatValue]];
	}
	else
	{
		[self setSelected3DPointColor: [sender color]];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction) IBSetSelected3DPointRadius: (id) sender
{
	if([point3DPropagateToAll state])
	{
		[self setAll3DPointsRadius: [sender floatValue]];
		[self setAll3DPointsColor: [point3DColorWell color]];
	}
	else
	{
		[self setSelected3DPointRadius: [sender floatValue]];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction) IBPropagate3DPointsSettings: (id) sender
{
	if([sender state]==NSOnState)
	{
		[self setAll3DPointsRadius: [point3DRadiusSlider floatValue]];
		[self setAll3DPointsColor: [point3DColorWell color]];
		[self IBSetSelected3DPointAnnotation: point3DDisplayPositionButton];
		[self IBSetSelected3DPointAnnotationColor: point3DTextColorWell];
		[self IBSetSelected3DPointAnnotationSize: point3DTextSizeSlider];
		[self setNeedsDisplay:YES];
	}
}

- (void) setSelected3DPointColor: (NSColor*) color
{
	if([self isAny3DPointSelected])[self set3DPointAtIndex:[self selected3DPointIndex] Color: color];
}

- (void) setAll3DPointsColor: (NSColor*) color
{
	unsigned int i = 0;	
	for(i=0 ; i<[point3DColorsArray count] ; i++)
	{
		[self set3DPointAtIndex:i Color: color];
	}
}

- (void) set3DPointAtIndex:(unsigned int) index Color: (NSColor*) color
{
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	actor->GetProperty()->SetColor([color redComponent],[color greenComponent],[color blueComponent]);

	[point3DColorsArray removeObjectAtIndex:index];
	[point3DColorsArray insertObject:color atIndex:index];
}

- (void) setSelected3DPointRadius: (float) radius
{
	if([self isAny3DPointSelected])[self set3DPointAtIndex:[self selected3DPointIndex] Radius: radius];
}

- (void) setAll3DPointsRadius: (float) radius
{
	unsigned int i = 0;	
	for(i=0 ; i<[point3DRadiusArray count] ; i++)
	{
		[self set3DPointAtIndex:i Radius: radius];
	}
}

- (void) set3DPointAtIndex:(unsigned int) index Radius: (float) radius
{
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	//Sphere
	vtkSphereSource *sphereSource = vtkSphereSource::New();
	sphereSource->SetRadius(radius);
	double center[3];
	[[point3DPositionsArray objectAtIndex:index] getValue:center];
	sphereSource->SetCenter(center[0],center[1],center[2]);
	//Mapper
	vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
	mapper->SetInputConnection(sphereSource->GetOutputPort());
	//Actor
	actor->SetMapper(mapper);
	
	sphereSource->Delete();
	mapper->Delete();
	
	[point3DRadiusArray removeObjectAtIndex:index];
	[point3DRadiusArray insertObject:[NSNumber numberWithFloat:radius] atIndex:index];
}

- (IBAction) save3DPointsDefaultProperties: (id) sender
{
	//color
	point3DDefaultColorRed = [[point3DColorWell color] redComponent];
	point3DDefaultColorGreen = [[point3DColorWell color] greenComponent];
	point3DDefaultColorBlue = [[point3DColorWell color] blueComponent];
	point3DDefaultColorAlpha = [[point3DColorWell color] alphaComponent];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorRed forKey:@"points3DcolorRed"];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorGreen forKey:@"points3DcolorGreen"];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorBlue forKey:@"points3DcolorBlue"];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorAlpha forKey:@"points3DcolorAlpha"];

	// radius
	point3DDefaultRadius = [point3DRadiusSlider floatValue];
	[[NSUserDefaults standardUserDefaults] setFloat:[point3DRadiusSlider floatValue] forKey:@"points3Dradius"];
}

- (void) load3DPointsDefaultProperties
{	
	//color
	float r, g, b, a;
	point3DDefaultColorRed = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorRed"];
	point3DDefaultColorGreen = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorGreen"];
	point3DDefaultColorBlue = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorBlue"];
	point3DDefaultColorAlpha = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorAlpha"];
	
	if(a==0.0)
	{
		point3DDefaultColorRed = 1.0;
		point3DDefaultColorGreen = 0.0;
		point3DDefaultColorBlue = 0.0;
		point3DDefaultColorAlpha = 1.0;
	}

	//radius
	point3DDefaultRadius = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3Dradius"];
	if (point3DDefaultRadius==0) point3DDefaultRadius = 1.0;
}

#pragma mark annotation

- (IBAction) IBSetSelected3DPointAnnotation: (id) sender
{
//	int displayName = [[sender cellWithTag:0] state];
	int displayPosition = [sender state];
	
	if([point3DPropagateToAll state])
	{
		int i;
		for(i=0; i<[point3DActorArray count]; i++)
		{
			[self setAnnotationWithPosition:displayPosition for3DPointAtIndex:i];
		}
	}
	else
	{
		[self setAnnotationWithPosition:displayPosition for3DPointAtIndex:[self selected3DPointIndex]];
	}
	[self setNeedsDisplay:YES];
}

- (void) setAnnotationWithPosition:(int)displayPosition for3DPointAtIndex:(unsigned int) index
{
	const char *position;//*name, *glue;

//	// name
//	if(displayName)
//		name = "Test Name";
//	else
//		name = "";
	
	//position
	if(displayPosition)
		position = [[point3DPositionsStringsArray objectAtIndex:index] UTF8String];
	else
		position = "";
	
	//line break
//	if(displayName && displayPosition)
//		glue = "\n";
//	else
//		glue = "";
	
	//char *bufferAnnotation = (char *)calloc((strlen(name) + strlen(glue) + strlen(position) + 0),sizeof(char));
	char *bufferAnnotation = (char *)calloc(strlen(position),sizeof(char));
	
//	strcat(bufferAnnotation, name);
//	strcat(bufferAnnotation, glue);
	strcat(bufferAnnotation, position);

	[self setAnnotation:bufferAnnotation for3DPointAtIndex:index];
	if (strlen(bufferAnnotation)>0)
		[self displayAnnotationFor3DPointAtIndex:index];
	else
		[self hideAnnotationFor3DPointAtIndex:index];
	
//	NSMutableArray *form = [point3DTextMatrixArray objectAtIndex:index];
//	[form replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:displayName]];
//	[form replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:displayPosition]];
	[point3DDisplayPositionArray replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:displayPosition]];
}

- (void) setAnnotation:(const char*) annotation for3DPointAtIndex:(unsigned int) index
{
	vtkVectorText *aText = vtkVectorText::New();
	aText->SetText(annotation);
	
	vtkPolyDataMapper *textMapper = vtkPolyDataMapper::New();
	textMapper->SetInput(aText->GetOutput());
	
	float radius = [[point3DRadiusArray objectAtIndex:index] floatValue];
	double position[3];
	[[point3DPositionsArray objectAtIndex:index] getValue:position];
	
		// text
	vtkFollower *text = vtkFollower::New();
	text->SetMapper(textMapper);
	float s = [[point3DTextSizesArray objectAtIndex:index] floatValue];
	text->SetScale(s,s,s);
	text->SetPosition(position[0]+radius,position[1]+radius,position[2]+radius);
	NSColor *c = [point3DTextColorsArray objectAtIndex:index];
	text->GetProperty()->SetColor([c redComponent], [c greenComponent], [c blueComponent]);
	
		// shadow
//	vtkFollower *textShadow = vtkFollower::New();
//	textShadow->SetMapper(textMapper);
//	textShadow->SetScale(4.3,4.3,4.3);
//	textShadow->SetPosition(x+radius-.1,y+radius,z+radius);
//	textShadow->GetProperty()->SetColor(0, 0, 0);
//
//	aRenderer->AddActor(textShadow);
//	textShadow->SetCamera(aCamera);

	void* textPointer = text;
	if (index<[point3DTextArray count])
	{
		vtkFollower* text0 = (vtkFollower*)[[point3DTextArray objectAtIndex:index] pointerValue];
		aRenderer->RemoveActor(text0);
		[point3DTextArray replaceObjectAtIndex:index withObject:[NSValue valueWithPointer:textPointer]];
		text0->Delete();
	}
	else
		[point3DTextArray addObject:[NSValue valueWithPointer:textPointer]];
}

- (void) displayAnnotationFor3DPointAtIndex:(unsigned int) index
{
	vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:index] pointerValue];
	aRenderer->AddActor(text);
	text->SetCamera(aCamera);
	[self setNeedsDisplay:YES];
}

- (void) hideAnnotationFor3DPointAtIndex:(unsigned int) index
{
	vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:index] pointerValue];
	aRenderer->RemoveActor(text);
	[self setNeedsDisplay:YES];
}

- (IBAction) IBSetSelected3DPointAnnotationColor: (id) sender
{
	if ([self selected3DPointIndex]<[point3DTextArray count])
	{
		NSColor *c = [sender color];
		float r, g, b;
		r = [c redComponent];
		g = [c greenComponent];
		b = [c blueComponent];
		
		if ([point3DPropagateToAll state])
		{
			int i;
			for(i=0; i<[point3DActorArray count]; i++)
			{
				vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:i] pointerValue];
				text->GetProperty()->SetColor(r, g, b);
				[point3DTextColorsArray replaceObjectAtIndex:i withObject:c];
			}
		}
		else
		{
			vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:[self selected3DPointIndex]] pointerValue];
			text->GetProperty()->SetColor(r, g, b);
			[point3DTextColorsArray replaceObjectAtIndex:[self selected3DPointIndex] withObject:c];
		}
		[self setNeedsDisplay:YES];
	}
}

- (IBAction) IBSetSelected3DPointAnnotationSize: (id) sender
{
	if ([self selected3DPointIndex]<[point3DTextArray count])
	{
		float s = [sender floatValue];
		
		if ([point3DPropagateToAll state])
		{
			int i;
			for(i=0; i<[point3DActorArray count]; i++)
			{
				vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:i] pointerValue];
				text->SetScale(s,s,s);
				[point3DTextSizesArray replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:s]];
			}
		}
		else
		{
			vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:[self selected3DPointIndex]] pointerValue];
			text->SetScale(s,s,s);
			[point3DTextSizesArray replaceObjectAtIndex:[self selected3DPointIndex] withObject:[NSNumber numberWithFloat:s]];
		}
		[self setNeedsDisplay:YES];
	}
}

#pragma mark-
#pragma mark Cursors

//cursor methods

- (void)mouseEntered:(NSEvent *)theEvent
{
	cursorSet = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	cursorSet = NO;
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    [cursor set];
}

- (void) checkCursor
{
	if(cursorSet) [cursor set];
}

-(void) setCursorForView: (long) tool
{
	NSCursor	*c;
	
	if (tool == tMesure || tool == t3Dpoint)
		c = [NSCursor crosshairCursor];
	else if( tool == t3DCut)
		c = [NSCursor crosshairCursor];
	else if (tool == t3DRotate)
		c = [NSCursor rotate3DCursor];
	else if (tool == tCamera3D)
		c = [NSCursor rotate3DCameraCursor];
	else if (tool == tTranslate)
		c = [NSCursor openHandCursor];
	else if (tool == tRotate)
		c = [NSCursor rotateCursor];
	else if (tool == tZoom)
		c = [NSCursor zoomCursor];
	else if (tool == tWL)
		c = [NSCursor contrastCursor];
	else if (tool == tNext)
		c = [NSCursor stackCursor];
	else if (tool == tText)
		c = [NSCursor IBeamCursor];
	else if (tool == t3DRotate)
		c = [NSCursor crosshairCursor];
	else if (tool == tCross)
		c = [NSCursor crosshairCursor];
	else	
		c = [NSCursor arrowCursor];
		
	if( c != cursor)
	{
		[cursor release];
		
		cursor = [c retain];
	}
}

#pragma mark-  Drag and Drop

- (void) startDrag:(NSTimer*)theTimer{
	NS_DURING
	_dragInProgress = YES;
	
	NSEvent *event = (NSEvent *)[theTimer userInfo];
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard]; 
	NSMutableArray *pbTypes = [NSMutableArray array];
	// The image we will drag 
	NSImage *image;
	if ([event modifierFlags] & NSShiftKeyMask)
		image = [self nsimage: YES];
	else
		image = [self nsimage: NO];
		
	// Thumbnail image and position
	NSPoint event_location = [event locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	local_point.x -= 35;
	local_point.y -= 35;

	NSSize originalSize = [image size];
	
	float ratio = originalSize.width / originalSize.height;
	
	NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(100, 100/ratio)] autorelease];

	[thumbnail lockFocus];
	[image drawInRect: NSMakeRect(0, 0, 100, 100/ratio) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
	[thumbnail unlockFocus];
	
	if ([event modifierFlags] & NSAlternateKeyMask)
		[ pbTypes addObject: NSFilesPromisePboardType];
	else
		[pbTypes addObject: NSTIFFPboardType];	
	

	[pboard declareTypes:pbTypes  owner:self];

		
	if ([event modifierFlags] & NSAlternateKeyMask) {
		NSRect imageLocation;
		local_point = [self convertPoint:event_location fromView:nil];
		imageLocation.origin =  local_point;
		imageLocation.size = NSMakeSize(32,32);
		[pboard setData:nil forType:NSFilesPromisePboardType]; 
		
		if (destinationImage)
			[destinationImage release];
		destinationImage = [image copy];
		
		[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"jpg"]
            fromRect:imageLocation
            source:self
            slideBack:YES
            event:event];
	} 
	else {		
		[pboard setData: [[NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] forType:NSTIFFPboardType];
		
		[ self dragImage:thumbnail
			at:local_point
			offset:dragOffset
			event:event 
			pasteboard:pboard 
			source:self 
			slideBack:YES];
	}
	
	NS_HANDLER
		NSLog(@"Exception while dragging: %@", [localException description]);
	NS_ENDHANDLER
	
	_dragInProgress = NO;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination{
	NSString *name = @"OsiriX";
	name = [name stringByAppendingPathExtension:@"jpg"];
	NSArray *array = [NSArray arrayWithObject:name];
	NSData *_data = [[NSBitmapImageRep imageRepWithData: [destinationImage TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	NSURL *url = [NSURL  URLWithString:name  relativeToURL:dropDestination];
	[_data writeToURL:url  atomically:YES];
	[destinationImage release];
	destinationImage = nil;
	return array;
}

- (void)deleteMouseDownTimer{
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	_mouseDownTimer = nil;
	_dragInProgress = NO;
}

//part of Dragging Source Protocol
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
	return NSDragOperationEvery;
}

-(void) squareView:(id) sender
{
	NSLog(@"%d", [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"]);
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 1) return;
	
	NSRect	newFrame = [self frame];
	NSRect	beforeFrame = [self frame];
	
	int		border = [self frame].size.height-1;
	
	if( border > [self frame].size.width) border = [self frame].size.width;
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 2) border = 512;
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 3) border = 768;
	
	newFrame.size.width = border;
	newFrame.size.height = border;

	newFrame.origin.x = (int) ((beforeFrame.size.width - border) / 2);
	newFrame.origin.y = (int) (10 + (beforeFrame.size.height - border) / 2);
	
	[self setFrame: newFrame];
	
	[[self window] display];
}

- (vtkRenderer*) vtkRenderer;
{
	return aRenderer;
}

- (vtkCamera*) vtkCamera;
{
	return aCamera;
}

- (void)panX:(float)x Y:(float)y;
{
	vtkRenderWindowInteractor *rwi = [self getInteractor];

	double ViewFocus[4];
	double NewPickPoint[4];

	// Calculate the focal depth
	vtkCamera* camera = aCamera;
	camera->GetFocalPoint(ViewFocus);
	rwi->GetInteractorStyle()->ComputeWorldToDisplay(aRenderer, ViewFocus[0], ViewFocus[1], ViewFocus[2], ViewFocus);
	double focalDepth = ViewFocus[2];

	rwi->GetInteractorStyle()->ComputeDisplayToWorld(aRenderer, (double)x, (double)y, focalDepth, NewPickPoint);

	// Get the current focal point and position

	camera->GetFocalPoint(ViewFocus);

	double *ViewPoint = camera->GetPosition();

	// Compute a translation vector, moving everything 1/10
	// the distance to the cursor. (Arbitrary scale factor)

	double MotionVector[3];
	MotionVector[0] = 0.01 * (ViewFocus[0] - NewPickPoint[0]);
	MotionVector[1] = 0.01 * (ViewFocus[1] - NewPickPoint[1]);
	MotionVector[2] = 0.01 * (ViewFocus[2] - NewPickPoint[2]);

	camera->SetFocalPoint(MotionVector[0] + ViewFocus[0],
						  MotionVector[1] + ViewFocus[1],
						  MotionVector[2] + ViewFocus[2]);

	camera->SetPosition(MotionVector[0] + ViewPoint[0],
						MotionVector[1] + ViewPoint[1],
						MotionVector[2] + ViewPoint[2]);

	if (rwi->GetLightFollowCamera()) 
	{
		aRenderer->UpdateLightsGeometryToFollowCamera();
	}
}

- (void)yaw:(float)degrees;
{
	aCamera->Yaw(degrees);
	aRenderer->ResetCameraClippingRange();
	[self setNeedsDisplay:YES];
}

- (void)recordFlyThru;
{
	[controller recordFlyThru];
}

#pragma mark-
#pragma mark  3DConnexion SpaceNavigator

- (void)closeEvent:(id) sender
{
	SRView *sV = (SRView*) snSRView;
	
	[sV getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent,NULL);

	snStopped = YES;
	
	[snCloseEventTimer release];
	snCloseEventTimer = 0L;
}

#if USE3DCONNEXION
- (void)connect2SpaceNavigator;
{
	snSRView = self;
	snStopped = YES;
	OSErr	error;
	if(InstallConnexionHandlers != NULL)
	{
		// Install message handler and register our client
		error = InstallConnexionHandlers(SRSpaceNavigatorMessageHandler, 0L, 0L);

		// This takes over in our application only
		snConnexionClientID = RegisterConnexionClient('OsiX', (UInt8*) "\pOsiriX", kConnexionClientModeTakeOver, kConnexionMaskAll);
	}
}

void SRSpaceNavigatorMessageHandler(io_connect_t connection, natural_t messageType, void *messageArgument)
{
	static ConnexionDeviceState	lastState;
	ConnexionDeviceState		*state;
	SRView *sV = (SRView*) snSRView;
	
	SInt16 tx, ty, tz, rx, ry, rz, xPos, yPos;
	float axis_max, speed, rot;
	
	BOOL record = NO;
	
	switch(messageType)
	{
		case kConnexionMsgDeviceState:
			state = (ConnexionDeviceState*)messageArgument;
			
			AbsoluteTime theTime = UpTime();
			uint64_t t = ((uint64_t*) &theTime)[0];

			if(t - state->time > 2*1000*1000)
			{		
				break;
			}

			if(state->client == snSRView->snConnexionClientID)
			{
                // decipher what command/event is being reported by the driver
                switch (state->command)
                {
                    case kConnexionCmdHandleAxis:
						// get the axis movement (names are taken from the SDK documentation)
						tx = state->axis[0];
						ty = state->axis[1];
						tz = state->axis[2];
						rx = state->axis[3];
						ry = state->axis[4];
						rz = state->axis[5];
						
						// normalization
						axis_max = 500.0; // typical value according to the SDK

						// if shift is pressed -> faster movement
						BOOL faster;
						if([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask)
							faster = YES;
						else faster = NO;

						// if ctrl is pressed -> record
						if([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSControlKeyMask)
							record = YES;
						else record = NO;

						if( sV->snCloseEventTimer)
						{
							[sV->snCloseEventTimer invalidate];
							[sV->snCloseEventTimer release];
							sV->snCloseEventTimer = 0L;
						}
						
						// *** zoom ***					
						if( sV->projectionMode != 2)
						{
							speed = 0.2; // zoom speed 0.2 is slow 1.0 is fast
							float zoom = ((float)tz/axis_max)*speed +1.0;

							if( zoom < 0.98 || zoom > 1.02)
							{
								[sV vtkCamera]->Zoom(zoom);
								[sV setNeedsDisplay:YES];
							}
						}
						else // endosocpy
						{
							float distance = [sV vtkCamera]->GetDistance();
							float dolly = ((float)tz/axis_max) / 60.;
							if(faster) dolly*=3.;
							if( dolly < -0.9) dolly = -0.9;
							
							[sV vtkCamera]->Dolly( 1.0 + dolly); 
							[sV vtkCamera]->SetDistance( distance);
							[sV vtkCamera]->ComputeViewPlaneNormal();
							[sV vtkCamera]->OrthogonalizeViewUp();
							[sV vtkRenderer]->ResetCameraClippingRange();
							[sV setNeedsDisplay:YES];
						}

						// *** rotation ***
						rot = -(float)rz;
						if( sV->projectionMode == 2) rot = (float)rz;
						
						float rotX, rotY;
						rotX = [sV frame].size.width/2.0 + cos(rot/axis_max)*50.0;
						rotY = [sV frame].size.height/2.0 + sin(rot/axis_max)*50.0;
						[sV vtkCamera]->Roll(rot/axis_max*10.0);
						[sV setNeedsDisplay:YES];
						
						// *** pan ***
						if( sV->projectionMode != 2)
						{
							[sV panX:[sV frame].size.width/2.0+tx*10.0 Y:[sV frame].size.height/2.0-ty*10.0];
							[sV setNeedsDisplay:YES];
						}
						// no pan for endoscopy mode
												
						// *** 3D rotation ***
						if( sV->projectionMode != 2)
						{
							xPos = lastState.axis[4]-(float)ry/axis_max*50.0;
							yPos = lastState.axis[3]-(float)rx/axis_max*50.0;
							[sV getInteractor]->SetEventInformation((int)xPos, (int)yPos, 0, 0);						
							if( sV->snStopped)
							{
								[sV getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
								sV->snStopped = NO;
							}
							else
								[sV getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);						
							state->axis[3] = yPos;
							state->axis[4] = xPos;
							[sV setNeedsDisplay:YES];
						}
						else // endoscopy
						{
							[sV vtkCamera]->Yaw((float)ry/axis_max*10.0);
							[sV vtkCamera]->Pitch((float)rx/axis_max*10.0);
							[sV vtkCamera]->ComputeViewPlaneNormal();
							[sV vtkCamera]->OrthogonalizeViewUp();
							[sV vtkRenderer]->ResetCameraClippingRange();
							[sV computeOrientationText];
							[sV setNeedsDisplay:YES];
						}
						[sV computeOrientationText];
						
						if([sV needsDisplay]) [sV display];
						
						sV->snCloseEventTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:sV selector:@selector(closeEvent:) userInfo:nil repeats:0] retain];
                        break;
                        
                    case kConnexionCmdHandleButtons:
						if(state->buttons==0) // buttons released
						{
							[sV closeEvent:nil];
						}
						else if(state->buttons==1) // left button pressed
						{
							if( sV->projectionMode != 2) [sV coView:nil];
							else [sV yaw:180.0];
						}
						else if(state->buttons==2) // right button pressed
						{
							if( sV->projectionMode != 2) [sV saView:nil];
							else [sV yaw:90.0];
						}
						else if(state->buttons==3) // both button are presed
						{
							if( sV->projectionMode != 2) [sV saViewOpposite:nil];
						}
                        break;
                }                
				
				memcpy( &lastState, state, (long)sizeof(ConnexionDeviceState));
			}
			break;
	}
	if(record) [sV recordFlyThru];
}
#else
- (void)connect2SpaceNavigator;
{
}
#endif

@end
