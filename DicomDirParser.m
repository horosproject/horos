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

#import "DicomDirParser.h"

@implementation DicomDirParser

-(void) dealloc
{
	[dirpath release];
	[data release];
	[super dealloc];
}

//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) _testForValidFilePath: (NSMutableArray*) dicomdirFileList path: (NSString*) startDirectory files: (NSMutableArray*) files
{
	NSString				*filePath					= nil;
	NSString				*cutFilePath				= nil;
	NSArray					*fileNames					= nil;
	NSString				*uppercaseFilePath;
	BOOL					isDirectory					= FALSE;
	NSFileManager			*fileManager				= [NSFileManager defaultManager];
	int						i							= 0;
	
	if (startDirectory==Nil || files==Nil) return;
	
	fileNames = [fileManager directoryContentsAtPath: startDirectory];
	for (i = 0; i < [fileNames count] && [files count] < [dicomdirFileList count]; i++)
	{
		filePath = [startDirectory stringByAppendingPathComponent: [fileNames objectAtIndex: i]];
		uppercaseFilePath = [filePath uppercaseString];
		isDirectory = FALSE;
		if ([fileManager fileExistsAtPath:filePath isDirectory: &isDirectory] && !isDirectory)
		{
			// only files with DCM or no extension		
			if ([[uppercaseFilePath pathExtension] isEqualToString: @".DCM"] || [[uppercaseFilePath pathExtension] isEqualToString: @""])
			{
				int			j							= 0;
				BOOL		found						= FALSE;
				
				cutFilePath = [uppercaseFilePath stringByDeletingPathExtension];
				for (j = 0; j < [dicomdirFileList count] && !found; j++)
				{
					if ([cutFilePath isEqualToString: [dicomdirFileList objectAtIndex: j]])
					{
						[files addObject: filePath];
						found = TRUE;
					}
				}
			}
		}
		isDirectory = FALSE;
		if ([fileManager fileExistsAtPath: filePath isDirectory: &isDirectory])
		{
			if (isDirectory)
			{
				[self _testForValidFilePath: dicomdirFileList path: filePath files:files];
			}
		}
	}
}


//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) parseArray:(NSMutableArray*) files
{
	NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	long			i, start, length;
	char			*buffer;
	NSString		*file;
	
	buffer = (char*)  [data UTF8String];
	
	i = 0;
	length = [data length];
	
	while( i < length)
	{
		if( buffer[ i] == '[')
		{
			start = i;
			while( buffer[i] != ']' && i < length)
			{
				if( buffer[i] == '\\') buffer[i] = '/';
				i++;
			}
			
			if( i-start-1 > 0)
			{
				file = [dirpath stringByAppendingString:[NSString stringWithCString: &(buffer[start+1]) length:i-start-1]];
				[result addObject: [[file uppercaseString] stringByDeletingPathExtension]];
			}
		}
		
		i++;
	}
	
	[self _testForValidFilePath: result path: dirpath files: files];	
}

-(id) init:(NSString*) srcFile
{
    NSTask          *aTask;
    NSMutableArray  *theArguments = [NSMutableArray array];
    NSPipe          *newPipe = [NSPipe pipe];
    NSData          *inData = nil;
    NSString        *s = [NSString stringWithString:@""];
    
	dirpath = [[NSString alloc] initWithFormat: @"%@/", [srcFile stringByDeletingLastPathComponent]];
	
    self = [super init];
    
    // create the subprocess
    aTask = [[NSTask alloc] init];
    
    [aTask setStandardOutput:newPipe];
    
    // set the subprocess to start a ping session
    [aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
    [aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmdump"]];
    [theArguments addObject:srcFile];
	
	[theArguments addObject:@"+P"];
	[theArguments addObject:@"0004,1500"];
	
    [aTask setArguments:theArguments];
    
    [aTask launch];
    
    while ([inData=[[newPipe fileHandleForReading] availableData] length]>0 || [aTask isRunning]) 
    {
		s = [s stringByAppendingString:[[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease]];
    }
	
    [aTask waitUntilExit];
	[aTask release];
    aTask = nil;
	
	data = [[NSString alloc] initWithString: s];
	
 return self;
}

@end
