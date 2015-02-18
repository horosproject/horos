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



#import <Cocoa/Cocoa.h>

/** \brief Window Controller for Wait rendering */
@interface WaitRendering : NSWindowController
{
    IBOutlet NSProgressIndicator *progress;
	IBOutlet NSButton		     *abort;
	IBOutlet NSTextField		 *message, *currentTimeText, *lastTimeText;
	
	NSString					*string;
	NSTimeInterval				lastDuration, lastTimeFrame;
	NSDate						*startTime;
	
	BOOL						aborted;
	volatile BOOL				stop;
	BOOL						supportCancel;
	NSModalSession				session;
	
	id							cancelDelegate;
	
	NSTimeInterval				displayedTime;
	
	NSWindow					*sheetForWindow;
}

- (id) init:(NSString*) s;
- (BOOL) run;
- (void) start;
- (void) end;
- (IBAction) abort:(id) sender;
- (void) setCancel :(BOOL) val;
- (BOOL) aborted;
- (void) setString:(NSString*) str;
- (void) setCancelDelegate:(id) object;
- (void) resetLastDuration;
@end
