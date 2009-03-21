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


#import "EndoscopyMPRView.h"
#import "EndoscopyViewer.h"
#import "DCMPix.h"
#import "Mailer.h"
#import "DICOMExport.h"
#import "BrowserController.h"

@implementation EndoscopyMPRView

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self != nil)
	{
		cameraPosition.x = 0.0;
		cameraPosition.y = 0.0;
		cameraFocalPoint.x = 0.0;
		cameraFocalPoint.y = 0.0;
		cameraAngle = 0.0;
		focalPointX = 0;
		focalPointY = 0;
		focalShiftX = 0;
		focalShiftY = 0;
		viewUpX = 0;
		viewUpY = 0;
		near = 3.0;
		maxFocalLength = 50.0;
	}
	return self;
}

- (void) subDrawRect:(NSRect)aRect
{	
	[super subDrawRect:aRect];
	
	float xCrossCenter,yCrossCenter;
	xCrossCenter = (crossPositionX-[[self curDCM] pwidth]/2) * scaleValue;
	yCrossCenter = (crossPositionY-[[self curDCM] pheight]/2) * scaleValue;
		
	// normalization of FOCAL VECTOR
	float vectNorm = sqrt(pow(focalShiftX,2)+pow(focalShiftY/[self pixelSpacingX]*[self pixelSpacingY],2));
	float maxSize = maxFocalLength;
	vectNorm = (vectNorm==0)? 1.0: vectNorm;
	maxSize = (vectNorm==0)? 0.0: maxSize;
	maxSize = (vectNorm>maxSize)? maxSize : vectNorm;
	float normalizationFactor = maxSize/vectNorm;
	
	//normalizationFactor = 1.0;
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	// antialiasing
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	
	// draw the direction vector
	glColor3f (1.0f, 0.0f, 1.0f);
	glLineWidth(1.0);
	glBegin(GL_LINES);
	glVertex2f(xCrossCenter,yCrossCenter);
	
	float cfocalShiftX = focalShiftX;
	float cfocalShiftY = focalShiftY;
	
	cfocalShiftX = cfocalShiftX;
	cfocalShiftY = cfocalShiftY;
	
	glVertex2f(	xCrossCenter+cfocalShiftX*normalizationFactor,
				yCrossCenter+cfocalShiftY*normalizationFactor);	//*[self pixelSpacingY]/[self pixelSpacingX]
	glEnd();
				
	// draw a point at the end of FOCAL POINT vector (handle to move the vector)
	glPointSize(2.0*near);
	glBegin(GL_POINTS);	
	
	glVertex2f(	xCrossCenter+cfocalShiftX*normalizationFactor,
				yCrossCenter+cfocalShiftY*normalizationFactor);	//*[self pixelSpacingY]/[self pixelSpacingX]
	glEnd();
	glPointSize(1.0);
	
	// normalization of VIEW UP VECTOR
	float vectViewUpNorm = sqrt(pow(viewUpX,2)+pow(viewUpY,2));
	float sizeViewUp = 25.0;
	vectViewUpNorm = (vectViewUpNorm==0)? 1.0: vectViewUpNorm;
	sizeViewUp = (vectViewUpNorm==0)? 0.0: sizeViewUp;
	sizeViewUp = (vectViewUpNorm>sizeViewUp)? sizeViewUp : vectViewUpNorm;
	float normalizationViewUpFactor = sizeViewUp/vectViewUpNorm*2.0;
	
	// draw the view up vecteur
	glColor3f (0.0f, 0.75f, 1.0f);
	glLineWidth(1.0);
	glBegin(GL_LINES);
	glVertex2f(xCrossCenter,yCrossCenter);
	glVertex2f(	xCrossCenter+viewUpX*normalizationViewUpFactor,
				yCrossCenter+viewUpY*normalizationViewUpFactor);	//*[self pixelSpacingY]/[self pixelSpacingX]
	glEnd();
	
	// antialiasing end
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);
}

- (void) mouseDown:(NSEvent *)theEvent
{
	NSPoint		focalPointLocation, mouseLocStart, mouseLoc;
	
		
	mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: self];
	//mouseLocStart = [self convertPoint:mouseLocStart fromView: self];
	mouseLocStart = [[[theEvent window] contentView] convertPoint:mouseLocStart toView:self];
	mouseLocStart = [self ConvertFromNSView2GL:mouseLocStart];
	
	focalPointLocation.x = crossPositionX + focalShiftX;
	focalPointLocation.y = crossPositionY + focalShiftY;
	
//	NSLog(@"mouseLocStart : %f, %f", mouseLocStart.x, mouseLocStart.y);
//	NSLog(@"crossPosition : %d, %d", crossPositionX, crossPositionY);
//	NSLog(@"focalShift : %d, %d", focalShiftX, focalShiftY);
//	NSLog(@"focalPointLocation : %f, %f", focalPointLocation.x, focalPointLocation.y);
	
	// normalization of focal vector
	float vectNorm = sqrt(pow(focalShiftX,2)+pow(focalShiftY/[self pixelSpacingX]*[self pixelSpacingY],2));
	float maxSize = maxFocalLength;
	vectNorm = (vectNorm==0)? 1.0: vectNorm;
	maxSize = (vectNorm==0)? 0.0: maxSize;
	maxSize = (vectNorm>maxSize)? maxSize : vectNorm;
	
	float normalizationFactor = maxSize/vectNorm;
	float scaleFactor = scaleValue;
	
//	if( (mouseLocStart.x > focalPointLocation.x-near && mouseLocStart.x < focalPointLocation.x+near) &&
//		(mouseLocStart.y > focalPointLocation.y-near && mouseLocStart.y < focalPointLocation.y+near) )
//	if( (mouseLocStart.x > focalPointX-near && mouseLocStart.x < focalPointX+near) &&
//		(mouseLocStart.y > focalPointY-near && mouseLocStart.y < focalPointY+near) )
	if( (mouseLocStart.x > crossPositionX+focalShiftX*normalizationFactor/scaleFactor-near/scaleFactor && mouseLocStart.x < crossPositionX+focalShiftX*normalizationFactor/scaleFactor+near/scaleFactor) &&
		(mouseLocStart.y > crossPositionY+focalShiftY*normalizationFactor/scaleFactor-near/scaleFactor && mouseLocStart.y < crossPositionY+focalShiftY*normalizationFactor/scaleFactor+near/scaleFactor) )		//
	{	
		NSLog(@"****mouseLocStart : %f, %f", mouseLocStart.x, mouseLocStart.y);
		BOOL keepOn = YES;
		while (keepOn)
		{
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			
			//mouseLoc = [theEvent locationInWindow];	//[self convertPoint: [theEvent locationInWindow] fromView:nil];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView: self];
			mouseLoc = [[[theEvent window] contentView] convertPoint:mouseLoc toView:self];
			mouseLoc = [self ConvertFromNSView2GL:mouseLoc];
			
			switch ([theEvent type])
			{
				case NSLeftMouseDragged:
					focalShiftX = (mouseLoc.x - crossPositionX)*scaleFactor;
					focalShiftY = (mouseLoc.y - crossPositionY)*scaleFactor;
					
					if( xFlipped) focalShiftX = -focalShiftX;
					if( yFlipped) focalShiftY = -focalShiftY;
					
					[self setFocalShiftX:focalShiftX];
					[self setFocalShiftY:focalShiftY];
					[self setNeedsDisplay:YES];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"changeFocalPoint" object:self  userInfo: nil];
				break;
				
				case NSLeftMouseUp:
					keepOn = NO;
				break;
					
				case NSPeriodic:
					
				break;
					
				default:
				
				break;
			}
		}
		[self setNeedsDisplay:YES];
	}
	else
	{
		[super mouseDown:theEvent];
	}
}

- (void) setCrossPosition: (float) x: (float) y
{
	[super setCrossPosition: x: y];
	//focalShiftX = focalPointX - crossPositionX;
	//focalShiftY = focalPointY - crossPositionY;
	[self setFocalShiftX:[self focalShiftX]]; // will recompute focalPointX
	[self setFocalShiftY:[self focalShiftY]]; // will recompute focalPointX
	[[NSNotificationCenter defaultCenter] postNotificationName: @"changeFocalPoint" object:self  userInfo: nil];
	[(EndoscopyViewer*)[[self controller] viewer] setCamera];
}

- (void) setCrossPositionX: (float) x
{
	[super setCrossPositionX: x];
	//focalShiftX = focalPointX - crossPositionX;
}

- (void) setCrossPositionY: (float) y
{
	[super setCrossPositionY: y];
	//focalShiftY = focalPointY - crossPositionY;
}

- (void) adjustWLWW:(float) wl :(float) ww
{
	[super adjustWLWW :wl :ww];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Update2DWLWWMenu" object: curWLWWMenu userInfo: nil];
}

- (void) setCameraPosition: (float) x : (float) y
{
	//NSLog(@"setCameraPosition: %f, %f", x, y);
	cameraPosition.x = x;
	cameraPosition.y = y;
	
//	y = ([[self controller] sign]>0)? [[originalView dcmPixList] count]-sliceIndex-1 : sliceIndex ;
//	[[self controller] reslice: (long)x+0.5:  (long)y+0.5: self];
//	[self setCrossPositionX: (float)x];
//	[self setCrossPositionY: (float)y];
//	[self setCrossPosition:x+[[self curDCM] pwidth]/2 :y+[[self curDCM] pwidth]/2];
}

- (NSPoint) cameraPosition
{
	return cameraPosition;
}

- (void) setCameraFocalPoint: (float) x : (float) y
{
	cameraFocalPoint.x = x;
	cameraFocalPoint.y = y;
}

//- (void) setCameraFocalPoint
//{
//	float x, y;
//	x = cameraPosition.x + focalShiftX * [[[self pixList] objectAtIndex:0] pixelSpacingX];
//	y = cameraPosition.y + focalShiftY * [[[self pixList] objectAtIndex:0] pixelSpacingY];
//	[self setCameraFocalPoint:x : y];
//}

- (NSPoint) cameraFocalPoint
{
	return cameraFocalPoint;
}

- (void) setCameraAngle: (float) alpha
{
	cameraAngle = alpha;
}

- (float) cameraAngle
{
	return cameraAngle;
}

- (void) setFocalPointX: (long) x
{
	focalPointX = x;
	focalShiftX = focalPointX - crossPositionX;
}

- (void) setFocalPointY: (long) y
{
	focalPointY = y;
	focalShiftY = focalPointY - crossPositionY;
}

- (long) focalPointX
{
	return focalPointX;
}

- (long) focalPointY
{
	return focalPointY;
}

- (void) setFocalShiftX: (long) x
{
	focalShiftX = x;
	focalPointX = crossPositionX + focalShiftX;
}

- (void) setFocalShiftY: (long) y
{
	focalShiftY = y;
	focalPointY = crossPositionY + focalShiftY;
}

- (long) focalShiftX
{
	return focalShiftX;
}

- (long) focalShiftY
{
	return focalShiftY;
}

- (void) setViewUpX: (long) x
{
	viewUpX = x;
}

- (void) setViewUpY: (long) y
{
	viewUpY = y;
}

- (long) viewUpX
{
	return viewUpX;
}

- (long) viewUpY
{
	return viewUpY;
}

#pragma mark-
#pragma mark Export

-(void) sendMail:(id) sender
{
	Mailer		*email;
	NSImage		*im = [self nsimage: NO];

	NSArray *representations;
	NSData *bitmapData;

	representations = [im representations];

	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

	[bitmapData writeToFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
				
	email = [[Mailer alloc] init];
	
	[email sendMail:@"--" to:@"--" subject:@"" isMIME:YES name:@"--" sendNow:NO image: [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]];
	
	[email release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
	NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
	
	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:nil file:[[[controller originalDCMFilesList] objectAtIndex:0] valueForKeyPath:@"series.name"]] == NSFileHandlingPanelOKButton)
	{		
			NSImage *im = [self nsimage:NO];
						
			NSArray *representations;
			NSData *bitmapData;
			
			representations = [im representations];
			
			bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			
			[bitmapData writeToFile:[panel filename] atomically:YES];
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

- (void) exportDICOMFile:(id) sender
{
	if ([sender isEqual:[[self window] windowController]])
	{
		DCMPix *curPix = [self curDCM];

		long	annotCopy		= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"],
				clutBarsCopy	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
		long	width, height, spp, bpp;
		float	cwl, cww;
		float	o[9];
		
		
		[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
		[[NSUserDefaults standardUserDefaults] setInteger: barHide forKey: @"CLUTBARS"];
		[DCMView setDefaults];
		
		NSMutableArray *producedFiles = [NSMutableArray array];
		
		unsigned char *data = [self superGetRawPixels:&width :&height :&spp :&bpp :YES :NO :NO];
		
		if( data)
		{
			DICOMExport *exportDCM = [[DICOMExport alloc] init];
			 
			[exportDCM setSourceFile: [[[controller originalDCMFilesList] objectAtIndex:[self curImage]] valueForKey:@"completePath"]];
			[exportDCM setSeriesDescription: @"Endoscopy"];
			
			[self getWLWW:&cwl :&cww];
			[exportDCM setDefaultWWWL: cww :cwl];
			
			[exportDCM setPixelSpacing: [curPix pixelSpacingX] / [self scaleValue] :[curPix pixelSpacingX] / [self scaleValue]];
				
			[exportDCM setSliceThickness: [curPix sliceThickness]];
			[exportDCM setSlicePosition: [curPix sliceLocation]];
			
			[self orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
			
			[exportDCM setOrientation: o];
			
			NSPoint tempPt = [self ConvertFromUpLeftView2GL: NSMakePoint( 0, 0)];				// <- Because we do screen capture !!!!!
			[curPix convertPixX: tempPt.x pixY: tempPt.y toDICOMCoords: o pixelCenter: YES];
			[exportDCM setPosition: o];
			
			[exportDCM setPixelData: data samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
			
			NSString *f = [exportDCM writeDCMFile: nil];
			if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
			
			if( f)
				[producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", [exportDCM SOPInstanceUID], @"SOPInstanceUID", nil]];
			
			[exportDCM release];
			free( data);
		}
				
		[[NSUserDefaults standardUserDefaults] setInteger: annotCopy forKey: @"ANNOTATIONS"];
		[[NSUserDefaults standardUserDefaults] setInteger: clutBarsCopy forKey: @"CLUTBARS"];
		[DCMView setDefaults];
		
		if( ([[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"] || [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"]) && [producedFiles count])
		{
			NSMutableArray *imagesForThisStudy = [NSMutableArray array];
			
			[[[BrowserController currentBrowser] managedObjectContext] lock];
			
			for( NSManagedObject *s in [[[[controller viewer] currentStudy] valueForKey: @"series"] allObjects])
				[imagesForThisStudy addObjectsFromArray: [[s valueForKey: @"images"] allObjects]];
			
			[[[BrowserController currentBrowser] managedObjectContext] unlock];
			
			NSArray *sopArray = [producedFiles valueForKey: @"SOPInstanceUID"];
			
			NSMutableArray *objects = [NSMutableArray array];
			for( NSString *sop in sopArray)
			{
				for( NSManagedObject *im in imagesForThisStudy)
				{
					if( [[im valueForKey: @"sopInstanceUID"] isEqualToString: sop])
						[objects addObject: im];
				}
			}
			
			if( [objects count] != [producedFiles count])
				NSLog( @"WARNING !! [objects count] != [producedFiles count]");
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"])
				[[BrowserController currentBrowser] selectServer: objects];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"])
			{
				for( NSManagedObject *im in objects)
					[im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
			}
		}
	}
	else
	{
		[(EndoscopyViewer*)[[self window] windowController] exportDICOMFile:sender];
	}
	
	[NSThread sleepForTimeInterval: 0.5];
	[[BrowserController currentBrowser] checkIncomingNow: self];
}

- (NSBitmapImageRep *)bitmapImageRepForCachingDisplayInRect:(NSRect)aRect
{
	long	width, height, spp, bpp;
	unsigned char *data = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
	NSBitmapImageRep *bits;
	bits = [[NSBitmapImageRep alloc] initWithData:[NSData dataWithBytes:data length:width*height*spp]];
	[bits autorelease];
	return bits;
}

-(unsigned char*) superGetRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical
{
	return [super getRawPixelsWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits:force8bits removeGraphical:removeGraphical squarePixels:YES allTiles:NO allowSmartCropping:NO origin:nil spacing:nil offset: nil isSigned: nil];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical
{
	if ([(EndoscopyViewer*)[[self window] windowController] exportAllViews])
		return [(EndoscopyViewer*)[[self window] windowController] getRawPixels:width :height :spp :bpp];
	else
		return [super getRawPixelsWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits:force8bits removeGraphical:removeGraphical squarePixels:YES allTiles:NO allowSmartCropping:NO origin:nil spacing:nil offset: nil isSigned: nil];
}

@end
