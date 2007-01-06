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
	

	[self setWindowControllers:[[WindowLayoutManager sharedWindowLayoutManager] viewers]];
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

		}
		else [self setHasProtocol:NO];
	}
		
	
}

- (IBAction)endSheet:(id)sender{
	if ([sender tag] == 1) {
		//create Layout set
		NSMutableDictionary *hangingProtocol = nil;

		 if (_addLayoutSet)
			hangingProtocol = [_hangingProtocol mutableCopy];
		
		if (!hangingProtocol) {

			hangingProtocol = [[NSMutableDictionary dictionary] retain];
		}
		
		//Add LayoutSet to SeriesSet
		NSMutableArray *arrangedSeries = [[hangingProtocol objectForKey:@"seriesSets"] mutableCopy];
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
			[seriesInfo setObject:[series valueForKey:@"seriesDescription"] forKey:@"protocolName"];
			
			// Not supported by OrthogonalMPRPETCTViewer
			if (!([controller isKindOfClass:[OrthogonalMPRPETCTViewer class]]  || [controller isKindOfClass:[SRController class]])) {
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller curWW]] forKey:@"ww"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller curWL]] forKey:@"wl"];
				[seriesInfo setObject:[controller curCLUTMenu] forKey:@"CLUTName"];
			}
			
			if ([controller isKindOfClass:[SRController class]]) {
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller firstSurface]] forKey:@"firstSurface"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller secondSurface]] forKey:@"secondSurface"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller resolution]] forKey:@"resolution"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller firstTransparency]] forKey:@"firstTransparency"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller secondTransparency]] forKey:@"secondTransparency"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller decimate]] forKey:@"decimate"];
				[seriesInfo setObject:[NSNumber numberWithInt:[controller smooth]] forKey:@"smooth"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller shouldDecimate]] forKey:@"shouldDecimate"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller shouldSmooth]] forKey:@"shouldSmooth"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller useFirstSurface]] forKey:@"useFirstSurface"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller useSecondSurface]] forKey:@"useSecondSurface"];
				[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller firstColor]] forKey:@"firstColor"];
				[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller secondColor]] forKey:@"secondColor"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller shouldRenderFusion]] forKey:@"shouldRenderFusion"];
				
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionFirstSurface]] forKey:@"fusionFirstSurface"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionSecondSurface]] forKey:@"fusionSecondSurface"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionResolution]] forKey:@"fusionResolution"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionFirstTransparency]] forKey:@"fusionFirstTransparency"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionSecondTransparency]] forKey:@"fusionSecondTransparency"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller fusionDecimate]] forKey:@"fusionDecimate"];
				[seriesInfo setObject:[NSNumber numberWithInt:[controller fusionSmooth]] forKey:@"fusionSmooth"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionShouldDecimate]] forKey:@"fusionShouldDecimate"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionShouldSmooth]] forKey:@"fuiosnShouldSmooth"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionUseFirstSurface]] forKey:@"fusionUseFirstSurface"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller fusionUseSecondSurface]] forKey:@"fusionUseSecondSurface"];
				[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller fusionFirstColor]] forKey:@"fusionFirstColor"];
				[seriesInfo setObject:[NSArchiver archivedDataWithRootObject:[controller fusionSecondColor]] forKey:@"fusionSecondColor"];

			}
			
			if ([controller isKindOfClass:[ViewerController class]]) {
				[seriesInfo setObject:[controller curWLWWMenu] forKey:@"wwwlMenuItem"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller rotation]] forKey:@"rotation"];
				[seriesInfo setObject:[NSNumber numberWithFloat:[controller scaleValue]] forKey:@"zoom"];
				[seriesInfo setObject:[NSNumber numberWithInt:[[controller seriesView] imageRows]] forKey:@"imageRows"];
				[seriesInfo setObject:[NSNumber numberWithInt:[[controller seriesView] imageColumns]] forKey:@"imageColumns"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller xFlipped]] forKey:@"xFlipped"];
				[seriesInfo setObject:[NSNumber numberWithBool:[controller yFlipped]] forKey:@"yFlipped"];
			}
			
			//Save Viewer Class
			[seriesInfo setObject:NSStringFromClass([controller class]) forKey:@"Viewer Class"];
			
			// MIP vs VP fpr Volume Rendering
			if ([controller isKindOfClass:[VRController class]] || [controller isKindOfClass:[VRPROController class]] )
				[seriesInfo setObject:[(VRController  *)controller renderingMode] forKey:@"mode"];
				
			[seriesInfo setObject:[NSNumber numberWithBool:[window isKeyWindow]] forKey:@"isKeyWindow"];
			
			// Have blending.  Get Series Description for blending
			
			if ([controller isKindOfClass:[ViewerController class]] && [controller blendingController]) {
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
