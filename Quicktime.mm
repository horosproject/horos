#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

// WHY THIS EXTERNAL APPLICATION FOR QUICKTIME?

// 64-bits apps support only very basic Quicktime API
// Quicktime is not multi-thread safe: highly recommended to use it only on the main thread

extern "C"
{
	extern OSErr VRObject_MakeObjectMovie (FSSpec *theMovieSpec, FSSpec *theDestSpec, long maxFrames);
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	EnterMovies();
	
//	argv[ 1] = "generateQTVR";
//	argv[ 2] = "/Users/antoinerosset/Desktop/a.mov";
//	argv[ 3] = "100";
	
	//	argv[ 1] : what to do?
	//	argv[ 2] : Path for Quicktime file
		
	if( argv[ 1] && argv[ 2])
	{
		NSString	*what = [NSString stringWithCString:argv[ 1]];
		NSString	*path = [NSString stringWithCString:argv[ 2]];
		
		NSLog( what);
		NSLog( path);
		
		if( [what isEqualToString:@"getFrame"])
		{
			int frameNo = [[NSString stringWithCString:argv[ 3]] intValue];
			
			QTMovie *movie = [[QTMovie alloc] initWithFile:path error: 0L];
			
			if( movie)
			{
				int curFrame = 0;
				[movie gotoBeginning];
				
				QTTime previousTime;
				
				curFrame = 0;
				
				while( QTTimeCompare( previousTime, [movie currentTime]) == NSOrderedAscending && curFrame != frameNo)
				{
					previousTime = [movie currentTime];
					curFrame++;
					[movie stepForward];
				}
				
				//[result addObject: [movie currentFrameImage]];
				
				[movie release];
			}
		}
		
		if( [what isEqualToString:@"generateQTVR"] && argv[ 3])
		{
			// argv[ 3] = frameNo
			
			int frameNo = [[NSString stringWithCString:argv[ 3]] intValue];
			
			FSRef				fsref;
			FSSpec				spec, newspec;
			
			FSPathMakeRef((unsigned const char *)[path fileSystemRepresentation], &fsref, NULL);
			FSGetCatalogInfo( &fsref, kFSCatInfoNone,NULL, NULL, &spec, NULL);
			
			FSMakeFSSpec(spec.vRefNum, spec.parID, "\ptempMovie", &newspec);
			
			VRObject_MakeObjectMovie( &spec, &newspec, frameNo);
		}
		
		if( [what isEqualToString:@"getExportSettings"] && argv[ 3] && argv[ 4] && argv[ 5])
		{
			[NSRunLoop currentRunLoop];
			
			QTMovie *aMovie = [[QTMovie alloc] initWithFile:path error: 0L];
			
			NSLog( @"getExportSettings : %@", path);
			
			// argv[ 3] = component dictionary path
			// argv[ 4] = pref nsdata path IN
			// argv[ 5] = pref nsdata path OUT
			
			if( aMovie)
			{
				NSDictionary *component = [NSDictionary dictionaryWithContentsOfFile: [NSString stringWithCString:argv[ 3]]];
				
				NSLog( [component description]);
				
				
				// **** See QuicktimeExport.m
				
				Component c;
				ComponentDescription cd;
				
				cd.componentType = [[component objectForKey: @"type"] longValue];
				cd.componentSubType = [[component objectForKey: @"subtype"] longValue];
				cd.componentManufacturer = [[component objectForKey: @"manufacturer"] longValue];
				cd.componentFlags = hasMovieExportUserInterface;
				cd.componentFlagsMask = hasMovieExportUserInterface;
				c = FindNextComponent( 0, &cd );
				
				MovieExportComponent exporter = OpenComponent(c);
				
				Boolean canceled;
				
				Movie theMovie = [aMovie quickTimeMovie];
				TimeValue duration = GetMovieDuration(theMovie);
				
				ComponentResult err;
				
				NSData *data = [NSData dataWithContentsOfFile: [NSString stringWithCString:argv[ 4]]];
				char	*ptr = (char*) [data bytes];
				
				if( data) MovieExportSetSettingsFromAtomContainer (exporter, &ptr);
				
				err = MovieExportDoUserDialog(exporter, theMovie, NULL, 0, duration, &canceled);
				if( err == NO && canceled == NO)
				{
					QTAtomContainer settings;
					err = MovieExportGetSettingsAsAtomContainer(exporter, &settings);
					if(err)
					{
						NSLog(@"Got error %d when calling MovieExportGetSettingsAsAtomContainer");
					}
					else
					{
						data = [NSData dataWithBytes:*settings length:GetHandleSize(settings)];	
						
						DisposeHandle(settings);
						CloseComponent(exporter);
						
						// **************************
						
						NSString	*dataPath = [NSString stringWithCString:argv[ 5]];
						[[NSFileManager defaultManager] removeFileAtPath: dataPath handler: 0L];
						[data writeToFile: dataPath atomically: YES];
					}
				}
				[aMovie release];
			}
		}
	}
	
	ExitMovies();
	
	[pool release];
	
	return 0;
}
