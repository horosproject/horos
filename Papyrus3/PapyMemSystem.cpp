/********************************************************************************/
/*                                                                              */
/*	Project  : P A P Y R U S  Toolkit                                       */
/*	File     : PapyMemSystem.cpp                                            */
/*	Function : contains calls for asynchronous read                         */
/*	Authors  : Olivier Baujard                                              */
/*                                                                              */
/*	History  : 03.1997	version 3.1                                     */
/*                 04.2001	version 3.7                                     */
/*                 09.2001      version 3.7  on CVS                             */
/*                                                                              */
/* 	(C) 1990-2001 The University Hospital of Geneva                         */
/*	All Rights Reserved                                                     */
/*                                                                              */
/********************************************************************************/


#include "PapyMemSystem.h"
#include <time.h>

PapyMemSystem::PapyMemSystem()
{
	theFilename=NULL;
	theBuffer=theCurrentWrite=theCurrentRead=theFirstPosition=theLastPosition=NULL;
	theLength=0L;
	theChunkSize=0L;
	theReadingThread=0;
	theReadEvent=NULL;
	theReadMutex=NULL;
	theWriteMutex=NULL;
	theBooleanMutex=NULL;
	theBoolean=0;
}

PapyMemSystem::~PapyMemSystem()
{
	Close();
}

int PapyMemSystem::Open(char* aFilename,long aLength,long aChunkSize)
{
	Close();
	strcpy(theFilename=new char[strlen(aFilename)+1],aFilename);
	theFilename[strlen(aFilename)]=0;
	theBuffer=new char[theLength=aLength];
	memset(theBuffer,0,theLength);
	theChunkSize=aChunkSize;
	theCurrentRead=theCurrentWrite=theFirstPosition=theBuffer;
	theLastPosition=theBuffer+theLength;
	if ((theReadEvent=CreateEvent(NULL,FALSE,FALSE,NULL))==NULL)
	{
		Close();
		return -1;
	}
	if ((theReadMutex=CreateMutex(NULL,FALSE,NULL))==NULL)
	{
		Close();
		return -1;
	}
	if ((theWriteMutex=CreateMutex(NULL,FALSE,NULL))==NULL)
	{
		Close();
		return -1;
	}
	if ((theBooleanMutex=CreateMutex(NULL,FALSE,NULL))==NULL)
	{
		Close();
		return -1;
	}
	if ((theReadingThread=_beginthread(ReadMemory,0,this))==-1)
	{
		Close();
	}
	return theReadingThread;
}

void PapyMemSystem::Close()
{
	if (theBuffer)
	{
		delete [] theBuffer;
	}
	theBuffer=theCurrentWrite=theCurrentRead=theFirstPosition=theLastPosition=NULL;
	if (theFilename)
	{
		delete [] theFilename;
	}
	theFilename=NULL;
	if (theReadMutex)
	{
		CloseHandle(theReadMutex);
	}
	theReadMutex=NULL;
	if (theWriteMutex)
	{
		CloseHandle(theWriteMutex);
	}
	theWriteMutex=NULL;
	if (theBooleanMutex)
	{
		CloseHandle(theBooleanMutex);
	}
	theBooleanMutex=NULL;
	if (theReadEvent)
	{
		CloseHandle(theReadEvent);
	}
	theReadEvent=NULL;
	theLength=0;
	theReadingThread=0;
	theBoolean=0;
}

long PapyMemSystem::Seek(int aPosition,long anOffset)
{
	long theResult;
	switch (aPosition) {
	case SEEK_SET:
			theCurrentRead=theFirstPosition+anOffset;
		break;
	case SEEK_CUR:
			theCurrentRead=theCurrentRead+anOffset;
		break;
	case SEEK_END:
			theCurrentRead=theLastPosition-anOffset;
		break;
	}
	theResult=theCurrentRead-theFirstPosition;
	return theResult;
}

int PapyMemSystem::IsMemoryAllocated()
{
	return (theBuffer) ? 1 : 0;
}

int PapyMemSystem::WaitSomethingToRead() // wait for bytes available to read from buffer
{
	int availableBytes=0;
	do
	{
		WaitForSingleObject(theReadMutex,INFINITE);
		WaitForSingleObject(theWriteMutex,INFINITE);
		if (theBoolean==0)
		{
			availableBytes=theCurrentWrite-theCurrentRead;
		}
		else
		{
			availableBytes=theLastPosition-theCurrentRead;
		}
		ReleaseMutex(theReadMutex);
		ReleaseMutex(theWriteMutex);
	} while (availableBytes<=0);
	return availableBytes;
}

int PapyMemSystem::Read(char* aBuffer,int aLength)
{
	int bytesAvailable=0;
	int toRead=0;
	int bytesRead=0;
	int theRemainingLength=aLength;
	do {
		bytesAvailable=WaitSomethingToRead();
		toRead=(bytesAvailable>=theRemainingLength) ? theRemainingLength : bytesAvailable;
		WaitForSingleObject(theReadMutex,INFINITE);
		memcpy(aBuffer,theCurrentRead,toRead);
		aBuffer+=toRead;
		theCurrentRead+=toRead;
		bytesRead+=toRead;
		theRemainingLength-=toRead;
		if (theCurrentRead==theLastPosition) 
		{
			theCurrentRead=theFirstPosition;
			WaitForSingleObject(theBooleanMutex,INFINITE);
			theBoolean=0;
			ReleaseMutex(theBooleanMutex);
		}
		ReleaseMutex(theReadMutex);
	} while (bytesRead!=aLength);
	return aLength;
}

int PapyMemSystem::WaitPlaceToWrite() // wait for bytes available to write in buffer
{
	int availableBytes=0;
	do
	{
		WaitForSingleObject(theReadMutex,INFINITE);
		WaitForSingleObject(theWriteMutex,INFINITE);
		if (theBoolean)
		{
			availableBytes=theCurrentRead-theCurrentWrite;
		}
		else
		{
			availableBytes=theLastPosition-theCurrentWrite;
		}
		ReleaseMutex(theReadMutex);
		ReleaseMutex(theWriteMutex);
	} while (availableBytes<=0);
	return availableBytes;
}

void PapyMemSystem::ReadMemory(void* aPapyMemSystem)
{
	PapyMemSystem* thePapyMemSystem=(PapyMemSystem*)aPapyMemSystem;
	_fmode=_O_BINARY;
	int theFile=_open(thePapyMemSystem->theFilename,_O_RDONLY);
	_lseek(theFile,0L,SEEK_SET);
	int bytesWrite=0;
	do {
		int theChunkSize=thePapyMemSystem->theChunkSize;
		int bytesAvailable=thePapyMemSystem->WaitPlaceToWrite();
		int toWrite=(bytesAvailable<theChunkSize) ? bytesAvailable : theChunkSize;
		WaitForSingleObject(thePapyMemSystem->theCurrentWrite,INFINITE);
		_read(theFile,(void*)(thePapyMemSystem->theCurrentWrite),toWrite);
		thePapyMemSystem->theCurrentWrite+=toWrite;
		if (thePapyMemSystem->theCurrentWrite==thePapyMemSystem->theLastPosition)
		{
			WaitForSingleObject(thePapyMemSystem->theBooleanMutex,INFINITE);
			thePapyMemSystem->theBoolean=1;
			ReleaseMutex(thePapyMemSystem->theBooleanMutex);
			thePapyMemSystem->theCurrentWrite=thePapyMemSystem->theFirstPosition;
		}
		ReleaseMutex(thePapyMemSystem->theWriteMutex);
		bytesWrite+=toWrite;
	} while (bytesWrite!=thePapyMemSystem->theLength);
	_close(theFile);
	_endthread();
}

extern "C" void* CreatePapyMemSystem()
{
	return new PapyMemSystem();
}

extern "C" int OpenPapyMemSystem(void* aPapyMemSystem,char* aFilename,long aLength,long aChunk)
{
	return ((PapyMemSystem*)aPapyMemSystem)->Open(aFilename,aLength,aChunk);
}

extern "C" void ClosePapyMemSystem(void* aPapyMemSystem)
{
	((PapyMemSystem*)aPapyMemSystem)->Close();
}

extern "C" int ReadPapyMemSystem(void* aPapyMemSystem,char* aBuffer,int aLength)
{
	return ((PapyMemSystem*)aPapyMemSystem)->Read(aBuffer,aLength);
}

extern "C" int SeekPapyMemSystem(void* aPapyMemSystem,int aPosition,long anOffset)
{
	return ((PapyMemSystem*)aPapyMemSystem)->Seek(aPosition,anOffset);
}

extern "C" int IsMemoryAllocated(void* aPapyMemSystem)
{
	return ((PapyMemSystem*)aPapyMemSystem)->IsMemoryAllocated();
}

extern "C" void DeletePapyMemSystem(void* aPapyMemSystem)
{
	delete ((PapyMemSystem*)aPapyMemSystem);
}

PapyMemSystem* aPapyMemSystem=NULL;

extern "C" int OpenMemSystem(char* aFilename,long aLength,long aChunk)
{
	aPapyMemSystem=(PapyMemSystem*)CreatePapyMemSystem();
	return OpenPapyMemSystem(aPapyMemSystem,aFilename,aLength,aChunk);
}

extern "C" int ReadMemSystem(char* aBuffer,int aLength)
{
	return (aPapyMemSystem) ? ReadPapyMemSystem(aPapyMemSystem,aBuffer,aLength) : -1;
}

extern "C" int SeekMemSystem(int aPosition,long anOffset)
{
	return (aPapyMemSystem) ? SeekPapyMemSystem(aPapyMemSystem,aPosition,anOffset) :-1;
}

extern "C" int IsAllocated()
{
	return (aPapyMemSystem) ? IsMemoryAllocated(aPapyMemSystem) : 0;
}

extern "C" void CloseMemSystem()
{
	if (aPapyMemSystem) DeletePapyMemSystem(aPapyMemSystem);
	aPapyMemSystem=NULL;
}
