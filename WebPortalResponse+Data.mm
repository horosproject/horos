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

#import "WebPortalResponse+Data.h"
#import "DicomAlbum.h"
#import "DicomDatabase.h"
#import "WebPortalUser.h"
#import "WebPortalSession.h"
#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "AsyncSocket.h"
#import "WebPortalDatabase.h"
#import "WebPortal+Databases.h"
#import "WebPortalConnection.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSString+N2.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "WebPortalStudy.h"
#import "DicomImage.h"
#import "DCMTKStoreSCU.h"



#import "BrowserController.h" // TODO: remove when badness solved



static NSTimeInterval StartOfDay(NSCalendarDate* day) {
	NSCalendarDate* start = [NSCalendarDate dateWithYear:day.yearOfCommonEra month:day.monthOfYear day:day.dayOfMonth hour:0 minute:0 second:0 timeZone:NULL];
	return start.timeIntervalSinceReferenceDate;
}



@implementation WebPortalResponse (Data)

+(NSArray*)MakeArray:(id)obj {
	if ([obj isKindOfClass:[NSArray class]])
		return obj;
	
	if (obj == nil)
		return [NSArray array];
	
	return [NSArray arrayWithObject:obj];
}

-(NSArray*)studyList_studiesForUser:(WebPortalUser*)user outTitle:(NSString**)title {
	NSString* ignore = NULL;
	if (!title) title = &ignore;
	
	NSString* albumReq = [wpc.parameters objectForKey:@"album"];
	if (albumReq.length) {
		*title = [NSString stringWithFormat:NSLocalizedString(@"%@", @"Web portal, study list, title format (%@ is album name)"), albumReq];
		return [portal studiesForUser:user album:albumReq sortBy:[wpc.parameters objectForKey:@"order"]];
	}
	
	NSString* browseReq = [wpc.parameters objectForKey:@"browse"];
	NSString* browseParameterReq = [wpc.parameters objectForKey:@"browseParameter"];
	
	NSPredicate* browsePredicate = NULL;
	
	if ([browseReq isEqual:@"newAddedStudies"] && browseParameterReq.doubleValue > 0)
	{
		*title = NSLocalizedString( @"New Available Studies", @"Web portal, study list, title");
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
				if ([wpc.parameters objectForKey:@"search"])
				{
					*title = NSLocalizedString(@"Search Results", @"Web portal, study list, title");
					
					NSMutableString* search = [NSMutableString string];
					NSString *searchString = [wpc.parameters objectForKey:@"search"];
					
					NSArray* components = [searchString componentsSeparatedByString:@" "];
					NSMutableArray *newComponents = [NSMutableArray array];
					for (NSString *comp in components)
					{
						if (![comp isEqualToString:@""])
							[newComponents addObject:comp];
					}
					
					searchString = [newComponents componentsJoinedByString:@" "];
					
					[search appendFormat:@"name CONTAINS[cd] '%@'", searchString]; // [c] is for 'case INsensitive' and [d] is to ignore accents (diacritic)
					browsePredicate = [NSPredicate predicateWithFormat:search];
				}
				else
					if ([wpc.parameters objectForKey:@"searchID"])
					{
						*title = NSLocalizedString(@"Search Results", @"Web portal, study list, title");
						NSMutableString *search = [NSMutableString string];
						NSString *searchString = [NSString stringWithString:[wpc.parameters objectForKey:@"searchID"]];
						
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
						if ([wpc.parameters objectForKey:@"searchAccessionNumber"])
						{
							*title = NSLocalizedString(@"Search Results", @"Web portal, study list, title");
							NSMutableString *search = [NSMutableString string];
							NSString *searchString = [NSString stringWithString:[wpc.parameters objectForKey:@"searchAccessionNumber"]];
							
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
		browsePredicate = [NSPredicate predicateWithValue:YES];
	}	
	
	return [portal studiesForUser:user predicate:browsePredicate sortBy:[wpc.parameters objectForKey:@"order"]];
}


-(DicomSeries*)series_seriesForUser:(WebPortalUser*)user {
	NSPredicate* browsePredicate;
	
	if ([wpc.parameters objectForKey:@"id"]) {
		if ([wpc.parameters objectForKey:@"studyID"])
			browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [wpc.parameters objectForKey:@"studyID"], [wpc.parameters objectForKey:@"id"]];
		else browsePredicate = [NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", [wpc.parameters objectForKey:@"id"]];
	} else
		return NULL;
	
	NSArray* series = [portal seriesForUser:user predicate:browsePredicate];
	if (series.count)
		return series.lastObject;
	
	return NULL;
}

-(void)sendImages:(NSArray*)images toDicomNode:(NSDictionary*)dicomNodeDescription {
	[portal updateLogEntryForStudy: [[images lastObject] valueForKeyPath: @"series.study"] withMessage: [NSString stringWithFormat: @"DICOM Send to: %@", [dicomNodeDescription objectForKey:@"Address"]] forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
	
	@try {
		NSDictionary* todo = [NSDictionary dictionaryWithObjectsAndKeys: [dicomNodeDescription objectForKey:@"Address"], @"Address", [dicomNodeDescription objectForKey:@"TransferSyntax"], @"TransferSyntax", [dicomNodeDescription objectForKey:@"Port"], @"Port", [dicomNodeDescription objectForKey:@"AETitle"], @"AETitle", [images valueForKey: @"completePath"], @"Files", nil];
		[NSThread detachNewThreadSelector:@selector(dicomSendThread:) toTarget:self withObject:todo];
	} @catch (NSException* e) {
		NSLog( @"Error: [WebPortalConnection sendImages:toDicomNode:] %@", e);
	}	
}

- (void)sendImagesToDicomNodeThread:(NSDictionary*)todo;
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[wpc.session.sendLock lock];
	@try {
		[[[[DCMTKStoreSCU alloc] initWithCallingAET:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
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
		[wpc.session.sendLock unlock];
		[pool release];
	}
}

-(NSArray*)seriesSortDescriptors {
	return NULL; // TODO: update&return session series sort keys
}



#pragma mark HTML

-(void)processLoginHtml {
	self.templateString = [portal stringForPath:@"login.html"];
}

-(void)processIndexHtml {
	self.templateString = [portal stringForPath:@"index.html"];
}

-(void)processMainHtml {
//	if (!wpc.user || wpc.user.uploadDICOM.boolValue)
//		[self supportsPOST:NULL withSize:0];
	
	NSMutableArray* albums = [NSMutableArray array];
	for (NSArray* album in [[BrowserController currentBrowser] albumArray]) // TODO: badness here
		if (![[album valueForKey:@"name"] isEqualToString:NSLocalizedString(@"Database", nil)])
			[albums addObject:album];
	[self.tokens setObject:albums forKey:@"Albums"];

	self.templateString = [portal stringForPath:@"main.html"];
}

-(void)processStudyHtml {
	NSArray* studies = NULL;
	NSString* studyId = [wpc.parameters objectForKey:@"id"];
	if (studyId)
		studies = [portal studiesForUser:wpc.user predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyId] sortBy:NULL];
	DicomStudy* study = studies.count == 1 ? [studies objectAtIndex:0] : NULL;
	if (!study)
		[self.tokens addError:NSLocalizedString(@"Invalid study selection.", @"Web Portal, study, error")];
	
	NSMutableArray* selectedSeries = [NSMutableArray array];
	for (NSString* selectedID in [WebPortalResponse MakeArray:[wpc.parameters objectForKey:@"selected"]])
		[selectedSeries addObjectsFromArray:[portal seriesForUser:wpc.user predicate:[NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", studyId, selectedID]]];
	
	NSString* action = [wpc.parameters objectForKey:@"action"];
	
	if ([action isEqual:@"dicomSend"] && study) {
		NSArray* dicomDestinationArray = [[wpc.parameters objectForKey:@"dicomDestination"] componentsSeparatedByString:@":"];
		if (dicomDestinationArray.count >= 4) {
			NSMutableDictionary* dicomDestination = [NSMutableDictionary dictionary];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:0] forKey:@"Address"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:1] forKey:@"Port"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:2] forKey:@"AETitle"];
			[dicomDestination setObject:[dicomDestinationArray objectAtIndex:3] forKey:@"TransferSyntax"];
			
			NSMutableArray* selectedImages = [NSMutableArray array];
			for (NSString* selectedID in [WebPortalResponse MakeArray:[wpc.parameters objectForKey:@"selected"]])
				for (DicomSeries* series in [portal seriesForUser:wpc.user predicate:[NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", studyId, selectedID]])
					[selectedImages addObjectsFromArray:series.images.allObjects];
			
			if (selectedImages.count) {
				[self sendImages:selectedImages toDicomNode:dicomDestination];
				[self.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Dicom send to node %@ initiated.", @"Web Portal, study, dicom send, success"), [dicomDestination objectForKey:@"AETitle"]]];
			} else
				[self.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Dicom send failed: no images selected. Select one or more series.", @"Web Portal, study, dicom send, error")]];
		} else
			[self.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Dicom send failed: cannot identify node.", @"Web Portal, study, dicom send, error")]];
	}
	
	if ([action isEqual:@"shareStudy"] && study) {
		NSString* destUserName = [wpc.parameters objectForKey:@"shareStudyUser"];
		// find this user
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [portal.database entityForName:@"User"];
		req.predicate = [NSPredicate predicateWithFormat: @"name == %@", destUserName];
		NSArray* users = [portal.database.managedObjectContext executeFetchRequest:req error:NULL];
		if (users.count == 1) {
			// add study to specific study list for this user
			WebPortalUser* destUser = users.lastObject;
			if (![[destUser.studies.allObjects valueForKey:@"study"] containsObject:study]) {
				WebPortalStudy* wpStudy = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:portal.database.managedObjectContext];
				wpStudy.user = destUser;
				wpStudy.patientUID = study.patientUID;
				wpStudy.studyInstanceUID = study.studyInstanceUID;
				wpStudy.dateAdded = [NSDate dateWithTimeIntervalSinceReferenceDate:[[NSUserDefaults standardUserDefaults] doubleForKey:@"lastNotificationsDate"]];
				[portal.database save:NULL];
			}
			
			// Send the email
			[portal sendNotificationsEmailsTo: users aboutStudies:[NSArray arrayWithObject:study] predicate:NULL message:[N2NonNullString([wpc.parameters objectForKey:@"message"]) stringByAppendingFormat: @"\r\r\r%@\r\r%%URLsList%%", NSLocalizedString( @"To view this study, click on the following link:", nil)] replyTo:wpc.user.email customText:nil webServerAddress:wpc.portalAddress];
			[portal updateLogEntryForStudy: study withMessage: [NSString stringWithFormat: @"Share Study with User: %@", destUserName] forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
			
			[tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"This study is now shared with <b>%@</b>.", @"Web Portal, study, share, ok (%@ is destUser.name)"), destUserName]];
		} else
			[self.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Study share failed: cannot identify user.", @"Web Portal, study, share, error")]];
	}
	
	[self.tokens setObject:[WebPortalProxy createWithObject:study transformer:DicomStudyTransformer.create] forKey:@"Study"];
	[self.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"%@", @"Web Portal, study, title format (%@ is study.name)"), study.name] forKey:@"PageTitle"];
	
	if (study) {
		[portal updateLogEntryForStudy:study withMessage:@"Browsing Study" forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
		
		[portal.dicomDatabase.managedObjectContext lock];
		@try {
			[self.tokens setObject:wpc.requestIsMacOS?@"osirixzip":@"zip" forKey:@"zipextension"];
			
			
			
			//	[templateString replaceOccurrencesOfString:@"%browse%" withString:browse];
		//	[templateString replaceOccurrencesOfString:@"%browseParameter%" withString:browseParameter];
		//	[templateString replaceOccurrencesOfString:@"%search%" withString:search];
		//	[templateString replaceOccurrencesOfString:@"%album%" withString:album];
			
			NSString* browse = [wpc.parameters objectForKey:@"browse"];
			NSString* browseParameter = [wpc.parameters objectForKey:@"browseParameter"];
			NSString* search = [wpc.parameters objectForKey:@"search"];
			NSString* album = [wpc.parameters objectForKey:@"album"];
			NSString* studyListLinkLabel = NSLocalizedString(@"Study list", nil);
			if (search.length)
				studyListLinkLabel = [NSString stringWithFormat:NSLocalizedString(@"Search results for: %@", nil), search];
			else if (album.length)
				studyListLinkLabel = [NSString stringWithFormat:NSLocalizedString(@"Album: %@", nil), album];
			else if ([browse isEqualToString:@"6hours"])
				studyListLinkLabel = NSLocalizedString(@"Last 6 Hours", nil);
			else if ([browse isEqualToString:@"today"])
				studyListLinkLabel = NSLocalizedString(@"Today", nil);
			[self.tokens setObject:studyListLinkLabel forKey:@"BackLinkLabel"];
			
			/*if ([[study valueForKey:@"reportURL"] hasPrefix: @"http://"] || [[study valueForKey:@"reportURL"] hasPrefix: @"https://"])
			{
				[WebPortalResponse mutableString:templateString block:@"Report" setVisible:NO];
				[WebPortalResponse mutableString:templateString block:@"ReportURL" setVisible:NO];
				
				[templateString replaceOccurrencesOfString:@"%ReportURLString%" withString:N2NonNullString([study valueForKey:@"reportURL"])];
			}
			else
			{
				[WebPortalResponse mutableString:templateString block:@"ReportURL" setVisible:NO];
				[WebPortalResponse mutableString:templateString block:@"Report" setVisible:([study valueForKey:@"reportURL"] && ![[settings valueForKey:@"iPhone"] boolValue])];
				
				if ([[[study valueForKey:@"reportURL"] pathExtension] isEqualToString: @"pages"])
					[templateString replaceOccurrencesOfString:@"%reportExtension%" withString:N2NonNullString(@"zip")];
				else
					[templateString replaceOccurrencesOfString:@"%reportExtension%" withString:N2NonNullString([[study valueForKey:@"reportURL"] pathExtension])];
			}
			*/
			
			//NSArray *tempArray = [templateString componentsSeparatedByString:@"%SeriesListItem%"];
			/*NSString *templateStringStart = [tempArray objectAtIndex:0];
			tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/SeriesListItem%"];
			NSString *seriesListItemString = [tempArray objectAtIndex:0];
			NSString *templateStringEnd = [tempArray lastObject];*/
			
			//returnHTML = [NSMutableString stringWithString: templateStringStart];
			
			//[returnHTML replaceOccurrencesOfString:@"%PatientID%" withString:N2NonNullString([study valueForKey:@"patientID"])];
			//[returnHTML replaceOccurrencesOfString:@"%PatientName%" withString:N2NonNullString([study valueForKey:@"name"])];
			//[returnHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:N2NonNullString([study valueForKey:@"studyName"])];
			//[returnHTML replaceOccurrencesOfString:@"%StudyModality%" withString:N2NonNullString([study valueForKey:@"modality"])];
			
			/*if (![study valueForKey:@"comment"])
				[WebPortalResponse mutableString:returnHTML block:@"StudyCommentBlock" setVisible:NO];
			else
			{
				[WebPortalResponse mutableString:returnHTML block:@"StudyCommentBlock" setVisible:YES];
				[returnHTML replaceOccurrencesOfString:@"%StudyComment%" withString:N2NonNullString([study valueForKey:@"comment"])];
			}*/
			
			/*NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[study valueForKey:@"stateText"] intValue]];
			if ([[study valueForKey:@"stateText"] intValue] == 0)
				stateText = nil;
			
			if (!stateText)
				[WebPortalResponse mutableString:returnHTML block:@"StudyStateBlock" setVisible:NO];
			else
			{
				[WebPortalResponse mutableString:returnHTML block:@"StudyStateBlock" setVisible:YES];
				[returnHTML replaceOccurrencesOfString:@"%StudyState%" withString:N2NonNullString(stateText)];
			}*/
			
//			NSDateFormatter *dobDateFormat = [[[NSDateFormatter alloc] init] autorelease];
//			[dobDateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateOfBirthFormat2"]];
			//NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
			//[dateFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
			
			//[returnHTML replaceOccurrencesOfString:@"%PatientDOB%" withString:N2NonNullString([dobDateFormat stringFromDate:[study valueForKey:@"dateOfBirth"]])];
			//[returnHTML replaceOccurrencesOfString:@"%AccessionNumber%" withString:N2NonNullString([study valueForKey:@"accessionNumber"])];
			//[returnHTML replaceOccurrencesOfString:@"%StudyDate%" withString: [WebPortalConnection iPhoneCompatibleNumericalFormat: [dateFormat stringFromDate: [study valueForKey:@"date"]]]];
			
			//NSArray *seriesArray = [study valueForKey:@"imageSeries"];
			
			/*NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
			NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
			NSArray * sortDescriptors;
			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
			[sortid release];
			[sortdate release];*/
			
			NSMutableArray* seriesArray = [NSMutableArray array];
			for (DicomSeries* s in [study.imageSeries sortedArrayUsingDescriptors:[self seriesSortDescriptors]])
				[seriesArray addObject:[WebPortalProxy createWithObject:s transformer:[DicomSeriesTransformer create]]];
			[self.tokens setObject:seriesArray forKey:@"Series"];
			
				
				//[tempHTML replaceOccurrencesOfString:@"%SeriesName%" withString:N2NonNullString(series.name)];
				//[tempHTML replaceOccurrencesOfString:@"%thumbnail%" withString: [NSString stringWithFormat:@"thumbnail?id=%@&studyID=%@", N2NonNullString([series valueForKey:@"seriesInstanceUID"]), N2NonNullString([study valueForKey:@"studyInstanceUID"])]];
				//[tempHTML replaceOccurrencesOfString:@"%SeriesID%" withString:N2NonNullString(series.seriesInstanceUID)];
				//[tempHTML replaceOccurrencesOfString:@"%SeriesComment%" withString:N2NonNullString([series valueForKey:@"comment"])];
				//[tempHTML replaceOccurrencesOfString:@"%PatientName%" withString:N2NonNullString(series.study.name)];
				
				/*if ([DCMAbstractSyntaxUID isPDF: [series valueForKey: @"seriesSOPClassUID"]])
					[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @".pdf"];
				else if ([DCMAbstractSyntaxUID isStructuredReport: [series valueForKey: @"seriesSOPClassUID"]])
					[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @".pdf"];
				else
					[tempHTML replaceOccurrencesOfString:@"%seriesExtension%" withString: @""];*/
				
				/*NSString *stateText = [[BrowserController statesArray] objectAtIndex: [[series valueForKey: @"stateText"] intValue]];
				if ([[series valueForKey:@"stateText"] intValue] == 0)
					stateText = nil;
				[tempHTML replaceOccurrencesOfString:@"%SeriesState%" withString:N2NonNullString(stateText)];*/
				
				/*t nbFiles = series.noFiles.intValue;
				if (nbFiles == 0)
					nbFiles = 1;
				NSString *imagesLabel = (nbFiles!=1)? NSLocalizedString(@"Images", nil) : NSLocalizedString(@"Image", nil);
				[tempHTML replaceOccurrencesOfString:@"%SeriesImageNumber%" withString: [NSString stringWithFormat:@"%d %@", nbFiles, imagesLabel]];
				*/
			/*	NSString *comment = [series valueForKey:@"comment"];
				if (comment == nil)
					comment = @"";
				[tempHTML replaceOccurrencesOfString:@"%SeriesComment%" withString: comment];*/
				
				
				/*NSString *checked = @"";
				for (NSString* selectedID in [parameters objectForKey:@"selected"])
				{
					if ([[series valueForKey:@"seriesInstanceUID"] isEqualToString:[selectedID stringByReplacingOccurrencesOfString:@"+" withString:@" "]])
						checked = @"checked";
				}*/
				
				/*[tempHTML replaceOccurrencesOfString:@"%checked%" withString:N2NonNullString(checked)];*/
				
				//[returnHTML appendString:tempHTML];
			//}
			
			//NSMutableString *tempHTML = [NSMutableString stringWithString:templateStringEnd];
			//[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2]];
			//templateStringEnd = [NSString stringWithString:tempHTML];
			
			/*NSString *checkAllStyle = @"";
			if ([seriesArray count]<=1) checkAllStyle = @"style='display:none;'";
			[returnHTML replaceOccurrencesOfString:@"%CheckAllStyle%" withString:N2NonNullString(checkAllStyle)];*/
			
			/*BOOL checkAllChecked = [[parameters objectForKey:@"CheckAll"] isEqualToString:@"on"] || [[parameters objectForKey:@"CheckAll"] isEqualToString:@"checked"];
			[returnHTML replaceOccurrencesOfString:@"%CheckAllChecked%" withString: checkAllChecked? @"checked=\"checked\"" : @""];
			*/
			
			NSMutableArray* dicomDestinations = [NSMutableArray array];
			if (!wpc.user || wpc.user.sendDICOMtoSelfIP.boolValue) {
				
				if (!wpc.user || wpc.user.sendDICOMtoAnyNodes.boolValue) {
					
				}
			}
			[self.tokens setObject:dicomDestinations forKey:@"DicomDestinations"];

			/*
			
			NSString *dicomNodesListItemString = @"";
			if (dicomSend)
			{
				tempArray = [templateStringEnd componentsSeparatedByString:@"%dicomNodesListItem%"];
				templateStringStart = [tempArray objectAtIndex:0];
				tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/dicomNodesListItem%"];
				dicomNodesListItemString = [tempArray objectAtIndex:0];
				templateStringEnd = [tempArray lastObject];
				[returnHTML appendString:templateStringStart];
				
				BOOL selectedDone = NO;
				
				if (wpc.user == nil || wpc.user.sendDICOMtoSelfIP.boolValue)
				{
					NSString *dicomNodeAddress = [asyncSocket connectedHost];
					NSString *dicomNodeAETitle = @"This Computer";
					
					NSString *dicomNodeSyntax;
					if ([[settings valueForKey:@"iPhone"] boolValue]) dicomNodeSyntax = @"5";
					else dicomNodeSyntax = @"0";
					NSString *dicomNodeDescription = @"This Computer";
					
					NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:N2NonNullString(dicomNodeAddress)];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:N2NonNullString(self.dicomCStorePortString)];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:N2NonNullString(dicomNodeAETitle)];
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:N2NonNullString(dicomNodeSyntax)];
					
					if (![[settings valueForKey:@"iPhone"] boolValue])
						dicomNodeDescription = [dicomNodeDescription stringByAppendingFormat:@" [%@:%@]", N2NonNullString(dicomNodeAddress), N2NonNullString(self.dicomCStorePortString)];
					
					[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:N2NonNullString(dicomNodeDescription)];
					
					NSString *selected = @"";
					
					if ([parameters objectForKey:@"dicomDestination"])
					{
						NSString * s = [parameters objectForKey:@"dicomDestination"];
						
						NSArray *sArray = [s componentsSeparatedByString: @":"];
						
						if ([sArray count] >= 2)
						{
							if ([[sArray objectAtIndex: 0] isEqualToString: dicomNodeAddress] && [[sArray objectAtIndex: 1] isEqualToString:self.dicomCStorePortString])
							{
								selected = @"selected";
								selectedDone = YES;
							}
						}
					}
					
					[tempHTML replaceOccurrencesOfString:@"%selected%" withString:N2NonNullString(selected)];
					
					[returnHTML appendString:tempHTML];
				}
				
				if (wpc.user == nil || wpc.user.sendDICOMtoAnyNodes.boolValue)
				{
					NSArray *nodes = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
					
					for (NSDictionary *node in nodes)
					{
						NSString *dicomNodeAddress = N2NonNullString([node objectForKey:@"Address"]);
						NSString *dicomNodePort = [NSString stringWithFormat:@"%d", [[node objectForKey:@"Port"] intValue]];
						NSString *dicomNodeAETitle = N2NonNullString([node objectForKey:@"AETitle"]);
						NSString *dicomNodeSyntax = [NSString stringWithFormat:@"%d", [[node objectForKey:@"TransferSyntax"] intValue]];
						NSString *dicomNodeDescription = N2NonNullString([node objectForKey:@"Description"]);
						
						NSMutableString *tempHTML = [NSMutableString stringWithString:dicomNodesListItemString];
						[tempHTML replaceOccurrencesOfString:@"%dicomNodeAddress%" withString:N2NonNullString(dicomNodeAddress)];
						[tempHTML replaceOccurrencesOfString:@"%dicomNodePort%" withString:N2NonNullString(dicomNodePort)];
						[tempHTML replaceOccurrencesOfString:@"%dicomNodeAETitle%" withString:N2NonNullString(dicomNodeAETitle)];
						[tempHTML replaceOccurrencesOfString:@"%dicomNodeSyntax%" withString:N2NonNullString(dicomNodeSyntax)];
						
						if (![[settings valueForKey:@"iPhone"] boolValue])
							dicomNodeDescription = [dicomNodeDescription stringByAppendingFormat:@" [%@:%@]", N2NonNullString(dicomNodeAddress), N2NonNullString(dicomNodePort)];
						
						[tempHTML replaceOccurrencesOfString:@"%dicomNodeDescription%" withString:N2NonNullString(dicomNodeDescription)];
						
						NSString *selected = @"";
						
						if ([parameters objectForKey:@"dicomDestination"] && selectedDone == NO)
						{
							NSString * s = [parameters objectForKey:@"dicomDestination"];
							
							NSArray *sArray = [s componentsSeparatedByString: @":"];
							
							if ([sArray count] >= 2)
							{
								if ([[sArray objectAtIndex: 0] isEqualToString: dicomNodeAddress] && [[sArray objectAtIndex: 1] isEqualToString: dicomNodePort])
								{
									selected = @"selected";
									selectedDone = YES;
								}
							}
						}
						
						[tempHTML replaceOccurrencesOfString:@"%selected%" withString:N2NonNullString(selected)];
						
						[returnHTML appendString:tempHTML];
					}
				}
				
				[returnHTML appendString:templateStringEnd];
			}
			else [returnHTML appendString:templateStringEnd];*/
			
			NSMutableArray* shareDestinations = [NSMutableArray array];
			if (!wpc.user || wpc.user.shareStudyWithUser.boolValue) {
				
			}
			[self.tokens setObject:shareDestinations forKey:@"ShareDestinations"];
			
			
			/*if (shareSend)
			{
				tempArray = [returnHTML componentsSeparatedByString:@"%userListItem%"];
				templateStringStart = [tempArray objectAtIndex:0];
				
				tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/userListItem%"];
				NSString *userListItemString = [tempArray objectAtIndex:0];
				
				templateStringEnd = [tempArray lastObject];
				
				returnHTML = [NSMutableString stringWithString: templateStringStart];
				
				@try
				{
					NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
					req.entity = [self.portal.database entityForName:@"User"];
					req.predicate = [NSPredicate predicateWithValue:YES];
					NSArray* users = [[self.portal.database.managedObjectContext countForFetchRequest:req error:NULL] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]];
					
					for ( NSManagedObject *user in users)
					{
						if (user != wpc.user)
						{
							NSMutableString *tempHTML = [NSMutableString stringWithString: userListItemString];
							
							[tempHTML replaceOccurrencesOfString:@"%username%" withString:N2NonNullString([user valueForKey: @"name"])];
							[tempHTML replaceOccurrencesOfString:@"%email%" withString:N2NonNullString([user valueForKey: @"email"])];
							
							NSString *userDescription = [NSString stringWithString:N2NonNullString([user valueForKey:@"name"])];
							if (![[settings valueForKey:@"iPhone"] boolValue])
								userDescription = [userDescription stringByAppendingFormat:@" (%@)", N2NonNullString([user valueForKey:@"email"])];
							
							[tempHTML replaceOccurrencesOfString:@"%userDescription%" withString:N2NonNullString(userDescription)];
							
							[returnHTML appendString: tempHTML];
						}
					}
				}
				@catch (NSException *e)
				{
					NSLog( @"****** exception in find all users htmlStudy: %@", e);
				}
				
				[returnHTML appendString: templateStringEnd];
			}*/
		} @catch (NSException* e) {
			NSLog(@"Error: [WebPortalResponse processStudyHtml:] %@", e);
		} @finally {
			[portal.dicomDatabase.managedObjectContext unlock];
		}
		
	}
		
		
		
		
			
	
	
	
	
	
	
	self.templateString = [portal stringForPath:@"study.html"];
}








-(void)processStudyListHtml {
	/*NSString* title = NULL;
	[self.tokens setObject:[self studyList_studiesForUser:wpc.user outTitle:&title] forKey:@"Studies"]	
	if (title) [self.tokens setObject:title forKey:@"PageTitle"];
	
	
	{
		[self.portal.dicomDatabase.managedObjectContext lock];
		
		NSMutableString *returnHTML = nil;
		
		@try
		{
			NSMutableString *templateString = [self webServicesHTMLMutableString:@"studyList.html"];
			
			[WebPortalResponse mutableString:templateString block:@"ZIPFunctions" setVisible:(wpc.user && wpc.user.downloadZIP.boolValue && ![[settings valueForKey:@"iPhone"] boolValue])];
			[WebPortalResponse mutableString:templateString block:@"Weasis" setVisible:(NSUserDefaults.webPortalUsesWeasis && ![[settings valueForKey:@"iPhone"] boolValue])];
			
			[templateString replaceOccurrencesOfString:@"%zipextension%" withString: ([[settings valueForKey:@"MacOS"] boolValue]?@"osirixzip":@"zip")];
			
			NSArray *tempArray = [templateString componentsSeparatedByString:@"%StudyListItem%"];
			NSString *templateStringStart = [tempArray objectAtIndex:0];
			tempArray = [[tempArray lastObject] componentsSeparatedByString:@"%/StudyListItem%"];
			NSString *studyListItemString = [tempArray objectAtIndex:0];
			NSString *templateStringEnd = [tempArray lastObject];
			
			returnHTML = [NSMutableString stringWithString:templateStringStart];
			
			int lineNumber = 0;
			for (DicomStudy *study in studies)
			{
				NSMutableString *tempHTML = [NSMutableString stringWithString:studyListItemString];
				
				[tempHTML replaceOccurrencesOfString:@"%lineParity%" withString:[NSString stringWithFormat:@"%d",lineNumber%2]];
				lineNumber++;
				
				// filenameString?
				[tempHTML replaceOccurrencesOfString:@"%StudyListItemName%" withString:N2NonNullString([study valueForKey:@"name"])];
				
				NSArray *seriesArray = [study valueForKey:@"imageSeries"] ; //imageSeries
				int count = 0;
				for (DicomSeries *series in seriesArray)
				{
					count++;
				}
				
				NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
				[dateFormat setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat2"]];
				
				NSString *date = [dateFormat stringFromDate:[study valueForKey:@"date"]];
				
				NSString *dateLabel = [NSString stringWithFormat:@"%@", [WebPortalConnection iPhoneCompatibleNumericalFormat:date]];
				dateLabel = [WebPortalConnection unbreakableStringWithString:dateLabel];
				BOOL displayBlock = YES;
				if ([dateLabel length])
					[tempHTML replaceOccurrencesOfString:@"%StudyDate%" withString:dateLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"StudyDateBlock" setVisible:displayBlock];
				
				NSString *seriesCountLabel = [NSString stringWithFormat:@"%d Series", count];
				displayBlock = YES;
				if ([seriesCountLabel length])
					[tempHTML replaceOccurrencesOfString:@"%SeriesCount%" withString:seriesCountLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"SeriesCountBlock" setVisible:displayBlock];
				
				NSString *patientIDLabel = [NSString stringWithFormat:@"%@", N2NonNullString([study valueForKey:@"patientID"])];
				displayBlock = YES;
				if ([patientIDLabel length])
					[tempHTML replaceOccurrencesOfString:@"%PatientID%" withString:patientIDLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"PatientIDBlock" setVisible:displayBlock];
				
				NSString *accessionNumberLabel = [NSString stringWithFormat:@"%@", N2NonNullString([study valueForKey:@"accessionNumber"])];
				displayBlock = YES;
				if ([accessionNumberLabel length])
					[tempHTML replaceOccurrencesOfString:@"%AccessionNumber%" withString:accessionNumberLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"AccessionNumberBlock" setVisible:displayBlock];
				
				NSString *studyCommentLabel = N2NonNullString([study valueForKey:@"comment"]);
				displayBlock = YES;
				if ([studyCommentLabel length])
					[tempHTML replaceOccurrencesOfString:@"%StudyComment%" withString:studyCommentLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"StudyCommentBlock" setVisible:displayBlock];
				
				NSString *studyDescriptionLabel = N2NonNullString([study valueForKey:@"studyName"]);
				displayBlock = YES;
				if ([studyDescriptionLabel length])
					[tempHTML replaceOccurrencesOfString:@"%StudyDescription%" withString:studyDescriptionLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"StudyDescriptionBlock" setVisible:displayBlock];
				
				NSString *studyModalityLabel = N2NonNullString([study valueForKey:@"modality"]);
				displayBlock = YES;
				if ([studyModalityLabel length])
					[tempHTML replaceOccurrencesOfString:@"%StudyModality%" withString:studyModalityLabel];
				else
					displayBlock = NO;
				[WebPortalResponse mutableString:tempHTML block:@"StudyModalityBlock" setVisible:displayBlock];
				
				NSString *stateText = @"";
				int v = [[study valueForKey:@"stateText"] intValue];
				if (v > 0 && v < [[BrowserController statesArray] count])
					stateText = [[BrowserController statesArray] objectAtIndex: v];
				
				NSString *studyStateLabel = N2NonNullString(stateText);
				displayBlock = YES;
				if ([studyStateLabel length])
					[tempHTML replaceOccurrencesOfString:@"%StudyState%" withString:studyStateLabel];
				else
					displayBlock = NO;
				
				[WebPortalResponse mutableString:tempHTML block:@"StudyStateBlock" setVisible:displayBlock];
				
				[tempHTML replaceOccurrencesOfString:@"%StudyListItemID%" withString:N2NonNullString([study valueForKey:@"studyInstanceUID"])];
				[returnHTML appendString:tempHTML];
			}
			
			[returnHTML appendString:templateStringEnd];
		}
		@catch (NSException *e)
		{
			NSLog( @"**** htmlStudyListForStudies exception: %@", e);
		}
		[self.portal.dicomDatabase.managedObjectContext unlock];
		
		return returnHTML;
	}
	
	
	self.templateString = [portal stringForPath:@"studyList.html"];*/
}






-(void)processSeriesHtml {
	/*DicomSeries* series = [self series_seriesForUser:wpc.user];
	
	NSArray *imagesArray = [[[series lastObject] valueForKey:@"images"] allObjects];
	
	NSMutableString *templateString = [self webServicesHTMLMutableString:@"series.html"];			
	[templateString replaceOccurrencesOfString:@"%StudyID%" withString:N2NonNullString([parameters objectForKey:@"studyID"])];
	[templateString replaceOccurrencesOfString:@"%SeriesID%" withString:N2NonNullString([parameters objectForKey:@"id"])];
	
	NSString *browse =  N2NonNullString([parameters objectForKey:@"browse"]);
	NSString *browseParameter =  N2NonNullString([parameters objectForKey:@"browseParameter"]);
	NSString *search =  N2NonNullString([parameters objectForKey:@"search"]);
	NSString *album = N2NonNullString([parameters objectForKey:@"album"]);
	
	[templateString replaceOccurrencesOfString:@"%browse%" withString:N2NonNullString(browse)];
	[templateString replaceOccurrencesOfString:@"%browseParameter%" withString:N2NonNullString(browseParameter)];
	[templateString replaceOccurrencesOfString:@"%search%" withString:search];
	[templateString replaceOccurrencesOfString:@"%album%" withString:album];
	
	// This is probably wrong... video/quictime, see Series.html
	// [templateString replaceOccurrencesOfString:@"%VideoType%" withString: isiPhone? @"video/x-m4v":@"video/x-mov"];
	[templateString replaceOccurrencesOfString:@"%MovieExtension%" withString: isIOS? @"m4v":@"mov"];
	
	[WebPortalResponse mutableString:templateString block:@"image" setVisible: [imagesArray count] == 1];
	[WebPortalResponse mutableString:templateString block:@"movie" setVisible: [imagesArray count] != 1];
	if ([imagesArray count] == 1)
	{
		[templateString replaceOccurrencesOfString:@"<!--[if !IE]>-->" withString:@""];
		[templateString replaceOccurrencesOfString:@"<!--<![endif]-->" withString:@""];
	}
	else
	{
		BOOL flash = NSUserDefaults.webPortalPrefersFlash && !isiPhone;
		[WebPortalResponse mutableString:templateString block:@"movieqt" setVisible:!flash];
		[WebPortalResponse mutableString:templateString block:@"moviefla" setVisible:flash];
		
		int width, height;
		
		[self getWidth: &width height:&height fromImagesArray: imagesArray isiPhone: isiPhone];
		
		height += 15; // quicktime controller height
		
		//NSLog(@"NEW w: %d, h: %d", width, height);
		[templateString replaceOccurrencesOfString:@"%width%" withString: [NSString stringWithFormat:@"%d", width]];
		[templateString replaceOccurrencesOfString:@"%height%" withString: [NSString stringWithFormat:@"%d", height]];
		
		// We will generate the movie now, if required... to avoid Quicktime plugin problem waiting for it. REMOVED
		//	[self produceMovieForSeries: [series lastObject] isiPhone: isiPhone fileURL:fileURL lockReleased: &lockReleased];
	}
	
	NSString *seriesName = N2NonNullString([[series lastObject] valueForKey:@"name"]);
	[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:[NSString stringWithFormat:NSLocalizedString(@"%@", @"Web portal, series, title format (%@ is series name)"), seriesName]];
	
	NSString *studyName = N2NonNullString([[series lastObject] valueForKeyPath:@"study.name"]);
	[templateString replaceOccurrencesOfString:@"%LinkToStudyLevel%" withString:N2NonNullString(studyName)];
	
	data = [templateString dataUsingEncoding:NSUTF8StringEncoding];
	err = NO;
	*/
}


-(void)processPasswordForgottenHtml {
	/*
	if (!portal.passwordRestoreAllowed) {
		response.statusCode = 404;
		return;
	}
	
	
	{
		
		NSMutableString *templateString = [self webServicesHTMLMutableString:@"password_forgotten.html"];
		
		NSString *message = @"";
		
		if ([[parameters valueForKey: @"what"] isEqualToString: @"restorePassword"])
		{
			NSString *email = [parameters valueForKey: @"email"];
			NSString *username = [parameters valueForKey: @"username"];
			
			// TRY TO FIND THIS USER
			if ([email length] > 0 || [username length] > 0)
			{
				[self.portal.database.managedObjectContext lock];
				
				@try
				{
					NSError *error = nil;
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:self.portal.database.managedObjectContext]];
					
					if ([email length] > [username length])
						[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(email BEGINSWITH[cd] %@) AND (email ENDSWITH[cd] %@)", email, email]];
					else
						[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"(name BEGINSWITH[cd] %@) AND (name ENDSWITH[cd] %@)", username, username]];
					
					error = nil;
					NSArray *users = [self.portal.database.managedObjectContext executeFetchRequest: dbRequest error:&error];
					
					if ([users count] >= 1)
					{
						for (WebPortalUser *user in users)
						{
							NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
							
							if (fromEmailAddress == nil)
								fromEmailAddress = @"";
							
							NSString *emailSubject = NSLocalizedString( @"Your password has been reset.", nil);
							NSMutableString *emailMessage = [NSMutableString stringWithString: @""];
							
							[user generatePassword];
							
							[emailMessage appendString: NSLocalizedString( @"Username:\r\r", nil)];
							[emailMessage appendString: [user valueForKey: @"name"]];
							[emailMessage appendString: @"\r\r"];
							[emailMessage appendString: NSLocalizedString( @"Password:\r\r", nil)];
							[emailMessage appendString: [user valueForKey: @"password"]];
							[emailMessage appendString: @"\r\r"];
							
							[portal updateLogEntryForStudy: nil withMessage: @"Password reseted for user" forUser: [user valueForKey: @"name"] ip: nil];
							
							[[CSMailMailClient mailClient] deliverMessage: [[[NSAttributedString alloc] initWithString: emailMessage] autorelease] headers: [NSDictionary dictionaryWithObjectsAndKeys: [user valueForKey: @"email"], @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", nil]];
							
							message = NSLocalizedString( @"You will receive shortly an email with a new password.", nil);
							
							[self.portal.database save:NULL];
						}
					}
					else
					{
						// To avoid someone scanning for the username
						[NSThread sleepForTimeInterval:3];
						
						[portal updateLogEntryForStudy: nil withMessage: @"Unknown user" forUser: [NSString stringWithFormat: @"%@ %@", username, email] ip: nil];
						
						message = NSLocalizedString( @"This user doesn't exist in our database.", nil);
					}
				}
				@catch( NSException *e)
				{
					NSLog( @"******* password_forgotten: %@", e);
				}
				
				[self.portal.database.managedObjectContext unlock];
			}
		}
		
		[WebPortalResponse mutableString:templateString block:@"MessageToWrite" setVisible:message.length];
		[templateString replaceOccurrencesOfString:@"%PageTitle%" withString:NSLocalizedString(@"Password Forgotten", @"Web portal, password forgotten, title")];
		
		[templateString replaceOccurrencesOfString: @"%Localized_Message%" withString:N2NonNullString(message)];
		
		data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
		
		err = NO;
	}
	*/
}


-(void)processAccountHtml {/*
	if (!wpc.user) {
		self.statusCode = 404;
		return;
	}
	
	
	{
		NSString *message = @"";
		BOOL messageIsError = NO;
		
		if ([[parameters valueForKey: @"what"] isEqualToString: @"changePassword"])
		{
			NSString * previouspassword = [parameters valueForKey: @"previouspassword"];
			NSString * password = [parameters valueForKey: @"password"];
			
			if ([previouspassword isEqualToString:user.password])
			{
				if ([[parameters valueForKey: @"password"] isEqualToString: [parameters valueForKey: @"password2"]])
				{
					if ([password length] >= 4)
					{
						// We can update the user password
						[user setValue: password forKey: @"password"];
						message = NSLocalizedString( @"Password updated successfully !", nil);
						[portal updateLogEntryForStudy: nil withMessage: [NSString stringWithFormat: @"User changed his password"] forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
					}
					else
					{
						message = NSLocalizedString( @"Password needs to be at least 4 characters !", nil);
						messageIsError = YES;
					}
				}
				else
				{
					message = NSLocalizedString( @"New passwords are not identical !", nil);
					messageIsError = YES;
				}
			}
			else
			{
				message = NSLocalizedString( @"Wrong current password !", nil);
				messageIsError = YES;
			}
		}
		
		if ([[parameters valueForKey: @"what"] isEqualToString: @"changeSettings"])
		{
			NSString * email = [parameters valueForKey: @"email"];
			NSString * address = [parameters valueForKey: @"address"];
			NSString * phone = [parameters valueForKey: @"phone"];
			
			[user setValue: email forKey: @"email"];
			[user setValue: address forKey: @"address"];
			[user setValue: phone forKey: @"phone"];
			
			if ([[[parameters valueForKey: @"emailNotification"] lowercaseString] isEqualToString: @"on"])
				[user setValue: [NSNumber numberWithBool: YES] forKey: @"emailNotification"];
			else
				[user setValue: [NSNumber numberWithBool: NO] forKey: @"emailNotification"];
			
			message = NSLocalizedString( @"Personal Information updated successfully !", nil);
		}
		
		NSMutableString *templateString = [self webServicesHTMLMutableString:@"account.html"];
		
		NSString *block = @"MessageToWrite";
		if (messageIsError)
		{
			block = @"ErrorToWrite";
			[WebPortalResponse mutableString:templateString block:@"MessageToWrite" setVisible:NO];
		}
		else
		{
			[WebPortalResponse mutableString:templateString block:@"ErrorToWrite" setVisible:NO];
		}
		
		[WebPortalResponse mutableString:templateString block:block setVisible:message.length];
		
		[templateString replaceOccurrencesOfString: @"%LocalizedLabel_MessageAccount%" withString:N2NonNullString(message)];
		
		[templateString replaceOccurrencesOfString: @"%name%" withString:N2NonNullString(user.name)];
		[templateString replaceOccurrencesOfString: @"%PageTitle%" withString:[NSString stringWithFormat:NSLocalizedString(@"User account for: %@", @"Web portal, account, title format (%@ is user.name)"), user.name]];
		
		[templateString replaceOccurrencesOfString: @"%email%" withString:N2NonNullString(user.email)];
		[templateString replaceOccurrencesOfString: @"%address%" withString:N2NonNullString(user.address)];
		[templateString replaceOccurrencesOfString: @"%phone%" withString:N2NonNullString(user.phone)];
		[templateString replaceOccurrencesOfString: @"%emailNotification%" withString: (user.emailNotification.boolValue?@"checked":@"")];
		
		data = [templateString dataUsingEncoding: NSUTF8StringEncoding];
		
		[self.portal.database save:NULL];
		
		err = NO;
	}
	*/
}






#pragma mark Administration HTML

-(void)processAdminIndexHtml {
	if (!wpc.user.isAdmin) {
		self.statusCode = 401;
		[portal updateLogEntryForStudy:NULL withMessage:@"Attempt to access admin area without being an admin" forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
		return;
	}
	
	[self.tokens setObject:NSLocalizedString(@"Administration", @"Web Portal, admin, index, title") forKey:@"PageTitle"];
	
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [portal.database entityForName:@"User"];
	req.predicate = [NSPredicate predicateWithValue:YES];
	[self.tokens setObject:[portal.database.managedObjectContext executeFetchRequest:req error:NULL] forKey:@"Users"];
	
	self.templateString = [portal stringForPath:@"admin/index.html"];
}

-(void)processAdminUserHtml {
	if (!wpc.user.isAdmin) {
		self.statusCode = 401;
		[portal updateLogEntryForStudy:NULL withMessage:@"Attempt to access admin area without being an admin" forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
		return;
	}

	NSObject* user = NULL;
	BOOL userRecycleParams = NO;
	NSString* action = [wpc.parameters objectForKey:@"action"];
	NSString* originalName = NULL;
	
	if ([action isEqual:@"delete"]) {
		originalName = [wpc.parameters objectForKey:@"originalName"];
		NSManagedObject* tempUser = [portal.database userWithName:originalName];
		if (!tempUser)
			[self.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't delete user <b>%@</b> because it doesn't exists.", @"Web Portal, admin, user edition, delete error (%@ is user.name)"), originalName]];
		else {
			[portal.database.managedObjectContext deleteObject:tempUser];
			[tempUser.managedObjectContext save:NULL];
			[self.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"User <b>%@</b> successfully deleted.", @"Web Portal, admin, user edition, delete ok (%@ is user.name)"), originalName]];
		}
	}
	
	if ([action isEqual:@"save"]) {
		originalName = [wpc.parameters objectForKey:@"originalName"];
		WebPortalUser* webUser = [portal.database userWithName:originalName];
		if (!webUser) {
			[self.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't save changes for user <b>%@</b> because it doesn't exists.", @"Web Portal, admin, user edition, save error (%@ is user.name)"), originalName]];
			userRecycleParams = YES;
		} else {
			// NSLog(@"SAVE params: %@", wpc.parameters.description);
			
			NSString* name = [wpc.parameters objectForKey:@"name"];
			NSString* password = [wpc.parameters objectForKey:@"password"];
			NSString* studyPredicate = [wpc.parameters objectForKey:@"studyPredicate"];
			NSNumber* downloadZIP = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"downloadZIP"] isEqual:@"on"]];
			
			NSError* err;
			
			err = NULL;
			if (![webUser validateName:&name error:&err])
				[self.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validatePassword:&password error:&err])
				[self.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateStudyPredicate:&studyPredicate error:&err])
				[self.tokens addError:err.localizedDescription];
			err = NULL;
			if (![webUser validateDownloadZIP:&downloadZIP error:&err])
				[self.tokens addError:err.localizedDescription];
			
			if (!self.tokens.errors.count) {
				webUser.name = name;
				webUser.password = password;
				webUser.email = [wpc.parameters objectForKey:@"email"];
				webUser.phone = [wpc.parameters objectForKey:@"phone"];
				webUser.address = [wpc.parameters objectForKey:@"address"];
				webUser.studyPredicate = studyPredicate;
				
				webUser.autoDelete = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"autoDelete"] isEqual:@"on"]];
				webUser.downloadZIP = downloadZIP;
				webUser.emailNotification = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"emailNotification"] isEqual:@"on"]];
				webUser.encryptedZIP = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"encryptedZIP"] isEqual:@"on"]];
				webUser.uploadDICOM = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"uploadDICOM"] isEqual:@"on"]];
				webUser.sendDICOMtoSelfIP = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"sendDICOMtoSelfIP"] isEqual:@"on"]];
				webUser.uploadDICOMAddToSpecificStudies = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"uploadDICOMAddToSpecificStudies"] isEqual:@"on"]];
				webUser.sendDICOMtoAnyNodes = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"sendDICOMtoAnyNodes"] isEqual:@"on"]];
				webUser.shareStudyWithUser = [NSNumber numberWithBool:[[wpc.parameters objectForKey:@"shareStudyWithUser"] isEqual:@"on"]];
				
				if (webUser.autoDelete.boolValue)
					webUser.deletionDate = [NSCalendarDate dateWithYear:[[wpc.parameters objectForKey:@"deletionDate_year"] integerValue] month:[[wpc.parameters objectForKey:@"deletionDate_month"] integerValue]+1 day:[[wpc.parameters objectForKey:@"deletionDate_day"] integerValue] hour:0 minute:0 second:0 timeZone:NULL];
				
				NSMutableArray* remainingStudies = [NSMutableArray array];
				for (NSString* studyObjectID in [[wpc.parameters objectForKey:@"remainingStudies"] componentsSeparatedByString:@","]) {
					studyObjectID = [studyObjectID.stringByTrimmingStartAndEnd stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					WebPortalStudy* wpStudy = NULL;
					// this is Mac OS X 10.6 SnowLeopard only // wpStudy = [webUser.managedObjectContext existingObjectWithID:[webUser.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:studyObjectID]] error:NULL];
					for (WebPortalStudy* iwpStudy in webUser.studies)
						if ([iwpStudy.objectID.URIRepresentation.absoluteString isEqual:studyObjectID]) {
							wpStudy = iwpStudy;
							break;
						}
					
					if (wpStudy) [remainingStudies addObject:wpStudy];
					else NSLog(@"Warning: Web Portal user %@ is referencing a study with CoreData ID %@, which doesn't exist", wpc.user.name, studyObjectID);
				}
				for (WebPortalStudy* iwpStudy in webUser.studies.allObjects)
					if (![remainingStudies containsObject:iwpStudy])
						[webUser removeStudiesObject:iwpStudy];
				
				[webUser.managedObjectContext save:NULL];
				
				[self.tokens addMessage:[NSString stringWithFormat:NSLocalizedString(@"Changes for user <b>%@</b> successfully saved.", @"Web Portal, admin, user edition, save ok (%@ is user.name)"), webUser.name]];
				user = webUser;
			} else
				userRecycleParams = YES;
		}
	}
	
	if ([action isEqual:@"new"]) {
		user = [portal.database newUser];
	}
	
	if (!action) { // edit
		originalName = [wpc.parameters objectForKey:@"name"];
		user = [portal.database userWithName:originalName];
		if (!user)
			[self.tokens addError:[NSString stringWithFormat:NSLocalizedString(@"Couldn't find user with name <b>%@</b>.", @"Web Portal, admin, user edition, edit error (%@ is user.name)"), originalName]];
	}
	
	[self.tokens setObject:[NSString stringWithFormat:NSLocalizedString(@"User Administration: %@", @"Web Portal, admin, user edition, title (%@ is user.name)"), user? [user valueForKey:@"name"] : originalName] forKey:@"PageTitle"];
	if (user)
		[self.tokens setObject:[WebPortalProxy createWithObject:user transformer:[WebPortalUserTransformer create]] forKey:@"User"];
	else if (userRecycleParams) [self.tokens setObject:wpc.parameters forKey:@"User"];
	
	self.templateString = [portal stringForPath:@"admin/user.html"];
}

#pragma mark JSON

-(void)processStudyListJson {
	/*NSArray* studies = [self studyList_studiesForUser:wpc.user parameters:wpc.parameters outTitle:NULL]	
	
	[portal.dicomDatabase lock];
	@try {
		NSMutableArray* r = [NSMutableArray array];
		for (DicomStudy* study in studies) {
			NSMutableDictionary* s = [NSMutableDictionary dictionary];
			
			[s setObject:N2NonNullString(study.name) forKey:@"name"];
			[s setObject:[[NSNumber numberWithInt:study.series.count] stringValue] forKey:@"seriesCount"];
			[s setObject:[NSUserDefaults.dateFormatter stringFromDate:study.date] forKey:@"date"];
			[s setObject:N2NonNullString(study.studyName) forKey:@"studyName"];
			[s setObject:N2NonNullString(study.modality) forKey:@"modality"];
			
			NSString* stateText = study.stateText;
			if (stateText.intValue)
				stateText = [BrowserController.statesArray objectAtIndex:studyText.intValue];
			[s setObject:N2NonNullString(stateText) forKey:@"stateText"];

			[s setObject:N2NonNullString(study.studyInstanceUID) forKey:@"studyInstanceUID"];

			[r addObject:s];
		}
		
		return [r JSONRepresentation];
	} @catch (NSException* e) {
		NSLog(@"Error: [WebPortalResponse processStudyListJson:] %@", e);
	} @finally {
		[portal.dicomDatabase unlock];
	}*/
}

-(void)processSeriesJson {
	/*DicomSeries* series = [self series_seriesForUser:wpc.user];
	
	NSArray *imagesArray = [[[series lastObject] valueForKey:@"images"] allObjects];
	
	
	@try
	{
		// Sort images with "instanceNumber"
		NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
		NSArray *sortDescriptors = [NSArray arrayWithObject:sort];
		[sort release];
		imagesArray = [imagesArray sortedArrayUsingDescriptors: sortDescriptors];
	}
	@catch (NSException * e)
	{
		NSLog( @"%@", [e description]);
	}
	
	
	
	
	
	NSMutableArray *jsonImagesArray = [NSMutableArray array];
	
	NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
	[context lock];
	
	@try
	{
		for (DicomImage *image in images)
		{
			[jsonImagesArray addObject:N2NonNullString([image valueForKey:@"sopInstanceUID"])];
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"***** jsonImageListForImages exception: %@", e);
	}
	
	[context unlock];
	
	return [jsonImagesArray JSONRepresentation];
	
	
	
	
	
	
	
	
	data = [json dataUsingEncoding:NSUTF8StringEncoding];
	err = NO;*/		
}

-(void)processAlbumsJson {/*
	
	NSMutableArray *jsonAlbumsArray = [NSMutableArray array];
	
	NSArray	*albumArray = [[BrowserController currentBrowser] albumArray];
	for (NSManagedObject *album in albumArray)
	{
		if (![[album valueForKey:@"name"] isEqualToString: NSLocalizedString(@"Database", nil)])
		{
			NSMutableDictionary *albumDictionary = [NSMutableDictionary dictionary];
			
			[albumDictionary setObject:N2NonNullString([album valueForKey:@"name"]) forKey:@"name"];
			[albumDictionary setObject:N2NonNullString([[album valueForKey:@"name"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]) forKey:@"nameURLSafe"];
			
			if ([[album valueForKey:@"smartAlbum"] intValue] == 1)
				[albumDictionary setObject:@"SmartAlbum" forKey:@"type"];
			else
				[albumDictionary setObject:@"Album" forKey:@"type"];
			
			[jsonAlbumsArray addObject:albumDictionary];
		}
	}
	
	NSString *json = [jsonAlbumsArray JSONRepresentation];
	
		data = [json dataUsingEncoding:NSUTF8StringEncoding];
		err = NO;
	*/
}

-(void)processSeriesListJson {/*

	{
		NSPredicate *browsePredicate;
		if ([[parameters allKeys] containsObject:@"id"])
		{
			browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		
		
		NSArray *studies = [self studiesForPredicate:browsePredicate];
		
		if ([studies count] == 1)
		{
			NSArray *series = [[studies objectAtIndex:0] valueForKey:@"imageSeries"];
			
			
			
			
			
			
			NSMutableArray *jsonSeriesArray = [NSMutableArray array];
			
			NSManagedObjectContext *context = [[BrowserController currentBrowser] managedObjectContext];
			
			[context lock];
			
			@try
			{
				for (DicomSeries *s in series)
				{
					NSMutableDictionary *seriesDictionary = [NSMutableDictionary dictionary];
					
					[seriesDictionary setObject:N2NonNullString([s valueForKey:@"seriesInstanceUID"]) forKey:@"seriesInstanceUID"];
					[seriesDictionary setObject:N2NonNullString([s valueForKey:@"seriesDICOMUID"]) forKey:@"seriesDICOMUID"];
					
					NSArray *dicomImageArray = [[s valueForKey:@"images"] allObjects];
					DicomImage *im;
					if ([dicomImageArray count] == 1)
						im = [dicomImageArray lastObject];
					else
						im = [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
					
					[seriesDictionary setObject:[im valueForKey:@"sopInstanceUID"] forKey:@"keyInstanceUID"];
					
					[jsonSeriesArray addObject:seriesDictionary];
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"******* jsonSeriesListForSeries exception: %@", e);
			}
			[context unlock];
			
			NSString *json =  [jsonSeriesArray JSONRepresentation];
			
			
			
			
			data = [json dataUsingEncoding:NSUTF8StringEncoding];
			err = NO;
		}
		else err = YES;
	}
	*/
}


#pragma mark WADO

// wado?requestType=WADO&studyUID=XXXXXXXXXXX&seriesUID=XXXXXXXXXXX&objectUID=XXXXXXXXXXX
// 127.0.0.1:3333/wado?requestType=WADO&frameNumber=1&studyUID=2.16.840.1.113669.632.20.1211.10000591592&seriesUID=1.3.6.1.4.1.19291.2.1.2.2867252960399100001&objectUID=1.3.6.1.4.1.19291.2.1.3.2867252960616100004
-(void)processWado {/*
	if (!self.portal.wadoEnabled) {
		self.statusCode = 403;
		[self setDataWithString:NSLocalizedString(@"OsiriX cannot fulfill your request because the WADO service is disabled.", NULL)];
		return;
	}
	
	if (![[[parameters objectForKey:@"requestType"] lowercaseString] isEqual:@"wado"]) {
		self.statusCode = 404;
		return;
	}
		
		
	NSString* studyUID = [parameters objectForKey:@"studyUID"];
	NSString* seriesUID = [parameters objectForKey:@"seriesUID"];
	NSString* objectUID = [parameters objectForKey:@"objectUID"];
	
	if (objectUID == nil)
		NSLog(@"***** WADO with objectUID == nil -> wado will fail");
	
	NSString *contentType = [[[[parameters objectForKey:@"contentType"] lowercaseString] componentsSeparatedByString: @","] objectAtIndex: 0];
	//					contentType = [contentType stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	int rows = [[parameters objectForKey:@"rows"] intValue];
	int columns = [[parameters objectForKey:@"columns"] intValue];
	int windowCenter = [[parameters objectForKey:@"windowCenter"] intValue];
	int windowWidth = [[parameters objectForKey:@"windowWidth"] intValue];
	int frameNumber = [[parameters objectForKey:@"frameNumber"] intValue];	// -> OsiriX stores frames as images
	int imageQuality = DCMLosslessQuality;
	
	if ([parameters objectForKey:@"imageQuality"])
	{
		if ([[parameters objectForKey:@"imageQuality"] intValue] > 80)
			imageQuality = DCMLosslessQuality;
		else if ([[parameters objectForKey:@"imageQuality"] intValue] > 60)
			imageQuality = DCMHighQuality;
		else if ([[parameters objectForKey:@"imageQuality"] intValue] > 30)
			imageQuality = DCMMediumQuality;
		else if ([[parameters objectForKey:@"imageQuality"] intValue] >= 0)
			imageQuality = DCMLowQuality;
	}
	
	NSString *transferSyntax = [[parameters objectForKey:@"transferSyntax"] lowercaseString];
	NSString *useOrig = [[parameters objectForKey:@"useOrig"] lowercaseString];
	
	NSError *error = nil;
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
	
	@try {
		NSMutableDictionary *imageCache = nil;
		NSArray *images = nil;
		
		if (wadoJPEGCache == nil)
			wadoJPEGCache = [[NSMutableDictionary alloc] initWithCapacity: WADOCACHESIZE];
		
		if ([wadoJPEGCache count] > WADOCACHESIZE)
			[wadoJPEGCache removeAllObjects];
		
		if ([contentType length] == 0 || [contentType isEqualToString: @"image/jpeg"] || [contentType isEqualToString: @"image/png"] || [contentType isEqualToString: @"image/gif"] || [contentType isEqualToString: @"image/jp2"])
		{
			imageCache = [wadoJPEGCache objectForKey: [objectUID stringByAppendingFormat: @"%d", frameNumber]];
		}
		
		if (imageCache == nil)
		{
			if (studyUID)
				[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"studyInstanceUID == %@", studyUID]];
			else
				[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
			
			NSArray *studies = [[[BrowserController currentBrowser] managedObjectContext] executeFetchRequest: dbRequest error: &error];
			
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
				[portal updateLogEntryForStudy: [studies lastObject] withMessage: @"WADO Send" forUser: nil ip: [asyncSocket connectedHost] forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
			}
		}
		
		if ([images count] || imageCache != nil)
		{
			if ([contentType isEqualToString: @"application/dicom"])
			{
				if ([useOrig isEqualToString: @"true"] || [useOrig isEqualToString: @"1"] || [useOrig isEqualToString: @"yes"])
				{
					data = [NSData dataWithContentsOfFile: [[images lastObject] valueForKey: @"completePath"]];
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
					
					data = [[BrowserController currentBrowser] getDICOMFile: [[images lastObject] valueForKey: @"completePath"] inSyntax: ts.transferSyntax quality: imageQuality];
				}
				err = NO;
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
					
					NSString *name = [NSString stringWithFormat:@"%@",[parameters objectForKey:@"id"]];
					name = [name stringByAppendingFormat:@"-NBIM-%d", [dicomImageArray count]];
					
					NSMutableString *fileName = [NSMutableString stringWithString: [path stringByAppendingPathComponent:name]];
					
					[BrowserController replaceNotAdmitted: fileName];
					
					[fileName appendString:@".mov"];
					
					NSString *outFile;
					if (isIOS)
						outFile = [NSString stringWithFormat:@"%@2.m4v", [fileName stringByDeletingPathExtension]];
					else
						outFile = fileName;
					
					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: isIOS], @"isiPhone", fileURL, @"fileURL", fileName, @"fileName", outFile, @"outFile", parameters, @"parameters", dicomImageArray, @"dicomImageArray", [NSNumber numberWithInt: rows], @"rows", [NSNumber numberWithInt: columns], @"columns", nil];
					
					lockReleased = YES;
					[self.portal.dicomDatabase.managedObjectContext unlock];
					
					[self generateMovie: dict];
					
					data = [NSData dataWithContentsOfFile: outFile];
					
					if (data)
						err = NO;
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
					
					[wadoJPEGCache setObject: imageCache forKey: [objectUID stringByAppendingFormat: @"%d", frameNumber]];
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
					
					data = [imageCache objectForKey: [NSString stringWithFormat: @"%@ %f %f %d %d %d", contentType, curWW, curWL, columns, rows, frameNumber]];
					
					if (data == nil)
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
							data = [imageRep representationUsingType: NSGIFFileType properties:imageProps];
						else if ([contentType isEqualToString: @"image/png"])
							data = [imageRep representationUsingType: NSPNGFileType properties:imageProps];
						else if ([contentType isEqualToString: @"image/jp2"])
							data = [imageRep representationUsingType: NSJPEG2000FileType properties:imageProps];
						else
							data = [imageRep representationUsingType: NSJPEGFileType properties:imageProps];
						
						[imageCache setObject: data forKey: [NSString stringWithFormat: @"%@ %f %f %d %d %d", contentType, curWW, curWL, columns, rows, frameNumber]];
					}
					
					if (data)
						err = NO;
				}
			}
		}
		else NSLog( @"****** WADO Server : image uid not found !");
		
		if (err)
		{
			data = [NSData data];
			err = NO;
		}
	} @catch (NSException * e) {
		NSLog(@"Error: [WebPortalResponse processWado:] %@", e);
		self.statusCode = 500;
	}*/
}

#pragma mark Weasis

-(void)processWeasisJnlp {
	if (!portal.weasisEnabled) {
		self.statusCode = 404;
		return;
	}
	
	[self.tokens setObject:wpc.portalURL forKey:@"WebServerAddress"];
	[self.tokens setObject:wpc.GETParams forKey:@"parameters"];
	
	self.templateString = [portal stringForPath:@"weasis.jnlp"];
	self.mimeType = @"application/x-java-jnlp-file";
}

-(void)processWeasisXml {
	if (!portal.weasisEnabled) {
		self.statusCode = 404;
		return;
	}
	
	NSString* studyInstanceUID = [wpc.parameters objectForKey:@"StudyInstanceUID"];
	NSString* seriesInstanceUID = [wpc.parameters objectForKey:@"SeriesInstanceUID"];
	NSArray* selectedSeries = [WebPortalResponse MakeArray:[wpc.parameters objectForKey:@"selected"]];
	
	NSMutableArray* requestedStudies = [NSMutableArray arrayWithCapacity:8];
	NSMutableArray* requestedSeries = [NSMutableArray arrayWithCapacity:64];
	
	// find requosted core data objects
	if (studyInstanceUID)
		[requestedStudies addObjectsFromArray:[portal studiesForUser:wpc.user predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyInstanceUID] sortBy:NULL]];
	if (seriesInstanceUID)
		[requestedSeries addObjectsFromArray:[portal seriesForUser:wpc.user predicate:[NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", seriesInstanceUID]]];
	for (NSString* selSeriesInstanceUID in selectedSeries)
		[requestedSeries addObjectsFromArray:[portal seriesForUser:wpc.user predicate:[NSPredicate predicateWithFormat:@"seriesInstanceUID == %@", selSeriesInstanceUID]]];
	
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
	if (wpc.user) {
		studies = (NSMutableArray*) [portal studiesForUser:wpc.user predicate:[NSPredicate predicateWithValue:YES] sortBy:nil];// is not mutable, but we won't mutate it anymore
	}
	
	// produce XML
	NSString* baseXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><wado_query wadoURL=\"%@/wado\"></wado_query>", wpc.portalURL];
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
	
	[self setDataWithString:[[doc autorelease] XMLString]];
	self.mimeType = @"text/xml";	
}

#pragma mark Other

-(void)processReport {
	/*
	
	{
		NSPredicate *browsePredicate;
		if ([[parameters allKeys] containsObject:@"id"])
		{
			browsePredicate = [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		
		NSArray *studies = [self studiesForPredicate:browsePredicate];
		
		if ([studies count] == 1)
		{
			[portal updateLogEntryForStudy: [studies lastObject] withMessage: @"Download Report" forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
			
			NSString *reportFilePath = [[studies lastObject] valueForKey:@"reportURL"];
			
			NSString *reportType = [reportFilePath pathExtension];
			
			if ([reportType isEqualToString: @"pages"])
			{
				NSString *zipFileName = [NSString stringWithFormat:@"%@.zip", [reportFilePath lastPathComponent]];
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
				{
					reportFilePath = [[reportFilePath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@", zipFileName];
				}
				
				data = [NSData dataWithContentsOfFile: reportFilePath];
				
				[[NSFileManager defaultManager] removeFileAtPath:reportFilePath handler:nil];
				
				if (data)
					err = NO;
			}
			else
			{
				data = [NSData dataWithContentsOfFile: reportFilePath];
				
				if (data)
					err = NO;
			}
		}
	}
	
	*/
}

-(void)processThumbnail {/*
	NSPredicate *browsePredicate = nil;
	NSString *seriesInstanceUID = nil, *studyInstanceUID = nil;
	
	if ([[parameters allKeys] containsObject:@"id"])
	{
		if ([[parameters allKeys] containsObject:@"studyID"])
		{
			if (thumbnailCache == nil)
				thumbnailCache = [[NSMutableDictionary alloc] initWithCapacity: THUMBNAILCACHE];
			
			if ([thumbnailCache count] > THUMBNAILCACHE)
				[thumbnailCache removeAllObjects];
			
			if ([thumbnailCache objectForKey: [parameters objectForKey:@"studyID"]])
			{
				NSDictionary *seriesThumbnail = [thumbnailCache objectForKey: [parameters objectForKey:@"studyID"]];
				
				if ([seriesThumbnail objectForKey: [parameters objectForKey:@"id"]])
					data = [seriesThumbnail objectForKey: [parameters objectForKey:@"id"]];
			}
			
			browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [parameters objectForKey:@"studyID"]];// AND seriesInstanceUID == %@", [parameters objectForKey:@"studyID"], [parameters objectForKey:@"id"]];
			
			studyInstanceUID = [parameters objectForKey:@"studyID"];
			seriesInstanceUID = [parameters objectForKey:@"id"];
		}
		else
		{
			browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [parameters objectForKey:@"id"]];
			studyInstanceUID = [parameters objectForKey:@"id"];
		}
	}
	else
		browsePredicate = [NSPredicate predicateWithValue:NO];
	
	if (data == nil)
	{
		NSArray *series = [self seriesForPredicate:browsePredicate];
		
		if ([series count]  > 0)
		{
			NSMutableDictionary *seriesThumbnails = [NSMutableDictionary dictionary];
			
			for ( DicomSeries *s in series)
			{
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [s valueForKey:@"thumbnail"]];
				
				NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
				
				NSData *dataThumbnail = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
				
				if (dataThumbnail && [s valueForKey: @"seriesInstanceUID"])
				{
					[seriesThumbnails setObject: dataThumbnail forKey: [s valueForKey: @"seriesInstanceUID"]];
					
					if ([seriesInstanceUID isEqualToString: [s valueForKey: @"seriesInstanceUID"]])
						data = dataThumbnail;
				}
			}
			
			if (studyInstanceUID && seriesThumbnails)
				[thumbnailCache setObject: seriesThumbnails forKey: studyInstanceUID];
		}
	}
	err = NO;*/
}

-(void)processSeriesPdf {/*
	NSPredicate *browsePredicate;
	if ([[parameters allKeys] containsObject:@"id"])
	{
		if ([[parameters allKeys] containsObject:@"studyID"])
			browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [parameters objectForKey:@"studyID"], [parameters objectForKey:@"id"]];
		else
			browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [parameters objectForKey:@"id"] ];
	}
	else
		browsePredicate = [NSPredicate predicateWithValue:NO];
	
	NSArray *series = [self seriesForPredicate: browsePredicate];
	
	if ([series count] == 1)
	{
		if ([DCMAbstractSyntaxUID isPDF: [[series lastObject] valueForKey: @"seriesSOPClassUID"]])
		{
			DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"]  decodingPixelData:NO];
			
			if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
			{
				data = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
				
				if (data)
					err = NO;
			}
		}
		
		if ([DCMAbstractSyntaxUID isStructuredReport: [[series lastObject] valueForKey: @"seriesSOPClassUID"]])
		{
			if ([[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/dicomsr_osirix/"] == NO)
				[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/dicomsr_osirix/" attributes: nil];
			
			NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [[[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"] lastPathComponent]] stringByAppendingPathExtension: @"html"];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
			{
				NSTask *aTask = [[[NSTask alloc] init] autorelease];		
				[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
				[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
				[aTask setArguments: [NSArray arrayWithObjects: [[[[series lastObject] valueForKey: @"images"] anyObject] valueForKey: @"completePath"], htmlpath, nil]];		
				[aTask launch];
				[aTask waitUntilExit];		
				[aTask interrupt];
			}
			
			if ([[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
			{
				NSTask *aTask = [[[NSTask alloc] init] autorelease];
				[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
				[aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
				[aTask launch];
				[aTask waitUntilExit];		
				[aTask interrupt];
			}
			
			data = [NSData dataWithContentsOfFile: [htmlpath stringByAppendingPathExtension: @"pdf"]];
			
			if (data)
				err = NO;
		}
	}
	
	if (err)
	{
		data = [NSData data];
		err = NO;
	}*/
}


-(void)processZip {/*

	{
		NSPredicate *browsePredicate;
		if ([[parameters allKeys] containsObject:@"id"])
		{
			if ([[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [parameters objectForKey:@"studyID"], [parameters objectForKey:@"id"]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		
		NSArray *series = [self seriesForPredicate:browsePredicate];
		
		NSMutableArray *imagesArray = [NSMutableArray array];
		for ( DicomSeries *s in series)
			[imagesArray addObjectsFromArray: [[s valueForKey:@"images"] allObjects]];
		
		if ([imagesArray count])
		{
			if (user.encryptedZIP.boolValue)
				[portal updateLogEntryForStudy: [[series lastObject] valueForKey: @"study"] withMessage: @"Download encrypted DICOM ZIP" forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
			else
				[portal updateLogEntryForStudy: [[series lastObject] valueForKey: @"study"] withMessage: @"Download DICOM ZIP" forUser:wpc.user.name ip:wpc.asyncSocket.connectedHost];
			
			@try
			{
				NSString *srcFolder = @"/tmp";
				NSString *destFile = @"/tmp";
				
				srcFolder = [srcFolder stringByAppendingPathComponent: [[[imagesArray lastObject] valueForKeyPath: @"series.study.name"] filenameString]];
				destFile = [destFile stringByAppendingPathComponent: [[[imagesArray lastObject] valueForKeyPath: @"series.study.name"] filenameString]];
				
				if (isMacOS)
					destFile = [destFile  stringByAppendingPathExtension: @"zip"];
				else
					destFile = [destFile  stringByAppendingPathExtension: @"osirixzip"];
				
				if (srcFolder)
					[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
				
				if (destFile)
					[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
				
				[[NSFileManager defaultManager] createDirectoryAtPath: srcFolder attributes: nil];
				
				if (lockReleased == NO)
				{
					[self.portal.dicomDatabase.managedObjectContext unlock];
					lockReleased = YES;
				}
				
				if (user.encryptedZIP.boolValue)
					[BrowserController encryptFiles: [imagesArray valueForKey: @"completePath"] inZIPFile: destFile password:user.password];
				else
					[BrowserController encryptFiles: [imagesArray valueForKey: @"completePath"] inZIPFile: destFile password: nil];
				
				data = [NSData dataWithContentsOfFile: destFile];
				
				if (srcFolder)
					[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
				
				if (destFile)
					[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
				
				if (data)
					err = NO;
				else
				{
					data = [NSData data];
					err = NO;
				}
			}
			@catch( NSException *e)
			{
				NSLog( @"**** web seriesAsZIP exception : %@", e);
			}
		}
	}
	
	*/
}

-(void)processImage {/*
	
	{
		NSPredicate *browsePredicate;
		if ([[parameters allKeys] containsObject:@"id"])
		{
			if ([[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [parameters objectForKey:@"studyID"], [parameters objectForKey:@"id"]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		
		NSArray *series = [self seriesForPredicate:browsePredicate];
		if ([series count] == 1)
		{
			NSArray *dicomImageArray = [[[series lastObject] valueForKey:@"images"] allObjects];
			DicomImage *im;
			if ([dicomImageArray count] == 1)
				im = [dicomImageArray lastObject];
			else
				im = [dicomImageArray objectAtIndex:[dicomImageArray count]/2];
			
			DCMPix* dcmPix = [[[DCMPix alloc] initWithPath:[im valueForKey:@"completePathResolved"] :0 :1 :nil :[[im valueForKey: @"numberOfFrames"] intValue]/2 :[[im valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:im] autorelease];
			
			if (dcmPix == nil)
			{
				NSLog( @"****** dcmPix creation failed for file : %@", [im valueForKey:@"completePathResolved"]);
				float *imPtr = (float*)malloc( [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue] * sizeof(float));
				for ( int i = 0 ;  i < [[im valueForKey: @"width"] intValue] * [[im valueForKey: @"height"] intValue]; i++)
					imPtr[ i] = i;
				
				dcmPix = [[[DCMPix alloc] initWithData: imPtr :32 :[[im valueForKey: @"width"] intValue] :[[im valueForKey: @"height"] intValue] :0 :0 :0 :0 :0] autorelease];
			}
			
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
				
				NSImage *image = [dcmPix image];
				
				float width = [image size].width;
				float height = [image size].height;
				
				int maxWidth = maxResolution, maxHeight = maxResolution;
				int minWidth = minResolution, minHeight = minResolution;
				
				BOOL resize = NO;
				
				if (width>maxWidth)
				{
					height =  height * maxWidth / width;
					width = maxWidth;
					resize = YES;
				}
				if (height>maxHeight)
				{
					width = width * maxHeight / height;
					height = maxHeight;
					resize = YES;
				}
				
				if (width < minWidth)
				{
					height = (float)height * (float)minWidth / (float)width;
					width = minWidth;
					resize = YES;
				}
				
				if (height < minHeight)
				{
					width = (float)width * (float)minHeight / (float)height;
					height = minHeight;
					resize = YES;
				}
				
				NSImage *newImage;
				
				if (resize)
					newImage = [image imageByScalingProportionallyToSize:NSMakeSize(width, height)];
				else
					newImage = image;
				
				if ([[parameters allKeys] containsObject:@"previewForMovie"])
				{
					[newImage lockFocus];
					
					NSImage *r = [NSImage imageNamed: @"PlayTemplate.png"];
					
					[r drawInRect: [self centerRect: NSMakeRect( 0,  0, [r size].width, [r size].height) inRect: NSMakeRect( 0,  0, [newImage size].width, [newImage size].height)] fromRect: NSMakeRect( 0,  0, [r size].width, [r size].height)  operation: NSCompositeSourceOver fraction: 1.0];
					
					[newImage unlockFocus];
				}
				
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [newImage TIFFRepresentation]];
				
				if ([[fileURL pathExtension] isEqualToString: @"png"])
				{
					NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
					data = [imageRep representationUsingType:NSPNGFileType properties: imageProps];
				}
				else if ([[fileURL pathExtension] isEqualToString: @"jpg"])
				{
					NSDictionary *imageProps = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: 0.8] forKey:NSImageCompressionFactor];
					data = [imageRep representationUsingType: NSJPEGFileType properties: imageProps];
				}
				else NSLog( @"***** unknown path extension: %@", [fileURL pathExtension]);
			}
		}
		
		err = NO;
	}*/
	
}

-(void)processMovie {/*
	
	{
		NSPredicate *browsePredicate;
		if ([[parameters allKeys] containsObject:@"id"])
		{
			if ([[parameters allKeys] containsObject:@"studyID"])
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", [parameters objectForKey:@"studyID"], [parameters objectForKey:@"id"]];
			else
				browsePredicate = [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@", [parameters objectForKey:@"id"]];
		}
		else
			browsePredicate = [NSPredicate predicateWithValue:NO];
		
		NSArray *series = [self seriesForPredicate:browsePredicate];
		
		if ([series count] == 1)
		{
			data = [self produceMovieForSeries: [series lastObject] isiPhone: isIOS fileURL: fileURL lockReleased: &lockReleased];
		}
		
		if (data == nil || [data length] == 0)
			NSLog( @"****** movie data == nil");
		
		err = NO;
	}
	*/
}


@end





