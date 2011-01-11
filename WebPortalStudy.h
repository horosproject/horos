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

@class DicomStudy, WebPortalUser;

@interface WebPortalStudy : NSManagedObject

@property (nonatomic, retain) NSDate * dateAdded;
@property (nonatomic, retain) NSString * patientUID;
@property (nonatomic, retain) NSString * studyInstanceUID;
@property (nonatomic, retain) WebPortalUser * user;

@property (readonly) DicomStudy* study;

@end
