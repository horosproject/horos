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

#import "WebPortalConnection+Data.h"
#import "WebPortalResponse.h"
#import "DicomAlbum.h"
#import "DicomDatabase.h"
#import "WebPortalUser.h"
#import "WebPortalSession.h"
#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "WebPortal+Databases.h"
#import "AsyncSocket.h"
#import "WebPortalDatabase.h"
#import "WebPortal+Databases.h"
#import "WebPortalConnection.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSString+N2.h"
#import "NSImage+N2.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "WebPortalStudy.h"
#import "DicomImage.h"
#import "DCM.h"
#import "DCMPix.h"
#import "DCMTKStoreSCU.h"
#import "NSFileManager+N2.h"
#import "N2Alignment.h"
#import "DCMAbstractSyntaxUID.h"
#import "NSFileManager+N2.h"
#import "CSMailMailClient.h"
#import "NSObject+SBJSON.h"
#import "NSManagedObject+N2.h"
#import "N2Operators.h"
#import "NSImage+OsiriX.h"


#import "BrowserController.h" // TODO: remove when badness solved
#import "BrowserControllerDCMTKCategory.h" // TODO: remove when badness solved

// TODO: NSUserDefaults access for keys @"logWebServer", @"notificationsEmailsSender" and @"lastNotificationsDate" must be replaced with WebPortal properties


static NSTimeInterval StartOfDay(NSCalendarDate* day) {
	NSCalendarDate* start = [NSCalendarDate dateWithYear:day.yearOfCommonEra month:day.monthOfYear day:day.dayOfMonth hour:0 minute:0 second:0 timeZone:NULL];
	return start.timeIntervalSinceReferenceDate;
}

static volatile int DCMPixLoadingThreads = 0;
static NSRecursiveLock *DCMPixLoadingLock = nil;

@implementation WebPortalConnection (Data)

+(NSArray*)MakeArray:(id)obj {
	if ([obj isKindOfClass:[NSArray class]])
		return obj;
	
	if (obj == nil)
		return [NSArray array];
	
	return [NSArray arrayWithObject:obj];
}

- (id)objectWithXID:(NSString*)xid ofClass:(Class)c {
	NSArray* axid = [xid componentsSeparatedByString:@"/"];
	if (axid.count != 3) {
		NSLog(@"ERROR: unexpected CoreData ID format, please contact the author");
		return nil;
	}
	
	NSString* axidEntityName = [axid objectAtIndex:1];
		
	N2ManagedDatabase* db = self.portal.dicomDatabase;
	if ([axidEntityName isEqualToString:@"User"])
		db = self.portal.database;
	
	NSManagedObject* o = [db objectWithID:[NSManagedObject UidForXid:xid]];
	
	if (c && ![o isKindOfClass:c])
		return nil;
	
	// ensure that the user is allowed to access this object
	
	if (user)
	{
		if ([o isKindOfClass: [DicomStudy class]])
		{
			DicomStudy *s = (DicomStudy*) o;
			
			if( [[self.portal studiesForUser:user predicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", s.patientUID, s.studyInstanceUID]] count] == 0)
				return nil;
		}
		
		if ([o isKindOfClass: [DicomSeries class]])
		{
			DicomSeries *s = (DicomSeries*) o;
			
			if( [[self.portal studiesForUser:user predicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", s.study.patientUID, s.study.studyInstanceUID]] count] == 0)
				return nil;
		}
	}
	
	return o;
}

-(NSArray*)studyList_requestedStudies:(NSString**)title {
	NSString* ignore = NULL;
	if (!title) title = &ignore;
	
	NSString* albumReq = [parameters objectForKey:@"album"];
	if (albumReq.length) {
		*title = [NSString stringWithFormat:NSLocalizedString(@"Album: %@", @"Web portal, study list, title format (%@ is album name)"), albumReq];
		return [self.portal studiesForUser:user album:albumReq sortBy:[parameters objectForKey:@"sortKey"]];
	}
	
	NSString* browseReq = [parameters objectForKey:@"browse"];
	NSString* browseParameterReq = [parameters objectForKey:@"browseParameter"];
	
	NSPredicate* browsePredicate = NULL;
	
	if ([browseReq isEqual:@"newAddedStudies"] && browseParameterReq.doubleValue > 0)
	{
		*title = NSLocalizedString( @"New Studies", @"Web portal, study list, title");
		browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", browseParameterReq.doubleValue];
	}
	else
		if ([browseReq isEqual:@"today"])
		{
			*title = NSLocalizedString( @"Today", @"Web portal, study list, title");
			browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", StartOfDay(NSCalendarDate.calendarDate)];
		}
		else
			if ([browseReq isEqual:@"6hours"])
			{
				*title = NSLocalizedString( @"Last 6 Hours", @"Web portal, study list, title");
				NSCalendarDate *now = [NSCalendarDate calendarDate];
				browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:[now hourOfDay]-6 minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:nil] timeIntervalSinceReferenceDate]];
			}
			else
				if ([parameters objectForKey:@"search"])
				{
					*title = NSLocalizedString(@"Search Results", @"Web portal, study list, title");
					
					NSMutableString* search = [NSMutableString string];
					NSString *searchString = [parameters objectForKey:@"search"];
					
					NSArray* components = [searchString componentsSeparatedByString:@" "];
					NSMutableArray *newComponents = [NSMutableArray array];
					for (NSString *comp in components)
					{
						if (![comp isEqualToString:@""])
							[newComponents addObject:comp];
					}
					
					searchString = [newComponents componentsJoinedByString:@" "];
					searchString = [searchString stringByReplacingOccurrencesOfString: @"\"" withString: @"\'"];
					searchString = [searchString stringByReplacingOccurrencesOfString: @"\'" withString: @"\\'"];
					
					[search appendFormat:@"name CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
					browsePredicate = [NSPredicate predicateWithFormat: search];
				}
				else
					if ([parameters objectForKey:@"searchID"])
					{
						*title = NSLocalizedString(@"Search Results", @"Web portal, study list, title");
						NSMutableString *search = [NSMutableString string];
						NSString *searchString = [NSString stringWithString:[parameters objectForKey:@"searchID"]];
						
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
					}
					else
						if ([parameters objectForKey:@"searchAccessionNumber"])
						{
							*title = NSLocalizedString(@"Search Results", @"Web portal, study list, title");
							NSMutableString *search = [NSMutableString string];
							NSString *searchString = [NSString stringWithString:[parameters objectForKey:@"searchAccessionNumber"]];
							
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
						}
	
	if (!browsePredicate) {
		*title = NSLocalizedString(@"Study List", @"Web portal, study list, title");
		//browsePredicate = [NSPredicate predicateWithValue:YES];
	}	
	
	if ([parameters objectForKey:@"sortKey"])
		if ([[[self.portal.dicomDatabase entityForName:@"Study"] attributesByName] objectForKey:[parameters objectForKey:@"sortKey"]])
			[self.session setObject:[parameters objectForKey:@"sortKey"] forKey:@"StudiesSortKey"];
	if (![self.session objectForKey:@"StudiesSortKey"])
		[self.session setObject:@"name" forKey:@"StudiesSortKey"];
	
	return [self.portal studiesForUser:user predicate:browsePredicate sortBy:[self.session objectForKey:@"StudiesSortKey"] fetchLimit: FETCHLIMIT];
}

-(void)sendImages:(NSArray*)images toDicomNode:(NSDictionary*)dicomNodeDescription {
	[self.portal updateLogEntryForStudy: [[images lastObject] valueForKeyPath: @"series.study"] withMessage: [NSString stringWithFormat: @"DICOM Send to: %@", [dicomNodeDescription objectForKey:@"Address"]] forUser:user.name ip:asyncSocket.connectedHost];
	
	@try {
		NSDictionary* todo = [NSDictionary dictionaryWithObjectsAndKeys: [dicomNodeDescription objectForKey:@"Address"], @"Address", [dicomNodeDescription objectForKey:@"TransferSyntax"], @"TransferSyntax", [dicomNodeDescription objectForKey:@"Port"], @"Port", [dicomNodeDescription objectForKey:@"AETitle"], @"AETitle", [images valueForKey: @"completePath"], @"Files", nil];
		[NSThread detachNewThreadSelector:@selector(sendImagesToDicomNodeThread:) toTarget:self withObject:todo];
	} @catch (NSException* e) {
		NSLog( @"Error: [WebPortalConnection sendImages:toDicomNode:] %@", e);
	}	
}

- (void)sendImagesToDicomNodeThread:(NSDictionary*)todo;
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		[[[[DCMTKStoreSCU alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] 
										  calledAET:[todo objectForKey:@"AETitle"] 
										   hostname:[todo objectForKey:@"Address"] 
											   port:[[todo objectForKey:@"Port"] intValue] 
										filesToSend:[todo valueForKey: @"Files"]
									 transferSyntax:[[todo objectForKey:@"TransferSyntax"] intValue] 
										compression:1.0
									extraParameters:NULL] autorelease] run:self];
	} @catch (NSException* e) {
		NSLog(@"Error: [WebServiceConnection sendImagesToDicomNodeThread:] %@", e);
	} @finally {
		[pool release];
	}
}

-(NSArray*)seriesSortDescriptors
{
	// Sort series with "id" & date
	NSSortDescriptor * sortid = [[[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)] autorelease];
	NSSortDescriptor * sortdate = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	NSArray * sortDescriptors = nil;
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
	else if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
	else sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];

	return sortDescriptors;
}

-(void)getWidth:(CGFloat*)width height:(CGFloat*)height fromImagesArray:(NSArray*)images {
	[self getWidth:width height:height fromImagesArray:images minSize:NSMakeSize(300) maxSize:NSMakeSize(1024)];
}

-(void)getWidth:(CGFloat*)width height:(CGFloat*)height fromImagesArray:(NSArray*)imagesArray minSize:(NSSize)minSize maxSize:(NSSize)maxSize {
	*width = 0;
	*height = 0;
	
	for (NSNumber* im in [imagesArray valueForKey: @"width"])
		if (im.intValue > *width) *width = im.intValue;
	for (NSNumber* im in [imagesArray valueForKey: @"height"])
		if (im.intValue > *height) *height = im.intValue;
	
	if (*width > maxSize.width) {
		*height *= maxSize.width / *width;
		*width = maxSize.width;
	}
	
	if (*height > maxSize.height) {
		*width *= maxSize.height / *height;
		*height = maxSize.height;
	}
	
	if (*width < minSize.width) {
		*height *= minSize.width / *width;
		*width = minSize.width;
	}
	
	if (*height < minSize.height) {
		*width *= minSize.height / *height;
		*height = minSize.height;
	}
}

- (void) movieDCMPixLoad: (NSDictionary*) dict
{
	[dict retain];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	NSArray *dicomImageArray = [dict valueForKey: @"DicomImageArray"];
	
	int location = [[dict valueForKey: @"location"] unsignedIntValue];
	int length = [[dict valueForKey: @"length"] unsignedIntValue];
	int width = [[dict valueForKey: @"width"] floatValue];
	int height = [[dict valueForKey: @"height"] floatValue];
	NSString *outFile = [dict valueForKey: @"outFile"];
	NSString *fileName = [dict valueForKey: @"fileName"];
	
	for( int x = location ; x < location+length; x++)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		DicomImage *im = [dicomImageArray objectAtIndex: x];
		
		@try 
		{
			DCMPix* dcmPix = [[DCMPix alloc] initWithPath:im.completePathResolved :0 :1 :nil :im.frameID.intValue :im.series.id.intValue isBonjour:NO imageObj:im];
			
			if (dcmPix)
			{
				float curWW = 0;
				float curWL = 0;
				
				if (im.series.windowWidth)
				{
					curWW = im.series.windowWidth.floatValue;
					curWL = im.series.windowLevel.floatValue;
				}
				
				if (curWW != 0)
					[dcmPix checkImageAvailble:curWW :curWL];
				else
					[dcmPix checkImageAvailble:[dcmPix savedWW] :[dcmPix savedWL]];
				
				if( x== 0 && [dcmPix cineRate])
					[[NSUserDefaults standardUserDefaults] setInteger: [dcmPix cineRate] forKey: @"quicktimeExportRateValue"];
			}
			else
			{
				NSLog( @"****** dcmPix creation failed for file : %@", [im valueForKey:@"completePathResolved"]);
				
				float *imPtr = (float*)malloc( width * height * sizeof(float));
				for ( int i = 0 ;  i < width * height; i++)
					imPtr[ i] = i;
				
				dcmPix = [[DCMPix alloc] initWithData: imPtr :32 :width :height :0 :0 :0 :0 :0];
			}
			
			NSImage *newImage;
			
			if( ([dcmPix pwidth] != width || [dcmPix pheight] != height) && [dcmPix pheight] > 0 && [dcmPix pwidth] > 0 && width > 0 && height > 0)
				newImage = [[dcmPix image] imageByScalingProportionallyToSize: NSMakeSize( width, height)];
			else
				newImage = [dcmPix image];
			
			if ([outFile hasSuffix:@"swf"])
				[[[NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:NULL] writeToFile:[[fileName stringByAppendingString:@" dir"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%6.6d.jpg", x]] atomically:YES];
			else
				[[newImage TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 1.0] writeToFile: [[fileName stringByAppendingString: @" dir"] stringByAppendingPathComponent: [NSString stringWithFormat: @"%6.6d.tiff", x]] atomically: YES];
			
			[dcmPix release];
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		[pool release];
	}
	
	[pool release];
	
	[dict release];
	
	@synchronized( self)
	{
		DCMPixLoadingThreads--;
	}
}

const NSString* const GenerateMovieOutFileParamKey = @"outFile";
const NSString* const GenerateMovieFileNameParamKey = @"fileName";
const NSString* const GenerateMovieDicomImagesParamKey = @"dicomImageArray";
//const NSString* const GenerateMovieIsIOSParamKey = @"isiPhone";

-(void)generateMovie:(NSMutableDictionary*)dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString* outFile = [dict objectForKey:GenerateMovieOutFileParamKey];
	NSString* fileName = [dict objectForKey:GenerateMovieFileNameParamKey];
	NSArray* dicomImageArray = [dict objectForKey:GenerateMovieDicomImagesParamKey];
	//BOOL isiPhone = [[dict objectForKey:GenerateMovieIsIOSParamKey] boolValue];
	
	NSMutableArray *imagesArray = [NSMutableArray array];
	
	@synchronized(self.portal.locks) {
		if (![self.portal.locks objectForKey:outFile])
			[self.portal.locks setObject:[[[NSRecursiveLock alloc] init] autorelease] forKey:outFile];
	}
		
	[[self.portal.locks objectForKey:outFile] lock];
	
	@try
	{
		if (![[NSFileManager defaultManager] fileExistsAtPath: outFile] || ([[dict objectForKey: @"rows"] intValue] > 0 && [[dict objectForKey: @"columns"] intValue] > 0))
		{
			int noOfThreads = MPProcessors();
			
			NSRange range = NSMakeRange( 0, 1+ ([dicomImageArray count] / noOfThreads));
						
			if( DCMPixLoadingLock == nil)
				DCMPixLoadingLock = [[NSRecursiveLock alloc] init];
			
			[DCMPixLoadingLock lock];
			
			[self.portal.dicomDatabase lock];
			
			NSLog( @"generateMovie: start dcmpix reading");
			
			CGFloat width, height;
			
			if ([[dict objectForKey: @"rows"] intValue] > 0 && [[dict objectForKey: @"columns"] intValue] > 0)
			{
				width = [[dict objectForKey: @"columns"] intValue];
				height = [[dict objectForKey: @"rows"] intValue];
			}
			else
				[self getWidth: &width height:&height fromImagesArray: dicomImageArray /* isiPhone:.. */];
			
			[[NSFileManager defaultManager] removeItemAtPath: [fileName stringByAppendingString: @" dir"] error: nil];
			[[NSFileManager defaultManager] createDirectoryAtPath: [fileName stringByAppendingString: @" dir"] attributes: nil];
			
			[[NSUserDefaults standardUserDefaults] setInteger: 10 forKey: @"quicktimeExportRateValue"];
			
			@try 
			{
				DCMPixLoadingThreads = 0;
				for( int i = 0 ; i < noOfThreads; i++)
				{
					if( range.length > 0)
					{
						@synchronized( self)
						{
							DCMPixLoadingThreads++;
						}
						[NSThread detachNewThreadSelector: @selector( movieDCMPixLoad:)
												 toTarget: self
											   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithUnsignedInt: range.location], @"location",
															[NSNumber numberWithUnsignedInt: range.length], @"length",
															[NSNumber numberWithFloat: width], @"width",
															[NSNumber numberWithFloat: height], @"height",
															outFile, @"outFile",
															fileName, @"fileName",
															dicomImageArray, @"DicomImageArray", nil]];
					}
					
					range.location += range.length;
					if( range.location + range.length > [dicomImageArray count])
						range.length = [dicomImageArray count] - range.location;
				}
				
				while( DCMPixLoadingThreads > 0)
					[NSThread sleepForTimeInterval: 0.1];
			}
			@catch (NSException * e) 
			{
				NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			}
			
			[self.portal.dicomDatabase unlock];
			
			[DCMPixLoadingLock unlock];
						
			NSTask *theTask = [[[NSTask alloc] init] autorelease];
			
			NSLog( @"generateMovie: start writeMovie process");
			
			if (self.requestIsIOS)
			{
				@try
				{
					[theTask setArguments: [NSArray arrayWithObjects: fileName, @"writeMovie", [fileName stringByAppendingString: @" dir"], [[NSUserDefaults standardUserDefaults] stringForKey: @"quicktimeExportRateValue"], nil]];
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
					NSString* type = @"iPhone";
					if (self.requestIsIPad) type = @"iPad";
					if (self.requestIsIPod) type = @"iPod";
					[theTask setArguments: [NSArray arrayWithObjects: outFile, @"writeMovieiPhone", fileName, type, nil]];
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
					[theTask setArguments: [NSArray arrayWithObjects: outFile, @"writeMovie", [outFile stringByAppendingString: @" dir"], [[NSUserDefaults standardUserDefaults] stringForKey: @"quicktimeExportRateValue"], nil]];
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
					[theTask launch];
					
					while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
				}
				@catch (NSException *e)
				{
					NSLog( @"***** writeMovie exception : %@", e);
				}
			}
			
			NSLog( @"generateMovie: end");
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"***** generate movie exception : %@", e);
	}
	
	[[self.portal.locks objectForKey:outFile] unlock];
	
	@synchronized(self.portal.locks) {
		if ([[self.portal.locks objectForKey:outFile] tryLock]) {
			[[self.portal.locks objectForKey: outFile] unlock];
			[self.portal.locks removeObjectForKey: outFile];
		}
	}
	
	[pool release];
}



-(NSData*)produceMovieForSeries:(DicomSeries*)series fileURL:(NSString*)fileURL {
	NSString* path = @"/tmp/osirixwebservices";
	[NSFileManager.defaultManager confirmDirectoryAtPath:path];
	
	NSString* name = [NSString stringWithFormat:@"%@", [parameters objectForKey:@"xid"]];
	name = [name stringByAppendingFormat:@"-NBIM-%ld", series.dateAdded];
	
	NSMutableString* fileName = [NSMutableString stringWithString:name];
	[BrowserController replaceNotAdmitted:fileName];
	fileName = [NSMutableString stringWithString:[path stringByAppendingPathComponent: fileName]];
	[fileName appendFormat:@".%@", fileURL.pathExtension];
	
	NSString *outFile;
	
	if (self.requestIsIOS)
		outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
	else
		outFile = fileName;
	
	NSData* data = [NSData dataWithContentsOfFile: outFile];
	
	if (!data)
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
			
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: /*[NSNumber numberWithBool: isiPhone], @"isiPhone", */fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", parameters, @"parameters", dicomImageArray, @"dicomImageArray", nil];
			
			[self.portal.dicomDatabase unlock];	
			
			[self generateMovie: dict];
			
			[self.portal.dicomDatabase lock];	

			
			data = [NSData dataWithContentsOfFile: outFile];
		}
	}
	
	return data;
}


#pragma mark HTML

-(void)processLoginHtml {
	response.templateString = [self.portal stringForPath:@"login.html"];
}

-(void)processIndexHtml {
	response.templateString = [self.portal stringForPath:@"index.html"];
}

-(void)processMainHtml {
//	if (!user || user.uploadDICOM.boolValue)
//		[self resetPOST];
	
	NSMutableArray* albums = [NSMutableArray array];
	for (NSArray* album in self.portal.dicomDatabase.albums) // TODO: badness here
		if (![[album valueForKey:@"name"] isEqualToString:NSLocalizedString(@"Database", nil)])
			[albums addObject:album];
	[response.tokens setObject:albums forKey:@"Albums"];
	[response.tokens setObject:[self.portal studiesForUser:user predicate:NULL] forKey:@"Studies"];
	
	response.templateString = [self.portal stringForPath:@"main.html"];
}

-(void)processStudyHtml {
	DicomStudy* study = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass: [DicomStudy class]];
	
	if (!study)
		return;
	
	NSMutableArray* selectedSeries = [NSMutableArray array];
	for (NSString* selectedXID in [WebPortalConnection MakeArray:[parameters objectForKey:@"selected"]])
		[selectedSeries addObject:[self objectWithXID:selectedXID ofClass: [DicomSeries class]]];
	
	if ([[parameters objectForKey:@"dicomSend"] isEqual:@"dicomSend"] && study) {
		NSArray* dicomDestinationArray = [[parameters objectForKey:@"dicomDestination"] componentsSeparatedByString:@":"];
		if (dicomDestinationArray.count >= 4) {
			NSMutableDictionary* dicomDestination = [NSMutableDictionary dictionary];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:dicomDestinationArray.count-4] forKey:@"Address"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:dicomDestinationArray.count-3] forKey:@"Port"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:dicomDestinationArray.count-2] forKey:@"AETitle"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:dicomDestinationArray.count-1] forKey:@"TransferSyntax"];
			
			NSMutableArray* selectedImages = [NSMutableArray array];
			for (DicomSeries* s in selectedSeries)
				[selectedImages addObjectsFromArray:s.sortedImages];
			
			if (selectedImages.count) {
				[self sendImages:selectedImages toDicomNode:dicomDestination];
				[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Dicom send to node %@ initiated.", @"Web Portal, study, dicom send, success"), [[dicomDestination objectForKey:@"AETitle"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			} else
				[response.tokens addError: NSLocalizedString(@"Dicom send failed: no images selected. Select one or more series.", @"Web Portal, study, dicom send, error")];
		} else
			[response.tokens addError: NSLocalizedString(@"Dicom send failed: cannot identify node.", @"Web Portal, study, dicom send, error")];
	}
	
	if ([[parameters objectForKey:@"WADOURLsRetrieve"] isEqual:@"WADOURLsRetrieve"] && study && [[NSUserDefaults standardUserDefaults] boolForKey:@"wadoServer"])
	{
		NSMutableArray* selectedImages = [NSMutableArray array];
		for (DicomSeries* s in selectedSeries)
			[selectedImages addObjectsFromArray:s.sortedImages];
		
		if (selectedImages.count)
		{
			NSString *protocol = [[NSUserDefaults standardUserDefaults] boolForKey:@"encryptedWebServer"] ? @"https" : @"http";
			NSString *wadoSubUrl = @"wado"; // See Web Server Preferences
			
			if( [wadoSubUrl hasPrefix: @"/"])
				wadoSubUrl = [wadoSubUrl substringFromIndex: 1];
			
			NSString *baseURL = [NSString stringWithFormat: @"%@/%@?requestType=WADO", self.portalURL, wadoSubUrl];
			
			NSMutableString *WADOURLs = [NSMutableString string];
			
			@try
			{
				for( DicomImage *image in selectedImages)
					[WADOURLs appendString: [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@\r", image.series.study.studyInstanceUID, image.series.seriesDICOMUID, image.sopInstanceUID, @"&useOrig=true"]];
			}
			@catch (NSException * e) {
				NSLog( @"***** exception in WADOURLsRetrieve - %s: %@", __PRETTY_FUNCTION__, e);
			}
			
			response.data = [WADOURLs dataUsingEncoding: NSUTF8StringEncoding];
			[response setMimeType:@"application/dcmURLs"];
			[response.httpHeaders setObject: [NSString stringWithFormat:@"attachment; filename=%@.dcmURLs", [[selectedSeries lastObject] valueForKeyPath: @"study.name"]] forKey: @"Content-Disposition"];
			return;
		}
		else
			[response.tokens addError: NSLocalizedString(@"WADO URL Retrieve failed: no images selected. Select one or more series.", @"Web Portal, study, dicom send, error")];
	}
	
	if ([[parameters objectForKey:@"shareStudy"] isEqual:@"shareStudy"] && study) {
		NSString* shareStudyDestination = [parameters objectForKey:@"shareStudyDestination"];
		WebPortalUser* destUser = NULL;
		
		if ([shareStudyDestination isEqual:@"NEW"])
			@try {
				destUser = [self.portal newUserWithEmail:[parameters objectForKey:@"shareDestinationCreateTempEmail"]];
			} @catch (NSException* e) {
				[self.response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't create temporary user: %@", nil), e.reason]];
			}
		else destUser = [self objectWithXID:shareStudyDestination ofClass: [WebPortalUser class]];
		
		if ([destUser isKindOfClass: [WebPortalUser class]]) {
			// add study to specific study list for this user
			if (![[destUser.studies.allObjects valueForKey:@"study"] containsObject:study]) {
				WebPortalStudy* wpStudy = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:self.portal.database.managedObjectContext];
				wpStudy.user = destUser;
				wpStudy.patientUID = study.patientUID;
				wpStudy.studyInstanceUID = study.studyInstanceUID;
				wpStudy.dateAdded = [NSDate dateWithTimeIntervalSinceReferenceDate:[[NSUserDefaults standardUserDefaults] doubleForKey:@"lastNotificationsDate"]];
				[self.portal.database save:NULL];
			}
			
			// Send the email
			[self.portal sendNotificationsEmailsTo:[NSArray arrayWithObject:destUser] aboutStudies:[NSArray arrayWithObject:study] predicate:NULL replyTo:user.email customText:[parameters objectForKey:@"message"]];
			[self.portal updateLogEntryForStudy: study withMessage: [NSString stringWithFormat: @"Share Study with User: %@", destUser.name] forUser:user.name ip:asyncSocket.connectedHost];
			
			[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"This study is now shared with <b>%@</b>.", @"Web Portal, study, share, ok (%@ is destUser.name)"), destUser.name]];
		} else
			[response.tokens addError: NSLocalizedString(@"Study share failed: cannot identify user.", @"Web Portal, study, share, error")];
	}
	
	[response.tokens setObject:[WebPortalProxy createWithObject:study transformer:DicomStudyTransformer.create] forKey:@"Study"];
	[response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"%@ - %@", @"Web Portal, study, title format (1st %@ is study.name, 2nd is study.studyName)"), study.name, study.studyName] forKey:@"PageTitle"];
	
	[self.portal updateLogEntryForStudy:study withMessage:@"Browsing Study" forUser:user.name ip:asyncSocket.connectedHost];
	
	[self.portal.dicomDatabase.managedObjectContext lock];
	@try {
		NSString* browse = [parameters objectForKey:@"browse"];
		NSString* search = [parameters objectForKey:@"search"];
		NSString* album = [parameters objectForKey:@"album"];
		NSString* studyListLinkLabel = NSLocalizedString(@"Study list", nil);
		if (search.length)
			studyListLinkLabel = [NSString stringWithFormat:NSLocalizedString(@"Search results for: %@", nil), search];
		else if (album.length)
			studyListLinkLabel = [NSString stringWithFormat:NSLocalizedString(@"Album: %@", nil), album];
		else if ([browse isEqualToString:@"6hours"])
			studyListLinkLabel = NSLocalizedString(@"Last 6 Hours", nil);
		else if ([browse isEqualToString:@"today"])
			studyListLinkLabel = NSLocalizedString(@"Today", nil);
		[response.tokens setObject:studyListLinkLabel forKey:@"BackLinkLabel"];
		
		// Series
		
		NSMutableArray* seriesArray = [NSMutableArray array];
		for (DicomSeries* s in [study.imageSeries sortedArrayUsingDescriptors:[self seriesSortDescriptors]])
			[seriesArray addObject:[WebPortalProxy createWithObject:s transformer:[DicomSeriesTransformer create]]];
		[response.tokens setObject:seriesArray forKey:@"Series"];
			
		// DICOM destinations

		NSMutableArray* dicomDestinations = [NSMutableArray array];
		if (!user || user.sendDICOMtoSelfIP.boolValue) {
				[dicomDestinations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											  [asyncSocket connectedHost], @"address",
											  self.dicomCStorePortString, @"port",
											  @"This Computer", @"aeTitle",
											  @"1", @"syntax", // 1 == JPEG2000 Lossless
											  self.requestIsIOS? @"This Device" : [NSString stringWithFormat:@"This Computer [%@:%@]", [asyncSocket connectedHost], self.dicomCStorePortString], @"description",
											  NULL]];
			if (!user || user.sendDICOMtoAnyNodes.boolValue)
				for (NSDictionary* node in [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO])
					[dicomDestinations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												  [node objectForKey:@"Address"], @"address",
												  [node objectForKey:@"Port"], @"port",
												  [node objectForKey:@"AETitle"], @"aeTitle",
												  [node objectForKey:@"TransferSyntax"], @"syntax",
												  self.requestIsIOS? [node objectForKey:@"Description"] : [NSString stringWithFormat:@"%@ [%@:%@]", [node objectForKey:@"Description"], [node objectForKey:@"Address"], [node objectForKey:@"Port"]], @"description",
												  NULL]];
		}
		[response.tokens setObject:dicomDestinations forKey:@"DicomDestinations"];
		
		// Share
		
		NSMutableArray* shareDestinations = [NSMutableArray array];
		if (!user || user.shareStudyWithUser.boolValue) {
			NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
			req.entity = [self.portal.database entityForName:@"User"];
			req.predicate = [NSPredicate predicateWithValue:YES];
			NSArray* users = [[self.portal.database.managedObjectContext executeFetchRequest:req error:NULL] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
			
			for (WebPortalUser* u in users)
				if (u != self.user)
					[shareDestinations addObject:[WebPortalProxy createWithObject:u transformer:[WebPortalUserTransformer create]]];
		}
		[response.tokens setObject:shareDestinations forKey:@"ShareDestinations"];

	} @catch (NSException* e) {
		NSLog(@"Error: [WebPortalResponse processStudyHtml:] %@", e);
	} @finally {
		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
		
	response.templateString = [self.portal stringForPath:@"study.html"];
}

-(void)processStudyListHtml {
	NSString* title = NULL;
	[response.tokens setObject:[self studyList_requestedStudies:&title] forKey:@"Studies"];	
	if (title) [response.tokens setObject:title forKey:@"PageTitle"];
	response.templateString = [self.portal stringForPath:@"studyList.html"];
}

-(void)processSeriesHtml {
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass: [DicomSeries class]];
	if (!series) 
		return;
	
	[response.tokens setObject:[WebPortalProxy createWithObject:series transformer:[DicomSeriesTransformer create]] forKey:@"Series"];
	[response.tokens setObject:series.name forKey:@"PageTitle"];
	[response.tokens setObject:[NSString stringWithFormat:@"%@ - %@", series.study.name, series.study.studyName] forKey:@"BackLinkLabel"];
	
	response.templateString = [self.portal stringForPath:@"series.html"];
}


-(void)processPasswordForgottenHtml {
	if (!self.portal.passwordRestoreAllowed)
		return;
	
	if ([[parameters valueForKey:@"action"] isEqualToString:@"restorePassword"])
	{
		NSString* email = [parameters valueForKey: @"email"];
		NSString* username = [parameters valueForKey: @"username"];
		
		// TRY TO FIND THIS USER
		if ([email length] > 0 || [username length] > 0) {
			[self.portal.database.managedObjectContext lock];
			
			@try
			{
				NSError *error = nil;
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:self.portal.database.managedObjectContext]];
				
				if ([email length] > [username length])
					[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(email BEGINSWITH[cd] %@) AND (email ENDSWITH[cd] %@)", email, email]];
				else [dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(name BEGINSWITH[cd] %@) AND (name ENDSWITH[cd] %@)", username, username]];
				
				NSArray *users = [self.portal.database.managedObjectContext executeFetchRequest: dbRequest error:NULL];
				
				if ([users count] >= 1)
				{
					for (WebPortalUser *u in users)
					{
						NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
						
						if (fromEmailAddress == nil)
							fromEmailAddress = @"";
						
						NSString *emailSubject = NSLocalizedString( @"Your password has been reset.", nil);
						NSMutableString *emailMessage = [NSMutableString stringWithString: @""];
						
						[u generatePassword];
						
						[emailMessage appendString: NSLocalizedString( @"Username:\r\r", nil)];
						[emailMessage appendString: u.name];
						[emailMessage appendString: @"\r\r"];
						[emailMessage appendString: NSLocalizedString( @"Password:\r\r", nil)];
						[emailMessage appendString: u.password];
						[emailMessage appendString: @"\r\r"];
						
						[self.portal updateLogEntryForStudy: nil withMessage: @"Password reset for user" forUser:u.name ip: nil];
						
						[[CSMailMailClient mailClient] deliverMessage: [[[NSAttributedString alloc] initWithString: emailMessage] autorelease] headers: [NSDictionary dictionaryWithObjectsAndKeys: u.email, @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", nil]];
						
						[response.tokens addMessage:NSLocalizedString(@"You will shortly receive an email with your new password.", nil)];
						
						[self.portal.database save:NULL];
					}
				}
				else
				{
					// To avoid someone scanning for the username
					[NSThread sleepForTimeInterval:3];
					
					[self.portal updateLogEntryForStudy: nil withMessage: @"Unknown user" forUser: [NSString stringWithFormat: @"%@ %@", username, email] ip: nil];
					
					[response.tokens addError:NSLocalizedString(@"This username doesn't exist in our database.", nil)];
				}
			}
			@catch (NSException* e) {
				NSLog( @"******* password_forgotten: %@", e);
			}
			@finally {
				[self.portal.database.managedObjectContext unlock];
			}
		}
	}
	
	[response.tokens setObject:NSLocalizedString(@"Forgotten Password", @"Web portal, password forgotten, title") forKey:@"PageTitle"];
	response.templateString = [self.portal stringForPath:@"password_forgotten.html"];
}


-(void)processAccountHtml {
	if (!self.user)
		return;
	
	if ([[parameters valueForKey:@"action"] isEqualToString:@"changePassword"]) {
		NSString * previouspassword = [parameters valueForKey: @"previouspassword"];
		NSString * password = [parameters valueForKey: @"password"];
		
		if ([previouspassword isEqualToString:user.password]) {
			if ([[parameters valueForKey:@"password"] isEqualToString:[parameters valueForKey:@"password2"]])
			{
				NSError* err = NULL;
				if (![user validatePassword:&password error:&err])
					[response.tokens addError:err.localizedDescription];
				else {
					// We can update the user password
					
//					if( [previouspassword isEqualToString: @"public"] && [self.user.name isEqualToString:@"public"])
//					{
//						// public / public demo account not editable
//						[response.tokens addMessage:NSLocalizedString(@"Public account not editable!", nil)];
//					}
//					else
					{
						user.password = password;
						[self.portal.database save:NULL];
						[response.tokens addMessage:NSLocalizedString(@"Password updated successfully!", nil)];
						[self.portal updateLogEntryForStudy: nil withMessage: [NSString stringWithFormat: @"User changed his password"] forUser:self.user.name ip:asyncSocket.connectedHost];
					}
				}
			}
			else
				[response.tokens addError:NSLocalizedString(@"The new password wasn't repeated correctly.", nil)];
		}
		else
			[response.tokens addError:NSLocalizedString(@"Wrong current password.", nil)];
	}
	
	if ([[parameters valueForKey:@"action"] isEqualToString:@"changeSettings"]) {
		user.email = [parameters valueForKey:@"email"];
		user.address = [parameters valueForKey:@"address"];
		user.phone = [parameters valueForKey:@"phone"];
		
		if ([[[parameters valueForKey:@"emailNotification"] lowercaseString] isEqualToString:@"on"])
			user.emailNotification = [NSNumber numberWithBool:YES];
		else user.emailNotification = [NSNumber numberWithBool: NO];
		
		[self.portal.database save:NULL];
		
		[response.tokens addMessage:NSLocalizedString(@"Personal information updated successfully!", nil)];
	}
	
	[response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"Account information for: %@", @"Web portal, account, title format (%@ is user.name)"), user.name] forKey:@"PageTitle"];
	response.templateString = [self.portal stringForPath:@"account.html"];
}



#pragma mark Administration HTML

-(void)processAdminIndexHtml {
	if (!user.isAdmin) {
		response.statusCode = 401;
		[self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to access admin area without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
		return;
	}
	
	[response.tokens setObject:NSLocalizedString(@"Administration", @"Web Portal, admin, index, title") forKey:@"PageTitle"];
	
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [self.portal.database entityForName:@"User"];
	req.predicate = [NSPredicate predicateWithValue:YES];
	[response.tokens setObject:[[self.portal.database.managedObjectContext executeFetchRequest:req error:NULL] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]] forKey:@"Users"];
	
	response.templateString = [self.portal stringForPath:@"admin/index.html"];
}

-(void)processAdminUserHtml {
	if (!user.isAdmin) {
		response.statusCode = 401;
		[self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to access admin area without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
		return;
	}

	NSObject* luser = NULL;
	BOOL userRecycleParams = NO;
	NSString* action = [parameters objectForKey:@"action"];
	NSString* originalName = NULL;
	
	if ([action isEqual:@"delete"]) {
		originalName = [parameters objectForKey:@"originalName"];
		NSManagedObject* tempUser = [self.portal.database userWithName:originalName];
		if (!tempUser)
			[response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't delete user <b>%@</b> because he doesn't exist.", @"Web Portal, admin, user edition, delete error (%@ is user.name)"), originalName]];
		else {
			[self.portal.database.managedObjectContext deleteObject:tempUser];
			[tempUser.managedObjectContext save:NULL];
			[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"User <b>%@</b> successfully deleted.", @"Web Portal, admin, user edition, delete ok (%@ is user.name)"), originalName]];
		}
	}
	
	if ([action isEqual:@"save"]) {
		originalName = [parameters objectForKey:@"originalName"];
		WebPortalUser* webUser = [self.portal.database userWithName:originalName];
		if (!webUser) {
			[response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't save changes for user <b>%@</b> because he doesn't exist.", @"Web Portal, admin, user edition, save error (%@ is user.name)"), originalName]];
			userRecycleParams = YES;
		} else {
			// NSLog(@"SAVE params: %@", parameters.description);
			
			NSString* name = [parameters objectForKey:@"name"];
			NSString* password = [parameters objectForKey:@"password"];
			NSString* studyPredicate = [parameters objectForKey:@"studyPredicate"];
			NSNumber* downloadZIP = [NSNumber numberWithBool:[[parameters objectForKey:@"downloadZIP"] isEqual:@"on"]];
			
			NSError* err;
			
			err = NULL;
			if (![webUser validateName:&name error:&err])
				[response.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validatePassword:&password error:&err])
				[response.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateStudyPredicate:&studyPredicate error:&err])
				[response.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateDownloadZIP:&downloadZIP error:&err])
				[response.tokens addError:err.localizedDescription];
			
			if (!response.tokens.errors.count) {
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
				webUser.canAccessPatientsOtherStudies = [NSNumber numberWithBool:[[parameters objectForKey:@"canAccessPatientsOtherStudies"] isEqual:@"on"]];
				webUser.canSeeAlbums = [NSNumber numberWithBool:[[parameters objectForKey:@"canSeeAlbums"] isEqual:@"on"]];
				
				if (webUser.autoDelete.boolValue)
					webUser.deletionDate = [NSCalendarDate dateWithYear:[[parameters objectForKey:@"deletionDate_year"] integerValue] month:[[parameters objectForKey:@"deletionDate_month"] integerValue]+1 day:[[parameters objectForKey:@"deletionDate_day"] integerValue] hour:0 minute:0 second:0 timeZone:NULL];
				
				NSMutableArray* remainingStudies = [NSMutableArray array];
				for (NSString* studyXid in [[self.parameters objectForKey:@"remainingStudies"] componentsSeparatedByString:@","]) {
					studyXid = [studyXid.stringByTrimmingStartAndEnd stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					WebPortalStudy* wpStudy = NULL;
					// this is Mac OS X 10.6 SnowLeopard only // wpStudy = [webUser.managedObjectContext existingObjectWithID:[webUser.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:studyObjectID]] error:NULL];
					for (WebPortalStudy* iwpStudy in webUser.studies)
						if ([iwpStudy.XID isEqual:studyXid]) {
							wpStudy = iwpStudy;
							break;
						}
					
					if (wpStudy) [remainingStudies addObject:wpStudy];
					else NSLog(@"Warning: Web Portal user %@ is referencing a study with CoreData ID %@, which doesn't exist", self.user.name, studyXid);
				}
				for (WebPortalStudy* iwpStudy in webUser.studies.allObjects)
					if (![remainingStudies containsObject:iwpStudy])
						[webUser removeStudiesObject:iwpStudy];
				
				[webUser.managedObjectContext save:NULL];
				
				[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Changes for user <b>%@</b> successfully saved.", @"Web Portal, admin, user edition, save ok (%@ is user.name)"), webUser.name]];
				luser = webUser;
			} else
				userRecycleParams = YES;
		}
	}
	
	if ([action isEqual:@"new"]) {
		luser = [self.portal.database newUser];
	}
	
	if (!action) { // edit
		originalName = [self.parameters objectForKey:@"name"];
		luser = [self.portal.database userWithName:originalName];
		if (!luser)
			[response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't find user with name <b>%@</b>.", @"Web Portal, admin, user edition, edit error (%@ is user.name)"), originalName]];
	}
	
	[response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"User Administration: %@", @"Web Portal, admin, user edition, title (%@ is user.name)"), luser? [luser valueForKey:@"name"] : originalName] forKey:@"PageTitle"];
	if (luser)
		[response.tokens setObject:[WebPortalProxy createWithObject:luser transformer:[WebPortalUserTransformer create]] forKey:@"EditedUser"];
	else if (userRecycleParams) [response.tokens setObject:self.parameters forKey:@"EditedUser"];
	
	response.templateString = [self.portal stringForPath:@"admin/user.html"];
}

#pragma mark JSON

-(void)processStudyListJson {
	NSArray* studies = [self studyList_requestedStudies:NULL];
	
	[self.portal.dicomDatabase.managedObjectContext lock];
	@try {
		NSMutableArray* r = [NSMutableArray array];
		for (DicomStudy* study in studies) {
			NSMutableDictionary* s = [NSMutableDictionary dictionary];
			
			[s setObject:N2NonNullString(study.name) forKey:@"name"];
			[s setObject:[[NSNumber numberWithInt:study.series.count] stringValue] forKey:@"seriesCount"];
			[s setObject:[NSUserDefaults.dateTimeFormatter stringFromDate:study.date] forKey:@"date"];
			[s setObject:N2NonNullString(study.studyName) forKey:@"studyName"];
			[s setObject:N2NonNullString(study.modality) forKey:@"modality"];
			
			NSString* stateText = (NSString*)study.stateText;
			if (stateText.intValue)
				stateText = [BrowserController.statesArray objectAtIndex:stateText.intValue];
			[s setObject:N2NonNullString(stateText) forKey:@"stateText"];

			[s setObject:N2NonNullString(study.studyInstanceUID) forKey:@"studyInstanceUID"];

			[r addObject:s];
		}
		
		[response setDataWithString:[r JSONRepresentation]];
	} @catch (NSException* e) {
		NSLog(@"Error: [WebPortalResponse processStudyListJson:] %@", e);
	} @finally {
		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
}

-(void)processSeriesJson {
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass:[DicomSeries class]];
	if (!series)
		return;

	NSArray* imagesArray = series.images.allObjects;
	@try { // Sort images with "instanceNumber"
		NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
		NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
		[sort release];
		imagesArray = [imagesArray sortedArrayUsingDescriptors: sortDescriptors];
	} @catch (NSException* e) { /* ignore */ }
	
	
	[self.portal.dicomDatabase.managedObjectContext lock];
	@try {
		NSMutableArray* jsonImagesArray = [NSMutableArray array];
		for (DicomImage* image in imagesArray)
			if (image.sopInstanceUID)
				[jsonImagesArray addObject:image.sopInstanceUID];
		[response setDataWithString:[jsonImagesArray JSONRepresentation]];
	}
	@catch (NSException *e) {
		NSLog( @"***** jsonImageListForImages exception: %@", e);
	} @finally {
		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
}

-(void)processAlbumsJson {
	NSMutableArray* jsonAlbumsArray = [NSMutableArray array];
	
	for (DicomAlbum* album in [self.portal.dicomDatabase albums])
		if (![album.name isEqualToString:NSLocalizedString(@"Database", nil)]) {
			NSMutableDictionary* albumDictionary = [NSMutableDictionary dictionary];
			
			[albumDictionary setObject:N2NonNullString(album.name) forKey:@"name"];
			[albumDictionary setObject:N2NonNullString([album.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]) forKey:@"nameURLSafe"];
			
			if (album.smartAlbum.intValue == 1)
				[albumDictionary setObject:@"SmartAlbum" forKey:@"type"];
			else [albumDictionary setObject:@"Album" forKey:@"type"];
			
			[jsonAlbumsArray addObject:albumDictionary];
		}
	
	[response setDataWithString:[jsonAlbumsArray JSONRepresentation]];
}

-(void)processSeriesListJson {
	DicomStudy* study = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass: [DicomStudy class]];
	if (!study)
		return;
	
	NSMutableArray *jsonSeriesArray = [NSMutableArray array];
	
	[self.portal.dicomDatabase.managedObjectContext lock];
	@try {
		for (DicomSeries* s in [study imageSeries]) {
			NSMutableDictionary* seriesDictionary = [NSMutableDictionary dictionary];
			
			[seriesDictionary setObject:s.seriesInstanceUID forKey:@"seriesInstanceUID"];
			[seriesDictionary setObject:s.seriesDICOMUID forKey:@"seriesDICOMUID"];
			
			NSArray* dicomImageArray = s.images.allObjects;
			DicomImage* im = dicomImageArray.count == 1 ? [dicomImageArray lastObject] : [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
			
			[seriesDictionary setObject:im.sopInstanceUID forKey:@"keyInstanceUID"];
			
			[jsonSeriesArray addObject:seriesDictionary];
		}
	} @catch (NSException *e) {
		NSLog( @"******* jsonSeriesListForSeries exception: %@", e);
	} @finally {
		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
	
	[response setDataWithString:[jsonSeriesArray JSONRepresentation]];
}


#pragma mark WADO

#define WadoCacheSize 2000

-(NSMutableDictionary*)wadoCache {
	const NSString* const WadoCacheKey = @"WADO Cache";
	NSMutableDictionary* dict = [self.portal.cache objectForKey:WadoCacheKey];
	if (!dict || ![dict isKindOfClass: [NSMutableDictionary class]])
		[self.portal.cache setObject: dict = [NSMutableDictionary dictionaryWithCapacity:WadoCacheSize] forKey:WadoCacheKey];
	return dict;
}

#define WadoSOPInstanceUIDCacheSize 5000

-(NSMutableDictionary*)wadoSOPInstanceUIDCache {
	const NSString* const WadoSOPInstanceUIDCacheKey = @"WADO SOPInstanceUID Cache";
	NSMutableDictionary* dict = [self.portal.cache objectForKey:WadoSOPInstanceUIDCacheKey];
	if (!dict || ![dict isKindOfClass:[NSMutableDictionary class]])
		[self.portal.cache setObject: dict = [NSMutableDictionary dictionaryWithCapacity:WadoSOPInstanceUIDCacheSize] forKey:WadoSOPInstanceUIDCacheKey];
	return dict;
}

// wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX
// 127.0.0.1:3333/wado?requestType=WADO&frameNumber=1&studyUID=2.16.840.1.113669.632.20.1211.10000591592&seriesUID=1.3.6.1.4.1.19291.2.1.2.2867252960399100001&objectUID=1.3.6.1.4.1.19291.2.1.3.2867252960616100004
-(void)processWado {
	if (!self.portal.wadoEnabled) {
		self.response.statusCode = 403;
		[self.response setDataWithString:NSLocalizedString(@"OsiriX cannot fulfill your request because the WADO service is disabled.", NULL)];
		return;
	}
	
	if (![[[parameters objectForKey:@"requestType"] lowercaseString] isEqual:@"wado"]) {
		self.response.statusCode = 404;
		return;
	}
	
	NSString* studyUID = [parameters objectForKey:@"studyUID"];
	NSString* seriesUID = [parameters objectForKey:@"seriesUID"];
	NSString* objectUID = [parameters objectForKey:@"objectUID"];
	
	if (objectUID == nil && (seriesUID.length > 0 || studyUID.length > 0)) // This is a 'special case', not officially supported by DICOM standard : we take all the series or study objects -> zip them -> send them
	{
		NSFetchRequest* dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		dbRequest.entity = [self.portal.dicomDatabase entityForName:@"Study"];
		
		if (studyUID)
			[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
		else
			[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		
		NSArray *studies = [self.portal.dicomDatabase.managedObjectContext executeFetchRequest:dbRequest error:NULL];
		
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
		
		if( allImages.count > 0)
		{
			// Zip them
			
			NSString *srcFolder = @"/tmp";
			NSString *destFile = @"/tmp";
			
			srcFolder = [srcFolder stringByAppendingPathComponent: [[[allImages lastObject] valueForKeyPath:@"series.study.name"] filenameString]];
			destFile = [destFile stringByAppendingPathComponent: [[[allImages lastObject] valueForKeyPath:@"series.study.name"] filenameString]];
			destFile = [destFile stringByAppendingPathExtension:@"osirixzip"];
			
			if (srcFolder)
				[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
			if (destFile)
				[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
			
			[NSFileManager.defaultManager confirmDirectoryAtPath:srcFolder];
			
			[self.portal.dicomDatabase.managedObjectContext unlock];
			[BrowserController encryptFiles: [allImages valueForKey:@"completePath"] inZIPFile:destFile password: user.encryptedZIP.boolValue? user.password : NULL ];
			[self.portal.dicomDatabase.managedObjectContext lock];

			self.response.data = [NSData dataWithContentsOfFile:destFile];
			self.response.statusCode = 0;
			[self.response setMimeType: @"application/osirixzip"];
			
			if (srcFolder)
				[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
			if (destFile)
				[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
				
			return;
		}
	}
	
	NSString* contentType = [[[[parameters objectForKey:@"contentType"] lowercaseString] componentsSeparatedByString: @","] objectAtIndex: 0];
	int rows = [[parameters objectForKey:@"rows"] intValue];
	int columns = [[parameters objectForKey:@"columns"] intValue];
	int windowCenter = [[parameters objectForKey:@"windowCenter"] intValue];
	int windowWidth = [[parameters objectForKey:@"windowWidth"] intValue];
	int frameNumber = [[parameters objectForKey:@"frameNumber"] intValue];	// -> OsiriX stores frames as images
	int imageQuality = DCMLosslessQuality;
	
	NSString* imageQualityParam = [parameters objectForKey:@"imageQuality"];
	if (imageQualityParam) {
		int imageQualityParamInt = imageQualityParam.intValue;
		if (imageQualityParamInt > 80)
			imageQuality = DCMLosslessQuality;
		else if (imageQualityParamInt > 60)
			imageQuality = DCMHighQuality;
		else if (imageQualityParamInt > 30)
			imageQuality = DCMMediumQuality;
		else if (imageQualityParamInt >= 0)
			imageQuality = DCMLowQuality;
	}
	
	NSString* transferSyntax = [[parameters objectForKey:@"transferSyntax"] lowercaseString];
	NSString* useOrig = [[parameters objectForKey:@"useOrig"] lowercaseString];
	
	NSFetchRequest* dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	dbRequest.entity = [self.portal.dicomDatabase entityForName:@"Study"];
	
	@try {
		NSMutableDictionary *imageCache = nil;
		NSArray *images = nil;
		
		if (self.wadoCache.count > WadoCacheSize)
			[self.wadoCache removeAllObjects];
		
		if( self.wadoSOPInstanceUIDCache.count > WadoSOPInstanceUIDCacheSize)
			[self.wadoSOPInstanceUIDCache removeAllObjects];
		
		NSString *cachedPathForSOPInstanceUID = nil;
		
		if (contentType.length == 0 || [contentType isEqualToString:@"image/jpeg"] || [contentType isEqualToString:@"image/png"] || [contentType isEqualToString:@"image/gif"] || [contentType isEqualToString:@"image/jp2"])
			imageCache = [self.wadoCache objectForKey:[objectUID stringByAppendingFormat:@"%d", frameNumber]];
		
		else if( [contentType isEqualToString: @"application/dicom"])
			cachedPathForSOPInstanceUID = [self.wadoSOPInstanceUIDCache objectForKey: objectUID];
		
		if (!imageCache && !cachedPathForSOPInstanceUID)
		{
			if (studyUID)
				[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
			else
				[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
			
			NSArray *studies = [self.portal.dicomDatabase.managedObjectContext executeFetchRequest:dbRequest error:NULL];
			
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
			
			//We will cache all the paths for these sopInstanceUIDs
			for( DicomImage *image in allImages)
				[self.wadoSOPInstanceUIDCache setObject: image.completePath forKey: image.sopInstanceUID];
			
			NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: objectUID]] customSelector: @selector( isEqualToSopInstanceUID:)];
			NSPredicate *N2NonNullStringPredicate = [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"];
			
			images = [[allImages filteredArrayUsingPredicate: N2NonNullStringPredicate] filteredArrayUsingPredicate: predicate];
			
			if ([images count] > 1)
			{
				images = [images sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"instanceNumber" ascending:YES] autorelease]]];
				
				if (frameNumber < [images count])
					images = [NSArray arrayWithObject: [images objectAtIndex: frameNumber]];
			}
			
			if ([images count])
			{
				[self.portal updateLogEntryForStudy: [studies lastObject] withMessage:@"WADO Send" forUser:self.user.name ip:self.asyncSocket.connectedHost];
			}
			
			cachedPathForSOPInstanceUID = [[images lastObject] valueForKey: @"completePath"];
		}
		
		if ([images count] || imageCache != nil || cachedPathForSOPInstanceUID != nil)
		{
			if ([contentType isEqualToString: @"application/dicom"])
			{
				if ([useOrig isEqualToString: @"true"] || [useOrig isEqualToString: @"1"] || [useOrig isEqualToString: @"yes"] || transferSyntax == nil)
				{
					response.data = [NSData dataWithContentsOfFile: cachedPathForSOPInstanceUID];
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
					
					#ifdef OSIRIX_LIGHT
					response.data = [NSData dataWithContentsOfFile: cachedPathForSOPInstanceUID];
					#else
					response.data = [[BrowserController currentBrowser] getDICOMFile:cachedPathForSOPInstanceUID inSyntax: ts.transferSyntax quality: imageQuality];
					#endif
				}
				//err = NO;
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
					
					NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"xid"]];
					name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
					
					NSMutableString *fileName = [NSMutableString stringWithString: [path stringByAppendingPathComponent:name]];
					
					[BrowserController replaceNotAdmitted: fileName];
					
					[fileName appendString:@".mov"];
					
					NSString *outFile;
					if (self.requestIsIOS)
						outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
					else
						outFile = fileName;
					
					NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: /*[NSNumber numberWithBool: self.requestIsIOS], GenerateMovieIsIOSParamKey,*/ /*fileURL, @"fileURL",*/ fileName, GenerateMovieFileNameParamKey, outFile, GenerateMovieOutFileParamKey, parameters, @"parameters", dicomImageArray, GenerateMovieDicomImagesParamKey, [NSNumber numberWithInt: rows], @"rows", [NSNumber numberWithInt: columns], @"columns", nil];
					
					[self.portal.dicomDatabase.managedObjectContext unlock];
					[self generateMovie:dict];
					[self.portal.dicomDatabase.managedObjectContext lock];
					
					self.response.data = [NSData dataWithContentsOfFile:outFile];
					
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
					
					[self.wadoCache setObject: imageCache forKey: [objectUID stringByAppendingFormat: @"%d", frameNumber]];
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
					
					self.response.data = [imageCache objectForKey: [NSString stringWithFormat: @"%@ %f %f %d %d %d", contentType, curWW, curWL, columns, rows, frameNumber]];
					
					if (!self.response.data.length)
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
							self.response.data = [imageRep representationUsingType: NSGIFFileType properties:imageProps];
						else if ([contentType isEqualToString: @"image/png"])
							self.response.data = [imageRep representationUsingType: NSPNGFileType properties:imageProps];
						else if ([contentType isEqualToString: @"image/jp2"])
							self.response.data = [imageRep representationUsingType: NSJPEG2000FileType properties:imageProps];
						else
							self.response.data = [imageRep representationUsingType: NSJPEGFileType properties:imageProps];
						
						[imageCache setObject:self.response.data forKey: [NSString stringWithFormat: @"%@ %f %f %d %d %d", contentType, curWW, curWL, columns, rows, frameNumber]];
					}
					
					if( contentType)
						[self.response setMimeType: contentType];
					
					// Alessandro: I'm not sure here, from Joris' code it seems WADO must always return HTTP 200, eventually with length 0..
					NSData *noData = self.response.data;
                    self.response.statusCode = 0;
				}
			}
		}
		else
			NSLog( @"****** WADO Server : image uid not found !");
		
		if (!self.response.data)
			self.response.data = [NSData data];

	} @catch (NSException * e) {
		NSLog(@"Error: [WebPortalResponse processWado:] %@", e);
		self.response.statusCode = 500;
	}
}

#pragma mark Weasis

-(void)processWeasisJnlp {
	if (!self.portal.weasisEnabled) {
		response.statusCode = 404;
		return;
	}
	
	[response.tokens setObject:self.portalURL forKey:@"WebServerAddress"];
	
	response.templateString = [self.portal stringForPath:@"weasis.jnlp"];
	response.mimeType = @"application/x-java-jnlp-file";
}

-(void)processWeasisXml {
	if (!self.portal.weasisEnabled) {
		response.statusCode = 404;
		return;
	}
	
	// find requosted core data objects

	NSMutableArray* requestedStudies = [NSMutableArray arrayWithCapacity:8];
	NSMutableArray* requestedSeries = [NSMutableArray arrayWithCapacity:64];
	
	NSString* xid = [parameters objectForKey:@"xid"];
	NSArray* selection = xid? [NSArray arrayWithObject:xid] : [WebPortalConnection MakeArray:[parameters objectForKey:@"selected"]];
	for (xid in selection) {
		NSManagedObject* oxid = [self objectWithXID:xid ofClass:NULL];
		if ([oxid isKindOfClass:[DicomStudy class]])
			[requestedStudies addObject:oxid];
		if ([oxid isKindOfClass:[DicomSeries class]])
			[requestedSeries addObject:oxid];
	}
	
	// extend arrays
	
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
	if (self.user) {
		studies = (NSMutableArray*) [self.portal studiesForUser:self.user predicate:[NSPredicate predicateWithValue:YES] sortBy:nil];// is not mutable, but we won't mutate it anymore
	}
	
	// produce XML
	NSString* baseXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><wado_query wadoURL=\"%@/wado\"></wado_query>", self.portalURL];
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:baseXML options:NSXMLDocumentIncludeContentTypeDeclaration|NSXMLDocumentTidyXML error:NULL];
	[doc setCharacterEncoding:@"UTF-8"];
	
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	dateFormatter.dateFormat = @"dd-MM-yyyy";
	NSDateFormatter* timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	timeFormatter.dateFormat = @"HH:mm:ss";	
	
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
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyDate" stringValue:[dateFormatter stringFromDate:study.date]]];
				[studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyTime" stringValue:[timeFormatter stringFromDate:study.date]]];
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
					[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientBirthDate" stringValue:[dateFormatter stringFromDate:study.dateOfBirth]]];
					[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientSex" stringValue:study.patientSex]];
				}
			}
	}
	
	[response setDataWithString:[[doc autorelease] XMLString]];
	response.mimeType = @"text/xml";	
}

#pragma mark Other

-(void)processReport {
	DicomStudy* study = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass:[DicomStudy class]];
	if (!study)
		return;
	
	[self.portal updateLogEntryForStudy:study withMessage: @"Download Report" forUser:user.name ip:asyncSocket.connectedHost];
	
	NSString *reportFilePath = study.reportURL;
	
	NSString *reportType = [reportFilePath pathExtension];
	
	if ([reportType isEqualToString: @"pages"])
	{
		NSString* zipFileName = [NSString stringWithFormat:@"%@.zip", [reportFilePath lastPathComponent]];
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
			reportFilePath = [[reportFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:zipFileName];
		
		response.data = [NSData dataWithContentsOfFile: reportFilePath];
		
		[[NSFileManager defaultManager] removeFileAtPath:reportFilePath handler:nil];
	}
	else
	{
		response.data = [NSData dataWithContentsOfFile: reportFilePath];
	}
}

#define ThumbnailsCacheSize 20

-(NSMutableDictionary*)thumbnailsCache {
	const NSString* const ThumbsCacheKey = @"Thumbnails Cache";
	NSMutableDictionary* dict = [self.portal.cache objectForKey:ThumbsCacheKey];
	if (!dict || ![dict isKindOfClass:[NSMutableDictionary class]])
		[self.portal.cache setObject: dict = [NSMutableDictionary dictionaryWithCapacity:ThumbnailsCacheSize] forKey:ThumbsCacheKey];
	return dict;
}

-(void)processThumbnail {
	NSString* xid = [parameters objectForKey:@"xid"];
	
	// is cached?
	NSData* data = [self.thumbnailsCache objectForKey:xid];
	if (data) {
		response.data = data;
		return;
	}
	
	// create it
	
	id object = [self objectWithXID:xid ofClass:Nil];
	if (!object)
		return;
	
	if ([object isKindOfClass:[DicomSeries class]]) {
		NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[object thumbnail]];
		NSDictionary* imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
		response.data = data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
	} else if ([object isKindOfClass: [DicomImage class]]) {
		NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[[(DicomImage*)object thumbnail] JPEGRepresentationWithQuality:0.3]];
		NSDictionary* imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
		response.data = data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
	}
	
	if (data)
		[self.thumbnailsCache setObject:data forKey:xid];
}

-(void)processSeriesPdf {
	#ifndef OSIRIX_LIGHT
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass:[DicomSeries class]];
	if (!series)
		return;
	
	if ([DCMAbstractSyntaxUID isPDF:series.seriesSOPClassUID]) {
		DCMObject* dcmObject = [DCMObject objectWithContentsOfFile:[series.images.anyObject valueForKey:@"completePath"] decodingPixelData:NO];
		if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
			response.data = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
	}
	
	if ([DCMAbstractSyntaxUID isStructuredReport:series.seriesSOPClassUID]) {
		NSString* path = [NSFileManager.defaultManager confirmDirectoryAtPath:@"/tmp/dicomsr_osirix"];
		NSString* htmlpath = [path stringByAppendingPathComponent:[[[series.images.anyObject valueForKey:@"completePath"] lastPathComponent] stringByAppendingPathExtension:@"xml"]];
		
		if (![NSFileManager.defaultManager fileExistsAtPath:htmlpath]) {
			NSTask* aTask = [[[NSTask alloc] init] autorelease];
			[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dicom.dic"] forKey:@"DCMDICTPATH"]];
			[aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dsr2html"]];
			[aTask setArguments:[NSArray arrayWithObjects: @"+X1", [series.images.anyObject valueForKey:@"completePath"], htmlpath, nil]];		
			[aTask launch];
			[aTask waitUntilExit];		
		}
		
		NSString* pdfpath = [htmlpath stringByAppendingPathExtension:@"pdf"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:pdfpath] == NO) {
			NSTask* aTask = [[[NSTask alloc] init] autorelease];
			[aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
			[aTask setArguments:[NSArray arrayWithObjects:htmlpath, @"pdfFromURL", nil]];		
			[aTask launch];
			[aTask waitUntilExit];	
		}
		
		response.data = [NSData dataWithContentsOfFile:pdfpath];
	}
	#endif
}


-(void)processZip {
	NSMutableArray* images = [NSMutableArray array];
	DicomStudy* study = nil;

	NSManagedObject* o = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass:nil];
	if ([o isKindOfClass:[DicomStudy class]]) {
		study = (DicomStudy*)o;
		for (DicomSeries* s in study.series)
			[images addObjectsFromArray:s.images.allObjects];
	} else if ([o isKindOfClass:[DicomSeries class]]) {
		study = ((DicomSeries*)o).study;
		[images addObjectsFromArray:((DicomSeries*)o).images.allObjects];
	}
	
	if (!images.count)
		return;
		
	if (user.encryptedZIP.boolValue)
		[self.portal updateLogEntryForStudy:study withMessage:@"Download encrypted DICOM ZIP" forUser:self.user.name ip:asyncSocket.connectedHost];
	else [self.portal updateLogEntryForStudy:study withMessage:@"Download DICOM ZIP" forUser:self.user.name ip:asyncSocket.connectedHost];
		
	@try
	{
		NSString *srcFolder = @"/tmp";
		NSString *destFile = @"/tmp";
		
		srcFolder = [srcFolder stringByAppendingPathComponent: [[[images lastObject] valueForKeyPath:@"series.study.name"] filenameString]];
		destFile = [destFile stringByAppendingPathComponent: [[[images lastObject] valueForKeyPath:@"series.study.name"] filenameString]];
		
		if (self.requestIsMacOS)
			destFile = [destFile stringByAppendingPathExtension:@"osirixzip"];
		else destFile = [destFile stringByAppendingPathExtension:@"zip"];
		
		if (srcFolder)
			[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
		if (destFile)
			[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
		
		[NSFileManager.defaultManager confirmDirectoryAtPath:srcFolder];
		
		[self.portal.dicomDatabase.managedObjectContext unlock];
		[BrowserController encryptFiles:[images valueForKey:@"completePath"] inZIPFile:destFile password: user.encryptedZIP.boolValue? user.password : NULL ];
		[self.portal.dicomDatabase.managedObjectContext lock];

		response.data = [NSData dataWithContentsOfFile:destFile];
		
		if (srcFolder)
			[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
		if (destFile)
			[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
	}
	@catch(NSException* e) {
		NSLog(@"**** web seriesAsZIP exception : %@", e);
	}
}

-(void)processImage {
	id object = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass:Nil];
	if (!object)
		return;
	
	NSArray* images = nil;
	
	if ([object isKindOfClass:[DicomSeries class]]) {
		images = [[object images] allObjects];
	} else if ([object isKindOfClass: [DicomImage class]]) {
		images = [NSArray arrayWithObject:object];
	}
	
	DicomImage* dicomImage = images.count == 1 ? [images lastObject] : [images objectAtIndex:images.count/2];
	
	DCMPix* dcmPix = [[[DCMPix alloc] initWithPath:dicomImage.completePathResolved :0 :1 :nil :dicomImage.numberOfFrames.intValue/2 :dicomImage.series.id.intValue isBonjour:NO imageObj:dicomImage] autorelease];
	
	/*if (!dcmPix)
	{
		NSLog( @"****** dcmPix creation failed for file : %@", [im valueForKey:@"completePathResolved"]);
		float *imPtr = (float*)malloc( [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue] * sizeof(float));
		for (int i = 0; i < dicomImage.width.intValue*dicomImage.height.intValue; i++)
			imPtr[i] = i;
		
		dcmPix = [[[DCMPix alloc] initWithData: imPtr :32 :[[dicomImage valueForKey: @"width"] intValue] :[[dicomImage valueForKey: @"height"] intValue] :0 :0 :0 :0 :0] autorelease];
	}*/
	
	if (!dcmPix)
		return;
	
	float curWW = 0;
	float curWL = 0;
	
	if (dicomImage.series.windowWidth) {
		curWW = dicomImage.series.windowWidth.floatValue;
		curWL = dicomImage.series.windowLevel.floatValue;
	}
	
	if (curWW != 0)
		[dcmPix checkImageAvailble:curWW :curWL];
	else [dcmPix checkImageAvailble:dcmPix.savedWW :dcmPix.savedWL];
	
	NSImage* image = [dcmPix image];
	
	NSSize size = image.size;
	[self getWidth:&size.width height:&size.height fromImagesArray:[NSArray arrayWithObject:dicomImage]];
	if (size != image.size)
		image = [image imageByScalingProportionallyToSize:size];
	
	if ([parameters objectForKey:@"previewForMovie"]) {
		[image lockFocus];
		
		NSImage* r = [NSImage imageNamed:@"PlayTemplate.png"];
		[r drawInRect:NSRectCenteredInRect(NSMakeRect(0,0,r.size.width,r.size.height), NSMakeRect(0,0,image.size.width,image.size.height)) fromRect:NSMakeRect(0,0,r.size.width,r.size.height) operation:NSCompositeSourceOver fraction:1.0];
		
		[image unlockFocus];
	}
	
	NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
	
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
	if ([requestedPath.pathExtension isEqualToString:@"png"]){
		response.data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
		response.mimeType = @"image/png";
		
	} else if ([requestedPath.pathExtension isEqualToString:@"jpg"]) {
		response.data = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		response.mimeType = @"image/jpeg";
	} // else NSLog( @"***** unknown path extension: %@", [fileURL pathExtension]);
}

-(void)processMovie {
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"] ofClass:[DicomSeries class]];
	if (!series)
		return;
	
	response.data = [self produceMovieForSeries:series fileURL:requestedPath];
	
	//if (data == nil || [data length] == 0)
	//	NSLog( @"****** movie data == nil");
}


@end





