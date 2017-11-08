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
 *  Author:  Gerd Ehlers, Andreas Barth
 *
 *  Purpose: Implementation of class DcmPixelItem
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:22 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"    /* make sure OS specific configuration is included first */

#define INCLUDE_CSTDLIB
#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#include "ofstdinc.h"

#include "ofstream.h"
#include "dcpxitem.h"
#include "dcswap.h"
#include "ofstring.h"
#include "ofstd.h"
#include "dcistrma.h"    /* for class DcmInputStream */
#include "dcostrma.h"    /* for class DcmOutputStream */


// ********************************


DcmPixelItem::DcmPixelItem(const DcmTag &tag,
                           const Uint32 len)
  : DcmOtherByteOtherWord(tag, len)
{
    Tag.setVR(EVR_pixelItem);
}


DcmPixelItem::DcmPixelItem(const DcmPixelItem &old)
  : DcmOtherByteOtherWord(old)
{
}


DcmPixelItem::~DcmPixelItem()
{
}


// ********************************


OFCondition DcmPixelItem::writeTagAndLength(DcmOutputStream &outStream,
                                            const E_TransferSyntax oxfer,
                                            Uint32 &writtenBytes) const
{
    OFCondition l_error = outStream.status();
    if (l_error.good())
    {
        /* write tag information */
        l_error = writeTag(outStream, Tag, oxfer);
        writtenBytes = 4;
        /* prepare to write the value field */
        Uint32 valueLength = Length;
        DcmXfer outXfer(oxfer);
        /* check byte-ordering */
        const E_ByteOrder oByteOrder = outXfer.getByteOrder();
        if (oByteOrder == EBO_unknown)
        {
            return EC_IllegalCall;
        }
        swapIfNecessary(oByteOrder, gLocalByteOrder, &valueLength, 4, 4);
        // availability of four bytes space in output buffer
        // has been checked by caller.
        writtenBytes += outStream.write(&valueLength, 4);
    } else
        writtenBytes = 0;
    return l_error;
}


void DcmPixelItem::print(ostream &out,
                         const size_t flags,
                         const int level,
                         const char *pixelFileName,
                         size_t *pixelCounter)
{
    /* call inherited method */
    printPixel(out, flags, level, pixelFileName, pixelCounter);
}


OFCondition DcmPixelItem::createOffsetTable(const DcmOffsetList &offsetList)
{
    OFCondition result = EC_Normal;

    unsigned int numEntries = (unsigned int)offsetList.size();
    if (numEntries > 0)
    {
        Uint32 current = 0;
        Uint32 *array = new Uint32[numEntries];
        if (array)
        {
            OFListConstIterator(Uint32) first = offsetList.begin();
            OFListConstIterator(Uint32) last = offsetList.end();
            unsigned int idx = 0;
            while (first != last)
            {
                array[idx++] = current;
                current += *first;
                ++first;
            }
            result = swapIfNecessary(EBO_LittleEndian, gLocalByteOrder,
                array, numEntries * sizeof(Uint32), sizeof(Uint32));
            if (result.good())
                result = putUint8Array(OFreinterpret_cast(Uint8 *, array), numEntries * sizeof(Uint32));
            delete[] array;
        } else
            result = EC_MemoryExhausted;
    }
    return result;
}


OFCondition DcmPixelItem::writeXML(ostream &out,
                                   const size_t flags)
{
    /* XML start tag for "item" */
    out << "<pixel-item";
    /* value length in bytes = 0..max */
    out << " len=\"" << Length << "\"";
    /* value loaded = no (or absent)*/
    if (!valueLoaded())
        out << " loaded=\"no\"";
    /* pixel item contains binary data */
    if (!(flags & DCMTypes::XF_writeBinaryData))
        out << " binary=\"hidden\"";
    else if (flags & DCMTypes::XF_encodeBase64)
        out << " binary=\"base64\"";
    else
        out << " binary=\"yes\"";
    out << ">";
    /* write element value (if loaded) */
    if (valueLoaded() && (flags & DCMTypes::XF_writeBinaryData))
    {
        OFString value;
        /* encode binary data as Base64 */
        if (flags & DCMTypes::XF_encodeBase64)
        {
            /* pixel items always contain 8 bit data, therefore, byte swapping not required */
            out << OFStandard::encodeBase64(OFstatic_cast(Uint8 *, getValue()), OFstatic_cast(size_t, Length), value);
        } else {
            /* encode as sequence of hexadecimal numbers */
            if (getOFStringArray(value).good())
                out << value;
        }
    }
    /* XML end tag for "item" */
    out << "</pixel-item>" << endl;
    /* always report success */
    return EC_Normal;
}

OFCondition DcmPixelItem::writeSignatureFormat(
    DcmOutputStream & outStream,
    const E_TransferSyntax oxfer,
    const E_EncodingType enctype)
{
  if (dcmEnableOldSignatureFormat.get())
  {
      /* Old signature format as created by DCMTK releases previous to 3.5.4.
       * This is non-conformant because it includes the item length in pixel items.
       */
      return DcmOtherByteOtherWord::writeSignatureFormat(outStream, oxfer, enctype);
  }
  else
  {
      /* In case the transfer state is not initialized, this is an illegal call */
      if (fTransferState == ERW_notInitialized)
          errorFlag = EC_IllegalCall;
      else
      {
          /* if this is not an illegal call, we need to do something. First */
          /* of all, check the error state of the stream that was passed */
          /* only do something if the error state of the stream is ok */
          errorFlag = outStream.status();
          if (errorFlag.good())
          {
              /* create an object that represents the transfer syntax */
              DcmXfer outXfer(oxfer);
              /* get this element's value. Mind the byte ordering (little */
              /* or big endian) of the transfer syntax which shall be used */
              Uint8 *value = OFstatic_cast(Uint8 *, getValue(outXfer.getByteOrder()));
              /* if this element's transfer state is ERW_init (i.e. it has not yet been written to */
              /* the stream) and if the outstream provides enough space for tag and length information */
              /* write tag and length information to it, do something */
              if (fTransferState == ERW_init)
              {
                  /* first compare with DCM_TagInfoLength (12). If there is not enough space
                   * in the buffer, check if the buffer is still sufficient for the requirements
                   * of this element, which may need only 8 instead of 12 bytes.
                   */
                  if (outStream.avail() >= 4)
                  {
                      /* if there is no value, Length (member variable) shall be set to 0 */
                      if (!value) Length = 0;
      
                      /* write tag and length information (and possibly also data type information) to the stream, */
                      /* mind the transfer syntax and remember the amount of bytes that have been written */
                      errorFlag = writeTag(outStream, Tag, oxfer); 
      
                      /* if the writing was successful, set this element's transfer */
                      /* state to ERW_inWork and the amount of transferred bytes to 0 */
                      if (errorFlag.good())
                      {
                          fTransferState = ERW_inWork;
                          fTransferredBytes = 0;
                      }
                  } else
                      errorFlag = EC_StreamNotifyClient;
              }
              /* if there is a value that has to be written to the stream */
              /* and if this element's transfer state is ERW_inWork */
              if (value && fTransferState == ERW_inWork)
              {
                  /* write as many bytes as possible to the stream starting at value[fTransferredBytes] */
                  /* (note that the bytes value[0] to value[fTransferredBytes-1] have already been */
                  /* written to the stream) */
                  Uint32 len = outStream.write(&value[fTransferredBytes], Length - fTransferredBytes);
                  /* increase the amount of bytes which have been transfered correspondingly */
                  fTransferredBytes += len;
                  /* see if there is something fishy with the stream */
                  errorFlag = outStream.status();
                  /* if the amount of transferred bytes equals the length of the element's value, the */
                  /* entire value has been written to the stream. Thus, this element's transfer state */
                  /* has to be set to ERW_ready. If this is not the case but the error flag still shows */
                  /* an ok value, there was no more space in the stream and a corresponding return value */
                  /* has to be set. (Isn't the "else if" part superfluous?!?) */
                  if (fTransferredBytes == Length)
                      fTransferState = ERW_ready;
                  else if (errorFlag.good())
                      errorFlag = EC_StreamNotifyClient;
              }
          }
      }
  }

  /* return result value */
  return errorFlag;
}

/*
** CVS/RCS Log:
** $Log: dcpxitem.cc,v $
** Revision 1.1  2006/03/01 20:15:22  lpysher
** Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
**
** Revision 1.29  2005/12/08 15:41:27  meichel
** Changed include path schema for all DCMTK header files
**
** Revision 1.28  2005/11/24 12:50:59  meichel
** Fixed bug in code that prepares a byte stream that is fed into the MAC
**   algorithm when creating or verifying a digital signature. The previous
**   implementation was non-conformant when signatures included compressed
**   (encapsulated) pixel data because the item length was included in the byte
**   stream, while it should not. The global variable dcmEnableOldSignatureFormat
**   and a corresponding command line option in dcmsign allow to re-enable the old
**   implementation.
**
** Revision 1.27  2004/02/04 16:42:42  joergr
** Adapted type casts to new-style typecast operators defined in ofcast.h.
** Removed acknowledgements with e-mail addresses from CVS log.
**
** Revision 1.26  2003/06/12 18:21:46  joergr
** Modified code to use const_iterators where appropriate (required for STL).
**
** Revision 1.25  2002/12/06 13:16:59  joergr
** Enhanced "print()" function by re-working the implementation and replacing
** the boolean "showFullData" parameter by a more general integer flag.
** Made source code formatting more consistent with other modules/files.
**
** Revision 1.24  2002/11/27 12:06:51  meichel
** Adapted module dcmdata to use of new header file ofstdinc.h
**
** Revision 1.23  2002/08/27 16:55:55  meichel
** Initial release of new DICOM I/O stream classes that add support for stream
**   compression (deflated little endian explicit VR transfer syntax)
**
** Revision 1.22  2002/05/24 14:51:51  meichel
** Moved helper methods that are useful for different compression techniques
**   from module dcmjpeg to module dcmdata
**
** Revision 1.21  2002/05/14 08:21:52  joergr
** Added support for Base64 (MIME) encoded binary data.
**
** Revision 1.20  2002/04/25 10:25:49  joergr
** Added support for XML output of DICOM objects.
**
** Revision 1.19  2002/04/16 13:43:20  joergr
** Added configurable support for C++ ANSI standard includes (e.g. streams).
**
** Revision 1.18  2001/11/16 15:55:04  meichel
** Adapted digital signature code to final text of supplement 41.
**
** Revision 1.17  2001/09/25 17:19:53  meichel
** Adapted dcmdata to class OFCondition
**
** Revision 1.16  2001/06/01 15:49:08  meichel
** Updated copyright header
**
** Revision 1.15  2000/04/14 15:55:06  meichel
** Dcmdata library code now consistently uses ofConsole for error output.
**
** Revision 1.14  2000/03/08 16:26:40  meichel
** Updated copyright header.
**
** Revision 1.13  2000/03/03 14:05:35  meichel
** Implemented library support for redirecting error messages into memory
**   instead of printing them to stdout/stderr for GUI applications.
**
** Revision 1.12  2000/02/23 15:12:00  meichel
** Corrected macro for Borland C++ Builder 4 workaround.
**
** Revision 1.11  2000/02/10 10:52:22  joergr
** Added new feature to dcmdump (enhanced print method of dcmdata): write
** pixel data/item value fields to raw files.
**
** Revision 1.10  2000/02/03 16:31:26  joergr
** Fixed bug: encapsulated data (pixel items) have never been loaded using
** method 'loadAllDataIntoMemory'. Therefore, encapsulated pixel data was
** never printed with 'dcmdump'.
** Corrected bug that caused wrong calculation of group length for sequence
** of items (e.g. encapsulated pixel data).
**
** Revision 1.9  2000/02/01 10:12:09  meichel
** Avoiding to include <stdlib.h> as extern "C" on Borland C++ Builder 4,
**   workaround for bug in compiler header files.
**
** Revision 1.8  1999/03/31 09:25:37  meichel
** Updated copyright header in module dcmdata
**
** Revision 1.7  1998/11/12 16:48:19  meichel
** Implemented operator= for all classes derived from DcmObject.
**
** Revision 1.6  1997/07/07 07:52:29  andreas
** - Enhanced (faster) byte swapping routine. swapIfNecessary moved from
**   a method in DcmObject to a general function.
**
** Revision 1.5  1997/07/03 15:10:03  andreas
** - removed debugging functions Bdebug() and Edebug() since
**   they write a static array and are not very useful at all.
**   Cdebug and Vdebug are merged since they have the same semantics.
**   The debugging functions in dcmdata changed their interfaces
**   (see dcmdata/include/dcdebug.h)
**
** Revision 1.4  1997/05/22 16:57:16  andreas
** - Corrected errors for writing of pixel sequences for encapsulated
**   transfer syntaxes.
**
** Revision 1.3  1996/01/05 13:27:41  andreas
** - changed to support new streaming facilities
** - unique read/write methods for file and block transfer
** - more cleanups
**
*/
