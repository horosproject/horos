//
//  KeyObjectReport.h
//  OsiriX
//
//  Created by Lance Pysher on 6/13/06.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>


#undef verify
#include "dsrdoc.h"
@interface KeyObjectReport : NSObject {
	id _study;
	DSRDocument *_doc;
	NSArray *_keyImages;
	NSString *_keyDescription;
	int _title;
	NSString *_seriesUID;
}

 - (id) initWithStudy:(id)study  
				title:(int)title   
				description:(NSString *)keyDescription
				seriesUID:(NSString *)seriesUID;
 - (void)createKO;
 - (BOOL)writeFileAtPath:(NSString *)path;
 - (BOOL)writeHTMLAtPath:(NSString *)path;
 - (NSString *)sopInstanceUID;

@end
