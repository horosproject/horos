/*
 *
 *  Copyright (C) 1996-2005, OFFIS
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
 *  Module:  dcmimgle
 *
 *  Author:  Joerg Riesmeier
 *
 *  Purpose: DicomInputPixelTemplate (Header)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:36 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef DIINPXT_H
#define DIINPXT_H

#include "osconfig.h"
#include "dctypes.h"
#include "dcpixel.h"

#include "ofbmanip.h"
#include "ofcast.h"

#include "diinpx.h"
#include "dipxrept.h"
#include "diutils.h"


/*--------------------*
 *  helper functions  *
 *--------------------*/

static inline Uint8 expandSign(const Uint8 Value,
                               const Uint8,
                               const Uint8)
{
    return Value;
}


static inline Uint16 expandSign(const Uint16 Value,
                                const Uint16,
                                const Uint16)
{
    return Value;
}


static inline Uint32 expandSign(const Uint32 Value,
                                const Uint32,
                                const Uint32)
{
    return Value;
}


static inline Sint8 expandSign(const Sint8 Value,
                               const Sint8 SignBit,
                               const Sint8 SignMask)
{
    return (Value & SignBit) ? (Value | SignMask) : Value;
}


static inline Sint16 expandSign(const Sint16 Value,
                                const Sint16 SignBit,
                                const Sint16 SignMask)
{
    return (Value & SignBit) ? (Value | SignMask) : Value;
}


static inline Sint32 expandSign(const Sint32 Value,
                                const Sint32 SignBit,
                                const Sint32 SignMask)
{
    return (Value & SignBit) ? (Value | SignMask) : Value;
}


static Uint32 getPixelData(DcmPixelData *PixelData,
                           Uint8 *&pixel)
{
    PixelData->getUint8Array(pixel);
    return PixelData->getLength();
}


static Uint32 getPixelData(DcmPixelData *PixelData,
                           Uint16 *&pixel)
{
    PixelData->getUint16Array(pixel);
    return PixelData->getLength();
}


/*---------------------*
 *  class declaration  *
 *---------------------*/

/** Template class to convert DICOM pixel stream to intermediate representation
 */
template<class T1, class T2>
class DiInputPixelTemplate
  : public DiInputPixel,
    public DiPixelRepresentationTemplate<T2>
{

 public:

    /** constructor
     *
     ** @param  pixel   pointer to DICOM dataset element containing the pixel data
     *  @param  alloc   number of bits allocated for each pixel
     *  @param  stored  number of bits stored for each pixel
     *  @param  high    position of bigh bit within bits allocated
     *  @param  start   start position of pixel data to be processed
     *  @param  count   number of pixels to be processed
     */
    DiInputPixelTemplate(/*const*/ DcmPixelData *pixel,
                         const Uint16 alloc,
                         const Uint16 stored,
                         const Uint16 high,
                         const unsigned int start,
                         const unsigned int count)
      : DiInputPixel(stored, start, count),
        Data(NULL)
    {
        MinValue[0] = 0;
        MinValue[1] = 0;
        MaxValue[0] = 0;
        MaxValue[1] = 0;
        if (this->isSigned())
        {
            AbsMinimum = -OFstatic_cast(double, DicomImageClass::maxval(Bits - 1, 0));
            AbsMaximum = OFstatic_cast(double, DicomImageClass::maxval(Bits - 1));
        } else {
            AbsMinimum = 0;
            AbsMaximum = OFstatic_cast(double, DicomImageClass::maxval(Bits));
        }
        if (pixel != NULL)
            convert(pixel, alloc, stored, high);
        if ((PixelCount == 0) || (PixelStart + PixelCount > Count))         // check for corrupt pixel length
            PixelCount = Count - PixelStart;
    }

    /** destructor
     */
    virtual ~DiInputPixelTemplate()
    {
        delete[] Data;
    }

    /** determine minimum and maximum pixel value
     *
     ** @return status, true if successful, false otherwise
     */
    int determineMinMax()
    {
        if (Data != NULL)
        {
            T2 *p = Data;
            unsigned int i;
            const unsigned int ocnt = OFstatic_cast(unsigned int, getAbsMaxRange());
            Uint8 *lut = NULL;
            if ((sizeof(T2) <= 2) && (Count > 3 * ocnt))               // optimization criteria
            {
                lut = new Uint8[ocnt];
                if (lut != NULL)
                {
                    OFBitmanipTemplate<Uint8>::zeroMem(lut, ocnt);
                    Uint8 *q = lut - OFstatic_cast(T2, getAbsMinimum());
                    for (i = Count; i != 0; --i)                       // fill lookup table
                        *(q + *(p++)) = 1;
                    q = lut;
                    for (i = 0; i < ocnt; ++i)                         // search for minimum
                    {
                        if (*(q++) != 0)
                        {
                            MinValue[0] = OFstatic_cast(T2, OFstatic_cast(double, i) + getAbsMinimum());
                            break;
                        }
                    }
                    q = lut + ocnt;
                    for (i = ocnt; i != 0; --i)                        // search for maximum
                    {
                        if (*(--q) != 0)
                        {
                            MaxValue[0] = OFstatic_cast(T2, OFstatic_cast(double, i - 1) + getAbsMinimum());
                            break;
                        }
                    }
                    if (Count >= PixelCount)                           // use global min/max value
                    {
                        MinValue[1] = MinValue[0];
                        MaxValue[1] = MaxValue[0];
                    } else {                                           // calculate min/max for selected range
                        OFBitmanipTemplate<Uint8>::zeroMem(lut, ocnt);
                        p = Data + PixelStart;
                        q = lut - OFstatic_cast(T2, getAbsMinimum());
                        for (i = PixelCount; i != 0; --i)                  // fill lookup table
                            *(q + *(p++)) = 1;
                        q = lut;
                        for (i = 0; i < ocnt; ++i)                         // search for minimum
                        {
                            if (*(q++) != 0)
                            {
                                MinValue[1] = OFstatic_cast(T2, OFstatic_cast(double, i) + getAbsMinimum());
                                break;
                            }
                        }
                        q = lut + ocnt;
                        for (i = ocnt; i != 0; --i)                         // search for maximum
                        {
                            if (*(--q) != 0)
                            {
                                MaxValue[1] = OFstatic_cast(T2, OFstatic_cast(double, i - 1) + getAbsMinimum());
                                break;
                            }
                        }
                    }
                }
            }
            if (lut == NULL)                                           // use conventional method
            {
                T2 value = *p;
                MinValue[0] = value;
                MaxValue[0] = value;
                for (i = Count; i > 1; --i)
                {
                    value = *(++p);
                    if (value < MinValue[0])
                        MinValue[0] = value;
                    else if (value > MaxValue[0])
                        MaxValue[0] = value;
                }
                if (Count <= PixelCount)                               // use global min/max value
                {
                    MinValue[1] = MinValue[0];
                    MaxValue[1] = MaxValue[0];
                } else {                                               // calculate min/max for selected range
                    p = Data + PixelStart;
                    value = *p;
                    MinValue[1] = value;
                    MaxValue[1] = value;
                    for (i = PixelCount; i > 1; --i)
                    {
                        value = *(++p);
                        if (value < MinValue[1])
                            MinValue[1] = value;
                        else if (value > MaxValue[1])
                            MaxValue[1] = value;
                    }
                }
            }
            delete[] lut;
            return 1;
        }
        return 0;
    }

    /** get pixel representation
     *
     ** @return pixel representation
     */
    inline EP_Representation getRepresentation() const
    {
        return DiPixelRepresentationTemplate<T2>::getRepresentation();
    }

    /** get pointer to input pixel data
     *
     ** @return pointer to input pixel data
     */
    inline const void *getData() const
    {
        return OFstatic_cast(const void *, Data);
    }

    /** get reference to pointer to input pixel data
     *
     ** @return reference to pointer to input pixel data
     */
    virtual void *getDataPtr()
    {
        return OFstatic_cast(void *, Data);
    }

    /** remove reference to (internally handled) pixel data
     */
    inline void removeDataReference()
    {
        Data = NULL;
    }

    /** get minimum pixel value
     *
     ** @param  idx  specifies whether to return the global minimum (0) or
     *               the minimum of the selected pixel range (1, see PixelStart/Range)
     *
     ** @return minimum pixel value
     */
    inline double getMinValue(const int idx) const
    {
        return (idx == 0) ? OFstatic_cast(double, MinValue[0]) : OFstatic_cast(double, MinValue[1]);
    }

    /** get maximum pixel value
     *
     ** @param  idx  specifies whether to return the global maximum (0) or
     *               the maximum of the selected pixel range (1, see PixelStart/Range)
     *
     ** @return maximum pixel value
     */
    inline double getMaxValue(const int idx) const
    {
        return (idx == 0) ? OFstatic_cast(double, MaxValue[0]) : OFstatic_cast(double, MaxValue[1]);
    }


 private:

    /** convert pixel data from DICOM dataset to input representation
     *
     ** @param  pixelData      pointer to DICOM dataset element containing the pixel data
     *  @param  bitsAllocated  number of bits allocated for each pixel
     *  @param  bitsStored     number of bits stored for each pixel
     *  @param  highBit        position of bigh bit within bits allocated
     */
    void convert(/*const*/ DcmPixelData *pixelData,
                 const Uint16 bitsAllocated,
                 const Uint16 bitsStored,
                 const Uint16 highBit)
    {
        const Uint16 bitsof_T1 = bitsof(T1);
        const Uint16 bitsof_T2 = bitsof(T2);
        T1 *pixel;
        const Uint32 length_Bytes = getPixelData(pixelData, pixel);
        const Uint32 length_T1 = length_Bytes / sizeof(T1);
        Count = ((length_Bytes * 8) + bitsAllocated - 1) / bitsAllocated;
        unsigned int i;
        
        /* need to split 'length' in order to avoid integer overflow for large pixel data */
        const Uint32 length_B1 = length_Bytes / bitsAllocated;
        const Uint32 length_B2 = length_Bytes % bitsAllocated;
        Count = 8 * length_B1 + (8 * length_B2 + bitsAllocated - 1) / bitsAllocated;
        
        Data = new T2[Count];
        if (Data != NULL)
        {
#ifdef DEBUG
            if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
            {
                ofConsole.lockCerr() << bitsAllocated << " " << bitsStored << " " << highBit << " " << isSigned() << endl;
                ofConsole.unlockCerr();
            }
#endif
            const T1 *p = pixel;
            T2 *q = Data;
            if (bitsof_T1 == bitsAllocated)                                             // case 1: equal 8/16 bit
            {
                if (bitsStored == bitsAllocated)
                {
#ifdef DEBUG
                    if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                    {
                        ofConsole.lockCerr() << "convert pixelData: case 1a (single copy)" << endl;
                        ofConsole.unlockCerr();
                    }
#endif
                    for (i = Count; i != 0; --i)
                        *(q++) = OFstatic_cast(T2, *(p++));
                }
                else /* bitsStored < bitsAllocated */
                {
                    T1 mask = 0;
                    for (i = 0; i < bitsStored; ++i)
                        mask |= OFstatic_cast(T1, 1 << i);
                    const T2 sign = 1 << (bitsStored - 1);
                    T2 smask = 0;
                    for (i = bitsStored; i < bitsof_T2; ++i)
                        smask |= OFstatic_cast(T2, 1 << i);
                    const Uint16 shift = highBit + 1 - bitsStored;
                    if (shift == 0)
                    {
#ifdef DEBUG
                        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                        {
                            ofConsole.lockCerr() << "convert pixelData: case 1b (mask & sign)" << endl;
                            ofConsole.unlockCerr();
                        }
#endif
                        for (i = length_T1; i != 0; --i)
                            *(q++) = expandSign(OFstatic_cast(T2, *(p++) & mask), sign, smask);
                    }
                    else /* shift > 0 */
                    {
#ifdef DEBUG
                        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                        {
                            ofConsole.lockCerr() << "convert pixelData: case 1c (shift & mask & sign)" << endl;
                            ofConsole.unlockCerr();
                        }
#endif
                        for (i = length_T1; i != 0; --i)
                            *(q++) = expandSign(OFstatic_cast(T2, (*(p++) >> shift) & mask), sign, smask);
                    }
                }
            }
            else if ((bitsof_T1 > bitsAllocated) && (bitsof_T1 % bitsAllocated == 0))   // case 2: divisor of 8/16 bit
            {
                const Uint16 times = bitsof_T1 / bitsAllocated;
                T1 mask = 0;
                for (i = 0; i < bitsStored; ++i)
                    mask |= OFstatic_cast(T1, 1 << i);
                Uint16 j;
                T1 value;
                if ((bitsStored == bitsAllocated) && (bitsStored == bitsof_T2))
                {
                    if (times == 2)
                    {
#ifdef DEBUG
                        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                        {
                            ofConsole.lockCerr() << "convert pixelData: case 2a (simple mask)" << endl;
                            ofConsole.unlockCerr();
                        }
#endif
                        for (i = length_T1; i != 0; --i, ++p)
                        {
                            *(q++) = OFstatic_cast(T2, *p & mask);
                            *(q++) = OFstatic_cast(T2, *p >> bitsAllocated);
                        }
                        
                        /* check for additional input pixel (in case of odd length when using partial access) */
                        if (length_T1 * 2 /* times */ < length_Bytes)
                            *(q++) = OFstatic_cast(T2, *p & mask);
                    }
                    else
                    {
#ifdef DEBUG
                        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                        {
                            ofConsole.lockCerr() << "convert pixelData: case 2b (mask)" << endl;
                            ofConsole.unlockCerr();
                        }
#endif
                        for (i = length_T1; i != 0; --i)
                        {
                            value = *(p++);
                            for (j = times; j != 0; --j)
                            {
                                *(q++) = OFstatic_cast(T2, value & mask);
                                value >>= bitsAllocated;
                            }
                        }
                    }
                }
                else
                {
#ifdef DEBUG
                    if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                    {
                        ofConsole.lockCerr() << "convert pixelData: case 2c (shift & mask & sign)" << endl;
                        ofConsole.unlockCerr();
                    }
#endif
                    const T2 sign = 1 << (bitsStored - 1);
                    T2 smask = 0;
                    for (i = bitsStored; i < bitsof_T2; ++i)
                        smask |= OFstatic_cast(T2, 1 << i);
                    const Uint16 shift = highBit + 1 - bitsStored;
                    for (i = length_T1; i != 0; --i)
                    {
                        value = *(p++) >> shift;
                        for (j = times; j != 0; --j)
                        {
                            *(q++) = expandSign(OFstatic_cast(T2, value & mask), sign, smask);
                            value >>= bitsAllocated;
                        }
                    }
                }
            }
            else if ((bitsof_T1 < bitsAllocated) && (bitsAllocated % bitsof_T1 == 0)    // case 3: multiplicant of 8/16
                && (bitsStored == bitsAllocated))
            {
#ifdef DEBUG
                if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                {
                    ofConsole.lockCerr() << "convert pixelData: case 3 (multi copy)" << endl;
                    ofConsole.unlockCerr();
                }
#endif
                const Uint16 times = bitsAllocated / bitsof_T1;
                Uint16 j;
                Uint16 shift;
                T2 value;
                for (i = length_T1; i != 0; --i)
                {
                    shift = 0;
                    value = OFstatic_cast(T2, *(p++));
                    for (j = times; j > 1; --j, --i)
                    {
                        shift += bitsof_T1;
                        value |= OFstatic_cast(T2, *(p++)) << shift;
                    }
                    *(q++) = value;
                }
            }
            else                                                                        // case 4: anything else
            {
#ifdef DEBUG
                if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                {
                    ofConsole.lockCerr() << "convert pixelData: case 4 (general)" << endl;
                    ofConsole.unlockCerr();
                }
#endif
                T2 value = 0;
                Uint16 bits = 0;
                Uint32 skip = highBit + 1 - bitsStored;
                Uint32 times;
                T1 mask[bitsof_T1];
                mask[0] = 1;
                for (i = 1; i < bitsof_T1; ++i)
                    mask[i] = (mask[i - 1] << 1) | 1;
                T2 smask = 0;
                for (i = bitsStored; i < bitsof_T2; ++i)
                    smask |= OFstatic_cast(T2, 1 << i);
                const T2 sign = 1 << (bitsStored - 1);
                const Uint32 gap = bitsAllocated - bitsStored;
                i = 0;
                while (i < length_T1)
                {
                    if (skip < bitsof_T1)
                    {
                        if (skip + bitsStored - bits < bitsof_T1)       // -++- --++
                        {
                            value |= (OFstatic_cast(T2, (*p >> skip) & mask[bitsStored - bits - 1]) << bits);
                            skip += bitsStored - bits + gap;
                            bits = bitsStored;
                        }
                        else                                            // ++-- ++++
                        {
                            value |= (OFstatic_cast(T2, (*p >> skip) & mask[bitsof_T1 - skip - 1]) << bits);
                            bits += bitsof_T1 - OFstatic_cast(Uint16, skip);
                            skip = (bits == bitsStored) ? gap : 0;
                            ++i;
                            ++p;
                        }
                        if (bits == bitsStored)
                        {
                            *(q++) = expandSign(value, sign, smask);
                            value = 0;
                            bits = 0;
                        }
                    }
                    else
                    {
                        times = skip / bitsof_T1;
                        i += times;
                        p += times;
                        skip -= times * bitsof_T1;
                    }
                }
            }
        }
    }

    /// pointer to pixel data
    T2 *Data;

    /// minimum pixel value ([0] = global, [1] = selected pixel range)
    T2 MinValue[2];
    /// maximum pixel value ([0] = global, [1] = selected pixel range)
    T2 MaxValue[2];

 // --- declarations to avoid compiler warnings

    DiInputPixelTemplate(const DiInputPixelTemplate<T1,T2> &);
    DiInputPixelTemplate<T1,T2> &operator=(const DiInputPixelTemplate<T1,T2> &);
};


#endif


/*
 *
 * CVS/RCS Log:
 * $Log: diinpxt.h,v $
 * Revision 1.1  2006/03/01 20:15:36  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.30  2005/12/08 16:47:44  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.29  2004/04/21 10:00:36  meichel
 * Minor modifications for compilation with gcc 3.4.0
 *
 * Revision 1.28  2004/02/06 11:07:50  joergr
 * Distinguish more clearly between const and non-const access to pixel data.
 *
 * Revision 1.27  2004/01/05 14:52:20  joergr
 * Removed acknowledgements with e-mail addresses from CVS log.
 *
 * Revision 1.26  2003/12/23 15:53:22  joergr
 * Replaced post-increment/decrement operators by pre-increment/decrement
 * operators where appropriate (e.g. 'i++' by '++i').
 *
 * Revision 1.25  2003/12/08 19:10:52  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Removed leading underscore characters from preprocessor symbols (reserved
 * symbols). Updated copyright header.
 *
 * Revision 1.24  2002/10/21 10:13:50  joergr
 * Corrected wrong calculation of min/max pixel value in cases where the
 * stored pixel data exceeds the expected size.
 *
 * Revision 1.23  2001/11/13 18:07:36  joergr
 * Fixed bug occurring when processing monochrome images with an odd number of
 * pixels.
 *
 * Revision 1.22  2001/10/10 15:25:09  joergr
 * Removed redundant variable declarations to avoid compiler warnings
 * ("declaration of ... shadows previous local").
 *
 * Revision 1.21  2001/09/28 13:04:59  joergr
 * Enhanced algorithm to determine the min and max value.
 *
 * Revision 1.20  2001/06/01 15:49:42  meichel
 * Updated copyright header
 *
 * Revision 1.19  2000/05/03 09:46:28  joergr
 * Removed most informational and some warning messages from release built
 * (#ifndef DEBUG).
 *
 * Revision 1.18  2000/04/28 12:32:30  joergr
 * DebugLevel - global for the module - now derived from OFGlobal (MF-safe).
 *
 * Revision 1.17  2000/04/27 13:08:39  joergr
 * Dcmimgle library code now consistently uses ofConsole for error output.
 *
 * Revision 1.16  2000/03/08 16:24:17  meichel
 * Updated copyright header.
 *
 * Revision 1.15  2000/03/03 14:09:12  meichel
 * Implemented library support for redirecting error messages into memory
 *   instead of printing them to stdout/stderr for GUI applications.
 *
 * Revision 1.14  1999/09/17 12:21:57  joergr
 * Added/changed/completed DOC++ style comments in the header files.
 * Enhanced efficiency of some "for" loops and of the implementation to
 * determine min/max values of the input pixels.
 *
 * Revision 1.13  1999/07/23 13:54:38  joergr
 * Optimized memory usage for converting input pixel data (reference instead
 * of copying where possible).
 *
 * Revision 1.12  1999/05/04 09:20:39  meichel
 * Minor code purifications to keep IBM xlC quiet
 *
 * Revision 1.11  1999/04/30 16:23:59  meichel
 * Minor code purifications to keep IBM xlC quiet
 *
 * Revision 1.10  1999/04/28 14:48:39  joergr
 * Introduced new scheme for the debug level variable: now each level can be
 * set separately (there is no "include" relationship).
 *
 * Revision 1.9  1999/03/24 17:20:03  joergr
 * Added/Modified comments and formatting.
 *
 * Revision 1.8  1999/02/11 16:00:54  joergr
 * Removed inline declarations from several methods.
 *
 * Revision 1.7  1999/02/03 17:04:37  joergr
 * Moved global functions maxval() and determineRepresentation() to class
 * DicomImageClass (as static methods).
 *
 * Revision 1.6  1999/01/20 15:01:31  joergr
 * Replaced invocation of getCount() by member variable Count where possible.
 *
 * Revision 1.5  1999/01/11 09:34:28  joergr
 * Corrected bug in determing 'AbsMaximum' (removed '+ 1').
 *
 * Revision 1.4  1998/12/22 14:23:16  joergr
 * Added calculation of member variables AbsMinimum/AbsMaximum.
 * Replaced method copyMem by for-loop copying each item.
 * Removed some '#ifdef DEBUG'.
 *
 * Revision 1.3  1998/12/16 16:30:34  joergr
 * Added methods to determine absolute minimum and maximum value for given
 * value representation.
 *
 * Revision 1.2  1998/12/14 17:18:23  joergr
 * Reformatted source code.
 *
 * Revision 1.1  1998/11/27 15:08:21  joergr
 * Added copyright message.
 * Introduced global debug level for dcmimage module to control error output.
 * Added support for new bit manipulation class.
 *
 * Revision 1.8  1998/07/01 08:39:21  joergr
 * Minor changes to avoid compiler warnings (gcc 2.8.1 with additional
 * options), e.g. add copy constructors.
 *
 * Revision 1.7  1998/05/11 14:53:17  joergr
 * Added CVS/RCS header to each file.
 *
 *
 */
