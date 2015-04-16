/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <Foundation/Foundation.h>



@interface DCMTransferSyntax : NSObject {

NSString	*transferSyntax;
BOOL		isEncapsulated;
BOOL		isLittleEndian;
BOOL		isExplicit;
NSString	*name;
NSMutableDictionary *transferSyntaxDict;

}
@property(readonly) NSString *transferSyntax;
@property(readonly) NSString *name;
@property(readonly )BOOL isEncapsulated;
@property(readonly) BOOL isLittleEndian;
@property(readonly) BOOL isExplicit;

+(id)ExplicitVRLittleEndianTransferSyntax;
+(id)ImplicitVRLittleEndianTransferSyntax;
+(id)ExplicitVRBigEndianTransferSyntax;

+(id)JPEG2000LosslessTransferSyntax;
+(id)JPEG2000LossyTransferSyntax;
+(id)JPEGBaselineTransferSyntax;
+(id)JPEGExtendedTransferSyntax;
+(id)JPEGLosslessTransferSyntax;
+(id)JPEGLossless14TransferSyntax;
+(id)JPEGLSLosslessTransferSyntax;
+(id)JPEGLSLossyTransferSyntax;
+(id)RLELosslessTransferSyntax;

- (id)initWithTS:(NSString *)ts;
- (id)initWithTS:(NSString *)ts isEncapsulated:(BOOL)encapsulated  isLittleEndian:(BOOL)endian  isExplicit:(BOOL)explicitValue name:(NSString *)aName;
- (id)initWithTransferSyntax:(DCMTransferSyntax *)ts;


- (BOOL)isEqualToTransferSyntax:(DCMTransferSyntax *)ts;

@end
