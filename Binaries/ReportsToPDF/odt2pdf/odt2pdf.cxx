/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

// with thanks to http://moutou.pagesperso-orange.fr/MyUNODoc_HTML/UNOCppAPI4.html

#include <stdio.h>
#include <wchar.h>

#include <sal/main.h>

#include <cppuhelper/bootstrap.hxx>

#include <osl/file.hxx>
#include <osl/process.h>
#include <rtl/process.h>

#include <com/sun/star/beans/XPropertySet.hpp>
#include <com/sun/star/uno/XComponentContext.hpp>
#include <com/sun/star/frame/XComponentLoader.hpp>
#include <com/sun/star/frame/XStorable.hpp>
#include <com/sun/star/lang/XMultiServiceFactory.hpp>
#include <com/sun/star/lang/XMultiComponentFactory.hpp>
#include <com/sun/star/connection/XConnector.hpp>
#include <com/sun/star/bridge/XUnoUrlResolver.hpp>
#include <com/sun/star/util/XModifiable.hpp>
#include <com/sun/star/util/XCloseable.hpp>
#include <com/sun/star/container/XEnumerationAccess.hpp>
#include <com/sun/star/frame/XDesktop.hpp>

#include <string.h>

using namespace com::sun::star::uno;
using namespace com::sun::star::lang;
using namespace com::sun::star::beans;
using namespace com::sun::star::bridge;
using namespace com::sun::star::frame;
using namespace com::sun::star::connection;
using namespace com::sun::star::util;
using namespace com::sun::star::container;

using ::rtl::OString;
using ::rtl::OUString;
using ::rtl::OUStringToOString;

//============================================================================
// from http://wiki.services.openoffice.org/wiki/UNO_automation_with_a_binary_%28executable%29

Reference<XMultiServiceFactory> ooConnect(const OUString& sConnectionString) {
    // create the initial component context
    Reference<XComponentContext> rComponentContext = ::cppu::defaultBootstrap_InitialComponentContext();
    
    // retrieve the servicemanager from the context
    Reference<XMultiComponentFactory> rServiceManager = rComponentContext->getServiceManager();
    
    // instantiate a sample service with the servicemanager.
    Reference<XInterface> rInstance = rServiceManager->createInstanceWithContext(OUString::createFromAscii("com.sun.star.bridge.UnoUrlResolver" ), rComponentContext);
    
    // Query for the XUnoUrlResolver interface
    Reference<XUnoUrlResolver> rResolver(rInstance, UNO_QUERY);
    if (!rResolver.is()) {
        printf("Error: Couldn't instantiate com.sun.star.bridge.UnoUrlResolver service\n");
        return NULL;
    }
    
    try {
        // resolve the uno-url
        rInstance = rResolver->resolve(sConnectionString);
        
        if (!rInstance.is()) {
            printf("StarOffice.ServiceManager is not exported from remote counterpart\n");
            return NULL;
        }
        
        // query for the simpler XMultiServiceFactory interface, sufficient for scripting
        Reference<XMultiServiceFactory> rOfficeServiceManager(rInstance, UNO_QUERY);
        
        if (!rOfficeServiceManager.is()) {
            printf("XMultiServiceFactory interface is not exported for StarOffice.ServiceManager\n");
            return NULL;
        }
        
        return rOfficeServiceManager;
    } catch (Exception& e) {
        printf("Error: %s\n", OUStringToOString(e.Message, RTL_TEXTENCODING_UTF8).pData->buffer);
    }
    
    return NULL;
}

//============================================================================
SAL_IMPLEMENT_MAIN_WITH_ARGS(argc, argv) {
    sal_Int32 nCount = (sal_Int32)rtl_getAppCommandArgCount();
    if (nCount < 2) {
        printf("Usage: odt2pdf -env:URE_MORE_TYPES=<office_types_rdb_url> <in_odt_path> <out_pdf_path> [connection_string]\n");
        exit(1);
    }
    
    // build paths
	
    OUString sWorkingDir;
    osl_getProcessWorkingDir(&sWorkingDir.pData);
    
	OUString sOdtPath, sPdfPath;
	rtl_getAppCommandArg(0, &sOdtPath.pData);
	rtl_getAppCommandArg(1, &sPdfPath.pData);
    
    OUString sAbsoluteOdtUrl, sAbsolutePdfUrl, ouStr;
    osl::FileBase::getFileURLFromSystemPath(sOdtPath, ouStr);
    osl::FileBase::getAbsoluteFileURL(sWorkingDir, ouStr, sAbsoluteOdtUrl);
    osl::FileBase::getFileURLFromSystemPath(sPdfPath, ouStr);
    osl::FileBase::getAbsoluteFileURL(sWorkingDir, ouStr, sAbsolutePdfUrl);
    
    OUString connectionString = OUString::createFromAscii("uno:socket,host=localhost,port=2083;urp;StarOffice.ServiceManager");
    if (nCount >= 3)
        rtl_getAppCommandArg(2, &connectionString.pData);
    
    // Connect to soffice
    
    Reference<XMultiServiceFactory> rOfficeServiceManager = ooConnect(connectionString);
    if (!rOfficeServiceManager.is()) {
        return 1;
    }
    
    printf("Successfully connected to the office\n");

    // get the desktop service using createInstance returns an XInterface type
    Reference<XInterface> xDesktopInterface = rOfficeServiceManager->createInstance(OUString::createFromAscii("com.sun.star.frame.Desktop"));
    Reference<XDesktop> xDesktop(xDesktopInterface, UNO_QUERY);
    
    // query for the XComponentLoader interface
    Reference<XComponentLoader> rComponentLoader(xDesktopInterface, UNO_QUERY);
    if (!rComponentLoader.is() ){
        printf("Couldn't instantiate Desktop XComponentLoader\n" );
        return 1;
    }
    
    bool documentWasAlreadyOpen = false;
    Reference<XComponent> xComponent;
    
    // Find the component
    Reference<XEnumerationAccess> xAlreadyOpenComponents = xDesktop->getComponents();
    if (xAlreadyOpenComponents->hasElements()) {
        Reference<XEnumeration> xAlreadyOpenComponentsEnumeration(xAlreadyOpenComponents->createEnumeration(), UNO_QUERY);
        while (xAlreadyOpenComponentsEnumeration->hasMoreElements()) {
            Reference<XComponent> xEnumeratedComponent(xAlreadyOpenComponentsEnumeration->nextElement(), UNO_QUERY);
            Reference<XStorable> xStoreable(xEnumeratedComponent, UNO_QUERY);
            if (xStoreable.is() && xStoreable->hasLocation()) {
                OUString sLocation = xStoreable->getLocation();
                if (xStoreable->getLocation().equals(sAbsoluteOdtUrl)) {
                    documentWasAlreadyOpen = true;
                    xComponent = xEnumeratedComponent;
                }
            }
            
        }
    }
    
    if (!documentWasAlreadyOpen) {
        // Open the file
        printf("Opening %s...\n", OUStringToOString(sOdtPath, RTL_TEXTENCODING_UTF8).pData->buffer);
        xComponent = rComponentLoader->loadComponentFromURL(sAbsoluteOdtUrl, OUString::createFromAscii("_default"), 0, Sequence<PropertyValue>());
    } else {
        printf("Document was already open: %s\n", OUStringToOString(sOdtPath, RTL_TEXTENCODING_UTF8).pData->buffer);
    }
    
    // Save as PDF
    
    printf("Saving PDF as %s\n", OUStringToOString(sPdfPath, RTL_TEXTENCODING_UTF8).pData->buffer);
    
    Sequence<PropertyValue> storeToUrlArgs(2);
    storeToUrlArgs[0].Name = OUString::createFromAscii("Overwrite");
    storeToUrlArgs[0].Value <<= (sal_Bool)true;
    storeToUrlArgs[1].Name = OUString::createFromAscii("FilterName");
    storeToUrlArgs[1].Value <<= OUString::createFromAscii("writer_pdf_Export"); // should be calc_pdf_Export for (xls, xlsb, ods) and impress_pdf_Export for (ppt, pptx, odp)
    
    Reference<XStorable> xStorable(xComponent, UNO_QUERY);
    xStorable->storeToURL(sAbsolutePdfUrl, storeToUrlArgs);
    
    // If we opened the file, we close it too
    
    if (!documentWasAlreadyOpen) {
        Reference<XModifiable> xModifiable(xComponent, UNO_QUERY);
        if ((xModifiable.is() && !xModifiable->isModified()) || !xModifiable.is()) {
            Reference<XCloseable> xCloseable(xComponent, UNO_QUERY);
            if (xCloseable.is())
                xCloseable->close(false);
            else xComponent->dispose();
        }
    }
    
    return 0;
}

/* vim:set shiftwidth=4 softtabstop=4 expandtab: */
