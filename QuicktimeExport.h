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




#import <Foundation/Foundation.h>
#import <QuickTime/QuickTime.h>


/** \brief QuickTime export */
@interface QuicktimeExport : NSObject {

	id						object;
	SEL						selector;
	long					numberOfFrames;
	unsigned long			codec;
	long					quality;
	
	NSSavePanel				*panel;
	NSArray					*exportTypes;
	
	IBOutlet NSView			*view;
	IBOutlet NSPopUpButton	*type;
}

+ (NSString*) generateQTVR:(NSString*) srcPath frames:(int) frames;
- (id) initWithSelector:(id) o :(SEL) s :(long) f;
- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name;
- (IBAction) changeExportType:(id) sender;
@end

