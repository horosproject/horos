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
 *  Module:  dcmimage
 *
 *  Author:  Joerg Riesmeier
 *
 *  Purpose: DicomColorPixelTemplate (Header)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:35 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef DICOPXT_H
#define DICOPXT_H

#include "osconfig.h"
#include "dctypes.h"
#include "ofbmanip.h"

#include "dicopx.h"
#include "dipxrept.h"


/********************************************************************/


inline Uint8 removeSign(const Uint8 value, const Uint8)
{
    return value;
}


inline Uint16 removeSign(const Uint16 value, const Uint16)
{
    return value;
}


inline Uint32 removeSign(const Uint32 value, const Uint32)
{
    return value;
}


inline Uint8 removeSign(const Sint8 value, const Sint8 offset)
{
    return OFstatic_cast(Uint8, OFstatic_cast(Sint16, value) + OFstatic_cast(Sint16, offset) + 1);
}


inline Uint16 removeSign(const Sint16 value, const Sint16 offset)
{
    return OFstatic_cast(Uint16, OFstatic_cast(Sint32, value) + OFstatic_cast(Sint32, offset) + 1);
}

/*
inline Uint32 removeSign(const Sint32 value, const Sint32 offset)
{
    return (value < 0) ? OFstatic_cast(Uint32, value + offset + 1) : OFstatic_cast(Uint32, value) + OFstatic_cast(Uint32, offset) + 1;
}


inline Uint8 removeSign(const Sint8 value, const Uint8 mask)
{
    return OFstatic_cast(Uint8, value) ^ mask;
}


inline Uint16 removeSign(const Sint16 value, const Uint16 mask)
{
    return OFstatic_cast(Uint16, value) ^ mask;
}
*/

inline Uint32 removeSign(const Sint32 value, const Uint32 mask)
{
    return OFstatic_cast(Uint32, value) ^ mask;
}


/*---------------------*
 *  class declaration  *
 *---------------------*/

/** Template class to handle color pixel data
 */
template<class T>
class DiColorPixelTemplate
  : public DiColorPixel,
    public DiPixelRepresentationTemplate<T>
{

 public:

    /** constructor
     *
     ** @param  docu         pointer to the DICOM document
     *  @param  pixel        pointer to input pixel data
     *  @param  samples      number of expected samples per pixel (for checking purposes)
     *  @param  status       status of the image object (reference variable)
     *  @param  sample_rate  dummy parameter (used for derived classes only)
     */
    DiColorPixelTemplate(const DiDocument *docu,
                         const DiInputPixel *pixel,
                         const Uint16 samples,
                         EI_Status &status,
                         const Uint16 sample_rate = 0)
      : DiColorPixel(docu, pixel, samples, status, sample_rate)
    {
        Data[0] = NULL;
        Data[1] = NULL;
        Data[2] = NULL;
    }

    /** destructor
     */
    virtual ~DiColorPixelTemplate()
    {
        delete[] Data[0];
        delete[] Data[1];
        delete[] Data[2];
    }

    /** get integer representation
     *
     ** @return integer representation of the internally stored pixel data
     */
    inline EP_Representation getRepresentation() const
    {
        return DiPixelRepresentationTemplate<T>::getRepresentation();
    }

    /** get pointer to internal array of pixel data.
     *  The returned array [0..2] points to the three image planes.
     *
     ** @return pointer to array of pixel data
     */
    inline const void *getData() const
    {
        return OFstatic_cast(const void *, Data);
    }

    /** get pointer to internal array of pixel data.
     *  The returned array [0..2] points to the three image planes.
     *
     ** @return pointer to array of pixel data
     */
    inline void *getDataPtr()
    {
        return OFstatic_cast(void *, Data);
    }

    /** get pointer to internal array of pixel data.
     *  The returned array [0..2] points to the three image planes.
     *
     ** @return reference to pointer to pixel data
     */
    inline void *getDataArrayPtr()
    {
        return OFstatic_cast(void *, Data);
    }

    /** fill given memory block with pixel data (all three image planes, RGB).
     *  Currently, the samples are always ordered by plane, thus the DICOM attribute
     *  'PlanarConfiguration' has to be set to '1'.
     *
     ** @param  data   pointer to memory block (array of 8 or 16 bit values, OB/OW)
     *  @param  count  number of T-size entries allocated in the 'data' array
     *
     ** @return OFTrue if successful, OFFalse otherwise
     */
    OFBool getPixelData(void *data,
                        const size_t count) const
    {
        OFBool result = OFFalse;
        /* check parameters and internal data */
        if ((data != NULL) && (count >= Count * 3) &&
            (Data[0] != NULL) && (Data[1] != NULL) && (Data[2] != NULL))
        {
            /* copy all three planes to the given memory block */
            OFBitmanipTemplate<T>::copyMem(Data[0], OFstatic_cast(T *, data), Count);
            OFBitmanipTemplate<T>::copyMem(Data[1], OFstatic_cast(T *, data) + Count, Count);
            OFBitmanipTemplate<T>::copyMem(Data[2], OFstatic_cast(T *, data) + 2 * Count, Count);
            result = OFTrue;
        }
        return result;
    }

    /** create true color (24/32 bit) bitmap for MS Windows.
     *
     ** @param  data        untyped pointer memory buffer (set to NULL if not allocated externally)
     *  @param  size        size of the memory buffer in bytes (if 0 'data' is set to NULL)
     *  @param  width       number of columns of the image
     *  @param  height      number of rows of the image
     *  @param  frame       index of frame to be converted (starting from 0)
     *  @param  fromBits    number of bits per sample used for internal representation of the image
     *  @param  toBits      number of bits per sample used for the output bitmap (<= 8)
     *  @param  mode        color output mode (24 or 32 bits, see dcmimgle/dcmimage.h for details)
     *  @param  upsideDown  specifies the order of lines in the images (0 = top-down, bottom-up otherwise)
     *  @param  padding     align each line to a 32-bit address if true
     *
     ** @return number of bytes allocated by the bitmap, or 0 if an error occured
     */
    unsigned int createDIB(void *&data,
                            const unsigned int size,
                            const Uint16 width,
                            const Uint16 height,
                            const unsigned int frame,
                            const int fromBits,
                            const int toBits,
                            const int mode,
                            const int upsideDown,
                            const int padding) const
    {
        unsigned int bytes = 0;
        if ((Data[0] != NULL) && (Data[1] != NULL) && (Data[2] != NULL) && (toBits <= 8))
        {
            const unsigned int count = OFstatic_cast(unsigned int, width) * OFstatic_cast(unsigned int, height);
            const unsigned int start = count * frame + ((upsideDown) ?
                OFstatic_cast(unsigned int, height - 1) * OFstatic_cast(unsigned int, width) : 0);
            const signed int nextRow = (upsideDown) ? -2 * OFstatic_cast(signed int, width) : 0;
            const T *r = Data[0] + start;
            const T *g = Data[1] + start;
            const T *b = Data[2] + start;
            Uint16 x;
            Uint16 y;
            if (mode == 24)     // 24 bits per pixel
            {
                const unsigned int wid3 = OFstatic_cast(unsigned int, width) * 3;
                // each line has to start at 32-bit-address, if 'padding' is true
                const int gap = (padding) ? OFstatic_cast(int, (4 - wid3 & 0x3) & 0x3) : 0;
                unsigned int fsize = (wid3 + gap) * OFstatic_cast(unsigned int, height);
                if ((data == NULL) || (size >= fsize))
                {
                    if (data == NULL)
                        data = new Uint8[fsize];
                    if (data != NULL)
                    {
                        Uint8 *q = OFstatic_cast(Uint8 *, data);
                        if (fromBits == toBits)
                        {
                            /* copy pixel data as is */
                            for (y = height; y != 0; y--)
                            {
                                for (x = width; x != 0; x--)
                                {
                                    /* reverse sample order: B-G-R */
                                    *(q++) = OFstatic_cast(Uint8, *(b++));
                                    *(q++) = OFstatic_cast(Uint8, *(g++));
                                    *(q++) = OFstatic_cast(Uint8, *(r++));
                                }
                                r += nextRow; g += nextRow; b += nextRow;           // go backwards if 'upsideDown'
                                q += gap;                                           // new line: jump to next 32-bit address
                            }
                        }
                        else if (fromBits < toBits)
                        {
                            /* increase color depth: multiply with factor */
                            const double gradient1 = OFstatic_cast(double, DicomImageClass::maxval(toBits)) /
                                                     OFstatic_cast(double, DicomImageClass::maxval(fromBits));
                            const Uint8 gradient2 = OFstatic_cast(Uint8, gradient1);
                            if (gradient1 == OFstatic_cast(double, gradient2))      // integer multiplication?
                            {
                                for (y = height; y != 0; y--)
                                {
                                    for (x = width; x != 0; x--)
                                    {
                                        /* reverse sample order: B-G-R */
                                        *(q++) = OFstatic_cast(Uint8, *(b++) * gradient2);
                                        *(q++) = OFstatic_cast(Uint8, *(g++) * gradient2);
                                        *(q++) = OFstatic_cast(Uint8, *(r++) * gradient2);
                                    }
                                    r += nextRow; g += nextRow; b += nextRow;       // go backwards if 'upsideDown'
                                    q += gap;                                       // new line: jump to next 32-bit address
                                }
                            } else {
                                for (y = height; y != 0; y--)
                                {
                                    for (x = width; x != 0; x--)
                                    {
                                        /* reverse sample order: B-G-R */
                                        *(q++) = OFstatic_cast(Uint8, OFstatic_cast(double, *(b++)) * gradient1);
                                        *(q++) = OFstatic_cast(Uint8, OFstatic_cast(double, *(g++)) * gradient1);
                                        *(q++) = OFstatic_cast(Uint8, OFstatic_cast(double, *(r++)) * gradient1);
                                    }
                                    r += nextRow; g += nextRow; b += nextRow;       // go backwards if 'upsideDown'
                                    q += gap;                                       // new line: jump to next 32-bit address
                                }
                            }
                        }
                        else /* fromBits > toBits */
                        {
                            /* reduce color depth: right shift */
                            const int shift = fromBits - toBits;
                            for (y = height; y != 0; y--)
                            {
                                for (x = width; x != 0; x--)
                                {
                                    /* reverse sample order: B-G-R */
                                    *(q++) = OFstatic_cast(Uint8, *(b++) >> shift);
                                    *(q++) = OFstatic_cast(Uint8, *(g++) >> shift);
                                    *(q++) = OFstatic_cast(Uint8, *(r++) >> shift);
                                }
                                r += nextRow; g += nextRow; b += nextRow;           // go backwards if 'upsideDown'
                                q += gap;                                           // new line: jump to next 32-bit address
                            }
                        }
                        bytes = fsize;
                    }
                }
            }
            else if (mode == 32)     // 32 bits per pixel
            {
                const unsigned int fsize = count * 4;
                if ((data == NULL) || (size >= fsize))
                {
                    if (data == NULL)
                        data = new Uint32[count];
                    if (data != NULL)
                    {
                        Uint32 *q = OFstatic_cast(Uint32 *, data);
                        if (fromBits == toBits)
                        {
                            /* copy pixel data as is */
                            for (y = height; y != 0; y--)
                            {
                                for (x = width; x != 0; x--)
                                {
                                    /* reverse sample order: B-G-R-0 */
                                    *(q++) = (OFstatic_cast(Uint32, *(b++)) << 24) |
                                             (OFstatic_cast(Uint32, *(g++)) << 16) |
                                             (OFstatic_cast(Uint32, *(r++)) << 8);
                                }
                                r += nextRow; g += nextRow; b += nextRow;           // go backwards if 'upsideDown'
                            }
                        }
                        else if (fromBits < toBits)
                        {
                            /* increase color depth: multiply with factor */
                            const double gradient1 = OFstatic_cast(double, DicomImageClass::maxval(toBits)) /
                                                     OFstatic_cast(double, DicomImageClass::maxval(fromBits));
                            const Uint32 gradient2 = OFstatic_cast(Uint32, gradient1);
                            if (gradient1 == OFstatic_cast(double, gradient2))      // integer multiplication?
                            {
                                for (y = height; y != 0; y--)
                                {
                                    for (x = width; x != 0; x--)
                                    {
                                        /* reverse sample order: B-G-R-0 */
                                        *(q++) = (OFstatic_cast(Uint32, *(b++) * gradient2) << 24) |
                                                 (OFstatic_cast(Uint32, *(g++) * gradient2) << 16) |
                                                 (OFstatic_cast(Uint32, *(r++) * gradient2) << 8);
                                    }
                                    r += nextRow; g += nextRow; b += nextRow;       // go backwards if 'upsideDown'
                                }
                            } else {
                                for (y = height; y != 0; y--)
                                {
                                    for (x = width; x != 0; x--)
                                    {
                                        /* reverse sample order: B-G-R-0 */
                                        *(q++) = (OFstatic_cast(Uint32, OFstatic_cast(double, *(b++)) * gradient1) << 24) |
                                                 (OFstatic_cast(Uint32, OFstatic_cast(double, *(g++)) * gradient1) << 16) |
                                                 (OFstatic_cast(Uint32, OFstatic_cast(double, *(r++)) * gradient1) << 8);
                                    }
                                    r += nextRow; g += nextRow; b += nextRow;       // go backwards if 'upsideDown'
                                }
                            }
                        }
                        else /* fromBits > toBits */
                        {
                            /* reduce color depth: right shift */
                            const int shift = fromBits - toBits;
                            for (y = height; y != 0; y--)
                            {
                                for (x = width; x != 0; x--)
                                {
                                    /* reverse sample order: B-G-R-0 */
                                    *(q++) = (OFstatic_cast(Uint32, *(b++) >> shift) << 24) |
                                             (OFstatic_cast(Uint32, *(g++) >> shift) << 16) |
                                             (OFstatic_cast(Uint32, *(r++) >> shift) << 8);
                                }
                                r += nextRow; g += nextRow; b += nextRow;           // go backwards if 'upsideDown'
                            }
                        }
                        bytes = fsize;
                    }
                }
            }
        }
        return bytes;
    }

    /** create true color (32 bit) bitmap for Java (AWT default format).
     *
     ** @param  data      resulting pointer to bitmap data (set to NULL if an error occurred)
     *  @param  width     number of columns of the image
     *  @param  height    number of rows of the image
     *  @param  frame     index of frame to be converted (starting from 0)
     *  @param  fromBits  number of bits per sample used for internal representation of the image
     *  @param  toBits    number of bits per sample used for the output bitmap (<= 8)
     *
     ** @return number of bytes allocated by the bitmap, or 0 if an error occured
     */
    unsigned int createAWTBitmap(void *&data,
                                  const Uint16 width,
                                  const Uint16 height,
                                  const unsigned int frame,
                                  const int fromBits,
                                  const int toBits) const
    {
        data = NULL;
        unsigned int bytes = 0;
        if ((Data[0] != NULL) && (Data[1] != NULL) && (Data[2] != NULL) && (toBits <= 8))
        {
            const unsigned int count = OFstatic_cast(unsigned int, width) * OFstatic_cast(unsigned int, height);
            data = new Uint32[count];
            if (data != NULL)
            {
                const unsigned int start = count * frame;
                const T *r = Data[0] + start;
                const T *g = Data[1] + start;
                const T *b = Data[2] + start;
                Uint32 *q = OFstatic_cast(Uint32 *, data);
                unsigned int i;
                if (fromBits == toBits)
                {
                    /* copy pixel data as is */
                    for (i = count; i != 0; --i)
                    {
                        /* sample order: R-G-B */
                        *(q++) = (OFstatic_cast(Uint32, *(r++)) << 24) |
                                 (OFstatic_cast(Uint32, *(g++)) << 16) |
                                 (OFstatic_cast(Uint32, *(b++)) << 8);
                    }
                }
                else if (fromBits < toBits)
                {
                    /* increase color depth: multiply with factor */
                    const double gradient1 = OFstatic_cast(double, DicomImageClass::maxval(toBits)) /
                                             OFstatic_cast(double, DicomImageClass::maxval(fromBits));
                    const Uint32 gradient2 = OFstatic_cast(Uint32, gradient1);
                    if (gradient1 == OFstatic_cast(double, gradient2))         // integer multiplication?
                    {
                        for (i = count; i != 0; --i)
                        {
                            /* sample order: R-G-B */
                            *(q++) = (OFstatic_cast(Uint32, *(r++) * gradient2) << 24) |
                                     (OFstatic_cast(Uint32, *(g++) * gradient2) << 16) |
                                     (OFstatic_cast(Uint32, *(b++) * gradient2) << 8);
                        }
                    } else {
                        for (i = count; i != 0; --i)
                        {
                            /* sample order: R-G-B */
                            *(q++) = (OFstatic_cast(Uint32, OFstatic_cast(double, *(r++)) * gradient1) << 24) |
                                     (OFstatic_cast(Uint32, OFstatic_cast(double, *(g++)) * gradient1) << 16) |
                                     (OFstatic_cast(Uint32, OFstatic_cast(double, *(b++)) * gradient1) << 8);
                        }
                    }
                }
                else /* fromBits > toBits */
                {
                    /* reduce color depth: right shift */
                    const int shift = fromBits - toBits;
                    for (i = count; i != 0; --i)
                    {
                        /* sample order: R-G-B */
                        *(q++) = (OFstatic_cast(Uint32, *(r++) >> shift) << 24) |
                                 (OFstatic_cast(Uint32, *(g++) >> shift) << 16) |
                                 (OFstatic_cast(Uint32, *(b++) >> shift) << 8);
                    }
                }
                bytes = count * 4;
            }
        }
        return bytes;
    }


 protected:

    /** constructor
     *
     ** @param  pixel  pointer to intermediate color pixel data
     *  @param  count  number of pixels
     */
    DiColorPixelTemplate(const DiColorPixel *pixel,
                         const unsigned int count)
      : DiColorPixel(pixel, count)
    {
        Data[0] = NULL;
        Data[1] = NULL;
        Data[2] = NULL;
    }

    /** initialize internal memory
     *
     ** @param  pixel  pointer to input pixel data
     *
     ** @return true (1) if successful, false (0) otherwise
     */
    inline int Init(const void *pixel)
    {
        int result = 0;
        if (pixel != NULL)
        {
            result = 1;
            /* allocate data buffer for the 3 planes */
            for (int j = 0; j < 3; j++)
            {
                Data[j] = new T[Count];
                if (Data[j] != NULL)
                {
                    /* erase empty part of the buffer (=blacken the background) */
                    if (InputCount < Count)
                        OFBitmanipTemplate<T>::zeroMem(Data[j] + InputCount, Count - InputCount);
                } else
                    result = 0;     // at least one buffer could not be allocated!
            }
        }
        return result;
    }


    /// pointer to pixel data (3 components)
    T *Data[3];


 private:

 // --- declarations to avoid compiler warnings

    DiColorPixelTemplate(const DiColorPixelTemplate<T> &);
    DiColorPixelTemplate<T> &operator=(const DiColorPixelTemplate<T> &);
};


#endif


/*
 *
 * CVS/RCS Log:
 * $Log: dicopxt.h,v $
 * Revision 1.1  2006/03/01 20:15:35  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.25  2005/12/08 16:01:35  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.24  2004/10/19 12:57:47  joergr
 * Enhanced API documentation.
 *
 * Revision 1.23  2004/02/06 11:18:18  joergr
 * Distinguish more clearly between const and non-const access to pixel data.
 *
 * Revision 1.22  2004/01/21 12:59:43  meichel
 * Added OFconst_cast, needed for Visual C++ 6
 *
 * Revision 1.21  2003/12/23 11:43:03  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Removed leading underscore characters from preprocessor symbols (reserved
 * symbols). Updated copyright header. Added missing API documentation.
 * Replaced post-increment/decrement operators by pre-increment/decrement
 * operators where appropriate (e.g. 'i++' by '++i').
 *
 * Revision 1.20  2002/12/10 17:39:50  meichel
 * Added explicit type cast to avoid compilation error on gcc 3.2
 *
 * Revision 1.19  2002/12/09 13:37:24  joergr
 * Added private undefined copy constructor and/or assignment operator.
 * Fixed bug that caused method createAWTBitmap() to return always empty pixel
 * data.
 *
 * Revision 1.18  2002/09/12 14:10:37  joergr
 * Replaced "createPixelData" by "getPixelData" which uses a new dcmdata
 * routine and is therefore more efficient.
 *
 * Revision 1.17  2002/08/29 12:57:49  joergr
 * Added method that creates pixel data in DICOM format.
 *
 * Revision 1.16  2002/06/26 16:17:41  joergr
 * Enhanced handling of corrupted pixel data and/or length.
 *
 * Revision 1.15  2002/01/29 17:07:08  joergr
 * Added optional flag to the "Windows DIB" methods allowing to switch off the
 * scanline padding.
 *
 * Revision 1.14  2001/12/11 14:23:44  joergr
 * Added type cast to keep old Sun compilers quiet.
 *
 * Revision 1.13  2001/11/09 16:44:35  joergr
 * Enhanced and renamed createTrueColorDIB() method.
 *
 * Revision 1.12  2001/06/01 15:49:29  meichel
 * Updated copyright header
 *
 * Revision 1.11  2000/03/08 16:21:51  meichel
 * Updated copyright header.
 *
 * Revision 1.10  1999/09/17 14:03:44  joergr
 * Enhanced efficiency of some "for" loops.
 *
 * Revision 1.9  1999/07/23 13:22:29  joergr
 * emoved inline method 'removeSign'which is no longer needed.
 *
 * Revision 1.8  1999/04/28 12:51:58  joergr
 * Corrected some typos, comments and formatting.
 *
 * Revision 1.7  1999/01/20 14:44:49  joergr
 * Corrected some typos and formatting.
 *
 * Revision 1.6  1998/11/27 13:50:20  joergr
 * Added copyright message. Replaced delete by delete[] for array types.
 * Added method to give direct (non const) access to internal data buffer.
 *
 * Revision 1.5  1998/05/11 14:53:13  joergr
 * Added CVS/RCS header to each file.
 *
 *
 */
