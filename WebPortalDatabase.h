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

#import <Cocoa/Cocoa.h>


@class WebPortalUser;


@interface WebPortalDatabase : NSObject {
    NSManagedObjectContext* managedObjectContext;
}

+(NSManagedObjectModel*)managedObjectModel;

@property(readonly,retain) NSManagedObjectContext* managedObjectContext;

-(id)initWithContext:(NSManagedObjectContext*)context;

-(void)save:(NSError**)err;
-(NSEntityDescription*)entityForName:(NSString*)name;
-(NSManagedObject*)objectWithID:(NSString*)theId;

-(WebPortalUser*)userWithName:(NSString*)name;
-(WebPortalUser*)newUser;

@end
