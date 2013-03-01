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
}

- (void)initDicomPredicateEditor {
    if (_inited)
        return;
    
    self.rowTemplates = [NSArray arrayWithObjects:
                         [[NSPredicateEditorRowTemplate alloc] initWithCompoundTypes:[NSArray arrayWithObjects: [NSNumber numberWithUnsignedInteger:NSAndPredicateType], [NSNumber numberWithUnsignedInteger:NSOrPredicateType], nil]],
                         [[O2DicomPredicateEditorRowTemplate alloc] init],
                         nil];
    
    NSDictionary* binding = [[[self infoForBinding:@"value"] retain] autorelease];
    if (binding) {
        NSMutableDictionary* options = [[[binding objectForKey:NSOptionsKey] mutableCopy] autorelease];
        
        [options setObject:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:[NSPredicate predicateWithValue:YES]]] forKey:NSNullPlaceholderBindingOption];
        
        [self unbind:@"value"];
        [self bind:@"value" toObject:[binding objectForKey:NSObservedObjectKey] withKeyPath:[binding objectForKey:NSObservedKeyPathKey] options:options];
    }
    
    [self addObserver:self forKeyPath:@"value" options:0 context:[self class]];
    
    _inited = YES;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"value"];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
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

- (void)setObjectValue:(id)value {
    if (_backbinding)
        return;
    
//    if (!value)
//        value = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:[NSPredicate predicateWithValue:YES]]];
    
    [super setObjectValue:value];
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
