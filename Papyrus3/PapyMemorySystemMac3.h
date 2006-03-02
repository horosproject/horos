#ifdef __cplusplus
extern "C" {
#endif

extern PapyShort        Papy3FOpenMem   (char *, char, PAPY_FILE, PAPY_FILE *, void *);
extern int 		Papy3FCloseMem  (PAPY_FILE *);
extern PapyShort 	Papy3FReadMem   (PAPY_FILE, PapyULong *, PapyULong, void **, Boolean);
extern int		Papy3FTellMem   (PAPY_FILE, PapyLong *);
extern int		Papy3FSeekMem   (PAPY_FILE, int, PapyLong);
extern Ptr 		Papy3GetMemPtr( PAPY_FILE vRefNum, long *pos, long *size, long *ActCount);
extern PapyShort	Papy3LoadFileMem( PAPY_FILE vRefNum);

#ifdef __cplusplus
}
#endif
