//
//  DicomImageDCMTKCategory.mm
//  OsiriX
//
//  Created by Lance Pysher on 7/5/06.

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

#import "DicomImageDCMTKCategory.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"


@implementation DicomImage(DicomImageDCMTKCategory)

- (NSString *)keyObjectType{
	NSString *type = nil;
	DcmFileFormat fileformat;
	DSRDocument *doc = new DSRDocument();
	OFCondition status = fileformat.loadFile([[self completePath] UTF8String]);
	if (status.good())
		status = doc->read(*fileformat.getDataset());
	if (status.good()){
		OFString codeMeaning = doc->getTree().getCurrentContentItem().getConceptName().getCodeMeaning();
		type = [NSString stringWithUTF8String:codeMeaning.c_str()];
	}
	delete doc;
	return type;
}
- (NSArray *)referencedObjects{
	NSArray *references = nil;
	DcmFileFormat fileformat;
	DSRDocument *doc = new DSRDocument();
	OFCondition status = fileformat.loadFile([[self completePath] UTF8String]);
	if (status.good())
		status = doc->read(*fileformat.getDataset());
	if (status.good()){
		//go down one level from root. Can have descrption or referenced objects
		doc->getTree().goDown();
		
		//get referenced images
	}
	delete doc;
	return references;
}



@end
