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


#undef verify
#include "dsrdoc.h"

/** \brief  DICOM Structured Report */

@interface StructuredReport : NSObject {
	id _study;
	DSRDocument *_doc;
	NSMutableArray *_findings;
	NSMutableArray *_conclusions;
	NSArray *_keyImages;
	NSString *_physician;
	NSString *_history;
	NSString *_sopInstanceUID;
	NSString *_request;
	NSString *_procedureDescription;
	NSString *_institution;
	NSString *_verifyOberverName;
	NSString *_verifyOberverOrganization;
	NSString *_path;
	NSXMLDocument *_xmlDoc;
	BOOL _reportHasChanged;
	BOOL _isEditable;
	BOOL _complete;
	BOOL _verified;
}

- (id)initWithStudy:(id)study;
- (id)initWithStudy:(id)study contentsOfFile:(NSString *)file;

- (NSArray *)findings;
- (void)setFindings:(NSMutableArray *)findings;
- (NSArray *)conclusions;
- (void)setConclusions:(NSMutableArray *)conclusions;
- (NSString *)physician;
- (void)setPhysician:(NSString *)physician;
- (NSString *)history;
- (void)setHistory:(NSString *)history;
- (NSString *)request;
- (void)setRequest:(NSString *)request;
- (NSString *)procedureDescription;
- (void)setProcedureDescription:(NSString *)procedureDescription;
- (NSString *)institution;
- (void)setInstitution:(NSString *)institution;
- (NSString *)verifyOberverName;
- (void)setVerifyOberverName:(NSString *)verifyOberverName;
- (NSString *)verifyOberverOrganization;
- (void)setVerifyOberverOrganization:(NSString *)verifyOberverOrganization;
- (BOOL)complete;
- (void)setComplete:(BOOL)complete;
- (BOOL)verified;
- (void)setVerified:(BOOL)verified;
- (NSArray *)keyImages;
- (void)setKeyImages:(NSArray *)keyImages;
- (BOOL)isEditable;
- (NSDate *)contentDate;
- (void)setContentDate:(NSDate *)date;
- (NSString *)title;
- (void)setTitle:(NSString *)title;


- (void)save;
- (void)export:(NSString *)path;

- (BOOL)fileExists;
- (void)checkCharacterSet;

- (void)createReport;
- (void)writeHTML;
- (void)writeXML;
- (void)readXML;
- (NSString *)xmlPath;
- (NSString *)htmlPath;
- (NSString *)srPath;

- (void)convertXMLToSR;
//- (NSMXLDocument *)xmlDoc;
- (NSArray *)referencedObjects;
- (NSArray *)keyImages;


@end
