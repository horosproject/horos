/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "N2DirectoryEnumerator.h"


@interface NSFileManager (N2)

-(void) moveItemAtPathToTrash: (NSString*) path;
-(NSString*)findSystemFolderOfType:(int)folderType forDomain:(int)domain;
-(NSString*)userApplicationSupportFolderForApp;
-(NSString*)tmpFilePathInDir:(NSString*)dirPath;
-(NSString*)tmpDirPath;
-(NSString*)tmpFilePathInTmp;
-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath;
-(NSString*)confirmNoIndexDirectoryAtPath:(NSString*)path;
-(NSUInteger)sizeAtPath:(NSString*)path;
-(NSUInteger)sizeAtFSRef:(FSRef*)theFileRef;
-(BOOL)copyItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath byReplacingExisting:(BOOL)replace error:(NSError**)err;

-(BOOL)applyFileModeOfParentToItemAtPath:(NSString*)path;

-(NSString*)destinationOfAliasAtPath:(NSString*)path;
-(NSString*)destinationOfAliasOrSymlinkAtPath:(NSString*)path;
-(NSString*)destinationOfAliasOrSymlinkAtPath:(NSString*)path resolved:(BOOL*)r;

-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path limitTo:(NSInteger)maxNumberOfFiles;
-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path filesOnly:(BOOL)filesOnly;
-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path filesOnly:(BOOL)filesOnly recursive:(BOOL)recursive;

@end
