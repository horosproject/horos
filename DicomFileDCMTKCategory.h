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

#import <Cocoa/Cocoa.h>
#import "dicomFile.h"

/** \brief  C++ calls for DicomFile 
*
*  Some C++ header from DCMTK and other C++ libs can conflict with Objective C during compilation.
*  Putting them in a separate category prevents compilation errors.
*/

@interface DicomFile (DicomFileDCMTKCategory)

+ (NSArray*) getEncodingArrayForFile: (NSString*) file;
+ (BOOL) isDICOMFileDCMTK:(NSString *) file; /**< Check for validity of DICOM using DCMTK */
+ (BOOL) isNRRDFile:(NSString *) file; /**< Test for NRRD file format */
+ (NSString*) getDicomField: (NSString*) field forFile: (NSString*) path;
+ (NSString*) getDicomFieldForGroup:(int) gr element: (int) el forDcmFileFormat: (void*) ff;

- (short) getDicomFileDCMTK; /**< Decode DICOM using DCMTK.  Returns 0 on success -1 on failure. */
- (short) getNRRDFile; /**< decode NRRD file format.  Returns 0 on success -1 on failure. */
@end
