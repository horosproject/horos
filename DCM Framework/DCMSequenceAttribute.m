/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

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
	[dcmObject setAttributeValues:[NSArray arrayWithObject:codeValue] forName:@"CodeValue"];
	[dcmObject setAttributeValues:[NSArray arrayWithObject:csd] forName:@"CodingSchemeDesignator"];
	[dcmObject setAttributeValues:[NSArray arrayWithObject:cm] forName:@"CodeMeaning"];
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

- (id)copyWithZone:(NSZone *)zone {
	DCMSequenceAttribute *seq = [super copyWithZone:zone];
	seq = [[self.sequenceItems mutableCopy] autorelease];
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
		NSLog(@"Add sequence Item %@ at Offset:%d", [item description], offset);
	NSArray *objects =  [NSArray arrayWithObjects:item, [NSNumber numberWithInt:offset], nil];
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

- (void)writeBaseToData:(DCMDataContainer *)dcmData transferSyntax:(DCMTransferSyntax *)ts{
	[dcmData addUnsignedShort:[self group]];
	[dcmData addUnsignedShort:[self element]];
	if (DCMDEBUG)
		NSLog(@"Write Sequence Base Length:%d", 0xFFFFFFFF);
	if ([ts isExplicit]) {
		[dcmData addString:_vr];
		[dcmData  addUnsignedShort:0];		// reserved bytes
		[dcmData  addUnsignedLong:(0xFFFFFFFF)];
	}
	else {
		[dcmData  addUnsignedLong:(0xFFFFFFFF)];
	}
}


- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts {
	// valueLength should be 0xFFFFFFFF from constructor

	[self writeBaseToData:container transferSyntax:ts];
				
	for ( NSDictionary *object in sequenceItems ) {
		[container addUnsignedShort:(0xfffe)];		// Item
		[container addUnsignedShort:(0xe000)];
		[container addUnsignedLong:(0xFFFFFFFF)];		// undefined length
	
		[[object objectForKey:@"item"] writeToDataContainer:container withTransferSyntax:ts  asDICOM3:NO];
	
		[container addUnsignedShort:(0xfffe)];		// Item Delimiter
		[container addUnsignedShort:(0xe00d)];
		[container addUnsignedLong:(0)];			// dummy length
		
	}
	
	[container addUnsignedShort:(0xfffe)];	// Sequence Delimiter
	[container addUnsignedShort:(0xe0dd)];
	[container addUnsignedLong:(0)];		// dummy length
	
	return YES;
}

// for the benefit of writeBaseToData

- (long)valueLength{
	return 0xFFFFFFFF;	
}

- (NSString *)description{
	NSString *sequenceDescription =  [super description];;
	//NSString *description = [super description];
	NSEnumerator *enumerator = [sequenceItems objectEnumerator];
	NSString *string;
	while (string = [[(NSDictionary *)[enumerator nextObject] objectForKey:@"item"] description])
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
