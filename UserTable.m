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

#import "UserTable.h"
#import "PSGenerator.h"
#import "BrowserController.h"

static PSGenerator *generator = nil;

@implementation UserTable

- (void) generatePassword
{
	if( generator == nil)
		generator = [[PSGenerator alloc] initWithSourceString: @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" minLength: 12 maxLength: 12];
	
	[self setPrimitiveValue: [[generator generate: 1] lastObject] forKey: @"password"];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	if( [self primitiveValueForKey: @"passwordCreationDate"] == nil)
		[self setPrimitiveValue: [NSDate date] forKey: @"passwordCreationDate"];
	
	[self generatePassword];

	// Create a unique name
	unsigned long long uid = 100. * [NSDate timeIntervalSinceReferenceDate];
	[self setPrimitiveValue: [NSString stringWithFormat: @"user %llu", uid] forKey: @"name"];
}

- (void) setPassword: (NSString*) newPassword
{
	if( [newPassword isEqualToString: [self primitiveValueForKey: @"password"]] == NO)
	{
		[self setValue: [NSDate date] forKey: @"passwordCreationDate"];
	}
	
	[self setPrimitiveValue: newPassword forKey: @"password"];
}

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
	if( [key isEqualToString: @"password"] && [*value length] < 4)
	{
		if( error)
		{
			NSDictionary *info = [NSDictionary dictionaryWithObject: NSLocalizedString( @"Password needs to be at least 4 characters.", nil) forKey: NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain: @"OsiriXDomain" code: -31 userInfo: info];
		}	
		return NO;
	}
	
	if( [key isEqualToString: @"password"])
		[self setPrimitiveValue: [NSDate date] forKey: @"passwordCreationDate"];
	
	if( [key isEqualToString: @"name"])
	{
		if( [*value length] < 4) // Length
		{
			if( error)
			{
				NSDictionary *info = [NSDictionary dictionaryWithObject: NSLocalizedString( @"Name needs to be at least 4 characters.", nil) forKey: NSLocalizedDescriptionKey];
				*error = [NSError errorWithDomain: @"OsiriXDomain" code: -31 userInfo: info];
			}	
			return NO;
		}
		
		[[[BrowserController currentBrowser] userManagedObjectContext] lock];
		
		NSArray	*users = nil;
		@try
		{
			NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
			[request setEntity: [[[[BrowserController currentBrowser] userManagedObjectModel] entitiesByName] objectForKey:@"User"]];
			[request setPredicate: [NSPredicate predicateWithFormat:@"name == %@", *value]];
			
			NSError *err = nil;
			users = [[[BrowserController currentBrowser] userManagedObjectContext] executeFetchRequest: request error: &err];
		}
		@catch ( NSException *e)
		{
			NSLog( @"******* validateValue UserTable exception: %@", e);
		}

		[[[BrowserController currentBrowser] userManagedObjectContext] unlock];
		
		if( ([users count] == 1 && [users lastObject] != self) || [users count] > 1)
		{
			if( error)
			{
				NSDictionary *info = [NSDictionary dictionaryWithObject: NSLocalizedString( @"Name needs to be unique. Two users cannot have the same name.", nil) forKey: NSLocalizedDescriptionKey];
				*error = [NSError errorWithDomain: @"OsiriXDomain" code: -31 userInfo: info];
			}	
			return NO;
		}
	}
	
	return YES;
}
@end
