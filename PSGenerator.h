/* PSGenerator */

#import <Cocoa/Cocoa.h>

@interface PSGenerator : NSObject
{
	// Parameters
	NSMutableString		*formatString;
	NSMutableDictionary	*sourceStringsDict;
	unsigned			minLength;
	unsigned			maxLength;
	unsigned			alternativeNum;
	BOOL				shouldMix;
	
	// Temporary Variables
	NSMutableArray  *tempArray;
	NSMutableString *tempString;
	NSString		*sourceString;
	NSString		*tempKey;
	NSMutableString *tempFormatString;
	unsigned		thisLength;
	unsigned		randCharPos;
	unsigned		tempAltNum;
	int				i, j, x, y;
	
}

- (id) initWithFormatString: (NSMutableString *) str
			  sourceStrings: (NSMutableDictionary *) stringDict
				  minLength: (unsigned) min
				  maxLength: (unsigned) max;
- (id) initWithSourceString: (NSString *) str
				  minLength: (unsigned) min
				  maxLength: (unsigned) max;
- (void) dealloc;


- (void) setFormatString: (NSMutableString *) str;
- (void) setStandardFormatString;
- (void) setSourceStrings: (NSMutableDictionary *) stringDict;
- (void) setMinLength: (unsigned) min;
- (void) setMaxLength: (unsigned) max;
- (void) setAlternativeNum: (unsigned) num;

- (NSString *) mainCharacterString;
- (NSString *) altCharacterString;
- (unsigned) minLength;
- (unsigned) maxLength;
- (unsigned) alternativeNum;
 

- (void) addStringToDict: (NSString *) str
				 withKey: (NSString *) key;

- (NSArray *) generate: (unsigned) numPasswords;
- (void) prepareFormatString;
@end

int randomNumberBetween( int low, int high );