//
//  LayoutWindowController.m
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


#import "LayoutWindowController.h"
#import "browserController.h"
#import "ViewerController.h"
#import "VRController.h"
#import "WindowLayoutManager.h"
#import "VRControllerVPRO.h"
#import "SRController.h"
#import "EndoscopyViewer.h"
#import "SeriesView.h"

#import "LayoutArrayController.h"
#import "HangingProtocolController.h"
#import "PlaceholderWindowController.h"


@implementation LayoutWindowController

+ (void)initialize{
	[LayoutWindowController exposeBinding:@"hangingProtocol"];
}

- (id)init{
	if (self = [super initWithWindowNibName:@"Layout"]) {
		_addLayoutSet = NO;
		_newButtonIsHidden = [[WindowLayoutManager sharedWindowLayoutManager] hangingProtocol] ? YES : NO;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
		//[[WindowLayoutManager sharedWindowLayoutManager] bind:@"hangingProtocol" toObject:self withKeyPath:@"hangingProtocol" options:nil];
	}
	return self;
}

- (void)dealloc{
	[_hangingProtocol release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[self window]];
	[super dealloc];
}

- (void)showWindow:(id)sender{
	[super showWindow:sender];
	if (![self hangingProtocol]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"No hanging protocol has been created for this study.", nil)];
		[alert setInformativeText:NSLocalizedString(@"Create hanging protocol with current window layout?", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self  didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}
	
	

- (void)windowDidLoad{
	if ([[self windowControllers] count]  > 0) {
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object:[self window]];		
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	if (returnCode == NSAlertFirstButtonReturn){
		[_hangingProtocolController add:self];
	}
	[[alert window] orderOut:nil];
	[alert release];
}

- (void)windowWillClose:(NSNotification *)note{
	//NSLog(@"Advanced Window Closing");
	[self save];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
	//NSLog(@"App Will Terminate");
	//[self save];
}

- (void)save{
	NSLog(@"Save Hanging Protocols");
	id study = [[WindowLayoutManager sharedWindowLayoutManager] currentStudy];
	NSMutableArray *advancedHangingProtocols = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey: @"ADVANCEDHANGINGPROTOCOLS2"]];
	//NSLog(@"****** HangingProtocols *************\n%@", _hangingProtocol);
	if (!advancedHangingProtocols)
		advancedHangingProtocols = [NSMutableArray array];
	NSPredicate *modalityPredicate = [NSPredicate predicateWithFormat:@"modality like[cd] %@", [study valueForKey:@"modality"]];
	NSPredicate *studyDescriptionPredicate = [NSPredicate predicateWithFormat:@"studyDescription like[cd] %@", [study valueForKey:@"studyName"]];
	NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:modalityPredicate, studyDescriptionPredicate, nil]];
	NSArray *filteredHangingProtocols = [advancedHangingProtocols filteredArrayUsingPredicate:compoundPredicate];
	[advancedHangingProtocols removeObjectsInArray:filteredHangingProtocols];
	if (_hangingProtocol)
		[advancedHangingProtocols addObject:_hangingProtocol];
	[[NSUserDefaults standardUserDefaults] setObject: advancedHangingProtocols forKey: @"ADVANCEDHANGINGPROTOCOLS2"];
}



- (NSString *)studyDescription{
	return [[[WindowLayoutManager sharedWindowLayoutManager] currentStudy] valueForKey:@"studyName"];
}


- (NSString *)modality{
	return [[[WindowLayoutManager sharedWindowLayoutManager] currentStudy] valueForKey:@"modality"];
}

- (NSString *)institution{
	return [[[WindowLayoutManager sharedWindowLayoutManager] currentStudy] valueForKey:@"institutionName"];
}


- (NSArray *)windowControllers{
	return [[WindowLayoutManager sharedWindowLayoutManager] viewers];
}

- (NSDictionary *)hangingProtocol{
	return _hangingProtocol;
}

- (void)setHangingProtocol:(NSMutableDictionary *)hangingProtocol{
	//NSLog(@"Layout set Hanging Protocol: %@", hangingProtocol);
	[_hangingProtocol release];
	_hangingProtocol = [hangingProtocol retain];
	BOOL isHidden = _hangingProtocol ? YES: NO;
	[self setNewButtonIsHidden:isHidden];
	[[WindowLayoutManager sharedWindowLayoutManager] setHangingProtocol:(NSMutableDictionary *)hangingProtocol];
}



- (BOOL) hasProtocol{
	return _hasProtocol;
}
- (void)setHasProtocol:(BOOL)hasProtocol{
	_hasProtocol = hasProtocol;
}

- (BOOL)addLayoutSet{
	return _addLayoutSet;
}
- (void)setAddLayoutSet:(BOOL)addSet{
	_addLayoutSet = addSet;
}

- (NSArray *)layouts{
	return [_hangingProtocol objectForKey:@"seriesSets"];
}


- (void)setLayouts:(NSArray *)layouts{
	[_hangingProtocol setObject: layouts forKey:@"seriesSets"];
}

- (BOOL)newButtonIsHidden{
	return _newButtonIsHidden;
}

- (void)setNewButtonIsHidden:(BOOL)isHidden{
	_newButtonIsHidden = isHidden;
}

- (id)windowLayoutManager{
	return [WindowLayoutManager sharedWindowLayoutManager] ;
}

- (IBAction)placeholder:(id)sender{
	PlaceholderWindowController *placeholder = [[PlaceholderWindowController alloc] init];
	[placeholder showWindow:self];
}



	

@end
