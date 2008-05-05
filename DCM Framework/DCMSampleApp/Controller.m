//
//  Controller.m
//  DCMSampleApp
//
//  Created by Lance Pysher on Thu Jun 17 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import "Controller.h"
#import "DCM.h"
#import "OpenGLView.h"
#import <veclib/veclib.h>

vImage_Error MyInitBuffer( vImage_Buffer *result, int height, int width, size_t bytesPerPixel )
{
	size_t rowBytes = width * bytesPerPixel;
	//Widen rowBytes out to a integer multiple of 16 bytes

	rowBytes = (rowBytes + 15) & ~15;

	//Make sure we are not an even power of 2 wide. 
	//Will loop a few times for rowBytes <= 16.

	while( 0 == (rowBytes & (rowBytes - 1) ) )
		rowBytes += 16; //grow rowBytes

	//Set up the buffer
	result->height = height;
	result->width = width;
	result->rowBytes = rowBytes;
	result->data = malloc( rowBytes * height );
	if (result->data == nil)
		return kvImageMemoryAllocationError;
	return kvImageNoError;
}

        

 void MyFreeBuffer( vImage_Buffer *buffer )
 {
    if( buffer && buffer->data )
        free( buffer->data );
 }

@implementation Controller

-(IBAction) open : (id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel runModalForTypes:nil];
	NSString *path = [openPanel filename];

	
	DCMObject *object = [[DCMObject alloc] initWithContentsOfFile:path decodingPixelData:NO];
	DCMAttribute *name = [object attributeForTag:[DCMAttributeTag tagWithName:@"PatientsName"]];
	[name setValues:[NSMutableArray arrayWithObject:@"jp2 Test"]];
	DCMAttribute *i = [object attributeForTag:[DCMAttributeTag tagWithName:@"PatientID"]];
	[i setValues:[NSMutableArray arrayWithObject:@"jp2 Test"]];
	[object newSOPInstanceUID];
	/*
	NSData *data = [[object attributeForTag:[DCMAttributeTag tagWithName:@"PixelData"]] value];
	signed short *buffer = [data bytes];
	int length = [data length] / 2;
	int i;
	for (i = 0; i < length; i+= 2500) 
		NSLog(@"value %d", buffer[i]); 
	*/
		
		
	/*
	DCMObject *scObject = [DCMObject secondaryCaptureObjectFromTemplate:object];
	if (scObject)
		NSLog([scObject description]);
	*/
	
	/*
	if (object)
		NSLog([object description]);
	*/
	NSString *outFile = @"~/Desktop/dcmtest.dcm";
	//[object writeToFile:[outFile  stringByExpandingTildeInPath] withTransferSyntax:[DCMTransferSyntax JPEGExtendedTransferSyntax] quality: DCMHighQuality atomically:YES];
	[object writeToFile:[outFile  stringByExpandingTildeInPath] withTransferSyntax:[DCMTransferSyntax JPEG2000LossyTransferSyntax] quality: DCMMediumQuality atomically:YES];
	//[object writeToFile:[outFile  stringByExpandingTildeInPath] withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
	
}

@end
