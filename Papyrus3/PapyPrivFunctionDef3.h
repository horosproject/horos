/********************************************************************************/
/*			                                                        */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyPrivFunctionDef3.h                                       */
/*	Function : contains the declarations of the private functions           */
/********************************************************************************/

#ifndef PapyPrivFunctionDef3H 
#define PapyPrivFunctionDef3H

/* --- functions definitions --- */

#include <libkern/OSByteOrder.h>

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
ComputeUndefinedGroupLength3    (PapyShort, PapyULong);

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


static __inline__ __attribute__((always_inline)) unsigned long long UInt64ToHost (PapyShort inFileNb, unsigned char *inBufP)
{
	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
		return OSSwapLittleToHostInt64( *((unsigned long long*) inBufP));
	else
		return OSSwapBigToHostInt64( *((unsigned long long*) inBufP));
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static __inline__ __attribute__((always_inline)) PapyULong UInt32ToHost (PapyShort inFileNb, unsigned char *inBufP)
{
	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
		return OSSwapLittleToHostInt32( *((PapyULong*) inBufP));
	else
		return OSSwapBigToHostInt32( *((PapyULong*) inBufP));
	
//	PapyULong theULong;
	
//	#if __BIG_ENDIAN__
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
//	{
//		PapyULong theTmpULong;
//		theULong = 0L;
//		theTmpULong  = (PapyULong) (*(inBufP + 3));
//		theTmpULong  = theTmpULong << 24;
//		theULong    |= theTmpULong;
//		theTmpULong  = (PapyULong) (*(inBufP + 2));
//		theTmpULong  = theTmpULong << 16;
//		theULong    |= theTmpULong;
//		theTmpULong  = (PapyULong) (*(inBufP + 1));
//		theTmpULong  = theTmpULong << 8;
//		theULong    |= theTmpULong;
//		theTmpULong  = (PapyULong) *inBufP;
//		theULong    |= theTmpULong;
//	}
//	else
//	{
//		theULong	= *((PapyULong*) inBufP);
//	}
//	#else
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
//	{
//		theULong	= *((PapyULong*) inBufP);
//	}
//	else
//	{
//		PapyULong theTmpULong;
//		theULong = 0L;
//		theTmpULong  = (PapyULong) *inBufP;
//		theTmpULong  = theTmpULong << 24;
//		theULong    |= theTmpULong;
//		theTmpULong  = (PapyULong) (*(inBufP + 1));
//		theTmpULong  = theTmpULong << 16;
//		theULong    |= theTmpULong;
//		theTmpULong  = (PapyULong) (*(inBufP + 2));
//		theTmpULong  = theTmpULong << 8;
//		theULong    |= theTmpULong;
//		theTmpULong  = (PapyULong) (*(inBufP + 3));
//		theULong    |= theTmpULong;
//	}
//	#endif
	
//	return theULong;
}

static __inline__ __attribute__((always_inline)) PapyLong Int32ToHost (PapyShort inFileNb, unsigned char *inBufP)
{
	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
		return OSSwapLittleToHostInt32( *((PapyLong*) inBufP));
	else
		return OSSwapBigToHostInt32( *((PapyLong*) inBufP));
	
//	PapyLong theLong;
//	
//	#if __BIG_ENDIAN__
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
//	{
//		PapyLong theTmpLong;
//		theLong = 0L;
//		theTmpLong  = (PapyLong) (*(inBufP + 3));
//		theTmpLong  = theTmpLong << 24;
//		theLong    |= theTmpLong;
//		theTmpLong  = (PapyLong) (*(inBufP + 2));
//		theTmpLong  = theTmpLong << 16;
//		theLong    |= theTmpLong;
//		theTmpLong  = (PapyLong) (*(inBufP + 1));
//		theTmpLong  = theTmpLong << 8;
//		theLong    |= theTmpLong;
//		theTmpLong  = (PapyLong) *inBufP;
//		theLong    |= theTmpLong;
//	}
//	else
//	{
//		theLong	= *((PapyLong*) inBufP);
//	}
//	#else
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
//	{
//		theLong	= *((PapyLong*) inBufP);
//	}
//	else
//	{
//		PapyLong theTmpLong;
//		theLong = 0L;
//		theTmpLong  = (PapyLong) *inBufP;
//		theTmpLong  = theTmpLong << 24;
//		theLong    |= theTmpLong;
//		theTmpLong  = (PapyLong) (*(inBufP + 1));
//		theTmpLong  = theTmpLong << 16;
//		theLong    |= theTmpLong;
//		theTmpLong  = (PapyLong) (*(inBufP + 2));
//		theTmpLong  = theTmpLong << 8;
//		theLong    |= theTmpLong;
//		theTmpLong  = (PapyLong) (*(inBufP + 3));
//		theLong    |= theTmpLong;
//	}
//	#endif	
//	return theLong;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static __inline__ __attribute__((always_inline)) PapyUShort UIntToHost (PapyShort inFileNb, unsigned char *inBufP)
{

	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
		return OSSwapLittleToHostInt16( *((PapyUShort*) inBufP));
	else
		return OSSwapBigToHostInt16( *((PapyUShort*) inBufP));

//	PapyULong theUShort;
//	
//#if __BIG_ENDIAN__
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
//	{
//		theUShort  = (PapyUShort) (*(inBufP + 1));
//		theUShort  = theUShort << 8;
//		theUShort |= (PapyUShort) *inBufP;
//	}
//	else
//	{
//		theUShort	= *((PapyUShort*) inBufP);
//	}
//#else
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)	// NSLi
//	{
//		theUShort = *((PapyUShort*) inBufP);
//	}
//	else
//	{
//		theUShort  = (PapyUShort) *inBufP;
//		theUShort  = theUShort << 8;
//		theUShort |= (PapyUShort) (*(inBufP + 1)); 
//	}
//#endif
//	
//	return theUShort;
}

static __inline__ __attribute__((always_inline)) PapyShort IntToHost (PapyShort inFileNb, unsigned char *inBufP)
{
	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
		return OSSwapLittleToHostInt16( *((PapyShort*) inBufP));
	else
		return OSSwapBigToHostInt16( *((PapyShort*) inBufP));
		
//	PapyShort theShort;
//	
//#if __BIG_ENDIAN__
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)
//	{
//		theShort  = (PapyShort) (*(inBufP + 1));
//		theShort  = theShort << 8;
//		theShort |= (PapyShort) *inBufP;
//	}
//	else
//	{
//		theShort	= *((PapyShort*) inBufP);
//	}
//#else
//	if (gArrTransfSyntax [inFileNb] != BIG_ENDIAN_EXPL)	// NSLi
//	{
//		theShort = *((PapyShort*) inBufP);
//	}
//	else
//	{
//		theShort  = (PapyShort) *inBufP;
//		theShort  = theShort << 8;
//		theShort |= (PapyShort) (*(inBufP + 1)); 
//	}
//#endif
//	
//	return theShort;
}

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
	unsigned char *theCharP;
	
	/* points to the right place in the buffer */
	theCharP  = inBufP;
	theCharP += *ioPosP;
	/* updates the current position in the read buffer */
	*ioPosP += 2;
	
	return UIntToHost(inFileNb, theCharP);
	
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
    
	/* points to the right place in the buffer */
	theCharP  = inBufP;
	theCharP += *ioPosP;
	/* updates the current position in the read buffer */
	*ioPosP += 4;
	
	return UInt32ToHost(inFileNb, theCharP);
    
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

