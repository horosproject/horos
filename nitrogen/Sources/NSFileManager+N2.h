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


@interface NSFileManager (N2)

-(NSString*)findSystemFolderOfType:(int)folderType forDomain:(int)domain;
-(NSString*)userApplicationSupportFolderForApp;
-(NSString*)tmpFilePathInDir:(NSString*)dirPath;
-(NSString*)tmpFilePathInTmp;
-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath;
-(NSString*)confirmNoIndexDirectoryAtPath:(NSString*)path;
-(NSUInteger)sizeAtPath:(NSString*)path;
-(NSUInteger)sizeAtFSRef:(FSRef*)theFileRef;
-(BOOL)copyItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath byReplacingExisting:(BOOL)replace error:(NSError**)err;
	
@end
