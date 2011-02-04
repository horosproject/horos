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

#import "WebPortal+Email+Log.h"
#import "WebPortal+Databases.h"
#import "WebPortalDatabase.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSString+N2.h"
#import "NSMutableString+N2.h"
#import "WebPortalUser.h"
#import "DicomStudy.h"
#import "CSMailMailClient.h"
#import "DicomDatabase.h"
#import "AppController.h"


@implementation WebPortal (EmailLog)

-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate message:(NSString*)message replyTo:(NSString*)replyto customText:(NSString*)customText webServerAddress:(NSString*)webServerAddress
{
	if (!self.notificationsEnabled)
		return NO;
	
	if (!webServerAddress)
		webServerAddress = WebPortal.defaultWebPortal.address;
	NSString* webServerURL = [self URLForAddress:webServerAddress];
	
	NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
	if (fromEmailAddress == nil)
		fromEmailAddress = @"";
	
	for (WebPortalUser* user in users) {
		NSMutableAttributedString *emailMessage = nil;
		
		if (message == nil)
			emailMessage = [[[NSMutableAttributedString alloc] initWithData:[self dataForPath:@"emailTemplate.txt"] options:NULL documentAttributes:nil error:NULL] autorelease];
		else
			emailMessage = [[[NSMutableAttributedString alloc] initWithString: message] autorelease];
		
		if (emailMessage)
		{
			if (customText == nil) customText = @"";
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%customText%" withString:N2NonNullString([customText stringByAppendingString:@"\r\r"])];
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%Username%" withString:N2NonNullString(user.name)];
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%WebServerAddress%" withString:webServerURL];
			
			NSMutableString *urls = [NSMutableString string];
			
			if ([filteredStudies count] > 1 && predicate != nil)
			{
				[urls appendString: NSLocalizedString( @"To view this entire list, including patients names:\r", nil)]; 
				[urls appendFormat: @"%@ : %@/studyList?%@\r\r\r\r", NSLocalizedString( @"Click here", nil), webServerURL, predicate]; 
			}
			
			for (DicomStudy* s in filteredStudies)
			{
				[urls appendFormat: @"%@ - %@ (%@)\r", s.modality, s.studyName, [NSUserDefaults.dateTimeFormatter stringFromDate:s.date]]; 
				[urls appendFormat: @"%@ : %@/study?id=%@&browse=all\r\r", NSLocalizedString( @"Click here", nil), webServerURL, s.studyInstanceUID]; 
			}
			
			[[emailMessage mutableString] replaceOccurrencesOfString: @"%URLsList%" withString:N2NonNullString(urls)];
			
			NSString *emailAddress = user.email;
			
			NSString *emailSubject = nil;
			if (replyto)
				emailSubject = [NSString stringWithFormat: NSLocalizedString( @"A new radiology exam is available for you, from %@", nil), replyto];
			else
				emailSubject = NSLocalizedString( @"A new radiology exam is available for you !", nil);
			
			[[CSMailMailClient mailClient] deliverMessage: emailMessage headers: [NSDictionary dictionaryWithObjectsAndKeys: emailAddress, @"To", fromEmailAddress, @"Sender", emailSubject, @"Subject", replyto, @"ReplyTo", nil]];
			
			for ( NSManagedObject *s in filteredStudies)
			{
				[self updateLogEntryForStudy: s withMessage: @"notification email" forUser:user.name ip:webServerAddress];
			}
		}
		else NSLog( @"********* warning : CANNOT send notifications emails, because emailTemplate.txt == nil");
	}
	
	return YES; // succeeded
}

-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate message:(NSString*)message replyTo:(NSString*)replyto customText:(NSString*)customText {
	return [self sendNotificationsEmailsTo:users aboutStudies:filteredStudies predicate:predicate message:message replyTo:replyto customText:customText webServerAddress:NULL];
}

- (void) emailNotifications
{
	if ([NSThread isMainThread] == NO)
	{
		NSLog( @"********* applescript needs to be in the main thread");
		return;
	}
	
	// Lets check if new studies are available for each users! and if temporary users reached the end of their life.....
	
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]];
	NSString *newCheckString = [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"lastNotificationsDate"] == nil)
	{
		[[NSUserDefaults standardUserDefaults] setValue: [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]] forKey: @"lastNotificationsDate"];
		return;
	}
	
	if ([self.dicomDatabase tryLock])
	{
		[WebPortal.defaultWebPortal.database.managedObjectContext lock];
		
		// TEMPORARY USERS
		
		@try
		{
			BOOL toBeSaved = NO;
			
			// Find all users
			NSError *error = nil;
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			dbRequest.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:WebPortal.defaultWebPortal.database.managedObjectContext];
			dbRequest.predicate = [NSPredicate predicateWithValue:YES];
			
			error = nil;
			NSArray *users = [WebPortal.defaultWebPortal.database.managedObjectContext executeFetchRequest: dbRequest error:&error];
			
			for (WebPortalUser* user in users)
			{
				if (user.autoDelete.boolValue == YES && user.deletionDate && [user.deletionDate timeIntervalSinceDate: [NSDate date]] < 0)
				{
					NSLog( @"----- Temporary User reached the EOL (end-of-life) : %@", user.name);
					
					[self updateLogEntryForStudy:nil withMessage: @"temporary user deleted" forUser:user.name ip:NSUserDefaults.webPortalAddress];
					
					toBeSaved = YES;
					[WebPortal.defaultWebPortal.database.managedObjectContext deleteObject: user];
				}
			}
			
			if (toBeSaved)
				[WebPortal.defaultWebPortal.database save:NULL];
		}
		@catch (NSException *e)
		{
			NSLog( @"***** emailNotifications exception for deleting temporary users: %@", e);
		}
		
		// CHECK dateAdded
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"notificationsEmails"] == YES)
		{
			@try
			{
				NSFetchRequest* dbRequest = nil;
				// Find all studies AFTER the lastCheckDate
				dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [dicomDatabase entityForName:@"Study"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
				NSArray *studies = [dicomDatabase.managedObjectContext executeFetchRequest:dbRequest error:NULL];
				
				if ([studies count] > 0)
				{
					// Find all users
					dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:database.managedObjectContext]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
					NSArray *users = [WebPortal.defaultWebPortal.database.managedObjectContext executeFetchRequest: dbRequest error:NULL];
					
					for (WebPortalUser* user in users)
					{
						if ([[user valueForKey: @"emailNotification"] boolValue] == YES && [(NSString*) [user valueForKey: @"email"] length] > 2)
						{
							NSArray *filteredStudies = studies;
							
							@try
							{
								filteredStudies = [studies filteredArrayUsingPredicate: [DicomDatabase predicateForSmartAlbumFilter: [user valueForKey: @"studyPredicate"]]];
								filteredStudies = [self arrayByAddingSpecificStudiesForUser:user predicate:[NSPredicate predicateWithFormat: @"dateAdded > CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]] toArray:filteredStudies];
								
								filteredStudies = [filteredStudies filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"dateAdded > CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]]]; 
								filteredStudies = [filteredStudies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
							}
							@catch (NSException * e)
							{
								NSLog( @"******* studyPredicate exception : %@ %@", e, user);
							}
							
							if ([filteredStudies count] > 0)
							{
								[self sendNotificationsEmailsTo: [NSArray arrayWithObject: user] aboutStudies: filteredStudies predicate: [NSString stringWithFormat: @"browse=newAddedStudies&browseParameter=%lf", [lastCheckDate timeIntervalSinceReferenceDate]] message: nil replyTo: nil customText: nil];
							}
						}
					}
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"***** emailNotifications exception: %@", e);
			}
		}
		[WebPortal.defaultWebPortal.database.managedObjectContext unlock];
		[dicomDatabase.managedObjectContext unlock];
	}
	
	[[NSUserDefaults standardUserDefaults] setValue: newCheckString forKey: @"lastNotificationsDate"];
}

-(void)updateLogEntryForStudy:(DicomStudy*)study withMessage:(NSString*)message forUser:(NSString*)user ip:(NSString*)ip
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"logWebServer"] == NO) return;
	
	[self.dicomDatabase.managedObjectContext lock];
	
	@try {
		if (user)
			message = [user stringByAppendingFormat:@": %@", message];
		
		if (!ip)
			ip = [[AppController sharedAppController] privateIP];
		
		// Search for same log entry during last 5 min
		NSArray* logs = NULL;
		@try {
			NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
			req.entity = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:self.dicomDatabase.managedObjectContext];
			req.predicate = [NSPredicate predicateWithFormat: @"(patientName==%@) AND (studyName==%@) AND (message==%@) AND (originName==%@) AND (endTime >= CAST(%lf, \"NSDate\"))", study.name, study.studyName, message, ip, [[NSDate dateWithTimeIntervalSinceNow: -5 * 60] timeIntervalSinceReferenceDate]];
			logs = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
		} @catch (NSException* e) {
			NSLog(@"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		if (!logs.count) {
			NSManagedObject* logEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:self.dicomDatabase.managedObjectContext];
			[logEntry setValue:[NSDate date] forKey:@"startTime"];
			[logEntry setValue:[NSDate date] forKey:@"endTime"];
			[logEntry setValue:@"Web" forKey:@"type"];
			
			if (study) {
				[logEntry setValue:study.name forKey:@"patientName"];
				[logEntry setValue:study.studyName forKey:@"studyName"];
			}
			
			[logEntry setValue:message forKey:@"message"];
			
			if (ip)
				[logEntry setValue:ip forKey:@"originName"];
		} else
			[logs setValue: [NSDate date] forKey: @"endTime"];
	} @catch (NSException* e) {
		NSLog( @"****** OsiriX HTTPConnection updateLogEntry exception : %@", e);
	} @finally {
		[self.dicomDatabase.managedObjectContext unlock];
	}
}

@end
