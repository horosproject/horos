#import <Foundation/Foundation.h>

@class  DCMTransferSyntax;
@interface DCMMutableData : NSMutableData {

BOOL isLittleEndian, isExplicitTS, dataRemaining;
int offset, position;
NSStringEncoding stringEncoding;
DCMTransferSyntax  	*transferSyntaxToReadDataSet, *transferSyntaxToReadMetaHeader, *transferSyntaxInUse; 



}
- (void)initValues;

- (BOOL)isLittleEndian;
- (BOOL)isExplicitTS;
- (BOOL)isEncapsulated;
- (BOOL)dataRemaining;
- (NSStringEncoding) stringEncoding;
- (void)setLittleEndian:(BOOL)value;
- (void)setExplicitTS:(BOOL)value;

- (void)setStringEncoding:(NSStringEncoding)encoding;

- (unsigned char)nextUnsignedChar;
- (unsigned short)nextUnsignedShort;
- (short)nextSignedShort;
- (unsigned long)nextUnsignedLong;
- (long)nextSignedLong;
- (unsigned long long)nextUnsignedLongLong;
- (long long)nextSignedLongLong;
- (float)nextFloat;
- (double)nextDouble;

- (NSString *)nextStringWithLength:(int)length;
- (NSString *)nextStringWithLength:(int)length encoding:(NSStringEncoding)encoding;
- (NSCalendarDate *)nextDate;
- (NSCalendarDate *)nextTimeWithLength:(int)length;
- (NSCalendarDate *)nextDateTimeWithLength:(int)length;
- (NSData *)nextDataWithLength:(int)length;

- (void)addUnsignedChar:(unsigned char)uChar;
- (void)addSignedChar:(signed char)sChar;
- (void)addUnsignedShort:(unsigned short)uShort;
- (void)addSignedShort:(signed short)sShort;
- (void)addUnsignedLong:(unsigned long)uLong;
- (void)addSignedLong:(signed long)sLong;
- (void)addUnsignedLongLong:(unsigned long long)uLongLong;
- (void)addSignedLongLong:(signed long long)sLongLong;
- (void)addFloat:(float)f;
- (void)addDouble:(double)d;

- (void)addString:(NSString *)string;
- (void)addString:(NSString *)string withEncoding:(NSStringEncoding)encoding;
- (void)addDate:(NSCalendarDate *)date;
- (void)addTime:(NSCalendarDate *)time;
- (void)addDateTime:(NSCalendarDate *)dateTime;

- (DCMTransferSyntax *) transferSyntaxToReadDataSet;
- (DCMTransferSyntax *)  transferSyntaxToReadMetaHeader;
- (DCMTransferSyntax *)   transferSyntaxInUse;
- (BOOL)determineTransferSyntax;
- (void)setTransferSyntaxToReadDataSet:(DCMTransferSyntax *)ts;
- (void)setTransferSyntaxToReadMetaHeader:(DCMTransferSyntax *)ts;

- (NSException *)testForLength: (int)elementLength;





@end
