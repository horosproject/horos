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

/** A structure used to describe a single run length of a mask.
 
 */

struct OSIROIMaskRun {
	NSRange widthRange;
    NSUInteger heightIndex;
    NSUInteger depthIndex;
};
typedef struct OSIROIMaskRun OSIROIMaskRun;

/** A structure used to describe a single point in a mask.
 
 */

struct OSIROIMaskIndex {
	NSUInteger x;
	NSUInteger y;
	NSUInteger z;
};
typedef struct OSIROIMaskIndex OSIROIMaskIndex;

CF_EXTERN_C_BEGIN

/** Returns YES if the `maskIndex` is withing the `maskRun`
 
 */
BOOL OSIROIMaskIndexInRun(OSIROIMaskIndex maskIndex, OSIROIMaskRun maskRun);
/** Returns an array of all the OSIROIMaskIndex structs in the `maskRun` 
 
 */
NSArray *OSIROIMaskIndexesInRun(OSIROIMaskRun maskRun); // should this be a function, or a static method on OSIROIMask?

CF_EXTERN_C_END

// masks are stored in width direction run lengths

/** `OSIROIMask` instances represent a mask that can be applied to a volume. The Mask itself is stored as a set of individual mask runs.
 
 Stored masks use the following structs.
 
 `test`
 
 
 
 `struct OSIROIMaskRun {`
 
 `NSRange widthRange;`
 
 `NSUInteger heightIndex;`
 
 `NSUInteger depthIndex;`
 
 `};`
 
 `typedef struct OSIROIMaskRun OSIROIMaskRun;`
 
 `struct OSIROIMaskIndex {`
 
 `NSUInteger x;`
 
 `NSUInteger y;`
 
 `NSUInteger z;`
 
 `};`
 
 `typedef struct OSIROIMaskIndex OSIROIMaskIndex;`
 
 Use the following functions are also available
 
 `BOOL OSIROIMaskIndexInRun(OSIROIMaskIndex maskIndex, OSIROIMaskRun maskRun);`
 
 `NSArray *OSIROIMaskIndexesInRun(OSIROIMaskRun maskRun);`
 
 
 
 
 */


@interface OSIROIMask : NSObject {
	NSArray *_maskRuns;
}

///-----------------------------------
/// @name Creating ROI Masks
///-----------------------------------


// create the thing, maybe we should really be working with C arrays.... or at least give the option
/** Initializes and returns a newly created ROI Mask.
 
 Creates a ROI Mask based on the given individual runs.
 
 @return The initialized ROI Mask object or `nil` if there was a problem initializing the object.
 @param maskRuns An array of OSIROIMaskRun structs in NSValues.
 */
- (id)initWithMaskRuns:(NSArray *)maskRuns;

///-----------------------------------
/// @name Working with the Mask
///-----------------------------------

/** Returns the mask as a set ofOSIROIMaskRun structs in NSValues.
 
 @return The mask as a set ofOSIROIMaskRun structs in NSValues.
 */
- (NSArray *)maskRuns;

/** Returns the mask as a set OSIROIMaskIndex structs in NSValues.
 
 @return The mask as a set OSIROIMaskIndex structs in NSValues.
 */
- (NSArray *)maskIndexes;

/** Returns YES if the given index is within the mask.
 
 @return YES if the given index is within the mask.
 
 @param index OSIROIMaskIndex struct to test.
 */
- (BOOL)indexInMask:(OSIROIMaskIndex)index;

@end

/** NSValue methods to handle Mask types.
 
 */


@interface NSValue (OSIROIMaskRun)

///-----------------------------------
/// @name OSIROIMaskRun methods
///-----------------------------------

/** Creates and returns an NSValue object that contains a given OSIROIMaskRun structure.
 
 @return A new NSValue object that contains the value of volumeRun.
 @param volumeRun The value for the new object.
 */
+ (NSValue *)valueWithOSIROIMaskRun:(OSIROIMaskRun)volumeRun;

/** Returns an OSIROIMaskRun structure representation of the receiver.
 
 @return An OSIROIMaskRun structure representation of the receiver.
 */
- (OSIROIMaskRun)OSIROIMaskRunValue;

/** Creates and returns an NSValue object that contains a given OSIROIMaskIndex structure.
 
 @return A new NSValue object that contains the value of maskIndex.
 @param maskIndex The value for the new object.
 */
+ (NSValue *)valueWithOSIROIMaskIndex:(OSIROIMaskIndex)maskIndex;

/** Returns an OSIROIMaskIndex structure representation of the receiver.
 
 @return An OSIROIMaskIndex structure representation of the receiver.
 */
- (OSIROIMaskIndex)OSIROIMaskIndexValue;
@end


