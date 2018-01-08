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

#import "Notifications.h"

NSString* const OsirixUpdateWLWWMenuNotification = @"UpdateWLWWMenu";
NSString* const OsirixChangeWLWWNotification = @"changeWLWW";
NSString* const OsirixROIChangeNotification = @"roiChange";
NSString* const OsirixCloseViewerNotification = @"CloseViewerNotification";
NSString* const OsirixUpdate2dCLUTMenuNotification = @"Update2DCLUTMenu";
NSString* const OsirixUpdate2dWLWWMenuNotification = @"Update2DWLWWMenu";
NSString* const OsirixLLMPRResliceNotification = @"LLMPRReslice";
NSString* const OsirixROIVolumePropertiesChangedNotification = @"ROIVolumePropertiesChanged";
NSString* const OsirixVRViewDidBecomeFirstResponderNotification = @"VRViewDidBecomeFirstResponder";
NSString* const OsirixUpdateVolumeDataNotification = @"updateVolumeData";
NSString* const OsirixRevertSeriesNotification = @"revertSeriesNotification";
NSString* const OsirixOpacityChangedNotification = @"OpacityChanged";
NSString* const OsirixDefaultToolModifiedNotification = @"defaultToolModified";
NSString* const OsirixDefaultRightToolModifiedNotification = @"defaultRightToolModified";
NSString* const OsirixUpdateConvolutionMenuNotification = @"UpdateConvolutionMenu";
NSString* const OsirixCLUTChangedNotification = @"CLUTChanged";
NSString* const OsirixUpdateCLUTMenuNotification = @"UpdateCLUTMenu";
NSString* const OsirixUpdateOpacityMenuNotification = @"UpdateOpacityMenu";
NSString* const OsirixRecomputeROINotification = @"recomputeROI";
NSString* const OsirixStopPlayingNotification = @"notificationStopPlaying";
NSString* const OsirixChatBroadcastNotification = @"notificationiChatBroadcast";
NSString* const OsirixSyncSeriesNotification = @"notificationSyncSeries";
NSString* const OsirixOrthoMPRSyncSeriesNotification = @"orthoMPRSyncSeriesNotification";
NSString* const OsirixReportModeChangedNotification = @"reportModeChanged";
NSString* const OsirixDeletedReportNotification = @"OsirixDeletedReport";
NSString* const OsirixStudyAnnotationsChangedNotification = @"OsirixStudyAnnotationsChanged";
NSString* const OsirixGLFontChangeNotification = @"changeGLFontNotification";
NSString* const OsirixAddToDBNotification = @"OsirixAddToDBNotification";
NSString* const OsirixAddNewStudiesDBNotification = @"OsirixAddNewStudiesDBNotification";
NSString* const OsirixDicomDatabaseDidChangeContextNotification = @"OsirixDicomDatabaseDidChangeContextNotification";
#define OsiriXAddToDBArrayKey @"OsiriXAddToDBArray"
NSString* const OsirixAddToDBNotificationImagesArray = OsiriXAddToDBArrayKey;
NSString* const OsirixAddToDBNotificationImagesPerAETDictionary = @"PerAETDictionary";
NSString* const OsirixAddToDBCompleteNotification = @"OsirixAddToDBCompleteNotification";
NSString* const OsirixAddToDBCompleteNotificationImagesArray = OsiriXAddToDBArrayKey; // is deprecated in favor of OsirixAddToDBNotificationImagesArray
NSString* const _O2AddToDBAnywayNotification = @"_O2AddToDBAnywayNotification";
NSString* const _O2AddToDBAnywayCompleteNotification = @"_O2AddToDBAnywayCompleteNotification";
NSString* const O2DatabaseInvalidateAlbumsCacheNotification = @"InvalidateAlbumsCache";
NSString* const OsirixDatabaseObjectsMayBecomeUnavailableNotification = @"OsirixDatabaseObjectsMayBecomeUnavailableNotification";
NSString* const OsirixNewStudySelectedNotification = @"NewStudySelectedNotification";
NSString* const OsirixDidLoadNewObjectNotification = @"OsiriX Did Load New Object";
NSString* const OsirixRTStructNotification = @"RTSTRUCTNotification";
NSString* const OsirixAlternateButtonPressedNotification = @"AlternateButtonPressed";
NSString* const OsirixROISelectedNotification = @"roiSelected";
NSString* const OsirixRemoveROINotification = @"removeROI";
NSString* const OsirixROIRemovedFromArrayNotification = @"roiRemovedFromArray";
NSString* const OsirixChangeFocalPointNotification = @"changeFocalPoint";
NSString* const OsirixWindow3dCloseNotification = @"Window3DClose";
NSString* const OsirixDisplay3dPointNotification = @"Display3DPoint";
NSString* const AppPluginDownloadInstallDidFinishNotification = @"PluginManagerControllerDownloadAndInstallDidFinish";
NSString* const OsirixXMLRPCMessageNotification = @"OsiriXXMLRPCMessage";
NSString* const OsirixDragMatrixImageMovedNotification = @"DragMatrixImageMoved";
NSString* const OsirixNotification = @"VRCameraDidChange";
NSString* const OsiriXFileReceivedNotification = @"OsiriXFileReceivedNotification";
NSString* const OsirixDCMSendStatusNotification = @"DCMSendStatus";
NSString* const OsirixDCMUpdateCurrentImageNotification = @"DCMUpdateCurrentImage";
NSString* const OsirixDCMViewIndexChangedNotification = @"DCMViewIndexChanged";
NSString* const OsirixRightMouseUpNotification = @"PLUGINrightMouseUp";
NSString* const OsirixMouseDownNotification = @"mouseDown";
NSString* const OsirixVRCameraDidChangeNotification = @"VRCameraDidChange";
NSString* const OsirixSyncNotification = @"sync";
NSString* const OsirixOrthoMPRPosChangeNotification = @"orthoMPRPosChangeNotification";
NSString* const OsirixAddROINotification = @"addROI";
NSString* const OsirixRightMouseDownNotification = @"PLUGINrightMouseDown";
NSString* const OsirixRightMouseDraggedNotification = @"PLUGINrightMouseDragged";
NSString* const OsirixLabelGLFontChangeNotification = @"changeLabelGLFontNotification";
NSString* const OsirixDrawTextInfoNotification = @"PLUGINdrawTextInfo";
NSString* const OsirixDrawObjectsNotification = @"PLUGINdrawObjects";
NSString* const OsirixDCMViewDidBecomeFirstResponderNotification = @"DCMViewDidBecomeFirstResponder";
NSString* const OsirixPerformDragOperationNotification = @"PluginDragOperationNotification";
NSString* const OsirixViewerWillChangeNotification = @"ViewerWillChangeNotification";
NSString* const OsirixViewerDidChangeNotification = @"ViewerDidChangeNotification";
NSString* const OsirixUpdateViewNotification = @"updateView";
NSString* const OsirixViewerControllerDidLoadImagesNotification = @"OsirixViewerControllerDidLoadImagesNotification";
NSString* const OsirixViewerControllerWillFreeVolumeDataNotification = @"OsirixViewerControllerWillFreeVolumeDataNotification"; // userinfo dict will contain an NSData with @"volumeData" key and a NSNumber with @"movieIndex" key
NSString* const OsirixViewerControllerDidAllocateVolumeDataNotification = @"OsirixViewerControllerDidAllocateVolumeDataNotification"; // userinfo dict will contain an NSData with @"volumeData" key and a NSNumber with @"movieIndex" key
NSString* const KFSplitViewDidCollapseSubviewNotification = @"KFSplitViewDidCollapseSubviewNotification";
NSString* const KFSplitViewDidExpandSubviewNotification = @"KFSplitViewDidExpandSubviewNotification";
NSString* const BLAuthenticatedNotification = @"BLAuthenticatedNotification";
NSString* const BLDeauthenticatedNotification = @"BLDeauthenticatedNotification";

NSString* const OsirixActiveLocalDatabaseDidChangeNotification = @"OsirixActiveLocalDatabaseDidChangeNotification";

NSString* const OsirixPopulatedContextualMenuNotification = @"OsirixPopulatedContextualMenuNotification";
NSString* const OsiriXLogEvent = @"OsiriXLogEvent";

NSString* const OsirixNodeRemovedFromCurvePathNotification = @"OsirixNodeRemovedFromCurvePath";
NSString* const OsirixUpdateCurvedPathCostNotification = @"OsirixUpdateCurvedPathCost";
NSString* const OsirixDeletedCurvedPathNotification = @"OsirixDeletedCurvedPath";
