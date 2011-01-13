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
#import "WebPortal.h"
#import "WebPortal+Databases.h"
#import "WebPortal+Email+Log.h"
#import "WebPortalDatabase.h"
#import "WebPortalSession.h"
#import "WebPortalResponse.h"
#import "WebPortalConnection+Data.h"
#import "WebPortalUser.h"
#import "WebPortalStudy.h"
#import "DicomDatabase.h"

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

static NSString* NotNil(NSString *s) {
	return s? s : @"";
}

@interface HTTPConnection () // make compiler aware of these hidden methods' existance

-(BOOL)isAuthenticated;
-(void)replyToHTTPRequest;

@end

@interface WebPortalConnection ()

@property(retain,readwrite) WebPortalResponse* response;
@property(retain,readwrite) WebPortalSession* session;
@property(retain,readwrite) WebPortalUser* user;

@end

@implementation WebPortalConnection

@synthesize response;
@synthesize session;
@synthesize user;
@synthesize parameters, GETParams;

-(BOOL)requestIsIOS {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"iPhone"] || [userAgent contains:@"iPad"];	
}

-(BOOL)requestIsMacOS {
	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
	return [userAgent contains:@"Mac OS"];	
}

-(id)initWithAsyncSocket:(AsyncSocket*)newSocket forServer:(HTTPServer*)myServer {
	self = [super initWithAsyncSocket:newSocket forServer:myServer];
	sendLock = [[NSLock alloc] init];
	return self;
}

-(void)dealloc {
	[sendLock lock];
	[sendLock unlock];
	[sendLock release];
	
	self.user = NULL;
	self.response = NULL;
	
	[multipartData release];
	[postBoundary release];
	[POSTfilename release];
	
	self.session = NULL;
	
	[super dealloc];
}

-(WebPortal*)portal {
	return self.server.portal;
}

-(WebPortalServer*)server {
	return (WebPortalServer*)server;
}

-(AsyncSocket*)asyncSocket {
	return asyncSocket;
}

-(CFHTTPMessageRef)request {
	return request;
}

-(NSString*)portalAddress {
	NSString* webPortalAddress = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Host") autorelease];
	if (webPortalAddress)
		webPortalAddress = [[webPortalAddress componentsSeparatedByString:@":"] objectAtIndex:0];
	else webPortalAddress = self.portal.address;
	return webPortalAddress;
}

-(NSString*)portalURL {
	return [self.portal URLForAddress:self.portalAddress];
}

NSString* const SessionDicomCStorePortKey = @"DicomCStorePort"; // NSNumber (int)

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
	if (!n) [session setObject: n = [NSNumber numberWithInt:[self guessDicomCStorePort]] forKey:SessionDicomCStorePortKey];
	return [n stringValue];
}

-(NSString*)passwordForUser:(NSString*)username {
	self.user = NULL;
	
	NSArray* users = NULL;
	[self.portal.database.managedObjectContext lock];
	@try {
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.portal.database.managedObjectContext];
		req.predicate = [NSPredicate predicateWithFormat:@"name == %@", username];
		users = [self.portal.database.managedObjectContext executeFetchRequest:req error:NULL];
	} @catch (NSException* e) {
		NSLog(@"Error: [WebPortalConnection passwordForUser:] %@", e);
	} @finally {
		[self.portal.database.managedObjectContext unlock];
	}
	
	if (users.count)
		self.user = users.lastObject;
	else [self.portal updateLogEntryForStudy:NULL withMessage:[NSString stringWithFormat: @"Unsuccessful login attempt with invalid user name: %@", username] forUser:NULL ip:asyncSocket.connectedHost];
	
	return self.user.password;
}

-(BOOL)isPasswordProtected:(NSString*)path {
	if ([path hasPrefix: @"/wado"]
	|| [path hasPrefix: @"/images/"]
	|| [path isEqual: @"/"]
	|| [path isEqual: @"/style.css"]
	|| [path hasSuffix:@".js"]
	|| [path isEqualToString: @"/iPhoneStyle.css"]
	|| [path hasPrefix: @"/password_forgotten"]
	|| [path hasPrefix: @"/index"]
	|| [path hasPrefix:@"/weasis/"]
	|| [path isEqualToString: @"/favicon.ico"])
		return NO;
	return self.portal.authenticationRequired;
}

-(BOOL)useDigestAccessAuthentication {
	return NO;
}

// Overrides HTTPConnection's method
- (BOOL)isSecureServer {
	return self.portal.usesSSL;
}

/**
 * Overrides HTTPConnection's method
 * 
 * This method is expected to return an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
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
					[theTask setArguments: [NSArray arrayWithObjects: fileName, @"writeMovie", [fileName stringByAppendingString: @" dir"], nil]];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
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
					[theTask setArguments: [NSArray arrayWithObjects: outFile, @"writeMovieiPhone", fileName, nil]];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
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
					[theTask setArguments: [NSArray arrayWithObjects: outFile, @"writeMovie", [outFile stringByAppendingString: @" dir"], nil]];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
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

	NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"id"]]; //[series valueForKey:@"id"];
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
			
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isiPhone], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", parameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
			
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

- (NSObject<HTTPResponse>*)httpResponseForMethod:(NSString*)method URI:(NSString*)path
{
	NSString* url = [[(id)CFHTTPMessageCopyRequestURL(request) autorelease] description];
	DLog(@"HTTP %@ %@", method, url);
	
	// parse the URL to find the parameters (if any)
	NSArray *urlComponenents = [url componentsSeparatedByString:@"?"];
	if ([urlComponenents count] == 2) GETParams = [urlComponenents lastObject];
	else GETParams = NULL;
	
	NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
	// GET params
	[params addEntriesFromDictionary:[WebPortalConnection ExtractParams:GETParams]];
	// POST params
	if ([method isEqualToString: @"POST"] && multipartData.count == 1) {
		NSString* POSTParams = [[[NSString alloc] initWithBytes: [[multipartData lastObject] bytes] length: [(NSData*) [multipartData lastObject] length] encoding: NSUTF8StringEncoding] autorelease];
		[params addEntriesFromDictionary:[WebPortalConnection ExtractParams:POSTParams]];
	}
	parameters = params;
	[response.tokens setObject:parameters forKey:@"Request"];
	
	// find the name of the requested file
	// SECURITY: we cannot allow the client to read any file on the hard disk (outside the shared dir), so no ".." 
	NSString* fileURL = [[urlComponenents objectAtIndex:0] stringByReplacingOccurrencesOfString:@".." withString:@""];
	
//	NSString* userAgent = [(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"User-Agent") autorelease];
//	BOOL isIOS [userAgent contains:@"iPhone"] || [userAgent contains:@"iPad"];	
//	BOOL isMacOS [userAgent contains:@"Mac OS"];	

	NSString* ext = [fileURL pathExtension];
	if ([ext compare:@"jar" options:NSCaseInsensitiveSearch|NSLiteralSearch] == NSOrderedSame)
		response.mimeType = @"application/java-archive";
	if ([ext compare:@"swf" options:NSCaseInsensitiveSearch|NSLiteralSearch] == NSOrderedSame)
		response.mimeType = @"application/x-shockwave-flash";
	
	if ([fileURL hasPrefix:@"/weasis/"])
	{
		response.data = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileURL]];
	}
	else if ([fileURL rangeOfString:@".pvt."].length) {
		response.statusCode = 404;
	}
	else
	{
		[self.portal.dicomDatabase.managedObjectContext lock];
		BOOL lockReleased = NO;
		@try {
			if ([fileURL isEqual:@"/"] || [fileURL isEqual: @"/index"])
				[self processIndexHtml];
			else
			if ([fileURL isEqual: @"/main"])
				[self processMainHtml];
			else
			if ([fileURL isEqual:@"/studyList"])
				[self processStudyListHtml];
			else	
			if ([fileURL isEqual:@"/studyList.json"])
				[self processStudyListJson];
			else
			if ([fileURL isEqual:@"/study"])
				[self processStudyHtml];
			else
			if ([fileURL isEqual:@"/wado"])
				[self processWado];
			else
			if ([fileURL isEqual:@"/thumbnail"])
				[self processThumbnail];
			else
			if ([fileURL isEqual:@"/series.pdf"])
				[self processSeriesPdf];
			else
			if ([fileURL isEqual:@"/series"])
				[self processSeriesHtml];
			else
			if ([fileURL isEqual:@"/series.json"])
				[self processSeriesJson];
			else
			if ([fileURL hasPrefix:@"/report"])
				[self processReport];
			else
			if ([fileURL hasSuffix:@".zip"] || [fileURL hasSuffix:@".osirixzip"])
				[self processZip];
			else
			if ([fileURL hasPrefix:@"/image."])
				[self processImage];
			else
			if ([fileURL isEqual:@"/movie.mov"] || [fileURL isEqual:@"/movie.m4v"] || [fileURL isEqual:@"/movie.swf"])
				[self processMovie];
			else
			if ([fileURL isEqual:@"/password_forgotten"])
				[self processPasswordForgottenHtml];
			else
			if ([fileURL isEqual: @"/account"])
				[self processAccountHtml];
			else
			if ([fileURL isEqual:@"/albums.json"])
				[self processAlbumsJson];
			else
			if ([fileURL isEqual:@"/seriesList.json"])
				[self processSeriesListJson];
			else
			if ([fileURL isEqual:@"/weasis.jnlp"])
				[self processWeasisJnlp];
			else
			if ([fileURL isEqual:@"/weasis.xml"])
				[self processWeasisXml];
			else
			if ([fileURL isEqual:@"/admin/"] || [fileURL isEqual:@"/admin/index"])
				[self processAdminIndexHtml];
			else
			if ([fileURL isEqualToString:@"/admin/user"])
				[self processAdminUserHtml];
			else
			response.data = [self.portal dataForPath:fileURL];
			
			if (!response.data.length && !response.statusCode)
				response.statusCode = 404;
			
		} @catch (NSException* e) {
			response.statusCode = 500;
			NSLog(@"Error: [WebPortalConnection httpResponseForMethod:URI:] %@", e);
		} @finally {
			if (!lockReleased)
				[self.portal.dicomDatabase.managedObjectContext unlock];
		}
	}
	
	if (response.data && !response.statusCode)
		return [[[HTTPDataResponse alloc] initWithData:response.data] autorelease]; // [[[WebPortalResponse alloc] initWithData:data mime:dataMime sessionId:session.sid] autorelease];*/
	else return NULL;
}

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath {
	if ([method isEqual:@"POST"])
		return YES;
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
	
	const NSUInteger CHECKLASTPART = 4096;
	
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
				file = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebPortal Upload %d", inc++]] stringByAppendingPathExtension: [oFile pathExtension]];
			}
			while( [[NSFileManager defaultManager] fileExistsAtPath: file]);
		
			[[NSFileManager defaultManager] moveItemAtPath: oFile toPath: file error: nil];
			
			if (user.uploadDICOMAddToSpecificStudies.boolValue)
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
							
							NSArray *studiesArrayStudyInstanceUID = [user.studies.allObjects valueForKey:@"studyInstanceUID"];
							NSArray *studiesArrayPatientUID = [user.studies.allObjects valueForKey: @"patientUID"];
							
							for ( NSManagedObject *study in studies)
							{
								if ([[study valueForKey: @"type"] isEqualToString:@"Series"])
									study = [study valueForKey:@"study"];
								
								if ([studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
								{
									NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:self.portal.database.managedObjectContext];
									
									[studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
									[studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
									[studyLink setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]] forKey: @"dateAdded"];
									
									[studyLink setValue: user forKey: @"user"];
									
									@try
									{
										[self.portal.database save:NULL];
									}
									@catch (NSException * e)
									{
										NSLog( @"*********** [self.portal.database save:NULL]");
									}
									
									studiesArrayStudyInstanceUID = [user.studies.allObjects valueForKey:@"studyInstanceUID"];
									studiesArrayPatientUID = [user.studies.allObjects valueForKey:@"patientUID"];
									
									[self.portal updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser:user.name ip: nil];
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
							POSTfilename = [[root stringByAppendingPathComponent: [NSString stringWithFormat: @"WebPortal Upload %d", inc++]] stringByAppendingPathExtension: extension];
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




#pragma mark Session, custom authentication

-(void)replyToHTTPRequest {
	self.response = [[[WebPortalResponse alloc] initWithWebPortalConnection:self] autorelease];
	
	NSString* method = [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(request)) autorelease];

	NSArray* cookies = [[(id)CFHTTPMessageCopyHeaderFieldValue(request, (CFStringRef)@"Cookie") autorelease] componentsSeparatedByString:@";"];
	for (NSString* cookie in cookies) {
		// cookie = [cookie stringByTrimmingStartAndEnd];
		NSArray* cookieBits = [cookie componentsSeparatedByString:@"="];
		if (cookieBits.count == 2 && [[cookieBits objectAtIndex:0] isEqual:SessionCookieName]) {
			WebPortalSession* temp = [self.portal sessionForId:[cookieBits objectAtIndex:1]];
			if (temp) self.session = temp;
		}
	}
	
	if ([method isEqualToString:@"GET"]) { // no session, GET... check for tokens
		NSString* url = [[NSMakeCollectable(CFHTTPMessageCopyRequestURL(request)) autorelease] description];
		NSArray* urlComponenents = [url componentsSeparatedByString:@"?"];
		if (urlComponenents.count > 1) {
			NSDictionary* params = [WebPortalConnection ExtractParams:urlComponenents.lastObject];
			NSString* username = [params objectForKey:@"username"];
			NSString* token = [params objectForKey:@"token"];
			if (username && token) // has token, user exists
				self.session = [self.portal sessionForUsername:username token:token];
		}
	}
	
	if (!session)
		self.session = [self.portal newSession];

	[response setSessionId:session.sid];
	
	
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
				NSString* sha1internal = [[[[[self passwordForUser:username] stringByAppendingString:NotNil(session.challenge)] dataUsingEncoding:NSUTF8StringEncoding] sha1Digest] hex];
				if ([sha1 compare:sha1internal options:NSLiteralSearch|NSCaseInsensitiveSearch] == NSOrderedSame) {
					[session setObject:username forKey:SessionUsernameKey];
					[session deleteChallenge];
				}
			}
		}
		
		if ([params objectForKey:@"logout"]) {
			[session setObject:NULL forKey:SessionUsernameKey];
			[user release]; user = NULL;
		}
	}
	
	[response.tokens setObject:NSLocalizedString(@"OsiriX Web Portal", @"Web Portal, general default title") forKey:@"PageTitle"]; // the default title
	[response.tokens setObject:[WebPortalProxy createWithObject:self transformer:[InfoTransformer create]] forKey:@"Info"];
	if (user) [response.tokens setObject:[WebPortalProxy createWithObject:user transformer:[WebPortalUserTransformer create]] forKey:@"User"];	
	
	[super replyToHTTPRequest];
	
	self.response = NULL;
}

-(BOOL)isAuthenticated {
//	if ([super isAuthenticated]) { // HTTP based auth disabled after 3.8.1
//		[session setObject:user.name forKey:SessionUsernameKey];
//		return YES;
//	}

	NSString* sessionUser = [session objectForKey:SessionUsernameKey];
	if (sessionUser) {	// this sets user to sessionUser
		[self passwordForUser:sessionUser];
		if (user)
			return YES;
	} else
		self.user = NULL;
	
	return NO;
}

// #defines from HTTPConnection.m
#define WRITE_ERROR_TIMEOUT 240
#define HTTP_RESPONSE 30

-(void)handleAuthenticationFailed
{
	//NSLog(@"handleAuthenticationFailed user %@", user);
	
	
	//	HTTPAuthenticationRequest* auth = [[[HTTPAuthenticationRequest alloc] initWithRequest:request] autorelease];
	//	if (auth.username)
	//		[self.portal updateLogEntryForStudy:nil withMessage:[NSString stringWithFormat:@"Wrong password for user %@", auth.username] forUser:NULL ip:asyncSocket.connectedHost];
	
	[self processLoginHtml];
	
	NSData* bodyData = self.response.data;
	// Status Code 401 - Unauthorized
	CFHTTPMessageRef resp = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 401, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(resp, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", bodyData.length]);
	CFHTTPMessageSetBody(resp, (CFDataRef)bodyData);
	
	[asyncSocket writeData:[self preprocessErrorResponse:resp] withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(resp);
}

-(void)handleResourceNotFound { // also other errors, actually
	int status = response.statusCode;
	if (!status) status = 404;
	
	CFHTTPMessageRef resp = CFHTTPMessageCreateResponse(kCFAllocatorDefault, status, NULL, kCFHTTPVersion1_1);
	
	NSData* bodyData = response.data;
	if (!bodyData.length)
		bodyData = [[NSString stringWithFormat:@"HTTP error %d", status] dataUsingEncoding:NSUTF8StringEncoding];
	
	CFHTTPMessageSetHeaderFieldValue(resp, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", bodyData.length]);
	CFHTTPMessageSetBody(resp, (CFDataRef)bodyData);
	
	NSData *responseData = [self preprocessErrorResponse:resp];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(resp);
}





@end
