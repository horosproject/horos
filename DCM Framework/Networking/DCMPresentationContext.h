//
//  DCMPresentationContext.h
//  OsiriX
//
//  Created by Lance Pysher on 11/28/04.

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


#import <Cocoa/Cocoa.h>

@class DCMTransferSyntax;

@interface DCMPresentationContext : NSObject {
	unsigned char contextID;
	NSMutableArray *transferSyntaxes;
	NSString *abstractSyntax;
	unsigned char reason;

}
+ (id)contextWithID:(unsigned char)theID;
- (id)initWithID:(unsigned char)theID;
- (unsigned char)contextID;
- (NSMutableArray *)transferSyntaxes;
- (void)setTransferSyntaxes:(NSMutableArray *)syntaxes;
- (void)addTransferSyntax:(DCMTransferSyntax *)syntax;
- (void)setAbstractSyntax:(NSString *)syntax;
- (NSString *)abstractSyntax;
- (unsigned char)reason;
- (void)setReason:(unsigned char)value;

@end
