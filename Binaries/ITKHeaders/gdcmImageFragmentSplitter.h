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
#ifndef GDCMIMAGEFRAGMENTSPLITTER_H
#define GDCMIMAGEFRAGMENTSPLITTER_H

#include "gdcmImageToImageFilter.h"

namespace gdcm
{

class DataElement;
/**
 * \brief ImageFragmentSplitter class
 * For single frame image, DICOM standard allow splitting the frame into multiple fragments
 */
class GDCM_EXPORT ImageFragmentSplitter : public ImageToImageFilter
{
public:
  ImageFragmentSplitter():FragmentSizeMax(0),Force(false) {}
  ~ImageFragmentSplitter() {}

  /// Split
  bool Split();

  /// FragmentSizeMax needs to be an even number
  void SetFragmentSizeMax(uint32_t fragsize);
  uint32_t GetFragmentSizeMax() const { return FragmentSizeMax; }

  /// When file already has all it's segment < FragmentSizeMax there is not need to run the filter.
  /// Unless the user explicitly say 'force' recomputation !
  void SetForce( bool f ) { Force = f; }

protected:

private:
  uint32_t FragmentSizeMax;
  bool Force;
};

} // end namespace gdcm

#endif //GDCMIMAGEFRAGMENTSPLITTER_H
