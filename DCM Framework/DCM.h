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


#import "OsiriX/DCMValueRepresentation.h"
#import "OsiriX/DCMAttributeTag.h"
#import "OsiriX/DCMAttribute.h"
#import "OsiriX/DCMSequenceAttribute.h"
#import "OsiriX/DCMDataContainer.h"
#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMTransferSyntax.h"
#import "OsiriX/DCMTagDictionary.h"
#import "OsiriX/DCMTagForNameDictionary.h"
#import "OsiriX/DCMCharacterSet.h"
#import "OsiriX/DCMPixelDataAttribute.h"
#import "OsiriX/DCMCalendarDate.h"

#import "DCMLimitedObject.h"

#import "DCMNetServiceDelegate.h"
#import "DCMEncapsulatedPDF.h"




#define DCMDEBUG 0
#define DCMFramework_compile YES



#import <Accelerate/Accelerate.h>

enum DCM_CompressionQuality {DCMLosslessQuality = 0, DCMHighQuality, DCMMediumQuality, DCMLowQuality};



@protocol MoveStatusProtocol
	- (void)setStatus:(unsigned short)moveStatus  numberSent:(int)numberSent numberError:(int)numberErrors;
@end


