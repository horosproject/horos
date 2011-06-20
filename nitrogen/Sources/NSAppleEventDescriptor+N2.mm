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

#import "NSAppleEventDescriptor+N2.h"


@implementation NSAppleEventDescriptor (Scripting)

+(NSAppleEventDescriptor*)descriptorWithObject:(id)object {
	if (!object || [object isKindOfClass:[NSNull class]])
		return [NSAppleEventDescriptor nullDescriptor];
	else
	if ([object isKindOfClass:[NSDictionary class]]) {
		NSDictionary* dictionary = (NSDictionary*)object;
		NSArray* ka = [dictionary allKeys];
		NSArray* kv = [dictionary allValues];
		
		NSMutableArray* list = [NSMutableArray arrayWithCapacity:ka.count+kv.count];
		for (NSUInteger i = 0; i < dictionary.count; ++i) {
			[list addObject:[ka objectAtIndex:i]];
			[list addObject:[kv objectAtIndex:i]];
		}
		
		NSAppleEventDescriptor* recoAed = [NSAppleEventDescriptor recordDescriptor];
		[recoAed setDescriptor:[self descriptorWithObject:list] forKeyword:'usrf'];
		return recoAed;
	} else
	if ([object isKindOfClass:[NSArray class]]) {
		NSArray* array = (NSArray*)object;
		NSAppleEventDescriptor* listAed = [NSAppleEventDescriptor listDescriptor];
		for (NSUInteger i = 0; i < array.count; ++i)
			[listAed insertDescriptor:[self descriptorWithObject:[array objectAtIndex:i]] atIndex:i+1];
		return listAed;
	} else 
	if ([object isKindOfClass:[NSString class]])
		return [NSAppleEventDescriptor descriptorWithString:object];
	else 
	if ([object isKindOfClass:[NSNumber class]]) {
		NSNumber* number = (NSNumber*)object;
		switch (number.objCType[0]) {
			case 'c': {
				char temp = [number charValue]; return [NSAppleEventDescriptor descriptorWithDescriptorType:'cha ' bytes:&temp length:sizeof(temp)]; // 'cha ': char
			} break;
			case 'i': {
				return [NSAppleEventDescriptor descriptorWithInt32:[number intValue]]; // 'long': integer
			} break;
			case 's': {
				short temp = [number shortValue]; return [NSAppleEventDescriptor descriptorWithDescriptorType:'shor' bytes:&temp length:sizeof(temp)]; // 'shor': small integer
			} break;
			case 'l':
			case 'q': {
				long temp = [number longValue]; return [NSAppleEventDescriptor descriptorWithDescriptorType:'comp' bytes:&temp length:sizeof(temp)]; // 'comp': double integer
			} break;
			  // 'C'
			case 'I': {
				unsigned int temp = [number unsignedIntValue]; return [NSAppleEventDescriptor descriptorWithDescriptorType:'magn' bytes:&temp length:sizeof(temp)]; // 'magn': unsigned integer
			} break;
			  // 'S'
			  // 'L'
			  // 'Q'
			case 'f': {
				float temp = [number floatValue]; return [NSAppleEventDescriptor descriptorWithDescriptorType:'sing' bytes:&temp length:sizeof(temp)]; // 'sing': small real
			} break;
			case 'd': {
				double temp = [number doubleValue]; return [NSAppleEventDescriptor descriptorWithDescriptorType:'doub' bytes:&temp length:sizeof(temp)]; // 'doub': real
			} break;
			case 'B': {
				return [NSAppleEventDescriptor descriptorWithBoolean:[number boolValue]]; // 'bool': boolean
			} break;
		}

		[NSException raise:NSGenericException format:@"unknown NSAppleEventDescriptor type for NSNumber with ObjC type %s", number.objCType];
	}
	
	@try {
		return [NSAppleEventDescriptor descriptorWithDescriptorType:'ObjC' data:[NSKeyedArchiver archivedDataWithRootObject:object]];
	} @catch (NSException* e) {
		NSLog(@"tried to use archivedDataWithRootObject but failed: %@", e.description);
	}
	
	[NSException raise:NSGenericException format:@"unknown NSAppleEventDescriptor type for class %@", [object className]];
	
	return NULL;
}

+(id)objectWithDescriptor:(NSAppleEventDescriptor*)descriptor {
	switch (descriptor.descriptorType) {
		case 'null':
		case 'msng':
			return [NSNull null];
		case 'reco': {
			NSAssert(descriptor.numberOfItems == 1, @"'reco' should contain only one subrecord");
			descriptor = [descriptor descriptorAtIndex:1];
			NSAssert(descriptor.descriptorType == 'list', @"'reco' subrecord should be of type 'list'");
			return [self dictionaryWithArray:[descriptor object]];
		} break;
		case 'list': {
			NSMutableArray* list = [NSMutableArray arrayWithCapacity:descriptor.numberOfItems];
			for (NSInteger i = 0; i < descriptor.numberOfItems; ++i)
				[list addObject:[[descriptor descriptorAtIndex:i+1] object]];
			return [[list copy] autorelease];
		} break;
		case 'utxt':
			return [descriptor stringValue];
		case 'cha ': {
			char temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithChar:temp];
		} break;
		case 'long': {
			int temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithInt:temp];
		} break;
		case 'shor': {
			short temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithShort:temp];
		} break;
		case 'comp': {
			long temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithLong:temp];
		} break;
		case 'magn': {
			unsigned int temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithUnsignedInt:temp];
		} break;
		case 'sing': {
			float temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithFloat:temp];
		} break;
		case 'doub': {
			double temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithDouble:temp];
		} break;
		case 'bool': {
			bool temp; [descriptor.data getBytes:&temp length:sizeof(temp)]; return [NSNumber numberWithBool:temp];
		} break;
			// 'exte': extended float
			// 'ldbl': 128 bits
		case 'ObjC': {
			return [NSKeyedUnarchiver unarchiveObjectWithData:descriptor.data];
		} break;
	}
	
	DescType type = descriptor.descriptorType;
	char* c = (char*)&type;
	[NSException raise:NSGenericException format:@"unhandled NSAppleEventDescriptor type '%c%c%c%c'", c[3],c[2],c[1],c[0]];
	
	return NULL;
}

-(id)object {
	return [NSAppleEventDescriptor objectWithDescriptor:self];
}

+(NSDictionary*)dictionaryWithArray:(NSArray*)list {
	NSAssert(list.count%2 == 0, @"'reco' subrecord 'list' should contain an even number of items");
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:list.count/2];
	for (NSUInteger i = 0; i < list.count/2; ++i)
		[dictionary setObject:[list objectAtIndex:i*2+1] forKey:[list objectAtIndex:i*2+0]];
	return [[dictionary copy] autorelease];
}

@end


@implementation NSObject (Scripting)

-(NSAppleEventDescriptor*)appleEventDescriptor {
	return [NSAppleEventDescriptor descriptorWithObject:self];
}

@end


@interface NSDictionary (Scripting)
@end 
@implementation NSDictionary (Scripting)

+(id)scriptingRecordWithDescriptor:(NSAppleEventDescriptor*)descriptor {
	return [descriptor object];
}

-(id)scriptingRecordDescriptor {
	NSLog(@"scriptingRecordDescriptor %@", self.description);
	NSObject* out = [self appleEventDescriptor];
	NSLog(@"outs %@", out.description);
	return out;
}

@end
