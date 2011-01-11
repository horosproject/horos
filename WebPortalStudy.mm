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
#import "BrowserController.h"
#import "DicomStudy.h"
#import "NSString+N2.h"


@implementation WebPortalStudy

@dynamic dateAdded;
@dynamic patientUID;
@dynamic studyInstanceUID;
@dynamic user;


// TODO: we're accessing the browser database, and this is bad
-(DicomStudy*)study {
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [NSEntityDescription entityForName:@"Study" inManagedObjectContext:BrowserController.currentBrowser.managedObjectContext];
	req.predicate = [NSPredicate predicateWithFormat: @"patientUID == %@ AND studyInstanceUID == %@", self.patientUID, self.studyInstanceUID];
	NSArray* studies = [BrowserController.currentBrowser.managedObjectContext executeFetchRequest:req error:NULL];
	
	if (studies.count != 1) {
		NSLog(@"Warning: Study request with \"patientUID == %@ AND studyInstanceUID == %@\" returned %d objects", self.patientUID, self.studyInstanceUID, studies.count);
		return NULL;
	}
	
	return [studies objectAtIndex:0];
}

@end
