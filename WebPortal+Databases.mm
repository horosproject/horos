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

#import "WebPortal+Databases.h"
#import "WebPortalUser.h"
#import "DicomDatabase.h"
#import "WebPortalDatabase.h"
#import "WebPortalStudy.h"

@implementation WebPortal (Databases)

-(NSArray*)arrayByAddingSpecificStudiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate toArray:(NSArray*)array
{
	NSMutableArray *specificArray = [NSMutableArray array];
	BOOL truePredicate = NO;
	
	if (!predicate) {
		predicate = [NSPredicate predicateWithValue: YES];
		truePredicate = YES;
	}
	
	@try
	{
		NSArray* userStudies = user.studies.allObjects;
		
		if (truePredicate == NO) {
			NSArray* allUserStudies = userStudies;
			NSArray* userStudies = [allUserStudies filteredArrayUsingPredicate:predicate];
			
			NSMutableArray* excludedStudies = [NSMutableArray arrayWithArray: allUserStudies];
			[excludedStudies removeObjectsInArray: userStudies];
			
			NSMutableArray* mutableArray = [NSMutableArray arrayWithArray: array];
			
			// First remove all user studies from array, we will re-add them after, if necessary
			for ( NSManagedObject *study in excludedStudies)
			{
				NSArray *obj = [mutableArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", [study valueForKey: @"patientUID"], [study valueForKey: @"studyInstanceUID"]]];
				
				if ([obj count] == 1)
				{
					[mutableArray removeObject: [obj lastObject]];
				}
				else if ([obj count] > 1)
					NSLog( @"********** warning multiple studies with same instanceUID and patientUID : %@", obj);
					}
			
			array = mutableArray;
		}
			
		// Find all studies of the DB
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext:self.dicomDatabase.managedObjectContext];
		req.predicate = [NSPredicate predicateWithValue:YES];
		NSArray* studiesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
		
		if (!userStudies)
			[specificArray addObjectsFromArray:studiesArray];
		else
			for (WebPortalStudy* study in userStudies) {
				NSArray *obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", study.patientUID, study.studyInstanceUID]];
				
				if ([obj count] == 1)
				{
					if ([array containsObject: [obj lastObject]] == NO && [specificArray containsObject: [obj lastObject]] == NO)
						[specificArray addObject: [obj lastObject]];
				}
				else if ([obj count] > 1)
					NSLog( @"********** warning multiple studies with same instanceUID and patientUID : %@", obj);
				else if (truePredicate && [obj count] == 0)
				{
					// It means this study doesnt exist in the entire DB -> remove it from this user list
					NSLog( @"This study is not longer available in the DB -> delete it : %@", [study valueForKey: @"patientUID"]);
					[self.database.managedObjectContext deleteObject:study];
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

-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate {
	return [self studiesForUser:user predicate:predicate sortBy:NULL];
}

-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue {
	NSArray* studiesArray = nil;
	
	[self.dicomDatabase.managedObjectContext lock];
	
	@try {
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext:self.dicomDatabase.managedObjectContext];
		req.predicate = [DicomDatabase predicateForSmartAlbumFilter:user.studyPredicate];
		studiesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
		
		if (user)
			studiesArray = [self arrayByAddingSpecificStudiesForUser:user predicate:NULL toArray:studiesArray];
		
		if (user.canAccessPatientsOtherStudies.boolValue) {
			NSFetchRequest* req = [[NSFetchRequest alloc] init];
			req.entity = [self.dicomDatabase entityForName:@"Study"];
			req.predicate = [NSPredicate predicateWithFormat:@"patientID IN %@", [studiesArray valueForKey:@"patientID"]];
			studiesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
			[req release];
		}
			
		if (predicate) studiesArray = [studiesArray filteredArrayUsingPredicate:predicate];
		
		if ([sortValue length] && [sortValue isEqualToString: @"date"] == NO)
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES selector: @selector( caseInsensitiveCompare:)] autorelease]]];
		else
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO] autorelease]]];
	
	} @catch(NSException* e) {
		NSLog(@"Error: [WebPortal studiesForUser:predicate:sortBy:] %@", e);
	} @finally {
		[self.dicomDatabase.managedObjectContext unlock];
	}
	
	return studiesArray;
}

-(NSArray*)seriesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate {
	NSArray *seriesArray = nil;
	NSArray *studiesArray = nil;
	
	[self.dicomDatabase.managedObjectContext lock];
	
	if( [seriesForUsersCache objectForKey: user.name])
	{
		if( [[[seriesForUsersCache objectForKey: user.name] objectForKey: @"timeStamp"] timeIntervalSinceNow] > -60) // 60 secs
		{
			NSMutableArray *returnedArray = [NSMutableArray arrayWithCapacity: [[[seriesForUsersCache objectForKey: user.name] objectForKey: @"seriesArray"] count]];
			
			for( NSManagedObject *o in [[seriesForUsersCache objectForKey: user.name] objectForKey: @"seriesArray"])
			{
				if( [o isFault] == NO)
					[returnedArray addObject: o];
			}
			
			[self.dicomDatabase.managedObjectContext unlock];
			
			return returnedArray;
		}
	}
	
	if (user.studyPredicate.length) // First, take all the available studies for this user, and then get the series : SECURITY : we want to be sure that he cannot access to unauthorized images
	{
		@try
		{
			NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
			req.entity = [self.dicomDatabase entityForName:@"Study"];
			req.predicate = [DicomDatabase predicateForSmartAlbumFilter:user.studyPredicate];
			
			studiesArray = [self arrayByAddingSpecificStudiesForUser:user predicate:NULL toArray:[self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL]];
			studiesArray = [studiesArray valueForKey: @"patientUID"];
		}
		
		@catch(NSException *e)
		{
			NSLog(@"************ seriesForPredicate exception: %@", e.description);
		}
	}
	
	@try
	{
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [self.dicomDatabase entityForName:@"Series"];
		
		if (studiesArray)
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, [NSPredicate predicateWithFormat: @"study.patientUID IN %@", studiesArray], nil]];
			
		req.predicate = predicate;
		
		seriesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
	}
	
	@catch(NSException *e)
	{
		NSLog(@"*********** seriesForPredicate exception: %@", e.description);
	}
	
	[seriesForUsersCache setObject: [NSDictionary dictionaryWithObjectsAndKeys: seriesArray, @"seriesArray", [NSDate date], @"timeStamp", nil] forKey: user.name];
	
	[self.dicomDatabase.managedObjectContext unlock];
	
	/*if ([seriesArray count] > 1)
	{
		NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
		NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSArray * sortDescriptors;
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
		[sortid release];
		[sortdate release];
		
		seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
	}*/
	
	return seriesArray;
}

-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName {
	return [self studiesForUser:user album:albumName sortBy:nil];
}

-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName sortBy:(NSString*)sortValue {
	
	NSArray *studiesArray = nil, *albumArray = nil;
	
	[self.dicomDatabase.managedObjectContext lock];
	
	@try
	{
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [self.dicomDatabase entityForName:@"Album"];
		req.predicate = [NSPredicate predicateWithFormat:@"name == %@", albumName];
		albumArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
	}
	@catch(NSException *e)
	{
		NSLog(@"******** studiesForAlbum exception: %@", e.description);
	}
	
	[self.dicomDatabase.managedObjectContext unlock];
	
	NSManagedObject *album = [albumArray lastObject];
	
	if ([[album valueForKey:@"smartAlbum"] intValue] == 1)
	{
		studiesArray = [self studiesForUser:user predicate:[DicomDatabase predicateForSmartAlbumFilter:[album valueForKey:@"predicateString"]] sortBy:sortValue];
	}
	else
	{
		NSArray *originalAlbum = [[album valueForKey:@"studies"] allObjects];
		
		if (user.studyPredicate.length)
		{
			@try
			{
				studiesArray = [originalAlbum filteredArrayUsingPredicate: [DicomDatabase predicateForSmartAlbumFilter:user.studyPredicate]];
				
				NSArray *specificArray = [self arrayByAddingSpecificStudiesForUser:user predicate:NULL toArray:NULL];
				
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
			
		if ([sortValue length] && [sortValue isEqualToString: @"date"] == NO)
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: sortValue ascending: YES selector: @selector( caseInsensitiveCompare:)] autorelease]]];
		else
			studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];								
	}
	
	//return [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease]]];
	return studiesArray;
}

@end
