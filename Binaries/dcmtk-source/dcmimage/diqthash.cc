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
 *  Purpose: class DcmQuantColorHashTable
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:35 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"
#include "diqthash.h"
#include "dcxfer.h"      /* for E_TransferSyntax */
#include "dcmimage.h"    /* for DicomImage */


DcmQuantColorHashTable::DcmQuantColorHashTable()
: table(NULL)
{
  table = new DcmQuantHistogramItemListPointer[DcmQuantHashSize];
  if (table)
  {
    for (unsigned int i=0; i < DcmQuantHashSize; i++)
    {
      table[i] = new DcmQuantHistogramItemList();
    }  
  }
}


DcmQuantColorHashTable::~DcmQuantColorHashTable()
{
  if (table)
  {
    for (unsigned int i=0; i < DcmQuantHashSize; i++) delete table[i];
    delete[] table;
  }
}


unsigned int DcmQuantColorHashTable::countEntries() const
{
  unsigned int result = 0;
  for (unsigned int i=0; i < DcmQuantHashSize; i++)
  {
    result += table[i]->size();
  }  
  return result;
}


unsigned int DcmQuantColorHashTable::createHistogram(DcmQuantHistogramItemPointer *& array)
{
  unsigned int numcolors = countEntries();
  array = new DcmQuantHistogramItemPointer[numcolors];
  if (array)
  {
    unsigned int counter = 0;
    for (unsigned int i=0; i < DcmQuantHashSize; i++)
    {
      table[i]->moveto(array, counter, numcolors);
    }      
  }
  return numcolors;
}


unsigned int DcmQuantColorHashTable::addToHashTable(
  DicomImage& image, 
  unsigned int newmaxval,
  unsigned int maxcolors)
{
  const unsigned int cols = image.getWidth();
  const unsigned int rows = image.getHeight();
  const unsigned int frames = image.getFrameCount();
  const int bits = sizeof(DcmQuantComponent)*8;

  unsigned int numcolors = 0;
  unsigned int j, k;
  const DcmQuantComponent *cp;
  DcmQuantPixel px;
  const void *data = NULL;

  // compute maxval
  unsigned int maxval = 0;
  for (int bb=0; bb < bits; bb++) maxval = (maxval << 1) | 1;

  DcmQuantScaleTable scaletable;
  scaletable.createTable(maxval, newmaxval);

  DcmQuantComponent r, g, b;

  for (unsigned int ff=0; ff<frames; ff++)
  {
    data = image.getOutputData(bits, ff, 0);
    if (data)
    {
      cp = OFstatic_cast(const DcmQuantComponent *, data);
      for (j = 0; j < rows; j++)
      {
        for (k = 0; k < cols; k++)
        {
          // get pixel
          r = *cp++;
          g = *cp++;
          b = *cp++;
          px.scale(r, g, b, scaletable);
      
          // lookup and increase if already in hash table
          numcolors += table[px.hash()]->add(px);
          if (numcolors > maxcolors) return 0;
        }
      }
    }
  }
  return numcolors;
}


/*
 *
 * CVS/RCS Log:
 * $Log: diqthash.cc,v $
 * Revision 1.1  2006/03/01 20:15:35  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.3  2005/12/08 15:42:30  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.2  2003/12/17 16:34:57  joergr
 * Adapted type casts to new-style typecast operators defined in ofcast.h.
 *
 * Revision 1.1  2002/01/25 13:32:11  meichel
 * Initial release of new color quantization classes and
 *   the dcmquant tool in module dcmimage.
 *
 *
 */
