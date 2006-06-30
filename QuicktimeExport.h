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




#import <Foundation/Foundation.h>
#import <QuickTime/QuickTime.h>

@interface QuicktimeExport : NSObject {

	id				object;
	SEL				selector;
	long			numberOfFrames;
	unsigned long   codec;
	long			quality;
}

- (id) initWithSelector:(id) o :(SEL) s :(long) f;
- (void) setCodec:(unsigned long) codec :(long) quality;
- (NSString*) generateMovie :(BOOL) openIt :(BOOL) produceFiles :(NSString*) name;
- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name;
@end

