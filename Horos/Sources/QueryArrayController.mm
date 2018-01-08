/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "DefaultsOsiriX.h"
#import "QueryArrayController.h"
#import "DCM.h"
#import "DCMNetServiceDelegate.h"
#import "DCMAbstractSyntaxUID.h"

#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import "DCMTKSeriesQueryNode.h"
#import "DCMTKImageQueryNode.h"
#import "MutableArrayCategory.h"
#import "N2Debug.h"

@implementation QueryArrayController

- (id)initWithCallingAET:(NSString *) myAET distantServer: (NSDictionary*) ds;
{
	if (self = [super init])
	{
		rootNode = nil;
		filters = [[NSMutableDictionary dictionary] retain];
		callingAET = [myAET retain];
		
		distantServer = [ds retain];
		calledAET = [[ds valueForKey: @"AETitle"] retain];
		hostname = [[ds valueForKey: @"Address"] retain];
		port = [[ds valueForKey: @"Port"] retain];
		
		queries = nil;
	}
	return self;
}

- (id)rootNode
{
	return rootNode;
}

- (void)dealloc
{
    @synchronized( self)
    {
        [queryLock lock];
        
        [rootNode release];
        [filters release];
        [calledAET release];
        [callingAET release];
        [hostname release];
        [port release];
        [queries release];
        [distantServer release];
        
        [queryLock unlock];
        [queryLock release];
	}
    
	[super dealloc];
}

- (NSMutableDictionary*) filters
{
    return filters;
}

- (void)addFilter:(id)filter forDescription:(NSString *)description
{
	if ([description rangeOfString:@"Date"].location != NSNotFound)
		filter = [DCMCalendarDate queryDate:filter];
	
	else if ([description rangeOfString:@"Time"].location != NSNotFound)
		filter = [DCMCalendarDate queryDate:filter];
	
    if( filter)
        [filters setObject:filter forKey:description];
}

- (NSArray *)queries
{
    @synchronized( self)
    {
        return queries;
    }
    
    return nil;
}

- (void)sortArray:(NSArray *)sortDesc
{
    @synchronized( self)
    {
        NSArray *newQueries = [queries sortedArrayUsingDescriptors:sortDesc];
        [queries release];
        queries = [newQueries retain];
    }
}

- (void)performQuery: (BOOL) showError
{
	if( queryLock == nil) queryLock = [[NSLock alloc] init];
    
	[queryLock lock];
	
	@try
    {
        BOOL sameAddress = NO;
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"])
        {
            if( [port intValue] == [[NSUserDefaults standardUserDefaults] integerForKey: @"AEPORT"])
            {
                for( NSString *s in [[DefaultsOsiriX currentHost] names])
                {
                    if( [hostname isEqualToString: s])
                        sameAddress = YES;
                }
                
                for( NSString *s in [[DefaultsOsiriX currentHost] addresses])
                {
                    if( [hostname isEqualToString: s])
                        sameAddress = YES;
                }
            }
        }
        
        if( sameAddress)
        {
            if( [NSThread isMainThread] && showError)
            {
                NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedString( @"Query Error", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", NSLocalizedString( @"OsiriX cannot generate a DICOM query on itself.", nil)];
                [alert runModal];
            }
        }
        else
        {
            @synchronized( self)
            {
                [rootNode release];
                rootNode = [[DCMTKRootQueryNode queryNodeWithDataset: nil
                                                callingAET: callingAET
                                                calledAET: calledAET 
                                                hostname: hostname
                                                port: [port intValue]
                                                transferSyntax: 0		//EXS_LittleEndianExplicit / EXS_JPEGProcess14SV1TransferSyntax
                                                compression:0.f
                                                extraParameters: distantServer] retain];
                                                
                NSMutableArray *filterArray = [NSMutableArray array];
                NSEnumerator *enumerator = [filters keyEnumerator];
                NSString *key;
                while (key = [enumerator nextObject])
                {
                    if ([filters objectForKey:key])
                    {
                        NSDictionary *filter = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[filters objectForKey:key], key, nil] forKeys:[NSArray arrayWithObjects:@"value",  @"name", nil]];
                        [filterArray addObject:filter];
                    }
                }
                [rootNode setShowErrorMessage: showError];
                [rootNode queryWithValues:filterArray];
                
        //		NSLog( @"Query values: %@", filterArray);
                
                if( [[NSThread currentThread] isCancelled] == NO)
                {
                    [queries release];
                    queries = nil;
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontFilterQueryStudiesForUniqueInstanceUID"] == NO)
                    {
                        NSMutableArray *tempResult = [NSMutableArray arrayWithArray: [rootNode children]];
                        NSMutableArray *uidsArray = [NSMutableArray arrayWithArray: [tempResult valueForKey:@"uid"]];
                        NSArray *sortedUidsArray = [uidsArray sortedArrayUsingSelector: @selector(compare:)];
                        
                        NSString *lastString = nil;
                        
                        for( NSString *s in sortedUidsArray)
                        {
                            if( [s isEqualToString: lastString])
                            {
                                NSUInteger index1 = [uidsArray indexOfObject: s];
                                NSUInteger index2 = [uidsArray indexOfObject: lastString];
                                
                                if( index1 != NSNotFound && index2 != NSNotFound)
                                {
                                    if( [[[tempResult objectAtIndex: index1] numberImages] intValue] < [[[tempResult objectAtIndex: index2] numberImages] intValue])
                                    {
                                        [uidsArray removeObjectAtIndex: index1];
                                        [tempResult removeObjectAtIndex: index1];
                                    }
                                    else
                                    {
                                        [uidsArray removeObjectAtIndex: index2];
                                        [tempResult removeObjectAtIndex: index2];
                                    }
                                }
                            }
                            else lastString = s;
                        }
                        
                        if( [tempResult count])
                            queries = [tempResult retain];
                    }
                    
                    if( queries == nil)
                        queries = [[rootNode children] retain];
                }
                
                if( queries == nil && rootNode != nil)
                    queries = [[NSMutableArray array] retain];
            }
        }
    }
    @catch (NSException * e)
    {	
        if( [NSThread isMainThread] && showError)
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Query Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Query Failed"];
            [alert runModal];
        }
        N2LogExceptionWithStackTrace( e);
	}
	
	[queryLock unlock];
}

- (void) performQuery
{
	return [self performQuery: YES];
}

- (NSDictionary *)parameters
{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	@try {
		
		[params setObject: [NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:callingAET forKey:@"callingAET"];
		[params setObject:calledAET forKey:@"calledAET"];
		[params setObject:hostname forKey:@"hostname"];
		[params setObject:port forKey:@"port"];
		
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];		//
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelFind] forKey:@"affectedSOPClassUID"];
	} @catch( NSException *localException) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Query Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Unable to perform Q/R. There was a missing parameter. Make sure you have AE Titles, IP addresses and ports for the queried computer"];
	
		[alert runModal];
		NSLog(@"Missing parameter for Query/retrieve: %@", [localException name]);
		params = nil;
	}
	return params;
}
@end
