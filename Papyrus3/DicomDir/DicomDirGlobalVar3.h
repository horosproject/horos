/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit (DicomDir library)			*/
/*	File     : DicomdirGlobalVar3.h						*/
/*	Function : contains the declarations of global variables		*/
/*	Authors  : Marianne Logean						*/
/*		   Christian Girard						*/
/*								   		*/
/*	History  : 02.1999	version 3.6					*/
/*								   		*/
/* 	(C) 1999 The University Hospital of Geneva				*/
/*	All Rights Reserved							*/
/*										*/
/********************************************************************************/


#ifndef DicomdirGlobalVar3H 
#define DicomdirGlobalVar3H

#ifdef FILENAME83	
#undef FILENAME83	
#endif



/* --- global variables --- */

/* has the DICOMDIR toolkit been inited or not ? */
WHERE3 int		gIsDicd3Inited;


WHERE3 PapyShort	gArrRecord [END_RECORD];


#endif	    /* DicomdirGlobalVar3H */

