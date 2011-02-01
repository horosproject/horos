/*
 *  kdu_OsiriXSupport.cpp
 *  OsiriX
 *
 */

#include "kdu_OsiriXSupport.h"

extern "C" int kdu_available()
{
	return 0;
}

extern "C" void* kdu_decompressJPEG2K( void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel, int num_threads)
{
	return 0L;
}

extern "C" void* kdu_decompressJPEG2KWithBuffer( void* inputBuffer, void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel, int num_threads)
{
	return 0L;
}

extern "C" void* kdu_compressJPEG2K( void *data, int samplesPerPixel, int rows, int columns, int precision, bool sign, int rate, long *compressedDataSize, int num_threads)
{
	return 0L;
}
