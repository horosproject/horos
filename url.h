/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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
//  url.h
//  OsiriX_Lion
//
//  Created by Alex Bettarini on 22 Nov 2014.
//  Copyright (c) 2014 Osiri-LXIV Team. All rights reserved.
//

#ifndef URL_H_INCLUDED
#define URL_H_INCLUDED

// search for URLWithString
#define URL_HOROS_VIEWER           @"http://www.horosproject.org"
#define URL_HOROS_WEB_PAGE         URL_HOROS_VIEWER
#define URL_VENDOR                 URL_HOROS_VIEWER
#define URL_EMAIL                  @"horos@horosproject.org"

#define URL_VENDOR_NOTICE          URL_HOROS_VIEWER
#define URL_VENDOR_USER_MANUAL     URL_HOROS_VIEWER

#define URL_HOROS_DOC_SECURITY     URL_HOROS_VIEWER

#define URL_HOROS_LEARNING         URL_HOROS_VIEWER@"/community/communicate/"
#define URL_HOROS_UPDATE           URL_HOROS_VIEWER@"/adaa7f5d1f33cb8ddd89fe300da7c2cd/"
#define URL_HOROS_UPDATE_CRASH     URL_HOROS_VIEWER@"/adaa7f5d1f33cb8ddd89fe300da7c2cd/"

#define URL_HOROS_VERSION          URL_HOROS_VIEWER@"/version.xml"

#define URL_HOROS_PLUGINS          URL_HOROS_VIEWER@"/horosplugins.html"


////////////////////////////////////////////////////////////////////////////////
// We want our own Defaults plist saved in ~/Library/Preferences/
// Make sure it matches "Bundle Identifier" in Deployment-Info.plist

#define BUNDLE_IDENTIFIER_PREFIX    "com.horosproject"
#define BUNDLE_IDENTIFIER           "com.horosproject.horos"

////////////////////////////////////////////////////////////////////////////////
// This is the address of the plist containing the list of the available plugins.
// the alternative link will be used if the first one doesn't reply...

//#define OSIRIX_PLUGIN_LIST_URL            @"http://www.osirix-viewer.com/osirix_plugins/plugins.plist"
//#define OSIRIX_PLUGIN_LIST_ALT_URL        @"http://www.osirixviewer.com/osirix_plugins/plugins.plist"

#define OSIRIX_PLUGIN_LIST_URL              @"http://www.horosproject.org/osirix_plugins/osirixplugins.plist"
#define OSIRIX_PLUGIN_LIST_ALT_URL          @"http://www.horosproject.org/wp-content/uploads/osirix_plugins/osirixplugins.plist"

#define HOROS_PLUGIN_LIST_URL               @"http://www.horosproject.org/horos_plugins/horosplugins.plist"
#define HOROS_PLUGIN_LIST_ALT_URL           @"http://www.horosproject.org/wp-content/uploads/horos_plugins/horosplugins.plist"

#define HOROS_PLUGIN_SUBMISSION_URL         @"http://www.horosproject.org/wp-content/horos_plugins/submit_plugin/index.html"

#endif
