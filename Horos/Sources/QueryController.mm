/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "QueryController.h"
#import "WaitRendering.h"
#import "QueryFilter.h"
#import "AppController.h"
#import "ImageAndTextCell.h"
#import "DCMCalendarDate.h"
#import "DCMNetServiceDelegate.h"
#import "QueryArrayController.h"
//#import "AdvancedQuerySubview.h"
#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import "DCMTKSeriesQueryNode.h"
#import "BrowserController.h"
#import "DCMTKQueryRetrieveSCP.h"
#import "DICOMToNSString.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "PieChartImage.h"
#import "OpenGLScreenReader.h"
#import "Notifications.h"
#import "NSUserDefaults+OsiriX.h"
#import "N2Debug.h"
#import "DicomDatabase.h"
#import "DicomStudy.h"
#import "CIADICOMField.h"
#import "N2Stuff.h"
#import "DicomFile.h"
#import "N2Debug.h"

#include "osconfig.h"

#include "dcvrsl.h"
#include "ofcast.h"
#include "ofstd.h"
#include "dctk.h"
#include "dcuid.h"

#define INCLUDE_CSTDIO
#include "ofstdinc.h"

#include "url.h"

static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *AccessionNumber = @"AccessionNumber";
static NSString *StudyDescription = @"StudyDescription";
static NSString *StudyComments = @"StudyComments";
static NSString *PatientBirthDate = @"PatientBirthDate";
static NSString *ReferringPhysician = @"ReferringPhysiciansName";
static NSString *InstitutionName = @"InstitutionName";
static NSString *InterpretationStatusID = @"InterpretationStatusID";

static QueryController *currentQueryController = nil;
static QueryController *currentAutoQueryController = nil;
static NSMutableArray *studyArrayInstanceUID = [[NSMutableArray alloc] init], *studyArrayID = [[NSMutableArray alloc] init];
static NSString *kComputeStudyArrayInstanceUIDLock = @"computeStudyArrayInstanceUID";
static BOOL afterDelayRefresh = NO;
static NSMutableDictionary *previousAutoRetrieve = [[NSMutableDictionary alloc] init];

static int inc = 0;

extern "C"
{
	extern const char *GetPrivateIP();
};

@implementation QueryController

@synthesize autoQuery;
@synthesize autoQueryLock;
@synthesize outlineView, DatabaseIsEdited, currentAutoQR, authView;

+ (void) queryTest: (NSDictionary*) aServer
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    QueryArrayController *qm = nil;
	NSArray *array = nil;
	
    NSCalendarDate *date = [NSCalendarDate dateWithYear: 2013 month: 1 day: 17 hour: 0 minute: 0 second: 1 timeZone: nil];
    
    for( int i = 0; i < 90; i++)
    {
        [NSThread sleepForTimeInterval: 0.1];
        
        BOOL succeed = NO;
        while( succeed == NO)
        {
            for( int h = 8; h < 15; h+=3)
            {
                @try
                {
                    qm = [[[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer] autorelease];
                    
                    NSCalendarDate *endDate = [date dateByAddingYears: 0 months: 0 days: 0 hours: 0 minutes: 0 seconds: 0];
                    
                    [qm addFilter: [NSString stringWithFormat: @"%@-%@", [[DCMCalendarDate dicomDateWithDate: date] dateString], [[DCMCalendarDate dicomDateWithDate: endDate] dateString]] forDescription:@"StudyDate"];
                    
                    NSString *studyTime = [NSString stringWithFormat: @"%02d0000.000-%02d0000.000", h, h+3];
                    [qm addFilter: studyTime forDescription:@"StudyTime"];
                    
                    [qm performQuery: NO];
                    
                    array = [qm queries];
                    
//                    NSLog( @"date: %@ time: %@ count: %d", date, studyTime, array.count);
                    
                    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary: [qm parameters]];
                    
                    for( DCMTKStudyQueryNode *object in array)
                    {
                        [object setShowErrorMessage: NO];
                        
                        [dictionary setObject: [object valueForKey:@"calledAET"] forKey:@"calledAET"];
                        [dictionary setObject: [object valueForKey:@"hostname"] forKey:@"hostname"];
                        [dictionary setObject: [object valueForKey:@"port"] forKey:@"port"];
                        [dictionary setObject: [object valueForKey:@"transferSyntax"] forKey:@"transferSyntax"];
                        
                        if( [[object theDescription] hasPrefix: @"Mg"] == NO && [[object theDescription] hasPrefix: @"Us"] == NO && [[object theDescription] hasPrefix: @"Ct"] == NO && [[object theDescription] hasPrefix: @"Mr"] == NO)
                            [object move: dictionary];
                    }
                    
                    succeed = YES;
                }
                @catch (NSException * e)
                {
                    NSLog( @"%@",  [e description]);
                }
            }
        }
        
        date = [date dateByAddingYears: 0 months: 0 days: 1 hours: 0 minutes: 0 seconds: 0];
        
        NSLog( @"%@", date);
    }
    
    [pool release];
}

+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer
{
	return [QueryController queryStudyInstanceUID: an server: aServer showErrors: YES];
}

+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer showErrors: (BOOL) showErrors
{
	QueryArrayController *qm = nil;
	NSArray *array = nil;
	
	@try
	{
		// aServer = [[QueryController currentQueryController] TLSAskPrivateKeyPasswordForServer:aServer];
		qm = [[[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer] autorelease];
		
		NSString *filterValue = [an stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([filterValue length] > 0)
		{
			[qm addFilter:filterValue forDescription:@"StudyInstanceUID"];
			[qm performQuery: showErrors];
			array = [qm queries];
		}
		
		for( id a in array)
		{
			if( [a isMemberOfClass:[DCMTKStudyQueryNode class]] == NO)
				NSLog( @"warning : [item isMemberOfClass:[DCMTKStudyQueryNode class]] == NO");
		}
	}
	@catch (NSException * e)
	{
		NSLog( @"%@",  [e description]);
	}
	
	return array;
}

+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer
{
	return [QueryController queryAndRetrieveAccessionNumber: an server: aServer showErrors: YES];
}

+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer showErrors: (BOOL) showErrors
{
	QueryArrayController *qm = nil;
	int error = 0;
	
	@try
	{
		// aServer = [[QueryController currentQueryController] TLSAskPrivateKeyPasswordForServer:aServer];
		qm = [[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer];
		
		NSString *filterValue = [an stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([filterValue length] > 0)
		{
			[qm addFilter:filterValue forDescription:@"AccessionNumber"];
			
			[qm performQuery: showErrors];
			
			NSArray *array = [qm queries];
			
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary: [qm parameters]];
//			NetworkMoveDataHandler *moveDataHandler = [NetworkMoveDataHandler moveDataHandler];
//			[dictionary setObject:moveDataHandler  forKey:@"receivedDataHandler"];
			
			for( DCMTKQueryNode	*object in array)
			{
				[object setShowErrorMessage: showErrors];
				 
				[dictionary setObject: [object valueForKey:@"calledAET"] forKey:@"calledAET"];
				[dictionary setObject: [object valueForKey:@"hostname"] forKey:@"hostname"];
				[dictionary setObject: [object valueForKey:@"port"] forKey:@"port"];
				[dictionary setObject: [object valueForKey:@"transferSyntax"] forKey:@"transferSyntax"];
				
				FILE * pFile = fopen ("/tmp/kill_all_storescu", "r");
				if( pFile)
					fclose (pFile);
				else
					[object move: dictionary];
			}
			
			if( [array count] == 0) error = -3;
		}
	}
	@catch (NSException * e)
	{
		NSLog( @"%@",  [e description]);
		error = -2;
	}
	
	[qm release];
	
	return error;
}

+ (void) retrieveStudies:(NSArray*) studies showErrors: (BOOL) showErrors
{
    [QueryController retrieveStudies: studies showErrors: showErrors checkForPreviousAutoRetrieve: NO];
}

+ (void) retrieveStudies:(NSArray*) studies showErrors: (BOOL) showErrors checkForPreviousAutoRetrieve: (BOOL) checkForPreviousAutoRetrieve
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    int i = 0;
    for( DCMTKQueryNode	*object in studies)
    {
        [NSThread currentThread].progress = (float) i++ / (float) studies.count;
        if( object.theDescription)
            [NSThread currentThread].status = [NSString stringWithFormat: @"%@ - %@", object.name, object.theDescription];
        else
            [NSThread currentThread].status = [NSString stringWithFormat: @"%@", object.name];
        if( [NSThread currentThread].isCancelled)
            break;
        
        BOOL proceedToDownload = YES;
        
        if( checkForPreviousAutoRetrieve)
        {
            @synchronized( previousAutoRetrieve)
            {
                NSString *stringID = [QueryController stringIDForStudy: object];
                
                NSNumber *previousNumberOfFiles = [previousAutoRetrieve objectForKey: stringID];
                int totalFiles = [[object valueForKey:@"numberImages"] intValue];
                
                // We only want to re-retrieve the study if they are new files compared to last time... we are maybe currently in the middle of a retrieve...
                
                if( [previousNumberOfFiles intValue] != totalFiles)
                {
                    [previousAutoRetrieve setValue: [NSNumber numberWithInt: totalFiles] forKey: stringID];
                }
                else
                    proceedToDownload = NO;
            }
        }
        
        if( proceedToDownload)
        {
            @try
            {
                [object setShowErrorMessage: showErrors];
                
                [dictionary setObject: [object valueForKey:@"calledAET"] forKey:@"calledAET"];
                [dictionary setObject: [object valueForKey:@"hostname"] forKey:@"hostname"];
                [dictionary setObject: [object valueForKey:@"port"] forKey:@"port"];
                [dictionary setObject: [object valueForKey:@"transferSyntax"] forKey:@"transferSyntax"];
                [dictionary setObject: [[object extraParameters] valueForKey: @"retrieveMode"] forKey: @"retrieveMode"];
                 
                FILE * pFile = fopen ("/tmp/kill_all_storescu", "r");
                if( pFile)
                    fclose (pFile);
                else
                    [object move: dictionary retrieveMode: [[[object extraParameters] valueForKey: @"retrieveMode"] intValue]];
            }
            @catch( NSException *e) {
                N2LogExceptionWithStackTrace( e);
            }
            
            if( checkForPreviousAutoRetrieve)
            {
                @synchronized( previousAutoRetrieve)
                {
                    [previousAutoRetrieve removeObjectForKey: [QueryController stringIDForStudy: object]];
                }
            }
        }
    }
}

+ (NSMutableArray*) queryStudiesForFilters:(NSDictionary*) filters servers: (NSArray*) serversList showErrors: (BOOL) showErrors
{
	QueryArrayController *qm = nil;
	NSMutableArray *studies = [NSMutableArray array];
	
	@try
	{
        for( NSDictionary *server in serversList)
        {
            [NSThread currentThread].status = [server valueForKey: @"Description"];
            
            qm = [[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer: server];
            
            if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
                //Specific Character Set
                [qm addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
            
            NSMutableDictionary *f = [NSMutableDictionary dictionary];
            
            if( [filters valueForKey: @"AccessionNumber"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_accession_number"])
                [f setObject: [filters valueForKey: @"AccessionNumber"] forKey: @"AccessionNumber"];
            
            if( [filters valueForKey: @"accessionNumber"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_accession_number"])
                [f setObject: [filters valueForKey: @"accessionNumber"] forKey: @"AccessionNumber"];
            
            if( [filters valueForKey: @"StudyDescription"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_description"])
                [f setObject: [filters valueForKey: @"StudyDescription"] forKey: @"StudyDescription"];
            
            if( [filters valueForKey: @"Comments"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_comments"])
                [f setObject: [filters valueForKey: @"Comments"] forKey: StudyComments];
            
            if( [filters valueForKey: @"StudyID"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                [f setObject: [filters valueForKey: @"StudyID"] forKey: @"StudyID"];
            
            if( [filters valueForKey: @"studyID"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                [f setObject: [filters valueForKey: @"studyID"] forKey: @"StudyID"];
            
            if( [filters valueForKey: @"StudyInstanceUID"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                [f setObject: [filters valueForKey: @"StudyInstanceUID"] forKey: @"StudyInstanceUID"];
            
            if( [filters valueForKey: @"studyInstanceUID"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                [f setObject: [filters valueForKey: @"studyInstanceUID"] forKey: @"StudyInstanceUID"];
            
            if( [filters valueForKey: PatientName] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_name"])
                [f setObject: [filters valueForKey: PatientName] forKey: PatientName];
            
            if( [filters valueForKey: @"patientName"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_name"])
                [f setObject: [filters valueForKey: @"patientName"] forKey: PatientName];
            
            if( [filters valueForKey: PatientID] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                [f setObject: [filters valueForKey: PatientID] forKey: PatientID];
            
            if( [filters valueForKey: @"patientID"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                [f setObject: [filters valueForKey: @"patientID"] forKey: PatientID];
            
            if( [filters valueForKey: PatientBirthDate] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_birthdate"])
                [f setObject: [DCMCalendarDate queryDate: [[filters valueForKey: PatientBirthDate] descriptionWithCalendarFormat:@"%Y%m%d" timeZone: nil locale:nil]] forKey: PatientBirthDate];
            
            if( [[filters valueForKey: @"date"] intValue] != 0 && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_study_date"])
            {
                QueryFilter *dateQueryFilter = nil, *timeQueryFilter = nil;
                
                [QueryController getDateAndTimeQueryFilterWithTag: [[filters valueForKey: @"date"] intValue] fromDate: [filters valueForKey: @"fromDate"] toDate: [filters valueForKey: @"toDate"] date: &dateQueryFilter time: &timeQueryFilter];
                
                if( dateQueryFilter)
                    [f setObject: [DCMCalendarDate queryDate: dateQueryFilter.filteredValue] forKey: @"StudyDate"];
                
                if( timeQueryFilter)
                    [f setObject: [DCMCalendarDate queryDate: timeQueryFilter.filteredValue] forKey: @"StudyTime"];
            }
            
            if( [[filters valueForKey: @"modality"] count] > 0)
            {
                if( f.count > 0 || [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_modality"])
                {
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
                        [f setObject: [[filters valueForKey: @"modality"] componentsJoinedByString: @"\\"] forKey: @"ModalitiesinStudy"];
                    else
                        [f setObject: [[filters valueForKey: @"modality"] componentsJoinedByString: @"\\"] forKey: @"Modality"];
                }
            }
            
            // Remove queries with only **** characters
            NSMutableArray *keysToBeRemoved = [NSMutableArray array];
            for( NSString *key in f)
            {
                if( [[f objectForKey: key] isKindOfClass: [NSString class]])
                {
                    NSString *s = [f objectForKey: key];
                    
                    if( [s rangeOfString:@"*"].location != NSNotFound && [s stringByReplacingOccurrencesOfString: @"*" withString:@""].length <= 2)
                    {
                        [keysToBeRemoved addObject: key];
                        NSLog( @"---- too small query (%@) -> removed: %@", key, s);
                    }
                    
                    s = [s stringByReplacingOccurrencesOfString: @"*" withString:@""];
                    
                    if( s.length == 0)
                    {
                        [keysToBeRemoved addObject: key];
                        NSLog( @"---- empty key (%@) -> removed", key);
                    }
                }
            }
            [f removeObjectsForKeys: keysToBeRemoved];
            
            [[qm filters] addEntriesFromDictionary: f];
            
            if( [[qm filters] count] == 0 || f.count == 0)
            {
                NSLog( @"***** no query parameters for queryStudiesForFilters: query not performed.");
            }
            else
            {
                [NSThread currentThread].supportsCancel = YES;
                
                [qm performQuery: showErrors];
                
                NSArray *studiesForThisNode = [qm queries];
                
                if( studiesForThisNode == nil)
                    NSLog( @"queryStudiesForFilters failed for this node: %@", [server valueForKey: @"Description"]);
                
                NSArray *uidArray = [studies valueForKey: @"uid"];
                
                for( NSUInteger x = 0 ; x < [studiesForThisNode count] ; x++)
                {
                    DCMTKStudyQueryNode *s = [studiesForThisNode objectAtIndex: x];
                    
                    if( s)
                    {
                        NSUInteger index = [uidArray indexOfObject: [s valueForKey:@"uid"]];
                        
                        if( index == NSNotFound) // not found
                            [studies addObject: s];
                        else 
                        {
                            if( [[studies objectAtIndex: index] valueForKey: @"numberImages"] && [s valueForKey: @"numberImages"])
                            {
                                if( [[[studies objectAtIndex: index] valueForKey: @"numberImages"] intValue] < [[s valueForKey: @"numberImages"] intValue])
                                    [studies replaceObjectAtIndex: index withObject: s];
                            }
                        }
                    }
                }
            }
            
            [qm release];
        }
	}
	@catch (NSException * e)
	{
		NSLog( @"%@",  [e description]);
	}
	
	return studies;
}

+ (NSArray*) queryStudiesForPatient:(DicomStudy*) study usePatientID:(BOOL) usePatientID usePatientName:(BOOL) usePatientName usePatientBirthDate: (BOOL) usePatientBirthDate servers: (NSArray*) serversList showErrors: (BOOL) showErrors
{
    if( usePatientID == NO && usePatientName == NO && usePatientBirthDate == NO)
    {
        NSLog( @"****** QR: usePatientID == NO && usePatientName == NO && usePatientBirthDate == NO");
        return 0;
    }
    
    if( usePatientName && study.name.length == 0)
    {
        NSLog( @"****** QR: usePatientName == YES && study.name.length == 0 : %@", study);
        return 0;
    }
    
    if( usePatientBirthDate && study.dateOfBirth == nil)
    {
        NSLog( @"****** QR: usePatientBirthDate == YES && study.dateOfBirth == 0 : %@", study);
        return 0;
    }
    
    if( usePatientID && study.patientID.length == 0)
    {
        NSLog( @"****** QR: usePatientID && study.patientID.length == 0 : %@", study);
        return 0;
    }
    
    if( usePatientName && usePatientBirthDate == NO && usePatientID == NO)
    {
        NSLog( @"****** QR: cannot query history on patient's name only, patient birthdate or patient ID required !");
        return 0;
    }
    
#ifndef NDEBUG
    NSLog( @"------- queryStudiesForPatient: %@", study.name);
#endif
    
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    
    if( usePatientBirthDate)
        [filters setObject: study.dateOfBirth forKey: PatientBirthDate];
    
    if( usePatientID)
        [filters setObject: study.patientID forKey: PatientID];
    
    NSMutableArray *studies = [QueryController queryStudiesForFilters: filters servers: serversList showErrors: showErrors];
    
    if( usePatientName)
    {
        for( int x = (long)[studies count]-1 ; x >= 0 ; x--)
        {
            DCMTKStudyQueryNode *s = [studies objectAtIndex: x];
            
            if( [[DicomFile NSreplaceBadCharacter: s.name] isEqualToString: study.name] == NO)
                    [studies removeObjectAtIndex: x];
        }
    }
    
	return studies;
}

+ (QueryController*) currentQueryController
{
	return currentQueryController;
}

+ (QueryController*) currentAutoQueryController
{
	return currentAutoQueryController;
}

+ (BOOL) echo: (NSString*) address port:(int) port AET:(NSString*) aet
{
	return [QueryController echoServer:[NSDictionary dictionaryWithObjectsAndKeys:address, @"Address", [NSNumber numberWithInt:port], @"Port", aet, @"AETitle", [NSNumber numberWithBool:NO], @"TLSEnabled", nil]];
}

+ (BOOL) echoServer:(NSDictionary*)serverParameters
{
	@try
	{
		NSString *address = [serverParameters objectForKey:@"Address"];
		NSNumber *port = [serverParameters objectForKey:@"Port"];
		NSString *aet = [serverParameters objectForKey:@"AETitle"];
		
		NSString *uniqueStringID = [NSString stringWithFormat:@"%d.%d.%d", getpid(), inc++, (int) random()];
		
		NSTask* theTask = [[[NSTask alloc]init]autorelease];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]] == NO)
			return YES;
		
		[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]];
		
		[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
		[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]];
		
		//NSArray *args = [NSArray arrayWithObjects: address, [NSString stringWithFormat:@"%d", port], @"-aet", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"-aec", aet, @"-to", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-ta", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-td", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], nil];
		
		NSMutableArray *args = [NSMutableArray array];
		[args addObject: address];
		[args addObject: [NSString stringWithFormat:@"%d", [port intValue]]];
		[args addObject: @"-aet"]; // set my calling AE title
		[args addObject: [NSUserDefaults defaultAETitle]]; 
		[args addObject: @"-aec"]; // set called AE title of peer
		[args addObject: aet];
		[args addObject: @"-to"]; // timeout for connection requests
		[args addObject: [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"]];
		[args addObject: @"-ta"]; // timeout for ACSE messages
		[args addObject: [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"]];
		[args addObject: @"-td"]; // timeout for DIMSE messages
		[args addObject: [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"]];
		
		if([[serverParameters objectForKey:@"TLSEnabled"] boolValue])
		{
			//[DDKeychain lockTmpFiles];
			
			// TLS support. Options listed here http://support.dcmtk.org/docs/echoscu.html
			
			if([[serverParameters objectForKey:@"TLSAuthenticated"] boolValue])
			{
				[args addObject:@"--enable-tls"]; // use authenticated secure TLS connection

				[DICOMTLS generateCertificateAndKeyForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID]; // export certificate/key from the Keychain to the disk
				[args addObject:[DICOMTLS keyPathForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID]]; // [p]rivate key file
				[args addObject:[DICOMTLS certificatePathForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID]]; // [c]ertificate file: string
						
				[args addObject:@"--use-passwd"];
				[args addObject: [DICOMTLS TLS_PRIVATE_KEY_PASSWORD]];
			}
			else
				[args addObject:@"--anonymous-tls"]; // use secure TLS connection without certificate
			
			// key and certificate file format options:
			[args addObject:@"--pem-keys"];
					
			//ciphersuite options:
			for (NSDictionary *suite in [serverParameters objectForKey:@"TLSCipherSuites"])
			{
				if ([[suite objectForKey:@"Supported"] boolValue])
				{
					[args addObject:@"--cipher"]; // add ciphersuite to list of negotiated suites
					[args addObject:[suite objectForKey:@"Cipher"]];
				}
			}
			
			if([[serverParameters objectForKey:@"TLSUseDHParameterFileURL"] boolValue])
			{
				[args addObject:@"--dhparam"]; // read DH parameters for DH/DSS ciphersuites
				[args addObject:[serverParameters objectForKey:@"TLSDHParameterFileURL"]];
			}
			
			// peer authentication options:
			TLSCertificateVerificationType verification = (TLSCertificateVerificationType)[[serverParameters objectForKey:@"TLSCertificateVerification"] intValue];
			if(verification==RequirePeerCertificate)
				[args addObject:@"--require-peer-cert"]; //verify peer certificate, fail if absent (default)
			else if(verification==VerifyPeerCertificate)
				[args addObject:@"--verify-peer-cert"]; //verify peer certificate if present
			else //IgnorePeerCertificate
				[args addObject:@"--ignore-peer-cert"]; //don't verify peer certificate	
			
			// certification authority options:
			if(verification==RequirePeerCertificate || verification==VerifyPeerCertificate)
			{
				NSString *trustedCertificatesDir = [NSString stringWithFormat:@"%@%@", TLS_TRUSTED_CERTIFICATES_DIR, uniqueStringID];
				[DDKeychain KeychainAccessExportTrustedCertificatesToDirectory:trustedCertificatesDir];
				NSArray *trustedCertificates = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:trustedCertificatesDir error:nil];
				
				//[args addObject:@"--add-cert-dir"]; // add certificates in d to list of certificates  .... needs to use OpenSSL & rename files (see http://forum.dicom-cd.de/viewtopic.php?p=3237&sid=bd17bd76876a8fd9e7fdf841b90cf639 )
				for (NSString *cert in trustedCertificates)
				{
					[args addObject:@"--add-cert-file"];
					[args addObject:[trustedCertificatesDir stringByAppendingPathComponent:cert]];
				}
			}
			
			// pseudo random generator options.
			// We initialize the pseudo-random number generator with the content of the screen which is is hardly predictable for an attacker
			// see http://www.mevis-research.de/~meyer/dcmtk/docs_352/dcmtls/randseed.txt
			[DDKeychain generatePseudoRandomFileToPath:TLS_SEED_FILE];
			[args addObject:@"--seed"]; // seed random generator with contents of f
			[args addObject:TLS_SEED_FILE];		
		}
		
		[theTask setArguments:args];
		[theTask launch];
        
        WaitRendering *wait = nil;
        
        if( [NSThread isMainThread])
        {
            NSString *description = [serverParameters objectForKey: @"Description"];
            
            if( description == nil)
                description = @"";
            
            wait = [[[WaitRendering alloc] init: [NSString stringWithFormat: NSLocalizedString( @"DICOM Echo %@...", nil), description]] autorelease];
        }
        
        [wait setCancel: YES];
        [wait showWindow:self];
        [wait start];
        
        while( [theTask isRunning])
        {
            [NSThread sleepForTimeInterval: 0.1];
            
            [wait run];
            if( [wait aborted])
                break;
		}
        
        [wait end];
        
		if([[serverParameters objectForKey:@"TLSEnabled"] boolValue])
		{
			//[DDKeychain unlockTmpFiles];
			[[NSFileManager defaultManager] removeItemAtPath:[DICOMTLS keyPathForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID] error:NULL];
			[[NSFileManager defaultManager] removeItemAtPath:[DICOMTLS certificatePathForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID] error:NULL];
			[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", TLS_TRUSTED_CERTIFICATES_DIR, uniqueStringID] error:NULL];
		}
		
        if( [wait aborted])
            return NO;
        
		if( [theTask terminationStatus] == 0) return YES;
		else return NO;
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return YES;
}

- (void) setAutoRefreshQueryResults: (NSInteger) i
{
	if( autoQuery)
		[[NSUserDefaults standardUserDefaults] setInteger: i forKey: @"autoRefreshQueryResultsAutoQR"];
	else
		[[NSUserDefaults standardUserDefaults] setInteger: i forKey: @"autoRefreshQueryResults"];
}

- (NSInteger) autoRefreshQueryResults
{
	if( autoQuery)
		return [[NSUserDefaults standardUserDefaults] integerForKey: @"autoRefreshQueryResultsAutoQR"];
	else
		return [[NSUserDefaults standardUserDefaults] integerForKey: @"autoRefreshQueryResults"];
}

- (IBAction) cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction) ok:(id)sender
{
	[NSApp stopModal];
}

- (void) autoRetrieveSettings: (id) sender
{
	NSNumber *NumberOfPreviousStudyToRetrieve = [[NSUserDefaults standardUserDefaults] objectForKey: @"NumberOfPreviousStudyToRetrieve"];
	NSNumber *retrieveSameModality = [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameModality"];
	NSNumber *retrieveSameDescription = [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameDescription"];

	[NSApp beginSheet:	autoRetrieveWindow
				modalForWindow: self.window
				modalDelegate: nil
				didEndSelector: nil
				contextInfo: nil];
			
	int result = [NSApp runModalForWindow: autoRetrieveWindow];
	
	[autoRetrieveWindow orderOut: self];
	
	[NSApp endSheet: autoRetrieveWindow];
	
	if( result != NSRunStoppedResponse) // Cancel
	{
        if( NumberOfPreviousStudyToRetrieve)
            [[NSUserDefaults standardUserDefaults] setObject: NumberOfPreviousStudyToRetrieve forKey: @"NumberOfPreviousStudyToRetrieve"];
        
        if( retrieveSameModality)
            [[NSUserDefaults standardUserDefaults] setObject: retrieveSameModality forKey: @"retrieveSameModality"];
        
        if( retrieveSameDescription)
            [[NSUserDefaults standardUserDefaults] setObject: retrieveSameDescription forKey: @"retrieveSameDescription"];
	}
    else
    {
        @synchronized( autoQRInstances)
        {
            if( [[NSUserDefaults standardUserDefaults] objectForKey: @"NumberOfPreviousStudyToRetrieve"])
                [[autoQRInstances objectAtIndex: currentAutoQR] setObject:[[NSUserDefaults standardUserDefaults] objectForKey: @"NumberOfPreviousStudyToRetrieve"]  forKey: @"NumberOfPreviousStudyToRetrieve"];
            
            if( [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameModality"])
                [[autoQRInstances objectAtIndex: currentAutoQR] setObject: [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameModality"] forKey: @"retrieveSameModality"];
            
            if( [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameDescription"])
                [[autoQRInstances objectAtIndex: currentAutoQR] setObject: [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameDescription"] forKey: @"retrieveSameDescription"];
        }
        
        [self saveSettings];
    }
}

- (IBAction) switchAutoRetrieving: (id) sender
{
	NSLog( @"auto-retrieving switched");
	
	@synchronized( previousAutoRetrieve)
	{
		[previousAutoRetrieve removeAllObjects];
	}
	
	if( autoQuery == YES && [[[autoQRInstances objectAtIndex: currentAutoQR] objectForKey: @"autoRetrieving"] boolValue])
	{
		[self refreshAutoQR: self];
	}
}

- (IBAction) lockAutoQRWindow:(id)sender
{
    
}

- (IBAction) deleteAutoQRInstance:(id)sender
{
    // Delete the instance
    if (NSRunCriticalAlertPanel( NSLocalizedString(@"Delete Auto QR Instance", nil),  NSLocalizedString(@"Are you sure you want to delete the current Auto QR Instance (%@)?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil, [[autoQRInstances objectAtIndex: currentAutoQR] objectForKey: @"instanceName"]) == NSAlertDefaultReturn)
    {
        [self willChangeValueForKey: @"instancesMenuList"];
        
        @synchronized( autoQRInstances)
        {
            int newIndex = currentAutoQR-1;
            [autoQRInstances removeObjectAtIndex: currentAutoQR];
            currentAutoQR = -1;
            [self setCurrentAutoQR: newIndex];
        }
        
        [self didChangeValueForKey: @"instancesMenuList"];
    }
}

- (IBAction) endCreateAutoQRInstance:(id) sender
{
	if( [sender tag])
	{
		if( [[autoQRInstanceName stringValue] isEqualToString: @""])
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Create Auto QR Instance", nil),  NSLocalizedString(@"Give a name !", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return;
		}
		
        for( NSDictionary *instance in autoQRInstances)
        {
            if( [[instance objectForKey: @"instanceName"] isEqualToString: [autoQRInstanceName stringValue]])
            {
                NSRunCriticalAlertPanel( NSLocalizedString(@"Create Auto QR Instance", nil),  NSLocalizedString(@"An Auto QR Instance with the same name already exists.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                return;
            }
		}
        
        [addAutoQRInstanceWindow orderOut: sender];
        [NSApp endSheet: addAutoQRInstanceWindow returnCode: [sender tag]];
        
        [self willChangeValueForKey: @"instancesMenuList"];
        
        @synchronized( autoQRInstances)
        {
            NSMutableDictionary *preset = [self savePresetInDictionaryWithDICOMNodes: YES];
            [preset setObject: [autoQRInstanceName stringValue] forKey: @"instanceName"];
            [autoQRInstances addObject: preset];
            
            [self setCurrentAutoQR: (long)[autoQRInstances count] -1];
            
            [self emptyPreset: self];
            
            self.autoRefreshQueryResults = 0;
            [[autoQRInstances objectAtIndex: currentAutoQR] setObject: [NSNumber numberWithInt: self.autoRefreshQueryResults] forKey: @"autoRefreshQueryResults"];
            
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"autoRetrieving"];
            [[autoQRInstances objectAtIndex: currentAutoQR] setObject: [NSNumber numberWithBool: NO] forKey: @"autoRetrieving"];
        }
        
        [self didChangeValueForKey: @"instancesMenuList"];
	}
	else
    {
        [addAutoQRInstanceWindow orderOut: sender];
        [NSApp endSheet: addAutoQRInstanceWindow returnCode: [sender tag]];
    }
}

- (NSArray*) instancesMenuList
{
    NSMutableArray *array = [NSMutableArray array];
    
    for( NSDictionary *d in autoQRInstances)
    {
        [array addObject: [d objectForKey: @"instanceName"]];
    }
    
    return array;
}

- (IBAction) createAutoQRInstance:(id)sender
{
    if( autoQRInstances.count >= MAXINSTANCE)
    {
        NSRunCriticalAlertPanel( NSLocalizedString( @"Create Auto QR Instance", nil),  NSLocalizedString(@"Too many Auto QR Instances already exist.", nil), NSLocalizedString( @"OK", nil), nil, nil);
        return;
    }
    
    [autoQRInstanceName setStringValue: @""];
    
    [NSApp beginSheet: addAutoQRInstanceWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) setCurrentAutoQR: (int) index
{
    [self saveSettings];
    
    @synchronized( autoQRInstances)
    {
        if( autoQRInstances.count == 0)
        {
            index = 0;
            
            [self emptyPreset: self];
            
            self.autoRefreshQueryResults = 0;
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"autoRetrieving"];
            
            NSMutableDictionary *preset = [self savePresetInDictionaryWithDICOMNodes: YES];
            [preset setObject: NSLocalizedString( @"Default Instance", nil) forKey: @"instanceName"];
            [autoQRInstances addObject: preset];
        }
        
        if( currentAutoQR >= 0) //During deleteAutoQRInstance:
        {
            if( resultArray)
                [[autoQRInstances objectAtIndex: currentAutoQR] setObject: [[resultArray copy] autorelease] forKey: @"resultArray"];
            else
                [[autoQRInstances objectAtIndex: currentAutoQR] removeObjectForKey: @"resultArray"];
        }
        
        if( index < 0)
            index = (long)autoQRInstances.count -1;
        
        if( index >= autoQRInstances.count)
            index = 0;
        
        currentAutoQR = index;
        
        self.window.title = [NSString stringWithFormat: @"%@ : %@", NSLocalizedString( @"DICOM Auto Query/Retrieve", nil), [[autoQRInstances objectAtIndex: currentAutoQR] objectForKey: @"instanceName"]];
        [self applyPresetDictionary: [autoQRInstances objectAtIndex: currentAutoQR]];
        
        [self refreshList: [[autoQRInstances objectAtIndex: currentAutoQR] objectForKey: @"resultArray"]];
        
        if( autoQRInstances.count <= 1)
            [autoQRNavigationControl setEnabled: NO];
        else
            [autoQRNavigationControl setEnabled: YES];
    }
}

- (IBAction)changeAutoQRInstance:(NSSegmentedControl*)sender
{
    int i = currentAutoQR;
    
    if( [sender selectedSegment] == 0)
        i--;
    else
        i++;
    
    [self setCurrentAutoQR: i];
}

- (NSMutableDictionary*) savePresetInDictionaryWithDICOMNodes: (BOOL) includeDICOMNodes
{
	NSMutableDictionary *presets = [NSMutableDictionary dictionary];
	
	if( includeDICOMNodes)
	{
		NSMutableArray *srcArray = [NSMutableArray array];
        NSMutableArray *srcAETitleArray = [NSMutableArray array];
		for( id src in sourcesArray)
		{
			if( [[src valueForKey: @"activated"] boolValue] == YES)
            {
				[srcArray addObject: [NSString stringWithString: [src valueForKey: @"AddressAndPort"]]];
                [srcAETitleArray addObject: [NSString stringWithString: [src valueForKey: @"AETitle"]]];
            }
		}
		
		if( [srcArray count] == 0 && [sourcesTable selectedRow] >= 0)
        {
			[srcArray addObject: [NSString stringWithString: [[sourcesArray objectAtIndex: [sourcesTable selectedRow]] valueForKey: @"AddressAndPort"]]];
            [srcAETitleArray addObject: [NSString stringWithString: [[sourcesArray objectAtIndex: [sourcesTable selectedRow]] valueForKey: @"AETitle"]]];
		}
        
		[presets setValue: srcArray forKey: @"DICOMNodes"];
        [presets setValue: srcAETitleArray forKey: @"DICOMNodesAETitle"];
	}
	
	[presets setValue: [searchFieldName stringValue] forKey: @"searchFieldName"];
	[presets setValue: [searchFieldRefPhysician stringValue] forKey: @"searchFieldRefPhysician"];
    [presets setValue: [searchInstitutionName stringValue] forKey: @"searchInstitutionName"];
    [presets setValue: @([statusFilterMatrix selectedTag]) forKey:@"searchStatus"];
	[presets setValue: [searchFieldID stringValue] forKey: @"searchFieldID"];
	[presets setValue: [searchFieldAN stringValue] forKey: @"searchFieldAN"];
	[presets setValue: [searchFieldStudyDescription stringValue] forKey: @"searchFieldStudyDescription"];
	[presets setValue: [searchFieldComments stringValue] forKey: @"searchFieldComments"];
    [presets setValue: [searchCustomField stringValue] forKey: @"searchCustomField"];
    [presets setValue: [[dicomFieldsMenu selectedItem] title] forKey: @"searchCustomFieldDICOM"];
	
	[presets setValue: [NSNumber numberWithInt: [dateFilterMatrix selectedTag]] forKey: @"dateFilterMatrix"];
	[presets setValue: [NSNumber numberWithInt: [birthdateFilterMatrix selectedTag]] forKey: @"birthdateFilterMatrix"];
	
	NSMutableArray *cellsString = [NSMutableArray array];
	for( NSCell *cell in [modalityFilterMatrix cells])
	{
		if( [cell state] == NSOnState)
			[cellsString addObject: [cell title]];
	}
	[presets setValue: cellsString forKey: @"modalityStrings"];
	
	[presets setValue: [NSNumber numberWithInt: [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]]] forKey: @"PatientModeMatrix"];
	
	[presets setValue: [NSNumber numberWithDouble: [[fromDate dateValue] timeIntervalSinceReferenceDate]] forKey: @"fromDate"];
	[presets setValue: [NSNumber numberWithDouble: [[toDate dateValue] timeIntervalSinceReferenceDate]] forKey: @"toDate"];
	[presets setValue: [NSNumber numberWithDouble: [[searchBirth dateValue] timeIntervalSinceReferenceDate]] forKey: @"searchBirth"];
	
	[presets setValue: [NSNumber numberWithInt: self.autoRefreshQueryResults] forKey: @"autoRefreshQueryResults"];
    
    if( [[NSUserDefaults standardUserDefaults] objectForKey: @"autoRetrieving"])
        [presets setValue: [[NSUserDefaults standardUserDefaults] objectForKey: @"autoRetrieving"] forKey: @"autoRetrieving"];
    
    if( [[NSUserDefaults standardUserDefaults] objectForKey: @"NumberOfPreviousStudyToRetrieve"])
        [presets setValue: [[NSUserDefaults standardUserDefaults] objectForKey: @"NumberOfPreviousStudyToRetrieve"] forKey: @"NumberOfPreviousStudyToRetrieve"];
    
    if( [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameModality"])
        [presets setValue: [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameModality"] forKey: @"retrieveSameModality"];
    
    if( [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameDescription"])
        [presets setValue: [[NSUserDefaults standardUserDefaults] objectForKey: @"retrieveSameDescription"] forKey: @"retrieveSameDescription"];
    
	return presets;
}

- (IBAction) endAddPreset:(id) sender
{
	if( [sender tag])
	{
		if( [[presetName stringValue] isEqualToString: @""])
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Add Preset", nil),  NSLocalizedString(@"Give a name !", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return;
		}
		
		NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
		
		if( savedPresets == nil) savedPresets = [NSDictionary dictionary];
		
		NSString *psName = [presetName stringValue];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"includeDICOMNodes"])
			psName = [psName stringByAppendingString: NSLocalizedString( @" & DICOM Nodes", nil)];
		
		if( [savedPresets objectForKey: psName])
		{
			if (NSRunCriticalAlertPanel( NSLocalizedString(@"Add Preset", nil),  NSLocalizedString(@"A Preset with the same name already exists. Should I replace it with the current one?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) != NSAlertDefaultReturn) return;
		}
		
		NSDictionary *presets = [self savePresetInDictionaryWithDICOMNodes: [[NSUserDefaults standardUserDefaults] boolForKey: @"includeDICOMNodes"]];
		
		NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary: savedPresets];
		[m setValue: presets forKey: psName];
		
		[[NSUserDefaults standardUserDefaults] setObject: m forKey:@"QRPresets"];
		
		[self buildPresetsMenu];
	}
	
	[presetWindow orderOut:sender];
    [NSApp endSheet:presetWindow returnCode:[sender tag]];
}

- (void) addPreset:(id) sender
{
    [presetName setStringValue: @""];
    
	[NSApp beginSheet: presetWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) emptyPreset:(id) sender
{
	[searchFieldRefPhysician setStringValue: @""];
    [searchInstitutionName setStringValue: @""];
    [statusFilterMatrix selectCellWithTag: 0];
	[searchFieldName setStringValue: @""];
	[searchFieldID setStringValue: @""];
	[searchFieldAN setStringValue: @""];
	[searchFieldStudyDescription setStringValue: @""];
	[searchFieldComments setStringValue: @""];
	[dateFilterMatrix selectCellWithTag: 0];
	[birthdateFilterMatrix selectCellWithTag: 0];
	[modalityFilterMatrix deselectAllCells];
	[PatientModeMatrix selectTabViewItemAtIndex: 0];
	
	[searchFieldName selectText: self];
	
	queryButtonPressed = NO;
}

- (void) applyPresetDictionary: (NSDictionary *) presets
{
	if( [presets valueForKey: @"DICOMNodes"])
	{
		NSArray *r = [presets valueForKey: @"DICOMNodes"];
        NSArray *rAE = [presets valueForKey: @"DICOMNodesAETitle"];
		
		if( [r count])
		{
			[self willChangeValueForKey:@"sourcesArray"];
			
			for( id src in sourcesArray)
			{
				[src setValue: [NSNumber numberWithBool: NO] forKey: @"activated"];
			}
			
//			if( [r count] == 1)
//			{
//				for( id src in sourcesArray)
//				{
//					if( [[src valueForKey: @"AddressAndPort"] isEqualToString: [r lastObject]])
//					{
//						[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [sourcesArray indexOfObject: src]] byExtendingSelection: NO];
//						[sourcesTable scrollRowToVisible: [sourcesArray indexOfObject: src]];
//					}
//				}
//			}
//			else
//			{
				BOOL first = YES;
				
                for( int i = 0; i < r.count; i++)
                {
                    NSString *v = [r objectAtIndex: i];
                    
                    NSString *ae = nil;
                    if( i < rAE.count)
                        ae = [rAE objectAtIndex: i];
                    
                    for( id src in sourcesArray)
                    {
                        if( [[src valueForKey: @"AddressAndPort"] isEqualToString: v] && (ae == nil || [ae isEqualToString: [src valueForKey:@"AETitle"]]))
                        {
                            [src setValue: [NSNumber numberWithBool: YES] forKey: @"activated"];
                            
                            if( first)
                            {
                                first = NO;
                                [sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [sourcesArray indexOfObject: src]] byExtendingSelection: NO];
                                [sourcesTable scrollRowToVisible: [sourcesArray indexOfObject: src]];
                            }
                        }
                    }
                }
//			}
			
			[self didChangeValueForKey:@"sourcesArray"];
		}
	}
	
	if( [presets valueForKey: @"autoRefreshQueryResults"])
	{
		self.autoRefreshQueryResults = [[presets valueForKey:@"autoRefreshQueryResults"] intValue];
	}
	
	if( [presets valueForKey: @"searchFieldRefPhysician"])
		[searchFieldRefPhysician setStringValue: [presets valueForKey: @"searchFieldRefPhysician"]];
	
	if( [presets valueForKey: @"searchInstitutionName"])
		[searchInstitutionName setStringValue: [presets valueForKey: @"searchInstitutionName"]];
    
    if( [presets valueForKey: @"searchStatus"])
        [statusFilterMatrix selectCellWithTag: [[presets valueForKey: @"searchStatus"] intValue]];
    
	if( [presets valueForKey: @"searchFieldName"])
		[searchFieldName setStringValue: [presets valueForKey: @"searchFieldName"]];
	
	if( [presets valueForKey: @"searchFieldID"])
		[searchFieldID setStringValue: [presets valueForKey: @"searchFieldID"]];
	
	if( [presets valueForKey: @"searchFieldAN"])
		[searchFieldAN setStringValue: [presets valueForKey: @"searchFieldAN"]];
	
	if( [presets valueForKey: @"searchFieldStudyDescription"])
		[searchFieldStudyDescription setStringValue: [presets valueForKey: @"searchFieldStudyDescription"]];
	
	if( [presets valueForKey: @"searchFieldComments"])
		[searchFieldComments setStringValue: [presets valueForKey: @"searchFieldComments"]];
	
    if( [presets valueForKey: @"searchCustomField"])
		[searchCustomField setStringValue: [presets valueForKey: @"searchCustomField"]];
	
    if( [presets valueForKey: @"searchCustomFieldDICOM"])
        [dicomFieldsMenu selectItemWithTitle: [presets valueForKey: @"searchCustomFieldDICOM"]];
    
	[dateFilterMatrix selectCellWithTag: [[presets valueForKey: @"dateFilterMatrix"] intValue]];
	[birthdateFilterMatrix selectCellWithTag: [[presets valueForKey: @"birthdateFilterMatrix"] intValue]];
	
	[modalityFilterMatrix deselectAllCells];
	
    if( [presets valueForKey: @"modalityStrings"])
    {
        for( NSCell *cell in [modalityFilterMatrix cells])
        {
            if( [[presets valueForKey: @"modalityStrings"] containsObject: cell.title])
                [cell setState: NSOnState];
        }
    }
	else if( [presets valueForKey: @"modalityFilterMatrixString"]) // Backward compatibility
	{
        NSString *m[7][3] = {{@"SC", @"CR", @"DX"},{@"CT", @"US", @"MG"},{@"MR", @"NM", @"PT"},{@"XA", @"RF", @"SR"},{@"DR", @"OT", @"RG"},{@"ES", @"VL", @"XC"},{@"AU", @"", @""}};
        
		NSString *s = [presets valueForKey: @"modalityFilterMatrixString"];
		
		NSScanner *scan = [NSScanner scannerWithString: s];
		
		BOOL more;
		do
		{
			NSInteger row, col;
			
			more = [scan scanInteger: &row];
			more = [scan scanInteger: &col];
			
			if( more && row < 7 && col < 3)
			{
                for( NSCell *cell in [modalityFilterMatrix cells])
                {
                    if( [cell.title isEqualToString: m[row][col]])
                        [cell setState: NSOnState];
                }
            }
			
		}
		while( more);
	}
    else if( [presets valueForKey: @"modalityFilterMatrixRow"] && [presets valueForKey: @"modalityFilterMatrixColumn"])  // Backward compatibility
		[modalityFilterMatrix selectCellAtRow: [[presets valueForKey: @"modalityFilterMatrixRow"] intValue]  column:[[presets valueForKey: @"modalityFilterMatrixColumn"] intValue]];

	[PatientModeMatrix selectTabViewItemAtIndex: [[presets valueForKey: @"PatientModeMatrix"] intValue]];
	
	[fromDate setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[presets valueForKey: @"fromDate"] doubleValue]]];
	[toDate setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[presets valueForKey: @"toDate"] doubleValue]]];
	[searchBirth setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[presets valueForKey: @"searchBirth"] doubleValue]]];
	
	switch( [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]])
	{
		case 0:		[searchFieldName selectText: self];				break;
		case 1:		[searchFieldID selectText: self];				break;
		case 2:		[searchFieldAN selectText: self];				break;
		case 3:		[searchFieldName selectText: self];				break;
		case 4:		[searchFieldStudyDescription selectText: self];	break;
		case 5:		[searchFieldRefPhysician selectText: self];		break;
		case 6:		[searchFieldComments selectText: self];			break;
        case 7:     [searchInstitutionName selectText: self];       break;
        case 8:     [searchCustomField selectText: self];           break;
	}
    
    if( [presets objectForKey: @"autoRetrieving"])
        [[NSUserDefaults standardUserDefaults] setObject: [presets objectForKey: @"autoRetrieving"] forKey: @"autoRetrieving"];

    if( [presets objectForKey: @"NumberOfPreviousStudyToRetrieve"])
        [[NSUserDefaults standardUserDefaults] setObject: [presets objectForKey: @"NumberOfPreviousStudyToRetrieve"] forKey: @"NumberOfPreviousStudyToRetrieve"];

    if( [presets objectForKey: @"retrieveSameModality"])
        [[NSUserDefaults standardUserDefaults] setObject: [presets objectForKey: @"retrieveSameModality"] forKey: @"retrieveSameModality"];

    if( [presets objectForKey: @"retrieveSameDescription"])
        [[NSUserDefaults standardUserDefaults] setObject: [presets objectForKey: @"retrieveSameDescription"] forKey: @"retrieveSameDescription"];
}

- (void) applyPreset:(id) sender
{
	if([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
	{
		// Delete the Preset
		if (NSRunCriticalAlertPanel( NSLocalizedString( @"Delete Preset", nil), NSLocalizedString(@"Are you sure you want to delete the selected Preset (%@)?", nil), NSLocalizedString( @"OK", nil), NSLocalizedString( @"Cancel", nil), nil, [sender title]) == NSAlertDefaultReturn)
		{
			NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
			
			NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary: savedPresets];
			[m removeObjectForKey: [sender title]];
			
			[[NSUserDefaults standardUserDefaults] setObject: m forKey:@"QRPresets"];
			
			[self buildPresetsMenu];
		}
	}
	else
	{
		NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
		
		if( [savedPresets objectForKey: [sender title]])
		{
			NSDictionary *presets = [savedPresets objectForKey: [sender title]];
			
			[self applyPresetDictionary: presets];
		}
	}
}

- (void) buildPresetsMenu
{
	[presetsPopup removeAllItems];
	NSMenu *menu = [presetsPopup menu];
	
	[menu setAutoenablesItems: NO];
	
	[menu addItemWithTitle: @"" action:nil keyEquivalent: @""];
	
	NSDictionary *savedPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"QRPresets"];
	
	[menu addItemWithTitle: NSLocalizedString( @"Empty Preset", nil) action:@selector(emptyPreset:) keyEquivalent:@""];
	[menu addItem: [NSMenuItem separatorItem]];
	
	if( [savedPresets count] == 0)
	{
		[[menu addItemWithTitle: NSLocalizedString( @"No Presets Saved", nil) action:nil keyEquivalent: @""] setEnabled: NO];
	}
	else
	{
		for( NSString *key in [[savedPresets allKeys] sortedArrayUsingSelector: @selector(compare:)])
		{
			[menu addItemWithTitle: key action:@selector(applyPreset:) keyEquivalent: @""];
		}
	}
	
	[menu addItem: [NSMenuItem separatorItem]];
	[menu addItemWithTitle: NSLocalizedString( @"Add current settings as a new Preset", nil) action:@selector(addPreset:) keyEquivalent:@""];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	BOOL valid = NO;
	
    if ([item action] == @selector(deleteSelection:))
	{
		[[BrowserController currentBrowser] setDatabase:[DicomDatabase activeLocalDatabase]];
        [[BrowserController currentBrowser] showEntireDatabase];
	
		NSIndexSet* indices = [outlineView selectedRowIndexes];
		
		for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
		{
			if( [indices containsIndex: i])
			{
				NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i] context: nil];

				if( [studyArray count] > 0)
				{
					valid = YES;
				}
			}
		}
    }
	else valid = YES;
	
    return valid;
}

-(void) deleteSelection:(id) sender
{
    NSIndexSet* indices = [outlineView selectedRowIndexes];
    BOOL somethingToDelete = NO;
    
    for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
    {
        if( [indices containsIndex: i])
        {
            if( [[outlineView itemAtRow: i] isMemberOfClass:[DCMTKStudyQueryNode class]])
                somethingToDelete = YES;
        } 
    }
    
    if( somethingToDelete == NO)
    {
        if( indices.count > 0)
            NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), NSLocalizedString(@"Select a study to delete it. You cannot delete series from this window, go to the Database window to delete series.", nil), NSLocalizedString(@"OK",nil), nil, nil);
    }
    else
    {
        [[BrowserController currentBrowser] setDatabase:[DicomDatabase activeLocalDatabase]];
        [[BrowserController currentBrowser] showEntireDatabase];
        
        BOOL extendingSelection = NO;
        
        @try 
        {
            for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
            {
                if( [indices containsIndex: i])
                {
                    if( [[outlineView itemAtRow: i] isMemberOfClass:[DCMTKStudyQueryNode class]])
                    {
                        NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i] context: nil];
                        
                        if( [studyArray count] > 0)
                        {
                            NSManagedObject	*series =  [[[BrowserController currentBrowser] childrenArray: [studyArray objectAtIndex: 0] onlyImages: NO] objectAtIndex:0];
                            [[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO extendingSelection: extendingSelection];
                            extendingSelection = YES;
                        }
                    }
                    else
                        [outlineView deselectRow: i];
                } 
            }

            if( extendingSelection)
                [[BrowserController currentBrowser] delItem: nil];
        }
        @catch (NSException * e) 
        {
            N2LogExceptionWithStackTrace(e);
        }
    }
}

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
    unichar c = [[event characters] characterAtIndex:0];
	
	if( [[self window] firstResponder] == outlineView)
	{
		if(c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
		{
			[self deleteSelection: self];
		}
		else if( c == ' ')
		{
			[self retrieve: self onlyIfNotAvailable: YES];
		}
		else if( c == NSNewlineCharacter || c == NSEnterCharacter || c == NSCarriageReturnCharacter)
		{
			[self retrieveAndView: self];
		}
		else if( c == 27) //Escape
		{
			DCMTKServiceClassUser *u = [queryManager rootNode];
			u._abortAssociation = YES;
		}
		else
		{
			[pressedKeys appendString: [event characters]];
			
			NSLog(@"%@", pressedKeys);
			
			NSArray *resultFilter = [resultArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", pressedKeys]];
			
			[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys selector:@selector(setString:) object:@""];
			[pressedKeys performSelector:@selector(setString:) withObject:@"" afterDelay:0.5];
			
			if( [resultFilter count])
			{
				[outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: [resultFilter objectAtIndex: 0]]] byExtendingSelection: NO];
				[outlineView scrollRowToVisible: [outlineView selectedRow]];
			}
			else NSBeep();
		}
	}
}

- (void) executeRefresh: (id) sender
{
    if (currentQueryController.DatabaseIsEdited == NO) [currentQueryController.outlineView reloadData];
	if (currentAutoQueryController.DatabaseIsEdited == NO) [currentAutoQueryController.outlineView reloadData];
	
    [NSThread detachNewThreadSelector:@selector(computeStudyArrayInstanceUID:) toTarget:self withObject:nil];
}

- (void) refresh: (id) sender
{
	if( afterDelayRefresh == NO)
	{
		afterDelayRefresh = YES;
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(executeRefresh:) object:nil];
		
		int delay;
		
		if( [currentQueryController.window isKeyWindow] || [currentAutoQueryController.window isKeyWindow])
			delay = 1;
		else
			delay = 10;
		
		[self performSelector:@selector(executeRefresh:) withObject:self afterDelay:delay];
	}
}

- (void) refreshAutoQR: (id) sender
{
	queryButtonPressed = YES;
    
    if( autoQuery)
    {
        for( int i = 0; i < autoQRInstances.count; i++)
            autoQueryRemainingSecs[ i] = 2;
    }
    else
        autoQueryRemainingSecs[ currentAutoQR] = 2;
        
    [self autoQueryTimerFunction: QueryTimer]; 
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(DCMTKQueryNode *) item
{
	@try
	{
        @synchronized( self)
        {
            if( item == nil)
            {
                if( [resultArray count] > index)
                    return [resultArray objectAtIndex:index];
                else
                    return nil;
            }
            else
            {
                NSArray *children = [item children];
                
                if( children.count > 0 && [[children lastObject] isKindOfClass: [DCMTKStudyQueryNode class]] == NO && [[children lastObject] isKindOfClass: [DCMTKSeriesQueryNode class]] == NO)
                {
                    [item purgeChildren];
                    children = [item children];
                }
                
                return [children objectAtIndex: index];
            }
        }
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *) o shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	@try
	{
//		if( [[tableColumn identifier] isEqualToString:@"comment"])
//		{
//			DatabaseIsEdited = YES;
//			return YES;
//		}
//		else
//		{
//			DatabaseIsEdited = NO;
//			return NO;
//		}
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    @synchronized( self)
    {
        @try
        {
            if (item == nil)
                return [resultArray count];
            else
            {
                if ( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES || [item isMemberOfClass:[DCMTKRootQueryNode class]] == YES)
                    return YES;
                else 
                    return NO;
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
	}
    
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(DCMTKQueryNode *) item
{
	@try
	{
        @synchronized( self)
        {
            if( item)
            {
                NSArray *children = [item children];
                
                if( children.count > 0 && [[children lastObject] isKindOfClass: [DCMTKStudyQueryNode class]] == NO && [[children lastObject] isKindOfClass: [DCMTKSeriesQueryNode class]] == NO)
                    [item purgeChildren];
                
                if (![item children])
                {
					if( performingCFind == NO)
					{
						performingCFind = YES; // to avoid re-entries during WaitRendering window, and separate thread for cFind
						
						[progressIndicator startAnimation:nil];
						[item queryWithValues:nil];
						[progressIndicator stopAnimation:nil];
						performingCFind = NO;
                        
                        if( [item children] == nil) // It failed... put an empty children...
                            [item setChildren: [NSMutableArray array]];
					}
                }
            }
            return  (item == nil) ? [resultArray count] : [[item children] count];
        }
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return [resultArray count];
}

- (NSArray*) localSeries:(id) item
{
    return [self localSeries: item context: nil];
}

- (NSArray*) localSeries:(id) item context: (NSManagedObjectContext*) context
{
	NSArray *seriesArray = nil;
	NSManagedObject *study = [[self localStudy: [outlineView parentForItem: item] context: context] lastObject];
	
	if( study == nil) return seriesArray;
	
	if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
	{
        if( context == nil)
        {
            if( [NSThread isMainThread])
                context = [[[BrowserController currentBrowser] database] managedObjectContext];
            else
                context = [[[BrowserController currentBrowser] database] independentContext];
        }
        
		@try
		{
			seriesArray = [[[study valueForKey:@"series"] allObjects] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]]];
		}
		@catch (NSException * e)
		{
            N2LogExceptionWithStackTrace(e);
		}
	}
	else
		NSLog( @"Warning! Not a series class ! %@", [item class]);
	
	return seriesArray;
}

- (void) applyNewStudyArray: (NSDictionary *) d
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(applyNewStudyArray:) object: nil];
    
	@synchronized (studyArrayInstanceUID)
	{
		if( currentQueryController.DatabaseIsEdited == NO)
			[currentQueryController.outlineView reloadData];
			
		if( currentAutoQueryController.DatabaseIsEdited == NO)
			[currentAutoQueryController.outlineView reloadData];
	}
	
	[pool release];
}

- (void) computeStudyArrayInstanceUID: (NSNumber*) sender
{
    if( [[BrowserController currentBrowser] database] == nil) // During DB rebuild
        return;
        
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *local_studyArrayID = nil;
	NSArray *local_studyArrayInstanceUID = nil;
	
    @synchronized( kComputeStudyArrayInstanceUIDLock)
    {
        @try
        {
            NSManagedObjectContext *independentContext = nil;
            
            if( [NSThread isMainThread])
                independentContext = [[[BrowserController currentBrowser] database] managedObjectContext];
            else
                independentContext = [[[BrowserController currentBrowser] database] independentContext];
            
            if( independentContext)
            {
                [independentContext lock];
                
                @try
                {
                    NSError *error = nil;
                    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
                    
                    request.entity = [NSEntityDescription entityForName: @"Study" inManagedObjectContext: independentContext];
                    request.predicate = [NSPredicate predicateWithValue: YES];
                    
                    NSArray *result = [independentContext executeFetchRequest:request error: &error];
                    
                    local_studyArrayID = [result valueForKey: @"objectID"];
                    local_studyArrayInstanceUID = [result valueForKey:@"studyInstanceUID"];
                }
                @catch (NSException* e)
                {
                    N2LogExceptionWithStackTrace(e);
                }
                @finally {
                    [independentContext unlock];
                }
            }
        }
        @catch (NSException * e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
    }
        
    if( local_studyArrayID && local_studyArrayInstanceUID)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(applyNewStudyArray:) object: nil];
        
        @synchronized (studyArrayInstanceUID)
        {
            [studyArrayInstanceUID removeAllObjects];
            [studyArrayInstanceUID addObjectsFromArray: local_studyArrayInstanceUID];
            
            if( studyArrayInstanceUID.count == 0) //Add a fake object : to avoid re-compute loop in - (NSArray*) localStudy:(id) item context: (NSManagedObjectContext*) context
                [studyArrayInstanceUID addObject: @"This is not a studyInstanceUID"];
            
            [studyArrayID removeAllObjects];
            [studyArrayID addObjectsFromArray: local_studyArrayID];
        }
        
        if( [NSThread isMainThread])
            [self performSelector: @selector(applyNewStudyArray:) withObject: nil afterDelay: 0.001];
        else
            [self performSelectorOnMainThread:@selector(applyNewStudyArray:) withObject: nil waitUntilDone: NO];
    }
    else
        NSLog( @"******** computeStudyArrayInstanceUID FAILED...");
        
	afterDelayRefresh = NO;
	
	[pool release];
}

- (NSArray*) localStudy:(id) item
{
    return [self localStudy: item context: nil];
}

- (NSArray*) localStudy:(id) item context: (NSManagedObjectContext*) context
{
	if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
	{
		@try
		{
			NSArray *result = [NSArray array];
			
            @synchronized (studyArrayInstanceUID)
            {
                if (studyArrayInstanceUID.count == 0)
                    [self computeStudyArrayInstanceUID: nil];

                NSUInteger index = [studyArrayInstanceUID indexOfObject:[item valueForKey: @"uid"]];
                
                if( index != NSNotFound)
                {
                    if( context == nil)
                    {
                        if( [NSThread isMainThread])
                            context = [[[BrowserController currentBrowser] database] managedObjectContext];
                        else
                            context = [[[BrowserController currentBrowser] database] independentContext];
                    }
                    
                    DicomStudy *s = (DicomStudy*) [context existingObjectWithID:[studyArrayID objectAtIndex: index] error:NULL];
                    
                    if( s)
                        result = [NSArray arrayWithObject: s];
                }
            }
			
			return result;
		}
		@catch (NSException * e)
		{
			@synchronized (studyArrayInstanceUID)
			{
				[studyArrayInstanceUID removeAllObjects];
			}
		}
	}
	
	return nil;
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation;
{
	@try
	{
		if( [[tableColumn identifier] isEqualToString: @"name"])
		{
			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
			{
				NSArray *studyArray;
				
				studyArray = [self localStudy: item context: nil];
				
				if( [studyArray count] > 0)
				{
					float localFiles = [[[studyArray objectAtIndex: 0] valueForKey: @"rawNoFiles"] floatValue];
					float totalFiles = [[item valueForKey:@"numberImages"] floatValue];
					float percentage = 0;
					
					if( totalFiles != 0.0)
						percentage = localFiles / totalFiles;
					if( percentage > 1.0) percentage = 1.0;
					
					return [NSString stringWithFormat:@"%@\n%d%% (%d/%d)", [cell title], (int)(percentage*100), (int)localFiles, (int)totalFiles];
				}
			}
			
			if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
			{
				NSArray *seriesArray;
				
				seriesArray = [self localSeries: item context: nil];
				
				if( [seriesArray count] > 0)
				{
					float localFiles = [[[seriesArray objectAtIndex: 0] valueForKey: @"rawNoFiles"] floatValue];
					float totalFiles = [[item valueForKey:@"numberImages"] floatValue];
					float percentage = 0;
					
					if( totalFiles != 0.0)
						percentage = localFiles / totalFiles;
						
					if(percentage > 1.0) percentage = 1.0;
					
					return [NSString stringWithFormat:@"%@\n%d%% (%d/%d)", [cell title], (int)(percentage*100), (int)localFiles, (int)totalFiles];
				}
			}
		}
	}
	@catch ( NSException *e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	return @"";
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	DCMTKStudyQueryNode *item = [[notification userInfo] valueForKey: @"NSObject"];
	
	if( [item children])
	{
		[item purgeChildren];
	}
}

- (void)outlineView:(NSOutlineView *)oV willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	@try
	{
		if( [[tableColumn identifier] isEqualToString: @"name"])	// Is this study already available in our local database?
		{
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"] && [[self window] firstResponder] == outlineView && [outlineView selectedRow] >= 0)
            {
                id study = nil;
                
                if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
                    study = [outlineView parentForItem: item];
                else
                    study = item;
                
                id selStudy = [outlineView itemAtRow: [outlineView selectedRow]];
                
                NSString *curUid = [NSString stringWithFormat: @"%@ %@", [item valueForKey: @"patientID"], [item valueForKey: @"name"]];
                NSString *selUid = [NSString stringWithFormat: @"%@ %@", [selStudy valueForKey: @"patientID"], [selStudy valueForKey: @"name"]];
                
                if( item != selStudy && [curUid length] > 0 && [curUid compare: selUid options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
                {
                    [cell setDrawsBackground: YES];
                    [cell setBackgroundColor: [NSColor lightGrayColor]];
                }
                else
                    [cell setDrawsBackground: NO];
            }
            
			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
			{
				NSArray	*studyArray = [self localStudy: item context: nil];
				
				if( [studyArray count] > 0)
				{
					float percentage = 0;
					
					if( [[item valueForKey:@"numberImages"] floatValue] != 0.0)
						percentage = [[[studyArray objectAtIndex: 0] valueForKey: @"rawNoFiles"] floatValue] / [[item valueForKey:@"numberImages"] floatValue];
						
					if(percentage > 1.0) percentage = 1.0;

					[(ImageAndTextCell *)cell setImage:[NSImage pieChartImageWithPercentage:percentage]];
				}
				else [(ImageAndTextCell *)cell setImage: nil];
			}
			else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
			{
				NSArray	*seriesArray;
				
				seriesArray = [self localSeries: item context: nil];
				
				if( [seriesArray count] > 0)
				{
					float percentage = 0;
					
					if( [[item valueForKey:@"numberImages"] floatValue] != 0.0)
						percentage = [[[seriesArray objectAtIndex: 0] valueForKey: @"rawNoFiles"] floatValue] / [[item valueForKey:@"numberImages"] floatValue];
						
					if(percentage > 1.0) percentage = 1.0;
					
					[(ImageAndTextCell *)cell setImage:[NSImage pieChartImageWithPercentage:percentage]];
				}
				else [(ImageAndTextCell *)cell setImage: nil];
			}
			else [(ImageAndTextCell *)cell setImage: nil];
			
			[cell setFont: [NSFont boldSystemFontOfSize:13]];
			[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		}
		else if( [[tableColumn identifier] isEqualToString: @"numberImages"])
		{
			if( [item valueForKey:@"numberImages"]) [cell setIntegerValue: [[item valueForKey:@"numberImages"] intValue]];
			else [cell setStringValue:@"n/a"];
		}
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    @synchronized( self)
    {
        @try
        {
            if( [[tableColumn identifier] isEqualToString: @"stateText"])
            {
                if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
                {
                    NSArray *studyArray = [self localStudy: item context: nil];
                    
                    if( [studyArray count] > 0)
                    {
                        if( [[[studyArray objectAtIndex: 0] valueForKey:@"stateText"] intValue] == 0)
                            return nil;
                        else
                            return [[studyArray objectAtIndex: 0] valueForKey: @"stateText"];
                    }
                }
                else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]])
                {
                    NSArray *seriesArray = [self localSeries: item context: nil];
                    if( [seriesArray count])
                    {
                        if( [[[seriesArray objectAtIndex: 0] valueForKey:@"stateText"] intValue] == 0)
                            return nil;
                        else
                            return [[seriesArray objectAtIndex: 0] valueForKey: @"stateText"];
                    }
                }
                else NSLog( @"***** unknown class in QueryController outlineView: %@", [item class]);
            }
            else if( [[tableColumn identifier] isEqualToString: @"serverStateText"])
            {
                if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
                {
                    if( [[item stateText] intValue] == 0)
                        return nil;
                    else
                        return [item stateText];
                }
                
                else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]])
                    return nil;
                
                else NSLog( @"***** unknown class in QueryController outlineView: %@", [item class]);
            }
            else if( [[tableColumn identifier] isEqualToString: @"comment"])
            {
                if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
                {
                    NSArray *studyArray = [self localStudy: item context: nil];
                    
                    if( [studyArray count] > 0)
                        return [[studyArray objectAtIndex: 0] valueForKey: @"comment"];
                }
                else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]])
                {
                    NSArray *seriesArray = [self localSeries: item context: nil];
                    if( [seriesArray count] > 0)
                        return [[seriesArray objectAtIndex: 0] valueForKey: @"comment"];
                }
                else NSLog( @"***** unknown class in QueryController outlineView: %@", [item class]);
            }
            else if( [[tableColumn identifier] isEqualToString: @"serverComment"])
            {
                if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
                    return [item valueForKey: @"comments"];
                
                else if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]])
                    return [item valueForKey: @"comments"];
                
                else NSLog( @"***** unknown class in QueryController outlineView: %@", [item class]);
            }
            else if ( [[tableColumn identifier] isEqualToString: @"Button"] == NO && [tableColumn identifier] != nil)
            {
                if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] || [item isMemberOfClass:[DCMTKSeriesQueryNode class]])
                {
                    if( [[tableColumn identifier] isEqualToString: @"numberImages"])
                    {
                        return [NSNumber numberWithInt: [[item valueForKey: [tableColumn identifier]] intValue]];
                    }
                    else return [item valueForKey: [tableColumn identifier]];
                }
                else NSLog( @"***** unknown class in QueryController outlineView: %@", [item class]);
            }	
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
    }
	
	return nil;
}

//- (void)outlineView:(NSOutlineView *) o setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
//{
//	NSArray *array;
//	
//	@try
//	{
////		if( [[tableColumn identifier] isEqualToString: @"comment"] || [[tableColumn identifier] isEqualToString: @"stateText"])
////		{
////			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
////				array = [self localStudy: item context: nil];
////			else
////				array = [self localSeries: item context: nil];
////			
////			if( [array count] > 0)
////			{
////				[[BrowserController currentBrowser] setDatabaseValue: object item: [array objectAtIndex: 0] forKey: [tableColumn identifier]];
////			}
////			else NSRunCriticalAlertPanel( NSLocalizedString(@"Study not available", nil), NSLocalizedString(@"The study is not available in the local Database, you cannot modify or set the comments/status fields.", nil), NSLocalizedString(@"OK", nil), nil, nil) ;
////		}
//	}
//	@catch (NSException * e)
//	{
//		N2LogExceptionWithStackTrace(e);
//	}
//	
//	DatabaseIsEdited = NO;
//	[outlineView reloadData];
//}

- (NSArray*) sortArray
{
	NSArray *s = [outlineView sortDescriptors];
	
	if( [s count])
	{
		if( [[[s objectAtIndex: 0] key] isEqualToString:@"date"])
		{
			NSMutableArray *sortArray = [NSMutableArray arrayWithObject: [s objectAtIndex: 0]];
			
			[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"time" ascending: [[s objectAtIndex: 0] ascending]] autorelease]];
			
			if( [s count] > 1)
			{
				NSMutableArray *lastObjects = [NSMutableArray arrayWithArray: s];
				[lastObjects removeObjectAtIndex: 0];
				[sortArray addObjectsFromArray: lastObjects];
			}
			
			return sortArray;
		}
	}
	
	return s;
}

- (void)outlineView:(NSOutlineView *)aOutlineView sortDescriptorsDidChange:(NSArray *)oldDescs
{
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	[resultArray sortUsingDescriptors: [self sortArray]];
	[outlineView reloadData];
	
	NSArray *s = [outlineView sortDescriptors];
	
	if( [s count])
	{
		if( [[[s objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
		{
			[outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection: NO];
		}
		else [outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: item]] byExtendingSelection: NO];
	}
	else [outlineView selectRowIndexes: [NSIndexSet indexSetWithIndex: [outlineView rowForItem: item]] byExtendingSelection: NO];
	
	[outlineView scrollRowToVisible: [outlineView selectedRow]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet *index = [outlineView selectedRowIndexes];
	id item = [outlineView itemAtRow:[index firstIndex]];
	
	if( item)
	{
		[selectedResultSource setStringValue: [NSString stringWithFormat:@"%@  /  %@:%d", [item valueForKey:@"calledAET"], [item valueForKey:@"hostname"], [[item valueForKey:@"port"] intValue]]];
	}
	else [selectedResultSource setStringValue:@""];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
        [outlineView setNeedsDisplay: YES];
}

- (IBAction) selectModality: (id) sender;
{
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	
	if( [event modifierFlags] & NSCommandKeyMask)
	{
		for( NSCell *c in [modalityFilterMatrix cells])
		{
			if( [sender selectedCell] != c)
				[c setState: NSOffState];
		}
	}
}

- (NSArray*) queryPatientID:(NSString*) ID
{
    NSDictionary *savedSettings = [self savePresetInDictionaryWithDICOMNodes: NO];
	
    [self emptyPreset: self];
    
	[PatientModeMatrix selectTabViewItemAtIndex: 1];	// PatientID search
	[searchFieldID setStringValue: ID];
	
	[self query: self];
	
	NSArray *result = [NSArray arrayWithArray: resultArray];
	
    [self applyPresetDictionary: savedSettings];
	
	return result;
}

- (void) querySelectedStudy: (id) sender
{
	id   item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	if( item && [item isMemberOfClass:[DCMTKStudyQueryNode class]])
	{
		queryButtonPressed = YES;
		[self queryPatientID: [item valueForKey:@"patientID"]];
	}
	else NSRunCriticalAlertPanel( NSLocalizedString(@"No Study Selected", nil), NSLocalizedString(@"Select a study to query all studies of this patient.", nil), NSLocalizedString(@"OK", nil), nil, nil) ;
}

- (NSArray*) queryPatientIDwithoutGUI: (NSString*) patientID
{
	NSString			*hostname;
	id					aServer;
	int					selectedServer;
	BOOL				atLeastOneSource = NO, noChecked = YES;
	NSArray				*copiedSources = [NSArray arrayWithArray: sourcesArray];
	
	noChecked = YES;
	for( NSUInteger i = 0; i < [copiedSources count]; i++)
	{
		if( [[[copiedSources objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
			noChecked = NO;
	}
	
	selectedServer = -1;
	if( noChecked)
		selectedServer = [sourcesTable selectedRow];
	
	atLeastOneSource = NO;
	
	NSString *filterValue = [patientID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSMutableArray *result = [NSMutableArray array];
	
	if ([filterValue length] > 0)
	{
		for( NSUInteger i = 0; i < [copiedSources count]; i++)
		{
			if( [[[copiedSources objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES || selectedServer == i)
			{
				aServer = [[copiedSources objectAtIndex:i] valueForKey:@"server"];
				
				hostname = [aServer objectForKey:@"Address"];
				
				QueryArrayController *qm = [[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer];
				
				[qm addFilter:filterValue forDescription: PatientID];
				
				[qm performQuery: NO];
				
				[result addObjectsFromArray: [qm queries]];
				
				[qm release];
			}
		}
	}
	
	return result;
}

-(void) realtimeCFindResults: (NSNotification*) notification
{
    if( [notification object] == [queryManager rootNode] && temporaryCFindResultArray)
    {
        if( [[self window] isVisible] && [[NSDate date] timeIntervalSinceReferenceDate] - lastTemporaryCFindResultUpdate > 1)
        {            
            NSArray	*curResult = [[notification object] children];
            
            @synchronized( curResult)
            {
                if( firstServerRealtimeResults)
                {
                    [temporaryCFindResultArray removeAllObjects];
                    [temporaryCFindResultArray addObjectsFromArray: curResult];
                }
                else if( [curResult count] < 4000)
                {
                    NSArray *uidArray = [temporaryCFindResultArray valueForKey: @"uid"];
                    
                    for( NSUInteger x = 0 ; x < [curResult count] ; x++)
                    {
                        NSUInteger index = [uidArray indexOfObject: [[curResult objectAtIndex: x] valueForKey:@"uid"]];
                        
                        if( index == NSNotFound) // not found
                            [temporaryCFindResultArray addObject: [curResult objectAtIndex: x]];
                        else 
                        {
                            if( [[temporaryCFindResultArray objectAtIndex: index] valueForKey: @"numberImages"] && [[curResult objectAtIndex: x] valueForKey: @"numberImages"])
                            {
                                if( [[[temporaryCFindResultArray objectAtIndex: index] valueForKey: @"numberImages"] intValue] < [[[curResult objectAtIndex: x] valueForKey: @"numberImages"] intValue])
                                {
                                    [temporaryCFindResultArray replaceObjectAtIndex: index withObject: [curResult objectAtIndex: x]];
                                }
                            }
                        }
                    }
                }
                
                if( [NSThread isMainThread])
                    [self refreshList: temporaryCFindResultArray];
                else
                    [self performSelectorOnMainThread:@selector(refreshList:) withObject: temporaryCFindResultArray waitUntilDone: NO];
            }
            
            lastTemporaryCFindResultUpdate = [[NSDate date] timeIntervalSinceReferenceDate];
        }
    }
}

-(BOOL) queryWithDisplayingErrors:(BOOL) showError 
{
    NSMutableDictionary *instance = [self savePresetInDictionaryWithDICOMNodes: YES];
    
    return [self queryWithDisplayingErrors: showError instance: instance index: -1];
}

-(BOOL) queryWithDisplayingErrors:(BOOL) showError instance: (NSMutableDictionary*) instance index: (int) index
{
	NSString			*theirAET, *hostname, *port;
	
	BOOL				error = NO;
	NSMutableArray		*tempResultArray = [NSMutableArray array];
    
    [temporaryCFindResultArray release];
    temporaryCFindResultArray = nil;
    if( [NSThread isMainThread])
        temporaryCFindResultArray = [[NSMutableArray array] retain];
    
    @synchronized( self)
    {
        for( NSThread *t in performingQueryThreads)
            [t setIsCancelled: YES];
    }
    
	[autoQueryLock lock];
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: queryArrayPrefs];
	
    BOOL atLeastOneSource = NO;
    
	@try 
	{
		firstServerRealtimeResults = YES;
		
        if( [NSThread isMainThread])
            [self refreshList: [NSArray array]]; // Clean the list
        
        NSArray *dicomNodes = [instance objectForKey: @"DICOMNodes"];
        NSArray *dicomNodesAE = [instance objectForKey: @"DICOMNodesAETitle"];
        
		for( int v = 0; v < dicomNodes.count; v++)
        {
            NSString *s = [dicomNodes objectAtIndex: v];
            NSString *ae = nil;
            if( v < dicomNodesAE.count)
                ae = [dicomNodesAE objectAtIndex: v];
                
            NSDictionary *aServer = nil;
            
            for( id src in sourcesArray)
            {
                if( [[src valueForKey: @"AddressAndPort"] isEqualToString: s] && (ae == nil || [[src valueForKey: @"AETitle"] isEqualToString: ae]))
                    aServer = [src valueForKey: @"server"];
            }
            
            if( aServer == nil)
                continue;
            
            theirAET = [aServer objectForKey:@"AETitle"];
            hostname = [aServer objectForKey:@"Address"];
            port = [aServer objectForKey:@"Port"];
                        
            [queryManager release];
            queryManager = nil;

            queryManager = [[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer];
            // add filters as needed
            
            if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
                //Specific Character Set
                [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
            
            BOOL queryAllFields = NO;
            int fromField;
            int toField;
            
            atLeastOneSource = YES;
            
            if( instance)
            {
                fromField = toField = [[instance objectForKey: @"PatientModeMatrix"] intValue];
            }
            else
            {
                if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask)
                {
                    NSLog( @"--- Query ALL fields");
                    queryAllFields = YES;
                }
                
                if( queryAllFields)
                {
                    fromField = 0;
                    toField = [PatientModeMatrix numberOfTabViewItems];
                }
                else
                {
                    fromField = toField = [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]];
                }
            }
            
            BOOL queryItem = NO;
            
            for( int v = fromField; v <= toField; v++)
            {
                switch( v)
                {
                    case 0:		currentQueryKey = PatientName;          break;
                    case 1:		currentQueryKey = PatientID;            break;
                    case 2:		currentQueryKey = AccessionNumber;      break;
                    case 3:		currentQueryKey = PatientBirthDate;     break;
                    case 4:		currentQueryKey = StudyDescription;     break;
                    case 5:		currentQueryKey = ReferringPhysician;	break;
                    case 6:		currentQueryKey = StudyComments;        break;
                    case 7:		currentQueryKey = InstitutionName;      break;
                    case 8:     currentQueryKey = customDICOMField;     break;
                    case 9:     currentQueryKey = InterpretationStatusID;    break;
                }
                
                if( currentQueryKey == customDICOMField && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_custom_dicom_field"])
                {
                    CIADICOMField *dicomField = nil;
                    NSString *customValue = nil;
                    
                    if( instance)
                    {
                        dicomField = [[dicomFieldsMenu itemWithTitle: [instance objectForKey: @"searchCustomFieldDICOM"]] representedObject];
                        customValue = [instance objectForKey: @"searchCustomField"];
                    }
                    else
                    {
                        dicomField = [[dicomFieldsMenu selectedItem] representedObject];
                        customValue = [searchCustomField stringValue];
                    }
                    
                    DcmTag tag( [dicomField group], [dicomField element]);
                    
                    currentQueryKey = [NSString stringWithUTF8String:tag.getTagName()];
                    
                    NSLog( @"DICOM Q&R with custom field: %@ : %@", currentQueryKey, customValue);
                    
                    if( showError && [customValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = [customValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter: filterValue forDescription: currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == PatientName && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_name"])
                {
                    NSString *patientNameValue = nil;
                    
                    if( instance)
                        patientNameValue = [instance objectForKey: @"searchFieldName"];
                    else
                    {
                        patientNameValue = [searchFieldName stringValue];
                        
                        if( [patientNameValue length] >= 64)
                            [searchFieldName setStringValue: [patientNameValue substringToIndex: 64]];
                    }
                    
                    if( showError && [patientNameValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = [patientNameValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == ReferringPhysician && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_referring_physician"])
                {
                    NSString *refPhysicianValue = nil;
                    
                    if( instance)
                        refPhysicianValue = [instance objectForKey: @"searchFieldRefPhysician"];
                    else
                        refPhysicianValue = [searchFieldRefPhysician stringValue];
                    
                    if( showError && [refPhysicianValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = [refPhysicianValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == InstitutionName && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_institution"])
                {
                    NSString *institutionNameValue = nil;
                    
                    if( instance)
                        institutionNameValue = [instance objectForKey: @"searchInstitutionName"];
                    else
                        institutionNameValue = [searchInstitutionName stringValue];
                    
                    if( showError && [institutionNameValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = [institutionNameValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == InterpretationStatusID && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_status"])
                {
                    NSString *studyStatusValue = nil;
                    
                    if( instance)
                        studyStatusValue = [NSString stringWithFormat: @"%d", [[instance objectForKey: @"searchStatus"] intValue]];
                    else
                        studyStatusValue = [NSString stringWithFormat: @"%d", (int) [statusFilterMatrix selectedTag]];
                    
                    if( showError && [studyStatusValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = [studyStatusValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter:filterValue forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == PatientBirthDate && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_birthdate"])
                {
                    int tag;
                    NSDate *date;
                    
                    if( instance)
                    {
                        tag = [[instance objectForKey: @"birthdateFilterMatrix"] intValue];
                        date = [NSDate dateWithTimeIntervalSinceReferenceDate: [[instance objectForKey: @"searchBirth"] doubleValue]];
                    }
                    else
                    {
                        tag = [birthdateFilterMatrix selectedTag];
                        date = [searchBirth dateValue];
                    }
                    
                    if( tag == 0)
                        [queryManager addFilter: [date descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] forDescription:currentQueryKey];
                    
                    if( tag == -1)
                        [queryManager addFilter: [date descriptionWithCalendarFormat:@"-%Y%m%d" timeZone:nil locale:nil] forDescription:currentQueryKey];
                    
                    if( tag == 1)
                        [queryManager addFilter: [date descriptionWithCalendarFormat:@"%Y%m%d-" timeZone:nil locale:nil] forDescription:currentQueryKey];
                    
                    queryItem = YES;
                }
                else if( currentQueryKey == PatientID && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                {
                    NSString *patientIDValue = nil;
                    
                    if( instance)
                        patientIDValue = [instance objectForKey: @"searchFieldID"];
                    else
                        patientIDValue = [searchFieldID stringValue];
                    
                    NSString *filterValue = [patientIDValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter:filterValue forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == AccessionNumber && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_accession_number"])
                {
                    NSString *ANValue = nil;
                    
                    if( instance)
                        ANValue = [instance objectForKey: @"searchFieldAN"];
                    else
                        ANValue = [searchFieldAN stringValue];
                    
                    
                    NSString *filterValue = [ANValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter:filterValue forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == StudyDescription && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_description"])
                {
                    NSString *studyDescriptionValue = nil;
                    
                    if( instance)
                        studyDescriptionValue = [instance objectForKey: @"searchFieldStudyDescription"];
                    else
                        studyDescriptionValue = [searchFieldStudyDescription stringValue];
                    
                    if( showError && [studyDescriptionValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = studyDescriptionValue;
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter: [filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
                else if( currentQueryKey == StudyComments && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_comments"])
                {
                    NSString *commentsValue = nil;
                    
                    if( instance)
                        commentsValue = [instance objectForKey: @"searchFieldComments"];
                    else
                        commentsValue = [searchFieldComments stringValue];
                    
                    if( showError && [commentsValue cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                    {
                        if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                        {
                            [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                            [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                        }
                    }
                    
                    NSString *filterValue = commentsValue;
                    
                    if ([filterValue length] > 0)
                    {
                        [queryManager addFilter: [filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                        queryItem = YES;
                    }
                }
            }
            
            QueryFilter *dateQueryFilter = nil, *timeQueryFilter = nil, *modalityQueryFilter = nil;
            
            [QueryController getDateAndTimeQueryFilterWithTag: [[instance objectForKey: @"dateFilterMatrix"] intValue] fromDate: fromDate.dateValue toDate: toDate.dateValue date: &dateQueryFilter time: &timeQueryFilter];
            
            if ([dateQueryFilter object] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_study_date"])
            {
                [queryManager addFilter:[dateQueryFilter filteredValue] forDescription:@"StudyDate"];
                queryItem = YES;
            }
            
            if ([timeQueryFilter object] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_study_date"])
            {
                [queryManager addFilter:[timeQueryFilter filteredValue] forDescription:@"StudyTime"];
                queryItem = YES;
            }
            
            modalityQueryFilter = [self getModalityQueryFilter: [instance objectForKey: @"modalityStrings"]];
            
            if( [modalityQueryFilter object])
            {
                if( queryItem || [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_modality"])
                {
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
                        [queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"ModalitiesinStudy"];
                    else
                        [queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"Modality"];
                    
                    queryItem = YES;
                }
            }
            
            if (queryItem)
            {
                [self performQuery: [NSNumber numberWithBool: showError]];
            }
            // if filter is empty and there is no date the query may be prolonged and fail. Ask first. Don't run if cancelled
            else
            {
                BOOL doit = NO;
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_blank_query"] == NO)
                {
                    if( [NSThread isMainThread])
                        NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), NSLocalizedString(@"No query parameters provided. Blank query is not allowed.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                }
                else
                {
                    if( showError && [NSThread isMainThread])
                    {
//                        if ([defaults boolForKey:alertSuppress])
//                        {
//                            doit = YES;
//                        }
//                        else
                        {
                            NSAlert* alert = [[NSAlert new] autorelease];
                            [alert setMessageText: NSLocalizedString(@"Query", nil)];
                            [alert setInformativeText: NSLocalizedString(@"No query parameters provided. The query may take a long time.", nil)];
//                            [alert setShowsSuppressionButton:YES];
                            [alert addButtonWithTitle: NSLocalizedString(@"Continue", nil)];
                            [alert addButtonWithTitle: NSLocalizedString(@"Cancel", nil)];
                            
                            if( [alert runModal] == NSAlertFirstButtonReturn) doit = YES;
                        }
                    }
                    else doit = YES;
                }
                
                if( doit)
                {
                    [self performQuery: [NSNumber numberWithBool: showError]];
                }
                else
                {
                    NSLog( @"The PACS query was not allowed.");
                    break;
                }
            }
            
            if( [NSThread isMainThread])
            {
                lastTemporaryCFindResultUpdate = 0;
                [self realtimeCFindResults: [NSNotification notificationWithName: @"realtimeCFindResults" object: [queryManager rootNode]]]; // If there are multiple sources
            }
            
            if( firstServerRealtimeResults)
            {
                firstServerRealtimeResults = NO;
                [tempResultArray removeAllObjects];
                [tempResultArray addObjectsFromArray: [queryManager queries]];
            }
            else
            {
                NSArray	*curResult = [queryManager queries];
                NSArray *uidArray = [tempResultArray valueForKey: @"uid"];
                
                for( NSUInteger x = 0 ; x < [curResult count] ; x++)
                {
                    NSUInteger index = [uidArray indexOfObject: [[curResult objectAtIndex: x] valueForKey:@"uid"]];
                    
                    if( index == NSNotFound) // not found
                        [tempResultArray addObject: [curResult objectAtIndex: x]];
                    else 
                    {
                        if( [[tempResultArray objectAtIndex: index] valueForKey: @"numberImages"] && [[curResult objectAtIndex: x] valueForKey: @"numberImages"])
                        {
                            if( [[[tempResultArray objectAtIndex: index] valueForKey: @"numberImages"] intValue] < [[[curResult objectAtIndex: x] valueForKey: @"numberImages"] intValue])
                            {
                                [tempResultArray replaceObjectAtIndex: index withObject: [curResult objectAtIndex: x]];
                            }
                        }
                    }
                }
            }
//				else
//				{
//					NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", theirAET, hostname, [port intValue]];
//				
//					response = [response stringByAppendingString:NSLocalizedString(@"Connection failed to this DICOM node (c-echo failed)", nil)];
//					
//					NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), response, NSLocalizedString(@"Continue", nil), nil, nil) ;
//				}
        
            
        }
		
		if( [tempResultArray count])
			[tempResultArray sortUsingDescriptors: [self sortArray]];
        
        firstServerRealtimeResults = YES;
		
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	[autoQueryLock unlock];
	
    if( autoQuery == NO)
    {
        if( [NSThread isMainThread])
            [self refreshList: tempResultArray];
        else
            [self performSelectorOnMainThread:@selector(refreshList:) withObject: tempResultArray waitUntilDone: NO];
	}
    else
    {
        @synchronized( autoQRInstances)
        {
            if( index >= 0)
            {
                if( index == currentAutoQR)
                {
                    if( [NSThread isMainThread])
                        [self refreshList: tempResultArray];
                    else
                        [self performSelectorOnMainThread:@selector(refreshList:) withObject: tempResultArray waitUntilDone: NO];
                }
                if( index < [autoQRInstances count])
                {
                    // instance dictionary is a copy of autoQRInstances dictionary !
                    
                    [[autoQRInstances objectAtIndex: index] setObject: tempResultArray forKey: @"resultArray"];
                    
                    [instance setObject: tempResultArray forKey: @"resultArray"];
                }
            }
        }
    }
    
	if( atLeastOneSource == NO && [NSThread isMainThread])
	{
		if( showError)
			NSRunCriticalAlertPanel( NSLocalizedString(@"Query", nil), NSLocalizedString( @"Please select a DICOM node (check box).", nil), NSLocalizedString(@"Continue", nil), nil, nil) ;
	}
	
    [temporaryCFindResultArray release];
    temporaryCFindResultArray = nil;
    
	return error;
}

- (void) refreshList: (NSArray*) l
{
	[l retain];
	
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"******* this function should be called in MAIN thread");
    
	[resultArray removeAllObjects];
    if ( [ l count ] > 0) {
        [resultArray addObjectsFromArray: l];
        [resultArray sortUsingDescriptors: [self sortArray]];
    }
	[outlineView reloadData];
    
    [numberOfStudies setStringValue:N2LocalizedSingularPluralCount(resultArray.count, NSLocalizedString( @"study found", nil), NSLocalizedString( @"studies found", nil))];
    
	[l release];
}

- (NSString*) exportDBListOnlySelected:(BOOL) onlySelected
{
	NSIndexSet *rowIndex;
	
	if( onlySelected) rowIndex = [outlineView selectedRowIndexes];
	else rowIndex = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange( 0, [outlineView numberOfRows])];
	
	NSMutableString	*string = [NSMutableString string];
	NSArray	*columns = [[outlineView tableColumns] valueForKey:@"identifier"];
	NSArray	*descriptions = [[outlineView tableColumns] valueForKey:@"headerCell"];
	int r;
	
	for( NSInteger x = 0; x < rowIndex.count; x++)
	{
		if( x == 0) r = rowIndex.firstIndex;
		else r = [rowIndex indexGreaterThanIndex: r];
		
		id aFile = [outlineView itemAtRow: r];
		
		if( aFile && [aFile isMemberOfClass: [DCMTKStudyQueryNode class]])
		{
			if( [string length])
				[string appendString: @"\r"];
			else
			{
				int i = 0;
				for( NSCell *s in descriptions)
				{
					@try
					{
						if( [aFile valueForKey: [columns objectAtIndex: [descriptions indexOfObject: s]]])
						{
							[string appendString: [s stringValue]];
							i++;
							if( i !=  [columns count])
								[string appendFormat: @"%c", NSTabCharacter];
						}
					}
					@catch ( NSException *e)
					{
					}
				}
				[string appendString: @"\r"];
			}
			
			int i = 0;
			for( NSString *identifier in columns)
			{
				@try
				{
					if( [[aFile valueForKey: identifier] description])
						[string appendString: [[aFile valueForKey: identifier] description]];
					i++;
					if( i !=  [columns count])
						[string appendFormat: @"%c", NSTabCharacter];
				}
				@catch ( NSException *e)
				{
				}
			}
		}	
	}
	
	return string;
}

- (IBAction) saveDBListAs:(id) sender
{
	NSString *list = [self exportDBListOnlySelected:NO];
	
	NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = @[@"txt"];
    panel.nameFieldStringValue = NSLocalizedString(@"Horos Database List", nil);
		
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [list writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

-(void) query:(id)sender
{
    @try
    {
        if ([sender isKindOfClass:[NSSearchField class]])
        {
            NSString	*chars = [[NSApp currentEvent] characters];
            
            if( [chars length])
            {
                if( [chars characterAtIndex:0] != 13 && [chars characterAtIndex:0] != 3) return;
            }
        }
        
        [self autoQueryTimer: self];
        
        [self queryWithDisplayingErrors: YES];
        
        queryButtonPressed = YES;
        
        if ([sender isKindOfClass:[NSSearchField class]])
            [sender selectText: self];
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
}

- (void) performQuery:(NSNumber*) showErrors
{
	checkAndViewTry = -1;
	
    if( [NSThread isMainThread] == NO)
        showErrors = [NSNumber numberWithBool: NO];
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL performQuery = NO;
    
    @synchronized( self)
    {
        for( NSThread *t in performingQueryThreads)
            [t setIsCancelled: YES];
        
        if( performingCFind == NO)
        {
            performingCFind = YES;
            
            if( [NSThread isMainThread] == NO)
                [progressIndicator performSelectorOnMainThread: @selector(startAnimation:) withObject:nil waitUntilDone: NO];
            else
                [progressIndicator startAnimation:nil];
            
            performQuery = YES;
            
            [performingQueryThreads addObject: [NSThread currentThread]];
        }
    }
    
    if( performQuery)
    {
        [queryManager performQuery: [showErrors boolValue]];
        
        @synchronized( self)
        {
            if( [NSThread isMainThread] == NO)
                [progressIndicator performSelectorOnMainThread: @selector(stopAnimation:) withObject:nil waitUntilDone: NO];
            else
                [progressIndicator stopAnimation:nil];
            
            performingCFind = NO;
            
            [performingQueryThreads removeObject: [NSThread currentThread]];
        }
    }
    
	[pool release];
}

+ (NSString*) stringIDForStudy:(id) item
{
	return [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@", [item valueForKey:@"name"], [item valueForKey:@"patientID"], [item valueForKey:@"accessionNumber"], [item valueForKey:@"date"], [item valueForKey:@"time"], [item valueForKey:@"uid"]];
}

- (void) addStudyIfNotAvailable: (id) item toArray:(NSMutableArray*) selectedItems context: (NSManagedObjectContext*) context
{
	NSArray *studyArray = [self localStudy: item context: context];
	
	int localFiles = 0;
	int totalFiles = [[item valueForKey:@"numberImages"] intValue];
	
	if( [studyArray count])
		localFiles = [[[studyArray objectAtIndex: 0] valueForKey: @"rawNoFiles"] intValue];
	
	if( [item valueForKey:@"numberImages"] == nil || ([[NSUserDefaults standardUserDefaults] boolForKey: @"SupportPACSWithNoNumberOfImagesField"] && [[item valueForKey:@"numberImages"] intValue] == 0))
	{
		// We dont know how many images are stored on the distant PACS... add it, if we have no images on our side...
		if( localFiles == 0)
			totalFiles = 1;
	}
	
	if( localFiles < totalFiles)
	{
		NSString *stringID = [QueryController stringIDForStudy: item];
		
		@synchronized( previousAutoRetrieve)
		{
			NSNumber *previousNumberOfFiles = [previousAutoRetrieve objectForKey: stringID];
			
			// We only want to re-retrieve the study if they are new files compared to last time... we are maybe currently in the middle of a retrieve...
			
			if( [previousNumberOfFiles intValue] != totalFiles)
			{
				[selectedItems addObject: item];
				[previousAutoRetrieve setValue: [NSNumber numberWithInt: totalFiles] forKey: stringID];
			}
		}
	}
}

- (void) autoRetrieveThread: (NSMutableDictionary*) instance
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [autoQueryLock lock];
    
    NSArray *list = [[[instance objectForKey: @"resultArray"] copy] autorelease];
    
	if( autoQuery == NO)
		goto returnFromThread;
	
	if( [[BrowserController currentBrowser] database] != [DicomDatabase activeLocalDatabase])
		goto returnFromThread;
	
	if( numberOfRunningRetrieve > 5)
	{
		NSLog( @"**** numberOfRunningRetrieve > 5... wait for next autoretrieve.");
		goto returnFromThread;
	}
	
	// Start to retrieve the first XX studies...
	
	@try 
	{
		NSMutableArray *selectedItems = [NSMutableArray array];
		NSManagedObjectContext *context = nil;
        
        if( [NSThread isMainThread])
            context = [[[BrowserController currentBrowser] database] managedObjectContext];
        else
            context = [[[BrowserController currentBrowser] database] independentContext];
        
		for( id item in list)
		{
            BOOL addItem = YES;
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QR_CheckForDuplicateAccessionNumber"])
            {
                for( id study in selectedItems)
                {
                    if( [[study valueForKey: @"accessionNumber"] isEqualToString: [item valueForKey: @"accessionNumber"]])
                    {
                        NSLog( @"--- Identical AccessionNumber: %@ - %d images", item, [[item valueForKey: @"numberImages"] intValue]);
                        
                        addItem = NO;
                        break;
                    }
                }
            }
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QR_DontReDownloadStudies"])
            {
                @synchronized( self)
                {
                    if( downloadedStudies == nil)
                        downloadedStudies = [[NSMutableArray alloc] init];
                    
                    for( NSDictionary *d in [NSArray arrayWithArray: downloadedStudies])
                    {
                        if( [[d valueForKey: @"date"] timeIntervalSinceNow] > -60*60) // 1 hour - dont redownload it !
                        {
                            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QR_DontDownloadMGDescription"])
                            {
                                if( [[[item valueForKey: @"theDescription"] lowercaseString] hasPrefix: @"mg "] || [[[item valueForKey: @"theDescription"] lowercaseString] hasPrefix: @"us seins"])
                                {
                                    addItem = NO;
                                }
                            }
                            
                            if( [[d valueForKey: @"accessionNumber"] isEqualToString: [item valueForKey: @"accessionNumber"]] && [[d valueForKey: @"numberImages"] intValue] == [[item valueForKey: @"numberImages"] intValue])
                            {
                                addItem = NO;
                            }
                        }
                        else [downloadedStudies removeObject: d];
                    }
                }
            }
            
            if( addItem)
            {
                [self addStudyIfNotAvailable: item toArray: selectedItems context: context];
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"QR_DontReDownloadStudies"])
                {
                    @synchronized( self)
                    {
                        [downloadedStudies addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], @"date", [item valueForKey: @"accessionNumber"], @"accessionNumber", [item valueForKey: @"numberImages"], @"numberImages", nil]];
                    }
                }
            }
                
			if( [selectedItems count] >= [[NSUserDefaults standardUserDefaults] integerForKey: @"MaxNumberOfRetrieveForAutoQR"]) break;
		}
		
		if( [selectedItems count])
		{
			if( [[instance objectForKey:@"NumberOfPreviousStudyToRetrieve"] intValue])
			{
                NSManagedObjectContext *context = nil;
                if( [NSThread isMainThread])
                    context = [[[BrowserController currentBrowser] database] managedObjectContext];
                else
                    context = [[[BrowserController currentBrowser] database] independentContext];
                
				NSMutableArray *previousStudies = [NSMutableArray array];
				for( id item in selectedItems)
				{
					NSArray *studiesOfThisPatient = [self queryPatientIDwithoutGUI: [item valueForKey:@"patientID"]];
					
					// Sort the resut by date & time
					NSMutableArray *sortArray = [NSMutableArray array];
					[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"date" ascending: NO] autorelease]];
					[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"time" ascending: NO] autorelease]];
					studiesOfThisPatient = [studiesOfThisPatient sortedArrayUsingDescriptors: sortArray];
					
					int numberOfStudiesAssociated = [[instance objectForKey:@"NumberOfPreviousStudyToRetrieve"] intValue];
					
					for( id study in studiesOfThisPatient)
					{
						// We dont want current study
						if( [[study valueForKey:@"uid"] isEqualToString: [item valueForKey:@"uid"]] == NO)
						{
							BOOL found = NO;
							
							if( numberOfStudiesAssociated > 0)
							{
								if( [[instance objectForKey:@"retrieveSameModality"] boolValue])
								{
                                    NSArray *modalities = [[item valueForKey:@"modality"] componentsSeparatedByString: @"\\"];
                                    NSArray *relatedStudyModalities = [[study valueForKey:@"modality"] componentsSeparatedByString: @"\\"];
                                    
                                    for( NSString *modality in modalities)
                                    {
                                        if( [modality isEqualToString: @"SR"] == NO &&
                                            [modality isEqualToString: @"SC"] == NO &&
                                            [modality isEqualToString: @"PR"] == NO &&
                                            [modality isEqualToString: @"KO"] == NO)
                                        {
                                            if( [relatedStudyModalities containsObject: modality])
                                                found = YES;
                                        }
                                    }
								}
								
								if( [[instance objectForKey:@"retrieveSameDescription"] boolValue])
								{
									if( [item valueForKey:@"theDescription"] && [study valueForKey:@"theDescription"])
									{
										if( [[study valueForKey:@"theDescription"] rangeOfString: [item valueForKey:@"theDescription"]].location != NSNotFound) found = YES;
									}
								}
								
								if( found)
								{
									[self addStudyIfNotAvailable: study toArray: previousStudies context: context];
									numberOfStudiesAssociated--;
								}
							}
						}
					}
				}
				
				[selectedItems addObjectsFromArray: previousStudies];
			}
			
			for( id item in selectedItems)
				[item setShowErrorMessage: NO];
			
			NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(performRetrieve:) object: selectedItems] autorelease];
            t.name = NSLocalizedString( @"Retrieving images...", nil);
            t.status = N2LocalizedSingularPluralCount(selectedItems.count, NSLocalizedString( @"study", nil), NSLocalizedString( @"studies", nil));
            if ([selectedItems count] > 1)
                t.progress = 0;
			t.supportsCancel = YES;
			[[ThreadsManager defaultManager] addThreadAndStart: t];
			
			NSLog( @"______________________________________________");
			NSLog( @"Will auto-retrieve these items:");
			for( id item in selectedItems)
			{
				NSLog( @"%@ %@ %@ %@", [item valueForKey:@"theDescription"], [item valueForKey:@"patientID"], [item valueForKey:@"accessionNumber"], [item valueForKey:@"date"]);
			}
			NSLog( @"______________________________________________");
			
			NSString *desc = nil;
			
			if( [selectedItems count] == 1) desc = [NSString stringWithFormat: NSLocalizedString( @"Will auto-retrieve %d study", nil), [selectedItems count]];
			else desc = [NSString stringWithFormat: NSLocalizedString( @"Will auto-retrieve %d studies", nil), [selectedItems count]];
			
			[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: desc name: @"autoquery"];
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
    returnFromThread:
    
	[autoQueryLock unlock];
	
	[pool release];
}

- (void) displayAndRetrieveQueryResults: (NSMutableDictionary*) instance
{
	if( [[instance objectForKey: @"autoRetrieving"] boolValue] && autoQuery == YES)
	{
		NSThread *t = [[[NSThread alloc] initWithTarget: self selector:@selector(autoRetrieveThread:) object: instance] autorelease];
		t.name = NSLocalizedString( @"Retrieving images...", nil);
		[[ThreadsManager defaultManager] addThreadAndStart: t];
	}
}

- (void) autoQueryThread: (NSDictionary*) dictionary
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if( autoQuery)
    {
        NSMutableDictionary *instance = [dictionary objectForKey: @"instance"];
        int index = [[dictionary objectForKey: @"index"] intValue];
        
        if( [self queryWithDisplayingErrors: NO instance: instance index: index] == 0)
            [self displayAndRetrieveQueryResults: instance];
        else
        {
            [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: @"Failed..." name: @"autoquery"];
            NSLog( @"****** Q&R autoQueryThread failed...");
        }
    }
    else
    {
        if( [self queryWithDisplayingErrors: NO] == 0)
            [self displayAndRetrieveQueryResults: nil];
        else
        {
            [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: @"Failed..." name: @"autoquery"];
            NSLog( @"****** Q&R autoQueryThread failed...");
        }
	}
    
	[pool release];
}

- (void) autoQueryTimerFunction:(NSTimer*) t
{
	if( autoQuery == NO) // We will refresh the results only after a valid query, generated by the user
	{
		if( queryButtonPressed == NO)
			return;
	}
	
	if( DatabaseIsEdited == NO)
	{
        if( autoQuery)
        {
            @synchronized( autoQRInstances)
            {
                int i = 0;
                
                for(int QRInstanceIndex = 0; i < [autoQRInstances count]; i++)
                {
                    NSDictionary *QRInstance = [[autoQRInstances objectAtIndex:QRInstanceIndex] retain];
                    
                    if( [[QRInstance objectForKey: @"autoRefreshQueryResults"] intValue] != 0)
                    {
                        if( --autoQueryRemainingSecs[ i] <= 0)
                        {
                            if( [autoQueryLock tryLock])
                            {
                                if( i == currentAutoQR)
                                {
                                    [self saveSettings];
                                    
                                    if (QRInstance != [autoQRInstances objectAtIndex:QRInstanceIndex])
                                    {
                                        [QRInstance release];
                                        QRInstance = [[autoQRInstances objectAtIndex:QRInstanceIndex] retain];
                                    }
                                }
                                
                                [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Query", nil) description: NSLocalizedString( @"Refreshing...", nil) name: @"autoquery"];
                                
                                NSThread *t = [[[NSThread alloc] initWithTarget:self selector: @selector(autoQueryThread: ) object: [NSDictionary dictionaryWithObjectsAndKeys: [[QRInstance mutableCopy] autorelease], @"instance", [NSNumber numberWithInt: i], @"index", nil]] autorelease];
                                
                                if( [[QRInstance objectForKey: @"instanceName"] length] && autoQRInstances.count > 1)
                                    t.name = [NSString stringWithFormat: NSLocalizedString( @"Auto-Querying images (%@)...", nil), [QRInstance objectForKey: @"instanceName"]];
                                else
                                    t.name = NSLocalizedString( @"Auto-Querying images...", nil);
                                
                                t.supportsCancel = YES;
                                [[ThreadsManager defaultManager] addThreadAndStart: t];
                                
                                if( [[QRInstance objectForKey: @"autoRefreshQueryResults"] intValue] >= 0)
                                    autoQueryRemainingSecs[ i] = 60 * [[QRInstance objectForKey: @"autoRefreshQueryResults"] intValue]; // minutes
                                else if( [[QRInstance objectForKey: @"autoRefreshQueryResults"] intValue] < 0)
                                    autoQueryRemainingSecs[ i] = - [[QRInstance objectForKey: @"autoRefreshQueryResults"] intValue]; // seconds
                                
                                [autoQueryLock unlock];
                            }
                            else autoQueryRemainingSecs[ i] = 0;
                        }
                    }
                    i++;
                    
                    [QRInstance release];
                }
            }
        }
        else
        {
            if( self.autoRefreshQueryResults != 0)
            {
                if( --autoQueryRemainingSecs[ currentAutoQR] <= 0)
                {
                    if( [autoQueryLock tryLock])
                    {
                        [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Query", nil) description: NSLocalizedString( @"Refreshing...", nil) name: @"autoquery"];
                        
                        [self saveSettings];
                        
                        NSThread *t = [[[NSThread alloc] initWithTarget:self selector: @selector(autoQueryThread: ) object: nil] autorelease];
                        t.name = NSLocalizedString( @"Auto-Querying images...", nil);
                        t.supportsCancel = YES;
                        [[ThreadsManager defaultManager] addThreadAndStart: t];
                        
                        if( self.autoRefreshQueryResults >= 0)
                            autoQueryRemainingSecs[ currentAutoQR] = 60 * self.autoRefreshQueryResults; // minutes
                        else
                            autoQueryRemainingSecs[ currentAutoQR] = -self.autoRefreshQueryResults; // seconds
                        
                        [autoQueryLock unlock];
                    }
                    else autoQueryRemainingSecs[ currentAutoQR] = 0;
                }
            }
        }
	}
	
    if( self.autoRefreshQueryResults)
        [autoQueryCounter setStringValue: [NSString stringWithFormat: @"%2.2d:%2.2d", (int) (autoQueryRemainingSecs[ currentAutoQR]/60), (int) (autoQueryRemainingSecs[ currentAutoQR]%60)]];
    else
        [autoQueryCounter setStringValue: @""];
}

- (IBAction) autoQueryTimer:(id) sender
{
    [QueryTimer invalidate];
    [QueryTimer release];
    QueryTimer = nil;
    
    if( self.autoRefreshQueryResults >= 0)
        autoQueryRemainingSecs[ currentAutoQR] = 60*self.autoRefreshQueryResults; // minutes
    else
        autoQueryRemainingSecs[ currentAutoQR] = -self.autoRefreshQueryResults; // seconds
    
    if( self.autoRefreshQueryResults)
        [autoQueryCounter setStringValue: [NSString stringWithFormat: @"%2.2d:%2.2d", (int) (autoQueryRemainingSecs[ currentAutoQR]/60), (int) (autoQueryRemainingSecs[ currentAutoQR]%60)]];
    else
        [autoQueryCounter setStringValue: @""];
    
    [self saveSettings];
    
    QueryTimer = [[NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector(autoQueryTimerFunction:) userInfo:nil repeats:YES] retain];
}

- (void)clearQuery:(id)sender
{
	[queryManager release];
	queryManager = nil;
	[progressIndicator stopAnimation: nil];
	[searchFieldName setStringValue: @""];
	[searchFieldRefPhysician setStringValue:@""];
    [searchInstitutionName setStringValue: @""];
	[searchFieldID setStringValue: @""];
	[searchFieldAN setStringValue: @""];
	[searchFieldStudyDescription setStringValue: @""];
	[searchFieldComments setStringValue: @""];
	[outlineView reloadData];
}

- (IBAction) copy: (id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	
	[pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:self];
	
	NSString *string;
	
	if( [[outlineView selectedRowIndexes] count] == 1)
		string = [[outlineView itemAtRow: [outlineView selectedRowIndexes].firstIndex] valueForKey: @"name"];
	else 
		string = [self exportDBListOnlySelected: YES];
	
	[pb setString: string forType:NSPasteboardTypeString];
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable forViewing: (BOOL) forViewing items:(NSArray*) items showGUI:(BOOL) showGUI
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	
    if( [NSThread isMainThread] == NO)
        showGUI = NO;
    
	if([items count])
	{
		for( id item in items)
		{
			[item setShowErrorMessage: showGUI];
			
			if( onlyIfNotAvailable)
			{
//				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"RetrieveOnlyMissingUID"])
//				{
//					DicomStudy *localStudy = nil;
//					
//					// Local Study
//					if( [item isMemberOfClass: [DCMTKSeriesQueryNode class]])
//					{
//						array = [self localSeries: item context: nil];
//						
//						if( [array count])
//							localStudy = [[array lastObject] valueForKey: @"study"];
//					}
//					else
//					{
//						array = [self localStudy: item context: nil];
//						
//						if( [array count])
//							localStudy = [array lastObject];
//					}
//					
//					if( localStudy)
//					{
//						NSArray *localImagesUIDs = [[localStudy valueForKeyPath: @"series.images.sopInstanceUID"] allObjects];
//						
//						DcmDataset *dataset = new DcmDataset();
//						
//						dataset-> insertEmptyElement(DCM_StudyInstanceUID, OFTrue);
//						dataset-> insertEmptyElement(DCM_SeriesInstanceUID, OFTrue);
//						dataset-> insertEmptyElement(DCM_SOPInstanceUID, OFTrue);
//						
//						if( [item isMemberOfClass:[DCMTKStudyQueryNode class]]) // Study Level
//							dataset-> putAndInsertString(DCM_StudyInstanceUID, [[item uid] UTF8String], OFTrue);
//						else													// Series Level
//							dataset-> putAndInsertString(DCM_SeriesInstanceUID, [[item uid] UTF8String], OFTrue);
//							
//						dataset-> putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE", OFTrue);
//						
//						[self queryWithValues: nil dataset: dataset];
//						
//						for( DCMTKImageQueryNode *image in [self children])
//						{
//							if( [image uid])
//							{
//								if( [localImagesUIDs containsObject: [image uid]])
//								{
//									// already here
//								}
//								else
//								{
//									// not here
//								}
//							}
//						}
//					}
//				}
//				else
				{
					int localNumber = 0;
					NSArray *array = 0L;
					
					if( [item isMemberOfClass: [DCMTKSeriesQueryNode class]])
						array = [self localSeries: item context: nil];
					else
						array = [self localStudy: item context: nil];
					
					if( [array count])
						localNumber = [[[array objectAtIndex: 0] valueForKey: @"rawNoFiles"] intValue];
					
					if( localNumber < [[item valueForKey:@"numberImages"] intValue] || [[item valueForKey:@"numberImages"] intValue] == 0)
					{
						NSString *stringID = [QueryController stringIDForStudy: item];
			
						@synchronized( previousAutoRetrieve)
						{
							NSNumber *previousNumberOfFiles = [previousAutoRetrieve objectForKey: stringID];
				
							// We only want to re-retrieve the study if they are new files compared to last time... we are maybe currently in the middle of a retrieve...
							
							if( [previousNumberOfFiles intValue] != [[item valueForKey:@"numberImages"] intValue] || [[item valueForKey:@"numberImages"] intValue] == 0)
							{
								[selectedItems addObject: item];
								[previousAutoRetrieve setValue: [NSNumber numberWithInt: [[item valueForKey:@"numberImages"] intValue]] forKey: stringID];
							}
							else NSLog( @"Already in transfer.... We don't need to download it...");
						}
					}
					else
						NSLog( @"Already here! We don't need to download it...");
				}
			}
			else
			{
				NSString *stringID = [QueryController stringIDForStudy: item];
				
				@synchronized( previousAutoRetrieve)
				{
					NSNumber *previousNumberOfFiles = [previousAutoRetrieve objectForKey: stringID];
					
					// We only want to re-retrieve the study if they are new files compared to last time... we are maybe currently in the middle of a retrieve...
					
					if( [previousNumberOfFiles intValue] != [[item valueForKey:@"numberImages"] intValue] || [[item valueForKey:@"numberImages"] intValue] == 0)
					{
						[selectedItems addObject: item];
						[previousAutoRetrieve setValue: [NSNumber numberWithInt: [[item valueForKey:@"numberImages"] intValue]] forKey: stringID];
					}
					else NSLog( @"Already in transfer.... We don't need to download it...");
				}
			}
		}
		
		if( [selectedItems count] > 0)
		{
			if( [sendToPopup indexOfSelectedItem] != 0 && forViewing == YES)
			{
				if( showGUI)
					NSRunCriticalAlertPanel(NSLocalizedString( @"DICOM Query & Retrieve",nil), NSLocalizedString( @"If you want to retrieve & view these images, change the destination to this computer ('retrieve to' menu).",nil),NSLocalizedString( @"OK",nil), nil, nil);
			}
			else
			{
				WaitRendering *wait = nil;
				
				if( showGUI)
				{
					wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting Retrieving...", nil)];
					[wait showWindow:self];
				}
				
				checkAndViewTry = -1;
				
				NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(performRetrieve:) object: selectedItems] autorelease];
				t.name = NSLocalizedString( @"Retrieving images...", nil);
                t.status = N2LocalizedSingularPluralCount(selectedItems.count, NSLocalizedString(@"study", nil), NSLocalizedString(@"studies", nil));
                if ([selectedItems count] > 1)
                    t.progress = 0;
				
				t.supportsCancel = YES;
				[[ThreadsManager defaultManager] addThreadAndStart: t];
				
				if( showGUI)
				{
					[NSThread sleepForTimeInterval: 0.2];
				
					[wait close];
					[wait autorelease];
				}
			}
		}
	}
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable forViewing: (BOOL) forViewing
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	NSIndexSet		*selectedRowIndexes = [outlineView selectedRowIndexes];
	
	if( [selectedRowIndexes count])
	{
		for (NSUInteger index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
		{
		   if ([selectedRowIndexes containsIndex:index])
				[selectedItems addObject: [outlineView itemAtRow:index]];
		}
		
		[self retrieve: sender onlyIfNotAvailable: onlyIfNotAvailable forViewing: forViewing items: selectedItems showGUI: YES];
	}
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable
{
	return [self retrieve: sender onlyIfNotAvailable: onlyIfNotAvailable forViewing: NO];
}

-(void) retrieve:(id)sender
{
	[self retrieve: sender onlyIfNotAvailable: NO];
}

- (IBAction) retrieveAndView: (id) sender
{
	[self retrieve: self onlyIfNotAvailable: YES forViewing: YES];
	[self view: self];
}

- (IBAction) retrieveAndViewClick: (id) sender
{
	if( [[outlineView tableColumns] count] > [outlineView clickedColumn] && [outlineView clickedColumn] >= 0)
	{
		if( [[[[outlineView tableColumns] objectAtIndex: [outlineView clickedColumn]] identifier] isEqualToString: @"comment"])
			return;
	}
	   
	if( [outlineView clickedRow] >= 0)
	{
		[self retrieveAndView: sender];
	}
}

- (void) retrieveClick:(id)sender
{
	if( [outlineView clickedRow] >= 0)
	{
		[self retrieve: sender];
	}
}

- (IBAction) setBirthDate:(id) sender
{
	NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[searchBirth dateValue] timeIntervalSinceReferenceDate]];
	NSCalendarDate *dateOfBirth = [NSCalendarDate date];
	NSString *yearOld = nil;
	NSInteger years, months, days;
	
	[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
	
	if( years < 2)
	{
		if( years < 1)
		{
			if( months < 1)
            {
                if( days < 0) yearOld = @"";
                else yearOld = [NSString stringWithFormat: NSLocalizedString( @"%d d", @"d = day"), days];
            }
            else yearOld = [NSString stringWithFormat: @"%d%@", (int) months, NSLocalizedString( @" m", @"m = month")];
        }
        else yearOld = [NSString stringWithFormat: @"%d%@ %d%@", (int) years, NSLocalizedString( @" y", @"y = year"), (int) months, NSLocalizedString( @" m", @"m = month")];
    }
    else yearOld = [NSString stringWithFormat: @"%d%@", (int) years, NSLocalizedString( @" y", @"y = year")];
    
	[yearOldBirth setStringValue: yearOld];
}

- (void) performRetrieve:(NSArray*) array
{
    if ( [[BrowserController currentBrowser] database] == nil) // During SB rebuild
        return;
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [NSThread currentThread].name = NSLocalizedString( @"Retrieving images...", nil);
    
	if( [[AppController sharedAppController] isStoreSCPRunning] == NO)
	{
		NSLog( @"----- isStoreSCPRunning == NO, cannot retrieve");
		return;
	}
	
	NSMutableArray *moveArray = [NSMutableArray array];
	
	@synchronized( self)
	{
		numberOfRunningRetrieve++;
	}
	
    // Apply the same order for retrieving, as the sources order
    NSMutableArray *reorderedArray = [NSMutableArray array];
    
    @try
    {
        for( NSDictionary *source in sourcesArray)
        {
            for( DCMTKQueryNode *node in array)
            {
                if( [[node _hostname] isEqualToString: [[source valueForKey: @"server"] valueForKey: @"Address"]] && [node _port] == [[[source valueForKey: @"server"] valueForKey: @"Port"] intValue])
                    if( [reorderedArray containsObject: node] == NO)
                        [reorderedArray addObject: node];
            }
        }
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace( e);
    }
    
    for( DCMTKQueryNode *node in array)
    {
        if( [reorderedArray containsObject: node] == NO)
            [reorderedArray addObject: node];
    }
    
    if( array.count == reorderedArray.count)
        array = reorderedArray;
    else
        NSLog( @"------- array.count != reorderedArray.count : QueryController performRetrieve");
    
    [array retain];
    
	@try
	{
		NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
		NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary: [queryManager parameters] copyItems: YES];
		
		NSLog( @"Retrieve START");
		
		BOOL allowNonCMOVE = YES;
		
		for( NSUInteger i = 0; i < [array count] ; i++)
		{
			DCMTKQueryNode *object = [[array objectAtIndex: i] retain];
			
			[dictionary setObject: [[[[object extraParameters] valueForKey: @"retrieveMode"] copy] autorelease] forKey:@"retrieveMode"];
			[dictionary setObject: [[[object valueForKey:@"calledAET"] copy] autorelease] forKey:@"calledAET"];
			[dictionary setObject: [[[object valueForKey:@"hostname"] copy] autorelease] forKey:@"hostname"];
			[dictionary setObject: [[[object valueForKey:@"port"] copy] autorelease] forKey:@"port"];
			[dictionary setObject: [[[object valueForKey:@"transferSyntax"] copy] autorelease] forKey:@"transferSyntax"];
            
            [dictionary setObject: [[NSUserDefaults defaultAETitle] copy] forKey: @"moveDestination"];
			
			NSDictionary *dstDict = nil;
			
			if( [sendToPopup indexOfSelectedItem] != 0)
			{
				NSInteger index = [sendToPopup indexOfSelectedItem] -2;
				
				dstDict = [[[[DCMNetServiceDelegate DICOMServersList] objectAtIndex: index] copy] autorelease];
				
				[dictionary setObject: [dstDict valueForKey:@"AETitle"] forKey: @"moveDestination"];
				
				allowNonCMOVE = NO;
			}
			
			if( [[dstDict valueForKey:@"Port"] intValue]  == [[dictionary valueForKey:@"port"] intValue] &&
				[[dstDict valueForKey:@"Address"] isEqualToString: [dictionary valueForKey:@"hostname"]])
				{
					NSLog( @"move source == move destination -> Do Nothing");
				}
			else
			{
				NSMutableDictionary *d = [NSMutableDictionary dictionary];
				[d setObject: object forKey: @"query"];
				[d setObject: [dictionary objectForKey: @"retrieveMode"] forKey: @"retrieveMode"];
				
				if( [object isMemberOfClass: [DCMTKSeriesQueryNode class]])
				{
					if( [outlineView parentForItem: object])
						[d setObject: [outlineView parentForItem: object] forKey:@"study"];	// for WADO retrieve at Series level
				}
				
				if( [dictionary objectForKey: @"moveDestination"])
					[d setObject: [dictionary objectForKey: @"moveDestination"] forKey: @"moveDestination"];
				
				[moveArray addObject: d];
			}
			
			[object release];
		}
		
		[dictionary release];
		[subPool release];
		
		int i = 0;
		for( NSDictionary *d in moveArray)
		{
			DCMTKQueryNode *object = [d objectForKey: @"query"];
			
			NSString *status = nil;
			
			if( [object isMemberOfClass:[DCMTKStudyQueryNode class]])
			{
				if( [array count] == 1) status = [NSString stringWithFormat: NSLocalizedString( @"%d study", nil), [array count]];
				else status = [NSString stringWithFormat: NSLocalizedString( @"%d studies", nil), [array count]];
                
                if( [object name])
                    status = [status stringByAppendingFormat:@" - %@", [object name]];
			}
			
			if( [object isMemberOfClass:[DCMTKSeriesQueryNode class]])
			{
				status = [NSString stringWithFormat: NSLocalizedString( @"%d series", nil), [array count]];
                
                if( [object theDescription])
                    status = [status stringByAppendingFormat:@" - %@", [object theDescription]];
			}
			
			[NSThread currentThread].status = [status stringByReplacingOccurrencesOfString: @"^" withString: @" "];
			
			@try
			{
				FILE * pFile = fopen ("/tmp/kill_all_storescu", "r");
				if( pFile)
					fclose (pFile);
				else
				{
					if( allowNonCMOVE)
						[object move: d retrieveMode: [[d objectForKey: @"retrieveMode"] intValue]];
					else
						[object move: d retrieveMode: CMOVERetrieveMode];
				}
			}
			@catch (NSException * e)
			{
                NSLog( @"dictionary: %@", d);
                NSLog( @"object: %@, %@", object, [object uid]);
				N2LogExceptionWithStackTrace( e);
			}
			
			@synchronized( previousAutoRetrieve)
			{
				[previousAutoRetrieve removeObjectForKey: [QueryController stringIDForStudy: object]];
			}
			
			[NSThread currentThread].progress = (float) ++i / (float) [moveArray count];
			if( [NSThread currentThread].isCancelled)
			{
				[[NSFileManager defaultManager] createFileAtPath: @"/tmp/kill_all_storescu" contents: [NSData data] attributes: nil];
				[NSThread sleepForTimeInterval: 3];
				unlink( "/tmp/kill_all_storescu");
				break;
			}
		}
		
		@synchronized( previousAutoRetrieve)
		{
			for( DCMTKQueryNode *object in [moveArray valueForKey: @"query"])
			{
				@try
				{
					[previousAutoRetrieve removeObjectForKey: [QueryController stringIDForStudy: object]];
				}
				@catch (NSException * e)
				{
					NSLog( @"performRetrieve previousAutoRetrieve removeObjectForKey exception: %@", e);
				}
			}
		}
		
		[NSThread sleepForTimeInterval: 0.5];	// To allow errorMessage on the main thread...
		
		if( [[self window] isVisible])
		{
			FILE * pFile = fopen( "/tmp/kill_all_storescu", "r");
			if( pFile)
				fclose (pFile);
			else
			{
				for( id item in array)
					[item setShowErrorMessage: YES];
			}
		}
		
		NSLog(@"Retrieve END");
	}
	@catch (NSException *e)
	{
		N2LogExceptionWithStackTrace( e);
	}
	
	[array release];
	
	@synchronized( self)
	{
		numberOfRunningRetrieve--;
	}
	
	[pool release];
}

- (void) checkAndView:(id) item
{
	if( [[self window] isVisible] == NO)
		return;
	
	if( checkAndViewTry < 0)
		return;
	
    DicomDatabase *db = [DicomDatabase activeLocalDatabase];
    [[BrowserController currentBrowser] setDatabase:db];
	[db initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
	
	NSError *error = nil;
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext *context = [[DicomDatabase activeLocalDatabase] managedObjectContext];
	
	NSArray *studyArray, *seriesArray;
	BOOL success = NO;
	
	[context lock];
	
	@try
	{
		if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
		{
			NSPredicate	*predicate = [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", [item valueForKey:@"uid"]];
			
			[request setEntity: [[BrowserController.currentBrowser.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
			[request setPredicate: predicate];
			
			studyArray = [context executeFetchRequest:request error:&error];
			if( [studyArray count] > 0)
			{
				NSManagedObject	*study = [studyArray objectAtIndex: 0];
				NSArray *seriesArray = [[BrowserController currentBrowser] childrenArray: study];
				
				if( [seriesArray count])
				{
					NSManagedObject	*series =  [seriesArray objectAtIndex: 0];
					
					if( [[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO] == NO)
					{
						[[BrowserController currentBrowser] showEntireDatabase];
						if( [[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO]) success = YES;
					}
					else success = YES;
					
					if( success) [[BrowserController currentBrowser] databaseOpenStudy: study];
				}
			}
		}
		
		if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
		{
			NSPredicate	*predicate = [NSPredicate predicateWithFormat:  @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]];
			
			NSLog( @"%@",  [predicate description]);
			
			[request setEntity: [[BrowserController.currentBrowser.database.managedObjectModel entitiesByName] objectForKey:@"Series"]];
			[request setPredicate: predicate];
			
			seriesArray = [context executeFetchRequest:request error:&error];
			if( [seriesArray count] > 0)
			{
				NSLog( @"%@",  [seriesArray description]);
				
				NSManagedObject	*series = [seriesArray objectAtIndex: 0];
				
				[[BrowserController currentBrowser] openViewerFromImages: [NSArray arrayWithObject: [[BrowserController currentBrowser] childrenArray: series]] movie: NO viewer :nil keyImagesOnly:NO];
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
					[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
				else
					[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
					
				success = YES;
			}
		}
		
		if( !success)
		{
            [db initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
			
			if( checkAndViewTry-- > 0 && [sendToPopup indexOfSelectedItem] == 0)
				[self performSelector:@selector(checkAndView:) withObject:item afterDelay:1.0];
			else
				success = YES;
		}
				
	}
	@catch (NSException * e)
	{
		NSLog( @"**** checkAndView exception: %@", [e description]);
	}
	
	[context unlock];
}

- (IBAction) view:(id) sender
{
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	
	{
		checkAndViewTry = 20;
		if( item)
            [self checkAndView: item];
	}
}

- (QueryFilter*) getModalityQueryFilter:(NSArray*) modalityArray
{
    QueryFilter *modalityFilter = nil;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
    {
        if( modalityArray.count)
            modalityFilter = [QueryFilter queryFilterWithObject: [modalityArray componentsJoinedByString:@"\\"] ofSearchType: searchExactMatch forKey:@"ModalitiesinStudy"];
        else
            modalityFilter = [QueryFilter queryFilterWithObject: nil ofSearchType: searchExactMatch forKey:@"ModalitiesinStudy"];
    }
    else
    {
        if( modalityArray.count)
            modalityFilter = [QueryFilter queryFilterWithObject: [modalityArray componentsJoinedByString:@"\\"] ofSearchType: searchExactMatch forKey:@"Modality"];
        else
            modalityFilter = [QueryFilter queryFilterWithObject: nil ofSearchType: searchExactMatch forKey:@"Modality"];
    }

    return modalityFilter;
}

- (void)setModalityQuery:(id)sender
{
    NSMutableString *cellsString = [NSMutableString string];
	for( NSCell *cell in [modalityFilterMatrix cells])
	{
		if( [cell state] == NSOnState)
		{
			NSInteger row, col;
			
			[modalityFilterMatrix getRow: &row column: &col ofCell:cell];
			[cellsString appendString: [NSString stringWithFormat:@"%d %d ", (int) row, (int) col]];
		}
	}
}

+ (void) getDateAndTimeQueryFilterWithTag: (int) tag fromDate:(NSDate*) from toDate:(NSDate*) to date: (QueryFilter**) dateQueryFilter time: (QueryFilter**) timeQueryFilter
{
    *dateQueryFilter = nil;
	*timeQueryFilter = nil;
	
	if( tag == between)
	{
		NSDate *later = [from laterDate: to];
		NSDate *earlier = [from earlierDate: to];
		
		NSString *between = [NSString stringWithFormat:@"%@-%@", [earlier descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil], [later descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];
		
		*dateQueryFilter = [QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch forKey:@"StudyDate"];
	}
    else if( tag == on)
	{
        DCMCalendarDate *date = [DCMCalendarDate dateWithTimeIntervalSinceReferenceDate: [from timeIntervalSinceReferenceDate]];
        
        *dateQueryFilter = [QueryFilter queryFilterWithObject: date ofSearchType: searchExactDate forKey:@"StudyDate"];
	}
	else
	{
		DCMCalendarDate *date = nil;
		
		int searchType = searchAfter;
		NSString *between = nil;
		
		switch( tag)
		{
			case anyDate: date = nil; break;
            
			case today: date = [DCMCalendarDate date]; searchType = searchExactDate; break;
                
			case yesteday: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24 -1];	searchType = searchExactDate; break;
                
            case dayBeforeYesterday: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*48 -1]; searchType = searchExactDate; break;
            
            case after: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: [from timeIntervalSinceReferenceDate]];
                
            case last2Days: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*2 -1]; break;
                
			case last7Days: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*7 -1]; break;
                
			case lastMonth: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31 -1]; break;
                
            case last3Months: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31*3 -1]; break;
            case last2Months: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31*2 -1]; break;
            case lastYear: date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*365 -1]; break;
            
            case todayAM:	// AM & PM
			case todayPM:
				date = [DCMCalendarDate date];
				searchType = searchExactDate;
				
				if( tag == todayAM)
					between = @"000000.000-120000.000";
				else
					between = @"120000.000-235959.000";
				
				*timeQueryFilter = [QueryFilter queryFilterWithObject: between ofSearchType: searchExactMatch forKey:@"StudyTime"];
            break;
                
            default:
                if( tag >= 100 && tag <= 200)
                {
                    int hours = tag - 100;
                    
                    searchType = searchAfter;
                    
                    date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*hours];
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMQueryAllowFutureQuery"])
                        between = [NSString stringWithFormat:@"%@.000-", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*60*hours] descriptionWithCalendarFormat: @"%H%M%S"]];
                    else
                        between = [NSString stringWithFormat:@"%@.000-%@.000", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*60*hours] descriptionWithCalendarFormat: @"%H%M%S"], [[NSCalendarDate date] descriptionWithCalendarFormat: @"%H%M%S"]];
                    
                    *timeQueryFilter = [QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyTime"];
                }
                else if( tag >= 200 && tag <= 300)
                {
                    int min = tag - 200;
                    
                    searchType = searchAfter;
                    
                    date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*min];
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMQueryAllowFutureQuery"])
                        between = [NSString stringWithFormat:@"%@.000-", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*min] descriptionWithCalendarFormat: @"%H%M%S"]];
                    else
                        between = [NSString stringWithFormat:@"%@.000-%@.000", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*min] descriptionWithCalendarFormat: @"%H%M%S"], [[NSCalendarDate date] descriptionWithCalendarFormat: @"%H%M%S"]];
                    
                    *timeQueryFilter = [QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyTime"];
                }
                else NSLog( @"******* unknown setDateQuery tag: %d", (int) tag);
                break;
            }
		*dateQueryFilter = [QueryFilter queryFilterWithObject: date ofSearchType: searchType forKey:@"StudyDate"];
	}
} 

- (void)setDateQuery:(id)sender
{
	if( [sender selectedTag] == between)
	{
		[fromDate setEnabled: YES];
		[toDate setEnabled: YES];
	}
    else if( [sender selectedTag] == on)
	{
		[fromDate setEnabled: YES];
		[toDate setEnabled: NO];
	}
	else
	{
		[fromDate setEnabled: NO];
		[toDate setEnabled: NO];
    }
}

-(void) awakeFromNib
{
    [authView setDelegate: self];
    [authView setString: "BUNDLE_IDENTIFIER.autoQRWindow"];
    [authView updateStatus: self];
    
	[numberOfStudies setStringValue: @""];
	
    if (autoQuery)
    {
        NSRect frame = [refreshGroup frame];
        frame.origin.y += 6;
        [refreshGroup setFrame:frame];
    }
    
    if( autoQuery)
        [PatientModeMatrix selectTabViewItemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"AutoQRPatientModeMatrixIndex"]];
    else
        [PatientModeMatrix selectTabViewItemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"QRPatientModeMatrixIndex"]];
    
//	[[self window] setFrameAutosaveName:@"QueryRetrieveWindow"];
	
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier: @"stateText"];
	NSPopUpButtonCell *buttonCell = [[[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO] autorelease];
//	[buttonCell setEditable: YES];
	[buttonCell setBordered: NO];
	[buttonCell addItemsWithTitles: [BrowserController statesArray]];
	[tableColumn setDataCell:buttonCell];
	
    tableColumn = [outlineView tableColumnWithIdentifier: @"serverStateText"];
    buttonCell = [[[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO] autorelease];
	[buttonCell setBordered: NO];
	[buttonCell addItemsWithTitles: [BrowserController statesArray]];
	[tableColumn setDataCell:buttonCell];
    
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldAN cell];
		item1 = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString( @"Recent Searches", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
        
		item2 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recents", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
        
		item3 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Clear", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
        
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldStudyDescription cell];
		item1 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recent Searches", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
        
		item2 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recents", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
        
		item3 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Clear", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
        
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldComments cell];
		item1 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recent Searches", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
        
		item2 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recents", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
        
		item3 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Clear", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
        
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldRefPhysician cell];
		item1 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recent Searches", nil)
										   action:NULL
									keyEquivalent:@""] autorelease];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
        
		item2 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recents", nil)
										   action:NULL
									keyEquivalent:@""] autorelease];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
        
		item3 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Clear", nil)
										   action:NULL
									keyEquivalent:@""] autorelease];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
        
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldID cell];
		item1 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recent Searches", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
        
		item2 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recents", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
        
		item3 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Clear", nil)
								action:NULL
								keyEquivalent:@""] autorelease];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
        
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldName cell];
		item1 = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString( @"Recent Searches", nil)
									action:NULL
									keyEquivalent:@""] autorelease];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
        
		item2 = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString( @"Recents", nil)
									action:NULL
									keyEquivalent:@""] autorelease];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
        
		item3 = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString( @"Clear", nil)
									action:NULL
									keyEquivalent:@""] autorelease];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
        
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	[[[outlineView tableColumnWithIdentifier: @"birthdate"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
	[[[outlineView tableColumnWithIdentifier: @"date"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
	
	[sourcesTable setDoubleAction: @selector(selectUniqueSource:)];
	
	[self refreshSources];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
		{
			[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
			[sourcesTable scrollRowToVisible: i];
			break;
		}
	}
	
	[self buildPresetsMenu];
	
	[alreadyInDatabase setImage:[NSImage pieChartImageWithPercentage:1.0]];
	[partiallyInDatabase setImage:[NSImage pieChartImageWithPercentage:0.33]];
	
	[self autoQueryTimer: self];
	
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	[toDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	
	[[self window] setDelegate: self];
	
	[self setBirthDate: nil];
    
    // build table header context menu
    if( [[outlineView autosaveName] length] == 0)
    {
        NSArray *cols = nil;
        
        if( autoQuery)
            cols = [[NSUserDefaults standardUserDefaults] arrayForKey: @"NewQueryControllerTableColumnsAutoQR"];
        else
            cols = [[NSUserDefaults standardUserDefaults] arrayForKey: @"NewQueryControllerTableColumns"];
        
        NSMenu *tableHeaderContextMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        [[outlineView headerView] setMenu:tableHeaderContextMenu];
        NSArray *tableColumns = [NSArray arrayWithArray:[outlineView tableColumns]]; // clone array so compiles/runs on 10.5
        NSEnumerator *enumerator = [tableColumns objectEnumerator];
        
        NSTableColumn *column;
        while((column = [enumerator nextObject]))
        {
            NSString *identifier = [column identifier];        
            NSString *title = [[column headerCell] title];
            if( [identifier isEqualToString: @"Button"] == NO && [identifier isEqualToString: @"name"] == NO)
            {
                NSMenuItem *item = [tableHeaderContextMenu addItemWithTitle:title action:@selector(contextMenuSelected:) keyEquivalent:@""];
                [item setTarget: self];
                [item setRepresentedObject: column];
                [item setState: cols ? NSOffState: NSOnState];
                
                if( cols)
                    [outlineView removeTableColumn:column]; // initially want to show all columns
            }
        }
        // add columns in correct order with correct width, ensure menu items are in correct state
        enumerator = [cols objectEnumerator];
        NSDictionary *colinfo;
        while((colinfo = [enumerator nextObject]))
        {
            NSString *identifier = [colinfo objectForKey: @"identifier"];
            NSMenuItem *item = nil;
            for (NSMenuItem *menuItem in tableHeaderContextMenu.itemArray)
            {
                if( [[(NSTableColumn*) menuItem.representedObject identifier] isEqualToString: identifier])
                {
                    item = menuItem;
                    break;
                }
            }
            
            if( !item)
            {
                if( [identifier isEqualToString: @"Button"] || [identifier isEqualToString: @"name"])
                {
                    column = [outlineView tableColumnWithIdentifier: identifier];
                    
                    [column setWidth: [[colinfo objectForKey:@"width"] floatValue]];
                }
                else
                    NSLog( @"QR: item not found: %@", identifier);
            }
            else
            {
                [item setState: NSOnState];
                column = [item representedObject];
                
                [column setWidth:[[colinfo objectForKey:@"width"] floatValue]];
                [outlineView addTableColumn: column];
            }
        }
        
        NSString *prefsSortKey = nil;
        if( autoQuery)
            prefsSortKey = @"QueryControllerTableColumnsSortDescriptorAutoQR";
        else
            prefsSortKey = @"QueryControllerTableColumnsSortDescriptor";
        
        if( [[NSUserDefaults standardUserDefaults] objectForKey: prefsSortKey])
        {
            NSDictionary *sort = [[NSUserDefaults standardUserDefaults] objectForKey: prefsSortKey];
            {
                if( [outlineView columnWithIdentifier: [sort objectForKey:@"key"]] != -1)
                {
                    NSSortDescriptor *prototype = [[outlineView tableColumnWithIdentifier: [sort objectForKey:@"key"]] sortDescriptorPrototype];
                    
                    [outlineView setSortDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:[sort objectForKey:@"key"] ascending:[[sort objectForKey:@"order"] boolValue]  selector: [prototype selector]] autorelease]]];
                }
                else
                    [outlineView setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
            }
        }
        else
            [outlineView setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
        
        // listen for changes so know when to save
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveTableColumns) name:NSOutlineViewColumnDidMoveNotification object: outlineView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveTableColumns) name:NSOutlineViewColumnDidResizeNotification object: outlineView];
    }
}

- (void)saveTableColumns
{
    NSMutableArray *cols = [NSMutableArray array];
    NSEnumerator *enumerator = [[outlineView tableColumns] objectEnumerator];
    NSTableColumn *column;
    while((column = [enumerator nextObject]))
    {
        [cols addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         [column identifier], @"identifier",
                         [NSNumber numberWithFloat:[column width]], @"width",
                         nil]];
    }
    
    if( autoQuery)
    {
        [[NSUserDefaults standardUserDefaults] setObject:cols forKey: @"NewQueryControllerTableColumnsAutoQR"];
        NSDictionary *sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[outlineView sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[outlineView sortDescriptors] objectAtIndex: 0] key], @"key", nil];
        [[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"QueryControllerTableColumnsSortDescriptorAutoQR"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:cols forKey: @"NewQueryControllerTableColumns"];
        NSDictionary *sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[outlineView sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[outlineView sortDescriptors] objectAtIndex: 0] key], @"key", nil];
        [[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"QueryControllerTableColumnsSortDescriptor"];
    }
}

- (void)contextMenuSelected:(NSMenuItem*)sender
{
    BOOL on = ([sender state] == NSOnState);
    [sender setState: on ? NSOffState : NSOnState];
    
    NSTableColumn *column = [sender representedObject];
    
    if( on)
        [outlineView removeTableColumn:column];
    else
        [outlineView addTableColumn:column];
    
    [outlineView setNeedsDisplay:YES];
    [self saveTableColumns];
}

//******

- (IBAction) selectUniqueSource:(id) sender
{
	[self willChangeValueForKey:@"sourcesArray"];
	
	for( NSUInteger i = 0; i < [sourcesArray count]; i++)
	{
		NSMutableDictionary		*source = [NSMutableDictionary dictionaryWithDictionary: [sourcesArray objectAtIndex: i]];
		
		if( [sender selectedRow] == i) [source setObject: [NSNumber numberWithBool:YES] forKey:@"activated"];
		else [source setObject: [NSNumber numberWithBool:NO] forKey:@"activated"];
		
		[sourcesArray	replaceObjectAtIndex: i withObject:source];
	}
	
	[self didChangeValueForKey:@"sourcesArray"];
}

- (NSDictionary*) findCorrespondingServer: (NSDictionary*) savedServer inServers : (NSArray*) servers
{
	for( NSUInteger i = 0 ; i < [servers count]; i++)
	{
		if( [[savedServer objectForKey:@"AETitle"] isEqualToString: [[servers objectAtIndex:i] objectForKey:@"AETitle"]] && 
			[[savedServer objectForKey:@"AddressAndPort"] isEqualToString: [NSString stringWithFormat:@"%@:%@", [[servers objectAtIndex:i] valueForKey:@"Address"], [[servers objectAtIndex:i] valueForKey:@"Port"]]])
			{
				return [servers objectAtIndex:i];
			}
	}
	
	return nil;
}

- (void) refreshSources
{
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: queryArrayPrefs];
	
	NSMutableArray		*serversArray		= [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
	NSArray				*savedArray			= [[NSUserDefaults standardUserDefaults] arrayForKey: queryArrayPrefs];
	
	[self willChangeValueForKey:@"sourcesArray"];
	 
	[sourcesArray removeAllObjects];
	
	for( NSUInteger i = 0; i < [savedArray count]; i++)
	{
		NSDictionary *server = [self findCorrespondingServer: [savedArray objectAtIndex:i] inServers: serversArray];
		
		if( server && ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
		{
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[[savedArray objectAtIndex: i] valueForKey:@"activated"], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
			
			[serversArray removeObject: server];
		}
	}
	
	for( NSUInteger i = 0; i < [serversArray count]; i++)
	{
		NSDictionary *server = [serversArray objectAtIndex: i];
		
		if( ([[server valueForKey:@"QR"] boolValue] == YES || [server valueForKey:@"QR"] == nil ))
		
			[sourcesArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", [server valueForKey:@"Description"], @"name", [server valueForKey:@"AETitle"], @"AETitle", [NSString stringWithFormat:@"%@:%@", [server valueForKey:@"Address"], [server valueForKey:@"Port"]], @"AddressAndPort", server, @"server", nil]];
	}
	
	[sourcesTable reloadData];
	
	[self didChangeValueForKey:@"sourcesArray"];
	
	// *********** Update Send To popup menu
	
	NSString	*previousItem = [[[sendToPopup selectedItem] title] retain];
	
	[sendToPopup removeAllItems];
	
	if( sendToPopup)
	{
		serversArray = [[[DCMNetServiceDelegate DICOMServersList] mutableCopy] autorelease];
		
		NSString *ip = [NSString stringWithUTF8String:GetPrivateIP()];
		[sendToPopup addItemWithTitle: [NSString stringWithFormat: NSLocalizedString( @"This Computer - %@/%@:%d", nil), [NSUserDefaults defaultAETitle], ip, [NSUserDefaults defaultAEPort]]];

		[[sendToPopup menu] addItem: [NSMenuItem separatorItem]];
		
		for( NSUInteger i = 0; i < [serversArray count]; i++)
		{
			NSDictionary *server = [serversArray objectAtIndex: i];
			
			NSString *title = [NSString stringWithFormat:@"%@ - %@/%@:%@", [server valueForKey:@"Description"], [server valueForKey:@"AETitle"], [server valueForKey:@"Address"], [server valueForKey:@"Port"]];
			
			while( [sendToPopup indexOfItemWithTitle: title] != -1)
				title = [title stringByAppendingString: @" "];
			
			[sendToPopup addItemWithTitle: title];
			
			if( [title isEqualToString: previousItem]) [sendToPopup selectItemWithTitle: previousItem];
		}
	}
	
	[previousItem release];
}

- (NSArray*) prepareDICOMFieldsArrays
{
	DcmDictEntry* e = NULL;
	DcmDataDictionary& globalDataDict = dcmDataDict.wrlock();
	
	DcmDictEntryList list;
    DcmHashDictIterator iter(globalDataDict.normalBegin());
    for( int x = 0; x < globalDataDict.numberOfNormalTagEntries(); ++iter, x++)
    {
        if ((*iter)->getPrivateCreator() == NULL) // exclude private tags
        {
            e = new DcmDictEntry(*(*iter));
            list.insertAndReplace(e);
        }
    }
	
	NSMutableArray *array = [NSMutableArray array];
	
    /* output the list contents */
    DcmDictEntryListIterator listIter(list.begin());
    DcmDictEntryListIterator listLast(list.end());
    for (; listIter != listLast; ++listIter)
    {
		e = *listIter;
		
		if( e->getGroup() > 0)
		{
			CIADICOMField *dicomField = [[CIADICOMField alloc] initWithGroup:e->getGroup() element:e->getElement() name:[NSString stringWithFormat:@"%s",e->getTagName()]];
			[array addObject:dicomField];
			[dicomField release];
		}
    }
	
	dcmDataDict.unlock();
	
	return array;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
        if ([keyPath isEqualToString: @"values.KeepQRWindowOnTop"])
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepQRWindowOnTop"])
                [[self window] setLevel: NSFloatingWindowLevel];
            else
                [[self window] setLevel: NSNormalWindowLevel];
        }
        
        if( [keyPath isEqualToString: @"values.SERVERS"])
        {
            [self refreshSources];
        }
	}
}

- (id) initAutoQuery: (BOOL) autoQR
{
    if( self = [super initWithWindowNibName:@"Query"])
	{
		if( [[DCMNetServiceDelegate DICOMServersList] count] == 0)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Query & Retrieve",nil),NSLocalizedString( @"No DICOM locations available. See Preferences to add DICOM locations.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseAddNotification:) name:OsirixAddToDBNotification object:nil];
		
		queryFilters = nil;
		currentQueryKey = nil;
		autoQuery = autoQR;
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		queryFilters = [[NSMutableArray array] retain];
		resultArray = [[NSMutableArray array] retain];
		autoQueryLock = [[NSRecursiveLock alloc] init];
        performingQueryThreads = [[NSMutableSet alloc] init];
		
		if( autoQuery == NO)
			queryArrayPrefs = @"SavedQueryArray";
		else 
			queryArrayPrefs = @"SavedQueryArrayAuto";
		
		[queryArrayPrefs retain];
		
		sourcesArray = [[[NSUserDefaults standardUserDefaults] objectForKey: queryArrayPrefs] mutableCopy];
		if( sourcesArray == nil) sourcesArray = [[NSMutableArray array] retain];
		
		[self refreshSources];
		
		[[self window] setDelegate:self];
		
		if( autoQuery == NO)
		{
            self.window.toolbar = nil;
            
			[dateFilterMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"QRLastDateFilterValue"]];
			[self setDateQuery: dateFilterMatrix];
			
			currentQueryController = self;
			[[self window] setTitle: NSLocalizedString( @"DICOM Query/Retrieve", nil)];

			if( [[AppController sharedAppController] isStoreSCPRunning] == NO)
				NSRunCriticalAlertPanel(NSLocalizedString( @"DICOM Query & Retrieve",nil), NSLocalizedString( @"Retrieve cannot work if the DICOM Listener is not activated. See Preferences - Listener.",nil),NSLocalizedString( @"OK",nil), nil, nil);
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepQRWindowOnTop"])
                [[self window] setLevel: NSFloatingWindowLevel];
            
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"KeepQRWindowOnTop" options:NSKeyValueObservingOptionInitial context:NULL];
            
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"SERVERS" options:NSKeyValueObservingOptionInitial context:NULL];
		}
		else
		{
            [self view: self.window.contentView recursiveBindEnableToObject:self withKeyPath: @"isUnlocked"];
            
			[self setDateQuery: dateFilterMatrix];
			
			currentAutoQueryController = self;
			
            [self willChangeValueForKey: @"instancesMenuList"];
            
            autoQRInstances = [[[NSUserDefaults standardUserDefaults] objectForKey:@"savedAutoDICOMQuerySettingsArray"] mutableCopy];
            
            if( autoQRInstances == nil)
                autoQRInstances = [NSMutableArray new];
            
            // retro compatibility
            NSMutableDictionary *d = [[[[NSUserDefaults standardUserDefaults] objectForKey: @"savedAutoDICOMQuerySettings"] mutableCopy] autorelease];
            if( d)
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"savedAutoDICOMQuerySettings"];
                
                [d setObject: NSLocalizedString( @"Default Instance", nil) forKey: @"instanceName"];
                
                [autoQRInstances addObject: d];
                
                [[NSUserDefaults standardUserDefaults] setObject: autoQRInstances forKey: @"savedAutoDICOMQuerySettingsArray"];
            }
            
            currentAutoQR = -1;
            [self setCurrentAutoQR: 0];
            
            for( int i = 0; i < autoQRInstances.count; i++)
            {
                if( [[[autoQRInstances objectAtIndex: i] valueForKey: @"autoRefreshQueryResults"] intValue] >= 0)
                    autoQueryRemainingSecs[ i] = 60 * [[[autoQRInstances objectAtIndex: i] valueForKey: @"autoRefreshQueryResults"] intValue]; // minutes
                else
                    autoQueryRemainingSecs[ i] = -[[[autoQRInstances objectAtIndex: i] valueForKey: @"autoRefreshQueryResults"] intValue]; // seconds
            }
            [self didChangeValueForKey: @"instancesMenuList"];
		}
        
        DICOMFieldsArray = [[self prepareDICOMFieldsArrays] retain];
        
        NSMenu *DICOMFieldsMenu = [dicomFieldsMenu menu];
        [DICOMFieldsMenu setAutoenablesItems:NO];
        [dicomFieldsMenu removeAllItems];
        
        NSMenuItem *item;
        item = [[[NSMenuItem alloc] init] autorelease];
        for( int i = 0; i < [DICOMFieldsArray count]; i++)
        {
            item = [[[NSMenuItem alloc] init] autorelease];
            [item setTitle:[[DICOMFieldsArray objectAtIndex:i] title]];
            [item setRepresentedObject:[DICOMFieldsArray objectAtIndex:i]];
            [DICOMFieldsMenu addItem:item];
            
            if( [[DICOMFieldsArray objectAtIndex:i] element] == 0x0080 && [[DICOMFieldsArray objectAtIndex:i] group] == 0x0008)
                [dicomFieldsMenu selectItemWithTitle: [[DICOMFieldsArray objectAtIndex:i] title]];
        }
        [dicomFieldsMenu setMenu: DICOMFieldsMenu];
	}
    
    return self;
}

- (void)dealloc
{
	if( avoidQueryControllerDeallocReentry) // This can happen with the cancelPreviousPerformRequestsWithTarget calls
		return;
	
	avoidQueryControllerDeallocReentry = YES;

    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"SERVERS"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"KeepQRWindowOnTop"];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixAddToDBNotification object:nil];

	NSLog( @"dealloc QueryController");
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(executeRefresh:) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys];
	
	[autoQueryLock lock];
	[autoQueryLock unlock];
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: queryArrayPrefs];
	[pressedKeys release];
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	[queryManager release];
	[queryFilters release];
	[sourcesArray release];
	[resultArray release];
	[QueryTimer invalidate];
	[QueryTimer release];
    [performingQueryThreads release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[queryArrayPrefs release];
	
	[autoQueryLock release];
    
    [DICOMFieldsArray release];
	
    [autoQRInstances release];
    
	avoidQueryControllerDeallocReentry = NO;

    if( autoQuery == NO)
        currentQueryController = nil;
    else
        currentAutoQueryController = nil;
    
	[super dealloc];
}

- (void) windowDidBecomeKey:(NSNotification *)notification
{
	if( performingCFind)
		return;
		
	[outlineView reloadData];
}

- (void)windowDidLoad
{
	id searchCell = [searchFieldName cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];

	searchCell = [searchFieldAN cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
	searchCell = [searchFieldRefPhysician cell];
	
	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
	searchCell = [searchFieldStudyDescription cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];

	searchCell = [searchFieldComments cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
	searchCell = [searchFieldID cell];

	[[searchCell cancelButtonCell] setTarget:self];
	[[searchCell cancelButtonCell] setAction:@selector(clearQuery:)];
	
    // OutlineView View
    
    [outlineView setDelegate: self];
	[outlineView setTarget: self];
	[outlineView setDoubleAction:@selector(retrieveAndViewClick:)];
	ImageAndTextCell *cellName = [[[ImageAndTextCell alloc] init] autorelease];
	[[outlineView tableColumnWithIdentifier:@"name"] setDataCell:cellName];
	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Tools"] autorelease];
	NSMenuItem *item;
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Retrieve the images", nil) action: @selector(retrieve:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];

	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Retrieve and display the images", nil) action: @selector(retrieveAndView:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Query all studies of this patient", nil) action: @selector(querySelectedStudy:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete the local images", nil) action: @selector(deleteSelection:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	[outlineView setMenu: menu];
	
	//set up Query Keys
	currentQueryKey = PatientName;
	
//	dateQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"StudyDate"] retain];
//	timeQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"StudyTime"] retain];
    
//    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
//        modalityQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"ModalitiesinStudy"] retain];
//	else
//        modalityQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"Modality"] retain];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSources) name:@"DCMNetServicesDidChange"  object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(realtimeCFindResults:) name:@"realtimeCFindResults"  object:nil];
    
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"Button"];
	NSButtonCell *buttonCell = [[[NSButtonCell alloc] init] autorelease];
	[buttonCell setTarget: self];
	[buttonCell setAction: @selector(retrieveClick:)];
	[buttonCell setControlSize: NSMiniControlSize];
	[buttonCell setImage: [NSImage imageNamed:@"InArrow.tif"]];
	[buttonCell setBezelStyle: NSRoundRectBezelStyle]; // was NSRegularSquareBezelStyle
	[tableColumn setDataCell: buttonCell];
}

- (void) saveSettings
{
	if( autoQuery)
    {
        if( currentAutoQR >= 0 && autoQRInstances)
        {
            @synchronized( autoQRInstances)
            {
                NSMutableDictionary* newDic = [[autoQRInstances objectAtIndex: currentAutoQR] mutableCopy];
                [newDic addEntriesFromDictionary: [self savePresetInDictionaryWithDICOMNodes: YES]];
                
                if (newDic != nil)
                    [autoQRInstances replaceObjectAtIndex:currentAutoQR withObject:newDic];
                
                NSMutableArray *resultsArrays = [NSMutableArray array];
                
                for( NSMutableDictionary *instance in autoQRInstances)
                {
                    if( [instance objectForKey: @"resultArray"])
                        [resultsArrays addObject: [instance objectForKey: @"resultArray"]];
                    else
                        [resultsArrays addObject: [NSNull null]];
                    
                    [instance removeObjectForKey: @"resultArray"]; // We dont want to save the result array in the preferences
                }
                
                [[NSUserDefaults standardUserDefaults] setObject: [[autoQRInstances copy] autorelease] forKey: @"savedAutoDICOMQuerySettingsArray"];
                
                int i = 0;
                for( id r in resultsArrays)
                {
                    if( r != [NSNull null])
                        [[autoQRInstances objectAtIndex: i] setObject: r forKey: @"resultArray"];
                    i++;
                }
            }
        }
	}
    else
    {
		NSDictionary *settings = [self savePresetInDictionaryWithDICOMNodes: YES];
        
        [[NSUserDefaults standardUserDefaults] setObject: settings forKey: @"savedDICOMQuerySettings"];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self saveTableColumns];
    
	[[self window] setAcceptsMouseMovedEvents: NO];
	
    if( autoQuery)
        [[NSUserDefaults standardUserDefaults] setInteger: [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]] forKey: @"AutoQRPatientModeMatrixIndex"];
    else
    {
        [[NSUserDefaults standardUserDefaults] setInteger: [dateFilterMatrix selectedTag] forKey: @"QRLastDateFilterValue"];
        [[NSUserDefaults standardUserDefaults] setInteger: [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]] forKey: @"QRPatientModeMatrixIndex"];
    }
    
	[[NSUserDefaults standardUserDefaults] setObject: sourcesArray forKey: queryArrayPrefs];
	
	[self saveSettings];
	
	[[self window] orderOut: self];
}

- (int) dicomEcho:(NSDictionary*) aServer
{
	int status = 0;
	
	NSString *theirAET;
	NSString *hostname;
	NSString *port;
	
	theirAET = [aServer objectForKey:@"AETitle"];
	hostname = [aServer objectForKey:@"Address"];
	port = [aServer objectForKey:@"Port"];
	
	status = [QueryController echoServer:aServer];
	
	return status;
}

- (IBAction) verify:(id)sender
{
//	int selectedRow = [sourcesTable selectedRow];
//    
//    [NSThread detachNewThreadSelector: @selector( queryTest:) toTarget: [QueryController class] withObject: [[sourcesArray objectAtIndex: selectedRow] valueForKey:@"server"]];
//    
    
	int status, selectedRow = [sourcesTable selectedRow];

	[progressIndicator startAnimation:nil];

	[self willChangeValueForKey:@"sourcesArray"];
	
	for( NSUInteger i = 0 ; i < [sourcesArray count]; i++)
	{
		[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
		[sourcesTable scrollRowToVisible: i];
		
		NSMutableDictionary *aServer = [sourcesArray objectAtIndex: i];
		
		switch( [self dicomEcho: [aServer objectForKey:@"server"]])
		{
            default:
			case 1:		status = 0;			break;
			case 0:		status = -1;		break;
			case -1:	status = -2;		break;
		}
		
		[aServer setObject:[NSNumber numberWithInt: status] forKey:@"test"];
	}
	
	[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow] byExtendingSelection: NO];
	
	[self didChangeValueForKey:@"sourcesArray"];
	
	[progressIndicator stopAnimation:nil];
}

- (IBAction) pressButtons:(id) sender
{
	switch( [sender selectedSegment])
	{
		case 0:		// Query
			[self query: sender];
		break;
		
		case 2:		// Retrieve
			[self retrieve: sender];
		break;
		
		case 3:		// Verify
			[self verify: sender];
		break;
		
		case 1:		// Query Selected Patient
			[self querySelectedStudy: self];
		break;
	}
}

-(void)observeDatabaseAddNotification:(NSNotification*)notification
{
	[self performSelectorOnMainThread:@selector(refresh:) withObject:self waitUntilDone:NO];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    if( [[splitView subviews] objectAtIndex: 0] == subview)
        return NO;
       
    return YES;  
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
    if( dividerIndex == 0)
        return 100;
    
    return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    if( dividerIndex == 0)
        return [splitView bounds].size.height-150;
    
    return proposedMax;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return YES;
}

-(BOOL)isUnlocked
{
	return ([authView authorizationState] == SFAuthorizationViewUnlockedState);
}

-(void)authorizationViewDidAuthorize:(SFAuthorizationView*)view
{
    [self willChangeValueForKey:@"isUnlocked"];
    [self didChangeValueForKey:@"isUnlocked"];
    
    [authButton setImage: [NSImage imageNamed: [self isUnlocked]? @"NSLockUnlockedTemplate" : @"NSLockLockedTemplate"]];
}

-(void)authorizationViewDidDeauthorize:(SFAuthorizationView*)view
{    
    [self willChangeValueForKey:@"isUnlocked"];
    [self didChangeValueForKey:@"isUnlocked"];
    
    [authButton setImage: [NSImage imageNamed: [self isUnlocked]? @"NSLockUnlockedTemplate" : @"NSLockLockedTemplate"]];
}

-(IBAction)authAction:(id)sender
{
	[authView buttonPressed: NULL];
}

-(void)view:(NSView*)view recursiveBindEnableToObject:(id)obj withKeyPath:(NSString*)keyPath
{
	if ([view isKindOfClass:[NSControl class]])
    {
		NSUInteger bki = 0;
		NSString* bk = NULL;
		BOOL doBind = YES;
		
		while (doBind)
        {
			++bki;
			bk = [NSString stringWithFormat:@"enabled%@", bki==1? @"" : [NSString stringWithFormat:@"%d", (int) bki]];
            
			NSDictionary* b = [view infoForBinding:bk];
			if (!b) break;
			
			if ([b objectForKey:NSObservedObjectKey] == obj && [[b objectForKey:NSObservedKeyPathKey] isEqualToString:keyPath])
				doBind = NO; // already bound
		}
		
		if (doBind)
			@try
            {
				[view bind:bk toObject:obj withKeyPath:keyPath options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSConditionallySetsEnabledBindingOption]];
				return;
			}
            @catch (NSException* e)
            {
				NSLog(@"Warning: %@", e.description);
			}
	}
	
	for (NSView* subview in view.subviews)
		[self view:subview recursiveBindEnableToObject:obj withKeyPath:keyPath];
    
    if( [view isKindOfClass: [NSTabView class]])
    {
        for (NSTabViewItem* tabItem in [(NSTabView*) view tabViewItems])
            [self view: tabItem.view  recursiveBindEnableToObject:obj withKeyPath:keyPath];
    }
}
@end
