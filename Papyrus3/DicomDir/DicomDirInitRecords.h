/********************************************************************************/
/*										*/
/*	Project  : P A P Y R U S  Toolkit (DicomDir library)			*/
/*	File     : DicomdirInitRecords.h					*/
/*	Function : declaration of the init fct.                                 */
/*	Authors  : Marianne Logean						*/
/*										*/
/*	History  : 06.1997	version 3.5					*/
/*		   02.1999	version 3.6					*/
/*										*/
/*	(C) 1997 - 1999 The University Hospital of Geneva      			*/
/*	All Rights Reserved					                */
/*										*/
/********************************************************************************/

#ifndef DicomdirInitRecordsH 
#define DicomdirInitRecordsH
#endif


/* ------------------------- functions definition ------------------------------*/

#ifdef _NO_PROTO

extern void init_PatientR();
extern void init_StudyR();
extern void init_SeriesR();
extern void init_ImageR();
extern void init_OverlayR();
extern void init_ModalityLUTR();
extern void init_VOILUTR();
extern void init_CurveR();
extern void init_Topic();
extern void init_Visit();
extern void init_Result();
extern void init_Interpretation();
extern void init_StudyComponentR();
extern void init_PrintQueue();
extern void init_FilmSession();
extern void init_BasicFilmBox();
extern void init_BasicImageBox();

#else

extern void init_PatientR(SElement[]);
extern void init_StudyR(SElement[]);
extern void init_SeriesR(SElement[]);
extern void init_ImageR(SElement[]);
extern void init_OverlayR(SElement[]);
extern void init_ModalityLUTR(SElement[]);
extern void init_VOILUTR(SElement[]);
extern void init_CurveR(SElement[]);
extern void init_Topic(SElement[]);
extern void init_Visit(SElement[]);
extern void init_Result(SElement[]);
extern void init_Interpretation(SElement[]);
extern void init_StudyComponentR(SElement[]);
extern void init_PrintQueue(SElement[]);
extern void init_FilmSession(SElement[]);
extern void init_BasicFilmBox(SElement[]);
extern void init_BasicImageBox(SElement[]);

#endif    /* DicomdirInitRecordsH */


