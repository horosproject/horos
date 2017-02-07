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
#ifndef GDCMAUDIOCODEC_H
#define GDCMAUDIOCODEC_H

#include "gdcmCodec.h"

namespace gdcm
{

/**
 * \brief AudioCodec
 */
class GDCM_EXPORT AudioCodec : public Codec
{
public:
  AudioCodec();
  ~AudioCodec();
  bool CanCode(TransferSyntax const &) const { return false; }
  bool CanDecode(TransferSyntax const &) const { return false; }
  bool Decode(DataElement const &is, DataElement &os);
};

} // end namespace gdcm

#endif //GDCMAUDIOCODEC_H
