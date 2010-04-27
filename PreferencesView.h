//
//  PreferencesView.h
//  OsiriX
//
//  Created by Alessandro Volz on 4/21/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface PreferencesView : NSControl {
	NSMutableArray* groups;
	id buttonActionTarget;
	SEL buttonActionSelector;
}

@property(assign) id buttonActionTarget;
@property(assign) SEL buttonActionSelector;

-(void)addItemWithTitle:(NSString*)title image:(NSImage*)image toGroupWithName:(NSString*)groupName context:(id)context;
-(NSUInteger)itemsCount;
-(id)contextForItemAtIndex:(NSUInteger)index;
-(NSInteger)indexOfItemWithContext:(id)context;

@end
