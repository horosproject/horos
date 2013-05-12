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

#import "WADOXML.h"

@implementation WADOXML

@synthesize studies, studyInstanceUID, seriesInstanceUID, SOPInstanceUID, wadoURL;

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    [studies release];
    
    studies = [[NSMutableDictionary dictionary] retain];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if( [elementName isEqualToString: @"wado_query"])
        self.wadoURL = [attributeDict objectForKey: @"wadoURL"];
    
    if( [elementName isEqualToString: @"Study"])
    {
        if( [studies objectForKey: [attributeDict objectForKey: @"StudyInstanceUID"]] == nil)
            [studies setObject: [NSMutableDictionary dictionary] forKey: [attributeDict objectForKey: @"StudyInstanceUID"]];
        
        self.studyInstanceUID = [attributeDict objectForKey: @"StudyInstanceUID"];
    }
    
    if( [elementName isEqualToString: @"Series"])
    {
        if( [studies objectForKey: self.studyInstanceUID] == nil)
            NSLog( @"****** [studies objectForKey: self.studyInstanceUID] == nil");
        
        if( [[studies objectForKey: self.studyInstanceUID] objectForKey: [attributeDict objectForKey: @"SeriesInstanceUID"]] == nil)
            [[studies objectForKey: self.studyInstanceUID] setObject: [NSMutableDictionary dictionary] forKey: [attributeDict objectForKey: @"SeriesInstanceUID"]];
        
        self.seriesInstanceUID = [attributeDict objectForKey: @"SeriesInstanceUID"];
    }
    
    if( [elementName isEqualToString: @"Instance"])
    {
        if( [studies objectForKey: self.studyInstanceUID] == nil)
            NSLog( @"****** [studies objectForKey: self.studyInstanceUID] == nil");
        
        if( [[studies objectForKey: self.studyInstanceUID] objectForKey: self.seriesInstanceUID] == nil)
            NSLog( @"****** [[studies objectForKey: self.studyInstanceUID] objectForKey: self.seriesInstanceUID] == nil");
        
        if( [[[studies objectForKey: self.studyInstanceUID] objectForKey: self.seriesInstanceUID] objectForKey: [attributeDict objectForKey: @"SOPInstanceUID"]] == nil)
            [[[studies objectForKey: self.studyInstanceUID] objectForKey: self.seriesInstanceUID] setObject: [NSMutableDictionary dictionary] forKey: [attributeDict objectForKey: @"SOPInstanceUID"]];
        else
            NSLog( @"****** [[[studies objectForKey: self.studyInstanceUID] objectForKey: self.seriesInstanceUID] objectForKey: [attributeDict objectForKey: @\"SOPInstanceUID\"]] != nil");
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{

}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    
}

- (void) parseURL: (NSURL*) url
{
    NSXMLParser * parser = [[[NSXMLParser alloc] initWithContentsOfURL: url] autorelease];
    
    [parser setDelegate: self];
    
    [parser parse];
}

- (NSArray*) getWADOUrls
{
    NSMutableArray *urls = [NSMutableArray array];
    
    NSString *baseURL = [NSString stringWithFormat: @"%@?requestType=WADO", self.wadoURL];
    
    for( NSString *StudyUID in studies)
    {
        for( NSString *SeriesUID in [studies objectForKey: StudyUID])
        {
            for( NSString *SOPUID in [[studies objectForKey: StudyUID] objectForKey: SeriesUID])
            {
                NSString *url = [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@", StudyUID, SeriesUID, SOPUID, @"&useOrig=true"];
                
                [urls addObject: [NSURL URLWithString: url]];
            }
        }
    }
    
    return urls;
}

- (void) dealloc
{
    [studies release];
    
    self.seriesInstanceUID = nil;
    self.studyInstanceUID = nil;
    self.SOPInstanceUID = nil;
    self.wadoURL = nil;
    
    [super dealloc];
}

@end
