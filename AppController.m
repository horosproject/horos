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


/*****************************************************************

MODIFICATION HISTORY

2.3
	20050714	LP	Added support for Bonjour DICOM connections.
					Method - (void)startDICOMBonjourSearch
	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).
				DDP	Removed FIRSTTIME and instead uses STARTCOUNT==0.
	20060116	LP	Added CombineProjectionSeries and splitMultiechoMR preference defaults
	20060124	LP	Added syncSeriesMenuItem
	20060125	LP	Added Set WL/WW Manually menu item
	
2.3.1
	20060206	LP	Working on improving multi monitor support. In Progress. works with hanging protocols
	20060217	LP	Finishing tiling work
	20060221	LP	Added more option to the WW/WL menu

2.3.2
	20060301	LP	Fixed bug with multiple screens. Screens now arranged left to right, rather than random
	20060310	JF  Eliminated KillPreviousProcess method and reorganized and commented RestartStoreSCP and StartStoreSCP.
					After changes in the Listener Preference Panel, the User is always asked to restart to make her changes effective
					At restart, RestartStoreSCP kills any storescp process eventually still alive, do some more init stuff and
					depending on @"USESTORESCP" key :
					- either creates a NetworkListener object for DCM framework storeSCP option
					- or detaches a new thread with StartSTORESCP method
  
****************************************************************/
#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#import "DOClient.h"
#import "ToolbarPanel.h"
#import "AppController.h"
#import "PreferencePaneController.h"
#import "BrowserController.h"
#import "BrowserControllerDCMTKCategory.h"
#import "ViewerController.h"
#import "SplashScreen.h"
#import "NSFont_OpenGL.h"
#import "Survey.h"
#import "PluginManager.h"
#import "DicomFile.h"
#import "HTTPServer.h"
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCM.h>
#import "PluginManager.h"
#import "DCMTKQueryRetrieveSCP.h"

#import "AppControllerDCMTKCategory.h"
#import "DefaultsOsiriX.h"
#import "OrthogonalMPRViewer.h"
#import "OrthogonalMPRPETCTViewer.h"

#import "WindowLayoutManager.h"
#import "QueryController.h"

#import "altivecFunctions.h"

#import "PluginManagerController.h"

#define BUILTIN_DCMTK YES


ToolbarPanelController		*toolbarPanel[10] = {0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L};

static		NSString				*currentHostName = 0L;

NSThread				*mainThread;
BOOL					NEEDTOREBUILD = NO;
BOOL					COMPLETEREBUILD = NO;
BOOL					USETOOLBARPANEL = NO;
short					Altivec;
AppController			*appController = 0L;
DCMTKQueryRetrieveSCP   *dcmtkQRSCP = 0L;
NSLock					*PapyrusLock = 0L;			// Papyrus is NOT thread-safe


enum	{kSuccess = 0,
        kCouldNotFindRequestedProcess = -1, 
        kInvalidArgumentsError = -2,
        kErrorGettingSizeOfBufferRequired = -3,
        kUnableToAllocateMemoryForBuffer = -4,
        kPIDBufferOverrunError = -5};

#include <sys/sysctl.h>

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static char *GetPrivateIP()
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

int GetAllPIDsForProcessName(const char* ProcessName, 
                             pid_t ArrayOfReturnedPIDs[], 
                             const unsigned int NumberOfPossiblePIDsInArray, 
                             unsigned int* NumberOfMatchesFound,
                             int* SysctlError)
{
    // --- Defining local variables for this function and initializing all to zero --- //
    int mib[6] = {0,0,0,0,0,0}; //used for sysctl call.
    int SuccessfullyGotProcessInformation;
    size_t sizeOfBufferRequired = 0; //set to zero to start with.
    int error = 0;
    long NumberOfRunningProcesses = 0;
    unsigned int Counter = 0;
    struct kinfo_proc* BSDProcessInformationStructure = NULL;
    pid_t CurrentExaminedProcessPID = 0;
    char* CurrentExaminedProcessName = NULL;

    // --- Checking input arguments for validity --- //
    if (ProcessName == NULL) //need valid process name
    {
        return(kInvalidArgumentsError);
    }

    if (ArrayOfReturnedPIDs == NULL) //need an actual array
    {
        return(kInvalidArgumentsError);
    }

    if (NumberOfPossiblePIDsInArray <= 0)
    {
        //length of the array must be larger than zero.
        return(kInvalidArgumentsError);
    }

    if (NumberOfMatchesFound == NULL) //need an integer for return.
    {
        return(kInvalidArgumentsError);
    }
    

    //--- Setting return values to known values --- //

    //initalizing PID array so all values are zero
    memset(ArrayOfReturnedPIDs, 0, NumberOfPossiblePIDsInArray * sizeof(pid_t));
        
    *NumberOfMatchesFound = 0; //no matches found yet

    if (SysctlError != NULL) //only set sysctlError if it is present
    {
        *SysctlError = 0;
    }

    //--- Getting list of process information for all processes --- //
    
    /* Setting up the mib (Management Information Base) which is an array of integers where each
    * integer specifies how the data will be gathered.  Here we are setting the MIB
    * block to lookup the information on all the BSD processes on the system.  Also note that
    * every regular application has a recognized BSD process accociated with it.  We pass
    * CTL_KERN, KERN_PROC, KERN_PROC_ALL to sysctl as the MIB to get back a BSD structure with
    * all BSD process information for all processes in it (including BSD process names)
    */
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;

    /* Here we have a loop set up where we keep calling sysctl until we finally get an unrecoverable error
    * (and we return) or we finally get a succesful result.  Note with how dynamic the process list can
    * be you can expect to have a failure here and there since the process list can change between
    * getting the size of buffer required and the actually filling that buffer.
    */
    SuccessfullyGotProcessInformation = FALSE;
    
    while (SuccessfullyGotProcessInformation == FALSE)
    {
        /* Now that we have the MIB for looking up process information we will pass it to sysctl to get the 
        * information we want on BSD processes.  However, before we do this we must know the size of the buffer to 
        * allocate to accomidate the return value.  We can get the size of the data to allocate also using the 
        * sysctl command.  In this case we call sysctl with the proper arguments but specify no return buffer 
        * specified (null buffer).  This is a special case which causes sysctl to return the size of buffer required.
        *
        * First Argument: The MIB which is really just an array of integers.  Each integer is a constant
        *     representing what information to gather from the system.  Check out the man page to know what
        *     constants sysctl will work with.  Here of course we pass our MIB block which was passed to us.
        * Second Argument: The number of constants in the MIB (array of integers).  In this case there are three.
        * Third Argument: The output buffer where the return value from sysctl will be stored.  In this case
        *     we don't want anything return yet since we don't yet know the size of buffer needed.  Thus we will
        *     pass null for the buffer to begin with.
        * Forth Argument: The size of the output buffer required.  Since the buffer itself is null we can just
        *     get the buffer size needed back from this call.
        * Fifth Argument: The new value we want the system data to have.  Here we don't want to set any system
        *     information we only want to gather it.  Thus, we pass null as the buffer so sysctl knows that 
        *     we have no desire to set the value.
        * Sixth Argument: The length of the buffer containing new information (argument five).  In this case
        *     argument five was null since we didn't want to set the system value.  Thus, the size of the buffer
        *     is zero or NULL.
        * Return Value: a return value indicating success or failure.  Actually, sysctl will either return
        *     zero on no error and -1 on error.  The errno UNIX variable will be set on error.
        */ 
        error = sysctl(mib, 3, NULL, &sizeOfBufferRequired, NULL, 0);

        /* If an error occurred then return the accociated error.  The error itself actually is stored in the UNIX 
        * errno variable.  We can access the errno value using the errno global variable.  We will return the 
        * errno value as the sysctlError return value from this function.
        */
        if (error != 0) 
        {
            if (SysctlError != NULL)
            {
                *SysctlError = errno;  //we only set this variable if the pre-allocated variable is given
            } 

            return(kErrorGettingSizeOfBufferRequired);
        }
    
        /* Now we successful obtained the size of the buffer required for the sysctl call.  This is stored in the 
        * SizeOfBufferRequired variable.  We will malloc a buffer of that size to hold the sysctl result.
        */
        BSDProcessInformationStructure = (struct kinfo_proc*) malloc(sizeOfBufferRequired);

        if (BSDProcessInformationStructure == NULL)
        {
            if (SysctlError != NULL)
            {
                *SysctlError = ENOMEM;  //we only set this variable if the pre-allocated variable is given
            } 

            return(kUnableToAllocateMemoryForBuffer); //unrecoverable error (no memory available) so give up
        }
    
        /* Now we have the buffer of the correct size to hold the result we can now call sysctl
        * and get the process information.  
        *
        * First Argument: The MIB for gathering information on running BSD processes.  The MIB is really 
        *     just an array of integers.  Each integer is a constant representing what information to 
        *     gather from the system.  Check out the man page to know what constants sysctl will work with.  
        * Second Argument: The number of constants in the MIB (array of integers).  In this case there are three.
        * Third Argument: The output buffer where the return value from sysctl will be stored.  This is the buffer
        *     which we allocated specifically for this purpose.  
        * Forth Argument: The size of the output buffer (argument three).  In this case its the size of the 
        *     buffer we already allocated.  
        * Fifth Argument: The buffer containing the value to set the system value to.  In this case we don't
        *     want to set any system information we only want to gather it.  Thus, we pass null as the buffer
        *     so sysctl knows that we have no desire to set the value.
        * Sixth Argument: The length of the buffer containing new information (argument five).  In this case
        *     argument five was null since we didn't want to set the system value.  Thus, the size of the buffer
        *     is zero or NULL.
        * Return Value: a return value indicating success or failure.  Actually, sysctl will either return 
        *     zero on no error and -1 on error.  The errno UNIX variable will be set on error.
        */ 
        error = sysctl(mib, 3, BSDProcessInformationStructure, &sizeOfBufferRequired, NULL, 0);
    
        //Here we successfully got the process information.  Thus set the variable to end this sysctl calling loop
        if (error == 0)
        {
            SuccessfullyGotProcessInformation = TRUE;
        }
        else 
        {
            /* failed getting process information we will try again next time around the loop.  Note this is caused
            * by the fact the process list changed between getting the size of the buffer and actually filling
            * the buffer (something which will happen from time to time since the process list is dynamic).
            * Anyways, the attempted sysctl call failed.  We will now begin again by freeing up the allocated 
            * buffer and starting again at the beginning of the loop.
            */
            free(BSDProcessInformationStructure); 
        }
    }//end while loop

    // --- Going through process list looking for processes with matching names --- //

    /* Now that we have the BSD structure describing the running processes we will parse it for the desired
     * process name.  First we will the number of running processes.  We can determine
     * the number of processes running because there is a kinfo_proc structure for each process.
     */
    NumberOfRunningProcesses = sizeOfBufferRequired / sizeof(struct kinfo_proc);  
    
    /* Now we will go through each process description checking to see if the process name matches that
     * passed to us.  The BSDProcessInformationStructure has an array of kinfo_procs.  Each kinfo_proc has
     * an extern_proc accociated with it in the kp_proc attribute.  Each extern_proc (kp_proc) has the process name
     * of the process accociated with it in the p_comm attribute and the PID of that process in the p_pid attibute.
     * We test the process name by compairing the process name passed to us with the value in the p_comm value.
     * Note we limit the compairison to MAXCOMLEN which is the maximum length of a BSD process name which is used
     * by the system. 
     */
    for (Counter = 0 ; Counter < NumberOfRunningProcesses ; Counter++)
    {
        //Getting PID of process we are examining
        CurrentExaminedProcessPID = BSDProcessInformationStructure[Counter].kp_proc.p_pid; 
    
        //Getting name of process we are examining
        CurrentExaminedProcessName = BSDProcessInformationStructure[Counter].kp_proc.p_comm; 
        
        if ((CurrentExaminedProcessPID > 0) //Valid PID
           && ((strncmp(CurrentExaminedProcessName, ProcessName, MAXCOMLEN) == 0))) //name matches
        {	
            // --- Got a match add it to the array if possible --- //
            if ((*NumberOfMatchesFound + 1) > NumberOfPossiblePIDsInArray)
            {
                //if we overran the array buffer passed we release the allocated buffer give an error.
                free(BSDProcessInformationStructure);
                return(kPIDBufferOverrunError);
            }
        
            //adding the value to the array.
            ArrayOfReturnedPIDs[*NumberOfMatchesFound] = CurrentExaminedProcessPID;
            
            //incrementing our number of matches found.
            *NumberOfMatchesFound = *NumberOfMatchesFound + 1;
        }
    }//end looking through process list

    free(BSDProcessInformationStructure); //done with allocated buffer so release.

    if (*NumberOfMatchesFound == 0)
    {
        //didn't find any matches return error.
        return(kCouldNotFindRequestedProcess);
    }
    else
    {
        //found matches return success.
        return(kSuccess);
    }
}

NSString * documentsDirectoryFor( int mode, NSString *url)
{
	char	s[1024];
	FSSpec	spec;
	FSRef	ref;
	
	switch( mode)
	{
		case 0:
			if( FSFindFolder (kOnAppropriateDisk, kDocumentsFolderType, kCreateFolder, &ref) == noErr )
			{
				NSString	*path;
				BOOL		isDir = YES;
				
				FSRefMakePath(&ref, (UInt8 *)s, sizeof(s));
				
				path = [[NSString stringWithUTF8String:s] stringByAppendingPathComponent:@"/OsiriX Data"];
				
				if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
				
				return path;
			}
			break;
			
		case 1:
		{
			NSString	*path;
			BOOL		isDir = YES;
			
			path = [url stringByAppendingPathComponent:@"/OsiriX Data"];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
						
			return path;
		}
		break;
	}
	
	return nil;
}

NSString * documentsDirectory()
{
	NSString *path = documentsDirectoryFor( [[NSUserDefaults standardUserDefaults] integerForKey: @"DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]);
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])	// STILL NOT AVAILABLE??
	{   // Use the default folder.. and reset this strange URL..
		
		[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
		
		return documentsDirectoryFor( [[NSUserDefaults standardUserDefaults] integerForKey: @"DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]);
	}
	
	return path;
}

static volatile BOOL converting = NO;

NSString* filenameWithDate( NSString *inputfile)
{
	NSDictionary	*fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:inputfile traverseLink:YES];
	NSDate			*createDate;
	NSNumber		*fileSize;
	
	createDate = [fattrs objectForKey:NSFileModificationDate];
	fileSize = [fattrs objectForKey:NSFileSize];
	
	if( createDate == 0L) createDate = [NSDate date];
	
	return [[[[inputfile lastPathComponent] stringByDeletingPathExtension] stringByAppendingFormat:@"%@-%d-%@", [createDate descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:nil locale:nil], [fileSize intValue], [[inputfile stringByDeletingLastPathComponent]lastPathComponent]] stringByAppendingString:@".dcm"];
}

NSString* convertDICOM( NSString *inputfile)
{
	NSString		*outputfile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/%@", filenameWithDate( inputfile)];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:outputfile]) return outputfile;
	
	converting = YES;
	NSLog(@"convertDICOM - FAILED to use current DICOM File Parser : %@", inputfile);
	[[BrowserController currentBrowser] decompressDICOM:inputfile to:outputfile deleteOriginal: NO];
	
	return outputfile;
}

//NSString* convertDICOM( NSString *inputfile)
//{
//	NSString		*tempString, *outputfile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/%@", filenameWithDate( inputfile)];
//    NSMutableArray  *theArguments = [NSMutableArray array];
//	long			i = 0;
//	
//	while( converting)
//	{
//		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
//	}
//	
//	NSLog(inputfile);
//	if ([[NSFileManager defaultManager] fileExistsAtPath:outputfile])
//	{
//		//[[NSFileManager defaultManager] removeFileAtPath:outputfile handler: 0L];
//		//NSLog(@"Already converted...");
//		return outputfile;
//	}
//	
//	converting = YES;
//	NSLog(@"IN");
//	NSTask *convertTask = [[NSTask alloc] init];
//    
////    [convertTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
////    [convertTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmdjpeg"]];
//
//	[convertTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle bundleForClass:[AppController class]] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
//	[convertTask setLaunchPath:[[[NSBundle bundleForClass:[AppController class]] resourcePath] stringByAppendingPathComponent:@"/dcmdjpeg"]]; 
//	
//    [theArguments addObject:inputfile];
//    [theArguments addObject:outputfile];
//	
//    [convertTask setArguments:theArguments];
//    
//	NS_DURING
//		// launch traceroute
//		[convertTask launch];
//		//[convertTask waitUntilExit];
//		
//		while( [convertTask isRunning] == YES)
//		{
//			//	NSLog(@"CONVERSION WORK");
//			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
//		}
//		
//		[convertTask interrupt];
//		[convertTask release];
//		
//		NSLog(@"OUT");
//		
//		converting = NO;
//		
//	NS_HANDLER
//		NSLog( [localException name]);
//		converting = NO;
//	NS_ENDHANDLER
//	
//	return outputfile ;
//}


int dictSort(id num1, id num2, void *context)
{
    return [[num1 objectForKey:@"AETitle"] caseInsensitiveCompare: [num2 objectForKey:@"AETitle"]];
}

#define kHasAltiVecMask    ( 1 << gestaltPowerPCHasVectorInstructions )  // used in  looking for a g4 

short HasAltiVec ( )
{
	Boolean			hasAltiVec = 0;
	OSErr			err;       
	SInt32			ppcFeatures;
	
	err = Gestalt ( gestaltPowerPCProcessorFeatures, &ppcFeatures );       
	if ( err == noErr)       
	{             
		if ( ( ppcFeatures & kHasAltiVecMask) != 0 )
		{
			hasAltiVec = 1;
			NSLog(@"AltiVEC is available");
		}
	}       
	return hasAltiVec;                   
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

BOOL hasMacOSXLeopard()
{
	OSErr						err;       
	SInt32						osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{
		NSLog( @"OS: %X", osVersion);
		if ( osVersion < 0x1050UL )
		{
			return NO;
		}
	}
	return YES;                   
}


BOOL hasMacOSXTiger()
{
	OSErr						err;       
	SInt32						osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{
		NSLog( @"OS: %X", osVersion);
		if ( osVersion < 0x1040UL )
		{
			return NO;
		}
	}
	return YES;                   
}

SInt32 osVersion()
{
	OSErr						err;       
	SInt32						osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{
		return osVersion;
	}
	return 0;                   
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

NSRect screenFrame()
	{
	int i = 0;
	float height = 0.0;
	float width = 0.0;
	float singleWidth = 0.0;
	int screenCount = [[NSScreen screens] count];
	NSRect frame;
	NSRect screenRect;
	switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"MULTIPLESCREENS"])
	{
		case 0:		// use main screen only
			screenRect    = [[[NSScreen screens] objectAtIndex:0] visibleFrame];
		break;
		
		case 1:		// use second screen only
			if (screenCount == 2)
			{
				screenRect = [[[NSScreen screens] objectAtIndex: 1] visibleFrame];
			}
			else if ( screenCount > 2) {
				//multiple monitors. Need to span at least two monitors for viewing if they are the same size.
				height = [[[NSScreen screens] objectAtIndex:1] frame].size.height;
				singleWidth = width = [[[NSScreen screens] objectAtIndex:1] frame].size.width;
				for (i = 2; i < screenCount; i ++) {
					frame = [[[NSScreen screens] objectAtIndex:i] frame];
					if (frame.size.height == height && frame.size.width == singleWidth)
						width =+ frame.size.width;
				}	
				screenRect = NSMakeRect([[[NSScreen screens] objectAtIndex:1] frame].origin.x, 
										[[[NSScreen screens] objectAtIndex:1] frame].origin.y,
										width,
										height);	
			}
			else //only one screen
			{
				screenRect    = [[[NSScreen screens] objectAtIndex:0] visibleFrame];
			}
		break;
		
		case 2:		// use all screens
			height = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
			singleWidth = width = [[[NSScreen screens] objectAtIndex:0] frame].size.width;
			for (i = 1; i < screenCount; i ++) {
					frame = [[[NSScreen screens] objectAtIndex:i] frame];
					if (frame.size.height == height && frame.size.width == singleWidth)
						width =+ frame.size.width;
				}	
			screenRect = NSMakeRect([[[NSScreen screens] objectAtIndex:0] frame].origin.x, 
										[[[NSScreen screens] objectAtIndex:0] frame].origin.y,
										width,
										height);
			//screenRect    = [[[NSScreen screens] objectAtIndex:0] visibleFrame];
			
			
		break;
	}
	return screenRect;
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@implementation AppController

- (IBAction)cancelModal:(id)sender
{
    [NSApp abortModal];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction)okModal:(id)sender
{
    [NSApp stopModal];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

-(IBAction)osirix64bit:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/OsiriX-64bit.html"]];
}

-(IBAction)sendEmail:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:rossetantoine@osirix-viewer.com"]]; 
}

-(IBAction)openOsirixWebPage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
}

-(IBAction)help:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Learning.html"]];
}

-(IBAction)openOsirixDiscussion:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://groups.yahoo.com/group/osirix/"]];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

+ (NSString*) currentHostName
{
	if( currentHostName) return currentHostName;
	
	currentHostName = [[[DefaultsOsiriX currentHost] name] retain];
}

+(void) cleanOsiriXSubProcesses
{
	const int kPIDArrayLength = 100;

    pid_t MyArray [kPIDArrayLength];
    unsigned int NumberOfMatches;
    int Counter, Error;
	
    Error = GetAllPIDsForProcessName( [[[NSProcessInfo processInfo] processName] UTF8String], MyArray, kPIDArrayLength, &NumberOfMatches, NULL);
	
	if (Error == 0)
    {
        for (Counter = 0 ; Counter < NumberOfMatches ; Counter++)
        {
			if( MyArray[ Counter] != getpid())
			{
				NSLog( @"Child Process to kill: %d (PID)", MyArray[ Counter]);
				
				kill( MyArray[ Counter], 15);
			}
        } 
    }
}

- (void) runPreferencesUpdateCheck:(NSTimer*) timer
{
	BOOL				restartListener = NO;
	BOOL				refreshDatabase = NO;
	BOOL				refreshColumns = NO;
	BOOL				recomputePETBlending = NO;
	BOOL				refreshViewer = NO;
	NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
	
	if( mainThread != [NSThread currentThread]) return;
	
	NS_DURING
	
	if( [[previousDefaults valueForKey: @"ROITEXTNAMEONLY"] intValue]				!=		[defaults integerForKey: @"ROITEXTNAMEONLY"])
		refreshViewer = YES;
	if( [[previousDefaults valueForKey: @"ROITEXTIFSELECTED"] intValue]				!=		[defaults integerForKey: @"ROITEXTIFSELECTED"])
		refreshViewer = YES;
	if ([[previousDefaults valueForKey: @"PET Blending CLUT"]		isEqualToString:	[defaults stringForKey: @"PET Blending CLUT"]] == NO) 
		recomputePETBlending = YES;
	if( [[previousDefaults valueForKey: @"COPYSETTINGS"] intValue]				!=		[defaults integerForKey: @"COPYSETTINGS"])
		refreshViewer = YES;
	if( [[previousDefaults valueForKey: @"DBDateFormat2"]			isEqualToString:	[defaults stringForKey: @"DBDateFormat2"]] == NO)
		refreshDatabase = YES;
	if( [[previousDefaults valueForKey: @"DBDateOfBirthFormat2"]			isEqualToString:	[defaults stringForKey: @"DBDateOfBirthFormat2"]] == NO)
		refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"DICOMTimeout"]intValue]		!=		[defaults integerForKey: @"DICOMTimeout"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"LISTENERCHECKINTERVAL"]intValue]		!=		[defaults integerForKey: @"LISTENERCHECKINTERVAL"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"SINGLEPROCESS"]intValue]				!=		[defaults integerForKey: @"SINGLEPROCESS"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"AETITLE"]					isEqualToString:	[defaults stringForKey: @"AETITLE"]] == NO)
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"STORESCPEXTRA"]			isEqualToString:	[defaults stringForKey: @"STORESCPEXTRA"]] == NO)
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"AEPORT"]					isEqualToString:	[defaults stringForKey: @"AEPORT"]] == NO)
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"AETransferSyntax"]		isEqualToString:	[defaults stringForKey: @"AETransferSyntax"]] == NO)
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"STORESCP"] intValue]					!=		[defaults integerForKey: @"STORESCP"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"USESTORESCP"] intValue]				!=		[defaults integerForKey: @"USESTORESCP"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"HIDEPATIENTNAME"] intValue]			!=		[defaults integerForKey: @"HIDEPATIENTNAME"])
		refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"COLUMNSDATABASE"]			isEqualToDictionary:[defaults objectForKey: @"COLUMNSDATABASE"]] == NO)
		refreshColumns = YES;	
	if ([[previousDefaults valueForKey: @"SERIESORDER"]intValue]				!=		[defaults integerForKey: @"SERIESORDER"])
		refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"KeepStudiesOfSamePatientTogether"]intValue]				!=		[defaults integerForKey: @"KeepStudiesOfSamePatientTogether"])
		refreshDatabase = YES;

	[previousDefaults release];
	previousDefaults = [[defaults dictionaryRepresentation] retain];
	
	if (refreshDatabase)
	{
		[[BrowserController currentBrowser] setDBDate];
		[[BrowserController currentBrowser] outlineViewRefresh];
	}
	
	if (restartListener)
	{
		if( showRestartNeeded == YES)
		{
			showRestartNeeded = NO;
			NSRunAlertPanel( NSLocalizedString( @"DICOM Listener", 0L), NSLocalizedString( @"Restart OsiriX to apply these changes.", 0L), NSLocalizedString( @"OK", 0L), nil, nil);
		}
	}
	
	if (refreshColumns)	
		[[BrowserController currentBrowser] refreshColumns];
	
	if( recomputePETBlending)
		[DCMView computePETBlendingCLUT];
	
	if( refreshViewer)
	{
		NSArray *windows = [NSApp windows];

		for(id loopItem in windows)
		{
			if([[loopItem windowController] isKindOfClass: [ViewerController class]] &&
				[loopItem isMainWindow])
			{
				[[loopItem windowController] copySettingsToOthers: self];
			}
		}
	}
	
	if( [defaults boolForKey: @"updateServers"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"updateServers"];
		[[QueryController currentQueryController] refreshSources];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:0L];
	}
	
	[[BrowserController currentBrowser] setNetworkLogs];
	[DicomFile resetDefaults];
	[DCMPix checkUserDefaults: YES];
	[DCMView setDefaults];
	[ROI loadDefaultSettings];
	
	NS_HANDLER
		NSLog(@"Exception updating prefs: %@", [localException description]);
	NS_ENDHANDLER
}

- (void) preferencesUpdated: (NSNotification*) note
{
	if( mainThread != [NSThread currentThread]) return;
	
	if( updateTimer)
	{
		[updateTimer invalidate];
		[updateTimer release];
		updateTimer = 0L;
	}
	
	updateTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(runPreferencesUpdateCheck:) userInfo:0L repeats: NO] retain];
}

-(void) UpdateWLWWMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu, *presetsMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
    mainMenu = [NSApp mainMenu];
    viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
    presetsMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
    
    keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    i = [presetsMenu numberOfItems];
    while(i-- > 0) [presetsMenu removeItemAtIndex:0];   
	
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Default WL & WW", 0L) action:@selector (ApplyWLWW:) keyEquivalent:@"l"];
	
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Other", 0L) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Full dynamic", 0L) action:@selector (ApplyWLWW:) keyEquivalent:@"y"];
	
	[presetsMenu addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [presetsMenu addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    [presetsMenu addItem: [NSMenuItem separatorItem]];
    [presetsMenu addItemWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Set WL/WW manually", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
}


-(void) UpdateConvolutionMenu: (NSNotification*) note
{
	//*** Build the menu
	NSMenu      *mainMenu;
	NSMenu      *viewerMenu, *convMenu;
	short       i;
	NSArray     *keys;
	NSArray     *sortedKeys;
	
//	NSLog( NSLocalizedString(@"Convolution Filters", nil));
	
	mainMenu = [NSApp mainMenu];
	viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
//	if( viewerMenu == 0L) NSLog( @"not found");
	
	convMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Convolution Filters", nil)] submenu];
//	if( convMenu == 0L) NSLog( @"not found");
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] allKeys];
	sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	i = [convMenu numberOfItems];
	while(i-- > 0) [convMenu removeItemAtIndex:0];    
	
	[convMenu addItemWithTitle:NSLocalizedString(@"No Filter", 0L) action:@selector (ApplyConv:) keyEquivalent:@""];
	
	[convMenu addItem: [NSMenuItem separatorItem]];
	
	for( i = 0; i < [sortedKeys count]; i++)
	{
		[convMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyConv:) keyEquivalent:@""];
	}
	[convMenu addItem: [NSMenuItem separatorItem]];
	[convMenu addItemWithTitle:NSLocalizedString(@"Add a Filter", 0L) action:@selector (AddConv:) keyEquivalent:@""];
}

-(void) UpdateCLUTMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu, *clutMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
    mainMenu = [NSApp mainMenu];
    viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
    clutMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Color Look Up Table", nil)] submenu];
    
    keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    i = [clutMenu numberOfItems];
    while(i-- > 0) [clutMenu removeItemAtIndex:0];    
	
	[clutMenu addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
	
	[clutMenu addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [clutMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
    }
    [clutMenu addItem: [NSMenuItem separatorItem]];
    [clutMenu addItemWithTitle:NSLocalizedString(@"Add a CLUT", nil) action:@selector (AddCLUT:) keyEquivalent:@""];
	
	[[clutMenu itemWithTitle:[note object]] setState:NSOnState];
}

#define INCOMINGPATH @"/INCOMING/"

-(void) restartSTORESCP
{
	NSLog(@"restartSTORESCP");
	
	// Is called restart because previous instances of storescp might exist and need to be killed before starting
	// This should be performed only if OsiriX is to handle storescp, depending on what is defined in the preferences
	// Key:@"STORESCP" is the corresponding switch
	
	NS_DURING
    quitting = YES;
	
	// The Built-In StoreSCP is now the default and only storescp available in OsiriX.... Antoine 4/9/06
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"USESTORESCP"] != YES)
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"USESTORESCP"];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"])
	{
		// Kill DCMTK listener
		// built in dcmtk serve testing
		if (BUILTIN_DCMTK == YES)
		{
			[dcmtkQRSCP release];
			dcmtkQRSCP = nil;
		}
		else
		{
			NSLog(@"********* WARNING - WE SHOULD NOT BE HERE - STORE-SCP");
			
			NSMutableArray  *theArguments = [NSMutableArray array];
			NSTask			*aTask = [[NSTask alloc] init];		
			[aTask setLaunchPath:@"/usr/bin/killall"];		
			[theArguments addObject:@"storescp"];
			[aTask setArguments:theArguments];		
			[aTask launch];
			[aTask waitUntilExit];		
			[aTask interrupt];
			[aTask release];
			aTask = nil;
		}
		
		//make sure that there exist a receiver folder at @"folder" path
		NSString            *path = [documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH];
		BOOL				isDir = YES;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) 
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"USESTORESCP"])
		{
			[NSThread detachNewThreadSelector: @selector(startSTORESCP:) toTarget: self withObject: self];
		}
	}
	
	NS_HANDLER
		NSLog(@"Exception restarting storeSCP");
	NS_ENDHANDLER
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"publishDICOMBonjour"])
	{
		//Start DICOM Bonjour 
		BonjourDICOMService = [[NSNetService  alloc] initWithDomain:@"" type:@"_dicom._tcp." name:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] port:[[[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"] intValue]];
		[BonjourDICOMService setDelegate: self];
		[BonjourDICOMService publish];
		
		[[DCMNetServiceDelegate sharedNetServiceDelegate] setPublisher: BonjourDICOMService];
	}
	else BonjourDICOMService = 0L;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"httpXMLRPCServer"])
	{
		XMLRPCServer = [[XMLRPCMethods alloc] init];
	}
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	NSLog(@"didNotPublish");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	NSLog(@"didNotResolve");
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	NSLog(@"netServiceDidPublish:");
	NSLog( [sender description]);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog(@"netServiceDidResolveAddress");
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	NSLog( @"netServiceDidStop");
	[BonjourDICOMService release];
	BonjourDICOMService = 0L;
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
	NSLog( @"netServiceWillPublish");
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
	NSLog( @"netServiceWillResolve");
}


-(void) displayListenerError: (NSString*) err
{
	NSRunCriticalAlertPanel( NSLocalizedString( @"DICOM Listener Error", 0L), err, NSLocalizedString( @"OK", 0L), nil, nil);
}

-(void) startSTORESCP:(id) sender
{
	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method
	
	if (BUILTIN_DCMTK)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSString *aeTitle = [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"];
		int port = [[[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"] intValue];
		NSDictionary *params = nil;
		
		dcmtkQRSCP = [[DCMTKQueryRetrieveSCP alloc] initWithPort:port  aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params];
		[dcmtkQRSCP run];
		
		[pool release];
		
		return;
	}
	
//	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method
//	// this implies it needs it's own pool of objects
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	
//	quitting = NO;
//	
//	// create the subprocess
//	theTask = [[NSTask alloc] init];
//	
//	// set DICOMDICTPATH in the environment of execution and choose storescp command
//	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
//	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/storescp"]];
//	
//	// initialize arguments for CLI
//	NSMutableArray *theArguments = [NSMutableArray array];
//	[theArguments addObject: @"-aet"];
//	[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]];
//	[theArguments addObject: @"-od"];
//	[theArguments addObject: [documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH]];
//	[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETransferSyntax"]];
//	[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]];
//	[theArguments addObject: @"--fork"];
//
//	if( [[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] != 0L &&
//		[[[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] isEqualToString:@""] == NO ) {
//		
//		NSLog([[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"]);
//		[theArguments addObjectsFromArray:[[[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] componentsSeparatedByString:@" "]];
//	}
//		
//	[theTask setArguments: theArguments];
//
//	
//	// open a pipe for traceroute to send its output to
//	NSPipe *thePipe = [NSPipe pipe];
//	[theTask setStandardOutput:thePipe];
//	
//	// open another pipe for the errors
//	NSPipe *errorPipe = [NSPipe pipe];
//	[theTask setStandardError:errorPipe];
//	
//	//-------------------------------launches dcmtk----------------------
//	[theTask launch];
//	[theTask waitUntilExit];
//	//-------------------------------------------------------------------
//	
//	//    int status = [theTask terminationStatus];	
//	NSData  *errData = [[errorPipe fileHandleForReading] availableData];
//	NSData  *resData = [[thePipe fileHandleForReading] availableData];	
//	NSString    *errString = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
//	NSString    *resString = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
//	
//	if( quitting == NO)
//		{
//		NSLog(@"Task failed.");
//		if( [errString isEqualToString:@""] == NO)
//			{
//				[self performSelectorOnMainThread:@selector(displayListenerError:) withObject:errString waitUntilDone: YES];
//			}
//		}
//	
//	[errString release];
//	[resString release];
//	[pool release];
}



- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
		NSLog(@"getURL: %@", url);
	// now you can create an NSURL and grab the necessary parts
}



- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	long				i;
	NSMutableArray		*filesArray = [NSMutableArray array];
	NSMutableArray		*pluginsArray = [NSMutableArray array];
	NSFileManager       *defaultManager = [NSFileManager defaultManager];
	BOOL                isDirectory;

	if([filenames count]==1) // for iChat Theatre... (drag & drop a DICOM file on the video chat window)
	{
		for( ViewerController *v in [ViewerController getDisplayed2DViewers])
		{
			for( id im in [v fileList])
				if([[im path] isEqualToString:[filenames objectAtIndex: 0]])
				{
					[[v window] makeKeyWindow];
					return;
				}
		}
	}
	
	for( i = 0; i < [filenames count]; i++)
	{
		if([defaultManager fileExistsAtPath:[filenames objectAtIndex:i] isDirectory:&isDirectory])     // A directory
		{
			if( isDirectory == YES)
			{
				NSString    *pathname;
				NSString    *aPath = [filenames objectAtIndex:i];
				if([[aPath pathExtension] isEqualToString:@"osirixplugin"])
				{
					[pluginsArray addObject:aPath];
				}
				else
				{
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					while (pathname = [enumer nextObject])
					{
						NSString * itemPath = [aPath stringByAppendingPathComponent:pathname];
						id fileType = [[enumer fileAttributes] objectForKey:NSFileType];
						
						if ([fileType isEqual:NSFileTypeRegular])
						{
							[filesArray addObject:itemPath];
						}
					}
				}
			}
			else    // A file
			{
				[filesArray addObject:[filenames objectAtIndex:i]];
			}
		}
	}
	
	if( [BrowserController currentBrowser] != 0L)
	{
		filesArray = [[BrowserController currentBrowser] copyFilesIntoDatabaseIfNeeded:filesArray];
		
		NSArray	*newImages = [[BrowserController currentBrowser] addFilesToDatabase:filesArray];
		[[BrowserController currentBrowser] outlineViewRefresh];
		
		if( [newImages count] > 0)
		{
			NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
				
			[[[BrowserController currentBrowser] databaseOutline] selectRow: [[[BrowserController currentBrowser] databaseOutline] rowForItem: object] byExtendingSelection: NO];
			[[[BrowserController currentBrowser] databaseOutline] scrollRowToVisible: [[[BrowserController currentBrowser] databaseOutline] selectedRow]];
		}
	}
	
	// Plugins installation
	if([pluginsArray count])
	{	
		NSMutableString *pluginNames = [NSMutableString string];
		NSMutableString *replacingPlugins = [NSMutableString string];
		
		NSString *replacing = NSLocalizedString(@" will be replaced by ", @"");
		NSString *strVersion = NSLocalizedString(@" version ", @"");
		
		NSMutableDictionary *active = [NSMutableDictionary dictionary];
		NSMutableDictionary *availabilities = [NSMutableDictionary dictionary];
		
		for(NSString *path in pluginsArray)
		{
			[pluginNames appendFormat:@"%@, ", [[path lastPathComponent] stringByDeletingPathExtension]];
			
			NSString *pluginBundleName = [[path lastPathComponent] stringByDeletingPathExtension];

			NSURL *bundleURL = [NSURL fileURLWithPath:[PluginManager pathResolved:path]];
			CFDictionaryRef bundleInfoDict = CFBundleCopyInfoDictionaryInDirectory((CFURLRef)bundleURL);
						
			CFStringRef versionString;
			if(bundleInfoDict != NULL)
				versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleVersion"));
			
			NSString *pluginBundleVersion;
			if(versionString != NULL)
				pluginBundleVersion = (NSString*)versionString;
			else
				pluginBundleVersion = @"";		
			
			NSArray *pluginsDictArray = [PluginManager pluginsList];
			for(NSDictionary *plug in pluginsDictArray)
			{
				if([pluginBundleName isEqualToString:[plug objectForKey:@"name"]])
				{
					[replacingPlugins appendString:[plug objectForKey:@"name"]];
					[replacingPlugins appendString:strVersion];
					[replacingPlugins appendString:[plug objectForKey:@"version"]];
					[replacingPlugins appendString:replacing];
					[replacingPlugins appendString:pluginBundleName];
					[replacingPlugins appendString:strVersion];
					[replacingPlugins appendString:pluginBundleVersion];
					[replacingPlugins appendString:@"\n\n"];
					
					[availabilities setObject:[plug objectForKey:@"availability"] forKey:path];
					[active setObject:[plug objectForKey:@"active"] forKey:path];
				}
			}
			CFRelease(versionString);
		}
		
		pluginNames = [NSMutableString stringWithString:[pluginNames substringToIndex:[pluginNames length]-2]];
		if([replacingPlugins length]) replacingPlugins = [NSMutableString stringWithString:[replacingPlugins substringToIndex:[replacingPlugins length]-2]];
		
		NSString *msg;
		NSString *areYouSure = NSLocalizedString(@"Are you sure you want to install", @"");
		
		if([pluginsArray count]==1)
			msg = [NSString stringWithFormat:NSLocalizedString(@"%@ the plugin named : %@ ?", @""), areYouSure, pluginNames];
		else
			msg = [NSString stringWithFormat:NSLocalizedString(@"%@ the following plugins : %@ ?", @""), areYouSure, pluginNames];
		
		if([replacingPlugins length])
			msg = [NSString stringWithFormat:@"%@\n\n%@", msg, replacingPlugins];
			
		NSInteger res = NSRunAlertPanel(NSLocalizedString(@"Plugins Installation", @""), msg, NSLocalizedString(@"OK", @""), NSLocalizedString(@"Cancel", @""), nil);

		if(res)
		{
			// move the plugin package into the plugins (active) directory
			NSString *destinationDirectory;
			NSString *destinationPath;

			NSArray *pluginManagerAvailabilities = [PluginManager availabilities];
			
			for(NSString *path in pluginsArray)
			{			
				NSString *availability = [availabilities objectForKey:path];
				BOOL isActive = [[active objectForKey:path] boolValue];
				
				if(!availability)
					isActive = YES;
				
				if([availability isEqualToString:[pluginManagerAvailabilities objectAtIndex:0]])
				{
					if(isActive)
						destinationDirectory = [PluginManager userActivePluginsDirectoryPath];
					else
						destinationDirectory = [PluginManager userInactivePluginsDirectoryPath];
				}
				else if([availability isEqualToString:[pluginManagerAvailabilities objectAtIndex:1]])
				{
					if(isActive)
						destinationDirectory = [PluginManager systemActivePluginsDirectoryPath];
					else
						destinationDirectory = [PluginManager systemInactivePluginsDirectoryPath];
				}
				else if([availability isEqualToString:[pluginManagerAvailabilities objectAtIndex:2]])
				{
					if(isActive)
						destinationDirectory = [PluginManager appActivePluginsDirectoryPath];
					else
						destinationDirectory = [PluginManager appInactivePluginsDirectoryPath];
				}
				else
				{
					if(isActive)
						destinationDirectory = [PluginManager userActivePluginsDirectoryPath];
					else
						destinationDirectory = [PluginManager userInactivePluginsDirectoryPath];
				}
							
				destinationPath = [destinationDirectory stringByAppendingPathComponent:[path lastPathComponent]];
			
				// delete the plugin if it already exists.
				
				NSString *pathToDelete = nil;
				
				if([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) // .osirixplugin extension
					pathToDelete = destinationPath;
				else
				{
					NSString *pathWithOldExt = [[destinationPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"plugin"];
					
					if([[NSFileManager defaultManager] fileExistsAtPath:pathWithOldExt]) // the plugin already exists but with the old extension ".plugin"
						pathToDelete = pathWithOldExt;
				}

				if(pathToDelete)
				{
					NSMutableArray *args = [NSMutableArray array];
					[args addObject:@"-r"];
					[args addObject:pathToDelete];
					
					NSTask *aTask = [[NSTask alloc] init];
					[aTask setLaunchPath:@"/bin/rm"];
					[aTask setArguments:args];
					[aTask launch];
					[aTask waitUntilExit];
					[aTask release];
				}
				
				// move the new plugin to the plugin folder				
				[PluginManager movePluginFromPath:path toPath:destinationPath];
			}
			
			[PluginManager discoverPlugins];
			[PluginManager setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];
			
			// refresh the plugin manager window (if open)
			NSArray *winList = [NSApp windows];		
			for(NSWindow *window in winList)
			{
				if( [[window windowController] isKindOfClass:[PluginManagerController class]])
					[[window windowController] refreshPluginList];
			}

		}
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if( [[[BrowserController currentBrowser] window] isMiniaturized] == YES || [[[BrowserController currentBrowser] window] isVisible] == NO)
	{
		NSArray				*winList = [NSApp windows];
		
		for( id loopItem in winList)
		{
			if( [[loopItem windowController] isKindOfClass:[ViewerController class]]) return;
		}
		
		[[[BrowserController currentBrowser] window] makeKeyAndOrderFront: self];
	}
}

- (void) applicationWillTerminate: (NSNotification*) aNotification
{
	[ROI saveDefaultSettings];
	
	[BonjourDICOMService stop];
	[BonjourDICOMService release];
	BonjourDICOMService = 0L;

    quitting = YES;
    [theTask interrupt];
	[theTask release];
	
	if (BUILTIN_DCMTK == YES)
	{
		[dcmtkQRSCP release];
		dcmtkQRSCP = nil;
	}
	
	[self destroyDCMTK];
	
	[AppController cleanOsiriXSubProcesses];
	
	// DELETE THE TEMP DIRECTORY...
	NSString *tempDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
	
	// DELETE THE DUMP DIRECTORY...
	NSString *dumpDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/DUMP/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory]) [[NSFileManager defaultManager] removeFileAtPath:dumpDirectory handler: 0L];
	
	// DELETE THE DECOMPRESSION DIRECTORY...
	NSString *decompressionDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/DECOMPRESSION/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:decompressionDirectory]) [[NSFileManager defaultManager] removeFileAtPath:decompressionDirectory handler: 0L];
}


- (void) terminate :(id) sender
{
	NSArray				*winList = [NSApp windows];
	
	if( [[BrowserController currentBrowser] shouldTerminate: sender] == NO) return;
	
	for( id loopItem in winList)
	{
		[loopItem orderOut:sender];
	}
	
	[[QueryController currentQueryController] release];

	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[NSApp terminate: sender];
}

- (id)init
{
	self = [super init];
	appController = self;
	
	PapyrusLock = [[NSLock alloc] init];
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	[IChatTheatreDelegate sharedDelegate];
	
	return self;
}

+ (id)sharedAppController {
	return appController;
}

static BOOL initialized = NO;
+ (void) initialize
{
	@try
	{
		if ( self == [AppController class] && initialized == NO)
		{
			#if __LP64__
			if( [[NSDate date] timeIntervalSinceDate: [NSCalendarDate dateWithYear:2007 month:12 day:15 hour:1 minute:1 second:1 timeZone:0L]] > 0 || [[NSUserDefaults standardUserDefaults] boolForKey:@"Outdated"])
			{
				NSRunCriticalAlertPanel(NSLocalizedString(@"Outdated Version", 0L), NSLocalizedString(@"Please update your application. Available on the web site.", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Outdated"];
				exit( 0);
			}
			else
			{
				NSString *exampleAlertSuppress = @"OsiriX 64-bit Warning";
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				if ([defaults boolForKey:exampleAlertSuppress])
				{
				}
				else {
					NSAlert* alert = [NSAlert new];
					[alert setMessageText: NSLocalizedString(@"OsiriX 64-bit Warning", 0L)];
					[alert setInformativeText:     NSLocalizedString(@"This is a preview version of OsiriX 64-bit. You SHOULD NOT use it for any scientific or clinical activities.", 0L)];
					[alert setShowsSuppressionButton:YES];
					[alert runModal];
					if ([[alert suppressionButton] state] == NSOnState)
					{
						[defaults setBool:YES forKey:exampleAlertSuppress];
					}
				}
			}
			#endif
						
			if( [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundlePackageType"] isEqualToString: @"APPL"])
			{
				[AppController cleanOsiriXSubProcesses];
								
				initialized = YES;
				
				long	i;
				
				srandom(time(NULL));
				
				mainThread = [NSThread currentThread];
							
				Altivec = HasAltiVec();
				//	if( Altivec == 0)
				//	{
				//		NSRunCriticalAlertPanel(@"Hardware Info", @"This application is optimized for Altivec - Velocity Engine unit, available only on G4/G5 processors.", @"OK", nil, nil);
				//		exit(0);
				//	}
				
				if (hasMacOSXTiger() == NO)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"MacOS X", 0L), NSLocalizedString(@"This application requires MacOS X 10.4 or higher. Please upgrade your operating system.", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
					exit(0);
				}
				
				NSLog(@"Number of processors: %d", MPProcessors ());
				
			//	if( hasMacOSXVersion() == NO)
			//	{
			//		NSRunCriticalAlertPanel(@"Software Error", @"This application requires MacOS X 10.3 or higher. Please upgrade your operating system.", @"OK", nil, nil);
			//		exit(0);
			//	}
				
			//	if( [[NSCalendarDate dateWithYear:2006 month:6 day:2 hour:12 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]] timeIntervalSinceNow] < 0)
			//	{
			//		NSRunCriticalAlertPanel(@"Update needed!", @"This version of OsiriX is outdated. Please download the last version from OsiriX web site!", @"OK", nil, nil);
			//		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
			//		exit(0);
			//	}
					
				//	switch( NSRunInformationalAlertPanel(@"OsiriX", @"Thank you for using OsiriX!\rWe need your help! Send us comments, bugs and ideas!\r\rI need supporting emails to prove utility of OsiriX!\r\rThanks!", @"Continue", @"Send an email", @"Web Site"))
				//	{
				//		case 0:
				//			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:rossetantoine@bluewin.ch?subject=OsiriX&cc=lpysher@mac.com,luca.spadola@mac.com,Osman.Ratib@sim.hcuge.ch"]];
				//		break;
				//		
				//		case -1:
				//			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
				//		break;
				//	}
				
				[[PluginManager alloc] init];
				
				// ** REGISTER DEFAULTS DICTIONARY

				[[NSUserDefaults standardUserDefaults] registerDefaults: [DefaultsOsiriX getDefaults]];
				[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
				[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];

				//Add Endoscopy LUT, WL/WW, shading to existing prefs
				// Shading Preset
				NSMutableArray *shadingArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"shadingsPresets"] mutableCopy];
				NSEnumerator *enumerator;
				NSDictionary *shading;
				BOOL exists = NO;
				
				exists = NO;
				for (shading in shadingArray) {
					if ([[shading objectForKey:@"name"] isEqualToString:@"Endoscopy"])
						exists = YES;					
				}
				if (exists == NO)
				{
					shading = [NSMutableDictionary dictionary];
					[shading setValue: @"Endoscopy" forKey: @"name"];
					[shading setValue: @"0.12" forKey: @"ambient"];
					[shading setValue: @"0.64" forKey: @"diffuse"];
					[shading setValue: @"0.73" forKey: @"specular"];
					[shading setValue: @"50" forKey: @"specularPower"];
					[shadingArray addObject:shading];
				}
				
				exists = NO;
				for (shading in shadingArray) {
					if ([[shading objectForKey:@"name"] isEqualToString:@"Glossy Bone"])
						exists = YES;					
				}
				if (exists == NO)
				{
					shading = [NSMutableDictionary dictionary];
					[shading setValue: @"Glossy Bone" forKey: @"name"];
					[shading setValue: @"0.15" forKey: @"ambient"];
					[shading setValue: @"0.24" forKey: @"diffuse"];
					[shading setValue: @"1.17" forKey: @"specular"];
					[shading setValue: @"6.98" forKey: @"specularPower"];
					[shadingArray addObject:shading];
				}
				
				exists = NO;
				for (shading in shadingArray) {
					if ([[shading objectForKey:@"name"] isEqualToString:@"Glossy Vascular"])
						exists = YES;					
				}
				if (exists == NO)
				{
					shading = [NSMutableDictionary dictionary];
					[shading setValue: @"Glossy Vascular" forKey: @"name"];
					[shading setValue: @"0.15" forKey: @"ambient"];
					[shading setValue: @"0.28" forKey: @"diffuse"];
					[shading setValue: @"1.42" forKey: @"specular"];
					[shading setValue: @"50" forKey: @"specularPower"];
					[shadingArray addObject:shading];
				}
				
				[[NSUserDefaults standardUserDefaults] setObject:shadingArray forKey:@"shadingsPresets"];
				[shadingArray release];
				
				// Endoscopy LUT
				NSMutableDictionary *cluts = [[[NSUserDefaults standardUserDefaults] objectForKey:@"CLUT"] mutableCopy];
				// fix bad CLUT in previous versions
				NSDictionary *clut = [cluts objectForKey:@"Endoscopy"];
				if (!clut || [[[clut objectForKey:@"Red"] objectAtIndex:0] intValue] != 240){
					NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
					NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
					NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
					NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
					for( i = 0; i < 256; i++)  {
						[bArray addObject: [NSNumber numberWithLong:(195 - (i * 0.26))]];
						[gArray addObject: [NSNumber numberWithLong:(187 - (i *0.26))]];
						[rArray addObject: [NSNumber numberWithLong:(240 + (i * 0.02))]];
					}
				[aCLUTFilter setObject:rArray forKey:@"Red"];
				[aCLUTFilter setObject:gArray forKey:@"Green"];
				[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
				// Points & Colors
				NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
				[points addObject:[NSNumber numberWithLong: 0]];
				[points addObject:[NSNumber numberWithLong: 255]];
		
				[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], 0L]];
				[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];

		
				[aCLUTFilter setObject:colors forKey:@"Colors"];
				[aCLUTFilter setObject:points forKey:@"Points"];
					
				[cluts setObject:aCLUTFilter forKey:@"Endoscopy"];
				[[NSUserDefaults standardUserDefaults] setObject:cluts forKey:@"CLUT"];
				}
				[cluts release];
				
				//ww/wl
				NSMutableDictionary *wlwwValues = [[[NSUserDefaults standardUserDefaults] objectForKey:@"WLWW3"] mutableCopy];
				NSDictionary *wwwl = [wlwwValues objectForKey:@"VR - Endoscopy"];
				if (!wwwl) {
					[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:-300], [NSNumber numberWithFloat:700], 0L] forKey:@"VR - Endoscopy"];
					[[NSUserDefaults standardUserDefaults] setObject:wlwwValues forKey:@"WLWW3"];
				}
				[wlwwValues release];
				
				
				// CREATE A TEMPORATY FILE DURING STARTUP
				NSString *path = [documentsDirectory() stringByAppendingPathComponent:@"/Loading"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path])
				{
					int result = NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX crashed during last startup", 0L), NSLocalizedString(@"Previous crash is maybe related to a corrupt database or corrupted images.\r\rShould I run OsiriX in Protected Mode (recommended) (no images displayed)? To allow you to delete the crashing/corrupted images/studies.\r\rOr Should I rebuild the local database? All albums, comments and status will be lost.", 0L), NSLocalizedString(@"Continue normaly",nil), NSLocalizedString(@"Protected Mode",nil), NSLocalizedString(@"Rebuild Database",nil));
					
					if( result == NSAlertOtherReturn)
					{
						NEEDTOREBUILD = YES;
						COMPLETEREBUILD = YES;
					}
					if( result == NSAlertAlternateReturn) [DCMPix setRunOsiriXInProtectedMode: YES];
				}
				
				[path writeToFile:path atomically:NO encoding: NSUTF8StringEncoding error: 0L];
				
				NSString *reportsDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/REPORTS/"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:reportsDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:reportsDirectory attributes:nil];
				
				NSString *roisDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/ROIs/"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:roisDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:roisDirectory attributes:nil];
				
				// DELETE & CREATE THE TEMP DIRECTORY...
				NSString *tempDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
				if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory attributes:nil];
				
				NSString *dumpDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/DUMP/"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:dumpDirectory attributes:nil];
				
				// CHECK IF THE REPORT TEMPLATE IS AVAILABLE
				
				NSString *reportFile;
				
				reportFile = [documentsDirectory() stringByAppendingPathComponent:@"/ReportTemplate.doc"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:reportFile] == NO)
					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/ReportTemplate.doc"] toPath:[documentsDirectory() stringByAppendingPathComponent:@"/ReportTemplate.doc"] handler:0L];

				reportFile = [documentsDirectory() stringByAppendingPathComponent:@"/ReportTemplate.rtf"];
				if ([[NSFileManager defaultManager] fileExistsAtPath:reportFile] == NO)
					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/ReportTemplate.rtf"] toPath:[documentsDirectory() stringByAppendingPathComponent:@"/ReportTemplate.rtf"] handler:0L];
				
				[AppController checkForHTMLTemplates];
				[AppController checkForPagesTemplate];
				
				// CHECK FOR THE HTML TEMPLATES DIRECTORY
//				
//				NSString *htmlTemplatesDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/HTML_TEMPLATES/"];
//				if ([[NSFileManager defaultManager] fileExistsAtPath:htmlTemplatesDirectory] == NO)
//					[[NSFileManager defaultManager] createDirectoryAtPath:htmlTemplatesDirectory attributes:nil];
//				
//				// CHECK FOR THE HTML TEMPLATES
//				
//				NSString *templateFile;
//				
//				templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportPatientsTemplate.html"];
//				NSLog(templateFile);
//				if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
//					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportPatientsTemplate.html"] toPath:templateFile handler:0L];
//
//				templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportStudiesTemplate.html"];
//				NSLog(templateFile);
//				if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
//					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStudiesTemplate.html"] toPath:templateFile handler:0L];
//					
//				// CHECK FOR THE HTML EXTRA DIRECTORY
//				
//				NSString *htmlExtraDirectory = [htmlTemplatesDirectory stringByAppendingPathComponent:@"html-extra/"];
//				if ([[NSFileManager defaultManager] fileExistsAtPath:htmlExtraDirectory] == NO)
//					[[NSFileManager defaultManager] createDirectoryAtPath:htmlExtraDirectory attributes:nil];
//					
//				// CSS file
//				NSString *cssFile = [htmlExtraDirectory stringByAppendingPathComponent:@"style.css"];
//				if ([[NSFileManager defaultManager] fileExistsAtPath:cssFile] == NO)
//					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStyle.css"] toPath:cssFile handler:0L];				
			}
		}
	}
	@catch( NSException *ne)
	{
		NSLog(@"exception: %@", [ne description]);
	}
	
}

#pragma mark-
#pragma mark growl

- (void) growlTitle:(NSString*) title description:(NSString*) description name:(NSString*) name
{
#if !__LP64__
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotUseGrowl"]) return;
	
	[GrowlApplicationBridge notifyWithTitle: title
							description: description 
							notificationName: name
							iconData: nil
							priority: 0
							isSticky: NO
							clickContext: nil];
#endif
}


- (NSDictionary *) registrationDictionaryForGrowl
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotUseGrowl"]) return 0L;
	
    NSArray *notifications;
    notifications = [NSArray arrayWithObjects: @"newfiles", @"delete", @"result", 0L];

    NSDictionary *dict = 0L;
	
	#if !__LP64__
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                             notifications, GROWL_NOTIFICATIONS_ALL,
                         notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
	#endif
	
    return (dict);
}


#pragma mark-

- (void) switchHandler:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:
                NSWorkspaceSessionDidResignActiveNotification])
    {
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"RunListenerOnlyIfActive"])
		{
			NSLog( @"***** OsiriX : session deactivation: STOP DICOM LISTENER FOR THIS SESSION");
			
			[dcmtkQRSCP abort];
			
			[QueryController echo: [NSString stringWithCString:GetPrivateIP()] port:[dcmtkQRSCP port] AET: [dcmtkQRSCP aeTitle]];
			
			while( [dcmtkQRSCP running])
			{
				NSLog( @"waiting for listener to stop...");
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
			}
			
			[dcmtkQRSCP release];
			dcmtkQRSCP = nil;
		}
    }
    else
    {
        NSLog( @"***** OsiriX : session activation: START DICOM LISTENER FOR THIS SESSION");
		
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: 2]];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"RunListenerOnlyIfActive"])
			[self restartSTORESCP];
    }
}

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
            selector:@selector(switchHandler:)
            name:NSWorkspaceSessionDidBecomeActiveNotification
            object:nil];
 
    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
            selector:@selector(switchHandler:)
            name:NSWorkspaceSessionDidResignActiveNotification
            object:nil];
			
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"UseDelaunayFor3DRoi"];	// By default, we always start with VTKDelaunay, PowerCrush has memory leaks and can crash with some 3D objects....
}

- (void) applicationWillFinishLaunching: (NSNotification *) aNotification
{
	long i;
	
	#if !__LP64__
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotUseGrowl"] == NO)
		[GrowlApplicationBridge setGrowlDelegate:self];
	#endif
	
//	DOClient	*client = [[DOClient alloc] init];
//	[client connect];
//	[client log:@"Happy Xmas 2006"];
		
//	[[PluginManager alloc] setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];
	[PluginManager setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];
    NSLog(@"Finishing Launching");
    
	theTask = nil;
	
	appController = self;
	[self initDCMTK];
	[self restartSTORESCP];
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	
    [nc addObserver: self
           selector: @selector(UpdateConvolutionMenu:)
               name: @"UpdateConvolutionMenu"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
			 
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: NSLocalizedString(@"No CLUT", 0L) userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: NSLocalizedString(@"Other", 0L) userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object:NSLocalizedString( @"No Filter", 0L) userInfo: 0L];
	
	NSLog(@"No of screens: %d", [[NSScreen screens] count]);
	
	for( i = 0; i < [[NSScreen screens] count]; i++)
		toolbarPanel[ i] = [[ToolbarPanelController alloc] initForScreen: i];
	
	for( i = 0; i < [[NSScreen screens] count]; i++)
		[toolbarPanel[ i] fixSize];
		
//	if( USETOOLBARPANEL) [[toolbarPanel window] makeKeyAndOrderFront:self];

// Increment the startup counter.

	long					startCount = [[NSUserDefaults standardUserDefaults] integerForKey: @"STARTCOUNT"];
	[[NSUserDefaults standardUserDefaults] setInteger: startCount+1 forKey: @"STARTCOUNT"];
	
	if (startCount==0)			// Replaces FIRSTTIME.
	{
		switch( NSRunInformationalAlertPanel( NSLocalizedString(@"OsiriX Updates", 0L), NSLocalizedString( @"Would you like to activate automatic checking for updates?", 0L), NSLocalizedString( @"Yes", 0L), NSLocalizedString( @"No", 0L), 0L))
		{
			case 0:
				[[NSUserDefaults standardUserDefaults] setObject: @"NO" forKey: @"CHECKUPDATES"];
			break;
		}
	}
	else
	{
//		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"SURVEYDONE3"];	// No survey for now...
		if (![[NSUserDefaults standardUserDefaults] boolForKey: @"SURVEYDONE3"])
		{
//			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"STARTCOUNT"] > 20)
//			{
//				switch( NSRunInformationalAlertPanel(@"OsiriX", @"Thank you for using OsiriX!\rDo you agree to answer a small survey to improve OsiriX?", @"Yes, sure!", @"Maybe next time", 0L))
//				{
//					case 1:
//					{
//						Survey		*survey = [[Survey alloc] initWithWindowNibName:@"Survey"];
//						[[survey window] center];
//						[survey showWindow:self];
//					}
//						break;
//				}
//			}

//			if( [[NSCalendarDate dateWithYear:2005 month:12 day:2 hour:12 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]] timeIntervalSinceNow] > 0)
//			{
//				int generated = (random() % 100) + 1;
//				
//				if( generated < 30)
//				{
//					Survey		*survey = [[Survey alloc] initWithWindowNibName:@"Survey"];
//					[[survey window] center];
//					[survey showWindow:self];
//				}
//			}

		}
		else
		{
//			[self about:self];
//			//fade out Splash window automatically 
//			[NSTimer scheduledTimerWithTimeInterval:2.0 target:splashController selector:@selector(windowShouldClose:) userInfo:nil repeats:0]; 
		}
	}
	
	[NSThread detachNewThreadSelector: @selector(checkForUpdates:) toTarget:self withObject: self];
	
	/// *****************************
	/// *****************************
	// HUG SPECIFIC CODE - DO NOT REMOVE - Thanks! Antoine Rosset
	if([DefaultsOsiriX isHUG])
	{
		if(	![[DefaultsOsiriX hostName] isEqualToString: @"lavimarch.hcuge.ch"] &&
			![[DefaultsOsiriX hostName] isEqualToString: @"drdd-mc19.hcuge.ch"] &&
			![[DefaultsOsiriX hostName] isEqualToString: @"uin-mc07.hcuge.ch"] && // quad G5 (joris)
			![[DefaultsOsiriX hostName] isEqualToString: @"uin-mc04.hcuge.ch"] && // raid
			![[DefaultsOsiriX hostName] isEqualToString: @"cih-1096.hcuge.ch"]) // quad Xeon (joris)
		{
			[self HUGDisableBonjourFeature];
			[self HUGVerifyComPACSPlugin];
		}
	}
	/// *****************************
	/// *****************************
		
	//Checks for Bonjour enabled dicom servers. Most likely other copies of OsiriX
	[self startDICOMBonjourSearch];
	
	previousDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
	showRestartNeeded = YES;
		
	[[NSNotificationCenter defaultCenter]	addObserver: self
											   selector: @selector(preferencesUpdated:)
												   name: NSUserDefaultsDidChangeNotification
												 object: nil];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"SAMESTUDY"];
}

- (IBAction) updateViews:(id) sender
{
	NSArray				*winList = [NSApp windows];
	
	for( id loopItem in winList)
	{
		if( [[loopItem windowController] isKindOfClass:[ViewerController class]])
		{
			[[loopItem windowController] needsDisplayUpdate];
		}
	}	
}

	// CONVERT OLD LUT FILES TO XML - PLEASE DONT DELETE THESE LINES!!! THANKS!!!!!
	//	{
	//		FILE*			fp;
	//		long			c, i;
	//		long			nb,r,g,b;
	//		long			red[ 256], green[ 256], blue[ 256];
	//		NSOpenPanel		*oPanel = [NSOpenPanel openPanel];
	//		
	//		for (i =0; i < 8; i++)
	//		{
	//		
	//		
	//		[oPanel setAllowsMultipleSelection:NO];
	//		[oPanel setCanChooseDirectories:NO];
	//	
	//		[oPanel runModalForDirectory:0L file:nil types:0L];
	//		
	//		fp = fopen ([[[oPanel filenames] objectAtIndex:0] UTF8String], "r");
	//		
	//		c = ' ';
	//		 while ((c = fgetc (fp)) != EOF) 
	//		  {
	//			switch (c) {
	//			  case 'S' : // rgb specified by a multiple of 256
	//					 fscanf (fp, "%li %li %li %li", &nb, &r, &g, &b);
	//				 
	//				 if (nb >= 0L && nb < 256L &&
	//					 r >= 0L && r < 256L &&
	//					 g >= 0L && g < 256L &&
	//					 b >= 0L && b < 256L) 
	//				{
	//				   red[nb] = (int) (r );
	//				   green[nb] = (int) (g );
	//				   blue[nb] = (int) (b);
	//				 } // if
	//			  break;
	//
	//			  case 'L' : // rgb specified by real values
	//					 fscanf (fp, "%li %li %li %li", &nb, &r, &g, &b);
	//				 
	//				 if (nb >= 0L && nb < 256L &&
	//					 r >= 0L && r <= 65535L &&
	//					 g >= 0L && g <= 65535L &&
	//					 b >= 0L && b <= 65535L) 
	//				{
	//				   red[nb] = (int) r / 256;
	//				   green[nb] = (int) g / 256;
	//				   blue[nb] = (int) b / 256;
	//				 } // if
	//						 break;
	//
	//			} // switch
	//
	//			// read until the end of line or eof
	//			while (((c = fgetc (fp)) != EOF) && (c != '\n') && (c!= '\r')) {}
	//
	//		  } // while ...not eof
	//		  
	//			NSMutableDictionary *xaCLUTFilter = [NSMutableDictionary dictionary];
	//			NSMutableArray		*xrArray = [NSMutableArray arrayWithCapacity:0];
	//			for( i = 0; i < 256; i++)
	//			{
	//				[xrArray addObject: [NSNumber numberWithLong: red[ i]]];
	//			}
	//			[xaCLUTFilter setObject:xrArray forKey:@"Red"];
	//			
	//			NSMutableArray		*xgArray = [NSMutableArray arrayWithCapacity:0];
	//			for( i = 0; i < 256; i++)
	//			{
	//				[xgArray addObject: [NSNumber numberWithLong: green[ i]]];
	//			}
	//			[xaCLUTFilter setObject:xgArray forKey:@"Green"];
	//			
	//			NSMutableArray		*xbArray = [NSMutableArray arrayWithCapacity:0];
	//			for( i = 0; i < 256; i++)
	//			{
	//				[xbArray addObject: [NSNumber numberWithLong: blue[ i]]];
	//			}
	//			[xaCLUTFilter setObject:xbArray forKey:@"Blue"];
	//			
	//			[xaCLUTFilter writeToFile:[[[oPanel filenames] objectAtIndex:0] stringByAppendingPathExtension:@"plist"] atomically:YES];
	//			}
	//	}
	

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————


#pragma mark-

- (void) displayUpdateMessage: (NSString*) msg
{
	if( [msg isEqualToString:@"UPTODATE"])
	{
		NSRunAlertPanel( NSLocalizedString( @"OsiriX is up-to-date", 0L), NSLocalizedString( @"You have the most recent version of OsiriX.", 0L), NSLocalizedString( @"OK", 0L), nil, nil);
	}
	
	if( [msg isEqualToString:@"ERROR"])
	{
		NSRunAlertPanel( NSLocalizedString( @"No Internet connection", 0L), NSLocalizedString( @"Unable to check latest version available.", 0L), NSLocalizedString( @"OK", 0L), nil, nil);
	}
	
	if( [msg isEqualToString:@"UPDATE"])
	{
		int button = NSRunAlertPanel( NSLocalizedString( @"New Version Available", 0L), NSLocalizedString( @"A new version of OsiriX is available. Would you like to download the new version now?", 0L), NSLocalizedString( @"OK", 0L), NSLocalizedString( @"Cancel", 0L), nil);
		
		if (NSOKButton == button)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
		}
	}
}

- (IBAction) checkForUpdates: (id) sender
{
	NSURL				*url;
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	
	if( sender != self) verboseUpdateCheck = YES;
	else verboseUpdateCheck = NO;
	
	if (hasMacOSXLeopard())
		url=[NSURL URLWithString:@"http://pubimage.hcuge.ch:8080/versionLeopard.xml"];
	else if (hasMacOSXTiger())
		url=[NSURL URLWithString:@"http://pubimage.hcuge.ch:8080/versionTiger.xml"];
	else
		url=[NSURL URLWithString:@"http://pubimage.hcuge.ch:8080/version.xml"];
	
	if( url == 0L)
	{
		if (hasMacOSXLeopard())
			url=[NSURL URLWithString:@"http://www.osirix-viewer.com/versionLeopard.xml"];
		else if (hasMacOSXTiger())
			url=[NSURL URLWithString:@"http://www.osirix-viewer.com/versionTiger.xml"];
		else
			url=[NSURL URLWithString:@"http://www.osirix-viewer.com/version.xml"];
	}
	
	if (url)
	{
		NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
		NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL: url];
		NSString *latestVersionNumber = [productVersionDict valueForKey:@"OsiriX"];
		
		if (productVersionDict && currVersionNumber && latestVersionNumber)
		{
			if ([latestVersionNumber intValue] <= [currVersionNumber intValue])
			{
				if (verboseUpdateCheck)
					[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"UPTODATE" waitUntilDone:YES];
			}
			else
			{
				if ([[NSUserDefaults standardUserDefaults] boolForKey: @"CHECKUPDATES"] || verboseUpdateCheck == YES)
					[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"UPDATE" waitUntilDone:YES];				
			}
		}
		else
		{
			if (verboseUpdateCheck)
				[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"ERROR" waitUntilDone:YES];
		}
	}
	
	[pool release];
}

- (void) URL: (NSURL*) sender resourceDidFailLoadingWithReason: (NSString*) reason
{
	if (verboseUpdateCheck)
		NSRunAlertPanel( NSLocalizedString( @"No connection available", 0L), reason, NSLocalizedString( @"OK", 0L), nil, nil);
}	

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

- (IBAction) about: (id) sender
{
/*
    if (!splashController)
    {
        splashController = [[SplashScreen alloc] init];
    }
*/
	if (splashController)
		[splashController release];
	splashController = [[SplashScreen alloc] init];
	[splashController showWindow:self];
	[splashController affiche];
}

- (IBAction) showPreferencePanel: (id) sender
{
	NSArray *winList = [NSApp windows];
	BOOL	found = NO;
					
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString:@"PreferencePanesViewer"])
		{
			found = YES;
			[[loopItem windowController] showWindow:self];
		}
	}
	
	if( found == NO)
	{
		PreferencePaneController *prefController = [[PreferencePaneController alloc] init];
		[prefController showWindow: self];
	}
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

-(void) dealloc
{
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
	
    [browserController release];
	[dcmtkQRSCP release];
	dcmtkQRSCP = 0L;
	
	[IChatTheatreDelegate releaseSharedDelegate];
	
    [super dealloc];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (id) FindViewer:(NSString*) nib :(NSMutableArray*) pixList
{
	NSArray				*winList = [NSApp windows];
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString: nib])
		{
			if( [[loopItem windowController] pixList] == pixList)
				return [loopItem windowController];
		}
	}
	
	return 0L;
}

- (NSArray*) FindRelatedViewers:(NSMutableArray*) pixList
{
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList = [NSMutableArray array];
	
	for( id loopItem in winList)
	{
		if( [[loopItem windowController] respondsToSelector:@selector( pixList)])
		{
			if( [[loopItem windowController] pixList] == pixList)
			{
				[viewersList addObject: [loopItem windowController]];
			}
		}
	}
	
	return viewersList;
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (NSScreen *)dbScreen{
	//return screen if there is a reserved DB Screen otherwise return nil;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ReserveScreenForDB"] == 1)
		return [dbWindow screen];
	return nil;
}

- (NSArray *)viewerScreens
{
	//once we have ethe list of viewers we need to arrange them ledft to right
	NSArray *viewers;
	if ([[NSScreen screens] count] > 1)
	{
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"ReserveScreenForDB"] == 2)	// Use only main screen
			return [NSArray arrayWithObject: [NSScreen mainScreen]];
		
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];
		NSScreen *screen;
		while (screen = [enumerator nextObject])
		{
			if (![screen isEqual:[self dbScreen]])
				[array addObject:screen];
		}
		//return array;
		viewers =  array;
	}
	else
		viewers =  [NSScreen screens] ; 
	
	
	//once we have the list of viewers we need to arrange them left to right
	int count = [viewers count];
	int i;
	int position;
	NSMutableArray *arrangedViewers = [NSMutableArray array];
	for (i = 0; i < count; i++)
	{
		NSScreen *aScreen = [viewers objectAtIndex:i];
		float x = [aScreen frame].origin.x;
		NSEnumerator *enumerator = [arrangedViewers objectEnumerator];
		NSScreen *screen;
		position = i;
		int current = 0;
		while (screen = [enumerator nextObject]) {
			if (x < [screen frame].origin.x)
			{
				position = current;
				current ++;
				break;
			}
		}
		
		[arrangedViewers insertObject:aScreen atIndex:position];
	}
	
	if( [self dbScreen] == 0L)
	{
		[arrangedViewers removeObject: [dbWindow screen]];
		[arrangedViewers addObject: [dbWindow screen]];
	}
	else if( [arrangedViewers count] > 1) [arrangedViewers removeObject: [dbWindow screen]];
	
	return arrangedViewers;
		
}

//- (NSRect) resizeWindow:(NSWindow*) win	withInRect:(NSRect) destRect
//{
//	NSRect	returnRect = [win frame];
//	
//	switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"WINDOWSIZEVIEWER"])
//	{
//		case 0:
//			returnRect = destRect;
//		break;
//		
//		default:
//			if( returnRect.size.width > destRect.size.width) returnRect.size.width = destRect.size.width;
//			if( returnRect.size.height > destRect.size.height) returnRect.size.height = destRect.size.height;
//			
//			// Center
//			
//			returnRect.origin.x = destRect.origin.x + destRect.size.width/2 - returnRect.size.width/2;
//			returnRect.origin.y = destRect.origin.y + destRect.size.height/2 - returnRect.size.height/2;
//		break;
//	}
//	
//	return returnRect;
//}

- (void) checkAllWindowsAreVisible:(id) sender makeKey: (BOOL) makeKey
{
	NSArray *winList = [NSApp windows];
	NSWindow *last = 0L;
	
	for( NSWindow *loopItem in winList)
	{
		if( [[loopItem windowController] isKindOfClass:[ViewerController class]])
		{
			if( [[loopItem windowController] windowWillClose] == NO)
			{
				last = loopItem;
				[loopItem orderFront: self];
			}
		}
	}
	
	if( last) [last makeKeyAndOrderFront: self];
}

- (void) checkAllWindowsAreVisible:(id) sender
{
	[self checkAllWindowsAreVisible: sender makeKey: NO];
}

- (void) displayViewers: (NSArray*) viewers OnThisScreen: (NSScreen*) screen
{
	NSRect screenRect = [screen visibleFrame];
	BOOL landscape = (screenRect.size.width/screenRect.size.height > 1) ? YES : NO;

	int rows = 1,  columns = 1, viewerCount = [viewers count];
	
	while (viewerCount > (rows * columns))
	{
		float ratio = ((float)columns/(float)rows);
		
		if (ratio > 1.5 && landscape)
			rows ++;
		else 
			columns ++;
	}
	
	int i;
	
	for( i = 0; i < viewerCount; i++)
	{
		int row = i/columns;
		int columnIndex = (i - (row * columns));
		int viewerPosition = i;
		
		NSRect frame = [screen visibleFrame];

		if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
		
		frame.size.width /= columns;
		frame.origin.x += (frame.size.width * columnIndex);
		
		if( i == viewerCount-1)
		{
			frame.size.width = [screen visibleFrame].size.width - (frame.origin.x - [screen visibleFrame].origin.x);
		}
		
		frame.size.height /= rows;
		frame.origin.y += frame.size.height * ((rows - 1) - row);
		
		[[viewers objectAtIndex:i] setWindowFrame:frame];
	}
}

- (int) currentRowForViewer: (ViewerController*) v
{
	int rows = ([[[v window] screen] visibleFrame].size.height / [[v window] frame].size.height);
	int currentrow = rows * ([[v window] frame].origin.y + [[v window] frame].size.height/2 - [[[v window] screen] visibleFrame].origin.y) / [[[v window] screen] visibleFrame].size.height;

	return rows - currentrow;
}

- (void) scaleToFit:(id)sender
{
	NSArray *array = [ViewerController getDisplayed2DViewers];
	
	for( ViewerController *v in array)
		[[v imageView] scaleToFit];
}

- (void) tileWindows:(id)sender
{
	long				i, j, k, x;
	// Array of open Windows
	NSArray				*winList = [NSApp windows];
	// array of viewers
	NSMutableArray		*viewersList = [NSMutableArray array];
	BOOL				origCopySettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYSETTINGS"];
	NSRect				screenRect =  screenFrame();
	// User default to keep studies segregated to separate screens
	BOOL				keepSameStudyOnSameScreen = [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesTogetherOnSameScreen"];
	// Array of arrays of viewers with same StudyUID
	NSMutableArray		*studyList = [NSMutableArray array];
	int					keyWindow = 0, numberOfMonitors;	
	NSArray				*screens = [self viewerScreens];
	
	numberOfMonitors = [screens count];
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"COPYSETTINGS"];
	
	//get 2D viewer windows
	for( i = 0; i < [winList count]; i++)
	{
		if(	[[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
		{
			if( [[[winList objectAtIndex:i] windowController] windowWillClose] == NO)
				[viewersList addObject: [[winList objectAtIndex:i] windowController]];
				
			if( [[viewersList lastObject] FullScreenON] ) return;
		}
	}
	
	//order windows from left-top to right-bottom, per screen if necessary
	NSMutableArray	*cWindows = [NSMutableArray arrayWithArray: viewersList];
	
	// Only the visible windows
	for( i = [cWindows count]-1; i >= 0; i--)
	{
		if( [[[cWindows objectAtIndex: i] window] isVisible] == NO) [cWindows removeObjectAtIndex: i];
	}
	
	NSMutableArray	*cResult = [NSMutableArray array];
	int count = [cWindows count];
	while( count > 0)
	{
		int index = 0;
		int row = [self currentRowForViewer: [cWindows objectAtIndex: index]];
		
		for( x = 0; x < [cWindows count]; x++)
		{
			if( [self currentRowForViewer: [cWindows objectAtIndex: x]] < row)
			{
				row = [self currentRowForViewer: [cWindows objectAtIndex: x]];
				index = x;
			}
		}
		
		float minX = [[[cWindows objectAtIndex: index] window] frame].origin.x;
		
		for( x = 0; x < [cWindows count]; x++)
		{
			if( [[[cWindows objectAtIndex: x] window] frame].origin.x < minX && [self currentRowForViewer: [cWindows objectAtIndex: x]] <= row)
			{
				minX = [[[cWindows objectAtIndex: x] window] frame].origin.x;
				index = x;
			}
		}
		
		[cResult addObject: [cWindows objectAtIndex: index]];
		[cWindows removeObjectAtIndex: index];
		count--;
	}
	
	NSLog( [cResult description]);
	
	// Add the hidden windows
	for( i = 0; i < [viewersList count]; i++)
	{
		if( [[[viewersList objectAtIndex: i] window] isVisible] == NO) [cResult addObject: [viewersList objectAtIndex: i]];
	}
	viewersList = cResult;
	
	for( i = 0; i < [viewersList count]; i++)
	{
		if( [[[viewersList objectAtIndex: i] window] isKeyWindow]) keyWindow = i;
	}
	
	if( keepSameStudyOnSameScreen)
	{
		//get 2D viewer study arrays
		for( i = 0; i < [viewersList count]; i++)
		{
			NSString	*studyUID = [[[[viewersList objectAtIndex: i] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyInstanceUID"];
			
			BOOL found = NO;
			// loop through and add to correct array if present
			for( x = 0; x < [studyList count]; x++)
			{
				if( [[[[[[studyList objectAtIndex: x] objectAtIndex: 0] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: studyUID])
				{
					[[studyList objectAtIndex: x] addObject: [viewersList objectAtIndex: i]];
					found = YES;
				}
			}
			// create new array for current UID
			if( found == NO)
			{
				[studyList addObject: [NSMutableArray array]];
				[[studyList lastObject] addObject: [viewersList objectAtIndex: i]];
			}
		}
	}
	
//	if( [studyList count])
//		NSLog( [studyList description]);
	
	int viewerCount = [viewersList count];
	
	screenRect = [[screens objectAtIndex:0] visibleFrame];
	BOOL landscape = (screenRect.size.width/screenRect.size.height > 1) ? YES : NO;
	
	int rows = [[[[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] objectForKey:@"Rows"] intValue];
	int columns = [[[[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] objectForKey:@"Columns"] intValue];

	if (![[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] || viewerCount < rows * columns)
	{
		if (landscape) {
			columns = 2 * numberOfMonitors;
			rows = 1;
		}
		else {
			columns = numberOfMonitors;
			rows = 2;
		}
	}
	
	//excess viewers. Need to add spaces to accept
	if( viewerCount > (rows * columns))
	{
		while (viewerCount > (rows * columns)){
			float ratio = ((float)columns/(float)rows)/numberOfMonitors;
			//NSLog(@"ratio: %f", ratio);
			if (ratio > 1.5 && landscape)
				rows ++;
			else 
				columns ++;
		}
	}
	
	if( keepSameStudyOnSameScreen && numberOfMonitors > 1 && [[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] == 0L)
	{
		for( i = 0; i < numberOfMonitors && i < [studyList count]; i++)
		{
			NSMutableArray	*viewersForThisScreen = [studyList objectAtIndex:i];
			
			if( i == numberOfMonitors -1 || i == [studyList count]-1)
			{
				// Take all remaining studies
				
				for ( x = i+1; x < [studyList count]; x++)
				{
					[viewersForThisScreen addObjectsFromArray: [studyList objectAtIndex: x]];
				}
			}
			
			[self displayViewers: viewersForThisScreen OnThisScreen: [screens objectAtIndex:i]];
		}
	}
	
	// if monitor count is greater than or equal to viewers. One viewer per window
	
	else if (viewerCount <= numberOfMonitors)
	{
		int count = [viewersList count];
		int skipScreen = 0;
		
		for( i = 0; i < count; i++)
		{
			NSScreen *screen = [screens objectAtIndex:i];
			NSRect frame = [screen visibleFrame];
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
			
			[[viewersList objectAtIndex:i] setWindowFrame: frame];				
		}
	}
	
	/* 
	Will have columns but no rows. 
	There are more columns than monitors. 
	 Need to separate columns among the window evenly
	 */
	
	else if((viewerCount <= columns) &&  (viewerCount % numberOfMonitors == 0))
	{
		int viewersPerScreen = viewerCount / numberOfMonitors;
		for( i = 0; i < viewerCount; i++)
		{
			int index = (int) i/viewersPerScreen;
			int viewerPosition = i % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:index];
			NSRect frame = [screen visibleFrame];
			
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
			frame.size.width /= viewersPerScreen;
			frame.origin.x += (frame.size.width * viewerPosition);
			
			[[viewersList objectAtIndex:i] setWindowFrame: frame];
		}
	} 
	//have different number of columns in each window
	else if( viewerCount <= columns) 
	{
		int columnsPerScreen = ceil(((float) columns / numberOfMonitors));

		int extraViewers = viewerCount % numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
			int monitorIndex = (int) i /columnsPerScreen;
			int viewerPosition = i % columnsPerScreen;
			NSScreen *screen = [screens objectAtIndex:monitorIndex];
			NSRect frame = [screen visibleFrame];
			
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
			if (monitorIndex < extraViewers) 
				frame.size.width /= columnsPerScreen;
			else
				frame.size.width /= (columnsPerScreen - 1);
				
			frame.origin.x += (frame.size.width * viewerPosition);
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame];
		}
	}
	//adjust for actual number of rows needed
	else if (viewerCount <=  columns * rows)  
	{
		int columnsPerScreen = ceil(((float) columns / numberOfMonitors));
		int extraViewers = columns % numberOfMonitors;
		
		for( i = 0; i < viewerCount; i++)
		{
			int row = i/columns;
			int columnIndex = (i - (row * columns));
			int monitorIndex =  columnIndex / columnsPerScreen;
			int viewerPosition = columnIndex % columnsPerScreen;
			
			NSScreen *screen = [screens objectAtIndex:monitorIndex];
			NSRect frame = [screen visibleFrame];
			
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
			
			if (monitorIndex < extraViewers || extraViewers == 0) 
				frame.size.width /= columnsPerScreen;
			else
				frame.size.width /= (columnsPerScreen - 1);
			
			frame.origin.x += (frame.size.width * viewerPosition);
			if( i == viewerCount-1 && monitorIndex != numberOfMonitors-1)
			{
				frame.size.width = [screen visibleFrame].size.width - (frame.origin.x - [screen visibleFrame].origin.x);
			}
			
			frame.size.height /= rows;
			frame.origin.y += frame.size.height * ((rows - 1) - row);

			if( monitorIndex == numberOfMonitors-1)
			{
				if( i + columns >= viewerCount)
				{
					frame.size.height += frame.origin.y - [screen visibleFrame].origin.y;
					frame.origin.y = [screen visibleFrame].origin.y;
				}
			}
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame];
		}
	}
	else
	{
		NSLog(@"NO tiling");
	}
	
	[[NSUserDefaults standardUserDefaults] setBool: origCopySettings forKey: @"COPYSETTINGS"];
	
	if( [viewersList count] > 0)
	{
		[[[viewersList objectAtIndex: keyWindow] window] makeKeyAndOrderFront:self];
		[[viewersList objectAtIndex: keyWindow] propagateSettings];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"])
		{
			for( i = 0; i < [viewersList count]; i++)
			{
				[[viewersList objectAtIndex: i] autoHideMatrix];
			}
		}
		
		[[[viewersList objectAtIndex: keyWindow] imageView] becomeMainWindow];
		[[viewersList objectAtIndex: keyWindow] refreshToolbar];
	}
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction) closeAllViewers: (id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Close All Viewers" object: self userInfo: Nil];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

//- (IBAction) saveLayout:(id) sender{
//	[[WindowLayoutManager sharedWindowLayoutManager] openLayoutWindow:sender];
//}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) startDICOMBonjourSearch
{
	if (!dicomNetServiceDelegate)
		dicomNetServiceDelegate = [DCMNetServiceDelegate sharedNetServiceDelegate];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

#pragma mark-
#pragma mark Geneva University Hospital (HUG) specific function

// Test ComPACS
- (void) HUGVerifyComPACSPlugin
{	
	if( [[PluginManager plugins] valueForKey:@"ComPACS"] == 0)
	{
		int button = NSRunAlertPanel(@"OsiriX HUG PACS",
									 @"Si vous voulez telecharger des images du PACS, vous devez installer le plugin ComPACS.",
									 @"OK", @"Cancel", nil);
		if (NSOKButton == button)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://intrad.hcuge.ch/intra/dim/uin/ressources/telechargement/"]];
		}
	}
}

// Hide the Bonjour Panel in the side drawer
- (void) HUGDisableBonjourFeature
{
	return;
	// disable Bonjour
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"bonjourSharing"];
	[browserController setBonjourSharingEnabled:NO];
	// change the GUI
	[[browserController bonjourSharingCheck] setState:NSOffState];
	[[browserController bonjourSharingCheck] setEnabled:NO];
	[[browserController bonjourServiceName] setStringValue:@""];
	[[browserController bonjourServiceName] setEnabled:NO];
	[[browserController bonjourPasswordCheck] setEnabled:NO];
	[[browserController bonjourPasswordTextField] setEnabled:NO];
	[[browserController bonjourSourcesBox] setNeedsDisplay:YES];
}


#pragma mark-
#pragma mark HTML Templates
+ (void)checkForHTMLTemplates;
{
	// directory
	NSString *htmlTemplatesDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/HTML_TEMPLATES/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:htmlTemplatesDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:htmlTemplatesDirectory attributes:nil];
	
	// HTML templates
	NSString *templateFile;

	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportPatientsTemplate.html"];
	NSLog(templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportPatientsTemplate.html"] toPath:templateFile handler:0L];

	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportStudiesTemplate.html"];
	NSLog(templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStudiesTemplate.html"] toPath:templateFile handler:0L];

	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportSeriesTemplate.html"];
	NSLog(templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportSeriesTemplate.html"] toPath:templateFile handler:0L];
	
	// HTML-extra directory
	NSString *htmlExtraDirectory = [htmlTemplatesDirectory stringByAppendingPathComponent:@"html-extra/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:htmlExtraDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:htmlExtraDirectory attributes:nil];
		
	// CSS file
	NSString *cssFile = [htmlExtraDirectory stringByAppendingPathComponent:@"style.css"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:cssFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStyle.css"] toPath:cssFile handler:0L];
}

#pragma mark-
#pragma mark Pages Template

+ (void)checkForPagesTemplate;
{
	// Pages template directory
	NSArray *templateDirectoryPathArray = [NSArray arrayWithObjects:NSHomeDirectory(), @"Library", @"Application Support", @"iWork", @"Pages", @"Templates", @"OsiriX", nil];
	int i;
	NSString *templateDirectory;
	for(i=0; i<[templateDirectoryPathArray count]; i++)
	{
		templateDirectory = [NSString pathWithComponents:[templateDirectoryPathArray subarrayWithRange:NSMakeRange(0,i+1)]];
		if(![[NSFileManager defaultManager] fileExistsAtPath:templateDirectory])
			[[NSFileManager defaultManager] createDirectoryAtPath:templateDirectory attributes:nil];
	}
	// Creates paths for other languages...
	NSArray *LocalizedTemplateDirectoryPathArray = [NSArray arrayWithObjects:NSHomeDirectory(), @"Library", @"Application Support", @"iWork", @"Pages", nil];
	NSString *localizedDirectory;
	
	NSArray	*localizedList = [NSArray arrayWithContentsOfFile: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/localizedTemplatesPages"]];
	
	for( i = 0 ; i < [localizedList count]; i++)
	{
		localizedDirectory = [NSString pathWithComponents:[LocalizedTemplateDirectoryPathArray arrayByAddingObject: [localizedList objectAtIndex: i]]];
		if(![[NSFileManager defaultManager] fileExistsAtPath:localizedDirectory]) [[NSFileManager defaultManager] createDirectoryAtPath:localizedDirectory attributes:nil];
		localizedDirectory = [localizedDirectory stringByAppendingPathComponent:@"OsiriX"];
		if(![[NSFileManager defaultManager] fileExistsAtPath:localizedDirectory]) [[NSFileManager defaultManager] createSymbolicLinkAtPath:localizedDirectory pathContent:templateDirectory];
	}
	
	// Pages template
	NSString *reportFile = [templateDirectory stringByAppendingPathComponent:@"/OsiriX Basic Report.template"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:reportFile] == NO)
	{
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriX Report.template"] toPath:[templateDirectory stringByAppendingPathComponent:@"/OsiriX Basic Report.template"] handler:0L];
	}
	
	// Pages templates in the OsiriX Data folder
	// creation of the alias to the iWork template folder if needed
	NSArray *templateDirectoryInOsiriXDataPathArray = [NSArray arrayWithObjects:documentsDirectory(), @"PAGES TEMPLATES", nil];
	NSString *templateDirectoryInOsiriXData = [NSString pathWithComponents:templateDirectoryInOsiriXDataPathArray];
	if(![[NSFileManager defaultManager] fileExistsAtPath:templateDirectoryInOsiriXData])
		[[NSFileManager defaultManager] createSymbolicLinkAtPath:templateDirectoryInOsiriXData pathContent:templateDirectory];
}

@end
