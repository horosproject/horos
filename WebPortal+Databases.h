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

#import "WebPortal.h"


@class WebPortalUser;


@interface WebPortal (Databases)

-(NSArray*)arrayByAddingSpecificStudiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate toArray:(NSArray*)array;

-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate;
-(NSArray*)studiesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate sortBy:(NSString*)sortValue;

-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName;
-(NSArray*)studiesForUser:(WebPortalUser*)user album:(NSString*)albumName sortBy:(NSString*)sortValue;

-(NSArray*)seriesForUser:(WebPortalUser*)user predicate:(NSPredicate*)predicate;

@end
