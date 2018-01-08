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
	return [NSString stringWithUTF8String:vr];
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
