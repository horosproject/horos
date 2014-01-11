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

@interface O2ViewerThumbnailsMatrix : NSMatrix {
    BOOL avoidRecursive;
    NSPoint draggingStartingPoint;
    NSTimeInterval doubleClick;
    NSCell *doubleClickCell;
}

@end

@interface O2ViewerThumbnailsMatrixRepresentedObject : NSObject {
    id _object;
    NSArray* _children;
}

@property(retain) id object;
@property(retain) NSArray* children;

+ (id)object:(id)object;
+ (id)object:(id)object children:(NSArray*)children;

@end