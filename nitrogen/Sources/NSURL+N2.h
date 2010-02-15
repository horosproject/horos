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


@interface N2URLParts : NSObject {
	NSString *_protocol, *_address, *_port, *_path, *_params;
}

@property(retain) NSString *protocol, *address, *port, *path, *params;
@property(readonly) NSString* pathAndParams;

@end


@interface NSURL (N2)

-(N2URLParts*)parts;
+(NSURL*)URLWithParts:(N2URLParts*)parts;

@end
