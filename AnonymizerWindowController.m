/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/***************************************** Modifications *********************************************

Version 2.3
	20060123	LP	Added more editable anonymize options
	20060123	LP	Added option to create directories
	
**************/



#import "AnonymizerWindowController.h"
#import <OsiriX/DCM.h>
#import "Wait.h"
//#import "ButtonAndTextField.h"
#import "ButtonAndTextCell.h"

@implementation AnonymizerWindowController

-(id) init{
	if (self = [super initWithWindowNibName:@"Anonymize"]) {
		tags = [[NSMutableArray array] retain];
		//[ButtonAndTextField setCellClass:[ButtonAndTextCell class]];
	}
    return self;
}

- (void)dealloc {
	[filesToAnonymize release];
	[dcmObjects release];
	[tagMatrixfirstColumn release];
	[tagMatrixsecondColumn release];
	[accessoryView release];
	[super dealloc];
}

- (void)windowDidLoad{
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

- (IBAction) anonymize:(id)sender
{
	long i;
	NSOpenPanel		*sPanel		= [NSOpenPanel openPanel];
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
		
		Wait *splash = [[Wait alloc] initWithString:@"Anonymize..."];
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesToAnonymize count]];
		
		if (DEBUG)
			NSLog(@"file Count: %d", [filesToAnonymize count]);
			
		NSString *file;
		NSManagedObject *dcm;
		
		for( i = 0; i < [filesToAnonymize count]; i++)
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
			
			//DCMObject *dcm = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
			//NSXMLDocument *xmlDoc = [dcm xmlDocument];
			//NSString *dst = [NSString stringWithFormat:@"%@/Desktop/%@", NSHomeDirectory(), @"test.xml"];
			//NSLog(dst);
			//if([[xmlDoc  XMLData] writeToFile:dst atomically:YES])
			//	NSLog(@"Wrote xml");
			[DCMObject anonymizeContentsOfFile:file  tags:[self tags]  writingToFile:dest];
			[pool release];
			[splash incrementBy:1];
		}
		
		[splash close];
		[splash release];
		
	}
	[sPanel setMessage:@""];
	[[self window] close];
	[filesToAnonymize release];
	filesToAnonymize = nil;
	[dcmObjects release];
	dcmObjects = 0L;
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
	while (cell = [enumerator nextObject]) {
		if (DEBUG)
			NSLog(@"Matrix cell: %@", [cell title]);
			if ([cell state] == NSOnState) { 
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
					default:
						attrTag = nil;				
						break;
				}
			if (DEBUG)
				NSLog(@"Anonymize tag:%@", [attrTag description]);
			if (attrTag) {
				id replacement;
				if ([cell tag] % 4 == 0)
					replacement = [[firstColumnValues cellWithTag:[cell tag]] objectValue];
				else
					replacement = [[secondColumnValues cellWithTag:[cell tag]] objectValue];
				if ([replacement length] <= 0) {
					//NSLog(@"Replacement Length: %d", [replacement length]);
					replacement = nil;
			//
				}
				NSArray *array = [NSArray arrayWithObjects: attrTag, replacement, nil];
				//NSLog(@"object: %@ Value: %@", [replacement description], NSStringFromClass([replacement class]));
				//NSLog(@"Replacement tags: %@", [array description]);
				[tags addObject:array];
			}
		}
	}
	return tags;
}

- (IBAction)matrixAction:(id)sender{
	int tag = [(NSCell *)[(NSMatrix *)sender selectedCell] tag];
	if (tag % 4 == 0)
		[[firstColumnValues cellWithTag:tag] setEnabled:[[sender selectedCell] state]];
	else
		[[secondColumnValues cellWithTag:tag] setEnabled:[[sender selectedCell] state]];
}


@end
