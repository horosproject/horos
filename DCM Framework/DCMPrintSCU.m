//
//  DCMPrintSCU.m
//  OsiriX
//
//  Created by Lance Pysher on 9/2/05.

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
//

#import "DCMPrintSCU.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMPrintSCU

- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init] ){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abortEcho:) name:@"DCMAbortEchoNotification" object:nil];
		debugLevel = 0;
		if ([params objectForKey:@"debugLevel"])
			debugLevel = [[params objectForKey:@"debugLevel"] intValue];
		NSMutableArray *contexts = [NSMutableArray array];

		DCMPresentationContext *context = [DCMPresentationContext contextWithID:0x01];		
		[context addTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]];
		[context setAbstractSyntax:[DCMAbstractSyntaxUID verificationClassUID]];
		[contexts addObject:context];
		
		NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
		[newParams setObject:contexts forKey:@"presentationContexts"];
		[newParams setObject:[NSNumber numberWithInt:debugLevel] forKey:@"debugLevel"];
		[newParams setObject:self  forKey:@"delegate"];
		 _dataHandler = [[DCMPrintResponseHandler alloc] initWithDebugLevel:debugLevel];
		[newParams setObject:_dataHandler forKey:@"receivedDataHandler"];
		if (debugLevel)
			NSLog(@"Create association for verification");
		association  = [[DCMAssociation associationInitiatorWithParameters:newParams] retain];
		if (debugLevel)
			NSLog(@"Association: %@", [association description]);
		//[association setReceivedDataHandler:nil];
		[pool release];
	}
	return self;
}

- (void)dealloc{
	[_filmSession release];
	[_sessionObject release];
	[super dealloc];
}

- (DCMNCreateRequest *)filmSession{
	if (!_filmSession)
		_filmSession = [[DCMNCreateRequest filmSessionInColor:_isColor] retain];
	return _filmSession;		
}

- (DCMObject *)sessionObject{
	if (!_sessionObject){
	}
	return _sessionObject;
}
		
- (BOOL)createFilmBox{
	return 0;
}
- (BOOL)createImageBox{
	return 0;
}

- (BOOL)print{
	if (association && [association isConnected]){
		if (debugLevel)
			NSLog(@"Start sending");
		 //_usePresentationContextID = [association presentationContextIDForAbstractSyntax:affectedSOPClassUID];
		// _transferSyntax = [[association transferSyntaxForPresentationContextID:usePresentationContextID] retain];
		 if (debugLevel)
			NSLog(@"using transfer syntax:%@", [_transferSyntax description]);
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//create film session
		
		[association send:[[self filmSession] data]  asCommand:YES  presentationContext:_usePresentationContextID];
		[association send:[[self sessionObject] writeDatasetWithTransferSyntax:_transferSyntax quality:100] asCommand:NO
				presentationContext:_usePresentationContextID];
		[association waitForPDataPDUsUntilHandlerReportsDone];
			// get layout. will need to create a FilmBox for each sheet of film
		
		[pool release];
		
	}
	return 0;
}


@end
