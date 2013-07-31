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
#import "DCMTKSeriesQueryNode.h"
#import "DCMNetServiceDelegate.h"
#import "DCMView.h"
#import "NSUserDefaults+OsiriX.h"
#import "QueryController.h"
#import "WADODownload.h"
#import "NSManagedObject+N2.h"
#import "Notifications.h"
#import "dcdeftag.h"

@interface XMLRPCInterfaceConnection : N2XMLRPCConnection

@end

@implementation XMLRPCInterface

-(id)init {
	if ((self = [super init])) {
        NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:@"httpXMLRPCServerPort"];
        _listener = [[N2ConnectionListener alloc] initWithPort:port connectionClass:[XMLRPCInterfaceConnection class]];
        _listener.threadPerConnection = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionOpened:) name:N2ConnectionListenerOpenedConnectionNotification object:_listener];
        
        if( _listener)
            NSLog( @"--- XML-RPC interface activated on port: %d", (int) port);
    }
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_listener release]; _listener = NULL;
	[super dealloc];
}

-(void)connectionOpened:(NSNotification*)notification {
	XMLRPCInterfaceConnection* connection = [[notification userInfo] objectForKey:N2ConnectionListenerOpenedConnection];
    connection.dontSpecifyStringType = YES;
	[connection setDelegate:self];
}

#pragma mark N2XMLRPCConnectionDelegate

// this method is implemented because the original XMLRPC interface wasn't case-sensitive with XMLRPC method names; anyway we'd still need to implement isSelectorAvailableToXMLRPC:
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
        NSObject* value = [obj valueForKey:key];
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]])
            [d setObject:[(NSString*)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)value.description, NULL) autorelease] forKey:key];
    }
    
    return d;
}

-(DicomStudy*)studyForObject:(NSManagedObject*)obj {
    if ([obj isKindOfClass:[DicomStudy class]]) return (id)obj;
    if ([obj isKindOfClass:[DicomSeries class]]) return [obj valueForKey:@"study"];
    if ([obj isKindOfClass:[DicomImage class]]) return [obj valueForKey:@"series.study"];
    return nil;
}

+(NSError*)errorWithCode:(NSInteger)code {
    NSString* xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>%d</value></member></struct></value></param></params></methodResponse>", (int) code];
    return [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:xml forKey:NSLocalizedDescriptionKey]];
}

#define ReturnWithCode(code) { if (error) *error = [XMLRPCInterface errorWithCode:code]; return nil; }
#define ReturnWithErrorValueAndObjectForKey(code, object, key) { return [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", (int)code], @"error", object, key, nil]; }
#define ReturnWithErrorValue(code) { return [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", (int)code] forKey:@"error"]; }

#pragma mark Exposed Methods

/**
 Method: KillOsiriX
 */
-(void)KillOsiriX:(NSDictionary*)params error:(NSError**)error {
    
    if( error)
        *error = nil;
    
    [[AppController sharedAppController] performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
}

/**
 Method: DownloadURL

 Parameters:
 URL: any URLs that return a file compatible with OsiriX, including .dcm, .zip, .osirixzip, ...
 Display: display the images at the end of the download? (Optional parameter : it requires a WADO URL, containing the studyUID parameter)

 Example: {URL: "http://127.0.0.1:3333/wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX"}
 Response: {error: "0"}
 */
-(NSDictionary*)DownloadURL:(NSDictionary*)paramDict error:(NSError**)error {
    @try
    {
        if ([[paramDict valueForKey:@"URL"] length])
        {
            NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(_threadRetrieveWado:) object:paramDict] autorelease];
            t.name = NSLocalizedString(@"WADO Retrieve...", nil);
            t.supportsCancel = YES;
            t.status = [[[NSURL URLWithString:@"/" relativeToURL: [NSURL URLWithString: [paramDict valueForKey:@"URL"]]] absoluteURL] description];
            [[ThreadsManager defaultManager] addThreadAndStart:t];
        }
        else 
            ReturnWithCode(400); // Bad Request
    }
    @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    
    ReturnWithErrorValue(0);
}

-(void)_threadRetrieveWado:(NSDictionary*)paramDict {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
        NSString* url = [paramDict valueForKey:@"URL"];
        
        WADODownload* downloader = [[[WADODownload alloc] init] autorelease];
        [downloader WADODownload:[NSArray arrayWithObject:[NSURL URLWithString:url]]];
        
        if( downloader.countOfSuccesses && [[NSThread currentThread] isCancelled] == NO)
        {
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
                
                if (studyUID)
                {
                    [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
                    
                    [NSThread sleepForTimeInterval: 2];
                    
                    NSPredicate* predicate = nil;
                    if (seriesUID)
                        predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@ AND ANY series.seriesDICOMUID == %@", studyUID, seriesUID];
                    else predicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyUID];
                    
                    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
                    do {
                        NSArray* istudies = [[self.database independentDatabase] objectsForEntity:@"Study" predicate:predicate error:NULL];
                        DicomStudy* istudy = [istudies lastObject];
                        if ([istudy.studyInstanceUID isEqualToString:studyUID]) {
                            DicomSeries* iseries = nil;
                            if (seriesUID)
                                for (DicomSeries* is in istudy.series)
                                    if ([is.seriesDICOMUID isEqualToString:seriesUID])
                                        iseries = is;
                            
                            NSManagedObject* obj = iseries? (id)iseries : (id)istudy;
                            [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjectsWithIDs:) withObject:[NSArray arrayWithObject:obj.objectID] waitUntilDone:NO];
                            
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval: 2];
                    } while ([NSDate timeIntervalSinceReferenceDate] - startTime < 30 && [[NSThread currentThread] isCancelled] == NO); // try for 30 seconds
                }
            }
        }
	} @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}


- (void)_PACSOnDemandRetrieve:(NSDictionary*)keys open:(NSPredicate*)predicate {
    [NSThread performBlockInBackground:^{
        NSMutableArray* dicomNodes = [NSMutableArray array];
        NSArray* allDicomNodes = [DCMNetServiceDelegate DICOMServersList];
        for (NSDictionary* si in [NSUserDefaults.standardUserDefaults arrayForKey:@"comparativeSearchDICOMNodes"])
            for (NSDictionary* di in allDicomNodes)
                if ([[si objectForKey:@"AETitle"] isEqualToString:[di objectForKey:@"AETitle"]] &&
                    [[si objectForKey:@"name"] isEqualToString:[di objectForKey:@"Description"]] &&
                    [[si objectForKey:@"AddressAndPort"] isEqualToString:[NSString stringWithFormat:@"%@:%@", [di valueForKey:@"Address"], [di valueForKey:@"Port"]]])
                {
                    [dicomNodes addObject:di];
                }
        
        NSThread* thread = [NSThread currentThread];
        thread.name = NSLocalizedString(@"Retrieving requested study...", nil);
        thread.status = (dicomNodes.count == 1)? NSLocalizedString(@"Querying distant server...", nil) : NSLocalizedString(@"Querying distant servers...", nil);
        [ThreadsManager.defaultManager addThreadAndStart:thread];
        
        DcmDataset slDataset;
        slDataset.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
        slDataset.insertEmptyElement(DCM_StudyInstanceUID);
        
        NSString* table = @"Study";
        
        for (NSString* key in keys) {
            NSString* value = [keys objectForKey:key];
            if (![value isKindOfClass:[NSString class]])
                value = [(id)value stringValue];
            
            NSString* k = [[key componentsSeparatedByString:@"."] lastObject];
            
            if ([k isEqualToString:@"QueryRetrieveLevel"]) {
                slDataset.putAndInsertString(DCM_QueryRetrieveLevel, value.UTF8String);
                if ([value isEqualToString:@"STUDY"])
                    table = @"Study";
                if ([value isEqualToString:@"SERIES"])
                    table = @"Series";
                if ([value isEqualToString:@"IMAGE"])
                    table = @"Image";
            }
            else if ([k isEqualToString:@"studyInstanceUID"])
                slDataset.putAndInsertString(DCM_StudyInstanceUID, value.UTF8String);
            else if ([k isEqualToString:@"seriesInstanceUID"])
                slDataset.putAndInsertString(DCM_SeriesInstanceUID, value.UTF8String);
            else if ([k isEqualToString:@"patientID"])
                slDataset.putAndInsertString(DCM_PatientID, value.UTF8String);
            else if ([k isEqualToString:@"accessionNumber"])
                slDataset.putAndInsertString(DCM_AccessionNumber, value.UTF8String);
        }
        
//        slDataset.print(std::cout);
        
        for (NSDictionary* dn in dicomNodes) {
            DCMTKRootQueryNode* qn = [DCMTKRootQueryNode queryNodeWithDataset:&slDataset
                                                                   callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                    calledAET:[dn objectForKey:@"AETitle"]
                                                                     hostname:[dn objectForKey:@"Address"]
                                                                         port:[[dn objectForKey:@"Port"] intValue]
                                                               transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                  compression:0
                                                              extraParameters:dn];
            [qn setShowErrorMessage:NO];
            
            [qn setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:&slDataset destination:nil];
            
            if (qn.children.count) {
                NSMutableDictionary* params = [[dn mutableCopy] autorelease];
                [params setObject:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"] forKey:@"moveDestination"];
                
                [NSThread performBlockInBackground:^{
                    NSDate* date = [NSDate date];
                    const NSTimeInterval maxWaitSeconds = 60;
                    DicomDatabase* idatabase = [self.database independentDatabase];
                    while (-[date timeIntervalSinceNow] < maxWaitSeconds) {
                        NSArray* iobjects = [idatabase objectsForEntity:table predicate:predicate error:NULL];
                        if (iobjects.count) {
                            [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjectsWithIDs:) withObject:[iobjects valueForKey:@"objectID"] waitUntilDone:NO];
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:0.1];
                    }
                    
                }];
                
                thread.status = NSLocalizedString(@"Retrieving...", nil);
                
                for (DCMTKStudyQueryNode* sqn in qn.children)
                    [sqn move:params retrieveMode:[[dn objectForKey:@"retrieveMode"] intValue]];
            }
        }
    }];
}

/**
 Method: DisplayStudy

 Parameters:
 PatientID:  0010,0020
 StudyID:  0020,0010

 Example: {PatientID: "1100697", StudyID: "A10043712203"}
 Response: {error: "0", elements: array of elements corresponding to the request}
 */
- (NSDictionary*)DisplayStudy:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* subpredicates = [NSMutableArray array];
    
    NSString* patientID = [paramDict valueForKey:@"PatientID"];
    if (patientID.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"patientID == %@", patientID]];
    
    NSString* studyInstanceUID = [paramDict valueForKey:@"StudyInstanceUID"];
    if (studyInstanceUID.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyInstanceUID]];
    
    NSString* accessionNumber = [paramDict valueForKey:@"AccessionNumber"];
    if (accessionNumber.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"accessionNumber == %@", accessionNumber]];

    if (!subpredicates.count)
        ReturnWithCode(400); // Bad Request
    
    NSError* lerror = nil;
    if (!error)
        error = &lerror;
    
    NSPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    
    NSArray* iobjects = [[self.database independentDatabase] objectsForEntity:@"Study" predicate:predicate error:error];
    
//  if (!iobjects.count) // do this anyway, to complete the study if something is amiss
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"XMLRPCWithPOD"] && [NSUserDefaults.standardUserDefaults boolForKey:@"searchForComparativeStudiesOnDICOMNodes"]) {
        NSMutableDictionary* keys = [NSMutableDictionary dictionary];
        
        if (patientID.length)
            [keys setObject:patientID forKey:@"patientID"];
        if (studyInstanceUID.length)
            [keys setObject:studyInstanceUID forKey:@"studyInstanceUID"];
        if (accessionNumber.length)
            [keys setObject:accessionNumber forKey:@"accessionNumber"];

        if (keys.count)
            [self _PACSOnDemandRetrieve:keys open:predicate];
    }
    
    if (error && *error)
        ReturnWithErrorValue((*error).code);
    if (iobjects.count == 0)
        ReturnWithErrorValue(-1);

    [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjectsWithIDs:) withObject:[iobjects valueForKey:@"objectID"] waitUntilDone:NO];
    
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* iobj in iobjects)
        [elements addObject:[[self class] dictionaryForObject:iobj]];
    ReturnWithErrorValueAndObjectForKey(0, elements, @"elements");
}

/**
 Method: DisplaySeries
 
 Parameters:
 PatientID:  0010,0020
 SeriesInstanceUID: 0020,000e
 
 Example: {PatientID: "1100697", SeriesInstanceUID: "1.3.12.2.1107.5.1.4.54693.30000007120706534864000001110"}
 Response: {error: "0", elements: array of elements corresponding to the request}
 */
- (NSDictionary*)DisplaySeries:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* subpredicates = [NSMutableArray array];
    
    NSString* patientID = [paramDict valueForKey:@"PatientID"];
    if (patientID.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"study.patientID == %@", patientID]];
    NSString* seriesInstanceUID = [paramDict valueForKey:@"SeriesInstanceUID"];
    if (seriesInstanceUID.length) [subpredicates addObject:[NSPredicate predicateWithFormat:@"seriesDICOMUID == %@", seriesInstanceUID]];
    
    if (!subpredicates.count)
        ReturnWithCode(400); // Bad Request
    
    NSError* lerror = nil;
    if (!error)
        error = &lerror;
    
    NSPredicate* predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    
    NSArray* iobjects = [[self.database independentDatabase] objectsForEntity:@"Series" predicate:predicate error:error];
    
//  if (!iobjects.count) // do this anyway, to complete the study if something is amiss
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"XMLRPCWithPOD"] && [NSUserDefaults.standardUserDefaults boolForKey:@"searchForComparativeStudiesOnDICOMNodes"]) {
        NSMutableDictionary* keys = [NSMutableDictionary dictionary];
        
        if (patientID.length)
            [keys setObject:patientID forKey:@"study.patientID"];
        if (seriesInstanceUID.length)
            [keys setObject:seriesInstanceUID forKey:@"seriesInstanceUID"];
        
        if (keys.count) {
            [keys setObject:@"SERIES" forKey:@"QueryRetrieveLevel"];
            [self _PACSOnDemandRetrieve:keys open:predicate];
        }
    }
    
    if (error && *error)
        ReturnWithErrorValue((*error).code);
    if (iobjects.count == 0)
        ReturnWithErrorValue(-1);
    
    [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjectsWithIDs:) withObject:[iobjects valueForKey:@"objectID"] waitUntilDone:NO];
    
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* iobj in iobjects)
        [elements addObject:[[self class] dictionaryForObject:iobj]];
    ReturnWithErrorValueAndObjectForKey(0, elements, @"elements");
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

 Response: {error: "0", elements: array of elements corresponding to the request}
 */
-(NSDictionary*)FindObject:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* request = [paramDict valueForKey:@"request"];
    NSString* entityName = [paramDict valueForKey:@"table"];
    NSString* command = [paramDict valueForKey:@"execute"];
    
    if (!request.length || !entityName.length)
        ReturnWithCode(400); // Bad Request
    
    NSError* lerror = nil;
    if (!error)
        error = &lerror;
    
    DicomDatabase* idatabase = [self.database independentDatabase];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:request];
    
    NSArray* iobjects = [idatabase objectsForEntity:entityName predicate:predicate error:error];
    
//  NSLog(@"FindObject %@ ||| %@ ||| %@ ||| %d", entityName, request, command, (int)iobjects.count);
    
//  if (!iobjects.count) // do this anyway, to complete the study if something is amiss
    if ([command isEqualToString:@"Open"] && [NSUserDefaults.standardUserDefaults boolForKey:@"XMLRPCWithPOD"] && [NSUserDefaults.standardUserDefaults boolForKey:@"searchForComparativeStudiesOnDICOMNodes"]) {
        NSMutableArray* predicates = [NSMutableArray array];
        if ([predicate isKindOfClass:[NSComparisonPredicate class]])
            [predicates addObject:predicate];
        if ([predicate isKindOfClass:[NSCompoundPredicate class]] && [(id)predicate compoundPredicateType] == NSAndPredicateType)
            for (id subpredicate in [(id)predicate subpredicates])
                if ([subpredicate isKindOfClass:[NSComparisonPredicate class]])
                    [predicates addObject:subpredicate];

        NSMutableDictionary* keys = [NSMutableDictionary dictionary];
        for (NSComparisonPredicate* p in predicates)
            if (p.comparisonPredicateModifier == NSDirectPredicateModifier && p.predicateOperatorType == NSEqualToPredicateOperatorType) {
                if (p.leftExpression.expressionType == NSKeyPathExpressionType && p.rightExpression.expressionType == NSConstantValueExpressionType)
                    [keys setObject:p.rightExpression.constantValue forKey:p.leftExpression.keyPath];
                else if (p.rightExpression.expressionType == NSKeyPathExpressionType && p.leftExpression.expressionType == NSConstantValueExpressionType)
                    [keys setObject:p.leftExpression.constantValue forKey:p.rightExpression.keyPath];
            }
        
        if (keys.count) {
            if ([entityName isEqual:@"Study"])
                [keys setObject:@"STUDY" forKey:@"QueryRetrieveLevel"];
            if ([entityName isEqual:@"Series"])
                [keys setObject:@"SERIES" forKey:@"QueryRetrieveLevel"];
            if ([entityName isEqual:@"Image"])
                [keys setObject:@"IMAGE" forKey:@"QueryRetrieveLevel"];

            [self _PACSOnDemandRetrieve:keys open:predicate];
        }
    }

    
    if (error && *error)
        ReturnWithErrorValue((*error).code);
    if (iobjects.count == 0)
        ReturnWithErrorValue(-1);
    
    if ([command isEqualToString:@"Open"])
        [self performSelectorOnMainThread:@selector(_onMainThreadOpenObjectsWithIDs:) withObject:[iobjects valueForKey:@"objectID"] waitUntilDone:NO];
    if ([command isEqualToString:@"Select"])
        [self performSelectorOnMainThread:@selector(_onMainThreadSelectObjectsWithIDs:) withObject:[iobjects valueForKey:@"objectID"] waitUntilDone:NO];
    
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* iobj in iobjects)
        [elements addObject:[[self class] dictionaryForObject:iobj]];

    if ([command isEqualToString:@"Delete"]) {
        for (NSManagedObject* iobj in iobjects) {
            DicomStudy* istudy = [self studyForObject:iobj];
            if (istudy)
                [idatabase.managedObjectContext deleteObject:istudy]; // TODO: but this is BAD... will the included Series and Images be removed and deleted from the DB ?
        }
        
        [idatabase save];
    }
    
    ReturnWithErrorValueAndObjectForKey(0, elements, @"elements");
}

-(void)_onMainThreadOpenObjectsWithIDs:(NSArray*)objectIDs { // actually, only the first element is opened...
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"bringOsiriXToFrontAfterReceivingMessage"])
        [NSApp activateIgnoringOtherApps:YES];
    
    NSMutableArray *objectIDsMutable = [NSMutableArray arrayWithArray: objectIDs];
    
    //Remove already displayed studies
    for( ViewerController *v in [ViewerController get2DViewers])
    {
        if( [objectIDs containsObject: [v.currentStudy objectID]])
        {
            [objectIDsMutable removeObject: [v.currentStudy objectID]];
            [v.window makeKeyAndOrderFront: self];
        }
    }
    
    for (NSManagedObject* obj in [self.database objectsWithIDs: objectIDsMutable]) {
        DicomStudy* study = [self studyForObject:obj];
        if ([study.imageSeries count]) {
			[[BrowserController currentBrowser] displayStudy:study object:obj command:@"Open"];
            break;
        }
    }
}

-(void)_onMainThreadSelectObjectsWithIDs:(NSArray*)objectIDs { // actually, only the first element is opened...
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"bringOsiriXToFrontAfterReceivingMessage"])
        [NSApp activateIgnoringOtherApps:YES];
    
    NSMutableArray *objectIDsMutable = [NSMutableArray arrayWithArray: objectIDs];
    
    //Remove already displayed studies
    for( ViewerController *v in [ViewerController get2DViewers])
    {
        if( [objectIDs containsObject: [v.currentStudy objectID]])
        {
            [objectIDsMutable removeObject: [v.currentStudy objectID]];
            [v.window makeKeyAndOrderFront: self];
        }
    }
    
    for (NSManagedObject* obj in [self.database objectsWithIDs: objectIDsMutable]) {
        DicomStudy* study = [self studyForObject:obj];
        if ([study.imageSeries count]) {
			[[BrowserController currentBrowser] displayStudy:study object:obj command:@"Select"];
            break;
        }
    }
}

/**
 Method: SwitchToDefaultDBIfNeeded

 Parameters:
 No parameters

 Response: {error: "0"}
 */
-(NSDictionary*)SelectDefaultDatabase:(NSDictionary*)paramDict error:(NSError**)error {
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setDatabase:) withObject:[DicomDatabase defaultDatabase] waitUntilDone:NO];
    ReturnWithErrorValue(0);
}

/**
 Method: OpenDB

 Parameters:
 path: path of the folder containing the 'OsiriX Data' folder

 if path is valid, but not DB is found, OsiriX will create a new one

 Example: {path: "/Users/antoinerosset/Documents/"}

 Response: {error: "0"}
*/
-(NSDictionary*)OpenDatabase:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* path = [paramDict valueForKey:@"path"];
    
    if (!path.length)
        ReturnWithCode(400); // Bad Request
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setDatabase:) withObject:[DicomDatabase databaseAtPath:path] waitUntilDone:NO];
    else ReturnWithErrorValue(-1);
    
    ReturnWithErrorValue(0);
}

/**
 Method: SelectAlbum

 Parameters:
 name: name of the album

 Example: {name: "Today"}

 Response: {error: "0"}
 */
-(NSDictionary*)SelectAlbum:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* name = [paramDict objectForKey:@"name"];
    
    if (!name.length)
        ReturnWithCode(400); // Bad Request
    
    NSArray* albums = [(DicomDatabase*)[self.database independentDatabase] albums];
    for (NSInteger i = 0; i < albums.count; ++i) {
        DicomAlbum* album = [albums objectAtIndex:i];
        if ([album.name isEqualToString:name]) {
            [self performSelectorOnMainThread:@selector(_onMainThreadSelectAlbumAtIndex:) withObject:[NSNumber numberWithInteger:i] waitUntilDone:NO];
            ReturnWithErrorValue(0);
        }
    }
    
    ReturnWithErrorValue(-1);
}

-(void)_onMainThreadSelectAlbumAtIndex:(NSInteger)i {
    [[[BrowserController currentBrowser] albumTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}

/**
 Method: CloseAllWindows

 Parameters: No Parameters

 Response: {error: "0"}
 */
-(NSDictionary*)CloseAllWindows:(NSDictionary*)paramDict error:(NSError**)error {
    for (ViewerController* v in [ViewerController getDisplayed2DViewers])
        [[v window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
    ReturnWithErrorValue(0);
}

/**
 Method: GetDisplayed2DViewerSeries

 Parameters: No Parameters

 Response: {error: "0", elements: array of series corresponding to displayed windows}
*/
-(NSDictionary*)GetDisplayed2DViewerSeries:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in [[ViewerController getDisplayed2DViewers] valueForKeyPath:@"imageView.seriesObj"])
        [elements addObject:[[self class] dictionaryForObject:obj]];
    
    ReturnWithErrorValueAndObjectForKey(0, elements, @"elements");
}

/**
 Method: GetDisplayed2DViewerStudies

 Parameters: No Parameters

 Response: {error: "0", elements: array of studies corresponding to displayed windows}
*/
-(NSDictionary*)GetDisplayed2DViewerStudies:(NSDictionary*)paramDict error:(NSError**)error {
    NSMutableArray* elements = [NSMutableArray array];
    for (NSManagedObject* obj in [[ViewerController getDisplayed2DViewers] valueForKeyPath:@"imageView.seriesObj.study"])
        [elements addObject:[[self class] dictionaryForObject:obj]];
    
    ReturnWithErrorValueAndObjectForKey(0, elements, @"elements");
}

/**
 Method: Close2DViewerWithSeriesUID

 Parameters:
 uid: series instance uid to close

 Example: {uid: "1.3.12.2.1107.5.1.4.51988.4.0.1164229612882469"}

 Response: {error: "0"}
*/
-(NSDictionary*)Close2DViewerWithSeriesUID:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* uid = [paramDict objectForKey:@"uid"];
    
    if (!uid.length)
        ReturnWithCode(400);
    
    for (ViewerController* v in [ViewerController getDisplayed2DViewers])
        if ([[v valueForKeyPath:@"imageView.seriesObj.seriesDICOMUID"] isEqualToString:uid])
            [[v window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
    
    ReturnWithErrorValue(0);
}

/**
 Method: Close2DViewerWithStudyUID

 Parameters:
 uid: study instance uid to close

 Example: {uid: "1.2.840.113745.101000.1008000.37915.4331.5559218"}

 Response: {error: "0"}
 */
-(NSDictionary*)Close2DViewerWithStudyUID:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* uid = [paramDict objectForKey:@"uid"];
    
    if (!uid.length)
        ReturnWithCode(400);
    
    for (ViewerController* v in [ViewerController getDisplayed2DViewers])
        if ([[v valueForKeyPath:@"imageView.seriesObj.study.studyInstanceUID"] isEqualToString:uid])
            [[v window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
    
    ReturnWithErrorValue(0);
}

/**
 Method: Retrieve

 Parameters:
 serverName: 
 filterValue: 
 filterKey:

 Example: osirix://?methodName=retrieve&serverName=Minipacs&filterKey=PatientID&filterValue=296228

 Response: {error: "0"}
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
        ReturnWithErrorValue(-2);
    
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
            
            ReturnWithErrorValue(0);
        } else
            ReturnWithErrorValue(-3);
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    
    ReturnWithErrorValue(-1);
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

 Response: {error: "0"}
 */
-(NSDictionary*)CMove:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* accessionNumber = [paramDict objectForKey:@"accessionNumber"];
    NSString* serverName = [paramDict objectForKey:@"server"];
    
    if (!accessionNumber.length || !serverName.length)
        ReturnWithCode(400);

    NSDictionary* source = nil;
    NSArray* sources = [DCMNetServiceDelegate DICOMServersList];
    for (NSDictionary* si in sources)
        if ([[si objectForKey:@"Description"] isEqualToString:serverName]) {
            source = si;
            break;
        }
    
    if (!source)
        ReturnWithErrorValue(-1);
    
    [self performSelectorOnMainThread:@selector(_onMainThreadQueryRetrieve:) withObject:[NSArray arrayWithObjects: accessionNumber, source, nil] waitUntilDone:NO];
    
    ReturnWithErrorValue(0);
}

-(void)_onMainThreadQueryRetrieve:(NSArray*)args {
    [QueryController queryAndRetrieveAccessionNumber:[args objectAtIndex:0] server:[args objectAtIndex:1]];
}

/**
 Method: DisplayStudyListByPatientName

 Parameters:
 PatientName: name of the patient

 Example: {PatientName: "DOE^JOHN"}

 Response: {error: "0"}
 */
-(NSDictionary*)DisplayStudyListByPatientName:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* patientName = [paramDict objectForKey:@"PatientName"];
    
    if (!patientName.length)
        ReturnWithCode(400);
    
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setSearchString:) withObject:patientName waitUntilDone:NO];
    
    ReturnWithErrorValue(0);
}

/**
 Method: DisplayStudyListByPatientId

 Parameters:
 PatientID: patient ID

 Example: {id: "0123456789"}

 Response: {error: "0"}
 */
-(NSDictionary*)DisplayStudyListByPatientId:(NSDictionary*)paramDict error:(NSError**)error {
    NSString* patientId = [paramDict objectForKey:@"PatientID"];
    
    if (!patientId.length)
        ReturnWithCode(400);
    
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setSearchString:) withObject:patientId waitUntilDone:NO];
    
    ReturnWithErrorValue(0);
}

/**
 Method: PathToFrontDCM
 
 Parameters:
 onlyfilename: string with value "yes" to activate only filename mode; if absent or not equal to "yes", the full path is returned
 
 Response: {error: "0", currentDCMPath: "/path/to/file.dcm"}
           {error: "0", currentDCMPath: "file.dcm"} if onlyfilename == "yes"
           {error: "0", currentDCMPath: ""} if no viewer is open
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
    
    ReturnWithErrorValueAndObjectForKey(0, path, @"currentDCMPath");
}

#pragma mark Old

- (void)processXMLRPCMessage:(NSString*)selName httpServerMessage:(NSMutableDictionary*)httpServerMessage HTTPServerRequest:(HTTPServerRequest*)mess version:(NSString*)vers paramDict:(NSDictionary*)paramDict encoding:(NSString*)encoding { // __deprecated
    XMLRPCInterfaceConnection* conn = [[[XMLRPCInterfaceConnection alloc] init] autorelease];
    conn.delegate = self;
    
    NSError* error = nil;
    id response = nil;
    @try {
        response = [conn methodCall:selName params:[NSArray arrayWithObject:paramDict] error:&error];
    } @catch (NSException* e) {
        if (!error)
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
    }
    if (error)
        response = [NSDictionary dictionaryWithObject:[[NSNumber numberWithInteger:error.code] stringValue] forKey:@"error"];

    if (response && httpServerMessage) {
        [httpServerMessage setValue:response forKey:@"ASResponse"];
        [httpServerMessage setValue:[[[NSXMLDocument alloc] initWithXMLString:[N2XMLRPC responseWithValue:response] options:0 error:NULL] autorelease] forKey:@"NSXMLDocumentResponse"];
    }
}

#pragma mark New

-(id)methodCall:(NSString*)methodName parameters:(NSDictionary*)parameters error:(NSError**)error {
    XMLRPCInterfaceConnection* conn = [[[XMLRPCInterfaceConnection alloc] init] autorelease];
    conn.delegate = self;
    return [conn methodCall:methodName params:[NSArray arrayWithObject:parameters] error:error];
}

@end

@implementation XMLRPCInterfaceConnection

-(id)methodCall:(NSString*)methodName params:(NSArray*)params error:(NSError**)error {
    NSXMLDocument* doc = _doc? _doc : [[[NSXMLDocument alloc] initWithXMLString:[N2XMLRPC requestWithMethodName:methodName arguments:params] options:0 error:NULL] autorelease];
    
    NSMutableDictionary* notificationObject = nil;
    if ([params count] < 1)
        notificationObject = [NSMutableDictionary dictionary];
    else {
        NSDictionary* dic = [params objectAtIndex:0];
        if ([dic isKindOfClass:[NSDictionary class]])
            notificationObject = [[dic mutableCopy] autorelease];
        else notificationObject = [NSMutableDictionary dictionary];
    }
    
    [notificationObject addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys: methodName, @"MethodName", methodName, @"methodName", doc, @"NSXMLDocument", self.address, @"peerAddress", nil]];
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixXMLRPCMessageNotification object:notificationObject];
    
    if ([[notificationObject valueForKey:@"Processed"] boolValue] || [notificationObject valueForKey:@"Response"] || [notificationObject valueForKey:@"NSXMLDocumentResponse"]) { // request processed, most probably by a plugin
        // new plugins are expected to return a value through the Response key, containing Cocoa values (NSNumber, NSArray, NSDictionary...)
        id response = [notificationObject valueForKey:@"Response"];
        if (response)
            return response;
        // older plugins returned a NSXMLDocument in the NSXMLDocumentResponse key
        doc = [notificationObject valueForKey:@"NSXMLDocumentResponse"];
        return [N2XMLRPC ParseElement:[[doc objectsForXQuery:@"/methodResponse/params/param/value" error:NULL] objectAtIndex:0]];
    }
    
    return [super methodCall:methodName params:params error:error];
}

@end

// TODO: announce with bonjour type _http._tcp.
