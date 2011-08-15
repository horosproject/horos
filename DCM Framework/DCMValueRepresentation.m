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

#import "DCMValueRepresentation.h"

//static char AE[2] = { 'A', 'E' };


@implementation DCMValueRepresentation
/*
+ (BOOL)isApplicationEntityVR:(char *)vr{
	return vr[0]=='A' &&  vr[1]=='E';
}

+ (BOOL)isAgeStringVR:(char *)vr {
		return vr[0]=='A' &&  vr[1]=='S';
	}

+ (BOOL)isAttributeTagVR:(char *)vr {
		return vr[0]=='A' &&  vr[1]=='T';
	}


+ (BOOL)isCodeStringVR:(char *)vr{
		return vr[0]=='C' &&  vr[1]=='S';
	}


+ (BOOL)isDateVR:(char *)vr {
		return vr[0]=='D' &&  vr[1]=='A';
	}


+ (BOOL)isDateTimeVR:(char *)vr{
		return vr[0]=='D' &&  vr[1]=='T';
	}


+ (BOOL)isDecimalStringVR:(char *)vr {
		return vr[0]=='D' &&  vr[1]=='S';
	}


+ (BOOL)isFloatDoubleVR:(char *)vr {
		return vr[0]=='F' &&  vr[1]=='D';
	}


+ (BOOL)isFloatSingleVR:(char *)vr{
		return vr[0]=='F' &&  vr[1]=='L';
	}


+ (BOOL)isIntegerStringVR:(char *)vr {
		return vr[0]=='I' &&  vr[1]=='S';
	}


+ (BOOL)isLongStringVR:(char *)vr{
		return vr[0]=='L' &&  vr[1]=='O';
	}


+ (BOOL)isLongTextVR:(char *)vr{
		return vr[0]=='L' &&  vr[1]=='T';
	}


+ (BOOL)isOtherByteVR:(char *)vr {
		return vr[0]=='O' &&  vr[1]=='B';
	}


+ (BOOL)isOtherFloatVR:(char *)vr{
		return vr[0]=='O' &&  vr[1]=='F';
	}


+ (BOOL)isOtherWordVR:(char *)vr{
		return vr[0]=='O' &&  vr[1]=='W';
	}


+ (BOOL)isOtherUnspecifiedVR:(char *)vr{		// Not a real VR ... but returned by dictionary
		return vr[0]=='O' &&  vr[1]=='X';
	}


+ (BOOL)isOtherByteOrWordVR:(char *)vr {
		return vr[0]=='O' && (vr[1]=='B' || vr[1]=='W' || vr[1]=='X');
	}


+ (BOOL)isPersonNameVR:(char *)vr{
		return vr[0]=='P' &&  vr[1]=='N';
	}


+ (BOOL)isShortStringVR:(char *)vr{
		return vr[0]=='S' &&  vr[1]=='H';
	}


+ (BOOL)isSignedLongVR:(char *)vr {
		return vr[0]=='S' &&  vr[1]=='L';
	}


+ (BOOL)isSequenceVR:(char *)vr {
		return vr[0]=='S' &&  vr[1]=='Q';
	}

+ (BOOL)isSignedShortVR:(char *)vr {
		return vr[0]=='S' &&  vr[1]=='S';
	}


+ (BOOL)isShortTextVR:(char *)vr{
		return vr[0]=='S' &&  vr[1]=='T';
	}


+ (BOOL)isTimeVR:(char *)vr {
		return vr[0]=='T' &&  vr[1]=='M';
	}


+ (BOOL)isUniqueIdentifierVR:(char *)vr {
		return vr[0]=='U' &&  vr[1]=='I';
	}


+ (BOOL)isUnsignedLongVR:(char *)vr {
		return vr[0]=='U' &&  vr[1]=='L';
	}


+ (BOOL)isUnknownVR:(char *)vr {
		return vr[0]=='U' &&  vr[1]=='N';
	}


+ (BOOL)isUnsignedShortVR:(char *)vr {
		return vr[0]=='U' &&  vr[1]=='S';
	}


+ (BOOL)isUnspecifiedShortVR:(char *)vr {			// Not a real VR ... but returned by dictionary
		return vr[0]=='X' &&  vr[1]=='S';
	}


+ (BOOL)isUnspecifiedShortOrOtherWordVR:(char *)vr {	// Not a real VR ... but returned by dictionary
		return vr[0]=='X' &&  vr[1]=='O';
	}


+ (BOOL)isUnlimitedTextVR:(char *)vr {
		return vr[0]=='U' &&  vr[1]=='T';
	}

+ (BOOL) isShortValueLengthVR:(char*)vr {
		return vr[0]=='A' && ( vr[1]=='E'
				    || vr[1]=='S'
				    || vr[1]=='T' )
		    || vr[0]=='C' &&   vr[1]=='S'
		    || vr[0]=='D' && ( vr[1]=='A'
				    || vr[1]=='S'
				    || vr[1]=='T' )
		    || vr[0]=='F' && ( vr[1]=='D'
				    || vr[1]=='L' )
		    || vr[0]=='I' &&   vr[1]=='S'
		    || vr[0]=='L' && ( vr[1]=='O'
				    || vr[1]=='T' )
		    || vr[0]=='P' &&   vr[1]=='N'
		    || vr[0]=='S' && ( vr[1]=='H'
				    || vr[1]=='L'
				    || vr[1]=='S'
				    || vr[1]=='T' )
		    || vr[0]=='T' &&   vr[1]=='M'
		    || vr[0]=='U' && ( vr[1]=='I'
				    || vr[1]=='L'
				    || vr[1]=='S' );
	}



+ (BOOL)isAffectedBySpecificCharacterSet:(char *)vr {
		return ([self isLongStringVR:vr]
		    || [self isLongTextVR:vr]
		    || [self isPersonNameVR:vr]
		    || [self isShortStringVR:vr]
		    || [self isShortTextVR:vr]
		    || [self isUnlimitedTextVR:vr]);
	}



+ (NSString *)stringValue:(char *)vr{
	return [NSString stringWithCString:vr];
}

+ (int)getWordLengthOfValueAffectedByEndianness:(char *)vr{
	int length = 1;
	if ([self isSignedShortVR:vr]
		 || [self isUnsignedShortVR:vr]
		 || [self isUnspecifiedShortVR:vr]
		 || [self isOtherWordVR:vr]
		 || [self isUnspecifiedShortOrOtherWordVR:vr]
		) {
			length=2;
		}
		
		if ([self isSignedLongVR:vr]
		 || [self isUnsignedLongVR:vr]
		 || [self isFloatSingleVR:vr]
		 || [self isOtherFloatVR:vr]
		) {
			length=4;
		}
		
		if ([self isFloatDoubleVR:vr]
		) {
			length=8;
		}
		
		return length;
	}
*/

+ (BOOL)isApplicationEntityVR:(NSString *)vrString{
	const char *vr = [vrString UTF8String];
	return vr[0]=='A' &&  vr[1]=='E';
}

+ (BOOL)isAgeStringVR:(NSString *)vrString{
	const char *vr = [vrString UTF8String];
		return vr[0]=='A' &&  vr[1]=='S';
	}

+ (BOOL)isAttributeTagVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='A' &&  vr[1]=='T';
	}


+ (BOOL)isCodeStringVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='C' &&  vr[1]=='S';
	}


+ (BOOL)isDateVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='D' &&  vr[1]=='A';
	}


+ (BOOL)isDateTimeVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='D' &&  vr[1]=='T';
	}


+ (BOOL)isDecimalStringVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='D' &&  vr[1]=='S';
	}


+ (BOOL)isFloatDoubleVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='F' &&  vr[1]=='D';
	}


+ (BOOL)isFloatSingleVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='F' &&  vr[1]=='L';
	}


+ (BOOL)isIntegerStringVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='I' &&  vr[1]=='S';
	}


+ (BOOL)isLongStringVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='L' &&  vr[1]=='O';
	}


+ (BOOL)isLongTextVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='L' &&  vr[1]=='T';
	}


+ (BOOL)isOtherByteVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='O' &&  vr[1]=='B';
	}


+ (BOOL)isOtherFloatVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='O' &&  vr[1]=='F';
	}


+ (BOOL)isOtherWordVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='O' &&  vr[1]=='W';
	}


+ (BOOL)isOtherUnspecifiedVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];		// Not a real VR ... but returned by dictionary
		return vr[0]=='O' &&  vr[1]=='X';
	}


+ (BOOL)isOtherByteOrWordVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='O' && (vr[1]=='B' || vr[1]=='W' || vr[1]=='X');
	}


+ (BOOL)isPersonNameVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='P' &&  vr[1]=='N';
	}


+ (BOOL)isShortStringVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='S' &&  vr[1]=='H';
	}


+ (BOOL)isSignedLongVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='S' &&  vr[1]=='L';
	}


+ (BOOL)isSequenceVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='S' &&  vr[1]=='Q';
	}

+ (BOOL)isSignedShortVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='S' &&  vr[1]=='S';
	}


+ (BOOL)isShortTextVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='S' &&  vr[1]=='T';
	}


+ (BOOL)isTimeVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='T' &&  vr[1]=='M';
	}


+ (BOOL)isUniqueIdentifierVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='U' &&  vr[1]=='I';
	}


+ (BOOL)isUnsignedLongVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='U' &&  vr[1]=='L';
	}


+ (BOOL)isUnknownVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='U' &&  vr[1]=='N';
	}


+ (BOOL)isUnsignedShortVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='U' &&  vr[1]=='S';
	}


+ (BOOL)isUnspecifiedShortVR:(NSString *)vrString{			// Not a real VR ... but returned by dictionary
const char *vr = [vrString UTF8String];
		return vr[0]=='X' &&  vr[1]=='S';
	}


+ (BOOL)isUnspecifiedShortOrOtherWordVR:(NSString *)vrString{	// Not a real VR ... but returned by dictionary
const char *vr = [vrString UTF8String];
		return vr[0]=='X' &&  vr[1]=='O';
	}


+ (BOOL)isUnlimitedTextVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return vr[0]=='U' &&  vr[1]=='T';
	}

+ (BOOL) isShortValueLengthVR:(NSString *)vrString{
const char *vr = [vrString UTF8String];
		return (vr[0]=='A' && ( vr[1]=='E'
				    || vr[1]=='S'
				    || vr[1]=='T' ))
		    || (vr[0]=='C' &&   vr[1]=='S')
		    || (vr[0]=='D' && ( vr[1]=='A'
				    || vr[1]=='S'
				    || vr[1]=='T' ))
		    || (vr[0]=='F' && ( vr[1]=='D'
				    || vr[1]=='L' ))
		    || (vr[0]=='I' &&   vr[1]=='S')
		    || (vr[0]=='L' && ( vr[1]=='O'
				    || vr[1]=='T' ))
		    || (vr[0]=='P' &&   vr[1]=='N')
		    || (vr[0]=='S' && ( vr[1]=='H'
				    || vr[1]=='L'
				    || vr[1]=='S'
				    || vr[1]=='T' ))
		    || (vr[0]=='T' &&   vr[1]=='M')
		    || (vr[0]=='U' && ( vr[1]=='I'
				    || vr[1]=='L'
				    || vr[1]=='S' ));
	}



+ (BOOL)isAffectedBySpecificCharacterSet:(NSString *)vrString{
	//const char *vr = [vrString UTF8String];
		return ([DCMValueRepresentation isLongStringVR:vrString]
		    || [DCMValueRepresentation isLongTextVR:vrString]
		    || [DCMValueRepresentation isPersonNameVR:vrString]
		    || [DCMValueRepresentation isShortStringVR:vrString]
		    || [DCMValueRepresentation isShortTextVR:vrString]
		    || [DCMValueRepresentation isUnlimitedTextVR:vrString]);
}

+ (BOOL)isValidVR:(NSString *)vrString{
	return  ([DCMValueRepresentation isApplicationEntityVR:vrString] ||
			[DCMValueRepresentation isAgeStringVR:vrString] ||
			[DCMValueRepresentation isAttributeTagVR:vrString] ||
			[DCMValueRepresentation isCodeStringVR:vrString] ||
			[DCMValueRepresentation isDateVR:vrString] ||
			[DCMValueRepresentation isDateTimeVR:vrString] ||
			[DCMValueRepresentation isDecimalStringVR:vrString] ||
			[DCMValueRepresentation isFloatDoubleVR:vrString] ||
			[DCMValueRepresentation isFloatSingleVR:vrString] ||
			[DCMValueRepresentation isIntegerStringVR:vrString] ||
			[DCMValueRepresentation isLongStringVR:vrString] ||
			[DCMValueRepresentation isLongTextVR:vrString] ||
			[DCMValueRepresentation isOtherByteVR:vrString] ||
			[DCMValueRepresentation isOtherFloatVR:vrString] ||
			[DCMValueRepresentation isOtherWordVR:vrString] ||
			[DCMValueRepresentation isOtherUnspecifiedVR:vrString] ||
			[DCMValueRepresentation isOtherByteOrWordVR:vrString] ||
			[DCMValueRepresentation isPersonNameVR:vrString] ||
			[DCMValueRepresentation isShortStringVR:vrString] ||
			[DCMValueRepresentation isSignedLongVR:vrString] ||
			[DCMValueRepresentation isSequenceVR:vrString] ||
			[DCMValueRepresentation isSignedShortVR:vrString] ||
			[DCMValueRepresentation isShortTextVR:vrString] ||
			[DCMValueRepresentation isTimeVR:vrString] ||
			[DCMValueRepresentation isUniqueIdentifierVR:vrString] ||
			[DCMValueRepresentation isUnsignedLongVR:vrString] ||
			[DCMValueRepresentation isUnknownVR:vrString] ||
			[DCMValueRepresentation isUnsignedShortVR:vrString] ||
			[DCMValueRepresentation isUnspecifiedShortVR:vrString] ||
			[DCMValueRepresentation isUnspecifiedShortOrOtherWordVR:vrString] ||
			[DCMValueRepresentation isUnlimitedTextVR:vrString] ||
			[DCMValueRepresentation isShortValueLengthVR:vrString]);
}



+ (NSString *)stringValue:(char *)vr{
	return [NSString stringWithCString:vr encoding: NSISOLatin1StringEncoding];
}

+ (int)getWordLengthOfValueAffectedByEndianness:(NSString *)vrString{
	//const char *vr = [vrString UTF8String];
	int length = 1;
	if ([DCMValueRepresentation isSignedShortVR:vrString]
		 || [DCMValueRepresentation isUnsignedShortVR:vrString]
		 || [DCMValueRepresentation isUnspecifiedShortVR:vrString]
		 || [DCMValueRepresentation isOtherWordVR:vrString]
		 || [DCMValueRepresentation isUnspecifiedShortOrOtherWordVR:vrString]
		) {
			length=2;
		}
		
		if ([DCMValueRepresentation isSignedLongVR:vrString]
		 || [DCMValueRepresentation isUnsignedLongVR:vrString]
		 || [DCMValueRepresentation isFloatSingleVR:vrString]
		 || [DCMValueRepresentation isOtherFloatVR:vrString]
		) {
			length=4;
		}
		
		if ([DCMValueRepresentation isFloatDoubleVR:vrString]
		) {
			length=8;
		}
		
		return length;
	}



@end
