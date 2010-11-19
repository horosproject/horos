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

#import "WebPortalData.h"
#import "WebPortalConnection.h"
#import "WebPortalSession.h"
#import "WebPortalPages.h"
#import "NSString+N2.h"
#import "AppController.h"


@implementation WebPortalData

+(NSRange)string:(NSString*)string rangeOfFirstOccurrenceOfBlock:(NSString*)b {
	NSString* begin = [NSString stringWithFormat: @"%%%@%%", b];
	NSString* end = [NSString stringWithFormat: @"%%/%@%%", b];
	
	NSRange range1 = [string rangeOfString:begin];
	if (!range1.length) return NSMakeRange(NSNotFound,0);
	NSRange range2 = [string rangeOfString:end];
	if (!range2.length) return NSMakeRange(NSNotFound,0);
	
	return NSMakeRange(range1.location, range2.location+range2.length-range1.location);
}

+(void)mutableString:(NSMutableString*)string block:(NSString*)b setVisible:(BOOL)visible {
	if (!visible)
		while (true) {
			NSRange range = [self string:string rangeOfFirstOccurrenceOfBlock:b];
			if (!range.length) break;
			[string replaceCharactersInRange:range withString:@""];
		}
	
	NSString* begin = [NSString stringWithFormat: @"%%%@%%", b];
	NSString* end = [NSString stringWithFormat: @"%%/%@%%", b];
	
	[string replaceOccurrencesOfString:begin withString:@"" options:NSLiteralSearch range:string.range];
	[string replaceOccurrencesOfString:end withString:@"" options:NSLiteralSearch range:string.range];
}

+(id)object:(id)o valueForKeyPath:(NSString*)keyPath {
	NSArray* parts = [keyPath componentsSeparatedByString:@"."];
	NSString* part0 = [parts objectAtIndex:0];
	
	/*if ([part0 isEqual:@"Defaults"]) {
		o = [NSUserDefaultsController sharedUserDefaultsController];
		keyPath = [[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@"."];
	}*/

	if ([o isKindOfClass:[NSDate class]])
		return [self object:[WebPortalProxy createWithObject:o transformer:[DateTransformer create]] valueForKeyPath:keyPath];
	if ([o isKindOfClass:[NSArray class]])
		return [self object:[WebPortalProxy createWithObject:o transformer:[ArrayTransformer create]] valueForKeyPath:keyPath];
	
	/*@try {
		id value = [o valueForKeyPath:keyPath];
		if (value)
			return value;
	} @catch (NSException* e) {
	}*/
	
	@try {
		id value = [o valueForKey:part0];
		if (parts.count > 1)
			return [self object:value valueForKeyPath:[[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@"."]];
		return value;
	} @catch (NSException* e) {
	}
	
	return NULL;
}

+(NSString*)evaluateToken:(NSString*)tokenStr withDictionary:(NSDictionary*)dict mustReevaluate:(BOOL*)mustReevaluate {
	// # separates the actual token from extra chars that can be used as comments or as marker for otherwise equal tokens
	NSArray* tokenStrParts = [tokenStr componentsSeparatedByString:@"#"];
	NSString* token = [tokenStrParts objectAtIndex:0];
	NSString* tokenStrExtras = tokenStrParts.count>1? [NSString stringWithFormat:@"#%@", [[tokenStrParts subarrayWithRange:NSMakeRange(1,tokenStrParts.count-1)] componentsJoinedByString:@"#"]] : @"";
	
	NSArray* parts = [token componentsSeparatedByString:@":"];
	NSString* part0 = [parts objectAtIndex:0];
	
	// is it a command?
	
//	NSLog(@"Evaluating %@ with %@", tokenStr, dict.description);
	
	if ([part0 isEqual:@"FOREACH"]) {
		NSString* arrayName = [parts objectAtIndex:1];
		NSString* iName = [parts objectAtIndex:2];
		
		NSString* body = [dict objectForKey:[token stringByAppendingString:@":Body"]];
		
		NSMutableString* ret = [NSMutableString string];
		
		NSMutableDictionary* idict = [[dict mutableCopy] autorelease];
		for (id i in [self object:dict valueForKeyPath:arrayName]) {
			[idict setObject:i forKey:iName];
			NSMutableString* istr = [[body mutableCopy] autorelease];
			[self mutableString:istr evaluateTokensWithDictionary:idict];
			[ret appendString:istr];
		}
		
		return ret;
	}
	
	if ([part0 isEqual:@"IF"]) {
		NSString* condition = [parts objectAtIndex:1];
		BOOL negate = NO;
		
		if ([condition characterAtIndex:0] == '!') {
			negate = YES;
			condition = [condition substringFromIndex:1];
		}
		
		id o = [self object:dict valueForKeyPath:condition];
		BOOL satisfied = NO;
		if ([o isKindOfClass:[NSNumber class]])
			satisfied = [o boolValue];
		else if (o)
			satisfied = YES;
		
		if (negate)
			satisfied = !satisfied;
		
		NSString* body = [dict objectForKey:[token stringByAppendingString:@":Body"]];
		NSString* bodyYes;
		NSString* bodyNo = NULL;
		NSRange elseRange = [body rangeOfString:[NSString stringWithFormat:@"%%ELSE:%@%@%%", [parts objectAtIndex:1], tokenStrExtras]];
		if (elseRange.length) {
			bodyYes = [body substringToIndex:elseRange.location];
			bodyNo = [body substringFromIndex:elseRange.location+elseRange.length];
		} else {
			bodyYes = body;
			bodyNo = @"";
		}
		
		*mustReevaluate = YES;
		return satisfied? bodyYes : bodyNo;
	}
	
	if ([part0 isEqual:@"URLENC"] || [part0 isEqual:@"U"]) {
		token = [[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@":"];
		return [[self evaluateToken:token withDictionary:dict mustReevaluate:mustReevaluate] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	if ([part0 isEqual:@"XMLENC"] || [part0 isEqual:@"X"]) {
		token = [[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@":"];
		NSString* evaldToken = [self evaluateToken:token withDictionary:dict mustReevaluate:mustReevaluate];
		return [evaldToken xmlEscapedString];
	}
	
	// or is it just a value?
	NSObject* o = [self object:dict valueForKeyPath:token];
	if (o) {
		if ([o isKindOfClass:[NSString class]])
			return (NSString*)o;
		// if ([o isKindOfClass:[NSDate class]]) // TODO: other...
		
		return o.description;
	}
	
	return @"";
}

+(void)mutableString:(NSMutableString*)string evaluateTokensWithDictionary:(NSDictionary*)tokens {
	NSRange range = string.range, occ;
	
	// scan for tokens
	while (range.location < string.length-1 && (occ = [string rangeOfString:@"%" options:NSLiteralSearch range:range]).length) {
		BOOL isToken = YES;
		// is it a token, or just a random percentage?
		NSRange occ2 = [string rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(occ.location+1, string.length-occ.location-1)];
		
		if (!occ2.length)
			isToken = NO;
		else if ([string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\n\r"] options:0 range:NSMakeRange(occ.location+1, occ2.location-occ.location-1)].length)
			isToken = NO;
		
		if (isToken) {
			// we have 2 eventual token delimiters, what's in between?
			NSString* tokenStr = [string substringWithRange:NSMakeRange(occ.location+1, occ2.location-occ.location-1)];
			NSMutableDictionary* dict = [[tokens mutableCopy] autorelease];
			
			if ([tokenStr characterAtIndex:0] == '[') { // opens a block, look for its closing
				tokenStr = [tokenStr substringFromIndex:1];
				NSString* tokenCloser = [NSString stringWithFormat:@"%%]%@%%", tokenStr];
				NSRange tokenCloserRange = [string rangeOfString:tokenCloser options:NSLiteralSearch range:NSMakeRange(occ2.location+1, string.length-(occ2.location+1))];
				if (tokenCloserRange.length) {
					NSString* blockKey = [[[tokenStr componentsSeparatedByString:@"#"] objectAtIndex:0] stringByAppendingString:@":Body"];
					[dict setObject:[string substringWithRange:NSMakeRange(occ2.location+1, tokenCloserRange.location-(occ2.location+1))] forKey:blockKey];
					occ2.location = tokenCloserRange.location+tokenCloserRange.length-1;
				}
			}
				
			BOOL mustReevaluate = NO;
			NSString* evaldStr = [self evaluateToken:tokenStr withDictionary:dict mustReevaluate:&mustReevaluate];
			if (evaldStr) {
				[string replaceCharactersInRange:NSMakeRange(occ.location, occ2.location-occ.location+1) withString:evaldStr];
				range.location = occ.location;
				if (!mustReevaluate)
					range.location += evaldStr.length; 
				range.length = string.length-range.location;
			} else
				isToken = NO;
		}
		
		if (!isToken) {
			range.location = occ.location+1;
			range.length = string.length-range.location;
		}
	}
}

@end


@interface WebPortalProxy ()

@property(readwrite, retain) NSObject* object;
@property(readwrite, retain) NSArray* transformers;

@end

@implementation WebPortalProxy

@synthesize object, transformers;

-(id)initWithObject:(NSObject*)o transformer:(NSObject*)t {
	self = [super init];
	self.object = o;
	
	if ([t isKindOfClass:[NSArray class]]) {
		for (NSObject* it in (NSArray*)t)
			if (![it isKindOfClass:[WebPortalProxyObjectTransformer class]])
				[NSException raise:NSInvalidArgumentException format:@"Invalid transformer class: %@", it.className];
		self.transformers = (NSArray*)t;
	} else if ([t isKindOfClass:[WebPortalProxyObjectTransformer class]])
		self.transformers = [NSArray arrayWithObject:t];
	else [NSException raise:NSInvalidArgumentException format:@"Invalid transformer class: %@", t.className];
	
	return self;
}

+(id)createWithObject:(NSObject*)o transformer:(id)t {
	return [[[self alloc] initWithObject:o transformer:t] autorelease];
}

-(void)dealloc {
	self.object = NULL;
	self.transformers = NULL;
	[super dealloc];
}

-(NSObject*)valueForKey:(NSString*)key {
	for (WebPortalProxyObjectTransformer* t in transformers)
		@try {
			id r = [t valueForKey:key object:object];
			if (r) return r;
		} @catch (NSException * e) {
		}
	
	return [object valueForKey:key];
}

@end


@implementation WebPortalProxyObjectTransformer : NSObject

-(id)valueForKey:(NSString*)k object:(NSObject*)o {
	return NULL;
}

@end


@interface NSMutableDictionary ()

-(NSMutableArray*)errors;

@end
@implementation NSMutableDictionary (WebPortalProxy)

static const NSString* const MessagesArrayTokenKey = @"Messages";
static const NSString* const ErrorsArrayTokenKey = @"Errors";

-(void)addError:(NSString*)error {
	[self.errors addObject:error];
}

-(void)addMessage:(NSString*)message {
	NSMutableArray* messages = [self objectForKey:MessagesArrayTokenKey];
	if (![messages isKindOfClass:[NSMutableArray class]]) {
		messages = [NSMutableArray array];
		[self setObject:messages forKey:MessagesArrayTokenKey];
	}
	
	[messages addObject:message];
}

-(NSMutableArray*)errors {
	NSMutableArray* errors = [self objectForKey:ErrorsArrayTokenKey];
	if (![errors isKindOfClass:[NSMutableArray class]]) {
		errors = [NSMutableArray array];
		[self setObject:errors forKey:ErrorsArrayTokenKey];
	}
	
	return errors;
}

@end


/*

@implementation WebPortalAlbumProxy : WebPortalProxy

+(id)album:(DicomAlbum*)album {
	return [[[self alloc] initWithObject:album] autorelease];
}

-(NSString*)type {
	return ((DicomAlbum*)object).smartAlbum.boolValue? @"SmartAlbum" : @"Album";
}

@end


*/