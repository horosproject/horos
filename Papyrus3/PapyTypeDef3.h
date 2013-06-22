/********************************************************************************/
/*		                                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyTypeDef3.h                                               */
/*	Function : contains the declarations of the constants, the enumerated	*/
/*		   types, the structures and the type definition for the  	*/
/*		   PAPYRUS toolkit.                                             */
/********************************************************************************/

#ifndef PapyTypeDef3H
#define PapyTypeDef3H

#include <stdio.h>

/* BEWARE : Mac must be defined only if we are on a Mac architecture. */

#ifndef unix
#ifndef hpux
#ifndef __alpha
#ifndef _WINDOWS
#ifndef Mac
#define Mac
#endif
#endif
#endif
#endif
#endif

#ifdef  DLL
#ifdef  WIN32
#define EXPORT
#define EXPORT32 __declspec (dllexport )
#define CALLINGCONV 
#else 	/* WIN32 not defined */
#define EXPORT _export _far _pascal
#define EXPORT32 
#define CALLINGCONV _far _pascal
#endif	/* WIN32 */
#else	/* DLL not defined */
#define EXPORT
#define EXPORT32 
#define CALLINGCONV
#endif	/* DLL */




/* --- constants needed by the file managers --- */


#ifndef SEEK_END
#define SEEK_END    2
#endif
#ifndef SEEK_CUR
#define SEEK_CUR    1
#endif
#ifndef SEEK_SET
#define SEEK_SET    0
#endif

#ifdef unix
#define NULLFILE    NULL
#else
#define NULLFILE    -1
#endif



/* --- boolean definitions --- */

#ifndef TRUE
#define TRUE	    1
#endif
#ifndef FALSE
#define FALSE	    0
#endif


/* --- Constant definitions --- */

#ifndef _WINDOWS
#define kMax_file_open	300
#else
#define kMax_file_open	20	/* Limitation on the PCs to 20 open files... */
#endif

#define kMax_tmp_file	10000
#define kLength_length	12
#define kMax_overlay	0x601E	  /* overlay groups are from 0x6000 to 0x601E (even) */
#define kMax_UIN_overlay  0x6FFF  /* UINOverlays are from 0x6001 to 0x6FFF (odd) */



/* --- basic types definitions --- */
/* will ensure cross-plateform interoperability */

typedef unsigned char   PapyUChar;		/* 8  bits unsigned char */	
typedef char            PapyChar;		/* 8  bits signed char */
typedef	short		PapyShort;		/* 16 bits short int */
typedef unsigned short	PapyUShort;		/* 16 bits unsigned short int */

#ifdef __alpha
typedef	int		PapyLong;		/* 32 bits long  int */
typedef	unsigned int	PapyULong;		/* 32 bits unsigned long  int */
#else
typedef	int		PapyLong;		/* 32 bits long  int */
typedef	unsigned int	PapyULong;		/* 32 bits unsigned long  int */
#endif

typedef float		PapyFloat;		/* 32 bits float */
typedef double		PapyFloatDouble;	/* 64 bits float double */

#ifdef Mac
typedef FILE *          PAPY_FILE; 	     	/* the pointer to a PAPYRUS file */
#else
#ifdef _WINDOWS
typedef int            	PAPY_FILE;           	/* Windows file handle */
#else  /* unix */
typedef FILE *      	PAPY_FILE;    		/* ANSI FILE pointer */
#endif /* _WINDOWS */
#endif /* Mac */


/* --- Enumerated types --- */

/* Definition of the DICOM transfer syntaxes */
enum ETransf_Syntax	{LITTLE_ENDIAN_IMPL, LITTLE_ENDIAN_EXPL, BIG_ENDIAN_EXPL};

/* The type of the file */
enum EFile_Type		{DICOM10, PAPYRUS3, DICOM_NOT10, DICOMDIR, PAPYRUS2, other};

/* Definition of the different compression used */
enum EPap_Compression	{NONE, JPEG_LOSSLESS, JPEG_LOSSY, RLE, MAYO_WAVELET, JPEG2000, MPEG2MPML, JPEGLSLossLess, JPEGLSLossy};

/* Definition of the photometric interpretation */
enum EPhoto_Interpret	{MONOCHROME1, MONOCHROME2, PALETTE, RGB, HSV, ARGB, CMYK, 
			 YBR_FULL, YBR_FULL_422, YBR_PARTIAL_422, YBR_RCT, YBR_ICT, YUV_RCT, UNKNOWN_COLOR}; 

enum EDataSet_Image 	{DataSetID, ImageID};

/* enumeration of the different imaging modalities */
enum EModality		{CR_IM, CT_IM, MR_IM, NM_IM, US_IM, US_MF_IM, SEC_CAPT_IM, 
                         DX_IM, MG_IM, IO_IM, PX_IM, RF_IM, PET_IM, VLE_IM, VLM_IM,
                         VLS_IM, VLP_IM, MFSBSC_IM, MFGBSC_IM, MFGWSC_IM, MFTCSC_IM, 
                         END_MODALITY};

/* is the module mandatory, conditional or user optional for a given modality ? */
enum EUsage		{M, C, U};

/* the different value representation defined in DICOM */
enum EV_R_T 		{AE, AS, AT, CS, DA, DS, DT, FL, FD, IS, LO, LT, OB, OW, 
			 PN, SH, SL, SQ, SS, ST, TM, UI, UL, UN, USS, UT, RET};

/* the DICOM defined types for the elements */
enum EType_T 		{T1, T1C, T2, T2C, T3};

/* what kind of Object is it ? */
enum EKind_Obj		{papItem, papModule, papGroup, papTmpFile, papRecord};

/* enum needed by UINOverlays */
enum E_ROI 		{RECTANGLE, ANNOTATION, GRAPHIC};
enum E_Font 		{TIMES, HELVETICA};
enum E_Style		{NORMAL, BOLD, ITALIC, BOLDITALIC};
enum E_Color 		{WHITE, BLACK, RED, GREEN, BLUE, CYAN, MAGENTA, YELLOW};

/* Not used in the toolkit:
enum E_Editable		{EDIT, FIXED};
enum E_Opacity 		{NONE, OPAQUE, TRANSPARENT};
enum E_Shape 		{MASK, RECT, ELLIPSE, POLY}; 	was FOR
*/



/* --- Structures and type definitions --- */

struct SPapy_List_;

typedef union UValue_T_	
{
    PapyShort		ss;	/* SS */
    PapyUShort		us;	/* US, AT */
    PapyUShort *	ow;	/* OW */
    PapyLong		sl;	/* SL */
    PapyULong		ul;	/* UL */
    PapyFloat		fl;	/* FL */
    PapyFloatDouble	fd;	/* FD */
    char *		a;	/* AE, AS, CS, DA, DS, DT, IS, LO, LT, OB, PN, SH, ST, TM, UI, UN, UT */
    struct SPapy_List_ *sq;	/* SQ */
} UValue_T;

typedef struct SElement_	/* structure of an element */
{
    PapyUShort		group;
    PapyUShort		element;
    PapyULong		length;
    enum EV_R_T		vr;	/* Value Representation */
    const char 		*vm;	/* Value Multiplicity */
    enum EType_T	type_t;	/* EType_T (mandatory, cond., optional) */
    PapyULong		nb_val;
    UValue_T		*value;
} SElement;


typedef struct SGroup_		/* assigns a number for each group */
{
    PapyUShort	 	number;
    PapyULong	 	size;
} SGroup;


typedef struct SShadowOwner_ 	/* keep the allowed elements of the shadow-groups */
{
    char		*str_value;
} SShadowOwner;


typedef struct SImageList_	/* keeps references to images */
{
    PapyShort 		file;	/* the reference to the file */
    PapyShort 		image;	/* the number of the image */
} SImageList;



/* --- types specific to PAPYRUS 3 --- */

typedef SElement pModule;		/* the pModule is defined the same way as an SElement */

typedef SElement Record;		/* the Record is defined the same way as an SElement */

typedef struct SObject_			/* the Object can be either a ... */
{
    enum EKind_Obj	whoAmI;		/* what kind of object is it ? */
    int			objID;		/* only way to identify a group or a module */
    struct SPapy_List_	*item;
    pModule		*module;
    SElement		*group;
    Record		*record;
    PapyULong		tmpFileLength;	/* the length of the temporary file */
    void		*file;		/* will store tmp file */
} papObject;

struct SPapy_List_
{
  papObject		*object;
  struct SPapy_List_	*next;
};

typedef struct SPapy_List_	Papy_List;

typedef Papy_List 		Item;

typedef Papy_List 		Sequence;

typedef	struct SData_Set_
{
  int 		moduleName;
  int		usage;		 /*enum EUsage	usage;*/
} Data_Set;


#endif /* PapyTypeDef3H */

