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

#import "OSICustomImageAnnotations.h"
#import "PreferencesWindowController+DCMTK.h"
#import "NSPreferencePane+OsiriX.h"

NSComparisonResult  compareViewTags(id firstView, id secondView, void * context);
NSComparisonResult  compareViewTags(id firstView, id secondView, void * context)
{
   int firstTag;
   int secondTag;
   id v = context;
	
	if( [v boolValue])
	{
		secondTag = [firstView tag];
		firstTag = [secondView tag];
	}
	else
	{
		firstTag = [firstView tag];
		secondTag = [secondView tag];
	}

   if (firstTag == secondTag) {return NSOrderedSame;}
   else
   {
       if (firstTag < secondTag) {return NSOrderedAscending;}
       else {return NSOrderedDescending;}
   }
}

@implementation OSICustomImageAnnotations

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSICustomImageAnnotations" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

- (void)dealloc {
    [_tlos release]; _tlos = nil;
    
    [super dealloc];
}

- (void)mainViewDidLoad {
	//[gray setInterceptsMouse:YES];
}

- (void) enableControls:(BOOL)enable
{
	if(!enable) [layoutView setDisabledText:@""];
	else [layoutView setDefaultDisabledText];
	[[self mainView] sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *))compareViewTags context: [NSNumber numberWithBool:enable]];
}

#pragma mark -

- (NSArray*) prepareDICOMFieldsArrays
{
	return [[[[self mainView] window] windowController] prepareDICOMFieldsArrays];
}

- (IBAction) loadsave:(id) sender
{
	if( [sameAsDefaultButton state] == NSOnState) return;
	
	if( [sender selectedSegment] == 0)		// Save
	{
		[self switchModality: modalitiesPopUpButton save: YES];
		
		NSSavePanel *sPanel = [NSSavePanel savePanel];
		[sPanel setAllowedFileTypes:@[@"plist"]];
        sPanel.nameFieldStringValue = [NSString stringWithFormat:@"%@.plist", [[modalitiesPopUpButton selectedItem] title] ];
        
        [sPanel beginWithCompletionHandler:^(NSInteger result) {
            if (result != NSFileHandlingPanelOKButton)
                return;
            
            [[layoutController curDictionary] writeToURL:sPanel.URL atomically:YES];
        }];
	}
	else						// Load
	{
		NSOpenPanel *sPanel = [NSOpenPanel openPanel];
        [sPanel setAllowedFileTypes:@[@"plist"]];

        [sPanel beginWithCompletionHandler:^(NSInteger result) {
            if (result != NSFileHandlingPanelOKButton)
                return;
            
            NSDictionary *cur = [NSDictionary dictionaryWithContentsOfURL:sPanel.URL];
            if( cur)
            {
                if( NSRunInformationalAlertPanel( NSLocalizedString(@"Settings", nil), NSLocalizedString( @"Are you really sure you want to replace current settings? It will delete the current settings.", nil) , NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
                {
                    NSMutableDictionary *annotationsLayoutDictionary = [layoutController annotationsLayoutDictionary];
                    
                    [annotationsLayoutDictionary setObject: cur  forKey: [layoutController currentModality]];
                    
                    [self switchModality: modalitiesPopUpButton save: NO];
                }
            }
        }];
	}
}

- (IBAction) reset: (id) sender
{
	if( NSRunInformationalAlertPanel( NSLocalizedString(@"Settings", nil), NSLocalizedString( @"Are you really sure you want to reset the current default settings? It will delete the current settings.", nil) , NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
	{
		NSMutableDictionary *annotationsLayoutDictionary = [layoutController annotationsLayoutDictionary];
		
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"AnnotationsDefault.plist"]];
		
		[annotationsLayoutDictionary setObject: [dict objectForKey:@"Default"]  forKey: @"Default"];
		
		[self switchModality: modalitiesPopUpButton save: NO];
	}
}

- (id)init
{
	NSLog(@"OSICustomImageAnnotations init");
	
	self = [super init];
	if (self != nil)
	{
	}
	
	return self;
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void)willSelect
{
	NSLog(@"OSICustomImageAnnotations willSelect");
	
	if( [modalitiesPopUpButton numberOfItems] < 5)
	{
		NSArray *modalities = [NSArray arrayWithObjects:NSLocalizedString(@"Default", nil), @"CR", @"CT", @"DX", @"ES", @"MG", @"MR", @"NM", @"OT",@"PT",@"RF",@"SC",@"US",@"XA", nil];
		
		[modalitiesPopUpButton removeAllItems];

		for (id item in modalities)
			[modalitiesPopUpButton addItemWithTitle: item];
	}
	
	if( layoutController == nil)
	{
		layoutController = [[CIALayoutController alloc] initWithWindow:window];
		[sameAsDefaultButton setHidden:YES];
		[resetDefaultButton setHidden:NO];
	}
}

- (void)didSelect
{
	[layoutController setLayoutView:layoutView];
	[layoutController setPrefPane:self];
	[layoutController awakeFromNib];
    
	[self enableControls:[self isUnlocked]];
}

- (NSPreferencePaneUnselectReply)shouldUnselect;
{
	NSWindow *win = [[self mainView] window];
	[win makeFirstResponder:contentTokenField];
	
	[layoutController validateTokenTextField:self];
	
	if(![layoutController checkAnnotations] || ![layoutController checkAnnotationsContent])
		return NSUnselectCancel;
	else
		return NSUnselectNow;
}

- (void)didUnselect
{
	if(layoutController)
	{
		[layoutController saveAnnotationLayout];
//		[layoutController release];
	}
//	layoutController = nil;

	[DICOMFieldsPopUpButton removeAllItems];
}

- (IBAction)addAnnotation:(id)sender;
{
	[layoutController addAnnotation:sender];
	
	[addCustomDICOMFieldButton setEnabled:YES];
	[addDICOMFieldButton setEnabled:YES];
	[addDatabaseFieldButton setEnabled:YES];
	[addSpecialFieldButton setEnabled:YES];
}

- (IBAction)removeAnnotation:(id)sender;
{
	[layoutController removeAnnotation:sender];
	[titleTextField setStringValue:@""];
	
	[addCustomDICOMFieldButton setEnabled:NO];
	[addDICOMFieldButton setEnabled:NO];
	[addDatabaseFieldButton setEnabled:NO];
	[addSpecialFieldButton setEnabled:NO];
}

- (IBAction)setTitle:(id)sender;
{
	[layoutController setTitle:sender];
}

- (IBAction)addFieldToken:(id)sender;
{
	if(sender==addCustomDICOMFieldButton || sender==addDICOMFieldButton || sender==addDatabaseFieldButton || sender==addSpecialFieldButton)
	{
		NSWindow *win = [[self mainView] window];
		[win makeFirstResponder:contentTokenField];
	}
	[layoutController addFieldToken:sender];
}

- (IBAction)validateTokenTextField:(id)sender;
{
	[layoutController validateTokenTextField:sender];
}

- (IBAction)saveAnnotationLayout:(id)sender;
{
	[layoutController saveAnnotationLayoutForModality:[[modalitiesPopUpButton selectedItem] title]];
}

- (IBAction)switchModality:(id)sender
{
	return [self switchModality: sender save: YES];
}

- (IBAction)switchModality:(id)sender save:(BOOL) save;
{
	[layoutController switchModality:sender save: save];
	[addAnnotationButton setEnabled:[sameAsDefaultButton state]==NSOffState];
	[removeAnnotationButton setEnabled:[sameAsDefaultButton state]==NSOffState];
	[loadsaveButton setEnabled:[sameAsDefaultButton state]==NSOffState];
	
	[addCustomDICOMFieldButton setEnabled:NO];
	[addDICOMFieldButton setEnabled:NO];
	[addDatabaseFieldButton setEnabled:NO];
	[addSpecialFieldButton setEnabled:NO];
}

- (CIALayoutController*)layoutController; {return layoutController;}

- (NSTextField*)titleTextField; {return titleTextField;}
- (NSTokenField*)contentTokenField; {return contentTokenField;}
- (NSTextField*)dicomNameTokenField; {return dicomNameTokenField;}
- (NSTextField*)dicomGroupTextField {return dicomGroupTextField;}
- (NSTextField*)dicomElementTextField; {return dicomElementTextField;}
- (NSTextField*)groupLabel; {return groupLabel;}
- (NSTextField*)elementLabel; {return elementLabel;}
- (NSTextField*)nameLabel; {return nameLabel;}
- (NSButton*)addCustomDICOMFieldButton; {return addCustomDICOMFieldButton;}
- (NSButton*)addDICOMFieldButton; {return addDICOMFieldButton;}
- (NSButton*)addDatabaseFieldButton; {return addDatabaseFieldButton;}
- (NSButton*)addSpecialFieldButton; {return addSpecialFieldButton;}
- (NSPopUpButton*)DICOMFieldsPopUpButton; {return DICOMFieldsPopUpButton;}
- (NSPopUpButton*)databaseFieldsPopUpButton; {return databaseFieldsPopUpButton;}
- (NSPopUpButton*)specialFieldsPopUpButton; {return specialFieldsPopUpButton;}
- (NSBox*)contentBox; {return contentBox;}
- (NSButton*)sameAsDefaultButton; {return sameAsDefaultButton;}
- (NSButton*)resetDefaultButton; {return resetDefaultButton;}
- (NSPopUpButton*)modalitiesPopUpButton; {return modalitiesPopUpButton;}

- (IBAction)setSameAsDefault:(id)sender;
{
	BOOL state = [sameAsDefaultButton state]==NSOnState;

	if(state)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"Default", nil), NSLocalizedString( @"Are you really sure you want to replace current settings with the default settings? It will delete the current settings.", nil) , NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn) 
			[layoutController loadAnnotationLayoutForModality:@"Default"];
		else
		{
			[sameAsDefaultButton setState: NSOffState];
			return;
		}
	}
	else
	{
		[layoutController loadAnnotationLayoutForModality:[[modalitiesPopUpButton selectedItem] title]];
	}
	[layoutView setEnabled:!state];
	[sameAsDefaultButton setState:state];
	[layoutView setNeedsDisplay:YES];
	
	[addAnnotationButton setEnabled:!state];
	[removeAnnotationButton setEnabled:!state];
	[loadsaveButton setEnabled:!state];
	
	[orientationWidgetButton setEnabled:!state];
}

- (NSButton*)orientationWidgetButton; {return orientationWidgetButton;}

- (IBAction)toggleOrientationWidget:(id)sender;
{
	BOOL state = [orientationWidgetButton state]==NSOnState;

	[layoutController setOrientationWidgetEnabled:state];
}

@end
