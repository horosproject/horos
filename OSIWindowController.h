/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

/** \brief base class for Window Controllers in OsiriX
*
*Root class for the Viewer Window Controllers such as ViewerController
*and Window3DController
*/

#import <Cocoa/Cocoa.h>
@class DicomDatabase;


enum OsiriXBlendingTypes {BlendingPlugin = -1, BlendingFusion = 1, BlendingSubtraction, BlendingMultiplication, BlendingRed, BlendingGreen, BlendingBlue, Blending2DRegistration, Blending3DRegistration, BlendingLL};

#ifdef id
#define redefineID
#undef id
#endif

@class DicomImage, DicomSeries, DicomStudy;

@interface OSIWindowController : NSWindowController
{
	int _blendingType;
	
	BOOL magneticWindowActivated;
	BOOL windowIsMovedByTheUserO;
	NSRect savedWindowsFrameO;
	
	DicomDatabase* _database;
}

@property(nonatomic,retain) DicomDatabase* database;
-(void)refreshDatabase:(NSArray*)newImages;

+ (BOOL) dontWindowDidChangeScreen;
+ (void) setDontEnterWindowDidChangeScreen:(BOOL) a;
+ (void) setDontEnterMagneticFunctions:(BOOL) a;
- (void) setMagnetic:(BOOL) a;
- (BOOL) magnetic;

- (NSMutableArray*) pixList;
- (void) addToUndoQueue:(NSString*) what;
- (int)blendingType;

- (IBAction) redo:(id) sender;
- (IBAction) undo:(id) sender;

- (IBAction) applyShading:(id) sender;
- (void) updateAutoAdjustPrinting: (id) sender;

#pragma mark-
#pragma mark current Core Data Objects
- (DicomStudy *)currentStudy;
- (DicomSeries *)currentSeries;
- (DicomImage *)currentImage;

- (float)curWW;
- (float)curWL;
@end

#ifdef redefineID
#define id Id
#undef redefineID
#endif
