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
#import "N2Debug.h"
#import "DicomAlbum.h"

@implementation WebPortal (Databases)

-(NSArray*)arrayByAddingSpecificStudiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate toArray:(NSArray*)array
{
	NSMutableArray *specificArray = [NSMutableArray array];
	BOOL truePredicate = NO;
	
	if (!predicate)
	{
		predicate = [NSPredicate predicateWithValue: YES];
		truePredicate = YES;
	}
	
	@try
	{
		NSArray* userStudies = user.studies.allObjects;
		
		if( userStudies.count == 0)
			return array;
		
		// Find studies
        // Ne faut-il pas un lock? Si, et je switch to [*Database objectsForEntity..]
		NSArray* studiesArray = [self.dicomDatabase objectsForEntity:self.dicomDatabase.studyEntity predicate:predicate];
		
		for (WebPortalStudy* study in userStudies)
		{
			NSArray *obj = nil;
			
			if (user.canAccessPatientsOtherStudies.boolValue)
				obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@", study.patientUID]];
			else
				obj = [studiesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", study.patientUID, study.studyInstanceUID]];
			
			if ([obj count] >= 1)
			{
				for( id o in obj)
				{
					if ([array containsObject: o] == NO && [specificArray containsObject: o] == NO)
						[specificArray addObject: o];
				}
			}
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

-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate
{
	return [self studiesForUser:user predicate:predicate sortBy:NULL];
}

-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue
{
	return [self studiesForUser: user predicate: predicate sortBy: sortValue fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies
{
	NSArray* studiesArray = nil;
	
	[self.dicomDatabase.managedObjectContext lock];
	
	@try
	{
		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
		req.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext:self.dicomDatabase.managedObjectContext];
		
		BOOL allStudies = NO;
		if( user.studyPredicate.length == 0)
			allStudies = YES;
		
		if( allStudies == NO)
		{
			if( predicate)
				req.predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects:	[DicomDatabase predicateForSmartAlbumFilter:user.studyPredicate],
																												predicate,
																												nil]];
			else
				req.predicate = [DicomDatabase predicateForSmartAlbumFilter:user.studyPredicate];
			
			studiesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
			
			if (user)
				studiesArray = [self arrayByAddingSpecificStudiesForUser:user predicate: predicate toArray:studiesArray];
			
			if (user.canAccessPatientsOtherStudies.boolValue)
			{
				NSFetchRequest* req = [[NSFetchRequest alloc] init];
				req.entity = [self.dicomDatabase entityForName:@"Study"];
				req.predicate = [NSPredicate predicateWithFormat:@"patientID IN %@", [studiesArray valueForKey:@"patientID"]];
				
				int previousStudiesArrayCount = studiesArray.count;
				
				studiesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
				
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
			
			studiesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
		}
        
        if( [sortValue length])
		{
			if( [sortValue rangeOfString: @"date"].location == NSNotFound)
				studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: sortValue ascending: YES selector: @selector( caseInsensitiveCompare:)]]];
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
	} @finally {
		[self.dicomDatabase.managedObjectContext unlock];
	}
	
	return studiesArray;
}

//-(NSArray*)seriesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate {
//	NSArray *seriesArray = nil;
//	NSArray *studiesArray = nil;
//	
//	[self.dicomDatabase.managedObjectContext lock];
//	
//	if( [seriesForUsersCache objectForKey: user.name])
//	{
//		if( [[[seriesForUsersCache objectForKey: user.name] objectForKey: @"timeStamp"] timeIntervalSinceNow] > -60) // 60 secs
//		{
//			NSMutableArray *returnedArray = [NSMutableArray arrayWithCapacity: [[[seriesForUsersCache objectForKey: user.name] objectForKey: @"seriesArray"] count]];
//			
//			for( NSManagedObject *o in [[seriesForUsersCache objectForKey: user.name] objectForKey: @"seriesArray"])
//			{
//				if( [o isFault] == NO)
//					[returnedArray addObject: o];
//			}
//			
//			[self.dicomDatabase.managedObjectContext unlock];
//			
//			return returnedArray;
//		}
//	}
//	
//	if (user.studyPredicate.length) // First, take all the available studies for this user, and then get the series : SECURITY : we want to be sure that he cannot access to unauthorized images
//	{
//		@try
//		{
//			NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
//			req.entity = [self.dicomDatabase entityForName:@"Study"];
//			req.predicate = [DicomDatabase predicateForSmartAlbumFilter:user.studyPredicate];
//			
//			studiesArray = [self arrayByAddingSpecificStudiesForUser:user predicate:NULL toArray:[self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL]];
//			studiesArray = [studiesArray valueForKey: @"patientUID"];
//		}
//		
//		@catch(NSException *e)
//		{
//			NSLog(@"************ seriesForPredicate exception: %@", e.description);
//		}
//	}
//	
//	@try
//	{
//		NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
//		req.entity = [self.dicomDatabase entityForName:@"Series"];
//		
//		if (studiesArray)
//			predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, [NSPredicate predicateWithFormat: @"study.patientUID IN %@", studiesArray], nil]];
//			
//		req.predicate = predicate;
//		
//		seriesArray = [self.dicomDatabase.managedObjectContext executeFetchRequest:req error:NULL];
//	}
//	
//	@catch(NSException *e)
//	{
//		NSLog(@"*********** seriesForPredicate exception: %@", e.description);
//	}
//	
//	[seriesForUsersCache setObject: [NSDictionary dictionaryWithObjectsAndKeys: seriesArray, @"seriesArray", [NSDate date], @"timeStamp", nil] forKey: user.name];
//	
//	[self.dicomDatabase.managedObjectContext unlock];
//	
//	/*if ([seriesArray count] > 1)
//	{
//		NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
//		NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
//		NSArray * sortDescriptors;
//		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
//		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
//		[sortid release];
//		[sortdate release];
//		
//		seriesArray = [seriesArray sortedArrayUsingDescriptors: sortDescriptors];
//	}*/
//	
//	return seriesArray;
//}

-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName {
	return [self studiesForUser:user album:albumName sortBy:nil];
}

-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName sortBy:(NSString*)sortValue
{
    return [self studiesForUser: user album: albumName sortBy: sortValue fetchLimit: 0 fetchOffset: 0 numberOfStudies: nil];
}

-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies
{
	

	
    NSArray* albumArray = [self.dicomDatabase objectsForEntity:self.dicomDatabase.albumEntity predicate:[NSPredicate predicateWithFormat:@"name == %@", albumName]];
	DicomAlbum* album = [albumArray lastObject];
	
    NSArray* studiesArray = nil;
    
	if (album.smartAlbum.intValue == 1)
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

@end
