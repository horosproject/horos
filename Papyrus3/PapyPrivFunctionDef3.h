/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyPrivFunctionDef3.h                                       */
/*	Function : contains the declarations of the private functions           */
/*	Authors  : Christian Girard                                             */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 01.1999	version 3.6                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                 10.2001      version 3.71 MAJ Dicom par CHG                  */
/*                                                                              */
/* 	(C) 1999-2001 The University Hospital of Geneva                         */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/

#ifndef PapyPrivFunctionDef3H 
#define PapyPrivFunctionDef3H



/* --- functions definitions --- */



/* --- PapyDataSetRead3 --- */

PapyShort 
ExtractFileMetaInformation3 	(PapyShort);

PapyShort 
ExtractPapyDataSetInformation3  (PapyShort);

PapyShort 
ExtractDicomDataSetInformation3 (PapyShort);

PapyShort 
ExtractGroup28Information 	(PapyShort);


/* --- PapyDataSetWrite3 --- */

void 
LookForGroupsInModule3 		(pModule *, int, int *, int *);

PapyShort
ItemModulesToGroups3 		(PapyShort, Item *, int);

PapyShort
ItemRecordsToGroups3            (PapyShort, Item *, int);

int 
Papy3GetRecordType 		(SElement *);

PapyShort 
CreateFileMetaInformation3 	(PapyShort, enum EPap_Compression, enum ETransf_Syntax, 
				 enum EModality);

void 
KeepReferences3                 (PapyShort, int, int, UValue_T *);

PapyShort 
SequencesToGroups3              (PapyShort, Item *, int);

PapyShort
CreateTmpFile3                  (PapyShort, PAPY_FILE *, void **);

PapyShort
WriteDicomHeader3               (PAPY_FILE, PapyShort, PapyULong *);


/* --- PapyFiles3 --- */

PapyULong 
ComputeUndefinedGroupLength3    (PapyShort, PapyLong);

PapyShort 
ComputeUndefinedSequenceLength3	(PapyShort, PapyULong *);

PapyShort 
ComputeUndefinedItemLength3	(PapyShort, PapyULong *);

PapyShort 
ReadGroup3 			(PapyShort, PapyUShort *, unsigned char **,
			      	 PapyULong *, PapyULong *);		  

PapyShort 
WriteGroup3 			(PAPY_FILE fp, unsigned char *, PapyULong);



/* --- PapyInit3 --- */

void 
InitGroup3 	 	(int, SElement *);

void 
InitModule3 	 	(int, SElement *);

void 
InitGroupNbAndSize3 	();

void 
InitModuleSize3 	();

void 
InitDataSetModules3 	();

void 
InitUIDs3 		();

void 
InitModulesLabels3  	();

pModule*
CreateModule3	        (int);

PapyShort 
Papy3FreeSQElement 	(SElement **, pModule *, int);


/* --- PapyRead3 --- */

PapyShort
PutBufferInGroup3 	(PapyShort, unsigned char *, SElement *, PapyUShort, PapyULong, 
		   	 PapyULong *, PapyLong);

PapyUShort
Extract2Bytes 	  	(unsigned char *, PapyULong *, long syntax);

extern PapyULong  
Extract4Bytes     	(unsigned char *, PapyULong *, long syntax);



/* --- PapyWrite3 --- */

PapyShort 
ComputeGroupLength3  	(PapyShort, SElement *, PapyULong *, enum ETransf_Syntax);

PapyULong 
ComputeSequenceLength3	(Item *, enum ETransf_Syntax);

void
Put4Bytes		(PapyULong, unsigned char *, PapyULong *);

PapyShort 
PutGroupInBuffer 	(PapyShort, PapyShort, int , SElement *, 
			 unsigned char *, PapyULong *, int);



#endif	    /* PapyPrivFunctionDef3H */

