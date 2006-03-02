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

#import "DICOMExport.h"
#import <OsiriX/DCM.h>
#import "BrowserController.h"
#import "dicomFile.h"
#import "DCMPix.h"

extern	NSString * documentsDirectory();
extern BrowserController	*browserWindow;

@implementation DICOMExport

- (void) setSeriesDescription: (NSString*) desc
{
	if( desc != exportSeriesDescription)
	{
		[exportSeriesDescription release];
		exportSeriesDescription = [desc retain];
	}
}

- (void) setSeriesNumber: (long) no
{
	//If no == -1, take the value of source dcm
	exportSeriesNumber = no;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		dcmSourcePath = 0L;
		dcmDst = 0L;
		
		data = 0L;
		width = height = spp = bpp = 0;
		
		image = 0L;
		imageData = 0L;
		freeImageData = NO;
		imageRepresentation = 0L;
		
		ww = wl = -1;
		
		exportInstanceNumber = 0;
		exportSeriesNumber = 5000;
		
		DCMObject *dcmObject = [[[DCMObject alloc] init] autorelease];
		[dcmObject newSeriesInstanceUID];
		
		exportSeriesUID = [[dcmObject attributeValueWithName:@"SeriesInstanceUID"] retain];
		exportSeriesDescription = @"OsiriX SC";
		[exportSeriesDescription retain];
		
		
		spacingX = 0;
		spacingY = 0;
		sliceThickness = 0;
		sliceInterval = 0;
		orientation[ 6] = 0;
		position[ 3] = 0;
		slicePosition = 0;
	}
	
	return self;
}

- (void) dealloc
{
	NSLog(@"DICOMExport released");
	
	// NSImage support
	[image release];
	[imageRepresentation release];
	if( freeImageData) free( imageData);

	[exportSeriesUID release];
	[exportSeriesDescription release];
	
	[dcmSourcePath release];
	[dcmDst release];
	
	[super dealloc];
}

- (void) setSourceFile:(NSString*) isource
{
	[dcmSourcePath release];
	dcmSourcePath = [isource retain];
}

- (long) setPixelData:		(unsigned char*) idata
		samplePerPixel:		(long) ispp
		bitsPerPixel:		(long) ibpp
		width:				(long) iwidth
		height:				(long) iheight
{
	spp = ispp;
	bpp = ibpp;
	width = iwidth;
	height = iheight;
	data = idata;
	
	return 0;
}

- (long) setPixelNSImage:	(NSImage*) iimage
{
	if( image != iimage)
	{
		[image release];
		image = 0L;
		
		[imageRepresentation release];
		imageRepresentation = 0L;
		
		if( freeImageData) free( imageData);
		freeImageData = NO;
		imageData = 0L;
		
		image = [iimage retain];
	}

	if( image)
	{
		NSData				*tiffRep = [image TIFFRepresentation];
		NSSize				imageSize;
		long				w, h, i;
		
		if( tiffRep)
		{
			imageRepresentation = [[NSBitmapImageRep alloc] initWithData:tiffRep];
			imageSize = [imageRepresentation size];
			
			w = imageSize.width;
			h = imageSize.height;
			
			if( [imageRepresentation bytesPerRow] != w)
			{
				imageData = malloc( h * w * [imageRepresentation samplesPerPixel]);
				freeImageData = YES;
				
				for( i = 0; i < height; i++)
				{
					BlockMoveData( [imageRepresentation bitmapData] + i * [imageRepresentation bytesPerRow], imageData + i * width * [imageRepresentation samplesPerPixel], width * [imageRepresentation samplesPerPixel]);
				}
			}
			else imageData = [imageRepresentation bitmapData];
			
			return [self setPixelData:		imageData
						samplePerPixel:		[imageRepresentation samplesPerPixel]
						bitsPerPixel:		[imageRepresentation bitsPerPixel]
						width:				w
						height:				h];
		}
		else return -1;
	}
	else return -1;
}

- (void) setDefaultWWWL: (long) iww :(long) iwl
{
	wl = iwl;
	ww = iww;
}

- (void) setPixelSpacing: (float) x :(float) y;
{
	spacingX = x;
	spacingY = y;
}

- (void) setSliceThickness: (float) t
{
	sliceThickness = t;
}

- (void) setOrientation: (float*) o
{
	long i;
	
	for( i = 0; i < 6; i++) orientation[ i] = o[ i];
}

- (void) setPosition: (float*) p
{
	long i;
	
	for( i = 0; i < 3; i++) position[ i] = p[ i];
}

- (void) setSlicePosition: (float) p
{
	slicePosition = p;
}

- (long) writeDCMFile: (NSString*) dstPath
{
	if( dstPath == 0L)
	{
		BOOL			isDir = YES;
		long			index = 0;
		NSString		*OUTpath = [documentsDirectory() stringByAppendingPathComponent:@"/INCOMING"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
		
		do
		{
			dstPath = [NSString stringWithFormat:@"%@/%d", OUTpath, index];
			index++;
		}
		while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
	}

	if( width != 0 && height != 0 && data != 0L)
	{
		long				i;
		DCMCalendarDate		*acquisitionDate = [DCMCalendarDate date], *studyDate = 0L, *studyTime = 0L;
		DCMObject			*dcmObject = 0L;
		NSString			*patientName = 0L, *patientID = 0L, *studyDescription = 0L, *studyUID = 0L, *studyID = 0L, *charSet = 0L;
		NSNumber			*seriesNumber = 0L;
		unsigned char		*squaredata = 0L;
		
		seriesNumber = [NSNumber numberWithInt:exportSeriesNumber];
		
		if( dcmSourcePath)
		{
			if ([DicomFile isDICOMFile:dcmSourcePath])
			{
				dcmObject = [DCMObject objectWithContentsOfFile:dcmSourcePath decodingPixelData:NO];
				
				patientName = [dcmObject attributeValueWithName:@"PatientsName"];
				patientID = [dcmObject attributeValueWithName:@"PatientID"];
				studyDescription = [dcmObject attributeValueWithName:@"StudyDescription"];
				studyUID = [dcmObject attributeValueWithName:@"StudyInstanceUID"];
				studyID = [dcmObject attributeValueWithName:@"StudyID"];
				studyDate = [dcmObject attributeValueWithName:@"StudyDate"];
				studyTime = [dcmObject attributeValueWithName:@"StudyTime"];
				charSet = [dcmObject attributeValueWithName:@"SpecificCharacterSet"];
				
				if( [seriesNumber intValue] == -1)
				{
					seriesNumber = [dcmObject attributeValueWithName:@"SeriesNumber"];
				}
			}
			else if ([DicomFile isFVTiffFile:dcmSourcePath])
			{
				DicomFile* FVfile = [[DicomFile alloc] init:dcmSourcePath];

				patientName = [FVfile elementForKey:@"patientName"]; 
				patientID = [FVfile elementForKey:@"patientID"];
				studyDescription = @"DICOM from FV300";
				studyUID = [FVfile elementForKey:@"studyID"];
				studyID = [FVfile elementForKey:@"studyID"];
				studyDate = [DCMCalendarDate date];
				studyTime = [DCMCalendarDate date];
				
				[FVfile release];
			}
		}
		else
		{
			patientName = @"Anonymous";
			patientID = @"0";
			studyDescription = @"SC";
			studyUID = @"0.0.0.0";
			studyID = @"0";
			studyDate = [DCMCalendarDate date];
			studyTime = [DCMCalendarDate date];
		}
		
		DCMCalendarDate *seriesDate = acquisitionDate;
		DCMCalendarDate *seriestime = acquisitionDate;
		
		NSNumber *slices = [NSNumber numberWithInt: 1];
		
		if( spacingX != 0 && spacingY != 0)
		{
			if( spacingX != spacingY)	// Convert to square pixels
			{
				if( bpp == 16)
				{
					vImage_Buffer	srcVimage, dstVimage;
					long			newHeight = ((float) height * spacingY) / spacingX;
					
					newHeight /= 2;
					newHeight *= 2;
					
					squaredata = malloc( newHeight * width * bpp/8);
					
					float	*tempFloatSrc = malloc( height * width * sizeof( float));
					float	*tempFloatDst = malloc( newHeight * width * sizeof( float));
					
					if( squaredata != 0L && tempFloatSrc != 0L && tempFloatDst != 0L)
					{
						long err;
						
						// Convert Source to float
						srcVimage.data = data;
						srcVimage.height =  height;
						srcVimage.width = width;
						srcVimage.rowBytes = width* bpp/8;
						
						dstVimage.data = tempFloatSrc;
						dstVimage.height =  height;
						dstVimage.width = width;
						dstVimage.rowBytes = width*sizeof( float);

						err = vImageConvert_16UToF(&srcVimage, &dstVimage, 0,  1, 0);
					//	if( err) NSLog(@"%d", err);
						
						// Scale the image
						srcVimage.data = tempFloatSrc;
						srcVimage.height =  height;
						srcVimage.width = width;
						srcVimage.rowBytes = width*sizeof( float);
						
						dstVimage.data = tempFloatDst;
						dstVimage.height =  newHeight;
						dstVimage.width = width;
						dstVimage.rowBytes = width*sizeof( float);
						
						err = vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
					//	if( err) NSLog(@"%d", err);
						
						// Convert Destination to 16 bits
						srcVimage.data = tempFloatDst;
						srcVimage.height =  newHeight;
						srcVimage.width = width;
						srcVimage.rowBytes = width*sizeof( float);
						
						dstVimage.data = squaredata;
						dstVimage.height =  newHeight;
						dstVimage.width = width;
						dstVimage.rowBytes = width* bpp/8;

						err = vImageConvert_FTo16U( &srcVimage, &dstVimage, 0,  1, 0);
					//	if( err) NSLog(@"%d", err);
						
						spacingY = spacingX;
						height = newHeight;
						
						data = squaredata;
						
						free( tempFloatSrc);
						free( tempFloatDst);
					}
				}
			}
		}
		
		NSNumber *rows = [NSNumber numberWithInt: height];
		NSNumber *columns  = [NSNumber numberWithInt: width];

		#if __BIG_ENDIAN__
		if( bpp == 16)
		{
			//Convert to little endian
			InverseShorts( (vector unsigned short*) data, height * width);
		}
		#endif
		
		NSMutableData *imageNSData = [NSMutableData dataWithBytes:data length: height * width * spp * bpp / 8];
		NSString *vr;
		int highBit;
		int bitsAllocated;
		float numberBytes;
		BOOL isSigned;
		BOOL isLittleEndian = YES;		//Yes, we work in little endian to make these Windows DICOM viewer happy...
		
		NSLog(@"Current bpp: %d", bpp);
		
		switch( bpp)
		{
			case 8:			
				highBit = 7;
				bitsAllocated = 8;
				numberBytes = 1;
				isSigned = NO;
			break;
			
			case 16:			
				highBit = 15;
				bitsAllocated = 16;
				numberBytes = 2;
				isSigned = NO;
			break;
			
			default:
				NSLog(@"Unsupported bpp: %d", bpp);
				return -1;
			break;
		}
		
		NSString *photometricInterpretation = @"MONOCHROME2";
		if (spp == 3) photometricInterpretation = @"RGB";
		
		[dcmDst release];
		dcmDst = [[DCMObject secondaryCaptureObjectWithBitDepth: bpp  samplesPerPixel:spp numberOfFrames:1] retain];
		
		//add attributes
		if( charSet) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:charSet] forName:@"SpecificCharacterSet"];
		if( studyUID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyUID] forName:@"StudyInstanceUID"];
		if( exportSeriesUID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:exportSeriesUID] forName:@"SeriesInstanceUID"];
		if( exportSeriesDescription) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:exportSeriesDescription] forName:@"SeriesDescription"];
		
		if( patientName) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:patientName] forName:@"PatientsName"];
		if( patientID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:patientID] forName:@"PatientID"];
		if( studyDescription) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyDescription] forName:@"StudyDescription"];
		[dcmDst setAttributeValues:nil forName:@"InstanceNumber"];
		if( seriesNumber) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:seriesNumber] forName:@"SeriesNumber"];
		if( studyID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyID] forName:@"StudyID"];
		
		if( dcmObject)
		{
			if([dcmObject attributeValueWithName:@"PatientsSex"]) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject: [dcmObject attributeValueWithName:@"PatientsSex"]] forName:@"PatientsSex"];
			if([dcmObject attributeValueWithName:@"PatientsBirthDate"]) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject: [dcmObject attributeValueWithName:@"PatientsBirthDate"]] forName:@"PatientsBirthDate"];
			if([dcmObject attributeValueWithName:@"AccessionNumber"]) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject: [dcmObject attributeValueWithName:@"AccessionNumber"]] forName:@"AccessionNumber"];
		}
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:@"OsiriX"] forName:@"ManufacturersModelName"];
		
		if( studyDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyDate] forName:@"StudyDate"];
		if( studyTime) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyTime] forName:@"StudyTime"];
		if( seriesDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:seriesDate] forName:@"SeriesDate"];
		if( seriestime) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:seriestime] forName:@"SeriesTime"];
		if( acquisitionDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:acquisitionDate] forName:@"AcquisitionDate"];
		if( acquisitionDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:acquisitionDate] forName:@"AcquisitionTime"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:exportInstanceNumber++]] forName:@"InstanceNumber"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:rows] forName:@"Rows"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:columns] forName:@"Columns"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:spp]] forName:@"SamplesperPixel"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:photometricInterpretation] forName:@"PhotometricInterpretation"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithBool:isSigned]] forName:@"PixelRepresentation"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:highBit]] forName:@"HighBit"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsAllocated"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsStored"];
		
		if( spacingX != 0 && spacingY != 0)
		{
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:spacingY], [NSNumber numberWithFloat:spacingX], 0L] forName:@"PixelSpacing"];
		}
		if( sliceThickness != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:sliceThickness]] forName:@"SliceThickness"];
		if( orientation[ 0] != 0 || orientation[ 1] != 0 || orientation[ 2] != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:orientation[ 0]], [NSNumber numberWithFloat:orientation[ 1]], [NSNumber numberWithFloat:orientation[ 2]], [NSNumber numberWithFloat:orientation[ 3]], [NSNumber numberWithFloat:orientation[ 4]], [NSNumber numberWithFloat:orientation[ 5]], 0L] forName:@"ImageOrientationPatient"];
		if( position[ 0] != 0 || position[ 1] != 0 || position[ 2] != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:position[ 0]], [NSNumber numberWithFloat:position[ 1]], [NSNumber numberWithFloat:position[ 2]], 0L] forName:@"ImagePositionPatient"];
		if( slicePosition != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:slicePosition]] forName:@"SliceLocation"];
		if( spp == 3) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:0]] forName:@"PlanarConfiguration"];
		
		if( bpp == 16)
		{
			vr = @"OW";
			
			//By default, we use a 1024 rescale intercept !!
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:-1024]] forName:@"RescaleIntercept"];
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:1]] forName:@"RescaleSlope"];
			
			if( ww != -1 && ww != -1)
			{
				[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:wl]] forName:@"WindowCenter"];
				[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:ww]] forName:@"WindowWidth"];
			}
		}
		else
		{
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:0]] forName:@"RescaleIntercept"];
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:1]] forName:@"RescaleSlope"];
			
			vr = @"OB";
		}
		
		//[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:@"US"] forName:@"RescaleType"];
		
		//add Pixel data
		

		DCMTransferSyntax *ts;
		if (isLittleEndian)
			ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
		else
			ts = [DCMTransferSyntax ExplicitVRBigEndianTransferSyntax];
		
		DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"PixelData"];
		DCMPixelDataAttribute *attr = [[[DCMPixelDataAttribute alloc] initWithAttributeTag:tag 
										vr:vr 
										length:numberBytes
										data:nil 
										specificCharacterSet:nil
										transferSyntax:ts 
										dcmObject:dcmDst
										decodeData:NO] autorelease];
		[attr addFrame:imageNSData];
		[dcmDst setAttribute:attr];

		[dcmDst writeToFile:dstPath withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
		
		if( squaredata)
		{
			free( squaredata);
		}
		squaredata = 0L;
		
		return 0;
	}
	else return -1;
}

@end
