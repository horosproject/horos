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
 *  Purpose: Implementation of class DcmUniqueIdentifier
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:22 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmdata/dcvrui.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"
#include "ofstream.h"
#include "ofstring.h"
#include "ofstd.h"
#include "dcvrui.h"
#include "dcuid.h"

#define INCLUDE_CSTRING
#define INCLUDE_CCTYPE
#include "ofstdinc.h"


// ********************************


DcmUniqueIdentifier::DcmUniqueIdentifier(const DcmTag &tag,
                                         const Uint32 len)
  : DcmByteString(tag, len)
{
    /* padding character is NULL not a space! */
    paddingChar = '\0';
    maxLength = 64;
}


DcmUniqueIdentifier::DcmUniqueIdentifier(const DcmUniqueIdentifier &old)
  : DcmByteString(old)
{
}


DcmUniqueIdentifier::~DcmUniqueIdentifier()
{
}


DcmUniqueIdentifier &DcmUniqueIdentifier::operator=(const DcmUniqueIdentifier &obj)
{
    DcmByteString::operator=(obj);
    return *this;
}


// ********************************


DcmEVR DcmUniqueIdentifier::ident() const
{
    return EVR_UI;
}


// ********************************


void DcmUniqueIdentifier::print(ostream &out,
                                const size_t flags,
                                const int level,
                                const char * /*pixelFileName*/,
                                size_t * /*pixelCounter*/)
{
    if (valueLoaded())
    {
        /* get string data (possibly multi-valued) */
        char *string = NULL;
        getString(string);
        if (string != NULL)
        {
            /* check whether UID number can be mapped to a UID name */
            const char *symbol = dcmFindNameOfUID(string);
            if ((symbol != NULL) && (strlen(symbol) > 0))
            {
                const size_t bufSize = strlen(symbol) + 1 /* for "=" */ + 1;
                char *buffer = new char[bufSize];
                if (buffer != NULL)
                {
                    /* concatenate "=" and the UID name */
                    OFStandard::strlcpy(buffer, "=", bufSize);
                    OFStandard::strlcat(buffer, symbol, bufSize);
                    printInfoLine(out, flags, level, buffer);
                    /* delete temporary character buffer */
                    delete[] buffer;
                } else /* could not allocate buffer */
                    DcmByteString::print(out, flags, level);
            } else /* no symbol (UID name) found */
                DcmByteString::print(out, flags, level);
        } else
            printInfoLine(out, flags, level, "(no value available)" );
    } else
        printInfoLine(out, flags, level, "(not loaded)" );
}


// ********************************


OFCondition DcmUniqueIdentifier::putString(const char *stringVal)
{
    const char *uid = stringVal;
    /* check whether parameter contains a UID name instead of a UID number */
    if ((stringVal != NULL) && (stringVal[0] == '='))
        uid = dcmFindUIDFromName(stringVal + 1);
    /* call inherited method to set the UID string */
    return DcmByteString::putString(uid);
}


// ********************************


OFCondition DcmUniqueIdentifier::makeMachineByteString()
{
    /* get string data */
    char *value = OFstatic_cast(char *, getValue());
    /* check whether automatic input data correction is enabled */
    if ((value != NULL) && dcmEnableAutomaticInputDataCorrection.get())
    {
        const int len = (int)strlen(value);
        /*
        ** Remove any leading, embedded, or trailing white space.
        ** This manipulation attempts to correct problems with
        ** incorrectly encoded UIDs which have been observed in
        ** some images.
        */
        int k = 0;
        for (int i = 0; i < len; i++)
        {
           if (!isspace(value[i]))
           {
              value[k] = value[i];
              k++;
           }
        }
        value[k] = '\0';
    }
    /* call inherited method: re-computes the string length, etc. */
    return DcmByteString::makeMachineByteString();
}


/*
** CVS/RCS Log:
** $Log: dcvrui.cc,v $
** Revision 1.1  2006/03/01 20:15:22  lpysher
** Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
**
** Revision 1.23  2005/12/08 15:42:06  meichel
** Changed include path schema for all DCMTK header files
**
** Revision 1.22  2004/01/16 13:46:03  joergr
** Adapted type casts to new-style typecast operators defined in ofcast.h.
**
** Revision 1.21  2002/12/06 13:19:26  joergr
** Enhanced "print()" function by re-working the implementation and replacing
** the boolean "showFullData" parameter by a more general integer flag.
** Made source code formatting more consistent with other modules/files.
**
** Revision 1.20  2002/11/27 12:06:59  meichel
** Adapted module dcmdata to use of new header file ofstdinc.h
**
** Revision 1.19  2001/09/25 17:20:01  meichel
** Adapted dcmdata to class OFCondition
**
** Revision 1.18  2001/06/01 15:49:21  meichel
** Updated copyright header
**
** Revision 1.17  2000/04/14 16:10:10  meichel
** Global flag dcmEnableAutomaticInputDataCorrection now derived from OFGlobal
**   and, thus, safe for use in multi-thread applications.
**
** Revision 1.16  2000/03/08 16:26:51  meichel
** Updated copyright header.
**
** Revision 1.15  2000/02/10 10:52:25  joergr
** Added new feature to dcmdump (enhanced print method of dcmdata): write
** pixel data/item value fields to raw files.
**
** Revision 1.14  2000/02/02 14:33:00  joergr
** Replaced 'delete' statements by 'delete[]' for objects created with 'new[]'.
**
** Revision 1.13  1999/03/31 09:26:01  meichel
** Updated copyright header in module dcmdata
**
** Revision 1.12  1998/11/12 16:48:31  meichel
** Implemented operator= for all classes derived from DcmObject.
**
** Revision 1.11  1997/07/21 08:25:35  andreas
** - Replace all boolean types (BOOLEAN, CTNBOOLEAN, DICOM_BOOL, BOOL)
**   with one unique boolean type OFBool.
**
** Revision 1.10  1997/07/03 15:10:20  andreas
** - removed debugging functions Bdebug() and Edebug() since
**   they write a static array and are not very useful at all.
**   Cdebug and Vdebug are merged since they have the same semantics.
**   The debugging functions in dcmdata changed their interfaces
**   (see dcmdata/include/dcdebug.h)
**
** Revision 1.9  1997/04/18 08:17:20  andreas
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
** Revision 1.8  1997/03/26 17:06:30  hewett
** Added global flag for disabling the automatic correction of small errors.
** Such behaviour is undesirable when performing data validation.
**
** Revision 1.7  1996/08/05 08:46:23  andreas
** new print routine with additional parameters:
**         - print into files
**         - fix output length for elements
** corrected error in search routine with parameter ESM_fromStackTop
**
** Revision 1.6  1996/05/31 09:09:51  hewett
** Unique Identifiers which are incorrectly encoded with leading, embedded
** or trailing white space are now corrected.
**
** Revision 1.5  1996/05/30 17:19:33  hewett
** Added a makeMachineByteString() method to strip and trailing whitespace
** from a UID.
**
** Revision 1.4  1996/01/29 13:38:34  andreas
** - new put method for every VR to put value as a string
** - better and unique print methods
**
*/


