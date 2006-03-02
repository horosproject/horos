/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit (Dicomdir library)			*/
/*	File     : DicomdirPubFunctionDef3.h					*/
/*	Function : contains the declarations of the public functions 		*/
/*	Authors  : Christian Girard						*/
/*		   Marianne Logean					        */
/*								   		*/
/*	History  : 02.1999	version 3.6					*/
/*								   		*/
/* 	(C) 1999 The University Hospital of Geneva				*/
/*	All Rights Reserved							*/
/*										*/
/********************************************************************************/


#ifndef DicomdirPubFunctionDef3H 
#define DicomdirPubFunctionDef3H





/* --- functions definitions --- */



/* --- DicomDirDataSetRead3 --- */

extern EXPORT32 Record*	EXPORT 
Papy3GetRecord		(PapyShort, int);



/* --- DicomDirDataSetWrite3 --- */

extern EXPORT32 Item*     EXPORT
Papy3CreateDicomDirDataSet (PapyShort);

extern EXPORT32 Item*     EXPORT
Papy3CreateDirRecItem (pModule*);

extern EXPORT32 void 	  EXPORT
Papy3LinkRecordToDS (Item *, SElement *, int);

extern EXPORT32 Record*	  EXPORT 
Papy3CreateRecord	(int);



/* --- DicomDirFiles --- */

extern EXPORT32 PapyShort EXPORT 
Papy3DicomDirCreate	(char *, int, PAPY_FILE, int, void*);

extern EXPORT32 PapyShort EXPORT 
Papy3WriteAndCloseDicomDir (PapyShort, int);



/* --- DicomDirInit --- */

extern EXPORT32 PapyShort EXPORT 
DicD3Init 		();

extern EXPORT32 PapyShort EXPORT 
Papy3RecordFree 	(SElement **, int, int);



#endif	    /* DicomdirPubFunctionDef3H */

