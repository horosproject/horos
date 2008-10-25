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

#import "AnonymizerWindowController.h"
#import <OsiriX/DCM.h>
#import "Wait.h"
#import "ButtonAndTextCell.h"
#import "BrowserController.h"

@implementation AnonymizerWindowController

- (NSDictionary*) anonymizeTags
{
	NSMutableDictionary	*dict = [NSMutableDictionary dictionary];
	NSEnumerator		*enumeratorCheck = [[[tagMatrixfirstColumn cells] arrayByAddingObjectsFromArray: [tagMatrixsecondColumn cells]] objectEnumerator];
	NSEnumerator		*enumeratorValue = [[[firstColumnValues cells] arrayByAddingObjectsFromArray: [secondColumnValues cells]] objectEnumerator];
	
	NSCell				*cellCheck, *cellValue;
	DCMAttributeTag		*attrTag;
	
	while (cellCheck = [enumeratorCheck nextObject])
	{
		cellValue = [enumeratorValue nextObject];
		
		if ([cellCheck state] == NSOnState)
		{
			[dict setObject:[cellValue stringValue] forKey:[cellCheck title]];
		}
	}
	
	NSLog( [dict description]);
	
	return dict;
}

- (void) setAnonymizeTags:(NSDictionary*) dict
{
	NSEnumerator	*enumerator = [dict keyEnumerator];
	NSString		*string;
	
	NSArray			*checksArray = [[tagMatrixfirstColumn cells] arrayByAddingObjectsFromArray: [tagMatrixsecondColumn cells]];
	NSArray			*valuesArray = [[firstColumnValues cells] arrayByAddingObjectsFromArray: [secondColumnValues cells]];
	int				i;
	
	for( i = 0; i < [checksArray count] ; i++) [[checksArray objectAtIndex: i] setState:NSOffState];
	for( i = 0; i < [valuesArray count] ; i++)
	{
		[[valuesArray objectAtIndex: i] setEnabled: NO];
		[[valuesArray objectAtIndex: i] setStringValue: @""];
	}
	
	while ((string = [enumerator nextObject]))
	{
		for( i = 0; i < [checksArray count] ; i++)
		{
			if( [[[checksArray objectAtIndex: i] title] isEqualToString: string])
			{
				[[checksArray objectAtIndex: i] setState: NSOnState];
				[[valuesArray objectAtIndex: i] setEnabled: YES];
				[[valuesArray objectAtIndex: i] setStringValue: [dict objectForKey: string]];
			}
		}
	}
}

- (IBAction) selectTemplateMenu:(id) sender;
{
	if( [sender selectedItem])
		[self setAnonymizeTags: [templates objectForKey: [[sender selectedItem] title]]];
}


- (IBAction)cancelModal:(id)sender
{
    [NSApp abortModal];
}

- (IBAction)okModal:(id)sender
{
    [NSApp stopModal];
}

- (IBAction) addTemplate:(id) sender;
{
	[templateName setStringValue:@""];
	
	[NSApp beginSheet:	templateNameWindow
						modalForWindow: [NSApp keyWindow]
						modalDelegate: nil
						didEndSelector: nil
						contextInfo: nil];
	
	int result = [NSApp runModalForWindow:templateNameWindow];
	
	[NSApp endSheet: templateNameWindow];
	[templateNameWindow orderOut: self];
	
	if( result == NSRunStoppedResponse && [[templateName stringValue] isEqualToString:@""] == NO)
	{
		[templates setObject:[self anonymizeTags] forKey: [templateName stringValue]];
		
		[templatesMenu removeAllItems];
		[templatesMenu addItemsWithTitles: [templates allKeys]];
		
		[templatesMenu selectItemWithTitle: [templateName stringValue]];
		
		[self selectTemplateMenu: templatesMenu];
	}
}

- (IBAction) removeTemplate:(id) sender;
{
	[templates removeObjectForKey: [[templatesMenu selectedCell] title]];
	
	[templatesMenu removeAllItems];
	[templatesMenu addItemsWithTitles: [templates allKeys]];
	
	if( [templatesMenu numberOfItems] > 0)
	{
		[templatesMenu selectItemAtIndex: 0];
		[self selectTemplateMenu: templatesMenu];
	}
}

-(id) init
{
	if (self = [super initWithWindowNibName:@"Anonymize"])
	{
		tags = [[NSMutableArray array] retain];
		producedFiles = [[NSMutableArray array] retain];
	}
    return self;
}

- (void)dealloc
{
	NSLog( @"AnonymizerWindowController dealloc");
	
	[producedFiles release];
	[templates release];
	[filesToAnonymize release];
	[dcmObjects release];
	[tagMatrixfirstColumn release];
	[tagMatrixsecondColumn release];
	[accessoryView release];
	[super dealloc];
}

- (void)windowDidLoad
{
	[(NSButtonCell *)[tagMatrixfirstColumn prototype] setAllowsMixedState:YES];
	[(NSButtonCell *)[tagMatrixsecondColumn prototype] setAllowsMixedState:YES];
	
	[tagMatrixfirstColumn retain];
	[tagMatrixsecondColumn retain];
	[accessoryView retain];

	NSEnumerator *enumerator = [[[tagMatrixfirstColumn cells] arrayByAddingObjectsFromArray: [tagMatrixsecondColumn cells]] objectEnumerator];
	NSCell *cell;
	while (cell = [enumerator nextObject])
	{
		int tag = [cell tag];
		if (tag % 4 == 0)
			[[firstColumnValues cellWithTag:tag] setEnabled:[cell state]];
		else
			[[secondColumnValues cellWithTag:tag] setEnabled:[cell state]];
	}
}

- (void) anonymizeProcess:(NSString*) path
{
	Wait *splash = [[Wait alloc] initWithString:@"Anonymize..."];
	[splash showWindow:self];
	[[splash progress] setMaxValue:[filesToAnonymize count]];
	
	if (DEBUG)
		NSLog(@"file Count: %d", [filesToAnonymize count]);
		
	NSString *file;
	NSManagedObject *dcm;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	for( int i = 0; i < [filesToAnonymize count]; i++)
	{
		file = [filesToAnonymize objectAtIndex: i];
		dcm = [dcmObjects objectAtIndex: i];

		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];			
		NSString		*extension		= [file pathExtension], *dest;
		long			previousSeries	= -1;
		long			serieCount		= 0;
		
		if([extension isEqualToString:@""]) extension = [NSString stringWithString:@"dcm"]; 
		
		NSString *tempPath;
		
		if( [[tagMatrixfirstColumn cellWithTag: 0] state] == NSOnState)
			tempPath = [path stringByAppendingPathComponent:[[firstColumnValues cellWithTag:0] stringValue]];
		else
			tempPath = [path stringByAppendingPathComponent:[dcm valueForKeyPath: @"series.study.name"]];
			
		// Find the DICOM-PATIENT folder
		if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
		
		tempPath = [tempPath stringByAppendingPathComponent:[dcm valueForKeyPath: @"series.study.studyName"] ];
		// Find the DICOM-STUDY folder
		if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
		
		tempPath = [tempPath stringByAppendingPathComponent:[dcm valueForKeyPath: @"series.name"] ];
		
		tempPath = [tempPath stringByAppendingFormat:@" - %@", [dcm valueForKeyPath: @"series.id"]];
		
		// Find the DICOM-SERIE folder
		if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
		
		long imageNo = [[dcm valueForKey:@"instanceNumber"] intValue];
		
		if( previousSeries != [[dcm valueForKeyPath: @"series.id"] intValue])
		{
			previousSeries = [[dcm valueForKeyPath: @"series.id"] intValue];
			serieCount++;
		}
		
		dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, extension];
		
		int t = 2;
		while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
		{
			dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d #%d.%@", tempPath, serieCount, imageNo, t, extension];
			t++;
		}
		
		//DCMObject *dcm = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
		//NSXMLDocument *xmlDoc = [dcm xmlDocument];
		//NSString *dst = [NSString stringWithFormat:@"%@/Desktop/%@", NSHomeDirectory(), @"test.xml"];
		//NSLog(dst);
		//if([[xmlDoc  XMLData] writeToFile:dst atomically:YES])
		//	NSLog(@"Wrote xml");
		@try
		{
			[DCMObject anonymizeContentsOfFile:file  tags:[self tags]  writingToFile:dest];
		}
		@catch (NSException * e)
		{
			NSLog( @"Exception during anonymization -- [DCMObject anonymizeContentsOfFile:file  tags:[self tags]  writingToFile:dest] : %@", e);
		}
		
		[producedFiles addObject: dest];
		
		[pool release];
		[splash incrementBy:1];
	}
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	[splash close];
	[splash release];

}

- (IBAction) anonymizeToThisPath:(NSString*) path
{
	[checkReplace setHidden: YES];
	
	templates = [[NSMutableDictionary alloc] initWithDictionary: [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"anonymizeTemplate"]];
	NSLog( [templates description]);
	
	[templatesMenu removeAllItems];
	[templatesMenu addItemsWithTitles: [templates allKeys]];
	[self selectTemplateMenu: templatesMenu];
	
	[producedFiles removeAllObjects];
	
	[anonymizeView addSubview: accessoryView];
	
	[NSApp beginSheet:	anonymizeWindow
						modalForWindow: [NSApp keyWindow]
						modalDelegate: nil
						didEndSelector: nil
						contextInfo: nil];
	
	int result = [NSApp runModalForWindow:anonymizeWindow];
	
	[NSApp endSheet: anonymizeWindow];
	[anonymizeWindow orderOut: self];
	
	[[NSUserDefaults standardUserDefaults] setObject: templates forKey:@"anonymizeTemplate"];
	
	if( result == NSRunStoppedResponse)
	{
		[self anonymizeProcess: path];
	}
	
	[filesToAnonymize release];
	filesToAnonymize = nil;
	[dcmObjects release];
	dcmObjects = 0L;
}

- (BOOL) cancelled
{
	return cancelled;
}

- (IBAction) anonymize:(id)sender
{
	[checkReplace setHidden: NO];
	
	templates = [[NSMutableDictionary alloc] initWithDictionary: [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"anonymizeTemplate"]];
	NSLog( [templates description]);
	
	[templatesMenu removeAllItems];
	[templatesMenu addItemsWithTitles: [templates allKeys]];
	[self selectTemplateMenu: templatesMenu];
	
	[producedFiles removeAllObjects];
	
	long i;
	sPanel		= [NSOpenPanel openPanel];
	//[sPanel setAccessoryView: optionsView];
	[sPanel setAccessoryView:accessoryView];
	[sPanel setCanCreateDirectories:YES];
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to save the DICOM anonymized files:",0L)];
	[sPanel setPrompt: NSLocalizedString(@"Anonymize",0L)];
	[sPanel setTitle: NSLocalizedString(@"Anonymize",0L)];
	
	BOOL isDir;
	NSString *path;
	if ([sPanel runModalForDirectory:0L file:NSLocalizedString(@"DICOM Export Folder", nil)] == NSFileHandlingPanelOKButton)
	{
		path = [[sPanel filenames] objectAtIndex:0];
		
		[self anonymizeProcess: path];
		
		cancelled = NO;
	}
	else cancelled = YES;
	[sPanel setMessage:@""];
	
	[filesToAnonymize release];
	filesToAnonymize = nil;
	[dcmObjects release];
	dcmObjects = 0L;
	
	[[NSUserDefaults standardUserDefaults] setObject: templates forKey:@"anonymizeTemplate"];
}

- (NSArray*) producedFiles
{
	return producedFiles;
}

- (void)setFilesToAnonymize:(NSArray *)files :(NSArray*)dcm{
	[filesToAnonymize release];
	[dcmObjects release];
	
	filesToAnonymize  = [files retain];
	dcmObjects = [dcm retain];
}

-(NSArray *)tags
{
	NSEnumerator *enumerator = [[[tagMatrixfirstColumn cells] arrayByAddingObjectsFromArray: [tagMatrixsecondColumn cells]] objectEnumerator];
	NSCell *cell;
	[tags removeAllObjects];
	DCMAttributeTag *attrTag;
	while (cell = [enumerator nextObject])
	{
		if (DEBUG)
			NSLog(@"Matrix cell: %@", [cell title]);
			if ([cell state] == NSOnState)
			{
				switch([cell tag])
				{
					case 0:
						attrTag = [DCMAttributeTag tagWithName:@"PatientsName"];
						break;
					case 2:
						attrTag = [DCMAttributeTag tagWithName:@"PatientsSex"];
						break;
					case 4:
						attrTag = [DCMAttributeTag tagWithName:@"PatientID"];
						break;
					case 6:
						attrTag = [DCMAttributeTag tagWithName:@"PatientsWeight"];
						break;
					case 8:
						attrTag = [DCMAttributeTag tagWithName:@"PatientsAge"];
						break;
					case 10:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialSponsorName"];
						break;
					case 12:
						attrTag = [DCMAttributeTag tagWithName:@"PatientsBirthDate"];
						break;
					case 14:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialProtocolID"];
						break;
					case 16:
						attrTag = [DCMAttributeTag tagWithName:@"InstitutionName"];
						break;
					case 18:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialProtocolName"];
						break;
					case 20:
						attrTag = [DCMAttributeTag tagWithName:@"StudyDate"];
						break;
					case 22:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialSiteID"];
						break;
					case 24:
						attrTag = [DCMAttributeTag tagWithName:@"StudyTime"];
						break;
					case 26:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialSiteName"];
						break;
					case 28:
						attrTag = [DCMAttributeTag tagWithName:@"AcquisitionDatetime"];
						break;
					case 34:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialSubjectID"];
						break;
					case 32:
						attrTag = [DCMAttributeTag tagWithName:@"SeriesDate"];
						break;
					case 30:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialSubjectReadingID"];
						break;
					case 36:
						attrTag = [DCMAttributeTag tagWithName:@"SeriesTime"];
						break;
					case 38:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialTimePointID"];
						break;
					case 40:
						attrTag = [DCMAttributeTag tagWithName:@"InstanceCreationDate"];
						break;
					case 42:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialTimePointDescription"];
						break;
					case 44:
						attrTag = [DCMAttributeTag tagWithName:@"InstanceCreationTime"];
						break;
					case 46:
						attrTag = [DCMAttributeTag tagWithName:@"ClinicalTrialCoordinatingCenterName"];
						break;
					case 48:
						attrTag = [DCMAttributeTag tagWithName:@"ReferringPhysiciansName"];
						break;
					case 50:
						attrTag = [DCMAttributeTag tagWithName:@"PerformingPhysiciansName"];
						break;
					case 52:
						attrTag = [DCMAttributeTag tagWithName:@"AccessionNumber"];
						break;
					case 54:
						attrTag = [DCMAttributeTag tagWithName:@"PhysiciansofRecord"];
						break;
					case 56:
						attrTag = [DCMAttributeTag tagWithName:@"StudyID"];
						break;
					default:
						attrTag = nil;				
						break;
				}
			if (DEBUG)
				NSLog(@"Anonymize tag:%@", [attrTag description]);
				
			if (attrTag)
			{
				id replacement;
				if ([cell tag] % 4 == 0)
					replacement = [[firstColumnValues cellWithTag:[cell tag]] objectValue];
				else
					replacement = [[secondColumnValues cellWithTag:[cell tag]] objectValue];
					
				if ([replacement isKindOfClass:[NSString class]])
				{
					if( [(NSString*) replacement length] <= 0) 
						replacement = nil;
				}
				
				if ([replacement isKindOfClass:[NSDate class]])
				{
					replacement = [NSCalendarDate dateWithTimeIntervalSince1970: [replacement timeIntervalSince1970]];
				}
				
				NSArray *array = [NSArray arrayWithObjects: attrTag, replacement, nil];
				
				[tags addObject:array];
			}
		}
	}
	return tags;
}

- (IBAction)matrixAction:(id)sender
{
	int tag = [(NSCell *)[(NSMatrix *)sender selectedCell] tag];
	
	if (tag % 4 == 0)
	{
		[[firstColumnValues cellWithTag:tag] setEnabled:[[sender selectedCell] state]];
		if( [[sender selectedCell] state] == NSOffState) [[firstColumnValues cellWithTag:tag] setStringValue:@""];
		else
		{
			switch( tag)
			{
				case 12:
				case 20:
				case 24:
				case 28:
				case 32:
				case 36:
				case 40:
				case 44:
					[[firstColumnValues cellWithTag:tag] setStringValue: [[[firstColumnValues cellWithTag:tag] formatter] stringForObjectValue: [NSDate date]]];
				break;
			}
		}
	}
	else
	{
		[[secondColumnValues cellWithTag:tag] setEnabled:[[sender selectedCell] state]];
		if( [[sender selectedCell] state] == NSOffState) [[secondColumnValues cellWithTag:tag] setStringValue:@""];
	}
}


@end
