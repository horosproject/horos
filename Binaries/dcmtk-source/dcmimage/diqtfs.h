/*
 *
 *  Copyright (C) 2002-2005, OFFIS
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
 *  Author:  Marco Eichelberg
 *
 *  Purpose: class DcmQuantFloydSteinberg
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:35 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef DIQTFS_H
#define DIQTFS_H


#include "osconfig.h"
#include "diqtpix.h"   /* for DcmQuantPixel */
#include "ofcond.h"    /* for OFCondition */


/** Floyd-Steinberg error vectors are stored internally as integer numbers
 *  containing the error multiplied by this constant.
 */
#define DcmQuantFloydSteinbergScale 1024


/** this class implements Floyd-Steinberg error diffusion.
 *  It is used during the color quantization of an image.
 */
class DcmQuantFloydSteinberg
{
public:

  /// constructor
  DcmQuantFloydSteinberg();

  /// destructor
  ~DcmQuantFloydSteinberg();

  /** initializes the Floyd-Steinberg error vectors for an image with the 
   *  given number of columns.
   *  @param cols number of columns in image
   *  @return EC_Normal if successful, an error code otherwise.
   */
  OFCondition initialize(unsigned int cols);
  
  /** uses the Floyd-Steinberg error vectors to adjust the color of the current image pixel.
   *  @param px the original image pixel is passed in this parameter. Upon return, the pixel
   *    value contains the new value after error diffusion.
   *  @param col column in which the current pixel is located, must be [0..columns-1]
   *  @param maxval maximum value for each color component.
   */
  inline void adjust(DcmQuantPixel& px, long col, long maxval)
  {
    long sr = px.getRed()   + thisrerr[col + 1] / DcmQuantFloydSteinbergScale;
    long sg = px.getGreen() + thisgerr[col + 1] / DcmQuantFloydSteinbergScale;
    long sb = px.getBlue()  + thisberr[col + 1] / DcmQuantFloydSteinbergScale;
    if ( sr < 0 ) sr = 0;
    else if ( sr > OFstatic_cast(long, maxval) ) sr = maxval;
    if ( sg < 0 ) sg = 0;
    else if ( sg > OFstatic_cast(long, maxval) ) sg = maxval;
    if ( sb < 0 ) sb = 0;
    else if ( sb > OFstatic_cast(long, maxval) ) sb = maxval;
    px.assign(OFstatic_cast(DcmQuantComponent, sr), OFstatic_cast(DcmQuantComponent, sg), OFstatic_cast(DcmQuantComponent, sb));
  }

  /** propagates the Floyd-Steinberg error terms for one pixel.
   *  @param px color value the current image pixel should have (after adjustment)
   *  @param mapped color value (selected from the color LUT) the current image pixel really uses
   *  @param col column in which the current pixel is located, must be [0..columns-1]
   */
  inline void propagate(const DcmQuantPixel& px, const DcmQuantPixel& mapped, long col)
  {
    long err;

    /* Propagate Floyd-Steinberg error terms. */
    if ( fs_direction )
    {
        err = ( OFstatic_cast(long, px.getRed()) - OFstatic_cast(long, mapped.getRed()) ) * DcmQuantFloydSteinbergScale;
        thisrerr[col + 2] += ( err * 7 ) / 16;
        nextrerr[col    ] += ( err * 3 ) / 16;
        nextrerr[col + 1] += ( err * 5 ) / 16;
        nextrerr[col + 2] += ( err     ) / 16;
        err = ( OFstatic_cast(long, px.getGreen()) - OFstatic_cast(long, mapped.getGreen()) ) * DcmQuantFloydSteinbergScale;
        thisgerr[col + 2] += ( err * 7 ) / 16;
        nextgerr[col    ] += ( err * 3 ) / 16;
        nextgerr[col + 1] += ( err * 5 ) / 16;
        nextgerr[col + 2] += ( err     ) / 16;
        err = ( OFstatic_cast(long, px.getBlue()) - OFstatic_cast(long, mapped.getBlue()) ) * DcmQuantFloydSteinbergScale;
        thisberr[col + 2] += ( err * 7 ) / 16;
        nextberr[col    ] += ( err * 3 ) / 16;
        nextberr[col + 1] += ( err * 5 ) / 16;
        nextberr[col + 2] += ( err     ) / 16;
    }
    else
    {
        err = ( OFstatic_cast(long, px.getRed()) - OFstatic_cast(long, mapped.getRed()) ) * DcmQuantFloydSteinbergScale;
        thisrerr[col    ] += ( err * 7 ) / 16;
        nextrerr[col + 2] += ( err * 3 ) / 16;
        nextrerr[col + 1] += ( err * 5 ) / 16;
        nextrerr[col    ] += ( err     ) / 16;
        err = ( OFstatic_cast(long, px.getGreen()) - OFstatic_cast(long, mapped.getGreen()) ) * DcmQuantFloydSteinbergScale;
        thisgerr[col    ] += ( err * 7 ) / 16;
        nextgerr[col + 2] += ( err * 3 ) / 16;
        nextgerr[col + 1] += ( err * 5 ) / 16;
        nextgerr[col    ] += ( err     ) / 16;
        err = ( OFstatic_cast(long, px.getBlue()) - OFstatic_cast(long, mapped.getBlue()) ) * DcmQuantFloydSteinbergScale;
        thisberr[col    ] += ( err * 7 ) / 16;
        nextberr[col + 2] += ( err * 3 ) / 16;
        nextberr[col + 1] += ( err * 5 ) / 16;
        nextberr[col    ] += ( err     ) / 16;
    }
  }

  /** starts error diffusion for a new row.
   *  The error vectors for the next image row are initialized to zero.
   *  The initial and last column of the current row are determined
   *  @param col initial column for the current row returned in this parameter
   *  @param limitcol limit column (one past the last valid column) for the 
   *    current row returned in this parameter. May become negative.
   */
  inline void startRow(long& col, long& limitcol)
  {
    for (unsigned int c = 0; c < columns + 2; ++c)
      nextrerr[c] = nextgerr[c] = nextberr[c] = 0;
  
    if (fs_direction)
    {
        col = 0;
        limitcol = columns;
    }
    else
    {
        col = columns - 1;
        limitcol = -1;
    }
  }
  
  /** finishes error diffusion for one image row.  The direction flag is 
   *  inverted and the error vectors for the "current" and "next" image row
   *  are swapped.
   */
  inline void finishRow()
  {
    temperr = thisrerr;
    thisrerr = nextrerr;
    nextrerr = temperr;
    temperr = thisgerr;
    thisgerr = nextgerr;
    nextgerr = temperr;
    temperr = thisberr;
    thisberr = nextberr;
    nextberr = temperr;
    fs_direction = ! fs_direction;
  }

  /** increases or decreases the column number
   *  depending on the direction flag.
   *  @param col column number, may become negative
   */
  inline void nextCol(long& col) const
  {
    if (fs_direction) ++col; else --col;
  }

private:

  /// frees all memory allocated by the error vectors
  void cleanup();

  /// private undefined copy constructor
  DcmQuantFloydSteinberg(const DcmQuantFloydSteinberg& src);

  /// private undefined copy assignment operator
  DcmQuantFloydSteinberg& operator=(const DcmQuantFloydSteinberg& src);

  /// current red error vector. Points to an array of (columns + 2) entries.
  long *thisrerr;

  /// red error vector for next row. Points to an array of (columns + 2) entries.
  long *nextrerr;
  
  /// current green error vector. Points to an array of (columns + 2) entries.
  long *thisgerr;

  /// green error vector for next row. Points to an array of (columns + 2) entries.
  long *nextgerr;

  /// current blue error vector. Points to an array of (columns + 2) entries.
  long *thisberr;

  /// blue error vector for next row. Points to an array of (columns + 2) entries.
  long *nextberr;

  /// temporary pointer used for swapping error vectors
  long *temperr;

  /** boolean flag indicating in which direction (left to right/right to left) 
   *  the FS distribution should be done. Flag is inverted after each row.
   */  
  int fs_direction;
  
  /// number of columns in image
  unsigned int columns;

};


#endif


/*
 * CVS/RCS Log:
 * $Log: diqtfs.h,v $
 * Revision 1.1  2006/03/01 20:15:35  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.4  2005/12/08 16:01:46  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.3  2003/12/23 12:16:59  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Updated copyright header.
 *
 * Revision 1.2  2002/05/15 09:53:30  meichel
 * Minor corrections to avoid warnings on Sun CC 2.0.1
 *
 * Revision 1.1  2002/01/25 13:32:04  meichel
 * Initial release of new color quantization classes and
 *   the dcmquant tool in module dcmimage.
 *
 *
 */
