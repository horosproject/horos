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

/***************************************** Modifications *********************************************

Version 2.3
	20060109	LP	Testing using dcmtk tool dcmgpdir for creating DICOMDIR
	20060116	LP	Fixed bug in assigning image paths using dcmtk dcmmkdir
	
*****************************************************************************************************/




#import "BurnerWindowController.h"
#import <OsiriX/DCM.h>
#import <DiscRecordingUI/DiscRecordingUI.h>
#import <DiscRecordingUI/DRSetupPanel.h>
#import "MutableArrayCategory.h"

#import  "BrowserController.h"

extern BrowserController  *browserWindow;

NSString* asciiString (NSString* name);

@implementation BurnerWindowController

-(id) initWithFiles:(NSArray *)theFiles
{
    if (self = [super initWithWindowNibName:@"BurnViewer"]) {
		
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		files = [theFiles retain];
		burning = NO;
		
		[[self window] center];
	}
	return self;
}

- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects releaseAfterBurn:(BOOL)releaseAfterBurn{
	if (self = [super initWithWindowNibName:@"BurnViewer"])
	{
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		files = [theFiles retain];
		dbObjects = [managedObjects retain];
		NSEnumerator *enumerator = [managedObjects objectEnumerator];
		id managedObject;
		id patient = nil;
		_multiplePatients = NO;
		while (managedObject = [enumerator nextObject]){
			id newPatient = [managedObject valueForKeyPath:@"series.study.patientUID"];
			
			if (patient == nil)
				patient = newPatient;
			else if (![patient isEqualToString:newPatient]) {
				_multiplePatients = YES;
				break;
			}
			patient = newPatient;
		}
		burning = NO;
		
		[[self window] center];
	}
	return self;
}

- (void)windowDidLoad{	
	NSLog(@"BurnViewer did load");
	
	[[self window] setDelegate:self];
	[self setup:nil];
	
	[compressionMode selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"Compression Mode for Burning"]];
}

- (void)dealloc
{
	runBurnAnimation = NO;
	
	[filesToBurn release];
	[dbObjects release];
	//NSLog(@"Burner dealloc");	
	[super dealloc];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (NSArray *)filesToBurn{
	return filesToBurn;
}

- (void)setFilesToBurn:(NSArray *)theFiles{
	[filesToBurn release];
	//filesToBurn = [self extractFileNames:theFiles];
	filesToBurn = [theFiles retain];
	//[filesTableView reloadData];
}

- (void)setIsBurning: (BOOL)value{
	burning = value;
}
- (BOOL)isBurning{
	return burning;
}



- (NSArray *)extractFileNames:(NSArray *)filenames{
    NSEnumerator *enumerator;
    NSString *pname;
    NSString *fname;
    NSString *pathName;
    BOOL isDir;

    NSMutableArray *fileNames = [[[NSMutableArray alloc] init] autorelease];
    enumerator = [filenames objectEnumerator];
	//NSLog(@"Extract");
    while (fname = [enumerator nextObject]){ 
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//NSLog(@"fname %@", fname);
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:fname isDirectory:&isDir] && isDir) {
            NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:fname];
            //Loop Through directories
            while (pname = [direnum nextObject]) {
                pathName = [fname stringByAppendingPathComponent:pname]; //make pathanme
                if ([manager fileExistsAtPath:pathName isDirectory:&isDir] && !isDir) { //check for directory
					if ([DCMObject objectWithContentsOfFile:pathName decodingPixelData:NO]){
                        [fileNames addObject:pathName];
					}
                }
            } //while pname
                
        } //if
        //else if ([dicomDecoder dicomCheckForFile:fname] > 0) {
		else if ([DCMObject objectWithContentsOfFile:fname decodingPixelData:NO]) {	//Pathname
				[fileNames addObject:fname];
        }
		[pool release];
    } //while
    return fileNames;
}

//Actions
-(IBAction)burn:(id)sender
{
	if (!(isExtracting || isSettingUpBurn || burning))
	{
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		cdName = [[nameField stringValue] retain];
		
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		if (cdName != nil) {
			runBurnAnimation = YES;
			[NSThread detachNewThreadSelector:@selector(burnAnimation:) toTarget:self withObject:nil];
			[NSThread detachNewThreadSelector:@selector(performBurn:) toTarget:self withObject:nil];
		}
		else
			NSBeginAlertSheet(@"Burn Warning" , @"OK", nil, nil, nil, nil, nil, nil, nil,@"Please add CD name");
	}
}

- (void)performBurn: (id) object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	isSettingUpBurn = YES;
	[self addDicomdir];
	isSettingUpBurn = NO;

	[self performSelectorOnMainThread:@selector(burnCD:) withObject:nil waitUntilDone:YES];
	[statusField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"" waitUntilDone:YES];
	[pool release];
}

- (void)setCDTitle: (NSString *)title{
	if (title) {
		[cdName release];
		//if ([title length] > 8)
		//	title = [title substringToIndex:8];
		cdName = [asciiString(title) retain];
		[nameField setStringValue: cdName];
	}
}

-(IBAction)setCDName:(id)sender{	
	NSString *name = [[nameField stringValue] uppercaseString];
	[self setCDTitle:name];
	NSLog(cdName);
}

-(NSString *)folderToBurn{
	return [NSString stringWithFormat:@"/tmp/%@",cdName];
}

- (void)burnCD:(id)object{

	DRTrack*	track = [self createTrack];

	if (track){
		DRBurnSetupPanel*	bsp = [DRBurnSetupPanel setupPanel];

		// We'll be the delegate for the setup panel. This allows us to show off some 
		// of the customization you can do.
		[bsp setDelegate:self];
		
		if ([bsp runSetupPanel] == NSOKButton)
		{
			DRBurnProgressPanel*	bpp = [DRBurnProgressPanel progressPanel];

			[bpp setDelegate:self];

			// And start off the burn itself. This will put up the progress dialog 
			// and do all the nice pretty things that a happy app does.
			[bpp beginProgressPanelForBurn:[bsp burnObject] layout:track];
			
			// If you wanted to run this as a sheet you would have sent
			 // [bpp beginProgressSheetForBurn:[bsp burnObject] layout:tracks modalForWindow:aWindow];
			//
		}
		else
			runBurnAnimation = NO;
	}
}


- (DRTrack *) createTrack{
	DRFolder* rootFolder = [DRFolder folderWithPath:[self folderToBurn]];		
	return [DRTrack trackForRootFolder:rootFolder];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (BOOL) validateMenuItem:(id)sender{

	if ([sender action] == @selector(terminate:))
		return (burning == NO);		// No quitting while a burn is going on

	return YES;
}


//#pragma mark Setup Panel Delegate Methods
/* We're implementing some of these setup panel delegate methods to illustrate what you could do to control a
	burn setup. */
	

/* This delegate method is called when a device is plugged in and becomes available for use. It's also
	called for each device connected to the machine when the panel is first shown. 
	
	Its's possible to query the device and ask it just about anything to determine if it's a device
	that should be used.
	
	Just return YES for a device you want and NO for those you don't. */
	
/*
- (BOOL) setupPanel:(DRSetupPanel*)aPanel deviceCouldBeTarget:(DRDevice*)device
{

#if 0
	// This bit of code shows how to filter devices bases on the properties of the device
	// For example, it's possible to limit the drives displayed to only those hooked up over
	// firewire, or converesely, you could NOT show drives if there was some reason to. 
	NSDictionary*	deviceInfo = [device info];
	if ([[deviceStatus objectForKey:DRDevicePhysicalInterconnectKey] isEqualToString:DRDevicePhysicalInterconnectFireWire])
		return YES;
	else
		return NO;
#else
	return YES;
#endif

}
 */ 
 
/*" This delegate method is called whenever the state of the media changes. This includes
	not only inserting and ejecting media, but also if some other app grabs the reservation,
	starts using it, etc.
	
	When we get sent this we're going to do a little bit of work to try to play nice with
	the rest of the world, but it essentially comes down to "is it a CDR or CDRW" that we
	care about. We could also check to see if there's enough room for our data (maybe the
	user stuck in a mini 2" CD or we need an 80 min CD).
	
	allows the delegate to determine if the media inserted in the 
	device is suitable for whatever operation is to be performed. The delegate should
	return a string to be used in the setup panel to inform the user of the 
	media status. If this method returns %NO, the default button will be disabled.
"*/

- (BOOL) setupPanel:(DRSetupPanel*)aPanel mediaIsSuitable:(NSDictionary*)status promptString:(NSString**)prompt
{

//	NSDictionary *burnerCapbilites = [status DRDeviceWriteCapabilitiesKey];
//	NSString*		mediaType;
//	// check to see what sort of media there is present in the drive. If it's not a 
//	// CDR or CDRW we reject it. This prevents us from burning to a DVD.
//	mediaType = [[status objectForKey:DRDeviceMediaInfoKey] objectForKey:DRDeviceMediaTypeKey];
//	if ([mediaType isEqualToString:DRDeviceMediaTypeCDR] == NO && [mediaType isEqualToString:DRDeviceMediaTypeCDRW] == NO)
//	{
//		if ([mediaType isEqualToString:DRDeviceMediaTypeDVDRW] == YES || [mediaType isEqualToString:DRDeviceMediaTypeDVD] == YES) {
//			if ([[burnerCapbilites DRDeviceCanTestWriteDVDKey] boolValue]) {
//				NSLog(@"Can burn DVD");
//				return YES;
//		}
//		else {
//			*prompt = [NSString stringWithCString:"That's not a writable CD!"];
//			return NO;
//		}
//	}
//	
//	// OK everyone agrees that this disc is OK to be burned in this drive.
//	// We could also return our own OK, prompt string here, but we'll let the default 
//	// all ready string do it's job
//	// *prompt = [NSString stringWithCString:"Let's roll!"];

	return YES;

}

//#pragma mark Progress Panel Delegate Methods

/* Here we are setting up this nice little instance variable that prevents the app from
	quitting while a burn is in progress. This gets checked up in validateMenu: and we'll
	set it to NO in burnProgressPanelDidFinish: */
	
	
- (void) burnProgressPanelWillBegin:(NSNotification*)aNotification
{

	burning = YES;	// Keep the app from being quit from underneath the burn.
	isThrobbing = NO;
	burnAnimationIndex = 0;
	[statusField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"Burning" waitUntilDone:YES];

}

- (void) burnProgressPanelDidFinish:(NSNotification*)aNotification
{
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager removeFileAtPath:[self folderToBurn] handler:nil];
	burning = NO;	// OK we can quit now.
	runBurnAnimation = NO;
}



/* OK, nothing fancy here. we just want to illustrate that it's possible for a delegate of the 
	progress panel to alter how the burn is handled once it completes. You may want to put up
	your own dialog, sent a notification if you're in the background, or just ignore it no matter what.
	
	We'll just NSLog the fact it finished (for good or bad) and return YES to indicate
	that we didn't handle it ourselves and that the progress panel should continue on its
	merry way. */
	
	
- (BOOL) burnProgressPanel:(DRBurnProgressPanel*)theBurnPanel burnDidFinish:(DRBurn*)burn
{
	NSDictionary*	burnStatus = [burn status];
	NSString*		state = [burnStatus objectForKey:DRStatusStateKey];
	
	if ([state isEqualToString:DRStatusStateFailed])
	{
		NSDictionary*	errorStatus = [burnStatus objectForKey:DRErrorStatusKey];
		NSString*		errorString = [errorStatus objectForKey:DRErrorStatusErrorStringKey];
		
		NSLog(@"The burn failed (%@)!", errorString);
	}
	else
		NSLog(@"Burn finished fine");
	burning=NO;
	[[self window] performClose:nil];
	//[[NSApplication sharedApplication] terminate: self];
	return YES;
}


- (void)windowWillClose:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setInteger: [compressionMode selectedTag] forKey:@"Compression Mode for Burning"];
	
	[browserWindow setBurnerWindowControllerToNIL];
	NSLog(@"Burner windowWillClose");
	
	[self release];
}

- (BOOL)windowShouldClose:(id)sender
{
	NSLog(@"Burner windowShouldClose");
	
	if ((isExtracting || isSettingUpBurn || burning))
		return NO;
	else {
		NSFileManager *manager = [NSFileManager defaultManager];
		[manager removeFileAtPath:[self folderToBurn] handler:nil];
		[filesToBurn release];
		filesToBurn = nil;
		[files release];
		files = nil;
		//[filesTableView reloadData];
		
		NSLog(@"Burner windowShouldClose YES");
		
		return YES;
	}
}




//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (BOOL)dicomCheck:(NSString *)filename{
	//DicomDecoder *dicomDecoder = [[[DicomDecoder alloc] init] autorelease];
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:filename decodingPixelData:NO];
	return (dcmObject) ? YES : NO;
}

- (void)importFiles:(NSArray *)filenames{
}

- (void)setup:(id)sender{
	//NSLog(@"Set up burn");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	isThrobbing = NO;
	runBurnAnimation = NO;
	[burnButton setEnabled:NO];
	isExtracting = YES;

//	[filesTableView reloadData];

	[self performSelectorOnMainThread:@selector(estimateFolderSize:) withObject:nil waitUntilDone:YES];
	[statusField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"" waitUntilDone:YES];
	isExtracting = NO;
	[NSThread detachNewThreadSelector:@selector(irisAnimation:) toTarget:self withObject:nil];
	[burnButton setEnabled:YES];
	NSString *title;
	if ([files count] > 0) {
		if (_multiplePatients){
			NSDate *date = [NSDate date];
			title = [NSString stringWithFormat:@"Archive-%@",  [date descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil 
    locale:nil]] ;
		}
		else{
			NSString *file = [files objectAtIndex:0];
			DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
			title = [dcmObject attributeValueWithName:@"PatientsName"];		
		}
	}
	else title = @"no name";
	[self setCDTitle:[title uppercaseString]];
	[pool release];

	
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (void)addDICOMDIRUsingDCMTK{
	NSString *burnFolder = [self folderToBurn];
	NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",burnFolder];
	NSString *subFolder = [NSString stringWithFormat:@"%@/IMAGES",burnFolder];
	
	NSTask              *theTask;
	//NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-W", @"-Nxc", @"*", nil];
	NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc",@"+id", burnFolder,  nil];
	//NSLog(@"burn args: %@", [theArguments description]);
	theTask = [[NSTask alloc] init];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];	// DO NOT REMOVE !
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dcmmkdir"]];
	[theTask setCurrentDirectoryPath:[self folderToBurn]];
	[theTask setArguments:theArguments];		

	[theTask launch];
	[theTask waitUntilExit];
	[theTask release];
}

- (void) produceHtml:(NSString*) burnFolder
{
	[[BrowserController currentBrowser] exportQuicktimeInt:dbObjects :burnFolder :YES];
}

- (void)addDicomdir{
	//NSLog(@"add Dicomdir");
	NS_DURING
	NSEnumerator *enumerator = [files objectEnumerator];
	NSString *file;
	NSString *burnFolder = [self folderToBurn];
	NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",burnFolder];
	NSString *subFolder = [NSString stringWithFormat:@"%@/IMAGES",burnFolder];
	NSFileManager *manager = [NSFileManager defaultManager];
	int i = 0;

//create burn Folder and dicomdir.
	
	if (![manager fileExistsAtPath:burnFolder])
		[manager createDirectoryAtPath:burnFolder attributes:nil];
	if (![manager fileExistsAtPath:subFolder])
		[manager createDirectoryAtPath:subFolder attributes:nil];
	if (![manager fileExistsAtPath:dicomdirPath])
		[manager copyPath:[[NSBundle mainBundle] pathForResource:@"DICOMDIR" ofType:nil] toPath:dicomdirPath handler:nil];
		
	NSMutableArray *newFiles = [NSMutableArray array];
	while (file = [enumerator nextObject]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *newPath = [NSString stringWithFormat:@"%@/%05d", subFolder, i++];
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
		//Don't want Big Endian, May not be readable
		if ([[dcmObject transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
			[dcmObject writeToFile:newPath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
		else
			[manager copyPath:file toPath:newPath handler:nil];
			
		if( dcmObject)	// <- it's a DICOM file
		{
			switch( [compressionMode selectedTag])
			{
				case 0:
				break;
				
				case 1:
					[browserWindow compressDICOMJPEG: [newPath retain]];
				break;
				
				case 2:
					[browserWindow decompressDICOMJPEG: [newPath retain]];
				break;
			}
		}
		
		[statusField performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:@"Copying: %@", [newPath lastPathComponent]] waitUntilDone:YES];
		[newFiles addObject:newPath];
		[pool release];
	}
	[statusField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"Creating DICOMDIR" waitUntilDone:YES];
	[self addDICOMDIRUsingDCMTK];
	int size = 400;
	
// Both these supplementary burn data are optional and controlled from a preference panel [DDP]
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Burn Osirix Application"])
	{
		NSString *iRadPath = [[NSBundle mainBundle] bundlePath];
		[statusField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"Writing Osirix application" waitUntilDone:YES];
		[manager copyPath:iRadPath toPath: [NSString stringWithFormat:@"%@/Osirix.app",burnFolder] handler:nil];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Burn html"])
	{
		[self performSelectorOnMainThread:@selector(produceHtml:) withObject:burnFolder waitUntilDone:YES];
	}
		
// Look for and if present copy a second folder for eg windows viewer or html files.

	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Burn Supplementary Folder"])
	{
		NSString *supplementaryBurnPath=[[NSUserDefaults standardUserDefaults] stringForKey: @"Supplementary Burn Path"];
		if (supplementaryBurnPath)
		{
			supplementaryBurnPath=[supplementaryBurnPath stringByExpandingTildeInPath];
			if ([manager fileExistsAtPath: supplementaryBurnPath])
			{
				[statusField performSelectorOnMainThread: @selector(setStringValue:) withObject:@"Writing extra files" waitUntilDone:YES];
				NSEnumerator *enumerator=[manager enumeratorAtPath: supplementaryBurnPath];
				while (file=[enumerator nextObject])
				{
					[manager copyPath: [NSString stringWithFormat:@"%@/%@", supplementaryBurnPath,file]
					  toPath: [NSString stringWithFormat:@"%@/%@", burnFolder,file] handler:nil]; 
				}
			}
		}
	}
	NS_HANDLER
		NSLog(@"Exception while creating DICOMDIR: %@", [localException name]);
	NS_ENDHANDLER
}


- (void)estimateFolderSize: (id) object {
	NSEnumerator			*enumerator = [files objectEnumerator];
	NSString				*file;
	long					size = 0;
	NSFileManager			*manager = [NSFileManager defaultManager];
	NSDictionary			*fattrs;
	while (file = [enumerator nextObject]){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		fattrs = [manager fileAttributesAtPath:file traverseLink:YES];
		size += [fattrs fileSize]/1024;
		[pool release];
	}
	size += 44400000/1024;			// fixed size of OsiriX, should be calculated to allow for changes.
	[sizeField setStringValue:[NSString stringWithFormat:@"%@ %d %@ %3.2fMB", NSLocalizedString(@"Files:", nil), [files count], NSLocalizedString(@"Estimated size (uncompressed):", nil), size/1024.0]];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (void)burnAnimation:(NSTimer *)timer{
	isThrobbing = NO;
	while (runBurnAnimation) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *animation = [NSString stringWithFormat:@"burn_anim%02d", burnAnimationIndex++];
		NSString *path = [[NSBundle mainBundle] pathForResource:animation ofType:@"tif"];
		NSImage *image = [ [[NSImage alloc]  initWithContentsOfFile:path] autorelease];
		[burnButton setImage:image];
		if (burnAnimationIndex > 11)
			burnAnimationIndex = 0;
		
		[NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
		[pool release];
	}
	
}

-(void)irisAnimation:(id)object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int index = 0;
	while (index <= 13) {
		NSString *animation = [NSString stringWithFormat:@"burn_iris%02d", index++];
		NSString *path = [[NSBundle mainBundle] pathForResource:animation ofType:@"tif"];
		NSImage *image = [ [[NSImage alloc]  initWithContentsOfFile:path] autorelease];
		[burnButton setImage:image];
		[NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.075]];		
	}
	[NSThread detachNewThreadSelector:@selector(throbAnimation:) toTarget:self withObject:nil];
	[pool release];
}

- (void)throbAnimation:(id)object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	isThrobbing = YES;
	while (isThrobbing) {
		NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
		NSString *path1 = [[NSBundle mainBundle] pathForResource:@"burn_anim00" ofType:@"tif"];
		NSImage *image = [ [[NSImage alloc]  initWithContentsOfFile:path1] autorelease];
		[burnButton setImage:image];
		[NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
		NSString *path2 = [[NSBundle mainBundle] pathForResource:@"burn_throb" ofType:@"tif"];
		NSImage *image2 = [[[NSImage alloc]  initWithContentsOfFile:path2] autorelease];
		
		[burnButton setImage:image2];
		[NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
		[subpool release];
	}
	[pool release];
}

/*
- (void)reloadData:(id)object{
	[filesTableView reloadData];
}
*/



@end
