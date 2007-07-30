//
//  DCMPresentationContext.m
//  OsiriX
//
//  Created by Lance Pysher on 11/28/04.

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
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMPresentationContext.h"
#import "DCM.h"


@implementation DCMPresentationContext

 + (id)contextWithID:(unsigned char)theID{
	return [[[DCMPresentationContext alloc] initWithID:theID] autorelease];
}

- (id)initWithID:(unsigned char)theID{
	if (self = [super init])
		contextID = theID;
		transferSyntaxes = [[NSMutableArray array] retain];
		abstractSyntax = nil;
		
	return self;
}

- (void)dealloc{
	[transferSyntaxes release];
	[abstractSyntax release];
	[super dealloc];
}

- (unsigned char)contextID{
	return contextID;
}


- (NSMutableArray *)transferSyntaxes{
	return transferSyntaxes;
}

- (NSString *)abstractSyntax{
	return abstractSyntax;
}

- (void)setTransferSyntaxes:(NSMutableArray *)syntaxes{
	[transferSyntaxes release];
	transferSyntaxes = [syntaxes retain];
}

- (void)addTransferSyntax:(DCMTransferSyntax *)syntax{
	[transferSyntaxes addObject:syntax];
}

- (void)setAbstractSyntax:(NSString *)syntax{
	[abstractSyntax release];
	abstractSyntax = [syntax retain];
}

- (unsigned char)reason{
	return reason;
}

- (void)setReason:(unsigned char)value{
	reason = value;
}

- (NSString *)description{
	return [NSString stringWithFormat:@"Presentation Context\nid:%d\ntransferSyntaxes:%@\nAbstractSyntax:%@\nReason0x%x",
										contextID, [transferSyntaxes description], abstractSyntax, reason];
}

@end
