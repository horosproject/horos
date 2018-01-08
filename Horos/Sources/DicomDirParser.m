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

#import "N2Debug.h"
#import "DicomDirParser.h"

static NSString *singeDcmDump = @"singeDcmDump";

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
			NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
			
            @try
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
                                    NSAutoreleasePool *pool3 = [[NSAutoreleasePool alloc] init];
                                    
                                    @try
                                    {
                                        BOOL found = NO;
                                        
                                        if( [dicomdirFileList containsObject: cutFilePath] || [dicomdirFileList containsObject: filePath])
                                        {
                                            [files addObject: filePath];
                                        }
                                        else
                                        {
                                            NSString *cutFilePathWithoutPathExtension = [cutFilePath stringByDeletingPathExtension];
                                            
                                            for( NSString *s in dicomdirFileList)
                                            {
                                                if( [cutFilePathWithoutPathExtension isEqualToString: s])
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
                                        }
                                    }
                                    @catch (...) {
                                    }
                                    @finally {
                                        [pool3 release];
                                    }
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
            @catch (NSException *e) {
                NSLog( @"%@", e);
            }
            @finally {
                [pool2 release];
            }
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	validFilePathDepth--;
}


//————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

- (void) parseArray:(NSMutableArray*) files
{
	NSMutableArray *result = [NSMutableArray array];
	long i, start, length;
	char *buffer;
	
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
				NSString *file = [dirpath stringByAppendingString:[[[NSString alloc] initWithBytes:&(buffer[start+1]) length:i-start-1 encoding:NSUTF8StringEncoding] autorelease]];
				
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
    @synchronized( singeDcmDump)
    {
        NSTask *aTask;
        NSMutableArray *theArguments = [NSMutableArray array];
        NSPipe *newPipe = [NSPipe pipe];
        NSData *inData = nil;
        NSMutableString *s = [NSMutableString stringWithString: @""];
        
        self = [super init];
        
        dirpath = [[NSString alloc] initWithFormat: @"%@/", [srcFile stringByDeletingLastPathComponent]];
        
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
        
        [aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
        [aTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmdump"]];
        [theArguments addObject:srcFile];
        
        [theArguments addObject:@"+L"];
        [theArguments addObject:@"+P"];
        [theArguments addObject:@"0004,1500"];
        
        [aTask setArguments:theArguments];
        
        [aTask launch];
        
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        
#define TIMEOUT 20
        
        @autoreleasepool
        {
            while( [inData = [[newPipe fileHandleForReading] availableData] length] > 0 || [aTask isRunning]) 
            {
                if( inData.length > 0 && inData.length < 2000UL * 1024UL)
                {
                    NSString *r = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
                    if( r)
                    {
                        [s appendString: r];
                        [r release];
                    }
                }
                
                if( [NSDate timeIntervalSinceReferenceDate] - start > TIMEOUT)
                    break;
            }
        }
        
        if( [NSDate timeIntervalSinceReferenceDate] - start > TIMEOUT)
            [aTask interrupt];
        
        //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
        
        [aTask release];
        aTask = nil;
        
        data = [[NSString alloc] initWithString: s];
	}
    
    return self;
}

@end
