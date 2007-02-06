/*
 *  SafeDBRebuild.c
 *  OsiriX
 *
 *  Created by Antoine Rosset on 22.05.06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#include "SafeDBRebuild.h"
#include "DicomFile.h"
#include "BrowserController.h"
#import <OsiriX/DCMCalendarDate.h>

NSLock	*PapyrusLock = 0L;
NSMutableDictionary *fileFormatPlugins = 0L;

NSMutableArray			*preProcessPlugins = 0L;
NSMutableDictionary		*reportPlugins = 0L;
NSMutableDictionary		*plugins = 0L, *pluginsDict = 0L;
NSThread				*mainThread = 0L;
BOOL					NEEDTOREBUILD = NO;
NSMutableDictionary		*DATABASECOLUMNS = 0L;
short					Altivec = 0;

#if __ppc__
// ALTIVEC FUNCTIONS
void InverseLongs(register vector unsigned int *unaligned_input, register long size)
{
	register long						i = size / 4;
	register vector unsigned char		identity = vec_lvsl(0, (int*) NULL );
	register vector unsigned char		byteSwapLongs = vec_xor( identity, vec_splat_u8(sizeof( long )- 1 ) );
	
	while(i-- > 0)
	{
		*unaligned_input++ = vec_perm( *unaligned_input, *unaligned_input, byteSwapLongs);
	}
}

void InverseShorts( register vector unsigned short *unaligned_input, register long size)
{
	register long						i = size / 8;
	register vector unsigned char		identity = vec_lvsl(0, (int*) NULL );
	register vector unsigned char		byteSwapShorts = vec_xor( identity, vec_splat_u8(sizeof( short) - 1) );
	
	while(i-- > 0)
	{
		*unaligned_input++ = vec_perm( *unaligned_input, *unaligned_input, byteSwapShorts);
	}
}
#endif

NSString* convertDICOM( NSString *inputfile)
{
	return inputfile;
}

void addFilesToDatabaseSafe(NSArray* newFilesArray, NSManagedObjectContext* context, NSManagedObjectModel* model, NSString* INpath, BOOL COMMENTSAUTOFILL)
{
	NSString				*curPatientUID = 0L, *curStudyID = 0L, *curSerieID = 0L;
	NSEnumerator			*enumerator = [newFilesArray objectEnumerator];
	long					ii, i, x;
	NSString				*newFile;
	unsigned long			index;
	NSError					*error = 0L;
	BOOL					addFailed = NO;
	NSManagedObject			*image, *seriesTable, *study, *album;
	NSDate					*today = [NSDate date];
	
	
	[context lock];
	
	[context setStalenessInterval: 120];
	
	// Find all current studies
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = 0L;
	NSArray *studiesArray;
	@try
	{
		studiesArray = [[context executeFetchRequest:dbRequest error:&error] retain];
	}
	@catch( NSException *ne)
	{
		NSLog(@"exception: %@", [ne description]);
		NSLog(@"executeFetchRequest failed for studiesArray.");
		error = [NSError errorWithDomain:@"OsiriXDomain" code:1 userInfo: 0L];
	}
	if (error)
	{
		NSLog( @"addFilesToDatabase ERROR: %@", [error localizedDescription]);
		
		[context unlock];
		
		//All these files were NOT saved..... due to an error. Move them back to the INCOMING folder.
		addFailed = YES;
	}
	else
	{
		// Add the new files
		while (newFile = [enumerator nextObject])
		{
			@try
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				DicomFile		*curFile = 0L;
				NSDictionary	*curDict = 0L;
				
				curFile = [[DicomFile alloc] init: newFile];
				
				if(curFile == 0L && [[newFile pathExtension] isEqualToString:@"zip"] == YES)
				{
					NSString *filePathWithoutExtension = [newFile stringByDeletingPathExtension];
					NSString *xmlFilePath = [filePathWithoutExtension stringByAppendingString:@".xml"];
					
					if([[NSFileManager defaultManager] fileExistsAtPath:xmlFilePath])
					{
						NSLog(@"read the xml data");
						NSLog(@"xmlFilePath : %@", xmlFilePath);
						NSLog(@"newFile : %@", newFile);
						curFile = [[DicomFile alloc] initWithXMLDescriptor:xmlFilePath path:newFile];
						NSLog(@"xml data OK");
					}
				}
				
				if( curFile)
				{
					curDict = [[curFile dicomElements] retain];
					[curFile release];
					curFile = 0L;
				}
				else curDict = [curDict retain];
				
				if( curDict != 0L)
				{
//					if( 0)
					{
						if( [[curDict objectForKey: @"studyID"] isEqualToString: curStudyID] == YES && [[curDict objectForKey: @"patientUID"] isEqualToString: curPatientUID] == YES)
						{
							
						}
						else
						{
							/*******************************************/
							/*********** Find study object *************/
							index = [[studiesArray  valueForKey:@"studyInstanceUID"] indexOfObject:[curDict objectForKey: @"studyID"]];
							if( index == NSNotFound)
							{
								// Fields
								study = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:context];
								[study setValue:today forKey:@"dateAdded"];
							
								[study setValue:[curDict objectForKey: @"studyID"] forKey:@"studyInstanceUID"];
								[study setValue:[curDict objectForKey: @"studyDescription"] forKey:@"studyName"];
								[study setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
								[study setValue:[curDict objectForKey: @"accessionNumber"] forKey:@"accessionNumber"];
							
								DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[curDict objectForKey: @"studyDate"]];
								[study setValue:[time timeAsNumber] forKey:@"dicomTime"];
							
								[study setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								[study setValue:[curDict objectForKey: @"patientBirthDate"] forKey:@"dateOfBirth"];
								[study setValue:[curDict objectForKey: @"patientSex"] forKey:@"patientSex"];
								[study setValue:[curDict objectForKey: @"referringPhysiciansName"] forKey:@"referringPhysician"];
								[study setValue:[curDict objectForKey: @"performingPhysiciansName"] forKey:@"performingPhysician"];
								[study setValue:[curDict objectForKey: @"institutionName"] forKey:@"institutionName"];
							
								[study setValue:[curDict objectForKey: @"patientID"] forKey:@"patientID"];
								[study setValue:[curDict objectForKey: @"patientName"] forKey:@"name"];
								[study setValue:[curDict objectForKey: @"patientUID"] forKey:@"patientUID"];
								[study setValue:[curDict objectForKey: @"studyNumber"] forKey:@"id"];
								[study setValue:[curDict objectForKey: @"studyComment"] forKey:@"comment"];
							
								//need to know if is DICOM so only DICOM is queried for Q/R
								if ([curDict objectForKey: @"hasDICOM"])
									[study setValue:[curDict objectForKey: @"hasDICOM"] forKey:@"hasDICOM"];
								
								NSArray	*newStudiesArray = [studiesArray arrayByAddingObject: study];
								[studiesArray release];
								studiesArray = [newStudiesArray retain];
								
								[curSerieID release];	curSerieID = 0L;
								
							}
							else
							{
								study = [studiesArray objectAtIndex: index];
								[study setValue:today forKey:@"dateAdded"];
							}
							
							[curStudyID release];			curStudyID = [[curDict objectForKey: @"studyID"] retain];
							[curPatientUID release];		curPatientUID = [[curDict objectForKey: @"patientUID"] retain];
						}
						
						long NoOfSeries = [[curDict objectForKey: @"numberOfSeries"] intValue];
						for(i = 0; i < NoOfSeries; i++)
						{
							NSString* SeriesNum;
							if (i)
								SeriesNum = [NSString stringWithFormat:@"%d",i];
							else
								SeriesNum = @"";
							
							if( [[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]] isEqualToString: curSerieID])
							{
							}
							else
							{
								/********************************************/
								/*********** Find series object *************/
								
								NSArray		*seriesArray = [[study valueForKey:@"series"] allObjects];
								
								//NSLog([curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]]);
								
								index = [[seriesArray valueForKey:@"seriesInstanceUID"] indexOfObject:[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]]];
								if( index == NSNotFound)
								{
									// Fields
									seriesTable = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext:context];
									[seriesTable setValue:today forKey:@"dateAdded"];
									
									if( [curDict objectForKey: @"seriesDICOMUID"]) [seriesTable setValue:[curDict objectForKey: @"seriesDICOMUID"] forKey:@"seriesDICOMUID"];
									if( [curDict objectForKey: @"SOPClassUID"]) [seriesTable setValue:[curDict objectForKey: @"SOPClassUID"] forKey:@"seriesSOPClassUID"];
									[seriesTable setValue:[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]] forKey:@"seriesInstanceUID"];
									[seriesTable setValue:[curDict objectForKey: [@"seriesDescription" stringByAppendingString:SeriesNum]] forKey:@"name"];
									[seriesTable setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
									[seriesTable setValue:[curDict objectForKey: [@"seriesNumber" stringByAppendingString:SeriesNum]] forKey:@"id"];
									[seriesTable setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
									[seriesTable setValue:[curDict objectForKey: @"protocolName"] forKey:@"seriesDescription"];
									
									DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[curDict objectForKey: @"studyDate"]];
									[seriesTable setValue:[time timeAsNumber] forKey:@"dicomTime"];
									
									// Relations
									[seriesTable setValue:study forKey:@"study"];
								}
								else
								{
									seriesTable = [seriesArray objectAtIndex: index];
									[seriesTable setValue:today forKey:@"dateAdded"];
								}
								
								[curSerieID release];
								curSerieID = [[curDict objectForKey: @"seriesID"] retain];
							}
							
							/*******************************************/
							/*********** Find image object *************/
							
							BOOL			iPod = NO, local = NO;
							if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
							{
								local = YES;
							}
							
							NSArray		*imagesArray = [[seriesTable valueForKey:@"images"] allObjects] ;
							
							index = [[imagesArray valueForKey:@"sopInstanceUID"] indexOfObject:[curDict objectForKey: [@"SOPUID" stringByAppendingString:SeriesNum]]];
							if( index != NSNotFound)
							{
								image = [imagesArray objectAtIndex: index];
							}
							
							if( index == NSNotFound)
							{
								image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
								[image setValue:[curDict objectForKey: [@"imageID" stringByAppendingString:SeriesNum]] forKey:@"instanceNumber"];
//								[image setValue:[[curDict objectForKey: [@"imageID" stringByAppendingString:SeriesNum]] stringValue] forKey:@"name"];
								[image setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								
								if( local) [image setValue: [newFile lastPathComponent] forKey:@"path"];
								else [image setValue:newFile forKey:@"path"];
								
								[image setValue:[NSNumber numberWithBool:iPod] forKey:@"iPod"];
								[image setValue:[NSNumber numberWithBool:local] forKey:@"inDatabaseFolder"];
								
								[image setValue:[curDict objectForKey: @"studyDate"]  forKey:@"date"];
								DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[curDict objectForKey: @"studyDate"]];
								[image setValue:[time timeAsNumber] forKey:@"dicomTime"];
								
								[image setValue:[curDict objectForKey: [@"SOPUID" stringByAppendingString:SeriesNum]] forKey:@"sopInstanceUID"];
								[image setValue:[curDict objectForKey: @"sliceLocation"] forKey:@"sliceLocation"];
								[image setValue:[[newFile pathExtension] lowercaseString] forKey:@"extension"];
								[image setValue:[curDict objectForKey: @"fileType"] forKey:@"fileType"];
								
								[image setValue:[curDict objectForKey: @"height"] forKey:@"height"];
								[image setValue:[curDict objectForKey: @"width"] forKey:@"width"];
								[image setValue:[curDict objectForKey: @"numberOfFrames"] forKey:@"numberOfFrames"];
								[image setValue:[NSNumber numberWithBool: NO] forKey:@"mountedVolume"];
								[image setValue:[curDict objectForKey: @"numberOfSeries"] forKey:@"numberOfSeries"];
							
								[seriesTable setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
								[study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
								[seriesTable setValue: 0L forKey:@"thumbnail"];
								
								// Relations
								[image setValue:seriesTable forKey:@"series"];
								
								if( COMMENTSAUTOFILL)
								{
									if([curDict objectForKey: @"commentsAutoFill"])
									{
										[seriesTable setValue:[curDict objectForKey: @"commentsAutoFill"] forKey:@"comment"];
										
										if( [study valueForKey:@"comment"] == 0L || [[study valueForKey:@"comment"] isEqualToString:@""])
										{
											[study setValue:[curDict objectForKey: @"commentsAutoFill"] forKey:@"comment"];
										}
									}
								}
								
								if([curDict valueForKey:@"album"] !=nil)
								{
									//Find all albums
									NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
									[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Album"]];
									[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
									error = 0L;
									NSArray *albumArray = [context executeFetchRequest:dbRequest error:&error];
									
									NSManagedObject *album = nil;
									int i;
									for(i=0 ; i<[albumArray count] ; i++)
									{
										if([[[albumArray objectAtIndex: i] valueForKeyPath:@"name"]
												isEqualToString: [curDict valueForKey:@"album"]])
										{
											album = [albumArray objectAtIndex: i];
										}
									}
									
									if (album == nil)
									{
//										NSString *name = [curDict valueForKey:@"album"];
//										album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
//										[album setValue:name forKey:@"name"];
										
										for(i=0 ; i<[albumArray count] ; i++)
										{
											if([[[albumArray objectAtIndex: i] valueForKeyPath:@"name"] isEqualToString: @"other"])
											{
												album = [albumArray objectAtIndex: i];
											}
										}
										
										if (album == nil)
										{
											album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
											[album setValue:@"other" forKey:@"name"];
										}
									}
									
									// add the file to the album
									if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
									{
										NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];	
										[studies addObject: [image valueForKeyPath:@"series.study"]];
									}
								}
							}
						}
					}
					[curFile release];
					
					[curDict release];
					curDict = 0L;
				}
				[pool release];
			}
			
			@catch( NSException *ne)
			{
				NSLog(@"exception: %@", [ne description]);
				NSLog(@"Parser failed for this file: %@", newFile);
			}
		}
	
		[studiesArray release];
		
		[curPatientUID release];
		[curStudyID release];
		[curSerieID release];
		
		[context unlock];
	}
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
		
	#if __ppc__
	Altivec = 1;
	#endif
	
	Papy3Init();
	
//	argv[ 1] : array
//	argv[ 2] : database path
//	argv[ 3] : model path
	
	if( argv[ 1] && argv[ 2] && argv[ 3])
	{
		NSManagedObjectModel		*model;
		NSManagedObjectContext		*context;
		BOOL						COMMENTSAUTOFILL;
		
		NSString					*f = [NSString stringWithCString:argv[ 1]];
		NSString					*p = [NSString stringWithCString:argv[ 2]];
		NSString					*m = [NSString stringWithCString:argv[ 3]];
		
		NSLog( @"Start Process");
		
		NSArray	*newFilesArray = [NSArray arrayWithContentsOfFile: f];

		NSString *INpath = [NSString stringWithContentsOfFile: p];
		
		// Preferences
		NSDictionary	*dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"];
		COMMENTSAUTOFILL = [[dict objectForKey: @"COMMENTSAUTOFILL"] intValue];
		
		// Context & Model
		
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [NSString stringWithContentsOfFile: m]]];
		
		
		NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
		context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator: coordinator];
	
		NSURL *url = [NSURL fileURLWithPath: [[INpath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/Database.sql"]];
		
		NSError *error = 0L;
		if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
		{
			NSLog( [error localizedDescription]);
		}
		[coordinator release];
		
		addFilesToDatabaseSafe( newFilesArray ,context ,model ,INpath ,COMMENTSAUTOFILL);
//		[BrowserController addFilesToDatabaseSafe: newFilesArray context: context model: model databasePath:INpath COMMENTSAUTOFILL: COMMENTSAUTOFILL];
		
		error = 0L;
		[context save: &error];
		
		[model release];
		[context release];
	}
	
	NSLog( @"End Process");
	
	[pool release];
	
	return 0;
}
