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

#import "ViewerController+CPP.h"
#import "AppController.h"
#import "DicomDatabase.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "NSThread+N2.h"
#include "dcfilefo.h"
#include "dcdeftag.h"

@implementation ViewerController (CPP)

- (IBAction)captureAndSetKeyImage:(id)sender
{
    [[AppController sharedAppController] playGrabSound];
    
    DicomStudy* study = [self currentStudy];
    
    // export the reconstruction as a new DICOM file
    NSDictionary* result = [self exportDICOMFileInt:1 withName:O2ScreenCapturesSeriesName allViewers:NO];
    NSString* path = [result objectForKey:@"file"];
    
    // if a "OsiriX KOS Plugin Reconstructions" series already existed, put it in that series
    DicomSeries* series = nil;
    for (DicomSeries* iseries in study.series)
        if ([iseries.name isEqualToString:O2ScreenCapturesSeriesName])
            series = iseries;
    if (series) {
        DcmFileFormat dfile;
        if (dfile.loadFile(path.fileSystemRepresentation).good()) {
            dfile.loadAllDataIntoMemory();
            DcmDataset* dset = dfile.getDataset(); // = &dfile;
            
            // clone seriesinstanceUID and seriesNumber
            dset->putAndInsertString(DCM_SeriesInstanceUID, series.seriesDICOMUID.UTF8String);
            dset->putAndInsertString(DCM_SeriesNumber, series.id.stringValue.UTF8String);
            
            // find highest instanceNumber in the series
            NSInteger instanceNumber = 0;
            for (DicomImage* image in series.images)
                if (image.instanceNumber.integerValue > instanceNumber)
                    instanceNumber = image.instanceNumber.integerValue;
            ++instanceNumber;
            
            NSNumber* instanceNumberString = [NSNumber numberWithInteger:instanceNumber];
            dset->putAndInsertString(DCM_InstanceNumber, instanceNumberString.stringValue.UTF8String);
            dset->putAndInsertString(DCM_AcquisitionNumber, instanceNumberString.stringValue.UTF8String);
            
            dfile.saveFile(path.fileSystemRepresentation);
        }
    }
    
    // import the file into our DB
    DicomDatabase* database = [DicomDatabase databaseForContext:study.managedObjectContext];
    NSArray* imageIDs = [database addFilesAtPaths:[NSArray arrayWithObject:path]
                                postNotifications:YES
                                        dicomOnly:YES
                              rereadExistingItems:YES
                                generatedByOsiriX:YES];
    
    // upload the new file to the DICOM node
    /*if (NO)
        [NSThread performBlockInBackground: ^{
            NSString* myAET = [NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"];
            NSString* tAET = [NSUserDefaults.standardUserDefaults stringForKey:KOSAETKey];
            NSString* tHost = [NSUserDefaults.standardUserDefaults stringForKey:KOSNodeHostKey];
            NSInteger tPort = [NSUserDefaults.standardUserDefaults integerForKey:KOSNodePortKey];
            
            NSThread* thread = [NSThread currentThread];
            thread.name = [NSString stringWithFormat:NSLocalizedString(@"KeyObjects for %@", nil), study.name];
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Saving reconstruction to %@...", nil), tAET];
            [ThreadsManager.defaultManager addThreadAndStart:thread];
            
            DCMTKStoreSCU* storescu = [[[DCMTKStoreSCU alloc] initWithCallingAET:myAET
                                                                       calledAET:tAET
                                                                        hostname:tHost
                                                                            port:tPort
                                                                     filesToSend:[NSArray arrayWithObject:path]
                                                                  transferSyntax:0
                                                                     compression:1.0
                                                                 extraParameters:nil] autorelease];
            [storescu run: nil];
        }];*/
    
    // set the new images as key images
    for (DicomImage* imageID in imageIDs)
        [[database objectWithID:imageID] setIsKeyImage:[NSNumber numberWithBool:YES]];
}

@end
