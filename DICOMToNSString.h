//
//  DICOMToNSString.h
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
 * $Log: DICOMToNSString.h,v $
*/

#import <Cocoa/Cocoa.h>

@interface NSString  (DICOMToNSString)

- (id) initWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding;
+ (id) stringWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding;
+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet;


@end
