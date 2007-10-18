//
//  DCMDataContainer.m
//  DCM Framework
//
//  Created by Lance Pysher on Mon Jun 07 2004.

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

#import "DCMDataContainer.h"
#import "DCM.h"



@implementation DCMDataContainer

@synthesize offset, dicomData;

+ (id) dataContainer {
	return [[[DCMDataContainer alloc] init] autorelease];
}

+ (id)dataContainerWithBytes:(const void *)bytes length:(NSUInteger)length{
	return [[[DCMDataContainer alloc] initWithBytes:bytes length:length] autorelease];
}

+ (id)dataContainerWithBytesNoCopy:(void *)bytes length:(NSUInteger)length{
	return [[[DCMDataContainer alloc] initWithBytesNoCopy:bytes length:length] autorelease];
}

+ (id)dataContainerWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)freeWhenDone{
	return [[[DCMDataContainer alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:freeWhenDone] autorelease];
}

+ (id)dataContainerWithContentsOfFile:(NSString *)path{
	return [[[DCMDataContainer alloc] initWithContentsOfFile:path] autorelease];
}

+ (id)dataContainerWithContentsOfMappedFile:(NSString *)path{
	return [[[DCMDataContainer alloc] initWithContentsOfMappedFile:path] autorelease];
}

+ (id)dataContainerWithContentsOfURL:(NSURL *)aURL{
	return [[[DCMDataContainer alloc] initWithContentsOfURL:aURL] autorelease];
}

+ (id)dataContainerWithData:(NSData *)aData{
	return [[[DCMDataContainer alloc] initWithData:aData] autorelease];
}

+ (id)dataContainerWithData:(NSData *)aData transferSyntax:(DCMTransferSyntax *)syntax{
	//NSLog(@"Data Length: %d", [aData length]);
	return [[[DCMDataContainer alloc] initWithData:aData transferSyntax:syntax] autorelease];
}




- (id) initWithData:(NSData *)data{

	if (self = [super init]) {
		dicomData = [data retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
			return nil;

	}
	return self;

}

- (id)initWithData:(NSData *)data transferSyntax:(DCMTransferSyntax *)syntax{
	if (self = [super init]) {
		dicomData = [data retain];
		transferSyntaxForMetaheader = [syntax retain];
		transferSyntaxForDataset = [syntax retain];
		transferSyntaxInUse = [transferSyntaxForDataset retain];
		_ptr = (unsigned char *)[dicomData bytes];
	}
	return self;
}


- (id)initWithContentsOfFile:(NSString *)path{
	NSData *aData = [[[NSData alloc] initWithContentsOfFile:path] autorelease];
	return [self initWithData:aData];
}

- (id)initWithContentsOfURL:(NSURL *)aURL{
	NSData *aData = [[[NSMutableData alloc] initWithContentsOfURL:aURL] autorelease];
	return [self initWithData:aData]; 
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithContentsOfURL:aURL] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length{
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithBytes:bytes length:length] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

- (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length{
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithBytesNoCopy:bytes length:length] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

 - (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)flag{
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithBytesNoCopy:bytes length:length freeWhenDone:flag] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
			return nil;
		//[self initValues];
	}
	return self;
}

- (id)init{
	if (self = [super init])
		dicomData = [[NSMutableData data] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		transferSyntaxForMetaheader = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
		[self initValues];
	return self;
}

- (void)dealloc {
	[transferSyntaxForDataset release];
	[transferSyntaxForMetaheader release];
	[transferSyntaxInUse release];
	[dicomData release];
	[super dealloc];
}

- (void)initValues{
	isLittleEndian = YES;
	isExplicitTS = NO;
	offset = 0;
	position = 0;
	stringEncoding = NSISOLatin1StringEncoding;
	//stringEncoding  = NSUTF8StringEncoding;
	if ([dicomData length] >= 132) {
		unsigned char buffer[4];
		NSRange range = {128,4};
		[dicomData getBytes:buffer range:range];
		if (buffer[0] == 'D' && buffer[1] == 'I' && buffer[2] == 'C' && buffer[3] == 'D') {
			offset = 132;
			position = offset;
		}
	}
}
	


- (BOOL)isLittleEndian{
	if (transferSyntaxInUse);
		return [transferSyntaxInUse isLittleEndian];
	return YES;
}

- (BOOL)isExplicitTS{
	if (transferSyntaxInUse);
		return [transferSyntaxInUse isExplicit];
	return YES;
}

- (BOOL)isEncapsulated{
	if (transferSyntaxInUse);
		return [transferSyntaxInUse isEncapsulated];
	return NO;
}

- (BOOL)dataRemaining{
	if (position < [dicomData length])
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
		unsigned char *x = _ptr + position++;
		return *x;
	}
	else 
		[exception raise];
	return 0;
	
}

- (unsigned short)nextUnsignedShort{
	NSException *exception = [self testForLength:2];
	if (!exception) {
		unsigned short *x;
		x = (unsigned short *)(_ptr + position);
		position += 2;
		return ([self isLittleEndian]) ? NSSwapLittleShortToHost(*x) : NSSwapBigShortToHost(*x) ;
	}
	
	else 
		[exception raise];
	return 0;

}


- (short)nextSignedShort{
	NSException *exception = [self testForLength:2];
	if (!exception) {
		signed short *x;
		x = (signed short *)(_ptr + position);
		position += 2;
		return (signed short)(([self isLittleEndian]) ? NSSwapLittleShortToHost(*x) : NSSwapBigShortToHost(*x)) ;
	}
	else 
		[exception raise];
	return 0;
}

- (unsigned int)nextUnsignedLong{
	NSException *exception = [self testForLength:4];
	if (!exception) {
		int size = 4;
		unsigned int *x;
		x = (unsigned int *)(_ptr + position);
		position += size;
		return (unsigned int)([self isLittleEndian]) ? NSSwapLittleIntToHost(*x) : NSSwapBigIntToHost(*x) ;
	}
	else 
		[exception raise];
	return 0;
}

- (int)nextSignedLong{
	NSException *exception = [self testForLength:4];
	if (!exception) {
		int size = 4;
		signed int *x;
		x = (signed int *)(_ptr + position);
		position += size;
		return (signed int)([self isLittleEndian]) ? NSSwapLittleIntToHost(*x) : NSSwapBigIntToHost(*x) ;
	}
	else 
		[exception raise];
	return 0;
}

- (unsigned long long)nextUnsignedLongLong{
	NSException *exception = [self testForLength:8];
	if (!exception) {
		int size = 8;
		unsigned long long *x;
		x = (unsigned long long *)(_ptr + position);
		position += size;
		return (unsigned  long long)([self isLittleEndian]) ? NSSwapLittleLongLongToHost(*x) : NSSwapBigLongLongToHost(*x) ;
	}
	else 
		[exception raise];
	return 0;
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
		[dicomData getBytes:u.buffer range:range];
		position += size;
		if ([self isLittleEndian])
			NSSwapLittleLongLongToHost(u.ull);
		return u.sll;
	}
	else 
		[exception raise];
	return 0;
}

- (float)nextFloat{
	NSException *exception = [self testForLength:4];
	if (!exception) {
		//int size = 4;
		union {
			float f;
			unsigned long l;
		} u;
		u.l = [self nextUnsignedLong];
		return u.f;
	}
	else 
		[exception raise];
	return 0;
}

- (double)nextDouble{
	NSException *exception = [self testForLength:8];
	if (!exception) {
		//int size = 8;
		union {
			unsigned long long l;
			double d;
		} u;
		u.l = [self nextUnsignedLongLong];
		return u.d;
	}
	else 
		[exception raise];
	return 0;
}


- (NSString *)nextStringWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		if (stringEncoding == 0)
			stringEncoding = NSISOLatin1StringEncoding;
		NSString *string;
		string = [[[NSString alloc] initWithBytes:(_ptr + position) length:(unsigned)length encoding:stringEncoding] autorelease];
		NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
		position += length;
		return [trimmedString  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
		
	}
	else 
		[exception raise];
	return nil;
}

- (NSString *)nextStringWithLength:(int)length encoding:(NSStringEncoding)encoding{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSString *string;
		string = [[[NSString alloc] initWithBytes:(_ptr + position) length:(unsigned)length encoding:encoding] autorelease];
		NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		position += length;
		return [trimmedString stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
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
		dateString = [[[NSString alloc] initWithBytes:(_ptr + position) length:8 encoding:NSUTF8StringEncoding] autorelease];
		NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
		position += 8;
		return date;
	}
	else 
		[exception raise];
	return nil;
}

- (NSMutableArray *)nextDatesWithLength:(int)length {
	NSException *exception = [self testForLength:length];
	NSMutableArray *dates = [NSMutableArray array];
	if (!exception) {
		NSString *string = [[[NSString alloc]  initWithBytes:(_ptr + position) length:length encoding:NSUTF8StringEncoding] autorelease];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if (string && [string intValue]) {
			NSArray *dateArray = [string componentsSeparatedByString:@"\\"];
			for ( NSString *dateString in dateArray ) {
				DCMCalendarDate *dcmDate = [DCMCalendarDate dicomDate:dateString];
				if( dcmDate )
					[dates addObject:dcmDate];
				
			}
		}
		position += length;

		return dates;
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
		dateString = [[[NSString alloc] initWithBytes:(_ptr + position) length:length encoding:NSUTF8StringEncoding] autorelease];
		NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
		position += length;
		return date;
	}
	else 
		[exception raise];
	return nil;
}

- (NSMutableArray *)nextTimesWithLength:(int)length{
	if (DEBUG)
		NSLog(@"Next time with length: %d", length);
	NSException *exception = [self testForLength:length];

	NSMutableArray *times = [NSMutableArray array];
	if (!exception) {
		NSString *string = [[[NSString alloc] initWithBytes:(_ptr + position) length:length encoding:NSUTF8StringEncoding] autorelease];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if (string && [string intValue]) {
			NSArray *dateArray = [string componentsSeparatedByString:@"\\"];
			for ( NSString *dateString in dateArray ) {
				DCMCalendarDate *dcmDate = [DCMCalendarDate dicomTime:dateString];
				if(dcmDate)
					[times addObject:dcmDate];			
			}
		}
		position += length;

		return times;
			
	}
	else 
		[exception raise];
	return nil;

}

- (NSCalendarDate *)nextDateTimeWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSString *format;
		if (length == 14)
			format = @"%Y%m%d%H%M%S";
		else if (length == 18)
			format = @"%Y%m%d%H%M%S.%F";
		else
			format = @"%Y%m%d%H%M%S.%F%z";
		//YYYYMMDDHHMMSS.FFFFFF&ZZZZ 
		NSString *dateString;

		dateString = [[[NSString alloc] initWithBytes:(_ptr + position) length:length encoding:NSUTF8StringEncoding] autorelease];

		NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
		position += length;

		return date;
	}
	else 
		[exception raise];
	return nil;
}

- (NSMutableArray *)nextDateTimesWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	//NSString *format;
	NSRange range = {position, length};
	NSMutableArray *times = [NSMutableArray array];
	NSEnumerator *enumerator;
	if (!exception) {
		NSString *string = [[[NSString alloc] initWithBytes:(_ptr + position) length:length encoding:NSUTF8StringEncoding] autorelease];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
		string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		NSArray *dateArray = [string componentsSeparatedByString:@"\\"];
		for ( NSString *dateString in dateArray ) {
			//NSCalendarDate *date = [[[NSCalendarDate alloc] initWithString:dateString  calendarFormat:format] autorelease];
			DCMCalendarDate *dcmDate = [DCMCalendarDate dicomDateTime:dateString];
			if(dcmDate)
				[times addObject:dcmDate];
			
		}
		position += length;
		return times;
	}
		
	else 
		[exception raise];
	return nil;


}

- (NSMutableData *)nextDataWithLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		NSRange range = {position, length};
		NSData *data = [dicomData subdataWithRange:range];
		NSMutableData *aData = [[[NSMutableData alloc] initWithData:data] autorelease];
		position += length;
		return aData;
	}
	else 
		[exception raise];
	return nil;
}

- (BOOL)skipLength:(int)length{
	NSException *exception = [self testForLength:length];
	if (!exception) {
		position += length;
		return YES;
	}
	else 
		[exception raise];
	return NO;
}

//Appending Data
- (void)addUnsignedChar:(unsigned char)uChar{
	unsigned char *buffer;
	buffer = &uChar;
	[dicomData appendBytes:buffer length:1];
}

- (void)addSignedChar:(signed char)sChar{
	char *buffer;
	buffer = (char *)&sChar;
	[dicomData appendBytes:buffer length:1];

}

- (void)addUnsignedShort:(unsigned short)uShort{
	int size = 2;
	union {
			unsigned short us;
			short ss;
			unsigned char buffer[size];
	} u;
	if ([self isLittleEndian]) 
		u.us = NSSwapHostShortToLittle(uShort);
	else
		u.us = uShort;

	[dicomData appendBytes:u.buffer length:size];
}

- (void)addSignedShort:(signed short)sShort{
	int size = 2;
	union {
		unsigned short us;
		short ss;
		unsigned char buffer[size];
	} u;
	u.ss = sShort;
	if ([self isLittleEndian]) 
		u.us = NSSwapHostShortToLittle(u.us);

	[dicomData appendBytes:u.buffer length:size];
}

- (void)addUnsignedLong:(unsigned long)uLong{
	int size = 4;
	union {
		unsigned long ul;
		unsigned char buffer[size];
	} u;
	u.ul = uLong;
	if ([self isLittleEndian]) 
		u.ul = NSSwapHostLongToLittle(u.ul);

	[dicomData appendBytes:u.buffer length:size];
}

- (void)addSignedLong:(signed long)sLong{
	int size = 4;
	union {
		unsigned long ul;
		long sl;
		unsigned char buffer[size];
	} u;
	u.sl = sLong;
	if ([self isLittleEndian]) 
		u.ul = NSSwapHostLongToLittle(u.ul);

	[dicomData appendBytes:u.buffer length:size];
}

- (void)addUnsignedLongLong:(unsigned long long)uLongLong{
	int size = 8;
	union {
		unsigned long ull;
		long sll;
		unsigned char buffer[size];
	} u;
	u.ull = uLongLong;
	if ([self isLittleEndian]) 
		u.ull = NSSwapHostLongToLittle(u.ull);

	[dicomData appendBytes:u.buffer length:size];
}

- (void)addSignedLongLong:(signed long long)sLongLong{
	int size = 8;
	union {
		unsigned long ull;
		long sll;
		unsigned char buffer[size];
	} u;
	u.sll = sLongLong;
	if ([self isLittleEndian]) 
		u.ull = NSSwapHostLongToLittle(u.ull);

	[dicomData appendBytes:u.buffer length:size];

}

- (void)addFloat:(float)f{
	int size = 4;
	union {
		float f;
		unsigned long l;
		unsigned char buffer[size];
	} u;
	u.f = f;
	if ([self isLittleEndian]) 
		u.l = NSSwapHostLongToLittle(u.l);

	[dicomData appendBytes:u.buffer length:size];
}


- (void)addDouble:(double)d{
	int size = 8;
	union {
		double d;
		unsigned long long l;
		unsigned char buffer[size];
	} u;
	u.d = d;
	if ([self isLittleEndian]) 
		u.l = NSSwapHostLongLongToLittle(u.l);

	[dicomData appendBytes:u.buffer length:size];
}

- (void)addString:(NSString *)string{
	NSData *data = [string dataUsingEncoding:stringEncoding];
	[dicomData appendData:data];
	int length = [string length];
	if (length%2)
		[self addUnsignedChar:0];
		//[self addUnsignedChar:0];
	
}
- (void)addString:(NSString *)string withEncoding:(NSStringEncoding)encoding{
	NSData *data = [string dataUsingEncoding:encoding];
	[dicomData appendData:data];
	int length = [string length];
	if (length%2)
		[self addUnsignedChar:0];
		//[self addUnsignedChar:0];
	
}

- (void)addStringWithoutPadding:(NSString *)string{
	NSData *data = [string dataUsingEncoding:stringEncoding];
	[dicomData appendData:data];
}

- (void)addDate:(DCMCalendarDate *)date{
	NSString *string = [date dateString];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[dicomData appendData:data];	
}
- (void)addTime:(DCMCalendarDate *)time{
	NSString *string = [time timeString];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[dicomData appendData:data];	
}

- (void)addDateTime:(DCMCalendarDate *)dateTime{
	NSString *string = [dateTime dateTimeString:NO];
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[dicomData appendData:data];	
}

- (void)addData:(NSData *)data{
	[dicomData appendData:data];
}

- (DCMTransferSyntax *) transferSyntaxForDataset{
	return transferSyntaxForDataset;
}
- (DCMTransferSyntax *)  transferSyntaxForMetaheader{
	return transferSyntaxForMetaheader;
}
- (DCMTransferSyntax *)   transferSyntaxInUse{
	return transferSyntaxInUse;
}

- (void)setTransferSyntaxForDataset:(DCMTransferSyntax *)ts{
	if (DEBUG)
		NSLog(@"setTransferSyntaxForDataset:%@", [ts description]);
	[transferSyntaxForDataset release];
	transferSyntaxForDataset = [ts retain];
}

- (void)setTransferSyntaxForMetaheader:(DCMTransferSyntax *)ts{
	[transferSyntaxForMetaheader release];
	transferSyntaxForMetaheader = [ts retain];
}

- (void)setUseMetaheaderTS:(BOOL)flag{
	[transferSyntaxInUse release];
	if (flag)
		transferSyntaxInUse = [transferSyntaxForMetaheader retain];
	else	
		transferSyntaxInUse = [transferSyntaxForDataset retain];
}


- (BOOL)determineTransferSyntax
{
	[transferSyntaxInUse release];
	transferSyntaxInUse = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
	NSException* exception;
	position = 128;
	int group;
	int element;
	NSString *vr;
	NSString *dicm = [self nextStringWithLength:4];
	if ([dicm isEqualToString:@"DICM"]) { //DICOM.10 file
		if (DEBUG)
			NSLog(@"Dicom part 10 file");
		
		/*
		transferSyntaxForMetaheader should be  explicit VR LE
		check for valid VR, just in case
		*/
		group = [self nextUnsignedShort];
		element = [self nextUnsignedShort];
		vr = [self nextStringWithLength:2];
		
		if (DEBUG)
			NSLog(@"group: %0004d element: %0004d vr: %@" , group, element, vr);

		if ([DCMValueRepresentation isValidVR:vr]) {
			[transferSyntaxForMetaheader release];
			transferSyntaxForMetaheader = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
			
		}
		else {
			[transferSyntaxForMetaheader release];
			transferSyntaxForMetaheader = [[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] retain];
		}
		[transferSyntaxInUse release];
		transferSyntaxInUse = [transferSyntaxForMetaheader retain];
		offset = 132;
		position = 132;
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
			[transferSyntaxForDataset release];
			transferSyntaxForDataset =  [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
			[transferSyntaxInUse release];
			transferSyntaxInUse = [transferSyntaxForDataset retain];
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
				[transferSyntaxForDataset release];
				transferSyntaxForDataset = [[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax] retain];
				
				[transferSyntaxInUse release];
				transferSyntaxInUse = [transferSyntaxForDataset retain];
				position = 0;
				offset = 0;
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
				//NSDictionary *tagValues = [[DCMTagDictionary sharedTagDictionary] objectForKey:[tag stringValue]];
				// have valid tag. Should be dicom
				if (tag) {
					
					[transferSyntaxForMetaheader release];
					transferSyntaxForMetaheader = [[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] retain];
					
					[transferSyntaxForDataset release];
					transferSyntaxForDataset = [transferSyntaxForMetaheader retain];
				}
				[transferSyntaxInUse release];
				transferSyntaxInUse = [transferSyntaxForDataset retain];
				position = 0;
				offset = 0;
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
		
	if (position + elementLength > [dicomData length]) {
		NSArray *keys = [NSArray arrayWithObjects:@"position", @"elementLength", @"dataLength", nil];
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:position], [NSNumber numberWithInt:elementLength], [NSNumber numberWithInt:[dicomData length]], nil];
	
		NSDictionary *userInfo =  [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		if (DEBUG)
			NSLog(@"error Info: %@", [userInfo description]);
		return [NSException exceptionWithName:@"DCMInvalidLengthException" reason:@"Length of element exceeds length remaining in data." userInfo:userInfo];
	}
	return nil;
}

- (unsigned)length {
	return [dicomData length];
}

- (void)startReadingMetaHeader
{
	[transferSyntaxInUse release];
	transferSyntaxInUse = [transferSyntaxForMetaheader retain];
}
- (void)startReadingDataSet{
	[transferSyntaxInUse release];
	transferSyntaxInUse = [transferSyntaxForDataset retain];
}

- (void)addPremable{
	NSMutableData *emptyData = [NSMutableData dataWithLength:128];
	[dicomData appendData:emptyData];
	[self addString:@"DICM"];
}

@end
