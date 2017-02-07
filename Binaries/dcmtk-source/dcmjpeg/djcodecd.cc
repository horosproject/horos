/*
 *
 *  Copyright (C) 1997-2005, OFFIS
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
 *  Module:  dcmjpeg
 *
 *  Author:  Marco Eichelberg, Norbert Olges
 *
 *  Purpose: Abstract base class for IJG JPEG decoder
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:43 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmjpeg/djcodecd.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */
 
int gForce1024RescaleInterceptForCT = 0;

#include "osconfig.h"
#include "djcodecd.h"
#include "ofstd.h"

// dcmdata includes
#include "dcdatset.h"  /* for class DcmDataset */
#include "dcdeftag.h"  /* for tag constants */
#include "dcpixseq.h"  /* for class DcmPixelSequence */
#include "dcpxitem.h"  /* for class DcmPixelItem */
#include "dcvrpobw.h"  /* for class DcmPolymorphOBOW */
#include "dcswap.h"    /* for swapIfNecessary() */
#include "dcuid.h"     /* for dcmGenerateUniqueIdentifer()*/

// dcmjpeg includes
#include "djcparam.h"  /* for class DJCodecParameter */
#include "djdecabs.h"  /* for class DJDecoder */

DJCodecDecoder::DJCodecDecoder()
: DcmCodec()
{
}


DJCodecDecoder::~DJCodecDecoder()
{
}

OFBool DJCodecDecoder::canChangeCoding(
    const E_TransferSyntax oldRepType,
    const E_TransferSyntax newRepType) const
{
  E_TransferSyntax myXfer = supportedTransferSyntax();
  DcmXfer newRep(newRepType);
  if (newRep.isNotEncapsulated() && (oldRepType == myXfer))
	return OFTrue; // decompress requested

  // we don't support re-coding for now.
  return OFFalse;
}


OFCondition DJCodecDecoder::decode(
    const DcmRepresentationParameter * fromRepParam,
    DcmPixelSequence * pixSeq,
    DcmPolymorphOBOW& uncompressedPixelData,
    const DcmCodecParameter * cp,
    const DcmStack& objStack) const
{
  OFCondition result = EC_Normal;
  // assume we can cast the codec parameter to what we need
  const DJCodecParameter *djcp = (const DJCodecParameter *)cp;

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
    Uint16 imageBitsStored = 0;
	Uint16 imageBitsAllocated = 0;
    Uint16 imageHighBit = 0;
    const char *sopClassUID = NULL;
    OFBool createPlanarConfiguration = OFFalse;
    OFBool createPlanarConfigurationInitialized = OFFalse;
    EP_Interpretation colorModel = EPI_Unknown;
    OFBool isSigned = OFFalse; Uint16 pixelRep = 0; // needed to decline color conversion of signed pixel data to RGB

    if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_SamplesPerPixel, imageSamplesPerPixel);
    if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_Rows, imageRows);
    if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_Columns, imageColumns);
    if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_BitsStored, imageBitsStored);
	if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_BitsAllocated, imageBitsAllocated);
    if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_HighBit, imageHighBit);
    if (result.good()) result = ((DcmItem *)dataset)->findAndGetUint16(DCM_PixelRepresentation, pixelRep);
    isSigned = (pixelRep == 0) ? OFFalse : OFTrue;
    // number of frames is an optional attribute - we don't mind if it isn't present.
    if (result.good()) (void) ((DcmItem *)dataset)->findAndGetSint32(DCM_NumberOfFrames, imageFrames);

    // we consider SOP Class UID as optional since we only need it to determine SOP Class specific
    // encoding rules for planar configuration.
    if (result.good()) (void) ((DcmItem *)dataset)->findAndGetString(DCM_SOPClassUID, sopClassUID);
	
    EP_Interpretation dicomPI = DcmJpegHelper::getPhotometricInterpretation((DcmItem *)dataset);

    OFBool isYBR = OFFalse;
    if ((dicomPI == EPI_YBR_Full)||(dicomPI == EPI_YBR_Full_422)||(dicomPI == EPI_YBR_Partial_422)) isYBR = OFTrue;

    if (imageFrames < 1) imageFrames = 1; // default in case this attribute contains garbage
    if (result.good())
    {
      DcmPixelItem *pixItem = NULL;
      Uint8 * jpegData = NULL;
      result = pixSeq->getItem(pixItem, 1); // first item is offset table, use second item
      if (result.good())
      {
        Uint32 fragmentLength = pixItem->getLength();
        result = pixItem->getUint8Array(jpegData);
        if (result.good())
        {
			const char *GEIcon = NULL;
			OFBool isGEIcon = OFFalse;
			if(((DcmItem *)dataset)->findAndGetString( DcmTagKey( 0x0029, 0x0010), GEIcon).good() && GEIcon)
			{
				if( strcmp( GEIcon, "GEIIS") == 0) // 0x0009, 0x1110 The problematic private group, containing a *always* JPEG compressed PixelData
					isGEIcon = OFTrue; // GE Icon pixel data are already and always compressed in JPEG -> dont touch lesion !
			}
			
			if( isGEIcon)
			{
				Uint16 *imageData16 = NULL;
				
				result = uncompressedPixelData.createUint16Array(fragmentLength/sizeof(Uint16), imageData16);
				if (result.good())
					memcpy( imageData16, jpegData, fragmentLength);
			}
			else
			{
			  Uint8 precision = scanJpegDataForBitDepth(jpegData, fragmentLength);
			  
			  OFBool jp2k = isJPEG2000();
			  
			  if( jp2k) // JPEG2000 support
				precision = imageBitsAllocated;
			  
			  if( precision == 0) result = EC_CannotChangeRepresentation; // something has gone wrong, bail out
			  else
			  {
				DJDecoder *jpeg = createDecoderInstance(fromRepParam, djcp, precision, isYBR);
				if (jpeg == NULL) result = EC_MemoryExhausted;
				else
				{
				  Uint32 frameSize = ((precision > 8) ? sizeof(Uint16) : sizeof(Uint8)) * imageRows * imageColumns * imageSamplesPerPixel;
				  Uint32 totalSize = frameSize * imageFrames;
				  if (totalSize & 1) totalSize++; // align on 16-bit word boundary
				  Uint16 *imageData16 = NULL;
				  Sint32 currentFrame = 0;
				  Uint32 currentItem = 1; // ignore offset table

				  result = uncompressedPixelData.createUint16Array(totalSize/sizeof(Uint16), imageData16);
				  if (result.good())
				  {
					Uint8 *imageData8 = (Uint8 *)imageData16;

					while ((currentFrame < imageFrames)&&(result.good()))
					{
					  result = jpeg->init();
					  if (result.good())
					  {
						result = EJ_Suspension;
						while (EJ_Suspension == result)
						{
						  result = pixSeq->getItem(pixItem, currentItem++);
						  if (result.good())
						  {
							fragmentLength = pixItem->getLength();
							result = pixItem->getUint8Array(jpegData);
							if (result.good())
							{
							  result = jpeg->decode(jpegData, fragmentLength, imageData8, frameSize, isSigned);
							}
						  }
						}
						if (result.good())
						{
						  if (! createPlanarConfigurationInitialized)
						  {
							// we need to know the decompressed photometric interpretation in order
							// to determine the final planar configuration.  However, this is only
							// known after the first call to jpeg->decode(), i.e. here.
							colorModel = jpeg->getDecompressedColorModel();
							if (colorModel == EPI_Unknown)
							{
							  // derive color model from DICOM photometric interpretation
							  if ((dicomPI == EPI_YBR_Full_422)||(dicomPI == EPI_YBR_Partial_422)) colorModel = EPI_YBR_Full;
							  else colorModel = dicomPI;
							}

							switch (djcp->getPlanarConfiguration())
							{
							  case EPC_default:
								createPlanarConfiguration = requiresPlanarConfiguration(sopClassUID, colorModel);
								break;
							  case EPC_colorByPixel:
								createPlanarConfiguration = OFFalse;
								break;
							  case EPC_colorByPlane:
								createPlanarConfiguration = OFTrue;
								break;
							}
							createPlanarConfigurationInitialized = OFTrue;
						  }

						  // convert planar configuration if necessary
						  if ((imageSamplesPerPixel == 3) && createPlanarConfiguration)
						  {
							if (precision > 8)
							  result = createPlanarConfigurationWord((Uint16 *)imageData8, imageColumns, imageRows);
							  else result = createPlanarConfigurationByte(imageData8, imageColumns, imageRows);
						  }
						  currentFrame++;
						  imageData8 += frameSize;
						}
					  }
					}

					if (result.good())
					{
					  // decompression is complete, finally adjust byte order if necessary
					  if (jpeg->bytesPerSample() == 1) // we're writing bytes into words
					  {
						result = swapIfNecessary(gLocalByteOrder, EBO_LittleEndian, imageData16, totalSize, sizeof(Uint16));
					  }
					}

					// adjust photometric interpretation depending on what conversion has taken place
					if (result.good())
					{
					  switch (colorModel)
					  {
						case EPI_Monochrome2:
						  result = ((DcmItem *)dataset)->putAndInsertString(DCM_PhotometricInterpretation, "MONOCHROME2");
						  if (result.good())
						  {
							imageSamplesPerPixel = 1;
							result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_SamplesPerPixel, imageSamplesPerPixel);
							
							if( gForce1024RescaleInterceptForCT && precision > 8)
							{
								if (0 == strcmp(sopClassUID, UID_CTImageStorage))
								{
									const char *string = NULL;
									
									if (((DcmItem *)dataset)->findAndGetString(DCM_RescaleIntercept, string, OFFalse).good() && string != NULL)
									{
										Sint16 previousRescaleIntercept = atoi( string);
										if( previousRescaleIntercept != -1024)
										{
											delete ((DcmItem *)dataset)->remove(DCM_RescaleIntercept);
											
											int difference = previousRescaleIntercept + 1024;
											Uint16 *imageData = imageData16;
											long loop = imageRows * imageColumns;
											while( loop-->0)
											{
												if( *imageData < -difference)
													*imageData++ = 0;
												else
													*imageData++ += difference;
											}
											
											char buf[64];
											OFStandard::ftoa(buf, sizeof(buf), -1024, OFStandard::ftoa_uppercase, 0, 6);
											if (result.good()) result = ((DcmItem *)dataset)->putAndInsertString(DCM_RescaleIntercept, buf);
										}
									}
								}
							}
						  }
						  break;
						case EPI_YBR_Full:
						  result = ((DcmItem *)dataset)->putAndInsertString(DCM_PhotometricInterpretation, "YBR_FULL");
						  if (result.good())
						  {
							imageSamplesPerPixel = 3;
							result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_SamplesPerPixel, imageSamplesPerPixel);
						  }
						  break;
						case EPI_RGB:
						  result = ((DcmItem *)dataset)->putAndInsertString(DCM_PhotometricInterpretation, "RGB");
						  if (result.good())
						  {
							imageSamplesPerPixel = 3;
							result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_SamplesPerPixel, imageSamplesPerPixel);
						  }
						  break;
						default:
						  /* leave photometric interpretation untouched unless it is YBR_FULL_422
						   * or YBR_PARTIAL_422. In this case, replace by YBR_FULL since decompression
						   * eliminates the subsampling.
						   */
						  if ((dicomPI == EPI_YBR_Full_422)||(dicomPI == EPI_YBR_Partial_422))
						  {
							result = ((DcmItem *)dataset)->putAndInsertString(DCM_PhotometricInterpretation, "YBR_FULL");
						  }
						  break;
					  }
					}

					// Bits Allocated is now either 8 or 16
					if (result.good())
					{
					  if (precision > 8) result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_BitsAllocated, 16);
					  else result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_BitsAllocated, 8);
					}

					// Planar Configuration depends on the createPlanarConfiguration flag
					if ((result.good()) && (imageSamplesPerPixel > 1))
					{
					  result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_PlanarConfiguration, (createPlanarConfiguration ? 1 : 0));
					}

					// Bits Stored cannot be larger than precision
					if ((result.good()) && (imageBitsStored > precision))
					{
					  result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_BitsStored, precision);
					}

					// High Bit cannot be larger than precision - 1
					if ((result.good()) && ((unsigned int)(imageHighBit+1) > (unsigned int)precision))
					{
					  result = ((DcmItem *)dataset)->putAndInsertUint16(DCM_HighBit, precision-1);
					}

					// Pixel Representation could be signed if lossless JPEG. For now, we just believe what we get.
				  }
				  delete jpeg;
				}
			  }
			}
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
        if (result.good() && (djcp->getUIDCreation() == EUC_always))
          result = DcmCodec::newInstance((DcmItem *)dataset, NULL, NULL, NULL);
    }

  }
  return result;
}


OFCondition DJCodecDecoder::encode(
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


OFCondition DJCodecDecoder::encode(
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


Uint16 DJCodecDecoder::readUint16(const Uint8 *data)
{
  return (((Uint16)(*data) << 8) | ((Uint16)(*(data+1))));
}


Uint8 DJCodecDecoder::scanJpegDataForBitDepth(
  const Uint8 *data,
  const Uint32 fragmentLength)
{
  Uint32 offset = 0;
  while(offset+4 < fragmentLength)
  {
    switch(readUint16(data+offset))
    {
      case 0xffc0: // SOF_0: JPEG baseline
        return data[offset+4];
        /* break; */
      case 0xffc1: // SOF_1: JPEG extended sequential DCT
        return data[offset+4];
        /* break; */
      case 0xffc2: // SOF_2: JPEG progressive DCT
        return data[offset+4];
        /* break; */
      case 0xffc3 : // SOF_3: JPEG lossless sequential
        return data[offset+4];
        /* break; */
      case 0xffc5: // SOF_5: differential (hierarchical) extended sequential, Huffman
        return data[offset+4];
        /* break; */
      case 0xffc6: // SOF_6: differential (hierarchical) progressive, Huffman
        return data[offset+4];
        /* break; */
      case 0xffc7: // SOF_7: differential (hierarchical) lossless, Huffman
        return data[offset+4];
        /* break; */
      case 0xffc8: // Reserved for JPEG extentions
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffc9: // SOF_9: extended sequential, arithmetic
        return data[offset+4];
        /* break; */
      case 0xffca: // SOF_10: progressive, arithmetic
        return data[offset+4];
        /* break; */
      case 0xffcb: // SOF_11: lossless, arithmetic
        return data[offset+4];
        /* break; */
      case 0xffcd: // SOF_13: differential (hierarchical) extended sequential, arithmetic
        return data[offset+4];
        /* break; */
      case 0xffce: // SOF_14: differential (hierarchical) progressive, arithmetic
        return data[offset+4];
        /* break; */
      case 0xffcf: // SOF_15: differential (hierarchical) lossless, arithmetic
        return data[offset+4];
        /* break; */
      case 0xffc4: // DHT
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffcc: // DAC
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffd0: // RST m
      case 0xffd1:
      case 0xffd2:
      case 0xffd3:
      case 0xffd4:
      case 0xffd5:
      case 0xffd6:
      case 0xffd7:
        offset +=2;
        break;
      case 0xffd8: // SOI
        offset +=2;
        break;
      case 0xffd9: // EOI
        offset +=2;
        break;
      case 0xffda: // SOS
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffdb: // DQT
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffdc: // DNL
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffdd: // DRI
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffde: // DHP
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffdf: // EXP
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xffe0: // APPn
      case 0xffe1:
      case 0xffe2:
      case 0xffe3:
      case 0xffe4:
      case 0xffe5:
      case 0xffe6:
      case 0xffe7:
      case 0xffe8:
      case 0xffe9:
      case 0xffea:
      case 0xffeb:
      case 0xffec:
      case 0xffed:
      case 0xffee:
      case 0xffef:
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xfff0: // JPGn
      case 0xfff1:
      case 0xfff2:
      case 0xfff3:
      case 0xfff4:
      case 0xfff5:
      case 0xfff6:
      case 0xfff7:
      case 0xfff8:
      case 0xfff9:
      case 0xfffa:
      case 0xfffb:
      case 0xfffc:
      case 0xfffd:
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xfffe: // COM
        offset += readUint16(data+offset+2)+2;
        break;
      case 0xff01: // TEM
        break;
      default:
        if ((data[offset]==0xff) && (data[offset+1]>2) && (data[offset+1] <= 0xbf)) // RES reserved markers
        {
          offset += 2;
        }
        else return 0; // syntax error, stop parsing
        break;
    }
  } // while
  return 0; // no SOF marker found
}


OFCondition DJCodecDecoder::createPlanarConfigurationByte(
  Uint8 *imageFrame,
  Uint16 columns,
  Uint16 rows)
{
  if (imageFrame == NULL) return EC_IllegalCall;

  unsigned int numPixels = columns * rows;
  if (numPixels == 0) return EC_IllegalCall;

  Uint8 *buf = new Uint8[3*numPixels + 3];
  if (buf)
  {
    memcpy(buf, imageFrame, (size_t)(3*numPixels));
    Uint8 *s = buf;                        // source
    Uint8 *r = imageFrame;                 // red plane
    Uint8 *g = imageFrame + numPixels;     // green plane
    Uint8 *b = imageFrame + (2*numPixels); // blue plane
    for (unsigned int i=numPixels; i; i--)
    {
      *r++ = *s++;
      *g++ = *s++;
      *b++ = *s++;
    }
    delete[] buf;
  } else return EC_MemoryExhausted;
  return EC_Normal;
}

OFCondition DJCodecDecoder::createPlanarConfigurationWord(
  Uint16 *imageFrame,
  Uint16 columns,
  Uint16 rows)
{
  if (imageFrame == NULL) return EC_IllegalCall;

  unsigned int numPixels = columns * rows;
  if (numPixels == 0) return EC_IllegalCall;

  Uint16 *buf = new Uint16[3*numPixels + 3];
  if (buf)
  {
    memcpy(buf, imageFrame, (size_t)(3*numPixels*sizeof(Uint16)));
    Uint16 *s = buf;                        // source
    Uint16 *r = imageFrame;                 // red plane
    Uint16 *g = imageFrame + numPixels;     // green plane
    Uint16 *b = imageFrame + (2*numPixels); // blue plane
    for (unsigned int i=numPixels; i; i--)
    {
      *r++ = *s++;
      *g++ = *s++;
      *b++ = *s++;
    }
    delete[] buf;
  } else return EC_MemoryExhausted;
  return EC_Normal;
}

/* This method examines if a given image requires color-by-plane planar configuration
 * depending on SOP Class UID (DICOM IOD) and photometric interpretation.
 * All SOP classes defined in the 2001 edition of the DICOM standard or earlier
 * are handled correctly.
 */

OFBool DJCodecDecoder::requiresPlanarConfiguration(
  const char *sopClassUID,
  EP_Interpretation photometricInterpretation)
{
  if (sopClassUID)
  {
    OFString sopClass(sopClassUID);

    // Hardcopy Color Image always requires color-by-plane
    if (sopClass == UID_HardcopyColorImageStorage) return OFTrue;

    // The 1996 Ultrasound Image IODs require color-by-plane if color model is YBR_FULL.
    if (photometricInterpretation == EPI_YBR_Full)
    {
      if ((sopClass == UID_UltrasoundMultiframeImageStorage)
        ||(sopClass == UID_UltrasoundImageStorage)) return OFTrue;
    }

  }
  return OFFalse;
}


/*
 * CVS/RCS Log
 * $Log: djcodecd.cc,v $
 * Revision 1.1  2006/03/01 20:15:43  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.8  2005/12/08 15:43:26  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.7  2005/11/30 14:15:50  onken
 * Added support for decoder modifications concerning color space conversions
 * of signed pixel data
 *
 * Revision 1.6  2004/08/24 14:57:10  meichel
 * Updated compression helper methods. Image type is not set to SECONDARY
 *   any more, support for the purpose of reference code sequence added.
 *
 * Revision 1.5  2002/05/24 14:59:51  meichel
 * Moved helper methods that are useful for different compression techniques
 *   from module dcmjpeg to module dcmdata
 *
 * Revision 1.4  2002/01/08 10:29:07  joergr
 * Corrected spelling of function dcmGenerateUniqueIdentifier().
 *
 * Revision 1.3  2001/12/20 10:41:49  meichel
 * Fixed warnings reported by Sun CC 2.0.1
 *
 * Revision 1.2  2001/11/28 13:48:15  joergr
 * Check return value of DcmItem::insert() statements where appropriate to
 * avoid memory leaks when insert procedure fails.
 *
 * Revision 1.1  2001/11/13 15:58:23  meichel
 * Initial release of module dcmjpeg
 *
 *
 */
