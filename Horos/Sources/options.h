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
//
//  options.h
//  OsiriX_Lion
//
//  Created by Alex Bettarini on 17 Nov 2014.
//  Copyright (c) 2014 Osiri-LXIV Team. All rights reserved.
//

#ifndef OPTIONS_H_INCLUDED
#define OPTIONS_H_INCLUDED

//#define VTK_USE_SYSTEM_TIFF

////////////////////////////////////////////////////////////////////////////////
#define WITH_IMPORTANT_NOTICE

////////////////////////////////////////////////////////////////////////////////
#define WITH_OS_VALIDATION

////////////////////////////////////////////////////////////////////////////////
#define WITH_RED_CAPTION

////////////////////////////////////////////////////////////////////////////////
/* If using this feature, you might want to change the TARGETS
 *  Build Settings,Code Signing
 *  from "Don't Code Sign"
 *  to "Developer ID Application: Your Name"
 */
//#define WITH_CODE_SIGNING // and certificate for Deployment build

////////////////////////////////////////////////////////////////////////////////
/* Also, search the source files for
 *  BUILTIN_DCMTK
 *  DCMDEBUG
 *  _STEREO_VISION_
 */
#endif
