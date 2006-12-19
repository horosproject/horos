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


@implementation LayoutWindowController

- (id)init{
	if (self = [super initWithWindowNibName:@"Layout"]) {
		_addLayoutSet = NO;
	}
	return self;
}

- (void)dealloc{
	[_windowControllers release];
	[_hangingProtocol release];
	[_studyDescription release];
	[_modality release];
	[super dealloc];
}

- (void)windowDidLoad{
	
	NSMutableArray *controllers = [NSMutableArray array];
	NSArray *windows = [NSApp windows] ;
	NSEnumerator *enumerator = [windows objectEnumerator];
	id window;
	//get WindowControllers
	while (window = [enumerator nextObject])
	{
		NSWindowController *controller = [window windowController];
		//right now just 2D Viewers will need to deal with other viewer classed evnetually
		//?Arrange controller by screen and origin.  First by screen then by x (lees first) then by y (greater first)
		if([controller isKindOfClass:[ViewerController class]])
			[controllers addObject:controller];
	}
	[self setWindowControllers:controllers];
	if ([_windowControllers count]  > 0) {
		id study = [[_windowControllers objectAtIndex:0] currentStudy];
		
		//Search for current matching hanging protocol
		NSArray *advancedHangingProtocols = [[NSUserDefaults standardUserDefaults] objectForKey: @"ADVANCEDHANGINGPROTOCOLS"];
		NSPredicate *modalityPredicate = [NSPredicate predicateWithFormat:@"modality like[cd] %@", [study valueForKey:@"modality"]];
		[self setModality:[study valueForKey:@"modality"]];
	
		NSPredicate *studyDescriptionPredicate = [NSPredicate predicateWithFormat:@"studyDescription like[cd] %@", [study valueForKey:@"studyName"]];
		[self setStudyDescription: [study valueForKey:@"studyName"]];

		NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:modalityPredicate, studyDescriptionPredicate, nil]];
		NSArray *filteredHangingProtocols = [advancedHangingProtocols filteredArrayUsingPredicate:compoundPredicate];
		if ([filteredHangingProtocols count] > 0) {	
			_hangingProtocol = [[filteredHangingProtocols objectAtIndex:0] mutableCopy] ;
			[self setHasProtocol:YES];
			// Have a sequence of an arrangement of sets. Could loop through using the next and previous series buttons
			//NSArray *arrangedSeries = [hangingProtocol objectForKey:@"seriesSets"];
			//NSArray *firstSet = [arrangedSeries objectAtIndex:0];
		}
		else [self setHasProtocol:NO];
	}
		
	
}

- (IBAction)endSheet:(id)sender{
	if ([sender tag] == 1) {
		//create Layout set
		NSMutableDictionary *hangingProtocol = nil;
		NSLog(@"_hangingProtocol: %@", [_hangingProtocol description]);
		 if (_addLayoutSet)
			hangingProtocol = [_hangingProtocol mutableCopy];
		
		if (!hangingProtocol) {
			NSLog(@"new Hanging Protocol");
			hangingProtocol = [[NSMutableDictionary dictionary] retain];
		}
		
		//Add LayoutSet to SeriesSet
		NSMutableArray *arrangedSeries = [[_hangingProtocol objectForKey:@"seriesSets"] mutableCopy];
		if (!arrangedSeries)
			arrangedSeries = [[NSMutableArray alloc] init];
			
		NSMutableArray *layoutArray = [NSMutableArray array];
		NSEnumerator *enumerator = [_windowControllers objectEnumerator];
		id controller;
		while (controller = [enumerator nextObject]) {
				/*
				 Each Series needs ViewerClass
				 series description (name)
				 ww/wl
				 CLUT
				 Window Frame
				 Screen Number
				 fusion
				 ImageTiles layout
				 rotation
				 zoom	
				*/
			NSMutableDictionary *seriesInfo = [NSMutableDictionary dictionary];
			NSWindow *window = [controller window];
			NSString *frame  = [window stringWithSavedFrame];
			[seriesInfo setObject:frame forKey:@"windowFrame"];
			NSScreen *screen = [window screen];				
			int screenNumber = [[NSScreen screens] indexOfObject:screen];
			[seriesInfo setObject:[NSNumber numberWithInt:screenNumber] forKey:@"screenNumber"];
			id series = [controller currentSeries];
			[seriesInfo setObject:[series valueForKey:@"name"] forKey:@"seriesDescription"];
			[seriesInfo setObject:[series valueForKey:@"id"] forKey:@"seriesNumber"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller curWW]] forKey:@"ww"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller curWL]] forKey:@"wl"];
			[seriesInfo setObject:[controller curWLWWMenu] forKey:@"wwwlMenuItem"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller rotation]] forKey:@"rotation"];
			[seriesInfo setObject:[NSNumber numberWithFloat:[controller scaleValue]] forKey:@"zoom"];
			[seriesInfo setObject:[controller curCLUTMenu] forKey:@"CLUTName"];
			[seriesInfo setObject:NSStringFromClass([controller class]) forKey:@"Viewer Class"];
			// Have blending.  Get Series Description for blending
			if ([controller blendingController]) {
				id blendingSeries = [[controller blendingController] currentSeries];
				[seriesInfo setObject:[blendingSeries valueForKey:@"name"] forKey:@"blendingSeriesDescription"];
				[seriesInfo setObject:[blendingSeries valueForKey:@"id"] forKey:@"blendingSeriesNumber"];	
				[seriesInfo setObject:[NSNumber numberWithInt:[controller blendingType]] forKey:@"blendingType"];					
			}
			[layoutArray addObject:seriesInfo];
	
		}	

		[arrangedSeries addObject:layoutArray];

		[hangingProtocol setObject:arrangedSeries forKey:@"seriesSets"];
		[hangingProtocol setObject:_modality forKey:@"modality"];
		[hangingProtocol setObject:_studyDescription forKey:@"studyDescription"];
		[arrangedSeries release];
		
		
		NSMutableArray *hangingProtocols = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ADVANCEDHANGINGPROTOCOLS"] mutableCopy];
		if (!hangingProtocols)
			hangingProtocols = [[NSMutableArray alloc] init];

		[hangingProtocols removeObject:_hangingProtocol];
		[hangingProtocols addObject:hangingProtocol];
		[hangingProtocol release];

		[[NSUserDefaults standardUserDefaults] setObject: hangingProtocols forKey: @"ADVANCEDHANGINGPROTOCOLS"];
		[hangingProtocols  release];
	}
	[[self window] orderOut:sender];
	[NSApp endSheet: [self window] returnCode:[sender tag]];

}

- (NSString *)studyDescription{
	return _studyDescription;
}
- (void)setStudyDescription:(NSString *)studyDescription{
	[_studyDescription release];
	_studyDescription = [studyDescription retain];
}

- (NSString *)modality{
	return _modality;
}

- (void)setModality:(NSString *)modality{
	[_modality release];
	_modality = [modality retain];
}

- (NSArray *)windowControllers{
	return _windowControllers;
}
- (void)setWindowControllers:(NSArray *)controllers{
	[_windowControllers release];
	_windowControllers = [controllers copy];
}

- (NSDictionary *)hangingProtocol{
	return _hangingProtocol;
}

- (void)setHangingProtocol:(NSMutableDictionary *)hangingProtocol{
	[_hangingProtocol release];
	_hangingProtocol = [hangingProtocol retain];
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
	

@end
