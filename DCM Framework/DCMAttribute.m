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

	if (self = [super init])
	{
		_vr = [vr retain];
		
		characterSet = [specificCharacterSet retain];
		
		if( characterSet == nil)
			characterSet = [[DCMCharacterSet alloc] initWithCode: @"ISO_IR 100"];
		
		_tag = [tag retain];
		_valueLength = vl;
		_values =  nil;
		if (dicomData) {
			NSArray *array = [self valuesForVR:_vr length:_valueLength data:dicomData];
			_values = [[NSMutableArray alloc]  initWithArray:array];
			if (DCMDEBUG){
				NSLog( @"%@", [self description]);
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

- (void)dealloc
{
	[characterSet release];
	[_vr release];
	[_tag release];
	[_values release];
	//if (_dataPtr != nil)
	//	free(_dataPtr);
	[super dealloc];
}
		
- (int)group
{
	return _tag.group;
}

- (int)element
{
	return _tag.element;
}

- (long)valueLength
{
	const char *chars = [_vr UTF8String];
	int vr = chars[0]<<8 | chars[1];
	int length = 0;
	int vm = self.valueMultiplicity;
	NSString *string;
	switch (vr) {
		// unsigned Short
		case DCM_US:   //unsigned short
		case DCM_SS:	//signed short
			length = vm * 2;
			break;
		case DCM_DA:	//Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
			if ([_values count] && 
				[[_values objectAtIndex:0] isKindOfClass:[DCMCalendarDate class]] && 
				[[_values objectAtIndex:0] isQuery]) {
				string = [_values componentsJoinedByString:@"\\"];
				length = [string length];
			}	
			else
				length = vm * 8 + (vm - 1);  //add (vm - 1) for between values.

                break;
		case DCM_TM:
			if ([_values count] && 
				[[_values objectAtIndex:0] isKindOfClass:[DCMCalendarDate class]] && 
				[[_values objectAtIndex:0] isQuery]) {
				string = [_values componentsJoinedByString:@"\\"];
				length = [string length];
			}	
			else
			//length is 13 if we use microseconds
				length = vm * 13 + (vm - 1);
                break;
		case DCM_DT:
			if ([_values count] && 
				[[_values objectAtIndex:0] isKindOfClass:[DCMCalendarDate class]] && 
				[[_values objectAtIndex:0] isQuery]) {
				string = [_values componentsJoinedByString:@"\\"];
				length = [string length];
			}	
			else
		//Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
                // By default, we don't add the timezone = 21
				length = vm * 21 + (vm - 1);
                break;
				
		//case DCM_SQ:	//Sequence of items
		//		//shouldn't get here
        //        break;
		
		case DCM_UN:	//unknown
		case DCM_OB:	//other Byte byte string not little/big endian sensitive
		case DCM_OW:	//other word 16bit word
				length = 0;
				for ( NSData *data in _values )
					length += [data length];
				//length = [(NSData *)[_values objectAtIndex:0] length];
                break;
		case DCM_AT:	//Attribute Tag 16bit unsigned integer
		case DCM_UL:	//unsigned Long
		case DCM_SL:	//signed long
		case DCM_FL:	//floating point Single 4 bytes fixed
			length = vm * 4;
			if (length%2)
			 length++;
			break;
		case DCM_FD:	//double floating point 8 bytes fixed
			length = vm * 8;
			break;           
			
		case DCM_AE:	//Application Entity  String 16bytes max
		case DCM_AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
		case DCM_CS:	//Code String   !6 byte max
		case DCM_DS:	//Decimal String  representing floating point number 16 byte max
				  
		case DCM_IS:	//Integer String 12 bytes max
		case DCM_LO:	//Character String 64 char max
		case DCM_LT:	//Long Text 10240 char Max
		case DCM_PN:	//Person Name string
		case DCM_SH:	//short string
		case DCM_ST:	//short Text 1024 char max
		case DCM_UI:    //String for UID
		case DCM_UT:	//unlimited text
		case DCM_QQ:
					//length may be different with different Character Sets
			string = [_values componentsJoinedByString:@"\\"];
			
			if( characterSet == nil)
				characterSet = [[DCMCharacterSet alloc] initWithCode: @"ISO_IR 100"];
			
			length = [string lengthOfBytesUsingEncoding: [characterSet encoding]];
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
			if (DCMDEBUG)
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

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts
{
	if( characterSet == nil)
		characterSet = [[DCMCharacterSet alloc] initWithCode: @"ISO_IR 100"];
	
	int i;
	const char *chars = [_vr UTF8String];
	int vr = chars[0]<<8 | chars[1];
	int vm = self.valueMultiplicity;
	
	NSString *string;
	
	[self writeBaseToData:container transferSyntax:ts];
	
	if (DCMDEBUG)
		NSLog(@"Write Attr: %@", [self description]);
		
	if ([DCMValueRepresentation isAffectedBySpecificCharacterSet:_vr])
	{
		string = [_values componentsJoinedByString: @"\\"];
		
		[container addString:string withEncodings: [characterSet encodings]];
	}
	else
	{
		switch (vr)
		{
		// unsigned Short
		 case DCM_US:   //unsigned short
				for (i = 0; i< vm; i++)
					[container addUnsignedShort:[[_values objectAtIndex:i] intValue]]; 
				break;
            case DCM_SS:	//signed short
				for (i = 0; i< vm; i++)
					[container addSignedShort:[[_values objectAtIndex:i] intValue]];
                break;
			
            case DCM_DA:	//Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
				for (i = 0; i< vm; i++) {

					[container addDate:(DCMCalendarDate *)[_values objectAtIndex:i]];
					if (i < (vm - 1))
						[container addStringWithoutPadding:@"\\"];
				}
				if (self.paddedLength != self.valueLength)
					[container addStringWithoutPadding:@" "];
                break;
			
            case DCM_TM:
				for (i = 0; i< vm; i++) {
					[container addTime:(DCMCalendarDate *)[_values objectAtIndex:i]];
					if (i < (vm - 1))
						[container addStringWithoutPadding:@"\\"];
				}
				if (self.paddedLength != self.valueLength)
					[container addStringWithoutPadding:@" "];
                break;
			
			case DCM_DT:	//Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
				for (i = 0; i< vm; i++) {
					[container addDateTime:[_values objectAtIndex:i]];
					if (i < (vm - 1))
						[container addStringWithoutPadding:@"\\"];
				}
				if (self.paddedLength != self.valueLength)
					[container addStringWithoutPadding:@" "];
                break;
				
            case DCM_SQ:	//Sequence of items
				//shouldn't get here
                break;
			
			case DCM_UN:	//unknown
            case DCM_OB:	//other Byte byte string not little/big endian sensitive
            case DCM_OW:	//other word 16bit word
				for (i = 0; i< [_values count]; i++) 
					[container addData:[_values objectAtIndex:i]];
                break;  
			
			case DCM_AT:	//Attribute Tag 16bit unsigned integer
            case DCM_UL:	//unsigned Long
				for (i = 0; i< vm; i++)
					[container addUnsignedLong:[[_values objectAtIndex:i] unsignedLongValue]];
                break;
            
            case DCM_SL:	//signed long
				for (i = 0; i< vm; i++)
					[container addSignedLong:[[_values objectAtIndex:i] longValue]];
                break;
			
            case DCM_FL:	//floating point Single 4 bytes fixed
				for (i = 0; i< vm; i++)
					[container addFloat:[[_values objectAtIndex:i] floatValue]];
                break;
			
            case DCM_FD:	//double floating point 8 bytes fixed
				for (i = 0; i< vm; i++)
					[container addDouble:[[_values objectAtIndex:i] doubleValue]];
                break;
			
            case DCM_AE:	//Application Entity  String 16bytes max
            case DCM_AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
            case DCM_CS:	//Code String   !6 byte max
            case DCM_DS:	//Decimal String  representing floating point number 16 byte max
                      
            case DCM_IS:	//Integer String 12 bytes max
            case DCM_LO:	//Character String 64 char max
            case DCM_LT:	//Long Text 10240 char Max
            case DCM_PN:	//Person Name string
            case DCM_SH:	//short string
            case DCM_ST:	//short Text 1024 char max
            case DCM_UT:	//unlimited text
            case DCM_QQ:
				string =  [_values componentsJoinedByString:@"\\"];
				[container addString:string];
                break;
			
            case DCM_UI:    //String for UID
				string =  [_values componentsJoinedByString:@"\\"];
				[container addStringWithZeroPadding:string];
				break;
				
          //  default: 
			//	values = [NSArray arrayWithObject:[dicomData nextDataWithLength:length]];
          //      break;
			
			
		}
	}
	return YES;
}

- (id)value
{
	if ([_values count] > 0)
		return [_values objectAtIndex:0];
	
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
		return  [NSString stringWithFormat:@"%@\t %@\t vl:%d\t vm:%d\t %@", _tag.description, _tag.vr, (int)self.valueLength, self.valueMultiplicity, [self valuesAsString]];
	return  [NSString stringWithFormat:@"%@\t vl:%d\t vm:%d", _tag.description, (int) self.valueLength, self.valueMultiplicity];
}
	
- (NSString *)readableDescription{
	if (self.valueLength < 100)
		return  [NSString stringWithFormat:@"%@ : %@", _tag.readableDescription, [_values componentsJoinedByString:@","]];
	return @"";
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
	else if ([DCMValueRepresentation isAffectedBySpecificCharacterSet:vrString])
	{
		string = [dicomData nextStringWithLength:length encodings:[characterSet encodings]];
		values = [NSMutableArray arrayWithArray: [string componentsSeparatedByString:@"\\"]];
	}
	else  {
		if (DCMDEBUG && vr == DCM_DT)
			NSLog(@"valuesForVR: length %d", length);
		switch (vr) {
		// unsigned Short
		 case DCM_US:   //unsigned short
				count = length/2;
				values = [NSMutableArray array];
				for (i = 0; i < count; i ++) 
					[values addObject:[NSNumber numberWithInt:[dicomData nextUnsignedShort]]];
                break;
            case DCM_SS:	//signed short
				count = length/2;
				values = [NSMutableArray array];
				for (i = 0; i < count; i ++) 
					[values addObject:[NSNumber numberWithInt:[dicomData nextSignedShort]]];
                break;

            case DCM_DA:	//Date String yyyymmdd 8bytes old format was yyyy.mm.dd for 10 bytes. May need to implement old format
				values = [dicomData nextDatesWithLength:length];

                break;
            case DCM_TM:
				values = [dicomData nextTimesWithLength:length];
                break;
			case DCM_DT:	//Date Time YYYYMMDDHHMMSS.FFFFFF&ZZZZ FFFFFF= fractional Sec. ZZZZ=offset from Hr and min offset from universal time
				values = [dicomData nextDateTimesWithLength:length];
                break;
				
            case DCM_SQ:	//Sequence of items
				//shouldn't get here
				values = nil;
                break;
			case DCM_UN:	//unknown
            case DCM_OB:	//other Byte byte string not little/big endian sensitive
            case DCM_OW:	//other word 16bit word
				values = [NSMutableArray arrayWithObject:[dicomData nextDataWithLength:length]];
                break;
			case DCM_AT:	//Attribute Tag 16bit unsigned integer
            case DCM_UL:	//unsigned Long
				{
					int p = 0;
					count = length/4;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++)
					{
						[values addObject:[NSNumber numberWithUnsignedLong: [dicomData nextUnsignedLong]]];
						p += 4;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
				break;
            
            case DCM_SL:	//signed long
				{
					int p = 0;
					count = length/4;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++)
					{
						[values addObject:[NSNumber numberWithLong:[dicomData nextSignedLong]]];
						p += 4;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
                break;
            case DCM_FL:	//floating point Single 4 bytes fixed
				{
					int p = 0;
					count = length/4;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++) 
					{
						[values addObject:[NSNumber numberWithFloat:[dicomData nextFloat]]];
						p += 4;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
				break;
            case DCM_FD:	//double floating point 8 bytes fixed
				{
					int p = 0;
					count = length/8;
					values = [NSMutableArray array];
					for (i = 0; i < count; i ++)
					{
						[values addObject:[NSNumber numberWithDouble:[dicomData nextDouble]]];
						p += 8;
					}
					if( length - p > 0) [dicomData skipLength: length - p];
				}
			break;           
			
            case DCM_AE:	//Application Entity  String 16bytes max
            case DCM_AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
            case DCM_CS:	//Code String   !6 byte max
            case DCM_DS:	//Decimal String  representing floating point number 16 byte max
                      
            case DCM_IS:	//Integer String 12 bytes max
            case DCM_LO:	//Character String 64 char max
            case DCM_LT:	//Long Text 10240 char Max
            case DCM_PN:	//Person Name string
            case DCM_SH:	//short string
            case DCM_ST:	//short Text 1024 char max
            case DCM_UI:    //String for UID
            case DCM_UT:	//unlimited text
            case DCM_QQ:
				string = [dicomData nextStringWithLength:length];
				values = [NSMutableArray arrayWithArray: [string componentsSeparatedByString:@"\\"]];
                break;
            default: 
				values = [NSMutableArray arrayWithObject:[dicomData nextDataWithLength:length]];
                break;

		}
	}
	return values;
	
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
		NSString *string = nil;
		if ([value isKindOfClass:[NSString class]])
			string = value;
		else if ([value isKindOfClass:[NSNumber class]])
			string = [value stringValue];
		else if ([value isKindOfClass:[NSDate class]])
			string = [value description];
		else if ([value isKindOfClass:[NSData class]])
        {
            @try {
                
                BOOL subData = NO;
                if( [value length] >= 256)
                {
                    value = [value subdataWithRange: NSMakeRange( 0, 256)];
                    subData = YES;
                }
                
                if( [value length] <= 256 && [value length] > 0)
                {
                    BOOL containStrangeCharacter = NO;
                    unsigned char *c = (unsigned char*) [value bytes];
                    
                    for( long x = 0; x < [value length]-1; x++)
                    {
                        if( c[ x] < 32 || c[ x] > 125)
                        {
                            containStrangeCharacter = YES;
                            break;
                        }
                    }
                    
                    if( containStrangeCharacter == NO)
                        string = [[[NSString alloc] initWithBytes: [value bytes] length: [value length] encoding: NSASCIIStringEncoding] autorelease];
                    else
                    {
                        NSUInteger capacity = [value length] * 2;
                        NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
                        [stringBuffer appendString: @"0x"];
                        const unsigned char *dataBuffer = [value bytes];
                        for (long x=0; x<[value length]; x++) {
                            [stringBuffer appendFormat:@"%02X", (NSUInteger)dataBuffer[x]];
                        }
                        string = stringBuffer;
                    }
                }
                
                if( subData)
                    string = [string stringByAppendingString: @"..."];
            }
            @catch (NSException *exception) {
                string = @"Unknown";
            }
        }
        else
			string = @"Unknown";
        
        if( string.length == 0)
            string = @"";
        
		NSXMLNode *number = [NSXMLNode attributeWithName:@"number" stringValue:[NSString stringWithFormat:@"%d",i++]];		
		NSXMLNode *element = [NSXMLNode elementWithName:@"value" children:nil attributes:[NSArray arrayWithObject:number]];
		
        if( string) {
			[element setStringValue:string];
			[elements addObject:element];
		}
	}
    
	myNode = [NSXMLNode elementWithName:aName children:elements attributes:attrs];
    
	return myNode;
}

@end
