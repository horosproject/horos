//
//  QTExportHTMLSummary.m
//  OsiriX
//
//  Created by joris on 17/07/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QTExportHTMLSummary.h"

extern NSString *documentsDirectory();

@implementation QTExportHTMLSummary

- (id)init;
{
	if (![super init])
		return;
	[self readTemplates];
	return self;
}

#pragma mark-
#pragma mark HTML template

- (void)readTemplates;
{
	patientsListTemplate = [NSString stringWithContentsOfFile:[documentsDirectory() stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportPatientsTemplate.html"]];
	examsListTemplate = [NSString stringWithContentsOfFile:[documentsDirectory() stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportStudiesTemplate.html"]];
}

- (NSString*)fillPatientsListTemplates;
{
	// working string to process the template
	NSMutableString *tempPatientHTML = [NSMutableString stringWithString:patientsListTemplate];
	// simple replacements
	[tempPatientHTML replaceOccurrencesOfString:@"%page_title%" withString:NSLocalizedString(@"Patients list",nil) options:NSLiteralSearch range:NSMakeRange(0, [tempPatientHTML length])];
	[tempPatientHTML replaceOccurrencesOfString:@"%patient_list_string%" withString:NSLocalizedString(@"Patients list",nil) options:NSLiteralSearch range:NSMakeRange(0, [tempPatientHTML length])];
	[tempPatientHTML replaceOccurrencesOfString:@"%footer_string%" withString:NSLocalizedString(@"Made with <a href='http://homepage.mac.com/rossetantoine/osirix/' target='_blank'>OsiriX</a>",nil) options:NSLiteralSearch range:NSMakeRange(0, [tempPatientHTML length])];
	
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
	while (series = [enumerator nextObject])
	{
		tempListItemTemplate = [NSMutableString stringWithString:listItemTemplate];
		[tempListItemTemplate replaceOccurrencesOfString:@"%patient_i_page%" withString:[[[series objectAtIndex:0] valueForKeyPath:@"study.name"] stringByAppendingString:@"/index.html"] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
		[tempListItemTemplate replaceOccurrencesOfString:@"%patient_i_name%" withString:[[series objectAtIndex:0] valueForKeyPath:@"study.name"] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
		[tempListItemTemplate replaceOccurrencesOfString:@"%patient_i_dateOfBirth%" withString:[[[series objectAtIndex:0] valueForKeyPath:@"study.dateOfBirth"] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString] timeZone:0L locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
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
	[tempExamsHTML replaceOccurrencesOfString:@"%patient_name%" withString:[[series objectAtIndex:0] valueForKeyPath:@"study.name"] options:NSLiteralSearch range:NSMakeRange(0, [tempExamsHTML length])];
	[tempExamsHTML replaceOccurrencesOfString:@"%patient_dateOfBirth%" withString:[[[series objectAtIndex:0] valueForKeyPath:@"study.dateOfBirth"] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString] timeZone:0L locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]] options:NSLiteralSearch range:NSMakeRange(0, [tempExamsHTML length])];
	[tempExamsHTML replaceOccurrencesOfString:@"%footer_string%" withString:NSLocalizedString(@"Made with <a href='http://homepage.mac.com/rossetantoine/osirix/' target='_blank'>OsiriX</a>",nil) options:NSLiteralSearch range:NSMakeRange(0, [tempExamsHTML length])];
	
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
	
	NSMutableString *fileName, *seriesName, *thumbnailName;
	NSString *studyDate, *studyTime;
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
		else
			lastImageOfSeries = NO;
		
		if(lastImageOfSeries)
		{
			seriesName = [NSMutableString stringWithString:[[series objectAtIndex:i] valueForKeyPath: @"name"]];
			[seriesName replaceOccurrencesOfString:@"/" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [seriesName length])];
			fileName = [NSMutableString stringWithFormat:@"%@ - %@", [[series objectAtIndex:i] valueForKeyPath:@"study.studyName"], [[series objectAtIndex:i] valueForKeyPath:@"study.id"]];
			[fileName appendFormat:@"/%@_%@", seriesName, [[series objectAtIndex:i] valueForKeyPath: @"id"]];
			
			thumbnailName = [NSMutableString stringWithFormat:@"%@_thumb.jpg", fileName];
			
			tempListItemTemplate = [NSMutableString stringWithString:listItemTemplate];
			extension = (imagesCount>1)? @"mov": @"jpg";
			[fileName appendFormat:@".%@",extension];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_file%" withString:fileName options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_thumbnail%" withString:thumbnailName options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_name%" withString:seriesName options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_id%" withString:[NSString stringWithFormat:@"%@",[[series objectAtIndex:i] valueForKeyPath: @"id"]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_images_count%" withString:[NSString stringWithFormat:@"%d",imagesCount] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempSeriesList appendString:tempListItemTemplate];
			imagesCount = 0;
			
			if(i==[series count]-1)
				lastImageOfStudy = YES;
			else if([[[series objectAtIndex:i] valueForKeyPath: @"study.studyInstanceUID"] intValue] != [[[series objectAtIndex:i+1] valueForKeyPath: @"study.studyInstanceUID"] intValue])
				lastImageOfStudy = YES;
			else if([[series objectAtIndex:i] valueForKeyPath: @"study.studyName"] != [[series objectAtIndex:i+1] valueForKeyPath: @"study.studyName"])
				lastImageOfStudy = YES;
			else
				lastImageOfStudy = NO;
				
			if(lastImageOfStudy)
			{			
				tempStudyBlockStart = [NSMutableString stringWithString:studyBlockStart];
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_name%" withString:[[series objectAtIndex:i] valueForKeyPath:@"study.studyName"] options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				studyDate = [[[series objectAtIndex:i] valueForKeyPath:@"study.date"] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString] timeZone:0L locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
				studyTime = [[[series objectAtIndex:i] valueForKeyPath:@"study.date"] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString] timeZone:0L locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
				
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_date%" withString:studyDate options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_time%" withString:studyTime options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
				[tempStudyBlockStart replaceOccurrencesOfString:@"%study_i_id%" withString:[[series objectAtIndex:i] valueForKeyPath:@"study.id"] options:NSLiteralSearch range:NSMakeRange(0, [tempStudyBlockStart length])];
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
	[fileManager createFileAtPath:[rootPath stringByAppendingString:@"/index.html"] contents:[htmlContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

- (void)createHTMLStudiesList;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSEnumerator *enumerator = [patientsDictionary objectEnumerator];
	id series;
	NSMutableString *seriesName;
	int i =0;
	while (series = [enumerator nextObject])
	{
		i++;
		seriesName = [NSMutableString stringWithString:[[series objectAtIndex:0] valueForKeyPath: @"study.name"]];
		[seriesName replaceOccurrencesOfString:@"/" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [seriesName length])];
		NSString *htmlContent = [self fillStudiesListTemplatesForSeries:series];
		[fileManager createFileAtPath:[rootPath stringByAppendingFormat:@"/%@/index.html",seriesName] contents:[htmlContent dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
	}
}

- (void)createHTMLExtraDirectory;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *htmlExtraDirectory = [documentsDirectory() stringByAppendingString:@"/HTML_TEMPLATES/html-extra/"];
	NSArray *directoryContent = [fileManager subpathsAtPath:htmlExtraDirectory];
	if([directoryContent count])
		[fileManager copyPath:htmlExtraDirectory toPath:[rootPath stringByAppendingString:@"/html-extra/"] handler:NO];
}

#pragma mark-
#pragma mark setters

- (void)setPath:(NSString*)path
{
	rootPath = path;
}

- (void)setPatientsDictionary:(NSDictionary*)dictionary;
{
	patientsDictionary = dictionary;
}

@end
