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

#import "DCMDataContainer.h"
#import "DCM.h"

static NSString *signalCatch = @"signalCatch";

void (*signal(int signum, void (*sighandler)(int)))(int);

static sigjmp_buf mark;

void signal_EXC(int sig_num)
{
    NSLog( @"******** Signal %d - DCMDataContainer - Catch the exception and resume function", sig_num);
    
    siglongjmp( mark, -1 );
}

@implementation DCMDataContainer

@synthesize offset, dicomData, position;

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

//+ (id)dataContainerWithContentsOfMappedFile:(NSString *)path{
//	return [[[DCMDataContainer alloc] initWithContentsOfMappedFile:path] autorelease];
//}

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

+ (id)dataContainerWithMutableData:(NSMutableData *)aData transferSyntax:(DCMTransferSyntax *)syntax{
	//NSLog(@"Data Length: %d", [aData length]);
	return [[[DCMDataContainer alloc] initWithData:aData transferSyntax:syntax] autorelease];
}

- (id) initWithData:(NSData *)data
{
    id object = nil;
    
	if (self = [super init])
    {
        @synchronized( signalCatch)
        {
            signal( SIGBUS , signal_EXC);
            signal( SIGFPE , signal_EXC);
            
            if( sigsetjmp( mark, 1) != 0)
            {
                // signal catch
                NSLog( @"%@", [NSThread callStackSymbols]);
            }
            else
            {        
                void *ptr = malloc( data.length);
                if( ptr)
                {
                    memcpy( ptr, data.bytes, data.length);
                    
                    void *tempPtr = malloc( data.length);
                    if( tempPtr)
                    {
                        free( tempPtr);
                        
                        dicomData = [[NSMutableData alloc] initWithBytesNoCopy: ptr length: data.length freeWhenDone: YES];
                        _ptr = (unsigned char *)[dicomData bytes];
                        
                        if (![self determineTransferSyntax])
                            [dicomData release];
                        else
                            object = self;
                    }
                    else
                        free( ptr);
                }
            }
            
            signal( SIGBUS, SIG_DFL);
            signal( SIGFPE, SIG_DFL);
        }
	}
    
    if( object == nil)
        [self autorelease];
    
    return object;
}

- (id)initWithData:(NSData *)data transferSyntax:(DCMTransferSyntax *)syntax{
	if (self = [super init]) {
		dicomData = [data mutableCopy];
		transferSyntaxForMetaheader = [syntax retain];
		transferSyntaxForDataset = [syntax retain];
		transferSyntaxInUse = [transferSyntaxForDataset retain];
		_ptr = (unsigned char *)[dicomData bytes];
	}
	return self;
}

- (id)initWithMutableData:(NSMutableData *)data transferSyntax:(DCMTransferSyntax *)syntax{
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
	/*if (self = [super init]) {
		dicomData = [[NSMutableData dataWithContentsOfURL:aURL] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
        {
			[dicomData release];
            [self autorelease];
            return nil;
        }
	}
	return self;*/
}

- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length{
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithBytes:bytes length:length] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
		{
            [self autorelease];
            return nil;
        }
	}
	return self;
}

- (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length{
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithBytesNoCopy:bytes length:length] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
		{
            [dicomData release];
            [self autorelease];
            return nil;
        }
	}
	return self;
}

 - (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)flag{
	if (self = [super init]) {
		dicomData = [[NSMutableData dataWithBytesNoCopy:bytes length:length freeWhenDone:flag] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		if (![self determineTransferSyntax])
		{
            [dicomData release];
            [self autorelease];
            return nil;
        }
	}
	return self;
}

- (id)init{
	if (self = [super init])
    {
		dicomData = [[NSMutableData data] retain];
		_ptr = (unsigned char *)[dicomData bytes];
		transferSyntaxForMetaheader = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
		[self initValues];
    }
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
	if (transferSyntaxInUse)
		return [transferSyntaxInUse isLittleEndian];
	return YES;
}

- (BOOL)isExplicitTS{
	if (transferSyntaxInUse)
		return [transferSyntaxInUse isExplicit];
	return YES;
}

- (BOOL)isEncapsulated{
	if (transferSyntaxInUse)
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
		const int size = 8;
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


- (NSString *)nextStringWithLength:(int)length
{
	NSException *exception = [self testForLength:length];
	if (!exception)
	{
		if (stringEncoding == 0)
			stringEncoding = NSISOLatin1StringEncoding;
			
		NSString *string = [[[NSString alloc] initWithBytes:(_ptr + position) length:(unsigned)length encoding:stringEncoding] autorelease];
		NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
		position += length;
        
		return [trimmedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	}
	else 
		[exception raise];
	return nil;
}

- (NSString *)nextStringWithLength:(int)length encodings:(NSStringEncoding*)encodings
{
	NSException *exception = [self testForLength:length];
	if (!exception)
	{
		NSString *string = [DCMCharacterSet stringWithBytes: (char*) (_ptr + position) length:(unsigned)length encodings:encodings];
        
		NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		position += length;
        
		return [trimmedString stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
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
		if (length == 4)
			format = @"%H%M";
		else if (length == 6)
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
	if (DCMDEBUG)
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
		if (length == 12)
			format = @"%Y%m%d%H%M";
		else if (length == 14)
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
	NSMutableArray *times = [NSMutableArray array];
    
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

- (NSMutableData *)nextDataWithLength:(int)length
{
	NSException *exception = [self testForLength: length];
	if (!exception)
    {
        NSMutableData *aData = nil;
        void *ptr = malloc( length);
        if( ptr)
        {
            memcpy( ptr, dicomData.bytes + position, length);
            
            void *tempPtr = malloc( length);
            if( tempPtr)
            {
                free( tempPtr);
                
                aData = [NSMutableData dataWithBytesNoCopy: ptr length: length freeWhenDone: YES];
            
                if( aData == nil)
                    free( ptr);
            }
            else
            {
                free( ptr);
                NSLog( @"****** NOT ENOUGH MEMORY ! UPGRADE TO OSIRIX 64-BIT");
            }
        }
        else
            NSLog( @"****** NOT ENOUGH MEMORY ! UPGRADE TO OSIRIX 64-BIT");
        
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
	const int size = 2;
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
	const int size = 2;
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
	const int size = 4;
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
	const int size = 4;
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
	const int size = 8;
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
	const int size = 8;
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
	const int size = 4;
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
	const int size = 8;
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
	int length = (int)[data length];
	if (length%2)
		[self addUnsignedChar: ' '];
	
}

- (void)addStringWithZeroPadding:(NSString *)string{
	NSData *data = [string dataUsingEncoding:stringEncoding];
	[dicomData appendData:data];
	int length = (int)[data length];
	if (length%2)
		[self addUnsignedChar: 0x00];
}


- (void)addString:(NSString *)string withEncodings:(NSStringEncoding*)encodings
{
//	unichar c;
//	int	 i, from, index;
//	NSMutableData *result = [NSMutableData data];
//	
//	for( i = 0, from = 0, index = 0; i < [string length]; i++)
//	{
//		c = [string characterAtIndex: i];
//		
//		if( c == 0x1b)
//		{
//			NSRange range = NSMakeRange( from, i-from);
//			
//			NSData *s = [[string substringWithRange: range] dataUsingEncoding: encodings[ index]];
//			
//			if( s)
//				[result appendData: s];
//			
//			from = i;
//			if( index < 9)
//			{
//				index++;
//				if( encodings[ index] == 0)
//					index--;
//			}
//		}
//	}
//	
//	[dicomData appendData: result];
//	int length = [result length];
//	if (length%2)
//		[self addUnsignedChar:' '];
	
	NSData *data = [string dataUsingEncoding:encodings[ 0]];
	[dicomData appendData:data];
	int length = (int)[data length];
	if (length%2)
		[self addUnsignedChar:' '];
}

- (void)addString:(NSString *)string withEncoding:(NSStringEncoding)encoding
{
	NSData *data = [string dataUsingEncoding:encoding];
	[dicomData appendData:data];
	int length = (int)[data length];
	if (length%2)
		[self addUnsignedChar:' '];	
}

- (void)addStringWithoutPadding:(NSString *)string
{
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
	NSMutableData *newData = [NSMutableData dataWithData:data];
	if ([data length] %2 != 0)
		[newData increaseLengthBy:1];
	[dicomData appendData:newData];
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
	if (DCMDEBUG)
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
	
	if ([dicm isEqualToString:@"DICM"])
	{ //DICOM.10 file
		if (DCMDEBUG)
			NSLog(@"Dicom part 10 file");
		
		/*
		transferSyntaxForMetaheader should be  explicit VR LE
		check for valid VR, just in case
		*/
		group = [self nextUnsignedShort];
		element = [self nextUnsignedShort];
		vr = [self nextStringWithLength:2];
		
		if (DCMDEBUG)
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
	else
	{
		int vl;
		position = 0;
		offset = 0;
		group = [self nextUnsignedShort];
		element = [self nextUnsignedShort];
		vr = [self nextStringWithLength:2];
		if ([DCMValueRepresentation isValidVR:vr])
		{  //have valid VR assume explicit Little Endian
			[transferSyntaxForDataset release];
			transferSyntaxForDataset =  [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
			[transferSyntaxInUse release];
			transferSyntaxInUse = [transferSyntaxForDataset retain];
			
			return YES;
		}
		// implicit is the default. Could still be Big Endian
		else{
			const char *vrChars = [vr UTF8String];
			char flipVR[3];
			flipVR[0] = vrChars[1];
			flipVR[1] = vrChars[0];
			flipVR[2] = 0;
			
			NSString *newVR = [NSString stringWithCString:flipVR encoding: NSASCIIStringEncoding];
			if ([DCMValueRepresentation isValidVR:newVR])
			{
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
	@try {
	exception = [NSException exceptionWithName:@"DCMNotDicomError" reason:@"File is not DICOM" userInfo:nil];
	[exception raise];
	} @catch( NSException *localException) {
		NSLog(@"ERROR:%@  REASON:%@", [exception name], [exception reason]);
	}
	return NO;			
}

- (NSException *)testForLength: (int)elementLength
{
	if (position + elementLength > [dicomData length] || elementLength < 0 || position < 0)
    {
		NSArray *keys = [NSArray arrayWithObjects:@"position", @"elementLength", @"dataLength", nil];
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:position], [NSNumber numberWithInt:elementLength], [NSNumber numberWithInt:(int)[dicomData length]], nil];
	
		NSDictionary *userInfo =  [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		if (DCMDEBUG)
			NSLog(@"error Info: %@", [userInfo description]);
        
        
        
		return [NSException exceptionWithName:@"DCMInvalidLengthException" reason:@"Length of element exceeds length remaining in data." userInfo:userInfo];
	}
    
    if( elementLength > 100)
    {
        void *ptr = malloc( elementLength + 1024);
        if( ptr == nil)
        {
            NSLog( @"****** NOT ENOUGH MEMORY ! UPGRADE TO OSIRIX 64-BIT");
            return [NSException exceptionWithName: @"Not Enough Memory" reason: @"Not Enough Memory - Upgrade to OsiriX 64-bit." userInfo: nil];
        }
        else free( ptr);
    }
    
	return nil;
}

- (unsigned)length {
	return (unsigned)[dicomData length];
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
