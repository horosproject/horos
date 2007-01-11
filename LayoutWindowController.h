//
//  LayoutWindowController.h
//  OsiriX
//
//  Created by Lance Pysher on 12/5/06.
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

/*
Saves and Creates Advanced Hanging Protocols
*/

#import <Cocoa/Cocoa.h>

@class LayoutArrayController;
@class HangingProtocolController;
@interface LayoutWindowController : NSWindowController {
	NSArray *_windowControllers;
	NSMutableDictionary *_hangingProtocol;
	NSString *_studyDescription;
	NSString *_modality;
	NSString *_institution;
	BOOL _hasProtocol;
	BOOL _addLayoutSet;
	IBOutlet LayoutArrayController *_layoutArrayController;
	IBOutlet HangingProtocolController	*_hangingProtocolController;
}

- (IBAction)endSheet:(id)sender;
- (NSString *)studyDescription;
- (void)setStudyDescription:(NSString *)studyDescription;
- (NSString *)modality;
- (void)setModality:(NSString *)modality;
- (NSArray *)windowControllers;
- (void)setWindowControllers:(NSArray *)controllers;
- (NSDictionary *)hangingProtocol;
- (void)setHangingProtocol:(NSMutableDictionary *)hangingProtocol;
- (BOOL) hasProtocol;
- (void)setHasProtocol:(BOOL)hasProtocol;
- (BOOL)addLayoutSet;
- (void)setAddLayoutSet:(BOOL)addSet;
- (NSString *)institution;
- (void)setInstitution:(NSString *)institution;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
