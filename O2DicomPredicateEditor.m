//
//  O2DicomPredicateEditor.m
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 06.12.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "O2DicomPredicateEditor.h"
#import "O2DicomPredicateEditorView.h"


@interface O2DicomPredicateEditorRowTemplate : NSPredicateEditorRowTemplate {
    O2DicomPredicateEditorView* _view;
}

@property(retain,nonatomic) O2DicomPredicateEditorView* view;

@end


@interface O2DicomPredicateEditor ()

- (void)initDicomPredicateEditor;

@end


@implementation O2DicomPredicateEditor

@synthesize dbMode = _dbMode;

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
                         [[NSPredicateEditorRowTemplate alloc] initWithCompoundTypes:[NSArray arrayWithObjects: [NSNumber numberWithUnsignedInteger:NSAndPredicateType], [NSNumber numberWithUnsignedInteger:NSOrPredicateType], nil]],
                         [[O2DicomPredicateEditorRowTemplate alloc] init],
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

+ (id)regroupedPredicate:(id)p {
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
                if (pka.count == 1)
                    np = [pka lastObject];
                else np = [NSCompoundPredicate andPredicateWithSubpredicates:pka];
                [a replaceObjectAtIndex:i withObject:np];
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
    value = [[self class] regroupedPredicate:value];

    _setting = YES;
    @try {
        [super setObjectValue:value];
    } @catch (...) {
        @throw;
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
//    NSArray* s = nil;
//    if ([p isKindOfClass:[NSCompoundPredicate class]])
//        s = [p subpredicates];
//    else s = [NSArray arrayWithObject:p];
//    
//    for (NSPredicate* p in s) {
        BOOL ok = NO;
        for (NSPredicateEditorRowTemplate* rt in self.rowTemplates)
            if ([rt matchForPredicate:p]) {
                ok = YES;
                break;
            }
        if (!ok)
            return NO;
//    }
    
    return YES;
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
