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

#import "SmartWindowController.h"
//#import "SearchSubview.h"
#import "O2DicomPredicateEditor.h"
#import "DicomDatabase.h"

@implementation SmartWindowController

@synthesize name = _name;
@synthesize predicate = _predicate;
@synthesize database = _database;

@synthesize nameField = _nameField;
@synthesize editor = _editor;

- (id)initWithDatabase:(DicomDatabase*)db {
	if (self = [super initWithWindowNibName:@"SmartAlbum"]) {
    }
    
	return self;
}

- (void)dealloc {
    [self.editor removeObserver:self forKeyPath:@"predicate"];
    
    self.name = nil;
    self.predicate = nil;
    self.database = nil;
	
    [super dealloc];
}

- (void)awakeFromNib {
    [self.editor setDbMode:YES];
    [self.editor addObserver:self forKeyPath:@"predicate" options:0 context:[SmartWindowController class]];
	[self.nameField.cell setPlaceholderString:NSLocalizedString(@"Smart Album", nil)];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [SmartWindowController class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    NSPredicate* p = [self.editor predicate];
    if (![self.predicate isEqual:p])
        self.predicate = p;
    
    NSLog(@"SmartWindowController: %@", p.predicateFormat);
}

- (void)windowWillClose:(NSNotification*)notification {
}

#pragma mark Actions

- (IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

- (IBAction)okAction:(id)sender {
    [NSApp endSheet:self.window];
}

#pragma mark -  

+ (NSSet*)keyPathsForValuesAffectingPredicateIsValid {
    return [NSSet setWithObject:@"predicate"];
}

- (BOOL)predicateIsValid {
//    NSLog(@"is valid? %@ --- %d", self.predicate, [self.predicate isEqual:[NSPredicate predicateWithValue:YES]]);
    return self.predicate && ![self.predicate isEqual:[NSPredicate predicateWithValue:YES]];
}

+ (NSSet*)keyPathsForValuesAffectingNameIsValid {
    return [NSSet setWithObject:@"name"];
}

- (BOOL)nameIsValid {
    return self.name.length && ![[[self.database objectsForEntity:self.database.albumEntity] valueForKey:@"name"] containsObject:self.name];
}

@end
