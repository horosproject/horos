/*
 *
 *  Copyright (C) 1994-2005, OFFIS
 *
 *  This software and supporting documentation were developed by
 *
 *    Kuratorium OFFIS e.V.
 *    Healthcare Information and Communication Systems
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *  THIS SOFTWARE IS MADE AVAILABLE,  AS IS,  AND OFFIS MAKES NO  WARRANTY
 *  REGARDING  THE  SOFTWARE,  ITS  PERFORMANCE,  ITS  MERCHANTABILITY  OR
 *  FITNESS FOR ANY PARTICULAR USE, FREEDOM FROM ANY COMPUTER DISEASES  OR
 *  ITS CONFORMITY TO ANY SPECIFICATION. THE ENTIRE RISK AS TO QUALITY AND
 *  PERFORMANCE OF THE SOFTWARE IS WITH THE USER.
 *
 *  Module:  dcmdata
 *
 *  Author:  Marco Eichelberg
 *
 *  Purpose: decoder codec class for RLE
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:22 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmdata/dcrleccd.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#include "osconfig.h"
#include "dcrleccd.h"

// dcmdata includes
#include "dcrlecp.h"   /* for class DcmRLECodecParameter */
#include "dcrledec.h"  /* for class DcmRLEDecoder */
#include "dcdatset.h"  /* for class DcmDataset */
#include "dcdeftag.h"  /* for tag constants */
#include "dcpixseq.h"  /* for class DcmPixelSequence */
#include "dcpxitem.h"  /* for class DcmPixelItem */
#include "dcvrpobw.h"  /* for class DcmPolymorphOBOW */
#include "dcswap.h"    /* for swapIfNecessary() */
#include "dcuid.h"     /* for dcmGenerateUniqueIdentifer()*/


DcmRLECodecDecoder::DcmRLECodecDecoder()
: DcmCodec()
{
}


DcmRLECodecDecoder::~DcmRLECodecDecoder()
{
}


OFBool DcmRLECodecDecoder::canChangeCoding(
    const E_TransferSyntax oldRepType,
    const E_TransferSyntax newRepType) const
{
  E_TransferSyntax myXfer = EXS_RLELossless;
  DcmXfer newRep(newRepType);
  if (newRep.isNotEncapsulated() && (oldRepType == myXfer)) return OFTrue; // decompress requested

  // we don't support re-coding for now.
  return OFFalse;
}


OFCondition DcmRLECodecDecoder::decode(
    const DcmRepresentationParameter * /* fromRepParam */,
    DcmPixelSequence * pixSeq,
    DcmPolymorphOBOW& uncompressedPixelData,
    const DcmCodecParameter * cp,
    const DcmStack& objStack) const
{
  OFCondition result = EC_Normal;

  // assume we can cast the codec parameter to what we need
  const DcmRLECodecParameter *djcp = OFstatic_cast(const DcmRLECodecParameter *, cp);

  OFBool enableReverseByteOrder = djcp->getReverseDecompressionByteOrder();

  DcmStack localStack(objStack);
  (void)localStack.pop();             // pop pixel data element from stack
  DcmObject *dataset = localStack.pop(); // this is the item in which the pixel data is located
  if ((!dataset)||((dataset->ident()!= EVR_dataset) && (dataset->ident()!= EVR_item))) result = EC_InvalidTag;
  else
  {
    Uint16 imageSamplesPerPixel = 0;
    Uint16 imageRows = 0;
    Uint16 imageColumns = 0;
    Sint32 imageFrames = 1;
    Uint16 imageBitsAllocated = 0;
    Uint16 imageBytesAllocated = 0;
    Uint16 imagePlanarConfiguration = 0;
    Uint32 rleHeader[16];
    DcmItem *ditem = OFstatic_cast(DcmItem *, dataset);

    if (result.good()) result = ditem->findAndGetUint16(DCM_SamplesPerPixel, imageSamplesPerPixel);
    if (result.good()) result = ditem->findAndGetUint16(DCM_Rows, imageRows);
    if (result.good()) result = ditem->findAndGetUint16(DCM_Columns, imageColumns);
    if (result.good()) result = ditem->findAndGetUint16(DCM_BitsAllocated, imageBitsAllocated);
    if (result.good())
    {
      imageBytesAllocated = OFstatic_cast(Uint16, imageBitsAllocated / 8);
      if ((imageBitsAllocated < 8)||(imageBitsAllocated % 8 != 0)) result = EC_CannotChangeRepresentation;
    }
    if (result.good() && (imageSamplesPerPixel > 1))
    {
      result = ditem->findAndGetUint16(DCM_PlanarConfiguration, imagePlanarConfiguration);
    }

    // number of frames is an optional attribute - we don't mind if it isn't present.
    if (result.good()) (void) ditem->findAndGetSint32(DCM_NumberOfFrames, imageFrames);
    if (imageFrames < 1) imageFrames = 1; // default in case this attribute contains garbage

    if (result.good())
    {
      DcmPixelItem *pixItem = NULL;
      Uint8 * rleData = NULL;
      const size_t bytesPerStripe = imageColumns * imageRows;

      DcmRLEDecoder rledecoder(bytesPerStripe);
      if (rledecoder.fail()) result = EC_MemoryExhausted;  // RLE decoder failed to initialize
      else
      {
        Uint32 frameSize = imageBytesAllocated * imageRows * imageColumns * imageSamplesPerPixel;
        Uint32 totalSize = frameSize * imageFrames;
        if (totalSize & 1) totalSize++; // align on 16-bit word boundary
        Uint16 *imageData16 = NULL;
        Sint32 currentFrame = 0;
        Uint32 currentItem = 1; // ignore offset table
        Uint32 numberOfStripes = 0;
        Uint32 fragmentLength = 0;
        Uint32 i;

        result = uncompressedPixelData.createUint16Array(totalSize/sizeof(Uint16), imageData16);
        if (result.good())
        {
          Uint8 *imageData8 = OFreinterpret_cast(Uint8 *, imageData16);

          while ((currentFrame < imageFrames) && result.good())
          {
            // get first pixel item of this frame
            result = pixSeq->getItem(pixItem, currentItem++);
            if (result.good())
            {
              fragmentLength = pixItem->getLength();
              result = pixItem->getUint8Array(rleData);
              if (result.good())
              {
                // we require that the RLE header must be completely
                // contained in the first fragment; otherwise bail out
                if (fragmentLength < 64) result = EC_CannotChangeRepresentation;
              }
            }

            if (result.good())
            {
              // copy RLE header to buffer and adjust byte order
              memcpy(rleHeader, rleData, 64);
              swapIfNecessary(gLocalByteOrder, EBO_LittleEndian, rleHeader, 16*sizeof(Uint32), sizeof(Uint32));

              // determine number of stripes.
              numberOfStripes = rleHeader[0];

              // check that number of stripes in RLE header matches our expectation
              if ((numberOfStripes < 1) || (numberOfStripes > 15) ||
                  (numberOfStripes != OFstatic_cast(Uint32, imageBytesAllocated) * imageSamplesPerPixel))
                  result = EC_CannotChangeRepresentation;
            }

            if (result.good())
            {
              // this variable keeps the number of bytes we have processed
              // for the current frame in earlier pixel fragments
              Uint32 fragmentOffset = 0;

              // this variable keeps the current position within the current fragment
              Uint32 byteOffset = 0;

              OFBool lastStripe = OFFalse;
              Uint32 inputBytes = 0;

              // pointers for buffer copy operations
              Uint8 *outputBuffer = NULL;
              Uint8 *pixelPointer = NULL;

              // byte offset for first sample in frame
              Uint32 sampleOffset = 0;

              // byte offset between samples
              Uint32 offsetBetweenSamples = 0;

              // temporary variables
              Uint32 sample = 0;
              Uint32 byte = 0;
              Uint32 pixel = 0;

              // for each stripe in stripe set
              for (i=0; (i<numberOfStripes) && result.good(); ++i)
              {
                // reset RLE codec
                rledecoder.clear();

                // adjust start point for RLE stripe, ignoring trailing garbage from the last run
                byteOffset = rleHeader[i+1];
                if (byteOffset < fragmentOffset) result = EC_CannotChangeRepresentation;
                else
                {
                  byteOffset -= fragmentOffset; // now byteOffset is correct but may point to next fragment
                  while ((byteOffset > fragmentLength) && result.good())
                  {
                    result = pixSeq->getItem(pixItem, currentItem++);
                    if (result.good())
                    {
                      byteOffset -= fragmentLength;
                      fragmentOffset += fragmentLength;
                      fragmentLength = pixItem->getLength();
                      result = pixItem->getUint8Array(rleData);
                    }
                  }
                }

                // byteOffset now points to the first byte of the new RLE stripe
                // check if the current stripe is the last one for this frame
                if (i+1 == numberOfStripes) lastStripe = OFTrue; else lastStripe = OFFalse;

                if (lastStripe)
                {
                  // the last stripe needs special handling because we cannot use the
                  // offset table to determine the number of bytes to feed to the codec
                  // if the RLE data is split in multiple fragments. We need to feed
                  // data fragment by fragment until the RLE codec has produced
                  // sufficient output.
                  while ((rledecoder.size() < bytesPerStripe) && result.good())
                  {
                    // feed complete remaining content of fragment to RLE codec and
                    // switch to next fragment
                    result = rledecoder.decompress(rleData + byteOffset, OFstatic_cast(size_t, fragmentLength - byteOffset));

                    // special handling for zero pad byte at the end of the RLE stream
                    // which results in an EC_StreamNotifyClient return code
                    // or trailing garbage data which results in EC_CorruptedData
                    if (rledecoder.size() == bytesPerStripe) result = EC_Normal;

                    // Check if we're already done. If yes, don't change fragment
                    if (result.good() || result == EC_StreamNotifyClient)
                    {
                      if (rledecoder.size() < bytesPerStripe)
                      {
                        result = pixSeq->getItem(pixItem, currentItem++);
                        if (result.good())
                        {
                          byteOffset = 0;
                          fragmentOffset += fragmentLength;
                          fragmentLength = pixItem->getLength();
                          result = pixItem->getUint8Array(rleData);
                        }
                      }
                      else byteOffset = fragmentLength;
                    }
                  } /* while */
                }
                else
                {
                  // not the last stripe. We can use the offset table to determine
                  // the number of bytes to feed to the RLE codec.
                  inputBytes = rleHeader[i+2];
                  if (inputBytes < rleHeader[i+1]) result = EC_CannotChangeRepresentation;
                  else
                  {
                    inputBytes -= rleHeader[i+1]; // number of bytes to feed to codec
                    while ((inputBytes > (fragmentLength - byteOffset)) && result.good())
                    {
                      // feed complete remaining content of fragment to RLE codec and
                      // switch to next fragment
                      result = rledecoder.decompress(rleData + byteOffset, OFstatic_cast(size_t, fragmentLength - byteOffset));

                      if (result.good() || result == EC_StreamNotifyClient)
                        result = pixSeq->getItem(pixItem, currentItem++);
                      if (result.good())
                      {
                        inputBytes -= fragmentLength - byteOffset;
                        byteOffset = 0;
                        fragmentOffset += fragmentLength;
                        fragmentLength = pixItem->getLength();
                        result = pixItem->getUint8Array(rleData);
                      }
                    } /* while */

                    // last fragment for this RLE stripe
                    result = rledecoder.decompress(rleData + byteOffset, OFstatic_cast(size_t, inputBytes));

                    // special handling for zero pad byte at the end of the RLE stream
                    // which results in an EC_StreamNotifyClient return code
                    // or trailing garbage data which results in EC_CorruptedData
                    if (rledecoder.size() == bytesPerStripe) result = EC_Normal;

                    byteOffset += inputBytes;
                  }
                }

                // make sure the RLE decoder has produced the right amount of data
                if (result.good() && (rledecoder.size() != bytesPerStripe))
                {
                  // error: RLE decoder is finished but has produced insufficient data for this stripe
                  result = EC_CannotChangeRepresentation;
                }

                // distribute decompressed bytes into output image array
                if (result.good())
                {
                  // which sample and byte are we currently compressing?
                  sample = i / imageBytesAllocated;
                  byte = i % imageBytesAllocated;

                  // raw buffer containing bytesPerStripe bytes of uncompressed data
                  outputBuffer = OFstatic_cast(Uint8 *, rledecoder.getOutputBuffer());

                  // compute byte offsets
                  if (imagePlanarConfiguration == 0)
                  {
                     sampleOffset = sample * imageBytesAllocated;
                     offsetBetweenSamples = imageSamplesPerPixel * imageBytesAllocated;
                  }
                  else
                  {
                     sampleOffset = sample * imageBytesAllocated * imageColumns * imageRows;
                     offsetBetweenSamples = imageBytesAllocated;
                  }

                  // initialize pointer to output data
                  if (enableReverseByteOrder)
                  {
                    // assume incorrect LSB to MSB order of RLE segments as produced by some tools
                    pixelPointer = imageData8 + sampleOffset + byte;
                  }
                  else
                  {
                    pixelPointer = imageData8 + sampleOffset + imageBytesAllocated - byte - 1;
                  }

                  // loop through all pixels of the frame
                  for (pixel = 0; pixel < bytesPerStripe; ++pixel)
                  {
                    *pixelPointer = *outputBuffer++;
                    pixelPointer += offsetBetweenSamples;
                  }
                }
              } /* for */
            }

            // advance by one frame
            if (result.good())
            {
              currentFrame++;
              imageData8 += frameSize;
            }

          } /* while still frames to process */

          // adjust byte order for uncompressed image to little endian
          swapIfNecessary(EBO_LittleEndian, gLocalByteOrder, imageData16, totalSize, sizeof(Uint16));
        }
      }
    }

    // the following operations do not affect the Image Pixel Module
    // but other modules such as SOP Common.  We only perform these
    // changes if we're on the main level of the dataset,
    // which should always identify itself as dataset, not as item.
    if (dataset->ident() == EVR_dataset)
    {
        // create new SOP instance UID if codec parameters require so
        if (result.good() && djcp->getUIDCreation()) result = 
          DcmCodec::newInstance(OFstatic_cast(DcmItem *, dataset), NULL, NULL, NULL);
    }
  }
  return result;
}


OFCondition DcmRLECodecDecoder::encode(
        const Uint16 * /* pixelData */,
        const Uint32 /* length */,
        const DcmRepresentationParameter * /* toRepParam */,
        DcmPixelSequence * & /* pixSeq */,
        const DcmCodecParameter * /* cp */,
        DcmStack & /* objStack */) const
{
  // we are a decoder only
  return EC_IllegalCall;
}


OFCondition DcmRLECodecDecoder::encode(
    const E_TransferSyntax /* fromRepType */,
    const DcmRepresentationParameter * /* fromRepParam */,
    DcmPixelSequence * /* fromPixSeq */,
    const DcmRepresentationParameter * /* toRepParam */,
    DcmPixelSequence * & /* toPixSeq */,
    const DcmCodecParameter * /* cp */,
    DcmStack & /* objStack */) const
{
  // we don't support re-coding for now.
  return EC_IllegalCall;
}


/*
 * CVS/RCS Log
 * $Log: dcrleccd.cc,v $
 * Revision 1.1  2006/03/01 20:15:22  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.7  2005/12/08 15:41:29  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.6  2005/07/26 17:08:35  meichel
 * Added option to RLE decoder that allows to correctly decode images with
 *   incorrect byte order of byte segments (LSB instead of MSB).
 *
 * Revision 1.5  2004/08/24 14:54:20  meichel
 *  Updated compression helper methods. Image type is not set to SECONDARY
 *   any more, support for the purpose of reference code sequence added.
 *
 * Revision 1.4  2003/08/14 09:01:06  meichel
 * Adapted type casts to new-style typecast operators defined in ofcast.h
 *
 * Revision 1.3  2003/03/21 13:08:04  meichel
 * Minor code purifications for warnings reported by MSVC in Level 4
 *
 * Revision 1.2  2002/07/18 12:15:39  joergr
 * Added explicit type casts to keep Sun CC 2.0.1 quiet.
 *
 * Revision 1.1  2002/06/06 14:52:40  meichel
 * Initial release of the new RLE codec classes
 *   and the dcmcrle/dcmdrle tools in module dcmdata
 *
 *
 */
