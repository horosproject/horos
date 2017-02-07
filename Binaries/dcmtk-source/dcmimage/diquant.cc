/*
 *
 *  Copyright (C) 2002-2005, OFFIS
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
 *  Module:  dcmimage
 *
 *  Author:  Marco Eichelberg
 *
 *  Purpose: DcmQuant
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:36 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"
#include "diquant.h"

#include "ofconsol.h"  /* for ofConsole */
#include "diqtid.h"    /* for DcmQuantIdent */
#include "diqtcmap.h"  /* for DcmQuantColorMapping */
#include "diqtpix.h"   /* for DcmQuantPixel */
#include "diqthash.h"  /* for DcmQuantColorHashTable */
#include "diqtctab.h"  /* for DcmQuantColorTable */
#include "diqtfs.h"    /* for DcmQuantFloydSteinberg */
#include "dcswap.h"    /* for swapIfNecessary() */
#include "dcitem.h"    /* for DcmItem */
#include "dcmimage.h"  /* for DicomImage */
#include "dcdeftag.h"  /* for tag constants */
#include "dcpixel.h"   /* for DcmPixelData */
#include "dcsequen.h"  /* for DcmSequenceOfItems */
#include "dcuid.h"     /* for dcmGenerateUniqueIdentifier() */


OFCondition DcmQuant::createPaletteColorImage(
    DicomImage& sourceImage,
    DcmItem& target,
    OFBool writeAsOW,
    OFBool write16BitEntries,
    OFBool floydSteinberg,
    Uint32 numberOfColors,
    OFString& description,
    OFBool verbose,
    DcmLargestDimensionType largeType,
    DcmRepresentativeColorType repType)
{
	// make sure we're operating on a color image
    if (sourceImage.isMonochrome()) return EC_IllegalCall;

    // make sure numberOfColors is in range
    if ((numberOfColors > 65536)||(numberOfColors < 2)) return EC_IllegalCall;

    OFCondition result = EC_Normal;

    // Create histogram of the colors, clustered if necessary
    if (verbose)
    {
      ofConsole.lockCerr() << "computing image histogram" << endl;
      ofConsole.unlockCerr();
    }

    DcmQuantColorTable chv;
    result = chv.computeHistogram(sourceImage, DcmQuantMaxColors);
    if (result.bad()) return result;

    unsigned int maxval = chv.getMaxVal();
    if (verbose)
    {
      ofConsole.lockCerr() << "image histogram: found " << chv.getColors() << " colors (at maxval=" << maxval << ")" << endl;
      ofConsole.unlockCerr();
    }

    // apply median-cut to histogram, making the new colormap.
    unsigned int cols = sourceImage.getWidth();
    unsigned int rows = sourceImage.getHeight();
    unsigned int frames = sourceImage.getFrameCount();

    if (verbose)
    {
      ofConsole.lockCerr() << "computing color map using Heckbert's median cut algorithm" << endl;
      ofConsole.unlockCerr();
    }

    DcmQuantColorTable colormap;
    result = colormap.medianCut(chv, cols * rows * frames, maxval, numberOfColors, largeType, repType);
    if (result.bad()) return result;
    chv.clear(); // frees most memory used by chv.

    // map the colors in the image to their closest match in the
    // new colormap, and write 'em out.
    DcmQuantColorHashTable cht;
    if (verbose)
    {
      ofConsole.lockCerr() << "mapping image data to color table" << endl;
      ofConsole.unlockCerr();
    }

    DcmQuantFloydSteinberg fs;
    if (floydSteinberg)
    {
      result = fs.initialize(cols);
      if (result.bad()) return result;
    }
    DcmQuantIdent id(cols);

    OFBool isByteData = (numberOfColors <= 256);

    // compute size requirement for palette color pixel data in bytes
    unsigned int totalSize = cols * rows * frames;
    if (! isByteData) totalSize *= 2;
    if (totalSize & 1) totalSize++;

    Uint16 *imageData16 = NULL;
    Uint8  *imageData8  = NULL;
    DcmPolymorphOBOW *pixelData = new DcmPolymorphOBOW(DCM_PixelData);
    if (pixelData)
    {
       result = pixelData->createUint16Array(totalSize/sizeof(Uint16), imageData16);
       if (result.good())
       {
       	 imageData16[(totalSize/sizeof(Uint16)) -1] = 0; // make sure pad byte is zero
         imageData8 = OFreinterpret_cast(Uint8 *, imageData16);
         result = target.insert(pixelData, OFTrue);
         if (result.good())
         {
            for (unsigned int ff=0; ff<frames; ff++)
            {
              if (isByteData)
              {
                if (floydSteinberg)
                  DcmQuantColorMapping<DcmQuantFloydSteinberg,Uint8>::create(sourceImage, ff, maxval, cht, colormap, fs, imageData8  + cols*rows*ff);
                  else DcmQuantColorMapping<DcmQuantIdent,    Uint8>::create(sourceImage, ff, maxval, cht, colormap, id, imageData8  + cols*rows*ff);
              }
              else
              {
                if (floydSteinberg)
                  DcmQuantColorMapping<DcmQuantFloydSteinberg,Uint16>::create(sourceImage, ff, maxval, cht, colormap, fs, imageData16 + cols*rows*ff);
                  else DcmQuantColorMapping<DcmQuantIdent,    Uint16>::create(sourceImage, ff, maxval, cht, colormap, id, imageData16 + cols*rows*ff);
             }
            } // for all frames

            // image creation is complete, finally adjust byte order if necessary
            if (isByteData)
            {
              result = swapIfNecessary(gLocalByteOrder, EBO_LittleEndian, imageData16, totalSize, sizeof(Uint16));
            }

         }
       }
    }

    if (verbose)
    {
      ofConsole.lockCerr() << "creating DICOM image pixel module" << endl;
      ofConsole.unlockCerr();
    }

    // create target image pixel module
    if (result.good()) result = target.putAndInsertUint16(DCM_SamplesPerPixel, 1);
    if (result.good()) result = target.putAndInsertUint16(DCM_PixelRepresentation, 0);
    if (result.good()) result = target.putAndInsertString(DCM_PhotometricInterpretation, "PALETTE COLOR");
    if (result.good()) result = target.putAndInsertUint16(DCM_Rows, OFstatic_cast(Uint16, rows));
    if (result.good()) result = target.putAndInsertUint16(DCM_Columns, OFstatic_cast(Uint16, cols));

    // determine bits allocated, stored, high bit
    Uint16 bitsAllocated = 8;
    Uint16 bitsStored = 8;
    Uint16 highBit = 7;
    if (! isByteData)
    {
      bitsAllocated = 16;
      bitsStored = 8;
      while ((1UL << bitsStored) < OFstatic_cast(unsigned int, numberOfColors)) bitsStored++;
      highBit = bitsStored - 1;
    }
    if (result.good()) result = target.putAndInsertUint16(DCM_BitsAllocated, bitsAllocated);
    if (result.good()) result = target.putAndInsertUint16(DCM_BitsStored, bitsStored);
    if (result.good()) result = target.putAndInsertUint16(DCM_HighBit, highBit);

    // make sure these attributes are not present in the target image
    delete target.remove(DCM_SmallestImagePixelValue);
    delete target.remove(DCM_LargestImagePixelValue);
    delete target.remove(DCM_PixelPaddingValue);
    delete target.remove(DCM_SmallestPixelValueInSeries);
    delete target.remove(DCM_LargestPixelValueInSeries);
    delete target.remove(DCM_PaletteColorLookupTableUID);
    delete target.remove(DCM_SegmentedRedPaletteColorLookupTableData);
    delete target.remove(DCM_SegmentedGreenPaletteColorLookupTableData);
    delete target.remove(DCM_SegmentedBluePaletteColorLookupTableData);
    delete target.remove(DCM_PlanarConfiguration);

    // UNIMPLEMENTED: frame increment pointer
    // UNIMPLEMENTED: pixel aspect ratio/pixel spacing/imager pixel spacing

    if (frames > 1)
    {
      char buf[20];
      sprintf(buf, "%u", frames);
      if (result.good()) result = target.putAndInsertString(DCM_NumberOfFrames, buf);
    }

    // create palette color LUT descriptor and data
    if (result.good()) result = colormap.write(target, writeAsOW, write16BitEntries);

    // create derivation description string
    if (result.good()) colormap.setDescriptionString(description);

    return result;
}


OFCondition DcmQuant::updateDerivationDescription(DcmItem *dataset, const char *description)
{
  if (description == NULL) return EC_IllegalCall;

  OFString derivationDescription(description);

  // append old Derivation Description, if any
  const char *oldDerivation = NULL;
  if ((dataset->findAndGetString(DCM_DerivationDescription, oldDerivation)).good() && oldDerivation)
  {
    derivationDescription += " [";
    derivationDescription += oldDerivation;
    derivationDescription += "]";
    if (derivationDescription.length() > 1024)
    {
      // ST is limited to 1024 characters, cut off tail
      derivationDescription.erase(1020);
      derivationDescription += "...]";
    }
  }

  return dataset->putAndInsertString(DCM_DerivationDescription, derivationDescription.c_str());
}


/*
 *
 * CVS/RCS Log:
 * $Log: diquant.cc,v $
 * Revision 1.1  2006/03/01 20:15:36  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.4  2005/12/08 15:42:33  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.3  2004/08/24 14:55:28  meichel
 * Removed duplicate code
 *
 * Revision 1.2  2003/12/17 16:34:57  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 *
 * Revision 1.1  2002/01/25 13:32:12  meichel
 * Initial release of new color quantization classes and
 *   the dcmquant tool in module dcmimage.
 *
 *
 */
