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

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define INCOMINGPATH @"/INCOMING.noindex/"

static NSMutableDictionary *movieLock = nil;

#define maxResolution 1024

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

- (void) updateLogEntryForStudy: (NSManagedObject*) study withMessage:(NSString*) message
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"logWebServer"] == NO) return;
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContextLoadIfNecessary: NO];
	if( context == nil)
		return;
	
	[context lock];
	
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
		[logEntry setValue: [asyncSocket connectedHost] forKey: @"originName"];
	}
	@catch (NSException * e)
	{
		NSLog( @"****** OsiriX HTTPConnection updateLogEntry exception : %@", e);
	}

	[context unlock];
}

- (BOOL)isPasswordProtected:(NSString *)path
{
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
	[[[BrowserController currentBrowser] userManagedObjectContext] lock];
	
	if( [username length] > 3)
	{
		NSArray	*users = nil;
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
		
		[currentUser release];
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
	NSArray *result = [DDKeychain SSLIdentityAndCertificates];
	if([result count] == 0)
	{
		[DDKeychain createNewIdentity];
		return [DDKeychain SSLIdentityAndCertificates];
	}
	return result;
}

- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer
{
    if ((self = [super initWithAsyncSocket: newSocket forServer: myServer]))
	{
		NSString *bundlePath = [NSMutableString stringWithString:[[NSBundle mainBundle] resourcePath]];
		webDirectory = [bundlePath stringByAppendingPathComponent: @"WebServicesHTML"];
		
		BOOL isDirectory = NO;
		if( [[NSFileManager defaultManager] fileExistsAtPath: [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent: @"WebServicesHTML"] isDirectory: &isDirectory] == YES && isDirectory == YES)
			webDirectory = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent: @"WebServicesHTML"];
		
		[webDirectory retain];
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
	[webDirectory release];
	[ipAddressString release];
	[currentUser release];
	
	[multipartData release];
	[postBoundary release];

	[super dealloc];
}

- (NSTimeInterval)startOfDay:(NSCalendarDate *)day
{
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: nil];
	return [start timeIntervalSinceReferenceDate];
}

+ (NSString*)nonNilString:(NSString*)aString;
{
	return (!aString)? @"" : aString;
}

- (NSMutableString*)htmlStudy:(DicomStudy*)study parameters:(NSDictionary*)parameters settings: (NSDictionary*) settings;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"study.html"]];
	NSArray *tempArray, *tempArray2;

	if( [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue] == NO && [[currentUser valueForKey: @"sendDICOMtoAnyNodes"] boolValue] == NO)
	{
		tempArray = [templateString componentsSeparatedByString:@"%SendingFunctions1%"];
		tempArray2 = [[tempArray lastObject] componentsSeparatedByString:@"%/SendingFunctions1%"];
		templateString = [NSMutableString stringWithFormat:@"%@%@",[tempArray objectAtIndex:0], [tempArray2 lastObject]];
		
		tempArray = [templateString componentsSeparatedByString:@"%SendingFunctions2%"];
		tempArray2 = [[tempArray lastObject] componentsSeparatedByString:@"%/SendingFunctions2%"];
		templateString = [NSMutableString stringWithFormat:@"%@%@",[tempArray objectAtIndex:0], [tempArray2 lastObject]];
		
		tempArray = [templateString componentsSeparatedByString:@"%SendingFunctions3%"];
		tempArray2 = [[tempArray lastObject] componentsSeparatedByString:@"%/SendingFunctions3%"];
		templateString = [NSMutableString stringWithFormat:@"%@%@",[tempArray objectAtIndex:0], [tempArray2 lastObject]];
	}
	else
	{
		[templateString replaceOccurrencesOfString:@"%SendingFunctions1%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%/SendingFunctions1%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%SendingFunctions2%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%/SendingFunctions2%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%SendingFunctions3%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%/SendingFunctions3%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	}
	
	if( [[currentUser valueForKey: @"downloadZIP"] boolValue] == NO)
	{
		tempArray = [templateString componentsSeparatedByString:@"%ZIPFunctions%"];
		tempArray2 = [[tempArray lastObject] componentsSeparatedByString:@"%/ZIPFunctions%"];
		templateString = [NSMutableString stringWithFormat:@"%@%@",[tempArray objectAtIndex:0], [tempArray2 lastObject]];
	}
	else
	{
		[templateString replaceOccurrencesOfString:@"%ZIPFunctions%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%/ZIPFunctions%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	}
	
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientInfo%" withString:NSLocalizedString(@"Patient Info", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientID%" withString:NSLocalizedString(@"ID", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientName%" withString:NSLocalizedString(@"Patient Name", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientDateOfBirth%" withString:NSLocalizedString(@"Date of Birth", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyDate%" withString:NSLocalizedString(@"Study Date", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyState%" withString:NSLocalizedString(@"Study Status", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyComment%" withString:NSLocalizedString(@"Study Comment", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyDescription%" withString:NSLocalizedString(@"Study Description", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyModality%" withString:NSLocalizedString(@"Modality", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Series%" withString:NSLocalizedString(@"Series", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_DICOMTransfer%" withString:NSLocalizedString(@"DICOM Transfer", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_SendSelectedSeriesTo%" withString:NSLocalizedString(@"Send selected Series to", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Send%" withString:NSLocalizedString(@"Send", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_DownloadAsZIP%" withString:NSLocalizedString(@"ZIP file", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSString *browse = [OsiriXHTTPConnection nonNilString:[parameters objectForKey:@"browse"]];
	NSString *search = [OsiriXHTTPConnection nonNilString:[parameters objectForKey:@"search"]];
	NSString *album = [OsiriXHTTPConnection nonNilString:[parameters objectForKey:@"album"]];
	
	[templateString replaceOccurrencesOfString:@"%browse%" withString:browse options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%search%" withString:[OsiriXHTTPConnection decodeURLString:search] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%album%" withString:[OsiriXHTTPConnection decodeURLString:[album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSString *LocalizedLabel_StudyList = @"";
	if(![search isEqualToString:@""])
		LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Search Result for", @""), [[OsiriXHTTPConnection decodeURLString:search] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else if(![album isEqualToString:@""])
		LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Album", @""), [[OsiriXHTTPConnection decodeURLString:album] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else
	{
		if([browse isEqualToString:@"6hours"])
			LocalizedLabel_StudyList = NSLocalizedString(@"Last 6 Hours", @"");
		else if([browse isEqualToString:@"today"])
			LocalizedLabel_StudyList = NSLocalizedString(@"Today", @"");
		else
			LocalizedLabel_StudyList = NSLocalizedString(@"Study List", @"");
	}
	
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyList%" withString:LocalizedLabel_StudyList options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	
	
	if([study valueForKey:@"reportURL"] && ![[settings valueForKey:@"iPhone"] boolValue])
	{
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_GetReport%" withString:NSLocalizedString(@"Download Report", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%Report%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%/Report%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	}
	else
	{
		tempArray = [templateString componentsSeparatedByString:@"%Report%"];
		tempArray2 = [[tempArray lastObject] componentsSeparatedByString:@"%/Report%"];
		templateString = [NSMutableString stringWithFormat:@"%@%@",[tempArray objectAtIndex:0], [tempArray2 lastObject]];
	}
	
	tempArray = [templateString componentsSeparatedByString:@"%SeriesListItem%"];
	NSString *templateStringStart = [tempArray objectAtIndex:0];
	tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/SeriesListItem%"];
	NSString *seriesListItemString = [tempArray objectAtIndex:0];
	NSString *templateStringEnd = [tempArray lastObject];
	
	NSMutableString *returnHTML = [NSMutableString stringWithString:templateStringStart];
	
	[returnHTML replaceOccurrencesOfString:@"%PageTitle%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%PatientID%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"patientID"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%PatientName%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyComment%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"comment"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"studyName"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyModality%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"modality"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
	if( [[study valueForKey:@"stateText"] intValue] == 0)
		stateText = nil;
	[returnHTML replaceOccurrencesOfString:@"%StudyState%" withString:[OsiriXHTTPConnection nonNilString:stateText] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	NSDateFormatter *dobDateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dobDateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateOfBirthFormat2"]];
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
	
	[returnHTML replaceOccurrencesOfString:@"%PatientDOB%" withString:[OsiriXHTTPConnection nonNilString:[dobDateFormat stringFromDate:[study valueForKey:@"dateOfBirth"]]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyDate%" withString:[OsiriXHTTPConnection iPhoneCompatibleNumericalFormat:[OsiriXHTTPConnection nonNilString:[dateFormat stringFromDate:[study valueForKey:@"date"]]]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	NSArray *seriesArray = [study valueForKey:@"imageSeries"];
	
	NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
	NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	NSArray * sortDescriptors;
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
	[sortid release];
	[sortdate release];
	
	seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
	
	for(DicomSeries *series in seriesArray)
	{
		NSMutableString *tempHTML = [NSMutableString stringWithString:seriesListItemString];
		[tempHTML replaceOccurrencesOfString:@"%SeriesName%" withString:[OsiriXHTTPConnection nonNilString:[series valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%thumbnail%" withString:[NSString stringWithFormat:@"thumbnail?id=%@&studyID=%@", [OsiriXHTTPConnection nonNilString:[series valueForKey:@"seriesInstanceUID"]], [OsiriXHTTPConnection nonNilString:[study valueForKey:@"studyInstanceUID"]]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesID%" withString:[OsiriXHTTPConnection nonNilString:[series valueForKey:@"seriesInstanceUID"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesComment%" withString:[OsiriXHTTPConnection nonNilString:[series valueForKey:@"comment"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%PatientName%" withString:[OsiriXHTTPConnection nonNilString:[series valueForKeyPath:@"study.name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[series valueForKey:@"stateText"] intValue]];
		if( [[series valueForKey:@"stateText"] intValue] == 0)
			stateText = nil;
		[tempHTML replaceOccurrencesOfString:@"%SeriesState%" withString:[OsiriXHTTPConnection nonNilString:stateText] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		
		int nbFiles = [[series valueForKey:@"noFiles"] intValue];
		if( nbFiles <= 1)
		{
			if( nbFiles == 0)
				nbFiles = 1;
		}
		NSString *imagesLabel = (nbFiles>1)? NSLocalizedString(@"Images", @"") : NSLocalizedString(@"Image", @"");
		[tempHTML replaceOccurrencesOfString:@"%SeriesImageNumber%" withString:[NSString stringWithFormat:@"%d %@", nbFiles, imagesLabel] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSString *checked = @"";
		for(NSString* selectedID in [parameters objectForKey:@"selected"])
		{
			if([[series valueForKey:@"seriesInstanceUID"] isEqualToString:[[selectedID stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "]])
				checked = @"checked";
		}
		
		[tempHTML replaceOccurrencesOfString:@"%checked%" withString:checked options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		[returnHTML appendString:tempHTML];
	}
	
	tempArray = [templateStringEnd componentsSeparatedByString:@"%dicomNodesListItem%"];
	templateStringStart = [tempArray objectAtIndex:0];
	tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/dicomNodesListItem%"];
	NSString *dicomNodesListItemString = [tempArray objectAtIndex:0];
	templateStringEnd = [tempArray lastObject];
	
	[returnHTML appendString:templateStringStart];
	
	NSString *checkAllStyle = @"";
	if([seriesArray count]<=1) checkAllStyle = @"style='display:none;'";
	[returnHTML replaceOccurrencesOfString:@"%CheckAllStyle%" withString:checkAllStyle options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	if( [[currentUser valueForKey: @"sendDICOMtoSelfIP"] boolValue] == YES && [[parameters objectForKey: @"dicomcstoreport"] intValue] > 0 && [ipAddressString length] >= 7)
	{
		NSString *dicomNodeAddress = ipAddressString;
		NSString *dicomNodePort = [parameters objectForKey: @"dicomcstoreport"];
		NSString *dicomNodeAETitle = @"This Computer";
		
		NSString *dicomNodeSyntax;
		if( [[settings valueForKey:@"iPhone"] boolValue]) dicomNodeSyntax = @"5";
		else dicomNodeSyntax = @"0";
		NSString *dicomNodeDescription = @"This Computer";
		
		NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
		if([[settings valueForKey:@"iPhone"] boolValue]) [tempHTML replaceOccurrencesOfString:@"[%dicomNodeAddress%:%dicomNodePort%]" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:dicomNodeAddress options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:dicomNodePort options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:dicomNodeAETitle options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:dicomNodeSyntax options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:dicomNodeDescription options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		[returnHTML appendString:tempHTML];
	}
	
	if( [[currentUser valueForKey: @"sendDICOMtoAnyNodes"] boolValue] == YES)
	{
		NSArray *nodes = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
		for(NSDictionary *node in nodes)
		{
			NSString *dicomNodeAddress = [OsiriXHTTPConnection nonNilString:[node objectForKey:@"Address"]];
			NSString *dicomNodePort = [NSString stringWithFormat:@"%d", [[node objectForKey:@"Port"] intValue]];
			NSString *dicomNodeAETitle = [OsiriXHTTPConnection nonNilString:[node objectForKey:@"AETitle"]];
			NSString *dicomNodeSyntax = [NSString stringWithFormat:@"%d", [[node objectForKey:@"TransferSyntax"] intValue]];
			NSString *dicomNodeDescription = [OsiriXHTTPConnection nonNilString:[node objectForKey:@"Description"]];
			
			NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
			if([[settings valueForKey:@"iPhone"] boolValue]) [tempHTML replaceOccurrencesOfString:@"[%dicomNodeAddress%:%dicomNodePort%]" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:dicomNodeAddress options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:dicomNodePort options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:dicomNodeAETitle options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:dicomNodeSyntax options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:dicomNodeDescription options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			
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
			
			[tempHTML replaceOccurrencesOfString:@"%selected%" withString:selected options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
			
			[returnHTML appendString:tempHTML];
		}
	}
	
	[returnHTML appendString:templateStringEnd];
	
	if([[parameters objectForKey:@"CheckAll"] isEqualToString:@"on"] || [[parameters objectForKey:@"CheckAll"] isEqualToString:@"checked"])
	{
		[returnHTML replaceOccurrencesOfString:@"%CheckAllLabel%" withString:NSLocalizedString(@"Uncheck All", @"") options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		[returnHTML replaceOccurrencesOfString:@"%CheckAllChecked%" withString:NSLocalizedString(@"checked", @"") options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	}
	else
	{
		[returnHTML replaceOccurrencesOfString:@"%CheckAllLabel%" withString:NSLocalizedString(@"Check All", @"") options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		[returnHTML replaceOccurrencesOfString:@"%CheckAllChecked%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	}
	
	[context unlock];
	
	return returnHTML;
}

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies settings: (NSDictionary*) settings
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"studyList.html"]];
	NSArray *tempArray, *tempArray2;
	if( [[currentUser valueForKey: @"downloadZIP"] boolValue] == NO)
	{
		tempArray = [templateString componentsSeparatedByString:@"%ZIPFunctions%"];
		tempArray2 = [[tempArray lastObject] componentsSeparatedByString:@"%/ZIPFunctions%"];
		templateString = [NSMutableString stringWithFormat:@"%@%@",[tempArray objectAtIndex:0], [tempArray2 lastObject]];
	}
	else
	{
		[templateString replaceOccurrencesOfString:@"%ZIPFunctions%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%/ZIPFunctions%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	}
	
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Home%" withString:NSLocalizedString(@"Home", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_DownloadAsZIP%" withString:NSLocalizedString(@"ZIP file", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	tempArray = [templateString componentsSeparatedByString:@"%StudyListItem%"];
	NSString *templateStringStart = [tempArray objectAtIndex:0];
	tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/StudyListItem%"];
	NSString *studyListItemString = [tempArray objectAtIndex:0];
	NSString *templateStringEnd = [tempArray lastObject];
	
	NSMutableString *returnHTML = [NSMutableString stringWithString:templateStringStart];
	
	for(DicomStudy *study in studies)
	{
		NSMutableString *tempHTML = [NSMutableString stringWithString:studyListItemString];
		// asciiString?
		[tempHTML replaceOccurrencesOfString:@"%StudyListItemName%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSArray *seriesArray = [study valueForKey:@"imageSeries"] ; //imageSeries
		int count = 0;
		for(DicomSeries *series in seriesArray)
		{
			count++;
		}
		
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
		
		NSString *date = [dateFormat stringFromDate:[study valueForKey:@"date"]];
		
		[tempHTML replaceOccurrencesOfString:@"%StudyDate%" withString:[NSString stringWithFormat:@"%@", [OsiriXHTTPConnection iPhoneCompatibleNumericalFormat:date]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesCount%" withString:[NSString stringWithFormat:@"%d Series", count] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%StudyComment%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"comment"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"studyName"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%StudyModality%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"modality"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSString *stateText = @"";
		if( [[study valueForKey:@"stateText"] intValue])
			stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
		[tempHTML replaceOccurrencesOfString:@"%StudyState%" withString:[OsiriXHTTPConnection nonNilString:stateText] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%StudyListItemID%" withString:[OsiriXHTTPConnection nonNilString:[study valueForKey:@"studyInstanceUID"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[returnHTML appendString:tempHTML];
	}
	
	[returnHTML appendString:templateStringEnd];
	
	[context unlock];
	
	return returnHTML;
}

- (NSArray*)studiesForPredicate:(NSPredicate *)predicate;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray *studiesArray;
	
	[context retain];
	[context lock];
	
	if( [[currentUser valueForKey: @"studyPredicate"] length] > 0)
	{
		@try
		{
			NSString *userPredicateString = [currentUser valueForKey: @"studyPredicate"];
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, [[BrowserController currentBrowser] smartAlbumPredicateString: userPredicateString], nil]];
		}
		@catch( NSException *e)
		{
			NSLog( @"****** User Filter Error : %@", e);
			NSLog( @"****** NO studies will be displayed.");
			
			predicate = [NSPredicate predicateWithValue: NO];
		}
	}
	
	@try
	{
		// Find all studies
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity:[[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate:predicate];
		
		error = nil;
		studiesArray = [context executeFetchRequest:dbRequest error:&error];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"studiesForPredicate exception: %@", e.description);
	}
	
	[context unlock];
	[context release];
	
	studiesArray = [studiesArray sortedArrayUsingSelector:@selector(compareName:)];
	
	return studiesArray;
}

- (NSArray*)seriesForPredicate:(NSPredicate *)predicate;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray *seriesArray;
	
	[context retain];
	[context lock];
	
	@try
	{
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity:[[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
		[dbRequest setPredicate:predicate];
		
		error = nil;
		seriesArray = [context executeFetchRequest:dbRequest error:&error];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"seriesForPredicate exception: %@", e.description);
	}
	
	[context unlock];
	[context release];
	
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
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	NSArray *studiesArray, *albumArray;
	
	[context retain];
	[context lock];
	
	@try
	{
		// Find all studies
		NSError *error = nil;
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity:[[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", albumName]];
		error = nil;
		albumArray = [context executeFetchRequest:dbRequest error:&error];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"studiesForAlbum exception: %@", e.description);
	}
	
	[context unlock];
	[context release];
	
	NSManagedObject *album = [albumArray lastObject];
	if([[album valueForKey:@"smartAlbum"] intValue]==1)
	{
		studiesArray = [self studiesForPredicate:[[BrowserController currentBrowser] smartAlbumPredicateString: [album valueForKey:@"predicateString"]]];
	}
	else
	{
		studiesArray = [[album valueForKey:@"studies"] allObjects];
	}
	
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
	NSMutableString *encodedString = [NSMutableString stringWithString:aString];
	[encodedString replaceOccurrencesOfString:@":" withString:@"%3A" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%" withString:@"%25" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"#" withString:@"%23" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@";" withString:@"%3B" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"@" withString:@"%40" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@" " withString:@"+" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	return encodedString;
}

+ (NSString*)decodeURLString:(NSString*)aString;
{
	NSMutableString *encodedString = [NSMutableString stringWithString:aString];
	[encodedString replaceOccurrencesOfString:@"%3A" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%2F" withString:@"/" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%25" withString:@"%" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%23" withString:@"#" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%3B" withString:@";" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"%40" withString:@"@" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	[encodedString replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
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

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	BOOL lockReleased = NO;
	BOOL dicomSendFailed = NO;
	
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
	
	// parse the URL to find the parameters (if any)
	NSArray *urlComponenents = [url componentsSeparatedByString:@"?"];
	NSString *parameterString = @"";
	if([urlComponenents count]==2) parameterString = [urlComponenents lastObject];
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
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
				[parameters setObject:[p lastObject] forKey:[p objectAtIndex:0]];
		}
		if([selected count])
			[parameters setObject:selected forKey:@"selected"];
	}
	//NSLog(@"parameters : %@", parameters);
	
	NSString *portString = [parameters objectForKey: @"dicomcstoreport"];
	if( portString == 0L)
		portString = @"11112";
	
	// find the name of the requested file
	urlComponenents = [(NSString*)[urlComponenents objectAtIndex:0] componentsSeparatedByString:@"?"];
	NSString *fileURL = [urlComponenents objectAtIndex:0];
	//NSLog(@"fileURL : %@", fileURL);
	
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
		requestedFile = [webDirectory stringByAppendingPathComponent:fileURL];
		err = ![[NSFileManager defaultManager] fileExistsAtPath:requestedFile];
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	data = [NSData dataWithContentsOfFile:requestedFile];
#pragma mark index.html
	if([requestedFile isEqualToString:[webDirectory stringByAppendingPathComponent:@"index.html"]])
	{
		NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"index.html"]];
		
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_SearchPatient%" withString:NSLocalizedString(@"Search Patient", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_SearchPatientID%" withString:NSLocalizedString(@"Search Patient ID", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_SearchButton%" withString:NSLocalizedString(@"Search", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Browse%" withString:NSLocalizedString(@"Browse", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Last6Hours%" withString:NSLocalizedString(@"Last 6 Hours", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Today%" withString:NSLocalizedString(@"Today", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyList%" withString:NSLocalizedString(@"Study List", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Albums%" withString:NSLocalizedString(@"Albums", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
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
			if(![[album valueForKey:@"name"] isEqualToString:NSLocalizedString(@"Database", @"")])
			{
				NSMutableString *tempString = [NSMutableString stringWithString:albumListItemString];
				[tempString replaceOccurrencesOfString:@"%AlbumName%" withString:[album valueForKey:@"name"] options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
				[tempString replaceOccurrencesOfString:@"%AlbumNameURL%" withString:[OsiriXHTTPConnection encodeURLString:[album valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
				[returnHTML appendString:tempString];
			}
		}
		
		[returnHTML appendString:templateStringEnd];
		
		[returnHTML replaceOccurrencesOfString: @"%DicomCStorePort%" withString: portString options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		
		[returnHTML replaceOccurrencesOfString: @"%DicomCStorePort%" withString: portString options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
		
		data = [returnHTML dataUsingEncoding:NSUTF8StringEncoding];
	}
#pragma mark wado
	else if([fileURL isEqualToString:@"/wado"]) 
	{
		if([[[parameters objectForKey:@"requestType"] lowercaseString] isEqualToString: @"wado"])
		{
			NSString *studyUID = [[parameters objectForKey:@"studyUID"] lowercaseString];
			NSString *seriesUID = [[parameters objectForKey:@"seriesUID"] lowercaseString];
			NSString *objectUID = [[parameters objectForKey:@"objectUID"] lowercaseString];
			NSString *contentType = [[[[parameters objectForKey:@"contentType"] lowercaseString] componentsSeparatedByString: @","] objectAtIndex: 0];
			int rows = [[parameters objectForKey:@"rows"] intValue];
			int columns = [[parameters objectForKey:@"columns"] intValue];
			int windowCenter = [[parameters objectForKey:@"windowCenter"] intValue];
			int windowWidth = [[parameters objectForKey:@"windowWidth"] intValue];
			//				int frameNumber = [[parameters objectForKey:@"frameNumber"] intValue]; -> OsiriX stores frames as images
			int imageQuality = DCMLosslessQuality;
			
			if( [parameters objectForKey:@"imageQuality"])
			{
				if( [[parameters objectForKey:@"imageQuality"] intValue] > 80)
					imageQuality = DCMLosslessQuality;
				else if( [[parameters objectForKey:@"imageQuality"] intValue] > 60)
					imageQuality = DCMHighQuality;
				else if( [[parameters objectForKey:@"imageQuality"] intValue] > 30)
					imageQuality = DCMMediumQuality;
				else if( [[parameters objectForKey:@"imageQuality"] intValue] >= 0)
					imageQuality = DCMLowQuality;
			}
			
			NSString *transferSyntax = [[parameters objectForKey:@"transferSyntax"] lowercaseString];
			NSString *useOrig = [[parameters objectForKey:@"useOrig"] lowercaseString];
			
			NSError *error = nil;
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
			
			@try
			{
				[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
				
				NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error: &error];
				
				if( [studies count] == 0)
					NSLog( @"****** WADO Server : study not found");
				
				if( [studies count] > 1)
					NSLog( @"****** WADO Server : more than 1 study with same uid");
				
				NSArray *allSeries = [[[studies lastObject] valueForKey: @"series"] allObjects];
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
							dicomImageArray = [dicomImageArray sortedArrayUsingDescriptors:sortDescriptors];
							
						}
						@catch (NSException * e)
						{
							NSLog( @"%@", [e description]);
						}
						
						if( [dicomImageArray count] > 1)
						{
							NSString *path = @"/tmp/osirixwebservices";
							[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
							
							NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"id"]];
							name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
							
							NSString *fileName = [path stringByAppendingPathComponent:name];
							fileName = [fileName stringByAppendingString:@".mov"];
							NSString *outFile;
							if( isiPhone)
								outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
							else
								outFile = fileName;
							
							NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", parameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
							
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
		if([(NSString*)[parameters objectForKey:@"browse"] isEqualToString:@"today"])
		{
			browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [self startOfDay:[NSCalendarDate calendarDate]]];
			pageTitle = NSLocalizedString(@"Today", @"");
		}
		else if([(NSString*)[parameters objectForKey:@"browse"] isEqualToString:@"6hours"])
		{
			NSCalendarDate *now = [NSCalendarDate calendarDate];
			browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:[now hourOfDay]-6 minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:nil] timeIntervalSinceReferenceDate]];
			pageTitle = NSLocalizedString(@"Last 6 hours", @"");
		}
		else if([(NSString*)[parameters objectForKey:@"browse"] isEqualToString:@"all"])
		{
			browsePredicate = [NSPredicate predicateWithValue:YES];
			pageTitle = NSLocalizedString(@"Study List", @"");
		}
		else if([parameters objectForKey:@"search"])
		{
			NSMutableString *search = [NSMutableString string];
			NSString *searchString = [NSString stringWithString:[[parameters objectForKey:@"search"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
			pageTitle = NSLocalizedString(@"Search Result", @"");
		}
		else if([parameters objectForKey:@"searchID"])
		{
			NSMutableString *search = [NSMutableString string];
			NSString *searchString = [NSString stringWithString: [[parameters objectForKey:@"searchID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
			pageTitle = NSLocalizedString(@"Search Result", @"");
		}
		else
		{
			browsePredicate = [NSPredicate predicateWithValue:YES];
			pageTitle = NSLocalizedString(@"Study List", @"");
		}
		
		NSMutableString *html = [self htmlStudyListForStudies: [self studiesForPredicate: browsePredicate] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
		
		if([parameters objectForKey:@"album"])
		{
			if(![[parameters objectForKey:@"album"] isEqualToString:@""])
			{
				html = [self htmlStudyListForStudies: [self studiesForAlbum:[OsiriXHTTPConnection decodeURLString:[[parameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
				pageTitle = [OsiriXHTTPConnection decodeURLString:[[parameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
		}
		
		[html replaceOccurrencesOfString:@"%PageTitle%" withString:pageTitle options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		if([parameters objectForKey:@"browse"])[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[parameters objectForKey:@"browse"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		else [html replaceOccurrencesOfString:@"%browse%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])]; 
		
		if([parameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[parameters objectForKey:@"search"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		else [html replaceOccurrencesOfString:@"%search%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		if([parameters objectForKey:@"album"])[html replaceOccurrencesOfString:@"%album%" withString:[NSString stringWithFormat:@"&album=%@",[parameters objectForKey:@"album"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		else [html replaceOccurrencesOfString:@"%album%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		[html replaceOccurrencesOfString: @"%DicomCStorePort%" withString: portString options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		data = [html dataUsingEncoding:NSUTF8StringEncoding];
		err = NO;
	}
#pragma mark study
	else if([fileURL isEqualToString:@"/study"])
	{
		NSPredicate *browsePredicate;
		if([[parameters allKeys] containsObject:@"id"])
		{
			browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		
		#pragma mark dicomSend
		if( [[parameters allKeys] containsObject:@"dicomSend"])
		{
			NSString *dicomDestination = [parameters objectForKey:@"dicomDestination"];
			NSArray *tempArray = [dicomDestination componentsSeparatedByString:@"%3A"];
			NSString *dicomDestinationAddress = [[tempArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString *dicomDestinationPort = [tempArray objectAtIndex:1];
			NSString *dicomDestinationAETitle = [[tempArray objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
				for(NSString* selectedID in [parameters objectForKey:@"selected"])
				{
					NSPredicate *pred = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [parameters objectForKey:@"id"], [[selectedID stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
					
					seriesArray = [self seriesForPredicate: pred];
					for(NSManagedObject *series in seriesArray)
					{
						NSArray *images = [[series valueForKey:@"images"] allObjects];
						[selectedImages addObjectsFromArray:images];
					}
				}
				
				[selectedImages retain];
				if( [selectedImages count])
					[self dicomSend: self];
				else
					dicomSendFailed = YES;
			}
			else
				dicomSendFailed = YES;
		}
		
		NSArray *studies = [self studiesForPredicate:browsePredicate];
		if( [studies count] == 1)
		{
			[self updateLogEntryForStudy: [studies lastObject] withMessage: @"Display Study"];
			
			ipAddressString = [[asyncSocket connectedHost] copy];
			
			NSMutableString *html = [self htmlStudy:[studies lastObject] parameters:parameters settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"iPhone", [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
			
			[html replaceOccurrencesOfString:@"%StudyID%" withString:[parameters objectForKey:@"id"] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			if( [[parameters allKeys] containsObject:@"dicomSend"])
			{
				NSString *dicomDestination = [parameters objectForKey:@"dicomDestination"];
				NSArray *tempArray = [dicomDestination componentsSeparatedByString:@"%3A"];
				NSString *dicomDestinationAETitle = [[tempArray objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSString *dicomDestinationAddress = [[tempArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
				if( dicomSendFailed)
					[html replaceOccurrencesOfString:@"%LocalizedLabel_SendStatus%" withString: [NSString stringWithFormat: NSLocalizedString( @"DICOM Transfer failed.", nil), dicomDestinationAddress, dicomDestinationAETitle] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				else
					[html replaceOccurrencesOfString:@"%LocalizedLabel_SendStatus%" withString: [NSString stringWithFormat: NSLocalizedString( @"Images sent to DICOM node: %@ - %@", nil), dicomDestinationAddress, dicomDestinationAETitle] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			}
			else
				[html replaceOccurrencesOfString:@"%LocalizedLabel_SendStatus%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			if([parameters objectForKey:@"browse"])[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[parameters objectForKey:@"browse"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			else [html replaceOccurrencesOfString:@"%browse%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			if([parameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[parameters objectForKey:@"search"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			else [html replaceOccurrencesOfString:@"%search%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			[html replaceOccurrencesOfString: @"%DicomCStorePort%" withString: portString options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
			data = [html dataUsingEncoding:NSUTF8StringEncoding];
		}
		err = NO;
	}
#pragma mark thumbnail
	else if([fileURL isEqualToString:@"/thumbnail"])
	{
		NSPredicate *browsePredicate;
		if([[parameters allKeys] containsObject:@"id"])
		{
			if( [[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[parameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		NSArray *series = [self seriesForPredicate:browsePredicate];
		if([series count]==1)
		{
			if(![[series lastObject] valueForKey:@"thumbnail"])
				[[BrowserController currentBrowser] buildThumbnail:[series lastObject]];
			
			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[[series lastObject] valueForKey:@"thumbnail"]];				
			NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
			data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
		}
		err = NO;
	}
#pragma mark series
	else if([fileURL isEqualToString:@"/series"])
	{
		NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"series.html"]];			
		[templateString replaceOccurrencesOfString:@"%StudyID%" withString:[parameters objectForKey:@"studyID"] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%SeriesID%" withString:[parameters objectForKey:@"id"] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
		NSString *browse = [OsiriXHTTPConnection nonNilString:[parameters objectForKey:@"browse"]];
		NSString *search = [OsiriXHTTPConnection nonNilString:[parameters objectForKey:@"search"]];
		NSString *album = [OsiriXHTTPConnection nonNilString:[parameters objectForKey:@"album"]];
		
		[templateString replaceOccurrencesOfString:@"%browse%" withString:browse options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%search%" withString:[OsiriXHTTPConnection decodeURLString:search] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		[templateString replaceOccurrencesOfString:@"%album%" withString:[OsiriXHTTPConnection decodeURLString:[album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
		NSPredicate *browsePredicate;
		if([[parameters allKeys] containsObject:@"id"])
		{
			if( [[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[parameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
			[templateString replaceOccurrencesOfString:@"%width%" withString:[NSString stringWithFormat:@"%d", width] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%height%" withString:[NSString stringWithFormat:@"%d", height] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		}
		
		NSString *seriesName = [OsiriXHTTPConnection nonNilString:[[series lastObject] valueForKey:@"name"]];
		[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:seriesName options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
		NSString *studyName = [OsiriXHTTPConnection nonNilString:[[series lastObject] valueForKeyPath:@"study.name"]];
		[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Home%" withString:studyName options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
		[templateString replaceOccurrencesOfString: @"%DicomCStorePort%" withString: portString options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
		
		data = [templateString dataUsingEncoding:NSUTF8StringEncoding];
		err = NO;
	}
#pragma mark ZIP
	else if( [fileURL hasSuffix:@".zip"] || [fileURL hasSuffix:@".osirixzip"])
	{
		NSPredicate *browsePredicate;
		if([[parameters allKeys] containsObject:@"id"])
		{
			if( [[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[parameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
		if( [[parameters allKeys] containsObject:@"id"])
		{
			if( [[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[parameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
			
			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]];
			NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
			data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
		}
		
		err = NO;
	}
#pragma mark movie
	else if([fileURL isEqualToString:@"/movie.mov"])
	{
		NSPredicate *browsePredicate;
		if([[parameters allKeys] containsObject:@"id"])
		{
			if( [[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [[parameters objectForKey:@"studyID"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
				dicomImageArray = [dicomImageArray sortedArrayUsingDescriptors:sortDescriptors];
				
			}
			@catch (NSException * e)
			{
				NSLog( @"%@", [e description]);
			}
			
			if([dicomImageArray count] > 1)
			{
				NSString *path = @"/tmp/osirixwebservices";
				[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
				
				NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"id"]];//[[series lastObject] valueForKey:@"id"];
				name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
				
				NSString *fileName = [path stringByAppendingPathComponent:name];
				fileName = [fileName stringByAppendingString:@".mov"];
				NSString *outFile;
				if( isiPhone)
					outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
				else
					outFile = fileName;
				
				NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", parameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
				
				[[[BrowserController currentBrowser] managedObjectContext] unlock];	
				
				lockReleased = YES;
				[self generateMovie: dict];
				
				data = [NSData dataWithContentsOfFile: outFile];
			}
		}
		
		err = NO;
	}
#pragma mark report
	else if([fileURL isEqualToString:@"/report"])
	{
		NSPredicate *browsePredicate;
		if([[parameters allKeys] containsObject:@"id"])
		{
			browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		NSArray *studies = [self studiesForPredicate:browsePredicate];
		
		if( [studies count] == 1)
		{
			[self updateLogEntryForStudy: [studies lastObject] withMessage: @"Download Report"];
			
			NSString *reportFilePath = [[studies lastObject] valueForKey:@"reportURL"];
			//NSLog(@"reportFilePath: %@", reportFilePath);
			
			reportType = [reportFilePath pathExtension];
			
			if(reportFilePath)
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
				
				data = [NSData dataWithContentsOfFile:reportFilePath];
				
				[[NSFileManager defaultManager] removeFileAtPath:reportFilePath handler:nil];
				
				err = NO;
			}
			else
				err = YES;
		}
	}
	#pragma mark m4v
	else if([fileURL hasSuffix:@".m4v"])
	{
		data = [NSData dataWithContentsOfFile:requestedFile];
		totalLength = [data length];
		
		err = NO;
	}
	#pragma mark account.html
	else if( [fileURL isEqualToString: @"account.html"])
	{
		
	}
	
	if( lockReleased == NO)
		[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	if( err)
		return nil;
	
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
	
	return YES;
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
		if( multipartData == nil)
			[self supportsPOST: nil withSize: 0];
		
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
		
		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};

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
					
					NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
					
					[postBoundary release];
					postBoundary = [[multipartData objectAtIndex:0] copy];
					
					NSLog( @"start boundary: %@", postBoundary);
					
					@try
					{
						NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
						postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
						postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
						
						NSString *extension = [[postInfoComponents lastObject] pathExtension];
						
						//NSString* root = [[[BrowserController currentBrowser] localDocumentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
						NSString* root = @"/tmp/";
						
						NSString* filename = nil;
						int inc = 1;
						
						do
						{
							filename = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebServer Upload %d", inc++]] stringByAppendingPathExtension: extension];
						}
						while( [[NSFileManager defaultManager] fileExistsAtPath: filename]);
						
						NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
						
						int l = [postBoundary length];
						for( int x = dataStartIndex; x < [postDataChunk length]-l; x++)
						{
							NSRange searchRange = {x, l};

							if ([[postDataChunk subdataWithRange:searchRange] isEqualToData: postBoundary])
							{
								fileDataRange.length -= ([postDataChunk length] - x) +2; // -2 = 0x0A0D
								break;
							}
						}
						
						[[NSFileManager defaultManager] createFileAtPath:filename contents: [postDataChunk subdataWithRange:fileDataRange] attributes:nil];
						NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];

						if (file)
						{
							[file seekToEndOfFile];
							[multipartData addObject:file];
						}
						else NSLog( @"***** Failed to create file - processDataChunk : %@", filename);
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
	}
	else
	{
		int l = [postBoundary length];
		NSRange fileDataRange = { 0, [postDataChunk length]};
		
		for( int x = 0; x < [postDataChunk length]-l; x++)
		{
			NSRange searchRange = {x, l};

			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData: postBoundary])
			{
				fileDataRange.length -= ([postDataChunk length] - x) +2; // -2 = 0x0A0D
				break;
			}
		}
		
		@try
		{
			[(NSFileHandle*)[multipartData lastObject] writeData: [postDataChunk subdataWithRange: fileDataRange]];
		}
		@catch (NSException * e)
		{
			NSLog( @"******* writeData processDataChunk exception: %@", e);
		}
	}
}

@end
