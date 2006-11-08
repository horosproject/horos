//
//  AYNSImageToDicom.m
//  FilmComposer
//
//  Created by Martin Suda on 03.07.06.
//  Copyright 2006 aycan digitalsysteme gmbh. All rights reserved.
//

#import "AYNSImageToDicom.h"

// masu 2006-10-02
// it seems that memory allocated in a method can not be released in an other
// try to make it global as a workaround
//struct rawData rawImage;


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

	int i;
	for (i = 0; i < [imageInformation count]; i++)
	{
		NSString *key = [imageInformation objectAtIndex: i];
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
	NSString *imageNumString = [NSString stringWithFormat: @"%d / %d", currentPos + 1, [filelist count]]; 	
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
	[aImage release];
	return infoDict;
}

- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations 
{
	NSMutableArray *images = [NSMutableArray array];

	if( [[options valueForKey:@"mode"] intValue] == eCurrentImage)
	{
		[images addObject: [NSNumber numberWithInt: [[currentViewer imageView] curImage]]];
	}
	else if ([[options valueForKey:@"mode"] intValue] == eAllImages)
	{
		NSArray *fileList = [currentViewer fileList];

		int i;
		for (i = [[options valueForKey:@"from"] intValue]; i < [[options valueForKey:@"to"] intValue]; i += [[options valueForKey:@"interval"] intValue])
		{
			[images addObject: [NSNumber numberWithInt: i]];
		}
	}
	else if ([[options valueForKey:@"mode"] intValue] == eKeyImages)
	{
		NSArray *fileList = [currentViewer fileList];

		int i;
		for (i = 0; i < [fileList count]; i++)
		{
			NSManagedObject *image;
			
			if( [[currentViewer imageView] flippedData]) image = [fileList objectAtIndex: [fileList count] -1 -i];
			else image = [fileList objectAtIndex: i];
			
			if (![[image valueForKey: @"isKeyImage"] boolValue])
				continue;
			
			[images addObject: [NSNumber numberWithInt: i]];
		}
	}

	return [self dicomFileListForViewer: currentViewer destinationPath: destPath fileList: images asColorPrint: colorPrint withAnnotations: annotations];
}

//********************************************************************************************
// returnValue must be retained and released by caller
//********************************************************************************************
- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath fileList: (NSArray *) fileList asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations
{
	NSMutableArray	*dicomFilePathList = [NSMutableArray arrayWithCapacity: 0];
	int currentImageIndex = [[currentViewer imageView] curImage];

	int i;
	for(i = 0; i < [fileList count]; i++)
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		[currentViewer setImageIndex: [[fileList objectAtIndex: i] intValue]];
		[dicomFilePathList addObject: [self _createDicomImageWithViewer: currentViewer toDestinationPath: destPath asColorPrint: colorPrint withAnnotations: annotations]];
		
		[pool release];
	}

	[[currentViewer imageView] setIndex: currentImageIndex];
	[[currentViewer imageView] sendSyncMessage:1];
	[currentViewer adjustSlider];
	
	return dicomFilePathList;
}

//********************************************************************************************
- (NSString *) _createDicomImageWithViewer: (ViewerController *) viewer toDestinationPath: (NSString *) destPath asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations
{
	NSImage *currentImage = [[viewer imageView] nsimage: NO];
	[currentImage setFlipped: YES];

	NSRect sourceRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
	NSRect imageRect;
	float rescale = 1;
	
	// Rescale image if resolution is too high, compared to the original resolution
	
	#define MAXSIZE 1.3
	
	if(		[currentImage size].width > [[[viewer imageView] curDCM] pwidth]*MAXSIZE &&
			[currentImage size].height > [[[viewer imageView] curDCM] pheight]*MAXSIZE)
		{
			if( [currentImage size].width/[[[viewer imageView] curDCM] pwidth] < [currentImage size].height / [[[viewer imageView] curDCM] pheight])
			{
				float ratio = [currentImage size].width / ([[[viewer imageView] curDCM] pwidth] * MAXSIZE);
				imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
				
				NSLog( @"ratio: %f", ratio);
			}
			else
			{
				float ratio = [currentImage size].height / ([[[viewer imageView] curDCM] pheight] * MAXSIZE);
				imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
				
				NSLog( @"ratio: %f", ratio);
			}
		}
	else imageRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
	
	NSImage *compositingImage = [[NSImage alloc] initWithSize: imageRect.size];
	[compositingImage setFlipped: YES];
	[currentImage setScalesWhenResized:YES];
	[compositingImage lockFocus];
	[currentImage drawInRect: imageRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
	[[NSColor whiteColor] set];
	[NSBezierPath setDefaultLineWidth: 2.0];
	[NSBezierPath strokeRect: NSMakeRect(imageRect.origin.x + 1, imageRect.origin.y + 1, imageRect.size.width - 1, imageRect.size.height - 1)];
	[currentImage release];
	
	NSLog( @"Size: %f %f", [compositingImage size].width, [compositingImage size].height);
	
	NSDictionary *patientInfoDict = [self _getAnnotationDictionary: viewer];

	if (annotations)
		[self _drawAnnotationsInRect: imageRect forTile: patientInfoDict isPrinting: YES];
	
	[compositingImage unlockFocus];
	
	NSString *imagePath = [self _writeDICOMHeaderAndData: patientInfoDict destinationPath: destPath imageData: compositingImage colorPrint: colorPrint];
	
	[compositingImage release];
	// masu 2006-10-04
	
	return imagePath;
}


//********************************************************************************************
- (NSString*) generateUniqueFileName:(NSString*) destinationPath
{
	NSTimeInterval secs = [NSDate timeIntervalSinceReferenceDate];
	NSString *filePath = [NSString stringWithFormat: @"%@/%ld", destinationPath, secs];
	int index = 0;
	BOOL isDir = YES;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isDir] && isDir)
		[[NSFileManager defaultManager] createDirectoryAtPath:destinationPath attributes:nil];
	
	NSString *tempFilePath = [NSString stringWithFormat: @"%@_%d.dcm", filePath, index]; 		
	do
	{
		tempFilePath = [NSString stringWithFormat: @"%@_%d.dcm", filePath, index];
		index++;
	}while( [[NSFileManager defaultManager] fileExistsAtPath: tempFilePath] == YES);
	
	return tempFilePath;
}

//********************************************************************************************
- (struct rawData) _convertImageToBitmap: (NSImage *) image
{
	NSBitmapImageRep *imageRepresentation = [NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]];

	//unsigned char *imageData = [imageRepresentation bitmapData];
	long bytesWritten = [imageRepresentation bytesPerRow] * [imageRepresentation size].height;
	if(m_ImageDataBytes)
	{
		[m_ImageDataBytes release];
		m_ImageDataBytes = nil;
	}
	
	m_ImageDataBytes = [[NSMutableData alloc] initWithBytes: [imageRepresentation bitmapData] length: bytesWritten];
	if(bytesWritten % 2 != 0)
	{
		//imageData[bytesWritten] = '\0';
		[m_ImageDataBytes appendBytes: '\0' length: 1];
		bytesWritten++;
	}

	struct rawData rawImage;
	rawImage.imageData = nil;
	rawImage.bytesWritten = bytesWritten;

	return rawImage;
}

//********************************************************************************************
- (struct rawData) _convertRGBToGrayscale: (NSImage *) image
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSBitmapImageRep *imageRepresentation = [NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]];

	long bytesWritten = 0;
	if(m_ImageDataBytes)
	{
		[m_ImageDataBytes release];
		m_ImageDataBytes = nil;
	}
	
	m_ImageDataBytes = [[NSMutableData alloc] initWithCapacity: ([imageRepresentation size].width * [imageRepresentation size].height) + 1];
	
	NSLog( @"IN");
	
	//unsigned char *imageBuffer = malloc([imageRepresentation size].width * [imageRepresentation size].height) + 1;
	//unsigned char *destBuffer = imageBuffer;

	float monoR, monoG, monoB;
	unsigned char grayValue = 0;
	Ptr bitMapDataPtr = (char *) [imageRepresentation bitmapData];

	int i;
	for(i = 0; i < [imageRepresentation size].height; i++)
	{
		char *sourceBuffer = bitMapDataPtr + i * [imageRepresentation bytesPerRow];

		int x;
		for(x = 0; x <  [imageRepresentation size].width; x++)
		{
			monoR = 0.299 * (float) *sourceBuffer++;
			monoG = 0.587 * (float) *sourceBuffer++;
			monoB = 0.114 * (float) *sourceBuffer++;
			grayValue = roundf(monoR + monoG + monoB);
			[m_ImageDataBytes appendBytes: &grayValue length: 1];
			//*destBuffer++ = grayValue;
			bytesWritten++;
		}
	}

	if(bytesWritten % 2 != 0)
	{
		grayValue = 0;
		[m_ImageDataBytes appendBytes: &grayValue length: 1];
		//*destBuffer++ = '\0';
		bytesWritten++;
	}
	
	NSLog( @"OUT");
	
	//[imageRepresentation release];
	[pool release];
	struct rawData rawImage;
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
	NSString *fontName = [NSString stringWithString: @"Andale Mono"];
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
	int i, theLongest = 0;
	NSArray *values = [tileDict allValues];
	for (i = 0; i < [values count]; i++)
	{
		NSString *value = [NSString stringWithFormat: @"%@",  [values objectAtIndex: i]];

		if (theLongest < [value length])
			theLongest = [value length];
	}

	float fontSize = imageRect.size.width / theLongest;
	#pragma mark TODO: font size min/max values (isPrinting)

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
	short group = 0, element = 0, dummyShort = 0;
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
	fwrite([[patientDict objectForKey:@"series.modality"] cString], [[patientDict objectForKey:@"series.modality"] length], 1, outFile);
	
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
	
	// new group
	
	group = CFSwapInt16HostToLittle(0x0028);
	
	// samplePerPixel
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0002);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	if (colorPrint)
		dummyShort = CFSwapInt16HostToLittle(3);
	else
		dummyShort = CFSwapInt16HostToLittle(1);
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

	// planarConfiguration
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0006);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x000);
	fwrite(&dummyShort, 2, 1, outFile);
	
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
	/*fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0107);
	fwrite(&element, 2, 1, outFile);
	fwrite("US", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0002);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0048);
	fwrite(&dummyShort, 2, 1, outFile);
	*/
	
	
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
	fwrite([outString cString], [outString length], 1, outFile);
	
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
	fwrite([outString cString], [outString length], 1, outFile);
	
	// new group
	// image data
	group = CFSwapInt16HostToLittle(0x7fe0);
	fwrite(&group, 2, 1, outFile);
	element = CFSwapInt16HostToLittle(0x0010);
	fwrite(&element, 2, 1, outFile);
	fwrite("OW", 2, 1, outFile);
	dummyShort = CFSwapInt16HostToLittle(0x0000);
	fwrite(&dummyShort, 2, 1, outFile);
	dummyLong = CFSwapInt32HostToLittle([image size].width * [image size].height * 1);// may be 3 for RGB
	dataSizePos = ftell(outFile);
	fwrite(&dummyLong, 4, 1, outFile);

	struct rawData rawImage;
	if (colorPrint)
		rawImage = [self _convertImageToBitmap: image];
	else
		rawImage = [self _convertRGBToGrayscale: image];
	//fwrite(rawImage.imageData, rawImage.bytesWritten, 1, outFile);
	fwrite([m_ImageDataBytes bytes], [m_ImageDataBytes length], 1, outFile);

	//m_ImageDataBytes
	fseek(outFile, dataSizePos, 0);
	rawImage.bytesWritten = CFSwapInt32HostToLittle(rawImage.bytesWritten);
	fwrite(&rawImage.bytesWritten, 4, 1, outFile);
	if(m_ImageDataBytes)
	{
		[m_ImageDataBytes release];
		m_ImageDataBytes = nil;
	}
	// only free grayscale char buffer
	//if (!colorPrint)
	//	free(rawImage.imageData);
	fclose(outFile);

	return path;
}

@end