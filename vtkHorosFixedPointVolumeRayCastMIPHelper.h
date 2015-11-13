/*=========================================================================

  Program:   Visualization Toolkit
  Module:    vtkHorosFixedPointVolumeRayCastMIPHelper.h

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkHorosFixedPointVolumeRayCastMIPHelper - A helper that generates MIP images for the volume ray cast mapper
// .SECTION Description
// This is one of the helper classes for the vtkHorosFixedPointVolumeRayCastMapper.
// It will generate maximum intensity images.
// This class should not be used directly, it is a helper class for
// the mapper and has no user-level API.
//
// .SECTION see also
// vtkHorosFixedPointVolumeRayCastMapper

#ifndef vtkHorosFixedPointVolumeRayCastMIPHelper_h
#define vtkHorosFixedPointVolumeRayCastMIPHelper_h

#include "vtkRenderingVolumeModule.h" // For export macro
#include "vtkFixedPointVolumeRayCastMIPHelper.h"

class vtkFixedPointVolumeRayCastMapper;
class vtkVolume;

class VTKRENDERINGVOLUME_EXPORT vtkHorosFixedPointVolumeRayCastMIPHelper : public vtkFixedPointVolumeRayCastMIPHelper //vtkFixedPointVolumeRayCastHelper
{
public:
  static vtkHorosFixedPointVolumeRayCastMIPHelper *New();
  vtkTypeMacro(vtkHorosFixedPointVolumeRayCastMIPHelper,vtkFixedPointVolumeRayCastHelper);
  void PrintSelf( ostream& os, vtkIndent indent );

  virtual void  GenerateImage( int threadID,
                               int threadCount,
                               vtkVolume *vol,
                               vtkFixedPointVolumeRayCastMapper *mapper);

protected:
  vtkHorosFixedPointVolumeRayCastMIPHelper();
  ~vtkHorosFixedPointVolumeRayCastMIPHelper();

private:
  vtkHorosFixedPointVolumeRayCastMIPHelper(const vtkHorosFixedPointVolumeRayCastMIPHelper&);  // Not implemented.
  void operator=(const vtkHorosFixedPointVolumeRayCastMIPHelper&);  // Not implemented.
};

#endif



