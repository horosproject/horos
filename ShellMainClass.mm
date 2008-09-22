/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "Wait.h"
#import "WaitRendering.h"
#import "DotMacKit/DotMacKit.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

#define CHECK NSLog(@"result code = %d", ok);

@interface ShellMainClass : NSApplication
{
	NSMutableArray	*services;
}

- (void) writeServices:(NSString*) path;
- (void) runScript:(NSString *)txt;

@end

static ShellMainClass	*mainClass = 0L;

// WHY THIS EXTERNAL APPLICATION FOR QUICKTIME?

// 64-bits apps support only very basic Quicktime API
// Quicktime is not multi-thread safe: highly recommended to use it only on the main thread

extern "C"
{
	extern OSErr VRObject_MakeObjectMovie (FSSpec *theMovieSpec, FSSpec *theDestSpec, long maxFrames);
}

static id aedesc_to_id(AEDesc *desc)
{
	OSErr ok;

	if (desc->descriptorType == typeChar)
	{
		NSMutableData *outBytes;
		NSString *txt;

		outBytes = [[NSMutableData alloc] initWithLength:AEGetDescDataSize(desc)];
		ok = AEGetDescData(desc, [outBytes mutableBytes], [outBytes length]);
		CHECK;

		txt = [[NSString alloc] initWithData:outBytes encoding:[NSString defaultCStringEncoding]];
		[outBytes release];
		[txt autorelease];

		return txt;
	}

	if (desc->descriptorType == typeSInt16)
	{
		SInt16 buf;
		
		AEGetDescData(desc, &buf, sizeof(buf));
		
		return [NSNumber numberWithShort:buf];
	}

	return [NSString stringWithFormat:@"[unconverted AEDesc, type=\"%c%c%c%c\"]", ((char *)&(desc->descriptorType))[0], ((char *)&(desc->descriptorType))[1], ((char *)&(desc->descriptorType))[2], ((char *)&(desc->descriptorType))[3]];
}

void scaniDiskDir( DMiDiskSession* mySession, NSString* path, NSArray* dir, NSMutableArray* files)
{
	for( NSString *currentPath in dir )
	{
		NSString *item = [path stringByAppendingPathComponent: currentPath];
		
		BOOL isDirectory;
		
		NSLog( item);
		
		if( [mySession fileExistsAtPath:item isDirectory:&isDirectory])
		{
			if( isDirectory )
			{
				NSArray *dirContent = [mySession directoryContentsAtPath: item];
				scaniDiskDir( mySession, item, dirContent, files);
			}
			else [files addObject: item];
		}
		else NSLog( @"File is missing??");
	}
}


int main(int argc, const char *argv[])
{

	return NSApplicationMain(argc, argv);
}

int executeProcess(int argc, char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	int error = 0;
	
	EnterMovies();
	
//	argv[ 1] = "generateQTVR";
//	argv[ 2] = "/Users/antoinerosset/Desktop/a.mov";
//	argv[ 3] = "100";
	
	//	argv[ 1] : what to do?
	//	argv[ 2] : Path for Quicktime file
		
	if( argv[ 1] && argv[ 2])
	{
		NSString	*what = [NSString stringWithCString:argv[ 1]];
		NSString	*path = [NSString stringWithCString:argv[ 2]];
		
		if( [what isEqualToString:@"DNSResolve"])
		{
			NSLog( @"NSNetServiceBrowser *browser = [[NSNetServiceBrowser alloc] init]");
			
			NSNetServiceBrowser *browser = [[NSNetServiceBrowser alloc] init];
			
			[browser setDelegate: mainClass];
			[browser searchForServicesOfType:@"_osirixdbsharing._tcp." inDomain:@""];
			
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 1]];
			
			[mainClass writeServices: path];
		}
		
		if( [what isEqualToString:@"OSAScript"])
		{
			[mainClass runScript: [NSString stringWithContentsOfFile: path]];
		}
		
		if( [what isEqualToString:@"getFilesFromiDisk"])
		{
			BOOL deleteFolder = [[NSString stringWithCString:argv[ 2]] intValue];
			BOOL success = YES;
			
			NSMutableArray  *filesArray = [NSMutableArray array];
			
			
			NSString        *dstPath, *OUTpath = @"/tmp/filesFromiDisk";
			NSString		*DICOMpath = @"Documents/DICOM";
			
			[[NSFileManager defaultManager] removeFileAtPath: OUTpath handler: 0L];
			[[NSFileManager defaultManager] createDirectoryAtPath: OUTpath attributes:nil];
			
			DMMemberAccount		*myDotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"----"];
			
			if ( myDotMacMemberAccount )
			{
				NSLog( @"myDotMacMemberAccount");
				
				DMiDiskSession *mySession = [DMiDiskSession iDiskSessionWithAccount: myDotMacMemberAccount];
				
				if( mySession )
				{
					NSLog( @"mySession");
					
					Wait *wait = [[Wait alloc] initWithString:NSLocalizedString(@"Receiving files from iDisk...", nil)];
					
					[wait setCancel: YES];
					
					// Find the DICOM folder
					if( ![mySession fileExistsAtPath: DICOMpath]) success = [mySession createDirectoryAtPath: DICOMpath attributes:nil];
					
					if( success )
					{
						NSArray *dirContent = [mySession directoryContentsAtPath: DICOMpath];
						
						NSLog( [dirContent description]);
						
						scaniDiskDir( mySession, DICOMpath, dirContent, filesArray);
						
						NSLog( [filesArray description]);
						
						[wait showWindow: 0L];
						[[wait progress] setMaxValue: [filesArray count]];
						
						for( long i = 0; i < [filesArray count] && [wait aborted] == NO; i++ )
						{
							dstPath = [OUTpath stringByAppendingPathComponent: [NSString stringWithFormat:@"%d", i]];
							
							[mySession movePath: [filesArray objectAtIndex: i] toPath: dstPath handler: 0L];
							
							[filesArray replaceObjectAtIndex:i withObject: dstPath];
							
							[wait incrementBy:1];
						}
						
						if( deleteFolder)
							[mySession removeFileAtPath: DICOMpath handler: 0L];
					}
					
					[wait close];
					[wait release];
				}
				else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?", 0L), NSLocalizedString(@"Unable to contact dotMac service.", 0L), NSLocalizedString(@"OK",nil),nil, nil);
			}
			else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?", 0L), NSLocalizedString(@"Unable to contact dotMac service.", 0L), NSLocalizedString(@"OK",nil),nil, nil);
			
			if( [filesArray count])
			{
				[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/files2load" handler: 0L];
				[filesArray writeToFile: @"/tmp/files2load" atomically: 0L];
			}
		}
		
		if( [what isEqualToString:@"sendFilesToiDisk"])
		{
			NSArray	*files2Copy = [NSArray arrayWithContentsOfFile: [NSString stringWithCString:argv[ 2]]];
			
			NSLog( [files2Copy description]);
			
			NSString	*DICOMpath = @"Documents/DICOM";
			
			DMMemberAccount		*myDotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"----"];
			
			if (myDotMacMemberAccount != nil )
			{
				NSLog( @"myDotMacMemberAccount");
				
				DMiDiskSession *mySession = [DMiDiskSession iDiskSessionWithAccount: myDotMacMemberAccount];
				if( mySession )
				{
					NSLog( @"mySession");
					
					// Find the DICOM folder
					if( ![mySession fileExistsAtPath: DICOMpath]) [mySession createDirectoryAtPath: DICOMpath attributes:nil];
					
					Wait *wait = [[Wait alloc] initWithString:NSLocalizedString(@"Sending files to iDisk...", nil)];
					
					[wait setCancel: YES];
					
					[wait showWindow: 0L];
					[[wait progress] setMaxValue: [files2Copy count]];
					
					for( long x = 0 ; x < [files2Copy count] && [wait aborted] == NO; x++ )
					{
						NSString			*dstPath, *srcPath = [files2Copy objectAtIndex:x];
						
						dstPath = [DICOMpath stringByAppendingPathComponent: [srcPath lastPathComponent]];
						
						NSLog( srcPath);
						NSLog( dstPath);
						
						if( ![mySession fileExistsAtPath: dstPath]) [mySession copyPath: srcPath toPath: dstPath handler:nil];
						else {
								if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [srcPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
								{
									[mySession removeFileAtPath: dstPath handler:nil];
									[mySession copyPath: srcPath toPath: dstPath handler:nil];
								}
								else break;
						}
						
						[wait incrementBy:1];
					}
					
					[wait close];
					[wait release];
				}
				else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"Unable to contact dotMac service.",@"Unable to contact dotMac service."), NSLocalizedString(@"OK",nil),nil, nil);
			}
			else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"No iDisk is currently defined in your system.",@"No iDisk is currently defined in your system."), NSLocalizedString(@"OK",nil),nil, nil);
		}
		
		if( [what isEqualToString:@"getFrame"])
		{
			int frameNo = [[NSString stringWithCString:argv[ 3]] intValue];
			
			QTMovie *movie = [[QTMovie alloc] initWithFile:path error: 0L];
			
			if( movie)
			{
				int curFrame = 0;
				[movie gotoBeginning];
				
				QTTime previousTime;
				
				curFrame = 0;
				
				while( QTTimeCompare( previousTime, [movie currentTime]) == NSOrderedAscending && curFrame != frameNo)
				{
					previousTime = [movie currentTime];
					curFrame++;
					[movie stepForward];
				}
				
				//[result addObject: [movie currentFrameImage]];
				
				[movie release];
			}
		}
		
		if( [what isEqualToString:@"generateQTVR"] && argv[ 3])
		{
			// argv[ 3] = frameNo
			
			int frameNo = [[NSString stringWithCString:argv[ 3]] intValue];
			
			FSRef				fsref;
			FSSpec				spec, newspec;
			
			FSPathMakeRef((unsigned const char *)[path fileSystemRepresentation], &fsref, NULL);
			FSGetCatalogInfo( &fsref, kFSCatInfoNone,NULL, NULL, &spec, NULL);
			
			FSMakeFSSpec(spec.vRefNum, spec.parID, "\ptempMovie", &newspec);
			
			VRObject_MakeObjectMovie( &spec, &newspec, frameNo);
		}
		
		if( [what isEqualToString:@"getExportSettings"] && argv[ 3] && argv[ 4] && argv[ 5])
		{
			[NSRunLoop currentRunLoop];
			
			QTMovie *aMovie = [[QTMovie alloc] initWithFile:path error: 0L];
			
			NSLog( @"getExportSettings : %@", path);
			
			// argv[ 3] = component dictionary path
			// argv[ 4] = pref nsdata path IN
			// argv[ 5] = pref nsdata path OUT
			
			if( aMovie)
			{
				NSDictionary *component = [NSDictionary dictionaryWithContentsOfFile: [NSString stringWithCString:argv[ 3]]];
				
				NSLog( [component description]);
				
				
				// **** See QuicktimeExport.m
				
				Component c;
				ComponentDescription cd;
				
				cd.componentType = [[component objectForKey: @"type"] longValue];
				cd.componentSubType = [[component objectForKey: @"subtype"] longValue];
				cd.componentManufacturer = [[component objectForKey: @"manufacturer"] longValue];
				cd.componentFlags = hasMovieExportUserInterface;
				cd.componentFlagsMask = hasMovieExportUserInterface;
				c = FindNextComponent( 0, &cd );
				
				MovieExportComponent exporter = OpenComponent(c);
				
				Boolean canceled;
				
				Movie theMovie = [aMovie quickTimeMovie];
				TimeValue duration = GetMovieDuration(theMovie);
				
				ComponentResult err;
				
				NSData *data = [NSData dataWithContentsOfFile: [NSString stringWithCString:argv[ 4]]];
				char	*ptr = (char*) [data bytes];
				
				if( data) MovieExportSetSettingsFromAtomContainer (exporter, &ptr);
				
				err = MovieExportDoUserDialog(exporter, theMovie, NULL, 0, duration, &canceled);
				if( err == NO && canceled == NO)
				{
					QTAtomContainer settings;
					err = MovieExportGetSettingsAsAtomContainer(exporter, &settings);
					if(err)
					{
						NSLog(@"Got error %d when calling MovieExportGetSettingsAsAtomContainer");
					}
					else
					{
						data = [NSData dataWithBytes:*settings length:GetHandleSize(settings)];	
						
						DisposeHandle(settings);
						CloseComponent(exporter);
						
						// **************************
						
						NSString	*dataPath = [NSString stringWithCString:argv[ 5]];
						[[NSFileManager defaultManager] removeFileAtPath: dataPath handler: 0L];
						[data writeToFile: dataPath atomically: YES];
					}
				}
				[aMovie release];
			}
		}
	}
	
	ExitMovies();
	
	[pool release];
	
	return error;
}

@implementation ShellMainClass

- (void)runScript:(NSString *)txt
{
ComponentInstance myComponent = OpenDefaultComponent(kOSAComponentType, kOSAGenericScriptingComponentSubtype);

NSData *scriptChars = [txt dataUsingEncoding:[NSString defaultCStringEncoding]];
AEDesc source, resultText;
OSAID scriptId, resultId;
OSErr ok;

// Convert the source string into an AEDesc of string type.
ok = AECreateDesc(typeChar, [scriptChars bytes], [scriptChars length], &source);
CHECK;

// Compile the source into a script.
scriptId = kOSANullScript;
ok = OSACompile(myComponent, &source, kOSAModeNull, &scriptId);
AEDisposeDesc(&source);
CHECK;


// Execute the script, using defaults for everything.
resultId = 0;
ok = OSAExecute(myComponent, scriptId, kOSANullScript, kOSAModeNull, &resultId);
CHECK;

if (ok == errOSAScriptError) {
AEDesc ernum, erstr;
id ernumobj, erstrobj;

// Extract the error number and error message from our scripting component.
ok = OSAScriptError(myComponent, kOSAErrorNumber, typeSInt16, &ernum);
CHECK;
ok = OSAScriptError(myComponent, kOSAErrorMessage, typeChar, &erstr);
CHECK;

// Convert them to ObjC types.
ernumobj = aedesc_to_id(&ernum);
AEDisposeDesc(&ernum);
erstrobj = aedesc_to_id(&erstr);
AEDisposeDesc(&erstr);

txt = [NSString stringWithFormat:@"Error, number=%@, message=%@", ernumobj, erstrobj];
} else {
// If no error, extract the result, and convert it to a string for display

if (resultId != 0) { // apple doesn't mention that this can be 0?
ok = OSADisplay(myComponent, resultId, typeChar, kOSAModeNull, &resultText);
CHECK;

//NSLog(@"result thingy type = \"%c%c%c%c\"", ((char *)&(resultText.descriptorType))[0], ((char *)&(resultText.descriptorType))[1], ((char *)&(resultText.descriptorType))[2], ((char *)&(resultText.descriptorType))[3]);

txt = aedesc_to_id(&resultText);
AEDisposeDesc(&resultText);
} else {
txt = @"[no value returned]";
}
OSADispose(myComponent, resultId);
}

ok = OSADispose(myComponent, scriptId);
CHECK;
}

- (void) writeServices:(NSString*) path
{
	[services writeToFile: path atomically: YES];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog( @"netServiceDidResolveAddress");
	
   if ([[sender addresses] count] > 0)
   {
        NSData * address;
        struct sockaddr * socketAddress;
        NSString * ipAddressString = nil;
        NSString * portString = nil;
        char buffer[256];
        int index;

        // Iterate through addresses until we find an IPv4 address
        for (index = 0; index < [[sender addresses] count]; index++) {
            address = [[sender addresses] objectAtIndex:index];
            socketAddress = (struct sockaddr *)[address bytes];

            if (socketAddress->sa_family == AF_INET) break;
        }

        // Be sure to include <netinet/in.h> and <arpa/inet.h> or else you'll get compile errors.

        if (socketAddress) {
            switch(socketAddress->sa_family) {
                case AF_INET:
                    if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer))) {
                        ipAddressString = [NSString stringWithCString:buffer];
                        portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
                    }
                    
                    // Cancel the resolve now that we have an IPv4 address.
                    [sender stop];

                    break;
                case AF_INET6:
                    // OsiriX server doesn't support IPv6
                    return;
            }
        }
		
		NSMutableDictionary	*serviceDict = [NSMutableDictionary dictionary];
		
		[serviceDict setValue: [sender hostName] forKey:@"HostName"];
		[serviceDict setValue: [sender name] forKey:@"Name"];
		[serviceDict setValue: ipAddressString forKey:@"Address"];
		[serviceDict setValue: portString forKey:@"OsiriXPort"];
		
		[services addObject: serviceDict];
	}
	
	[sender release];
}

// This object is the delegate of its NSNetServiceBrowser object.
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: aNetService, @"service", @"bonjour", @"type", 0L];
	
	[aNetService retain];
	[aNetService setDelegate:self];
	[aNetService resolveWithTimeout: 1];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[self setDelegate: self];
		mainClass = self;
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	services = [[NSMutableArray array] retain];

	NSArray *arguments = [[NSProcessInfo processInfo] arguments];

	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing...", nil)];
	
	[wait showWindow:self];
	
	NSLog( @"**** 32-bit shell started");
	
	NSLog( [arguments description]);
	
	int argc = [arguments count];
	
	char **argv = (char**) malloc( argc * sizeof( char*));
	
	for( int i = 0; i < argc; i++)
		argv[ i] = (char*) [[arguments objectAtIndex: i] UTF8String];
	
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	
	ProcessSerialNumber psn;
	
	if (!GetCurrentProcess(&psn))
	{
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
        SetFrontProcess(&psn);
    }
	
	executeProcess( argc, argv);
	
	free( argv);
	
	NSLog( @"**** 32-bit shell exit");
	
	[wait close];
	[wait release];
	
	exit( 0);
}

@end