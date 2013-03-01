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
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "N2Debug.h"

@implementation SmartWindowController

@synthesize name = _name;
@synthesize predicate = _predicate;
@synthesize database = _database;
@synthesize mode = _mode;
@synthesize nameField = _nameField;
@synthesize editor = _editor;
@synthesize sqlText = _sqlText;

- (id)initWithDatabase:(DicomDatabase*)database {
	if (self = [super initWithWindowNibName:@"SmartAlbum"]) {
        self.database = database;
    }
    
	return self;
}

- (void)awakeFromNib {
    [self.editor setDbMode:YES];
    //[self.editor addObserver:self forKeyPath:@"value" options:0 context:[self class]];
    [self addObserver:self forKeyPath:@"predicate" options:0 context:[self class]]; ///
	[self.nameField.cell setPlaceholderString:NSLocalizedString(@"Smart Album", nil)];
}

- (void)dealloc {
 //   [self.editor removeObserver:self forKeyPath:@"value"];
    [self removeObserver:self forKeyPath:@"predicate"]; ///
    
    self.name = nil;
    self.predicate = nil;
    self.database = nil;
	
    [super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
/*    NSPredicate* p = [self.editor predicate];
    NSPredicate* mp = self.predicate;
    if (![self.predicate isEqual:p])
        self.predicate = p;*/
    
    if ([keyPath isEqual:@"value"])
        NSLog(@"!!!!!!!!! %@ !!! %@ -> %@", object, keyPath, [object valueForKeyPath:@"predicate"]);
    else NSLog(@"!!!!!!!!! %@ !!! %@ -> %@", object, keyPath, [object valueForKeyPath:keyPath]);
}

- (void)windowWillClose:(NSNotification*)notification {
}

+ (NSSet*)keyPathsForValuesAffectingPredicateFormat {
    return [NSSet setWithObject:@"predicate"];
}


- (void)setPredicate:(id)predicate {
    @try {
        if ([predicate isKindOfClass:[NSCompoundPredicate class]] && [predicate compoundPredicateType] == NSAndPredicateType && [[predicate subpredicates] count] > 1) { // somehow, we get AND(TRUEPREDICATE, XXX) instead of XXX
            NSMutableArray* sps = [NSMutableArray array];
            for (id sp in [predicate subpredicates])
                if (![sp isEqual:[NSPredicate predicateWithValue:YES]])
                    [sps addObject:sp];
            if (sps.count == 1)
                predicate = [sps objectAtIndex:0];
        }
        
        if (predicate != _predicate) {
            [_predicate release];
            _predicate = [predicate retain];
        }
    } @catch (...) {
        @throw;
    } @finally {
    }
}

- (NSString*)predicateFormat {
    if (_predicate)
        return [_predicate predicateFormat];
    else return @"TRUEPREDICATE";
}

- (void)setPredicateFormat:(NSString*)predicateFormat {
    NSLog(@"setPredicateFormat: %@", predicateFormat);
    if (!predicateFormat)
        self.predicate = nil;
    else
        @try {
            self.predicate = [NSPredicate predicateWithFormat:predicateFormat];
        } @catch (...) {
//            self.predicate = nil;
        }
}

#pragma mark Actions

- (IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

- (IBAction)okAction:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)helpAction:(NSSegmentedControl*)sender {
    if ([sender selectedSegment] == 0) {
        [NSWorkspace.sharedWorkspace openFile:[[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"] withApplication: nil andDeactivate: YES];
        [NSThread sleepForTimeInterval:1];
    }
    
    if ([sender selectedSegment] == 1)
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
}

- (IBAction)testAction:(id)sender {
    @try {
        BrowserController* bc = [BrowserController currentBrowser];
    
        bc.testPredicate = [bc smartAlbumPredicateString:self.predicateFormat];
        if (!bc.testPredicate)
            [NSException raise:NSGenericException format:NSLocalizedString(@"Invalid NSPredicate SQL syntax", nil)];
            
        NSString* exception = [bc outlineViewRefresh];
        bc.testPredicate = nil;
        
        if (exception)
            @throw exception;
        
        NSRunInformationalAlertPanel( NSLocalizedString(@"It works!",nil), NSLocalizedString(@"This filter works: the result is now displayed in the Database Window.", nil), nil, nil, nil);
    }
    @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
        NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil), [NSString stringWithFormat: NSLocalizedString(@"This filter is NOT working: %@", nil), e], NSLocalizedString(@"OK", nil), nil, nil);
    }
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

+ (NSSet*)keyPathsForValuesAffectingSQLIsValid {
    return [NSSet setWithObject:@"sqlText.value"];
}

- (BOOL)SQLIsValid {
    @try {
        NSString* s = [self.sqlText string];
        NSPredicate* p = [NSPredicate predicateWithFormat:s];

        if ([[self.editor.rowTemplates objectAtIndex:1] matchForPredicate:p])
            return YES;

    } @catch (...) {
    }
    
    return NO;
}

@end
