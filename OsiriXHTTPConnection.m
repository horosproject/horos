#import "OsiriXHTTPConnection.h"
#import "DDKeychain.h"
#import "BrowserController.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DCMTKStoreSCU.h"
#import "DCMPix.h"
#import <QTKit/QTKit.h>
#import "DCMNetServiceDelegate.h"
#import "AppController.h"
#import "BrowserControllerDCMTKCategory.h"
#import "DCM.h"
#import "HTTPResponse.h"

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define maxResolution 1024

@implementation OsiriXHTTPConnection

- (BOOL)isPasswordProtected:(NSString *)path
{
	// We're only going to password protect the "secret" directory.
	
	return [path hasPrefix:@"/secret"];
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

- (NSString *)passwordForUser:(NSString *)username
{
	// You can do all kinds of cool stuff here.
	// For simplicity, we're not going to check the username, only the password.
	
	return @"secret";
}

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)isSecureServer
{
	// Create an HTTPS server (all connections will be secured via SSL/TLS)
	return NO;
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

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies settings: (NSDictionary*) settings
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"studyList.html"]];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Home%" withString:NSLocalizedString(@"Home", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_DownloadAsZIP%" withString:NSLocalizedString(@"ZIP file", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSArray *tempArray = [templateString componentsSeparatedByString:@"%StudyListItem%"];
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
		
		[tempHTML replaceOccurrencesOfString:@"%StudyDate%" withString:[NSString stringWithFormat:@"%@", [WebServicesMethods iPhoneCompatibleNumericalFormat:date]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
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
	NSDictionary *todo = [NSDictionary dictionaryWithObjectsAndKeys: [selectedDICOMNode objectForKey:@"Address"], @"Address", [selectedDICOMNode objectForKey:@"TransferSyntax"], @"TransferSyntax", [selectedDICOMNode objectForKey:@"Port"], @"Port", [selectedDICOMNode objectForKey:@"AETitle"], @"AETitle", [selectedImages valueForKey: @"completePath"], @"Files", nil];
	[NSThread detachNewThreadSelector:@selector(dicomSendToDo:) toTarget:self withObject:todo];
}

- (void)dicomSendToDo:(NSDictionary*)todo;
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if( sendLock == nil) sendLock = [[NSLock alloc] init];
	
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

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	BOOL lockReleased = NO;
	
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
	//	
	//	if( isiPhone)
	//		NSLog(@"isiPhone : %d", isiPhone);
	
	
	int totalLength;
	
	{
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
		if( portString == 0L) portString = @"0";
		
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
		//NSLog(@"requestedFile : %@", requestedFile);
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
					[tempString replaceOccurrencesOfString:@"%AlbumNameURL%" withString:[WebServicesMethods encodeURLString:[album valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempString length])];
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
				[dbRequest setEntity:[[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
				
				NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
				[context lock];
				
				@try
				{
					[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
					
					NSArray *studies = [context executeFetchRequest: dbRequest error: &error];
					
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
								
								NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"id"]];//[[series lastObject] valueForKey:@"id"];
								name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
								
								NSString *fileName = [path stringByAppendingPathComponent:name];
								fileName = [fileName stringByAppendingString:@".mov"];
								NSString *outFile;
								if( isiPhone)
									outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
								else
									outFile = fileName;
								
//								NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", mess, @"mess", parameters, @"parameters", dicomImageArray, @"dicomImageArray", [NSThread currentThread], @"thread", contentRange, @"contentRange", nil];
//								
//								[[[BrowserController currentBrowser] managedObjectContext] unlock];	// It's important because writeMovie will call performonmainthread !!!
//								
//								[self generateMovie: dict];
//								
//								[[[BrowserController currentBrowser] managedObjectContext] lock];
								
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
				[context unlock];
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
				searchString = [WebServicesMethods decodeURLString:searchString];
				
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
				searchString = [WebServicesMethods decodeURLString:searchString];
				
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
			
			NSMutableString *html = [self htmlStudyListForStudies:[self studiesForPredicate:browsePredicate] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
			
			if([parameters objectForKey:@"album"])
			{
				if(![[parameters objectForKey:@"album"] isEqualToString:@""])
				{
					html = [self htmlStudyListForStudies: [self studiesForAlbum:[WebServicesMethods decodeURLString:[[parameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
					pageTitle = [WebServicesMethods decodeURLString:[[parameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
			
			if( [[parameters allKeys] containsObject:@"dicomSend"])
			{
				NSString *dicomDestination = [parameters objectForKey:@"dicomDestination"];
				NSArray *tempArray = [dicomDestination componentsSeparatedByString:@"%3A"];
				NSString *dicomDestinationAddress = [[tempArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSString *dicomDestinationPort = [tempArray objectAtIndex:1];
				NSString *dicomDestinationAETitle = [[tempArray objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSString *dicomDestinationSyntax = [tempArray objectAtIndex:3];
				
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
				[self dicomSend: self];
			}
			
			NSArray *studies = [self studiesForPredicate:browsePredicate];
			if([studies count]==1)
			{
				// We want the ip address of the client
				char buffer[256];
				[ipAddressString release];
				ipAddressString = nil;
				struct sockaddr *addr = (struct sockaddr *) [[asyncSocket connectedHost] bytes];
				if( addr->sa_family == AF_INET)
				{
					if (inet_ntop(AF_INET, &((struct sockaddr_in *)addr)->sin_addr, buffer, sizeof(buffer)))
						ipAddressString = [[NSString stringWithCString:buffer] retain];
				}
				
				NSMutableString *html = [self htmlStudy:[studies lastObject] parameters:parameters settings: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"iPhone", [NSNumber numberWithBool: isMacOS], @"MacOS", nil]];
				
				[html replaceOccurrencesOfString:@"%StudyID%" withString:[parameters objectForKey:@"id"] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				if( [[parameters allKeys] containsObject:@"dicomSend"])
				{
					NSString *dicomDestination = [parameters objectForKey:@"dicomDestination"];
					NSArray *tempArray = [dicomDestination componentsSeparatedByString:@"%3A"];
					NSString *dicomDestinationAETitle = [[tempArray objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					NSString *dicomDestinationAddress = [[tempArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
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
			[templateString replaceOccurrencesOfString:@"%search%" withString:[WebServicesMethods decodeURLString:search] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%album%" withString:[WebServicesMethods decodeURLString:[album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
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
		else if([fileURL isEqualToString:@"/image"])
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
		else if([fileURL isEqualToString:@"/movie"])
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
					
//					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", mess, @"mess", parameters, @"parameters", dicomImageArray, @"dicomImageArray", [NSThread currentThread], @"thread", contentRange, @"contentRange", nil];
//					
//					[[[BrowserController currentBrowser] managedObjectContext] unlock];	// It's important because writeMovie will call performonmainthread !!!
//					
//					[self generateMovie: dict];
//					
//					[[[BrowserController currentBrowser] managedObjectContext] lock];
					
					//					[NSThread detachNewThreadSelector:@selector( generateMovie:) toTarget: self withObject: dict];		// <- not very stable......
					
					return lockReleased;
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
			if([studies count]==1)
			{
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
						[zipTask setArguments:[NSArray arrayWithObjects:@"-r" , zipFileName, [reportFilePath lastPathComponent], nil]];
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
			
			if([contentRange hasPrefix:@"bytes="])
			{
				NSString *rangeString = [contentRange stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
				NSArray *rangeComponents = [rangeString componentsSeparatedByString:@"-"];
				int rangeStart = [[rangeComponents objectAtIndex:0] intValue];
				int rangeStop = [[rangeComponents objectAtIndex:1] intValue];
				int rangeLength = rangeStop - rangeStart + 1;
				NSRange range = NSMakeRange(rangeStart, rangeLength);
				data = [data subdataWithRange:range];
			}
			err = NO;
		}
		
		if( err)
		{
//			NSLog(@"404 - Not Found : %@", requestedFile);
//			CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, (CFStringRef) vers); // Not found
//			CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", 0]);
//			[mess setResponse:response];
//			CFRelease(response);
			return lockReleased;
		}
		
//		CFHTTPMessageRef response = [self prepareResponse: data fileURL: fileURL contentRange: contentRange totalLength: totalLength mess: mess parameters: parameters];
//		
//		CFHTTPMessageSetBody(response, (CFDataRef)data);
//		[mess setResponse:response];
//		CFRelease(response);
		
		return [[[HTTPDataResponse alloc] initWithData: data] autorelease];
	}
	
//    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, (CFStringRef) vers); // Method Not Allowed
//	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", 0]);
//    [mess setResponse:response];
//    CFRelease(response);
	
	return nil;
}

@end
