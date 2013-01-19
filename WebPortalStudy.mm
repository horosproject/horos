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

#import "WebPortalStudy.h"
#import "WebPortalUser.h"
#import "BrowserController.h"
#import "DicomStudy.h"
#import "NSString+N2.h"
#import "WebPortal.h"
#import "DicomDatabase.h"


@implementation WebPortalStudy

@dynamic dateAdded;
@dynamic patientUID;
@dynamic studyInstanceUID;
@dynamic user;


// TODO: we're accessing the defaultWebPortal database, and this is bad
-(DicomStudy*)study
{
    DicomDatabase* ddb = [[[WebPortal defaultWebPortal] dicomDatabase] independentDatabase];
    
	NSArray* studies = [ddb objectsForEntity:ddb.studyEntity predicate:[NSPredicate predicateWithFormat: @"patientUID BEGINSWITH[cd] %@ AND studyInstanceUID == %@", self.patientUID, self.studyInstanceUID]];
	
	if (studies.count != 1)
    {
		NSLog(@"Warning: Study request with \"patientUID == %@ AND studyInstanceUID == %@\" returned %d objects", self.patientUID, self.studyInstanceUID, (int) studies.count);
		return NULL;
	}
	
	return [studies objectAtIndex:0];
}
@end
