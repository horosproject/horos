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

#import "WebPortalResponse.h"
#import "WebPortalConnection.h"
#import "WebPortalConnection+Data.h"
#import "WebPortalSession.h"
#import "WebPortalDatabase.h"
#import "WebPortal.h"
#import "NSString+N2.h"
#import "AppController.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "BrowserController.h"
#import "DCMAbstractSyntaxUID.h"
#import "NSManagedObject+N2.h"
#import "N2Operators.h"
#import "NSUserDefaults+OsiriX.h"


@implementation WebPortalResponse

@synthesize httpHeaders, templateString, statusCode, wpc;

-(id)initWithWebPortalConnection:(WebPortalConnection*)iwpc {
	self = [super initWithData:NULL];
	wpc = iwpc;
	portal = wpc.portal;
	httpHeaders = [[NSMutableDictionary alloc] initWithCapacity:4];
	return self;
}

/*-(id)initWithData:(NSData*)idata mime:(NSString*)mime sessionId:(NSString*)sessionId {
 self = [self init];
 self.data = idata;
 // if (mime) [httpHeaders setObject:mime forKey:@"Content-Type"];
 if (sessionId) ;
 return self;
 }*/

-(void)dealloc {
	[httpHeaders release];
	[templateString release];
	[tokens release];
	[super dealloc];
}

-(void)setSessionId:(NSString*)sessionId {
	[httpHeaders setObject:[NSString stringWithFormat:@"%@=%@; path=/", SessionCookieName, sessionId] forKey:@"Set-Cookie"];
}

-(NSString*)mimeType {
	return [httpHeaders objectForKey:@"Content-Type"];
}

-(void)setMimeType:(NSString*)value {
	[httpHeaders setObject:value forKey:@"Content-Type"];
}

-(void)setDataWithString:(NSString*)str {
	[self setData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSData*)data {
	if (!data && templateString) {
		NSMutableString* ts = self.templateString.mutableCopy;
		[WebPortalResponse mutableString:ts evaluateTokensWithDictionary:self.tokens context:wpc];
		[self setDataWithString:ts];
		[ts release];
	}
	
	if (!data) {
		self.data = [NSData data];
		if (!self.statusCode)
			self.statusCode = 404;
	}
	
	return data;
}
/*
-(UInt64)contentLength {
	return self.data.length;
}*/

-(void)setData:(NSData*)d {
	if (data != d) {
		[data release];
		data = [d retain];
	}
}

-(NSMutableDictionary*)tokens {
	if (!tokens)
		tokens = [[NSMutableDictionary alloc] init];
	return tokens;
}



/*+(NSRange)string:(NSString*)string rangeOfFirstOccurrenceOfBlock:(NSString*)b {
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
}*/

+(id)object:(id)o valueForKeyPath:(NSString*)keyPath context:(id)context {
	NSArray* parts = [keyPath componentsSeparatedByString:@"."];
	NSString* part0 = [parts objectAtIndex:0];
	
	/*if ([part0 isEqual:@"Defaults"]) {
		o = [NSUserDefaultsController sharedUserDefaultsController];
		keyPath = [[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@"."];
	}*/

	if ([o isKindOfClass:NSString.class])
		return [self object:[WebPortalProxy createWithObject:o transformer:[StringTransformer create]] valueForKeyPath:keyPath context:context];
	if ([o isKindOfClass:NSDate.class])
		return [self object:[WebPortalProxy createWithObject:o transformer:[DateTransformer create]] valueForKeyPath:keyPath context:context];
//	if ([o isKindOfClass:NSArray.class])
//		return [self object:[WebPortalProxy createWithObject:o transformer:[ArrayTransformer create]] valueForKeyPath:keyPath context:context];
//	if ([o isKindOfClass:NSSet.class])
//		return [self object:[WebPortalProxy createWithObject:o transformer:[SetTransformer create]] valueForKeyPath:keyPath context:context];
	if ([o isKindOfClass:WebPortalUser.class])
		return [self object:[WebPortalProxy createWithObject:o transformer:[WebPortalUserTransformer create]] valueForKeyPath:keyPath context:context];
	if ([o isKindOfClass:DicomStudy.class])
		return [self object:[WebPortalProxy createWithObject:o transformer:[DicomStudyTransformer create]] valueForKeyPath:keyPath context:context];
	if ([o isKindOfClass:DicomSeries.class])
		return [self object:[WebPortalProxy createWithObject:o transformer:[DicomSeriesTransformer create]] valueForKeyPath:keyPath context:context];
	
	if ([o isKindOfClass:NSManagedObject.class])
		return [self object:[WebPortalProxy createWithObject:o transformer:[WebPortalProxyObjectTransformer create]] valueForKeyPath:keyPath context:context];

	/*@try {
		id value = [o valueForKeyPath:keyPath];
		if (value)
			return value;
	} @catch (NSException* e) {
	}*/
	
	@try {
		id value = NULL;
		if ([o isKindOfClass:WebPortalProxy.class])
			value = [o valueForKey:part0 context:context];
		else {
			if ([o isKindOfClass:NSArray.class] || [o isKindOfClass:NSSet.class])
				part0 = [@"@" stringByAppendingString:part0];
			value = [o valueForKey:part0];
		}
		if (parts.count > 1)
			return [self object:value valueForKeyPath:[[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@"."] context:context];
		return value;
	} @catch (NSException* e) {
		NSLog(@"[WebPortalRosponse object:valueForKeyPath:context] %@", e);
	}
	
	return NULL;
}

+(NSString*)evaluateToken:(NSString*)tokenStr withDictionary:(NSDictionary*)dict context:(id)context mustReevaluate:(BOOL*)mustReevaluate {
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
		NSInteger c = 0;
		for (id i in [self object:dict valueForKeyPath:arrayName context:context]) {
			[idict setObject:i forKey:iName];
			[idict setObject:[NSNumber numberWithInteger:c] forKey:[NSString stringWithFormat:@"%@_Index", iName]];
			[idict setObject:[NSNumber numberWithInteger:c%2] forKey:[NSString stringWithFormat:@"%@_Index2", iName]];
			
			NSMutableString* istr = [[body mutableCopy] autorelease];
			[self mutableString:istr evaluateTokensWithDictionary:idict context:context];
			[ret appendString:istr];
			
			c++;
		}
		
		return ret;
	}
	
	if ([part0 isEqual:@"IF"]) {
		NSString* condition = [parts objectAtIndex:1];
		
		NSArray* conditionPartsOr = [condition componentsSeparatedByString:@"||"];
		BOOL orSatisfied = NO;
		for (NSString* condition in conditionPartsOr) {
			NSArray* conditionPartsAnd = [condition componentsSeparatedByString:@"&&"];
			BOOL andSatisfied = YES;
			for (NSString* condition in conditionPartsAnd) {
				BOOL negate = NO;
				
				if ([condition characterAtIndex:0] == '!') {
					negate = YES;
					condition = [condition substringFromIndex:1];
				}
				
				BOOL satisfied = NO;
				NSArray* conditionPartsOp = [condition componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"=<>"]];
				NSMutableArray* conditionPartsOp2 = [NSMutableArray array];
				for (NSString* s in conditionPartsOp)
					if (s.length)
						[conditionPartsOp2 addObject:s];
				if (conditionPartsOp2.count == 2) {
					NSString* sl = [conditionPartsOp2 objectAtIndex:0];
					unichar sl0 = [sl characterAtIndex:0];
					NSObject* vl = NULL;
					if (sl0 == '"' && [sl characterAtIndex:sl.length-1] == '"')
						vl = [sl substringWithRange:NSMakeRange(1,sl.length-2)];
					else if (sl0 >= '0' && sl0 <= '9')
						vl = [NSNumber numberWithFloat:sl.floatValue];
					else vl = [self object:dict valueForKeyPath:sl context:context];
					
					NSString* sr = [conditionPartsOp2 objectAtIndex:1];
					unichar sr0 = [sr characterAtIndex:0];
					NSObject* vr = NULL;
					if (sr0 == '"' && [sr characterAtIndex:sr.length-1] == '"')
						vr = [sr substringWithRange:NSMakeRange(1,sr.length-2)];
					else if (sr0 >= '0' && sr0 <= '9')
						vr = [NSNumber numberWithFloat:sr.floatValue];
					else vr = [self object:dict valueForKeyPath:sr context:context];
					
					if ([vl isKindOfClass:[vr class]] || [vr isKindOfClass:[vl class]])
						if ([vl isKindOfClass:NSString.class] || [vl isKindOfClass:NSNumber.class]) {
							NSComparisonResult cr = [(NSNumber*)vl compare:(NSNumber*)vr];
							NSString* op = [condition substringWithRange:NSMakeRange(sl.length, condition.length-sl.length-sr.length)];
							
							if ([op isEqual:@"=="])
								satisfied = cr==NSOrderedSame;
							if ([op isEqual:@"<"])
								satisfied = cr==NSOrderedAscending;
							if ([op isEqual:@">"])
								satisfied = cr==NSOrderedDescending;
							if ([op isEqual:@">="])
								satisfied = cr!=NSOrderedAscending;
							if ([op isEqual:@"<="])
								satisfied = cr!=NSOrderedDescending;
						}
				} else {
					id o = [self object:dict valueForKeyPath:condition context:context];
					
					if ([o isKindOfClass:[NSNumber class]])
						satisfied = [o boolValue];
					else if (o)
						satisfied = YES;
				}
				
				if (negate)
					satisfied = !satisfied;
				
				andSatisfied = andSatisfied && satisfied;
			}
			
			orSatisfied = orSatisfied || andSatisfied;
		}
		
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
		return orSatisfied? bodyYes : bodyNo;
	}
	
	if ([part0 isEqual:@"URLENC"] || [part0 isEqual:@"U"]) {
		token = [[parts subarrayWithRange:NSMakeRange(1,parts.count-1)] componentsJoinedByString:@":"];
		NSString* str = [self evaluateToken:token withDictionary:dict context:context mustReevaluate:mustReevaluate];
		return [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[str mutableCopy] autorelease], NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), kCFStringEncodingUTF8) autorelease];
	}
	
	if ([part0 isEqual:@"XMLENC"] || [part0 isEqual:@"X"]) {
		NSUInteger from = 1;
		
		NSString* part1 = NULL;
		if (parts.count >= 3)
			part1 = [parts objectAtIndex:1];
		
		if ([part1 isEqualToString:@"ZWS"])
			++from;
		
		token = [[parts subarrayWithRange:NSMakeRange(from,parts.count-from)] componentsJoinedByString:@":"];
		NSString* evaldToken = [self evaluateToken:token withDictionary:dict context:context mustReevaluate:mustReevaluate];
		
		if ([part1 isEqualToString:@"ZWS"])
			evaldToken = [[evaldToken componentsWithLength:1] componentsJoinedByString:[NSString stringWithFormat:@"%C",0x200b]];
		
		return [evaldToken xmlEscapedString];
	}
	
	// or is it just a value?
	NSObject* o = [self object:dict valueForKeyPath:token context:context];
	if (o) {
		if ([o isKindOfClass:[NSString class]])
			return (NSString*)o;
		// if ([o isKindOfClass:[NSDate class]]) // TODO: other..?
		
		return o.description;
	}
	
	return @"";
}

+(void)mutableString:(NSMutableString*)string evaluateTokensWithDictionary:(NSDictionary*)localtokens context:(id)context {
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
			NSMutableDictionary* dict = [[localtokens mutableCopy] autorelease];
			
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
			NSString* evaldStr = [self evaluateToken:tokenStr withDictionary:dict context:context mustReevaluate:&mustReevaluate];
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

-(NSObject*)valueForKey:(NSString*)key context:(id)context {
	for (WebPortalProxyObjectTransformer* t in transformers)
		@try {
			id r = [t valueForKey:key object:object context:context];
			if (r) return r;
		} @catch (NSException * e) {
		}
	
	return [object valueForKey:key];
}

@end


@implementation WebPortalProxyObjectTransformer : NSObject

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSObject*)o context:(WebPortalConnection*)wpc {

	if ([o isKindOfClass:NSManagedObject.class] && [key isEqual:@"isSelected"]) {
		NSString* xid = ((NSManagedObject*)o).XID;
		for (NSString* selectedID in [WebPortalConnection MakeArray:[wpc.parameters objectForKey:@"selected"]])
			if ([selectedID isEqualToString:xid])
				return [NSNumber numberWithBool:YES];
		return [NSNumber numberWithBool:NO];
	}
	
	return NULL;
}


@end


@implementation InfoTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(WebPortalConnection*)wpc context:(WebPortalConnection*)wpcagain {
	if ([key isEqual:@"isIOS"])
		return [NSNumber numberWithBool:wpc.requestIsIOS];
	if ([key isEqual:@"isMacOS"])
		return [NSNumber numberWithBool:wpc.requestIsMacOS];
	if ([key isEqual:@"proposeWeasis"])
		return [NSNumber numberWithBool: wpc.portal.weasisEnabled && !wpc.requestIsIOS ];
	if ([key isEqual:@"proposeFlash"])
		return [NSNumber numberWithBool: wpc.portal.flashEnabled && !wpc.requestIsIOS ];
	if ([key isEqual:@"authenticationRequired"])
		return [NSNumber numberWithBool: wpc.portal.authenticationRequired && !wpc.user ];
	if ([key isEqual:@"newToken"])
		return [wpc.session createToken];
	if ([key isEqual:@"passwordRestoreAllowed"])
		return [NSNumber numberWithBool: wpc.portal.passwordRestoreAllowed ];
	if ([key isEqual:@"baseUrl"])
		return wpc.portalURL;
	if ([key isEqual:@"dicomCStorePort"])
		return wpc.dicomCStorePortString;
	if ([key isEqual:@"newChallenge"])
		return [wpc.session newChallenge];
	if ([key isEqual:@"proposeDicomUpload"])
		return [NSNumber numberWithBool: (!wpc.user || wpc.user.uploadDICOM.boolValue) && !wpc.requestIsIOS ];
	if ([key isEqual:@"proposeDicomSend"]) {
		return [NSNumber numberWithBool: ((!wpc.user || wpc.user.sendDICOMtoSelfIP.boolValue) && !wpc.requestIsIOS) || (wpc.user.sendDICOMtoAnyNodes.boolValue /* TODO: && destinations.count */)]; 
	}
	if ([key isEqual:@"proposeZipDownload"])
		return [NSNumber numberWithBool: (!wpc.user || wpc.user.downloadZIP.boolValue) && !wpc.requestIsIOS ];
	
	if ([key isEqual:@"proposeShare"])
		if (!wpc.user || wpc.user.shareStudyWithUser.boolValue) {
			NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
			req.entity = [wpc.portal.database entityForName:@"User"];
			req.predicate = [NSPredicate predicateWithValue:YES];
			return [NSNumber numberWithBool: [wpc.portal.database.managedObjectContext countForFetchRequest:req error:NULL] > (wpc.user? 1 : 0) ];
		} else
			return [NSNumber numberWithBool:NO];
	
	if ([key hasPrefix:@"getParameters"] || [key hasPrefix:@"allParameters"]) {
		NSString* rest = [key substringFromIndex:13];
		if (rest.length && [rest characterAtIndex:0] == '(' && [rest characterAtIndex:rest.length-1] == ')') {
			rest = [rest substringWithRange:NSMakeRange(1,rest.length-2)];
			NSMutableDictionary* vars = NULL;
			if ([key hasPrefix:@"getParameters"])
				vars = [[[WebPortalConnection ExtractParams:wpc.GETParams] mutableCopy] autorelease];
			if ([key hasPrefix:@"allParameters"])
				vars = [[wpc.parameters mutableCopy] autorelease];
			
			for (rest in [rest componentsSeparatedByString:@","]) {
				NSArray* set = [rest componentsSeparatedByString:@"="];
				if (set.count == 2) {
					if ([[set objectAtIndex:1] length])
						[vars setObject:[set objectAtIndex:1] forKey:[set objectAtIndex:0]];
					else [vars removeObjectForKey:[set objectAtIndex:0]];
				}
			}
			
			return [WebPortalConnection FormatParams:vars];
		}
		
		if ([key hasPrefix:@"getParameters"])
			return wpc.GETParams;
		if ([key hasPrefix:@"allParameters"])
			return [WebPortalConnection FormatParams:wpc.parameters];
	}
	
	return [super valueForKey:key object:wpc context:wpcagain];
}

@end


@implementation WebPortalUserTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(WebPortalUser*)user context:(WebPortalConnection*)wpc {
	if ([key isEqual:@"originalName"])
		return user.name;
	
	return [super valueForKey:key object:user context:wpc];
}

@end


@implementation StringTransformer

NSString* iPhoneCompatibleNumericalFormat(NSString* aString) { // this is to avoid numbers to be interpreted as phone numbers
	NSMutableString* newString = [NSMutableString string];
	for (int i = 0; i < aString.length; ++i) {
		[newString appendString:@"<span>"];
		[newString appendString:[[aString substringWithRange:NSMakeRange(i,1)] xmlEscapedString]];
		[newString appendString:@"</span>"];
	}
	return newString;
}

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSString*)object context:(WebPortalConnection*)wpc {
	if ([key isEqual:@"Spanned"])
		return iPhoneCompatibleNumericalFormat(object);
	
	return [super valueForKey:key object:object context:wpc];
}

@end


/*@implementation ArrayTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSArray*)object context:(WebPortalConnection*)wpc {
//	if ([key isEqual:@"count"])
//		NSLog();
	//	return [NSNumber numberWithUnsignedInt:object.count];
	
	return [super valueForKey:key object:object context:wpc];
}

@end


@implementation SetTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSSet*)object context:(WebPortalConnection*)wpc {
	//if ([key isEqual:@"count"])
	//	return [NSNumber numberWithUnsignedInt:object.count];
	
	return [super valueForKey:key object:object context:wpc];
}

@end*/


@implementation DateTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSDate*)object context:(WebPortalConnection*)wpc {
	if ([key isEqual:@"DateTime"]) {
		return [NSUserDefaults.dateTimeFormatter stringFromDate:object];
	}
	
	if ([key isEqual:@"Date"]) {
		return [NSUserDefaults.dateFormatter stringFromDate:object];
	}
	
	if ([key isEqual:@"Months"]) {
		static NSArray* monthNames = [[NSArray alloc] initWithObjects: NSLocalizedString(@"January", @"Month"), NSLocalizedString(@"February", @"Month"), NSLocalizedString(@"March", @"Month"), NSLocalizedString(@"April", @"Month"), NSLocalizedString(@"May", @"Month"), NSLocalizedString(@"June", @"Month"), NSLocalizedString(@"July", @"Month"), NSLocalizedString(@"August", @"Month"), NSLocalizedString(@"September", @"Month"), NSLocalizedString(@"October", @"Month"), NSLocalizedString(@"November", @"Month"), NSLocalizedString(@"December", @"Month"), NULL];
		NSMutableArray* months = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		if (!object)
			[months addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:-1], @"value", NSLocalizedString(@"Month", @"Month"), @"name", [NSNumber numberWithBool:YES], @"selected", [NSNumber numberWithBool:YES], @"disabled", NULL]];
		for (NSUInteger i = 0; i < 12; ++i)
			[months addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i], @"value", [monthNames objectAtIndex:i], @"name", [NSNumber numberWithBool: [calDate monthOfYear] == i+1 ], @"selected", NULL]];
		return months;
	}
	
	if ([key isEqual:@"Days"]) {
		NSMutableArray* days = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		if (!object)
			[days addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"value", NSLocalizedString(@"Day", @"Day"), @"name", [NSNumber numberWithBool:YES], @"selected", [NSNumber numberWithBool:YES], @"disabled", NULL]];
		for (NSUInteger i = 0; i < 31; ++i)
			[days addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i+1], @"value", [NSNumber numberWithInt:i+1], @"name", [NSNumber numberWithBool: [calDate dayOfMonth] == i+1 ], @"selected", NULL]];
		return days;
	}
	
	const NSUInteger NextYears = 5;
	if ([key isEqual:@"NextYears"]) {
		NSMutableArray* years = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		NSCalendarDate* currDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[NSDate timeIntervalSinceReferenceDate]];
		if ([calDate yearOfCommonEra] < [currDate yearOfCommonEra])
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"value", [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"name", [NSNumber numberWithBool:YES], @"selected", NULL]];
		for (NSUInteger i = [currDate yearOfCommonEra]; i < [currDate yearOfCommonEra]+NextYears; ++i)
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i], @"value", [NSNumber numberWithInt:i], @"name", [NSNumber numberWithBool: [calDate yearOfCommonEra] == i ], @"selected", NULL]];
		if ([calDate yearOfCommonEra] >= [currDate yearOfCommonEra]+NextYears)
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"value", [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"name", [NSNumber numberWithBool:YES], @"selected", NULL]];
		return years;
	}
	
	return [super valueForKey:key object:object context:wpc];
}

@end


@implementation DicomStudyTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(DicomStudy*)study context:(WebPortalConnection*)wpc {
	
	if ([key isEqual:@"reportIsLink"]) {
		return [NSNumber numberWithBool: [study.reportURL hasPrefix:@"http://"] || [study.reportURL hasPrefix:@"https://"] ];
	}
	
	if ([key isEqual:@"reportExtension"]) {
		BOOL isDir = NO;
		[NSFileManager.defaultManager fileExistsAtPath:study.reportURL isDirectory:&isDir];
		return isDir? @"zip" : study.reportURL.pathExtension;
	}
	
	if ([key isEqual:@"stateText"]) {
		if (!study.stateText.intValue)
			return NULL;
		return [BrowserController.statesArray objectAtIndex:study.stateText.intValue];
	}
	
	return [super valueForKey:key object:study context:wpc];
}

@end


@implementation DicomSeriesTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)init {
	self = [super init];
	size = NSMakeSize(-1,-1);
	return self;
}

-(id)valueForKey:(NSString*)key object:(DicomSeries*)series context:(WebPortalConnection*)wpc {
	if ([key isEqual:@"seriesExtension"]) {
		if ([DCMAbstractSyntaxUID isPDF:series.seriesSOPClassUID] || [DCMAbstractSyntaxUID isStructuredReport:series.seriesSOPClassUID])
			return @".pdf";
		return @"";
	}
	
	if ([key isEqual:@"stateText"]) {
		if (series.stateText.intValue)
			return [[BrowserController statesArray] objectAtIndex:series.stateText.intValue];
		return NULL;
	}
	
	/*if ([key isEqual:@"noFiles"]) {
		return [NSNumber numberWithInt:[[series performSelector:@selector(noFiles)] intValue]];
	}*/

	if ([key isEqual:@"width"] || [key isEqual:@"height"]) {
		if (size.height == -1) {
			NSArray* images = [series.images allObjects];
			
			if (images.count > 1) {
				if (wpc.requestIsIPhone)
					[wpc getWidth:&size.width height:&size.height fromImagesArray:images minSize:NSMakeSize(256) maxSize:NSMakeSize(290)];
				else {
					[wpc getWidth:&size.width height:&size.height fromImagesArray:images];
					if (!wpc.requestIsIOS)
						size.height += 15; // controller height (quicktime, flash)
				}
			} else {
				[wpc getWidth:&size.width height:&size.height fromImagesArray:images];
			}

		}
		if ([key isEqual:@"width"])
			return [NSNumber numberWithInt:size.width];
		if ([key isEqual:@"height"])
			return [NSNumber numberWithInt:size.height];
	}
	
	return [super valueForKey:key object:series context:wpc];
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




@implementation NSMutableDictionary (WebPortalProxy)

static const NSString* const MessagesArrayTokenKey = @"Messages";
static const NSString* const ErrorsArrayTokenKey = @"Errors";

-(NSMutableArray*)errors {
	NSMutableArray* errors = [self objectForKey:ErrorsArrayTokenKey];
	if (![errors isKindOfClass:[NSMutableArray class]]) {
		errors = [NSMutableArray array];
		[self setObject:errors forKey:ErrorsArrayTokenKey];
	}
	
	return errors;
}

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

@end
