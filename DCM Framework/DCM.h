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

#import "DCMDirectory.h"
#import "DCMRecord.h"
#import "DCMRootRecord.h"
#import "DCMPatientRecord.h"
#import "DCMStudyRecord.h"
#import "DCMSeriesRecord.h"
#import "DCMImageRecord.h"
#import "DCMLimitedObject.h"

#import "DCMNetServiceDelegate.h"
#import "DCMEncapsulatedPDF.h"




#define DCMDEBUG NO
#define DCMFramework_compile YES



#import <Accelerate/Accelerate.h>

enum DCM_CompressionQuality {DCMLosslessQuality, DCMHighQuality, DCMMediumQuality, DCMLowQuality};



@protocol MoveStatusProtocol
	- (void)setStatus:(unsigned short)moveStatus  numberSent:(int)numberSent numberError:(int)numberErrors;
@end


