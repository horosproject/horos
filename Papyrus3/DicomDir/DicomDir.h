/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit (DicomDir library)			*/
/*	File     : Dicomdir.h							*/
/*	Function : contains the declarations of types, enumerated types, 	*/
/*		   constants and global variables				*/
/*	Authors  : Mathieu Funk							*/
/*		   Christian Girard						*/
/*		   Jean-Francois Vurlod						*/
/*		   Marianne Logean					        */
/*								   		*/
/*	History  : 05.1997	version 3.5					*/
/*		   02.1999	version 3.6					*/
/*								   		*/
/*      (C) 1997-1999 The University Hospital of Geneva				*/
/*      All Rights Reserved						        */
/*										*/
/********************************************************************************/

#ifndef DicomdirH 
#define DicomdirH

#ifndef Papyrus3H 
#include "Papyrus3.h"
#endif
		
/* --- includes --- */

#ifndef FILENAME83		    /* this is for the normal machines ... */

#ifndef DicomdirEnumRecordsH 
#include "DicomDirEnumRecords.h"
#endif
#ifndef DicomdirTypeDef3H	    /* DICOMDIR type definition */
#include "DicomDirTypeDef3.h"
#endif
#ifndef DicomdirPrivFunctionDef3H   /* DICOMDIR private functions */
#include "DicomDirPrivFunctionDef3.h"
#endif
#ifndef DicomdirPubFunctionDef3H    /* DICOMDIR public functions */
#include "DicomDirPubFunctionDef3.h"
#endif
#ifndef DicomdirGlobalVar3H         /* DICOMDIR global variables */
#include "DicomDirGlobalVar3.h"
#endif

#else				    /* FILENAME83 defined for the DOS machines */

#ifndef DicomdirEnumRecordsH 
#include "DICDER3.h"
#endif
#ifndef DicomdirTypeDef3H	    /* DICOMDIR type definition */
#include "DICDTD3.h"
#endif
#ifndef DicomdirPrivFunctionDef3H   /* DICOMDIR private functions */
#include "DICDPRF3.h"
#endif
#ifndef DicomdirPubFunctionDef3H    /* DICOMDIR public functions */
#include "DICDPUF3.h"
#endif
#ifndef DicomdirGlobalVar3H         /* DICOMDIR global variables */
#include "DICDGLV3.h"
#endif

#endif 				    /* FILENAME83 defined */



#endif	    /* DicomdirH */

