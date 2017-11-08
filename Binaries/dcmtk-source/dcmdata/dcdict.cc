/*
 *
 *  Copyright (C) 1994-2005, OFFIS
 *
 *  This software and supporting documentation were developed by
 *
 *    Kuratorium OFFIS e.V.
 *    Healthcare Information and Communication Systems
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *  THIS SOFTWARE IS MADE AVAILABLE,  AS IS,  AND OFFIS MAKES NO  WARRANTY
 *  REGARDING  THE  SOFTWARE,  ITS  PERFORMANCE,  ITS  MERCHANTABILITY  OR
 *  FITNESS FOR ANY PARTICULAR USE, FREEDOM FROM ANY COMPUTER DISEASES  OR
 *  ITS CONFORMITY TO ANY SPECIFICATION. THE ENTIRE RISK AS TO QUALITY AND
 *  PERFORMANCE OF THE SOFTWARE IS WITH THE USER.
 *
 *  Module:  dcmdata
 *
 *  Author:  Andrew Hewett
 *
 *  Purpose: loadable DICOM data dictionary
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:19 $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */

#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "dcdict.h"

#include "ofconsol.h"
#include "ofstd.h"
#include "dcdefine.h"
#include "dcdicent.h"

#define INCLUDE_CSTDLIB
#define INCLUDE_CSTDIO
#define INCLUDE_CSTRING
#define INCLUDE_CCTYPE
#include "ofstdinc.h"

/*
** The separator character between fields in the data dictionary file(s)
*/
#define DCM_DICT_FIELD_SEPARATOR_CHAR '\t'

/*
** Comment character for the data dictionary file(s)
*/
#define DCM_DICT_COMMENT_CHAR '#'

/*
** THE Global DICOM Data Dictionary
*/

GlobalDcmDataDictionary dcmDataDict(OFTrue /*loadBuiltin*/, OFTrue /*loadExternal*/);


/*
** Member Functions
*/

static DcmDictEntry*
makeSkelEntry(Uint16 group, Uint16 element,
             Uint16 upperGroup, Uint16 upperElement,
             DcmEVR evr, const char* tagName, int vmMin, int vmMax,
             const char* standardVersion,
             DcmDictRangeRestriction groupRestriction,
             DcmDictRangeRestriction elementRestriction,
             const char* privCreator)
{
    DcmDictEntry* e = NULL;
    e = new DcmDictEntry(group, element, upperGroup, upperElement, evr,
                         tagName, vmMin, vmMax, standardVersion, OFFalse, privCreator);
    if (e != NULL) {
        e->setGroupRangeRestriction(groupRestriction);
        e->setElementRangeRestriction(elementRestriction);
    }
    return e;
}


OFBool DcmDataDictionary::loadSkeletonDictionary()
{
    /*
    ** We need to know about Group Lengths to compute them
    */
    DcmDictEntry* e = NULL;
    e = makeSkelEntry(0x0000, 0x0000, 0xffff, 0x0000,
                      EVR_UL, "GenericGroupLength", 1, 1, "GENERIC",
                      DcmDictRange_Unspecified, DcmDictRange_Unspecified, NULL);
    addEntry(e);
    e = makeSkelEntry(0x0000, 0x0001, 0xffff, 0x0001,
                      EVR_UL, "GenericGroupLengthToEnd", 1, 1, "GENERIC",
                      DcmDictRange_Unspecified, DcmDictRange_Unspecified, NULL);
    addEntry(e);
    /*
    ** We need to know about Items and Delimitation Items to parse
    ** (and construct) sequences.
    */
    e = makeSkelEntry(0xfffe, 0xe000, 0xfffe, 0xe000,
                      EVR_na, "Item", 1, 1, "DICOM3",
                      DcmDictRange_Unspecified, DcmDictRange_Unspecified, NULL);
    addEntry(e);
    e = makeSkelEntry(0xfffe, 0xe00d, 0xfffe, 0xe00d,
                      EVR_na, "ItemDelimitationItem", 1, 1, "DICOM3",
                      DcmDictRange_Unspecified, DcmDictRange_Unspecified, NULL);
    addEntry(e);
    e = makeSkelEntry(0xfffe, 0xe0dd, 0xfffe, 0xe0dd,
                      EVR_na, "SequenceDelimitationItem", 1, 1, "DICOM3",
                      DcmDictRange_Unspecified, DcmDictRange_Unspecified, NULL);
    addEntry(e);

    skeletonCount = numberOfEntries();
    return OFTrue;
}

DcmDataDictionary::DcmDataDictionary(OFBool loadBuiltin, OFBool loadExternal)
  : hashDict(),
    repDict(),
    skeletonCount(0),
    dictionaryLoaded(OFFalse)
{
    loadSkeletonDictionary();
    if (loadBuiltin) {
        loadBuiltinDictionary();
        dictionaryLoaded = (numberOfEntries() > skeletonCount);
    }
    if (loadExternal) {
        if (loadExternalDictionaries()) {
            dictionaryLoaded = OFTrue;
        }
    }
}

DcmDataDictionary::~DcmDataDictionary()
{
//    clear(); We will keep it in memory idenfinitevely.... if another thread uses it
}


void DcmDataDictionary::clear()
{
   hashDict.clear();
   repDict.clear();
}


static void
stripWhitespace(char* s)
{
  if (s)
  {
    char c;
    char *t;
    char *p;
    t=p=s;
    while ((c = *t++)) if (!isspace(c)) *p++ = c;
    *p = '\0';
  }
}

static char*
stripTrailingWhitespace(char* s)
{
    int i, n;

    if (s == NULL) return s;

    n = (int)strlen(s);
    for (i = n - 1; i >= 0 && isspace(s[i]); i--)
        s[i] = '\0';
    return s;
}

static void
stripLeadingWhitespace(char* s)
{
  if (s)
  {
    char c;
    char *t=s;
    char *p=s;
    while (isspace(*t)) t++;
    while ((c = *t++)) *p++ = c;
    *p = '\0';
  }
}

static OFBool
parseVMField(char* vmField, int& vmMin, int& vmMax)
{
    OFBool ok = OFTrue;
    char c = 0;
    int dummy = 0;

    /* strip any whitespace */
    stripWhitespace(vmField);

    if (sscanf(vmField, "%d-%d%c", &vmMin, &dummy, &c) == 3) {
        /* treat "2-2n" like "2-n" for the moment */
        if ((c == 'n') || (c == 'N')) {
            vmMax = DcmVariableVM;
        } else {
            ok = OFFalse;
        }
    } else if (sscanf(vmField, "%d-%d", &vmMin, &vmMax) == 2) {
        /* range VM (e.g. "2-6") */
    } else if (sscanf(vmField, "%d-%c", &vmMin, &c) == 2) {
        if ((c == 'n') || (c == 'N')) {
            vmMax = DcmVariableVM;
        } else {
            ok = OFFalse;
        }
    } else if (sscanf(vmField, "%d%c", &vmMin, &c) == 2) {
        /* treat "2n" like "2-n" for the moment */
        if ((c == 'n') || (c == 'N')) {
            vmMax = DcmVariableVM;
        } else {
            ok = OFFalse;
        }
    } else if (sscanf(vmField, "%d", &vmMin) == 1) {
        /* fixed VM */
        vmMax = vmMin;
    } else if (sscanf(vmField, "%c", &c) == 1) {
        /* treat "n" like "1-n" */
        if ((c == 'n') || (c == 'N')) {
            vmMin = 1;
            vmMax = DcmVariableVM;
        } else {
            ok = OFFalse;
        }
    } else {
        ok = OFFalse;
    }
    return ok;
}

static int
splitFields(const char* line, char* fields[], int maxFields, char splitChar)
{
    const char *p;
    int foundFields = 0;
    int len;

    do {
#ifdef __BORLANDC__
        // Borland Builder expects a non-const argument
        p = strchr(OFconst_cast(char *, line), splitChar);
#else
        p = strchr(line, splitChar);
#endif
        if (p == NULL) {
            len = (int)strlen(line);
        } else {
            len = (int)(p - line);
        }
        fields[foundFields] = OFstatic_cast(char *, malloc(len+1));
        strncpy(fields[foundFields], line, len);
        fields[foundFields][len] = '\0';
        foundFields++;
        line = p + 1;
    } while ((foundFields < maxFields) && (p != NULL));

    return foundFields;
}

static OFBool
parseTagPart(char *s, unsigned int& l, unsigned int& h,
             DcmDictRangeRestriction& r)
{
    OFBool ok = OFTrue;
    char restrictor = ' ';

    r = DcmDictRange_Unspecified; /* by default */

    if (sscanf(s, "%x-%c-%x", &l, &restrictor, &h) == 3) {
        switch (restrictor) {
        case 'o':
        case 'O':
            r = DcmDictRange_Odd;
            break;
        case 'e':
        case 'E':
            r = DcmDictRange_Even;
            break;
        case 'u':
        case 'U':
            r = DcmDictRange_Unspecified;
            break;
        default:
            ofConsole.lockCerr() << "DcmDataDictionary: Unknown range restrictor: " << restrictor << endl;
            ofConsole.unlockCerr();
            ok = OFFalse;
            break;
        }
    } else if (sscanf(s, "%x-%x", &l, &h) == 2) {
        r = DcmDictRange_Even; /* by default */
    } else if (sscanf(s, "%x", &l) == 1) {
        h = l;
    } else {
        ok = OFFalse;
    }
    return ok;
}

static OFBool
parseWholeTagField(char* s, DcmTagKey& key,
                   DcmTagKey& upperKey,
                   DcmDictRangeRestriction& groupRestriction,
                   DcmDictRangeRestriction& elementRestriction,
                   char *&privCreator)
{
    unsigned int gl, gh, el, eh;
    groupRestriction = DcmDictRange_Unspecified;
    elementRestriction = DcmDictRange_Unspecified;

    stripLeadingWhitespace(s);
    stripTrailingWhitespace(s);

    char gs[64];
    char es[64];
    char pc[64];
    int slen = (int)strlen(s);

    if (s[0] != '(') return OFFalse;
    if (s[slen-1] != ')') return OFFalse;
    if (strchr(s, ',') == NULL) return OFFalse;

    /* separate the group and element parts */
    int i = 1; /* after the '(' */
    int gi = 0;
    for (; s[i] != ',' && s[i] != '\0'; i++)
    {
        gs[gi] = s[i];
        gi++;
    }
    gs[gi] = '\0';

    if (s[i] == '\0') return OFFalse; /* element part missing */
    i++; /* after the ',' */

    stripLeadingWhitespace(s+i);

    int pi = 0;
    if (s[i] == '\"') /* private creator */
    {
        i++;  // skip opening quotation mark
        for (; s[i] != '\"' && s[i] != '\0'; i++) pc[pi++] = s[i];
        pc[pi] = '\0';
        if (s[i] == '\0') return OFFalse; /* closing quotation mark missing */
        i++;
        stripLeadingWhitespace(s+i);
        if (s[i] != ',') return OFFalse; /* element part missing */
        i++; /* after the ',' */
    }

    int ei = 0;
    for (; s[i] != ')' && s[i] != '\0'; i++) {
        es[ei] = s[i];
        ei++;
    }
    es[ei] = '\0';

    /* parse the tag parts into their components */
    stripWhitespace(gs);
    if (parseTagPart(gs, gl, gh, groupRestriction) == OFFalse)
        return OFFalse;

    stripWhitespace(es);
    if (parseTagPart(es, el, eh, elementRestriction) == OFFalse)
        return OFFalse;

    if (pi > 0)
    {
      // copy private creator name
      privCreator = new char[strlen(pc)+1]; // deleted by caller
      if (privCreator) strcpy(privCreator,pc);
    }

    key.set(OFstatic_cast(unsigned short, gl), OFstatic_cast(unsigned short, el));
    upperKey.set(OFstatic_cast(unsigned short, gh), OFstatic_cast(unsigned short, eh));

    return OFTrue;
}

static OFBool
onlyWhitespace(const char* s)
{
    int len = (int)strlen(s);
    int charsFound = OFFalse;

    for (int i=0; (!charsFound) && (i<len); i++) {
        charsFound = !isspace(s[i]);
    }
    return (!charsFound)?(OFTrue):(OFFalse);
}

static char*
getLine(char* line, int maxLineLen, FILE* f)
{
    char* s;

    s = fgets(line, maxLineLen, f);

    /* strip any trailing white space */
    stripTrailingWhitespace(line);

    return s;
}

static OFBool
isaCommentLine(const char* s)
{
    OFBool isComment = OFFalse; /* assumption */
    int len = (int)strlen(s);
    int i = 0;
    for (i=0; i<len && isspace(s[i]); i++) /*loop*/;
    isComment = (s[i] == DCM_DICT_COMMENT_CHAR);
    return isComment;
}

OFBool
DcmDataDictionary::loadDictionary(const char* fileName, OFBool errorIfAbsent)
{

    char lineBuf[DCM_MAXDICTLINESIZE+1];
    FILE* f = NULL;
    int lineNumber = 0;
    char* lineFields[DCM_MAXDICTFIELDS+1];
    int fieldsPresent;
    DcmDictEntry* e;
    int errorsEncountered = 0;
    OFBool errorOnThisLine = OFFalse;
    int i;

    DcmTagKey key, upperKey;
    DcmDictRangeRestriction groupRestriction = DcmDictRange_Unspecified;
    DcmDictRangeRestriction elementRestriction = DcmDictRange_Unspecified;
    DcmVR vr;
    char* vrName;
    char* tagName;
    char* privCreator;
    int vmMin, vmMax = 1;
    const char* standardVersion;

    /* first, check whether 'fileName' really points to a file (and not to a directory or the like) */
    if (!OFStandard::fileExists(fileName) || (f = fopen(fileName, "r")) == NULL) {
        if (errorIfAbsent) {
            ofConsole.lockCerr() << "DcmDataDictionary: Cannot open file: " << fileName << endl;
            ofConsole.unlockCerr();
        }
        return OFFalse;
    }

    while (getLine(lineBuf, DCM_MAXDICTLINESIZE, f)) {
        lineNumber++;

        if (onlyWhitespace(lineBuf)) {
            continue; /* ignore this line */
        }
        if (isaCommentLine(lineBuf)) {
            continue; /* ignore this line */
        }

        errorOnThisLine = OFFalse;

        /* fields are tab separated */
        fieldsPresent = splitFields(lineBuf, lineFields,
                                    DCM_MAXDICTFIELDS,
                                    DCM_DICT_FIELD_SEPARATOR_CHAR);

        /* initialize dict entry fields */
        vrName = NULL;
        tagName = NULL;
        privCreator = NULL;
        vmMin = vmMax = 1;
        standardVersion = "DICOM";

        switch (fieldsPresent) {
        case 0:
        case 1:
        case 2:
            ofConsole.lockCerr() << "DcmDataDictionary: "<< fileName << ": "
                 << "too few fields (line "
                 << lineNumber << ")" << endl;
            ofConsole.unlockCerr();
            errorOnThisLine = OFTrue;
            break;
        default:
            ofConsole.lockCerr() << "DcmDataDictionary: " << fileName << ": "
                 << "too many fields (line "
                 << lineNumber << "): " << endl;
            ofConsole.unlockCerr();
            errorOnThisLine = OFTrue;
            break;
        case 5:
            stripWhitespace(lineFields[4]);
            standardVersion = lineFields[4];
            /* drop through to next case label */
        case 4:
            /* the VM field is present */
            if (!parseVMField(lineFields[3], vmMin, vmMax)) {
                ofConsole.lockCerr() << "DcmDataDictionary: " << fileName << ": "
                     << "bad VM field (line "
                     << lineNumber << "): " << lineFields[3] << endl;
                ofConsole.unlockCerr();
                errorOnThisLine = OFTrue;
            }
            /* drop through to next case label */
        case 3:
            if (!parseWholeTagField(lineFields[0], key, upperKey,
                 groupRestriction, elementRestriction, privCreator))
            {
                ofConsole.lockCerr() << "DcmDataDictionary: " << fileName << ": "
                     << "bad Tag field (line "
                     << lineNumber << "): " << lineFields[0] << endl;
                ofConsole.unlockCerr();
                errorOnThisLine = OFTrue;
            } else {
                /* all is OK */
                vrName = lineFields[1];
                stripWhitespace(vrName);

                tagName = lineFields[2];
                stripWhitespace(tagName);

            }
        }

        if (!errorOnThisLine) {
            /* check the VR Field */
            vr.setVR(vrName);
            if (vr.getEVR() == EVR_UNKNOWN) {
                ofConsole.lockCerr() << "DcmDataDictionary: " << fileName << ": "
                     << "bad VR field (line "
                     << lineNumber << "): " << vrName << endl;
                ofConsole.unlockCerr();
                errorOnThisLine = OFTrue;
            }
        }

        if (!errorOnThisLine) {
            e = new DcmDictEntry(
                key.getGroup(), key.getElement(),
                upperKey.getGroup(), upperKey.getElement(),
                vr, tagName, vmMin, vmMax, standardVersion, OFTrue,
                privCreator);

            e->setGroupRangeRestriction(groupRestriction);
            e->setElementRangeRestriction(elementRestriction);
            addEntry(e);
        }

        for (i=0; i<fieldsPresent; i++) {
            free(lineFields[i]);
            lineFields[i] = NULL;
        }

        delete[] privCreator;

        if (errorOnThisLine) {
            errorsEncountered++;
        }
    }

    fclose(f);

    /* return OFFalse if errors were encountered */
    return (errorsEncountered == 0) ? (OFTrue) : (OFFalse);
}

#ifndef HAVE_GETENV

static
char* getenv() {
    return NULL;
}

#endif /* !HAVE_GETENV */



OFBool
DcmDataDictionary::loadExternalDictionaries()
{
    const char* env = NULL;
    int len;
    int sepCnt = 0;
    OFBool msgIfDictAbsent = OFTrue;
    OFBool loadFailed = OFFalse;

    env = getenv(DCM_DICT_ENVIRONMENT_VARIABLE);
    if ((env == NULL) || (strlen(env) == 0)) {
        env = DCM_DICT_DEFAULT_PATH;
        msgIfDictAbsent = OFFalse;
    }

    if ((env != NULL) && (strlen(env) != 0)) {
        len = (int)strlen(env);
        for (int i=0; i<len; i++) {
            if (env[i] == ENVIRONMENT_PATH_SEPARATOR) {
                sepCnt++;
            }
        }

        if (sepCnt == 0) {
            if (!loadDictionary(env, msgIfDictAbsent)) {
                return OFFalse;
            }
        } else {
            char** dictArray;

            dictArray = OFstatic_cast(char **, malloc((sepCnt + 1) * sizeof(char*)));

            int ndicts = splitFields(env, dictArray, sepCnt+1,
                                     ENVIRONMENT_PATH_SEPARATOR);

            for (int ii=0; ii<ndicts; ii++) {
                if ((dictArray[ii] != NULL) && (strlen(dictArray[ii]) > 0)) {
                    if (!loadDictionary(dictArray[ii], msgIfDictAbsent)) {
                        loadFailed = OFTrue;
                    }
                }
                free(dictArray[ii]);
            }
            free(dictArray);
        }
    }

    return (loadFailed) ? (OFFalse) : (OFTrue);
}


void
DcmDataDictionary::addEntry(DcmDictEntry* e)
{
    if (e->isRepeating()) {
        /*
         * Find the best position in repeating tag list
         * Existing entries are replaced if the ranges and repetition
         * constraints are the same.
         * If a range represents a subset of an existing range then it
         * will be placed before it in the list.  This ensures that a
         * search will find the subset rather than the superset.
         * Otherwise entries are appended to the end of the list.
         */
        OFBool inserted = OFFalse;

        DcmDictEntryListIterator iter(repDict.begin());
        DcmDictEntryListIterator last(repDict.end());
        for (; !inserted && iter != last; ++iter) {
            if (e->setEQ(**iter)) {
                /* replace the old entry with the new */
                DcmDictEntry *old = *iter;
                *iter = e;
#ifdef PRINT_REPLACED_DICTIONARY_ENTRIES
                ofConsole.lockCerr() << "replacing " << *old << endl;
                ofConsole.unlockCerr();
#endif
                delete old;
                inserted = OFTrue;
            } else if (e->subset(**iter)) {
                /* e is a subset of the current list position, insert before */
                repDict.insert(iter, e);
                inserted = OFTrue;
            }
        }
        if (!inserted) {
            /* insert at end */
            repDict.push_back(e);
            inserted = OFTrue;
        }
    } else {
        hashDict.put(e);
    }
}

void
DcmDataDictionary::deleteEntry(const DcmDictEntry& entry)
{
    DcmDictEntry* e = NULL;
    e = OFconst_cast(DcmDictEntry *, findEntry(entry));
    if (e != NULL) {
        if (e->isRepeating()) {
            repDict.remove(e);
            delete e;
        } else {
            hashDict.del(entry.getKey(), entry.getPrivateCreator());
        }
    }
}

const DcmDictEntry*
DcmDataDictionary::findEntry(const DcmDictEntry& entry) const
{
    const DcmDictEntry* e = NULL;

    if (entry.isRepeating()) {
        OFBool found = OFFalse;
        DcmDictEntryListConstIterator iter(repDict.begin());
        DcmDictEntryListConstIterator last(repDict.end());
        for (; !found && iter != last; ++iter) {
            if (entry.setEQ(**iter)) {
                found = OFTrue;
                e = *iter;
            }
        }
    } else {
        e = hashDict.get(entry, entry.getPrivateCreator());
    }
    return e;
}

const DcmDictEntry*
DcmDataDictionary::findEntry(const DcmTagKey& key, const char *privCreator) const
{
    /* search first in the normal tags dictionary and if not found
     * then search in the repeating tags list.
     */
    const DcmDictEntry* e = NULL;

    e = hashDict.get(key, privCreator);
    if (e == NULL) {
        /* search in the repeating tags dictionary */
        OFBool found = OFFalse;
        DcmDictEntryListConstIterator iter(repDict.begin());
        DcmDictEntryListConstIterator last(repDict.end());
        for (; !found && iter != last; ++iter) {
            if ((*iter)->contains(key, privCreator)) {
                found = OFTrue;
                e = *iter;
            }
        }
    }
    return e;
}

const DcmDictEntry*
DcmDataDictionary::findEntry(const char *name) const
{
    const DcmDictEntry* e = NULL;
    const DcmDictEntry* ePrivate = NULL;

    /* search first in the normal tags dictionary and if not found
     * then search in the repeating tags list.
     */
    DcmHashDictIterator iter;
    for (iter=hashDict.begin(); (e==NULL) && (iter!=hashDict.end()); ++iter) {
        if ((*iter)->contains(name)) {
            e = *iter;
            if (e->getGroup() % 2) 
            {
                /* tag is a private tag - continue search to be sure to find non-private keys first */
                if (!ePrivate) ePrivate = e;
                e = NULL;
            }
        }
    }

    if (e == NULL) {
        /* search in the repeating tags dictionary */
        OFBool found = OFFalse;
        DcmDictEntryListConstIterator iter2(repDict.begin());
        DcmDictEntryListConstIterator last(repDict.end());
        for (; !found && iter2 != last; ++iter2) {
            if ((*iter2)->contains(name)) {
                found = OFTrue;
                e = *iter2;
            }
        }
    }

    if (e == NULL && ePrivate != NULL) {
        /* no standard key found - use the first private key found */
        e = ePrivate;
    }

    return e;
}


/* ================================================================== */

GlobalDcmDataDictionary::GlobalDcmDataDictionary(OFBool loadBuiltin, OFBool loadExternal)
: dataDict(loadBuiltin, loadExternal)
#ifdef _REENTRANT
, dataDictLock()
#endif
{
}

GlobalDcmDataDictionary::~GlobalDcmDataDictionary()
{
}

const DcmDataDictionary& GlobalDcmDataDictionary::rdlock()
{
#ifdef _REENTRANT
  dataDictLock.rdlock();
#endif
  return dataDict;
}

DcmDataDictionary& GlobalDcmDataDictionary::wrlock()
{
#ifdef _REENTRANT
  dataDictLock.wrlock();
#endif
  return dataDict;
}

void GlobalDcmDataDictionary::unlock()
{
#ifdef _REENTRANT
  dataDictLock.unlock();
#endif
}

OFBool GlobalDcmDataDictionary::isDictionaryLoaded()
{
  OFBool result = rdlock().isDictionaryLoaded();
  unlock();
  return result;
}

void GlobalDcmDataDictionary::clear()
{
  wrlock().clear();
  unlock();
}


/*
** CVS/RCS Log:
** $Log: dcdict.cc,v $
** Revision 1.1  2006/03/01 20:15:19  lpysher
** Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
**
** Revision 1.36  2005/12/08 15:41:04  meichel
** Changed include path schema for all DCMTK header files
**
** Revision 1.35  2005/11/28 16:13:57  meichel
** Minor adaptations needed for Borland Builder 6
**
** Revision 1.34  2005/11/17 13:33:11  meichel
** When locating DICOM tags by name in DcmDataDictionary::findEntry,
**   public tags are now preferred over private tags of the same name.
**
** Revision 1.33  2004/08/03 16:45:58  meichel
** Minor changes for platforms on which strchr/strrchr return a const pointer.
**
** Revision 1.32  2004/02/04 16:27:12  joergr
** Adapted type casts to new-style typecast operators defined in ofcast.h.
** Removed acknowledgements with e-mail addresses from CVS log.
**
** Revision 1.31  2003/10/15 16:55:43  meichel
** Updated error messages for parse errors
**
** Revision 1.30  2003/07/03 15:38:14  meichel
** Introduced DcmDictEntryListConstIterator, needed for compiling with HAVE_STL.
**
** Revision 1.29  2003/03/21 13:08:04  meichel
** Minor code purifications for warnings reported by MSVC in Level 4
**
** Revision 1.28  2002/11/27 12:06:44  meichel
** Adapted module dcmdata to use of new header file ofstdinc.h
**
** Revision 1.27  2002/07/23 14:21:30  meichel
** Added support for private tag data dictionaries to dcmdata
**
** Revision 1.26  2002/06/12 16:57:52  joergr
** Added test to "load data dictionary" routine checking whether given filename
** really points to a file and not to a directory or the like.
**
** Revision 1.25  2002/02/27 14:21:35  meichel
** Declare dcmdata read/write locks only when compiled in multi-thread mode
**
** Revision 1.24  2001/06/01 15:49:01  meichel
** Updated copyright header
**
** Revision 1.23  2000/05/03 14:19:09  meichel
** Added new class GlobalDcmDataDictionary which implements read/write lock
**   semantics for safe access to the DICOM dictionary from multiple threads
**   in parallel. The global dcmDataDict now uses this class.
**
** Revision 1.22  2000/04/14 15:55:03  meichel
** Dcmdata library code now consistently uses ofConsole for error output.
**
** Revision 1.21  2000/03/08 16:26:32  meichel
** Updated copyright header.
**
** Revision 1.20  2000/03/03 14:05:31  meichel
** Implemented library support for redirecting error messages into memory
**   instead of printing them to stdout/stderr for GUI applications.
**
** Revision 1.19  2000/02/23 15:11:49  meichel
** Corrected macro for Borland C++ Builder 4 workaround.
**
** Revision 1.18  2000/02/01 10:12:05  meichel
** Avoiding to include <stdlib.h> as extern "C" on Borland C++ Builder 4,
**   workaround for bug in compiler header files.
**
** Revision 1.17  1999/03/31 09:25:22  meichel
** Updated copyright header in module dcmdata
**
** Revision 1.16  1998/07/28 15:52:37  meichel
** Introduced new compilation flag PRINT_REPLACED_DICTIONARY_ENTRIES
**   which causes the dictionary to display all duplicate entries.
**
** Revision 1.15  1998/07/15 15:51:51  joergr
** Removed several compiler warnings reported by gcc 2.8.1 with
** additional options, e.g. missing copy constructors and assignment
** operators, initialization of member variables in the body of a
** constructor instead of the member initialization list, hiding of
** methods by use of identical names, uninitialized member variables,
** missing const declaration of char pointers. Replaced tabs by spaces.
**
** Revision 1.14  1998/02/06 15:07:23  meichel
** Removed many minor problems (name clashes, unreached code)
**   reported by Sun CC4 with "+w" or Sun CC2.
**
** Revision 1.13  1998/01/27 10:51:40  meichel
** Removed some unused variables, meaningless const modifiers
**   and unreached statements.
**
** Revision 1.12  1997/08/26 14:03:17  hewett
** New data structures for data-dictionary.  The main part of the
** data-dictionary is now stored in an hash table using an optimized
** hash function.  This new data structure reduces data-dictionary
** load times by a factor of 4!  he data-dictionary specific linked-list
** has been replaced by a linked list derived from OFList class
** (see ofstd/include/oflist.h).
** The only interface modifications are related to iterating over the entire
** data dictionary which should not be needed by "normal" applications.
**
** Revision 1.11  1997/07/31 15:55:11  meichel
** New routine stripWhitespace() in dcdict.cc, much faster.
**
** Revision 1.10  1997/07/21 08:25:25  andreas
** - Replace all boolean types (BOOLEAN, CTNBOOLEAN, DICOM_BOOL, BOOL)
**   with one unique boolean type OFBool.
**
** Revision 1.9  1997/05/22 13:16:04  hewett
** Added method DcmDataDictionary::isDictionaryLoaded() to ask if a full
** data dictionary has been loaded.  This method should be used in tests
** rather that querying the number of entries (a sekelton dictionary is
** now always present).
**
** Revision 1.8  1997/05/13 13:49:37  hewett
** Modified the data dictionary parse code so that it can handle VM
** descriptions of the form "2-2n" (as used in some supplements).
** Currently, a VM of "2-2n" will be represented internally as "2-n".
** Also added preload of a few essential attribute descriptions into
** the data dictionary (e.g. Item and ItemDelimitation tags).
**
** Revision 1.7  1996/09/18 16:37:26  hewett
** Added capability to search data dictionary by tag name.
**
** Revision 1.6  1996/04/18 09:51:00  hewett
** White space is now being stripped from data dictionary fields.  Previously
** a tag name could retain trailing whitespace which caused silly results
** when generating dcdeftag.h (e.g. tag names wil trailing underscores).
**
** Revision 1.5  1996/03/20 16:44:04  hewett
** Updated for revised data dictionary.  Repeating tags are now handled better.
** A linear list of repeating tags has been introduced with a subset ordering
** mechanism to ensure that dictionary searches locate the most precise
** dictionary entry.
**
** Revision 1.4  1996/03/12 15:21:22  hewett
** The repeating sub-dictionary has been split into a repeatingElement and
** a repeatingGroups dictionary.  This is a temporary measure to reduce the
** problem of overlapping dictionary entries.  A full solution will require
** more radical changes to the data dictionary insertion and search
** mechanims.
**
** Revision 1.3  1996/01/09 11:06:44  andreas
** New Support for Visual C++
** Correct problems with inconsistent const declarations
** Correct error in reading Item Delimitation Elements
**
** Revision 1.2  1996/01/05 13:27:34  andreas
** - changed to support new streaming facilities
** - unique read/write methods for file and block transfer
** - more cleanups
**
** Revision 1.1  1995/11/23 17:02:39  hewett
** Updated for loadable data dictionary.  Some cleanup (more to do).
**
*/
