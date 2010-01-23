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

#import <Foundation/Foundation.h>


@interface DCMValueRepresentation : NSObject {

}
/*
+ (BOOL)isApplicationEntityVR:(char *)vr;
+ (BOOL)isAgeStringVR:(char *)vr;
+ (BOOL)isAttributeTagVR:(char *)vr;
+ (BOOL)isCodeStringVR:(char *)vr;
+ (BOOL)isDateVR:(char *)vr;
+ (BOOL)isDateTimeVR:(char *)vr;
+ (BOOL)isDecimalStringVR:(char *)vr;
+ (BOOL)isFloatDoubleVR:(char *)vr;
+ (BOOL)isFloatSingleVR:(char *)vr;
+ (BOOL)isIntegerStringVR:(char *)vr;
+ (BOOL)isLongStringVR:(char *)vr;
+ (BOOL)isLongTextVR:(char *)vr;
+ (BOOL)isOtherByteVR:(char *)vr;
+ (BOOL)isOtherFloatVR:(char *)vr;
+ (BOOL)isOtherWordVR:(char *)vr;
+ (BOOL)isOtherUnspecifiedVR:(char *)vr;
+ (BOOL)isOtherByteOrWordVR:(char *)vr;
+ (BOOL)isPersonNameVR:(char *)vr;
+ (BOOL)isShortStringVR:(char *)vr;
+ (BOOL)isSignedLongVR:(char *)vr;
+ (BOOL)isSequenceVR:(char *)vr;
+ (BOOL)isSignedShortVR:(char *)vr;
+ (BOOL)isShortTextVR:(char *)vr;
+ (BOOL)isTimeVR:(char *)vr;
+ (BOOL)isUniqueIdentifierVR:(char *)vr;
+ (BOOL)isUnsignedLongVR:(char *)vr;
+ (BOOL)isUnknownVR:(char *)vr;
+ (BOOL)isUnsignedShortVR:(char *)vr;
+ (BOOL)isUnspecifiedShortVR:(char *)vr;
+ (BOOL)isUnspecifiedShortOrOtherWordVR:(char *)vr;
+ (BOOL)isUnlimitedTextVR:(char *)vr;
+ (BOOL) isShortValueLengthVR:(char*)vr;

+ (BOOL)isAffectedBySpecificCharacterSet:(char *)vr;
*/
+ (NSString *)stringValue:(char *)vr;

//+ (int)getWordLengthOfValueAffectedByEndianness:(char *)vr;

+ (BOOL)isApplicationEntityVR:(NSString *)vrString;
+ (BOOL)isAgeStringVR:(NSString *)vrString;
+ (BOOL)isAttributeTagVR:(NSString *)vrString;
+ (BOOL)isCodeStringVR:(NSString *)vrString;
+ (BOOL)isDateVR:(NSString *)vrString;
+ (BOOL)isDateTimeVR:(NSString *)vrString;
+ (BOOL)isDecimalStringVR:(NSString *)vrString;
+ (BOOL)isFloatDoubleVR:(NSString *)vrString;
+ (BOOL)isFloatSingleVR:(NSString *)vrString;
+ (BOOL)isIntegerStringVR:(NSString *)vrString;
+ (BOOL)isLongStringVR:(NSString *)vrString;
+ (BOOL)isLongTextVR:(NSString *)vrString;
+ (BOOL)isOtherByteVR:(NSString *)vrString;
+ (BOOL)isOtherFloatVR:(NSString *)vrString;
+ (BOOL)isOtherWordVR:(NSString *)vrString;
+ (BOOL)isOtherUnspecifiedVR:(NSString *)vrString;
+ (BOOL)isOtherByteOrWordVR:(NSString *)vrString;
+ (BOOL)isPersonNameVR:(NSString *)vrString;
+ (BOOL)isShortStringVR:(NSString *)vrString;
+ (BOOL)isSignedLongVR:(NSString *)vrString;
+ (BOOL)isSequenceVR:(NSString *)vrString;
+ (BOOL)isSignedShortVR:(NSString *)vrString;
+ (BOOL)isShortTextVR:(NSString *)vrString;
+ (BOOL)isTimeVR:(NSString *)vrString;
+ (BOOL)isUniqueIdentifierVR:(NSString *)vrString;
+ (BOOL)isUnsignedLongVR:(NSString *)vrString;
+ (BOOL)isUnknownVR:(NSString *)vrString;
+ (BOOL)isUnsignedShortVR:(NSString *)vrString;
+ (BOOL)isUnspecifiedShortVR:(NSString *)vrString;
+ (BOOL)isUnspecifiedShortOrOtherWordVR:(NSString *)vrString;
+ (BOOL)isUnlimitedTextVR:(NSString *)vrString;
+ (BOOL)isShortValueLengthVR:(NSString *)vrString;

+ (BOOL)isAffectedBySpecificCharacterSet:(NSString *)vrString;
+ (BOOL)isValidVR:(NSString *)vrString;


+ (int)getWordLengthOfValueAffectedByEndianness:(NSString *)vrString;



@end
