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

#import "QTExportHTMLSummary.h"
#import "AppController.h"
#import "BrowserController.h"
#import "DCMAbstractSyntaxUID.h"
#import "NSDictionary+N2.h"

@implementation QTExportHTMLSummary

@synthesize imagePathsDictionary;

+(NSString*)nonNilString:(NSString*)aString;
{
	return (!aString)? @"" : aString;
}

- (id)init;
{
	if (![super init])
		return nil;
	
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
	self.imagePathsDictionary = NULL;
	
	[super dealloc];
}

#pragma mark-
#pragma mark HTML template

- (void)readTemplates;
{
	[AppController checkForHTMLTemplates];
	patientsListTemplate = [[NSString stringWithContentsOfFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportPatientsTemplate.html"]] retain];
	[AppController checkForHTMLTemplates];
	examsListTemplate = [[NSString stringWithContentsOfFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportStudiesTemplate.html"]] retain];
	[AppController checkForHTMLTemplates];
	seriesTemplate = [[NSString stringWithContentsOfFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/HTML_TEMPLATES/QTExportSeriesTemplate.html"]] retain];
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

+(NSString*)kindOfPath:(NSString*)path forSeriesId:(int)seriesId inSeriesPaths:(NSDictionary*)seriesPaths {
	NSNumber* seriesIdK = [NSNumber numberWithInt:seriesId];
	NSDictionary* pathsForSeries = [seriesPaths objectForKey:seriesIdK];
	return [pathsForSeries keyForObject:path];
}

-(NSString*)imagePathForSeriesId:(int)seriesId kind:(NSString*)kind relativeTo:(NSString*)passedRootPath {
	// TODO: find and remove from dict and return corresponding item
	if (imagePathsDictionary) {
		NSNumber* seriesIdK = [NSNumber numberWithInt:seriesId];

		NSMutableDictionary* pathsForSeries = [imagePathsDictionary objectForKey:seriesIdK];
		if (!pathsForSeries)
			return NULL;
		
		return [passedRootPath stringByAppendingPathComponent:[pathsForSeries objectForKey:kind]];
	}
	
	return NULL;
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
	
	NSMutableString *fileName, *thumbnailName, *htmlName;
	NSString *studyDate, *studyTime, *seriesName;
	NSString *extension;

	BOOL lastImageOfSeries, lastImageOfStudy;
	lastImageOfSeries = lastImageOfStudy = NO;
	
	uniqueSeriesID = 0;
	
	for(i=0; i<[series count]; i++)
	{
		imagesCount++;
		if( i == [series count]-1)
			lastImageOfSeries = YES;
		else if([[[series objectAtIndex:i] valueForKey: @"id"] intValue] != [[[series objectAtIndex:i+1] valueForKey: @"id"] intValue])
			lastImageOfSeries = YES;
		else if([[[series objectAtIndex:i] valueForKey: @"seriesInstanceUID"] isEqualToString: [[series objectAtIndex:i+1] valueForKey: @"seriesInstanceUID"]] == NO)
			lastImageOfSeries = YES;
		else if( [[[series objectAtIndex:i] valueForKeyPath: @"study.id"] isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.id"]] == NO || [[[series objectAtIndex:i] valueForKeyPath: @"study.patientUID"] isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.patientUID"]] == NO)
			lastImageOfSeries = YES;
		else
			lastImageOfSeries = NO;
		
		if( lastImageOfSeries)
		{
			uniqueSeriesID++;
			
			seriesName = asciiString( [BrowserController replaceNotAdmitted: [NSMutableString stringWithString:[[series objectAtIndex:i] valueForKey: @"name"]]]);
			fileName = [BrowserController replaceNotAdmitted: [NSMutableString stringWithFormat:@"%@ - %@", asciiString( [[series objectAtIndex:i] valueForKeyPath:@"study.studyName"]), [[series objectAtIndex:i] valueForKeyPath:@"study.id"]]];
			NSString* iId = [[series objectAtIndex:i] valueForKey: @"id"];
			[fileName appendFormat:@"/%@_%@", seriesName, iId];
			
			[fileName appendFormat: @"_%d", uniqueSeriesID];
			
			thumbnailName = [[[self imagePathForSeriesId:[iId intValue] kind:@"thumb" relativeTo:rootPath] mutableCopy] autorelease];
			if (!thumbnailName) thumbnailName = [NSMutableString stringWithFormat:@"%@_thumb.jpg", fileName];
			
			htmlName = [NSMutableString stringWithFormat:@"%@.html", fileName];
			
			tempListItemTemplate = [NSMutableString stringWithString:listItemTemplate];
			extension = (imagesCount>1)? @"mov": @"jpg";
			
			if( [DCMAbstractSyntaxUID isPDF: [[series objectAtIndex:i] valueForKey: @"seriesSOPClassUID"]])
			{
				extension = @"pdf";
				NSString* tempPdfPath = [[[self imagePathForSeriesId:[iId intValue] kind:extension relativeTo:rootPath] mutableCopy] autorelease];
				if (tempPdfPath)
					[fileName setString:tempPdfPath];
				else [fileName appendFormat:@".%@",extension];
				[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_file%" withString:[QTExportHTMLSummary nonNilString: fileName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			
			}
			else
			{
				NSString* tempXXXPath = [self imagePathForSeriesId:[iId intValue] kind:extension relativeTo:rootPath];
				if (tempXXXPath)
					[fileName setString:tempXXXPath];
				else [fileName appendFormat:@".%@",extension];
				[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_file%" withString:[QTExportHTMLSummary nonNilString:htmlName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			}

			
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_thumbnail%" withString:[QTExportHTMLSummary nonNilString:thumbnailName] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_name%" withString:[QTExportHTMLSummary nonNilString: [[series objectAtIndex:i] valueForKey: @"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_id%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%@",[[series objectAtIndex:i] valueForKey: @"id"]]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempListItemTemplate replaceOccurrencesOfString:@"%series_i_images_count%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%d",imagesCount]] options:NSLiteralSearch range:NSMakeRange(0, [tempListItemTemplate length])];
			[tempSeriesList appendString:tempListItemTemplate];
			
			if( [extension isEqualToString: @"pdf"] == NO)
				[self createHTMLSeriesPage:[series objectAtIndex:i] numberOfImages:imagesCount outPutFileName:htmlName];
			
			imagesCount = 0;
			
			if(i==[series count]-1)
				lastImageOfStudy = YES;
			else if([[[series objectAtIndex:i] valueForKeyPath: @"study.studyInstanceUID"] isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.studyInstanceUID"]] == NO)
				lastImageOfStudy = YES;
			else if([[[series objectAtIndex:i] valueForKeyPath: @"study.patientUID"] isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.patientUID"]] == NO)
				lastImageOfStudy = YES;
			else if([[[series objectAtIndex:i] valueForKeyPath: @"study.studyName"]isEqualToString: [[series objectAtIndex:i+1] valueForKeyPath: @"study.studyName"]] == NO)
				lastImageOfStudy = YES;
			else
				lastImageOfStudy = NO;
				
			if(lastImageOfStudy)
			{
				uniqueSeriesID = 0;
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

+ (void) getMovieWidth: (int*) width height: (int*) height imagesArray: (NSArray*) imagesArray
{
	*width = 0;
	*height = 0;
	
	for( NSNumber *im in [imagesArray valueForKey: @"width"])
		if( [im intValue] > *width) *width = [im intValue];
	
	for( NSNumber *im in [imagesArray valueForKey:@"height"])
		if( [im intValue] > *height) *height = [im intValue];
	
	int maxWidth = 800, maxHeight = 800;
	int minWidth = 400, minHeight = 400;
	
	if( *width > maxWidth)
	{
		*height = *height * maxWidth / *width;
		*width = maxWidth;
	}
	
	if( *width < minWidth)
	{
		*height = *height * minWidth / *width;
		*width = minWidth;
	}
	
	if( *height > maxHeight)
	{
		*width = *width * maxHeight / *height;
		*height = maxHeight;
	}
	
	if( *height < minHeight)
	{
		*width = *width * minHeight / *height;
		*height = minHeight;
	}
}

- (NSString*)fillSeriesTemplatesForSeries:(NSManagedObject*)series numberOfImages:(int)imagesCount;
{
	NSString* seriesId = [series valueForKeyPath:@"id"];
	
	NSMutableString *tempHTML = [NSMutableString stringWithString:seriesTemplate];
	
	[tempHTML replaceOccurrencesOfString:@"%series_name%" withString:[QTExportHTMLSummary nonNilString:[series valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%patient_name%" withString:[QTExportHTMLSummary nonNilString:[series valueForKeyPath:@"study.name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%patient_dateOfBirth%" withString:[QTExportHTMLSummary nonNilString:[dateFormat stringFromDate: [series valueForKeyPath:@"study.dateOfBirth"] ]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%series_name%" withString:[QTExportHTMLSummary nonNilString:[series valueForKey:@"name"]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%series_id%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%@",[series valueForKey: @"id"]]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%series_images_count%" withString:[QTExportHTMLSummary nonNilString:[NSString stringWithFormat:@"%d", imagesCount]] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	
	NSMutableString *seriesStr = [NSMutableString stringWithString: asciiString( [series valueForKey: @"name"])];
	[BrowserController replaceNotAdmitted: seriesStr];
			
	NSMutableString *fileName = [NSMutableString stringWithFormat:@"./%@_%@", seriesStr, [series valueForKey: @"id"]];
	
	[fileName appendFormat: @"_%d", uniqueSeriesID];
	
	NSString *extension = (imagesCount>1)? @"mov": @"jpg";
	
	NSString* tempXXXPath = [self imagePathForSeriesId:[seriesId intValue] kind:extension relativeTo:rootPath];
	if (tempXXXPath)
		[fileName setString:tempXXXPath];
	else [fileName appendFormat:@".%@",extension];
	
	[tempHTML replaceOccurrencesOfString:@"%series_file_path%" withString:[QTExportHTMLSummary nonNilString:fileName] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
	[tempHTML replaceOccurrencesOfString:@"%footer_string%" withString:footerString options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];

	NSArray *components;
	
	if( imagesCount > 1 && [[[series valueForKeyPath: @"images.width"] allObjects] count] > 0)
	{
		[tempHTML replaceOccurrencesOfString:@"%series_mov%" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		
		int width, height;
		
		[QTExportHTMLSummary getMovieWidth: &width height: &height imagesArray: [[series valueForKey: @"images"] allObjects]];
		
		[tempHTML replaceOccurrencesOfString:@"%width%" withString: [NSString stringWithFormat:@"%d", width] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])];
		[tempHTML replaceOccurrencesOfString:@"%height%" withString: [NSString stringWithFormat:@"%d", height + 15] options:NSLiteralSearch range:NSMakeRange(0, [tempHTML length])]; // +15 is for the movie's controller
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
	[[[BrowserController currentBrowser] managedObjectContext] lock];

	[self createHTMLPatientsList];
	[self createHTMLStudiesList];
	[self createHTMLExtraDirectory];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
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
	NSString *htmlExtraDirectory = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"/HTML_TEMPLATES/html-extra/"];
	//if([directoryContent count])
	[fileManager copyPath:htmlExtraDirectory toPath:[rootPath stringByAppendingPathComponent:@"/html-extra/"] handler:NO];
}

- (void)createHTMLSeriesPage:(NSManagedObject*)series numberOfImages:(int)imagesCount outPutFileName:(NSString*)fileName;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *htmlContent = [self fillSeriesTemplatesForSeries:series numberOfImages:imagesCount];
	NSString *patientName = asciiString([NSMutableString stringWithString:[series valueForKeyPath: @"study.name"]]);
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
