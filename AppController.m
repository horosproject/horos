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
#import "NSPanel+N2.h"
#ifndef OSIRIX_LIGHT
#import "BonjourPublisher.h"
#ifndef MACAPPSTORE
#import "Reports.h"
#import <ILCrashReporter/ILCrashReporter.h>
#import "VRView.h"
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
#import "Window3DController.h"
#import "N2Stuff.h"
#import "OSIGeneralPreferencePanePref.h"
#import "Security/Security.h"
#import "Security/SecRequirement.h"
#import "Security/SecCode.h"
#import "PFMoveApplication.h"
#import "OSIGeneralPreferencePanePref.h"

#include <OpenGL/OpenGL.h>

#include <kdu_OsiriXSupport.h>

#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
	 
#define BUILTIN_DCMTK YES

#define MAXSCREENS 10
ToolbarPanelController *toolbarPanel[ MAXSCREENS] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};

static NSMenu *mainMenuCLUTMenu = nil, *mainMenuWLWWMenu = nil, *mainMenuConvMenu = nil, *mainOpacityMenu = nil;
static NSDictionary *previousWLWWKeys = nil, *previousCLUTKeys = nil, *previousConvKeys = nil, *previousOpacityKeys = nil;
static BOOL checkForPreferencesUpdate = YES, _appDidFinishLoading = NO;
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
						width = frame.size.width;
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
					width = frame.size.width;
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
    N2LogExceptionWithStackTrace(exception);
}

//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

static NSDate *lastWarningDate = nil;


@interface AppController ()

+(void)checkForWordTemplates;

@end


@implementation AppController

@synthesize checkAllWindowsAreVisibleIsOff, filtersMenu, windowsTilingMenuRows, windowsTilingMenuColumns, isSessionInactive, dicomBonjourPublisher = BonjourDICOMService, XMLRPCServer;
@synthesize bonjourPublisher = _bonjourPublisher;

+(BOOL) hasMacOSX1083
{
	OSErr err;
	SInt32 osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );
	if ( err == noErr)
	{
		if( osVersion < 0x1083UL || osVersion >= 0x1084UL)
		{
			return NO;
		}
	}
	return YES;
}

+(BOOL) hasMacOSXMountainLion
{
	OSErr err;
	SInt32 osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );
	if ( err == noErr)
	{
		if ( osVersion < 0x1080UL )
		{
			return NO;
		}
	}
	return YES;
}


+(BOOL) hasMacOSXLion
{
	OSErr err;       
	SInt32 osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{
		if ( osVersion < 0x1075UL )
		{
			return NO;
		}
	}
	return YES;                   
}


+(BOOL) hasMacOSXSnowLeopard
{
	OSErr err;
	SInt32 osVersion;
	
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
	OSErr err;       
	SInt32 osVersion;
	
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
	[[AppController sharedAppController] performSelectorOnMainThread: @selector(pause) withObject: nil waitUntilDone: NO];
}

-(void)applicationDidChangeScreenParameters:(NSNotification*)aNotification
{
    NSLog( @"--- applicationDidChangeScreenParameters : resetToolbars");
    [[AppController sharedAppController] closeAllViewers: self];
    
    [AppController resetToolbars];
}

+ (void) resetToolbars
{
	int numberOfScreens = [[NSScreen screens] count] + 1; //Just in case, we connect a second monitor when using OsiriX.
	
	for( int i = 0; i < MAXSCREENS; i++)
    {
		if( toolbarPanel[ i])
            [toolbarPanel[ i] release];
        
        toolbarPanel[ i] = nil;
	}
    
	for( int i = 0; i < numberOfScreens; i++)
		toolbarPanel[ i] = [[ToolbarPanelController alloc] initForScreen: i];
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

+(ToolbarPanelController*)toolbarForScreen:(NSScreen*)screen
{
    NSArray* screens = [NSScreen screens];
    NSUInteger i = [screens indexOfObject:screen];
    
    if( i == NSNotFound)
        return nil;
    
    if( i>= MAXSCREENS)
        return nil;
    
    return toolbarPanel[i];
}

+ (void) displayImportantNotice:(id) sender
{
    if( [AppController isFDACleared])
        return;
    
	if( lastWarningDate == nil || [lastWarningDate timeIntervalSinceNow] < -60*60)
	{
		int result = NSRunCriticalAlertPanel( NSLocalizedString( @"Important Notice", nil), NSLocalizedString( @"This version of OsiriX, being a free open-source software (FOSS), is not certified as a commercial medical device for primary diagnostic imaging.\r\rFor a certified version and to get rid of this message, please update to 'OsiriX MD' certified version.", nil), NSLocalizedString( @"OsiriX MD", nil), NSLocalizedString( @"I agree", nil), NSLocalizedString( @"Quit", nil));
		
		if( result == NSAlertDefaultReturn)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://pixmeo.pixmeo.com/products.html#OsiriXMD"]];
			
		else if( result == NSAlertOtherReturn)
			[[AppController sharedAppController] terminate: self];
	}
	
	[lastWarningDate release];
	lastWarningDate = [[NSDate date] retain];
}

+ (BOOL) isKDUEngineAvailable
{
	return kdu_available();
}

+ (void) checkForPreferencesUpdate: (BOOL) b
{
	checkForPreferencesUpdate = b;
}

+ (void) cleanOsiriXSubProcesses
{
	const int kPIDArrayLength = 100;
    
    pid_t MyArray [kPIDArrayLength];
    unsigned int NumberOfMatches;
    int Counter, Error;
	
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SingleProcessMultiThreadedListener"] == NO)
    {
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
    
    Error = GetAllPIDsForProcessName( "CrashReporter", MyArray, kPIDArrayLength, &NumberOfMatches, NULL);
	
	if (Error == 0)
    {
        for (Counter = 0 ; Counter < NumberOfMatches ; Counter++)
        {
			if( MyArray[ Counter] != getpid())
			{
				NSLog( @"Child Process to kill (CrashReporter): %d (PID)", MyArray[ Counter]);
				kill( MyArray[ Counter], 15);
			}
        }
    }
}

+(NSString*)UID
{
    return [NSString stringWithFormat:@"%@|%@", [N2Shell serialNumber], NSUserName()];
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
		N2LogExceptionWithStackTrace(e);
	}
	
	return r;
}

+ (BOOL) willExecutePlugin
{
	BOOL returnValue = YES;
	
	if( [AppController isFDACleared])
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hidePluginCertificationWarning"] == NO)
        {
            NSAlert* alert = [[NSAlert new] autorelease];
            [alert setMessageText: NSLocalizedString( @"Important Notice", nil)];
            [alert setInformativeText: NSLocalizedString( @"Plugins are not certified for primary diagnosis in medical imaging, unless specifically written by the plugin author(s).", nil)];
            [alert setShowsSuppressionButton:YES ];
            [alert addButtonWithTitle: NSLocalizedString( @"OK", nil)];
            [alert addButtonWithTitle: NSLocalizedString( @"Cancel", nil)];
            
            if( [alert runModal] == NSAlertSecondButtonReturn)
                return NO;
            
            if ([[alert suppressionButton] state] == NSOnState)
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"hidePluginCertificationWarning"];
        }
    }
	
	return returnValue;
}

- (void) pause
{ // __deprecated
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
	
	
	for(NSString *path in pluginsArray)
	{
		[pluginNames appendFormat:@"%@, ", [[path lastPathComponent] stringByDeletingPathExtension]];
		
		NSString *pluginBundleName = [[path lastPathComponent] stringByDeletingPathExtension];
		
		NSURL *bundleURL = [NSURL fileURLWithPath: [PluginManager pathResolved:path]];
		CFDictionaryRef bundleInfoDict = CFBundleCopyInfoDictionaryInDirectory((CFURLRef)bundleURL);
		
		CFStringRef versionString = nil;
		if(bundleInfoDict != NULL)
        {
			versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleVersion"));
		
            if( versionString == nil)
                versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleShortVersionString"));
        }
        
		NSString *pluginBundleVersion = nil;
		if(versionString != NULL)
			pluginBundleVersion = (NSString*)versionString;
		else
			pluginBundleVersion = @"";		
		
		for(NSDictionary *plug in [PluginManager pluginsList])
		{
			if([pluginBundleName isEqualToString: [plug objectForKey:@"name"]])
			{
				[replacingPlugins appendString: [plug objectForKey:@"name"]];
				[replacingPlugins appendString: strVersion];
				[replacingPlugins appendString: [plug objectForKey:@"version"]];
				[replacingPlugins appendString: replacing];
				[replacingPlugins appendString: pluginBundleName];
				[replacingPlugins appendString: strVersion];
				[replacingPlugins appendString: pluginBundleVersion];
				[replacingPlugins appendString: @".\n\n"];
			}
		}
		
		if( bundleInfoDict)
			CFRelease( bundleInfoDict);
	}
	
	pluginNames = [NSMutableString stringWithString: [pluginNames substringToIndex:[pluginNames length]-2]];
	if([replacingPlugins length]) replacingPlugins = [NSMutableString stringWithString:[replacingPlugins substringToIndex:[replacingPlugins length]-2]];
	
	NSString *msg;
	NSString *areYouSure = NSLocalizedString(@"Are you sure you want to install", @"");
	
	if( [pluginsArray count] == 1)
		msg = [NSString stringWithFormat:NSLocalizedString(@"%@ the plugin named : %@ ?", @""), areYouSure, pluginNames];
	else
		msg = [NSString stringWithFormat:NSLocalizedString(@"%@ the following plugins : %@ ?", @""), areYouSure, pluginNames];
	
	if( [replacingPlugins length])
		msg = [NSString stringWithFormat:@"%@\n\n%@", msg, replacingPlugins];
	
	NSInteger res = NSRunAlertPanel(NSLocalizedString(@"Plugins Installation", @""), msg, NSLocalizedString(@"OK", @""), NSLocalizedString(@"Cancel", @""), nil);
	
	if( res)
	{
		for( NSString *path in pluginsArray)
            [PluginManager installPluginFromPath: path];
		
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
	}
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

-(IBAction) osirix64bit:(id)sender
{
	if( sender)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/OsiriX-64bit.html"]];
	else
	{
		NSArray* urls = [NSArray arrayWithObject: [NSURL URLWithString:@"http://www.osirix-viewer.com/OsiriX-64bit.html"]];

        [[NSWorkspace sharedWorkspace] openURLs:urls withAppBundleIdentifier: nil options: NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor: nil launchIdentifiers: nil];
	}
}

-(IBAction)sendEmail:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:pixmeo@pixmeo.com"]];
}

-(IBAction)openOsirixWebPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.pixmeo.com"]];
}

-(IBAction)help:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Learning.html"]];
}

-(IBAction)openOsirixDiscussion:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://groups.yahoo.com/group/osirix/"]];
}

-(IBAction)userManual:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://pixmeo.pixmeo.com/products.html#OsiriXUserManual"]];
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
			if( [[NSFileManager defaultManager] fileExistsAtPath: path] && [(NSString*)[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] length] > 0)
			{
				[NSThread currentThread].status = [[NSThread currentThread].status stringByAppendingFormat: NSLocalizedString( @" - %@", nil), [NSString stringWithContentsOfFile: path]];
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


- (void) setAETitleToHostname
{
	char s[_POSIX_HOST_NAME_MAX+1];
	gethostname(s,_POSIX_HOST_NAME_MAX);
	NSString *c = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
	NSRange range = [c rangeOfString: @"."];
	if( range.location != NSNotFound) c = [c substringToIndex: range.location];
	
	if( [c length] > 16)
		c = [c substringToIndex: 16];
	
    if( c.length == 0)
        c = @"OSIRIX";
    
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
	
	@try {
	
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
    if ([[previousDefaults valueForKey: @"DICOMConnectionTimeout"] intValue] != [defaults integerForKey: @"DICOMConnectionTimeout"])
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
	if ([[previousDefaults valueForKey: @"SingleProcessMultiThreadedListener"] intValue] != [defaults integerForKey: @"SingleProcessMultiThreadedListener"])
		restartListener = YES;
	if ([[previousDefaults valueForKey: @"activateCGETSCP"] intValue] != [defaults integerForKey: @"activateCGETSCP"])
		restartListener = YES;
    if ([[previousDefaults valueForKey: @"activateCFINDSCP"] intValue] != [defaults integerForKey: @"activateCFINDSCP"])
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
	
	} @catch( NSException *localException) {
		NSLog(@"Exception updating prefs: %@", [localException description]);
	}
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
		if( viewerMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... viewerMenu == nil -> viewerMenu == itemAtIndex == 5");
			NSLog( @"Not found item: %@", NSLocalizedString(@"2D Viewer", nil));
			viewerMenu = [[mainMenu itemAtIndex: 5]  submenu];
			NSLog( @"***** Selected item: %@", [viewerMenu title]);
		}
		mainOpacityMenu = [[viewerMenu itemWithTitle: NSLocalizedString(@"Opacity", nil)] submenu];
		if( mainOpacityMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... mainOpacityMenu == nil -> mainOpacityMenu == itemAtIndex == 42");
			NSLog( @"Not found item: %@", NSLocalizedString(@"Opacity", nil));
			mainOpacityMenu = [[viewerMenu itemAtIndex: 41]  submenu];
			NSLog( @"***** Selected item: %@", [mainOpacityMenu title]);
		}
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
		viewerMenu = [[mainMenu itemWithTitle: NSLocalizedString(@"2D Viewer", nil)] submenu];
		if( viewerMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... viewerMenu == nil -> viewerMenu == itemAtIndex == 5");
			NSLog( @"Not found item: %@", NSLocalizedString(@"2D Viewer", nil));
			viewerMenu = [[mainMenu itemAtIndex: 5]  submenu];
			NSLog( @"***** Selected item: %@", [viewerMenu title]);
		}
		
		mainMenuWLWWMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
		if( mainMenuWLWWMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... mainMenuWLWWMenu == nil -> mainMenuWLWWMenu == itemAtIndex");
			NSLog( @"Not found item: %@", NSLocalizedString(@"Window Width & Level", nil));
			mainMenuWLWWMenu = [[viewerMenu itemAtIndex: 38]  submenu];
			NSLog( @"***** Selected item: %@", [mainMenuWLWWMenu title]);
		}
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
		if( viewerMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... viewerMenu == nil -> viewerMenu == itemAtIndex == 5");
			NSLog( @"Not found item: %@", NSLocalizedString(@"2D Viewer", nil));
			viewerMenu = [[mainMenu itemAtIndex: 5]  submenu];
			NSLog( @"***** Selected item: %@", [viewerMenu title]);
		}
		mainMenuConvMenu = [[viewerMenu itemWithTitle: NSLocalizedString(@"Convolution Filters", nil)] submenu];
		if( mainMenuConvMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... mainMenuConvMenu == nil -> mainMenuConvMenu == itemAtIndex == 43");
			NSLog( @"Not found item: %@", NSLocalizedString(@"Convolution Filters", nil));
			mainMenuConvMenu = [[viewerMenu itemAtIndex: 42]  submenu];
			NSLog( @"***** Selected item: %@", [mainMenuConvMenu title]);
		}
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
		if( viewerMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... viewerMenu == nil -> viewerMenu == itemAtIndex == 5");
			NSLog( @"Not found item: %@", NSLocalizedString(@"2D Viewer", nil));
			viewerMenu = [[mainMenu itemAtIndex: 5]  submenu];
			NSLog( @"***** Selected item: %@", [viewerMenu title]);
		}
		mainMenuCLUTMenu = [[[viewerMenu itemWithTitle:NSLocalizedString(@"Color Look Up Table", nil)] submenu] retain];
		if( mainMenuCLUTMenu == nil)
		{
			NSLog( @"***** NSLocalization bug.... mainMenuCLUTMenu == nil -> mainMenuCLUTMenu == itemAtIndex == 40");
			NSLog( @"Not found item: %@", NSLocalizedString(@"Color Look Up Table", nil));
			mainMenuCLUTMenu = [[viewerMenu itemAtIndex: 39]  submenu];
			NSLog( @"***** Selected item: %@", [mainMenuCLUTMenu title]);
		}
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
	[dict setValue:[AppController UID] forKey: @"UID"]; 
	
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
        case 23:
			[dict setValue: @"JPEGLSLossless" forKey: @"preferredSyntax"];
            break;
        case 24:
			[dict setValue: @"JPEGLSLossy" forKey: @"preferredSyntax"];
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
	
	@try
    {
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
                while( [aTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
//				[aTask waitUntilExit];
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
		[NSTimer scheduledTimerWithTimeInterval: 5 target: self selector: @selector(startDICOMBonjour:) userInfo: nil repeats: NO];
	}
}

#ifndef OSIRIX_LIGHT
- (void)netService:(NSNetService *)aNetService didNotResolve:(NSDictionary *)errorDict
{
    [aNetService stop];
    [aNetService release];
}

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
					
					NSRunCriticalAlertPanel( NSLocalizedString( @"Registration Key", nil), [NSString stringWithFormat: NSLocalizedString( @"There is already another running OsiriX application using this registration key. Buy another license or a site license to run multiple instances of OsiriX at the same time.\r\r%@", nil), info], NSLocalizedString( @"OK", nil), nil, nil);
					exit(0);
				}
			}
		}
	}
    
    [aNetService stop];
    [aNetService release];
}

#endif

-(void) displayError: (NSString*) err
{
	NSRunCriticalAlertPanel( NSLocalizedString( @"Error", nil), err, NSLocalizedString( @"OK", nil), nil, nil);
}

-(void) displayListenerError: (NSString*) err // the DiscPublishing plugin swizzles this method, do not rename it
{
	NSLog( @"*** listener error (displayListenerError): %@", err);
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
	{
		NSAlert* alert = [[NSAlert new] autorelease];
		[alert setMessageText: NSLocalizedString( @"DICOM Listener Error", nil)];
		[alert setInformativeText: [err stringByAppendingString: @"\r\rThis error message can be hidden by activating the Server Mode (see Listener Preferences)"]];
		[alert addButtonWithTitle: NSLocalizedString(@"OK", nil)];
		
		[alert beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
}

-(void) startSTORESCP:(id) sender
{
	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method

	#ifndef OSIRIX_LIGHT
	[STORESCP lock];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [NSThread currentThread].name = @"DICOM Store-SCP";
    
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
		N2LogExceptionWithStackTrace(e);
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
	
    [NSThread currentThread].name = @"DICOM Store-SCP TLS";
    
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
            N2LogExceptionWithStackTrace(e);
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
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"httpXMLRPCServer"] == NO)
		{
			int result = NSRunInformationalAlertPanel(NSLocalizedString(@"URL scheme", nil), NSLocalizedString(@"OsiriX URL scheme (osirix://) is currently not activated!\r\rShould I activate it now? Restart is necessary.", nil), NSLocalizedString(@"No",nil), NSLocalizedString(@"Activate & Restart",nil), nil);
			
			if( result == NSAlertAlternateReturn)
			{
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"httpXMLRPCServer"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				[[NSApplication sharedApplication] terminate: self];
			}
		}
		
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
		
        if( [url.pathExtension isEqualToString: @"xml"])
        {
            [[BrowserController currentBrowser] asyncWADOXMLDownloadURL: url];
		}
		else if([urlComponents count] == 2)
		{
            NSString *parameterString = @"";
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
                            NSString* value = [param substringFromIndex:separatorRange.location+1];
                            unichar c = [value characterAtIndex:0];
                            if ((c == '"' || c == '\'') && [value characterAtIndex:value.length-1] == c)
                                value = [value substringWithRange:NSMakeRange(1,value.length-2)];
							[urlParameters setObject:value forKey:[param substringToIndex: separatorRange.location]];
						}
						@catch (NSException * e)
						{
							NSLog( @"**** exception in getUrl: %@", param);
						}
					}
				}
				
				if( [urlParameters objectForKey: @"methodName"]) // XML-RPC message
				{
                    NSMutableDictionary* paramDict = [NSMutableDictionary dictionaryWithDictionary:urlParameters];
                    [XMLRPCServer methodCall:[urlParameters objectForKey:@"methodName"] parameters:paramDict error:NULL];
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
								NSPredicate	*request = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: sopinstanceuid]] customSelector: @selector(isEqualToSopInstanceUID:)];
								
								NSArray *imagesArray = [allImages filteredArrayUsingPredicate: request];
								
								if( [imagesArray count])
								{
									[[BrowserController currentBrowser] displayStudy: [[imagesArray lastObject] valueForKeyPath: @"series.study"] object: [imagesArray lastObject] command: @"Open"];
									succeeded = YES;
								}
							}
							@catch (NSException * e)
							{
                                N2LogExceptionWithStackTrace(e);
							}
							
							[context unlock];
						}
						//Second option, try to find the uid in the ENTIRE db....
						
						if( succeeded == NO)
						{
							NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[[BrowserController currentBrowser] database] seriesEntity]];
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
                                N2LogExceptionWithStackTrace(e);
							}
							[wait end];
							[wait close];
							[wait autorelease];
							
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

    // exclude --LoadPlugin arguments
    NSMutableArray* passedFilenames = [NSMutableArray array];
    NSArray* args = [[NSProcessInfo processInfo] arguments];
    for (NSString* path in filenames) {
        BOOL isLoadPlugin = NO;
        for (NSInteger i = 0; !isLoadPlugin && i < (long)args.count-1; ++i)
            if ([[args objectAtIndex:i] isEqualToString:@"--LoadPlugin"])
                if ([[args objectAtIndex:i+1] isEqualToString:path])
                    isLoadPlugin = YES;
        if (!isLoadPlugin)
            [passedFilenames addObject:path];
    }

	[[BrowserController currentBrowser] subSelectFilesAndFoldersToAdd: passedFilenames];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if (!_appDidFinishLoading)
        return;
    
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
	[wait autorelease];
	
	unlink( "/tmp/kill_all_storescu");
	
	[[NSUserDefaults standardUserDefaults] setBool: hideListenerError_copy forKey: @"hideListenerError"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"copyHideListenerError"];
	[[NSUserDefaults standardUserDefaults] synchronize];
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
	
	// DELETE THE DUMP DIRECTORY...
	NSString *dumpDirectory = [[DicomDatabase activeLocalDatabase] dumpDirPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory])
		[[NSFileManager defaultManager] removeItemAtPath:dumpDirectory error:NULL];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory])
        [[NSFileManager defaultManager] moveItemAtPathToTrash: dumpDirectory];
    if ([[NSFileManager defaultManager] fileExistsAtPath: dumpDirectory])
        NSLog( @"******** FAILED to clean the dumpDirectory directory: %@", dumpDirectory);
    
    NSString *tempDirectory = [[DicomDatabase activeLocalDatabase] tempDirPath];
    NSString *decompressionDirectory = [[DicomDatabase activeLocalDatabase] decompressionDirPath];

    if (![NSUserDefaults.standardUserDefaults boolForKey:@"DoNotEmptyIncomingDir"]) // not DoNot -> delete files
    {
        // DELETE the content of TEMP.noindex directory...
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory])
            [[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:NULL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory])
            [[NSFileManager defaultManager] moveItemAtPathToTrash: tempDirectory];
        if ([[NSFileManager defaultManager] fileExistsAtPath: tempDirectory])
            NSLog( @"******** FAILED to clean the tempDirectory directory: %@", tempDirectory);
        
        // DELETE THE DECOMPRESSION.noindex DIRECTORY...
        if ([[NSFileManager defaultManager] fileExistsAtPath:decompressionDirectory])
            [[NSFileManager defaultManager] removeItemAtPath:decompressionDirectory error:NULL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:decompressionDirectory])
            [[NSFileManager defaultManager] moveItemAtPathToTrash: decompressionDirectory];
        if ([[NSFileManager defaultManager] fileExistsAtPath: decompressionDirectory])
            NSLog( @"******** FAILED to clean the decompressionDirectory directory: %@", decompressionDirectory);
    }

	// Delete all process_state files
	for (NSString* s in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: @"/tmp" error:nil])
		if ([s hasPrefix:@"process_state-"])
			[[NSFileManager defaultManager] removeItemAtPath:[@"/tmp" stringByAppendingPathComponent:s] error:nil];
	
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/zippedCD/" error:nil];

    NSString *tmpDirPath = [[NSFileManager defaultManager] tmpDirPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath: tmpDirPath])
        [[NSFileManager defaultManager] removeItemAtPath: tmpDirPath error:NULL];
    if ([[NSFileManager defaultManager] fileExistsAtPath: tmpDirPath])
        [[NSFileManager defaultManager] moveItemAtPathToTrash: tmpDirPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath: tmpDirPath])
        NSLog( @"******** FAILED to clean the tmpDirPath directory: %@", tmpDirPath);
    
    // EMPTY THE INCOMING.noindex DIRECTORY...
    NSString* incomingDirectoryPath = [[DicomDatabase activeLocalDatabase] incomingDirPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath: incomingDirectoryPath] && ![NSUserDefaults.standardUserDefaults boolForKey:@"DoNotEmptyIncomingDir"])
    {
		for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: incomingDirectoryPath error: nil])
			[[NSFileManager defaultManager] removeItemAtPath: [tempDirectory stringByAppendingPathComponent:file] error: nil];
        
        for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: incomingDirectoryPath error: nil])
			[[NSFileManager defaultManager] moveItemAtPathToTrash: [tempDirectory stringByAppendingPathComponent:file]];
        
        if( [[[NSFileManager defaultManager] contentsOfDirectoryAtPath: incomingDirectoryPath error: nil] count])
            [[NSFileManager defaultManager] moveItemAtPathToTrash: incomingDirectoryPath];
        
        if ([[[NSFileManager defaultManager] contentsOfDirectoryAtPath: incomingDirectoryPath error: nil] count])
            NSLog( @"******** FAILED to clean the INCOMING.noindex directory: %@", incomingDirectoryPath);
    }

    [[NSFileManager defaultManager] confirmDirectoryAtPath: incomingDirectoryPath];
}

- (void) terminate :(id) sender
{
	if( [[BrowserController currentBrowser] shouldTerminate: sender] == NO) return;
	
    for( NSWindow *w in [NSApp windows])
		[w orderOut:sender];
    
	#ifndef OSIRIX_LIGHT
	[dcmtkQRSCP abort];
	[dcmtkQRSCPTLS abort];
	#endif
	
    [NSThread sleepForTimeInterval: 0.5];
    
	#ifndef OSIRIX_LIGHT
	[[QueryController currentQueryController] release];
	[[QueryController currentAutoQueryController] release];
    #endif
	
    NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
    while ([[[ThreadsManager defaultManager] threads] count] && [NSDate timeIntervalSinceReferenceDate]-t < 10) { // give declared background threads 10 secs to cancel
        for (NSThread* thread in [[ThreadsManager defaultManager] threads])
            if (![thread isCancelled])
                [thread cancel];
        [NSThread sleepForTimeInterval:0.05];
    }
    
    for( NSWindow *w in [NSApp windows])
		[w close];
    
	[[NSUserDefaults standardUserDefaults] synchronize];
	
    [OSIGeneralPreferencePanePref applyLanguagesIfNeeded];
    
	[NSApp terminate: sender];
}

- (id)init
{
    @try
    {
        self = [super init];
        OsiriX = appController = self;
        
        [[NSFileManager defaultManager] removeItemAtPath:[[NSFileManager defaultManager] tmpDirPath] error:NULL];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kLocalDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]] stringByAppendingPathComponent:@"DLog.enable"]])
            [N2Debug setActive:YES];
        
    //  NSLog(@"%@ -> %d", [[[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kLocalDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]] stringByAppendingPathComponent:@"DLog.enable"], [N2Debug isActive]);
        
        PapyrusLock = [[NSRecursiveLock alloc] init];
        STORESCP = [[NSRecursiveLock alloc] init];
        STORESCPTLS = [[NSRecursiveLock alloc] init];
        
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
        
        #ifndef OSIRIX_LIGHT
        [VRView testGraphicBoard];
        #endif
    }
    @catch (NSException * e)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Error", nil), e.reason, NSLocalizedString(@"OK", nil), nil, nil);
        
        N2LogExceptionWithStackTrace(e);
    }
        
	return self;
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
//    N2LogExceptionWithStackTrace(e);
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
//			if( [[NSDate date] timeIntervalSinceDate: [NSCalendarDate dateWithYear:2012 month:11 day:10 hour:1 minute:1 second:1 timeZone:nil]] > 0 || [[NSUserDefaults standardUserDefaults] boolForKey:@"Outdated2"])
//			{
//				NSRunCriticalAlertPanel(NSLocalizedString(@"Outdated Version", nil), NSLocalizedString(@"Please update your application. Available on the web site.", nil), NSLocalizedString(@"OK", nil), nil, nil);
//				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Outdated2"];
//				[[NSUserDefaults standardUserDefaults] synchronize];
//				exit( 0);
//			}
//            NSRunCriticalAlertPanel(NSLocalizedString(@"Training Version", nil), NSLocalizedString(@"Training version for rcs2.pl.", nil), NSLocalizedString(@"OK", nil), nil, nil);
//			#endif
						
			if( [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundlePackageType"] isEqualToString: @"APPL"])
			{
				[NSThread detachNewThreadSelector: @selector(DNSResolve:) toTarget: self withObject: nil];
							
				initialized = YES;
				
				long	i;
				
				srandom(time(NULL));
				
				Altivec = HasAltiVec();
				//	if( Altivec == 0)
				//	{
				//		NSRunCriticalAlertPanel(@"Hardware Info", @"This application is optimized for Altivec - Velocity Engine unit, available only on G4/G5 processors.", @"OK", nil, nil);
				//		exit(0);
				//	}
				
				if ([AppController hasMacOSXSnowLeopard] == NO)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"Mac OS X", nil), NSLocalizedString(@"This application requires Mac OS X 10.6 or higher. Please upgrade your operating system.", nil), NSLocalizedString(@"Quit", nil), nil, nil);
					exit(0);
				}
                
                int processors;
                int mib[2] = {CTL_HW, HW_NCPU};
                size_t dataLen = sizeof(int); // 'num' is an 'int'
                int result = sysctl(mib, 2, &processors, &dataLen, NULL, 0);
                if (result == -1)
                    processors = 1;
                
                NSLog(@"*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*-+-*");
				NSLog(@"Number of processors: %d / %d", processors, (int) [[NSProcessInfo processInfo] processorCount]);
				NSLog(@"Main screen backingScaleFactor: %f", (float) [[NSScreen mainScreen] backingScaleFactor]);
                NSLog(@"Version: %@ - %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"]);
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
                [[NSUserDefaults standardUserDefaults] setInteger:200 forKey:@"NSInitialToolTipDelay"];
                [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"DontUseUndoQueueForROIs"];
                [[NSUserDefaults standardUserDefaults] setInteger: 20 forKey: @"UndoQueueSize"];
                
                // AutoClean evolution: old defaults AUTOCLEANINGSPACEPRODUCED and AUTOCLEANINGSPACEOPENED are merged into AutocleanSpaceMode
                if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AutocleanSpaceMode"] == nil) {
                    BOOL cleanOldest = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AUTOCLEANINGSPACEPRODUCED"] boolValue];
                    BOOL cleanOldestUnopened = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AUTOCLEANINGSPACEOPENED"] boolValue];
                    if (!cleanOldest && !cleanOldestUnopened) {
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AUTOCLEANINGSPACE"];
                        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"AutocleanSpaceMode"];
                    } else if (cleanOldestUnopened) {
                        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"AutocleanSpaceMode"];
                    } else 
                        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"AutocleanSpaceMode"];
                }
                
				[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
				[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
				
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OSIEnvironmentActivated"];
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"is12bitPluginAvailable"];
//				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DONTCOPYWLWWSETTINGS"];
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ROITEXTNAMEONLY"];
				
				if( [[NSUserDefaults standardUserDefaults] objectForKey: @"copyHideListenerError"])
					[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey: @"copyHideListenerError"] forKey: @"hideListenerError"];
				
				#ifdef MACAPPSTORE
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MACAPPSTORE"]; // Also modify in DefaultsOsiriX.m
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AUTHENTICATION"];
				[[NSUserDefaults standardUserDefaults] setObject: NSLocalizedString( @"(~/Library/Application Support/OsiriX App/)", nil) forKey:@"DefaultDatabasePath"];
				#else
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MACAPPSTORE"]; // Also modify in DefaultsOsiriX.m
				[[NSUserDefaults standardUserDefaults] setObject: NSLocalizedString( @"(Current User Documents folder)", nil) forKey:@"DefaultDatabasePath"];
				#endif
				
				#ifdef __LP64__
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"LP64bit"];
				#else
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"LP64bit"];
				#endif
                
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_name"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_id"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_accession_number"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_birthdate"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_description"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_referring_physician"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_comments"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_institution"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_study_date"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_modality"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_blank_query"];
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"allow_qr_custom_dicom_field"];
				
                
                
                
                // if we are loading a database that isn't on the root volume, then we must wait for it to load - if it doesn't become available after a few minutes, then we'll just let osirix switch to the db at ~/Documents as it would do anyway
                
                NSString* dataBasePath = nil;
                @try {
                    dataBasePath = documentsDirectoryFor([[NSUserDefaults standardUserDefaults] integerForKey:@"DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]);
                }
                @catch (NSException *e) {
                    N2LogException( e);
                }
                
                if ([dataBasePath hasPrefix:@"/Volumes/"] || dataBasePath == nil) {
                    NSString* volumePath = [[[dataBasePath componentsSeparatedByString:@"/"] subarrayWithRange:NSMakeRange(0,3)] componentsJoinedByString:@"/"];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:volumePath]) {
                        NSPanel* dialog = [NSPanel alertWithTitle:@"OsiriX Data"
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"OsiriX is configured to use the database located at %@. This volume is currently not available, most likely because it hasn't yet been mounted by the system, or because it is not plugged in or is turned off, or because you don't have write permissions for this location. OsiriX will wait for a few minutes, then give up and switch to a database in the current user's home directory.", nil), [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]]
                                                    defaultButton:@"Quit"
                                                  alternateButton:@"Continue"
                                                             icon:nil];
                        NSModalSession session = [NSApp beginModalSessionForWindow:dialog];
                        
                        NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate]+10*60; // if ignored, the dialog stays up for 10 minutes
                        for (;;) {
                            NSInteger r = [NSApp runModalSession:session];
                            if (r == NSAlertDefaultReturn) // default button says Quit
                                exit(0);
                            else if (r == NSAlertAlternateReturn) // alternate button says Continue
                                break;
                            if ([[NSFileManager defaultManager] fileExistsAtPath:volumePath]) // the volume has become available, we can close the dialog
                                break;
                            if ([NSDate timeIntervalSinceReferenceDate] > endTime) { // time's out, we close the dialog
                                NSLog(@"Warning: after waiting for 10 minutes, OsiriX is switching to the default database location because %@ is still not available", volumePath);
                                break;
                            }
                        }
                        
                        [NSApp endModalSession:session];
                        [dialog orderOut:self];
                        
                        @try {
                            dataBasePath = documentsDirectoryFor([[NSUserDefaults standardUserDefaults] integerForKey:@"DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]);
                        }
                        @catch (NSException *e) {
                            [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
                            [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DEFAULT_DATABASELOCATION"];
                        }
                    }
                }
                
                // now, sometimes databases point to other volumes for data storage through the DBFOLDER_LOCATION file, so if it's the case verify that that volume is mounted, too
                dataBasePath = [DicomDatabase baseDirPathForPath:dataBasePath]; // we know this is the ".../OsiriX Data" path
                // TODO: sometimes people use an alias... and if it's an alias, we should check that it points to an available volume..... should.
                NSString* dataBaseDataPath = [NSString stringWithContentsOfFile:[dataBasePath stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] encoding:NSUTF8StringEncoding error:NULL];
                if ([dataBaseDataPath hasPrefix:@"/Volumes/"]) {
                    NSString* volumePath = [[[dataBaseDataPath componentsSeparatedByString:@"/"] subarrayWithRange:NSMakeRange(0,3)] componentsJoinedByString:@"/"];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:volumePath]) {
                        NSPanel* dialog = [NSPanel alertWithTitle:@"OsiriX Data"
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"OsiriX is configured to use the database with data located at %@. This volume is currently not available, most likely because it hasn't yet been mounted by the system, or because it is not plugged in or is turned off, or because you don't have write permissions for this location. OsiriX will wait for a few minutes, then give up and ignore this highly dangerous situation.", nil), dataBaseDataPath]
                                                    defaultButton:@"Quit"
                                                  alternateButton:@"Continue"
                                                             icon:nil];
                        NSModalSession session = [NSApp beginModalSessionForWindow:dialog];
                        
                        NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate]+10*60; // if ignored, the dialog stays up for 10 minutes
                        for (;;) {
                            NSInteger r = [NSApp runModalSession:session];
                            if (r == NSAlertDefaultReturn) // default button says Quit
                                exit(0);
                            else if (r == NSAlertAlternateReturn) // alternate button says Continue
                                break;
                            if ([[NSFileManager defaultManager] fileExistsAtPath:volumePath]) // the volume has become available, we can close the dialog
                                break;
                            if ([NSDate timeIntervalSinceReferenceDate] > endTime) { // time's out, we close the dialog
                                NSLog(@"Warning: after waiting for 10 minutes, OsiriX is switching to the default database location because %@ is still not available", volumePath);
                                break;
                            }
                        }
                        
                        [NSApp endModalSession:session];
                        [dialog orderOut:self];
                    }
                }
                
                
                
                
                
                
                pluginManager = [[PluginManager alloc] init];
                
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
				if (!wwwl)
                {
					[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:-300], [NSNumber numberWithFloat:700], nil] forKey:@"VR - Endoscopy"];
					[[NSUserDefaults standardUserDefaults] setObject:wlwwValues forKey:@"WLWW3"];
				}
				
                
				// CREATE A TEMPORATY FILE DURING STARTUP
				
				NSString* path = [[DicomDatabase defaultBaseDirPath] stringByAppendingPathComponent:@"Loading"];
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
                {
                    if( [[NSFileManager defaultManager] fileExistsAtPath: path])
                    {
                        int result = NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX crashed during last startup", nil), NSLocalizedString(@"Previous crash is maybe related to a corrupt database or corrupted images.\r\rShould I run OsiriX in Protected Mode (recommended) (no images displayed)? To allow you to delete the crashing/corrupted images/studies.\r\rOr Should I rebuild the local database? All albums, comments and status will be lost.", nil), NSLocalizedString(@"Continue normally",nil), NSLocalizedString(@"Protected Mode",nil), NSLocalizedString(@"Rebuild Database",nil));
                        
                        if( result == NSAlertOtherReturn)
                        {
                            NEEDTOREBUILD = YES;
                            COMPLETEREBUILD = YES;
                        }
                        if( result == NSAlertAlternateReturn) [DCMPix setRunOsiriXInProtectedMode: YES];
                    }
                }
                
                [path writeToFile:path atomically:NO encoding: NSUTF8StringEncoding error: nil];
				
                [self checkForWordTemplates];
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
    
//    NSUserNotification *userNotification = [[NSUserNotification new] autorelease];
//    
//    userNotification.title = title;
//    userNotification.subtitle = description;
//    
//    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: userNotification];
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"doNotUseGrowl"]) return nil;
	
    NSDictionary *dict = nil;
	
#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
    
    NSArray *notifications = [NSArray arrayWithObjects: @"newstudy", @"newfiles", @"delete", @"result", @"autorouting", @"autoquery", @"send", nil];
    
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                             notifications, GROWL_NOTIFICATIONS_ALL,
                         notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
#endif
#endif
    return dict;
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
	
	[NSThread sleepForTimeInterval: 0.1];
	
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NinjaSTORESCP"]) // some undefined external entity is linked to OsiriX for DICOM communications...
        return YES;
		
	return NO;
}

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
	unlink( "/tmp/kill_all_storescu");
	
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

	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"TOOLKITPARSER4"] == 0 || [[NSUserDefaults standardUserDefaults] boolForKey:@"USEPAPYRUSDCMPIX4"] == NO)
	{
		[self growlTitle: NSLocalizedString( @"Warning!", nil) description: NSLocalizedString( @"DCM Framework is selected as the DICOM reader/parser. The performances of this toolkit are slower.", nil)  name:@"result"];
        
        NSLog( @"********");
        NSLog( @"********");
        NSLog( @"********");
		NSLog( @"******** %@", NSLocalizedString( @"DCM Framework is selected as the DICOM reader/parser. The performances of this toolkit are slower.", nil));
        NSLog( @"********");
        NSLog( @"********");
        NSLog( @"********");
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SingleProcessMultiThreadedListener"] == NO)
		NSLog( @"----- %@", NSLocalizedString( @"DICOM Listener is multi-processes mode.", nil));
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"])
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"checkForUpdatesPlugins"];
	
	#ifndef MACAPPSTORE
	#ifndef OSIRIX_LIGHT
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"checkForUpdatesPlugins"])
		[NSThread detachNewThreadSelector:@selector(checkForUpdates:) toTarget:pluginManager withObject:pluginManager];
	
    
    // If OsiriX crashed before...
    NSString *OsiriXCrashed = @"/tmp/OsiriXCrashed";
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: OsiriXCrashed]) // Activate check for update !
    {
        [[NSFileManager defaultManager] removeItemAtPath: OsiriXCrashed error: nil];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CheckOsiriXUpdates4"] == NO)
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
                [NSThread detachNewThreadSelector: @selector(checkForUpdates:) toTarget: self withObject: @"crash"];
        }
    }
    else [NSThread detachNewThreadSelector: @selector(checkForUpdates:) toTarget:self withObject: self];
    
	#endif
	#endif
    
    // Remove PluginManager items...
    #ifdef MACAPPSTORE
    NSMenu *pluginsMenu = [filtersMenu supermenu];
    
    [pluginsMenu removeItemAtIndex: [pluginsMenu numberOfItems]-1];
    [pluginsMenu removeItemAtIndex: [pluginsMenu numberOfItems]-1];
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
		N2LogExceptionWithStackTrace(e);
		exit( 0);
	}
	
#endif
	
	
//	NSString *source = [NSString stringWithContentsOfFile: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"]];
//	
//	NSArray *lines = [source componentsSeparatedByString: @"\n"];
//	
//	NSMutableDictionary *nameDictionary = [NSMutableDictionary dictionary], *tagDictionary = [NSMutableDictionary dictionary];
//	
//    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"DCMTagDictionary")];
//    
//    tagDictionary = [NSMutableDictionary dictionaryWithContentsOfFile: [bundle pathForResource:@"tagDictionary" ofType:@"plist"]];
//    nameDictionary = [NSMutableDictionary dictionaryWithContentsOfFile: [bundle pathForResource:@"nameDictionary" ofType:@"plist"]];
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
//                    if( [tagDictionary objectForKey: grel])
//                    {
////                        NSLog( @"%@", [tagDictionary objectForKey: grel]);
//                    }
//                    else
//                    {
//                        NSLog( @"%@", d);
//                        
//                        [tagDictionary setObject: d forKey: grel];
//                        [nameDictionary setObject: grel forKey: [f objectAtIndex: 2]];
//                    }
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

	#ifdef NDEBUG
	#else
	NSLog( @"Testing localization for menus");
	NSMenu *mainMenu = [NSApp mainMenu];
	
	if( [[[mainMenu itemAtIndex: 5] title] isEqualToString: NSLocalizedString(@"2D Viewer", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 1");
    
	if( [[[mainMenu itemAtIndex: 1] title] isEqualToString: NSLocalizedString(@"File", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 2");
	
	NSMenu *viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
	
	if( [[[viewerMenu itemAtIndex: 41] title] isEqualToString: NSLocalizedString(@"Window Width & Level", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 3");
    
	if( [[[viewerMenu itemAtIndex: 48] title] isEqualToString: NSLocalizedString(@"Image Tiling", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 4");
    
	if( [[[viewerMenu itemAtIndex: 12] title] isEqualToString: NSLocalizedString(@"Orientation", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 5");
    
	if( [[[viewerMenu itemAtIndex: 44] title] isEqualToString: NSLocalizedString(@"Opacity", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 6");
    
	if( [[[viewerMenu itemAtIndex: 45] title] isEqualToString: NSLocalizedString(@"Convolution Filters", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 7");
    
	if( [[[viewerMenu itemAtIndex: 42] title] isEqualToString: NSLocalizedString(@"Color Look Up Table", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 8");
	
	NSMenu *fileMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"File", nil)] submenu];
	
	if( [[[fileMenu itemAtIndex: 12] title] isEqualToString: NSLocalizedString(@"Export", nil)] == NO)
        NSLog( @"******* WARNING MENU MOVED / RENAMED ! LOCALIZATION PROBLEMS 10");
    
    if( [[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"odt2pdf"] == nil)
    {
        NSLog( @"\r****** path2odt2pdf == nil\r*****************************");
    }
    
	#endif
    
    _appDidFinishLoading = YES;
    
    [ROI loadDefaultSettings];
    
#ifndef OSIRIX_LIGHT
    PFMoveToApplicationsFolderIfNecessary();

    if( [AppController isFDACleared])
    {
        
        SecRequirementRef requirement = 0;
        SecStaticCodeRef code = 0;
        
        OSStatus status = SecRequirementCreateWithString( (CFStringRef) @"anchor trusted and certificate leaf [subject.CN] = \"Developer ID Application: Antoine Rosset\"", kSecCSDefaultFlags, &requirement);
        
        status = SecStaticCodeCreateWithPath( (CFURLRef) [[NSBundle mainBundle] bundleURL], kSecCSDefaultFlags, &code);
        
        NSError *errors = nil;
        
        status = SecStaticCodeCheckValidityWithErrors(code, kSecCSDefaultFlags, requirement, (CFErrorRef*) &errors);
        
        if(status != noErr)
        {
            NSLog( @"SecStaticCodeCheckValidity: %d", (int) status);
            NSLog( @"%@", errors);
            
            NSRunCriticalAlertPanel( NSLocalizedString( @"Code signing and Certificate", nil), [NSString stringWithFormat: NSLocalizedString( @"Invalid code signing or certificate. Redownload OsiriX from the pixmeo web site.\r\r%@\r\r%@", nil), errors.localizedDescription, errors.userInfo], NSLocalizedString( @"Quit", nil) , nil, nil);
            exit( 0);
        }
        
        CFRelease( requirement);
        CFRelease( code);
    }
#endif
    
    if( [AppController hasMacOSXLion] == NO)
    {
        NSRunCriticalAlertPanel( NSLocalizedString( @"MacOS Version", nil), NSLocalizedString( @"OsiriX requires MacOS 10.7.5 or higher. Please update your OS: Apple Menu - Software Update...", nil), NSLocalizedString( @"Quit", nil) , nil, nil);
        exit( 0);
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SyncPreferencesFromURL"])
        [NSThread detachNewThreadSelector: @selector( addPreferencesFromURL:) toTarget: [OSIGeneralPreferencePanePref class] withObject: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"SyncPreferencesURL"]]];
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

#define kIOPCIDevice                "IOPCIDevice"
#define kIONameKey                  "IOName"
#define kDisplayKey                 "display"
#define kModelKey                   "model"
#define kIntelGPUPrefix             @"Intel"
+ (NSArray *)getGPUNames
{
    NSMutableArray *GPUs = [NSMutableArray array];
    
    // The IOPCIDevice class includes display adapters/GPUs.
    CFMutableDictionaryRef devices = IOServiceMatching(kIOPCIDevice);
    io_iterator_t entryIterator;
    
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, devices, &entryIterator) == kIOReturnSuccess) {
        io_registry_entry_t device;
        
        while ((device = IOIteratorNext(entryIterator))) {
            CFMutableDictionaryRef serviceDictionary;
            
            if (IORegistryEntryCreateCFProperties(device, &serviceDictionary, kCFAllocatorDefault, kNilOptions) != kIOReturnSuccess) {
                // Couldn't get the properties for this service, so clean up and
                // continue.
                IOObjectRelease(device);
                continue;
            }
            
            const void *ioName = CFDictionaryGetValue(serviceDictionary, @kIONameKey);
            
            if (ioName) {
                // If we have an IOName, and its value is "display", then we've
                // got a "model" key, whose value is a CFDataRef that we can
                // convert into a string.
                if (CFGetTypeID(ioName) == CFStringGetTypeID() && CFStringCompare(ioName, CFSTR(kDisplayKey), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                    const void *model = CFDictionaryGetValue(serviceDictionary, @kModelKey);
                    
                    NSString *gpuName = [[[NSString alloc] initWithData:( NSData *)model
                                                              encoding:NSASCIIStringEncoding] autorelease];
                    
                    [GPUs addObject:gpuName];
                }
            }
            
            CFRelease(serviceDictionary);
        }
    }
    
    return GPUs;
}

-(void)verifyHardwareInterpolation
{
    if( [AppController hasMacOSX1083]) // Intel 10.8.3 graphic bug
    {
        BOOL onlyIntelGraphicBoard = YES;
        for( NSString *gpuName in [AppController getGPUNames])
        {
            if( [gpuName hasPrefix: kIntelGPUPrefix] == NO)
                onlyIntelGraphicBoard = NO;
        }
        
        if( onlyIntelGraphicBoard)
        {
            NSLog( @"**** 10.8.3 graphic board bug: only intel board discovered : No 32-bit pipeline available");
            NSLog( @"%@", [AppController getGPUNames]);
            
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FULL32BITPIPELINE"];
            return;
        }
    }
    
	NSUInteger size = 32, size2 = size*size;
	
	NSWindow* win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,size,size) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
	
	long annotCopy = [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"];
	long clutBarsCopy = [[NSUserDefaults standardUserDefaults] integerForKey:@"CLUTBARS"];
	BOOL noInterpolationCopy = [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"];
	BOOL highQInterpolationCopy = [[NSUserDefaults standardUserDefaults] boolForKey:@"SOFTWAREINTERPOLATION"];
	
	float pixData[] = {0,1,1,0};
	DCMPix* dcmPix = [[DCMPix alloc] initWithData:pixData :32 :2 :2 :1 :1 :0 :0 :0];
	
	CGLContextObj cgl_ctx;
	float iwl, iww;
	DCMView* dcmView;
    unsigned char* planes[1];
	unsigned char gray_2[size2];
    unsigned char gray_1[size2];
    
	[[NSUserDefaults standardUserDefaults] setInteger:annotNone forKey:@"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger:barHide forKey:@"CLUTBARS"];
	
	// pix 1: no interpolation
    
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NOINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SOFTWAREINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FULL32BITPIPELINE"];
	
	dcmView = [[DCMView alloc] initWithFrame:NSMakeRect(0, 0, size,size)];
	[dcmView setPixels:[NSArray arrayWithObject:dcmPix] files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
	[dcmView setScaleValueCentered:size];
	[win.contentView addSubview:dcmView];
	[dcmView drawRect:NSMakeRect(0,0,size,size)];
    
    {
        float o[ 9], imOrigin[ 3], imSpacing[ 2];
        long width, height, spp, bpp;
        
        unsigned char *data = [dcmView getRawPixelsViewWidth: &width height: &height spp: &spp bpp: &bpp screenCapture: YES force8bits: YES removeGraphical: YES squarePixels: YES allowSmartCropping: NO origin: imOrigin spacing: imSpacing offset: nil isSigned: nil];
        
        assert( spp == 3);
        
        if( data)
        {
            for (int i = 0; i < size2; ++i)
                gray_1[i] = (data[i*3]+data[i*3+1]+data[i*3+2])/3;
            free( data);
            
//            planes[0] = gray_1;
//            NSBitmapImageRep* representation = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
//                                                                                       pixelsWide:size pixelsHigh:size bitsPerSample:8
//                                                                                  samplesPerPixel:1 hasAlpha:NO isPlanar:NO
//                                                                                   colorSpaceName:NSCalibratedBlackColorSpace bytesPerRow:size
//                                                                                     bitsPerPixel:8];
//            [[representation TIFFRepresentation] writeToFile:@"/tmp/aaaaa1.tif" atomically:YES];
//            [representation release];
        }
    }
    
	[dcmView removeFromSuperview];
	[dcmView release];
	
	// pix 2: interpolation
	
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NOINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SOFTWAREINTERPOLATION"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FULL32BITPIPELINE"];
	dcmView = [[DCMView alloc] initWithFrame: NSMakeRect(0, 0, size,size)];
	[dcmView setPixels:[NSArray arrayWithObject:dcmPix] files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
	[dcmView setScaleValueCentered:size];
	[win.contentView addSubview:dcmView];
	[dcmView drawRect:NSMakeRect(0,0,size,size)];
	
    {
        float o[ 9], imOrigin[ 3], imSpacing[ 2];
        long width, height, spp, bpp;
        
        unsigned char *data = [dcmView getRawPixelsViewWidth: &width height: &height spp: &spp bpp: &bpp screenCapture: YES force8bits: YES removeGraphical: YES squarePixels: YES allowSmartCropping: NO origin: imOrigin spacing: imSpacing offset: nil isSigned: nil];
        
        assert( spp == 3);
        
        if( data)
        {
            for (int i = 0; i < size2; ++i)
                gray_1[i] = (data[i*3]+data[i*3+1]+data[i*3+2])/3;
            free( data);
            
//            planes[0] = gray_1;
//            NSBitmapImageRep* representation = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes
//                                                                                       pixelsWide:size pixelsHigh:size bitsPerSample:8
//                                                                                  samplesPerPixel:1 hasAlpha:NO isPlanar:NO
//                                                                                   colorSpaceName:NSCalibratedBlackColorSpace bytesPerRow:size
//                                                                                     bitsPerPixel:8];
//            [[representation TIFFRepresentation] writeToFile:@"/tmp/aaaaa2.tif" atomically:YES];
//            [representation release];
        }
    }
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
		NSLog( @"-- 32bit pipeline available : delta = %f", delta);
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasFULL32BITPIPELINE"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FULL32BITPIPELINE"];
	}
	else
	{
		NSLog( @"-- 32bit pipeline inactivated : delta = %f", delta);
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasFULL32BITPIPELINE"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FULL32BITPIPELINE"];
	}
}

- (void) applicationWillFinishLaunching: (NSNotification *) aNotification
{
    [AppController cleanOsiriXSubProcesses];
    
    if( [NSDate timeIntervalSinceReferenceDate] - [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastDate32bitPipelineCheck"] > 60L*60L*24L) // 1 days
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
	
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"COPYDATABASEMODE"] intValue] == 1) // tag 1 "if on CD", disappeared after new CD/DVD import system
        [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"COPYDATABASEMODE"];
        
//	NSLog(@"%s", __PRETTY_FUNCTION__, nil);
	
	if( dialog == NO)
	{
		
	}
	
	#ifndef OSIRIX_LIGHT
	#ifndef MACAPPSTORE
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
    {
        @try
        {
            ILCrashReporter *reporter = [ILCrashReporter defaultReporter];
            
            NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
            
            if( [d valueForKey: @"crashReporterSMTPServer"]) {
                reporter.SMTPServer = [d valueForKey: @"crashReporterSMTPServer"];
                int port = [d integerForKey: @"crashReporterSMTPPort"];
                reporter.SMTPPort = port? port : 25;
                // if these are empty, set them to empty
                reporter.SMTPUsername = [d valueForKey: @"crashReporterSMTPUsername"];
                reporter.SMTPPassword = [d valueForKey: @"crashReporterSMTPPassword"];
            }
            
            if( [d valueForKey: @"crashReporterFromAddress"])
                reporter.fromAddress = [d valueForKey: @"crashReporterFromAddress"];
            
            NSString *reportAddr = @"crash@osirix-viewer.com";
            if( [d valueForKey: @"crashReporterToAddress"])
                reportAddr = [d valueForKey: @"crashReporterToAddress"];
            
            reporter.automaticReport = [d boolForKey: @"crashReporterAutomaticReport"];
            
            [reporter launchReporterForCompany: @"OsiriX Developers" reportAddr: reportAddr];
        }
        @catch (NSException *e)
        {
            NSLog( @"**** Exception ILCrashReporter: %@", e);
        }
    }
	#endif
	#endif
	
	[PluginManager setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];
    
	theTask = nil;
	
	appController = self;
	[self initDCMTK];
	[self restartSTORESCP];
	
	[NSTimer scheduledTimerWithTimeInterval: 2 target: self selector: @selector(checkForRestartStoreSCPOrder:) userInfo: nil repeats: YES];
	
	[DicomDatabase initializeDicomDatabaseClass];
	[BrowserController initializeBrowserControllerClass];
	#ifndef OSIRIX_LIGHT
	[WebPortal initializeWebPortalClass];
    _bonjourPublisher = [[BonjourPublisher alloc] init];
	#endif
	
	#ifndef OSIRIX_LIGHT
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"httpXMLRPCServer"]) {
		if(XMLRPCServer == nil) XMLRPCServer = [[XMLRPCInterface alloc] init];
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
	
    #ifndef OSIRIX_LIGHT
	[NSTimer scheduledTimerWithTimeInterval: 5 target: self selector: @selector(checkSN64:) userInfo: nil repeats: NO];
	#endif
    #endif
	
	#ifndef OSIRIX_LIGHT
	#ifndef MACAPPSTORE
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"doNotUseGrowl"] == NO)
	{
        // If Growl crashed before...
        NSString *GrowlCrashed = @"/tmp/OsiriXGrowlCrashed";
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: GrowlCrashed])
        {
            [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"doNotUseGrowl"];
            [[NSFileManager defaultManager] removeItemAtPath: GrowlCrashed error: nil];
        }
        else 
        {
            [GrowlCrashed writeToFile: GrowlCrashed atomically: YES encoding: NSUTF8StringEncoding error: nil];
            
            [GrowlApplicationBridge setGrowlDelegate: self];
            
            [[NSFileManager defaultManager] removeItemAtPath: GrowlCrashed error: nil];
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
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
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
	
    [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseKDUForJPEG2000"];
    [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseOpenJpegForJPEG2000"];
    [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"useDCMTKForJP2K"];
    
	if( [AppController hasMacOSXMountainLion] == NO)
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"EncryptCD"];
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"encryptForExport"];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideNoMountainLionWarning"] == NO)
		{
			NSAlert* alert = [[NSAlert new] autorelease];
			[alert setMessageText: NSLocalizedString( @"Mac OS Version", nil)];
			[alert setInformativeText: NSLocalizedString( @"You should upgrade to MacOS 10.8 or higher, for better performances, more features and more stability.", nil)];
			[alert setShowsSuppressionButton:YES ];
			[alert addButtonWithTitle: NSLocalizedString( @"Continue", nil)];
            [alert addButtonWithTitle: NSLocalizedString( @"Upgrade", nil)];
			if( [alert runModal] == NSAlertSecondButtonReturn)
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/os-x-mountain-lion/id537386512?mt=12"]];
            
			if ([[alert suppressionButton] state] == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"hideNoMountainLionWarning"];
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
    
    
    //if ([NSUserDefaults.standardUserDefaults boolForKey:@"DoNotEmptyIncomingDir"]) // move temp & decompress to incoming
    {
        NSString* inc = [[DicomDatabase activeLocalDatabase] incomingDirPath];
        for (NSString* path in [NSArray arrayWithObjects: [[DicomDatabase activeLocalDatabase] tempDirPath], [[DicomDatabase activeLocalDatabase] decompressionDirPath], nil])
            for (NSString* f in [[NSFileManager defaultManager] enumeratorAtPath:path filesOnly:NO recursive:NO])
                [[NSFileManager defaultManager] moveItemAtPath:[path stringByAppendingPathComponent:f] toPath:[inc stringByAppendingPathComponent:f] error:NULL];
    }
    
    
	
//	[self checkForOsirixMimeType];
	
// 	*(long*)0 = 0xDEADBEEF;	// Test for ILCrashReporter
	
//	[html2pdf pdfFromURL: @"http://zimbra.latour.ch"];

	if( [AppController isKDUEngineAvailable])
		NSLog( @"/*\\ /*\\ KDU Engine AVAILABLE /*\\ /*\\");
	else
		NSLog( @"KDU Engine NOT available");
    
    if( checkSN64String.length)
    {
        NSLog( @"-----------------------------------------------------------------");
        NSLog( @"UID: %@", checkSN64String);
        NSLog( @"-----------------------------------------------------------------");
    }
}

- (IBAction) updateViews:(id) sender
{
	NSArray *winList = [NSApp windows];
	
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

+ (BOOL) isFDACleared
{
	return NO;
}

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
	
    if( [msg isEqualToString: @"UPDATECRASH"])
    {
        NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX crashed", nil), NSLocalizedString(@"OsiriX crashed... You are running an outdated version of OsiriX ! This bug is probably corrected in the last version !", nil), NSLocalizedString(@"OK",nil), nil, nil);
        
        #if __LP64__
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://pixmeo.pixmeo.com/login"]];
        #else
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Downloads.html"]];
        #endif
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
	
	if( sender != self)
        verboseUpdateCheck = YES;
	else
        verboseUpdateCheck = NO;
	
    BOOL verboseAfterCrash = NO;
    
    if( [sender isKindOfClass:[NSString class]] && [sender isEqualToString: @"crash"])
        verboseAfterCrash = YES;
    
	if( [AppController hasMacOSXLion])
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
				if (verboseUpdateCheck && verboseAfterCrash == NO)
				{
					[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"UPTODATE" waitUntilDone: NO];
				}
			}
			else
			{
				if( ([[NSUserDefaults standardUserDefaults] boolForKey: @"CheckOsiriXUpdates4"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO) || verboseUpdateCheck == YES)
				{
                    if( verboseAfterCrash)
                        [self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:@"UPDATECRASH" waitUntilDone: NO];
                    else
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

-(IBAction)showPreferencePanel:(id)sender
{
	[[PreferencesWindowController sharedPreferencesWindowController] showWindow: sender];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
    [browserController release];
	[dcmtkQRSCP release];
	dcmtkQRSCP = nil;
	
	[dcmtkQRSCPTLS release];
	dcmtkQRSCPTLS = nil;
	
//	#ifndef OSIRIX_LIGHT
//	[IChatTheatreDelegate releaseSharedDelegate];
//	#endif
	
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
		if( [[loopItem windowController] respondsToSelector:@selector(pixList)])
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

- (NSArray*)viewerScreens
{
	NSMutableArray* screens = [[[[NSUserDefaults standardUserDefaults] screensUsedForViewers] mutableCopy] autorelease];
    if (!screens.count)
        screens = [[[NSScreen screens] mutableCopy] autorelease];
	
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ReserveScreenForDB"] && [screens containsObject:[dbWindow screen]] && [screens count] > 1)
        [screens removeObjectIdenticalTo:[dbWindow screen]];
    
	// arrange them left to right
    [screens sortUsingComparator:^NSComparisonResult(id o1, id o2) {
        NSRect f1 = ((NSScreen*)o1).frame, f2 = ((NSScreen*)o2).frame;
        CGFloat c1 = f1.origin.x+f1.size.width/2, c2 = f2.origin.x+f2.size.width/2;
        if (c1 < c2) return NSOrderedAscending;
        if (c1 > c2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    return screens;
}

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

		if( USETOOLBARPANEL) frame.size.height -= [[AppController toolbarForScreen:screen] exposedHeight];
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
		[item setAction: @selector(setFixedTilingRows:)];
	}
	
	for( NSMenuItem *item in [windowsTilingMenuColumns itemArray])
	{
		[item setTarget: self];
		[item setAction: @selector(setFixedTilingColumns:)];
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

- (IBAction) tileWindows:(id)sender
{
    NSMutableArray *viewersList = [NSMutableArray array];
    
    //get 2D viewer windows
	for( NSWindow *win in [NSApp orderedWindows])
	{
		if( [[win windowController] isKindOfClass:[OSIWindowController class]] == YES)
		{
			if( [[win windowController] magnetic])
			{
				if( [[win windowController] windowWillClose] == NO && [win isMiniaturized] == NO)
					[viewersList addObject: [win windowController]];
                
				else if( [[win windowController] windowWillClose])
				{
				}
                
				if( [[viewersList lastObject] FullScreenON])
                    return;
			}
		}
        
        [win setAnimationBehavior: NSWindowAnimationBehaviorNone];
	}
    
    [self tileWindows: sender windows: viewersList display2DViewerToolbar: USETOOLBARPANEL];
}

- (IBAction) tile3DWindows:(id)sender
{
    NSMutableArray *viewersList = [NSMutableArray array];
    
    //get 2D viewer windows
	for( NSWindow *win in [NSApp orderedWindows])
	{
		if( [[win windowController] isKindOfClass:[Window3DController class]] == YES)
		{
            if( [[win windowController] windowWillClose] == NO && [win isMiniaturized] == NO && [win isVisible] == YES)
                [viewersList addObject: [win windowController]];
            
            else if( [[win windowController] windowWillClose])
            {
            }
            
            if( [[viewersList lastObject] FullScreenON])
                return;
		}
	}
    
    [self tileWindows: sender windows: viewersList display2DViewerToolbar: NO];
    
    for( NSWindowController *win in viewersList)
        [[win window] makeKeyAndOrderFront: self];
}

- (void) tileWindows:(id)sender windows: (NSMutableArray*) viewersList display2DViewerToolbar: (BOOL) display2DViewerToolbar
{
	BOOL origCopySettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYSETTINGS"];
	NSRect screenRect =  screenFrame();
	BOOL keepSameStudyOnSameScreen = [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesTogetherOnSameScreen"];
	NSMutableArray *studyList = [NSMutableArray array];
	ViewerController *keyWindow = nil;
    
	delayedTileWindows = NO;
	
	[AppController checkForPreferencesUpdate: NO];
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"COPYSETTINGS"];
	[AppController checkForPreferencesUpdate: YES];
	
	//order windows from left-top to right-bottom, per screen if necessary
	NSMutableArray	*cWindows = [NSMutableArray arrayWithArray: viewersList];
	
	// Only the visible windows
	for( int i = (long) [cWindows count]-1; i >= 0; i--)
	{
		if( [[[cWindows objectAtIndex: i] window] isVisible] == NO) [cWindows removeObjectAtIndex: i];
	}
	
    //Retain windows
    NSArray *windows = [cWindows valueForKey: @"window"];
    
	NSMutableArray* screens = [[[self viewerScreens] mutableCopy] autorelease];

    if (viewersList.count < screens.count && [[NSUserDefaults standardUserDefaults] boolForKey: @"UseDBScreenAtLast"])
    {
        NSScreen* dbscreen = [dbWindow screen];
        [screens removeObjectIdenticalTo:dbscreen];
    }

    int numberOfMonitors = [screens count];

	NSMutableArray *cResult = [NSMutableArray array];
    
	@try
	{
		int count = [cWindows count];
		while( count > 0)
		{
			int index = 0;
			int row = [self currentRowForViewer: [cWindows objectAtIndex: index]];
			
			for( int x = 0; x < [cWindows count]; x++)
			{
				if( [self currentRowForViewer: [cWindows objectAtIndex: x]] < row)
				{
					row = [self currentRowForViewer: [cWindows objectAtIndex: x]];
					index = x;
				}
			}
			
			float minX = [self windowCenter: [[cWindows objectAtIndex: index] window]].x;
			
			for( int x = 0; x < [cWindows count]; x++)
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
            
            keyWindow = v;
		}
	}
	
	viewersList = cResult;
	
    if( keyWindow == nil)
    {
        for( ViewerController *v in viewersList)
        {
            if( [[v window] isKeyWindow])
                keyWindow = v;
        }
    }
	
	BOOL identical = YES;
	
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"tileWindowsOrderByStudyDate"])
    {
        if( [hiddenWindows count])
            [hiddenWindows removeAllObjects];
        
        [viewersList sortUsingComparator: ^NSComparisonResult(id obj1, id obj2)
        {
            NSDate *date1 = [[obj1 currentStudy] date];
            NSDate *date2 = [[obj2 currentStudy] date];
            
            return [date2 compare: date1];
        }];
    }
    
	if( keepSameStudyOnSameScreen)
	{
		// Are there different studies
		if( [viewersList count])
		{
			NSString	*studyUID = [[[[viewersList objectAtIndex: 0] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyInstanceUID"];
			
			//get 2D viewer study arrays
			for( int i = 0; i < [viewersList count]; i++)
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
			for( int i = 0; i < [viewersList count]; i++)
			{
				NSString	*studyUID = [[[[viewersList objectAtIndex: i] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyInstanceUID"];
				
				BOOL found = NO;
				// loop through and add to correct array if present
				for( int x = 0; x < [studyList count]; x++)
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
	
    float landscapeRatio = 1.5;
    
    if( screenRect.size.width/screenRect.size.height > 1.7) // 16/9 screen or more
        landscapeRatio = 2.0;
    
    float portraitRatio = 0.9;
    
    if( screenRect.size.height/screenRect.size.width > 1.7) // 16/9 screen or more
        portraitRatio = 0.49;
    
	int rows = [[WindowLayoutManager sharedWindowLayoutManager] windowsRows];
	int columns = [[WindowLayoutManager sharedWindowLayoutManager] windowsColumns];
	
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
	
    if( rows <= 0)
        rows = 1;
    
    if( columns <= 0)
        columns = 1;
    
	//excess viewers. Need to add spaces to accept
	if( viewerCount > (rows * columns))
	{
		float ratioValue;
		
		if( landscape) ratioValue = landscapeRatio;
		else ratioValue = portraitRatio;
		
		float viewerCountPerScreen = (float) viewerCount / (float) numberOfMonitors;
		
        BOOL fixedRows = NO, fixedColumns = NO;
        
        if( [sender isKindOfClass: [NSDictionary class]] && [sender objectForKey: @"rows"])
            fixedRows = YES;
        
        if( [sender isKindOfClass: [NSDictionary class]] && [sender objectForKey: @"columns"])
            fixedColumns = YES;
        
		while (viewerCountPerScreen > (rows * columns))
		{
			if( fixedRows)
				columns++;
			else if( fixedColumns)
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
        
        if( rows * columns > viewerCountPerScreen && rows*(columns-1) == viewerCountPerScreen)
            columns --;
		
        if( rows * columns > viewerCountPerScreen && columns*(rows-1) == viewerCountPerScreen)
            rows --;
        
		columns *= numberOfMonitors;
	}
	
	// Smart arrangement if one window was added or removed
	if( numberOfMonitors == 1)
	{
		@try 
		{
			if( lastColumns != columns)
			{
				if( lastCount == (long) [viewersList count] -1)	// One window was added
				{
					if( columns < [viewersList count])
					{
						[viewersList insertObject: [viewersList lastObject] atIndex: lastColumns];
						[viewersList removeObjectAtIndex: (long) [viewersList count]-1];
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
            N2LogExceptionWithStackTrace(e);
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
			
			for( int i = 0; i < numberOfMonitors && i < [studyList count]; i++)
			{
				NSMutableArray	*viewersForThisScreen = [studyList objectAtIndex:i];
				
				if( i == numberOfMonitors -1 || i == (long) [studyList count]-1)
				{
					// Take all remaining studies
					
					for( int x = i+1; x < [studyList count]; x++)
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
		
		for( int i = 0; i < count; i++)
		{
			NSScreen *screen = [screens objectAtIndex:i];
			NSRect frame = [screen visibleFrame];
			if( display2DViewerToolbar) frame.size.height -= [[AppController toolbarForScreen:screen] exposedHeight];
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
		for( int i = 0; i < viewerCount; i++)
		{
			int index = (int) i/viewersPerScreen;
			int viewerPosition = i % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:index];
			NSRect frame = [screen visibleFrame];
			
			if( display2DViewerToolbar) frame.size.height -= [[AppController toolbarForScreen:screen] exposedHeight];
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
		
		for( int i = 0; i < viewerCount; i++)
		{
			int monitorIndex = (int) i /columnsPerScreen;
			int viewerPosition = i % columnsPerScreen;
			NSScreen *screen = [screens objectAtIndex: monitorIndex];
			NSRect frame = [screen visibleFrame];
			
			if( display2DViewerToolbar) frame.size.height -= [[AppController toolbarForScreen:screen] exposedHeight];
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
					[viewersList removeObject: [hiddenWindows objectAtIndex: 0]];
					[viewersList insertObject: [hiddenWindows objectAtIndex: 0] atIndex: i];
					
					[hiddenWindows removeObject: [hiddenWindows objectAtIndex: 0]];
				}
			}
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame showWindow:YES animate: YES];
            
            [hiddenWindows removeObject: [viewersList objectAtIndex:i]];
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
			for( int i = 0; i < viewerCount; i++)
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
						[viewersList removeObject: [hiddenWindows objectAtIndex: 0]];
						[viewersList insertObject: [hiddenWindows objectAtIndex: 0] atIndex: i];
						
						[hiddenWindows removeObject: [hiddenWindows objectAtIndex: 0]];
					}
				}
				
				[viewersForThisScreen addObject: [viewersList objectAtIndex:i]];
                
                [hiddenWindows removeObject: [viewersList objectAtIndex:i]];
			}
			
			if( [viewersForThisScreen count])
				[self displayViewers: viewersForThisScreen monitorIndex: monitorIndex screens: screens numberOfMonitors: numberOfMonitors rowsPerScreen: rowsPerScreen columnsPerScreen: columnsPerScreen];
		}
	}
	else
		NSLog(@"NO tiling");
	
    [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat: @"%d%d", lastRows, lastColumns] forKey: @"LastWindowsTilingRowsColumns"];
    
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
	
	if( [viewersList count] > 0 && keyWindow != nil)
	{
        [DCMView setDontListenToSyncMessage: YES];
        
		[[keyWindow window] makeKeyAndOrderFront:self];
		[keyWindow propagateSettings];
		
		NSDisableScreenUpdates();
        
		for( id v in [[viewersList reverseObjectEnumerator] allObjects])
		{
			if( [v isKindOfClass:[ViewerController class]])
			{
                if( v != keyWindow)
                {
                    if( [v checkFrameSize] == YES)
                        [v buildMatrixPreview: YES];
                    
                    [v redrawToolbar]; // To avoid the drag & remove item bug - multiple windows
                }
			}
            
            if( [keyWindow isKindOfClass:[ViewerController class]])
            {
                if( [keyWindow checkFrameSize] == YES)
                    [keyWindow buildMatrixPreview: YES];
                [keyWindow redrawToolbar];
            }
		}
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"])
		{
			for( id v in viewersList)
				[v autoHideMatrix];
		}
		
        ViewerController *v = keyWindow;
        if( [v isKindOfClass: [ViewerController class]])
        {
            [[v imageView] becomeMainWindow];
            [v refreshToolbar];
		}
        
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncPreviewList"])
			[keyWindow syncThumbnails];
        
		NSEnableScreenUpdates();
        
        [DCMView setDontListenToSyncMessage: NO];
	}
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction) closeAllViewers: (id) sender
{
    // Is there a full screen window displayed?
    for( id window in [NSApp orderedWindows])
    {
        if( [window isKindOfClass: [NSFullScreenWindow class]])
        {
            NSBeep();
            return;
        }
    }
    
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
#ifndef MACAPPSTORE
#ifndef OSIRIX_LIGHT
	NSString *templateDirectory = nil;

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
#endif
    
    return nil;
}

+(void)checkForWordTemplates
{
#ifndef MACAPPSTORE
#ifndef OSIRIX_LIGHT
    // previously, we had a single word template in the OsiriX Data folder
    NSString* oldReportFilePath = [documentsDirectory() stringByAppendingPathComponent:@"ReportTemplate.doc"];
    
    // today, we use a dir in the database folder, which contains the templates
    NSString* templatesDirPath = [documentsDirectory() stringByAppendingPathComponent:@"WORD TEMPLATES"];
    
    // by default, the templates are stored in the Office Application Support folder
    NSString* wordTemplatesOsirixDirPath = [Reports wordTemplatesOsirixDirPath];
    [[NSFileManager defaultManager] confirmDirectoryAtPath:wordTemplatesOsirixDirPath];
    
    // TODO: aliases for other Office languages
    
    NSUInteger templatesCount = 0;
    for (NSString* filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:wordTemplatesOsirixDirPath error:NULL]) 
        if ([filename hasPrefix:@"OsiriX "])
            ++templatesCount;
    
    if (!templatesCount && [[NSFileManager defaultManager] fileExistsAtPath:templatesDirPath])
        for (NSString* filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:templatesDirPath error:NULL])
            if ([filename hasPrefix:@"OsiriX "]) {
                [[NSFileManager defaultManager] copyItemAtPath:[templatesDirPath stringByAppendingPathComponent:filename] toPath:[wordTemplatesOsirixDirPath stringByAppendingPathComponent:filename] error:NULL];
                ++templatesCount;
            }
    if (!templatesCount)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:oldReportFilePath])
            [[NSFileManager defaultManager] createSymbolicLinkAtPath:[wordTemplatesOsirixDirPath stringByAppendingPathComponent:@"OsiriX Basic Report Template.doc"] pathContent:oldReportFilePath];
        else
            [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ReportTemplate.doc"] toPath:[templatesDirPath stringByAppendingPathComponent:@"OsiriX Basic Report Template.doc"] error:NULL];
    }
#endif
#endif
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

#pragma mark -

- (NSManagedObjectContext*) defaultWebPortalManagedObjectContext
{
    @try
    {
        #ifndef OSIRIX_LIGHT
        return [[[WebPortal defaultWebPortal] database] managedObjectContext];
        #endif
    }
    @catch (NSException *e) {
        NSLog( @"***** defaultWebPortalManagedObjectContext : %@", e);
    }
    
    static NSManagedObjectContext *fakeContext = nil;
    if( fakeContext == nil)
    {
        fakeContext  = [[NSManagedObjectContext alloc] init];
        NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/WebPortalDB.momd"]]] autorelease];
        NSPersistentStoreCoordinator *psc = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model] autorelease];
        [fakeContext setPersistentStoreCoordinator: psc];
    }
    return fakeContext;
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
                if (setCount.unsignedIntegerValue > 0)
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

-(void)playGrabSound {
    NSString* path = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Grab.aif";
    NSSound* sound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
    sound.delegate = self;
    [sound play];
}

- (void)sound:(NSSound*)sound didFinishPlaying:(BOOL)finishedPlaying {
    [sound release];
}

@end
