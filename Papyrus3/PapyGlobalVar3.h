/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyGlobalVar3.h                                             */
/*	Function : contains the declarations of global variables                */
/********************************************************************************/

#ifndef PapyGlobalVar3H 
#define PapyGlobalVar3H

#ifdef FILENAME83	
#undef FILENAME83	
#endif


/* --- global variables --- */

/* compatibility variables to ensure the version of the PAPYRUS toolkit */
/* is able to read a given file */

/* which version of the PAPYRUS toolkit are we running ? */
WHERE3 char		gPapyrusVersion 	[6];

/* is my file compatible with this version of the PAPYRUS toolkit */
WHERE3 char		gPapyrusCompatibility	[2];

/* the version of this particular PAPYRUS file */
WHERE3 float	        gPapyrusFileVersion	[kMax_file_open];

WHERE3 void *gCachedGroupLength[kMax_file_open];

WHERE3 void *gCachedFramesMap[kMax_file_open];
WHERE3 int gCachedFrameCount[kMax_file_open];

/* has the PAPYRUS toolkit been initialized or not ? */
WHERE3 int		gIsPapy3Inited;

/* Papyrus file pointers to the currently open files */
WHERE3 PAPY_FILE	gPapyFile		[kMax_file_open];
WHERE3 PapyULong    gPapyFileSize	[kMax_file_open];
WHERE3 char			*gPapyFilePath	[kMax_file_open];
WHERE3 int      	gSeekPos		[kMax_file_open];
WHERE3 char      	gSeekPosApplied	[kMax_file_open];
WHERE3 int			goImageSize		[kMax_file_open];
/* What is the type of the fiel we are dealing with ? */
/* DICOM10, PAPYRUS3, DICOM_NOT10, DICOMDIR */
WHERE3 enum EFile_Type	gIsPapyFile		[kMax_file_open];

/* the current name (incremental) to give to a tmp or DICOM file */
WHERE3 int		gCurrTmpFilename	[kMax_file_open];

/* filename for each open file in write mode */
WHERE3 char		*gPapFilename		[kMax_file_open];

/* filename for each open file in write mode */
WHERE3 char		*gPapSOPInstanceUID		[kMax_file_open];


/* nb of images in each file */						    
WHERE3 PapyShort	gArrNbImages		[kMax_file_open];

/* pointer to the list of icons (only valid if Papyrus compressed images */
WHERE3 PapyUChar	**gArrIcons		[kMax_file_open];

/* pointers to the group 41 of each file in read mode */
WHERE3 SElement		*gArrGroup41		[kMax_file_open];

/* pointers to the group 41 of each file in read mode */
WHERE3 SElement		*unknownElements       [kMax_file_open];
WHERE3 long         unKnownElementsNumber   [kMax_file_open];

/* the syntax used in each open file */
WHERE3 enum ETransf_Syntax gArrTransfSyntax 	[kMax_file_open];
WHERE3 char		*gSOPClassUID	[kMax_file_open];
/* the compression used for the images of each file */
WHERE3 enum EPap_Compression gArrCompression	[kMax_file_open];

/* the photometric interpretation of the images of each file */
WHERE3 enum EPhoto_Interpret gArrPhotoInterpret	[kMax_file_open];

/* the pointers on the memory structure of the files */
WHERE3 Item		*gArrMemFile		[kMax_file_open];

/* pointers to the file summaries objects */
WHERE3 Item		*gPatientSummaryItem	[kMax_file_open];

/* pointers to the begining of the pointer sequences item */
WHERE3 Item		*gPtrSequenceItem	[kMax_file_open];

/* pointers to the begining of the image sequences item */
WHERE3 Item		*gImageSequenceItem 	[kMax_file_open];

WHERE3 SGroup		gArrGroup		[END_GROUP];
WHERE3 PapyShort	gArrModule		[END_MODULE];

/* for each modality defined, store the enumeration of the modules and their usage */
WHERE3 Data_Set		*gArrModalities		[END_MODALITY];
WHERE3 int		gArrModuleNb		[END_MODALITY];
/* for each modality stores the associated UID */
WHERE3 char		*gArrUIDs		[END_MODALITY];
/* store the modality of each file */
WHERE3 int		gFileModality		[kMax_file_open];


/* is the file in read or write mode ? */
WHERE3 PapyShort	gReadOrWrite		[kMax_file_open];

/* the current overlay group number */
WHERE3 PapyUShort	gCurrentOverlay		[kMax_file_open];

/* the current UINoverlay group number */
WHERE3 PapyUShort	gCurrentUINOverlay 	[kMax_file_open];



/* nb of allowed element in shadow group */
WHERE3 PapyUShort 	gNbShadowOwner		[kMax_file_open];
/* list of allowed elements */
WHERE3 SShadowOwner	*gShadowOwner		[kMax_file_open];

/* backward references */
WHERE3 char		*gx0028ImageFormat 	[kMax_file_open];
WHERE3 PapyUShort	gx0028Rows		[kMax_file_open];
WHERE3 PapyUShort	gx0028Columns		[kMax_file_open];
WHERE3 PapyUShort	gx0028BitsAllocated 	[kMax_file_open];
WHERE3 PapyUShort	gx0028BitsStored	[kMax_file_open];



/* variables needed for the creation of the pointer sequence */

/* Image IdentificationpModulee */
WHERE3 char		*gRefSOPClassUID	[kMax_file_open];
WHERE3 char		*gRefSOPInstanceUID;
WHERE3 char		*gRefImageNb;

/* Icon Image pModule */
WHERE3 PapyUShort	gRefRows;
WHERE3 PapyUShort	gRefColumns;
WHERE3 PapyUShort	gRefBitsAllocated;
WHERE3 PapyUShort	gRefBitsStored;
WHERE3 PapyUShort	gRefHighBit;
WHERE3 PapyUShort	gRefIsSigned;
WHERE3 PapyUShort	gRefPixMin;
WHERE3 PapyUShort	gRefPixMax;
WHERE3 PapyLong		gRefWW;
WHERE3 PapyLong		gRefWL;
WHERE3 PapyUShort 	*gRefPixelData;
WHERE3 PapyUShort	gIconSize;	/* the size of the icon image */



/* the compression used for the images of the converted file */
WHERE3 enum EPap_Compression gCompression;
WHERE3 int	        gCompressionFactor;

WHERE3 float	        gZoomFactor;

WHERE3 float	        gSubSamplingFactor;

WHERE3 float            gLeftX;
WHERE3 float            gTopY;
WHERE3 float            gRightX;
WHERE3 float            gBottomY;
			
WHERE3 int	        gWindowWidth;
WHERE3 int	        gWindowLevel;



/* Image Pointer pModule & Pixel Offset pModule */

/* referenced SOP instance UID of each image of each file */
WHERE3 char		**gImageSOPinstUID	[kMax_file_open];

/* offset to the data set for each data set of each file */
WHERE3 PapyULong	*gRefImagePointer	[kMax_file_open];

/* offset to the pixel data element of each data set of each file */
WHERE3 PapyULong	*gRefPixelOffset	[kMax_file_open];

/* position of insertion of the value of gRefImagePointer (write) */
WHERE3 PapyULong	*gPosImagePointer	[kMax_file_open];

/* position of insertion of the value of gRefPixelOffset (write) */
WHERE3 PapyULong	*gPosPixelOffset	[kMax_file_open];

/* offset to the Pointer Sequence (read) */
WHERE3 PapyULong	gOffsetToPtrSeq		[kMax_file_open];

/* offset to the Image   Sequence (read) */
WHERE3 PapyULong	gOffsetToImageSeq	[kMax_file_open];



/* offset to the First Patient : 0x0004:0x1200 */
WHERE3 PapyULong	gPosFirstPatientOffset  [kMax_file_open];
WHERE3 PapyULong	gRefFirstPatientOffset  [kMax_file_open];
/* offset to the Last Patient : 0x0004:0x1202 */
WHERE3 PapyULong	gPosLastPatientOffset   [kMax_file_open];
WHERE3 PapyULong	gRefLastPatientOffset   [kMax_file_open];

/* offset of the Next Directory Record of the same Directory Entity */
WHERE3 PapyULong	*gPosNextDirRecordOffset  [kMax_file_open];
WHERE3 PapyULong	*gRefNextDirRecordOffset  [kMax_file_open];

/* offset of the First Directory Record of the Referenced Lower Level Directory */
WHERE3 PapyULong	*gPosLowerLevelDirRecordOffset	[kMax_file_open];
WHERE3 PapyULong	*gRefLowerLevelDirRecordOffset	[kMax_file_open];

/* the current file number (for the indexes) */
WHERE3 PapyShort	gCurrFile;

/* module names */
WHERE3 char            *sModule_Acquisition_Context;
WHERE3 char            *sModule_Approval;
WHERE3 char            *sModule_Audio;
WHERE3 char            *sModule_Basic_Annotation_Presentation;
WHERE3 char            *sModule_Basic_Film_Box_Presentation;
WHERE3 char            *sModule_Basic_Film_Box_Relationship;
WHERE3 char            *sModule_Basic_Film_Session_Presentation;
WHERE3 char            *sModule_Basic_Film_Session_Relationship;
WHERE3 char            *sModule_BiPlane_Image;
WHERE3 char            *sModule_BiPlane_Overlay;
WHERE3 char            *sModule_BiPlane_Sequence;
WHERE3 char            *sModule_Cine;
WHERE3 char            *sModule_Contrast_Bolus;
WHERE3 char            *sModule_CR_Image;
WHERE3 char            *sModule_CR_Series;
WHERE3 char            *sModule_CT_Image;
WHERE3 char            *sModule_Curve;
WHERE3 char            *sModule_Curve_Identification;
WHERE3 char            *sModule_Device;
WHERE3 char	       *sModule_Directory_Information;
WHERE3 char            *sModule_Display_Shutter;
WHERE3 char            *sModule_DX_Anatomy_Imaged;
WHERE3 char            *sModule_DX_Detector;
WHERE3 char            *sModule_DX_Image;
WHERE3 char            *sModule_DX_Positioning;
WHERE3 char            *sModule_DX_Series;
WHERE3 char	       *sModule_External_Papyrus_File_Reference_Sequence;
WHERE3 char	       *sModule_External_Patient_File_Reference_Sequence;
WHERE3 char	       *sModule_External_Study_File_Reference_Sequence;
WHERE3 char	       *sModule_External_Visit_Reference_Sequence;
WHERE3 char	       *sModule_File_Reference;
WHERE3 char	       *sModule_File_Set_Identification;
WHERE3 char            *sModule_Frame_Of_Reference;
WHERE3 char            *sModule_Frame_Pointers;
WHERE3 char            *sModule_General_Equipment;
WHERE3 char            *sModule_General_Image;
WHERE3 char            *sModule_General_Patient_Summary;
WHERE3 char            *sModule_General_Series;
WHERE3 char            *sModule_General_Series_Summary;
WHERE3 char            *sModule_General_Study;
WHERE3 char            *sModule_General_Study_Summary;
WHERE3 char            *sModule_General_Visit_Summary;
WHERE3 char            *sModule_Icon_Image;
WHERE3 char            *sModule_Identifying_Image_Sequence;
WHERE3 char            *sModule_Image_Box_Pixel_Presentation;
WHERE3 char            *sModule_Image_Box_Relationship;
WHERE3 char            *sModule_Image_Histogram;
WHERE3 char            *sModule_Image_Identification;
WHERE3 char            *sModule_Image_Overlay_Box_Presentation;
WHERE3 char            *sModule_Image_Overlay_Box_Relationship;
WHERE3 char            *sModule_Image_Pixel;
WHERE3 char            *sModule_Image_Plane;
WHERE3 char            *sModule_Image_Pointer;
WHERE3 char            *sModule_Image_Sequence;
WHERE3 char            *sModule_Internal_Image_Pointer_Sequence;
WHERE3 char            *sModule_Interpretation_Approval;
WHERE3 char            *sModule_Interpretation_Identification;
WHERE3 char            *sModule_Interpretation_Recording;
WHERE3 char            *sModule_Interpretation_Relationship;
WHERE3 char            *sModule_Interpretation_State;
WHERE3 char            *sModule_Interpretation_Transcription;
WHERE3 char            *sModule_Intra_Oral_Image;
WHERE3 char            *sModule_Intra_Oral_Series;
WHERE3 char            *sModule_LUT_Identification;
WHERE3 char            *sModule_Mammography_Image;
WHERE3 char            *sModule_Mammography_Series;
WHERE3 char            *sModule_Mask;
WHERE3 char            *sModule_Modality_LUT;
WHERE3 char            *sModule_MR_Image;
WHERE3 char            *sModule_Multi_Frame;
WHERE3 char            *sModule_Multi_frame_Overlay;
WHERE3 char            *sModule_NM_Detector;
WHERE3 char            *sModule_NM_Image;
WHERE3 char            *sModule_NM_Image_Pixel;
WHERE3 char            *sModule_NM_Isotope;
WHERE3 char            *sModule_NM_Multi_Frame;
WHERE3 char            *sModule_NM_Multi_gated_Acquisition_Image;
WHERE3 char            *sModule_NM_Phase;
WHERE3 char            *sModule_NM_Reconstruction;
WHERE3 char            *sModule_NM_Series;
WHERE3 char            *sModule_NM_Tomo_Acquisition;
WHERE3 char            *sModule_Overlay_Identification;
WHERE3 char            *sModule_Overlay_Plane;
WHERE3 char            *sModule_Palette_Color_Lookup;
WHERE3 char            *sModule_Patient;
WHERE3 char            *sModule_Patient_Demographic;
WHERE3 char            *sModule_Patient_Identification;
WHERE3 char            *sModule_Patient_Medical;
WHERE3 char            *sModule_Patient_Relationship;
WHERE3 char            *sModule_Patient_Study;
WHERE3 char            *sModule_Patient_Summary;
WHERE3 char            *sModule_PET_Curve;
WHERE3 char            *sModule_PET_Image;
WHERE3 char            *sModule_PET_Isotope;
WHERE3 char            *sModule_PET_Multi_Gated_Acquisition;
WHERE3 char            *sModule_PET_Series;
WHERE3 char            *sModule_Pixel_Offset;
WHERE3 char            *sModule_Printer;
WHERE3 char            *sModule_Print_Job;
WHERE3 char            *sModule_Result_Identification;
WHERE3 char            *sModule_Results_Impression;
WHERE3 char            *sModule_Result_Relationship;
WHERE3 char            *sModule_RF_Tomography_Acquisition;
WHERE3 char            *sModule_ROI_Contour;
WHERE3 char            *sModule_RT_Beams;
WHERE3 char            *sModule_RT_Brachy_Application_Setups;
WHERE3 char            *sModule_RT_Dose;
WHERE3 char            *sModule_RT_Dose_ROI;
WHERE3 char            *sModule_RT_DVH;
WHERE3 char            *sModule_RT_Fraction_Scheme;
WHERE3 char            *sModule_RT_General_Plan;
WHERE3 char            *sModule_RT_Image;
WHERE3 char            *sModule_RT_Patient_Setup;
WHERE3 char            *sModule_RT_Prescription;
WHERE3 char            *sModule_RT_ROI_Observations;
WHERE3 char            *sModule_RT_Series;
WHERE3 char            *sModule_RT_Tolerance_Tables;
WHERE3 char            *sModule_SC_Image;
WHERE3 char            *sModule_SC_Image_Equipment;
WHERE3 char            *sModule_SC_Multi_Frame_Image;
WHERE3 char            *sModule_SC_Multi_Frame_Vector;
WHERE3 char            *sModule_Slice_Coordinates;
WHERE3 char            *sModule_SOP_Common;
WHERE3 char            *sModule_Specimen_Identification;
WHERE3 char            *sModule_Structure_Set;
WHERE3 char            *sModule_Study_Acquisition;
WHERE3 char            *sModule_Study_Classification;
WHERE3 char            *sModule_Study_Component;
WHERE3 char            *sModule_Study_Component_Acquisition;
WHERE3 char            *sModule_Study_Component_Relationship;
WHERE3 char            *sModule_Study_Content;
WHERE3 char            *sModule_Study_Identification;
WHERE3 char            *sModule_Study_Read;
WHERE3 char            *sModule_Study_Relationship;
WHERE3 char            *sModule_Study_Scheduling;
WHERE3 char            *sModule_Therapy;
WHERE3 char	       *sModule_UIN_Overlay_Sequence;
WHERE3 char            *sModule_US_Frame_of_Reference;
WHERE3 char            *sModule_US_Image;
WHERE3 char            *sModule_US_Region_Calibration;
WHERE3 char            *sModule_Visit_Admission;
WHERE3 char            *sModule_Visit_Discharge;
WHERE3 char            *sModule_Visit_Identification;
WHERE3 char            *sModule_Visit_Relationship;
WHERE3 char            *sModule_Visit_Scheduling;
WHERE3 char            *sModule_Visit_Status;
WHERE3 char            *sModule_VL_Image;
WHERE3 char            *sModule_VOI_LUT;
WHERE3 char            *sModule_XRay_Acquisition;
WHERE3 char            *sModule_XRay_Acquisition_Dose;
WHERE3 char            *sModule_XRay_Collimator;
WHERE3 char            *sModule_XRay_Filtration;
WHERE3 char            *sModule_XRay_Generation;
WHERE3 char            *sModule_XRay_Grid;
WHERE3 char            *sModule_XRay_Image;
WHERE3 char            *sModule_XRay_Table;
WHERE3 char            *sModule_XRay_Tomography_Acquisition;
WHERE3 char            *sModule_XRF_Positioner;

/* labels of the elements of all modules */
WHERE3 char            *sLabel_Acquisition_Context [3];
WHERE3 char            *sLabel_Audio [10];
WHERE3 char            *sLabel_BasicAnnotationPresentation [3];
WHERE3 char            *sLabel_BasicFilmBoxPresentation [13];
WHERE3 char            *sLabel_BasicFilmBoxRelationship [4];
WHERE3 char            *sLabel_BasicFilmSessionPresentation [7];
WHERE3 char            *sLabel_BasicFilmSessionRelationship [2];
WHERE3 char            *sLabel_BiPlaneImage [3];
WHERE3 char            *sLabel_BiPlaneOverlay [3];
WHERE3 char            *sLabel_BiPlaneSequence [3];
WHERE3 char            *sLabel_Cine [11];
WHERE3 char            *sLabel_Contrast_Bolus [13];
WHERE3 char            *sLabel_CR_Image [16];
WHERE3 char            *sLabel_CR_Series [8];
WHERE3 char            *sLabel_CT_Image [26];
WHERE3 char            *sLabel_Curve [17];
WHERE3 char            *sLabel_Curve_Identification [7];
WHERE3 char            *sLabel_Device [2];
WHERE3 char	       *sLabel_Directory_Information [5];
WHERE3 char	       *sLabel_Display_Shutter [9];
WHERE3 char	       *sLabel_DX_Anatomy_Imaged [4];
WHERE3 char	       *sLabel_DX_Detector [28];
WHERE3 char	       *sLabel_DX_Image [22];
WHERE3 char	       *sLabel_DX_Positioning [22];
WHERE3 char	       *sLabel_DX_Series [4];
WHERE3 char	       *sLabel_External_Papyrus_File_Reference_Sequence [2];
WHERE3 char	       *sLabel_External_Patient_File_Reference_Sequence [2];
WHERE3 char	       *sLabel_External_Study_File_Reference_Sequence [2];
WHERE3 char	       *sLabel_External_Visit_Reference_Sequence [2];
WHERE3 char	       *sLabel_File_Reference [5];
WHERE3 char	       *sLabel_File_Set_Identification [4];
WHERE3 char            *sLabel_Frame_Of_Reference [3];
WHERE3 char            *sLabel_Frame_Pointers [4];
WHERE3 char            *sLabel_General_Equipment [13];
WHERE3 char            *sLabel_General_Image [15];
WHERE3 char            *sLabel_General_Patient_Summary [7];
WHERE3 char            *sLabel_General_Series [16];
WHERE3 char            *sLabel_General_Series_Summary [5];
WHERE3 char            *sLabel_General_Study [11];
WHERE3 char            *sLabel_General_Study_Summary [7];
WHERE3 char            *sLabel_General_Visit_Summary [4];
WHERE3 char            *sLabel_Icon_Image [16];
WHERE3 char            *sLabel_Identifying_Image_Sequence [2];
WHERE3 char            *sLabel_Image_Box_Pixel_Presentation [8];
WHERE3 char            *sLabel_Image_Box_Relationship [4];
WHERE3 char            *sLabel_Image_Histogram [2];
WHERE3 char            *sLabel_Image_Identification [4];
WHERE3 char            *sLabel_Image_Overlay_Box_Presentation [7];
WHERE3 char            *sLabel_Image_Overlay_Box_Relationship [2];
WHERE3 char            *sLabel_Image_Pixel [20];
WHERE3 char            *sLabel_Image_Plane [6];
WHERE3 char            *sLabel_Image_Pointer [2];
WHERE3 char            *sLabel_Image_Sequence [2];
WHERE3 char            *sLabel_Internal_Image_Pointer_Sequence [2];
WHERE3 char            *sLabel_Interpretation_Approval [5];
WHERE3 char            *sLabel_Interpretation_Identification [3];
WHERE3 char            *sLabel_Interpretation_Recording [5];
WHERE3 char            *sLabel_Interpretation_Relationship [2];
WHERE3 char            *sLabel_Interpretation_State [3];
WHERE3 char            *sLabel_Interpretation_Transcription [6];
WHERE3 char            *sLabel_Intra_Oral_Image [6];
WHERE3 char            *sLabel_Intra_Oral_Series [2];
WHERE3 char            *sLabel_LUT_Identification [3];
WHERE3 char            *sLabel_Mammography_Image [9];
WHERE3 char            *sLabel_Mammography_Series [2];
WHERE3 char            *sLabel_Mask [3];
WHERE3 char            *sLabel_Modality_LUT [5];
WHERE3 char            *sLabel_MR_Image [49];
WHERE3 char            *sLabel_Multi_Frame [3];
WHERE3 char            *sLabel_Multi_frame_Overlay [3];
WHERE3 char            *sLabel_NM_Detector [2];
WHERE3 char            *sLabel_NM_Image [23];
WHERE3 char            *sLabel_NM_Image_Pixel [7];
WHERE3 char            *sLabel_NM_Isotope [4];
WHERE3 char            *sLabel_NM_Multi_Frame [18];
WHERE3 char            *sLabel_NM_Multi_gated_Acquisition_Image [6];
WHERE3 char            *sLabel_NM_Phase [2];
WHERE3 char            *sLabel_NM_Reconstruction [6];
WHERE3 char            *sLabel_NM_Series [3];
WHERE3 char            *sLabel_NM_Tomo_Acquisition [3];
WHERE3 char            *sLabel_Overlay_Identification [5];
WHERE3 char            *sLabel_Overlay_Plane [22];
WHERE3 char            *sLabel_Palette_Color_Lookup [11];
WHERE3 char            *sLabel_Patient [11];
WHERE3 char            *sLabel_Patient_Demographic [16];
WHERE3 char            *sLabel_Patient_Identification [9];
WHERE3 char            *sLabel_Patient_Medical [9];
WHERE3 char            *sLabel_Patient_Relationship [4];
WHERE3 char            *sLabel_Patient_Study [7];
WHERE3 char            *sLabel_Patient_Summary [3];
WHERE3 char            *sLabel_Pixel_Offset [2];
WHERE3 char            *sLabel_Printer [10];
WHERE3 char            *sLabel_Print_Job [8];
WHERE3 char            *sLabel_Result_Identification [3];
WHERE3 char            *sLabel_Results_Impression [3];
WHERE3 char            *sLabel_Result_Relationship [3];
WHERE3 char            *sLabel_SC_Image [3];
WHERE3 char            *sLabel_SC_Image_Equipment [9];
WHERE3 char            *sLabel_SOP_Common [7];
WHERE3 char	       *sLabel_Specimen_Identification [3];
WHERE3 char            *sLabel_Study_Acquisition [11];
WHERE3 char            *sLabel_Study_Classification [4];
WHERE3 char            *sLabel_Study_Component [4];
WHERE3 char            *sLabel_Study_Component_Acquisition [6];
WHERE3 char            *sLabel_Study_Component_Relationship [2];
WHERE3 char            *sLabel_Study_Content [4];
WHERE3 char            *sLabel_Study_Identification [4];
WHERE3 char            *sLabel_Study_Read [4];
WHERE3 char            *sLabel_Study_Relationship [7];
WHERE3 char            *sLabel_Study_Scheduling [13];
WHERE3 char            *sLabel_Therapy [2];
WHERE3 char	       *sLabel_UIN_Overlay_Sequence [3];
WHERE3 char            *sLabel_US_Frame_of_Reference [13];
WHERE3 char            *sLabel_US_Image [47];
WHERE3 char            *sLabel_US_Region_Calibration [2];
WHERE3 char            *sLabel_Visit_Admission [9];
WHERE3 char            *sLabel_Visit_Discharge [5];
WHERE3 char            *sLabel_Visit_Identification [6];
WHERE3 char            *sLabel_Visit_Relationship [3];
WHERE3 char            *sLabel_Visit_Scheduling [6];
WHERE3 char            *sLabel_Visit_Status [5];
WHERE3 char            *sLabel_VOI_LUT [5];
WHERE3 char            *sLabel_XRay_Acquisition [16];
WHERE3 char            *sLabel_XRay_Acquisition_Dose [22];
WHERE3 char            *sLabel_XRay_Collimator [9];
WHERE3 char            *sLabel_XRay_Filtration [5];
WHERE3 char            *sLabel_XRay_Generation [13];
WHERE3 char            *sLabel_XRay_Grid [9];
WHERE3 char            *sLabel_XRay_Image [19];
WHERE3 char            *sLabel_XRay_Table [6];
WHERE3 char            *sLabel_XRay_Tomography_Acquisition [7];

#endif	    /* PapyGlobalVar3H */

