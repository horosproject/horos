/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "SmartWindowController.h"
//#import "SearchSubview.h"
#import "O2DicomPredicateEditor.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "N2Debug.h"

@implementation SmartWindowController

@synthesize name = _name;
@synthesize predicateFormat = _predicateFormat;
@synthesize database = _database;
@synthesize album = _album;
@synthesize mode = _mode;
@synthesize nameField = _nameField;
@synthesize editor = _editor;

- (id)initWithDatabase:(DicomDatabase*)database {
	if (self = [super initWithWindowNibName:@"SmartAlbum"]) {
        self.database = database;
    }
    
	return self;
}

- (void)awakeFromNib {
    [self.editor setDbMode:YES];
	[self.nameField.cell setPlaceholderString:NSLocalizedString(@"Smart Album", nil)];
    
//    [self addObserver:self forKeyPath:@"predicate" options:NSKeyValueObservingOptionInitial context:[self class]];
    
    if (self.predicate && ![self.editor reallyMatchForPredicate:self.predicate])
        self.mode = 1;
}

- (void)dealloc {
//    [self removeObserver:self forKeyPath:@"predicate"];
    self.name = nil;
    self.predicate = nil;
    self.album = nil;
    self.database = nil;
	
    [super dealloc];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if (context != [self class])
//        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    
//    // useless ?
//}

+ (NSSet*)keyPathsForValuesAffectingPredicate {
    return [NSSet setWithObject:@"predicateFormat"];
}

- (NSPredicate*)predicate {
    @try {
        if (self.predicateFormat.length)
            return [NSPredicate predicateWithFormat:self.predicateFormat];
    } @catch (...) {
    }
    
    return nil;
}

- (void)setPredicate:(id)predicate {
    self.predicateFormat = [predicate predicateFormat];
}

- (NSString*)predicateFormat {
    if (_predicateFormat.length)
        return _predicateFormat;
    else return nil;
}

- (void)setPredicateFormat:(NSString *)predicateFormat {
    if (predicateFormat != _predicateFormat) {
        [_predicateFormat release];
        _predicateFormat = [predicateFormat retain];
    }
}


#pragma mark Actions

- (IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
    
    [BrowserController currentBrowser].testPredicate = nil;
    [[BrowserController currentBrowser] outlineViewRefresh];;
}

- (IBAction)okAction:(id)sender {
    [NSApp endSheet:self.window];
    
    [BrowserController currentBrowser].testPredicate = nil;
    [[BrowserController currentBrowser] outlineViewRefresh];;
}

- (IBAction)helpAction:(NSSegmentedControl*)sender {
    if ([sender selectedSegment] == 0)
    {
        [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/OsiriXTables.pdf" error:nil];
        [[NSFileManager defaultManager] copyItemAtPath: [[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"] toPath: @"/tmp/OsiriXTables.pdf" error: nil];
		[[NSWorkspace sharedWorkspace] openFile: @"/tmp/OsiriXTables.pdf" withApplication: nil andDeactivate: YES];
        
        [NSThread sleepForTimeInterval:1];
    }
    
    if ([sender selectedSegment] == 1)
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
}

- (IBAction)testAction:(id)sender {
    @try {
        NSPredicate* p = [NSPredicate predicateWithFormat:self.predicateFormat];
        
        BrowserController* bc = [BrowserController currentBrowser];
        p = [bc smartAlbumPredicateString:self.predicateFormat];
        if (!p)
            [NSException raise:NSGenericException format:NSLocalizedString(@"Invalid NSPredicate SQL syntax", nil)];
        
        NSError* error = nil;
        [self.database objectsForEntity:self.database.studyEntity predicate:p error:&error];
        if (error)
            [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
        
        bc.testPredicate = p;
        [bc outlineViewRefresh];
        
        NSString* message = NSLocalizedString(@"This filter works: the result is now displayed in the Database Window.", nil);
        
        NSRunInformationalAlertPanel( NSLocalizedString(@"It works!",nil), @"%@", nil, nil, nil, message);
    }
    @catch (NSException* e) {
//        N2LogExceptionWithStackTrace(e);
        NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil), @"%@", nil, nil, nil, [NSString stringWithFormat: NSLocalizedString(@"This filter is NOT working: %@", nil), e]);
    }
}

#pragma mark -  

+ (NSSet*)keyPathsForValuesAffectingPredicateFormatIsValid {
    return [NSSet setWithObject:@"predicateFormat"];
}

- (BOOL)predicateFormatIsValid {
    @try {
        NSPredicate* p = [NSPredicate predicateWithFormat:self.predicateFormat];
        if (p)
            return YES;
    } @catch (...) {
    }
    
    return NO;
}

+ (NSSet*)keyPathsForValuesAffectingNameIsValid {
    return [NSSet setWithObject:@"name"];
}

- (BOOL)nameIsValid {
    NSMutableArray* albums = [[[self.database objectsForEntity:self.database.albumEntity] mutableCopy] autorelease];
    if (self.album) [albums removeObject:self.album];
    return self.name.length && ![[albums valueForKey:@"name"] containsObject:self.name];
}

+ (NSSet*)keyPathsForValuesAffectingModeIsPredicate {
    return [NSSet setWithObject:@"mode"];
}

- (BOOL)modeIsPredicate {
    return self.mode == 0;
}

+ (NSSet*)keyPathsForValuesAffectingModeIsSQL {
    return [NSSet setWithObject:@"mode"];
}

- (BOOL)modeIsSQL {
    return self.mode == 1;
}

+ (NSSet*)keyPathsForValuesAffectingOkButtonTitle {
    return [NSSet setWithObject:@"album"];
}

- (NSString*)okButtonTitle {
    if (self.album)
        return NSLocalizedString(@"Save", nil);
    return NSLocalizedString(@"Create", nil);
}

@end
