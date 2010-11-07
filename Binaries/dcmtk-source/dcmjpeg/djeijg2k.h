
#ifndef DJEIJG2K_H
#define DJEIJG2K_H

#include "osconfig.h"
#include "oflist.h"
#include "djencabs.h"

class DJCodecParameter;


class DJCompressJP2K: public DJEncoder
{
public:

  /** constructor for lossy JPEG
   *  @param cp codec parameters
   *  @param mode mode of operation
   *  @param quality compression quality
   */
  DJCompressJP2K(const DJCodecParameter& cp, EJ_Mode mode, Uint8 quality, Uint8 bitsAllocated);

  /// destructor
  virtual ~DJCompressJP2K();

  /** single frame compression routine for 16-bit raw pixel data.
   *  May only be called if bytesPerSample() == 2.
   *  @param columns columns of frame
   *  @param rows rows of frame
   *  @param interpr photometric interpretation of input frame
   *  @param samplesPerPixel samples per pixel of input frame
   *  @param image_buffer pointer to frame buffer
   *  @param to compressed frame returned in this parameter upon success
   *  @param length length of compressed frame (in bytes) returned in this parameter
   *    upon success; length guaranteed to be always even.
   *  @return EC_Normal if successful, an error code otherwise.
   */
  virtual OFCondition encode(
    Uint16 columns,
    Uint16 rows,
    EP_Interpretation interpr,
    Uint16 samplesPerPixel,
    Uint16 *image_buffer,
    Uint8 *&to,
    Uint32 &length);

  virtual OFCondition encode(
    Uint16 columns,
    Uint16 rows,
    EP_Interpretation interpr,
    Uint16 samplesPerPixel,
    Uint8 *image_buffer,
    Uint8 *&to,
    Uint32 &length);

  /** returns the number of bytes per sample that will be expected when encoding.
   */
  virtual Uint16 bytesPerSample() const { return 2; }

  /** returns the number of bits per sample that will be expected when encoding.
   */
  virtual Uint16 bitsPerSample() const { return 12; }

  /** callback for IJG compress destination manager.
   *  Internal use only, not to be called by client code.
   *  @param cinfo pointer to compress info
   */
//  void initDestination(jpeg_compress_struct *cinfo);

  /** callback for IJG compress destination manager.
   *  Internal use only, not to be called by client code.
   *  @param cinfo pointer to compress info
   */
//  int emptyOutputBuffer(jpeg_compress_struct *cinfo);

  /** callback for IJG compress destination manager.
   *  Internal use only, not to be called by client code.
   *  @param cinfo pointer to compress info
   */
//  void termDestination(jpeg_compress_struct *cinfo);
  	
  /** callback function used to report warning messages and the like.
   *  Should not be called by user code directly.
   *  @param arg opaque pointer to JPEG compress structure
   */
//  virtual void outputMessage(void *arg) const;

private:

  /// private undefined copy constructor
  DJCompressJP2K(const DJCompressJP2K&);

  /// private undefined copy assignment operator
  DJCompressJP2K& operator=(const DJCompressJP2K&);

  /// cleans up pixelDataList, called from destructor and error handlers
  void cleanup();

  /// codec parameters
  const DJCodecParameter *cparam;
  
  /// for lossy compression, defines compression quality factor
  Uint8 quality;
  Uint8 bitsAllocated;

  /// enum for mode of operation (baseline, sequential, progressive etc.)
  EJ_Mode modeofOperation;

  /// list of compressed pixel data blocks  
  OFList<unsigned char *> pixelDataList;

  /// filled number of bytes in last block in pixelDataList
  size_t bytesInLastBlock;

};

#endif
