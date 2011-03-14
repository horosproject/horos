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
@property (nonatomic, retain) NSDate * passwordCreationDate;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * sendDICOMtoAnyNodes;
@property (nonatomic, retain) NSNumber * sendDICOMtoSelfIP;
@property (nonatomic, retain) NSNumber * shareStudyWithUser;
@property (nonatomic, retain) NSString * studyPredicate;
@property (nonatomic, retain) NSNumber * uploadDICOM;
@property (nonatomic, retain) NSNumber * uploadDICOMAddToSpecificStudies;
@property (nonatomic, retain) NSSet* studies;

-(void)generatePassword;

-(BOOL)validatePassword:(NSString**)value error:(NSError**)error;
-(BOOL)validateDownloadZIP:(NSNumber**)value error:(NSError**)error;
-(BOOL)validateName:(NSString**)value error:(NSError**)error;
-(BOOL)validateStudyPredicate:(NSString**)value error:(NSError**)error;

@end

@interface WebPortalUser (CoreDataGeneratedAccessors)

- (void)addStudiesObject:(WebPortalStudy*)value;
- (void)removeStudiesObject:(WebPortalStudy*)value;
- (void)addStudies:(NSSet *)value;
- (void)removeStudies:(NSSet *)value;

@end
