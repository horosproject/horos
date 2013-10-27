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

#import "Reports.h"
#import "DicomFile.h"
#import "OsiriX/DCM.h"
#import "BrowserController.h"
#import "NSString+N2.h"
#import "NSFileManager+N2.h"
#import "NSAppleScript+N2.h"

// if you want check point log info, define CHECK to the next line, uncommented:
#define CHECK NSLog(@"Applescript result code = %d", ok);

// This converts an AEDesc into a corresponding NSValue.

static id aedesc_to_id(AEDesc *desc)
{
	OSErr ok;

	if (desc->descriptorType == typeChar)
	{
		NSMutableData *outBytes;
		NSString *txt;

		outBytes = [[NSMutableData alloc] initWithLength:AEGetDescDataSize(desc)];
		ok = AEGetDescData(desc, [outBytes mutableBytes], [outBytes length]);
		CHECK;

		txt = [[NSString alloc] initWithData:outBytes encoding: NSUTF8StringEncoding];
		[outBytes release];
		[txt autorelease];

		return txt;
	}

	if (desc->descriptorType == typeSInt16)
	{
		SInt16 buf;
		AEGetDescData(desc, &buf, sizeof(buf));
		return [NSNumber numberWithShort:buf];
	}

	return [NSString stringWithFormat:@"[unconverted AEDesc, type=\"%c%c%c%c\"]", ((char *)&(desc->descriptorType))[0], ((char *)&(desc->descriptorType))[1], ((char *)&(desc->descriptorType))[2], ((char *)&(desc->descriptorType))[3]];
}

@interface Reports ()

- (void)runScript:(NSString*)txt;
- (BOOL)createNewWordReportForStudy:(NSManagedObject*)study toDestinationPath:(NSString*)destinationFile;

@end

@implementation Reports

+ (NSString*) getUniqueFilename:(id) study
{
	NSString *s = [study valueForKey:@"accessionNumber"];
	
	if( [s length] > 0)
		return [DicomFile NSreplaceBadCharacter: [[study valueForKey:@"patientUID"] stringByAppendingFormat:@"-%@", [study valueForKey:@"accessionNumber"]]];
	else
		return [DicomFile NSreplaceBadCharacter: [[study valueForKey:@"patientUID"] stringByAppendingFormat:@"-%@", [study valueForKey:@"studyInstanceUID"]]];
}

+ (NSString*) getOldUniqueFilename:(NSManagedObject*) study
{
	return [DicomFile NSreplaceBadCharacter: [[study valueForKey:@"patientUID"] stringByAppendingFormat:@"-%@", [study valueForKey:@"id"]]];
}



- (NSString *) HFSStyle: (NSString*) string
{
	return [[(NSURL *)CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)string, kCFURLHFSPathStyle, NO) autorelease] path];
}

- (NSString *) HFSPathFromPOSIXPath: (NSString*) p
{
    // thanks to stone.com for the pointer to  CFURLCreateWithFileSystemPath()

    CFURLRef    url;
    CFStringRef hfsPath = NULL;

    BOOL        isDirectoryPath = [p hasSuffix:@"/"];
    // Note that for the usual case of absolute paths,  isDirectoryPath is
    // completely ignored by CFURLCreateWithFileSystemPath.
    // isDirectoryPath is only considered for relative paths.
    // This code has not really been tested relative paths...

    url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                          (CFStringRef)p,
                                          kCFURLPOSIXPathStyle,
                                          isDirectoryPath);
    if (NULL != url) {

        // Convert URL to a colon-delimited HFS path
        // represented as Unicode characters in an NSString.

        hfsPath = CFURLCopyFileSystemPath(url, kCFURLHFSPathStyle);
        if (NULL != hfsPath) {
            [(NSString *)hfsPath autorelease];
        }
        CFRelease(url);
    }

    return (NSString *) hfsPath;
}

- (BOOL) createNewReport:(NSManagedObject*) study destination:(NSString*) path type:(int) type
{	
	NSString *uniqueFilename = [Reports getUniqueFilename: study];
	
	switch( type)
	{
		case 0:
		{
			NSString *destinationFile = [NSString stringWithFormat:@"%@%@.%@", path, uniqueFilename, @"doc"];
			[[NSFileManager defaultManager] removeItemAtPath: destinationFile error: nil];
			
            [self createNewWordReportForStudy:study toDestinationPath:destinationFile];
        }
		break;
		
		case 1:
		{
			NSString *destinationFile = [NSString stringWithFormat:@"%@%@.%@", path, uniqueFilename, @"rtf"];
			[[NSFileManager defaultManager] removeItemAtPath: destinationFile error: nil];
			
			[[NSFileManager defaultManager] copyPath:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/ReportTemplate.rtf"] toPath:destinationFile handler: nil];
			
			NSDictionary                *attr;
			NSMutableAttributedString	*rtf = [[NSMutableAttributedString alloc] initWithRTF: [NSData dataWithContentsOfFile:destinationFile] documentAttributes:&attr];
			NSString					*rtfString = [rtf string];
			NSRange						range;
			
			// SCAN FIELDS
			
			NSManagedObjectModel	*model = [[[study managedObjectContext] persistentStoreCoordinator] managedObjectModel];
			NSArray *properties = [[[[model entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
			
			
			NSDateFormatter		*date = [[[NSDateFormatter alloc] init] autorelease];
			[date setDateStyle: NSDateFormatterShortStyle];
			
			for( NSString *name in properties)
			{
				NSString	*string;
				
				if( [[study valueForKey: name] isKindOfClass: [NSDate class]])
				{
					string = [date stringFromDate: [study valueForKey: name]];
				}
				else string = [[study valueForKey: name] description];
				
				NSRange	searchRange = rtf.range;
				
				do
				{
					range = [rtfString rangeOfString: [NSString stringWithFormat:@"«%@»", name] options:0 range:searchRange];
					
					if( range.length > 0)
					{
						if( string)
						{
							[rtf replaceCharactersInRange:range withString:string];
						}
						else [rtf replaceCharactersInRange:range withString:@""];
						
						searchRange = NSMakeRange( range.location, [rtf length]-(range.location+1));
					}
				}while( range.length != 0);
			}
			
			// TODAY
			
			NSRange	searchRange = rtf.range;
			
			range = [rtfString rangeOfString: @"«today»" options:0 range: searchRange];
			if( range.length > 0)
			{
				[rtf replaceCharactersInRange:range withString:[date stringFromDate: [NSDate date]]];
			}
			
			// DICOM Fields
			NSArray	*seriesArray = [[BrowserController currentBrowser] childrenArray: study];
			if( [seriesArray count] > 0)
			{
				NSArray	*imagePathsArray = [[BrowserController currentBrowser] imagesPathArray: [seriesArray objectAtIndex: 0]];
				BOOL moreFields = NO;
				do
				{
					NSRange firstChar = [rtfString rangeOfString: @"«DICOM_FIELD:"];
					if( firstChar.location != NSNotFound)
					{
						NSRange secondChar = [rtfString rangeOfString: @"»"];
						
						if( secondChar.location != NSNotFound)
						{
							NSString	*dicomField = [rtfString substringWithRange: NSMakeRange( firstChar.location+firstChar.length, secondChar.location - (firstChar.location+firstChar.length))];
							
							
							NSLog( @"%@", dicomField);
							
							DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [imagePathsArray objectAtIndex: 0] decodingPixelData:NO];
							if (dcmObject)
							{
								if( [dcmObject attributeValueWithName: dicomField])
								{
									[rtf replaceCharactersInRange:NSMakeRange(firstChar.location, secondChar.location-firstChar.location+1)  withString: [dcmObject attributeValueWithName: dicomField]];
								}
								else
								{
									NSLog( @"**** Dicom field not found: %@ in %@", dicomField, [imagePathsArray objectAtIndex: 0]);
									[rtf replaceCharactersInRange:NSMakeRange(firstChar.location, secondChar.location-firstChar.location+1)  withString:@""];
								}
							}
							moreFields = YES;
						}
						else moreFields = NO;
					}
					else moreFields = NO;
				}
				while( moreFields);
			}
			
			[[rtf RTFFromRange:rtf.range documentAttributes:attr] writeToFile:destinationFile atomically:YES];
			
			[rtf release];
			[study setValue: destinationFile forKey:@"reportURL"];
			
			[[NSWorkspace sharedWorkspace] openFile:destinationFile withApplication:@"TextEdit" andDeactivate: YES];
			[NSThread sleepForTimeInterval: 1];
		}
		break;
		
		case 2:
		{
			NSString *destinationFile = [NSString stringWithFormat:@"%@%@.%@", path, uniqueFilename, @"pages"];
			[[NSFileManager defaultManager] removeItemAtPath: destinationFile error: nil];
			
			[self createNewPagesReportForStudy:study toDestinationPath:destinationFile];
		}
		break;
		
		case 5:
		{
			NSString *destinationFile = [NSString stringWithFormat:@"%@%@.%@", path, uniqueFilename, @"odt"];
			[[NSFileManager defaultManager] removeItemAtPath: destinationFile error: nil];
			
			[[NSFileManager defaultManager] copyPath:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/ReportTemplate.odt"] toPath:destinationFile handler: nil];
			[self createNewOpenDocumentReportForStudy:study toDestinationPath:destinationFile];
			
		}
		break;
	}
	return YES;
}

// initialize it in your init method:

- (void) dealloc
{
	[templateName release];
	
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self)
	{
		templateName = [[NSMutableString stringWithString:@"OsiriX Basic Report"] retain];
	}
	return self;
}

// do the grunge work -

// the sweetly wrapped method is all we need to know:

- (void)runScript:(NSString *)txt
{
    NSAppleScript* as = [[[NSAppleScript alloc] initWithSource:txt] autorelease];
    NSDictionary* errs = nil;
    [as runWithArguments:nil error:&errs];
    if ([errs count])
        NSLog(@"Error: AppleScript execution failed: %@", errs);
}

+(id)_runAppleScript:(NSString*)source withArguments:(NSArray*)args
{
    NSError* err = nil;
    NSDictionary* errs = nil;
    
    if (!source) [NSException raise:NSGenericException format:@"Couldn't read script source"];
    
    NSAppleScript* script = [[[NSAppleScript alloc] initWithSource:source] autorelease];
    if (!script) [NSException raise:NSGenericException format:@"Invalid script source"];
    
    id r = [script runWithArguments:args error:&errs];
    if (errs) [NSException raise:NSGenericException format:@"%@", errs];
    
    return r;
}

#pragma mark -

- (void)searchAndReplaceFieldsFromStudy:(NSManagedObject*)aStudy inString:(NSMutableString*)aString;
{
	if( aString == nil)
		return;
		
	NSManagedObjectModel *model = [[[aStudy managedObjectContext] persistentStoreCoordinator] managedObjectModel];
	NSArray *properties = [[[[model entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
	
	NSDateFormatter		*date = [[[NSDateFormatter alloc] init] autorelease];
	[date setDateStyle: NSDateFormatterShortStyle];
    
    NSDateFormatter		*longDate = [[[NSDateFormatter alloc] init] autorelease];
	[longDate setDateStyle: NSDateFormatterLongStyle];
	
	for( NSString *propertyName in properties)
	{
		NSString *propertyValue;
		
		if( [[aStudy valueForKey:propertyName] isKindOfClass:[NSDate class]])
			propertyValue = [date stringFromDate: [aStudy valueForKey:propertyName]];
		else
			propertyValue = [[aStudy valueForKey:propertyName] description];
			
		if(!propertyValue)
			propertyValue = @"";
			
		//		« is encoded as &#xAB;
		//      » is encoded as &#xBB;
		[aString replaceOccurrencesOfString:[NSString stringWithFormat:@"&#xAB;%@&#xBB;", propertyName] withString:propertyValue options:NSLiteralSearch range:aString.range];
		[aString replaceOccurrencesOfString:[NSString stringWithFormat:@"«%@»", propertyName] withString:propertyValue options:NSLiteralSearch range:aString.range];
	}
	
	// "today"
	[aString replaceOccurrencesOfString:@"&#xAB;today&#xBB;" withString:[date stringFromDate: [NSDate date]] options:NSLiteralSearch range:aString.range];
	[aString replaceOccurrencesOfString:@"«today»" withString:[date stringFromDate: [NSDate date]] options:NSLiteralSearch range:aString.range];
    
    [aString replaceOccurrencesOfString:@"&#xAB;longtoday&#xBB;" withString:[longDate stringFromDate: [NSDate date]] options:NSLiteralSearch range:aString.range];
	[aString replaceOccurrencesOfString:@"«longtoday»" withString:[longDate stringFromDate: [NSDate date]] options:NSLiteralSearch range:aString.range];
	
	NSArray	*seriesArray = [[BrowserController currentBrowser] childrenArray: aStudy];
	NSArray	*imagePathsArray = [[BrowserController currentBrowser] imagesPathArray: [seriesArray objectAtIndex: 0]];
	
	// DICOM Fields
	BOOL moreFields = NO;
	do
	{
		NSRange firstChar = [aString rangeOfString: @"&#xAB;DICOM_FIELD:"];
		
		if( firstChar.location == NSNotFound)
			firstChar = [aString rangeOfString: @"«DICOM_FIELD:"];
		
		if( firstChar.location != NSNotFound)
		{
			NSRange secondChar = [aString rangeOfString: @"&#xBB;" options: 0 range: NSMakeRange( firstChar.location+firstChar.length, aString.length - (firstChar.location+firstChar.length)) locale: nil];
			if( secondChar.location == NSNotFound)
				secondChar = [aString rangeOfString: @"»"];
			
			if( secondChar.location != NSNotFound)
			{
				NSString *dicomField = [aString substringWithRange: NSMakeRange( firstChar.location+firstChar.length, secondChar.location - (firstChar.location+firstChar.length))];
				
                if( dicomField.length) // delete the <blabla> strings
                {
                    dicomField = [dicomField stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    NSRange sChar;
                    do
                    {
                        sChar = [dicomField rangeOfString: @"<"];
                        if( sChar.location != NSNotFound)
                        {
                            NSRange sChar2 = [dicomField rangeOfString: @">"];
                            
                            if( sChar2.location != NSNotFound)
                                dicomField = [dicomField stringByReplacingCharactersInRange:NSMakeRange( sChar.location, sChar2.location + sChar2.length - sChar.location) withString:@""];
                        }
                    }
                    while( sChar.location != NSNotFound);
				}
                
				NSLog( @"Report: DICOM_Field: %@", dicomField);
				
				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [imagePathsArray objectAtIndex: 0] decodingPixelData:NO];
				if (dcmObject)
				{
					if( [dcmObject attributeValueWithName: dicomField])
					{
						[aString replaceCharactersInRange:NSMakeRange(firstChar.location, secondChar.location-firstChar.location+secondChar.length)  withString: [dcmObject attributeValueWithName: dicomField]];
					}
					else
					{
						NSLog( @"**** Dicom field not found: %@ in %@", dicomField, [imagePathsArray objectAtIndex: 0]);
						[aString replaceCharactersInRange:NSMakeRange(firstChar.location, secondChar.location-firstChar.location+secondChar.length)  withString:@""];
					}
				}
				else
					{
						NSLog( @"**** Dicom field not found: %@ in %@", dicomField, [imagePathsArray objectAtIndex: 0]);
						[aString replaceCharactersInRange:NSMakeRange(firstChar.location, secondChar.location-firstChar.location+secondChar.length)  withString:@""];
					}
				moreFields = YES;
			}
			else moreFields = NO;
		}
		else moreFields = NO;
	}
	while( moreFields);
}

#pragma mark -
#pragma mark Word

+(NSString*)msofficeApplicationSupportDirPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Microsoft/Office"];
}

+(NSArray*)msofficeApplicationSupportTemplateSubpaths {
    return [NSArray arrayWithObjects:
            @"User Templates/My Templates/OsiriX", // English
            // @"//OsiriX" // Chinese (Simplified)
            // @"//OsiriX" // Chinese (Traditional)
            // @"//OsiriX" // Danish
            // @"//OsiriX" // Dutch
            // @"//OsiriX" // Finnish
            @"Modèles utilisateur/Mes modèles/OsiriX", // French
            @"Benutzervorlagen/Meine Vorlagen/OsiriX", // German
            // @"Modelli utente//OsiriX", // Italian
            // @"//OsiriX" // Japanese
            // @"/Mine maler/OsiriX" // Norwegian (Bokmål)
            // @"//OsiriX" // Polish
            // @"//OsiriX" // Russian
            // @"//OsiriX" // Spanish
            // @"//OsiriX" // Swedish 
            nil];
}

+(NSString*)wordTemplatesOsirixDirPath {
    return [[self msofficeApplicationSupportDirPath] stringByAppendingPathComponent:[[self msofficeApplicationSupportTemplateSubpaths] objectAtIndex:0]];
}

+(NSString*)databaseWordTemplatesDirPath {
    return [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"WORD TEMPLATES"];
}

+(NSString*)databasePagesTemplatesDirPath {
    return [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"PAGES TEMPLATES"];
}

+(NSString*)resolvedDatabaseWordTemplatesDirPath {
    return [[NSFileManager defaultManager] destinationOfAliasOrSymlinkAtPath:[self databaseWordTemplatesDirPath]];
}

+ (NSMutableArray*)wordTemplatesList
{
	NSMutableArray* templatesArray = [NSMutableArray array];
    
	NSDirectoryEnumerator* directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[self resolvedDatabaseWordTemplatesDirPath]];
	NSString* filename;
	while ((filename = [directoryEnumerator nextObject]))
	{
		[directoryEnumerator skipDescendents];
		if ([filename hasPrefix:@"OsiriX "]) // this is a template for us (we should maybe verify that it is a valid Word template... but what ever...)
			[templatesArray addObject:[filename substringFromIndex:7]];
	}
	
	return templatesArray;
}

- (NSString*) generateWordReportMergeDataForStudy:(NSManagedObject*) study
{
	long x;
	
	NSManagedObjectModel	*model = [[[study managedObjectContext] persistentStoreCoordinator] managedObjectModel];
    
	NSArray *properties = [[[[model entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
	
	NSMutableString	*file = [NSMutableString stringWithString:@""];
	
	for( x = 0; x < [properties count]; x++)
	{
		NSString	*name = [properties objectAtIndex: x];
		[file appendString:name];
		[file appendFormat: @"%c", NSTabCharacter];
	}
	
	[file appendString:@"\r"];
	
	NSDateFormatter		*date = [[[NSDateFormatter alloc] init] autorelease];
	[date setDateStyle: NSDateFormatterShortStyle];
	
	for( x = 0; x < [properties count]; x++)
	{
		NSString	*name = [properties objectAtIndex: x];
		NSString	*string;
		
		if( [[study valueForKey: name] isKindOfClass: [NSDate class]])
		{
			string = [date stringFromDate: [study valueForKey: name]];
		}
		else string = [[study valueForKey: name] description];
		
		if( string)
			[file appendString: [DicomFile NSreplaceBadCharacter:string]];
		else
			[file appendString: @""];
		
		[file appendFormat: @"%c", NSTabCharacter];
	}
	
	NSString	*path = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/Report.rtf"];
	
	[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	
	NSMutableAttributedString	*rtf = [[[NSMutableAttributedString alloc] initWithString: file] autorelease];
	
	[[rtf RTFFromRange:rtf.range documentAttributes: nil] writeToFile: path atomically:YES]; // To support full encoding in MicroSoft Word
	
	return path;
}

- (BOOL)createNewWordReportForStudy:(NSManagedObject*)study toDestinationPath:(NSString*)destinationFile
{
    // Applescript doesnt support UTF-8 encoding
    
//    NSString* tempPath = [[[destinationFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MSTempReport"] stringByAppendingPathExtension:[destinationFile pathExtension]];
  //  [[NSFileManager defaultManager] removeItemAtPath: tempPath error: nil];
    
    [[NSFileManager defaultManager] removeItemAtPath:destinationFile error: nil];
    
    NSString* inTemplateName = templateName;
    NSString* sourceData = [self generateWordReportMergeDataForStudy:study];
    NSString* templatePath = nil;
    
    NSString* templatesDirPath = [[self class] resolvedDatabaseWordTemplatesDirPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:templatesDirPath]) {
        NSMutableArray* templatesDirPathContents = [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:templatesDirPath error:NULL] mutableCopy] autorelease];
        for (NSInteger i = (long)templatesDirPathContents.count-1; i >= 0; --i)
            if (![[templatesDirPathContents objectAtIndex:i] hasPrefix:@"OsiriX "])
                [templatesDirPathContents removeObjectAtIndex:i];
        if ([templatesDirPathContents count] == 1)
            inTemplateName = [templatesDirPathContents objectAtIndex:0];
        
        templatePath = [templatesDirPath stringByAppendingPathComponent:inTemplateName];
    }
    else {
        templatePath = [[templatesDirPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ReportTemplate.doc"];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:templatePath])
    {
        NSRunCriticalAlertPanel( NSLocalizedString( @"Microsoft Word", nil),  NSLocalizedString(@"I cannot find the OsiriX Word Template doc file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return NO;
    }
	NSString* source =
    @"on run argv\n"
    @"  set dataSourceFileUnix to (item 1 of argv)\n"
	@"  set outFilePathUnix to (item 2 of argv)\n"
	@"  set templatePathUnix to (item 3 of argv)\n"
	@"  set dataSourceFile to POSIX file dataSourceFileUnix\n"
    @"  set outFilePath to POSIX file outFilePathUnix\n"
    @"  set templatePath to POSIX file templatePathUnix\n"
    @"  tell application \"Microsoft Word\"\n"
    @"    open templatePath\n"
    @"    open data source data merge of document 1 name dataSourceFile\n"
    @"    set myMerge to data merge of document 1\n"
    @"    set destination of myMerge to send to new document\n"
    @"    execute data merge myMerge\n"
    @"    save as document 1 file name (outFilePath as string)\n"
    @"    close document 2 saving no\n" // close the non-merged file
    @"  end tell\n"
    @"end run\n";
	
//	NSLog(@"%@", source);
    
    @try {
        [[self class] _runAppleScript:source withArguments:[NSArray arrayWithObjects: sourceData, destinationFile, templatePath, nil]];
    } @catch( NSException* e) {
        NSLog( @"Exception: %@", e.reason);
        return NO;
    }
    
    [study setValue:destinationFile forKey: @"reportURL"];
    
    [[NSWorkspace sharedWorkspace] openFile:destinationFile withApplication:@"Microsoft Word" andDeactivate:YES]; // it's already open, but we're making it come to foreground
    [NSThread sleepForTimeInterval:1]; // why?
    
    return YES;
}

#pragma mark -
#pragma mark OpenDocument

- (BOOL) createNewOpenDocumentReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
{
	// decompress the gzipped index.xml.gz file in the .pages bundle
	NSTask *unzip = [[[NSTask alloc] init] autorelease];
	[unzip setLaunchPath:@"/usr/bin/unzip"];
	[unzip setCurrentDirectoryPath: [aPath stringByDeletingLastPathComponent]];
	
	[[NSFileManager defaultManager] removeItemAtPath: [[aPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"OOOsiriX"] error: nil];
	[unzip setArguments: [NSArray arrayWithObjects: aPath, @"-d", @"OOOsiriX", nil]];
	[unzip launch];

	while( [unzip isRunning])
        [NSThread sleepForTimeInterval: 0.1];
    
    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
	int status = [unzip terminationStatus];
 
	if (status == 0)
		NSLog(@"OO Report creation. unzip -d succeeded.");
	else
	{
		NSLog(@"OO Report creation  failed. Cause: unzip -d failed.");
		return NO;
	}
	
	// read the xml file and find & replace templated string with patient's datas
	NSString *indexFilePath = [NSString stringWithFormat:@"%@/OOOsiriX/content.xml", [aPath stringByDeletingLastPathComponent]];
	NSError *xmlError = nil;
	NSStringEncoding xmlFileEncoding = NSUTF8StringEncoding;
	NSMutableString *xmlContentString = [NSMutableString stringWithContentsOfFile:indexFilePath encoding:xmlFileEncoding error:&xmlError];
	
	[self searchAndReplaceFieldsFromStudy:aStudy inString:xmlContentString];
	
	if(![xmlContentString writeToFile:indexFilePath atomically:YES encoding:xmlFileEncoding error:&xmlError])
		return NO;
	
	// zip back the index.xml file
	unzip = [[[NSTask alloc] init] autorelease];
	[unzip setLaunchPath:@"/usr/bin/zip"];
	[unzip setCurrentDirectoryPath: [[aPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"OOOsiriX"]];
	[unzip setArguments: [NSArray arrayWithObjects: @"-q", @"-r", aPath, @"content.xml", nil]];
	[unzip launch];

	while( [unzip isRunning])
        [NSThread sleepForTimeInterval: 0.1];
    
    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
	status = [unzip terminationStatus];
 
	if (status == 0)
		NSLog(@"OO Report creation. zip succeeded.");
	else
	{
		NSLog(@"OO Report creation  failed. Cause: zip failed.");
		// we don't need to return NO, because the xml has been modified. Thus, even if the file is not compressed, the report is valid...
	}
	
	[[NSFileManager defaultManager] removeItemAtPath: [[aPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"OOOsiriX"] error: nil];
	
	[aStudy setValue:aPath forKey:@"reportURL"];
	
	// open the modified .odt file
	if( [[NSWorkspace sharedWorkspace] openFile:aPath withApplication: @"OpenOffice" andDeactivate: YES] == NO)
		[[NSWorkspace sharedWorkspace] openFile:aPath withApplication: nil andDeactivate: YES];
	[NSThread sleepForTimeInterval: 1];
	
	// end
	return YES;
}

#pragma mark -
#pragma mark Pages.app

- (void) decompressPagesFileIfNecessary: (NSString*) aPath
{
    BOOL isDirectory = NO;
    if( [[NSFileManager defaultManager] fileExistsAtPath: aPath isDirectory: &isDirectory] && isDirectory == NO)
    {
#define UNZIPPEDNAME @"unzipped"
        
        // decompress .pages file
        NSTask *unzip = [[[NSTask alloc] init] autorelease];
        [unzip setLaunchPath:@"/usr/bin/unzip"];
        [unzip setCurrentDirectoryPath:aPath.stringByDeletingLastPathComponent];
        [unzip setArguments:[NSArray arrayWithObjects: @"-qq", @"-o", @"-d", UNZIPPEDNAME, aPath, nil]];
        [unzip launch];
        
        while( [unzip isRunning])
            [NSThread sleepForTimeInterval: 0.1];
        
        //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
        int status = [unzip terminationStatus];
        
        if (status == 0)
            NSLog(@"Pages Report creation. unzip -d succeeded.");
        else
        {
            NSLog(@"Pages Report creation  failed. Cause: unzip -d failed.");
            return;
        }
        
        [[NSFileManager defaultManager] removeItemAtPath: aPath error: nil];
        [[NSFileManager defaultManager] moveItemAtPath: [aPath.stringByDeletingLastPathComponent stringByAppendingPathComponent: UNZIPPEDNAME] toPath: aPath error: nil];
    }
}

- (BOOL)createNewPagesReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
{	
	// create the Pages file, using the template (not filling the patient's data yet)
	
	[[NSFileManager defaultManager] removeItemAtPath:aPath error:NULL];
    
    NSString* templatePath = [[self class] pathForPagesTemplate: templateName];
    if( templatePath)
        [[NSFileManager defaultManager] copyItemAtPath: templatePath toPath:aPath byReplacingExisting:YES error: nil];
    else {
		NSRunCriticalAlertPanel( NSLocalizedString( @"Pages", nil),  NSLocalizedString(@"Failed to create the report with Pages.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return NO;
	}
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:aPath] == NO) {
		NSRunCriticalAlertPanel( NSLocalizedString( @"Pages", nil),  NSLocalizedString(@"Failed to create the report with Pages.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return NO;
	}
    
    [self decompressPagesFileIfNecessary: aPath];
    
	// read the xml file and find & replace templated string with patient's datas
	NSString *indexFilePath = [aPath stringByAppendingPathComponent:@"index.xml"];
    if( [[NSFileManager defaultManager] fileExistsAtPath:indexFilePath] == NO)
    {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"pages2pages09" ofType:@"applescript"];
        [[self class] _runAppleScript: [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error:nil] withArguments:[NSArray arrayWithObjects: templatePath, [templatePath stringByAppendingString: @"09.pages"], nil]];
        
        NSLog( @"-- Try to convert to Pages 09: %@", templateName);
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: [templatePath stringByAppendingString: @"09.pages"]])
        {
            [[NSFileManager defaultManager] removeItemAtPath: templatePath error: nil];
            [[NSFileManager defaultManager] moveItemAtPath: [templatePath stringByAppendingString: @"09.pages"] toPath:templatePath error: nil];
            [[NSFileManager defaultManager] removeItemAtPath: aPath error: nil];
            [[NSFileManager defaultManager] copyItemAtPath: templatePath toPath:aPath byReplacingExisting:YES error: nil];
            
            [self decompressPagesFileIfNecessary: aPath];
        }
        
        if( [[NSFileManager defaultManager] fileExistsAtPath:indexFilePath] == NO)
        {
            NSRunCriticalAlertPanel( NSLocalizedString( @"Pages", nil),  NSLocalizedString(@"OsiriX requires templates files in Pages '09 format. Open you template in Pages, select File menu and Export to Pages '09 format.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            return NO;
        }
    }
    
	NSError *xmlError = nil;
	NSStringEncoding xmlFileEncoding = NSUTF8StringEncoding;
	NSMutableString *xmlContentString = [NSMutableString stringWithContentsOfFile:indexFilePath encoding:xmlFileEncoding error:&xmlError];

	[self searchAndReplaceFieldsFromStudy:aStudy inString:xmlContentString];
	
	if(![xmlContentString writeToFile:indexFilePath atomically:YES encoding:xmlFileEncoding error:&xmlError])
		return NO;
	
	[aStudy setValue: aPath forKey:@"reportURL"];
	
	// open the modified .pages file
	[[NSWorkspace sharedWorkspace] openFile:aPath withApplication:@"Pages" andDeactivate: YES];
	[NSThread sleepForTimeInterval: 1];
	
	// end
	return YES;
}

+ (NSString*) pathForPagesTemplate: (NSString*) templateName
{
	NSString *templateDirectory = [self databasePagesTemplatesDirPath];
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:templateDirectory];
	
	NSString *file;
	while ((file = [directoryEnumerator nextObject]))
	{
		[directoryEnumerator skipDescendents];
		if( [file.stringByDeletingPathExtension isEqualToString: templateName.stringByDeletingPathExtension])
        {
            if( [file.pathExtension isEqualToString: @"pages"])
                return [templateDirectory stringByAppendingPathComponent: file];
        }
	}
    
    return nil;
}

+ (NSMutableArray*)pagesTemplatesList;
{
	// iWork templates directory
	NSString *templateDirectory = [self databasePagesTemplatesDirPath];
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:templateDirectory];
	
	NSMutableArray *templatesArray = [NSMutableArray arrayWithCapacity:1];
	NSString *file;
	while ((file = [directoryEnumerator nextObject]))
	{
		[directoryEnumerator skipDescendents];
		if( [file.pathExtension isEqualToString: @"pages"])
			[templatesArray addObject: file];
	}
	
	return templatesArray;
}

- (NSMutableString *)templateName;
{
	return templateName;
}

- (void)setTemplateName:(NSString *)aName;
{
	[templateName setString:aName];
	[templateName replaceOccurrencesOfString:@".pages" withString:@"" options:NSLiteralSearch range:templateName.range];
}

@end
