/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyPubFunctionDef3.h                                        */
/*	Function : contains the declarations of the public functions            */
/********************************************************************************/


#ifndef PapyPubFunctionDef3H 
#define PapyPubFunctionDef3H



/* --- functions definitions --- */



/* --- PapyDataSetRead3 --- */

extern EXPORT32 pModule*	EXPORT 
Papy3GetModule		(PapyShort, PapyShort, int);



/* --- PapyDataSetWrite3 --- */

extern EXPORT32 SElement* EXPORT 
Papy3GetGroup2		(PapyShort);

extern EXPORT32 Item* 	  EXPORT 
Papy3CreateDataSet	(PapyShort);

extern EXPORT32 PapyShort EXPORT	
Papy3InsertItemToSequence (pModule *, int, enum EKind_Obj, void *, int);

extern EXPORT32 void	  EXPORT 
Papy3LinkModuleToDS 	(Item *, pModule  *, int);

extern EXPORT32 void      EXPORT 
Papy3LinkGroupToDS 	(Item *, SElement *, int);

extern EXPORT32 pModule*	  EXPORT 
Papy3CreateModule	(Item *, int);

extern EXPORT32 pModule*	  EXPORT 
Papy3FindModule		(Item *, int);

extern EXPORT32 PapyShort EXPORT 
Papy3CloseDataSet	(PapyShort, Item *, int, int);



/* --- PapyFiles3 --- */

extern EXPORT32 PapyShort EXPORT 
FindFreeFile3	();

extern EXPORT32 PapyShort EXPORT 
Papy3FileOpen 		(char *, PAPY_FILE, int, void* );

extern EXPORT32 PapyShort EXPORT 
Papy3FileCreate 	(char *, PAPY_FILE, PapyUShort, enum ETransf_Syntax, 
                         enum EPap_Compression, enum EModality, int, int, void*);

extern EXPORT32 PapyShort EXPORT 
Papy3FileClose 		(PapyShort, int);

extern EXPORT32 PapyShort EXPORT 
Papy3WriteAndCloseFile	(PapyShort, int);

extern EXPORT32 PapyShort EXPORT 
Papy3GetNextGroupNb 	(PapyShort);

extern EXPORT32 PapyShort EXPORT 
Papy3SkipNextGroup  	(PapyShort);

extern EXPORT32 PapyShort EXPORT 
Papy3GotoGroupNb    	(PapyShort, PapyShort);

extern EXPORT32 PapyShort EXPORT 
Papy3GotoGroupNb0x7FE0  (PapyShort, SElement **);

extern EXPORT32 PapyUShort EXPORT 
Papy3FindOwnerRange   	(PapyShort, PapyUShort, char *);

extern EXPORT32 PapyShort EXPORT 
Papy3GotoElemNb		(PapyShort, PapyUShort, PapyUShort, PapyULong *);

extern EXPORT32 PapyULong EXPORT 
Papy3ExtractItemLength	(PapyShort);


/* --- PapyConvertFiles3 --- */


extern EXPORT32 int       EXPORT 
Papyrus2Papyrus         (char *, char *, PAPY_FILE, int, int *);
  
extern EXPORT32 int       EXPORT 
Papyrus2Dicom           (char *, char *, PAPY_FILE, int, int *);
  
extern EXPORT32 int       EXPORT 
Dicom2Papyrus           (char *, int, char **, int, enum EModality);

extern EXPORT32 int       EXPORT
GetPapyFileType         (char *, int *, int *, enum EModality *);

extern EXPORT32 int       EXPORT
Papyrus2Jpeg            (char *, char *, short, int *, int, int, enum EPap_Compression, int);

/*extern EXPORT32 int       EXPORT
OldPapyrus2Jpeg         (char *, char *, short, int, int *, int, int);*/



/* --- PapyInit3 --- */

extern EXPORT32 PapyShort EXPORT 
Papy3AddOwner 		(PapyShort, char *);

extern EXPORT32 PapyShort EXPORT 
Papy3Init 		();

extern EXPORT32 PapyShort EXPORT 
Dicom2PapyInit          ();

extern EXPORT32 enum EModality EXPORT 
SetModality             (char *);

extern EXPORT32 void      EXPORT 
SetCompression          (enum EPap_Compression);

extern EXPORT32 void      EXPORT 
SetCompressionFactor    (int);

extern EXPORT32 void      EXPORT 
SetZoomFactor           (float);

extern EXPORT32 void      EXPORT 
SetWindowingValue       (int, int);

extern EXPORT32 void      EXPORT 
SetSubSamplingFactor    (float);

extern EXPORT32 void      EXPORT 
SetCropingPoints        (float, float, float, float);

extern EXPORT32 SElement* EXPORT 
Papy3GroupCreate 	(int);

extern EXPORT32 PapyShort EXPORT 
Papy3ClearElement 	(SElement *, PapyShort, int);

extern EXPORT32 PapyShort EXPORT 
Papy3GroupFree 		(SElement **, int);

extern EXPORT32 PapyShort EXPORT 
Papy3ModuleFree 	(SElement **, int, int);

extern EXPORT32 PapyShort EXPORT 
Papy3ImageFree 		(SElement *);



/* --- functions of the list handler (PapyList3) --- */

extern Papy_List*       InsertFirstInList	(Papy_List **, papObject *);
extern Papy_List*       InsertLastInList	(Papy_List **, papObject *);
extern Papy_List*       InsertInListAt		(Papy_List **, papObject *, PapyShort);
extern Papy_List*       InsertGroupInList	(Papy_List **, papObject *);
extern PapyShort        DeleteFirstInList	(PapyShort, Papy_List **, int, int, int);
extern PapyShort        DeleteLastInList	(PapyShort, Papy_List **, int, int, int);
extern PapyShort        DeleteList		(PapyShort, Papy_List **, int, int, int);



/* --- PapyRead3 --- */

extern EXPORT32 UValue_T*  EXPORT 
Papy3GetElement		(SElement*, int, PapyULong *, int *);

extern EXPORT32 PapyUShort* EXPORT 
Papy3GetPixelData (PapyShort , int , SElement *, int , long *);

extern EXPORT32 PapyShort EXPORT 
Papy3GroupRead 		(PapyShort, SElement **);

extern EXPORT32 PapyShort EXPORT
Papy3GroupReadNb    (PapyShort, SElement **, int);

/* --- PapyUtils3 --- */

extern EXPORT32 void	  EXPORT 
Papy3SetIconSize	(PapyUShort);

extern EXPORT32 PapyUShort EXPORT 
Papy3GetIconSize	();

extern char *		
PapyStrDup		(char *);

extern EXPORT32 PapyShort EXPORT 
Papy3GotoUID 		(PapyShort, char *, enum EDataSet_Image);

extern EXPORT32 PapyShort EXPORT 
Papy3GotoNumber 	(PapyShort, PapyShort, enum EDataSet_Image);

extern EXPORT32 PapyShort EXPORT 
Papy3CheckValidOwnerId 	(PapyShort, unsigned char *, PapyULong *, PapyUShort, PapyULong, SElement *);

extern EXPORT32 int	  EXPORT 
Papy3ToEnumGroup 	(PapyUShort);

extern EXPORT32 PapyUShort EXPORT 
Papy3EnumToElemNb	(SElement *, int);

extern EXPORT32 PapyShort EXPORT 
Papy3ElemTagToEnumNb	(PapyUShort, PapyUShort, int *, int *);

extern EXPORT32 void      
ExtractDicomdirFromPath (char *, char *);

extern EXPORT32 void      
ExtractModality 	(UValue_T *val, PapyShort fileNb);

extern EXPORT32 void      EXPORT 
Pap2ToPap3Date          (char *, char *);

extern EXPORT32 void      EXPORT 
Pap2ToPap3Time          (char *, char *);

extern EXPORT32 void      EXPORT 
Pap2ToPap3Name          (char *, char *);

extern EXPORT32 PapyUChar *      EXPORT 
ConvertYbrToRgb          (PapyUChar *, int, int, enum EPhoto_Interpret, char);


/* --- PapyWrite3 --- */

extern EXPORT32 PapyShort EXPORT 
Papy3PutElement		(SElement *, int, void *);

extern EXPORT32 PapyShort EXPORT 
Papy3PutIcon 		(PapyShort, PapyShort, PapyUChar *);

extern EXPORT32 PapyShort EXPORT 
Papy3PutImage 		(PapyShort, SElement *, int, PapyUShort *, PapyUShort, PapyUShort, 
			 PapyUShort, PapyULong);

extern EXPORT32 PapyShort EXPORT 
Papy3PutUnknown		(SElement *, int, PapyChar *, PapyULong);

extern EXPORT32 PapyShort EXPORT 
Papy3GroupWrite		(PapyShort, SElement *, int);

extern EXPORT32 PapyShort EXPORT
JPEGLossyEncodeImage    (PapyShort, int , PapyUChar *, PapyUChar *, PapyUChar **, PapyULong *,int , int , int , int);



/* --- PapyError3 --- */

extern EXPORT32 void	 EXPORT 
PAPY3PRINTERRMSG 	();



/* functions for getting global vars (PapyGetGlobalVar3) */

extern EXPORT32 PAPY_FILE EXPORT 	  
Papy3GetFile		(PapyShort);

extern EXPORT32 int	  EXPORT 	  
Papy3GetCurrTmpFilename(PapyShort);

extern EXPORT32 PapyShort EXPORT 	  
Papy3GetNbImages	(PapyShort);

extern EXPORT32 enum ETransf_Syntax EXPORT 
Papy3GetTransfSyntax	(PapyShort);

extern EXPORT32 int 	  EXPORT 	  
Papy3GetModality	(PapyShort);
extern EXPORT32 PapyShort EXPORT	  
Papy3GetNbElemInModule  (int);

extern EXPORT32 int	  EXPORT	  
Papy3GetFileKind	(int);

extern EXPORT32 char*     EXPORT	  
Papy3GetToolkitVersion  ();

extern EXPORT32 enum EPap_Compression EXPORT 
Papy3GetCompression     (PapyShort);



#endif	    /* PapyPubFunctionDef3H */

