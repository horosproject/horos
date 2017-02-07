/*=========================================================================

  Program: GDCM (Grassroots DICOM). A DICOM library
  Module:  $URL$

  Copyright (c) 2006-2010 Mathieu Malaterre
  All rights reserved.
  See Copyright.txt or http://gdcm.sourceforge.net/Copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
#ifndef GDCMIMPLICITDATAELEMENT_H
#define GDCMIMPLICITDATAELEMENT_H

#include "gdcmDataElement.h"

namespace gdcm
{

class ExplicitImplicitDataElement;
/**
 * \brief Class to represent an *Implicit VR* Data Element
 * \note bla
 */
class GDCM_EXPORT ImplicitDataElement : public DataElement
{
public:
  VL GetLength() const;

  template <typename TSwap>
  std::istream &Read(std::istream& is);

  template <typename TSwap>
  std::istream &ReadWithLength(std::istream& is, VL & length);

  template <typename TSwap>
  const std::ostream &Write(std::ostream& os) const;
};

} // end namespace gdcm

#include "gdcmImplicitDataElement.txx"

#endif //GDCMIMPLICITDATAELEMENT_H
