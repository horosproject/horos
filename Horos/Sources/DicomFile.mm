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

#include <stdio.h>

#include "options.h"
#include "url.h"
#import "DCMUIDs.h"

#ifndef OSIRIX_LIGHT
#include "FVTiff.h"
#endif
#import "MutableArrayCategory.h"
#import "SRAnnotation.h"
#import "SRAnnotation.h"
#import "DicomFile.h"
#import "ViewerController.h"
#import "PluginFileFormatDecoder.h"
#import "DCMCalendarDate.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCMSequenceAttribute.h"
#import "DICOMToNSString.h"
#import "DefaultsOsiriX.h"

#ifndef OSIRIX_LIGHT
#import <vtk_tiff.h>
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

#include <GDCM/gdcmScanner.h>

#include "Horos.h"

extern NSString * convertDICOM( NSString *inputfile);
extern NSRecursiveLock *PapyrusLock;

static BOOL DEFAULTSSET = NO;
static int TOOLKITPARSER = 1, PREFERPAPYRUSFORCD = 1;
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
    if (i > 0)
    {
        while( --i > 0)
        {
            if( str[i] ==' ') str[i] = 0;
            else i = 0;
        }
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

+ (NSString*) NSreplaceBadCharacter:(NSString*) str
{
    if( str == nil) return nil;
    
    NSMutableString	*mutableStr = [NSMutableString stringWithString: str];
    
    [mutableStr replaceOccurrencesOfString:@","   withString:@" " options:0 range:mutableStr.range];
    [mutableStr replaceOccurrencesOfString:@"^"   withString:@" " options:0 range:mutableStr.range];
    [mutableStr replaceOccurrencesOfString:@"/"   withString:@"-" options:0 range:mutableStr.range];
    [mutableStr replaceOccurrencesOfString:@"\r"  withString:@""  options:0 range:mutableStr.range];
    [mutableStr replaceOccurrencesOfString:@"\n"  withString:@""  options:0 range:mutableStr.range];
    [mutableStr replaceOccurrencesOfString:@"\""  withString:@"'" options:0 range:mutableStr.range];
    [mutableStr replaceOccurrencesOfString:@"   " withString:@" " options:0 range:mutableStr.range]; //tripple space -> single space
    [mutableStr replaceOccurrencesOfString:@"  "  withString:@" " options:0 range:mutableStr.range]; //double space -> single space
    
    unsigned long i = [mutableStr length];
    
    if (i > 0)
    {
        while( --i > 0)
        {
            if( [mutableStr characterAtIndex:i]==' ')
                [mutableStr deleteCharactersInRange:NSMakeRange(i, 1)];
            else
                i = 1;
        }
    }
    
    return mutableStr;
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
    int	i, from, len = (int)strlen(str), index;
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
    
    int fromLength = (int)strlen(str);
    
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
            int convertLength = (int)(currentChar - firstChar) - 1;
            
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
        int convertLength = (int)(currentChar - firstChar);
        if (convertLength > 0)
        {
            int convertLength = (int)(currentChar - firstChar);
            
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
            
            PREFERPAPYRUSFORCD = (int)[sd integerForKey: @"PREFERPAPYRUSFORCD"];
            TOOLKITPARSER = 2; // Always and only DCMTK. Papyrus has been removed from the project.
            
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
            [dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@BUNDLE_IDENTIFIER]];
            
            DEFAULTSSET = YES;
            
            PREFERPAPYRUSFORCD = [[dict objectForKey: @"PREFERPAPYRUSFORCD"] intValue];
            TOOLKITPARSER = [[dict objectForKey: @"TOOLKITPARSER4"] intValue];
            if( TOOLKITPARSER == 0)
                TOOLKITPARSER = 2;
            
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
    
    if( [extension isEqualToString:@"tiff"] ||
       [extension isEqualToString:@"stk"] ||
       [extension isEqualToString:@"tif"])
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
    
    if( [extension isEqualToString:@"tiff"] ||
       [extension isEqualToString:@"tif"])
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
    
    if( [extension isEqualToString:@"hdr"] ||
       [extension isEqualToString:@"nii"])
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


+ (BOOL) isDICOMFile:(NSString *) filePath compressed:(BOOL*) compressed image:(BOOL*) image
{
    if (compressed)
        *compressed = NO; // Assume it's not compressed
    
    if (image)
        *image = YES; // Assume it has pixel data
    
    //////////////////////////////////////////////////////////
    
    try
    {
        gdcm::Scanner theScanner;
        
        gdcm::Directory::FilenamesType filenames;
        filenames.push_back( std::string([filePath UTF8String]) );
        
        theScanner.AddTag(gdcm::Tag(0x0020, 0x000e));//Series UID
        if( !theScanner.Scan( filenames ) )
        {
            return NO;
        }
        
        if( !theScanner.IsKey( filenames[0].c_str() ) )
        {
            return NO;
        }
    }
    catch (...)
    {
        return NO;
    }
    
    //////////////////////////////////////////////////////////
    
    if (image)
    {
        @try
        {
            try
            {
                gdcm::Scanner theScanner;
                
                gdcm::Directory::FilenamesType filenames;
                filenames.push_back( std::string([filePath UTF8String]) );
                
                theScanner.AddTag(gdcm::Tag(0x7FE0, 0x0010));//Series UID
                if( !theScanner.Scan( filenames ) )
                {
                    return NO;
                }
                
                if( !theScanner.IsKey( filenames[0].c_str() ) )
                {
                    return NO;
                }
            }
            catch (...)
            {
                *image = NO;
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
            *image = NO;
        }
    }
    
    //////////////////////////////////////////////////////////
    
    if (compressed)
    {
        @try
        {
            NSString *transferSyntax = [DicomFile getDicomField: @"TransferSyntaxUID" forFile: filePath];
            if ([transferSyntax isEqualToString: DCM_JPEGLossless] ||
                [transferSyntax isEqualToString: DCM_JPEGBaseline] ||
                [transferSyntax isEqualToString: DCM_JPEG2000Lossy] ||
                [transferSyntax isEqualToString: DCM_JPEG2000Lossless] ||
                [transferSyntax isEqualToString: DCM_JPEGLSLossless] ||
                [transferSyntax isEqualToString: DCM_JPEGLSLossy])
            {
                *compressed = YES;
            }
            else
            {
                *compressed = NO;
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
            *compressed = NO;
        }
    }
    
    //////////////////////////////////////////////////////////

    return YES;
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
    
    if( [extension isEqualToString:@"tiff"] ||
       [extension isEqualToString:@"tif"])
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
                date = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] valueForKey:NSFileCreationDate] retain];
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
    
    
    if( [extension isEqualToString:@"tiff"] ||
       [extension isEqualToString:@"tif"] ||
       [extension isEqualToString:@"stk"] ||
       [extension isEqualToString:@"png"] ||
       [extension isEqualToString:@"jpg"] ||
       [extension isEqualToString:@"jpeg"] ||
       [extension isEqualToString:@"jp2"] ||
       [extension isEqualToString:@"pdf"] ||
       [extension isEqualToString:@"pct"] ||
       [extension isEqualToString:@"gif"])
    {
        NSImage		*otherImage = [[NSImage alloc] initWithContentsOfFile:filePath];
        if( otherImage || [extension isEqualToString:@"tiff"] || [extension isEqualToString:@"tif"])
        {
            // Try to identify a 2 digit number in the last part of the file.
            char				strNo[ 5];
            NSString			*tempString = [[filePath lastPathComponent] stringByDeletingPathExtension];
            
#ifndef STATIC_DICOM_LIB
#ifndef OSIRIX_LIGHT
            if( [extension isEqualToString:@"tiff"] ||
               [extension isEqualToString:@"stk"] ||
               [extension isEqualToString:@"tif"])
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
                @autoreleasepool
                {
                    CGImageRef cgRef = [otherImage CGImageForProposedRect:NULL context:nil hints:nil];
                    NSBitmapImageRep *r = [[[NSBitmapImageRep alloc] initWithCGImage:cgRef] autorelease];
                    [r setSize: otherImage.size];
                    
                    NSBitmapImageRep *TIFFRep = [NSBitmapImageRep imageRepWithData: [r TIFFRepresentation]];
                    
                    width = TIFFRep.pixelsWide;
                    height = TIFFRep.pixelsHigh;
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
    
    if( [extension isEqualToString:@"mov"] ||
       [extension isEqualToString:@"mpg"] ||
       [extension isEqualToString:@"mpeg"] ||
       [extension isEqualToString:@"avi"])
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
    
    if( [extension isEqualToString:@"pic"])
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
    const char	*ptr;
    long		i;
    
    NSString	*extension = [[filePath pathExtension] lowercaseString];
    
    if( [extension isEqualToString:@"lsm"])
    {
        file = [NSData dataWithContentsOfFile: filePath];
        if( [file length] > 1)
        {
            fileType = [@"LSM" retain];
            
            ptr = (const char*)[file bytes];
            
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
            
            int	LENGTH1 = 0, TIF_BITSPERSAMPLE_CHANNEL1 = 0, TIF_BITSPERSAMPLE_CHANNEL2 = 0, TIF_BITSPERSAMPLE_CHANNEL3 = 0;
            int	TIF_COMPRESSION = 0, TIF_PHOTOMETRICINTERPRETATION = 0, LENGTH2 = 0, TIF_STRIPOFFSETS = 0, TIF_SAMPLESPERPIXEL = 0, TIF_STRIPBYTECOUNTS = 0;
            int	TIF_CZ_LSMINFO = 0, TIF_STRIPOFFSETS1 = 0, TIF_STRIPOFFSETS2 = 0, TIF_STRIPOFFSETS3 = 0;
            int	TIF_STRIPBYTECOUNTS1 = 0, TIF_STRIPBYTECOUNTS2 = 0, TIF_STRIPBYTECOUNTS3 = 0;
            
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
                [dicomElements setObject:[NSNumber numberWithInt:(int)i] forKey:[@"seriesNumber" stringByAppendingString:SeriesNum]];
                [dicomElements setObject:[imageID stringByAppendingString:SeriesNum] forKey:[@"SOPUID" stringByAppendingString:SeriesNum]];
                [dicomElements setObject:[NSNumber numberWithInt:(int)i] forKey:[@"imageID" stringByAppendingString:SeriesNum]];
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
    
    if( [extension isEqualToString:@"hdr"])
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
                
                date = [[Horos dateWithString:[NSString stringWithCString: Analyze->hist.exp_date encoding: NSISOLatin1StringEncoding] calendarFormat:@"%Y%m%d"] retain];
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
    
    if( (( [extension isEqualToString:@"hdr"]) &&
         ([[NSFileManager defaultManager] fileExistsAtPath:[[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)) ||
       ( [extension isEqualToString:@"nii"]))
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
    return -1;
}

-(short) getDicomFile
{
    BOOL isCD = NO;
    
    if( PREFERPAPYRUSFORCD)
        isCD = filesAreFromCDMedia;
    
    if( TOOLKITPARSER == 1 || isCD == YES) return [self getDicomFilePapyrus: NO];
    
    if( TOOLKITPARSER == 0) return [self getDicomFilePapyrus: NO];
    
    if( TOOLKITPARSER == 2) return [self getDicomFileDCMTK];
    
    return [self getDicomFileDCMTK];
}

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
        [dicomElements setObject:[NSNumber numberWithInt:(int)height] forKey:@"height"];
        [dicomElements setObject:[NSNumber numberWithInt:(int)width] forKey:@"width"];
        [dicomElements setObject:[NSNumber numberWithInt:(int)NoOfFrames] forKey:@"numberOfFrames"];
        [dicomElements setObject:[NSNumber numberWithInt:(int)NoOfSeries] forKey:@"numberOfSeries"];
        [dicomElements setObject:filePath forKey:@"filePath"];
    }
    else
    {
        [self autorelease];
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
                [self autorelease];
                
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
                [self autorelease];
                
                returnVal = nil;
            }
        }
    }
    
    if( returnVal)
    {
        [dicomElements setObject:[NSNumber numberWithInt:(int)height] forKey:@"height"];
        [dicomElements setObject:[NSNumber numberWithInt:(int)width] forKey:@"width"];
        [dicomElements setObject:[NSNumber numberWithInt:(int)NoOfFrames] forKey:@"numberOfFrames"];
        [dicomElements setObject:[NSNumber numberWithInt:(int)NoOfSeries] forKey:@"numberOfSeries"];
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
        patientName = [DicomFile NSreplaceBadCharacter: [src valueForKey:@"patientName"]];
        patientName = [patientName stringByReplacingOccurrencesOfString: @"-" withString: @" "];
        
        NSString *firstRepresentation = [[patientName componentsSeparatedByString: @"="] objectAtIndex: 0];
        
        if( firstRepresentation.length)
            patientName = firstRepresentation;
    }
    
    if( gUsePatientBirthDateForUID)
        patientBirthDate = [Horos:[NSDate dateWithTimeIntervalSinceReferenceDate:[[src valueForKey:@"patientBirthDate"] timeIntervalSinceReferenceDate]] descriptionWithCalendarFormat:@"%Y%m%d"];

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

//// fake DICOM for other files with XML descriptor
//
//- (id) initWithXMLDescriptor: (NSString*)pathToXMLDescriptor path:(NSString*) f
//{
//	if( self = [super init])
//	{	
//		// XML Data
//		NSLog(@"pathToXMLDescriptor : %@", pathToXMLDescriptor);
//		NSLog(@"f : %@", f);	
//		CFURLRef sourceURL;
////		sourceURL = CFURLCreateWithString (	NULL, // allocator 
////											(CFStringRef) urlToXMLDescriptor, // url string 
////											NULL); // base url
//											
//		sourceURL = CFURLCreateFromFileSystemRepresentation (	NULL, // allocator 
//																(unsigned char*) [pathToXMLDescriptor UTF8String], // string buffer
//																[pathToXMLDescriptor length],	// buffer length
//																FALSE); // is directory
//		NSLog(@"sourceURL : %@", sourceURL);
//
//		BOOL result;
//		SInt32 errorCode;
//		CFDataRef xmlData;
//		//NSLog(@"xmlData");
//		result = CFURLCreateDataAndPropertiesFromResource (	NULL, // allocator 
//															sourceURL, &xmlData,
//															NULL, NULL, // properties 
//															&errorCode);
//		
//		CFRelease( sourceURL);
//		
//		if (errorCode==0)
//		{
//			//NSLog(@"cfXMLTree");
//			CFTreeRef cfXMLTree;
//			cfXMLTree = CFXMLTreeCreateFromData (	kCFAllocatorDefault,
//													xmlData,
//													NULL, // datasource 
//													kCFXMLParserSkipWhitespace,
//													kCFXMLNodeCurrentVersion);
//			
//			//NSLog(@"cfXMLTree : %@", cfXMLTree);
//			//NSLog(@"[curFile dicomElements]");
//			dicomElements = [[NSMutableDictionary dictionary] retain];
//
//			//NSLog(@"dicomElements : %@", dicomElements);
//			
//			// 
//			CFTreeRef attributesTree;
//			attributesTree = CFTreeGetChildAtIndex(cfXMLTree, 0);
//			
//			CFRelease( cfXMLTree);
//			
//			//NSLog(@"attributesTree: %@", attributesTree);
//			// NSMutableDictionary* xmlData = [[NSMutableDictionary alloc] initWithCapacity:14];
//			NSMutableDictionary* xmlData = [NSMutableDictionary dictionaryWithContentsOfFile:pathToXMLDescriptor];
//			
////			for(i=0; i<14; i++)
////			{
////				CFTreeRef childProjectName = CFTreeGetChildAtIndex(attributesTree, i);
////				node = CFXMLTreeGetNode(childProjectName);
////				nodeName = CFXMLNodeGetString(node);
////				child = CFTreeGetChildAtIndex(childProjectName, 0);
////				node = CFXMLTreeGetNode(child);
////				nodeValue = CFXMLNodeGetString(node);
////				[xmlData setObject:nodeValue forKey:nodeName];
////				//NSLog(@"nodeName : %@", nodeName);
////				//NSLog(@"nodeValue : %@", nodeValue);
////			}
//		
//			width = 4;
//			height = 4;
//			name = [[xmlData objectForKey:@"patientName"] retain];
//			study = [[xmlData objectForKey:@"studyDescription"] retain];
//			serie = [[NSString alloc] initWithString:[f lastPathComponent]];
//			date = [[NSDate dateWithString:[xmlData objectForKey:@"studyDate"]] retain];
//			Modality = [[xmlData objectForKey:@"modality"] retain];
//			filePath = [f retain];
//			fileType = [@"XMLDESCRIPTOR" retain];
//			NoOfSeries = 1;
//			NoOfFrames = [[xmlData objectForKey:@"numberOfImages"] intValue];
//			
//			studyID = [[xmlData objectForKey:@"studyID"] retain];
//			self.serieID = [filePath lastPathComponent];
//			imageID = [[NSString alloc] initWithString:[filePath lastPathComponent]];
//			SOPUID = [imageID retain];
//			patientID = [[xmlData objectForKey:@"patientID"] retain];
//			studyIDs = [studyID retain];
//			seriesNo = [[NSString alloc] initWithString:@"0"];
//			imageType = nil;
//			
//			[dicomElements setObject:[xmlData objectForKey:@"album"] forKey:@"album"];
//			[dicomElements setObject:name forKey:@"patientName"];
//			[dicomElements setObject:patientID forKey:@"patientID"];
//			[dicomElements setObject:[xmlData objectForKey:@"accessionNumber"] forKey:@"accessionNumber"];
//			[dicomElements setObject:study forKey:@"studyDescription"];
//			[dicomElements setObject:Modality forKey:@"modality"];
//			[dicomElements setObject:studyID forKey:@"studyID"];
//			[dicomElements setObject:date forKey:@"studyDate"];
//			[dicomElements setObject:[xmlData objectForKey:@"numberOfImages"] forKey:@"numberOfImages"];
//			//[dicomElements setObject:[xmlData objectForKey:@"DATE_ADDED"] forKey:@""];
//			[dicomElements setObject:[xmlData objectForKey:@"referringPhysiciansName"] forKey:@"referringPhysiciansName"];
//			[dicomElements setObject:[xmlData objectForKey:@"performingPhysiciansName"] forKey:@"performingPhysiciansName"];
//			[dicomElements setObject:[xmlData objectForKey:@"institutionName"] forKey:@"institutionName"];
//			[dicomElements setObject:[NSDate dateWithString:[xmlData objectForKey:@"patientBirthDate"]] forKey:@"patientBirthDate"];
//			
//			[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
//			[dicomElements setObject:self.serieID forKey:@"seriesID"];
//			[dicomElements setObject:[[[NSString alloc] initWithString:[filePath lastPathComponent]] autorelease] forKey:@"seriesDescription"];
//			[dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
//			[dicomElements setObject:imageID forKey:@"SOPUID"];
//			[dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
//			[dicomElements setObject:fileType forKey:@"fileType"];
//			[dicomElements setObject:f forKey:@"filePath"];
//			
//			NSLog(@"dicomElements : %@", dicomElements);
//		}
//	}
//	
//	return self;
//}

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
