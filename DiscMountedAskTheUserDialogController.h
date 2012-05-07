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

@interface DiscMountedAskTheUserDialogController : NSWindowController {
    NSString* _mountedPath;
    NSInteger _filesCount;
    NSInteger _choice;
    // Outlets
    NSTextField* _label;
}

@property(assign) IBOutlet NSTextField* label;
@property(readonly) NSInteger choice;

-(id)initWithMountedPath:(NSString*)path dicomFilesCount:(NSInteger)count;

-(IBAction)buttonAction:(NSButton*)sender;

@end
