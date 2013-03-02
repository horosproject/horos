This repository contains the source code of OsiriX, the open-source DICOM Viewer.

About OsiriX...

OsiriX is an image processing software dedicated to DICOM images (".dcm" / ".DCM" extension) produced by imaging equipment (MRI, CT, PET, PET-CT, SPECT-CT, Ultrasounds, ...). It is fully compliant with the DICOM standard for image comunication and image file formats. OsiriX is able to receive images transferred by DICOM communication protocol from any PACS or imaging modality (C-STORE SCP/SCU, and Query/Retrieve : C-MOVE SCU/SCP, C-FIND SCU/SCP, C-GET SCU/SCP, WADO) .

OsiriX has been specifically designed for navigation and visualization of multimodality and multidimensional images: 2D Viewer, 3D Viewer, 4D Viewer (3D series with temporal dimension, for example: Cardiac-CT) and 5D Viewer (3D series with temporal and functional dimensions, for example: Cardiac-PET-CT). The 3D Viewer offers all modern rendering modes: Multiplanar reconstruction (MPR), Surface Rendering, Volume Rendering and Maximum Intensity Projection (MIP). All these modes support 4D data and are able to produce image fusion between two different series (PET-CT and SPECT-CT display support).

OsiriX is at the same time a DICOM PACS workstation for imaging and an image processing software for medical research (radiology and nuclear imaging), functional imaging, 3D imaging, confocal microscopy and molecular imaging.

Who is behind OsiriX? Read the User Manual introduction: http://www.osirix-viewer.com/UserManualIntroduction.pdf.

OsiriX is currently developped and maintained by Pixmeo, a Geneva based company in Switzerland.

Looking for certified version for using OsiriX in clinical environments? We distribute a FDA-Cleared version for primary diagnostic imaging: OsiriX MD, or you can go to our partners page to find a certified version of OsiriX.

OsiriX is available in 32-bit and 64-bit format. The 64-bit version allows you to load an unlimited number of images, exceeding the 4-GB limit of 32-bit applications. The 64-bit version is also fully optimized for Intel multi-cores processors, offering the best performances for 3D renderings.

OsiriX supports a complete plug-ins architecture that allows you to expand the capabilities of OsiriX for your personal needs! This plug-in architecture gives you access to the powerfull Cocoa framework with an easy object-oriented and dynamic language: Objective-C.

Current features

DICOM File Support
Read and display all DICOM Files (mono-frame, multi-frames)
Read and display the new MRI/CT multi-frame format (5200 group)
JPEG Lossy, JPEG Lossless, JPEG-LS, JPEG 2000, RLE
Monochrome1, Monochrome2, RGB, YBR, Planar, Palettes, ...
Support custom (non-square) Pixel Aspect Ratio
8, 12, 16, 32 bits
Write 'SC' (Secondary Capture) DICOM Files from any 2D/3D reconstructions
Read and display all DICOM Meta-Data
Read AND Write DICOM CD/DVD (DICOMDIR support)
Export DICOM Files to TIFF, JPEG, Quicktime, RAW, DICOM, PACS
CD/DVD Creation with DICOMDIR support, including cross-platform viewer (Weasis)
Built-in SQL compatible database with unlimited number of files

DICOM Network Support
Send studies (C-STORE SCU, DICOM Send)
Receive studies (C-STORE SCP, DICOM Listener)
Query and Retrieve studies from/to a PACS workstation (C-FIND SCU, C-MOVE SCU, WADO)
Use OsiriX as a DICOM PACS server (C-FIND SCP, C-MOVE SCP, WADO)
On-the-fly conversion between all DICOM transfer syntaxes
C-GET SCU/SCP and WADO support for dynamic IP transfers
DICOM Printing support
Seamless integration with OsiriX HD for iPhone/iPad
Seamless integration with any PACS server, including the open-source dcm4chee server

Non-DICOM Files Support
LSM files from Zeiss (8, 16, 32 bits) (Confocal Microscopy)
BioRadPIC files (8, 16, 32 bits) (Confocal Microscopy)
TIFF (8, 12, 16, 32 bits), multi-pages
ANALYZE (8, 12, 16, 32 bits)
PNG, JPEG, PDF (multi-pages), Quicktime, AVI, MPEG, MPEG4

2D Viewer
Intuitive GUI
Customizable Toolbars
Bicubic Interpolation with full 32-bit pixel pipeline
Thick Slab for multi-slices CT and MRI (Mean, MIP, Volume Rendering)
ROIs: Polygons, Circles, Pencil, Rectangles, Point, ... with undo/redo support
Key Images
Multi-Buttons and Scroll-wheel mouses supported, including Magic Trackpad support.
Custom CLUT (Color Look-Up Tables)
Custom 3x3 and 5x5 Convolution Filters (Bone filters, ...)
4D Viewer for Cardiac-CT and other temporal series
Image Fusion for PET-CT & SPECT-CT exams with adjustable blending percentage
Image subtraction for XA
Hanging Protocols
Tiles export
2D Image Registration & Reslicing
Workspaces
Image stiching
Plugins support for external functions

3D Post-Processing
MPR (Multiplanar Reconstruction) with Thick Slab (Mean, MIP, Volume Rendering)
3D Curved-MPR
with Thick Slab
3D MIP (Maximum Intensity Projection)
3D Volume Rendering
3D Surface Rendering
3D ROIs
3D Image Registration
Stereo Vision with Red/Blue glasses
Export any 3D images to Quicktime, TIFF, JPEG
All 3D viewers support 'Image Fusion' for PET-CT exams and '4D mode' for Cardiac-CT.

Optimization
Multi-threaded for multi-processors and multi-core processors support
Asyncronous reading
OpenGL for 2D Viewer and all 3D Viewers
Graphic board accelerated, with 3D texture mapping support
Available in 32-bit and 64-bit

Expansion & Scientific Research
OsiriX supports a complete dynamic plugins architecture
Access pixels directly in 32-bits float for B&W images or ARGB values for color images
Create and manage windows
Access the entire Cocoa framework
Create and manage OpenGL views
Faster than IDL, Easier than ImageJ !

Based on robust Open-Source components
Cocoa (OpenStep, GNUStep, NextStep)
VTK (Visualization Toolkit)
ITK (Insight Toolkit)
PixelMed (David Clunie)
Papyrus 3.0
DICOM Offis DCMTK
OpenGL
LibTIFF
LibJPEG
CharLS

Complete DICOM Conformance statement for OsiriX is available here: http://www.osirix-viewer.com/DICOMConformanceStatements.pdf

