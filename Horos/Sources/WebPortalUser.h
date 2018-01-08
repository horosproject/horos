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


#import <Cocoa/Cocoa.h>

#define HASHPASSWORD @"**********"

/** \brief  Core Data Entity for a web user */
@class WebPortalStudy;

@interface WebPortalUser : NSManagedObject {
}

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * autoDelete;
@property (nonatomic, retain) NSNumber * canAccessPatientsOtherStudies;
@property (nonatomic, retain) NSNumber * canSeeAlbums;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSDate * deletionDate;
@property (nonatomic, retain) NSNumber * downloadZIP;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * emailNotification;
@property (nonatomic, retain) NSNumber * encryptedZIP;
@property (nonatomic, retain) NSNumber * isAdmin;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * passwordHash;
@property (nonatomic, retain) NSDate * passwordCreationDate;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * sendDICOMtoAnyNodes;
@property (nonatomic, retain) NSNumber * sendDICOMtoSelfIP;
@property (nonatomic, retain) NSNumber * shareStudyWithUser;
@property (nonatomic, retain) NSNumber * createTemporaryUser;
@property (nonatomic, retain) NSString * studyPredicate;
@property (nonatomic, retain) NSNumber * uploadDICOM;
@property (nonatomic, retain) NSNumber * downloadReport;
@property (nonatomic, retain) NSNumber * uploadDICOMAddToSpecificStudies;
@property (nonatomic, retain) NSSet* studies;
@property (nonatomic, retain) NSSet* recentStudies;
@property (nonatomic, retain) NSNumber * showRecentPatients;

-(void)generatePassword;
-(void)convertPasswordToHashIfNeeded;

-(BOOL)validatePassword:(NSString**)value error:(NSError**)error;
-(BOOL)validateDownloadZIP:(NSNumber**)value error:(NSError**)error;
-(BOOL)validateName:(NSString**)value error:(NSError**)error;
-(BOOL)validateStudyPredicate:(NSString**)value error:(NSError**)error;

-(NSArray*)arrayByAddingSpecificStudiesToArray:(NSArray*)array;

-(NSArray*)studiesForPredicate:(NSPredicate*)predicate;
-(NSArray*)studiesForPredicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue;
-(NSArray*)studiesForPredicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies;

+(NSArray*)studiesForUser: (WebPortalUser*) user predicate:(NSPredicate*)predicate;
+(NSArray*)studiesForUser: (WebPortalUser*) user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue;
+(NSArray*)studiesForUser: (WebPortalUser*) user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies;

-(NSArray*)studiesForAlbum:(NSString*)albumName;
-(NSArray*)studiesForAlbum:(NSString*)albumName sortBy:(NSString*)sortValue;
-(NSArray*)studiesForAlbum:(NSString*)albumName sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies;

+(NSArray*)studiesForUser: (WebPortalUser*) user album:(NSString*)albumName;
+(NSArray*)studiesForUser: (WebPortalUser*) user album:(NSString*)albumName sortBy:(NSString*)sortValue;
+(NSArray*)studiesForUser: (WebPortalUser*) user album:(NSString*)albumName sortBy:(NSString*)sortValue fetchLimit:(int) fetchLimit fetchOffset:(int) fetchOffset numberOfStudies:(int*) numberOfStudies;
@end

@interface WebPortalUser (CoreDataGeneratedAccessors)

- (void)addStudiesObject:(WebPortalStudy*)value;
- (void)removeStudiesObject:(WebPortalStudy*)value;
- (void)addStudies:(NSSet *)value;
- (void)removeStudies:(NSSet *)value;
- (void)addRecentStudies:(NSSet *)value;
- (void)removeRecentStudies:(NSSet *)value;
@end

