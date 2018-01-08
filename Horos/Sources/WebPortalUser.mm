/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "WebPortalUser.h"
#import "WebPortalStudy.h"
#import "WebPortalDatabase.h"
#import "DicomDatabase.h"
#import "PSGenerator.h"
#import "WebPortal.h"
#import "AppController.h"
#import "NSError+OsiriX.h"
#import "DDData.h"
#import "NSData+N2.h"
#import "BrowserController.h"
#import "QueryController.h"
#import "DicomStudy.h"
#import "DCMTKStudyQueryNode.h"
#import "WebPortalResponse.h"

static PSGenerator *generator = nil;
static NSMutableDictionary *studiesForUserCache = nil;

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
@dynamic createTemporaryUser;
@dynamic studyPredicate;
@dynamic uploadDICOM;
@dynamic downloadReport;
@dynamic uploadDICOMAddToSpecificStudies;
@dynamic studies;
@dynamic recentStudies;
@dynamic showRecentPatients;

#define TIMEOUT 5*60

+ (NSArray*) cachedArrayForArray: (NSArray*) studiesArray
{
    NSMutableArray *cachedObjects = [NSMutableArray arrayWithArray: studiesArray];

    for( int i = 0; i < cachedObjects.count; i++)
    {
        if( [[cachedObjects objectAtIndex: i] isKindOfClass: [DCMTKStudyQueryNode class]] == NO)
            [cachedObjects replaceObjectAtIndex: i withObject: [[cachedObjects objectAtIndex: i] objectID]];
    }
    
    return cachedObjects;
}
                                 
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
    
    [self willChangeValueForKey: @"name"];
	[self setPrimitiveValue: [NSString stringWithFormat: @"user %llu", uid] forKey: @"name"];
    [self didChangeValueForKey: @"name"];
}


- (void) setAutoDelete: (NSNumber*) v
{
	if( [v boolValue])
	{
		[self setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [NSDate timeIntervalSinceReferenceDate] + [[NSUserDefaults standardUserDefaults] integerForKey: @"temporaryUserDuration"] * 60L*60L*24L] forKey: @"deletionDate"];
	}
	[self willChangeValueForKey: @"autoDelete"];
	[self setPrimitiveValue: v forKey: @"autoDelete"];
    [self didChangeValueForKey: @"autoDelete"];
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
        
        [self willChangeValueForKey: @"passwordHash"];
        [self setPrimitiveValue: @"" forKey: @"passwordHash"];
        [self didChangeValueForKey: @"passwordHash"];
        
        [self willChangeValueForKey: @"passwordCreationDate"];
        [self setPrimitiveValue: [NSDate date] forKey: @"passwordCreationDate"];
        [self didChangeValueForKey: @"passwordCreationDate"];
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
        
        if( [password2validate length] - [[password2validate commonPrefixWithString: self.name options: NSCaseInsensitiveSearch] length] < 4)
        {
            if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString( @"Password needs to be different from the user name.", NULL)];
            return NO;
        }
        
        NSUInteger invidualCharacters = 0;
        NSMutableArray *array = [NSMutableArray array];
        for( int i = 0; i < [password2validate length]; i++)
        {
            NSString *character = [password2validate substringWithRange: NSMakeRange( i, 1)];
            if( [array containsObject: character] == NO)
            {
                invidualCharacters++;
                [array addObject: character];
            }
        }
        
        if( invidualCharacters < 3)
        {
            if (error) *error = [NSError osirixErrorWithCode:-31 localizedDescription:NSLocalizedString( @"Password needs to have at least 3 different characters.", NULL)];
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
	
	@try {
		NSError* err = NULL;
		NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
		request.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
		request.predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", *value];
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
	}

	return YES;
}

-(BOOL)validateStudyPredicate:(NSString**)value error:(NSError**)error
{
    DicomDatabase *dicomDBContext = [NSThread isMainThread] ? WebPortal.defaultWebPortal.dicomDatabase : [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
    
	@try {
		NSFetchRequest* request = [[[NSFetchRequest alloc] init] autorelease];
		request.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext:self.managedObjectContext];
		request.predicate = [DicomDatabase predicateForSmartAlbumFilter:*value];
		
		NSError* e = NULL;
		[dicomDBContext.managedObjectContext executeFetchRequest:request error:&e];
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

-(NSArray*)arrayByAddingSpecificStudiesToArray:(NSArray*)array
{
	NSMutableArray *specificArray = nil;
	
    if( array == nil)
        array = [NSArray array];
    
	@try
	{
		NSArray* userStudies = self.studies.allObjects;
		
		if( userStudies.count == 0)
			return array;
        
        NSString *userID = [self.name stringByAppendingString: @" specificStudies"];
        
        @synchronized( studiesForUserCache)
        {
            if( userID && [studiesForUserCache objectForKey: userID] && [[[studiesForUserCache objectForKey: userID] objectForKey: @"date"] timeIntervalSinceNow] > -TIMEOUT) // one hour
            {
                DicomDatabase *dicomDBContext = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
                
                NSMutableArray *cachedObjects = [NSMutableArray arrayWithArray: [[studiesForUserCache objectForKey: userID] objectForKey: @"array"]];
                
                for( int i = 0; i < cachedObjects.count; i++)
                {
                    if( [[cachedObjects objectAtIndex: i] isKindOfClass: [NSManagedObjectID class]])
                        [cachedObjects replaceObjectAtIndex: i withObject: [dicomDBContext objectWithID: [cachedObjects objectAtIndex: i]]];
                }
                
                specificArray = cachedObjects;
            }
        }
        
        if( specificArray == nil)
        {
            NSArray* studiesArray = nil;
            
            @synchronized( studiesForUserCache)
            {
                if( [studiesForUserCache objectForKey: @"all DB studies"] && [[[studiesForUserCache objectForKey: @"all DB studies"] objectForKey: @"date"] timeIntervalSinceNow] > -TIMEOUT)
                {
                    DicomDatabase *dicomDBContext = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
                    
                    NSMutableArray *cachedObjects = [NSMutableArray arrayWithArray: [[studiesForUserCache objectForKey: @"all DB studies"] objectForKey: @"array"]];
                    
                    for( int i = 0; i < cachedObjects.count; i++)
                    {
                        if( [[cachedObjects objectAtIndex: i] isKindOfClass: [NSManagedObjectID class]])
                            [cachedObjects replaceObjectAtIndex: i withObject: [dicomDBContext objectWithID: [cachedObjects objectAtIndex: i]]];
                    }
                    
                    studiesArray = cachedObjects;
                }
            }
            
            if( studiesArray == nil)
            {
                DicomDatabase *dicomDBContext = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
                
                [dicomDBContext lock];
                
                // Find all studies
                NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
                req.entity = [NSEntityDescription entityForName: @"Study" inManagedObjectContext:dicomDBContext.managedObjectContext];
                req.predicate = [NSPredicate predicateWithValue: YES];
                studiesArray = [dicomDBContext.managedObjectContext executeFetchRequest:req error:NULL];
                
                @synchronized( studiesForUserCache)
                {
                    if( studiesArray)
                        [studiesForUserCache setObject: [NSDictionary dictionaryWithObjectsAndKeys: [WebPortalUser cachedArrayForArray: studiesArray], @"array", [NSDate date], @"date", nil] forKey: @"all DB studies"];
                }
                
                [dicomDBContext unlock];
            }
            
            specificArray = [NSMutableArray array];
            
            for (WebPortalStudy* study in userStudies)
            {
                NSArray *obj = nil;
                
                if (self.canAccessPatientsOtherStudies.boolValue)
                    obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID BEGINSWITH[cd] %@", study.patientUID]];
                else
                    obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID BEGINSWITH[cd] %@ AND studyInstanceUID == %@", study.patientUID, study.studyInstanceUID]];
                
                if ([obj count] >= 1)
                {
                    for( id o in obj)
                    {
                        if ([array containsObject: o] == NO && [specificArray containsObject: o] == NO)
                            [specificArray addObject: o];
                    }
                }
                else if ([obj count] == 0)
                {
                    // It means this study doesnt exist in the entire DB -> remove it from this user list
                    NSLog( @"This study is not longer available in the DB -> delete it : %@", [study valueForKey: @"patientUID"]);
                    [self.managedObjectContext deleteObject:study];
                    [self.managedObjectContext save: nil];
                }
            }
            
            @synchronized( studiesForUserCache)
            {
                if( userID)
                    [studiesForUserCache setObject: [NSDictionary dictionaryWithObjectsAndKeys: [WebPortalUser cachedArrayForArray: specificArray], @"array", [NSDate date], @"date", nil] forKey: userID];
            }
        }
	}
	@catch (NSException * e)
	{
		NSLog( @"********** addSpecificStudiesToArray : %@", e);
	}
	
	for (id study in array)
		if (![specificArray containsObject:study])
			[specificArray addObject:study];
	
	return specificArray;
}

-(NSArray*)studiesForPredicate:(NSPredicate*)predicate
{
	return [self studiesForPredicate:predicate sortBy:NULL];
}

-(NSArray*)studiesForPredicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue
{
	return [self studiesForPredicate: predicate sortBy: sortValue fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

-(NSArray*)studiesForPredicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies
{
    return [WebPortalUser studiesForUser: self predicate: predicate sortBy: sortValue fetchLimit: fetchLimit fetchOffset: fetchOffset numberOfStudies: numberOfStudies];
}

+(NSArray*)studiesForUser: (WebPortalUser*) user predicate:(NSPredicate*)predicate;
{
    return [WebPortalUser studiesForUser: user predicate: predicate sortBy: nil fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

+(NSArray*)studiesForUser: (WebPortalUser*) user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue;
{
    return [WebPortalUser studiesForUser: user predicate: predicate sortBy: sortValue fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

+(NSArray*)studiesForUser: (WebPortalUser*) user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies
{
	NSArray* studiesArray = nil;
	
    DicomDatabase *dicomDBContext = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
    
	@try
	{
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext: dicomDBContext.managedObjectContext];
		
		BOOL allStudies = NO;
		if( user.studyPredicate.length == 0)
			allStudies = YES;
		
		if( allStudies == NO)
		{
            req.predicate = [DicomDatabase predicateForSmartAlbumFilter: user.studyPredicate];
			
            if( studiesForUserCache == nil && user)
            {
                studiesForUserCache = [[NSMutableDictionary alloc] init];
                [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(managedObjectChangedNotificationReceived:) name: NSManagedObjectContextObjectsDidChangeNotification object: nil];
            }
            
            NSString *userID = user.name;
            
            @synchronized( studiesForUserCache)
            {
                if( user && [studiesForUserCache objectForKey: userID] && [[[studiesForUserCache objectForKey: userID] objectForKey: @"date"] timeIntervalSinceNow] > -TIMEOUT)
                {
                    NSMutableArray *cachedObjects = [NSMutableArray arrayWithArray: [[studiesForUserCache objectForKey: userID] objectForKey: @"array"]];
                    
                    for( int i = 0; i < cachedObjects.count; i++)
                    {
                        if( [[cachedObjects objectAtIndex: i] isKindOfClass: [NSManagedObjectID class]])
                            [cachedObjects replaceObjectAtIndex: i withObject: [dicomDBContext objectWithID: [cachedObjects objectAtIndex: i]]];
                    }
                    
                    studiesArray = cachedObjects;
                }
            }
            
            if( studiesArray == nil)
            {
                studiesArray = [dicomDBContext.managedObjectContext executeFetchRequest:req error:NULL];
                
                @synchronized( studiesForUserCache)
                {
                    if( user && studiesArray)
                        [studiesForUserCache setObject: [NSDictionary dictionaryWithObjectsAndKeys: [WebPortalUser cachedArrayForArray: studiesArray], @"array", [NSDate date], @"date", nil] forKey: userID];
                }
            }
            
            if( user && user.studyPredicate.length > 0)
				studiesArray = [user arrayByAddingSpecificStudiesToArray: studiesArray];
            
            if( predicate)
                studiesArray = [studiesArray filteredArrayUsingPredicate: predicate];
            
			if( user.canAccessPatientsOtherStudies.boolValue)
			{
				NSFetchRequest* req = [[NSFetchRequest alloc] init];
				req.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext: dicomDBContext.managedObjectContext];
				req.predicate = [NSPredicate predicateWithFormat:@"patientUID IN %@", [studiesArray valueForKey:@"patientUID"]];
				
				int previousStudiesArrayCount = studiesArray.count;
				
				studiesArray = [dicomDBContext.managedObjectContext executeFetchRequest:req error:NULL];
				
				if( predicate && studiesArray.count != previousStudiesArrayCount)
					studiesArray = [studiesArray filteredArrayUsingPredicate: predicate];
				
				[req release];
			}
		}
		else
		{
			if( predicate == nil)
				predicate = [NSPredicate predicateWithValue: YES];
			
			req.predicate = predicate;
			
			studiesArray = [dicomDBContext.managedObjectContext executeFetchRequest:req error:NULL];
		}
        
        if( [sortValue length])
		{
			if( [sortValue rangeOfString: @"date"].location == NSNotFound)
				studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: sortValue ascending: YES selector: @selector(caseInsensitiveCompare:)]]];
			else
				studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: sortValue ascending: NO]]];
		}
        
		if( numberOfStudies)
			*numberOfStudies = studiesArray.count;
		
        if( fetchLimit)
        {
            NSRange range = NSMakeRange( fetchOffset, fetchLimit);
            
            if( range.location > studiesArray.count)
                range.location = studiesArray.count;
            
            if( range.location + range.length > studiesArray.count)
                range.length = studiesArray.count - range.location;
            
            studiesArray = [studiesArray subarrayWithRange: range];
        }
		
	} @catch(NSException* e) {
		NSLog(@"Error: [WebPortal studiesForUser:predicate:sortBy:] %@", e);
	}
	
    if( studiesArray == nil)
        studiesArray = [NSArray array];
    
	return studiesArray;
}

-(NSArray*)studiesForAlbum:(NSString*)albumName
{
	return [self studiesForAlbum:albumName sortBy:nil];
}

-(NSArray*)studiesForAlbum:(NSString*)albumName sortBy:(NSString*)sortValue
{
    return [self studiesForAlbum: albumName sortBy: sortValue fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

-(NSArray*)studiesForAlbum:(NSString*)albumName sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies
{
    return [WebPortalUser studiesForUser: self album: albumName sortBy: sortValue fetchLimit: fetchLimit fetchOffset: fetchOffset numberOfStudies: numberOfStudies];
}

+(NSArray*)studiesForUser: (WebPortalUser*) user album:(NSString*)albumName;
{
    return [WebPortalUser studiesForUser: user album: albumName sortBy: nil fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

+(NSArray*)studiesForUser: (WebPortalUser*) user album:(NSString*)albumName sortBy:(NSString*)sortValue;
{
    return [WebPortalUser studiesForUser: user album: albumName sortBy: sortValue fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

+ (void) managedObjectChangedNotificationReceived: (NSNotification*) n
{
    @synchronized( studiesForUserCache)
    {
        NSMutableSet *set = [NSMutableSet set];
        
        if( [n.userInfo objectForKey: NSInsertedObjectsKey])
            [set unionSet: [n.userInfo objectForKey: NSInsertedObjectsKey]];
        
        if( [n.userInfo objectForKey: NSDeletedObjectsKey])
            [set unionSet: [n.userInfo objectForKey: NSDeletedObjectsKey]];
        
        for( NSManagedObject *object in set)
        {
            if( [object isKindOfClass: [DicomStudy class]] || [object isKindOfClass: [WebPortalUser class]] || [object isKindOfClass: [WebPortalStudy class]])
            {
                [studiesForUserCache removeAllObjects];
                [DicomStudyTransformer clearOtherStudiesForThisPatientCache];
                return;
            }
        }
        
        // WebPortal User updated ?
        
        set = [NSMutableSet set];
        
        if( [n.userInfo objectForKey: NSUpdatedObjectsKey])
            [set unionSet: [n.userInfo objectForKey: NSUpdatedObjectsKey]];
        
        for( NSManagedObject *object in set)
        {
            if( [object isKindOfClass: [WebPortalUser class]])
            {
                [studiesForUserCache removeAllObjects];
                [DicomStudyTransformer clearOtherStudiesForThisPatientCache];
                return;
            }
        }
    }
}

+(NSArray*)studiesForUser: (WebPortalUser*) user album:(NSString*)albumName sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies
{
	NSArray *studiesArray = nil, *albumArray = nil;
	
    if( studiesForUserCache == nil && user)
    {
        studiesForUserCache = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(managedObjectChangedNotificationReceived:) name: NSManagedObjectContextObjectsDidChangeNotification object: nil];
    }
    
    NSString *userID = [user.name stringByAppendingFormat:@" %@", albumName];
    
    @synchronized( studiesForUserCache)
    {
        if( user && [studiesForUserCache objectForKey: userID] && [[[studiesForUserCache objectForKey: userID] objectForKey: @"date"] timeIntervalSinceNow] > -TIMEOUT)
        {
            DicomDatabase *dicomDBContext = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
            
            NSMutableArray *cachedObjects = [NSMutableArray arrayWithArray: [[studiesForUserCache objectForKey: userID] objectForKey: @"array"]];
            
            for( int i = 0; i < cachedObjects.count; i++)
            {
                if( [[cachedObjects objectAtIndex: i] isKindOfClass: [NSManagedObjectID class]])
                    [cachedObjects replaceObjectAtIndex: i withObject: [dicomDBContext objectWithID: [cachedObjects objectAtIndex: i]]];
            }
            
            studiesArray = cachedObjects;
            
            if ([sortValue length] && [sortValue isEqualToString: @"date"] == NO)
                studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES selector: @selector(caseInsensitiveCompare:)] autorelease]]];
            else
                studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
        }
    }
    
    if( studiesArray == nil)
    {
        DicomDatabase *dicomDBContext = [WebPortal.defaultWebPortal.dicomDatabase independentDatabase];
        
        [dicomDBContext.managedObjectContext lock];
        
        @try
        {
            NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
            req.entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:dicomDBContext.managedObjectContext];
            req.predicate = [NSPredicate predicateWithFormat:@"name == %@", albumName];
            albumArray = [dicomDBContext.managedObjectContext executeFetchRequest:req error:NULL];
        }
        @catch(NSException *e)
        {
            NSLog(@"******** studiesForAlbum exception: %@", e.description);
        }
        
        [dicomDBContext.managedObjectContext unlock];
        
        NSManagedObject *album = [albumArray lastObject];
        
        if ([[album valueForKey:@"smartAlbum"] intValue] == 1)
        {
            studiesArray = [WebPortalUser studiesForUser: user predicate:[DicomDatabase predicateForSmartAlbumFilter:[album valueForKey:@"predicateString"]] sortBy:sortValue];
            
            // PACS On Demand
            NSString *pred = [user.studyPredicate uppercaseString];
            pred = [pred stringByReplacingOccurrencesOfString:@" " withString: @""];
            pred = [pred stringByReplacingOccurrencesOfString:@"(" withString: @""];
            pred = [pred stringByReplacingOccurrencesOfString:@")" withString: @""];
            if( user == nil || pred.length == 0 || [pred isEqualToString: @"YES==YES"])
            {
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"ActivatePACSOnDemandForWebPortalAlbums"])
                {
//                    BOOL usePatientID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientIDForUID"];
//                    BOOL usePatientBirthDate = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientBirthDateForUID"];
//                    BOOL usePatientName = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientNameForUID"];
                    
                    // Servers
                    NSArray *servers = [BrowserController comparativeServers];
                    
                    if( servers.count)
                    {
                        // Distant studies
                        // In current versions, two filters exist: modality & date
                        NSArray *distantStudies = nil;
                        for( NSDictionary *d in [[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"])
                        {
                            if( [[d valueForKey: @"activated"] boolValue] && [albumName isEqualToString: [d valueForKey: @"name"]])
                                distantStudies = [QueryController queryStudiesForFilters: d servers: servers showErrors: NO];
                        }
                        
                        if( distantStudies.count)
                        {
                            NSMutableArray *mutableStudiesArray = [NSMutableArray arrayWithArray: studiesArray];
                            
                            // Merge local and distant studies
                            for( DCMTKStudyQueryNode *distantStudy in distantStudies)
                            {
                                if( [[mutableStudiesArray valueForKey: @"studyInstanceUID"] containsObject: [distantStudy studyInstanceUID]] == NO)
                                    [mutableStudiesArray addObject: distantStudy];
                                
                                else if( [[NSUserDefaults standardUserDefaults] boolForKey: @"preferStudyWithMoreImages"])
                                {
                                    NSUInteger index = [[mutableStudiesArray valueForKey: @"studyInstanceUID"] indexOfObject: [distantStudy studyInstanceUID]];
                                    
                                    if( index != NSNotFound && [[[mutableStudiesArray objectAtIndex: index] rawNoFiles] intValue] < [[distantStudy noFiles] intValue])
                                    {
                                        [mutableStudiesArray replaceObjectAtIndex: index withObject: distantStudy];
                                    }
                                }
                            }
                            
                            studiesArray = mutableStudiesArray;
                        }
                    }
                }
            }
        }
        else
        {
            NSArray *originalAlbum = [[album valueForKey:@"studies"] allObjects];
            
            if( user.studyPredicate.length)
            {
                @try
                {
                    studiesArray = [originalAlbum filteredArrayUsingPredicate: [DicomDatabase predicateForSmartAlbumFilter: user.studyPredicate]];
                    
                    NSArray *specificArray = [user arrayByAddingSpecificStudiesToArray: nil];
                    
                    for ( NSManagedObject *specificStudy in specificArray)
                    {
                        if ([originalAlbum containsObject: specificStudy] == YES && [studiesArray containsObject: specificStudy] == NO)
                        {
                            studiesArray = [studiesArray arrayByAddingObject: specificStudy];						
                        }
                    }
                }
                @catch( NSException *e)
                {
                    NSLog( @"****** User Filter Error : %@", e);
                    NSLog( @"****** NO studies will be displayed.");
                    
                    studiesArray = nil;
                }
            }
            else studiesArray = originalAlbum;
        }
        
        if ([sortValue length] && [sortValue isEqualToString: @"date"] == NO)
            studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES selector: @selector(caseInsensitiveCompare:)] autorelease]]];
        else
            studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
        
        @synchronized( studiesForUserCache)
        {
            if( user && studiesArray)
            {
                [studiesForUserCache setObject: [NSDictionary dictionaryWithObjectsAndKeys: [WebPortalUser cachedArrayForArray: studiesArray], @"array", [NSDate date], @"date", nil] forKey: userID];
            }
        }
    }
        
    if( numberOfStudies)
        *numberOfStudies = studiesArray.count;
    
    if( fetchLimit)
    {
        NSRange range = NSMakeRange( fetchOffset, fetchLimit);
        
        if( range.location > studiesArray.count)
            range.location = studiesArray.count;
        
        if( range.location + range.length > studiesArray.count)
            range.length = studiesArray.count - range.location;
        
        studiesArray = [studiesArray subarrayWithRange: range];
    }
    
	return studiesArray;
}

- (NSArray*) recentPatients
{
    NSMutableArray *recentPatients = [NSMutableArray array];
    
    NSDate *oldestDate = [[NSDate date] dateByAddingTimeInterval: -[NSUserDefaults.standardUserDefaults doubleForKey: @"WebPortalMaximumNumberOfDaysForRecentStudies"]*86400.];
    
    NSSet *recentStudies = [self.recentStudies filteredSetUsingPredicate:[NSPredicate predicateWithFormat: @"dateAdded > CAST(%lf, \"NSDate\")", [oldestDate timeIntervalSinceReferenceDate]]];
    
    for( NSString *patientUID in [[NSSet setWithArray: [recentStudies.allObjects valueForKey: @"patientUID"]] allObjects])
    {
        DicomDatabase* ddb = [[[WebPortal defaultWebPortal] dicomDatabase] independentDatabase];
        
        NSArray *studies = [ddb objectsForEntity: @"Study" predicate: [NSPredicate predicateWithFormat: @"patientUID == %@", patientUID]];
        
        if( studies.count)
        {
            //take the most recent study
            [recentPatients addObject: [[studies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"date" ascending: YES]]] lastObject]];
        }
    }
    
    [recentPatients sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES]]];
    
    return recentPatients;
}

@end



