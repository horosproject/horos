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
#import "QueryController.h"
#import "AsyncSocket.h"
#import "N2Debug.h"

static NSString *WebPortalResponseLock = @"WebPortalResponseLock";

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
	
    @synchronized( WebPortalResponseLock)
    {
        
        /*if ([part0 isEqualToString:@"Defaults"]) {
            o = [NSUserDefaultsController sharedUserDefaultsController];
            keyPath = [[parts subarrayWithRange:NSMakeRange(1,(long)parts.count-1)] componentsJoinedByString:@"."];
        }*/

        if ([o isKindOfClass: [NSString class]])
            return [self object:[WebPortalProxy createWithObject:o transformer:[StringTransformer create]] valueForKeyPath:keyPath context:context];
        if ([o isKindOfClass: [NSDate class]])
            return [self object:[WebPortalProxy createWithObject:o transformer:[DateTransformer create]] valueForKeyPath:keyPath context:context];
    //	if ([o isKindOfClass:NSArray.class])
    //		return [self object:[WebPortalProxy createWithObject:o transformer:[ArrayTransformer create]] valueForKeyPath:keyPath context:context];
    //	if ([o isKindOfClass:NSSet.class])
    //		return [self object:[WebPortalProxy createWithObject:o transformer:[SetTransformer create]] valueForKeyPath:keyPath context:context];
        if ([o isKindOfClass: [WebPortalUser class]])
            return [self object:[WebPortalProxy createWithObject:o transformer:[WebPortalUserTransformer create]] valueForKeyPath:keyPath context:context];
        if ([o isKindOfClass: [DicomStudy class]])
            return [self object:[WebPortalProxy createWithObject:o transformer:[DicomStudyTransformer create]] valueForKeyPath:keyPath context:context];
        if ([o isKindOfClass: [DicomSeries class]])
            return [self object:[WebPortalProxy createWithObject:o transformer:[DicomSeriesTransformer create]] valueForKeyPath:keyPath context:context];
        
        if ([o isKindOfClass: [NSManagedObject class]])
            return [self object:[WebPortalProxy createWithObject:o transformer:[WebPortalProxyObjectTransformer create]] valueForKeyPath:keyPath context:context];

        /*@try {
            id value = [o valueForKeyPath:keyPath];
            if (value)
                return value;
        } @catch (NSException* e) {
        }*/
        
        @try {
            id value = NULL;
            if ([o isKindOfClass: [WebPortalProxy class]])
                value = [o valueForKey:part0 context:context];
            else {
                if ([o isKindOfClass: [NSArray class]] || [o isKindOfClass: [NSSet class]])
                    part0 = [@"@" stringByAppendingString:part0];
                value = [o valueForKey:part0];
            }
            if (parts.count > 1)
                return [self object:value valueForKeyPath:[[parts subarrayWithRange:NSMakeRange(1,(long)parts.count-1)] componentsJoinedByString:@"."] context:context];
            return value;
        } @catch (NSException* e) {
            NSLog(@"***** [WebPortalRosponse object:valueForKeyPath:context] %@", e);
        }
    }
    
	return NULL;
}

+(NSString*)evaluateToken:(NSString*)tokenStr withDictionary:(NSDictionary*)dict context:(id)context mustReevaluate:(BOOL*)mustReevaluate {
	// # separates the actual token from extra chars that can be used as comments or as marker for otherwise equal tokens
	NSArray* tokenStrParts = [tokenStr componentsSeparatedByString:@"#"];
	NSString* token = [tokenStrParts objectAtIndex:0];
	NSString* tokenStrExtras = tokenStrParts.count>1? [NSString stringWithFormat:@"#%@", [[tokenStrParts subarrayWithRange:NSMakeRange(1,(long)tokenStrParts.count-1)] componentsJoinedByString:@"#"]] : @"";
	
	NSArray* parts = [token componentsSeparatedByString:@":"];
	NSString* part0 = [parts objectAtIndex:0];
	
	// is it a command?
	
//	NSLog(@"Evaluating %@ with %@", tokenStr, dict.description);
	
	if ([part0 isEqualToString:@"FOREACH"]) {
		NSString* arrayName = [parts objectAtIndex:1];
		NSString* iName = [parts objectAtIndex:2];
		
		NSString* body = [dict objectForKey:[token stringByAppendingString:@":Body"]];
		
		NSMutableString* ret = [NSMutableString string];
		
		NSMutableDictionary* idict = [[dict mutableCopy] autorelease];
		NSInteger c = 0;
		id array = [self object:dict valueForKeyPath:arrayName context:context];
		if ([array isKindOfClass: [NSSet class]])
			array = [array allObjects];
		for (id i in array) {
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
	
	if ([part0 isEqualToString:@"IF"]) {
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
						if ([vl isKindOfClass:[NSString class]] || [vl isKindOfClass:[NSNumber class]]) {
							NSComparisonResult cr = [(NSNumber*)vl compare:(NSNumber*)vr];
							NSString* op = [condition substringWithRange:NSMakeRange(sl.length, condition.length-sl.length-sr.length)];
							
							if ([op isEqualToString:@"=="])
								satisfied = cr==NSOrderedSame;
							if ([op isEqualToString:@"<"])
								satisfied = cr==NSOrderedAscending;
							if ([op isEqualToString:@">"])
								satisfied = cr==NSOrderedDescending;
							if ([op isEqualToString:@">="])
								satisfied = cr!=NSOrderedAscending;
							if ([op isEqualToString:@"<="])
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
	
	if ([part0 isEqualToString:@"URLENC"] || [part0 isEqualToString:@"U"]) {
		token = [[parts subarrayWithRange:NSMakeRange(1,(long)parts.count-1)] componentsJoinedByString:@":"];
		NSString* str = [self evaluateToken:token withDictionary:dict context:context mustReevaluate:mustReevaluate];
		return [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[str mutableCopy] autorelease], NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), kCFStringEncodingUTF8) autorelease];
	}
	
	if ([part0 isEqualToString:@"XMLENC"] || [part0 isEqualToString:@"X"]) {
		NSUInteger from = 1;
		
		NSString* part1 = NULL;
		if (parts.count >= 3)
			part1 = [parts objectAtIndex:1];
		
		if ([part1 isEqualToString:@"ZWS"])
			++from;
		
		token = [[parts subarrayWithRange:NSMakeRange(from,(long)parts.count-from)] componentsJoinedByString:@":"];
		NSString* evaldToken = [self evaluateToken:token withDictionary:dict context:context mustReevaluate:mustReevaluate];
		
		if ([part1 isEqualToString:@"ZWS"])
			evaldToken = [[evaldToken componentsWithLength:1] componentsJoinedByString:[NSString stringWithFormat:@"%C", (unsigned short)0x200b]];
		
		return [evaldToken xmlEscapedString];
	}
    
    if ([part0 isEqualToString:@"LOCNUM"])
    {
        token = [[parts subarrayWithRange:NSMakeRange(1,(long)parts.count-1)] componentsJoinedByString:@":"];
        NSObject* o = [self object:dict valueForKeyPath:token context:context];
        if (o)
        {
            if ([o isKindOfClass:[NSNumber class]] == NO)
                o = [NSNumber numberWithFloat: [o.description floatValue]];
            
            return [NSNumberFormatter localizedStringFromNumber: (NSNumber*) o numberStyle: NSNumberFormatterDecimalStyle];
        }
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
                else NSLog( @"***** WebPortal: syntax error : no closing for: %@", tokenCloser);
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

-(NSObject*)valueForKey:(NSString*)key context:(id)context
{
    @synchronized( WebPortalResponseLock)
    {
        for (WebPortalProxyObjectTransformer* t in transformers)
            @try {
			id r = [t valueForKey:key object:object context:context];
			if (r) return r;
            } @catch (NSException * e) {
            }
	}
	return [object valueForKey:key];
}

@end


@implementation WebPortalProxyObjectTransformer : NSObject

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSObject*)o context:(WebPortalConnection*)wpc {

	if ([o isKindOfClass: [NSManagedObject class]] && [key isEqualToString:@"isSelected"]) {
		NSString* xid = ((NSManagedObject*)o).XID;
		for (NSString* selectedID in [WebPortalConnection MakeArray:[wpc.parameters objectForKey:@"selected"]])
			if ([selectedID isEqualToString:xid])
				return @YES;
		return @NO;
	}
	
	return NULL;
}


@end


@implementation InfoTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(WebPortalConnection*)wpc context:(WebPortalConnection*)wpcagain {
	if ([key isEqualToString:@"isIOS"])
		return [NSNumber numberWithBool: wpc.requestIsIOS];
	if ([key isEqualToString:@"isMacOS"])
		return [NSNumber numberWithBool: wpc.requestIsMacOS];
	if ([key isEqualToString:@"proposeWeasis"])
		return [NSNumber numberWithBool: wpc.portal.weasisEnabled && !wpc.requestIsIOS];
	if ([key isEqualToString:@"proposeFlash"])
		return [NSNumber numberWithBool: wpc.portal.flashEnabled && !wpc.requestIsIOS];
	if ([key isEqualToString:@"authenticationRequired"])
		return [NSNumber numberWithBool: wpc.portal.authenticationRequired && !wpc.user];
	if ([key isEqualToString:@"newToken"])
		return [wpc.session createToken];
	if ([key isEqualToString:@"passwordRestoreAllowed"])
		return [NSNumber numberWithBool: wpc.portal.passwordRestoreAllowed];
	if ([key isEqualToString:@"baseUrl"])
		return wpc.portalURL;
    if ([key isEqualToString:@"clientAddress"])
		return wpc.asyncSocket.connectedHost;
    if ([key isEqualToString:@"isLAN"])
	{
        if( [wpc.asyncSocket.connectedHost hasPrefix: @"10."]) return @YES;
        if( [wpc.asyncSocket.connectedHost hasPrefix: @"172."]) return @NO;
        if( [wpc.asyncSocket.connectedHost hasPrefix: @"192."]) return @YES;
        if( [wpc.asyncSocket.connectedHost hasPrefix: @"127.0.0.1"]) return @YES;
        
        return @NO;
    }
	if ([key isEqualToString:@"dicomCStorePort"])
		return wpc.dicomCStorePortString;
	if ([key isEqualToString:@"newChallenge"])
		return [wpc.session newChallenge];
    if ([key isEqualToString:@"proposeReport"])
    {
        if( wpc.portal.authenticationRequired && !wpc.user) return @NO;
        return [NSNumber numberWithBool: !wpc.user || wpc.user.downloadReport.boolValue];
    }
	if ([key isEqualToString:@"proposeDicomUpload"])
    {
        if( wpc.portal.authenticationRequired && !wpc.user) return @NO;
		return [NSNumber numberWithBool: (!wpc.user || wpc.user.uploadDICOM.boolValue) && !wpc.requestIsIOS];
	}
    if ([key isEqualToString:@"proposeDicomSend"])
    {
        if( wpc.portal.authenticationRequired && !wpc.user) return @NO;
		return [NSNumber numberWithBool: !wpc.user || wpc.user.sendDICOMtoSelfIP.boolValue || (wpc.user.sendDICOMtoAnyNodes.boolValue)];
    }
	if ([key isEqualToString:@"proposeWADORetrieve"])
		return [NSNumber numberWithBool: wpc.portal.weasisEnabled]; 
	if ([key isEqualToString:@"WADOBaseURL"])
	{
//		NSString *protocol = [[NSUserDefaults standardUserDefaults] boolForKey:@"encryptedWebServer"] ? @"https" : @"http";
		NSString *wadoSubUrl = @"wado"; // See Web Server Preferences
		
		if( [wadoSubUrl hasPrefix: @"/"])
			wadoSubUrl = [wadoSubUrl substringFromIndex: 1];
		
		NSString *baseURL = [NSString stringWithFormat: @"%@/%@", wpc.portalURL, wadoSubUrl];
		
		return baseURL; 
	}
    
	if ([key isEqualToString:@"proposeZipDownload"])
    {
        if( wpc.portal.authenticationRequired && !wpc.user) return @NO;
		return [NSNumber numberWithBool: (!wpc.user || wpc.user.downloadZIP.boolValue) && !wpc.requestIsIOS];
	}
    if ([key isEqualToString:@"proposeDelete"])
		return [NSNumber numberWithBool: ([[NSUserDefaults standardUserDefaults] boolForKey:@"webPortalAdminCanDeleteStudies"] && wpc.user.isAdmin.boolValue)];
    
	if ([key isEqualToString:@"proposeShare"])
    {
        if( wpc.portal.authenticationRequired && !wpc.user) return @NO;
        
		if (!wpc.user || wpc.user.shareStudyWithUser.boolValue)
        {
            WebPortalDatabase *idatabase = [wpc.portal.database independentDatabase];
            
			NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
			req.entity = [idatabase entityForName:@"User"];
			req.predicate = [NSPredicate predicateWithValue:YES];
            
            NSNumber *result = @NO;
            [idatabase.managedObjectContext lock];
            @try {
                result = [NSNumber numberWithBool: [idatabase.managedObjectContext countForFetchRequest:req error:NULL] > (wpc.user? 1 : 0) ];
            }
            @catch (NSException *e) {
                NSLog(@"***** [WebPortalRosponse object:valueForKeyPath:context] %@", e);
            }
            @finally {
                [idatabase.managedObjectContext unlock];
            }
			return result;
		} else
			return @NO;
	}
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
	if ([key isEqualToString:@"originalName"])
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
	if ([key isEqualToString:@"Spanned"])
		return iPhoneCompatibleNumericalFormat(object);
	
	return [super valueForKey:key object:object context:wpc];
}

@end


/*@implementation ArrayTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSArray*)object context:(WebPortalConnection*)wpc {
//	if ([key isEqualToString:@"count"])
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
	//if ([key isEqualToString:@"count"])
	//	return [NSNumber numberWithUnsignedInt:object.count];
	
	return [super valueForKey:key object:object context:wpc];
}

@end*/


@implementation DateTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSDate*)object context:(WebPortalConnection*)wpc {
	if ([key isEqualToString:@"DateTime"]) {
		return [NSUserDefaults.dateTimeFormatter stringFromDate:object];
	}
	
	if ([key isEqualToString:@"Date"]) {
		return [NSUserDefaults.dateFormatter stringFromDate:object];
	}
	
	if ([key isEqualToString:@"Months"]) {
		static NSArray* monthNames = [[NSArray alloc] initWithObjects: NSLocalizedString(@"January", @"Month"), NSLocalizedString(@"February", @"Month"), NSLocalizedString(@"March", @"Month"), NSLocalizedString(@"April", @"Month"), NSLocalizedString(@"May", @"Month"), NSLocalizedString(@"June", @"Month"), NSLocalizedString(@"July", @"Month"), NSLocalizedString(@"August", @"Month"), NSLocalizedString(@"September", @"Month"), NSLocalizedString(@"October", @"Month"), NSLocalizedString(@"November", @"Month"), NSLocalizedString(@"December", @"Month"), NULL];
		NSMutableArray* months = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		if (!object)
			[months addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:-1], @"value", NSLocalizedString(@"Month", @"Month"), @"name", @YES, @"selected", @YES, @"disabled", NULL]];
		for (NSUInteger i = 0; i < 12; ++i)
			[months addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i], @"value", [monthNames objectAtIndex:i], @"name", [NSNumber numberWithBool: [calDate monthOfYear] == i+1 ], @"selected", NULL]];
		return months;
	}
	
	if ([key isEqualToString:@"Days"]) {
		NSMutableArray* days = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		if (!object)
			[days addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"value", NSLocalizedString(@"Day", @"Day"), @"name", @YES, @"selected", @YES, @"disabled", NULL]];
		for (NSUInteger i = 0; i < 31; ++i)
			[days addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i+1], @"value", [NSNumber numberWithInt:i+1], @"name", [NSNumber numberWithBool: [calDate dayOfMonth] == i+1 ], @"selected", NULL]];
		return days;
	}
	
	const NSUInteger NextYears = 5;
	if ([key isEqualToString:@"NextYears"]) {
		NSMutableArray* years = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		NSCalendarDate* currDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[NSDate timeIntervalSinceReferenceDate]];
		if ([calDate yearOfCommonEra] < [currDate yearOfCommonEra])
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"value", [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"name", @YES, @"selected", NULL]];
		for (NSUInteger i = [currDate yearOfCommonEra]; i < [currDate yearOfCommonEra]+NextYears; ++i)
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i], @"value", [NSNumber numberWithInt:i], @"name", [NSNumber numberWithBool: [calDate yearOfCommonEra] == i ], @"selected", NULL]];
		if ([calDate yearOfCommonEra] >= [currDate yearOfCommonEra]+NextYears)
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"value", [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"name", @YES, @"selected", NULL]];
		return years;
	}
	
	return [super valueForKey:key object:object context:wpc];
}

@end


static NSMutableDictionary *otherStudiesForThisPatientCache = nil;

@implementation DicomStudyTransformer

+ (void) clearOtherStudiesForThisPatientCache
{
    @synchronized( otherStudiesForThisPatientCache)
    {
        [otherStudiesForThisPatientCache removeAllObjects];
    }
}

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(DicomStudy*)study context:(WebPortalConnection*)wpc
{
    if ([key isEqualToString:@"hasKeyImagesOrROIImages"])
	{
        if( [[study keyImages] count])
            return @YES;
        
        if( [[study roiImages] count])
            return @YES;
        
        return @NO;
    }
    
	if ([key isEqualToString:@"reportIsLink"])
    {
		return [NSNumber numberWithBool: [study.reportURL hasPrefix:@"http://"] || [study.reportURL hasPrefix:@"https://"] ];
	}
	
	if ([key isEqualToString:@"otherStudiesForThisPatient"])
	{
		NSMutableArray *otherStudies = nil;
		
        @try
        {
            // Cache system for comparative studies, if PACS On Demand is activated
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"ActivatePACSOnDemandForWebPortalOtherStudies"])
            {
                if( otherStudiesForThisPatientCache == nil)
                    otherStudiesForThisPatientCache = [[NSMutableDictionary alloc] init];
                
                #define CACHETIMEOUT -30
                @synchronized( otherStudiesForThisPatientCache)
                {
                    // REMOVE OLD KEYS
                    NSMutableArray *keysToRemove = [NSMutableArray array];
                    for( NSString *key in otherStudiesForThisPatientCache)
                    {
                        if( [[[otherStudiesForThisPatientCache objectForKey: key] objectForKey: @"timeStamp"] timeIntervalSinceNow] < CACHETIMEOUT)
                            [keysToRemove addObject: key];
                    }
                    if( keysToRemove.count)
                        [otherStudiesForThisPatientCache removeObjectsForKeys: keysToRemove];
                    
                    if( [otherStudiesForThisPatientCache objectForKey: study.patientID])
                    {
                        NSDictionary *d = [otherStudiesForThisPatientCache objectForKey: study.patientID];
                        NSDate *timeStamp = [d objectForKey: @"timeStamp"];
                        
                        if( [timeStamp timeIntervalSinceNow] > CACHETIMEOUT)
                        {
                            DicomDatabase *db = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
                            otherStudies = [NSMutableArray arrayWithArray: [db objectsWithIDs: [d objectForKey: @"studyIDs"]]];
                        }
                    }
                }
            }
        }
        @catch (NSException *exception) {
            N2LogExceptionWithStackTrace( exception);
        }
        
        if( otherStudies == nil)
        {
            @try
            {
                otherStudies = [[[WebPortalUser studiesForUser: wpc.user predicate: [NSPredicate predicateWithFormat: @"(patientID == %@)", study.patientID] sortBy: @"date"] mutableCopy] autorelease];
                
                // PACS On Demand
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"ActivatePACSOnDemandForWebPortalOtherStudies"])
                {
                    BOOL usePatientID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientIDForUID"];
                    BOOL usePatientBirthDate = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientBirthDateForUID"];
                    BOOL usePatientName = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientNameForUID"];
                    
                    // Servers
                    NSArray *servers = [BrowserController comparativeServers];
                    
                    if( servers.count)
                    {
                        // Distant studies
    #ifndef OSIRIX_LIGHT
                        NSArray *distantStudies = [QueryController queryStudiesForPatient: study usePatientID: usePatientID usePatientName: usePatientName usePatientBirthDate: usePatientBirthDate servers: servers showErrors: NO];
                        
                        // Merge local and distant studies
                        for( DCMTKStudyQueryNode *distantStudy in distantStudies)
                        {
                            if( [[otherStudies valueForKey: @"studyInstanceUID"] containsObject: [distantStudy studyInstanceUID]] == NO && [[distantStudy noFiles] integerValue] > 0)
                            {
                                [otherStudies addObject: distantStudy];
                            }
                            else if( [[NSUserDefaults standardUserDefaults] boolForKey: @"preferStudyWithMoreImages"])
                            {
                                NSUInteger index = [[otherStudies valueForKey: @"studyInstanceUID"] indexOfObject: [distantStudy studyInstanceUID]];
                                
                                if( index != NSNotFound && [[[otherStudies objectAtIndex: index] rawNoFiles] intValue] < [[distantStudy noFiles] intValue])
                                {
                                    [otherStudies replaceObjectAtIndex: index withObject: distantStudy];
                                }
                            }
                        }
    #endif
                    }
                }
            }
            @catch (NSException * e)
            {
                NSLog(@"***** [WebPortalRosponse object:valueForKeyPath:context] %@", e);
            }
            
            [otherStudies sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"date" ascending: NO]]];
        }
        // Cache system for comparative studies, if PACS On Demand is activated
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"ActivatePACSOnDemandForWebPortalOtherStudies"])
        {
            if( otherStudiesForThisPatientCache == nil)
                otherStudiesForThisPatientCache = [[NSMutableDictionary alloc] init];
            
            @synchronized( otherStudiesForThisPatientCache)
            {
                NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], @"timeStamp", [otherStudies valueForKey: @"objectID"], @"studyIDs", nil];
                [otherStudiesForThisPatientCache setObject: d forKey:study.patientID];
            }
        }
        
		return otherStudies;
	}
	
	if ([key isEqualToString:@"reportExtension"]) {
		BOOL isDir = NO;
		[NSFileManager.defaultManager fileExistsAtPath:study.reportURL isDirectory:&isDir];
		return isDir? @"zip" : study.reportURL.pathExtension;
	}
	
	if ([key isEqualToString:@"stateText"]) {
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
	if ([key isEqualToString:@"seriesExtension"]) {
		if ([DCMAbstractSyntaxUID isPDF:series.seriesSOPClassUID] || [DCMAbstractSyntaxUID isStructuredReport:series.seriesSOPClassUID])
			return @".pdf";
		return @"";
	}
	
	if ([key isEqualToString:@"stateText"]) {
		if (series.stateText.intValue)
			return [[BrowserController statesArray] objectAtIndex:series.stateText.intValue];
		return NULL;
	}
	
	/*if ([key isEqualToString:@"noFiles"]) {
		return [NSNumber numberWithInt:[[series performSelector:@selector(noFiles)] intValue]];
	}*/

	if ([key isEqualToString:@"width"] || [key isEqualToString:@"height"]) {
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
		if ([key isEqualToString:@"width"])
			return [NSNumber numberWithInt:size.width];
		if ([key isEqualToString:@"height"])
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
