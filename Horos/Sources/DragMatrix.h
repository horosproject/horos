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


#import <AppKit/AppKit.h>

/*****************************************************************************/
/* DragMatrix */
 /** \brief  A matrix of image cells with reordering
 *
 * This calls allows you to create a matrix of image cells that can be
 * reordered (similar to object in an outline view).  To use this class
 * add it to your project.  In InterfaceBuilder create a matrix of
 * ImageViews.  In the properties pane go to custom class and set the class
 * to DragMatrix.  When a image is dragged this class sends a notification
 * "DragMatrixImageMoved".  The object is itself.  The user info contains
 * the following keys
 * 	- "images" = Selected DicomImages
 */
/*****************************************************************************/

@interface DragMatrix : NSMatrix {
    NSEvent * downEvent;
    NSRect oldDrawRect, newDrawRect;
    BOOL shouldDraw;
    IBOutlet id arrayController;
	NSArray *selection;
    NSInteger srcRow, srcCol, dstRow, dstCol;
} 
//- (void) setController:(id)controller;
// Private
- (NSEvent*) downEvent; 
- (void) setDownEvent:(NSEvent *)event; 
- (void) clearDragDestinationMembers;
-(NSArray *)selection;

@end

