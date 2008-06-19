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


#include "FVTiff.h"
#import <dicomFile.h>
#import "Papyrus3/Papyrus3.h"
#import "ViewerController.h"
#import "PluginFileFormatDecoder.h"
#include <QuickTime/QuickTime.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCMSequenceAttribute.h>
#import "DCMObjectDBImport.h"
#import "DICOMToNSString.h"
#import "DefaultsOsiriX.h"
#import <QTKit/QTKit.h>
#include "tiffio.h"
#import "DicomFileDCMTKCategory.h"
#import "PluginManager.h"
#include "nifti1.h"
#include "nifti1_io.h"

/************  Modifications *************************************************************************************
*	Version 2.3
*	20051214	LP	Modified DICOM decoding merge all DR, DX, RF series in a study into one study.
*	20051216	LP	Will separate series based on Echo Time (TE)
*	20051225	LP	Fixed bug when parsing with DCMFramework Added width and height
*	20060116	LP	Added NSUserDefaults for splitting series by Echo and combining CR,DR, RF series
*
*	20060303	LP	Moved character set encoding to a cataegory of NSString - DICOMToNSString - to allow conversion of 
*					DICOM to NSStrings elsewher ein OsiriX
*
*******************************************************************************************************************/

extern NSString * convertDICOM( NSString *inputfile);
extern NSLock	*PapyrusLock;

static BOOL DEFAULTSSET = NO;
static int TOOLKITPARSER = NO, PREFERPAPYRUSFORCD = NO;
static BOOL COMMENTSAUTOFILL = NO;
static BOOL splitMultiEchoMR = NO;
static BOOL useSeriesDescription = NO;
static BOOL NOLOCALIZER = NO;
static BOOL combineProjectionSeries = NO, oneFileOnSeriesForUS = NO;
static int combineProjectionSeriesMode = NO;
static BOOL	CHECKFORLAVIM = NO;
static int COMMENTSGROUP = NO;
static int COMMENTSELEMENT = NO;
static BOOL SEPARATECARDIAC4D = NO;
static BOOL filesAreFromCDMedia = NO;

char* replaceBadCharacter (char* str, NSStringEncoding encoding) 
{
	if( encoding != NSISOLatin1StringEncoding) return str;

	long i = strlen( str);
	
	while( i-- >0)
	{
		if( str[i] == '/') str[i] = '-';
		if( str[i] == '^') str[i] = ' ';
	}
	
	i = strlen( str);
	while( --i > 0)
	{
		if( str[i] ==' ') str[i] = 0;
		else i = 0;
	}
	
	return str;
}

//@implementation NSString(_encodings_)
//- (NSArray*)allAvailableEncodings
//{
//    NSMutableArray*     array = [[NSMutableArray array] retain];
//    const NSStringEncoding*     encoding = [NSString availableStringEncodings];
//
//    while (*encoding) {
//        NSMutableArray* row = [NSMutableArray arrayWithCapacity:2];
//
////		NSLog([NSString localizedNameOfStringEncoding:*encoding]);
//
//        [row addObject:[NSString localizedNameOfStringEncoding:*encoding]];
//        [row addObject:[NSNumber numberWithInt:*encoding]];
//        encoding++;
//
//        [array addObject:row];
//
//    }
//
//    return [array autorelease];
//}
//
//- (int)numberFromLocalizedStringEncodingName:(NSString*)aName
//{
//    NSArray *encodings = [[self allAvailableEncodings] retain];
//    NSEnumerator *en = [encodings objectEnumerator];
//    NSArray *encPair = [NSArray array];
//    int searchedNumber = 0;
//
//    while (encPair = [en nextObject])
//    {
//        if ([[encPair objectAtIndex:0] isEqualTo:aName])
//            searchedNumber = [[encPair objectAtIndex:1] intValue];
//    }
//
//    [encodings release];
//    return searchedNumber;
//}
//@end

@implementation DicomFile

- (BOOL) containsString: (NSString*) s inArray: (NSArray*) a
{
	for( NSString *v in a)
	{
		if ([v isKindOfClass:[NSString class]])
		{
			if ([v isEqualToString: s]) return YES;
		}
	}
	return NO;
}

+ (void) setFilesAreFromCDMedia: (BOOL) f;
{
	filesAreFromCDMedia = f;
}

-(long) NoOfSeries {return NoOfSeries;}
-(long) getWidth {return width;}
-(long) getHeight {return height;}

+ (NSString*) NSreplaceBadCharacter: (NSString*) str
{
	if( str == 0L) return 0L;
	
	NSMutableString	*mutable = [NSMutableString stringWithString: str];
	
	[mutable replaceOccurrencesOfString:@"^" withString:@" " options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\"" withString:@"'" options:0 range:NSMakeRange(0, [mutable length])];
	
	
	long i = [mutable length];
	while( --i > 0)
	{
		if( [mutable characterAtIndex: i]==' ') [mutable deleteCharactersInRange: NSMakeRange( i, 1)];
		else i = 0;
	}
	
	return mutable;
}

+ (NSString *) stringWithBytes:(char *) str encodings: (NSStringEncoding*) encoding
{
	if( str == 0L) return 0L;

	char				c;
	int					i, x, from, len = strlen( str), index;
	NSMutableString		*result = [NSMutableString string];
	
	for( i = 0, from = 0, index = 0; i < len; i++)
	{
		c = str[ i];
		
		if( c == 0x1b || i == len-1)
		{
			if( i == len-1) i = len;
			
			NSString	*s = [[NSString alloc] initWithBytes: str+from length:i-from encoding:encoding[ index]];
			
			if( s)
			{
				[result appendString: s];
				
				if( encoding[ index] == -2147481280)	// Korean support
				{
					[result replaceOccurrencesOfString:@"$)C" withString:@"" options:0 range:NSMakeRange(0, [result length])];
				}
				
				[s release];
			}
			
			from = i;
			index = 1;
//			if( index < 9) index++;
		}
	}
	
	return [DicomFile NSreplaceBadCharacter: result];
}

+ (char *) replaceBadCharacter:(char *) str encoding: (NSStringEncoding) encoding{
	return replaceBadCharacter (str, encoding);
}

+ (void) resetDefaults
{
	DEFAULTSSET = NO;
}

+ (void) setDefaults
{
	if( DEFAULTSSET == NO)
	{
		if( [[NSUserDefaults standardUserDefaults] objectForKey: @"TOOLKITPARSER"])
		{
			NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
			
			DEFAULTSSET = YES;
			
			PREFERPAPYRUSFORCD = [sd integerForKey: @"PREFERPAPYRUSFORCD"];
			TOOLKITPARSER = [sd integerForKey: @"TOOLKITPARSER"];
			COMMENTSAUTOFILL = [sd boolForKey: @"COMMENTSAUTOFILL"];
			SEPARATECARDIAC4D = [sd boolForKey: @"SEPARATECARDIAC4D"];
			
			COMMENTSGROUP = [[sd objectForKey: @"COMMENTSGROUP"] intValue];
			COMMENTSELEMENT = [[sd objectForKey: @"COMMENTSELEMENT"] intValue];
			
			useSeriesDescription = [sd boolForKey: @"useSeriesDescription"];
			splitMultiEchoMR = [sd boolForKey: @"splitMultiEchoMR"];
			NOLOCALIZER = [sd boolForKey: @"NOLOCALIZER"];
			oneFileOnSeriesForUS = [sd boolForKey: @"oneFileOnSeriesForUS"];
			combineProjectionSeries = [sd boolForKey: @"combineProjectionSeries"];
			combineProjectionSeriesMode = [sd boolForKey: @"combineProjectionSeriesMode"];
			
			if( [DefaultsOsiriX isLAVIM])
			{
				CHECKFORLAVIM = YES;	// HUG SPECIFIC, Thanks... Antoine Rosset
			}
		}
		else	// FOR THE SAFEDBREBUILD ! Shell tool
		{
			NSMutableDictionary	*dict = [DefaultsOsiriX getDefaults];
			[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"]];
			
			DEFAULTSSET = YES;
			
			PREFERPAPYRUSFORCD = [[dict objectForKey: @"PREFERPAPYRUSFORCD"] intValue];
			TOOLKITPARSER = [[dict objectForKey: @"TOOLKITPARSER"] intValue];
			COMMENTSAUTOFILL = [[dict objectForKey: @"COMMENTSAUTOFILL"] intValue];
			SEPARATECARDIAC4D = [[dict objectForKey: @"SEPARATECARDIAC4D"] intValue];
			
			COMMENTSGROUP = [[dict objectForKey: @"COMMENTSGROUP"] intValue];
			COMMENTSELEMENT = [[dict objectForKey: @"COMMENTSELEMENT"] intValue];
			
			useSeriesDescription = [[dict objectForKey: @"useSeriesDescription"] intValue];
			splitMultiEchoMR = [[dict objectForKey: @"splitMultiEchoMR"] intValue];
			NOLOCALIZER = [[dict objectForKey: @"NOLOCALIZER"] intValue];
			combineProjectionSeries = [[dict objectForKey: @"combineProjectionSeries"] intValue];
			oneFileOnSeriesForUS = [[dict objectForKey: @"oneFileOnSeriesForUS"] intValue];
			combineProjectionSeriesMode = [[dict objectForKey: @"combineProjectionSeriesMode"] intValue];
			
			CHECKFORLAVIM = NO;
		}
		
//		NSLog( @"Toolkit:%d", TOOLKITPARSER);
	}
}

+ (BOOL) isTiffFile:(NSString *) file
{
	int success = NO, i;
	NSString	*extension = [[file pathExtension] lowercaseString];
	
	#ifndef STATIC_DICOM_LIB
	
	if( [extension isEqualToString:@"tiff"] == YES ||
		[extension isEqualToString:@"stk"] == YES ||
		[extension isEqualToString:@"tif"] == YES)
	{
		TIFF* tif = TIFFOpen([file UTF8String], "r");
		if(tif)
		{
			success = YES;
			TIFFClose(tif);
		}
	}
	
	#endif
	
	return success;
}

+ (BOOL) isFVTiffFile:(NSString *) file
{
	int success = NO, i;
	NSString	*extension = [[file pathExtension] lowercaseString];

	#ifndef STATIC_DICOM_LIB
	if( [extension isEqualToString:@"tiff"] == YES ||
		[extension isEqualToString:@"tif"] == YES)
	{
		short head_size = 0;
		char* head_data = 0;
		TIFF* tif = TIFFOpen([file UTF8String], "r");
		if(tif)
		{
			success = TIFFGetField(tif, TIFFTAG_FV_MMHEADER, &head_size, &head_data);
			TIFFClose(tif);
		}
	}
	#endif
	return success;
}

+ (BOOL) isNIfTIFile:(NSString *) file
{
	// NIfTI support developed by Zack Mahdavi at the Center for Neurological Imaging, a division of Harvard Medical School
	// For more information: http://cni.bwh.harvard.edu/
	// For questions or suggestions regarding NIfTI integration in OsiriX, please contact zmahdavi@bwh.harvard.edu
	
	int success = NO, i;
	NSString	*extension = [[file pathExtension] lowercaseString];
	struct nifti_1_header  *NIfTI;
	
	if( [extension isEqualToString:@"hdr"] == YES ||
		[extension isEqualToString:@"nii"] == YES)
	{
		NIfTI = (nifti_1_header *) nifti_read_header([file UTF8String], nil, 0);
		
		if( (NIfTI->magic[0] != 'n')                           ||
					(NIfTI->magic[1] != 'i' && NIfTI->magic[1] != '+')   ||
					(NIfTI->magic[2] != '1')                           ||
					(NIfTI->magic[3] != '\0') )
		{
			success = NO;
		}
		else
		{
			success = YES;
		}
		
		NIfTI = 0L;
	}
	return success;
}

+ (BOOL) isDICOMFile:(NSString *) file compressed:(BOOL*) compressed
{
	//return [DicomFile isDICOMFileDCMTK:file]; 
	// return [DCMObject isDICOM:[NSData dataWithContentsOfFile:file]]; <- This is EXTREMELY slow with large files like XA, CR: You have to read the ENTIRE file to test it.
		
	BOOL            readable = YES;
	PapyShort       fileNb, theErr;

	[PapyrusLock lock];
	fileNb = Papy3FileOpen ( (char*) [file UTF8String], (PAPY_FILE) 0, TRUE, 0);
	if (fileNb < 0)
	{
		readable = NO;
	}
	else
	{
		if( compressed)
		{
			if( gArrCompression [fileNb] == JPEG_LOSSLESS || gArrCompression [fileNb] == JPEG_LOSSY  || gArrCompression [fileNb] == JPEG2000) *compressed = YES;
			else *compressed = NO;
		}
		Papy3FileClose (fileNb, TRUE);
	}
	
	[PapyrusLock unlock];
	
	if (!readable)
	{
		if( compressed) *compressed = NO;
		return [DCMObject isDICOM:[NSData dataWithContentsOfMappedFile:file]];
	}
    return readable;
}

+ (BOOL) isDICOMFile:(NSString *) file
{
	return [DicomFile isDICOMFile:file compressed:0L];
}

+ (BOOL) isXMLDescriptedFile:(NSString *) file
{
	NSString *filePathWithoutExtension = [file stringByDeletingPathExtension];
	NSString *xmlFilePath = [filePathWithoutExtension stringByAppendingString:@".xml"];
	return [[NSFileManager defaultManager] fileExistsAtPath:xmlFilePath];
}

+ (BOOL) isXMLDescriptorFile:(NSString *) file
{
	BOOL readable = YES;
	readable = readable && [[NSFileManager defaultManager] fileExistsAtPath:file];
	NSString *filePathWithoutExtension = [file stringByDeletingPathExtension];
	NSString *zipFilePath = [filePathWithoutExtension stringByAppendingString:@".zip"];
	readable = readable && [[NSFileManager defaultManager] fileExistsAtPath:zipFilePath];
	return readable;
}

-(short) getFVTiffFile
{
	int success = 0;
	NSString	*extension = [[filePath pathExtension] lowercaseString];
	
	#ifndef STATIC_DICOM_LIB
	if( [extension isEqualToString:@"tiff"] == YES ||
		[extension isEqualToString:@"tif"] == YES)
	{
		TIFF* tif = TIFFOpen( [filePath UTF8String], "r");
		
		short head_size = 0;
		char* head_data = 0;
		
		if(tif)
			success = TIFFGetField(tif, TIFFTAG_FV_MMHEADER, &head_size, &head_data);
		
		if (success)
		{
			int i, j;
			
		
			int w = 0, h = 0;
			FV_MM_HEAD mm_head;
			NSXMLDocument *xmlDocument;
			xmlDocument = XML_from_FVTiff(filePath);
			
			FV_Read_MM_HEAD(head_data, &mm_head);
			NoOfFrames = 1;
			NoOfSeries = 1;
			for(i = 0; i < FV_SPATIAL_DIMENSION; i++)
			{
				if (*(mm_head.DimInfo[i].Name) == 'Z')
					NoOfFrames = mm_head.DimInfo[i].Size;
				else if (*(mm_head.DimInfo[i].Name) != 'X' && *(mm_head.DimInfo[i].Name) != 'Y')
					NoOfSeries *= mm_head.DimInfo[i].Size;
			}
			
			TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
			TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
			
			
			width = w;
			height = h;
			
			height /= 2;
			height *= 2;
			width /= 2;
			width *= 2;
						
			name = [[NSString alloc] initWithString: [filePath lastPathComponent]];
//			name = [[NSString alloc] initWithCString:mm_head.Name encoding:NSWindowsCP1252StringEncoding];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:name];
			serieID = [[NSString alloc] initWithString:name];
			imageID = [[NSString alloc] initWithString:name];
			study = [[NSString alloc] initWithString:name];
			serie = [[NSString alloc] initWithString:name];
			Modality = [[NSString alloc] initWithString:@"FV300"];
			fileType = [[NSString stringWithString:@"FVTiff"] retain];
			
			// set the comments and date fields
			NSXMLElement* rootElement = [xmlDocument rootElement];
			NSString* datetime_string = [NSString string];
			for (i = 0; i < [rootElement childCount]; i++)
			{
				NSXMLNode* theNode = [rootElement childAtIndex:i];
				if ([[theNode name] isEqualToString:@"Description"])
					[dicomElements setObject:[theNode stringValue] forKey:@"studyComment"];
				if ([[theNode name] isEqualToString:@"Acquisition Parameters"])
					for (j = 0; j < [theNode childCount]; j++)
					{
						NSXMLNode* theSubNode = [theNode childAtIndex:j];
						if ([[theSubNode name] isEqualToString:@"Date"])
							datetime_string = [NSString stringWithFormat:@"%@ %@", datetime_string, [theSubNode stringValue]];
						if ([[theSubNode name] isEqualToString:@"Time"])
							datetime_string = [NSString stringWithFormat:@"%@ %@", datetime_string, [theSubNode stringValue]];
					}
			}
			
			
			date = [NSDate dateWithNaturalLanguageString:datetime_string];
			if (date == 0L)
				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
			
			[dicomElements setObject:studyID forKey:@"studyID"];
			[dicomElements setObject:study forKey:@"studyDescription"];
			
			[dicomElements setObject:date forKey:@"studyDate"];
			
			[dicomElements setObject:Modality forKey:@"modality"];
			[dicomElements setObject:patientID forKey:@"patientID"];
			[dicomElements setObject:name forKey:@"patientName"];
			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
			[dicomElements setObject:fileType forKey:@"fileType"];

			for (i = 0; i < NoOfSeries; i++)
			{
				NSString* SeriesNum;
				if (i)
					SeriesNum = [NSString stringWithFormat:@"%d",i];
				else
					SeriesNum = @"";
								
				[dicomElements setObject:[SeriesNum stringByAppendingString:serieID] forKey:[@"seriesID" stringByAppendingString:SeriesNum]];
//				[dicomElements setObject:[SeriesNum stringByAppendingString:name] forKey:[@"seriesDescription" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[NSNumber numberWithInt: i] forKey:[@"seriesNumber" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[imageID stringByAppendingString:SeriesNum] forKey:[@"SOPUID" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[NSNumber numberWithInt: i] forKey:[@"imageID" stringByAppendingString:SeriesNum]];
				
				// seriesDescription stuff
				int pos = i;
				NSString* seriesDesc = @"FV ";
				int largestDimSize = 1;
				int j;
				for (j = 0; j < FV_SPATIAL_DIMENSION; j++)
					if (*(mm_head.DimInfo[j].Name) != 'X' && *(mm_head.DimInfo[j].Name) != 'Y' && *(mm_head.DimInfo[j].Name) != 'Z')
						largestDimSize *= mm_head.DimInfo[j].Size;
				for (j = FV_SPATIAL_DIMENSION - 1; j >= 0; j--)
				{
					if (mm_head.DimInfo[j].Size > 1 && *(mm_head.DimInfo[j].Name) != 'X' && *(mm_head.DimInfo[j].Name) != 'Y' && *(mm_head.DimInfo[j].Name) != 'Z')
					{
						if (![seriesDesc isEqualToString:@"FV "])
							seriesDesc = [seriesDesc stringByAppendingString:@", "];
						
						
						largestDimSize /= mm_head.DimInfo[j].Size;
						seriesDesc = [seriesDesc stringByAppendingFormat:@"%s %d", mm_head.DimInfo[j].Name, pos / largestDimSize];
						pos %= largestDimSize;
					}
				}
				[dicomElements setObject:seriesDesc forKey:[@"seriesDescription" stringByAppendingString:SeriesNum]];
			}
			[xmlDocument release];
		}
		if(tif) TIFFClose(tif);
	}
	
	#endif
	
	if (success)
		return 0;
	else
		return -1;
}

// For testing purposes only. Can quickly generate very large database to test performances
-(short) getRandom
{
	height = 512;
	width = 512;

	imageID = [[NSString alloc] initWithString: [[NSDate date] description]];
	serieID = [[NSString alloc] initWithString: [[NSDate date] description]];
	studyID = [[NSString alloc] initWithFormat:@"%d", random()];

	name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	patientID = [[NSString alloc] initWithString:name];
	study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	Modality = [[NSString alloc] initWithString:@"RD"];
	date = [[NSCalendarDate date] retain];
	serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	fileType = [[NSString stringWithString:@"IMAGE"] retain];

	NoOfSeries = 1;
	NoOfFrames = 1;
	
	[dicomElements setObject:studyID forKey:@"studyID"];
	[dicomElements setObject:study forKey:@"studyDescription"];
	[dicomElements setObject:date forKey:@"studyDate"];
	[dicomElements setObject:Modality forKey:@"modality"];
	[dicomElements setObject:patientID forKey:@"patientID"];
	[dicomElements setObject:name forKey:@"patientName"];
	[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
	[dicomElements setObject:serieID forKey:@"seriesID"];
	[dicomElements setObject:name forKey:@"seriesDescription"];
	[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
	[dicomElements setObject:imageID forKey:@"SOPUID"];
	[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
	[dicomElements setObject:fileType forKey:@"fileType"];

	return 0;
}

-(short) getImageFile
{
	NSString	*extension = [[filePath pathExtension] lowercaseString];
	
	NoOfFrames = 1;
	
	
	if( [extension isEqualToString:@"tiff"] == YES ||
		[extension isEqualToString:@"tif"] == YES ||
		[extension isEqualToString:@"stk"] == YES ||
		[extension isEqualToString:@"png"] == YES ||
		[extension isEqualToString:@"jpg"] == YES ||
		[extension isEqualToString:@"jpeg"] == YES ||
		[extension isEqualToString:@"pdf"] == YES ||
		[extension isEqualToString:@"pct"] == YES ||
		[extension isEqualToString:@"gif"] == YES)
		{
			NSImage		*otherImage = [[NSImage alloc] initWithContentsOfFile:filePath];
			if( otherImage || [extension isEqualToString:@"tiff"] || [extension isEqualToString:@"tif"])
			{
				// Try to identify a 2 digit number in the last part of the file.
				char				strNo[ 5];
				NSString			*tempString = [[filePath lastPathComponent] stringByDeletingPathExtension];
				NSRange				range;
				NSBitmapImageRep	*rep;
				
				#ifndef STATIC_DICOM_LIB
				if( [extension isEqualToString:@"tiff"] == YES ||
					[extension isEqualToString:@"stk"] == YES ||
					[extension isEqualToString:@"tif"] == YES)
				{
					TIFF* tif = TIFFOpen([filePath UTF8String], "r");
					if( tif)
					{
						long count = 0;
						int w = 0, h = 0;
						
						width = 0;
						height = 0;
						
						count = 0;
						do
						{
							TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
							TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
							
							if( w > width) width = w;
							if( h > height) height = h;
							
							count++;
						}
						while (TIFFReadDirectory(tif));
						
						NoOfFrames = count;
						
						NSLog( @"TIFF NoOfFrames: %d", NoOfFrames);
						
						TIFFClose(tif);
					}
				}
				else
				#endif
				{
					if( [extension isEqualToString:@"pdf"])
					{
						NSSize			newSize = [otherImage size];
							
						newSize.width *= 1.5;		// Increase PDF resolution to 72 * 1.5 DPI !
						newSize.height *= 1.5;		// KEEP THIS VALUE IN SYNC WITH DCMPIX.M
						
						[otherImage setScalesWhenResized:YES];
						[otherImage setSize: newSize];
					}

					rep = [NSBitmapImageRep imageRepWithData:[otherImage TIFFRepresentation]];
					if( rep)
					{
						height = [rep pixelsHigh];
						width = [rep pixelsWide];
					}
				}
				
								
				height /= 2;
				height *= 2;
				width /= 2;
				width *= 2;
				
				if( [tempString length] >= 4) strNo[ 0] = [tempString characterAtIndex: [tempString length] -4];	else strNo[ 0]= 0;
				if( [tempString length] >= 3) strNo[ 1] = [tempString characterAtIndex: [tempString length] -3];	else strNo[ 1]= 0;
				if( [tempString length] >= 2) strNo[ 2] = [tempString characterAtIndex: [tempString length] -2];	else strNo[ 2]= 0;
				if( [tempString length] >= 1) strNo[ 3] = [tempString characterAtIndex: [tempString length] -1];	else strNo[ 3]= 0;
				strNo[ 4] = 0;
				
				if( strNo[ 0] >= '0' && strNo[ 0] <= '9' && strNo[ 1] >= '0' && strNo[ 1] <= '9' && strNo[ 2] >= '0' && strNo[ 2] <= '9'  && strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 4] stringByAppendingString:[NSString stringWithCString: (char*) strNo]]];
					serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 4]];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 4]];
				}
				else if( strNo[ 1] >= '0' && strNo[ 1] <= '9' && strNo[ 2] >= '0' && strNo[ 2] <= '9' && strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					// We HAVE a number with 3 digit at the end of the file!! Make a serie of it!
					
					strNo[0] = strNo[ 1];
					strNo[1] = strNo[ 2];
					strNo[2] = strNo[ 3];
					strNo[3] = 0;
					
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 3] stringByAppendingString:[NSString stringWithCString: (char*) strNo]]];
					serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 3]];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 3]];
				}
				else if( strNo[ 2] >= '0' && strNo[ 2] <= '9' && strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					// We HAVE a number with 2 digit at the end of the file!! Make a serie of it!
					strNo[0] = strNo[ 2];
					strNo[1] = strNo[ 3];
					strNo[2] = 0;
					
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 2] stringByAppendingString:[NSString stringWithCString: (char*) strNo]]];
					serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 2]];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 2]];
				}
				else if( strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					// We HAVE a number with 1 digit at the end of the file!! Make a serie of it!
					strNo[0] = strNo[ 3];
					strNo[1] = 0;
					
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 1] stringByAppendingString:[NSString stringWithCString: (char*) strNo]]];
					serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 1]];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 1]];
				}
				else
				{
					imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
					SOPUID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
					serieID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
					studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				}
				
				name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				patientID = [[NSString alloc] initWithString:name];
				study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				Modality = [[NSString alloc] initWithString:extension];
				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
				serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				fileType = [[NSString stringWithString:@"IMAGE"] retain];
				
				if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
				{
					NSString *newSerieID = [[NSString alloc] initWithFormat:@"%@-%@-%@", serieID, imageID, [filePath lastPathComponent]];
					[serieID release];
					serieID = newSerieID;
				}
				
				NoOfSeries = 1;
				
				if( [extension isEqualToString:@"pdf"])
				{
					NSPDFImageRep		*pdfRepresentation = [NSPDFImageRep imageRepWithData: [NSData dataWithContentsOfFile: filePath]];
					
					NoOfFrames = [pdfRepresentation pageCount];
					
					if( NoOfFrames > 20) NoOfFrames = 20;   // Limit number of pages to 20 !
				}
				
				[dicomElements setObject:studyID forKey:@"studyID"];
				[dicomElements setObject:study forKey:@"studyDescription"];
				[dicomElements setObject:date forKey:@"studyDate"];
				[dicomElements setObject:Modality forKey:@"modality"];
				[dicomElements setObject:patientID forKey:@"patientID"];
				[dicomElements setObject:name forKey:@"patientName"];
				[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
				[dicomElements setObject:serieID forKey:@"seriesID"];
				[dicomElements setObject:name forKey:@"seriesDescription"];
				[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
				[dicomElements setObject:SOPUID forKey:@"SOPUID"];
				[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
				[dicomElements setObject:fileType forKey:@"fileType"];
				
				[otherImage release];
				
				return 0;
			}
	}
	
	if( [extension isEqualToString:@"mov"] == YES ||
		[extension isEqualToString:@"mpg"] == YES ||
		[extension isEqualToString:@"mpeg"] == YES ||
		[extension isEqualToString:@"avi"] == YES)
		{
			#if !__LP64__
			NSMovie *movie = [[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:filePath] byReference:NO];
			if( movie)
			{
				name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				patientID = [[NSString alloc] initWithString:name];
				studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				serieID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				
				
				study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				Modality = [[NSString alloc] initWithString:extension];
				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
				serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				fileType = [[NSString stringWithString:@"IMAGE"] retain];
				
				Movie			mov = [movie QTMovie];
				TimeValue		aTime = 0L;
				OSType			mediatype = 'eyes';
				Rect			tempRect;
				
				GetMovieBox (mov, &tempRect);
				tempRect.right -= tempRect.left;
				tempRect.bottom -= tempRect.top;
				tempRect.left = 0;
				tempRect.top = 0;
				
				height = tempRect.bottom;
				height /= 2;
				height *= 2;
				width = tempRect.right;
				width /= 2;
				width *= 2;
				
				NoOfFrames = 1;
				NoOfSeries = 1;
				do
				{
					GetMovieNextInterestingTime (   mov,
												   nextTimeMediaSample,
												   1,
												   &mediatype,
												   aTime,
												   1,
												   &aTime,
												   0L);
					if (aTime != -1) NoOfFrames++;
				} while (aTime != -1);
				
				if( NoOfFrames > 400) NoOfFrames = 400;   // Limit number of images to 400 !
				
				[dicomElements setObject:studyID forKey:@"studyID"];
				[dicomElements setObject:study forKey:@"studyDescription"];
				[dicomElements setObject:date forKey:@"studyDate"];
				[dicomElements setObject:Modality forKey:@"modality"];
				[dicomElements setObject:patientID forKey:@"patientID"];
				[dicomElements setObject:name forKey:@"patientName"];
				[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
				[dicomElements setObject:serieID forKey:@"seriesID"];
				[dicomElements setObject:name forKey:@"seriesDescription"];
				[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
				[dicomElements setObject:imageID forKey:@"SOPUID"];
				[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
				[dicomElements setObject:fileType forKey:@"fileType"];
				
				[movie release];
				
				return 0;
			}
			#else
			[QTMovie enterQTKitOnThreadDisablingThreadSafetyProtection];
			
			QTMovie *movie = [[QTMovie alloc] initWithURL:[NSURL fileURLWithPath:filePath] error: 0L];
			if( movie)
			{
				name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				patientID = [[NSString alloc] initWithString:name];
				studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				serieID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				
				
				study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				Modality = [[NSString alloc] initWithString:extension];
				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
				serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				fileType = [[NSString stringWithString:@"IMAGE"] retain];
				
				[movie gotoBeginning];
				
				height = [[movie currentFrameImage] size].height;
				height /= 2;
				height *= 2;
				width = [[movie currentFrameImage] size].width;
				width /= 2;
				width *= 2;
				
				NoOfFrames = 0;
				NoOfSeries = 1;
				
				QTTime previousTime;
				
				do
				{
					previousTime = [movie currentTime];
					NoOfFrames++;
					[movie stepForward];
				}
				while( QTTimeCompare( previousTime, [movie currentTime]) == NSOrderedAscending && NoOfFrames < 400);
				
				if( NoOfFrames > 400) NoOfFrames = 400;   // Limit number of images to 400 !
				
				[dicomElements setObject:studyID forKey:@"studyID"];
				[dicomElements setObject:study forKey:@"studyDescription"];
				[dicomElements setObject:date forKey:@"studyDate"];
				[dicomElements setObject:Modality forKey:@"modality"];
				[dicomElements setObject:patientID forKey:@"patientID"];
				[dicomElements setObject:name forKey:@"patientName"];
				[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
				[dicomElements setObject:serieID forKey:@"seriesID"];
				[dicomElements setObject:name forKey:@"seriesDescription"];
				[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
				[dicomElements setObject:imageID forKey:@"SOPUID"];
				[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
				[dicomElements setObject:fileType forKey:@"fileType"];
				
				[movie release];
				
				[QTMovie exitQTKitOnThread];
				
				return 0;
			}
			[QTMovie exitQTKitOnThread];
			#endif
	}
	
	return -1;
}

//-(short) getSIGNA5
//{
//	NSData		*file;
//	char		*ptr;
//	long		i;
//	NSString	*extension = [[filePath pathExtension] lowercaseString];
//	
//	file = [NSData dataWithContentsOfFile: filePath];
//	if( [file length] > 3300)
//	{
//		ptr = (char*) [file bytes];
//		
////		for( i = 0 ; i < [file length]; i++)
////		{
////			if( *((short*)&ptr[ i]) == 512 && *((short*)&ptr[ i+2]) == 512)
////			{
////				NSLog(@"Found! %d", i);
////				NSLog(@"%2.2f, %2.2f", *((float*)&ptr[ i+4]), *((float*)&ptr[ i+8]));
////				NSLog(@"%2.2f, %2.2f", *((float*)&ptr[ i+12]), *((float*)&ptr[ i+16]));
////				NSLog(@"%2.2f, %2.2f", *((float*)&ptr[ i+20]), *((float*)&ptr[ i+24]));
////			}
////		}
//		
//		//for( i = 0 ; i < [file length]; i++)
//		i = 3228;
//		{
//			if( ptr[ i] == 'I' && ptr[ i+1] == 'M' && ptr[ i+2] == 'G' && ptr[ i+3] == 'F')
//			{
//				NSLog(@"SIGNA 5.X File Format: %d", i);
//				
//				name = [[NSString alloc] initWithString: [[filePath lastPathComponent] stringByDeletingPathExtension]];
//				patientID = [[NSString alloc] initWithString:name];
//				studyID = [[NSString alloc] initWithString:name];
//				serieID = [[NSString alloc] initWithString:name];
//				imageID = [[NSString alloc] initWithString:[filePath pathExtension]];
//				study = [[NSString alloc] initWithString:@"unnamed"];
//				serie = [[NSString alloc] initWithString:@"unnamed"];
//				Modality = [[NSString alloc] initWithString:extension];
//				fileType = [[NSString stringWithString:@"SIGNA5"] retain];
//				
//				FILE *fp = fopen([ filePath UTF8String], "r");
//				
//				fseek(fp, i, SEEK_SET);
//				
//				int magic;
//				fread(&magic, 4, 1, fp);
//  
//				int offset;
//				fread(&offset, 4, 1, fp);
//				
//				NSLog(@"offset: %d", offset+i);
//				
//				fread(&height, 4, 1, fp);
//				fread(&width, 4, 1, fp);
//				int depth;
//				fread(&depth, 4, 1, fp);
//				
//				NoOfFrames = 1;
//				NoOfSeries = 1;
//				
//				NSLog(@"%dx%dx%d", height, width, depth);
//				
//				fclose( fp);
//				
//				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
//				
//				[dicomElements setObject:studyID forKey:@"studyID"];
//				[dicomElements setObject:study forKey:@"studyDescription"];
//				[dicomElements setObject:date forKey:@"studyDate"];
//				[dicomElements setObject:Modality forKey:@"modality"];
//				[dicomElements setObject:patientID forKey:@"patientID"];
//				[dicomElements setObject:name forKey:@"patientName"];
//				[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
//				[dicomElements setObject:serieID forKey:@"seriesID"];
//				[dicomElements setObject:name forKey:@"seriesDescription"];
//				[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
//				[dicomElements setObject:imageID forKey:@"SOPUID"];
//				[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
//				[dicomElements setObject:fileType forKey:@"fileType"];
//
//				if( name != 0L & studyID != 0L & serieID != 0L & imageID != 0L)
//				{
//					return 0;   // success
//				}
//			}
//		}
//		
//	}
//	
//	return -1;
//}

#include "BioradHeader.h"

-(short) getBioradPicFile
{
	FILE					*fp;
	char					*ptr;
	long					i;
	struct BioradHeader		header;
	
	NSString	*extension = [[filePath pathExtension] lowercaseString];
	
	if( [extension isEqualToString:@"pic"] == YES)
	{
		NSLog(@"Entering getBioradPicFile");
		
		fp = fopen( [filePath UTF8String], "r");
		if( fp)
		{
			fileType = [[NSString stringWithString:@"BIORAD"] retain];
			
			fread( &header, 76, 1, fp);
			
			// GJ: 040609 giving better names
			NSString	*fileNameStem = [[filePath lastPathComponent] stringByDeletingPathExtension];
			// Biorad files _usually_ keep the channel number in the last two digits
			NSString	*channelString = [fileNameStem substringFromIndex:[fileNameStem length]-2];
			NSString	*imageStem = [fileNameStem substringToIndex:[fileNameStem length]-2];
			name = [[NSString alloc] initWithString: [filePath lastPathComponent]];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:imageStem];
			serieID = [[NSString alloc] initWithString:fileNameStem];
			imageID = [[NSString alloc] initWithString:fileNameStem];
			study = [[NSString alloc] initWithString:imageStem];
			serie = [[NSString alloc] initWithString:fileNameStem];
			Modality = [[NSString alloc] initWithString:@"BRP"];
			//////////////////////////////////////////////////////////////////////////////////////
			
			short realheight = NSSwapLittleShortToHost(header.ny);
			height = realheight/2;
			height *= 2;
			short realwidth = NSSwapLittleShortToHost(header.nx);
			width =realwidth/ 2;
			width *= 2;			
			NoOfFrames = NSSwapLittleShortToHost(header.npic);
			NoOfSeries = 1;
			/*GJ: 040609 - Nice idea, but need to do more to implement this
			if([channelString isEqualToString:@"02"]) NoOfSeries = 2;
			if([channelString isEqualToString:@"03"]) NoOfSeries = 3;
			NSLog(@"No of Series = %d",NoOfSeries);
			*/
			
			date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
			
			NSLog(@"File has h x w x d %d x %d x %d",height,width,NoOfFrames);
			int bytesPerPixel=1;
			// if 8bit, byte_format==1 otherwise 16bit
			if (NSSwapLittleShortToHost(header.byte_format)!=1)
			{
				bytesPerPixel=2;
			}
			
			fclose( fp);
			
			[dicomElements setObject:studyID forKey:@"studyID"];
			[dicomElements setObject:study forKey:@"studyDescription"];
			[dicomElements setObject:date forKey:@"studyDate"];
			[dicomElements setObject:Modality forKey:@"modality"];
			[dicomElements setObject:patientID forKey:@"patientID"];
			[dicomElements setObject:name forKey:@"patientName"];
			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
			[dicomElements setObject:serieID forKey:@"seriesID"];
			[dicomElements setObject:name forKey:@"seriesDescription"];
			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];
			
			if( name != 0L & studyID != 0L & serieID != 0L & imageID != 0L & NoOfFrames>0)
			{
				return 0;   // success
			}
		}
	}
	
	return -1;
}

-(short) getLSM
{
	NSData		*file;
	const char		*ptr;
	long		i;
	
	NSString	*extension = [[filePath pathExtension] lowercaseString];
	
	if( [extension isEqualToString:@"lsm"] == YES)
	{
		file = [NSData dataWithContentsOfFile: filePath];
		if( [file length] > 1)
		{
			fileType = [[NSString stringWithString:@"LSM"] retain];
			
			ptr = [file bytes];
			
			if( ptr[ 2] == 42)
			{
				NSLog(@"LSM File");
			}
			
			name = [[NSString alloc] initWithString: [filePath lastPathComponent]];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:name];
			serieID = [[NSString alloc] initWithString:name];
			imageID = [[NSString alloc] initWithString:name];
			study = [[NSString alloc] initWithString:name];
			serie = [[NSString alloc] initWithString:name];
			Modality = [[NSString alloc] initWithString:@"LSM"];
			//////////////////////////////////////////////////////////////////////////////////////
			
			FILE *fp = fopen([ filePath UTF8String], "r");
			int it = 0;
			int nextoff=0;
			int counter=0;
			int pos=8, k;
			short shortval;
			
			int	LENGTH1, TIF_BITSPERSAMPLE_CHANNEL1, TIF_BITSPERSAMPLE_CHANNEL2, TIF_BITSPERSAMPLE_CHANNEL3;
			int	TIF_COMPRESSION, TIF_PHOTOMETRICINTERPRETATION, LENGTH2, TIF_STRIPOFFSETS, TIF_SAMPLESPERPIXEL, TIF_STRIPBYTECOUNTS;
			int	TIF_CZ_LSMINFO, TIF_STRIPOFFSETS1, TIF_STRIPOFFSETS2, TIF_STRIPOFFSETS3;
			int	TIF_STRIPBYTECOUNTS1, TIF_STRIPBYTECOUNTS2, TIF_STRIPBYTECOUNTS3;
			
			do
			{
				fseek(fp, 8, SEEK_SET);
				fread(&shortval, 2, 1, fp);
				it = EndianU16_LtoN( shortval);
				for( k=0 ; k<it ; k++)
				{
					unsigned char   tags2[ 12];
					fseek(fp, pos+2+12*k, SEEK_SET);
					fread( &tags2, 12, 1, fp);
					
					{
						int TAGTYPE = 0;
						int LENGTH = 0;
						int MASK = 0x00ff;
						int MASK2 = 0x000000ff;
						
						TAGTYPE = ((tags2[1] & MASK) << 8) | ((tags2[0] & MASK ) <<0);
						LENGTH = ((tags2[7] & MASK2) << 24) | ((tags2[6] & MASK2) << 16) | ((tags2[5] & MASK2) << 8) | (tags2[4] & MASK2);
						
						switch (TAGTYPE)
						{
							case 254:
							//	lsm_fi.TIF_NEWSUBFILETYPE = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
								break;
							case 256:
								width = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
								break;
							case 257:
								height = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
								break;
							case 258:
								LENGTH1 = ((tags2[7] & MASK2) << 24) | ((tags2[6] & MASK2) << 16) | ((tags2[5] & MASK2) << 8) | (tags2[4] & MASK2);
								TIF_BITSPERSAMPLE_CHANNEL1 = ((tags2[8] & MASK2) << 0);
								TIF_BITSPERSAMPLE_CHANNEL2 = ((tags2[9] & MASK2) << 0);
								TIF_BITSPERSAMPLE_CHANNEL3 = ((tags2[10] & MASK2) << 0);
								break;
							case 259:
								TIF_COMPRESSION = ((tags2[8] & MASK2) << 0);
								break;
							case 262:
								TIF_PHOTOMETRICINTERPRETATION = ((tags2[8] & MASK2) << 0);
								break;
							case 273:
								LENGTH2 = ((tags2[7] & MASK2) << 24) | ((tags2[6] & MASK2) << 16) | ((tags2[5] & MASK2) << 8) | (tags2[4] & MASK2);
								TIF_STRIPOFFSETS = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
								break;
							case 277:
								TIF_SAMPLESPERPIXEL = ((tags2[8] & MASK2) << 0);
								break;
							case 279:
								TIF_STRIPBYTECOUNTS = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
								break;
							case 34412:
								TIF_CZ_LSMINFO = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
								break;
							default:
								break;
						}
					}
				}
				
				fseek(fp, TIF_STRIPOFFSETS, SEEK_SET);
				
				fread( &TIF_STRIPOFFSETS1, 4, 1, fp);   TIF_STRIPOFFSETS1 = EndianU32_LtoN( TIF_STRIPOFFSETS1);
				fread( &TIF_STRIPOFFSETS2, 4, 1, fp);   TIF_STRIPOFFSETS2 = EndianU32_LtoN( TIF_STRIPOFFSETS2);
				fread( &TIF_STRIPOFFSETS3, 4, 1, fp);   TIF_STRIPOFFSETS3 = EndianU32_LtoN( TIF_STRIPOFFSETS3);
				
				fseek(fp, (int)pos + 2 + 12 * (int)it, SEEK_SET);
				fread( &nextoff, 4, 1, fp);
				pos = EndianU32_LtoN( nextoff);
				counter++;
			//	if (LENGTH2==1) STRIPOFF.add( new Long( lsm_fi.TIF_STRIPOFFSETS  ) );
			//	else
			//		STRIPOFF.add( new Long( lsm_fi.TIF_STRIPOFFSETS1  ) );
					
			//	IMAGETYPE.add( new Long( lsm_fi.TIF_NEWSUBFILETYPE ) );

			} while( 0);	//while (nextoff!=0);

			/* Searches for the number of tags in the first image directory */
			int iterator1;
			fseek(fp, 8, SEEK_SET);
			fread(&shortval, 2, 1, fp);
			iterator1 = EndianU16_LtoN( shortval);
			
			/* Analyses each tag found */
			for ( k=0 ; k<iterator1 ; k++)
			{
				unsigned char   TAG1[ 12];
				fseek(fp, 10+12*k, SEEK_SET);
				fread( &TAG1, 12, 1, fp);
				
				{
					int TAGTYPE = 0;
					int LENGTH = 0;
					int MASK = 0x00ff;
					int MASK2 = 0x000000ff;
					
					TAGTYPE = ((TAG1[1] & MASK) << 8) | ((TAG1[0] & MASK ) <<0);
					LENGTH = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);
					
					switch (TAGTYPE)
					{
						case 254:
						//	lsm_fi.TIF_NEWSUBFILETYPE = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
							break;
						case 256:
							width = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
							break;
						case 257:
							height = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
							break;
						case 258:
							LENGTH1 = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);
							TIF_BITSPERSAMPLE_CHANNEL1 = ((TAG1[8] & MASK2) << 0);
							TIF_BITSPERSAMPLE_CHANNEL2 = ((TAG1[9] & MASK2) << 0);
							TIF_BITSPERSAMPLE_CHANNEL3 = ((TAG1[10] & MASK2) << 0);
							break;
						case 259:
							TIF_COMPRESSION = ((TAG1[8] & MASK2) << 0);
							break;
						case 262:
							TIF_PHOTOMETRICINTERPRETATION = ((TAG1[8] & MASK2) << 0);
							break;
						case 273:
							LENGTH2 = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);
							TIF_STRIPOFFSETS = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
							break;
						case 277:
							TIF_SAMPLESPERPIXEL = ((TAG1[8] & MASK2) << 0);
							break;
						case 279:
							TIF_STRIPBYTECOUNTS = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
							break;
						case 34412:
							TIF_CZ_LSMINFO = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
							break;
						default:
							break;
					}
				}
			} // end for
			
			fseek(fp, TIF_STRIPOFFSETS, SEEK_SET);
			
			fread( &TIF_STRIPOFFSETS1, 4, 1, fp);   TIF_STRIPOFFSETS1 = EndianU32_LtoN( TIF_STRIPOFFSETS1);
			fread( &TIF_STRIPOFFSETS2, 4, 1, fp);   TIF_STRIPOFFSETS2 = EndianU32_LtoN( TIF_STRIPOFFSETS2);
			fread( &TIF_STRIPOFFSETS3, 4, 1, fp);   TIF_STRIPOFFSETS3 = EndianU32_LtoN( TIF_STRIPOFFSETS3);
			
			fseek(fp, TIF_STRIPBYTECOUNTS, SEEK_SET);
			
			fread( &TIF_STRIPBYTECOUNTS1, 4, 1, fp);   TIF_STRIPBYTECOUNTS1 = EndianU32_LtoN( TIF_STRIPBYTECOUNTS1);
			fread( &TIF_STRIPBYTECOUNTS2, 4, 1, fp);   TIF_STRIPBYTECOUNTS2 = EndianU32_LtoN( TIF_STRIPBYTECOUNTS2);
			fread( &TIF_STRIPBYTECOUNTS3, 4, 1, fp);   TIF_STRIPBYTECOUNTS3 = EndianU32_LtoN( TIF_STRIPBYTECOUNTS3);
			
			if( TIF_CZ_LSMINFO)
			{
				fseek(fp, TIF_CZ_LSMINFO + 8, SEEK_SET);
				
				int		DIMENSION_X, DIMENSION_Y, DIMENSION_Z, NUMBER_OF_CHANNELS, TIMESTACKSIZE, DATATYPE, DATATYPE2, SCANTYPE;
				short   SPECTRALSCAN;
				double   VOXELSIZE_X, VOXELSIZE_Y, VOXELSIZE_Z;
				
				fread( &DIMENSION_X, 4, 1, fp);		DIMENSION_X = EndianS32_LtoN( DIMENSION_X);
				fread( &DIMENSION_Y, 4, 1, fp);		DIMENSION_Y = EndianS32_LtoN( DIMENSION_Y);
				fread( &DIMENSION_Z, 4, 1, fp);		DIMENSION_Z = EndianS32_LtoN( DIMENSION_Z);
				
				fread( &NUMBER_OF_CHANNELS, 4, 1, fp);		NUMBER_OF_CHANNELS = EndianS32_LtoN( NUMBER_OF_CHANNELS);
				fread( &TIMESTACKSIZE, 4, 1, fp);			TIMESTACKSIZE = EndianS32_LtoN( TIMESTACKSIZE);
				
				fread( &DATATYPE, 4, 1, fp);			DATATYPE = EndianU32_LtoN( DATATYPE);
				
				fseek(fp, TIF_CZ_LSMINFO + 64, SEEK_SET);
				fread( &SCANTYPE, 4, 1, fp);			SCANTYPE = EndianU32_LtoN( SCANTYPE);
	
				switch (SCANTYPE) {
				case 3:
					NoOfFrames = TIMESTACKSIZE;
					NoOfSeries = NUMBER_OF_CHANNELS;
					break;
				case 4:
					NoOfFrames = TIMESTACKSIZE;
					NoOfSeries = NUMBER_OF_CHANNELS;
					break;
				case 6:
					NoOfFrames = DIMENSION_Z  * TIMESTACKSIZE;
					NoOfSeries = NUMBER_OF_CHANNELS;
					break;
				default:
					NoOfFrames = DIMENSION_Z  * TIMESTACKSIZE;
					NoOfSeries = NUMBER_OF_CHANNELS;
					break;
				}
				
				
				
				//NSLog(@"getLSM opened an LSM file with %d series",NoOfSeries);
				
	//			stream.seek((int)position+90);
	//			SPECTRALSCAN = swap(stream.readShort());
	//			
	//			// second datatype , orignal scandata or calculated data or animation
	//			stream.seek((int)position+92);
	//			DATATYPE2 = swap(stream.readInt());
	//			
	//			stream.seek((int)position+100);
	//			OFFSET_INPUTLUT = swap(stream.readInt());
	//			
	//			stream.seek((int)position+104);
	//			OFFSET_OUTPUTLUT = swap(stream.readInt());
	//			
	
//				fseek(fp, TIF_CZ_LSMINFO + 40, SEEK_SET);
//				fread( &VOXELSIZE_X, 8, 1, fp);
//				VOXELSIZE_X = EndianU32_LtoN( VOXELSIZE_X);
				
//				fseek(fp, TIF_CZ_LSMINFO + 48, SEEK_SET);
//				stream.seek((int)position + 48);
//				VOXELSIZE_Y = swap(stream.readDouble());
//				
//				fseek(fp, TIF_CZ_LSMINFO + 56, SEEK_SET);
//				stream.seek((int)position + 56);
//				VOXELSIZE_Z = swap(stream.readDouble());

	//			
	//			stream.seek((int)position + 108);
	//			OFFSET_CHANNELSCOLORS = swap(stream.readInt());
	//			
	//			stream.seek((int)position + 120);
	//			OFFSET_CHANNELDATATYPES = swap(stream.readInt());
	//			
	//			stream.seek((int)position+124);
	//			OFFSET_SCANINFO = swap(stream.readInt());
	//			
	//			stream.seek((int)position+132);
	//			OFFSET_TIMESTAMPS = swap(stream.readInt());
	//			
	//			stream.seek((int)position+204);
	//			OFFSET_CHANNELWAVELENGTH = swap(stream.readInt());
			}
			
			fclose( fp);
			



			date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
			
			[dicomElements setObject:studyID forKey:@"studyID"];
			[dicomElements setObject:study forKey:@"studyDescription"];
			[dicomElements setObject:date forKey:@"studyDate"];
			[dicomElements setObject:Modality forKey:@"modality"];
			[dicomElements setObject:patientID forKey:@"patientID"];
			[dicomElements setObject:name forKey:@"patientName"];
			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
//			[dicomElements setObject:serieID forKey:@"seriesID"];
//			[dicomElements setObject:name forKey:@"seriesDescription"];
//			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
//			[dicomElements setObject:imageID forKey:@"SOPUID"];
//			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];
			
////////////////
			for (i = 0; i < NoOfSeries; i++)
			{
				NSString* SeriesNum;
				if (i)
					SeriesNum = [NSString stringWithFormat:@"%d",i];
				else
					SeriesNum = @"";
								
				[dicomElements setObject:[SeriesNum stringByAppendingString:serieID] forKey:[@"seriesID" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[SeriesNum stringByAppendingString:name] forKey:[@"seriesDescription" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[NSNumber numberWithInt: i] forKey:[@"seriesNumber" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[imageID stringByAppendingString:SeriesNum] forKey:[@"SOPUID" stringByAppendingString:SeriesNum]];
				[dicomElements setObject:[NSNumber numberWithInt: i] forKey:[@"imageID" stringByAppendingString:SeriesNum]];
			}
////////////////
			return 0;
		}
	}
	
	return -1;
}

#include "Analyze.h"

-(short) getAnalyze
{
	struct dsr  *Analyze;
	BOOL		intelByteOrder = NO;
	NSData		*file;
	NSString	*extension = [[filePath pathExtension] lowercaseString];

	if( [extension isEqualToString:@"hdr"] == YES)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:[[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)
		{
			file = [NSData dataWithContentsOfFile: filePath];
			if( [file length] == 348)
			{
				fileType = [[NSString stringWithString:@"ANALYZE"] retain];
				
				Analyze = (struct dsr*) [file bytes];
				
				name = [[NSString alloc] initWithCString: replaceBadCharacter(Analyze->hk.db_name, NSISOLatin1StringEncoding) encoding: NSASCIIStringEncoding];
				patientID = [[NSString alloc] initWithString:name];
				studyID = [[NSString alloc] initWithString:name];
				serieID = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
				imageID = [[NSString alloc] initWithString:name];
				study = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
				serie = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
				Modality = [[NSString alloc] initWithString:@"ANZ"];
				
				date = [[NSCalendarDate alloc] initWithString:[NSString stringWithCString: Analyze->hist.exp_date] calendarFormat:@"%Y%m%d"];
				if(date == 0L) date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
				
				short endian = Analyze->dime.dim[ 0];		// dim[0] 
				if ((endian < 0) || (endian > 15)) 
				{
					intelByteOrder = YES;
				}
				
				height = Analyze->dime.dim[ 1];
				if( intelByteOrder) height = Endian16_Swap( height);
				height /= 2;
				height *= 2;
				width = Analyze->dime.dim[ 2];
				if( intelByteOrder) width = Endian16_Swap( width);
				width /= 2;
				width *= 2;
				
				NoOfFrames = Analyze->dime.dim[ 3];
				if( intelByteOrder) NoOfFrames = Endian16_Swap( NoOfFrames);
				NoOfSeries = 1;
				
				[dicomElements setObject:studyID forKey:@"studyID"];
				[dicomElements setObject:study forKey:@"studyDescription"];
				[dicomElements setObject:date forKey:@"studyDate"];
				[dicomElements setObject:Modality forKey:@"modality"];
				[dicomElements setObject:patientID forKey:@"patientID"];
				[dicomElements setObject:name forKey:@"patientName"];
				[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
				[dicomElements setObject:serieID forKey:@"seriesID"];
				[dicomElements setObject:name forKey:@"seriesDescription"];
				[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
				[dicomElements setObject:imageID forKey:@"SOPUID"];
				[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
				[dicomElements setObject:fileType forKey:@"fileType"];
				
				if( name != 0L & studyID != 0L & serieID != 0L & imageID != 0L)
				{
					return 0;   // success
				}
			}
		}
	}
	
	return -1;
}

-(short) getNIfTI
{
	// NIfTI support developed by Zack Mahdavi at the Center for Neurological Imaging, a division of Harvard Medical School
	// For more information: http://cni.bwh.harvard.edu/
	// For questions or suggestions regarding NIfTI integration in OsiriX, please contact zmahdavi@bwh.harvard.edu

	struct nifti_1_header  *NIfTI;
	NSData		*file;
	NSString	*extension = [[filePath pathExtension] lowercaseString];

	if( (( [extension isEqualToString:@"hdr"] == YES) && 
		([[NSFileManager defaultManager] fileExistsAtPath:[[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)) ||
		( [extension isEqualToString:@"nii"] == YES))
	{
		fileType = [[NSString stringWithString:@"NIfTI"] retain];
		
		NIfTI = (nifti_1_header *) nifti_read_header([filePath UTF8String], nil, 0);
		
		if( (NIfTI->magic[0] == 'n')                           &&
			(NIfTI->magic[1] == 'i' || NIfTI->magic[1] == '+')   &&
			(NIfTI->magic[2] == '1')                           &&
			(NIfTI->magic[3] == '\0') )
		{
			name = [DicomFile NSreplaceBadCharacter: [filePath lastPathComponent]]; 
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:name];
			serieID = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
			imageID = [[NSString alloc] initWithString:name];
			study = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
			serie = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
			Modality = [[NSString alloc] initWithString:@"NIfTI"];
			date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
			
			width = NIfTI->dim[ 1];
			width /= 2;
			width *= 2;

			height = NIfTI->dim[ 2];
			height /= 2;
			height *= 2;
			
			NoOfFrames = NIfTI->dim[ 3];
			NoOfSeries = 1;
			
			[dicomElements setObject:studyID forKey:@"studyID"];
			[dicomElements setObject:study forKey:@"studyDescription"];
			[dicomElements setObject:date forKey:@"studyDate"];
			[dicomElements setObject:Modality forKey:@"modality"];
			[dicomElements setObject:patientID forKey:@"patientID"];
			[dicomElements setObject:name forKey:@"patientName"];
			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
			[dicomElements setObject:serieID forKey:@"seriesID"];
			[dicomElements setObject:name forKey:@"seriesDescription"];
			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];
			
			
			if( name != 0L & studyID != 0L & serieID != 0L & imageID != 0L)
			{
				return 0;   // success
			}
		}
	}
	
	return -1;
}
	
+(NSXMLDocument *) getNIfTIXML : (NSString *) file 
{
	NSString	*returnString;
	nifti_image *NIfTI;
	NSString	*extension = [[file pathExtension] lowercaseString];
	NSXMLDocument *xmlDoc;
	
	NSXMLElement *rootElement = [[NSXMLElement alloc] initWithName:@"NIfTIObject"];
	xmlDoc = [[NSXMLDocument alloc] initWithRootElement: rootElement];
	
	// Process NIfTI header
	
	if([self isNIfTIFile: file])
	{
		NIfTI = nifti_image_read( [file UTF8String], 0);
		 
		returnString = [[NSString alloc] initWithCString: nifti_image_to_ascii( NIfTI)];
		NSLog(@"NIFTI INFO:  %@", returnString);
		
		// Now build the XML document

		// Cycle through string, and parse out key and value from each line.  Then store in XML document.
		NSArray *allLines = [returnString componentsSeparatedByString:@"\n"];
		
		if([allLines count] > 0)
		{
			NSLog(@"allLines Count:  %d", [allLines count]);
			for(id loopItem1 in allLines)
			{
				NSString* aLine = (NSString *) loopItem1;
				
				// Now split string based on location of equals (=) sign
				NSArray *splitLine = [aLine componentsSeparatedByString:@" = '"];
				NSLog(@"splitLine %@", splitLine);
				
				if([splitLine count] == 2)
				{
					// Expected value
					NSString * key = (NSString *) [splitLine objectAtIndex:0]; 
					key = [key substringFromIndex: 2];
					NSString * value = (NSString *) [splitLine objectAtIndex:1];
					value = [value substringToIndex:[value length] - 1];
					
					NSLog(@"key value %@,%@", key, value);
					
					// Create node, then add to xml
					NSXMLElement *node = [[NSXMLElement alloc] initWithName: key];
					[node addAttribute:[NSXMLNode attributeWithName:@"group" stringValue:@""]];
					[node addAttribute:[NSXMLNode attributeWithName:@"element" stringValue:@""]];
					[node addAttribute:[NSXMLNode attributeWithName:@"vr" stringValue:@""]];
					[node addAttribute:[NSXMLNode attributeWithName:@"attributeTag" stringValue:@""]];
					
					NSXMLElement *childNode = [[NSXMLElement alloc] initWithName:@"value" stringValue:value];
					[childNode addAttribute:[NSXMLNode attributeWithName:@"number" stringValue:@"0"]];
					[node addChild:childNode];
					
					[rootElement addChild:node];
				}
			}
		}
		
		// Review the NIfTI extension list and add any elements to list.
		if( NIfTI->num_ext > 0 && NIfTI->ext_list != NULL )
		{
			int c = 0;
			nifti1_extension * ext;
			ext = NIfTI->ext_list;
			for ( c = 0; c < NIfTI->num_ext; c++ )
			{
				NSXMLElement *node = [[NSXMLElement alloc] initWithName:
					[@"extension: ecode " stringByAppendingString:[NSString stringWithFormat:@"%i", ext->ecode]]];
				[node addAttribute:[NSXMLNode attributeWithName:@"group" stringValue:@""]];
				[node addAttribute:[NSXMLNode attributeWithName:@"element" stringValue:@""]];
				[node addAttribute:[NSXMLNode attributeWithName:@"vr" stringValue:@""]];
				[node addAttribute:[NSXMLNode attributeWithName:@"attributeTag" stringValue:@""]];
				
				NSXMLElement *childNode = [[NSXMLElement alloc] initWithName:@"value" stringValue:[NSString stringWithCString:ext->edata]];
				[childNode addAttribute:[NSXMLNode attributeWithName:@"number" stringValue:@"0"]];
				[node addChild:childNode];
				
				[rootElement addChild:node];

				ext++;
			}
		}
	}
	return xmlDoc;
} 
		
-(short) getDicomFilePapyrus :(BOOL) forceConverted
{
	int					itemType;
	long				cardiacTime = -1;
	short				x, theErr;
	PapyShort           fileNb, imageNb;
	PapyULong           nbVal;
	UValue_T            *val;
	SElement			*theGroupP;
	NSString			*converted = 0L;
	NSStringEncoding	encoding;//NSStringEncoding
	NSString *echoTime = nil;
	NSString *sopClassUID = nil;
	NSMutableArray *imageTypeArray = 0L;
	
	[PapyrusLock lock];
	
	// open the test file
	if( forceConverted) fileNb = -1;
	else fileNb = Papy3FileOpen ( (char*) [filePath UTF8String], (PAPY_FILE) 0, TRUE, 0);
	if( fileNb < 0)
	{
		converted = convertDICOM( filePath);
		fileNb = Papy3FileOpen (  (char*) [converted UTF8String], (PAPY_FILE) 0, TRUE, 0);
	}
	
	[PapyrusLock unlock];
	
	if (fileNb >= 0)
	{
		if( gIsPapyFile [fileNb] == DICOM10 || gIsPapyFile [fileNb] == DICOM_NOT10)	// Actual version of OsiriX supports only DICOM... should we support PAPYRUS?... NO: too much work!
		{
			NSString *characterSet = 0L;
			
			if( gArrCompression  [fileNb] == MPEG2MPML)
			{
				fileType = [[NSString stringWithString:@"DICOMMPEG2"] retain];
				[dicomElements setObject:fileType forKey:@"fileType"];
			}
			else
			{
				fileType = [[NSString stringWithString:@"DICOM"] retain];
				[dicomElements setObject:fileType forKey:@"fileType"];
			}
			
			imageNb = 1;
			
			if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
			
			encoding = NSISOLatin1StringEncoding;
			
			if (COMMENTSAUTOFILL == YES || CHECKFORLAVIM == YES)
			{
				if( COMMENTSAUTOFILL)
				{
					NSString	*commentsField;
					
					theErr = Papy3GotoGroupNb (fileNb, COMMENTSGROUP);
					if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
					{
						SElement *inGrOrModP = theGroupP;
						
						int theEnumGrNb = Papy3ToEnumGroup( COMMENTSGROUP);
						int theMaxElem = gArrGroup [theEnumGrNb].size;
						int j;
						
						for (j = 0; j < theMaxElem; j++, inGrOrModP++)
						{
							if( inGrOrModP->element == COMMENTSELEMENT)
							{
								if( inGrOrModP->nb_val > 0)
								{
									UValue_T *theValueP = inGrOrModP->value;
									
									if( theValueP->a)
									{
										commentsField = [NSString stringWithCString:theValueP->a];
										
										[dicomElements setObject:commentsField forKey:@"commentsAutoFill"];
									}
								}
							}
						}
						theErr = Papy3GroupFree (&theGroupP, TRUE);
					}
				}
				
				if( CHECKFORLAVIM)
				{
					NSString	*album = 0L;
					
					theErr = Papy3GotoGroupNb (fileNb, 0x0020);
					if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
					{
						SElement *inGrOrModP = theGroupP;
						
						int theEnumGrNb = Papy3ToEnumGroup( 0x0020);
						int theMaxElem = gArrGroup [theEnumGrNb].size;
						int j;
						
						for (j = 0; j < theMaxElem; j++, inGrOrModP++)
						{
							if( inGrOrModP->element == 0x4000)
							{
								if( inGrOrModP->nb_val > 0)
								{
									UValue_T *theValueP = inGrOrModP->value;
									
									if( theValueP->a)
									{
										album = [NSString stringWithCString:theValueP->a];
										
										if( [album length] >= 2)
										{
											if( [[album substringToIndex:2] isEqualToString: @"LV"])
											{
												album = [album substringFromIndex:2];
												[dicomElements setObject:album forKey:@"album"];
											}
										}
									}
								}
							}
						}
						
						theErr = Papy3GroupFree (&theGroupP, TRUE);
					}
					
					theErr = Papy3GotoGroupNb (fileNb, 0x0040);
					if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
					{
						SElement *inGrOrModP = theGroupP;
						
						int theEnumGrNb = Papy3ToEnumGroup( 0x0040);
						int theMaxElem = gArrGroup [theEnumGrNb].size;
						int j;
						
						for (j = 0; j < theMaxElem; j++, inGrOrModP++)
						{
							if( inGrOrModP->element == 0x0280)
							{
								if( inGrOrModP->nb_val > 0)
								{
									UValue_T *theValueP = inGrOrModP->value;
									
									if( theValueP->a)
									{
										album = [NSString stringWithCString:theValueP->a];
										
										if( [album length] >= 2)
										{
											if( [[album substringToIndex:2] isEqualToString: @"LV"])
											{
												album = [album substringFromIndex:2];
												[dicomElements setObject:album forKey:@"album"];
											}
										}
									}
								}
							}
							
							if( inGrOrModP->element == 0x1400)
							{
								if( inGrOrModP->nb_val > 0)
								{
									UValue_T *theValueP = inGrOrModP->value;
									
									if( theValueP->a)
									{
										album = [NSString stringWithCString:theValueP->a];
										
										if( [album length] >= 2)
										{
											if( [[album substringToIndex:2] isEqualToString: @"LV"])
											{
												album = [album substringFromIndex:2];
												[dicomElements setObject:album forKey:@"album"];
											}
										}
									}
								}
							}
						}
						theErr = Papy3GroupFree (&theGroupP, TRUE);
					}
				}
			}
			
			if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
			
			theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0008);
			
			if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
			{
				val = Papy3GetElement (theGroupP, papSOPClassUIDGr, &nbVal, &itemType);
				if (val != NULL)
				{
					sopClassUID = [NSString stringWithCString:val->a];
					[dicomElements setObject:sopClassUID forKey:@"SOPClassUID"];					
				}
				
				val = Papy3GetElement (theGroupP, papSpecificCharacterSetGr, &nbVal, &itemType);
				if (val != NULL)
				{
					val += nbVal-1;
					
					characterSet = [NSString stringWithCString:val->a];
					
					encoding = [NSString encodingForDICOMCharacterSet:characterSet];
				}
				
				val = Papy3GetElement (theGroupP, papImageTypeGr, &nbVal, &itemType);
				if (val != NULL)
				{
					UValue_T *ty = val;
					imageTypeArray = [NSMutableArray array];
					for( int z = 0; z < nbVal ; z++)
					{
						[imageTypeArray addObject: [[[NSString alloc] initWithCString:ty->a encoding: NSASCIIStringEncoding] autorelease]];
						ty++;
					}
					
					if( nbVal > 2)
					{
						val+=2;
						imageType = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
					}
					else imageType = 0L;
				}
				else imageType = 0L;
				
				if( imageType) [dicomElements setObject:imageType forKey:@"imageType"];
				
				val = Papy3GetElement (theGroupP, papSOPInstanceUIDGr, &nbVal, &itemType);
				if (val != NULL) SOPUID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
				else SOPUID = 0L;
				if( SOPUID) [dicomElements setObject:SOPUID forKey:@"SOPUID"];
				
				// TEST
				
//				char*	t = sopInstanceUIDEncode( SOPUID);
//				NSLog( SOPUID);
//				NSLog( sopInstanceUIDDecode( t));
//				NSLog( @"%d %d", strlen( t), [SOPUID length]);
//				free( t);
				
				val = Papy3GetElement (theGroupP, papStudyDescriptionGr, &nbVal, &itemType); //
				if (val != NULL) study = [[NSString alloc] initWithBytes: replaceBadCharacter(val->a, encoding) length: strlen(val->a) encoding:encoding];
				else study = [[NSString alloc] initWithString:@"unnamed"];
				[dicomElements setObject:study forKey:@"studyDescription"];
				
				val = Papy3GetElement (theGroupP, papModalityGr, &nbVal, &itemType);
				if (val != NULL) Modality = [[NSString alloc] initWithCString:val->a encoding: encoding];
				else Modality = [[NSString alloc] initWithString:@"OT"];
				[dicomElements setObject:Modality forKey:@"modality"];
				
				val = Papy3GetElement (theGroupP, papImageDateGr, &nbVal, &itemType);
				if (val != NULL)
				{
					NSString	*studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
					if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
					
					val = Papy3GetElement (theGroupP, papImageTimeGr, &nbVal, &itemType);
					if (val != NULL)
					{
						NSString*   completeDate;
						NSString*   studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
						
						completeDate = [studyDate stringByAppendingString:studyTime];
						
						if( [studyTime length] == 6)
							date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
						else
							date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
					}
					else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				}
				else
				{
					val = Papy3GetElement (theGroupP, papAcquisitionDateGr, &nbVal, &itemType);
					if (val != NULL)
					{
						NSString	*studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
						if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
						
						val = Papy3GetElement (theGroupP, papAcquisitionTimeGr, &nbVal, &itemType);
						if (val != NULL)
						{
							NSString*   completeDate;
							NSString*   studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
							
							completeDate = [studyDate stringByAppendingString:studyTime];
							
							if( [studyTime length] == 6)
								date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
							else
								date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
						}
						else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
					}
					else
					{
						val = Papy3GetElement (theGroupP, papSeriesDateGr, &nbVal, &itemType);
						if (val != NULL)
						{
							NSString	*studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
							if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
							
							val = Papy3GetElement (theGroupP, papSeriesTimeGr, &nbVal, &itemType);
							if (val != NULL)
							{
								NSString*   completeDate;
								NSString*   studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
								
								completeDate = [studyDate stringByAppendingString:studyTime];
								
								if( [studyTime length] == 6)
									date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
								else
									date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
							}
							else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
						}
						else
						{
							val = Papy3GetElement (theGroupP, papStudyDateGr, &nbVal, &itemType);
							if (val != NULL)
							{
								NSString	*studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
								if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
								
								val = Papy3GetElement (theGroupP, papStudyTimeGr, &nbVal, &itemType);
								if (val != NULL)
								{
									NSString*   completeDate;
									NSString*   studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
									
									completeDate = [studyDate stringByAppendingString:studyTime];
									
									if( [studyTime length] == 6)
										date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
									else
										date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
								}
								else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
							}
							else date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:0L] retain];
						}
					}
				}
				
				if( date) [dicomElements setObject:date forKey:@"studyDate"];
				
				 val = Papy3GetElement (theGroupP, papSeriesDescriptionGr, &nbVal, &itemType);
				if (val != NULL) serie = [[NSString alloc] initWithBytes: replaceBadCharacter(val->a, encoding) length: strlen(val->a) encoding:encoding];
				else serie = [[NSString alloc] initWithString:@"unnamed"];
				[dicomElements setObject:serie forKey:@"seriesDescription"];
				
				 val = Papy3GetElement (theGroupP, papInstitutionNameGr, &nbVal, &itemType);
				if (val != NULL) {
					NSString *institution = [[NSString alloc] initWithBytes: replaceBadCharacter(val->a, encoding) length: strlen(val->a) encoding:encoding];
					[dicomElements setObject:institution forKey:@"institutionName"];
					[institution release];
				}
				
				val = Papy3GetElement (theGroupP, papReferringPhysiciansNameGr, &nbVal, &itemType);
				if (val != NULL) {
					NSString *physician = [[NSString alloc] initWithBytes: replaceBadCharacter(val->a, encoding) length: strlen(val->a) encoding:encoding];
					[dicomElements setObject:physician forKey:@"referringPhysiciansName"];
					[physician release];
				}
				
				val = Papy3GetElement (theGroupP, papPerformingPhysiciansNameGr, &nbVal, &itemType);
				if (val != NULL) {
					NSString *physician = [[NSString alloc] initWithBytes: replaceBadCharacter(val->a, encoding) length: strlen(val->a) encoding:encoding];
					[dicomElements setObject:physician forKey:@"performingPhysiciansName"];
					[physician release];
				}
				
				val = Papy3GetElement (theGroupP, papAccessionNumberGr, &nbVal, &itemType);
				if (val != NULL) {
					[dicomElements setObject:[[[NSString alloc] initWithCString: val->a encoding: NSASCIIStringEncoding] autorelease] forKey:@"accessionNumber"];
				}
				
				theErr = Papy3GroupFree (&theGroupP, TRUE);
			}
			else
			{
				study = [[NSString alloc] initWithString:@"unnamed"];
				Modality = [[NSString alloc] initWithString:@"OT"];
				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
				serie = [[NSString alloc] initWithString:@"unnamed"];
				
				[dicomElements setObject:date forKey:@"studyDate"];
				[dicomElements setObject:Modality forKey:@"modality"];
				[dicomElements setObject:serie forKey:@"seriesDescription"];
				[dicomElements setObject:study forKey:@"studyDescription"];
			}
			
			//if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
			// get the Patient group
			theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0010);
			if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
			{
				//Patient Name
				val = Papy3GetElement (theGroupP, papPatientsNameGr, &nbVal, &itemType);
				if (val != NULL)
				{
					name = [[NSString alloc] initWithBytes: replaceBadCharacter(val->a, encoding)  length: strlen(val->a) encoding:encoding];
					if(name == 0L) name = [[NSString alloc] initWithCString: val->a encoding: encoding];
				}
				else name = [[NSString alloc] initWithString:@"No name"];
				[dicomElements setObject:name forKey:@"patientName"];
				
				//Patient ID
				val = Papy3GetElement (theGroupP, papPatientIDGr, &nbVal, &itemType);
				if (val != NULL)
				{
					patientID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
					[dicomElements setObject:patientID forKey:@"patientID"];
				}
				
				// Patient Age
				val = Papy3GetElement (theGroupP, papPatientsAgeGr, &nbVal, &itemType);
				if (val != NULL) {  
					NSString *patientAge =  [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
					[dicomElements setObject:patientAge forKey:@"patientAge"];
					
					//NSLog(@"Patient Age %@", patientAge);
				}
				//Patient BD
				val = Papy3GetElement (theGroupP, papPatientsBirthDateGr, &nbVal, &itemType);
				if (val != NULL) {  
					NSString		*patientDOB =  [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
					NSCalendarDate	*DOB = [NSCalendarDate dateWithString: patientDOB calendarFormat:@"%Y%m%d"];
					
					NSDate	*test = [NSDate dateWithTimeIntervalSinceReferenceDate: [DOB timeIntervalSinceReferenceDate]];
					
					if( DOB) [dicomElements setObject:test forKey:@"patientBirthDate"];
				}
				//Patients Sex
				val = Papy3GetElement (theGroupP, papPatientsSexGr, &nbVal, &itemType);
				if (val != NULL) {  
					NSString *patientsSex =  [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
					[dicomElements setObject:patientsSex forKey:@"patientSex"];
					//NSLog(@"Patient's Sex %@", patientsSex);
				}
				
				// free the module and the associated sequences
				theErr = Papy3GroupFree (&theGroupP, TRUE);
		   }
		   else
		   {
				name = [[NSString alloc] initWithString:@"No name"];
		   }
		   
		  // if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
		   
			theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0018);
			if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
			{
				val = Papy3GetElement (theGroupP, papScanOptionsGr, &nbVal, &itemType);
				if (val != NULL)
				{
					if( strlen( val->a) >= 4)
					{
						if( val->a[ 0] == 'T' && val->a[ 1] == 'P')
						{
							if( val->a[ 2] >= '0' && val->a[ 2] <= '9')
							{
								if( val->a[ 3] >= '0' && val->a[ 3] <= '9')
								{
									cardiacTime = (val->a[ 2] - '0')*10;
									cardiacTime += val->a[ 3] - '0';
								}
								else
								{
									cardiacTime = val->a[ 2] - '0';
								}
							}
						}
					}
				}
				[dicomElements setObject:[NSNumber numberWithLong: cardiacTime] forKey:@"cardiacTime"];
				
				val = Papy3GetElement (theGroupP, papProtocolNameGr, &nbVal, &itemType);
				if (val != NULL) [dicomElements setObject:[[[NSString alloc] initWithCString:val->a encoding: encoding] autorelease] forKey:@"protocolName"];
				
				//Get TE for Dual Echo and multiecho MRI sequences
				
				val = Papy3GetElement (theGroupP, papEchoTimeGr, &nbVal, &itemType);
				if (val != NULL) echoTime = [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
				
				theErr = Papy3GroupFree (&theGroupP, TRUE);
			}
			
			//if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
			
		   // get the General Image module
		   theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0020);
		   if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		   {
				val = Papy3GetElement (theGroupP, papImageNumberGr, &nbVal, &itemType);
				if (val != NULL)
				{
					imageID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
					int val = [imageID intValue];
					[imageID release];
					imageID = [[NSString alloc] initWithFormat:@"%5d", val];
				}
				else imageID = 0L;
				
				// Compute slice location
				
				float		orientation[ 9];
				float		origin[ 3];
				float		location = 0;
				UValue_T    *tmp;
				
				origin[0] = origin[1] = origin[2] = 0;
				
				val = Papy3GetElement (theGroupP, papImagePositionPatientGr, &nbVal, &itemType);
				if (val != NULL)
				{
					tmp = val;
					
					origin[0] = [[NSString stringWithCString:tmp->a] floatValue];
					
					if( nbVal > 1)
					{
						tmp++;
						origin[1] = [[NSString stringWithCString:tmp->a] floatValue];
					}
					
					if( nbVal > 2)
					{
						tmp++;
						origin[2] = [[NSString stringWithCString:tmp->a] floatValue];
					}
				}
				
				orientation[ 0] = 1;	orientation[ 1] = 0;		orientation[ 2] = 0;
				orientation[ 3] = 0;	orientation[ 4] = 1;		orientation[ 5] = 0;
				
				val = Papy3GetElement (theGroupP, papImageOrientationPatientGr, &nbVal, &itemType);
				if (val != NULL)
				{
					long j;
					tmp = val;
					if( nbVal != 6) { nbVal = 6;		NSLog(@"Orientation is NOT 6 !!!");}
					for (j = 0; j < nbVal; j++)
					{
						orientation[ j]  = [[NSString stringWithCString:tmp->a] floatValue];
						tmp++;
					}
				}
				
				// Compute normal vector
				orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
				orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
				orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
				
				if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8])) location = origin[ 0];
				if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8])) location = origin[ 1];
				if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7])) location = origin[ 2];
				
				[dicomElements setObject:[NSNumber numberWithFloat: location] forKey:@"sliceLocation"];
				
				if( imageID == 0L || [imageID intValue] >= 99999)
				{
					int val = 10000 + location*10.;
					imageID = [[NSString alloc] initWithFormat:@"%5d", val];
				}
				[dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];

				
//				val = Papy3GetElement (theGroupP, papSliceLocationGr, &nbVal, &itemType);
//				if (val != NULL)
//				{
//					sliceLocation = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
//					int val = ([sliceLocation floatValue]) * 100.;
//					[sliceLocation release];
//					sliceLocation = [[NSString alloc] initWithFormat:@"%7d", val];
//				}
//				else sliceLocation = [[NSString alloc] initWithFormat:@"%7d", 1];
				
				seriesNo = 0L;
				val = Papy3GetElement (theGroupP, papSeriesNumberGr, &nbVal, &itemType);
				if (val != NULL)
				{
					seriesNo = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
				}
				else seriesNo = [[NSString alloc] initWithString: @"0"];
				
				if( seriesNo) [dicomElements setObject:[NSNumber numberWithInt:[seriesNo intValue]]  forKey:@"seriesNumber"];
				
				val = Papy3GetElement (theGroupP, papSeriesInstanceUIDGr, &nbVal, &itemType);
				if( val != NULL) [dicomElements setObject:[NSString stringWithCString:val->a] forKey:@"seriesDICOMUID"];
				
				if (val != NULL) serieID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
				else serieID = [[NSString alloc] initWithString:name];
				
				// *********** WARNING : SERIESID MUST BE IDENTICAL BETWEEN DCMFRAMEWORK & PAPYRUS TOOLKIT !!!!! OTHERWISE muliple identical series will be created during DATABASE rebuild !
				
				if( cardiacTime != -1 && SEPARATECARDIAC4D == YES)  // For new Cardiac-CT Siemens series
				{
					NSString	*n;
					
					n = [[NSString alloc] initWithFormat:@"%@ %2.2d", serieID , cardiacTime];
					[serieID release];
					serieID = n;
				}
				
				if( seriesNo)
				{
					NSString	*n;
					
					n = [[NSString alloc] initWithFormat:@"%8.8d %@", [seriesNo intValue] , serieID];
					[serieID release];
					serieID = n;
				}
				
				if( imageType != 0 && useSeriesDescription)
				{
					NSString	*n;
					
					n = [[NSString alloc] initWithFormat:@"%@ %@", serieID , imageType];
					[serieID release];
					serieID = n;
				}
				
				if( serie != 0L && useSeriesDescription)
				{
					NSString	*n;
					
					n = [[NSString alloc] initWithFormat:@"%@ %@", serieID , serie];
					[serieID release];
					serieID = n;
				}
				
				//Segregate by TE  values
				if( echoTime != nil && splitMultiEchoMR)
				{
					NSString	*n;
					
					n = [[NSString alloc] initWithFormat:@"%@ TE-%@", serieID , echoTime];
					[serieID release];
					serieID = n;
				}
				
			   if( NOLOCALIZER && [self containsString: @"LOCALIZER" inArray: imageTypeArray])
			   {
				   NSString	*n;
				   
				   n = [[NSString alloc] initWithString: @"LOCALIZER"];
				   [serieID release];
				   serieID = n;
				   
				   [serie release];
				   serie = [[NSString alloc] initWithString: @"Localizers"];
				   [dicomElements setObject:serie forKey:@"seriesDescription"];
			   }
			   
				val = Papy3GetElement (theGroupP, papStudyInstanceUIDGr, &nbVal, &itemType);
				if (val != NULL) studyID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
				else
				{
					studyID = [[NSString alloc] initWithString:name];
				}
				[dicomElements setObject:studyID forKey:@"studyID"];
				
				val = Papy3GetElement (theGroupP, papStudyIDGr, &nbVal, &itemType);
				if (val != NULL) studyIDs = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
				else studyIDs = [[NSString alloc] initWithString:@"0"];
				
				if( studyIDs) [dicomElements setObject:studyIDs forKey:@"studyNumber"];
				
				// free the module and the associated sequences 
				theErr = Papy3GroupFree (&theGroupP, TRUE);
		   }
		   
		  // if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
		   
			theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0028);
		   if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		   {
				long realwidth;
				
				// ROWS
				val = Papy3GetElement (theGroupP, papRowsGr, &nbVal, &itemType);
				if (val != NULL)
				{
					height = (int) (*val).us;
					height /=2;
					height *=2;
				}
				// COLUMNS
				val = Papy3GetElement (theGroupP, papColumnsGr, &nbVal, &itemType);
				if (val != NULL) 
				{
					realwidth = (int) (*val).us;
					width = realwidth/2;
					width *=2;
				}
				theErr = Papy3GroupFree (&theGroupP, TRUE);
			}
			
			NoOfFrames = gArrNbImages [fileNb];
			NoOfSeries = 1;
			
			if( patientID == 0L) patientID = [[NSString alloc] initWithString:@""];
		}
		/*
		// Go to groups 0s0042 for Encapsulated Document Possible PDF
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0042);
		if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			val = Papy3GetElement (theGroupP, 0x0011, &nbVal, &itemType);
			if (val != NULL) {
				NSLog(@"Encapsulated PDF decode with Papyrus");
			}
		}
		*/
		[PapyrusLock lock];
		
		// close and free the file and the associated allocated memory 
		Papy3FileClose (fileNb, TRUE);
		
		[PapyrusLock unlock];
		
		if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
		{
			NSString *newSerieID = [[NSString alloc] initWithFormat:@"%@-%@-%@", serieID, imageID, [dicomElements objectForKey:@"SOPUID"]];
			[serieID release];
			serieID = newSerieID;
		}
		
//		if (NOLOCALIZER)
//		{
//			NSRange range = [serie rangeOfString:@"localizer" options:NSCaseInsensitiveSearch];
//			if( range.location != NSNotFound)
//			{
//				return -1;
//			}
//		}
		
		[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
		
		if( serieID == 0L) serieID = [[NSString alloc] initWithString:name];
		
		if( [Modality isEqualToString:@"US"] && oneFileOnSeriesForUS)
		{
			[dicomElements setObject: [serieID stringByAppendingString: [filePath lastPathComponent]] forKey:@"seriesID"];
		}
		else if (([Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]) && combineProjectionSeries)
		{
			if( combineProjectionSeriesMode == 0)		// *******Combine all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject:studyID forKey:@"seriesID"];
				[dicomElements setObject:[NSNumber numberWithLong: [serieID intValue] * 1000 + [imageID intValue]] forKey:@"imageID"];
			}
			else if( combineProjectionSeriesMode == 1)	// *******Split all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject: [serieID stringByAppendingString: imageID] forKey:@"seriesID"];
			}
			else NSLog( @"ARG! ERROR !? Unknown combineProjectionSeriesMode");
		}
		else
			[dicomElements setObject:serieID forKey:@"seriesID"];

		if( studyID == 0L)
		{
			studyID = [[NSString alloc] initWithString:name];
			[dicomElements setObject:studyID forKey:@"studyID"];
		}
		
		if( imageID == 0L)
		{
			imageID = [[NSString alloc] initWithString:name];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
		}
	
		if( date == 0L)
		{
			date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:0L] retain];
			[dicomElements setObject:date forKey:@"studyDate"];
		}
		
		[dicomElements setObject:[NSNumber numberWithBool:YES] forKey:@"hasDICOM"];
		
		//NSLog(@"DicomElements:  %@ %@" ,NSStringFromClass([dicomElements class]) ,[dicomElements description]);
		
		if( name != 0L && studyID != 0L && serieID != 0L && imageID != 0L && width != 0 && height != 0)
		{
			return 0;   // success
		}
	}
	
	if ([sopClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]]) return [self getDicomFileDCMTK];
	
	if( converted)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:converted])
		{
			[[NSFileManager defaultManager] removeFileAtPath:converted handler: 0L];
		}
	}
	else
	{
		if( forceConverted == NO)
		{
			return [self getDicomFilePapyrus: YES];
		}
	}
	
	

	
	return -1;			// failed
}

-(short) getDicomFile
{
	BOOL isCD = NO;
	
	if( PREFERPAPYRUSFORCD)
		isCD = filesAreFromCDMedia;

	if( TOOLKITPARSER == 1 || isCD == YES) return [self getDicomFilePapyrus: NO];
	if( TOOLKITPARSER == 0) return [self decodeDICOMFileWithDCMFramework];
	if( TOOLKITPARSER == 2) return [self getDicomFileDCMTK];
	
	return [self getDicomFileDCMTK];
}

-(short) decodeDICOMFileWithDCMFramework
{
	BOOL returnValue = -1;
	long cardiacTime = -1;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DCMObject *dcmObject;
	
	if (COMMENTSAUTOFILL == YES || CHECKFORLAVIM == YES)
		dcmObject = [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];
	else
		dcmObject = [DCMObjectDBImport objectWithContentsOfFile:filePath decodingPixelData:NO];
	   
	if (dcmObject) {

		if (COMMENTSAUTOFILL == YES || CHECKFORLAVIM == YES)
		{
			if( COMMENTSAUTOFILL)
			{
				id			commentsField;
				NSString	*grel = [NSString stringWithFormat:@"%04X,%04X", COMMENTSGROUP, COMMENTSELEMENT];
				
				if (commentsField = [dcmObject attributeValueForKey: grel])
				{
					if( [commentsField isKindOfClass: [NSString class]])
						[dicomElements setObject:commentsField forKey:@"commentsAutoFill"];
					
					if( [commentsField isKindOfClass: [NSNumber class]])
						[dicomElements setObject:[commentsField stringValue] forKey:@"commentsAutoFill"];
						
					if( [commentsField isKindOfClass: [NSCalendarDate class]])
						[dicomElements setObject:[commentsField description] forKey:@"commentsAutoFill"];
				}
			}
			
			////////// **** HUG SPECIFIC CODE - DO NOT REMOVE THANKS ! Antoine Rosset
			
			if( CHECKFORLAVIM)
			{
				//Le nom de l'Žtude peut se trouver dans plusieurs champs DICOM, suivant la modalitŽ de l'examen.
				//IRM :	0x0040:0x0280
				//CT Philips :	0x0040:0x1400
				//CT GE :	Pas encore dŽfini
				//Autres modalitŽs :	A dŽfinir.
				NSString			*field = 0L, *album = 0L;
				
				field = [dcmObject attributeValueForKey: @"0020,4000"];
				if( field)
				{
					if( [field length] >= 2)
						if( [[field substringToIndex:2] isEqualToString: @"LV"])
							album = [field substringFromIndex:2];
				}
				
				field = [dcmObject attributeValueForKey: @"0040,0280"];
				if( field)
				{
					if( [field length] >= 2)
						if( [[field substringToIndex:2] isEqualToString: @"LV"])
							album = [field substringFromIndex:2];
				}
				
				field = [dcmObject attributeValueForKey: @"0040,1400"];
				if( field)
				{
					if( [field length] >= 2)
						if( [[field substringToIndex:2] isEqualToString: @"LV"])
							album = [field substringFromIndex:2];
				}
				
				if( album) [dicomElements setObject:album forKey:@"album"];
			}
		}
		NSString *transferSyntaxUID = [dcmObject attributeValueWithName:@"TransferSyntaxUID"];
		if( [transferSyntaxUID isEqualToString:@"1.2.840.10008.1.2.4.100"])
		{
			fileType = [[NSString stringWithString:@"DICOMMPEG2"] retain];
			[dicomElements setObject:fileType forKey:@"fileType"];
		}
		else
		{
			fileType = [[NSString stringWithString:@"DICOM"] retain];
			[dicomElements setObject:fileType forKey:@"fileType"];
		}
		
		NSMutableArray	*imageTypeArray = [NSMutableArray arrayWithArray: [dcmObject attributeArrayWithName:@"ImageType"]];
		if( [imageTypeArray count] > 2)
		{
			if (imageType = [[[dcmObject attributeArrayWithName:@"ImageType"] objectAtIndex: 2] retain]) //ImageType		
				[dicomElements setObject:imageType forKey:@"imageType"];
		}
			
		if (SOPUID =[[dcmObject attributeValueForKey:@"0008,0018"] retain])	//SOPInstanceUID {
			[dicomElements setObject:SOPUID forKey:@"SOPUID"];
			
		if (study = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"StudyDescription"]] retain])
			[dicomElements setObject:study forKey:@"studyDescription"];
		else {
			study = [[NSString stringWithString:@"unnamed"] retain];
			[dicomElements setObject:study forKey:@"studyDescription"];
		}
		
		if (Modality = [[dcmObject attributeValueWithName:@"Modality"] retain])
			[dicomElements setObject:Modality forKey:@"modality"];
		else {
			Modality = [@"OT" retain];
			[dicomElements setObject:Modality forKey:@"modality"];
		}
			
		NSString *studyDate = [[dcmObject attributeValueWithName:@"StudyDate"] dateString];
		NSString *studyTime = [[dcmObject attributeValueWithName:@"StudyTime"] timeString];
		NSString *seriesDate = [[dcmObject attributeValueWithName:@"SeriesDate"] dateString];
		NSString *seriesTime = [[dcmObject attributeValueWithName:@"SeriesTime"] timeString];
		NSString *acqDate = [[dcmObject attributeValueWithName:@"AcquisitionDate"] dateString];
		NSString *acqTime = [[dcmObject attributeValueWithName:@"AcquisitionTime"] timeString];
		NSString *contDate = [[dcmObject attributeValueWithName:@"ContentDate"] dateString];
		NSString *contTime = [[dcmObject attributeValueWithName:@"ContentTime"] timeString];
		
		//NSString *date;
		if (contDate && contTime)
		{
			if( [contTime length] == 6)
				date = [[NSCalendarDate alloc] initWithString:[contDate stringByAppendingString:contTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[contDate stringByAppendingString:contTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else if (acqDate && acqTime)
		{
			if( [acqTime length] == 6)
				date = [[NSCalendarDate alloc] initWithString:[acqDate stringByAppendingString:acqTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[acqDate stringByAppendingString:acqTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else if (seriesDate && seriesTime)
		{
			if( [seriesTime length] == 6)
				date = [[NSCalendarDate alloc] initWithString:[seriesDate stringByAppendingString:seriesTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[seriesDate stringByAppendingString:seriesTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else if (studyDate && studyTime)
		{
			if( [studyTime length] == 6)
				date = [[NSCalendarDate alloc] initWithString:[studyDate stringByAppendingString:studyTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[studyDate stringByAppendingString:studyTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else
		{
			date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:0L] retain];
		}
		
		[dicomElements setObject:date forKey:@"studyDate"];
		
		//JF20070103 if series title doesn't exist, replace it by series number, and the latter doesn't exist, keep unnamed
		BOOL modalityNoSC = TRUE; //JF20070103
		if ([[dcmObject attributeValueForKey:@"0008,0018"] isEqualToString:@"1.2.840.10008.5.1.4.1.1.7"] == YES) modalityNoSC=FALSE; //JF20070103
		if (serie = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"SeriesDescription"]] retain])
			[dicomElements setObject:serie forKey:@"seriesDescription"];
		else if ((serie = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"instanceNumber"]] retain]) && modalityNoSC)
			[dicomElements setObject:serie forKey:@"seriesDescription"]; //JF20070103
		else if (!modalityNoSC) serie = [@"unnamed" retain]; //JF20070103 		
		else {
			serie = [@"unnamed" retain];
			[dicomElements setObject:serie forKey:@"seriesDescription"];
		}
			
		if ([dcmObject attributeValueWithName:@"InstitutionName"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"InstitutionName"] forKey:@"institutionName"];
			
		if ([dcmObject attributeValueWithName:@"ReferringPhysiciansName"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"ReferringPhysiciansName"] forKey:@"referringPhysiciansName"];
			
		if ([dcmObject attributeValueWithName:@"PerformingPhysiciansName"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PerformingPhysiciansName"] forKey:@"performingPhysiciansName"];
			
		if ([dcmObject attributeValueWithName:@"AccessionNumber"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"AccessionNumber"] forKey:@"accessionNumber"];
			
		if (name = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"PatientsName"]] retain])
			[dicomElements setObject:name forKey:@"patientName"];
		else {
			name = [@"No name" retain];
			[dicomElements setObject:name forKey:@"patientName"];
		}
			
		if (patientID = [[dcmObject attributeValueWithName:@"PatientID"] retain])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PatientID"] forKey:@"patientID"];
		else {
			patientID = [@"" retain];
			[dicomElements setObject:patientID forKey:@"patientID"];
		}
			
		if ([dcmObject attributeValueWithName:@"PatientsAge"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PatientsAge"] forKey:@"patientAge"];
			
		if ([dcmObject attributeValueWithName:@"PatientsBirthDate"])
			[dicomElements setObject:(NSDate *)[dcmObject attributeValueWithName:@"PatientsBirthDate"] forKey:@"patientBirthDate"];
			
		if ([dcmObject attributeValueWithName:@"PatientsSex"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PatientsSex"] forKey:@"patientSex"];
			
		if ([dcmObject attributeValueWithName:@"ScanOptions"]){
			NSString *scanOptions = [dcmObject attributeValueWithName:@"ScanOptions"];
			if ([scanOptions length] >= 4 && [scanOptions hasPrefix:@"TP"]){
				NSString *cardiacString = [scanOptions substringWithRange:NSMakeRange(2,2)];
				cardiacTime = [cardiacString intValue];	
				[dicomElements setObject:[NSNumber numberWithLong: cardiacTime] forKey:@"cardiacTime"];			
			}
		}
		
		if ([dcmObject attributeValueWithName:@"ProtocolName"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"ProtocolName"] forKey:@"protocolName"];
		/*	
		if ([dcmObject attributeValueWithName:@"ProtocolName"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"ProtocolName"] forKey:@"protocolName"];
		*/	
		NSString *instanceNumber;
//		NSLog(@"get Instance Number");
		if (imageID = [dcmObject attributeValueWithName:@"InstanceNumber"])
		{
			int val = [imageID intValue];
			imageID = [[NSString alloc] initWithFormat:@"%5d", val];		
		}
		else
			imageID = 0;
				
		// Compute slice location
		float		orientation[ 9];
		float		origin[ 3];
		float		location = 0;
		
		origin[0] = origin[1] = origin[2] = 0;
		
		NSArray *ipp = [dcmObject attributeArrayWithName:@"ImagePositionPatient"];
		if( ipp)
		{
			origin[0] = [[ipp objectAtIndex:0] floatValue];
			origin[1] = [[ipp objectAtIndex:1] floatValue];
			origin[2] = [[ipp objectAtIndex:2] floatValue];
		}
		
		orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
		orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
		NSArray *iop = [dcmObject attributeArrayWithName:@"ImageOrientationPatient"];
		if( iop)
		{
			long j;
			
			for (j = 0 ; j < [iop count]; j++) 
				orientation[ j] = [[iop objectAtIndex:j] floatValue];
		}

		// Compute normal vector
		orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
		orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
		orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
		
		if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8])) location = origin[ 0];
		if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8])) location = origin[ 1];
		if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7])) location = origin[ 2];
		
		[dicomElements setObject:[NSNumber numberWithFloat: location] forKey:@"sliceLocation"];
		
		if( imageID == 0L || [imageID intValue] >= 99999)
		{
			int val = 10000 + location*10.;
			imageID = [[NSString alloc] initWithFormat:@"%5d", val];
		}
		[dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];
		
		// Series Number
		
		if (seriesNo = [[dcmObject attributeValueWithName:@"SeriesNumber"] retain]) {
		}
		else
			seriesNo = [[NSString alloc] initWithString: @"0"];
		[dicomElements setObject:[NSNumber numberWithInt:[seriesNo intValue]] forKey:@"seriesNumber"];
			
		if (serieID = [[dcmObject attributeValueWithName:@"SeriesInstanceUID"] retain])
		{
			[dicomElements setObject: serieID forKey:@"seriesDICOMUID"];
		}
			
		if (studyID = [[dcmObject attributeValueWithName:@"StudyInstanceUID"] retain])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"StudyInstanceUID"] forKey:@"studyID"];
			
		if (studyIDs = [[dcmObject attributeValueWithName:@"StudyID"] retain]) {
		}
		else 
			studyIDs = [@"0" retain];
		[dicomElements setObject:studyIDs forKey:@"studyNumber"];
		
		if ([dcmObject attributeValueWithName:@"NumberofFrames"])
			NoOfFrames = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
		else
			NoOfFrames = 1;
		
		if( [dcmObject attributeValueWithName:@"SOPClassUID"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"SOPClassUID"] forKey:@"SOPClassUID"];
		
		if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]]){
			NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
			NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData:pdfData];						
			NoOfFrames = [rep pageCount];							
		}
		
		// *********** WARNING : SERIESID MUST BE IDENTICAL BETWEEN DCMFRAMEWORK & PAPYRUS TOOLKIT !!!!! OTHERWISE muliple identical series will be created during DATABASE rebuild !
				
		if( cardiacTime != -1 && SEPARATECARDIAC4D == YES)  // For new Cardiac-CT Siemens series
		{
			NSString	*n;
			n = [[NSString alloc] initWithFormat:@"%@ %2.2d", serieID , cardiacTime];
			[serieID release];
			serieID = n;
		}
		if( seriesNo)
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%8.8d %@", [seriesNo intValue] , serieID];
			[serieID release];
			serieID = n;
		}
		
		if( imageType != 0 && useSeriesDescription)
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%@ %@", serieID , imageType];
			[serieID release];
			serieID = n;
		}
		
		if( serie != 0L && useSeriesDescription)
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%@ %@", serieID , serie];
			[serieID release];
			serieID = n;
		}
		
		if( NOLOCALIZER && [self containsString: @"LOCALIZER" inArray: imageTypeArray])
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithString: @"LOCALIZER"];
			[serieID release];
			serieID = n;
			
			[serie release];
			serie = [[NSString alloc] initWithString: @"Localizers"];
			[dicomElements setObject:serie forKey:@"seriesDescription"];
		}
		
		NSString *echoTime = nil;
		
		if ((echoTime = [dcmObject attributeValueWithName:@"EchoTime"])  && splitMultiEchoMR) 
		{
			NSString	*n;					
			n = [[NSString alloc] initWithFormat:@"%@ TE-%@", serieID, echoTime];
			[serieID release];
			serieID = n;
		}
		
		if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
		{
			NSString *newSerieID = [[NSString alloc] initWithFormat:@"%@-%@-%@", serieID, imageID, [dicomElements objectForKey:@"SOPUID"]];
			[serieID release];
			serieID = newSerieID;
		}
		
//		if (NOLOCALIZER)
//		{
//			NSRange range = [serie rangeOfString:@"localizer" options:NSCaseInsensitiveSearch];
//			if( range.location != NSNotFound)
//			{
//				return -1;
//			}
//		}

		if( serieID == 0L)  
			serieID = [[NSString alloc] initWithString:name];
		
		if( [Modality isEqualToString:@"US"] && oneFileOnSeriesForUS)
		{
			[dicomElements setObject: [serieID stringByAppendingString: [filePath lastPathComponent]] forKey:@"seriesID"];
		}
		else if (([Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]) &&  combineProjectionSeries)
		{
			if( combineProjectionSeriesMode == 0)		// *******Combine all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject:studyID forKey:@"seriesID"];
				[dicomElements setObject:[NSNumber numberWithLong: [serieID intValue] * 1000 + [imageID intValue]] forKey:@"imageID"];
			}
			else if( combineProjectionSeriesMode == 1)	// *******Split all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject: [serieID stringByAppendingString: imageID] forKey:@"seriesID"];
			}
			else NSLog( @"ARG! ERROR !? Unknown combineProjectionSeriesMode");
		}
		else
			[dicomElements setObject:serieID forKey:@"seriesID"];
		
		
		NoOfSeries = 1;
		
		[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
		[dicomElements setObject:[NSNumber numberWithBool:YES] forKey:@"hasDICOM"];
		
		returnValue = 0;
		
		width = [[dcmObject attributeValueWithName:@"Columns"] intValue];
		height= [[dcmObject attributeValueWithName:@"Rows"] intValue];
		if (width < 4)
			width = 4;
		if (height < 4)
			height = 4;
	}
	
	[pool release];
	

	
	return returnValue;
}

- (id) initRandom
{
	id returnVal = 0L;
//	NSLog(@"Init dicomFile: %d", DICOMOnly);
	if( self = [super init])
	{
		[DicomFile setDefaults];
		
		//width and height need to greater than 0 or get validation errors
		
		width = 1;
		height = 1;
		name = 0L;
		study = 0L;
		serie = 0L;
		date = 0L;
		Modality = 0L;
		filePath = [[NSString alloc] initWithFormat:@"protp/aksidkoa/saodkireks/ksidjaiskd/orkerofk%d", random()];
		SOPUID = 0L;
		fileType = 0L;
		NoOfSeries = 1;
		studyID = 0L;
		serieID = 0L;
		imageID = 0L;
		patientID = 0L;
		studyIDs = 0L;
		seriesNo = 0L;
		imageType = 0L;
		
		dicomElements = [[NSMutableDictionary dictionary] retain];
		
		if( [self getRandom] == 0)
		{
			returnVal = self;
		}
	}
	
	if( returnVal)
	{
		[dicomElements setObject:[NSNumber numberWithInt: height] forKey:@"height"];
		[dicomElements setObject:[NSNumber numberWithInt: width] forKey:@"width"];
		[dicomElements setObject:[NSNumber numberWithInt: NoOfFrames] forKey:@"numberOfFrames"];
		[dicomElements setObject:[NSNumber numberWithInt: NoOfSeries] forKey:@"numberOfSeries"];
	}
	
	return returnVal;
}

- (id) init:(NSString*) f DICOMOnly:(BOOL) DICOMOnly
{
	id returnVal = 0L;
//	NSLog(@"Init dicomFile: %d", DICOMOnly);
	if( self = [super init])
	{
		[DicomFile setDefaults];
		
		//width and height need to greater than 0 or get validation errors
		
		width = 1;
		height = 1;
		name = 0L;
		study = 0L;
		serie = 0L;
		date = 0L;
		Modality = 0L;
		filePath = f;
		SOPUID = 0L;
		fileType = 0L;
		NoOfSeries = 1;
		
		[filePath retain];
		
		studyID = 0L;
		serieID = 0L;
		imageID = 0L;
		patientID = 0L;
		studyIDs = 0L;
		seriesNo = 0L;
		imageType = 0L;
		
		dicomElements = [[NSMutableDictionary dictionary] retain];
		
		if( DICOMOnly)
		{
			if( [self getDicomFile] == 0)
			{
				returnVal = self;
			}
			else
			{
				[self release];
				
				returnVal = 0L;
			}
		}
		else
		{
			if( [self getFVTiffFile] == 0) // this needs to happen before getImageFile, since a FVTiff is a legal tiff and getImageFile will try to read it
			{
				returnVal = self;
			}
			else if( [self getImageFile] == 0)
			{
				returnVal = self;
			}
			else if ([self getPluginFile] == 0)
			{
				returnVal = self;
			}
			else if( [self getBioradPicFile] == 0)
			{
				returnVal = self;
			}
			else if( [self getAnalyze] == 0)
			{
				returnVal = self;
			}
			else if( [self getNIfTI] == 0)
			{
				returnVal = self;
			}
			else if( [self getLSM] == 0)
			{
				returnVal = self;
			}
			else if( [self getNRRDFile] == 0)
			{
				returnVal = self;
			}
			else if( [self getDicomFile] == 0)
			{
				returnVal = self;
			}
			else
			{
				[self release];
				
				returnVal = 0L;
			}
		}
	}
	
	if( returnVal)
	{
		[dicomElements setObject:[NSNumber numberWithInt: height] forKey:@"height"];
		[dicomElements setObject:[NSNumber numberWithInt: width] forKey:@"width"];
		[dicomElements setObject:[NSNumber numberWithInt: NoOfFrames] forKey:@"numberOfFrames"];
		[dicomElements setObject:[NSNumber numberWithInt: NoOfSeries] forKey:@"numberOfSeries"];
	}
	
	return returnVal;
}

- (id) init:(NSString*) f
{
	return [self init:f	DICOMOnly:NO];
}

- (void) dealloc
{
    [imageType release];
    [SOPUID release];
    [patientID release];
    [seriesNo release];

    [name release];
    [study release];
    [serie release];
    [date release];
    [filePath release];
    [studyID release];
	[studyIDs release];
    [serieID release];
    [imageID release];
    [Modality release];
	[dicomElements release];
	[fileType release];
	
    [super dealloc];
}

- (NSString*) patientUID
{
	NSString	*string = [NSString stringWithFormat:@"%@-%@-%@", [dicomElements valueForKey:@"patientName"], [dicomElements valueForKey:@"patientID"], [[NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[dicomElements valueForKey:@"patientBirthDate"] timeIntervalSinceReferenceDate]] descriptionWithCalendarFormat:@"%Y%m%d"]];
	//[[dicomElements valueForKey:@"patientBirthDate"] timeIntervalSinceReferenceDate]];
	
	return [[DicomFile NSreplaceBadCharacter: string] uppercaseString];
}

- (long) NoOfFrames { return NoOfFrames;}

- (NSMutableDictionary *)dicomElements {
	return dicomElements;
}

- (id)elementForKey:(id)key{
	return [dicomElements objectForKey:key];
}

- (short)getPluginFile{
	NSString	*extension = [[filePath pathExtension] lowercaseString];	
	NoOfFrames = 1;	
	
	id fileFormatBundle;
	#ifdef OSIRIX_VIEWER
	if (fileFormatBundle = [[PluginManager fileFormatPlugins] objectForKey:extension])
	{
		fileType = [[NSString stringWithString:@"IMAGE"] retain];
		
		PluginFileFormatDecoder *decoder = [[[fileFormatBundle principalClass] alloc] init];
		float *fImage = [decoder checkLoadAtPath:filePath];
		width = [[decoder width] floatValue];
		height = [[decoder height] floatValue];
		[self extractSeriesStudyImageNumbersFromFileName:[[filePath lastPathComponent] stringByDeletingPathExtension]];
		
		if ([decoder patientName] != nil) {
			name = [[decoder patientName] retain];
		}
		else 
			name = [[NSString alloc] initWithString:[filePath lastPathComponent]];

		
		if ([decoder patientID])
			patientID = [[decoder patientID] retain];
		else			
			patientID = [[NSString alloc] initWithString:name];
			
		if ([decoder studyDescription])
			study = [[decoder studyDescription] retain];
		else
			study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			
		Modality = [[NSString alloc] initWithString:extension];
		date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
		

		if ([decoder seriesDescription])
			serie = [[decoder seriesDescription] retain];
		else
			serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];

		if ([decoder studyID])
			[dicomElements setObject:[decoder studyID] forKey:@"studyID"];
		else 
			[dicomElements setObject:studyID forKey:@"studyID"];
		NSLog(@"studyID ; %@", studyID);
		if ([decoder studyDescription])
			[dicomElements setObject:[decoder studyDescription]forKey:@"studyDescription"];
		else
			[dicomElements setObject:study forKey:@"studyDescription"];
			
			
		[dicomElements setObject:date forKey:@"studyDate"];
		[dicomElements setObject:Modality forKey:@"modality"];

		if ([decoder patientID])
			[dicomElements setObject:[decoder patientID] forKey:@"patientID"];
		else	
			[dicomElements setObject:patientID forKey:@"patientID"];

		if ([decoder patientName])
			[dicomElements setObject:[decoder patientName] forKey:@"patientName"];
		else	
			[dicomElements setObject:name forKey:@"patientName"];
			
		[dicomElements setObject:[self patientUID] forKey:@"patientUID"];

		if ([decoder seriesID])
			[dicomElements setObject:[decoder seriesID] forKey:@"seriesID"];
		else
			[dicomElements setObject:serieID forKey:@"seriesID"];

		if ([decoder seriesDescription])
			[dicomElements setObject:[decoder seriesDescription] forKey:@"seriesDescription"];
		else
			[dicomElements setObject:name forKey:@"seriesDescription"];

		[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
		[dicomElements setObject:imageID forKey:@"SOPUID"];
		[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
		[dicomElements setObject:fileType forKey:@"fileType"];
		
		[decoder release];
		free(fImage);
		return 0;				
	}
	#endif
	
	return -1;
}

- (void)extractSeriesStudyImageNumbersFromFileName:(NSString *)tempString{
// Try to identify a 2 digit number in the last part of the file.
				char				strNo[ 5];
	if( [tempString length] >= 4) strNo[ 0] = [tempString characterAtIndex: [tempString length] -4];	else strNo[ 0]= 0;
	if( [tempString length] >= 3) strNo[ 1] = [tempString characterAtIndex: [tempString length] -3];	else strNo[ 1]= 0;
	if( [tempString length] >= 2) strNo[ 2] = [tempString characterAtIndex: [tempString length] -2];	else strNo[ 2]= 0;
	if( [tempString length] >= 1) strNo[ 3] = [tempString characterAtIndex: [tempString length] -1];	else strNo[ 3]= 0;
		strNo[ 4] = 0;
		
	if( strNo[ 0] >= '0' && strNo[ 0] <= '9' && strNo[ 1] >= '0' && strNo[ 1] <= '9' && strNo[ 2] >= '0' && strNo[ 2] <= '9'  && strNo[ 3] >= '0' && strNo[ 3] <= '9')
		{
			// We HAVE a number with 4 digit at the end of the file!! Make a serie of it!
			
			imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
			serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -4]];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -4]];
	}
	else if( strNo[ 1] >= '0' && strNo[ 1] <= '9' && strNo[ 2] >= '0' && strNo[ 2] <= '9' && strNo[ 3] >= '0' && strNo[ 3] <= '9')
	{
			// We HAVE a number with 3 digit at the end of the file!! Make a serie of it!
			
			strNo[0] = strNo[ 1];
			strNo[1] = strNo[ 2];
			strNo[2] = strNo[ 3];
			strNo[3] = 0;
			
			imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
			serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -3]];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -3]];
	}
	else if( strNo[ 2] >= '0' && strNo[ 2] <= '9' && strNo[ 3] >= '0' && strNo[ 3] <= '9')
	{
			// We HAVE a number with 2 digit at the end of the file!! Make a serie of it!
			strNo[0] = strNo[ 2];
			strNo[1] = strNo[ 3];
			strNo[2] = 0;
			
			imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
			serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -2]];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -2]];
	}
	else if( strNo[ 3] >= '0' && strNo[ 3] <= '9')
	{
			// We HAVE a number with 1 digit at the end of the file!! Make a serie of it!
			strNo[0] = strNo[ 3];
			strNo[1] = 0;
			
			imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
			serieID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -1]];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -1]];
	}
	else
	{
			studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			serieID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	}

}

// fake DICOM for other files with XML descriptor

- (id) initWithXMLDescriptor: (NSString*)pathToXMLDescriptor path:(NSString*) f
{
	if( self = [super init])
	{	
		// XML Data
		NSLog(@"pathToXMLDescriptor : %@", pathToXMLDescriptor);
		NSLog(@"f : %@", f);	
		CFURLRef sourceURL;
//		sourceURL = CFURLCreateWithString (	NULL, // allocator 
//											(CFStringRef) urlToXMLDescriptor, // url string 
//											NULL); // base url
											
		sourceURL = CFURLCreateFromFileSystemRepresentation (	NULL, // allocator 
																(unsigned char*) [pathToXMLDescriptor UTF8String], // string buffer
																[pathToXMLDescriptor length],	// buffer length
																FALSE); // is directory
		NSLog(@"sourceURL : %@", sourceURL);

		BOOL result;
		SInt32 errorCode;
		CFDataRef xmlData;
		//NSLog(@"xmlData");
		result = CFURLCreateDataAndPropertiesFromResource (	NULL, // allocator 
															sourceURL, &xmlData,
															NULL, NULL, // properties 
															&errorCode);
		//NSLog(@"xmlData: %@", xmlData);
		//NSLog(@"errorCode: %d", errorCode);
		if (errorCode==0)
		{
			//NSLog(@"cfXMLTree");
			CFTreeRef cfXMLTree;
			cfXMLTree = CFXMLTreeCreateFromData (	kCFAllocatorDefault,
													xmlData,
													NULL, // datasource 
													kCFXMLParserSkipWhitespace,
													kCFXMLNodeCurrentVersion);
			
			//NSLog(@"cfXMLTree : %@", cfXMLTree);
			//NSLog(@"[curFile dicomElements]");
			dicomElements = [[NSMutableDictionary dictionary] retain];

			//NSLog(@"dicomElements : %@", dicomElements);
			
			// 
			CFTreeRef attributesTree, child;
			CFXMLNodeRef node;
			CFStringRef nodeName, nodeValue;
			attributesTree = CFTreeGetChildAtIndex(cfXMLTree, 0);
			//NSLog(@"attributesTree: %@", attributesTree);

			int i;
			// NSMutableDictionary* xmlData = [[NSMutableDictionary alloc] initWithCapacity:14];
			NSMutableDictionary* xmlData = [NSMutableDictionary dictionaryWithContentsOfFile:pathToXMLDescriptor];
			
//			for(i=0; i<14; i++)
//			{
//				CFTreeRef childProjectName = CFTreeGetChildAtIndex(attributesTree, i);
//				node = CFXMLTreeGetNode(childProjectName);
//				nodeName = CFXMLNodeGetString(node);
//				child = CFTreeGetChildAtIndex(childProjectName, 0);
//				node = CFXMLTreeGetNode(child);
//				nodeValue = CFXMLNodeGetString(node);
//				[xmlData setObject:nodeValue forKey:nodeName];
//				//NSLog(@"nodeName : %@", nodeName);
//				//NSLog(@"nodeValue : %@", nodeValue);
//			}
		
			width = 4;
			height = 4;
			name = [[xmlData objectForKey:@"patientName"] retain];
			study = [[xmlData objectForKey:@"studyDescription"] retain];
			serie = [[NSString alloc] initWithString:[f lastPathComponent]];
			date = [[NSDate dateWithString:[xmlData objectForKey:@"studyDate"]] retain];
			Modality = [[xmlData objectForKey:@"modality"] retain];
			filePath = [f retain];
			fileType = [[NSString stringWithString:@"XMLDESCRIPTOR"] retain];
			NoOfSeries = 1;
			NoOfFrames = [[xmlData objectForKey:@"numberOfImages"] intValue];
			
			studyID = [[xmlData objectForKey:@"studyID"] retain];
			serieID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			SOPUID = [imageID retain];
			patientID = [[xmlData objectForKey:@"patientID"] retain];
			studyIDs = [studyID retain];
			seriesNo = [[NSString alloc] initWithString:@"0"];
			imageType = 0L;
			
			[dicomElements setObject:[xmlData objectForKey:@"album"] forKey:@"album"];
			[dicomElements setObject:name forKey:@"patientName"];
			[dicomElements setObject:patientID forKey:@"patientID"];
			[dicomElements setObject:[xmlData objectForKey:@"accessionNumber"] forKey:@"accessionNumber"];
			[dicomElements setObject:study forKey:@"studyDescription"];
			[dicomElements setObject:Modality forKey:@"modality"];
			[dicomElements setObject:studyID forKey:@"studyID"];
			[dicomElements setObject:date forKey:@"studyDate"];
			[dicomElements setObject:[xmlData objectForKey:@"numberOfImages"] forKey:@"numberOfImages"];
			//[dicomElements setObject:[xmlData objectForKey:@"DATE_ADDED"] forKey:@""];
			[dicomElements setObject:[xmlData objectForKey:@"referringPhysiciansName"] forKey:@"referringPhysiciansName"];
			[dicomElements setObject:[xmlData objectForKey:@"performingPhysiciansName"] forKey:@"performingPhysiciansName"];
			[dicomElements setObject:[xmlData objectForKey:@"institutionName"] forKey:@"institutionName"];
			[dicomElements setObject:[NSDate dateWithString:[xmlData objectForKey:@"patientBirthDate"]] forKey:@"patientBirthDate"];
			
			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
			[dicomElements setObject:serieID forKey:@"seriesID"];
			[dicomElements setObject:[[NSString alloc] initWithString:[filePath lastPathComponent]] forKey:@"seriesDescription"];
			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];

			
			NSLog(@"dicomElements : %@", dicomElements);
		}
	}
	
	return self;
}

- (BOOL)autoFillComments{
	return COMMENTSAUTOFILL;
}

- (BOOL)useSeriesDescription{
	return useSeriesDescription;
}

- (BOOL)splitMultiEchoMR{
	return splitMultiEchoMR;
}

- (BOOL) noLocalizer{
	return NOLOCALIZER;
}

- (BOOL)oneFileOnSeriesForUS{
	return oneFileOnSeriesForUS;
}

- (BOOL)combineProjectionSeries{
	return combineProjectionSeries;
}

- (BOOL)combineProjectionSeriesMode{
	return combineProjectionSeriesMode;
}

- (BOOL)separateCardiac4D{
	return SEPARATECARDIAC4D;
}

- (BOOL)checkForLAVIM{
	return CHECKFORLAVIM;
}

- (int)commentsGroup {
	return COMMENTSGROUP;
}

- (int)commentsElement {
	return COMMENTSELEMENT;
}

@end
