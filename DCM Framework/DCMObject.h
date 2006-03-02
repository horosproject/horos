//
//  DCMObject.h
//  DCM Framework
//
//  Created by Lance Pysher on Mon Jun 07 2004.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/*
	This is the  main object representaing a Dicom File or as a list of Attributes for networking
*/

#import <Foundation/Foundation.h>

@class DCMAttribute;
@class DCMAttributeTag;
@class DCMDataContainer;
@class DCMCharacterSet;
@class DCMTagDictionary ;
@class DCMTagForNameDictionary;
@class DCMTransferSyntax;

@interface DCMObject : NSObject {

	NSMutableDictionary *attributes;
	NSDictionary *dicomDict;
	DCMTagDictionary *sharedTagDictionary;
	DCMTagForNameDictionary *sharedTagForNameDictionary;
	DCMCharacterSet *specificCharacterSet;
	DCMTransferSyntax *transferSyntax;
	BOOL _decodePixelData;

}
+ (BOOL)isDICOM:(NSData *)data;
+ (NSString *)rootUID;
+ (NSString *)implementationClassUID;
+ (NSString *)implementationVersionName;
+ (id)dcmObject;
//+ (BOOL)anonymizeContentsOfFile:(NSString *)file  tags:(NSArray *)tags  writingToFile:(NSString *)destination newPatientName:(NSString*) patName;
+ (BOOL)anonymizeContentsOfFile:(NSString *)file  tags:(NSArray *)tags  writingToFile:(NSString *)destination;
+ (id)secondaryCaptureObjectFromTemplate:(DCMObject *)object;
+ (id)secondaryCaptureObjectWithBitDepth:(int)bitDepth  samplesPerPixel:(int)spp numberOfFrames:(int)nff;
+ (id)objectWithData:(NSData *)data decodingPixelData:(BOOL)decodePixelData;
+ (id)objectWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData;
+ (id)objectWithContentsOfURL:(NSURL *)aURL decodingPixelData:(BOOL)decodePixelData;
+ (id)objectWithObject:(DCMObject *)object;
- (id)initWithData:(NSData *)data decodingPixelData:(BOOL)decodePixelData;
- (id)initWithData:(NSData *)data transferSyntax:(DCMTransferSyntax *)syntax;
- (id)initWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData;
- (id)initWithContentsOfURL:(NSURL *)aURL decodingPixelData:(BOOL)decodePixelData;
- (id)initWithObject:(DCMObject *)object;
- (id)initWithDataContainer:(DCMDataContainer *)data lengthToRead:(long)lengthToRead byteOffset:(long  *)byteOffset characterSet:(DCMCharacterSet *)characterSet decodingPixelData:(BOOL)decodePixelData;
- (id)init;
//Dicom Parsing
- (int)getGroup:(DCMDataContainer *)dicomData;
- (int)getElement:(DCMDataContainer *)dicomData;
- (int)length:(DCMDataContainer *)dicomData;
- (NSString *)getvr:(DCMDataContainer *)dicomData forTag:(DCMAttributeTag *)tag isExplicit:(BOOL)isExplicit;
- (NSMutableArray *)getValues:(DCMDataContainer *)dicomData;

- (long)readDataSet:(DCMDataContainer *)dicomData lengthToRead:(long)lengthToRead byteOffset:(long *)byteOffset;
- (long)readNewSequenceAttribute:(DCMAttribute *)attr dicomData:(DCMDataContainer *)dicomData byteOffset:(long *)byteOffset lengthToRead:(long)lengthToRead specificCharacterSet:(DCMCharacterSet *)specificCharacterSet;
- (DCMAttribute *) newAttributeForAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicitTS
			forImplicitUseOW:(BOOL)forImplicitUseOW;
			
- (void)removeMetaInformation;
- (void)updateMetaInformationWithTransferSyntax: (DCMTransferSyntax *)ts aet:(NSString *)aet;
- (void)removeGroupLengths;
- (void)removePrivateTags;
- (void)removePlanarAndRescaleAttributes;
//- (void)anonyimizeAttributeForTag:(DCMAttributeTag *)tag newPatientName:(NSString*) patName;
- (void)anonyimizeAttributeForTag:(DCMAttributeTag *)tag replacingWith:(id)aValue;
- (void)newStudyInstanceUID;
- (void)newSeriesInstanceUID;
- (void)newSOPInstanceUID;
- (NSString *)anonymizeString:(NSString *)string;
- (DCMTransferSyntax *)transferSyntax;
- (DCMCharacterSet *)specificCharacterSet;
- (void)setCharacterSet:(DCMCharacterSet *)characterSet;
- (DCMAttribute *)attributeForTag:(DCMAttributeTag *)tag;
- (id)attributeValueWithName:(NSString *)name;
- (id)attributeValueForKey:(NSString *)key;
- (DCMAttribute *)attributeWithName:(NSString *)name;
- (NSArray *)attributeArrayWithName:(NSString *)name;
- (void)setAttribute:(DCMAttribute *)attr;
- (void)addAttributeValue:(id)value   forName:(NSString *)name;
- (void)setAttributeValues:(NSMutableArray *)values forName:(NSString *)name;
- (NSMutableDictionary *)attributes;
- (BOOL)pixelDataIsDecoded;

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts AET:(NSString *)aet  asDICOM3:(BOOL)flag;
- (BOOL)writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			AET:(NSString *)aet 
			strippingGroupLengthLength:(BOOL)stripGroupLength;
- (BOOL)writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:(NSString *)aet atomically:(BOOL)flag;
- (BOOL)writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:(NSString *)aet atomically:(BOOL)flag;

- (NSData *)writeDatasetWithTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality;
- (BOOL)isNeededAttribute:(char *)tagString;

- (NSXMLNode *)xmlNode;
- (NSXMLDocument *)xmlDocument;


//deprecated methods
- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality;
- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts  asDICOM3:(BOOL)flag;
- (BOOL)writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			strippingGroupLengthLength:(BOOL)stripGroupLength;
- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality asDICOM3:(BOOL)flag;
- (BOOL)writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality atomically:(BOOL)flag;
- (BOOL)writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality atomically:(BOOL)flag;

//sequences
- (NSArray *)referencedSeriesSequence;
- (NSArray *)referencedImageSequenceForObject:(DCMObject *)object;

//Structured Report Object
+ (id)objectWithCodeValue:(NSString *)codeValue  
			codingSchemeDesignator:(NSString *)codingSchemeDesignator  
			codeMeaning:(NSString *)codeMeaning;



@end
