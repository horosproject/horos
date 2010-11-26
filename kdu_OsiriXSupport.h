/*
 *  kdu_OsiriXSupport.h
 *  OsiriX
 *
 */

extern "C" int kdu_available();
extern "C" void* kdu_decompressJPEG2K( void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int num_threads);
extern "C" void* kdu_decompressJPEG2KWithBuffer( void* inputBuffer, void* jp2Data, long jp2DataSize, long *decompressedBufferSize, int num_threads);
extern "C" void* kdu_compressJPEG2K( void *data, int samplesPerPixel, int rows, int columns, int precision, bool sign, int rate, long *compressedDataSize, int num_threads);