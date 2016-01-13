/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/

#import <Foundation/Foundation.h>
//#import <Cocoa/Cocoa.h>

@class DCMCalendarDate;
@class DCMTransferSyntax;

@interface DCMDataContainer : NSObject {
	NSMutableData *dicomData;
	BOOL isLittleEndian, isExplicitTS, dataRemaining;
	int offset, position;
	NSStringEncoding stringEncoding;	
	DCMTransferSyntax	*transferSyntaxForDataset, *transferSyntaxForMetaheader, *transferSyntaxInUse; 
	unsigned char *_ptr;
}

@property(readonly) int offset, position;
@property(readonly) unsigned int length;
@property(readonly) NSMutableData *dicomData;

+ (id)dataContainer;
+ (id)dataContainerWithBytes:(const void *)bytes length:(NSUInteger)length;
+ (id)dataContainerWithBytesNoCopy:(void *)bytes length:(NSUInteger)length;
+ (id)dataContainerWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)freeWhenDone;
+ (id)dataContainerWithContentsOfFile:(NSString *)path;
//+ (id)dataContainerWithContentsOfMappedFile:(NSString *)path;
+ (id)dataContainerWithContentsOfURL:(NSURL *)aURL;
+ (id)dataContainerWithData:(NSData *)aData;
+ (id)dataContainerWithData:(NSData *)aData transferSyntax:(DCMTransferSyntax *)syntax;
+ (id)dataContainerWithMutableData:(NSMutableData *)aData transferSyntax:(DCMTransferSyntax *)syntax;

- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data transferSyntax:(DCMTransferSyntax *)syntax;
- (id)initWithMutableData:(NSMutableData *)data transferSyntax:(DCMTransferSyntax *)syntax;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)aURL;
- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length;
- (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length;
- (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)flag;
 

- (void)initValues;

- (BOOL)isLittleEndian;
- (BOOL)isExplicitTS;
- (BOOL)isEncapsulated;
- (BOOL)dataRemaining;
- (NSStringEncoding) stringEncoding;
- (void)setLittleEndian:(BOOL)value;
- (void)setExplicitTS:(BOOL)value;

- (void)setStringEncoding:(NSStringEncoding)encoding;

- (unsigned char)nextUnsignedChar;
- (unsigned short)nextUnsignedShort;
- (short)nextSignedShort;
- (unsigned int)nextUnsignedLong;
- (int)nextSignedLong;
- (unsigned long long)nextUnsignedLongLong;
- (long long)nextSignedLongLong;
- (float)nextFloat;
- (double)nextDouble;

- (NSString *)nextStringWithLength:(int)length;
- (NSString *)nextStringWithLength:(int)length encoding:(NSStringEncoding)encoding;
- (NSString *)nextStringWithLength:(int)length encodings:(NSStringEncoding*)encodings;
- (NSCalendarDate *)nextDate;
- (NSMutableArray *)nextDatesWithLength:(int)length;
- (NSCalendarDate *)nextTimeWithLength:(int)length;
- (NSMutableArray *)nextTimesWithLength:(int)length;
- (NSCalendarDate *)nextDateTimeWithLength:(int)length;
- (NSMutableArray *)nextDateTimesWithLength:(int)length;
- (NSMutableData *)nextDataWithLength:(int)length;
- (BOOL)skipLength:(int)length;

- (void)addUnsignedChar:(unsigned char)uChar;
- (void)addSignedChar:(signed char)sChar;
- (void)addUnsignedShort:(unsigned short)uShort;
- (void)addSignedShort:(signed short)sShort;
- (void)addUnsignedLong:(unsigned long)uLong;
- (void)addSignedLong:(signed long)sLong;
- (void)addUnsignedLongLong:(unsigned long long)uLongLong;
- (void)addSignedLongLong:(signed long long)sLongLong;
- (void)addFloat:(float)f;
- (void)addDouble:(double)d;

- (void)addString:(NSString *)string;
- (void)addStringWithZeroPadding:(NSString *)string;
- (void)addString:(NSString *)string withEncoding:(NSStringEncoding)encoding;
- (void)addString:(NSString *)string withEncodings:(NSStringEncoding*)encoding;
- (void)addStringWithoutPadding:(NSString *)string;
- (void)addDate:(DCMCalendarDate *)date;
- (void)addTime:(DCMCalendarDate *)time;
- (void)addDateTime:(DCMCalendarDate *)dateTime;
- (void)addData:(NSData *)data;

- (DCMTransferSyntax *) transferSyntaxForDataset;
- (DCMTransferSyntax *) transferSyntaxForMetaheader;
- (DCMTransferSyntax *) transferSyntaxInUse;
- (void)setUseMetaheaderTS:(BOOL)flag;
- (BOOL)determineTransferSyntax;
- (void)setTransferSyntaxForDataset:(DCMTransferSyntax *)ts;
- (void)setTransferSyntaxForMetaheader:(DCMTransferSyntax *)ts;

- (NSException *)testForLength: (int)elementLength;

- (void)startReadingMetaHeader;
- (void)startReadingDataSet;

- (void)addPremable;

@end
