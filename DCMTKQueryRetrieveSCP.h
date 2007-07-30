//
//  DCMTKQueryRetrieveSCP.h
//  OsiriX
//
//  Created by Lance Pysher on 3/16/06.

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

#import <Cocoa/Cocoa.h>


@interface DCMTKQueryRetrieveSCP : NSObject {
	int _port;
	NSString *_aeTitle;
	NSDictionary *_params;
	BOOL _abort;
}

- (id)initWithPort:(int)port aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params;
- (void)run;
-(void)abort;
//- (void)cleanup:(NSTimer *)timer;

@end
