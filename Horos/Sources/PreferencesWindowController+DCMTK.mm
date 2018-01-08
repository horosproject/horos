/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "PreferencesWindowController+DCMTK.h"
#import "CIADICOMField.h"

#include "osconfig.h"
#include "mdfconen.h"

#include "dcvrsl.h"
#include "ofcast.h"
#include "ofstd.h"
#include "dctk.h"
#include "dcuid.h"

#define INCLUDE_CSTDIO
#include "ofstdinc.h"


@implementation PreferencesWindowController (DCMTK)

- (NSArray*) prepareDICOMFieldsArrays
{
	DcmDictEntry* e = NULL;
	DcmDataDictionary& globalDataDict = dcmDataDict.wrlock();
	
	DcmDictEntryList list;
    DcmHashDictIterator iter(globalDataDict.normalBegin());
    for( int x = 0; x < globalDataDict.numberOfNormalTagEntries(); ++iter, x++)
    {
        if ((*iter)->getPrivateCreator() == NULL) // exclude private tags
        {
          e = new DcmDictEntry(*(*iter));
          list.insertAndReplace(e);
        }
    }
	
	NSMutableArray *DICOMFieldsArray = [NSMutableArray array];
	
    /* output the list contents */
    DcmDictEntryListIterator listIter(list.begin());
    DcmDictEntryListIterator listLast(list.end());
    for (; listIter != listLast; ++listIter)
    {
		e = *listIter;
		
		if( e->getGroup() > 0)
		{
//			NSString	*s = [NSString stringWithFormat:@"(0x%04x,0x%04x) %s", e->getGroup(), e->getElement(), e->getTagName()];
					
//			[DICOMFieldsTitlesArray addObject: s];
//			[DICOMFieldsArray addObject:[NSString stringWithFormat:@"%s",e->getTagName()]];
//			
//			[DICOMGroupsArray addObject:[NSNumber numberWithInt:e->getGroup()]];
			
			CIADICOMField *dicomField = [[CIADICOMField alloc] initWithGroup:e->getGroup() element:e->getElement() name:[NSString stringWithFormat:@"%s",e->getTagName()]];
			[DICOMFieldsArray addObject:dicomField];
			[dicomField release];
		}
    }
	
	dcmDataDict.unlock();
	
	return DICOMFieldsArray;
}


@end
