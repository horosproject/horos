#import "DCMMutableData.h"
#import "DCM.h"



@implementation DCMMutableData

+ (id) data {
	return [[[DCMMutableData alloc] init] autorelease];
}

+ (id)dataWithBytes:(const void *)bytes length:(unsigned)length{
	return [[[DCMMutableData alloc] initWithBytes:bytes length:length] autorelease];
}

+ (id)dataWithBytesNoCopy:(void *)bytes length:(unsigned)length{
	return [[[DCMMutableData alloc] initWithBytesNoCopy:bytes length:length] autorelease];
}

+ (id)dataWithBytesNoCopy:(void *)bytes length:(unsigned)length freeWhenDone:(BOOL)freeWhenDone{
	return [[[DCMMutableData alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:freeWhenDone] autorelease];
}

+ (id)dataWithContentsOfFile:(NSString *)path{
	return [[[DCMMutableData alloc] initWithContentsOfFile:path] autorelease];
}

+ (id)dataWithContentsOfMappedFile:(NSString *)path{
	return [[[DCMMutableData alloc] initWithContentsOfMappedFile:path] autorelease];
}

+ (id)dataWithContentsOfURL:(NSURL *)aURL{
	return [[[DCMMutableData alloc] initWithContentsOfURL:aURL] autorelease];
}

+ (id)dataWithData:(NSData *)aData{
	return [[[DCMMutableData alloc] initWithData:aData] autorelease];
}





- (id) initWithData:(NSData *)data{
	if (self = [super initWithData:data]) {
		if (![self determineTransferSyntax])
			return nil;
	}
	return self;
}


- (id)initWithContentsOfFile:(NSString *)path{
	if (self = [super initWithContentsOfFile:path]) {
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;

}
- (id)initWithContentsOfURL:(NSURL *)aURL{
	if (self = [super initWithContentsOfURL:aURL]) {
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

- (id)initWithBytes:(const void *)bytes length:(unsigned)length{
	if (self = [super initWithBytes:bytes length:length]) {
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

- (id)initWithBytesNoCopy:(void *)bytes length:(unsigned)length{
	if (self = [super initWithBytesNoCopy:bytes length:length]) {
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

 - (id)initWithBytesNoCopy:(void *)bytes length:(unsigned)length freeWhenDone:(BOOL)flag{
	if (self = [super initWithBytesNoCopy:bytes length:length freeWhenDone:flag]) {
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

- (id)init{
	if (self = [super init])
		[self initValues];
	return self;
}

- (void)initValues{
	isLittleEndian = YES;
	isExplicitTS = NO;
	offset = 0;
	position = 0;
	stringEncoding  = NSUTF8StringEncoding;
	if ([self length] >= 132) {
		unsigned char buffer[4];
		NSRange range = {128,4};
		[self getBytes:buffer range:range];
		if (buffer[0] == 'D' && buffer[1] == 'I' && buffer[2] == 'C' && buffer[3] == 'D') {
			offset = 132;
			position = offset;
		}
	}
}
	


- (BOOL)isLittleEndian{
	return [transferSyntaxInUse isLittleEndian];
}

- (BOOL)isExplicitTS{
	return [transferSyntaxInUse isExplicit];
}

- (BOOL)isEncapsulated{
	return [transferSyntaxInUse isEncapsulated];
}

- (BOOL)dataRemaining{
	if (position < [self length])
		return YES;
	return NO;
}

- (NSStringEncoding) stringEncoding{
	return stringEncoding;
}

- (void)setLittleEndian:(BOOL)value{
	isLittleEndian = value;
}

- (void)setExplicitTS:(BOOL)value{
	isExplicitTS = value;
}

- (void)setStringEncoding:(NSStringEncoding)encoding{
	stringEncoding = encoding;
}


//Retrieving data
- (unsigned char)nextUnsignedChar{
	NSException *exception = [self testForLength:1];
	if (!exception) {
		NSRange range = {position++, 1};
		unsigned char *buffer = malloc(sizeof(unsigned char));
		[self getBytes:buffer range:range];
		unsigned char value = buffer[0];
		free(buffer);
		return value;
	}
	else 
		[exception raise];
	return nil;
	
}

- (unsigned short)nextUnsignedShort{
	NSException *exception = [self testForLength:2];
	if (!exception) {
		int size = 2;
		union {
			unsigned short us;
			short ss;
			unsigned char buffer[size];
		} u;
		NSRange range = {position, size};
		[self getBytes:u.buffer range:range];
		position += size;
		return (isLittleEndian) ? NSSwapLittleShortToHost(u.us) : (u.us) ;
	}
	else 
		[exception raise];
	return nil;

}


- (short)nextSignedShort{
	NSException *exception = [self testForLength:2];
	if (!exception) {
		int size = 2;
		union {
			unsigned short us;
			short ss;
			unsigned char buffer[size];
		} u;
		NSRange range = {position, size};
		[self getBytes:u.buffer range:range];
		position += size;
		if  (isLittleEndian)  
			NSSwapLittleShortToHost(u.us);
		return u.ss;
	}
	else 
		[exception raise];
	return nil;
}

- (unsigned long)nextUnsignedLong{
	NSException *exception = [self testForLength:4];
	if (!exception) {
		int size = 4;
		union {
			unsigned long ul;
			long sl;
			unsigned char buffer[size];
		} u;
		NSRange range = {position, size};
		[self getBytes:u.buffer range:range];
		position += size;
		return (isLittleEndian) ? NSSwapLittleLongToHost(u.ul) : (u.ul) ;
	}
	else 
		[exception raise];
	return nil;
}

- (long)nextSignedLong{
	NSException *exception = [self testForLength:4];
	if (!exception) {
		int size = 4;
		union {
			unsigned long ul;
			long sl;
			unsigned char buffer[size];
		} u;
		NSRange range = {position, size};
		[self getBytes:u.buffer range:range];
		position += size;
		if (isLittleEndian)
			NSSwapLittleLongToHost(u.ul);
		return u.sl;
	}
	else 
		[exception raise];
	return nil;
}

- (unsigned long long)nextUnsignedLongLong{
	NSException *exception = [self testForLength:8];
	if (!exception) {
		int size = 8;
		union {
			unsigned long ull;
			long sll;
			unsigned char buffer[size];
		} u;
		NSRange range = {position, size};
		[self getBytes:u.buffer range:range];
		position += size;
		return (isLittleEndian) ? NSSwapLittleLongLongToHost(u.ull) : (u.ull) ;
	}
	else 
		[exception raise];
	return nil;
}

- (long long)nextSignedLongLong{
	NSException *exception = [self testForLength:8];
	if (!exception) {
		int size = 8;
		union {
			unsigned long long ull;
			long long sll;
			unsigned char buffer[size];
		} u;
		NSRange range = {position, size};
		[self getBytes:u.buffer range:range];
		position += size;
		if (isLittleEndian)
			NSSwapLittleLongLongToHost(u.ull);
		return u.sll;
	}
	else 
		[exception raise];
	return nil;
}

- (float)nextFloat{
	NSException *exception = [self testForLength:4];
	if (!exception) {
		int size = 4;
		union {
			float f;
			unsigned long l;
			unsigned char buffer[size];
		} u;
		u.l = [self nextUnsignedLong];
		return u.f;
	}
	else 
		[exception raise];
	return nil;
}

- (double)nextDouble{
	NSException *exception = [self testForLength:8];
	if (!exception) {
		int size = 8;
		union {
			unsigned long long l;
			double d;
			unsigned char buffer[size];
		} u;
		u.l = [self nextUnsignedLongLong];
		return u.d;
	}
	else 
		[exception raise];
	return nil;
}


- (NSString *)nextStringWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		if (stringEncoding == nil)
			stringEncoding = NSUTF8StringEncoding;
		NSString *string;
		NSRange range = {position, length};
		NSData *data = [self subdataWithRange:range];
		string = [[[NSString alloc] initWithData:data encoding:stringEncoding] autorelease];
		position += length;
		return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	else 
		[exception raise];
	return nil;
}

- (NSString *)nextStringWithLength:(int)length encoding:(NSStringEncoding)encoding{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSString *string;
		NSRange range = {position, length};
		NSData *data = [self subdataWithRange:range];
		string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
		position += length;
		return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	else 
		[exception raise];
	return nil;

}

- (NSCalendarDate *)nextDate{	
	NSException *exception = [self testForLength:8];
	if (!exception) {
		NSString *format = @"%Y%m%d";
		NSString *dateString;
		NSRange range = {position, 8};
		NSData *data = [self subdataWithRange:range];
		dateString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
		position += 8;
		return date;
	}
	else 
		[exception raise];
	return nil;
}

- (NSCalendarDate *)nextTimeWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSString *format;
		if (length == 6)
			format = @"%H%M%S";
		else
			format = @"%H%M%S.%F";
		
		NSString *dateString;
		NSRange range = {position, length};
		NSData *data = [self subdataWithRange:range];
		dateString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
		position += length;
		return date;
	}
	else 
		[exception raise];
	return nil;
}

- (NSCalendarDate *)nextDateTimeWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSString *format = @"%Y%m%d%H%M%S.F&z";
		//YYYYMMDDHHMMSS.FFFFFF&ZZZZ 
		NSString *dateString;
		NSRange range = {position, length};
		NSData *data = [self subdataWithRange:range];
		dateString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
		position += length;
		return date;
	}
	else 
		[exception raise];
	return nil;
}

- (NSData *)nextDataWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSRange range = {position, length};
		NSData *data = [self subdataWithRange:range];
		position += length;
		return data;
	}
	else 
		[exception raise];
	return nil;
}
//Appending Data
- (void)addUnsignedChar:(unsigned char)uChar{
	unsigned char *buffer;
	buffer = &uChar;
	[self appendBytes:buffer length:1];
}

- (void)addSignedChar:(signed char)sChar{
	char *buffer;
	buffer = &sChar;
	[self appendBytes:buffer length:1];

}

- (void)addUnsignedShort:(unsigned short)uShort{
	int size = 2;
	union {
			unsigned short us;
			short ss;
			unsigned char buffer[size];
	} u;
	if (isLittleEndian) 
		u.us = NSSwapHostShortToLittle(uShort);
	else
		u.us = uShort;

	[self appendBytes:u.buffer length:size];
}

- (void)addSignedShort:(signed short)sShort{
	int size = 2;
	union {
		unsigned short us;
		short ss;
		unsigned char buffer[size];
	} u;
	u.ss = sShort;
	if (isLittleEndian) 
		u.us = NSSwapHostShortToLittle(u.us);

	[self appendBytes:u.buffer length:size];
}

- (void)addUnsignedLong:(unsigned long)uLong{
	int size = 4;
	union {
		unsigned long ul;
		unsigned char buffer[size];
	} u;
	u.ul = uLong;
	if (isLittleEndian) 
		u.ul = NSSwapHostLongToLittle(u.ul);

	[self appendBytes:u.buffer length:size];
}

- (void)addSignedLong:(signed long)sLong{
	int size = 4;
	union {
		unsigned long ul;
		long sl;
		unsigned char buffer[size];
	} u;
	u.sl = sLong;
	if (isLittleEndian) 
		u.ul = NSSwapHostLongToLittle(u.ul);

	[self appendBytes:u.buffer length:size];
}

- (void)addUnsignedLongLong:(unsigned long long)uLongLong{
	int size = 8;
	union {
		unsigned long ull;
		long sll;
		unsigned char buffer[size];
	} u;
	u.ull = uLongLong;
	if (isLittleEndian) 
		u.ull = NSSwapHostLongToLittle(u.ull);

	[self appendBytes:u.buffer length:size];
}

- (void)addSignedLongLong:(signed long long)sLongLong{
	int size = 8;
	union {
		unsigned long ull;
		long sll;
		unsigned char buffer[size];
	} u;
	u.sll = sLongLong;
	if (isLittleEndian) 
		u.ull = NSSwapHostLongToLittle(u.ull);

	[self appendBytes:u.buffer length:size];

}

- (void)addFloat:(float)f{
	int size = 4;
	union {
		float f;
		unsigned long l;
		unsigned char buffer[size];
	} u;
	u.f = f;
	if (isLittleEndian) 
		u.l = NSSwapHostLongToLittle(u.l);

	[self appendBytes:u.buffer length:size];
}


- (void)addDouble:(double)d{
	int size = 8;
	union {
		double d;
		unsigned long long l;
		unsigned char buffer[size];
	} u;
	u.d = d;
	if (isLittleEndian) 
		u.l = NSSwapHostLongLongToLittle(u.l);

	[self appendBytes:u.buffer length:size];
}

- (void)addString:(NSString *)string{
	NSString *paddedString;
	int length = [string length];
	if (length%2 == 0)
		paddedString = string;
	else
		paddedString = [string stringByPaddingToLength:length+1 withString:@" " startingAtIndex:length];
	NSData *data = [paddedString dataUsingEncoding:stringEncoding];
	[self appendData:data];
}
- (void)addString:(NSString *)string withEncoding:(NSStringEncoding)encoding{
	NSString *paddedString;
	int length = [string length];
	if (length%2 == 0)
		paddedString = string;
	else
		paddedString = [string stringByPaddingToLength:length+1 withString:@" " startingAtIndex:length];
	NSData *data = [paddedString dataUsingEncoding:encoding];
	[self appendData:data];
}

- (void)addDate:(NSCalendarDate *)date{
	NSString *format = @"%Y%m%d";
	NSString *string = [date descriptionWithCalendarFormat:format];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[self appendData:data];	
}
- (void)addTime:(NSCalendarDate *)time{
	NSString *format = @"%H%M%S";
	NSString *string = [time descriptionWithCalendarFormat:format];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[self appendData:data];	
}
- (void)addDateTime:(NSCalendarDate *)dateTime{
	NSString *format = @"%Y%m%d%H%M%S.F&z";
	NSString *string = [dateTime descriptionWithCalendarFormat:format];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[self appendData:data];	
}

- (DCMTransferSyntax *) transferSyntaxToReadDataSet{
	return transferSyntaxToReadDataSet;
}
- (DCMTransferSyntax *)  transferSyntaxToReadMetaHeader{
	return transferSyntaxToReadMetaHeader;
}
- (DCMTransferSyntax *)   transferSyntaxInUse{
	return transferSyntaxInUse;
}

- (void)setTransferSyntaxToReadDataSet:(DCMTransferSyntax *)ts{
	[transferSyntaxToReadDataSet release];
	transferSyntaxToReadDataSet = [ts retain];
	transferSyntaxInUse = transferSyntaxToReadDataSet;
}

- (void)setTransferSyntaxToReadMetaHeader:(DCMTransferSyntax *)ts{
	[transferSyntaxToReadMetaHeader release];
	transferSyntaxToReadMetaHeader = [ts retain];
	transferSyntaxInUse = transferSyntaxToReadMetaHeader;
}


- (BOOL)determineTransferSyntax{
	NSException* exception;
	position = 128;
	int group;
	int element;
	NSString *vr;
	NSString *dicm = [self nextStringWithLength:4];
	if ([dicm isEqualToString:@"DICM"]) { //DICOM.10 file
		if (DEBUG)
			NSLog(@"Dicom part 10 file");
		offset = 132;
		position = 132;
		/*
		transferSyntaxToReadMetaHeader should be  explicit VR LE
		check for valid VR, just in case
		*/
		group = [self nextUnsignedShort];
		element = [self nextUnsignedShort];
		vr = [self nextStringWithLength:2];
		
		if (DEBUG)
			NSLog(@"group: %d element: %d vr: %@" , group, element, vr);

		if ([DCMValueRepresentation isValidVR:vr]) {
			transferSyntaxToReadMetaHeader = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
			
		}
		else {
			transferSyntaxToReadMetaHeader = [[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] retain];
		}
		transferSyntaxInUse = transferSyntaxToReadMetaHeader;
		return YES;
	}
	// maybe non part 10 DICOM file.
	else {
		int vl;
		position = 0;
		offset = 0;
		group = [self nextUnsignedShort];
		element = [self nextUnsignedShort];
		vr = [self nextStringWithLength:2];
		if ([DCMValueRepresentation isValidVR:vr]) {  //have valid VR assume explicit Little Endian
			transferSyntaxToReadDataSet =  [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
			transferSyntaxInUse = transferSyntaxToReadDataSet;
			return YES;
		}
		// implicit is the default. Could still be Big Endian
		else{
			const char *vrChars = [vr UTF8String];
			char flipVR[2];
			flipVR[0] = vrChars[1];
			flipVR[1] = vrChars[0];
			NSString *newVR = [NSString stringWithCString:flipVR length:2];
			if ([DCMValueRepresentation isValidVR:newVR]) {
				transferSyntaxToReadDataSet = [[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax] retain];
				transferSyntaxInUse = transferSyntaxToReadDataSet;
				return YES;
			}
			
			else{
			//test the first tag or two to see if it is implicit or not a valid file.
				group = [self nextUnsignedShort];
				element = [self nextUnsignedShort]; 	
				if (group == 0  && element == 0) {
					//try next tag
					vl = [self nextUnsignedLong];
					position += vl;
					group = [self nextUnsignedShort];
					element = [self nextUnsignedShort];
				}
				DCMAttributeTag *tag = [[[DCMAttributeTag alloc]  initWithGroup:group element:element] autorelease];
				NSDictionary *tagValues = [[DCMTagDictionary sharedTagDictionary] objectForKey:[tag stringValue]];
				// have valid tag. Should be dicom
				if (tag)
					transferSyntaxToReadDataSet = transferSyntaxToReadMetaHeader = [[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] retain];
				transferSyntaxInUse = transferSyntaxToReadDataSet;
				return YES;
			}
		}
	}
	NSLog(@"Not a valid DICOM file");
	NS_DURING
	exception = [NSException exceptionWithName:@"DCMNotDicomError" reason:@"File is not DICOM" userInfo:nil];
	[exception raise];
	NS_HANDLER
		NSLog(@"ERROR:%@  REASON:%@", [exception name], [exception reason]);
	NS_ENDHANDLER
	return NO;			
}

- (NSException *)testForLength: (int)elementLength{
	if (position + elementLength > [self length]) {
		NSArray *keys = [NSArray arrayWithObjects:@"position", @"elementLength", @"dataLength", nil];
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:position], [NSNumber numberWithInt:elementLength], [NSNumber numberWithInt:[self length]], nil];
		NSDictionary *userInfo =  [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		return [NSException exceptionWithName:@"DCMInvalidLengthException" reason:@"Length of element exceeds length remaining in data." userInfo:userInfo];
	}
	return nil;
}


@end
