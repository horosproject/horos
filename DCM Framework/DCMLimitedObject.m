//
//  DCMLimitedObject.m
//  OsiriX
//
//  Created by Lance Pysher on 9/15/05.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//


#import "DCMLimitedObject.h"
#import "DCM.h"


@implementation DCMLimitedObject
+ (id)objectWithData:(NSData *)data lastGroup:(unsigned short)lastGroup{
	return [[[DCMObject alloc] initWithData:data lastGroup:(unsigned short)lastGroup] autorelease];
}

+ (id)objectWithContentsOfFile:(NSString *)file lastGroup:(unsigned short)lastGroup{
	return [[[DCMObject alloc] initWithContentsOfFile:file lastGroup:(unsigned short)lastGroup] autorelease];
}

+ (id)objectWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup{
	return [[[DCMObject alloc] initWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup] autorelease];
}


- (id)initWithData:(NSData *)data lastGroup:(unsigned short)lastGroup{
	DCMDataContainer *container = [DCMDataContainer dataContainerWithData:data];
	long offset = 0;
	return [self  initWithDataContainer:container lengthToRead:[container length] - [container offset] byteOffset:&offset characterSet:nil lastGroup:(unsigned short)lastGroup];

}

- (id)initWithContentsOfFile:(NSString *)file lastGroup:(unsigned short)lastGroup{
	NSData *aData = [NSData dataWithContentsOfFile:file];
	return [self initWithData:aData lastGroup:(unsigned short)lastGroup] ;
}

- (id)initWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup{
	NSData *aData = [NSData dataWithContentsOfURL:aURL];
	return [self initWithData:aData lastGroup:(unsigned short)lastGroup] ;
}

- (id)initWithDataContainer:(DCMDataContainer *)data lengthToRead:(long)lengthToRead byteOffset:(long  *)byteOffset characterSet:(DCMCharacterSet *)characterSet lastGroup:(unsigned short)lastGroup{

	if (self = [super init]) {
		//NSDate *timestamp =[NSDate date];

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
			
		*byteOffset = [self readDataSet:dicomData toGroup:(unsigned short)lastGroup byteOffset:byteOffset];
		
		if (*byteOffset == 0xffffffffl)
			self = nil;
		
		if (DEBUG)
			NSLog(@"end readDataSet byteOffset: %d", *byteOffset);
		[dicomData release];
			//NSLog(@"DCMObject end init: %f", -[timestamp  timeIntervalSinceNow]); 
	}

	return self;
}

- (long)readDataSet:(DCMDataContainer *)dicomData toGroup:(unsigned short)lastGroup byteOffset:(long *)byteOffset{

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL readingMetaHeader = NO;
	int endMetaHeaderPosition = 0;					

	long endByteOffset =  0xffffffffl;
	BOOL isExplicit = [[dicomData transferSyntaxInUse] isExplicit];
	BOOL forImplicitUseOW = NO;
	
	// keep track of pixel data size in case need Vl for encapsulated data ...
	int rows = 0;
	int columns = 0;
	int frames = 1;
	int samplesPerPixel = 1;
	int bytesPerSample = 0;
	BOOL isShort = NO;
	BOOL pixelRepresentationIsSigned = NO;
	int group = 0x0000;
	NS_DURING
	while ((group < lastGroup || group == 0xFFFE )) {
		NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];

		
		int group = [self getGroup:dicomData];
		int element = [self getElement:dicomData];
		if (group > 0x0002) {
			//NSLog(@"start reading dataset");
			[dicomData startReadingDataSet];
		}
		isExplicit = [[dicomData transferSyntaxInUse] isExplicit];
		//NSLog(@"DCMObject readTag: %f", -[timestamp  timeIntervalSinceNow]);
		DCMAttributeTag *tag = [[[DCMAttributeTag alloc]  initWithGroup:group element:element] autorelease];
		*byteOffset+=4;
		//if (DEBUG)
		//		NSLog(@"byteoffset before VR %d",*byteOffset);
		if (DEBUG)
			NSLog(@"Tag: %@  group: 0x%4000x  word 0x%4000x", [tag description], group, element);
		if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"ItemDelimitationItem"]]) {
			// Read and discard value length
			[dicomData nextUnsignedLong];
			*byteOffset+=4;
			if (DEBUG)
				NSLog(@"ItemDelimitationItem");
			break;
			//return *byteOffset;	// stop now, since we must have been called to read an item's dataset
		}
		else if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"Item"]]){
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
				//NSDictionary *tagValues = [sharedTagDictionary objectForKey:[tag stringValue]];

				//vr = [tagValues objectForKey:@"VR"];
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
			else if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"PixelData"]]) {
			
			attr = (DCMPixelDataAttribute *) [[[DCMPixelDataAttribute alloc]	initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			transferSyntax:[dicomData transferSyntaxForDataset]
			dcmObject:self
			decodeData:NO] autorelease];
				*byteOffset = endByteOffset;
			}
			else if (vl != 0xffffffffl && vl != 0) {
				//[self newAttr];
				attr = [[[DCMAttribute alloc] initWithAttributeTag:tag 
						vr:vr 
						length: vl 
						data:dicomData 
						specificCharacterSet:specificCharacterSet
						isExplicit:[dicomData isExplicitTS]
						forImplicitUseOW:forImplicitUseOW] autorelease];
				*byteOffset += vl;
				if (DEBUG)
					NSLog(@"byteOffset %d attr %@", *byteOffset, [attr description]);
			}
			/*
			else if (vl == 0xffffffffl && [[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"PixelData"]] && [[dicomData transferSyntaxInUse] isEncapsulated]) {
			}
			*/
			if (DEBUG)
				NSLog(@"Attr: %@", [attr description]);
			if (attr)
				[attributes setObject:attr forKey:[tag stringValue]];
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"MetaElementGroupLength"]])  {
				readingMetaHeader = YES;
				if (DEBUG)
					NSLog(@"metaheader length : %d", [[attr value] intValue]);
				endMetaHeaderPosition = [[attr value] intValue] + *byteOffset;
				[dicomData startReadingMetaHeader];
			}
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"TransferSyntaxUID"]]) {
					
				DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS:[attr value]] autorelease];
				[transferSyntax release];
				transferSyntax = [ts retain];
				[dicomData setTransferSyntaxForDataset:ts];
				//if (DEBUG)
				//	NSLog(@"NEW TS: %@", [ts description]);
			}
			
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"SpecificCharacterSet"]]){

				[specificCharacterSet release];
				specificCharacterSet = [[DCMCharacterSet alloc] initWithCode:[attr value]];
			}
			
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"Rows"]]) 
				rows = [[attr value] intValue];
				
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"Columns"]]) 
				columns = [[attr value] intValue];
				
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"NumberOfFrames"]]) 
				frames = [[attr value] intValue];
				
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"SamplesPerPixel"]]) 
				samplesPerPixel = [[attr value] intValue];
				
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"BitsAllocated"]]) {
				bytesPerSample = ([[attr value] intValue] - 1)/8 + 1;
				if (bytesPerSample > 1)
					isShort = YES;
			}
			
			if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"PixelRepresentation"]]) {
				pixelRepresentationIsSigned = [[attr value] intValue] ;
	
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
	NS_HANDLER
		NSLog(@"Error reading data for dicom object");
		//exception = [NSException exceptionWithName:@"DCMReadingError" reason:@"Cannot read Dicom Object" userInfo:nil];
		*byteOffset = 0xffffffffl;
	NS_ENDHANDLER
	//NSLog(@"DCMObject  End readDataSet: %f", -[timestamp  timeIntervalSinceNow]);
	[pool release];
	//[exception raise];
	
	return *byteOffset;
}


@end
