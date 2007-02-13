//
//  LogManager.h
//  OsiriX
//
//  Created by Lance Pysher on 4/21/06.
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

#import <Cocoa/Cocoa.h>


@interface LogManager : NSObject {
	NSTimer *_timer;
	NSMutableDictionary *_currentLogs;
}

+ (id)currentLogManager;
- (void)checkLogs:(NSTimer *)timer;
- (NSString *)logFolder;
- (void) resetLogs;

@end
