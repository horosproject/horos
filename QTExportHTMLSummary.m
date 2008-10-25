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

#import "QTExportHTMLSummary.h"
#import "AppController.h"

extern NSString *documentsDirectory();

@implementation QTExportHTMLSummary

+(NSString*)nonNilString:(NSString*)aString;
{
	return (!aString)? @"" : aString;
}

- (id)init;
{
	if (![super init])
		return 0L;
	
	[self readTemplates];
	
	footerString = NSLocalizedString(@"Made with <a href='http://www.osirix-viewer.com' target='_blank'>OsiriX</a><br />Requires <a href='http://www.apple.com/quicktime/' target='_blank'>QuickTime</a> to display some of the images",nil);
	[footerString retain];
	
	dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateStyle: NSDateFormatterShortStyle];

	timeFormat = [[NSDateFormatter alloc] init];
	[timeFormat setTimeStyle: NSDateFormatterShortStyle];
	
	return self;
}

- (void) dealloc
{
	[footerString release];
	[dateFormat release];
	[timeFormat release];
	
	[patientsListTemplate release];
	[examsListTemplate release];
	[seriesTemplate release];
	
	[rootPath release];
	[patientsDictionary release];
	
	[super dealloc];
}

#pragma mark-
#pragma mark HTML template

- (void)readTemplates;
{
	[AppController checkForHTMLTemplates];
	patientsListTemplate = [[NSString stringWithContentsOfFile:[documentsDirectory() stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportPatientsTemplate.html"]] retain];
	[AppController checkForHTMLTemplates];
	examsListTemplate = [[NSString stringWithContentsOfFile:[documentsDirectory() stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportStudiesTemplate.html"]] retain];
	[AppController checkForHTMLTemplates];
	seriesTemplate = [[NSString stringWithContentsOfFile:[documentsDirectory() stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportSeriesTemplate.html"]] retain];
}

- (NSString*)fillPatientsListTemplates;
{
	// working string to process the template
	NSMutableString *tempPatientHTML = [NSMutableString stringWithString:patientsListTemplate];
	// simple replacements
	[tempPatientHTML replaceOccurrencesOfString:@"%page_title%" withString:NSLocalizedString(@"Patients list",nil) options:NSLiteralSearch range:NSMakeRange(0, [tempPatientHTML length])];
	[tempPatientHTML replaceOccurrencesOfString:@"%patient_list_string%" withString:NSLocalizedString(@"Patients list",nil) options:NSLiteralSearch range:NSMakeRange(0, [tempPatientHTML length])];
	[tempPatientHTML replaceOccurrencesOfString:@"%footer_string%" withString:footerString options:NSLiteralSearch range:NSMakeRange(0, [tempPatientHTML length])];
	
	// look for the patients list html structure
	NSArray *components = [tempPatientHTML componentsSeparatedByString:@"%start_patient_i%"];
	NSString *templateStart = [NSString stringWithString:[components objectAtIndex:0]];
	components = [[components objectAtIndex:1] componentsSeparatedByString:@"%end_patient_i%"];
	NSString *listItemTemplate = [components objectAtIndex:0];
	NSString *templateEnd = [NSString stringWithString:[components objectAtIndex:1]];

	// create the html patient list
	NSMutableString *tempPatientsList = [NSMutableString stringWithCapacity:0];
	NSMutableString *tempListItemTemplate;
	
	NSEnumerator *enumerator = [patientsDictionary objectEnumerator];
	id series;

	NSString *linkToPatientPage, *patientName, *patientDateOfBirth;
	while (series = [enumerator nextObject])
	{
		tempListItemTemplate = [NSMutableString stringWithString:listItemTemplate];
		//linkToPatientPage = [asciiString([[series objectAtIndex:0] valueForKeyPath:@"study.name"]) stringByAppendingPathComponent:@"/index.html"];
		linkToPatientPage = [NSString stringWithFormat:@"./%@/%@", asciiString([[series objectAtIndex:0] valueForKeyPath:@"study.name"]), @"index.html"];
		
		[tempListItemTemplate replaceOccurrencesOfString:@"%patient_i_page%" withString:[QTExportHTMLSummary nonNilString:linkToPatientPage] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
		patientName = [[series objectAtIndex:0] valueForKeyPath:@"study.name"];
		[tempListItemTemplate replaceOccurrencesOfString:@"%patient_i_name%" withString:[QTExportHTMLSummary nonNilString:patientName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
		patientDateOfBirth = [dateFormat stringFromDate: [[series objectAtIndex:0] valueForKeyPath:@"study.dateOfBirth"]];
		[tempListItemTemplate replaceOccurrencesOfString:@"%patient_i_dateOfBirth%" withString:[QTExportHTMLSummary nonNilString:patientDateOfBirth] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
		[tempPatientsList appendString:tempListItemTemplate];
	}
	// create the whole html code
	NSMutableString *filledTemplate = [NSMutableString stringWithString:templateStart];
	[filledTemplate appendString:tempPatientsList];
	[filledTemplate appendString:templateEnd];
	
	return filledTemplate;
}

- (NSString*)fillStudiesListTemplatesForSeries:(NSArray*) series;
{
	// working string to process the template
	NSMutableString *tempExamsHTML = [NSMutableString stringWithString:examsListTemplate];
	// simple replacements
	[tempExamsHTML replaceOccurrencesOfString:@"%patient_name%" withString:[QTExportHTMLSummary nonNilString:[[series objectAtIndex:0] valueForKeyPath:@"study.name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempExamsHTML length])];
	[tempExamsHTML replaceOccurrencesOfString:@"%patient_dateOfBirth%" withString:[QTExportHTMLSummary nonNilString:[dateFormat stringFromDate: [[series objectAtIndex:0] valueForKeyPath:@"study.dateOfBirth"] ]] options:NSLiteralSearch range:NSMakeRange(0, [tempExamsHTML length])];
	[tempExamsHTML replaceOccurrencesOfString:@"%footer_string%" withString:footerString options:NSLiteralSearch range:NSMakeRange(0, [tempExamsHTML length])];
	
	// look for the study html block structure
	NSArray *components = [tempExamsHTML componentsSeparatedByString:@"%study_i_start%"];
	NSString *templateHeader = [NSString stringWithString:[components objectAtIndex:0]];
	components = [[components objectAtIndex:1] componentsSeparatedByString:@"%study_i_end%"];
	NSString *studyBlock = [components objectAtIndex:0];
	NSString *templateFooter = [NSString stringWithString:[components objectAtIndex:1]];
	
	// look for the series list html structure
	components = [studyBlock componentsSeparatedByString:@"%series_i_start%"];
	NSString *studyBlockStart = [NSString stringWithString:[components objectAtIndex:0]];
	components = [[components objectAtIndex:1] componentsSeparatedByString:@"%series_i_end%"];
	NSString *listItemTemplate = [components objectAtIndex:0];
	NSString *studyBlockEnd = [NSString stringWithString:[components objectAtIndex:1]];
	
	// create the html studies blocks
	NSMutableString *tempStudyBlock = [NSMutableString stringWithCapacity:0];
	// create the html series lists
	NSMutableString *tempSeriesList = [NSMutableString stringWithCapacity:0];
	NSMutableString *tempListItemTemplate, *tempStudyBlockStart;

	int i, imagesCount = 0;
	long previousSeries = -1;
	
	NSMutableString *fileName, *thumbnailName, *htmlName;
	NSString *studyDate, *studyTime, *seriesName;
	NSString *extension;

	BOOL lastImageOfSeries, lastImageOfStudy;
	lastImageOfSeries = lastImageOfStudy = NO;
	
	for(i=0; i<[series count]; i++)
	{
		imagesCount++;
		if(i==[series count]-1)
			lastImageOfSeries = YES;
		else if([[[series objectAtIndex:i] valueForKey: @"id"] intValue] != [[[series objectAtIndex:i+1] valueForKey: @"id"] intValue])
			lastImageOfSeries = YES;
		else if([[[series objectAtIndex:i] valueForKeyPath: @"study.id"] isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.id"]] == NO)
			lastImageOfSeries = YES;
		else
			lastImageOfSeries = NO;
		
		if(lastImageOfSeries)
		{
			seriesName = asciiString( [NSMutableString stringWithString:[[series objectAtIndex:i] valueForKey: @"name"]]);
			fileName = [NSMutableString stringWithFormat:@"%@ - %@", asciiString( [[series objectAtIndex:i] valueForKeyPath:@"study.studyName"]), [[series objectAtIndex:i] valueForKeyPath:@"study.id"]];
			[fileName appendFormat:@"/%@_%@", seriesName, [[series objectAtIndex:i] valueForKey: @"id"]];
			
			thumbnailName = [NSMutableString stringWithFormat:@"%@_thumb.jpg", fileName];
			htmlName = [NSMutableString stringWithFormat:@"%@.html", fileName];
			
			tempListItemTemplate = [NSMutableString stringWithString:listItemTemplate];
			extension = (imagesCount>1)? @"mov": @"jpg";
			[fileName appendFormat:@".%@",extension];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_file%" withString:[QTExportHTMLSummary nonNilString:htmlName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_thumbnail%" withString:[QTExportHTMLSummary nonNilString:thumbnailName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_name%" withString:[QTExportHTMLSummary nonNilString:seriesName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_id%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%@",[[series objectAtIndex:i] valueForKey: @"id"]]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_images_count%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%d",imagesCount]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempSeriesList appendString:tempListItemTemplate];
			
			[self createHTMLSeriesPage:[series objectAtIndex:i] numberOfImages:imagesCount outPutFileName:htmlName];
			
			imagesCount = 0;
			
			if(i==[series count]-1)
				lastImageOfStudy = YES;
			else if([[[series objectAtIndex:i] valueForKeyPath: @"study.studyInstanceUID"] isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.studyInstanceUID"]] == NO)
				lastImageOfStudy = YES;
			else if([[[series objectAtIndex:i] valueForKeyPath: @"study.studyName"]isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.studyName"]] == NO)
				lastImageOfStudy = YES;
			else
				lastImageOfStudy = NO;
				
			if(lastImageOfStudy)
			{			
				tempStudyBlockStart = [NSMutableString stringWithString:studyBlockStart];
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_name%" withString:[QTExportHTMLSummary nonNilString:[[series objectAtIndex:i] valueForKeyPath:@"study.studyName"]] options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				studyDate = [dateFormat stringFromDate: [[series objectAtIndex:i] valueForKeyPath:@"study.date"]];
				studyTime = [timeFormat stringFromDate: [[series objectAtIndex:i] valueForKeyPath:@"study.date"]];
				
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_date%" withString:[QTExportHTMLSummary nonNilString:studyDate] options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_time%" withString:[QTExportHTMLSummary nonNilString:studyTime] options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_id%" withString:[QTExportHTMLSummary nonNilString:[[series objectAtIndex:i] valueForKeyPath:@"study.id"]] options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				[tempStudyBlock appendString:tempStudyBlockStart];
				[tempStudyBlock appendString:tempSeriesList];
				[tempStudyBlock appendString:studyBlockEnd];
				tempSeriesList = [NSMutableString stringWithCapacity:0];
			}
		}
	}
	
	// create the whole html code
	NSMutableString *filledTemplate = [NSMutableString stringWithString:templateHeader];
	[filledTemplate appendString:tempStudyBlock];
	[filledTemplate appendString:templateFooter];
	
	return filledTemplate;
}

- (NSString*)fillSeriesTemplatesForSeries:(NSManagedObject*)series numberOfImages:(int)imagesCount;
{
	NSMutableString *tempHTML = [NSMutableString stringWithString:seriesTemplate];
	
	[tempHTML replaceOccurrencesOfString:@"%series_name%" withString:[QTExportHTMLSummary nonNilString:[series valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%patient_name%" withString:[QTExportHTMLSummary nonNilString:[series valueForKeyPath:@"study.name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%patient_dateOfBirth%" withString:[QTExportHTMLSummary nonNilString:[dateFormat stringFromDate: [series valueForKeyPath:@"study.dateOfBirth"] ]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%series_name%" withString:[QTExportHTMLSummary nonNilString:[series valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%series_id%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%@",[series valueForKey: @"id"]]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%series_images_count%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%d", imagesCount]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];

	NSString *studyName = asciiString([series valueForKeyPath:@"study.studyName"]);
	NSMutableString *fileName = [NSMutableString stringWithFormat:@"./%@_%@", asciiString([NSMutableString stringWithString:[series valueForKey: @"name"]]), [series valueForKey: @"id"]];
	NSString *extension = (imagesCount>1)? @"mov": @"jpg";
	[fileName appendFormat:@".%@",extension];
	
	[tempHTML replaceOccurrencesOfString:@"%series_file_path%" withString:[QTExportHTMLSummary nonNilString:fileName] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%footer_string%" withString:footerString options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];

	NSArray *components;

	if(imagesCount>1 && [[[series valueForKeyPath:@"images.width"] allObjects] count] > 0 )
	{
		[tempHTML replaceOccurrencesOfString:@"%series_mov%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%width%" withString:[NSString stringWithFormat:@"%@", [[[series valueForKeyPath:@"images.width"] allObjects] objectAtIndex:0]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%height%" withString:[NSString stringWithFormat:@"%d", [[[[series valueForKeyPath:@"images.height"] allObjects] objectAtIndex:0] intValue]+15] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])]; // +15 is for the movie's controller
		components = [tempHTML componentsSeparatedByString:@"%series_img%"];
		
	}
	else
	{
		[tempHTML replaceOccurrencesOfString:@"%series_img%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		components = [tempHTML componentsSeparatedByString:@"%series_mov%"];
	}
	
	NSMutableString *filledTemplate;
	filledTemplate = [NSMutableString stringWithString:[components objectAtIndex:0]];
	[filledTemplate appendString:[components objectAtIndex:2]];
	return filledTemplate;
}

#pragma mark-
#pragma mark HTML file creation

- (void)createHTMLfiles;
{
	[self createHTMLPatientsList];
	[self createHTMLStudiesList];
	[self createHTMLExtraDirectory];
}

- (void)createHTMLPatientsList;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];

	NSString *htmlContent = [self fillPatientsListTemplates];
	[fileManager createFileAtPath:[rootPath stringByAppendingPathComponent:@"/index.html"] contents:[htmlContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

- (void)createHTMLStudiesList;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSEnumerator *enumerator = [patientsDictionary objectEnumerator];
	id study;
	NSString *patientName;
	while (study = [enumerator nextObject])
	{
		if( [study count] > 0)
		{
			patientName = asciiString( [NSMutableString stringWithString:[[study objectAtIndex:0] valueForKeyPath: @"study.name"]]);
			NSString *htmlContent = [self fillStudiesListTemplatesForSeries:study];
			[fileManager createFileAtPath:[rootPath stringByAppendingFormat:@"/%@/index.html", patientName] contents:[htmlContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
		}
	}
}

- (void)createHTMLExtraDirectory;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *htmlExtraDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/HTML_TEMPLATES/html-extra/"];
	NSArray *directoryContent = [fileManager subpathsAtPath:htmlExtraDirectory];
	//if([directoryContent count])
	[fileManager copyPath:htmlExtraDirectory toPath:[rootPath stringByAppendingPathComponent:@"/html-extra/"] handler:NO];
}

- (void)createHTMLSeriesPage:(NSManagedObject*)series numberOfImages:(int)imagesCount outPutFileName:(NSString*)fileName;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *htmlContent = [self fillSeriesTemplatesForSeries:series numberOfImages:imagesCount];
	NSString *patientName = asciiString([NSMutableString stringWithString:[series valueForKeyPath: @"study.name"]]);
	NSString *studyName = asciiString([NSMutableString stringWithString:[series valueForKeyPath: @"study.studyName"]]);
	[fileManager createFileAtPath:[rootPath stringByAppendingFormat:@"/%@/%@", patientName, fileName] contents:[htmlContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

#pragma mark-
#pragma mark setters

- (void)setPath:(NSString*)path
{
	if( rootPath != path)
	{
		[rootPath release];
		rootPath = [path retain];
	}
}

- (void)setPatientsDictionary:(NSDictionary*)dictionary;
{
	if( patientsDictionary != dictionary)
	{
		[patientsDictionary release];
		patientsDictionary = [dictionary retain];
	}
}

@end
