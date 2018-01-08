/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


#import "DCMAttributeTag.h"
#import "DCM.h"

@implementation DCMAttributeTag

@synthesize group = _group, element = _element, name = _name, vr = _vr;

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
		_name = [@"Unknown" retain];
		_vr = nil;
		NSDictionary *dict = [(NSDictionary *)[DCMTagDictionary sharedTagDictionary] objectForKey:[self stringValue]];
		if (dict) {
            [_name release];
			_name = [[dict objectForKey:@"Description"] retain];
			_vr = [[dict objectForKey:@"VR"] retain];
		}
		
		if (!_vr)
			_vr = [@"UN" retain];
		/*
		if (![DCMValueRepresentation isValidVR:_vr])
			_vr = [@"UN" retain];
		*/

		
	}
	return self;
}

- (id) initWithTag:(DCMAttributeTag *)tag{
	return [self initWithGroup: tag.group element: tag.element];
	
}

- (id) initWithTagString:(NSString *)tagString{
	if (self = [super init])
	{
        NSString* _tag = [NSString stringWithString:tagString];
        _tag = [_tag stringByReplacingOccurrencesOfString:@"(" withString:@""];
        _tag = [_tag stringByReplacingOccurrencesOfString:@")" withString:@""];
        
		NSScanner *scanner = [NSScanner scannerWithString:_tag];
		if( tagString == nil || _tag == nil)
			NSLog( @"tagString == nil");
		unsigned int uGroup, uElement;
		[scanner scanHexInt:&uGroup];
		[scanner scanString:@"," intoString:nil];
		[scanner scanHexInt:&uElement];
		_group = (int)uGroup;
		_element = (int)uElement;

		NSDictionary *dict = [[DCMTagDictionary sharedTagDictionary] objectForKey:_tag];
		
		if (dict)
		{
			_name = [(NSString *)CFDictionaryGetValue((CFDictionaryRef)dict, @"Description") retain];
			_vr =	[(NSString *)CFDictionaryGetValue((CFDictionaryRef)dict, @"VR") retain];
		}
		if (!_vr)
			_vr = [@"UN" retain];
		/*
		if (![DCMValueRepresentation isValidVR:_vr])
			_vr = [@"UN" retain];
		*/
	}
	return self;
	
}
- (id) initWithName:(NSString *)name
{
	NSString *tagString = [(NSDictionary *)[DCMTagForNameDictionary sharedTagForNameDictionary] objectForKey:name];
	if( tagString == nil)
		return nil;
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

- (BOOL)isPrivate{
	if ((_group%2) == 0)
		return NO;		
	return YES;
}

- (NSString *)stringValue {
	if (!_stringValue)
		_stringValue = [[NSString alloc] initWithFormat:@"%0004X,%0004X", _group, _element];
	return _stringValue;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@\t%@\t%@", self.stringValue, _name, _vr];
}

- (NSString *)readableDescription {
    
    if( _name.length > 0)
        return _name;
    else
        return self.stringValue;
}

- (long)longValue {
	NSLog(@"long Value for %@:%ld", self.description, (long)(_group<<16) + (long)(_element&0xffff));
	return (long)(_group<<16) + (long)(_element&0xffff);
}

- (NSComparisonResult)compare:(DCMAttributeTag *)tag {
	//NSNumber *thisTag = [NSNumber numberWithLong:[self longValue]];
	//NSNumber *otherTag = [NSNumber numberWithLong:[tag longValue]];
	return [[self stringValue] compare: tag.stringValue];
}

- (BOOL)isEquaToTag:(DCMAttributeTag *)tag {
	return [[tag stringValue] isEqualToString: self.stringValue];

}

-(BOOL)isEqual:(id)object {
	return [object isKindOfClass:[DCMAttributeTag class]] && [self isEquaToTag:object];
}

@end
