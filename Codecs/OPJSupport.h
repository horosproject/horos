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