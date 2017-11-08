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
 *  Purpose: DicomMonochromeInputPixelTemplate (Header)
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:36 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#ifndef DIMOIPXT_H
#define DIMOIPXT_H

#include "osconfig.h"
#include "ofconsol.h"
#include "ofbmanip.h"
#include "ofcast.h"

#include "dimopxt.h"


/*---------------------*
 *  class declaration  *
 *---------------------*/

/** Template class to convert monochrome pixel data to intermediate representation
 */
template<class T1, class T2, class T3>
class DiMonoInputPixelTemplate
  : public DiMonoPixelTemplate<T3>
{

 public:

    /** constructor
     *
     ** @param  pixel     pointer to input pixel representation
     *  @param  modality  pointer to modality transform object
     */
    DiMonoInputPixelTemplate(DiInputPixel *pixel,
                             DiMonoModality *modality)
      : DiMonoPixelTemplate<T3>(pixel, modality)
    {
        /* erase empty part of the buffer (= blacken the background) */
        if ((this->Data != NULL) && (this->InputCount < this->Count))
            OFBitmanipTemplate<T3>::zeroMem(this->Data + this->InputCount, this->Count - this->InputCount);
        if ((pixel != NULL) && (this->Count > 0))
        {
            // check whether to apply any modality transform
            if ((this->Modality != NULL) && this->Modality->hasLookupTable() && (bitsof(T1) <= MAX_TABLE_ENTRY_SIZE))
            {
                modlut(pixel);
                // ignore modality LUT min/max values since the image does not necessarily have to use all LUT entries
                this->determineMinMax();
            }
            else if ((this->Modality != NULL) && this->Modality->hasRescaling())
            {
                rescale(pixel, this->Modality->getRescaleSlope(), this->Modality->getRescaleIntercept());
                this->determineMinMax(OFstatic_cast(T3, this->Modality->getMinValue()), OFstatic_cast(T3, this->Modality->getMaxValue()));
            } else {
                rescale(pixel);                     // "copy" or reference pixel data
                this->determineMinMax(OFstatic_cast(T3, this->Modality->getMinValue()), OFstatic_cast(T3, this->Modality->getMaxValue()));
            }
        }
    }

    /** destructor
     */
    virtual ~DiMonoInputPixelTemplate()
    {
    }


 private:

    /** initialize optimization LUT
     *
     ** @param  lut   reference to storage area for lookup table
     *  @param  ocnt  number of LUT entries (will be check as optimization criteria)
     *
     ** @return status, true if successful (LUT has been created), false otherwise
     */
    inline int initOptimizationLUT(T3 *&lut,
                                   const unsigned int ocnt)
    {
        int result = 0;
        if ((sizeof(T1) <= 2) && (this->InputCount > 3 * ocnt))                     // optimization criteria
        {                                                                     // use LUT for optimization
            lut = new T3[ocnt];
            if (lut != NULL)
            {
#ifdef DEBUG
                if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                {
                    ofConsole.lockCerr() << "INFO: using optimized routine with additional LUT" << endl;
                    ofConsole.unlockCerr();
                }
#endif
                result = 1;
            }
        }
        return result;
    }

    /** perform modality LUT transform
     *
     ** @param  input  pointer to input pixel representation
     */
    void modlut(DiInputPixel *input)
    {
        const T1 *pixel = OFstatic_cast(const T1 *, input->getData());
        if ((pixel != NULL) && (this->Modality != NULL))
        {
            const DiLookupTable *mlut = this->Modality->getTableData();
            if (mlut != NULL)
            {
                const int useInputBuffer = (sizeof(T1) == sizeof(T3)) && (this->Count <= input->getCount());
                if (useInputBuffer)                            // do not copy pixel data, reference them!
                {
                    this->Data = OFstatic_cast(T3 *, input->getDataPtr());
                    input->removeDataReference();              // avoid double deletion
                } else
                    this->Data = new T3[this->Count];
                if (this->Data != NULL)
                {
#ifdef DEBUG
                    if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                    {
                        ofConsole.lockCerr() << "INFO: using modality routine 'modlut()'" << endl;
                        ofConsole.unlockCerr();
                    }
#endif
                    T2 value = 0;
                    const T2 firstentry = mlut->getFirstEntry(value);                     // choose signed/unsigned method
                    const T2 lastentry = mlut->getLastEntry(value);
                    const T3 firstvalue = OFstatic_cast(T3, mlut->getFirstValue());
                    const T3 lastvalue = OFstatic_cast(T3, mlut->getLastValue());
                    const T1 *p = pixel + input->getPixelStart();
                    T3 *q = this->Data;
                    unsigned int i;
                    T3 *lut = NULL;
                    const unsigned int ocnt = OFstatic_cast(unsigned int, input->getAbsMaxRange());  // number of LUT entries
                    if (initOptimizationLUT(lut, ocnt))
                    {                                                                     // use LUT for optimization
                        const T2 absmin = OFstatic_cast(T2, input->getAbsMinimum());
                        q = lut;
                        for (i = 0; i < ocnt; ++i)                                        // calculating LUT entries
                        {
                            value = OFstatic_cast(T2, i) + absmin;
                            if (value <= firstentry)
                                *(q++) = firstvalue;
                            else if (value >= lastentry)
                                *(q++) = lastvalue;
                            else
                                *(q++) = OFstatic_cast(T3, mlut->getValue(value));
                        }
                        const T3 *lut0 = lut - OFstatic_cast(T2, absmin);                 // points to 'zero' entry
                        q = this->Data;
                        for (i = this->InputCount; i != 0; --i)                                 // apply LUT
                            *(q++) = *(lut0 + (*(p++)));
                    }
                    if (lut == NULL)                                                      // use "normal" transformation
                    {
                        for (i = this->InputCount; i != 0; --i)
                        {
                            value = OFstatic_cast(T2, *(p++));
                            if (value <= firstentry)
                                *(q++) = firstvalue;
                            else if (value >= lastentry)
                                *(q++) = lastvalue;
                            else
                                *(q++) = OFstatic_cast(T3, mlut->getValue(value));
                        }
                    }
                    delete[] lut;
                }
            }
        }
    }

    /** perform rescale slope/intercept transform
     *
     ** @param  input      pointer to input pixel representation
     *  @param  slope      rescale slope value (optional)
     *  @param  intercept  rescale intercept value (optional)
     */
    void rescale(DiInputPixel *input,
                 const double slope = 1.0,
                 const double intercept = 0.0)
    {
        const T1 *pixel = OFstatic_cast(const T1 *, input->getData());
        if (pixel != NULL)
        {
            const int useInputBuffer = (sizeof(T1) == sizeof(T3)) && (this->Count <= input->getCount()) && (input->getPixelStart() == 0);
            if (useInputBuffer)
            {                                              // do not copy pixel data, reference them!
                this->Data = OFstatic_cast(T3 *, input->getDataPtr());
                input->removeDataReference();              // avoid double deletion
            } else
                this->Data = new T3[this->Count];
            if (this->Data != NULL)
            {
                T3 *q = this->Data;
                unsigned int i;
                if ((slope == 1.0) && (intercept == 0.0))
                {
                    if (!useInputBuffer)
                    {
                        const T1 *p = pixel + input->getPixelStart();
                        for (i = this->InputCount; i != 0; --i)   // copy pixel data: can't use copyMem because T1 isn't always equal to T3
                            *(q++) = OFstatic_cast(T3, *(p++));
                    }
                } else {
#ifdef DEBUG
                    if (DicomImageClass::checkDebugLevel(DicomImageClass::DL_Informationals))
                    {
                        ofConsole.lockCerr() << "INFO: using modality routine 'rescale()'" << endl;
                        ofConsole.unlockCerr();
                    }
#endif
                    T3 *lut = NULL;
                    const T1 *p = pixel + input->getPixelStart();
                    const unsigned int ocnt = OFstatic_cast(unsigned int, input->getAbsMaxRange());  // number of LUT entries
                    if (initOptimizationLUT(lut, ocnt))
                    {                                                                     // use LUT for optimization
                        const double absmin = input->getAbsMinimum();
                        q = lut;
                        if (slope == 1.0)
                        {
                            for (i = 0; i < ocnt; ++i)                                    // calculating LUT entries
                                *(q++) = OFstatic_cast(T3, OFstatic_cast(double, i) + absmin + intercept);
                        } else {
                            if (intercept == 0.0)
                            {
                                for (i = 0; i < ocnt; ++i)
                                    *(q++) = OFstatic_cast(T3, (OFstatic_cast(double, i) + absmin) * slope);
                            } else {
                                for (i = 0; i < ocnt; ++i)
                                    *(q++) = OFstatic_cast(T3, (OFstatic_cast(double, i) + absmin) * slope + intercept);
                            }
                        }
                        const T3 *lut0 = lut - OFstatic_cast(T2, absmin);                 // points to 'zero' entry
                        q = this->Data;
                        for (i = this->InputCount; i != 0; --i)                                 // apply LUT
                            *(q++) = *(lut0 + (*(p++)));
                    }
                    if (lut == NULL)                                                      // use "normal" transformation
                    {
                        if (slope == 1.0)
                        {
                            for (i = this->Count; i != 0; --i)
                                *(q++) = OFstatic_cast(T3, OFstatic_cast(double, *(p++)) + intercept);
                        } else {
                            if (intercept == 0.0)
                            {
                                for (i = this->InputCount; i != 0; --i)
                                    *(q++) = OFstatic_cast(T3, OFstatic_cast(double, *(p++)) * slope);
                            } else {
                                for (i = this->InputCount; i != 0; --i)
                                    *(q++) = OFstatic_cast(T3, OFstatic_cast(double, *(p++)) * slope + intercept);
                            }
                        }
                    }
                    delete[] lut;
                }
            }
        }
    }
};


#endif


/*
 *
 * CVS/RCS Log:
 * $Log: dimoipxt.h,v $
 * Revision 1.1  2006/03/01 20:15:36  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.33  2005/12/08 16:47:51  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.32  2004/04/21 10:00:36  meichel
 * Minor modifications for compilation with gcc 3.4.0
 *
 * Revision 1.31  2004/02/06 11:07:50  joergr
 * Distinguish more clearly between const and non-const access to pixel data.
 *
 * Revision 1.30  2004/01/05 14:52:20  joergr
 * Removed acknowledgements with e-mail addresses from CVS log.
 *
 * Revision 1.29  2003/12/23 15:53:22  joergr
 * Replaced post-increment/decrement operators by pre-increment/decrement
 * operators where appropriate (e.g. 'i++' by '++i').
 *
 * Revision 1.28  2003/12/08 19:13:54  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 * Removed leading underscore characters from preprocessor symbols (reserved
 * symbols). Updated CVS header.
 *
 * Revision 1.27  2003/06/12 15:08:34  joergr
 * Fixed inconsistent API documentation reported by Doxygen.
 *
 * Revision 1.26  2003/06/02 17:06:21  joergr
 * Fixed bug in optimization criterion which caused dcmimgle to ignore the
 * "start frame" parameter in the DicomImage constructors under certain
 * circumstances.
 *
 * Revision 1.25  2002/10/21 10:13:51  joergr
 * Corrected wrong calculation of min/max pixel value in cases where the
 * stored pixel data exceeds the expected size.
 *
 * Revision 1.24  2002/06/26 16:05:43  joergr
 * Enhanced handling of corrupted pixel data and/or length.
 *
 * Revision 1.23  2001/11/13 18:10:43  joergr
 * Fixed bug occurring when processing monochrome images with an odd number of
 * pixels.
 * Fixed bug with incorrect calculation of min/max pixel values in images with
 * modality LUTs where not all LUT entries are used (previous optimization rule
 * was apparently too optimistic).
 *
 * Revision 1.22  2001/09/28 13:07:12  joergr
 * Added further robustness checks.
 *
 * Revision 1.21  2001/06/01 15:49:45  meichel
 * Updated copyright header
 *
 * Revision 1.20  2000/06/02 12:40:50  joergr
 * Removed debug message.
 *
 * Revision 1.19  2000/05/03 09:46:28  joergr
 * Removed most informational and some warning messages from release built
 * (#ifndef DEBUG).
 *
 * Revision 1.18  2000/04/28 12:32:31  joergr
 * DebugLevel - global for the module - now derived from OFGlobal (MF-safe).
 *
 * Revision 1.17  2000/04/27 13:08:39  joergr
 * Dcmimgle library code now consistently uses ofConsole for error output.
 *
 * Revision 1.16  2000/03/08 16:24:19  meichel
 * Updated copyright header.
 *
 * Revision 1.15  2000/03/03 14:09:12  meichel
 * Implemented library support for redirecting error messages into memory
 *   instead of printing them to stdout/stderr for GUI applications.
 *
 * Revision 1.14  1999/09/17 12:26:00  joergr
 * Added/changed/completed DOC++ style comments in the header files.
 * iEnhanced efficiency of some "for" loops.
 *
 * Revision 1.13  1999/07/23 14:04:35  joergr
 * Optimized memory usage for converting input pixel data (reference instead
 * of copying where possible).
 *
 * Revision 1.12  1999/05/03 15:43:20  joergr
 * Replaced method applyOptimizationLUT by its contents (method body) to avoid
 * warnings (and possible errors) on Sun CC 2.0.1 :-/
 *
 * Revision 1.11  1999/05/03 11:09:29  joergr
 * Minor code purifications to keep Sun CC 2.0.1 quiet.
 *
 * Revision 1.10  1999/04/29 16:46:45  meichel
 * Minor code purifications to keep DEC cxx 6 quiet.
 *
 * Revision 1.9  1999/04/28 14:50:35  joergr
 * Introduced new scheme for the debug level variable: now each level can be
 * set separately (there is no "include" relationship).
 *
 * Revision 1.8  1999/03/24 17:20:10  joergr
 * Added/Modified comments and formatting.
 *
 * Revision 1.7  1999/03/02 12:02:27  joergr
 * Corrected bug: when determining minimum and maximum pixel value (external)
 * modality LUTs were ignored.
 *
 * Revision 1.6  1999/02/11 16:37:10  joergr
 * Removed inline declarations from several methods.
 *
 * Revision 1.5  1999/02/03 17:29:19  joergr
 * Added optimization LUT to transform pixel data.
 *
 * Revision 1.4  1999/01/20 15:06:24  joergr
 * Replaced invocation of getCount() by member variable Count where possible.
 * Added optimization to modality and VOI transformation (using additional
 * LUTs).
 *
 * Revision 1.3  1998/12/22 14:29:39  joergr
 * Replaced method copyMem by for-loop copying each item.
 * Renamed some variables
 *
 * Revision 1.2  1998/12/14 17:21:09  joergr
 * Added support for signed values as second entry in look-up tables
 * (= first value mapped).
 *
 * Revision 1.1  1998/11/27 15:24:08  joergr
 * Added copyright message.
 * Added new cases to optimize rescaling.
 * Added support for new bit manipulation class.
 * Corrected bug in modality LUT transformation method.
 *
 * Revision 1.5  1998/07/01 08:39:23  joergr
 * Minor changes to avoid compiler warnings (gcc 2.8.1 with additional
 * options), e.g. add copy constructors.
 *
 * Revision 1.4  1998/05/11 14:53:21  joergr
 * Added CVS/RCS header to each file.
 *
 *
 */
