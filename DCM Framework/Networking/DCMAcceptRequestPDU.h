//
//  DCMAcceptRequestPDU.h
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


#import <Cocoa/Cocoa.h>
#import "DCM_PDU.h"

@class DCMPresentationContext;
@interface DCMAcceptRequestPDU : DCM_PDU {

	NSString *calledAET;
	NSString *callingAET;
	NSString *implementationClassUID;
	NSString *implementationVersionName;
	int maximumLengthReceived;	//the maximum PDU length that we will offer to receive
	NSArray *presentationContexts;
	int protocolVersion;
	NSMutableArray *itemList;

}

@property(readonly) NSString *calledAET;
@property(readonly) NSString *callingAET;
@property(readonly) int maximumLengthReceived;

- (id)initWithParameters:(NSDictionary *)params;
- (id)initWithData:(NSMutableData *)data;
- (NSMutableData *)dataForAET:(NSString *)aet withName:(NSString *)name;
- (NSMutableData *)dataForSyntaxSubItem:(unsigned char)subItemType  name:(NSString *)name;
- (NSMutableData *)dataForPresentationContext:(DCMPresentationContext *)context ofType:(unsigned char)type;
- (NSArray *)acceptedPresentationContextsWithAbstractSyntaxIncludedFromRequest:(NSArray *)request;
- (NSArray *)requestedPresentationContexts;




@end
