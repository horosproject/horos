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
    
    self.nestingMode = NSRuleEditorNestingModeList;
    
    self.rowTemplates = [NSArray arrayWithObjects:
                         [[NSPredicateEditorRowTemplate alloc] initWithCompoundTypes:[NSArray arrayWithObjects: [NSNumber numberWithUnsignedInteger:NSAndPredicateType], [NSNumber numberWithUnsignedInteger:NSOrPredicateType], nil]],
                         [[O2DicomPredicateEditorRowTemplate alloc] init],
                         nil];
    
    //   NSPredicateEditorRowTemplate* rt = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:@"" rightExpressionAttributeType:<#(NSAttributeType)#> modifier:<#(NSComparisonPredicateModifier)#> operators:<#(NSArray *)#> options:<#(NSUInteger)#>];
    
    //    self.rowTemplates = [NSArray arrayWithObjects:
    //                         t1,
    //                         nil];
    
    NSDictionary* binding = [[[self infoForBinding:@"value"] retain] autorelease];
    if (binding) {
        NSMutableDictionary* options = [[[binding objectForKey:NSOptionsKey] mutableCopy] autorelease];
        
        [options setObject:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:[NSPredicate predicateWithValue:YES]]] forKey:NSNullPlaceholderBindingOption];
        
        [self unbind:@"value"];
        [self bind:@"value" toObject:[binding objectForKey:NSObservedObjectKey] withKeyPath:[binding objectForKey:NSObservedKeyPathKey] options:options];
    }
    
    _inited = YES;
}

- (void)setDbMode:(BOOL)dbMode {
    if (dbMode)
        self.nestingMode = NSRuleEditorNestingModeCompound;
    else self.nestingMode = NSRuleEditorNestingModeList;

}

/*- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
 [super resizeSubviewsWithOldSize:oldSize];
 }*/

+ (NSSet*)keyPathsForValuesAffectingValue {
    return [NSSet setWithObject:@"predicate"];
}

- (void)validateEditing {
    if (!_inValidateEditing) { // to avoid an infinite recurse loop
        _inValidateEditing = YES;
        [super validateEditing];
        _inValidateEditing = NO;
    }
}




/*- (DcmDataset*)dictionary {
    
}*/



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

//- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
//    if (context != [O2DicomPredicateEditorRowTemplate class])
//        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    
//    NSLog(@"hey hooo i know preee ===[ %@ ]=== ===[ %@ ]=== ===[ %@ ]=== ", [object predicate], [[object editor] predicate], [[NSApp delegate] predicate]);
//}

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
