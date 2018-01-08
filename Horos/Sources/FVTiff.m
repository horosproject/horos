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


#include "FVTiff.h"
#include "CoreFoundation/CFByteOrder.h"
#include "string.h"
#include <stdio.h>

static TIFFExtendProc _TIFFParentExtender = NULL;

static void _FVTIFFDefaultDirectory(TIFF *tif);

int FV_Read_DIM_INFO(const char* data, FV_MM_DIM_INFO* info)
{
	memset(info, 0, sizeof(FV_MM_DIM_INFO));
	
	strncpy(info->Name, data, FV_DIMNAME_LENGTH);
	data += FV_DIMNAME_LENGTH;
	
	info->Size = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	*((unsigned long long*) &(info->Origin)) = CFSwapInt64LittleToHost(*((unsigned long long*) data));
	data += sizeof(unsigned long long);
	
	*((unsigned long long*) &(info->Resolution)) = CFSwapInt64LittleToHost(*((unsigned long long*) data));
	data += sizeof(unsigned long long);
	
	strncpy(info->Units, data, FV_UNITS_LENGTH);
	return 1;
}

int FV_Read_MM_HEAD(const char* data, FV_MM_HEAD* head) // for now I don't quite understand how the MM_HEAD is stored, so I will only fill in 
{														// the members I feel kinda confident about
	int i = 0;

	memset(head, 0, sizeof(FV_MM_HEAD));
	
	head->HeaderFlag = CFSwapInt16LittleToHost(*((unsigned short*) data));
	data += sizeof(unsigned short);
	
	head->Status = *((unsigned char*) data);
	data += sizeof(unsigned char);

	head->ImageType = *((unsigned char*) data);
	data += sizeof(unsigned char);

	strncpy(head->Name, data, FV_IMAGE_NAME_LENGTH);
	data += FV_IMAGE_NAME_LENGTH;
	
	head->Data = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	head->NumberOfColors = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	head->MM_256_Colors = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	head->MM_All_Colors = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	head->CommentSize = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	head->Comment = CFSwapInt32LittleToHost(*((unsigned int*) data));
	data += sizeof(unsigned int);
	
	for (i = 0; i < FV_SPATIAL_DIMENSION; i++)
	{
		FV_Read_DIM_INFO(data, &head->DimInfo[i]);
		data += sizeof(FV_MM_DIM_INFO);
	}
	
	return 1;
}

NSXMLDocument * XML_from_FVTiff(NSString* srcFile)
{
	NSXMLElement *rootElement = [[NSXMLElement alloc] initWithName:@"FVTiff Meta-Data"];
	NSXMLDocument *xmlDocument = 0;
	char* desc = 0;
	int success = 0;

	TIFF* tif = TIFFOpen([srcFile UTF8String], "r");
	if(tif)
		success = TIFFGetField(tif, TIFFTAG_IMAGEDESCRIPTION, &desc);
	if (success)
	{
		int i;
		int descLen = strlen(desc);
		int lineStart = 0;
		char lineBuffer[256];
		char* line = lineBuffer;
		line[0] = 0;
		NSMutableArray *elements = [NSMutableArray array];
		
		for (i = 0; i < descLen; i++)
		{
			if (desc[i] == 0x0D || desc[i] == 0x0A)
			{
				int lineLen = i - lineStart;
				if (lineLen > 0)
				{
					strncpy(line, desc + lineStart, lineLen);
					line[lineLen] = 0;
					
					if (line[0] == '[' && strcmp(line + (lineLen - 4), "End]") == 0) // new node
					{
						line[lineLen - 5] = 0;
						line++;
						
						NSXMLNode *element = [NSXMLNode elementWithName:[NSString stringWithUTF8String:line] children:elements attributes:nil];
						[rootElement addChild:element];
						elements = [NSMutableArray array];
					}
					else if (line[0] != '[')
					{
						NSXMLNode *element;
						char* value;
						value = index(line, '=');
						if (value)
						{
							value[0] = 0;
							value++;

							element = [NSXMLNode elementWithName:[NSString stringWithUTF8String:line] children:nil attributes:nil];
							[element setStringValue:[NSString stringWithUTF8String:value]];
						}
						else
						{
							element = [NSXMLNode elementWithName:@"Comment" children:nil attributes:nil];
							[element setStringValue:[NSString stringWithUTF8String:line]];							
						}
						[elements addObject:element];
					}
				}
				lineStart = i + 1;
			}
		}
	}
	
	if(tif) TIFFClose(tif);
	
	xmlDocument = [[NSXMLDocument alloc] initWithRootElement:rootElement];
	[rootElement release];
	return xmlDocument;
}


void FVTIFFInitialize(void)
{
    static int first_time=1;
        
    if (! first_time) return; /* Been there. Done that. */
    first_time = 0;
        
    /* Grab the inherited method and install */
    _TIFFParentExtender = TIFFSetTagExtender(_FVTIFFDefaultDirectory);
	
//	TIFFSetWarningHandler((TIFFErrorHandler) FV_EMPTY_TIFFWarning);			<- This is crashing in 64-bit !!!
}

static void
_FVTIFFDefaultDirectory(TIFF *tif)
{
    /* Install the extended Tag field info */
    TIFFMergeFieldInfo(tif, FVTiffFieldInfo, sizeof(FVTiffFieldInfo) / sizeof(FVTiffFieldInfo[0]));

    /* Since an FVTIFF client module may have overridden
     * the default directory method, we call it now to
     * allow it to set up the rest of its own methods.
     */

    if (_TIFFParentExtender) 
        (*_TIFFParentExtender)(tif);
}

void FV_EMPTY_TIFFWarning(const char *module, const char *fmt, ...){}

