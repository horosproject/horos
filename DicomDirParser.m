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




#import "DicomDirParser.h"

NSString * documentsDirectory();

@implementation DicomDirParser

-(void) dealloc
{
	[dirpath release];
	[data release];
	[super dealloc];
}


//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (NSMutableArray*) _testForValidFilePath: (NSMutableArray*) dicomdirFileList path: (NSString*) startDirectory files: (NSMutableArray*) files
{

// (DDP 060112): Can cause an EXC_BAD_ACCESS crash on second recursive call at [... uppercaseString], being investigated.
// Suggests an autoreleased variable... which I've tried to prevent with a retain/release bracket in [browserController addDICOMDIR].

//	NSMutableArray			*correctCaseDicomFileArray	= [NSMutableArray arrayWithCapacity: 100];
	NSString				*filePath					= nil;
	NSString				*cutFilePath				= nil;
	NSArray					*fileNames					= nil;
	NSString				*uppercaseFilePath;
	BOOL					isDirectory					= FALSE;
	NSFileManager			*fileManager				= [NSFileManager defaultManager];
	int						i							= 0;
	
	
	if (startDirectory==Nil || files==Nil)
		return (files);
	
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
					NSString *cutUpperFilePathName = [[[dicomdirFileList objectAtIndex: j] uppercaseString] stringByDeletingPathExtension];
					if ([cutFilePath isEqualToString: cutUpperFilePathName])
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
	return files;
}


//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (NSMutableArray*) parseArray:(NSMutableArray*) files
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:0];
	long			i, start, length;
	char			*buffer;
	BOOL			firstFile = YES, addExtension = NO;
	NSString		*file;
	
	buffer = (char*)  [data cString];
	
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
			
			file = [dirpath stringByAppendingString:[NSString stringWithCString: &(buffer[start+1]) length:i-start-1]];
			
			[result addObject: file];

			

			/*if( firstFile)
			{
				firstFile = NO;
				if( [[NSFileManager defaultManager] fileExistsAtPath:file] == NO) addExtension = YES;
			}
			
			if( addExtension) file = [file stringByAppendingString: @".DCM"];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath:file] == YES) [result addObject: file];*/
		}
		
		i++;
	}
	return [self _testForValidFilePath: result path: dirpath files: files];	
	
	//return result;
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
    [aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
    [aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dcmdump"]];
    [theArguments addObject:srcFile];
	
	[theArguments addObject:@"+P"];
	[theArguments addObject:@"0004,1500"];
	
    [aTask setArguments:theArguments];
    
    [aTask launch];
    
    while ([inData=[[newPipe fileHandleForReading] availableData] length]>0) 
    { 
        s = [s stringByAppendingString:[[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease]];
    }
	
    [aTask interrupt];
	[aTask release];
    aTask = nil;
	
	data = [[NSString alloc] initWithString: s];
	
 return self;
}

@end
