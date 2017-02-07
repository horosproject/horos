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
 *  Purpose: DicomRotateTemplate (Header)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:36 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef DIROTAT_H
#define DIROTAT_H

#include "osconfig.h"
#include "ofcast.h"
#include "dctypes.h"

#include "dipixel.h"
#include "ditranst.h"


/*---------------------*
 *  class declaration  *
 *---------------------*/

/** Template class to rotate images (on pixel data level).
 *  by steps of 90 degrees
 */
template<class T>
class DiRotateTemplate
  : public DiTransTemplate<T>
{

 public:

    /** constructor.
     *  This method is used to rotate an image and store the result in the same storage area.
     *
     ** @param  pixel      pointer to object where the pixel data are stored
     *  @param  src_cols   original width of the image
     *  @param  src_rows   original height of the image
     *  @param  dest_cols  new width of the image
     *  @param  dest_rows  new height of the image
     *  @param  frames     number of frames
     *  @param  degree     angle by which the image should be rotated
     */
    DiRotateTemplate(DiPixel *pixel,
                     const Uint16 src_cols,
                     const Uint16 src_rows,
                     const Uint16 dest_cols,
                     const Uint16 dest_rows,
                     const Uint32 frames,
                     const int degree)
      : DiTransTemplate<T>(0, src_cols, src_rows, dest_cols, dest_rows, frames)
    {
        if (pixel != NULL)
        {
            this->Planes = pixel->getPlanes();
            if ((pixel->getCount() > 0) && (this->Planes > 0) &&
                (pixel->getCount() == OFstatic_cast(unsigned int, src_cols) * OFstatic_cast(unsigned int, src_rows) * frames))
            {
                if (degree == 90)
                    rotateRight(OFstatic_cast(T **, pixel->getDataArrayPtr()));
                else if (degree == 180)
                    rotateTopDown(OFstatic_cast(T **, pixel->getDataArrayPtr()));
                else if (degree == 270)
                    rotateLeft(OFstatic_cast(T **, pixel->getDataArrayPtr()));
            } else {
                if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Warnings))
                {
                   ofConsole.lockCerr() << "WARNING: could not rotate image ... corrupted data." << endl;
                   ofConsole.unlockCerr();
                }
            }
        }
    }

    /** constructor.
     *  This method is used to perform only the preparation and to start rotation later with method 'rotateData()'
     *
     ** @param  planes     number of planes (1 or 3)
     *  @param  src_cols   original width of the image
     *  @param  src_rows   original height of the image
     *  @param  dest_cols  new width of the image
     *  @param  dest_rows  new height of the image
     *  @param  frames     number of frames
     */
    DiRotateTemplate(const int planes,
                     const Uint16 src_cols,
                     const Uint16 src_rows,
                     const Uint16 dest_cols,
                     const Uint16 dest_rows,
                     const Uint32 frames)
      : DiTransTemplate<T>(planes, src_cols, src_rows, dest_cols, dest_rows, frames)
    {
    }

    /** destructor
     */
    virtual ~DiRotateTemplate()
    {
    }

    /** choose algorithm depending on rotation angle
     *
     ** @param  src     array of pointers to source image pixels
     *  @param  dest    array of pointers to destination image pixels
     *  @param  degree  angle by which the image should be rotated
     */
    inline void rotateData(const T *src[],
                           T *dest[],
                           const int degree)
    {
        if (degree == 90)
            rotateRight(src, dest);
        else if (degree == 180)
            rotateTopDown(src, dest);
        else if (degree == 270)
            rotateLeft(src, dest);
        else
            this->copyPixel(src, dest);
    }


 protected:

   /** rotate source image left and store result in destination image
    *
    ** @param  src   array of pointers to source image pixels
    *  @param  dest  array of pointers to destination image pixels
    */
    inline void rotateLeft(const T *src[],
                           T *dest[])
    {
        if ((src != NULL) && (dest != NULL))
        {
            Uint16 x;
            Uint16 y;
            const T *p;
            T *q;
            T *r;
            const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y);
            for (int j = 0; j < this->Planes; ++j)
            {
                p = src[j];
                r = dest[j];
                for (unsigned int f = this->Frames; f != 0; --f)
                {
                    r += count;
                    for (x = this->Dest_X; x != 0; --x)
                    {
                        q = r - x;
                        for (y = this->Dest_Y; y != 0; --y)
                        {
                            *q = *p++;
                            q -= this->Dest_X;
                        }
                    }
                }
            }
        }
    }

   /** rotate source image right and store result in destination image
    *
    ** @param  src   array of pointers to source image pixels
    *  @param  dest  array of pointers to destination image pixels
    */
    inline void rotateRight(const T *src[],
                            T *dest[])
    {
        if ((src != NULL) && (dest != NULL))
        {
            Uint16 x;
            Uint16 y;
            const T *p;
            T *q;
            T *r;
            const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y);
            for (int j = 0; j < this->Planes; ++j)
            {
                p = src[j];
                r = dest[j];
                for (unsigned int f = this->Frames; f != 0; --f)
                {
                    for (x = this->Dest_X; x != 0; --x)
                    {
                        q = r + x - 1;
                        for (y = this->Dest_Y; y != 0; --y)
                        {
                            *q = *p++;
                            q += this->Dest_X;
                        }
                    }
                    r += count;
                }
            }
        }
    }

   /** rotate source image top-down and store result in destination image
    *
    ** @param  src   array of pointers to source image pixels
    *  @param  dest  array of pointers to destination image pixels
    */
    inline void rotateTopDown(const T *src[],
                              T *dest[])
    {
        if ((src != NULL) && (dest != NULL))
        {
            unsigned int i;
            const T *p;
            T *q;
            const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y);
            for (int j = 0; j < this->Planes; ++j)
            {
                p = src[j];
                q = dest[j];
                for (unsigned int f = this->Frames; f != 0; --f)
                {
                    q += count;
                    for (i = count; i != 0; --i)
                        *--q = *p++;
                    q += count;
                }
            }
        }
    }

 private:

   /** rotate image left and store result in the same storage area
    *
    ** @param  data  array of pointers to source/destination image pixels
    */
    inline void rotateLeft(T *data[])
    {
        const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y);
        T *temp = new T[count];
        if (temp != NULL)
        {
            Uint16 x;
            Uint16 y;
            const T *p;
            T *q;
            T *r;
            for (int j = 0; j < this->Planes; ++j)
            {
                r = data[j];
                for (unsigned int f = this->Frames; f != 0; --f)
                {
                    OFBitmanipTemplate<T>::copyMem(OFstatic_cast(const T *, r), temp, count);  // create temporary copy of current frame
                    p = temp;
                    r += count;
                    for (x = this->Dest_X; x != 0; --x)
                    {
                        q = r - x;
                        for (y = this->Dest_Y; y != 0; --y)
                        {
                            *q = *p++;
                            q -= this->Dest_X;
                        }
                    }
                }
            }
            delete[] temp;
        }
    }

   /** rotate image right and store result in the same storage area
    *
    ** @param  data  array of pointers to source/destination image pixels
    */
    inline void rotateRight(T *data[])
    {
        const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y);
        T *temp = new T[count];
        if (temp != NULL)
        {
            Uint16 x;
            Uint16 y;
            const T *p;
            T *q;
            T *r;
            for (int j = 0; j < this->Planes; ++j)
            {
                r = data[j];
                for (unsigned int f = this->Frames; f != 0; --f)
                {
                    OFBitmanipTemplate<T>::copyMem(OFstatic_cast(const T *, r), temp, count);  // create temporary copy of current frame
                    p = temp;
                    for (x = this->Dest_X; x != 0; --x)
                    {
                        q = r + x - 1;
                        for (y = this->Dest_Y; y != 0; --y)
                        {
                            *q = *p++;
                            q += this->Dest_X;
                        }
                    }
                    r += count;
                }
            }
            delete[] temp;
        }
    }

   /** rotate image top-down and store result in the same storage area
    *
    ** @param  data  array of pointers to source/destination image pixels
    */
    inline void rotateTopDown(T *data[])
    {
        unsigned int i;
        T *p;
        T *q;
        T t;
        T *s;
        const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y);
        for (int j = 0; j < this->Planes; ++j)
        {
            s = data[j];
            for (unsigned int f = this->Frames; f != 0; --f)
            {
                p = s;
                q = s + count;
                for (i = count / 2; i != 0; --i)
                {
                    t = *p;
                    *p++ = *--q;
                    *q = t;
                }
                s += count;
            }
        }
    }
};


#endif


/*
 *
 * CVS/RCS Log:
 * $Log: dirotat.h,v $
 * Revision 1.1  2006/03/01 20:15:36  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.16  2005/12/08 16:48:08  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.15  2005/06/15 08:23:54  joergr
 * Fixed bug which prevented rotateTopDown() from rotating multi-frame images
 * correctly (only the first frame was actually rotated).
 *
 * Revision 1.14  2004/04/21 10:00:36  meichel
 * Minor modifications for compilation with gcc 3.4.0
 *
 * Revision 1.13  2004/02/06 11:07:50  joergr
 * Distinguish more clearly between const and non-const access to pixel data.
 *
 * Revision 1.12  2003/12/23 15:53:22  joergr
 * Replaced post-increment/decrement operators by pre-increment/decrement
 * operators where appropriate (e.g. 'i++' by '++i').
 *
 * Revision 1.11  2003/12/09 10:14:54  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Removed leading underscore characters from preprocessor symbols (reserved
 * symbols). Updated copyright header.
 *
 * Revision 1.10  2001/06/01 15:49:50  meichel
 * Updated copyright header
 *
 * Revision 1.9  2000/09/12 10:04:45  joergr
 * Corrected bug: wrong parameter for attribute search routine led to crashes
 * when multiple pixel data attributes were contained in the dataset (e.g.
 * IconImageSequence). Added new checking routines to avoid crashes when
 * processing corrupted image data.
 *
 * Revision 1.8  2000/03/08 16:24:24  meichel
 * Updated copyright header.
 *
 * Revision 1.7  2000/03/02 12:51:37  joergr
 * Rewrote variable initialization in class contructors to avoid warnings
 * reported on Irix.
 *
 * Revision 1.6  1999/09/17 13:07:20  joergr
 * Added/changed/completed DOC++ style comments in the header files.
 * Enhanced efficiency of some "for" loops.
 *
 * Revision 1.5  1999/03/24 17:17:20  joergr
 * Removed debug code.
 * Added/Modified comments and formatting.
 *
 * Revision 1.4  1999/01/20 15:12:47  joergr
 * Added debug code to measure time of some routines.
 *
 * Revision 1.3  1998/12/16 16:38:49  joergr
 * Added additional case to copy pixels.
 *
 * Revision 1.2  1998/12/14 17:30:49  joergr
 * Added (missing) implementation of methods to rotate images/frames without
 * creating a new DicomImage.
 *
 * Revision 1.1  1998/11/27 14:57:46  joergr
 * Added copyright message.
 * Added methods and classes for flipping and rotating, changed for
 * scaling and clipping.
 *
 *
 */
