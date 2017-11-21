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
//
//  OPJSupport.h
//  OsiriX_Lion
//
//  Created by Aaron Boxer on 1/21/14.
//

#ifndef __OsiriX_Lion__OPJSupport__
#define __OsiriX_Lion__OPJSupport__

#include <iostream>
#include "options.h"

class OPJSupport {
    
public:
    OPJSupport();
    ~OPJSupport();
    
    void* decompressJPEG2K( void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel);
    void* decompressJPEG2KWithBuffer( void* inputBuffer, void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel);
    
    unsigned char *compressJPEG2K(   void *data,
                                  int samplesPerPixel,
                                  int rows,
                                  int columns,
                                  int bitsstored, //precision,
                                  unsigned char bitsAllocated,
                                  bool sign,
                                  int rate,
                                  long *compressedDataSize);
};

#endif /* defined(__OsiriX_Lion__OPJSupport__) */