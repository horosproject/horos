/*
**
** Author: Andrew Hewett, medigration GmbH
**
** Module: extneg.cc
**
** Purpose:
**   Extended Negotiation for A-ASSOCIATE
**
** Last Update:         $Author: lpysher $
** Update Date:         $Date: 2006/03/01 20:15:50 $
** Source File:         $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmnet/extneg.cc,v $
** CVS/RCS Revision:    $Revision: 1.1 $
** Status:              $State: Exp $
**
** CVS/RCS Log at end of file
**
*/


#include "osconfig.h" /* make sure OS specific configuration is included first */
#include "extneg.h"


void appendList(const SOPClassExtendedNegotiationSubItemList& from, SOPClassExtendedNegotiationSubItemList& to)
{
    OFListConstIterator(SOPClassExtendedNegotiationSubItem*) i = from.begin();
    while (i != from.end()) {
        to.push_back(*i);
        ++i;
    }
}

void deleteListMembers(SOPClassExtendedNegotiationSubItemList& lst)
{
    OFListIterator(SOPClassExtendedNegotiationSubItem*) i = lst.begin();
    while (i != lst.end()) {
		delete[] (*i)->serviceClassAppInfo;
		(*i)->serviceClassAppInfo = NULL;
        delete *i;
        ++i;
    }
    lst.clear();
}


/*
** CVS/RCS Log:
** $Log: extneg.cc,v $
** Revision 1.1  2006/03/01 20:15:50  lpysher
** Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
**
** Revision 1.5  2005/12/08 15:44:54  meichel
** Changed include path schema for all DCMTK header files
**
** Revision 1.4  2004/02/04 15:33:48  joergr
** Removed acknowledgements with e-mail addresses from CVS log.
**
** Revision 1.3  2003/06/12 18:25:20  joergr
** Modified code to use const_iterators where appropriate (required for STL).
**
** Revision 1.2  2003/06/02 16:44:11  meichel
** Renamed local variables to avoid name clashes with STL
**
** Revision 1.1  1999/04/19 08:40:03  meichel
** Added experimental support for extended SOP class negotiation.
**
**
*/
