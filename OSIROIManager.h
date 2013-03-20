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

#import <Cocoa/Cocoa.h>

/**  
 
 The `OSIROIManager` class defines the interface to discover ROIs and filter for the ROIs of interest. After creating an instance of `OSIROIManager` a\
 client can use it to get an array of ROIs and can register itself as a delegate to recieve updates about the ROIs in the given `OSIVolumeWindow.
 
 */


// anyone who is interested in dealing with ROIs can create one of these and learn about what is going on with ROIs

// and OSIROIManager is meant to act as a filter, it will return ROIs

// what I want is an object that will give me a list of volume ROIs

extern const NSString *OSILineROIType;
//extern const NSString *OSI;

@class OSIStudy;
@class OSIROI;
@class OSIVolumeWindow;

/**  
 
 The `OSIROIManager` sends a `OSIROIManagerROIsDidUpdateNotification` whenever there is any change in the managed ROIs
 
 */

extern NSString* const OSIROIManagerROIsDidUpdateNotification; 

extern NSString* const OSIROIUpdatedROIKey;
extern NSString* const OSIROIRemovedROIKey;
extern NSString* const OSIROIAddedROIKey;

@protocol OSIROIManagerDelegate;


@interface OSIROIManager : NSObject {
	id <OSIROIManagerDelegate> _delegate;
	
	OSIVolumeWindow *_volumeWindow;
	BOOL _coalesceROIs;
	
    BOOL _allROIsLoaded;
    
	BOOL _rebuildingROIs;
	
    NSMutableArray *_addedOSIROIs;
	NSMutableArray *_OSIROIs;
    NSMutableSet *_watchedROIs; // the osirix ROIs that are backing the OSIROIs that are being managed. These are the ROIs that need to be watched, and the OSIROIs need to be updated when these change
}

///-----------------------------------
/// @name Accessing the Delegate
///-----------------------------------

/** The receiver’s delegate or nil if it doesn’t have a delegate.

 See OSIROIManagerDelegate Protocol Reference for the methods this delegate should implement.
 
 */
@property (nonatomic, readwrite, assign) id <OSIROIManagerDelegate> delegate;

/** The OSIVolumeWindow to which this ROIManager is attached.
  
 */
@property (nonatomic, readonly, retain) OSIVolumeWindow* volumeWindow;

///-----------------------------------
/// @name Creating ROI Managers
///-----------------------------------

/** Initializes and returns a newly created ROI Manager.
 
 This is a convenience method for initializing the receiver and not coalescing ROIs with the same name

 @return The initialized ROI Manager object or `nil` if there was a problem initializing the object.
 @param volumeWindow The Volume Window in which the ROI Manager will look for ROIs.
 @see initWithVolumeWindow:coalesceROIs:
 */
- (id)initWithVolumeWindow:(OSIVolumeWindow *)volumeWindow;

/** Initializes and returns a newly created ROI Manager.
 
 Initializes the newly created ROI Manager to look in volumeWindow for ROIs, and optionally coalesces ROI with the same name into a single volumetric ROI
 
 @return The initialized ROI Manager object or `nil` if there was a problem initializing the object.
 @param volumeWindow The Volume Window in which the ROI Manager will look for ROIs.
 @param coalesceROIs If this is YES, this ROI manager will coalesce all ROIs with the same name into a single volumetric ROI.
 @see initWithVolumeWindow:
 */
- (id)initWithVolumeWindow:(OSIVolumeWindow *)volumeWindow coalesceROIs:(BOOL)coalesceROIs; // if coalesceROIs is YES, ROIs with the same name will 


///-----------------------------------
/// @name Working witth ROIs
///-----------------------------------

/** Returns the array OSIROI objects the reciever is managing.
 
 @return The array OSIROI objects the reciever is managing.
 */
- (NSArray *)ROIs; // return OSIROIs observable

/** Returns the first ROI with a given name that would be in the ROI array.
 
 This is just a convenience method to access the first ROI with a given name returned by ROIs.

 @param name The name of the desired ROI.
 @see ROIs
 @see ROIsWithName:
 @return The first ROI with a given name that would be in the ROI array.
 */
- (OSIROI *)firstROIWithName:(NSString *)name; // convenience method to get the first ROI with a given name

/** Returns all the ROIs managed by the receiver that have the given name.
 
 This is just a convenience method to access the first ROI with a given name returned by ROIs.
 
 @param name The name of the desired ROIs
 @see ROIs
 @see firstROIWithName:
 @return Returns all the ROIs managed by the receiver that have the given name.
 */
- (NSArray *)ROIsWithName:(NSString *)name;

/** Returns the first ROI with a given name that would be in the ROI array and is currently visible to the user.
  
 @see ROIsWithName:
 @see firstROIWithName:
 @see firstVisibleROIWithNamePrefix:
 @return Returns all the ROIs managed by the receiver that have the given name.
 */
- (OSIROI *)firstVisibleROIWithName:(NSString *)name;

/** Returns the first ROI with a whose name starts wth `prefix` that would be in the ROI array and is currently visible to the user.
 
 @see ROIsWithName:
 @see firstROIWithName:
 @see firstVisibleROIWithNamePrefix:
 @return Returns all the ROIs managed by the receiver that have the given name.
 */
- (OSIROI *)firstVisibleROIWithNamePrefix:(NSString *)prefix;

/** Returns `NSString` objects representing the names of all the ROIs managed by the receiver.

@see ROIsWithName:
@see firstROIWithName:
@return Returns all the ROIs managed by the receiver that have the given name.
*/
- (NSArray *)ROINames; // returns all the unique ROI names

/** Returns YES if all the ROIs in the volume have been loaded. Returns NO DCM objects are still loading and there not all ROIs are available yet.
 Observable.
 
 @see ROIs
 @see viewerController
 */
- (BOOL)allROIsLoaded;

/** Add an OSIROI to the manager. This is useful to have the ROIManager handle drawing of the ROI.
 
 @see ROIs
 @see removeOSIROI:
 */
- (void)addROI:(OSIROI *)roi;

/** Remove an OSIROI that was added. This is useful to have the ROIManager handle drawing of the ROI.
 
 @see ROIs
 @see insertOSIROI:
 */
- (void)removeROI:(OSIROI *)roi;

// not done
//- (id)init; // look at all ROIS
//
//- (id)initWithStudy:(OSIStudy *)study; // if a study is specifed, only ROIs the manager will only look at ROIs in this study
//
//- (NSArray *)ROIsOfType:(NSString *)type;

@end

/**  
 
 The `OSIROIManagerDelegate` Protocol is to be implemented by the delegate of an OSIROIManager to be notified of changes in the managed ROIs.
 
 @warning *Important:* None of these methodes are implemented yet. Listen for the `OSIROIManagerROIsDidUpdateNotification` notification instead
 
 */


@protocol OSIROIManagerDelegate <NSObject>
@optional

/** Informs the delegate that `ROI` was added to the Volume Window.
 
 @param ROIManager the ROIManager that sent the message.
 @param ROI The ROI that was added.
 
 @warning *Important:* Not implemented yet. Listen for the `OSIROIManagerROIsDidUpdateNotification` notification instead

 */
- (void)ROIManager:(OSIROIManager *)ROIManager didAddROI:(OSIROI *)ROI;
/** Informs the delegate that `ROI` was removed to the Volume Window.
 
 @param ROIManager the ROIManager that sent the message.
 @param ROI The ROI that was removed.
 
 @warning *Important:* Not implemented yet. Listen for the `OSIROIManagerROIsDidUpdateNotification` notification instead
 */
- (void)ROIManager:(OSIROIManager *)ROIManager didRemoveROI:(OSIROI *)ROI;
/** Informs the delegate that `ROI` was modified.
 
 @param ROIManager the ROIManager that sent the message.
 @param ROI The ROI that was modified.
 
 @warning *Important:* Not implemented yet. Listen for the `OSIROIManagerROIsDidUpdateNotification` notification instead
 */
- (void)ROIManager:(OSIROIManager *)ROIManager didModifyROI:(OSIROI *)ROI;

@end

