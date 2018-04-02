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

#import "AppController.h"
#import "WaitRendering.h"
#import "BurnerWindowController.h"
#import "MutableArrayCategory.h"
#import <DiscRecordingUI/DRSetupPanel.h>
#import <DiscRecordingUI/DRBurnSetupPanel.h>
#import <DiscRecordingUI/DRBurnProgressPanel.h>
#import "BrowserController.h"
#import "DicomStudy.h"
#import "DicomImage.h"
#import "DicomStudy+Report.h"
#import "Anonymization.h"
#import "AnonymizationPanelController.h"
#import "AnonymizationViewController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "NSFileManager+N2.h"
#import "N2Debug.h"
#import "NSImage+N2.h"
#import "DicomDir.h"
#import "DicomDatabase.h"
#import <DiskArbitration/DiskArbitration.h>
#import "DicomFile.h"
#import "DicomFileDCMTKCategory.h"
#import "DCMUIDs.h"
#import "DicomDatabase+DCMTK.h"
#import "Horos.h"

@implementation BurnerWindowController

@synthesize password, buttonsDisabled, selectedUSB;

- (void) createDMG:(NSString*) imagePath withSource:(NSString*) directoryPath
{
	[[NSFileManager defaultManager] removeItemAtPath:imagePath error:NULL];
	
	NSTask* makeImageTask = [[[NSTask alloc] init] autorelease];

	[makeImageTask setLaunchPath: @"/bin/sh"];
	
	imagePath = [imagePath stringByReplacingOccurrencesOfString: @"\"" withString: @"\\\""];
	directoryPath = [directoryPath stringByReplacingOccurrencesOfString: @"\"" withString: @"\\\""];
	
	NSString* cmdString = [NSString stringWithFormat: @"hdiutil create \"%@\" -srcfolder \"%@\"",
													  imagePath,
													  directoryPath];

	NSArray *args = [NSArray arrayWithObjects: @"-c", cmdString, nil];

	[makeImageTask setArguments:args];
	[makeImageTask launch];
    while( [makeImageTask isRunning])
        [NSThread sleepForTimeInterval: 0.1];
    
    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
}


-(id) initWithFiles:(NSArray *)theFiles
{
    if( self = [super initWithWindowNibName:@"BurnViewer"])
    {
		[[NSFileManager defaultManager] removeItemAtPath:[self folderToBurn] error:NULL];
		
		files = [theFiles mutableCopy];
		burning = NO;
		
		[[self window] center];
		
		NSLog( @"Burner allocated");
	}
	return self;
}

- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects
{
	if( self = [super initWithWindowNibName:@"BurnViewer"])
	{
		[[NSFileManager defaultManager] removeItemAtPath:[self folderToBurn] error:NULL];
		
		files = [theFiles mutableCopy]; // file paths
		dbObjectsID = [managedObjects mutableCopy];
		originalDbObjectsID = [dbObjectsID mutableCopy];
		
		[files removeDuplicatedStringsInSyncWithThisArray: dbObjectsID];
		
		id managedObject;
		id patient = nil;
		_multiplePatients = NO;
		
		for (managedObject in [[[BrowserController currentBrowser] database] objectsWithIDs: dbObjectsID])
		{
			NSString *newPatient = [managedObject valueForKeyPath:@"series.study.patientUID"];
			
			if( patient == nil)
				patient = newPatient;
			else if( [patient compare: newPatient options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
			{
				_multiplePatients = YES;
				break;
			}
			patient = newPatient;
		}
		
		burning = NO;
		
		[[self window] center];
		
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidUnmountNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
        
		NSLog( @"Burner allocated");
	}
	return self;
}

-(void)_observeVolumeNotification:(NSNotification*)notification
{
    [self willChangeValueForKey: @"volumes"];
    [self didChangeValueForKey:@"volumes"];
}

- (void)windowDidLoad
{
	NSLog(@"BurnViewer did load");
	
	[[self window] setDelegate:self];
	[self setup:nil];
	
	[compressionMode selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"Compression Mode for Burning"]];
}

- (void)dealloc
{
	windowWillClose = YES;
	
	runBurnAnimation = NO;
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    
	[anonymizedFiles release];
	[filesToBurn release];
	[dbObjectsID release];
	[originalDbObjectsID release];
	[cdName release];
	[password release];
    [writeDMGPath release];
    [writeVolumePath release];
	[anonymizationTags release];
    [files release];
    
	NSLog(@"Burner dealloc");	
	[super dealloc];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (NSArray *)filesToBurn
{
	return filesToBurn;
}

- (void)setFilesToBurn:(NSArray *)theFiles
{
	[filesToBurn release];
	filesToBurn = [theFiles retain];
}

- (NSArray *)extractFileNames:(NSArray *)filenames
{
    NSString *pname;
    NSString *fname;
    NSString *pathName;
    BOOL isDir;

    NSMutableArray *fileNames = [[[NSMutableArray alloc] init] autorelease];
	//NSLog(@"Extract");
    for (fname in filenames)
	{ 
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//NSLog(@"fname %@", fname);
        NSFileManager *manager = [NSFileManager defaultManager];
        if( [manager fileExistsAtPath:fname isDirectory:&isDir] && isDir)
		{
            NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:fname];
            //Loop Through directories
            while (pname = [direnum nextObject])
			{
                pathName = [fname stringByAppendingPathComponent:pname]; //make pathanme
                if( [manager fileExistsAtPath:pathName isDirectory:&isDir] && !isDir)
				{ //check for directory
					if( [DicomFile isDICOMFile: pathName])
                        [fileNames addObject:pathName];
                }
            } //while pname
                
        } //if
		else if( [DicomFile isDICOMFile: fname]) {	//Pathname
				[fileNames addObject:fname];
        }
		[pool release];
    } //while
    return fileNames;
}

//Actions
-(IBAction) burn: (id)sender
{
	if( !(isExtracting || isSettingUpBurn || burning))
	{
        cancelled = NO;
        
        [sizeField setStringValue: @""];
        
        [cdName release];
        cdName = [[nameField stringValue] retain];
        
        if( [cdName length] <= 0)
        {
            [cdName release];
            cdName = [@"UNTITLED" retain];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:[self folderToBurn] error:NULL];
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/burnAnonymized"] error:NULL];
        
        [writeVolumePath release];
        writeVolumePath = nil;
        
        [writeDMGPath release];
        writeDMGPath = nil;
        
        [anonymizationTags release];
        anonymizationTags = nil;
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"])
        {
            AnonymizationPanelController* panelController = [Anonymization showPanelForDefaultsKey:@"AnonymizationFields" modalForWindow:self.window modalDelegate:NULL didEndSelector:NULL representedObject:NULL];
            
            if( panelController.end == AnonymizationPanelCancel)
                return;
            
            anonymizationTags = [panelController.anonymizationViewController.tagsValues retain];
        }
        else
        {
            [anonymizedFiles release];
            anonymizedFiles = nil;
        }
        
        self.buttonsDisabled = YES;
        
        @try
        {
            if( cdName != nil && [cdName length] > 0)
            {
                runBurnAnimation = YES;
                
                if( [[NSUserDefaults standardUserDefaults] integerForKey: @"burnDestination"] == USBKey)
                {
                    [writeVolumePath release];
                    writeVolumePath = nil;
                    if( selectedUSB != NSNotFound && selectedUSB < [self volumes].count)
                        writeVolumePath = [[[self volumes] objectAtIndex: selectedUSB] retain];
                    
                    if( writeVolumePath == nil)
                    {
                        NSRunCriticalAlertPanel( NSLocalizedString( @"USB Writing", nil), NSLocalizedString( @"No destination selected.", nil), NSLocalizedString( @"OK", nil), nil, nil);
                        
                        self.buttonsDisabled = NO;
                        runBurnAnimation = NO;
                        burning = NO;
                        return;
                    }
                    
                    NSInteger result = NSRunCriticalAlertPanel( NSLocalizedString( @"USB Writing", nil), NSLocalizedString( @"The ENTIRE content of the selected media (%@) will be deleted, before writing the new data. Do you confirm?", nil), NSLocalizedString( @"OK", nil), NSLocalizedString( @"Cancel", nil), nil, writeVolumePath, nil);
                    
                    if( result != NSAlertDefaultReturn)
                    {
                        self.buttonsDisabled = NO;
                        runBurnAnimation = NO;
                        burning = NO;
                        return;
                    }
                    
                    [[BrowserController currentBrowser] removePathFromSources: writeVolumePath];
                }
                
                if( [[NSUserDefaults standardUserDefaults] integerForKey: @"burnDestination"] == DMGFile)
                {
                    NSSavePanel *savePanel = [NSSavePanel savePanel];
                    [savePanel setCanSelectHiddenExtension:YES];
                    [savePanel setAllowedFileTypes:@[@"dmg"]];
                    [savePanel setTitle:@"Save as DMG"];
                    savePanel.nameFieldStringValue = cdName;
                    
                    if ([savePanel runModal] == NSFileHandlingPanelOKButton)
                    {
                        [writeDMGPath release];
                        writeDMGPath = [[[savePanel URL] path] retain];
                        [[NSFileManager defaultManager] removeItemAtPath: writeDMGPath error: nil];
                    }
                    else
                    {
                        self.buttonsDisabled = NO;
                        runBurnAnimation = NO;
                        burning = NO;
                        return;
                    }
                }
                
                self.password = @"";
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"EncryptCD"])
                {
                    int result = 0;
                    do
                    {
                        [NSApp beginSheet: passwordWindow
                           modalForWindow: self.window
                            modalDelegate: nil
                           didEndSelector: nil
                              contextInfo: nil];
                        
                        result = [NSApp runModalForWindow: passwordWindow];
                        [passwordWindow makeFirstResponder: nil];
                        
                        [NSApp endSheet: passwordWindow];
                        [passwordWindow orderOut: self];
                    }
                    while( [self.password length] < 8 && result == NSRunStoppedResponse);
                    
                    if( result == NSRunStoppedResponse)
                    {
                        
                    }
                    else
                    {
                        self.buttonsDisabled = NO;
                        runBurnAnimation = NO;
                        burning = NO;
                        return;
                    }
                }
                
                NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(performBurn:) object: nil] autorelease];
                t.name = NSLocalizedString( @"Burning...", nil);
                [[ThreadsManager defaultManager] addThreadAndStart: t];
            }
            else
            {
                NSBeginAlertSheet( NSLocalizedString( @"Burn Warning", nil) , NSLocalizedString( @"OK", nil), nil, nil, nil, nil, nil, nil, nil, NSLocalizedString( @"Please add CD name", nil));
                
                self.buttonsDisabled = NO;
                runBurnAnimation = NO;
                burning = NO;
                return;
            } 
        }
        @catch (NSException *exception)
        {
            NSLog( @"*** exception: %@", exception);
        }
	}
}

- (void)performBurn: (id) object
{	 
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    DicomDatabase *idatabase = [[[[BrowserController currentBrowser] database] independentDatabase] retain];
    
    NSMutableArray *dbObjects = [[[idatabase objectsWithIDs: dbObjectsID] mutableCopy] autorelease];
    NSMutableArray *originalDbObjects = [[[idatabase objectsWithIDs: originalDbObjectsID] mutableCopy] autorelease];
    
    @try
    {
        isSettingUpBurn = YES;
        
        if( anonymizationTags)
        {
            NSDictionary* anonOut = [Anonymization anonymizeFiles:files dicomImages: dbObjects toPath:@"/tmp/burnAnonymized" withTags: anonymizationTags];
            
            [anonymizedFiles release];
            anonymizedFiles = [[anonOut allValues] mutableCopy];
        }
        
        [self prepareCDContent: dbObjects :originalDbObjects];
        
        isSettingUpBurn = NO;
        
        int no = 0;
            
        if( anonymizedFiles) no = [anonymizedFiles count];
        else no = [files count];
        
        burning = YES;
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: [self folderToBurn]] && cancelled == NO)
        {
            if( no)
            {
                switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"burnDestination"])
                {
                    case DMGFile:
                        [self createDMG: writeDMGPath withSource:[self folderToBurn]];
                    break;
                    
                    case CDDVD:
                        [self performSelectorOnMainThread:@selector(burnCD:) withObject:nil waitUntilDone:NO];
                        return;
                    break;
                        
                    case USBKey:
                        [self saveOnVolume];
                    break;
                }
            }
        }
        
        self.buttonsDisabled = NO;
        runBurnAnimation = NO;
        burning = NO;
        
        if( cancelled == NO)
        {
            // Finished ! Close the window....
            
            [[NSSound soundNamed: @"Glass.aiff"] play];
            [self.window performSelectorOnMainThread: @selector(performClose:) withObject: self waitUntilDone: NO];
        }
    }
    @catch (NSException *exception)
    {
        NSLog( @"*** exception: %@", exception);
    }
    @finally
    {
        [pool release];
    }
}

- (IBAction) setAnonymizedCheck: (id) sender
{
	if( [anonymizedCheckButton state] == NSOnState)
	{
		if( [[nameField stringValue] isEqualToString: [self defaultTitle]])
		{
			NSDate *date = [NSDate date];
			[self setCDTitle: [NSString stringWithFormat:@"Archive-%@",  [date descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]]];
		}
	}
}

- (void)setCDTitle: (NSString *)title
{
	if( title)
	{
		[cdName release];
		//if( [title length] > 8)
		//	title = [title substringToIndex:8];
		cdName = [[[title uppercaseString] filenameString] retain];
		[nameField setStringValue: cdName];
	}
}

-(IBAction)setCDName:(id)sender
{
	NSString *name = [[nameField stringValue] uppercaseString];
	[self setCDTitle:name];
}

-(NSString *)folderToBurn
{
	return [NSString stringWithFormat:@"/tmp/%@",cdName];
}

-(NSArray*) volumes
{
    NSArray	*removeableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    NSMutableArray *array = [NSMutableArray array];
    
    for( NSString *mediaPath in removeableMedia)
    {
        BOOL		isWritable, isUnmountable, isRemovable;
        NSString	*description = nil, *type = nil;
        
        [[NSWorkspace sharedWorkspace] getFileSystemInfoForPath: mediaPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&type];
        
        if( isRemovable && isWritable && isUnmountable)
            [array addObject: mediaPath];
    }
    
    return array;
}

- (void) saveOnVolume
{
    NSLog( @"Erase volume : %@", writeVolumePath);
    
    for( NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: writeVolumePath error: nil])
        [[NSFileManager defaultManager] removeItemAtPath: [writeVolumePath stringByAppendingPathComponent: path] error: nil];
    
    
    [[NSFileManager defaultManager] copyItemAtPath: [self folderToBurn] toPath: writeVolumePath byReplacingExisting: YES error: nil];
    
    NSString *newName = cdName;
    
    NSTask *t = [NSTask launchedTaskWithLaunchPath: @"/usr/sbin/diskutil" arguments: [NSArray arrayWithObjects: @"rename", writeVolumePath, newName, nil]];
    
    while( [t isRunning])
        [NSThread sleepForTimeInterval: 0.1];
    
    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
    
    [NSThread sleepForTimeInterval: 1];
    
    //Did we succeed? Basic MS-DOS FAT support only CAPITAL letters and maximum of 10 characters...
    if( [[NSFileManager defaultManager] fileExistsAtPath: [[writeVolumePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: newName]] == NO)
    {
        if( newName.length > 10)
            newName = [newName substringToIndex: 10];
        
        NSTask *t = [NSTask launchedTaskWithLaunchPath: @"/usr/sbin/diskutil" arguments: [NSArray arrayWithObjects: @"rename", writeVolumePath, [newName uppercaseString], nil]];
        
        while( [t isRunning])
            [NSThread sleepForTimeInterval: 0.1];
        
        //[t waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
        
        [NSThread sleepForTimeInterval: 1];
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: [[writeVolumePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: newName]] == NO)
        {
            newName = @"DICOM";
            
            NSTask *t = [NSTask launchedTaskWithLaunchPath: @"/usr/sbin/diskutil" arguments: [NSArray arrayWithObjects: @"rename", writeVolumePath, newName, nil]];
            
            while( [t isRunning])
                [NSThread sleepForTimeInterval: 0.1];
            
            //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
            
            [NSThread sleepForTimeInterval: 1];
        }
    }
    
    [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [[writeVolumePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: newName]];
    
    NSLog( @"Ejecting new DICOM Volume: %@", newName);
}

- (void)burnCD:(id)object
{
    if( [NSThread isMainThread] == NO)
    {
        NSLog( @"******* THIS SHOULD BE ON THE MAIN THREAD: burnCD");
    }
    
    sizeInMb = [[self getSizeOfDirectory: [self folderToBurn]] intValue] / 1024;
    
	DRTrack* track = [DRTrack trackForRootFolder: [DRFolder folderWithPath: [self folderToBurn]]];
    
    if( track)
    {
        DRBurnSetupPanel *bsp = [DRBurnSetupPanel setupPanel];
        
        [bsp setDelegate: self];
        
        if( [bsp runSetupPanel] == NSOKButton)
        {
            DRBurnProgressPanel *bpp = [DRBurnProgressPanel progressPanel];
            [bpp setDelegate: self];
            [bpp beginProgressSheetForBurn:[bsp burnObject] layout:track modalForWindow: [self window]];
            
            return;
        }
	}
    
    self.buttonsDisabled = NO;
    runBurnAnimation = NO;
    burning = NO;
}

//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (BOOL) validateMenuItem:(id)sender
{
	if( [sender action] == @selector(terminate:))
		return (burning == NO);		// No quitting while a burn is going on

	return YES;
}

- (BOOL) setupPanel:(DRSetupPanel*)aPanel deviceContainsSuitableMedia:(DRDevice*)device promptString:(NSString**)prompt;
{
	NSDictionary *status = [device status];
	
	int freeSpace = [[[status objectForKey: DRDeviceMediaInfoKey] objectForKey: DRDeviceMediaBlocksFreeKey] longLongValue] * 2UL / 1024UL;
	
	if( freeSpace > 0 && sizeInMb >= freeSpace)
	{
		*prompt = [NSString stringWithFormat: NSLocalizedString(@"The data to burn is larger than a media size (%d MB), you need a DVD to burn this amount of data (%d MB).", nil), freeSpace, sizeInMb];
        cancelled = YES;
		return NO;
	}
	else if( freeSpace > 0)
	{
		*prompt = [NSString stringWithFormat: NSLocalizedString(@"Data to burn: %d MB (Media size: %d MB), representing %2.2f %%.", nil), sizeInMb, freeSpace, (float) sizeInMb * 100. / (float) freeSpace];
	}
	
	return YES;

}

- (void) burnProgressPanelWillBegin:(NSNotification*)aNotification
{
	burnAnimationIndex = 0;
    runBurnAnimation = YES;
}

- (void) burnProgressPanelDidFinish:(NSNotification*)aNotification
{
    
}

- (BOOL) burnProgressPanel:(DRBurnProgressPanel*)theBurnPanel burnDidFinish:(DRBurn*)burn
{
	NSDictionary*	burnStatus = [burn status];
	NSString*		state = [burnStatus objectForKey:DRStatusStateKey];
	BOOL            succeed = NO;
    
	if( [state isEqualToString:DRStatusStateFailed])
	{
		NSDictionary*	errorStatus = [burnStatus objectForKey:DRErrorStatusKey];
		NSString*		errorString = [errorStatus objectForKey:DRErrorStatusErrorStringKey];
		
		NSRunCriticalAlertPanel( NSLocalizedString( @"Burning failed", nil), @"%@", NSLocalizedString( @"OK", nil), nil, nil, errorString);
	}
	else
    {
        succeed = YES;
		[sizeField setStringValue: NSLocalizedString( @"Burning is finished !", nil)];
	}
    
    self.buttonsDisabled = NO;
    runBurnAnimation = NO;
    burning = NO;
    
    if( succeed)
        [[self window] performSelector: @selector(performClose:) withObject: nil afterDelay: 1];
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [irisAnimationTimer invalidate];
    [irisAnimationTimer release];
    irisAnimationTimer = nil;
    
    [burnAnimationTimer invalidate];
    [burnAnimationTimer release];
    burnAnimationTimer = nil;
    
	windowWillClose = YES;
	
	[[NSUserDefaults standardUserDefaults] setInteger: [compressionMode selectedTag] forKey:@"Compression Mode for Burning"];
	
	NSLog(@"Burner windowWillClose");
	
	[[self window] setDelegate: nil];
	
	isExtracting = NO;
	isSettingUpBurn = NO;
	burning = NO;
	runBurnAnimation = NO;
	
	[self autorelease];
}

- (BOOL)windowShouldClose:(id)sender
{
	NSLog(@"Burner windowShouldClose");
	
	if( (isExtracting || isSettingUpBurn || burning))
		return NO;
	else
	{
		[[NSFileManager defaultManager] removeItemAtPath: [self folderToBurn] error:NULL];
		[[NSFileManager defaultManager] removeItemAtPath: [NSString stringWithFormat:@"/tmp/burnAnonymized"] error:NULL];
		
		[filesToBurn release];
		filesToBurn = nil;
		[files release];
		files = nil;
		[anonymizedFiles release];
		anonymizedFiles = nil;
		
		NSLog(@"Burner windowShouldClose YES");
		
		return YES;
	}
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (void)importFiles:(NSArray *)filenames{
}

- (NSString*) defaultTitle
{
	NSString *title = nil;
	
	if( [files count] > 0)
	{
		NSString *file = [files objectAtIndex:0];
        title = [DicomFile getDicomField: @"PatientsName" forFile: file];
	}
	
    if( title == nil)
        title = @"UNTITLED";
	
	return [[title uppercaseString] filenameString];
}

- (void)setup:(id)sender
{
	//NSLog(@"Set up burn");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	runBurnAnimation = NO;
	[burnButton setEnabled:NO];
	isExtracting = YES;
	
	[self performSelectorOnMainThread:@selector(estimateFolderSize:) withObject:nil waitUntilDone:YES];
	isExtracting = NO;
    
    irisAnimationTimer = [[NSTimer timerWithTimeInterval: 0.07  target: self selector: @selector(irisAnimation:) userInfo: nil repeats: YES] retain];
    [[NSRunLoop currentRunLoop] addTimer: irisAnimationTimer forMode: NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer: irisAnimationTimer forMode: NSDefaultRunLoopMode];
    
    
    burnAnimationTimer = [[NSTimer timerWithTimeInterval: 0.07  target: self selector: @selector(burnAnimation:) userInfo: nil repeats: YES] retain];
    
    [[NSRunLoop currentRunLoop] addTimer: burnAnimationTimer forMode: NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer: burnAnimationTimer forMode: NSDefaultRunLoopMode];
    
	[burnButton setEnabled:YES];
	
	NSString *title = nil;
	
	if( _multiplePatients || [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"])
	{
		NSDate *date = [NSDate date];
		title = [NSString stringWithFormat:@"Archive-%@",  [date descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]];
	}
	else title = [[self defaultTitle] uppercaseString];
	
	[self setCDTitle: title];
	[pool release];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

/*+(void)image:(NSImage*)image writePGMToPath:(NSString*)ppmpath {
    NSSize scaledDownSize = [image sizeByScalingDownProportionallyToSize:NSMakeSize(128,128)];
    NSInteger width = scaledDownSize.width, height = scaledDownSize.height;
    
    static CGColorSpaceRef grayColorSpace = nil;
    if( !grayColorSpace) grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef cgContext = CGBitmapContextCreate(NULL, width, height, 8, width, grayColorSpace, 0);
    uint8* data = CGBitmapContextGetData(cgContext);
    
    NSGraphicsContext* nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
    
    NSGraphicsContext* savedContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:nsContext];
    [image drawInRect:NSMakeRect(0,0,width,height) fromRect:NSMakeRect(0,0,image.size.width,image.size.height) operation:NSCompositeCopy fraction:1];
    [NSGraphicsContext setCurrentContext:savedContext];
    
    NSMutableData* out = [NSMutableData data];
    
    [out appendData:[[NSString stringWithFormat:@"P5\n%d %d\n255\n", width, height] dataUsingEncoding:NSUTF8StringEncoding]];
    [out appendBytes:data length:width*height];
    
    [[NSFileManager defaultManager] confirmDirectoryAtPath:[ppmpath stringByDeletingLastPathComponent]];
    [out writeToFile:ppmpath atomically:YES];
    
    CGContextRelease(cgContext);
}*/

- (void)addDICOMDIRUsingDCMTK_forFilesAtPaths:(NSArray*/*NSString*/)paths dicomImages:(NSArray*/*DicomImage*/)dimages
{
    [DicomDir createDicomDirAtDir:[self folderToBurn]];
}

- (void) produceHtml:(NSString*) burnFolder dicomObjects: (NSMutableArray*) originalDbObjects
{
	//We want to create html only for the images, not for PR, and hidden DICOM SR
	NSMutableArray *images = [NSMutableArray arrayWithCapacity: [originalDbObjects count]];
	
	for( id obj in originalDbObjects)
	{
		if( [DicomStudy displaySeriesWithSOPClassUID: [obj valueForKeyPath:@"series.seriesSOPClassUID"] andSeriesDescription: [obj valueForKeyPath:@"series.name"]])
			[images addObject: obj];
	}
	
	[[BrowserController currentBrowser] exportQuicktimeInt: images :burnFolder :YES];
}

- (NSNumber*) getSizeOfDirectory: (NSString*) path
{
	if( [[NSFileManager defaultManager] fileExistsAtPath: path] == NO) return [NSNumber numberWithLong: 0];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
	if( ![attributes[NSFileType] isEqualToString:NSFileTypeSymbolicLink] && ![attributes[NSFileType] isEqualToString:NSFileTypeUnknown])
	{
		NSArray *args = nil;
		NSPipe *fromPipe = nil;
		NSFileHandle *fromDu = nil;
		NSData *duOutput = nil;
		NSString *size = nil;
		NSArray *stringComponents = nil;
		char aBuffer[ 300];

		args = [NSArray arrayWithObjects:@"-ks",path,nil];
		fromPipe =[NSPipe pipe];
		fromDu = [fromPipe fileHandleForWriting];
		NSTask *duTool = [[[NSTask alloc] init] autorelease];

		[duTool setLaunchPath:@"/usr/bin/du"];
		[duTool setStandardOutput:fromDu];
		[duTool setArguments:args];
		[duTool launch];
		
        while( [duTool isRunning])
            [NSThread sleepForTimeInterval: 0.1];
        
        //[duTool waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
		
		duOutput = [[fromPipe fileHandleForReading] availableData];
		[duOutput getBytes:aBuffer];
		
		size = [NSString stringWithUTF8String:aBuffer];
		stringComponents = [size pathComponents];
		
		size = [stringComponents objectAtIndex:0];
		size = [size substringToIndex:[size length]-1];
		
		return [NSNumber numberWithUnsignedLongLong:(unsigned long long)[size doubleValue]];
	}
	else return [NSNumber numberWithUnsignedLongLong:(unsigned long long)0];
}

- (IBAction) cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction) ok:(id)sender
{
	[NSApp stopModal];
}

- (NSString*) cleanStringForFile: (NSString*) s
{
	s = [s stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	s = [s stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	
	return s;	
}

- (void) prepareCDContent: (NSMutableArray*) dbObjects :(NSMutableArray*) originalDbObjects
{
    NSThread* thread = [NSThread currentThread];
    
	[finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"" waitUntilDone:YES];
    
	@try
    {
        __block NSInteger selectedCompressionMode;
        dispatch_sync(dispatch_get_main_queue(), ^{
            selectedCompressionMode = [compressionMode selectedTag];
        });
        
        NSEnumerator *enumerator;
        if( anonymizedFiles) enumerator = [anonymizedFiles objectEnumerator];
        else enumerator = [files objectEnumerator];
        
        NSString *file;
        NSString *burnFolder = [self folderToBurn];
        //NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",burnFolder];
        NSString *subFolder = [NSString stringWithFormat:@"%@/DICOM",burnFolder];
        NSFileManager *manager = [NSFileManager defaultManager];
        int i = 0;

        //create burn Folder and dicomdir.
        
        if( ![manager fileExistsAtPath:burnFolder])
            [manager createDirectoryAtPath:burnFolder withIntermediateDirectories:YES attributes:nil error:NULL];
        if( ![manager fileExistsAtPath:subFolder])
            [manager createDirectoryAtPath:subFolder withIntermediateDirectories:YES attributes:nil error:NULL];
        
        /*
        
        FAUZE - 24-Mar-2018: Not clear why the statement below is needed. Causing abortion of thread because DICOMDIR resource not present
         
        if( ![manager fileExistsAtPath:dicomdirPath]);
        [manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"DICOMDIR" ofType:nil] toPath:dicomdirPath error:NULL];
        
        */
            
        NSMutableArray *newFiles = [NSMutableArray array];
        NSMutableArray *compressedArray = [NSMutableArray array];
        NSMutableArray *bigEndianFilesToConvert = [NSMutableArray array];
        
        while((file = [enumerator nextObject]) && cancelled == NO)
        {
            @autoreleasepool {
                NSString *newPath = [NSString stringWithFormat:@"%@/%05d", subFolder, i++];
                
                [manager copyItemAtPath:file toPath:newPath error:NULL];
                
                if( [DicomFile isDICOMFile: newPath])
                {
                    if( [[DicomFile getDicomField: @"TransferSyntaxUID" forFile: newPath] isEqualToString: DCM_ExplicitVRBigEndian])
                       [bigEndianFilesToConvert addObject: newPath];
                    
                    switch(selectedCompressionMode)
                    {
                        case 0:
                        break;
                        
                        case 1:
                            [compressedArray addObject: newPath];
                        break;
                        
                        case 2:
                            [compressedArray addObject: newPath];
                        break;
                    }
                }
                
                [newFiles addObject:newPath];
            }
        }
        
        if( bigEndianFilesToConvert.count)
            [DicomDatabase decompressDicomFilesAtPaths: bigEndianFilesToConvert];
        
        if( [newFiles count] > 0 && cancelled == NO)
        {
            NSArray *copyCompressionSettings = nil;
            NSArray *copyCompressionSettingsLowRes = nil;
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"JPEGinsteadJPEG2000"] && selectedCompressionMode == 1) // Temporarily switch the prefs... ugly....
            {
                copyCompressionSettings = [[NSUserDefaults standardUserDefaults] objectForKey: @"CompressionSettings"];
                copyCompressionSettingsLowRes = [[NSUserDefaults standardUserDefaults] objectForKey: @"CompressionSettingsLowRes"];
                
                [[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", [NSNumber numberWithInt: compression_JPEG], @"compression", @"0", @"quality", nil]] forKey: @"CompressionSettings"];
                
                [[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", [NSNumber numberWithInt: compression_JPEG], @"compression", @"0", @"quality", nil]] forKey: @"CompressionSettingsLowRes"];
                
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            @try
            {

                
                
                switch(selectedCompressionMode)
                {
                    case 1:
                        [[[BrowserController currentBrowser] database] processFilesAtPaths:compressedArray intoDirAtPath:nil mode:Compress];
                    break;
                    
                    case 2:
                        [[[BrowserController currentBrowser] database] processFilesAtPaths:compressedArray intoDirAtPath:nil mode:Decompress];
                        break;
                }
            }
            @catch (NSException *e) {
                NSLog(@"Exception while prepareCDContent compression: %@", e);
            }
            
            if( copyCompressionSettings && copyCompressionSettingsLowRes)
            {
                [[NSUserDefaults standardUserDefaults] setObject: copyCompressionSettings forKey:@"CompressionSettings"];
                [[NSUserDefaults standardUserDefaults] setObject: copyCompressionSettingsLowRes forKey:@"CompressionSettingsLowRes"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            thread.name = NSLocalizedString( @"Burning...", nil);
            thread.status = NSLocalizedString( @"Writing DICOMDIR...", nil);
            [self addDICOMDIRUsingDCMTK_forFilesAtPaths:newFiles dicomImages:dbObjects];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnWeasis"] && cancelled == NO)
            {
                thread.name = NSLocalizedString( @"Burning...", nil);
                thread.status = NSLocalizedString( @"Adding Weasis...", nil);
                
                NSString* weasisPath = [[AppController sharedAppController] weasisBasePath];
                for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:weasisPath error:NULL])
                    [[NSFileManager defaultManager] copyItemAtPath:[weasisPath stringByAppendingPathComponent:subpath] toPath:[burnFolder stringByAppendingPathComponent:subpath] error:NULL];
                
                NSString *burnWeasisPath = [burnFolder stringByAppendingPathComponent:@"weasis"];
                NSArray *skips = @[ @".DS_Store" ];
                for (NSString *weasisPath in [[Horos WeasisCustomizationPaths] reverseObjectEnumerator]) { // reversed to mimic the WebPortal priorities
                    NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath:weasisPath];
                    for (NSString *subpath in de)
                        if (![skips containsObject:subpath.lastPathComponent]) {
                            NSString *dest = [burnWeasisPath stringByAppendingPathComponent:subpath];
                            if ([de.fileAttributes[NSFileType] isEqual:NSFileTypeDirectory]) {
                                [[NSFileManager defaultManager] createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
                            } else {
                                if ([[NSFileManager defaultManager] fileExistsAtPath:dest])
                                    [[NSFileManager defaultManager] removeItemAtPath:dest error:NULL];
                                [[NSFileManager defaultManager] copyItemAtPath:[weasisPath stringByAppendingPathComponent:subpath] toPath:dest error:NULL];
                            }
                        }
                }
                
                // Change Label in Autorun.inf
                NSStringEncoding encoding;
                NSString *autorunInf = [NSString stringWithContentsOfFile: [burnFolder stringByAppendingPathComponent: @"Autorun.inf"] usedEncoding: &encoding error: nil];
                
                if( autorunInf.length)
                {
                    autorunInf = [autorunInf stringByReplacingOccurrencesOfString: @"Label=Weasis" withString: [NSString stringWithFormat: @"Label=%@", cdName]];
                    
                    [[NSFileManager defaultManager] removeItemAtPath: [burnFolder stringByAppendingPathComponent: @"Autorun.inf"] error: nil];
                    [autorunInf writeToFile: [burnFolder stringByAppendingPathComponent: @"Autorun.inf"] atomically: YES encoding: encoding  error: nil];
                }
            }
            
            /*
             
            FAUZE - 24-Mar-2018 - Light viewer does not exist.
             
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnOsirixApplication"] && cancelled == NO)
            {
                thread.name = NSLocalizedString( @"Burning...", nil);
                thread.status = NSLocalizedString( @"Adding Horos Lite...", nil);
                // unzip the file
                NSTask *unzipTask = [[NSTask alloc] init];
                [unzipTask setLaunchPath: @"/usr/bin/unzip"];
                [unzipTask setCurrentDirectoryPath: burnFolder];
                [unzipTask setArguments: [NSArray arrayWithObjects: @"-o", [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Horos Launcher.zip"], nil]]; // -o to override existing report w/ same name
                [unzipTask launch];
                
                while( [unzipTask isRunning])
                    [NSThread sleepForTimeInterval: 0.1];
                
                //[unzipTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                
                [unzipTask release];
            }
            */
            
            if(  [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnHtml"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"] == NO && cancelled == NO)
            {
                thread.name = NSLocalizedString( @"Burning...", nil);
                thread.status = NSLocalizedString( @"Adding HTML pages...", nil);
                [self produceHtml: burnFolder dicomObjects: originalDbObjects];
            }
            
            if( [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"].length <= 1)
                [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
            
            if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"] stringByExpandingTildeInPath]] == NO)
                [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnSupplementaryFolder"] && cancelled == NO)
            {
                thread.name = NSLocalizedString( @"Burning...", nil);
                thread.status = NSLocalizedString( @"Adding Supplementary folder...", nil);
                NSString *supplementaryBurnPath = [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"];
                if( supplementaryBurnPath)
                {
                    supplementaryBurnPath = [supplementaryBurnPath stringByExpandingTildeInPath];
                    if( [manager fileExistsAtPath: supplementaryBurnPath])
                    {
                        NSEnumerator *enumerator = [manager enumeratorAtPath: supplementaryBurnPath];
                        while (file=[enumerator nextObject])
                        {
                            [manager copyItemAtPath: [NSString stringWithFormat:@"%@/%@", supplementaryBurnPath,file] toPath: [NSString stringWithFormat:@"%@/%@", burnFolder,file] error:NULL];
                        }
                    }
                    else [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
                }
            }
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"copyReportsToCD"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"] == NO && cancelled == NO)
            {
                thread.name = NSLocalizedString( @"Burning...", nil);
                thread.status = NSLocalizedString( @"Adding Reports...", nil);
                
                NSMutableArray *studies = [NSMutableArray array];
                
                for( NSManagedObject *im in dbObjects)
                {
                    if( [im valueForKeyPath:@"series.study.reportURL"])
                    {
                        if( [studies containsObject: [im valueForKeyPath:@"series.study"]] == NO)
                            [studies addObject: [im valueForKeyPath:@"series.study"]];
                    }
                }
                
                for( DicomStudy *study in studies)
                {
                    if( [[study valueForKey: @"reportURL"] hasPrefix: @"http://"] || [[study valueForKey: @"reportURL"] hasPrefix: @"https://"])
                    {
                        NSStringEncoding enc;
                        NSString *urlContent = [NSString stringWithContentsOfURL: [NSURL URLWithString: [study valueForKey: @"reportURL"]] usedEncoding:&enc error:NULL];
                        
                        [urlContent writeToFile: [NSString stringWithFormat:@"%@/Report-%@ %@.%@", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]], [self cleanStringForFile: [[study valueForKey:@"reportURL"] pathExtension]]] atomically: YES encoding:enc error:NULL];
                    }
                    else
                    {
                        // Convert to PDF
                        
                        NSString *pdfPath = [study saveReportAsPdfInTmp];
                        
                        if( [manager fileExistsAtPath: pdfPath] == NO)
                            [manager copyItemAtPath: [study valueForKey:@"reportURL"] toPath: [NSString stringWithFormat:@"%@/Report-%@ %@.%@", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]], [self cleanStringForFile: [[study valueForKey:@"reportURL"] pathExtension]]] error:NULL];
                        else
                            [manager copyItemAtPath: pdfPath toPath: [NSString stringWithFormat:@"%@/Report-%@ %@.pdf", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]]] error:NULL];
                    }
                    
                    if( cancelled)
                        break;
                }
            }
        }
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"EncryptCD"] && cancelled == NO)
        {
            if( cancelled == NO)
            {
                thread.name = NSLocalizedString( @"Burning...", nil);
                thread.status = NSLocalizedString( @"Encrypting...", nil);
                
                // ZIP method - zip test.zip /testFolder -r -e -P hello
                
                [BrowserController encryptFileOrFolder: burnFolder inZIPFile: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.zip"] password: self.password];
                self.password = @"";
                
                [[NSFileManager defaultManager] removeItemAtPath: burnFolder error: nil];
                [[NSFileManager defaultManager] createDirectoryAtPath: burnFolder withIntermediateDirectories:YES attributes:nil error:NULL];
                
                [[NSFileManager defaultManager] moveItemAtPath: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.zip"] toPath: [burnFolder stringByAppendingPathComponent: @"encryptedDICOM.zip"] error: nil];
                [[NSString stringWithString: NSLocalizedString( @"The images are encrypted with a password in this ZIP file: first, unzip this file to read the content. Use an Unzip application to extract the files.", nil)] writeToFile: [burnFolder stringByAppendingPathComponent: @"ReadMe.txt"] atomically: YES encoding: NSASCIIStringEncoding error: nil];
            }
        }
        
        thread.name = NSLocalizedString( @"Burning...", nil);
        thread.status = [NSString stringWithFormat: NSLocalizedString( @"Writing %3.2fMB...", nil), (float) ([[self getSizeOfDirectory: burnFolder] longLongValue] / 1024)];
        
        [finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat: NSLocalizedString (@"Final files size to burn: %3.2fMB", nil), (float) ([[self getSizeOfDirectory: burnFolder] longLongValue] / 1024)] waitUntilDone:YES];
    }
    @catch( NSException * e)
    {
        N2LogException( e);
    }
}

- (IBAction) estimateFolderSize: (id) sender
{
	NSString				*file;
	long					size = 0;
	NSFileManager			*manager = [NSFileManager defaultManager];
	NSDictionary			*fattrs;
	
	for (file in files)
	{
		fattrs = [manager attributesOfItemAtPath:file error:NULL];
		size += [fattrs fileSize]/1024;
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnWeasis"])
	{
		size += 17 * 1024; // About 17MB
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnOsirixApplication"])
	{
		size += 8 * 1024; // About 8MB
	}
	
    if( [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"].length <= 1)
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"] stringByExpandingTildeInPath]] == NO)
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
    
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnSupplementaryFolder"])
	{
		size += [[self getSizeOfDirectory: [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"]] longLongValue];
	}
	
	[sizeField setStringValue:[NSString stringWithFormat:@"%@ %d  %@ %3.2fMB", NSLocalizedString(@"No of files:", nil), (int) [files count], NSLocalizedString(@"Files size (without compression):", nil), size/1024.0]];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (void)burnAnimation:(NSTimer *)timer
{
	if( windowWillClose)
		return;
	
    if( runBurnAnimation == NO)
        return;
    
    if( burnAnimationIndex > 11)
        burnAnimationIndex = 0;
    
    NSString *animation = [NSString stringWithFormat:@"burn_anim%02d.tif", burnAnimationIndex++];
    NSImage *image = [NSImage imageNamed: animation];
    [burnButton setImage:image];
}

-(void)irisAnimation:(NSTimer*) timer
{
    if( runBurnAnimation)
        return;
    
	if( irisAnimationIndex > 17)
        irisAnimationIndex = 0;
    
    NSString *animation = [NSString stringWithFormat:@"burn_iris%02d.tif", irisAnimationIndex++];
    NSImage *image = [NSImage imageNamed: animation];
    [burnButton setImage:image];
}
@end
