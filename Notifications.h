/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>

extern NSString* const OsirixUpdateWLWWMenuNotification;
extern NSString* const OsirixChangeWLWWNotification;
extern NSString* const OsirixROIChangeNotification;
extern NSString* const OsirixCloseViewerNotification;
extern NSString* const OsirixUpdate2dCLUTMenuNotification;
extern NSString* const OsirixUpdate2dWLWWMenuNotification;
extern NSString* const OsirixLLMPRResliceNotification;
extern NSString* const OsirixROIVolumePropertiesChangedNotification;
extern NSString* const OsirixVRViewDidBecomeFirstResponderNotification;
extern NSString* const OsirixUpdateVolumeDataNotification;
extern NSString* const OsirixRevertSeriesNotification;
extern NSString* const OsirixOpacityChangedNotification;
extern NSString* const OsirixDefaultToolModifiedNotification;
extern NSString* const OsirixDefaultRightToolModifiedNotification;
extern NSString* const OsirixUpdateConvolutionMenuNotification;
extern NSString* const OsirixCLUTChangedNotification;
extern NSString* const OsirixUpdateCLUTMenuNotification;
extern NSString* const OsirixUpdateOpacityMenuNotification;
extern NSString* const OsirixRecomputeROINotification;
extern NSString* const OsirixStopPlayingNotification;
extern NSString* const OsirixChatBroadcastNotification;
extern NSString* const OsirixSyncSeriesNotification;
extern NSString* const OsirixReportModeChangedNotification;
extern NSString* const OsirixDeletedReportNotification;
extern NSString* const OsirixServerArrayChangedNotification;
extern NSString* const OsirixGLFontChangeNotification;
extern NSString* const OsirixAddToDBNotification;
extern const NSString* const OsirixAddToDBNotificationImagesArray;
extern NSString* const OsirixAddToDBCompleteNotification;
extern const NSString* const OsirixAddToDBCompleteNotificationImagesArray;
extern NSString* const OsirixNewStudySelectedNotification;
extern NSString* const OsirixDidLoadNewObjectNotification;
extern NSString* const OsirixRTStructNotification;
extern NSString* const OsirixAlternateButtonPressedNotification;
extern NSString* const OsirixROISelectedNotification;
extern NSString* const OsirixRemoveROINotification;
extern NSString* const OsirixROIRemovedFromArrayNotification;
extern NSString* const OsirixChangeFocalPointNotification;
extern NSString* const OsirixWindow3dCloseNotification;
extern NSString* const OsirixDisplay3dPointNotification;
extern NSString* const OsirixPluginDownloadInstallDidFinishNotification;
extern NSString* const OsirixXMLRPCMessageNotification;
extern NSString* const OsirixDragMatrixImageMovedNotification;
extern NSString* const OsirixNotification;
extern NSString* const OsiriXFileReceivedNotification;
extern NSString* const OsirixDCMSendStatusNotification;
extern NSString* const OsirixDCMUpdateCurrentImageNotification;
extern NSString* const OsirixDCMViewIndexChangedNotification;
extern NSString* const OsirixRightMouseUpNotification;
extern NSString* const OsirixMouseDownNotification;
extern NSString* const OsirixVRCameraDidChangeNotification;
extern NSString* const OsirixSyncNotification;
extern NSString* const OsirixAddROINotification;
extern NSString* const OsirixRightMouseDownNotification;
extern NSString* const OsirixRightMouseDraggedNotification;
extern NSString* const OsirixLabelGLFontChangeNotification;
extern NSString* const OsirixDrawTextInfoNotification;
extern NSString* const OsirixDrawObjectsNotification;
extern NSString* const OsirixDCMViewDidBecomeFirstResponderNotification;
extern NSString* const OsirixPerformDragOperationNotification;
extern NSString* const OsirixViewerWillChangeNotification;
extern NSString* const OsirixViewerDidChangeNotification;
extern NSString* const OsirixUpdateViewNotification;
extern NSString* const KFSplitViewDidCollapseSubviewNotification;
extern NSString* const KFSplitViewDidExpandSubviewNotification;
extern NSString* const BLAuthenticatedNotification;
extern NSString* const BLDeauthenticatedNotification;

/**
 * OsirixPopulatedContextualMenuNotification
 * object: NSMenu*
 * userInfo:
 *  - key [ViewerController className]
 *		the ViewerController the rightclick occurred in
 *	- key [ROI className], optional
 *		the rightclicked ROI
 **/
extern NSString* const OsirixPopulatedContextualMenuNotification;
