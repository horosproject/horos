#import "OsiriXHTTPConnection.h"
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
#import "UserTable.h"
#import "DicomFile.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define INCOMINGPATH @"/INCOMING.noindex/"

static NSMutableDictionary *movieLock = nil;
static NSString *webDirectory = nil;
static NSString *language = nil;

#define maxResolution 1024

NSString* notNil( NSString *s)
{
	if( s == nil)
		return @"";
	else
		return s;
}

@interface NSImage (ProportionalScaling)
- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize;
@end

@implementation NSImage (ProportionalScaling)

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
{
	NSImage* sourceImage = self;
	NSImage* newImage = nil;
	
	if ([sourceImage isValid])
	{
		NSSize imageSize = [sourceImage size];
		float width  = imageSize.width;
		float height = imageSize.height;
		
		float targetWidth  = targetSize.width;
		float targetHeight = targetSize.height;
		
		float scaleFactor  = 0.0;
		float scaledWidth  = targetWidth;
		float scaledHeight = targetHeight;
		
		NSPoint thumbnailPoint = NSZeroPoint;
		
		if ( NSEqualSizes( imageSize, targetSize ) == NO )
		{
			
			float widthFactor  = targetWidth / width;
			float heightFactor = targetHeight / height;
			
			if ( widthFactor < heightFactor )
				scaleFactor = widthFactor;
			else
				scaleFactor = heightFactor;
			
			scaledWidth  = width  * scaleFactor;
			scaledHeight = height * scaleFactor;
			
			if ( widthFactor < heightFactor )
				thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
			
			else if ( widthFactor > heightFactor )
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
		}
		
		newImage = [[NSImage alloc] initWithSize:targetSize];
		
		if( [newImage size].width > 0 && [newImage size].height > 0)
		{
			[newImage lockFocus];
			
			NSRect thumbnailRect;
			thumbnailRect.origin = thumbnailPoint;
			thumbnailRect.size.width = scaledWidth;
			thumbnailRect.size.height = scaledHeight;
			
			[sourceImage drawInRect: thumbnailRect
						   fromRect: NSZeroRect
						  operation: NSCompositeSourceOver
						   fraction: 1.0];
			
			[newImage unlockFocus];
		}
	}
	
	return [newImage autorelease];
}
@end

@implementation OsiriXHTTPConnection

+ (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message forUser: (NSString*) user ip: (NSString*) ip
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"logWebServer"] == NO) return;
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
	if( context == nil)
		return;
	
	[context lock];
	
	if( user)
		message = [user stringByAppendingFormat:@" : %@", message];
	
	if( ip == nil)
		ip = [[AppController sharedAppController] privateIP];
	
	@try
	{
		NSManagedObject *logEntry = nil;
		
		logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
		[logEntry setValue: [NSDate date] forKey:@"startTime"];
		[logEntry setValue: @"Web" forKey:@"type"];
		
		if( study)
			[logEntry setValue: [study valueForKey: @"name"] forKey:@"patientName"];
		
		if( study)
			[logEntry setValue: [study valueForKey: @"studyName"] forKey:@"studyName"];
		
		[logEntry setValue: message forKey: @"message"];
		
		if( ip)
			[logEntry setValue: ip forKey: @"originName"];
	}
	@catch (NSException * e)
	{
		NSLog( @"****** OsiriX HTTPConnection updateLogEntry exception : %@", e);
	}

	[context unlock];
}

- (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message
{
	[OsiriXHTTPConnection updateLogEntryForStudy: study withMessage: message forUser: [currentUser valueForKey: @"name"] ip: [asyncSocket connectedHost]];
}

+ (void) checkWebDirectory
{
	#define PATH2HTML @"~/Library/Application Support/OsiriX/"
	
	if( webDirectory == nil)
	{
		language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex: 0];
		
		if( language == nil)
			language = @"English";
		
		[language retain];
		
		webDirectory = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"WebServicesHTML"];
		
		BOOL isDirectory;
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"customWebPages"])
		{
			NSString *supportPath = [PATH2HTML stringByExpandingTildeInPath];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: [supportPath stringByAppendingPathComponent: @"WebServicesHTML"] isDirectory: &isDirectory] == YES && isDirectory == YES)
				webDirectory = [supportPath stringByAppendingPathComponent: @"WebServicesHTML"];
			else
			{
				[[NSFileManager defaultManager] copyItemAtPath: webDirectory toPath: [supportPath stringByAppendingPathComponent: [webDirectory lastPathComponent]] error: nil];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: [supportPath stringByAppendingPathComponent: @"WebServicesHTML"] isDirectory: &isDirectory] == YES && isDirectory == YES)
					webDirectory = [supportPath stringByAppendingPathComponent: @"WebServicesHTML"];
			}
		}
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: [webDirectory stringByAppendingPathComponent: language] isDirectory: &isDirectory] == YES && isDirectory == YES)
			webDirectory = [webDirectory stringByAppendingPathComponent: language];
		else
			webDirectory = [webDirectory stringByAppendingPathComponent: @"English"];
		
			
		[webDirectory retain];
	}
}

+ (BOOL) sendNotificationsEmailsTo: (NSArray*) users aboutStudies: (NSArray*) filteredStudies predicate: (NSString*) predicate message: (NSString*) message replyTo: (NSString*) replyto customText: (NSString*) customText
{
	[OsiriXHTTPConnection checkWebDirectory];
	
	int webPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"httpWebServerPort"];
	NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
	
	NSString *webServerAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"webServerAddress"];
	if( [webServerAddress length] == 0)
		webServerAddress = [[AppController sharedAppController] privateIP];
	
	if( fromEmailAddress == nil)
		fromEmailAddress = @"";
	
	for( NSManagedObject *user in users)
	{
		NSMutableAttributedString *emailMessage = nil;
		
		if( message == nil)
			emailMessage = [[[NSMutableAttributedString alloc] initWithPath: [webDirectory stringByAppendingPathComponent:@"emailTemplate.txt"] documentAttributes: nil] autorelease];
		else
			emailMessage = [[[NSMutableAttributedString alloc] initWithString: message] autorelease];
		
		if( emailMessage)
		{
			NSString *http = [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptedWebServer"] ? @"https":@"http";
			
			if( customText == nil) customText = @"";
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%customText%" withString: notNil( [customText stringByAppendingString:@"\r\r"]) options: NSLiteralSearch range: NSMakeRange(0, [emailMessage length])];
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%Username%" withString: notNil( [user valueForKey: @"name"]) options: NSLiteralSearch range: NSMakeRange(0, [emailMessage length])];
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%WebServerAddress%" withString: [NSString stringWithFormat: @"%@://%@:%d", http, webServerAddress, webPort] options: NSLiteralSearch range: NSMakeRange(0, [emailMessage length])];
			
			NSMutableString *urls = [NSMutableString string];
			
			if( [filteredStudies count] > 1 && predicate != nil)
			{
				[urls appendString: NSLocalizedString( @"To view this entire list, including patients names:\r", nil)]; 
				[urls appendFormat: @"%@ : %@://%@:%d/studyList?%@\r\r\r\r", NSLocalizedString( @"Click here", nil), http, predicate]; 
			}
			
			for( NSManagedObject *s in filteredStudies)
			{
				[urls appendFormat: @"%@ - %@ (%@)\r", [s valueForKey: @"modality"], [s valueForKey: @"studyName"], [BrowserController DateTimeFormat: [s valueForKey: @"date"]]]; 
				[urls appendFormat: @"%@ : %@://%@:%d/study?id=%@&browse=all\r\r", NSLocalizedString( @"Click here", nil), http, webServerAddress, webPort, [s valueForKey: @"studyInstanceUID"]]; 
			}
			
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%URLsList%" withString: notNil( urls) options: NSLiteralSearch range: NSMakeRange(0, [emailMessage length])];
			
			NSString *emailAddress = [user valueForKey: @"email"];
			
			NSString *emailSubject = nil;
			if( replyto)
				emailSubject = [NSString stringWithFormat: NSLocalizedString( @"A new radiology exam is available for you, from %@", nil), replyto];
			else
				emailSubject = NSLocalizedString( @"A new radiology exam is available for you !", nil);
			
			[[CSMailMailClient mailClient] deliverMessage: emailMessage headers: [NSDictionary dictionaryWithObjectsAndKeys: emailAddress, @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", replyto, @"ReplyTo", nil]];
			
			for( NSManagedObject *s in filteredStudies)
			{
				[OsiriXHTTPConnection updateLogEntryForStudy: s withMessage: @"notification email" forUser: [user valueForKey: @"name"] ip: webServerAddress];
			}
		}
		else NSLog( @"********* warning : CANNOT send notifications emails, because emailTemplate.txt == nil");
	}
	
	return YES; // succeeded
}

+ (void) emailNotifications
{
	if( [NSThread isMainThread] == NO)
	{
		NSLog( @"********* applescript needs to be in the main thread");
		return;
	}
	
	[OsiriXHTTPConnection checkWebDirectory];

	// Lets check if new studies are available for each users! and if temporary users reached the end of their life.....
	
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]];
	NSString *newCheckString = [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]];
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"lastNotificationsDate"] == nil)
	{
		[[NSUserDefaults standardUserDefaults] setValue: [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]] forKey: @"lastNotificationsDate"];
		return;
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
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
		
		for( NSManagedObject *user in users)
		{
			if( [[user valueForKey: @"autoDelete"] boolValue] == YES && [[user valueForKey: @"deletionDate"] timeIntervalSinceDate: [NSDate date]] < 0)
			{
				NSLog( @"----- Temporary User reached the EOL (end-of-life) : %@", [user valueForKey: @"name"]);
				
				[OsiriXHTTPConnection updateLogEntryForStudy: nil withMessage: @"temporary user deleted" forUser: [user valueForKey: @"name"] ip: [[NSUserDefaults standardUserDefaults] valueForKey: @"webServerAddress"]];
				
				toBeSaved = YES;
				[[[BrowserController currentBrowser] userManagedObjectContext] deleteObject: user];
			}
		}
		
		if( toBeSaved)
			[[[BrowserController currentBrowser] userManagedObjectContext] save: nil];
	}
	@catch (NSException *e)
	{
		NSLog( @"***** emailNotifications exception for deleting temporary users: %@", e);
	}
	
	// CHECK dateAdded
	
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
		
		NSString *webServerAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"webServerAddress"];
		if( [webServerAddress length] == 0)
			webServerAddress = [[AppController sharedAppController] privateIP];
		
		int webPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"httpWebServerPort"];
		
		if( [studies count] > 0)
		{
			// Find all users
			error = nil;
			dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
			[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
			
			error = nil;
			NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
			
			for( NSManagedObject *user in users)
			{
				if( [[user valueForKey: @"emailNotification"] boolValue] == YES && [(NSString*) [user valueForKey: @"email"] length] > 2)
				{
					NSArray *filteredStudies = studies;
					
					@try
					{
						filteredStudies = [studies filteredArrayUsingPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [user valueForKey: @"studyPredicate"]]];
						filteredStudies = [OsiriXHTTPConnection addSpecificStudiesToArray: filteredStudies forUser: user predicate: [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]]];
						filteredStudies = [filteredStudies filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]]]; 
						filteredStudies = [filteredStudies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
					}
					@catch (NSException * e)
					{
						NSLog( @"******* studyPredicate exception : %@ %@", e, user);
					}
					
					if( [filteredStudies count] > 0)
					{
						[OsiriXHTTPConnection sendNotificationsEmailsTo: [NSArray arrayWithObject: user] aboutStudies: filteredStudies predicate: [NSString stringWithFormat: @"browse=newAddedStudies&browseParameter=%lf", [lastCheckDate timeIntervalSinceReferenceDate]] message: nil replyTo: nil customText: nil];
					}
				}
			}
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"***** emailNotifications exception: %@", e);
	}
	
	[[[BrowserController currentBrowser] userManagedObjectContext] unlock];
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	[[NSUserDefaults standardUserDefaults] setValue: newCheckString forKey: @"lastNotificationsDate"];
}

- (BOOL) isPasswordProtected:(NSString *)path
{
	if( [path hasPrefix: @"/wado"])
		return NO;
		
	if( [path hasPrefix: @"/images/"])
		return NO;
	
	if( [path isEqualToString: @"/"])
		return NO;
	
	if( [path isEqualToString: @"/style.css"])
		return NO;
	
	if( [path isEqualToString: @"/styleswitcher.js"])
		return NO;
	
	if( [path isEqualToString: @"/iPhoneStyle.css"])
		return NO;
	
	if( [path hasPrefix: @"/password_forgotten"])
		return NO;
	
	if( [path hasPrefix: @"/index"])
		return NO;
		
	if( [path isEqualToString: @"/favicon.ico"])
		return NO;
	
	return [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"];
}

- (BOOL)useDigestAccessAuthentication
{
	// Digest access authentication is the default setting.
	// Notice in Safari that when you're prompted for your password,
	// Safari tells you "Your login information will be sent securely."
	// 
	// If you return NO in this method, the HTTP server will use
	// basic authentication. Try it and you'll see that Safari
	// will tell you "Your password will be sent unencrypted",
	// which is strongly discouraged.
	
	return YES;
}

- (void)handleAuthenticationFailed
{
	[super handleAuthenticationFailed];
	
	HTTPAuthenticationRequest *auth = [[[HTTPAuthenticationRequest alloc] initWithRequest:request] autorelease];
	
	if( [self useDigestAccessAuthentication])
	{
		if(![auth isDigest])
			return ;
		
		if( [auth username])
			[self updateLogEntryForStudy: nil withMessage: [NSString stringWithFormat: @"Wrong password for user %@", [auth username]]];
	}
}

- (NSString *) passwordForUser:(NSString *)username
{
	[currentUser release];
	currentUser = nil;
	
	if( [username length] > 3)
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
		@catch ( NSException *e)
		{
			NSLog( @"******* passwordForUser exception: %@", e);
		}
		
		[[[BrowserController currentBrowser] userManagedObjectContext] unlock];
		
		if( [users count] == 0)
		{
			[self updateLogEntryForStudy: nil withMessage: [NSString stringWithFormat: @"Unknown user: %@", username]];
			return nil;
		}
		if( [users count] > 1)
		{
			NSLog( @"******** WARNING multiple users with identical user name : %@", username);
		}
		
		currentUser = [[users lastObject] retain];
	}
	else return nil;
	
	return [currentUser valueForKey: @"password"];
}

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)isSecureServer
{
	// Create an HTTPS server (all connections will be secured via SSL/TLS)
	return [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptedWebServer"];
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
	if( identity == nil)
	{
		[DDKeychain createNewIdentity];
		identity = (id)[DDKeychain KeychainAccessPreferredIdentityForName:@"com.osirixviewer.osirixwebserver" keyUse:CSSM_KEYUSE_ANY];
	}
	return [NSArray arrayWithObject:identity];
}

- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer
{
    if ((self = [super initWithAsyncSocket: newSocket forServer: myServer]))
	{
		[OsiriXHTTPConnection checkWebDirectory];
    }
    return self;
}

- (void) dealloc
{
	[sendLock lock];
	[sendLock unlock];
	[sendLock release];
	
	[selectedDICOMNode release];
	[selectedImages release];
	[ipAddressString release];
	[currentUser release];
	
	[multipartData release];
	[postBoundary release];
	[POSTfilename release];
	[urlParameters release];
	
	
	[super dealloc];
}

- (NSTimeInterval)startOfDay:(NSCalendarDate *)day
{
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: nil];
	return [start timeIntervalSinceReferenceDate];
}

- (NSMutableString*) setBlock: (NSString*) b visible: (BOOL) v forString: (NSMutableString*) s
{
	NSString *begin = [NSString stringWithFormat: @"%%%@%%", b];
	NSString *end = [NSString stringWithFormat: @"%%/%@%%", b];
	
	if( v == NO)
	{
		NSArray *tempArray = [s componentsSeparatedByString: begin];
		NSArray *tempArray2 = [[tempArray lastObject] componentsSeparatedByString: end];
		s = [NSMutableString stringWithFormat: @"%@%@", [tempArray objectAtIndex:0], [tempArray2 lastObject]];
	}
	else
	{
		[s replaceOccurrencesOfString: begin withString: @"" options: NSLiteralSearch range: NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString: end withString: @"" options: NSLiteralSearch range: NSMakeRange(0, [s length])];
	}
	
	return s;
}

- (NSMutableString*)htmlStudy:(DicomStudy*)study parameters:(NSDictionary*)parameters settings: (NSDictionary*) settings;
{
	BOOL dicomSend = NO;
	BOOL shareSend = NO;
	
	if( currentUser == nil || [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue])
		dicomSend = YES;
		
	if( currentUser && [[currentUser valueForKey: @"shareStudyWithUser"] boolValue])
		shareSend = YES;
	
	NSArray *users = nil;
	
	if( shareSend)
	{
		// Find all users
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		
		error = nil;
		users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error: &error];
		
		if( [users count] == 1) // only current user...
			shareSend = NO;
	}
	
	if( currentUser && [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue] == YES && [[currentUser valueForKey: @"sendDICOMtoAnyNodes"] boolValue] == NO)
	{
		if( [[parameters objectForKey: @"dicomcstoreport"] intValue] > 0 && [ipAddressString length] >= 7)
		{
		}
		else dicomSend = NO;
	}
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"study.html"]];
	
	templateString = [self setBlock: @"SendingFunctions1" visible: dicomSend forString: templateString];
	templateString = [self setBlock: @"SendingFunctions2" visible: dicomSend forString: templateString];
	templateString = [self setBlock: @"SendingFunctions3" visible: dicomSend forString: templateString];
	templateString = [self setBlock: @"SharingFunctions" visible: shareSend forString: templateString];
	templateString = [self setBlock: @"ZIPFunctions" visible:((currentUser == nil || [[currentUser valueForKey: @"downloadZIP"] boolValue]) && ![[settings valueForKey:@"iPhone"] boolValue]) forString: templateString];
	
	[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSString *browse = notNil( [parameters objectForKey:@"browse"]);
	NSString *browseParameter = notNil( [parameters objectForKey:@"browseParameter"]);
	NSString *search = notNil( [parameters objectForKey:@"search"]);
	NSString *album = notNil( [parameters objectForKey:@"album"]);
	
	[templateString replaceOccurrencesOfString:@"%browse%" withString: notNil( browse) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%browseParameter%" withString: notNil( browseParameter) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%search%" withString: notNil( [OsiriXHTTPConnection decodeURLString:search]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%album%" withString: notNil( [OsiriXHTTPConnection decodeURLString: [album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSString *LocalizedLabel_StudyList = @"";
	if(![search isEqualToString:@""])
		LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Search Result for", nil), [[OsiriXHTTPConnection decodeURLString:search] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else if(![album isEqualToString:@""])
		LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Album", nil), [[OsiriXHTTPConnection decodeURLString:album] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else
	{
		if([browse isEqualToString:@"6hours"])
			LocalizedLabel_StudyList = NSLocalizedString(@"Last 6 Hours", nil);
		else if([browse isEqualToString:@"today"])
			LocalizedLabel_StudyList = NSLocalizedString(@"Today", nil);
		else
			LocalizedLabel_StudyList = NSLocalizedString(@"Study List", nil);
	}
	
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyList%" withString: notNil( LocalizedLabel_StudyList) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	templateString = [self setBlock: @"Report" visible: ([study valueForKey:@"reportURL"] && ![[settings valueForKey:@"iPhone"] boolValue]) forString: templateString];
	
	if( [[[study valueForKey:@"reportURL"] pathExtension] isEqualToString: @"pages"])
		[templateString replaceOccurrencesOfString:@"%reportExtension%" withString: notNil( @"zip") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	else
		[templateString replaceOccurrencesOfString:@"%reportExtension%" withString: notNil( [[study valueForKey:@"reportURL"] pathExtension]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
	NSArray *tempArray = [templateString componentsSeparatedByString:@"%SeriesListItem%"];
	NSString *templateStringStart = [tempArray objectAtIndex:0];
	tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/SeriesListItem%"];
	NSString *seriesListItemString = [tempArray objectAtIndex:0];
	NSString *templateStringEnd = [tempArray lastObject];
	
	NSMutableString *returnHTML = [NSMutableString stringWithString: templateStringStart];
	
	[returnHTML replaceOccurrencesOfString:@"%PageTitle%" withString:notNil( [study valueForKey:@"name"]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%PatientID%" withString:notNil( [study valueForKey:@"patientID"]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%PatientName%" withString:notNil( [study valueForKey:@"name"]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyComment%" withString:notNil( [study valueForKey:@"comment"]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:notNil( [study valueForKey:@"studyName"]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyModality%" withString:notNil( [study valueForKey:@"modality"]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
	if( [[study valueForKey:@"stateText"] intValue] == 0)
		stateText = nil;
	[returnHTML replaceOccurrencesOfString:@"%StudyState%" withString:notNil( stateText) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	NSDateFormatter *dobDateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dobDateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateOfBirthFormat2"]];
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
	
	[returnHTML replaceOccurrencesOfString:@"%PatientDOB%" withString: notNil( [dobDateFormat stringFromDate:[study valueForKey:@"dateOfBirth"]]) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyDate%" withString: [OsiriXHTTPConnection iPhoneCompatibleNumericalFormat: [dateFormat stringFromDate: [study valueForKey:@"date"]]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
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
	for(DicomSeries *series in seriesArray)
	{
		NSMutableString *tempHTML = [NSMutableString stringWithString:seriesListItemString];
		
		[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		lineNumber++;
		
		[tempHTML replaceOccurrencesOfString:@"%SeriesName%" withString: notNil( [series valueForKey:@"name"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%thumbnail%" withString: [NSString stringWithFormat:@"thumbnail?id=%@&studyID=%@", notNil( [series valueForKey:@"seriesInstanceUID"]), notNil( [study valueForKey:@"studyInstanceUID"])] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesID%" withString: notNil( [series valueForKey:@"seriesInstanceUID"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesComment%" withString: notNil( [series valueForKey:@"comment"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%PatientName%" withString: notNil( [series valueForKeyPath:@"study.name"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		if( [DCMAbstractSyntaxUID isPDF: [series valueForKey: @"seriesSOPClassUID"]])
			[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @".pdf"  options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @""  options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];

		NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[series valueForKey: @"stateText"] intValue]];
		if( [[series valueForKey:@"stateText"] intValue] == 0)
			stateText = nil;
		[tempHTML replaceOccurrencesOfString:@"%SeriesState%" withString: notNil( stateText) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		int nbFiles = [[series valueForKey:@"noFiles"] intValue];
		if( nbFiles <= 1)
		{
			if( nbFiles == 0)
				nbFiles = 1;
		}
		NSString *imagesLabel = (nbFiles>1)? NSLocalizedString(@"Images", nil) : NSLocalizedString(@"Image", nil);
		[tempHTML replaceOccurrencesOfString:@"%SeriesImageNumber%" withString: [NSString stringWithFormat:@"%d %@", nbFiles, imagesLabel] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSString *checked = @"";
		for(NSString* selectedID in [parameters objectForKey:@"selected"])
		{
			if([[series valueForKey:@"seriesInstanceUID"] isEqualToString:[[selectedID stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]])
				checked = @"checked";
		}
		
		[tempHTML replaceOccurrencesOfString:@"%checked%" withString: notNil( checked) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		[returnHTML appendString:tempHTML];
	}
	
	NSMutableString *tempHTML = [NSMutableString stringWithString:templateStringEnd];
	[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2] options:NSLiteralSearch range:NSMakeRange(0, [templateStringEnd length])];
	templateStringEnd = [NSString stringWithString:tempHTML];
	
	NSString *dicomNodesListItemString = @"";
	if( dicomSend)
	{
		tempArray = [templateStringEnd componentsSeparatedByString:@"%dicomNodesListItem%"];
		templateStringStart = [tempArray objectAtIndex:0];
		tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/dicomNodesListItem%"];
		dicomNodesListItemString = [tempArray objectAtIndex:0];
		templateStringEnd = [tempArray lastObject];
		[returnHTML appendString:templateStringStart];
		
		NSString *checkAllStyle = @"";
		if([seriesArray count]<=1) checkAllStyle = @"style='display:none;'";
		[returnHTML replaceOccurrencesOfString:@"%CheckAllStyle%" withString: notNil( checkAllStyle) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		
		if( [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue] == YES)
		{
			NSString *dicomNodeAddress = ipAddressString;
			NSString *dicomNodePort = [parameters objectForKey: @"dicomcstoreport"];
			NSString *dicomNodeAETitle = @"This Computer";
			
			NSString *dicomNodeSyntax;
			if( [[settings valueForKey:@"iPhone"] boolValue]) dicomNodeSyntax = @"5";
			else dicomNodeSyntax = @"0";
			NSString *dicomNodeDescription = @"This Computer";
			
			NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString: notNil( dicomNodeAddress) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString: notNil( dicomNodePort) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString: notNil( dicomNodeAETitle) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString: notNil( dicomNodeSyntax) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];

			if(![[settings valueForKey:@"iPhone"] boolValue])
				dicomNodeDescription = [dicomNodeDescription stringByAppendingFormat:@" [%@:%@]", notNil( dicomNodeAddress), notNil( dicomNodePort)];
			
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString: notNil( dicomNodeDescription) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			
			[returnHTML appendString:tempHTML];
		}
	
		if( [[currentUser valueForKey: @"sendDICOMtoAnyNodes"] boolValue] == YES)
		{
			NSArray *nodes = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
			for(NSDictionary *node in nodes)
			{
				NSString *dicomNodeAddress = notNil( [node objectForKey:@"Address"]);
				NSString *dicomNodePort = [NSString stringWithFormat:@"%d", [[node objectForKey:@"Port"] intValue]];
				NSString *dicomNodeAETitle = notNil( [node objectForKey:@"AETitle"]);
				NSString *dicomNodeSyntax = [NSString stringWithFormat:@"%d", [[node objectForKey:@"TransferSyntax"] intValue]];
				NSString *dicomNodeDescription = notNil( [node objectForKey:@"Description"]);
				
				NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString: notNil( dicomNodeAddress) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString: notNil( dicomNodePort) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString: notNil( dicomNodeAETitle) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString: notNil( dicomNodeSyntax) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
				
				if(![[settings valueForKey:@"iPhone"] boolValue])
					dicomNodeDescription = [dicomNodeDescription stringByAppendingFormat:@" [%@:%@]", notNil( dicomNodeAddress), notNil( dicomNodePort)];
				
				[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString: notNil( dicomNodeDescription) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
				
				NSString *selected = @"";
				
				if( [parameters objectForKey:@"dicomDestination"])
				{
					NSString * s = [[parameters objectForKey:@"dicomDestination"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					NSArray *sArray = [s componentsSeparatedByString: @":"];
					
					if( [sArray count] >= 2)
					{
						if( [[sArray objectAtIndex: 0] isEqualToString: dicomNodeAddress] && 
						   [[sArray objectAtIndex: 1] isEqualToString: dicomNodePort])
							selected = @"selected";
					}
				}
				else if( ipAddressString && [[parameters objectForKey: @"dicomcstoreport"] intValue] == 0)
				{
					// Try to match the calling http client in our destination nodes
					
					struct sockaddr_in service;
					const char	*host_name = [[node valueForKey:@"Address"] UTF8String];
					
					bzero((char *) &service, sizeof(service));
					service.sin_family = AF_INET;
					
					if( host_name)
					{
						if (isalpha(host_name[0]))
						{
							struct hostent *hp;
							
							hp = gethostbyname( host_name);
							if( hp) bcopy(hp->h_addr, (char *) &service.sin_addr, hp->h_length);
							else service.sin_addr.s_addr = inet_addr( host_name);
						}
						else service.sin_addr.s_addr = inet_addr( host_name);
						
						char buffer[256];
						
						if (inet_ntop(AF_INET, &service.sin_addr, buffer, sizeof(buffer)))
						{
							if( [[NSString stringWithCString:buffer] isEqualToString: ipAddressString])
								selected = @"selected";
						}
					}
				}
				
				[tempHTML replaceOccurrencesOfString:@"%selected%" withString: notNil( selected) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
				
				[returnHTML appendString:tempHTML];
			}
		}
		
		[returnHTML appendString:templateStringEnd];
		
		if([[parameters objectForKey:@"CheckAll"] isEqualToString:@"on"] || [[parameters objectForKey:@"CheckAll"] isEqualToString:@"checked"])
		{
			[returnHTML replaceOccurrencesOfString:@"%CheckAllChecked%" withString: @"checked" options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		}
		else
		{
			[returnHTML replaceOccurrencesOfString:@"%CheckAllChecked%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		}
	}
	else [returnHTML appendString:templateStringEnd];
	
	if( shareSend)
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
			
			for( NSManagedObject *user in users)
			{
				if( user != currentUser)
				{
					NSMutableString *tempHTML = [NSMutableString stringWithString: userListItemString];
					
					[tempHTML replaceOccurrencesOfString:@"%username%" withString: notNil( [user valueForKey: @"name"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
					[tempHTML replaceOccurrencesOfString:@"%email%" withString: notNil( [user valueForKey: @"email"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
					
					NSString *userDescription = [NSString stringWithString:notNil([user valueForKey:@"name"])];
					if(![[settings valueForKey:@"iPhone"] boolValue])
						userDescription = [userDescription stringByAppendingFormat:@" (%@)", notNil([user valueForKey:@"email"])];
					
					[tempHTML replaceOccurrencesOfString:@"%userDescription%" withString: notNil(userDescription) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
					
					[returnHTML appendString: tempHTML];
				}
			}
		}
		@catch ( NSException *e)
		{
			NSLog( @"****** exception in find all users htmlStudy: %@", e);
		}
		
		[returnHTML appendString: templateStringEnd];
	}
	
	[context unlock];
	
	return returnHTML;
}

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies settings: (NSDictionary*) settings
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"studyList.html"]];
	
	templateString = [self setBlock: @"ZIPFunctions" visible: ( currentUser && [[currentUser valueForKey: @"downloadZIP"] boolValue] && ![[settings valueForKey:@"iPhone"] boolValue]) forString: templateString];
	
	[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSArray *tempArray = [templateString componentsSeparatedByString:@"%StudyListItem%"];
	NSString *templateStringStart = [tempArray objectAtIndex:0];
	tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/StudyListItem%"];
	NSString *studyListItemString = [tempArray objectAtIndex:0];
	NSString *templateStringEnd = [tempArray lastObject];
	
	NSMutableString *returnHTML = [NSMutableString stringWithString:templateStringStart];
	
	int lineNumber = 0;
	for(DicomStudy *study in studies)
	{
		NSMutableString *tempHTML = [NSMutableString stringWithString:studyListItemString];
		
		[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		lineNumber++;
		
		// asciiString?
		[tempHTML replaceOccurrencesOfString:@"%StudyListItemName%" withString: notNil( [study valueForKey:@"name"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSArray *seriesArray = [study valueForKey:@"imageSeries"] ; //imageSeries
		int count = 0;
		for(DicomSeries *series in seriesArray)
		{
			count++;
		}
		
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
		
		NSString *date = [dateFormat stringFromDate:[study valueForKey:@"date"]];
		
		NSString *dateLabel = [NSString stringWithFormat:@"%@", [OsiriXHTTPConnection iPhoneCompatibleNumericalFormat:date]];
		dateLabel = [OsiriXHTTPConnection unbreakableStringWithString:dateLabel];
		BOOL displayBlock = YES;
		if([dateLabel length])
			[tempHTML replaceOccurrencesOfString:@"%StudyDate%" withString:dateLabel options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			displayBlock = NO;
			
		tempHTML = [self setBlock:@"StudyDateBlock" visible:displayBlock forString:tempHTML];

		NSString *seriesCountLabel = [NSString stringWithFormat:@"%d Series", count];
		displayBlock = YES;
		if([seriesCountLabel length])
			[tempHTML replaceOccurrencesOfString:@"%SeriesCount%" withString:seriesCountLabel options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			displayBlock = NO;
			
		tempHTML = [self setBlock:@"SeriesCountBlock" visible:displayBlock forString:tempHTML];
		
		NSString *studyCommentLabel = notNil([study valueForKey:@"comment"]);
		displayBlock = YES;
		if([studyCommentLabel length])
			[tempHTML replaceOccurrencesOfString:@"%StudyComment%" withString:studyCommentLabel options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			displayBlock = NO;
			
		tempHTML = [self setBlock:@"StudyCommentBlock" visible:displayBlock forString:tempHTML];
		
		NSString *studyDescriptionLabel = notNil([study valueForKey:@"studyName"]);
		displayBlock = YES;
		if([studyDescriptionLabel length])
			[tempHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:studyDescriptionLabel options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			displayBlock = NO;
			
		tempHTML = [self setBlock:@"StudyDescriptionBlock" visible:displayBlock forString:tempHTML];
		
		NSString *studyModalityLabel = notNil([study valueForKey:@"modality"]);
		displayBlock = YES;
		if([studyModalityLabel length])
			[tempHTML replaceOccurrencesOfString:@"%StudyModality%" withString:studyModalityLabel options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			displayBlock = NO;
			
		tempHTML = [self setBlock:@"StudyModalityBlock" visible:displayBlock forString:tempHTML];
				
		NSString *stateText = @"";
		if( [[study valueForKey:@"stateText"] intValue])
			stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
		
		NSString *studyStateLabel = notNil( stateText);
		displayBlock = YES;
		if([studyStateLabel length])
			[tempHTML replaceOccurrencesOfString:@"%StudyState%" withString:studyStateLabel options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		else
			displayBlock = NO;
		
		tempHTML = [self setBlock:@"StudyStateBlock" visible:displayBlock forString:tempHTML];
		
		[tempHTML replaceOccurrencesOfString:@"%StudyListItemID%" withString: notNil( [study valueForKey:@"studyInstanceUID"]) options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[returnHTML appendString:tempHTML];
	}
	
	[returnHTML appendString:templateStringEnd];
	
	[context unlock];
	
	return returnHTML;
}

- (NSArray*) addSpecificStudiesToArray: (NSArray*) array
{
	return [OsiriXHTTPConnection addSpecificStudiesToArray: array forUser: currentUser predicate: nil];
}

+ (NSArray*) addSpecificStudiesToArray: (NSArray*) array forUser: (NSManagedObject*) user predicate: (NSPredicate*) predicate
{
	NSMutableArray *specificArray = [NSMutableArray array];
	
	if( predicate == nil)
		predicate = [NSPredicate predicateWithValue: YES];
	
	@try
	{
		if( [[[user valueForKey: @"studies"] allObjects] count])
		{
			// Find all studies
			NSError *error = nil;
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
			[dbRequest setPredicate: predicate];
			
			error = nil;
			NSArray *studiesArray = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error: &error];
			
			for( NSManagedObject *study in [user valueForKey: @"studies"])
			{
				NSArray *obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", [study valueForKey: @"patientUID"], [study valueForKey: @"studyInstanceUID"]]];
				
				if( [obj count] == 1)
					[specificArray addObject: [obj lastObject]];
				else if( [obj count] > 1)
					NSLog( @"********** warning multiple studies with same instanceUID and patientUID : %@", obj);
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
		
		if( [sortValue length] && [sortValue isEqualToString: @"date"] == NO)
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES] autorelease]]];
		else
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
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
	
	if( [(NSString*) [currentUser valueForKey: @"studyPredicate"] length] > 0) // First, take all the available studies for this user, and then get the series : SECURITY : we want to be sure that he cannot access to unauthorized images
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
		
		if( studiesArray)
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
	
	NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
	NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	NSArray * sortDescriptors;
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
	[sortid release];
	[sortdate release];
	
	seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
	
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
		NSLog(@"studiesForAlbum exception: %@", e.description);
	}
	
	[context unlock];
	
	NSManagedObject *album = [albumArray lastObject];
	
	if([[album valueForKey:@"smartAlbum"] intValue] == 1)
	{
		studiesArray = [self studiesForPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [album valueForKey:@"predicateString"]] sortBy: [urlParameters objectForKey:@"order"]];
	}
	else
	{
		NSArray *originalAlbum = [[album valueForKey:@"studies"] allObjects];
		
		if( currentUser && [(NSString*) [currentUser valueForKey: @"studyPredicate"] length] > 0)
		{
			@try
			{
				studiesArray = [originalAlbum filteredArrayUsingPredicate: [[BrowserController currentBrowser] smartAlbumPredicateString: [currentUser valueForKey: @"studyPredicate"]]];
				
				NSArray *specificArray = [self addSpecificStudiesToArray: [NSArray array]];
				
				for( NSManagedObject *specificStudy in specificArray)
				{
					if( [originalAlbum containsObject: specificStudy] == YES && [studiesArray containsObject: specificStudy] == NO)
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
		
		if( [sortValue length] && [sortValue isEqualToString: @"date"] == NO)
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES] autorelease]]];
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
	
	if( sendLock == nil)
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

+ (NSString*)encodeURLString:(NSString*)aString;
{
	if( aString == nil) aString = @"";
	
	NSMutableString *encodedString = [NSMutableString stringWithString:aString];
	[encodedString replaceOccurrencesOfString:@":" withString:@"%3A" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@";" withString:@"%3B" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"@" withString:@"%40" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@" " withString:@"+" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"&" withString:@"%26" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	return encodedString;
}

+ (NSString*)decodeURLString:(NSString*)aString;
{
	if( aString == nil) aString = @"";
	
	NSMutableString *encodedString = [NSMutableString stringWithString:aString];
	[encodedString replaceOccurrencesOfString:@"%3A" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%2F" withString:@"/" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%25" withString:@"%" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%23" withString:@"#" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%3B" withString:@";" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%40" withString:@"@" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%26" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	return encodedString;
}

+ (NSString *)encodeCharacterEntitiesIn:(NSString *)source;
{ 
	if(!source) return nil;
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
		for(i = 0; i < count; i++)
		{
			NSRange range = [source rangeOfString: [NSString stringWithFormat: @"%C", 160 + i]];
			if(range.location != NSNotFound)
			{
				[escaped replaceOccurrencesOfString: [NSString stringWithFormat: @"%C", 160 + i]
										 withString: [codes objectAtIndex: i] 
											options: NSLiteralSearch 
											  range: NSMakeRange(0, [escaped length])];
			}
		}
		return escaped;    // Note this is autoreleased
	}
}

+ (NSString *)decodeCharacterEntitiesIn:(NSString *)source;
{ 
	if(!source) return nil;
	else if([source rangeOfString: @"&"].location == NSNotFound) return source;
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
		for(i = 0; i < count; i++)
		{
			NSRange range = [source rangeOfString: [codes objectAtIndex: i]];
			if(range.location != NSNotFound)
			{
				[escaped replaceOccurrencesOfString: [codes objectAtIndex: i] 
										 withString: [NSString stringWithFormat: @"%C", 160 + i] 
											options: NSLiteralSearch 
											  range: NSMakeRange(0, [escaped length])];
			}
		}
		return escaped;    // Note this is autoreleased
	}
}

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
	[newString replaceOccurrencesOfString:@" " withString:@"&nbsp;" options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
	return [NSString stringWithString:newString];
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
	if( [AppController mainThread] != [NSThread currentThread])
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
	
	if( [AppController mainThread] != [NSThread currentThread])
	{
		[aMovie detachFromCurrentThread];
		[QTMovie exitQTKitOnThread];
	}
}

- (void) generateMovie: (NSMutableDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( movieLock == nil)
		movieLock = [[NSMutableDictionary alloc] init];
	
	NSString *outFile = [dict objectForKey: @"outFile"];
	NSString *fileName = [dict objectForKey: @"fileName"];
	NSArray *dicomImageArray = [dict objectForKey: @"dicomImageArray"];
	BOOL isiPhone = [[dict objectForKey:@"isiPhone"] boolValue];
	
	NSMutableArray *imagesArray = [NSMutableArray array];
	
	if( [movieLock objectForKey: outFile] == nil)
		[movieLock setObject: [[[NSRecursiveLock alloc] init] autorelease] forKey: outFile];
	
	[[movieLock objectForKey: outFile] lock];
	
	if( ![[NSFileManager defaultManager] fileExistsAtPath: outFile])
	{
		int maxWidth, maxHeight;
		
		if( isiPhone)
		{
			maxWidth = 300; // for the poster frame of the movie to fit in the iphone screen (vertically)
			maxHeight = 310;
		}
		else
		{
			maxWidth = maxResolution;
			maxHeight = maxResolution;
		}
		
		
		NSMutableArray *pixs = [NSMutableArray arrayWithCapacity: [dicomImageArray count]];
		
		[[[BrowserController currentBrowser] managedObjectContext] lock];
		
		for (DicomImage *im in dicomImageArray)
		{
			DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [im valueForKey:@"completePathResolved"] :0 :1 :nil :[[im valueForKey:@"frameID"] intValue] :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im];
			
			if(dcmPix)
			{
				float curWW = 0;
				float curWL = 0;
				
				if([[im valueForKey:@"series"] valueForKey:@"windowWidth"])
				{
					curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
					curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
				}
				
				if( curWW != 0)
					[dcmPix checkImageAvailble:curWW :curWL];
				else
					[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
				
				[pixs addObject: dcmPix];
				[dcmPix release];
			}
		}
		
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
				
		for (DCMPix *dcmPix in pixs)
		{
			NSImage *im = [dcmPix image];
			
			int width = [dcmPix pwidth];
			int height = [dcmPix pheight];
			
			BOOL resize = NO;
			
			if(width>maxWidth)
			{
				height = height * maxWidth / width;
				width = maxWidth;
				resize = YES;
			}
			
			if(height>maxHeight)
			{
				width = width * maxHeight / height;
				height = maxHeight;
				resize = YES;
			}
			
			NSImage *newImage;
			
			if( resize)
				newImage = [im imageByScalingProportionallyToSize:NSMakeSize(width, height)];
			else
				newImage = im;
			
			[imagesArray addObject: newImage];
		}
		
		[[NSFileManager defaultManager] removeItemAtPath: [fileName stringByAppendingString: @" dir"] error: nil];
		[[NSFileManager defaultManager] createDirectoryAtPath: [fileName stringByAppendingString: @" dir"] attributes: nil];
		
		int inc = 0;
		for( NSImage *img in imagesArray)
		{
			[[img TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 1.0] writeToFile: [[fileName stringByAppendingString: @" dir"] stringByAppendingPathComponent: [NSString stringWithFormat: @"%6.6d.tiff", inc]] atomically: YES];
			inc++;
		}
		
		NSTask *theTask = [[[NSTask alloc] init] autorelease];
		
		if( isiPhone)
		{
			@try
			{
				NSArray *parameters = [NSArray arrayWithObjects: fileName, @"writeMovie", [fileName stringByAppendingString: @" dir"], nil];
				
				[theTask setArguments: parameters];
				[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
				[theTask launch];
				
				while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
			}
			@catch ( NSException *e)
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
			@catch ( NSException *e)
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
			@catch ( NSException *e)
			{
				NSLog( @"***** writeMovie exception : %@", e);
			}
		}
	}
	
	[[movieLock objectForKey: outFile] unlock];
	
	if( [[movieLock objectForKey: outFile] tryLock])
	{
		[[movieLock objectForKey: outFile] unlock];
		[movieLock removeObjectForKey: outFile];
	}
	
	[pool release];
}

- (NSString *)realm
{
	// Change the realm each day
	return [NSString stringWithFormat: @"OsiriX Web Portal (%@ - %@)" , [[AppController sharedAppController] privateIP], [BrowserController  DateOfBirthFormat: [NSDate date]] ];
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

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	BOOL lockReleased = NO, waitBeforeReturning = NO;
	
	NSString *contentRange = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Range") autorelease];
	NSString *userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	
	NSScanner *scan = [NSScanner scannerWithString:userAgent];
	BOOL isSafari = NO;
	BOOL isMacOS = NO;
	
	while(![scan isAtEnd])
	{
		if( !isSafari) isSafari = [scan scanString:@"Safari/" intoString:nil];
		if( !isMacOS) isMacOS = [scan scanString:@"Mac OS" intoString: nil];
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
	
	if(!isiPhone) // look
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
	
	if( [method isEqualToString: @"POST"] && multipartData && [multipartData count] == 1) // through POST
	{
		url = [url stringByAppendingString: @"?"];
		url = [url stringByAppendingString: [[[NSString alloc] initWithBytes: [[multipartData lastObject] bytes] length: [(NSData*) [multipartData lastObject] length] encoding: NSUTF8StringEncoding] autorelease]];
	}
	
	// parse the URL to find the parameters (if any)
	NSArray *urlComponenents = [url componentsSeparatedByString:@"?"];
	NSString *parameterString = @"";
	if([urlComponenents count] == 2) parameterString = [urlComponenents lastObject];
	
	[urlParameters release];
	urlParameters = [[NSMutableDictionary dictionary] retain];
	if(![parameterString isEqualToString:@""])
	{
		NSArray *paramArray = [parameterString componentsSeparatedByString:@"&"];
		NSMutableArray *selected = [NSMutableArray array];
		for(NSString *param in paramArray)
		{
			NSArray *p = [param componentsSeparatedByString:@"="];
			if([[p objectAtIndex:0] isEqualToString:@"selected"])
			{
				[selected addObject:[p lastObject]];
			}
			else
				[urlParameters setObject:[p lastObject] forKey:[p objectAtIndex:0]];
		}
		
		if([selected count])
			[urlParameters setObject:selected forKey:@"selected"];
	}
	
	NSString *portString = [urlParameters objectForKey: @"dicomcstoreport"];
	if( portString == 0L)
		portString = @"11112";
	
	// find the name of the requested file
	urlComponenents = [(NSString*)[urlComponenents objectAtIndex:0] componentsSeparatedByString:@"?"];
	NSString *fileURL = [urlComponenents objectAtIndex:0];
	
	NSString *requestedFile, *reportType;
	NSData *data;
	BOOL err = YES;
	
	if([fileURL isEqualToString:@"/"])
	{
		requestedFile = [webDirectory stringByAppendingPathComponent:@"index.html"];
		err = NO;
	}
	else
	{
		requestedFile = [webDirectory stringByAppendingPathComponent: fileURL];
		
		// SECURITY : we cannot allow the client to read any file on the hard disk !?!?!!!
		requestedFile = [requestedFile stringByReplacingOccurrencesOfString: @".." withString: @""];
		
		err = ![[NSFileManager defaultManager] fileExistsAtPath: requestedFile];
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	@try
	{
		data = [NSData dataWithContentsOfFile:requestedFile];
		
		#pragma mark index
		if( [fileURL isEqualToString: @"/index.html"] || [fileURL isEqualToString: @"/"])
		{
			NSMutableString *templateString = [NSMutableString stringWithContentsOfFile: [webDirectory stringByAppendingPathComponent:@"index.html"]];
			
			templateString = [self setBlock: @"AuthorizedRestorePasswordWebServer" visible: [[NSUserDefaults standardUserDefaults] boolForKey: @"restorePasswordWebServer"] forString: templateString];
			
			data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
			
			err = NO;
		}
		
		#pragma mark main
		
		if([fileURL isEqualToString: @"/main"])
		{
			NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"main.html"]];
			
			templateString = [self setBlock: @"userAccount" visible: currentUser ? YES : NO forString: templateString];
			
			if( currentUser)
			{				
				[templateString replaceOccurrencesOfString:@"%UserNameLabel%" withString: notNil([currentUser valueForKey: @"name"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%UserEmailLabel%" withString: notNil([currentUser valueForKey: @"email"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%UserPhoneLabel%" withString: notNil([currentUser valueForKey: @"phone"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			}
			
			templateString = [self setBlock: @"AuthorizedUploadDICOMFiles" visible: ( currentUser && [[currentUser valueForKey: @"uploadDICOM"] boolValue] && !isiPhone) forString: templateString];
			
			if( currentUser == nil || (currentUser && [[currentUser valueForKey: @"uploadDICOM"] boolValue] == YES))
				[self supportsPOST: nil withSize: 0];
			
			NSArray *tempArray = [templateString componentsSeparatedByString:@"%AlbumListItem%"];
			NSString *templateStringStart = [tempArray objectAtIndex:0];
			tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/AlbumListItem%"];
			NSString *albumListItemString = [tempArray objectAtIndex:0];
			NSString *templateStringEnd = [tempArray lastObject];
			
			NSMutableString *returnHTML = [NSMutableString stringWithString:templateStringStart];
			
			NSArray	*albumArray = [[BrowserController currentBrowser] albumArray];
			for(NSManagedObject *album in albumArray)
			{
				if(![[album valueForKey:@"name"] isEqualToString: NSLocalizedString(@"Database", nil)])
				{
					NSMutableString *tempString = [NSMutableString stringWithString:albumListItemString];
					[tempString replaceOccurrencesOfString: @"%AlbumName%" withString: notNil( [album valueForKey:@"name"]) options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
					[tempString replaceOccurrencesOfString: @"%AlbumNameURL%" withString: [OsiriXHTTPConnection encodeURLString: [album valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
					if([[album valueForKey:@"smartAlbum"] intValue] == 1)
						[tempString replaceOccurrencesOfString: @"%AlbumType%" withString:@"SmartAlbum" options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
					else
						[tempString replaceOccurrencesOfString: @"%AlbumType%" withString:@"Album" options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
					[returnHTML appendString:tempString];
				}
			}
			
			[returnHTML appendString:templateStringEnd];
			
			[returnHTML replaceOccurrencesOfString: @"%DicomCStorePort%" withString: notNil( portString) options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
			
			data = [returnHTML dataUsingEncoding:NSUTF8StringEncoding];
			
			err = NO;
		}
	#pragma mark wado
		else if( [fileURL isEqualToString:@"/wado"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"wadoServer"])
		{
			if( [[[urlParameters objectForKey:@"requestType"] lowercaseString] isEqualToString: @"wado"])
			{
				NSString *studyUID = [urlParameters objectForKey:@"studyUID"];
				NSString *seriesUID = [urlParameters objectForKey:@"seriesUID"];
				NSString *objectUID = [urlParameters objectForKey:@"objectUID"];
				
				if( objectUID == nil)
					NSLog( @"***** WADO with objectUID == nil -> wado will fail");
				
				NSString *contentType = [[[[urlParameters objectForKey:@"contentType"] lowercaseString] componentsSeparatedByString: @","] objectAtIndex: 0];
				int rows = [[urlParameters objectForKey:@"rows"] intValue];
				int columns = [[urlParameters objectForKey:@"columns"] intValue];
				int windowCenter = [[urlParameters objectForKey:@"windowCenter"] intValue];
				int windowWidth = [[urlParameters objectForKey:@"windowWidth"] intValue];
				//				int frameNumber = [[urlParameters objectForKey:@"frameNumber"] intValue]; -> OsiriX stores frames as images
				int imageQuality = DCMLosslessQuality;
				
				if( [urlParameters objectForKey:@"imageQuality"])
				{
					if( [[urlParameters objectForKey:@"imageQuality"] intValue] > 80)
						imageQuality = DCMLosslessQuality;
					else if( [[urlParameters objectForKey:@"imageQuality"] intValue] > 60)
						imageQuality = DCMHighQuality;
					else if( [[urlParameters objectForKey:@"imageQuality"] intValue] > 30)
						imageQuality = DCMMediumQuality;
					else if( [[urlParameters objectForKey:@"imageQuality"] intValue] >= 0)
						imageQuality = DCMLowQuality;
				}
				
				NSString *transferSyntax = [[urlParameters objectForKey:@"transferSyntax"] lowercaseString];
				NSString *useOrig = [[urlParameters objectForKey:@"useOrig"] lowercaseString];
				
				NSError *error = nil;
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
				
				@try
				{
					if( studyUID)
						[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
					else
						[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
					
					NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error: &error];
					
					if( [studies count] == 0)
						NSLog( @"****** WADO Server : study not found");
					
					if( [studies count] > 1)
						NSLog( @"****** WADO Server : more than 1 study with same uid");
					
					NSArray *allSeries = [[[studies lastObject] valueForKey: @"series"] allObjects];
					
					if( seriesUID)
						allSeries = [allSeries filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", seriesUID]];
					
					NSArray *allImages = [NSArray array];
					for( id series in allSeries)
						allImages = [allImages arrayByAddingObjectsFromArray: [[series valueForKey: @"images"] allObjects]];
					
					NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: objectUID]] customSelector: @selector( isEqualToSopInstanceUID:)];
					NSPredicate *notNilPredicate = [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"];
					
					NSArray *images = [[allImages filteredArrayUsingPredicate: notNilPredicate] filteredArrayUsingPredicate: predicate];
					
					if( [images count])
					{
						if( [contentType isEqualToString: @"application/dicom"])
						{
							if( [useOrig isEqualToString: @"true"] || [useOrig isEqualToString: @"1"] || [useOrig isEqualToString: @"yes"])
							{
								data = [NSData dataWithContentsOfFile: [[images lastObject] valueForKey: @"completePath"]];
							}
							else
							{
								DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS: transferSyntax] autorelease];
								
								if( [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEG2000LosslessTransferSyntax]] ||
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
						else if( [contentType isEqualToString: @"video/mpeg"])
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
							
							if( [dicomImageArray count] > 1)
							{
								NSString *path = @"/tmp/osirixwebservices";
								[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
								
								NSString *name = [NSString stringWithFormat:@"%@",[urlParameters objectForKey:@"id"]];
								name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
								
								NSMutableString *fileName = [NSMutableString stringWithString: [path stringByAppendingPathComponent:name]];
								
								[BrowserController replaceNotAdmitted: fileName];
								
								[fileName appendString:@".mov"];
								
								NSString *outFile;
								if( isiPhone)
									outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
								else
									outFile = fileName;
								
								NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", urlParameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
								
								lockReleased = YES;
								[[[BrowserController currentBrowser] managedObjectContext] unlock];
								
								[self generateMovie: dict];
								
								data = [NSData dataWithContentsOfFile: outFile];
								
								if( data)
									err = NO;
							}
						}
						else // image/jpeg
						{
							DicomImage *im = [images lastObject];
							
							DCMPix* dcmPix = [[[DCMPix alloc] initWithPath:[im valueForKey:@"completePathResolved"] :0 :1 :nil :0 :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im] autorelease];
							
							if(dcmPix)
							{
								NSImage *image = nil;
								
								float curWW = windowWidth;
								float curWL = windowCenter;
								
								if( curWW == 0 && [[im valueForKey:@"series"] valueForKey:@"windowWidth"])
								{
									curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
									curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
								}
								
								if( curWW != 0)
									[dcmPix checkImageAvailble:curWW :curWL];
								else
									[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
								
								image = [dcmPix image];
								float width = [image size].width;
								float height = [image size].height;
								
								int maxWidth = columns;
								int maxHeight = rows;
								
								BOOL resize = NO;
								
								if(width > maxWidth && maxWidth > 0)
								{
									height =  height * maxWidth / width;
									width = maxWidth;
									resize = YES;
								}
								if(height > maxHeight && maxHeight > 0)
								{
									width = width * maxHeight / height;
									height = maxHeight;
									resize = YES;
								}
								
								NSImage *newImage;
								
								if( resize)
									newImage = [image imageByScalingProportionallyToSize: NSMakeSize(width, height)];
								else
									newImage = image;
								
								NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]];
								NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
								
								if( [contentType isEqualToString: @"image/gif"])
									data = [imageRep representationUsingType: NSGIFFileType properties:imageProps];
								else if( [contentType isEqualToString: @"image/png"])
									data = [imageRep representationUsingType: NSPNGFileType properties:imageProps];
								else if( [contentType isEqualToString: @"image/jp2"])
									data = [imageRep representationUsingType: NSJPEG2000FileType properties:imageProps];
								else
									data = [imageRep representationUsingType: NSJPEGFileType properties:imageProps];
								
								if( data)
									err = NO;
							}
						}
					}
					else NSLog( @"****** WADO Server : image uid not found !");
				
					if( err)
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
		else if([fileURL isEqualToString:@"/studyList"])
		{
			NSPredicate *browsePredicate;
			NSString *pageTitle;
			if( [[urlParameters objectForKey:@"browse"] isEqualToString: @"newAddedStudies"] && [[urlParameters objectForKey:@"browseParameter"] doubleValue] > 0)
			{
				browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [[urlParameters objectForKey:@"browseParameter"] doubleValue]];
				pageTitle = NSLocalizedString( @"New Studies Available", nil);
			}
			else if([(NSString*)[urlParameters objectForKey:@"browse"] isEqualToString:@"today"])
			{
				browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [self startOfDay:[NSCalendarDate calendarDate]]];
				pageTitle = NSLocalizedString( @"Today", nil);
			}
			else if([(NSString*)[urlParameters objectForKey:@"browse"] isEqualToString:@"6hours"])
			{
				NSCalendarDate *now = [NSCalendarDate calendarDate];
				browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:[now hourOfDay]-6 minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:nil] timeIntervalSinceReferenceDate]];
				pageTitle = NSLocalizedString( @"Last 6 hours", nil);
			}
			else if([(NSString*)[urlParameters objectForKey:@"browse"] isEqualToString:@"all"])
			{
				browsePredicate = [NSPredicate predicateWithValue:YES];
				pageTitle = NSLocalizedString(@"Study List", nil);
			}
			else if([urlParameters objectForKey:@"search"])
			{
				NSMutableString *search = [NSMutableString string];
				NSString *searchString = [NSString stringWithString: [[[urlParameters objectForKey:@"search"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
				searchString = [OsiriXHTTPConnection decodeURLString:searchString];
				
				NSArray *components = [searchString componentsSeparatedByString:@" "];
				NSMutableArray *newComponents = [NSMutableArray array];
				for (NSString *comp in components)
				{
					if(![comp isEqualToString:@""])
						[newComponents addObject:comp];
				}
				
				searchString = [newComponents componentsJoinedByString:@" "];
				
				[search appendFormat:@"name CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
				browsePredicate = [NSPredicate predicateWithFormat:search];
				pageTitle = NSLocalizedString(@"Search Result", nil);
			}
			else if([urlParameters objectForKey:@"searchID"])
			{
				NSMutableString *search = [NSMutableString string];
				NSString *searchString = [NSString stringWithString: [[[urlParameters objectForKey:@"searchID"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
				searchString = [OsiriXHTTPConnection decodeURLString:searchString];
				
				NSArray *components = [searchString componentsSeparatedByString:@" "];
				NSMutableArray *newComponents = [NSMutableArray array];
				for (NSString *comp in components)
				{
					if(![comp isEqualToString:@""])
						[newComponents addObject:comp];
				}
				
				searchString = [newComponents componentsJoinedByString:@" "];
				
				[search appendFormat:@"patientID CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
				browsePredicate = [NSPredicate predicateWithFormat:search];
				pageTitle = NSLocalizedString(@"Search Result", nil);
			}
			else
			{
				browsePredicate = [NSPredicate predicateWithValue:YES];
				pageTitle = NSLocalizedString(@"Study List", nil);
			}
			
			NSMutableString *html = [self htmlStudyListForStudies: [self studiesForPredicate: browsePredicate sortBy: [urlParameters objectForKey:@"order"]] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", [NSNumber numberWithBool: isiPhone], @"iPhone", nil]];
			
			if([urlParameters objectForKey:@"album"])
			{
				if(![[urlParameters objectForKey:@"album"] isEqualToString:@""])
				{
					html = [self htmlStudyListForStudies: [self studiesForAlbum:[OsiriXHTTPConnection decodeURLString:[[urlParameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] sortBy:[urlParameters objectForKey:@"order"]] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
					pageTitle = [OsiriXHTTPConnection decodeURLString:[[urlParameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				}
			}
			
			[html replaceOccurrencesOfString:@"%PageTitle%" withString: notNil( pageTitle) options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			if([urlParameters objectForKey:@"browse"])[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[urlParameters objectForKey:@"browse"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			else [html replaceOccurrencesOfString:@"%browse%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])]; 
			
			if([urlParameters objectForKey:@"browseParameter"])[html replaceOccurrencesOfString:@"%browseParameter%" withString:[NSString stringWithFormat:@"&browseParameter=%@",[urlParameters objectForKey:@"browseParameter"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			else [html replaceOccurrencesOfString:@"%browseParameter%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])]; 
			
			if([urlParameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[urlParameters objectForKey:@"search"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			else [html replaceOccurrencesOfString:@"%search%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			if([urlParameters objectForKey:@"album"])[html replaceOccurrencesOfString:@"%album%" withString:[NSString stringWithFormat:@"&album=%@",[urlParameters objectForKey:@"album"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			else [html replaceOccurrencesOfString:@"%album%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];

			if([urlParameters objectForKey:@"order"])
			{
				if([[urlParameters objectForKey:@"order"] isEqualToString:@"name"])
				{
					[html replaceOccurrencesOfString:@"%orderByName%" withString:@"sortedBy" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
					[html replaceOccurrencesOfString:@"%orderByDate%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				}
				else
				{
					[html replaceOccurrencesOfString:@"%orderByDate%" withString:@"sortedBy" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
					[html replaceOccurrencesOfString:@"%orderByName%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				}
			}
			else
			{
				[html replaceOccurrencesOfString:@"%orderByDate%" withString:@"sortedBy" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				[html replaceOccurrencesOfString:@"%orderByName%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			}
			
			[html replaceOccurrencesOfString: @"%DicomCStorePort%" withString: notNil( portString) options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			data = [html dataUsingEncoding:NSUTF8StringEncoding];
			err = NO;
		}
	#pragma mark study
		else if([fileURL isEqualToString:@"/study"])
		{
			NSString *message = nil;
			
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			#pragma mark dicomSend
			if( [[urlParameters allKeys] containsObject:@"dicomSend"])
			{
				NSString *dicomDestination = [[[urlParameters objectForKey:@"dicomDestination"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				NSArray *tempArray = [dicomDestination componentsSeparatedByString:@":"];
				
				if( [tempArray count] >= 4)
				{
					NSString *dicomDestinationAddress = [[[tempArray objectAtIndex:0]  stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSString *dicomDestinationPort = [tempArray objectAtIndex:1];
					NSString *dicomDestinationAETitle = [[[tempArray objectAtIndex:2]  stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSString *dicomDestinationSyntax = [tempArray objectAtIndex:3];
					
					if( dicomDestinationAddress && dicomDestinationPort && dicomDestinationAETitle && dicomDestinationSyntax)
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
						for(NSString* selectedID in [urlParameters objectForKey:@"selected"])
						{
							NSPredicate *pred = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [urlParameters objectForKey:@"id"], [[selectedID stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
							
							seriesArray = [self seriesForPredicate: pred];
							for(NSManagedObject *series in seriesArray)
							{
								NSArray *images = [[series valueForKey:@"images"] allObjects];
								[selectedImages addObjectsFromArray:images];
							}
						}
						
						[selectedImages retain];
						
						if( [selectedImages count])
						{
							[self dicomSend: self];
							
							message = [NSString stringWithFormat: NSLocalizedString( @"Images sent to DICOM node: %@ - %@", nil), dicomDestinationAddress, dicomDestinationAETitle];
						}
					}
					
					if( message == nil)
						message = [NSString stringWithFormat: NSLocalizedString( @"DICOM Transfer failed to node : %@ - %@", nil), dicomDestinationAddress, dicomDestinationAETitle];
				}
				
				if( message == nil)
					message = [NSString stringWithFormat: NSLocalizedString( @"DICOM Transfer failed to node : cannot identify DICOM node.", nil)];
			}
			
			NSArray *studies = [self studiesForPredicate:browsePredicate];
			
			if( [studies count] == 1)
			{
				if( [[urlParameters allKeys] containsObject:@"shareStudy"])
				{
					NSString *userDestination = [[[urlParameters objectForKey:@"userDestination"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSString *messageFromUser = [[[urlParameters objectForKey:@"message"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					
					if( userDestination)
					{
						id study = [studies lastObject];
						
						// Find this user
						NSError *error = nil;
						NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
						[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
						[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"name == %@", userDestination]];
						
						error = nil;
						NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
						
						if( [users count] == 1)
						{
							// Add study to specific study list for this user
							NSManagedObject *destUser = [users lastObject];
							
							NSArray *studiesArrayStudyInstanceUID = [[[destUser valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
							NSArray *studiesArrayPatientUID = [[[destUser valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
							
							NSManagedObject *studyLink = nil;
							
							if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
							{
								NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: [BrowserController currentBrowser].userManagedObjectContext];
							
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
							
							[OsiriXHTTPConnection sendNotificationsEmailsTo: users aboutStudies: [NSArray arrayWithObject: study] predicate: nil message: [messageFromUser stringByAppendingFormat: @"\r\r\r%@\r\r%%URLsList%%", NSLocalizedString( @"To view this study, click on the following link:", nil)] replyTo: [currentUser valueForKey: @"email"] customText: nil];
							
							[OsiriXHTTPConnection updateLogEntryForStudy: study withMessage: [NSString stringWithFormat: @"Share Study with User: %@", userDestination] forUser: [currentUser valueForKey: @"name"] ip: [asyncSocket connectedHost]];
							
							message = [NSString stringWithFormat: NSLocalizedString( @"This study is now shared with %@.", nil), userDestination];
						}
					}
					
					if( message == nil)
						message = [NSString stringWithFormat: NSLocalizedString( @"Failed to share this study with %@.", nil), userDestination];
				}
			
			
				[self updateLogEntryForStudy: [studies lastObject] withMessage: @"Display Study"];
				
				ipAddressString = [[asyncSocket connectedHost] copy];
				
				NSMutableString *html = [self htmlStudy:[studies lastObject] parameters:urlParameters settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"iPhone", [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
				
				[html replaceOccurrencesOfString:@"%StudyID%" withString: notNil( [urlParameters objectForKey:@"id"]) options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
//				if( [[urlParameters allKeys] containsObject:@"dicomSend"])
//				{
//					NSString *dicomDestination = [urlParameters objectForKey:@"dicomDestination"];
//					NSArray *tempArray = [dicomDestination componentsSeparatedByString:@":"];
//					
//					if( [tempArray count] >= 3)
//					{
//						NSString *dicomDestinationAETitle = [[tempArray objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//						NSString *dicomDestinationAddress = [[tempArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//					}
//				}
				
				[html replaceOccurrencesOfString:@"%LocalizedLabel_SendStatus%" withString: notNil( message) options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				if( [urlParameters objectForKey:@"browse"])
					[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[urlParameters objectForKey:@"browse"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				else
					[html replaceOccurrencesOfString:@"%browse%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				if([urlParameters objectForKey:@"browseParameter"])[html replaceOccurrencesOfString:@"%browseParameter%" withString:[NSString stringWithFormat:@"&browseParameter=%@",[urlParameters objectForKey:@"browseParameter"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				else [html replaceOccurrencesOfString:@"%browseParameter%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				if([urlParameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[urlParameters objectForKey:@"search"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				else [html replaceOccurrencesOfString:@"%search%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				[html replaceOccurrencesOfString: @"%DicomCStorePort%" withString: notNil( portString) options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				data = [html dataUsingEncoding:NSUTF8StringEncoding];
			}
			err = NO;
		}
	#pragma mark thumbnail
		else if([fileURL isEqualToString:@"/thumbnail"])
		{
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				if( [[urlParameters allKeys] containsObject:@"studyID"])
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[urlParameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				else
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
				
			NSArray *series = [self seriesForPredicate:browsePredicate];
			
			if( [series count] == 1)
			{
				if(![[series lastObject] valueForKey:@"thumbnail"])
					[[BrowserController currentBrowser] buildThumbnail:[series lastObject]];
				
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[[series lastObject] valueForKey:@"thumbnail"]];				
				NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
				data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
			}
			err = NO;
		}
	#pragma mark series.pdf
		else if( [fileURL isEqualToString:@"/series.pdf"])
		{
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				if( [[urlParameters allKeys] containsObject:@"studyID"])
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[urlParameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				else
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *series = [self seriesForPredicate: browsePredicate];
			
			if( [series count] == 1)
			{
				if( [DCMAbstractSyntaxUID isPDF: [[series lastObject] valueForKey: @"seriesSOPClassUID"]])
				{
					DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"]  decodingPixelData:NO];
				
					if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
					{
						data = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
						
						if( data)
							err = NO;
					}
				}
			}
			
			if( err)
			{
				data = [NSData data];
				err = NO;
			}
		}
	#pragma mark series
		else if( [fileURL isEqualToString:@"/series"])
		{
			NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"series.html"]];			
			[templateString replaceOccurrencesOfString:@"%StudyID%" withString: notNil( [urlParameters objectForKey:@"studyID"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%SeriesID%" withString: notNil( [urlParameters objectForKey:@"id"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			NSString *browse =  notNil( [urlParameters objectForKey:@"browse"]);
			NSString *browseParameter =  notNil( [urlParameters objectForKey:@"browseParameter"]);
			NSString *search =  notNil( [urlParameters objectForKey:@"search"]);
			NSString *album = notNil( [urlParameters objectForKey:@"album"]);
			
			[templateString replaceOccurrencesOfString:@"%browse%" withString: notNil( browse) options: NSLiteralSearch range: NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%browseParameter%" withString: notNil( browseParameter) options: NSLiteralSearch range: NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%search%" withString: [OsiriXHTTPConnection decodeURLString:search] options: NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%album%" withString: [OsiriXHTTPConnection decodeURLString: [album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			[templateString replaceOccurrencesOfString:@"%VideoType%" withString: isiPhone? @"video/x-m4v":@"video/x-mov" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%MovieExtension%" withString: isiPhone? @"m4v":@"mov" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				if( [[urlParameters allKeys] containsObject:@"studyID"])
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[urlParameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				else
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *series = [self seriesForPredicate:browsePredicate];
			NSArray *imagesArray = [[[series lastObject] valueForKey:@"images"] allObjects];

			if([imagesArray count] == 1)
			{
				[templateString replaceOccurrencesOfString:@"<!--[if !IE]>-->" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"<!--<![endif]-->" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				[templateString replaceOccurrencesOfString:@"%movie%" withString:@"<!--" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%/movie%" withString:@"-->" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				[templateString replaceOccurrencesOfString:@"%image%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%/image%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			}
			else
			{
				[templateString replaceOccurrencesOfString:@"%image%" withString:@"<!--" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%/image%" withString:@"-->" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];			
				[templateString replaceOccurrencesOfString:@"%movie%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%/movie%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				DicomImage *lastImage = [imagesArray lastObject];
				int width = [[lastImage valueForKey:@"width"] intValue];
				int height = [[lastImage valueForKey:@"height"] intValue];
				
				int maxWidth = width;
				int maxHeight = height;
				
				if( isiPhone)
				{
					maxWidth = 300; // for the poster frame of the movie to fit in the iphone screen (vertically)
					maxHeight = 310;
				}
				else
				{
					maxWidth = maxResolution;
					maxHeight = maxResolution;
				}
				
				if(width>maxWidth)
				{
					height = (float)height * (float)maxWidth / (float)width;
					width = maxWidth;
				}
				
				if(height>maxHeight)
				{
					width = (float)width * (float)maxHeight / (float)height;
					height = maxHeight;
				}
				
				height += 15; // quicktime controller height
				
				//NSLog(@"NEW w: %d, h: %d", width, height);
				[templateString replaceOccurrencesOfString:@"%width%" withString: [NSString stringWithFormat:@"%d", width] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString:@"%height%" withString: [NSString stringWithFormat:@"%d", height] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				NSString *url = nil;
				
				if( isiPhone)
					url = [NSString stringWithFormat: @"/movie.m4v?id=%@&studyID=%@", [urlParameters objectForKey:@"id"], [urlParameters objectForKey:@"studyID"]];
				else
					url = [NSString stringWithFormat: @"/movie.mov?id=%@&studyID=%@", [urlParameters objectForKey:@"id"], [urlParameters objectForKey:@"studyID"]];
					
				[templateString replaceOccurrencesOfString:@"%DownloadMovieURL%" withString: [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", url, NSLocalizedString( @"Link to Quicktime Movie File", nil)] options: NSLiteralSearch range: NSMakeRange(0, [templateString length])];
			}
			
			NSString *seriesName = notNil( [[series lastObject] valueForKey:@"name"]);
			[templateString replaceOccurrencesOfString:@"%PageTitle%" withString: notNil( seriesName) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			NSString *studyName = notNil( [[series lastObject] valueForKeyPath:@"study.name"]);
			[templateString replaceOccurrencesOfString:@"%LinkToStudyLevel%" withString: notNil( studyName) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			[templateString replaceOccurrencesOfString: @"%DicomCStorePort%" withString: notNil( portString) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			data = [templateString dataUsingEncoding:NSUTF8StringEncoding];
			err = NO;
		}
#pragma mark report
		else if( [fileURL hasPrefix:@"/report"])
		{
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [urlParameters objectForKey:@"id"]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *studies = [self studiesForPredicate:browsePredicate];
			
			if( [studies count] == 1)
			{
				[self updateLogEntryForStudy: [studies lastObject] withMessage: @"Download Report"];
				
				NSString *reportFilePath = [[studies lastObject] valueForKey:@"reportURL"];
				
				reportType = [reportFilePath pathExtension];
				
				if( [reportType isEqualToString: @"pages"])
				{
					NSString *zipFileName = [NSString stringWithFormat:@"%@.zip", [reportFilePath lastPathComponent]];
					// zip the directory into a single archive file
					NSTask *zipTask   = [[NSTask alloc] init];
					[zipTask setLaunchPath:@"/usr/bin/zip"];
					[zipTask setCurrentDirectoryPath:[[reportFilePath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
					if([reportType isEqualToString:@"pages"])
						[zipTask setArguments:[NSArray arrayWithObjects: @"--quiet", @"-r" , zipFileName, [reportFilePath lastPathComponent], nil]];
					else
						[zipTask setArguments:[NSArray arrayWithObjects: zipFileName, [reportFilePath lastPathComponent], nil]];
					[zipTask launch];
					while( [zipTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
					int result = [zipTask terminationStatus];
					[zipTask release];
					
					if(result==0)
					{
						reportFilePath = [[reportFilePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", zipFileName];
					}
					
					data = [NSData dataWithContentsOfFile: reportFilePath];
					
					[[NSFileManager defaultManager] removeFileAtPath:reportFilePath handler:nil];
					
					if( data)
						err = NO;
				}
				else
				{
					data = [NSData dataWithContentsOfFile: reportFilePath];
					
					if( data)
						err = NO;
				}
			}
		}
	#pragma mark ZIP
		else if( [fileURL hasSuffix:@".zip"] || [fileURL hasSuffix:@".osirixzip"])
		{
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				if( [[urlParameters allKeys] containsObject:@"studyID"])
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[urlParameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				else
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *series = [self seriesForPredicate:browsePredicate];
			
			NSMutableArray *imagesArray = [NSMutableArray array];
			for( DicomSeries *s in series)
				[imagesArray addObjectsFromArray: [[s valueForKey:@"images"] allObjects]];
			
			if( [imagesArray count])
			{
				if( [[currentUser valueForKey: @"encryptedZIP"] boolValue])
					[self updateLogEntryForStudy: [[series lastObject] valueForKey: @"study"] withMessage: @"Download encrypted DICOM ZIP"];
				else
					[self updateLogEntryForStudy: [[series lastObject] valueForKey: @"study"] withMessage: @"Download DICOM ZIP"];
					
				@try
				{
					NSString *srcFolder = @"/tmp";
					NSString *destFile = @"/tmp";
					
					srcFolder = [srcFolder stringByAppendingPathComponent: asciiString( [[imagesArray lastObject] valueForKeyPath: @"series.study.name"])];
					destFile = [destFile stringByAppendingPathComponent: asciiString( [[imagesArray lastObject] valueForKeyPath: @"series.study.name"])];
					
					if( isMacOS)
						destFile = [destFile  stringByAppendingPathExtension: @"zip"];
					else
						destFile = [destFile  stringByAppendingPathExtension: @"osirixzip"];
					
					[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
					[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
					
					[[NSFileManager defaultManager] createDirectoryAtPath: srcFolder attributes: nil];
					
					if( lockReleased == NO)
					{
						[[[BrowserController currentBrowser] managedObjectContext] unlock];
						lockReleased = YES;
					}
					
					if( [[currentUser valueForKey: @"encryptedZIP"] boolValue])
						[BrowserController encryptFiles: [imagesArray valueForKey: @"completePath"] inZIPFile: destFile password: [currentUser valueForKey: @"password"]];
					else
						[BrowserController encryptFiles: [imagesArray valueForKey: @"completePath"] inZIPFile: destFile password: nil];
					
					data = [NSData dataWithContentsOfFile: destFile];
					
					[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
					[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
					
					if( data)
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
		else if([fileURL isEqualToString:@"/image.png"])
		{
			NSPredicate *browsePredicate;
			if( [[urlParameters allKeys] containsObject:@"id"])
			{
				if( [[urlParameters allKeys] containsObject:@"studyID"])
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[urlParameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				else
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *series = [self seriesForPredicate:browsePredicate];
			if([series count]==1)
			{
				NSMutableArray *imagesArray = [NSMutableArray array];
				NSArray *dicomImageArray = [[[series lastObject] valueForKey:@"images"] allObjects];
				DicomImage *im;
				if([dicomImageArray count] == 1)
					im = [dicomImageArray lastObject];
				else
					im = [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
				
				DCMPix* dcmPix = [[DCMPix alloc] initWithPath:[im valueForKey:@"completePathResolved"] :0 :1 :nil :[[im valueForKey: @"numberOfFrames"] intValue]/2 :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im];
				
				if(dcmPix)
				{
					float curWW = 0;
					float curWL = 0;
					
					if([[im valueForKey:@"series"] valueForKey:@"windowWidth"])
					{
						curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
						curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
					}
					
					if( curWW != 0)
						[dcmPix checkImageAvailble:curWW :curWL];
					else
						[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
					
					[imagesArray addObject:[dcmPix image]];
					[dcmPix release];
				}
				NSImage *image = [imagesArray lastObject];
				float width = [image size].width;
				float height = [image size].height;
				
				int maxWidth = width;
				int maxHeight = height;
				
				maxWidth = maxResolution;
				maxHeight = maxResolution;
				
				BOOL resize = NO;
				
				if(width>maxWidth)
				{
					height =  height * maxWidth / width;
					width = maxWidth;
					resize = YES;
				}
				if(height>maxHeight)
				{
					width = width * maxHeight / height;
					height = maxHeight;
					resize = YES;
				}
				
				NSImage *newImage;
				
				if( resize)
					newImage = [image imageByScalingProportionallyToSize:NSMakeSize(width, height)];
				else
					newImage = image;
				
				if( [[urlParameters allKeys] containsObject:@"previewForMovie"])
				{
					[newImage lockFocus];
					
					NSImage *r = [NSImage imageNamed: @"PlayTemplate.png"];
					
					[r drawInRect: [self centerRect: NSMakeRect( 0,  0, [r size].width, [r size].height) inRect: NSMakeRect( 0,  0, [newImage size].width, [newImage size].height)] fromRect: NSMakeRect( 0,  0, [r size].width, [r size].height)  operation: NSCompositeSourceOver fraction: 1.0];
					
					[newImage unlockFocus];
				}
				
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]];
				NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
				data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
			}
			
			err = NO;
		}
	#pragma mark movie
		else if( [fileURL isEqualToString:@"/movie.mov"] || [fileURL isEqualToString:@"/movie.m4v"])
		{
			NSPredicate *browsePredicate;
			if([[urlParameters allKeys] containsObject:@"id"])
			{
				if( [[urlParameters allKeys] containsObject:@"studyID"])
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[urlParameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				else
					browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[urlParameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *series = [self seriesForPredicate:browsePredicate];
			
			if([series count]==1)
			{
				NSArray *dicomImageArray = [[[series lastObject] valueForKey:@"images"] allObjects];
				
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
				
				if([dicomImageArray count] > 1)
				{
					NSString *path = @"/tmp/osirixwebservices";
					[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
					
					NSString *name = [NSString stringWithFormat:@"%@",[urlParameters objectForKey:@"id"]]; //[[series lastObject] valueForKey:@"id"];
					name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
					
					NSMutableString *fileName = [NSMutableString stringWithString: [path stringByAppendingPathComponent: name]];
					
					[BrowserController replaceNotAdmitted: fileName];
					
					[fileName appendString:@".mov"];
					
					NSString *outFile;
					
					if( isiPhone)
						outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
					else
						outFile = fileName;
					
					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", urlParameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
					
					[[[BrowserController currentBrowser] managedObjectContext] unlock];	
					
					lockReleased = YES;
					[self generateMovie: dict];
					
					data = [NSData dataWithContentsOfFile: outFile];
				}
			}
			
			err = NO;
		}
//		#pragma mark m4v
//		else if([fileURL hasSuffix:@".m4v"]) -- I DONT UNDERSTAND WHERE THIS IS NEEDED...
//		{
//			data = [NSData dataWithContentsOfFile: requestedFile];
//			totalLength = [data length];
//			
//			err = NO;
//		}
		#pragma mark password forgotten
		else if( [fileURL isEqualToString: @"/password_forgotten"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"restorePasswordWebServer"])
		{
			NSMutableString *templateString = [NSMutableString stringWithContentsOfFile: [webDirectory stringByAppendingPathComponent:@"password_forgotten.html"]];
			
			NSString *message = @"";
			
			if( [[urlParameters valueForKey: @"what"] isEqualToString: @"restorePassword"])
			{
				NSString *email = [[[urlParameters valueForKey: @"email"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				NSString *username = [[[urlParameters valueForKey: @"username"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				
				// TRY TO FIND THIS USER
				if( [email length] > 0 || [username length] > 0)
				{
					[[[BrowserController currentBrowser] userManagedObjectContext] lock];
					
					@try
					{
						NSError *error = nil;
						NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
						[dbRequest setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey: @"User"]];
						
						if( [email length] > [username length])
							[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(email BEGINSWITH[cd] %@) AND (email ENDSWITH[cd] %@)", email, email]];
						else
							[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(name BEGINSWITH[cd] %@) AND (name ENDSWITH[cd] %@)", username, username]];
							
						error = nil;
						NSArray *users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: dbRequest error:&error];
						
						if( [users count] >= 1)
						{
							for( UserTable *user in users)
							{
								NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
								
								if( fromEmailAddress == nil)
									fromEmailAddress = @"";
								
								NSString *emailSubject = NSLocalizedString( @"Your password has been resetted.", nil);
								NSMutableString *emailMessage = [NSMutableString stringWithString: @""];
								
								[user generatePassword];
								
								[emailMessage appendString: NSLocalizedString( @"Username:\r\r", nil)];
								[emailMessage appendString: [user valueForKey: @"name"]];
								[emailMessage appendString: @"\r\r"];
								[emailMessage appendString: NSLocalizedString( @"Password:\r\r", nil)];
								[emailMessage appendString: [user valueForKey: @"password"]];
								[emailMessage appendString: @"\r\r"];
								
								[OsiriXHTTPConnection updateLogEntryForStudy: nil withMessage: @"Password resetted for user" forUser: [user valueForKey: @"name"] ip: nil];
								
								[[CSMailMailClient mailClient] deliverMessage: [[[NSAttributedString alloc] initWithString: emailMessage] autorelease] headers: [NSDictionary dictionaryWithObjectsAndKeys: [user valueForKey: @"email"], @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", nil]];
							
								message = NSLocalizedString( @"You will receive shortly an email with a new password.", nil);
								
								[[BrowserController currentBrowser] saveUserDatabase];
							}
						}
						else
						{
							// To avoid someone scanning for the username
							waitBeforeReturning = YES;
							
							[OsiriXHTTPConnection updateLogEntryForStudy: nil withMessage: @"Unknown user" forUser: [NSString stringWithFormat: @"%@ %@", username, email] ip: nil];
							
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
			
			templateString = [self setBlock: @"MessageToWrite" visible: [message length] forString: templateString];
			
			[templateString replaceOccurrencesOfString: @"%Localized_Message%" withString: notNil( message) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
			
			err = NO;
		}
		#pragma mark account
		else if( [fileURL isEqualToString: @"/account"])
		{
			if( currentUser)
			{
				NSString *message = @"";
				BOOL messageIsError = NO;
				
				if( [[urlParameters valueForKey: @"what"] isEqualToString: @"changePassword"])
				{
					NSString * previouspassword = [[[urlParameters valueForKey: @"previouspassword"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSString * password = [[[urlParameters valueForKey: @"password"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					
					if( [previouspassword isEqualToString: [currentUser valueForKey: @"password"]])
					{
						if( [[urlParameters valueForKey: @"password"] isEqualToString: [urlParameters valueForKey: @"password2"]])
						{
							if( [password length] >= 4)
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
				
				if( [[urlParameters valueForKey: @"what"] isEqualToString: @"changeSettings"])
				{
					NSString * email = [[[urlParameters valueForKey: @"email"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSString * address = [[[urlParameters valueForKey: @"address"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					NSString * phone = [[[urlParameters valueForKey: @"phone"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					
					[currentUser setValue: email forKey: @"email"];
					[currentUser setValue: address forKey: @"address"];
					[currentUser setValue: phone forKey: @"phone"];
					
					if( [[[urlParameters valueForKey: @"emailNotification"] lowercaseString] isEqualToString: @"on"])
						[currentUser setValue: [NSNumber numberWithBool: YES] forKey: @"emailNotification"];
					else
						[currentUser setValue: [NSNumber numberWithBool: NO] forKey: @"emailNotification"];
						
					message = NSLocalizedString( @"Personal Information updated successfully !", nil);
				}
				
				NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"account.html"]];
				
				NSString *block = @"MessageToWrite";
				if(messageIsError)
				{
					block = @"ErrorToWrite";
					templateString = [self setBlock:@"MessageToWrite" visible:NO forString:templateString];
				}
				else
					templateString = [self setBlock:@"ErrorToWrite" visible:NO forString:templateString];

				templateString = [self setBlock:block visible:[message length] forString:templateString];
				
				[templateString replaceOccurrencesOfString: @"%LocalizedLabel_MessageAccount%" withString: notNil( message) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				[templateString replaceOccurrencesOfString: @"%name%" withString: notNil( [currentUser valueForKey: @"name"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString: @"%DicomCStorePort%" withString: notNil( portString) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				[templateString replaceOccurrencesOfString: @"%email%" withString: notNil( [currentUser valueForKey: @"email"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString: @"%address%" withString: notNil( [currentUser valueForKey: @"address"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString: @"%phone%" withString: notNil( [currentUser valueForKey: @"phone"]) options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				[templateString replaceOccurrencesOfString: @"%emailNotification%" withString: ([[currentUser valueForKey: @"emailNotification"] boolValue]?@"checked":@"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
				
				data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
				
				[[BrowserController currentBrowser] saveUserDatabase];
				
				err = NO;
			}
		}
	}
	
	@catch( NSException *e)
	{
		NSLog( @"******** httpResponseForMethod OsiriXHTTPConnection exception: %@", e);
		NSLog( @"******** method : %@ path : %@", method, path);
		err = YES;
	}
	
	if( lockReleased == NO)
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	if( waitBeforeReturning)
		[NSThread sleepForTimeInterval: 3];
	
	if( err)
		data = [[NSString stringWithString: NSLocalizedString( @"Error 404\r\rFailed to process this request.\r\rOur security team and our webmaster have been notified. They will arrive shortly at this computer location.", nil)] dataUsingEncoding: NSUTF8StringEncoding];
	
	return [[[HTTPDataResponse alloc] initWithData: data] autorelease];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	if( [@"POST" isEqualToString:method])
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
	
	for( int x = [postDataChunk length]-CHECKLASTPART; x < [postDataChunk length]-l; x++)
	{
		if( x >= 0)
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
	
	// We want to find this file after db insert: get studyInstanceUID, patientUID and instanceSOPUID
	
	DicomFile *f = [[[DicomFile alloc] init: POSTfilename DICOMOnly: YES] autorelease];
	
	NSString *studyInstanceUID = [f elementForKey: @"studyID"], *patientUID = [f elementForKey: @"patientUID"];	//, *sopInstanceUID = [f elementForKey: @"SOPUID"];
	
	do
	{
		file = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebServer Upload %d", inc++]] stringByAppendingPathExtension: [POSTfilename pathExtension]];
	}
	while( [[NSFileManager defaultManager] fileExistsAtPath: file]);
				
	[[NSFileManager defaultManager] moveItemAtPath: POSTfilename toPath: file error: nil];
	
	[[BrowserController currentBrowser] checkIncomingNow: self];
	
	if( studyInstanceUID && patientUID)
	{
		[[[BrowserController currentBrowser] managedObjectContext] lock];
		
		@try
		{
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey: @"Study"]];
			[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(patientUID == %@) AND (studyInstanceUID == %@)", patientUID, studyInstanceUID]];
			
			NSError *error = nil;
			NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error:&error];
			
			// Add study to specific study list for this user
			
			NSArray *studiesArrayStudyInstanceUID = [[[currentUser valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
			NSArray *studiesArrayPatientUID = [[[currentUser valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
			
			for( NSManagedObject *study in studies)
			{
				if( [[study valueForKey: @"type"] isEqualToString:@"Series"])
					study = [study valueForKey:@"study"];
				
				if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
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
					
					[OsiriXHTTPConnection updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser: [currentUser valueForKey: @"name"] ip: nil];
				}
			}
		}
		@catch( NSException *e)
		{
			NSLog( @"********* OsiriXHTTPConnection closeFileHandleAndClean exception : %@", e);
		}
		///
		
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
	}
	else NSLog( @"****** studyInstanceUID && patientUID == nil upload POST");
	
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
	
	if( !postHeaderOK)
	{
		if( multipartData == nil)
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
						
						if( eof)
							[self closeFileHandleAndClean];
					}
					@catch ( NSException *e)
					{
						NSLog( @"******* POST processDataChunk : %@", e);
					}
					[postInfo release];
					
					break;
				}
			}
		}
		
		// For other POST, like account update
		
		if( [postDataChunk length] < 4096)
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
		
		if( eof)
			[self closeFileHandleAndClean];
	}
}

@end
