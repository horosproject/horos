/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyMemSystem.h                                              */
/*	Function : contains calls for asynchronous read                         */
/********************************************************************************/

#ifndef PapyMemSystem3H
#define PapyMemSystem3H

/* ------------------------- includes ------------------------------------------*/

#include <windows.h>
#include <process.h>    /* _beginthread, _endthread */
#include <fcntl.h>      

#ifdef __cplusplus
extern "C" {
int __cdecl _close(int);
long __cdecl _lseek(int, long, int);
int __cdecl _open(const char *, int, ...);
int __cdecl _read(int, void *, unsigned int);
int __cdecl _write(int, void *, unsigned int);
char* __cdecl sprintf(char*, char *, ...);
}
#endif

#ifdef __cplusplus /* C++ PapyMemSystem class and functions */

class PapyMemSystem {
public:
	PapyMemSystem();
	~PapyMemSystem();
	int		Open(char* aFilename,long aLength,long aChunkSize=10240L);
	void	Close();
	int		Read(char* aBuffer,int aLength);
	long	Seek(int aPosition,long anOffset);
	int		WaitSomethingToRead(); 
	int		WaitPlaceToWrite();
	int		IsMemoryAllocated();
	static	void ReadMemory(void* aPapyMemSystem);	// function used in thread
private:
	char*	theBuffer;				// Buffer to read from
	long	theLength;				// Length of buffer
	long	theChunkSize;			// Length of an element chunk read in thread
	char*	theFilename;			// Filename to read from 
	unsigned long theReadingThread;	// Handle to thread reading from filename to fill buffer
	char*	theFirstPosition;		// Starting position of buffer
	char*	theLastPosition;		// Last position in buffer
	char*	theCurrentRead;			// Current position of buffer reading cursor
	char*	theCurrentWrite;			// Current position of file reading cursor
	HANDLE	theReadEvent;			// Event to synchronize file reading
	HANDLE	theReadMutex;				// Mutex to synchronize buffer reading
	HANDLE	theWriteMutex;				// Mutex to synchronize file reading
	HANDLE	theBooleanMutex;				// Mutex to synchronize file reading
	short	theBoolean;				// boolean to check if end of buffer has been reach by all threads
};

extern "C" {
int OpenMemSystem(char* aFilename,long aLength,long aChunk);
int ReadMemSystem(char* aBuffer,int aLength);
int SeekMemSystem(int aPosition,long anOffset);
int IsAllocated();
void CloseMemSystem();
}

#endif

#ifndef __cplusplus	/* C API to PapyMemSystem class */

void* CreatePapyMemSystem();
int OpenPapyMemSystem(void* aPapyMemSystem,char* aFilename,long aLength,long aChunk);
void ClosePapyMemSystem(void* aPapyMemSystem);
int ReadPapyMemSystem(void* aPapyMemSystem,char* aBuffer,int aLength);
int SeekPapyMemSystem(void* aPapyMemSystem,int aPosition,long anOffset);
int IsMemoryAllocated(void* aPapyMemSystem);
void DeletePapyMemSystem(void* aPapyMemSystem);

int OpenMemSystem(char* aFilename,long aLength,long aChunk);
int ReadMemSystem(char* aBuffer,int aLength);
int SeekMemSystem(int aPosition,long anOffset);
int IsAllocated();
void CloseMemSystem();

#endif

#endif
