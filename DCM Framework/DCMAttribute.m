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

#import "DCMAttribute.h"
#import "DCM.h"

@implementation DCMAttribute

@synthesize vr = _vr;
@synthesize values = _values;
@synthesize attrTag = _tag;
@synthesize characterSet;

+ (id)attributeWithAttribute:(DCMAttribute *)attr{
	return [[[DCMAttribute alloc] initWithAttribute:attr] autorelease];
}

+ (id)attributeWithAttributeTag:(DCMAttributeTag *)tag{
	return [[[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
}
+ (id)attributeWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr{
	return [[[DCMAttribute alloc] initWithAttributeTag:tag  vr:vr] autorelease];
}
+ (id)attributeWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr  values:(NSMutableArray *)values{
	return [[[DCMAttribute alloc] initWithAttributeTag:tag  vr:vr  values:values] autorelease];
}

+ (id)attributeinitWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicitValue
			forImplicitUseOW:(BOOL)forImplicitUseOW
			{
			
		return [[[DCMAttribute alloc] initWithAttributeTag:tag 
			vr:vr 
			length: vl 
			data:dicomData 
			specificCharacterSet:specificCharacterSet
			isExplicit:explicitValue
			forImplicitUseOW:forImplicitUseOW] autorelease];
}

- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicitValue
			forImplicitUseOW:(BOOL)forImplicitUseOW{

	if (self = [super init]) {
		_vr = [vr retain];
		characterSet = [specificCharacterSet retain];
		_tag = [tag retain];
		_valueLength = vl;
		_values =  nil;
		if (dicomData) {
			NSArray *array = [self valuesForVR:_vr length:_valueLength data:dicomData];
			_values = [[NSMutableArray alloc]  initWithArray:array];
			if (DEBUG){
				NSLog([self description]);
			}
		}
		_dataPtr = nil;
	}

	return self;
}

- (id)initWithAttributeTag:(DCMAttributeTag *)tag{
	return [self initWithAttributeTag:tag  vr:nil];

}

- (id)initWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr{
	if (self = [super init]) {
			_tag = [tag retain];
			_valueLength =0;
			_values = [[NSMutableArray array] retain];
		if (vr != nil)
			_vr = [vr retain];
		else
			_vr = [[tag vr] retain];
			
		_dataPtr = nil;

	}

	return self;
}

- (id)initWithAttributeTag:(DCMAttributeTag *)tag  vr:(NSString *)vr  values:(NSMutableArray *)values{
	if (self = [super init]) {
		_tag = [tag retain];
		_valueLength =0;
		_values = [values retain];
		if (vr != nil)
			_vr = [vr retain];
		else
			_vr = [[tag vr] retain];
		_dataPtr = nil;
	}
	
	return self;
}

- (id)initWithAttribute:(DCMAttribute *)attr{
	if (self = [super init]) {
		_tag = [[DCMAttributeTag  alloc] initWithTag:(DCMAttributeTag *)attr.attrTag];
		_values = [attr.values mutableCopy];
		_vr = [attr.vr copy];
		_dataPtr = nil;
	}
	return self;
}

- (id) initWithAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(long) vl 
			dataPtr: (unsigned char *)dataPtr{
	if (self = [super init]) {
		_tag = [tag retain];
		_valueLength = vl;
		if (vr != nil)
			_vr = [vr retain];
		else
			_vr = [tag.vr retain];
		_dataPtr = dataPtr;
	}

	return self;
}
	
- (id)copyWithZone:(NSZone *)zone{
	return [[DCMAttribute allocWithZone:zone] initWithAttribute:self];
}

- (void)dealloc {

	[characterSet release];
	[_vr release];
	[_tag release];
	[_values release];
	//if (_dataPtr != nil)
	//	free(_dataPtr);
	[super dealloc];
}
		
- (int)group{
	return _tag.group;
}

- (int)element{
	return _tag.element;
}

- (long)valueLength{
	const char *chars = [_vr UTF8String];
	int vr = chars[0]<<8 | chars[1];
	int length = 0;
	int vm = self.valueMultiplicity;
	NSString *string;
	switch (vr) {
		// unsigned Short
		case US:   //unsigned short
		case SS:	//signed short
			length = vm * 2;
			break;
		case DA:	//Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
			if ([_values count] && 
				[[_values objectAtIndex:0] isKindOfClass:[DCMCalendarDate class]] && 
				[[_values objectAtIndex:0] isQuery]) {
				string = [_values componentsJoinedByString:@"\\"];
				length = [string length];
			}	
			else
				length = vm * 8 + (vm - 1);  //add (vm - 1) for between values.

                break;
		case TM:
			if ([_values count] && 
				[[_values objectAtIndex:0] isKindOfClass:[DCMCalendarDate class]] && 
				[[_values objectAtIndex:0] isQuery]) {
				string = [_values componentsJoinedByString:@"\\"];
				length = [string length];
			}	
			else
			//length is 13 if we use microseconds other wise 10 for milliseconds
				length = vm * 13 + (vm - 1);
                break;
		case DT:	
			if ([_values count] && 
				[[_values objectAtIndex:0] isKindOfClass:[DCMCalendarDate class]] && 
				[[_values objectAtIndex:0] isQuery]) {
				string = [_values componentsJoinedByString:@"\\"];
				length = [string length];
			}	
			else
		//Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
				length = vm * 0xe + (vm - 1);
                break;
				
		//case SQ:	//Sequence of items
		//		//shouldn't get here
        //        break;
		
		case UN:	//unknown
		case OB:	//other Byte byte string not little/big endian sensitive
		case OW:	//other word 16bit word
				length = 0;
				for ( NSData *data in _values )
					length += [data length];
				//length = [(NSData *)[_values objectAtIndex:0] length];
                break;
		case AT:	//Attribute Tag 16bit unsigned integer
		case UL:	//unsigned Long            
		case SL:	//signed long
		case FL:	//floating point Single 4 bytes fixed
			length = vm * 4;
			if (length%2)
			 length++;
			break;
		case FD:	//double floating point 8 bytes fixed
			length = vm * 8;
			break;           
			
		case AE:	//Application Entity  String 16bytes max
		case AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
		case CS:	//Code String   !6 byte max
		case DS:	//Decimal String  representing floating point number 16 byte max
				  
		case IS:	//Integer String 12 bytes max
		case LO:	//Character String 64 char max
		case LT:	//Long Text 10240 char Max
		case PN:	//Person Name string
		case SH:	//short string
		case ST:	//short Text 1024 char max
		case UI:    //String for UID             
		case UT:	//unlimited text
		case QQ: 
					//length may be different with different Character Sets
			string = [_values componentsJoinedByString:@"\\"];
			length = [string lengthOfBytesUsingEncoding:[characterSet encoding]];
			 //[string length];
			break;
		default: 
			length = [(NSData *)[_values objectAtIndex:0] length];
			break;

		}
	if (length < 0)
		length = 0;
	return length;
}

- (long)paddedLength {

	long paddedLength = self.valueLength;
	if (paddedLength%2)
		paddedLength++;
	return paddedLength;
}

- (int)valueMultiplicity{
	return [_values count];
}

- (NSString *)vrStringValue{
	return _tag.stringValue;
}

- (long)paddedValueLength{
	return 0;
}

- (void)addValue:(id)value{
	[_values addObject:value];
}

- (void)writeBaseToData:(DCMDataContainer *)dcmData transferSyntax:(DCMTransferSyntax *)ts{
	
	[dcmData addUnsignedShort: self.group];  //write group
	[dcmData addUnsignedShort: self.element]; //write Element
	//write length
		if ([ts isExplicit]) {	
			//write VR is explicit
			if (DEBUG)
				NSLog(@"Write VR: %@", _vr);
			[dcmData addString:_vr];
			if ([DCMValueRepresentation isShortValueLengthVR:_vr]) {
				[dcmData  addUnsignedShort:self.paddedLength];
			}
			
			else {
				[dcmData  addUnsignedShort:0];		// reserved bytes
				[dcmData  addUnsignedLong:self.paddedLength];
			}
			
		}
		else {
			[dcmData  addUnsignedLong:self.paddedLength];
		}

}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts{
	int i;
	const char *chars = [_vr UTF8String];
	int vr = chars[0]<<8 | chars[1];

	int vm = self.valueMultiplicity;
	NSString *string;
	[self writeBaseToData:container transferSyntax:ts];
	if (DEBUG)
		NSLog(@"Write Attr: %@", [self description]);
	if ([DCMValueRepresentation isAffectedBySpecificCharacterSet:_vr]) {
		string =  [_values componentsJoinedByString:@"\\"];
		[container addString:string withEncoding:[characterSet encoding]];
	}
	else {
		switch (vr) {
		// unsigned Short
		 case US:   //unsigned short
				for (i = 0; i< vm; i++)
					[container addUnsignedShort:[[_values objectAtIndex:i] intValue]]; 
				break;
            case SS:	//signed short
				for (i = 0; i< vm; i++)
					[container addSignedShort:[[_values objectAtIndex:i] intValue]];
                break;
			
            case DA:	//Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
				for (i = 0; i< vm; i++) {

					[container addDate:(DCMCalendarDate *)[_values objectAtIndex:i]];
					if (i < (vm - 1))
						[container addStringWithoutPadding:@"\\"];
				}
				if (self.paddedLength != self.valueLength)
					[container addStringWithoutPadding:@" "];
                break;
			
            case TM:
				for (i = 0; i< vm; i++) {
					[container addTime:(DCMCalendarDate *)[_values objectAtIndex:i]];
					if (i < (vm - 1))
						[container addStringWithoutPadding:@"\\"];
				}
				if (self.paddedLength != self.valueLength)
					[container addStringWithoutPadding:@" "];
                break;
			
			case DT:	//Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
				for (i = 0; i< vm; i++) {
					[container addDateTime:[_values objectAtIndex:i]];
					if (i < (vm - 1))
						[container addStringWithoutPadding:@"\\"];
				}
				if (self.paddedLength != self.valueLength)
					[container addStringWithoutPadding:@" "];

                break;
				
            case SQ:	//Sequence of items
				//shouldn't get here
                break;
			
			case UN:	//unknown
            case OB:	//other Byte byte string not little/big endian sensitive
            case OW:	//other word 16bit word
				for (i = 0; i< [_values count]; i++) 
					[container addData:[_values objectAtIndex:i]];
                break;  
			
			case AT:	//Attribute Tag 16bit unsigned integer
            case UL:	//unsigned Long
				for (i = 0; i< vm; i++)
					[container addUnsignedLong:[[_values objectAtIndex:i] intValue]];
                break;
            
            case SL:	//signed long
				for (i = 0; i< vm; i++)
					[container addSignedLong:[[_values objectAtIndex:i] intValue]];
                break;
			
            case FL:	//floating point Single 4 bytes fixed
				for (i = 0; i< vm; i++)
					[container addFloat:[[_values objectAtIndex:i] floatValue]];
                break;
			
            case FD:	//double floating point 8 bytes fixed
				for (i = 0; i< vm; i++)
					[container addDouble:[[_values objectAtIndex:i] doubleValue]];
                break;
			
            case AE:	//Application Entity  String 16bytes max
            case AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
            case CS:	//Code String   !6 byte max
            case DS:	//Decimal String  representing floating point number 16 byte max
                      
            case IS:	//Integer String 12 bytes max
            case LO:	//Character String 64 char max
            case LT:	//Long Text 10240 char Max
            case PN:	//Person Name string
            case SH:	//short string
            case ST:	//short Text 1024 char max
            case UI:    //String for UID             
            case UT:	//unlimited text
            case QQ: 
				string =  [_values componentsJoinedByString:@"\\"];
				[container addString:string];
				
                break;
			
          //  default: 
			//	values = [NSArray arrayWithObject:[dicomData nextDataWithLength:length]];
          //      break;
			
			
		}
	}
	return YES;
}

- (id)value{
	if ([_values count] > 0)
		return [_values objectAtIndex:0];
	NSLog(@"No value attribute: %@", self.description);
	return nil;
}

- (NSString *)valueAsString{
	return nil;
}

- (NSString *)valuesAsString{
	if ([_values count] > 0)
		//return [_values componentsJoinedByString:@"\\"];
		return [_values description];
	else
		return @"";
}

- (NSString *)description{
	if (self.valueLength < 100)
		return  [NSString stringWithFormat:@"%@\t %@\t vl:%d\t vm:%d\t %@", _tag.description, _tag.vr, self.valueLength, self.valueMultiplicity, [self valuesAsString]];
	return  [NSString stringWithFormat:@"%@\t vl:%d\t vm:%d", _tag.description, self.valueLength, self.valueMultiplicity];
}
	

- (NSArray *)valuesForVR:(NSString *)vrString  length:(int)length data:(DCMDataContainer *)dicomData{
	NSMutableArray *values;
	int i = 0;
	int count = 0;
	NSString *string = nil;
	const char *chars = [vrString UTF8String];
	int vr = chars[0]<<8 | chars[1];
	if (length == 0)
		values = [NSMutableArray array];
	else if ([DCMValueRepresentation isAffectedBySpecificCharacterSet:vrString]) {
		string = [dicomData nextStringWithLength:length encoding:[characterSet encoding]];
		values = (NSMutableArray *)[string componentsSeparatedByString:@"\\"];
	}
	else  {
		if (DEBUG && vr == DT)
			NSLog(@"valuesForVR: length %d", length);
		switch (vr) {
		// unsigned Short
		 case US:   //unsigned short
				count = length/2;
				values = [NSMutableArray array];
				for (i = 0; i < count; i ++) 
					[(NSMutableArray *)values addObject:[NSNumber numberWithInt:[dicomData nextUnsignedShort]]];
                break;
            case SS:	//signed short
				count = length/2;
				values = [NSMutableArray array];
				for (i = 0; i < count; i ++) 
					[(NSMutableArray *)values addObject:[NSNumber numberWithInt:[dicomData nextSignedShort]]];
                break;

            case DA:	//Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
				values = [dicomData nextDatesWithLength:length];

                break;
            case TM:
				values = [dicomData nextTimesWithLength:length];
                break;
			case DT:	//Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
				values = [dicomData nextDateTimesWithLength:length];
                break;
				
            case SQ:	//Sequence of items
				//shouldn't get here
				values = nil;
                break;
			case UN:	//unknown
            case OB:	//other Byte byte string not little/big endian sensitive
            case OW:	//other word 16bit word
				values = [NSArray arrayWithObject:[dicomData nextDataWithLength:length]];               
                break;
			case AT:	//Attribute Tag 16bit unsigned integer
            case UL:	//unsigned Long
				{
					int p = 0;
					count = length/4;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++)
					{
						[(NSMutableArray *)values addObject:[NSNumber numberWithInt:[dicomData nextUnsignedLong]]];
						p += 4;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
				break;
            
            case SL:	//signed long
				{
					int p = 0;
					count = length/4;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++)
					{
						[(NSMutableArray *)values addObject:[NSNumber numberWithInt:[dicomData nextSignedLong]]];
						p += 4;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
                break;
            case FL:	//floating point Single 4 bytes fixed
				{
					int p = 0;
					count = length/4;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++) 
					{
						[(NSMutableArray *)values addObject:[NSNumber numberWithFloat:[dicomData nextFloat]]];
						p += 4;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
				break;
            case FD:	//double floating point 8 bytes fixed
				{
					int p = 0;
					count = length/8;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++)
					{
						[(NSMutableArray *)values addObject:[NSNumber numberWithDouble:[dicomData nextDouble]]];
						p += 8;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
			break;           
			
            case AE:	//Application Entity  String 16bytes max
            case AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
            case CS:	//Code String   !6 byte max
            case DS:	//Decimal String  representing floating point number 16 byte max
                      
            case IS:	//Integer String 12 bytes max
            case LO:	//Character String 64 char max
            case LT:	//Long Text 10240 char Max
            case PN:	//Person Name string
            case SH:	//short string
            case ST:	//short Text 1024 char max
            case UI:    //String for UID             
            case UT:	//unlimited text
            case QQ: 
				string = [dicomData nextStringWithLength:length];
				values = (NSMutableArray *)[string componentsSeparatedByString:@"\\"];
				
                break;
            default: 
				values = [NSArray arrayWithObject:[dicomData nextDataWithLength:length]];
                break;

		}
	}
	NSMutableArray *mutableValues = [NSMutableArray arrayWithArray:values];

	return mutableValues;
	
}

- (void)swapBytes:(NSMutableData *)data{
}

- (NSXMLNode *)xmlNode{
	NSXMLNode *myNode;
	NSXMLNode *groupAttr = [NSXMLNode attributeWithName:@"group" stringValue:[NSString stringWithFormat:@"%04x", self.attrTag.group]];
	NSXMLNode *elementAttr = [NSXMLNode attributeWithName:@"element" stringValue:[NSString stringWithFormat:@"%04x", self.attrTag.element]];
	NSXMLNode *tagNode = [NSXMLNode attributeWithName:@"attributeTag" stringValue: self.attrTag.stringValue];
	NSXMLNode *vrAttr = [NSXMLNode attributeWithName:@"vr" stringValue: self.attrTag.vr];
	NSArray *attrs = [NSArray arrayWithObjects:groupAttr,elementAttr, vrAttr,tagNode, nil];
	NSMutableString *aName = [NSMutableString stringWithString: self.attrTag.name];
	[aName replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [aName length])];
	NSMutableArray *elements = [NSMutableArray array];
	int i = 0;
	for ( id value in self.values ) {
		NSString *string;
		if ([value isKindOfClass:[NSString class]])
			string = value;
		else if ([value isKindOfClass:[NSNumber class]])
			string = [value stringValue];
		else if ([value isKindOfClass:[NSDate class]])
			string = [value description];
		else
			string = nil;
			
		NSXMLNode *number = [NSXMLNode attributeWithName:@"number" stringValue:[NSString stringWithFormat:@"%d",i++]];		
		NSXMLNode *element = [NSXMLNode elementWithName:@"value" children:nil attributes:[NSArray arrayWithObject:number]];
		if (string) {
			[element setStringValue:string];
			[elements addObject:element];	
		}
	}
	myNode = [NSXMLNode elementWithName:aName children:elements attributes:attrs];

	return myNode;
}

@end
