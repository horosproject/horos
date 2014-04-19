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

#import "DicomStudy.h"
#import "DicomStudy+Report.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DicomAlbum.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCM.h>
#import "MutableArrayCategory.h"
#import "SRAnnotation.h"
#import "DicomDatabase.h"
#import "N2Debug.h"
#import "N2Stuff.h"

#ifdef OSIRIX_VIEWER
#import "DCMView.h"
#import "DCMPix.h"
#import "VRController.h"
#import "browserController.h"
#import "BonjourBrowser.h"
#import "DicomFileDCMTKCategory.h"
#import "DICOMToNSString.h"
#import "XMLControllerDCMTKCategory.h"
#import "Notifications.h"
#import "SRAnnotation.h"
#import "NSFileManager+N2.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "WebPortalUser.h"
#import "WebPortal.h"
#import "WebPortalDatabase.h"
#import "DICOMExport.h"
#endif

#define WBUFSIZE 512

NSString* soundex4( NSString *inString)
{
	char *p, *p1;
	int i;
	char workbuf[WBUFSIZE + 1];
	char priorletter;
	
	if( inString == nil) return nil;
	
      /* Make a working copy  */
	
      strncpy(workbuf, [[inString uppercaseString] UTF8String], WBUFSIZE);
      workbuf[WBUFSIZE] = 0;
	  
      /* Convert all vowels to 'A'  */

      for (p = workbuf; *p; ++p)
      {
            if (strchr("AEIOUY", *p))
                  *p = 'A';
      }

      /* Prefix transformations: done only once on the front of a name */

      if ( 0 == strncmp(workbuf, "MAC", 3))     /* MAC to MCC    */
            workbuf[1] = 'C';
      else if ( 0 == strncmp(workbuf, "KN", 2)) /* KN to NN      */
            workbuf[0] = 'N';
      else if ('K' == workbuf[0])                     /* K to C        */
            workbuf[0] = 'C';
      else if ( 0 == strncmp(workbuf, "PF", 2)) /* PF to FF      */
            workbuf[0] = 'F';
      else if ( 0 == strncmp(workbuf, "SCH", 3))/* SCH to SSS    */
            workbuf[1] = workbuf[2] = 'S';

      /*
      ** Infix transformations: done after the first letter,
      ** left to right
      */

      while ((p = strstr(workbuf, "DG")) > workbuf)   /* DG to GG      */
            p[0] = 'G';
      while ((p = strstr(workbuf, "CAAN")) > workbuf) /* CAAN to TAAN  */
            p[0] = 'T';
      while ((p = strchr(workbuf, 'D')) > workbuf)    /* D to T        */
            p[0] = 'T';
      while ((p = strstr(workbuf, "NST")) > workbuf)  /* NST to NSS    */
            p[2] = 'S';
      while ((p = strstr(workbuf, "AV")) > workbuf)   /* AV to AF      */
            p[1] = 'F';
      while ((p = strchr(workbuf, 'Q')) > workbuf)    /* Q to G        */
            p[0] = 'G';
      while ((p = strchr(workbuf, 'Z')) > workbuf)    /* Z to S        */
            p[0] = 'S';
      while ((p = strchr(workbuf, 'M')) > workbuf)    /* M to N        */
            p[0] = 'N';
      while ((p = strstr(workbuf, "KN")) > workbuf)   /* KN to NN      */
            p[0] = 'N';
      while ((p = strchr(workbuf, 'K')) > workbuf)    /* K to C        */
            p[0] = 'C';
      while ((p = strstr(workbuf, "AH")) > workbuf)   /* AH to AA      */
            p[1] = 'A';
      while ((p = strstr(workbuf, "HA")) > workbuf)   /* HA to AA      */
            p[0] = 'A';
      while ((p = strstr(workbuf, "AW")) > workbuf)   /* AW to AA      */
            p[1] = 'A';
      while ((p = strstr(workbuf, "PH")) > workbuf)   /* PH to FF      */
            p[0] = p[1] = 'F';
      while ((p = strstr(workbuf, "SCH")) > workbuf)  /* SCH to SSS    */
            p[0] = p[1] = 'S';

      /*
      ** Suffix transformations: done on the end of the word,
      ** right to left
      */

      /* (1) remove terminal 'A's and 'S's      */

      for (i = strlen(workbuf) - 1;
            (i > 0) && ('A' == workbuf[i] || 'S' == workbuf[i]);
            --i)
      {
            workbuf[i] = 0;
      }

      /* (2) terminal NT to TT      */

      for (i = strlen(workbuf) - 1;
            (i > 1) && ('N' == workbuf[i - 1] || 'T' == workbuf[i]);
            --i)
      {
            workbuf[i - 1] = 'T';
      }

      /* Now strip out all the vowels except the first     */

      p = p1 = workbuf;
      while ( 0 != (*p1++ = *p++))
      {
            while ('A' == *p)
                  ++p;
      }

      /* Remove all duplicate letters     */

      p = p1 = workbuf;
      priorletter = 0;
      do {
            while (*p == priorletter)
                  ++p;
            priorletter = *p;
      } while (0 != (*p1++ = *p++));

      /* Finish up */
	
	  return [NSString stringWithUTF8String: workbuf];
}

@implementation DicomStudy

@dynamic accessionNumber;
@dynamic comment, comment2, comment3, comment4;
@dynamic date;
@dynamic dateAdded;
@dynamic dateOfBirth;
@dynamic dateOpened;
@dynamic dictateURL;
@dynamic expanded;
@dynamic hasDICOM;
@dynamic id;
@dynamic institutionName;
@dynamic lockedStudy;
@dynamic modality;
@dynamic name;
@dynamic numberOfImages;
@dynamic patientID;
@dynamic patientSex;
@dynamic patientUID;
@dynamic performingPhysician;
@dynamic referringPhysician;
@dynamic reportURL;
@dynamic stateText;
@dynamic studyInstanceUID;
@dynamic studyName;
@dynamic windowsState;
@dynamic albums;
@dynamic series;


static NSRecursiveLock *dbModifyLock = nil;

+ (NSRecursiveLock*) dbModifyLock
{
	if( dbModifyLock == nil)
		dbModifyLock = [[NSRecursiveLock alloc] init];
		
	return dbModifyLock;
}

+ (NSString*) soundex: (NSString*) s
{
	NSArray *a = [s componentsSeparatedByString:@" "];
	NSMutableString *r = [NSMutableString string];
	
	for( NSString *w in a)
		[r appendFormat:@" %@", soundex4( w)];
	
	return r;
}

+ (NSString*) scrambleString: (NSString*) t
{
    static NSMutableArray *v = nil;
    
    if( v == nil)
    {
        v = [[NSMutableArray arrayWithObjects: @"A", @"E", @"I", @"O", @"U", @"Y", @"R", @"F", @"N", @"M", @"P", @"L", @"S", @"D", @"B", @"C", nil] retain];
        
        for (int i = [v count]; i > 1; i--)
            [v exchangeObjectAtIndex:i-1 withObjectAtIndex:random()%i];
    }
    
    t = [t stringByReplacingOccurrencesOfString: @"A" withString: [v objectAtIndex: 0]];
    t = [t stringByReplacingOccurrencesOfString: @"E" withString: [v objectAtIndex: 1]];
    t = [t stringByReplacingOccurrencesOfString: @"I" withString: [v objectAtIndex: 2]];
    t = [t stringByReplacingOccurrencesOfString: @"O" withString: [v objectAtIndex: 3]];
    t = [t stringByReplacingOccurrencesOfString: @"U" withString: [v objectAtIndex: 4]];
    t = [t stringByReplacingOccurrencesOfString: @"Y" withString: [v objectAtIndex: 5]];
    t = [t stringByReplacingOccurrencesOfString: @"R" withString: [v objectAtIndex: 6]];
    t = [t stringByReplacingOccurrencesOfString: @"F" withString: [v objectAtIndex: 7]];
    t = [t stringByReplacingOccurrencesOfString: @"N" withString: [v objectAtIndex: 8]];
    t = [t stringByReplacingOccurrencesOfString: @"M" withString: [v objectAtIndex: 9]];
    t = [t stringByReplacingOccurrencesOfString: @"P" withString: [v objectAtIndex: 10]];
    t = [t stringByReplacingOccurrencesOfString: @"L" withString: [v objectAtIndex: 11]];
    t = [t stringByReplacingOccurrencesOfString: @"S" withString: [v objectAtIndex: 12]];
    t = [t stringByReplacingOccurrencesOfString: @"D" withString: [v objectAtIndex: 13]];
    t = [t stringByReplacingOccurrencesOfString: @"B" withString: [v objectAtIndex: 14]];
    t = [t stringByReplacingOccurrencesOfString: @"C" withString: [v objectAtIndex: 15]];
    
    t = [t stringByReplacingOccurrencesOfString: @"a" withString: [v objectAtIndex: 0]];
    t = [t stringByReplacingOccurrencesOfString: @"e" withString: [v objectAtIndex: 1]];
    t = [t stringByReplacingOccurrencesOfString: @"i" withString: [v objectAtIndex: 2]];
    t = [t stringByReplacingOccurrencesOfString: @"o" withString: [v objectAtIndex: 3]];
    t = [t stringByReplacingOccurrencesOfString: @"u" withString: [v objectAtIndex: 4]];
    t = [t stringByReplacingOccurrencesOfString: @"y" withString: [v objectAtIndex: 5]];
    t = [t stringByReplacingOccurrencesOfString: @"r" withString: [v objectAtIndex: 6]];
    t = [t stringByReplacingOccurrencesOfString: @"f" withString: [v objectAtIndex: 7]];
    t = [t stringByReplacingOccurrencesOfString: @"n" withString: [v objectAtIndex: 8]];
    t = [t stringByReplacingOccurrencesOfString: @"m" withString: [v objectAtIndex: 9]];
    t = [t stringByReplacingOccurrencesOfString: @"p" withString: [v objectAtIndex: 10]];
    t = [t stringByReplacingOccurrencesOfString: @"l" withString: [v objectAtIndex: 11]];
    t = [t stringByReplacingOccurrencesOfString: @"s" withString: [v objectAtIndex: 12]];
    t = [t stringByReplacingOccurrencesOfString: @"d" withString: [v objectAtIndex: 13]];
    t = [t stringByReplacingOccurrencesOfString: @"b" withString: [v objectAtIndex: 14]];
    t = [t stringByReplacingOccurrencesOfString: @"c" withString: [v objectAtIndex: 15]];
    return t;
}

- (NSSet*) series
{
    if( self.managedObjectContext.deletedObjects.count == 0)
        return [self primitiveValueForKey: @"series"];
    else
        return [[self primitiveValueForKey: @"series"] objectsPassingTest:^BOOL(DicomSeries *obj, BOOL *stop)
            {
                if( obj.isDeleted)
                    return NO;
                
                return YES;
            }];
}


- (NSString*) studyName
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [[self primitiveValueForKey: @"studyName"] capitalizedString];
    
    return [self primitiveValueForKey: @"studyName"];
}

- (NSString*) performingPhysician
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [[self primitiveValueForKey: @"performingPhysician"] capitalizedString];
    
    return [self primitiveValueForKey: @"performingPhysician"];
}

- (NSString*) referringPhysician
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [[self primitiveValueForKey: @"referringPhysician"] capitalizedString];
    
    return [self primitiveValueForKey: @"referringPhysician"];
}

- (NSString*) institutionName
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [[self primitiveValueForKey: @"institutionName"] capitalizedString];
    
    return [self primitiveValueForKey: @"institutionName"];
}

- (NSString*) name
{
    NSString *s = [[self primitiveValueForKey: @"name"] stringByReplacingOccurrencesOfString:@"^" withString:@" "];
    
    s = [s stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"CapitalizedString"])
        return [s capitalizedString];
    
    return s;
    
//    return [DicomStudy scrambleString: [self primitiveValueForKey: @"name"]];
}

- (BOOL) isDistant
{
    return NO;
}

- (void) reapplyAnnotationsFromDICOMSR
{
    static int avoidReentry3 = 0;
    
    if( avoidReentry3)
    {
        NSLog( @"****** reapplyAnnotationsFromDICOMSR avoidReentry");
        return;
    }
    
    avoidReentry3++;
    
	#ifndef OSIRIX_LIGHT
	if( [self.hasDICOM boolValue] == YES)
	{
        @try
        {
            NSManagedObject *archivedAnnotations = [self annotationsSRImage];
            NSString *dstPath = [archivedAnnotations valueForKey: @"completePath"];
            
            if( dstPath)
            {
                SRAnnotation *r = [[[SRAnnotation alloc] initWithContentsOfFile: dstPath] autorelease];
                
                NSDictionary *annotations = [r annotations];
                if( annotations)
                    [self applyAnnotationsFromDictionary: annotations];
            }
        }
        @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
        @finally {
        }
	}
	#endif
    
    avoidReentry3--;
}

- (void) applyAnnotationsFromDictionary: (NSDictionary*) rootDict
{
	if( rootDict == nil)
	{
		NSLog( @"******** applyAnnotationsFromDictionary : rootDict == nil");
		return;
	}
	
	if( [self.studyInstanceUID isEqualToString: [rootDict valueForKey: @"studyInstanceUID"]] == NO) // || [self.patientUID compare: [rootDict valueForKey: @"patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
	{
		NSLog( @"******** WARNING applyAnnotationsFromDictionary will not be applied - studyInstanceUID are NOT corresponding: %@ / %@", [rootDict valueForKey: @"studyInstanceUID"], self.studyInstanceUID);
	}
	else
	{
		@try
		{
			// We are at root level
			if( [rootDict valueForKey: @"comment"]) {[self willChangeValueForKey: @"comment"];[self setPrimitiveValue: [rootDict valueForKey: @"comment"] forKey: @"comment"]; [self didChangeValueForKey: @"comment"];}
            if( [rootDict valueForKey: @"comment2"]) {[self willChangeValueForKey: @"comment2"];[self setPrimitiveValue: [rootDict valueForKey: @"comment2"] forKey: @"comment2"]; [self didChangeValueForKey: @"comment2"];}
            if( [rootDict valueForKey: @"comment3"]) {[self willChangeValueForKey: @"comment3"];[self setPrimitiveValue: [rootDict valueForKey: @"comment3"] forKey: @"comment3"]; [self didChangeValueForKey: @"comment3"];}
            if( [rootDict valueForKey: @"comment4"]) {[self willChangeValueForKey: @"comment4"];[self setPrimitiveValue: [rootDict valueForKey: @"comment4"] forKey: @"comment4"]; [self didChangeValueForKey: @"comment4"];}
			
            if( [rootDict valueForKey: @"stateText"])
            {
                [self willChangeValueForKey: @"stateText"];
                [self setPrimitiveValue: [rootDict valueForKey: @"stateText"] forKey: @"stateText"];
                [self didChangeValueForKey: @"stateText"];
            }
            
            NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName: @"Album"];
            req.predicate = [NSPredicate predicateWithValue: YES];
            NSArray* albums = [self.managedObjectContext executeFetchRequest: req error: nil];
            
			for( NSString *name in [rootDict valueForKey: @"albums"])
			{
				NSUInteger index = [[albums valueForKey: @"name"] indexOfObject: name];
				
				if( index != NSNotFound)
				{
					if( [[[albums objectAtIndex: index] valueForKey: @"smartAlbum"] boolValue] == NO)
					{
						NSMutableSet *studies = [[albums objectAtIndex: index] mutableSetValueForKey: @"studies"];	
						
						[studies addObject: self];
					}
				}
			}
			
			NSArray *seriesArray = [self.series allObjects];
			
			NSArray *allImages = nil, *compressedSopInstanceUIDArray = nil;
			
			for( NSDictionary *series in [rootDict valueForKey: @"series"])
			{
				// -------------------------
				// Find corresponding series
				if( [series valueForKey: @"seriesInstanceUID"] && [series valueForKey: @"seriesDICOMUID"])
				{
					NSUInteger index = [[seriesArray valueForKey: @"seriesInstanceUID"] indexOfObject: [series valueForKey: @"seriesInstanceUID"]];
					
					if( index == NSNotFound)
						index = [[seriesArray valueForKey: @"seriesDICOMUID"] indexOfObject: [series valueForKey: @"seriesDICOMUID"]];
					
					if( index != NSNotFound)
					{
						DicomSeries *s = [seriesArray objectAtIndex: index];
						
						if( [series valueForKey:@"comment"]) {[s willChangeValueForKey: @"comment"];[s setPrimitiveValue: [series valueForKey: @"comment"] forKey: @"comment"]; [s didChangeValueForKey: @"comment"];}
						if( [series valueForKey:@"comment2"]) {[s willChangeValueForKey: @"comment2"];[s setPrimitiveValue: [series valueForKey: @"comment2"] forKey: @"comment2"]; [s didChangeValueForKey: @"comment2"];};
						if( [series valueForKey:@"comment3"]) {[s willChangeValueForKey: @"comment3"];[s setPrimitiveValue: [series valueForKey: @"comment3"] forKey: @"comment3"]; [s didChangeValueForKey: @"comment3"];};
						if( [series valueForKey:@"comment4"]) {[s willChangeValueForKey: @"comment4"];[s setPrimitiveValue: [series valueForKey: @"comment4"] forKey: @"comment4"]; [s didChangeValueForKey: @"comment4"];};
						
						if( [series valueForKey:@"stateText"])
                        {
                            [s willChangeValueForKey: @"stateText"];
							[s setPrimitiveValue: [series valueForKey:@"stateText"] forKey: @"stateText"];
                            [s didChangeValueForKey: @"stateText"];
						}
                        
						for( NSDictionary *image in [series valueForKey: @"images"])
						{
							if( allImages == nil)
							{
								allImages = [NSArray array];
								for( id w in seriesArray)
									allImages = [allImages arrayByAddingObjectsFromArray: [[w valueForKey: @"images"] allObjects]];
									
								compressedSopInstanceUIDArray = [allImages filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"]];
							}
							
							NSPredicate	*predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: [image valueForKey: @"sopInstanceUID"]]] customSelector: @selector(isEqualToSopInstanceUID:)];
							NSArray	*found = [compressedSopInstanceUIDArray filteredArrayUsingPredicate: predicate];
					
							// -------------------------
							// Find corresponding image
							if( [found count] > 0)
							{
								DicomImage *i = [found lastObject];
								
								if( [image valueForKey:@"isKeyImage"])
                                {
                                    [i willChangeValueForKey: @"storedIsKeyImage"];
									[i setPrimitiveValue: [image valueForKey:@"isKeyImage"] forKey: @"storedIsKeyImage"];
                                    [i didChangeValueForKey: @"storedIsKeyImage"];
                                }
							}
//							else NSLog( @"----- applyAnnotationsFromDictionary : image not found : %@", [image valueForKey: @"sopInstanceUID"]);
						}
					}
//					else NSLog( @"----- applyAnnotationsFromDictionary : series not found : %@", [series valueForKey: @"seriesInstanceUID"]);
				}
			}
		}
		@catch (NSException * e)
		{
            N2LogExceptionWithStackTrace(e);
		}
	}
}

- (NSDictionary*) annotationsAsDictionary
{
	// Comments - Study / Series
	
	// State - Study / Series
	
	// Albums - Study
	
	// Key Images - Image
	
	// ***************************************************************************************************
	
	// Study Level
	
	NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
	
	if( self.studyInstanceUID)
		[rootDict setObject: self.studyInstanceUID forKey: @"studyInstanceUID"];
	
	if( self.name)
		[rootDict setObject: self.name forKey: @"patientsName"];
	
	if( self.patientID)
		[rootDict setObject: self.patientID forKey: @"patientID"];
	
	if( self.patientUID)
		[rootDict setObject: self.patientUID forKey: @"patientUID"];
	
	if( self.comment) [rootDict setObject: self.comment forKey: @"comment"];
	if( self.comment2) [rootDict setObject: self.comment2 forKey: @"comment2"];
	if( self.comment3) [rootDict setObject: self.comment3 forKey: @"comment3"];
	if( self.comment4) [rootDict setObject: self.comment4 forKey: @"comment4"];
	
	if( self.stateText)
		[rootDict setObject: self.stateText forKey: @"stateText"];
	
	NSMutableArray *albumsArray = [NSMutableArray array];
	
	for( DicomAlbum * a in [[self.albums allObjects] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease]]])
	{
		if( [[a valueForKey: @"smartAlbum"] boolValue] == NO)
		{
			NSString *name = [a valueForKey: @"name"];
			[albumsArray addObject: name];
		}
	}
	
	[rootDict setObject: albumsArray forKey: @"albums"];
	
	// ***************************************************************************************************
	
	// Series Level
	
	NSMutableArray *seriesArray = [NSMutableArray array];
	
	for( DicomSeries *series in [[self.series allObjects] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: YES]]])
	{
		NSMutableDictionary *seriesDict = [NSMutableDictionary dictionary];
		
		if( [series valueForKey:@"seriesInstanceUID"] && [series valueForKey:@"seriesDICOMUID"])
		{
			if( [series valueForKey:@"comment"]) [seriesDict setObject: [series valueForKey:@"comment"] forKey: @"comment"];
			if( [series valueForKey:@"comment2"]) [seriesDict setObject: [series valueForKey:@"comment2"] forKey: @"comment2"];
			if( [series valueForKey:@"comment3"]) [seriesDict setObject: [series valueForKey:@"comment3"] forKey: @"comment3"];
			if( [series valueForKey:@"comment4"]) [seriesDict setObject: [series valueForKey:@"comment4"] forKey: @"comment4"];
			
			if( [series valueForKey:@"stateText"])
				[seriesDict setObject: [series valueForKey:@"stateText"] forKey: @"stateText"];
			
			// ***************************************************************************************************
			
			// Images Level
			
			NSMutableArray *imagesArray = [NSMutableArray array];
			for( DicomSeries *image in [[[series valueForKey: @"images"] allObjects] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: YES]]])
			{
				NSMutableDictionary *imageDict = [NSMutableDictionary dictionary];
				
				if( [image valueForKey:@"sopInstanceUID"])
				{
					if( [image valueForKey:@"storedIsKeyImage"])
					{
						[imageDict setObject: [image valueForKey:@"isKeyImage"] forKey: @"isKeyImage"];
						[imageDict setObject: [image valueForKey:@"sopInstanceUID"] forKey: @"sopInstanceUID"];
						[imagesArray addObject: imageDict];
					}
				}
			}
			
			if( [imagesArray count] > 0)
				[seriesDict setObject: imagesArray forKey: @"images"];
			
			if( [seriesDict count] > 0)
			{
				[seriesDict setObject: [series valueForKey:@"seriesInstanceUID"] forKey: @"seriesInstanceUID"];
				[seriesDict setObject: [series valueForKey:@"seriesDICOMUID"] forKey: @"seriesDICOMUID"];
				
				[seriesArray addObject: seriesDict];
			}
		}
	}
	
	if( [seriesArray count] > 0)
		[rootDict setObject: seriesArray forKey: @"series"];
	
	return rootDict;
}

- (void) archiveAnnotationsAsDICOMSR
{
    static int avoidReentry2 = 0;
    
    if( avoidReentry2)
    {
        NSLog( @"****** archiveAnnotationsAsDICOMSR avoidReentry");
        return;
    }
    
    avoidReentry2++;
    
	#ifndef OSIRIX_LIGHT
	if ([self.hasDICOM boolValue] == YES)
	{
		@try {
            BOOL isMainDB = self.managedObjectContext.persistentStoreCoordinator == BrowserController.currentBrowser.database.managedObjectContext.persistentStoreCoordinator;

			NSManagedObject *archivedAnnotations = [self annotationsSRImage];
			NSString *dstPath = [archivedAnnotations valueForKey: @"completePath"];
			
			if( dstPath == nil)
				dstPath = isMainDB? [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"] : [[NSFileManager defaultManager] tmpFilePathInTmp];
			
			NSDictionary *annotationsDict = [self annotationsAsDictionary];
			
			SRAnnotation *w = [[[SRAnnotation alloc] initWithContentsOfFile: dstPath] autorelease];
			if( [[w annotations] isEqualToDictionary: annotationsDict] == NO)
			{
                if( w)
                    dstPath = isMainDB? [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"] : [[NSFileManager defaultManager] tmpFilePathInTmp];
                
				// Save or Re-Save it as DICOM SR
				SRAnnotation *r = [[[SRAnnotation alloc] initWithDictionary: annotationsDict path: dstPath forImage: [[[self.series anyObject] valueForKey:@"images"] anyObject]] autorelease];
				[r writeToFileAtPath: dstPath];
				
                DicomDatabase *idb = nil;
                if( [[NSThread currentThread] isMainThread])
                    idb = BrowserController.currentBrowser.database;
                else
                    idb = [BrowserController.currentBrowser.database independentDatabase];
                
                if( isMainDB)
                    [idb addFilesAtPaths: [NSArray arrayWithObject: dstPath]
                                                               postNotifications: NO
                                                                       dicomOnly: YES
                                                             rereadExistingItems: YES
                                                               generatedByOsiriX: YES];
                else
                    [[DicomDatabase databaseAtPath: @"/tmp"] addFilesAtPaths: [NSArray arrayWithObject: dstPath]
                                                           postNotifications: NO
                                                                   dicomOnly: YES
                                                         rereadExistingItems: YES
                                                           generatedByOsiriX: YES];
			}
		}
		@catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
		}
        @finally {
        }
	}
    avoidReentry2--;
    
	#endif
}

- (void) archiveWindowsStateAsDICOMSR
{
    NSLog( @"--- Windows State -> DICOM SR : %@", self.name);
    
    NSData *windowsState = self.windowsState;
    
    NSString *dstPath = [BrowserController.currentBrowser.database uniquePathForNewDataFileWithExtension: @"dcm"];
    
    SRAnnotation *r = [[[SRAnnotation alloc] initWithWindowsState: windowsState path:dstPath forImage: [[[self.series anyObject] valueForKey:@"images"] anyObject]] autorelease];
    
    [r writeToFileAtPath: dstPath];
    
    [self.managedObjectContext save: nil];
    
    DicomDatabase *idb = nil;
    if( [[NSThread currentThread] isMainThread])
        idb = BrowserController.currentBrowser.database;
    else
        idb = [BrowserController.currentBrowser.database independentDatabase];
    
    [idb addFilesAtPaths: [NSArray arrayWithObject: dstPath]
       postNotifications: YES
               dicomOnly: YES
     rereadExistingItems: YES
       generatedByOsiriX: YES];
}

- (void) archiveReportAsDICOMSR
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"archiveReportsAndAnnotationsAsDICOMSR"] == NO)
		return;
    
    static int avoidReentry = 0;
    
    if( avoidReentry)
    {
        NSLog( @"****** archiveReportAsDICOMSR avoidReentry");
        return;
    }
    
    avoidReentry++;
    
	#ifndef OSIRIX_LIGHT
	if( [self.hasDICOM boolValue] == YES)
	{
		[self.managedObjectContext lock];
		@try
		{
            BOOL isMainDB = self.managedObjectContext.persistentStoreCoordinator == BrowserController.currentBrowser.database.managedObjectContext.persistentStoreCoordinator;

			// Report
			NSString *zippedFile = @"/tmp/zippedReport.zip";
			BOOL needToArchive = NO;
			NSString *dstPath = nil;
			DicomImage *reportImage = [self reportImage];
			
			dstPath = [reportImage valueForKey: @"completePathResolved"];
			
			if( dstPath == nil)
				dstPath = isMainDB? [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"] : [[NSFileManager defaultManager] tmpFilePathInTmp];
			
			if( [self.reportURL hasPrefix: @"http://"] || [self.reportURL hasPrefix: @"https://"])
			{
				SRAnnotation *r = [[[SRAnnotation alloc] initWithContentsOfFile: dstPath] autorelease];
				if( [self.reportURL isEqualToString: [r reportURL]] == NO)
					needToArchive = YES;
			}
			else if( [[NSFileManager defaultManager] fileExistsAtPath: self.reportURL])
			{
				NSDate *storedModifDate = [reportImage valueForKey: @"date"];
				NSDate *fileModifDate = [[[NSFileManager defaultManager] attributesOfItemAtPath: self.reportURL error: nil] valueForKey: NSFileModificationDate];
				
				if( reportImage == nil || [[storedModifDate description] isEqualToString: [fileModifDate description]] == NO) // We want to compare only date and time, without milliseconds
				{
					[BrowserController encryptFileOrFolder: self.reportURL inZIPFile: zippedFile password: nil deleteSource: NO showGUI: NO];
				
					if( [[NSFileManager defaultManager] fileExistsAtPath: zippedFile])
					{
						SRAnnotation *r = [[[SRAnnotation alloc] initWithContentsOfFile: dstPath] autorelease];
						if( [[NSData dataWithContentsOfFile: zippedFile] isEqualToData: [r dataEncapsulated]] == NO)
							needToArchive = YES;
					}
				}
			}
			else //empty or deleted report?
			{
				if( [reportImage valueForKey: @"completePath"] && [[NSFileManager defaultManager] fileExistsAtPath: [reportImage valueForKey: @"completePath"]])
				{
					needToArchive = YES;
					zippedFile = nil;	//We will archive an empty NSData
				}
				
				if( self.reportURL && [[NSFileManager defaultManager] fileExistsAtPath: self.reportURL])
					[[NSFileManager defaultManager] removeItemAtPath: self.reportURL error: nil];
				
                
                [self willChangeValueForKey: @"reportURL"];
				[self setPrimitiveValue: nil forKey: @"reportURL"];
                [self didChangeValueForKey: @"reportURL"];
			}
			
			if( needToArchive)
			{
				SRAnnotation *r = nil;
				
				NSLog( @"--- Report -> DICOM SR : %@", self.name);
				
				if( [self.reportURL hasPrefix: @"http://"] || [self.reportURL hasPrefix: @"https://"])
					r = [[[SRAnnotation alloc] initWithURLReport: self.reportURL path: dstPath forImage: [[[self.series anyObject] valueForKey:@"images"] anyObject]] autorelease];
				else
				{
					NSDate *modifDate = [[[NSFileManager defaultManager] attributesOfItemAtPath: self.reportURL error: nil] valueForKey: NSFileModificationDate];
					r = [[[SRAnnotation alloc] initWithFileReport: zippedFile path: dstPath forImage: [[[self.series anyObject] valueForKey:@"images"] anyObject] contentDate: modifDate] autorelease];
				}
				
				[r writeToFileAtPath: dstPath];
				
                [self.managedObjectContext save: nil];
                
                DicomDatabase *idb = nil;
                if( [[NSThread currentThread] isMainThread])
                    idb = BrowserController.currentBrowser.database;
                else
                    idb = [BrowserController.currentBrowser.database independentDatabase];
                
                if( isMainDB)
                    [idb addFilesAtPaths: [NSArray arrayWithObject: dstPath]
                                                               postNotifications: YES
                                                                       dicomOnly: YES
                                                             rereadExistingItems: YES
                                                               generatedByOsiriX: YES];
                else
                    [[DicomDatabase databaseAtPath: @"/tmp"] addFilesAtPaths: [NSArray arrayWithObject: dstPath]
                                                           postNotifications: YES
                                                                   dicomOnly: YES
                                                         rereadExistingItems: YES
                                                           generatedByOsiriX: YES];
			}
			
			if( zippedFile)
				[[NSFileManager defaultManager] removeItemAtPath: zippedFile error: nil];
		}
		@catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
		}
        @finally {
            [self.managedObjectContext unlock];
        }
	}
    
    avoidReentry--;
    
	#endif
}

- (BOOL)validateForDelete:(NSError **)error
{
	BOOL delete = [super validateForDelete: error];
	if (delete)
	{
		if( self.reportURL && [[NSFileManager defaultManager] fileExistsAtPath: self.reportURL])
			[[NSFileManager defaultManager] removeItemAtPath: self.reportURL error: nil];
	}
	return delete;
}

- (NSString*) soundex
{
	return [DicomStudy soundex: self.name];
}

+ (NSString*) displayedModalitiesForSeries: (NSArray*) seriesModalities
{
    NSMutableArray *r = [NSMutableArray array];
    
    BOOL SC = NO, SR = NO, PR = NO, OT = NO;
    
    for( NSString *mod in seriesModalities)
    {
        if( [mod isEqualToString:@"SR"])
            SR = YES;
        else if( [mod isEqualToString:@"SC"])
            SC = YES;
        else if( [mod isEqualToString:@"PR"])
            PR = YES;
        else if( [mod isEqualToString:@"RTSTRUCT"] == YES && [r containsString: mod] == NO)
            [r addObject: @"RT"];
        else if( [mod isEqualToString:@"OT"])
            OT = YES;
        else if( [mod isEqualToString:@"KO"])
        {
        }
        else if([r containsString: mod] == NO)
            [r addObject: mod];
    }
    
    if( [r count] == 0)
    {
        if( SC) [r addObject: @"SC"];
        else if( OT) [r addObject: @"OT"];
        else
        {
            if( SR) [r addObject: @"SR"];
            if( PR) [r addObject: @"PR"];
        }
    }
    
    NSString *m = [r componentsJoinedByString:@"\\"];
    
    return m;
}

- (NSString*) modalities
{
    [self.managedObjectContext lock];
    @try
    {
        if (cachedModalites && _numberOfImagesWhenCachedModalities == self.numberOfImages.integerValue)
            return cachedModalites;
        
        // skip the "OsiriX No Autodeletion" series
        NSMutableArray* series = [[[self.series allObjects] mutableCopy] autorelease];
        for (DicomSeries* serie in series)
            if (serie.id.intValue == 5005 && [serie.name isEqualToString:@"OsiriX No Autodeletion"]) {
                [series removeObject:serie];
                break;
            }
        
        NSString *m = [DicomStudy displayedModalitiesForSeries: [[series sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending: YES]]] valueForKey:@"modality"]];
        
        [cachedModalites release];
        cachedModalites = [m retain];
        _numberOfImagesWhenCachedModalities = self.numberOfImages.integerValue;
        
        return m;
    }
    @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        [self.managedObjectContext unlock];
    }
    
    return nil;
}

- (void) didTurnIntoFault
{
    [dicomTime release]; dicomTime = nil;
    [cachedModalites release]; cachedModalites = nil;
}

- (void) dealloc
{
	[self didTurnIntoFault];
	[super dealloc];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (BOOL) isHidden;
{
	return isHidden;
}

- (void) setHidden: (BOOL) h;
{
	isHidden = h;
}

- (NSString*) type
{
	return @"Study";
}

- (void) dcmodifyThread: (NSDictionary*) dict
{
	#ifdef OSIRIX_VIEWER
	#ifndef OSIRIX_LIGHT
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[[DicomStudy dbModifyLock] lock];
	@try {
        NSMutableArray *files = [NSMutableArray arrayWithArray: [dict objectForKey: @"files"]];
		NSMutableArray	*params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--ignore-errors", nil];
		NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: [files objectAtIndex: 0]] objectAtIndex: 0]];
        
		if( [dict objectForKey: @"value"] == nil || [(NSString*)[dict objectForKey: @"value"] length] == 0)
			[params addObjectsFromArray: [NSArray arrayWithObjects: @"-e", [dict objectForKey: @"field"], nil]];
		else
        {
            if( [[dict objectForKey: @"value"] canBeConvertedToEncoding: encoding])
                [params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", [dict objectForKey: @"field"], [dict objectForKey: @"value"]], nil]];
            else
                NSLog( @"---- cannot convert [dict objectForKey: value] to this encoding: %ld", (long) encoding);
		}
        
		if( files)
		{
			[files removeDuplicatedStrings];
			
			[params addObjectsFromArray: files];
			
			@try
			{
				[XMLController modifyDicom: params encoding: encoding];
				
				for( id loopItem in files)
                {
					[[NSFileManager defaultManager] removeFileAtPath: [loopItem stringByAppendingString:@".bak"] handler:nil];
                }
			}
			@catch (NSException * e)
			{
				NSLog(@"**** DicomStudy setComment: %@", e);
			}
		}
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [[DicomStudy dbModifyLock] unlock];
        [pool release];
    }
	#endif
	#endif
}

- (void) setComment: (NSString*) c
{
	if( [self.hasDICOM boolValue] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"savedCommentsAndStatusInDICOMFiles"] && [[DicomDatabase databaseForContext:[self managedObjectContext]] isLocal])
	{
		if( c == nil)
			c = @"";
			
		if( ([(NSString*)[self primitiveValueForKey: @"comment"] length] != 0 || [c length] != 0))
		{
			if( [c isEqualToString: [self primitiveValueForKey: @"comment"]] == NO)
			{
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [[self paths] allObjects], @"files", @"(0032,4000)", @"field", c, @"value", nil];
				
				NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(dcmodifyThread:) object: dict] autorelease];
				t.name = NSLocalizedString( @"Updating DICOM files...", nil);
				t.status = N2LocalizedSingularPluralCount( [[dict objectForKey: @"files"] count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
                
				[[ThreadsManager defaultManager] addThreadAndStart: t];
			}
		}
	}
	
	NSString *previousValue = [self primitiveValueForKey: @"comment"];
	
	[self willChangeValueForKey: @"comment"];
	[self setPrimitiveValue: c forKey: @"comment"];
	[self didChangeValueForKey: @"comment"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[self archiveAnnotationsAsDICOMSR];
	}
}

- (void) setComment2: (NSString*) c
{
	NSString *previousValue = [self primitiveValueForKey: @"comment2"];
	
	[self willChangeValueForKey: @"comment2"];
	[self setPrimitiveValue: c forKey: @"comment2"];
	[self didChangeValueForKey: @"comment2"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[self archiveAnnotationsAsDICOMSR];
	}
}

- (void) setComment3: (NSString*) c
{
	NSString *previousValue = [self primitiveValueForKey: @"comment3"];
	
	[self willChangeValueForKey: @"comment3"];
	[self setPrimitiveValue: c forKey: @"comment3"];
	[self didChangeValueForKey: @"comment3"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[self archiveAnnotationsAsDICOMSR];
	}
}

- (void) setComment4: (NSString*) c
{
	NSString *previousValue = [self primitiveValueForKey: @"comment4"];
	
	[self willChangeValueForKey: @"comment4"];
	[self setPrimitiveValue: c forKey: @"comment4"];
	[self didChangeValueForKey: @"comment4"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[self archiveAnnotationsAsDICOMSR];
	}
}

- (void) setStateText: (NSNumber*) c
{
	#ifdef OSIRIX_VIEWER
	#ifndef OSIRIX_LIGHT
	@try 
	{
		if( [self.hasDICOM boolValue] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"savedCommentsAndStatusInDICOMFiles"] && [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]] == NO)
		{
			if( c == nil)
				c = [NSNumber numberWithInt: 0];
			
			if( [c intValue] != [[self primitiveValueForKey: @"stateText"] intValue])
			{
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [[self paths] allObjects], @"files", @"(4008,0212)", @"field", [c stringValue], @"value", nil];
				
				NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(dcmodifyThread:) object: dict] autorelease];
				t.name = NSLocalizedString( @"Updating DICOM files...", nil);
				t.status = N2LocalizedSingularPluralCount( [[dict objectForKey: @"files"] count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
                
				[[ThreadsManager defaultManager] addThreadAndStart: t];
            }
        }
        
        if( [self.hasDICOM boolValue] == YES)
        {
            // Save as DICOM PDF
            if( [[NSUserDefaults standardUserDefaults] boolForKey:@"generateDICOMPDFWhenValidated"] && [c intValue] == 4 && self.reportURL.length)
            {
                BOOL isMainDB = self.managedObjectContext.persistentStoreCoordinator == BrowserController.currentBrowser.database.managedObjectContext.persistentStoreCoordinator;
                
                NSString *filePath = isMainDB? [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"] : [[NSFileManager defaultManager] tmpFilePathInTmp];
                
                @try {
                    [self saveReportAsDicomAtPath: filePath];
                    
                    DicomDatabase *idb = nil;
                    if( [[NSThread currentThread] isMainThread])
                        idb = BrowserController.currentBrowser.database;
                    else
                        idb = [BrowserController.currentBrowser.database independentDatabase];
                    
                    if( isMainDB)
                        [idb addFilesAtPaths: [NSArray arrayWithObject: filePath]
                           postNotifications: YES
                                   dicomOnly: YES
                         rereadExistingItems: YES
                           generatedByOsiriX: YES];
                    else
                        [[DicomDatabase databaseAtPath: @"/tmp"] addFilesAtPaths: [NSArray arrayWithObject: filePath]
                                                               postNotifications: YES
                                                                       dicomOnly: YES
                                                             rereadExistingItems: YES
                                                               generatedByOsiriX: YES];
                }
                @catch (NSException *e) {
                    N2LogExceptionWithStackTrace(e);
                }
            }
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	#endif
	#endif
	
	NSNumber *previousState = [self primitiveValueForKey: @"stateText"];
	
	[self willChangeValueForKey: @"stateText"];
	[self setPrimitiveValue: c forKey: @"stateText"];
	[self didChangeValueForKey: @"stateText"];
	
	if( [c intValue] != [previousState intValue])
		[self archiveAnnotationsAsDICOMSR];
}

- (void) setReportURL: (NSString*) url
{
	#ifdef OSIRIX_VIEWER
	BrowserController *cB = [BrowserController currentBrowser];
	
	if( url)
	{
		if( [url hasPrefix: @"http://"] == NO && [url hasPrefix: @"https://"] == NO)
		{
		   NSString *commonPath = [[cB fixedDocumentsDirectory] commonPrefixWithString: url options: NSLiteralSearch];
		
			if( [commonPath isEqualToString: [cB fixedDocumentsDirectory]])
			{
				url = [url substringFromIndex: [[cB fixedDocumentsDirectory] length]];
				
				if( [url hasPrefix: @"TEMP.noindex/"])
					url = [url stringByReplacingOccurrencesOfString: @"TEMP.noindex/" withString: @"REPORTS/"];
				
				if( [url characterAtIndex: 0] == '/') url = [url substringFromIndex: 1];
			}
		}
	}
	#endif
	
	[self willChangeValueForKey: @"reportURL"];
	[self setPrimitiveValue: url forKey: @"reportURL"];
	[self didChangeValueForKey: @"reportURL"];
	
	[self archiveReportAsDICOMSR];
}

- (NSString*) reportURL
{
	NSString *url = [self primitiveValueForKey: @"reportURL"];
	
	#ifdef OSIRIX_VIEWER
	if( url && [url length])
	{
		if( [url hasPrefix: @"http://"] == NO && [url hasPrefix: @"https://"] == NO)
		{
			BrowserController *cB = [BrowserController currentBrowser];
			
			if( [cB isBonjour: [self managedObjectContext]])
			{
				// We will give a path with TEMP.noindex, instead of REPORTS
				if( [url characterAtIndex: 0] != '/')
				{
					if( [url hasPrefix: @"REPORTS/"])
						url = [url stringByReplacingOccurrencesOfString: @"REPORTS/" withString: @"TEMP.noindex/"];
					url = [[cB fixedDocumentsDirectory] stringByAppendingPathComponent: url];
				}
			}
			else
			{
				if( [url characterAtIndex: 0] != '/')
					url = [[cB fixedDocumentsDirectory] stringByAppendingPathComponent: url];
				else
				{	// Should we convert it to a local path?
					NSString *commonPath = [[cB fixedDocumentsDirectory] commonPrefixWithString: url options: NSLiteralSearch];
					if( [commonPath isEqualToString: [cB fixedDocumentsDirectory]])
                    {
                        [self willChangeValueForKey: @"reportURL"];
						[self setPrimitiveValue: url forKey: @"reportURL"];
                        [self didChangeValueForKey: @"reportURL"];
                    }
				}
			}
		}
	}
	#endif
	
	return url;
}

- (NSString *) localstring
{
	BOOL local = YES;
	
	[self.managedObjectContext lock];
	@try {
		NSManagedObject* obj = [[[self.series anyObject] valueForKey:@"images"] anyObject];
		local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	if (local)
        return @"L";
	else return @"";
}

- (void) setDate:(NSDate*) date
{
    @synchronized (self)
    {
        [dicomTime release];
        dicomTime = nil;
        
        [self willChangeValueForKey: @"date"];
        [self setPrimitiveValue: date forKey:@"date"];
        [self didChangeValueForKey: @"date"];
    }
}

- (NSNumber*) dicomTime
{
    @synchronized (self) {
        if( dicomTime) return dicomTime;
        
        dicomTime = [[[DCMCalendarDate dicomTimeWithDate:self.date] timeAsNumber] retain];
        
        return dicomTime;
    }
    
    return nil;
}

- (id) valueForUndefinedKey:(NSString *)key
{
	NSSet *paths = [self paths];
	
	if( [paths count])
	{
		id value = [DicomFile getDicomField: key forFile: [[paths anyObject] completePath]];
		if (value)
			return value;
	}
	
	return [super valueForUndefinedKey: key];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSNumber*) intervalSinceBirth
{
    if( [[NSUserDefaults standardUserDefaults] integerForKey: @"yearOldDatabaseDisplay"] == 0)
        return [NSNumber numberWithDouble: [[NSDate date] timeIntervalSinceDate: self.dateOfBirth]];
    else
        return [NSNumber numberWithDouble: [self.date timeIntervalSinceDate: self.dateOfBirth]];
}

+ (NSString*) yearOldAcquisition:(NSDate*) acquisitionDate FromDateOfBirth: (NSDate*) dateOfBirth
{
	if( dateOfBirth && acquisitionDate)
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [dateOfBirth timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [acquisitionDate timeIntervalSinceReferenceDate]];
		
		NSInteger years, months, days;
		
		[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
		
		if( years < 2)
		{
			if( years < 1)
			{
				if( months < 1)
				{
					if( days < 0) return @"";
					else return [NSString stringWithFormat: NSLocalizedString( @"%d d", @"d = day"), days];
				}
				else return [NSString stringWithFormat: @"%d%@", (int) months, NSLocalizedString( @" m", @"m = month")];
			}
			else return [NSString stringWithFormat: @"%d%@ %d%@", (int) years, NSLocalizedString( @" y", @"y = year"), (int) months, NSLocalizedString( @" m", @"m = month")];
		}
		else return [NSString stringWithFormat: @"%d%@", (int) years, NSLocalizedString( @" y", @"y = year")];
	}
	else return @"";
}

- (NSString*) yearOldAcquisition
{
    return [DicomStudy yearOldAcquisition: self.date FromDateOfBirth: self.dateOfBirth];
}

+ (NSString*) yearOldFromDateOfBirth: (NSDate*) dateOfBirth
{
    if( dateOfBirth)
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [dateOfBirth timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate date];
		
		NSInteger years, months, days;
		
		[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
		
		if( years < 2)
		{
			if( years < 1)
			{
				if( months < 1)
				{
					if( days < 0) return @"";
					else return [NSString stringWithFormat: NSLocalizedString( @"%d d", @"d = day"), days];
				}
				else return [NSString stringWithFormat: @"%d%@", (int) months, NSLocalizedString( @" m", @"m = month")];
			}
			else return [NSString stringWithFormat: @"%d%@ %d%@", (int) years, NSLocalizedString( @" y", @"y = year"), (int) months, NSLocalizedString( @" m", @"m = month")];
		}
		else return [NSString stringWithFormat: @"%d%@", (int) years, NSLocalizedString( @" y", @"y = year")];
	}
	else return @"";
}

- (NSString*) yearOld
{
	return [DicomStudy yearOldFromDateOfBirth: self.dateOfBirth];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void) setModality:(NSString *) s
{
	if( [s isEqualToString:@"SC"] ||
		[s isEqualToString:@"PR"] ||
		[s isEqualToString:@"SR"] ||
		[s isEqualToString:@"RTSTRUCT"] ||
		[s isEqualToString:@"RT"] ||
		[s isEqualToString:@"KO"])
	{
		if( self.modality.length > 0)
			return; //We are not insterested in these 'technical' modalities, we prefer true modalities like CT, MR, ...
	}
		   
	[self willChangeValueForKey: @"modality"];
	[self setPrimitiveValue: s forKey:@"modality"];
	[self didChangeValueForKey: @"modality"];
}

- (void) setNumberOfImages:(NSNumber *) n
{
    @synchronized (self) {
//        [cachedRawNoFiles release];
//        cachedRawNoFiles = nil;
        
        [cachedModalites release];
        cachedModalites = nil;
        
        [self willChangeValueForKey: @"numberOfImages"];
        [self setPrimitiveValue: n forKey:@"numberOfImages"];
        [self didChangeValueForKey: @"numberOfImages"];
    }
}

- (NSNumber *) rawNoFiles
{
    int sum = 0;
    
    [self.managedObjectContext lock];
    @try
    {
        for( DicomSeries *s in [self.series allObjects])
        {
            sum += [[s valueForKey: @"rawNoFiles"] intValue];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        [self.managedObjectContext unlock];
    }

    return [NSNumber numberWithInt:sum];
}

- (NSNumber *) noFilesExcludingMultiFrames
{
	if ([[self primitiveValueForKey:@"numberOfImages"] intValue] <= 0) // There are frames !
	{
		[self.managedObjectContext lock];
		@try {
            int sum = 0;
			for (DicomSeries* s in [self.series allObjects])
            {
                sum += [[s valueForKey:@"noFilesExcludingMultiFrames"] intValue];
            }
            return [NSNumber numberWithInt:sum];
		}
		@catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
		}
        @finally {
            [self.managedObjectContext unlock];
        }
	}
	return [self noFiles];
}

- (NSNumber *) noSeries
{
    return [NSNumber numberWithInt: self.imageSeries.count];
}

- (NSNumber *) noFiles
{
	int n = [[self primitiveValueForKey:@"numberOfImages"] intValue];
	if (n == 0)
	{
		int sum = 0;
		NSNumber *no = nil;
		
		[self.managedObjectContext lock];
		@try {
			BOOL framesInSeries = NO;
			
			for( DicomSeries *s in [self.series allObjects])
			{
                if( [DCMAbstractSyntaxUID isStructuredReport: [s valueForKey: @"seriesSOPClassUID"]] == NO &&
                    [DCMAbstractSyntaxUID isSupportedPrivateClasses: [s valueForKey: @"seriesSOPClassUID"]] == NO &&
                    [DCMAbstractSyntaxUID isPresentationState: [s valueForKey: @"seriesSOPClassUID"]] == NO)
                {
                    sum += [[s valueForKey:@"noFiles"] intValue];
                    
                    if( [[s primitiveValueForKey:@"numberOfImages"] intValue] < 0) // There are frames !
                        framesInSeries = YES;
                }
			}
			
			if( framesInSeries)
				sum = -sum;
			
			no = [NSNumber numberWithInt: sum];
			
			[self willChangeValueForKey: @"numberOfImages"];
			[self setPrimitiveValue: no forKey:@"numberOfImages"];
			[self didChangeValueForKey: @"numberOfImages"];
		}
		@catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
		}
		@finally {
            [self.managedObjectContext unlock];
        }
		
		if (sum < 0)
			return [NSNumber numberWithInt: -sum];
		else return no;
	}
	else
	{
		if (n < 0)
			return [NSNumber numberWithInt: -n];
		else return [self primitiveValueForKey:@"numberOfImages"];
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSSet*) paths
{
    [self.managedObjectContext lock];
	@try {
        NSMutableSet *set = [NSMutableSet set];
		for (id subset in [self valueForKeyPath:@"series.images.completePath"])
			[set unionSet: subset];
        return set;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

- (NSSet*) pathsForForkedProcess
{
    [self.managedObjectContext lock];
	@try {
        NSMutableSet* set = [NSMutableSet set];
		for (id subset in [self valueForKeyPath:@"series.images.completePathWithNoDownloadAndLocalOnly"])
			[set unionSet:subset];
        return set;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSSet*) keyImages
{
    [self.managedObjectContext lock];
	@try {
        NSMutableSet* set = [NSMutableSet set];
		for (id object in self.series)
			[set unionSet:[object keyImages]];
        return set;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ------------------------ Series subselections-----------------------------------ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

+ (BOOL) displaySeriesWithSOPClassUID: (NSString*) uid andSeriesDescription: (NSString*) description containingOnlyPixels: (BOOL) pixels
{
    if ([description isEqualToString:@"OsiriX No Autodeletion"])
        return NO;
    
    if( pixels)
    {
        if (uid == nil || [DCMAbstractSyntaxUID isImageStorage: uid])
        {
            if( [uid isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
                return NO;
            
            return YES;
        }
    }
    else
    {
        if (uid == nil || [DCMAbstractSyntaxUID isImageStorage: uid] || [DCMAbstractSyntaxUID isRadiotherapy:uid] || [DCMAbstractSyntaxUID isWaveform:uid])
            return YES;
        
        if ([DCMAbstractSyntaxUID isStructuredReport:uid] && [description hasPrefix: @"OsiriX ROI SR"] == NO && [description hasPrefix: @"OsiriX Annotations SR"] == NO && [description hasPrefix: @"OsiriX Report SR"] == NO && [description hasPrefix: @"OsiriX WindowsState SR"] == NO)
            return YES;
	}
    
	return NO;
}

+ (BOOL) displaySeriesWithSOPClassUID: (NSString*) uid andSeriesDescription: (NSString*) description
{
    return [self displaySeriesWithSOPClassUID: uid andSeriesDescription: description containingOnlyPixels: NO];
}

- (NSSet*)images
{
    [self.managedObjectContext lock];
	@try {
        NSMutableSet* images = [NSMutableSet set];
		for (id subset in [self valueForKeyPath: @"series.images"])
			[images unionSet: subset];
        return images;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

+ (NSArray*) seriesSortDescriptors
{
    NSSortDescriptor * sortid = [NSSortDescriptor sortDescriptorWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];
    NSSortDescriptor * sortdate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray * sortDescriptors = nil;
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
    else if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
    else sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
    
    return sortDescriptors;
}

- (NSArray*)allSeries
{
    return [self.series sortedArrayUsingDescriptors: [DicomStudy seriesSortDescriptors]];
}

- (NSArray*)imageSeriesContainingPixels:(BOOL) pixels
{
	[self.managedObjectContext lock];
    @try {
        NSMutableArray* newArray = [NSMutableArray array];
		for (DicomSeries* series in [self.series sortedArrayUsingDescriptors: [DicomStudy seriesSortDescriptors]])
			@try {
                if ([DicomStudy displaySeriesWithSOPClassUID:series.seriesSOPClassUID andSeriesDescription:series.name containingOnlyPixels: pixels])
                    [newArray addObject:series];
            } @catch (...) {
            }
        return newArray;
	}
    @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

- (NSArray*)imageSeries
{
    return [self imageSeriesContainingPixels: NO];
}

- (NSArray*)keyObjectSeries
{
    [self.managedObjectContext lock];
	@try {
        NSMutableArray *newArray = [NSMutableArray array];
		for (DicomSeries *series in self.series)
			if ( [[DCMAbstractSyntaxUID keyObjectSelectionDocumentStorage] isEqualToString:[series valueForKey:@"seriesSOPClassUID"]])
				[newArray addObject:series];
        return newArray;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

- (NSArray*)keyObjects
{
    [self.managedObjectContext lock];
	@try {
        NSMutableSet *set = [NSMutableSet set];
		for (DicomSeries *series in [self keyObjectSeries])
			[set unionSet: series.images];
        return [set allObjects];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

- (NSArray *)presentationStateSeries
{
    [self.managedObjectContext lock];
	@try {
        NSMutableArray *newArray = [NSMutableArray array];
		for (DicomSeries *series in self.series)
			if ([DCMAbstractSyntaxUID isPresentationState:[series valueForKey:@"seriesSOPClassUID"]])
				[newArray addObject:series];
        return newArray;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

- (NSArray *)waveFormSeries
{
    [self.managedObjectContext lock];
	@try {
        NSMutableArray *newArray = [NSMutableArray array];
		for (DicomSeries *series in self.series)
			if ([DCMAbstractSyntaxUID isWaveform:[series valueForKey:@"seriesSOPClassUID"]])
				[newArray addObject:series];
        return newArray;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}


- (NSManagedObject *) annotationsSRImage // Comments, Status, Key Images, ...
{
	NSSet* array = self.series;
	if( array.count < 1) return nil;
	
	[self.managedObjectContext lock];
	@try {
        NSMutableArray* newArray = [NSMutableArray array];
        NSManagedObject* image = nil;

		for( DicomSeries *series in array)
		{
			if( [[series valueForKey:@"id"] intValue] == 5004 && [[series valueForKey:@"name"] isEqualToString: @"OsiriX Annotations SR"] == YES && [DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]] == YES)
				[newArray addObject: series];
		}
		
		// Take the most recent series
		if( [newArray count] > 1)
		{
			NSLog( @"****** multiple (%d) annotationsSRImage 5004 series: Delete the extra series and merge the images...", (int) [newArray count]);
			
			@try
			{
				NSMutableSet *r = [[newArray lastObject] mutableSetValueForKey: @"images"];
			
				for( DicomSeries *i in newArray)
				{
					if( i != [newArray lastObject])
					{
						[r addObjectsFromArray: [[i valueForKey: @"images"] allObjects]];
						
						NSMutableSet *o = [i mutableSetValueForKey: @"images"];
						[o setValue: [NSNumber numberWithBool: NO] forKeyPath: @"inDatabaseFolder"];
						[o removeAllObjects];
						[[self managedObjectContext] deleteObject: i];
					}
				}
                
				[self.managedObjectContext save:nil];
				
				[r setValue: [NSNumber numberWithBool: YES] forKeyPath: @"inDatabaseFolder"];
			}
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e);
			}
            
            [self setNumberOfImages: nil];
		}
		
		if( [[[newArray lastObject] valueForKey: @"images"] count] > 1)
		{
			NSArray *images = [[[newArray lastObject] valueForKey: @"images"] allObjects];
			
			// Take the most recent image
			images = [images sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
			image = [images lastObject];
		}
		else
            image = [[[newArray lastObject] valueForKey: @"images"] anyObject];

        return image;
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
    
	return nil;
}

- (DicomImage*) reportImage
{
	NSArray *images = nil;
	
	@try 
	{
		images = [[[self reportSRSeries] valueForKey: @"images"] allObjects];
		
		if( [images count] > 1)
		{
			// Take the most recent image
			images = [images sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: YES]]];
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return [images lastObject];
}

- (NSManagedObject *) reportSRSeries
{
	NSSet* array = self.series;
	if (array.count < 1) return nil;
	
	[self.managedObjectContext lock];
	@try {
        NSMutableArray *newArray = [NSMutableArray array];
    
		for( DicomSeries *series in array)
		{
			if( [[series valueForKey:@"id"] intValue] == 5003 && [[series valueForKey:@"name"] isEqualToString: @"OsiriX Report SR"] == YES && [DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]] == YES)
				[newArray addObject:series];
		}
		
		if( [newArray count] > 1)
		{
			NSLog( @"****** multiple (%d) reportSRSeries: Delete the extra series and merge the images...", (int) [newArray count]);
			
			@try
			{
				NSMutableSet *r = [[newArray lastObject] mutableSetValueForKey: @"images"];
			
				for( DicomSeries *i in newArray)
				{
					if( i != [newArray lastObject])
					{
						[r addObjectsFromArray: [[i valueForKey: @"images"] allObjects]];
						
						NSMutableSet *o = [i mutableSetValueForKey: @"images"];
						[o setValue: [NSNumber numberWithBool: NO] forKeyPath: @"inDatabaseFolder"];
						[o removeAllObjects];
						[[self managedObjectContext] deleteObject: i];
					}
				}

                [self setNumberOfImages: nil];
                
				[self.managedObjectContext save:nil];

				[r setValue: [NSNumber numberWithBool: YES] forKeyPath: @"inDatabaseFolder"];
			}
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e);
			}
		}

        return [newArray lastObject];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
	@finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

- (NSArray*) allWindowsStateSRSeries
{
	NSArray *images = nil;
	
	@try
	{
		images = [[[self windowsStateSRSeries] valueForKey: @"images"] allObjects];
		
		if( [images count] > 1)
		{
			// Take the most recent image
			images = [images sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: YES]]];
		}
	}
	@catch (NSException * e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return images;
}

- (DicomImage*) windowsStateImage // most recent state
{
	return [[self allWindowsStateSRSeries] lastObject];
}

- (NSManagedObject *) windowsStateSRSeries
{
	NSSet* array = self.series;
	if (array.count < 1) return nil;
	
	[self.managedObjectContext lock];
	@try {
        NSMutableArray *newArray = [NSMutableArray array];
        
		for( DicomSeries *series in array)
		{
			if( [[series valueForKey:@"id"] intValue] == 5006 && [[series valueForKey:@"name"] isEqualToString: @"OsiriX WindowsState SR"] == YES && [DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]] == YES)
				[newArray addObject:series];
		}
		
		if( [newArray count] > 1)
		{
			NSLog( @"****** multiple (%d) reportSRSeries: Delete the extra series and merge the images...", (int) [newArray count]);
			
			@try
			{
				NSMutableSet *r = [[newArray lastObject] mutableSetValueForKey: @"images"];
                
				for( DicomSeries *i in newArray)
				{
					if( i != [newArray lastObject])
					{
						[r addObjectsFromArray: [[i valueForKey: @"images"] allObjects]];
						
						NSMutableSet *o = [i mutableSetValueForKey: @"images"];
						[o setValue: [NSNumber numberWithBool: NO] forKeyPath: @"inDatabaseFolder"];
						[o removeAllObjects];
						[[self managedObjectContext] deleteObject: i];
					}
				}
                
                [self setNumberOfImages: nil];
                
				[self.managedObjectContext save:nil];
                
				[r setValue: [NSNumber numberWithBool: YES] forKeyPath: @"inDatabaseFolder"];
			}
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e);
			}
		}
        
        return [newArray lastObject];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
	@finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

- (NSManagedObject *)roiSRSeries
{
	NSSet* array = self.series;
	if (array.count < 1) return nil;
	
	[self.managedObjectContext lock];
	@try {
        NSMutableArray *newArray = [NSMutableArray array];
		for( DicomSeries *series in array)
		{
			if( [[series valueForKey:@"id"] intValue] == 5002 && [[series valueForKey:@"name"] isEqualToString: @"OsiriX ROI SR"] == YES && [DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]] == YES)
				[newArray addObject:series];
		}
		
		if( [newArray count] > 1)
		{
			NSLog( @"****** multiple (%d) roiSRSeries: Delete the extra series and merge the images...", (int) [newArray count]);
			
			@try
			{
				NSMutableSet *r = [[newArray lastObject] mutableSetValueForKey: @"images"];
			
				for( DicomSeries *i in newArray)
				{
					if( i != [newArray lastObject])
					{
						[r addObjectsFromArray: [[i valueForKey: @"images"] allObjects]];
						
						NSMutableSet *o = [i mutableSetValueForKey: @"images"];
						[o setValue: [NSNumber numberWithBool: NO] forKeyPath: @"inDatabaseFolder"];
						[o removeAllObjects];
						[[self managedObjectContext] deleteObject: i];
					}
				}
                
                [self setNumberOfImages: nil];
                
				[self.managedObjectContext save:nil];

				[r setValue: [NSNumber numberWithBool: YES] forKeyPath: @"inDatabaseFolder"];
			}
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e);
			}
		}
        return [newArray lastObject];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

- (DicomImage*) roiForImage: (DicomImage*) image inArray: (NSArray*) roisArray
{
	[self.managedObjectContext lock];
	@try  {
		NSString *searchedUID = [image valueForKey: @"sopInstanceUID"];
		
		searchedUID = [searchedUID stringByAppendingFormat: @"-%d", [[image valueForKey: @"frameID"] intValue]];
		
		if( roisArray == nil)
			roisArray = [[[self roiSRSeries] valueForKey: @"images"] allObjects];
		
		NSArray	*found = [roisArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"comment == %@", searchedUID]];
		
		// Take the most recent roi
		if( [found count] > 1)
		{
			found = [[[found sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: YES]]] mutableCopy] autorelease];
			NSLog( @"--- multiple rois array for same sopInstanceUID (roiForImage) : %d", (int) [found count]);
			
			// Merge the other ROIs with this ROI, and empty the old ones
			NSMutableArray *r = [NSMutableArray array];
			for( DicomImage *i in found)
			{
				if( i != [found lastObject])
				{
					@try
					{
						if( [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]])
						{
							// Not modified on the 'bonjour client side'?
							if( [[i valueForKey:@"inDatabaseFolder"] boolValue])
							{
								// The ROI file was maybe changed on the server -> delete it
								[[NSFileManager defaultManager] removeItemAtPath: [i valueForKey: @"completePath"] error: nil];
							}
						}
						
						NSData *d = [SRAnnotation roiFromDICOM: [i valueForKey: @"completePathResolved"]];
						
						if( d)
						{
							NSArray *o = [NSUnarchiver unarchiveObjectWithData: d];
							
							if( [o count])
							{
								[r addObjectsFromArray: o];
								[SRAnnotation archiveROIsAsDICOM: [NSArray array] toPath: [i valueForKey: @"completePathResolved"] forImage: image];
							}
						}
					}
					@catch (NSException * e)
					{
                        N2LogExceptionWithStackTrace(e);
					}
				}
			}
			
			if( [r count])
			{
				NSArray *o = [NSUnarchiver unarchiveObjectWithData: [SRAnnotation roiFromDICOM: [[found lastObject] valueForKey: @"completePathResolved"]]];
				[r addObjectsFromArray: o];
                
				[SRAnnotation archiveROIsAsDICOM: r toPath: [[found lastObject] valueForKey: @"completePathResolved"] forImage: image];
			}
		}
		
		if( [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]])
		{
			// Not modified on the 'bonjour client side'?
			if( [[[found lastObject] valueForKey:@"inDatabaseFolder"] boolValue])
			{
				// The ROI file was maybe changed on the server -> delete it
				if( [[found lastObject] valueForKey: @"completePath"])
					[[NSFileManager defaultManager] removeItemAtPath: [[found lastObject] valueForKey: @"completePath"] error: nil];
			}
		}
		
		return [found lastObject];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

- (NSString*) roiPathForImage: (DicomImage*) image
{
	return [self roiPathForImage: image inArray: nil];
}

- (NSString*) roiPathForImage: (DicomImage*) image inArray: (NSArray*) roisArray
{
	NSString *path = nil;
	
	@try 
	{
		DicomImage *roi = [self roiForImage: image inArray: roisArray];
		
		path = [roi valueForKey: @"completePathResolved"];
		
		if( path == nil) // Try the 'old' ROIs folder
			path = [image SRPath];
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return path;
}

- (NSComparisonResult)compareName:(DicomStudy*)study;
{
	return [self.name caseInsensitiveCompare:[study valueForKey:@"name"]];
}

- (NSString*) albumsNames
{
	[self.managedObjectContext lock];
	@try {
		return [[[self.albums allObjects] valueForKey:@"name"] componentsJoinedByString:@"/"];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
	@finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

-(NSArray*) roiImages
{
    NSMutableArray *roiImages = [NSMutableArray array];
    
    NSArray *allImages = [self.images allObjects];
    
    for (DicomImage *roi in [self.roiSRSeries images])
    {
        NSArray *robjs = [NSUnarchiver unarchiveObjectWithData:[SRAnnotation roiFromDICOM:[roi completePath]]];
        if (!robjs.count) continue;
        
        NSInteger it = [roi.comment rangeOfString:@"-" options:NSLiteralSearch+NSBackwardsSearch].location;
        NSString *uid = [roi.comment substringToIndex:it];
        int fid = [[roi.comment substringFromIndex:it+1] intValue];
        // find the image that uses these ROIs
        NSPredicate *p;
        if (fid)
            p = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@ and frameID = %@", uid, [NSNumber numberWithInt:fid]];
        else
            p = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@", uid];
        
        NSArray *found = [allImages filteredArrayUsingPredicate:p];
        if( found.count)
            [roiImages addObject:[found objectAtIndex:0]];
    }
    
    NSSortDescriptor * sortid = [NSSortDescriptor sortDescriptorWithKey:@"series.seriesInstanceUID" ascending: YES comparator: ^NSComparisonResult(id o1, id o2) {
        return [o1 compare: o2 options:NSNumericSearch | NSCaseInsensitiveSearch];
    }];
    
    [roiImages sortUsingDescriptors: [NSArray arrayWithObjects: sortid, [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"instanceNumber" ascending:YES], nil]];
    
    return roiImages;
}

- (NSArray*) roiAndKeyImages
{
    NSMutableArray *images = [NSMutableArray arrayWithArray: [[self roiImages] arrayByAddingObjectsFromArray: self.keyImages.allObjects]];
    
    // remove double entries: first sort, then remove subsequent doubles
    [images sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
     {
         if (obj1 < obj2) return NSOrderedAscending;
         if (obj1 > obj2) return NSOrderedDescending;
         return NSOrderedSame;
     }];
    
    for (NSInteger i = (long)images.count-2; i >= 0; --i)
        if ([images objectAtIndex:i] == [images objectAtIndex:i+1])
            [images removeObjectAtIndex:i+1];
    
    NSSortDescriptor * sortid = [NSSortDescriptor sortDescriptorWithKey:@"series.seriesInstanceUID" ascending: YES comparator: ^NSComparisonResult(id o1, id o2) {
        return [o1 compare: o2 options:NSNumericSearch | NSCaseInsensitiveSearch];
    }];
    
    [images sortUsingDescriptors: [NSArray arrayWithObjects: sortid, [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"instanceNumber" ascending:YES], nil]];
    
    return images;
}

- (NSArray*) generateDICOMSCImagesForKeyImages: (BOOL) keyImages andROIImages: (BOOL) ROIImages
{
#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
    NSArray *images = nil;
    
    if( keyImages && ROIImages)
        images = [self roiAndKeyImages];
    else if( keyImages)
        images = self.keyImages.allObjects;
    else if( ROIImages)
        images = self.roiImages;
    
    NSMutableArray *producedFiles = [NSMutableArray array];
    DICOMExport *exporter = [[[DICOMExport alloc] init] autorelease];
    
    for( DicomImage *image in images)
    {
        NSDictionary *d = [image imageAsDICOMScreenCapture: exporter];
        
        [producedFiles addObject: d];
    }
    
    if( [producedFiles count])
    {
        NSArray *objects = [BrowserController.currentBrowser.database addFilesAtPaths: [producedFiles valueForKey: @"file"]
                                                                    postNotifications: YES
                                                                            dicomOnly: YES
                                                                  rereadExistingItems: YES
                                                                    generatedByOsiriX: YES];
        
        objects = [BrowserController.currentBrowser.database objectsWithIDs: objects];
        
        return  objects;
    }
#endif
#endif
    return nil;
}

- (NSArray*) studiesForThisPatient
{
    NSArray *comparatives = nil;
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
	req.predicate = [NSPredicate predicateWithFormat: @"(patientUID == %@)", self.patientUID];
    
    @try {
        comparatives = [self.managedObjectContext executeFetchRequest: req error: nil];
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
    
    return comparatives;
}

#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
-(NSArray*)authorizedUsers
{
    NSManagedObjectContext* webContext = [WebPortal.defaultWebPortal.database independentContext];
    
    @try
    {
        NSFetchRequest *dbRequest = [NSFetchRequest fetchRequestWithEntityName: @"User"];
        dbRequest.predicate = [NSPredicate predicateWithValue:YES];
        dbRequest.sortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES]];
        
        // Find all users
        NSArray* users = [webContext executeFetchRequest: dbRequest error:NULL];
        
        // Find all comparatives for this patient
        NSArray* allStudies = [self studiesForThisPatient];
        
        NSMutableArray* authorizedUsers = [NSMutableArray array];
        for( WebPortalUser* user in users)
        {
            if( user.studyPredicate.length > 0)
            {
                NSArray *studies = nil;
                
                // First check the studyPredicate of the user
                
                if( user.canAccessPatientsOtherStudies)
                    studies = [allStudies filteredArrayUsingPredicate: [DicomDatabase predicateForSmartAlbumFilter: user.studyPredicate]];
                else
                    studies = [[NSArray arrayWithObject: self] filteredArrayUsingPredicate: [DicomDatabase predicateForSmartAlbumFilter: user.studyPredicate]];
                
                if( studies.count)
                    [authorizedUsers addObject: user];
                
                // And now check his list of specific studies
                else 
                {
                    if( user.canAccessPatientsOtherStudies && [[user.studies.allObjects valueForKey:@"patientUID"] containsObject: self.patientUID])
                        [authorizedUsers addObject: user];
                    
                    else if( [[user.studies.allObjects valueForKey:@"studyInstanceUID"] containsObject: self.studyInstanceUID])
                        [authorizedUsers addObject: user];
                }
            }
            else
                [authorizedUsers addObject: user];
        }
        
        return authorizedUsers;
    }
    @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    
    return nil;
}
#endif
#endif

@end
