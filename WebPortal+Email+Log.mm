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
#import "N2Debug.h"

// TODO: NSUserDefaults access for keys @"logWebServer", @"notificationsEmailsSender" and @"lastNotificationsDate" must be replaced with WebPortal properties


@implementation WebPortal (EmailLog)

- (void) sendEmailOnMainThread: (NSDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *ts = [dict objectForKey: @"template"];
	NSDictionary *messageHeaders = [dict objectForKey: @"headers"];
	
	[[CSMailMailClient mailClient] deliverMessage:ts headers:messageHeaders];

	[pool release];
}

-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate customText:(NSString*)customText
{
    return [self sendNotificationsEmailsTo: users aboutStudies: filteredStudies predicate: predicate customText: customText from: nil];
}

-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate customText:(NSString*)customText from:(WebPortalUser*) from
{
	NSString *fromEmailAddress = [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"];
	if (fromEmailAddress == nil)
		fromEmailAddress = @"";
	
	for (WebPortalUser* user in users) {
		NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
		
		if (customText) [tokens setObject:customText forKey:@"customText"];
		[tokens setObject:user forKey:@"Destination"];
        if( from)
            [tokens setObject:from forKey:@"FromUser"];
		[tokens setObject:self.URL forKey:@"WebServerURL"];
		[tokens setObject:filteredStudies forKey:@"Studies"];
		if (predicate) [tokens setObject:predicate forKey:@"predicate"];
		
		NSMutableString* ts = [[[self stringForPath:@"emailTemplate.html"] mutableCopy] autorelease];
		[WebPortalResponse mutableString:ts evaluateTokensWithDictionary:tokens context:NULL];
		
		NSString* emailSubject = NSLocalizedString(@"A new radiology exam is available for you", nil);
		
		NSMutableDictionary* messageHeaders = [NSMutableDictionary dictionary];
		[messageHeaders setObject:user.email forKey:@"To"];
		[messageHeaders setObject:fromEmailAddress forKey:@"Sender"];
		[messageHeaders setObject:emailSubject forKey:@"Subject"];
		
		// NSAttributedString initWithHTML is NOT thread-safe
		[self performSelectorOnMainThread: @selector(sendEmailOnMainThread:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ts, @"template", messageHeaders, @"headers", nil] waitUntilDone: NO];
		
		for (NSManagedObject* s in filteredStudies)
			[self updateLogEntryForStudy:s withMessage: @"notification email" forUser:user.name ip:nil];
	}
	
	return YES; // succeeded
}

// TEMPORARY USERS
- (void) deleteTemporaryUsers:(NSTimer*)timer
{
    [database.managedObjectContext lock];
    
    @try
    {
        BOOL toBeSaved = NO;
        
        NSArray *users = [database objectsForEntity:database.userEntity];
        
        for (WebPortalUser* user in users)
        {
            if (user.autoDelete.boolValue == YES && user.deletionDate && [user.deletionDate timeIntervalSinceNow] < 0)
            {
                NSLog( @"----- Temporary User reached the EOL (end-of-life) : %@", user.name);
                
                [self updateLogEntryForStudy:nil withMessage: @"temporary user deleted" forUser:user.name ip:nil];
                
                toBeSaved = YES;
                [database.managedObjectContext deleteObject:user];
            }
        }
        
        if (toBeSaved)
            [database save:NULL];
    }
    @catch (NSException *e)
    {
        NSLog( @"***** deleteTemporaryUsers exception for deleting temporary users: %@", e);
    }
    
    [database.managedObjectContext unlock];
}

- (void) emailNotifications
{
	if ([NSThread isMainThread] == NO)
	{
		NSLog( @"********* emailNotifications: applescript needs to be in the main thread");
		return;
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"] == NO)
		return;
	
	// Lets check if new studies are available for each users! and if temporary users reached the end of their life.....
	
	NSDate *lastCheckDate = [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]];
	NSString *newCheckString = [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"lastNotificationsDate"] == nil)
	{
		[[NSUserDefaults standardUserDefaults] setValue: [NSString stringWithFormat: @"%lf", [NSDate timeIntervalSinceReferenceDate]] forKey: @"lastNotificationsDate"];
		return;
	}
	
    [database.managedObjectContext lock];
    
    // CHECK dateAdded
    
    if (self.notificationsEnabled)
    {
        @try
        {
            // Find all studies AFTER the lastCheckDate
            NSArray *studies = [dicomDatabase objectsForEntity:@"Study"];
            
            if ([studies count] > 0)
            {
                NSArray *users = [database objectsForEntity:database.userEntity];
                
                for (WebPortalUser* user in users)
                {
                    if ([[user valueForKey: @"emailNotification"] boolValue] == YES && [(NSString*) [user valueForKey: @"email"] length] > 2)
                    {
                        NSArray *filteredStudies = studies;
                        
                        @try
                        {
                            filteredStudies = [studies filteredArrayUsingPredicate: [DicomDatabase predicateForSmartAlbumFilter: [user valueForKey: @"studyPredicate"]]];
                            
                            if( user.studyPredicate.length)
                                filteredStudies = [user arrayByAddingSpecificStudiesToArray: filteredStudies];
                            
                            filteredStudies = [filteredStudies filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"dateAdded > CAST(%lf, \"NSDate\")", [lastCheckDate timeIntervalSinceReferenceDate]]]; 
                            filteredStudies = [filteredStudies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
                        }
                        @catch (NSException * e)
                        {
                            NSLog( @"******* studyPredicate exception : %@ %@", e, user);
                        }
                        
                        if ([filteredStudies count] > 0)
                        {
                            [self sendNotificationsEmailsTo: [NSArray arrayWithObject: user] aboutStudies:[dicomDatabase objectsWithIDs:filteredStudies] predicate: [NSString stringWithFormat: @"browse=newAddedStudies&browseParameter=%lf", [lastCheckDate timeIntervalSinceReferenceDate]] customText: nil];
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
    [database.managedObjectContext unlock];
	
	[[NSUserDefaults standardUserDefaults] setValue: newCheckString forKey: @"lastNotificationsDate"];
}

-(void)updateLogEntryForStudy:(DicomStudy*)study withMessage:(NSString*)message forUser:(NSString*)user ip:(NSString*)ip
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"logWebServer"] == NO) return;
	
    DicomDatabase* independentDatabase = nil;
    
    if( [NSThread isMainThread])
        independentDatabase = self.dicomDatabase;
    else
        independentDatabase = self.dicomDatabase.independentDatabase;
    
	@try {
		if (user)
			message = [user stringByAppendingFormat:@": %@", message];
		
		if (!ip)
			ip = [[AppController sharedAppController] privateIP];
		
		// Search for same log entry during last 5 min
		NSArray* logs = NULL;
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat: @"(patientName==%@) AND (studyName==%@) AND (message==%@) AND (originName==%@) AND (endTime >= CAST(%lf, \"NSDate\"))", study.name, study.studyName, message, ip, [[NSDate dateWithTimeIntervalSinceNow: -5 * 60] timeIntervalSinceReferenceDate]];
        logs = [independentDatabase objectsForEntity:independentDatabase.logEntryEntity predicate:predicate];
		
		if (!logs.count) {
			NSManagedObject* logEntry = [independentDatabase newObjectForEntity:independentDatabase.logEntryEntity];
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
		[independentDatabase save];
	}
}

-(WebPortalUser*)newUserWithEmail:(NSString*)email 
{
	// create user
	
	//NSArray* users = [self usersWithPredicate:[NSPredicate predicateWithFormat:@"email ==[cd] %@", email]];
	//if (users.count)
	//	[NSException raise:NSGenericException format:NSLocalizedString(@"A user with email %@ already exists.", NULL), email];
	
	if (![email isEmail])
		[NSException raise:NSGenericException format:NSLocalizedString(@"%@ is not an email address.", NULL), email];
	
    
    NSArray *existingUsers = [self.database.independentDatabase usersWithPredicate:[NSPredicate predicateWithFormat:@"email == %@", email]];
    
    WebPortalUser* user = nil;
    
    if( existingUsers.count)
        user = [existingUsers objectAtIndex: 0];
    else
    {
        user = [self.database.independentDatabase newUser];
        user.email = email;
        user.name = [email substringToIndex:[email rangeOfString:@"@"].location];
        
        for (int i = 1; ![user validateForInsert:nil]; ++i)
            user.name = [[email substringToIndex:[email rangeOfString:@"@"].location] stringByAppendingFormat:@"-%d", i];
        
        user.autoDelete = [NSNumber numberWithBool:YES];
        
        // send message
        NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
        
        [tokens setObject:user forKey:@"User"];
        [tokens setObject:self.URL forKey:@"WebServerURL"];
        
        NSMutableString* ts = [[[self stringForPath:@"tempUserEmail.html"] mutableCopy] autorelease];
        [WebPortalResponse mutableString:ts evaluateTokensWithDictionary:tokens context:NULL];
        
        NSString* emailSubject = [NSString stringWithFormat:NSLocalizedString(@"Temporary account on %@", nil), self.URL];
        
        NSMutableDictionary* messageHeaders = [NSMutableDictionary dictionary];
        [messageHeaders setObject:user.email forKey:@"To"];
        
        if( [[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"])
            [messageHeaders setObject:[[NSUserDefaults standardUserDefaults] valueForKey: @"notificationsEmailsSender"] forKey:@"Sender"];
        else
            [messageHeaders setObject: @"" forKey:@"Sender"];
        [messageHeaders setObject:emailSubject forKey:@"Subject"];
        
        // NSAttributedString initWithHTML is NOT thread-safe
        [self performSelectorOnMainThread: @selector(sendEmailOnMainThread:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ts, @"template", messageHeaders, @"headers", nil] waitUntilDone: NO];
    }
	
	return user;
}

@end
