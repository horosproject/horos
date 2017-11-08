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
 *  Purpose: Implementation of class DcmByteString
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:19 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "ofstream.h"
#include "ofstring.h"
#include "ofstd.h"
#include "dcbytstr.h"
#include "dcvr.h"
#include "dcdebug.h"

#define INCLUDE_CSTDLIB
#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#define INCLUDE_NEW
#include "ofstdinc.h"


// ********************************


DcmByteString::DcmByteString(const DcmTag &tag,
                             const Uint32 len)
  : DcmElement(tag, len),
    paddingChar(' '),
    maxLength(DCM_UndefinedLength),
    realLength(len),
    fStringMode(DCM_UnknownString)
{
}


DcmByteString::DcmByteString(const DcmByteString &old)
  : DcmElement(old),
    paddingChar(old.paddingChar),
    maxLength(old.maxLength),
    realLength(old.realLength),
    fStringMode(old.fStringMode)
{
}


DcmByteString::~DcmByteString()
{
}


DcmByteString &DcmByteString::operator=(const DcmByteString &obj)
{
    DcmElement::operator=(obj);
    /* copy member variables */
    realLength = obj.realLength;
    fStringMode = obj.fStringMode;
    paddingChar = obj.paddingChar;
    maxLength = obj.maxLength;
    return *this;
}


// ********************************


DcmEVR DcmByteString::ident() const
{
    /* valid type identifier is set by derived classes */
    return EVR_UNKNOWN;
}


unsigned int DcmByteString::getVM()
{
    char *s = NULL;
    /* get stored string value */
    getString(s);
    unsigned int vm = 0;
    /*  check for empty string */
    if ((s == NULL) || (Length == 0))
        vm = 0;
    else
    {
        /* count number of delimiters */
        vm = 1;
        char c;
        while ((c = *s++) != 0)
        {
            if (c == '\\')
                vm++;
        }
    }
    return vm;
}


OFCondition DcmByteString::clear()
{
    /* call inherited method */
    errorFlag = DcmElement::clear();
    /* set string representation to unknown */
    fStringMode = DCM_UnknownString;
    return errorFlag;
}


Uint32 DcmByteString::getRealLength()
{
    /* convert string to internal representation (if required) */
    if (fStringMode != DCM_MachineString)
    {
        /* strips non-significant trailing spaces (padding) and determines 'realLength' */
        makeMachineByteString();
    }
    /* strig length of the internal representation */
    return realLength;
}


Uint32 DcmByteString::getLength(const E_TransferSyntax /*xfer*/,
                                const E_EncodingType /*enctype*/)
{
    /* convert string to DICOM representation, i.e. add padding if required */
    makeDicomByteString();
    /* DICOM value length is always an even number */
    return Length;
}


// ********************************


void DcmByteString::print(ostream &out,
                          const size_t flags,
                          const int level,
                          const char * /*pixelFileName*/,
                          size_t * /*pixelCounter*/)
{
    if (valueLoaded())
    {
        /* get string data */
        char *string = NULL;
        getString(string);
        if (string != NULL)
        {
            unsigned int printedLength = (unsigned int)strlen(string) + 2 /* for enclosing brackets */;
            /* print line start with tag and VR */
            printInfoLineStart(out, flags, level);
            out << '[';
            /* check whether full value text should be printed */
            if ((flags & DCMTypes::PF_shortenLongTagValues) && (printedLength > DCM_OptPrintLineLength))
            {
                char output[DCM_OptPrintLineLength - 1 /* for "[" */ + 1];
                /* truncate value text and append "..." */
                OFStandard::strlcpy(output, string, OFstatic_cast(size_t, DCM_OptPrintLineLength) - 4 /* for "[" and "..." */ + 1);
                OFStandard::strlcat(output, "...", OFstatic_cast(size_t, DCM_OptPrintLineLength) - 1 /* for "[" */ + 1);
                out << output;
                printedLength = DCM_OptPrintLineLength;
            } else
                out << string << ']';
            /* print line end with length, VM and tag name */
            printInfoLineEnd(out, flags, printedLength);
        } else
            printInfoLine(out, flags, level, "(no value available)" );
    } else
        printInfoLine(out, flags, level, "(not loaded)" );
}


// ********************************


OFCondition DcmByteString::write(DcmOutputStream &outStream,
                                 const E_TransferSyntax writeXfer,
                                 const E_EncodingType encodingType)
{
    if (fTransferState == ERW_notInitialized)
        errorFlag = EC_IllegalCall;
    else
    {
        /* convert string value to DICOM representation and call inherited method */
        if (fTransferState == ERW_init)
            makeDicomByteString();
        errorFlag = DcmElement::write(outStream, writeXfer, encodingType);
    }
    return errorFlag;
}


OFCondition DcmByteString::writeSignatureFormat(DcmOutputStream &outStream,
                                                const E_TransferSyntax writeXfer,
                                                const E_EncodingType encodingType)
{
    if (fTransferState == ERW_notInitialized)
        errorFlag = EC_IllegalCall;
    else
    {
        /* convert string value to DICOM representation and call inherited method */
        if (fTransferState == ERW_init)
            makeDicomByteString();
        errorFlag = DcmElement::writeSignatureFormat(outStream, writeXfer, encodingType);
    }
    return errorFlag;
}


// ********************************


OFCondition DcmByteString::getOFString(OFString &stringVal,
                                       const unsigned int pos,
                                       OFBool /*normalize*/)
{
    errorFlag = EC_Normal;
    /* check given string position index */
    if (pos >= getVM())
        errorFlag = EC_IllegalParameter;
    else
    {
        /* get string data */
        char *s = OFstatic_cast(char *, getValue());
        /* extract specified string component */
        errorFlag = getStringPart(stringVal, s, pos);
    }
    return errorFlag;
}


OFCondition DcmByteString::getStringValue(OFString &stringVal)
{
    const char *s = OFstatic_cast(char *, getValue());
    /* check whether string value is present */
    if (s != NULL)
        stringVal = s;
    else {
        /* return empty string in case of empty value field */
        stringVal = "";
    }
    return errorFlag;
}


OFCondition DcmByteString::getString(char *&stringVal)
{
    /* get string data */
    stringVal = OFstatic_cast(char *, getValue());
    /* convert to internal string representation (without padding) if required */
    if ((stringVal != NULL) && (fStringMode != DCM_MachineString))
        makeMachineByteString();
    return errorFlag;
}


// ********************************


OFCondition DcmByteString::putString(const char *stringVal)
{
    errorFlag = EC_Normal;
    /* check for an empty string parameter */
    if ((stringVal != NULL) && (strlen(stringVal) > 0))
        putValue(stringVal, (Uint32)strlen(stringVal));
    else
        putValue(NULL, 0);
    /* make sure that extra padding is removed from the string */
    fStringMode = DCM_UnknownString;
    makeMachineByteString();
    return errorFlag;
}


OFCondition DcmByteString::putOFStringArray(const OFString &stringVal)
{
    /* sets the value of a complete (possibly multi-valued) string attribute */
    return putString(stringVal.c_str());
}


// ********************************


OFCondition DcmByteString::makeDicomByteString()
{
    /* get string data */
    char *value = NULL;
    errorFlag = getString(value);
    if (value != NULL)
    {
        /* check for odd length */
        if (realLength & 1)
        {
            /* if so add a padding character */
            Length = realLength + 1;
            value[realLength] = paddingChar;
        } else if (realLength < Length)
            Length = realLength;
        /* terminate string (removes additional trailing padding characters) */
        value[Length] = '\0';
    }
    /* current string representation is now the DICOM one */
    fStringMode = DCM_DicomString;
    return errorFlag;
}


OFCondition DcmByteString::makeMachineByteString()
{
    errorFlag = EC_Normal;
    /* get string data */
    char *value = OFstatic_cast(char *, getValue());
    /* determine initial string length */
    if (value != NULL)
    {
        realLength = (Uint32)strlen(value);
        /* remove all trailing spaces if automatic input data correction is enabled */
        if (dcmEnableAutomaticInputDataCorrection.get())
        {
            /*
            ** This code removes extra padding chars at the end of
            ** a ByteString.  Trailing padding can cause problems
            ** when comparing strings.
            */
            if (realLength > 0)
            {
                size_t i = 0;
                for(i = OFstatic_cast(size_t, realLength); (i > 0) && (value[i - 1] == paddingChar); i--)
                    value[i - 1] = '\0';
                realLength = OFstatic_cast(Uint32, i);
            }
        }
    } else
        realLength = 0;
    /* current string representation is now the internal one */
    fStringMode = DCM_MachineString;
    return errorFlag;
}


// ********************************


Uint8 *DcmByteString::newValueField()
{
    Uint8 *value = NULL;
    /* check for odd length (in case of a protocol error) */
    if (Length & 1)
    {
        /* allocate space for extra padding character (required for the DICOM representation of the string) */
#ifdef HAVE_STD__NOTHROW
        // we want to use a non-throwing new here if available.
        // If the allocation fails, we report an EC_MemoryExhausted error
        // back to the caller.
        value = new (std::nothrow) Uint8[Length + 2];
#else
        try {
            value = new Uint8[Length + 2];
        } catch (...) {
            value = NULL;
        }
        
#endif

        /* terminate string after real length */
        if (value != NULL)
            value[Length] = 0;
        /* enforce old (pre DCMTK 3.5.2) behaviour? */
        if (!dcmAcceptOddAttributeLength.get())
        {
            /* make length even */
            Length++;
        }
    } else {
        /* length is even */
#ifdef HAVE_STD__NOTHROW
        // we want to use a non-throwing new here if available.
        // If the allocation fails, we report an EC_MemoryExhausted error
        // back to the caller.
        value = new (std::nothrow) Uint8[Length + 1];
#else
        try {
            value = new Uint8[Length + 1];
        } catch (...) {
            value = NULL;
        }
#endif
    }
    /* make sure that the string is properly terminates by a 0 byte */
    if (value != NULL)
        value[Length] = 0;
    return value;
}


// ********************************


void DcmByteString::postLoadValue()
{
    /* initially, after loading an attribute the string mode is unknown */
    fStringMode = DCM_UnknownString;
    /* correct value length if automatic input data correction is enabled */
    if (dcmEnableAutomaticInputDataCorrection.get())
    {
        /* check for odd length */
        if (Length & 1)
        {
            // newValueField always allocates an even number of bytes and sets
            // the pad byte to zero, so we can safely increase Length here.
            Length++;
        }
    }
}


// ********************************


OFCondition DcmByteString::verify(const OFBool autocorrect)
{
    char *value = NULL;
    /* get string data */
    errorFlag = getString(value);
    /* check for non-empty string */
    if ((value != NULL) && (realLength != 0))
    {
        /* create a temporary buffer for the string value */
        char *tempstr = new char[realLength + 1];
        unsigned int field = 0;
        unsigned int num = getVM();
        unsigned int pos = 0;
        unsigned int temppos = 0;
        char c;
        /* check all string components */
        while (field < num )
        {
            unsigned int fieldlen = 0;
            /* check size limit for each string component */
            while (((c = value[pos++]) != 0) && (c != '\\'))
            {
                if ((fieldlen < maxLength) && autocorrect)
                    tempstr[temppos++] = c;
                fieldlen++;
            }
            if (fieldlen >= maxLength)
                errorFlag = EC_CorruptedData;
            /* 'c' is either '\\' or NULL */
            if (autocorrect)
                tempstr[temppos++] = c;
            field++;
            if (pos > Length)
                break;
        }
        /* replace current string value if auto correction is enabled */
        if (autocorrect)
            putString(tempstr);
        delete[] tempstr;
    }
    /* report a debug message if an error occurred */
    DCM_dcmdataCDebug(3, errorFlag.bad(),
            ("DcmByteString::verify: Illegal values in Tag=(0x%4.4x,0x%4.4x) VM=%d",
            getGTag(), getETag(), getVM() ));
    return errorFlag;
}


// ********************************


// global function to get a particular component of a DICOM string
OFCondition getStringPart(OFString &result,
                          const char *orgStr,
                          const unsigned int pos)
{
    OFCondition l_error = EC_Normal;
    /* check string parameter */
    if (orgStr != NULL)
    {
        /* search for beginning of specified string component  */
        unsigned int i = 0;
        while ((i < pos) && (*orgStr != '\0'))
        {
            if (*orgStr++ == '\\')
                i++;
        }
        /* if found ... */
        if (i == pos)
        {
            /* search for end of specified string component  */
            const char *t = orgStr;
            while ((*t != '\0') && (*t != '\\'))
                t++;
            /* check whether string component is non-empty */
            if (t - orgStr > 0)
                result.assign(orgStr, t - orgStr);
            else
                result = "";
        } else {
            /* specified component index not found in string */
            l_error = EC_IllegalParameter;
        }
    } else
        l_error = EC_IllegalParameter;
    return l_error;
}


// global function for normalizing a DICOM string
void normalizeString(OFString &string,
                     const OFBool multiPart,
                     const OFBool leading,
                     const OFBool trailing)
{
    /* check for non-empty string */
    if (!string.empty())
    {
        size_t partindex = 0;
        size_t offset = 0;
        size_t len = string.length();
        while (partindex < len)
        {
            // remove leading spaces in every part of the string
            if (leading)
            {
                offset = 0;
                while ((partindex + offset < len) && (string[partindex + offset] == ' '))
                    offset++;
                if (offset > 0)
                    string.erase(partindex, offset);
            }
            len = string.length();
            // compute begin to the next separator index!
            if (multiPart)
            {
                partindex = string.find('\\', partindex);
                if (partindex == OFString_npos)
                    partindex = len;
            } else
                partindex = len;
            // remove trailing spaces in every part of the string
            if (trailing && partindex)
            {
                offset = partindex - 1;
                while ((offset > 0) && (string[offset] == ' '))
                    offset--;
                if (offset != partindex - 1)
                {
                    if (string[offset] == ' ')
                    {
                        string.erase(offset, partindex - offset);
                        partindex = offset;
                    } else {
                        string.erase(offset+1, partindex - offset-1);
                        partindex = offset+1;
                    }
                }
            }
            len = string.length();
            if (partindex != len)
                ++partindex;
        }
    }
}


/*
** CVS/RCS Log:
** $Log: dcbytstr.cc,v $
** Revision 1.1  2006/03/01 20:15:19  lpysher
** Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
**
** Revision 1.40  2005/12/08 15:40:56  meichel
** Changed include path schema for all DCMTK header files
**
** Revision 1.39  2005/11/28 15:53:13  meichel
** Renamed macros in dcdebug.h
**
** Revision 1.38  2004/02/04 16:10:49  joergr
** Adapted type casts to new-style typecast operators defined in ofcast.h.
** Removed acknowledgements with e-mail addresses from CVS log.
**
** Revision 1.37  2003/12/11 13:40:46  meichel
** newValueField() now uses std::nothrow new if available
**
** Revision 1.36  2002/12/06 13:07:28  joergr
** Enhanced "print()" function by re-working the implementation and replacing
** the boolean "showFullData" parameter by a more general integer flag.
** Made source code formatting more consistent with other modules/files.
**
** Revision 1.35  2002/11/27 12:06:42  meichel
** Adapted module dcmdata to use of new header file ofstdinc.h
**
** Revision 1.34  2002/08/27 16:55:43  meichel
** Initial release of new DICOM I/O stream classes that add support for stream
**   compression (deflated little endian explicit VR transfer syntax)
**
** Revision 1.33  2002/07/08 14:44:38  meichel
** Improved dcmdata behaviour when reading odd tag length. Depending on the
**   global boolean flag dcmAcceptOddAttributeLength, the parser now either accepts
**   odd length attributes or implements the old behaviour, i.e. assumes a real
**   length larger by one.
**
** Revision 1.32  2002/04/25 10:13:47  joergr
** Removed getOFStringArray() implementation.
**
** Revision 1.31  2002/04/16 13:43:14  joergr
** Added configurable support for C++ ANSI standard includes (e.g. streams).
**
** Revision 1.30  2001/09/25 17:19:46  meichel
** Adapted dcmdata to class OFCondition
**
** Revision 1.29  2001/06/01 15:48:58  meichel
** Updated copyright header
**
** Revision 1.28  2000/11/07 16:56:17  meichel
** Initial release of dcmsign module for DICOM Digital Signatures
**
** Revision 1.27  2000/04/14 16:10:09  meichel
** Global flag dcmEnableAutomaticInputDataCorrection now derived from OFGlobal
**   and, thus, safe for use in multi-thread applications.
**
** Revision 1.26  2000/03/08 16:26:29  meichel
** Updated copyright header.
**
** Revision 1.25  2000/02/23 15:11:46  meichel
** Corrected macro for Borland C++ Builder 4 workaround.
**
** Revision 1.24  2000/02/10 10:52:16  joergr
** Added new feature to dcmdump (enhanced print method of dcmdata): write
** pixel data/item value fields to raw files.
**
** Revision 1.23  2000/02/02 14:32:47  joergr
** Replaced 'delete' statements by 'delete[]' for objects created with 'new[]'.
**
** Revision 1.22  2000/02/01 10:12:04  meichel
** Avoiding to include <stdlib.h> as extern "C" on Borland C++ Builder 4,
**   workaround for bug in compiler header files.
**
** Revision 1.21  1999/03/31 09:25:16  meichel
** Updated copyright header in module dcmdata
**
** Revision 1.20  1998/11/12 16:48:13  meichel
** Implemented operator= for all classes derived from DcmObject.
**
** Revision 1.19  1998/07/15 15:51:46  joergr
** Removed several compiler warnings reported by gcc 2.8.1 with
** additional options, e.g. missing copy constructors and assignment
** operators, initialization of member variables in the body of a
** constructor instead of the member initialization list, hiding of
** methods by use of identical names, uninitialized member variables,
** missing const declaration of char pointers. Replaced tabs by spaces.
**
** Revision 1.18  1997/10/13 11:33:48  hewett
** Fixed bug in DcmByteString::getOFString due to inverse logic causing
** a string to be retrieved for all illegal values of pos while the errorFlag
** was set to EC_IllegalCall for all legal values of pos.
**
** Revision 1.17  1997/09/11 15:18:16  hewett
** Added a putOFStringArray method.
**
** Revision 1.16  1997/08/29 08:32:53  andreas
** - Added methods getOFString and getOFStringArray for all
**   string VRs. These methods are able to normalise the value, i. e.
**   to remove leading and trailing spaces. This will be done only if
**   it is described in the standard that these spaces are not relevant.
**   These methods do not test the strings for conformance, this means
**   especially that they do not delete spaces where they are not allowed!
**   getOFStringArray returns the string with all its parts separated by \
**   and getOFString returns only one value of the string.
**   CAUTION: Currently getString returns a string with trailing
**   spaces removed (if dcmEnableAutomaticInputDataCorrection == OFTrue) and
**   truncates the original string (since it is not copied!). If you rely on this
**   behaviour please change your application now.
**   Future changes will ensure that getString returns the original
**   string from the DICOM object (NULL terminated) inclusive padding.
**   Currently, if you call getOF... before calling getString without
**   normalisation, you can get the original string read from the DICOM object.
**
** Revision 1.15  1997/07/24 13:10:50  andreas
** - Removed Warnings from SUN CC 2.0.1
**
** Revision 1.14  1997/07/21 07:56:39  andreas
** - Corrected error in length computation of DcmItem for strings in
**   items.
** - Replace all boolean types (BOOLEAN, CTNBOOLEAN, DICOM_BOOL, BOOL)
**   with one unique boolean type OFBool.
**
** Revision 1.13  1997/07/03 15:09:52  andreas
** - removed debugging functions Bdebug() and Edebug() since
**   they write a static array and are not very useful at all.
**   Cdebug and Vdebug are merged since they have the same semantics.
**   The debugging functions in dcmdata changed their interfaces
**   (see dcmdata/include/dcdebug.h)
**
** Revision 1.12  1997/05/16 08:31:27  andreas
** - Revised handling of GroupLength elements and support of
**   DataSetTrailingPadding elements. The enumeratio E_GrpLenEncoding
**   got additional enumeration values (for a description see dctypes.h).
**   addGroupLength and removeGroupLength methods are replaced by
**   computeGroupLengthAndPadding. To support Padding, the parameters of
**   element and sequence write functions changed.
**
** Revision 1.11  1997/04/18 08:17:13  andreas
** - The put/get-methods for all VRs did not conform to the C++-Standard
**   draft. Some Compilers (e.g. SUN-C++ Compiler, Metroworks
**   CodeWarrier, etc.) create many warnings concerning the hiding of
**   overloaded get methods in all derived classes of DcmElement.
**   So the interface of all value representation classes in the
**   library are changed rapidly, e.g.
**   OFCondition get(Uint16 & value, const unsigned int pos);
**   becomes
**   OFCondition getUint16(Uint16 & value, const unsigned int pos);
**   All (retired) "returntype get(...)" methods are deleted.
**   For more information see dcmdata/include/dcelem.h
**
** Revision 1.10  1997/03/26 17:05:51  hewett
** Added global flag for disabling the automatic correction of small errors.
** Such behaviour is undesirable when performing data validation.
**
** Revision 1.9  1996/08/05 08:46:07  andreas
** new print routine with additional parameters:
**         - print into files
**         - fix output length for elements
** corrected error in search routine with parameter ESM_fromStackTop
**
** Revision 1.8  1996/05/31 09:09:08  hewett
** The stripping of trailing padding characters has been restored (without
** the 8bit char removal bug).  Trailing padding characters are insignificant
** and if they are not removed problems arise with string comparisons since
** the dicom encoding rules require the addition of a padding character for
** odd length strings.
**
** Revision 1.7  1996/05/30 17:17:49  hewett
** Disabled erroneous code to strip trailing padding characters.
**
** Revision 1.6  1996/04/16 16:05:22  andreas
** - better support und bug fixes for NULL element value
**
** Revision 1.5  1996/03/11 13:17:23  hewett
** Removed get function for unsigned char*
**
** Revision 1.4  1996/01/09 11:06:42  andreas
** New Support for Visual C++
** Correct problems with inconsistent const declarations
** Correct error in reading Item Delimitation Elements
**
** Revision 1.3  1996/01/05 13:27:32  andreas
** - changed to support new streaming facilities
** - unique read/write methods for file and block transfer
** - more cleanups
**
*/
