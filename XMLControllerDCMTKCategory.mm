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

#import "XMLControllerDCMTKCategory.h"

#undef verify

#include "osconfig.h"
#include "mdfconen.h"

#include "dcvrsl.h"
#include "ofcast.h"
#include "ofstd.h"
#include "dctk.h"
#include "dcuid.h"

#define INCLUDE_CSTDIO
#include "ofstdinc.h"

@implementation XMLController (XMLControllerDCMTKCategory)

-(int) modifyDicom:(NSArray*) params
{
	int			i, argc = [params count];
	char		*argv[ argc];
	
	NSLog( [params description]);
	
	for( i = 0; i < argc; i++)
	{
		argv[ i] = (char*) [[params objectAtIndex: i] UTF8String];
	}
	
    int error_count = 0;
    
	MdfConsoleEngine engine( argc, argv,"dcmodify");
    
	error_count=engine.startProvidingService();
    
	if (error_count > 0)
	    CERR << "There were " << error_count << " error(s)" << endl;
	
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
    DcmHashDictIterator end(globalDataDict.normalEnd());
    for (; iter != end; ++iter)
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
