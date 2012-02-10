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

#import "XMLRPCMethods.h"
#import "N2ConnectionListener.h"
#import "N2XMLRPCConnection.h"
#import "AppController.h"
#import "N2XMLRPC.h"
#import "NSThread+N2.h"
#import "ThreadsManager.h"
#import "N2Debug.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomAlbum.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "ViewerController.h"
#import "DCMTKRootQueryNode.h"
#import "DCMNetServiceDelegate.h"
#import "DCMView.h"
#import "NSUserDefaults+OsiriX.h"
#import "QueryController.h"
#import "WADODownload.h"
#import "NSManagedObject+N2.h"

@implementation XMLRPCInterface

-(id)init {
	if ((self = [super init])) {
        NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:@"httpXMLRPCServerPort"];
        _listener = [[N2ConnectionListener alloc] initWithPort:port connectionClass:[N2XMLRPCConnection class]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionOpened:) name:N2ConnectionListenerOpenedConnectionNotification object:_listener];
    }
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_listener release]; _listener = NULL;
	[super dealloc];
}

-(void)connectionOpened:(NSNotification*)notification {
	N2XMLRPCConnection* connection = [[notification userInfo] objectForKey:N2ConnectionListenerOpenedConnection];
	[connection setDelegate:self];
}

-(NSError*)errorWithCode:(NSInteger)code {
    NSString* xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%d</value></member></struct></value></param></params></methodResponse>", code];
    return [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:xml forKey:NSLocalizedDescriptionKey]];
}

#pragma mark N2XMLRPCConnectionDelegate

-(NSString*)selectorStringForXMLRPCRequestMethodName:(NSString*)selName {
    selName = [selName lowercaseString];
	if ([selName isEqualToString:@"killosirix"])
        return @"KillOsiriX:error:";
	if ([selName isEqualToString:@"downloadurl"])
        return @"DownloadURL:error:";
	if ([selName isEqualToString:@"displaystudy"])
        return @"DisplayStudy:error:";
    if ([selName isEqualToString:@"displayseries"])
        return @"DisplaySeries:error:";
	if ([selName isEqualToString:@"dbwindowfind"] || [selName isEqualToString:@"findobject"])
        return @"FindObject:error:";
	if ([selName isEqualToString:@"switchtodefaultdbifneeded"])
        return @"SelectDefaultDatabase:error:";
    if ([selName isEqualToString:@"opendb"])
        return @"OpenDatabase:error:";
	if ([selName isEqualToString:@"selectalbum"])
        return @"SelectAlbum:error:";
    if ([selName isEqualToString:@"closeallwindows"])
        return @"CloseAllWindows:error:";
	if ([selName isEqualToString:@"getdisplayed2dviewerseries"])
        return @"GetDisplayed2DViewerSeries:error:";
	if ([selName isEqualToString:@"getdisplayed2dviewerstudies"])
        return @"GetDisplayed2DViewerStudies:error:";
	if ([selName isEqualToString:@"close2dviewerwithseriesuid"])
        return @"Close2DViewerWithSeriesUID:error:";
	if ([selName isEqualToString:@"close2dviewerwithstudyuid"])
        return @"Close2DViewerWithStudyUID:error:";
	if ([selName isEqualToString:@"retrieve"])
        return @"Retrieve:error:";
	if ([selName isEqualToString:@"cmove"])
        return @"CMove:error:";
	if ([selName isEqualToString:@"displaystudylistbypatientname"])
        return @"DisplayStudyListByPatientName:error:";
	if ([selName isEqualToString:@"displaystudylistbypatientid"])
        return @"DisplayStudyListByPatientId:error:";
    if ([selName isEqualToString:@"pathtofrontdcm"])
        return @"PathToFrontDCM:error:";
    return nil;
}

#pragma mark Utilities for exposed methods

-(DicomDatabase*)database {
    return [[BrowserController currentBrowser] database];
}

+(NSDictionary*)dictionaryForObject:(NSManagedObject*)obj {
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    
    for (NSString* key in [obj.entity attributesByName]) {
        id value = [obj valueForKey:key];
        if (value)
            [d setObject:value forKey:key];
    }
    
    return d;
}

-(DicomStudy*)studyForObject:(NSManagedObject*)obj {
    if ([obj isKindOfClass:[DicomStudy class]]) return (id)obj;
    if ([obj isKindOfClass:[DicomSeries class]]) return [obj valueForKey:@"study"];
    if ([obj isKindOfClass:[DicomImage class]]) return [obj valueForKey:@"series.study"];
    return nil;
}

-(NSArray*)objectsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate error:(NSError**)error {
    DicomDatabase* database = [self database];
    
    [database initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
    
    NSArray* independentObjects = [[database independentDatabase] objectsForEntity:[database entityForName:entityName] predicate:predicate error:error];
    
    NSMutableArray* objects = [NSMutableArray arrayWithCapacity:independentObjects.count];
    for (NSManagedObject* independentObject in independentObjects)
        @try {
            [objects addObject:[database.managedObjectContext objectWithID:independentObject.objectID]];
        } @catch (NSException* e) {
            // ignore exception
        }
    
    return objects;
}

#define ReturnWithCode(code) { if (error) *error = [self errorWithCode:code]; return nil; }

#pragma mark Exposed Methods

/**
 Method: KillOsiriX
 */
-(void)KillOsiriX:(NSDictionary*)params error:(NSError**)error {
    [[AppController sharedAppController] performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
}

/**
 Method: DownloadURL

 Parameters:
 URL: any URLs that return a file compatible with OsiriX, including .dcm, .zip, .osirixzip, ...
 Display: display the images at the end of the download? (Optional parameter : it requires a WADO URL, containing the studyUID parameter)

 Example: {URL: "http://127.0.0.1:3333/wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX"}
 Response: {}
 */
-(NSDictionary*)DownloadURL:(NSDictionary*)paramDict error:(NSError**)error {
    @try
    {
        if ([[paramDict valueForKey:@"URL"] length])
        {
            NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(_threadRetrieveWado:) object:paramDict] autorelease];
            t.name = NSLocalizedString(@"WADO Retrieve...", nil);
            t.supportsCancel = YES;
            t.status = [paramDict valueForKey:@"URL"];
            [[ThreadsManager defaultManager] addThreadAndStart:t];
        }
        else 
            ReturnWithCode(400); // Bad Request
    }
    @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    
    return [NSDictionary dictionary];
}

-(void)_threadRetrieveWado:(NSDictionary*)paramDict {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
        NSString* url = [paramDict valueForKey:@"URL"];
        
        WADODownload* downloader = [[WADODownload alloc] init];        
        [downloader WADODownload:[NSArray arrayWithObject:[NSURL URLWithString:url]]];
        [downloader release];
        
        if ([[paramDict valueForKey:@"Display"] boolValue]) {
            NSString* studyUID = nil;
            NSString* seriesUID = nil;
            
            for (NSString* s in [[[url componentsSeparatedByString:@"?"] lastObject] componentsSeparatedByString:@"&"]) {
                NSRange separatorRange = [s rangeOfString:@"="];
                if (separatorRange.location == NSNotFound)
                    continue;
                @try {
                    if ([[s substringToIndex:separatorRange.location] isEqualToString:@"studyUID"])
                        studyUID = [s substringFromIndex:separatorRange.location+1];
                    if ([[s substringToIndex:separatorRange.location] isEqualToString:@"seriesUID"])
                        seriesUID = [s substringFromIndex:separatorRange.location+1];
                } @catch (NSException* e) {
                    N2LogExceptionWithStackTrace(e);
                }
            }
            
            if (studyUID) {
                NSPredicate* predicate = nil;
                if (seriesUID)
                    predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@ AND ANY series.seriesDICOMUID == %@", studyUID, seriesUID];
                else predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyUID];
                
                DicomDatabase* database = [self database];
                
                NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
                do {
                    NSArray* studies = [self objectsWithEntityName:@"Study" predicate:predicate error:NULL];
                    if ([[[studies lastObject] valueForKey:@"studyInstanceUID"] isEqualToString:studyUID]) {
                        DicomStudy* study = [studies lastObject];
                        DicomSeries* series = nil;
                        if (seriesUID)
                            for (DicomSeries* s in study.series)
                                if ([s.seriesDICOMUID isEqualToString:seriesUID])
                                    series = s;
                        
                        [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjects:) withObject:[NSArray arrayWithObject: series? (id)series : (id)study] waitUntilDone:NO];
                        
                        break;
                    }
                    
                    [NSThread sleepForTimeInterval:1];
                } while ([NSDate timeIntervalSinceReferenceDate] - startTime < 300); // try for 300 seconds = 5 minutes
            }
        }
	} @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}


/**
 Method: DisplayStudy

 Parameters:
 PatientID:  0010,0020
 StudyID:  0020,0010

 Example: {PatientID: "1100697", StudyID: "A10043712203"}
 Response: {elements: array of elements corresponding to the request}
 */
-(NSDictionary*)DisplayStudy:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* subpredicates = [NSMutableArray array];
    NSString* temp;
    
    temp = [paramDict valueForKey:@"PatientID"];
    if (temp.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"patientID == %@", temp]];
    temp = [paramDict valueForKey:@"StudyInstanceUID"];
    if (temp.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"studyInstanceUID == %@", temp]];

    if (subpredicates.count)
        ReturnWithCode(400); // Bad Request
    
    NSArray* objects = [self objectsWithEntityName:@"Study" predicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates] error:error];
    
    [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjects:) withObject:objects waitUntilDone:NO];
    
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in objects)
        [elements addObject:[[self class] dictionaryForObject:obj]];
    return [NSDictionary dictionaryWithObject:elements forKey:@"elements"];
}

/**
 Method: DisplaySeries
 
 Parameters:
 PatientID:  0010,0020
 SeriesInstanceUID: 0020,000e
 
 Example: {PatientID: "1100697", SeriesInstanceUID: "1.3.12.2.1107.5.1.4.54693.30000007120706534864000001110"}
 Response: {elements: array of elements corresponding to the request}
 */
-(NSDictionary*)DisplaySeries:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* subpredicates = [NSMutableArray array];
    NSString* temp;
    
    temp = [paramDict valueForKey:@"PatientID"];
    if (temp.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"study.patientID == %@", temp]];
    temp = [paramDict valueForKey:@"SeriesInstanceUID"];
    if (temp.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", temp]];
    
    if (subpredicates.count)
        ReturnWithCode(400); // Bad Request
    
    NSArray* objects = [self objectsWithEntityName:@"Series" predicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates] error:error];
    
    [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjects:) withObject:objects waitUntilDone:NO];
    
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in objects)
        [elements addObject:[[self class] dictionaryForObject:obj]];
    return [NSDictionary dictionaryWithObject:elements forKey:@"elements"];
}

/**
 Method: DBWindowFind

 Parameters:
 request: SQL request, see 'Predicate Format String Syntax' from Apple documentation
 table: OsiriX entity name: Image, Series, Study
 execute: Select, Open, Delete or Nothing - you may skip this entry

 execute is performed at the  study level: you cannot delete a single series of a study

 Example: {request: "name == 'OsiriX'", table: "Study", execute: "Select"}
 Example: {request: "(name LIKE '*OSIRIX*')", table: "Study", execute: "Open"}

 Response: {elements: array of elements corresponding to the request}
 */
-(NSDictionary*)FindObject:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* request = [paramDict valueForKey:@"request"];
    NSString* entityName = [paramDict valueForKey:@"table"];
    NSString* command = [paramDict valueForKey:@"execute"];
    
    if (!request.length || !entityName.length)
        ReturnWithCode(400); // Bad Request

    NSArray* objects = [self objectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:request] error:error];
    
    if ([command isEqualToString:@"Open"])
        [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjects:) withObject:objects waitUntilDone:NO];
    if ([command isEqualToString:@"Select"])
        [self performSelectorOnMainThread:@selector(_onMainThreadSelectObjects:) withObject:objects waitUntilDone:NO];
    
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in objects)
        [elements addObject:[[self class] dictionaryForObject:obj]];

    if ([command isEqualToString:@"Delete"])
        [self performSelectorOnMainThread:@selector(_onMainThreadDeleteObjects:) withObject:objects waitUntilDone:NO];
    
    return [NSDictionary dictionaryWithObject:elements forKey:@"elements"];
}

-(void)_onMainThreadOpenObjects:(NSArray*)objects { // actually, only the first element is opened...
    for (NSManagedObject* obj in objects) {
        NSLog(@"Opening %@", obj.XID);
        DicomStudy* study = [self studyForObject:obj];
        if ([study.imageSeries count]) {
			[[BrowserController currentBrowser] displayStudy:study object:obj command:@"Open"];
            break;
        }
    }
}

-(void)_onMainThreadSelectObjects:(NSArray*)objects { // actually, only the first element is opened...
    for (NSManagedObject* obj in objects) {
        DicomStudy* study = [self studyForObject:obj];
        if ([study.imageSeries count]) {
			[[BrowserController currentBrowser] displayStudy:study object:obj command:@"Select"];
            break;
        }
    }
}

-(void)_onMainThreadDeleteObjects:(NSArray*)objects {
    DicomDatabase* database = [self database];
    
    for (NSManagedObject* obj in objects) {
        DicomStudy* study = [self studyForObject:obj];
        if (study)
            [database.managedObjectContext deleteObject:study]; // TODO: but this is BAD... will the included Series and Images be removed and deleted from the DB ?
    }
    
    [database save];
}

/**
 Method: SwitchToDefaultDBIfNeeded

 Parameters:
 No parameters

 Response: {}
 */
-(NSDictionary*)SelectDefaultDatabase:(NSDictionary*)paramDict error:(NSError**)error {
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setDatabase:) withObject:[DicomDatabase defaultDatabase] waitUntilDone:NO];
    return [NSDictionary dictionary];
}

/**
 Method: OpenDB

 Parameters:
 path: path of the folder containing the 'OsiriX Data' folder

 if path is valid, but not DB is found, OsiriX will create a new one

 Example: {path: "/Users/antoinerosset/Documents/"}

 Response: {}
*/
-(NSDictionary*)OpenDatabase:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* path = [paramDict valueForKey:@"path"];
    
    if (!path.length)
        ReturnWithCode(400); // Bad Request
    
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setDatabase:) withObject:[DicomDatabase databaseAtPath:path] waitUntilDone:NO];
    
    return [NSDictionary dictionary];
}

/**
 Method: SelectAlbum

 Parameters:
 name: name of the album

 Example: {name: "Today"}

 Response: {}
 */
-(NSDictionary*)SelectAlbum:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* name = [paramDict objectForKey:@"name"];
    
    if (!name.length)
        ReturnWithCode(400); // Bad Request
    
    DicomDatabase* database = [self database];
    
    NSArray* albums = [database albums];
    for (NSInteger i = 0; i < albums.count; ++i) {
        DicomAlbum* album = [albums objectAtIndex:i];
        if ([album.name isEqualToString:name]) {
            [self performSelectorOnMainThread:@selector(_onMainThreadSelectAlbumAtIndex:) withObject:[NSNumber numberWithInteger:i] waitUntilDone:NO];
            return [NSDictionary dictionary];
        }
    }
    
    ReturnWithCode(404); // Not Found
}

-(void)_onMainThreadSelectAlbumAtIndex:(NSInteger)i {
    [[[BrowserController currentBrowser] albumTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}

/**
 Method: CloseAllWindows

 Parameters: No Parameters

 Response: {}
 */
-(NSDictionary*)CloseAllWindows:(NSDictionary*)paramDict error:(NSError**)error {
    for (ViewerController* v in [ViewerController getDisplayed2DViewers])
        [[v window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
    return [NSDictionary dictionary];
}

/**
 Method: GetDisplayed2DViewerSeries

 Parameters: No Parameters

 Response: {elements: array of series corresponding to displayed windows}
*/
-(NSDictionary*)GetDisplayed2DViewerSeries:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in [[ViewerController getDisplayed2DViewers] valueForKeyPath:@"imageView.seriesObj"])
        [elements addObject:[[self class] dictionaryForObject:obj]];
    
    return [NSDictionary dictionaryWithObject:elements forKey:@"elements"];
}

/**
 Method: GetDisplayed2DViewerStudies

 Parameters: No Parameters

 Response: {elements: array of studies corresponding to displayed windows}
*/
-(NSDictionary*)GetDisplayed2DViewerStudies:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in [[ViewerController getDisplayed2DViewers] valueForKeyPath:@"imageView.seriesObj.study"])
        [elements addObject:[[self class] dictionaryForObject:obj]];
    
    return [NSDictionary dictionaryWithObject:elements forKey:@"elements"];
}

/**
 Method: Close2DViewerWithSeriesUID

 Parameters:
 uid: series instance uid to close

 Example: {uid: "1.3.12.2.1107.5.1.4.51988.4.0.1164229612882469"}

 Response: {}
*/
-(NSDictionary*)Close2DViewerWithSeriesUID:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* uid = [paramDict objectForKey:@"uid"];
    
    if (!uid.length)
        ReturnWithCode(400);
    
    for (ViewerController* v in [ViewerController getDisplayed2DViewers])
        if ([[v valueForKeyPath:@"imageView.seriesObj.seriesDICOMUID"] isEqualToString:uid])
            [[v window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
    
    return [NSDictionary dictionary];
}

/**
 Method: Close2DViewerWithStudyUID

 Parameters:
 uid: study instance uid to close

 Example: {uid: "1.2.840.113745.101000.1008000.37915.4331.5559218"}

 Response: {}
 */
-(NSDictionary*)Close2DViewerWithStudyUID:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* uid = [paramDict objectForKey:@"uid"];
    
    if (!uid.length)
        ReturnWithCode(400);
    
    for (ViewerController* v in [ViewerController getDisplayed2DViewers])
        if ([[v valueForKeyPath:@"imageView.seriesObj.study.studyInstanceUID"] isEqualToString:uid])
            [[v window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
    
    return [NSDictionary dictionary];
}

/**
 Method: Retrieve

 Parameters:
 serverName: 
 filterValue: 
 filterKey:

 Example: osirix://?methodName=retrieve&serverName=Minipacs&filterKey=PatientID&filterValue=296228

 Response: {}
 */
-(NSDictionary*)Retrieve:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* serverName = [paramDict objectForKey:@"serverName"];
    NSInteger retrieveModeParam = [[paramDict objectForKey:@"retrieveMode"] integerValue];
    
    if (!serverName.length)
        ReturnWithCode(400);
    
    NSDictionary* source = nil;
    NSArray* sources = [DCMNetServiceDelegate DICOMServersList];
    for (NSDictionary* si in sources)
        if ([[si objectForKey:@"Description"] isEqualToString:serverName]) {
            source = si;
            break;
        }
    
    if (!source)
        ReturnWithCode(404);
    
    @try {
        DCMTKRootQueryNode* rootNode = [[DCMTKRootQueryNode alloc] initWithDataset:nil
                                                                        callingAET:[NSUserDefaults defaultAETitle]
                                                                         calledAET:[source objectForKey:@"AETitle"]
                                                                          hostname:[source objectForKey:@"Address"]
                                                                              port:[[source objectForKey:@"Port"] intValue]
                                                                    transferSyntax:0
                                                                       compression:nil
                                                                   extraParameters:source];
        
        NSMutableArray* filters = [NSMutableArray array];
        for (NSInteger i = 1; i < 100; ++i) {
            NSString* filterKey = [paramDict objectForKey:(i != 1 ? [NSString stringWithFormat:@"filterKey%d", (int)i] : @"filterKey")];
            NSString* filterValue = [paramDict objectForKey:(i != 1 ? [NSString stringWithFormat:@"filterValue%d", (int)i] : @"filterValue")];
            if (filterKey && filterValue)
                [filters addObject:[NSDictionary dictionaryWithObjectsAndKeys: filterValue, @"value", filterKey, @"name", nil]];
        }
       
        [rootNode queryWithValues:filters];
        
        int retrieveMode = CMOVERetrieveMode;
        if (retrieveModeParam == WADORetrieveMode) retrieveMode = WADORetrieveMode;
        if (retrieveModeParam == CGETRetrieveMode) retrieveMode = CGETRetrieveMode;
        
        if ([[rootNode children] count])
        {
            NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSUserDefaults defaultAETitle], @"moveDestination",
                                  [NSNumber numberWithInt:retrieveMode] , @"retrieveMode",
                                  [rootNode children], @"children", nil];
            [NSThread detachNewThreadSelector:@selector(_threadRetrieve:) toTarget:self withObject:dict];
            
            return [NSDictionary dictionary];
        }
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    
    ReturnWithCode(500);
}

-(void)_threadRetrieve:(NSDictionary*)dict
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        for (DCMTKQueryNode* study in [dict valueForKey:@"children"])
            [study move:dict retrieveMode:[[dict valueForKey:@"retrieveMode"] intValue]];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

/**
 Method: CMove

 Parameters:
 accessionNumber: accessionNumber of the study to retrieve
 server: server description where the images are located (See OsiriX Locations Preferences)

 Example: {accessionNumber: "UA876410", server: "Main-PACS"}

 Response: {}
 */
-(NSDictionary*)CMove:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* accessionNumber = [paramDict objectForKey:@"accessionNumber"];
    NSString* serverName = [paramDict objectForKey:@"server"];
    
    NSDictionary* source = nil;
    NSArray* sources = [DCMNetServiceDelegate DICOMServersList];
    for (NSDictionary* si in sources)
        if ([[si objectForKey:@"Description"] isEqualToString:serverName]) {
            source = si;
            break;
        }
    
    if (!source || !accessionNumber.length)
        ReturnWithCode(404);
    
    [self performSelectorOnMainThread:@selector(_onMainThreadQueryRetrieve:) withObject:[NSArray arrayWithObjects: accessionNumber, source, nil] waitUntilDone:NO];
    
    return [NSDictionary dictionary];
}

-(void)_onMainThreadQueryRetrieve:(NSArray*)args {
    [QueryController queryAndRetrieveAccessionNumber:[args objectAtIndex:0] server:[args objectAtIndex:1]];
}

/**
 Method: DisplayStudyListByPatientName

 Parameters:
 PatientName: name of the patient

 Example: {PatientName: "DOE^JOHN"}

 Response: {}
 */
-(NSDictionary*)DisplayStudyListByPatientName:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* patientName = [paramDict objectForKey:@"PatientName"];
    
    if (!patientName.length)
        ReturnWithCode(404);
    
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setSearchString:) withObject:patientName waitUntilDone:NO];
    
    return [NSDictionary dictionary];
}

/**
 Method: DisplayStudyListByPatientId

 Parameters:
 PatientID: patient ID

 Example: {id: "0123456789"}

 Response: {}
 */
-(NSDictionary*)DisplayStudyListByPatientId:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* patientId = [paramDict objectForKey:@"PatientID"];
    
    if (!patientId.length)
        ReturnWithCode(404);
    
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setSearchString:) withObject:patientId waitUntilDone:NO];
    
    return [NSDictionary dictionary];
}

/**
 Method: PathToFrontDCM
 
 Parameters:
 onlyfilename: string with value "yes" to activate only filename mode; if absent or not equal to "yes", the full path is returned
 
 Response: {currentDCMPath: "/path/to/file.dcm"}
           {currentDCMPath: "file.dcm"} if onlyfilename == "yes"
           {currentDCMPath: ""} if no viewer is open
 */
-(NSDictionary*)PathToFrontDCM:(NSDictionary*)paramDict error:(NSError**)error {
    BOOL onlyFilename = [[paramDict objectForKey:@"onlyfilename"] isEqualToString:@"yes"];
    
    ViewerController* viewer = [ViewerController frontMostDisplayed2DViewer];
    
    NSString* path = nil;
    
    if (viewer) {
        path  = [[BrowserController currentBrowser] getLocalDCMPath:[[viewer fileList] objectAtIndex:[[viewer imageView] curImage]] :0];
        if (onlyFilename)
            path = [path lastPathComponent];
    }
    
    if (!path)
        path = @"";
    
    return [NSDictionary dictionaryWithObject:path forKey:@"currentDCMPath"];
}

#pragma mark Old

- (BOOL)processXMLRPCMessage:(NSString*)selName httpServerMessage:(NSMutableDictionary*)httpServerMessage HTTPServerRequest:(HTTPServerRequest*)mess version:(NSString*)vers paramDict:(NSDictionary*)paramDict encoding:(NSString*)encoding { // __deprecated
    SEL methodSelector = NSSelectorFromString([self selectorStringForXMLRPCRequestMethodName:selName]);
    
    NSDictionary* response;
    NSError* error = nil;
    
    if ([self respondsToSelector:methodSelector])
        @try {
            NSDictionary* response = [self performSelector:methodSelector withObject:paramDict withObject:(id)&error];
            
            if (response)
                [httpServerMessage setValue:response forKey: @"ASResponse"];

            if (error)
                response = [NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:error.code] stringValue] forKey:@"error"];
            
        } @catch (NSException* e) {
            if (error)
                response = [NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:error.code] stringValue] forKey:@"error"];
        } @finally {
            return YES;
        }
    
    // this next block is here for retro-compatibility if eventually any plugin was calling this...
    NSString* xml = [NSString stringWithFormat: @"<?xml version=\"1.0\"?><methodResponse><params><param><value>%@</value></param></params></methodResponse>", [N2XMLRPC FormatElement:response]];
    NSXMLDocument* doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:NULL] autorelease];
    [httpServerMessage setObject:doc forKey:@"NSXMLDocumentResponse"];
    
    return NO;
}

@end

// TODO: announce with bonjour type _http._tcp.
