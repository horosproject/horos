//
//  DCMObject.m
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

// 7/5/2005  Changed startReadingDataSet to check for group > 0x0002 instead of checking for length of metaheader. in case metaheader length is wrong. LP
// 7/7/2005  Changed testing of explicit TS to after checking  if reading dataset. LP.

#import "DCMObject.h"
#import "DCM.h"
#import "DCMAbstractSyntaxUID.h"
#import <Accelerate/Accelerate.h>
//#import "DCMUIDs.h"

static NSString *DCM_SecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7";
static NSString *rootUID = @"1.3.6.1.4.1.19291.2.1";
static NSString *uidQualifier = @"99";
static NSString *implementationName = @"OSIRIX";
static NSString *softwareVersion = @"001";

@implementation DCMObject
+ (BOOL)isDICOM:(NSData *)data{
	//int position = 128;
	if( [data length] < 132) return NO;
	unsigned char *string = (unsigned char *)[data bytes];
	//unsigned char *string2 = string + 128;
	//NSLog(@"dicom at 128: %@" , [NSString  stringWithCString:string2 length:4]);
	if (string[128] == 'D' && string[129] == 'I'&& string[130] == 'C' && string[131] == 'M')
	return YES;
	return NO;
}


+ (NSString *)rootUID{
	return rootUID;
}

+ (NSString *)implementationClassUID{
	return [NSString stringWithFormat:@"%@.%@.1", rootUID, uidQualifier];
}

+ (NSString *)implementationVersionName{
	return [NSString stringWithFormat:@"%@%@", implementationName, softwareVersion];
}

+ (id)dcmObject{
	return [[[DCMObject alloc] init] autorelease];
}

+ (BOOL)anonymizeContentsOfFile:(NSString *)file  tags:(NSArray *)tags  writingToFile:(NSString *)destination{
	DCMObject *object = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
	NSEnumerator *enumerator = [tags objectEnumerator];
	NSArray *tagArray;
	DCMAttributeTag *tag;
	[object removePrivateTags];
	while (tagArray = [enumerator nextObject])
	{
		tag = [tagArray objectAtIndex:0];
		
		id value = nil;
		if ([tagArray count] > 1)
			value = [tagArray objectAtIndex:1];
		
		[object anonyimizeAttributeForTag:tag replacingWith:value];
		if ([[tag name] isEqualToString: @"PatientID"])
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"OtherPatientIDs"] replacingWith:value];
		if ([[tag name] isEqualToString: @"InstanceCreationDate"]) {
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"ContentDate"] replacingWith:value];
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionDate"] replacingWith:value];
		}
		if ([[tag name] isEqualToString: @"InstanceCreationTime"]) {
			NSLog(@"InstanceCreationTime");
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"ContentTime"] replacingWith:value];
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionTime"] replacingWith:value];
		}
		if ([[tag name] isEqualToString: @"AcquisitionDatetime"])
		{
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionDate"] replacingWith:value];
			[object anonyimizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionTime"] replacingWith:value];
		}
	}
	
	//get rid of some other tags containing addresses and phone numbers
	if ([object attributeValueWithName:@"InstitutionAddress"])
		[object setAttributeValues:[NSMutableArray array] forName:@"InstitutionAddress"];
	if ([object attributeValueWithName:@"PatientsAddress"])
		[object setAttributeValues:[NSMutableArray array] forName:@"PatientsAddress"];
	if ([object attributeValueWithName:@"PatientsTelephoneNumbers"])
		[object setAttributeValues:[NSMutableArray array] forName:@"PatientsTelephoneNumbers"];
	
	
	
	if (DEBUG)
		NSLog(@"TransferSyntax: %@", [object transferSyntax]);
	DCMTransferSyntax *ts = [object transferSyntax];
	if (![ts isExplicit])
		ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	return [object  writeToFile:destination withTransferSyntax:ts quality: DCMLosslessQuality atomically:YES];
}

+ (id)secondaryCaptureObjectFromTemplate:(DCMObject *)object{
	//NSLog(@"Secondary capture");
	DCMObject *scObject = [object copy];
	NSMutableDictionary *attrs = [scObject attributes];
	NSMutableArray *keysToRemove = [NSMutableArray array];
	NSEnumerator *enumerator = [attrs keyEnumerator];
	NSString *key;
	DCMAttribute *attr;
	while (key = [enumerator nextObject]) {
		attr = [attrs objectForKey:key];
		int element;
		if (attr) {
			if ([(DCMAttributeTag *)[attr attrTag] group] == 0x0002) {
				//keep all metaheaders
			}
			else if ([(DCMAttributeTag *)[attr attrTag] group] == 0x0008) {
				//keep these
				element = [(DCMAttributeTag *)[attr attrTag] element];
				switch (element) {
					case 0x0005:
					case 0x0020:
					case 0x0030:
					case 0x0080:
					case 0x0081:
					case 0x0082:
					case 0x0090:
					case 0x0092:
					case 0x0094:
					case 0x0096:
					case 0x0116:
					case 0x0201:
					case 0x1010:
					case 0x1030:
					case 0x1040:
					case 0x1048:
					case 0x1049:
					case 0x1050:
					case 0x1052:
					case 0x1060:
					case 0x1062:
					case 0x1080:
					case 0x1084:
					case 0x1100:
					case 0x1110:
					case 0x1120:
					case 0x1125:
					case 0x2218:
					case 0x2220:
					case 0x2228:
					case 0x2229:
					case 0x2230:
							break;
					default: [keysToRemove addObject:key]; 
				}
			}
			else if ([(DCMAttributeTag *)[attr attrTag] group] == 0x0010) {
				//keep these
				element = [(DCMAttributeTag *)[attr attrTag] element];
				switch (element) {
					case 0x0010:
					case 0x0020:
					case 0x0021:
					case 0x0030:
					case 0x0032:
					case 0x0040:
					case 0x0050:
					case 0x0101:
					case 0x0102:
					case 0x1000:
					case 0x1001:
					case 0x1005:
					case 0x1010:
					case 0x1020:
					case 0x1030:
					case 0x1040:
					case 0x1060:
					case 0x1080:
					case 0x1081:
					case 0x1090:
					case 0x2000:
					case 0x2110:
					case 0x2150:
					case 0x2152:
					case 0x2154:
					case 0x2160:
					case 0x2180:
					case 0x21A0:
					case 0x21B0:
					case 0x21C0:
					case 0x21D0:
					case 0x21F0:
					case 0x4000:
							break;
					default: [keysToRemove addObject:key]; 
				}
			}
			else if ([(DCMAttributeTag *)[attr attrTag] group] == 0x0020) {
				//keep these
				element = [(DCMAttributeTag *)[attr attrTag] element];
				switch (element) {
					case 0x000D:
					case 0x0010:
					case 0x1070:
					case 0x1200:
					case 0x1202:
					case 0x1204:
					case 0x1206:
					case 0x1208:					
						break;
					default: [keysToRemove addObject:key]; 
				}

			}
			else	
				[keysToRemove addObject:key];
		} //if


		
	} //while 
	//attributes to add
	[attrs removeObjectsForKeys:keysToRemove];
	DCMAttributeTag *SOPClassUIDTag = [DCMAttributeTag tagWithName:@"SOPClassUID"];
	NSMutableArray *SOPClassUIDValue = [NSMutableArray arrayWithObject:DCM_SecondaryCaptureImageStorage];
	DCMAttribute *SOPClassUIDAttr = [DCMAttribute attributeWithAttributeTag:SOPClassUIDTag  vr:[SOPClassUIDTag vr]  values:SOPClassUIDValue];
	[attrs setObject:SOPClassUIDAttr forKey:@"SOPClassUID"];
	NSMutableArray *mediaStorageSOPClassUIDValue = [NSMutableArray arrayWithObject:DCM_SecondaryCaptureImageStorage];
	DCMAttributeTag *mediaStorageSOPClassUIDTag = [DCMAttributeTag tagWithName:@"MediaStorageSOPClassUID"];
	DCMAttribute *mediaStorageSOPClassUIDAttr = [DCMAttribute attributeWithAttributeTag:mediaStorageSOPClassUIDTag  vr:[mediaStorageSOPClassUIDTag vr]  values:mediaStorageSOPClassUIDValue];
	[attrs setObject:mediaStorageSOPClassUIDAttr forKey:@"MediaStorageSOPClassUID"];
	
	//DCMAttributeTag *SOPClassUIDTag = [DCMAttributeTag tagWithName:@"SOPClassUID"];
	
	DCMAttributeTag *scDeviceIDTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceID"];
	NSMutableArray *scDeviceIDValue = [NSMutableArray arrayWithObject:@"OsiriX"];
	DCMAttribute *scDeviceIDAttr = [DCMAttribute attributeWithAttributeTag:scDeviceIDTag  vr:[scDeviceIDTag vr]  values:scDeviceIDValue];
	[attrs setObject:scDeviceIDAttr forKey:@"SecondaryCaptureDeviceID"];
	
	DCMAttributeTag *scDeviceManufacturerTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceManufacturer"];
	NSMutableArray *scDeviceManufacturerValue = [NSMutableArray arrayWithObject:@"OsiriX"];
	DCMAttribute *scDeviceManufacturerAttr = [DCMAttribute attributeWithAttributeTag:scDeviceManufacturerTag  vr:[scDeviceManufacturerTag vr]  values:scDeviceManufacturerValue];
	[attrs setObject:scDeviceManufacturerAttr forKey:@"SecondaryCaptureDeviceManufacturer"];
	
	DCMAttributeTag *scDeviceModelTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceManufacturersModelName"];
	NSMutableArray *scDeviceModelValue = [NSMutableArray arrayWithObject:@"OsiriX"];
	DCMAttribute *scDeviceModelAttr = [DCMAttribute attributeWithAttributeTag:scDeviceModelTag  vr:[scDeviceModelTag vr]  values:scDeviceModelValue];
	[attrs setObject:scDeviceModelAttr forKey:@"SecondaryCaptureDeviceManufacturersModelName"];
	
	DCMAttributeTag *scDeviceSoftwareTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceSoftwareVersions"];
	NSMutableArray *scDeviceSoftwareValue = [NSMutableArray arrayWithObject:@"1.4"];
	DCMAttribute *scDeviceSoftwareAttr = [DCMAttribute attributeWithAttributeTag:scDeviceSoftwareTag  vr:[scDeviceSoftwareTag vr]  values:scDeviceSoftwareValue];
	[attrs setObject:scDeviceSoftwareAttr forKey:@"SecondaryCaptureDeviceSoftwareVersions"];
	
	DCMAttributeTag *scDateTag = [DCMAttributeTag tagWithName:@"DateofSecondaryCapture"];
	NSMutableArray *scDateValue = [NSMutableArray arrayWithObject:[DCMCalendarDate date]];
	DCMAttribute *scDateAttr = [DCMAttribute attributeWithAttributeTag:scDateTag  vr:[scDateTag vr]  values:scDateValue];
	[attrs setObject:scDateAttr forKey:@"DateofSecondaryCapture"];
	
	DCMAttributeTag *scTimeTag = [DCMAttributeTag tagWithName:@"TimeofSecondaryCapture"];
	NSMutableArray *scTimeValue = [NSMutableArray arrayWithObject:[DCMCalendarDate date]];
	DCMAttribute *scTimeAttr = [DCMAttribute attributeWithAttributeTag:scTimeTag  vr:[scTimeTag vr]  values:scTimeValue];
	[attrs setObject:scTimeAttr forKey:@"TimeofSecondaryCapture"];
	
	DCMAttributeTag *modalityTag = [DCMAttributeTag tagWithName:@"Modality"];
	NSMutableArray *modalityValue = [NSMutableArray arrayWithObject:@"SC"];
	DCMAttribute *modalityAttr = [DCMAttribute attributeWithAttributeTag:modalityTag  vr:[modalityTag vr]  values:modalityValue];
	[attrs setObject:modalityAttr forKey:@"Modality"];
	
	[scObject newSeriesInstanceUID];
	[scObject newSOPInstanceUID];
	[scObject updateMetaInformationWithTransferSyntax:[scObject transferSyntax] aet:@"OsiriX"];
	return scObject;
}

+ (id)secondaryCaptureObjectWithBitDepth:(int)bitDepth  samplesPerPixel:(int)spp numberOfFrames:(int)nff{
	DCMObject *scObject = [[[DCMObject alloc] init] autorelease];
	NSString *abstractSyntax;
	//NSLog(@"Number Frames for SC: %d", nff);
	if (nff > 1) {
		if	(spp > 1)
			abstractSyntax = [DCMAbstractSyntaxUID multiframeTrueColorSecondaryCaptureImageStorage];
		else if (bitDepth < 8)
			abstractSyntax = [DCMAbstractSyntaxUID multiframeSingleBitSecondaryCaptureImageStorage];
		else if (bitDepth == 8)
			abstractSyntax = [DCMAbstractSyntaxUID multiframeGrayscaleByteSecondaryCaptureImageStorage];
		else
			abstractSyntax = [DCMAbstractSyntaxUID multiframeGrayscaleWordSecondaryCaptureImageStorage];
	}
	else
		abstractSyntax = [DCMAbstractSyntaxUID secondaryCaptureImageStorage];
	//secondary capture tags	
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:abstractSyntax] forName:@"SOPClassUID"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:abstractSyntax] forName:@"MediaStorageSOPClassUID"];	
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"OsiriX"]  forName:@"SecondaryCaptureDeviceID"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"OsiriX"]  forName:@"SecondaryCaptureDeviceManufacturer"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"OsiriX"]  forName:@"SecondaryCaptureDeviceManufacturersModelName"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"2.0.0"]  forName:@"SecondaryCaptureDeviceSoftwareVersions"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]]  forName:@"DateofSecondaryCapture"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]]  forName:@"TimeofSecondaryCapture"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"SC"]  forName:@"Modality"];
	//[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"SC"]  forName:@"Modality"];
	//new UIDs
	[scObject newStudyInstanceUID];
	[scObject newSeriesInstanceUID];
	[scObject newSOPInstanceUID];
	
	[scObject updateMetaInformationWithTransferSyntax: [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] aet:@"osirix"];
	//Patient Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
	[scObject setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
	//Study Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"StudyID"];
	[scObject setAttributeValues:[NSMutableArray array] forName:@"StudyDescription"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"StudyDate"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"StudyTime"];
	//Series Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"SeriesDescription"];
	[scObject setAttributeValues:[NSMutableArray array] forName:@"SeriesNumber"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"SeriesDate"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"SeriesTime"];
	//Instance Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"InstanceNumber"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"AcquisitionDate"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"AcquisitionTime"];
	// pixel Data info
	/*
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:nff]] forName:@"NumberofFrames"];

SamplesperPixel
PhotometricInterpretation
PlanarConfiguration
Rows
Columns
PixelSpacing
BitsAllocated
BitsStored
HighBit
PixelRepresentation
	*/
	

	[scObject updateMetaInformationWithTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] aet:@"OsiriX"];
	return scObject;


}

+ (id)objectWithData:(NSData *)data decodingPixelData:(BOOL)decodePixelData{
	return [[[DCMObject alloc] initWithData:data decodingPixelData:decodePixelData] autorelease];
}

+ (id)objectWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData{
	
	return [[[DCMObject alloc] initWithContentsOfFile:file decodingPixelData:decodePixelData] autorelease];
}

+ (id)objectWithContentsOfURL:(NSURL *)aURL decodingPixelData:(BOOL)decodePixelData{
		return [[[DCMObject alloc] initWithContentsOfURL:aURL decodingPixelData:decodePixelData] autorelease];
}
 + (id)objectWithObject:(DCMObject *)object{
	return [[[DCMObject alloc] initWithObject:object] autorelease];
}
		
- (id)initWithData:(NSData *)data decodingPixelData:(BOOL)decodePixelData{
	DCMDataContainer *container = [DCMDataContainer dataContainerWithData:data];
	long offset = 0;
	if (DEBUG)
			NSLog(@"start byteOffset: %d", offset);
	if (DEBUG)
		NSLog(@"Container length:%d  offet:%d", [container length],[container offset]);
	return [self  initWithDataContainer:container lengthToRead:[container length] - [container offset] byteOffset:&offset characterSet:nil decodingPixelData:decodePixelData];

}

- (id)initWithData:(NSData *)data transferSyntax:(DCMTransferSyntax *)syntax{
	DCMDataContainer *container = [DCMDataContainer dataContainerWithData:data transferSyntax:syntax];
	long offset = 0;
	return [self  initWithDataContainer:container lengthToRead:[container length] byteOffset:&offset characterSet:nil decodingPixelData:NO];
}

- (id)initWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData{
	if([[NSFileManager defaultManager] fileExistsAtPath:file] == NO) return 0L;
	NSData *aData = [NSData dataWithContentsOfMappedFile:file];
	return [self initWithData:aData decodingPixelData:decodePixelData] ;
}

- (id)initWithContentsOfURL:(NSURL *)aURL decodingPixelData:(BOOL)decodePixelData{
	NSData *aData = [NSData dataWithContentsOfURL:aURL];
	return [self initWithData:aData decodingPixelData:decodePixelData] ;
}

- (id)initWithDataContainer:(DCMDataContainer *)data lengthToRead:(long)lengthToRead byteOffset:(long  *)byteOffset characterSet:(DCMCharacterSet *)characterSet decodingPixelData:(BOOL)decodePixelData{
	if (self = [super init]) {
		//NSDate *timestamp =[NSDate date];
		_decodePixelData = decodePixelData;
		sharedTagDictionary = [DCMTagDictionary sharedTagDictionary];
		sharedTagForNameDictionary = [DCMTagForNameDictionary sharedTagForNameDictionary];
		attributes = [[NSMutableDictionary dictionary] retain];
		if (characterSet)
			specificCharacterSet = [characterSet retain];
		else
			specificCharacterSet = [[DCMCharacterSet alloc] initWithCode:@"ISO_IR 100"];
		transferSyntax = [[data transferSyntaxForDataset] retain];
		DCMDataContainer *dicomData;
		dicomData = [data retain];
			
		*byteOffset = [self readDataSet:dicomData lengthToRead:lengthToRead byteOffset:byteOffset];
		
		if (*byteOffset == 0xffffffffl)
			self = nil;
		
		if (DEBUG)
			NSLog(@"end readDataSet byteOffset: %d", *byteOffset);
		[dicomData release];
			//NSLog(@"DCMObject end init: %f", -[timestamp  timeIntervalSinceNow]); 
	}

	return self;
}

- (id)initWithObject:(DCMObject *)object{
	if (self = [super init]){
		specificCharacterSet = [[object specificCharacterSet] copy];
		attributes = [[object attributes] mutableCopy];
		transferSyntax = [[object transferSyntax] copy];
		_decodePixelData = [object pixelDataIsDecoded];
	}
	//NSLog(@"initWithObject");
	return self;
}

- (id)init {
	if (self = [super init]) {
		sharedTagDictionary = [DCMTagDictionary sharedTagDictionary];
		sharedTagForNameDictionary = [DCMTagForNameDictionary sharedTagForNameDictionary];
		attributes = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	return [[DCMObject allocWithZone:zone] initWithObject:self];
}

- (void) dealloc {
	//NSLog(@"Dealloc DCMObject");
	[specificCharacterSet release];
	[attributes release];
	[transferSyntax release];
	[super dealloc];
}


- (long)readDataSet:(DCMDataContainer *)dicomData lengthToRead:(long)lengthToRead byteOffset:(long *)byteOffset{

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL readingMetaHeader = NO;
	int endMetaHeaderPosition = 0;					
	BOOL undefinedLength = lengthToRead == 0xffffffffl;	
	long endByteOffset= (undefinedLength) ? 0xffffffffl : *byteOffset + lengthToRead - 1;
	BOOL isExplicit = [[dicomData transferSyntaxInUse] isExplicit];
	BOOL forImplicitUseOW = NO;
	

	BOOL pixelRepresentationIsSigned = NO;
	
	@try
	{
	while ((undefinedLength || *byteOffset < endByteOffset)) {
		NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
		if (DEBUG) {
			NSLog(@"byteOffset:%d, endByteOffset:%d", *byteOffset, endByteOffset);
		}
		
		int group = [self getGroup:dicomData];
		int element = [self getElement:dicomData];
		if (group > 0x0002) {
			//NSLog(@"start reading dataset");
			[dicomData startReadingDataSet];
		}
		
		else if (transferSyntax != nil && group == 0x0002 && element == 0x0010) {
			//workaround for extra Transfer Syntax element in some Conquest files
			[dicomData startReadingDataSet];
		}
		
		isExplicit = [[dicomData transferSyntaxInUse] isExplicit];
		//NSLog(@"DCMObject readTag: %f", -[timestamp  timeIntervalSinceNow]);
		DCMAttributeTag *tag = [[[DCMAttributeTag alloc]  initWithGroup:group element:element] autorelease];
		*byteOffset+=4;
		
		const char *tagUTF8 = [[tag stringValue] UTF8String];


		if (DEBUG)
			NSLog(@"Tag: %@  group: 0x%4000x  word 0x%4000x", [tag description], group, element);
			// "FFFE,E00D" == Item Delimitation Item
		if (strcmp(tagUTF8, "FFFE,E00D") == 0) {
			// Read and discard value length
			[dicomData nextUnsignedLong];
			*byteOffset+=4;
			if (DEBUG)
				NSLog(@"ItemDelimitationItem");
			break;
			//return *byteOffset;	// stop now, since we must have been called to read an item's dataset
		}
		
		// "FFFE,E000" == Item 
		else if (strcmp(tagUTF8, "FFFE,E000") == 0) {
			// this is bad ... there shouldn't be Items here since they should
			// only be found during readNewSequenceAttribute()
			// however, try to work around Philips bug ...
			long vl = [dicomData nextUnsignedLong];		// always implicit VR form for items and delimiters
			*byteOffset+=4;
			NSLog(@"Ignoring bad Item at %d  %@ VL=<0x%x", *byteOffset, [tag stringValue], vl);
			// let's just ignore it for now
			//continue;
		}
		// get tag Values
		else {
		// get vr

			NSString *vr;
			long vl = 0;
			if (isExplicit) {
				vr = [dicomData nextStringWithLength:2];
				if (DEBUG)
					NSLog(@"Explicit VR %@", vr);
				*byteOffset+=2;
				if (!vr)
					vr = [tag vr];
			}
			
			//implicit
			else{

				vr = [tag vr];
				if (!vr)
					vr = @"UN";
				if ([vr isEqualToString:@"US/SS/OW"])
					vr = @"OW";
				// set VR for Pixel Description depenedent tags. Can be either  US or SS depending on Pixel Description
				if ([vr isEqualToString:@"US/SS"]) {
				if ( pixelRepresentationIsSigned)
						vr = @"SS";
					else 
						vr = @"US";
				}
				if (DEBUG)
					NSLog(@"Implicit VR %@", vr);	


			}
			//if (DEBUG)
			//	NSLog(@"byteoffset after vr %d, VR:%@",*byteOffset,  vr, vl);
		//  ****** get length *********
			if (isExplicit) {
				if ([DCMValueRepresentation isShortValueLengthVR:vr]) {
					vl = [dicomData nextUnsignedShort];
					*byteOffset+=2;
				}
				else {
					[dicomData nextUnsignedShort];	// reserved bytes
					vl = [dicomData nextUnsignedLong];
					*byteOffset+=6;
				}
			}
			else {
				vl = [dicomData nextUnsignedLong];
				*byteOffset += 4;
			}
			if (DEBUG)
				NSLog(@"Tag: %@, length: %d", [tag description], vl);
			//if (DEBUG)
			//	NSLog(@"byteoffset after length %d, VR:%@  length:%d",*byteOffset,  vr, vl);
				
		
			// generate Attributes
			DCMAttribute *attr = nil;
			//sequence attribute
			
			if ([DCMValueRepresentation isSequenceVR:vr] || ([DCMValueRepresentation  isUnknownVR:vr] && vl == 0xffffffffl)) {
				//NSLog(@"DCMObject sequence: %f", -[timestamp  timeIntervalSinceNow]);
					attr = (DCMAttribute *) [[[DCMSequenceAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
					*byteOffset = [self readNewSequenceAttribute:attr dicomData:dicomData byteOffset:byteOffset lengthToRead:vl specificCharacterSet:specificCharacterSet];

			} 
			
			// "7FE0,0010" == PixelData
			else if (strcmp(tagUTF8, "7FE0,0010") == 0) {			
				attr = (DCMPixelDataAttribute *) [[[DCMPixelDataAttribute alloc]	initWithAttributeTag:(DCMAttributeTag *)tag 
				vr:(NSString *)vr 
				length:(long) vl 
				data:(DCMDataContainer *)dicomData 
				specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
				transferSyntax:[dicomData transferSyntaxForDataset]
				dcmObject:self
				decodeData:_decodePixelData] autorelease];
					*byteOffset = endByteOffset;
			}
			else if (vl != 0xffffffffl && vl != 0) {
				if ([self isNeededAttribute:(char *)tagUTF8])
					attr = [[[DCMAttribute alloc] initWithAttributeTag:tag 
						vr:vr 
						length: vl 
						data:dicomData 
						specificCharacterSet:specificCharacterSet
						isExplicit:[dicomData isExplicitTS]
						forImplicitUseOW:forImplicitUseOW] autorelease];
				else {
					attr = nil;
					[dicomData skipLength:vl];
				}
				*byteOffset += vl;
				if (DEBUG)
					NSLog(@"byteOffset %d attr %@", *byteOffset, [attr description]);
			}

			if (DEBUG)
				NSLog(@"Attr: %@", [attr description]);
			//add attr to attributes
			if (attr)
				CFDictionarySetValue((CFMutableDictionaryRef)attributes, [tag stringValue], attr);
				
			// 0002,0000 = MetaElementGroupLength
			if (strcmp(tagUTF8, "0002,0000") == 0) {
				readingMetaHeader = YES;
				if (DEBUG)
					NSLog(@"metaheader length : %d", [[attr value] intValue]);
				endMetaHeaderPosition = [[attr value] intValue] + *byteOffset;
				[dicomData startReadingMetaHeader];
			}
			//0002,0010 == TransferSyntaxUID
			else if (strcmp(tagUTF8, "0002,0010") == 0  
				&& transferSyntax == nil)  //some conquest files have the transfer Syntax twice. Need to ignore to second one
				 {
					
				DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS:[attr value]] autorelease];
				[transferSyntax release];
				transferSyntax = [ts retain];
				[dicomData setTransferSyntaxForDataset:ts];
			}
			
			//0008,0005 == SpecificCharacterSet
			else if (strcmp(tagUTF8, "0008,0005") == 0) {
				[specificCharacterSet release];
				specificCharacterSet = [[DCMCharacterSet alloc] initWithCode:[attr value]];
			}

				
			/*
			if (readingMetaHeader && (*byteOffset >= endMetaHeaderPosition)) {
				if (DEBUG)
					NSLog(@"End reading Metaheader. Metaheader position: %d, byteOffset: %d", endMetaHeaderPosition, *byteOffset);
				readingMetaHeader = NO;
				[dicomData startReadingDataSet];
			}
			*/	
				

		}
		[subPool release];
				
	}
	[transferSyntax release];
	transferSyntax = [[dicomData transferSyntaxForDataset] retain];
	}
	
	@catch (NSException *ne)
	{
		NSLog(@"Error reading data for dicom object");
		NSLog( [ne description]);
		*byteOffset = 0xffffffffl;
	}
	//NSLog(@"DCMObject  End readDataSet: %f", -[timestamp  timeIntervalSinceNow]);
	[pool release];
	//[exception raise];
	
	return *byteOffset;
}

- (long) readNewSequenceAttribute:(DCMAttribute *)attr dicomData:(DCMDataContainer *)dicomData byteOffset:(long *)byteOffset lengthToRead:(long)lengthToRead specificCharacterSet:(DCMCharacterSet *)aSpecificCharacterSet{

	BOOL undefinedLength = lengthToRead == 0xffffffffl;
	long endByteOffset = (undefinedLength) ? 0xffffffffl : *byteOffset+lengthToRead-1;
	NSException *myException;
	NS_DURING
		if (DEBUG)
			NSLog(@"Read newSequence:%@  lengthtoRead:%d byteOffset:%d, characterSet: %@", [attr description], lengthToRead, *byteOffset, [aSpecificCharacterSet characterSet] );
		while (undefinedLength || *byteOffset < endByteOffset) {
			NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
			long itemStartOffset=*byteOffset;
			int group = [self getGroup:dicomData];
			int element = [self getElement:dicomData];
			DCMAttributeTag *tag = [[[DCMAttributeTag alloc]  initWithGroup:group element:element] autorelease];
			*byteOffset+=4;
			
			long vl = [dicomData nextUnsignedLong];		// always implicit VR form for items and delimiters
			*byteOffset+=4;
//System.err.println(byteOffset+" "+tag+" VL=<0x"+Long.toHexString(vl)+">");
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"SequenceDelimitationItem"]]) {
				if (DEBUG)
					NSLog(@"SequenceDelimitationItem");
//System.err.println("readNewSequenceAttribute: SequenceDelimitationItem");
				break;
			}
			else if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"Item"]]) {
				if (DEBUG)
				NSLog(@"New Item");
				DCMObject *object = [[[[self class] alloc] initWithDataContainer:dicomData lengthToRead:vl byteOffset:byteOffset characterSet:specificCharacterSet decodingPixelData:NO] autorelease];
				//DCMObject *object = [[[DCMObject alloc] initWithDataContainer:dicomData lengthToRead:vl byteOffset:byteOffset characterSet:specificCharacterSet decodingPixelData:NO] autorelease];

				[(DCMSequenceAttribute *)attr  addItem:object offset:itemStartOffset];
				if (DEBUG)
					NSLog(@"end New Item");
			}
			else {
				myException = [NSException exceptionWithName:@"DCM Bad Tag"  reason:@"(not Item or Sequence Delimiter) in Sequence at byte offset " userInfo:nil];
				[myException raise];
			}
			[subPool release];
		}
		
		
	NS_HANDLER
		NSLog(@"Error");
		*byteOffset = -1;
	NS_ENDHANDLER
		return *byteOffset;
	
	
}

- (DCMAttribute *) newAttributeForAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicit
			forImplicitUseOW:(BOOL)forImplicitUseOW {
	DCMAttribute *a = nil;

		return a;
}




//Dicom Parsing
- (int)getGroup:(DCMDataContainer *)dicomData{
	int group = [dicomData nextUnsignedShort];
	return group;
}
- (int)getElement:(DCMDataContainer *)dicomData{
	int element = [dicomData nextUnsignedShort];
	return element;
}
- (int)length:(DCMDataContainer *)dicomData{
	int length = 0;
	return length;
}

- (NSString *)getvr:(DCMDataContainer *)dicomData forTag:(DCMAttributeTag *)tag isExplicit:(BOOL)isExplicit{
/*
	if (isExplicit) {
		//char vr[2] = 
	}
	else{
	}
*/
	NSString *vr = @"";
	return vr;
}

- (NSMutableArray *)getValues:(DCMDataContainer *)dicomData{
	NSMutableArray *values = [NSMutableArray array];
	return values;
}

- (NSString *)description{

	NSString *description = @"";
	NSArray *keys = [[attributes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSEnumerator *enumerator = [keys objectEnumerator];
	DCMAttribute *attr;
	NSString *key;
	while (key = [enumerator nextObject]) {
		//NSLog(@"key: %@", key);
		attr = [attributes objectForKey:key];
		description = [NSString stringWithFormat:@"%@ \n%@", description, [attr description]];
	}
	return description;
	
}

- (void)removeMetaInformation{
	NSEnumerator *enumerator = [attributes keyEnumerator];
	NSString *key;
	NSMutableArray *keysToRemove = [NSMutableArray array];
	while (key = [enumerator nextObject]) {
		DCMAttribute *attr = [attributes objectForKey:key];
		if ([(DCMAttributeTag *)[attr attrTag] group] == 0x0002)
			[keysToRemove addObject:key];
		}
	[attributes removeObjectsForKeys:keysToRemove];
}

- (void)updateMetaInformationWithTransferSyntax: (DCMTransferSyntax *)ts aet:(NSString *)aet{
/*
	mandatory attributes:
		FileMetaInformationVersion
		MediaStorageSOPClassUID
		MediaStorageSOPInstanceUID
		TransferSyntaxUID
		ImplementationClassUID
		SourceApplicationEntityTitle
		groupLengthTag
		
*/
	int gl = 0;

	// FileMetaInformationVersion
	DCMAttributeTag *tag = [[DCMAttributeTag alloc] initWithName:@"FileMetaInformationVersion"];
	DCMAttribute *attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	char bytes[2];
	bytes[0] = 0x00;
	bytes[1] = 0x01;
	NSData *data = [NSData dataWithBytes:bytes length:2];
	[attr addValue:data];
	[attributes setObject:attr forKey:[tag stringValue]];
	gl += [attr paddedLength];
	gl += (4+4+4);
	if (DEBUG)
		NSLog(@"padded Length: %d  group length: %d", [attr paddedLength], gl);
	[attr release];
	[tag release];

	
	//should already have MediaStorageClassUID and InstanceUID
	if ([self attributeWithName:@"MediaStorageSOPClassUID"]){
		gl += (4+2+2);
		gl += [[self attributeWithName:@"MediaStorageSOPClassUID"] paddedLength];
	}
	//need to copy SOPCLassUID"
	else{
		NSString *sopClassUID = [self attributeValueWithName:@"SOPClassUID"];
		if (sopClassUID) {
			tag = [[DCMAttributeTag alloc] initWithName:@"MediaStorageSOPClassUID"];
			attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
			[attr addValue:sopClassUID];
			[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
			gl += [attr paddedLength];
			gl += (4+2+2);
		}
	}
	
	if ([self attributeWithName:@"MediaStorageSOPInstanceUID"]){
		gl += (4+2+2);
		gl += [[self attributeWithName:@"MediaStorageSOPInstanceUID"] paddedLength];
	}	//need to copy SOPInstanceUID"
	else{
		NSString *sopInstanceUID = [self attributeValueWithName:@"SOPInstanceUID"];
		if (sopInstanceUID) {
			tag = [[DCMAttributeTag alloc] initWithName:@"MediaStorageSOPInstanceUID"];
			attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
			[attr addValue:sopInstanceUID];
			[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
			gl += [attr paddedLength];
			gl += (4+2+2);
		}
	}


	//TransferSyntaxUID
	tag = [[DCMAttributeTag alloc] initWithName:@"TransferSyntaxUID"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:[ts transferSyntax]];
	[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
	gl += [attr paddedLength];
	gl += (4+2+2);

	[attr release];
	[tag release];
	
	//ImplementationClassUID
	tag = [[DCMAttributeTag alloc] initWithName:@"ImplementationClassUID"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:rootUID];
	[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
	gl += [attr paddedLength];
	gl += (4+2+2);

	[attr release];
	[tag release];
	
	//ImplementationVersionName
	tag = [[DCMAttributeTag alloc] initWithName:@"ImplementationVersionName"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:@"OSIRIX001"];
	[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
	gl += [attr paddedLength];
	gl += (4+2+2);
	[attr release];
	[tag release];
	
	
	//SourceApplicationEntityTitle
	if (aet) {
		tag = [[DCMAttributeTag alloc] initWithName:@"SourceApplicationEntityTitle"];
		attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
		[attr addValue:aet];
		[attributes setObject:attr forKey:[tag stringValue]];
		[attr release];
		[tag release];
	}

	
	

	
	attr = [attributes objectForKey:[sharedTagForNameDictionary objectForKey:@"SourceApplicationEntityTitle"]];
	if (attr) {
		gl += (4+2+2);	// 1 fixed EVR short-length-form elements
		gl += [attr paddedLength];
	}
	

			//groupLengthTag
	tag = [[DCMAttributeTag alloc] initWithName:@"MetaElementGroupLength"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:[NSNumber numberWithInt:gl]];
	[attributes setObject:attr forKey:[tag stringValue]];

	[attr release];
	[tag release];



}

- (DCMAttribute *)attributeForTag:(DCMAttributeTag *)tag{
	return [attributes objectForKey:[tag stringValue]];
}

- (DCMAttribute *)attributeWithName:(NSString *)name{
	return [self attributeForTag:[DCMAttributeTag tagWithName:name]];
}

- (id)attributeValueWithName:(NSString *)name{
	return [[self attributeForTag:[DCMAttributeTag tagWithName:name]] value];
}

- (id)attributeValueForKey:(NSString *)key{
	return [[attributes objectForKey:key] value];
}

- (NSArray *)attributeArrayWithName:(NSString *)name{
	return [[self attributeForTag:[DCMAttributeTag tagWithName:name]] values];
}

- (void)setAttribute:(DCMAttribute *)attr{
	[attributes setObject:attr  forKey:[(DCMAttributeTag *)[attr attrTag] stringValue]];
}

- (void)addAttributeValue:(id)value   forName:(NSString *)name{	
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:name];
	DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:(DCMAttributeTag *)tag];
	if ([attributes objectForKey:[tag stringValue]])
		[[attributes objectForKey:[tag stringValue]] addValue:value];
	else {
		[attr addValue:value];
		[attributes setObject:attr forKey:[tag stringValue]];
	}
}

- (void)setAttributeValues:(NSMutableArray *)values forName:(NSString *)name{
	//NSLog(@"setAttr: %@", name);
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:name];
	DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:(DCMAttributeTag *)tag];
	[attr setValues:values];
	[attributes setObject:attr forKey:[tag stringValue]];
}

-(NSMutableDictionary *)attributes{
	return attributes;
}

- (BOOL)pixelDataIsDecoded{
	return _decodePixelData;
}

	//write Data

- (void)removeGroupLengths{
	NSEnumerator *enumerator = [attributes keyEnumerator];
	NSString *key;
	NSMutableArray *keysToRemove = [NSMutableArray array];
	while (key = [enumerator nextObject]) {
		DCMAttribute *attr = [attributes objectForKey:key];
		//remove all group lengths except for Metaheader group
		if ([(DCMAttributeTag *)[attr attrTag] element] == 0x0000 && [(DCMAttributeTag *)[attr attrTag] group] != 0x0002) {
			if (DEBUG)
				NSLog(@"Remove %@", [attr description]);
			[keysToRemove addObject:key];
		}
	}
	
	[attributes removeObjectsForKeys:keysToRemove];
	
		//dataset trailing padding
	//[attributes removeObjectForKey:@"FFFC,FFFC"];
}

- (void)removePrivateTags{
	NSEnumerator *enumerator = [attributes keyEnumerator];
	NSString *key;
	NSMutableArray *keysToRemove = [NSMutableArray array];
	while (key = [enumerator nextObject]) {
		DCMAttribute *attr = [attributes objectForKey:key];
		//remove all group lengths except for Metaheader group
		if ([(DCMAttributeTag *)[attr attrTag] group] % 2 != 0) {
			if (DEBUG)
				NSLog(@"Remove Private Tag %@", [attr description]);
			[keysToRemove addObject:key];
		}
	}
	[attributes removeObjectsForKeys:keysToRemove];
}

- (void)removePlanarAndRescaleAttributes{
	[attributes removeObjectForKey:[[DCMAttributeTag tagWithName:@"RescaleSlope"] stringValue]];
	[attributes removeObjectForKey:[[DCMAttributeTag tagWithName:@"RescaleIntercept"] stringValue]];;
	[attributes removeObjectForKey:[[DCMAttributeTag tagWithName:@"PlanarConfiguration"] stringValue]];;
}


- (void)anonyimizeAttributeForTag:(DCMAttributeTag *)tag replacingWith:(id)aValue{
	DCMAttribute *attr = [attributes objectForKey:[tag stringValue]];
	//Add attr is aValue exists create attr if absent and add new value
	if (aValue && !attr) {
		attr = [DCMAttribute attributeWithAttributeTag:(DCMAttributeTag *)tag];
		[attr addValue:aValue];
		[attributes setObject:attr forKey:[tag stringValue]];
	}
	
	
	/*change data if attribute exists.
	Will not change UIDs or metaheader tags
	  Change will depend on vr.  Change date to 1/1/2000.  Change strings to  something.  change numbers to 0.
	  
	*/
	// NSLog(@"anonyimizeAttributeForTag:%@  aValue%@", tag, aValue);
//	if ([(DCMAttributeTag *)[attr attrTag] isEquaToTag:[DCMAttributeTag tagWithName:@"PatientsSex"]])
//		[attr setValues:[NSMutableArray array]];
//	if ([(DCMAttributeTag *)[attr attrTag] isEquaToTag:[DCMAttributeTag tagWithName:@"PatientsBirthDate"]])
//		[attr setValues:[NSMutableArray array]];
//	else
	if (attr && [tag group] != 0x0002 && ![[tag vr] isEqualToString:@"UI"]) {
		const char *chars = [[tag vr] UTF8String];
		int vr = chars[0]<<8 | chars[1];
		NSMutableArray *values = [attr values];
		NSEnumerator *enumerator = [values objectEnumerator];
		id value;
		id newValue = nil;
		int index;
		NSString *format = nil;
		while (value = [enumerator nextObject]) {
			index = [values indexOfObject:value];
			switch (vr) {
					//NSNumbers
				case AT:	//Attribute Tag 16bit unsigned integer 
				case UL:	//unsigned Long            
				case SL:	//signed long
				case FL:	//floating point Single 4 bytes fixed
				case FD:	//double floating point 8 bytes fixed
				case US:   //unsigned short
				case SS:	//signed short
					newValue = [NSNumber numberWithInt:0];
					break;
					//calendar dates
				case DA:	format = @"%Y%m%d";
				case TM:	if (!format)
								format = @"%H%M%S";
				case DT:	if (!format)
								format = @"%Y%m%d%H%M%S";
					newValue = [DCMCalendarDate dateWithYear:[value yearOfCommonEra] month:[value monthOfYear] day:1 hour:12 minute:00 second:00 timeZone:[value timeZone]];
					if (aValue && [aValue isMemberOfClass:[NSCalendarDate class]]){
						DCMCalendarDate *date = [DCMCalendarDate dateWithString:[aValue descriptionWithCalendarFormat:format] calendarFormat:format];
						//[aValue release];
						aValue = date;
					}
					else
						aValue = nil;
					break;
				/*		
				case SQ:	//Sequence of items
						//shouldn't get here
						break;
				*/
				
						//NSData  make zeroed NSData of length of old NSData
				case UN:	//unknown
				case OB:	//other Byte byte string not little/big endian sensitive
				case OW:	//other word 16bit word
						newValue = [NSMutableData dataWithLength:[(NSData *)value length]];
						break;
					//NUmber strings	
				case SH:	//short string	
				case DS:	//Decimal String  representing floating point number 16 byte max
				case IS:	//Integer String 12 bytes max
						newValue =  @"0";
						break;
					//Age string					
				case AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
					newValue = @"000Y";
						break;
					//code string
				case CS:	//Code String   16 byte max
					newValue = @"0000";
					break;
				case AE:	//Application Entity  String 16bytes max
				case LO:	//Character String 64 char max
				case LT:	//Long Text 10240 char Max
				case PN:	//Person Name string
				case ST:	//short Text 1024 char max
				case UI:    //String for UID             
				case UT:	//unlimited text
				case QQ: 	
					//newValue = @"XXXXXXX";
					//Patient ID are unique whene anonymized. but same for each ID
					/*
					else if ([[attr attrTag] isEquaToTag:[DCMAttributeTag tagWithName:@"PatientID"]])
					{
						newValue = @"";
					}
					*/
					newValue = [self anonymizeString:[values objectAtIndex:index]];
					break;
	 
			}
			

			if (aValue) {
				if (DEBUG)
					NSLog(@"Anonymize Values: %@ to value: %@",[attr description], [aValue description]);
				[values replaceObjectAtIndex:index withObject:aValue];
			}
			else {
				if (DEBUG)
					NSLog(@"Anonymize Values: %@ to value: %@",[attr description], [newValue description]);
				[values replaceObjectAtIndex:index withObject:newValue];
			}
		}	
		
	}

}

- (NSString *)anonymizeString:(NSString *)string{
	int root = 0;
	int i = 0;
	int value = 0;
	char newChar = 0;
	char x;
	int length = [string length];
	char newString[length];
	const char *chars = [string UTF8String];
	while (i < length) {
		root +=  chars[i];
		value = root * length * chars[i];
		x = value%65;
		switch(x) {
			case 0: newChar = '0';
				break;
			case 1: newChar = '1';
				break;
			case 2: newChar = '2';
				break;
			case 3: newChar = '3';
				break;
			case 4: newChar = '4';
				break;
			case 5: newChar = '5';
				break;
			case 6: newChar = '6';
			break;
			case 7: newChar = '7';
			break;
			case 8: newChar = '8';
			break;
			case 9: newChar = '9';
			break;
			case 10: newChar = 'a';
			break;
			case 11: newChar = 'b';
			break;
			case 12: newChar = 'c';
			break;
			case 13: newChar = 'd';
			break;
			case 14: newChar = 'e';
			break;
			case 15: newChar = 'f';
			break;
			case 16: newChar = 'g';
			break;
			case 17: newChar = 'h';
			break;
			case 18: newChar = 'i';
			break;
			case 19: newChar = 'j';
			break;
			case 20: newChar = 'k';
			break;
			case 21: newChar = 'l';
			break;
			case 22: newChar = 'm';
			break;
			case 23: newChar = 'n';
			break;
			case 24: newChar = 'o';
			break;
			case 25: newChar = 'p';
			break;
			case 26: newChar = 'q';
			break;
			case 27: newChar = 'r';
			break;
			case 28: newChar = 's';
			break;
			case 29: newChar = 't';
			break;
			case 30: newChar = 'u';
			break;
			case 31: newChar = 'v';
			break;
			case 32: newChar = 'w';
			break;
			case 33: newChar = 'x';
			break;
			case 34: newChar = 'y';
			break;
			case 35: newChar = 'z';
			break;
			case 36: newChar = 'A';
			break;
			case 37: newChar = 'B';
			break;
			case 38: newChar = 'C';
			break;
			case 39: newChar = 'D';
			break;
			case 40: newChar = 'E';
			break;
			case 41: newChar = 'F';
			break;
			case 42: newChar = 'G';
			break;
			case 43: newChar = 'H';
			break;
			case 44: newChar = 'I';
			break;
			case 45: newChar = 'J';
			break;
			case 46: newChar = 'K';
			break;
			case 47: newChar = 'L';
			break;
			case 48: newChar = 'M';
			break;
			case 49: newChar = 'N';
			break;
			case 50: newChar = 'O';
			break;
			case 51: newChar = 'P';
			break;
			case 52: newChar = 'Q';
			break;
			case 53: newChar = 'R';
			break;
			case 54: newChar = 'S';
			break;
			case 55: newChar = 'T';
			break;
			case 56: newChar = 'U';
			break;
			case 57: newChar = 'V';
			break;
			case 58: newChar = 'W';
			break;
			case 59: newChar = 'X';
			break;
			case 60: newChar = 'Y';
			break;
			case 61: newChar = 'Z';
			break;
			case 62: newChar = '.';
			break;
			case 63: newChar = ',';
			break;
			case 64: newChar = '^';
			break;
			case 65: newChar = '~';
			break;
		}
		newString[i++] = newChar;
	}
	NSData *data = [NSData dataWithBytes:newString length:length];
	return [[[NSString alloc] initWithData:data encoding:[specificCharacterSet encoding]] autorelease];
}

- (void)newStudyInstanceUID{
	//NSString *ipAddress = [[NSHost currentHost] address];
	//NSString *curentTime = [[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d%H%M%S%F" timeZone:nil  locale:nil];
	NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSArray *values = [globallyUniqueString componentsSeparatedByString:@"-"];
	NSEnumerator *enumerator = [values objectEnumerator];
	NSString *string;
	NSMutableArray *newUIDValues = [NSMutableArray array];
	while (string = [enumerator nextObject]) {
		unsigned int hexValue;
		NSScanner *scanner = [NSScanner scannerWithString:string];
		[scanner scanHexInt:&hexValue];
		NSString *newValue = [NSString stringWithFormat:@"%u", hexValue];
		
		[newUIDValues addObject:newValue];
	}
	NSString *uidSuffix = [newUIDValues componentsJoinedByString:@""];
	
	
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"1", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	uid = [uid substringToIndex:64];
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"StudyInstanceUID"];
	NSMutableArray *attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:tag vr:[tag vr] values:attrValues];
	[attributes setObject:attr forKey:[tag stringValue]];
	//DCMAttribute *attr = [attributes objectForKey:[tag stringValue]];
	
}
- (void)newSeriesInstanceUID{
	NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSArray *values = [globallyUniqueString componentsSeparatedByString:@"-"];
	NSEnumerator *enumerator = [values objectEnumerator];
	NSString *string;
	NSMutableArray *newUIDValues = [NSMutableArray array];
	while (string = [enumerator nextObject])
	{
		unsigned int hexValue;
		NSScanner *scanner = [NSScanner scannerWithString:string];
		[scanner scanHexInt:&hexValue];
		NSString *newValue = [NSString stringWithFormat:@"%u", hexValue];
		
		[newUIDValues addObject:newValue];
	}
	NSString *uidSuffix = [newUIDValues componentsJoinedByString:@""];
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"2", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	uid = [uid substringToIndex:64];
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"SeriesInstanceUID"];
	NSMutableArray *attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:tag vr:[tag vr] values:attrValues];
	[attributes setObject:attr forKey:[tag stringValue]];
}

- (void)newSOPInstanceUID{
	NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSArray *values = [globallyUniqueString componentsSeparatedByString:@"-"];
	NSEnumerator *enumerator = [values objectEnumerator];
	NSString *string;
	NSMutableArray *newUIDValues = [NSMutableArray array];
	while (string = [enumerator nextObject]) {
		unsigned int hexValue;
		NSScanner *scanner = [NSScanner scannerWithString:string];
		[scanner scanHexInt:&hexValue];
		NSString *newValue = [NSString stringWithFormat:@"%u", hexValue];
		
		[newUIDValues addObject:newValue];
	}
	NSString *uidSuffix = [newUIDValues componentsJoinedByString:@""];
	
	
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"3", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	uid = [uid substringToIndex:64];
	//NSLog(@"SOPInstanceUID: %@  length: %d", uid, [uid length]);
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"SOPInstanceUID"];
	NSMutableArray *attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute *sopAttr = [DCMAttribute attributeWithAttributeTag:tag vr:[tag vr] values:attrValues];
	if (DEBUG)
		NSLog(@"New SOP tag: %@ attr: %@", [tag description], [sopAttr description]);
	[attributes setObject:sopAttr  forKey:[tag stringValue]];
	
	DCMAttributeTag *mediaTag = [DCMAttributeTag tagWithName:@"MediaStorageSOPInstanceUID"];
	attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute  *mediaAttr = [DCMAttribute attributeWithAttributeTag:mediaTag vr:[mediaTag vr] values:attrValues];
	[attributes setObject:mediaAttr forKey:[mediaTag stringValue]];
}
		

- (DCMTransferSyntax *)transferSyntax{
	return transferSyntax;
}

- (DCMCharacterSet *)specificCharacterSet{
	return specificCharacterSet;
}

- (void)setCharacterSet:(DCMCharacterSet *)characterSet{
	//NSLog(@"set Charcter Set: %@", [characterSet description]);
	[specificCharacterSet release];
	specificCharacterSet = [characterSet retain];
	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSEnumerator *enumerator = [sortedKeys objectEnumerator];
	enumerator = [sortedKeys objectEnumerator];
	DCMAttribute *attr;
	NSString *key;
	while (key = [enumerator nextObject]) {
		attr = [attributes objectForKey:key];
		if (attr)
			[attr setCharacterSet:specificCharacterSet];
	}
}




- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts  asDICOM3:(BOOL)flag{
	return [self writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts AET:@"OSIRIX"  asDICOM3:(BOOL)flag];
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts AET:(NSString *)aet  asDICOM3:(BOOL)flag{

	if (!ts)
		ts = transferSyntax;
	DCMTransferSyntax *explicitTS = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	[container setTransferSyntaxForDataset:ts];	
	
	NSEnumerator *enumerator;
	DCMAttribute *attr;
	NSString *key;
	NSException *exception;
	BOOL status = YES;
	//NS_DURING
	
	
	[self removeGroupLengths];
	
	//need to convert PixelData TransferSyntax
	DCMAttributeTag *pixelData = [DCMAttributeTag tagWithName:@"PixelData"];
	DCMPixelDataAttribute *pixelDataAttr = (DCMPixelDataAttribute *)[attributes objectForKey:[pixelData stringValue]];
	//NSLog(@"Pixel Data %@", [pixelDataAttr description]);
	
	//if we have the attr and the conversion failed stop
	if (pixelDataAttr && ![pixelDataAttr convertToTransferSyntax: transferSyntax quality:DCMLosslessQuality]) {
		NSLog(@"Could not convert pixel Data to %@", [transferSyntax description]);
		return NO;
	}
	
	
	if (flag) {
		[self updateMetaInformationWithTransferSyntax:ts aet:aet];
		[container addPremable];
	}

	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	enumerator = [sortedKeys objectEnumerator];
	while (key = [enumerator nextObject]) {
		//if (DEBUG)
		//	NSLog(@"key:%@ %@", key, NSStringFromClass([key class]));
		attr = [attributes objectForKey:key];
		if (attr) {
			if (flag && ([(DCMAttributeTag *)[attr attrTag] group] == 0x0002)) {
				[container setUseMetaheaderTS:YES];
				if (![attr writeToDataContainer:container withTransferSyntax:explicitTS]) {
					exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data", [attr description]] userInfo:nil];
					[exception raise];
				}
			}
			else {		
				[container setUseMetaheaderTS:NO];
				if (![attr writeToDataContainer:container withTransferSyntax:ts]) {
					exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data with syntax:%@", [attr description], [ts transferSyntax]] userInfo:nil];
					[exception raise];
				}			
			}
		}
	}
	
//	NS_HANDLER
//		if (exception)
//			NSLog(@"Exception:%@	reason:%@", [exception name], [exception reason]);
//		status =  NO;
//	NS_ENDHANDLER
	
	return status;
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality asDICOM3:(BOOL)flag{
	return [self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			strippingGroupLengthLength:YES];
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			strippingGroupLengthLength:(BOOL)stripGroupLength{
	return [self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			AET:@"OSIRIX"
			strippingGroupLengthLength:(BOOL)stripGroupLength];
	}
			

- (BOOL)writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			AET:(NSString *)aet 
			strippingGroupLengthLength:(BOOL)stripGroupLength
	{
			
	if (ts == nil)
		ts = transferSyntax;
	DCMTransferSyntax *explicitTS = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	
	
	NSEnumerator *enumerator;
	DCMAttribute *attr;
	NSString *key;
	NSException *exception = nil;
	BOOL status = YES;
	NS_DURING
	
	//routine for Files
	if (stripGroupLength)
		[self removeGroupLengths];
		
	//If ts is lossy, Need  new SOPInstanceUID
	if ([ts isEqualToTransferSyntax:[DCMTransferSyntax JPEG2000LossyTransferSyntax]]
	 || [ts isEqualToTransferSyntax:[DCMTransferSyntax JPEGBaselineTransferSyntax]] 
	 || [ts isEqualToTransferSyntax:[DCMTransferSyntax JPEGExtendedTransferSyntax]] )
		[self newSOPInstanceUID];
	//need to convert PixelData TransferSyntax
	DCMAttributeTag *pixelDataTag = [DCMAttributeTag tagWithName:@"PixelData"];
	DCMPixelDataAttribute *pixelDataAttr = (DCMPixelDataAttribute *)[attributes objectForKey:[pixelDataTag stringValue]];

	//if we have the attr and the conversion failed stop	
	if (pixelDataAttr && ![pixelDataAttr convertToTransferSyntax: ts quality:quality]) {
		NSLog(@"Could not convert pixel Data to %@", [ts description]);
		status = NO;
		//return NO;
	}
	[container setTransferSyntaxForDataset:ts];	
	if (DEBUG)
		NSLog(@"Writing DICOM Object with syntax:%@", [ts description]);
	//writing Dicom has preamble and metaheader.  Neither for dataset
	if (flag) {
		if (DEBUG)
			NSLog(@"updateMetaInformation newTransferSyntax:%@", [ts description]);
		[self updateMetaInformationWithTransferSyntax:ts aet:aet];
		[container addPremable];
	}
	
	//set character set if necessary
	if (!specificCharacterSet && [self attributeValueWithName:@"SpecificCharacterSet"])
		[self setCharacterSet:[[DCMCharacterSet alloc] initWithCode:[self attributeValueWithName:@"SpecificCharacterSet"]]];

	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	enumerator = [sortedKeys objectEnumerator];
	while (key = [enumerator nextObject]) {
		//if (DEBUG)
		//	NSLog(@"key:%@ %@", key, NSStringFromClass([key class]));
		attr = [attributes objectForKey:key];
		if (attr) {
			//skip metaheader for dataset
			if ([(DCMAttributeTag *)[attr attrTag] group] == 0x0002) {
				if (flag){
					[container setUseMetaheaderTS:YES];
					if (![attr writeToDataContainer:container withTransferSyntax:explicitTS]) {
						exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data", [attr description]] userInfo:nil];
						[exception raise];
					}
				}
			}
			else {		
				[container setUseMetaheaderTS:NO];
				if (![attr writeToDataContainer:container withTransferSyntax:ts]) {
					exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data with syntax:%@", [attr description], [ts transferSyntax]] userInfo:nil];
					[exception raise];
				}			
			}
		}
	}
	
	NS_HANDLER
		if (exception)
			NSLog(@"Exception:%@	reason:%@", [exception name], [exception reason]);
		status =  NO;
	NS_ENDHANDLER
	
	return status;

	
}


- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality{
	return [self writeToDataContainer:container withTransferSyntax:ts quality:quality asDICOM3:YES];
}

- (BOOL)writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality atomically:(BOOL)flag{
	return [self writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:@"OSIRIX" atomically:(BOOL)flag];
}

- (BOOL)writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:(NSString *)aet atomically:(BOOL)flag
{
	BOOL status = NO;
	NS_DURING		
		DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
		//if ([self writeToDataContainer:container withTransferSyntax:ts quality:quality]) {
			if ([self writeToDataContainer:(DCMDataContainer *)container 
					withTransferSyntax:(DCMTransferSyntax *)ts 
					quality:(int)quality 
					asDICOM3:YES
					AET:(NSString *)aet
					strippingGroupLengthLength:YES]) {
			status =  [[container dicomData] writeToFile:path atomically:flag];
		}
		else
			status  = NO;
		
	NS_HANDLER
		NSLog(@"Writing to %@ failed", path);
		status = NO;
	NS_ENDHANDLER
	
		return status;
}


- (BOOL)writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality atomically:(BOOL)flag {
	return [self writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:@"OSIRIX" atomically:(BOOL)flag];
}

- (BOOL)writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:(NSString *)aet atomically:(BOOL)flag{
	BOOL status = NO;
	NS_DURING
	DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
	//if ([self writeToDataContainer:container withTransferSyntax:ts quality:quality])
	if ([self writeToDataContainer:(DCMDataContainer *)container 
					withTransferSyntax:(DCMTransferSyntax *)ts 
					quality:(int)quality 
					asDICOM3:YES
					AET:(NSString *)aet
					strippingGroupLengthLength:YES]) 
		status =  [[container dicomData] writeToURL:aURL atomically:flag];
	else
		status =  NO;
	NS_HANDLER
		
	NS_ENDHANDLER
		return status;
}

//This is for creatina a dataset for sending. Need to strip FileMetaData first.

- (NSData *)writeDatasetWithTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
	NSData *data;
	NS_DURING
	if ([self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:NO
			strippingGroupLengthLength:YES]) 
				// retain data to avoid autorelease
				data = [[container dicomData] retain];
	else
		data = nil; 
	NS_HANDLER
		data = nil;
	NS_ENDHANDLER
	[pool release];
	//put data in next autorelease pool
	[data autorelease];
	return data;

}

//subclasses can overide to just pick out certain attributes and speed up 
- (BOOL)isNeededAttribute:(char *)tagString{
	return YES;
}

- (NSXMLNode *)xmlNode{
	NSXMLNode *myNode;

	NSMutableArray *elements = [NSMutableArray array];

	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	DCMAttribute *attr;
	NSString *key;
	NSEnumerator *enumerator = [sortedKeys objectEnumerator];
	while (key = [enumerator nextObject]) {
		attr = [attributes objectForKey:key];
		if (attr) 
			[elements addObject:[attr xmlNode]];
		
	}
	
	myNode = [NSXMLNode elementWithName:@"item" children:elements attributes:nil];
	return myNode;
}

- (NSXMLDocument *)xmlDocument{
	
	NSXMLElement *rootElement = [[[NSXMLElement alloc] initWithName:@"DICOMObject"] autorelease];
	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	DCMAttribute *attr;
	NSString *key;
	
	NSEnumerator *enumerator = [sortedKeys objectEnumerator];
	while (key = [enumerator nextObject]) {
		
		attr = [attributes objectForKey:key];
		if (attr) {
			
			[rootElement addChild:[attr xmlNode]];
		}
		
	}
		
	NSXMLDocument *xmlDocument = [[[NSXMLDocument alloc] initWithRootElement:rootElement] autorelease];
	NSError *error = 0L;
	if(![xmlDocument validateAndReturnError:&error])
	NSLog(@"xml Document erorr:\n%@", [error description]);
	return xmlDocument;
	
	
}

//accessing frequent sequences
- (NSArray *)referencedSeriesSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"ReferencedSeriesSequence"] sequenceItems];
}

- (NSArray *)referencedImageSequenceForObject:(DCMObject *)object{
	return [(DCMSequenceAttribute *)[object attributeWithName:@"ReferencedImageSequence"] sequenceItems];
}

//Structured Report Object
+(id)objectWithCodeValue:(NSString *)codeValue  
			codingSchemeDesignator:(NSString *)codingSchemeDesignator  
			codeMeaning:(NSString *)codeMeaning{
	DCMObject *dcmObject = [DCMObject  dcmObject];

	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codeValue] forName:@"CodeValue"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codingSchemeDesignator] forName:@"CodingSchemeDesignator"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codeMeaning] forName:@"CodeMeaning"];

	return dcmObject;
		
}





@end
