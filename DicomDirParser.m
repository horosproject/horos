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

@interface NSString(NumberStuff)
- (BOOL)holdsIntegerValue;
@end

@implementation NSString(NumberStuff)
- (BOOL)holdsIntegerValue
{
    if ([self length] == 0)
        return NO;
    
    NSString *compare = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *validCharacters = [NSCharacterSet decimalDigitCharacterSet];
    for (NSUInteger i = 0; i < [compare length]; i++) 
    {
        unichar oneChar = [compare characterAtIndex:i];
        if (![validCharacters characterIsMember:oneChar])
            return NO;
    }
    return YES;
}
@end

#import "DicomDirParser.h"


//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

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
	NSString *filePath = nil;
	NSString *cutFilePath = nil;
	NSArray *fileNames = nil;
	NSString *uppercaseFilePath;
	BOOL isDirectory = FALSE;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	int i = 0;
	
	if (startDirectory == Nil || files == Nil) return;
	
	fileNames = [fileManager directoryContentsAtPath: startDirectory];
	for (i = 0; i < [fileNames count]; i++)
	{
		filePath = [startDirectory stringByAppendingPathComponent: [fileNames objectAtIndex: i]];
		uppercaseFilePath = [filePath uppercaseString];
		isDirectory = FALSE;
		if ([fileManager fileExistsAtPath:filePath isDirectory: &isDirectory] && !isDirectory)
		{
			@try
			{
				NSString *ext = [uppercaseFilePath pathExtension];
				
				// only files with DCM or no extension, or a number like 82873.9982.9928.22
				if ([ext isEqualToString: @"DCM"] || [ext isEqualToString: @""] || [ext length] > 4 || [ext length] < 3 || [ext holdsIntegerValue] == YES)
				{
					int j = 0;
					
					if( [ext length] <= 4 && [ext length] >= 3 && [ext holdsIntegerValue] == NO)
						cutFilePath = [uppercaseFilePath stringByDeletingPathExtension];
					else
						cutFilePath = uppercaseFilePath;
					
					if( [cutFilePath length] < 2000)
					{
						for( NSString *s in dicomdirFileList)
						{
							if ([cutFilePath isEqualToString: s] || [[cutFilePath stringByDeletingPathExtension] isEqualToString: s] || [filePath isEqualToString: s])
							{
								[files addObject: filePath];
								break;
							}
							
							if( [[s pathExtension] isEqualToString: @""])	/// for this case: 738495.		// GE Scanner
							{
								if( [[cutFilePath stringByDeletingPathExtension] isEqualToString: [s stringByDeletingPathExtension]])
								{
									[files addObject: filePath];
									break;
								}
							}
						}
					}
				}
			}
			@catch (NSException *e)
			{
				NSLog( @"**** _testForValidFilePath exception: %@", e);
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
	NSMutableArray *result = [NSMutableArray array];
	long i, start, length;
	char *buffer;
	NSString *file;
	
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
				
				NSString *ext = [file pathExtension];
				
				if( [ext length] <= 4 && [ext length] >= 3 && [ext holdsIntegerValue] == NO)
					[result addObject: [[file uppercaseString] stringByDeletingPathExtension]];
				else
					[result addObject: [file uppercaseString]];
			}
		}
		
		i++;
	}
	
	[self _testForValidFilePath: result path: dirpath files: files];	
}

-(id) init:(NSString*) srcFile
{
    NSTask *aTask;
    NSMutableArray *theArguments = [NSMutableArray array];
    NSPipe *newPipe = [NSPipe pipe];
    NSData *inData = nil;
    NSString *s = [NSString stringWithString:@""];
    
	dirpath = [[NSString alloc] initWithFormat: @"%@/", [srcFile stringByDeletingLastPathComponent]];
	
    self = [super init];
    
    // create the subprocess
    aTask = [[NSTask alloc] init];
    
    [aTask setStandardOutput:newPipe];
    
    // set the subprocess to start a ping session
    [aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
    [aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmdump"]];
    [theArguments addObject:srcFile];
	
	[theArguments addObject:@"+L"];
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
