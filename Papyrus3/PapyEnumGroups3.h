/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyEnumGroups3.h                                            */
/*      Function : contains the declarations of the groups names and of the     */
/*		   elements names                                               */
/********************************************************************************/


#ifndef PapyEnumGroups3H 
#define PapyEnumGroups3H

#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef   PapyEnumImageGroups3H
#include "PapyEnumImageGroups3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef   PapyEnumImageGroups3H
#include "PAPEIG3.h"
#endif

#endif 				/* FILENAME83 defined */

/* 	enumeration of the groups	*/

enum groups {
Group2,
Group4,
Group8,
Group10,
Group18,
Group20,
Group28,
Group32,
Group38,
Group3A,
Group40,
Group41,
Group42,
Group50,
Group54,
Group60,
Group70,
Group88,
Group100,
Group2000,
Group2001,
Group2010,
Group2020,
Group2030,
Group2040,
Group2050,
Group2100,
Group2110,
Group2120,
Group2130,
Group3002,
Group3004,
Group3006,
Group3008,
Group300A,
Group300C,
Group300E,
Group4000,
Group4008,
Group5000,
Group5200,
Group5400,
Group6000,
UINOVERLAY,
Group7053,
Group7FE0,
END_GROUP
};


#endif
