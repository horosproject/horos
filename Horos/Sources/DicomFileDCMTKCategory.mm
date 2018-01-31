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

#import "DicomFileDCMTKCategory.h"
#import "DCMAbstractSyntaxUID.h"
#import "DICOMToNSString.h"
#import "MutableArrayCategory.h"
#import "DicomStudy.h"
#import "SRAnnotation.h"
#import "N2Debug.h"

#include "osconfig.h"
#include "dcfilefo.h"
#include "dcdeftag.h"
#include "ofstd.h"

#include "dctk.h"
#include "dcdebug.h"
#include "cmdlnarg.h"
#include "ofconapp.h"
#include "dcuid.h"       /* for dcmtk version name */
#include "djdecode.h"    /* for dcmjpeg decoders */
#include "dipijpeg.h"    /* for dcmimage JPEG plugin */

#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
#include <NrrdIO.h> // part of ITK
#endif
#endif

#include <string>

extern NSRecursiveLock *PapyrusLock;

@implementation DicomFile (DicomFileDCMTKCategory)

+ (NSArray*) getEncodingArrayForFile: (NSString*) file
{
    DcmFileFormat fileformat;
    NSArray *encodingArray = nil;
    
    OFCondition status = fileformat.loadFile( [file UTF8String], EXS_Unknown, EGL_noChange, DCM_MaxReadLength, ERM_autoDetect);
    
    DcmDataset *dataset = fileformat.getDataset();
    
    const char *string = NULL;
    
    if( dataset && dataset->findAndGetString(DCM_SpecificCharacterSet, string, OFFalse).good() && string != NULL)
    {
        encodingArray = [[NSString stringWithCString:string encoding: NSISOLatin1StringEncoding] componentsSeparatedByString:@"\\"];
    }
    
    if( encodingArray == nil)
        encodingArray = [NSArray arrayWithObject: @"ISO_IR 100"];
    
    return encodingArray;
}

+ (BOOL) isDICOMFileDCMTK:(NSString *) file{
    DcmFileFormat fileformat;
    OFCondition status = fileformat.loadFile([file UTF8String]);
    if (status.good())
        return YES;
    return NO;
}

+ (BOOL) isNRRDFile:(NSString *) file
{
    int success = NO;
    NSString	*extension = [[file pathExtension] lowercaseString];
    
    if( [extension isEqualToString:@"nrrd"])
    {
        success = YES;
    }
    return success;
}

+ (NSString*) getDicomFieldForGroup:(int) gr element: (int) el forDcmFileFormat: (void*) ff
{
    NSString *returnedValue = nil;
    DcmFileFormat *fileformat = (DcmFileFormat*) ff;
    
    if( fileformat)
    {
        @try
        {
            OFString string;
            DcmDataset *dataset = fileformat->getDataset();
            
            DcmTagKey dcmkey( gr, el);
            
            if( dataset && dataset->findAndGetOFString( dcmkey, string, OFFalse).good() && string.length() > 0)
                returnedValue = [NSString stringWithCString:string.c_str() encoding: NSISOLatin1StringEncoding];
            
            if( returnedValue == nil)
            {
                //Maybe in the metadata?
                DcmMetaInfo *metaset = fileformat->getMetaInfo();
                
                if( metaset && metaset->findAndGetOFString( dcmkey, string, OFFalse).good() && string.length() > 0)
                    returnedValue = [NSString stringWithCString:string.c_str() encoding: NSISOLatin1StringEncoding];
            }
            
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
    }
    
    return returnedValue;
}

+ (NSString*) getDicomField: (NSString*) field forFile: (NSString*) path
{
    if( field.length <= 0)
        return nil;
    
    DcmTagKey dcmkey(0xffff,0xffff);
    const DcmDataDictionary& globalDataDict = dcmDataDict.rdlock();
    const DcmDictEntry *dicent = globalDataDict.findEntry( [field UTF8String]);
    
    //successfull lookup in dictionary -> translate to tag and return
    if (dicent)
        dcmkey = dicent->getKey();
    dcmDataDict.unlock();
    
    if( dcmkey.getGroup() != 0xffff && dcmkey.getElement() != 0xffff)
    {
        [PapyrusLock lock];
        
        DcmFileFormat fileformat;
        
        OFCondition status = fileformat.loadFile( [path UTF8String],  EXS_Unknown, EGL_noChange, DCM_MaxReadLength, ERM_autoDetect);
        
        [PapyrusLock unlock];
        
        if (status.good())
            return [DicomFile getDicomFieldForGroup: dcmkey.getGroup()  element:dcmkey.getElement() forDcmFileFormat: &fileformat];
    }
    
    return nil;
}

-(short) getNRRDFile
{
#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
    int			success = 0;
    NSString	*extension = [[filePath pathExtension] lowercaseString];
    char		*err = nil;
    
    if( [extension isEqualToString:@"nrrd"])
    {
        Nrrd *nin;
        
        /* create a nrrd; at this point this is just an empty container */
        nin = nrrdNew();
        
        /* read in the nrrd from file */
        if (nrrdLoad(nin, [filePath UTF8String], NULL))
        {
            err = biffGetDone(NRRD);
            fprintf(stderr, "trouble reading \"%s\":\n%s", [filePath UTF8String], err);
            free(err);
            return success;
        }
        
        printf("\"%s\" is a %d-dimensional nrrd of type %d (%s)\n",
               [filePath UTF8String], nin->dim, nin->type,
               airEnumStr(nrrdType, nin->type));
        
        printf("the array contains %d elements, each %d bytes in size\n",
               (int)nrrdElementNumber(nin), (int)nrrdElementSize(nin));
        
        if( nin->dim > 1)
        {
            height = 512;
            width = 512;
            
            NoOfSeries = 1;
            
            imageID = [[NSString alloc] initWithString: [[NSDate date] description]];
            self.serieID = [[NSDate date] description];
            
            unsigned int random = (unsigned int)time(NULL);
            studyID = [[NSString alloc] initWithFormat:@"%d", random];
            
            name = [[NSString alloc] initWithString:[filePath lastPathComponent]];
            patientID = [[NSString alloc] initWithString:name];
            study = [[NSString alloc] initWithString:[filePath lastPathComponent]];
            Modality = [[NSString alloc] initWithString:@"RD"];
            date = [[NSCalendarDate date] retain];
            serie = [[NSString alloc] initWithString:[filePath lastPathComponent]];
            fileType = [@"IMAGE" retain];
            
            
            NoOfFrames = 1;
            
            [dicomElements setObject:studyID forKey:@"studyID"];
            [dicomElements setObject:study forKey:@"studyDescription"];
            [dicomElements setObject:date forKey:@"studyDate"];
            [dicomElements setObject:Modality forKey:@"modality"];
            [dicomElements setObject:patientID forKey:@"patientID"];
            [dicomElements setObject:name forKey:@"patientName"];
            [dicomElements setObject:[self patientUID] forKey:@"patientUID"];
            [dicomElements setObject:self.serieID forKey:@"seriesID"];
            [dicomElements setObject:name forKey:@"seriesDescription"];
            [dicomElements setObject:[NSNumber numberWithInt: 0] forKey:@"seriesNumber"];
            [dicomElements setObject:imageID forKey:@"SOPUID"];
            [dicomElements setObject:[NSNumber numberWithInt:[imageID intValue]] forKey:@"imageID"];
            [dicomElements setObject:fileType forKey:@"fileType"];
        }
        
        nrrdNuke(nin);
        
        // ********** Now, test the IO of ITK
        
        //		typedef itk::Image<char,4> TestImageType; // pixel type doesn't matter for current purpose
        //		typedef itk::ImageFileReader<TestImageType> TestFileReaderType; // reader for testing a file
        //		TestFileReaderType::Pointer onefileReader = TestFileReaderType::New();
        //
        //		onefileReader->SetFileName([filePath UTF8String]);
        //
        //		try
        //		{
        //			onefileReader->GenerateOutputInformation();
        //		}
        //		catch(itk::ExceptionObject &excp)
        //		{
        //			return -1;
        //		}
        //
        //		// grab the ImageIO instance for the reader
        //		itk::ImageIOBase *imageIO = onefileReader->GetImageIO();
        //		unsigned int NumberOfDimensions =  imageIO->GetNumberOfDimensions();
        //		//std::endl;
        //		unsigned dims[32];   // almost always no more than 4 dims, but ...
        //		unsigned origin[32];
        //		double spacing[32];
        //		std::vector<double> directions[32];
        //		for(unsigned i = 0; i < NumberOfDimensions && i < 32; i++)
        //		 {
        //		 dims[i] = imageIO->GetDimensions(i);
        //		 origin[i] = imageIO->GetOrigin(i);
        //		 spacing[i] = imageIO->GetSpacing(i);
        //		 directions[i] = imageIO->GetDirection(i);
        //		 }
        ////		// PixelType is SCALAR, RGB, RGBA, VECTOR, COVARIANTVECTOR, POINT,INDEX
        ////		itk::ImageIOBase::PixelType pixelType = imageIO->GetPixelType();
        ////		// IOComponentType is UCHAR, CHAR, USHORT, SHORT, UINT, INT, ULONG,LONG, FLOAT, DOUBLE
        ////		itk::ImageIOBase::IOComponentType componentType = imageIO->GetIOComponentType();
        ////		const std::type_info &typeinfo typeInfo = imageIO->GetComponentTypeInfo();
        ////		// NumberOfComponents is usually one, but for non-scalar pixel types, it can be anything
        //		unsigned int NumberOfComponents = imageIO->GetNumberOfComponents();
    }
    
    if (success)
        return 0;
    else
#endif
#endif
        return -1;
}

-(short) getDicomFileDCMTK
{
    int i;
    long cardiacTime = -1;
    
    NSStringEncoding encoding[ 10];
    NSString *echoTime = nil;
    const char *string = NULL;
    NSMutableArray *imageTypeArray = nil;
    
    DcmFileFormat fileformat;
    [PapyrusLock lock];
    
    OFCondition status = fileformat.loadFile([filePath UTF8String],  EXS_Unknown, EGL_noChange, DCM_MaxReadLength, ERM_autoDetect);
    
    [PapyrusLock unlock];
    
    if (status.good())
    {
        for( i = 0; i < 10; i++) encoding[ i] = 0;
        encoding[ 0] = NSISOLatin1StringEncoding;
        
        DcmDataset *dataset = fileformat.getDataset();
        
        //TransferSyntax
        if (fileformat.getMetaInfo()->findAndGetString(DCM_TransferSyntaxUID, string, OFFalse).good() && string != NULL
            && [[NSString stringWithCString:string encoding: NSASCIIStringEncoding] isEqualToString:@"1.2.840.10008.1.2.4.100"])
        {
            fileType = [@"DICOMMPEG2" retain];
            [dicomElements setObject:fileType forKey:@"fileType"];
        }
        else
        {
            fileType = [@"DICOM" retain];
            [dicomElements setObject:fileType forKey:@"fileType"];
        }
        
        // PrivateInformationCreatorUID
        if (fileformat.getMetaInfo()->findAndGetString(DCM_PrivateInformationCreatorUID, string, OFFalse).good() && string != NULL) {
            [dicomElements setObject:[NSString stringWithCString:string encoding:NSISOLatin1StringEncoding] forKey:@"PrivateInformationCreatorUID"];
        }
        
        //Character Set
        if (dataset->findAndGetString(DCM_SpecificCharacterSet, string, OFFalse).good() && string != NULL)
        {
            NSArray	*c = [[NSString stringWithCString:string encoding: NSISOLatin1StringEncoding] componentsSeparatedByString:@"\\"];
            
            if( [c count] >= 10) NSLog( @"Encoding number >= 10 ???");
            
            if( [c count] < 10)
            {
                for( i = 0; i < [c count]; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c objectAtIndex: i]];
                for( i = (int)[c count]; i < 10; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c lastObject]];
            }
        }
        
        if ([self autoFillComments]  == YES) // ||[self checkForLAVIM] == YES)
        {
            if( [self autoFillComments])
            {
                NSString *commentsField = nil;
                DcmItem *dicomItems = nil;
                
                if( [self commentsGroup] && [self commentsElement])
                {
                    DcmTagKey key = DcmTagKey([self commentsGroup], [self commentsElement]);
                    
                    if( [self commentsGroup] == 2) // MetaHeader
                        dicomItems = fileformat.getMetaInfo();
                    else
                        dicomItems = dataset;
                    
                    if( dicomItems->findAndGetString(key, string, OFFalse).good() && string != NULL)
                        commentsField = [DicomFile stringWithBytes: (char*) string encodings:encoding];
                }
                
                if( [self commentsGroup2] && [self commentsElement2])
                {
                    DcmTagKey key = DcmTagKey([self commentsGroup2], [self commentsElement2]);
                    
                    if( [self commentsGroup2] == 2) // MetaHeader
                        dicomItems = fileformat.getMetaInfo();
                    else
                        dicomItems = dataset;
                    
                    if( dicomItems->findAndGetString(key, string, OFFalse).good() && string != NULL)
                    {
                        if( commentsField)
                            commentsField = [commentsField stringByAppendingFormat: @" / %@", [DicomFile stringWithBytes: (char*) string encodings:encoding]];
                        else
                            commentsField = [DicomFile stringWithBytes: (char*) string encodings:encoding];
                        [dicomElements setObject:commentsField forKey:@"commentsAutoFill"];
                    }
                }
                
                if( [self commentsGroup3] && [self commentsElement3])
                {
                    DcmTagKey key = DcmTagKey([self commentsGroup3], [self commentsElement3]);
                    
                    if( [self commentsGroup3] == 2) // MetaHeader
                        dicomItems = fileformat.getMetaInfo();
                    else
                        dicomItems = dataset;
                    
                    if( dicomItems->findAndGetString(key, string, OFFalse).good() && string != NULL)
                    {
                        if( commentsField)
                            commentsField = [commentsField stringByAppendingFormat: @" / %@", [DicomFile stringWithBytes: (char*) string encodings:encoding]];
                        else
                            commentsField = [DicomFile stringWithBytes: (char*) string encodings:encoding];
                        [dicomElements setObject:commentsField forKey:@"commentsAutoFill"];
                    }
                }
                
                if( [self commentsGroup4] && [self commentsElement4])
                {
                    DcmTagKey key = DcmTagKey([self commentsGroup4], [self commentsElement4]);
                    
                    if( [self commentsGroup4] == 2) // MetaHeader
                        dicomItems = fileformat.getMetaInfo();
                    else
                        dicomItems = dataset;
                    
                    if( dicomItems->findAndGetString(key, string, OFFalse).good() && string != NULL)
                    {
                        if( commentsField)
                            commentsField = [commentsField stringByAppendingFormat: @" / %@", [DicomFile stringWithBytes: (char*) string encodings:encoding]];
                        else
                            commentsField = [DicomFile stringWithBytes: (char*) string encodings:encoding];
                        [dicomElements setObject:commentsField forKey:@"commentsAutoFill"];
                    }
                }
                
                if( commentsField)
                    [dicomElements setObject:commentsField forKey:@"commentsAutoFill"];
            }
            
            //			if([self checkForLAVIM] == YES)
            //			{
            //				NSString	*album = nil;
            //				if (dataset->findAndGetString(DCM_ImageComments, string, OFFalse).good() && string != NULL)
            //				{
            //					album = [NSString stringWithUTF8String:string encoding: NSISOLatin1StringEncoding];
            //					if( [album length] >= 2)
            //					{
            //						if( [[album substringToIndex:2] isEqualToString: @"LV"])
            //						{
            //							album = [album substringFromIndex:2];
            //							[dicomElements setObject:album forKey:@"album"];
            //						}
            //					}
            //				}
            //
            //				DcmTagKey albumKey = DcmTagKey(0x0040, 0x0280);
            //				if (dataset->findAndGetString(albumKey, string, OFFalse).good() && string != NULL)
            //				{
            //					album = [NSString stringWithUTF8String:string encoding: NSISOLatin1StringEncoding];
            //					if( [album length] >= 2)
            //					{
            //						if( [[album substringToIndex:2] isEqualToString: @"LV"])
            //						{
            //							album = [album substringFromIndex:2];
            //							[dicomElements setObject:album forKey:@"album"];
            //						}
            //					}
            //				}
            //
            //				 albumKey = DcmTagKey(0x0040, 0x1400);
            //				 if (dataset->findAndGetString(albumKey, string, OFFalse).good() && string != NULL)
            //				 {
            //					album = [NSString stringWithUTF8String:string encoding: NSISOLatin1StringEncoding];
            //					if( [album length] >= 2)
            //					{
            //						if( [[album substringToIndex:2] isEqualToString: @"LV"])
            //						{
            //							album = [album substringFromIndex:2];
            //							[dicomElements setObject:album forKey:@"album"];
            //						}
            //					}
            //				}
            //			}  //ckeck LAVIN
            
        } //check autofill and album
        
        //SOPClass
        NSString *sopClassUID = nil;
        if (dataset->findAndGetString(DCM_SOPClassUID, string, OFFalse).good() && string != NULL)
        {
            [dicomElements setObject:[NSString stringWithCString:string encoding: NSASCIIStringEncoding] forKey:@"SOPClassUID"];
            sopClassUID = [NSString stringWithCString: string encoding: NSASCIIStringEncoding] ;
        }
        
        //Image Type
        if (dataset->findAndGetString(DCM_ImageType, string, OFFalse).good() && string != NULL)
        {
            imageTypeArray = [NSMutableArray arrayWithArray: [[NSString stringWithCString:string encoding: NSISOLatin1StringEncoding] componentsSeparatedByString:@"\\"]];
            
            if( [imageTypeArray count] > 2)
            {
                imageType = [[imageTypeArray objectAtIndex: 2] retain];
                [dicomElements setObject:imageType forKey:@"imageType"];
            }
        }
        else
            imageType = nil;
        
        if( imageType) [dicomElements setObject:imageType forKey:@"imageType"];
        
        //SOPInstanceUID
        if (dataset->findAndGetString(DCM_SOPInstanceUID, string, OFFalse).good() && string != NULL)
        {
            SOPUID = [[NSString stringWithCString:string encoding: NSISOLatin1StringEncoding] retain];
        }
        else
            SOPUID = nil;
        if (SOPUID) [dicomElements setObject:SOPUID forKey:@"SOPUID"];
        
        //Study Description
        if (dataset->findAndGetString(DCM_StudyDescription, string, OFFalse).good() && string != NULL)
            study = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
        else
        {
            DcmItem *item = NULL;
            if (dataset->findAndGetSequenceItem(DCM_ProcedureCodeSequence, item).good())
            {
                if( item->findAndGetString(DCM_CodeMeaning, string, OFFalse).good() && string != NULL)
                    study = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
            }
        }
        if( !study)
            study = [[NSString alloc] initWithString: @"unnamed"];
        [dicomElements setObject:study forKey: @"studyDescription"];
        
        //Modality
        if (dataset->findAndGetString(DCM_Modality, string, OFFalse).good() && string != NULL)
        {
            Modality = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
        }
        else
            Modality = [[NSString alloc] initWithString:@"OT"];
        [dicomElements setObject:Modality forKey:@"modality"];
        
        
        //Acquistion Date
        NSString *studyDate = nil;
        if (dataset->findAndGetString(DCM_AcquisitionDate, string, OFFalse).good() && string != NULL && strlen( string) > 0)
            studyDate = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        else if (dataset->findAndGetString(DCM_ContentDate, string, OFFalse).good() && string != NULL && strlen( string) > 0)
            studyDate = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        else if (dataset->findAndGetString(DCM_SeriesDate, string, OFFalse).good() && string != NULL && strlen( string) > 0)
            studyDate = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        else if (dataset->findAndGetString(DCM_StudyDate, string, OFFalse).good() && string != NULL && strlen( string) > 0)
            studyDate = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        if( [studyDate length] != 8) studyDate = [studyDate stringByReplacingOccurrencesOfString:@"." withString:@""];
        
        NSString* studyTime = nil;
        if (dataset->findAndGetString(DCM_AcquisitionTime, string, OFFalse).good() && string != NULL && strlen( string) > 0 && atof( string) > 0)
            studyTime = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        else if (dataset->findAndGetString(DCM_ContentTime, string, OFFalse).good() && string != NULL && strlen( string) > 0 && atof( string) > 0)
            studyTime = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        else if (dataset->findAndGetString(DCM_SeriesTime, string, OFFalse).good() && string != NULL && strlen( string) > 0 && atof( string) > 0)
            studyTime = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        else if (dataset->findAndGetString(DCM_StudyTime, string, OFFalse).good() && string != NULL && strlen( string) > 0 && atof( string) > 0)
            studyTime = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
        
        studyTime = [studyTime stringByReplacingOccurrencesOfString:@":" withString:@""];
        
        if( studyDate && studyTime)
        {
            NSString *completeDate = [studyDate stringByAppendingString:studyTime];
            
            if( [studyTime length] >= 6)
                date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
            else
                date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M"];
        }
        else if( studyDate)
        {
            studyDate = [studyDate stringByAppendingString: @"120000"];
            date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat: @"%Y%m%d%H%M%S"];
        }
        else
            date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil] retain];
        
        if( date)
            [dicomElements setObject:date forKey:@"studyDate"];
        
        //Series Description
        if (dataset->findAndGetString(DCM_SeriesDescription, string, OFFalse).good() && string != NULL)
            serie = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
        else if (dataset->findAndGetString(DCM_PerformedProcedureStepDescription, string, OFFalse).good() && string != NULL)
            serie = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
        else if (dataset->findAndGetString(DCM_AcquisitionDeviceProcessingDescription, string, OFFalse).good() && string != NULL)
            serie = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
        else if( serie == nil)
            serie = [[NSString alloc] initWithString: @"unnamed"];
        
        [dicomElements setObject:serie forKey:@"seriesDescription"];
        
        //Institution Name
        if (dataset->findAndGetString(DCM_InstitutionName,  string, OFFalse).good() && string != NULL)
        {
            NSString *institution = [DicomFile stringWithBytes: (char*) string encodings:encoding];
            [dicomElements setObject:institution forKey:@"institutionName"];
        }
        
        //Referring Physician
        if (dataset->findAndGetString(DCM_ReferringPhysiciansName,  string, OFFalse).good() && string != NULL)
        {
            NSString *referringPhysiciansName = [DicomFile stringWithBytes: (char*) string encodings:encoding];
            [dicomElements setObject:referringPhysiciansName forKey:@"referringPhysiciansName"];
        }
        
        //Performing Physician
        if (dataset->findAndGetString(DCM_PerformingPhysiciansName,  string, OFFalse).good() && string != NULL)
        {
            NSString *performingPhysiciansName = [DicomFile stringWithBytes: (char*) string encodings:encoding];
            [dicomElements setObject:performingPhysiciansName forKey:@"performingPhysiciansName"];
        }
        
        //Accession Number
        if (dataset->findAndGetString(DCM_AccessionNumber,  string, OFFalse).good() && string != NULL)
        {
            NSString *accessionNumber = [DicomFile stringWithBytes: (char*) string encodings:encoding replaceBadCharacters: NO];
            [dicomElements setObject:accessionNumber forKey:@"accessionNumber"];
        }
        
        //Patients Name
        if (dataset->findAndGetString(DCM_PatientsName, string, OFFalse).good() && string != NULL)
        {
            name = [[DicomFile stringWithBytes: (char*) string encodings:encoding replaceBadCharacters:NO] retain];
            if(name == nil) name = [[NSString alloc] initWithCString: string encoding: encoding[ 0]];
        }
        else
            name = [[NSString alloc] initWithString: @"No name"];
        
        [dicomElements setObject:name forKey:@"patientName"];
        
        //Patient ID
        if (dataset->findAndGetString(DCM_PatientID, string, OFFalse).good() && string != NULL)
        {
            patientID  = [[DicomFile stringWithBytes: (char*) string encodings:encoding replaceBadCharacters: NO] retain];
            [dicomElements setObject:patientID forKey: @"patientID"];
        }
        
        //Patients Age
        if (dataset->findAndGetString(DCM_PatientsAge, string, OFFalse).good() && string != NULL)
        {
            NSString *patientAge  = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
            [dicomElements setObject:patientAge forKey:@"patientAge"];
            [patientAge  release];
        }
        
        //Patients BD
        if (dataset->findAndGetString(DCM_PatientsBirthDate, string, OFFalse).good() && string != NULL)
        {
            NSString		*patientDOB =  [[[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding] autorelease];
            NSCalendarDate	*DOB = [NSCalendarDate dateWithString: patientDOB calendarFormat:@"%Y%m%d"];
            if( DOB) [dicomElements setObject:DOB forKey:@"patientBirthDate"];
        }
        
        //Patients Sex
        if (dataset->findAndGetString(DCM_PatientsSex, string, OFFalse).good() && string != NULL)
        {
            NSString *patientSex  = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
            [dicomElements setObject:patientSex forKey:@"patientSex"];
            [patientSex  release];
        }
        
        
        //Cardiac Time
        if (dataset->findAndGetString(DCM_ScanOptions, string, OFFalse).good() && string != NULL){
            if( strlen( string) >= 4)
            {
                if( string[ 0] == 'T' && string[ 1] == 'P')
                {
                    if( string[ 2] >= '0' && string[ 2] <= '9')
                    {
                        if( string[ 3] >= '0' && string[ 3] <= '9')
                        {
                            cardiacTime = (string[ 2] - '0')*10;
                            cardiacTime += string[ 3] - '0';
                        }
                        else
                        {
                            cardiacTime = string[ 2] - '0';
                        }
                    }
                }
            }
            [dicomElements setObject:[NSNumber numberWithLong: cardiacTime] forKey:@"cardiacTime"];
        }
        
        //Protocol Name
        if (dataset->findAndGetString(DCM_ProtocolName, string, OFFalse).good() && string != NULL)
        {
            NSString *protocol = [DicomFile stringWithBytes: (char*) string encodings: encoding];
            if( protocol == nil) protocol = [[[NSString alloc] initWithCString: string encoding: encoding[ 0]]  autorelease];
            [dicomElements setObject:protocol  forKey:@"protocolName"];
        }
        
        //		//manufacturer
        //		if (dataset->findAndGetString(DCM_Manufacturer, string, OFFalse).good() && string != NULL)
        //		{
        //			NSString *manufacturer = [DicomFile stringWithBytes: (char*) string encodings: encoding];
        //			if( manufacturer == nil) manufacturer = [[[NSString alloc] initWithCString: string encoding: encoding[ 0]] autorelease];
        //
        //			if( [manufacturer hasPrefix: @"MAC:"])
        //				[dicomElements setObject: manufacturer forKey: @"manufacturer"];
        //		}
        
        //Echo Time
        if (dataset->findAndGetString(DCM_EchoTime, string, OFFalse).good() && string != NULL)
        {
            echoTime = [[[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding] autorelease];
        }
        
        //Image Number
        if (dataset->findAndGetString(DCM_InstanceNumber, string, OFFalse).good() && string != NULL)
        {
            int val = [[NSString stringWithCString:string encoding: NSASCIIStringEncoding] intValue];
            imageID = [[NSString alloc] initWithFormat:@"%5d", val];
        }
        else imageID = nil;
        
        // Compute slice location
        
        Float64		orientation[9];
        Float64		origin[ 3];
        Float64		location = 0;
        int count = 0;
        
        origin[0] = origin[1] = origin[2] = 0;
        
        while (count < 3 && dataset->findAndGetFloat64(DCM_ImagePositionPatient, origin[count], count, OFFalse).good())
            count++;
        
        orientation[ 0] = 1;	orientation[ 1] = 0;		orientation[ 2] = 0;
        orientation[ 3] = 0;	orientation[ 4] = 1;		orientation[ 5] = 0;
        
        count = 0;
        while (count < 6 && dataset->findAndGetFloat64(DCM_ImageOrientationPatient, orientation[count], count, OFFalse).good())
            count++;
        
        // Compute normal vector
        orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
        orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
        orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
        
        if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8])) location = origin[ 0];
        if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8])) location = origin[ 1];
        if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7])) location = origin[ 2];
        
        [dicomElements setObject:[NSNumber numberWithDouble: (double)location] forKey:@"sliceLocation"];
        
        if( imageID == nil || [imageID intValue] >= 99999)
        {
            int val = 10000 + location*10.;
            [imageID release];
            imageID = [[NSString alloc] initWithFormat:@"%5d", val];
        }
        [dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];
        
        //Series Number
        if (dataset->findAndGetString(DCM_SeriesNumber, string, OFFalse).good() && string != NULL)
        {
            seriesNo = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
        }
        else
            seriesNo = [[NSString alloc] initWithString: @"0"];
        if( seriesNo) [dicomElements setObject:[NSNumber numberWithInt:[seriesNo intValue]]  forKey:@"seriesNumber"];
        
        //Series Instance UID
        if (dataset->findAndGetString(DCM_SeriesInstanceUID, string, OFFalse).good() && string != NULL)
        {
            self.serieID = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
            [dicomElements setObject:self.serieID forKey:@"seriesDICOMUID"];
        }
        else
            self.serieID = name;
        
        //Series ID
        
        if( cardiacTime != -1 && [self separateCardiac4D] == YES && [Modality isEqualToString: @"SC"] == NO)  // For new Cardiac-CT Siemens series
            self.serieID = [NSString stringWithFormat:@"%@ %2.2d", self.serieID , (int) cardiacTime];
        
        if( seriesNo)
            self.serieID = [NSString stringWithFormat:@"%8.8d %@", [seriesNo intValue] , self.serieID];
        
        if( imageType != 0 && [self useSeriesDescription])
            self.serieID = [NSString stringWithFormat:@"%@ %@", self.serieID , imageType];
        
        if( serie != nil && [self useSeriesDescription])
            self.serieID = [NSString stringWithFormat:@"%@ %@", self.serieID , serie];
        
        if( sopClassUID != nil && [[DCMAbstractSyntaxUID hiddenImageSyntaxes] containsObject: sopClassUID])
            self.serieID = [NSString stringWithFormat:@"%@ %@", self.serieID , sopClassUID];
        
        //Segregate by TE  values
        if( echoTime != nil && [self splitMultiEchoMR])
            self.serieID = [NSString stringWithFormat:@"%@ TE-%@", self.serieID , echoTime];
        
        //Study Instance UID
        if (dataset->findAndGetString(DCM_StudyInstanceUID, string, OFFalse).good() && string != NULL)
            studyID = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
        else
            studyID = [[NSString alloc] initWithString:name];
        
        [dicomElements setObject:studyID forKey:@"studyID"];
        
        //StudyID
        if (dataset->findAndGetString(DCM_StudyID, string, OFFalse).good() && string != NULL)
            studyIDs = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
        else
            studyIDs = [[NSString alloc] initWithString:@"0"];
        
        if( studyIDs)
            [dicomElements setObject:studyIDs forKey:@"studyNumber"];
        
        if( [self commentsFromDICOMFiles])
        {
            if (dataset->findAndGetString( DCM_StudyComments, string, OFFalse).good() && string != NULL)
                [dicomElements setObject: [NSString stringWithCString:string encoding: NSASCIIStringEncoding] forKey:@"studyComments"];
            
            if (dataset->findAndGetString( DCM_ImageComments, string, OFFalse).good() && string != NULL)
                [dicomElements setObject: [NSString stringWithCString:string encoding: NSASCIIStringEncoding] forKey:@"seriesComments"];
            
            if (dataset->findAndGetString( DCM_InterpretationStatusID, string, OFFalse).good() && string != NULL)
                [dicomElements setObject: [NSNumber numberWithInt: [[NSString stringWithCString:string encoding: NSASCIIStringEncoding] intValue]] forKey:@"stateText"];
        }
        
        //Rows
        unsigned short rows = 0;
        if (dataset->findAndGetUint16(DCM_Rows, rows, OFFalse).good())
            height = rows;
        
        //Columns
        unsigned short columns = 0;
        if (dataset->findAndGetUint16(DCM_Columns, columns, OFFalse).good())
            width = columns;
        
        //Number of Frames
        if (dataset->findAndGetString(DCM_NumberOfFrames, string, OFFalse).good() && string != NULL)
            NoOfFrames = atoi(string);
        
        // Is it a multi frame DICOM files? We need to parse these sequences for the correct sliceLocation value !
        int i = 0;
        DcmItem *ditem = NULL;
        NSMutableArray *sliceLocationArray = [NSMutableArray array];
        NSMutableArray *imageCardiacTriggerArray = [NSMutableArray array];
        
        double originMultiFrame[ 3] = {0, 0, 0}, orientationMultiFrame[ 9] = {1, 0, 0, 0, 1, 0};
        
        // SHARED
        if (dataset->findAndGetSequenceItem(DCM_SharedFunctionalGroupsSequence, ditem, 0).good())
        {
            DcmItem *eitem = NULL;
            if (ditem->findAndGetSequenceItem(DCM_PlanePositionVolumeSequence, eitem, 0).good())
            {
                int count = 0;
                while (count < 6 && eitem->findAndGetFloat64(DCM_ImageOrientationVolume, orientationMultiFrame[count], count, OFFalse).good())
                    count++;
                
                if( count != 6 && count != 0)
                    NSLog( @"******* DCM_ImageOrientationVolume : count != 6 && count != 0");
            }
        }
        
        // PER FRAME
        do
        {
            if (dataset->findAndGetSequenceItem(DCM_PerFrameFunctionalGroupsSequence, ditem, i++).good())
            {
                int x = 0;
                DcmItem *eitem = NULL;
                do
                {
                    if (ditem->findAndGetSequenceItem(DCM_CardiacTriggerSequence, eitem, x).good())
                    {
                        Float64 triggerSequence = 0;
                        
                        if( eitem->findAndGetFloat64(DCM_TriggerDelayTime, triggerSequence, 0, OFFalse).good())
                            [imageCardiacTriggerArray addObject: [NSString stringWithFormat: @"%lf", triggerSequence]];
                    }
                    
                    BOOL succeed = YES;
                    
                    if (ditem->findAndGetSequenceItem(DCM_PlanePositionVolumeSequence, eitem, x).good())
                    {
                        int count = 0;
                        while (count < 3 && eitem->findAndGetFloat64(DCM_ImagePositionVolume, originMultiFrame[count], count, OFFalse).good())
                            count++;
                        
                        if( count != 3)
                            succeed = NO;
                    }
                    else
                        succeed = NO;
                    
                    if( succeed == NO)
                    {
                        succeed = YES;
                        
                        if (ditem->findAndGetSequenceItem(DCM_PlanePositionSequence, eitem, x).good())
                        {
                            int count = 0;
                            while (count < 3 && eitem->findAndGetFloat64(DCM_ImagePositionPatient, originMultiFrame[count], count, OFFalse).good())
                                count++;
                            
                            if( count != 3)
                                succeed = NO;
                        }
                        else succeed = NO;
                        
                        if (ditem->findAndGetSequenceItem(DCM_PlaneOrientationSequence, eitem, x).good())
                        {
                            int count = 0;
                            while (count < 6 && eitem->findAndGetFloat64(DCM_ImageOrientationPatient, orientationMultiFrame[count], count, OFFalse).good())
                                count++;
                            
                            if( count != 6 && count != 0)
                                succeed = NO;
                        }
                        else succeed = NO;
                    }
                    
                    if( succeed)
                    {
                        // Compute normal vector
                        orientationMultiFrame[ 6] = orientationMultiFrame[ 1]*orientationMultiFrame[ 5] - orientationMultiFrame[ 2]*orientationMultiFrame[ 4];
                        orientationMultiFrame[ 7] = orientationMultiFrame[ 2]*orientationMultiFrame[ 3] - orientationMultiFrame[ 0]*orientationMultiFrame[ 5];
                        orientationMultiFrame[ 8] = orientationMultiFrame[ 0]*orientationMultiFrame[ 4] - orientationMultiFrame[ 1]*orientationMultiFrame[ 3];
                        
                        float location = 0;
                        
                        if( fabs( orientationMultiFrame[ 6]) > fabs(orientationMultiFrame[ 7]) && fabs( orientationMultiFrame[ 6]) > fabs(orientationMultiFrame[ 8]))
                            location = originMultiFrame[ 0];
                        
                        if( fabs( orientationMultiFrame[ 7]) > fabs(orientationMultiFrame[ 6]) && fabs( orientationMultiFrame[ 7]) > fabs(orientationMultiFrame[ 8]))
                            location = originMultiFrame[ 1];
                        
                        if( fabs( orientationMultiFrame[ 8]) > fabs(orientationMultiFrame[ 6]) && fabs( orientationMultiFrame[ 8]) > fabs(orientationMultiFrame[ 7]))
                            location = originMultiFrame[ 2];
                        
                        [sliceLocationArray addObject: [NSNumber numberWithFloat: location]];
                    }
                    
                    x++;
                }
                while (eitem != NULL);
            }
        }
        while (ditem != NULL);
        
        if( sliceLocationArray.count)
        {
            if( NoOfFrames == sliceLocationArray.count)
                [dicomElements setObject: sliceLocationArray forKey:@"sliceLocationArray"];
            else
                NSLog( @"*** NoOfFrames != sliceLocationArray.count for MR/CT/US multiframe sliceLocation computation (%d, %d)", (int) NoOfFrames, (int) sliceLocationArray.count);
        }
        if( imageCardiacTriggerArray.count)
        {
            if( NoOfFrames == imageCardiacTriggerArray.count)
                [dicomElements setObject: imageCardiacTriggerArray forKey:@"imageCommentPerFrame"];
            else
                NSLog( @"*** NoOfFrames != imageCardiacTriggerArray.count for MR/CT multiframe image type frame computation (%d, %d)", (int) NoOfFrames, (int) imageCardiacTriggerArray.count);
            
        }
        
        // Is it PDF DICOM file?
        if( [sopClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
        {
            const Uint8 *buffer = nil;
            unsigned int length;
            if (dataset->findAndGetUint8Array(DCM_EncapsulatedDocument, buffer, &length, OFFalse).good() && length > 0)
            {
                NSData *pdfData = [NSData dataWithBytes:buffer length:(unsigned)length];;
                NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData:pdfData];
                
                NoOfFrames = [rep pageCount];
                
                NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
                [pdfImage addRepresentation: rep];
                
                NSBitmapImageRep *bitRep = [NSBitmapImageRep imageRepWithData: [pdfImage TIFFRepresentation]];
                
                if( bitRep.pixelsWide > pdfImage.size.width)
                {
                    height = bitRep.pixelsHigh;
                    width = bitRep.pixelsWide;
                }
                else
                {
                    height = pdfImage.size.height;
                    width = pdfImage.size.width;
                }
            }
        }
        
#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
        if( [sopClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"])
        {
            if( [DicomStudy displaySeriesWithSOPClassUID: sopClassUID andSeriesDescription: [dicomElements objectForKey: @"seriesDescription"]])
            {
                NSPDFImageRep *rep = [self PDFImageRep];
                
                NoOfFrames = [rep pageCount];
                
                NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
                [pdfImage addRepresentation: rep];
                
                NSBitmapImageRep *bitRep = [NSBitmapImageRep imageRepWithData: [pdfImage TIFFRepresentation]];
                
                if( bitRep.pixelsWide > pdfImage.size.width)
                {
                    height = bitRep.pixelsHigh;
                    width = bitRep.pixelsWide;
                }
                else
                {
                    height = pdfImage.size.height;
                    width = pdfImage.size.width;
                }
            }
            
            NSString *referencedSOPInstanceUID = [SRAnnotation getImageRefSOPInstanceUID: filePath];
            
            if( referencedSOPInstanceUID)
                [dicomElements setObject: referencedSOPInstanceUID forKey: @"referencedSOPInstanceUID"];
            
            @try
            {
                if( [[dicomElements objectForKey: @"seriesDescription"] hasPrefix: @"OsiriX ROI SR"])
                {
                    NSString *referencedSOPInstanceUID = [SRAnnotation getImageRefSOPInstanceUID: filePath];
                    if( referencedSOPInstanceUID)
                        [dicomElements setObject: referencedSOPInstanceUID forKey: @"referencedSOPInstanceUID"];
                    
                    int numberOfROIs = [[NSUnarchiver unarchiveObjectWithData: [SRAnnotation roiFromDICOM: filePath]] count];
                    [dicomElements setObject: [NSNumber numberWithInt: numberOfROIs] forKey: @"numberOfROIs"];
                }
            }
            @catch (NSException * e)
            {
                N2LogExceptionWithStackTrace(e);
            }
        }
#endif
#endif
        
        NoOfSeries = 1;
        
        if( patientID == nil) patientID = [[NSString alloc] initWithString:@""];
        
        if( NoOfFrames > 1) // SERIES ID MUST BE UNIQUE!!!!!
            self.serieID = [NSString stringWithFormat:@"%@-%@-%@", self.serieID, imageID, [dicomElements objectForKey:@"SOPUID"]];
        
        if( NoOfFrames <= 1 && [self noLocalizer] && ([self containsString: @"LOCALIZER" inArray: imageTypeArray] || [self containsString: @"REF" inArray: imageTypeArray] || [self containsLocalizerInString: serie]) && [DCMAbstractSyntaxUID isImageStorage: sopClassUID])
        {
            self.serieID = @"LOCALIZER";
            
            [serie release];
            serie = [[NSString alloc] initWithString: @"Localizers"];
            [dicomElements setObject:serie forKey:@"seriesDescription"];
            
            [dicomElements setObject: [self.serieID stringByAppendingString: studyID] forKey: @"seriesDICOMUID"];
        }		
        
        [dicomElements setObject:[self patientUID] forKey:@"patientUID"];
        
        if( self.serieID == nil) self.serieID = name;
        
        if( [Modality isEqualToString:@"US"] && [self oneFileOnSeriesForUS])
        {
            [dicomElements setObject: [self.serieID stringByAppendingString: [filePath lastPathComponent]] forKey:@"seriesID"];
        }
        else if ( [self combineProjectionSeries] && ([Modality isEqualToString:@"MG"] || [Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]))
        {
            if( [self combineProjectionSeriesMode] == 0)		// *******Combine all CR and DR Modality series in a study into one series
            {
                if( sopClassUID != nil && [[DCMAbstractSyntaxUID hiddenImageSyntaxes] containsObject: sopClassUID])
                    [dicomElements setObject:self.serieID forKey:@"seriesID"];
                else
                    [dicomElements setObject:studyID forKey:@"seriesID"];
                
                [dicomElements setObject:[NSNumber numberWithLong: [self.serieID intValue] * 1000 + [imageID intValue]] forKey:@"imageID"];
            }
            else if( [self combineProjectionSeriesMode] == 1)	// *******Split all CR and DR Modality series in a study into one series
            {
                [dicomElements setObject: [self.serieID stringByAppendingString: imageID] forKey:@"seriesID"];
            }
            else NSLog( @"ARG! ERROR !? Unknown combineProjectionSeriesMode");
        }
        else
            [dicomElements setObject:self.serieID forKey:@"seriesID"];
        
        if( studyID == nil)
        {
            studyID = [[NSString alloc] initWithString:name];
            [dicomElements setObject:studyID forKey:@"studyID"];
        }
        
        if( imageID == nil)
        {
            imageID = [[NSString alloc] initWithString:name];
            [dicomElements setObject:imageID forKey:@"SOPUID"];
        }
        
        if( date == nil)
        {
            date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil] retain];
            [dicomElements setObject:date forKey:@"studyDate"];
        }
        
        [dicomElements setObject:[NSNumber numberWithBool:YES] forKey:@"hasDICOM"];
        
        if( name != nil && studyID != nil && self.serieID != nil && imageID != nil && width != 0 && height != 0)
        {
            return 0;   // success
        }
    }
    
    return-1;
}
@end
