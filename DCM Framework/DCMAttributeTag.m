//
//  DCMAttributeTag.m
//  DCM Framework
//
//  Created by Lance Pysher on Thu Jun 03 2004.

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

/***************************************** Modifications *********************************************

Version 2.3

	2005 20051220	LP	Minor code optimizing replaced some NSDictionary with CF Dictionary calls. 
			Added _stringValue. Changed from convenience  method to alloc NSString
			
****************************************************************************************************/

#import "DCMAttributeTag.h"
#import "DCM.h"


@implementation DCMAttributeTag

+ (id) tagWithGroup:(int)group element:(int)element{
	return [[[DCMAttributeTag alloc] initWithGroup:group element:element] autorelease];
}

+ (id) tagWithTag:(DCMAttributeTag *)tag{
	return [[[DCMAttributeTag alloc] initWithTag:(DCMAttributeTag *)tag] autorelease];
}

+ (id) tagWithTagString:(NSString *)tagString{
	return [[[DCMAttributeTag alloc] initWithTagString:tagString] autorelease];
}

+ (id) tagWithName:(NSString *)name{
	return [[[DCMAttributeTag alloc] initWithName:name] autorelease];
}



- (id) initWithGroup:(int)group element:(int)element{
	if (self = [super init]) {
		_group = group;
		_element = element;
		_name = @"Unknown";
		_vr = nil;
		NSDictionary *dict = [(NSDictionary *)[DCMTagDictionary sharedTagDictionary] objectForKey:[self stringValue]];
		if (dict) {
			_name = [[dict objectForKey:@"Description"] retain];
			_vr = [[dict objectForKey:@"VR"] retain];
		}
		if (!_vr)
			_vr = @"UN";
		/*
		if (![DCMValueRepresentation isValidVR:_vr])
			_vr = @"UN";
		*/

		
	}
	return self;
}

- (id) initWithTag:(DCMAttributeTag *)tag{
	return [self initWithGroup:[tag group] element:[tag element]];
	
}

- (id) initWithTagString:(NSString *)tagString{
	if (self = [super init]) {
		NSDictionary *dict = [[DCMTagDictionary sharedTagDictionary] objectForKey:tagString];
		//CFDictionaryRef dict = CFDictionaryGetValue((CFDictionaryRef)[DCMTagDictionary sharedTagDictionary],tagString);
		if (dict) {
		
			_name = [(NSString *)CFDictionaryGetValue((CFDictionaryRef)dict, @"Description") retain];
			_vr =	[(NSString *)CFDictionaryGetValue((CFDictionaryRef)dict, @"VR") retain];
			NSScanner *scanner = [NSScanner scannerWithString:tagString];
			unsigned int uGroup, uElement;
			[scanner scanHexInt:&uGroup];
			[scanner scanString:@"," intoString:nil];
			[scanner scanHexInt:&uElement];
			_group = (int)uGroup;
			_element = (int)uElement;
		}
		if (!_vr)
			_vr = @"UN";
		/*
		if (![DCMValueRepresentation isValidVR:_vr])
			_vr = @"UN";
		*/
	}
	return self;
	
}
- (id) initWithName:(NSString *)name{
	NSString *tagString = [(NSDictionary *)[DCMTagForNameDictionary sharedTagForNameDictionary] objectForKey:name];
	return [self initWithTagString:tagString];
}


- (id)copyWithZone:(NSZone *)zone{
	return [[DCMAttributeTag allocWithZone:zone] initWithTag:self];
}

- (void) dealloc{
	[_name release];
	[_vr release];
	[_stringValue release];
	[super dealloc];
}
- (int)group{
	return _group;
}
- (int)element{
	return _element;
}
- (BOOL)isPrivate{
	if ((_group%2) == 0)
		return NO;		
	return YES;
}

- (NSString *)stringValue{
	if (!_stringValue)
		_stringValue = [[NSString alloc] initWithFormat:@"%0004X,%0004X", _group, _element];
	return _stringValue;
}

- (NSString *)description{
	return [NSString stringWithFormat:@"%@\t%@\t%@",[self stringValue], _name, _vr];
	//return [self stringValue];
}

- (long)longValue{
	NSLog(@"long Value for %@:%d", [self description], (long)_group<<16 + (long)_element&0xffff);
	return (long)_group<<16 + (long)_element&0xffff;
}
	
	
- (NSComparisonResult)compare:(DCMAttributeTag *)tag{
	//NSNumber *thisTag = [NSNumber numberWithLong:[self longValue]];
	//NSNumber *otherTag = [NSNumber numberWithLong:[tag longValue]];
	return [[self stringValue] compare:[tag stringValue]];
}

- (BOOL)isEquaToTag:(DCMAttributeTag *)tag{
	return [[tag stringValue] isEqualToString:[self stringValue]];

}

- (NSString *)vr{
	return _vr;
}

- (NSString *)name{
	return _name;
}


@end
