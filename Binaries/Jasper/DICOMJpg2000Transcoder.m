#import "DICOMJpg2000Transcoder.h"
#import "Jasper.h"
#import "DICOM.h"


@implementation DICOMJpg2000Transcoder

+ (void)convertToHost:(DICOMObject *)dicomObject{
	NSMutableData *data = [dicomObject pixelData];
	int fmtid;
	jas_image_t *jasImage;
	char *fmtname;
	jas_init();
	jas_stream_t *jasStream = jas_stream_memopen((char *)[data bytes], [data length]);
		
	if ((fmtid = jas_image_getfmt(jasStream)) < 0) 
		NSLog(@"unknown image format\n");
		

		// Decode the image. 
	if (!(jasImage = jas_image_decode(jasStream, fmtid, 0))) 
		NSLog(@"cannot load image\n");
		

		// Close the image file. 
		jas_stream_close(jasStream);
		int numcmpts = jas_image_numcmpts(jasImage);
		int width = jas_image_cmptwidth(jasImage, 0);
		int height = jas_image_cmptheight(jasImage, 0);
		int depth = jas_image_cmptprec(jasImage, 0);
		int i;
		int j;
		int k = 0;
		fmtname = jas_image_fmttostr(fmtid);
		//NSLog(@"%s %d %d %d %d %ld\n", fmtname, numcmpts, width, height, depth, (long) jas_image_rawsize(jasImage));
		int bitDepth = 0;
		if (depth == 8)
			bitDepth = 1;
		else if (depth <= 16)
			bitDepth = 2;
		else if (depth > 16)
			bitDepth = 4;
		NSMutableData *newPixelData = [NSMutableData dataWithLength:(int)(width * height * bitDepth * numcmpts)];
		// short data
		if (depth > 8) {
			signed short *bitmapData = [newPixelData mutableBytes];
			for ( i = 0; i < height; i++) {
				for ( j = 0; j < width; j++) {
					for ( k= 0; k < numcmpts; k++)
					*bitmapData++ =	(signed short)(jas_image_readcmptsample(jasImage, k, j ,i ));
				}
			}
		}
		// char data
		else { 
			unsigned char *bitmapData = [newPixelData mutableBytes];
			for ( i = 0; i < height; i++) {
				for ( j = 0; j < width; j++) {
					for ( k= 0; k < numcmpts; k++)
					*bitmapData++ =	(unsigned char)(jas_image_readcmptsample(jasImage, k, j ,i ));
				}
			}
		}
		//void *imageData = jasMatrix->data_;
		jas_image_destroy(jasImage);
		jas_image_clearfmts();
		
		[dicomObject setPixelData:newPixelData];
		//NSLog(@"PixelData length: %d", [[dicomObject pixelData] length]);
}

+ (void)convertToNative:(DICOMObject *)dicomObject{
	[DICOMJpg2000Transcoder convertToHost:dicomObject];
}


@end
