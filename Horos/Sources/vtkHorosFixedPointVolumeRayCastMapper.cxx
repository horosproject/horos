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

#include "vtkHorosFixedPointVolumeRayCastMapper.h"

#include <vtkObjectFactory.h>
#include <vtkRenderWindow.h>
#include <vtkRenderer.h>
#include <vtkTimerLog.h>
#include <vtkRayCastImageDisplayHelper.h>
#include "vtkHorosFixedPointVolumeRayCastMIPHelper.h"

#include <math.h>

int dontRenderVolumeRenderingOsiriX = 0;

vtkStandardNewMacro(vtkHorosFixedPointVolumeRayCastMapper);

vtkHorosFixedPointVolumeRayCastMapper::vtkHorosFixedPointVolumeRayCastMapper()
{
    this->MIPHelper = vtkHorosFixedPointVolumeRayCastMIPHelper::New();
}

void vtkHorosFixedPointVolumeRayCastMapper::DisplayRenderedImage( vtkRenderer *ren, vtkVolume   *vol )
{
    float depth;
    if ( this->IntermixIntersectingGeometry )
    {
        depth = this->MinimumViewDistance;
    }
    else
    {
        depth = -1;
    }
    
    
    if( this->FinalColorWindow != 1.0 || this->FinalColorLevel != 0.5 )
    {
        this->ApplyFinalColorWindowLevel();
    }
    
    this->ImageDisplayHelper->RenderTexture( vol, ren, this->RayCastImage, depth );
}


void vtkHorosFixedPointVolumeRayCastMapper::Render( vtkRenderer *ren, vtkVolume *vol )
{
  this->Timer->StartTimer();

  // Since we are passing in a value of 0 for the multiRender flag
  // (this is a single render pass - not part of a multipass AMR render)
  // then we know the origin, spacing, and extent values will not
  // be used so just initialize everything to 0. No need to check
  // the return value of the PerImageInitialization method - since this
  // is not a multirender it will always return 1.
  double dummyOrigin[3]  = {0.0, 0.0, 0.0};
  double dummySpacing[3] = {0.0, 0.0, 0.0};
  int dummyExtent[6] = {0, 0, 0, 0, 0, 0};
  this->PerImageInitialization( ren, vol, 0,
				dummyOrigin,
				dummySpacing,
				dummyExtent );

  this->PerVolumeInitialization( ren, vol );

  vtkRenderWindow *renWin=ren->GetRenderWindow();

  if ( renWin && renWin->CheckAbortStatus() )
    {
    this->AbortRender();
    return;
    }

  this->PerSubVolumeInitialization( ren, vol, 0 );
  if ( renWin && renWin->CheckAbortStatus() )
    {
    this->AbortRender();
    return;
    }

  if( dontRenderVolumeRenderingOsiriX == 0)
	this->RenderSubVolume();

  if ( renWin && renWin->CheckAbortStatus() )
    {
    this->AbortRender();
    return;
    }

  this->DisplayRenderedImage( ren, vol );

  this->Timer->StopTimer();
  this->TimeToDraw = this->Timer->GetElapsedTime();
  // If we've increased the sample distance, account for that in the stored time. Since we
  // don't get linear performance improvement, use a factor of .66
  this->StoreRenderTime( ren, vol,
			 this->TimeToDraw *
			 this->ImageSampleDistance *
			 this->ImageSampleDistance *
			 ( 1.0 + 0.66*
			   (this->SampleDistance - this->OldSampleDistance) /
			   this->OldSampleDistance ) );

  this->SampleDistance = this->OldSampleDistance;
}
