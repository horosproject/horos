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

extern int maindcmdump(int argc, char *argv[]);

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

static int validFilePathDepth = 0;

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
	if( startDirectory == Nil || files == Nil) return;
	if( [startDirectory isEqualToString: @""] || [startDirectory isEqualToString: @"/"]) return;
	validFilePathDepth++;
	
	@try 
	{
		for( NSString *filePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: startDirectory error: nil])
		{
			filePath = [startDirectory stringByAppendingPathComponent: filePath];
			
			NSString *uppercaseFilePath = [filePath uppercaseString];
			
			BOOL isDirectory = NO;
			if( [[NSFileManager defaultManager] fileExistsAtPath: filePath isDirectory: &isDirectory])
			{
				if( isDirectory == NO)
				{
					@try
					{
						NSString *ext = [uppercaseFilePath pathExtension];
						
						// only files with DCM or no extension, or a number like 82873.9982.9928.22
						if ([ext isEqualToString: @"DCM"] || [ext isEqualToString: @""] || [ext length] > 4 || [ext length] < 3 || [ext holdsIntegerValue] == YES)
						{
							NSString *cutFilePath = nil;
							
							if( [ext length] <= 4 && [ext length] >= 3 && [ext holdsIntegerValue] == NO)
								cutFilePath = [uppercaseFilePath stringByDeletingPathExtension];
							else
								cutFilePath = uppercaseFilePath;
							
							if( [cutFilePath length] < 2000)
							{
								BOOL found = NO;
								
								for( NSString *s in dicomdirFileList)
								{
									if ([cutFilePath isEqualToString: s] || [[cutFilePath stringByDeletingPathExtension] isEqualToString: s] || [filePath isEqualToString: s])
									{
										[files addObject: filePath];
										found = YES;
										break;
									}
									
									if( [[s pathExtension] isEqualToString: @""])	/// for this case: 738495.		// GE Scanner
									{
										if( [[cutFilePath stringByDeletingPathExtension] isEqualToString: [s stringByDeletingPathExtension]])
										{
											[files addObject: filePath];
											found = YES;
											break;
										}
									}
								}
								
//								if( found == NO)
//									NSLog( @"--- Not found in DICOMDIR: %@", cutFilePath);
							}
						}
					}
					@catch (NSException *e)
					{
						NSLog( @"**** _testForValidFilePath exception: %@", e);
					}
				}
				else if( validFilePathDepth < 8)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					[self _testForValidFilePath: dicomdirFileList path: filePath files:files];
				
					[pool release];
				}
			}
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	validFilePathDepth--;
}


//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) parseArray:(NSMutableArray*) files
{
	NSMutableArray *result = [NSMutableArray array];
	long i, start, length;
	char *buffer;
	NSString *file;
	
	buffer = (char*) [data UTF8String];
	
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
	
	validFilePathDepth = 0;
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
    
//	const char *args[ 4];
//	
//	args[ 0] = [srcFile UTF8String];
//	args[ 1] = "+L";
//	args[ 2] = "+P";
//	args[ 3] = "0004,1500";
//	
//	FILE *fp;
//	
//	if((fp=freopen("/tmp/out.txt", "w", stdout))==NULL)
//	{
//		printf("Cannot open file.\n");
//	}
//	
//	maindcmdump(4, (char**) args);
//	
//	fclose(fp);
//	
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
