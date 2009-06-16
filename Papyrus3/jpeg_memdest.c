#include <stdio.h>
#include <stdlib.h>

/* this is not a core library module, so it doesn't define JPEG_INTERNALS */

#include "jinclude8.h"
#include "jpeglib8.h"
#include "jerror8.h"

#include "jpeg_memdest.h"

/*
** init_destination: Initialize memory destination object.
** Called by jpeg_start_compress before any data is actually written.
**
** cinfo: (in/out) pointer to JPEG compression object
*/

METHODDEF(void)
init_destination (j_compress_ptr cinfo)
{
  mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;

  /* image buffer must be allocated before mem_dest routines are called.  */
  if(dest->buffer == NULL) {
    fprintf(stderr, "jmem_dest: init_destination: buffer not allocated\n");
    ERREXIT(cinfo, JERR_BUFFER_SIZE);
  }

  /* Initialize public members */

  /* Theoretically, the compression object could be re-used to
  ** compress multiple images, i.e. without calling jpeg_memory_dest for
  ** each image.  Therefore, the public buffer pointer and counter need
  ** to be reset in this method, which is called by jpeg_start_compress.
  ** Before jpeg_start_compress is called, the user is assumed to have
  ** re-loaded the memory block pointed to by the private member buffer.
  */

  /* next_output_bytes is set to point at the beginning of the
  ** destination image buffer.
  */
  dest->pub.next_output_byte = dest->buffer;

  /* free_in_buffer is set to the maximum size of the destination image
  ** buffer
  */
  dest->pub.free_in_buffer = dest->buffer_size;
}




/*
 * Empty the output buffer --- called whenever buffer fills up.
 *
 * In typical applications, this should write the entire output buffer
 * (ignoring the current state of next_output_byte & free_in_buffer),
 * reset the pointer & count to the start of the buffer, and return TRUE
 * indicating that the buffer has been dumped.
 *
 * In applications that need to be able to suspend compression due to output
 * overrun, a FALSE return indicates that the buffer cannot be emptied now.
 * In this situation, the compressor will return to its caller (possibly with
 * an indication that it has not accepted all the supplied scanlines).  The
 * application should resume compression after it has made more room in the
 * output buffer.  Note that there are substantial restrictions on the use of
 * suspension --- see the documentation.
 *
 * When suspending, the compressor will back up to a convenient restart point
 * (typically the start of the current MCU). next_output_byte & free_in_buffer
 * indicate where the restart point will be if the current call returns FALSE.
 * Data beyond this point will be regenerated after resumption, so do not
 * write it out when emptying the buffer externally.
 */

/* NOTE: the memory buffer should be large enough to handle the entire
** compressed image.  If empty_output_buffer is ever called, then it
** indicates an error condition, which is that the memory image buffer
** was too small to contain the compressed image.
*/
METHODDEF(boolean)
empty_output_buffer (j_compress_ptr cinfo)
{
  /*
  mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
  */

  fprintf(stderr,
          "jmem_dest: empty_output_buffer: buffer should not ever be full\n");

  ERREXIT(cinfo, JERR_BUFFER_SIZE);

  return FALSE;
}




/*
 * Terminate destination --- called by jpeg_finish_compress
 * after all data has been written.  Usually needs to flush buffer.
 *
 * NB: *not* called by jpeg_abort or jpeg_destroy; surrounding
 * application must deal with any cleanup that should happen even
 * for error exit.
 */

/* NOTE: term_destination doesn't really do anything for the memory
** buffer.  The data is handled by an external routine.
*/
METHODDEF(void)
term_destination (j_compress_ptr cinfo)
{
  mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
  dest->datacount = dest->buffer_size - dest->pub.free_in_buffer;
}

/* jpeg_memory_dest: Prepare for output to memory.
**
** cinfo: (in/out) pointer to compression object
** jfif_buffer: (in) compressed image buffer.
** buf_size: (in) size of jfif_buffer, in bytes.
**
** Note that the allocation and freeing of the image buffer has to be
** done OUTSIDE of the mem_dest routines.
**
** Note that the only access the user has to the private members,
** buffer and buffer_size, is through jpeg_memory_dest.
**
** Be sure to read the comments for init_destination.
*/

GLOBAL(void)
jpeg_memory_dest (j_compress_ptr cinfo, unsigned char *jfif_buffer,
                  int buf_size)
{
  mem_dest_ptr dest;

  if(jfif_buffer == NULL) {
    fprintf(stderr, "jpeg_memory_dest: memory buffer needs to be allocated\n");
    ERREXIT(cinfo, JERR_BUFFER_SIZE);
  }

  /* Allocate the destination object.
  ** -- Allocation lasts until the compression object is destroyed
  ** -- that is, when jpeg_destroy_compress is called.
  **
  ** This memory destination object can not be allocated per image
  ** (i.e., with JPOOL_IMAGE), because there are elements of this object
  ** which are not completed until jpeg_finish_compress is called
  ** (therefore the object must exist /after/ jpeg_finish_compress is
  ** called), but jpeg_finish_compresses would free memory associated
  ** with this structure if it were allocated per image.
   *
   * This makes it dangerous to use this manager and a different destination
   * manager serially with the same JPEG object, because their private object
   * sizes may be different.  Caveat programmer.
  */
  if (cinfo->dest == NULL) {    /* first time for this JPEG object? */
    cinfo->dest = (struct jpeg_destination_mgr *)
      (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
                                  (size_t) sizeof(mem_destination_mgr));
  }

  dest = (mem_dest_ptr) cinfo->dest;  /* for casting */

  /* Initialize method pointers */
  dest->pub.init_destination = init_destination;
  dest->pub.empty_output_buffer = empty_output_buffer;
  dest->pub.term_destination = term_destination;

  /* Initialize private member */
  dest->buffer = (JOCTET*)jfif_buffer;
  dest->buffer_size = buf_size;
}
