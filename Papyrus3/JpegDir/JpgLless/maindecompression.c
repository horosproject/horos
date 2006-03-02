#include <stdio.h>
#include <stdlib.h>
#include <string.h>  
#include <time.h>

#ifdef Mac
#include <Files.h>
#include <types.h>
#include <stat.h>
#include <profiler.h>
#endif

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


PAPY_FILE JpegFile;     

extern void JPEGLosslessDecodeImage (PAPY_FILE, PapyUHShort *, int, int);

typedef enum {
      M_SOF0 = 0xc0,
      M_SOF1 = 0xc1,
      M_SOF2 = 0xc2,
      M_SOF3 = 0xc3,

      M_SOF5 = 0xc5,
      M_SOF6 = 0xc6,
      M_SOF7 = 0xc7,

      M_JPG = 0xc8,
      M_SOF9 = 0xc9,
      M_SOF10 = 0xca,
      M_SOF11 = 0xcb,

      M_SOF13 = 0xcd,
      M_SOF14 = 0xce,
      M_SOF15 = 0xcf,

      M_DHT = 0xc4,

      M_DAC = 0xcc,

      M_RST0 = 0xd0,
      M_RST1 = 0xd1,
      M_RST2 = 0xd2,
      M_RST3 = 0xd3,
      M_RST4 = 0xd4,
      M_RST5 = 0xd5,
      M_RST6 = 0xd6,
      M_RST7 = 0xd7,

      M_SOI = 0xd8,
      M_EOI = 0xd9,
      M_SOS = 0xda,
      M_DQT = 0xdb,
      M_DNL = 0xdc,
      M_DRI = 0xdd,
      M_DHP = 0xde,
      M_EXP = 0xdf,

      M_APP0 = 0xe0,
      M_APP15 = 0xef,

      M_JPG0 = 0xf0,
      M_JPG13 = 0xfd,
      M_COM = 0xfe,

      M_TEM = 0x01,

      M_ERROR = 0x100
} JpegMarker;

void main(void)
{

int c, c2, nbytes, lenght, lenght_elt; /* Read File Header */
int Precision, imageHeight, imageWidth; /* image parameters*/
short numComponents;
PapyULong foo =0L;
PapyULong imagesize;
PapyULong imagesizelim;
int numBytes;
PapyUHChar *readBuffer;
int i, j, tempo, bufsize;
int Buffindex;
PapyUHShort *image;
PapyULong	 refPoint;

PapyShort err;
short fileNb;
FSSpec 	fFile; 
struct stat buf_stat;
PapyUHChar *imagefin;
time_t tempsBegin, tempsEnd; 
char name[30];
PAPY_FILE OutFile;
void *fFileOut;

/*
err = ProfilerInit(collectDetailed, bestTimeBase, 100, 20);
if (err != 0) {
			printf("Error in ProfilerInit: %d \n", err);
			exit(-1);
			}
ProfilerSetStatus(false);
*/


strcpy((char *) fFile.name, "Ankle.jpeg");
c2pstr((char *) fFile.name);

printf("Decompile %s\n", fFile.name);

fFile.vRefNum = - LMGetSFSaveDisk ();
fFile.parID = LMGetCurDirStore ();

/* Open the file in the Papyrus 3 way */
err= Papy3FOpen (NULL, 'r', 0, &JpegFile, (void *) &fFile);
if (err < 0) { 
				printf("Open file failed... \n");
				exit(-1);
			 }
			 
/*
Papy3FTell ( (PAPY_FILE) JpegFile, (PapyLong *)  &refPoint);
printf("refpoint %d %d\n", refPoint, err);
*/

if (fstat(JpegFile,&buf_stat) == -1) {
				printf("error in stat \n");
				exit(-1);
				}
				
lenght = buf_stat.st_size;

/* Rewind the file */
err = Papy3FSeek(JpegFile, SEEK_SET, 0L);
if (err < 0) { 
				printf("Seek file failed... \n");
				exit(-1); 
			 }

			 
/* Read File Header */

    /*
     * Demand an SOI marker at the start of the file --- otherwise it's
     * probably not a JPEG file at all.
     */
    
     
    bufsize =  100L; 
    readBuffer = (PapyUHChar *) ecalloc3((PapyULong) bufsize, (PapyULong) sizeof(PapyUHChar));
    
    numBytes =  100L;  
    Papy3FRead (JpegFile, (PapyULong *) &numBytes, (PapyULong) foo, (void *) readBuffer);
    
    /*
     Papy3FTell ( (PAPY_FILE) JpegFile, (PapyLong *)  &refPoint);
    printf("refpoint %d %d\n", refPoint, err);
    */
    
    Buffindex = 0;
    c = readBuffer[Buffindex++];

    c2 = readBuffer[Buffindex++];
   
    if ((c != 0xFF) || (c2 != M_SOI)) {
        if( c == EOF ) {
            printf("Reached end of input file. All done!\n");
            Papy3FClose (&JpegFile);
            exit(1);
        } else {
	    printf ("Not a JPEG file. Found %02X %02X\n", c, c2);
	    exit (1); 
        }
    }/*endif*/

    /* GetSoi (dcPtr);		 OK, process SOI */
    
    /*
     * Process markers until SOF
     */

    nbytes = 0;
    do {
	do {
	    nbytes++;
	    c =  readBuffer[Buffindex++];
	    
	} while (c != 0xFF);
	do {
	    c =  readBuffer[Buffindex++];
	} while (c == 0xFF);
    } while (c == 0);
    
    
    switch (c) {
    case M_SOF0:
    case M_SOF1:
    case M_SOF3:
              
    		   tempo = readBuffer[Buffindex++];
	   		   lenght_elt =  (tempo<<8) + readBuffer[Buffindex++];
	   		 
   			   Precision = readBuffer[Buffindex++];
   			 
   			   tempo = readBuffer[Buffindex++];
    		   imageHeight = (tempo<<8) + readBuffer[Buffindex++];
    		 
    	       tempo = readBuffer[Buffindex++];
    		   imageWidth = (tempo<<8) + readBuffer[Buffindex++];
    		 
   			   numComponents =  readBuffer[Buffindex++];
   			  printf("Depth %d... numComponents %d... \n", (int) Precision, (int) numComponents);
   			  printf("height %d width %d... \n", (int) imageHeight, (int) imageWidth);
   	
	break;

    default:
	fprintf (stderr, "Unsupported SOF marker type 0x%02x", c);
	break;
    }
 
    efree3 (&readBuffer);


/* Rewind the file */
err = Papy3FSeek(JpegFile, SEEK_SET, 0L);
if (err < 0) { 
				printf("Seek file failed... \n");
				exit(-1);
			 }

/*
Papy3FTell ( (PAPY_FILE) JpegFile, (PapyLong *)  &refPoint);
printf("refpoint %d (after rewind)\n", refPoint);
*/

/* Define memory for output image */
 
 printf("numcomponents %d \n", numComponents);
 
if (Precision == 8) imagesize = (PapyULong) imageWidth*imageHeight*numComponents; 
else imagesize = (PapyULong) imageWidth*imageHeight*numComponents*2;

image = (PapyUHShort *) emalloc3((PapyULong) imagesize);
		 
/* jpeg lossless compression */

tempsBegin = time(NULL);
/*
ProfilerSetStatus(true);
*/
JPEGLosslessDecodeImage ((PAPY_FILE) JpegFile, (PapyUHShort *) image, (int) Precision, (int) lenght);
/*
ProfilerSetStatus(false);

ProfilerDump("\pDec_Det_Optimise.psv1");

ProfilerTerm();
*/

printf("duree: %d secondes \n", (time(NULL) - tempsBegin));

Papy3FClose (&JpegFile);

strcpy((char *) name, "Ankle.ppm");
/* c2pstr((char *) name); */
                    
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

/* Rewind the file */
err = Papy3FSeek(OutFile, SEEK_SET, 0L);
if (err < 0) {  
				printf("Seek outfile failed... \n");
				exit(-1);
			 }
	

err = Papy3FWrite(OutFile, (PapyULong *) &imagesize, 1L, image);
if ( err < 0) {
    		printf("error in outfile write process %d\n", err);
    		Papy3FClose (&OutFile);
    		exit(-1);
    		}
    		
Papy3FClose (&OutFile);
		
efree3(&image);

printf("Sortie a fin de programme... \n");

}