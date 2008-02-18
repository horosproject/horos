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

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMSOPClassExtendedNegotiationUserInformationSubItem.h"


@implementation DCMSOPClassExtendedNegotiationUserInformationSubItem

+ (id)sopClassExtendedNegotiationUserInformationSubItemWithType:(unsigned char)aType length:(int)theLength  sopClassLength:(int)sopLength  sopClassUID:(NSString *)uid  info:(NSData *)data{
	return [[[DCMSOPClassExtendedNegotiationUserInformationSubItem alloc] initWithType:aType length:theLength  sopClassLength:sopLength  sopClassUID:uid  info:data] autorelease];
}

- (id)initWithType:(unsigned char)aType length:(int)theLength  sopClassLength:(int)sopLength  sopClassUID:(NSString *)uid  info:(NSData *)data{
	if (self = [super initWithType:aType length:theLength]) {
		sopClassUIDLength = sopLength;
		sopClassUID = [uid retain];
		info = [data retain];
	}
	return self;
}

- (void)dealloc{
	[info release];
	[sopClassUID release];
	[super dealloc];
}

-(int)sopClassUIDLength{
	return sopClassUIDLength;
}
- (NSString *) sopClassUID{
	return sopClassUID;
}
- (NSData *) info{
	return info;
}

@end
