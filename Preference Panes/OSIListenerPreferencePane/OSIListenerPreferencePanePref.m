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

#import "OSIListenerPreferencePanePref.h"


#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>

char *GetPrivateIP()
{
	struct			hostent *h;
	char			hostname[100];
	gethostname(hostname, 99);
	if ((h=gethostbyname(hostname)) == NULL)
	{
        perror("Error: ");
        return "(Error locating Private IP Address)";
    }
	
    return (char*) inet_ntoa(*((struct in_addr *)h->h_addr));
}

@implementation OSIListenerPreferencePanePref

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
	
	if( aView == _authView) return;
	
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }

	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

- (void) enableControls: (BOOL) val
{
	[self checkView: [self mainView] :val];

//	[characterSetPopup setEnabled: val];
//	[addServerDICOM setEnabled: val];
//	[addServerSharing setEnabled: val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIListenerPreferencePanePref");
	
	[super dealloc];
}

-(IBAction) setExtraStoreSCP:(id) sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[extrastorescp stringValue] forKey:@"STORESCPEXTRA"];
}

-(IBAction) helpstorescp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://support.dcmtk.org/docs/storescp.html"]];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.listener"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];


	//setup GUI
	
	NSString *ip = [NSString stringWithCString:GetPrivateIP()];
	char			hostname[100];
	gethostname(hostname, 99);
	NSString *name = [NSString stringWithCString:hostname];

	[ipField setStringValue: ip];
	[nameField setStringValue: name];
	
	if( [defaults stringForKey:@"STORESCPEXTRA"])
		[extrastorescp setStringValue:[defaults stringForKey:@"STORESCPEXTRA"]];
	[aeTitleField setStringValue:[defaults stringForKey:@"AETITLE"]];
	[portField setStringValue:[defaults stringForKey:@"AEPORT"]];
	
	[generateLogsButton setState:[defaults boolForKey:@"NETWORKLOGS"]];
	[listenerOnOffButton setState:[defaults boolForKey:@"STORESCP"]];
	
	[singleProcessButton setState:[defaults boolForKey:@"SINGLEPROCESS"]];
	
//	[useStoreSCPModeMatrix selectCellWithTag:[defaults boolForKey:@"USESTORESCP"]];
//	
//	[defaults boolForKey:@"USESTORESCP"] ? 
//	[transferSyntaxBox setHidden:NO] : [transferSyntaxBox setHidden:YES];
//	int index = 7;
//	if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+x="]) //local byte order
//		index = 0;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xe"]) // explicit litle
//		index = 1;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xb"]) // explicit Big
//		index = 2;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xs"]) // jpeg lossless
//		index = 3;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xy"]) // jpeg lossy 8
//		index = 4;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xx"]) //jpeg lossy 12
//		index = 5;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xr"]) // rle
//		index = 6;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xi"]) // implicit
//		index = 7;
//	
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xv"]) // jpeg 2000 lossless
//		index = 8;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xw"]) // jpeg 2000 lossy
//		index = 9;
//	
//	[transferSyntaxModeMatrix selectCellWithTag:index];

	[deleteFileModeMatrix selectCellWithTag:[defaults boolForKey:@"DELETEFILELISTENER"]];
	
	[listenerOnOffAnonymize setState:[defaults boolForKey:@"ANONYMIZELISTENER"]];
	
	[logDurationPopup selectItemWithTag: [defaults integerForKey:@"LOGCLEANINGDAYS"]];
}

- (IBAction)setLogDuration:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[[logDurationPopup selectedItem] tag]  forKey:@"LOGCLEANINGDAYS"];
}

- (IBAction)setAE:(id)sender{
	[[NSUserDefaults standardUserDefaults] setObject:[aeTitleField stringValue] forKey:@"AETITLE"];
	[[NSUserDefaults standardUserDefaults] setObject:[portField stringValue] forKey:@"AEPORT"];
}

- (IBAction)setUseStoreSCP:(id)sender{
	BOOL useDCMTK = [[sender selectedCell] tag];
	NSLog(@"setUseStoreSCP: %d", useDCMTK);	
	[[NSUserDefaults standardUserDefaults] setBool:useDCMTK forKey:@"USESTORESCP"];	
	useDCMTK ? [transferSyntaxBox setHidden:NO] : [transferSyntaxBox setHidden:YES];		
}

- (IBAction)setTransferSyntaxMode:(id)sender{
	NSString *AETransferSyntax;
	switch( [[sender selectedCell] tag])
	{
		default:
		case 0:		AETransferSyntax = [[NSString alloc] initWithString:@"+x="];		break;
		case 1:		AETransferSyntax = [[NSString alloc] initWithString:@"+xe"];		break;
		case 2:		AETransferSyntax = [[NSString alloc] initWithString:@"+xb"];		break;
		case 3:		AETransferSyntax = [[NSString alloc] initWithString:@"+xs"];		break;
		case 4:		AETransferSyntax = [[NSString alloc] initWithString:@"+xy"];		break;
		case 5:		AETransferSyntax = [[NSString alloc] initWithString:@"+xx"];		break;
		case 6:		AETransferSyntax = [[NSString alloc] initWithString:@"+xr"];		break;
		case 7:		AETransferSyntax = [[NSString alloc] initWithString:@"+xi"];		break;
		case 8:		AETransferSyntax = [[NSString alloc] initWithString:@"+xv"];		break;
		case 9:		AETransferSyntax = [[NSString alloc] initWithString:@"+xw"];		break;
	}
	[[NSUserDefaults standardUserDefaults] setObject:AETransferSyntax forKey:@"AETransferSyntax"];
	[AETransferSyntax release];
}

- (IBAction)setSingleProcess:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"SINGLEPROCESS"];
}
- (IBAction)setDeleteFileMode:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey:@"DELETEFILELISTENER"];
}
- (IBAction)setListenerOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"STORESCP"];
}
- (IBAction)setGenerateLogs:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"NETWORKLOGS"];
}
- (IBAction)setAnonymizeListenerOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"ANONYMIZELISTENER"];
}
@end
