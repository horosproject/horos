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




#import "QuicktimeExport.h"
#import "Wait.h"

static BOOL	PRODUCEFILES;

NSString * documentsDirectory();

static OSErr getFSRefAtPath( NSString* sourceItem, FSRef* sourceRef)
{
    OSErr    err;
    BOOL    isSymLink;
    id manager=[NSFileManager defaultManager];
    NSDictionary *sourceAttribute = [manager fileAttributesAtPath:sourceItem traverseLink:NO];
    isSymLink = ([sourceAttribute objectForKey:@"NSFileType"] == NSFileTypeSymbolicLink);
    if(isSymLink){
        const char    *sourceParentPath;
        FSRef        sourceParentRef;
        HFSUniStr255    sourceFileName;

        sourceParentPath = (UInt8*)[[sourceItem stringByDeletingLastPathComponent] fileSystemRepresentation];
        err = FSPathMakeRef(sourceParentPath, &sourceParentRef, NULL);
        if(err == noErr){
            [[sourceItem lastPathComponent] getCharacters:sourceFileName.unicode];
            sourceFileName.length = [[sourceItem lastPathComponent] length];
            if (sourceFileName.length == 0){
                err = fnfErr;
            }
            else err = FSMakeFSRefUnicode(&sourceParentRef, sourceFileName.length, sourceFileName.unicode, kTextEncodingFullName, sourceRef);
        }
    }
    else{
        err = FSPathMakeRef([sourceItem fileSystemRepresentation], sourceRef, NULL);
    }

    return err;
}

static StringPtr QTUtils_ConvertCToPascalString (char *theString)
{
	StringPtr	myString = malloc(strlen(theString) + 1);
	short		myIndex = 0;

	while (theString[myIndex] != '\0') {
		myString[myIndex + 1] = theString[myIndex];
		myIndex++;
	}
	
	myString[0] = (unsigned char)myIndex;
	
	return(myString);
}

@implementation QuicktimeExport

- (id) initWithSelector:(id) o :(SEL) s :(long) f
{
	[super init];
	
	object = o;
	selector = s;
	numberOfFrames = f;
	codec = kJPEGCodecType;
	quality = codecHighQuality;
	return self;
}

- (void) setCodec:(unsigned long) c :(long) q
{
	codec = c;
	quality = q;
}

- (void) CopyNSImageToGWorld :(NSImage *) image :(GWorldPtr) gWorldPtr
{
    NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
	PixMapHandle 	pixMapHandle;
    Ptr				pixBaseAddr;

    // Lock the pixels
    pixMapHandle = GetGWorldPixMap(gWorldPtr);
    LockPixels (pixMapHandle);
    pixBaseAddr = GetPixBaseAddr(pixMapHandle);
    
	NSData				*tiffRep = [image TIFFRepresentation];
	NSBitmapImageRep	*imageRepresentation = [[NSBitmapImageRep alloc] initWithData:tiffRep];
	
	Ptr bitMapDataPtr = [imageRepresentation bitmapData];
	
	if ((bitMapDataPtr != nil) && (pixBaseAddr != nil))
	{
		long	i,j;
		long	pixmapRowBytes = GetPixRowBytes(pixMapHandle);
		
		NSSize imageSize = [(NSBitmapImageRep *)imageRepresentation size];
		
		long height = imageSize.height;
		long width = imageSize.width;
		
		NSLog(@"%d", [imageRepresentation bitsPerPixel]);
		
		for (i = 0 ; i < height; i++)
		{
			unsigned char *src = bitMapDataPtr + i * [imageRepresentation bytesPerRow];
			unsigned char *dst = pixBaseAddr + i * pixmapRowBytes;
			
			for ( j = 0 ; j < width; j++)
			{
				*dst++ = 0;
				*dst++ = *src++;
				*dst++ = *src++;
				*dst++ = *src++;
			}
		}
	}
	
	[imageRepresentation release];
    UnlockPixels(pixMapHandle);
	
	[subpool release];
}

- (short) QTVideo_AddVideoSamplesToMedia :(Media) theMedia :(Rect *) trackFrame
{
	GWorldPtr theGWorld = nil;
	long curSample;
	ImageDescriptionHandle imageDesc = nil;
	CGrafPtr oldPort;
	GDHandle oldGDeviceH;
	OSErr err = noErr;
	ComponentInstance   ci;
	long			dataSize;
	ComponentResult		result;
	short  notSyncFlag;
	Handle 			theRes;
	NSImage *im;
	long	maxImage;
                
            // Create a graphics world
        err = NewGWorld (&theGWorld,	/* pointer to created gworld */	
                32,		/* pixel depth */
                trackFrame, 		/* bounds */
                nil, 			/* color table */
                nil,			/* handle to GDevice */ 
                (GWorldFlags)0);	/* flags */


        // Lock the pixels
        LockPixels (GetGWorldPixMap(theGWorld)/*GetPortPixMap(theGWorld)*/);


    ci = OpenDefaultComponent (StandardCompressionType, StandardCompressionSubType);

    // Do not requite the user to enter the keyframe data
     long flags;
     SCGetInfo(ci, scPreferenceFlagsType, &flags);
     flags &= ~scAllowZeroKeyFrameRate;
     SCSetInfo(ci, scPreferenceFlagsType, &flags);
    
    SCSpatialSettings theDefaultChoice = { codec,
                                       (CodecComponent)0L,
                                       0,
                                       quality };
    SCSetInfo(ci, scSpatialSettingsType, &theDefaultChoice);

    SCTemporalSettings timeSettings;
	timeSettings.temporalQuality = codecHighQuality;

	timeSettings.frameRate = X2Fix(10.0);
	timeSettings.keyFrameRate = 1;
	
	SCSetInfo(ci, scTemporalSettingsType, &timeSettings);
    
    im = [object performSelector: selector withObject: [NSNumber numberWithLong:-1] withObject:[NSNumber numberWithLong: numberOfFrames]];
    
    [self CopyNSImageToGWorld: im :theGWorld];
    
	if( PRODUCEFILES == NO)
	{
		result = SCSetTestImagePixMap (ci,
						   GetGWorldPixMap(theGWorld),
						   0L,
						   scPreferScalingAndCropping);
		
		result = SCRequestSequenceSettings (ci);
	}
	else result = 0;
	
    [im release];
    if (result < 0 || result == scUserCancelled) return -1;
	
	Wait    *wait = [[Wait alloc] initWithString:0L];
	[wait showWindow:self];
	
    SCGetInfo(ci, scTemporalSettingsType, &timeSettings);

result = SCCompressSequenceBegin (ci,
				GetGWorldPixMap(theGWorld),
				0L,
				&imageDesc);

// Change the current graphics port to the GWorld
GetGWorld(&oldPort, &oldGDeviceH);
SetGWorld(theGWorld, nil);

// For each sample...
 maxImage = numberOfFrames;

[wait setCancel:YES];
[[wait progress] setMaxValue:maxImage];

for (curSample = 0; curSample < maxImage; curSample++) 
{
	NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];

	NSLog(@"frame: %d", curSample);

    im = [object performSelector: selector withObject: [NSNumber numberWithLong: curSample] withObject:[NSNumber numberWithLong: numberOfFrames]];
	
	UpdateSystemActivity (UsrActivity);	// avoid sleep or screen saver mode
	
	if( PRODUCEFILES == NO)
	{
		[self CopyNSImageToGWorld :im :theGWorld];
		
		result = SCCompressSequenceFrame (ci,
				  GetGWorldPixMap(theGWorld),
				  0L,
				  &theRes,
				  &dataSize,
				  &notSyncFlag);
			
			if( curSample == maxImage-1)
			 // Add sample data and a description to a media
            err = AddMediaSample(theMedia,	/* media specifier */ 
                    theRes,	/* handle to sample data - dataIn */
                    0,		/* specifies offset into data reffered to by dataIn handle */
                    dataSize, /* number of bytes of sample data to be added */ 
                    X2Fix( 0.01 / 500.0),		 /* frame duration = 1/10 sec */
                    (SampleDescriptionHandle)imageDesc,	/* sample description handle */ 
                    1,	/* number of samples */
                    notSyncFlag,	/* control flag indicating self-contained samples */
                    nil);		/* returns a time value where sample was insterted */
			else
            // Add sample data and a description to a media
            err = AddMediaSample(theMedia,	/* media specifier */ 
                    theRes,	/* handle to sample data - dataIn */
                    0,		/* specifies offset into data reffered to by dataIn handle */
                    dataSize, /* number of bytes of sample data to be added */ 
                    X2Fix( 0.01 / Fix2X(timeSettings.frameRate)),		 /* frame duration = 1/10 sec */
                    (SampleDescriptionHandle)imageDesc,	/* sample description handle */ 
                    1,	/* number of samples */
                    notSyncFlag,	/* control flag indicating self-contained samples */
                    nil);		/* returns a time value where sample was insterted */
	}
	else
	{
		NSString *curFile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/OsiriX%4d.tif", curSample];
		
		[[im TIFFRepresentation] writeToFile:curFile atomically:YES];
	}
	
	
	[im release];
	
	[wait incrementBy:1];

	if( [wait aborted])
	{
		err = -1;
		curSample = maxImage;
	}
	[subpool release];
}
		
UnlockPixels (GetGWorldPixMap(theGWorld));

SetGWorld (oldPort, oldGDeviceH);

[wait close];

[wait release];

// Dealocate our previously alocated handles and GWorld

if (theGWorld)
{
	DisposeGWorld (theGWorld);
}
	
return err;
} 

-(short) QTVideo_CreateMyVideoTrack:(Movie) theMovie :(Rect *) trackFrame
{
	Track theTrack;
	Media theMedia;
	OSErr err = noErr;
        
        // 1. Create the track
        theTrack = NewMovieTrack (theMovie, 		/* movie specifier */
                            FixRatio((*trackFrame).right,1),  /* width */
                            FixRatio((*trackFrame).bottom,1), /* height */
                                                        kNoVolume);  /* trackVolume */
        
        // 2. Create the media for the track
        theMedia = NewTrackMedia (theTrack,		/* track identifier */
                                VideoMediaType,		/* type of media */
                                600, 	/* time coordinate system */
                                nil,			/* data reference - use the file that is associated with the movie  */
                                0);			/* data reference type */

        // 3. Establish a media-editing session
        BeginMediaEdits (theMedia);

        // 3a. Add Samples to the media
        err = [self QTVideo_AddVideoSamplesToMedia: theMedia :trackFrame];
        
        // 3b. End media-editing session
        EndMediaEdits (theMedia);

        // 4. Insert a reference to a media segment into the track
        InsertMediaIntoTrack (theTrack,		/* track specifier */
                                0,	/* track start time */
                                0, 	/* media start time */
                                GetMediaDuration(theMedia), /* media duration */
                                X2Fix(1.0));		/* media rate ((Fixed) 0x00010000L) */

    return err;
} 

- (Movie) CreateMovie: (Rect*) trackFrame :(NSString *) filename
{
    Movie theMovie = nil;
    FSSpec mySpec;
    short resRefNum = 0;
    short resId = movieInDataForkResID;
    OSErr err = noErr;
    FSRef fsRef;


    [filename writeToFile:filename atomically:false];
    
    err = getFSRefAtPath(filename, &fsRef);
    
    
    err =FSGetCatalogInfo(&fsRef, 
                                    kFSCatInfoNone, 
                                    NULL,
                                    NULL,
                                    &mySpec,
                                    NULL);
    
    err = CreateMovieFile (&mySpec, 
                            'TVOD',
                            smCurrentScript, 
                            createMovieFileDeleteCurFile | createMovieFileDontCreateResFile,
                            &resRefNum, 
                            &theMovie );
    if( err == 0)
    {
        err = [self QTVideo_CreateMyVideoTrack: theMovie : trackFrame];
        if( err == noErr)
        {
            err = AddMovieResource (theMovie, resRefNum, &resId, QTUtils_ConvertCToPascalString ("testing"));
            if (resRefNum)
            {
                CloseMovieFile (resRefNum);
            }
        }
        else
        {
			CloseMovieFile (resRefNum);
			
            DisposeMovie( theMovie);
            theMovie = 0L;
            
            FSpDelete( &mySpec);
        }
    }
    else
    {
        NSRunAlertPanel(NSLocalizedString(@"Error",nil), NSLocalizedString(@"I cannot create this file... File is busy? opened? not enough place?",nil), nil, nil, nil);
    }
    return theMovie;
}

- (NSString*) generateMovie :(BOOL) openIt :(BOOL) produceFiles :(NSString*) name
{
    Rect            trackFrame;
    NSSavePanel     *panel = [NSSavePanel savePanel];
    Movie           theMovie = nil;
	long			result;
	NSString		*fileName;
	
	PRODUCEFILES = produceFiles;
	
	if( PRODUCEFILES)
	{
		result = NSFileHandlingPanelOKButton;
		
		[[NSFileManager defaultManager] removeFileAtPath: [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"] handler: 0L];
		[[NSFileManager defaultManager] createDirectoryAtPath: [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"] attributes: 0L];
		
		fileName = [documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriXMovie.mov"];
	}
	else
	{
		[panel setCanSelectHiddenExtension:YES];
		[panel setRequiredFileType:@"mov"];
		
		result = [panel runModalForDirectory:0L file:name];
		
		fileName = [panel filename];
	}
	
	if( result == NSFileHandlingPanelOKButton)
	{
		trackFrame.top = 0;
		trackFrame.left = 0;
		
		NSImage *im = [object performSelector: selector withObject: [NSNumber numberWithLong:-1] withObject:[NSNumber numberWithLong: numberOfFrames]];
		
		trackFrame.bottom = [im size].height;
		trackFrame.right = [im size].width;
		
		theMovie = [self CreateMovie: &trackFrame : fileName];
		
		if( theMovie)
		{
			if( openIt == YES && PRODUCEFILES == NO)
			{
				NSWorkspace *ws = [NSWorkspace sharedWorkspace];
				[ws openFile:fileName];
			}
			
			DisposeMovie( theMovie);
			theMovie = 0L;
			
			return fileName;
		}
	}
	
	return 0L;
}
@end
