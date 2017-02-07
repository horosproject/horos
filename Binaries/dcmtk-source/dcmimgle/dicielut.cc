/*
 *
 *  Copyright (C) 1999-2005, OFFIS
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
 *  Purpose: DicomCIELABLUT (Source)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:36 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"

#include "ofconsol.h"
#include "dicielut.h"

#define INCLUDE_CMATH
#include "ofstdinc.h"


/*----------------*
 *  constructors  *
 *----------------*/

DiCIELABLUT::DiCIELABLUT(const unsigned int count,
                         const Uint16 max,
                         const Uint16 *ddl_tab,
                         const double *val_tab,
                         const unsigned int ddl_cnt,
                         const double val_min,
                         const double val_max,
                         const double lum_min,
                         const double lum_max,
                         const double amb,
                         const OFBool inverse,
                         ostream *stream,
                         const OFBool printMode)
  : DiDisplayLUT(count, max, amb /*, 'illum' not used*/)
{
    if ((Count > 0) && (Bits > 0))
    {
#ifdef DEBUG
        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
        {
            ofConsole.lockCerr() << "INFO: new CIELAB LUT with " << Bits << " bits output and "
                                 << Count << " entries created !" << endl;
            ofConsole.unlockCerr();
        }
#endif
        if (val_min >= val_max)
        {
            if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Errors))
            {
                ofConsole.lockCerr() << "ERROR: invalid value range for CIELAB LUT creation ("
                                     << val_min << " - " << val_max << ") !" << endl;
                ofConsole.unlockCerr();
            }
        }
        /* create the lookup table */
        Valid = createLUT(ddl_tab, val_tab, ddl_cnt, val_min, val_max, lum_min, lum_max,
                          inverse, stream, printMode);
    }
}


/*--------------*
 *  destructor  *
 *--------------*/

DiCIELABLUT::~DiCIELABLUT()
{
}


/********************************************************************/


int DiCIELABLUT::createLUT(const Uint16 *ddl_tab,
                           const double *val_tab,
                           const unsigned int ddl_cnt,
                           const double val_min,
                           const double val_max,
                           const double lum_min,
                           const double lum_max,
                           const OFBool inverse,
                           ostream *stream,
                           const OFBool printMode)
{
    int status = 0;
    if ((ddl_tab != NULL) && (val_tab != NULL) && (ddl_cnt > 0) && (val_max > 0) && (val_min < val_max))
    {
        const unsigned int cin_ctn = (inverse) ? ddl_cnt : Count;      // number of points to be interpolated
        double *cielab = new double[cin_ctn];
        if (cielab != NULL)
        {
            unsigned int i;
            double llin = 0;
            double cub = 0;
            const double amb = getAmbientLightValue();
            /* check whether Lmin or Lmax is set */
            const double min = (lum_min < 0) ? val_min + amb : lum_min /*includes 'amb'*/;
            const double max = (lum_max < 0) ? val_max + amb : lum_max /*includes 'amb'*/;
            const double lmin = min / max;
            const double hmin = (lmin > 0.008856) ? 116.0 * pow(lmin, 1.0 / 3.0) - 16 : 903.3 * lmin;
            const double lfac = (100.0 - hmin) / (OFstatic_cast(double, cin_ctn - 1) * 903.3);
            const double loff = hmin / 903.3;
            const double cfac = (100.0 - hmin) / (OFstatic_cast(double, cin_ctn - 1) * 116.0);
            const double coff = (16.0  + hmin) / 116.0;
            for (i = 0; i < cin_ctn; ++i)                   // compute CIELAB function
            {
                llin = OFstatic_cast(double, i) * lfac + loff;
                cub = OFstatic_cast(double, i) * cfac + coff;
                cielab[i] = ((llin > 0.008856) ? cub * cub * cub : llin) * max;
            }
            DataBuffer = new Uint16[Count];
            if (DataBuffer != NULL)                         // create look-up table
            {
                Uint16 *q = DataBuffer;
                unsigned int j = 0;
                /* check whether to apply the inverse transformation */
                if (inverse)
                {
                    double v;
                    const double factor = OFstatic_cast(double, ddl_cnt - 1) / OFstatic_cast(double, Count - 1);
                    /* convert from DDL */
                    for (i = 0; i < Count; ++i)
                    {
                        v = val_tab[OFstatic_cast(int, i * factor)] + amb;    // need to scale index to range of value table
                        while ((j + 1 < ddl_cnt) && (cielab[j] < v))          // search for closest index, assuming monotony
                            ++j;
                        if ((j > 0) && (fabs(cielab[j - 1] - v) < fabs(cielab[j] - v)))
                            --j;
                        *(q++) = ddl_tab[j];
                    }
                } else {
                    /* initial DDL boundaries */
                    unsigned int ddl_min = 0;
                    unsigned int ddl_max= ddl_cnt - 1;
                    /* check whether minimum luminance is specified */
                    if (lum_min >= 0)
                    {
                        j = ddl_min;
                        /* determine corresponding minimum DDL value */
                        while ((j < ddl_max) && (val_tab[j] + amb < lum_min))
                            ++j;
                        ddl_min = j;
                    }
                    /* check whether maximum luminance is specified */
                    if (lum_max >= 0)
                    {
                        j = ddl_max;
                        /* determine corresponding maximum DDL value */
                        while ((j > ddl_min) && (val_tab[j] + amb > lum_max))
                            --j;
                        ddl_max = j;
                    }
                    j = ddl_min;
                    const double *r = cielab;
                    /* convert to DDL */
                    for (i = Count; i != 0; --i, ++r)
                    {
                        while ((j < ddl_max) && (val_tab[j] + amb < *r))  // search for closest index, assuming monotony
                            ++j;
                        if ((j > 0) && (fabs(val_tab[j - 1] + amb - *r) < fabs(val_tab[j] + amb - *r)))
                            --j;
                        *(q++) = ddl_tab[j];
                    }
                }
                Data = DataBuffer;
                if (stream != NULL)                         // write curve data to file
                {
                    if (Count == ddl_cnt)                   // check whether CIELAB LUT fits exactly to DISPLAY file
                    {
                        for (i = 0; i < ddl_cnt; ++i)
                        {
                            (*stream) << ddl_tab[i];                               // DDL
                            stream->setf(ios::fixed, ios::floatfield);
                            if (printMode)
                                (*stream) << "\t" << val_tab[i] + amb;             // CC
                            (*stream) << "\t" << cielab[i];                        // CIELAB
                            if (printMode)
                            {
                                if (inverse)
                                    (*stream) << "\t" << cielab[Data[i]];          // PSC'
                                else
                                    (*stream) << "\t" << val_tab[Data[i]] + amb;   // PSC
                            }
                            (*stream) << endl;
                        }
                    } else {
                        if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Warnings))
                        {
                            ofConsole.lockCerr() << "WARNING: can't write curve data, wrong DISPLAY file or CIELAB LUT !" << endl;
                            ofConsole.unlockCerr();
                        }
                    }
                }
                status = 1;
            }
        }
        delete[] cielab;
    }
    return status;
}


/*
 *
 * CVS/RCS Log:
 * $Log: dicielut.cc,v $
 * Revision 1.1  2006/03/01 20:15:36  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.22  2005/12/08 15:42:45  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.21  2004/04/14 11:58:29  joergr
 * Changed type of integer variable to keep Sun CC 2.0.1 quiet.
 *
 * Revision 1.20  2003/12/23 16:03:18  joergr
 * Replaced post-increment/decrement operators by pre-increment/decrement
 * operators where appropriate (e.g. 'i++' by '++i').
 *
 * Revision 1.19  2003/12/08 17:40:54  joergr
 * Updated CVS header.
 *
 * Revision 1.18  2003/12/08 14:47:03  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 *
 * Revision 1.17  2003/02/12 11:37:14  joergr
 * Added Dmin/max support to CIELAB calibration routines.
 *
 * Revision 1.16  2002/11/27 14:08:11  meichel
 * Adapted module dcmimgle to use of new header file ofstdinc.h
 *
 * Revision 1.15  2002/07/19 13:09:31  joergr
 * Enhanced handling of "inverse" calibration used for input devices.
 *
 * Revision 1.14  2002/07/18 12:33:07  joergr
 * Added support for hardcopy and softcopy input devices (camera and scanner).
 *
 * Revision 1.13  2002/07/03 13:50:59  joergr
 * Fixed inconsistencies regarding the handling of ambient light.
 *
 * Revision 1.12  2002/07/02 16:24:36  joergr
 * Added support for hardcopy devices to the calibrated output routines.
 *
 * Revision 1.11  2001/06/01 15:49:53  meichel
 * Updated copyright header
 *
 * Revision 1.10  2000/05/03 09:47:22  joergr
 * Removed most informational and some warning messages from release built
 * (#ifndef DEBUG).
 *
 * Revision 1.9  2000/04/28 12:33:41  joergr
 * DebugLevel - global for the module - now derived from OFGlobal (MF-safe).
 *
 * Revision 1.8  2000/04/27 13:10:25  joergr
 * Dcmimgle library code now consistently uses ofConsole for error output.
 *
 * Revision 1.7  2000/03/08 16:24:26  meichel
 * Updated copyright header.
 *
 * Revision 1.6  2000/03/03 14:09:17  meichel
 * Implemented library support for redirecting error messages into memory
 *   instead of printing them to stdout/stderr for GUI applications.
 *
 * Revision 1.5  1999/10/21 17:46:46  joergr
 * Corrected calculation of CIELAB display curve (thanks to Mr. Mertelmeier
 * from Siemens).
 *
 * Revision 1.4  1999/10/18 15:06:23  joergr
 * Enhanced command line tool dcmdspfn (added new options).
 *
 * Revision 1.3  1999/10/18 10:14:01  joergr
 * Simplified calculation of CIELAB function (now fully percentage based).
 *
 * Revision 1.2  1999/09/17 13:13:28  joergr
 * Enhanced efficiency of some "for" loops.
 *
 * Revision 1.1  1999/09/10 08:54:48  joergr
 * Added support for CIELAB display function. Restructured class hierarchy
 * for display functions.
 *
 */
