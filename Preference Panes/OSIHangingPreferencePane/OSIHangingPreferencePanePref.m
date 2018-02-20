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
 OsiriX project.
 
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

#import "WindowLayoutManager.h"
#import "OSIHangingPreferencePanePref.h"
#import "NSArray+N2.h"
#import "NSPreferencePane+OsiriX.h"
#import "Notifications.h"
#import "AppController.h"

@implementation OSIHangingPreferencePanePref

@synthesize modalityForHangingProtocols;
@synthesize WLWWNewName, WLnew, WWnew;

+ (void) convertWLWWToMenuTag: (NSMutableDictionary*) protocol
{
    if( [[protocol objectForKey: @"WL"] floatValue] == 0 && [[protocol objectForKey: @"WW"] floatValue] == 0)
    {
        [protocol setObject: @100 forKey: @"WLWW"]; //Default
        return;
    }
         
    if( [[protocol objectForKey: @"WL"] floatValue] == 1 && [[protocol objectForKey: @"WW"] floatValue] == 1)
    {
        [protocol setObject: @101 forKey: @"WLWW"]; //Full Dynamic
        return;
    }
    
    NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
    NSArray *sortedKeys = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for( NSString *key in sortedKeys)
    {
        NSArray *a = [wlwwDict objectForKey: key];
        
        if( [[protocol objectForKey: @"WL"] floatValue] == [[a objectAtIndex:0] floatValue] && [[protocol objectForKey: @"WW"] floatValue] == [[a objectAtIndex:1] floatValue])
        {
            [protocol setObject: @([sortedKeys indexOfObject: key] + 1) forKey: @"WLWW"];
            return;
        }
    }
    
    [protocol setObject: @0 forKey: @"WLWW"];
    return;
}

+ (void) convertMenuTagToWLWW: (NSMutableDictionary*) protocol
{
    if( [protocol objectForKey: @"WLWW"] == nil)
        return;
    
    if( [[protocol objectForKey: @"WLWW"] intValue] == 100 || [[protocol objectForKey: @"WLWW"] intValue] == 0)
    {
        [protocol setObject: @0 forKey: @"WL"]; //Default
        [protocol setObject: @0 forKey: @"WW"];
        [protocol removeObjectForKey: @"WLWW"];
        return;
    }
    
    if( [[protocol objectForKey: @"WLWW"] intValue] == 101)
    {
        [protocol setObject: @1 forKey: @"WL"]; //Full
        [protocol setObject: @1 forKey: @"WW"];
        [protocol removeObjectForKey: @"WLWW"];
        return;
    }
    
    NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
    NSArray *sortedKeys = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    if( [[protocol objectForKey: @"WLWW"] intValue] > 0 && [[protocol objectForKey: @"WLWW"] intValue] <= sortedKeys.count)
    {
        NSString *key = [sortedKeys objectAtIndex: [[protocol objectForKey: @"WLWW"] intValue]-1];
        NSArray *a = [wlwwDict objectForKey: key];
        
        [protocol setObject: [a objectAtIndex:0] forKey: @"WL"];
        [protocol setObject: [a objectAtIndex:1] forKey: @"WW"];
        [protocol removeObjectForKey: @"WLWW"];
        return;
    }
    
    [protocol removeObjectForKey: @"WLWW"];
    
    return;
}

- (void) AddCurrentWLWW:(NSMutableDictionary*) sender
{
	self.WLWWNewName = NSLocalizedString(@"Unnamed", nil);
	
    currentWLWWProtocol = [sender retain];
    
	[NSApp beginSheet: addWLWWWindow modalForWindow: self.mainView.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(IBAction) endNameWLWW:(id) sender
{
    [addWLWWWindow makeFirstResponder: nil];
    
    if( [sender tag])   //User clicks OK Button
    {        
        if( WLnew == nil || WWnew == nil)
        {
            NSRunCriticalAlertPanel( NSLocalizedString( @"WL / WW Error", nil), NSLocalizedString( @"Provide values for WL and WW.", nil), NSLocalizedString( @"OK", nil), nil, nil);
            return;
        }
        
        float iwl, iww;
        
        iwl = [WLnew floatValue];
        iww = [WWnew floatValue];
        if( iww < 1) iww = 1;
        
        if( self.WLWWNewName.length)
        {
            NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] mutableCopy] autorelease];
            
            if( [presetsDict valueForKey: self.WLWWNewName])
            {
                if( NSRunInformationalAlertPanel(NSLocalizedString( @"WL / WW", 0L), NSLocalizedString( @"Another WL/WW setting with this name already exists. Are you sure you want to replace it with this one?", 0L), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) != NSAlertDefaultReturn)
                {
                    return;
                }
            }
            
            [presetsDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:self.WLWWNewName];
            [[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey:@"WLWW3"];
            
            [self buildWLWWMenu];
            
            [currentWLWWProtocol setValue: @(iwl) forKey: @"WL"];
            [currentWLWWProtocol setValue: @(iww) forKey: @"WW"];
            
            NSArray *sortedKeys = [[presetsDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            
            for( NSString *key in sortedKeys)
            {
                NSArray *a = [presetsDict objectForKey: key];
                
                if( [[currentWLWWProtocol objectForKey: @"WL"] floatValue] == [[a objectAtIndex:0] floatValue] && [[currentWLWWProtocol objectForKey: @"WW"] floatValue] == [[a objectAtIndex:1] floatValue])
                {
                    [currentWLWWProtocol setObject: @([sortedKeys indexOfObject: key] + 1) forKey: @"WLWW"];
                    break;
                }
            }
        }
        else
        {
            NSRunCriticalAlertPanel( NSLocalizedString( @"WL / WW Error", nil), NSLocalizedString( @"Provide a name for this setting.", nil), NSLocalizedString( @"OK", nil), nil, nil);
            return;
        }
    }
    else
    {
        [currentWLWWProtocol setValue: @0 forKey: @"WL"];
        [currentWLWWProtocol setValue: @0 forKey: @"WW"];
        [currentWLWWProtocol setValue: @100 forKey: @"WLWW"]; // Default
    }
    
    [addWLWWWindow orderOut:sender];
    
    [NSApp endSheet:addWLWWWindow returnCode:[sender tag]];
    
    [currentWLWWProtocol release];
    currentWLWWProtocol = nil;
}

- (NSArray*) currentHangingProtocol
{
    NSArray *a = [hangingProtocols objectForKey: modalityForHangingProtocols];
    
    for( NSMutableDictionary *d in a)
    {
        if( [[d valueForKey: @"NumberOfComparativeToDisplay"] intValue] <= 0)
             [d setValue: [NSNumber numberWithInt: 1] forKey: @"NumberOfComparativeToDisplay"];
    }
    
    return a;
}

- (void) buildWLWWMenu
{
    [WLWWPopup removeAllItems];
    
    NSArray *sortedKeys = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [WLWWPopup addItemWithTitle:NSLocalizedString(@"Default WL & WW", nil) action: nil keyEquivalent:@""];
    [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: 100];
    
    [WLWWPopup addItemWithTitle:NSLocalizedString(@"Full dynamic", nil) action: nil keyEquivalent:@""];
    [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: 101];
    
    [WLWWPopup addItemWithTitle:NSLocalizedString(@"Other", nil) action: nil keyEquivalent:@""];
    [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: 0];
    
    [WLWWPopup addItem: [NSMenuItem separatorItem]];
    
    for( int i = 0; i < [sortedKeys count]; i++)
    {
        [WLWWPopup addItemWithTitle:[NSString stringWithFormat:@"%@", [sortedKeys objectAtIndex:i]] action: nil keyEquivalent:@""];
        [[WLWWPopup itemAtIndex: WLWWPopup.itemArray.count -1] setTag: i+1];
    }
}

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIHangingPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
        [addWLWWWindow retain];
        
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        // Windows/Image/WLWW menus
        NSMenu *tilingMenu = [[AppController sharedAppController] imageTilingMenu];
        
        [windowsTilingPopup removeAllItems];
        [imageTilingPopup removeAllItems];
        
        for( NSMenuItem *i in tilingMenu.itemArray)
        {
            [windowsTilingPopup addItem: [i.copy autorelease]];
            [imageTilingPopup addItem: [i.copy autorelease]];
        }
        
        [windowsTilingPopup addItem: [NSMenuItem separatorItem]];
        [windowsTilingPopup addItemWithTitle: NSLocalizedString( @"All series", nil) action:nil keyEquivalent:@""];
        [[[windowsTilingPopup itemArray] lastObject] setTag: 1000];
        
        for( NSMenuItem *i in windowsTilingPopup.itemArray)
            [i setAction: nil];
        
        for( NSMenuItem *i in imageTilingPopup.itemArray)
            [i setAction: nil];
        
        [self buildWLWWMenu];
	}
	
	return self;
}

- (void)deleteWLWW:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSString *name = (id) contextInfo;
	
    if( returnCode == 1)
    {
		NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] mutableCopy] autorelease];
        
        NSUInteger index = [[[presetsDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] indexOfObject: name];
        
		[presetsDict removeObjectForKey: name];
		[[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey:@"WLWW3"];
        
        [self buildWLWWMenu];
        
        for( NSString *modality in hangingProtocols)
        {
            for( NSMutableDictionary *p in [hangingProtocols objectForKey: modality])
            {
                if( [[p valueForKey: @"WLWW"] intValue] == index+1)
                {
                    [p setValue: @0 forKey: @"WL"];
                    [p setValue: @0 forKey: @"WW"];
                    [p setValue: @100 forKey: @"WLWW"];
                }
            }
        }
    }
	
	[name release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id) object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString: @"arrangedObjects.WLWW"])
    {
        for( NSMutableDictionary *d in [arrayController selectedObjects])
        {
            if( [[d valueForKey: @"WLWW"] intValue] == 0)
                [self AddCurrentWLWW: d];
            
            if( [[d valueForKey: @"WLWW"] intValue] != 0 && [[d valueForKey: @"WLWW"] intValue] != 100 && [[d valueForKey: @"WLWW"] intValue] != 101)
            {
                if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) // Delete
                {
                    NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
                    NSArray *sortedKeys = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                    
                    NSString *name = [sortedKeys objectAtIndex: [[d valueForKey: @"WLWW"] intValue]-1];
                    
                    NSBeginAlertSheet( NSLocalizedString(@"Remove a WL/WW preset", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, self.mainView.window, self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [name retain], NSLocalizedString( @"Are you sure you want to delete preset : '%@'?", nil), name);
                }
            }
        }
    }
    
    if( [keyPath isEqualToString: @"arrangedObjects.Study Description"])
    {
        for( NSMutableDictionary *d in [arrayController selectedObjects])
        {
           if( [[arrayController arrangedObjects] indexOfObject: d] == 0)
           {
               if( [[d valueForKey: @"Study Description"] isEqualToString: NSLocalizedString( @"Default", nil)] == NO && [[d valueForKey: @"Study Description"] isEqualToString: @"Default"] == NO)
               {
                   NSRunCriticalAlertPanel( NSLocalizedString( @"Default Protocol", nil), NSLocalizedString( @"Default protocol cannot be renamed", nil), NSLocalizedString( @"OK", nil), nil, nil);
                   
                   [d setValue: NSLocalizedString( @"Default", nil) forKey: @"Study Description"];
               }
           }
        }
    }
}

- (void) mainViewDidLoad
{
}

- (void)dealloc
{
	[hangingProtocols release];
	self.modalityForHangingProtocols = nil;
	
    self.WWnew = nil;
    self.WLnew = nil;
    self.WLWWNewName = nil;
    
    NSLog(@"dealloc OSIHangingPreferencePanePref");
    
    [addWLWWWindow release];
    
    [_tlos release]; _tlos = nil;
    
	[super dealloc];
}

- (void)setModalityForHangingProtocols:(NSString*) m
{
    [[[self mainView] window] makeFirstResponder: nil];
    
    [self willChangeValueForKey: @"currentHangingProtocol"];
	[modalityForHangingProtocols autorelease];
	modalityForHangingProtocols = [m retain];
    [self didChangeValueForKey: @"currentHangingProtocol"];
}

- (IBAction)newHangingProtocol:(id)sender
{
	NSMutableDictionary *protocol = [NSMutableDictionary dictionary];
    [protocol setObject: [NSString stringWithFormat: @"%@ %d", NSLocalizedString( @"Character String", nil), (int) [[hangingProtocols objectForKey:modalityForHangingProtocols] count]] forKey:@"Study Description"];
    [protocol setObject: [NSNumber numberWithInt:0] forKey:@"WindowsTiling"];
	[protocol setObject: [NSNumber numberWithInt:0] forKey:@"ImageTiling"];
    [protocol setObject: @(YES) forKey:@"Sync"];
    [protocol setObject: @(YES) forKey:@"Propagate"];
    [protocol setObject: [NSNumber numberWithInt:0] forKey:@"WL"]; // Default WL/WW
    [protocol setObject: [NSNumber numberWithInt:0] forKey:@"WW"];
    [protocol setObject: [NSNumber numberWithInt:100] forKey:@"WLWW"];
    [protocol setObject: [NSNumber numberWithInt:1] forKey:@"NumberOfComparativeToDisplay"];
    
    [self willChangeValueForKey: @"currentHangingProtocol"];
    [[hangingProtocols objectForKey:modalityForHangingProtocols] addObject:protocol];
    [self didChangeValueForKey: @"currentHangingProtocol"];
}

- (void) deleteSelectedRow:(NSTableView*)sender
{
    if( NSRunInformationalAlertPanel(NSLocalizedString( @"Delete Protocol", 0L), NSLocalizedString( @"Are you sure you want to delete the selected protocol?", 0L), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
    {
        [self willChangeValueForKey: @"currentHangingProtocol"];
        [[hangingProtocols objectForKey:modalityForHangingProtocols] removeObjectAtIndex: sender.selectedRow];
        [self didChangeValueForKey: @"currentHangingProtocol"];
    }
}

-(void) willSelect
{
	hangingProtocols = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HANGINGPROTOCOLS"] deepMutableCopy];
	
    for( NSString *modality in hangingProtocols)
    {
        for( NSMutableDictionary *protocol in [hangingProtocols objectForKey: modality])
        {
            [OSIHangingPreferencePanePref convertWLWWToMenuTag: protocol];
            
            if( [[hangingProtocols objectForKey: modality] indexOfObject: protocol] == 0)
                [protocol setValue: NSLocalizedString( @"Default", nil) forKey: @"Study Description"];
            
            if( [protocol objectForKey: @"Sync"] == nil)
                [protocol setObject: @(YES) forKey: @"Sync"];
            
            if( [protocol objectForKey: @"Propagate"] == nil)
                [protocol setObject: @(YES) forKey: @"Propagate"];
            
            if( [[protocol objectForKey: @"NumberOfSeriesPerComparative"] integerValue] < 1)
                [protocol setObject: @1 forKey: @"NumberOfSeriesPerComparative"];
        }
    }
	self.modalityForHangingProtocols = @"CR";
    
    [arrayController addObserver:self forKeyPath: @"arrangedObjects.WLWW" options: 0 context:NULL];
    [arrayController addObserver:self forKeyPath: @"arrangedObjects.Study Description" options: 0 context:NULL];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
    [arrayController removeObserver: self forKeyPath: @"arrangedObjects.WLWW"];
    [arrayController removeObserver: self forKeyPath: @"arrangedObjects.Study Description"];
    
    for( NSString *modality in hangingProtocols)
    {
        for( NSMutableDictionary *protocol in [hangingProtocols objectForKey: modality])
        {
            [OSIHangingPreferencePanePref convertMenuTagToWLWW: protocol];
            
            [protocol setObject: @([WindowLayoutManager windowsRowsForHangingProtocol: protocol]) forKey: @"Rows"];
            [protocol setObject: @([WindowLayoutManager windowsColumnsForHangingProtocol: protocol]) forKey: @"Columns"];
            
            [protocol setObject: @([WindowLayoutManager imagesRowsForHangingProtocol: protocol]) forKey: @"Image Rows"];
            [protocol setObject: @([WindowLayoutManager imagesColumnsForHangingProtocol: protocol]) forKey: @"Image Columns"];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:hangingProtocols forKey:@"HANGINGPROTOCOLS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end

#pragma mark

@interface HangingTableView : NSTableView {
}

@end

@implementation HangingTableView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	if ((c == NSDeleteCharacter || c == NSBackspaceCharacter))
    {
        if( [self selectedRow] > 0)
            [(OSIHangingPreferencePanePref*)[self delegate] deleteSelectedRow: self];
        else
            NSRunCriticalAlertPanel( NSLocalizedString( @"Delete Protocol", 0L), NSLocalizedString( @"You cannot delete the default protocol", nil), NSLocalizedString( @"OK", nil), nil, nil);
	}
	else
        [super keyDown:event];
}

@end

