//
//  AYNSImageToDicom.h
//  FilmComposer
//
//  Created by Martin Suda on 03.07.06.
//  Copyright 2006 aycan digitalsysteme gmbh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"
#import "DCMView.h"


enum
{
	eCurrentImage = 0,
	eKeyImages = 1,
	eAllImages = 2,
};

struct rawData
{
	unsigned char *imageData;
	long bytesWritten;
};

@interface AYNSImageToDicom : NSObject
{
	NSMutableData	*m_ImageDataBytes;
}

- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;
- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath fileList: (NSArray *) fileList asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;

@end
