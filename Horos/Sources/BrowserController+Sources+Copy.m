/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "BrowserController+Sources+Copy.h"
#import "DicomImage.h"
#import "DicomFile.h"
#import "DicomDatabase.h"
#import "DataNodeIdentifier.h"
#import "DCMNetServiceDelegate.h"
#import "MutableArrayCategory.h"
#import "ThreadsManager.h"
#import "RemoteDicomDatabase.h"
#import "NSThread+N2.h"
#import "N2Debug.h"
#import "N2Stuff.h"

@implementation BrowserController (SourcesCopy)

-(void)copyImagesToLocalBrowserSourceThread:(NSArray*)io
{
    @autoreleasepool
    {
        if( io.count < 4)
        {
            NSLog( @"******* copyImagesToLocalBrowserSourceThread : io.count < 4");
            return;
        }
        
        @try
        {
            NSThread* thread = [NSThread currentThread];
            
            DicomDatabase *srcDatabase = [io objectAtIndex:2];
            NSArray* dicomImages = [srcDatabase.independentDatabase objectsWithIDs: [io objectAtIndex: 0]];
            
            NSMutableArray* imagePaths = [NSMutableArray array];
            for (DicomImage* image in dicomImages)
                if (![imagePaths containsObject:image.completePath])
                    [imagePaths addObject:image.completePath];
            
            thread.status = NSLocalizedString(@"Opening database...", nil);
            DicomDatabase* dstDatabase = [[io objectAtIndex:3] independentDatabase];
            
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Copying %@ %@...", nil), N2LocalizedDecimal( imagePaths.count), (imagePaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
            NSMutableArray* dstPaths = [NSMutableArray array];
            
            NSTimeInterval fiveSeconds = [NSDate timeIntervalSinceReferenceDate] + 5;
            NSTimeInterval oneSecond = [NSDate timeIntervalSinceReferenceDate] + 1;
            
            for (NSInteger i = 0; i < imagePaths.count; ++i)
            {
                thread.progress = 1.0*i/imagePaths.count;
                
                if (thread.isCancelled)
                    break;
                
                NSString* srcPath = [imagePaths objectAtIndex:i];
                NSString* dstPath = [dstDatabase uniquePathForNewDataFileWithExtension: @"dcm"];
                
                if( dstPath.length)
                {
                    static NSString *oneCopyAtATime = @"oneCopyAtATime";
                    @synchronized( oneCopyAtATime)
                    {
                        if( srcDatabase.isReadOnly)
                        {
                            NSTask *t = [NSTask launchedTaskWithLaunchPath: @"/bin/cp" arguments: @[srcPath, dstPath]];
                            while( [t isRunning]){};
                        }
                        else if( [[NSFileManager defaultManager] copyItemAtPath: srcPath toPath: dstPath error: nil] == NO)
                            NSLog( @"**** copyItemAtPath failed: %@", dstPath);

                        if( [[NSFileManager defaultManager] fileExistsAtPath: dstPath])
                        {
                            if( [DicomFile isDICOMFile: dstPath] == NO)
                                [[NSFileManager defaultManager] moveItemAtPath: dstPath toPath: [[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension: [srcPath pathExtension]] error: nil];
                            
                            [dstPaths addObject:dstPath];
                        }
                    }
                }
                
                if( fiveSeconds < [NSDate timeIntervalSinceReferenceDate])
                {
                    thread.status = [NSString stringWithFormat:NSLocalizedString(@"Indexing %@ %@...", nil), N2LocalizedDecimal( dstPaths.count), (dstPaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil))];
                    
                    [dstDatabase addFilesAtPaths: dstPaths postNotifications: YES dicomOnly: [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDICOM"] rereadExistingItems:NO  generatedByOsiriX: NO importedFiles: YES returnArray: NO];
                    
                    [dstPaths removeAllObjects];
                    
                    fiveSeconds = [NSDate timeIntervalSinceReferenceDate] + 5;
                }
                
                if( oneSecond < [NSDate timeIntervalSinceReferenceDate])
                {
                    thread.status = [NSString stringWithFormat:NSLocalizedString(@"Copying %@ %@...", nil), N2LocalizedDecimal( (long)imagePaths.count-i), ((long)imagePaths.count-i == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil))];
                    
                    oneSecond = [NSDate timeIntervalSinceReferenceDate] + 1;
                }
            }
            
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Indexing %@ %@...", nil), N2LocalizedDecimal( dstPaths.count), (dstPaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil))];
            thread.progress = -1;
            [dstDatabase addFilesAtPaths:dstPaths];
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
	}
}

-(void)copyImagesToRemoteBrowserSourceThread:(NSArray*)io
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
    
	DataNodeIdentifier* destination = [io objectAtIndex:1];
	DicomDatabase *srcDatabase = [io objectAtIndex:2];
    NSArray* dicomImages = [srcDatabase.independentDatabase objectsWithIDs: [io objectAtIndex: 0]];
    
	NSMutableArray* imagePaths = [NSMutableArray array];
	NSMutableArray* imagePathsObjs = [NSMutableArray array];
	for (DicomImage* image in dicomImages)
		if (![imagePaths containsObject:image.completePath]) {
			[imagePaths addObject:image.completePath];
            [imagePathsObjs addObject:image];
        }
	
	thread.status = NSLocalizedString(@"Opening database...", nil);
    
    @try
    {
        RemoteDicomDatabase* dstDatabase = [RemoteDicomDatabase databaseForLocation:destination.location port:destination.port name:destination.description update:NO];
        
        thread.status = [NSString stringWithFormat:NSLocalizedString(@"Sending %@ %@...", nil), N2LocalizedDecimal( imagePaths.count), (imagePaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
        
        
        [dstDatabase uploadFilesAtPaths:imagePaths imageObjects:nil];
    }
    @catch (NSException* e)
    {
        thread.status = NSLocalizedString(@"Error: destination is unavailable", nil);
        N2LogExceptionWithStackTrace(e);
        [NSThread sleepForTimeInterval:1];
    }
    
	[pool release];
}

-(void)copyRemoteImagesToLocalBrowserSourceThread:(NSArray*)io
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
    
    DataNodeIdentifier* destination = [io objectAtIndex:1];
	RemoteDicomDatabase* srcDatabase = [io objectAtIndex:2];
    NSMutableArray* dicomImages = [[[srcDatabase.independentDatabase objectsWithIDs: [io objectAtIndex: 0]] mutableCopy] autorelease];
    
	NSMutableArray* imagePaths = [[[dicomImages valueForKey:@"completePath"] mutableCopy] autorelease];
	[imagePaths removeDuplicatedStringsInSyncWithThisArray:dicomImages];
	
	thread.status = NSLocalizedString(@"Opening database...", nil);
    
	DicomDatabase* idatabase = [[DicomDatabase databaseAtPath:destination.location name:destination.description] independentDatabase];
	
	thread.status = [NSString stringWithFormat:NSLocalizedString(@"Fetching %@ %@...", nil), N2LocalizedDecimal( dicomImages.count), (dicomImages.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
	NSMutableArray* dstPaths = [NSMutableArray array];
	for (NSInteger i = 0; i < dicomImages.count; ++i)
    {
        @try
        {
            DicomImage* dicomImage = [dicomImages objectAtIndex:i];
            NSString* srcPath = [srcDatabase cacheDataForImage:dicomImage maxFiles:0];
            
            if (srcPath)
            {
                NSString* ext = [DicomFile isDICOMFile:srcPath]? @"dcm" : srcPath.pathExtension;
                NSString* dstPath = [idatabase uniquePathForNewDataFileWithExtension:ext];
                
                if( dstPath.length)
                    if ([[NSFileManager defaultManager] moveItemAtPath:srcPath toPath:dstPath error:NULL])
                        [dstPaths addObject:dstPath];
            }
        }
        @catch (NSException *exception)
        {
            N2LogExceptionWithStackTrace( exception);
        }
		thread.progress = 1.0*i/dicomImages.count;
		
        if (thread.isCancelled)
            break;
	}
	
	thread.status = NSLocalizedString(@"Indexing files...", nil);
	thread.progress = -1;
	[idatabase addFilesAtPaths:dstPaths];
	
	[pool release];
}

-(void)copyRemoteImagesToRemoteBrowserSourceThread:(NSArray*)io
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
    
	DataNodeIdentifier* destination = [io objectAtIndex:1];
    RemoteDicomDatabase* srcDatabase = [io objectAtIndex:2];
    NSMutableArray* dicomImages = [[[srcDatabase.independentDatabase objectsWithIDs: [io objectAtIndex: 0]] mutableCopy] autorelease];
	
	NSMutableArray* imagePaths = [[[dicomImages valueForKey:@"completePath"] mutableCopy] autorelease];
	[imagePaths removeDuplicatedStringsInSyncWithThisArray:dicomImages];
	
	NSString* dstAddress = nil;
	NSString* dstAET = nil;
	NSInteger dstPort = 0;
	NSInteger dstSyntax = 0;
	if ([destination isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
    {
		[RemoteDatabaseNodeIdentifier location:destination.location port:destination.port toAddress:&dstAddress port:NULL];
		dstPort = [[destination.dictionary objectForKey:@"port"] integerValue];
		dstAET = [destination.dictionary objectForKey:@"AETitle"];
		if (!dstAET || !dstPort || !dstSyntax)
        {
			thread.status = NSLocalizedString(@"Fetching destination information...", nil);
            NSDictionary* dstInfo = nil;
            @try
            {
                RemoteDicomDatabase* dstDatabase = [RemoteDicomDatabase databaseForLocation:destination.location port:destination.port name:destination.description update:NO];
                
                dstInfo = [dstDatabase fetchDicomDestinationInfo];
            } @catch (NSException* e)
            {
                thread.status = NSLocalizedString(@"Error: destination is unavailable", nil);
                N2LogExceptionWithStackTrace(e);
                [NSThread sleepForTimeInterval:1];
            }
			if ([dstInfo objectForKey:@"AETitle"]) dstAET = [dstInfo objectForKey:@"AETitle"];
			if ([dstInfo objectForKey:@"Port"]) dstPort = [[dstInfo objectForKey:@"Port"] integerValue];
			if ([dstInfo objectForKey:@"TransferSyntax"]) dstSyntax = [[dstInfo objectForKey:@"TransferSyntax"] integerValue];
		}
	} else if ([destination isKindOfClass:[DicomNodeIdentifier class]])
    {
		[DicomNodeIdentifier location:destination.location port:destination.port toAddress:&dstAddress port:&dstPort aet:&dstAET];
		dstSyntax = [[destination.dictionary objectForKey:@"TransferSyntax"] integerValue];
	}

	thread.status = [NSString stringWithFormat:NSLocalizedString(@"Sending SCU request...", nil), dicomImages.count];
	[srcDatabase storeScuImages:dicomImages toDestinationAETitle:dstAET address:dstAddress port:dstPort transferSyntax:dstSyntax];

	[pool release];
}

-(BOOL)initiateCopyImages:(NSArray*)dicomImages toSource:(DataNodeIdentifier*)destination
{
	if (_database.isLocal)
    {
		if ([destination isKindOfClass:[LocalDatabaseNodeIdentifier class]]) { // local Horos to local Horos
            
            DicomDatabase *dst = [DicomDatabase databaseAtPath:destination.location]; // Create the mainDatabase on the MAIN thread, if necessary !
            
            NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyImagesToLocalBrowserSourceThread:) object:[NSArray arrayWithObjects: [dicomImages valueForKey:@"objectID"], destination, _database, dst, NULL]] autorelease];
            thread.name = NSLocalizedString(@"Copying images...", nil);
            thread.supportsCancel = YES;
            [[ThreadsManager defaultManager] addThreadAndStart:thread];
            return YES;
        } else if ([destination isKindOfClass:[RemoteDatabaseNodeIdentifier class]]) { // local Horos to remote Horos
            NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyImagesToRemoteBrowserSourceThread:) object:[NSArray arrayWithObjects: [dicomImages valueForKey:@"objectID"], destination, _database, NULL]] autorelease];
            thread.supportsCancel = YES;
            thread.name = NSLocalizedString(@"Sending images...", nil);
            [[ThreadsManager defaultManager] addThreadAndStart:thread];
            return YES;
        } else if ([destination isKindOfClass:[DicomNodeIdentifier class]]) { // local Horos to remote DICOM
            NSArray* r = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
            for (int i = 0; i < r.count; ++i)
                if ([destination isEqualToDictionary:[r objectAtIndex:i]])
                    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:@"lastSendServer"];
            [self selectServer:dicomImages];
            return YES;
            // [_database storeScuImages:dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax];
		}
	}
    else
    {
		if ([destination isKindOfClass:[LocalDatabaseNodeIdentifier class]])
        { // remote Horos to local Horos
            
            [DicomDatabase databaseAtPath:destination.location]; // Create the mainDatabase on the MAIN thread, if necessary !
            
            NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyRemoteImagesToLocalBrowserSourceThread:) object:[NSArray arrayWithObjects: [dicomImages valueForKey:@"objectID"], destination, _database, NULL]] autorelease];
            thread.name = NSLocalizedString(@"Copying images...", nil);
            thread.supportsCancel = YES;
            [[ThreadsManager defaultManager] addThreadAndStart:thread];
            return YES;
		} else if ([destination isKindOfClass:[RemoteDatabaseNodeIdentifier class]] || [destination isKindOfClass:[DicomNodeIdentifier class]]) { // remote Horos to remote Horos // remote Horos to remote DICOM
				NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyRemoteImagesToRemoteBrowserSourceThread:) object:[NSArray arrayWithObjects: [dicomImages valueForKey:@"objectID"], destination, _database, NULL]] autorelease];
				thread.name = NSLocalizedString(@"Initiating image transfer...", nil);
                thread.supportsCancel = YES;
				[[ThreadsManager defaultManager] addThreadAndStart:thread];
				return YES;
		}
	}
	
	return NO;
}

@end
