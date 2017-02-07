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
 *  Purpose: DicomScaleTemplates (Header)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:36 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef DISCALET_H
#define DISCALET_H

#include "osconfig.h"
#include "dctypes.h"
#include "ofconsol.h"
#include "ofcast.h"
#include "ofstream.h"

#include "ditranst.h"
#include "dipxrept.h"
#include "diutils.h"


/*---------------------*
 *  macro definitions  *
 *---------------------*/

#define SCALE_FACTOR 4096
#define HALFSCALE_FACTOR 2048


/*--------------------*
 *  helper functions  *
 *--------------------*/

// help function to set scaling values

static inline void setScaleValues(Uint16 data[],
                                  const Uint16 min,
                                  const Uint16 max)
{
    Uint16 remainder = max % min;
    Uint16 step0 = max / min;
    Uint16 step1 = max / min;
    if (remainder > OFstatic_cast(Uint16, min / 2))
    {
        remainder = min - remainder;
        ++step0;
    } else
        ++step1;
    const double count = OFstatic_cast(double, min) / (OFstatic_cast(double, remainder) + 1);
    Uint16 i;
    double c = count;
    for (i = 0; i < min; ++i)
    {
        if ((i >= OFstatic_cast(Uint16, c)) && (remainder > 0))
        {
            --remainder;
            c += count;
            data[i] = step1;
        }
        else
            data[i] = step0;
    }
}


/*---------------------*
 *  class declaration  *
 *---------------------*/

/** Template class to scale images (on pixel data level).
 *  with and without interpolation
 */
template<class T>
class DiScaleTemplate
  : public DiTransTemplate<T>
{

 public:

    /** constructor, scale clipping area.
     *
     ** @param  planes     number of planes (1 or 3)
     *  @param  columns    width of source image
     *  @param  rows       height of source image
     *  @param  left_pos   left coordinate of clipping area
     *  @param  top_pos    top coordinate of clipping area
     *  @param  src_cols   width of clipping area
     *  @param  src_rows   height of clipping area
     *  @param  dest_cols  width of destination image (scaled image)
     *  @param  dest_rows  height of destination image
     *  @param  frames     number of frames
     *  @param  bits       number of bits per plane/pixel
     */
    DiScaleTemplate(const int planes,
                    const Uint16 columns,           /* resolution of source image */
                    const Uint16 rows,
                    const signed int left_pos,     /* origin of clipping area */
                    const signed int top_pos,
                    const Uint16 src_cols,          /* extension of clipping area */
                    const Uint16 src_rows,
                    const Uint16 dest_cols,         /* extension of destination image */
                    const Uint16 dest_rows,
                    const Uint32 frames,            /* number of frames */
                    const int bits = 0)
      : DiTransTemplate<T>(planes, src_cols, src_rows, dest_cols, dest_rows, frames, bits),
        Left(left_pos),
        Top(top_pos),
        Columns(columns),
        Rows(rows)
    {
    }

    /** constructor, scale whole image.
     *
     ** @param  planes     number of planes (1 or 3)
     *  @param  src_cols   width of source image
     *  @param  src_rows   height of source image
     *  @param  dest_cols  width of destination image (scaled image)
     *  @param  dest_rows  height of destination image
     *  @param  frames     number of frames
     *  @param  bits       number of bits per plane/pixel
     */
    DiScaleTemplate(const int planes,
                    const Uint16 src_cols,          /* resolution of source image */
                    const Uint16 src_rows,
                    const Uint16 dest_cols,         /* resolution of destination image */
                    const Uint16 dest_rows,
                    const Uint32 frames,            /* number of frames */
                    const int bits = 0)
      : DiTransTemplate<T>(planes, src_cols, src_rows, dest_cols, dest_rows, frames, bits),
        Left(0),
        Top(0),
        Columns(src_cols),
        Rows(src_rows)
    {
    }

    /** destructor
     */
    virtual ~DiScaleTemplate()
    {
    }

    /** choose scaling/clipping algorithm depending on specified parameters.
     *
     ** @param  src          array of pointers to source image pixels
     *  @param  dest         array of pointers to destination image pixels
     *  @param  interpolate  interpolation algorithm (0 = no interpolation, 1 = pbmplus algorithm, 2 = c't algorithm)
     *  @param  value        value to be set outside the image boundaries (used for clipping, default: 0)
     */
    void scaleData(const T *src[],               // combined clipping and scaling UNTESTED for multi-frame images !!
                   T *dest[],
                   const int interpolate,
                   const T value = 0)
    {
        if ((src != NULL) && (dest != NULL))
        {
#ifdef DEBUG
            if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_DebugMessages))
            {
                ofConsole.lockCout() << "C/R: " << Columns << " " << Rows << endl
                                     << "L/T: " << Left << " " << Top << endl
                                     << "SX/Y: " << this->Src_X << " " << this->Src_Y << endl
                                     << "DX/Y: " << this->Dest_X << " " << this->Dest_Y << endl;
                ofConsole.unlockCout();
            }
#endif
            if ((Left + OFstatic_cast(signed int, this->Src_X) <= 0) || (Top + OFstatic_cast(signed int, this->Src_Y) <= 0) ||
                (Left >= OFstatic_cast(signed int, Columns)) || (Top >= OFstatic_cast(signed int, Rows)))
            {                                                                   // no image to be displayed
#ifdef DEBUG
                if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                {
                    ofConsole.lockCerr() << "INFO: clipping area is fully outside the image boundaries !" << endl;
                    ofConsole.unlockCerr();
                }
#endif
                this->fillPixel(dest, value);                                         // ... fill bitmap
            }
            else if ((this->Src_X == this->Dest_X) && (this->Src_Y == this->Dest_Y))                    // no scaling
            {
                if ((Left == 0) && (Top == 0) && (Columns == this->Src_X) && (Rows == this->Src_Y))
                    this->copyPixel(src, dest);                                       // copying
                else if ((Left >= 0) && (OFstatic_cast(Uint16, Left + this->Src_X) <= Columns) &&
                         (Top >= 0) && (OFstatic_cast(Uint16, Top + this->Src_Y) <= Rows))
                    clipPixel(src, dest);                                       // clipping
                else
                    clipBorderPixel(src, dest, value);                          // clipping (with border)
            }
            else if ((interpolate == 1) && (this->Bits <= MAX_INTERPOLATION_BITS))    // interpolation (pbmplus)
                interpolatePixel(src, dest);
            else if ((interpolate == 2) && (this->Dest_X >= this->Src_X) && (this->Dest_Y >= this->Src_Y))    // interpolated expansion (c't)
                expandPixel(src, dest);
            else if ((interpolate == 2) && (this->Src_X >= this->Dest_X) && (this->Src_Y >= this->Dest_Y))    // interpolated reduction (c't)
                reducePixel(src, dest);
            else if ((this->Dest_X % this->Src_X == 0) && (this->Dest_Y % this->Src_Y == 0))            // replication
                replicatePixel(src, dest);
            else if ((this->Src_X % this->Dest_X == 0) && (this->Src_Y % this->Dest_Y == 0))            // supression
                suppressPixel(src, dest);
            else                                                                // general scaling
                scalePixel(src, dest);
        }
    }

 protected:

    /// left coordinate of clipping area
    const signed int Left;
    /// top coordinate of clipping area
    const signed int Top;
    /// width of source image
    const Uint16 Columns;
    /// height of source image
    const Uint16 Rows;


 private:

    /** clip image to specified area (only inside image boundaries).
     *  This is an optimization of the more general method clipBorderPixel().
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void clipPixel(const T *src[],
                   T *dest[])
    {
        const unsigned int x_feed = Columns - this->Src_X;
        const unsigned int y_feed = OFstatic_cast(unsigned int, Rows - this->Src_Y) * OFstatic_cast(unsigned int, Columns);
        Uint16 x;
        Uint16 y;
        const T *p;
        T *q;
        for (int j = 0; j < this->Planes; ++j)
        {
            p = src[j] + OFstatic_cast(unsigned int, Top) * OFstatic_cast(unsigned int, Columns) + Left;
            q = dest[j];
            for (unsigned int f = this->Frames; f != 0; --f)
            {
                for (y = this->Dest_Y; y != 0; --y)
                {
                    for (x = this->Dest_X; x != 0; --x)
                        *(q++) = *(p++);
                    p += x_feed;
                }
                p += y_feed;
            }
        }
    }

    /** clip image to specified area and add a border if necessary.
     *  NOT fully tested - UNTESTED for multi-frame and multi-plane images !!
     *
     ** @param  src    array of pointers to source image pixels
     *  @param  dest   array of pointers to destination image pixels
     *  @param  value  value to be set outside the image boundaries
     */
    void clipBorderPixel(const T *src[],
                         T *dest[],
                         const T value)
    {
        const Uint16 s_left = (Left > 0) ? OFstatic_cast(Uint16, Left) : 0;
        const Uint16 s_top = (Top > 0) ? OFstatic_cast(Uint16, Top) : 0;
        const Uint16 d_left = (Left < 0 ? OFstatic_cast(Uint16, -Left) : 0);
        const Uint16 d_top = (Top < 0) ? OFstatic_cast(Uint16, -Top) : 0;
        const Uint16 d_right = (OFstatic_cast(unsigned int, this->Src_X) + OFstatic_cast(unsigned int, s_left) <
                                OFstatic_cast(unsigned int, Columns) + OFstatic_cast(unsigned int, d_left)) ?
                               (this->Src_X - 1) : (Columns + d_left - s_left - 1);
        const Uint16 d_bottom = (OFstatic_cast(unsigned int, this->Src_Y) + OFstatic_cast(unsigned int, s_top) <
                                 OFstatic_cast(unsigned int, Rows) + OFstatic_cast(unsigned int, d_top)) ?
                                (this->Src_Y - 1) : (Rows + d_top - s_top - 1);
        const Uint16 x_count = d_right - d_left + 1;
        const Uint16 y_count = d_bottom - d_top + 1;
        const unsigned int s_start = OFstatic_cast(unsigned int, s_top) * OFstatic_cast(unsigned int, Columns) + s_left;
        const unsigned int x_feed = Columns - x_count;
        const unsigned int y_feed = OFstatic_cast(unsigned int, Rows - y_count) * Columns;
        const unsigned int t_feed = OFstatic_cast(unsigned int, d_top) * OFstatic_cast(unsigned int, this->Src_X);
        const unsigned int b_feed = OFstatic_cast(unsigned int, this->Src_Y - d_bottom - 1) * OFstatic_cast(unsigned int, this->Src_X);

        /*
         *  The approach is to divide the destination image in up to four areas outside the source image
         *  plus one area for the source image. The for and while loops are scanning linearly over the
         *  destination image and setting the appropriate value depending on the current area. This is
         *  different from most of the other algorithms in this toolkit where the source image is scanned
         *  linearly.
         */
        Uint16 x;
        Uint16 y;
        unsigned int i;
        const T *p;
        T *q;
        for (int j = 0; j < this->Planes; ++j)
        {
            p = src[j] + s_start;
            q = dest[j];
            for (unsigned int f = this->Frames; f != 0; --f)
            {
                for (i = t_feed; i != 0; --i)               // top
                    *(q++) = value;
                for (y = y_count; y != 0; --y)              // middle part:
                {
                    x = 0;
                    while (x < d_left)                      // - left
                    {
                        *(q++) = value;
                        ++x;
                    }
                    while (x <= d_right)                    // - middle
                    {
                        *(q++) = *(p++);
                        ++x;
                    }
                    while (x < this->Src_X)                       // - right
                    {
                        *(q++) = value;
                        ++x;
                    }
                    p += x_feed;
                }
                for (i = b_feed; i != 0; --i)               // bottom
                    *(q++) = value;
                p += y_feed;
            }
        }
    }

    /** enlarge image by an integer factor.
     *  Pixels are replicated independently in both directions.
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void replicatePixel(const T *src[],
                        T *dest[])
    {
        const Uint16 x_factor = this->Dest_X / this->Src_X;
        const Uint16 y_factor = this->Dest_Y / this->Src_Y;
        const unsigned int x_feed = Columns;
        const unsigned int y_feed = OFstatic_cast(unsigned int, Rows - this->Src_Y) * OFstatic_cast(unsigned int, Columns);
        const T *sp;
        Uint16 x;
        Uint16 y;
        Uint16 dx;
        Uint16 dy;
        const T *p;
        T *q;
        T value;
        for (int j = 0; j < this->Planes; ++j)
        {
            sp = src[j] + OFstatic_cast(unsigned int, Top) * OFstatic_cast(unsigned int, Columns) + Left;
            q = dest[j];
            for (Uint32 f = this->Frames; f != 0; --f)
            {
                for (y = this->Src_Y; y != 0; --y)
                {
                    for (dy = y_factor; dy != 0; --dy)
                    {
                        for (x = this->Src_X, p = sp; x != 0; --x)
                        {
                            value = *(p++);
                            for (dx = x_factor; dx != 0; --dx)
                                *(q++) = value;
                        }
                    }
                    sp += x_feed;
                }
                sp += y_feed;
            }
        }
    }

    /** shrink image by an integer divisor
     *  Pixels are suppressed independently in both directions.
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void suppressPixel(const T *src[],
                       T *dest[])
    {
        const unsigned int x_divisor = this->Src_X / this->Dest_X;
        const unsigned int x_feed = OFstatic_cast(unsigned int, this->Src_Y / this->Dest_Y) * OFstatic_cast(unsigned int, Columns) - this->Src_X;
        const unsigned int y_feed = OFstatic_cast(unsigned int, Rows - this->Src_Y) * OFstatic_cast(unsigned int, Columns);
        Uint16 x;
        Uint16 y;
        const T *p;
        T *q;
        for (int j = 0; j < this->Planes; ++j)
        {
            p = src[j] + OFstatic_cast(unsigned int, Top) * OFstatic_cast(unsigned int, Columns) + Left;
            q = dest[j];
            for (Uint32 f = this->Frames; f != 0; --f)
            {
                for (y = this->Dest_Y; y != 0; --y)
                {
                    for (x = this->Dest_X; x != 0; --x)
                    {
                        *(q++) = *p;
                        p += x_divisor;
                    }
                    p += x_feed;
                }
                p += y_feed;
            }
        }
    }

    /** free scaling method without interpolation.
     *  This algorithm is necessary for overlays (1 bpp).
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void scalePixel(const T *src[],
                    T *dest[])
    {
        const Uint16 xmin = (this->Dest_X < this->Src_X) ? this->Dest_X : this->Src_X;      // minimum width
        const Uint16 ymin = (this->Dest_Y < this->Src_Y) ? this->Dest_Y : this->Src_Y;      // minimum height
        Uint16 *x_step = new Uint16[xmin];
        Uint16 *y_step = new Uint16[ymin];
        Uint16 *x_fact = new Uint16[xmin];
        Uint16 *y_fact = new Uint16[ymin];

       /*
        *  Approach: If one pixel line has to be added or removed it is taken from the middle of the image (1/2).
        *  For two lines it is at 1/3 and 2/3 of the image and so on. It sounds easy but it was a hard job ;-)
        */

        if ((x_step != NULL) && (y_step != NULL) && (x_fact != NULL) && (y_fact != NULL))
        {
            Uint16 x;
            Uint16 y;
            if (this->Dest_X < this->Src_X)
                setScaleValues(x_step, this->Dest_X, this->Src_X);
            else if (this->Dest_X > this->Src_X)
                setScaleValues(x_fact, this->Src_X, this->Dest_X);
            if (this->Dest_X <= this->Src_X)
                OFBitmanipTemplate<Uint16>::setMem(x_fact, 1, xmin);  // initialize with default values
            if (this->Dest_X >= this->Src_X)
                OFBitmanipTemplate<Uint16>::setMem(x_step, 1, xmin);  // initialize with default values
            x_step[xmin - 1] += Columns - this->Src_X;                      // skip to next line
            if (this->Dest_Y < this->Src_Y)
                setScaleValues(y_step, this->Dest_Y, this->Src_Y);
            else if (this->Dest_Y > this->Src_Y)
                setScaleValues(y_fact, this->Src_Y, this->Dest_Y);
            if (this->Dest_Y <= this->Src_Y)
                OFBitmanipTemplate<Uint16>::setMem(y_fact, 1, ymin);  // initialize with default values
            if (this->Dest_Y >= this->Src_Y)
                OFBitmanipTemplate<Uint16>::setMem(y_step, 1, ymin);  // initialize with default values
            y_step[ymin - 1] += Rows - this->Src_Y;                         // skip to next frame
            const T *sp;
            Uint16 dx;
            Uint16 dy;
            const T *p;
            T *q;
            T value;
            for (int j = 0; j < this->Planes; ++j)
            {
                sp = src[j] + OFstatic_cast(unsigned int, Top) * OFstatic_cast(unsigned int, Columns) + Left;
                q = dest[j];
                for (Uint32 f = 0; f < this->Frames; ++f)
                {
                    for (y = 0; y < ymin; ++y)
                    {
                        for (dy = 0; dy < y_fact[y]; ++dy)
                        {
                            for (x = 0, p = sp; x < xmin; ++x)
                            {
                                value = *p;
                                for (dx = 0; dx < x_fact[x]; ++dx)
                                    *(q++) = value;
                                p += x_step[x];
                            }
                        }
                        sp += OFstatic_cast(unsigned int, y_step[y]) * OFstatic_cast(unsigned int, Columns);
                    }
                }
            }
        }
        delete[] x_step;
        delete[] y_step;
        delete[] x_fact;
        delete[] y_fact;
    }


    /** free scaling method with interpolation.
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void interpolatePixel(const T *src[],
                          T *dest[])
    {
        if ((this->Src_X != Columns) || (this->Src_Y != Rows))
        {
            if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Errors))
            {
               ofConsole.lockCerr() << "ERROR: interpolated scaling and clipping at the same time not implemented" << endl
                                    << "       ... ignoring clipping region !" << endl;
               ofConsole.unlockCerr();
            }
            this->Src_X = Columns;            // temporarily removed 'const' for 'Src_X' in class 'DiTransTemplate'
            this->Src_Y = Rows;               //                             ... 'Src_Y' ...
        }

        /*
         *   based on scaling algorithm from "Extended Portable Bitmap Toolkit" (pbmplus10dec91)
         *   (adapted to be used with signed pixel representation and inverse images - mono2)
         */

        Uint16 x;
        Uint16 y;
        const T *p;
        T *q;
        T const *sp = NULL;                         // initialization avoids compiler warning
        T const *fp;
        T *sq;

        const unsigned int sxscale = OFstatic_cast(unsigned int, (OFstatic_cast(double, this->Dest_X) / OFstatic_cast(double, this->Src_X)) * SCALE_FACTOR);
        const unsigned int syscale = OFstatic_cast(unsigned int, (OFstatic_cast(double, this->Dest_Y) / OFstatic_cast(double, this->Src_Y)) * SCALE_FACTOR);
        DiPixelRepresentationTemplate<T> rep;
        const signed int maxvalue = DicomImageClass::maxval(this->Bits - rep.isSigned());

        T *xtemp = new T[this->Src_X];
        signed int *xvalue = new signed int[this->Src_X];

        if ((xtemp == NULL) || (xvalue == NULL))
        {
            if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Errors))
            {
                ofConsole.lockCerr() << "ERROR: can't allocate temporary buffers for interpolation scaling !" << endl;
                ofConsole.unlockCerr();
            }

            const unsigned int count = OFstatic_cast(unsigned int, this->Dest_X) * OFstatic_cast(unsigned int, this->Dest_Y) * this->Frames;
            for (int j = 0; j < this->Planes; ++j)
                OFBitmanipTemplate<T>::zeroMem(dest[j], count);     // delete destination buffer
        }
        else
        {
            for (int j = 0; j < this->Planes; ++j)
            {
                fp = src[j];
                sq = dest[j];
                for (Uint32 f = this->Frames; f != 0; --f)
                {
                    for (x = 0; x < this->Src_X; ++x)
                        xvalue[x] = HALFSCALE_FACTOR;
                    unsigned int yfill = SCALE_FACTOR;
                    unsigned int yleft = syscale;
                     int yneed = 1;
                    int ysrc = 0;
                    for (y = 0; y < this->Dest_Y; ++y)
                    {
                        if (this->Src_Y == this->Dest_Y)
                        {
                            sp = fp;
                            for (x = this->Src_X, p = sp, q = xtemp; x != 0; --x)
                                *(q++) = *(p++);
                            fp += this->Src_X;
                        }
                        else
                        {
                            while (yleft < yfill)
                            {
                                if (yneed && (ysrc < OFstatic_cast(int, this->Src_Y)))
                                {
                                    sp = fp;
                                    fp += this->Src_X;
                                    ++ysrc;
                                }
                                for (x = 0, p = sp; x < this->Src_X; ++x)
                                    xvalue[x] += yleft * OFstatic_cast(signed int, *(p++));
                                yfill -= yleft;
                                yleft = syscale;
                                yneed = 1;
                            }
                            if (yneed && (ysrc < OFstatic_cast(int, this->Src_Y)))
                            {
                                sp = fp;
                                fp += this->Src_X;
                                ++ysrc;
                                yneed = 0;
                            }
                            for (x = 0, p = sp, q = xtemp; x < this->Src_X; ++x)
                            {
                                 signed int v = xvalue[x] + yfill * OFstatic_cast(signed int, *(p++));
                                v /= SCALE_FACTOR;
                                *(q++) = OFstatic_cast(T, (v > maxvalue) ? maxvalue : v);
                                xvalue[x] = HALFSCALE_FACTOR;
                            }
                            yleft -= yfill;
                            if (yleft == 0)
                            {
                                yleft = syscale;
                                yneed = 1;
                            }
                            yfill = SCALE_FACTOR;
                        }
                        if (this->Src_X == this->Dest_X)
                        {
                            for (x = this->Dest_X, p = xtemp, q = sq; x != 0; --x)
                                *(q++) = *(p++);
                            sq += this->Dest_X;
                        }
                        else
                        {
                            signed int v = HALFSCALE_FACTOR;
                            unsigned int xfill = SCALE_FACTOR;
                            unsigned int xleft;
                            int xneed = 0;
                            q = sq;
                            for (x = 0, p = xtemp; x < this->Src_X; ++x, ++p)
                            {
                                xleft = sxscale;
                                while (xleft >= xfill)
                                {
                                    if (xneed)
                                    {
                                        ++q;
                                        v = HALFSCALE_FACTOR;
                                    }
                                    v += xfill * OFstatic_cast(signed int, *p);
                                    v /= SCALE_FACTOR;
                                    *q = OFstatic_cast(T, (v > maxvalue) ? maxvalue : v);
                                    xleft -= xfill;
                                    xfill = SCALE_FACTOR;
                                    xneed = 1;
                                }
                                if (xleft > 0)
                                {
                                    if (xneed)
                                    {
                                        ++q;
                                        v = HALFSCALE_FACTOR;
                                        xneed = 0;
                                    }
                                    v += xleft * OFstatic_cast(signed int, *p);
                                    xfill -= xleft;
                                }
                            }
                            if (xfill > 0)
                                v += xfill * OFstatic_cast(signed int, *(--p));
                            if (!xneed)
                            {
                                v /= SCALE_FACTOR;
                                *q = OFstatic_cast(T, (v > maxvalue) ? maxvalue : v);
                            }
                            sq += this->Dest_X;
                        }
                    }
                }
            }
        }
        delete[] xtemp;
        delete[] xvalue;
    }


    /** free scaling method with interpolation (only for expansion).
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void expandPixel(const T *src[],
                     T *dest[])
    {
#ifdef DEBUG
        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
        {
            ofConsole.lockCerr() << "INFO: expandPixel with interpolated c't algorithm" << endl;
            ofConsole.unlockCerr();
        }
#endif
        const double x_factor = OFstatic_cast(double, this->Src_X) / OFstatic_cast(double, this->Dest_X);
        const double y_factor = OFstatic_cast(double, this->Src_Y) / OFstatic_cast(double, this->Dest_Y);
        const unsigned int f_size = OFstatic_cast(unsigned int, Rows) * OFstatic_cast(unsigned int, Columns);
        const T *sp;
        double bx, ex;
        double by, ey;
        int bxi, exi;
        int byi, eyi;
        unsigned int offset;
        double value, sum;
        double x_part, y_part;
        double l_factor, r_factor;
        double t_factor, b_factor;
        int xi;
        int yi;
        Uint16 x;
        Uint16 y;
        const T *p;
        T *q;

        /*
         *   based on scaling algorithm from "c't - Magazin fuer Computertechnik" (c't 11/94)
         *   (adapted to be used with signed pixel representation and inverse images - mono1)
         */

        for (int j = 0; j < this->Planes; ++j)
        {
            sp = src[j] + OFstatic_cast(unsigned int, Top) * OFstatic_cast(unsigned int, Columns) + Left;
            q = dest[j];
            for (Uint32 f = 0; f < this->Frames; ++f)
            {
                for (y = 0; y < this->Dest_Y; ++y)
                {
                    by = y_factor * OFstatic_cast(double, y);
                    ey = y_factor * (OFstatic_cast(double, y) + 1.0);
                    byi = OFstatic_cast(int, by);
                    eyi = OFstatic_cast(int, ey);
                    if (OFstatic_cast(double, eyi) == ey)
                        --eyi;
                    y_part = OFstatic_cast(double, eyi) / y_factor;
                    b_factor = y_part - OFstatic_cast(double, y);
                    t_factor = (OFstatic_cast(double, y) + 1.0) - y_part;
                    for (x = 0; x < this->Dest_X; ++x)
                    {
                        value = 0;
                        bx = x_factor * OFstatic_cast(double, x);
                        ex = x_factor * (OFstatic_cast(double, x) + 1.0);
                        bxi = OFstatic_cast(int, bx);
                        exi = OFstatic_cast(int, ex);
                        if (OFstatic_cast(double, exi) == ex)
                            --exi;
                        x_part = OFstatic_cast(double, exi) / x_factor;
                        l_factor = x_part - OFstatic_cast(double, x);
                        r_factor = (OFstatic_cast(double, x) + 1.0) - x_part;
                        offset = OFstatic_cast(unsigned int, byi - 1) * OFstatic_cast(unsigned int, Columns);
                        for (yi = byi; yi <= eyi; ++yi)
                        {
                            offset += Columns;
                            p = sp + offset + OFstatic_cast(unsigned int, bxi);
                            for (xi = bxi; xi <= exi; ++xi)
                            {
                                sum = OFstatic_cast(double, *(p++));
                                if (bxi != exi)
                                {
                                    if (xi == bxi)
                                        sum *= l_factor;
                                    else
                                        sum *= r_factor;
                                }
                                if (byi != eyi)
                                {
                                    if (yi == byi)
                                        sum *= b_factor;
                                    else
                                        sum *= t_factor;
                                }
                                value += sum;
                            }
                        }
                        *(q++) = OFstatic_cast(T, value + 0.5);
                    }
                }
                sp += f_size;                                        // skip to next frame start: UNTESTED
            }
        }
    }


    /** free scaling method with interpolation (only for reduction).
     *
     ** @param  src   array of pointers to source image pixels
     *  @param  dest  array of pointers to destination image pixels
     */
    void reducePixel(const T *src[],
                          T *dest[])
    {
#ifdef DEBUG
        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals | DicomImageClass::DL_Warnings))
        {
            ofConsole.lockCerr() << "INFO: reducePixel with interpolated c't algorithm ... still a little BUGGY !" << endl;
            ofConsole.unlockCerr();
        }
#endif
        const double x_factor = OFstatic_cast(double, this->Src_X) / OFstatic_cast(double, this->Dest_X);
        const double y_factor = OFstatic_cast(double, this->Src_Y) / OFstatic_cast(double, this->Dest_Y);
        const double xy_factor = x_factor * y_factor;
        const unsigned int f_size = OFstatic_cast(unsigned int, Rows) * OFstatic_cast(unsigned int, Columns);
        const T *sp;
        double bx, ex;
        double by, ey;
        int bxi, exi;
        int byi, eyi;
        unsigned int offset;
        double value, sum;
        double l_factor, r_factor;
        double t_factor, b_factor;
        int xi;
        int yi;
        Uint16 x;
        Uint16 y;
        const T *p;
        T *q;

        /*
         *   based on scaling algorithm from "c't - Magazin fuer Computertechnik" (c't 11/94)
         *   (adapted to be used with signed pixel representation and inverse images - mono1)
         */

        for (int j = 0; j < this->Planes; ++j)
        {
            sp = src[j] + OFstatic_cast(unsigned int, Top) * OFstatic_cast(unsigned int, Columns) + Left;
            q = dest[j];
            for (Uint32 f = 0; f < this->Frames; ++f)
            {
                for (y = 0; y < this->Dest_Y; ++y)
                {
                    by = y_factor * OFstatic_cast(double, y);
                    ey = y_factor * (OFstatic_cast(double, y) + 1.0);
                    byi = OFstatic_cast(int, by);
                    eyi = OFstatic_cast(int, ey);
                    if (ey - OFstatic_cast(double, eyi) < 0.00001)
                        --eyi;
                    b_factor = 1 + OFstatic_cast(double, byi) - by;
                    t_factor = ey - OFstatic_cast(double, eyi);
                    for (x = 0; x < this->Dest_X; ++x)
                    {
                        value = 0;
                        bx = x_factor * OFstatic_cast(double, x);
                        ex = x_factor * (OFstatic_cast(double, x) + 1.0);
                        bxi = OFstatic_cast(int, bx);
                        exi = OFstatic_cast(int, ex);
                        if (ex - OFstatic_cast(double, exi) < 0.00001)
                            --exi;
                        l_factor = 1 + OFstatic_cast(double, bxi) - bx;
                        r_factor = ex - OFstatic_cast(double, exi);
                        offset = OFstatic_cast(unsigned int, byi - 1) * OFstatic_cast(unsigned int, Columns);
                        for (yi = byi; yi <= eyi; ++yi)
                        {
                            offset += Columns;
                            p = sp + offset + OFstatic_cast(unsigned int, bxi);
                            for (xi = bxi; xi <= exi; ++xi)
                            {
                                sum = OFstatic_cast(double, *(p++)) / xy_factor;
                                if (xi == bxi)
                                    sum *= l_factor;
                                else if (xi == exi)
                                    sum *= r_factor;
                                if (yi == byi)
                                    sum *= b_factor;
                                else if (yi == eyi)
                                    sum *= t_factor;
                                value += sum;
                            }
                        }
                        *(q++) = OFstatic_cast(T, value + 0.5);
                    }
                }
                sp += f_size;                                        // skip to next frame start: UNTESTED
            }
        }
    }
};

#endif


/*
 *
 * CVS/RCS Log:
 * $Log: discalet.h,v $
 * Revision 1.1  2006/03/01 20:15:36  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.25  2005/12/08 16:48:09  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.24  2004/04/21 10:00:36  meichel
 * Minor modifications for compilation with gcc 3.4.0
 *
 * Revision 1.23  2004/01/05 14:52:20  joergr
 * Removed acknowledgements with e-mail addresses from CVS log.
 *
 * Revision 1.22  2003/12/23 15:53:22  joergr
 * Replaced post-increment/decrement operators by pre-increment/decrement
 * operators where appropriate (e.g. 'i++' by '++i').
 *
 * Revision 1.21  2003/12/09 10:25:06  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Removed leading underscore characters from preprocessor symbols (reserved
 * symbols). Updated copyright header.
 *
 * Revision 1.20  2002/12/09 13:32:56  joergr
 * Renamed parameter/local variable to avoid name clashes with global
 * declaration left and/or right (used for as iostream manipulators).
 *
 * Revision 1.19  2002/04/16 13:53:12  joergr
 * Added configurable support for C++ ANSI standard includes (e.g. streams).
 *
 * Revision 1.18  2001/06/01 15:49:51  meichel
 * Updated copyright header
 *
 * Revision 1.17  2000/05/03 09:46:29  joergr
 * Removed most informational and some warning messages from release built
 * (#ifndef DEBUG).
 *
 * Revision 1.16  2000/04/28 12:32:33  joergr
 * DebugLevel - global for the module - now derived from OFGlobal (MF-safe).
 *
 * Revision 1.15  2000/04/27 13:08:42  joergr
 * Dcmimgle library code now consistently uses ofConsole for error output.
 *
 * Revision 1.14  2000/03/08 16:24:24  meichel
 * Updated copyright header.
 *
 * Revision 1.13  2000/03/07 16:15:13  joergr
 * Added explicit type casts to make Sun CC 2.0.1 happy.
 *
 * Revision 1.12  2000/03/03 14:09:14  meichel
 * Implemented library support for redirecting error messages into memory
 *   instead of printing them to stdout/stderr for GUI applications.
 *
 * Revision 1.11  1999/11/19 12:37:19  joergr
 * Fixed bug in scaling method "reducePixel" (reported by gcc 2.7.2.1).
 *
 * Revision 1.10  1999/09/17 13:07:20  joergr
 * Added/changed/completed DOC++ style comments in the header files.
 * Enhanced efficiency of some "for" loops.
 *
 * Revision 1.9  1999/08/25 16:41:55  joergr
 * Added new feature: Allow clipping region to be outside the image
 * (overlapping).
 *
 * Revision 1.8  1999/07/23 14:09:24  joergr
 * Added new interpolation algorithm for scaling.
 *
 * Revision 1.7  1999/04/28 14:55:05  joergr
 * Introduced new scheme for the debug level variable: now each level can be
 * set separately (there is no "include" relationship).
 *
 * Revision 1.6  1999/03/24 17:20:24  joergr
 * Added/Modified comments and formatting.
 *
 * Revision 1.5  1999/02/11 16:42:10  joergr
 * Removed inline declarations from several methods.
 *
 * Revision 1.4  1999/02/03 17:35:14  joergr
 * Moved global functions maxval() and determineRepresentation() to class
 * DicomImageClass (as static methods).
 *
 * Revision 1.3  1998/12/22 14:39:44  joergr
 * Added some preparation to enhance interpolated scaling (clipping and
 * scaling) in the future.
 *
 * Revision 1.2  1998/12/16 16:39:45  joergr
 * Implemented combined clipping and scaling for pixel replication and
 * suppression.
 *
 * Revision 1.1  1998/11/27 15:47:11  joergr
 * Added copyright message.
 * Combined clipping and scaling methods.
 *
 * Revision 1.4  1998/05/11 14:53:29  joergr
 * Added CVS/RCS header to each file.
 *
 *
 */
