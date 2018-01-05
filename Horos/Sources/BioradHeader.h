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
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#define BIORAD_HEADER_LENGTH 76
#define BIORAD_NOTE_LENGTH 96
#define BIORAD_NOTE_TEXT_LENGTH 80

struct BioradHeader{
	short int nx,ny,npic;
	 int unused0;
	 int notesAvailable;
	short int byte_format;
	char unused1[38];
	short int magicNumber;
	char unused2[20];
} __attribute__((__packed__));

struct BioradNote
{
//	short displayLevel;
//	int moreNotes; // 0 if this is the last note, else there is another note
//	int unused;
//  	short noteType;
	char unsused[16];
/* Note type := 1 for live collection note,
  := 2 for note including file name,
  := 3 if note for multiplier file,
  := 4, 5, etc.,; additional descriptive notes */
	char noteText[BIORAD_NOTE_LENGTH];
} __attribute__((__packed__));


/*
  Bio-Rad(TM) .PIC Image File Information
  (taken from: "Introductory Edited Version 1.0", issue 1/12/93.)
  (Location of Image Calibration Parameters in Comos 6.03 and MPL .PIC files)

  The general structure of Bio-Rad .PIC files is as follows:

  HEADER (76 bytes)
  Image data (#1)
  .
  .
  Image data (#npic)
  NOTE (#1)
  .                       ; NOTES are optional.
  .
  NOTE (#notes)
  RGB LUT (color Look Up Table)


  Header Information:

  The header of Bio-Rad .PIC files is fixed in size, and is 76 bytes.

  ------------------------------------------------------------------------------
  'C' Definition              byte    size    Information
  (bytes)   
  ------------------------------------------------------------------------------
  int nx, ny;                 0       2*2     image width and height in pixels
  int npic;                   4       2       number of images in file
  int ramp1_min, ramp1_max;   6       2*2     LUT1 ramp min. and max.
  NOTE *notes;                10      4       no notes=0; has notes=non zero
  BOOL byte_format;           14      2       bytes=TRUE(1); words=FALSE(0)
  int n;                      16      2       image number within file
  char name[32];              18      32      file name
  int merged;                 50      2       merged format
  unsigned color1;            52      2       LUT1 color status
  unsigned file_id;           54      2       valid .PIC file=12345
  int ramp2_min, ramp2_max;   56      2*2     LUT2 ramp min. and max.
  unsigned color2;            60      2       LUT2 color status
  BOOL edited;                62      2       image has been edited=TRUE(1)
  int _lens;                  64      2       Integer part of lens magnification
  float mag_factor;           66      4       4 byte real mag. factor (old ver.)
  unsigned dummy[3];          70      6       NOT USED (old ver.=real lens mag.)
  ------------------------------------------------------------------------------

  Additional information about the HEADER structure:

  Bytes   Description     Details
  ------------------------------------------------------------------------------
  0-9     nx, ny, npic, ramp1_min, ramp1_max; (all are 2-byte integers)

  10-13   notes           NOTES are present in the file, otherwise there are
  none.  NOTES follow immediately after image data at
  the end of the file.  Each note os 96 bytes long.

  14-15   byte_format     Read as a 2 byte integer.  If this is set to 1, then
  each pixel is 8-bits; otherwise pixels are 16-bits.

  16-17   n               Only used in COMOS/SOM when the file is loaded into
  memory.

  18-49   name            The name of the file (without path); zero terminated.

  50-51   merged          see Note 1.

  52-53   colour1

  54-55   file_id         Read as a 2 byte integer.  Aways set to 12345.
  Just a check that the file is in Bio-Rad .PIC format.

  56-59   ramp2_min/max   Read as 2 byte integers.

  60-61   color2          Read as a 2 byte integer.

  62-63   edited          Not used in disk files.

  64-65   int_lens        Read as a 2 byte integer.
  Integer part of the objective lens used.

  66-69   mag_factor      Read as a 4-byte real.

  mag. factor=(float)(dispbox.dy*2)/(float)(512.0*scandata.ly)

  where:  dispbox.dy = the width of the image.
  scandata.ly = the width of the scan region.

  the pixel size in microns can be calculated as follows:

  pixel size = scale_factor/lens/mag_factor

  where:  lens = the objective lens used as a floating pt. number
  scale_factor = the scaling number setup for the system
  on which the image was collected.

  70-75   dummy[3]    Last 6 bytes not used in current version of disk file
  format. (older versions stored a 4 byte real lens mag
  here.)
  ------------------------------------------------------------------------------

  Note 1 : Values stored in bytes 50-51 :

  0        : Merge off
  1        : 4-bit merge
  2        : Alternate 8-bit merge
  3        : Alternate columns merge
  4        : Alternate rows merge
  5        : Maximum pixel intensity merge
  6        : 256 colour optimised merge with RGB LUT saved at the end
  of each merge.
  7        : As 6 except that RGB LUT saved after all the notes.


  Information about NOTE structure and the RGB LUT are not included in this
  file.  Please see the Bio-Rad manual for more information.


  ==============================================================================

  Info added by Geert Meesen from MRC-600 and MRC-1024 Manuals.

  -------------------------------------------------------------

  Note Structure : 

  Bytes   Description     Details
  ------------------------------------------------------------------------------
  0-1     Display level of this note

  2-5     =0 if this is the last note, else there is another note (32 bit integer)

  10-11   Note type := 1 for live collection note,
  := 2 for note including file name,
  := 3 if note for multiplier file,
  := 4, 5, etc.,; additional descriptive notes

  16-95   Text of note (80 bytes)


  =============================================================================

  Info added by Geert Meesen from personal experiments.

  ------------------------------------------------------------

  - Until now I only have experience with 8-bit images from the MRC-1024 confocal microscope. 
  The newer microscopes (Radiance 2000, for example) are capable of generating 16 bit images, 
  I think. I have access to such a microscope and will try to find out later. For now it
  should be possible to look at the byte-word flag in the header.

  - I have experience with two types of images : 
  --- One slice in the Z-direction, 3 channels of recording. This type is stored as a three-slice image
  with the 3 channels in consecutive layers. (Single-Slice)
  --- Different Z slices with only one channel. (Z-stack)

  - The header should contain some info about the pixel-size, but until now I was not really
  able to interpret this info. It's easier to extract the info from the notes at the end.
  You can find 3 notes saying something like (from AUPCE.NOT, a Z-stack file)

  AXIS_2 001 0.000000e+00 2.999667e-01 microns                                    
  AXIS_3 001 0.000000e+00 2.999667e-01 microns                                    
  AXIS_4 001 0.000000e+00 1.000000e+00 microns                                    
  AXIS_9 011 0.000000e+00 1.000000e+00 RGB channel

  These lines give the pixelsize for the X (axis_2), Y (axis_3) and Z (axis_4) axis in the units mentioned. I don't
  know if this unit is always 'microns'.

  For a Single-Slice images you get ( from AB003A.NOT, a Single-Slice image) :

  AXIS_2 001 0.000000e+00 1.799800e+00 microns
  AXIS_3 001 0.000000e+00 1.799800e+00 microns
  AXIS_4 011 0.000000e+00 1.000000e+00 RGB channel

  It seems that AXIS_4 is used for indicating an RGB channel image.
*/
