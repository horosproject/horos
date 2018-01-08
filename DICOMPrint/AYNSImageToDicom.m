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

#import "AYNSImageToDicom.h"
#import "OSIWindow.h"
#import "NSFont_OpenGL.h"
#import "Notifications.h"
#import "SeriesView.h"

extern BOOL FULL32BITPIPELINE;

@interface AYNSImageToDicom (private)
- (NSString *) _createDicomImageWithViewer: (ViewerController *) viewer toDestinationPath: (NSString *) destPath asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;
- (struct rawData) _convertRGBToGrayscale: (NSImage *) image;
- (struct rawData) _convertImageToBitmap: (NSImage *) image;
- (NSString *) generateUniqueFileName:(NSString *) destinationPath;
- (NSString*) _writeDICOMHeaderAndData: (NSDictionary*)patientDict destinationPath: (NSString*) destPath imageData:(NSImage*) image colorPrint: (BOOL)  colorPrint;
- (void) _drawAnnotationsInRect: (NSRect) imageRect forTile: (NSDictionary*) tileDict  isPrinting:(BOOL) print;
- (NSDictionary *) _getAnnotationDictionary: (ViewerController *) viewController;
@end

@implementation AYNSImageToDicom

- (id) init
{
	if(self = [super init])
	{
		m_ImageDataBytes = nil;
	}

	return self;
}

- (void) dealloc
{
	if(m_ImageDataBytes)
	{
		[m_ImageDataBytes release];
		m_ImageDataBytes = nil;
	}
	[super dealloc];
}

//********************************************************************************************
// returnValue must be retained and released by caller
//********************************************************************************************

//********************************************************************************************
- (NSDictionary*) _getAnnotationDictionary: (ViewerController*) viewController
{
	int					currentPos = [[viewController imageView] curImage];
	NSMutableArray		*filelist = [viewController fileList];
	NSManagedObject		*curImage = [filelist objectAtIndex: currentPos];
	NSManagedObject		*study = [curImage valueForKeyPath:@"series.study"];
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];

	NSArray *imageInformation = [NSArray arrayWithObjects:
		@"series.study.id",
		@"series.study.name",
		@"series.study.patientID",
		@"series.name",
		@"series.study.studyName",
		@"series.modality",
		@"series.comment",
		@"series.dateAdded",
		@"series.dicomTime",
		//@"series.seriesInstanceUID",
		@"series.stateText",
		@"patientID",
		@"referringPhysician",
		@"performingPhysician",
		@"date",
		@"dateAdded",
		@"dicomTime",
		@"institutionName",
		@"patientUID",
		nil];

	for (NSString *key in imageInformation)
	{
		if ([key hasPrefix: @"series."])
		{
			if ([curImage valueForKeyPath: key])
			{
				[infoDict setValue: [curImage valueForKeyPath: key] forKey: key];
				continue;
			}
		}
		else
		{
			if ([study valueForKey: key])
			{
				[infoDict setValue: [study valueForKey: key] forKey: key];
				continue;
			}
		}

		[infoDict setValue: @"n.a." forKey: key];
	}

	float wl = 0, ww = 0;
	//short numOfImages = 0, currentImage = 0;
	[[viewController imageView] getWLWW: &wl :&ww];	
	
	NSString *helpString = [NSString stringWithFormat: @"WL: %.0f WW: %.0f", wl, ww];
	[infoDict setObject: helpString forKey: @"wlww"];
	helpString = [NSString stringWithFormat: @"%.0f", wl];
	[infoDict setObject: helpString forKey: @"windowCenter"];
	helpString = [NSString stringWithFormat: @"%.0f", ww];
	[infoDict setObject: helpString forKey: @"windowWidth"];
	NSString *imageNumString = [NSString stringWithFormat: @"%d / %d", currentPos + 1, (int) [filelist count]];
	[infoDict setObject: imageNumString forKey: @"imageNumber"];
	//NSMutableArray *pixlist = [viewController pixList];
	//float thickness = [[pixlist objectAtIndex: currentPos] sliceThickness];
	//NSString *thicknessString = [NSString stringWithFormat:@"%.2f", thickness];
	//[infoDict setObject: thicknessString forKey: @"thickness"];
	
	//float scaleOffset = [aView scaleOffsetRegistration];
	float scaleValue = [[viewController imageView] scaleValue];
	float rotation = [[viewController imageView] rotation];
	NSString *scaleString = [NSString stringWithFormat: @"Zoom: %0.0f%% Angle: %0.0f", /*scaleOffset * */scaleValue * 100.0, (float) ((long) rotation % 360)];
	[infoDict setObject: scaleString forKey: @"zoomRotation"];
	NSImage *aImage = [[viewController imageView] nsimage:YES];
	[infoDict setObject: [NSString stringWithFormat: @"%.0f x %.0f", [aImage size].width, [aImage size].height] forKey: @"imageSize"];	
	[infoDict setObject: [NSString stringWithFormat: @"%.0f", [aImage size].width] forKey: @"imageSize.width"];
	[infoDict setObject: [NSString stringWithFormat: @"%.0f", [aImage size].height] forKey: @"imageSize.height"];
	
	return infoDict;
}

- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations 
{
	NSMutableArray *images = [NSMutableArray array];
	NSArray *fileList = [currentViewer fileList];
	
	if( [[options valueForKey:@"mode"] intValue] == eCurrentImage)
	{
		int i;
		
		if( [[currentViewer imageView] flippedData]) i = (long) [fileList count] -1 -[[currentViewer imageView] curImage];
		else i = [[currentViewer imageView] curImage];
		
		[images addObject: [NSNumber numberWithInt: i]];
	}
	else if ([[options valueForKey:@"mode"] intValue] == eAllImages)
	{
		int i;
		for (i = [[options valueForKey:@"from"] intValue]; i < [[options valueForKey:@"to"] intValue]; i += [[options valueForKey:@"interval"] intValue])
		{
			[images addObject: [NSNumber numberWithInt: i]];
		}
	}
	else if ([[options valueForKey:@"mode"] intValue] == eKeyImages)
	{
		int i;
		for (i = 0; i < [fileList count]; i++)
		{
			NSManagedObject *image;
            NSUInteger index = 0;
			
			if( [[currentViewer imageView] flippedData]) index = [fileList count] -1 -i;
			else index = i;
            
            image = [fileList objectAtIndex: index];
			
			if (![[image valueForKey: @"isKeyImage"] boolValue] && [[[currentViewer roiList] objectAtIndex:index] count] == 0)
				continue;
			
			[images addObject: [NSNumber numberWithInt: i]];
		}
	}

	return [self dicomFileListForViewer: currentViewer destinationPath: destPath options: options fileList: images asColorPrint: colorPrint withAnnotations: annotations];
}

//********************************************************************************************
// returnValue must be retained and released by caller
//********************************************************************************************
- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options fileList: (NSArray *) fileList asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations 
{
	NSMutableArray	*dicomFilePathList = [NSMutableArray array];
	int currentImageIndex = [[currentViewer imageView] curImage];
	
	/////// ****************
	
	float fontSizeCopy = [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"];
	float scaleFactor = 1.0;
	
	NSRect rf = [[currentViewer window] frame];
	BOOL m = [currentViewer magnetic];
	BOOL v = [currentViewer checkFrameSize];
	[OSIWindow setDontConstrainWindow: YES];
	[currentViewer setMagnetic : NO];
	[currentViewer setMatrixVisible: NO];
	
	int columns = [[options valueForKey: @"columns"] intValue];
	int rows = [[options valueForKey: @"rows"] intValue];
	
	float inc = (1 + ((columns - 1) * 0.35));
	if( inc > 2.0) inc = 2.0;
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"allowSmartCropping"];
	
	NSPoint o = [[[currentViewer window] screen] visibleFrame].origin;
	o.y += [[[currentViewer window] screen] visibleFrame].size.height;
	
	/////// ****************
	
	[OSIWindowController setDontEnterMagneticFunctions: YES];
	[OSIWindowController setDontEnterWindowDidChangeScreen: YES];
	
	int previousRows = [[currentViewer seriesView] imageRows], previousColumns = [[currentViewer seriesView] imageColumns];
	
	if( previousRows != 1 || previousColumns != 1)
		[currentViewer setImageRows: 1 columns: 1];
	
	BOOL copyFULL32BITPIPELINE = FULL32BITPIPELINE;
	
    FULL32BITPIPELINE = NO;
    
	for(NSNumber *imageIndex in fileList)
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		[currentViewer setImageIndex: [imageIndex intValue]];
		
		BOOL windowSizeChanged = NO;
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"printAt100%Minimum"] && [currentViewer scaleValue] < 1.0)
		{
			scaleFactor = 1. / [currentViewer scaleValue];
			
			int MAXWindowSize = [[NSUserDefaults standardUserDefaults] integerForKey: @"MAXWindowSize"];
			
			int noFactor = (columns * rows) / 2;
			if( noFactor < 1) noFactor = 1;
			if( noFactor > 6) noFactor = 6;
			
			int cMAXWindowSize = MAXWindowSize / noFactor;
			
			if( rf.size.width * scaleFactor > cMAXWindowSize)
				scaleFactor = cMAXWindowSize / rf.size.width;
			
			if( rf.size.height * scaleFactor > cMAXWindowSize)
				scaleFactor = cMAXWindowSize / rf.size.height;
			
			if( scaleFactor <= 1.0)
				scaleFactor = 1.0;
			else
			{
				windowSizeChanged = YES;
				[[currentViewer window] setFrame: NSMakeRect( o.x, o.y, rf.size.width * scaleFactor, rf.size.height * scaleFactor) display: YES];	
			}
		}
		else scaleFactor = 1.0;
		
		if( fontSizeCopy * inc * scaleFactor * 1.2 != [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"])
		{
			[[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy * inc * scaleFactor * 1.2 forKey: @"FONTSIZE"];
			[NSFont resetFont: 0];
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixGLFontChangeNotification object: currentViewer];
		}
		
		[dicomFilePathList addObject: [self _createDicomImageWithViewer: currentViewer toDestinationPath: destPath asColorPrint: colorPrint withAnnotations: annotations]];
		
		if( windowSizeChanged)
			[[currentViewer window] setFrame: NSMakeRect( o.x, o.y, rf.size.width, rf.size.height) display: YES];
		
		[pool release];
	}
	
	FULL32BITPIPELINE = copyFULL32BITPIPELINE;
	
	/////// ****************
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"allowSmartCropping"];
	
	if( fontSizeCopy != [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"])
	{
		[[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy forKey: @"FONTSIZE"];
		[NSFont resetFont: 0];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixGLFontChangeNotification object: currentViewer];
	}
	
	[currentViewer setMagnetic : m];
	[[currentViewer window] setFrame: rf display: YES];
	[currentViewer setMatrixVisible: v];
	
	if( previousRows != 1 || previousColumns != 1)
		[currentViewer setImageRows: previousRows columns: previousColumns];
	
	[OSIWindowController setDontEnterMagneticFunctions: NO];
	[OSIWindowController setDontEnterWindowDidChangeScreen: NO];
	
	/////// ****************
	
	[[currentViewer imageView] setIndex: currentImageIndex];
	[[currentViewer imageView] sendSyncMessage:0];
	[currentViewer adjustSlider];
	
	return dicomFilePathList;
}

//********************************************************************************************
- (NSString *) _createDicomImageWithViewer: (ViewerController *) viewer toDestinationPath: (NSString *) destPath asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations
{
	NSImage *currentImage = [[viewer imageView] nsimage];
	
	NSDictionary *patientInfoDict = [self _getAnnotationDictionary: viewer];
	
	NSString *imagePath = [self _writeDICOMHeaderAndData: patientInfoDict destinationPath: destPath imageData: currentImage colorPrint: colorPrint];
	
	if( imagePath == nil)
	{
		NSLog( @"WARNING imagePath == nil");
		imagePath = @"";
	}
	return imagePath;
}


//********************************************************************************************
- (NSString*) generateUniqueFileName:(NSString*) destinationPath
{
	NSTimeInterval secs = [NSDate timeIntervalSinceReferenceDate];
	NSString *filePath = [destinationPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%ld", (long) secs]];
	int index = 0;
	BOOL isDir = YES;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isDir] && isDir)
		[[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSString *tempFilePath;
	
	do
	{
		tempFilePath = [filePath stringByAppendingFormat: @"-%d.dcm", index];
		index++;
	}while( [[NSFileManager defaultManager] fileExistsAtPath: tempFilePath] == YES);
	
	return tempFilePath;
}

//********************************************************************************************
- (struct rawData) _convertImageToBitmap: (NSImage *) image
{
	NSBitmapImageRep *imageRepresentation = [NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]];
	
	struct rawData rawImage;
	
	rawImage.imageData = nil;
	rawImage.bytesWritten = 0;
	
	if( [imageRepresentation samplesPerPixel] != 3) return rawImage;
	
	if( imageRepresentation)
	{
		long bytesWritten = [imageRepresentation bytesPerRow] * [imageRepresentation size].height;
		if(m_ImageDataBytes)
		{
			[m_ImageDataBytes release];
			m_ImageDataBytes = nil;
		}
		
		m_ImageDataBytes = [[NSMutableData alloc] initWithBytes: [imageRepresentation bitmapData] length: bytesWritten];
		if(bytesWritten % 2 != 0)
		{
			char zero = 0;
			[m_ImageDataBytes appendBytes: &zero length: 1];
			bytesWritten++;
		}
		
		rawImage.bytesWritten = bytesWritten;
		
		return rawImage;
	}
	
	return rawImage;
}

//********************************************************************************************
- (struct rawData) _convertRGBToGrayscale: (NSImage *) image
{
	NSBitmapImageRep *imageRepresentation = [NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]];
	
	struct rawData rawImage;
	rawImage.imageData = nil;
	rawImage.bytesWritten = 0;
	
	if( [imageRepresentation samplesPerPixel] != 3)
		return rawImage;
	
	long bytesWritten = 0;
	if(m_ImageDataBytes)
	{
		[m_ImageDataBytes release];
		m_ImageDataBytes = nil;
	}
	
	m_ImageDataBytes = [[NSMutableData alloc] initWithCapacity: ([imageRepresentation bytesPerRow] * [imageRepresentation size].height) + 1];
	
	float monoR, monoG, monoB;
	unsigned char grayValue = 0;
	unsigned char * bitMapDataPtr = (unsigned char *) [imageRepresentation bitmapData];

	int i;
	for(i = 0; i < [imageRepresentation size].height; i++)
	{
		unsigned char *sourceBuffer = bitMapDataPtr + i * [imageRepresentation bytesPerRow];

		int x;
		for(x = 0; x <  [imageRepresentation size].width; x++)
		{
			monoR = 0.299 * (float) *sourceBuffer++;	//76.245
			monoG = 0.587 * (float) *sourceBuffer++;	//149.685
			monoB = 0.114 * (float) *sourceBuffer++;	//29.07
			
			grayValue = roundf(monoR + monoG + monoB);
			[m_ImageDataBytes appendBytes: &grayValue length: 1];
			bytesWritten++;
		}
	}

	if(bytesWritten % 2 != 0)
	{
		grayValue = 0;
		[m_ImageDataBytes appendBytes: &grayValue length: 1];
		bytesWritten++;
	}
	
	rawImage.imageData = nil;
	rawImage.bytesWritten = bytesWritten;
	return rawImage;
}


//********************************************************************************************
- (void) _drawString: (id) stringObj atPoint: (NSPoint) point withFontSize: (float) fontSize atRightBorder: (BOOL) rightBorder
{
	float whiteXOffset = 1.0;
	float whiteYOffset = 1.0;

	NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
	NSString *fontName = @"Andale Mono";
	[attribs setObject: [NSFont fontWithName: fontName size: fontSize] forKey: NSFontAttributeName];
	NSMutableAttributedString *attribString = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@", stringObj] attributes: attribs];

	if (rightBorder)
		point.x -= [attribString size].width;

	[attribs setObject: [NSColor blackColor] forKey: NSForegroundColorAttributeName];
	[attribString setAttributes: attribs range: NSMakeRange(0, [attribString length])];
	[attribString drawAtPoint: point];

	[attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
	[attribString setAttributes: attribs range: NSMakeRange(0, [attribString length])];
	[attribString drawAtPoint: NSMakePoint(point.x + whiteXOffset, point.y + whiteYOffset)];

	[attribString release];
}

//********************************************************************************************
- (void) _drawAnnotationsInRect: (NSRect) imageRect forTile: (NSDictionary*) tileDict  isPrinting:(BOOL) print
{
	int theLongest = 0;
	NSArray *values = [tileDict allValues];
	for (id loopItem in values)
	{
		NSString *value = [NSString stringWithFormat: @"%@",  loopItem];

		if (theLongest < [value length])
			theLongest = [value length];
	}

	float fontSize = imageRect.size.width / theLongest;

	//---------------------------------
	// upper left corner
	float nextX = imageRect.origin.x + 3;
	float nextY = imageRect.origin.y;

	// image Size
	[self _drawString: [tileDict objectForKey: @"imageSize"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: NO];

	// view size
	nextY += fontSize + 2;
	[self _drawString: [NSString stringWithFormat: @"View size: %.0f x %.0f", imageRect.size.width, imageRect.size.height] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: NO];

	// WL WW
	nextY += fontSize + 2;
	[self _drawString: [NSString stringWithFormat: @"%@", [tileDict objectForKey: @"wlww"]] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: NO];

	//---------------------------------
	// lower left corner
	nextY = imageRect.size.height - fontSize - 10;

	// thickness
	[self _drawString: [tileDict objectForKey: @"thickness"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: NO];

	// zoom
	nextY -= fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"zoomRotation"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: NO];

	// image number
	nextY -= fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"imageNumber"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: NO];
	
	//---------------------------------
	// upper right corner
	nextX = imageRect.size.width - 5;
	nextY = imageRect.origin.y;

	// institution name
	[self _drawString: [tileDict objectForKey: @"institutionName"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// patient name
	nextY += fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"series.study.name"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// patient id
	nextY += fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"series.study.patientID"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// study name
	nextY += fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"series.study.studyName"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// series id
	nextY += fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"series.study.id"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	//---------------------------------
	// lower right corn
	nextY = imageRect.size.height - fontSize - 10;

	// referring physician
	//[self _drawString: [NSString stringWithFormat: @"ref.Ph.: %@", [tileDict objectForKey: @"referringPhysician"]] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// date added
	//nextY -= fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"dateAdded"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// date time
	nextY -= fontSize + 2;
	[self _drawString: [tileDict objectForKey: @"dicomTime"] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];

	// performing physician
	nextY -= fontSize + 2;
	[self _drawString: [NSString stringWithFormat: @"perf.Ph.: %@", [tileDict objectForKey: @"performingPhysician"]] atPoint: NSMakePoint(nextX, nextY) withFontSize: fontSize atRightBorder: YES];
}

//********************************************************************************************
- (NSString*) _writeDICOMHeaderAndData: (NSDictionary *) patientDict destinationPath: (NSString *) destPath imageData: (NSImage *) image colorPrint: (BOOL) colorPrint
{
	NSString *path = nil;
	path = [self generateUniqueFileName: destPath];
	FILE *outFile = nil;
	short group = 0, element = 0, dummyShort = 0, samplePerPixel = 1;
	//char	singleDummy;
	long dummyLong = 0;
	long metaElementGroupLengthPosition;
	long metaElementGroupLength = 0;
	long dataSizePos = 0;
	//char outBuffer[255];
	//char zero = 0x00;

	if(!path)
		return nil;

	outFile = fopen([path fileSystemRepresentation],"wb");
	if( outFile == 0) return nil;
	
	fseek(outFile, 0, 0);
	int i = 0;
	for(i = 0; i < 128; i++)
	{
		fwrite("\0", 1, 1, outFile);
	}
	fwrite("DICM", 1, 4, outFile);
	
	// MetaElementGroupLength
	group = 0x0002;
	element = 0x0000;
	group = CFSwapInt16HostToLittle(group);
	element = CFSwapInt16HostToLittle(element);
	dummyShort = 0x0004;
	dummyShort = CFSwapInt16HostToLittle(dummyShort);
	fwrite(&group, 2, 1, outFile);
	fwrite(&element, 2, 1, outFile);
	fwrite("UL", 2, 1, outFile);
	fwrite(&dummyShort, 2, 1, outFile);
	metaElementGroupLengthPosition = ftell(outFile); //must test this!!!! masu
	// fill position
	fwrite(&dummyLong, 4, 1, outFile);
	//metaElementGroupLength += sizeof(long);
	
	// start here to count the bytes of the Meta-Header
	//FileMetaInformationVersion
	element = CFSwapInt16HostToLittle(0x0001);
	fwrite(&group, 2, 1, outFile);
	fwrite(&element, 2, 1, outFile);
	fwrite("OB", 2, 1, outFile);
	dummyShort = 0x0000;
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = 0x0000;
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0001);
	fwrite(&dummyShort, 2, 1, outFile);
	//dummyShort = CFSwapInt16HostToLittle(0x0002);
	
	// MediaStorageSOPClassUID
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0002);
	fwrite(&element, 2, 1, outFile);
	fwrite("UI", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("MediaStorageSOPClassUID "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("MediaStorageSOPClassUID ", strlen("MediaStorageSOPClassUID "), 1, outFile);
	//fwrite(&zero, 1, 1, outFile);
	metaElementGroupLength = metaElementGroupLength + 22 + CFSwapInt16HostToLittle(dummyShort);
	
	// MediaStorageSOPInstanceUID
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0003);
	fwrite(&element, 2, 1, outFile);
	fwrite("UI", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("MediaStorageSOPInstanceUID"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("MediaStorageSOPClassUID", strlen("MediaStorageSOPInstanceUID"), 1, outFile);
	//fwrite(&zero, 1, 1, outFile);
	metaElementGroupLength = metaElementGroupLength + 8 + CFSwapInt16HostToLittle(dummyShort);
	
	//TransferSyntaxUID
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0010);
	fwrite(&element, 2, 1, outFile);
	fwrite("UI", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("TransferSyntaxUID "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("TransferSyntaxUID ", strlen("TransferSyntaxUID "), 1, outFile);
	//fwrite(&zero, 1, 1, outFile);
	metaElementGroupLength = metaElementGroupLength + 8 + CFSwapInt16HostToLittle(dummyShort);

	//ImplementationClassUID
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0012);
	fwrite(&element, 2, 1, outFile);
	fwrite("SH", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("ImplementationClassUID"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("ImplementationClassUID", strlen("ImplementationClassUID"), 1, outFile);
	//fwrite(&zero, 1, 1, outFile);
	metaElementGroupLength = metaElementGroupLength + 8 + CFSwapInt16HostToLittle(dummyShort);
	
	//ImplementationVersionName
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0013);
	fwrite(&element, 2, 1, outFile);
	fwrite("SH", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("ImplementationVersionName "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("ImplementationVersionName ", strlen("ImplementationVersionName "), 1, outFile);
	//fwrite(&zero, 1, 1, outFile);
	metaElementGroupLength = metaElementGroupLength + 8 + CFSwapInt16HostToLittle(dummyShort);
	
	//SourceApplicationEntityTitle
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0016);
	fwrite(&element, 2, 1, outFile);
	fwrite("AE", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("SourceApplicationEntityTitle"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("SourceApplicationEntityTitle", strlen("SourceApplicationEntityTitle"), 1, outFile);
	//fwrite(&zero, 1, 1, outFile);
	
	metaElementGroupLength = metaElementGroupLength + 8 + CFSwapInt16HostToLittle(dummyShort);
	//metaElementGroupLength -= 2;
	// seek back to write metaheader size
	long currentPos = ftell(outFile);
	fseek(outFile, metaElementGroupLengthPosition, 0);
	metaElementGroupLength = CFSwapInt32HostToLittle(metaElementGroupLength);
	fwrite(&metaElementGroupLength, 4, 1, outFile);
	fseek(outFile, currentPos, 0);
	
	// SpecificCharacterSet
	// --> filler
	group = CFSwapInt16HostToLittle(0x0008);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0005);
	fwrite(&element, 2, 1, outFile);
	
	fwrite("CS", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("ISO_IR 100"));
	fwrite(&dummyShort, 2, 1, outFile);	
	fwrite("ISO_IR 100", strlen("ISO_IR 100"), 1, outFile);
	
	//ImageType
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0008);
	fwrite(&element, 2, 1, outFile);
	fwrite("CS", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("SomeKindOfImageType "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("SomeKindOfImageType ", strlen("SomeKindOfImageType "), 1, outFile);
	
	
	//SOPClassUID
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0016);
	fwrite(&element, 2, 1, outFile);
	fwrite("UI", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("SOPClassUID "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("SOPClassUID ", strlen("SOPClassUID "), 1, outFile);
	
	//SOPInstanceUID
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0018);
	fwrite(&element, 2, 1, outFile);
	fwrite("UI", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("SOPInstanceUID"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("SOPInstanceUID", strlen("SOPInstanceUID"), 1, outFile);
	
	//StudyDate
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0020);
	fwrite(&element, 2, 1, outFile);
	fwrite("DA", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("20010101"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("20010101", strlen("20010101"), 1, outFile);
	
	//SeriesDate
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0021);
	fwrite(&element, 2, 1, outFile);
	fwrite("DA", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("20010101"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("20010101", strlen("20010101"), 1, outFile);
	
	//AcquisitionDate
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0022);
	fwrite(&element, 2, 1, outFile);
	fwrite("DA", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("20010101"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("20010101", strlen("20010101"), 1, outFile);
	
	//ContentDate
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0023);
	fwrite(&element, 2, 1, outFile);
	fwrite("DA", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("20010101"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("20010101", strlen("20010101"), 1, outFile);
	
	//StudyTime
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0030);
	fwrite(&element, 2, 1, outFile);
	fwrite("TM", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("120000.000000 "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("120000.000000 ", strlen("120000.000000 "), 1, outFile);
	
	//SeriesTime
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0031);
	fwrite(&element, 2, 1, outFile);
	fwrite("TM", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("120000.000000 "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("120000.000000 ", strlen("120000.000000 "), 1, outFile);
	
	//AcquisitionTime
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0032);
	fwrite(&element, 2, 1, outFile);
	fwrite("TM", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("120000.000000 "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("120000.000000 ", strlen("120000.000000 "), 1, outFile);
	
	//ContentTime
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0033);
	fwrite(&element, 2, 1, outFile);
	fwrite("TM", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("120000.000000 "));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("120000.000000 ", strlen("120000.000000 "), 1, outFile);
	
	//AccessionNumber
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0050);
	fwrite(&element, 2, 1, outFile);
	fwrite("SH", 2, 1, outFile); //0P10008543998000
	dummyShort = CFSwapInt16HostToLittle(strlen("0P10008543998000"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("0P10008543998000", strlen("0P10008543998000"), 1, outFile);
	
	//Modality
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0060);
	fwrite(&element, 2, 1, outFile);
	fwrite("CS", 2, 1, outFile);
	dummyShort = [[patientDict objectForKey:@"series.modality"] length];
	dummyShort = CFSwapInt16HostToLittle(dummyShort);
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite([[patientDict objectForKey:@"series.modality"] UTF8String], [[patientDict objectForKey:@"series.modality"] length], 1, outFile);
	
	//Manufacturer
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0070);
	fwrite(&element, 2, 1, outFile);
	fwrite("LO", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("_aycan"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("_aycan", strlen("_aycan"), 1, outFile);
	
	//InstitutionName
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0080);
	fwrite(&element, 2, 1, outFile);
	fwrite("LO", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("HOSPITAL"));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("HOSPITAL", strlen("HOSPITAL"), 1, outFile);
	
	//InstitutionAdress
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0081);
	fwrite(&element, 2, 1, outFile);
	fwrite("ST", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen(""));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("", strlen(""), 1, outFile);
	
	// new group
	//Patientname
	group = CFSwapInt16HostToLittle(0x0010);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0010);
	fwrite(&element, 2, 1, outFile);
	fwrite("PN", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen(""));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("", strlen(""), 1, outFile);
	
	//PatientID
	group = CFSwapInt16HostToLittle(0x0010);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0020);
	fwrite(&element, 2, 1, outFile);
	fwrite("LO", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen(""));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("", strlen(""), 1, outFile);
	
	//PatientBirthDay
	group = CFSwapInt16HostToLittle(0x0010);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0030);
	fwrite(&element, 2, 1, outFile);
	fwrite("DA", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen(""));
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite("", strlen(""), 1, outFile);
	
	// newe group
	// Slicethickness
	group = CFSwapInt16HostToLittle(0x0018);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0050);
	fwrite(&element, 2, 1, outFile);
	fwrite("DS", 2, 1, outFile);
	NSMutableString *outString = [patientDict objectForKey:@"thickness"]; 
	//NSLog(@"outString = %@", outString);
	dummyShort = CFSwapInt16HostToLittle(0x0004);
	fwrite(&dummyShort, 2, 1, outFile);
	long floatStringValue = [outString doubleValue];
	//floatStringValue = CFSwapInt32HostToLittle(floatStringValue);
	fwrite(&floatStringValue, 4, 1, outFile);
	
	
//------------------------------------------------------------
	// new group
	
	group = CFSwapInt16HostToLittle(0x2020);
		//Basic Grayscale Image Sequence  (2020,0110) SQ
		//Basic Color Image Sequence  (2020,0111) SQ

	fwrite(&group, 2, 1, outFile);
	if (colorPrint)
		element = CFSwapInt16HostToLittle(0x0111);
	else
		element = CFSwapInt16HostToLittle(0x0110);
	fwrite(&element, 2, 1, outFile);
	fwrite("SQ", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0000);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyLong = CFSwapInt32HostToLittle(0xFFFFFFFF);
	fwrite(&dummyLong, 4, 1, outFile);

	//first and unique element of the sequence
	
	dummyShort = CFSwapInt16HostToLittle(0xFFFE);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0xE000);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyLong = CFSwapInt32HostToLittle(0xFFFFFFFF);
	fwrite(&dummyLong, 4, 1, outFile);

	
	// new group

	group = CFSwapInt16HostToLittle(0x0028);
	
	// samplePerPixel
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0002);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	if (colorPrint) samplePerPixel = 3;
	else samplePerPixel = 1;
	dummyShort = CFSwapInt16HostToLittle(samplePerPixel);
	fwrite(&dummyShort, 2, 1, outFile);
	
	
	
	//PhotometricInterpretation		
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0004);
	fwrite(&element, 2, 1, outFile);
	fwrite("CS", 2, 1, outFile);
	if (colorPrint)
		dummyShort = CFSwapInt16HostToLittle(strlen("RGB "));
	else
		dummyShort = CFSwapInt16HostToLittle(strlen("MONOCHROME2 "));
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x001);
	if (colorPrint)
		fwrite("RGB ", strlen("RGB "), 1, outFile);
	else
		fwrite("MONOCHROME2 ", strlen("MONOCHROME2 "), 1, outFile);

// 08 C.7.6.3.1.3 Planar Configuration 
//Planar Configuration (0028,0006) indicates whether the color pixel data are sent color-by-plane or 
//color-by-pixel. This Attribute shall be present if Samples per Pixel (0028,0002) has a value greater 
//than 1. It shall not be present otherwise.

// in image box picture: 1 (frame interleave) 
// dcmtk dcmprscp:   cannot update Basic Grayscale Image Box: unsupported attribute in basic grayscale image sequence

	if (colorPrint)
	{
		// planarConfiguration
		fwrite(&group, 2, 1, outFile);
		element = CFSwapInt16HostToLittle(0x0006);
		fwrite(&element, 2, 1, outFile);
		fwrite("US", 2, 1, outFile);
		dummyShort = CFSwapInt16HostToLittle(0x0002);
		fwrite(&dummyShort, 2, 1, outFile);
		dummyShort = CFSwapInt16HostToLittle(0x0000);
		fwrite(&dummyShort, 2, 1, outFile);
	}

	// rows
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0010);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	outString = [NSMutableString stringWithFormat: @"%.0f", [image size].height];//[patientDict objectForKey:@"imageSize.width"]; 
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	short stringIntValue = [outString intValue];
	stringIntValue = CFSwapInt16HostToLittle(stringIntValue);
	fwrite(&stringIntValue, 2, 1, outFile);
	
	
	// Columns
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0011);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	outString = [NSMutableString stringWithFormat: @"%.0f", [image size].width];//[patientDict objectForKey:@"imageSize.height"]; 
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	stringIntValue = [outString intValue];
	stringIntValue = CFSwapInt16HostToLittle(stringIntValue);
	fwrite(&stringIntValue, 2, 1, outFile);
	
	

	// aspect ratio
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0034);
	fwrite(&element, 2, 1, outFile);
	fwrite("IS", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(strlen("1\\1 "));
	fwrite(&dummyShort, 2, 1, outFile);
	//dummyShort = CFSwapInt16HostToLittle(m_BitsAllocated);
	fwrite("1\\1 ", strlen("1\\1 "), 1, outFile);
	
	// bitsAllocated
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0100);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(8);
	fwrite(&dummyShort, 2, 1, outFile);
	
	// BitsStored
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0101);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(8);
	fwrite(&dummyShort, 2, 1, outFile);
	
	// HighBit
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0102);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(7);
	fwrite(&dummyShort, 2, 1, outFile);
	
	// PixelRepresentation
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0103);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0000);
	fwrite(&dummyShort, 2, 1, outFile);
/*	
	//SmallestImagePixelValue
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0106);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0000);
	fwrite(&dummyShort, 2, 1, outFile);
	
	//LargestImagePixelValue
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0107);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0048);
	fwrite(&dummyShort, 2, 1, outFile);
	
	
	
	//WindowCenter
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x1050);
	fwrite(&element, 2, 1, outFile);
	fwrite("DS", 2, 1, outFile);
	outString = [patientDict objectForKey:@"windowCenter"]; 
	outString = [NSMutableString stringWithFormat:@"%@/%@", outString, outString];
	if([outString length] % 2 != 0)
		[outString appendString: @" "];
	dummyShort = CFSwapInt16HostToLittle([outString length]);
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite([outString UTF8String], [outString length], 1, outFile);
	
	//WindowWidth
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x1051);
	fwrite(&element, 2, 1, outFile);
	fwrite("DS", 2, 1, outFile);
	outString = [patientDict objectForKey:@"windowWidth"]; 
	outString = [NSMutableString stringWithFormat:@"%@/%@", outString, outString];
	if([outString length] % 2 != 0)
		[outString appendString: @" "];
	dummyShort = CFSwapInt16HostToLittle([outString length]);
	fwrite(&dummyShort, 2, 1, outFile);
	fwrite([outString UTF8String], [outString length], 1, outFile);
*/	
	// new group
	// image data
	group = CFSwapInt16HostToLittle(0x7fe0);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0010);
	fwrite(&element, 2, 1, outFile);
	fwrite("OW", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0000);
	fwrite(&dummyShort, 2, 1, outFile);
	//image 8 bit
	dummyLong = CFSwapInt32HostToLittle([image size].width * [image size].height * samplePerPixel);
	dataSizePos = ftell(outFile);
	fwrite(&dummyLong, 4, 1, outFile);

	struct rawData rawImage;
	if (colorPrint)
		rawImage = [self _convertImageToBitmap: image];
	else
		rawImage = [self _convertRGBToGrayscale: image];
	
	if( rawImage.bytesWritten && m_ImageDataBytes)
	{
		fwrite([m_ImageDataBytes bytes], [m_ImageDataBytes length], 1, outFile);
		
		fseek(outFile, dataSizePos, 0);
		rawImage.bytesWritten = CFSwapInt32HostToLittle(rawImage.bytesWritten);
		fwrite(&rawImage.bytesWritten, 4, 1, outFile);
		if(m_ImageDataBytes)
		{
			[m_ImageDataBytes release];
			m_ImageDataBytes = nil;
		}
		//end element and end sequence
		//go to end of image
		fseek (outFile, 0, SEEK_END);
		dummyShort = CFSwapInt16HostToLittle(0xFFFE);
		//end element and end sequence
		fwrite(&dummyShort, 2, 1, outFile);
		dummyShort = CFSwapInt16HostToLittle(0xE00D);
		fwrite(&dummyShort, 2, 1, outFile);
		dummyLong = CFSwapInt32HostToLittle(0x00000000);
		fwrite(&dummyLong, 4, 1, outFile);
		dummyShort = CFSwapInt16HostToLittle(0xFFFE);
		fwrite(&dummyShort, 2, 1, outFile);
		dummyShort = CFSwapInt16HostToLittle(0xE0DD);
		fwrite(&dummyShort, 2, 1, outFile);
		dummyLong = CFSwapInt32HostToLittle(0x00000000);
		fwrite(&dummyLong, 4, 1, outFile);
		
		fclose(outFile);
	}
	else return nil;
	
	return path;
}

@end
