/*=========================================================================
 Copyright (c) Pixmeo SARL
 All rights reserved.
 =========================================================================*/

#ifdef __cplusplus
#define EXTERNC extern "C" 
#else
#define EXTERNC 
#endif

EXTERNC int kdu_available();
EXTERNC void* kdu_decompressJPEG2K( void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel, int num_threads);
EXTERNC void* kdu_decompressJPEG2KWithBuffer( void* inputBuffer, void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int *colorModel, int num_threads);
EXTERNC void* kdu_compressJPEG2K( void *data, int samplesPerPixel, int rows, int columns, int precision, bool sign, int rate, long *compressedDataSize, int num_threads);