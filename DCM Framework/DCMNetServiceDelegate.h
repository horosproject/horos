/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <Cocoa/Cocoa.h>

/** \ brief Eanbles DICOM Bonjour */
@interface DCMNetServiceDelegate : NSObject {

	NSNetServiceBrowser *_dicomNetBrowser;
	NSMutableArray *_dicomServices;
	NSNetService *publisher;
}
+ (NSString*) gethostnameAndPort: (int*) port forService:(NSNetService*) sender;
+ (NSHost*) currentHost;
+ (NSArray *) DICOMServersList;
+ (NSArray *) DICOMServersListSendOnly: (BOOL) send QROnly:(BOOL) QR;
+ (NSArray *) DICOMServersListSendOnly: (BOOL) send QROnly:(BOOL) QR forked:(BOOL) forked;
+ (id)sharedNetServiceDelegate;
- (void) setPublisher: (NSNetService*) p;
- (void)update;
- (NSArray *)dicomServices;
- (int)portForNetService:(NSNetService *)netService;

@end
