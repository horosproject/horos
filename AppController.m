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

//diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nomount ram://1165430`

#import "SystemConfiguration/SCDynamicStoreCopySpecific.h"
#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#import "ToolbarPanel.h"
#import "AppController.h"
#import "PreferencesWindowController.h"
#import "BrowserController.h"
#import "BrowserControllerDCMTKCategory.h"
#import "ViewerController.h"
#import "XMLController.h"
#import "SplashScreen.h"
#import "NSFont_OpenGL.h"
#import "DicomFile.h"
#import <OsiriX/DCM.h>
#import "PluginManager.h"
#import "DCMTKQueryRetrieveSCP.h"
#import "BLAuthentication.h"
#import "AppControllerDCMTKCategory.h"
#import "DefaultsOsiriX.h"
#import "OrthogonalMPRViewer.h"
#import "OrthogonalMPRPETCTViewer.h"
#import "NavigatorView.h"
#import "WindowLayoutManager.h"
#import "QueryController.h"
#import "N2Shell.h"
#import "NSSplitViewSave.h"
#import "altivecFunctions.h"
#import "NSUserDefaultsController+OsiriX.h"
#import <N2Debug.h>
#import "NSFileManager+N2.h"
#import <objc/runtime.h>
#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
#import <ILCrashReporter/ILCrashReporter.h>
#endif
#endif
#import "PluginManagerController.h"
#import "OSIWindowController.h"
#import "Notifications.h"
#import "WaitRendering.h"
#import "WebPortal.h"
#import "DicomImage.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "DicomDatabase.h"
#import "N2MutableUInteger.h"

#include <OpenGL/OpenGL.h>

#include <kdu_OsiriXSupport.h>

#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
	 
#define BUILTIN_DCMTK YES

ToolbarPanelController *toolbarPanel[10] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};

static NSMenu *mainMenuCLUTMenu = nil, *mainMenuWLWWMenu = nil, *mainMenuConvMenu = nil, *mainOpacityMenu = nil;
static NSDictionary *previousWLWWKeys = nil, *previousCLUTKeys = nil, *previousConvKeys = nil, *previousOpacityKeys = nil;
static BOOL checkForPreferencesUpdate = YES;
static PluginManager *pluginManager = nil;
static unsigned char *LUT12toRGB = nil;
static BOOL canDisplay12Bit = NO;
static NSInvocation *fill12BitBufferInvocation = nil;
static NSString *appStartingDate = nil;

BOOL					NEEDTOREBUILD = NO;
BOOL					COMPLETEREBUILD = NO;
BOOL					USETOOLBARPANEL = NO;
short					Altivec = 1, Use_kdu_IfAvailable = 1;
AppController			*appController = nil;
DCMTKQueryRetrieveSCP   *dcmtkQRSCP = nil, *dcmtkQRSCPTLS = nil;
NSString				*checkSN64String = nil;
NSNetService			*checkSN64Service = nil;
NSRecursiveLock			*PapyrusLock = nil, *STORESCP = nil, *STORESCPTLS = nil;			// Papyrus is NOT thread-safe
NSMutableArray			*accumulateAnimationsArray = nil;
BOOL					accumulateAnimations = NO;

AppController* OsiriX = nil;

extern int delayedTileWindows;
extern NSString* getMacAddress(void);

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


#ifdef OSIRIX_LIGHT
void exitOsiriX(void)
{
	[NSException raise: @"JPEG error exception raised" format: @"JPEG error exception raised - See Console.app for error message"];
}
#endif

static char *privateIPstring = nil;

const char *GetPrivateIP()
{
	if( privateIPstring == nil)
	{
		struct			hostent *h;
		static char		hostname[ 100];
		
		gethostname(hostname, 99);
		
		if ((h=gethostbyname(hostname)) == NULL)
		{
			NSLog( @"**** Cannot GetPrivateIP -> will use hostname");
			
			privateIPstring = (char*) malloc( 100);
			strcpy( privateIPstring, hostname);
		}
		else
		{
			privateIPstring = (char*) malloc( 100);
			strcpy( privateIPstring, (char*) inet_ntoa(*((struct in_addr *)h->h_addr)));
		}
	}
	
	return privateIPstring;
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

NSString* documentsDirectoryFor(int mode, NSString *url) { // __deprecated
	return [DicomDatabase baseDirPathForMode:mode path:url];
}

NSString* documentsDirectory() { // __deprecated
	return [DicomDatabase defaultBaseDirPath];
}

static volatile BOOL converting = NO;

NSString* filenameWithDate( NSString *inputfile)
{
	NSDictionary	*fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:inputfile traverseLink:YES];
	NSDate			*createDate;
	NSNumber		*fileSize;
	
	createDate = [fattrs objectForKey:NSFileModificationDate];
	fileSize = [fattrs objectForKey:NSFileSize];
	
	if( createDate == nil) createDate = [NSDate date];
	
	return [[[[inputfile lastPathComponent] stringByDeletingPathExtension] stringByAppendingFormat:@"%@-%d-%@", [createDate descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:nil locale:nil], [fileSize intValue], [[inputfile stringByDeletingLastPathComponent]lastPathComponent]] stringByAppendingString:@".dcm"];
}

NSString* convertDICOM( NSString *inputfile)
{
	if( inputfile == nil)
		return nil;
	
	NSString *outputfile = [[[DicomDatabase defaultDatabase] tempDirPath] stringByAppendingPathComponent:filenameWithDate(inputfile)];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:outputfile])
		return outputfile;
	
	converting = YES;
	NSLog(@"convertDICOM - FAILED to use current DICOM File Parser : %@", inputfile);
	#ifndef OSIRIX_LIGHT
	[[BrowserController currentBrowser] decompressDICOMList: [NSArray arrayWithObject: inputfile] to: [outputfile stringByDeletingLastPathComponent]];
	#endif
	return outputfile;
}

//NSString* convertDICOM( NSString *inputfile)
//{
//	NSString		*tempString, *outputfile = [documentsDirectory() stringByAppendingFormat:@"/TEMP.noindex/%@", filenameWithDate( inputfile)];
//    NSMutableArray  *theArguments = [NSMutableArray array];
//	long			i = 0;
//	
//	while( converting)
//	{
//		[NSThread sleepForTimeInterval:0.002];
//	}
//	
//	NSLog(inputfile);
//	if ([[NSFileManager defaultManager] fileExistsAtPath:outputfile])
//	{
//		//[[NSFileManager defaultManager] removeFileAtPath:outputfile handler: nil];
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
//			[NSThread sleepForTimeInterval:0.002];
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
			else if ( screenCount > 2)
			{
				//multiple monitors. Need to span at least two monitors for viewing if they are the same size.
				height = [[[NSScreen screens] objectAtIndex:1] frame].size.height;
				singleWidth = width = [[[NSScreen screens] objectAtIndex:1] frame].size.width;
				for (i = 2; i < screenCount; i ++)
				{
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
			for (i = 1; i < screenCount; i ++)
			{
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

#import <Foundation/Foundation.h>  

// This function takes as parameter the data of the aliases  
// stored in the com.apple.LaunchServices.plist file.  
// It returns the resolved path as string.  
static NSString *getResolvedAliasPath(NSData* inData)  
{  
    NSString *outPath = nil;  
    if(inData != nil)  
    {  
        const void *theDataPtr = [inData bytes];  
        NSUInteger theDataLength = [inData length];  
        if(theDataPtr != nil && theDataLength > 0)  
        {  
            // Create an AliasHandle from the NSData  
            AliasHandle theAliasHandle;  
            theAliasHandle = (AliasHandle)NewHandle(theDataLength);  
            bcopy(theDataPtr, *theAliasHandle, theDataLength);  
			
            FSRef theRef;  
            Boolean wChang;  
            OSStatus err = noErr;  
            err = FSResolveAlias(NULL, theAliasHandle, &theRef, &wChang);  
            if(err == noErr)  
            {  
                // The path was resolved.  
                char path[1024];  
                err = FSRefMakePath(&theRef, (UInt8*)path, sizeof(path));  
                if(err == noErr)  
                    outPath = [NSString stringWithUTF8String:path];  
            }  
            else  
            {  
                // If we can't resolve the alias (file not found),  
                // we can still return the path.  
                CFStringRef tmpPath = NULL;  
                err = FSCopyAliasInfo(theAliasHandle, NULL, NULL,  
                                      &tmpPath, NULL, NULL);  
				
                if(err == noErr && tmpPath != NULL)  
                    outPath = [(NSString*)tmpPath autorelease];  
            }  
			
            DisposeHandle((Handle)theAliasHandle);  
        }  
    }  
	
    return outPath;  
}  

static void dumpLSArchitecturesForX86_64()  
{ 
		// The path of the com.apple.LaunchServices.plist file.  
		NSString *prefsPath = @"~/Library/Preferences/com.apple.LaunchServices.plist";  
		prefsPath = [prefsPath stringByExpandingTildeInPath];  
		
		NSDictionary *mainDict = [NSDictionary dictionaryWithContentsOfFile:prefsPath];  
		if(mainDict != nil)  
		{  
			// We are only interested by the  
			// "LSArchitecturesForX86_64" dictionary.  
			NSDictionary *architectureDict = [mainDict objectForKey:@"LSArchitecturesForX86_64"];  
			
			// Get the list of applications.  
			// The array is ordered by applicationID.  
			NSArray *applicationIDArray = [architectureDict allKeys];  
			if(applicationIDArray != nil)  
			{  
				// For each applicationID  
				NSUInteger i = 0;  
				for(i = 0 ; i < [applicationIDArray count] ; i++)  
				{  
					NSString *applicationID = [applicationIDArray objectAtIndex:i];
					NSArray *appArray = [architectureDict objectForKey:applicationID];
					
					// For each instance of the application,  
					// there is a pair (Alias, architecture).  
					// The alias is stored as a NSData  
					// and the architecture as a NSString.  
					NSUInteger j = 0;  
					for(j = 0 ; j < [appArray count] / 2 ; j++)  
					{  
						// Just for safety  
						if(j * 2 + 1 < [appArray count])  
						{  
							NSData *aliasData = [appArray objectAtIndex:j * 2];  
							
							NSString *theArch = [appArray objectAtIndex:j * 2 + 1];  
							
							if(aliasData != nil && theArch != nil)  
							{  
								// Get the path of the application  
								NSString *resolvedPath = getResolvedAliasPath(aliasData);  
								
								if( [resolvedPath isEqualToString: [[NSBundle mainBundle] bundlePath]])
								{
									if( [theArch isEqualToString: @"i386"])
									{										
										NSAlert* alert = [[NSAlert new] autorelease];
										[alert setMessageText: NSLocalizedString(@"64-bit", nil)];
										[alert setInformativeText: NSLocalizedString(@"This version of OsiriX can run in 64-bit, but it is set to run in 32-bit. You can change this setting, by selecting the OsiriX icon in Applications folder, select 'Get Info' in Finder File menu and UNCHECK 'run in 32-bit mode'.", nil)];
										[alert setShowsSuppressionButton:YES ];
										[alert addButtonWithTitle: NSLocalizedString(@"Continue", nil)];
										[alert runModal];
										if ([[alert suppressionButton] state] == NSOnState)
											[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"hideAlertRunIn32bit"];
									}
								}
							}  
						}  
					}  
				}  
			}  
		}
}  

void exceptionHandler(NSException *exception)
{
    NSLog(@"%@", [exception reason]);
    NSLog(@"%@", [exception userInfo]);
	[AppController printStackTrace: exception];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

static NSDate *lastWarningDate = nil;


@implementation AppController

@synthesize checkAllWindowsAreVisibleIsOff, filtersMenu, windowsTilingMenuRows, windowsTilingMenuColumns, isSessionInactive, dicomBonjourPublisher = BonjourDICOMService;

- (void) pause { // __deprecated
	[[[BrowserController currentBrowser] database] lock]; // was checkIncomingLock
	sleep( 2);
	[[[BrowserController currentBrowser] database] unlock]; // was checkIncomingLock
}

// Plugins installation
- (void) installPlugins: (NSArray*) pluginsArray
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
		
		CFStringRef versionString = nil;
		if(bundleInfoDict != NULL)
			versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleVersion"));
		
		NSString *pluginBundleVersion = nil;
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
		
		if( bundleInfoDict)
			CFRelease( bundleInfoDict);
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
			
			BOOL move = YES;
			
			if(pathToDelete)
			{
				// first, try with NSFileManager
				
				if( [[NSFileManager defaultManager] removeFileAtPath: pathToDelete handler: nil] == NO)			// Please leave this line! ANR
				{
					NSMutableArray *args = [NSMutableArray array];
					[args addObject:@"-r"];
					[args addObject:pathToDelete];
					
					[[BLAuthentication sharedInstance] executeCommand:@"/bin/rm" withArgs:args];
				}
				
				[[NSFileManager defaultManager] removeFileAtPath: pathToDelete handler: nil];			// Please leave this line! ANR
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: pathToDelete])
				{
					NSRunAlertPanel( NSLocalizedString( @"Plugins Installation", nil), NSLocalizedString( @"Failed to remove previous version of the plugin.", nil), NSLocalizedString( @"OK", nil), nil, nil);
					move = NO;
				}
			}
			
			// move the new plugin to the plugin folder				
			if( move)
				[PluginManager movePluginFromPath:path toPath:destinationPath];
		}
		
		[PluginManager discoverPlugins];
		[PluginManager setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];
		
#ifndef OSIRIX_LIGHT
		// refresh the plugin manager window (if open)
		NSArray *winList = [NSApp windows];		
		for(NSWindow *window in winList)
		{
			if( [[window windowController] isKindOfClass:[PluginManagerController class]])
				[[window windowController] refreshPluginList];
		}
#endif
		
		NSRunInformationalAlertPanel(NSLocalizedString(@"Plugin Update Completed", @""), NSLocalizedString(@"All your plugins are now up to date. Restart OsiriX to use the new or updated plugins.", @""), NSLocalizedString(@"OK", @""), nil, nil);
	}
}


+(BOOL) hasMacOSXSnowLeopard
{
	OSErr						err;       
	SInt32						osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{
		if ( osVersion < 0x1060UL )
		{
			return NO;
		}
	}
	return YES;                   
}

+(BOOL) hasMacOSXLeopard
{
	OSErr						err;       
	SInt32						osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{
		if ( osVersion < 0x1050UL )
		{
			return NO;
		}
	}
	return YES;                   
}

+ (void) createNoIndexDirectoryIfNecessary:(NSString*) path { // __deprecated
	[[NSFileManager defaultManager] confirmNoIndexDirectoryAtPath:path];
}

+ (void) pause
{
	[[AppController sharedAppController] performSelectorOnMainThread: @selector( pause) withObject: nil waitUntilDone: NO];
}

+ (void) resetToolbars
{
	int numberOfScreens = [[NSScreen screens] count] + 1; //Just in case, we connect a second monitor when using OsiriX.
	
	for( int i = 0; i < numberOfScreens; i++)
	{
		if( toolbarPanel[ i]) [toolbarPanel[ i] release];
	}
	
	for( int i = 0; i < numberOfScreens; i++)
		toolbarPanel[ i] = [[ToolbarPanelController alloc] initForScreen: i];
	
/*	for( int i = 0; i < numberOfScreens; i++)
		[toolbarPanel[ i] fixSize];*/
}

+ (void) resizeWindowWithAnimation:(NSWindow*) window newSize: (NSRect) newWindowFrame
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"NSWindowsSetFrameAnimate"])
	{
		@try
		{
			NSDictionary *windowResize = [NSDictionary dictionaryWithObjectsAndKeys:
										 window, NSViewAnimationTargetKey,
										 [NSValue valueWithRect: newWindowFrame],
										 NSViewAnimationEndFrameKey,
										 nil];
			
			if( accumulateAnimations)
			{
				if( accumulateAnimationsArray == nil) accumulateAnimationsArray = [[NSMutableArray array] retain];
				[accumulateAnimationsArray addObject: windowResize];
			}
			else
			{
				[OSIWindowController setDontEnterWindowDidChangeScreen: YES];
				
				NSViewAnimation * animation = [[[NSViewAnimation alloc]  initWithViewAnimations: [NSArray arrayWithObjects: windowResize, nil]] autorelease];
				[animation setAnimationBlockingMode: NSAnimationBlocking];
				[animation setDuration: 0.15];
				[animation startAnimation];
			
				[OSIWindowController setDontEnterWindowDidChangeScreen: NO];
			}
		}
		@catch( NSException *e)
		{
			NSLog( @"resizeWindowWithAnimation exception: %@", e);
		}
	}
	else
	{
		[window setFrame: newWindowFrame display: YES];
	}
}

+ (void) displayImportantNotice:(id) sender
{
	if( lastWarningDate == nil || [lastWarningDate timeIntervalSinceNow] < -60*60*16) // 16 hours
	{
		int result = NSRunCriticalAlertPanel( NSLocalizedString( @"Important Notice", nil), NSLocalizedString( @"This version of OsiriX, being a free open-source software (FOSS), is not certified as a commercial medical device (FDA or CE-1) for primary diagnostic imaging.\r\rFor a FDA / CE-1 certified version, please check our web page:\r\rhttp://www.osirix-viewer.com/Certifications.html\r", nil), NSLocalizedString( @"I agree", nil), NSLocalizedString( @"Quit", nil), NSLocalizedString( @"Certifications", nil));
		
		if( result == NSAlertOtherReturn)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Certifications.html"]];
			
		else if( result != NSAlertDefaultReturn)
			[[AppController sharedAppController] terminate: self];
	}
	
	[lastWarningDate release];
	lastWarningDate = [[NSDate date] retain];
}

+ (BOOL) isKDUEngineAvailable
{
	return kdu_available();
}

- (NSString *)computerName
{
	return [(id)SCDynamicStoreCopyComputerName(NULL, NULL) autorelease];
}

- (NSString*) privateIP
{
	return [NSString stringWithCString:GetPrivateIP() encoding:NSUTF8StringEncoding];
}

- (IBAction)cancelModal:(id)sender
{
    [NSApp abortModal];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction)okModal:(id)sender
{
    [NSApp stopModal];
}

#ifndef OSIRIX_LIGHT
- (IBAction) autoQueryRefresh:(id)sender
{
	[[QueryController currentAutoQueryController] refreshAutoQR: sender];
}
#endif

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

-(IBAction)osirix64bit:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/OsiriX-64bit.html"]];
}

-(IBAction)sendEmail:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:rossetantoine@osirix-viewer.com"]]; 
}

-(IBAction)openOsirixWebPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
}

-(IBAction)help:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Learning.html"]];
}

-(IBAction)openOsirixDiscussion:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://groups.yahoo.com/group/osirix/"]];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

- (void) waitForPID: (NSNumber*) pidNumber
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int pid = [pidNumber intValue];
	int rc, state;
	BOOL threadStateChanged = NO;
	NSString *path = [NSString stringWithFormat: @"/tmp/process_state-%d", pid]; 
	
	do
	{
		if( threadStateChanged == NO)
		{
			if( [[NSFileManager defaultManager] fileExistsAtPath: path] && [[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] length] > 0)
			{
				[NSThread currentThread].status = [[NSThread currentThread].status stringByAppendingFormat: NSLocalizedString( @" Service: %@", nil), [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
				[NSThread sleepForTimeInterval: 1];
				threadStateChanged = YES;
			}
		}
	
		rc = waitpid( pid, &state, WNOHANG);
		[NSThread sleepForTimeInterval: 0.1];
	}
	while( rc >= 0);
	
	[pool release];
}

+ (int) numberOfSubOsiriXProcesses
{
	const int kPIDArrayLength = 100;

    pid_t MyArray [kPIDArrayLength];
    unsigned int NumberOfMatches;
    int Counter, Error;
	int number = 0;
	
    Error = GetAllPIDsForProcessName( [[[NSProcessInfo processInfo] processName] UTF8String], MyArray, kPIDArrayLength, &NumberOfMatches, NULL);
	
	if (Error == 0)
    {
        for (Counter = 0 ; Counter < NumberOfMatches ; Counter++)
        {
			if( MyArray[ Counter] != getpid())
				number++;
        } 
    }
	
	return number;
}

+ (void) cleanOsiriXSubProcesses
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
				
				char dir[ 1024];
				sprintf( dir, "%s-%d", "/tmp/lock_process", MyArray[ Counter]);
				unlink( dir);
			}
        } 
    }
}

- (void) setAETitleToHostname
{
	char s[_POSIX_HOST_NAME_MAX+1];
	gethostname(s,_POSIX_HOST_NAME_MAX);
	NSString *c = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
	NSRange range = [c rangeOfString: @"."];
	if( range.location != NSNotFound) c = [c substringToIndex: range.location];
	
	if( [c length] > 16)
		c = [c substringToIndex: 16];
	
	[[NSUserDefaults standardUserDefaults] setObject: c forKey:@"AETITLE"];
}

- (void) checkForRestartStoreSCPOrder: (NSTimer*) t
{
	if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/RESTARTOSIRIXSTORESCP"])
	{
		[NSThread sleepForTimeInterval: 1];
		[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/RESTARTOSIRIXSTORESCP" error: nil];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"]) // Only for server mode
		{
			NSLog( @"******* RESTARTOSIRIXSTORESCP : killDICOMListenerWait");
			[self killDICOMListenerWait: YES];
			
			[NSThread sleepForTimeInterval: 1];
						
			NSLog( @"******* RESTARTOSIRIXSTORESCP : restartSTORESCP");
			[self restartSTORESCP];
		}
	}
}

- (void) runPreferencesUpdateCheck:(NSTimer*) timer
{
	[updateTimer invalidate];
	[updateTimer release];
	updateTimer = nil;
	
	BOOL restartListener = NO;
	BOOL refreshDatabase = NO;
	BOOL refreshColumns = NO;
	BOOL recomputePETBlending = NO;
	BOOL refreshViewer = NO;
	BOOL revertViewer = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if( [NSThread isMainThread] == NO) return;
	
	NSDictionary *dictionaryRepresentation = [defaults dictionaryRepresentation];
	
	if( [dictionaryRepresentation isEqualToDictionary: previousDefaults]) return;
	
	NS_DURING
	
	if( [[previousDefaults valueForKey: @"DisplayDICOMOverlays"] intValue] != [defaults integerForKey: @"DisplayDICOMOverlays"])
		revertViewer = YES;
	if( [[previousDefaults valueForKey: @"ROITEXTNAMEONLY"] intValue] != [defaults integerForKey: @"ROITEXTNAMEONLY"])
		refreshViewer = YES;
	if( [[previousDefaults valueForKey: @"ROITEXTIFSELECTED"] intValue] != [defaults integerForKey: @"ROITEXTIFSELECTED"])
		refreshViewer = YES;
	if( [[previousDefaults valueForKey: @"PET Blending CLUT"] isKindOfClass: [NSString class]])
	{
		if ([[previousDefaults valueForKey: @"PET Blending CLUT"] isEqualToString: [defaults stringForKey: @"PET Blending CLUT"]] == NO) 
			recomputePETBlending = YES;
	}
	else NSLog( @"*** isKindOfClass NSString");
	if( [[previousDefaults valueForKey: @"COPYSETTINGS"] intValue] != [defaults integerForKey: @"COPYSETTINGS"])
		refreshViewer = YES;
	if( [[previousDefaults valueForKey: @"DBDateFormat2"] isKindOfClass:[NSString class]])
	{
		if( [[previousDefaults valueForKey: @"DBDateFormat2"] isEqualToString: [defaults stringForKey: @"DBDateFormat2"]] == NO)
			refreshDatabase = YES;
	}
	else NSLog( @"*** isKindOfClass NSString");
	if( [[previousDefaults valueForKey: @"DBDateOfBirthFormat2"] isKindOfClass:[NSString class]])
	{
		if( [[previousDefaults valueForKey: @"DBDateOfBirthFormat2"] isEqualToString: [defaults stringForKey: @"DBDateOfBirthFormat2"]] == NO)
			refreshDatabase = YES;
	}
	else NSLog( @"*** isKindOfClass NSString");
	if ([[previousDefaults valueForKey: @"DICOMTimeout"] intValue] != [defaults integerForKey: @"DICOMTimeout"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"UseHostNameForAETitle"] intValue] != [defaults integerForKey: @"UseHostNameForAETitle"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"preferredSyntaxForIncoming"] intValue] != [defaults integerForKey: @"preferredSyntaxForIncoming"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"httpXMLRPCServer"] intValue] != [defaults integerForKey: @"httpXMLRPCServer"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"httpXMLRPCServerPort"] intValue] != [defaults integerForKey: @"httpXMLRPCServerPort"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"httpWebServer"] intValue] != [defaults integerForKey: @"httpWebServer"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"httpWebServerPort"] intValue] != [defaults integerForKey: @"httpWebServerPort"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"encryptedWebServer"] intValue] != [defaults integerForKey: @"encryptedWebServer"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"LISTENERCHECKINTERVAL"] intValue] != [defaults integerForKey: @"LISTENERCHECKINTERVAL"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"SINGLEPROCESS"] intValue] != [defaults integerForKey: @"SINGLEPROCESS"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"activateCGETSCP"] intValue] != [defaults integerForKey: @"activateCGETSCP"])
		restartListener = YES;
	
	if( [[previousDefaults valueForKey: @"AETITLE"] isKindOfClass:[NSString class]])
	{
		if ([[previousDefaults valueForKey: @"AETITLE"] isEqualToString: [defaults stringForKey: @"AETITLE"]] == NO)
			restartListener = YES;
	}
	else NSLog( @"*** isKindOfClass NSString");
	if( [[previousDefaults valueForKey: @"STORESCPEXTRA"] isKindOfClass:[NSString class]])
	{
		if ([[previousDefaults valueForKey: @"STORESCPEXTRA"] isEqualToString: [defaults stringForKey: @"STORESCPEXTRA"]] == NO)
			restartListener = YES;
	}
	else NSLog( @"*** isKindOfClass NSString");
	if ([[previousDefaults valueForKey: @"AEPORT"] intValue] != [defaults integerForKey: @"AEPORT"])
		restartListener = YES;
	if( [[previousDefaults valueForKey: @"AETransferSyntax"] isKindOfClass:[NSString class]])
	{
		if ([[previousDefaults valueForKey: @"AETransferSyntax"] isEqualToString: [defaults stringForKey: @"AETransferSyntax"]] == NO)
			restartListener = YES;
	}
	else NSLog( @"*** isKindOfClass NSString");
	if ([[previousDefaults valueForKey: OsirixCanActivateDefaultDatabaseOnlyDefaultsKey] intValue] !=	[defaults integerForKey: OsirixCanActivateDefaultDatabaseOnlyDefaultsKey])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"STORESCP"] intValue] != [defaults integerForKey: @"STORESCP"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"USESTORESCP"] intValue] != [defaults integerForKey: @"USESTORESCP"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"HIDEPATIENTNAME"] intValue] != [defaults integerForKey: @"HIDEPATIENTNAME"])
		refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"COLUMNSDATABASE"] isEqualToDictionary:[defaults objectForKey: @"COLUMNSDATABASE"]] == NO)
		refreshColumns = YES;	
	if ([[previousDefaults valueForKey: @"SERIESORDER"] intValue] != [defaults integerForKey: @"SERIESORDER"])
		refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"KeepStudiesOfSamePatientTogether"] intValue] != [defaults integerForKey: @"KeepStudiesOfSamePatientTogether"])
		refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"NOINTERPOLATION"] intValue] != [defaults integerForKey: @"NOINTERPOLATION"])
		refreshViewer = YES;
	if ([[previousDefaults valueForKey: @"SOFTWAREINTERPOLATION"] intValue] != [defaults integerForKey: @"SOFTWAREINTERPOLATION"])
		refreshViewer = YES;
	if ([[previousDefaults valueForKey: @"publishDICOMBonjour"] intValue] != [defaults integerForKey: @"publishDICOMBonjour"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"STORESCPTLS"] intValue] != [defaults integerForKey: @"STORESCPTLS"])
		restartListener = YES;
	
	if( [defaults integerForKey: @"httpWebServer"] == 1 && [defaults integerForKey: @"httpWebServer"] != [[previousDefaults valueForKey: @"httpWebServer"] intValue])
	{
		if( [AppController hasMacOSXSnowLeopard] == NO)
			NSRunCriticalAlertPanel( NSLocalizedString( @"Unsupported", nil), NSLocalizedString( @"It is highly recommend to upgrade to MacOS 10.6 or higher to use the OsiriX Web Server.", nil), NSLocalizedString( @"OK", nil) , nil, nil);
	}
	
	[previousDefaults release];
	previousDefaults = [dictionaryRepresentation retain];
	
	if (refreshDatabase)
	{
		[[BrowserController currentBrowser] setDBDate];
		[[BrowserController currentBrowser] outlineViewRefresh];
	}
	
//	if( [(NSString*) [defaults valueForKey:OsirixWebPortalAddressDefaultsKey] length] == 0)
//		[defaults setValue: [[AppController sharedAppController] privateIP] forKey:OsirixWebPortalAddressDefaultsKey];
	
	if (restartListener)
	{
		NSString *c = [[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"];
		if( [c length] > 16)
		{
			c = [c substringToIndex: 16];
			[[NSUserDefaults standardUserDefaults] setObject: c forKey:@"AETITLE"];
		}
		
		if( showRestartNeeded == YES)
		{
			showRestartNeeded = NO;
			NSRunAlertPanel( NSLocalizedString( @"DICOM Listener", nil), NSLocalizedString( @"Restart OsiriX to apply these changes.", nil), NSLocalizedString( @"OK", nil), nil, nil);
		}
	}
	
	if (refreshColumns)	
		[[BrowserController currentBrowser] refreshColumns];
	
	if( recomputePETBlending)
		[DCMView computePETBlendingCLUT];
	
	[DCMPix checkUserDefaults: YES];
	
	if( refreshViewer || revertViewer)
	{
		NSArray *windows = [ViewerController getDisplayed2DViewers];
		
		for(ViewerController *v in windows)
		{
			[v needsDisplayUpdate];
			if( revertViewer)
				[v displayDICOMOverlays: self];
		}
		
		for(ViewerController *v in windows)
		{
			if([[v window] isMainWindow])
				[v copySettingsToOthers: self];
		}
	}
	
	#ifndef OSIRIX_LIGHT
	if( [defaults boolForKey: @"updateServers"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"updateServers"];
		[[QueryController currentQueryController] refreshSources];
		[[QueryController currentAutoQueryController] refreshSources];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixServerArrayChangedNotification object:nil];
	}
	#endif
	
	@try
	{
		{
			NSDictionary *defaultSettings = [[defaults arrayForKey: @"CompressionSettings"] objectAtIndex: 0];
			
			if( [[defaultSettings valueForKey: @"compression"] intValue] == 0 || [[defaultSettings valueForKey: @"modality"] isEqualToString: NSLocalizedString( @"default", nil)] == NO)
			{
				NSMutableDictionary *d = [[defaultSettings mutableCopy] autorelease];
				
				if( [[defaultSettings valueForKey: @"compression"] intValue] == 0) // same as default
					[d setObject: @"1" forKey: @"compression"];
				
				if( [[defaultSettings valueForKey: @"modality"] isEqualToString: NSLocalizedString( @"default", nil)] == NO) // item 0 IS default
					[d setObject: NSLocalizedString( @"default", nil) forKey: @"modality"];
				
				NSMutableArray *a = [[[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"] mutableCopy] autorelease];
				
				[a replaceObjectAtIndex: 0 withObject: d];
				
				[[NSUserDefaults standardUserDefaults] setObject: a forKey: @"CompressionSettings"];
			}
		}
		
		{
			NSDictionary *defaultSettings = [[defaults arrayForKey: @"CompressionSettingsLowRes"] objectAtIndex: 0];
			
			if( [[defaultSettings valueForKey: @"compression"] intValue] == 0 || [[defaultSettings valueForKey: @"modality"] isEqualToString: NSLocalizedString( @"default", nil)] == NO)
			{
				NSMutableDictionary *d = [[defaultSettings mutableCopy] autorelease];
				
				if( [[defaultSettings valueForKey: @"compression"] intValue] == 0) // same as default
					[d setObject: @"1" forKey: @"compression"];
				
				if( [[defaultSettings valueForKey: @"modality"] isEqualToString: NSLocalizedString( @"default", nil)] == NO) // item 0 IS default
					[d setObject: NSLocalizedString( @"default", nil) forKey: @"modality"];
				
				NSMutableArray *a = [[[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"] mutableCopy] autorelease];
				
				[a replaceObjectAtIndex: 0 withObject: d];
				
				[[NSUserDefaults standardUserDefaults] setObject: a forKey: @"CompressionSettingsLowRes"];
			}
		}
		
		if( [[[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"] length] == 0)
		{
			[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
			[[NSUserDefaults standardUserDefaults] setObject: nil forKey: @"SupplementaryBurnPath"];
		}
	}
	@catch (NSException *e) 
	{
		NSLog( @"%@", e);
	}
	
	Use_kdu_IfAvailable = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseKDUForJPEG2000"];
	
	#ifndef OSIRIX_LIGHT
	[DCMPixelDataAttribute setUse_kdu_IfAvailable: Use_kdu_IfAvailable];
	#endif
	
	[[BrowserController currentBrowser] setNetworkLogs];
	[[BrowserController currentBrowser] createDBContextualMenu]; // Update the routing rules
	[DicomFile resetDefaults];
	
	[DCMView setDefaults];
	[ROI loadDefaultSettings];
	
	if( restartListener)
	{
		if( [defaults boolForKey: @"UseHostNameForAETitle"])
		{
			[self setAETitleToHostname];
		}
	}
	
	NS_HANDLER
		NSLog(@"Exception updating prefs: %@", [localException description]);
	NS_ENDHANDLER
}

+ (void) checkForPreferencesUpdate: (BOOL) b
{
	checkForPreferencesUpdate = b;
}

- (void) preferencesUpdated: (NSNotification*) note
{
	if( [NSThread isMainThread] == NO) return;
	if( checkForPreferencesUpdate == NO) return;
	
	if( updateTimer)
		return;
	
	updateTimer = [[NSTimer scheduledTimerWithTimeInterval: 1 target: self selector:@selector(runPreferencesUpdateCheck:) userInfo:nil repeats: NO] retain];
}

-(void) UpdateOpacityMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
	if( mainOpacityMenu == nil)
	{
		mainMenu = [NSApp mainMenu];
		viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
		mainOpacityMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Opacity", nil)] submenu];
	}
	
	if( [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] != previousOpacityKeys)
	{
		previousOpacityKeys = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"];
		keys = [previousOpacityKeys allKeys];
		
		sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		i = [mainOpacityMenu numberOfItems];
		while(i-- > 0) [mainOpacityMenu removeItemAtIndex:0];   
		
		[mainOpacityMenu addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
		for( i = 0; i < [sortedKeys count]; i++)
		{
			[mainOpacityMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyOpacity:) keyEquivalent:@""];
		}
		[mainOpacityMenu addItem: [NSMenuItem separatorItem]];
		[mainOpacityMenu addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];
	}
	
	[[mainOpacityMenu itemWithTitle:[note object]] setState:NSOnState];
}

-(void) UpdateWLWWMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
	if( mainMenuWLWWMenu == nil)
	{
		mainMenu = [NSApp mainMenu];
		viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
		mainMenuWLWWMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
	}
	
	if( [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] != previousWLWWKeys)
	{
		previousWLWWKeys = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
		keys = [previousWLWWKeys allKeys];
		
		sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		i = [mainMenuWLWWMenu numberOfItems];
		while(i-- > 0) [mainMenuWLWWMenu removeItemAtIndex:0];   
		
		[mainMenuWLWWMenu addItemWithTitle:NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@"l"];
		
		[mainMenuWLWWMenu addItemWithTitle:NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
		[mainMenuWLWWMenu addItemWithTitle:NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@"y"];
		
		[mainMenuWLWWMenu addItem: [NSMenuItem separatorItem]];
		
		for( i = 0; i < [sortedKeys count]; i++)
		{
			[mainMenuWLWWMenu addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
		}
		[mainMenuWLWWMenu addItem: [NSMenuItem separatorItem]];
		[mainMenuWLWWMenu addItemWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
		[mainMenuWLWWMenu addItemWithTitle:NSLocalizedString(@"Set WL/WW manually", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	}
	
	[[mainMenuWLWWMenu itemWithTitle:[note object]] setState:NSOnState];
}

-(void) UpdateConvolutionMenu: (NSNotification*) note
{
	//*** Build the menu
	NSMenu      *mainMenu;
	NSMenu      *viewerMenu;
	short       i;
	NSArray     *keys;
	NSArray     *sortedKeys;
	
	if( mainMenuConvMenu == nil)
	{
		mainMenu = [NSApp mainMenu];
		viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
		mainMenuConvMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Convolution Filters", nil)] submenu];
	}
	
	if( [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] != previousConvKeys)
	{
		previousConvKeys = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"];
		keys = [previousConvKeys allKeys];
		
		sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		i = [mainMenuConvMenu numberOfItems];
		while(i-- > 0) [mainMenuConvMenu removeItemAtIndex:0];    
		
		[mainMenuConvMenu addItemWithTitle:NSLocalizedString(@"No Filter", nil) action:@selector (ApplyConv:) keyEquivalent:@""];
		
		[mainMenuConvMenu addItem: [NSMenuItem separatorItem]];
		
		for( i = 0; i < [sortedKeys count]; i++)
		{
			[mainMenuConvMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyConv:) keyEquivalent:@""];
		}
		[mainMenuConvMenu addItem: [NSMenuItem separatorItem]];
		[mainMenuConvMenu addItemWithTitle:NSLocalizedString(@"Add a Filter", nil) action:@selector (AddConv:) keyEquivalent:@""];
	}
}

-(void) UpdateCLUTMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
	if( mainMenuCLUTMenu == nil)
	{
		mainMenu = [NSApp mainMenu];
		viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
		mainMenuCLUTMenu = [[[viewerMenu itemWithTitle:NSLocalizedString(@"Color Look Up Table", nil)] submenu] retain];
    }

	if( [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] != previousCLUTKeys)
	{
		previousCLUTKeys = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"];
		keys = [previousCLUTKeys allKeys];
		
		sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		
		i = [mainMenuCLUTMenu numberOfItems];
		while(i-- > 0) [mainMenuCLUTMenu removeItemAtIndex:0];   
		
		[mainMenuCLUTMenu addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
		
		[mainMenuCLUTMenu addItem: [NSMenuItem separatorItem]];
		
		for( i = 0; i < [sortedKeys count]; i++)
		{
			[mainMenuCLUTMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
		}
		[mainMenuCLUTMenu addItem: [NSMenuItem separatorItem]];
		[mainMenuCLUTMenu addItemWithTitle:NSLocalizedString(@"Add a CLUT", nil) action:@selector (AddCLUT:) keyEquivalent:@""];
	}
	
	[[mainMenuCLUTMenu itemWithTitle:[note object]] setState:NSOnState];
}

#ifndef OSIRIX_LIGHT
- (void) checkSN64:(NSTimer*) t
{
	@try
	{
		if( checkSN64String && checkSN64Service)
		{
			[checkSN64Service setDelegate: self];
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: checkSN64String, @"sn", getMacAddress(), @"MAC", appStartingDate, @"startingDate", nil];
			
			NSLog( @"%@", dict);
			
			[checkSN64Service setTXTRecordData: [NSNetService dataFromTXTRecordDictionary: dict]];
			[checkSN64Service publishWithOptions: NSNetServiceNoAutoRename];
		}
	}
	
	@catch (NSException *e)
	{
		NSLog( @"checkSN64: %@", e);
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	if( checkSN64Service != aNetService && [[aNetService type] isEqualToString: @"_snosirix._tcp."])
	{
		if( [[checkSN64Service name] isEqualToString: [aNetService name]] == NO)
		{
			[aNetService retain];
			[aNetService setDelegate: self];
			[aNetService resolveWithTimeout: 5];
		}
	}
}
#endif

- (void) startDICOMBonjour:(NSTimer*) t
{
	NSLog( @"startDICOMBonjour");

	BonjourDICOMService = [[NSNetService alloc] initWithDomain:@"" type:@"_dicom._tcp." name: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] port:[[[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"] intValue]];
	
	NSString* description = [NSUserDefaults bonjourSharingName];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	if( description && [description length] > 0)
		[dict setValue: description forKey: @"serverDescription"];
	
	[dict setValue: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] forKey: @"AETitle"]; 
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"activateCGETSCP"])
		[dict setValue: @"YES" forKey: @"CGET"]; // TXTRECORD doesnt support NSNumber
	else
		[dict setValue: @"NO" forKey: @"CGET"];  // TXTRECORD doesnt support NSNumber
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"httpWebServer"] && [[NSUserDefaults standardUserDefaults] boolForKey: @"wadoServer"])
	{
		int port = [NSUserDefaults webPortalPortNumber];
		[dict setValue: @"YES" forKey: @"WADO"]; // TXTRECORD doesnt support NSNumber
		[dict setValue: [NSString stringWithFormat:@"%d", port] forKey: @"WADOPort"];
		[dict setValue: @"/wado" forKey: @"WADOURL"];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptedWebServer"])
			[dict setValue: @"https" forKey: @"WADOProtocol"];
		else
			[dict setValue: @"http" forKey: @"WADOProtocol"];
	}
	
	switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"preferredSyntaxForIncoming"])
	{
		case 0:
			[dict setValue: @"LittleEndianImplicit" forKey: @"preferredSyntax"];
		break;
		case 21:
			[dict setValue: @"JPEGProcess14SV1TransferSyntax" forKey: @"preferredSyntax"];
		break;
		case 26:
			[dict setValue: @"JPEG2000LosslessOnly" forKey: @"preferredSyntax"];
		break;
		case 27:
			[dict setValue: @"JPEG2000" forKey: @"preferredSyntax"];
		break;
		case 22:
			[dict setValue: @"RLELossless" forKey: @"preferredSyntax"];
		break;
		default:
			[dict setValue: @"LittleEndianExplicit" forKey: @"preferredSyntax"];
		break;
	}
	
	[BonjourDICOMService setTXTRecordData: [NSNetService dataFromTXTRecordDictionary: dict]];
		
	[BonjourDICOMService setDelegate: self];
	[BonjourDICOMService publish];
	
	[[DCMNetServiceDelegate sharedNetServiceDelegate] setPublisher: BonjourDICOMService];
}


#pragma mark-

-(void) restartSTORESCP
{
	NSLog(@"restartSTORESCP");
	
	// Is called restart because previous instances of storescp might exist and need to be killed before starting
	// This should be performed only if OsiriX is to handle storescp, depending on what is defined in the preferences
	// Key:@"STORESCP" is the corresponding switch
	
	@try {
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
				
				NSMutableArray *theArguments = [NSMutableArray array];
				NSTask *aTask = [[NSTask alloc] init];		
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
			NSString* path = [[DicomDatabase activeLocalDatabase] incomingDirPath];
			[[NSFileManager defaultManager] confirmNoIndexDirectoryAtPath:path];
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"USESTORESCP"])
			{
				if( [STORESCP tryLock])
				{
					[NSThread detachNewThreadSelector: @selector(startSTORESCP:) toTarget: self withObject: self];
					
					[STORESCP unlock];
				}
				else NSRunCriticalAlertPanel( NSLocalizedString( @"DICOM Listener Error", nil), NSLocalizedString( @"Cannot start DICOM Listener. Another thread is already running. Restart OsiriX.", nil), NSLocalizedString( @"OK", nil), nil, nil);
			}		
		}
		
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"])
		{
			[dcmtkQRSCPTLS release];
			dcmtkQRSCPTLS = nil;
			
			//make sure that there exist a receiver folder at @"folder" path
			NSString* path = [[DicomDatabase activeLocalDatabase] incomingDirPath];
			[[NSFileManager defaultManager] confirmNoIndexDirectoryAtPath:path];
			
			if( [STORESCPTLS tryLock])
			{
				[NSThread detachNewThreadSelector: @selector(startSTORESCPTLS:) toTarget: self withObject: self];
				
				[STORESCPTLS unlock];
			}
			else NSRunCriticalAlertPanel( NSLocalizedString( @"DICOM TLS Listener Error", nil), NSLocalizedString( @"Cannot start DICOM TLS Listener. Another thread is already running. Restart OsiriX.", nil), NSLocalizedString( @"OK", nil), nil, nil);
		}
	
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
	
	[BonjourDICOMService stop];
	[BonjourDICOMService release];
	BonjourDICOMService = nil;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"publishDICOMBonjour"])
	{
		//Start DICOM Bonjour 
		[NSTimer scheduledTimerWithTimeInterval: 5 target: self selector: @selector( startDICOMBonjour:) userInfo: nil repeats: NO];
	}
}

#ifndef OSIRIX_LIGHT

- (void)netServiceDidResolveAddress:(NSNetService *) aNetService
{
	if( [[aNetService type] isEqualToString: @"_snosirix._tcp."])
	{
		NSDictionary *d = [NSNetService dictionaryFromTXTRecordData: [aNetService TXTRecordData]];
		
		NSString *otherString = [[[NSString alloc] initWithData: [d valueForKey: @"sn"] encoding: NSUTF8StringEncoding] autorelease];
		NSString *otherMAC = [[[NSString alloc] initWithData: [d valueForKey: @"MAC"] encoding: NSUTF8StringEncoding] autorelease];
		NSString *otherStartingDate = [[[NSString alloc] initWithData: [d valueForKey: @"startingDate"] encoding: NSUTF8StringEncoding] autorelease];
		
		if( [checkSN64String length] > 4 && [otherString length] > 4)
		{
			NSString *myMacAddress = getMacAddress();
			
			NSLog( @"Other : %@ : %@ : %@", otherString, otherMAC, otherStartingDate);
			NSLog( @"Self  : %@ : %@ : %@", checkSN64String, myMacAddress, appStartingDate);
			
			if( otherMAC != nil && myMacAddress != nil && otherStartingDate != nil && appStartingDate != nil)
			{
				if( [checkSN64String isEqualToString: otherString] == YES && [otherMAC isEqualToString: myMacAddress] == NO && [otherStartingDate isEqualToString: appStartingDate] == NO)
				{
					[checkSN64Service release];
					checkSN64Service = nil;
					
					NSString *info = [NSString stringWithFormat: @"Other : %@ : %@\rSelf  : %@ : %@", otherString, otherMAC, checkSN64String, myMacAddress];
					
					NSRunCriticalAlertPanel( NSLocalizedString( @"64-bit Extension License", nil), [NSString stringWithFormat: NSLocalizedString( @"There is already another running OsiriX application using this 64-bit extension serial number. Buy a site license to run an unlimited number of OsiriX applications at the same time.\r\r%@", nil), info], NSLocalizedString( @"OK", nil), nil, nil);
					exit(0);
				}
			}
		}
	}
}

#endif

-(void) displayError: (NSString*) err
{
	NSRunCriticalAlertPanel( NSLocalizedString( @"Error", nil), err, NSLocalizedString( @"OK", nil), nil, nil);
}

-(void) displayListenerError: (NSString*) err
{
	NSLog( @"*** listener error (displayListenerError): %@", err);
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
	{
		NSAlert* alert = [[NSAlert new] autorelease];
		[alert setMessageText: NSLocalizedString( @"DICOM Listener Error", nil)];
		[alert setInformativeText: [err stringByAppendingString: @"\r\rThis error message can be hidden by activating the Server Mode (see Listener Preferences)"]];
		[alert addButtonWithTitle: NSLocalizedString(@"OK", nil)];
		
		[alert runModal];
	}
}

-(void) startSTORESCP:(id) sender
{
	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method

	#ifndef OSIRIX_LIGHT
	[STORESCP lock];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try 
	{
		
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseHostNameForAETitle"])
			[self setAETitleToHostname];
		
		NSString *c = [[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"];
		if( [c length] > 16)
		{
			c = [c substringToIndex: 16];
			[[NSUserDefaults standardUserDefaults] setObject: c forKey:@"AETITLE"];
		}
		
		NSString *aeTitle = [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"];
		int port = [[[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"] intValue];
		NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"TLSEnabled"];
		
		dcmtkQRSCP = [[DCMTKQueryRetrieveSCP alloc] initWithPort:port  aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params];
		[dcmtkQRSCP run];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[pool release];
	[STORESCP unlock];
	#endif
	
	return;
	
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
//	if( [[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] != nil &&
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

-(void) startSTORESCPTLS:(id) sender
{
	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method
#ifndef OSIRIX_LIGHT
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"])
	{
		[STORESCPTLS lock];
		
		@try 
		{
			NSString *c = [[NSUserDefaults standardUserDefaults] stringForKey:@"TLSStoreSCPAETITLE"];
			if( [c length] > 16)
			{
				c = [c substringToIndex: 16];
				[[NSUserDefaults standardUserDefaults] setObject: c forKey:@"TLSStoreSCPAETITLE"];
			}
			
			NSString *aeTitle = [[NSUserDefaults standardUserDefaults] stringForKey: @"TLSStoreSCPAETITLE"];
			int port = [[[NSUserDefaults standardUserDefaults] stringForKey: @"TLSStoreSCPAEPORT"] intValue];
			NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"TLSEnabled"];
			
			dcmtkQRSCPTLS = [[DCMTKQueryRetrieveSCP alloc] initWithPort:port aeTitle:aeTitle extraParamaters:params];
			[dcmtkQRSCPTLS run];
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		[STORESCPTLS unlock];
	}	
	
	[pool release];
#endif
	return;
}

// Manage osirix URL : osirix://

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *str = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *url = [NSURL URLWithString: str];
		
	if( [[url scheme] isEqualToString: @"osirix"])
	{
		NSString *content = [url resourceSpecifier];
		
		BOOL betweenQuotation = NO;
		
		NSMutableString *parsedContent = [NSMutableString string];
		for( int i = 0 ; i < content.length; i++)
		{
			if( [content characterAtIndex: i] == '\'')
				betweenQuotation = !betweenQuotation;
				
			if( [content characterAtIndex: i] == '?' && betweenQuotation)
				[parsedContent appendString: @"__question__"];
			else
				[parsedContent appendFormat: @"%c", [content characterAtIndex: i]];
		}
		
		// parse the URL to find the parameters (if any)
		
		NSArray *urlComponents = [NSArray array];
		for( NSString *s in [parsedContent componentsSeparatedByString: @"?"])
		{
			urlComponents = [urlComponents arrayByAddingObject: [s stringByReplacingOccurrencesOfString:@"__question__" withString:@"?"]];
		}
		
		NSString *parameterString = @"";
		if([urlComponents count] == 2)
		{
			parameterString = [[urlComponents lastObject] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		
			NSMutableDictionary *urlParameters = [NSMutableDictionary dictionary];
			if(![parameterString isEqualToString: @""])
			{
				NSMutableString *parsedParameterString = [NSMutableString string];
				for( int i = 0 ; i < parameterString.length; i++)
				{
					if( [parameterString characterAtIndex: i] == '\'')
						betweenQuotation = !betweenQuotation;
						
					if( [parameterString characterAtIndex: i] == '&' && betweenQuotation)
						[parsedParameterString appendString: @"__and__"];
					else
						[parsedParameterString appendFormat: @"%c", [parameterString characterAtIndex: i]];
				}
				
				NSArray *paramArray = [NSArray array];
				for( NSString *s in [parsedParameterString componentsSeparatedByString: @"&"])
				{
					paramArray = [paramArray arrayByAddingObject: [s stringByReplacingOccurrencesOfString:@"__and__" withString:@"&"]];
				}
				
				for(NSString *param in paramArray)
				{
					NSRange separatorRange = [param rangeOfString: @"="];
					
					if( separatorRange.location != NSNotFound)
					{
						@try
						{
							[urlParameters setObject: [[param substringFromIndex: separatorRange.location+1] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"'\""]] forKey: [param substringToIndex: separatorRange.location]];
						}
						@catch (NSException * e)
						{
							NSLog( @"**** exception in getUrl: %@", param);
						}
					}
				}
				
				if( [urlParameters objectForKey: @"methodName"]) // XML-RPC message
				{
					NSMutableDictionary *paramDict = [NSMutableDictionary dictionaryWithDictionary: urlParameters];
					
					[paramDict removeObjectForKey: @"methodName"];
					
					[XMLRPCServer processXMLRPCMessage: [urlParameters objectForKey: @"methodName"] httpServerMessage: nil HTTPServerRequest: nil version: (NSString*) kCFHTTPVersion1_0 paramDict: paramDict encoding: @"UTF-8"];
				}
				
				if( [urlParameters objectForKey: @"image"])
				{
					NSArray *components = [[urlParameters objectForKey: @"image"] componentsSeparatedByString:@"+"];
					
					if( [components count] == 2)
					{
						NSString *sopclassuid = [components objectAtIndex: 0];
						NSString *sopinstanceuid = [components objectAtIndex: 1];
						int frame = [[urlParameters objectForKey: @"frames"] intValue];
						
						BOOL succeeded = NO;
						
						//First try to find it in the selected study
						if( succeeded == NO)
						{
							NSMutableArray *allImages = [NSMutableArray array];
							[[BrowserController currentBrowser] filesForDatabaseOutlineSelection: allImages];
							
							NSManagedObjectContext *context = [[[BrowserController currentBrowser] database] managedObjectContext];
							
							[context lock];
							
							@try
							{
								NSPredicate	*request = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: sopinstanceuid]] customSelector: @selector( isEqualToSopInstanceUID:)];
								
								NSArray *imagesArray = [allImages filteredArrayUsingPredicate: request];
								
								if( [imagesArray count])
								{
									[[BrowserController currentBrowser] displayStudy: [[imagesArray lastObject] valueForKeyPath: @"series.study"] object: [imagesArray lastObject] command: @"Open"];
									succeeded = YES;
								}
							}
							@catch (NSException * e)
							{
								NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
							}
							
							[context unlock];
						}
						//Second option, try to find the uid in the ENTIRE db....
						
						if( succeeded == NO)
						{
							NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[[[[BrowserController currentBrowser] database] managedObjectModel] entitiesByName] objectForKey: @"Series"]];
							[dbRequest setPredicate: [NSPredicate predicateWithFormat: @"seriesSOPClassUID == %@", sopclassuid]];
							
							NSManagedObjectContext *context = [[[BrowserController currentBrowser] database] managedObjectContext];
							
							[context lock];
							
							WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString( @"Locating the image in the database...", nil)];
							[wait showWindow: self];
							[wait setCancel: YES];
							[wait start];
							
							@try
							{
								NSError	*error = nil;
								NSArray *allSeries = [[context executeFetchRequest: dbRequest error: &error] valueForKey: @"images"];
								
								NSMutableArray *allImages = [NSMutableArray array];
								for( NSSet *s in allSeries)
									[allImages addObjectsFromArray: [s allObjects]];
								
								NSData *searchedUID = [DicomImage sopInstanceUIDEncodeString: sopinstanceuid];
								DicomImage *searchUIDImage = nil;
								
								for( DicomImage *i in allImages)
								{
									if( [[i valueForKey: @"compressedSopInstanceUID"] isEqualToSopInstanceUID: searchedUID])
										searchUIDImage = i;
									
									if( searchUIDImage)
										break;
									
									if( [wait run] == NO)
										break;
								}
								
								if( searchUIDImage)
									[[BrowserController currentBrowser] displayStudy: [searchUIDImage valueForKeyPath: @"series.study"] object: searchUIDImage command: @"Open"];
							}
							@catch (NSException * e)
							{
								NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
							}
							[wait end];
							[wait close];
							[wait release];
							
							[context unlock];
						}
					}
				}
			}
		}
	}
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	long				i;
	NSMutableArray		*filesArray = [NSMutableArray array];
	NSMutableArray		*pluginsArray = [NSMutableArray array];
	NSFileManager       *defaultManager = [NSFileManager defaultManager];
	BOOL                isDirectory;

	if([filenames count] == 1) // for iChat Theatre... (drag & drop a DICOM file on the video chat window)
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
	
	[[BrowserController currentBrowser] subSelectFilesAndFoldersToAdd: filenames];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	[[BrowserController currentBrowser] syncReportsIfNecessary];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO) // Server mode
	{
		if( [[[BrowserController currentBrowser] window] isMiniaturized] == YES || [[[BrowserController currentBrowser] window] isVisible] == NO)
		{
			NSArray *winList = [NSApp windows];
			
			for( id loopItem in winList)
			{
				if( [[loopItem windowController] isKindOfClass:[ViewerController class]]) return;
			}
			
			[[[BrowserController currentBrowser] window] makeKeyAndOrderFront: self];
		}
	}
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"]) // Server mode
		return YES;
	
	if( flag == NO)
		[[[BrowserController currentBrowser] window] makeKeyAndOrderFront: self];
	
	return YES;
}

- (IBAction) killAllStoreSCU:(id) sender
{
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Abort Incoming DICOM processes...", nil)];
	[wait showWindow: self];
	
	BOOL hideListenerError_copy = [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"];
	
	[[NSUserDefaults standardUserDefaults] setBool: hideListenerError_copy forKey: @"copyHideListenerError"];
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"hideListenerError"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[NSFileManager defaultManager] createFileAtPath: @"/tmp/kill_all_storescu" contents: [NSData data] attributes: nil];
	[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 3]];
	
	[wait close];
	[wait release];
	
	unlink( "/tmp/kill_all_storescu");
	
	[[NSUserDefaults standardUserDefaults] setBool: hideListenerError_copy forKey: @"hideListenerError"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"copyHideListenerError"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) waitUnlockFileWithPID: (NSNumber*) nspid
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	BOOL fileExist = YES;
	int pid = [nspid intValue], inc = 0, rc = pid, state;
	char dir[ 1024];
	sprintf( dir, "%s-%d", "/tmp/lock_process", pid);
	
	do
	{
		FILE * pFile = fopen (dir,"r");
		if( pFile)
		{
			rc = waitpid( pid, &state, WNOHANG);	// Check to see if this pid is still alive?
			fclose (pFile);
		}
		else
			fileExist = NO;
		
		usleep( 100000);
		inc++;
	}
#define TIMEOUT 1200 // 1200*100000 = 120 secs
	while( fileExist == YES && inc < TIMEOUT && rc >= 0);
	
	if( inc >= TIMEOUT)
	{
		kill( pid, 15);
		NSLog( @"******* waitUnlockFile for %d sec", inc/10);
	}
	
	if( rc < 0)
	{
		kill( pid, 15);
		NSLog( @"******* waitUnlockFile : child process died...");
	}
	
	unlink( dir);
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"] == NO)
	{
		NSString *str = [NSString stringWithContentsOfFile:@"/tmp/error_message" encoding:NSUTF8StringEncoding error:nil];
		[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/error_message" error: nil];
		
		if( str && [str length] > 0)
			[[AppController sharedAppController] performSelectorOnMainThread: @selector( displayListenerError:) withObject: str waitUntilDone: NO];
	}
	
	[pool release];
}


- (void) applicationWillTerminate: (NSNotification*) aNotification
{
	unlink( "/tmp/kill_all_storescu");
	
	[webServer release];
	webServer = nil;
	
	[XMLRPCServer release];
	XMLRPCServer = nil;
	
	[self closeAllViewers: self];
	
	for (NSThread* t in [[ThreadsManager defaultManager] threads])
		[t cancel];
	
	
	[[BrowserController currentBrowser] browserPrepareForClose];

#ifndef OSIRIX_LIGHT
	[WebPortal finalizeWebPortalClass];
#endif

	[ROI saveDefaultSettings];
	
	[BonjourDICOMService stop];
	[BonjourDICOMService release];
	BonjourDICOMService = nil;

    quitting = YES;
    [theTask interrupt];
	[theTask release];
	
//	if (BUILTIN_DCMTK == YES)
//	{
//		[dcmtkQRSCP release];
//		dcmtkQRSCP = nil;
//
//		[dcmtkQRSCPTLS release];
//		dcmtkQRSCPTLS = nil;
//	}
	
	[self destroyDCMTK];
	
	[AppController cleanOsiriXSubProcesses];
	
	// DELETE the content of TEMP.noindex directory...
	NSString *tempDirectory = [[DicomDatabase activeLocalDatabase] tempDirPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory])
		for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tempDirectory error:NULL])
			[[NSFileManager defaultManager] removeItemAtPath:[tempDirectory stringByAppendingPathComponent:file] error:NULL];
	tempDirectory = [tempDirectory stringByDeletingPathExtension];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory])
		[[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:NULL];
	
	// DELETE THE DUMP DIRECTORY...
	NSString *dumpDirectory = [[DicomDatabase activeLocalDatabase] dumpDirPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory])
		[[NSFileManager defaultManager] removeItemAtPath:dumpDirectory error:NULL];
	
	// DELETE THE DECOMPRESSION.noindex DIRECTORY...
	NSString *decompressionDirectory = [[DicomDatabase activeLocalDatabase] decompressionDirPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:decompressionDirectory])
		[[NSFileManager defaultManager] removeItemAtPath:decompressionDirectory error:NULL];
	decompressionDirectory = [decompressionDirectory stringByDeletingPathExtension];
	if ([[NSFileManager defaultManager] fileExistsAtPath:decompressionDirectory])
		[[NSFileManager defaultManager] removeItemAtPath:decompressionDirectory error:NULL];
	
	// Delete all process_state files
	for (NSString* s in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: @"/tmp" error:nil])
		if ([s hasPrefix:@"process_state-"])
			[[NSFileManager defaultManager] removeItemAtPath:[@"/tmp" stringByAppendingPathComponent:s] error:nil];
	
	[NSSplitView saveSplitView];
	
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/zippedCD/" error:nil];
}


- (void) terminate :(id) sender
{
	if( [[BrowserController currentBrowser] shouldTerminate: sender] == NO) return;
	
	#ifndef OSIRIX_LIGHT
	[dcmtkQRSCP abort];
	[dcmtkQRSCPTLS abort];
	#endif
	
	[NSThread sleepForTimeInterval: 1];
	
	for( NSWindow *w in [NSApp windows])
		[w orderOut:sender];
	
	#ifndef OSIRIX_LIGHT
	[[QueryController currentQueryController] release];
	[[QueryController currentAutoQueryController] release];
	#endif
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[NSApp terminate: sender];
}

- (id)init
{
	self = [super init];
	OsiriX = appController = self;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[[[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kLocalDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]] stringByAppendingPathComponent:@"DLog.enable"]])
		[N2Debug setActive:YES];
	
	PapyrusLock = [[NSRecursiveLock alloc] init];
	STORESCP = [[NSRecursiveLock alloc] init];
	STORESCPTLS = [[NSRecursiveLock alloc] init];
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	#ifndef OSIRIX_LIGHT
	[IChatTheatreDelegate sharedDelegate];
	#endif
	
	return self;
}

+ (void) setUSETOOLBARPANEL: (BOOL) b
{
	USETOOLBARPANEL = b;
}

+ (BOOL) USETOOLBARPANEL
{
	return USETOOLBARPANEL;
}

+ (AppController*) sharedAppController
{
	return appController;
}
//
//#define EXTRACT_LONG_BIG(A,B)	{			\
//	(B) = (unsigned long)(A)[3]				\
//	  | (((unsigned long)(A)[2]) << 8)		\
//	  | (((unsigned long)(A)[1]) << 16)		\
//	  | (((unsigned long)(A)[0]) << 24);	\
//	}
//
//#define EXTRACT_LONG_BIG2(A,B)	{			\
//	(B) = (unsigned int)(A)[3]				\
//	  | (((unsigned int)(A)[2]) << 8)		\
//	  | (((unsigned int)(A)[1]) << 16)		\
//	  | (((unsigned int)(A)[0]) << 24);		\
//	}

+ (void) DNSResolve:(id) o
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	
	NSLog( @"start DNSResolve");
	
	for( NSString *s in [[DefaultsOsiriX currentHost] names])
	{
		NSLog( @"%@", s);
	}
	
	NSLog( @"end DNSResolve");
	
	[p release];
}

+ (NSString*) printStackTrace: (NSException*) e
{
	NSMutableString *r = [NSMutableString string];
	
	@try 
	{
		NSArray * addresses = [e callStackReturnAddresses];
		if( [addresses count])
		{
			void * backtrace_frames[[addresses count]];
			int i = 0;
			for (NSNumber * address in addresses)
			{
				backtrace_frames[i] = (void *)[address unsignedLongValue];
				i++;
			}
			
			char **frameStrings = backtrace_symbols(&backtrace_frames[0], [addresses count]);
			
			if(frameStrings != NULL)
			{
				int x;
				for(x = 0; x < [addresses count]; x++)
				{
					NSString *frame_description = [NSString stringWithUTF8String:frameStrings[ x]];
					NSLog( @"------- %@", frame_description);
					[r appendFormat: @"%@\r", frame_description];
				}
				free( frameStrings);
				frameStrings = nil;
			}
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	return r;
}

+ (BOOL) isFDACleared
{
	return NO;
}

+ (BOOL) willExecutePlugin
{
	BOOL returnValue = YES;
	
	if( [AppController isFDACleared])
	{
		NSString *alertSuppress = @"FDA Plugin warning";
		if ([[NSUserDefaults standardUserDefaults] boolForKey: alertSuppress] == NO)
		{
			NSAlert* alert = [[NSAlert new] autorelease];
			[alert setMessageText: NSLocalizedString(@"FDA & Plugins", nil)];
			[alert setInformativeText: NSLocalizedString(@"Plugins are not covered by the FDA clearance of OsiriX MD. Check with the plugin manufacturer, if it is cleared for a primary diagnostic usage.", nil)];
			[alert setShowsSuppressionButton:YES ];
			[alert addButtonWithTitle: NSLocalizedString(@"Continue", nil)];
			[alert addButtonWithTitle: NSLocalizedString(@"Cancel", nil)];
			
			if( [alert runModal] == NSAlertFirstButtonReturn)
				returnValue = YES;
			else
				returnValue = NO;
			
			if ([[alert suppressionButton] state] == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:alertSuppress];
		}
	}
	
	return returnValue;
}

static BOOL initialized = NO;
+ (void) initialize
{
//	int test = NSSwapHostIntToBig( 19191919);
//	unsigned char *ptr = (unsigned char*) &test;
//	long result;
//	
//	EXTRACT_LONG_BIG2( ptr, result);
//	NSLog(@"%d", result);
//	
//	EXTRACT_LONG_BIG( ptr, result);
//	NSLog(@"%d", result);

//	@try 
//	{
//		NSException *e = [NSException exceptionWithName: @"hallo" reason: @"prout" userInfo: nil];
//		[e raise];
//	}
//	@catch (NSException * e) 
//	{
//		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
//		#ifdef OSIRIX_VIEWER
//		[AppController printStackTrace: e];
//		#endif
//	}
	
//	NSSetUncaughtExceptionHandler( exceptionHandler);
//	
//	NSException *e = [NSException exceptionWithName: @"hallo" reason: @"prout" userInfo: nil];
//	[e raise];
	
	@try
	{
		if ( self == [AppController class] && initialized == NO)
		{
//			#if __LP64__
//			if( [[NSDate date] timeIntervalSinceDate: [NSCalendarDate dateWithYear:2009 month:12 day:20 hour:1 minute:1 second:1 timeZone:nil]] > 0 || [[NSUserDefaults standardUserDefaults] boolForKey:@"Outdated"])
//			{
//				NSRunCriticalAlertPanel(NSLocalizedString(@"Outdated Version", nil), NSLocalizedString(@"Please update your application. Available on the web site.", nil), NSLocalizedString(@"OK", nil), nil, nil);
//				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Outdated"];
//				[[NSUserDefaults standardUserDefaults] synchronize];
//				exit( 0);
//			}
//			#endif
						
			if( [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundlePackageType"] isEqualToString: @"APPL"])
			{
				[NSThread detachNewThreadSelector: @selector( DNSResolve:) toTarget: self withObject: nil];
				
				[AppController cleanOsiriXSubProcesses];
								
				initialized = YES;
				
				long	i;
				
				srandom(time(NULL));
				
				Altivec = HasAltiVec();
				//	if( Altivec == 0)
				//	{
				//		NSRunCriticalAlertPanel(@"Hardware Info", @"This application is optimized for Altivec - Velocity Engine unit, available only on G4/G5 processors.", @"OK", nil, nil);
				//		exit(0);
				//	}
				
				if ([AppController hasMacOSXLeopard] == NO)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"MacOS X", nil), NSLocalizedString(@"This application requires MacOS X 10.5 or higher. Please upgrade your operating system.", nil), NSLocalizedString(@"OK", nil), nil, nil);
					exit(0);
				}
				
				NSLog(@"Number of processors: %d", MPProcessors ());
				
				#ifdef NDEBUG
				#else
				NSLog( @"**** DEBUG MODE ****");
				#endif
				
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
				
				// ** REGISTER DEFAULTS DICTIONARY

				[[NSUserDefaults standardUserDefaults] registerDefaults: [DefaultsOsiriX getDefaults]];
//				[[NSUserDefaults standardUserDefaults] addSuiteNamed: @"com.rossetantoine.osirix"]; // Backward compatibility
				
				[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
				[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
				
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"is12bitPluginAvailable"];
//				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DONTCOPYWLWWSETTINGS"];
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ROITEXTNAMEONLY"];
				
				if( [[NSUserDefaults standardUserDefaults] objectForKey: @"copyHideListenerError"])
					[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey: @"copyHideListenerError"] forKey: @"hideListenerError"];
				
				pluginManager = [[PluginManager alloc] init];
				
				
				#ifdef MACAPPSTORE
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MACAPPSTORE"]; // Also modify in DefaultsOsiriX.m
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AUTHENTICATION"];
				[[NSUserDefaults standardUserDefaults] setObject:@"(~/Library/Application Support/OsiriX/)" forKey:@"DefaultDatabasePath"];
				#else
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MACAPPSTORE"]; // Also modify in DefaultsOsiriX.m
				[[NSUserDefaults standardUserDefaults] setObject:@"(Current User Documents folder)" forKey:@"DefaultDatabasePath"];
				#endif
				
				//Add Endoscopy LUT, WL/WW, shading to existing prefs
				// Shading Preset
				NSMutableArray *shadingArray = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"shadingsPresets"] mutableCopy] autorelease];
				NSDictionary *shading;
				BOOL exists = NO;
				
				exists = NO;
				for (shading in shadingArray)
				{
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
				for (shading in shadingArray)
				{
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
				for (shading in shadingArray)
				{
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
				
				// Endoscopy LUT
				NSMutableDictionary *cluts = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"CLUT"] mutableCopy] autorelease];
				// fix bad CLUT in previous versions
				NSDictionary *clut = [cluts objectForKey:@"Endoscopy"];
				if (!clut || [[[clut objectForKey:@"Red"] objectAtIndex:0] intValue] != 240)
				{
						NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
						NSMutableArray		*rArray = [NSMutableArray array];
						NSMutableArray		*gArray = [NSMutableArray array];
						NSMutableArray		*bArray = [NSMutableArray array];
						for( i = 0; i < 256; i++)  {
							[bArray addObject: [NSNumber numberWithLong:(195 - (i * 0.26))]];
							[gArray addObject: [NSNumber numberWithLong:(187 - (i *0.26))]];
							[rArray addObject: [NSNumber numberWithLong:(240 + (i * 0.02))]];
						}
					[aCLUTFilter setObject:rArray forKey:@"Red"];
					[aCLUTFilter setObject:gArray forKey:@"Green"];
					[aCLUTFilter setObject:bArray forKey:@"Blue"];
			
					// Points & Colors
					NSMutableArray *colors = [NSMutableArray array], *points = [NSMutableArray array];
					[points addObject:[NSNumber numberWithLong: 0]];
					[points addObject:[NSNumber numberWithLong: 255]];
			
					[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], nil]];
					[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];

			
					[aCLUTFilter setObject:colors forKey:@"Colors"];
					[aCLUTFilter setObject:points forKey:@"Points"];
						
					[cluts setObject:aCLUTFilter forKey:@"Endoscopy"];
					[[NSUserDefaults standardUserDefaults] setObject:cluts forKey:@"CLUT"];
				}
				
				//ww/wl
				NSMutableDictionary *wlwwValues = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"WLWW3"] mutableCopy] autorelease];
				NSDictionary *wwwl = [wlwwValues objectForKey:@"VR - Endoscopy"];
				if (!wwwl) {
					[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:-300], [NSNumber numberWithFloat:700], nil] forKey:@"VR - Endoscopy"];
					[[NSUserDefaults standardUserDefaults] setObject:wlwwValues forKey:@"WLWW3"];
				}
				
				// CREATE A TEMPORATY FILE DURING STARTUP
				
				NSString* path = [[DicomDatabase defaultBaseDirPath] stringByAppendingPathComponent:@"Loading"];
				
				if ([[NSFileManager defaultManager] fileExistsAtPath:path])
				{
					int result = NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX crashed during last startup", nil), NSLocalizedString(@"Previous crash is maybe related to a corrupt database or corrupted images.\r\rShould I run OsiriX in Protected Mode (recommended) (no images displayed)? To allow you to delete the crashing/corrupted images/studies.\r\rOr Should I rebuild the local database? All albums, comments and status will be lost.", nil), NSLocalizedString(@"Continue normally",nil), NSLocalizedString(@"Protected Mode",nil), NSLocalizedString(@"Rebuild Database",nil));
					
					if( result == NSAlertOtherReturn)
					{
						NEEDTOREBUILD = YES;
						COMPLETEREBUILD = YES;
					}
					if( result == NSAlertAlternateReturn) [DCMPix setRunOsiriXInProtectedMode: YES];
				}
				
				[path writeToFile:path atomically:NO encoding: NSUTF8StringEncoding error: nil];
				
				[AppController checkForPagesTemplate];
				
				Use_kdu_IfAvailable = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseKDUForJPEG2000"];
				
				#ifndef OSIRIX_LIGHT
				[DCMPixelDataAttribute setUse_kdu_IfAvailable: Use_kdu_IfAvailable];
				#endif
				
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
//					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportPatientsTemplate.html"] toPath:templateFile handler:nil];
//
//				templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportStudiesTemplate.html"];
//				NSLog(templateFile);
//				if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
//					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStudiesTemplate.html"] toPath:templateFile handler:nil];
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
//					[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStyle.css"] toPath:cssFile handler:nil];				
			}
		}
	}
	@catch( NSException *ne)
	{
		NSLog(@"+initialize exception: %@", [ne description]);
	}
	
}

#pragma mark-
#pragma mark growl

- (void) growlTitle:(NSString*) title description:(NSString*) description name:(NSString*) name
{
#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotUseGrowl"]) return;
	
	[GrowlApplicationBridge notifyWithTitle: title
							description: description 
							notificationName: name
							iconData: nil
							priority: 0
							isSticky: NO
							clickContext: nil];
#endif
#endif
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotUseGrowl"]) return nil;
	
    NSArray *notifications;
    notifications = [NSArray arrayWithObjects: @"newstudy", @"newfiles", @"delete", @"result", @"autorouting", @"autoquery", @"send", nil];

    NSDictionary *dict = nil;
	
#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                             notifications, GROWL_NOTIFICATIONS_ALL,
                         notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
#endif
#endif
    return (dict);
}

#pragma mark-

- (void) killDICOMListenerWait: (BOOL) wait
{
	[dcmtkQRSCP abort];
	[dcmtkQRSCPTLS abort];
	
	[self killAllStoreSCU: self];
	
	#ifndef OSIRIX_LIGHT
	if( dcmtkQRSCP)
		[QueryController echo: [self privateIP] port:[dcmtkQRSCP port] AET: [dcmtkQRSCP aeTitle]];
	if( dcmtkQRSCPTLS)
		[QueryController echo: [self privateIP] port:[dcmtkQRSCPTLS port] AET: [dcmtkQRSCPTLS aeTitle]];
	#endif
	
	[NSThread sleepForTimeInterval: 1.0];
	
	if( wait)
	{
		while( [dcmtkQRSCP running])
		{
			NSLog( @"waiting for listener to stop...");
			[NSThread sleepForTimeInterval: 0.1];
		}
		while( [dcmtkQRSCPTLS running])
		{
			NSLog( @"waiting for TLS listener to stop...");
			[NSThread sleepForTimeInterval: 0.1];
		}
	}
	
	[dcmtkQRSCP release];
	dcmtkQRSCP = nil;
	[dcmtkQRSCPTLS release];
	dcmtkQRSCPTLS = nil;
}

- (void) switchHandler:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:  NSWorkspaceSessionDidResignActiveNotification])
    {
		[[[BrowserController currentBrowser] database] save:nil];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"RunListenerOnlyIfActive"])
		{
			NSLog( @"----- OsiriX : session deactivation: STOP DICOM LISTENER FOR THIS SESSION");
			
			[self killDICOMListenerWait: YES];
			
			isSessionInactive = YES;
		}
    }
    else if ([[notification name] isEqualToString:  NSWorkspaceSessionDidBecomeActiveNotification])
    {
		[NSThread sleepForTimeInterval: 4];
		
		isSessionInactive = NO;
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"RunListenerOnlyIfActive"])
		{
			NSLog( @"----- OsiriX : session activation: START DICOM LISTENER FOR THIS SESSION");
			
			// [[BrowserController currentBrowser] loadDatabase: [[BrowserController currentBrowser] currentDatabasePath]]; // TODO: hmm
			
			[self restartSTORESCP];
		}
	}
}

- (BOOL) isStoreSCPRunning
{
	if( [dcmtkQRSCP running])
		return YES;
		
	if( [dcmtkQRSCPTLS running])
		return YES;
		
	return NO;
}

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
	unlink( "/tmp/kill_all_storescu");
	
	[NSSplitView loadSplitView];
	
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
	
//	if ([[NSUserDefaultsController sharedUserDefaultsController] boolForKey: @"ActivityWindowVisibleFlag"])
//		[[[ActivityWindowController defaultController] window] makeKeyAndOrderFront:self];	
	
//	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"UseDelaunayFor3DRoi"];	// By default, we always start with VTKDelaunay, PowerCrush has memory leaks and can crash with some 3D objects....

//	#if !__LP64__
//	[[[NSApplication sharedApplication] dockTile] setBadgeLabel: @"32-bit"];
//	[[[NSApplication sharedApplication] dockTile] display];
//	#else
//	[[[NSApplication sharedApplication] dockTile] setBadgeLabel: @"64-bit"];
//	[[[NSApplication sharedApplication] dockTile] display];
//	#endif

//	[AppController displayImportantNotice: self];

	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"TOOLKITPARSER3"] == 0 || [[NSUserDefaults standardUserDefaults] boolForKey:@"USEPAPYRUSDCMPIX3"] == NO)
	{
		[self growlTitle: NSLocalizedString( @"Warning!", nil) description: NSLocalizedString( @"DCM Framework is selected as the DICOM reader/parser. The performances of this toolkit are slower.", nil)  name:@"result"];
		NSLog( @"******** %@", NSLocalizedString( @"DCM Framework is selected as the DICOM reader/parser. The performances of this toolkit are slower.", nil));
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SINGLEPROCESS"])
	{
		[self growlTitle: NSLocalizedString( @"Warning!", nil) description: NSLocalizedString( @"DICOM Listener is in Single Process mode. The performances will be slower.", nil)  name:@"result"];
		NSLog( @"******** %@", NSLocalizedString( @"DICOM Listener is in Single Process mode. The performances will be slower.", nil));
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideAlertSingleProcess"] == NO)
		{
			NSAlert* alert = [[NSAlert new] autorelease];
			[alert setMessageText: NSLocalizedString( @"Warning!", nil)];
			[alert setInformativeText: NSLocalizedString( @"DICOM Listener is in Single Process mode. The performances will be slower. See Listener - Preferences.", nil)];
			[alert setShowsSuppressionButton:YES ];
			[alert addButtonWithTitle: NSLocalizedString( @"Continue", nil)];
			[alert runModal];
			if ([[alert suppressionButton] state] == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"hideAlertSingleProcess"];
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"checkForUpdatesPlugins"];
	}
	
	#ifndef MACAPPSTORE
	#ifndef OSIRIX_LIGHT
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"checkForUpdatesPlugins"])
		[NSThread detachNewThreadSelector:@selector(checkForUpdates:) toTarget:pluginManager withObject:pluginManager];
	
	[NSThread detachNewThreadSelector: @selector(checkForUpdates:) toTarget:self withObject: self];
	#endif
	#endif
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"]) // Server mode
		[[[BrowserController currentBrowser] window] orderOut: self];

#ifdef OSIRIX_LIGHT
	@try
	{
		int button = NSRunAlertPanel( NSLocalizedString( @"OsiriX Lite", nil), NSLocalizedString( @"This is the Lite version of OsiriX: many functions are not available. You can download the full version of OsiriX on the Internet.", nil), NSLocalizedString( @"Continue", nil), NSLocalizedString( @"Download", nil), nil);
	
		if (NSCancelButton == button)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
	}
	@catch (NSException * e)
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
		exit( 0);
	}
	
#endif
	
	
//	NSString *source = [NSString stringWithContentsOfFile: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"]];
//	
//	NSArray *lines = [source componentsSeparatedByString: @"\n"];
//	
//	NSMutableDictionary *nameDictionary = [NSMutableDictionary dictionary], *tagDictionary = [NSMutableDictionary dictionary];
//	
//	for( NSString *l in lines)
//	{
//		if( [l hasPrefix: @"#"] == NO)
//		{
//			NSArray *f = [l componentsSeparatedByString: @"\t"];
//			
//			if( [f count] == 5)
//			{
//				NSString *grel = [[f objectAtIndex: 0] stringByReplacingOccurrencesOfString: @"(" withString:@""];
//				grel = [grel stringByReplacingOccurrencesOfString: @")" withString:@""];
//				grel = [grel uppercaseString];
//				
//				if( [grel length] >= 9 && [grel characterAtIndex:4] == ',')
//				{
//					grel = [grel substringToIndex: 9];
//					
//					NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys: [f objectAtIndex: 2], @"Description", [f objectAtIndex: 3], @"VM", [f objectAtIndex: 1], @"VR", nil];	//[f objectAtIndex: 4], @"Version", nil];
//					
//					[tagDictionary setObject: d forKey: grel];
//					
//					[nameDictionary setObject: grel forKey: [f objectAtIndex: 2]];
//				}
//			}
//			else
//				NSLog( @"%@", f);
//		}
//	}
//	
//	[tagDictionary writeToFile: @"/tmp/tagDictionary.plist" atomically: YES];
//	[nameDictionary writeToFile: @"/tmp/nameDictionary.plist" atomically: YES];
//	warning : patientssex -> patientsex, patientsname -> patientname, ...
	
//	<?xml version="1.0" encoding="UTF-8"?>
//	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//	<plist version="1.0">
//	<dict>
//	<key>Description</key>
//	<string>PhilipsFactor</string>
//	<key>VM</key>
//	<string>1</string>
//	<key>VR</key>
//	<string>DS</string>
//	</dict>
//	</plist>
	
//	NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData: [NSData dataWithContentsOfFile: @"/tmp/test.jp2"]];
//	
//	NSUInteger pix;
//	
//	[rep getPixel: &pix atX: 2 y: 2];
//	
//	NSLog( @"%@", rep);
}

- (void) checkForOsirixMimeType
{
	NSString *path = @"~/Library/Preferences/com.apple.LaunchServices.plist";
	
	NSDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile: [path stringByExpandingTildeInPath]];

	for( NSDictionary* handler in [dict objectForKey: @"LSHandlers"])
	{
		if( [[handler objectForKey: @"LSHandlerURLScheme"] isEqualToString: @"dicom"])
		{
			return;
		}
	}
	
	NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary: dict];
	
	NSDictionary *handlerForOsiriX = [NSDictionary dictionaryWithObjectsAndKeys: @"com.rossetantoine.osirix", @"LSHandlerRoleAll", @"dicom", @"LSHandlerURLScheme", nil];
	
	[mutableDict setObject: [[dict objectForKey: @"LSHandlers"] arrayByAddingObject: handlerForOsiriX] forKey: @"LSHandlers"];
	
	[[NSFileManager defaultManager] removeItemAtPath: [path stringByExpandingTildeInPath]  error: nil];
	[mutableDict writeToFile: [path stringByExpandingTildeInPath]  atomically: YES];
}

- (void) applicationWillFinishLaunching: (NSNotification *) aNotification
{
	if( [NSDate timeIntervalSinceReferenceDate] - [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastDate32bitPipelineCheck"] > 60L*60L*24L*150L) // 150 days
	{
		[[NSUserDefaults standardUserDefaults] setDouble: [NSDate timeIntervalSinceReferenceDate] forKey: @"lastDate32bitPipelineCheck"];
		[self verifyHardwareInterpolation];
	}
	
	BOOL dialog = NO;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/"] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/" attributes: nil];
	
	if( [[NSUserDefaults standardUserDefaults] valueForKey: @"timeZone"])
	{
		if( [[NSUserDefaults standardUserDefaults] integerForKey: @"timeZone"] != [[NSTimeZone localTimeZone] secondsFromGMT])
		{
		//	NSLog( @"***** Time zone has changed: this modification can affect study dates, study times and birth dates!");
		//	[NSTimeZone setDefaultTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: [[NSUserDefaults standardUserDefaults] integerForKey: @"timeZone"]]];
		}
	}
	else [[NSUserDefaults standardUserDefaults] setInteger: [[NSTimeZone localTimeZone] secondsFromGMT] forKey: @"timeZone"];
	
//	NSLog(@"%s", __PRETTY_FUNCTION__, nil);
	
	if( dialog == NO)
	{
		
	}
	
	#ifndef OSIRIX_LIGHT
	#ifndef MACAPPSTORE
	@try
	{
		[[ILCrashReporter defaultReporter] launchReporterForCompany:@"OsiriX Developers" reportAddr:@"crash@osirix-viewer.com"];
	}
	@catch (NSException *e)
	{
		NSLog( @"**** Exception ILCrashReporter: %@", e);
	}
	#endif
	#endif
	
	[PluginManager setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];
    
	theTask = nil;
	
	appController = self;
	[self initDCMTK];
	[self restartSTORESCP];
	
	[NSTimer scheduledTimerWithTimeInterval: 2 target: self selector: @selector( checkForRestartStoreSCPOrder:) userInfo: nil repeats: YES];
	
	[DicomDatabase initializeDicomDatabaseClass];
	[BrowserController initializeBrowserControllerClass];
	#ifndef OSIRIX_LIGHT
	[WebPortal initializeWebPortalClass];
	#endif
	
	#ifndef OSIRIX_LIGHT
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"httpXMLRPCServer"]) {
		if(XMLRPCServer == nil) XMLRPCServer = [[XMLRPCMethods alloc] init];
	}
	#endif
	
	#if __LP64__
	appStartingDate = [[[NSDate date] description] retain];
	checkSN64Service = [[NSNetService alloc] initWithDomain:@"" type:@"_snosirix._tcp." name: [self privateIP] port: 8486];
	checkSN64String = [[NSString stringWithContentsOfFile: [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent: @".sn64"]] retain];
	if( checkSN64String == nil)
		checkSN64String = [[NSString stringWithContentsOfFile: [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent: @"sn64"]] retain];
	
	NSNetServiceBrowser *checkSN64Browser = [[NSNetServiceBrowser alloc] init];
	[checkSN64Browser setDelegate:self];
	[checkSN64Browser searchForServicesOfType:@"_snosirix._tcp." inDomain:@""];
	
	[NSTimer scheduledTimerWithTimeInterval: 5 target: self selector: @selector( checkSN64:) userInfo: nil repeats: NO];
	#endif
	
	#ifndef OSIRIX_LIGHT
	#ifndef MACAPPSTORE
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"doNotUseGrowl"] == NO)
	{
		[GrowlApplicationBridge setGrowlDelegate:self];
		
		if( [GrowlApplicationBridge isGrowlInstalled] == NO)
		{
			NSString *alertSuppress = @"growl info";
			if ([[NSUserDefaults standardUserDefaults] boolForKey: alertSuppress] == NO)
			{
				dialog = YES;
				
				NSAlert* alert = [[NSAlert new] autorelease];
				[alert setMessageText: NSLocalizedString(@"Growl !", nil)];
				[alert setInformativeText: NSLocalizedString(@"Did you know that OsiriX supports Growl? An amazing notification system for MacOS. You can download it for free on Internet.", nil)];
				[alert setShowsSuppressionButton:YES ];
				[alert addButtonWithTitle: NSLocalizedString(@"Continue", nil)];
				[alert addButtonWithTitle: NSLocalizedString(@"Download Growl", nil)];
				
				if( [alert runModal] == NSAlertFirstButtonReturn)
				{
					
				}
				else
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info"]];
				
				if ([[alert suppressionButton] state] == NSOnState)
					[[NSUserDefaults standardUserDefaults] setBool:YES forKey:alertSuppress];
			}
		}
	}
	#endif
	#endif
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: OsirixUpdateWLWWMenuNotification
             object: nil];
    [nc addObserver: self
           selector: @selector(UpdateConvolutionMenu:)
               name: OsirixUpdateConvolutionMenuNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: OsirixUpdateCLUTMenuNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(UpdateOpacityMenu:)
               name: OsirixUpdateOpacityMenuNotification
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: NSLocalizedString(@"Linear Table", nil) userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: NSLocalizedString(@"No CLUT", nil) userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: NSLocalizedString(@"Other", nil) userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object:NSLocalizedString( @"No Filter", nil) userInfo: nil];
	
	[AppController resetToolbars];
	
//	if( USETOOLBARPANEL) [[toolbarPanel window] makeKeyAndOrderFront:self];
	
// Increment the startup counter.
	
	long startCount = [[NSUserDefaults standardUserDefaults] integerForKey: @"STARTCOUNT"];
	[[NSUserDefaults standardUserDefaults] setInteger: startCount+1 forKey: @"STARTCOUNT"];
	
	if (startCount == 0) // Replaces FIRSTTIME.
	{
		switch( NSRunInformationalAlertPanel( NSLocalizedString(@"OsiriX Updates", nil), NSLocalizedString( @"Would you like to activate automatic checking for updates?", nil), NSLocalizedString( @"Yes", nil), NSLocalizedString( @"No", nil), nil))
		{
			case 0:
				[[NSUserDefaults standardUserDefaults] setObject: @"NO" forKey: @"CheckOsiriXUpdates4"];
			break;
		}
	}
	else
	{
		if (![[NSUserDefaults standardUserDefaults] boolForKey: @"SURVEYDONE5"])
		{
//			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"STARTCOUNT2"] > 20)
//			{
//				switch( NSRunInformationalAlertPanel(@"OsiriX", @"Thank you for using OsiriX!\rDo you agree to answer a small survey to improve OsiriX?", @"Yes, sure!", @"Maybe next time", nil))
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
			
//			if( [[NSCalendarDate dateWithYear:2009 month:10 day:14 hour:12 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]] timeIntervalSinceNow] > 0 &&
//				[[NSCalendarDate dateWithYear:2009 month:9 day:1 hour:12 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]] timeIntervalSinceNow] < 0)
//			{
//				Survey *survey = [[Survey alloc] initWithWindowNibName:@"Survey"];
//				[[survey window] center];
//				[survey showWindow: self];
//			}
		}
		else
		{
//			[self about:self];
//			//fade out Splash window automatically 
//			[NSTimer scheduledTimerWithTimeInterval:2.0 target:splashController selector:@selector(windowShouldClose:) userInfo:nil repeats:0]; 
		}
	}
	
		
	//Checks for Bonjour enabled dicom servers. Most likely other copies of OsiriX
	[self startDICOMBonjourSearch];
	
	previousDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
	showRestartNeeded = YES;
		
	[[NSNotificationCenter defaultCenter]	addObserver: self
											   selector: @selector(preferencesUpdated:)
												   name: NSUserDefaultsDidChangeNotification
												 object: nil];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"SAMESTUDY"];
		
	[[NSUserDefaults standardUserDefaults] setBool: [AppController hasMacOSXSnowLeopard] forKey: @"hasMacOSXSnowLeopard"];
	
	if( [AppController hasMacOSXSnowLeopard] == NO)
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"EncryptCD"];
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"encryptForExport"];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideNoSnowLeopardWarning"] == NO)
		{
			NSAlert* alert = [[NSAlert new] autorelease];
			[alert setMessageText: NSLocalizedString( @"Mac OS Version", nil)];
			[alert setInformativeText: NSLocalizedString( @"You should upgrade to MacOS 10.6 or higher, for better performances, more features and more stability.", nil)];
			[alert setShowsSuppressionButton:YES ];
			[alert addButtonWithTitle: NSLocalizedString( @"Continue", nil)];
			[alert runModal];
			if ([[alert suppressionButton] state] == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"hideNoSnowLeopardWarning"];
		}
	}
	
	[self initTilingWindows];

	#if __LP64__
	#else
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideAlertRunIn32bit"] == NO)
	{
		for( NSNumber *arc in [[NSBundle mainBundle] executableArchitectures])
		{
			if( [arc integerValue] == NSBundleExecutableArchitectureX86_64)
				dumpLSArchitecturesForX86_64();
		}
	}
	#endif
	
//	[self checkForOsirixMimeType];
	
//	*(long*)0 = 0xDEADBEEF;	// Test for ILCrashReporter
	
//	[html2pdf pdfFromURL: @"http://zimbra.latour.ch"];

	if( [AppController isKDUEngineAvailable])
		NSLog( @"/*\\ /*\\ KDU Engine AVAILABLE /*\\ /*\\");
	else
		NSLog( @"KDU Engine NOT available");
	
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
	//		[oPanel runModalForDirectory:nil file:nil types:nil];
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
	//				 if (nb >= nil && nb < 256L &&
	//					 r >= nil && r < 256L &&
	//					 g >= nil && g < 256L &&
	//					 b >= nil && b < 256L) 
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
	//				 if (nb >= nil && nb < 256L &&
	//					 r >= nil && r <= 65535L &&
	//					 g >= nil && g <= 65535L &&
	//					 b >= nil && b <= 65535L) 
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
	//			NSMutableArray		*xrArray = [NSMutableArray array];
	//			for( i = 0; i < 256; i++)
	//			{
	//				[xrArray addObject: [NSNumber numberWithLong: red[ i]]];
	//			}
	//			[xaCLUTFilter setObject:xrArray forKey:@"Red"];
	//			
	//			NSMutableArray		*xgArray = [NSMutableArray array];
	//			for( i = 0; i < 256; i++)
	//			{
	//				[xgArray addObject: [NSNumber numberWithLong: green[ i]]];
	//			}
	//			[xaCLUTFilter setObject:xgArray forKey:@"Green"];
	//			
	//			NSMutableArray		*xbArray = [NSMutableArray array];
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
	[msg retain];
	
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	if( [msg isEqualToString:@"LISTENER"])
	{
		NSRunAlertPanel( NSLocalizedString( @"DICOM Listener Error", nil), NSLocalizedString( @"OsiriX listener cannot start. Is the Port valid? Is there another process using this Port?\r\rSee Listener - Preferences.", nil), NSLocalizedString( @"OK", nil), nil, nil);
	}
	
	if( [msg isEqualToString:@"UPTODATE"])
	{
		NSRunAlertPanel( NSLocalizedString( @"OsiriX is up-to-date", nil), NSLocalizedString( @"You have the most recent version of OsiriX.", nil), NSLocalizedString( @"OK", nil), nil, nil);
	}
	
	if( [msg isEqualToString:@"ERROR"])
	{
		NSRunAlertPanel( NSLocalizedString( @"No Internet connection", nil), NSLocalizedString( @"Unable to check latest version available.", nil), NSLocalizedString( @"OK", nil), nil, nil);
	}
	
	if( [msg isEqualToString:@"UPDATE"])
	{
		#if __LP64__
		int button = NSRunAlertPanel( NSLocalizedString( @"New Version Available", nil), NSLocalizedString( @"A new version of OsiriX is available. Would you like to download the new version now?\r\rAs a user of OsiriX 64-bit, this OsiriX update will require the new 64-bit extension to run in 64-bit.", nil), NSLocalizedString( @"Download", nil), NSLocalizedString( @"Continue", nil), nil);
		
		if (NSOKButton == button)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://pixmeo.pixmeo.com/login"]];
		
		#else
		int button = NSRunAlertPanel( NSLocalizedString( @"New Version Available", nil), NSLocalizedString( @"A new version of OsiriX is available. Would you like to download the new version now?", nil), NSLocalizedString( @"Download", nil), NSLocalizedString( @"Continue", nil), nil);
		
		if (NSOKButton == button)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com"]];
			
		#endif
	}
	
	[pool release];
	
	[msg release];
}

- (id) splashScreen
{
	WaitRendering *wait = nil;
	
	#ifdef OSIRIX_LIGHT
	wait = [[[WaitRendering alloc] init: NSLocalizedString(@"Starting OsiriX Lite...", nil)] autorelease];
	#else
	if( sizeof( long) == 8)
		wait = [[[WaitRendering alloc] init: NSLocalizedString(@"Starting OsiriX 64-bit", nil)] autorelease];
	else
		wait = [[[WaitRendering alloc] init: NSLocalizedString(@"Starting OsiriX 32-bit", nil)] autorelease];
	#endif

	return wait;
}

#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
- (IBAction) checkForUpdates: (id) sender
{
	NSURL *url;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( sender != self) verboseUpdateCheck = YES;
	else verboseUpdateCheck = NO;
	
	if( [AppController hasMacOSXLeopard])
		url = [NSURL URLWithString:@"http://www.osirix-viewer.com/versionLeopard.xml"];
	else
		url = [NSURL URLWithString:@"http://www.osirix-viewer.com/version.xml"];
	
	if( url)
	{
		NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
		NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL: url];
		NSString *latestVersionNumber = [productVersionDict valueForKey:@"OsiriX"];
		
		if (productVersionDict && currVersionNumber && latestVersionNumber)
		{
			if ([latestVersionNumber intValue] <= [currVersionNumber intValue])
			{
				if (verboseUpdateCheck)
				{
					[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"UPTODATE" waitUntilDone: NO];
				}
			}
			else
			{
				if( ([[NSUserDefaults standardUserDefaults] boolForKey: @"CheckOsiriXUpdates4"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO) || verboseUpdateCheck == YES)
				{
					[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"UPDATE" waitUntilDone: NO];
				}
			}
		}
		else
		{
			if (verboseUpdateCheck)
			{
				[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"ERROR" waitUntilDone: NO];
			}
		}
	}
	
	[pool release];
}
#endif
#endif

- (void) URL: (NSURL*) sender resourceDidFailLoadingWithReason: (NSString*) reason
{
	if (verboseUpdateCheck)
		NSRunAlertPanel( NSLocalizedString( @"No connection available", nil), reason, NSLocalizedString( @"OK", nil), nil, nil);
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

-(IBAction)showPreferencePanel:(id)sender {
	PreferencesWindowController* prefsController = NULL;
	
	for (NSWindow* window in [NSApp windows])
		if ([window.windowController isKindOfClass:[PreferencesWindowController class]]) {
			prefsController = window.windowController;
			break;
		}
	
	if (!prefsController)
		prefsController = [[PreferencesWindowController alloc] init];
	
	[prefsController showWindow:sender];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

-(void) dealloc
{
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
	
    [browserController release];
	[dcmtkQRSCP release];
	dcmtkQRSCP = nil;
	
	[dcmtkQRSCPTLS release];
	dcmtkQRSCPTLS = nil;
	
	#ifndef OSIRIX_LIGHT
	[IChatTheatreDelegate releaseSharedDelegate];
	#endif
	
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
	
	return nil;
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

- (NSScreen *)dbScreen
{
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
	else viewers = [NSScreen screens]; 
	
	if( [viewers count] == 1) return viewers;
	
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
		while (screen = [enumerator nextObject])
		{
			if (x < [screen frame].origin.x)
			{
				position = current;
				current ++;
				break;
			}
		}
		
		[arrangedViewers insertObject:aScreen atIndex:position];
	}
	
	if( [self dbScreen] == nil)
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
	if( checkAllWindowsAreVisibleIsOff) return;

	NSArray *winList = [NSApp windows];
	NSWindow *last = nil;
	
	for( NSWindow *loopItem in winList)
	{
		if( [[loopItem windowController] isKindOfClass:[ViewerController class]])
		{
			if( [[loopItem windowController] windowWillClose] == NO)
			{
				last = loopItem;
				[loopItem orderFront: self];
				[[loopItem windowController] checkBuiltMatrixPreview];
				[[loopItem windowController] redrawToolbar];	// To avoid the drag & remove item bug - multiple windows
			}
		}
	}
	
	if( makeKey)
	{
		[last makeKeyAndOrderFront: self];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncPreviewList"])
			[[last windowController] syncThumbnails];
	}
}

- (void) checkAllWindowsAreVisible:(id) sender
{
	[self checkAllWindowsAreVisible: sender makeKey: NO];
}

- (void) displayViewers: (NSArray*) viewers monitorIndex: (int) monitorIndex screens: (NSArray*) screens numberOfMonitors:(int) numberOfMonitors rowsPerScreen:(int) rowsPerScreen columnsPerScreen:(int) columnsPerScreen
{
	BOOL strechWindows = [[NSUserDefaults standardUserDefaults] boolForKey: @"StrechWindows"];
	BOOL lastScreen = NO;
	
	int OcolumnsPerScreen = columnsPerScreen;
	int OrowsPerScreen = rowsPerScreen;
	
	for( int i = 0; i < [viewers count]; i++)
	{
		if( monitorIndex == numberOfMonitors-1 && strechWindows == YES && lastScreen == NO)
		{
			int remaining = [viewers count] - i;
		
			lastScreen = YES;
		
			while( rowsPerScreen*columnsPerScreen > remaining)
			{
				rowsPerScreen--;
				
				if( rowsPerScreen*columnsPerScreen > remaining)
					columnsPerScreen--;
			}
		
			while( rowsPerScreen*columnsPerScreen < remaining)
				rowsPerScreen++;
		}
		
		int posInScreen = i % (OcolumnsPerScreen*OrowsPerScreen);
		int row = posInScreen / columnsPerScreen;
		int column = posInScreen % columnsPerScreen;
		
		NSScreen *screen = [screens objectAtIndex: monitorIndex];
		NSRect frame = [screen visibleFrame];

		if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController exposedHeight];
		frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];

		int temp;

		temp = frame.size.width / columnsPerScreen;
		frame.size.width = temp * columnsPerScreen;

		temp = frame.size.height / rowsPerScreen;
		frame.size.height = temp * rowsPerScreen;

		NSRect visibleFrame = frame;
		frame.size.width /= columnsPerScreen;
		frame.origin.x += (frame.size.width * column);

		frame.size.height /= rowsPerScreen;
		frame.origin.y += frame.size.height * ((rowsPerScreen - 1) - row);

		if( lastScreen)
		{
			if( i + columnsPerScreen >= [viewers count] && strechWindows == YES)
			{
				frame.size.height += frame.origin.y - visibleFrame.origin.y;
				frame.origin.y = visibleFrame.origin.y;
			}
		}

		[[viewers objectAtIndex:i] setWindowFrame:frame showWindow:YES animate: YES];
	}
}

//-(IBAction)toggleActivityWindow:(id)sender
//{
//	ActivityWindowController* controller = [ActivityWindowController defaultController];
//	if (![controller.window isVisible] || ![controller.window isKeyWindow])
//		[controller.window makeKeyAndOrderFront:sender];
//	else
//		[controller.window orderOut:sender];
//	
//	[[NSUserDefaultsController sharedUserDefaultsController] setBool: [controller.window isVisible] forKey:@"ActivityWindowVisibleFlag"];
//}

//{
//	NSRect screenRect = [screen visibleFrame];
//	BOOL landscape = (screenRect.size.width/screenRect.size.height > 1) ? YES : NO;
//
//	int rows = 1,  columns = 1, viewerCount = [viewers count];
//	
//	while (viewerCount > (rows * columns))
//	{
//		float ratio = ((float)columns/(float)rows);
//		
//		if (ratio > 1.5 && landscape)
//			rows ++;
//		else 
//			columns ++;
//	}
//	
//	int i;
//	
//	for( i = 0; i < viewerCount; i++)
//	{
//		int row = i/columns;
//		int columnIndex = (i - (row * columns));
//		int viewerPosition = i;
//		
//		NSRect frame = [screen visibleFrame];
//
//		if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController exposedHeight];
//		frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];
//		
//		int temp;
//			
////		temp = frame.size.width / columnsPerScreen;
////		frame.size.width = temp * columnsPerScreen;
////		
////		temp = frame.size.height / rows;
////		frame.size.height = temp * rows;
//		
//		frame.size.width /= columns;
//		frame.origin.x += (frame.size.width * columnIndex);
//		
//		if( i == viewerCount-1)
//		{
//			frame.size.width = [screen visibleFrame].size.width - (frame.origin.x - [screen visibleFrame].origin.x);
//		}
//		
//		frame.size.height /= rows;
//		frame.origin.y += frame.size.height * ((rows - 1) - row);
//		
//		[[viewers objectAtIndex:i] setWindowFrame:frame showWindow:YES animate: YES];
//	}
//}

- (NSArray*) orderedScreens
{
	NSMutableArray *srcScreens = [NSMutableArray arrayWithArray: [NSScreen screens]];
	NSMutableArray *dstScreens = [NSMutableArray array];
	
	while( [srcScreens count])
	{
		float minY = 1000000, minX = 1000000;
		
		NSScreen *screen = nil;
		for( NSScreen *s in srcScreens)
		{
			if( [s visibleFrame].origin.y <= minY)
			{
				if( [s visibleFrame].origin.x < minX)
				{
					minY = [s visibleFrame].origin.y;
					minX = [s visibleFrame].origin.x;
					screen = s;
				}
			}
		}
		
		if( screen)
		{
			[dstScreens addObject: screen];
			[srcScreens removeObject: screen];
		}
	}
	
	[dstScreens removeObject: [dbWindow screen]];
	[dstScreens addObject: [dbWindow screen]];
	
	return dstScreens;
}

- (int) currentRowForViewer: (ViewerController*) v
{
	NSUInteger i = [[self orderedScreens] indexOfObject: [[v window] screen]];
	if( i == NSNotFound) i = 0;
	i++;
	
	i *= 3000;
	
	return i - ([[v window] frame].origin.y + (3*[[v window] frame].size.height)/4 - [[[v window] screen] visibleFrame].origin.y);
}

- (void) scaleToFit:(id)sender
{
	NSArray *array = [ViewerController getDisplayed2DViewers];
	
	for( ViewerController *v in array)
		[[v imageView] scaleToFit];
}

- (NSPoint) windowCenter: (NSWindow*) w
{
	NSUInteger i = [[self orderedScreens] indexOfObject: [w screen]];
	if( i == NSNotFound) i = 0;
	i++;
	
	i *= 3000;
	
	return NSMakePoint( i + [w frame].origin.x + [w frame].size.width/2, i + [w frame].origin.y + [w frame].size.height/2);
}

- (void) initTilingWindows
{
	for( NSMenuItem *item in [windowsTilingMenuRows itemArray])
	{
		[item setTarget: self];
		[item setAction: @selector( setFixedTilingRows:)];
	}
	
	for( NSMenuItem *item in [windowsTilingMenuColumns itemArray])
	{
		[item setTarget: self];
		[item setAction: @selector( setFixedTilingColumns:)];
	}
}

- (IBAction) setFixedTilingRows: (id) sender
{
	[self tileWindows: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: [sender tag]], @"rows", nil]];
}

- (IBAction) setFixedTilingColumns: (id) sender
{
	[self tileWindows: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: [sender tag]], @"columns", nil]];
}

- (BOOL) validateMenuItem:(NSMenuItem *) item
{
    if( [item action] == @selector(setFixedTilingRows:) || [item action] == @selector(setFixedTilingColumns:))
	{
		if( [item action] == @selector(setFixedTilingColumns:))
		{
		   if( [item tag] == lastColumns && [item tag] <= [[ViewerController getDisplayed2DViewers] count])
				[item setState: NSOnState];
			else
				[item setState: NSOffState];
		}
		
		if( [item action] == @selector(autoQueryRefresh:))
		{
			#ifndef OSIRIX_LIGHT
			if( [QueryController currentAutoQueryController])
				return YES;
			else
			#endif
				return NO;
		}
		
		if( [item action] == @selector(setFixedTilingRows:))
		{
			if( [item tag] == lastRows && [item tag] <= [[ViewerController getDisplayed2DViewers] count])
				[item setState: NSOnState];
			else
			   [item setState: NSOffState];
		}
		
		if( [item tag] > [[ViewerController getDisplayed2DViewers] count])
			return NO;
    }
    return YES;
}

- (void) tileWindows:(id)sender
{
	long				i, x;
	// Array of open Windows
	NSArray				*winList = [NSApp windows];
	// array of viewers
	NSMutableArray		*viewersList = [NSMutableArray array];
	BOOL				origCopySettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYSETTINGS"];
	NSRect				screenRect =  screenFrame();
	// User default to keep studies segregated to separate screens
	BOOL				keepSameStudyOnSameScreen = [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesTogetherOnSameScreen"];
//	BOOL				strechWindows = [[NSUserDefaults standardUserDefaults] boolForKey: @"StrechWindows"];
	// Array of arrays of viewers with same StudyUID
	NSMutableArray		*studyList = [NSMutableArray array];
	int					keyWindow = 0, numberOfMonitors;	
	NSArray				*screens = [self viewerScreens];
	
//	BOOL				fixedTiling = [[NSUserDefaults standardUserDefaults] boolForKey: @"FixedTiling"];
//	int					fixedTilingRows = [[NSUserDefaults standardUserDefaults] integerForKey: @"FixedTilingRows"];
//	int					fixedTilingColumns = [[NSUserDefaults standardUserDefaults] integerForKey: @"fixedTilingColumns"];
	
//	fixedTiling = YES;
//	fixedTilingColumns = 2;
//	fixedTilingRows = 2;
	
	delayedTileWindows = NO;
	
	numberOfMonitors = [screens count];
	
	[AppController checkForPreferencesUpdate: NO];
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"COPYSETTINGS"];
	[AppController checkForPreferencesUpdate: YES];
	
	//get 2D viewer windows
	for( NSWindow *win in winList)
	{
		if( [[win windowController] isKindOfClass:[OSIWindowController class]] == YES)
		{
			if( [[win windowController] magnetic])
			{
				if( [[win windowController] windowWillClose] == NO && [win isMiniaturized] == NO)
					[viewersList addObject: [win windowController]];
				else if( [[win windowController] windowWillClose])
				{
	//				NSLog( @"*** [[win windowController] windowWillClose] ***");
	//				[win performClose: self];
				}
					
				if( [[viewersList lastObject] FullScreenON]) return;
			}
		}
	}
	
	for( id obj in winList)
		[obj retain];
	
	//order windows from left-top to right-bottom, per screen if necessary
	NSMutableArray	*cWindows = [NSMutableArray arrayWithArray: viewersList];
	
	// Only the visible windows
	for( i = [cWindows count]-1; i >= 0; i--)
	{
		if( [[[cWindows objectAtIndex: i] window] isVisible] == NO) [cWindows removeObjectAtIndex: i];
	}
	
	NSMutableArray	*cResult = [NSMutableArray array];
	
	@try
	{
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
			
			float minX = [self windowCenter: [[cWindows objectAtIndex: index] window]].x;
			
			for( x = 0; x < [cWindows count]; x++)
			{
				if( [self windowCenter: [[cWindows objectAtIndex: x] window]].x < minX && [self currentRowForViewer: [cWindows objectAtIndex: x]] <= row)
				{
					minX = [self windowCenter: [[cWindows objectAtIndex: x] window]].x;
					index = x;
				}
			}
			
			[cResult addObject: [cWindows objectAtIndex: index]];
			[cWindows removeObjectAtIndex: index];
			count--;
		}
	}
	@catch ( NSException *e)
	{
		NSLog( @"***** 1: %@", e);
	}
	
	NSMutableArray *hiddenWindows = [NSMutableArray array];
	
	// Add the hidden windows
	for( ViewerController *v in viewersList)
	{
		if( [[v window] isVisible] == NO)
		{
			[hiddenWindows addObject: v];
			[cResult addObject: v];
		}
	}
	
	viewersList = cResult;
	
	for( i = 0; i < [viewersList count]; i++)
	{
		if( [[[viewersList objectAtIndex: i] window] isKeyWindow]) keyWindow = i;
	}
	
	BOOL identical = YES;
	
	if( keepSameStudyOnSameScreen)
	{
		// Are there different studies
		if( [viewersList count])
		{
			NSString	*studyUID = [[[[viewersList objectAtIndex: 0] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyInstanceUID"];
			
			//get 2D viewer study arrays
			for( i = 0; i < [viewersList count]; i++)
			{
				if( [[[[[viewersList objectAtIndex: i] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: studyUID] == NO)
					identical = NO;
			}
		}
	}
	
	@try
	{
		if( keepSameStudyOnSameScreen == YES && identical == NO)
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
		else keepSameStudyOnSameScreen = NO;
	}
	@catch ( NSException *e)
	{
		NSLog( @"***** 2: %@", e);
	}
	
	int viewerCount = [viewersList count];
	
	screenRect = [[screens objectAtIndex:0] visibleFrame];
	
	BOOL landscape = (screenRect.size.width/screenRect.size.height > 1) ? YES : NO;
	
	int rows = [[[[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] objectForKey:@"Rows"] intValue];
	int columns = [[[[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] objectForKey:@"Columns"] intValue];
	
	if( [sender isKindOfClass: [NSDictionary class]])
	{
		if( [[sender objectForKey: @"rows"] intValue])
		{
			rows = [[sender objectForKey: @"rows"] intValue];
			columns = floor( (float) viewerCount / (float) rows);
		}
		if( [[sender objectForKey: @"columns"] intValue])
		{
			columns = [[sender objectForKey: @"columns"] intValue];
			rows = floor( (float) viewerCount / (float) columns);
		}
	}
	
	if( ![[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol] || viewerCount < rows * columns)
	{
		if (landscape)
		{
			columns = 2 * numberOfMonitors;
			rows = 1;
		}
		else
		{
			columns = numberOfMonitors;
			rows = 2;
		}
	}
	
	//excess viewers. Need to add spaces to accept
	if( viewerCount > (rows * columns))
	{
		float ratioValue;
		
		if( landscape) ratioValue = 1.5;
		else ratioValue = 1.0;
		
		float viewerCountPerScreen = (float) viewerCount / (float) numberOfMonitors;
		
		while (viewerCountPerScreen > (rows * columns))
		{
			if( [sender isKindOfClass: [NSDictionary class]] && [sender objectForKey: @"rows"])
				columns++;
			else if( [sender isKindOfClass: [NSDictionary class]] && [sender objectForKey: @"columns"])
				rows++;
			else
			{
				float ratio = (float) columns / (float) rows;
			
				if (ratio > ratioValue)
					rows ++;
				else 
					columns ++;
			}
		}
		
		columns *= numberOfMonitors;
	}
	
	// Smart arrangement if one window was added or removed
	if( numberOfMonitors == 1)
	{
		@try 
		{
			if( lastColumns != columns)
			{
				if( lastCount == [viewersList count] -1)	// One window was added
				{
					if( columns < [viewersList count])
					{
						[viewersList insertObject: [viewersList lastObject] atIndex: lastColumns];
						[viewersList removeObjectAtIndex: [viewersList count]-1];
					}
						
				}
				
//				if( lastCount == [viewersList count] +1)	// One window was removed
//				{
//					if( viewersAddresses)
//					{
//						// Try to find the missing Viewer
//						
//						for( int i = 0 ; i < [viewersAddresses count]; i++)
//						{
//							if( [viewersList containsObject: [[viewersAddresses objectAtIndex: i] nonretainedObjectValue]] == NO)
//							{
//								// We found the missing viewer
//								[viewersList insertObject: [viewersList lastObject] atIndex: i];
//								[viewersList removeObjectAtIndex: [viewersList count]-1];
//								break;
//							}
//						}
//					}
//				}
			}
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
	}
	
	lastColumns = columns;
	lastRows = rows;
	lastCount = [viewersList count];
	
//	if( viewersAddresses == nil)
//		viewersAddresses = [[NSMutableArray array] retain];
//	
//	[viewersAddresses removeAllObjects];
//	for( id v in viewersList)
//		[viewersAddresses addObject: [NSValue valueWithNonretainedObject: v]];
	
	accumulateAnimations = YES;
	
	if( keepSameStudyOnSameScreen && numberOfMonitors > 1)
	{
		@try
		{
			NSLog(@"Tile Windows with keepSameStudyOnSameScreen == YES");
			
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
				
				[self displayViewers: viewersForThisScreen monitorIndex: i screens: screens numberOfMonitors: numberOfMonitors rowsPerScreen: rows columnsPerScreen: columns];
			}
			
		}
		@catch ( NSException *e)
		{
			NSLog( @"***** 3: %@", e);
		}
	}
	
	// if monitor count is greater than or equal to viewers. One viewer per window
	
	else if (viewerCount <= numberOfMonitors)
	{
		int count = [viewersList count];
		
		for( i = 0; i < count; i++)
		{
			NSScreen *screen = [screens objectAtIndex:i];
			NSRect frame = [screen visibleFrame];
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController exposedHeight];
			frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];
			
			[[viewersList objectAtIndex:i] setWindowFrame: frame showWindow:YES animate: YES];			
		}
		
		lastColumns = numberOfMonitors;
	}
	
	/* Will have columns but no rows. 
	 There are more columns than monitors. 
	  Need to separate columns among the window evenly  */
	
	else if((viewerCount <= columns) &&  (viewerCount % numberOfMonitors == 0))
	{
		int viewersPerScreen = viewerCount / numberOfMonitors;
		for( i = 0; i < viewerCount; i++)
		{
			int index = (int) i/viewersPerScreen;
			int viewerPosition = i % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:index];
			NSRect frame = [screen visibleFrame];
			
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController exposedHeight];
			frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];
			
			frame.size.width /= viewersPerScreen;
			frame.origin.x += (frame.size.width * viewerPosition);
			
			[[viewersList objectAtIndex:i] setWindowFrame: frame showWindow:YES animate: YES];
		}
		
		lastRows = 1;
		lastColumns = viewerCount;
	} 
	//have different number of columns in each window
	else if( viewerCount <= columns) 
	{
		int columnsPerScreen = ceil(((float) columns / numberOfMonitors));
		int extraViewers = viewerCount % numberOfMonitors;
		
		for( i = 0; i < viewerCount; i++)
		{
			int monitorIndex = (int) i /columnsPerScreen;
			int viewerPosition = i % columnsPerScreen;
			NSScreen *screen = [screens objectAtIndex: monitorIndex];
			NSRect frame = [screen visibleFrame];
			
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController exposedHeight];
			frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];
			
			if (monitorIndex < extraViewers) 
				frame.size.width /= columnsPerScreen;
			else
				frame.size.width /= (columnsPerScreen - 1);
				
			frame.origin.x += (frame.size.width * viewerPosition);
			
			if( [hiddenWindows count])	// We have new viewers to insert !
			{
				if( [[[viewersList objectAtIndex:i] window] screen] != screen)
				{
					[viewersList removeObject: [hiddenWindows lastObject]];
					[viewersList insertObject: [hiddenWindows lastObject] atIndex: i];
					
					[hiddenWindows removeObject: [hiddenWindows lastObject]];
				}
			}
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame showWindow:YES animate: YES];
		}
		
		lastRows = 1;
		lastColumns = viewerCount;
	}
	//adjust for actual number of rows needed
	else if (viewerCount <=  columns * rows)  
	{
		int columnsPerScreen = columns;
		int rowsPerScreen = rows;
		
		columnsPerScreen = ceil(((float) columns / (float) numberOfMonitors));
		
		
		NSMutableArray *viewersForThisScreen = [NSMutableArray array];
		
		int previousIndex = 0;
		int monitorIndex;
		
		if( viewerCount)
		{
			for( i = 0; i < viewerCount; i++)
			{
				monitorIndex =  i / (columnsPerScreen*rowsPerScreen);
				
				if( monitorIndex == numberOfMonitors) monitorIndex = numberOfMonitors-1;
				
				NSScreen *screen = [screens objectAtIndex: monitorIndex];
				
				if( monitorIndex != previousIndex)
				{
					[self displayViewers: viewersForThisScreen monitorIndex: previousIndex screens: screens numberOfMonitors: numberOfMonitors rowsPerScreen: rowsPerScreen columnsPerScreen: columnsPerScreen];
					[viewersForThisScreen removeAllObjects];
					
					previousIndex = monitorIndex;
				}
				
				if( [hiddenWindows count])	// We have new viewers to insert !
				{
					if( [[[viewersList objectAtIndex:i] window] screen] != screen)
					{
						[viewersList removeObject: [hiddenWindows lastObject]];
						[viewersList insertObject: [hiddenWindows lastObject] atIndex: i];
						
						[hiddenWindows removeObject: [hiddenWindows lastObject]];
					}
				}
				
				[viewersForThisScreen addObject: [viewersList objectAtIndex:i]];
			}
			
			if( [viewersForThisScreen count])
				[self displayViewers: viewersForThisScreen monitorIndex: monitorIndex screens: screens numberOfMonitors: numberOfMonitors rowsPerScreen: rowsPerScreen columnsPerScreen: columnsPerScreen];
		}
	}
	else
		NSLog(@"NO tiling");
	
	accumulateAnimations = NO;
	if( [accumulateAnimationsArray count])
	{
		[OSIWindowController setDontEnterMagneticFunctions: YES];
		[OSIWindowController setDontEnterWindowDidChangeScreen: YES];
		
		NSViewAnimation * animation = [[[NSViewAnimation alloc]  initWithViewAnimations: accumulateAnimationsArray] autorelease];
		[animation setAnimationBlockingMode: NSAnimationBlocking];
		
		if( [accumulateAnimationsArray count] == 1)
			[animation setDuration: 0.20];
		else
			[animation setDuration: 0.40];
		[animation startAnimation];
		
		[accumulateAnimationsArray release];
		accumulateAnimationsArray = nil;
		
		[OSIWindowController setDontEnterMagneticFunctions: NO];
		[OSIWindowController setDontEnterWindowDidChangeScreen: NO];
	}
	
	[AppController checkForPreferencesUpdate: NO];
	[[NSUserDefaults standardUserDefaults] setBool: origCopySettings forKey: @"COPYSETTINGS"];
	[AppController checkForPreferencesUpdate: YES];
	
	if( [viewersList count] > 0)
	{
		[[[viewersList objectAtIndex: keyWindow] window] makeKeyAndOrderFront:self];
		[[viewersList objectAtIndex: keyWindow] propagateSettings];
		
		for( id v in viewersList)
		{
			if( [v isKindOfClass:[ViewerController class]])
			{
				[v checkBuiltMatrixPreview];
				[v redrawToolbar]; // To avoid the drag & remove item bug - multiple windows
			}
		}
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"])
		{
			for( id v in viewersList)
				[v autoHideMatrix];
		}
		
		[[[viewersList objectAtIndex: keyWindow] imageView] becomeMainWindow];
		[[viewersList objectAtIndex: keyWindow] refreshToolbar];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncPreviewList"])
			[[viewersList objectAtIndex: keyWindow] syncThumbnails];
	}
	
	for( id obj in winList)
		[obj release];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction) closeAllViewers: (id) sender
{
	[ViewerController closeAllWindows];
}

- (void) startDICOMBonjourSearch
{
	if (!dicomNetServiceDelegate)
		dicomNetServiceDelegate = [DCMNetServiceDelegate sharedNetServiceDelegate];
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

#pragma mark-
#pragma mark HTML Templates
+ (void)checkForHTMLTemplates { // __deprecated
	[[[BrowserController currentBrowser] database] checkForHtmlTemplates];
}

#pragma mark-
#pragma mark Pages Template

+ (NSString*)checkForPagesTemplate;
{
	NSString *templateDirectory = nil;
	#ifndef MACAPPSTORE
	// Pages template directory
	NSArray *templateDirectoryPathArray = [NSArray arrayWithObjects:NSHomeDirectory(), @"Library", @"Application Support", @"iWork", @"Pages", @"Templates", @"OsiriX", nil];
	int i;
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
	NSString *reportFile = [templateDirectory stringByAppendingPathComponent:@"OsiriX Basic Report.template"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:reportFile] == NO) {
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriX Report.template"] toPath:[templateDirectory stringByAppendingPathComponent:@"/OsiriX Basic Report.template"] handler:nil];
	}
	
#endif
	return templateDirectory;
}

#pragma mark-
#pragma mark 12 Bit Display support.

+ (BOOL)canDisplay12Bit;
{
	return canDisplay12Bit;
}

+ (void)setCanDisplay12Bit:(BOOL)boo;
{
	canDisplay12Bit = boo;
	[[NSUserDefaults standardUserDefaults] setBool:boo forKey:@"is12bitPluginAvailable"];
}

+ (void)setLUT12toRGB:(unsigned char*)lut;
{
	LUT12toRGB = lut;
}

+ (unsigned char*)LUT12toRGB;
{
	return LUT12toRGB;
}

+ (void)set12BitInvocation:(NSInvocation*)invocation;
{
	[fill12BitBufferInvocation release];
	fill12BitBufferInvocation = [invocation retain];
}

+ (NSInvocation*)fill12BitBufferInvocation;
{
	return fill12BitBufferInvocation;
}

#pragma mark Hardware Interpolation

-(void)verifyHardwareInterpolation
{
	NSUInteger size = 32, size2 = size*size;
	
	NSWindow* win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,size,size) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
	
	long annotCopy = [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"];
	long clutBarsCopy = [[NSUserDefaults standardUserDefaults] integerForKey:@"CLUTBARS"];
	BOOL noInterpolationCopy = [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"];
	BOOL highQInterpolationCopy = [[NSUserDefaults standardUserDefaults] boolForKey:@"SOFTWAREINTERPOLATION"];
	BOOL full32bitPipeCopy = [[NSUserDefaults standardUserDefaults] boolForKey:@"FULL32BITPIPELINE"];
	
	float pixData[] = {0,1,1,0};
	DCMPix* dcmPix = [[DCMPix alloc] initWithData:pixData :32 :2 :2 :1 :1 :0 :0 :0];
	
	CGLContextObj cgl_ctx;
	unsigned char temp_rgb[size2*3];
	float iwl, iww;
	DCMView* dcmView;
//	unsigned char* planes[1];
	
	[[NSUserDefaults standardUserDefaults] setInteger:annotNone forKey:@"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger:barHide forKey:@"CLUTBARS"];
	
	// pix 1: no interpolation

	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NOINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SOFTWAREINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FULL32BITPIPELINE"];
	
	dcmView = [[DCMView alloc] initWithSize:NSMakeSize(size,size)];
	[dcmView setPixels:[NSArray arrayWithObject:dcmPix] files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
	[dcmView setScaleValueCentered:size];
	[win.contentView addSubview:dcmView];
	[dcmView drawRect:NSMakeRect(0,0,size,size)];

	cgl_ctx = (CGLContextObj)[[dcmView openGLContext] CGLContextObj];
	glReadBuffer(GL_BACK);

	glReadPixels(0, 0, size, size, GL_RGB, GL_UNSIGNED_BYTE, temp_rgb);
	unsigned char gray_1[size2];
	for (int i = 0; i < size2; ++i)
		gray_1[i] = (temp_rgb[i*3]+temp_rgb[i*3+1]+temp_rgb[i*3+2])/3;
	
/*	planes[0] = gray_1;
	NSBitmapImageRep* representation = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
																			   pixelsWide:size pixelsHigh:size bitsPerSample:8
																		  samplesPerPixel:1 hasAlpha:NO isPlanar:NO
																		   colorSpaceName:NSCalibratedBlackColorSpace bytesPerRow:size
																			 bitsPerPixel:8];
	[[representation TIFFRepresentation] writeToFile:@"/Users/pacs/aaaaa1.tif" atomically:YES];
	[representation release];*/
	
	[dcmView removeFromSuperview];
	[dcmView release];
	
	// pix 2: interpolation
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NOINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SOFTWAREINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FULL32BITPIPELINE"];
	dcmView = [[DCMView alloc] initWithSize:NSMakeSize(size,size)];
	[dcmView setPixels:[NSArray arrayWithObject:dcmPix] files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
	[dcmView setScaleValueCentered:size];
	[win.contentView addSubview:dcmView];
	[dcmView drawRect:NSMakeRect(0,0,size,size)];
	
	cgl_ctx = (CGLContextObj)[[dcmView openGLContext] CGLContextObj];
	glReadBuffer(GL_BACK);
	
	glReadPixels(0, 0, size, size, GL_RGB, GL_UNSIGNED_BYTE, temp_rgb);
	unsigned char gray_2[size2];
	for (int i = 0; i < size2; ++i)
		gray_2[i] = (temp_rgb[i*3]+temp_rgb[i*3+1]+temp_rgb[i*3+2])/3;
	
	/*planes[0] = gray_2;
	representation = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
																			   pixelsWide:size pixelsHigh:size bitsPerSample:8
																		  samplesPerPixel:1 hasAlpha:NO isPlanar:NO
																		   colorSpaceName:NSCalibratedBlackColorSpace bytesPerRow:size
																			 bitsPerPixel:8];
	[[representation TIFFRepresentation] writeToFile:@"/Users/pacs/aaaaa2.tif" atomically:YES];
	[representation release];*/
	
	[dcmView removeFromSuperview];
	[dcmView release];
	
	[win release];
	[dcmPix release];
	
	
	[[NSUserDefaults standardUserDefaults] setInteger: annotCopy forKey:@"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: clutBarsCopy forKey:@"CLUTBARS"];
	[[NSUserDefaults standardUserDefaults] setBool: noInterpolationCopy forKey:@"NOINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool: highQInterpolationCopy forKey:@"SOFTWAREINTERPOLATION"];
	
	[DCMView setCLUTBARS:clutBarsCopy ANNOTATIONS:annotCopy];
	
	// eval results
	
	CGFloat delta = 0;
	for (int i = 0; i < size2; ++i)
		delta += fabsf((float)gray_1[i]-(float)gray_2[i]);
	BOOL has32bitPipeline = delta > 1000; // we may want to raise this..
	
	if (has32bitPipeline)
	{
		NSLog( @"-- 32bit pipeline activated");
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasFULL32BITPIPELINE"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FULL32BITPIPELINE"];
	}
	else
	{
		NSLog( @"-- 32bit pipeline inactivated");
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasFULL32BITPIPELINE"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FULL32BITPIPELINE"];
	}
}

#pragma mark -

- (NSManagedObjectContext*) defaultWebPortalManagedObjectContext
{
	#ifndef OSIRIX_LIGHT
	return [[[WebPortal defaultWebPortal] database] managedObjectContext];
	#else
	static NSManagedObjectContext *fakeContext = nil;
	if( fakeContext == nil)
	{
		fakeContext  = [[NSManagedObjectContext alloc] init];
		NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/WebPortalDB.momd"]]];
		NSPersistentStoreCoordinator *psc = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model] autorelease];
		[fakeContext setPersistentStoreCoordinator: psc];
	}
	return fakeContext;
	#endif
}

-(WebPortal*)defaultWebPortal {
	#ifndef OSIRIX_LIGHT
	return [WebPortal defaultWebPortal];
	#else
	return nil;
	#endif
}

#ifndef OSIRIX_LIGHT

-(NSString*)weasisBasePath {
	return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"weasis"];
}

#endif

static NSMutableDictionary* _receivingDict = nil;

-(void)_receivingIconUpdate {
	if (!_receivingDict.count)
		[NSApp setApplicationIconImage:[NSImage imageNamed:@"Osirix.icns"]];
	else [NSApp setApplicationIconImage:[NSImage imageNamed:@"OsirixDownload.icns"]];
}

-(void)_receivingIconSet:(BOOL)flag {
	@synchronized (self) {
		if (!_receivingDict)
			_receivingDict = [[NSMutableDictionary alloc] init];
		
		NSThread* thread = [NSThread currentThread];
		NSValue* threadValue = [NSValue valueWithPointer:thread];
		N2MutableUInteger* setCount = [_receivingDict objectForKey:threadValue];
		
		if (flag) {
			if (!setCount)
				[_receivingDict setObject: setCount = [N2MutableUInteger mutableUIntegerWithUInteger:1] forKey:threadValue];
			else [setCount increment];
		} else {
			if (setCount) {
				[setCount decrement];
				if (!setCount.unsignedIntegerValue)
					[_receivingDict removeObjectForKey:threadValue];
			}
		}
		
		[self performSelectorOnMainThread:@selector(_receivingIconUpdate) withObject:nil waitUntilDone:NO];
	}
}

-(void)setReceivingIcon {
	[self _receivingIconSet:YES];
}

-(void)unsetReceivingIcon {
	[self _receivingIconSet:NO];
}

-(void)setBadgeLabel:(NSString*)label {
	[[NSApp dockTile] setBadgeLabel:label];
	[[NSApp dockTile] display];
}

@end
