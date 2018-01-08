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

#import <Foundation/Foundation.h>

/** \brief  DICOM Attribute Tag 
*
*  The DICOM  Attribute tags consist of a 4 byte group and a 4 byte element in hexadecimal notation
* Other properties are the VR value representation.  For implicit transfer syntaxes
* the VR is obtained from the dicom dictionary.  For explicit transfer syntaxes, the VR will be defined in the
* file/data.  The string valeu is the human readable definition of the tag.
*/
@interface DCMAttributeTag : NSObject {

	int  _group;
	int _element;
	NSString *_name;
	NSString *_vr;
	NSString *_stringValue;
	

}
@property(readonly) int group;
@property(readonly) int element;
@property(readonly) NSString *stringValue;
@property(readonly) BOOL isPrivate;
@property(readonly) long longValue;
@property(retain) NSString *vr;
@property(readonly) NSString *name;
@property(readonly) NSString *description;

/** Create a tag with the defined group and element.*/
+ (id)tagWithGroup:(int)group element:(int)element;

/** Create a copy of a tag */
+ (id)tagWithTag:(DCMAttributeTag *)tag;

/** Create a tag  from a string representation of the element and tag\n
* Format for the string is 0xGGGG,0xEEEE
*/
+ (id)tagWithTagString:(NSString *)tagString;

/** Create a tag with the human readable name
* For Exmaple @"PatientsName.\n
* See the name dictionary for the list of names
*/
+ (id)tagWithName:(NSString *)name;

/** Initialize a tag with the defined group and element.*/
- (id)initWithGroup:(int)group element:(int)element;

/** Initialize a copy of a tag */
- (id)initWithTag:(DCMAttributeTag *)tag;

/** Create a tag  from a string representation of the element and tag\n
* Format for the string is oxGGGGEEEE
*/
- (id)initWithTagString:(NSString *)tagString;

/** Initialize a tag with the human readable name
* For Exmaple @"PatientsName.\n
* See the name dictionary for the list of names
*/
- (id)initWithName:(NSString *)name;


/** Compare tags. Used for sorting */
- (NSComparisonResult)compare:(DCMAttributeTag *)tag;

/** Tests to see if group and element are the same */
- (BOOL)isEquaToTag:(DCMAttributeTag *)tag;

- (NSString *)readableDescription;
@end
