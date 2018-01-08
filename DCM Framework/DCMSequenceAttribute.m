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

#import "DCMSequenceAttribute.h"
#import "DCM.h"

@implementation DCMSequenceAttribute

@synthesize sequenceItems;

+ (id)contentSequence{
	DCMSequenceAttribute *sequence = [DCMSequenceAttribute sequenceAttributeWithName:@"ContentSequence"];
	return sequence;
}

+ (id)conceptNameCodeSequenceWithCodeValue:(NSString *)codeValue 
		codeSchemeDesignator:(NSString *)csd  
		codeMeaning:(NSString *)cm{
	
	DCMSequenceAttribute *sequence = [DCMSequenceAttribute sequenceAttributeWithName:@"ConceptNameCodeSequence"];
	DCMObject *dcmObject = [DCMObject dcmObject];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codeValue] forName:@"CodeValue"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:csd] forName:@"CodingSchemeDesignator"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:cm] forName:@"CodeMeaning"];
	[sequence addItem:dcmObject];
	
	return sequence;	
}

+ (id)sequenceAttributeWithName:(NSString *)name{
	DCMAttributeTag * tag = [DCMAttributeTag tagWithName:name];
	DCMSequenceAttribute *sequence = [[[DCMSequenceAttribute alloc] initWithAttributeTag:tag] autorelease];
	return sequence;
}

- (id)initWithAttributeTag:(DCMAttributeTag *)tag{

	if (self = [super initWithAttributeTag:(DCMAttributeTag *)tag]) 
		sequenceItems  = [[NSMutableArray array] retain];
	
	return self;
}
	
- (id)initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicitValue
			forImplicitUseOW:(BOOL)forImplicitUseOW{
	if (self = [super  initWithAttributeTag:(DCMAttributeTag *)tag]) 
		sequenceItems  = [[NSMutableArray array] retain];
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	DCMSequenceAttribute *seq = [super copyWithZone:zone];
	if( seq == nil) return nil;
	
	sequenceItems = [self.sequenceItems mutableCopy];
	
	return seq;
}

- (void)dealloc {
	//NSLog(@"Release Sequence");
	[sequenceItems release];
	[super dealloc];
}

- (void)addItem:(id)item{
	[self addItem:item offset:0];
}

- (void)addItem:(id)item offset:(long)offset{
	if(DCMDEBUG)
		NSLog(@"Add sequence Item %@ at Offset:%ld", [item description], offset);
	NSArray *objects =  [NSArray arrayWithObjects:item, [NSNumber numberWithInt:(int)offset], nil];
	NSArray *keys =		[NSArray arrayWithObjects:@"item", @"offset", nil];
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[sequenceItems addObject:dictionary];
}

- (NSArray *)sequence {
	NSMutableArray *array = [NSMutableArray array];
	for ( NSDictionary *dict in sequenceItems )
		[array addObject:[dict objectForKey:@"item"]];
	return array;
}

// use super

- (void)writeBaseToData:(DCMDataContainer *)dcmData transferSyntax:(DCMTransferSyntax *)ts
{
	[dcmData addUnsignedShort:[self group]];
	[dcmData addUnsignedShort:[self element]];
	
	if ([ts isExplicit])
	{
		[dcmData addString: _vr];
		[dcmData addUnsignedShort:0];		// reserved bytes
		[dcmData addUnsignedLong: SQLength];
	}
	else
		[dcmData  addUnsignedLong: SQLength];
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts
{
	if( [_vr isEqualToString: @"SQ"] == NO)
	{
		// we dont write UN sequences
//		[_vr release];
//		_vr = @"SQ";
//		[_vr retain];
		
		return YES;
	}
	
	// We only support PixelData at the root level
	for( NSDictionary *object in sequenceItems)
	{
		DCMObject *o = [object objectForKey:@"item"];
		
		if( [[o attributes] objectForKey: [[DCMAttributeTag tagWithName:@"PixelData"] stringValue]])
			return YES;
	}
	
	DCMDataContainer *dummyContainer = [DCMDataContainer dataContainerWithMutableData: [NSMutableData data] transferSyntax: ts];
	
	for( NSDictionary *object in sequenceItems)
	{
		[dummyContainer addUnsignedShort:(0xfffe)];
		[dummyContainer addUnsignedShort:(0xe000)];
		
		DCMObject *o = [object objectForKey:@"item"];
		
		DCMDataContainer *c = [DCMDataContainer dataContainerWithMutableData: [NSMutableData data] transferSyntax: ts];
		
		[o writeToDataContainer: c withTransferSyntax: ts AET: @"OSIRIX" asDICOM3: NO];
		
		long l = [[c dicomData] length];
		[dummyContainer addUnsignedLong:( l)];
		[dummyContainer addData: [c dicomData]];
	}
	
	SQLength = [[dummyContainer dicomData] length];
	
	[self writeBaseToData: container transferSyntax:ts];
	[container addData: [dummyContainer dicomData]];
	
	return YES;
}

// for the benefit of writeBaseToData

- (long)valueLength{
	return 0xFFFFFFFF;	
}

- (NSString *)readableDescription{
	NSString *sequenceDescription =  [super readableDescription];
    
	NSEnumerator *enumerator = [sequenceItems objectEnumerator];
	NSString *string;
	while ((string = [[(NSDictionary *)[enumerator nextObject] objectForKey:@"item"] readableDescription]))
		sequenceDescription = [NSString stringWithFormat:@"%@\n\t%@", sequenceDescription, string];
	return sequenceDescription;
}

- (NSString *)description{
	NSString *sequenceDescription =  [super description];
	//NSString *description = [super description];
	NSEnumerator *enumerator = [sequenceItems objectEnumerator];
	NSString *string;
	while ((string = [[(NSDictionary *)[enumerator nextObject] objectForKey:@"item"] description]))
		sequenceDescription = [NSString stringWithFormat:@"%@\n\t%@", sequenceDescription, string];
	return sequenceDescription;
}

- (NSXMLNode *)xmlNode{

	NSMutableArray *elements = [NSMutableArray array];
	for ( id value in sequenceItems ) {
		[elements addObject:[[value objectForKey:@"item"] xmlNode]];
	}
	NSMutableString *aName = [NSMutableString stringWithString:[[self attrTag] name]];
	[aName replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [aName length])];
	
	NSXMLNode *groupAttr = [NSXMLNode attributeWithName:@"group" stringValue:[NSString stringWithFormat:@"%04x",[[self attrTag] group]]];
	NSXMLNode *elementAttr = [NSXMLNode attributeWithName:@"element" stringValue:[NSString stringWithFormat:@"%04x",[[self attrTag] element]]];
	NSXMLNode *vrAttr = [NSXMLNode attributeWithName:@"vr" stringValue:[[self attrTag] vr]];
	NSArray *attrs = [NSArray arrayWithObjects:groupAttr,elementAttr, vrAttr, nil];
	NSXMLNode *myNode = [NSXMLNode elementWithName:aName children:elements attributes:attrs];

	return myNode;
}
		


@end
