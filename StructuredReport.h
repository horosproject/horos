//
//  StructuredReport.h
//  OsiriX
//
//  Created by Lance Pysher on 5/31/06.

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

@interface StructuredReport : NSObject {
	id _study;
	DSRDocument *_doc;
	NSArray *_findings;
	NSArray *_conclusions;
	NSString *_physician;
	NSString *_history;
}

- (id)initWithStudy:(id)study;

- (NSArray *)findings;
- (void)setFindings:(NSArray *)findings;
- (NSArray *)conclusions;
- (void)setConclusions:(NSArray *)conclusions;
- (NSString *)physician;
- (void)setPhysician:(NSString *)physician;
- (NSString *)history;
- (void)setHistory:(NSString *)history;

- (BOOL)fileExists;

- (void)createReport;
- (void)writeHTML;
- (void)writeXML;
- (void)readXML;
- (NSString *)xmlPath;
- (NSString *)htmlPath;
- (NSString *)srPath;
- (void)createReport;

@end
