//
//  DCMAssociationResponder.h
//  OsiriX
//
//  Created by Lance Pysher on 12/13/04.

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
#import "DCMAssociation.h"



@interface DCMAssociationResponder : DCMAssociation {

}

+ (id)associationResponderWithParameters:(NSDictionary *)params;
- (id)initWithParameters:(NSDictionary *)params;

- (NSArray *)applySelectionPolicies:(NSArray *)contexts;
- (NSArray *)applyAbstractSyntaxSelectionPolicy:(NSArray *)contexts;
- (NSArray *)applyTransferSyntaxSelectionPolicy:(NSArray *)contexts;
- (NSArray *)applyExplicitTransferSyntaxPreferencePolicy:(NSArray *)contexts;
- (NSArray *)sanitizePresentationContextsForAcceptance:(NSArray *)contexts;


@end
