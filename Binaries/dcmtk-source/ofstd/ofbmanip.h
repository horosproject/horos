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
 *  Module:  ofstd
 *
 *  Author:  Joerg Riesmeier
 *
 *  Purpose: Template class for bit manipulations (Header)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:17:55 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef OFBMANIP_H
#define OFBMANIP_H

#include "osconfig.h"
#include "ofcast.h"

#define INCLUDE_CSTRING
#include "ofstdinc.h"


#ifdef HAVE_BZERO
#ifndef HAVE_PROTOTYPE_BZERO
BEGIN_EXTERN_C
extern void bzero(char* s, int len);
END_EXTERN_C
#endif
#endif


/*---------------------*
 *  class declaration  *
 *---------------------*/

/** A template class for bit manipulations.
 *  This class is used to perform platform independent operations on typed memory areas.
 */
template<class T>
class OFBitmanipTemplate
{

 public:

    /** copies specified number of elements from source to destination
     *
     ** @param  src    pointer to source memory
     *  @param  dest   pointer to destination memory
     *  @param  count  number of elements to be copied
     */
    static void copyMem(const T *src,
                        T *dest,
                        const unsigned int count)
    {
#ifdef HAVE_MEMCPY
        memcpy(OFstatic_cast(void *, dest), OFstatic_cast(const void *, src), OFstatic_cast(size_t, count) * sizeof(T));
#elif HAVE_BCOPY
        bcopy(OFstatic_cast(const void *, src), OFstatic_cast(void *, dest), OFstatic_cast(size_t, count) * sizeof(T));
#else
        unsigned int i;
        const T *p = src;
        T *q = dest;
        for (i = count; i != 0; --i)
            *q++ = *p++;
#endif
    }


    /** sets specified number of elements in destination memory to defined value
     *
     ** @param  dest   pointer to destination memory
     *  @param  value  value to be set
     *  @param  count  number of elements to be set
     */
    static void setMem(T *dest,
                       const T value,
                       const unsigned int count)
    {
#ifdef HAVE_MEMSET
        if ((value == 0) || (sizeof(T) == sizeof(unsigned char)))
            memset(OFstatic_cast(void *, dest), OFstatic_cast(int, value), OFstatic_cast(size_t, count) * sizeof(T));
        else
#endif
        {
            unsigned int i;
            T *q = dest;
            for (i = count; i != 0; --i)
                *q++ = value;
        }
    }


    /** sets specified number of elements in destination memory to zero
     *
     ** @param  dest   pointer to destination memory
     *  @param  count  number of elements to be set to zero
     */
    static void zeroMem(T *dest,
                        const unsigned int count)
    {
#ifdef HAVE_BZERO
        // some platforms, e.g. OSF1, require the first parameter to be char *.
        bzero(OFreinterpret_cast(char *, dest), OFstatic_cast(size_t, count) * sizeof(T));
#else
#ifdef HAVE_MEMSET
        memset(OFstatic_cast(void *, dest), 0, OFstatic_cast(size_t, count) * sizeof(T));
#else
        unsigned int i;
        T *q = dest;
        for (i = count; i != 0; --i)
            *q++ = 0;
#endif
#endif
    }
};


#endif


/*
 *
 * CVS/RCS Log:
 * $Log: ofbmanip.h,v $
 * Revision 1.1  2006/03/01 20:17:55  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.16  2005/12/08 16:05:46  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.15  2003/12/05 10:37:41  joergr
 * Removed leading underscore characters from preprocessor symbols (reserved
 * symbols). Updated copyright date where appropriate.
 *
 * Revision 1.14  2003/08/29 07:54:52  joergr
 * Modified function zeroMem() to compile with MSVC again where bzero() is not
 * available.
 *
 * Revision 1.13  2003/08/14 09:01:18  meichel
 * Adapted type casts to new-style typecast operators defined in ofcast.h
 *
 * Revision 1.12  2002/11/27 11:23:04  meichel
 * Adapted module ofstd to use of new header file ofstdinc.h
 *
 * Revision 1.11  2001/06/01 15:51:31  meichel
 * Updated copyright header
 *
 * Revision 1.10  2000/03/08 16:36:00  meichel
 * Updated copyright header.
 *
 * Revision 1.9  2000/02/02 10:56:25  joergr
 * Removed space characters before preprocessor directives.
 *
 * Revision 1.8  1999/09/17 11:46:34  joergr
 * Enhanced efficiency of "for" loops.
 *
 * Revision 1.7  1999/08/25 16:44:44  joergr
 * Enhanced efficiency of inner loops (count loop variable down).
 *
 * Revision 1.6  1999/04/30 16:34:07  meichel
 * Added provision for systems which have bzero() but no prototype, e.g. SunOS
 *
 * Revision 1.5  1999/04/29 16:49:22  meichel
 * Changed first parameter in bzero() call to char *, required on OSF1.
 *
 * Revision 1.4  1999/04/26 16:07:52  joergr
 * Changed comments.
 *
 * Revision 1.3  1998/12/16 15:59:51  joergr
 * Corrected bug in setMem routine (expected 'value' parameter for system
 * function 'memset' is implicitely casted to 'unsigned char').
 *
 * Revision 1.2  1998/12/02 12:52:05  joergr
 * Corrected bug in setMem routine (parameter 'value' was ignored).
 *
 * Revision 1.1  1998/11/27 12:29:20  joergr
 * First release of class for plaform independant memory operations.
 *
 *
 */
