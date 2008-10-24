/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - GPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "WebServicesMethods.h"
#import "BrowserController.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DCMTKStoreSCU.h"
#import "DCMPix.h"
#import <QTKit/QTKit.h>
#import "DCMNetServiceDelegate.h"

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define maxResolution 1024

extern NSThread					*mainThread;

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
  
  return [newImage autorelease];
}

@end


@implementation WebServicesMethods

+ (NSString*)nonNilString:(NSString*)aString;
{
	return (!aString)? @"" : aString;
}

- (void) error: (NSString*) error
{
	NSRunCriticalAlertPanel( NSLocalizedString(@"HTTP Web Server Error", 0L),  [NSString stringWithFormat: NSLocalizedString(@"Error starting HTTP Web Server: %@", 0L), error], NSLocalizedString(@"OK",nil), nil, nil);	
}

- (void) serverThread
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];

	httpServ = [[HTTPServer alloc] init];
	[httpServ setType:@"_http._tcp."];
	[httpServ setName:@"OsiriXWebServer"];
	[httpServ setPort:[[NSUserDefaults standardUserDefaults] integerForKey:@"httpWebServerPort"]];
	[httpServ setDelegate:self];

	NSString *bundlePath = [NSMutableString stringWithString:[[NSBundle mainBundle] resourcePath]];
	webDirectory = [[bundlePath stringByAppendingPathComponent:@"WebServicesHTML"] retain];

	NSError *error = nil;
	if (![httpServ start:&error])
	{
		NSLog(@"Error starting HTTP Web Server: %@", error);
		httpServ = 0L;
		[self performSelectorOnMainThread: @selector(error:) withObject:error waitUntilDone: NO];
	}
	else
	{
		NSLog(@"******** Starting HTTP Web Server on port %d", [httpServ port]);
	}
	
	if( httpServ)
	{
		shouldKeepRunning = YES;
		
		NSRunLoop *theRL = [NSRunLoop currentRunLoop];
		
		[running lock];
		
		while (shouldKeepRunning && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
		
		[running unlock];
	}
	
	[pool release];
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		[QTMovie movie];	//Force QT init on the main thread
		
		lockArray = [[NSMutableDictionary dictionary] retain];
		running = [[NSLock alloc] init];
		
		NSString *path = @"/tmp/osirixwebservices";
		[[NSFileManager defaultManager] removeFileAtPath: path handler:nil];
		
		[NSThread detachNewThreadSelector:@selector(serverThread) toTarget:self withObject:0L];
	}
	return self;
}

- (void)dealloc
{
	shouldKeepRunning = NO;
	[running lock];
	[running unlock];
	[running release];
	
	[sendLock lock];
	[sendLock unlock];
	[sendLock release];
	
	[httpServ release];
	[webDirectory release];
	[selectedDICOMNode release];
	[selectedImages release];
	[lockArray release];
	[super dealloc];
}

- (void) sendResponse:(NSMutableDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSData* data  = [dict objectForKey: @"data"];
	NSString* fileURL = [dict objectForKey: @"fileURL"];
	NSString *contentRange = [dict objectForKey: @"contentRange"];
	int totalLength = [[dict objectForKey: @"totalLength"] intValue];
	HTTPServerRequest* mess = [dict objectForKey: @"mess"];
	NSMutableDictionary *parameters = [dict objectForKey: @"parameters"];
	
	CFHTTPMessageRef response = [self prepareResponse:  data fileURL:  fileURL contentRange: contentRange totalLength: totalLength mess: mess parameters: parameters];
	CFHTTPMessageSetBody(response, (CFDataRef)data);
	[mess setResponse:response];
	CFRelease(response);
	
	[pool release];
}

- (void) generateMovie: (NSMutableDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString* fileURL  = [dict objectForKey: @"fileURL"];
	NSString* contentRange = [dict objectForKey: @"contentRange"];
	NSString *outFile = [dict objectForKey: @"outFile"];
	NSString *fileName = [dict objectForKey: @"fileName"];
	NSThread *httpServerThread = [dict objectForKey: @"thread"];
	NSArray *dicomImageArray = [dict objectForKey: @"dicomImageArray"];
	BOOL isiPhone = [[dict objectForKey:@"isiPhone"] boolValue];

//	if( [lockArray objectForKey: [outFile lastPathComponent]] == 0L) [lockArray setObject: [[[NSLock alloc] init] autorelease] forKey: [outFile lastPathComponent]];
//	[[lockArray objectForKey: [outFile lastPathComponent]] lock];
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	[context lock];
	
	NSMutableArray *imagesArray = [NSMutableArray array];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath: outFile])
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
					
		for (DicomImage *im in dicomImageArray)
		{
			for (int x = 0; x < [[im valueForKey:@"numberOfFrames"] intValue]; x++)
			{
				DCMPix* dcmPix = [[DCMPix alloc] myinit:[im valueForKey:@"completePathResolved"] :0 :1 :0L :x :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im];
			  
				if(dcmPix)
				{
					float curWW = 0;
					float curWL = 0;
					
					if([[im valueForKey:@"series"] valueForKey:@"windowWidth"])
					{
						curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
						curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
					}
					
					if(curWW!=0 && curWW!=curWL)
						[dcmPix checkImageAvailble:curWW :curWL];
					else
						[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
					
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
					[dcmPix release];
				}
			}
		}
		
		[context unlock];	// It's important because writeMovie will call performonmainthread !!!
		
		[[BrowserController currentBrowser] writeMovie:imagesArray name:fileName];
		
		if( isiPhone)
		{
			[self exportMovieToiPhone:fileName newFileName:outFile];
			[[NSFileManager defaultManager] removeFileAtPath:fileName handler:nil];
		}
		
		[context lock];
	}
	
	[context unlock];
	
//	[[lockArray objectForKey: [outFile lastPathComponent]] unlock];
	
	NSData *data = [NSData dataWithContentsOfFile:outFile];
	int totalLength = [data length];
	
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
	
	[dict setObject: data forKey: @"data"];
	[dict setObject: [NSNumber numberWithInt: totalLength] forKey: @"totalLength"];
	
	// The answer HAS to be performed on the same thread as the http server
	
	[self performSelector:@selector( sendResponse:) onThread: httpServerThread withObject:dict waitUntilDone: YES];
	
	[pool release];
}

- (CFHTTPMessageRef) prepareResponse: (NSData*) data fileURL: (NSString*) fileURL contentRange:(NSString*) contentRange totalLength:(int) totalLength mess:(HTTPServerRequest*) mess parameters:(NSMutableDictionary*) parameters
{
	CFHTTPMessageRef request = [mess request];
	
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
	if([fileURL isEqualToString:@"/thumbnail"]) CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("image/png"));
	else if([fileURL isEqualToString:@"/image"]) CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("image/png"));
	else if([fileURL isEqualToString:@"/movie"] || [fileURL hasSuffix:@".m4v"])
	{
		if([contentRange hasPrefix:@"bytes="])
		{
			NSString *rangeString = [contentRange stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
			NSArray *rangeComponents = [rangeString componentsSeparatedByString:@"-"];
			int rangeStart = [[rangeComponents objectAtIndex:0] intValue];
			int rangeStop = [[rangeComponents objectAtIndex:1] intValue];
			if(rangeStop-rangeStart+1<=totalLength)
			{
				CFRelease(response);
				response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 206, NULL, kCFHTTPVersion1_1); //Partial Content
				CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
				CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Range"), (CFStringRef)[NSString stringWithFormat:@"bytes %d-%d/%d", rangeStart, rangeStop, totalLength]);
			}
		}
		
		//CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("video/x-m4v")); // doesn't work with safari...
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("video/mp4"));
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Accept-Ranges"), CFSTR("bytes"));
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Last-Modified"), CFSTR("Fri, 21 Dec 2007 16:00:00 GMT"));

		NSString *ifModifiedSince = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"If-Modified-Since") autorelease];
		//NSLog(@"ifModifiedSince : %@", ifModifiedSince);
		if(ifModifiedSince && ![contentRange hasPrefix:@"bytes="])
		{
			CFRelease(response);
			response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 304, NULL, kCFHTTPVersion1_1); 
		}
		NSDate *now = [NSDate date];
		NSString *currentDate = [now descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S GMT" timeZone:nil locale:nil];
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Date"), (CFStringRef) currentDate);
		
		
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Keep-Alive"), CFSTR("timeout=5, max=100"));
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Connection"), CFSTR("Keep-Alive"));
	
		if([[parameters allKeys] containsObject:@"id"])
		{
			CFHTTPMessageSetHeaderFieldValue(response, CFSTR("ETag"), (CFStringRef)[parameters objectForKey:@"id"]);
		}
		else
		{
			CFHTTPMessageSetHeaderFieldValue(response, CFSTR("ETag"), CFSTR("xyzzy"));
		}
	}
	else if([fileURL isEqualToString:@"/report"])
	{
		CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), CFSTR("application/zip"));
	}
	
	return response;
}

- (void)HTTPConnection:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess
{
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	@try
	{
		[self HTTPConnectionProtected:conn didReceiveRequest:mess];
	}
	
	@catch (NSException * e)
	{
		NSLog( @"HTTPConnection WebServices : %@", e);
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
}

- (void)HTTPConnectionProtected:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess
{
    CFHTTPMessageRef request = [mess request];
	
	NSDictionary *allHeaderFields = [(id)CFHTTPMessageCopyAllHeaderFields(request) autorelease];
	
	NSString *contentRange = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Range") autorelease];
	
	NSString *userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	
	NSScanner *scan = [NSScanner scannerWithString:userAgent];
	BOOL isSafari = NO;
	while(![scan isAtEnd] && !isSafari)
	{
		isSafari = [scan scanString:@"Safari/" intoString:nil];
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
	
	if(!isiPhone) // look for Mobile Webkit (used in Mobile OsiriX)
	{
		scan = [NSScanner scannerWithString:userAgent];
		BOOL isiPhoneOS = NO;
		while(![scan isAtEnd] && !isiPhoneOS)
		{
			isiPhoneOS = [scan scanString:@"iPhone OS" intoString:nil];
			[scan setScanLocation:[scan scanLocation]+1];
		}
		
		scan = [NSScanner scannerWithString:userAgent];
		BOOL isWebKit = NO;
		while(![scan isAtEnd] && !isWebKit)
		{
			isWebKit = [scan scanString:@"AppleWebKit" intoString:nil];
			[scan setScanLocation:[scan scanLocation]+1];
		}
		
		isiPhone = isiPhoneOS && isWebKit;
	}
//	
//	if( isiPhone)
//		NSLog(@"isiPhone : %d", isiPhone);
	
    NSString *vers = [(id)CFHTTPMessageCopyVersion(request) autorelease];
//	NSLog(@"vers : %@", vers);
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, vers ? (CFStringRef)vers : kCFHTTPVersion1_0); // Version Not Supported
        [mess setResponse:response];
        CFRelease(response);
        return;
    }

    NSString *method = [(id)CFHTTPMessageCopyRequestMethod(request) autorelease];
//	NSLog(@"method : %@", method);
    if (!method) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
	
	int totalLength;
	
    if ([method isEqual:@"GET"])
	{
		int i;
		NSError *error = nil;
		
		NSString *url = [[(id)CFHTTPMessageCopyRequestURL(request) autorelease] description];
		//NSLog(@"url : %@", url);
				
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
		if([requestedFile isEqualToString:[webDirectory stringByAppendingPathComponent:@"index.html"]])
		{
			NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"index.html"]];
			
			[templateString replaceOccurrencesOfString:@"%LocalizedLabel_SearchPatient%" withString:NSLocalizedString(@"Search Patient", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
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

			data = [returnHTML dataUsingEncoding:NSUTF8StringEncoding];
		}
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
				browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:[now hourOfDay]-6 minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:0L] timeIntervalSinceReferenceDate]];
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
			else
			{
				browsePredicate = [NSPredicate predicateWithValue:YES];
				pageTitle = NSLocalizedString(@"Study List", @"");
			}
			
			NSMutableString *html = [self htmlStudyListForStudies:[self studiesForPredicate:browsePredicate]];
			
			if([parameters objectForKey:@"album"])
			{
				if(![[parameters objectForKey:@"album"] isEqualToString:@""])
				{
					html = [self htmlStudyListForStudies:[self studiesForAlbum:[WebServicesMethods decodeURLString:[[parameters objectForKey:@"album"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
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

			data = [html dataUsingEncoding:NSUTF8StringEncoding];
			err = NO;
		}
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
				NSString *dicomDestinationAddress = [tempArray objectAtIndex:0];
				NSString *dicomDestinationPort = [tempArray objectAtIndex:1];
				NSString *dicomDestinationAETitle = [tempArray objectAtIndex:2];
				NSString *dicomDestinationSyntax = [tempArray objectAtIndex:3];
								
				[selectedDICOMNode release];
				selectedDICOMNode = [NSMutableDictionary dictionary];
				[selectedDICOMNode setObject:dicomDestinationAddress forKey:@"Address"];
				[selectedDICOMNode setObject:dicomDestinationPort forKey:@"Port"];
				[selectedDICOMNode setObject:dicomDestinationAETitle forKey:@"AETitle"];
				[selectedDICOMNode setObject:dicomDestinationSyntax forKey:@"Transfer Syntax"];
				[selectedDICOMNode retain];

				[selectedImages release];
				selectedImages = [NSMutableArray array];
				NSArray *seriesArray;
				for(NSString* selectedID in [parameters objectForKey:@"selected"])
				{
					NSPredicate *browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [[selectedID stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
					seriesArray = [self seriesForPredicate:browsePredicate];
					for(NSManagedObject *series in seriesArray)
					{
						NSArray *images = [[series valueForKey:@"images"] allObjects];
						[selectedImages addObjectsFromArray:images];
					}
				}
				
				[selectedImages retain];
				[self dicomSend:self];
			}
				
			NSArray *studies = [self studiesForPredicate:browsePredicate];
			if([studies count]==1)
			{
				// We want the ip address of the client
				char buffer[256];
				[ipAddressString release];
				ipAddressString = 0L;
				struct sockaddr *addr = (struct sockaddr *) [[conn peerAddress] bytes];
				if( addr->sa_family == AF_INET)
				{
					if (inet_ntop(AF_INET, &((struct sockaddr_in *)addr)->sin_addr, buffer, sizeof(buffer)))
						ipAddressString = [[NSString stringWithCString:buffer] retain];
				}
				
				NSMutableString *html = [self htmlStudy:[studies lastObject] parameters:parameters isiPhone:isiPhone];
				[html replaceOccurrencesOfString:@"%StudyID%" withString:[parameters objectForKey:@"id"] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				
				if([parameters objectForKey:@"browse"])[html replaceOccurrencesOfString:@"%browse%" withString:[NSString stringWithFormat:@"&browse=%@",[parameters objectForKey:@"browse"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				else [html replaceOccurrencesOfString:@"%browse%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];

				if([parameters objectForKey:@"search"])[html replaceOccurrencesOfString:@"%search%" withString:[NSString stringWithFormat:@"&search=%@",[parameters objectForKey:@"search"]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
				else [html replaceOccurrencesOfString:@"%search%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
			
				data = [html dataUsingEncoding:NSUTF8StringEncoding];
			}
			err = NO;
		}
		else if([fileURL isEqualToString:@"/thumbnail"])
		{
			NSPredicate *browsePredicate;
			if([[parameters allKeys] containsObject:@"id"])
			{
				browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
		else if([fileURL isEqualToString:@"/series"])
		{
			NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"series.html"]];			
			[templateString replaceOccurrencesOfString:@"%StudyID%" withString:[parameters objectForKey:@"studyID"] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%SeriesID%" withString:[parameters objectForKey:@"id"] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			NSString *browse = [WebServicesMethods nonNilString:[parameters objectForKey:@"browse"]];
			NSString *search = [WebServicesMethods nonNilString:[parameters objectForKey:@"search"]];
			NSString *album = [WebServicesMethods nonNilString:[parameters objectForKey:@"album"]];
			
			[templateString replaceOccurrencesOfString:@"%browse%" withString:browse options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%search%" withString:[WebServicesMethods decodeURLString:search] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			[templateString replaceOccurrencesOfString:@"%album%" withString:[WebServicesMethods decodeURLString:[album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];

			NSPredicate *browsePredicate;
			if([[parameters allKeys] containsObject:@"id"])
			{
				browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			NSArray *series = [self seriesForPredicate:browsePredicate];
			NSArray *imagesArray = [[[series lastObject] valueForKey:@"images"] allObjects];
			if([imagesArray count] == 1 && [[[imagesArray lastObject] valueForKey: @"numberOfFrames"] intValue] <= 1)
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
			
			NSString *seriesName = [WebServicesMethods nonNilString:[[series lastObject] valueForKeyPath:@"name"]];
			[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:seriesName options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
			
			NSString *studyName = [WebServicesMethods nonNilString:[[series lastObject] valueForKeyPath:@"study.name"]];
			[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Home%" withString:studyName options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];

			
			data = [templateString dataUsingEncoding:NSUTF8StringEncoding];
			err = NO;
		}
		else if([fileURL isEqualToString:@"/image"])
		{
			NSPredicate *browsePredicate;
			if([[parameters allKeys] containsObject:@"id"])
			{
				browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			}
			else
				browsePredicate = [NSPredicate predicateWithValue:NO];
			
			NSArray *series = [self seriesForPredicate:browsePredicate];
			if([series count]==1)
			{
				NSMutableArray *imagesArray = [NSMutableArray array];
				NSArray *dicomImageArray = [[[series lastObject] valueForKey:@"images"] allObjects];
				DicomImage *im;
				if([dicomImageArray count] == 1 && [[[dicomImageArray lastObject] valueForKey: @"numberOfFrames"] intValue] <= 1)
				{
					im = [dicomImageArray lastObject];
				}
				else
				{
					im = [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
				}
				
				DCMPix* dcmPix = [[DCMPix alloc] myinit:[im valueForKey:@"completePathResolved"] :0 :1 :0L :[[[dicomImageArray lastObject] valueForKey: @"numberOfFrames"] intValue]/2 :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im];
				  
				if(dcmPix)
				{
					float curWW = 0;
					float curWL = 0;
					
					if([[im valueForKey:@"series"] valueForKey:@"windowWidth"])
					{
						curWW = [[[im valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
						curWL = [[[im valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
					}
					
					if(curWW!=0 && curWW!=curWL)
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
		else if([fileURL isEqualToString:@"/movie"])
		{
			NSPredicate *browsePredicate;
			if([[parameters allKeys] containsObject:@"id"])
			{
				browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [[parameters objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
					NSLog( [e description]);
				}
				
				if([dicomImageArray count] > 1 || [[[dicomImageArray lastObject] valueForKey: @"numberOfFrames"] intValue] > 1)
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
						
					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", mess, @"mess", parameters, @"parameters", dicomImageArray, @"dicomImageArray", [NSThread currentThread], @"thread", contentRange, @"contentRange", 0L];
					
					[[[BrowserController currentBrowser] managedObjectContext] unlock];	// It's important because writeMovie will call performonmainthread !!!
					
					[self generateMovie: dict];
					
					[[[BrowserController currentBrowser] managedObjectContext] lock];
					
//					[NSThread detachNewThreadSelector:@selector( generateMovie:) toTarget: self withObject: dict];		// <- not very stable......
					
					return;
				}
			}
			
			err = NO;
		}
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
				NSString *reportFilePath = [[studies lastObject] valueForKeyPath:@"reportURL"];
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
			NSLog(@"404 - Not Found : %@", requestedFile);
			CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_1); // Not found
			CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", 0]);
			[mess setResponse:response];
			CFRelease(response);
			return;
		}

		CFHTTPMessageRef response = [self prepareResponse:  data fileURL:  fileURL contentRange: contentRange totalLength: totalLength mess: mess parameters: parameters];
		
		CFHTTPMessageSetBody(response, (CFDataRef)data);
		[mess setResponse:response];
		CFRelease(response);
		return;
	}

    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1); // Method Not Allowed
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", 0]);
    [mess setResponse:response];
    CFRelease(response);
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
		// Find all studies
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
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, 0L];
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, 0L];
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
		studiesArray = [[album valueForKeyPath:@"studies"] allObjects];
	}

	return studiesArray;
}

- (NSMutableString*)htmlStudyListForStudies:(NSArray*)studies;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"studyList.html"]];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Home%" withString:NSLocalizedString(@"Home", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
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
		[tempHTML replaceOccurrencesOfString:@"%StudyListItemName%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSArray *seriesArray = [study valueForKeyPath:@"imageSeries"] ; //imageSeries
		int count = 0;
		for(DicomSeries *series in seriesArray)
		{
			count++;
		}

		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];

		NSString *date = [dateFormat stringFromDate:[study valueForKeyPath:@"date"]];
		
		[tempHTML replaceOccurrencesOfString:@"%StudyDate%" withString:[NSString stringWithFormat:@"%@", [WebServicesMethods iPhoneCompatibleNumericalFormat:date]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesCount%" withString:[NSString stringWithFormat:@"%d Series", count] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%StudyComment%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"comment"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSString *stateText = @"";
		if( [[study valueForKeyPath:@"stateText"] intValue])
			stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKeyPath:@"stateText"] intValue]];
		[tempHTML replaceOccurrencesOfString:@"%StudyState%" withString:[WebServicesMethods nonNilString:stateText] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%StudyListItemID%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"studyInstanceUID"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[returnHTML appendString:tempHTML];
	}
	
	[returnHTML appendString:templateStringEnd];
	
	[context unlock];
	
	return returnHTML;
}

- (NSMutableString*)htmlStudy:(DicomStudy*)study parameters:(NSDictionary*)parameters isiPhone:(BOOL)isiPhone;
{
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	
	[context lock];
	
	NSMutableString *templateString = [NSMutableString stringWithContentsOfFile:[webDirectory stringByAppendingPathComponent:@"study.html"]];
	
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientInfo%" withString:NSLocalizedString(@"Patient Info", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientID%" withString:NSLocalizedString(@"ID", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientName%" withString:NSLocalizedString(@"Patient Name", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_PatientDateOfBirth%" withString:NSLocalizedString(@"Date of Birth", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyDate%" withString:NSLocalizedString(@"Study Date", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyState%" withString:NSLocalizedString(@"Study Status", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_StudyComment%" withString:NSLocalizedString(@"Study Comment", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Series%" withString:NSLocalizedString(@"Series", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_DICOMTransfer%" withString:NSLocalizedString(@"DICOM Transfer", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_SendSelectedSeriesTo%" withString:NSLocalizedString(@"Send selected Series to", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%LocalizedLabel_Send%" withString:NSLocalizedString(@"Send", @"") options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];

	NSString *browse = [WebServicesMethods nonNilString:[parameters objectForKey:@"browse"]];
	NSString *search = [WebServicesMethods nonNilString:[parameters objectForKey:@"search"]];
	NSString *album = [WebServicesMethods nonNilString:[parameters objectForKey:@"album"]];
	
	[templateString replaceOccurrencesOfString:@"%browse%" withString:browse options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%search%" withString:[WebServicesMethods decodeURLString:search] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	[templateString replaceOccurrencesOfString:@"%album%" withString:[WebServicesMethods decodeURLString:[album stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] options:NSLiteralSearch range:NSMakeRange(0, [templateString length])];
	
	NSString *LocalizedLabel_StudyList = @"";
	if(![search isEqualToString:@""])
		LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Search Result for", @""), [[WebServicesMethods decodeURLString:search] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else if(![album isEqualToString:@""])
		LocalizedLabel_StudyList = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Album", @""), [[WebServicesMethods decodeURLString:album] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
	
	NSArray *tempArray, *tempArray2;
	
	if([study valueForKeyPath:@"reportURL"] && !isiPhone)
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
							
	[returnHTML replaceOccurrencesOfString:@"%PageTitle%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%PatientID%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"patientID"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%PatientName%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyComment%" withString:[WebServicesMethods nonNilString:[study valueForKeyPath:@"comment"]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKeyPath:@"stateText"] intValue]];
	[returnHTML replaceOccurrencesOfString:@"%StudyState%" withString:[WebServicesMethods nonNilString:stateText] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];

	NSDateFormatter *dobDateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dobDateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateOfBirthFormat2"]];
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];

	[returnHTML replaceOccurrencesOfString:@"%PatientDOB%" withString:[WebServicesMethods nonNilString:[dobDateFormat stringFromDate:[study valueForKeyPath:@"dateOfBirth"]]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	[returnHTML replaceOccurrencesOfString:@"%StudyDate%" withString:[WebServicesMethods iPhoneCompatibleNumericalFormat:[WebServicesMethods nonNilString:[dateFormat stringFromDate:[study valueForKeyPath:@"date"]]]] options:NSLiteralSearch range:NSMakeRange(0, [returnHTML length])];
	
	NSArray *seriesArray = [study valueForKeyPath:@"imageSeries"];

	NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
	NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	NSArray * sortDescriptors;
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, 0L];
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, 0L];
	[sortid release];
	[sortdate release];
		
	seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
	
	for(DicomSeries *series in seriesArray)
	{
		NSMutableString *tempHTML = [NSMutableString stringWithString:seriesListItemString];
		[tempHTML replaceOccurrencesOfString:@"%SeriesName%" withString:[WebServicesMethods nonNilString:[series valueForKeyPath:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%thumbnail%" withString:[NSString stringWithFormat:@"thumbnail?id=%@", [WebServicesMethods nonNilString:[series valueForKeyPath:@"seriesInstanceUID"]]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%SeriesID%" withString:[WebServicesMethods nonNilString:[series valueForKeyPath:@"seriesInstanceUID"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		int nbFiles = [[series valueForKey:@"noFiles"] intValue];
		if( nbFiles <= 1)
		{
			nbFiles = [[[[series valueForKey: @"images"] anyObject] valueForKey: @"numberOfFrames"] intValue];
			if( nbFiles == 0) nbFiles = 1;
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
	
	NSArray *nodes = [self dicomNodes];
	for(NSDictionary *node in nodes)
	{
		NSString *dicomNodeAddress = [WebServicesMethods nonNilString:[node objectForKey:@"Address"]];
		NSString *dicomNodePort = [NSString stringWithFormat:@"%d", [[node objectForKey:@"Port"] intValue]];
		NSString *dicomNodeAETitle = [WebServicesMethods nonNilString:[node objectForKey:@"AETitle"]];
		NSString *dicomNodeSyntax = [NSString stringWithFormat:@"%d", [[node objectForKey:@"Transfer Syntax"] intValue]];
		NSString *dicomNodeDescription = [WebServicesMethods nonNilString:[node objectForKey:@"Description"]];
		
		NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
		if(isiPhone)[tempHTML replaceOccurrencesOfString:@"[%dicomNodeAddress%:%dicomNodePort%]" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:dicomNodeAddress options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:dicomNodePort options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:dicomNodeAETitle options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:dicomNodeSyntax options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:dicomNodeDescription options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		NSString *selected = @"";
		
		if( [parameters objectForKey:@"dicomDestination"])
		{
			if([[NSString stringWithFormat:@"%@:%@:%@:%@", dicomNodeAddress, dicomNodePort, dicomNodeAETitle, dicomNodeSyntax] isEqualToString:[[parameters objectForKey:@"dicomDestination"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]])
				selected = @"selected";
		}
		else if( ipAddressString)
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


- (NSTimeInterval)startOfDay:(NSCalendarDate *)day
{
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[day yearOfCommonEra] month:[day monthOfYear] day:[day dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L];
	return [start timeIntervalSinceReferenceDate];
}

- (NSArray*)dicomNodes;
{
	return [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
	NSMutableArray *nodes = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"SERVERS"]];
	for(NSDictionary *node in nodes)
	{
		if(![node objectForKey:@"Send"]) [nodes removeObject:node];
	}
	return [NSArray arrayWithArray:nodes];
}

- (void)dicomSend:(id)sender;
{	
	NSDictionary *todo = [NSDictionary dictionaryWithObjectsAndKeys: [selectedDICOMNode objectForKey:@"Address"], @"Address", [selectedDICOMNode objectForKey:@"Transfer Syntax"], @"Transfer Syntax", [selectedDICOMNode objectForKey:@"Port"], @"Port", [selectedDICOMNode objectForKey:@"AETitle"], @"AETitle", [selectedImages valueForKey: @"completePath"], @"Files", 0L];
	[NSThread detachNewThreadSelector:@selector(dicomSendToDo:) toTarget:self withObject:todo];
}

- (void)dicomSendToDo:(NSDictionary*)todo;
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if( sendLock == 0L) sendLock = [[NSLock alloc] init];
	
	[sendLock lock];
	
	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
																calledAET: [todo objectForKey:@"AETitle"] 
																hostname: [todo objectForKey:@"Address"] 
																port: [[todo objectForKey:@"Port"] intValue] 
																filesToSend: [todo valueForKey: @"Files"]
																transferSyntax: [[todo objectForKey:@"Transfer Syntax"] intValue] 
																compression: 1.0
																extraParameters: nil];
	
	@try
	{
		[storeSCU run:self];
	}
		
	@catch(NSException *ne)
	{
		NSLog( @"WebService DICOM Send FAILED");
		NSLog( [ne name]);
		NSLog( [ne reason]);
	}
	
	[sendLock unlock];
	
	[storeSCU release];
	storeSCU = 0L;
	
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

    // create the attributes dictionary for movieWithAttributes
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              (id)inFile,                    QTMovieFileNameAttribute,
                              [NSNumber numberWithBool:NO],  QTMovieOpenAsyncOKAttribute,
                              QTMovieApertureModeClean,      QTMovieApertureModeAttribute,
                              [NSNumber numberWithBool:YES], QTMovieIsActiveAttribute,
                              nil];

	QTMovie *aMovie = 0L;
	
    // create a QTMovie from the file
	if( mainThread != [NSThread currentThread])
	{
		[QTMovie enterQTKitOnThread];
		
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: inFile, @"file", 0L];
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
	
	if( mainThread != [NSThread currentThread])
	{
		[aMovie detachFromCurrentThread];
		[QTMovie exitQTKitOnThread];
	}
}
@end
