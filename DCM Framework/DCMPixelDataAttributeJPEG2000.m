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

#import "DCMPixelDataAttributeJPEG2000.h"
#import "DCM.h"
/*
jas_image_t *raw_decode(jas_stream_t *in, NSDictionary *info){
	
	jas_image_t *image;
	jas_image_cmptparm_t cmptparms[3];
	jas_image_cmptparm_t *cmptparm;
	int i;
	int width = [[info objectForKey:@"Width"] intValue];
	int height = [[info objectForKey:@"Height"] intValue];
	int spp = [[info objectForKey:@"SamplesPerPixel"] intValue];
	int prec = [[info objectForKey:@"Precision"] intValue];
	BOOL sgnd = [[info objectForKey:@"Signed"] boolValue];

	
	for (i = 0, cmptparm = cmptparms; i < spp; ++i, ++cmptparm) {
		cmptparm->tlx = 0;
		cmptparm->tly = 0;
		cmptparm->hstep = 1;
		cmptparm->vstep = 1;
		cmptparm->width = width;
		cmptparm->height = height;
		cmptparm->prec = prec;
		cmptparm->sgnd = sgnd;
	}
	
	if (!(image = jas_image_create(spp, cmptparms, JAS_CLRSPC_UNKNOWN))) {
		return nil;
	}
	
	return image;
}
*/
/******************************************************************************\
* Miscellaneous functions.
\******************************************************************************/

int pnm_getuint(jas_stream_t *in, int wordsize, uint_fast32_t *val);

static int pnm_getsint(jas_stream_t *in, int wordsize, int_fast32_t *val)
{
	uint_fast32_t tmpval;

	if (pnm_getuint(in, wordsize, &tmpval)) {
		return -1;
	}
	if (val) {
		assert((tmpval & (1 << (wordsize - 1))) == 0);
		*val = tmpval;
	}

	return 0;
}

int pnm_getuint(jas_stream_t *in, int wordsize, uint_fast32_t *val)
{
	uint_fast32_t tmpval;
	int c;
	int n;

	tmpval = 0;
	n = (wordsize + 7) / 8;
	while (--n >= 0) {
		if ((c = jas_stream_getc(in)) == EOF) {
			return -1;
		}
		tmpval = (tmpval << 8) | c;
	}
	tmpval &= (((uint_fast64_t) 1) << wordsize) - 1;
	if (val) {
		*val = tmpval;
	}

	return 0;
}
/*
static int pnm_getc(jas_stream_t *in)
{
	int c;
	for (;;) {
		if ((c = jas_stream_getc(in)) == EOF) {
			return -1;
		}
		if (c != '#') {
			return c;
		}
		do {
			if ((c = jas_stream_getc(in)) == EOF) {
				return -1;
			}
		} while (c != '\n' && c != '\r');
	}
}

static int pnm_getint16(jas_stream_t *in, int *val)
{
	int v;
	int c;

	if ((c = jas_stream_getc(in)) == EOF) {
		return -1;
	}
	v = c & 0xff;
	if ((c = jas_stream_getc(in)) == EOF) {
		return -1;
	}
	v = (v << 8) | (c & 0xff);
	*val = v;

	return 0;
}
*/
@implementation DCMPixelDataAttribute (DCMPixelDataAttributeJPEG2000)

//- (NSMutableData *)encodeJPEG2000:(NSMutableData *)data quality:(int)quality
//{
//	NSMutableData *jpeg2000Data = nil;	
//	jas_image_t *image;
//	jas_image_cmptparm_t cmptparms[3];
//	jas_image_cmptparm_t *cmptparm;
//	int i;
//	int width = _columns;
//	int height = _rows;
//	int spp = _samplesPerPixel;
////	int prec = _pixelDepth;
//	int prec = [[_dcmObject attributeValueWithName:@"BitsStored"] intValue];
//	BOOL sgnd = [[_dcmObject attributeValueWithName:@"PixelRepresentation"] intValue];
//	if ([[_dcmObject attributeValueWithName:@"RescaleIntercept"] intValue] < 0)
//		sgnd = YES;
//		
//	if (sgnd &&  prec > 8)
//	{
//		//Encode
//		[self encodeRescale:data WithPixelDepth:prec];
//		sgnd = NO;
//	}
//	else
//		[_dcmObject removePlanarAndRescaleAttributes];
//	
//	unsigned char *buffer = (unsigned char*)[data bytes];
//	int theLength = [data length];
//	jas_init();
//	jas_stream_t *jasStream = jas_stream_memopen((char *)buffer, theLength);
//	
//	
//	for (i = 0, cmptparm = cmptparms; i < spp; ++i, ++cmptparm)
//	{
//		cmptparm->tlx = 0;
//		cmptparm->tly = 0;
//		cmptparm->hstep = 1;
//		cmptparm->vstep = 1;
//		cmptparm->width = width;
//		cmptparm->height = height;
//		cmptparm->prec = prec;
//		cmptparm->sgnd = sgnd;
//	}
//	
//	if (!(image = jas_image_create(spp, cmptparms, JAS_CLRSPC_UNKNOWN))) {
//		return nil;
//	}
//	
//	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"PhotometricInterpretation"];
//	DCMAttribute *attr = [[_dcmObject attributes] objectForKey:[tag stringValue]];
//	NSString *photometricInterpretation = [attr value];
//	//int jasColorSpace = JAS_CLRSPC_UNKNOWN;
//	if ([photometricInterpretation isEqualToString:@"MONOCHROME1"] || [photometricInterpretation isEqualToString:@"MONOCHROME2"]) {
//		jas_image_setclrspc(image, JAS_CLRSPC_SGRAY);
//		jas_image_setcmpttype(image, 0,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_GRAY_Y));
//	}
//	else if ([photometricInterpretation isEqualToString:@"RGB"] || [photometricInterpretation isEqualToString:@"ARGB"]) {
//		jas_image_setclrspc(image, JAS_CLRSPC_SRGB);
//		jas_image_setcmpttype(image, 0,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_RGB_R));
//		jas_image_setcmpttype(image, 1,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_RGB_G));
//		jas_image_setcmpttype(image, 2,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_RGB_B));
//	}
//	else if ([photometricInterpretation isEqualToString:@"YBR_FULL_422"] || [photometricInterpretation isEqualToString:@"YBR_PARTIAL_422"] || [photometricInterpretation isEqualToString:@"YBR_FULL"]) {
//		jas_image_setclrspc(image, JAS_CLRSPC_FAM_YCBCR);
//		jas_image_setcmpttype(image, 0,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_YCBCR_Y));
//		jas_image_setcmpttype(image, 1,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_YCBCR_CB));
//		jas_image_setcmpttype(image, 2,
//		  JAS_IMAGE_CT_COLOR(JAS_CLRSPC_CHANIND_YCBCR_CR));
//		
//	}
//		/*
//	if ([photometricInterpretation isEqualToString:@"CMYK"])
//		jasColorSpace = JCS_CMYK;
//		*/
//	int cmptno;	
//	int x,y;
//	jas_matrix_t *jasData[3];
//	int_fast64_t v;
//	jasData[0] = 0;
//	jasData[1] = 0;
//	jasData[2] = 0;	
//	for (cmptno = 0; cmptno < spp; ++cmptno)
//	{
//		if (!(jasData[cmptno] = jas_matrix_create(1, width)))
//		{
//			return nil;
//		}
//	}
//	
//	for (y = 0; y < height; ++y) {
//		for (x = 0; x < width; ++x) {
//			for (cmptno = 0; cmptno < spp; ++cmptno) {
//				if (sgnd) {
//					/* The sample data is signed. */
//					int_fast32_t sv;
//					if (pnm_getsint(jasStream, prec, &sv)) {
//						/*
//						if (!pnm_allowtrunc) {
//							goto done;
//						}
//						*/
//						sv = 0;
//					}
//					v = sv;
//				} else {
//					/* The sample data is unsigned. */
//					uint_fast32_t uv;
//					if (pnm_getuint(jasStream, prec, &uv)) {
//						/*
//						if (!pnm_allowtrunc) {
//							goto done;
//						}
//						*/
//						uv = 0;
//					}
//					v = uv;
//				}
//				jas_matrix_set(jasData[cmptno], 0, x, v);
//			}
//		}	
//		for (cmptno = 0; cmptno < spp; ++cmptno)
//		{
//			if (jas_image_writecmpt(image, cmptno, 0, y, width, 1, jasData[cmptno]))
//			{
//				NSLog( @"Err");
//			}
//		}
//	}
//	
//	//write to JPEG2000
//	char *optstr = "rate=0.05 mode=int";
//	if (quality == DCMLosslessQuality) {
//		optstr = nil;
//	}
//	else if (quality == DCMHighQuality) {
//		optstr = "rate=0.1 mode=int";
//	}
//	else if (quality == DCMMediumQuality)
//		optstr = "rate=0.05 mode=int";
//		
//	else if (quality ==  DCMLowQuality) {
//		optstr = "rate=0.02 mode=int";
//	}
//	
//	unsigned char *outBuffer = malloc(theLength);
//	jas_stream_t *outS =  jas_stream_memopen((char *)outBuffer, theLength);
//	jpc_encode(image, outS , optstr);
//	jas_stream_flush(outS );
//
//	long compressedLength = jas_stream_tell(outS);
//
//	
////	NSString *tmpFile = @"/tmp/dcm.jpc";
////	jas_stream_t  *out = jas_stream_fopen("/tmp/dcm.jpc", "w+b");
////	jpc_encode(image, out, optstr);
////	long compressedLength = jas_stream_length(out);
//
//	jpeg2000Data = [NSMutableData dataWithBytes:outBuffer length:compressedLength];
//
//
//	for (cmptno = 0; cmptno < spp; ++cmptno) {
//		if (jasData[cmptno]) {
//			jas_matrix_destroy(jasData[cmptno]);
//		}
//	}
//	
//	(void) jas_stream_close(outS);
//	free(outBuffer);
//	jas_image_destroy(image);
//	jas_image_clearfmts();
//	
//
//	return jpeg2000Data;
//}

@end
