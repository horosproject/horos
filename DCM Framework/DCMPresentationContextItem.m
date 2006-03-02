//
//  DCMPresentationContextItem.m
//  OsiriX
//
//  Created by Lance Pysher on 12/2/04.

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
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMPresentationContextItem.h"
#import "DCMPresentationContext.h"


@implementation DCMPresentationContextItem

+ (id)presentationContextItemWithType:(unsigned char)aType length:(int)theLength presentationContext:(DCMPresentationContext *)theContext{
	return [[[DCMPresentationContextItem alloc] initWithType:aType length:theLength presentationContext:theContext] autorelease];
}

+ (id)presentationContextItemWithType:(unsigned char)aType length:(int)theLength contextID:(unsigned char)contextID  reason:(unsigned char)reason{
	return [[[DCMPresentationContextItem alloc] initWithType:aType length:theLength contextID:contextID  reason:reason]  autorelease];
}

- (id)initWithType:(unsigned char)aType length:(int)theLength contextID:(unsigned char)contextID  reason:(unsigned char)reason{
	if (self = [super initWithType:aType length:theLength]){
		context = [[DCMPresentationContext alloc]initWithID:contextID];
		[context setReason:reason];
	}
	return self;
}

- (id)initWithType:(unsigned char)aType length:(int)theLength presentationContext:(DCMPresentationContext *)theContext{
	if (self = [super initWithType:aType length:theLength]){
		context = [theContext retain];
	}
	return self;
}
	

- (void)dealloc{
	[context release];
	[super dealloc];
}

- (DCMPresentationContext *)context{
	return context;
}

@end
