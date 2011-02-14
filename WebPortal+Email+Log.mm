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
#import "WebPortalResponse.h"
#import "NSUserDefaults+OsiriX.h"
#import "NSString+N2.h"
#import "NSMutableString+N2.h"
#import "WebPortalUser.h"
#import "DicomStudy.h"
#import "CSMailMailClient.h"
#import "DicomDatabase.h"
#import "AppController.h"
#import "NSManagedObject+N2.h"

// TODO: NSUserDefaults access for keys @"logWebServer", @"notificationsEmailsSender" and @"lastNotificationsDate" must be replaced with WebPortal properties


@implementation WebPortal (EmailLog)

-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate replyTo:(NSString*)replyto customText:(NSString*)customText
{
	if (!self.notificationsEnabled)
		return NO;
	
	NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
	if (fromEmailAddress == nil)
		fromEmailAddress = @"";
	
	for (WebPortalUser* user in users) {
		NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
		
		if (customText) [tokens setObject:customText forKey:@"customText"];
		[tokens setObject:user forKey:@"Destination"];
		[tokens setObject:self.URL forKey:@"WebServerURL"];
		
		NSMutableString* urls = [NSMutableString string];
		
		if ([filteredStudies count] > 1 && predicate != nil) {
			[urls appendString: NSLocalizedString( @"<br/>To view this entire list, including patients names:<br/>", nil)]; 
			NSString* url = [NSString stringWithFormat:@"%@/studyList?%@", self.URL, predicate];
			[urls appendFormat: @"%@: <a href=\"%@\">%@</a><br/>", NSLocalizedString(@"Click here", nil), url, url]; 
		}
		
		for (DicomStudy* s in filteredStudies) {
			[urls appendFormat: @"<br/>%@ - %@ (%@)<br/>", s.modality, s.studyName, [NSUserDefaults.dateTimeFormatter stringFromDate:s.date]]; 
			NSString* url = [NSString stringWithFormat:@"%@/study?xid=%@", self.URL, s.XID];
			[urls appendFormat: @"%@: <a href=\"%@\">%@</a><br/>", NSLocalizedString(@"Click here", nil), url, url]; 
		}
		
		[tokens setObject:urls forKey:@"URLsList"];
		
		NSMutableString* ts = [[[self stringForPath:@"emailTemplate.html"] mutableCopy] autorelease];
		[WebPortalResponse mutableString:ts evaluateTokensWithDictionary:tokens context:NULL];
		
		NSString *emailSubject = NSLocalizedString(@"A new radiology exam is available for you", nil);
		if (replyto)
			emailSubject = [NSString stringWithFormat:NSLocalizedString(@"A new radiology exam is available for you, from %@", nil), replyto];
		
		NSMutableDictionary* messageHeaders = [NSMutableDictionary dictionary];
		[messageHeaders setObject:user.email forKey:@"To"];
		[messageHeaders setObject:fromEmailAddress forKey:@"Sender"];
		[messageHeaders setObject:emailSubject forKey:@"Subject"];
		if (replyto) [messageHeaders setObject:replyto forKey:@"ReplyTo"];
		[[CSMailMailClient mailClient] deliverMessage:[[[NSAttributedString alloc] initWithHTML:[ts dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL] autorelease] headers:messageHeaders];
		
		for (NSManagedObject* s in filteredStudies)
			[self updateLogEntryForStudy:s withMessage: @"notification email" forUser:user.name ip:nil];
	}
	
	return YES; // succeeded
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
					
					[self updateLogEntryForStudy:nil withMessage: @"temporary user deleted" forUser:user.name ip:nil];
					
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
		
		if (self.notificationsEnabled)
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
								[self sendNotificationsEmailsTo: [NSArray arrayWithObject: user] aboutStudies: filteredStudies predicate: [NSString stringWithFormat: @"browse=newAddedStudies&browseParameter=%lf", [lastCheckDate timeIntervalSinceReferenceDate]] replyTo: nil customText: nil];
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
