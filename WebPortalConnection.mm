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

#import "WebPortalConnection.h"
#import "WebPortalSession.h"
#import "WebPortalData.h"
#import "WebPortalPages.h"

#import "AsyncSocket.h"
#import "DDKeychain.h"
#import "BrowserController.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "DicomImage.h"
#import "DCMTKStoreSCU.h"
#import "DCMPix.h"
#import <QTKit/QTKit.h>
#import "DCMNetServiceDelegate.h"
#import "AppController.h"
#import "BrowserControllerDCMTKCategory.h"
#import "DCM.h"
#import "HTTPResponse.h"
#import "HTTPAuthenticationRequest.h"
#import "CSMailMailClient.h"
#import "WebPortalUser.h"
#import "DicomFile.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "N2Debug.h"
#import "NSString+N2.h"
#import "NSUserDefaultsController+N2.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "NSString+N2.h"
#import "DDData.h"
#import "NSData+N2.h"
#import "NSMutableString+N2.h"
#import "NSImage+N2.h"
#import "NSMutableDictionary+N2.h"
#import "DicomAlbum.h"

#import "JSON.h"

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define INCOMINGPATH @"/INCOMING.noindex/"

static NSMutableDictionary *movieLock = nil;
static NSMutableDictionary *wadoJPEGCache = nil;
static NSMutableDictionary *thumbnailCache = nil;

#define minResolution 400
#define maxResolution 800
#define WADOCACHESIZE 2000
#define THUMBNAILCACHE 20

NSString* NotNil(NSString *s) {
	return s? s : @"";
}

// make compiler aware of these methods' existance
@interface HTTPConnection ()
-(BOOL)isAuthenticated;
-(void)replyToHTTPRequest;
@end


NSString* const SessionCookieName = @"SID";

@interface WebPortalResponse : HTTPDataResponse {
	NSMutableDictionary* httpHeaders;
	NSUInteger httpStatusCode;
}

@property(retain) NSData* data;
@property NSUInteger httpStatusCode;
@property(readonly) NSMutableDictionary* httpHeaders;

-(id)init;
//-(id)initWithData:(NSData*)data mime:(NSString*)mime sessionId:(NSString*)sessionId __deprecated;

@end
@implementation WebPortalResponse

@synthesize data, httpHeaders, httpStatusCode;

-(id)init {
	self = [super initWithData:NULL];
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
	[super dealloc];
}

-(void)setSessionId:(NSString*)sessionId {
	[httpHeaders setObject:[NSString stringWithFormat:@"%@=%@; path=/", SessionCookieName, sessionId] forKey:@"Set-Cookie"];
}

-(void)setDataWithString:(NSString*)str {
	[self setData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

@end



@implementation WebPortalConnection

@synthesize session, currentUser;

NSString* const SessionChallengeKey = @"Challenge"; // NSString
NSString* const SessionDicomCStorePortKey = @"DicomCStorePort"; // NSNumber (int)

+(BOOL)IsSecureServer {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"encryptedWebServer"];
}

+(NSString*)WebServerAddress {
	NSString* webServerAddress = [[NSUserDefaults standardUserDefaults] valueForKey:@"webServerAddress"];
	if (!webServerAddress.length)
		webServerAddress = [[AppController sharedAppController] privateIP];
	return webServerAddress;
}

-(NSString*)webServerAddress {
	NSString* webServerAddress = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Host") autorelease];
	if (webServerAddress)
		webServerAddress = [[webServerAddress componentsSeparatedByString:@":"] objectAtIndex:0];
	else webServerAddress = WebPortalConnection.WebServerAddress;
	return webServerAddress;
}

+(NSString*)WebServerURLForAddress:(NSString*)webServerAddress {
	NSString* http = WebPortalConnection.IsSecureServer ? @"https":@"http";
	int webPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"httpWebServerPort"];
	return [NSString stringWithFormat: @"%@://%@:%d", http, webServerAddress, webPort];
}

+(NSString*)WebServerURL {
	return [self WebServerURLForAddress:self.WebServerAddress];
}

-(NSString*)webServerURL {
	return [WebPortalConnection WebServerURLForAddress:self.webServerAddress];
}

+(NSData*)WebServicesHTMLData:(NSString*)file {
	NSMutableArray* dirsToScanForFile = [NSMutableArray arrayWithCapacity:2];
	// did the user choose the WebServicesHTML in Library?
	if ([NSUserDefaultsController WebServerPrefersCustomWebPages]) [dirsToScanForFile addObject:@"~/Library/Application Support/OsiriX/WebServicesHTML"];
	[dirsToScanForFile addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WebServicesHTML"]];
	
	const NSString* const DefaultLanguage = @"English";
	BOOL isDirectory;
	
	for (NSInteger i = 0; i < dirsToScanForFile.count; ++i) {
		NSString* path = [dirsToScanForFile objectAtIndex:i];
		
		// path not on disk, ignore
		if (![[NSFileManager defaultManager] fileExistsAtPath:[path resolvedPathString] isDirectory:&isDirectory] || !isDirectory) {
			[dirsToScanForFile removeObjectAtIndex:i];
			--i; continue;
		}
		
		// path exists, look for a localized subdir first, otherwise in the dir itself
		
		for (NSString* lang in [[[NSBundle mainBundle] preferredLocalizations] arrayByAddingObject:DefaultLanguage]) {
			NSString* langPath = [path stringByAppendingPathComponent:lang];
			if ([[NSFileManager defaultManager] fileExistsAtPath:[langPath resolvedPathString] isDirectory:&isDirectory] && isDirectory) {
				[dirsToScanForFile insertObject:langPath atIndex:i];
				++i; break;
			}
		}
	}
	
	for (NSString* dirToScanForFile in dirsToScanForFile) {
		NSString* path = [dirToScanForFile stringByAppendingPathComponent:file];
		@try {
			NSData* data = [NSData dataWithContentsOfFile:[path resolvedPathString]];
			if (data) return data;
		} @catch (NSException* e) {
			// do nothing, just try next
		}
	}
	
//	NSLog( @"****** File not found: %@", file);
	
	return NULL;
}

+(NSString*)WebServicesHTMLString:(NSString*)file {
	NSData* data = [self WebServicesHTMLData:file];
	if (data) return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return NULL;
}

+(NSMutableString*)WebServicesHTMLMutableString:(NSString*)file {
	return [[[self WebServicesHTMLString:file] mutableCopy] autorelease];
}

-(int)guessDicomCStorePort
{
	DLog(@"Trying to guess DICOM C-Store Port...");
	
	for (NSDictionary *node in [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO])
	{
		NSString *dicomNodeAddress = NotNil([node objectForKey:@"Address"]);
		int dicomNodePort = [[node objectForKey:@"Port"] intValue];
		
		struct sockaddr_in service;
		const char	*host_name = [[node valueForKey:@"Address"] UTF8String];
		
		bzero((char *) &service, sizeof(service));
		service.sin_family = AF_INET;
		
		if (host_name)
		{
			if (isalpha(host_name[0]))
			{
				struct hostent* hp = gethostbyname(host_name);
				if (hp) bcopy(hp->h_addr, (char*)&service.sin_addr, hp->h_length);
				else service.sin_addr.s_addr = inet_addr(host_name);
			}
			else service.sin_addr.s_addr = inet_addr(host_name);
			
			char buffer[256];
			if (inet_ntop(AF_INET, &service.sin_addr, buffer, sizeof(buffer)))
			{
				if ([[NSString stringWithCString:buffer] isEqualToString:[asyncSocket connectedHost]]) // TODO: this may fail because of comparaisons between ipv6 and ipv4 addys
				{
					DLog( @"\tFound! %@:%d", [asyncSocket connectedHost], dicomNodePort);
					return dicomNodePort;
				}
			}
		}
	}
	
	DLog(@"\tNot found, will use 11112");
	return 11112;
}

-(NSString*)dicomCStorePortString {
	NSNumber* n = [session objectForKey:SessionDicomCStorePortKey];
	if (!n)
		[session setObject: n = [NSNumber numberWithInt:[self guessDicomCStorePort]] forKey:SessionDicomCStorePortKey];
	return [n stringValue];
}

+(NSString*)composePath:(NSString*)base with:(NSString*)rel {
	NSURL* baseurl = [NSURL URLWithString: [base characterAtIndex:0] == '/' ? base : [NSString stringWithFormat:@"/%@", base] ];
	NSURL* url = [NSURL URLWithString:rel relativeToURL:baseurl];
	return [base characterAtIndex:0] == '/' ? url.path : [url.path substringFromIndex:1];
}

-(NSMutableString*)webServicesHTMLMutableString:(NSString*)file {
	NSMutableString* html = [WebPortalConnection WebServicesHTMLMutableString:file];
	if (!html)
		NSLog(@"********* html == nil : webServicesHTMLMutableString:%@", file);

	NSRange range;
	while ((range = [html rangeOfString:@"%INCLUDE:"]).length) {
		NSRange rangeEnd = [html rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(range.location+range.length, html.length-(range.location+range.length))];
		NSString* replaceFilename = [html substringWithRange:NSMakeRange(range.location+range.length, rangeEnd.location-(range.location+range.length))];
		NSString* replaceFilepath = [WebPortalConnection composePath:file with:replaceFilename];
		[html replaceCharactersInRange:NSMakeRange(range.location, rangeEnd.location+rangeEnd.length-range.location) withString:NotNil([self webServicesHTMLMutableString:replaceFilepath])];
	}
	
	[WebPortalData mutableString:html block:@"userAccount" setVisible: currentUser? YES : NO];
	[WebPortalData mutableString:html block:@"IfAuthenticationRequired" setVisible: [[NSUserDefaults standardUserDefaults] boolForKey:@"passwordWebServer"] && !currentUser];
	[WebPortalData mutableString:html block:@"IfUserIsAdmin" setVisible: currentUser.isAdmin? YES : NO];

	if (currentUser) {			
		[html replaceOccurrencesOfString:@"%UserNameLabel%" withString:NotNil(currentUser.name)];
		[html replaceOccurrencesOfString:@"%UserEmailLabel%" withString:NotNil(currentUser.email)];
		[html replaceOccurrencesOfString:@"%UserPhoneLabel%" withString:NotNil(currentUser.phone)];
		
		if ((range = [html rangeOfString:@"%NewSessionToken%"]).length) {
			NSString* token = [session createToken];
			do {
				[html replaceCharactersInRange:range withString:token];
			} while ((range = [html rangeOfString:@"%NewSessionToken%"]).length);
		}
	}
	
	if ((range = [html rangeOfString:@"%NewChallenge%"]).length) {
		double challenged = [NSDate timeIntervalSinceReferenceDate];
		NSString* challenge = [[[NSData dataWithBytes:&challenged length:sizeof(double)] md5Digest] hex];
		[html replaceOccurrencesOfString:@"%NewChallenge%" withString:NotNil(challenge)];
		[session setObject:challenge forKey:SessionChallengeKey];
	}
	
	if ((range = [html rangeOfString:@"%DicomCStorePort%"]).length) { // only if necessary, so dicomCStorePortString is only generated for sessions that need it
		[html replaceOccurrencesOfString: @"%DicomCStorePort%" withString:self.dicomCStorePortString];
	}
	
	return html;
}

+ (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message forUser: (NSString*) user ip: (NSString*) ip
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"logWebServer"] == NO) return;
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
	if (context == nil)
		return;
	
	[context lock];
	
	@try
	{
		if (user)
			message = [user stringByAppendingFormat:@" : %@", message];
	
		if (ip == nil)
			ip = [[AppController sharedAppController] privateIP];
	
		// Search for same log entry during last 5 min
		
		NSArray *logs = nil;
		@try 
		{
			NSError *error = nil;
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"LogEntry"]];
			[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(patientName==%@) AND (studyName==%@) AND (message==%@) AND (originName==%@) AND (endTime >= CAST(%lf, \"NSDate\"))", [study valueForKey: @"name"], [study valueForKey: @"studyName"], message, ip, [[NSDate dateWithTimeIntervalSinceNow: -5 * 60] timeIntervalSinceReferenceDate]]];
		
			logs = [context executeFetchRequest: dbRequest error: &error];
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		if ([logs count] == 0)
		{
			NSManagedObject *logEntry = nil;
			
			logEntry = [NSEntityDescription insertNewObjectForEntityForName: @"LogEntry" inManagedObjectContext:context];
			[logEntry setValue: [NSDate date] forKey: @"startTime"];
			[logEntry setValue: [NSDate date] forKey: @"endTime"];
			[logEntry setValue: @"Web" forKey: @"type"];
			
			if (study)
				[logEntry setValue: [study valueForKey: @"name"] forKey: @"patientName"];
			
			if (study)
				[logEntry setValue: [study valueForKey: @"studyName"] forKey: @"studyName"];
			
			[logEntry setValue: message forKey: @"message"];
			
			if (ip)
				[logEntry setValue: ip forKey: @"originName"];
		}
		else
			[logs setValue: [NSDate date] forKey: @"endTime"];
	}
	@catch (NSException * e)
	{
		NSLog( @"****** OsiriX HTTPConnection updateLogEntry exception : %@", e);
	}

	[context unlock];
}

- (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message
{
	[WebPortalConnection updateLogEntryForStudy: study withMessage: message forUser:currentUser.name ip: [asyncSocket connectedHost]];
}

+(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate message:(NSString*)message replyTo:(NSString*)replyto customText:(NSString*)customText webServerAddress:(NSString*)webServerAddress
{
	if (!webServerAddress)
		webServerAddress = self.WebServerAddress;
	NSString* webServerURL = [self WebServerURLForAddress:webServerAddress];
	
	NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
	if (fromEmailAddress == nil)
		fromEmailAddress = @"";
	
	for ( NSManagedObject *user in users)
	{
		NSMutableAttributedString *emailMessage = nil;
		
		if (message == nil)
			emailMessage = [[[NSMutableAttributedString alloc] initWithData:[WebPortalConnection WebServicesHTMLData:@"emailTemplate.txt"] options:NULL documentAttributes:nil error:NULL] autorelease];
		else
			emailMessage = [[[NSMutableAttributedString alloc] initWithString: message] autorelease];
		
		if (emailMessage)
		{
			if (customText == nil) customText = @"";
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%customText%" withString:NotNil([customText stringByAppendingString:@"\r\r"])];
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%Username%" withString:NotNil([user valueForKey: @"name"])];
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%WebServerAddress%" withString:webServerURL];
			
			NSMutableString *urls = [NSMutableString string];
			
			if ([filteredStudies count] > 1 && predicate != nil)
			{
				[urls appendString: NSLocalizedString( @"To view this entire list, including patients names:\r", nil)]; 
				[urls appendFormat: @"%@ : %@/studyList?%@\r\r\r\r", NSLocalizedString( @"Click here", nil), webServerURL, predicate]; 
			}
			
			for ( NSManagedObject *s in filteredStudies)
			{
				[urls appendFormat: @"%@ - %@ (%@)\r", [s valueForKey: @"modality"], [s valueForKey: @"studyName"], [BrowserController DateTimeFormat: [s valueForKey: @"date"]]]; 
				[urls appendFormat: @"%@ : %@/study?id=%@&browse=all\r\r", NSLocalizedString( @"Click here", nil), webServerURL, [s valueForKey: @"studyInstanceUID"]]; 
			}
			
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%URLsList%" withString:NotNil(urls)];
			
			NSString *emailAddress = [user valueForKey: @"email"];
			
			NSString *emailSubject = nil;
			if (replyto)
				emailSubject = [NSString stringWithFormat: NSLocalizedString( @"A new radiology exam is available for you, from %@", nil), replyto];
			else
				emailSubject = NSLocalizedString( @"A new radiology exam is available for you !", nil);
			
			[[CSMailMailClient mailClient] deliverMessage: emailMessage headers: [NSDictionary dictionaryWithObjectsAndKeys: emailAddress, @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", replyto, @"ReplyTo", nil]];
			
			for ( NSManagedObject *s in filteredStudies)
			{
				[WebPortalConnection updateLogEntryForStudy: s withMessage: @"notification email" forUser: [user valueForKey: @"name"] ip:webServerAddress];
			}
		}
		else NSLog( @"********* warning : CANNOT send notifications emails, because emailTemplate.txt == nil");
	}
	
	return YES; // succeeded
}

+(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate message:(NSString*)message replyTo:(NSString*)replyto customText:(NSString*)customText {
	return [self sendNotificationsEmailsTo:users aboutStudies:filteredStudies predicate:predicate message:message replyTo:replyto customText:customText webServerAddress:NULL];
}

+ (void) emailNotifications
{
	if ([NSThread isMainThread] == NO)
	{
		NSLog( @"********* applescript needs to be in the main thread");
		return;
	}

	// Lets check if new studies are available for each users! and if temporary users reached the end of their life.....
	
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]];
	NSString *newCheckString = [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"lastNotificationsDate"] == nil)
	{
		[[NSUserDefaults standardUserDefaults] setValue: [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]] forKey: @"lastNotificationsDate"];
		return;
	}
	
	if ([[[BrowserController currentBrowser] managedObjectContext] tryLock])
	{
		[[[BrowserController currentBrowser] userManagedObjectContext] lock];
		
		// TEMPORARY USERS
		
		@try
		{
			BOOL toBeSaved = NO;
			
			// Find all users
			NSError *error = nil;
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
			[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
			
			error = nil;
			NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
			
			for ( NSManagedObject *user in users)
			{
				if ([[user valueForKey: @"autoDelete"] boolValue] == YES && [user valueForKey: @"deletionDate"] && [[user valueForKey: @"deletionDate"] timeIntervalSinceDate: [NSDate date]] < 0)
				{
					NSLog( @"----- Temporary User reached the EOL (end-of-life) : %@", [user valueForKey: @"name"]);
					
					[WebPortalConnection updateLogEntryForStudy: nil withMessage: @"temporary user deleted" forUser: [user valueForKey: @"name"] ip: [[NSUserDefaults standardUserDefaults] valueForKey: @"webServerAddress"]];
					
					toBeSaved = YES;
					[[[BrowserController currentBrowser] userManagedObjectContext] deleteObject: user];
				}
			}
			
			if (toBeSaved)
				[[[BrowserController currentBrowser] userManagedObjectContext] save: nil];
		}
		@catch (NSException *e)
		{
			NSLog( @"***** emailNotifications exception for deleting temporary users: %@", e);
		}
		
		// CHECK dateAdded
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"notificationsEmails"] == YES)
		{
			@try
			{
				NSError *error = nil;
				NSFetchRequest *dbRequest = nil;
				
				// Find all studies AFTER the lastCheckDate
				error = nil;
				dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"Study"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
				
				error = nil;
				NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error:&error];
				
				if ([studies count] > 0)
				{
					// Find all users
					error = nil;
					dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
					
					error = nil;
					NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
					
					for ( NSManagedObject *user in users)
					{
						if ([[user valueForKey: @"emailNotification"] boolValue] == YES && [(NSString*) [user valueForKey: @"email"] length] > 2)
						{
							NSArray *filteredStudies = studies;
							
							@try
							{
								filteredStudies = [studies filteredArrayUsingPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [user valueForKey: @"studyPredicate"]]];
								filteredStudies = [WebPortalConnection addSpecificStudiesToArray: filteredStudies forUser: user predicate: [NSPredicate predicateWithFormat: @"dateAdded > CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]]];
								
								filteredStudies = [filteredStudies filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"dateAdded > CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]]]; 
								filteredStudies = [filteredStudies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
							}
							@catch (NSException * e)
							{
								NSLog( @"******* studyPredicate exception : %@ %@", e, user);
							}
							
							if ([filteredStudies count] > 0)
							{
								[WebPortalConnection sendNotificationsEmailsTo: [NSArray arrayWithObject: user] aboutStudies: filteredStudies predicate: [NSString stringWithFormat: @"browse=newAddedStudies&browseParameter=%lf", [lastCheckDate timeIntervalSinceReferenceDate]] message: nil replyTo: nil customText: nil];
							}
						}
					}
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"***** emailNotifications exception: %@", e);
			}
		}
		[[[BrowserController currentBrowser] userManagedObjectContext] unlock];
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
	}
	
	[[NSUserDefaults standardUserDefaults] setValue: newCheckString forKey: @"lastNotificationsDate"];
}

- (BOOL) isPasswordProtected:(NSString *)path
{
	if ([path hasPrefix: @"/wado"])
		return NO;
		
	if ([path hasPrefix: @"/images/"])
		return NO;
	
	if ([path isEqualToString: @"/"])
		return NO;
	
	if ([path isEqualToString: @"/style.css"])
		return NO;
	
	if ([path hasSuffix:@".js"])
		return NO;
	
	if ([path isEqualToString: @"/iPhoneStyle.css"])
		return NO;
	
	if ([path hasPrefix: @"/password_forgotten"])
		return NO;
	
	if ([path hasPrefix: @"/index"])
		return NO;
	
	if ([path hasPrefix:@"/weasis/"])
		return NO;
	
	if ([path isEqualToString: @"/favicon.ico"])
		return NO;

	return [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"];
}

/*-(BOOL)useDigestAccessAuthentication {
	return YES;
}*/ // commented becauso is default superclass behavior

- (NSString *) passwordForUser:(NSString *)username
{
	self.currentUser = NULL;
	
	if ([username length] >= 2)
	{
		NSArray	*users = nil;
		
		[[[BrowserController currentBrowser] userManagedObjectContext] lock];
		
		@try
		{
			NSFetchRequest *r = [[[NSFetchRequest alloc] init] autorelease];
			[r setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey:@"User"]];
			[r setPredicate: [NSPredicate predicateWithFormat:@"name == %@", username]];
			
			NSError *error = nil;
			users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: r error: &error];
		}
		@catch (NSException *e)
		{
			NSLog( @"******* passwordForUser exception: %@", e);
		}
		
		[[[BrowserController currentBrowser] userManagedObjectContext] unlock];
		
		if ([users count] == 0)
		{
			[self updateLogEntryForStudy: nil withMessage: [NSString stringWithFormat: @"Unknown user: %@", username]];
			return nil;
		}
		if ([users count] > 1)
		{
			NSLog( @"******** WARNING multiple users with identical user name : %@", username);
		}
		
		self.currentUser = users.lastObject;
	}
	else return nil;
	
	return currentUser.password;
}

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)isSecureServer
{
	// Create an HTTPS server (all connections will be secured via SSL/TLS)
	return [WebPortalConnection IsSecureServer];
}

/**
 * Overrides HTTPConnection's method
 * 
 * This method is expected to returns an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 **/
- (NSArray *)sslIdentityAndCertificates
{
//	NSArray *result = [DDKeychain SSLIdentityAndCertificates];
	id identity = (id)[DDKeychain KeychainAccessPreferredIdentityForName:@"com.osirixviewer.osirixwebserver" keyUse:CSSM_KEYUSE_ANY];
	if (identity == nil)
	{
		[DDKeychain createNewIdentity];
		identity = (id)[DDKeychain KeychainAccessPreferredIdentityForName:@"com.osirixviewer.osirixwebserver" keyUse:CSSM_KEYUSE_ANY];
	}
	
	NSMutableArray *array = [NSMutableArray arrayWithObject:identity];
	
	// We add the chain of certificates that validates the chosen certificate.
	// This way we don't have to install the intermediate certificates on the clients systems. Yay!
	NSArray *certificateChain = [DDKeychain KeychainAccessCertificateChainForIdentity:(SecIdentityRef)identity];
	[array addObjectsFromArray:certificateChain];

	return [NSArray arrayWithArray:array];
}

- (void) dealloc
{
	[sendLock lock];
	[sendLock unlock];
	[sendLock release];
	
	[selectedDICOMNode release];
	[selectedImages release];
	self.currentUser = NULL;
	
	[multipartData release];
	[postBoundary release];
	[POSTfilename release];
	[urlParameters release];
	
	self.session = NULL;
	
	[super dealloc];
}

- (NSTimeInterval)startOfDay:(NSCalendarDate *)day
{
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: nil];
	return [start timeIntervalSinceReferenceDate];
}

- (NSMutableString*)htmlStudy:(DicomStudy*)study parameters:(NSDictionary*)parameters settings: (NSDictionary*) settings;
{
	BOOL dicomSend = NO;
	BOOL shareSend = NO;
	BOOL weasis = NO;
	
	if (currentUser == nil || currentUser.sendDICOMtoSelfIP.boolValue)
		dicomSend = YES;
		
	if (currentUser && currentUser.shareStudyWithUser.boolValue)
		shareSend = YES;
	
	if ([NSUserDefaultsController WebServerUsesWeasis])
		weasis = YES;
	
	NSArray *users = nil;
	
	if (shareSend)
	{
		// Find all users
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		
		error = nil;
		users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error: &error];
		
		if ([users count] == 1) // only current user...
			shareSend = NO;
	}
	
	if (currentUser && [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue] == YES && [[currentUser valueForKey: @"sendDICOMtoAnyNodes"] boolValue] == NO)
	{
		//if ([[session objectForKey:SessionDicomCStorePortKey] intValue] > 0 && [ipAddressString length] >= 7)
		//{
		//}
		//else dicomSend = NO;
	}
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *returnHTML = nil;
	
	@try
	{
		NSMutableString* templateString = [self webServicesHTMLMutableString:@"study.html"];
		
		[WebPortalData mutableString:templateString block:@"SendingFunctions1" setVisible: dicomSend|weasis];
		[WebPortalData mutableString:templateString block:@"SendingFunctions2" setVisible:dicomSend|weasis];
		[WebPortalData mutableString:templateString block:@"SendingFunctions3" setVisible:dicomSend];
		[WebPortalData mutableString:templateString block:@"SharingFunctions" setVisible:shareSend];
		[WebPortalData mutableString:templateString block:@"ZIPFunctions" setVisible:((currentUser == nil || [[currentUser valueForKey: @"downloadZIP"] boolValue]) && ![[settings valueForKey:@"iPhone"] boolValue])];
		[WebPortalData mutableString:templateString block:@"Weasis" setVisible: (weasis && ![[settings valueForKey:@"iPhone"] boolValue])];
		
		[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip")];
		
		NSString *browse = NotNil([parameters objectForKey:@"browse"]);
		NSString *browseParameter = NotNil([parameters objectForKey:@"browseParameter"]);
		NSString *search = NotNil([parameters objectForKey:@"search"]);
		NSString *album = NotNil([parameters objectForKey:@"album"]);
		
		[templateString replaceOccurrencesOfString:@"%browse%" withString:browse];
		[templateString replaceOccurrencesOfString:@"%browseParameter%" withString:browseParameter];
		[templateString replaceOccurrencesOfString:@"%search%" withString:search];
		[templateString replaceOccurrencesOfString:@"%album%" withString:album];
		
		NSString *LocalizedLabel_StudyList = @"";
		if (![search isEqualToString:@""])
			LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Search Result for", nil), search];
		else if (![album isEqualToString:@""])
			LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Album", nil), album];
		else
		{
			if ([browse isEqualToString:@"6hours"])
				LocalizedLabel_StudyList = NSLocalizedString(@"Last 6 Hours", nil);
			else if ([browse isEqualToString:@"today"])
				LocalizedLabel_StudyList = NSLocalizedString(@"Today", nil);
			else
				LocalizedLabel_StudyList = NSLocalizedString(@"Study List", nil);
		}
		
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyList%" withString:NotNil(LocalizedLabel_StudyList)];
		
		if ([[study valueForKey:@"reportURL"] hasPrefix: @"http://"] || [[study valueForKey:@"reportURL"] hasPrefix: @"https://"])
		{
			[WebPortalData mutableString:templateString block:@"Report" setVisible:NO];
			[WebPortalData mutableString:templateString block:@"ReportURL" setVisible:NO];
			
			[templateString replaceOccurrencesOfString:@"%ReportURLString%" withString:NotNil([study valueForKey:@"reportURL"])];
		}
		else
		{
			[WebPortalData mutableString:templateString block:@"ReportURL" setVisible:NO];
			[WebPortalData mutableString:templateString block:@"Report" setVisible:([study valueForKey:@"reportURL"] && ![[settings valueForKey:@"iPhone"] boolValue])];
			
			if ([[[study valueForKey:@"reportURL"] pathExtension] isEqualToString: @"pages"])
				[templateString replaceOccurrencesOfString:@"%reportExtension%" withString:NotNil(@"zip")];
			else
				[templateString replaceOccurrencesOfString:@"%reportExtension%" withString:NotNil([[study valueForKey:@"reportURL"] pathExtension])];
		}

			
		NSArray *tempArray = [templateString componentsSeparatedByString:@"%SeriesListItem%"];
		NSString *templateStringStart = [tempArray objectAtIndex:0];
		tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/SeriesListItem%"];
		NSString *seriesListItemString = [tempArray objectAtIndex:0];
		NSString *templateStringEnd = [tempArray lastObject];
		
		returnHTML = [NSMutableString stringWithString: templateStringStart];
		
		[returnHTML replaceOccurrencesOfString:@"%PageTitle%" withString:NotNil([study valueForKey:@"name"])];
		[returnHTML replaceOccurrencesOfString:@"%PatientID%" withString:NotNil([study valueForKey:@"patientID"])];
		[returnHTML replaceOccurrencesOfString:@"%PatientName%" withString:NotNil([study valueForKey:@"name"])];
		[returnHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:NotNil([study valueForKey:@"studyName"])];
		[returnHTML replaceOccurrencesOfString:@"%StudyModality%" withString:NotNil([study valueForKey:@"modality"])];

		if (![study valueForKey:@"comment"])
			[WebPortalData mutableString:returnHTML block:@"StudyCommentBlock" setVisible:NO];
		else
		{
			[WebPortalData mutableString:returnHTML block:@"StudyCommentBlock" setVisible:YES];
			[returnHTML replaceOccurrencesOfString:@"%StudyComment%" withString:NotNil([study valueForKey:@"comment"])];
		}

		NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
		if ([[study valueForKey:@"stateText"] intValue] == 0)
			stateText = nil;
		
		if (!stateText)
			[WebPortalData mutableString:returnHTML block:@"StudyStateBlock" setVisible:NO];
		else
		{
			[WebPortalData mutableString:returnHTML block:@"StudyStateBlock" setVisible:YES];
			[returnHTML replaceOccurrencesOfString:@"%StudyState%" withString:NotNil(stateText)];
		}
		
		NSDateFormatter *dobDateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dobDateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateOfBirthFormat2"]];
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
		
		[returnHTML replaceOccurrencesOfString:@"%PatientDOB%" withString:NotNil([dobDateFormat stringFromDate:[study valueForKey:@"dateOfBirth"]])];
		[returnHTML replaceOccurrencesOfString:@"%AccessionNumber%" withString:NotNil([study valueForKey:@"accessionNumber"])];
		[returnHTML replaceOccurrencesOfString:@"%StudyDate%" withString: [WebPortalConnection iPhoneCompatibleNumericalFormat: [dateFormat stringFromDate: [study valueForKey:@"date"]]]];
		
		NSArray *seriesArray = [study valueForKey:@"imageSeries"];
		
		NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
		NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSArray * sortDescriptors;
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
		[sortid release];
		[sortdate release];
		
		seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
		
		int lineNumber=0;
		for (DicomSeries *series in seriesArray)
		{
			NSMutableString *tempHTML = [NSMutableString stringWithString:seriesListItemString];
			
			[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2]];
			lineNumber++;
			
			[tempHTML replaceOccurrencesOfString:@"%SeriesName%" withString:NotNil(series.name)];
			[tempHTML replaceOccurrencesOfString:@"%thumbnail%" withString: [NSString stringWithFormat:@"thumbnail?id=%@&studyID=%@", NotNil([series valueForKey:@"seriesInstanceUID"]), NotNil([study valueForKey:@"studyInstanceUID"])]];
			[tempHTML replaceOccurrencesOfString:@"%SeriesID%" withString:NotNil(series.seriesInstanceUID)];
			[tempHTML replaceOccurrencesOfString:@"%SeriesComment%" withString:NotNil([series valueForKey:@"comment"])];
			[tempHTML replaceOccurrencesOfString:@"%PatientName%" withString:NotNil(series.study.name)];
			
			if ([DCMAbstractSyntaxUID isPDF: [series valueForKey: @"seriesSOPClassUID"]])
				[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @".pdf"];
			else if ([DCMAbstractSyntaxUID isStructuredReport: [series valueForKey: @"seriesSOPClassUID"]])
				[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @".pdf"];
			else
				[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @""];

			NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[series valueForKey: @"stateText"] intValue]];
			if ([[series valueForKey:@"stateText"] intValue] == 0)
				stateText = nil;
			[tempHTML replaceOccurrencesOfString:@"%SeriesState%" withString:NotNil(stateText)];
			
			int nbFiles = [[series valueForKey:@"noFiles"] intValue];
			if (nbFiles <= 1)
			{
				if (nbFiles == 0)
					nbFiles = 1;
			}
			NSString *imagesLabel = (nbFiles>1)? NSLocalizedString(@"Images", nil) : NSLocalizedString(@"Image", nil);
			[tempHTML replaceOccurrencesOfString:@"%SeriesImageNumber%" withString: [NSString stringWithFormat:@"%d %@", nbFiles, imagesLabel]];
			
			NSString *comment = [series valueForKey:@"comment"];
			if (comment == nil)
				comment = @"";
			[tempHTML replaceOccurrencesOfString:@"%SeriesComment%" withString: comment];
			
			
			NSString *checked = @"";
			for (NSString* selectedID in [parameters objectForKey:@"selected"])
			{
				if ([[series valueForKey:@"seriesInstanceUID"] isEqualToString:[selectedID stringByReplacingOccurrencesOfString:@"+" withString:@" "]])
					checked = @"checked";
			}
			
			[tempHTML replaceOccurrencesOfString:@"%checked%" withString:NotNil(checked)];
			
			[returnHTML appendString:tempHTML];
		}
		
		NSMutableString *tempHTML = [NSMutableString stringWithString:templateStringEnd];
		[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2]];
		templateStringEnd = [NSString stringWithString:tempHTML];
		
		NSString *checkAllStyle = @"";
		if ([seriesArray count]<=1) checkAllStyle = @"style='display:none;'";
		[returnHTML replaceOccurrencesOfString:@"%CheckAllStyle%" withString:NotNil(checkAllStyle)];
		
		BOOL checkAllChecked = [[parameters objectForKey:@"CheckAll"] isEqualToString:@"on"] || [[parameters objectForKey:@"CheckAll"] isEqualToString:@"checked"];
		[returnHTML replaceOccurrencesOfString:@"%CheckAllChecked%" withString: checkAllChecked? @"checked=\"checked\"" : @""];
		
		NSString *dicomNodesListItemString = @"";
		if (dicomSend)
		{
			tempArray = [templateStringEnd componentsSeparatedByString:@"%dicomNodesListItem%"];
			templateStringStart = [tempArray objectAtIndex:0];
			tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/dicomNodesListItem%"];
			dicomNodesListItemString = [tempArray objectAtIndex:0];
			templateStringEnd = [tempArray lastObject];
			[returnHTML appendString:templateStringStart];
			
			BOOL selectedDone = NO;
			
			if (currentUser == nil || [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue] == YES)
			{
				NSString *dicomNodeAddress = [asyncSocket connectedHost];
				NSString *dicomNodeAETitle = @"This Computer";
				
				NSString *dicomNodeSyntax;
				if ([[settings valueForKey:@"iPhone"] boolValue]) dicomNodeSyntax = @"5";
				else dicomNodeSyntax = @"0";
				NSString *dicomNodeDescription = @"This Computer";
				
				NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:NotNil(dicomNodeAddress)];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:NotNil(self.dicomCStorePortString)];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:NotNil(dicomNodeAETitle)];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:NotNil(dicomNodeSyntax)];

				if (![[settings valueForKey:@"iPhone"] boolValue])
					dicomNodeDescription = [dicomNodeDescription stringByAppendingFormat:@" [%@:%@]", NotNil(dicomNodeAddress), NotNil(self.dicomCStorePortString)];
				
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:NotNil(dicomNodeDescription)];
				
				NSString *selected = @"";
					
				if ([parameters objectForKey:@"dicomDestination"])
				{
					NSString * s = [parameters objectForKey:@"dicomDestination"];
					
					NSArray *sArray = [s componentsSeparatedByString: @":"];
					
					if ([sArray count] >= 2)
					{
						if ([[sArray objectAtIndex: 0] isEqualToString: dicomNodeAddress] && [[sArray objectAtIndex: 1] isEqualToString:self.dicomCStorePortString])
						{
							selected = @"selected";
							selectedDone = YES;
						}
					}
				}
				
				[tempHTML replaceOccurrencesOfString:@"%selected%" withString:NotNil(selected)];
				
				[returnHTML appendString:tempHTML];
			}
		
			if (currentUser == nil || [[currentUser valueForKey: @"sendDICOMtoAnyNodes"] boolValue] == YES)
			{
				NSArray *nodes = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
				
				for (NSDictionary *node in nodes)
				{
					NSString *dicomNodeAddress = NotNil([node objectForKey:@"Address"]);
					NSString *dicomNodePort = [NSString stringWithFormat:@"%d", [[node objectForKey:@"Port"] intValue]];
					NSString *dicomNodeAETitle = NotNil([node objectForKey:@"AETitle"]);
					NSString *dicomNodeSyntax = [NSString stringWithFormat:@"%d", [[node objectForKey:@"TransferSyntax"] intValue]];
					NSString *dicomNodeDescription = NotNil([node objectForKey:@"Description"]);
					
					NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:NotNil(dicomNodeAddress)];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:NotNil(dicomNodePort)];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:NotNil(dicomNodeAETitle)];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:NotNil(dicomNodeSyntax)];
					
					if (![[settings valueForKey:@"iPhone"] boolValue])
						dicomNodeDescription = [dicomNodeDescription stringByAppendingFormat:@" [%@:%@]", NotNil(dicomNodeAddress), NotNil(dicomNodePort)];
					
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:NotNil(dicomNodeDescription)];
					
					NSString *selected = @"";
					
					if ([parameters objectForKey:@"dicomDestination"] && selectedDone == NO)
					{
						NSString * s = [parameters objectForKey:@"dicomDestination"];
						
						NSArray *sArray = [s componentsSeparatedByString: @":"];
						
						if ([sArray count] >= 2)
						{
							if ([[sArray objectAtIndex: 0] isEqualToString: dicomNodeAddress] && [[sArray objectAtIndex: 1] isEqualToString: dicomNodePort])
							{
								selected = @"selected";
								selectedDone = YES;
							}
						}
					}
					
					[tempHTML replaceOccurrencesOfString:@"%selected%" withString:NotNil(selected)];
					
					[returnHTML appendString:tempHTML];
				}
			}
			
			[returnHTML appendString:templateStringEnd];
		}
		else [returnHTML appendString:templateStringEnd];
		
		if (shareSend)
		{
			tempArray = [returnHTML componentsSeparatedByString:@"%userListItem%"];
			templateStringStart = [tempArray objectAtIndex:0];
			
			tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/userListItem%"];
			NSString *userListItemString = [tempArray objectAtIndex:0];
			
			templateStringEnd = [tempArray lastObject];
			
			returnHTML = [NSMutableString stringWithString: templateStringStart];
			
			@try
			{
				users = [users sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
				
				for ( NSManagedObject *user in users)
				{
					if (user != currentUser)
					{
						NSMutableString *tempHTML = [NSMutableString stringWithString: userListItemString];
						
						[tempHTML replaceOccurrencesOfString:@"%username%" withString:NotNil([user valueForKey: @"name"])];
						[tempHTML replaceOccurrencesOfString:@"%email%" withString:NotNil([user valueForKey: @"email"])];
						
						NSString *userDescription = [NSString stringWithString:NotNil([user valueForKey:@"name"])];
						if (![[settings valueForKey:@"iPhone"] boolValue])
							userDescription = [userDescription stringByAppendingFormat:@" (%@)", NotNil([user valueForKey:@"email"])];
						
						[tempHTML replaceOccurrencesOfString:@"%userDescription%" withString:NotNil(userDescription)];
						
						[returnHTML appendString: tempHTML];
					}
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"****** exception in find all users htmlStudy: %@", e);
			}
			
			[returnHTML appendString: templateStringEnd];
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"******* htmlStudy exception: %@", e);
	}
	
	[context unlock];
	
	return returnHTML;
}

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies settings: (NSDictionary*) settings
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *returnHTML = nil;
	
	@try
	{
		NSMutableString *templateString = [self webServicesHTMLMutableString:@"studyList.html"];

		[WebPortalData mutableString:templateString block:@"ZIPFunctions" setVisible:(currentUser && [[currentUser valueForKey: @"downloadZIP"] boolValue] && ![[settings valueForKey:@"iPhone"] boolValue])];
		[WebPortalData mutableString:templateString block:@"Weasis" setVisible:([NSUserDefaultsController WebServerUsesWeasis] && ![[settings valueForKey:@"iPhone"] boolValue])];
		
		[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip")];
		
		NSArray *tempArray = [templateString componentsSeparatedByString:@"%StudyListItem%"];
		NSString *templateStringStart = [tempArray objectAtIndex:0];
		tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/StudyListItem%"];
		NSString *studyListItemString = [tempArray objectAtIndex:0];
		NSString *templateStringEnd = [tempArray lastObject];
		
		returnHTML = [NSMutableString stringWithString:templateStringStart];
		
		int lineNumber = 0;
		for (DicomStudy *study in studies)
		{
			NSMutableString *tempHTML = [NSMutableString stringWithString:studyListItemString];
			
			[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2]];
			lineNumber++;
			
			// filenameString?
			[tempHTML replaceOccurrencesOfString:@"%StudyListItemName%" withString:NotNil([study valueForKey:@"name"])];
			
			NSArray *seriesArray = [study valueForKey:@"imageSeries"] ; //imageSeries
			int count = 0;
			for (DicomSeries *series in seriesArray)
			{
				count++;
			}
			
			NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
			
			NSString *date = [dateFormat stringFromDate:[study valueForKey:@"date"]];
			
			NSString *dateLabel = [NSString stringWithFormat:@"%@", [WebPortalConnection iPhoneCompatibleNumericalFormat:date]];
			dateLabel = [WebPortalConnection unbreakableStringWithString:dateLabel];
			BOOL displayBlock = YES;
			if ([dateLabel length])
				[tempHTML replaceOccurrencesOfString:@"%StudyDate%" withString:dateLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"StudyDateBlock" setVisible:displayBlock];

			NSString *seriesCountLabel = [NSString stringWithFormat:@"%d Series", count];
			displayBlock = YES;
			if ([seriesCountLabel length])
				[tempHTML replaceOccurrencesOfString:@"%SeriesCount%" withString:seriesCountLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"SeriesCountBlock" setVisible:displayBlock];
			
			NSString *patientIDLabel = [NSString stringWithFormat:@"%@", NotNil([study valueForKey:@"patientID"])];
			displayBlock = YES;
			if ([patientIDLabel length])
				[tempHTML replaceOccurrencesOfString:@"%PatientID%" withString:patientIDLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"PatientIDBlock" setVisible:displayBlock];
			
			NSString *accessionNumberLabel = [NSString stringWithFormat:@"%@", NotNil([study valueForKey:@"accessionNumber"])];
			displayBlock = YES;
			if ([accessionNumberLabel length])
				[tempHTML replaceOccurrencesOfString:@"%AccessionNumber%" withString:accessionNumberLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"AccessionNumberBlock" setVisible:displayBlock];
			
			NSString *studyCommentLabel = NotNil([study valueForKey:@"comment"]);
			displayBlock = YES;
			if ([studyCommentLabel length])
				[tempHTML replaceOccurrencesOfString:@"%StudyComment%" withString:studyCommentLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"StudyCommentBlock" setVisible:displayBlock];
			
			NSString *studyDescriptionLabel = NotNil([study valueForKey:@"studyName"]);
			displayBlock = YES;
			if ([studyDescriptionLabel length])
				[tempHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:studyDescriptionLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"StudyDescriptionBlock" setVisible:displayBlock];
			
			NSString *studyModalityLabel = NotNil([study valueForKey:@"modality"]);
			displayBlock = YES;
			if ([studyModalityLabel length])
				[tempHTML replaceOccurrencesOfString:@"%StudyModality%" withString:studyModalityLabel];
			else
				displayBlock = NO;
			[WebPortalData mutableString:tempHTML block:@"StudyModalityBlock" setVisible:displayBlock];
					
			NSString *stateText = @"";
			int v = [[study valueForKey:@"stateText"] intValue];
			if (v > 0 && v < [[BrowserController statesArray] count])
				stateText = [[BrowserController statesArray] objectAtIndex: v];
			
			NSString *studyStateLabel = NotNil(stateText);
			displayBlock = YES;
			if ([studyStateLabel length])
				[tempHTML replaceOccurrencesOfString:@"%StudyState%" withString:studyStateLabel];
			else
				displayBlock = NO;
			
			[WebPortalData mutableString:tempHTML block:@"StudyStateBlock" setVisible:displayBlock];
			
			[tempHTML replaceOccurrencesOfString:@"%StudyListItemID%" withString:NotNil([study valueForKey:@"studyInstanceUID"])];
			[returnHTML appendString:tempHTML];
		}
		
		[returnHTML appendString:templateStringEnd];
	}
	@catch (NSException *e)
	{
		NSLog( @"**** htmlStudyListForStudies exception: %@", e);
	}
	[context unlock];
	
	return returnHTML;
}

- (NSArray*) addSpecificStudiesToArray: (NSArray*) array
{
	return [WebPortalConnection addSpecificStudiesToArray: array forUser: currentUser predicate: nil];
}

+ (NSArray*) addSpecificStudiesToArray: (NSArray*) array forUser: (NSManagedObject*) user predicate: (NSPredicate*) predicate
{
	NSMutableArray *specificArray = [NSMutableArray array];
	BOOL truePredicate = NO;
	
	if (predicate == nil)
	{
		predicate = [NSPredicate predicateWithValue: YES];
		truePredicate = YES;
	}
	
	@try
	{
		NSArray *userStudies = nil;
		
		if (truePredicate == NO)
		{
			NSArray *allUserStudies = [[user valueForKey: @"studies"] allObjects];
			NSArray *userStudies = [allUserStudies filteredArrayUsingPredicate: predicate];
			NSMutableArray *excludedStudies = [NSMutableArray arrayWithArray: allUserStudies];
			
			[excludedStudies removeObjectsInArray: userStudies];
			
			NSMutableArray *mutableArray = [NSMutableArray arrayWithArray: array];
			
			// First remove all user studies from array, we will re-add them after, if necessary
			for ( NSManagedObject *study in excludedStudies)
			{
				NSArray *obj = [mutableArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", [study valueForKey: @"patientUID"], [study valueForKey: @"studyInstanceUID"]]];
				
				if ([obj count] == 1)
				{
					[mutableArray removeObject: [obj lastObject]];
				}
				else if ([obj count] > 1)
					NSLog( @"********** warning multiple studies with same instanceUID and patientUID : %@", obj);
			}
			
			array = mutableArray;
		}
		else userStudies = [[user valueForKey: @"studies"] allObjects];
		
		// Find all studies of the DB
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		
		error = nil;
		NSArray *studiesArray = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error: &error];
		
		for ( NSManagedObject *study in userStudies)
		{
			NSArray *obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", [study valueForKey: @"patientUID"], [study valueForKey: @"studyInstanceUID"]]];
			
			if ([obj count] == 1)
			{
				if ([array containsObject: [obj lastObject]] == NO && [specificArray containsObject: [obj lastObject]] == NO)
					[specificArray addObject: [obj lastObject]];
			}
			else if ([obj count] > 1)
				NSLog( @"********** warning multiple studies with same instanceUID and patientUID : %@", obj);
			else if (truePredicate && [obj count] == 0)
			{
				// It means this study doesnt exist in the entire DB -> remove it from this user list
				NSLog( @"This study is not longer available in the DB -> delete it : %@", [study valueForKey: @"patientUID"]);
				[[[BrowserController currentBrowser] userManagedObjectContext] deleteObject: study];
			}
		}
	}
	@catch (NSException * e)
	{
		NSLog( @"********** addSpecificStudiesToArray : %@", e);
	}
	
	return [array arrayByAddingObjectsFromArray: specificArray];
}

- (NSArray*)studiesForPredicate:(NSPredicate *)predicate;
{
	return [self studiesForPredicate: predicate sortBy: nil];
}

- (NSArray*)studiesForPredicate:(NSPredicate *)predicate sortBy: (NSString*) sortValue
{
	NSArray *studiesArray = nil;
	
	[[BrowserController currentBrowser].managedObjectContext lock];
	
	@try
	{
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [currentUser valueForKey: @"studyPredicate"]]];
		
		error = nil;
		studiesArray = [[BrowserController currentBrowser].managedObjectContext executeFetchRequest:dbRequest error: &error];
		studiesArray = [self addSpecificStudiesToArray: studiesArray];
		studiesArray = [studiesArray filteredArrayUsingPredicate: predicate];
		
		if ([sortValue length] && [sortValue isEqualToString: @"date"] == NO)
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES selector: @selector( caseInsensitiveCompare:)] autorelease]]];
		else
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO] autorelease]]];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"********** studiesForPredicate exception: %@", e.description);
	}
	
	[[BrowserController currentBrowser].managedObjectContext unlock];
	
	return studiesArray;
}

- (NSArray*)seriesForPredicate:(NSPredicate *)predicate;
{
	NSArray *seriesArray = nil;
	NSArray *studiesArray = nil;
	
	[[BrowserController currentBrowser].managedObjectContext lock];
	
	if ([(NSString*) [currentUser valueForKey: @"studyPredicate"] length] > 0) // First, take all the available studies for this user, and then get the series : SECURITY : we want to be sure that he cannot access to unauthorized images
	{
		@try
		{
			NSError *error = nil;
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
			[dbRequest setPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [currentUser valueForKey: @"studyPredicate"]]];
			
			error = nil;
			studiesArray = [self addSpecificStudiesToArray: [[BrowserController currentBrowser].managedObjectContext executeFetchRequest:dbRequest error:&error]];
			studiesArray = [studiesArray valueForKey: @"patientUID"];
		}
		
		@catch(NSException *e)
		{
			NSLog(@"************ seriesForPredicate exception: %@", e.description);
		}
	}
	
	@try
	{
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
		
		if (studiesArray)
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, [NSPredicate predicateWithFormat: @"study.patientUID IN %@", studiesArray], nil]];
		
		[dbRequest setPredicate: predicate];
		
		error = nil;
		seriesArray = [[BrowserController currentBrowser].managedObjectContext executeFetchRequest:dbRequest error:&error];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"*********** seriesForPredicate exception: %@", e.description);
	}
	
	
	[[BrowserController currentBrowser].managedObjectContext unlock];
	
	if ([seriesArray count] > 1)
	{
		NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
		NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSArray * sortDescriptors;
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
		[sortid release];
		[sortdate release];
		
		seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
	}
	
	return seriesArray;
}

- (NSArray*)studiesForAlbum:(NSString *)albumName;
{
	return [self studiesForAlbum: albumName sortBy: nil];
}

- (NSArray*)studiesForAlbum:(NSString *)albumName sortBy: (NSString*) sortValue;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray *studiesArray = nil, *albumArray = nil;
	
	[context lock];
	
	@try
	{
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithFormat:@"name == %@", albumName]];
		error = nil;
		albumArray = [context executeFetchRequest:dbRequest error:&error];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"******** studiesForAlbum exception: %@", e.description);
	}
	
	[context unlock];
	
	NSManagedObject *album = [albumArray lastObject];
	
	if ([[album valueForKey:@"smartAlbum"] intValue] == 1)
	{
		studiesArray = [self studiesForPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [album valueForKey:@"predicateString"]] sortBy: [urlParameters objectForKey:@"order"]];
	}
	else
	{
		NSArray *originalAlbum = [[album valueForKey:@"studies"] allObjects];
		
		if (currentUser && [(NSString*) [currentUser valueForKey: @"studyPredicate"] length] > 0)
		{
			@try
			{
				studiesArray = [originalAlbum filteredArrayUsingPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [currentUser valueForKey: @"studyPredicate"]]];
				
				NSArray *specificArray = [self addSpecificStudiesToArray: [NSArray array]];
				
				for ( NSManagedObject *specificStudy in specificArray)
				{
					if ([originalAlbum containsObject: specificStudy] == YES && [studiesArray containsObject: specificStudy] == NO)
					{
						studiesArray = [studiesArray arrayByAddingObject: specificStudy];						
					}
				}
			}
			@catch( NSException *e)
			{
				NSLog( @"****** User Filter Error : %@", e);
				NSLog( @"****** NO studies will be displayed.");
				
				studiesArray = nil;
			}
		}
		else studiesArray = originalAlbum;
		
		if ([sortValue length] && [sortValue isEqualToString: @"date"] == NO)
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES selector: @selector( caseInsensitiveCompare:)] autorelease]]];
		else
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];								
	}
	
	//return [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
	return studiesArray;
}

- (void)dicomSend:(id)sender;
{
	[self updateLogEntryForStudy: [[selectedImages lastObject] valueForKeyPath: @"series.study"] withMessage: [NSString stringWithFormat: @"DICOM Send to: %@", [selectedDICOMNode objectForKey:@"Address"]]];
	
	@try
	{
		NSDictionary *todo = [NSDictionary dictionaryWithObjectsAndKeys: [selectedDICOMNode objectForKey:@"Address"], @"Address", [selectedDICOMNode objectForKey:@"TransferSyntax"], @"TransferSyntax", [selectedDICOMNode objectForKey:@"Port"], @"Port", [selectedDICOMNode objectForKey:@"AETitle"], @"AETitle", [selectedImages valueForKey: @"completePath"], @"Files", nil];
		[NSThread detachNewThreadSelector:@selector(dicomSendToDo:) toTarget:self withObject:todo];
	}
	@catch( NSException *e)
	{
		NSLog( @"***** - (void)dicomSend:(id)sender; :%@", e);
	}
}

- (void)dicomSendToDo:(NSDictionary*)todo;
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if (sendLock == nil)
		sendLock = [[NSLock alloc] init];
	
	[sendLock lock];
	
	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
															  calledAET: [todo objectForKey:@"AETitle"] 
															   hostname: [todo objectForKey:@"Address"] 
																   port: [[todo objectForKey:@"Port"] intValue] 
															filesToSend: [todo valueForKey: @"Files"]
														 transferSyntax: [[todo objectForKey:@"TransferSyntax"] intValue] 
															compression: 1.0
														extraParameters: nil];
	
	@try
	{
		[storeSCU run:self];
	}
	
	@catch(NSException *ne)
	{
		NSLog( @"WebService DICOM Send FAILED");
		NSLog( @"%@", [ne name]);
		NSLog( @"%@", [ne reason]);
	}
	
	[sendLock unlock];
	
	[storeSCU release];
	storeSCU = nil;
	
	[pool release];
}

/*+ (NSString*)encodeURLString:(NSString*)aString;
{
	if (aString == nil) aString = @"";
	
	NSMutableString *encodedString = [NSMutableString stringWithString:aString];
	[encodedString replaceOccurrencesOfString:@":" withString:@"%3A"];
	[encodedString replaceOccurrencesOfString:@"/" withString:@"%2F"];
	[encodedString replaceOccurrencesOfString:@"%" withString:@"%25"];
	[encodedString replaceOccurrencesOfString:@"#" withString:@"%23"];
	[encodedString replaceOccurrencesOfString:@";" withString:@"%3B"];
	[encodedString replaceOccurrencesOfString:@"@" withString:@"%40"];
	[encodedString replaceOccurrencesOfString:@" " withString:@"+"];
	[encodedString replaceOccurrencesOfString:@"&" withString:@"%26"];
	return encodedString;
}*/

/*+ (NSString*)decodeURLString:(NSString*)aString;
{
	if (aString == nil) aString = @"";
	
	NSMutableString *encodedString = [NSMutableString stringWithString:aString];
	[encodedString replaceOccurrencesOfString:@"%3A" withString:@":"];
	[encodedString replaceOccurrencesOfString:@"%2F" withString:@"/"];
	[encodedString replaceOccurrencesOfString:@"%25" withString:@"%"];
	[encodedString replaceOccurrencesOfString:@"%23" withString:@"#"];
	[encodedString replaceOccurrencesOfString:@"%3B" withString:@";"];
	[encodedString replaceOccurrencesOfString:@"%40" withString:@"@"];
	[encodedString replaceOccurrencesOfString:@"+" withString:@" "];
	[encodedString replaceOccurrencesOfString:@"%26" withString:@"&"];
	return encodedString;
}*/

/*+ (NSString *)encodeCharacterEntitiesIn:(NSString *)source;
{ 
	if (!source) return nil;
	else
	{
		NSMutableString *escaped = [NSMutableString stringWithString: source];
		NSArray *codes = [NSArray arrayWithObjects: @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
						  @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
						  @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
						  @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
						  @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
						  @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
						  @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
						  @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
						  @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
						  @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
						  @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
						  @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
						  @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
						  @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
		
		int i, count = [codes count];
		
		// Html
		for (i = 0; i < count; i++)
		{
			NSRange range = [source rangeOfString: [NSString stringWithFormat: @"%C", 160 + i]];
			if (range.location != NSNotFound)
			{
				[escaped replaceOccurrencesOfString: [NSString stringWithFormat: @"%C", 160 + i]
										 withString: [codes objectAtIndex: i] ];
			}
		}
		return escaped;    // Note this is autoreleased
	}
}

+ (NSString *)decodeCharacterEntitiesIn:(NSString *)source;
{ 
	if (!source) return nil;
	else if ([source rangeOfString: @"&"].location == NSNotFound) return source;
	else
	{
		NSMutableString *escaped = [NSMutableString stringWithString: source];
		NSArray *codes = [NSArray arrayWithObjects: @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
						  @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
						  @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
						  @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
						  @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
						  @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
						  @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
						  @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
						  @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
						  @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
						  @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
						  @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
						  @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
						  @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
		
		int i, count = [codes count];
		
		// Html
		for (i = 0; i < count; i++)
		{
			NSRange range = [source rangeOfString: [codes objectAtIndex: i]];
			if (range.location != NSNotFound)
			{
				[escaped replaceOccurrencesOfString: [codes objectAtIndex: i] 
										 withString: [NSString stringWithFormat: @"%C", 160 + i] ];
			}
		}
		return escaped;    // Note this is autoreleased
	}
}
*/
+ (NSString*)iPhoneCompatibleNumericalFormat:(NSString*)aString; // this is to avoid numbers to be interpreted as phone numbers
{
	NSMutableString* newString = [NSMutableString string];
	NSString *spanStart = @"<span>";
	NSString *spanEnd = @"</span>";
	NSString *letterI;
	for (int i=0; i<[aString length]; i++)
	{
		letterI = [aString substringWithRange:NSMakeRange(i, 1)];
		[newString appendString:spanStart];
		[newString appendString:letterI];
		[newString appendString:spanEnd];
	}
	return newString;
}

+ (NSString*)unbreakableStringWithString:(NSString*)aString;
{
	NSMutableString* newString = [NSMutableString stringWithString:aString];
	[newString replaceOccurrencesOfString:@" " withString:@"&nbsp;"];
	return [NSString stringWithString:newString];
}

- (void) getWidth: (int*) width height: (int*) height fromImagesArray: (NSArray*) imagesArray isiPhone: (BOOL) isiPhone;
{
	*width = 0;
	*height = 0;
	
	for ( NSNumber *im in [imagesArray valueForKey: @"width"])
		if ([im intValue] > *width) *width = [im intValue];

	for ( NSNumber *im in [imagesArray valueForKey: @"height"])
		if ([im intValue] > *height) *height = [im intValue];

	int maxWidth, maxHeight;
	int minWidth, minHeight;

	minWidth = minResolution;
	minHeight = minResolution;

	if (isiPhone)
	{
		maxWidth = 300; // for the poster frame of the movie to fit in the iphone screen (vertically)
		maxHeight = 310;
	}
	else
	{
		maxWidth = maxResolution;
		maxHeight = maxResolution;
	}

	if (*width > maxWidth)
	{
		*height = (float) *height * (float)maxWidth / (float) *width;
		*width = maxWidth;
	}

	if (*height > maxHeight)
	{
		*width = (float) *width * (float)maxHeight / (float) *height;
		*height = maxHeight;
	}

	if (*width < minWidth)
	{
		*height = (float) *height * (float)minWidth / (float) *width;
		*width = minWidth;
	}

	if (*height < minHeight)
	{
		*width = (float) *width * (float)minHeight / (float) *height;
		*height = minHeight;
	}
}

- (void) movieWithFile:(NSMutableDictionary*) dict
{
	QTMovie *e = [QTMovie movieWithFile:[dict objectForKey:@"file"] error:nil];
	[dict setObject: e forKey:@"movie"];
	
	[e detachFromCurrentThread];
}

- (void)exportMovieToiPhone:(NSString *)inFile newFileName:(NSString *)outFile;
{
    NSError *error = nil;
	
	QTMovie *aMovie = nil;
	
    // create a QTMovie from the file
	if ([NSThread isMainThread] == NO)
	{
		[QTMovie enterQTKitOnThread];
		
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: inFile, @"file", nil];
		[self performSelectorOnMainThread: @selector( movieWithFile:) withObject: dict waitUntilDone: YES];
		aMovie = [dict objectForKey:@"movie"];
		[aMovie attachToCurrentThread];
	}
	else
	{
		aMovie = [QTMovie movieWithFile: inFile error:nil];
	}
	
    if (aMovie && nil == error)
	{
		if (NO == [aMovie attributeForKey:QTMovieHasApertureModeDimensionsAttribute])
		{
			[aMovie generateApertureModeDimensions];
		}
		
		[aMovie setAttribute:QTMovieApertureModeClean forKey:QTMovieApertureModeAttribute];
		
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithBool:YES], QTMovieExport,
										   [NSNumber numberWithLong:'M4VP'], QTMovieExportType, nil];
		
		BOOL status = [aMovie writeToFile:outFile withAttributes:dictionary];
		
		if (NO == status)
		{
            // something didn't go right during the export process
            NSLog(@"%@ encountered a problem when exporting.\n", [outFile lastPathComponent]);
        }
    }
	else
	{
        // couldn't open the movie
        //NSAlert *alert = [NSAlert alertWithError:error];
        //[alert runModal];
		NSLog(@"exportMovieToiPhone Error : %@", error);
    }
	
	if ([NSThread isMainThread] == NO)
	{
		[aMovie detachFromCurrentThread];
		[QTMovie exitQTKitOnThread];
	}
}

- (void) generateMovie: (NSMutableDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (movieLock == nil)
		movieLock = [[NSMutableDictionary alloc] init];
	
	NSString *outFile = [dict objectForKey: @"outFile"];
	NSString *fileName = [dict objectForKey: @"fileName"];
	NSArray *dicomImageArray = [dict objectForKey: @"dicomImageArray"];
	BOOL isiPhone = [[dict objectForKey:@"isiPhone"] boolValue];
	
	NSMutableArray *imagesArray = [NSMutableArray array];
	
	if ([movieLock objectForKey: outFile] == nil)
		[movieLock setObject: [[[NSRecursiveLock alloc] init] autorelease] forKey: outFile];
	
	[[movieLock objectForKey: outFile] lock];
	
	@try
	{
		if (![[NSFileManager defaultManager] fileExistsAtPath: outFile] || ([[dict objectForKey: @"rows"] intValue] > 0 && [[dict objectForKey: @"columns"] intValue] > 0))
		{
			NSMutableArray *pixs = [NSMutableArray arrayWithCapacity: [dicomImageArray count]];
			
			[[[BrowserController currentBrowser] managedObjectContext] lock];
			
			for (DicomImage *im in dicomImageArray)
			{
				DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [im valueForKey:@"completePathResolved"] :0 :1 :nil :[[im valueForKey:@"frameID"] intValue] :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im];
				
				if (dcmPix)
				{
					float curWW = 0;
					float curWL = 0;
					
					if ([[im valueForKey:@"series"] valueForKey:@"windowWidth"])
					{
						curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
						curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
					}
					
					if (curWW != 0)
						[dcmPix checkImageAvailble:curWW :curWL];
					else
						[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
					
					[pixs addObject: dcmPix];
					[dcmPix release];
				}
				else
				{
					NSLog( @"****** dcmPix creation failed for file : %@", [im valueForKey:@"completePathResolved"]);
					float *imPtr = (float*)malloc( [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue] * sizeof(float));
					for ( int i = 0 ;  i < [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue]; i++)
						imPtr[ i] = i;
					
					dcmPix = [[DCMPix alloc] initWithData: imPtr :32 :[[im valueForKey: @"width"] intValue] :[[im valueForKey: @"height"] intValue] :0 :0 :0 :0 :0];
					[pixs addObject: dcmPix];
					[dcmPix release];
				}
			}
			
			[[[BrowserController currentBrowser] managedObjectContext] unlock];
			
			int width, height;
			
			if ([[dict objectForKey: @"rows"] intValue] > 0 && [[dict objectForKey: @"columns"] intValue] > 0)
			{
				width = [[dict objectForKey: @"columns"] intValue];
				height = [[dict objectForKey: @"rows"] intValue];
			}
			else 
				[self getWidth: &width height:&height fromImagesArray: dicomImageArray isiPhone: isiPhone];
			
			for (DCMPix *dcmPix in pixs)
			{
				NSImage *im = [dcmPix image];
				
				NSImage *newImage;
				
				if ([dcmPix pwidth] != width || [dcmPix pheight] != height)
					newImage = [im imageByScalingProportionallyToSize: NSMakeSize( width, height)];
				else
					newImage = im;
				
				[imagesArray addObject: newImage];
			}
			
			[[NSFileManager defaultManager] removeItemAtPath: [fileName stringByAppendingString: @" dir"] error: nil];
			[[NSFileManager defaultManager] createDirectoryAtPath: [fileName stringByAppendingString: @" dir"] attributes: nil];
			
			int inc = 0;
			for ( NSImage *img in imagesArray)
			{
				NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
				//[[img TIFFRepresentation] writeToFile: [[fileName stringByAppendingString: @" dir"] stringByAppendingPathComponent: [NSString stringWithFormat: @"%6.6d.tiff", inc]] atomically: YES];
				if ([outFile hasSuffix:@"swf"])
					[[[NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:NULL] writeToFile:[[fileName stringByAppendingString:@" dir"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%6.6d.jpg", inc]] atomically:YES];
				else
					[[img TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 1.0] writeToFile: [[fileName stringByAppendingString: @" dir"] stringByAppendingPathComponent: [NSString stringWithFormat: @"%6.6d.tiff", inc]] atomically: YES];
				inc++;
				[pool release];
			}
			
			NSTask *theTask = [[[NSTask alloc] init] autorelease];
			
			if (isiPhone)
			{
				@try
				{
					NSArray *parameters = [NSArray arrayWithObjects: fileName, @"writeMovie", [fileName stringByAppendingString: @" dir"], nil];
					
					[theTask setArguments: parameters];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
					[theTask launch];
					
					while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
				}
				@catch (NSException *e)
				{
					NSLog( @"***** writeMovie exception : %@", e);
				}
				
				theTask = [[[NSTask alloc] init] autorelease];
				
				@try
				{
					NSArray *parameters = [NSArray arrayWithObjects: outFile, @"writeMovieiPhone", fileName, nil];
					
					[theTask setArguments: parameters];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
					[theTask launch];
					
					while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
				}
				@catch (NSException *e)
				{
					NSLog( @"***** writeMovieiPhone exception : %@", e);
				}
			}
			else
			{
				@try
				{
					NSArray *parameters = [NSArray arrayWithObjects: outFile, @"writeMovie", [outFile stringByAppendingString: @" dir"], nil];
					
					[theTask setArguments: parameters];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
					[theTask launch];
					
					while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
				}
				@catch (NSException *e)
				{
					NSLog( @"***** writeMovie exception : %@", e);
				}
			}
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"***** generate movie exception : %@", e);
	}
	
	[[movieLock objectForKey: outFile] unlock];
	
	if ([[movieLock objectForKey: outFile] tryLock])
	{
		[[movieLock objectForKey: outFile] unlock];
		[movieLock removeObjectForKey: outFile];
	}
	
	[pool release];
}

- (NSString *)realm
{
	// Change the realm each day
	return [NSString stringWithFormat: @"OsiriX Web Portal (%@ - %@)" , [WebPortalConnection WebServerAddress], [BrowserController DateOfBirthFormat:[NSDate date]] ];
}

- (NSRect) centerRect: (NSRect) smallRect
               inRect: (NSRect) bigRect
{
    NSRect centerRect;
    centerRect.size = smallRect.size;

    centerRect.origin.x = (bigRect.size.width - smallRect.size.width) / 2.0;
    centerRect.origin.y = (bigRect.size.height - smallRect.size.height) / 2.0;

    return (centerRect);
}

- (NSData*) produceMovieForSeries: (NSManagedObject *) series isiPhone:(BOOL) isiPhone fileURL: (NSString*) fileURL lockReleased: (BOOL*) lockReleased
{
	NSData *data = nil;
	
	NSString *path = @"/tmp/osirixwebservices";
	[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];

	NSString *name = [NSString stringWithFormat:@"%@",[urlParameters objectForKey:@"id"]]; //[series valueForKey:@"id"];
	name = [name stringByAppendingFormat:@"-NBIM-%ld", [series valueForKey: @"dateAdded"]];

	NSMutableString *fileName = [NSMutableString stringWithString:name];
	[BrowserController replaceNotAdmitted: fileName];
	fileName = [NSMutableString stringWithString:[path stringByAppendingPathComponent: fileName]];
	[fileName appendFormat:@".%@", fileURL.pathExtension];

	NSString *outFile;

	if (isiPhone)
		outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
	else
		outFile = fileName;

	data = [NSData dataWithContentsOfFile: outFile];

	if (data == nil)
	{
		NSArray *dicomImageArray = [[series valueForKey:@"images"] allObjects];
		
		if ([dicomImageArray count] > 1)
		{
			@try
			{
				// Sort images with "instanceNumber"
				NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
				NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
				[sort release];
				dicomImageArray = [dicomImageArray sortedArrayUsingDescriptors: sortDescriptors];
				
			}
			@catch (NSException * e)
			{
				NSLog( @"%@", [e description]);
			}
			
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", urlParameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
			
			[[[BrowserController currentBrowser] managedObjectContext] unlock];	
			
			*lockReleased = YES;
			[self generateMovie: dict];
			
			data = [NSData dataWithContentsOfFile: outFile];
		}
	}

	return data;
}
/*
+(NSString*)ipv6:(NSString*)inadd {
	const char* inaddc = [[node valueForKey:@"Address"] UTF8String];
	
	struct sockaddr_in service;
	bzero((char*)&service, sizeof(service));
	
	service.sin_family = AF_INET6;
	
}*/

+(NSDictionary*)ExtractParams:(NSString*)paramsString {
	if (!paramsString.length)
		return [NSDictionary dictionary];
	
	NSArray* paramsArray = [paramsString componentsSeparatedByString:@"&"];
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:paramsArray.count];

	for (NSString* param in paramsArray)
	{
		NSArray* paramArray = [param componentsSeparatedByString:@"="];
		
		NSString* paramName = [[[paramArray objectAtIndex:0] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString* paramValue = paramArray.count > 1? [[[paramArray objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : (NSString*)[NSNull null];
		
		NSMutableArray* prevVal = [params objectForKey:paramName];
		if (prevVal && ![prevVal isKindOfClass:[NSMutableArray class]]) {
			prevVal = [NSMutableArray arrayWithObject:prevVal];
			[params setObject:prevVal forKey:paramName];
		}
		
		if (prevVal)
			[prevVal addObject:paramValue];
		else [params setObject:paramValue forKey:paramName];
	}
	
	return params;
}

+(NSArray*)MakeArray:(id)obj {
	if ([obj isKindOfClass:[NSArray class]])
		return obj;
	
	if (obj == nil)
		return [NSArray array];
	
	return [NSArray arrayWithObject:obj];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	WebPortalResponse* response = [[[WebPortalResponse alloc] init] autorelease];
	[response setSessionId:session.sid];

	BOOL lockReleased = NO, waitBeforeReturning = NO;
	
	NSString *contentRange = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Range") autorelease];
	NSString *userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	
	NSScanner *scan = [NSScanner scannerWithString:userAgent];
	BOOL isSafari = NO;
	BOOL isMacOS = NO;
	
	while(![scan isAtEnd])
	{
		if (!isSafari) isSafari = [scan scanString:@"Safari/" intoString:nil];
		if (!isMacOS) isMacOS = [scan scanString:@"Mac OS" intoString: nil];
		[scan setScanLocation:[scan scanLocation]+1];
	}
	
	scan = [NSScanner scannerWithString:userAgent];
	BOOL isMobile = NO;
	while(![scan isAtEnd] && !isMobile)
	{
		isMobile = [scan scanString:@"Mobile/" intoString:nil];
		[scan setScanLocation:[scan scanLocation]+1];
	}
	
	BOOL isiPhone = isSafari && isMobile; // works only with Mobile Safari
	
	if (!isiPhone) // look
	{
		scan = [NSScanner scannerWithString:userAgent];
		BOOL isiPhoneOS = NO;
		while(![scan isAtEnd] && !isiPhoneOS)
		{
			isiPhoneOS = [scan scanString:@"iPhone OS" intoString:nil];
			[scan setScanLocation:[scan scanLocation]+1];
		}
		
		//		scan = [NSScanner scannerWithString:userAgent];
		//		BOOL isWebKit = NO;
		//		while(![scan isAtEnd] && !isWebKit)
		//		{
		//			isWebKit = [scan scanString:@"AppleWebKit" intoString:nil];
		//			[scan setScanLocation:[scan scanLocation]+1];
		//		}
		
		isiPhone = isiPhoneOS;
	}
	
	int totalLength;
	
	NSString *url = [[(id)CFHTTPMessageCopyRequestURL(request) autorelease] description];
	
	DLog(@"HTTP %@ %@", method, url);
	
	// parse the URL to find the parameters (if any)
	NSArray *urlComponenents = [url componentsSeparatedByString:@"?"];
	NSString *parameterString = NULL;
	if ([urlComponenents count] == 2) parameterString = [urlComponenents lastObject];
	
	[urlParameters release];
	urlParameters = [[NSMutableDictionary dictionary] retain];
	
	// GET params
	[urlParameters addEntriesFromDictionary:[WebPortalConnection ExtractParams:parameterString]];
	
	// POST params
	if ([method isEqualToString: @"POST"] && multipartData && [multipartData count] == 1) // through POST
	{
		NSString* postParamsString = [[[NSString alloc] initWithBytes: [[multipartData lastObject] bytes] length: [(NSData*) [multipartData lastObject] length] encoding: NSUTF8StringEncoding] autorelease];
		[urlParameters addEntriesFromDictionary:[WebPortalConnection ExtractParams:postParamsString]];
	}
	
	// find the name of the requested file
	urlComponenents = [(NSString*)[urlComponenents objectAtIndex:0] componentsSeparatedByString:@"?"];
	NSString *fileURL = [urlComponenents objectAtIndex:0];
	
	NSString *reportType;
	NSData *data = nil;
	BOOL err = YES;
	NSString* dataMime = NULL;
	
	// SECURITY : we cannot allow the client to read any file on the hard disk !?!?!!!
	fileURL = [fileURL stringByReplacingOccurrencesOfString:@".." withString:@""];

	if ([fileURL isEqualToString:@"/"])
		fileURL = @"/index";
	
	NSString* ext = [fileURL pathExtension];
	if ([ext compare:@"jar" options:NSCaseInsensitiveSearch|NSLiteralSearch range:ext.range] == NSOrderedSame)
		dataMime = @"application/java-archive";
	if ([ext compare:@"swf" options:NSCaseInsensitiveSearch|NSLiteralSearch range:ext.range] == NSOrderedSame)
		dataMime = @"application/x-shockwave-flash";
	
	if ([fileURL hasPrefix:@"/weasis/"])
	{
		data = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileURL]];
		err = !data;
	}
	else
	{
		[[[BrowserController currentBrowser] managedObjectContext] lock];
		
		@try
		{
			if (![fileURL rangeOfString:@".pvt."].length)
				data = [WebPortalConnection WebServicesHTMLData:fileURL];
			err = !data;
			
			#pragma mark index
			if ([fileURL isEqualToString: @"/index"])
			{
				NSMutableString* templateString = [self webServicesHTMLMutableString:@"index.html"];
				
				[WebPortalData mutableString:templateString block:@"AuthorizedRestorePasswordWebServer" setVisible:[[NSUserDefaults standardUserDefaults] boolForKey:@"restorePasswordWebServer"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"passwordWebServer"]];
				[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:@"OsiriX Web Portal"];
				
				data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
				
				err = NO;
			}
			
			#pragma mark main
			if ([fileURL isEqualToString: @"/main"])
			{
				NSMutableString *templateString = [self webServicesHTMLMutableString:@"main.html"];
				
				if (!currentUser || currentUser.uploadDICOM.boolValue)
					[self supportsPOST:NULL withSize:0];

				NSMutableDictionary* tokens = [NSMutableDictionary dictionary];

				[tokens setObject:NSLocalizedString(@"OsiriX Web Portal", @"Web Portal, main page, title") forKey:@"PageTitle"];
				[tokens setObject:currentUser forKey:@"User"];
				[tokens setBool: currentUser.uploadDICOM && !isiPhone forKey:@"AuthorizedUploadDICOMFiles"];
				[tokens setBool: !currentUser || [[self studiesForPredicate:[NSPredicate predicateWithValue:YES] sortBy:nil] count] forKey:@"accessStudies"];
				
				NSArray* unfilteredAlbums = [[BrowserController currentBrowser] albumArray];
				NSMutableArray* albums = [NSMutableArray array];
				for (NSArray* album in unfilteredAlbums) {
		//			NSLog(@"DicomAlbum]]] %@", album.description);
					if ([[album valueForKey:@"name"] isEqualToString:NSLocalizedString(@"Database", nil)])
						continue;
					else [albums addObject:[WebPortalProxy createWithObject:album transformer:[AlbumTransformer create]]];
				}
				[tokens setObject:albums forKey:@"Albums"];
				
				[WebPortalData mutableString:templateString evaluateTokensWithDictionary:tokens];
				
				data = [templateString dataUsingEncoding:NSUTF8StringEncoding];
				err = NO;
			}
			
			#pragma mark wado
			// wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX
			// 127.0.0.1:3333/wado?requestType=WADO&frameNumber=1&studyUID=2.16.840.1.113669.632.20.1211.10000591592&seriesUID=1.3.6.1.4.1.19291.2.1.2.2867252960399100001&objectUID=1.3.6.1.4.1.19291.2.1.3.2867252960616100004
			else if ([fileURL hasSuffix: @"/wado"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"wadoServer"])
			{
				if ([[[urlParameters objectForKey:@"requestType"] lowercaseString] isEqualToString: @"wado"])
				{
					NSString *studyUID = [urlParameters objectForKey:@"studyUID"];
					NSString *seriesUID = [urlParameters objectForKey:@"seriesUID"];
					NSString *objectUID = [urlParameters objectForKey:@"objectUID"];
					
					if (objectUID == nil)
						NSLog( @"***** WADO with objectUID == nil -> wado will fail");
					
					NSString *contentType = [[[[urlParameters objectForKey:@"contentType"] lowercaseString] componentsSeparatedByString: @","] objectAtIndex: 0];
//					contentType = [contentType stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					int rows = [[urlParameters objectForKey:@"rows"] intValue];
					int columns = [[urlParameters objectForKey:@"columns"] intValue];
					int windowCenter = [[urlParameters objectForKey:@"windowCenter"] intValue];
					int windowWidth = [[urlParameters objectForKey:@"windowWidth"] intValue];
					int frameNumber = [[urlParameters objectForKey:@"frameNumber"] intValue];	// -> OsiriX stores frames as images
					int imageQuality = DCMLosslessQuality;
					
					if ([urlParameters objectForKey:@"imageQuality"])
					{
						if ([[urlParameters objectForKey:@"imageQuality"] intValue] > 80)
							imageQuality = DCMLosslessQuality;
						else if ([[urlParameters objectForKey:@"imageQuality"] intValue] > 60)
							imageQuality = DCMHighQuality;
						else if ([[urlParameters objectForKey:@"imageQuality"] intValue] > 30)
							imageQuality = DCMMediumQuality;
						else if ([[urlParameters objectForKey:@"imageQuality"] intValue] >= 0)
							imageQuality = DCMLowQuality;
					}
					
					NSString *transferSyntax = [[urlParameters objectForKey:@"transferSyntax"] lowercaseString];
					NSString *useOrig = [[urlParameters objectForKey:@"useOrig"] lowercaseString];
					
					NSError *error = nil;
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
					
					@try
					{
						NSMutableDictionary *imageCache = nil;
						NSArray *images = nil;
						
						if (wadoJPEGCache == nil)
							wadoJPEGCache = [[NSMutableDictionary alloc] initWithCapacity: WADOCACHESIZE];
						
						if ([wadoJPEGCache count] > WADOCACHESIZE)
							[wadoJPEGCache removeAllObjects];
						
						if ([contentType length] == 0 || [contentType isEqualToString: @"image/jpeg"] || [contentType isEqualToString: @"image/png"] || [contentType isEqualToString: @"image/gif"] || [contentType isEqualToString: @"image/jp2"])
						{
							imageCache = [wadoJPEGCache objectForKey: [objectUID stringByAppendingFormat: @"%d", frameNumber]];
						}
						
						if (imageCache == nil)
						{
							if (studyUID)
								[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
							else
								[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
							
							NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error: &error];
							
							if ([studies count] == 0)
								NSLog( @"****** WADO Server : study not found");
							
							if ([studies count] > 1)
								NSLog( @"****** WADO Server : more than 1 study with same uid");
							
							NSArray *allSeries = [[[studies lastObject] valueForKey: @"series"] allObjects];
							
							if (seriesUID)
								allSeries = [allSeries filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", seriesUID]];
							
							NSArray *allImages = [NSArray array];
							for ( id series in allSeries)
								allImages = [allImages arrayByAddingObjectsFromArray: [[series valueForKey: @"images"] allObjects]];
							
							NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: objectUID]] customSelector: @selector( isEqualToSopInstanceUID:)];
							NSPredicate *NotNilPredicate = [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"];
							
							images = [[allImages filteredArrayUsingPredicate: NotNilPredicate] filteredArrayUsingPredicate: predicate];
							
							if ([images count] > 1)
							{
								images = [images sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"instanceNumber" ascending:YES] autorelease]]];
								
								if (frameNumber < [images count])
									images = [NSArray arrayWithObject: [images objectAtIndex: frameNumber]];
							}
							
							if ([images count])
							{
								[WebPortalConnection updateLogEntryForStudy: [studies lastObject] withMessage: @"WADO Send" forUser: nil ip: [asyncSocket connectedHost]];
							}
						}
						
						if ([images count] || imageCache != nil)
						{
							if ([contentType isEqualToString: @"application/dicom"])
							{
								if ([useOrig isEqualToString: @"true"] || [useOrig isEqualToString: @"1"] || [useOrig isEqualToString: @"yes"])
								{
									data = [NSData dataWithContentsOfFile: [[images lastObject] valueForKey: @"completePath"]];
								}
								else
								{
									DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS: transferSyntax] autorelease];
									
									if ([ts isEqualToTransferSyntax: [DCMTransferSyntax JPEG2000LosslessTransferSyntax]] ||
									   [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEG2000LossyTransferSyntax]] ||
									   [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGBaselineTransferSyntax]] ||
									   [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGLossless14TransferSyntax]] ||
									   [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGBaselineTransferSyntax]])
									{
										
									}
									else // Explicit VR Little Endian
										ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
									
									data = [[BrowserController currentBrowser] getDICOMFile: [[images lastObject] valueForKey: @"completePath"] inSyntax: ts.transferSyntax quality: imageQuality];
								}
								err = NO;
							}
							else if ([contentType isEqualToString: @"video/mpeg"])
							{
								DicomImage *im = [images lastObject];
								
								NSArray *dicomImageArray = [[[im valueForKey: @"series"] valueForKey:@"images"] allObjects];
								
								@try
								{
									// Sort images with "instanceNumber"
									NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
									NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
									[sort release];
									dicomImageArray = [dicomImageArray sortedArrayUsingDescriptors: sortDescriptors];
									
								}
								@catch (NSException * e)
								{
									NSLog( @"%@", [e description]);
								}
								
								if ([dicomImageArray count] > 1)
								{
									NSString *path = @"/tmp/osirixwebservices";
									[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
									
									NSString *name = [NSString stringWithFormat:@"%@",[urlParameters objectForKey:@"id"]];
									name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
									
									NSMutableString *fileName = [NSMutableString stringWithString: [path stringByAppendingPathComponent:name]];
									
									[BrowserController replaceNotAdmitted: fileName];
									
									[fileName appendString:@".mov"];
									
									NSString *outFile;
									if (isiPhone)
										outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
									else
										outFile = fileName;
									
									NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", urlParameters, @"parameters", dicomImageArray, @"dicomImageArray", [NSNumber numberWithInt: rows], @"rows", [NSNumber numberWithInt: columns], @"columns", nil];
									
									lockReleased = YES;
									[[[BrowserController currentBrowser] managedObjectContext] unlock];
									
									[self generateMovie: dict];
									
									data = [NSData dataWithContentsOfFile: outFile];
									
									if (data)
										err = NO;
								}
							}
							else // image/jpeg
							{
								DCMPix* dcmPix = [imageCache valueForKey: @"dcmPix"];
								
								if (dcmPix)
								{
									// It's in the cache
								}
								else if ([images count] > 0)
								{
									DicomImage *im = [images lastObject];
									
									dcmPix = [[[DCMPix alloc] initWithPath: [im valueForKey: @"completePathResolved"] :0 :1 :nil :frameNumber :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im] autorelease];
									
									if (dcmPix == nil)
									{
										NSLog( @"****** dcmPix creation failed for file : %@", [im valueForKey:@"completePathResolved"]);
										float *imPtr = (float*)malloc( [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue] * sizeof(float));
										for ( int i = 0 ;  i < [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue]; i++)
											imPtr[ i] = i;
										
										dcmPix = [[[DCMPix alloc] initWithData: imPtr :32 :[[im valueForKey: @"width"] intValue] :[[im valueForKey: @"height"] intValue] :0 :0 :0 :0 :0] autorelease];
									}
									
									imageCache = [NSMutableDictionary dictionaryWithObject: dcmPix forKey: @"dcmPix"];
									
									[wadoJPEGCache setObject: imageCache forKey: [objectUID stringByAppendingFormat: @"%d", frameNumber]];
								}
								
								if (dcmPix)
								{
									NSImage *image = nil;
									NSManagedObject *im =  [dcmPix imageObj];
									
									float curWW = windowWidth;
									float curWL = windowCenter;
									
									if (curWW == 0 && [[im valueForKey:@"series"] valueForKey:@"windowWidth"])
									{
										curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
										curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
									}
									
									if (curWW == 0)
									{
										curWW = [dcmPix savedWW];
										curWL = [dcmPix savedWL];
									}
									
									data = [imageCache objectForKey: [NSString stringWithFormat: @"%@ %f %f %d %d %d", contentType, curWW, curWL, columns, rows, frameNumber]];
									
									if (data == nil)
									{
										[dcmPix checkImageAvailble: curWW :curWL];
										
										image = [dcmPix image];
										float width = [image size].width;
										float height = [image size].height;
										
										int maxWidth = columns;
										int maxHeight = rows;
										
										BOOL resize = NO;
										
										if (width > maxWidth && maxWidth > 0)
										{
											height =  height * maxWidth / width;
											width = maxWidth;
											resize = YES;
										}
										
										if (height > maxHeight && maxHeight > 0)
										{
											width = width * maxHeight / height;
											height = maxHeight;
											resize = YES;
										}
										
										NSImage *newImage;
										
										if (resize)
											newImage = [image imageByScalingProportionallyToSize: NSMakeSize(width, height)];
										else
											newImage = image;
										
										NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]];
										NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
										
										if ([contentType isEqualToString: @"image/gif"])
											data = [imageRep representationUsingType: NSGIFFileType properties:imageProps];
										else if ([contentType isEqualToString: @"image/png"])
											data = [imageRep representationUsingType: NSPNGFileType properties:imageProps];
										else if ([contentType isEqualToString: @"image/jp2"])
											data = [imageRep representationUsingType: NSJPEG2000FileType properties:imageProps];
										else
											data = [imageRep representationUsingType: NSJPEGFileType properties:imageProps];
										
										[imageCache setObject: data forKey: [NSString stringWithFormat: @"%@ %f %f %d %d %d", contentType, curWW, curWL, columns, rows, frameNumber]];
									}
									
									if (data)
										err = NO;
								}
							}
						}
						else NSLog( @"****** WADO Server : image uid not found !");
					
						if (err)
						{
							data = [NSData data];
							err = NO;
						}
					}
					@catch (NSException * e)
					{
						NSLog( @"****** WADO Server exception: %@", e);
					}
				}
			}
			
			#pragma mark studyList
			else if ([fileURL isEqualToString:@"/studyList"] || [fileURL isEqualToString:@"/studyList.json"])
			{
				NSPredicate *browsePredicate;
				NSString *pageTitle;
				if ([[urlParameters objectForKey:@"browse"] isEqualToString: @"newAddedStudies"] && [[urlParameters objectForKey:@"browseParameter"] doubleValue] > 0)
				{
					browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [[urlParameters objectForKey:@"browseParameter"] doubleValue]];
					pageTitle = NSLocalizedString( @"New Studies Available", nil);
				}
				else if ([(NSString*)[urlParameters objectForKey:@"browse"] isEqualToString:@"today"])
				{
					browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [self startOfDay:[NSCalendarDate calendarDate]]];
					pageTitle = NSLocalizedString( @"Today", nil);
				}
				else if ([(NSString*)[urlParameters objectForKey:@"browse"] isEqualToString:@"6hours"])
				{
					NSCalendarDate *now = [NSCalendarDate calendarDate];
					browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:[now hourOfDay]-6 minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:nil] timeIntervalSinceReferenceDate]];
					pageTitle = NSLocalizedString( @"Last 6 hours", nil);
				}
				else if ([(NSString*)[urlParameters objectForKey:@"browse"] isEqualToString:@"all"])
				{
					browsePredicate = [NSPredicate predicateWithValue:YES];
					pageTitle = NSLocalizedString(@"Study List", nil);
				}
				else if ([urlParameters objectForKey:@"search"])
				{
					NSMutableString *search = [NSMutableString string];
					NSString *searchString = [urlParameters objectForKey:@"search"];
					
					NSArray *components = [searchString componentsSeparatedByString:@" "];
					NSMutableArray *newComponents = [NSMutableArray array];
					for (NSString *comp in components)
					{
						if (![comp isEqualToString:@""])
							[newComponents addObject:comp];
					}
					
					searchString = [newComponents componentsJoinedByString:@" "];
					
					[search appendFormat:@"name CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
					browsePredicate = [NSPredicate predicateWithFormat:search];
					pageTitle = NSLocalizedString(@"Search Result", nil);
				}
				else if ([urlParameters objectForKey:@"searchID"])
				{
					NSMutableString *search = [NSMutableString string];
					NSString *searchString = [NSString stringWithString:[urlParameters objectForKey:@"searchID"]];
					
					NSArray *components = [searchString componentsSeparatedByString:@" "];
					NSMutableArray *newComponents = [NSMutableArray array];
					for (NSString *comp in components)
					{
						if (![comp isEqualToString:@""])
							[newComponents addObject:comp];
					}
					
					searchString = [newComponents componentsJoinedByString:@" "];
					
					[search appendFormat:@"patientID CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
					browsePredicate = [NSPredicate predicateWithFormat:search];
					pageTitle = NSLocalizedString(@"Search Result", nil);
				}
				else if ([urlParameters objectForKey:@"searchAccessionNumber"])
				{
					NSMutableString *search = [NSMutableString string];
					NSString *searchString = [NSString stringWithString:[urlParameters objectForKey:@"searchAccessionNumber"]];
					
					NSArray *components = [searchString componentsSeparatedByString:@" "];
					NSMutableArray *newComponents = [NSMutableArray array];
					for (NSString *comp in components)
					{
						if (![comp isEqualToString:@""])
							[newComponents addObject:comp];
					}
					
					searchString = [newComponents componentsJoinedByString:@" "];
					
					[search appendFormat:@"accessionNumber CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
					browsePredicate = [NSPredicate predicateWithFormat:search];
					pageTitle = NSLocalizedString(@"Search Result", nil);
				}
				else
				{
					browsePredicate = [NSPredicate predicateWithValue:YES];
					pageTitle = NSLocalizedString(@"Study List", nil);
				}
				
				if ([fileURL isEqualToString:@"/studyList"])
				{
					NSMutableString *html = [self htmlStudyListForStudies: [self studiesForPredicate: browsePredicate sortBy: [urlParameters objectForKey:@"order"]] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", [NSNumber numberWithBool: isiPhone], @"iPhone", nil]];
					
					if ([urlParameters objectForKey:@"album"])
					{
						if (![[urlParameters objectForKey:@"album"] isEqualToString:@""])
						{
							html = [self htmlStudyListForStudies: [self studiesForAlbum:[urlParameters objectForKey:@"album"] sortBy:[urlParameters objectForKey:@"order"]] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
							pageTitle = [urlParameters objectForKey:@"album"];
						}
					}
					
					[html replaceOccurrencesOfString:@"%PageTitle%" withString:NotNil(pageTitle)];
					
					if ([urlParameters objectForKey:@"browse"])[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[urlParameters objectForKey:@"browse"]]];
					else [html replaceOccurrencesOfString:@"%browse%" withString:@""]; 
					
					if ([urlParameters objectForKey:@"browseParameter"])[html replaceOccurrencesOfString:@"%browseParameter%" withString:[NSString stringWithFormat:@"&browseParameter=%@",[urlParameters objectForKey:@"browseParameter"]]];
					else [html replaceOccurrencesOfString:@"%browseParameter%" withString:@""]; 
					
					if ([urlParameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[urlParameters objectForKey:@"search"]]];
					else [html replaceOccurrencesOfString:@"%search%" withString:@""];
					
					if ([urlParameters objectForKey:@"album"])[html replaceOccurrencesOfString:@"%album%" withString:[NSString stringWithFormat:@"&album=%@",[urlParameters objectForKey:@"album"]]];
					else [html replaceOccurrencesOfString:@"%album%" withString:@""];

					if ([urlParameters objectForKey:@"order"])
					{
						if ([[urlParameters objectForKey:@"order"] isEqualToString:@"name"])
						{
							[html replaceOccurrencesOfString:@"%orderByName%" withString:@"sortedBy"];
							[html replaceOccurrencesOfString:@"%orderByDate%" withString:@""];
						}
						else
						{
							[html replaceOccurrencesOfString:@"%orderByDate%" withString:@"sortedBy"];
							[html replaceOccurrencesOfString:@"%orderByName%" withString:@""];
						}
					}
					else
					{
						[html replaceOccurrencesOfString:@"%orderByDate%" withString:@"sortedBy"];
						[html replaceOccurrencesOfString:@"%orderByName%" withString:@""];
					}
					
					data = [html dataUsingEncoding:NSUTF8StringEncoding];
					err = NO;
				}
				#pragma mark     JSON
				else if ([fileURL isEqualToString:@"/studyList.json"])
				{
					NSArray *studies;
					
					if ([urlParameters objectForKey:@"album"])
					{
						if (![[urlParameters objectForKey:@"album"] isEqualToString:@""])
						{
							studies = [self studiesForAlbum:[urlParameters objectForKey:@"album"] sortBy:[urlParameters objectForKey:@"order"]];
						}
					}
					else
						studies = [self studiesForPredicate:browsePredicate sortBy:[urlParameters objectForKey:@"order"]];
					NSString *json = [self jsonStudyListForStudies:studies];
					data = [json dataUsingEncoding:NSUTF8StringEncoding];
					err = NO;
				}
			}
		#pragma mark study
			else if ([fileURL isEqualToString:@"/study"])
			{
				NSString *message = nil;
				
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				#pragma mark dicomSend
				if ([[urlParameters allKeys] containsObject:@"dicomSend"])
				{
					NSString *dicomDestination = [urlParameters objectForKey:@"dicomDestination"];
					NSArray *tempArray = [dicomDestination componentsSeparatedByString:@":"];
					
					if ([tempArray count] >= 4)
					{
						NSString *dicomDestinationAddress = [tempArray objectAtIndex:0];
						NSString *dicomDestinationPort = [tempArray objectAtIndex:1];
						NSString *dicomDestinationAETitle = [tempArray objectAtIndex:2];
						NSString *dicomDestinationSyntax = [tempArray objectAtIndex:3];
						
						if (dicomDestinationAddress && dicomDestinationPort && dicomDestinationAETitle && dicomDestinationSyntax)
						{
							[selectedDICOMNode release];
							selectedDICOMNode = [NSMutableDictionary dictionary];
							[selectedDICOMNode setObject:dicomDestinationAddress forKey:@"Address"];
							[selectedDICOMNode setObject:dicomDestinationPort forKey:@"Port"];
							[selectedDICOMNode setObject:dicomDestinationAETitle forKey:@"AETitle"];
							[selectedDICOMNode setObject:dicomDestinationSyntax forKey:@"TransferSyntax"];
							[selectedDICOMNode retain];
							
							[selectedImages release];
							selectedImages = [NSMutableArray array];
							NSArray *seriesArray;
							for (NSString* selectedID in [WebPortalConnection MakeArray:[urlParameters objectForKey:@"selected"]])
							{
								NSPredicate *pred = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"id"], selectedID];
								
								seriesArray = [self seriesForPredicate: pred];
								for (NSManagedObject *series in seriesArray)
								{
									NSArray *images = [[series valueForKey:@"images"] allObjects];
									[selectedImages addObjectsFromArray:images];
								}
							}
							
							[selectedImages retain];
							
							if ([selectedImages count])
							{
								[self dicomSend: self];
								
								message = [NSString stringWithFormat: NSLocalizedString( @"Images sent to DICOM node: %@ - %@", nil), dicomDestinationAddress, dicomDestinationAETitle];
							}
							else
								message = [NSString stringWithFormat: NSLocalizedString( @"No images selected ! Select one or more series.", nil), dicomDestinationAddress, dicomDestinationAETitle];

						}
						
						if (message == nil)
							message = [NSString stringWithFormat: NSLocalizedString( @"DICOM Transfer failed to node : %@ - %@", nil), dicomDestinationAddress, dicomDestinationAETitle];
					}
					
					if (message == nil)
						message = [NSString stringWithFormat: NSLocalizedString( @"DICOM Transfer failed to node : cannot identify DICOM node.", nil)];
				}
				
				NSArray *studies = [self studiesForPredicate:browsePredicate];
				
				if ([studies count] == 1)
				{
					if ([[urlParameters allKeys] containsObject:@"shareStudy"])
					{
						NSString *userDestination = [urlParameters objectForKey:@"userDestination"];
						NSString *messageFromUser = [urlParameters objectForKey:@"message"];
						
						if (userDestination)
						{
							id study = [studies lastObject];
							
							// Find this user
							NSError *error = nil;
							NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
							[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"name == %@", userDestination]];
							
							error = nil;
							NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
							
							if ([users count] == 1)
							{
								// Add study to specific study list for this user
								NSManagedObject *destUser = [users lastObject];
								
								NSArray *studiesArrayStudyInstanceUID = [[[destUser valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
								NSArray *studiesArrayPatientUID = [[[destUser valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
								
								NSManagedObject *studyLink = nil;
								
								if ([studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
								{
									studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: [BrowserController currentBrowser].userManagedObjectContext];
								
									[studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
									[studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
								}
								else studyLink = [studiesArrayStudyInstanceUID objectAtIndex: [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]]];
								
								[studyLink setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]] forKey: @"dateAdded"];
								[studyLink setValue: destUser forKey: @"user"];
								
								@try
								{
									[[BrowserController currentBrowser].userManagedObjectContext save: nil];
								}
								@catch (NSException * e)
								{
									NSLog( @"*********** [[BrowserController currentBrowser].userManagedObjectContext save: nil]");
								}
								
								// Send the email
								
								[WebPortalConnection sendNotificationsEmailsTo: users aboutStudies: [NSArray arrayWithObject: study] predicate: nil message: [messageFromUser stringByAppendingFormat: @"\r\r\r%@\r\r%%URLsList%%", NSLocalizedString( @"To view this study, click on the following link:", nil)] replyTo: [currentUser valueForKey: @"email"] customText:nil webServerAddress:self.webServerAddress];
								
								[WebPortalConnection updateLogEntryForStudy: study withMessage: [NSString stringWithFormat: @"Share Study with User: %@", userDestination] forUser: [currentUser valueForKey: @"name"] ip: [asyncSocket connectedHost]];
								
								message = [NSString stringWithFormat: NSLocalizedString( @"This study is now shared with %@.", nil), userDestination];
							}
						}
						
						if (message == nil)
							message = [NSString stringWithFormat: NSLocalizedString( @"Failed to share this study with %@.", nil), userDestination];
					}
				
				
					[self updateLogEntryForStudy: [studies lastObject] withMessage: @"Display Study"];
										
					NSMutableString *html = [self htmlStudy:[studies lastObject] parameters:urlParameters settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"iPhone", [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
					
					[html replaceOccurrencesOfString:@"%StudyID%" withString:NotNil([urlParameters objectForKey:@"id"])];
					
	//				if ([[urlParameters allKeys] containsObject:@"dicomSend"])
	//				{
	//					NSString *dicomDestination = [urlParameters objectForKey:@"dicomDestination"];
	//					NSArray *tempArray = [dicomDestination componentsSeparatedByString:@":"];
	//					
	//					if ([tempArray count] >= 3)
	//					{
	//						NSString *dicomDestinationAETitle = [tempArray objectAtIndex:2];
	//						NSString *dicomDestinationAddress = [tempArray objectAtIndex:0];
	//					}
	//				}
					
					[html replaceOccurrencesOfString:@"%LocalizedLabel_SendStatus%" withString:NotNil(message)];
					
					if ([urlParameters objectForKey:@"browse"])
						[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[urlParameters objectForKey:@"browse"]]];
					else
						[html replaceOccurrencesOfString:@"%browse%" withString:@""];
					
					if ([urlParameters objectForKey:@"browseParameter"])[html replaceOccurrencesOfString:@"%browseParameter%" withString:[NSString stringWithFormat:@"&browseParameter=%@",[urlParameters objectForKey:@"browseParameter"]]];
					else [html replaceOccurrencesOfString:@"%browseParameter%" withString:@""];
					
					if ([urlParameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[urlParameters objectForKey:@"search"]]];
					else [html replaceOccurrencesOfString:@"%search%" withString:@""];
					
					data = [html dataUsingEncoding:NSUTF8StringEncoding];
				}
				err = NO;
			}
		#pragma mark thumbnail
			else if ([fileURL isEqualToString:@"/thumbnail"])
			{
				NSPredicate *browsePredicate = nil;
				NSString *seriesInstanceUID = nil, *studyInstanceUID = nil;
				
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					if ([[urlParameters allKeys] containsObject:@"studyID"])
					{
						if (thumbnailCache == nil)
							thumbnailCache = [[NSMutableDictionary alloc] initWithCapacity: THUMBNAILCACHE];
						
						if ([thumbnailCache count] > THUMBNAILCACHE)
							[thumbnailCache removeAllObjects];
						
						if ([thumbnailCache objectForKey: [urlParameters objectForKey:@"studyID"]])
						{
							NSDictionary *seriesThumbnail = [thumbnailCache objectForKey: [urlParameters objectForKey:@"studyID"]];
							
							if ([seriesThumbnail objectForKey: [urlParameters objectForKey:@"id"]])
								data = [seriesThumbnail objectForKey: [urlParameters objectForKey:@"id"]];
						}
						
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [urlParameters objectForKey:@"studyID"]];// AND seriesInstanceUID == %@", [urlParameters objectForKey:@"studyID"], [urlParameters objectForKey:@"id"]];
						
						studyInstanceUID = [urlParameters objectForKey:@"studyID"];
						seriesInstanceUID = [urlParameters objectForKey:@"id"];
					}
					else
					{
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
						studyInstanceUID = [urlParameters objectForKey:@"id"];
					}
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
					
				if (data == nil)
				{
					NSArray *series = [self seriesForPredicate:browsePredicate];
					
					if ([series count]  > 0)
					{
						NSMutableDictionary *seriesThumbnails = [NSMutableDictionary dictionary];
						
						for ( DicomSeries *s in series)
						{
							NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [s valueForKey:@"thumbnail"]];
							
							NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
							
							NSData *dataThumbnail = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
							
							if (dataThumbnail && [s valueForKey: @"seriesInstanceUID"])
							{
								[seriesThumbnails setObject: dataThumbnail forKey: [s valueForKey: @"seriesInstanceUID"]];
							
								if ([seriesInstanceUID isEqualToString: [s valueForKey: @"seriesInstanceUID"]])
									data = dataThumbnail;
							}
						}
						
						if (studyInstanceUID && seriesThumbnails)
							[thumbnailCache setObject: seriesThumbnails forKey: studyInstanceUID];
					}
				}
				err = NO;
			}
		#pragma mark series.pdf
			else if ([fileURL isEqualToString:@"/series.pdf"])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					if ([[urlParameters allKeys] containsObject:@"studyID"])
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"studyID"], [urlParameters objectForKey:@"id"]];
					else
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [urlParameters objectForKey:@"id"] ];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				NSArray *series = [self seriesForPredicate: browsePredicate];
				
				if ([series count] == 1)
				{
					if ([DCMAbstractSyntaxUID isPDF: [[series lastObject] valueForKey: @"seriesSOPClassUID"]])
					{
						DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"]  decodingPixelData:NO];
					
						if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
						{
							data = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
							
							if (data)
								err = NO;
						}
					}
					
					if ([DCMAbstractSyntaxUID isStructuredReport: [[series lastObject] valueForKey: @"seriesSOPClassUID"]])
					{
						if ([[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/dicomsr_osirix/"] == NO)
							[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/dicomsr_osirix/" attributes: nil];
					
						NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [[[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"] lastPathComponent]] stringByAppendingPathExtension: @"html"];
						
						if ([[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
						{
							NSTask *aTask = [[[NSTask alloc] init] autorelease];		
							[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
							[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
							[aTask setArguments: [NSArray arrayWithObjects: [[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"], htmlpath, nil]];		
							[aTask launch];
							[aTask waitUntilExit];		
							[aTask interrupt];
						}
						
						if ([[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
						{
							NSTask *aTask = [[[NSTask alloc] init] autorelease];
							[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
							[aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
							[aTask launch];
							[aTask waitUntilExit];		
							[aTask interrupt];
						}
						
						data = [NSData dataWithContentsOfFile: [htmlpath stringByAppendingPathExtension: @"pdf"]];
							
						if (data)
							err = NO;
					}
				}
				
				if (err)
				{
					data = [NSData data];
					err = NO;
				}
			}
		#pragma mark series
			else if ([fileURL isEqualToString:@"/series"] || [fileURL isEqualToString:@"/series.json"])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					if ([[urlParameters allKeys] containsObject:@"studyID"])
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"studyID"], [urlParameters objectForKey:@"id"]];
					else
						browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				NSArray *series = [self seriesForPredicate:browsePredicate];
				NSArray *imagesArray = [[[series lastObject] valueForKey:@"images"] allObjects];

				if ([fileURL isEqualToString:@"/series"])
				{
					NSMutableString *templateString = [self webServicesHTMLMutableString:@"series.html"];			
					[templateString replaceOccurrencesOfString:@"%StudyID%" withString:NotNil([urlParameters objectForKey:@"studyID"])];
					[templateString replaceOccurrencesOfString:@"%SeriesID%" withString:NotNil([urlParameters objectForKey:@"id"])];
					
					NSString *browse =  NotNil([urlParameters objectForKey:@"browse"]);
					NSString *browseParameter =  NotNil([urlParameters objectForKey:@"browseParameter"]);
					NSString *search =  NotNil([urlParameters objectForKey:@"search"]);
					NSString *album = NotNil([urlParameters objectForKey:@"album"]);
					
					[templateString replaceOccurrencesOfString:@"%browse%" withString:NotNil(browse)];
					[templateString replaceOccurrencesOfString:@"%browseParameter%" withString:NotNil(browseParameter)];
					[templateString replaceOccurrencesOfString:@"%search%" withString:search];
					[templateString replaceOccurrencesOfString:@"%album%" withString:album];
					
					// This is probably wrong... video/quictime, see Series.html
					// [templateString replaceOccurrencesOfString:@"%VideoType%" withString: isiPhone? @"video/x-m4v":@"video/x-mov"];
					[templateString replaceOccurrencesOfString:@"%MovieExtension%" withString: isiPhone? @"m4v":@"mov"];
					
					[WebPortalData mutableString:templateString block:@"image" setVisible: [imagesArray count] == 1];
					[WebPortalData mutableString:templateString block:@"movie" setVisible: [imagesArray count] != 1];
					if ([imagesArray count] == 1)
					{
						[templateString replaceOccurrencesOfString:@"<!--[if !IE]>-->" withString:@""];
						[templateString replaceOccurrencesOfString:@"<!--<![endif]-->" withString:@""];
					}
					else
					{
						BOOL flash = [NSUserDefaultsController WebServerPrefersFlash] && !isiPhone;
						[WebPortalData mutableString:templateString block:@"movieqt" setVisible:!flash];
						[WebPortalData mutableString:templateString block:@"moviefla" setVisible:flash];

						int width, height;
						
						[self getWidth: &width height:&height fromImagesArray: imagesArray isiPhone: isiPhone];
						
						height += 15; // quicktime controller height
						
						//NSLog(@"NEW w: %d, h: %d", width, height);
						[templateString replaceOccurrencesOfString:@"%width%" withString: [NSString stringWithFormat:@"%d", width]];
						[templateString replaceOccurrencesOfString:@"%height%" withString: [NSString stringWithFormat:@"%d", height]];
						
						// We will generate the movie now, if required... to avoid Quicktime plugin problem waiting for it. REMOVED
					//	[self produceMovieForSeries: [series lastObject] isiPhone: isiPhone fileURL:fileURL lockReleased: &lockReleased];
					}
					
					NSString *seriesName = NotNil([[series lastObject] valueForKey:@"name"]);
					[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:NotNil(seriesName)];
					
					NSString *studyName = NotNil([[series lastObject] valueForKeyPath:@"study.name"]);
					[templateString replaceOccurrencesOfString:@"%LinkToStudyLevel%" withString:NotNil(studyName)];
					
					data = [templateString dataUsingEncoding:NSUTF8StringEncoding];
					err = NO;
				}
				#pragma mark     JSON
				else if ([fileURL isEqualToString:@"/series.json"])
				{
					@try
					{
						// Sort images with "instanceNumber"
						NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
						NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
						[sort release];
						imagesArray = [imagesArray sortedArrayUsingDescriptors: sortDescriptors];
					}
					@catch (NSException * e)
					{
						NSLog( @"%@", [e description]);
					}
					
					NSString *json = [self jsonImageListForImages:imagesArray];
					data = [json dataUsingEncoding:NSUTF8StringEncoding];
					err = NO;			
				}

			}
	#pragma mark report
			else if ([fileURL hasPrefix:@"/report"])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				NSArray *studies = [self studiesForPredicate:browsePredicate];
				
				if ([studies count] == 1)
				{
					[self updateLogEntryForStudy: [studies lastObject] withMessage: @"Download Report"];
					
					NSString *reportFilePath = [[studies lastObject] valueForKey:@"reportURL"];
					
					reportType = [reportFilePath pathExtension];
					
					if ([reportType isEqualToString: @"pages"])
					{
						NSString *zipFileName = [NSString stringWithFormat:@"%@.zip", [reportFilePath lastPathComponent]];
						// zip the directory into a single archive file
						NSTask *zipTask   = [[NSTask alloc] init];
						[zipTask setLaunchPath:@"/usr/bin/zip"];
						[zipTask setCurrentDirectoryPath:[[reportFilePath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
						if ([reportType isEqualToString:@"pages"])
							[zipTask setArguments:[NSArray arrayWithObjects: @"-q", @"-r" , zipFileName, [reportFilePath lastPathComponent], nil]];
						else
							[zipTask setArguments:[NSArray arrayWithObjects: zipFileName, [reportFilePath lastPathComponent], nil]];
						[zipTask launch];
						while( [zipTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
						int result = [zipTask terminationStatus];
						[zipTask release];
						
						if (result==0)
						{
							reportFilePath = [[reportFilePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", zipFileName];
						}
						
						data = [NSData dataWithContentsOfFile: reportFilePath];
						
						[[NSFileManager defaultManager] removeFileAtPath:reportFilePath handler:nil];
						
						if (data)
							err = NO;
					}
					else
					{
						data = [NSData dataWithContentsOfFile: reportFilePath];
						
						if (data)
							err = NO;
					}
				}
			}
		#pragma mark ZIP
			else if ([fileURL hasSuffix:@".zip"] || [fileURL hasSuffix:@".osirixzip"])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					if ([[urlParameters allKeys] containsObject:@"studyID"])
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"studyID"], [urlParameters objectForKey:@"id"]];
					else
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				NSArray *series = [self seriesForPredicate:browsePredicate];
				
				NSMutableArray *imagesArray = [NSMutableArray array];
				for ( DicomSeries *s in series)
					[imagesArray addObjectsFromArray: [[s valueForKey:@"images"] allObjects]];
				
				if ([imagesArray count])
				{
					if ([[currentUser valueForKey: @"encryptedZIP"] boolValue])
						[self updateLogEntryForStudy: [[series lastObject] valueForKey: @"study"] withMessage: @"Download encrypted DICOM ZIP"];
					else
						[self updateLogEntryForStudy: [[series lastObject] valueForKey: @"study"] withMessage: @"Download DICOM ZIP"];
						
					@try
					{
						NSString *srcFolder = @"/tmp";
						NSString *destFile = @"/tmp";
						
						srcFolder = [srcFolder stringByAppendingPathComponent: [[[imagesArray lastObject] valueForKeyPath: @"series.study.name"] filenameString]];
						destFile = [destFile stringByAppendingPathComponent: [[[imagesArray lastObject] valueForKeyPath: @"series.study.name"] filenameString]];
						
						if (isMacOS)
							destFile = [destFile  stringByAppendingPathExtension: @"zip"];
						else
							destFile = [destFile  stringByAppendingPathExtension: @"osirixzip"];
						
						if (srcFolder)
							[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
						
						if (destFile)
							[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
						
						[[NSFileManager defaultManager] createDirectoryAtPath: srcFolder attributes: nil];
						
						if (lockReleased == NO)
						{
							[[[BrowserController currentBrowser] managedObjectContext] unlock];
							lockReleased = YES;
						}
						
						if ([[currentUser valueForKey: @"encryptedZIP"] boolValue])
							[BrowserController encryptFiles: [imagesArray valueForKey: @"completePath"] inZIPFile: destFile password: [currentUser valueForKey: @"password"]];
						else
							[BrowserController encryptFiles: [imagesArray valueForKey: @"completePath"] inZIPFile: destFile password: nil];
						
						data = [NSData dataWithContentsOfFile: destFile];
						
						if (srcFolder)
							[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
						
						if (destFile)
							[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
						
						if (data)
							err = NO;
						else
						{
							data = [NSData data];
							err = NO;
						}
					}
					@catch( NSException *e)
					{
						NSLog( @"**** web seriesAsZIP exception : %@", e);
					}
				}
			}
		#pragma mark image
			else if ([fileURL hasPrefix:@"/image."])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					if ([[urlParameters allKeys] containsObject:@"studyID"])
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"studyID"], [urlParameters objectForKey:@"id"]];
					else
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				NSArray *series = [self seriesForPredicate:browsePredicate];
				if ([series count] == 1)
				{
					NSArray *dicomImageArray = [[[series lastObject] valueForKey:@"images"] allObjects];
					DicomImage *im;
					if ([dicomImageArray count] == 1)
						im = [dicomImageArray lastObject];
					else
						im = [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
					
					DCMPix* dcmPix = [[[DCMPix alloc] initWithPath:[im valueForKey:@"completePathResolved"] :0 :1 :nil :[[im valueForKey: @"numberOfFrames"] intValue]/2 :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im] autorelease];
					
					if (dcmPix == nil)
					{
						NSLog( @"****** dcmPix creation failed for file : %@", [im valueForKey:@"completePathResolved"]);
						float *imPtr = (float*)malloc( [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue] * sizeof(float));
						for ( int i = 0 ;  i < [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue]; i++)
							imPtr[ i] = i;
						
						dcmPix = [[[DCMPix alloc] initWithData: imPtr :32 :[[im valueForKey: @"width"] intValue] :[[im valueForKey: @"height"] intValue] :0 :0 :0 :0 :0] autorelease];
					}
					
					if (dcmPix)
					{
						float curWW = 0;
						float curWL = 0;
						
						if ([[im valueForKey:@"series"] valueForKey:@"windowWidth"])
						{
							curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
							curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
						}
						
						if (curWW != 0)
							[dcmPix checkImageAvailble:curWW :curWL];
						else
							[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
						
						NSImage *image = [dcmPix image];
						
						float width = [image size].width;
						float height = [image size].height;
						
						int maxWidth = maxResolution, maxHeight = maxResolution;
						int minWidth = minResolution, minHeight = minResolution;
						
						BOOL resize = NO;
						
						if (width>maxWidth)
						{
							height =  height * maxWidth / width;
							width = maxWidth;
							resize = YES;
						}
						if (height>maxHeight)
						{
							width = width * maxHeight / height;
							height = maxHeight;
							resize = YES;
						}
						
						if (width < minWidth)
						{
							height = (float)height * (float)minWidth / (float)width;
							width = minWidth;
							resize = YES;
						}
						
						if (height < minHeight)
						{
							width = (float)width * (float)minHeight / (float)height;
							height = minHeight;
							resize = YES;
						}
						
						NSImage *newImage;
						
						if (resize)
							newImage = [image imageByScalingProportionallyToSize:NSMakeSize(width, height)];
						else
							newImage = image;
						
						if ([[urlParameters allKeys] containsObject:@"previewForMovie"])
						{
							[newImage lockFocus];
							
							NSImage *r = [NSImage imageNamed: @"PlayTemplate.png"];
							
							[r drawInRect: [self centerRect: NSMakeRect( 0,  0, [r size].width, [r size].height) inRect: NSMakeRect( 0,  0, [newImage size].width, [newImage size].height)] fromRect: NSMakeRect( 0,  0, [r size].width, [r size].height)  operation: NSCompositeSourceOver fraction: 1.0];
							
							[newImage unlockFocus];
						}
						
						NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [newImage TIFFRepresentation]];
						
						if ([[fileURL pathExtension] isEqualToString: @"png"])
						{
							NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
							data = [imageRep representationUsingType:NSPNGFileType properties: imageProps];
						}
						else if ([[fileURL pathExtension] isEqualToString: @"jpg"])
						{
							NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
							data = [imageRep representationUsingType: NSJPEGFileType properties: imageProps];
						}
						else NSLog( @"***** unknown path extension: %@", [fileURL pathExtension]);
					}
				}
				
				err = NO;
			}
			
			#pragma mark movie.mov/.m4v/.swf
			else if ([fileURL isEqualToString:@"/movie.mov"] || [fileURL isEqualToString:@"/movie.m4v"] || [fileURL isEqualToString:@"/movie.swf"])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					if ([[urlParameters allKeys] containsObject:@"studyID"])
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"studyID"], [urlParameters objectForKey:@"id"]];
					else
						browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				NSArray *series = [self seriesForPredicate:browsePredicate];
				
				if ([series count] == 1)
				{
					data = [self produceMovieForSeries: [series lastObject] isiPhone: isiPhone fileURL: fileURL lockReleased: &lockReleased];
				}
				
				if (data == nil || [data length] == 0)
					NSLog( @"****** movie data == nil");
					
				err = NO;
			}
	//		#pragma mark m4v
	//		else if ([fileURL hasSuffix:@".m4v"]) -- I DONT UNDERSTAND WHERE THIS IS NEEDED...
	//		{
	//			data = [NSData dataWithContentsOfFile: requestedFile];
	//			totalLength = [data length];
	//			
	//			err = NO;
	//		}
			
			#pragma mark password forgotten
			else if ([fileURL isEqualToString: @"/password_forgotten"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"restorePasswordWebServer"])
			{
				NSMutableString *templateString = [self webServicesHTMLMutableString:@"password_forgotten.html"];
				
				NSString *message = @"";
				
				if ([[urlParameters valueForKey: @"what"] isEqualToString: @"restorePassword"])
				{
					NSString *email = [urlParameters valueForKey: @"email"];
					NSString *username = [urlParameters valueForKey: @"username"];
					
					// TRY TO FIND THIS USER
					if ([email length] > 0 || [username length] > 0)
					{
						[[[BrowserController currentBrowser] userManagedObjectContext] lock];
						
						@try
						{
							NSError *error = nil;
							NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
							
							if ([email length] > [username length])
								[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(email BEGINSWITH[cd] %@) AND (email ENDSWITH[cd] %@)", email, email]];
							else
								[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(name BEGINSWITH[cd] %@) AND (name ENDSWITH[cd] %@)", username, username]];
								
							error = nil;
							NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
							
							if ([users count] >= 1)
							{
								for (WebPortalUser *user in users)
								{
									NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
									
									if (fromEmailAddress == nil)
										fromEmailAddress = @"";
									
									NSString *emailSubject = NSLocalizedString( @"Your password has been reset.", nil);
									NSMutableString *emailMessage = [NSMutableString stringWithString: @""];
									
									[user generatePassword];
									
									[emailMessage appendString: NSLocalizedString( @"Username:\r\r", nil)];
									[emailMessage appendString: [user valueForKey: @"name"]];
									[emailMessage appendString: @"\r\r"];
									[emailMessage appendString: NSLocalizedString( @"Password:\r\r", nil)];
									[emailMessage appendString: [user valueForKey: @"password"]];
									[emailMessage appendString: @"\r\r"];
									
									[WebPortalConnection updateLogEntryForStudy: nil withMessage: @"Password reseted for user" forUser: [user valueForKey: @"name"] ip: nil];
									
									[[CSMailMailClient mailClient] deliverMessage: [[[NSAttributedString alloc] initWithString: emailMessage] autorelease] headers: [NSDictionary dictionaryWithObjectsAndKeys: [user valueForKey: @"email"], @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", nil]];
								
									message = NSLocalizedString( @"You will receive shortly an email with a new password.", nil);
									
									[[BrowserController currentBrowser] saveUserDatabase];
								}
							}
							else
							{
								// To avoid someone scanning for the username
								waitBeforeReturning = YES;
								
								[WebPortalConnection updateLogEntryForStudy: nil withMessage: @"Unknown user" forUser: [NSString stringWithFormat: @"%@ %@", username, email] ip: nil];
								
								message = NSLocalizedString( @"This user doesn't exist in our database.", nil);
							}
						}
						@catch( NSException *e)
						{
							NSLog( @"******* password_forgotten: %@", e);
						}
						
						[[[BrowserController currentBrowser] userManagedObjectContext] unlock];
					}
				}
				
				[WebPortalData mutableString:templateString block:@"MessageToWrite" setVisible:message.length];
				[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:@"Password Forgotten"];
				
				[templateString replaceOccurrencesOfString: @"%Localized_Message%" withString:NotNil(message)];
				
				data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
				
				err = NO;
			}
			
			#pragma mark account
			else if ([fileURL isEqualToString: @"/account"])
			{
				if (currentUser)
				{
					NSString *message = @"";
					BOOL messageIsError = NO;
					
					if ([[urlParameters valueForKey: @"what"] isEqualToString: @"changePassword"])
					{
						NSString * previouspassword = [urlParameters valueForKey: @"previouspassword"];
						NSString * password = [urlParameters valueForKey: @"password"];
						
						if ([previouspassword isEqualToString: [currentUser valueForKey: @"password"]])
						{
							if ([[urlParameters valueForKey: @"password"] isEqualToString: [urlParameters valueForKey: @"password2"]])
							{
								if ([password length] >= 4)
								{
									// We can update the user password
									[currentUser setValue: password forKey: @"password"];
									message = NSLocalizedString( @"Password updated successfully !", nil);
									[self updateLogEntryForStudy: nil withMessage: [NSString stringWithFormat: @"User changed his password"]];
								}
								else
								{
									message = NSLocalizedString( @"Password needs to be at least 4 characters !", nil);
									messageIsError = YES;
								}
							}
							else
							{
								message = NSLocalizedString( @"New passwords are not identical !", nil);
								messageIsError = YES;
							}
						}
						else
						{
							message = NSLocalizedString( @"Wrong current password !", nil);
							messageIsError = YES;
						}
					}
					
					if ([[urlParameters valueForKey: @"what"] isEqualToString: @"changeSettings"])
					{
						NSString * email = [urlParameters valueForKey: @"email"];
						NSString * address = [urlParameters valueForKey: @"address"];
						NSString * phone = [urlParameters valueForKey: @"phone"];
						
						[currentUser setValue: email forKey: @"email"];
						[currentUser setValue: address forKey: @"address"];
						[currentUser setValue: phone forKey: @"phone"];
						
						if ([[[urlParameters valueForKey: @"emailNotification"] lowercaseString] isEqualToString: @"on"])
							[currentUser setValue: [NSNumber numberWithBool: YES] forKey: @"emailNotification"];
						else
							[currentUser setValue: [NSNumber numberWithBool: NO] forKey: @"emailNotification"];
							
						message = NSLocalizedString( @"Personal Information updated successfully !", nil);
					}
					
					NSMutableString *templateString = [self webServicesHTMLMutableString:@"account.html"];
					
					NSString *block = @"MessageToWrite";
					if (messageIsError)
					{
						block = @"ErrorToWrite";
						[WebPortalData mutableString:templateString block:@"MessageToWrite" setVisible:NO];
					}
					else
					{
						[WebPortalData mutableString:templateString block:@"ErrorToWrite" setVisible:NO];
					}

					[WebPortalData mutableString:templateString block:block setVisible:message.length];
					
					[templateString replaceOccurrencesOfString: @"%LocalizedLabel_MessageAccount%" withString:NotNil(message)];
					
					[templateString replaceOccurrencesOfString: @"%name%" withString:NotNil([currentUser valueForKey: @"name"])];
					[templateString replaceOccurrencesOfString: @"%PageTitle%" withString:[NSString stringWithFormat:@"User account for: %@", currentUser.name]];
					
					[templateString replaceOccurrencesOfString: @"%email%" withString:NotNil([currentUser valueForKey: @"email"])];
					[templateString replaceOccurrencesOfString: @"%address%" withString:NotNil([currentUser valueForKey: @"address"])];
					[templateString replaceOccurrencesOfString: @"%phone%" withString:NotNil([currentUser valueForKey: @"phone"])];
					[templateString replaceOccurrencesOfString: @"%emailNotification%" withString: ([[currentUser valueForKey: @"emailNotification"] boolValue]?@"checked":@"")];
					
					data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
					
					[[BrowserController currentBrowser] saveUserDatabase];
					
					err = NO;
				}
			}
			
			#pragma mark Albums (JSON)
			else if ([fileURL isEqualToString:@"/albums.json"])
			{
				NSString *json = [self jsonAlbumList];
				data = [json dataUsingEncoding:NSUTF8StringEncoding];
				err = NO;
			}
			
			#pragma mark seriesList (JSON)
			else if ([fileURL isEqualToString:@"/seriesList.json"])
			{
				NSPredicate *browsePredicate;
				if ([[urlParameters allKeys] containsObject:@"id"])
				{
					browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
				}
				else
					browsePredicate = [NSPredicate predicateWithValue:NO];
				
				
				NSArray *studies = [self studiesForPredicate:browsePredicate];
				
				if ([studies count] == 1)
				{
					NSArray *seriesArray = [[studies objectAtIndex:0] valueForKey:@"imageSeries"];
					NSString *json = [self jsonSeriesListForSeries:seriesArray];
					data = [json dataUsingEncoding:NSUTF8StringEncoding];
					err = NO;
				}
				else err = YES;
			}
			
			#pragma mark weasis.jnlp
			else if ([NSUserDefaultsController WebServerUsesWeasis] && [fileURL isEqualToString:@"/weasis.jnlp"])
			{
				NSString* jnlp = [self weasisJnlpWithParamsString:parameterString];
				data = [jnlp dataUsingEncoding:NSUTF8StringEncoding];
				dataMime = @"application/x-java-jnlp-file";
				err = NO;
			}
			
			#pragma mark weasis.xml
			else if ([NSUserDefaultsController WebServerUsesWeasis] && [fileURL isEqualToString:@"/weasis.xml"])
			{
				NSString* jnlp = [self weasisXmlWithParams:urlParameters];
				data = [jnlp dataUsingEncoding:NSUTF8StringEncoding];
				dataMime = @"text/xml";
				err = NO;
			}
			
			#pragma mark admin
			else if ([fileURL hasPrefix:@"/admin/"])
			{
				if (currentUser.isAdmin) {
					#pragma mark     index
					if ([fileURL isEqualToString:@"/admin/"] || [fileURL isEqualToString:@"/admin/index"]) {
						[self generate:response adminIndex:urlParameters];
						//data = [html dataUsingEncoding:NSUTF8StringEncoding];
						err = NO;
					}
					
					#pragma mark     user
					if ([fileURL isEqualToString:@"/admin/user"]) {
						[self generate:response adminUser:urlParameters];
						err = NO;
					}
				} else {
					[NSException raise:NSGenericException format:NSLocalizedString(@"Access to the administration interface is only granted to administrators.", @"Web Portal, admin, access error")];
				}
			}
		}
	
		@catch( NSException *e)
		{
			NSLog( @"******** httpResponseForMethod WebPortalConnection exception: %@", e);
			NSLog( @"******** method : %@ path : %@", method, path);
			err = YES;
		}
		
	}
	
	if (lockReleased == NO)
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	if (waitBeforeReturning)
		[NSThread sleepForTimeInterval: 3];
	
	if (err)
		data = [[NSString stringWithString: NSLocalizedString( @"Error 404\r\rFailed to process this request.\r\rThis error will be logged and the webmaster will be notified.", nil)] dataUsingEncoding: NSUTF8StringEncoding];
	
	if (data)
		[response setData:data];
	if (dataMime)
		[response.httpHeaders setObject:dataMime forKey:@"Content-Type"];
	
	return response; // [[[WebPortalResponse alloc] initWithData:data mime:dataMime sessionId:session.sid] autorelease];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	if ([@"POST" isEqualToString:method])
	{
		return YES;
	}
	
	return [super supportsMethod:method atPath:relativePath];
}

- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
{
	dataStartIndex = 0;
	[multipartData release];
	multipartData = [[NSMutableArray alloc] init];
	postHeaderOK = FALSE;
	
	[postBoundary release];
	postBoundary = nil;
	
	[POSTfilename release];
	POSTfilename = nil;
	
	return YES;
}

- (BOOL) checkEOF:(NSData*) postDataChunk range: (NSRange*) r
{
	BOOL eof = NO;
	int l = [postBoundary length];
	
	#define CHECKLASTPART 4096
	
	for ( int x = [postDataChunk length]-CHECKLASTPART; x < [postDataChunk length]-l; x++)
	{
		if (x >= 0)
		{
			NSRange searchRange = {x, l};
			
			// If MacOS 10.6 : we should use - (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
			
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData: postBoundary])
			{
				r->length -= ([postDataChunk length] - x) +2; // -2 = 0x0A0D
				return YES;
			}
		}
	}
	return NO;
}

- (void) closeFileHandleAndClean
{
	int inc = 1;
	NSString *file;
	NSString *root = [[[BrowserController currentBrowser] localDocumentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
	NSMutableArray *filesArray = [NSMutableArray array];
	
	if ([[POSTfilename pathExtension] isEqualToString: @"zip"] || [[POSTfilename pathExtension] isEqualToString: @"osirixzip"])
	{
		NSTask *t = [[[NSTask alloc] init] autorelease];
		
		[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/osirixUnzippedFolder" error: nil];
		
		@try
		{
			[t setLaunchPath: @"/usr/bin/unzip"];
			[t setCurrentDirectoryPath: @"/tmp/"];
			NSArray *args = [NSArray arrayWithObjects: @"-o", @"-d", @"osirixUnzippedFolder", POSTfilename, nil];
			[t setArguments: args];
			[t launch];
			[t waitUntilExit];
		}
		@catch( NSException *e)
		{
			NSLog( @"***** unzipFile exception: %@", e);
		}
		
		if (POSTfilename)
			[[NSFileManager defaultManager] removeItemAtPath: POSTfilename error: nil];
		
		NSString *rootDir = @"/tmp/osirixUnzippedFolder";
		BOOL isDirectory = NO;
		
		for ( NSString *file in [[NSFileManager defaultManager] subpathsOfDirectoryAtPath: rootDir error: nil])
		{
			if ([file hasSuffix: @".DS_Store"] == NO && [file hasPrefix: @"__MACOSX"] == NO && [[NSFileManager defaultManager] fileExistsAtPath: [rootDir stringByAppendingPathComponent: file] isDirectory: &isDirectory] && isDirectory == NO)
				[filesArray addObject: [rootDir stringByAppendingPathComponent: file]];
		}
	}
	else
		[filesArray addObject: POSTfilename];
	
	NSString *previousPatientUID = nil;
	NSString *previousStudyInstanceUID = nil;
	
	// We want to find this file after db insert: get studyInstanceUID, patientUID and instanceSOPUID
	for ( NSString *oFile in filesArray)
	{
		DicomFile *f = [[[DicomFile alloc] init: oFile DICOMOnly: YES] autorelease];
		
		if (f)
		{
			do
			{
				file = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebServer Upload %d", inc++]] stringByAppendingPathExtension: [oFile pathExtension]];
			}
			while( [[NSFileManager defaultManager] fileExistsAtPath: file]);
		
			[[NSFileManager defaultManager] moveItemAtPath: oFile toPath: file error: nil];
			
			if ([[currentUser valueForKey: @"uploadDICOMAddToSpecificStudies"] boolValue])
			{
				NSString *studyInstanceUID = [f elementForKey: @"studyID"], *patientUID = [f elementForKey: @"patientUID"];	//, *sopInstanceUID = [f elementForKey: @"SOPUID"];
				
				if ([studyInstanceUID isEqualToString: previousStudyInstanceUID] == NO || [patientUID isEqualToString: previousPatientUID] == NO)
				{
					previousStudyInstanceUID = [[studyInstanceUID copy] autorelease];
					previousPatientUID = [[patientUID copy] autorelease];
					
					[[BrowserController currentBrowser] checkIncomingNow: self];
					[NSThread sleepForTimeInterval: 1];
					[[BrowserController currentBrowser] checkIncomingNow: self];
					
					if (studyInstanceUID && patientUID)
					{
						[[[BrowserController currentBrowser] managedObjectContext] lock];
						
						@try
						{
							NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"Study"]];
							[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(patientUID == %@) AND (studyInstanceUID == %@)", patientUID, studyInstanceUID]];
							
							NSError *error = nil;
							NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error:&error];
							
							if ([studies count] == 0)
								NSLog( @"****** [studies count == 0] cannot find the file{s} we just received... upload POST");
							
							// Add study to specific study list for this user
							
							NSArray *studiesArrayStudyInstanceUID = [[[currentUser valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
							NSArray *studiesArrayPatientUID = [[[currentUser valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
							
							for ( NSManagedObject *study in studies)
							{
								if ([[study valueForKey: @"type"] isEqualToString:@"Series"])
									study = [study valueForKey:@"study"];
								
								if ([studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
								{
									NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: [BrowserController currentBrowser].userManagedObjectContext];
									
									[studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
									[studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
									[studyLink setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]] forKey: @"dateAdded"];
									
									[studyLink setValue: currentUser forKey: @"user"];
									
									@try
									{
										[[BrowserController currentBrowser].userManagedObjectContext save: nil];
									}
									@catch (NSException * e)
									{
										NSLog( @"*********** [[BrowserController currentBrowser].userManagedObjectContext save: nil]");
									}
									
									studiesArrayStudyInstanceUID = [[[currentUser valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
									studiesArrayPatientUID = [[[currentUser valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
									
									[WebPortalConnection updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser: [currentUser valueForKey: @"name"] ip: nil];
								}
							}
						}
						@catch( NSException *e)
						{
							NSLog( @"********* WebPortalConnection closeFileHandleAndClean exception : %@", e);
						}
						///
						
						[[[BrowserController currentBrowser] managedObjectContext] unlock];
					}
					else NSLog( @"****** studyInstanceUID && patientUID == nil upload POST");
				}
			}
		}
	}
	
	
	[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/osirixUnzippedFolder" error: nil];
	
	[multipartData release];	multipartData = nil;
	[postBoundary release];		postBoundary = nil;
	[POSTfilename release];		POSTfilename = nil;
}

- (void)processDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	//NSLog(@"processPostDataChunk");
	
	if (!postHeaderOK)
	{
		if (multipartData == nil)
			[self supportsPOST: nil withSize: 0];
		
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
		
		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};
			
			// If MacOS 10.6 : we should use - (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
			
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];
				
				if ([newData length])
				{
					[multipartData addObject:newData];
				}
				else
				{
					postHeaderOK = TRUE;
					
					NSString* postInfo = [[NSString alloc] initWithBytes: [[multipartData objectAtIndex:1] bytes] length:[(NSData*) [multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
					
					[postBoundary release];
					postBoundary = [[multipartData objectAtIndex:0] copy];
					
					@try
					{
						NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
						postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
						postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
						
						NSString *extension = [[postInfoComponents lastObject] pathExtension];
						
						NSString* root = @"/tmp/";
						
						int inc = 1;
						
						do
						{
							POSTfilename = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebServer Upload %d", inc++]] stringByAppendingPathExtension: extension];
						}
						while( [[NSFileManager defaultManager] fileExistsAtPath: POSTfilename]);
						
						[POSTfilename retain];
						
						NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
						
						BOOL eof = [self checkEOF: postDataChunk range: &fileDataRange];
						
						[[NSFileManager defaultManager] createFileAtPath:POSTfilename contents: [postDataChunk subdataWithRange:fileDataRange] attributes:nil];
						NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:POSTfilename] retain];
						
						if (file)
						{
							[file seekToEndOfFile];
							[multipartData addObject:file];
						}
						else NSLog( @"***** Failed to create file - processDataChunk : %@", POSTfilename);
						
						if (eof)
							[self closeFileHandleAndClean];
						
						[file release];
					}
					@catch (NSException *e)
					{
						NSLog( @"******* POST processDataChunk : %@", e);
					}
					[postInfo release];
					
					break;
				}
			}
		}
		
		// For other POST, like account update
		
		if ([postDataChunk length] < 4096)
		{
			[multipartData release];
			multipartData = [[NSMutableArray array] retain];
			[multipartData addObject: postDataChunk];
		}
	}
	else
	{
		NSRange fileDataRange = { 0, [postDataChunk length]};
		
		BOOL eof = [self checkEOF: postDataChunk range: &fileDataRange];
		
		@try
		{
			[(NSFileHandle*)[multipartData lastObject] writeData: [postDataChunk subdataWithRange: fileDataRange]];
		}
		@catch (NSException * e)
		{
			NSLog( @"******* writeData processDataChunk exception: %@", e);
		}
		
		if (eof)
			[self closeFileHandleAndClean];
	}
}

#pragma mark JSON

- (NSString*)jsonAlbumList;
{
	NSMutableArray *jsonAlbumsArray = [NSMutableArray array];
	
	NSArray	*albumArray = [[BrowserController currentBrowser] albumArray];
	for (NSManagedObject *album in albumArray)
	{
		if (![[album valueForKey:@"name"] isEqualToString: NSLocalizedString(@"Database", nil)])
		{
			NSMutableDictionary *albumDictionary = [NSMutableDictionary dictionary];
			
			[albumDictionary setObject:NotNil([album valueForKey:@"name"]) forKey:@"name"];
			[albumDictionary setObject:NotNil([[album valueForKey:@"name"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]) forKey:@"nameURLSafe"];
			
			if ([[album valueForKey:@"smartAlbum"] intValue] == 1)
				[albumDictionary setObject:@"SmartAlbum" forKey:@"type"];
			else
				[albumDictionary setObject:@"Album" forKey:@"type"];
			
			[jsonAlbumsArray addObject:albumDictionary];
		}
	}
	
	return [jsonAlbumsArray JSONRepresentation];
}

- (NSString*)jsonStudyListForStudies:(NSArray*)studies;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSMutableArray *jsonStudiesArray = [NSMutableArray array];
	
	[context lock];
	
	@try
	{
		
		int lineNumber = 0;
		for (DicomStudy *study in studies)
		{
			NSMutableDictionary *studyDictionary = [NSMutableDictionary dictionary];
			
			[studyDictionary setObject:NotNil([study valueForKey:@"name"]) forKey:@"name"];
			
			NSArray *seriesArray = [study valueForKey:@"imageSeries"];
			int count = 0;
			for (DicomSeries *series in seriesArray)
			{
				count++;
			}
			
			[studyDictionary setObject:[NSString stringWithFormat:@"%d", count] forKey:@"seriesCount"];
			
			
			NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
			NSString *date = [dateFormat stringFromDate:[study valueForKey:@"date"]];		
			[studyDictionary setObject:date forKey:@"date"];		
			
			[studyDictionary setObject:NotNil([study valueForKey:@"comment"]) forKey:@"comment"];

			[studyDictionary setObject:NotNil([study valueForKey:@"studyName"]) forKey:@"studyName"];

			[studyDictionary setObject:NotNil([study valueForKey:@"modality"]) forKey:@"modality"];
			
			NSString *stateText = @"";
			if ([[study valueForKey:@"stateText"] intValue])
				stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
			
			[studyDictionary setObject:NotNil(stateText) forKey:@"stateText"];

			[studyDictionary setObject:NotNil([study valueForKey:@"studyInstanceUID"]) forKey:@"studyInstanceUID"];
			
			[jsonStudiesArray addObject:studyDictionary];
		}	
	}
	@catch (NSException *e)
	{
		NSLog( @"****** jsonStudyListForStudies exception: %@", e);
	}
	
	[context unlock];
	
	return [jsonStudiesArray JSONRepresentation];
}

- (NSString*)jsonSeriesListForSeries:(NSArray*)series;
{
	NSMutableArray *jsonSeriesArray = [NSMutableArray array];
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];

	@try
	{
		for (DicomSeries *s in series)
		{
			NSMutableDictionary *seriesDictionary = [NSMutableDictionary dictionary];
			
			[seriesDictionary setObject:NotNil([s valueForKey:@"seriesInstanceUID"]) forKey:@"seriesInstanceUID"];
			[seriesDictionary setObject:NotNil([s valueForKey:@"seriesDICOMUID"]) forKey:@"seriesDICOMUID"];
			
			NSArray *dicomImageArray = [[s valueForKey:@"images"] allObjects];
			DicomImage *im;
			if ([dicomImageArray count] == 1)
				im = [dicomImageArray lastObject];
			else
				im = [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
			
			[seriesDictionary setObject:[im valueForKey:@"sopInstanceUID"] forKey:@"keyInstanceUID"];
			
			[jsonSeriesArray addObject:seriesDictionary];
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"******* jsonSeriesListForSeries exception: %@", e);
	}
	[context unlock];
	
	return [jsonSeriesArray JSONRepresentation];
}

- (NSString*)jsonImageListForImages:(NSArray*)images;
{
	NSMutableArray *jsonImagesArray = [NSMutableArray array];
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	[context lock];
	
	@try
	{
		for (DicomImage *image in images)
		{
			[jsonImagesArray addObject:NotNil([image valueForKey:@"sopInstanceUID"])];
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"***** jsonImageListForImages exception: %@", e);
	}
	
	[context unlock];
	
	return [jsonImagesArray JSONRepresentation];
}

#pragma mark Weasis

+(NSString*)WeasisXmlFormatDate:(NSDate*)date {
	NSDateFormatter* format = [[[NSDateFormatter alloc] init] autorelease];
	format.dateFormat = @"dd-MM-yyyy";
	return [format stringFromDate:date];
}

+(NSString*)WeasisXmlFormatTime:(NSDate*)date {
	NSDateFormatter* format = [[[NSDateFormatter alloc] init] autorelease];
	format.dateFormat = @"HH:mm:ss";
	return [format stringFromDate:date];
}

-(NSString*)weasisJnlpWithParamsString:(NSString*)parameters {
	NSMutableString* templateString = [self webServicesHTMLMutableString:@"weasis.jnlp"];
	
	[templateString replaceOccurrencesOfString:@"%WebServerAddress%" withString:self.webServerURL];
	[templateString replaceOccurrencesOfString:@"%parameters%" withString:NotNil(parameters)];
	
	return templateString;
}

-(NSString*)weasisXmlWithParams:(NSDictionary*)parameters {
	NSString* studyInstanceUID = [parameters objectForKey:@"StudyInstanceUID"];
	NSString* seriesInstanceUID = [parameters objectForKey:@"SeriesInstanceUID"];
	NSArray* selectedSeries = [WebPortalConnection MakeArray:[parameters objectForKey:@"selected"]];
	
	NSMutableArray* requestedStudies = [NSMutableArray arrayWithCapacity:8];
	NSMutableArray* requestedSeries = [NSMutableArray arrayWithCapacity:64];
	
	// find requosted core data objects
	if (studyInstanceUID)
		[requestedStudies addObjectsFromArray:[self studiesForPredicate:[NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyInstanceUID]]];
	if (seriesInstanceUID)
		[requestedSeries addObjectsFromArray:[self seriesForPredicate:[NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", seriesInstanceUID]]];
	for (NSString* selSeriesInstanceUID in selectedSeries)
		[requestedSeries addObjectsFromArray:[self seriesForPredicate:[NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", selSeriesInstanceUID]]];
	
	NSMutableArray* patientIds = [NSMutableArray arrayWithCapacity:2];
	NSMutableArray* studies = [NSMutableArray arrayWithCapacity:8];
	NSMutableArray* series = [NSMutableArray arrayWithCapacity:64];
	
	for (DicomStudy* study in requestedStudies) {
		if (![studies containsObject:study])
			[studies addObject:study];
		if (![patientIds containsObject:study.patientID])
			[patientIds addObject:study.patientID];
		for (DicomSeries* serie in study.series)
			if (![series containsObject:serie])
				[series addObject:serie];
	}
	
	for (DicomSeries* serie in requestedSeries) {
		if (![studies containsObject:serie.study])
			[studies addObject:serie.study];
		if (![patientIds containsObject:serie.study.patientID])
			[patientIds addObject:serie.study.patientID];
		if (![series containsObject:serie])
			[series addObject:serie];
	}
	
	// filter by user rights
	if (currentUser)
	{
		studies = (NSMutableArray*) [self studiesForPredicate: [NSPredicate predicateWithValue:YES] sortBy: nil];// is not mutable, but we won't mutate it anymore
	}
	
	// produce XML
	NSString* baseXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><wado_query wadoURL=\"%@/wado\"></wado_query>", self.webServerURL];
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:baseXML options:NSXMLDocumentIncludeContentTypeDeclaration|NSXMLDocumentTidyXML error:NULL];
	[doc setCharacterEncoding:@"UTF-8"];
	
	for (NSString* patientId in patientIds) {
		NSXMLElement* patientNode = [NSXMLNode elementWithName:@"Patient"];
		[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientID" stringValue:patientId]];
		BOOL patientDataSet = NO;
		[doc.rootElement addChild:patientNode];
		
		for (DicomStudy* study in studies)
			if ([study.patientID isEqual:patientId]) {
				NSXMLElement* studyNode = [NSXMLNode elementWithName:@"Study"];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyInstanceUID" stringValue:study.studyInstanceUID]];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyDescription" stringValue:study.studyName]];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyDate" stringValue:[WebPortalConnection WeasisXmlFormatDate:study.date]]];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyTime" stringValue:[WebPortalConnection WeasisXmlFormatTime:study.date]]];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"AccessionNumber" stringValue:study.accessionNumber]];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyID" stringValue:study.id]]; // ?
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"ReferringPhysicianName" stringValue:study.referringPhysician]];
				[patientNode addChild:studyNode];
				
				for (DicomSeries* serie in series)
					if (serie.study == study) {
						NSXMLElement* serieNode = [NSXMLNode elementWithName:@"Series"];
						[serieNode addAttribute:[NSXMLNode attributeWithName:@"SeriesInstanceUID" stringValue:serie.seriesDICOMUID]];
						[serieNode addAttribute:[NSXMLNode attributeWithName:@"SeriesDescription" stringValue:serie.seriesDescription]];
						[serieNode addAttribute:[NSXMLNode attributeWithName:@"SeriesNumber" stringValue:[serie.id stringValue]]]; // ?
						[serieNode addAttribute:[NSXMLNode attributeWithName:@"Modality" stringValue:serie.modality]];
						[studyNode addChild:serieNode];

						for (DicomImage* image in serie.images) {
							NSXMLElement* instanceNode = [NSXMLNode elementWithName:@"Instance"];
							[instanceNode addAttribute:[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:image.sopInstanceUID]];
							[instanceNode addAttribute:[NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[image.instanceNumber stringValue]]];
							[serieNode addChild:instanceNode];
						}
					}
				
				if (!patientDataSet) {
					[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientName" stringValue:study.name]];
					[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientBirthDate" stringValue:[WebPortalConnection WeasisXmlFormatDate:study.dateOfBirth]]];
					[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientSex" stringValue:study.patientSex]];
				}
			}
	}

	return [[doc autorelease] XMLString];
}

#pragma mark Administration HTML

-(void)generate:(WebPortalResponse*)response adminIndex:(NSDictionary*)parameters {
	NSMutableString* templateString = [self webServicesHTMLMutableString:@"admin/index.html"];
	
	NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
	
	[tokens setObject:NSLocalizedString(@"Administration", @"Web Portal, admin, index, title") forKey:@"PageTitle"];
	
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	[req setEntity:[[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey:@"User"]];
	[req setPredicate:[NSPredicate predicateWithValue:YES]];
	[tokens setObject:[[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest:req error:NULL] forKey:@"Users"];
	
	[WebPortalData mutableString:templateString evaluateTokensWithDictionary:tokens];
	
	[response setDataWithString:templateString];
}

-(void)generate:(WebPortalResponse*)response adminUser:(NSDictionary*)parameters {
	NSMutableString* templateString = [self webServicesHTMLMutableString:@"admin/user.html"];
	
	NSMutableDictionary* tokens = [[NSMutableDictionary alloc] init];

	NSObject* user = NULL;
	BOOL userRecycleParams = NO;
	NSString* action = [parameters objectForKey:@"action"];
	NSString* originalName = NULL;
	
	if ([action isEqual:@"delete"]) {
		originalName = [parameters objectForKey:@"originalName"];
		NSManagedObject* tempUser = [[BrowserController currentBrowser] userWithName:originalName];
		if (!tempUser)
			[tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't delete user %@ because it doesn't exists.", @"Web Portal, admin, user edition, delete error"), originalName]];
		else {
			[[[BrowserController currentBrowser] userManagedObjectContext] deleteObject:tempUser];
			[tempUser.managedObjectContext save:NULL];
			[tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"User %@ successfully deleted.", @"Web Portal, admin, user edition, delete ok"), originalName]];
		}
	}
	
	if ([action isEqual:@"save"]) {
		originalName = [parameters objectForKey:@"originalName"];
		WebPortalUser* webUser = [[BrowserController currentBrowser] userWithName:originalName];
		if (!webUser) {
			[tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't save changes for user %@ because it doesn't exists.", @"Web Portal, admin, user edition, save error"), originalName]];
			userRecycleParams = YES;
		} else {
			NSLog(@"SAVE params: %@", parameters.description);
			
			NSString* name = [parameters objectForKey:@"name"];
			NSString* password = [parameters objectForKey:@"password"];
			NSString* studyPredicate = [parameters objectForKey:@"studyPredicate"];
			NSNumber* downloadZIP = [NSNumber numberWithBool:[[parameters objectForKey:@"downloadZIP"] isEqual:@"on"]];
			
			NSError* err;

			err = NULL;
			if (![webUser validateName:&name error:&err])
				[tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validatePassword:&password error:&err])
				[tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateStudyPredicate:&studyPredicate error:&err])
				[tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateDownloadZIP:&downloadZIP error:&err])
				[tokens addError:err.localizedDescription];
			
			if (!tokens.errors.count) {
				webUser.name = name;
				webUser.password = password;
				webUser.email = [parameters objectForKey:@"email"];
				webUser.phone = [parameters objectForKey:@"phone"];
				webUser.address = [parameters objectForKey:@"address"];
				webUser.studyPredicate = studyPredicate;
				
				webUser.autoDelete = [NSNumber numberWithBool:[[parameters objectForKey:@"autoDelete"] isEqual:@"on"]];
				webUser.downloadZIP = downloadZIP;
				webUser.emailNotification = [NSNumber numberWithBool:[[parameters objectForKey:@"emailNotification"] isEqual:@"on"]];
				webUser.encryptedZIP = [NSNumber numberWithBool:[[parameters objectForKey:@"encryptedZIP"] isEqual:@"on"]];
				webUser.uploadDICOM = [NSNumber numberWithBool:[[parameters objectForKey:@"uploadDICOM"] isEqual:@"on"]];
				webUser.sendDICOMtoSelfIP = [NSNumber numberWithBool:[[parameters objectForKey:@"sendDICOMtoSelfIP"] isEqual:@"on"]];
				webUser.uploadDICOMAddToSpecificStudies = [NSNumber numberWithBool:[[parameters objectForKey:@"uploadDICOMAddToSpecificStudies"] isEqual:@"on"]];
				webUser.sendDICOMtoAnyNodes = [NSNumber numberWithBool:[[parameters objectForKey:@"sendDICOMtoAnyNodes"] isEqual:@"on"]];
				webUser.shareStudyWithUser = [NSNumber numberWithBool:[[parameters objectForKey:@"shareStudyWithUser"] isEqual:@"on"]];
				
				if (webUser.autoDelete.boolValue)
					webUser.deletionDate = [NSCalendarDate dateWithYear:[[parameters objectForKey:@"deletionDate_year"] integerValue] month:[[parameters objectForKey:@"deletionDate_month"] integerValue]+1 day:[[parameters objectForKey:@"deletionDate_day"] integerValue] hour:0 minute:0 second:0 timeZone:NULL];
				
				[webUser.managedObjectContext save:NULL];
				
				[tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Changes for user %@ successfully saved.", @"Web Portal, admin, user edition, save ok"), webUser.name]];
				user = webUser;
			} else
				userRecycleParams = YES;
		}
	}
	
	if ([action isEqual:@"new"]) {
		user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[[BrowserController currentBrowser] userManagedObjectContext]];
	//	[[[BrowserController currentBrowser] usersArrayController] addObject:user];
	}
	
	if (!action) { // edit
		originalName = [parameters objectForKey:@"name"];
		user = [[BrowserController currentBrowser] userWithName:originalName];
		if (!user)
			[tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't find user with name %@.", @"Web Portal, admin, user edition, edit error"), originalName]];
	}
	
	[tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"User Administration: %@", @"Web Portal, admin, user edition, title"), user? [user valueForKey:@"name"] : originalName] forKey:@"PageTitle"];
	if (user) [tokens setObject:[WebPortalProxy createWithObject:user transformer:[UserTransformer create]] forKey:@"User"];
	else if (userRecycleParams) [tokens setObject:parameters forKey:@"User"];
	
	//NSLog(@"USER: %@", user.description);
	
	[WebPortalData mutableString:templateString evaluateTokensWithDictionary:tokens];
	
	[response setDataWithString:templateString];
}

#pragma mark Session, custom authentication

-(void)replyToHTTPRequest {
	NSString* method = [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(request)) autorelease];
	NSString* cookie = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Cookie") autorelease];
	
	NSArray* cookieBits = [cookie componentsSeparatedByString:@"="];
	if (cookieBits.count == 2 && [[cookieBits objectAtIndex:0] isEqual:SessionCookieName])
		self.session = [WebPortalSession sessionForId:[cookieBits objectAtIndex:1]];
	
	if ([method isEqualToString:@"GET"]) { // no session, GET... check for tokens
		NSString* url = [[NSMakeCollectable(CFHTTPMessageCopyRequestURL(request)) autorelease] description];
		NSArray* urlComponenents = [url componentsSeparatedByString:@"?"];
		if (urlComponenents.count > 1) {
			NSDictionary* params = [WebPortalConnection ExtractParams:urlComponenents.lastObject];
			NSString* username = [params objectForKey:@"username"];
			NSString* token = [params objectForKey:@"token"];
			if (username && token) // has token, user exists
				self.session = [WebPortalSession sessionForUsername:username token:token];
		}
	}
	
	if (!session)
		self.session = [WebPortalSession create];

	if ([method isEqualToString:@"POST"] && multipartData.count == 1) // POST auth ?
	{
		NSData* data = multipartData.lastObject;
		NSString* paramsString = [[[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding] autorelease];
		NSDictionary* params = [WebPortalConnection ExtractParams:paramsString];
		
		if ([params objectForKey:@"login"]) {
			NSString* username = [params objectForKey:@"username"];
			NSString* password = [params objectForKey:@"password"];
			NSString* sha1 = [params objectForKey:@"sha1"];
			if (username.length && password.length && [password isEqual:[self passwordForUser:username]])
				[session setObject:username forKey:SessionUsernameKey];
			else if (username.length && sha1.length) {
				NSString* sha1internal = [[[[[self passwordForUser:username] stringByAppendingString:NotNil([session objectForKey:SessionChallengeKey])] dataUsingEncoding:NSUTF8StringEncoding] sha1Digest] hex];
				if ([sha1 compare:sha1internal options:NSLiteralSearch|NSCaseInsensitiveSearch] == NSOrderedSame) {
					[session setObject:username forKey:SessionUsernameKey];
					[session setObject:NULL forKey:SessionChallengeKey];
				}
			}
		}
		
		if ([params objectForKey:@"logout"]) {
			[session setObject:NULL forKey:SessionUsernameKey];
			[currentUser release]; currentUser = NULL;
		}
	}
	
	[super replyToHTTPRequest];
}

-(BOOL)isAuthenticated {
	if ([super isAuthenticated]) { // we still allow HTTP based auth - but is it still used?
		[session setObject:[currentUser valueForKey:@"username"] forKey:SessionUsernameKey];
		return YES;
	}

	NSString* sessionUser = [session objectForKey:SessionUsernameKey];
	if (sessionUser) {	// this sets currentUser to sessionUser
		[self passwordForUser:sessionUser];
		if (currentUser)
			return YES;
	} else {
		[currentUser release]; currentUser = NULL;
	}
	
	return NO;
}

-(NSString*)htmlLogin {
	NSMutableString* html = [self webServicesHTMLMutableString:@"login.html"];
	
	[WebPortalData mutableString:html block:@"AuthorizedRestorePasswordWebServer" setVisible:[[NSUserDefaults standardUserDefaults] boolForKey: @"restorePasswordWebServer"]];
	[html replaceOccurrencesOfString:@"%PageTitle%" withString:[NSString stringWithFormat:@"OsiriX Web Portal", currentUser.name]];
	
	return html;
}

// #defines from HTTPConnection.m
#define WRITE_ERROR_TIMEOUT 240
#define HTTP_RESPONSE 30

-(void)handleAuthenticationFailed
{
	HTTPAuthenticationRequest *auth = [[[HTTPAuthenticationRequest alloc] initWithRequest:request] autorelease];
	if (auth.username)
		[self updateLogEntryForStudy:nil withMessage:[NSString stringWithFormat:@"Wrong password for user %@", auth.username]];

	NSData* bodyData = [[self htmlLogin] dataUsingEncoding:NSUTF8StringEncoding];
	// Status Code 401 - Unauthorized
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 401, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", bodyData.length]);
	CFHTTPMessageSetBody(response, (CFDataRef)bodyData);
	
	[asyncSocket writeData:[self preprocessErrorResponse:response] withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(response);
}





@end
