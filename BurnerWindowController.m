/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "AppController.h"
#import "WaitRendering.h"
#import "BurnerWindowController.h"
#import <OsiriX/DCM.h>
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

@implementation BurnerWindowController
@synthesize password, buttonsDisabled;

- (void) createDMG:(NSString*) imagePath withSource:(NSString*) directoryPath
{
	NSFileManager *manager = [NSFileManager defaultManager];
	
	[manager removeFileAtPath:imagePath handler:nil];
	
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
	[makeImageTask waitUntilExit];
}

- (void)writeDMG:(id)object
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setRequiredFileType:@"dmg"];
	[savePanel setTitle:@"Save as DMG"];
	
	if( [savePanel runModalForDirectory:nil file: [[self folderToBurn] lastPathComponent]] == NSFileHandlingPanelOKButton)
	{
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Writing DMG file...", nil)];
		[wait showWindow:self];
		        
		@try
		{
			[self createDMG:[[savePanel URL] path] withSource:[self folderToBurn]];
		}
		@catch (NSException * e)
		{
			NSLog( @"******** exception during writeDMG: %@", e);
		}
		
		[wait close];
		[wait release];
	}
	
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager removeFileAtPath:[self folderToBurn] handler:nil];
	
	self.buttonsDisabled = NO;
}

- (void) copyDefaultsSettings
{
	burnSuppFolder = [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnSupplementaryFolder"];
	burnOsiriX = [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnOsirixApplication"];
	burnHtml = [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnHtml"];
	burnWeasis = [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnWeasis"];;
}

- (void) restoreDefaultsSettings
{
	[[NSUserDefaults standardUserDefaults] setBool: burnSuppFolder forKey:@"BurnSupplementaryFolder"];
	[[NSUserDefaults standardUserDefaults] setBool: burnOsiriX forKey:@"BurnOsirixApplication"];
	[[NSUserDefaults standardUserDefaults] setBool: burnHtml forKey:@"BurnHtml"];
	[[NSUserDefaults standardUserDefaults] setBool: burnWeasis forKey:@"BurnWeasis"];
}

-(id) initWithFiles:(NSArray *)theFiles
{
    if (self = [super initWithWindowNibName:@"BurnViewer"]) {
		
		[self copyDefaultsSettings];
		
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		files = [theFiles mutableCopy];
		burning = NO;
		
		[[self window] center];
		
		NSLog( @"Burner allocated");
	}
	return self;
}

- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects
{
	if (self = [super initWithWindowNibName:@"BurnViewer"])
	{
		[self copyDefaultsSettings];
		
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
        idatabase = [[[DicomDatabase databaseForContext:[[managedObjects objectAtIndex:0] managedObjectContext]] independentDatabase] retain];
        
		files = [theFiles mutableCopy]; // file paths
		dbObjects = [[idatabase objectsWithIDs:managedObjects] mutableCopy]; // managedObjects in idatabase
		originalDbObjects = [dbObjects mutableCopy];
		
		[files removeDuplicatedStringsInSyncWithThisArray: dbObjects];
		
		id managedObject;
		id patient = nil;
		_multiplePatients = NO;
		
		[idatabase lock];
		
		for (managedObject in dbObjects)
		{
			id newPatient = [managedObject valueForKeyPath:@"series.study.patientUID"];
			
			if (patient == nil)
				patient = newPatient;
			else if (![patient isEqualToString:newPatient])
			{
				_multiplePatients = YES;
				break;
			}
			patient = newPatient;
		}
		
		[idatabase unlock];
		
		burning = NO;
		
		[[self window] center];
		
		NSLog( @"Burner allocated");
	}
	return self;
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
		
	[anonymizedFiles release];
	[filesToBurn release];
	[dbObjects release];
	[originalDbObjects release];
	[cdName release];
	[password release];
    
    [idatabase release];
	
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
        if ([manager fileExistsAtPath:fname isDirectory:&isDir] && isDir)
		{
            NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:fname];
            //Loop Through directories
            while (pname = [direnum nextObject])
			{
                pathName = [fname stringByAppendingPathComponent:pname]; //make pathanme
                if ([manager fileExistsAtPath:pathName isDirectory:&isDir] && !isDir)
				{ //check for directory
					if ([DCMObject objectWithContentsOfFile:pathName decodingPixelData:NO])
					{
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
-(IBAction) burn: (id)sender
{
	if (!(isExtracting || isSettingUpBurn || burning))
	{
		[sizeField setStringValue: @""];
		
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		[cdName release];
		cdName = [[nameField stringValue] retain];
		
		if( [cdName length] <= 0)
		{
			[cdName release];
			cdName = [[NSString stringWithString: @"UNTITLED"] retain];
		}
		
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		[[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithFormat:@"/tmp/burnAnonymized"] handler:nil];
		
		writeDMG = NO;
		if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) writeDMG = YES;
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"saveAsDMGFile"]) writeDMG = YES;
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"])
		{
			AnonymizationPanelController* panelController = [Anonymization showPanelForDefaultsKey:@"AnonymizationFields" modalForWindow:self.window modalDelegate:NULL didEndSelector:NULL representedObject:NULL];
			
			if (panelController.end == AnonymizationPanelCancel)
				return;
			
			NSDictionary* anonOut = [Anonymization anonymizeFiles:files dicomImages: dbObjects toPath:@"/tmp/burnAnonymized" withTags:panelController.anonymizationViewController.tagsValues];
			
			[anonymizedFiles release];
			anonymizedFiles = [[anonOut allValues] mutableCopy];
		}
		else
		{
			[anonymizedFiles release];
			anonymizedFiles = nil;
		}
		
		self.buttonsDisabled = YES;
		
		if (cdName != nil && [cdName length] > 0)
		{
			runBurnAnimation = YES;
            
			NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( performBurn:) object: nil] autorelease];
			t.name = NSLocalizedString( @"Burning...", nil);
			[[ThreadsManager defaultManager] addThreadAndStart: t];
		}
		else
			NSBeginAlertSheet( NSLocalizedString( @"Burn Warning", nil) , NSLocalizedString( @"OK", nil), nil, nil, nil, nil, nil, nil, nil, NSLocalizedString( @"Please add CD name", nil));
	}
}

- (void)performBurn: (id) object
{	 
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	isSettingUpBurn = YES;
	
	[self addDicomdir];
	
	isSettingUpBurn = NO;
	
	int no = 0;
		
	if( anonymizedFiles) no = [anonymizedFiles count];
	else no = [files count];
		
	if( [[NSFileManager defaultManager] fileExistsAtPath: [self folderToBurn]])
	{
		if( no)
		{
			if( writeDMG)
            {
                [self performSelectorOnMainThread:@selector( writeDMG:) withObject:nil waitUntilDone:YES];
                runBurnAnimation = NO;
            }
			else
            {
                [self performSelectorOnMainThread:@selector( burnCD:) withObject:nil waitUntilDone:YES];
            }
		}
        else
            runBurnAnimation = NO;
	}
	else
	{
		self.buttonsDisabled = NO;
        runBurnAnimation = NO;
	}
	
	burning = NO;
	
	
	[pool release];
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
	if (title)
	{
		[cdName release];
		//if ([title length] > 8)
		//	title = [title substringToIndex:8];
		cdName = [[[title uppercaseString] filenameString] retain];
		[nameField setStringValue: cdName];
	}
}

-(IBAction)setCDName:(id)sender
{
	NSString *name = [[nameField stringValue] uppercaseString];
	[self setCDTitle:name];
	NSLog( @"%@", cdName);
}

-(NSString *)folderToBurn
{
	return [NSString stringWithFormat:@"/tmp/%@",cdName];
}

- (void)burnCD:(id)object
{
	sizeInMb = [[self getSizeOfDirectory: [self folderToBurn]] intValue] / 1024;
	
    DRTrack*	track = [self createTrack];

    if (track)
    {
        DRBurnSetupPanel*	bsp = [DRBurnSetupPanel setupPanel];

        // We'll be the delegate for the setup panel. This allows us to show off some 
        // of the customization you can do.
        [bsp setDelegate:self];
        
        if ([bsp runSetupPanel] == NSOKButton)
        {
            DRBurnProgressPanel*	bpp = [DRBurnProgressPanel progressPanel];

            [bpp setDelegate:self];
            
            // If you wanted to run this as a sheet you would have sent
            [bpp beginProgressSheetForBurn:[bsp burnObject] layout:track modalForWindow: [self window]];
        }
        else
            runBurnAnimation = NO;
    }
    else
        runBurnAnimation = NO;
	
	self.buttonsDisabled = NO;
}


- (DRTrack *) createTrack
{
	DRFolder* rootFolder = [DRFolder folderWithPath:[self folderToBurn]];		
	return [DRTrack trackForRootFolder:rootFolder];
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (BOOL) validateMenuItem:(id)sender
{

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

- (BOOL) setupPanel:(DRSetupPanel*)aPanel deviceContainsSuitableMedia:(DRDevice*)device promptString:(NSString**)prompt; 
{
	NSDictionary *status = [device status];
	
	int freeSpace = [[[status objectForKey: DRDeviceMediaInfoKey] objectForKey: DRDeviceMediaBlocksFreeKey] longLongValue] * 2UL / 1024UL;
	
	if( freeSpace > 0 && sizeInMb >= freeSpace)
	{
		*prompt = [NSString stringWithFormat: NSLocalizedString(@"The data to burn is larger than a media size (%d MB), you need a DVD to burn this amount of data (%d MB).", nil), freeSpace, sizeInMb];
		return NO;
	}
	else if( freeSpace > 0)
	{
		*prompt = [NSString stringWithFormat: NSLocalizedString(@"Data to burn: %d MB (Media size: %d MB), representing %2.2f %%.", nil), sizeInMb, freeSpace, (float) sizeInMb * 100. / (float) freeSpace];
	}
	
	return YES;

}

//#pragma mark Progress Panel Delegate Methods

/* Here we are setting up this nice little instance variable that prevents the app from
	quitting while a burn is in progress. This gets checked up in validateMenu: and we'll
	set it to NO in burnProgressPanelDidFinish: */
	
	
- (void) burnProgressPanelWillBegin:(NSNotification*)aNotification
{
	burning = YES;	// Keep the app from being quit from underneath the burn.
	burnAnimationIndex = 0;
    runBurnAnimation = YES;
}

- (void) burnProgressPanelDidFinish:(NSNotification*)aNotification
{
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager removeFileAtPath:[self folderToBurn] handler:nil];
	burning = NO;	// OK we can quit now.
	runBurnAnimation = NO;
}

- (BOOL) burnProgressPanel:(DRBurnProgressPanel*)theBurnPanel burnDidFinish:(DRBurn*)burn
{
	NSDictionary*	burnStatus = [burn status];
	NSString*		state = [burnStatus objectForKey:DRStatusStateKey];
	
	if ([state isEqualToString:DRStatusStateFailed])
	{
		NSDictionary*	errorStatus = [burnStatus objectForKey:DRErrorStatusKey];
		NSString*		errorString = [errorStatus objectForKey:DRErrorStatusErrorStringKey];
		
		NSRunCriticalAlertPanel( NSLocalizedString( @"Burning failed", nil), errorString, NSLocalizedString( @"OK", nil), nil, nil);
	}
	else
		[sizeField setStringValue: NSLocalizedString( @"Burning is finished !", nil)];
	
	burning = NO;
	
	if ([self.window isSheet])
		[NSApp endSheet:self.window];
	[[self window] performClose:nil];
	
    runBurnAnimation = NO;
    
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
	
	[self restoreDefaultsSettings];
	
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
	
	if ((isExtracting || isSettingUpBurn || burning))
		return NO;
	else
	{
		NSFileManager *manager = [NSFileManager defaultManager];
		[manager removeFileAtPath: [self folderToBurn] handler:nil];
		[manager removeFileAtPath: [NSString stringWithFormat:@"/tmp/burnAnonymized"] handler:nil];
		[manager removeFileAtPath: [self folderToBurn] handler:nil];
		
		[filesToBurn release];
		filesToBurn = nil;
		[files release];
		files = nil;
		[anonymizedFiles release];
		anonymizedFiles = nil;
		
		//[filesTableView reloadData];
		
		if ([self.window isSheet])
			[NSApp endSheet:self.window];
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

- (NSString*) defaultTitle
{
	NSString *title = nil;
	
	if ([files count] > 0)
	{
		NSString *file = [files objectAtIndex:0];
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
		title = [dcmObject attributeValueWithName:@"PatientsName"];
	}
	else title = @"UNTITLED";
	
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
    
    irisAnimationTimer = [[NSTimer timerWithTimeInterval: 0.1  target: self selector: @selector( irisAnimation:) userInfo: NO repeats: YES] retain];
    [[NSRunLoop currentRunLoop] addTimer: irisAnimationTimer forMode: NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer: irisAnimationTimer forMode: NSDefaultRunLoopMode];
    
    
    burnAnimationTimer = [[NSTimer timerWithTimeInterval: 0.1  target: self selector: @selector( burnAnimation:) userInfo: NO repeats: YES] retain];
    
    [[NSRunLoop currentRunLoop] addTimer: burnAnimationTimer forMode: NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer: burnAnimationTimer forMode: NSDefaultRunLoopMode];
    
	[burnButton setEnabled:YES];
	
	NSString *title = nil;
	
	if (_multiplePatients || [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"])
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
    if (!grayColorSpace) grayColorSpace = CGColorSpaceCreateDeviceGray();
    
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

- (void) produceHtml:(NSString*) burnFolder
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

	if( [[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO]fileType]!=NSFileTypeSymbolicLink || [[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO]fileType]!=NSFileTypeUnknown)
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
		[duTool waitUntilExit];
		
		duOutput = [[fromPipe fileHandleForReading] availableData];
		[duOutput getBytes:aBuffer];
		
		size = [NSString stringWithCString:aBuffer];
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

- (void) addDicomdir
{
    NSThread* thread = [NSThread currentThread];
    
	[finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"" waitUntilDone:YES];
    
	NS_DURING
	NSEnumerator *enumerator;
	if( anonymizedFiles) enumerator = [anonymizedFiles objectEnumerator];
	else enumerator = [files objectEnumerator];
	
	NSString *file;
	NSString *burnFolder = [self folderToBurn];
	NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",burnFolder];
	NSString *subFolder = [NSString stringWithFormat:@"%@/DICOM",burnFolder];
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
	NSMutableArray *compressedArray = [NSMutableArray array];
	
	while (file = [enumerator nextObject])
	{
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
					[compressedArray addObject: newPath];
				break;
				
				case 2:
					[compressedArray addObject: newPath];
				break;
			}
		}
		
		[newFiles addObject:newPath];
		[pool release];
	}
	
	if( [newFiles count] > 0)
	{
		NSArray *copyCompressionSettings = nil;
		int copyCompressionResolutionLimit = 0;
		
		// Change the JPEG2000 settings
		if( [compressionMode selectedTag] == 1 && [[NSUserDefaults standardUserDefaults] boolForKey: @"JPEGinsteadJPEG2000"] == YES)
		{
			copyCompressionSettings = [[NSUserDefaults standardUserDefaults] objectForKey: @"CompressionSettings"];
			copyCompressionResolutionLimit = [[NSUserDefaults standardUserDefaults] integerForKey: @"CompressionResolutionLimit"];
			
			// 2 == compression_JPEG
			[[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", @"2", @"compression", @"1", @"quality", nil]] forKey: @"CompressionSettings"];
			[[NSUserDefaults standardUserDefaults] setObject: @"1" forKey: @"CompressionResolutionLimit"];
			[[NSUserDefaults standardUserDefaults] synchronize]; // We need this, because compression/decompression is done in a separate process
			
			// First decompress them, if compressed
			[[BrowserController currentBrowser] decompressArrayOfFiles: compressedArray work: [NSNumber numberWithChar: 'D']];
		}
		
		switch( [compressionMode selectedTag])
		{
			case 1:
				[[BrowserController currentBrowser] decompressArrayOfFiles: compressedArray work: [NSNumber numberWithChar: 'C']];
			break;
			
			case 2:
				[[BrowserController currentBrowser] decompressArrayOfFiles: compressedArray work: [NSNumber numberWithChar: 'D']];
			break;
		}
		
		// Restore the settings
		if( copyCompressionSettings)
		{
			[[NSUserDefaults standardUserDefaults] setObject: copyCompressionSettings forKey: @"CompressionSettings"];
			[[NSUserDefaults standardUserDefaults] setInteger: copyCompressionResolutionLimit forKey: @"CompressionResolutionLimit"];
		}
		
        thread.name = NSLocalizedString( @"Burning...", nil);
        thread.status = NSLocalizedString( @"Writing DICOMDIR...", nil);
		[self addDICOMDIRUsingDCMTK_forFilesAtPaths:newFiles dicomImages:dbObjects];
		
		// Both these supplementary burn data are optional and controlled from a preference panel [DDP]
		
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"BurnWeasis"])
		{
            thread.name = NSLocalizedString( @"Burning...", nil);
            thread.status = NSLocalizedString( @"Adding Weasis...", nil);
			NSString* weasisPath = [[AppController sharedAppController] weasisBasePath];
			for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:weasisPath error:NULL])
				[[NSFileManager defaultManager] copyItemAtPath:[weasisPath stringByAppendingPathComponent:subpath] toPath:[burnFolder stringByAppendingPathComponent:subpath] error:NULL];
		}
			
		
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"BurnOsirixApplication"])
		{
            thread.name = NSLocalizedString( @"Burning...", nil);
            thread.status = NSLocalizedString( @"Adding OsiriX Lite...", nil);
			// unzip the file
			NSTask *unzipTask = [[NSTask alloc] init];
			[unzipTask setLaunchPath: @"/usr/bin/unzip"];
			[unzipTask setCurrentDirectoryPath: burnFolder];
			[unzipTask setArguments: [NSArray arrayWithObjects: @"-o", [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"OsiriX Launcher.zip"], nil]]; // -o to override existing report w/ same name
			[unzipTask launch];
			[unzipTask waitUntilExit];
			[unzipTask release];
		}
		
		if ( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnHtml"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"] == NO)
		{
            thread.name = NSLocalizedString( @"Burning...", nil);
            thread.status = NSLocalizedString( @"Adding HTML pages...", nil);
			[self performSelectorOnMainThread:@selector( produceHtml:) withObject:burnFolder waitUntilDone:YES];
		}
			
		// Look for and if present copy a second folder for eg windows viewer or html files.

		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"BurnSupplementaryFolder"])
		{
            thread.name = NSLocalizedString( @"Burning...", nil);
            thread.status = NSLocalizedString( @"Adding Supplementary folder...", nil);
			NSString *supplementaryBurnPath = [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"];
			if (supplementaryBurnPath)
			{
				supplementaryBurnPath = [supplementaryBurnPath stringByExpandingTildeInPath];
				if ([manager fileExistsAtPath: supplementaryBurnPath])
				{
					NSEnumerator *enumerator = [manager enumeratorAtPath: supplementaryBurnPath];
					while (file=[enumerator nextObject])
					{
						[manager copyPath: [NSString stringWithFormat:@"%@/%@", supplementaryBurnPath,file] toPath: [NSString stringWithFormat:@"%@/%@", burnFolder,file] handler:nil]; 
					}
				}
			}
		}
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"copyReportsToCD"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"] == NO)
		{
            thread.name = NSLocalizedString( @"Burning...", nil);
            thread.status = NSLocalizedString( @"Adding Reports...", nil);
            
			NSMutableArray *studies = [NSMutableArray array];
			
			[idatabase lock];
			
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
					NSString *urlContent = [NSString stringWithContentsOfURL: [NSURL URLWithString: [study valueForKey: @"reportURL"]]];
					
					[urlContent writeToFile: [NSString stringWithFormat:@"%@/Report-%@ %@.%@", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]], [self cleanStringForFile: [[study valueForKey:@"reportURL"] pathExtension]]] atomically: YES];
				}
				else
				{
					// Convert to PDF
					
					NSString *pdfPath = [study saveReportAsPdfInTmp];
					
					if( [manager fileExistsAtPath: pdfPath] == NO)
						[manager copyPath: [study valueForKey:@"reportURL"] toPath: [NSString stringWithFormat:@"%@/Report-%@ %@.%@", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]], [self cleanStringForFile: [[study valueForKey:@"reportURL"] pathExtension]]] handler:nil]; 
					else
						[manager copyPath: pdfPath toPath: [NSString stringWithFormat:@"%@/Report-%@ %@.pdf", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]]] handler: nil];
				}
			}
			
			[idatabase unlock];
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"EncryptCD"])
	{
        thread.name = NSLocalizedString( @"Burning...", nil);
        thread.status = NSLocalizedString( @"Encrypting CD...", nil);
        
		self.password = @"";
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
			// ZIP method - zip test.zip /testFolder -r -e -P hello
			
			[BrowserController encryptFileOrFolder: burnFolder inZIPFile: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.zip"] password: self.password];
			self.password = @"";
			
			[[NSFileManager defaultManager] removeItemAtPath: burnFolder error: nil];
			[[NSFileManager defaultManager] createDirectoryAtPath: burnFolder attributes: nil];
			
			[[NSFileManager defaultManager] moveItemAtPath: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.zip"] toPath: [burnFolder stringByAppendingPathComponent: @"encryptedDICOM.zip"] error: nil];
			[[NSString stringWithString: NSLocalizedString( @"The images are encrypted with a password in this ZIP file. On MacOS it requires Stuffit Expander to decompress it. On Windows, use WinZIP.", nil)] writeToFile: [burnFolder stringByAppendingPathComponent: @"ReadMe.txt"] atomically: YES encoding: NSASCIIStringEncoding error: nil];
			
//			NSTask *t;
//			NSArray *args;
//			
//			[[NSFileManager defaultManager] removeItemAtPath: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.dmg"] error: nil];
//			
//			t = [[[NSTask alloc] init] autorelease];
//			[t setLaunchPath: @"/usr/bin/hdiutil"];
//			args = [NSArray arrayWithObjects: @"create", [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.dmg"], @"-srcfolder", burnFolder, @"-fs", @"MS-DOS", @"-format", @"UDTO", nil]; // @"-encryption", @"-passphrase", self.password
//			[t setArguments: args];
//			[t launch];
//			[t waitUntilExit];
//			
//			[[NSFileManager defaultManager] removeItemAtPath: burnFolder error: nil];
//			[[NSFileManager defaultManager] createDirectoryAtPath: burnFolder attributes: nil];
//			
//			[[NSFileManager defaultManager] moveItemAtPath: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.dmg.cdr"] toPath: [burnFolder stringByAppendingPathComponent: @"encryptedDICOM.iso"] error: nil];
//			[[NSFileManager defaultManager] moveItemAtPath: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.dmg.iso"] toPath: [burnFolder stringByAppendingPathComponent: @"encryptedDICOM.iso"] error: nil];
//			[[NSString stringWithString: NSLocalizedString( @"The images are encrypted in this ISO file. On Mac, simply double-click on the file. On Windows, you need to install an ISO mounter, such as Gizmo Drive : http://arainia.com/software/gizmo/overview.php?nID=4", nil)] writeToFile: [burnFolder stringByAppendingPathComponent: @"ReadMe.txt"] atomically: YES encoding: NSASCIIStringEncoding error: nil];
		}
		else [[NSFileManager defaultManager] removeItemAtPath: burnFolder error: nil];
	}
	
    thread.name = NSLocalizedString( @"Burning...", nil);
    thread.status = [NSString stringWithFormat: NSLocalizedString( @"Writing %3.2fMB...", nil), (float) ([[self getSizeOfDirectory: burnFolder] longLongValue] / 1024)];
    
	[finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:@"Final files size to burn: %3.2fMB", (float) ([[self getSizeOfDirectory: burnFolder] longLongValue] / 1024)] waitUntilDone:YES];
	
	NS_HANDLER
		NSLog(@"Exception while creating DICOMDIR: %@", [localException name]);
	NS_ENDHANDLER
}

- (IBAction) estimateFolderSize: (id) sender
{
	NSString				*file;
	long					size = 0;
	NSFileManager			*manager = [NSFileManager defaultManager];
	NSDictionary			*fattrs;
	
	for (file in files)
	{
		fattrs = [manager fileAttributesAtPath:file traverseLink:YES];
		size += [fattrs fileSize]/1024;
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"BurnWeasis"])
	{
		size += 17 * 1024; // About 17MB
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"BurnOsirixApplication"])
	{
		size += 8 * 1024; // About 8MB
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"BurnSupplementaryFolder"])
	{
		size += [[self getSizeOfDirectory: [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"]] longLongValue];
	}
	
	[sizeField setStringValue:[NSString stringWithFormat:@"%@ %d  %@ %3.2fMB", NSLocalizedString(@"No of files:", nil), [files count], NSLocalizedString(@"Files size (without compression):", nil), size/1024.0]];
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
    
	if( irisAnimationIndex > 13)
        irisAnimationIndex = 0;
    
    NSString *animation = [NSString stringWithFormat:@"burn_iris%02d.tif", irisAnimationIndex++];
    NSImage *image = [NSImage imageNamed: animation];
    [burnButton setImage:image];
}
@end
