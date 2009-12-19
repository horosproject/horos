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

static PSGenerator *generator = nil;

@implementation UserTable

- (void) generatePassword
{
	if( generator == nil)
		generator = [[PSGenerator alloc] initWithSourceString: @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" minLength: 8 maxLength: 8];
	
	[self setPrimitiveValue: [[generator generate: 1] lastObject] forKey: @"password"];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	if( [self primitiveValueForKey: @"passwordCreationDate"] == nil)
		[self setValue: [NSDate date] forKey: @"passwordCreationDate"];
	
	[self generatePassword];
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
			
			return NO;
		}
	}
	
	return YES;
}
@end
