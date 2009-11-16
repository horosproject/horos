/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>


/** \brief Controller for performing query */
@interface QueryArrayController : NSObject
{
	id rootNode;
	NSMutableDictionary *filters;
	NSString *callingAET;
	NSString *calledAET;
	NSString *hostname;
	NSString *port;
	NSArray *queries;
	NSDictionary *distantServer;
	NSLock *queryLock;
	int retrieveMode;
}

- (id)initWithCallingAET:(NSString *) myAET distantServer: (NSDictionary*) ds;

- (id)rootNode;
- (NSArray *)queries;

- (void)addFilter:(id)filter forDescription:(NSString *)description;
- (void)sortArray:(NSArray *)sortDesc;
- (void)performQuery;
- (NSDictionary *)parameters;
- (void)performQuery: (BOOL) showError;

@end
