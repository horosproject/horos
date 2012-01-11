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

#import "WebPortalUser.h"
#import "DicomDatabase.h"
#import "PSGenerator.h"
#import "WebPortal.h"
#import "AppController.h"
#import "NSError+OsiriX.h"
#import "DDData.h"
#import "NSData+N2.h"

static PSGenerator *generator = nil;

@implementation WebPortalUser

@dynamic address;
@dynamic autoDelete;
@dynamic canAccessPatientsOtherStudies;
@dynamic canSeeAlbums;
@dynamic creationDate;
@dynamic deletionDate;
@dynamic downloadZIP;
@dynamic email;
@dynamic emailNotification;
@dynamic encryptedZIP;
@dynamic isAdmin;
@dynamic name;
@dynamic password;
@dynamic passwordHash;
@dynamic passwordCreationDate;
@dynamic phone;
@dynamic sendDICOMtoAnyNodes;
@dynamic sendDICOMtoSelfIP;
@dynamic shareStudyWithUser;
@dynamic studyPredicate;
@dynamic uploadDICOM;
@dynamic downloadReport;
@dynamic uploadDICOMAddToSpecificStudies;
@dynamic studies;

- (void) generatePassword
{
	if( generator == nil)
		generator = [[PSGenerator alloc] initWithSourceString: @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" minLength: 12 maxLength: 12];
	
	[self setValue: [[generator generate: 1] lastObject] forKey: @"password"];
}

- (NSString*) email
{
	if( [self primitiveValueForKey: @"email"] == nil)
		return @"";
	
	return [self primitiveValueForKey: @"email"];
}

- (NSString*) phone
{
	if( [self primitiveValueForKey: @"phone"] == nil)
		return @"";
	
	return [self primitiveValueForKey: @"phone"];
}

- (NSString*) address
{
	if( [self primitiveValueForKey: @"address"] == nil)
		return @"";
	
	return [self primitiveValueForKey: @"address"];
}

- (void) awakeFromInsert
{
	[super awakeFromInsert];
	
	if( [self primitiveValueForKey: @"passwordCreationDate"] == nil)
		[self setPrimitiveValue: [NSDate date] forKey: @"passwordCreationDate"];
	
	if( [self primitiveValueForKey: @"creationDate"] == nil)
		[self setPrimitiveValue: [NSDate date] forKey: @"creationDate"];
	
	if( [self primitiveValueForKey: @"dateAdded"] == nil)
		[self setPrimitiveValue: [NSDate date] forKey: @"dateAdded"];

	if( [self primitiveValueForKey: @"studyPredicate"] == nil)
		[self setPrimitiveValue: @"(YES == NO)" forKey: @"studyPredicate"];
	
	[self generatePassword];

	// Create a unique name
	unsigned long long uid = 100. * [NSDate timeIntervalSinceReferenceDate];
	[self setPrimitiveValue: [NSString stringWithFormat: @"user %llu", uid] forKey: @"name"];
}


- (void) setAutoDelete: (NSNumber*) v
{
	if( [v boolValue])
	{
		[self setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [NSDate timeIntervalSinceReferenceDate] + [[NSUserDefaults standardUserDefaults] integerForKey: @"temporaryUserDuration"] * 60L*60L*24L] forKey: @"deletionDate"];
	}
	
	[self setPrimitiveValue: v forKey: @"autoDelete"];
}

- (void) setName: (NSString*) newName
{
    if( [newName isEqualToString: self.name] == NO)
    {
        if( [self.password length] > 0 && [self.password isEqualToString: HASHPASSWORD] == NO)
        {
            
        }
        else
        {
            NSLog( @"------- WebPortalUser : name changed -> password reset");
            [self generatePassword];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: @"WebPortalUsernameChanged" object: self];
        }
        
        [self willChangeValueForKey: @"name"];
        [self setPrimitiveValue: newName forKey: @"name"];
        [self didChangeValueForKey: @"name"];
    }
}

- (void) setPassword: (NSString*) newPassword
{
	if( [newPassword length] >= 4 && [newPassword isEqualToString: HASHPASSWORD] == NO)
	{
		[self setValue: [NSDate date] forKey: @"passwordCreationDate"];
        
        [self willChangeValueForKey: @"password"];
        [self setPrimitiveValue: newPassword forKey: @"password"];
        [self didChangeValueForKey: @"password"];
        
        [self setPrimitiveValue: @"" forKey: @"passwordHash"];
        [self setPrimitiveValue: [NSDate date] forKey: @"passwordCreationDate"];
    }
}

- (void) convertPasswordToHashIfNeeded
{
    if( [self.password length] > 0 && [self.password isEqualToString: HASHPASSWORD] == NO) // We dont want to store password, only sha1Digest version ! 
    {
        self.passwordHash = [[[[self.password stringByAppendingString: self.name] dataUsingEncoding:NSUTF8StringEncoding] sha1Digest] hex];
        
        [self willChangeValueForKey: @"password"];
        [self setPrimitiveValue: HASHPASSWORD forKey: @"password"];
        [self didChangeValueForKey: @"password"];
        
        NSLog( @"---- Convert password to hash string. Delete original password for user: %@", self.name);
    }
}

-(BOOL)validatePassword:(NSString**)value error:(NSError**)error
{
    NSString *password2validate = *value;
    
    if( [password2validate isEqualToString: HASHPASSWORD] == NO)
    {
        if( [[password2validate stringByReplacingOccurrencesOfString: @"*" withString: @""] length] == 0)
        {
            if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString( @"Password cannot contain only '*' characters.", NULL)];
            return NO;
        }
	    
        if( [password2validate length] < 4)
        {
            if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString( @"Password needs to be at least 4 characters long.", NULL)];
            return NO;
        }
        
        if( [password2validate stringByTrimmingCharactersInSet: [NSCharacterSet decimalDigitCharacterSet]].length == 0)
        {
            if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString( @"Password cannot contain only numbers: add letters.", NULL)];
            return NO;
        }
        
        if( [password2validate stringByReplacingOccurrencesOfString: [password2validate substringToIndex: 1] withString: @""].length == 0)
        {
            if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString( @"Password cannot contain only the same character.", NULL)];
            return NO;
        }
    }
	
	return YES;
}

-(BOOL)validateDownloadZIP:(NSNumber**)value error:(NSError**)error {
	if ([*value boolValue] && !AppController.hasMacOSXSnowLeopard) {
		if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString(@"ZIP download requires MacOS 10.6 or higher.", NULL)];
		return NO;
	}
	
	return YES;
}

-(BOOL)validateName:(NSString**)value error:(NSError**)error {
	if ([*value length] < 2) {
		if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString(@"Name needs to be at least 2 characters long.", NULL)];
		return NO;
	}
	
	[self.managedObjectContext lock];
	@try {
		NSError* err = NULL;
		NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
		request.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
		request.predicate = [NSPredicate predicateWithFormat:@"name == %@", *value];
		NSArray* users = [self.managedObjectContext executeFetchRequest:request error:&err];
		if (err) [NSException exceptionWithName:NSGenericException reason:@"Database error." userInfo:[NSDictionary dictionaryWithObject:err forKey:NSUnderlyingErrorKey]];
		
		if ((users.count == 1 && users.lastObject != self) || users.count > 1) {
			if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString(@"A user with that name already exists. Two users cannot have the same name.", NULL)];
			return NO;
		}
	} @catch (NSException* e) {
		NSLog(@"*** [WebPortalUser validateName:error:] exception: %@", e);
		NSDictionary* info = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Internal database error.", NULL) forKey:NSLocalizedDescriptionKey];
		if (error) *error = [NSError errorWithDomain:@"OsiriXDomain" code:-31 userInfo:info];
		return NO;
	} @finally {
		[self.managedObjectContext unlock];
	}

	return YES;
}

-(BOOL)validateStudyPredicate:(NSString**)value error:(NSError**)error {
	@try {
		NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
		request.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext:self.managedObjectContext];
		request.predicate = [DicomDatabase predicateForSmartAlbumFilter:*value];
		
		NSError* e = NULL;
		[WebPortal.defaultWebPortal.dicomDatabase.managedObjectContext executeFetchRequest:request error:&e];
		if (e) {
			if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescriptionFormat:NSLocalizedString(@"Syntax error in study predicate filter: %@", NULL), e.localizedDescription? e.localizedDescription : NSLocalizedString(@"Unknown Error", NULL)];
			return NO;
		}
	} @catch (NSException* e) {
		NSLog(@"*** [WebPortalUser validateStudyPredicate:error:] exception: %@", e);
		*error = [NSError osirixErrorWithCode:-31 localizedDescription:[NSString stringWithFormat:NSLocalizedString(@"Error: %@", nil), e]];
		return NO;
	}
	
	return YES;
}

@end



