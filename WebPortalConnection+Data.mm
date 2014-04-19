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
#import "WebPortal+Email+Log.h"
#import "WebPortalResponse.h"
#import "DicomAlbum.h"
#import "DicomDatabase.h"
#import "WebPortalUser.h"
#import "WebPortalSession.h"
#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "AsyncSocket.h"
#import "WebPortalDatabase.h"
#import "WebPortalConnection.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSString+N2.h"
#import "NSImage+N2.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "DicomStudy+Report.h"
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
#import "N2Debug.h"
#import "MutableArrayCategory.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "QuicktimeExport.h"
#import "dicomFile.h"
#import "QueryController.h"
#import "SRAnnotation.h"
#import "BrowserController.h" // TODO: remove when badness solved
#import "BrowserControllerDCMTKCategory.h" // TODO: remove when badness solved
#import "DCMView.h"
#import "DicomImage.h"
#import "DCMTKQueryNode.h"

// TODO: NSUserDefaults access for keys @"logWebServer", @"notificationsEmailsSender" and @"lastNotificationsDate" must be replaced with WebPortal properties

static NSTimeInterval StartOfDay(NSCalendarDate* day) {
	NSCalendarDate* start = [NSCalendarDate dateWithYear:day.yearOfCommonEra month:day.monthOfYear day:day.dayOfMonth hour:0 minute:0 second:0 timeZone:NULL];
	return start.timeIntervalSinceReferenceDate;
}

static volatile int DCMPixLoadingThreads = 0, uniqueInc = 1;
static NSRecursiveLock *DCMPixLoadingLock = nil;

@implementation WebPortalConnection (Data)

+ (NSString*)tmpDirPath {
    static NSString* path = nil;
    if (!path) {
        path = [[[NSFileManager.defaultManager tmpDirPath] stringByAppendingPathComponent:@"WebServer"] retain];
        [NSFileManager.defaultManager confirmDirectoryAtPath:path];
    }
    
    return path;
}

+(NSArray*)MakeArray:(id)obj {
	if ([obj isKindOfClass:[NSArray class]])
		return obj;
	
	if (obj == nil)
		return [NSArray array];
	
	return [NSArray arrayWithObject:obj];
}

- (DicomStudy*) studyForStudyInstanceUID: (NSString*) uid server: (NSDictionary*)
ss
{
    DicomStudy *returnedStudy = nil;
    
    @try
    {
        // First try to find it locally
        N2ManagedDatabase* db = self.independentDicomDatabase;
        NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
        [r setPredicate: [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", uid]];
        
        NSArray *studyArray = nil;
        @try
        {
            studyArray = [db.managedObjectContext executeFetchRequest: r error: nil];
        }
        @catch (NSException *e) { N2LogExceptionWithStackTrace(e);}
        
        if( studyArray.count > 1)
			NSLog( @"****** WADO Server : more than 1 study with same uid : %d", (int) studyArray.count);
        
        if( studyArray.count > 0)
            return [studyArray lastObject];
        
        // Find it on a distant server
        
        NSArray *studies = nil;
        
        if( ss)
            studies = [QueryController queryStudyInstanceUID: uid server: ss showErrors: NO];
        else
        {
            studies = [QueryController queryStudiesForFilters: [NSDictionary dictionaryWithObjectsAndKeys: uid, @"StudyInstanceUID", nil] servers: [BrowserController comparativeServers] showErrors: NO];
        }
        
        if( studies.count)
        {
            [QueryController retrieveStudies: studies showErrors: NO checkForPreviousAutoRetrieve: YES];
            
            NSTimeInterval dateStart = [NSDate timeIntervalSinceReferenceDate];
            NSUInteger lastNumberOfImages = 0, currentNumberOfImages = 0;
            studyArray = nil;
            
            do
            {
                DicomStudy *s = [studyArray lastObject];
                lastNumberOfImages = s.images.count;
                DicomDatabase* db = self.independentDicomDatabase;
                [NSThread sleepForTimeInterval: 0.1];
                
//                [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
//                [NSThread sleepForTimeInterval: 0.3];
                [db importFilesFromIncomingDir];
                
                // And find the study locally
                NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
                [r setPredicate: [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", uid]];
                
                @try
                {
                    studyArray = [db.managedObjectContext executeFetchRequest: r error: nil];
                }
                @catch (NSException *e) { N2LogExceptionWithStackTrace(e);}
                
                returnedStudy = s = [studyArray lastObject];
                currentNumberOfImages = s.images.count;
            }
            while( ([studyArray count] == 0 || lastNumberOfImages != currentNumberOfImages) && [NSDate timeIntervalSinceReferenceDate] - dateStart < 20);
            
            if( studyArray.count == 0)
                N2LogStackTrace( @"---- failed to retrieve distant study");
        }
        else
            N2LogStackTrace( @"---- study uid NOT found on distant servers");
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
    
    return returnedStudy;
}

- (id)objectWithXID:(NSString*)xid
{
    NSManagedObject* o = nil;
    
    if( [xid hasPrefix: @"POD:"]) // PACS On Demand object
    {
        NSArray* axid = [xid componentsSeparatedByString:@":"];
        
        if (axid.count == 5)
        {
            // Example: POD:172.18.1.5:4096:STUDY:2.16.840.1.113669.632.20.121711.10000370559
            
            //Find the server, and retrieve the object(s)
            
            NSArray *serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
            NSDictionary *s = nil;
            
            for( NSDictionary *aServer in serversArray)
            {
                if( [[aServer objectForKey:@"Activated"] boolValue] && [[aServer objectForKey:@"Address"] isEqualToString: [axid objectAtIndex: 1]] && [[aServer objectForKey:@"Port"] intValue] == [[axid objectAtIndex: 2] intValue])
                {
                    s = aServer;
                    break;
                }
            }
            
            if( s)
            {
                if( [[axid objectAtIndex: 3] isEqualToString: @"STUDY"])
                    o = [self studyForStudyInstanceUID: [axid objectAtIndex: 4] server: s];
                else
                    N2LogStackTrace( @"**** XID POD at non-study level??");
            }
        }
    }
    else
    {
        NSArray* axid = [xid componentsSeparatedByString:@"/"];
        
        if (axid.count != 3) {
            N2LogStackTrace(@"****** ERROR: unexpected CoreData ID format, please contact dev team");
            return nil;
        }
        
        NSString* axidEntityName = [axid objectAtIndex:1];
        
        N2ManagedDatabase* db = nil;
        if ([axidEntityName isEqualToString:@"User"])
            db = [self.portal.database independentDatabase];
        else
            db = self.independentDicomDatabase;
        
        o = [db objectWithID:[NSManagedObject UidForXid:xid]];
    }
    
    // ensure that the user is allowed to access this object
    if (user && ([o isKindOfClass: [DicomStudy class]] || [o isKindOfClass: [DicomSeries class]])) // Too slow to check for DicomImage
    {
        DicomStudy *s = nil;
        
        if ([o isKindOfClass: [DicomStudy class]])
            s = (DicomStudy*) o;
        
        if ([o isKindOfClass: [DicomSeries class]])
        {
            DicomSeries *series = (DicomSeries*) o;
            s = series.study;
        }
        
        if ([o isKindOfClass: [DicomImage class]])
        {
            DicomImage *image = (DicomImage*) o;
            s = image.series.study;
        }
        
        NSArray *studies = [WebPortalUser studiesForUser: user predicate: [NSPredicate predicateWithFormat: @"patientUID BEGINSWITH[cd] %@", s.patientUID]];
        
        if( [[studies filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", s.studyInstanceUID]] count] == 0)
        {
            NSLog( @"**** study not found for this user (%@) : %@", user, s);
            return nil;
        }
    }
    
    // Distant study with more images?
    if( [o isKindOfClass: [DicomStudy class]] && [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"automaticallyRetrievePartialStudies"])
    {
        // Servers
        NSArray *servers = [BrowserController comparativeServers];
        DicomStudy *localStudy = (DicomStudy*) o;
        
        if( servers.count)
        {
            // Distant study
            DicomStudy *distantStudy = [[QueryController queryStudiesForFilters: [NSDictionary dictionaryWithObject: [o valueForKey: @"studyInstanceUID"] forKey: @"StudyInstanceUID"] servers: servers showErrors: NO] lastObject];
            
            if( [[localStudy rawNoFiles] intValue] < [[distantStudy noFiles] intValue])
            {
                [QueryController retrieveStudies: [NSArray arrayWithObject: distantStudy] showErrors: NO checkForPreviousAutoRetrieve: YES];
                
                NSTimeInterval dateStart = [NSDate timeIntervalSinceReferenceDate];
                NSUInteger lastNumberOfImages = 0, currentNumberOfImages = 0;
                do
                {
                    DicomStudy *s = (DicomStudy*) o;
                    
                    lastNumberOfImages = s.images.count;
                    [NSThread sleepForTimeInterval: 0.1];
                    
//                    [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
//                    [NSThread sleepForTimeInterval: 0.3];
                    
                    [[[DicomDatabase activeLocalDatabase] independentDatabase] importFilesFromIncomingDir];
                    
                    [s.managedObjectContext refreshObject: s mergeChanges: NO];
                    
                    currentNumberOfImages = s.images.count;
                }
                while( [NSDate timeIntervalSinceReferenceDate] - dateStart < 10 && lastNumberOfImages != currentNumberOfImages);
            }
        }
    }
	
	return o;
}

-(NSArray*)studyList_requestedStudies:(NSString**)title
{
	NSString* ignore = nil;
    NSArray* result = nil;
    int fetchLimitPerPage = [[NSUserDefaults standardUserDefaults] integerForKey: @"FetchLimitForWebPortal"];
    int numberOfStudies;
    int page = [[parameters objectForKey:@"page"] intValue];
    
	if (!title) title = &ignore;
	
    if ([parameters objectForKey:@"sortKey"])
        if ([[[self.portal.dicomDatabase entityForName:@"Study"] attributesByName] objectForKey:[parameters objectForKey:@"sortKey"]])
            [self.session setObject:[parameters objectForKey:@"sortKey"] forKey:@"StudiesSortKey"];
    
    if (![self.session objectForKey:@"StudiesSortKey"])
        [self.session setObject:@"date" forKey:@"StudiesSortKey"];
    
	NSString* albumReq = [parameters objectForKey:@"album"];
	if (albumReq.length)
    {
		*title = [NSString stringWithFormat:NSLocalizedString(@"Album: %@", @"Web portal, study list, title format (%@ is album name)"), albumReq];
		result = [WebPortalUser studiesForUser: user album:albumReq sortBy:[self.session objectForKey:@"StudiesSortKey"] fetchLimit: fetchLimitPerPage fetchOffset: page*fetchLimitPerPage numberOfStudies: &numberOfStudies];
	}
	else
    {
        NSString* browseReq = [parameters objectForKey:@"browse"];
        NSString* browseParameterReq = [parameters objectForKey:@"browseParameter"];
        NSMutableDictionary *PODFilter = [NSMutableDictionary dictionary];
        NSPredicate* browsePredicate = NULL;
        
        if ([browseReq isEqualToString:@"newAddedStudies"] && browseParameterReq.doubleValue > 0)
        {
            *title = NSLocalizedString( @"New Studies", @"Web portal, study list, title");
            browsePredicate = [NSPredicate predicateWithFormat: @"dateAdded >= CAST(%lf, \"NSDate\")", browseParameterReq.doubleValue];
            
            // No equivalence in PACS On Demand
        }
        else if ([browseReq isEqualToString:@"today"])
        {
            *title = NSLocalizedString( @"Today", @"Web portal, study list, title");
            NSTimeInterval ti = StartOfDay(NSCalendarDate.calendarDate);
            browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", ti];
            
            [PODFilter setObject: [NSNumber numberWithInt: after] forKey: @"date"];
            [PODFilter setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: ti] forKey: @"fromDate"];
        }
        else if ([browseReq isEqualToString:@"6hours"])
        {
            *title = NSLocalizedString( @"Last 6 Hours", @"Web portal, study list, title");
            NSCalendarDate *now = [NSCalendarDate calendarDate];
            NSTimeInterval ti = [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:[now hourOfDay]-6 minute:[now minuteOfHour] second:[now secondOfMinute] timeZone:nil] timeIntervalSinceReferenceDate];
            browsePredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", ti];
            
            [PODFilter setObject: [NSNumber numberWithInt: after] forKey: @"date"];
            [PODFilter setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: ti] forKey: @"fromDate"];
        }
        else if ([parameters objectForKey:@"search"])
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
            searchString = [searchString stringByReplacingOccurrencesOfString: @", " withString: @" "];
            searchString = [searchString stringByReplacingOccurrencesOfString: @"," withString: @" "];
            
            [search appendFormat:@"name BEGINSWITH[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
            
            if( searchString.length >= 2)
                [PODFilter setObject: [searchString stringByAppendingString:@"*"] forKey: @"PatientsName"];
            
            //
            
            browsePredicate = [[BrowserController currentBrowser] patientsnamePredicate: [parameters objectForKey:@"search"] soundex: NO];
        }
        else if ([parameters objectForKey:@"searchID"])
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
            
            [search appendFormat:@"patientID BEGINSWITH[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
            browsePredicate = [NSPredicate predicateWithFormat:search];
            
            if( searchString.length >= 2)
                [PODFilter setObject: [searchString stringByAppendingString:@"*"] forKey: @"PatientID"];
        }
        else if ([parameters objectForKey:@"searchAccessionNumber"])
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
            
            [search appendFormat:@"accessionNumber BEGINSWITH[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
            browsePredicate = [NSPredicate predicateWithFormat:search];
            
            if( searchString.length >= 2)
                [PODFilter setObject: [searchString stringByAppendingString:@"*"] forKey: @"AccessionNumber"];
        }
        
        if (!browsePredicate)
        {
            *title = NSLocalizedString(@"Study List", @"Web portal, study list, title");
            //browsePredicate = [NSPredicate predicateWithValue:YES];
        }
        
        result = [WebPortalUser studiesForUser: user predicate:browsePredicate sortBy: nil fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil]; // Sort and FetchLimit is applied AFTER PACS On Demand
        
        // PACS On Demand
        NSString *pred = [user.studyPredicate uppercaseString];
        pred = [pred stringByReplacingOccurrencesOfString:@" " withString: @""];
        pred = [pred stringByReplacingOccurrencesOfString:@"(" withString: @""];
        pred = [pred stringByReplacingOccurrencesOfString:@")" withString: @""];
        if( user == nil || pred.length == 0 || [pred isEqualToString: @"YES==YES"])
        {
            if( PODFilter.count >= 1 && [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"ActivatePACSOnDemandForWebPortalSearch"])
            {
//                BOOL usePatientID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientIDForUID"];
//                BOOL usePatientBirthDate = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientBirthDateForUID"];
//                BOOL usePatientName = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientNameForUID"];
                
                // Servers
                NSArray *servers = [BrowserController comparativeServers];
                
                if( servers.count)
                {
                    NSArray *distantStudies = [QueryController queryStudiesForFilters: PODFilter servers: servers showErrors: NO];
                    
                    if( [[[PODFilter valueForKey: @"PatientsName"] componentsSeparatedByString: @" "] count] > 1) // For patient name, if several components, try with ^ separator, and add missing results
                    {
                        NSString *s = [PODFilter valueForKey: @"PatientsName"];
                        
                        // replace last occurence // fan siu hung
                        [PODFilter setValue: [s stringByReplacingCharactersInRange: [s rangeOfString: @" " options: NSBackwardsSearch] withString: @"^"] forKey: @"PatientsName"];
                        
                        NSArray *subResult = [QueryController queryStudiesForFilters: PODFilter servers: servers showErrors: NO];
                        
                        NSArray *resultUIDs = [distantStudies valueForKey: @"uid"];
                        
                        for( DCMTKQueryNode *n in subResult)
                        {
                            if( [resultUIDs containsObject: n.uid] == NO)
                                distantStudies = [distantStudies arrayByAddingObject: n];
                        }
                    }
                    
                    if( distantStudies.count)
                    {
                        NSMutableArray *mutableStudiesArray = [NSMutableArray arrayWithArray: result];
                        
                        // Merge local and distant studies
                        for( DCMTKStudyQueryNode *distantStudy in distantStudies)
                        {
                            if( [[mutableStudiesArray valueForKey: @"studyInstanceUID"] containsObject: [distantStudy studyInstanceUID]] == NO)
                                [mutableStudiesArray addObject: distantStudy];
                            
                            else if( [[NSUserDefaults standardUserDefaults] boolForKey: @"preferStudyWithMoreImages"])
                            {
                                NSUInteger index = [[mutableStudiesArray valueForKey: @"studyInstanceUID"] indexOfObject: [distantStudy studyInstanceUID]];
                                
                                if( index != NSNotFound && [[[mutableStudiesArray objectAtIndex: index] rawNoFiles] intValue] < [[distantStudy noFiles] intValue])
                                {
                                    [mutableStudiesArray replaceObjectAtIndex: index withObject: distantStudy];
                                }
                            }
                        }
                        
                        result = mutableStudiesArray;
                    }
                }
            }
        }
        
        NSString *sortValue = [self.session objectForKey:@"StudiesSortKey"];
        
        if( [sortValue length])
		{
			if( [sortValue rangeOfString: @"date"].location == NSNotFound)
				result = [result sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: sortValue ascending: YES selector: @selector(caseInsensitiveCompare:)]]];
			else
				result = [result sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: sortValue ascending: NO]]];
		}
        
        numberOfStudies = result.count;
		
        if( fetchLimitPerPage)
        {
            NSRange range = NSMakeRange( page*fetchLimitPerPage, fetchLimitPerPage);
            
            if( range.location > result.count)
                range.location = result.count;
            
            if( range.location + range.length > result.count)
                range.length = result.count - range.location;
            
            result = [result subarrayWithRange: range];
        }
    }
    
    if( [parameters objectForKey:@"page"])
        [self.session setObject: [parameters objectForKey:@"page"] forKey:@"Page"];
    else
        [self.session setObject: [NSNumber numberWithInt: 0] forKey:@"Page"];
    
    [self.session setObject: [NSNumber numberWithInt: numberOfStudies] forKey:@"NumberOfStudies"];
    
    if( numberOfStudies%fetchLimitPerPage == 0)
        [self.session setObject: [NSNumber numberWithInt: (numberOfStudies/fetchLimitPerPage)] forKey:@"NumberOfPages"];
    else
        [self.session setObject: [NSNumber numberWithInt: 1 + (numberOfStudies/fetchLimitPerPage)] forKey:@"NumberOfPages"];
    
    [self.session setObject: [NSNumber numberWithInt:fetchLimitPerPage] forKey:@"FetchLimitPerPage"];
    
	return result;
}

-(void)sendImages:(NSArray*)images toDicomNode:(NSDictionary*)dicomNodeDescription
{
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
									extraParameters:[NSDictionary dictionaryWithObject:self.portal.dicomDatabase.independentDatabase forKey:@"DicomDatabase"]] autorelease] run: nil];
	} @catch (NSException* e) {
		NSLog(@"Error: [WebServiceConnection sendImagesToDicomNodeThread:] %@", e);
	} @finally {
		[pool release];
	}
}

-(void)getWidth:(CGFloat*)width height:(CGFloat*)height fromImagesArray:(NSArray*)images {
    
    if( images.count > 4)
        [self getWidth:width height:height fromImagesArray:images minSize:NSMakeSize( [[NSUserDefaults standardUserDefaults] floatForKey: @"WebServerMinWidthForMovie"]) maxSize:NSMakeSize( [[NSUserDefaults standardUserDefaults] floatForKey: @"WebServerMaxWidthForMovie"])];
    else
        [self getWidth:width height:height fromImagesArray:images minSize:NSMakeSize( [[NSUserDefaults standardUserDefaults] floatForKey: @"WebServerMinWidthForMovie"]) maxSize:NSMakeSize( [[NSUserDefaults standardUserDefaults] floatForKey: @"WebServerMaxWidthForStillImage"])];
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

- (void) drawText: (NSString*) text atLocation: (NSPoint) loc
{
    [text drawAtPoint: loc withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSColor blackColor], NSForegroundColorAttributeName, nil]];
    
    loc.x++;
    loc.y++;
    
    [text drawAtPoint: loc withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName, nil]];
}

- (void) movieDCMPixLoad: (NSDictionary*) dict
{
    @autoreleasepool {
        DicomDatabase *idd = self.portal.dicomDatabase.independentDatabase;
        NSArray *dicomImageArray = [idd objectsWithIDs: [dict valueForKey: @"DicomImageArray"]];
        
        int location = [[dict valueForKey: @"location"] unsignedIntValue];
        int length = [[dict valueForKey: @"length"] unsignedIntValue];
        int width = [[dict valueForKey: @"width"] floatValue];
        int height = [[dict valueForKey: @"height"] floatValue];
        NSString *outFile = [dict valueForKey: @"outFile"];
        NSString *fileName = [dict valueForKey: @"fileName"];
        NSInteger* fpsP = (NSInteger*)[[dict valueForKey:@"fpsP"] pointerValue];
        
        NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 0.7] forKey:NSImageCompressionFactor];
        
        DicomSeries *series = [(DicomImage*)[dicomImageArray lastObject] series];
        NSArray *allImages = [series sortedImages];
        int totalImages = series.images.count;
        
        for( int x = location ; x < location+length; x++)
        {
            @autoreleasepool {
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
                        
                        if (x == 0 && [dcmPix cineRate])
                            *fpsP = [dcmPix cineRate];
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
                    
        #define TEXTHEIGHT 15
                    [newImage lockFocus];
                    [self drawText: [NSString stringWithFormat: @"%d / %d", (int) ([allImages indexOfObject: im]+1), totalImages]  atLocation: NSMakePoint( 1, newImage.size.height - TEXTHEIGHT)];
                    [newImage unlockFocus];
                    
                    if ([outFile hasSuffix:@"swf"])
                        [[[NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:imageProps] writeToFile:[[fileName stringByAppendingString:@" dir"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%6.6d.jpg", x]] atomically:YES];
                    else
                        [[newImage TIFFRepresentationUsingCompression: NSTIFFCompressionLZW factor: 1.0] writeToFile: [[fileName stringByAppendingString: @" dir"] stringByAppendingPathComponent: [NSString stringWithFormat: @"%6.6d.tiff", x]] atomically: YES];
                    
                    [dcmPix release];
                }
                @catch (NSException * e)
                {
                    N2LogExceptionWithStackTrace(e);
                }
            }
        }
        
        @synchronized( self)
        {
            DCMPixLoadingThreads--;
        }
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
	
    int MaxNumberOfFramesForWebPortalMovies = [[NSUserDefaults standardUserDefaults] integerForKey: @"MaxNumberOfFramesForWebPortalMovies"];
    
    if( MaxNumberOfFramesForWebPortalMovies > 2 && dicomImageArray.count >= MaxNumberOfFramesForWebPortalMovies)
    {
        do
        {
            NSMutableArray *newArray = [NSMutableArray arrayWithCapacity: dicomImageArray.count / 2];
            
            for ( int i = 0; i < dicomImageArray.count; i += 2)
                [newArray addObject: [dicomImageArray objectAtIndex: i]];
            
            dicomImageArray = newArray;
        }
        while( dicomImageArray.count > MaxNumberOfFramesForWebPortalMovies);
    }
    
	@synchronized(self.portal.locks)
    {
		if (![self.portal.locks objectForKey:outFile])
			[self.portal.locks setObject:[[[NSRecursiveLock alloc] init] autorelease] forKey:outFile];
	}
    
	[[self.portal.locks objectForKey:outFile] lock];
	
	@try
	{
		if (![[NSFileManager defaultManager] fileExistsAtPath: outFile] || ([[dict objectForKey: @"rows"] intValue] > 0 && [[dict objectForKey: @"columns"] intValue] > 0))
		{
			int noOfThreads = [[NSProcessInfo processInfo] processorCount];
			
            if( noOfThreads > 12)
                noOfThreads = 12;
            
			NSRange range = NSMakeRange( 0, 1+ ([dicomImageArray count] / noOfThreads));
            
			if( DCMPixLoadingLock == nil)
				DCMPixLoadingLock = [[NSRecursiveLock alloc] init];
			
			[DCMPixLoadingLock lock];
			
            //			[self.portal.dicomDatabase lock];
			
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
			
            NSInteger fps = 0;
            
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
						[NSThread detachNewThreadSelector: @selector(movieDCMPixLoad:)
												 toTarget: self
											   withObject: [NSDictionary dictionaryWithObjectsAndKeys:
															[NSNumber numberWithUnsignedInt: range.location], @"location",
															[NSNumber numberWithUnsignedInt: range.length], @"length",
															[NSNumber numberWithFloat: width], @"width",
															[NSNumber numberWithFloat: height], @"height",
															outFile, @"outFile",
															fileName, @"fileName",
															[dicomImageArray valueForKey: @"objectID"], @"DicomImageArray",
                                                            [NSValue valueWithPointer:&fps], @"fpsP", nil]];
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
                N2LogExceptionWithStackTrace(e);
			}
			
            //			[self.portal.dicomDatabase unlock];
			
			[DCMPixLoadingLock unlock];
            
            if (fps <= 0)
                fps = [[NSUserDefaults standardUserDefaults] integerForKey: @"quicktimeExportRateValue"];
            if (fps <= 0)
                fps = 10;
            
			NSLog( @"generateMovie: start writeMovie process");
            
            if( [outFile hasSuffix:@".swf"]) // FLASH
            {
                @try
                {
                    NSTask *theTask = [[[NSTask alloc] init] autorelease];
                    
                    [theTask setArguments: [NSArray arrayWithObjects: outFile, @"writeMovie", [outFile stringByAppendingString: @" dir"], [[NSNumber numberWithInteger:fps] stringValue], nil]];
                    [theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
                    [theTask launch];
                    
                    while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
                }
                @catch (NSException *e)
                {
                    NSLog( @"***** writeMovie exception : %@", e);
                }
            }
            else
            {
                @try
                {
                    NSString *root = [fileName stringByAppendingString: @" dir"];
                    
                    CMTimeValue timeValue = 600 / fps;
                    CMTime frameDuration = CMTimeMake( timeValue, 600);
                    
                    NSError *error = nil;
                    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath: outFile] fileType: AVFileTypeQuickTimeMovie error:&error];
                    
                    if (!error)
                    {
                        double bitsPerSecond = width * height * fps * 4;
                        
                        if( bitsPerSecond > 0)
                        {
                            NSDictionary *videoSettings = nil;
                            
                            if( self.requestIsIOS) // AVVideoCodecH264
                            {
                                videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 AVVideoCodecH264, AVVideoCodecKey,
                                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                                  [NSNumber numberWithDouble: bitsPerSecond], AVVideoAverageBitRateKey,
                                                  [NSNumber numberWithInteger: 1], AVVideoMaxKeyFrameIntervalKey,
                                                  nil], AVVideoCompressionPropertiesKey,
                                                 [NSNumber numberWithInt: width], AVVideoWidthKey,
                                                 [NSNumber numberWithInt: height], AVVideoHeightKey, nil];
                            }
                            else // AVVideoCodecJPEG
                            {
                                videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 AVVideoCodecJPEG, AVVideoCodecKey,
                                                 [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat: 0.9], AVVideoQualityKey, nil] ,AVVideoCompressionPropertiesKey,
                                                 [NSNumber numberWithInt: width], AVVideoWidthKey,
                                                 [NSNumber numberWithInt: height], AVVideoHeightKey, nil];
                            }
                            
                            // Instanciate the AVAssetWriterInput
                            AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
                            
                            if( writerInput == nil)
                                N2LogStackTrace( @"**** writerInput == nil : %@", videoSettings);
                            
                            // Instanciate the AVAssetWriterInputPixelBufferAdaptor to be connected to the writer input
                            AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
                            // Add the writer input to the writer and begin writing
                            [writer addInput:writerInput];
                            [writer startWriting];
                            
                            CMTime nextPresentationTimeStamp;
                            
                            nextPresentationTimeStamp = kCMTimeZero;
                            
                            [writer startSessionAtSourceTime:nextPresentationTimeStamp];
                            
                            for( NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: root error: nil])
                            {
                                NSAutoreleasePool *pool = [NSAutoreleasePool new];
                                
                                CVPixelBufferRef buffer = nil;
                                
                                {
                                    NSImage *im = [[NSImage alloc] initWithContentsOfFile: [root stringByAppendingPathComponent: file]];
                                    if( im)
                                        buffer = [QuicktimeExport CVPixelBufferFromNSImage: im];
                                    [im release];
                                }
                                
                                [pool release];
                                
                                if( buffer)
                                {
                                    CVPixelBufferLockBaseAddress(buffer, 0);
                                    while( writerInput && [writerInput isReadyForMoreMediaData] == NO)
                                        [NSThread sleepForTimeInterval: 0.1];
                                    [pixelBufferAdaptor appendPixelBuffer:buffer withPresentationTime:nextPresentationTimeStamp];
                                    CVPixelBufferUnlockBaseAddress(buffer, 0);
                                    CVPixelBufferRelease(buffer);
                                    buffer = nil;
                                    
                                    nextPresentationTimeStamp = CMTimeAdd(nextPresentationTimeStamp, frameDuration);
                                }
                            }
                            [writerInput markAsFinished];
                        }
                        else
                            N2LogStackTrace( @"********** bitsPerSecond == 0");
                        
                        [writer finishWriting];
                    }
                    [[NSFileManager defaultManager] removeItemAtPath: root error: nil];
                    
                    [writer release];
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
	
	@synchronized(self.portal.locks)
    {
		if ([[self.portal.locks objectForKey:outFile] tryLock])
        {
			[[self.portal.locks objectForKey: outFile] unlock];
			[self.portal.locks removeObjectForKey: outFile];
		}
	}
	
	[pool release];
}



-(NSData*)produceMovieForSeries:(DicomSeries*)series fileURL:(NSString*)fileURL
{
	NSString* path = [WebPortalConnection tmpDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:path];
    
	NSArray *dicomImageArray = [[series valueForKey:@"images"] allObjects];
    
	NSString* name = [NSString stringWithFormat:@"%@", [parameters objectForKey:@"xid"]];
	name = [name stringByAppendingFormat:@"-NBIM-%d", (int) [dicomImageArray count]];
	
	NSMutableString* fileName = [NSMutableString stringWithString:name];
	[BrowserController replaceNotAdmitted:fileName];
	fileName = [NSMutableString stringWithString:[path stringByAppendingPathComponent: fileName]];
	[fileName appendFormat:@".%@", fileURL.pathExtension];
	
	NSString *outFile;
	
	if (self.requestIsIOS)
		outFile = [NSString stringWithFormat:@"%@2.mp4", [fileName stringByDeletingPathExtension]];
	else
		outFile = fileName;
	
	NSData* data = [NSData dataWithContentsOfFile: outFile];
	
	if (!data)
	{
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
			
            //			[self.portal.dicomDatabase unlock];
			
			[self generateMovie: dict];
			
            //			[self.portal.dicomDatabase lock];
            
			
			data = [NSData dataWithContentsOfFile: outFile];
		}
	}
	
	return data;
}


#pragma mark HTML

-(void)processLoginHtml {
	response.templateString = [self.portal stringForPath:@"login.html"];
	response.mimeType = @"text/html";
}

-(void)processIndexHtml {
	response.templateString = [self.portal stringForPath:@"index.html"];
	response.mimeType = @"text/html";
}

-(void)processMainHtml {
    //	if (!user || user.uploadDICOM.boolValue)
    //		[self resetPOST];
	
    //    [self.independentDicomDatabase.managedObjectContext reset]; //We want fresh data : from the persistentstore
    
	NSMutableArray* albums = [NSMutableArray array];
	for (DicomAlbum* album in self.independentDicomDatabase.albums)
    {
		if (![[album valueForKey:@"name"] isEqualToString:NSLocalizedString(@"Database", nil)])
        {
            @autoreleasepool
            {
                int numberOfStudies = 0;
                
                [WebPortalUser studiesForUser: user album: album.name sortBy: nil fetchLimit: 1 fetchOffset: 0 numberOfStudies: &numberOfStudies];
                
                if( numberOfStudies >= 1)
                    [albums addObject:album];
                
                album.numberOfStudies = numberOfStudies;
            }
        }
	}
    [response.tokens setObject:albums forKey:@"Albums"];
    [response.tokens setObject:[WebPortalUser studiesForUser: user predicate:NULL] forKey:@"Studies"];
	
	response.templateString = [self.portal stringForPath:@"main.html"];
	response.mimeType = @"text/html";
}

- (BOOL) processDeleteObject:(NSString*) XID
{
    if( [XID hasPrefix: @"POD:"])
    {
        NSLog( @"-- Cannot delete a distant study: %@", XID);
        return NO;
    }
    
    NSManagedObject *dbObject = [self objectWithXID:XID];
    
    DicomStudy *study = nil;
    DicomSeries *series = nil;
    
    if( [dbObject isKindOfClass: [DicomStudy class]])
        study = (DicomStudy*) dbObject;
    
    if( [dbObject isKindOfClass: [DicomSeries class]])
    {
        study = [dbObject valueForKey: @"study"];
        series = (DicomSeries*) dbObject;
    }
    
    if( study)
    {
        [response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Images successfully deleted.", nil)]];
        [self.portal updateLogEntryForStudy: study withMessage: [NSString stringWithFormat: @"Images deleted"] forUser:user.name ip:asyncSocket.connectedHost];
        
        if( series)
        {
            [series.managedObjectContext deleteObject: series];
            if( study.imageSeries.count == 0)
                [study.managedObjectContext deleteObject: study];
        }
        else
            [study.managedObjectContext deleteObject: study];
        
        BOOL isStudyDeleted = study.isDeleted;
        
        [self.independentDicomDatabase save];
        
        return isStudyDeleted;
    }
    else
        [self.response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Study not found", nil)]];
    
    return NO;
}

-(void)processStudyHtml
{
    [self processStudyHtml: [parameters objectForKey:@"xid"]];
}
	
-(void)processStudyHtml: (NSString*) xid
{
    DicomStudy* study = [self objectWithXID: xid];
    
	if (!study)
		return;
	
	NSMutableArray* selectedSeries = [NSMutableArray array];
	for (NSString* selectedXID in [WebPortalConnection MakeArray:[parameters objectForKey:@"selected"]])
		[selectedSeries addObject:[self objectWithXID:selectedXID]];
	
    if( study && user)
    {
        //save this study in recent studies list, if not already here
        WebPortalStudy *studyLink = [[user.recentStudies filteredSetUsingPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", study.studyInstanceUID]] anyObject];
        
        if( !studyLink)
        {
            studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"RecentStudy" inManagedObjectContext: user.managedObjectContext];
            
            studyLink.studyInstanceUID = [[[study valueForKey: @"studyInstanceUID"] copy] autorelease];
            studyLink.user = user;
        }
        
        studyLink.patientUID = [[[study valueForKey: @"patientUID"] copy] autorelease];
        studyLink.dateAdded = [NSDate date];
        
        NSMutableSet *recentStudies = [user mutableSetValueForKey: @"recentStudies"];
        if( recentStudies.count > [[NSUserDefaults standardUserDefaults] integerForKey: @"WebPortalMaximumNumberOfRecentStudies"])
        {
            NSMutableArray *array = [NSMutableArray arrayWithArray: recentStudies.allObjects];
            [array sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"dateAdded" ascending: NO]]];
            
            for( WebPortalStudy *s in [array subarrayWithRange:  NSMakeRange(  [[NSUserDefaults standardUserDefaults] integerForKey: @"WebPortalMaximumNumberOfRecentStudies"], array.count - [[NSUserDefaults standardUserDefaults] integerForKey: @"WebPortalMaximumNumberOfRecentStudies"])])
            {
                [recentStudies removeObject: s];
            }
        }
        [user.managedObjectContext save: nil];
    }
    
	if( [parameters objectForKey:@"dicomSend"] && study)
    {
		NSArray* dicomDestinationArray = [[parameters objectForKey:@"dicomDestination"] componentsSeparatedByString:@":"];
		if (dicomDestinationArray.count >= 4) {
			NSMutableDictionary* dicomDestination = [NSMutableDictionary dictionary];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:(long)dicomDestinationArray.count-4] forKey:@"Address"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:(long)dicomDestinationArray.count-3] forKey:@"Port"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:(long)dicomDestinationArray.count-2] forKey:@"AETitle"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:(long)dicomDestinationArray.count-1] forKey:@"TransferSyntax"];
			
            NSMutableArray* selectedImages = [NSMutableArray array];
            if( selectedSeries.count)
                for (DicomSeries* s in selectedSeries)
                    [selectedImages addObjectsFromArray:s.sortedImages];
            else
                for (DicomSeries* s in study.series)
                    [selectedImages addObjectsFromArray:s.sortedImages];
            
			if (selectedImages.count) {
				[self sendImages:selectedImages toDicomNode:dicomDestination];
				[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Dicom send to node %@ initiated.", @"Web Portal, study, dicom send, success"), [[dicomDestination objectForKey:@"AETitle"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			} else
				[response.tokens addError: NSLocalizedString(@"Dicom send failed: no images selected. Select one or more series.", @"Web Portal, study, dicom send, error")];
		} else
			[response.tokens addError: NSLocalizedString(@"Dicom send failed: cannot identify node.", @"Web Portal, study, dicom send, error")];
	}
	
	if( [parameters objectForKey:@"WADOURLsRetrieve"] && study && [[NSUserDefaults standardUserDefaults] boolForKey:@"wadoServer"])
	{
		NSMutableArray* selectedImages = [NSMutableArray array];
		for (DicomSeries* s in selectedSeries)
			[selectedImages addObjectsFromArray:s.sortedImages];
		
		if (selectedImages.count)
		{
//			NSString *protocol = [[NSUserDefaults standardUserDefaults] boolForKey:@"encryptedWebServer"] ? @"https" : @"http";
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
                N2LogExceptionWithStackTrace(e);
			}
			
			response.data = [WADOURLs dataUsingEncoding: NSUTF8StringEncoding];
			[response setMimeType:@"application/dcmURLs"];
			[response.httpHeaders setObject: [NSString stringWithFormat:@"attachment; filename=%@.dcmURLs", [[selectedSeries lastObject] valueForKeyPath: @"study.name"]] forKey: @"Content-Disposition"];
			return;
		}
		else
			[response.tokens addError: NSLocalizedString(@"WADO URL Retrieve failed: no images selected. Select one or more series.", @"Web Portal, study, dicom send, error")];
	}
	
    if( [[parameters objectForKey:@"message"] isEqualToString: @"delete"] && [parameters objectForKey:@"seriesToDelete"] && study)
    {
        if (!user.isAdmin.boolValue)
        {
            response.statusCode = 401;
            [self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to delete images without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
        }
        else
        {
            if( [self processDeleteObject: [parameters objectForKey:@"seriesToDelete"]])
                study = nil;
        }
    }
    
	if( [parameters objectForKey:@"shareStudy"] && study)
    {
        if( !user || user.shareStudyWithUser.boolValue)
        {
            NSString* shareStudyDestination = [parameters objectForKey:@"shareStudyDestination"];
            WebPortalUser* destUser = NULL;
            
            if ([shareStudyDestination isEqualToString:@"NEW"])
            {
                if( !user || user.createTemporaryUser.boolValue)
                {
                    @try
                    {
                        destUser = [self.portal newUserWithEmail:[parameters objectForKey:@"shareDestinationCreateTempEmail"]];
                    }
                    @catch (NSException* e)
                    {
                        [self.response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't create temporary user: %@", nil), e.reason]];
                    }
                }
                else
                    [response.tokens addError: NSLocalizedString(@"Study share failed: not authorized.", @"Web Portal, study, share, error")];
            }
            else destUser = [self objectWithXID:shareStudyDestination];
            
            if ([destUser isKindOfClass: [WebPortalUser class]])
            {
                // add study to specific study list for this user
                if (![[destUser.studies.allObjects valueForKey:@"studyInstanceUID"] containsObject:study.studyInstanceUID])
                {
                    WebPortalStudy* wpStudy = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext: destUser.managedObjectContext];
                    wpStudy.user = destUser;
                    wpStudy.patientUID = study.patientUID;
                    wpStudy.studyInstanceUID = study.studyInstanceUID;
                    wpStudy.dateAdded = [NSDate dateWithTimeIntervalSinceReferenceDate:[[NSUserDefaults standardUserDefaults] doubleForKey:@"lastNotificationsDate"]];
                    [destUser.managedObjectContext save:NULL];
                    
                    [response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"This study is now shared with <b>%@</b>.", @"Web Portal, study, share, ok (%@ is destUser.name)"), destUser.name]];
                }
                else
                    [response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"This study is shared with <b>%@</b>.", @"Web Portal, study, share, ok (%@ is destUser.name)"), destUser.name]];
                
                // Send the email
                [self.portal sendNotificationsEmailsTo:[NSArray arrayWithObject:destUser] aboutStudies:[NSArray arrayWithObject:study] predicate:NULL customText: [parameters objectForKey:@"message"] from: user];
                [self.portal updateLogEntryForStudy: study withMessage: [NSString stringWithFormat: @"Share Study with User: %@", destUser.name] forUser:user.name ip:asyncSocket.connectedHost];
            } else
                [response.tokens addError: NSLocalizedString(@"Study share failed: cannot identify user.", @"Web Portal, study, share, error")];
        }
        else
            [response.tokens addError: NSLocalizedString(@"Study share failed: not authorized.", @"Web Portal, study, share, error")];
	}
	
    if( study)
    {
        [response.tokens setObject:[WebPortalProxy createWithObject:study transformer:DicomStudyTransformer.create] forKey:@"Study"];
        [response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"%@ - %@ - %@", @"Web Portal, study, title format (1st %@ is study.name, 2nd is study.studyName, 3rd date)"), study.name, study.studyName, [NSUserDefaults.dateTimeFormatter stringFromDate:study.date]] forKey:@"PageTitle"];
    }
    else
        [response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"Study Deleted", nil)] forKey:@"PageTitle"];
    
	[self.portal updateLogEntryForStudy:study withMessage:@"Browsing Study" forUser:user.name ip:asyncSocket.connectedHost];
	
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
        
        if( [[parameters objectForKey: @"back"] isEqualToString: @"main"])
        {
            studyListLinkLabel= NSLocalizedString(@"Home", nil);
            [response.tokens setObject:@"main" forKey:@"backLink"];
		}
        else
            [response.tokens setObject:@"studyList" forKey:@"backLink"];
		
        [response.tokens setObject:studyListLinkLabel forKey:@"BackLinkLabel"];
        
		// Series
		
		NSMutableArray* seriesArray = [NSMutableArray array];
		for (DicomSeries* s in study.imageSeries)
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
                                          self.requestIsIOS? NSLocalizedString( @"This Device", nil) : [NSString stringWithFormat: NSLocalizedString( @"This Computer [%@:%@]", nil), [asyncSocket connectedHost], self.dicomCStorePortString], @"description",
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
		if (!user || user.shareStudyWithUser.boolValue)
        {
            WebPortalDatabase *idatabase = [self.portal.database independentDatabase];
			NSArray* users = [[idatabase objectsForEntity:idatabase.userEntity] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
			
			for (WebPortalUser* u in users)
				if (u != self.user)
					[shareDestinations addObject:[WebPortalProxy createWithObject:u transformer:[WebPortalUserTransformer create]]];
		}
		[response.tokens setObject:shareDestinations forKey:@"ShareDestinations"];
        
	} @catch (NSException* e) {
		NSLog(@"Error: [WebPortalResponse processStudyHtml:] %@", e);
	}
    
	response.templateString = [self.portal stringForPath:@"study.html"];
	response.mimeType = @"text/html";
}

-(void)processLogsListHtml
{
    if (!user.isAdmin.boolValue)
    {
        response.statusCode = 401;
        [self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to see logs without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
        return;
    }
    
    NSArray *logsArray = nil;
    
    if( [parameters objectForKey:@"externalIPs"])
    {
        [response.tokens setObject: NSLocalizedString( @"Logs - External IPs", nil) forKey:@"PageTitle"];
        
        logsArray = [self.independentDicomDatabase objectsForEntity: @"LogEntry" predicate: [NSPredicate predicateWithFormat: @"type == %@ AND NOT originName BEGINSWITH '172.' AND NOT originName BEGINSWITH '10.' AND NOT originName BEGINSWITH '192.168.' AND NOT originName BEGINSWITH '127.' AND NOT originName LIKE '::1'", @"Web"] error:nil fetchLimit: 2000 sortDescriptors:[NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"startTime" ascending: NO]]];
    }
    else
    {
        [response.tokens setObject: NSLocalizedString( @"Logs", nil) forKey:@"PageTitle"];
    
        logsArray = [self.independentDicomDatabase objectsForEntity: @"LogEntry" predicate: [NSPredicate predicateWithFormat: @"type == %@", @"Web"] error:nil fetchLimit: 2000 sortDescriptors:[NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"startTime" ascending: NO]]];
    }
        
	[response.tokens setObject: logsArray forKey:@"Logs"];
    
	response.templateString = [self.portal stringForPath:@"admin/logs.html"];
	response.mimeType = @"text/html";
}

-(void)processStudyListHtml
{
    if( [parameters objectForKey:@"delete"])
    {
        if (!user.isAdmin.boolValue)
        {
            response.statusCode = 401;
            [self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to delete images without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
        }
        else
        {
            [self processDeleteObject: [parameters objectForKey:@"delete"]];
        }
    }
    
    NSString* title = NULL;
	[response.tokens setObject:[self studyList_requestedStudies:&title] forKey:@"Studies"];
	if (title) [response.tokens setObject:title forKey:@"PageTitle"];
	response.templateString = [self.portal stringForPath:@"studyList.html"];
	response.mimeType = @"text/html";
}

-(void)processKeyROIsImagesHtml
{
    DicomStudy *study = nil;
    
    NSManagedObject* oxid = [self objectWithXID:[parameters objectForKey:@"xid"]];
    if ([oxid isKindOfClass:[DicomStudy class]])
    {
        study = (DicomStudy*) oxid;
        
        if( study == nil)
            return;
        
        [response.tokens setObject: [WebPortalProxy createWithObject:study transformer:[DicomStudyTransformer create]] forKey:@"Study"];
        [response.tokens setObject: [NSString stringWithFormat: @"%@ - %@", study.name, NSLocalizedString( 	@"Key Images and ROI Images", nil)] forKey:@"PageTitle"];
        [response.tokens setObject: [NSString stringWithFormat:@"%@ - %@", study.name, study.studyName] forKey:@"BackLinkLabel"];
    }
    
	response.templateString = [self.portal stringForPath:@"keyroisimages.html"];
	response.mimeType = @"text/html";
}

-(void)processSeriesHtml
{
    DicomSeries *series = nil;
    
    NSManagedObject* oxid = [self objectWithXID:[parameters objectForKey:@"xid"]];
    if ([oxid isKindOfClass:[DicomSeries class]])
    {
        series = (DicomSeries*) oxid;
        
        if( series == nil)
            return;
        
        [response.tokens setObject:[WebPortalProxy createWithObject:series transformer:[DicomSeriesTransformer create]] forKey:@"Series"];
        [response.tokens setObject:[NSString stringWithFormat: @"%@ - %@", series.name, series.id.stringValue] forKey:@"PageTitle"];
        [response.tokens setObject:[NSString stringWithFormat:@"%@ - %@", series.study.name, series.study.studyName] forKey:@"BackLinkLabel"];
    }
    
	response.templateString = [self.portal stringForPath:@"series.html"];
	response.mimeType = @"text/html";
}

- (void) sendEmailOnMainThread: (NSDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *ts = [dict objectForKey: @"template"];
	NSDictionary *messageHeaders = [dict objectForKey: @"headers"];
	
	[[CSMailMailClient mailClient] deliverMessage:ts headers:messageHeaders];
    
	[pool release];
}

-(void)processPasswordForgottenHtml {
	if (!self.portal.passwordRestoreAllowed)
		return;
	
	if ([[parameters valueForKey:@"action"] isEqualToString:@"restorePassword"])
	{
		NSString* email = [parameters valueForKey: @"email"];
		NSString* username = [parameters valueForKey: @"username"];
		
		// TRY TO FIND THIS USER
		if ([email length] > 0 || [username length] > 0)
        {
            WebPortalDatabase *db = self.portal.database.independentDatabase;
            
			@try
			{
                NSPredicate* predicate = nil;
				if ([email length] > [username length])
					predicate = [NSPredicate predicateWithFormat: @"(email BEGINSWITH[cd] %@) AND (email ENDSWITH[cd] %@)", email, email];
				else predicate = [NSPredicate predicateWithFormat: @"(name BEGINSWITH[cd] %@) AND (name ENDSWITH[cd] %@)", username, username];
				
				NSArray *users = [db objectsForEntity: db.userEntity predicate:predicate];
				
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
						
                        NSString *webPortalDefaultTitle = [[NSUserDefaults standardUserDefaults] stringForKey: @"WebPortalTitle"];
                        if( webPortalDefaultTitle.length == 0)
                            webPortalDefaultTitle = NSLocalizedString(@"OsiriX Web Portal", @"Web Portal, general default title");
                        
                        [emailMessage appendString: webPortalDefaultTitle];
                        [emailMessage appendString: @"<br><br>"];
                        [emailMessage appendString: @"<br><br>"];
                        
						[emailMessage appendString: NSLocalizedString( @"Username:<br><br>", nil)];
						[emailMessage appendString: u.name];
						[emailMessage appendString: @"<br><br>"];
						[emailMessage appendString: NSLocalizedString( @"Password:<br><br>", nil)];
						[emailMessage appendString: u.password];
						[emailMessage appendString: @"<br><br>"];
                        [emailMessage appendString: @"<br><br>"];
                        [emailMessage appendString: NSLocalizedString( @"Login here:<br>", nil)];
                        [emailMessage appendString: self.portal.URL];
                        
						[self.portal updateLogEntryForStudy: nil withMessage: @"Password reset for user" forUser:u.name ip: nil];
						
                        NSDictionary *messageHeaders = [NSDictionary dictionaryWithObjectsAndKeys: u.email, @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", nil];
                        
                        // NSAttributedString initWithHTML is NOT thread-safe
                        [self performSelectorOnMainThread: @selector(sendEmailOnMainThread:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: emailMessage, @"template", messageHeaders, @"headers", nil] waitUntilDone: NO];
                        
						[response.tokens addMessage:NSLocalizedString(@"You will shortly receive an email with your new password.", nil)];
						
						[db save:NULL];
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
		}
	}
	
	[response.tokens setObject:NSLocalizedString(@"Forgotten Password", @"Web portal, password forgotten, title") forKey:@"PageTitle"];
	response.templateString = [self.portal stringForPath:@"password_forgotten.html"];
	response.mimeType = @"text/html";
}


-(void)processAccountHtml
{
	if (!self.user)
		return;
	
	if ([[parameters valueForKey:@"action"] isEqualToString:@"changePassword"])
    {
		NSString * password = [parameters valueForKey: @"password"];
		NSString * sha1 = [parameters objectForKey:@"sha1"];
        
        [user convertPasswordToHashIfNeeded];
        
        NSString* sha1internal = user.passwordHash;
        
        if( [sha1internal length] > 0 && [sha1 compare:sha1internal options:NSLiteralSearch|NSCaseInsensitiveSearch] == NSOrderedSame)
        {
			if ([[parameters valueForKey:@"password"] isEqualToString:[parameters valueForKey:@"password2"]])
			{
				NSError* err = NULL;
				if (![user validatePassword:&password error:&err])
					[response.tokens addError:err.localizedDescription];
				else
                {
					// We can update the user password
					
                    //					if( [previouspassword isEqualToString: @"public"] && [self.user.name isEqualToString:@"public"])
                    //					{
                    //						// public / public demo account not editable
                    //						[response.tokens addMessage:NSLocalizedString(@"Public account not editable!", nil)];
                    //					}
                    //					else
					{
						user.password = password;
                        
                        [user convertPasswordToHashIfNeeded];
                        
						[user.managedObjectContext save:NULL];
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
	
	if ([[parameters valueForKey:@"action"] isEqualToString:@"changeSettings"])
    {
		user.email = [parameters valueForKey:@"email"];
		user.address = [parameters valueForKey:@"address"];
		user.phone = [parameters valueForKey:@"phone"];
		
		if ([[[parameters valueForKey:@"emailNotification"] lowercaseString] isEqualToString:@"on"])
			user.emailNotification = [NSNumber numberWithBool:YES];
		else user.emailNotification = [NSNumber numberWithBool: NO];
        
        if ([[[parameters valueForKey:@"showRecentPatients"] lowercaseString] isEqualToString:@"on"])
			user.showRecentPatients = [NSNumber numberWithBool:YES];
		else user.showRecentPatients = [NSNumber numberWithBool: NO];
		
		[user.managedObjectContext save: nil];
		
		[response.tokens addMessage:NSLocalizedString(@"Personal information updated successfully!", nil)];
	}
	
	[response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"Account information for: %@", @"Web portal, account, title format (%@ is user.name)"), user.name] forKey:@"PageTitle"];
	response.templateString = [self.portal stringForPath:@"account.html"];
	response.mimeType = @"text/html";
}

#pragma mark Administration HTML

-(void)processAdminIndexHtml {
	if (!user.isAdmin.boolValue) {
		response.statusCode = 401;
		[self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to access admin area without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
		return;
	}
	
	[response.tokens setObject:NSLocalizedString(@"Administration", @"Web Portal, admin, index, title") forKey:@"PageTitle"];
    
    WebPortalDatabase *idatabase = [self.portal.database independentDatabase];
	[response.tokens setObject:[[idatabase objectsForEntity:idatabase.userEntity] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]] forKey:@"Users"];
	
	response.templateString = [self.portal stringForPath:@"admin/index.html"];
	response.mimeType = @"text/html";
}

-(void)processAdminUserHtml {
	if (!user.isAdmin.boolValue) {
		response.statusCode = 401;
		[self.portal updateLogEntryForStudy:NULL withMessage:@"Attempt to access admin area without being an admin" forUser:user.name ip:asyncSocket.connectedHost];
		return;
	}
    
	NSObject* luser = NULL;
	BOOL userRecycleParams = NO;
	NSString* action = [parameters objectForKey:@"action"];
	NSString* originalName = NULL;
	
    WebPortalDatabase *idatabase = [self.portal.database independentDatabase];
    
	if ([action isEqualToString:@"delete"])
    {
		originalName = [parameters objectForKey:@"originalName"];
		NSManagedObject* tempUser = [idatabase userWithName:originalName];
		if (!tempUser)
			[response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't delete user <b>%@</b> because he doesn't exist.", @"Web Portal, admin, user edition, delete error (%@ is user.name)"), originalName]];
		else {
			[idatabase.managedObjectContext deleteObject:tempUser];
			[idatabase save:NULL];
			[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"User <b>%@</b> successfully deleted.", @"Web Portal, admin, user edition, delete ok (%@ is user.name)"), originalName]];
		}
	}
	
	if ([action isEqualToString:@"save"]) {
		originalName = [parameters objectForKey:@"originalName"];
		WebPortalUser* webUser = [idatabase userWithName:originalName];
		if (!webUser) {
			[response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't save changes for user <b>%@</b> because he doesn't exist.", @"Web Portal, admin, user edition, save error (%@ is user.name)"), originalName]];
			userRecycleParams = YES;
		} else {
			// NSLog(@"SAVE params: %@", parameters.description);
			
			NSString* name = [[parameters objectForKey:@"name"] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString* newPassword = [[parameters objectForKey:@"newPassword"] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString* newPassword2 = [[parameters objectForKey:@"newPassword2"] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString* studyPredicate = [parameters objectForKey:@"studyPredicate"];
			NSNumber* downloadZIP = [NSNumber numberWithBool:[[parameters objectForKey:@"downloadZIP"] isEqualToString:@"on"]];
			
			NSError* err;
			
			err = NULL;
			if (![webUser validateName:&name error:&err])
				[response.tokens addError:err.localizedDescription];
			err = NULL;
            
			if ( newPassword.length > 0 && ![webUser validatePassword:&newPassword error:&err])
				[response.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateStudyPredicate:&studyPredicate error:&err])
				[response.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateDownloadZIP:&downloadZIP error:&err])
				[response.tokens addError:err.localizedDescription];
			
            if( newPassword.length > 0 && [newPassword isEqualToString: newPassword2] == NO)
                [response.tokens addError: NSLocalizedString( @"Passwords are not identical.", nil)];
            
			if (!response.tokens.errors.count)
            {
                if( newPassword.length > 0 && [newPassword isEqualToString: newPassword2])
                {
                    if( [webUser.name isEqualToString: name] == NO)
                        webUser.name = name;
                    
                    webUser.password = newPassword;
                    [webUser convertPasswordToHashIfNeeded];
                }
                else
                {
                    if( [webUser.name isEqualToString: name] == NO)
                    {
                        webUser.name = name;
                        [response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"User's name has changed. The password has been reset to a new password: %@", nil), webUser.password]];
                        [webUser convertPasswordToHashIfNeeded];
                    }
                }
                
                webUser.email = [parameters objectForKey:@"email"];
				webUser.phone = [parameters objectForKey:@"phone"];
				webUser.address = [parameters objectForKey:@"address"];
				webUser.studyPredicate = studyPredicate;
				
				webUser.autoDelete = [NSNumber numberWithBool:[[parameters objectForKey:@"autoDelete"] isEqualToString:@"on"]];
				webUser.downloadZIP = downloadZIP;
				webUser.emailNotification = [NSNumber numberWithBool:[[parameters objectForKey:@"emailNotification"] isEqualToString:@"on"]];
                webUser.showRecentPatients = [NSNumber numberWithBool:[[parameters objectForKey:@"showRecentPatients"] isEqualToString:@"on"]];
				webUser.encryptedZIP = [NSNumber numberWithBool:[[parameters objectForKey:@"encryptedZIP"] isEqualToString:@"on"]];
				webUser.uploadDICOM = [NSNumber numberWithBool:[[parameters objectForKey:@"uploadDICOM"] isEqualToString:@"on"]];
				webUser.downloadReport = [NSNumber numberWithBool:[[parameters objectForKey:@"downloadReport"] isEqualToString:@"on"]];
                webUser.sendDICOMtoSelfIP = [NSNumber numberWithBool:[[parameters objectForKey:@"sendDICOMtoSelfIP"] isEqualToString:@"on"]];
				webUser.uploadDICOMAddToSpecificStudies = [NSNumber numberWithBool:[[parameters objectForKey:@"uploadDICOMAddToSpecificStudies"] isEqualToString:@"on"]];
				webUser.sendDICOMtoAnyNodes = [NSNumber numberWithBool:[[parameters objectForKey:@"sendDICOMtoAnyNodes"] isEqualToString:@"on"]];
				webUser.shareStudyWithUser = [NSNumber numberWithBool:[[parameters objectForKey:@"shareStudyWithUser"] isEqualToString:@"on"]];
                webUser.createTemporaryUser = [NSNumber numberWithBool:[[parameters objectForKey:@"createTemporaryUser"] isEqualToString:@"on"]];
				webUser.canAccessPatientsOtherStudies = [NSNumber numberWithBool:[[parameters objectForKey:@"canAccessPatientsOtherStudies"] isEqualToString:@"on"]];
				webUser.canSeeAlbums = [NSNumber numberWithBool:[[parameters objectForKey:@"canSeeAlbums"] isEqualToString:@"on"]];
				
				if (webUser.autoDelete.boolValue)
					webUser.deletionDate = [NSCalendarDate dateWithYear:[[parameters objectForKey:@"deletionDate_year"] integerValue] month:[[parameters objectForKey:@"deletionDate_month"] integerValue]+1 day:[[parameters objectForKey:@"deletionDate_day"] integerValue] hour:0 minute:0 second:0 timeZone:NULL];
				
				NSMutableArray* remainingStudies = [NSMutableArray array];
				for (NSString* studyXid in [[self.parameters objectForKey:@"remainingStudies"] componentsSeparatedByString:@","])
                {
					studyXid = [studyXid.stringByTrimmingStartAndEnd stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
                    if( studyXid.length)
                    {
                        WebPortalStudy* wpStudy = NULL;
                        // this is Mac OS X 10.6 SnowLeopard only // wpStudy = [webUser.managedObjectContext existingObjectWithID:[webUser.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:studyObjectID]] error:NULL];
                        for (WebPortalStudy* iwpStudy in webUser.studies)
                            if ([iwpStudy.XID isEqualToString:studyXid])
                            {
                                wpStudy = iwpStudy;
                                break;
                            }
                        
                        if (wpStudy)
                            [remainingStudies addObject:wpStudy];
                        else
                            NSLog(@"Warning: Web Portal user %@ is referencing a study with CoreData ID %@, which doesn't exist", self.user.name, studyXid);
                    }
                }
				for (WebPortalStudy* iwpStudy in webUser.studies.allObjects)
					if (![remainingStudies containsObject:iwpStudy])
						[webUser removeStudiesObject:iwpStudy];
				
				[idatabase save:NULL];
				
				[response.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Changes for user <b>%@</b> successfully saved.", nil), webUser.name]];
				luser = webUser;
			} else
				userRecycleParams = YES;
		}
	}
	
	if ([action isEqualToString:@"new"]) {
		luser = [idatabase newUser];
	}
	
	if (!action) { // edit
		originalName = [self.parameters objectForKey:@"name"];
		luser = [idatabase userWithName:originalName];
		if (!luser)
			[response.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't find user with name <b>%@</b>.", nil), originalName]];
	}
	
	[response.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"User Administration: %@", nil), luser? [luser valueForKey:@"name"] : originalName] forKey:@"PageTitle"];
	if (luser)
		[response.tokens setObject:[WebPortalProxy createWithObject:luser transformer:[WebPortalUserTransformer create]] forKey:@"EditedUser"];
	else if (userRecycleParams) [response.tokens setObject:self.parameters forKey:@"EditedUser"];
	
	response.templateString = [self.portal stringForPath:@"admin/user.html"];
	response.mimeType = @"text/html";
}

#pragma mark JSON

-(void)processStudyListJson {
	NSArray* studies = [self studyList_requestedStudies:NULL];
	
    //	[self.portal.dicomDatabase.managedObjectContext lock];
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
        //		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
}

-(void)processSeriesJson {
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"]];
	if (!series)
		return;
    
	NSArray* imagesArray = series.images.allObjects;
	@try { // Sort images with "instanceNumber"
		NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
		NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
		[sort release];
		imagesArray = [imagesArray sortedArrayUsingDescriptors: sortDescriptors];
	} @catch (NSException* e) { /* ignore */ }
	
	
    //	[self.portal.dicomDatabase.managedObjectContext lock];
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
        //		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
}

-(void)processAlbumsJson {
	NSMutableArray* jsonAlbumsArray = [NSMutableArray array];
	
	for (DicomAlbum* album in [self.independentDicomDatabase albums])
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
	DicomStudy* study = [self objectWithXID:[parameters objectForKey:@"xid"]];
	if (!study)
		return;
	
	NSMutableArray *jsonSeriesArray = [NSMutableArray array];
	
    //	[self.portal.dicomDatabase.managedObjectContext lock];
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
        //		[self.portal.dicomDatabase.managedObjectContext unlock];
	}
	
	[response setDataWithString:[jsonSeriesArray JSONRepresentation]];
}


#pragma mark WADO

#ifdef __LP64__
#define WadoCacheSize 1000
#else
#define WadoCacheSize 100
#endif

-(NSMutableDictionary*)wadoCache {
	const NSString* const WadoCacheKey = @"WADO Cache";
    NSMutableDictionary* dict = nil;
    @synchronized( self.portal.cache)
    {
        dict = [self.portal.cache objectForKey:WadoCacheKey];
        if (!dict || ![dict isKindOfClass: [NSMutableDictionary class]])
            [self.portal.cache setObject: dict = [NSMutableDictionary dictionaryWithCapacity:WadoCacheSize] forKey:WadoCacheKey];
	}
    return dict;
}

#define WadoSOPInstanceUIDCacheSize 5000

-(NSMutableDictionary*)wadoSOPInstanceUIDCache
{
	const NSString* const WadoSOPInstanceUIDCacheKey = @"WADO SOPInstanceUID Cache";
    NSMutableDictionary* dict = nil;
    @synchronized( self.portal.cache)
    {
        dict = [self.portal.cache objectForKey:WadoSOPInstanceUIDCacheKey];
        if (!dict || ![dict isKindOfClass:[NSMutableDictionary class]])
            [self.portal.cache setObject: dict = [NSMutableDictionary dictionaryWithCapacity:WadoSOPInstanceUIDCacheSize] forKey:WadoSOPInstanceUIDCacheKey];
    }
	return dict;
}

// wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX
// 127.0.0.1:3333/wado?requestType=WADO&frameNumber=1&studyUID=2.16.840.1.113669.632.20.1211.10000591592&seriesUID=1.3.6.1.4.1.19291.2.1.2.2867252960399100001&objectUID=1.3.6.1.4.1.19291.2.1.3.2867252960616100004
-(void)processWado
{
	if (!self.portal.wadoEnabled)
    {
		self.response.statusCode = 403;
		[self.response setDataWithString:NSLocalizedString(@"OsiriX cannot fulfill your request because the WADO service is disabled.", NULL)];
		return;
	}
	
	if (![[[parameters objectForKey:@"requestType"] lowercaseString] isEqualToString:@"wado"])
    {
		self.response.statusCode = 404;
		return;
	}
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"wadoRequestRequireValidToken"])
    {
        NSString* token = [parameters objectForKey:@"token"];
        
        BOOL tokenFound = NO;
        
        for (WebPortalSession* isession in [self.portal sessions])
        {
            if( [isession containsToken:token])
            {
                tokenFound = YES;
                break;
            }
        }
        
        if( tokenFound == NO)
        {
            if( [[parameters objectForKey:@"studyUID"] length] == 0 || [[parameters objectForKey:@"seriesUID"] length] == 0 || [[parameters objectForKey:@"objectUID"] length] == 0)
            {
                [NSThread sleepForTimeInterval: 1];
                self.response.statusCode = 401;
                [self.response setDataWithString:NSLocalizedString(@"Unauthorized WADO access - no valid token or incomplete request", NULL)];
                return;
            }
        }
    }
	
	NSString* studyUID = [parameters objectForKey:@"studyUID"];
	NSString* seriesUID = [parameters objectForKey:@"seriesUID"];
	NSString* objectUID = [parameters objectForKey:@"objectUID"];
	
	if (objectUID == nil && (seriesUID.length > 0 || studyUID.length > 0)) // This is a 'special case', not officially supported by DICOM standard : we take all the series or study objects -> zip them -> send them
	{
        DicomStudy *study = [self studyForStudyInstanceUID: studyUID server: nil];
        
        NSArray *allSeries = [[study valueForKey: @"series"] allObjects];
		
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
            
            destFile = [destFile stringByAppendingFormat:@"-%d", uniqueInc++];
			destFile = [destFile stringByAppendingPathExtension:@"osirixzip"];
			
			if (srcFolder)
				[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
			if (destFile)
				[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
			
			[NSFileManager.defaultManager confirmDirectoryAtPath:srcFolder];
			
			[BrowserController encryptFiles: [allImages valueForKey:@"completePath"] inZIPFile:destFile password: user.encryptedZIP.boolValue? user.password : NULL ];
            
			self.response.data = [NSData dataWithContentsOfFile:destFile];
			self.response.statusCode = 0;
			[self.response setMimeType: @"application/osirixzip"];
			
			if (srcFolder)
				[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
			if (destFile)
				[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
            
            [self.portal updateLogEntryForStudy:study withMessage: @"WADO Send" forUser:user.name ip:asyncSocket.connectedHost];
            
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
	dbRequest.entity = self.independentDicomDatabase.studyEntity;
	
	@try
    {
		NSMutableDictionary *imageCache = nil;
		NSArray *images = nil;
		
        @synchronized( self.wadoCache)
        {
            if (self.wadoCache.count > WadoCacheSize)
                [self.wadoCache removeAllObjects];
        }
        
        @synchronized( self.wadoSOPInstanceUIDCache)
        {
            if( self.wadoSOPInstanceUIDCache.count > WadoSOPInstanceUIDCacheSize)
                [self.wadoSOPInstanceUIDCache removeAllObjects];
		}
        
		NSString *cachedPathForSOPInstanceUID = nil;
		
		if (contentType.length == 0 || [contentType isEqualToString:@"image/jpeg"] || [contentType isEqualToString:@"image/png"] || [contentType isEqualToString:@"image/gif"] || [contentType isEqualToString:@"image/jp2"])
        {
			@synchronized( self.wadoCache)
            {
                imageCache = [self.wadoCache objectForKey:[objectUID stringByAppendingFormat:@"%d", frameNumber]];
            }
        }
		else if( [contentType isEqualToString: @"application/dicom"])
        {
			@synchronized( self.wadoSOPInstanceUIDCache)
            {
                cachedPathForSOPInstanceUID = [self.wadoSOPInstanceUIDCache objectForKey: objectUID];
            }
        }
        
		if (!imageCache && !cachedPathForSOPInstanceUID)
		{
			NSPredicate* predicate1 = nil;
            if (studyUID)
				predicate1 = [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID];
            
			NSArray* studies = [self.independentDicomDatabase objectsForEntity:self.independentDicomDatabase.studyEntity predicate:predicate1];
			
			if ([studies count] == 0)
				NSLog( @"****** WADO Server : study not found");
			
			if ([studies count] > 1)
				NSLog( @"****** WADO Server : more than 1 study with same uid : %d", (int) studies.count);
			
            NSArray *allSeries = [NSArray array];
            
            for( DicomStudy *s in studies)
                allSeries = [allSeries arrayByAddingObjectsFromArray: [[s valueForKey: @"series"] allObjects]];
			
			if (seriesUID && studyUID == nil) // If a studyUID is specified, take all seriesUID (OsiriX can merge multiple seriesUID: combine CR, for example...)
				allSeries = [allSeries filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", seriesUID]];
			
			NSArray *allImages = [NSArray array];
			for ( id series in allSeries)
				allImages = [allImages arrayByAddingObjectsFromArray: [[series valueForKey: @"images"] allObjects]];
			
			//We will cache all the paths for these sopInstanceUIDs
            
            @synchronized( self.wadoSOPInstanceUIDCache)
            {
                for( DicomImage *image in allImages)
                    [self.wadoSOPInstanceUIDCache setObject: image.completePath forKey: image.sopInstanceUID];
			}
            
			NSPredicate* predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: objectUID]] customSelector: @selector(isEqualToSopInstanceUID:)];
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
                @autoreleasepool
                {
                    DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS: transferSyntax] autorelease];
                    
                    if( [useOrig boolValue] == 1 || ts == nil || [ts.name isEqualToString: @"Unknown Syntax"])
                    {
                        response.data = [NSData dataWithContentsOfFile: cachedPathForSOPInstanceUID];
                    }
                    else
                    {
                        if ([ts isEqualToTransferSyntax: [DCMTransferSyntax JPEG2000LosslessTransferSyntax]] ||
                            [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEG2000LossyTransferSyntax]] ||
                            [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGBaselineTransferSyntax]] ||
                            [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGLossless14TransferSyntax]] ||
                            [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGLSLosslessTransferSyntax]] ||
                            [ts isEqualToTransferSyntax: [DCMTransferSyntax JPEGLSLossyTransferSyntax]] ||
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
					NSString *path = [WebPortalConnection tmpDirPath];
					[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
					
					NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"xid"]];
					name = [name stringByAppendingFormat:@"-WADOMpeg-%d", (int) [dicomImageArray count]];
					
					NSMutableString *fileName = [NSMutableString stringWithString: [path stringByAppendingPathComponent:name]];
					
					[BrowserController replaceNotAdmitted: fileName];
					
					[fileName appendString:@".mov"];
					
					NSString *outFile;
					if (self.requestIsIOS)
						outFile = [NSString stringWithFormat:@"%@2.mp4", [fileName stringByDeletingPathExtension]];
					else
						outFile = fileName;
					
					NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: /*[NSNumber numberWithBool: self.requestIsIOS], GenerateMovieIsIOSParamKey,*/ /*fileURL, @"fileURL",*/ fileName, GenerateMovieFileNameParamKey, outFile, GenerateMovieOutFileParamKey, parameters, @"parameters", dicomImageArray, GenerateMovieDicomImagesParamKey, [NSNumber numberWithInt: rows], @"rows", [NSNumber numberWithInt: columns], @"columns", nil];
					
					[self generateMovie:dict];
					
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
					
                    @synchronized( self.wadoCache)
                    {
                        [self.wadoCache setObject: imageCache forKey: [objectUID stringByAppendingFormat: @"%d", frameNumber]];
                    }
                }
				
				if (dcmPix)
				{
					NSImage *image = nil;
					NSManagedObject *im =  [self.independentDicomDatabase objectWithID: [dcmPix imageObjectID]];
					
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
//					NSData *noData = self.response.data;
                    self.response.statusCode = 0;
				}
			}
		}
		else
			NSLog( @"****** WADO Server : image uid not found ! %@", objectUID);
		
		if (!self.response.data)
			self.response.data = [NSData data];
        
	}
    @catch (NSException * e)
    {
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
	
	response.templateString = [self.portal stringForPath:@"weasis.jnlp"];
	response.mimeType = @"application/x-java-jnlp-file";
}

-(void)processWeasisXml {
	if (!self.portal.weasisEnabled) {
		response.statusCode = 404;
		return;
	}
	
	// find requested core data objects
    
	NSMutableArray* requestedStudies = [NSMutableArray arrayWithCapacity:8];
	NSMutableArray* requestedSeries = [NSMutableArray arrayWithCapacity:64];
	
	NSString* xid = [parameters objectForKey:@"xid"];
	NSArray* selection = xid? [NSArray arrayWithObject:xid] : [WebPortalConnection MakeArray:[parameters objectForKey:@"selected"]];
	for (xid in selection) {
		NSManagedObject* oxid = [self objectWithXID:xid];
		if ([oxid isKindOfClass:[DicomStudy class]])
			[requestedStudies addObject:oxid];
		if ([oxid isKindOfClass:[DicomSeries class]])
			[requestedSeries addObject:oxid];
	}
    
	// extend arrays
	
	NSMutableArray* studies = [NSMutableArray arrayWithCapacity:8];
	NSMutableArray* series = [NSMutableArray arrayWithCapacity:64];
	
	for (DicomStudy* study in requestedStudies) {
		if (![studies containsObject:study])
			[studies addObject:study];
		for (DicomSeries* serie in study.series)
			if (![series containsObject:serie])
				[series addObject:serie];
	}
	
	for (DicomSeries* serie in requestedSeries) {
		if (![studies containsObject:serie.study])
			[studies addObject:serie.study];
		if (![series containsObject:serie])
			[series addObject:serie];
	}
	
	// filter by user rights
	if( self.user)
    {
        NSArray *authorizedStudies = [WebPortalUser studiesForUser: self.user predicate:nil sortBy:nil];
        
        for( int i = (long)studies.count-1; i >= 0; i--)
        {
            BOOL authorized = NO;
            DicomStudy *currentStudy = [studies objectAtIndex: i];
            
            for( DicomStudy *s in authorizedStudies)
            {
                if( [[s XID] isEqualToString: currentStudy.XID])
                {
                    authorized = YES;
                    break;
                }
            }
            
            if( authorized == NO)
            {
                NSLog( @"******** Trying to load a not authorized study through a Weasis JNLP request? %@", [studies objectAtIndex: i]);
                [studies removeObjectAtIndex: i];
            }
        }
	}
    
    
    // We need the TRUE DICOM informations: re-parse the DICOM objects... if preferences such as Combine CR, split MG, ... are activated
    
    NSMutableArray *imageObjects = [NSMutableArray array];
    
    for( DicomSeries *serie in series)
        [imageObjects addObjectsFromArray: serie.images.allObjects];
    
    NSMutableArray *imagePaths = [NSMutableArray arrayWithArray: [imageObjects valueForKey:@"completePath"]];
    
    [imagePaths removeDuplicatedStrings];
    
    NSMutableDictionary* patientDictionary = [NSMutableDictionary dictionary];
    
    NSMutableArray* dcmFiles = [NSMutableArray array];
    
    for( NSString *path in imagePaths)
    {
        DicomFile *dcmFile = [[[DicomFile alloc] init: path DICOMOnly: YES] autorelease];
        
        if( dcmFile)
        {
            [dcmFiles addObject: dcmFile];
            
            NSMutableDictionary *patient = nil;
            NSMutableDictionary *study = nil;
            NSMutableDictionary *series = nil;
            
            if( [dcmFile elementForKey: @"patientID"] && [patientDictionary objectForKey: [dcmFile elementForKey: @"patientID"]] == nil)
                [patientDictionary setObject: [NSMutableDictionary dictionary] forKey: [dcmFile elementForKey: @"patientID"]];
            
            patient = [patientDictionary objectForKey: [dcmFile elementForKey: @"patientID"]];
            
            if( [dcmFile elementForKey: @"studyID"] && [patient objectForKey: [dcmFile elementForKey: @"studyID"]] == nil)
                [patient setObject: [NSMutableDictionary dictionary] forKey: [dcmFile elementForKey: @"studyID"]];
            
            study = [patient objectForKey: [dcmFile elementForKey: @"studyID"]];
            
            if( [dcmFile elementForKey: @"seriesDICOMUID"] && [study objectForKey: [dcmFile elementForKey: @"seriesDICOMUID"]] == nil)
                [study setObject: [NSMutableDictionary dictionary] forKey: [dcmFile elementForKey: @"seriesDICOMUID"]];
            
            series = [study objectForKey: [dcmFile elementForKey: @"seriesDICOMUID"]];
            
            if( [dcmFile elementForKey: @"SOPUID"])
                [series setObject: dcmFile forKey: [dcmFile elementForKey: @"SOPUID"]];
        }
    }
    
	// produce XML
	NSString* baseXML = nil;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"wadoOnlyServer"])
        baseXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><wado_query xmlns=\"http://www.weasis.org/xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" wadoURL=\"%@/wado\"></wado_query>", [[WebPortal wadoOnlyWebPortal] URL]];
    else
        baseXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><wado_query xmlns=\"http://www.weasis.org/xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" wadoURL=\"%@/wado\"></wado_query>", self.portalURL];
    
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:baseXML options:NSXMLDocumentIncludeContentTypeDeclaration|NSXMLDocumentTidyXML error:NULL];
	[doc setCharacterEncoding:@"UTF-8"];
	
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	dateFormatter.dateFormat = @"yyyyMMdd";
	NSDateFormatter* timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	timeFormatter.dateFormat = @"HHmmss";
	
	for (NSString* patientId in [patientDictionary allKeys])
    {
		NSXMLElement* patientNode = [NSXMLNode elementWithName:@"Patient"];
		[patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientID" stringValue:patientId]];
		BOOL patientDataSet = NO;
		[doc.rootElement addChild:patientNode];
		
		for (NSDictionary *studies in [[patientDictionary valueForKey: patientId] allValues])
        {
            DicomFile *dcmFile = [[[[studies allValues] lastObject] allValues] lastObject];
            
            @try
            {
                NSXMLElement* studyNode = [NSXMLNode elementWithName:@"Study"];
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyInstanceUID" stringValue: [dcmFile elementForKey: @"studyID"]]];
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyDescription" stringValue: [dcmFile elementForKey: @"studyDescription"]]];
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyDate" stringValue: [dcmFile elementForKey: @"studyDate"]]];
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyTime" stringValue: [dcmFile elementForKey: @"studyDate"]]];
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"AccessionNumber" stringValue: [dcmFile elementForKey: @"accessionNumber"]]];
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"StudyID" stringValue: [dcmFile elementForKey: @"studyID"]]]; // ?
                [studyNode addAttribute:[NSXMLNode attributeWithName:@"ReferringPhysicianName" stringValue: [dcmFile elementForKey: @"referringPhysiciansName"]]];
                [patientNode addChild:studyNode];
                
                for (NSDictionary* serie in [studies allValues])
                {
                    dcmFile = [[serie allValues] lastObject];
                    
                    NSXMLElement* serieNode = [NSXMLNode elementWithName:@"Series"];
                    [serieNode addAttribute:[NSXMLNode attributeWithName:@"SeriesInstanceUID" stringValue: [dcmFile elementForKey: @"seriesDICOMUID"]]];
                    [serieNode addAttribute:[NSXMLNode attributeWithName:@"SeriesDescription" stringValue: [dcmFile elementForKey: @"seriesDescription"]]];
                    [serieNode addAttribute:[NSXMLNode attributeWithName:@"SeriesNumber" stringValue: [[dcmFile elementForKey: @"seriesNumber"] stringValue]]];
                    [serieNode addAttribute:[NSXMLNode attributeWithName:@"Modality" stringValue: [dcmFile elementForKey: @"modality"]]];
                    [studyNode addChild:serieNode];
                    
                    for( DicomFile* dcmFile in [serie allValues])
                    {
                        NSXMLElement* instanceNode = [NSXMLNode elementWithName:@"Instance"];
                        [instanceNode addAttribute:[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue: [dcmFile elementForKey: @"SOPUID"]]];
                        [instanceNode addAttribute:[NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[[dcmFile elementForKey: @"imageID"] stringValue]]];
                        [serieNode addChild:instanceNode];
                    }
                }
                
                if (!patientDataSet)
                {
                    [patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientName" stringValue: [dcmFile elementForKey: @"patientName"]]];
                    [patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientBirthDate" stringValue: [dcmFile elementForKey: @"patientBirthDate"]]];
                    [patientNode addAttribute:[NSXMLNode attributeWithName:@"PatientSex" stringValue: [dcmFile elementForKey: @"patientSex"]]];
                }
            }
            @catch (NSException *exception) {
                N2LogException( exception);
            }
        }
	}
	
	[response setDataWithString:[[doc autorelease] XMLString]];
	response.mimeType = @"text/xml";
}

#pragma mark Other

-(void)processReport {
	DicomStudy* study = [self objectWithXID:[parameters objectForKey:@"xid"]];
	if (!study)
		return;
	
	[self.portal updateLogEntryForStudy:study withMessage: @"View Report" forUser:user.name ip:asyncSocket.connectedHost];
	
//	NSString *reportFilePath = study.reportURL;
	
    NSString *tmpFile = [study saveReportAsPdfInTmp];
    
    response.data = [NSData dataWithContentsOfFile: tmpFile];
    
    [[NSFileManager defaultManager] removeFileAtPath: tmpFile handler:nil];
    
    //	NSString *reportType = [reportFilePath pathExtension];
    //
    //	if ([reportType isEqualToString: @"pages"])
    //	{
    //		NSString* zipFileName = [NSString stringWithFormat:@"%@.zip", [reportFilePath lastPathComponent]];
    //		// zip the directory into a single archive file
    //		NSTask *zipTask   = [[NSTask alloc] init];
    //		[zipTask setLaunchPath:@"/usr/bin/zip"];
    //		[zipTask setCurrentDirectoryPath:[[reportFilePath stringByDeletingLastPathComponent] stringByAppendingString:@"/"]];
    //		if ([reportType isEqualToString:@"pages"])
    //			[zipTask setArguments:[NSArray arrayWithObjects: @"-q", @"-r" , zipFileName, [reportFilePath lastPathComponent], nil]];
    //		else
    //			[zipTask setArguments:[NSArray arrayWithObjects: zipFileName, [reportFilePath lastPathComponent], nil]];
    //		[zipTask launch];
    //		while( [zipTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
    //		int result = [zipTask terminationStatus];
    //		[zipTask release];
    //
    //		if (result==0)
    //			reportFilePath = [[reportFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:zipFileName];
    //
    //		response.data = [NSData dataWithContentsOfFile: reportFilePath];
    //
    //		[[NSFileManager defaultManager] removeFileAtPath:reportFilePath handler:nil];
    //	}
    //	else
    //	{
    //		response.data = [NSData dataWithContentsOfFile: reportFilePath];
    //	}
}

-(NSMutableDictionary*)thumbnailsCache {
    
    @synchronized( self.portal.cache)
    {
        const NSString* const ThumbsCacheKey = @"Thumbnails Cache";
        NSMutableDictionary* dict = [self.portal.cache objectForKey:ThumbsCacheKey];
        if (!dict || ![dict isKindOfClass:[NSMutableDictionary class]])
            [self.portal.cache setObject: dict = [NSMutableDictionary dictionary] forKey:ThumbsCacheKey];
        
        return dict;
    }
    
    return nil;
}

-(void)processThumbnail {
	NSString* xid = [parameters objectForKey:@"xid"];
	
    NSData* data = nil;
    @synchronized( self.portal.cache)
    {
        // is cached?
        data = [self.thumbnailsCache objectForKey:xid];
        if (data) {
            response.data = data;
            return;
        }
	}
    
	// create it
	
	id object = [self objectWithXID:xid];
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
	
	response.mimeType = @"image/png";
	
    @synchronized( self.portal.cache)
    {
        if (data)
        {
#define MAX_ThumbnailsCacheSize 400
            
            if( [self.thumbnailsCache count] > MAX_ThumbnailsCacheSize)
                [self.thumbnailsCache removeAllObjects];
            
            [self.thumbnailsCache setObject:data forKey:xid];
        }
    }
}

-(void)processSeriesPdf {
#ifndef OSIRIX_LIGHT
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"]];
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
			[aTask setArguments:[NSArray arrayWithObjects: @"+X1", @"--unknown-relationship", @"--ignore-constraints", @"--ignore-item-errors", @"--skip-invalid-items", [series.images.anyObject valueForKey:@"completePath"], htmlpath, nil]];
			[aTask launch];
			while( [aTask isRunning])
                [NSThread sleepForTimeInterval: 0.1];
            
            //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
		}
		
		NSString* pdfpath = [htmlpath stringByAppendingPathExtension:@"pdf"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:pdfpath] == NO) {
			NSTask* aTask = [[[NSTask alloc] init] autorelease];
			[aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
			[aTask setArguments:[NSArray arrayWithObjects:htmlpath, @"pdfFromURL", nil]];
			[aTask launch];
            NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
			while( [aTask isRunning] && [NSDate timeIntervalSinceReferenceDate] - start < 10)
                [NSThread sleepForTimeInterval: 0.1];
            
            //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
		}
		
		response.data = [NSData dataWithContentsOfFile:pdfpath];
	}
#endif
}


-(void)processZip {
	NSMutableArray* images = [NSMutableArray array];
	DicomStudy* study = nil;
    
	NSManagedObject* o = [self objectWithXID:[parameters objectForKey:@"xid"]];
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
		destFile = [destFile stringByAppendingFormat:@"-%d", uniqueInc++];
		if (self.requestIsMacOS)
			destFile = [destFile stringByAppendingPathExtension:@"osirixzip"];
		else destFile = [destFile stringByAppendingPathExtension:@"zip"];
		
		if (srcFolder)
			[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
		if (destFile)
			[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
		
		[NSFileManager.defaultManager confirmDirectoryAtPath:srcFolder];
		
        //		[self.portal.dicomDatabase.managedObjectContext unlock];
		[BrowserController encryptFiles:[images valueForKey:@"completePath"] inZIPFile:destFile password: user.encryptedZIP.boolValue? user.password : NULL ];
        //		[self.portal.dicomDatabase.managedObjectContext lock];
        
		response.data = [NSData dataWithContentsOfFile:destFile];
		
		if (srcFolder)
			[NSFileManager.defaultManager removeItemAtPath:srcFolder error:nil];
		if (destFile)
			[NSFileManager.defaultManager removeItemAtPath:destFile error:nil];
	}
	@catch(NSException* e)
    {
		NSLog(@"**** web seriesAsZIP exception : %@", e);
	}
}

- (void) saveImageAsScreenCapture: (NSString*) XID
{
    if( [NSThread isMainThread] == NO)
        NSLog( @"****** we should be on MAIN thread");
    
    DicomImage *dicomImage = [self objectWithXID:[parameters objectForKey:@"xid"]];
    
    [DCMView setCLUTBARS: CLUTBARS ANNOTATIONS: annotGraphics];
    
    BOOL savedSmartCropping = [[NSUserDefaults standardUserDefaults] boolForKey: @"allowSmartCropping"];
    
    [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"allowSmartCropping"];
    
    NSImage *image = [dicomImage imageAsScreenCapture: NSMakeRect(0,0, [[NSUserDefaults standardUserDefaults] integerForKey: @"DicomImageScreenCaptureWidth"],[[NSUserDefaults standardUserDefaults] integerForKey: @"DicomImageScreenCaptureHeight"])];
    
    [DCMView setDefaults];
    [[NSUserDefaults standardUserDefaults] setBool: savedSmartCropping forKey: @"allowSmartCropping"];
    
    NSArray *representations = [image representations];
    NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.8] forKey:NSImageCompressionFactor]];
    
    NSString* path = [[[WebPortalConnection tmpDirPath] stringByAppendingPathComponent: dicomImage.XIDFilename] stringByAppendingPathExtension: @"jpg"];
    [[NSFileManager defaultManager] removeItemAtPath: path error: nil];
    [bitmapData writeToFile: path atomically:YES];
}

-(void)processImageAsScreenCapture: (BOOL) asDisplayed
{
	id object = [self objectWithXID:[parameters objectForKey:@"xid"]];
	if (!object)
		return;
	
	NSArray* images = nil;
	
	if ([object isKindOfClass:[DicomSeries class]])
    {
		images = [[object images] allObjects];
	}
    else if ([object isKindOfClass: [DicomImage class]])
    {
		images = [NSArray arrayWithObject:object];
	}
	
	DicomImage* dicomImage = images.count == 1 ? [images lastObject] : [images objectAtIndex:images.count/2];
	
    if( asDisplayed)
    {
        if ([requestedPath.pathExtension isEqualToString:@"jpg"])
        {
            // waitUntileDone is very risky... cross lock possible ?!
            [self performSelectorOnMainThread: @selector( saveImageAsScreenCapture:) withObject: dicomImage.XID waitUntilDone: YES];
            
            NSString* path = [[[WebPortalConnection tmpDirPath] stringByAppendingPathComponent: dicomImage.XIDFilename] stringByAppendingPathExtension: @"jpg"];
            response.data = [NSData dataWithContentsOfFile: path];
            response.mimeType = @"image/jpeg";
            return;
        }
        else
            N2LogStackTrace( @"*** only JPEG are supported");
    }
    
	DCMPix* dcmPix = [[[DCMPix alloc] initWithPath:dicomImage.completePathResolved :0 :1 :nil :dicomImage.frameID.intValue :dicomImage.series.id.intValue isBonjour:NO imageObj:dicomImage] autorelease];
	
	if (!dcmPix)
		return;
	
	float curWW = 0;
	float curWL = 0;
	
	if (dicomImage.series.windowWidth)
    {
		curWW = dicomImage.series.windowWidth.floatValue;
		curWL = dicomImage.series.windowLevel.floatValue;
	}
	
	if (curWW != 0)
		[dcmPix checkImageAvailble:curWW :curWL];
	else
        [dcmPix checkImageAvailble:dcmPix.savedWW :dcmPix.savedWL];
	
    NSImage* image = [dcmPix image];
	
	NSSize size = image.size;
	[self getWidth:&size.width height:&size.height fromImagesArray:[NSArray arrayWithObject:dicomImage]];
	if (size != image.size)
		image = [image imageByScalingProportionallyToSize:size];
	
	if ([parameters objectForKey:@"previewForMovie"])
    {
		[image lockFocus];
		
		NSImage* r = [NSImage imageNamed:@"PlayTemplate.png"];
		[r drawInRect:NSRectCenteredInRect(NSMakeRect(0,0,r.size.width,r.size.height), NSMakeRect(0,0,image.size.width,image.size.height)) fromRect:NSMakeRect(0,0,r.size.width,r.size.height) operation:NSCompositeSourceOver fraction:1.0];
		
		[image unlockFocus];
	}
    
    if( asDisplayed == NO)
    {
        NSArray *seriesImages = dicomImage.series.sortedImages;
        [image lockFocus];
		[self drawText: [NSString stringWithFormat: @"%d / %d", (int) [seriesImages indexOfObject: dicomImage]+1, (int) seriesImages.count]  atLocation: NSMakePoint( 1, image.size.height - TEXTHEIGHT)];
		[image unlockFocus];
    }
	
	NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
	
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
	if ([requestedPath.pathExtension isEqualToString:@"png"])
    {
		response.data = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
		response.mimeType = @"image/png";
		
	}
    else if ([requestedPath.pathExtension isEqualToString:@"jpg"])
    {
		response.data = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		response.mimeType = @"image/jpeg";
	}
    // else NSLog( @"***** unknown path extension: %@", [fileURL pathExtension]);
}

-(void)processImage
{
    return [self processImageAsScreenCapture: NO];
}

-(void)processMovie
{
	DicomSeries* series = [self objectWithXID:[parameters objectForKey:@"xid"]];
	if (!series)
		return;
	
	response.data = [self produceMovieForSeries:series fileURL:requestedPath];
	
	//if (data == nil || [data length] == 0)
	//	NSLog( @"****** movie data == nil");
}


@end

