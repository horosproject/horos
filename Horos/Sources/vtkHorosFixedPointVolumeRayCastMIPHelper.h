/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
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

#include <vtkRenderingVolumeModule.h> // For export macro
#include <vtkFixedPointVolumeRayCastMIPHelper.h>

class vtkFixedPointVolumeRayCastMapper;
class vtkVolume;

class VTKRENDERINGVOLUME_EXPORT vtkHorosFixedPointVolumeRayCastMIPHelper : public vtkFixedPointVolumeRayCastMIPHelper //vtkFixedPointVolumeRayCastHelper
{
public:
  static vtkHorosFixedPointVolumeRayCastMIPHelper *New();
  vtkTypeMacro(vtkHorosFixedPointVolumeRayCastMIPHelper,vtkFixedPointVolumeRayCastHelper);
  void PrintSelf( ostream& os, vtkIndent indent ) override;

  virtual void  GenerateImage( int threadID,
                               int threadCount,
                               vtkVolume *vol,
                               vtkFixedPointVolumeRayCastMapper *mapper) override;

protected:
  vtkHorosFixedPointVolumeRayCastMIPHelper();
  ~vtkHorosFixedPointVolumeRayCastMIPHelper();

private:
  vtkHorosFixedPointVolumeRayCastMIPHelper(const vtkHorosFixedPointVolumeRayCastMIPHelper&);  // Not implemented.
  void operator=(const vtkHorosFixedPointVolumeRayCastMIPHelper&);  // Not implemented.
};

#endif



