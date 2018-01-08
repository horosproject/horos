/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


#import "DCMLimitedObject.h"
#import "DCM.h"


@implementation DCMLimitedObject
+ (id)objectWithData:(NSData *)data lastGroup:(unsigned short)lastGroup{
	return [[[DCMLimitedObject alloc] initWithData:data lastGroup:(unsigned short)lastGroup] autorelease];
}

+ (id)objectWithContentsOfFile:(NSString *)file lastGroup:(unsigned short)lastGroup{
	return [[[DCMLimitedObject alloc] initWithContentsOfFile:file lastGroup:(unsigned short)lastGroup] autorelease];
}

+ (id)objectWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup{
	return [[[DCMLimitedObject alloc] initWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup] autorelease];
}


- (id)initWithData:(NSData *)data lastGroup:(unsigned short)lastGroup{
	DCMDataContainer *container = [DCMDataContainer dataContainerWithData:data];
	int offset = 0;
	return [self  initWithDataContainer:container lengthToRead:[container length] - [container offset] byteOffset:&offset characterSet:nil lastGroup:(unsigned short)lastGroup];

}

- (id)initWithContentsOfFile:(NSString *)file lastGroup:(unsigned short)lastGroup{
	NSData *aData = [NSData dataWithContentsOfMappedFile:file];
	return [self initWithData:aData lastGroup:(unsigned short)lastGroup] ;
}

- (id)initWithContentsOfURL:(NSURL *)aURL lastGroup:(unsigned short)lastGroup{
	NSData *aData = [NSData dataWithContentsOfURL:aURL];
	return [self initWithData:aData lastGroup:(unsigned short)lastGroup] ;
}

- (id)initWithDataContainer:(DCMDataContainer *)data lengthToRead:(int)lengthToRead byteOffset:(int*)byteOffset characterSet:(DCMCharacterSet *)characterSet lastGroup:(unsigned short)lastGroup{

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
		
		if (*byteOffset == 0xFFFFFFFF)
        {
			[self autorelease];
            self = nil;
		}
		if (DCMDEBUG)
			NSLog(@"end readDataSet byteOffset: %d", *byteOffset);
		[dicomData release];
			//NSLog(@"DCMObject end init: %f", -[timestamp  timeIntervalSinceNow]); 
	}

	return self;
}

- (int)readDataSet:(DCMDataContainer *)dicomData toGroup:(unsigned short)lastGroup byteOffset:(int *)byteOffset{

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL readingMetaHeader = NO;
	int endMetaHeaderPosition = 0;					

	int endByteOffset =  0xFFFFFFFF;
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
	@try
    {
        while ((group < lastGroup || group == 0xFFFE ))
        {
            NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
            
            @try
            {
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
                //if (DCMDEBUG)
                //		NSLog(@"byteoffset before VR %d",*byteOffset);
                if (DCMDEBUG)
                    NSLog(@"Tag: %@  group: 0x%4000x  word 0x%4000x", [tag description], group, element);
                if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"ItemDelimitationItem"]]) {
                    // Read and discard value length
                    [dicomData nextUnsignedLong];
                    *byteOffset+=4;
                    if (DCMDEBUG)
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
                    if (DCMDEBUG)
                        NSLog(@"Ignoring bad Item at %d  %@ VL=<0x%x", *byteOffset, [tag stringValue], (unsigned int) vl);
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
                        if (DCMDEBUG)
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
                        if (DCMDEBUG)
                            NSLog(@"Implicit VR %@", vr);	


                    }
                    //if (DCMDEBUG)
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
                    if (DCMDEBUG)
                        NSLog(@"Tag: %@, length: %ld", [tag description], vl);
                    //if (DCMDEBUG)
                    //	NSLog(@"byteoffset after length %d, VR:%@  length:%d",*byteOffset,  vr, vl);
                        
                
                    // generate Attributes
                    DCMAttribute *attr = nil;
                    //sequence attribute
                    
                    if ([DCMValueRepresentation isSequenceVR:vr] || ([DCMValueRepresentation  isUnknownVR:vr] && vl == 0xFFFFFFFF)) {
                        //NSLog(@"DCMObject sequence: %f", -[timestamp  timeIntervalSinceNow]);
                            attr = (DCMAttribute *) [[[DCMSequenceAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
                            *byteOffset = [self readNewSequenceAttribute:attr dicomData:dicomData byteOffset:byteOffset lengthToRead:(int)vl specificCharacterSet:specificCharacterSet];

                    }
                    else if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"PixelData"]])
                    {
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
                    else if (vl != 0xFFFFFFFF && vl != 0)
                    {
                        //[self newAttr];
                        attr = [[[DCMAttribute alloc] initWithAttributeTag:tag 
                                vr:vr 
                                length: vl 
                                data:dicomData 
                                specificCharacterSet:specificCharacterSet
                                isExplicit:[dicomData isExplicitTS]
                                forImplicitUseOW:forImplicitUseOW] autorelease];
                        *byteOffset += vl;
                        if (DCMDEBUG)
                            NSLog(@"byteOffset %d attr %@", *byteOffset, [attr description]);
                    }
                    /*
                    else if (vl == 0xFFFFFFFF && [[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"PixelData"]] && [[dicomData transferSyntaxInUse] isEncapsulated]) {
                    }
                    */
                    if (DCMDEBUG)
                        NSLog(@"Attr: %@", [attr description]);
                    if (attr)
                        [attributes setObject:attr forKey:[tag stringValue]];
                    if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"MetaElementGroupLength"]])  {
                        readingMetaHeader = YES;
                        if (DCMDEBUG)
                            NSLog(@"metaheader length : %d", [[attr value] intValue]);
                        endMetaHeaderPosition = [[attr value] intValue] + *byteOffset;
                        [dicomData startReadingMetaHeader];
                    }
                    if ([[tag stringValue] isEqualToString:[sharedTagForNameDictionary objectForKey:@"TransferSyntaxUID"]]) {
                            
                        DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS:[attr value]] autorelease];
                        [transferSyntax release];
                        transferSyntax = [ts retain];
                        [dicomData setTransferSyntaxForDataset:ts];
                        //if (DCMDEBUG)
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
                        if (DCMDEBUG)
                            NSLog(@"End reading Metaheader. Metaheader position: %d, byteOffset: %d", endMetaHeaderPosition, *byteOffset);
                        readingMetaHeader = NO;
                        [dicomData startReadingDataSet];
                    }
                    */	
                        

                }
                    
                    
            }
            @catch (NSException *e) {
                NSLog( @"%@", e);
            }
            @finally {
                [subPool release];
            }
        }
        [transferSyntax release];
        transferSyntax = [[dicomData transferSyntaxForDataset] retain];
    }
    @catch( NSException *localException) {
		NSLog(@"Error reading data for dicom object");
		//exception = [NSException exceptionWithName:@"DCMReadingError" reason:@"Cannot read Dicom Object" userInfo:nil];
		*byteOffset = 0xFFFFFFFF;
	}
	//NSLog(@"DCMObject  End readDataSet: %f", -[timestamp  timeIntervalSinceNow]);
	[pool release];
	//[exception raise];
	
	return *byteOffset;
}


@end
