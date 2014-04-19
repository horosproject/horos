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

#define DCM_AE 0x4145 //Application Entity  String 16bytes max
#define DCM_AS 0x4153 //Age String Format mmmM,dddD,nnnY ie 018Y
#define DCM_AT 0x4154 //Attribute Tag 16bit unsigned integer
#define DCM_CS 0x4353 //Code String   16 byte max
#define DCM_DA 0x4441 //Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
#define DCM_DS 0x4453 //Decimal String  representing floating point number 16 byte max
#define DCM_DT 0x4454 //Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
#define DCM_FD 0x4644 //floating point Single 4 bytes fixed
#define DCM_FL 0x464C //double floating point 8 bytes fixed
#define DCM_IS 0x4953 //Integer String 12 bytes max
#define DCM_LO 0x4C4F //Character String 64 char max
#define DCM_LT 0x4C54 //Long Text 10240 char Max
#define DCM_PN 0x504E //Person Name string
#define DCM_SH 0x5348 //short string
#define DCM_SL 0x534C //signed long
#define DCM_SS 0x5353 //signed short
#define DCM_ST 0x5354 //short Text 1024 char max
#define DCM_TM 0x544D //Time String
#define DCM_UI 0x5549 //String for UID
#define DCM_UL 0x554C //unsigned Long
#define DCM_US 0x5553 //unsigned short
#define DCM_UT 0x5554 //unlimited text
#define DCM_OB 0x4F42 //other Byte byte string not little/big endian sensitive
#define DCM_OW 0x4F57 //other word 16bit word
#define DCM_OF 0x4F46 //Other Float 
#define DCM_SQ 0x5351 //Sequence of items
#define DCM_UN 0x554E //unknown
#define DCM_QQ 0x3F3F

@class DCMAttributeTag;
@class DCMDataContainer;
@class DCMCharacterSet;
@class DCMTransferSyntax;

@interface DCMAttribute : NSObject {
	DCMAttributeTag *_tag;
	long _valueLength;
	NSMutableArray *_values;
	NSString *_vr;
	DCMCharacterSet *characterSet;
	NSString *name;
	unsigned char *_dataPtr;

}

@property(readonly) int group, element;
@property(readonly) int valueMultiplicity;
@property(readonly) NSString *vr, *vrStringValue;
@property(readonly) NSString *description;
@property(readonly) long paddedLength;
@property(readonly) long paddedValueLength;
@property(readonly) long valueLength;
@property(retain) NSMutableArray *values;
@property(readonly) DCMAttributeTag *attrTag;
@property(retain) DCMCharacterSet *characterSet;

+ (id)attributeWithAttribute:(DCMAttribute *)attr;
+ (id)attributeWithAttributeTag:(DCMAttributeTag *)tag;
+ (id)attributeWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr;
+ (id)attributeWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr  values:(NSMutableArray *)values;
+ (id)attributeinitWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicitValue
			forImplicitUseOW:(BOOL)forImplicitUseOW;



- (id)initWithAttribute:(DCMAttribute *)attr;
- (id)initWithAttributeTag:(DCMAttributeTag *)tag;
//possible private tag not in dictionary
- (id)initWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr;
// creating attributes from scratch.  Will try and get vr from dictionary first.
- (id) initWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr  values:(NSMutableArray *)values;
- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicitValue
			forImplicitUseOW:(BOOL)forImplicitUseOW;
- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			dataPtr: (unsigned char *)dataPtr;
- (long) paddedLength;
- (id)value;
- (void)addValue:(id)value;
- (void)writeBaseToData:(DCMDataContainer *)dcmData transferSyntax:(DCMTransferSyntax *)ts;
- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts;

- (NSString *)valuesAsString;
- (NSArray *)valuesForVR:(NSString *)vrString  length:(int)length data:(DCMDataContainer *)dicomData;
- (void)swapBytes:(NSMutableData *)data;
- (id)copyWithZone:(NSZone *)zone;

- (NSXMLNode *)xmlNode;
- (NSString*)readableDescription;
@end
