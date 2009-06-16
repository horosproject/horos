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

/* mem_destination_mgr: memory destination manager */


typedef struct {
  struct jpeg_destination_mgr pub; /* public fields */

  JOCTET * buffer;              /* image buffer */
  unsigned int buffer_size;     /* image buffer size */
  unsigned int datacount;
} mem_destination_mgr;




typedef mem_destination_mgr * mem_dest_ptr;




extern GLOBAL(void) jpeg_memory_dest (j_compress_ptr cinfo, unsigned char *jfif_buffer,  int buf_size);
