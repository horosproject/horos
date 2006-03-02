//
//  DCMNCreateRequest.h
//  OsiriX
//
//  Created by Lance Pysher on 9/2/05.

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
#import "DCMCommandMessage.h"


@interface DCMNCreateRequest : DCMCommandMessage {

}
+ (NSString *)newUID;
+ (id) filmSessionInColor:(BOOL)isColor;
+ (id) filmBox;

+ (id)nCreateRequestWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		hasDataset:(BOOL)hasDataset;

- (id)initWithSopClassUID:(NSString *)sopClassUID 
		sopInstanceUID:(NSString *)sopInstanceUID 
		hasDataset:(BOOL)hasDataset;
		

@end
