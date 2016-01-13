/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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

#import "DicomImageDCMTKCategory.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"
#include "dsrtypes.h"
#include "dsrimgtn.h"

@implementation DicomImage(DicomImageDCMTKCategory)

- (NSString*) keyObjectType
{
	NSString *type = nil;
	DcmFileFormat fileformat;
	DSRDocument *doc = new DSRDocument();
	OFCondition status = fileformat.loadFile([[self completePath] UTF8String]);
	if (status.good())
		status = doc->read(*fileformat.getDataset());
	if (status.good())
	{
		OFString codeMeaning = doc->getTree().getCurrentContentItem().getConceptName().getCodeMeaning();
		type = [NSString stringWithUTF8String:codeMeaning.c_str()];
	}
	delete doc;
	return type;
}

- (NSArray*) referencedObjects
{
	NSMutableArray *references = [NSMutableArray array];
	DcmFileFormat fileformat;
	DSRDocument *doc = new DSRDocument();
	OFCondition status = fileformat.loadFile([[self completePath] UTF8String]);
	if (status.good())
		status = doc->read(*fileformat.getDataset());
	if (status.good())
	{
		DSRDocumentTreeNode *node = NULL; 
		//DSRDocumentTree  *tree = doc->getTree();
		/* iterate over all nodes */ 
        do { 
            node = OFstatic_cast(DSRDocumentTreeNode *, doc->getTree().getNode()); 
            if (node->getValueType() == DSRTypes::VT_Image)
			{
				//image node get SOPCInstance
				DSRImageTreeNode *imageNode = OFstatic_cast(DSRImageTreeNode *, node);
				OFString sopInstance = imageNode->getSOPInstanceUID();
				NSString *uid = [NSString stringWithUTF8String:sopInstance.c_str()];
				if (uid)
					[references addObject:uid];
			}
        } while (doc->getTree().iterate()); 
	}
	delete doc;
	return references;
}



@end
