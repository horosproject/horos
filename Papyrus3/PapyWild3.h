/********************************************************************************/
/*				                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyWild3.h                                                  */
/*	Function : declaration of the fct of wild                               */
/*	Authors  : Matthieu Funk                                                */
/*                 Christian Girard                                             */
/*                 Jean-Francois Vurlod                                         */
/*                 Marianne Logean                                              */
/*                                                                              */
/*	History  : 12.1990      version 1.0                                     */
/*                 04.1991      version 1.1                                     */
/*                 12.1991      version 1.2                                     */
/*                 06.1993      version 2.0                                     */
/*                 06.1994      version 3.0                                     */
/*                 06.1995      version 3.1                                     */
/*                 02.1996      version 3.3                                     */
/*                 02.1999      version 3.6                                     */
/*                 04.2001      version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                 10.2001      version 3.71 MAJ Dicom par CHG                  */
/*                                                                              */
/* 	(C) 1990-2001                                                           */
/*	The University Hospital of Geneva                                       */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/


#ifndef PapyWild3H
#define PapyWild3H
#endif


#ifdef _NO_PROTO
extern char	*wildname();
extern void	wild3();

extern void	wild2exit();
extern void	wildexit();
extern void	wildcexit();
extern void	wildrexit();
extern void	tameexit();
#else
extern char	*wildname(register char *);
extern void	wild3(char *,char *);

extern void	wild2exit(char *, char *);
extern void	wildexit(char *);
extern void	wildcexit(char *);
extern void	wildrexit(char *);
extern void	tameexit();
#endif
