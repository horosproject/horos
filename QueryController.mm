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

#import "QueryController.h"
#import "WaitRendering.h"
#import "QueryFilter.h"
#import "AdvancedQuerySubview.h"
#import "AppController.h"
#import "ImageAndTextCell.h"
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import "QueryArrayController.h"
#import "AdvancedQuerySubview.h"
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

#include "osconfig.h"
#include "mdfconen.h"

#include "dcvrsl.h"
#include "ofcast.h"
#include "ofstd.h"
#include "dctk.h"
#include "dcuid.h"

#define INCLUDE_CSTDIO
#include "ofstdinc.h"

static NSString *PatientName = @"PatientsName";
static NSString *PatientID = @"PatientID";
static NSString *AccessionNumber = @"AccessionNumber";
static NSString *StudyDescription = @"StudyDescription";
static NSString *Comments = @"Comments";
static NSString *PatientBirthDate = @"PatientBirthDate";
static NSString *ReferringPhysician = @"ReferringPhysiciansName";
static NSString *InstitutionName = @"InstitutionName";

static QueryController *currentQueryController = nil;
static QueryController *currentAutoQueryController = nil;
static NSMutableArray *studyArrayInstanceUID = [[NSMutableArray alloc] init], *studyArrayID = [[NSMutableArray alloc] init];
static NSString *kStudyArrayInstanceUIDLock = @"studyArrayInstanceUIDLock";
static NSString *kComputeStudyArrayInstanceUIDLock = @"computeStudyArrayInstanceUID";
static BOOL afterDelayRefresh = NO;

static int inc = 0;

extern "C"
{
	extern const char *GetPrivateIP();
};

@implementation QueryController

@synthesize autoQuery, autoQueryLock, outlineView, DatabaseIsEdited;

+ (void) queryTest: (NSDictionary*) aServer
{
    NSMutableDictionary *months = [NSMutableDictionary dictionary];
    
    for( int i = 0 ; i < 12; i++)
        [months setObject: [NSMutableDictionary dictionary] forKey: [NSString stringWithFormat: @"%d", i+1]];
    
    QueryArrayController *qm = nil;
	NSArray *array = nil;
	
    NSCalendarDate *date = [NSCalendarDate dateWithYear: 2011 month: 1 day: 1 hour: 0 minute: 0 second: 1 timeZone: nil];
    
    for( int i = 0; i < 365; i++)
    {
        [NSThread sleepForTimeInterval: 0.1];
        
        BOOL succeed = NO;
        while( succeed == NO)
        {
            @try
            {
                qm = [[[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer] autorelease];
                
                NSCalendarDate *endDate = [date dateByAddingYears: 0 months: 0 days: 1 hours: 0 minutes: 0 seconds: 0];
                
                NSString *timeString = [[DCMCalendarDate dicomDateWithDate: date] dateString];
                
                [qm addFilter: @"CT\\US" forDescription: @"ModalitiesinStudy"];
                [qm addFilter: [NSString stringWithFormat: @"%@-%@", [[DCMCalendarDate dicomDateWithDate: date] dateString], [[DCMCalendarDate dicomDateWithDate: endDate] dateString]] forDescription:@"StudyDate"];
                [qm addFilter: [NSString stringWithString: @"230000.000-070000.000"] forDescription:@"StudyTime"];
                //[qm addFilter: [NSString stringWithFormat: @"%@-%@", [[DCMCalendarDate dicomDateWithDate: date] dateString], [[DCMCalendarDate dicomDateWithDate: date] dateString]] forDescription:@"StudyDate"];
                //[qm addFilter: [NSString stringWithString: @"190000.000-230000.000"] forDescription:@"StudyTime"];
                
                [qm performQuery: NO];
                
                array = [qm queries];
                
                NSString *month = [NSString stringWithFormat: @"%d", [date monthOfYear]];
                NSMutableDictionary *dict = [months objectForKey: month];
                
                for( id a in array)
                {
                    if( [[a valueForKey: @"modality"] isEqualToString: @"US"])
                        [dict setObject: [NSNumber numberWithInt: [[dict objectForKey: @"US"] intValue] + 1] forKey: @"US"];
                    
                    if( [[a valueForKey: @"modality"] isEqualToString: @"CT"])
                        [dict setObject: [NSNumber numberWithInt: [[dict objectForKey: @"CT"] intValue] + 1] forKey: @"CT"];
                }
                
                succeed = YES;
            }
            @catch (NSException * e)
            {
                NSLog( @"%@",  [e description]);
            }
        }
        
        date = [date dateByAddingYears: 0 months: 0 days: 1 hours: 0 minutes: 0 seconds: 0];
        
        NSLog( @"%@", date);
    }
    
    for( int i = 1 ; i <= 12; i++)
    {
        NSLog( @"%d", i);
        NSLog( @"%@", [months objectForKey: [NSString stringWithFormat: @"%d", i]]);
    }
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
		
		NSString *uniqueStringID = [NSString stringWithFormat:@"%d.%d.%d", getpid(), inc++, random()];	
		
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
				[args addObject:TLS_PRIVATE_KEY_PASSWORD];
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
		[theTask waitUntilExit];
		
		if([[serverParameters objectForKey:@"TLSEnabled"] boolValue])
		{
			//[DDKeychain unlockTmpFiles];
			[[NSFileManager defaultManager] removeFileAtPath:[DICOMTLS keyPathForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID] handler:nil];
			[[NSFileManager defaultManager] removeFileAtPath:[DICOMTLS certificatePathForServerAddress:address port:[port intValue] AETitle:aet withStringID:uniqueStringID] handler:nil];
			[[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithFormat:@"%@%@", TLS_TRUSTED_CERTIFICATES_DIR, uniqueStringID] handler:nil];		
		}
		
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
	
	if( result != NSRunStoppedResponse)
	{
		[[NSUserDefaults standardUserDefaults] setObject: NumberOfPreviousStudyToRetrieve forKey: @"NumberOfPreviousStudyToRetrieve"];
		[[NSUserDefaults standardUserDefaults] setObject: retrieveSameModality forKey: @"retrieveSameModality"];
		[[NSUserDefaults standardUserDefaults] setObject: retrieveSameDescription forKey: @"retrieveSameDescription"];
	}
}

- (IBAction) switchAutoRetrieving: (id) sender
{
	NSLog( @"auto-retrieving switched");
	
	@synchronized( previousAutoRetrieve)
	{
		[previousAutoRetrieve removeAllObjects];
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"autoRetrieving"]  && autoQuery == YES)
	{
		[self refreshAutoQR: self];
//		if( [autoQueryLock tryLock])
//		{
//			[self autoQueryThread];
//			[autoQueryLock unlock];
//		}
	}
}

- (NSDictionary*) savePresetInDictionaryWithDICOMNodes: (BOOL) includeDICOMNodes
{
	NSMutableDictionary *presets = [NSMutableDictionary dictionary];
	
	if( includeDICOMNodes)
	{
		NSMutableArray *srcArray = [NSMutableArray array];
		for( id src in sourcesArray)
		{
			if( [[src valueForKey: @"activated"] boolValue] == YES)
				[srcArray addObject: [src valueForKey: @"AddressAndPort"]];
		}
		
		if( [srcArray count] == 0 && [sourcesTable selectedRow] >= 0)
			[srcArray addObject: [[sourcesArray objectAtIndex: [sourcesTable selectedRow]] valueForKey: @"AddressAndPort"]];
		
		[presets setValue: srcArray forKey: @"DICOMNodes"];
	}
	
	[presets setValue: [searchFieldName stringValue] forKey: @"searchFieldName"];
	[presets setValue: [searchFieldRefPhysician stringValue] forKey: @"searchFieldRefPhysician"];
	[presets setValue: [searchFieldID stringValue] forKey: @"searchFieldID"];
	[presets setValue: [searchFieldAN stringValue] forKey: @"searchFieldAN"];
	[presets setValue: [searchFieldStudyDescription stringValue] forKey: @"searchFieldStudyDescription"];
	[presets setValue: [searchFieldComments stringValue] forKey: @"searchFieldComments"];
    [presets setValue: [searchCustomField stringValue] forKey: @"searchCustomField"];
    [presets setValue: [[dicomFieldsMenu selectedItem] title] forKey: @"searchCustomFieldDICOM"];
	
	[presets setValue: [NSNumber numberWithInt: [dateFilterMatrix selectedTag]] forKey: @"dateFilterMatrix"];
	[presets setValue: [NSNumber numberWithInt: [birthdateFilterMatrix selectedTag]] forKey: @"birthdateFilterMatrix"];
	
	NSMutableString *cellsString = [NSMutableString string];
	for( NSCell *cell in [modalityFilterMatrix cells])
	{
		if( [cell state] == NSOnState)
		{
			NSInteger row, col;
			
			[modalityFilterMatrix getRow: &row column: &col ofCell:cell];
			[cellsString appendString: [NSString stringWithFormat:@"%d %d ", row, col]];
		}
	}
	[presets setValue: cellsString forKey: @"modalityFilterMatrixString"];
	
	[presets setValue: [NSNumber numberWithInt: [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]]] forKey: @"PatientModeMatrix"];
	
	[presets setValue: [NSNumber numberWithDouble: [[fromDate dateValue] timeIntervalSinceReferenceDate]] forKey: @"fromDate"];
	[presets setValue: [NSNumber numberWithDouble: [[toDate dateValue] timeIntervalSinceReferenceDate]] forKey: @"toDate"];
	[presets setValue: [NSNumber numberWithDouble: [[searchBirth dateValue] timeIntervalSinceReferenceDate]] forKey: @"searchBirth"];
	
	[presets setValue: [NSNumber numberWithInt: self.autoRefreshQueryResults] forKey: @"autoRefreshQueryResults"];

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
	[NSApp beginSheet: presetWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) emptyPreset:(id) sender
{
	[searchFieldRefPhysician setStringValue: @""];
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
		
		if( [r count])
		{
			[self willChangeValueForKey:@"sourcesArray"];
			
			for( id src in sourcesArray)
			{
				[src setValue: [NSNumber numberWithBool: NO] forKey: @"activated"];
			}
			
			if( [r count] == 1)
			{
				for( id src in sourcesArray)
				{
					if( [[src valueForKey: @"AddressAndPort"] isEqualToString: [r lastObject]])
					{
						[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [sourcesArray indexOfObject: src]] byExtendingSelection: NO];
						[sourcesTable scrollRowToVisible: [sourcesArray indexOfObject: src]];
					}
				}
			}
			else
			{
				BOOL first = YES;
				
				for( id v in r)
				{
					for( id src in sourcesArray)
					{
						if( [[src valueForKey: @"AddressAndPort"] isEqualToString: v])
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
			}
			
			[self didChangeValueForKey:@"sourcesArray"];
		}
	}
	
	if( [presets valueForKey: @"autoRefreshQueryResults"])
	{
		self.autoRefreshQueryResults = [[presets valueForKey:@"autoRefreshQueryResults"] intValue];
	}
	
	if( [presets valueForKey: @"searchFieldRefPhysician"])
		[searchFieldRefPhysician setStringValue: [presets valueForKey: @"searchFieldRefPhysician"]];
	
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
	
	if( [presets valueForKey: @"modalityFilterMatrixRow"] && [presets valueForKey: @"modalityFilterMatrixColumn"])
		[modalityFilterMatrix selectCellAtRow: [[presets valueForKey: @"modalityFilterMatrixRow"] intValue]  column:[[presets valueForKey: @"modalityFilterMatrixColumn"] intValue]];
	else
	{
		NSString *s = [presets valueForKey: @"modalityFilterMatrixString"];
		
		NSScanner *scan = [NSScanner scannerWithString: s];
		
		BOOL more;
		do
		{
			NSInteger row, col;
			
			more = [scan scanInteger: &row];
			more = [scan scanInteger: &col];
			
			if( more)
				[modalityFilterMatrix selectCellAtRow: row column: col];
			
		}
		while( more);
	}
	
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
}

- (void) applyPreset:(id) sender
{
	if([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
	{
		// Delete the Preset
		if (NSRunCriticalAlertPanel( NSLocalizedString(@"Delete Preset", nil),  NSLocalizedString(@"Are you sure you want to delete the selected Preset?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
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
	
	[menu addItemWithTitle: NSLocalizedString( @"Empty Preset", nil) action:@selector( emptyPreset:) keyEquivalent:@""];
	[menu addItem: [NSMenuItem separatorItem]];
	
	if( [savedPresets count] == 0)
	{
		[[menu addItemWithTitle: NSLocalizedString( @"No Presets Saved", nil) action:nil keyEquivalent: @""] setEnabled: NO];
	}
	else
	{
		for( NSString *key in [[savedPresets allKeys] sortedArrayUsingSelector: @selector( compare:)])
		{
			[menu addItemWithTitle: key action:@selector( applyPreset:) keyEquivalent: @""];
		}
	}
	
	[menu addItem: [NSMenuItem separatorItem]];
	[menu addItemWithTitle: NSLocalizedString( @"Add current settings as a new Preset", nil) action:@selector( addPreset:) keyEquivalent:@""];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	BOOL valid = NO;
	
    if ([item action] == @selector( deleteSelection:))
	{
		[[BrowserController currentBrowser] setDatabase:[DicomDatabase activeLocalDatabase]];
        [[BrowserController currentBrowser] showEntireDatabase];
	
		NSIndexSet* indices = [outlineView selectedRowIndexes];
		
		for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
		{
			if( [indices containsIndex: i])
			{
				NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i]];

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
    NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), NSLocalizedString(@"Are you sure you want to delete the selected images?", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
    
    if( result == NSAlertDefaultReturn)
    {
        [[BrowserController currentBrowser] setDatabase:[DicomDatabase activeLocalDatabase]];
        [[BrowserController currentBrowser] showEntireDatabase];
        
        NSIndexSet* indices = [outlineView selectedRowIndexes];
        BOOL extendingSelection = NO;
        
     //   [[[DicomDatabase activeLocalDatabase] managedObjectContext] lock];
        
        @try 
        {
            for( NSUInteger i = [indices firstIndex]; i != [indices lastIndex]+1; i++)
            {
                if( [indices containsIndex: i])
                {
                    NSArray *studyArray = [self localStudy: [outlineView itemAtRow: i]];
                    
                    if( [studyArray count] > 0)
                    {
                        NSManagedObject	*series =  [[[BrowserController currentBrowser] childrenArray: [studyArray objectAtIndex: 0] onlyImages: NO] objectAtIndex:0];
                        [[BrowserController currentBrowser] findAndSelectFile:nil image:[[series valueForKey:@"images"] anyObject] shouldExpand:NO extendingSelection: extendingSelection];
                        extendingSelection = YES;
                    }
                    else NSBeep();
                } 
            }

            if( extendingSelection)
            {
                [[BrowserController currentBrowser] delItem: nil];
            }
        }
        @catch (NSException * e) 
        {
            N2LogExceptionWithStackTrace(e);
        }
        
    //    [[[DicomDatabase activeLocalDatabase] managedObjectContext] unlock];
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
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector( executeRefresh:) object:nil];
		
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
	autoQueryRemainingSecs = 1;
	[self autoQueryTimerFunction: QueryTimer]; 
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	@try
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
			return [[(DCMTKQueryNode *)item children] objectAtIndex:index];
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
		if( [[tableColumn identifier] isEqualToString:@"comment"])
		{
			DatabaseIsEdited = YES;
			return YES;
		}
		else
		{
			DatabaseIsEdited = NO;
			return NO;
		}
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
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
	
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	@try
	{
		if( item)
		{
			if (![(DCMTKQueryNode *)item children])
			{
				@synchronized( self)
				{
					if( performingCFind == NO)
					{
						performingCFind = YES; // to avoid re-entries during WaitRendering window, and separate thread for cFind
						
						[progressIndicator startAnimation:nil];
						[item queryWithValues:nil];
						[progressIndicator stopAnimation:nil];
						performingCFind = NO;
					}
				}
			}
		}
		return  (item == nil) ? [resultArray count] : [[(DCMTKQueryNode *) item children] count];
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return [resultArray count];
}

- (NSArray*) localSeries:(id) item
{
	NSArray *seriesArray = nil;
	NSManagedObject *study = [[self localStudy: [outlineView parentForItem: item]] lastObject];
	
	if( study == nil) return seriesArray;
	
	if( [item isMemberOfClass:[DCMTKSeriesQueryNode class]] == YES)
	{
		NSManagedObjectContext *context = [[DicomDatabase activeLocalDatabase] managedObjectContext];
		
		[context lock];
		
		@try
		{
			seriesArray = [[[study valueForKey:@"series"] allObjects] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"(seriesDICOMUID == %@)", [item valueForKey:@"uid"]]];
		}
		@catch (NSException * e)
		{
            N2LogExceptionWithStackTrace(e);
		}
		
		[context unlock];
	}
	else
		NSLog( @"Warning! Not a series class !");
	
	return seriesArray;
}

- (void) applyNewStudyArray: (NSDictionary *) d
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *local_studyArrayID = nil;
	NSArray *local_studyArrayInstanceUID = nil;
	
    @synchronized( kComputeStudyArrayInstanceUIDLock)
    {
        @try
        {
            NSManagedObjectContext *independentContext = [[[BrowserController currentBrowser] database] independentContext];
            
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
            
            if( local_studyArrayID && local_studyArrayInstanceUID)
            {
                @synchronized (studyArrayInstanceUID)
                {
                    [studyArrayInstanceUID removeAllObjects];
                    [studyArrayInstanceUID addObjectsFromArray: local_studyArrayInstanceUID];
                
                    [studyArrayID removeAllObjects];
                    [studyArrayID addObjectsFromArray: local_studyArrayID];
                }
                
                if( [NSThread isMainThread])
                    [self applyNewStudyArray: nil];
                else
                    [self performSelectorOnMainThread:@selector(applyNewStudyArray:) withObject: nil waitUntilDone: NO];
            }
            else
                NSLog( @"******** computeStudyArrayInstanceUID FAILED...");
        }
        @catch (NSException * e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
    }
	
	afterDelayRefresh = NO;
	
	[pool release];
}

- (NSArray*) localStudy:(id) item
{
	if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
	{
		@try
		{
			NSArray *result = nil;
			
            @synchronized (studyArrayInstanceUID)
            {
                if (studyArrayInstanceUID.count == 0)
                    [self computeStudyArrayInstanceUID: nil];

                NSUInteger index = [studyArrayInstanceUID indexOfObject:[item valueForKey: @"uid"]];
                
                if( index == NSNotFound) result = [NSArray array];
                else
                {
                    result = [NSArray arrayWithObject: [[[BrowserController currentBrowser] database] objectWithID: [studyArrayID objectAtIndex: index]]];
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
				
				studyArray = [self localStudy: item];
				
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
				
				seriesArray = [self localSeries: item];
				
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

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	@try
	{
		if( [[tableColumn identifier] isEqualToString: @"name"])	// Is this study already available in our local database?
		{
			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
			{
				NSArray	*studyArray = [self localStudy: item];
				
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
				
				seriesArray = [self localSeries: item];
				
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
	@try
	{
		if( [[tableColumn identifier] isEqualToString: @"stateText"])
		{
			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
			{
				NSArray *studyArray = [self localStudy: item];
				
				if( [studyArray count] > 0)
				{
					if( [[[studyArray objectAtIndex: 0] valueForKey:@"stateText"] intValue] == 0)
						return nil;
					else
						return [[studyArray objectAtIndex: 0] valueForKey: @"stateText"];
				}
			}
			else
			{
				NSArray *seriesArray = [self localSeries: item];
				if( [seriesArray count])
				{
					if( [[[seriesArray objectAtIndex: 0] valueForKey:@"stateText"] intValue] == 0)
						return nil;
					else
						return [[seriesArray objectAtIndex: 0] valueForKey: @"stateText"];
				}
			}
		}
		else if( [[tableColumn identifier] isEqualToString: @"comment"])
		{
			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
			{
				NSArray *studyArray = [self localStudy: item];
				
				if( [studyArray count] > 0 && [[item valueForKey: @"comments"] length] == 0)
					return [[studyArray objectAtIndex: 0] valueForKey: @"comment"];
				else
					return [item valueForKey: @"comments"];
			}
			else
			{
				NSArray *seriesArray = [self localSeries: item];
				if( [seriesArray count] > 0 && [[item valueForKey: @"comments"] length] == 0)
					return [[seriesArray objectAtIndex: 0] valueForKey: @"comment"];
				else
					return [item valueForKey: @"comments"];
			}
		}
		else if ( [[tableColumn identifier] isEqualToString: @"Button"] == NO && [tableColumn identifier] != nil)
		{
			if( [[tableColumn identifier] isEqualToString: @"numberImages"])
			{
				return [NSNumber numberWithInt: [[item valueForKey: [tableColumn identifier]] intValue]];
			}
			else return [item valueForKey: [tableColumn identifier]];		
		}	
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return nil;
}

- (void)outlineView:(NSOutlineView *) o setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSArray *array;
	
	@try
	{
		if( [[tableColumn identifier] isEqualToString: @"comment"] || [[tableColumn identifier] isEqualToString: @"stateText"])
		{
			if( [item isMemberOfClass:[DCMTKStudyQueryNode class]] == YES)
				array = [self localStudy: item];
			else
				array = [self localSeries: item];
			
			if( [array count] > 0)
			{
                [[BrowserController currentBrowser] setDatabase:[DicomDatabase activeLocalDatabase]];
				[[BrowserController currentBrowser] setDatabaseValue: object item: [array objectAtIndex: 0] forKey: [tableColumn identifier]];
			}
			else NSRunCriticalAlertPanel( NSLocalizedString(@"Study not available", nil), NSLocalizedString(@"The study is not available in the local Database, you cannot modify or set the comments/status fields.", nil), NSLocalizedString(@"OK", nil), nil, nil) ;
		}
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	DatabaseIsEdited = NO;
	[outlineView reloadData];
}

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
//	NSInteger PatientModeMatrixSelected = [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]];
//	NSInteger dateFilterMatrixSelected = [dateFilterMatrix selectedTag];
//	NSMutableArray *selectedModalities = [NSMutableArray array];
//	for( NSCell *c in [modalityFilterMatrix cells]) if( [c state] == NSOnState) [selectedModalities addObject: c];
//	NSString *copySearchField = [NSString stringWithString: [searchFieldID stringValue]];
	
	[PatientModeMatrix selectTabViewItemAtIndex: 1];	// PatientID search
	
	[dateFilterMatrix selectCellWithTag: 0];
	[self setDateQuery: dateFilterMatrix];
	[modalityFilterMatrix deselectAllCells];
	[self setModalityQuery: modalityFilterMatrix];
	[searchFieldID setStringValue: ID];
	
	[self query: self];
	
	NSArray *result = [NSArray arrayWithArray: resultArray];
	
//	[PatientModeMatrix selectTabViewItemAtIndex: PatientModeMatrixSelected];
//	[dateFilterMatrix selectCellWithTag: dateFilterMatrixSelected];
//	for( NSCell *c in selectedModalities) [modalityFilterMatrix selectCell: c];
//	[searchFieldID setStringValue: copySearchField];
	
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

- (int) array: uidArray containsObject: (NSString*) uid
{
	BOOL result = NO;
	
	for( NSUInteger x = 0 ; x < [uidArray count]; x++)
	{
		if( [[uidArray objectAtIndex: x] isEqualToString: uid]) return x;
	}
	
	return -1;
}

- (NSArray*) queryPatientIDwithoutGUI: (NSString*) patientID
{
	NSString			*theirAET;
	NSString			*hostname;
	NSString			*port;
	id					aServer;
	int					selectedServer;
	BOOL				atLeastOneSource = NO, noChecked = YES, error = NO;
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
                        int index = [self array: uidArray containsObject: [[curResult objectAtIndex: x] valueForKey:@"uid"]];
                        
                        if( index == -1) // not found
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
                
                if( [temporaryCFindResultArray count])
                    [temporaryCFindResultArray sortUsingDescriptors: [self sortArray]];
                
                [self performSelectorOnMainThread:@selector( refreshList:) withObject: temporaryCFindResultArray waitUntilDone: NO];
            }
            
            lastTemporaryCFindResultUpdate = [[NSDate date] timeIntervalSinceReferenceDate];
        }
    }
}

-(BOOL) queryWithDisplayingErrors:(BOOL) showError
{
	NSString			*theirAET;
	NSString			*hostname;
	NSString			*port;
	NSNetService		*netService = nil;
	id					aServer;
	int					selectedServer;
	BOOL				atLeastOneSource = NO, noChecked = YES, error = NO;
	NSMutableArray		*tempResultArray = [NSMutableArray array];
    
    [temporaryCFindResultArray release];
    temporaryCFindResultArray = nil;
    if( [NSThread isMainThread])
        temporaryCFindResultArray = [[NSMutableArray array] retain];
    
	[autoQueryLock lock];
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: queryArrayPrefs];
	
	@try 
	{
		noChecked = YES;
		for( NSUInteger i = 0; i < [sourcesArray count]; i++)
		{
			if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES)
				noChecked = NO;
		}
		
		selectedServer = -1;
		if( noChecked)
			selectedServer = [sourcesTable selectedRow];
		
		atLeastOneSource = NO;
		firstServerRealtimeResults = YES;
		
        if( [NSThread isMainThread])
            [self performSelectorOnMainThread:@selector( refreshList:) withObject: [NSArray array] waitUntilDone: NO]; // Clean the list
        
		for( NSUInteger i = 0; i < [sourcesArray count]; i++)
		{
			if( [[[sourcesArray objectAtIndex: i] valueForKey:@"activated"] boolValue] == YES || selectedServer == i)
			{
				aServer = [[sourcesArray objectAtIndex:i] valueForKey:@"server"];
				
				if( showError)
					[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
				
				theirAET = [aServer objectForKey:@"AETitle"];
				hostname = [aServer objectForKey:@"Address"];
				port = [aServer objectForKey:@"Port"];
				
				{
					[self setDateQuery: dateFilterMatrix];
					[self setModalityQuery: modalityFilterMatrix];
					
					[queryManager release];
					queryManager = nil;

					queryManager = [[QueryArrayController alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] distantServer:aServer];
					// add filters as needed
					
					if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] isEqualToString:@"ISO_IR 100"] == NO)
						//Specific Character Set
						[queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
					
                    BOOL queryAllFields = NO;
                    
                    if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask)
                    {
                        NSLog( @"--- Query ALL fields");
                        queryAllFields = YES;
                    }
                    
                    int fromField = [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]];
                    int toField = [PatientModeMatrix indexOfTabViewItem: [PatientModeMatrix selectedTabViewItem]];
                    
                    if( queryAllFields)
                    {
                        fromField = 0;
                        toField = [PatientModeMatrix numberOfTabViewItems];
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
                            case 6:		currentQueryKey = Comments;             break;
                            case 7:		currentQueryKey = InstitutionName;      break;
                            case 8:     currentQueryKey = customDICOMField;     break;
                        }
                        
                        if( currentQueryKey == customDICOMField && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_custom_dicom_field"])
                        {
                            CIADICOMField *dicomField = [[dicomFieldsMenu selectedItem] representedObject];
                            
                            DcmTag tag( [dicomField group], [dicomField element]);
                            
                            currentQueryKey = [NSString stringWithCString: tag.getTagName()];
                            
                            NSLog( @"DICOM Q&R with custom field: %@ : %@", currentQueryKey, [searchCustomField stringValue]);
                            
                            if( showError && [[searchCustomField stringValue] cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                            {
                                if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                                {
                                    [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                                    [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                                }
                            }
                            
                            NSString *filterValue = [[searchCustomField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                            if ([filterValue length] > 0)
                            {
                                if( tag.getVR().isaString())
                                    filterValue = [filterValue stringByAppendingString:@"*"];
                                
                                [queryManager addFilter: filterValue forDescription: currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == PatientName && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_name"])
                        {
                            if( showError && [[searchFieldName stringValue] cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                            {
                                if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                                {
                                    [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                                    [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                                }
                            }
                            
                            if( [[searchFieldName stringValue] length] >= 64)
                                [searchFieldName setStringValue: [[searchFieldName stringValue] substringToIndex: 64]];
                            
                            NSString *filterValue = [[searchFieldName stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == ReferringPhysician && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_referring_physician"])
                        {
                            if( showError && [[searchFieldRefPhysician stringValue] cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                            {
                                if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                                {
                                    [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                                    [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                                }
                            }
                            
                            NSString *filterValue = [[searchFieldRefPhysician stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == InstitutionName && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_institution"])
                        {
                            if( showError && [[searchInstitutionName stringValue] cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                            {
                                if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                                {
                                    [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                                    [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                                }
                            }
                            
                            NSString *filterValue = [[searchInstitutionName stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter:[filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == PatientBirthDate && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_birthdate"])
                        {
                            if( [birthdateFilterMatrix selectedTag] == 0)
                                [queryManager addFilter: [[searchBirth dateValue] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] forDescription:currentQueryKey];
                            
                            if( [birthdateFilterMatrix selectedTag] == -1)
                                [queryManager addFilter: [[searchBirth dateValue] descriptionWithCalendarFormat:@"-%Y%m%d" timeZone:nil locale:nil] forDescription:currentQueryKey];
                            
                            if( [birthdateFilterMatrix selectedTag] == 1)
                                [queryManager addFilter: [[searchBirth dateValue] descriptionWithCalendarFormat:@"%Y%m%d-" timeZone:nil locale:nil] forDescription:currentQueryKey];
                            
                            queryItem = YES;
                        }
                        else if( currentQueryKey == PatientID && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_id"])
                        {
                            NSString *filterValue = [[searchFieldID stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter:filterValue forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == AccessionNumber && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_accession_number"])
                        {
                            NSString *filterValue = [[searchFieldAN stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter:filterValue forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == StudyDescription && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_description"])
                        {
                            if( showError && [[searchFieldStudyDescription stringValue] cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                            {
                                if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                                {
                                    [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                                    [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                                }
                            }
                            
                            NSString *filterValue = [searchFieldStudyDescription stringValue];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter: [filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                        else if( currentQueryKey == Comments && [[NSUserDefaults standardUserDefaults] boolForKey: @"allow_qr_comments"])
                        {
                            if( showError && [[searchFieldComments stringValue] cStringUsingEncoding: [NSString encodingForDICOMCharacterSet: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"]]] == nil)
                            {
                                if (NSRunCriticalAlertPanel( NSLocalizedString(@"Query Encoding", nil),  NSLocalizedString(@"The query cannot be encoded in current character set. Should I switch to UTF-8 (ISO_IR 192) encoding?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                                {
                                    [[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 192" forKey: @"STRINGENCODING"];
                                    [queryManager addFilter: [[NSUserDefaults standardUserDefaults] stringForKey: @"STRINGENCODING"] forDescription:@"SpecificCharacterSet"];
                                }
                            }
                            
                            NSString *filterValue = [searchFieldComments stringValue];
                            
                            if ([filterValue length] > 0)
                            {
                                [queryManager addFilter: [filterValue stringByAppendingString:@"*"] forDescription:currentQueryKey];
                                queryItem = YES;
                            }
                        }
                    }
                    
					if ([dateQueryFilter object])
					{
						[queryManager addFilter:[dateQueryFilter filteredValue] forDescription:@"StudyDate"];
						queryItem = YES;
					}
					
					if ([timeQueryFilter object])
					{
						[queryManager addFilter:[timeQueryFilter filteredValue] forDescription:@"StudyTime"];
						queryItem = YES;
					}
					
					if ([modalityQueryFilter object])
					{
                        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
                            [queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"ModalitiesinStudy"];
                        else
                            [queryManager addFilter:[modalityQueryFilter filteredValue] forDescription:@"Modality"];
						queryItem = YES;
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
                            NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), NSLocalizedString(@"No query parameters provided. Blank query is not allowed.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                        }
						else
                        {
                            if( showError)
                            {
                                if( atLeastOneSource == NO)
                                {
                                    NSString *alertSuppress = @"No parameters query";
                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                    if ([defaults boolForKey:alertSuppress])
                                    {
                                        doit = YES;
                                    }
                                    else
                                    {
                                        NSAlert* alert = [[NSAlert new] autorelease];
                                        [alert setMessageText: NSLocalizedString(@"Query", nil)];
                                        [alert setInformativeText: NSLocalizedString(@"No query parameters provided. The query may take a long time.", nil)];
                                        [alert setShowsSuppressionButton:YES ];
                                        [alert addButtonWithTitle: NSLocalizedString(@"Continue", nil)];
                                        [alert addButtonWithTitle: NSLocalizedString(@"Cancel", nil)];
                                        
                                        if ( [alert runModal] == NSAlertFirstButtonReturn) doit = YES;
                                        
                                        if ([[alert suppressionButton] state] == NSOnState)
                                        {
                                            [defaults setBool:YES forKey:alertSuppress];
                                        }
                                    }
                                }
                                else doit = YES;
                            }
                            else doit = YES;
						}
                        
						if( doit)
						{
							[self performQuery: [NSNumber numberWithBool: showError]];
						}
						else i = [sourcesArray count];
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
							int index = [self array: uidArray containsObject: [[curResult objectAtIndex: x] valueForKey:@"uid"]];
							
							if( index == -1) // not found
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
				}
//				else
//				{
//					NSString	*response = [NSString stringWithFormat: @"%@  /  %@:%d\r\r", theirAET, hostname, [port intValue]];
//				
//					response = [response stringByAppendingString:NSLocalizedString(@"Connection failed to this DICOM node (c-echo failed)", nil)];
//					
//					NSRunCriticalAlertPanel( NSLocalizedString(@"Query Error", nil), response, NSLocalizedString(@"Continue", nil), nil, nil) ;
//				}
			
				atLeastOneSource = YES;
			}
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
	
	[self performSelectorOnMainThread:@selector( refreshList:) withObject: tempResultArray waitUntilDone: NO];
	
	if( atLeastOneSource == NO)
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
	
	[resultArray removeAllObjects];
	[resultArray addObjectsFromArray: l];
	[outlineView reloadData];
	
    if( [resultArray count] <= 1) [numberOfStudies setStringValue: [NSString stringWithFormat: NSLocalizedString( @"%d study found", nil), [resultArray count]]];
	else [numberOfStudies setStringValue: [NSString stringWithFormat: NSLocalizedString( @"%d studies found", nil), [resultArray count]]];
    
	[l release];
}

- (void) displayQueryResults
{
	[sourcesTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [sourcesTable selectedRow]] byExtendingSelection: NO];
}

- (NSString*) exportDBListOnlySelected:(BOOL) onlySelected
{
	NSIndexSet *rowIndex;
	
	if( onlySelected) rowIndex = [outlineView selectedRowIndexes];
	else rowIndex = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange( 0, [outlineView numberOfRows])];
	
	NSMutableString	*string = [NSMutableString string];
	NSNumber *row;
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
	NSString *list = [self exportDBListOnlySelected: NO];
	
	NSSavePanel *sPanel	= [NSSavePanel savePanel];
		
	[sPanel setRequiredFileType:@"txt"];
	
	if ([sPanel runModalForDirectory: nil file:NSLocalizedString(@"OsiriX Database List", nil)] == NSFileHandlingPanelOKButton)
	{
		[list writeToFile: [sPanel filename] atomically: YES];
	}
}

-(void) query:(id)sender
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
	
	[self displayQueryResults];
	
	if ([sender isKindOfClass:[NSSearchField class]])
		[sender selectText: self];
}

- (void) performQuery:(NSNumber*) showErrors
{
	checkAndViewTry = -1;
	
    if( [NSThread isMainThread] == NO)
        showErrors = [NSNumber numberWithBool: NO];
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @synchronized( self)
    {
        if( performingCFind == NO)
        {
            performingCFind = YES;
            
            if( [NSThread isMainThread] == NO)
                [progressIndicator performSelectorOnMainThread: @selector( startAnimation:) withObject:nil waitUntilDone: NO];
            else
                [progressIndicator startAnimation:nil];
            
            [queryManager performQuery: [showErrors boolValue]];
            
            if( [NSThread isMainThread] == NO)
                [progressIndicator performSelectorOnMainThread: @selector( stopAnimation:) withObject:nil waitUntilDone: NO];
            else
                [progressIndicator stopAnimation:nil];
            
            performingCFind = NO;
        }
    }
    
	[pool release];
}

- (NSString*) stringIDForStudy:(id) item
{
	return [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@", [item valueForKey:@"name"], [item valueForKey:@"patientID"], [item valueForKey:@"accessionNumber"], [item valueForKey:@"date"], [item valueForKey:@"time"], [item valueForKey:@"uid"]];
}

- (void) addStudyIfNotAvailable: (id) item toArray:(NSMutableArray*) selectedItems
{
	NSArray *studyArray = [self localStudy: item];
	
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
		NSString *stringID = [self stringIDForStudy: item];
		
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

- (void) autoRetrieveThread: (NSArray*) list
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( autoQuery == NO)
		goto returnFromThread;
	
	if( [[BrowserController currentBrowser] database] != [DicomDatabase activeLocalDatabase])
		goto returnFromThread;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAuthorizeAutoRetrieve"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"autoRetrieving"];
		goto returnFromThread;
	}
	
	if( numberOfRunningRetrieve > 5)
	{
		NSLog( @"**** numberOfRunningRetrieve > 5... wait for next autoretrieve.");
		goto returnFromThread;
	}
	
	[autoQueryLock lock];
	
	// Start to retrieve the first XX studies...
	
	@try 
	{
		NSMutableArray *selectedItems = [NSMutableArray array];
		
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
                            if( [[d valueForKey: @"accessionNumber"] isEqualToString: [item valueForKey: @"accessionNumber"]] && [[d valueForKey: @"numberImages"] intValue] == [[item valueForKey: @"numberImages"] intValue])
                            {
                                addItem = NO;
                            
                                NSLog( @"--- Already downloaded during last hour: %@ - %d images", item, [[item valueForKey: @"numberImages"] intValue]);
                            }
                        }
                        else [downloadedStudies removeObject: d];
                    }
                }
            }
            
            if( addItem)
            {
                [self addStudyIfNotAvailable: item toArray: selectedItems];
                
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
			if( [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfPreviousStudyToRetrieve"])
			{
				NSMutableArray *previousStudies = [NSMutableArray array];
				for( id item in selectedItems)
				{
					NSArray *studiesOfThisPatient = [self queryPatientIDwithoutGUI: [item valueForKey:@"patientID"]];
					
					// Sort the resut by date & time
					NSMutableArray *sortArray = [NSMutableArray array];
					[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"date" ascending: NO] autorelease]];
					[sortArray addObject: [[[NSSortDescriptor alloc] initWithKey:@"time" ascending: NO] autorelease]];
					studiesOfThisPatient = [studiesOfThisPatient sortedArrayUsingDescriptors: sortArray];
					
					int numberOfStudiesAssociated = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfPreviousStudyToRetrieve"];
					
					for( id study in studiesOfThisPatient)
					{
						// We dont want current study
						if( [[study valueForKey:@"uid"] isEqualToString: [item valueForKey:@"uid"]] == NO)
						{
							BOOL found = YES;
							
							if( numberOfStudiesAssociated > 0)
							{
								if( [[NSUserDefaults standardUserDefaults] boolForKey:@"retrieveSameModality"])
								{
									if( [item valueForKey:@"modality"] && [study valueForKey:@"modality"])
									{
										if( [[study valueForKey:@"modality"] rangeOfString: [item valueForKey:@"modality"]].location == NSNotFound) found = NO;						
									}
									else found = NO;
								}
								
								if( [[NSUserDefaults standardUserDefaults] boolForKey:@"retrieveSameDescription"])
								{
									if( [item valueForKey:@"theDescription"] && [study valueForKey:@"theDescription"])
									{
										if( [[study valueForKey:@"theDescription"] rangeOfString: [item valueForKey:@"theDescription"]].location == NSNotFound) found = NO;
									}
									else found = NO;
								}
								
								if( found)
								{
									[self addStudyIfNotAvailable: study toArray: previousStudies];
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
			
			NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( performRetrieve:) object: selectedItems] autorelease];
			t.name = NSLocalizedString( @"Retrieving images...", nil);
            t.status = N2LocalizedSingularPluralCount(selectedItems.count, @"study", @"studies");
            if ([selectedItems count] > 1)
                t.progress = 0;
			t.supportsCancel = YES;
			[[ThreadsManager defaultManager] addThreadAndStart: t];
			
//			[NSThread detachNewThreadSelector:@selector( performRetrieve:) toTarget:self withObject: selectedItems];
			
			NSLog( @"______________________________________________");
			NSLog( @"Will auto-retrieve these items:");
			for( id item in selectedItems)
			{
				NSLog( @"%@ %@ %@ %@", [item valueForKey:@"name"], [item valueForKey:@"patientID"], [item valueForKey:@"accessionNumber"], [item valueForKey:@"date"]);
			}
			NSLog( @"______________________________________________");
			
			NSString *desc = nil;
			
			if( [selectedItems count] == 1) desc = [NSString stringWithFormat: NSLocalizedString( @"Will auto-retrieve %d study", nil), [selectedItems count]];
			else desc = [NSString stringWithFormat: NSLocalizedString( @"Will auto-retrieve %d studies", nil), [selectedItems count]];
			
			[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: desc name: @"autoquery"];
		}
		else
		{
//			NSLog( @"--- autoRetrieving is up to date! Nothing to retrieve ---");
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	[autoQueryLock unlock];
	
	returnFromThread:
	
	[pool release];
}

- (void) displayAndRetrieveQueryResults
{
	[self displayQueryResults];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"autoRetrieving"] && autoQuery == YES)
	{
		NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( autoRetrieveThread:) object: [NSArray arrayWithArray: resultArray]] autorelease];
		t.name = NSLocalizedString( @"Retrieving images...", nil);
		[[ThreadsManager defaultManager] addThreadAndStart: t];
		
//		[NSThread detachNewThreadSelector:@selector( autoRetrieveThread:) toTarget:self withObject: [NSArray arrayWithArray: resultArray]];
	}
}

- (void) autoQueryThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( [self queryWithDisplayingErrors: NO] == 0)
		[self performSelectorOnMainThread: @selector( displayAndRetrieveQueryResults) withObject:0 waitUntilDone: NO];
	else
	{
		[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Retrieve", nil) description: @"Failed..." name: @"autoquery"];
        NSLog( @"****** Q&R autoQueryThread failed...");
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
		if( --autoQueryRemainingSecs <= 0)
		{
			if( [autoQueryLock tryLock])
			{
				[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Q&R Auto-Query", nil) description: NSLocalizedString( @"Refreshing...", nil) name: @"autoquery"];
				
				[self saveSettings];
				
				NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( autoQueryThread) object: nil] autorelease];
				t.name = NSLocalizedString( @"Auto-Querying images...", nil);
				t.supportsCancel = YES;
				[[ThreadsManager defaultManager] addThreadAndStart: t];
				
//				[NSThread detachNewThreadSelector: @selector( autoQueryThread) toTarget: self withObject: nil];
				
				autoQueryRemainingSecs = 60*self.autoRefreshQueryResults; 
				
				[autoQueryLock unlock];
			}
			else autoQueryRemainingSecs = 0;
		}
	}
	
	[autoQueryCounter setStringValue: [NSString stringWithFormat: @"%2.2d:%2.2d", (int) (autoQueryRemainingSecs/60), (int) (autoQueryRemainingSecs%60)]];
}

- (IBAction) autoQueryTimer:(id) sender
{
	if( self.autoRefreshQueryResults)
	{
		[QueryTimer invalidate];
		[QueryTimer release];
		
		autoQueryRemainingSecs = 60*self.autoRefreshQueryResults;
		[autoQueryCounter setStringValue: [NSString stringWithFormat: @"%2.2d:%2.2d", (int) (autoQueryRemainingSecs/60), (int) (autoQueryRemainingSecs%60)]];
		
		QueryTimer = [[NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector( autoQueryTimerFunction:) userInfo:nil repeats:YES] retain];
	}
	else
	{
		[autoQueryCounter setStringValue: @""];
		
		[QueryTimer invalidate];
		[QueryTimer release];
		QueryTimer = nil;
		
		if( autoQuery == YES)
			[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"autoRetrieving"];
	}
}

- (void)clearQuery:(id)sender
{
	[queryManager release];
	queryManager = nil;
	[progressIndicator stopAnimation:nil];
	[searchFieldName setStringValue:@""];
	[searchFieldRefPhysician setStringValue:@""];
	[searchFieldID setStringValue:@""];
	[searchFieldAN setStringValue:@""];
	[searchFieldStudyDescription setStringValue:@""];
	[searchFieldComments setStringValue: @""];
	[outlineView reloadData];
}

- (IBAction) copy: (id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	NSString *string;
	
	if( [[outlineView selectedRowIndexes] count] == 1)
		string = [[outlineView itemAtRow: [outlineView selectedRowIndexes].firstIndex] valueForKey: @"name"];
	else 
		string = [self exportDBListOnlySelected: YES];
	
	[pb setString: string forType:NSStringPboardType];
}

-(void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable forViewing: (BOOL) forViewing items:(NSArray*) items showGUI:(BOOL) showGUI
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	
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
//						array = [self localSeries: item];
//						
//						if( [array count])
//							localStudy = [[array lastObject] valueForKey: @"study"];
//					}
//					else
//					{
//						array = [self localStudy: item];
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
						array = [self localSeries: item];
					else
						array = [self localStudy: item];
					
					if( [array count])
						localNumber = [[[array objectAtIndex: 0] valueForKey: @"rawNoFiles"] intValue];
					
					if( localNumber < [[item valueForKey:@"numberImages"] intValue] || [[item valueForKey:@"numberImages"] intValue] == 0)
					{
						NSString *stringID = [self stringIDForStudy: item];
			
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
				NSString *stringID = [self stringIDForStudy: item];
				
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
				
				NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( performRetrieve:) object: selectedItems] autorelease];
				t.name = NSLocalizedString( @"Retrieving images...", nil);
                t.status = N2LocalizedSingularPluralCount(selectedItems.count, @"study", @"studies");
                if ([selectedItems count] > 1)
                    t.progress = 0;
				
				t.supportsCancel = YES;
				[[ThreadsManager defaultManager] addThreadAndStart: t];
				
//				[NSThread detachNewThreadSelector:@selector( performRetrieve:) toTarget:self withObject: selectedItems];
				
				if( showGUI)
				{
					[NSThread sleepForTimeInterval: 0.2];
				
					[wait close];
					[wait release];
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
			else yearOld = [NSString stringWithFormat: NSLocalizedString( @"%d m", @"m = month"), months];
		}
		else yearOld = [NSString stringWithFormat: NSLocalizedString( @"%d y %d m", @"y = year, m = month"),years, months];
	}
	else yearOld = [NSString stringWithFormat: NSLocalizedString( @"%d y", @"y = year"), years];
		
	[yearOldBirth setStringValue: yearOld];
}

- (void) performRetrieve:(NSArray*) array
{
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
    NSArray *copiedSourcesArray = [NSArray arrayWithArray: sourcesArray];
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
        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
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
				NSLog( @"performRetrieve move exception: %@", e);
			}
			
			@synchronized( previousAutoRetrieve)
			{
				[previousAutoRetrieve removeObjectForKey: [self stringIDForStudy: object]];
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
					[previousAutoRetrieve removeObjectForKey: [self stringIDForStudy: object]];
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
		NSLog( @"performRetrieve exception: %@", e);
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
	{
		[item release];
		return;
	}
	
	if( checkAndViewTry < 0)
	{
		[item release];
		return;
	}
	
    [[BrowserController currentBrowser] setDatabase:[DicomDatabase activeLocalDatabase]];
	[[BrowserController currentBrowser] checkIncoming: self];
	
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
			NSPredicate	*predicate = [NSPredicate predicateWithFormat:  @"(studyInstanceUID == %@)", [item valueForKey:@"uid"]];
			
			[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
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
			
			[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
			[request setPredicate: predicate];
			
			seriesArray = [context executeFetchRequest:request error:&error];
			if( [seriesArray count] > 0)
			{
				NSLog( @"%@",  [seriesArray description]);
				
				NSManagedObject	*series = [seriesArray objectAtIndex: 0];
				
				[[BrowserController currentBrowser] openViewerFromImages: [NSArray arrayWithObject: [[BrowserController currentBrowser] childrenArray: series]] movie: nil viewer :nil keyImagesOnly:NO];
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
					[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
				else
					[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
					
				success = YES;
			}
		}
		
		if( !success)
		{
			[[BrowserController currentBrowser] checkIncoming: self];
			
			if( checkAndViewTry-- > 0 && [sendToPopup indexOfSelectedItem] == 0)
				[self performSelector:@selector( checkAndView:) withObject:item afterDelay:1.0];
			else
				success = YES;
		}
		
		if( success)
			[item release];
				
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
		if( item) [self checkAndView: [item retain]];
	}
}

- (void)setModalityQuery:(id)sender
{
	[modalityQueryFilter release];
	
	NSMutableString *m = [NSMutableString stringWithString: @""];
	for( NSCell *cell in [sender cells])
	{
		if( [cell state] == NSOnState)
		{
			if( [m length]) [m appendString:@"\\"];
			[m appendString: [cell title]];
		}
	}
	
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
    {
        if( [m length])
            modalityQueryFilter = [[QueryFilter queryFilterWithObject: m ofSearchType: searchExactMatch forKey:@"ModalitiesinStudy"] retain];
        else
            modalityQueryFilter = [[QueryFilter queryFilterWithObject: nil ofSearchType: searchExactMatch forKey:@"ModalitiesinStudy"] retain];
    }
    else
    {
        if( [m length])
            modalityQueryFilter = [[QueryFilter queryFilterWithObject: m ofSearchType: searchExactMatch forKey:@"Modality"] retain];
        else
            modalityQueryFilter = [[QueryFilter queryFilterWithObject: nil ofSearchType: searchExactMatch forKey:@"Modality"] retain];
    }
}


- (void)setDateQuery:(id)sender
{
	[dateQueryFilter release];
	[timeQueryFilter release];
	timeQueryFilter = nil;
	
	if( [sender selectedTag] == 5)
	{
		[fromDate setEnabled: YES];
		[toDate setEnabled: YES];
		
		NSDate *later = [[fromDate dateValue] laterDate: [toDate dateValue]];
		NSDate *earlier = [[fromDate dateValue] earlierDate: [toDate dateValue]];
		
		NSString *between = [NSString stringWithFormat:@"%@-%@", [earlier descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil], [later descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];
		
		dateQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch forKey:@"StudyDate"] retain];
	}
	else
	{
		[fromDate setEnabled: NO];
		[toDate setEnabled: NO];
		
		DCMCalendarDate *date = nil;
		
		int searchType = searchAfter;
		NSString *between = nil;
		
		switch( [sender selectedTag])
		{
			case 0:			date = nil;																								break;
			case 1:			date = [DCMCalendarDate date];											searchType = SearchToday;		break;
			case 2:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24 -1];	searchType = searchYesterday;	break;
			case 3:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*7 -1];									break;
			case 4:			date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*24*31 -1];									break;
			
            default:
                if( [sender selectedTag] >= 100 && [sender selectedTag] <= 200)
                {
                    int hours = [sender selectedTag] - 100;
                    
                    searchType = searchAfter;
                    
                    date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*60*hours];
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMQueryAllowFutureQuery"])
                        between = [NSString stringWithFormat:@"%@.000-", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*60*hours] descriptionWithCalendarFormat: @"%H%M%S"]];
                    else
                        between = [NSString stringWithFormat:@"%@.000-%@.000", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*60*hours] descriptionWithCalendarFormat: @"%H%M%S"], [[NSCalendarDate date] descriptionWithCalendarFormat: @"%H%M%S"]];
                        
                    timeQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyTime"] retain];
                }
                else if( [sender selectedTag] >= 200 && [sender selectedTag] <= 300)
                {
                    int min = [sender selectedTag] - 200;
                    
                    searchType = searchAfter;
                    
                    date = [DCMCalendarDate dateWithTimeIntervalSinceNow: -60*min];
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMQueryAllowFutureQuery"])
                        between = [NSString stringWithFormat:@"%@.000-", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*min] descriptionWithCalendarFormat: @"%H%M%S"]];
                    else
                        between = [NSString stringWithFormat:@"%@.000-%@.000", [[NSCalendarDate dateWithTimeIntervalSinceNow: -60*min] descriptionWithCalendarFormat: @"%H%M%S"], [[NSCalendarDate date] descriptionWithCalendarFormat: @"%H%M%S"]];
                    
                    timeQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyTime"] retain];
                }
                else NSLog( @"******* unknown setDateQuery tag: %@", (int) [sender selectedTag]);
			break;
				
			case 10:	// AM & PM
			case 11:
				date = [DCMCalendarDate date];
				searchType = SearchToday;
				
				if( [sender selectedTag] == 10)
					between = [NSString stringWithString:@"000000.000-120000.000"];
				else
					between = [NSString stringWithString:@"120000.000-235959.000"];
				
				timeQueryFilter = [[QueryFilter queryFilterWithObject:between ofSearchType:searchExactMatch  forKey:@"StudyTime"] retain];
			break;
		}
		dateQueryFilter = [[QueryFilter queryFilterWithObject:date ofSearchType:searchType  forKey:@"StudyDate"] retain];
	}
}

-(void) awakeFromNib
{
	[numberOfStudies setStringValue: @""];
	
	[[self window] setFrameAutosaveName:@"QueryRetrieveWindow"];
	
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier: @"stateText"];
	NSPopUpButtonCell *buttonCell = [[[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO] autorelease];
	[buttonCell setEditable: YES];
	[buttonCell setBordered: NO];
	[buttonCell addItemsWithTitles: [BrowserController statesArray]];
	[tableColumn setDataCell:buttonCell];
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldAN cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
								action:NULL
								keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
								action:NULL
								keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
								action:NULL
								keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldStudyDescription cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
								action:NULL
								keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
								action:NULL
								keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
								action:NULL
								keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldComments cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
								action:NULL
								keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
								action:NULL
								keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
								action:NULL
								keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldRefPhysician cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
										   action:NULL
									keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
										   action:NULL
									keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
										   action:NULL
									keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldID cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
								action:NULL
								keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
								action:NULL
								keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
								action:NULL
								keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	{
		NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
		NSMenuItem *item1, *item2, *item3;
		id searchCell = [searchFieldName cell];
		item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches"
									action:NULL
									keyEquivalent:@""];
		[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
		[cellMenu insertItem:item1 atIndex:0];
		[item1 release];
		item2 = [[NSMenuItem alloc] initWithTitle:@"Recents"
									action:NULL
									keyEquivalent:@""];
		[item2 setTag:NSSearchFieldRecentsMenuItemTag];
		[cellMenu insertItem:item2 atIndex:1];
		[item2 release];
		item3 = [[NSMenuItem alloc] initWithTitle:@"Clear"
									action:NULL
									keyEquivalent:@""];
		[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
		[cellMenu insertItem:item3 atIndex:2];
		[item3 release];
		[searchCell setSearchMenuTemplate:cellMenu];
	}
	
	[[[outlineView tableColumnWithIdentifier: @"birthdate"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
	[[[outlineView tableColumnWithIdentifier: @"date"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
	
	[sourcesTable setDoubleAction: @selector( selectUniqueSource:)];
	
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
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAuthorizeAutoRetrieve"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"autoRetrieving"];
		
		NSLog( @"--- autoretrieving is not authorized - see locations preferences");
	}
	
	[self setBirthDate: nil];
    
    // build table header context menu
    if( [[outlineView autosaveName] length] == 0)
    {
        NSArray *cols = [[NSUserDefaults standardUserDefaults] arrayForKey: @"QueryControllerTableColumns"];
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
            NSMenuItem *item = [tableHeaderContextMenu itemWithTitle:[colinfo objectForKey:@"title"]];
            if(!item) continue; // missing title
            [item setState:NSOnState];
            column = [item representedObject];
            
            NSString *identifier = [column identifier];
            if( [identifier isEqualToString: @"Button"] == NO && [identifier isEqualToString: @"name"] == NO)
            {
                [column setWidth:[[colinfo objectForKey:@"width"] floatValue]];
                [outlineView addTableColumn: column];
            }
            else
                [column setWidth:[[colinfo objectForKey:@"width"] floatValue]];
        }
        
        if( [[NSUserDefaults standardUserDefaults] objectForKey: @"QueryControllerTableColumnsSortDescriptor"])
        {
            NSDictionary *sort = [[NSUserDefaults standardUserDefaults] objectForKey: @"QueryControllerTableColumnsSortDescriptor"];
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
                         [[column headerCell] title], @"title",
                         [NSNumber numberWithFloat:[column width]], @"width",
                         nil]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:cols forKey: @"QueryControllerTableColumns"];
    
    NSDictionary *sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[outlineView sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[outlineView sortDescriptors] objectAtIndex: 0] key], @"key", nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"QueryControllerTableColumnsSortDescriptor"];
}

- (void)contextMenuSelected:(NSMenuItem*)sender
{
    BOOL on = ([sender state] == NSOnState);
    [sender setState: on ? NSOffState : NSOnState];
    
    NSTableColumn *column = [sender representedObject];
    
    NSString *identifier = [column identifier];

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
		
		NSLog( @"%@",  [server description]);
		
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
		
		NSString *ip = [NSString stringWithCString:GetPrivateIP()];
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
    DcmHashDictIterator end(globalDataDict.normalEnd());
    for (; iter != end; ++iter)
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

- (id) initAutoQuery: (BOOL) autoQR
{
    if ( self = [super initWithWindowNibName:@"Query"])
	{
		if( [[DCMNetServiceDelegate DICOMServersList] count] == 0)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Query & Retrieve",nil),NSLocalizedString( @"No DICOM locations available. See Preferences to add DICOM locations.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseAddNotification:) name:OsirixAddToDBNotification object:nil];
		
		queryFilters = nil;
		dateQueryFilter = nil;
		timeQueryFilter = nil;
		modalityQueryFilter = nil;
		currentQueryKey = nil;
		autoQuery = autoQR;
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		queryFilters = [[NSMutableArray array] retain];
		resultArray = [[NSMutableArray array] retain];
		previousAutoRetrieve = [[NSMutableDictionary dictionary] retain];
		autoQueryLock = [[NSRecursiveLock alloc] init];
		
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
			[dateFilterMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"QRLastDateFilterValue"]];
			[self setDateQuery: dateFilterMatrix];
			
			currentQueryController = self;
			[[self window] setTitle: NSLocalizedString( @"DICOM Query/Retrieve", nil)];

			if( [[AppController sharedAppController] isStoreSCPRunning] == NO)
				NSRunCriticalAlertPanel(NSLocalizedString( @"DICOM Query & Retrieve",nil), NSLocalizedString( @"Retrieve cannot work if the DICOM Listener is not activated. See Preferences - Listener.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
		else
		{
			[self setDateQuery: dateFilterMatrix];
			
			currentAutoQueryController = self;
			[[self window] setTitle: NSLocalizedString( @"DICOM Auto Query/Retrieve", nil)];
			
			NSDictionary *d = [[NSUserDefaults standardUserDefaults] objectForKey: @"savedAutoDICOMQuerySettings"];
			[self applyPresetDictionary: d];
		}
        
        DICOMFieldsArray = [[self prepareDICOMFieldsArrays] retain];
        
        NSMenu *DICOMFieldsMenu = [dicomFieldsMenu menu];
        [DICOMFieldsMenu setAutoenablesItems:NO];
        [dicomFieldsMenu removeAllItems];
        
        NSMenuItem *item;
        item = [[[NSMenuItem alloc] init] autorelease];
        int i;
        for (i=0; i<[DICOMFieldsArray count]; i++)
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

	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixAddToDBNotification object:nil];

	NSLog( @"dealloc QueryController");
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector( executeRefresh:) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys];
	
	[autoQueryLock lock];
	[autoQueryLock unlock];
	
	[[NSUserDefaults standardUserDefaults] setObject:sourcesArray forKey: queryArrayPrefs];
	[pressedKeys release];
	[fromDate setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	[queryManager release];
	[queryFilters release];
	[dateQueryFilter release];
	[timeQueryFilter release];
	[modalityQueryFilter release];
	[previousAutoRetrieve release];
	[sourcesArray release];
	[resultArray release];
	[QueryTimer invalidate];
	[QueryTimer release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[queryArrayPrefs release];
	
	[autoQueryLock release];
    
    [DICOMFieldsArray release];
	
	avoidQueryControllerDeallocReentry = NO;
	
	[super dealloc];
	
	currentQueryController = nil;
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
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Retrieve the images", nil) action: @selector( retrieve:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];

	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Retrieve and display the images", nil) action: @selector( retrieveAndView:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Query all studies of this patient", nil) action: @selector( querySelectedStudy:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete the local images", nil) action: @selector( deleteSelection:) keyEquivalent:@""] autorelease];
	[item setTarget: self];		[menu addItem: item];
	
	[outlineView setMenu: menu];
	
	//set up Query Keys
	currentQueryKey = PatientName;
	
	dateQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"StudyDate"] retain];
	timeQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"StudyTime"] retain];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SupportQRModalitiesinStudy"])
        modalityQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"ModalitiesinStudy"] retain];
	else
        modalityQueryFilter = [[QueryFilter queryFilterWithObject:nil ofSearchType:searchExactMatch forKey:@"Modality"] retain];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( updateServers:) name:@"DCMNetServicesDidChange"  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( realtimeCFindResults:) name:@"realtimeCFindResults"  object:nil];
    
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"Button"];
	NSButtonCell *buttonCell = [[[NSButtonCell alloc] init] autorelease];
	[buttonCell setTarget:self];
	[buttonCell setAction:@selector(retrieveClick:)];
	[buttonCell setControlSize:NSMiniControlSize];
	[buttonCell setImage:[NSImage imageNamed:@"InArrow.tif"]];
	[buttonCell setBezelStyle: NSRoundRectBezelStyle]; // was NSRegularSquareBezelStyle
	[tableColumn setDataCell:buttonCell];
}

- (void) saveSettings
{
	NSDictionary *settings = [self savePresetInDictionaryWithDICOMNodes: YES];
	
	if( autoQuery)
		[[NSUserDefaults standardUserDefaults] setObject: settings forKey: @"savedAutoDICOMQuerySettings"];
	else
		[[NSUserDefaults standardUserDefaults] setObject: settings forKey: @"savedDICOMQuerySettings"];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self saveTableColumns];
    
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[NSUserDefaults standardUserDefaults] setInteger: [dateFilterMatrix selectedTag] forKey: @"QRLastDateFilterValue"];
	
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

- (void) updateServers:(NSNotification *)note
{
	[self refreshSources];
}

- (IBAction) verify:(id)sender
{
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

- (IBAction)abort:(id)sender
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter postNotificationName:@"DCMAbortQueryNotification" object:nil];
	[defaultCenter postNotificationName:@"DCMAbortMoveNotification" object:nil];
	[defaultCenter postNotificationName:@"DCMAbortEchoNotification" object:nil];
}


- (IBAction)controlAction:(id)sender{
	if ([sender selectedSegment] == 0)
		[self verify:sender];
	else if ([sender selectedSegment] == 1)
		[self abort:sender];
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

-(void)observeDatabaseAddNotification:(NSNotification*)notification {
	[self performSelectorOnMainThread:@selector(refresh:) withObject:self waitUntilDone:NO];
}

@end
