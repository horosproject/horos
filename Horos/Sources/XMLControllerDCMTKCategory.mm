/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "XMLControllerDCMTKCategory.h"
#import "BrowserController.h"
#undef verify

#include "osconfig.h"
#include "mdfconen.h"
#import "N2Debug.h"

#include "dcvrsl.h"
#include "ofcast.h"
#include "ofstd.h"
#include "dctk.h"
#include "dcuid.h"

#define INCLUDE_CSTDIO
#include "ofstdinc.h"


#import "DicomFile.h"
#import "DICOMToNSString.h"
#import "DicomFileDCMTKCategory.h"
#import "DCMAttributeTag.h"
#include <GDCM/gdcmReader.h>
#include <GDCM/gdcmDefs.h>
#include <GDCM/gdcmAnonymizer.h>
#include <GDCM/gdcmWriter.h>

extern NSRecursiveLock *PapyrusLock;

@implementation XMLController (XMLControllerDCMTKCategory)


+ (BOOL) modifyDicom:(NSArray*) tagAndValues dicomFiles:(NSArray*) dicomFiles
{
    BOOL modifySuccess = YES;
    
    for (NSString* f in dicomFiles)
    {
        const char* filename = [f cStringUsingEncoding:[NSString defaultCStringEncoding]];
        
        gdcm::Reader reader;
        
        reader.SetFileName(filename);
        
        if( !reader.Read() )
        {
            std::cerr << "Can't read file for anonymization." << std::endl;
            
            modifySuccess = NO;
            
            continue;
        }
        else
        {
            gdcm::File &file = reader.GetFile();
            
            gdcm::MediaStorage ms;
            ms.SetFromFile(file);
            if( !gdcm::Defs::GetIODNameFromMediaStorage(ms) )
            {
                std::cerr << "The Media Storage Type is not supported for anonymization: " << ms << std::endl;
                
                modifySuccess = NO;
                
                continue;
            }
            else
            {
                NSStringEncoding encoding = [NSString defaultCStringEncoding];
                
                if ([dicomFiles lastObject] != nil)
                {
                    if ([[DicomFile getEncodingArrayForFile:[dicomFiles lastObject]] count] > 0)
                    {
                        encoding = [NSString encodingForDICOMCharacterSet:[[DicomFile getEncodingArrayForFile:[dicomFiles lastObject]] objectAtIndex: 0]];
                    }
                }
                
                std::vector< std::pair<gdcm::Tag, std::string> > replace_tags;
                for (NSArray* replacingItem in tagAndValues)
                {
                    std::string newValue = "";
                    
                    DCMAttributeTag* tag = ([replacingItem count] > 0 ? [replacingItem objectAtIndex:0] : nil);
                    
                    if (tag)
                    {
                        if ([replacingItem count] >= 2)
                            newValue = std::string( [[replacingItem objectAtIndex:1] cStringUsingEncoding:encoding] );
                    
                        replace_tags.push_back( std::make_pair(gdcm::Tag(tag.group,tag.element),newValue) );
                    }
                }
                
                /////////////////////////////
                /////////////////////////////
                /////////////////////////////
                /////////////////////////////
                /////////////////////////////
                
                gdcm::Anonymizer anon;
                anon.SetFile( file );
                
                bool success = true;
                
                std::vector< std::pair<gdcm::Tag, std::string> >::const_iterator it2 = replace_tags.begin();
                for(; it2 != replace_tags.end(); ++it2)
                {
                    success = success && anon.Replace( it2->first, it2->second.c_str() );
                }
                
                if (!success)
                {
                    modifySuccess = NO;
                }
                
                /////////////////////////////
                /////////////////////////////
                /////////////////////////////
                /////////////////////////////
                /////////////////////////////
                
                const char* outfilename = filename;
                
                gdcm::Writer writer;
                writer.SetFileName( outfilename );
                writer.SetFile( file );
                
                if( !writer.Write() )
                {
                    std::cerr << "Could not Write : " << outfilename << std::endl;
                    if( strcmp(filename,outfilename) != 0 )
                    {
                        gdcm::System::RemoveFile( outfilename );
                    }
                    else
                    {
                        std::cerr << "gdcmanon just corrupted: " << filename << " (data lost)." << std::endl;
                        
                    }
                    
                    modifySuccess = NO;
                    
                    continue;
                }
            }
        }
    }
    
    //////////////////////
    //////////////////////
    //////////////////////
    //////////////////////
    //////////////////////
    
    return modifySuccess;
}


+ (int) modifyDicom:(NSArray*) params encoding: (NSStringEncoding) encoding
{
	int error_count = 0;
	
	@try 
	{
		int i, argc = [params count];
		char *argv[ argc];
		
		for( i = 0; i < argc; i++)
        {
            if ([params count] >= i+1)
                argv[ i] = (char*) [[params objectAtIndex: i] cStringUsingEncoding: encoding];
            else
                argv[ i] = (char*) [@"" cStringUsingEncoding: encoding];
        }
		
		MdfConsoleEngine engine( argc, argv,"dcmodify");
		
		error_count=engine.startProvidingService();
		
		if (error_count > 0)
			NSLog( @"------- XMLController modifyDicom : there were %d errors", error_count);
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
    return error_count;
}

-(int) getGroupAndElementForName:(NSString*) name group:(int*) gp element:(int*) el
{
	int result = 0;
    DcmTagKey key(0xffff,0xffff);
    const DcmDataDictionary& globalDataDict = dcmDataDict.rdlock();
    const DcmDictEntry *dicent = globalDataDict.findEntry( [name UTF8String]);
	
    //successfull lookup in dictionary -> translate to tag and return
    
	if (dicent)
    {
        key = dicent->getKey();
		*gp = key.getGroup();
		*el = key.getElement();
		
		result = 0;
     }
	 else result = -1;
	 
     dcmDataDict.unlock();
    
	return result;
}

- (void) prepareDictionaryArray
{
	DcmDictEntry* e = NULL;
	DcmDataDictionary& globalDataDict = dcmDataDict.wrlock();
	
	DcmDictEntryList list;
    DcmHashDictIterator iter(globalDataDict.normalBegin());
    for( int x = 0; x < globalDataDict.numberOfNormalTagEntries(); ++iter, x++)
    {
        if ((*iter)->getPrivateCreator() == NULL) // exclude private tags
        {
          e = new DcmDictEntry(*(*iter));
          list.insertAndReplace(e);
        }
    }
	
    /* output the list contents */
    DcmDictEntryListIterator listIter(list.begin());
    DcmDictEntryListIterator listLast(list.end());
    for (; listIter != listLast; ++listIter)
    {
		e = *listIter;
		
		if( e->getGroup() > 0)
		{
			NSString	*s = [NSString stringWithFormat:@"(0x%04x,0x%04x) %s", e->getGroup(), e->getElement(), e->getTagName()];
		
			[dictionaryArray addObject: s];
		}
    }
	
	dcmDataDict.unlock();
}
@end
