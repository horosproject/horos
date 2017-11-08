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
 *  Purpose:
 *    This file contains the interface to routines which provide
 *    DICOM object encoding/decoding, search and lookup facilities.
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
#include "ofstd.h"
#include "ofstream.h"
#include "dcobject.h"
#include "dcvr.h"
#include "dcxfer.h"
#include "dcswap.h"
#include "dcdebug.h"
#include "dcistrma.h"    /* for class DcmInputStream */
#include "dcostrma.h"    /* for class DcmOutputStream */

#define INCLUDE_CSTDIO
#define INCLUDE_IOMANIP
#include "ofstdinc.h"


// global flags

OFGlobal<OFBool> dcmEnableAutomaticInputDataCorrection(OFTrue);
OFGlobal<OFBool> dcmAcceptOddAttributeLength(OFTrue);
OFGlobal<OFBool> dcmEnableCP246Support(OFTrue);
OFGlobal<OFBool> dcmEnableOldSignatureFormat(OFFalse);
OFGlobal<OFBool> dcmAutoDetectDatasetXfer(OFFalse);

// ****** public methods **********************************


DcmObject::DcmObject(const DcmTag &tag,
                     const Uint32 len)
  : Tag(tag),
    Length(len),
    fTransferState(ERW_init),
    errorFlag(EC_Normal),
    fTransferredBytes(0)
{
}


DcmObject::DcmObject(const DcmObject &obj)
  : Tag(obj.Tag),
    Length(obj.Length),
    fTransferState(obj.fTransferState),
    errorFlag(obj.errorFlag),
    fTransferredBytes(obj.fTransferredBytes)
{
}


DcmObject::~DcmObject()
{
}


DcmObject &DcmObject::operator=(const DcmObject &obj)
{
    Tag = obj.Tag;
    Length = obj.Length;
    errorFlag = obj.errorFlag;
    fTransferState = obj.fTransferState;
    fTransferredBytes = obj.fTransferredBytes;
    return *this;
}


// ********************************


void DcmObject::transferInit()
{
    fTransferState = ERW_init;
    fTransferredBytes = 0;
}


void DcmObject::transferEnd()
{
    fTransferState = ERW_notInitialized;
}


// ********************************


DcmObject * DcmObject::nextInContainer(const DcmObject * /*obj*/)
{
    return NULL;
}


OFCondition DcmObject::nextObject(DcmStack & /*stack*/,
                                  const OFBool /*intoSub*/)
{
    return EC_TagNotFound;
}


// ********************************


OFCondition DcmObject::search(const DcmTagKey &/*tag*/,
                              DcmStack &/*resultStack*/,
                              E_SearchMode /*mode*/,
                              OFBool /*searchIntoSub*/)
{
   return EC_TagNotFound;
}


OFCondition DcmObject::searchErrors(DcmStack &resultStack)
{
    if (errorFlag.bad())
        resultStack.push(this);
    return errorFlag;
}


// ********************************


OFCondition DcmObject::writeXML(ostream & /*out*/,
                                const size_t /*flags*/)
{
    return EC_IllegalCall;
}


// ***********************************************************
// ****** protected methods **********************************
// ***********************************************************


void DcmObject::printNestingLevel(ostream &out,
                                  const size_t flags,
                                  const int level)
{
    if (flags & DCMTypes::PF_showTreeStructure)
    {
        /* special treatment for the last entry on the level */
        if (flags & DCMTypes::PF_lastEntry)
        {
            /* show vertical bar for the tree structure */
            for (int i = 2; i < level; i++)
                out << "| ";
            /* show juncture sign for the last entry */
            if (level > 0)
                out << "+ ";
        } else {
            /* show vertical bar for the tree structure */
            for (int i = 1; i < level; i++)
                out << "| ";
        }
    } else {
        /* show nesting level */
        for (int i = 1; i < level; i++)
            out << "  ";
    }
}


void DcmObject::printInfoLineStart(ostream &out,
                                   const size_t flags,
                                   const int level,
                                   DcmTag *tag)
{
    /* default: use object's tag */
    if (tag == NULL)
        tag = &Tag;
    DcmVR vr(tag->getVR());
    /* show nesting level */
    printNestingLevel(out, flags, level);
    if (flags & DCMTypes::PF_showTreeStructure)
    {
        /* print tag name */
        out << tag->getTagName() << ' ';
        /* add padding spaces if required */
        const signed int padLength = 35 - (int)strlen(tag->getTagName()) - 2 * level;
        if (padLength > 0)
            out << OFString(OFstatic_cast(size_t, padLength), ' ');
    } else {
        /* print line start: tag and VR */
        out << hex << setfill('0') << "("
            << setw(4) << tag->getGTag() << ","
            << setw(4) << tag->getETag() << ") "
            << dec << setfill(' ')
            << vr.getVRName() << " ";
    }
}


void DcmObject::printInfoLineEnd(ostream &out,
                                 const size_t flags,
                                 const unsigned int printedLength,
                                 DcmTag *tag)
{
    unsigned int vm = 0;
    unsigned int length = 0;
    /* default: use object's tag, VM and length */
    if (tag == NULL)
    {
        tag = &Tag;
        vm = getVM();
        length = Length;
    }
    if (flags & DCMTypes::PF_showTreeStructure)
    {
        /* finish the current line */
        out << endl;
    } else {
        /* fill with spaces if necessary */
        if (printedLength < DCM_OptPrintValueLength)
            out << OFString(OFstatic_cast(size_t, DCM_OptPrintValueLength - printedLength), ' ');
        /* print line end: length, VM and tag name */
        out << " # ";
        if (length == DCM_UndefinedLength)
            out << "u/l";   // means "undefined/length"
        else
            out << setw(3) << length;
        out << ","
            << setw(2) << vm << " "
            << tag->getTagName() << endl;
    }
}


void DcmObject::printInfoLine(ostream &out,
                              const size_t flags,
                              const int level,
                              const char *info,
                              DcmTag *tag)
{
    /* print tag and VR */
    printInfoLineStart(out, flags, level, tag);
    /* check whether info text fits into the limit */
    unsigned int printedLength = 0;
    /* check for valid info text */
    if (info != NULL)
    {
        /* check info text length */
        printedLength = (unsigned int)strlen(info);
        if (printedLength > DCM_OptPrintValueLength)
        {
            /* check whether full info text should be printed */
            if ((flags & DCMTypes::PF_shortenLongTagValues) && (printedLength > DCM_OptPrintLineLength))
            {
                char output[DCM_OptPrintLineLength + 1];
                /* truncate info text and append "..." */
                OFStandard::strlcpy(output, info, OFstatic_cast(size_t, DCM_OptPrintLineLength) - 3 /* for "..." */ + 1);
                OFStandard::strlcat(output, "...", OFstatic_cast(size_t, DCM_OptPrintLineLength) + 1);
                out << output;
                printedLength = DCM_OptPrintLineLength;
            } else
                out << info;
        } else
            out << info;
    }
    /* print length, VM and tag name */
    printInfoLineEnd(out, flags, printedLength, tag);
}


// ********************************


OFCondition DcmObject::writeTag(DcmOutputStream &outStream,
                                const DcmTag &tag,
                                const E_TransferSyntax oxfer)
    /*
     * This function writes the tag information which was passed to the stream. When
     * writing information, the transfer syntax which was passed is accounted for.
     *
     * Parameters:
     *   outStream - [out] The stream that the information will be written to.
     *   tag       - [in] The tag which shall be written.
     *   oxfer     - [in] The transfer syntax which shall be used.
     */
{
    /* create an object which represents the transfer syntax */
    DcmXfer outXfer(oxfer);
    /* determine the byte ordering */
    const E_ByteOrder outByteOrder = outXfer.getByteOrder();
    /* if the byte ordering is unknown, this is an illegal call (return error) */
    if (outByteOrder == EBO_unknown)
        return EC_IllegalCall;
    /* determine the group number, mind the transfer syntax and */
    /* write the group number value (2 bytes) to the stream */
    Uint16 groupTag = tag.getGTag();
    swapIfNecessary(outByteOrder, gLocalByteOrder, &groupTag, 2, 2);
    outStream.write(&groupTag, 2);
    /* determine the element number, mind the transfer syntax and */
    /* write the element number value (2 bytes) to the stream */
    Uint16 elementTag = tag.getETag();    // 2 byte length;
    swapIfNecessary(outByteOrder, gLocalByteOrder, &elementTag, 2, 2);
    outStream.write(&elementTag, 2);
    /* if the stream reports an error return this error, else return ok */
    return outStream.status();
}


Uint32 DcmObject::getTagAndLengthSize(const E_TransferSyntax oxfer) const
{
    /* create an object which represents the transfer syntax */
    DcmXfer oxferSyn(oxfer);

    if (oxferSyn.isExplicitVR())
    {
       /* map "UN" to "OB" if generation of "UN" is disabled */  
       DcmVR outvr(getTag().getVR().getValidEVR());

       if (outvr.usesExtendedLengthEncoding())
       {
         return 12;
       }
    }
    return 8;
}


OFCondition DcmObject::writeTagAndLength(DcmOutputStream &outStream,
                                         const E_TransferSyntax oxfer,
                                         Uint32 &writtenBytes) const
    /*
     * This function writes this DICOM object's tag and length information to the stream. When
     * writing information, the transfer syntax which was passed is accounted for. If the transfer
     * syntax shows an explicit value representation, the data type of this object is also written
     * to the stream. In general, this function follows the rules which are specified in the DICOM
     * standard (see DICOM standard (year 2000) part 5, section 7) (or the corresponding section
     * in a later version of the standard) concerning the encoding of a data set which shall be
     * transmitted.
     *
     * Parameters:
     *   outStream    - [out] The stream that the information will be written to.
     *   oxfer        - [in] The transfer syntax which shall be used.
     *   writtenBytes - [out] Contains in the end the amount of bytes which have been written to the stream.
     */
{
    /* check the error status of the stream. If it is not ok, nothing can be done */
    OFCondition l_error = outStream.status();
    if (l_error.bad())
    {
        writtenBytes = 0;
    } else {
        /* if the stream is ok, we need to do something */

        /* write the tag information (a total of 4 bytes, group number and element */
        /* number) to the stream. Mind the transfer syntax's byte ordering. */
        l_error = writeTag(outStream, Tag, oxfer);
        writtenBytes = 4;

        /* create an object which represents the transfer syntax */
        DcmXfer oxferSyn(oxfer);

        /* determine the byte ordering */
        const E_ByteOrder oByteOrder = oxferSyn.getByteOrder();

        /* if the byte ordering is unknown, this is an illegal call (return error) */
        if (oByteOrder == EBO_unknown)
            return EC_IllegalCall;

        /* if the transfer syntax is one with explicit value representation */
        /* this value's data type also has to be written to the stream. Do so */
        /* and also write the length information to the stream. */
        if (oxferSyn.isExplicitVR())
        {
            /* Create an object that represents this object's data type */
            DcmVR myvr(getVR());

            /* getValidEVR() will convert datatype "UN" to "OB" if generation of "UN" is disabled */
            DcmEVR vr = myvr.getValidEVR();

            /* get name of data type */
            const char *vrname = myvr.getValidVRName();

            /* write data type name to the stream (a total of 2 bytes) */
            outStream.write(vrname, 2);
            writtenBytes += 2;

            /* create another data type object on the basis of the above created object */
            DcmVR outvr(vr);

            /* in case we are dealing with a transfer syntax with explicit VR (see if above) */
            /* and the actual VR uses extended length encoding (see DICOM standard (year 2000) */
            /* part 5, section 7.1.2) (or the corresponding section in a later version of the */
            /* standard) we have to add 2 reserved bytes (set to a value of 00H) to the data */
            /* type field and the actual length field is 4 bytes wide. Write the corresponding */
            /* information to the stream. */
            if (outvr.usesExtendedLengthEncoding())
            {
                Uint16 reserved = 0;
                outStream.write(&reserved, 2);                                      // write 2 reserved bytes to stream
                Uint32 valueLength = Length;                                        // determine length
                swapIfNecessary(oByteOrder, gLocalByteOrder, &valueLength, 4, 4);   // mind transfer syntax
                outStream.write(&valueLength, 4);                                   // write length, 4 bytes wide
                writtenBytes += 6;                                                  // remember that 6 bytes were written in total
            }
            /* in case that we are dealing with a transfer syntax with explicit VR (see if above) and */
            /* the actual VR does not use extended length encoding (see DICOM standard (year 2000) */
            /* part 5, section 7.1.2) (or the corresponding section in a later version of the standard) */
            /* we do not have to add reserved bytes to the data type field and the actual length field */
            /* is 2 bytes wide. Write the corresponding information to the stream. */
            else {
                Uint16 valueLength = OFstatic_cast(Uint16, Length);                 // determine length
                swapIfNecessary(oByteOrder, gLocalByteOrder, &valueLength, 2, 2);   // mind transfer syntax
                outStream.write(&valueLength, 2);                                   // write length, 2 bytes wide
                writtenBytes += 2;                                                  // remember that 2 bytes were written in total
            }
         }
         /* if the transfer syntax is one with implicit value representation this value's data type */
         /* does not have to be written to the stream. Only the length information has to be written */
         /* to the stream. According to the DICOM standard the length field is in this case always 4 */
         /* byte wide. (see DICOM standard (year 2000) part 5, section 7.1.2) (or the corresponding */
         /* section in a later version of the standard) */
         else {
            Uint32 valueLength = Length;                                          // determine length
            swapIfNecessary(oByteOrder, gLocalByteOrder, &valueLength, 4, 4);     // mind transfer syntax
            outStream.write(&valueLength, 4);                                     // write length, 4 bytes wide
            writtenBytes += 4;                                                    // remember that 4 bytes were written in total
         }
    }

    /* return result */
    return l_error;
}


OFBool DcmObject::isSignable() const
{
    return Tag.isSignable();
}


OFBool DcmObject::containsUnknownVR() const
{
    return Tag.isUnknownVR();
}


/*
 * CVS/RCS Log:
 * $Log: dcobject.cc,v $
 * Revision 1.1  2006/03/01 20:15:22  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.45  2005/12/08 15:41:19  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.44  2005/12/02 08:53:57  joergr
 * Changed macro NO_XFER_DETECTION_FOR_DATASETS into a global option that can
 * be enabled and disabled at runtime.
 *
 * Revision 1.43  2005/11/24 12:50:59  meichel
 * Fixed bug in code that prepares a byte stream that is fed into the MAC
 *   algorithm when creating or verifying a digital signature. The previous
 *   implementation was non-conformant when signatures included compressed
 *   (encapsulated) pixel data because the item length was included in the byte
 *   stream, while it should not. The global variable dcmEnableOldSignatureFormat
 *   and a corresponding command line option in dcmsign allow to re-enable the old
 *   implementation.
 *
 * Revision 1.42  2005/05/10 15:27:18  meichel
 * Added support for reading UN elements with undefined length according
 *   to CP 246. The global flag dcmEnableCP246Support allows to revert to the
 *   prior behaviour in which UN elements with undefined length were parsed
 *   like a normal explicit VR SQ element.
 *
 * Revision 1.41  2004/04/27 09:21:27  wilkens
 * Fixed a bug in dcelem.cc which occurs when one is serializing a dataset
 * (that contains an attribute whose length value is coded with 2 bytes) into
 * a given buffer. Although the number of available bytes in the buffer was
 * sufficient, the dataset->write(...) method would always return
 * EC_StreamNotifyClient to indicate that there are not sufficient bytes
 * available in the buffer. This code modification fixes the problem.
 *
 * Revision 1.40  2004/02/04 16:35:46  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Removed acknowledgements with e-mail addresses from CVS log.
 *
 * Revision 1.39  2002/12/06 13:15:12  joergr
 * Enhanced "print()" function by re-working the implementation and replacing
 * the boolean "showFullData" parameter by a more general integer flag.
 * Made source code formatting more consistent with other modules/files.
 *
 * Revision 1.38  2002/11/27 12:06:49  meichel
 * Adapted module dcmdata to use of new header file ofstdinc.h
 *
 * Revision 1.37  2002/08/27 16:55:52  meichel
 * Initial release of new DICOM I/O stream classes that add support for stream
 *   compression (deflated little endian explicit VR transfer syntax)
 *
 * Revision 1.36  2002/08/20 12:18:48  meichel
 * Changed parameter list of loadFile and saveFile methods in class
 *   DcmFileFormat. Removed loadFile and saveFile from class DcmObject.
 *
 * Revision 1.35  2002/07/08 14:44:40  meichel
 * Improved dcmdata behaviour when reading odd tag length. Depending on the
 *   global boolean flag dcmAcceptOddAttributeLength, the parser now either accepts
 *   odd length attributes or implements the old behaviour, i.e. assumes a real
 *   length larger by one.
 *
 * Revision 1.34  2002/04/25 10:17:19  joergr
 * Added support for XML output of DICOM objects.
 *
 * Revision 1.33  2002/04/16 13:43:19  joergr
 * Added configurable support for C++ ANSI standard includes (e.g. streams).
 *
 * Revision 1.32  2002/04/11 12:27:10  joergr
 * Added new methods for loading and saving DICOM files.
 *
 * Revision 1.31  2001/11/16 15:55:03  meichel
 * Adapted digital signature code to final text of supplement 41.
 *
 * Revision 1.30  2001/11/01 14:55:41  wilkens
 * Added lots of comments.
 *
 * Revision 1.29  2001/09/25 17:19:52  meichel
 * Adapted dcmdata to class OFCondition
 *
 * Revision 1.28  2001/06/01 15:49:06  meichel
 * Updated copyright header
 *
 * Revision 1.27  2000/04/14 16:10:09  meichel
 * Global flag dcmEnableAutomaticInputDataCorrection now derived from OFGlobal
 *   and, thus, safe for use in multi-thread applications.
 *
 * Revision 1.26  2000/03/08 16:26:38  meichel
 * Updated copyright header.
 *
 * Revision 1.25  2000/03/07 15:41:00  joergr
 * Added explicit type casts to make Sun CC 2.0.1 happy.
 *
 * Revision 1.24  2000/02/10 10:52:20  joergr
 * Added new feature to dcmdump (enhanced print method of dcmdata): write
 * pixel data/item value fields to raw files.
 *
 * Revision 1.23  2000/02/01 10:12:09  meichel
 * Avoiding to include <stdlib.h> as extern "C" on Borland C++ Builder 4,
 *   workaround for bug in compiler header files.
 *
 * Revision 1.22  1999/03/31 09:25:34  meichel
 * Updated copyright header in module dcmdata
 *
 *
 */
