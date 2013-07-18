/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#ifndef OSIRIX_LIGHT
#include "FVTiff.h"
#endif
#import "MutableArrayCategory.h"
#import "SRAnnotation.h"
#import "SRAnnotation.h"
#import <dicomFile.h>
#import "Papyrus3/Papyrus3.h"
#import "ViewerController.h"
#import "PluginFileFormatDecoder.h"
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCMSequenceAttribute.h>
#import "DCMObjectDBImport.h"
#import "DICOMToNSString.h"
#import "DefaultsOsiriX.h"
#ifndef OSIRIX_LIGHT
#include "tiffio.h"
#endif
#import "DicomFileDCMTKCategory.h"
#import "PluginManager.h"
#import "NSString+N2.h"
#import "N2Debug.h"
#include "NSFileManager+N2.h"

#import <AVFoundation/AVFoundation.h>

#ifndef DECOMPRESS_APP
#include "nifti1.h"
#include "nifti1_io.h"
#endif

#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
#import "DicomStudy.h"
#endif
#endif

extern NSString * convertDICOM( NSString *inputfile);
extern NSRecursiveLock *PapyrusLock;

static BOOL DEFAULTSSET = NO;
static int TOOLKITPARSER = NO, PREFERPAPYRUSFORCD = NO;
static BOOL COMMENTSAUTOFILL = NO, COMMENTSFROMDICOMFILES = NO;
static BOOL splitMultiEchoMR = NO;
static BOOL useSeriesDescription = NO;
static BOOL NOLOCALIZER = NO;
static BOOL combineProjectionSeries = NO, oneFileOnSeriesForUS = NO;
static int combineProjectionSeriesMode = NO;
//static int CHECKFORLAVIM = -1;
static int COMMENTSGROUP = NO, COMMENTSGROUP2 = NO, COMMENTSGROUP3 = NO, COMMENTSGROUP4 = NO;
static int COMMENTSELEMENT = NO, COMMENTSELEMENT2 = NO, COMMENTSELEMENT3 = NO, COMMENTSELEMENT4 = NO;
static BOOL gUsePatientIDForUID = YES, gUsePatientBirthDateForUID = YES, gUsePatientNameForUID = YES;
static BOOL SEPARATECARDIAC4D = NO;
//static BOOL SeparateCardiacMR = NO;
//static int SeparateCardiacMRMode = 0;
static BOOL filesAreFromCDMedia = NO;

#define QUICKTIMETIMEFRAMELIMIT 1200

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
@synthesize serieID;

- (BOOL) containsLocalizerInString: (NSString*) str
{
    if( str.length == 0)
        return NO;
    
	NSArray *stringsToFind = [[[NSUserDefaults standardUserDefaults] valueForKey: @"NOLOCALIZER_Strings"] componentsSeparatedByString:@","];
	
	for( NSString *localizerString in stringsToFind)
	{
		if( [localizerString hasPrefix: @" "])
			localizerString = [localizerString substringFromIndex: 1];
		
		if( [localizerString hasSuffix: @" "])
			localizerString = [localizerString substringToIndex: localizerString.length-2];
		
		if( [str rangeOfString: localizerString options: NSCaseInsensitiveSearch].location != NSNotFound)
			return YES;
	}
	
	return NO;
}

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
	if( str == nil) return nil;
	
	NSMutableString	*mutable = [NSMutableString stringWithString: str];
	
    [mutable replaceOccurrencesOfString:@"," withString:@" " options:0 range:mutable.range];
	[mutable replaceOccurrencesOfString:@"^" withString:@" " options:0 range:mutable.range]; 
	[mutable replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:mutable.range]; 
	[mutable replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:mutable.range]; 
	[mutable replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:mutable.range]; 
	[mutable replaceOccurrencesOfString:@"\"" withString:@"'" options:0 range:mutable.range];
    [mutable replaceOccurrencesOfString:@"   " withString:@" " options:0 range:mutable.range]; //tripple space -> single space
	[mutable replaceOccurrencesOfString:@"  " withString:@" " options:0 range:mutable.range]; //double space -> single space
    
	int i = [mutable length];
	while( --i > 0)
	{
		if( [mutable characterAtIndex: i]==' ') [mutable deleteCharactersInRange: NSMakeRange( i, 1)];
		else i = 0;
	}
	
	return mutable;
}

+ (NSString *) stringWithBytes:(char *) str encodings: (NSStringEncoding*) encoding
{
	return [DicomFile stringWithBytes: str encodings: encoding replaceBadCharacters: YES];
}

+ (BOOL) checkForEscapeCharacter: (char *) strValue size:(size_t) strLength
{
    BOOL result = NO;
    // iterate over the string of characters
    for (size_t pos = 0; pos < strLength; ++pos)
    {
        // and search for the first ESC character
        if (*strValue++ == '\033')
        {
            // then return with "true"
            result = YES;
            break;
        }
    }
    return result;
}

+ (NSString *) originalStringWithBytes:(char *) str encodings: (NSStringEncoding*) encoding replaceBadCharacters: (BOOL) replace
{
	if( str == nil) return nil;
    
	char c;
	int	i, from, len = strlen( str), index;
	NSMutableString	*result = [NSMutableString string];
	BOOL separators = NO;
    //	BOOL twoCharsEncoding = NO;
	
	for( i = 0, from = 0, index = 0; i < len; i++)
	{
		c = str[ i];
		
        //		if( encoding[ index] == NSISO2022JPStringEncoding || encoding[ index] == -2147483647)
        //			twoCharsEncoding = YES;
        //		else
        //			twoCharsEncoding = NO;
		
		BOOL separatorFound = NO;
		
        //		if( twoCharsEncoding)
        //		{
        //			if( c == 0x1b && str[ i+1] == '(')
        //				separatorFound = YES;
        //		}
        //		else
        //		{
        if( c == 0x1b)
            separatorFound = YES;
        //		}
		
		if( separatorFound || i == len-1)
		{
			if( separatorFound)
				separators = YES;
			
			if( i == len-1)
				i = len;
			
            if( i-from)
            {
                NSString *s = [[NSString alloc] initWithBytes: str+from length:i-from encoding: encoding[ index]];
                
                NSLog( @"%@ %d", s, (int) encoding[ index]);
                
                if( s)
                {
                    [result appendString: s];
                    
                    if( encoding[ index] == -2147481280)	// Korean support
                        [result replaceOccurrencesOfString:@"$)C" withString:@"" options:0 range:result.range];
                    
                    [s release];
                }
            }
			
			from = i;
			if( index < 9)
			{
				index++;
				if( encoding[ index] == 0)
					index--;
			}
		}
	}
	
//	if( separators)
//	{
//		[result replaceOccurrencesOfString: @"\x1b" withString: @"" options: 0 range:result.range];
//		[result replaceOccurrencesOfString: @"(B=)" withString: @"=" options: 0 range:result.range];
//		[result replaceOccurrencesOfString: @"(B" withString: @"" options: 0 range:result.range];
//	}
	
	if( replace)
		return [DicomFile NSreplaceBadCharacter: result];
	else
		return result;
}

// Based on dcmtk 3.6 convertString function

+ (NSString *) stringWithBytes:(char *) str encodings: (NSStringEncoding*) encodings replaceBadCharacters: (BOOL) replace
{
	if( str == nil) return nil;
    
    int fromLength = strlen( str);
    
	NSMutableString	*result = [NSMutableString string];
    BOOL checkPNDelimiters = YES;
    NSStringEncoding currentEncoding = encodings[ 0];
	int pos = 0;
    char *firstChar = str;
    char *currentChar = str;
    BOOL isFirstGroup = NO; // if delimiters contains '=' -> patient name
    int escLength = 0;
    
	while(pos < fromLength)
	{
		char c0 = *currentChar++;
        BOOL isEscape = (c0 == '\033');
        BOOL isDelimiter = (c0 == '\012') || (c0 == '\014') || (c0 == '\015') || (((c0 == '^') || (c0 == '=')) && (((c0 != '^') && (c0 != '=')) || checkPNDelimiters));
       
        if (isEscape || isDelimiter)
        {
            int convertLength = currentChar - firstChar - 1;
			
            if( convertLength - (escLength+1) >= 0)
            {
                NSString *s = nil;
                
                s = [[[NSString alloc] initWithBytes: firstChar length:convertLength encoding: currentEncoding] autorelease];
                
                if( s)
                    [result appendString: s];
            }
            
            // check whether this was the first component group of a PN value
            if (isDelimiter && (c0 == '='))
                isFirstGroup = NO;
        }
        
        if (isEscape)
        {
            // report a warning as this is a violation of DICOM PS 3.5 Section 6.2.1
            if (isFirstGroup)
            {
                NSLog( @"DcmSpecificCharacterSet: Escape sequences shall not be used in the first component group of a Person Name (PN), using them anyway)");
            }
            
            // we need at least two more characters to determine the new character set
            escLength = 2;
            if (pos + escLength < fromLength)
            {
                NSString *key = nil;
                char c1 = *currentChar++;
                char c2 = *currentChar++;
                char c3 = '\0';
                if ((c1 == 0x28) && (c2 == 0x42))       // ASCII
                    key = @"ISO 2022 IR 6";
                else if ((c1 == 0x2d) && (c2 == 0x41))  // Latin alphabet No. 1
                    key = @"ISO 2022 IR 100";
                else if ((c1 == 0x2d) && (c2 == 0x42))  // Latin alphabet No. 2
                    key = @"ISO 2022 IR 101";
                else if ((c1 == 0x2d) && (c2 == 0x43))  // Latin alphabet No. 3
                    key = @"ISO 2022 IR 109";
                else if ((c1 == 0x2d) && (c2 == 0x44))  // Latin alphabet No. 4
                    key = @"ISO 2022 IR 110";
                else if ((c1 == 0x2d) && (c2 == 0x4c))  // Cyrillic
                    key = @"ISO 2022 IR 144";
                else if ((c1 == 0x2d) && (c2 == 0x47))  // Arabic
                    key = @"ISO 2022 IR 127";
                else if ((c1 == 0x2d) && (c2 == 0x46))  // Greek
                    key = @"ISO 2022 IR 126";
                else if ((c1 == 0x2d) && (c2 == 0x48))  // Hebrew
                    key = @"ISO 2022 IR 138";
                else if ((c1 == 0x2d) && (c2 == 0x4d))  // Latin alphabet No. 5
                    key = @"ISO 2022 IR 148";
                else if ((c1 == 0x29) && (c2 == 0x49))  // Japanese
                    key = @"ISO 2022 IR 13";
                else if ((c1 == 0x28) && (c2 == 0x4a))  // Japanese - is this really correct?
                    key = @"ISO 2022 IR 13";
                else if ((c1 == 0x2d) && (c2 == 0x54))  // Thai
                    key = @"ISO 2022 IR 166";
                else if ((c1 == 0x24) && (c2 == 0x42))  // Japanese (multi-byte)
                    key = @"ISO 2022 IR 87";
                else if ((c1 == 0x24) && (c2 == 0x28))  // Japanese (multi-byte)
                {
                    escLength = 3;
                    // do we still have another character in the string?
                    if (pos + escLength < fromLength)
                    {
                        c3 = *currentChar++;
                        if (c3 == 0x44)
                            key = @"ISO 2022 IR 159";
                    }
                }
                else if ((c1 == 0x24) && (c2 == 0x29)) // Korean (multi-byte)
                {
                    escLength = 3;
                    // do we still have another character in the string?
                    if (pos + escLength < fromLength)
                    {
                        c3 = *currentChar++;
                        if (c3 == 0x43)                 // Korean (multi-byte)
                            key = @"ISO 2022 IR 149";
                        else if (c3 == 0x41)            // Simplified Chinese (multi-byte)
                            key = @"ISO 2022 IR 58";
                    }
                }
        
                if( key == nil)
                    NSLog( @"*** key == nil");
                else
                {
                    currentEncoding = [NSString encodingForDICOMCharacterSet: key];
                    
//                    BOOL found = NO;
//                    for( int x = 0; x < 10; x++)
//                    {
//                        if( currentEncoding == encodings[ x])
//                            found = YES;
//                    }
                    
//                    if( found == NO)
//                        NSLog( @"*** encoding not found in declared SpecificCharacterSet (0008,0005)");
                    
                    checkPNDelimiters = ([key isEqualToString: @"ISO 2022 IR 87"] == NO) && ([key isEqualToString: @"ISO 2022 IR 159"] == NO);
                    
                    if( checkPNDelimiters)
                        firstChar = currentChar;
                    else
                        firstChar = currentChar - (escLength+1);
                    
                }
                
                pos += escLength;
                
                if( checkPNDelimiters)
                    escLength = 0;
            }
            
            if(pos >= fromLength)
                NSLog( @"incomplete sequence");
        }
        else if (isDelimiter)
        {
            [result appendFormat: @"%c", c0];
            
            if (currentEncoding != encodings[ 0])
            {
                currentEncoding = encodings[ 0];
                checkPNDelimiters = YES;
            }
            firstChar = currentChar;
        }
        ++pos;
	}
	
    // convert any remaining characters from the input string
    {
        int convertLength = currentChar - firstChar;
        if (convertLength > 0)
        {
            int convertLength = currentChar - firstChar;
            
            if( firstChar + convertLength <= str + fromLength && ( convertLength - (escLength+1) >= 0))
            {
                NSString *s = [[[NSString alloc] initWithBytes: firstChar length:convertLength encoding: currentEncoding] autorelease];
            
                if( s)
                    [result appendString: s];
            }
        }
	}
    
	if( replace)
		return [DicomFile NSreplaceBadCharacter: result];
	else
		return result;
}

+ (char *) replaceBadCharacter:(char *) str encoding: (NSStringEncoding) encoding
{
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
		if( [[NSUserDefaults standardUserDefaults] objectForKey: @"TOOLKITPARSER4"])
		{
			NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
			
			DEFAULTSSET = YES;
			
			PREFERPAPYRUSFORCD = [sd integerForKey: @"PREFERPAPYRUSFORCD"];
			TOOLKITPARSER = [sd integerForKey: @"TOOLKITPARSER4"];
			
			#ifdef OSIRIX_LIGHT
			TOOLKITPARSER = 2;
			#endif
			
			COMMENTSFROMDICOMFILES = [sd boolForKey: @"CommentsFromDICOMFiles"];
			COMMENTSAUTOFILL = [sd boolForKey: @"COMMENTSAUTOFILL"];
			SEPARATECARDIAC4D = [sd boolForKey: @"SEPARATECARDIAC4D"];
//			SeparateCardiacMR = [sd boolForKey: @"SeparateCardiacMR"];
//			SeparateCardiacMRMode = [sd integerForKey: @"SeparateCardiacMRMode"];
			
			COMMENTSGROUP = [[sd objectForKey: @"COMMENTSGROUP"] intValue];
			COMMENTSELEMENT = [[sd objectForKey: @"COMMENTSELEMENT"] intValue];
            
            COMMENTSGROUP2 = [[sd objectForKey: @"COMMENTSGROUP2"] intValue];
			COMMENTSELEMENT2 = [[sd objectForKey: @"COMMENTSELEMENT2"] intValue];
			
            COMMENTSGROUP3 = [[sd objectForKey: @"COMMENTSGROUP3"] intValue];
			COMMENTSELEMENT3 = [[sd objectForKey: @"COMMENTSELEMENT3"] intValue];
            
            COMMENTSGROUP4 = [[sd objectForKey: @"COMMENTSGROUP4"] intValue];
			COMMENTSELEMENT4 = [[sd objectForKey: @"COMMENTSELEMENT4"] intValue];
			
			useSeriesDescription = [sd boolForKey: @"useSeriesDescription"];
			splitMultiEchoMR = [sd boolForKey: @"splitMultiEchoMR"];
			NOLOCALIZER = [sd boolForKey: @"NOLOCALIZER"];
			oneFileOnSeriesForUS = [sd boolForKey: @"oneFileOnSeriesForUS"];
			combineProjectionSeries = [sd boolForKey: @"combineProjectionSeries"];
			combineProjectionSeriesMode = [sd boolForKey: @"combineProjectionSeriesMode"];
			
            gUsePatientBirthDateForUID = [sd boolForKey: @"UsePatientBirthDateForUID"];
            gUsePatientIDForUID = [sd boolForKey: @"UsePatientIDForUID"];
            gUsePatientNameForUID = [sd boolForKey: @"UsePatientNameForUID"];
		}
		else	// FOR THE SAFEDBREBUILD ! Shell tool
		{
			NSMutableDictionary	*dict = [DefaultsOsiriX getDefaults];
			[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"]];
			
			DEFAULTSSET = YES;
			
			PREFERPAPYRUSFORCD = [[dict objectForKey: @"PREFERPAPYRUSFORCD"] intValue];
			TOOLKITPARSER = [[dict objectForKey: @"TOOLKITPARSER4"] intValue];
			
			COMMENTSFROMDICOMFILES = [[dict objectForKey: @"CommentsFromDICOMFiles"] intValue];
			COMMENTSAUTOFILL = [[dict objectForKey: @"COMMENTSAUTOFILL"] intValue];
			SEPARATECARDIAC4D = [[dict objectForKey: @"SEPARATECARDIAC4D"] intValue];
//			SeparateCardiacMR = [[dict objectForKey: @"SeparateCardiacMR"] intValue];
//			SeparateCardiacMRMode = [[dict objectForKey: @"SeparateCardiacMRMode"] intValue];
			
			COMMENTSGROUP = [[dict objectForKey: @"COMMENTSGROUP"] intValue];
			COMMENTSELEMENT = [[dict objectForKey: @"COMMENTSELEMENT"] intValue];
            
			COMMENTSGROUP2 = [[dict objectForKey: @"COMMENTSGROUP2"] intValue];
			COMMENTSELEMENT2 = [[dict objectForKey: @"COMMENTSELEMENT2"] intValue];
			
            COMMENTSGROUP3 = [[dict objectForKey: @"COMMENTSGROUP3"] intValue];
			COMMENTSELEMENT3 = [[dict objectForKey: @"COMMENTSELEMENT3"] intValue];
			
            COMMENTSGROUP4 = [[dict objectForKey: @"COMMENTSGROUP4"] intValue];
			COMMENTSELEMENT4 = [[dict objectForKey: @"COMMENTSELEMENT4"] intValue];
            
			useSeriesDescription = [[dict objectForKey: @"useSeriesDescription"] intValue];
			splitMultiEchoMR = [[dict objectForKey: @"splitMultiEchoMR"] intValue];
			NOLOCALIZER = [[dict objectForKey: @"NOLOCALIZER"] intValue];
			combineProjectionSeries = [[dict objectForKey: @"combineProjectionSeries"] intValue];
			oneFileOnSeriesForUS = [[dict objectForKey: @"oneFileOnSeriesForUS"] intValue];
			combineProjectionSeriesMode = [[dict objectForKey: @"combineProjectionSeriesMode"] intValue];
			
            gUsePatientBirthDateForUID = [[dict objectForKey: @"UsePatientBirthDateForUID"] intValue];
            gUsePatientIDForUID = [[dict objectForKey: @"UsePatientIDForUID"] intValue];
            gUsePatientNameForUID = [[dict objectForKey: @"UsePatientNameForUID"] intValue];
            
//			CHECKFORLAVIM = NO;
		}
	}
}

+ (BOOL) isTiffFile:(NSString *) file
{
	int success = NO;
	
	#ifndef STATIC_DICOM_LIB
	#ifndef OSIRIX_LIGHT
	NSString *extension = [[file pathExtension] lowercaseString];
	
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
	#endif
	return success;
}

+ (BOOL) isFVTiffFile:(NSString *) file
{
	int success = NO;

	#ifndef STATIC_DICOM_LIB
	#ifndef OSIRIX_LIGHT
	NSString *extension = [[file pathExtension] lowercaseString];
	
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
	#endif
	return success;
}

#ifndef DECOMPRESS_APP
+ (BOOL) isNIfTIFile:(NSString *) file
{
	// NIfTI support developed by Zack Mahdavi at the Center for Neurological Imaging, a division of Harvard Medical School
	// For more information: http://cni.bwh.harvard.edu/
	// For questions or suggestions regarding NIfTI integration in OsiriX, please contact zmahdavi@bwh.harvard.edu
	
	int success = NO;
	NSString	*extension = [[file pathExtension] lowercaseString];
	struct nifti_1_header  *NIfTI;
	
	if( [extension isEqualToString:@"hdr"] == YES ||
		[extension isEqualToString:@"nii"] == YES)
	{
		NIfTI = (nifti_1_header *) nifti_read_header([file UTF8String], nil, 0);
		
		if( (NIfTI->magic[0] != 'n')                           ||
					(NIfTI->magic[1] != 'i' && NIfTI->magic[1] != '+')   ||
					(NIfTI->magic[2] != '1')                           ||
					(NIfTI->magic[3] != '\0'))
		{
			success = NO;
		}
		else
		{
			success = YES;
		}
		
		NIfTI = nil;
	}
	return success;
}
#endif

+ (BOOL) isDICOMFile:(NSString *) file compressed:(BOOL*) compressed image:(BOOL*) image
{
	if( compressed)
		*compressed = NO;
		
	if( image)
		*image = NO;
	
	BOOL  readable = YES, isImage;
	PapyShort fileNb;
	
	[PapyrusLock lock];
	
	@try
	{
		fileNb = Papy3FileOpen( (char*) [file UTF8String], (PAPY_FILE) 0, TRUE, 0);
		if (fileNb < 0)
			readable = NO;
		else
		{
			if( gSOPClassUID [fileNb])
				isImage = [DCMAbstractSyntaxUID isImageStorage: [NSString stringWithCString: gSOPClassUID [fileNb] encoding: NSISOLatin1StringEncoding]];
			else
				isImage = NO;
			
			if( image)
				*image = isImage;
			
			if( compressed)
			{
				if( isImage)
				{
					if( gArrCompression [fileNb] == JPEG_LOSSLESS || gArrCompression [fileNb] == JPEG_LOSSY || gArrCompression [fileNb] == JPEG2000 || gArrCompression [fileNb] == JPEGLSLossLess || gArrCompression [fileNb] == JPEGLSLossy) *compressed = YES;
				}
			}
			Papy3FileClose (fileNb, TRUE);
		}
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	[PapyrusLock unlock];
	
    return readable;
}

+ (BOOL) isDICOMFile:(NSString *) file compressed:(BOOL*) compressed
{
	return [DicomFile isDICOMFile: file compressed: compressed image: nil];
}

+ (BOOL) isDICOMFile:(NSString *) file
{
	return [DicomFile isDICOMFile: file compressed: nil];
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
	
	#ifndef STATIC_DICOM_LIB
	#ifndef OSIRIX_LIGHT
	NSString *extension = [[filePath pathExtension] lowercaseString];
	
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
			
			name = [[NSString alloc] initWithString: [filePath lastPathComponent]];
//			name = [[NSString alloc] initWithCString:mm_head.Name encoding:NSWindowsCP1252StringEncoding];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:name];
			self.serieID = name;
			imageID = [[NSString alloc] initWithString:name];
			study = [[NSString alloc] initWithString:name];
			serie = [[NSString alloc] initWithString:name];
			Modality = [[NSString alloc] initWithString:@"FV300"];
			fileType = [@"FVTiff" retain];
			
			// set the comments and date fields
			NSXMLElement* rootElement = [xmlDocument rootElement];
			NSString* datetime_string = [NSString string];
			for (i = 0; i < [rootElement childCount]; i++)
			{
				NSXMLNode* theNode = [rootElement childAtIndex:i];
				if ([[theNode name] isEqualToString:@"Description"])
					[dicomElements setObject:[theNode stringValue] forKey:@"studyComments"];
					
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
			
			
			date = [[NSDate dateWithNaturalLanguageString:datetime_string] retain];
			if (date == nil)
				date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
			if( date == nil) date = [[NSDate date] retain];
            
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
								
				[dicomElements setObject:[SeriesNum stringByAppendingString: self.serieID] forKey:[@"seriesID" stringByAppendingString:SeriesNum]];
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
	self.serieID = [[NSDate date] description];
	studyID = [[NSString alloc] initWithFormat:@"%ld", random()];

	name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	patientID = [[NSString alloc] initWithString:name];
	study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	Modality = [[NSString alloc] initWithString:@"RD"];
	date = [[NSCalendarDate date] retain];
	serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
	fileType = [@"IMAGE" retain];

	NoOfSeries = 1;
	NoOfFrames = 1;
	
	[dicomElements setObject:studyID forKey:@"studyID"];
	[dicomElements setObject:study forKey:@"studyDescription"];
	[dicomElements setObject:date forKey:@"studyDate"];
	[dicomElements setObject:Modality forKey:@"modality"];
	[dicomElements setObject:patientID forKey:@"patientID"];
	[dicomElements setObject:name forKey:@"patientName"];
	[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
	[dicomElements setObject:self.serieID forKey:@"seriesID"];
	[dicomElements setObject:name forKey:@"seriesDescription"];
	[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
	[dicomElements setObject:imageID forKey:@"SOPUID"];
	[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
	[dicomElements setObject:fileType forKey:@"fileType"];

	return 0;
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
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
        [extension isEqualToString:@"jp2"] == YES ||
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
				NSBitmapImageRep	*rep;
				
				#ifndef STATIC_DICOM_LIB
				#ifndef OSIRIX_LIGHT
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
						
//						NSLog( @"TIFF NoOfFrames: %d", NoOfFrames);
						
						TIFFClose(tif);
					}
				}
				else
				#endif
				#endif
				{
					if( otherImage && [extension isEqualToString:@"pdf"])
					{
						height = [otherImage size].height;
						width = [otherImage size].width;
					}
					else
					{
						rep = [NSBitmapImageRep imageRepWithData:[otherImage TIFFRepresentation]];
						
						if( rep)
						{
							if( [rep pixelsWide] > [otherImage size].width)
							{
								height = [rep pixelsHigh];
								width = [rep pixelsWide];
							}
							else
							{
								height = [otherImage size].height;
								width = [otherImage size].width;
							}
						}
					}
				}
				
				if( [tempString length] >= 4) strNo[ 0] = [tempString characterAtIndex: [tempString length] -4];	else strNo[ 0]= 0;
				if( [tempString length] >= 3) strNo[ 1] = [tempString characterAtIndex: [tempString length] -3];	else strNo[ 1]= 0;
				if( [tempString length] >= 2) strNo[ 2] = [tempString characterAtIndex: [tempString length] -2];	else strNo[ 2]= 0;
				if( [tempString length] >= 1) strNo[ 3] = [tempString characterAtIndex: [tempString length] -1];	else strNo[ 3]= 0;
				strNo[ 4] = 0;
				
				if( strNo[ 0] >= '0' && strNo[ 0] <= '9' && strNo[ 1] >= '0' && strNo[ 1] <= '9' && strNo[ 2] >= '0' && strNo[ 2] <= '9'  && strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 4] stringByAppendingString:[NSString stringWithCString: (char*) strNo encoding: NSISOLatin1StringEncoding]]];
					self.serieID = [tempString substringToIndex: [tempString length] - 4];
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
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 3] stringByAppendingString:[NSString stringWithCString: (char*) strNo encoding: NSISOLatin1StringEncoding]]];
					self.serieID = [tempString substringToIndex: [tempString length] - 3];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 3]];
				}
				else if( strNo[ 2] >= '0' && strNo[ 2] <= '9' && strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					// We HAVE a number with 2 digit at the end of the file!! Make a serie of it!
					strNo[0] = strNo[ 2];
					strNo[1] = strNo[ 3];
					strNo[2] = 0;
					
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 2] stringByAppendingString:[NSString stringWithCString: (char*) strNo encoding: NSISOLatin1StringEncoding]]];
					self.serieID = [tempString substringToIndex: [tempString length] - 2];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 2]];
				}
				else if( strNo[ 3] >= '0' && strNo[ 3] <= '9')
				{
					// We HAVE a number with 1 digit at the end of the file!! Make a serie of it!
					strNo[0] = strNo[ 3];
					strNo[1] = 0;
					
					imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
					SOPUID = [[NSString alloc] initWithString: [[tempString substringToIndex: [tempString length] - 1] stringByAppendingString:[NSString stringWithCString: (char*) strNo encoding: NSISOLatin1StringEncoding]]];
					self.serieID = [tempString substringToIndex: [tempString length] - 1];
					studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] - 1]];
				}
				else
				{
					imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
					SOPUID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
					self.serieID = [filePath lastPathComponent];
					studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				}
				
				name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				patientID = [[NSString alloc] initWithString:name];
				study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				Modality = [[NSString alloc] initWithString:extension];
				date = [[[[NSFileManager defaultManager] attributesOfItemAtPath: filePath error: nil] fileCreationDate] retain];
                if( date == nil) date = [[NSDate date] retain];
				serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
				fileType = [@"IMAGE" retain];
				
				if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
					self.serieID = [NSString stringWithFormat:@"%@-%@-%@", self.serieID, imageID, [filePath lastPathComponent]];
				
				NoOfSeries = 1;
				
				if( [extension isEqualToString:@"pdf"])
				{
					NSPDFImageRep *pdfRepresentation = [NSPDFImageRep imageRepWithData: [NSData dataWithContentsOfFile: filePath]];
					
					NoOfFrames = [pdfRepresentation pageCount];
					
					if( NoOfFrames > 50) NoOfFrames = 50;   // Limit number of pages
				}
				
				[dicomElements setObject:studyID forKey:@"studyID"];
				[dicomElements setObject:study forKey:@"studyDescription"];
				[dicomElements setObject:date forKey:@"studyDate"];
				[dicomElements setObject:Modality forKey:@"modality"];
				[dicomElements setObject:patientID forKey:@"patientID"];
				[dicomElements setObject:name forKey:@"patientName"];
				[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
				[dicomElements setObject:self.serieID forKey:@"seriesID"];
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
        name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
        patientID = [[NSString alloc] initWithString:name];
        studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
        self.serieID = [filePath lastPathComponent];
        imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
        
        
        study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
        Modality = [[NSString alloc] initWithString:extension];
        date = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error: nil] fileCreationDate] retain];
        if( date == nil) date = [[NSDate date] retain];
        serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
        fileType = [@"IMAGE" retain];

        NoOfFrames = 1;
        NoOfSeries = 1;
        
        NSError *error = nil;
        AVAsset *asset = [AVAsset assetWithURL: [NSURL fileURLWithPath: filePath]];
        AVAssetReader *asset_reader = [[[AVAssetReader alloc] initWithAsset: asset error: &error] autorelease];
        
        NSArray* video_tracks = [asset tracksWithMediaType: AVMediaTypeVideo];
        if( video_tracks.count)
        {
            AVAssetTrack* video_track = [video_tracks objectAtIndex:0];
            
//            NSLog(@"%f %f", video_track.naturalSize.width, video_track.naturalSize.height);
            
            NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject: [NSNumber numberWithInt: kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
            
            AVAssetReaderTrackOutput* asset_reader_output = [[[AVAssetReaderTrackOutput alloc] initWithTrack:video_track outputSettings:dictionary] autorelease];
            [asset_reader addOutput:asset_reader_output];
            [asset_reader startReading];
            
            NoOfFrames = 0;
            while( [asset_reader status] == AVAssetReaderStatusReading)
            {
                CMSampleBufferRef sampleBufferRef = [asset_reader_output copyNextSampleBuffer];
                
                if( NoOfFrames == 0)
                {
                    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
                    size_t w = CVPixelBufferGetWidth(pixelBuffer); 
                    size_t h = CVPixelBufferGetHeight(pixelBuffer);
                    
                    height = h;
                    width = w;
                }
                
                if( sampleBufferRef)
                {
                    CMSampleBufferInvalidate(sampleBufferRef);
                    CFRelease(sampleBufferRef);
                    
                    NoOfFrames++;
                }
            }
        }
        
        if( NoOfFrames > QUICKTIMETIMEFRAMELIMIT) NoOfFrames = QUICKTIMETIMEFRAMELIMIT;   // Limit number of images !
        
        [dicomElements setObject:studyID forKey:@"studyID"];
        [dicomElements setObject:study forKey:@"studyDescription"];
        [dicomElements setObject:date forKey:@"studyDate"];
        [dicomElements setObject:Modality forKey:@"modality"];
        [dicomElements setObject:patientID forKey:@"patientID"];
        [dicomElements setObject:name forKey:@"patientName"];
        [dicomElements setObject:[self patientUID] forKey:@"patientUID"];
        [dicomElements setObject:self.serieID forKey:@"seriesID"];
        [dicomElements setObject:name forKey:@"seriesDescription"];
        [dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
        [dicomElements setObject:imageID forKey:@"SOPUID"];
        [dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
        [dicomElements setObject:fileType forKey:@"fileType"];
        
        return 0;
    }
	
	return -1;
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"


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
//				if( date == nil) date = [[NSDate date] retain];
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
//				if( name != nil & studyID != nil & serieID != nil & imageID != nil)
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
	struct BioradHeader		header;
	
	NSString	*extension = [[filePath pathExtension] lowercaseString];
	
	if( [extension isEqualToString:@"pic"] == YES)
	{
		NSLog(@"Entering getBioradPicFile");
		
		fp = fopen( [filePath UTF8String], "r");
		if( fp)
		{
			fileType = [@"BIORAD" retain];
			
			fread( &header, 76, 1, fp);
			
			// GJ: 040609 giving better names
			NSString	*fileNameStem = [[filePath lastPathComponent] stringByDeletingPathExtension];
			// Biorad files _usually_ keep the channel number in the last two digits
			
			NSString	*imageStem = [fileNameStem substringToIndex:[fileNameStem length]-2];
			name = [[NSString alloc] initWithString: [filePath lastPathComponent]];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:imageStem];
			self.serieID = fileNameStem;
			imageID = [[NSString alloc] initWithString:fileNameStem];
			study = [[NSString alloc] initWithString:imageStem];
			serie = [[NSString alloc] initWithString:fileNameStem];
			Modality = [[NSString alloc] initWithString:@"BRP"];
			//////////////////////////////////////////////////////////////////////////////////////
			
			short realheight = NSSwapLittleShortToHost(header.ny);
			height = realheight;
			short realwidth = NSSwapLittleShortToHost(header.nx);
			width = realwidth;	
			NoOfFrames = NSSwapLittleShortToHost(header.npic);
			NoOfSeries = 1;
			
			date = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error: nil] fileCreationDate] retain];
			if( date == nil) date = [[NSDate date] retain];
            
			//NSLog(@"File has h x w x d %d x %d x %d",height,width,NoOfFrames);
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
			[dicomElements setObject:self.serieID forKey:@"seriesID"];
			[dicomElements setObject:name forKey:@"seriesDescription"];
			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];
			
			if( name != nil && studyID != nil && self.serieID != nil && imageID != nil && NoOfFrames>0)
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
			fileType = [@"LSM" retain];
			
			ptr = [file bytes];
			
			if( ptr[ 2] == 42)
				NSLog(@"LSM File");
			
			name = [[NSString alloc] initWithString: [filePath lastPathComponent]];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:name];
			self.serieID = name;
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
						
						TAGTYPE = ((tags2[1] & MASK) << 8) | ((tags2[0] & MASK) <<0);
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
			//	if (LENGTH2==1) STRIPOFF.add( new Long( lsm_fi.TIF_STRIPOFFSETS ));
			//	else
			//		STRIPOFF.add( new Long( lsm_fi.TIF_STRIPOFFSETS1 ));
					
			//	IMAGETYPE.add( new Long( lsm_fi.TIF_NEWSUBFILETYPE));

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
					
					TAGTYPE = ((TAG1[1] & MASK) << 8) | ((TAG1[0] & MASK) <<0);
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
				
				int		DIMENSION_X, DIMENSION_Y, DIMENSION_Z, NUMBER_OF_CHANNELS, TIMESTACKSIZE, DATATYPE, SCANTYPE;
				
				fread( &DIMENSION_X, 4, 1, fp);		DIMENSION_X = EndianS32_LtoN( DIMENSION_X);
				fread( &DIMENSION_Y, 4, 1, fp);		DIMENSION_Y = EndianS32_LtoN( DIMENSION_Y);
				fread( &DIMENSION_Z, 4, 1, fp);		DIMENSION_Z = EndianS32_LtoN( DIMENSION_Z);
				
				fread( &NUMBER_OF_CHANNELS, 4, 1, fp);		NUMBER_OF_CHANNELS = EndianS32_LtoN( NUMBER_OF_CHANNELS);
				fread( &TIMESTACKSIZE, 4, 1, fp);			TIMESTACKSIZE = EndianS32_LtoN( TIMESTACKSIZE);
				
				fread( &DATATYPE, 4, 1, fp);			DATATYPE = EndianU32_LtoN( DATATYPE);
				
				fseek(fp, TIF_CZ_LSMINFO + 64, SEEK_SET);
				fread( &SCANTYPE, 4, 1, fp);			SCANTYPE = EndianU32_LtoN( SCANTYPE);
	
				switch (SCANTYPE)
				{
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
			



			date = [[[[NSFileManager defaultManager] attributesOfItemAtPath: filePath error: nil] fileCreationDate] retain];
			if( date == nil) date = [[NSDate date] retain];
            
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
					SeriesNum = [NSString stringWithFormat:@"%ld",i];
				else
					SeriesNum = @"";
								
				[dicomElements setObject:[SeriesNum stringByAppendingString: self.serieID] forKey:[@"seriesID" stringByAppendingString:SeriesNum]];
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
				fileType = [@"ANALYZE" retain];
				
				Analyze = (struct dsr*) [file bytes];
				
				name = [[NSString alloc] initWithCString: replaceBadCharacter(Analyze->hk.db_name, NSISOLatin1StringEncoding) encoding: NSASCIIStringEncoding];
				patientID = [[NSString alloc] initWithString:name];
				studyID = [[NSString alloc] initWithString:name];
				self.serieID = [[filePath lastPathComponent] stringByDeletingPathExtension];
				imageID = [[NSString alloc] initWithString:name];
				study = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
				serie = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
				Modality = [[NSString alloc] initWithString:@"ANZ"];
				
				date = [[NSCalendarDate alloc] initWithString:[NSString stringWithCString: Analyze->hist.exp_date encoding: NSISOLatin1StringEncoding] calendarFormat:@"%Y%m%d"];
				if(date == nil) date = [[[[NSFileManager defaultManager] attributesOfItemAtPath: filePath error: nil] fileCreationDate] retain];
				if( date == nil) date = [[NSDate date] retain];
                
				short endian = Analyze->dime.dim[ 0];		// dim[0] 
				if ((endian < 0) || (endian > 15)) 
				{
					intelByteOrder = YES;
				}
				
				height = Analyze->dime.dim[ 1];
				if( intelByteOrder) height = Endian16_Swap( height);
				width = Analyze->dime.dim[ 2];
				if( intelByteOrder) width = Endian16_Swap( width);
				
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
				[dicomElements setObject:self.serieID forKey:@"seriesID"];
				[dicomElements setObject:name forKey:@"seriesDescription"];
				[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
				[dicomElements setObject:imageID forKey:@"SOPUID"];
				[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
				[dicomElements setObject:fileType forKey:@"fileType"];
				
				if( name != nil && studyID != nil && self.serieID != nil && imageID != nil)
				{
					return 0;   // success
				}
			}
		}
	}
	
	return -1;
}

#ifndef DECOMPRESS_APP
-(short) getNIfTI
{
	// NIfTI support developed by Zack Mahdavi at the Center for Neurological Imaging, a division of Harvard Medical School
	// For more information: http://cni.bwh.harvard.edu/
	// For questions or suggestions regarding NIfTI integration in OsiriX, please contact zmahdavi@bwh.harvard.edu

	struct nifti_1_header  *NIfTI;
	
	NSString	*extension = [[filePath pathExtension] lowercaseString];

	if( (( [extension isEqualToString:@"hdr"] == YES) && 
		([[NSFileManager defaultManager] fileExistsAtPath:[[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)) ||
		( [extension isEqualToString:@"nii"] == YES))
	{
		NIfTI = (nifti_1_header *) nifti_read_header([filePath UTF8String], nil, 0);
		
		if( NIfTI == nil)
			return -1;
		
		fileType = [@"NIfTI" retain];
		
		if( (NIfTI->magic[0] == 'n') &&
			(NIfTI->magic[1] == 'i' || NIfTI->magic[1] == '+') &&
			(NIfTI->magic[2] == '1') &&
			(NIfTI->magic[3] == '\0'))
		{
			name = [[DicomFile NSreplaceBadCharacter: [filePath lastPathComponent]] retain];
			patientID = [[NSString alloc] initWithString:name];
			studyID = [[NSString alloc] initWithString:name];
			self.serieID = [[filePath lastPathComponent] stringByDeletingPathExtension];
			imageID = [[NSString alloc] initWithString:name];
			study = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
			serie = [[NSString alloc] initWithString:[[filePath lastPathComponent] stringByDeletingPathExtension]];
			Modality = [[NSString alloc] initWithString:@"NIfTI"];
			date = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] fileCreationDate] retain];
			if( date == nil) date = [[NSDate date] retain];
            
			width = NIfTI->dim[ 1];

			height = NIfTI->dim[ 2];
			
			NoOfFrames = NIfTI->dim[ 3];
			NoOfSeries = 1;
			
			[dicomElements setObject:studyID forKey:@"studyID"];
			[dicomElements setObject:study forKey:@"studyDescription"];
			[dicomElements setObject:date forKey:@"studyDate"];
			[dicomElements setObject:Modality forKey:@"modality"];
			[dicomElements setObject:patientID forKey:@"patientID"];
			[dicomElements setObject:name forKey:@"patientName"];
			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
			[dicomElements setObject:self.serieID forKey:@"seriesID"];
			[dicomElements setObject:name forKey:@"seriesDescription"];
			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];
			
			
			if( name != nil && studyID != nil && self.serieID != nil && imageID != nil)
			{
				return 0;   // success
			}
		}
		
		free( NIfTI);
	}
	
	return -1;
}

+(NSXMLDocument *) getNIfTIXML : (NSString *) file 
{
	NSString	*returnString;
	nifti_image *NIfTI;
	
	NSXMLDocument *xmlDoc;
	
	NSXMLElement *rootElement = [[[NSXMLElement alloc] initWithName:@"NIfTIObject"] autorelease];
	xmlDoc = [[[NSXMLDocument alloc] initWithRootElement: rootElement] autorelease];
	
	// Process NIfTI header
	
	if([self isNIfTIFile: file])
	{
		NIfTI = nifti_image_read( [file UTF8String], 0);
		 
		returnString = [[[NSString alloc] initWithCString:nifti_image_to_ascii(NIfTI) encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"NIFTI INFO:  %@", returnString);
		
		// Now build the XML document

		// Cycle through string, and parse out key and value from each line.  Then store in XML document.
		NSArray *allLines = [returnString componentsSeparatedByString:@"\n"];
		
		if([allLines count] > 0)
		{
			NSLog(@"allLines Count:  %d", (int) [allLines count]);
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
					NSXMLElement *node = [[[NSXMLElement alloc] initWithName: key] autorelease];
					[node addAttribute:[NSXMLNode attributeWithName:@"group" stringValue:@""]];
					[node addAttribute:[NSXMLNode attributeWithName:@"element" stringValue:@""]];
					[node addAttribute:[NSXMLNode attributeWithName:@"vr" stringValue:@""]];
					[node addAttribute:[NSXMLNode attributeWithName:@"attributeTag" stringValue:@""]];
					
					NSXMLElement *childNode = [[[NSXMLElement alloc] initWithName:@"value" stringValue:value] autorelease];
					[childNode addAttribute:[NSXMLNode attributeWithName:@"number" stringValue:@"0"]];
					[node addChild:childNode];
					
					[rootElement addChild:node];
				}
			}
		}
		
		// Review the NIfTI extension list and add any elements to list.
		if( NIfTI->num_ext > 0 && NIfTI->ext_list != NULL)
		{
			int c = 0;
			nifti1_extension * ext;
			ext = NIfTI->ext_list;
			for ( c = 0; c < NIfTI->num_ext; c++)
			{
				NSXMLElement *node = [[[NSXMLElement alloc] initWithName:
					[@"extension: ecode " stringByAppendingString:[NSString stringWithFormat:@"%i", ext->ecode]]] autorelease];
				[node addAttribute:[NSXMLNode attributeWithName:@"group" stringValue:@""]];
				[node addAttribute:[NSXMLNode attributeWithName:@"element" stringValue:@""]];
				[node addAttribute:[NSXMLNode attributeWithName:@"vr" stringValue:@""]];
				[node addAttribute:[NSXMLNode attributeWithName:@"attributeTag" stringValue:@""]];
				
				NSXMLElement *childNode = [[[NSXMLElement alloc] initWithName:@"value" stringValue:[NSString stringWithUTF8String:ext->edata]] autorelease];
				[childNode addAttribute:[NSXMLNode attributeWithName:@"number" stringValue:@"0"]];
				[node addChild:childNode];
				
				[rootElement addChild:node];

				ext++;
			}
		}
	}
	return xmlDoc;
} 
#endif

- (NSPDFImageRep*) PDFImageRep
{
#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT

	[[NSFileManager defaultManager] confirmDirectoryAtPath:@"/tmp/dicomsr_osirix/"];
	
	NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [filePath lastPathComponent]] stringByAppendingPathExtension: @"xml"];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
	{
		NSTask *aTask = [[[NSTask alloc] init] autorelease];		
		[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
		[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
		[aTask setArguments: [NSArray arrayWithObjects: @"+X1", @"--unknown-relationship", @"--ignore-constraints", @"--ignore-item-errors", @"--skip-invalid-items", filePath, htmlpath, nil]];		
		[aTask launch];
		while( [aTask isRunning])
            [NSThread sleepForTimeInterval: 0.1];
        
        //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
		[aTask interrupt];
	}
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
	{
        if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]])
        {
            NSTask *aTask = [[[NSTask alloc] init] autorelease];
            [aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
            [aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
            [aTask launch];
            NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
			while( [aTask isRunning] && [NSDate timeIntervalSinceReferenceDate] - start < 10)
                [NSThread sleepForTimeInterval: 0.1];
            
            //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
            [aTask interrupt];
        }
	}
	
	return [NSPDFImageRep imageRepWithData: [NSData dataWithContentsOfFile: [htmlpath stringByAppendingPathExtension: @"pdf"]]];
#endif
#endif
	
	return nil;
}

-(short) getDicomFilePapyrus :(BOOL) forceConverted
{
    int					itemType, returnValue = -1;
    long				cardiacTime = -1;
    short				theErr;
    PapyShort           fileNb, imageNb;
    PapyULong           nbVal;
    UValue_T            *val;
    SElement			*theGroupP;
    NSString			*converted = nil;
    NSStringEncoding	encoding[ 10];
    NSString *echoTime = nil;
    NSString *sopClassUID = nil;
    NSMutableArray *imageTypeArray = nil;

    if( filePath == nil)
        return returnValue;
    
    [PapyrusLock lock];

    @try
    {
        // open the test file
        if( forceConverted) fileNb = -1;
        else fileNb = Papy3FileOpen ( (char*) [filePath UTF8String], (PAPY_FILE) 0, TRUE, 0);
        
        if( fileNb < 0)
        {
            NSLog( @"fileNb < 0 : %d , %@", fileNb, filePath);
            if( [self getDicomFileDCMTK] == 0)	// First, try with dcmtk
                return 0;
            
//    #ifndef DECOMPRESS_APP
//            // And if it failed, try to convert it...
//            converted = convertDICOM( filePath);
//            fileNb = Papy3FileOpen (  (char*) [converted UTF8String], (PAPY_FILE) 0, TRUE, 0);
//    #endif
        }
        
        if (fileNb >= 0)
        {
            if( gIsPapyFile [fileNb] == DICOM10 || gIsPapyFile [fileNb] == DICOM_NOT10)	// Actual version of OsiriX supports only DICOM... should we support PAPYRUS?... NO: too much work!
            {
                if( gArrCompression  [fileNb] == MPEG2MPML)
                {
                    fileType = [@"DICOMMPEG2" retain];
                    [dicomElements setObject:fileType forKey:@"fileType"];
                }
                else
                {
                    fileType = [@"DICOM" retain];
                    [dicomElements setObject:fileType forKey:@"fileType"];
                }
                
                imageNb = 1;
                
                if (gIsPapyFile [fileNb] == DICOM10)
                    theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                
                NSString *characterSet = nil;
                for( int i = 0; i < 10; i++) encoding[ i] = 0;
                encoding[ 0] = NSISOLatin1StringEncoding;
                
                if (COMMENTSAUTOFILL == YES) // || CHECKFORLAVIM == YES)
                {
                    if( COMMENTSAUTOFILL)
                    {
                        NSString *commentsField = nil;
                        
                        if( COMMENTSGROUP && COMMENTSELEMENT)
                        {
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
                                            
                                            if( theValueP->a && validAPointer( inGrOrModP->vr))
                                            {
                                                commentsField = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                                            }
                                        }
                                    }
                                }
                                theErr = Papy3GroupFree (&theGroupP, TRUE);
                            }
                        }
                        
                        if( COMMENTSGROUP2 && COMMENTSELEMENT2)
                        {
                            if (gIsPapyFile [fileNb] == DICOM10)
                                theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                            
                            
                            theErr = Papy3GotoGroupNb (fileNb, COMMENTSGROUP2);
                            if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                            {
                                SElement *inGrOrModP = theGroupP;
                                
                                int theEnumGrNb = Papy3ToEnumGroup( COMMENTSGROUP2);
                                int theMaxElem = gArrGroup [theEnumGrNb].size;
                                int j;
                                
                                for (j = 0; j < theMaxElem; j++, inGrOrModP++)
                                {
                                    if( inGrOrModP->element == COMMENTSELEMENT2)
                                    {
                                        if( inGrOrModP->nb_val > 0)
                                        {
                                            UValue_T *theValueP = inGrOrModP->value;
                                            
                                            if( theValueP->a && validAPointer( inGrOrModP->vr))
                                            {
                                                if( commentsField)
                                                    commentsField = [commentsField stringByAppendingFormat: @" / %@", [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding]];
                                                else
                                                    commentsField = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                                            }
                                        }
                                    }
                                }
                                theErr = Papy3GroupFree (&theGroupP, TRUE);
                            }
                        }
                        
                        if( COMMENTSGROUP3 && COMMENTSELEMENT3)
                        {
                            if (gIsPapyFile [fileNb] == DICOM10)
                                theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                            
                            theErr = Papy3GotoGroupNb (fileNb, COMMENTSGROUP3);
                            if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                            {
                                SElement *inGrOrModP = theGroupP;
                                
                                int theEnumGrNb = Papy3ToEnumGroup( COMMENTSGROUP3);
                                int theMaxElem = gArrGroup [theEnumGrNb].size;
                                int j;
                                
                                for (j = 0; j < theMaxElem; j++, inGrOrModP++)
                                {
                                    if( inGrOrModP->element == COMMENTSELEMENT3)
                                    {
                                        if( inGrOrModP->nb_val > 0)
                                        {
                                            UValue_T *theValueP = inGrOrModP->value;
                                            
                                            if( theValueP->a && validAPointer( inGrOrModP->vr))
                                            {
                                                if( commentsField)
                                                    commentsField = [commentsField stringByAppendingFormat: @" / %@", [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding]];
                                                else
                                                    commentsField = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                                            }
                                        }
                                    }
                                }
                                theErr = Papy3GroupFree (&theGroupP, TRUE);
                            }
                        }
                        
                        if( COMMENTSGROUP4 && COMMENTSELEMENT4)
                        {
                            if (gIsPapyFile [fileNb] == DICOM10)
                                theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                            
                            theErr = Papy3GotoGroupNb (fileNb, COMMENTSGROUP4);
                            if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                            {
                                SElement *inGrOrModP = theGroupP;
                                
                                int theEnumGrNb = Papy3ToEnumGroup( COMMENTSGROUP4);
                                int theMaxElem = gArrGroup [theEnumGrNb].size;
                                int j;
                                
                                for (j = 0; j < theMaxElem; j++, inGrOrModP++)
                                {
                                    if( inGrOrModP->element == COMMENTSELEMENT4)
                                    {
                                        if( inGrOrModP->nb_val > 0)
                                        {
                                            UValue_T *theValueP = inGrOrModP->value;
                                            
                                            if( theValueP->a && validAPointer( inGrOrModP->vr))
                                            {
                                                if( commentsField)
                                                    commentsField = [commentsField stringByAppendingFormat: @" / %@", [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding]];
                                                else
                                                    commentsField = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                                            }
                                        }
                                    }
                                }
                                theErr = Papy3GroupFree (&theGroupP, TRUE);
                            }
                        }
                        
                        if( commentsField)
                            [dicomElements setObject: commentsField forKey:@"commentsAutoFill"];
                    }
                    
                    //				if( CHECKFORLAVIM == YES)
                    //				{
                    //					NSString	*album = nil;
                    //					
                    //					theErr = Papy3GotoGroupNb (fileNb, 0x0020);
                    //					if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                    //					{
                    //						SElement *inGrOrModP = theGroupP;
                    //						
                    //						int theEnumGrNb = Papy3ToEnumGroup( 0x0020);
                    //						int theMaxElem = gArrGroup [theEnumGrNb].size;
                    //						int j;
                    //						
                    //						for (j = 0; j < theMaxElem; j++, inGrOrModP++)
                    //						{
                    //							if( inGrOrModP->element == 0x4000)
                    //							{
                    //								if( inGrOrModP->nb_val > 0)
                    //								{
                    //									UValue_T *theValueP = inGrOrModP->value;
                    //									
                    //									if( theValueP->a && validAPointer( inGrOrModP->vr))
                    //									{
                    //										album = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                    //										
                    //										if( [album length] >= 2)
                    //										{
                    //											if( [[album substringToIndex:2] isEqualToString: @"LV"])
                    //											{
                    //												album = [album substringFromIndex:2];
                    //												[dicomElements setObject:album forKey:@"album"];
                    //											}
                    //										}
                    //									}
                    //								}
                    //							}
                    //						}
                    //						
                    //						theErr = Papy3GroupFree (&theGroupP, TRUE);
                    //					}
                    //					
                    //					theErr = Papy3GotoGroupNb (fileNb, 0x0040);
                    //					if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                    //					{
                    //						SElement *inGrOrModP = theGroupP;
                    //						
                    //						int theEnumGrNb = Papy3ToEnumGroup( 0x0040);
                    //						int theMaxElem = gArrGroup [theEnumGrNb].size;
                    //						int j;
                    //						
                    //						for (j = 0; j < theMaxElem; j++, inGrOrModP++)
                    //						{
                    //							if( inGrOrModP->element == 0x0280)
                    //							{
                    //								if( inGrOrModP->nb_val > 0)
                    //								{
                    //									UValue_T *theValueP = inGrOrModP->value;
                    //									
                    //									if( theValueP->a && validAPointer( inGrOrModP->vr))
                    //									{
                    //										album = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                    //										
                    //										if( [album length] >= 2)
                    //										{
                    //											if( [[album substringToIndex:2] isEqualToString: @"LV"])
                    //											{
                    //												album = [album substringFromIndex:2];
                    //												[dicomElements setObject:album forKey:@"album"];
                    //											}
                    //										}
                    //									}
                    //								}
                    //							}
                    //							
                    //							if( inGrOrModP->element == 0x1400)
                    //							{
                    //								if( inGrOrModP->nb_val > 0)
                    //								{
                    //									UValue_T *theValueP = inGrOrModP->value;
                    //									
                    //									if( theValueP->a && validAPointer( inGrOrModP->vr))
                    //									{
                    //										album = [NSString stringWithCString:theValueP->a encoding: NSISOLatin1StringEncoding];
                    //										
                    //										if( [album length] >= 2)
                    //										{
                    //											if( [[album substringToIndex:2] isEqualToString: @"LV"])
                    //											{
                    //												album = [album substringFromIndex:2];
                    //												[dicomElements setObject:album forKey:@"album"];
                    //											}
                    //										}
                    //									}
                    //								}
                    //							}
                    //						}
                    //						theErr = Papy3GroupFree (&theGroupP, TRUE);
                    //					}
                    //				}
                }
                
                if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);

                theErr = Papy3GotoGroupNb(fileNb, (PapyShort)0x0002);
                if (theErr >= 0 && Papy3GroupRead(fileNb, &theGroupP) > 0)
                {
                    val = Papy3GetElement(theGroupP, papPrivateInformationCreatorUIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        NSString* privateInformationCreatorUID = [NSString stringWithCString:val->a encoding: NSISOLatin1StringEncoding];
                        if (privateInformationCreatorUID.length)
                            [dicomElements setObject:privateInformationCreatorUID forKey:@"PrivateInformationCreatorUID"];
                    }
                    
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
                
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0008);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    val = Papy3GetElement (theGroupP, papSOPClassUIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        sopClassUID = [NSString stringWithCString:val->a encoding: NSISOLatin1StringEncoding];
                        [dicomElements setObject:sopClassUID forKey:@"SOPClassUID"];					
                    }
                    
                    val = Papy3GetElement (theGroupP, papSpecificCharacterSetGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        for( int z = 0; z < nbVal ; z++)
                        {
                            if( z < 10)
                            {
                                characterSet = [NSString stringWithCString:val->a encoding: NSISOLatin1StringEncoding];
                                encoding[ z] = [NSString encodingForDICOMCharacterSet:characterSet];
                            }
                            else NSLog( @"Encoding number >= 10 ???");
                            val++;
                        }
                    }
                    
                    val = Papy3GetElement (theGroupP, papImageTypeGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
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
                        else imageType = nil;
                    }
                    else imageType = nil;
                    
                    if( imageType) [dicomElements setObject:imageType forKey:@"imageType"];
                    
                    val = Papy3GetElement (theGroupP, papSOPInstanceUIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) SOPUID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                    else SOPUID = nil;
                    if( SOPUID) [dicomElements setObject: SOPUID forKey: @"SOPUID"];
                    
                    // TEST
                    //				char* t = sopInstanceUIDEncode( SOPUID);
                    //				NSLog( SOPUID);
                    //				NSLog( sopInstanceUIDDecode( t));
                    //				NSLog( @"%d %d", strlen( t), [SOPUID length]);
                    //				free( t);
                    
                    val = Papy3GetElement (theGroupP, papStudyDescriptionGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) study = [[DicomFile stringWithBytes: (char*) val->a encodings:encoding] retain];
                    else
                    {
                        val = Papy3GetElement (theGroupP, papProcedureCodeSequenceGr, &nbVal, &itemType);
                        if (val != NULL && nbVal >= 1 && val->sq)
                        {
                            // get a pointer to the first element of the list
                            Papy_List *seq = val->sq->object->item;
                            
                            while (seq)
                            {
                                SElement * gr = (SElement *) seq->object->group;
                                switch( gr->group)
                                {
                                    case 0x0008:
                                    {
                                        val = Papy3GetElement ( gr, papCodeMeaningGr, &nbVal, &itemType);
                                        if (val != NULL && val->a && validAPointer( itemType))
                                            study = [[DicomFile stringWithBytes: (char*) val->a encodings:encoding] retain];
                                    }
                                }
                                seq = seq->next;
                            }
                        }
                    }
                    if( !study)
                        study = [[NSString alloc] initWithString: @"unnamed"];
                    [dicomElements setObject: study forKey: @"studyDescription"];
                    
                    val = Papy3GetElement (theGroupP, papModalityGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) Modality = [[DicomFile stringWithBytes: (char*) val->a encodings:encoding] retain];
                    else Modality = [[NSString alloc] initWithString: @"OT"];
                    [dicomElements setObject: Modality forKey: @"modality"];
                    
                    NSString *studyTime = nil, *studyDate = nil;
                    
                    val = Papy3GetElement (theGroupP, papAcquisitionDateGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                        studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                    else
                    {
                        val = Papy3GetElement (theGroupP, papImageDateGr, &nbVal, &itemType);
                        if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                            studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                        else
                        {
                            val = Papy3GetElement (theGroupP, papSeriesDateGr, &nbVal, &itemType);
                            if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                                studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                            else
                            {
                                val = Papy3GetElement (theGroupP, papStudyDateGr, &nbVal, &itemType);
                                if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                                    studyDate = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                            }
                        }
                    }
                    if( [studyDate length] != 6) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
                    
                    val = Papy3GetElement (theGroupP, papAcquisitionTimeGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0 && atof( val->a) > 0)
                        studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                    else
                    {
                        val = Papy3GetElement (theGroupP, papImageTimeGr, &nbVal, &itemType);
                        if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0 && atof( val->a) > 0)
                            studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                        else
                        {
                            val = Papy3GetElement (theGroupP, papSeriesTimeGr, &nbVal, &itemType);
                            if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0 && atof( val->a) > 0)
                                studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                            else
                            {
                                val = Papy3GetElement (theGroupP, papStudyTimeGr, &nbVal, &itemType);
                                if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0 && atof( val->a) > 0)
                                    studyTime = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                            }
                        }
                    }
                    
                    if( studyDate && studyTime)
                    {
                        NSString *completeDate = [studyDate stringByAppendingString:studyTime];
                        
                        if( [studyTime length] >= 6)
                            date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
                        else
                            date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
                    }
                    else if( studyDate)
                    {
                        studyDate = [studyDate stringByAppendingString: @"120000"];
                        date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat: @"%Y%m%d%H%M%S"];
                    }
                    else
                        date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil] retain];
                    
                    if( date)
                        [dicomElements setObject:date forKey:@"studyDate"];
                    
                    val = Papy3GetElement (theGroupP, papSeriesDescriptionGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        serie = [[DicomFile stringWithBytes: (char*) val->a encodings:encoding] retain];
                        [dicomElements setObject: serie forKey: @"seriesDescription"];
                    }
                    
                    val = Papy3GetElement (theGroupP, papInstitutionNameGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        [dicomElements setObject: [DicomFile stringWithBytes: (char*) val->a encodings:encoding] forKey:@"institutionName"];
                    }
                    
                    val = Papy3GetElement (theGroupP, papReferringPhysiciansNameGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        [dicomElements setObject:[DicomFile stringWithBytes: (char*) val->a encodings:encoding] forKey:@"referringPhysiciansName"];
                    }
                    
                    val = Papy3GetElement (theGroupP, papPerformingPhysiciansNameGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        [dicomElements setObject:[DicomFile stringWithBytes: (char*) val->a encodings:encoding] forKey:@"performingPhysiciansName"];
                    }
                    
                    val = Papy3GetElement (theGroupP, papAccessionNumberGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        [dicomElements setObject:[DicomFile stringWithBytes: (char*) val->a encodings:encoding replaceBadCharacters: NO] forKey:@"accessionNumber"];
                    }
                    
                    //				val = Papy3GetElement (theGroupP, papManufacturerGr, &nbVal, &itemType);
                    //				if (val != NULL && val->a && validAPointer( itemType))
                    //				{
                    //					NSString *manufacturer = [DicomFile stringWithBytes: (char*) val->a encodings:encoding];
                    //					if( [manufacturer hasPrefix: @"MAC:"])
                    //						[dicomElements setObject: manufacturer forKey: @"manufacturer"];
                    //				}
                    
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
                else
                {
                    study = [[NSString alloc] initWithString:@"unnamed"];
                    Modality = [[NSString alloc] initWithString:@"OT"];
                    date = [[[[NSFileManager defaultManager] attributesOfItemAtPath: filePath error: nil] fileCreationDate] retain];
                    if( date == nil) date = [[NSDate date] retain];
                    
                    [dicomElements setObject:date forKey:@"studyDate"];
                    [dicomElements setObject:Modality forKey:@"modality"];
                    [dicomElements setObject:study forKey:@"studyDescription"];
                }
                
                //if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                // get the Patient group
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0010);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    //Patient Name
                    val = Papy3GetElement (theGroupP, papPatientsNameGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        name = [[DicomFile stringWithBytes: (char*) val->a encodings:encoding] retain];
                        if(name == nil) name = [[NSString alloc] initWithCString: val->a encoding: encoding[ 0]];
                    }
                    else name = [[NSString alloc] initWithString:@"No name"];
                    [dicomElements setObject:name forKey:@"patientName"];
                    
                    //Patient ID
                    val = Papy3GetElement (theGroupP, papPatientIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        patientID = [[DicomFile stringWithBytes: (char*) val->a encodings:encoding replaceBadCharacters: NO] retain];
                        [dicomElements setObject:patientID forKey:@"patientID"];
                    }
                    
                    // Patient Age
                    val = Papy3GetElement (theGroupP, papPatientsAgeGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {  
                        NSString *patientAge =  [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
                        [dicomElements setObject:patientAge forKey:@"patientAge"];
                        
                        //NSLog(@"Patient Age %@", patientAge);
                    }
                    //Patient BD
                    val = Papy3GetElement (theGroupP, papPatientsBirthDateGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {  
                        NSString		*patientDOB =  [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
                        NSCalendarDate	*DOB = [NSCalendarDate dateWithString: patientDOB calendarFormat:@"%Y%m%d"];
                        
                        if( DOB) [dicomElements setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: [DOB timeIntervalSinceReferenceDate]] forKey:@"patientBirthDate"];
                    }
                    //Patients Sex
                    val = Papy3GetElement (theGroupP, papPatientsSexGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {  
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
                    if (val != NULL && val->a && validAPointer( itemType))
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
                    [dicomElements setObject:[NSNumber numberWithLong: cardiacTime] forKey: @"cardiacTime"];
                    
                    val = Papy3GetElement (theGroupP, papProtocolNameGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) [dicomElements setObject: [DicomFile stringWithBytes: (char*) val->a encodings:encoding] forKey: @"protocolName"];
                    
                    if( serie == nil)
                    {
                        val = Papy3GetElement (theGroupP, papAcquisitionDeviceProcessingDescriptionGr, &nbVal, &itemType);
                        if (val != NULL && val->a && validAPointer( itemType))
                        {
                            serie = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                            [dicomElements setObject: serie forKey: @"seriesDescription"];
                        }
                    }
                    
                    //Get TE for Dual Echo and multiecho MRI sequences
                    val = Papy3GetElement (theGroupP, papEchoTimeGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) echoTime = [[[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding] autorelease];
                    
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
                
                //if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                
                // get the General Image module
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0020);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    val = Papy3GetElement (theGroupP, papImageNumberGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        int v = [[NSString stringWithCString:val->a encoding: NSASCIIStringEncoding] intValue];
                        imageID = [[NSString alloc] initWithFormat:@"%5d", v];
                    }
                    else imageID = nil;
                    
                    // Compute slice location
                    
                    float		orientation[ 9];
                    float		origin[ 3];
                    float		location = 0;
                    UValue_T    *tmp;
                    
                    origin[0] = origin[1] = origin[2] = 0;
                    
                    val = Papy3GetElement (theGroupP, papImagePositionPatientGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType) && nbVal == 3)
                    {
                        origin[0] = [[NSString stringWithCString:val++->a encoding: NSISOLatin1StringEncoding] floatValue];
                        origin[1] = [[NSString stringWithCString:val++->a encoding: NSISOLatin1StringEncoding] floatValue];
                        origin[2] = [[NSString stringWithCString:val++->a encoding: NSISOLatin1StringEncoding] floatValue];
                    }
                    
                    orientation[ 0] = 1;	orientation[ 1] = 0;		orientation[ 2] = 0;
                    orientation[ 3] = 0;	orientation[ 4] = 1;		orientation[ 5] = 0;
                    
                    val = Papy3GetElement (theGroupP, papImageOrientationPatientGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType) && nbVal == 6)
                    {
                        for (int j = 0; j < nbVal; j++)
                            orientation[ j]  = [[NSString stringWithCString:val++->a encoding: NSISOLatin1StringEncoding] floatValue];
                    }
                    
                    // Compute normal vector
                    orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
                    orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
                    orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
                    
                    if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8])) location = origin[ 0];
                    if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8])) location = origin[ 1];
                    if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7])) location = origin[ 2];
                    
                    [dicomElements setObject:[NSNumber numberWithFloat: location] forKey:@"sliceLocation"];
                    
                    if( imageID == nil || [imageID intValue] >= 99999)
                    {
                        int val = 10000 + location*10.;
                        imageID = [[NSString alloc] initWithFormat:@"%5d", val];
                    }
                    [dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];
                    
                    
                    //				val = Papy3GetElement (theGroupP, papSliceLocationGr, &nbVal, &itemType);
                    //				if (val != NULL && val->a && validAPointer( itemType))
                    //				{
                    //					sliceLocation = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                    //					int val = ([sliceLocation floatValue]) * 100.;
                    //					[sliceLocation release];
                    //					sliceLocation = [[NSString alloc] initWithFormat:@"%7d", val];
                    //				}
                    //				else sliceLocation = [[NSString alloc] initWithFormat:@"%7d", 1];
                    
                    seriesNo = nil;
                    val = Papy3GetElement (theGroupP, papSeriesNumberGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType))
                    {
                        seriesNo = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                    }
                    else seriesNo = [[NSString alloc] initWithString: @"0"];
                    
                    if( seriesNo) [dicomElements setObject:[NSNumber numberWithInt:[seriesNo intValue]]  forKey:@"seriesNumber"];
                    
                    val = Papy3GetElement (theGroupP, papSeriesInstanceUIDGr, &nbVal, &itemType);
                    if( val != NULL && val->a && validAPointer( itemType)) [dicomElements setObject:[NSString stringWithCString:val->a encoding: NSISOLatin1StringEncoding] forKey:@"seriesDICOMUID"];
                    
                    if (val != NULL && val->a && validAPointer( itemType)) self.serieID = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
                    else self.serieID = name;
                    
                    // *********** WARNING : SERIESID MUST BE IDENTICAL BETWEEN DCMFRAMEWORK & PAPYRUS TOOLKIT !!!!! OTHERWISE muliple identical series will be created during DATABASE rebuild !
                    
                    if( cardiacTime != -1 && SEPARATECARDIAC4D == YES)  // For new Cardiac-CT Siemens series
                        self.serieID = [NSString stringWithFormat:@"%@ %2.2d", serieID , (int) cardiacTime];
                    
                    if( seriesNo)
                        self.serieID = [NSString stringWithFormat:@"%8.8d %@", [seriesNo intValue] , serieID];
                    
                    if( imageType != 0 && useSeriesDescription)
                        self.serieID = [NSString stringWithFormat:@"%@ %@", serieID , imageType];
                    
                    if( serie != nil && useSeriesDescription)
                        self.serieID = [NSString stringWithFormat:@"%@ %@", serieID , serie];
                    
                    if( sopClassUID != nil && [[DCMAbstractSyntaxUID hiddenImageSyntaxes] containsObject: sopClassUID])
                        self.serieID = [NSString stringWithFormat:@"%@ %@", serieID , sopClassUID];
                    
                    //Segregate by TE  values
                    if( echoTime != nil && splitMultiEchoMR)
                        self.serieID = [NSString stringWithFormat:@"%@ TE-%@", serieID , echoTime];
                    
                    val = Papy3GetElement (theGroupP, papStudyInstanceUIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) studyID = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                    else
                        studyID = [[NSString alloc] initWithString:name];
                    
                    [dicomElements setObject:studyID forKey:@"studyID"];
                    
                    if( NOLOCALIZER && ([self containsString: @"LOCALIZER" inArray: imageTypeArray] || [self containsString: @"REF" inArray: imageTypeArray] || [self containsLocalizerInString: serie]) && [DCMAbstractSyntaxUID isImageStorage: sopClassUID])
                    {
                        self.serieID = @"LOCALIZER";
                        
                        [serie release];
                        serie = [[NSString alloc] initWithString: @"Localizers"];
                        [dicomElements setObject: serie forKey: @"seriesDescription"];
                        
                        [dicomElements setObject: [self.serieID stringByAppendingString: studyID] forKey: @"seriesDICOMUID"];
                    }
                    
                    val = Papy3GetElement (theGroupP, papStudyIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType)) studyIDs = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                    else studyIDs = [[NSString alloc] initWithString:@"0"];
                    
                    if( studyIDs) [dicomElements setObject:studyIDs forKey:@"studyNumber"];
                    
                    if( COMMENTSFROMDICOMFILES)
                    {
                        val = Papy3GetElement (theGroupP, papImageCommentsGr, &nbVal, &itemType);
                        if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                            [dicomElements setObject: [NSString stringWithCString: val->a encoding: NSASCIIStringEncoding] forKey: @"seriesComments"];
                    }
                    // free the module and the associated sequences 
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
                
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0028);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    long realwidth;
                    
                    // ROWS
                    val = Papy3GetElement (theGroupP, papRowsGr, &nbVal, &itemType);
                    if (val != NULL)
                        height = (int) (*val).us;
                    
                    // COLUMNS
                    val = Papy3GetElement (theGroupP, papColumnsGr, &nbVal, &itemType);
                    if (val != NULL) 
                    {
                        realwidth = (int) (*val).us;
                        width = realwidth;
                    }
                    val = Papy3GetElement (theGroupP, papFramesofInterestDescriptionGr, &nbVal, &itemType); // papPresentationLabelGr == DCM_FramesOfInterestDescription == 0x0028, 0x6022
                    if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                    {
                        NSMutableArray *a = [NSMutableArray array];
                        for( int v = 0 ; v < nbVal ; v++, val++)
                            [a addObject: [NSString stringWithCString: val->a encoding: NSASCIIStringEncoding]];
                        
                        [dicomElements setObject: a  forKey: @"keyFrames"];
                    }	
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
                
                if( COMMENTSFROMDICOMFILES)
                {
                    theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0032);
                    if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                    {
                        val = Papy3GetElement (theGroupP, papStudyCommentsGr, &nbVal, &itemType);
                        if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0 && [dicomElements objectForKey: @"commentsAutoFill"] == nil)
                            [dicomElements setObject: [NSString stringWithCString: val->a encoding: NSASCIIStringEncoding] forKey: @"studyComments"];
                        
                        theErr = Papy3GroupFree (&theGroupP, TRUE);
                    }
                }
                
                if( serie == nil)
                {
                    theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0040);
                    if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                    {
                        val = Papy3GetElement (theGroupP, papPerformedProcedureStepDescriptionGr, &nbVal, &itemType);
                        if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                        {
                            serie = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
                            [dicomElements setObject: serie forKey: @"seriesDescription"];
                        }
                        
                        theErr = Papy3GroupFree (&theGroupP, TRUE);
                    }
                }
                
                NoOfFrames = gArrNbImages [fileNb];
                NoOfSeries = 1;
                
                // Is it a multi frame DICOM files? We need to parse these sequences for the correct sliceLocation value !
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x5200);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    float originMultiFrame[ 3], orientationMultiFrame[ 9];
                    
                    originMultiFrame[0] = originMultiFrame[1] = originMultiFrame[2] = 0;
                    orientationMultiFrame[ 0] = 1;	orientationMultiFrame[ 1] = 0;		orientationMultiFrame[ 2] = 0;
                    orientationMultiFrame[ 3] = 0;	orientationMultiFrame[ 4] = 1;		orientationMultiFrame[ 5] = 0;
                    
                    UValue_T *val3 = nil;
                    // ****** ****** ****** ************************************************************************
                    // SHARED FRAME
                    // ****** ****** ****** ************************************************************************
                    
                    val = Papy3GetElement ( theGroupP, papSharedFunctionalGroupsSequence, &nbVal, &itemType);
                    
                    // there is an element
                    if ( val)
                    {
                        // there is a sequence
                        if (val->sq)
                        {
                            // get a pointer to the first element of the list
                            Papy_List *dcmList = val->sq->object->item;
                            
                            // loop through the elements of the sequence
                            while (dcmList != NULL)
                            {
                                SElement * gr = (SElement *) dcmList->object->group;
                                
                                switch( gr->group)
                                {
                                    case 0x0020:
                                        val3 = Papy3GetElement (gr, papPlanePositionVolumeSequence, &nbVal, &itemType);
                                        if (val3 != NULL && nbVal >= 1)
                                        {
                                            // there is a sequence
                                            if (val3->sq)
                                            {
                                                Papy_List *PixelMatrixSeq = val3->sq->object->item;
                                                
                                                // loop through the elements of the sequence
                                                while (PixelMatrixSeq)
                                                {
                                                    SElement * gr = (SElement *) PixelMatrixSeq->object->group;
                                                    
                                                    switch( gr->group)
                                                    {
                                                        case 0x0020:
                                                        {
                                                            UValue_T *val4 = nil;
                                                            val4 = Papy3GetElement (gr, papImageOrientationVolumeGr, &nbVal, &itemType);
                                                            if (val4 != NULL && itemType == FD && nbVal == 6)
                                                            {
                                                                for ( int j = 0; j < nbVal; j++)
                                                                    orientationMultiFrame[ j]  = val4++->fd;
                                                            }
                                                        }
                                                        break;
                                                    }
                                                    
                                                    // get the next element of the list
                                                    PixelMatrixSeq = PixelMatrixSeq->next;
                                                }
                                            }
                                        }
                                        break;
                                }
                                // get the next element of the list
                                dcmList = dcmList->next;
                            } // while ...loop through the sequence
                        } // if ...there is a sequence of groups
                    } // if ...val is not NULL
                    
                    // ****** ****** ****** ************************************************************************
                    // PER FRAME
                    // ****** ****** ****** ************************************************************************
                    
                    long frameCount = 0;
                    
                    val = Papy3GetElement ( theGroupP, papPerFrameFunctionalGroupsSequence, &nbVal, &itemType);
                    
                    // there is an element
                    if ( val)
                    {
                        // there is a sequence
                        if (val->sq)
                        {
                            // get a pointer to the first element of the list
                            Papy_List *dcmList = val->sq;
                            
                            NSMutableArray *sliceLocationArray = [NSMutableArray array];
                            NSMutableArray *imageCardiacTriggerArray = [NSMutableArray array];
                            
                            // loop through the elements of the sequence
                            while (dcmList)
                            {
                                if( dcmList->object->item)
                                {
                                    
                                    {
                                        Papy_List *groupsForFrame = dcmList->object->item;
                                        
                                        while( groupsForFrame)
                                        {
                                            if( groupsForFrame->object->group)
                                            {
                                                UValue_T *valb = nil, *valc = nil;
                                                SElement *gr = (SElement *) groupsForFrame->object->group;
                                                
                                                switch( gr->group)
                                                {
                                                    case 0x0018:
                                                        valb = Papy3GetElement (gr, papCardiacTriggerSequence, &nbVal, &itemType);
                                                        if (valb != NULL && nbVal >= 1)
                                                        {
                                                            // there is a sequence
                                                            if (valb->sq)
                                                            {
                                                                // get a pointer to the first element of the list
                                                                Papy_List *seq = valb->sq->object->item;
                                                                
                                                                // loop through the elements of the sequence
                                                                while (seq)
                                                                {
                                                                    SElement * gr = (SElement *) seq->object->group;
                                                                    
                                                                    switch( gr->group)
                                                                    {
                                                                        case 0x0020:
                                                                        {
                                                                            valc = Papy3GetElement ( gr, papTriggerDelayTime, &nbVal, &itemType);
                                                                            if (itemType == FD)
                                                                                [imageCardiacTriggerArray addObject: [NSString stringWithFormat: @"%lf", valc->fd]];
                                                                        }
                                                                    }
                                                                    
                                                                    // get the next element of the list
                                                                    seq = seq->next;
                                                                }
                                                            }
                                                        }
                                                        break;
                                                        
                                                    case 0x0020:
                                                        valb = Papy3GetElement (gr, papPlanePositionVolumeSequence, &nbVal, &itemType);
                                                        if (valb != NULL && nbVal >= 1)
                                                        {
                                                            // there is a sequence
                                                            if (valb->sq)
                                                            {
                                                                // get a pointer to the first element of the list
                                                                Papy_List *seq = valb->sq->object->item;
                                                                
                                                                // loop through the elements of the sequence
                                                                while (seq)
                                                                {
                                                                    SElement * gr = (SElement *) seq->object->group;
                                                                    
                                                                    switch( gr->group)
                                                                    {
                                                                        case 0x0020:
                                                                            valc = Papy3GetElement ( gr, papImagePositionVolumeGr, &nbVal, &itemType);
                                                                            if (valc != NULL && itemType == FD && nbVal == 3)
                                                                            {
                                                                                originMultiFrame[0] = valc++->fd;
                                                                                originMultiFrame[1] = valc++->fd;
                                                                                originMultiFrame[2] = valc++->fd;
                                                                            }
                                                                        break;
                                                                    }
                                                                    
                                                                    // get the next element of the list
                                                                    seq = seq->next;
                                                                }
                                                            }
                                                        }
                                                        
                                                        valb = Papy3GetElement (gr, papPlanePositionSequence, &nbVal, &itemType);
                                                        if (valb != NULL && nbVal >= 1)
                                                        {
                                                            // there is a sequence
                                                            if (valb->sq)
                                                            {
                                                                // get a pointer to the first element of the list
                                                                Papy_List *seq = valb->sq->object->item;
                                                                
                                                                // loop through the elements of the sequence
                                                                while (seq)
                                                                {
                                                                    SElement * gr = (SElement *) seq->object->group;
                                                                    
                                                                    switch( gr->group)
                                                                    {
                                                                        case 0x0020:
                                                                            valc = Papy3GetElement ( gr, papImagePositionPatientGr, &nbVal, &itemType);
                                                                            if (valc != NULL && valc->a && validAPointer( itemType) && nbVal == 3)
                                                                            {
                                                                                originMultiFrame[0] = [[NSString stringWithCString:valc++->a encoding: NSISOLatin1StringEncoding] floatValue];
                                                                                originMultiFrame[1] = [[NSString stringWithCString:valc++->a encoding: NSISOLatin1StringEncoding] floatValue];
                                                                                originMultiFrame[2] = [[NSString stringWithCString:valc++->a encoding: NSISOLatin1StringEncoding] floatValue];
                                                                            }
                                                                        break;
                                                                    }
                                                                    
                                                                    // get the next element of the list
                                                                    seq = seq->next;
                                                                }
                                                            }
                                                        }
                                                        
                                                        valb = Papy3GetElement (gr, papPlaneOrientationSequence, &nbVal, &itemType);
                                                        if (valb != NULL && nbVal >= 1)
                                                        {
                                                            // there is a sequence
                                                            if (valb->sq)
                                                            {
                                                                // get a pointer to the first element of the list
                                                                Papy_List *seq = valb->sq->object->item;
                                                                
                                                                // loop through the elements of the sequence
                                                                while (seq)
                                                                {
                                                                    SElement * gr = (SElement *) seq->object->group;
                                                                    
                                                                    switch( gr->group)
                                                                    {
                                                                        case 0x0020:
                                                                        {
                                                                            valc = Papy3GetElement( gr, papImageOrientationPatientGr, &nbVal, &itemType);
                                                                            if (valc != NULL && valc->a && validAPointer( itemType) && nbVal == 6)
                                                                            {
                                                                                for (int j = 0; j < nbVal; j++)
                                                                                    orientationMultiFrame[ j]  = [[NSString stringWithCString: valc++->a encoding: NSISOLatin1StringEncoding] floatValue];
                                                                            }
                                                                        }
                                                                        break;
                                                                    }
                                                                    
                                                                    // get the next element of the list
                                                                    seq = seq->next;
                                                                }
                                                            }
                                                        }
                                                        
                                                        // Compute normal vector
                                                        orientationMultiFrame[ 6] = orientationMultiFrame[ 1]*orientationMultiFrame[ 5] - orientationMultiFrame[ 2]*orientationMultiFrame[ 4];
                                                        orientationMultiFrame[ 7] = orientationMultiFrame[ 2]*orientationMultiFrame[ 3] - orientationMultiFrame[ 0]*orientationMultiFrame[ 5];
                                                        orientationMultiFrame[ 8] = orientationMultiFrame[ 0]*orientationMultiFrame[ 4] - orientationMultiFrame[ 1]*orientationMultiFrame[ 3];
                                                        
                                                        float location = 0;
                                                        
                                                        if( fabs( orientationMultiFrame[ 6]) > fabs(orientationMultiFrame[ 7]) && fabs( orientationMultiFrame[ 6]) > fabs(orientationMultiFrame[ 8]))
                                                            location = originMultiFrame[ 0];
                                                        
                                                        if( fabs( orientationMultiFrame[ 7]) > fabs(orientationMultiFrame[ 6]) && fabs( orientationMultiFrame[ 7]) > fabs(orientationMultiFrame[ 8]))
                                                            location = originMultiFrame[ 1];
                                                        
                                                        if( fabs( orientationMultiFrame[ 8]) > fabs(orientationMultiFrame[ 6]) && fabs( orientationMultiFrame[ 8]) > fabs(orientationMultiFrame[ 7]))
                                                            location = originMultiFrame[ 2];
                                                        
                                                        [sliceLocationArray addObject: [NSNumber numberWithFloat: location]];
                                                        
                                                        break;
                                                } // switch( gr->group)
                                            } // if( groupsForFrame->object->item)
                                            
                                            if( groupsForFrame)
                                            {
                                                // get the next element of the list
                                                groupsForFrame = groupsForFrame->next;
                                            }
                                        } // while groupsForFrame
                                    }
                                }
                                
                                if( dcmList)
                                {
                                    // get the next element of the list
                                    dcmList = dcmList->next;
                                    
                                    frameCount++;
                                }
                            } // while ...loop through the sequence
                            
                            if( sliceLocationArray.count)
                            {
                                if( NoOfFrames == sliceLocationArray.count)
                                    [dicomElements setObject: sliceLocationArray forKey:@"sliceLocationArray"];
                                else
                                    NSLog( @"*** NoOfFrames != sliceLocationArray.count for MR/CT multiframe sliceLocation computation (%d, %d)", (int) NoOfFrames, (int) sliceLocationArray.count);
                            }
                            
                            if( imageCardiacTriggerArray.count)
                            {
                                if( NoOfFrames == imageCardiacTriggerArray.count)
                                    [dicomElements setObject: imageCardiacTriggerArray forKey:@"imageCommentPerFrame"];
                                else
                                    NSLog( @"*** NoOfFrames != imageCardiacTriggerArray.count for MR/CT multiframe image type frame computation (%d, %d)", (int) NoOfFrames, (int) imageCardiacTriggerArray.count);
                                
                            }
                        } // if ...there is a sequence of groups
                    } // if ...val is not NULL
                    
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                    
                    if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
                }
                
                if( patientID == nil) patientID = [[NSString alloc] initWithString:@""];
            }
            
            // Go to groups 0x0042 for Encapsulated Document Possible PDF
            if ([sopClassUID isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
            {
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0042);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    SElement *element = theGroupP + papEncapsulatedDocumentGr;
                    
                    if( element->nb_val > 0 && validAPointer( element->vr) && element->value->a)
                    {
                        NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData: [NSData dataWithBytes: element->value->a length: element->length]];
                        NoOfFrames = [rep pageCount];
                        
                        NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
                        [pdfImage addRepresentation: rep];
                        
                        NSBitmapImageRep *bitRep = [NSBitmapImageRep imageRepWithData: [pdfImage TIFFRepresentation]];
                        
                        if( bitRep.pixelsWide > pdfImage.size.width)
                        {
                            height = bitRep.pixelsHigh;
                            width = bitRep.pixelsWide;
                        }
                        else
                        {
                            height = pdfImage.size.height;
                            width = pdfImage.size.width;
                        }
                    }
                    
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
            }
            
    #ifdef OSIRIX_VIEWER
    #ifndef OSIRIX_LIGHT
            if( [sopClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"]) // DICOM SR
            {
                if( [DicomStudy displaySeriesWithSOPClassUID: sopClassUID andSeriesDescription: [dicomElements objectForKey: @"seriesDescription"]])
                {
                    @try
                    {
                        NSPDFImageRep *rep = [self PDFImageRep];
                        
                        NoOfFrames = [rep pageCount];
                        
                        NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
                        [pdfImage addRepresentation: rep];
                        
                        NSBitmapImageRep *bitRep = [NSBitmapImageRep imageRepWithData: [pdfImage TIFFRepresentation]];
                        
                        if( bitRep.pixelsWide > pdfImage.size.width)
                        {
                            height = bitRep.pixelsHigh;
                            width = bitRep.pixelsWide;
                        }
                        else
                        {
                            height = pdfImage.size.height;
                            width = pdfImage.size.width;
                        }
                    }
                    @catch (NSException * e)
                    {
                        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
                    }
                }
                
                @try
                {
                    if( [[dicomElements objectForKey: @"seriesDescription"] hasPrefix: @"OsiriX ROI SR"])
                    {
                        NSString *referencedSOPInstanceUID = [SRAnnotation getImageRefSOPInstanceUID: filePath];
                        if( referencedSOPInstanceUID)
                            [dicomElements setObject: referencedSOPInstanceUID forKey: @"referencedSOPInstanceUID"];
                        
                        int numberOfROIs = [[NSUnarchiver unarchiveObjectWithData: [SRAnnotation roiFromDICOM: filePath]] count];
                        [dicomElements setObject: [NSNumber numberWithInt: numberOfROIs] forKey: @"numberOfROIs"];
                    }
                }
                @catch (NSException * e)
                {
                    NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
                }
            }
    #endif
    #endif
            
            if( COMMENTSFROMDICOMFILES)
            {
                theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x4008);
                if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
                {
                    val = Papy3GetElement (theGroupP, papInterpretationStatusIDGr, &nbVal, &itemType);
                    if (val != NULL && val->a && validAPointer( itemType) && strlen( val->a) > 0)
                        [dicomElements setObject: [NSNumber numberWithInt: [[NSString stringWithCString: val->a encoding: NSASCIIStringEncoding] intValue]] forKey: @"stateText"];
                    
                    theErr = Papy3GroupFree (&theGroupP, TRUE);
                }
            }
            
            // close and free the file and the associated allocated memory 
            Papy3FileClose (fileNb, TRUE);
            
            if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
                self.serieID = [NSString stringWithFormat:@"%@-%@-%@", self.serieID, imageID, [dicomElements objectForKey:@"SOPUID"]];
            
            [dicomElements setObject:[self patientUID] forKey:@"patientUID"];
            
            if( self.serieID == nil) self.serieID = name;
            
            if( [Modality isEqualToString:@"US"] && oneFileOnSeriesForUS)
            {
                [dicomElements setObject: [self.serieID stringByAppendingString: [filePath lastPathComponent]] forKey:@"seriesID"];
            }
            else if (combineProjectionSeries && ([Modality isEqualToString:@"MG"] || [Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]))
            {
                if( combineProjectionSeriesMode == 0)		// *******Combine all CR and DR Modality series in a study into one series
                {
                    if( sopClassUID != nil && [[DCMAbstractSyntaxUID hiddenImageSyntaxes] containsObject: sopClassUID])
                        [dicomElements setObject: self.serieID forKey:@"seriesID"];
                    else
                        [dicomElements setObject: studyID forKey: @"seriesID"];
                    
                    [dicomElements setObject: [NSNumber numberWithLong: [self.serieID intValue] * 1000 + [imageID intValue]] forKey: @"imageID"];
                }
                else if( combineProjectionSeriesMode == 1)	// *******Split all CR and DR Modality series in a study into one series
                {
                    [dicomElements setObject: [self.serieID stringByAppendingString: imageID] forKey:@"seriesID"];
                }
                else NSLog( @"ARG! ERROR !? Unknown combineProjectionSeriesMode");
            }
            else
                [dicomElements setObject: self.serieID forKey:@"seriesID"];
            
            if( studyID == nil)
            {
                studyID = [[NSString alloc] initWithString:name];
                [dicomElements setObject:studyID forKey:@"studyID"];
            }
            
            if( imageID == nil)
            {
                imageID = [[NSString alloc] initWithString:name];
                [dicomElements setObject:imageID forKey:@"SOPUID"];
            }
            
            if( date == nil)
            {
                date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil] retain];
                [dicomElements setObject:date forKey:@"studyDate"];
            }
            
            [dicomElements setObject:[NSNumber numberWithBool:YES] forKey:@"hasDICOM"];
            
            if( serie == nil)
                serie = [@"unnamed" retain];
            
            [dicomElements setObject:serie forKey:@"seriesDescription"];
            
            if( [[dicomElements objectForKey: @"studyDescription"] isEqualToString: @"unnamed"])
            {
                [study release];
                study = [[NSString alloc] initWithString: serie];
                [dicomElements setObject:study forKey: @"studyDescription"];
            }
            
            if( name != nil && studyID != nil && self.serieID != nil && imageID != nil && width != 0 && height != 0)
            {
                returnValue = 0;   // success
            }
        }
        
        if( converted)
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:converted])
                [[NSFileManager defaultManager] removeItemAtPath: converted error: nil];
        }
        else
        {
            if( forceConverted == NO && returnValue != 0)
                returnValue = [self getDicomFilePapyrus: YES];
        }
    }
    @catch (...)
    {
        @throw;
    }
    @finally
    {
        [PapyrusLock unlock];
    }

    return returnValue;
}

-(short) getDicomFile
{
	BOOL isCD = NO;
	
	if( PREFERPAPYRUSFORCD)
		isCD = filesAreFromCDMedia;

	if( TOOLKITPARSER == 1 || isCD == YES) return [self getDicomFilePapyrus: NO];
	
	#ifndef OSIRIX_LIGHT
	if( TOOLKITPARSER == 0) return [self decodeDICOMFileWithDCMFramework];
	#else
	if( TOOLKITPARSER == 0) return [self getDicomFilePapyrus: NO];
	#endif
	
	if( TOOLKITPARSER == 2) return [self getDicomFileDCMTK];
	
	return [self getDicomFileDCMTK];
}

#ifndef OSIRIX_LIGHT
-(short) decodeDICOMFileWithDCMFramework
{
	BOOL returnValue = -1;
	long cardiacTime = -1;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DCMObject *dcmObject;
	
	if (COMMENTSAUTOFILL == YES) // || CHECKFORLAVIM == YES)
		dcmObject = [DCMObject objectWithContentsOfFile:filePath decodingPixelData:NO];
	else
		dcmObject = [DCMObjectDBImport objectWithContentsOfFile:filePath decodingPixelData:NO];
	   
	if (dcmObject)
	{
		if (COMMENTSAUTOFILL == YES) // || CHECKFORLAVIM == YES)
		{
			if( COMMENTSAUTOFILL)
			{
                NSString *commentsField = nil, *grel = nil;
                id field = nil;
                
                if( COMMENTSGROUP && COMMENTSELEMENT)
                {
                    grel = [NSString stringWithFormat:@"%04X,%04X", COMMENTSGROUP, COMMENTSELEMENT];
                    if(( field = [dcmObject attributeValueForKey: grel]))
                    {
                        if( [field isKindOfClass: [NSString class]])
                            commentsField = [NSString stringWithString: field];
                        
                        if( [field isKindOfClass: [NSNumber class]])
                            commentsField = [field stringValue];
                        
                        if( [field isKindOfClass: [NSCalendarDate class]])
                            commentsField = [field description];
                    }
                }
                
                if( COMMENTSGROUP2 && COMMENTSELEMENT2)
                {
                    grel = [NSString stringWithFormat:@"%04X,%04X", COMMENTSGROUP2, COMMENTSELEMENT2];
                    if(( field = [dcmObject attributeValueForKey: grel]))
                    {
                        NSString *value = nil;
                        
                        if( [field isKindOfClass: [NSString class]])
                            value = [NSString stringWithString: field];
                        
                        if( [field isKindOfClass: [NSNumber class]])
                            value = [field stringValue];
                        
                        if( [field isKindOfClass: [NSCalendarDate class]])
                            value = [field description];
                        
                        if( value)
                        {
                            if( commentsField)
                                commentsField = [commentsField stringByAppendingFormat: @" / %@", value];
                            else
                                commentsField = value;
                        }
                    }
                }
                
                if( COMMENTSGROUP3 && COMMENTSELEMENT3)
                {
                    grel = [NSString stringWithFormat:@"%04X,%04X", COMMENTSGROUP3, COMMENTSELEMENT3];
                    if(( field = [dcmObject attributeValueForKey: grel]))
                    {
                        NSString *value = nil;
                        
                        if( [field isKindOfClass: [NSString class]])
                            value = [NSString stringWithString: field];
                        
                        if( [field isKindOfClass: [NSNumber class]])
                            value = [field stringValue];
                        
                        if( [field isKindOfClass: [NSCalendarDate class]])
                            value = [field description];
                        
                        if( value)
                        {
                            if( commentsField)
                                commentsField = [commentsField stringByAppendingFormat: @" / %@", value];
                            else
                                commentsField = value;
                        }
                    }
                }
                
                if( COMMENTSGROUP4 && COMMENTSELEMENT4)
                {
                    grel = [NSString stringWithFormat:@"%04X,%04X", COMMENTSGROUP4, COMMENTSELEMENT4];
                    if(( field = [dcmObject attributeValueForKey: grel]))
                    {
                        NSString *value = nil;
                        
                        if( [field isKindOfClass: [NSString class]])
                            value = [NSString stringWithString: field];
                        
                        if( [field isKindOfClass: [NSNumber class]])
                            value = [field stringValue];
                        
                        if( [field isKindOfClass: [NSCalendarDate class]])
                            value = [field description];
                        
                        if( value)
                        {
                            if( commentsField)
                                commentsField = [commentsField stringByAppendingFormat: @" / %@", value];
                            else
                                commentsField = value;
                        }
                    }
                }
                
                if( commentsField)
                    [dicomElements setObject: commentsField forKey:@"commentsAutoFill"];
			}
            
//			if( CHECKFORLAVIM == YES)
//			{
//				//Le nom de l'Žtude peut se trouver dans plusieurs champs DICOM, suivant la modalitŽ de l'examen.
//				//IRM :	0x0040:0x0280
//				//CT Philips :	0x0040:0x1400
//				//CT GE :	Pas encore dŽfini
//				//Autres modalitŽs :	A dŽfinir.
//				NSString			*field = nil, *album = nil;
//				
//				field = [dcmObject attributeValueForKey: @"0020,4000"];
//				if( field)
//				{
//					if( [field length] >= 2)
//						if( [[field substringToIndex:2] isEqualToString: @"LV"])
//							album = [field substringFromIndex:2];
//				}
//				
//				field = [dcmObject attributeValueForKey: @"0040,0280"];
//				if( field)
//				{
//					if( [field length] >= 2)
//						if( [[field substringToIndex:2] isEqualToString: @"LV"])
//							album = [field substringFromIndex:2];
//				}
//				
//				field = [dcmObject attributeValueForKey: @"0040,1400"];
//				if( field)
//				{
//					if( [field length] >= 2)
//						if( [[field substringToIndex:2] isEqualToString: @"LV"])
//							album = [field substringFromIndex:2];
//				}
//				
//				if( album) [dicomElements setObject:album forKey:@"album"];
//			}
		}
		
		NSString *transferSyntaxUID = [dcmObject attributeValueWithName:@"TransferSyntaxUID"];
		if( [transferSyntaxUID isEqualToString:@"1.2.840.10008.1.2.4.100"])
		{
			fileType = [@"DICOMMPEG2" retain];
			[dicomElements setObject:fileType forKey:@"fileType"];
		}
		else
		{
			fileType = [@"DICOM" retain];
			[dicomElements setObject:fileType forKey:@"fileType"];
		}
        
        NSString* privateInformationCreatorUID = [dcmObject attributeValueWithName:@"PrivateInformationCreatorUID"];
        if (privateInformationCreatorUID.length)
            [dicomElements setObject:privateInformationCreatorUID forKey:@"PrivateInformationCreatorUID"];
		
		NSMutableArray	*imageTypeArray = [NSMutableArray arrayWithArray: [dcmObject attributeArrayWithName:@"ImageType"]];
		if( [imageTypeArray count] > 2)
		{
			if((imageType = [[[dcmObject attributeArrayWithName:@"ImageType"] objectAtIndex: 2] retain])) //ImageType		
				[dicomElements setObject:imageType forKey:@"imageType"];
		}
			
		if((SOPUID =[[dcmObject attributeValueForKey:@"0008,0018"] retain]))	//SOPInstanceUID 
			[dicomElements setObject:SOPUID forKey:@"SOPUID"];
			
		if((study = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"StudyDescription"]] retain]))
			[dicomElements setObject:study forKey:@"studyDescription"];
		else
		{
			study = [@"unnamed" retain];
			[dicomElements setObject:study forKey:@"studyDescription"];
		}
		
		if((Modality = [[dcmObject attributeValueWithName:@"Modality"] retain]))
			[dicomElements setObject:Modality forKey:@"modality"];
		else
		{
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
		if (acqDate && acqTime)
		{
			if( [acqTime length] >= 6)
				date = [[NSCalendarDate alloc] initWithString:[acqDate stringByAppendingString:acqTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[acqDate stringByAppendingString:acqTime] calendarFormat:@"%Y%m%d%H%M"];
		}
        else if (contDate && contTime)
		{
			if( [contTime length] >= 6)
				date = [[NSCalendarDate alloc] initWithString:[contDate stringByAppendingString:contTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[contDate stringByAppendingString:contTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else if (seriesDate && seriesTime)
		{
			if( [seriesTime length] >= 6)
				date = [[NSCalendarDate alloc] initWithString:[seriesDate stringByAppendingString:seriesTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[seriesDate stringByAppendingString:seriesTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else if (studyDate && studyTime)
		{
			if( [studyTime length] >= 6)
				date = [[NSCalendarDate alloc] initWithString:[studyDate stringByAppendingString:studyTime] calendarFormat:@"%Y%m%d%H%M%S"];
			else
				date = [[NSCalendarDate alloc] initWithString:[studyDate stringByAppendingString:studyTime] calendarFormat:@"%Y%m%d%H%M"];
		}
		else
		{
			date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil] retain];
		}
		
		[dicomElements setObject:date forKey:@"studyDate"];
		
		//JF20070103 if series title doesn't exist, replace it by series number, and the latter doesn't exist, keep unnamed
		
		BOOL modalityNoSC = TRUE; //JF20070103
		
		if ([[dcmObject attributeValueForKey:@"0008,0018"] isEqualToString:@"1.2.840.10008.5.1.4.1.1.7"] == YES) modalityNoSC=FALSE; //JF20070103
		
		if ((serie = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"SeriesDescription"]] retain]))
			[dicomElements setObject:serie forKey:@"seriesDescription"];
		else if ((serie = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"instanceNumber"]] retain]) && modalityNoSC)
			[dicomElements setObject:serie forKey:@"seriesDescription"]; //JF20070103
		else if (!modalityNoSC) serie = [@"unnamed" retain]; //JF20070103 		
		else
		{
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
			
		if ((name = [[DicomFile NSreplaceBadCharacter: [dcmObject attributeValueWithName:@"PatientsName"]] retain]))
			[dicomElements setObject:name forKey:@"patientName"];
		else
		{
			name = [@"No name" retain];
			[dicomElements setObject:name forKey:@"patientName"];
		}
			
		if ((patientID = [[dcmObject attributeValueWithName:@"PatientID"] retain]))
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PatientID"] forKey:@"patientID"];
		else
		{
			patientID = [@"" retain];
			[dicomElements setObject:patientID forKey:@"patientID"];
		}
			
		if ([dcmObject attributeValueWithName:@"PatientsAge"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PatientsAge"] forKey:@"patientAge"];
			
		if ([dcmObject attributeValueWithName:@"PatientsBirthDate"])
			[dicomElements setObject:(NSDate *)[dcmObject attributeValueWithName:@"PatientsBirthDate"] forKey:@"patientBirthDate"];
			
		if ([dcmObject attributeValueWithName:@"PatientsSex"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"PatientsSex"] forKey:@"patientSex"];
			
		if ([dcmObject attributeValueWithName:@"ScanOptions"])
		{
			NSString *scanOptions = [dcmObject attributeValueWithName:@"ScanOptions"];
			if ([scanOptions length] >= 4 && [scanOptions hasPrefix:@"TP"])
			{
				NSString *cardiacString = [scanOptions substringWithRange:NSMakeRange(2,2)];
				cardiacTime = [cardiacString intValue];	
				[dicomElements setObject:[NSNumber numberWithLong: cardiacTime] forKey:@"cardiacTime"];			
			}
		}
		
		if ([dcmObject attributeValueWithName:@"ProtocolName"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"ProtocolName"] forKey:@"protocolName"];
		
//		if ([dcmObject attributeValueWithName:@"Manufacturer"])
//		{
//			NSString *manufacturer = [dcmObject attributeValueWithName:@"Manufacturer"];
//			if( [manufacturer hasPrefix: @"MAC:"])
//				[dicomElements setObject: manufacturer forKey:@"manufacturer"];
//		}
		
		if ((imageID = [dcmObject attributeValueWithName:@"InstanceNumber"]))
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
		
		if( imageID == nil || [imageID intValue] >= 99999)
		{
			int val = 10000 + location*10.;
			imageID = [[NSString alloc] initWithFormat:@"%5d", val];
		}
		[dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];
		
		// Series Number
		
		if ((seriesNo = [[dcmObject attributeValueWithName:@"SeriesNumber"] retain]))
		{
		}
		else
			seriesNo = [[NSString alloc] initWithString: @"0"];
		[dicomElements setObject:[NSNumber numberWithInt:[seriesNo intValue]] forKey:@"seriesNumber"];
			
		if ((self.serieID = [dcmObject attributeValueWithName:@"SeriesInstanceUID"]))
		{
			[dicomElements setObject: self.serieID forKey:@"seriesDICOMUID"];
		}
			
		if ((studyID = [[dcmObject attributeValueWithName:@"StudyInstanceUID"] retain]))
			[dicomElements setObject:[dcmObject attributeValueWithName:@"StudyInstanceUID"] forKey:@"studyID"];
			
		if ((studyIDs = [[dcmObject attributeValueWithName:@"StudyID"] retain]))
		{
		}
		else 
			studyIDs = [@"0" retain];
		[dicomElements setObject:studyIDs forKey:@"studyNumber"];
		
		if( COMMENTSFROMDICOMFILES)
		{
			if( [dcmObject attributeValueWithName: @"StudyComments"])
				[dicomElements setObject: [dcmObject attributeValueWithName: @"StudyComments"] forKey: @"studyComments"];
		
			if( [dcmObject attributeValueWithName: @"ImageComments"])
				[dicomElements setObject: [dcmObject attributeValueWithName: @"ImageComments"] forKey: @"seriesComments"];
		}
		
		if( COMMENTSFROMDICOMFILES)
		{
			if( [dcmObject attributeValueWithName: @"InterpretationStatusID"])
				[dicomElements setObject: [NSNumber numberWithInt: [[dcmObject attributeValueWithName: @"InterpretationStatusID"] intValue]] forKey: @"stateText"];
		}
		
		if ([dcmObject attributeValueWithName:@"NumberofFrames"])
			NoOfFrames = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
		else
			NoOfFrames = 1;
		
		if( [dcmObject attributeValueWithName:@"SOPClassUID"])
			[dicomElements setObject:[dcmObject attributeValueWithName:@"SOPClassUID"] forKey:@"SOPClassUID"];
		
		// *********** WARNING : SERIESID MUST BE IDENTICAL BETWEEN DCMFRAMEWORK & PAPYRUS TOOLKIT !!!!! OTHERWISE muliple identical series will be created during DATABASE rebuild !
				
		if( cardiacTime != -1 && SEPARATECARDIAC4D == YES)  // For new Cardiac-CT Siemens series
			self.serieID = [NSString stringWithFormat:@"%@ %2.2d", self.serieID , (int) cardiacTime];
        
		if( seriesNo)
			self.serieID = [NSString stringWithFormat:@"%8.8d %@", [seriesNo intValue] , self.serieID];
		
		if( imageType != 0 && useSeriesDescription)
			self.serieID = [NSString stringWithFormat:@"%@ %@", self.serieID , imageType];
		
		if( serie != nil && useSeriesDescription)
			self.serieID = [NSString stringWithFormat:@"%@ %@", self.serieID , serie];
        
        if( [dcmObject attributeValueWithName: @"SOPClassUID"] != nil && [[DCMAbstractSyntaxUID hiddenImageSyntaxes] containsObject: [dcmObject attributeValueWithName: @"SOPClassUID"]])
			self.serieID = [NSString stringWithFormat:@"%@ %@", self.serieID , [dcmObject attributeValueWithName: @"SOPClassUID"]];
		
		if( NOLOCALIZER && ([self containsString: @"LOCALIZER" inArray: imageTypeArray] || [self containsString: @"REF" inArray: imageTypeArray] || [self containsLocalizerInString: serie]) && [DCMAbstractSyntaxUID isImageStorage: [dcmObject attributeValueWithName: @"SOPClassUID"]])
		{
			self.serieID = @"LOCALIZER";
			
			[serie release];
			serie = [[NSString alloc] initWithString: @"Localizers"];
			[dicomElements setObject:serie forKey:@"seriesDescription"];
			
			[dicomElements setObject: [self.serieID stringByAppendingString: studyID] forKey: @"seriesDICOMUID"];
		}
		
		NoOfSeries = 1;
		
		[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
		[dicomElements setObject:[NSNumber numberWithBool:YES] forKey:@"hasDICOM"];
		
		returnValue = 0;
		
		width = [[dcmObject attributeValueWithName:@"Columns"] intValue];
		height = [[dcmObject attributeValueWithName:@"Rows"] intValue];
		
		if( [[dcmObject attributeValueWithName: @"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
		{
			NSData *pdfData = [dcmObject attributeValueWithName: @"EncapsulatedDocument"];
			NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData:pdfData];						
			NoOfFrames = [rep pageCount];
			
			NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
            [pdfImage addRepresentation: rep];
            
            NSBitmapImageRep *bitRep = [NSBitmapImageRep imageRepWithData: [pdfImage TIFFRepresentation]];
            
            if( bitRep.pixelsWide > pdfImage.size.width)
            {
                height = bitRep.pixelsHigh;
                width = bitRep.pixelsWide;
            }
            else
            {
                height = pdfImage.size.height;
                width = pdfImage.size.width;
            }
		}
		
		#ifdef OSIRIX_VIEWER
		#ifndef OSIRIX_LIGHT
		if( [[dcmObject attributeValueWithName: @"SOPClassUID"] hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"])
		{
			if( [DicomStudy displaySeriesWithSOPClassUID: [dcmObject attributeValueWithName: @"SOPClassUID"] andSeriesDescription: [dicomElements objectForKey: @"seriesDescription"]])
			{
				@try
				{
					NSPDFImageRep *rep = [self PDFImageRep];
					
					NoOfFrames = [rep pageCount];
					
                    NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
                    [pdfImage addRepresentation: rep];
                    
                    NSBitmapImageRep *bitRep = [NSBitmapImageRep imageRepWithData: [pdfImage TIFFRepresentation]];
                    
                    if( bitRep.pixelsWide > pdfImage.size.width)
                    {
                        height = bitRep.pixelsHigh;
                        width = bitRep.pixelsWide;
                    }
                    else
                    {
                        height = pdfImage.size.height;
                        width = pdfImage.size.width;
                    }
				}
				@catch (NSException * e)
				{
                    N2LogExceptionWithStackTrace(e);
				}
				
				@try
				{
					if( [[dicomElements objectForKey: @"seriesDescription"] hasPrefix: @"OsiriX ROI SR"])
					{
						NSString *referencedSOPInstanceUID = [SRAnnotation getImageRefSOPInstanceUID: filePath];
						if( referencedSOPInstanceUID)
							[dicomElements setObject: referencedSOPInstanceUID forKey: @"referencedSOPInstanceUID"];
						
						int numberOfROIs = [[NSUnarchiver unarchiveObjectWithData: [SRAnnotation roiFromDICOM: filePath]] count];
						[dicomElements setObject: [NSNumber numberWithInt: numberOfROIs] forKey: @"numberOfROIs"];
					}
				}
				@catch (NSException * e)
				{
                    N2LogExceptionWithStackTrace(e);
				}
			}
		}
		#endif
		#endif
		
		NSString *echoTime = nil;
		
		if ((echoTime = [dcmObject attributeValueWithName:@"EchoTime"])  && splitMultiEchoMR)
			self.serieID = [NSString stringWithFormat:@"%@ TE-%@", self.serieID, echoTime];
		
		if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
			self.serieID = [NSString stringWithFormat:@"%@-%@-%@", self.serieID, imageID, [dicomElements objectForKey:@"SOPUID"]];
		
		if( self.serieID == nil)
			self.serieID = name;
		
		if( [Modality isEqualToString:@"US"] && oneFileOnSeriesForUS)
		{
			[dicomElements setObject: [self.serieID stringByAppendingString: [filePath lastPathComponent]] forKey:@"seriesID"];
		}
		else if( combineProjectionSeries && ([Modality isEqualToString:@"MG"] || [Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]))
		{
			if( combineProjectionSeriesMode == 0)		// *******Combine all CR and DR Modality series in a study into one series
			{
                if( [dcmObject attributeValueWithName: @"SOPClassUID"] != nil && [[DCMAbstractSyntaxUID hiddenImageSyntaxes] containsObject: [dcmObject attributeValueWithName: @"SOPClassUID"]])
                    [dicomElements setObject:self.serieID forKey:@"seriesID"];
                else
                    [dicomElements setObject:studyID forKey:@"seriesID"];
                
				[dicomElements setObject:[NSNumber numberWithLong: [self.serieID intValue] * 1000 + [imageID intValue]] forKey:@"imageID"];
			}
			else if( combineProjectionSeriesMode == 1)	// *******Split all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject: [self.serieID stringByAppendingString: imageID] forKey:@"seriesID"];
			}
			else NSLog( @"ARG! ERROR !? Unknown combineProjectionSeriesMode");
		}
		else
			[dicomElements setObject:self.serieID forKey:@"seriesID"];
		
		if (width < 4)
			width = 4;
		if (height < 4)
			height = 4;
	}
	
	[pool release];
	
	return returnValue;
}
#endif

- (id) initRandom
{
	id returnVal = nil;
	
	if( self = [super init])
	{
		[DicomFile setDefaults];
		
		//width and height need to greater than 0 or get validation errors
		
		width = 1;
		height = 1;
		filePath = [[NSString alloc] initWithFormat:@"protp/aksidkoa/saodkireks/ksidjaiskd/orkerofk%d", (int) random()];
		NoOfSeries = 1;
		
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
		[dicomElements setObject:filePath forKey:@"filePath"];
	}
	
	return returnVal;
}

- (id) init:(NSString*) f DICOMOnly:(BOOL) DICOMOnly
{
	id returnVal = nil;
//	NSLog(@"Init dicomFile: %d", DICOMOnly);
	if( self = [super init])
	{
		[DicomFile setDefaults];
		
		//width and height need to greater than 0 or get validation errors
		
		width = 1;
		height = 1;
		filePath = f;
		NoOfSeries = 1;
		
		[filePath retain];
		
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
				
				returnVal = nil;
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
			#ifndef DECOMPRESS_APP
			else if( [self getNIfTI] == 0)
			{
				returnVal = self;
			}
			#endif
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
				
				returnVal = nil;
			}
		}
	}
	
	if( returnVal)
	{
		[dicomElements setObject:[NSNumber numberWithInt: height] forKey:@"height"];
		[dicomElements setObject:[NSNumber numberWithInt: width] forKey:@"width"];
		[dicomElements setObject:[NSNumber numberWithInt: NoOfFrames] forKey:@"numberOfFrames"];
		[dicomElements setObject:[NSNumber numberWithInt: NoOfSeries] forKey:@"numberOfSeries"];
		[dicomElements setObject:f forKey:@"filePath"];
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
    self.serieID = nil;
    [imageID release];
    [Modality release];
	[dicomElements release];
	[fileType release];
	
    [super dealloc];
}

+ (NSString*) patientUID: (id) src
{
    [DicomFile setDefaults];
    
    NSString *patientName = @"";
    NSString *patientID = @"";
    NSString *patientBirthDate = @"";
    
    if( gUsePatientBirthDateForUID == NO && gUsePatientIDForUID == NO && gUsePatientNameForUID == NO)
        N2LogStackTrace( @"PatientUID requires at least one parameter.");
    
    if( gUsePatientNameForUID)
    {
        patientName = [[src valueForKey:@"patientName"] stringByReplacingOccurrencesOfString: @"-" withString: @" "];
        
        NSString *firstRepresentation = [[patientName componentsSeparatedByString: @"="] objectAtIndex: 0];
        
        if( firstRepresentation.length)
            patientName = firstRepresentation;
    }
    
    if( gUsePatientBirthDateForUID)
        patientBirthDate = [[NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[src valueForKey:@"patientBirthDate"] timeIntervalSinceReferenceDate]] descriptionWithCalendarFormat:@"%Y%m%d"];
    
    if( gUsePatientIDForUID)
        patientID = [src valueForKey:@"patientID"];
    
	NSString *string = [NSString stringWithFormat:@"%@-%@-%@", patientName, patientID, patientBirthDate];
	
	return [[DicomFile NSreplaceBadCharacter: string] uppercaseString];
}

- (NSString*) patientUID
{
	return [DicomFile patientUID: dicomElements];
}

- (long) NoOfFrames{ return NoOfFrames;}

- (NSMutableDictionary *) dicomElements
{
	return dicomElements;
}

- (id)elementForKey:(id)key
{
	return [dicomElements objectForKey:key];
}

- (short)getPluginFile
{
	#ifdef OSIRIX_VIEWER
	NSString	*extension = [[filePath pathExtension] lowercaseString];	
	NoOfFrames = 1;	
	
	id fileFormatBundle;
	
	if ((fileFormatBundle = [[PluginManager fileFormatPlugins] objectForKey:extension]))
	{
		fileType = [@"IMAGE" retain];
		
		PluginFileFormatDecoder *decoder = [[[fileFormatBundle principalClass] alloc] init];
        
        [PluginManager startProtectForCrashWithFilter: decoder];
        
		float *fImage = [decoder checkLoadAtPath:filePath];
		width = [[decoder width] floatValue];
		height = [[decoder height] floatValue];
		[self extractSeriesStudyImageNumbersFromFileName:[[filePath lastPathComponent] stringByDeletingPathExtension]];
		
		if ([decoder patientName] != nil)
			name = [[decoder patientName] retain];
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
		date = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] fileCreationDate] retain];
		if( date == nil) date = [[NSDate date] retain];
        
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
			
		[dicomElements setObject:[self patientUID] forKey: @"patientUID"];

		if ([decoder seriesID])
			[dicomElements setObject:[decoder seriesID] forKey:@"seriesID"];
		else
			[dicomElements setObject:self.serieID forKey:@"seriesID"];

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
        
        [PluginManager endProtectForCrash];
        
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
			self.serieID = [tempString substringToIndex: [tempString length] -4];
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
			self.serieID = [tempString substringToIndex: [tempString length] -3];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -3]];
	}
	else if( strNo[ 2] >= '0' && strNo[ 2] <= '9' && strNo[ 3] >= '0' && strNo[ 3] <= '9')
	{
			// We HAVE a number with 2 digit at the end of the file!! Make a serie of it!
			strNo[0] = strNo[ 2];
			strNo[1] = strNo[ 3];
			strNo[2] = 0;
			
			imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
			self.serieID = [tempString substringToIndex: [tempString length] -2];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -2]];
	}
	else if( strNo[ 3] >= '0' && strNo[ 3] <= '9')
	{
			// We HAVE a number with 1 digit at the end of the file!! Make a serie of it!
			strNo[0] = strNo[ 3];
			strNo[1] = 0;
			
			imageID = [[NSString alloc] initWithCString: (char*) strNo encoding: NSASCIIStringEncoding];
			self.serieID = [tempString substringToIndex: [tempString length] -1];
			studyID = [[NSString alloc] initWithString: [tempString substringToIndex: [tempString length] -1]];
	}
	else
	{
			studyID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			self.serieID = [filePath lastPathComponent];
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
		
		CFRelease( sourceURL);
		
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
			CFTreeRef attributesTree;
			attributesTree = CFTreeGetChildAtIndex(cfXMLTree, 0);
			
			CFRelease( cfXMLTree);
			
			//NSLog(@"attributesTree: %@", attributesTree);
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
			fileType = [@"XMLDESCRIPTOR" retain];
			NoOfSeries = 1;
			NoOfFrames = [[xmlData objectForKey:@"numberOfImages"] intValue];
			
			studyID = [[xmlData objectForKey:@"studyID"] retain];
			self.serieID = [filePath lastPathComponent];
			imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
			SOPUID = [imageID retain];
			patientID = [[xmlData objectForKey:@"patientID"] retain];
			studyIDs = [studyID retain];
			seriesNo = [[NSString alloc] initWithString:@"0"];
			imageType = nil;
			
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
			[dicomElements setObject:self.serieID forKey:@"seriesID"];
			[dicomElements setObject:[[[NSString alloc] initWithString:[filePath lastPathComponent]] autorelease] forKey:@"seriesDescription"];
			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
			[dicomElements setObject:fileType forKey:@"fileType"];
			[dicomElements setObject:f forKey:@"filePath"];
			
			NSLog(@"dicomElements : %@", dicomElements);
		}
	}
	
	return self;
}

- (BOOL) commentsFromDICOMFiles
{
	return COMMENTSFROMDICOMFILES;
}

- (BOOL) autoFillComments
{
	return COMMENTSAUTOFILL;
}

- (BOOL) useSeriesDescription
{
	return useSeriesDescription;
}

- (BOOL) splitMultiEchoMR
{
	return splitMultiEchoMR;
}

- (BOOL) noLocalizer
{
	return NOLOCALIZER;
}

- (BOOL) oneFileOnSeriesForUS
{
	return oneFileOnSeriesForUS;
}

- (BOOL) combineProjectionSeries
{
	return combineProjectionSeries;
}

- (BOOL) combineProjectionSeriesMode
{
	return combineProjectionSeriesMode;
}

- (BOOL) separateCardiac4D
{
	return SEPARATECARDIAC4D;
}

//- (BOOL) checkForLAVIM
//{
//	if( CHECKFORLAVIM == YES) return YES;
//	
//	return NO;
//}

- (int)commentsGroup
{
	return COMMENTSGROUP;
}

- (int)commentsElement
{
	return COMMENTSELEMENT;
}

- (int)commentsGroup2
{
	return COMMENTSGROUP2;
}

- (int)commentsElement2
{
	return COMMENTSELEMENT2;
}

- (int)commentsGroup3
{
	return COMMENTSGROUP3;
}

- (int)commentsElement3
{
	return COMMENTSELEMENT3;
}

- (int)commentsGroup4
{
	return COMMENTSGROUP4;
}

- (int)commentsElement4
{
	return COMMENTSELEMENT4;
}

@end
