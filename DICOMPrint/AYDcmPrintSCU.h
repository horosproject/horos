/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#ifndef AYDCMPRINTSCU_H
#define AYDCMPRINTSCU_H

#include "AYPrintManager.h"

#include <time.h>
#include <iostream>
#include <string>
#include <vector>
using namespace std;

#include "dcdatset.h"
#include "ofstd.h"
#include "dctk.h"

#include <xercesc/parsers/XercesDOMParser.hpp>
#include <xercesc/dom/DOM.hpp>
#include <xercesc/sax/HandlerBase.hpp>
#include <xercesc/util/XMLString.hpp>
XERCES_CPP_NAMESPACE_USE




/**
 * 
 */
class AYDcmPrintSCU
{
  public:

    enum
    {
      NO_ERROR = 0,

      // configfile errors
      CONFIGFILE_NOT_DEFINED_ERROR,              // No configfile defined from calling application
      CONFIGFILE_NOT_FOUND_ERROR,                // The specified configfile does not exist
      CONFIGFILE_READ_ERROR,                     // The specified configfile could not be opened
      XML_PARSER_INITIALIZATION_ERROR,           // Error while initializing the xml library
      XML_PARSER_XML_ERROR,                      // Error while parsing the configfile

      // errors in connection parameters
      INVALID_HOST_ERROR,                        // The configured hostname or IP address was not valid
      INVALID_PORT_ERROR,                        // The configured port number was not valid
      INVALID_AETITLE_SENDER_ERROR,              // The configured AE title for the sender was not valid
      INVALID_AETITLE_RECEIVER_ERROR,            // The configured AE title for the receiver was not valid

      // missing general tags in configfile
      NO_ASSOCIATION_FOUND_ERROR,                // No association tag found in configfile
      NO_FILMSESSION_FOUND_ERROR,                // No film session tag found inside the association tag
      NO_FILMBOX_FOUND_ERROR,                    // No film box tag found inside the film session tag
      NO_IMAGEBOX_FOUND_ERROR,                   // No image box tags found inside the active film box

      // association errors
      OPEN_ASSOCIATION_ERROR,                    // There was an error during association negotiation
      CLOSE_ASSOCIATION_ERROR,                   // Error while closing the active association

      // film session specific errors
      FILMSESSION_CREATE_REQUEST_ERROR,          // Error while sending the N-CREATE request for film session
      REQUEST_MEMORY_ALLOCATION_FAILED,          // The SCP could not allocate the requested memory
      FILMSESSION_ACTION_REQUEST_ERROR,          // Error while sending the N-ACTION request for film session
      FILMSESSION_DELETE_REQUEST_ERROR,          // Error while sending the N-DELETE request for film session

      // film box specific errors
      NO_IMAGE_DISPLAY_FORMAT_ERROR,             // Attribute 'image display format' was not found in the processed film box
      FILMBOX_CREATE_REQUEST_ERROR,              // Error while sending the N-CREATE request for film box
      INVALID_SCP_RESPONSE,                      // The response from SCP has not the expected content
      FILMBOX_ACTION_REQUEST_ERROR,              // Error while sending the N-ACTION request for film box
      FILMBOX_DELETE_REQUEST_ERROR,              // Error while sending the N-DELETE request for film box

      // global errors
      NO_SUCH_ATTRIBUTE,                         // The SCP does not support at least one attribute in dataset
      INVALID_ATTRIBUTE_VALUE,                   // The SCP does not support the value for at least on attribute in dataset
      MISSING_ATTRIBUTE,                         // A mandatory attribute is missing in dataset
      UNSUPPORTED_ACTION_REQUEST,                // 
      RESOURCE_LIMITATION,                       //
      PRINT_QUEUE_FULL,                          //
      IMAGE_SIZE_TO_LARGE,                       //
      INSUFFICENT_MEMORY_ON_PRINTER,             //
      FILMSESSION_PRINTING_NOT_SUPPORTED,        //
      LAST_FILMBOX_NOT_PRINTED_YET,              //
      UNKNOWN_DIMSE_STATUS,                      //

			// errors while setting pixel data 
			// from dicom file to image box
      INVALID_DICOM_FILE_PATH,
      READ_DICOM_FILE_ERROR,
      IMAGE_BOX_SET_REQUEST_ERROR,
      READ_ATTRIBUTE_ERROR,
      SET_ATTRIBUTE_ERROR
    };

    enum
    {
      LOG_INIT,
      LOG_ERROR,
      LOG_WARNING,
      LOG_INFO,
      LOG_VERBOSE,
      LOG_DEBUG
    };


    /**
     * Constructor.
     * @param logpath Directory where the logfiles should be written to. NULL sets logging to stderr.
     * @param loglevel Loglevel which should be logged (Default is LOG_ERROR).
     */
    AYDcmPrintSCU(const char *logpath = NULL, int loglevel = LOG_ERROR, const char *basename = NULL);


    /**
     * Destructor.
     */
    ~AYDcmPrintSCU();


    /**
     * This is the main method which has to be called from a program to trigger the
     * print SCU. The only parameter is the configfile with all information about
     * the printjob.
     * @param configfile Absolute path to the configfile.
     * @return Errorstatus
     */
    int sendPrintjob(const char *configfile);


  private:

    /**  */
    XercesDOMParser *m_pParser;

    /**  */
    AYPrintManager *m_pPrintManager;


    // Association parameters
    string m_sHostname;
    int m_nPort;
    string m_sAETitleSender;
    string m_sAETitleReceiver;
    int m_nMaxPDUSize;
    bool m_bUseColorPrinting;
    bool m_bUseAnnotationBoxes;
    bool m_bUsePresentationLUT;
    bool m_bUseFilmSessionActionRequest;

    // Printer information
    string sPrinterStatus;
    string sPrinterStatusInfo;
    string sPrinterName;
    string Manufacturer;
    string ManufacturersModelName;
    string DeviceSerialNumber;
    string SoftwareVersion;
    string sDateOfLastCalibration;
    string sTimeOfLastCalibration;

    // Logging parameters
    string m_sLogpath;
    string m_sLogfileBasename;
    int m_nLoglevel;

    ostream *stdlogger;
    ostream *joblogger;
    ostream *dumplogger;

    ofstream *stdlogfile;
    ofstream *joblogfile;
    ofstream *dumplogfile;


    /**
     * Reads the configfile with printjob information and parses the XML.
     * @param configfile Absolute path to the configfile.
     * @return Errorstatus
     */
    int parseXMLConfigfile(const char *configfile);


    /**
     *
     */
    int openAssociation(DOMNode *pAssociation);


    /**
     *
     */
    int closeAssociation();


    /**
     *
     */
    int processFilmSession(DOMNode *pFilmSession);


    /**
     *
     */
    int processFilmBox(DOMNode *pXMLFilmBox, OFString sReferencedFilmSessionInstanceUID, int &nImageCounter);


    /**
     * Reads the association parameters from the XML node
     * pNode and sets them to the attributes.
     * @param pNode XML node from the configuration which represents an association.
     * @return Errorstatus (NO_ERROR if all association parameters are valid.)
     */
    int setAssociationParameters(DOMNode *pNode);


    /**
     *
     */
    int addFilmSessionParameters(DOMNode *pNode, DcmDataset *pDataset);


    /**
     *
     */
    int addFilmBoxParameters(DOMNode *pNode, DcmDataset *pDataset);


    /**
     *
     */
    int addImageBoxParameters(DOMNode *pNode, DcmDataset *pDataset);


    /**
     * Checks if a string value is an integer.
     * @param sValue String value to check.
     * @return true if sValue is an integer. false if not.
     */
    bool isInteger(string sValue);


    /**
     * Checks if pNode contains an attribute with name sAttrName.
     * @param pNode XML node to be checked for the attribute.
     * @param sAttrName Name of the attribute which is searched.
     * @return true if attribute exists in pNode, false otherwise.
     */
    bool isXMLAttributeAvailable(DOMNode *pNode, string sAttrName);


    /**
     * Returns the value of attribute with name sAttrName.
     * @param pNode XML node to be checked for the attribute.
     * @param sAttrName Name of the attribute which is searched.
     * @return String containing the value of the attribute.
     */
    string getXMLAttributeValue(DOMNode *pNode, string sAttributeName);


    /**
     * Checks if a DICOM tag with key oKey is available in pDataset.
     * @param pDataset Pointer to a DICOM dataset which should be checked.
     * @param oKey Key of the attribute which should be searched.
     * @return true if attribute exists in pDataset, false otherwise.
     */
    bool isDicomAttributeAvailable(DcmDataset *pDataset, DcmTagKey oKey);


    /**
     * Searchs for an attribute with key oKey in pDataset and returns its value as a string.
     * @param pDataset Pointer to a DICOM dataset which contains the attribute.
     * @param oKey Key of the attribute which should be searched.
     * @return String containing the value of the attribute.
     */
    string getDicomAttributeValue(DcmDataset *pDataset, DcmTagKey oKey);


    /**
     * Searchs for an attribute with key oKey in DICOM dataset pDataset and the XML node pNode
     * and writes the found attribute to the DICOM item pItem. The value in pNote has a higher priority
     * than the value in pDataset. Optional attributes are added if they are available at least in one
     * of the sources. Missing mandatory attributes force an error if they don't exist in both sources.
     * @param pDataset Pointer to a DICOM dataset with information for this image box.
     * @param oKey Key of the attribute which should be searched and added.
     * @param pNode XML node with config information for this image box.
     * @param sAttrName Name of the attribute which should be searched and added.
     * @param pItem Pointer to the final DICOM object containing the new image box.
     * @param bIsMandatory Flag, which has to be set if the attribute is a mandatory attribute.
     * @return Error status. Possible values:
     *         - NO_ERROR
     *           No error occured. Attribute has been successfully added or it was an
     *           optional attribute and not found in one of the sources.
     *         - SET_ATTRIBUTE_ERROR
     *           An error occured while adding the attribute to the new item.
     *         - MISSING_ATTRIBUTE_ERROR
     *           The attribute was flaged as mandatory but not found in one of the sources
     */
    int addImageBoxAttribute(DcmDataset *pDataset, DcmTagKey oKey, DOMNode *pNode, string sAttrName, DcmItem *pItem, bool bIsMandatory);


    /**
     * Returns a formatted string with the current date and time.
     * @return Formatted time string in the form YYYYMMDD.HHMMSS
     */
    string timestring(bool bAddSeparator=true);


    /**
     *
     */
    int decodeDimseStatus(unsigned int unStatus, string sRequest);

};

#endif
