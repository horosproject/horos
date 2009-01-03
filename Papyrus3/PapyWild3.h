/********************************************************************************/
/*				                                                */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyWild3.h                                                  */
/*	Function : declaration of the fct of wild                               */
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
