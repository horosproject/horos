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

#import "DicomStudy+Report.h"
#import "DicomSeries.h"
#import "N2Shell.h"
#import "NSString+N2.h"
#import "N2Debug.h"
#import "NSAppleScript+N2.h"
#import "NSFileManager+N2.h"
#import "DCMObject.h"
#import "DCMEncapsulatedPDF.h"
#import "DicomImage.h"
#import "DCMCalendarDate.h"
#import "DCMTransferSyntax.h"
#import "DCM.h"
#import "Reports.h"

@implementation DicomStudy (Report)

+(void)_transformOdtAtPath:(NSString*)odtPath toPdfAtPath:pdfPath
{
    // determine the default app for ODT files
    NSURL* applicationUrl = NULL;
    OSStatus status = LSGetApplicationForInfo(kLSUnknownType, kLSUnknownCreator, CFSTR("odt"), kLSRolesAll, NULL, (CFURLRef*)&applicationUrl);
    if (status) [NSException raise:NSGenericException format:@"can't find custom application for ODT files"];
    NSString* applicationPath = applicationUrl.path;
    
    if( [applicationPath contains: @"LibreOffice"])
    {
        // ./soffice --headless --convert-to pdf /Users/antoinerosset/Desktop/-28199--A10075196600.odt
        
        @try {
            NSTask* task = [[[NSTask alloc] init] autorelease];
            
            [task setLaunchPath: [applicationPath stringByAppendingPathComponent:@"Contents/MacOS/soffice"]];
            [task setCurrentDirectoryPath: [odtPath stringByDeletingLastPathComponent]];
            [task setArguments: [NSArray arrayWithObjects: @"--headless", @"--convert-to", @"pdf", odtPath, nil]];
            [task setStandardOutput:[NSPipe pipe]];
            [task launch];
            while( [task isRunning])
                [NSThread sleepForTimeInterval: 0.1];
            
            //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
            
            BOOL succeeded = NO;
            
            if ([task terminationStatus] == 0)
                succeeded = YES;
            
            if( succeeded) {
                [[NSFileManager defaultManager] moveItemAtPath: [[odtPath stringByDeletingPathExtension] stringByAppendingPathExtension: @"pdf"] toPath: pdfPath error: nil];
            }
            else
                N2LogStackTrace( @"LibreOffice: PDF conversion failed");
            
        } @catch (NSException* e) {
            N2LogException( e);
        }
    }
    else
    {
        NSString* sofficePath = [applicationPath stringByAppendingPathComponent:@"Contents/MacOS/soffice"];
        
        // determine if soffice wants --accept or -accept
        
        NSString* acceptString = nil;
        NSString* sofficeHelp = [N2Shell execute:sofficePath arguments:[NSArray arrayWithObject:@"-help"]];
        if ([sofficeHelp contains:@"--accept"])
            acceptString = @"--accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager";
        else acceptString = @"-accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager";
        
        // LibreOffice is moving files around.....
        
        NSString* offapiPath = nil;
        for (NSString* subpath in [NSArray arrayWithObjects:@"Contents/MacOS/types/offapi.rdb", @"Contents/basis-link/program/offapi.rdb", @"Contents/MacOS/oovbaapi.rdb", nil]) {
            offapiPath = [applicationPath stringByAppendingPathComponent:subpath];
            if ([NSFileManager.defaultManager fileExistsAtPath:offapiPath])
                break;
            else offapiPath = nil;
        }
        
        NSString* urelinklibPath = nil;
        for (NSString* subpath in [NSArray arrayWithObjects:@"Contents/ure-link/lib", @"Contents/basis-link/ure-link/lib", @"Contents/MacOS/urelibs", nil]) {
            urelinklibPath = [applicationPath stringByAppendingPathComponent:subpath];
            if ([NSFileManager.defaultManager fileExistsAtPath:urelinklibPath])
                break;
            else urelinklibPath = nil;
        }
        
        if (!offapiPath || !urelinklibPath)
            [NSException raise:NSGenericException format:@"can't find necessary items inside %@", [applicationPath lastPathComponent]];
        
        // launch soffice to make sure it's accepting sdk interactions
        
        NSString* command = [NSString stringWithFormat:@"%@ \"%@\" &", sofficePath, acceptString];
        system(command.UTF8String);
        
        // wait for a few secs until the port is actually open (soffice can take some time to launch...)
        
        BOOL succeeded = NO;
        NSException* lastException = nil;
        NSString* lastStdOut = nil;
        
        NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
        while (!succeeded && [NSDate timeIntervalSinceReferenceDate] < startTime+10) {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            @try {
                NSTask* task = [[[NSTask alloc] init] autorelease];
                
                [task setLaunchPath:[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"odt2pdf"]];
                [task setArguments:[NSArray arrayWithObjects: [NSString stringWithFormat:@"-env:URE_MORE_TYPES=file://%@", offapiPath], odtPath, pdfPath, nil]];
                [task setEnvironment:[NSDictionary dictionaryWithObject:urelinklibPath forKey:@"DYLD_LIBRARY_PATH"]];
                [task setStandardOutput:[NSPipe pipe]];
                [task launch];
                while( [task isRunning])
                    [NSThread sleepForTimeInterval: 0.1];
                
                //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                
                if ([task terminationStatus] == 0)
                    succeeded = YES;
                
                [lastStdOut release];
                lastStdOut = [[[[[NSString alloc] initWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
                
                if (!succeeded) [NSThread sleepForTimeInterval:0.25];
            } @catch (NSException* e) {
                [lastException release];
                lastException = [e retain];
            } @finally {
                [pool release];
            }
        }
        
        [lastStdOut autorelease];
        [lastException autorelease];
        
        if (!succeeded && lastException)
            @throw lastException;
        
        if (lastStdOut.length)
            NSLog(@"%@", lastStdOut);
    }
}

+(id)_runAppleScriptAtPath:(NSString*)path withArguments:(NSArray*)args
{
    NSError* err = nil;
    NSDictionary* errs = nil;
    
    if (!path) [NSException raise:NSGenericException format:@"NULL script path"];
    
    NSString* source = [NSString stringWithContentsOfFile:path usedEncoding:NULL error:&err];
    if (err) [NSException raise:NSGenericException format:@"%@", err.localizedDescription];
    if (!source) [NSException raise:NSGenericException format:@"Couldn't read script source"];
    
    NSAppleScript* script = [[[NSAppleScript alloc] initWithSource:source] autorelease];
    if (!script) [NSException raise:NSGenericException format:@"Invalid script source"];
    
    id r = [script runWithArguments:args error:&errs];
    if (errs) [NSException raise:NSGenericException format:@"%@", errs];
    
    return r;
}

+(void)transformReportAtPath:(NSString*)reportPath toPdfAtPath:(NSString*)outPdfPath
{
    if ([reportPath.pathExtension.lowercaseString isEqualToString:@"odt"])
    {
        [[self class] _transformOdtAtPath:reportPath toPdfAtPath:outPdfPath];
    }
    else  if ([reportPath.pathExtension.lowercaseString isEqualToString:@"rtf"] || [reportPath.pathExtension.lowercaseString isEqualToString:@"rtfd"])
    {
        int result = 0;
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: @"/System/Library/Printers/Libraries/convert"]) // Not available anymore in 10.8
            [N2Shell execute:@"/System/Library/Printers/Libraries/convert" arguments:[NSArray arrayWithObjects: @"-f", reportPath, @"-o", outPdfPath, nil] outStatus:&result];
        else if( [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/sbin/cupsfilter"])
        {
            [NSFileManager.defaultManager removeItemAtPath: outPdfPath error:nil];
            [NSFileManager.defaultManager createFileAtPath: outPdfPath contents:[NSData data] attributes:nil];
            
            NSTask* task = [[[NSTask alloc] init] autorelease];
            [task setLaunchPath: @"/usr/sbin/cupsfilter"];
            [task setArguments: [NSArray arrayWithObjects: reportPath, nil]];
            [task setStandardOutput:[NSFileHandle fileHandleForWritingAtPath: outPdfPath]];
            [task setStandardError:[NSPipe pipe]];
            
            [task launch];
            while( [task isRunning])
                [NSThread sleepForTimeInterval: 0.1];
        }
        else
            NSLog( @"************* no converter tool available");
    }
    else if ([reportPath.pathExtension.lowercaseString isEqualToString:@"pages"])
    {
        NSString *path = nil;
        if( [Reports Pages5orHigher])
            path = [[NSBundle mainBundle] pathForResource:@"pages2pdf" ofType:@"applescript"];
        else
            path = [[NSBundle mainBundle] pathForResource:@"pages092pdf" ofType:@"applescript"];
        
        [[self class] _runAppleScriptAtPath:path withArguments:[NSArray arrayWithObjects: reportPath, outPdfPath, nil]];
    }
    else if ([reportPath.pathExtension.lowercaseString isEqualToString:@"doc"] || [reportPath.pathExtension.lowercaseString isEqualToString:@"docx"]) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"word2pdf" ofType:@"applescript"];
        [[self class] _runAppleScriptAtPath:path withArguments:[NSArray arrayWithObjects: reportPath, outPdfPath, nil]];
    }
    else
        [NSException raise:NSGenericException format:@"Can't transform report to PDF: %@", reportPath];
}

-(void)saveReportAsPdfAtPath:(NSString*)path
{
    [[self class] transformReportAtPath:self.reportURL toPdfAtPath:path];
}

-(NSString*)saveReportAsPdfInTmp
{
    NSString* path = [NSFileManager.defaultManager tmpFilePathInTmp];
    
    path = [path stringByAppendingPathExtension: @"pdf"];
    
    [self saveReportAsPdfAtPath:path];
    
    return path;
}

+(BOOL)_ifAvailableCopyAttributeWithName:(NSString*)name from:(DCMObject*)from to:(DCMObject*)to alternatively:(id)altvalue 
{
    id attribute = [from attributeValueWithName:name];
    id thevalue = attribute;
    if (!thevalue && altvalue)
        thevalue = [altvalue isKindOfClass:[NSArray class]] ? altvalue : [NSArray arrayWithObject:altvalue];
    if (thevalue)
    {
        thevalue = [thevalue isKindOfClass:[NSArray class]] ? thevalue : [NSArray arrayWithObject: thevalue];
        [to setAttributeValues:thevalue forName:name];
    }
    return attribute != nil;
}

+(BOOL)_ifAvailableCopyAttributeWithName:(NSString*)name from:(DCMObject*)from to:(DCMObject*)to
{
    return [self _ifAvailableCopyAttributeWithName:name from:from to:to alternatively:nil];
}

+(void)transformPdfAtPath:(NSString*)pdfPath toDicomAtPath:(NSString*)outDicomPath usingSourceDicomAtPath:(NSString*)sourcePath
{
    DCMObject* source = [DCMObject objectWithContentsOfFile:sourcePath decodingPixelData:NO];
    
    DCMObject* output = [DCMObject encapsulatedPDF:[NSFileManager.defaultManager contentsAtPath:pdfPath]];
    
    NSString *reportName = NSLocalizedString( @"Report PDF", nil);
    
    if( [[NSUserDefaults standardUserDefaults] objectForKey: @"ReportName"])
        reportName = [[NSUserDefaults standardUserDefaults] objectForKey: @"ReportName"];
    
//    [self _ifAvailableCopyAttributeWithName:@"SpecificCharacterSet" from:source to:output alternatively:@"ISO_IR 100"];
    [self _ifAvailableCopyAttributeWithName:@"SpecificCharacterSet" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"StudyInstanceUID" from:source to:output];
    [output setAttributeValues:[NSMutableArray arrayWithObject: reportName] forName:@"SeriesDescription"];
    [output setAttributeValues:[NSMutableArray arrayWithObject:@"1"] forName:@"InstanceNumber"];
    [output setAttributeValues:[NSMutableArray arrayWithObject:@"1"] forName:@"StudyID"];
    [output setAttributeValues:[NSMutableArray arrayWithObject:@"0"] forName:@"SeriesNumber"];
    [self _ifAvailableCopyAttributeWithName:@"StudyDescription" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"PatientsName" from:source to:output alternatively:@""];
    [self _ifAvailableCopyAttributeWithName:@"PatientID" from:source to:output alternatively:@"0"];
    [self _ifAvailableCopyAttributeWithName:@"PatientsBirthDate" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"AccessionNumber" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"ReferringPhysiciansName" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"PatientsSex" from:source to:output alternatively:@""];
    [self _ifAvailableCopyAttributeWithName:@"PatientsBirthDate" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"StudyInstanceUID" from:source to:output];
    [self _ifAvailableCopyAttributeWithName:@"StudyDate" from:source to:output alternatively:[DCMCalendarDate dicomDateWithDate:[NSDate date]]];
    [self _ifAvailableCopyAttributeWithName:@"StudyTime" from:source to:output alternatively:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]];
    
    [output setAttributeValues:[NSMutableArray arrayWithObject: [DCMCalendarDate dicomDateWithDate:[NSDate date]]] forName:@"SeriesDate"];
    [output setAttributeValues:[NSMutableArray arrayWithObject: [DCMCalendarDate dicomTimeWithDate:[NSDate date]]] forName:@"SeriesTime"];
    
    [output writeToFile:outDicomPath withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
}

-(void)transformPdfAtPath:(NSString*)pdfPath toDicomAtPath:(NSString*)outDicomPath
{
    NSString* sourcePath = nil;
    for (DicomSeries* series in self.series.allObjects) {
        for (DicomImage* image in series.sortedImages) {
            if ([NSFileManager.defaultManager fileExistsAtPath:image.completePath])
                sourcePath = image.completePath;
            if (sourcePath)
                break;
        }
        if (sourcePath)
            break;
    }
    
    [[self class] transformPdfAtPath:pdfPath toDicomAtPath:outDicomPath usingSourceDicomAtPath:sourcePath];
}

-(void)saveReportAsDicomAtPath:(NSString*)path
{
    NSString* pdfPath = [self saveReportAsPdfInTmp];
    [self transformPdfAtPath:pdfPath toDicomAtPath:path];
    [NSFileManager.defaultManager removeItemAtPath:pdfPath error:NULL];
}

-(NSString*)saveReportAsDicomInTmp
{
    NSString* path = [NSFileManager.defaultManager tmpFilePathInTmp];
    [self saveReportAsDicomAtPath:path];
    return path;
}

@end
