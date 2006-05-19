//
//  DICOMToNSString.m
//  OsiriX
//
//  Created by Lance Pysher on 3/3/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/*
 *  Last Update:      $Author: meichel $
 *  Update Date:      $Date: 2005/12/08 15:44:22 $
 *  Source File:      $Source: /share/dicom/cvs-depot/dcmtk/dcmnet/apps/storescu.cc,v $
 *  CVS/RCS Revision: $Revision: 1.64 $
 *  Status:           $State: Exp $

 * svn Log:
 * $Log: DICOMToNSString.mm,v $
*/

#import "DICOMToNSString.h"

@implementation NSString (DICOMToNSString)

- (id) initWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding{	
	NSLog(@"String %s  encoding: %@",cString,  encoding);
	NSStringEncoding stringEncoding = [NSString encodingForDICOMCharacterSet:encoding];
	return [self initWithCString:cString  encoding:stringEncoding];
}

+ (id) stringWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding{
	return [[[NSString alloc] initWithCString:(char *)cString  DICOMEncoding:(NSString *)encoding] autorelease];
}

+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet{
	NSStringEncoding	encoding = NSISOLatin1StringEncoding;
	if	   ( [characterSet isEqualToString:@"ISO_IR 100"]) encoding = NSISOLatin1StringEncoding; 	
	else if( [characterSet isEqualToString:@"ISO_IR 127"]) encoding = -2147483130;	//[characterSet numberFromLocalizedStringEncodingName :@"Arabic (ISO 8859-6)"];
	else if( [characterSet isEqualToString:@"ISO_IR 101"]) encoding = NSISOLatin2StringEncoding;
	else if( [characterSet isEqualToString:@"ISO_IR 109"]) encoding = -2147483133;	//[characterSet numberFromLocalizedStringEncodingName :@"Western (ISO Latin 3)"];
	else if( [characterSet isEqualToString:@"ISO_IR 110"]) encoding = -2147483132;	//[characterSet numberFromLocalizedStringEncodingName :@"Central European (ISO Latin 4)"];
	else if( [characterSet isEqualToString:@"ISO_IR 144"]) encoding = -2147483131;	//[characterSet numberFromLocalizedStringEncodingName :@"Cyrillic (ISO 8859-5)"];
	else if( [characterSet isEqualToString:@"ISO_IR 126"]) encoding = -2147483129;	//[characterSet numberFromLocalizedStringEncodingName :@"Greek (ISO 8859-7)"];
	else if( [characterSet isEqualToString:@"ISO_IR 138"]) encoding = -2147483128;	//[characterSet numberFromLocalizedStringEncodingName :@"Hebrew (ISO 8859-8)"];
	else if( [characterSet isEqualToString:@"GB18030"]) encoding = -2147482062;	//[characterSet numberFromLocalizedStringEncodingName :@"Chinese (GB 18030)"];
	else if( [characterSet isEqualToString:@"ISO_IR 192"]) encoding = NSUTF8StringEncoding;
	else if( [characterSet isEqualToString:@"ISO 2022 IR 149"]) encoding = -2147483645;	//[characterSet numberFromLocalizedStringEncodingName :@"Korean (Mac OS)"];
	else if( [characterSet isEqualToString:@"ISO 2022 IR 13"]) encoding = -2147483647;	//21 //[characterSet numberFromLocalizedStringEncodingName :@"Japanese (ISO 2022-JP)"];	//
	else if( [characterSet isEqualToString:@"ISO_IR 13"]) encoding = -2147483647;	//[characterSet numberFromLocalizedStringEncodingName :@"Japanese (Mac OS)"];
	else if( [characterSet isEqualToString:@"ISO 2022 IR 87"]) encoding = NSISO2022JPStringEncoding;
	else if( [characterSet isEqualToString:@"ISO_IR 166"]) encoding = -2147483125;	//[characterSet numberFromLocalizedStringEncodingName :@"Thai (ISO 8859-11)"];
	
	return encoding;

}





@end
