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

#if __ppc__
//#import <ILCrashReporter/ILCrashReporter.h>
#endif
#import "ToolbarPanel.h"
#import "AppController.h"
#import "PreferenceController.h"
#import "PreferencePaneController.h"
#import "BrowserController.h"
#import "ViewerController.h"
#import "SplashScreen.h"
#import "NSFont_OpenGL.h"
#import "Survey.h"
#import "PluginManager.h"

#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCM.h>
#import "NetworkListener.h"
#import "DCMTKQueryRetrieveSCP.h"

#import "AppControllerDCMTKCategory.h"

#import "OrthogonalMPRViewer.h"
#import "OrthogonalMPRPETCTViewer.h"

#define BUILTIN_DCMTK YES

static NSString *hostName = @"";

ToolbarPanelController		*toolbarPanel[10] = {0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L};

extern		NSMutableDictionary		*plugins;
extern		BrowserController		*browserWindow;

NSMenu                  *presetsMenu,
						*convMenu,
						*clutMenu,
						*OpacityMenu;

NSThread				*mainThread;
BOOL					NEEDTOREBUILD = NO;
BOOL					USETOOLBARPANEL = NO;
short					Altivec;

AppController			*appController = 0L;

NetworkListener			*storeSCP = 0L;
DCMTKQueryRetrieveSCP   *dcmtkQRSCP;

NSLock					*PapyrusLock = 0L;			// Papyrus is NOT thread-safe


enum	{kSuccess = 0,
        kCouldNotFindRequestedProcess = -1, 
        kInvalidArgumentsError = -2,
        kErrorGettingSizeOfBufferRequired = -3,
        kUnableToAllocateMemoryForBuffer = -4,
        kPIDBufferOverrunError = -5};

#include <sys/sysctl.h>

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
        error = sysctl(mib, 3, NULL, &sizeOfBufferRequired, NULL, NULL);

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
        error = sysctl(mib, 3, BSDProcessInformationStructure, &sizeOfBufferRequired, NULL, NULL);
    
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

#if __ppc__
// ALTIVEC FUNCTIONS

void InverseLongs(register vector unsigned int *unaligned_input, register long size)
{
	register long						i = size / 4;
	register vector unsigned char		identity = vec_lvsl(0, (int*) NULL );
	register vector unsigned char		byteSwapLongs = vec_xor( identity, vec_splat_u8(sizeof( long )- 1 ) );
	
	while(i-- > 0)
	{
		*unaligned_input++ = vec_perm( *unaligned_input, *unaligned_input, byteSwapLongs);
	}
}

void InverseShorts( register vector unsigned short *unaligned_input, register long size)
{
	register long						i = size / 8;
	register vector unsigned char		identity = vec_lvsl(0, (int*) NULL );
	register vector unsigned char		byteSwapShorts = vec_xor( identity, vec_splat_u8(sizeof( short) - 1) );
	
	while(i-- > 0)
	{
		*unaligned_input++ = vec_perm( *unaligned_input, *unaligned_input, byteSwapShorts);
	}
}

void vmultiply(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	register vector float zero = (vector float) vec_splat_u32(0);
	
	while(i-- > 0)
	{
		*r++ = vec_madd( *a++, *b++, zero);
	}
}

void vsubtract(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_sub( *a++, *b++);
	}
}

void vmax8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_max( *a++, *b++);
	}
}

void vmax(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_max( *a++, *b++);
	}
}

void vmin(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_min( *a++, *b++);
	}
}

void vmin8(vector float *a, vector float *b, vector float *r, long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_min( *a++, *b++);
	}
}
#endif

void vmultiplyNoAltivec( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		*r++ = *a++ * *b++;
	}
}

void vsubtractNoAltivec( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		*r++ = *a++ - *b++;
	}
}


void vmaxNoAltivec(float *a, float *b, float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		if( *a > *b) { *r++ = *a++; b++; }
		else { *r++ = *b++; a++; }
	}
}

void vminNoAltivec( float *a,  float *b,  float *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		if( *a < *b) { *r++ = *a++; b++; }
		else { *r++ = *b++; a++; }
	}
}

NSString * documentsDirectory()
{
	char	s[1024];
	FSSpec	spec;
	FSRef	ref;
	short	vRefNum;
	long	dirID;
	
	switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"DATABASELOCATION"])
	{
		case 0:
			if ( FindFolder( kOnAppropriateDisk, kDocumentsFolderType, true, &vRefNum, &dirID ) == noErr )
			{
				FSMakeFSSpec( vRefNum, dirID, (ConstStr255Param)"", &spec );
				if ( FSpMakeFSRef(&spec, &ref) == noErr )
				{
					NSString	*path;
					BOOL		isDir = YES;
					FSRefMakePath(&ref, (UInt8 *)s, sizeof(s));
					
					path = [[NSString stringWithUTF8String:s] stringByAppendingString:@"/OsiriX Data"];
					if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
					
					return path;// not sure if s is in UTF8 encoding:  What's opposite of -[NSString fileSystemRepresentation]?
				}
			}
			break;
			
		case 1:
		{
			NSString	*path;
			BOOL		isDir = YES;
			
			path=[[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"] stringByAppendingString:@"/OsiriX Data"];
			if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])	// STILL NOT AVAILABLE??
			{   // Use the default folder.. and reset this strange URL..
				
				[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
				
				return documentsDirectory();
			}
			
			return path;
		}
			break;
	}
	
	return nil;
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
	NSString		*tempString, *outputfile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/%@", filenameWithDate( inputfile)];
    NSMutableArray  *theArguments = [NSMutableArray array];
	long			i = 0;
	
	while( converting)
	{
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
	}
	
	NSLog(inputfile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:outputfile])
	{
		//[[NSFileManager defaultManager] removeFileAtPath:outputfile handler: 0L];
		//NSLog(@"Already converted...");
		return outputfile;
	}
	
	converting = YES;
	NSLog(@"IN");
	NSTask *convertTask = [[NSTask alloc] init];
    
//    [convertTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
//    [convertTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dcmdjpeg"]];

	[convertTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle bundleForClass:[AppController class]] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[convertTask setLaunchPath:[[[NSBundle bundleForClass:[AppController class]] resourcePath] stringByAppendingString:@"/dcmdjpeg"]]; 
	
    [theArguments addObject:inputfile];
    [theArguments addObject:outputfile];
	
    [convertTask setArguments:theArguments];
    
	NS_DURING
		// launch traceroute
		[convertTask launch];
		//[convertTask waitUntilExit];
		
		while( [convertTask isRunning] == YES)
		{
			//	NSLog(@"CONVERSION WORK");
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
		}
		
		[convertTask interrupt];
		[convertTask release];
		
		NSLog(@"OUT");
		
		converting = NO;
		
	NS_HANDLER
		NSLog( [localException name]);
		converting = NO;
	NS_ENDHANDLER
	
	return outputfile ;
}


int dictSort(id num1, id num2, void *context)
{
    return [[num1 objectForKey:@"AETitle"] caseInsensitiveCompare: [num2 objectForKey:@"AETitle"]];
}

#define kHasAltiVecMask    ( 1 << gestaltPowerPCHasVectorInstructions )  // used in  looking for a g4 

short HasAltiVec ( )
{
	Boolean hasAltiVec = 0;
	OSErr      err;       
	long      ppcFeatures;
	
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

BOOL hasMacOSXVersion()
{
	OSErr		err;
	long      osVersion;
	
	err = Gestalt ( gestaltSystemVersion, &osVersion );       
	if ( err == noErr)       
	{             
		if ( osVersion < 0x1030 )
		{
			return NO;
		}
	}       
	return YES;                   
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

BOOL hasMacOSXTiger()
{
	OSErr						err;       
	long						osVersion;
	
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

-(IBAction)sendEmail:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:rossetantoine@bluewin.ch"]]; 
}

-(IBAction)openOsirixWebPage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/"]];
}

-(IBAction)help:(id)sender{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"QuickManual" ofType:@"pdf"]];
}


-(IBAction)openOsirixWikiWebPage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://en.wikibooks.org/wiki/Online_Osirix_Documentation"]];
}

-(IBAction)openOsirixDiscussion:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://groups.yahoo.com/group/osirix/"]];
}


- (IBAction) openOsirixBugReporter: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://sourceforge.net/tracker/?func=add&group_id=107249&atid=647131"]];
}


- (IBAction) openOsirixFeatureRequest: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://sourceforge.net/tracker/?func=add&group_id=107249&atid=647134"]];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

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
	
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Default WL & WW", 0L) action:@selector (ApplyWLWW:) keyEquivalent:@""]; 
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Full dynamic", 0L) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Other", 0L) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[presetsMenu addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [presetsMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    [presetsMenu addItem: [NSMenuItem separatorItem]];
    [presetsMenu addItemWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	[presetsMenu addItemWithTitle:NSLocalizedString(@"Set WL/WW manually", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	
	[[presetsMenu itemWithTitle:[note object]] setState:NSOnState];
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
	
	[[convMenu itemWithTitle:[note object]] setState:NSOnState];
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
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"USESTORESCP"];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"])
	{
		// Kill DCMTK listener
		//built in dcmtk serve testing
		if (BUILTIN_DCMTK == YES)
		{
			[dcmtkQRSCP abort];
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
		
		// Kill OsiriX framework listener
		if( storeSCP)
		{
			NSLog(@"********* WARNING - WE SHOULD NOT BE HERE - STORE-SCP");
			
			[storeSCP stop];
			[storeSCP release];
			storeSCP = 0L;
		}
		
		//make sure that there exist a receiver folder at @"folder" path
		NSString            *path = [documentsDirectory() stringByAppendingString:INCOMINGPATH];
		BOOL				isDir = YES;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) 
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		
		// @"USESTORESCP" is true when DCMTK is chosen
		// In this case it's necesary to start a new thread
		// In case of using DCM framework, the code follows right after "else" statement
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"USESTORESCP"])
		{
			[NSThread detachNewThreadSelector: @selector(startSTORESCP:) toTarget: self withObject: self];
		}
		else
		{
			NSLog(@"********* WARNING - WE SHOULD NOT BE HERE - STORE-SCP");
			
			//DCM framework storescp
			//NSAutoreleasePool allows retaining storeSCP NetworkListener object, having it persist after the [pool release]
			
			NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
			
			int debugLevel = 0;
			NSMutableDictionary *params = [NSMutableDictionary dictionary];
			[params setObject: [NSNumber numberWithInt:debugLevel] forKey: @"debugLevel"];
			[params setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] forKey: @"calledAET"];
			[params setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]  forKey: @"port"];
			[params setObject: path  forKey: @"folder"];
			storeSCP = [[NetworkListener listenWithParameters:params] retain];

			[pool release];
		}
	}

	NS_HANDLER
		NSLog(@"Exception restarting storeSCP");
	NS_ENDHANDLER
}

-(void) displayListenerError: (NSString*) err
{
	NSRunCriticalAlertPanel(@"DICOM Listener Error", err, @"OK", nil, nil);
}

-(void) startSTORESCP:(id) sender
{
	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method
	// this implies it needs it's own pool of objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	if (BUILTIN_DCMTK) {
	//Testing built in dcmtk server don't remove- LP
		NSLog(@"dcmtk:");
		NSString *aeTitle = [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"];
		int port = [[[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"] intValue];
		NSDictionary *params = nil;
		dcmtkQRSCP = [[DCMTKQueryRetrieveSCP alloc] initWithPort:port  aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params];
		[dcmtkQRSCP run];
		return;
	}
	
	// this method is always executed as a new thread detached from the NSthread command of RestartSTORESCP method
	// this implies it needs it's own pool of objects

	
	quitting = NO;
	
	// create the subprocess
	theTask = [[NSTask alloc] init];
	
	// set DICOMDICTPATH in the environment of execution and choose storescp command
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/storescp"]];
	
	// initialize arguments for CLI
	NSMutableArray *theArguments = [NSMutableArray array];
	[theArguments addObject: @"-aet"];
	[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]];
	[theArguments addObject: @"-od"];
	[theArguments addObject: [documentsDirectory() stringByAppendingString:INCOMINGPATH]];
	[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETransferSyntax"]];
	[theArguments addObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"]];
	[theArguments addObject: @"--fork"];

	if( [[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] != 0L &&
		[[[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] isEqualToString:@""] == NO ) {
		
		NSLog([[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"]);
		[theArguments addObjectsFromArray:[[[NSUserDefaults standardUserDefaults] stringForKey: @"STORESCPEXTRA"] componentsSeparatedByString:@" "]];
	}
		
	[theTask setArguments: theArguments];

	
	// open a pipe for traceroute to send its output to
	NSPipe *thePipe = [NSPipe pipe];
	[theTask setStandardOutput:thePipe];
	
	// open another pipe for the errors
	NSPipe *errorPipe = [NSPipe pipe];
	[theTask setStandardError:errorPipe];
	
	//-------------------------------launches dcmtk----------------------
	[theTask launch];
	[theTask waitUntilExit];
	//-------------------------------------------------------------------
	
	//    int status = [theTask terminationStatus];	
	NSData  *errData = [[errorPipe fileHandleForReading] availableData];
	NSData  *resData = [[thePipe fileHandleForReading] availableData];	
	NSString    *errString = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];
	NSString    *resString = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
	
	if( quitting == NO)
		{
		NSLog(@"Task failed.");
		if( [errString isEqualToString:@""] == NO)
			{
				[self performSelectorOnMainThread:@selector(displayListenerError:) withObject:errString waitUntilDone: YES];
			}
		}
	
	[errString release];
	[resString release];
	[pool release];
	
}



- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	long				i;
	NSMutableArray		*filesArray = [[NSMutableArray alloc] initWithCapacity:0];
	NSFileManager       *defaultManager = [NSFileManager defaultManager];
	BOOL                isDirectory;
	
	for( i = 0; i < [filenames count]; i++)
	{
		if([defaultManager fileExistsAtPath:[filenames objectAtIndex:i] isDirectory:&isDirectory])     // A directory
		{
			if( isDirectory == YES)
			{
				NSString    *pathname;
				NSString    *aPath = [filenames objectAtIndex:i];
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
			else    // A file
			{
				[filesArray addObject:[filenames objectAtIndex:i]];
			}
		}
	}
	
	if( browserWindow != 0L)
	{
		filesArray = [browserWindow copyFilesIntoDatabaseIfNeeded:filesArray];
		
		NSArray	*newImages = [browserWindow addFilesToDatabase:filesArray];
		[browserWindow outlineViewRefresh];
		
		if( [newImages count] > 0)
		{
			NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
				
			[[browserWindow databaseOutline] selectRow: [[browserWindow databaseOutline] rowForItem: object] byExtendingSelection: NO];
			[[browserWindow databaseOutline] scrollRowToVisible: [[browserWindow databaseOutline] selectedRow]];
		}
	}
	
	[filesArray release];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if( [[browserWindow window] isMiniaturized] == YES || [[browserWindow window] isVisible] == NO)
	{
		NSArray				*winList = [NSApp windows];
		long				i;
		
		for( i = 0; i < [winList count]; i++)
		{
			if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) return;
		}
		
		[[browserWindow window] makeKeyAndOrderFront: self];
	}
}

- (void) applicationWillTerminate: (NSNotification*) aNotification
{
    quitting = YES;
    [theTask interrupt];
	[theTask release];
	
	if (BUILTIN_DCMTK == YES)
	{
		[dcmtkQRSCP abort];
		[dcmtkQRSCP release];
		dcmtkQRSCP = nil;
	}
	
	[self destroyDCMTK];
	
	[AppController cleanOsiriXSubProcesses];
}


- (void) terminate :(id) sender
{
	NSArray				*winList = [NSApp windows];
	long				i;
	
	for( i = 0; i < [winList count]; i++)
	{
		[[winList objectAtIndex:i] orderOut:sender];
	}
	
	[NSApp terminate: sender];
	
	// DELETE THE TEMP DIRECTORY...
	NSString *tempDirectory = [documentsDirectory() stringByAppendingString:@"/TEMP/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
	
	// DELETE THE DUMP DIRECTORY...
	NSString *dumpDirectory = [documentsDirectory() stringByAppendingString:@"/DUMP/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory]) [[NSFileManager defaultManager] removeFileAtPath:dumpDirectory handler: 0L];
}

- (id)init {
	self = [super init];
	//	pluginClasses = [[NSMutableArray alloc] init];
	//	pluginInstances = [[NSMutableArray alloc] init];
	//currentHangingProtocol = [[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:6], [NSNumber numberWithInt:6], nil] forKeys: [NSArray arrayWithObjects: @"Rows", @"Columns", nil]] retain];
	currentHangingProtocol = nil;
	appController = self;
	
	PapyrusLock = [[NSLock alloc] init];
	
	return self;
}

+ (id)sharedAppController {
	return appController;
}

+ (void) addCLUT: (NSString*) filename dictionary: (NSMutableDictionary*) clutValues
{
	if( [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"])
		[clutValues setObject:[NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"]] forKey: filename];
	else
	{
		NSLog(@"CLUT plist not found: %@", filename);
	}
}

+ (void) addConvolutionFilter: (short) size :(short*) vals :(NSString*) name :(NSMutableDictionary*) convValues
{
	long				i;
	NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
	NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];

	[aConvFilter setObject:[NSNumber numberWithLong:size] forKey:@"Size"];
	
	long norm = 0;
	for( i = 0; i < size*size; i++) norm += vals[i];
	[aConvFilter setObject:[NSNumber numberWithLong:norm] forKey:@"Normalization"];
	
	for( i = 0; i < size*size; i++) [valArray addObject:[NSNumber numberWithLong:vals[i]]];
	[aConvFilter setObject:valArray forKey:@"Matrix"];
	
	[convValues setObject:aConvFilter forKey:name];
}


+ (long) vramSize
{
	int					i = 0;
	short				MAXDISPLAYS = 8;
	io_service_t		dspPorts[MAXDISPLAYS];
	CGDirectDisplayID   displays[MAXDISPLAYS];
	CFTypeRef			typeCode;
	CGDisplayCount		displayCount = 0;
	
	// First we're going to grab the online displays
	CGGetOnlineDisplayList(MAXDISPLAYS, displays, &displayCount);
	
	// Now we iterate through them
	for(i = 0; i < displayCount; i++)
		dspPorts[i] = CGDisplayIOServicePort(displays[i]);

	// Ask for the physical size of VRAM of the primary display
	typeCode = IORegistryEntryCreateCFProperty(dspPorts[0], CFSTR("IOFBMemorySize"), kCFAllocatorDefault, kNilOptions);
	
	// Validate our data and make sure we're getting the right type
	if(typeCode && CFGetTypeID(typeCode) == CFNumberGetTypeID())
	{
		long vramStorage = 0;
		// Convert this to a useable number
		CFNumberGetValue(typeCode, kCFNumberSInt32Type, &vramStorage);
		// If we get something other than 0, we'll use it
		if(vramStorage > 0)
			return vramStorage;
	}
	
	return 0;
}

static BOOL initialized = NO;

 + (void) initialize
{
	@try
	{
	if ( self == [AppController class] && initialized == NO)
	{
		[AppController cleanOsiriXSubProcesses];
		
		initialized = YES;
		
		long	i;
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		srandom(time(NULL));
		
	//	[[ILCrashReporter defaultReporter] launchReporterForCompany:@"OsiriX Developers" reportAddr:@"rossetantoine@mac.com"];
		
		mainThread  = [NSThread currentThread];
					
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
	//		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/"]];
	//		exit(0);
	//	}
			
		//	switch( NSRunInformationalAlertPanel(@"OsiriX", @"Thank you for using OsiriX!\rWe need your help! Send us comments, bugs and ideas!\r\rI need supporting emails to prove utility of OsiriX!\r\rThanks!", @"Continue", @"Send an email", @"Web Site"))
		//	{
		//		case 0:
		//			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:rossetantoine@bluewin.ch?subject=OsiriX&cc=lpysher@mac.com,luca.spadola@mac.com,Osman.Ratib@sim.hcuge.ch"]];
		//		break;
		//		
		//		case -1:
		//			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/"]];
		//		break;
		//	}
		
		[[PluginManager alloc] init];
		
		// ** WLWW PRESETS
		float iww, iwl;
		
		NSMutableDictionary *wlwwValues = [NSMutableDictionary dictionary];
		
		iww = 842;          iwl = -595;
		[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Pulmonary"];
		
		iww = 1500;          iwl = 300;
		[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Bone"];
		
		iww = 100;          iwl = 50;
		[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Brain"];
		
		iww = 350;          iwl = 40;
		[wlwwValues setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:@"CT - Abdomen"];
		
		[defaultValues setObject:wlwwValues forKey:@"WLWW3"];
		
		// ** CONVOLUTION PRESETS
		
		NSMutableDictionary *convValues = [NSMutableDictionary dictionary];
		
		// --
		{
			NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
			NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];
			short				vals[9] = {-1, -1, -1, -1, 9, -1, -1, -1, -1};
			
			[aConvFilter setObject:[NSNumber numberWithLong:3] forKey:@"Size"];
			[aConvFilter setObject:[NSNumber numberWithLong:1] forKey:@"Normalization"];
			for( i = 0; i < 9; i++) [valArray addObject: [NSNumber numberWithLong:vals[i]]];
			[aConvFilter setObject:valArray forKey:@"Matrix"];
			[convValues setObject:aConvFilter forKey:@"Bone Filter 3x3"];
		}
		// --
		// --
		{
			NSMutableDictionary *aConvFilter = [NSMutableDictionary dictionary];
			NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];
			short				vals[25] = {	1, 1, 1, 1, 1,
				1, 4, 4, 4, 1,
				1, 4, 12, 4, 1,
				1, 4, 4, 4, 1,
				1, 1, 1, 1, 1};
			
			[aConvFilter setObject:[NSNumber numberWithLong:5] forKey:@"Size"];
			[aConvFilter setObject:[NSNumber numberWithLong:60] forKey:@"Normalization"];
			for( i = 0; i < 25; i++) [valArray addObject:[NSNumber numberWithLong:vals[i]]];
			[aConvFilter setObject:valArray forKey:@"Matrix"];
			[convValues setObject:aConvFilter forKey:@"Basic Smooth 5x5"];
		}
		{
			short				vals[9] = {1, 2, 1, 2, 4, 2, 1, 2, 1};
			[AppController addConvolutionFilter:3 :vals :@"Blur 3x3" :convValues];
		}
		{
			short				vals[25] = {1, 1, 2, 1, 1, 1, 2, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 2, 1, 1, 1, 2, 1, 1};
			[AppController addConvolutionFilter:5 :vals :@"Blur 5x5" :convValues];
		}
		{
			short				vals[25] = {3, 3, 2, 3, 3, 3, 2, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 2, 3, 3, 3, 2, 3, 3};
			[AppController addConvolutionFilter:5 :vals :@"Inverted blur" :convValues];
		}
		{
			short				vals[25] = {0, 0, -1, 0, 0, 0, -1, -2, -1, 0, -1, -2, -3, -2, -1, 0, -1, -2, -1, 0, 0, 0, -1, 0, 0};
			[AppController addConvolutionFilter:5 :vals :@"Negative blur" :convValues];
		}
		{
			short				vals[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};
			[AppController addConvolutionFilter:3 :vals :@"Edge north" :convValues];
		}
		{
			short				vals[9] = {1, 0, -1, 2, 0, -2, 1, 0, -1};
			[AppController addConvolutionFilter:3 :vals :@"Edge west" :convValues];
		}
		{
			short				vals[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};
			[AppController addConvolutionFilter:3 :vals :@"Edge diagonal" :convValues];
		}
		{
			short				vals[9] = {0, 1, 0, -1, 0, 1, 0, -1, 0};
			[AppController addConvolutionFilter:3 :vals :@"Edge north" :convValues];
		}
		{
			short				vals[9] = {-1, -1, -1, -1, 8, -1, -1, -1, -1};
			[AppController addConvolutionFilter:3 :vals :@"Laplacian 8" :convValues];
		}
		{
			short				vals[9] = {-1, 0, -1, 0, 7, 0, -1, 0, -1};
			[AppController addConvolutionFilter:3 :vals :@"Laplacian 7" :convValues];
		}
		{
			short				vals[9] = {-1, 0, 0, 0, 0, 0, 0, 0, 1};
			[AppController addConvolutionFilter:3 :vals :@"Emboss" :convValues];
		}
		{
			short				vals[9] = {-1, -1, 0, -1, 0, 1, 0, 1, 1};
			[AppController addConvolutionFilter:3 :vals :@"Emboss heavy" :convValues];
		}
		{
			short				vals[9] = {1, 1, 1, 1, 1, 1, 1, 1, 1};
			[AppController addConvolutionFilter:3 :vals :@"Lowpass" :convValues];
		}
		{
			short				vals[9] = {1, -2, 1, -2, 4, -2, 1, -2, 1};
			[AppController addConvolutionFilter:3 :vals :@"Highpass" :convValues];
		}
		{
			short				vals[25] = {1, 1, 2, 1, 1, 1, 2, 4, 2, 1, 2, 4, 8, 4, 2, 1, 2, 4, 2, 1, 1, 1, 2, 1, 1};
			[AppController addConvolutionFilter:5 :vals :@"Gaussian blur" :convValues];
		}
		{
			short				vals[25] = {0,  0, -1,  0,  0, 0, -1, -2, -1,  0, -1, -2, 16, -2, -1, 0, -1, -2, -1,  0, 0,   0,  -1,   0,   0};
			[AppController addConvolutionFilter:5 :vals :@"Hat" :convValues];
		}
		{
			short				vals[25] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 24, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
			[AppController addConvolutionFilter:5 :vals :@"Laplacian" :convValues];
		}
		{
			short				vals[25] = {0, -1, -1, -1, 0, -1, 2, -4, 2, -1, -1, -4, 13, -4, -1, -1, 2, -4, 2, -1, 0, -1, -1, -1, 0};
			[AppController addConvolutionFilter:5 :vals :@"highpass" :convValues];
		}
		{
			short				vals[9] = {-1, -1, -1, -1, 9, -1, -1, -1, -1};
			[AppController addConvolutionFilter:3 :vals :@"Sharpen" :convValues];
		}
		{
			short				vals[9] = {1, 1, 1, 1, -7, 1, 1, 1, 1};
			[AppController addConvolutionFilter:3 :vals :@"Excessive edges" :convValues];
		}
		{
			short				vals[25] = {-1, -1, -1, -1, -1, -1, 2, 2, 2, -1, -1, 2, 8, 2, -1, -1, 2, 2, 2, -1, -1, -1, -1, -1, -1};
			[AppController addConvolutionFilter:5 :vals :@"5x5 sharpen" :convValues];
		}

		// --
		
		[defaultValues setObject:convValues forKey:@"Convolution"];
		
		// ** OPACITY TABLES
		NSMutableDictionary *opacityValues = [NSMutableDictionary dictionary];
		
		NSMutableDictionary *aOpacityFilter = [NSMutableDictionary dictionary];
		NSMutableArray *points = [NSMutableArray arrayWithCapacity:0];
		
		for( i = 0; i < 256; i++)
		{
			NSPoint pt;
			//math.h
			pt.x = 1000+i;
			pt.y = log10( 1. + (i/255.)*9.);
			
			[points addObject: NSStringFromPoint( pt)];
		}
		
		[aOpacityFilter setObject:points forKey:@"Points"];
		[opacityValues setObject:aOpacityFilter forKey:@"Logarithmic Table"];
		
		// Log Inverse
		
		aOpacityFilter = [NSMutableDictionary dictionary];
		points = [NSMutableArray arrayWithCapacity:0];
		
		for( i = 0; i < 256; i++)
		{
			NSPoint pt;
			//math.h
			pt.x = 1000+i;
			pt.y = 1. - log10( 1. + ((255-i)/255.)*9.);
			
			[points addObject: NSStringFromPoint( pt)];
		}
		
		[aOpacityFilter setObject:points forKey:@"Points"];
		[opacityValues setObject:aOpacityFilter forKey:@"Logarithmic Inverse Table"];
		
		// Smooth CT
		
		aOpacityFilter = [NSMutableDictionary dictionary];
		points = [NSMutableArray arrayWithCapacity:0];
		
		{
			NSPoint pt;
			pt.x = 1000+180;
			pt.y = 0.05;
			
			[points addObject: NSStringFromPoint( pt)];
		}
		
		[aOpacityFilter setObject:points forKey:@"Points"];
		[opacityValues setObject:aOpacityFilter forKey:@"Smooth Table"];
		
		[defaultValues setObject:opacityValues forKey:@"OPACITY"];
		
		// ** CLUT PRESETS
		NSMutableDictionary *clutValues = [NSMutableDictionary dictionary];
		
		// --
		{
			//    NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
			//	NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
			//	for( i = 0; i < 256; i++)
			//	{
			//		[rArray addObject: [NSNumber numberWithLong:i]];
			//	}
			//	[aCLUTFilter setObject:rArray forKey:@"Red"];
			//	
			//	NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
			//	for( i = 0; i < 256; i++)
			//	{
			//		[gArray addObject: [NSNumber numberWithLong:0]];
			//	}
			//	[aCLUTFilter setObject:gArray forKey:@"Green"];
			//	
			//	NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
			//	for( i = 0; i < 256; i++)
			//	{
			//		[bArray addObject: [NSNumber numberWithLong:0]];
			//	}
			//	[aCLUTFilter setObject:bArray forKey:@"Blue"];
			//	
			//	[clutValues setObject:aCLUTFilter forKey:@"Red CLUT"];
		}
		
		// --
		{
			NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
			NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
			for( i = 0; i < 128; i++) [rArray addObject: [NSNumber numberWithLong:i*2]];
			for( i = 128; i < 256; i++) [rArray addObject: [NSNumber numberWithLong:255]];
			[aCLUTFilter setObject:rArray forKey:@"Red"];
			
			NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
			for( i = 0; i < 128; i++) [gArray addObject: [NSNumber numberWithLong:0]];
			for( i = 128; i < 192; i++) [gArray addObject: [NSNumber numberWithLong: (i-128)*4]];
			for( i = 192; i < 256; i++) [gArray addObject: [NSNumber numberWithLong: 255]];
			[aCLUTFilter setObject:gArray forKey:@"Green"];
			
			NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
			for( i = 0; i < 192; i++) [bArray addObject: [NSNumber numberWithLong:0]];
			for( i = 192; i < 256; i++) [bArray addObject: [NSNumber numberWithLong:(i-192)*4]];
			[aCLUTFilter setObject:bArray forKey:@"Blue"];
			
			// Points & Colors
			NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
			
			[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];
			[points addObject:[NSNumber numberWithLong: 0]];
			
			[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];
			[points addObject:[NSNumber numberWithLong: 128]];
			
			[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], 0L]];
			[points addObject:[NSNumber numberWithLong: 192]];
			
			[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], 0L]];
			[points addObject:[NSNumber numberWithLong: 256]];
			
			[aCLUTFilter setObject:colors forKey:@"Colors"];
			[aCLUTFilter setObject:points forKey:@"Points"];
			
			[clutValues setObject:aCLUTFilter forKey:@"PET"];
		}
		
		// --
		{
			NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
			NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
			for( i = 0; i < 256; i++) [rArray addObject: [NSNumber numberWithLong:255-i]];
			[aCLUTFilter setObject:rArray forKey:@"Red"];
			
			NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
			for( i = 0; i < 256; i++) [gArray addObject: [NSNumber numberWithLong:255-i]];
			[aCLUTFilter setObject:gArray forKey:@"Green"];
			
			NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
			for( i = 0; i < 256; i++) [bArray addObject: [NSNumber numberWithLong:255-i]];
			[aCLUTFilter setObject:bArray forKey:@"Blue"];
			
			// Points & Colors
			NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
			
			[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 1], 0L]];
			[points addObject:[NSNumber numberWithLong: 0]];
			
			[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], 0L]];
			[points addObject:[NSNumber numberWithLong: 256]];
			
			[aCLUTFilter setObject:colors forKey:@"Colors"];
			[aCLUTFilter setObject:points forKey:@"Points"];
			
			[clutValues setObject:aCLUTFilter forKey:@"B/W Inverse"];
		}
		
		[AppController addCLUT: @"VR Muscles-Bones"  dictionary: clutValues];
		[AppController addCLUT: @"VR Bones"  dictionary: clutValues];
		[AppController addCLUT: @"VR Red Vessels"  dictionary: clutValues];
		[AppController addCLUT: @"BlackBody"  dictionary: clutValues];	
		[AppController addCLUT: @"Flow"  dictionary: clutValues];		
		[AppController addCLUT: @"GEcolor"  dictionary: clutValues];	
		[AppController addCLUT: @"Spectrum"  dictionary: clutValues];	
		[AppController addCLUT: @"NIH"  dictionary: clutValues];	
		[AppController addCLUT: @"HotIron"  dictionary: clutValues];	
		[AppController addCLUT: @"GrayRainbow"  dictionary: clutValues];	
	
		[AppController addCLUT: @"UCLA"  dictionary: clutValues];			
		[AppController addCLUT: @"Stern"  dictionary: clutValues];		
		[AppController addCLUT: @"Ratio"  dictionary: clutValues];		
		[AppController addCLUT: @"Rainbow3"  dictionary: clutValues];		
		[AppController addCLUT: @"Rainbow2"  dictionary: clutValues];		
		[AppController addCLUT: @"Rainbow"  dictionary: clutValues];	
		[AppController addCLUT: @"ired"  dictionary: clutValues];		
		[AppController addCLUT: @"Hue1"  dictionary: clutValues];		
		[AppController addCLUT: @"Hue2"  dictionary: clutValues];		
		[AppController addCLUT: @"HotMetal"  dictionary: clutValues];	
		[AppController addCLUT: @"HotGreen"  dictionary: clutValues];	

		[defaultValues setObject:clutValues forKey:@"CLUT"];
		
		// ** PREFERENCES - SERVERS
		
		NSMutableArray *serversValues = [NSMutableArray arrayWithCapacity:0];
		
		NSMutableDictionary *aServer = [[NSMutableDictionary alloc] init];
		[aServer setObject:@"127.0.0.1" forKey: @"Address"];
		[aServer setObject:@"OsiriX" forKey: @"AETitle"];
		[aServer setObject:@"4444" forKey: @"Port"];
		[aServer setObject:NSLocalizedString(@"This is an example", nil) forKey:@"Description"];
		
		[serversValues addObject:aServer];
		[aServer release];
		
		[defaultValues setObject:serversValues forKey:@"SERVERS"];
		
		serversValues = [NSMutableArray arrayWithCapacity:0];
		[defaultValues setObject:serversValues forKey:@"OSIRIXSERVERS"];
		
		//routing calendars
		[defaultValues setObject:[NSMutableArray arrayWithObject:@"Osirix"] forKey:@"ROUTING CALENDARS"];
		
		// ** AETITLE
		NSString *userName = [NSUserName() uppercaseString];
		if ([userName length] > 4)
			userName = [userName substringToIndex:4];
		NSString *computerName = [[[NSHost currentHost] name] uppercaseString];
		if ([computerName length] > 4)
			computerName = [computerName substringToIndex:4];
		NSString *suggestedAE = [NSString stringWithFormat:@"OSIRIX_%@_%@", computerName, userName];
		[defaultValues setObject: suggestedAE forKey: @"AETITLE"];
		//[defaultValues setObject:@"OSIRIX" forKey:@"AETITLE"];

		[defaultValues setObject:@"1.0" forKey:@"points3DcolorRed"];
		[defaultValues setObject:@"0" forKey:@"points3DcolorGreen"];
		[defaultValues setObject:@"0" forKey:@"points3DcolorBlue"];
		[defaultValues setObject:@"1.0" forKey:@"points3DcolorAlpha"];
	
		// *************
		// AUTO-CLEANING
		// *************
		
		[defaultValues setObject:@"NO" forKey:@"AUTOCLEANINGDATE"];
		[defaultValues setObject:@"NO" forKey:@"AUTOCLEANINGDATEPRODUCED"];
		[defaultValues setObject:@"NO" forKey:@"AUTOCLEANINGDATEOPENED"];
		
		[defaultValues setObject:@"90" forKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"];
		[defaultValues setObject:@"90" forKey:@"AUTOCLEANINGDATEOPENEDDAYS"];
		
		[defaultValues setObject:@"2" forKey:@"DEFAULTRIGHTTOOL"];	//ZOOM TOOL
		
		[defaultValues setObject:@"YES" forKey:@"AUTOCLEANINGSPACE"];
		[defaultValues setObject:@"YES" forKey:@"AUTOCLEANINGSPACEPRODUCED"];
		[defaultValues setObject:@"YES" forKey:@"AUTOCLEANINGSPACEOPENED"];
		
		[defaultValues setObject:@"100" forKey:@"AUTOCLEANINGSPACESIZE"];
		
		[defaultValues setObject:@"B/W Inverse" forKey:@"PET Clut Mode"];
		[defaultValues setObject:@"PET" forKey: @"PET Default CLUT"];
		[defaultValues setObject:@"PET" forKey: @"PET Blending CLUT"];
		
		// ** PORT
		[defaultValues setObject:@"4096" forKey:@"AEPORT"];
		
		// ** SYNTAX
		[defaultValues setObject:@"+xi" forKey:@"AETransferSyntax"];
		
		// ** STORESCPEXTRA
		[defaultValues setObject:@"" forKey:@"STORESCPEXTRA"];
		
		// ** ROITEXTIFSELECTED
//		[defaultValues setObject:@"NO" forKey:@"ROITEXTIFSELECTED"];
		
		// ** STORESCP
		[defaultValues setObject:@"YES" forKey: @"STORESCP"];
		
		// ** USEALWAYSTOOLBARPANEL
		[defaultValues setObject:@"NO" forKey: @"USEALWAYSTOOLBARPANEL"];
		
		// ** HIDEPATIENTNAME
		[defaultValues setObject:@"NO" forKey:@"HIDEPATIENTNAME"];
		
		// ** DELETEFILELISTENER
		[defaultValues setObject:@"YES" forKey:@"DELETEFILELISTENER"];
//		
		long	pVRAM;
//		
		pVRAM = [AppController vramSize]  / (1024L * 1024L);
		NSLog(@"VRAM: %d MB", pVRAM);
		
		// ** MAX3DTEXTURE
		// ** MAX3DTEXTURESHADING
		if( pVRAM >= 512)
		{	
			[defaultValues setObject:@"256" forKey:@"MAX3DTEXTURE"];
			[defaultValues setObject:@"128" forKey:@"MAX3DTEXTURESHADING"];
		}
		else if( pVRAM >= 256)
		{
			[defaultValues setObject:@"128" forKey:@"MAX3DTEXTURE"];
			[defaultValues setObject:@"64" forKey:@"MAX3DTEXTURESHADING"];
		}
		else if( pVRAM >= 128)
		{
			[defaultValues setObject:@"128" forKey:@"MAX3DTEXTURE"];
			[defaultValues setObject:@"32" forKey:@"MAX3DTEXTURESHADING"];
		}
		else
		{
			[defaultValues setObject:@"32" forKey:@"MAX3DTEXTURE"];
			[defaultValues setObject:@"32" forKey:@"MAX3DTEXTURESHADING"];
		}
				
		// ** BESTRENDERING
		[defaultValues setObject:@"1.6" forKey:@"BESTRENDERING"];

		// ** OPENVIEWER
		[defaultValues setObject:@"YES" forKey:@"OPENVIEWER"];
		
		// ** ANONYMIZELISTENER
		[defaultValues setObject:@"NO" forKey:@"ANONYMIZELISTENER"];
		
		// ** ConvertPETtoSUVautomatically
		[defaultValues setObject: @"YES" forKey: @"ConvertPETtoSUVautomatically"];
		
		// ** SURVEYDONE
		[defaultValues setObject: @"NO" forKey: @"SURVEYDONE3"];
		
		// ** ROUTINGACTIVATED
		[defaultValues setObject:@"NO" forKey:@"ROUTINGACTIVATED"];
		
		// ** AUTOHIDEMATRIX
		[defaultValues setObject: @"NO" forKey: @"AUTOHIDEMATRIX"];

		// ** AutoPlay
		[defaultValues setObject: @"YES" forKey: @"AutoPlayAnimation"];
		
		// ** USEPAPYRUSDCMPIX
		[defaultValues setObject: @"YES" forKey: @"USEPAPYRUSDCMPIX"];
		
		// ** USEPAPYRUSDCMFILE
		[defaultValues setObject: @"YES" forKey: @"USEPAPYRUSDCMFILE"];
		
		// ** DCMTKJPEG
		[defaultValues setObject: @"NO" forKey: @"DCMTKJPEG"];
		
		// ** CHECKUPDATES
		[defaultValues setObject: @"YES" forKey: @"CHECKUPDATES"];
		
		// ** MOUNT/UNMOUNT
		[defaultValues setObject:@"YES" forKey:@"MOUNT"];
		[defaultValues setObject:@"YES" forKey:@"UNMOUNT"];
		
		// ** USEDICOMDIR
		[defaultValues setObject: @"YES" forKey: @"USEDICOMDIR"];
		
		// ** SAVEROIS
		[defaultValues setObject: @"YES" forKey: @"SAVEROIS"];
		
		// ** NOLOCALIZER
		[defaultValues setObject: @"YES" forKey: @"NOLOCALIZER"];
		
		// ** TRANSITIONEFFECT
		[defaultValues setObject: @"NO" forKey: @"TRANSITIONEFFECT"];
		
		// ** NOINTERPOLATION
		[defaultValues setObject:@"NO" forKey:@"NOINTERPOLATION"];
		
		// ** WINDOWSIZEVIEWER
		[defaultValues setObject: @"0" forKey: @"WINDOWSIZEVIEWER"];
		
		// ** STILLMOVIEMODE
		[defaultValues setObject: @"0" forKey: @"STILLMOVIEMODE"];
		
		// ** ReserveScreenForDB
		[defaultValues setObject: @"1" forKey: @"ReserveScreenForDB"];
		
		// ** SERIESORDER
		[defaultValues setObject:@"0" forKey:@"SERIESORDER"];
		
		// ** TRANSITIONTYPE
		[defaultValues setObject: @"0" forKey: @"TRANSITIONTYPE"];
		
		// ** COPYDATABASE
		[defaultValues setObject: @"NO" forKey: @"COPYDATABASE"];
		
		// ** SUVCONVERSION
		[defaultValues setObject: @"0" forKey: @"SUVCONVERSION"];
		
		// ** AUTOCLEANINGCOMMENTS
		[defaultValues setObject: @"NO" forKey: @"AUTOCLEANINGCOMMENTS"];
		
		// ** AUTOCLEANINGCOMMENTSTEXT
		[defaultValues setObject: @"" forKey: @"AUTOCLEANINGCOMMENTSTEXT"];
		
		// ** AUTOCLEANINGDONTCONTAIN
		[defaultValues setObject: @"0" forKey: @"AUTOCLEANINGDONTCONTAIN"];
		
		// ** AUTOCLEANINGDELETEORIGINAL
		[defaultValues setObject: @"NO" forKey: @"AUTOCLEANINGDELETEORIGINAL"];
		
		// ** COMMENTSAUTOFILL
		[defaultValues setObject: @"NO" forKey: @"COMMENTSAUTOFILL"];
		
		// ** COMMENTSGROUP
		[defaultValues setObject: @"0008" forKey: @"COMMENTSGROUP"];
		
		// ** COMMENTSELEMENT
		[defaultValues setObject: @"0008" forKey: @"COMMENTSELEMENT"];
		
		// ** Burn Osirix Application	
		[defaultValues setObject: @"YES" forKey: @"Burn Osirix Application"];
		
		// ** Burn Supplementary Folder	
		[defaultValues setObject: @"NO" forKey: @"Burn Supplementary Folder"];
		
		// ** Supplementary Burn Path	
		[defaultValues setObject: @"" forKey: @"Supplementary Burn Path"];
		
		// ** DATABASEINDEX
		[defaultValues setObject:@"0" forKey:@"DATABASEINDEX"];
		
		// ** ANNOTATIONS
		[defaultValues setObject: @"2" forKey: @"ANNOTATIONS"];
		
		// ** CLUT BARS
		[defaultValues setObject: @"3" forKey :@"CLUTBARS"];
		
		// ** COPYDATABASEMODE
		[defaultValues setObject:@"0" forKey:@"COPYDATABASEMODE"];
		
		// ** DATABASELOCATION
		[defaultValues setObject:@"0" forKey:@"DATABASELOCATION"];
		
		// ** FONTNAME
		[defaultValues setObject: @"Geneva" forKey: @"FONTNAME"];
		
		// ** FONTSIZE
		[defaultValues setObject: @"14.0" forKey: @"FONTSIZE"];
		
		// ** DATABASELOCATIONURL
		[defaultValues setObject: @"" forKey: @"DATABASELOCATIONURL"];
		
		// ** REPORTSMODE
		if( [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Microsoft Word"])
			[defaultValues setObject: @"0" forKey: @"REPORTSMODE"];
		else
			[defaultValues setObject: @"1" forKey: @"REPORTSMODE"];
		
		// ** LASTURL
		[defaultValues setObject: @"http://homepage.mac.com/rossetantoine/internet.dcm" forKey: @"LASTURL"];
		
		// ** TEXTURELIMIT
		[defaultValues setObject: @"0" forKey: @"TEXTURELIMIT"];
		
		// ** MAPPERMODEVR
		[defaultValues setObject: @"0" forKey: @"MAPPERMODEVR"];
		
		// ** STARTCOUNT
		[defaultValues setObject: @"0" forKey: @"STARTCOUNT"];
		
		// ** ORIGINALSIZE
		[defaultValues setObject: @"NO" forKey: @"ORIGINALSIZE"];
		
		// ** Scroll Wheel Reversed
		[defaultValues setObject: @"YES" forKey: @"Scroll Wheel Reversed"];
		
		// ** ALBUMNAME
		[defaultValues setObject: @"OsiriX" forKey: @"ALBUMNAME"];
		
		//IMAGE TILING
		[defaultValues setObject:@"1" forKey: @"IMAGEROWS"];
		[defaultValues setObject:@"1" forKey: @"IMAGECOLUMNS"];
		
		// ** STRINGENCODING
		[defaultValues setObject :@"ISO_IR 100" forKey: @"STRINGENCODING"];

		// ** ROI Default
		[defaultValues setObject:[NSNumber numberWithFloat: 2] forKey:@"ROIThickness"];
		[defaultValues setObject:[NSNumber numberWithFloat: 1.0] forKey:@"ROIOpacity"];
		[defaultValues setObject:[NSNumber numberWithFloat: 0.3 * 65535.] forKey:@"ROIColorR"];
		[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROIColorG"];
		[defaultValues setObject:[NSNumber numberWithFloat: 0.3 * 65535.] forKey:@"ROIColorB"];
		[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROITextColorR"];
		[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROITextColorG"];
		[defaultValues setObject:[NSNumber numberWithFloat: 0.0 * 65535.] forKey:@"ROITextColorB"];
		[defaultValues setObject:[NSNumber numberWithFloat: 1.0 * 65535.] forKey:@"ROIRegionColorR"];
		[defaultValues setObject:[NSNumber numberWithFloat: 0.0 * 65535.] forKey:@"ROIRegionColorG"];
		[defaultValues setObject:[NSNumber numberWithFloat: 0.0 * 65535.] forKey:@"ROIRegionColorB"];
		[defaultValues setObject:[NSNumber numberWithFloat: 0.5] forKey:@"ROIRegionOpacity"];
		[defaultValues setObject:[NSNumber numberWithFloat: 5] forKey:@"ROIRegionThickness"];
		
		// **HANGING PROTOCOLS
		NSMutableDictionary *defaultHangingProtocols = [NSMutableDictionary dictionary];
		NSArray *modalities = [NSArray arrayWithObjects:NSLocalizedString(@"CR", nil), NSLocalizedString(@"CT", nil), NSLocalizedString(@"DX", nil), NSLocalizedString(@"ES", nil), NSLocalizedString(@"MG", nil), NSLocalizedString(@"MR", nil), NSLocalizedString(@"NM", nil), NSLocalizedString(@"OT", nil),NSLocalizedString(@"PT", nil),NSLocalizedString(@"RF", nil),NSLocalizedString(@"SC", nil),NSLocalizedString(@"US", nil),NSLocalizedString(@"XA", nil), nil];
		NSEnumerator *enumerator = [modalities objectEnumerator];
		NSString *modality;
		while (modality = [enumerator nextObject]) {
			//NSLog(@"Modality %@", modality);
			NSMutableDictionary *protocol = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Default", [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil] forKeys:[NSArray arrayWithObjects:@"Study Description", @"Rows", @"Columns",@"Image Rows", @"Image Columns", nil]];
			NSMutableArray *protocols = [NSMutableArray arrayWithObject:protocol];
			[defaultHangingProtocols setObject:protocols forKey:modality];
		}
		[defaultValues setObject: defaultHangingProtocols forKey: @"HANGINGPROTOCOLS"];
		
		// ** COLUMNSDATABASE
		NSMutableDictionary *defaultDATABASECOLUMNS = [NSMutableDictionary dictionary];
		[defaultValues setObject: defaultDATABASECOLUMNS forKey: @"COLUMNSDATABASE"];
		
		// **
		
		[defaultValues setObject: @"YES" forKey: @"COPYSETTINGS"];	
		[defaultValues setObject: @"ISO_IR 100" forKey: @"QUERYCHARACTERSET"];
		
		[defaultValues setObject: @"YES" forKey: @"USESTORESCP"];
		// Parsing Series Objects
		[defaultValues setObject:@"YES" forKey:@"splitMultiEchoMR"];
		[defaultValues setObject:@"YES" forKey:@"combineProjectionSeries"];
		
		// ** REGISTER DEFAULTS DICTIONARY

		[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
		
		// CREATE A TEMPORATY FILE DURING STARTUP
		NSString            *path = [documentsDirectory() stringByAppendingString:@"/Loading"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) NEEDTOREBUILD = YES;
		
		[path writeToFile:path atomically:NO];
		
		NSString *reportsDirectory = [documentsDirectory() stringByAppendingString:@"/REPORTS/"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:reportsDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:reportsDirectory attributes:nil];

		// DELETE & CREATE THE TEMP DIRECTORY...
		NSString *tempDirectory = [documentsDirectory() stringByAppendingString:@"/TEMP/"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
		if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory attributes:nil];
		
		NSString *dumpDirectory = [documentsDirectory() stringByAppendingString:@"/DUMP/"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:dumpDirectory] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:dumpDirectory attributes:nil];
		
		// CHECK IF THE REPORT TEMPLATE IS AVAILABLE
		
		NSString *reportFile;
		
		reportFile = [documentsDirectory() stringByAppendingString:@"/ReportTemplate.doc"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:reportFile] == NO)
			[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/ReportTemplate.doc"] toPath:[documentsDirectory() stringByAppendingString:@"/ReportTemplate.doc"] handler:0L];

		reportFile = [documentsDirectory() stringByAppendingString:@"/ReportTemplate.rtf"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:reportFile] == NO)
			[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/ReportTemplate.rtf"] toPath:[documentsDirectory() stringByAppendingString:@"/ReportTemplate.rtf"] handler:0L];
	}
	}
	@catch( NSException *ne)
	{
		NSLog(@"exception: %@", [ne description]);
	}
}


- (void) applicationWillFinishLaunching: (NSNotification *) aNotification
{
	long i;
	
	[[PluginManager alloc] setMenus: filtersMenu :roisMenu :othersMenu :dbMenu];

    NSLog(@"Finishing Launching");
    
	theTask = nil;
	verboseUpdateCheck = NO;
	
	appController = self;
	[self initDCMTK];
	[self restartSTORESCP];
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(windowsMenuChanged:)
               name: NSMenuDidChangeItemNotification
             object: nil];
	
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

	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"CHECKUPDATES"])
		[NSThread detachNewThreadSelector: @selector(checkForUpdates:) toTarget:self withObject: self];

	/// *****************************
	/// *****************************
	// HUG SPECIFIC CODE - DO NOT REMOVE - Thanks! Antoine Rosset
	if([AppController isHUG])
	{
		if(![hostName isEqualToString: @"lavimarch.hcuge.ch"])
		{
			[self HUGDisableBonjourFeature];
			[self HUGVerifyComPACSPlugin];
		}
	}
	/// *****************************
	/// *****************************
		
	//Checks for Bonjour enabled dicom servers. Most likely other copies of OsiriX
	[self startDICOMBonjourSearch];
	
}

- (IBAction) updateViews:(id) sender {
	long				i;
	NSArray				*winList = [NSApp windows];
	
	for( i = 0; i < [winList count]; i++) {
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) {
			[[[winList objectAtIndex:i] windowController] needsDisplayUpdate];
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
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/"]];
		}
	}
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction) checkForUpdates: (id) sender
{
	NSURL				*url;
	NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
	
	if( sender != self) verboseUpdateCheck = YES;
	else verboseUpdateCheck = NO;
	
	if (hasMacOSXTiger())
		url=[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/versionTiger.xml"];
	else
		url=[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/version.xml"];
	
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


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) URLResourceDidFinishLoading: (NSURL*) sender
{
	NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL: sender];
	NSString *latestVersionNumber = [productVersionDict valueForKey:@"OsiriX"];
	
	if (productVersionDict && currVersionNumber && latestVersionNumber)
	{
		if ([latestVersionNumber intValue] <= [currVersionNumber intValue])
		{
			if (verboseUpdateCheck)
				NSRunAlertPanel( NSLocalizedString( @"OsiriX is up-to-date", 0L), NSLocalizedString( @"You have the most recent version of OsiriX.", 0L), NSLocalizedString( @"OK", 0L), nil, nil);
		}
		else
		{
			int button = NSRunAlertPanel( NSLocalizedString( @"New Version Available", 0L), NSLocalizedString( @"A new version of OsiriX is available. Would you like to download the new version now?", 0L), NSLocalizedString( @"OK", 0L), NSLocalizedString( @"Cancel", 0L), nil);
			
			if (NSOKButton == button)
			{
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/"]];
			}
		}
	}
}



- (void) URL: (NSURL*) sender resourceDidFailLoadingWithReason: (NSString*) reason
{
	if (verboseUpdateCheck)
		NSRunAlertPanel( NSLocalizedString( @"No connection available", 0L), reason, NSLocalizedString( @"OK", 0L), nil, nil);
}	


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#pragma mark-

-(void) windowsMenuChanged: (NSNotification*) note
{
	NSMenu  *menu = [note object];
	long	i, val = 1;
	
	if( menu == [NSApp windowsMenu])
	{
		for( i = 9; i < [menu numberOfItems]; i++)
		{
			if( [[[menu itemAtIndex:i] title] isEqualToString:@"Local DICOM Database"] == NO)
			{
				[[menu itemAtIndex:i] setKeyEquivalent:[[[NSNumber numberWithLong:val] stringValue] retain]];
				[[menu itemAtIndex:i] setKeyEquivalentModifierMask: NSCommandKeyMask];
				val++;
			}
		}
	}
}

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
	long	i;
					
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"PreferencePanesViewer"])
		{
			found = YES;
			[[[winList objectAtIndex:i] windowController] showWindow:self];
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
    [super dealloc];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (id) FindViewer:(NSString*) nib :(NSMutableArray*) pixList
{
	long				i;
	NSArray				*winList = [NSApp windows];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString: nib])
		{
			if( [[[winList objectAtIndex:i] windowController] pixList] == pixList)
				return [[winList objectAtIndex:i] windowController];
		}
	}
	
	return 0L;
}

- (NSArray*) FindRelatedViewers:(NSMutableArray*) pixList
{
	long				i;
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList = [NSMutableArray array];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[winList objectAtIndex:i] windowController] respondsToSelector:@selector( pixList)])
		{
			if( [[[winList objectAtIndex:i] windowController] pixList] == pixList)
			{
				[viewersList addObject: [[winList objectAtIndex:i] windowController]];
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
	for (i = 0; i < count; i++) {
		NSScreen *aScreen = [viewers objectAtIndex:i];
		float x = [aScreen frame].origin.x;
		NSEnumerator *enumerator = [arrangedViewers objectEnumerator];
		NSScreen *screen;
		position = i;
		int current = 0;
		while (screen = [enumerator nextObject]) {
			if (x < [screen frame].origin.x) {
				position = current;
				current ++;
				break;
			}
		}
		
		[arrangedViewers insertObject:aScreen atIndex:position];

	}
	
	return arrangedViewers;
		
}

- (NSRect) resizeWindow:(NSWindow*) win	withInRect:(NSRect) destRect
{
	NSRect	returnRect = [win frame];
	
	switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"WINDOWSIZEVIEWER"])
	{
		case 0:
			returnRect = destRect;
		break;
		
		default:
			if( returnRect.size.width > destRect.size.width) returnRect.size.width = destRect.size.width;
			if( returnRect.size.height > destRect.size.height) returnRect.size.height = destRect.size.height;
			
			// Center
			
			returnRect.origin.x = destRect.origin.x + destRect.size.width/2 - returnRect.size.width/2;
			returnRect.origin.y = destRect.origin.y + destRect.size.height/2 - returnRect.size.height/2;
		break;
	}
	
	return returnRect;
}

- (void) tileWindows:(id)sender
{
	long				i, j, k;
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	BOOL				tileDone = NO, origCopySettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYSETTINGS"];
	NSRect				screenRect =  screenFrame();
	
	int					numberOfMonitors = [[self viewerScreens] count];	

	NSLog(@"tile Windows");
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"COPYSETTINGS"];
	
	//get 2D viewer windows
	for( i = 0; i < [winList count]; i++)
	{
		if(	[[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
		{
			[viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	// get viewer count
	int viewerCount = [viewersList count];
	
	NSArray *screens = [self viewerScreens];
	
	//NSLog(@"viewers: %d, screens: %d", viewerCount, numberOfMonitors);
	
	screenRect = [[screens objectAtIndex:0] visibleFrame];
	BOOL landscape = (screenRect.size.width/screenRect.size.height > 1) ? YES : NO;
	if (landscape)
		NSLog(@"Landscape");
	else
		NSLog(@"portrait");

	tileDone = YES;
		
	int rows = [[currentHangingProtocol objectForKey:@"Rows"] intValue];
	int columns = [[currentHangingProtocol objectForKey:@"Columns"] intValue];
	
	if (!currentHangingProtocol)
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
	while (viewerCount > (rows * columns)){
		float ratio = ((float)columns/(float)rows)/numberOfMonitors;
		//NSLog(@"ratio: %f", ratio);
		if (ratio > 1.5 && landscape)
			rows ++;
		else 
			columns ++;
	}
	
	
	// set image tiling to 1 row and columns
	if (![[NSUserDefaults standardUserDefaults] integerForKey: @"IMAGEROWS"])
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGEROWS"];
	if (![[NSUserDefaults standardUserDefaults] integerForKey: @"IMAGECOLUMNS"])
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGECOLUMNS"];
	//I will generalize the options once I get a handle on the issues. LP
	// if monitor count is greater than or equal to viewers. One viewer per window
	if (viewerCount <= numberOfMonitors) {
		int count = [viewersList count];
		int skipScreen = 0;
		
		for( i = 0; i < count; i++) {
			NSScreen *screen = [screens objectAtIndex:i];
			NSRect frame = [screen visibleFrame];
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
			
			[[viewersList objectAtIndex:i] setWindowFrame: [self resizeWindow: [[viewersList objectAtIndex:i] window] withInRect: frame]];				

		}
	} 
	/* 
	Will have columns but no rows. 
	There are more columns than monitors. 
	 Need to separate columns among the window evenly
	 */
	else if((viewerCount <= columns) &&  (viewerCount % numberOfMonitors == 0)){
		int viewersPerScreen = viewerCount / numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
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
		int viewersPerScreen = ceil(((float) columns / numberOfMonitors));

		int extraViewers = viewerCount % numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
			int monitorIndex = (int) i /viewersPerScreen;
			int viewerPosition = i % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:monitorIndex];
			NSRect frame = [screen visibleFrame];
			
			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
			if (monitorIndex < extraViewers) 
				frame.size.width /= viewersPerScreen;
			else
				frame.size.width /= (viewersPerScreen - 1);
				
			frame.origin.x += (frame.size.width * viewerPosition);
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame];
		}
	}
	//adjust for actual number of rows needed
	else if (viewerCount <=  columns * rows)  
	{
		int viewersPerScreen = ceil(((float) columns / numberOfMonitors));
		int extraViewers = columns % numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
			int row = i/columns;
			int columnIndex = (i - (row * columns));
			int monitorIndex =  columnIndex /viewersPerScreen;
			int viewerPosition = columnIndex % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:monitorIndex];
			NSRect frame = [screen visibleFrame];

			if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];

			if (monitorIndex < extraViewers || extraViewers == 0) 
				frame.size.width /= viewersPerScreen;
			else
				frame.size.width /= (viewersPerScreen - 1);
				
			frame.origin.x += (frame.size.width * viewerPosition);
			
			frame.size.height /= rows;
			frame.origin.y += frame.size.height * ((rows - 1) - row);
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame];
		}
	}
	else
	{
		NSLog(@"NO tiling");
		tileDone = NO;
	}

	if( [viewersList count] >= 1)
		[[[viewersList lastObject] window] makeKeyAndOrderFront:self];
	
	[[NSUserDefaults standardUserDefaults] setBool: origCopySettings forKey: @"COPYSETTINGS"];
	[[viewersList lastObject] propagateSettings];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"])
	{
		for( i = 0; i < [viewersList count]; i++)
		{
			[[viewersList objectAtIndex: i] autoHideMatrix];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		[[viewersList objectAtIndex: i] showWindow:self];
	}
	
//	[[viewersList lastObject] makeKeyAndOrderFront:self];
//	[[viewersList lastObject] makeMainWindow];
	
	[viewersList release];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (IBAction) closeAllViewers: (id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Close All Viewers" object: self userInfo: Nil];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) setCurrentHangingProtocolForModality: (NSString *) modality description: (NSString *) description
{

	[currentHangingProtocol release];
	currentHangingProtocol = nil;
	
	if (!modality )
	{
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGEROWS"];
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGECOLUMNS"];

	}
	else
	{
		
		NSArray *hangingProtocolArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] objectForKey: modality];
		if ([hangingProtocolArray count] > 0) {
			NSEnumerator *enumerator = [hangingProtocolArray objectEnumerator];
			currentHangingProtocol = [hangingProtocolArray objectAtIndex:0];
			
			[[NSUserDefaults standardUserDefaults] setInteger: [[currentHangingProtocol objectForKey: @"Image Rows"] intValue] forKey: @"IMAGEROWS"];
			[[NSUserDefaults standardUserDefaults] setInteger: [[currentHangingProtocol objectForKey: @"Image Columns"] intValue] forKey: @"IMAGECOLUMNS"];
			
			NSMutableDictionary *protocol;
			while (protocol = [enumerator nextObject]) {
				NSRange searchRange = [description rangeOfString:[protocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
				if (searchRange.location != NSNotFound) {
					currentHangingProtocol = protocol;
					break;
				}
			}
			
			[currentHangingProtocol retain];
		}
	}
	
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (NSDictionary *) currentHangingProtocol
{
	return currentHangingProtocol;
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) startDICOMBonjourSearch
{
	if (!dicomNetServiceDelegate)
		dicomNetServiceDelegate = [DCMNetServiceDelegate sharedNetServiceDelegate];
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (BOOL) xFlipped
{
	return xFlipped;
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) setXFlipped: (BOOL) v
{
	xFlipped = v;
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (BOOL) yFlipped
{
	return yFlipped;
}


//———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) setYFlipped: (BOOL) v
{
	yFlipped = v;
}

- ( NSMenuItem *)	syncSeriesMenuItem{
	return syncSeriesMenuItem;
}

#pragma mark-
#pragma mark Geneva University Hospital (HUG) specific function

static BOOL isHcugeCh = NO, testDone = NO;

// Test if the computer is in the HUG (domain name == hcuge.ch)
+ (BOOL) isHUG
{
	if( testDone == NO)
	{
		NSArray	*names = [[NSHost currentHost] names];
		int i;
		for( i = 0; i < [names count] && !isHcugeCh; i++)
		{
			int len = [[names objectAtIndex: i] length];
			if ( len < 8 ) continue;  // Fixed out of bounds error in following line when domainname is short.
			NSString *domainName = [[names objectAtIndex: i] substringFromIndex: len - 8];

			if([domainName isEqualToString: @"hcuge.ch"])
			{
				isHcugeCh = YES;
				hostName = [names objectAtIndex: i];
				//NSLog(@"hostName : %@", hostName);
			}
		}
		testDone = YES;
	}
	return isHcugeCh;
}

// Test ComPACS
- (void) HUGVerifyComPACSPlugin
{	
	if( [plugins valueForKey:@"ComPACS"] == 0)
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


@end
