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




#import <AppKit/AppKit.h>


@interface AnonymizerWindowController : NSWindowController {

IBOutlet NSMatrix		*tagMatrixfirstColumn, *tagMatrixsecondColumn;
IBOutlet NSMatrix		*firstColumnValues;
IBOutlet NSMatrix		*secondColumnValues;
IBOutlet NSView			*accessoryView;

NSArray *filesToAnonymize, *dcmObjects;
NSString *folderPath;
NSMutableArray *tags;

}

- (IBAction)anonymize:(id)sender;
- (IBAction)matrixAction:(id)sender;
- (void)setFilesToAnonymize:(NSArray *)files :(NSArray*) dcm;
-(NSArray *)tags;

@end
