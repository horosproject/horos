//////////
//
//	File:		VRMakeObject.c
//
//	Contains:	Code for creating a QuickTime VR object movie from a linear QuickTime movie.
//
//	Written by:	Tim Monroe
//				Based on MakeQTVRObject code by Pete Falco and Michael Chen (and others?).
//
//	Copyright:	© 1991-1998 by Apple Computer, Inc., all rights reserved.
//
//	Change History (most recent first):
//
//	   <6>	 	03/21/00	rtm		made changes to get things running under CarbonLib
//	   <5>	 	02/01/99	rtm		reworked prompt and filename handling to remove "\p" sequences
//	   <4>	 	09/30/98	rtm		tweaked call to AddMovieResource to create single-fork movies;
//									tweaked call to FlattenMovieData to enable FastStart option
//	   <3>	 	01/22/98	rtm		version 2.0 objects working on MacOS and Windows
//	   <2>	 	01/21/98	rtm		version 1.0 objects working on MacOS and Windows
//	   <1>	 	01/20/98	rtm		first file from QTVRObjectAuthoring.c in MakeQTVRObject 1.0b2
//
//	This file contains functions that convert a linear QuickTime movie into a QuickTime VR object movie.
//	Here we can create both version 1.0 and version 2.0 QTVR object movies.
//
//
//	VERSION 2.0 FILE FORMAT
//
//	The definitive source of information about creating QTVR 2.0 object movies is Chapter 3 of the
//	book "Virtual Reality Programming With QuickTime VR 2.0". (This information is also available
//	online, at <http://dev.info.apple.com/dev/techsupport/insidemac/qtvr/qtvrapi-2.html>.) Here is
//	a condensed version of the info in that chapter, as pertains to objects:
//
//	An object movie is a QuickTime movie that contains at least three tracks: a QTVR track, an object
//	track, and an object image track. In addition, a QuickTime VR movie must contain some special user data
//	that specifies the QuickTime VR movie controller. A QuickTime VR movie can also contain other kinds of
//	tracks, such as hot spot image tracks and even sound tracks.
//
//	A QuickTime VR movie contains a single "QTVR track", which maintains a list of the nodes in the
//	movie. Each individual sample in the QTVR track's media contains information about a single node,
//	such as the node's type, ID, and name. Since we are creating a single-node movie here, our
//	QTVR track will contain a single media sample. 
//
//	Every media sample in a QTVR track has the same sample description, whose type is QTVRSampleDescription.
//	The data field of that sample description is a "VR world", an atom container whose child atoms specify
//	information about the nodes in the movie, such as the default node ID and the default imaging properties.
//	We'll spend a good bit of time putting things into the VR world.
//
//	An object movie also contains a single "object track", which contains information specific to the
//	object nodes in a scene. An object track has a media sample for each media sample in the QTVR track.
//	As a result, our object track will have one sample. The QTVRObjectSampleAtom structure defines the media
//	sample data. 
//
//	The actual image data for an object node is contained in an "object image track". The individual
//	frames in that track are various views of the object. There may also be a "hot spot image track" that
//	contains the hot spot images. This sample code does not create hot spot image tracks.
//
//	So, our general strategy, given a linear QuickTime movie, is as follows:
//		(1) Create a new, empty movie. Call this movie the "QTVR movie".
//		(2) Create a QTVR track and its associated media.
//		(3) Create a VR world atom container; this is stored in the sample description for the QTVR track.
//		(4) Create a node information atom container for each node; this is stored as a media sample
//	        in the QTVR track.
//		(5) Create an object track and add it to the movie.
//		(6)	Create an object image track by copying the video track from the QuickTime movie to the QTVR movie.
//		(7) Set up track references from the QTVR track to the object track, and from the object track
//	        to the object image track.
//		(8) Add a user data item that identifies the QTVR movie controller.
//		(9) Flatten the QTVR movie into the final object movie.
//
//
//	VERSION 1.0 FILE FORMAT
//
//	The definitive source of information about creating QTVR version 1.0 object movies is Technote 1036,
//	"QuickTime VR 1.0 Object Movie File Format" released in March 1996, available online at the address
//	<http://devworld.apple.com/dev/technotes/tn/tn1036.html>. Here is a condensed version of the info
//	in that technote:
//
//	For version 1.0 object movies, the file format is quite simple. A single-node object movie contains
//	an "object video track", an active video track that contains the various views of the object in the
//	movie frames. An object video track is essentially just a standard QuickTime video track and is the
//	same as the version 2 object image tack.
//
//	What distinguishes an object movie from a standard linear QuickTime movie is the manner in which
//	the frames of the video track are displayed to the user. This is determined by a special piece of
//	user data stored in the object movie file, which selects the QuickTime VR movie controller.
//
//	Various display parameters of the object movie (for instance, the default pan angle) are contained in
//	another piece of user data, of type 'NAVG'. The data in this user data item is structured according
//	to the QTVRObjectFileFormat1x0Record structure.
//
//	A QuickTime VR object movie can also contain a movie poster of the object and a movie file preview.
//	A movie poster is a single view of the object that can be used to represent the object. A poster is
//	defined by specifying a time in the object video track. In general, the poster view should be the same
//	as the initial object view specified in the 'NAVG' user data item. A movie file preview is some part
//	of the object movie that is displayed in order to give the user an idea of what's in the entire movie
//	(for instance, in Standard File Package dialog boxes).
//
//	Version 1.0 object movies do not support hot spots.
//
//	So, our general strategy, given a linear QuickTime movie, is as follows:
//		(1) Create a new, empty movie. Call this movie the "QTVR movie".
//		(2)	Create an object video track by copying the video track from the linear movie to the QTVR movie.
//		(3) Add a user data item of type 'NAVG' to the QTVR movie that specifies object parameters.
//		(4)	Add a user data item of type 'ctyp' that identifies the QTVR movie controller.
//		(5) Set the poster time to the desired view of the object.
//		(6) Create a movie file preview and add it to the movie.
//		(7) Flatten the QTVR movie into the final object movie.
//
//
//	NOTES:
//
//	*** (1) ***
//	The routines in this file use lots of hard-coded values. A real-life application would want to elicit the
//	actual values for a specific object movie from the user. (Hey, this is only sample code!)
//
//	*** (2) ***
//	All data in QTAtom structures must be in big-endian format. We use macros like EndianU32_NtoB to convert
//	values into the proper format before inserting them into atoms. See VRObject_CreateVRWorld for some examples.
//	Similarly, data in the version 1.0 'NAVG' user data item must be big-endian.
//
//////////

#include "VRMakeObject.h"
OSErr VRObject_ImportVideoTrack (Movie theSrcMovie, Movie theDstMovie, Track *theImageTrack);
long					gVersionToCreate = kQTVRVersion2;		// the version of the file format we create
OSErr VRObject_AddStr255ToAtomContainer (QTAtomContainer theContainer, QTAtom theParent, Str255 theString, QTAtomID *theID);
void VRObject_ConvertFloatToBigEndian (float *theFloat);
OSErr VRObject_SetControllerType (Movie theMovie, OSType theType);
OSErr VRObject_GetPanAndTiltFromTime (TimeValue theTime,
										TimeValue theFrameDuration,
										short theNumColumns,
										short theNumRows,
										short theLoopSize,
										Float32 theStartPan,
										Float32 theEndPan,
										Float32 theStartTilt,
										Float32 theEndTilt,
										Float32 *thePan, 
										Float32 *theTilt);
//////////
//
// VRObject_CreateVRWorld
// Create a VR world atom container and add the basic required atoms to it. Also, create a
// node information atom container and add a node header atom to it. Return both atom containers.
//
// The caller is responsible for disposing of the VR world and the node information atom
// (by calling QTDisposeAtomContainer).
//
// This function assumes that the scene described by the VR world contains a single node whose
// type is specified by the theNodeType parameter.
//
//////////

OSErr VRObject_CreateVRWorld (QTAtomContainer *theVRWorld, QTAtomContainer *theNodeInfo, OSType theNodeType)
{
	QTAtomContainer			myVRWorld = NULL;
	QTAtomContainer			myNodeInfo = NULL;
	QTVRWorldHeaderAtom		myVRWorldHeaderAtom;
	QTAtom					myImagingParentAtom;
	QTAtom					myNodeParentAtom;
	QTAtom					myNodeAtom;
	QTVRPanoImagingAtom		myPanoImagingAtom;
	QTVRNodeLocationAtom	myNodeLocationAtom;
	QTVRNodeHeaderAtom		myNodeHeaderAtom;
	UInt16					myIndex;
	OSErr					myErr = noErr;

	//////////
	//
	// create a VR world atom container
	//
	//////////

	myErr = QTNewAtomContainer(&myVRWorld);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	

	//////////
	//
	// add a VR world header atom to the VR world
	//
	//////////

	myVRWorldHeaderAtom.majorVersion = EndianU16_NtoB(kQTVRMajorVersion);
	myVRWorldHeaderAtom.minorVersion = EndianU16_NtoB(kQTVRMinorVersion);

	// insert the scene name string, if we have one; if not, set nameAtomID to 0
	if (false) {
		Str255				myStr = "\pMy Scene";
		QTAtomID			myID;
		
		myErr = VRObject_AddStr255ToAtomContainer(myVRWorld, kParentAtomIsContainer, myStr, &myID);
		myVRWorldHeaderAtom.nameAtomID = EndianU32_NtoB(myID);
	} else
		myVRWorldHeaderAtom.nameAtomID = EndianU32_NtoB(0L);
	
	myVRWorldHeaderAtom.defaultNodeID = EndianU32_NtoB(kDefaultNodeID);
	myVRWorldHeaderAtom.vrWorldFlags = EndianU32_NtoB(0L);
	myVRWorldHeaderAtom.reserved1 = EndianU32_NtoB(0L);
	myVRWorldHeaderAtom.reserved2 = EndianU32_NtoB(0L);

	// add the atom to the atom container (the VR world)
	myErr = QTInsertChild(myVRWorld, kParentAtomIsContainer, kQTVRWorldHeaderAtomType, 1, 1, sizeof(QTVRWorldHeaderAtom), &myVRWorldHeaderAtom, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
		
	//////////
	//
	// add an imaging parent atom to the VR world and insert imaging atoms into it
	//
	// imaging atoms describe the default imaging characteristics for the different types of nodes in the scene;
	// currently, only the panorama imaging atoms are defined, so we'll include those (even in object movies)
	//
	//////////
	
	myErr = QTInsertChild(myVRWorld, kParentAtomIsContainer, kQTVRImagingParentAtomType, 1, 1, 0, NULL, &myImagingParentAtom);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
		
	// fill in the fields of the panorama imaging atom structure
	myPanoImagingAtom.majorVersion = EndianU16_NtoB(kQTVRMajorVersion);
	myPanoImagingAtom.minorVersion = EndianU16_NtoB(kQTVRMinorVersion);
	myPanoImagingAtom.correction = EndianU32_NtoB(kQTVRFullCorrection);
	myPanoImagingAtom.imagingValidFlags = EndianU32_NtoB(kQTVRValidCorrection | kQTVRValidQuality | kQTVRValidDirectDraw);
	for (myIndex = 0; myIndex < 6; myIndex++)
		myPanoImagingAtom.imagingProperties[myIndex] = EndianU32_NtoB(0L);
	myPanoImagingAtom.reserved1 = EndianU32_NtoB(0L);
	myPanoImagingAtom.reserved2 = EndianU32_NtoB(0L);
	
	// add a panorama imaging atom for kQTVRMotion state
	myPanoImagingAtom.quality = EndianU32_NtoB(codecLowQuality);
	myPanoImagingAtom.directDraw = EndianU32_NtoB(true);
	myPanoImagingAtom.imagingMode = EndianU32_NtoB(kQTVRMotion);
	myErr = QTInsertChild(myVRWorld, myImagingParentAtom, kQTVRPanoImagingAtomType, 0, 0, sizeof(QTVRPanoImagingAtom), &myPanoImagingAtom, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
		
	// add a panorama imaging atom for kQTVRStatic state
	myPanoImagingAtom.quality = EndianU32_NtoB(codecHighQuality);
	myPanoImagingAtom.directDraw = EndianU32_NtoB(false);
	myPanoImagingAtom.imagingMode = EndianU32_NtoB(kQTVRStatic);
	myErr = QTInsertChild(myVRWorld, myImagingParentAtom, kQTVRPanoImagingAtomType, 0, 0, sizeof(QTVRPanoImagingAtom), &myPanoImagingAtom, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
		
	//////////
	//
	// add a node parent atom to the VR world and insert node ID atoms into it
	//
	//////////
	
	myErr = QTInsertChild(myVRWorld, kParentAtomIsContainer, kQTVRNodeParentAtomType, 1, 1, 0, NULL, &myNodeParentAtom);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
		
	// add a node ID atom
	myErr = QTInsertChild(myVRWorld, myNodeParentAtom, kQTVRNodeIDAtomType, kDefaultNodeID, 0, 0, 0, &myNodeAtom);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	
	// add a single node location atom to the node ID atom
	myNodeLocationAtom.majorVersion = EndianU16_NtoB(kQTVRMajorVersion);
	myNodeLocationAtom.minorVersion = EndianU16_NtoB(kQTVRMinorVersion);
	myNodeLocationAtom.nodeType = EndianU32_NtoB(theNodeType);
	myNodeLocationAtom.locationFlags = EndianU32_NtoB(kQTVRSameFile);
	myNodeLocationAtom.locationData = EndianU32_NtoB(0);
	myNodeLocationAtom.reserved1 = EndianU32_NtoB(0);
	myNodeLocationAtom.reserved2 = EndianU32_NtoB(0);
	
	// insert the node location atom into the node ID atom
	myErr = QTInsertChild(myVRWorld, myNodeAtom, kQTVRNodeLocationAtomType, 1, 1, sizeof(QTVRNodeLocationAtom), &myNodeLocationAtom, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	
	//////////
	//
	// create a node information atom container and add a node header atom to it
	//
	//////////
	
	myErr = QTNewAtomContainer(&myNodeInfo);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	

	myNodeHeaderAtom.majorVersion = EndianU16_NtoB(kQTVRMajorVersion);
	myNodeHeaderAtom.minorVersion = EndianU16_NtoB(kQTVRMinorVersion);
	myNodeHeaderAtom.nodeType = EndianU32_NtoB(theNodeType);
	myNodeHeaderAtom.nodeID = EndianU32_NtoB(kDefaultNodeID);
	myNodeHeaderAtom.commentAtomID = EndianU32_NtoB(0L);
	myNodeHeaderAtom.reserved1 = EndianU32_NtoB(0L);
	myNodeHeaderAtom.reserved2 = EndianU32_NtoB(0L);
	
	// insert the node name string into the node info atom container
	if (false) {
		Str255				myStr = "\pMy Node";
		QTAtomID			myID;
		
		myErr = VRObject_AddStr255ToAtomContainer(myNodeInfo, kParentAtomIsContainer, myStr, &myID);
		myNodeHeaderAtom.nameAtomID = EndianU32_NtoB(myID);
	} else
		myNodeHeaderAtom.nameAtomID = EndianU32_NtoB(0L);
	
	// insert the node header atom into the node info atom container
	myErr = QTInsertChild(myNodeInfo, kParentAtomIsContainer, kQTVRNodeHeaderAtomType, 1, 1, sizeof(QTVRNodeHeaderAtom), &myNodeHeaderAtom, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	
	//////////
	//
	// create hot spot atoms and add them to the node information atom container
	// [left as an exercise for the reader]
	//
	//////////
	
bail:
	// return the atom containers that we've created and configured here
	*theVRWorld = myVRWorld;
	*theNodeInfo = myNodeInfo;
	
	return(myErr);
}


//////////
//
// VRObject_CreateObjectTrack
// Configure the specified object track. Note that theSrcMovie is the linear QuickTime movie.
//
//////////

OSErr VRObject_CreateObjectTrack (Movie theSrcMovie, Track theObjectTrack, Media theObjectMedia, long maxFrames)
{
	SampleDescriptionHandle		mySampleDesc = NULL;
	QTAtomContainer				myObjectSample;
	QTVRObjectSampleAtom		myObjectSampleData;
	TimeValue					myDuration;
	TimeValue					myCurrTime;
	Float32						myInitialPan, myInitialTilt;
	OSErr						myErr = noErr;

	//////////
	//
	// get some information from the linear QuickTime movie
	//
	//////////
	
	// get the duration of a single video frame
	GetMovieNextInterestingTime(theSrcMovie, nextTimeMediaSample, 0, NULL, (TimeValue)0, fixed1, NULL, &myDuration);

	// get the movie's current time, and convert it to an initial pan/tilt pair
	myCurrTime = GetMovieTime(theSrcMovie, NULL);
	
	VRObject_GetPanAndTiltFromTime(myCurrTime,
									kDefaultFrameDuration,
									kDefaultNumOfColumns,
									kDefaultNumOfRows,
									kDefaultLoopSize,
									kDefaultStartPan,
									kDefaultEndPan,
									kDefaultStartTilt,
									kDefaultEndTilt,
									&myInitialPan, &myInitialTilt);

	//////////
	//
	// add a media sample to the object track
	//
	//////////
	
	// create a sample description; this contains no real info, but AddMediaSample requires it
	mySampleDesc = (SampleDescriptionHandle)NewHandleClear(sizeof(SampleDescription));

	myErr = QTNewAtomContainer(&myObjectSample);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	
	myObjectSampleData.majorVersion = EndianU16_NtoB(kQTVRMajorVersion);
	myObjectSampleData.minorVersion = EndianU16_NtoB(kQTVRMinorVersion);
	
	myObjectSampleData.movieType = EndianU16_NtoB(kDefaultMovieType);
	myObjectSampleData.viewStateCount = EndianU16_NtoB(kDefaultViewStateCount);
	myObjectSampleData.defaultViewState = EndianU16_NtoB(kDefaultDefaultViewState);
	myObjectSampleData.mouseDownViewState = EndianU16_NtoB(kDefaultMouseDownViewState);
	
	myObjectSampleData.viewDuration = EndianU32_NtoB(myDuration);
	
	myObjectSampleData.minPan = EndianU32_NtoB (0);
	myObjectSampleData.maxPan = EndianU32_NtoB (360);
	myObjectSampleData.defaultPan = EndianU32_NtoB (0);
	
	switch( maxFrames)
	{
		case 18:
			myObjectSampleData.columns = EndianU32_NtoB((UInt32) 18);
			myObjectSampleData.rows = EndianU32_NtoB((UInt32)1);

			myObjectSampleData.minTilt =  (0);
			myObjectSampleData.maxTilt =  (0);
			myObjectSampleData.defaultTilt =  (0);
		break;
		
		case 36:
			myObjectSampleData.columns = EndianU32_NtoB((UInt32)36);
			myObjectSampleData.rows = EndianU32_NtoB((UInt32)1);
			
			myObjectSampleData.minTilt =  (0);
			myObjectSampleData.maxTilt =  (0);
			myObjectSampleData.defaultTilt =  (0);
		break;
		
		case 100:
			myObjectSampleData.columns = EndianU32_NtoB((UInt32)10);
			myObjectSampleData.rows = EndianU32_NtoB((UInt32)10);

			myObjectSampleData.minTilt =  (90);
			myObjectSampleData.maxTilt =  (-90);
			myObjectSampleData.defaultTilt =  (90);
		break;
		
		case 400:
			myObjectSampleData.columns = EndianU32_NtoB((UInt32)20);
			myObjectSampleData.rows = EndianU32_NtoB((UInt32)20);

			myObjectSampleData.minTilt =  (90);
			myObjectSampleData.maxTilt =  (-90);
			myObjectSampleData.defaultTilt =  (90);
		break;
		
		case 1600:
			myObjectSampleData.columns = EndianU32_NtoB((UInt32)40);
			myObjectSampleData.rows = EndianU32_NtoB((UInt32)40);

			myObjectSampleData.minTilt =  (90);
			myObjectSampleData.maxTilt =  (-90);
			myObjectSampleData.defaultTilt =  (90);
		break;
	}
	
	
	myObjectSampleData.mouseMotionScale = kDefaultMouseMotionScale;
	myObjectSampleData.minFieldOfView = kDefaultMinFieldOfView;
	myObjectSampleData.fieldOfView = kDefaultFieldOfView;
	myObjectSampleData.defaultFieldOfView = kDefaultFieldOfView;
	myObjectSampleData.defaultViewCenterH = kDefaultDefaultViewCenterH;
	myObjectSampleData.defaultViewCenterV = kDefaultDefaultViewCenterV;
	myObjectSampleData.viewRate = kDefaultViewRate;
	myObjectSampleData.frameRate = kDefaultFrameRate;

	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.mouseMotionScale);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.minPan);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.maxPan);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.defaultPan);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.minTilt);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.maxTilt);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.defaultTilt);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.minFieldOfView);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.fieldOfView);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.defaultFieldOfView);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.defaultViewCenterH);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.defaultViewCenterV);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.viewRate);
	VRObject_ConvertFloatToBigEndian(&myObjectSampleData.frameRate);

	myObjectSampleData.animationSettings = EndianU32_NtoB(kDefaultAnimationSettings);
	myObjectSampleData.controlSettings = EndianU32_NtoB(kDefaultControlSettings); 
	
	// insert the object sample atom into the object sample atom container
	myErr = QTInsertChild(myObjectSample, kParentAtomIsContainer, kQTVRObjectInfoAtomType, 1, 1, sizeof(QTVRObjectSampleAtom), &myObjectSampleData, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	
	// get the duration of the object image track (which is the same as the duration of the linear video track)
	myDuration = GetMovieDuration(theSrcMovie);
	
	// create the media sample
	BeginMediaEdits(theObjectMedia);

	myErr = AddMediaSample(theObjectMedia, (Handle)myObjectSample, 0, GetHandleSize((Handle)myObjectSample), myDuration, (SampleDescriptionHandle)mySampleDesc, 1, 0, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	

	EndMediaEdits(theObjectMedia);

	// add the media to the track
	myErr = InsertMediaIntoTrack(theObjectTrack, 0, 0, myDuration, fixed1);
	
bail:
	return(myErr);
}

//////////
//
// VRObject_CreateQTVRMovieVers2x0
// Create a single-node QuickTime VR object movie from the specified QuickTime movie.
//
// NOTE: This function builds a movie that conforms to version 2.0 of the QuickTime VR file format.
//
//////////

OSErr VRObject_CreateQTVRMovieVers2x0 (FSSpec *theObjMovSpec, FSSpec *theSrcMovSpec, long maxFrames)
{
	Handle							myHandle = NULL;
	SampleDescriptionHandle			mySampleDesc = NULL;
	QTVRSampleDescriptionHandle		myQTVRDesc = NULL;
	QTAtomContainer					myVRWorld;
	QTAtomContainer					myNodeInfo;
	Movie							myObjMovie = NULL;
	Movie							mySrcMovie = NULL;
 	short							myObjResRefNum = 0;
	short							mySrcResRefNum = 0;
	short							myResID = movieInDataForkResID;
	Track							myQTVRTrack = NULL;
	Media							myQTVRMedia = NULL;
	Track							myObjectTrack = NULL;
	Media							myObjectMedia = NULL;
	Track							myImageTrack = NULL;
	long							mySize;
	long							myFlags = createMovieFileDeleteCurFile | createMovieFileDontCreateResFile;
	TimeValue						myDuration;
	TimeScale						myScale;
	Fixed							myWidth, myHeight;
	OSErr							myErr = noErr;
	
	//////////
	//
	// create a new movie
	//
	//////////

	// create a movie file for the destination movie
	myErr = CreateMovieFile(theObjMovSpec, FOUR_CHAR_CODE('TVOD'), smCurrentScript, myFlags, &myObjResRefNum, &myObjMovie);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	

	//////////
	//
	// copy the video track from the linear movie to the new movie; this is the "object image track"
	//
	//////////

	// open the source linear movie file
	myErr = OpenMovieFile(theSrcMovSpec, &mySrcResRefNum, fsRdPerm);
	if (myErr != noErr)
		goto bail;
	
	myErr = NewMovieFromFile(&mySrcMovie, mySrcResRefNum, NULL, 0, 0, 0);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	
	SetMoviePlayHints(mySrcMovie, hintsHighQuality, hintsHighQuality);

	// copy the video track from the linear movie to the object movie
	myErr = VRObject_ImportVideoTrack(mySrcMovie, myObjMovie, &myImageTrack);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}
		
	
	//////////
	//
	// get some information from the linear QuickTime movie
	//
	//////////
	
	// get the duration and dimensions of the object image track
	myDuration = GetTrackDuration(myImageTrack);
	GetTrackDimensions(myImageTrack, &myWidth, &myHeight);
	myScale = GetMediaTimeScale(GetTrackMedia(myImageTrack));
	
	//////////
	//
	// create the QTVR movie track and media
	//
	//////////

	myQTVRTrack = NewMovieTrack(myObjMovie, myWidth, myHeight, kFullVolume);
	myQTVRMedia = NewTrackMedia(myQTVRTrack, kQTVRQTVRType, myScale, NULL, 0);
	if ((myQTVRTrack == NULL) || (myQTVRMedia == NULL))
		goto bail;
		
	// create a VR world atom container and a node information atom container;
	// remember that the VR world becomes part of the QTVR sample description,
	// and the node information atom container becomes the media sample data
	myErr = VRObject_CreateVRWorld(&myVRWorld, &myNodeInfo, kQTVRObjectType);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}
		
	if ((myVRWorld == NULL) || (myNodeInfo == NULL))
		goto bail;
	
	// create a QTVR sample description
	mySize = sizeof(QTVRSampleDescription) + GetHandleSize((Handle)myVRWorld) - sizeof(long);
	myQTVRDesc = (QTVRSampleDescriptionHandle)NewHandleClear(mySize);
	if (myQTVRDesc == NULL)
		goto bail;
		
	(**myQTVRDesc).descSize = mySize;
	(**myQTVRDesc).descType = kQTVRQTVRType;
	(**myQTVRDesc).reserved1 = 0;
	(**myQTVRDesc).reserved2 = 0;
	(**myQTVRDesc).dataRefIndex = 0;

	// copy the VR world atom container into the data field of the QTVR sample description
	BlockMove(*((Handle)myVRWorld), &((**myQTVRDesc).data), GetHandleSize((Handle)myVRWorld));
	
	// create the media sample
	BeginMediaEdits(myQTVRMedia);

	myErr = AddMediaSample(myQTVRMedia, (Handle)myNodeInfo, 0, GetHandleSize((Handle)myNodeInfo), myDuration, (SampleDescriptionHandle)myQTVRDesc, 1, 0, NULL);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}
	EndMediaEdits(myQTVRMedia);
	
	// add the media to the track
	InsertMediaIntoTrack(myQTVRTrack, 0, 0, myDuration, fixed1);
	
	//////////
	//
	// create an object track and add it to the movie
	//
	//////////
	
	// create object track and media
	myObjectTrack = NewMovieTrack(myObjMovie, myWidth, myHeight, 0);
	myObjectMedia = NewTrackMedia(myObjectTrack, kQTVRObjectType, myScale, NULL, 0);
	if ((myObjectTrack == NULL) || (myObjectMedia == NULL))
		goto bail;
	
	myErr = VRObject_CreateObjectTrack(mySrcMovie, myObjectTrack, myObjectMedia, maxFrames);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	//////////
	//
	// create track references from QTVR track to object track
	// and from the object track to the object image track
	//
	//////////
	
	if (myObjectTrack != NULL)
		AddTrackReference(myQTVRTrack, myObjectTrack, kQTVRObjectType, NULL);
		
	if (myImageTrack != NULL)
		AddTrackReference(myObjectTrack, myImageTrack, kQTVRImageTrackRefType, NULL);

	//////////
	//
	// add a user data item that identifies the QTVR movie controller
	//
	//////////
	
	myErr = VRObject_SetControllerType(myObjMovie, kQTVRQTVRType);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
	//////////
	//
	// add the movie resource to the object movie
	//
	//////////
	
	myErr = AddMovieResource(myObjMovie, myObjResRefNum, &myResID, NULL);
	
bail:
	if (mySampleDesc != NULL)
		DisposeHandle((Handle)mySampleDesc);
	
	if (myQTVRDesc != NULL)
		DisposeHandle((Handle)myQTVRDesc);
	
	if (myVRWorld != NULL)
		QTDisposeAtomContainer(myVRWorld);
		
	if (myNodeInfo != NULL)
		QTDisposeAtomContainer(myNodeInfo);

	if (myObjResRefNum != 0)
		CloseMovieFile(myObjResRefNum);
	
	if (myObjMovie != NULL)
		DisposeMovie(myObjMovie);
		
	if (mySrcResRefNum != 0)
		CloseMovieFile(mySrcResRefNum);
		
	if (mySrcMovie != NULL) 
		DisposeMovie(mySrcMovie);
		
	return(myErr);
}

//////////
//
// VRObject_MakeObjectMovie
// Create a single-node QuickTime VR object movie from the specified linear QuickTime movie file.
//
//////////

OSErr VRObject_MakeObjectMovie (FSSpec *theMovieSpec, FSSpec *theDestSpec, long maxFrames)
{
	FSSpec						myTempSpec;
	Movie						myTempMovie = NULL;
	Movie						myObjectMovie = NULL;
	short						myTempResRefNum = 0;
	OSErr						myErr = noErr;

	// create a temporary version of the object movie file,
	// located in the same directory as the destination object movie file;
	// to create a new file name, we'll just change the last character of the destination movie file name
	// (no doubt you could do a better job here!)
	myTempSpec = *theDestSpec;
	
	if (myTempSpec.name[myTempSpec.name[0]] == 't')
		myTempSpec.name[myTempSpec.name[0]] = '@';
	else
		myTempSpec.name[myTempSpec.name[0]] = 't';
	
	// create a single node object movie in the temp file
		myErr = VRObject_CreateQTVRMovieVers2x0(&myTempSpec, theMovieSpec, maxFrames);
		
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}
	// create the final, flattened movie
	myErr = OpenMovieFile(&myTempSpec, &myTempResRefNum, fsRdPerm);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}			
	myErr = NewMovieFromFile(&myTempMovie, myTempResRefNum, NULL, 0, 0, 0);
	if (myErr != noErr)
	{
		printf("quicktime error : %d", myErr);
		goto bail;
	}	
				
	// flatten the temporary file into a new movie file;
	// put the movie resource first so that FastStart is possible
	myObjectMovie = FlattenMovieData(myTempMovie, flattenDontInterleaveFlatten | flattenAddMovieToDataFork | flattenForceMovieResourceBeforeMovieData, theDestSpec, FOUR_CHAR_CODE('TVOD'), smSystemScript, createMovieFileDeleteCurFile | createMovieFileDontCreateResFile);

bail:	
	if (myObjectMovie != NULL)
		DisposeMovie(myObjectMovie);

	if (myTempMovie != NULL)
		DisposeMovie(myTempMovie);
		
	if (myTempResRefNum != 0)
		CloseMovieFile(myTempResRefNum);
		
	DeleteMovieFile(&myTempSpec);
					
	return(myErr);
}


//////////
//
// VRObject_ImportVideoTrack
// Copy a video track from one movie (the source) to another (the destination).
//
//////////

OSErr VRObject_ImportVideoTrack (Movie theSrcMovie, Movie theDstMovie, Track *theImageTrack)
{
	Track			mySrcTrack = NULL;
	Media			mySrcMedia = NULL;
	Track			myDstTrack = NULL;
	Media			myDstMedia = NULL;
	Fixed			myWidth, myHeight;
	OSType			myType;
	OSErr			myErr = noErr;
	
	ClearMoviesStickyError();
	
	// get the first video track in the source movie
	mySrcTrack = GetMovieIndTrackType(theSrcMovie, 1, VideoMediaType, movieTrackMediaType);
	if (mySrcTrack == NULL)
		return(paramErr);
	
	// get the track's media and dimensions	
	mySrcMedia = GetTrackMedia(mySrcTrack);
	GetTrackDimensions(mySrcTrack, &myWidth, &myHeight);
	
	// create a destination track
	myDstTrack = NewMovieTrack(theDstMovie, myWidth, myHeight, GetTrackVolume(mySrcTrack));

	// create a destination media
	GetMediaHandlerDescription(mySrcMedia, &myType, 0, 0);
	myDstMedia = NewTrackMedia(myDstTrack, myType, GetMediaTimeScale(mySrcMedia), 0, 0);
		
	// copy the entire track
	InsertTrackSegment(mySrcTrack, myDstTrack, 0, GetTrackDuration(mySrcTrack), 0);
	CopyTrackSettings(mySrcTrack, myDstTrack);
	SetTrackLayer(myDstTrack, GetTrackLayer(mySrcTrack));

	// an object video track should always be enabled
	SetTrackEnabled(myDstTrack, true);

	if (theImageTrack != NULL)
		*theImageTrack = myDstTrack;

	return(GetMoviesStickyError());
}


//////////
//
// VRObject_GetPanAndTiltFromTime
// Get the pan and tilt angles that correspond to the specified movie time.
//
//////////

OSErr VRObject_GetPanAndTiltFromTime (TimeValue theTime,
										TimeValue theFrameDuration,
										short theNumColumns,
										short theNumRows,
										short theLoopSize,
										Float32 theStartPan,
										Float32 theEndPan,
										Float32 theStartTilt,
										Float32 theEndTilt,
										Float32 *thePan, 
										Float32 *theTilt)
{
	short			myRow, myColumn;
	TimeValue		myTime;
	Float32			myPanRange;
	Float32			myTiltRange;
	OSErr			myErr = noErr;
	
	myPanRange = theEndPan - theStartPan;
	myTiltRange = theStartTilt - theEndTilt;

	theTime /= theFrameDuration;				// adjust for frame duration
	
	myTime = theTime / theLoopSize;
	myRow = myTime / theNumColumns;
	myColumn = myTime % theNumColumns;
	
	// note the mixed Float32 and integer math
	if (theNumColumns == 1)
		*thePan = theStartPan;
	else if (myPanRange == 360.0)
		*thePan = theStartPan + (myColumn * (myPanRange / (theNumColumns)));
	else
		*thePan = theStartPan + (myColumn * (myPanRange / (theNumColumns - 1)));
	
	if (theNumRows == 1)
		*theTilt = theStartTilt;
	else
		*theTilt = theStartTilt - (myRow * (myTiltRange / (theNumRows - 1)));
	
	return(myErr);
}


//////////
//
// VRObject_SetControllerType
// Set the controller type of the specified movie.
//
// This function adds an item to the movie's user data;
// the updated user data is written to the movie file when the movie is next updated
// (by calling AddMovieResource or UpdateMovieResource).
//
//////////

OSErr VRObject_SetControllerType (Movie theMovie, OSType theType)
{
	UserData		myUserData;
	OSErr			myErr = noErr;

	// make sure we've got a movie
	if (theMovie == NULL)
		return(paramErr);
		
	// get the movie's user data list
	myUserData = GetMovieUserData(theMovie);
	if (myUserData == NULL)
		return(paramErr);
	
	theType = EndianU32_NtoB(theType);
	myErr = SetUserDataItem(myUserData, &theType, sizeof(theType), kQTControllerType, 0);

	return(myErr);
}


//////////
//
// VRObject_AddStr255ToAtomContainer
// Add a Pascal string to the specified atom container; return (through theID) the ID of the new string atom.
//
//////////

OSErr VRObject_AddStr255ToAtomContainer (QTAtomContainer theContainer, QTAtom theParent, Str255 theString, QTAtomID *theID)
{
	OSErr					myErr = noErr;

	*theID = 0;				// initialize the returned atom ID
	
	if ((theContainer == NULL) || (theParent == 0))
		return(paramErr);
		
	if (theString[0] != 0) {
		QTAtom				myStringAtom;
		UInt16				mySize;
		QTVRStringAtomPtr	myStringAtomPtr = NULL;
		
		mySize = sizeof(QTVRStringAtom) - 4 + theString[0] + 1;
		myStringAtomPtr = (QTVRStringAtomPtr)NewPtrClear(mySize);
		
		if (myStringAtomPtr != NULL) {
			myStringAtomPtr->stringUsage = EndianU16_NtoB(1);
			myStringAtomPtr->stringLength = EndianU16_NtoB(theString[0]);
			BlockMove(theString + 1, myStringAtomPtr->theString, theString[0]);
			myStringAtomPtr->theString[theString[0]] = '\0';
			myErr = QTInsertChild(theContainer, theParent, kQTVRStringAtomType, 0, 0, mySize, (Ptr)myStringAtomPtr, &myStringAtom);
			DisposePtr((Ptr)myStringAtomPtr);
			
			if (myErr == noErr)
				QTGetAtomTypeAndID(theContainer, myStringAtom, NULL, theID);
		}
	}
	
	return(myErr);
}


//////////
//
// VRObject_ConvertFloatToBigEndian
// Convert the specified floating-point number to big-endian format.
//
//////////

void VRObject_ConvertFloatToBigEndian (float *theFloat)
{
	unsigned long		*myLongPtr;
	
	myLongPtr = (unsigned long *)theFloat;
	*myLongPtr = EndianU32_NtoB(*myLongPtr);
}
