#if BITS_IN_JSAMPLE == 8
#include "jinclude8.h"
#include "jpeglib8.h"
#include "jerror8.h"
#endif

#if BITS_IN_JSAMPLE == 12
#include "jinclude8.h"
#include "jpeglib8.h"
#include "jerror8.h"
#endif

#if BITS_IN_JSAMPLE == 16
#include "jinclude8.h"
#include "jpeglib8.h"
#include "jerror8.h"
#endif

EXTERN(void) jpeg_memory_src JPP((j_decompress_ptr cinfo, const JOCTET * buffer, size_t bufsize));
