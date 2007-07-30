/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Foundation/Foundation.h>
#import <QuickTime/QuickTime.h>

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
	IBOutlet NSSlider		*rateSlider;
	IBOutlet NSTextField	*rateValue;
}

- (id) initWithSelector:(id) o :(SEL) s :(long) f;
//- (void) setCodec:(unsigned long) codec :(long) quality;
//- (NSString*) generateMovie :(BOOL) openIt :(BOOL) produceFiles :(NSString*) name;
- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name;
- (IBAction) setRate:(id) sender;
- (IBAction) changeExportType:(id) sender;
@end

