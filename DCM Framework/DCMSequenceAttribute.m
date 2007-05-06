//
//  DCMSequenceAttribute.m
//  OsiriX
//
//  Created by Lance Pysher on Fri Jun 11 2004.

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

#import "DCMSequenceAttribute.h"
#import "DCM.h"


@implementation DCMSequenceAttribute

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

- (id) initWithAttributeTag:(DCMAttributeTag *)tag{

	if (self = [super initWithAttributeTag:(DCMAttributeTag *)tag]) 
		sequenceItems  = [[NSMutableArray array] retain];

	return self;
}
	

- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
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
	[seq setSequenceItems: [[[self sequenceItems] mutableCopy] autorelease]];
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
	if(DEBUG)
		NSLog(@"Add sequence Item %@ at Offset:%d", [item description], offset);
	NSArray *objects =  [NSArray arrayWithObjects:item, [NSNumber numberWithInt:offset], nil];
	NSArray *keys =		[NSArray arrayWithObjects:@"item", @"offset", nil];
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[sequenceItems addObject:dictionary];
}

- (void)setSequenceItems:(NSMutableArray *)sequence{
	[sequenceItems release];
	sequenceItems = [sequence retain];
}

- (NSMutableArray *)sequenceItems{
	return sequenceItems;
}

- (NSArray *)sequence{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *enumerator = [sequenceItems objectEnumerator];
	NSDictionary *dict;
	while (dict = [enumerator nextObject])
		[array addObject:[dict objectForKey:@"item"]];
	return array;
}

// use super

- (void)writeBaseToData:(DCMDataContainer *)dcmData transferSyntax:(DCMTransferSyntax *)ts{
	[dcmData addUnsignedShort:[self group]];
	[dcmData addUnsignedShort:[self element]];
	if (DEBUG)
		NSLog(@"Write Sequence Base Length:%d", 0xffffffffl);
	if ([ts isExplicit]) {
		[dcmData addString:_vr];
		[dcmData  addUnsignedShort:0];		// reserved bytes
		[dcmData  addUnsignedLong:(0xffffffffl)];
	}
	else {
		[dcmData  addUnsignedLong:(0xffffffffl)];
	}
}


- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts{
	// valueLength should be 0xffffffff from constructor

	[self writeBaseToData:container transferSyntax:ts];
				
	NSEnumerator *enumerator = [sequenceItems objectEnumerator];
	NSDictionary *object;
	while (object = [enumerator nextObject]) {
		[container addUnsignedShort:(0xfffe)];		// Item
		[container addUnsignedShort:(0xe000)];
		[container addUnsignedLong:(0xffffffffl)];		// undefined length
	
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
	return 0xffffffffl;	
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
	NSXMLNode *myNode;
	NSXMLNode *groupAttr = [NSXMLNode attributeWithName:@"group" stringValue:[NSString stringWithFormat:@"%04x",[[self attrTag] group]]];
	NSXMLNode *elementAttr = [NSXMLNode attributeWithName:@"element" stringValue:[NSString stringWithFormat:@"%04x",[[self attrTag] element]]];
	NSXMLNode *vrAttr = [NSXMLNode attributeWithName:@"vr" stringValue:[[self attrTag] vr]];
	NSArray *attrs = [NSArray arrayWithObjects:groupAttr,elementAttr, vrAttr, nil];
	NSEnumerator *enumerator = [sequenceItems objectEnumerator];
	id value;
	NSMutableArray *elements = [NSMutableArray array];

	while (value = [enumerator nextObject]){
			[elements addObject:[[value objectForKey:@"item"] xmlNode]];
	}
	NSMutableString *aName = [NSMutableString stringWithString:[[self attrTag] name]];
	[aName replaceOccurrencesOfString:@"/" withString:@"_" options:nil range:NSMakeRange(0, [aName length])];
	myNode = [NSXMLNode elementWithName:aName children:elements attributes:attrs];
	return myNode;
}
		


@end
