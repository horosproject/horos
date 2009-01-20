/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyPrivFunctionDef3.h                                       */
/*	Function : contains the declarations of the private functions           */
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

/********************************************************************************/
/*										*/
/*	Extract2Bytes : extract a 2-Bytes value (USS, SS or AT) from the buf and*/
/*	increment pos accordingly.						*/
/* 	return : the extracted value						*/
/*										*/
/********************************************************************************/
static __inline__ __attribute__((always_inline)) PapyUShort Extract2Bytes (PapyShort inFileNb, unsigned char *inBufP, PapyULong *ioPosP)
/*unsigned char *inBufP;				 the buffer to read from */
/*PapyULong 	*ioPosP;			      the position in the buffer */
{
	PapyUShort theUShort;
	unsigned char *theCharP;
	
	/* points to the right place in the buffer */
	theCharP  = inBufP;
	theCharP += *ioPosP;
	/* updates the current position in the read buffer */
	*ioPosP += 2;
	
	/* extract the element according to the little-endian syntax */
#if __BIG_ENDIAN__
	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
	{
		theUShort  = (PapyUShort) (*(theCharP + 1));
		theUShort  = theUShort << 8;
		theUShort |= (PapyUShort) *theCharP;
	}
	else
	{
		theUShort	= *((PapyUShort*) theCharP);
	}
#else
	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
	{
		theUShort = *((PapyUShort*) theCharP);
	}
	else
	{
		theUShort  = (PapyUShort) (*(theCharP + 1));
		theUShort  = theUShort << 8;
		theUShort |= (PapyUShort) *theCharP;
	}
#endif
	
	return theUShort;
	
} /* endof Extract2Bytes */



/********************************************************************************/
/*										*/
/*	Extract4Bytes : extract a 4-Bytes value (UL, SL or FL) of the buf and 	*/
/*	increment pos accordingly.						*/
/* 	return : the extracted value					 	*/
/*										*/
/********************************************************************************/
static __inline__ __attribute__((always_inline)) PapyULong Extract4Bytes (PapyShort inFileNb, unsigned char *inBufP, PapyULong *ioPosP)
{
	unsigned char *theCharP;
	PapyULong theULong;
    
	/* points to the right place in the buffer */
	theCharP  = inBufP;
	theCharP += *ioPosP;
	/* updates the current position in the read buffer */
	*ioPosP += 4;
	
		/* extract the element according to the little-endian syntax */
	#if __BIG_ENDIAN__
	if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL)
	{
		PapyULong theTmpULong;
		theULong = 0L;
		theTmpULong  = (PapyULong) (*(theCharP + 3));
		theTmpULong  = theTmpULong << 24;
		theULong    |= theTmpULong;
		theTmpULong  = (PapyULong) (*(theCharP + 2));
		theTmpULong  = theTmpULong << 16;
		theULong    |= theTmpULong;
		theTmpULong  = (PapyULong) (*(theCharP + 1));
		theTmpULong  = theTmpULong << 8;
		theULong    |= theTmpULong;
		theTmpULong  = (PapyULong) *theCharP;
		theULong    |= theTmpULong;
	}
	else
	{
		theULong	= *((PapyULong*) theCharP);
	}
	#else
	if (gArrTransfSyntax [inFileNb] == LITTLE_ENDIAN_EXPL)
	{
		theULong	= *((PapyULong*) theCharP);
	}
	else
	{
		PapyULong theTmpULong;
		theULong = 0L;
		theTmpULong  = (PapyULong) (*(theCharP + 3));
		theTmpULong  = theTmpULong << 24;
		theULong    |= theTmpULong;
		theTmpULong  = (PapyULong) (*(theCharP + 2));
		theTmpULong  = theTmpULong << 16;
		theULong    |= theTmpULong;
		theTmpULong  = (PapyULong) (*(theCharP + 1));
		theTmpULong  = theTmpULong << 8;
		theULong    |= theTmpULong;
		theTmpULong  = (PapyULong) *theCharP;
		theULong    |= theTmpULong;
	}
	#endif
	
	return theULong;
    
} /* endof Extract4Bytes */


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

