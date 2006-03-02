#include <stdio.h>
#include <stdlib.h>
#include <string.h>  
#include <time.h>
#include <errno.h>

#ifdef Mac
#include <Files.h>
#include <types.h>
#include <stat.h>
#include <profiler.h>
#endif

#include "jpeg.h"
#include "JPEGLess.h"
#include "io.h"

/* Papyrus 3 redefined basic types */
#ifndef FILENAME83		/* this is for the normal machines ... */

#ifndef PapyTypeDef3H
#include "PapyTypeDef3.h"
#endif

#ifndef PapyEalloc3H
#include "PapyEalloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapyFileSystem3.h"
#endif

#else				/* FILENAME83 defined for the DOS machines */

#ifndef PapyTypeDef3H
#include "PAPYDEF3.h"
#endif

#ifndef PapyEalloc3H
#include "Papaloc3.h"
#endif

#ifndef   PapyFileSystem3H
#include "PapFSys3.h"
#endif

#endif 				/* FILENAME83 defined */


Uchar *ImageBuffer;

/* FILE **inFile, **outFile; */

void main(void)
{
PAPY_FILE InFile;
PAPY_FILE OutFile;     
PapyShort err;
char	fileName [256];
#ifdef Mac
FSSpec 	fFileIn; 
#else
void	*fFileIn;
#endif
/* FSSpec 	fFileOut; */
char name[30];
void *fFileOut; 
PapyULong lenght;
struct stat buf_stat;
PapyULong foo =0L;
time_t tempsBegin; 
long outputJPEGBytes;
Uchar *JPEGData;
int ImWidth, ImHeight, ImPrecision; 
PapyUHShort *ImageBufferShort; 

/*
err = ProfilerInit(collectSummary, ticksTimeBase, 100, 20);
if (err != 0) {
			printf("Error in ProfilerInit: %d \n", err);
			perror("erreur");
			exit(-1);
			}
ProfilerSetStatus(false);
*/


strcpy((char *) fileName, "Ankle.brut");
/* c2pstr((char *) fileName); */ 

strcpy((char *) name, "Ankle.jpeg");

err = strcmp((char *) fileName, "Ankle.brut");

if ( err == 0) {
				ImWidth = 1184;
				ImHeight = 884;
				ImPrecision = 8;
				}
else {
		if ( strcmp((char *) fileName, "F-18.brut") == 0) { 
				ImWidth = 320;
				ImHeight = 240;
				ImPrecision = 8;
				}	
		else {
				if ( strcmp((char *) fileName, "Crois16b.brut") == 0) { 
					ImWidth = 512;
					ImHeight = 512;
					ImPrecision = 16;
					}
				else {
					if ( strcmp((char *) fileName, "degrade16b.brut") == 0) { 
					ImWidth = 1024;
					ImHeight = 1024;
					ImPrecision = 16;
					}		
					else exit(-1);
				}
			}
	}

/* c2pstr((char *) name); */
 
printf("Compile %s result: %s\n", fileName, name);

#ifdef Mac
strcpy((char *) fFileIn.name, fileName);
c2pstr((char *) fFileIn.name);

fFileIn.vRefNum = - LMGetSFSaveDisk ();
fFileIn.parID = LMGetCurDirStore ();
#endif
 
/* Open the infile in the Papyrus 3 way */
err= Papy3FOpen (fileName, 'r', 0, &InFile, (void *) &fFileIn);
if (err < 0) { 
				printf("Open infile failed... %d\n", err);
				exit(-1);
			 }
			 
/* Rewind the infile */
err = Papy3FSeek(InFile, SEEK_SET, 0L);
if (err < 0) { 
				printf("Seek infile failed... \n");
				exit(-1);
			 }     
                    
/* Open the outfile in the Papyrus 3 way */

err= Papy3FCreate (name, 0, 0, &OutFile, &fFileOut);
if (err < 0) { 
				printf("Creation outfile failed... \n");
				exit(-1);
			 }

err= Papy3FOpen (name, 'w', 0, &OutFile, fFileOut);
if (err < 0) { 
				printf("Open outfile failed... \n");
				exit(-1);
			 }
/*
err= Papy3FOpen (NULL, 'w', 0, &OutFile, (void *) &fFileOut);
if (err < 0) { 
				printf("Open outfile failed... %d\n", err);
				exit(-1);
			 }
*/

/* Rewind the file */
err = Papy3FSeek(OutFile, SEEK_SET, 0L);
if (err < 0) {   
				printf("Seek outfile failed... \n");
				exit(-1);
			 }
	
if (fstat(InFile,&buf_stat) == -1) {
				printf("error in stat \n");
				exit(-1);
				}
				
lenght = buf_stat.st_size;
ImageBuffer = (PapyUHChar *) ecalloc3((PapyULong) lenght+5, (PapyULong) sizeof(PapyUHChar));

Papy3FRead (InFile, (PapyULong *) &lenght, (PapyULong) foo, (void *) ImageBuffer);
ImageBuffer [lenght] = EOF;

ImageBufferShort = (PapyUHShort *) ImageBuffer;

tempsBegin = time(NULL);
/*
ProfilerSetStatus(true);
*/

JPEGLosslessEncodeImage ((PapyUHShort *) ImageBufferShort, (PapyUHChar **) &JPEGData, (PapyULong *) &outputJPEGBytes, ImWidth, ImHeight, ImPrecision);
/*
ProfilerSetStatus(false);

ProfilerDump("\pComOpt16_AnkleSummary.prof");
ProfilerTerm();
*/
printf("duree: %d secondes \n", (time(NULL) - tempsBegin));

Papy3FClose (&InFile);

err = Papy3FWrite(OutFile, (PapyULong *) &outputJPEGBytes, 1L, JPEGData);
    if ( err < 0) {
    			printf("error in outfile write process %d\n", err);
    			Papy3FClose (&OutFile);
    			exit(-1);
    			}   
    			
Papy3FClose (&OutFile);
    
efree3 (&ImageBuffer);
efree3 (&JPEGData);

}