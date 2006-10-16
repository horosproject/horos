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

#import <QTKit/QTKit.h>
#import "QuicktimeExport.h"
#import "Wait.h"
#import "WaitRendering.h"

NSString * documentsDirectory();

@implementation QuicktimeExport

- (id) initWithSelector:(id) o :(SEL) s :(long) f
{
	[super init];
	
	[NSBundle loadNibNamed:@"QuicktimeExport" owner:self];
	
	object = o;
	selector = s;
	numberOfFrames = f;
	
	return self;
}

#if !__LP64__
- (NSArray *)availableComponents
{
	NSMutableArray *array = [NSMutableArray array];
	
	ComponentDescription cd;
	Component c;
	
	cd.componentType = MovieExportType;
	cd.componentSubType = kQTFileTypeMovie;
	cd.componentManufacturer = kAppleManufacturer;
	cd.componentFlags = hasMovieExportUserInterface;
	cd.componentFlagsMask = hasMovieExportUserInterface;
	c = FindNextComponent( 0, &cd );
	
	if( c)
	{
		Handle name = NewHandle(4);
		ComponentDescription exportCD;
		
		if (GetComponentInfo(c, &exportCD, name, nil, nil) == noErr)
		{
			unsigned char *namePStr = (unsigned char*) *name;
			NSString *nameStr = [[NSString alloc] initWithBytes:&namePStr[1] length:namePStr[0] encoding:NSUTF8StringEncoding];
			
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				nameStr, @"name",
				[NSData dataWithBytes:&c length:sizeof(c)], @"component",
				[NSNumber numberWithLong:exportCD.componentType], @"type",
				[NSNumber numberWithLong:exportCD.componentSubType], @"subtype",
				[NSNumber numberWithLong:exportCD.componentManufacturer], @"manufacturer",
				nil];
			[array addObject:dictionary];
			[nameStr release];
		}
		
		DisposeHandle(name);
	}
	
	cd.componentType = MovieExportType;
	cd.componentSubType = kQTFileTypeAVI;
	cd.componentManufacturer = kAppleManufacturer;
	cd.componentFlags = hasMovieExportUserInterface;
	cd.componentFlagsMask = hasMovieExportUserInterface;
	c = FindNextComponent( 0, &cd );
	
	if( c)
	{
		Handle name = NewHandle(4);
		ComponentDescription exportCD;
		
		if (GetComponentInfo(c, &exportCD, name, nil, nil) == noErr)
		{
			unsigned char *namePStr = (unsigned char*) *name;
			NSString *nameStr = [[NSString alloc] initWithBytes:&namePStr[1] length:namePStr[0] encoding:NSUTF8StringEncoding];
			
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				nameStr, @"name",
				[NSData dataWithBytes:&c length:sizeof(c)], @"component",
				[NSNumber numberWithLong:exportCD.componentType], @"type",
				[NSNumber numberWithLong:exportCD.componentSubType], @"subtype",
				[NSNumber numberWithLong:exportCD.componentManufacturer], @"manufacturer",
				nil];
			[array addObject:dictionary];
			[nameStr release];
		}
		
		DisposeHandle(name);
	}
	
	cd.componentType = MovieExportType;
	cd.componentSubType = kQTFileTypeMP4;
	cd.componentManufacturer = kAppleManufacturer;
	cd.componentFlags = hasMovieExportUserInterface;
	cd.componentFlagsMask = hasMovieExportUserInterface;
	c = FindNextComponent( 0, &cd );
	
	if( c)
	{
		Handle name = NewHandle(4);
		ComponentDescription exportCD;
		
		if (GetComponentInfo(c, &exportCD, name, nil, nil) == noErr)
		{
			unsigned char *namePStr = (unsigned char*) *name;
			NSString *nameStr = [[NSString alloc] initWithBytes:&namePStr[1] length:namePStr[0] encoding:NSUTF8StringEncoding];
			
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				nameStr, @"name",
				[NSData dataWithBytes:&c length:sizeof(c)], @"component",
				[NSNumber numberWithLong:exportCD.componentType], @"type",
				[NSNumber numberWithLong:exportCD.componentSubType], @"subtype",
				[NSNumber numberWithLong:exportCD.componentManufacturer], @"manufacturer",
				nil];
			[array addObject:dictionary];
			[nameStr release];
		}
		
		DisposeHandle(name);
	}
	
	return array;
}

- (NSData *)getExportSettings:(QTMovie*) aMovie component:(NSDictionary*) component
{
	Component c;
	
	memcpy(&c, [[component objectForKey:@"component"] bytes], sizeof(c));
	
	MovieExportComponent exporter = OpenComponent(c);
	Boolean canceled;
	
	Movie theMovie = [aMovie quickTimeMovie] ;
	TimeValue duration = GetMovieDuration(theMovie) ;
	
	ComponentResult err;
	
	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey: [NSString stringWithFormat:@"Quicktime Export:%d", [component valueForKey:@"subtype"]]];
	char	*ptr = (char*) [data bytes];
	
	if( data) MovieExportSetSettingsFromAtomContainer (exporter, &ptr);
	
	err = MovieExportDoUserDialog(exporter, theMovie, NULL, 0, duration, &canceled);
	if(err)
	{
		NSLog(@"Got error %d when calling MovieExportDoUserDialog");
		CloseComponent(exporter);
		return nil;
	}
	if(canceled)
	{
		CloseComponent(exporter);
		return nil;
	}
	
	QTAtomContainer settings;
	err = MovieExportGetSettingsAsAtomContainer(exporter, &settings);
	if(err)
	{
		NSLog(@"Got error %d when calling MovieExportGetSettingsAsAtomContainer");
		CloseComponent(exporter);
		return nil;
	}
	
	data = [NSData dataWithBytes:*settings length:GetHandleSize(settings)];	
	[[NSUserDefaults standardUserDefaults] setObject:data forKey: [NSString stringWithFormat:@"Quicktime Export:%d", [component valueForKey:@"subtype"]]];
	
	DisposeHandle(settings);

	CloseComponent(exporter);
	
	return data;
}

- (BOOL) writeMovie:(QTMovie *)movie toFile:(NSString *)file withComponent:(NSDictionary *)component withExportSettings:(NSData *)exportSettings
{
	if( exportSettings == 0L) return;
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], QTMovieExport,
		[component objectForKey:@"subtype"], QTMovieExportType,
		[component objectForKey:@"manufacturer"], QTMovieExportManufacturer,
		exportSettings, QTMovieExportSettings,
		nil];
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Movie encoding...", nil)];
	[wait showWindow:self];
	
	BOOL result = [movie writeToFile:file withAttributes:attributes];
	if(!result)
	{
		NSLog(@"Couldn't write movie to file");
		return NO;
	}
	
	[wait close];
	[wait release];
	
	return YES;
}

- (IBAction) setRate:(id) sender
{
	[rateValue setStringValue: [NSString stringWithFormat:@"%d im/s", [sender intValue]]];
}

- (IBAction) changeExportType:(id) sender
{
	unsigned long subtype = [[[exportTypes objectAtIndex: [type indexOfSelectedItem]] valueForKey:@"subtype"] unsignedLongValue];
	
	if( subtype == kQTFileTypeMovie)  [panel setRequiredFileType:@"mov"];
	if( subtype == kQTFileTypeAVI)	[panel setRequiredFileType:@"avi"];
	if( subtype == kQTFileTypeMP4)	[panel setRequiredFileType:@"mpg4"];
}

- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name
{
	NSString		*fileName;
	long			result;

	exportTypes = [self availableComponents];
	
	panel = [NSSavePanel savePanel];
	
	if( produceFiles)
	{
		result = NSFileHandlingPanelOKButton;
		
		[[NSFileManager defaultManager] removeFileAtPath: [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"] handler: 0L];
		[[NSFileManager defaultManager] createDirectoryAtPath: [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"] attributes: 0L];
		
		fileName = [documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriXMovie.mov"];
	}
	else
	{
		[panel setCanSelectHiddenExtension:YES];
		[panel setRequiredFileType:@"mov"];
		
		[panel setAccessoryView: view];
		[type removeAllItems];
				
		[type addItemsWithTitles: [exportTypes valueForKey: @"name"]];

		result = [panel runModalForDirectory:0L file:name];
		
		fileName = [panel filename];
	}
	
	if( result == NSFileHandlingPanelOKButton)
	{
		int				maxImage, myState, curSample = 0;
		Movie			qtMovie = 0L;
		QTTime			curTime;
		QTMovie			*mMovie = 0L;
		
		if( produceFiles == NO)
		{
			[[QTMovie movie] writeToFile: [fileName stringByAppendingString:@"temp"] withAttributes: 0L];
			
			mMovie = [QTMovie movieWithFile:[fileName stringByAppendingString:@"temp"] error:nil];
			[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			
			long long timeValue = 600 / [rateSlider intValue];
			long timeScale = 600;
			
			curTime = QTMakeTime(timeValue, timeScale);
		}
		
		Wait    *wait = [[Wait alloc] initWithString:0L :NO];
		[wait showWindow:self];
		
		// For each sample...
		maxImage = numberOfFrames;

		[wait setCancel:YES];
		[[wait progress] setMaxValue:maxImage];
		
		NSDictionary *myDict = [NSDictionary dictionaryWithObject: @"jpeg" forKey: QTAddImageCodecType];
		
		for (curSample = 0; curSample < maxImage; curSample++) 
		{
			[wait incrementBy:1];
			
			NSImage	*im = [object performSelector: selector withObject: [NSNumber numberWithLong: curSample] withObject:[NSNumber numberWithLong: numberOfFrames]];
			
			if( im)
			{
				if( produceFiles == NO)
				{
					[mMovie addImage:im forDuration:curTime withAttributes: myDict];
				}
				else
				{
					NSString *curFile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/OsiriX%4d.tif", curSample];
					
					[[im TIFFRepresentation] writeToFile:curFile atomically:YES];
				}
							
				[im release];
			}
			
			if( [wait aborted]) curSample = maxImage;
		}
		[wait close];
		
		[wait release];
		
		if( produceFiles == NO)
		{
			[[NSFileManager defaultManager] removeFileAtPath:fileName handler:0L];
			
			NSData	*exportSettings = [self getExportSettings: mMovie component: [exportTypes objectAtIndex: [type indexOfSelectedItem]]];
		
			if( exportSettings)
			{
				[self writeMovie:mMovie toFile:fileName withComponent:[exportTypes objectAtIndex: [type indexOfSelectedItem]] withExportSettings: exportSettings];
			
				if( openIt)
				{
					NSWorkspace *ws = [NSWorkspace sharedWorkspace];
					[ws openFile:fileName];
				}
			}
			[[NSFileManager defaultManager] removeFileAtPath:[fileName stringByAppendingString:@"temp"] handler:0L];
		}
		
		return fileName;
	}
	
	return 0L;
}
#endif

@end
