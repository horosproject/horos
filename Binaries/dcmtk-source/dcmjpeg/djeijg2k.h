
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
  DJCompressJP2K(const DJCodecParameter& cp, EJ_Mode mode, Uint8 quality, Uint8 bitsPerSample);

  /// destructor
  virtual ~DJCompressJP2K();

  virtual OFCondition encode(
    Uint16 columns,
    Uint16 rows,
    EP_Interpretation interpr,
    Uint16 samplesPerPixel,
    Uint8 *image_buffer,
    Uint8 *&to,
    Uint32 &length,
	Uint8 pixelRepresentation,
	double minUsed, double maxUsed);
	
 virtual OFCondition encode(
    Uint16 columns,
    Uint16 rows,
    EP_Interpretation interpr,
    Uint16 samplesPerPixel,
    Uint16 *image_buffer,
    Uint8 *&to,
    Uint32 &length,
	Uint8 pixelRepresentation,
	double minUsed, double maxUsed);

virtual OFCondition encode( 
  Uint16 columns,
  Uint16 rows,
  EP_Interpretation colorSpace,
  Uint16 samplesPerPixel,
  Uint8 * image_buffer,
  Uint8 * & to,
  Uint32 & length,
  Uint8 bitsAllocated,
  Uint8 pixelRepresentation,
  double minUsed, double maxUsed);
  
  
  /** returns the number of bytes per sample that will be expected when encoding.
   */
  virtual Uint16 bytesPerSample() const;

  /** returns the number of bits per sample that will be expected when encoding.
   */
  virtual Uint16 bitsPerSample() const;

private:

  /// private undefined copy constructor
  DJCompressJP2K(const DJCompressJP2K&);

  /// private undefined copy assignment operator
  DJCompressJP2K& operator=(const DJCompressJP2K&);

  /// codec parameters
  const DJCodecParameter *cparam;
  
  void findMinMax( int &_min, int &_max, char *bytes, long length, OFBool isSigned, int rows, int columns, int bitsAllocated);
  
  /// for lossy compression, defines compression quality factor
  Uint8 quality;
  Uint8 bitsPerSampleValue;

  /// enum for mode of operation (baseline, sequential, progressive etc.)
  EJ_Mode modeofOperation;
};

#endif
