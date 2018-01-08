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


#import "O2DicomPredicateEditor.h"
#import "O2DicomPredicateEditorView.h"
#import "N2Debug.h"

@interface O2DicomPredicateEditorRowTemplate : NSPredicateEditorRowTemplate {
    O2DicomPredicateEditorView* _view;
}

@property(retain,nonatomic) O2DicomPredicateEditorView* view;

@end

@interface O2DicomPredicateEditorCompoundRowTemplate : NSPredicateEditorRowTemplate {
    NSArray* _subtemplates;
}

- (id)initWithSubtemplates:(NSArray*)subtemplates;
- (double)reallyMatchForPredicate:(id)predicate;

@end


@interface O2DicomPredicateEditor ()

- (void)initDicomPredicateEditor;

@end


@implementation O2DicomPredicateEditor

@synthesize dbMode = _dbMode, inited = _inited;

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self initDicomPredicateEditor];
    }
    
    return self;
}

- (void)awakeFromNib {
    [self initDicomPredicateEditor];
    
    NSDictionary* binding = [[[self infoForBinding:@"value"] retain] autorelease];
    if (binding) {
        NSMutableDictionary* options = [[[binding objectForKey:NSOptionsKey] mutableCopy] autorelease];
        
        [options setObject:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:[NSPredicate predicateWithValue:YES]]] forKey:NSNullPlaceholderBindingOption];
        
        [self unbind:@"value"];
        [self bind:@"value" toObject:[binding objectForKey:NSObservedObjectKey] withKeyPath:[binding objectForKey:NSObservedKeyPathKey] options:options];
    }
    
    [self addObserver:self forKeyPath:@"value" options:0 context:[self class]];
}

- (void)initDicomPredicateEditor {
    if (_inited)
        return;
    
    self.rowTemplates = [NSArray arrayWithObjects:
                         _dpert = [[[O2DicomPredicateEditorRowTemplate alloc] init] autorelease],
                         [[[O2DicomPredicateEditorCompoundRowTemplate alloc] initWithSubtemplates:[NSArray arrayWithObject:_dpert]] autorelease],
                         nil];
    
    _inited = YES;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"value"];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if (_setting)
        return;
    
    _backbinding = YES;
    @try {
        NSDictionary* binding = [[[self infoForBinding:@"value"] retain] autorelease];
        if (binding)
            [[binding objectForKey:NSObservedObjectKey] setValue:self.predicate forKeyPath:[binding objectForKey:NSObservedKeyPathKey]];
    } @catch (...) {
        @throw;
    } @finally {
        _backbinding = NO;
    }
}

- (id)regroupedPredicate:(id)p {
    if ([[p predicateFormat] isEqualToString:@"TRUEPREDICATE"])
        return p;
    
    if ([_dpert matchForPredicate:p])
        p = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:p]];

    if ([p isKindOfClass:[NSCompoundPredicate class]]) {
        NSMutableDictionary* d = [NSMutableDictionary dictionary];
        NSMutableArray* a = [NSMutableArray array];
        
        for (id sp in [p subpredicates])
            if ([sp isKindOfClass:[NSComparisonPredicate class]]) {
                NSMutableArray* pka = [d objectForKey:[sp keyPath]];
                if (!pka) {
                    [d setObject:(pka = [NSMutableArray array]) forKey:[sp keyPath]];
                    [a addObject:[sp keyPath]];
                }
                [pka addObject:sp];
            } else
                [a addObject:sp];

        for (size_t i = 0; i < a.count; ++i)
            if (![[a objectAtIndex:i] isKindOfClass:[NSPredicate class]]) {
                NSArray* pka = [d objectForKey:[a objectAtIndex:i]];
                id np;
                if (pka.count == 1) {
                    np = [pka lastObject];
                    [a replaceObjectAtIndex:i withObject:np];
                } else {
                    np = [NSCompoundPredicate andPredicateWithSubpredicates:pka];
                    if ([_dpert matchForPredicate:np])
                        [a replaceObjectAtIndex:i withObject:np];
                    else [a replaceObjectsInRange:NSMakeRange(i,1) withObjectsFromArray:pka];
                }
            }
        
        p = [[[NSCompoundPredicate alloc] initWithType:[p compoundPredicateType] subpredicates:a] autorelease];
    }
    
    return p;
}

- (void)setObjectValue:(id)value {
    if (_backbinding)
        return;
    
    [self initDicomPredicateEditor]; // weird, this is needed: bindings are assigned before initWithFrame: or awakeFromNib...
    
    // try grouping conditions on the same keys in separate compounds
    value = [self regroupedPredicate:value];

    _setting = YES;
    @try {
        [super setObjectValue:value];
    } @catch ( NSException *e) {
        N2LogException( e);
    } @finally {
        _setting = NO;
    }
}

- (void)setDbMode:(BOOL)dbMode {
    _dbMode = dbMode;
    if (dbMode)
        self.nestingMode = NSRuleEditorNestingModeCompound;
    else self.nestingMode = NSRuleEditorNestingModeList;
}

+ (NSSet*)keyPathsForValuesAffectingValue {
    return [NSSet setWithObject:@"predicate"];
}

- (void)validateEditing { // to avoid an infinite recurse loop
    if (!_inValidateEditing) {
        _inValidateEditing = YES;
        [super validateEditing];
        _inValidateEditing = NO;
    }
}

- (BOOL)matchForPredicate:(id)p {
    p = [self regroupedPredicate:p];
    
    BOOL ok = NO;
    for (NSPredicateEditorRowTemplate* rt in self.rowTemplates)
        if ([rt matchForPredicate:p]) {
            ok = YES;
            break;
        }
    
    return ok;
}

- (BOOL)reallyMatchForPredicate:(NSPredicate*)p {
    p = [self regroupedPredicate:p];
    
    for (id rt in self.rowTemplates) {
        double rtok = 0;
        if ([rt respondsToSelector:@selector(reallyMatchForPredicate:)])
            rtok = [(O2DicomPredicateEditorCompoundRowTemplate*)rt reallyMatchForPredicate:p];
        else rtok = [(NSPredicateEditorRowTemplate*)rt matchForPredicate:p];
        if (rtok > 0)
            return YES;
    }
    
    return NO;
}

@end



@implementation O2DicomPredicateEditorRowTemplate

@synthesize view = _view;

- (void)dealloc {
//    [_view removeObserver:self forKeyPath:@"predicate"];
    self.view = nil;
    [super dealloc];
}

- (O2DicomPredicateEditorView*)view {
    if (!_view) {
        _view = [[O2DicomPredicateEditorView alloc] initWithFrame:NSZeroRect];
        [_view setFrameSize:NSMakeSize(4000, 20)];
//        [_view addObserver:self forKeyPath:@"predicate" options:0 context:[O2DicomPredicateEditorRowTemplate class]];
    }
    
    return _view;
}

- (double)matchForPredicate:(id)predicate {
    return [self.view matchForPredicate:predicate];
}

- (NSArray*)templateViews {
    return [NSArray arrayWithObject:self.view];
}

- (void)setPredicate:(id)predicate {
    [self.view setPredicate:predicate];
}

- (NSPredicate*)predicateWithSubpredicates:(NSArray*)subpredicates {
    return [self.view predicate];
}

@end




@implementation O2DicomPredicateEditorCompoundRowTemplate

- (id)initWithSubtemplates:(NSArray*)subtemplates {
    if ((self = [super initWithCompoundTypes:[NSArray arrayWithObjects: [NSNumber numberWithUnsignedInteger:NSAndPredicateType], [NSNumber numberWithUnsignedInteger:NSOrPredicateType], nil]])) {
        _subtemplates = [subtemplates retain];
    }
    
    return self;
}

- (void)dealloc {
    [_subtemplates release];
    [super dealloc];
}

- (double)reallyMatchForPredicate:(id)predicate {
    double r = [super matchForPredicate:predicate];
    
    if (r) { // super says we can show this, but can we ?
        for (id subpredicate in [predicate subpredicates]) {
            BOOL ok = NO;
            for (NSPredicateEditorRowTemplate* rt in _subtemplates)
                if ([rt matchForPredicate:subpredicate]) {
                    ok = YES;
                    break;
                }
            if (!ok)
                return 0;
        }
    }
    
    return r;
}


@end


