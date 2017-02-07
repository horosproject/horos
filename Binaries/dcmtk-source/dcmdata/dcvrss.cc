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
 *  Purpose: Implementation of class DcmSignedShort
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
#include "ofstream.h"
#include "dcvrss.h"
#include "dcvm.h"

#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#include "ofstdinc.h"


// ********************************


DcmSignedShort::DcmSignedShort(const DcmTag &tag,
                               const Uint32 len)
  : DcmElement(tag, len)
{
}


DcmSignedShort::DcmSignedShort(const DcmSignedShort &old)
  : DcmElement(old)
{
}


DcmSignedShort::~DcmSignedShort()
{
}


DcmSignedShort &DcmSignedShort::operator=(const DcmSignedShort &obj)
{
    DcmElement::operator=(obj);
    return *this;
}


// ********************************


DcmEVR DcmSignedShort::ident() const
{
    return EVR_SS;
}


unsigned int DcmSignedShort::getVM()
{
    return Length / sizeof(Sint16);
}


// ********************************


void DcmSignedShort::print(ostream &out,
                           const size_t flags,
                           const int level,
                           const char * /*pixelFileName*/,
                           size_t * /*pixelCounter*/)
{
    if (valueLoaded())
    {
        /* get signed integer data */
        Sint16 *sintVals;
        errorFlag = getSint16Array(sintVals);
        if (sintVals != NULL)
        {
            const unsigned int count = getVM();
            const unsigned int maxLength = (flags & DCMTypes::PF_shortenLongTagValues) ?
                DCM_OptPrintLineLength : OFstatic_cast(unsigned int, -1) /*unlimited*/;
            unsigned int printedLength = 0;
            unsigned int newLength = 0;
            char buffer[32];
            /* print line start with tag and VR */
            printInfoLineStart(out, flags, level);
            /* print multiple values */
            for (unsigned int i = 0; i < count; i++, sintVals++)
            {
                /* check whether first value is printed (omit delimiter) */
                if (i == 0)
                    sprintf(buffer, "%hd", *sintVals);
                else
                    sprintf(buffer, "\\%hd", *sintVals);
                /* check whether current value sticks to the length limit */
                newLength = printedLength + (unsigned int)strlen(buffer);
                if ((newLength <= maxLength) && ((i + 1 == count) || (newLength + 3 <= maxLength)))
                {
                    out << buffer;
                    printedLength = newLength;
                } else {
                    /* check whether output has been truncated */
                    if (i + 1 < count)
                    {
                        out << "...";
                        printedLength += 3;
                    }
                    break;
                }
            }
            /* print line end with length, VM and tag name */
            printInfoLineEnd(out, flags, printedLength);
        } else
            printInfoLine(out, flags, level, "(no value available)");
    } else
        printInfoLine(out, flags, level, "(not loaded)");
}


// ********************************


OFCondition DcmSignedShort::getSint16(Sint16 &sintVal,
                                      const unsigned int pos)
{
    /* get signed integer data */
    Sint16 *sintValues = NULL;
    errorFlag = getSint16Array(sintValues);
    /* check data before returning */
    if (errorFlag.good())
    {
        if (sintValues == NULL)
            errorFlag = EC_IllegalCall;
        else if (pos >= getVM())
            errorFlag = EC_IllegalParameter;
        else
            sintVal = sintValues[pos];
    }
    /* clear value in case of error */
    if (errorFlag.bad())
        sintVal = 0;
    return errorFlag;
}


OFCondition DcmSignedShort::getSint16Array(Sint16 *&sintVals)
{
    sintVals = OFstatic_cast(Sint16 *, getValue());
    return errorFlag;
}


// ********************************


OFCondition DcmSignedShort::getOFString(OFString &stringVal,
                                        const unsigned int pos,
                                        OFBool /*normalize*/)
{
    Sint16 sintVal;
    /* get the specified numeric value */
    errorFlag = getSint16(sintVal, pos);
    if (errorFlag.good())
    {
        /* ... and convert it to a character string */
        char buffer[32];
        sprintf(buffer, "%i", sintVal);
        /* assign result */
        stringVal = buffer;
    }
    return errorFlag;
}


// ********************************


OFCondition DcmSignedShort::putSint16(const Sint16 sintVal,
                                      const unsigned int pos)
{
    Sint16 val = sintVal;
    errorFlag = changeValue(&val, sizeof(Sint16) * pos, sizeof(Sint16));
    return errorFlag;
}


OFCondition DcmSignedShort::putSint16Array(const Sint16 *sintVals,
                                           const unsigned int numSints)
{
    errorFlag = EC_Normal;
    if (numSints > 0)
    {
        /* check for valid data */
        if (sintVals != NULL)
            errorFlag = putValue(sintVals, sizeof(Sint16) * OFstatic_cast(Uint32, numSints));
        else
            errorFlag = EC_CorruptedData;
    } else
        errorFlag = putValue(NULL, 0);
    return errorFlag;
}


// ********************************


OFCondition DcmSignedShort::putString(const char *stringVal)
{
    errorFlag = EC_Normal;
    /* check input string */
    if ((stringVal != NULL) && (strlen(stringVal) > 0))
    {
        const unsigned int vm = getVMFromString(stringVal);
        if (vm > 0)
        {
            Sint16 *field = new Sint16[vm];
            const char *s = stringVal;
            char *value;
            /* retrieve signed integer data from character string */
            for (unsigned int i = 0; (i < vm) && errorFlag.good(); i++)
            {
                /* get first value stored in 's', set 's' to beginning of the next value */
                value = getFirstValueFromString(s);
                if ((value == NULL) || (sscanf(value, "%hd", &field[i]) != 1))
                    errorFlag = EC_CorruptedData;
                delete[] value;
            }
            /* set binary data as the element value */
            if (errorFlag.good())
                errorFlag = putSint16Array(field, vm);
            /* delete temporary buffer */
            delete[] field;
        } else
            errorFlag = putValue(NULL, 0);
    } else
        errorFlag = putValue(NULL, 0);
    return errorFlag;
}


// ********************************


OFCondition DcmSignedShort::verify(const OFBool autocorrect)
{
    /* check for valid value length */
    if (Length % (sizeof(Sint16)) != 0)
    {
        errorFlag = EC_CorruptedData;
        if (autocorrect)
        {
            /* strip to valid length */
            Length -= (Length % (sizeof(Sint16)));
        }
    } else
        errorFlag = EC_Normal;
    return errorFlag;
}


/*
** CVS/RCS Log:
** $Log: dcvrss.cc,v $
** Revision 1.1  2006/03/01 20:15:22  lpysher
** Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
**
** Revision 1.25  2005/12/08 15:42:03  meichel
** Changed include path schema for all DCMTK header files
**
** Revision 1.24  2004/02/04 16:07:15  joergr
** Adapted type casts to new-style typecast operators defined in ofcast.h.
** Removed acknowledgements with e-mail addresses from CVS log.
**
** Revision 1.23  2002/12/06 13:12:38  joergr
** Enhanced "print()" function by re-working the implementation and replacing
** the boolean "showFullData" parameter by a more general integer flag.
** Made source code formatting more consistent with other modules/files.
**
** Revision 1.22  2002/11/27 12:06:58  meichel
** Adapted module dcmdata to use of new header file ofstdinc.h
**
** Revision 1.21  2002/04/25 10:33:20  joergr
** Added getOFString() implementation.
**
** Revision 1.20  2002/04/16 13:43:26  joergr
** Added configurable support for C++ ANSI standard includes (e.g. streams).
**
** Revision 1.19  2001/09/25 17:20:00  meichel
** Adapted dcmdata to class OFCondition
**
** Revision 1.18  2001/06/01 15:49:20  meichel
** Updated copyright header
**
** Revision 1.17  2000/04/14 15:55:09  meichel
** Dcmdata library code now consistently uses ofConsole for error output.
**
** Revision 1.16  2000/03/08 16:26:50  meichel
** Updated copyright header.
**
** Revision 1.15  2000/03/03 14:05:40  meichel
** Implemented library support for redirecting error messages into memory
**   instead of printing them to stdout/stderr for GUI applications.
**
** Revision 1.14  2000/02/10 10:52:25  joergr
** Added new feature to dcmdump (enhanced print method of dcmdata): write
** pixel data/item value fields to raw files.
**
** Revision 1.13  2000/02/02 14:32:59  joergr
** Replaced 'delete' statements by 'delete[]' for objects created with 'new[]'.
**
** Revision 1.12  1999/03/31 09:25:58  meichel
** Updated copyright header in module dcmdata
**
** Revision 1.11  1997/07/21 08:25:34  andreas
** - Replace all boolean types (BOOLEAN, CTNBOOLEAN, DICOM_BOOL, BOOL)
**   with one unique boolean type OFBool.
**
** Revision 1.10  1997/07/03 15:10:18  andreas
** - removed debugging functions Bdebug() and Edebug() since
**   they write a static array and are not very useful at all.
**   Cdebug and Vdebug are merged since they have the same semantics.
**   The debugging functions in dcmdata changed their interfaces
**   (see dcmdata/include/dcdebug.h)
**
** Revision 1.9  1997/04/18 08:10:53  andreas
** - Corrected debugging code
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
** Revision 1.8  1996/08/05 08:46:22  andreas
** new print routine with additional parameters:
**         - print into files
**         - fix output length for elements
** corrected error in search routine with parameter ESM_fromStackTop
**
** Revision 1.7  1996/05/20 13:27:52  andreas
** correct minor bug in print routine
**
** Revision 1.6  1996/04/16 16:05:26  andreas
** - better support und bug fixes for NULL element value
**
** Revision 1.5  1996/03/26 09:59:38  meichel
** corrected bug (deletion of const char *) which prevented compilation on NeXT
**
** Revision 1.4  1996/01/29 13:38:34  andreas
** - new put method for every VR to put value as a string
** - better and unique print methods
**
** Revision 1.3  1996/01/05 13:27:53  andreas
** - changed to support new streaming facilities
** - unique read/write methods for file and block transfer
** - more cleanups
**
*/
