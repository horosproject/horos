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

extern NSString				*documentsDirectory();

#import "Reports.h"
#import "DicomFile.h"

// if you want check point log info, define CHECK to the next line, uncommented:
#define CHECK NSLog(@"result code = %d", ok);

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

		txt = [[NSString alloc] initWithData:outBytes encoding:[NSString defaultCStringEncoding]];
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

@implementation Reports

+ (NSString*) getUniqueFilename:(NSManagedObject*) study
{
	return [DicomFile NSreplaceBadCharacter: [[study valueForKey:@"patientUID"] stringByAppendingFormat:@"-%@", [study valueForKey:@"id"]]];
}

- (NSString*) generateReportSourceData:(NSManagedObject*) study
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
	
	NSString	*shortDateString = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
	NSDictionary	*localeDictionnary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
		
	for( x = 0; x < [properties count]; x++)
	{
		NSString	*name = [properties objectAtIndex: x];
		NSString	*string;
		
		if( [[study valueForKey: name] isKindOfClass: [NSDate class]])
		{
			string = [[study valueForKey: name] descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary];
		}
		else string = [[study valueForKey: name] description];
		
		if( string)
			[file appendString: [DicomFile NSreplaceBadCharacter:string]];
		else
			[file appendString: @""];
		
		[file appendFormat: @"%c", NSTabCharacter];
	}
	
	NSString	*path = [documentsDirectory() stringByAppendingFormat:@"/TEMP/Report.txt"];
	
	[[NSFileManager defaultManager] removeFileAtPath:path handler:0L];
	
	[file writeToFile: path atomically: YES];
	
	return path;
}

- (NSString *) HFSStyle: (NSString*) string
{
	return [[(NSURL *)CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)string, kCFURLHFSPathStyle, NO) autorelease] path];
}

- (NSString *) reportScriptBody:(NSManagedObject*) study
{
	NSString	*sourceData = [self generateReportSourceData: study];
	
	[[NSWorkspace sharedWorkspace] openFile:[documentsDirectory() stringByAppendingFormat:@"/ReportTemplate.doc"] withApplication:@"Microsoft Word" andDeactivate:NO];
	
	NSMutableString *s = [NSMutableString stringWithCapacity:1000];

	[s appendString:@"tell application \"Microsoft Word\"\n"];
	[s appendString:[NSString stringWithFormat:@"set dataSourceFile to (POSIX file \"%@\")\n", sourceData]];
	[s appendString:[NSString stringWithFormat:@"open data source data merge of active document name dataSourceFile\n"]];
	[s appendString:@"set myMerge to data merge of active document\n"];
	[s appendString:@"set destination of myMerge to send to new document\n"];
	[s appendString:@"execute data merge myMerge\n"];
	[s appendString:@"save as active document file name \"report.doc\"\n"];
	[s appendString:@"close active document saving no\n"];
	[s appendString:@"close active document saving no\n"];
	[s appendString:@"end tell\n"];
	
	NSLog( s);
	
	return s;
}

- (BOOL) createNewReport:(NSManagedObject*) study destination:(NSString*) path type:(int) type
{	
	NSString	*uniqueFilename = [Reports getUniqueFilename: study];
	
	switch( type)
	{
		case 0:
		{
			[self runScript: [self reportScriptBody: study]];
			
			NSString	*destinationFile = [NSString stringWithFormat:@"%@%@.%@", path, uniqueFilename, @"doc"];
			[[NSFileManager defaultManager] movePath:[documentsDirectory() stringByAppendingFormat:@"/report.doc"] toPath:destinationFile handler: 0L];
			[[NSWorkspace sharedWorkspace] openFile:destinationFile withApplication:@"Microsoft Word"];
			[study setValue: destinationFile forKey:@"reportURL"];
		}
		break;
		
		case 1:
		{
			NSString	*destinationFile = [NSString stringWithFormat:@"%@%@.%@", path, uniqueFilename, @"rtf"];
			[[NSFileManager defaultManager] copyPath:[documentsDirectory() stringByAppendingFormat:@"/ReportTemplate.rtf"] toPath:destinationFile handler: 0L];
			
			NSDictionary                *attr;
			NSMutableAttributedString	*rtf = [[NSMutableAttributedString alloc] initWithRTF: [NSData dataWithContentsOfFile:destinationFile] documentAttributes:&attr];
			NSString					*rtfString = [rtf string];
			NSRange						range;
			
			// SCAN FIELDS
			
			long x;
			NSManagedObjectModel	*model = [[[study managedObjectContext] persistentStoreCoordinator] managedObjectModel];
			NSArray *properties = [[[[model entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
			NSMutableString	*file = [NSMutableString stringWithString:@""];
			
			NSString	*shortDateString = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
			NSDictionary	*localeDictionnary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
			
			for( x = 0; x < [properties count]; x++)
			{
				NSString	*name = [properties objectAtIndex: x];
				NSString	*string;
				
				if( [[study valueForKey: name] isKindOfClass: [NSDate class]])
				{
					string = [[study valueForKey: name] descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary];
				}
				else string = [[study valueForKey: name] description];
				
				NSRange	searchRange = NSMakeRange(0, [rtf length]);
				
				do
				{
					range = [rtfString rangeOfString: [NSString stringWithFormat:@"Ç%@È", name] options:0 range: searchRange];
					
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
			
			NSRange	searchRange = NSMakeRange(0, [rtf length]);
			
			range = [rtfString rangeOfString: [NSString stringWithString:@"ÇtodayÈ"] options:0 range: searchRange];
			if( range.length > 0)
			{
				[rtf replaceCharactersInRange:range withString:[[NSDate date] descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary]];
			}
			
			[[rtf RTFFromRange:NSMakeRange(0, [rtf length]) documentAttributes:attr] writeToFile:destinationFile atomically:YES];
			
			[[NSWorkspace sharedWorkspace] openFile:destinationFile withApplication:@"TextEdit"];
			[study setValue: destinationFile forKey:@"reportURL"];
		}
		break;
	}
	return YES;
}

// initialize it in your init method:

- (id)init
{
	self = [super init];
	if (self)
	{
		myComponent = OpenDefaultComponent(kOSAComponentType, kOSAGenericScriptingComponentSubtype);
		// other initialization code here
	}
	return self;
}

// do the grunge work -

// the sweetly wrapped method is all we need to know:

- (void)runScript:(NSString *)txt
{
NSData *scriptChars = [txt dataUsingEncoding:[NSString defaultCStringEncoding]];
AEDesc source, resultText;
OSAID scriptId, resultId;
OSErr ok;

// Convert the source string into an AEDesc of string type.
ok = AECreateDesc(typeChar, [scriptChars bytes], [scriptChars length], &source);
CHECK;

// Compile the source into a script.
scriptId = kOSANullScript;
ok = OSACompile(myComponent, &source, kOSAModeNull, &scriptId);
AEDisposeDesc(&source);
CHECK;


// Execute the script, using defaults for everything.
resultId = 0;
ok = OSAExecute(myComponent, scriptId, kOSANullScript, kOSAModeNull, &resultId);
CHECK;

if (ok == errOSAScriptError) {
AEDesc ernum, erstr;
id ernumobj, erstrobj;

// Extract the error number and error message from our scripting component.
ok = OSAScriptError(myComponent, kOSAErrorNumber, typeShortInteger, &ernum);
CHECK;
ok = OSAScriptError(myComponent, kOSAErrorMessage, typeChar, &erstr);
CHECK;

// Convert them to ObjC types.
ernumobj = aedesc_to_id(&ernum);
AEDisposeDesc(&ernum);
erstrobj = aedesc_to_id(&erstr);
AEDisposeDesc(&erstr);

txt = [NSString stringWithFormat:@"Error, number=%@, message=%@", ernumobj, erstrobj];
} else {
// If no error, extract the result, and convert it to a string for display

if (resultId != 0) { // apple doesn't mention that this can be 0?
ok = OSADisplay(myComponent, resultId, typeChar, kOSAModeNull, &resultText);
CHECK;

//NSLog(@"result thingy type = \"%c%c%c%c\"", ((char *)&(resultText.descriptorType))[0], ((char *)&(resultText.descriptorType))[1], ((char *)&(resultText.descriptorType))[2], ((char *)&(resultText.descriptorType))[3]);

txt = aedesc_to_id(&resultText);
AEDisposeDesc(&resultText);
} else {
txt = @"[no value returned]";
}
OSADispose(myComponent, resultId);
}

ok = OSADispose(myComponent, scriptId);
CHECK;
}

@end
