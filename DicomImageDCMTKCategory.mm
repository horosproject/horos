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
