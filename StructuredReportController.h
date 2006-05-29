//
//  StructuredReportController.h
//  OsiriX
//
//  Created by Lance Pysher on 5/29/06.
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


@interface StructuredReportController : NSWindowController {

	NSArray *_findings;
	NSArray *_conclusions;
	NSString *_physician;
	NSString *_history;
	id _study;
	
	
}

- (id)initWithStudy:(id)study;
- (BOOL)createReportForStudy:(id)study;
-(IBAction)endSheet:(id)sender;
- (void)createReportExportHTML:(BOOL)html;

- (NSArray *)findings;
- (void)setFindings:(NSArray *)findings;
- (NSArray *)conclusions;
- (void)setConclusions:(NSArray *)conclusions;
- (NSString *)physician;
- (void)setPhysician:(NSString *)physician;
- (NSString *)history;
- (void)setHistory:(NSString *)history;
@end
