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

#import "DCMObject.h"
#import "DCM.h"
#import "DCMAbstractSyntaxUID.h"
#import <Accelerate/Accelerate.h>
#import "DCMCharacterSet.h"

static NSString *DCM_SecondaryCaptureImageStorage = @"1.2.840.10008.5.1.4.1.1.7";
static NSString *rootUID = @"1.3.6.1.4.1.19291.2.1";
static NSString *uidQualifier = @"99";
static NSString *implementationName = @"OSIRIX";
static NSString *softwareVersion = @"001";
static unsigned int globallyUnique = 1;
static NSString *macAddress = nil;

void exitOsiriX(void)
{
	[NSException raise: @"JPEG error exception raised" format: @"JPEG error exception raised - See Console.app for error message"];
}

#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>

static kern_return_t FindEthernetInterfaces(io_iterator_t *matchingServices);
static kern_return_t GetMACAddress(io_iterator_t intfIterator, UInt8 *MACAddress, UInt8 bufferSize);

// Returns an iterator containing the primary (built-in) Ethernet interface. The caller is responsible for
// releasing the iterator after the caller is done with it.
static kern_return_t FindEthernetInterfaces(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    CFMutableDictionaryRef	matchingDict;
    CFMutableDictionaryRef	propertyMatchDict;
    
    // Ethernet interfaces are instances of class kIOEthernetInterfaceClass. 
    // IOServiceMatching is a convenience function to create a dictionary with the key kIOProviderClassKey and 
    // the specified value.
    matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);

    // Note that another option here would be:
    // matchingDict = IOBSDMatching("en0");
        
    if (NULL == matchingDict) {
        printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
        // Each IONetworkInterface object has a Boolean property with the key kIOPrimaryInterface. Only the
        // primary (built-in) interface has this property set to TRUE.
        
        // IOServiceGetMatchingServices uses the default matching criteria defined by IOService. This considers
        // only the following properties plus any family-specific matching in this order of precedence 
        // (see IOService::passiveMatch):
        //
        // kIOProviderClassKey (IOServiceMatching)
        // kIONameMatchKey (IOServiceNameMatching)
        // kIOPropertyMatchKey
        // kIOPathMatchKey
        // kIOMatchedServiceCountKey
        // family-specific matching
        // kIOBSDNameKey (IOBSDNameMatching)
        // kIOLocationMatchKey
        
        // The IONetworkingFamily does not define any family-specific matching. This means that in            
        // order to have IOServiceGetMatchingServices consider the kIOPrimaryInterface property, we must
        // add that property to a separate dictionary and then add that to our matching dictionary
        // specifying kIOPropertyMatchKey.
            
        propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
													  &kCFTypeDictionaryKeyCallBacks,
													  &kCFTypeDictionaryValueCallBacks);
    
        if (NULL == propertyMatchDict) {
            printf("CFDictionaryCreateMutable returned a NULL dictionary.\n");
        }
        else {
            // Set the value in the dictionary of the property with the given key, or add the key 
            // to the dictionary if it doesn't exist. This call retains the value object passed in.
            CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue); 
            
            // Now add the dictionary containing the matching value for kIOPrimaryInterface to our main
            // matching dictionary. This call will retain propertyMatchDict, so we can release our reference 
            // on propertyMatchDict after adding it to matchingDict.
            CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
            CFRelease(propertyMatchDict);
        }
    }
    
    // IOServiceGetMatchingServices retains the returned iterator, so release the iterator when we're done with it.
    // IOServiceGetMatchingServices also consumes a reference on the matching dictionary so we don't need to release
    // the dictionary explicitly.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, matchingServices);    
    if (KERN_SUCCESS != kernResult) {
        printf("IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
    }
        
    return kernResult;
}
    
// Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
// If no interfaces are found the MAC address is set to an empty string.
// In this sample the iterator should contain just the primary interface.
static kern_return_t GetMACAddress(io_iterator_t intfIterator, UInt8 *MACAddress, UInt8 bufferSize)
{
    io_object_t		intfService;
    io_object_t		controllerService;
    kern_return_t	kernResult = KERN_FAILURE;
    
    // Make sure the caller provided enough buffer space. Protect against buffer overflow problems.
	if (bufferSize < kIOEthernetAddressSize) {
		return kernResult;
	}
	
	// Initialize the returned address
    bzero(MACAddress, bufferSize);
    
    // IOIteratorNext retains the returned object, so release it when we're done with it.
    while ((intfService = IOIteratorNext(intfIterator)))
    {
        CFTypeRef	MACAddressAsCFData;        

        // IONetworkControllers can't be found directly by the IOServiceGetMatchingServices call, 
        // since they are hardware nubs and do not participate in driver matching. In other words,
        // registerService() is never called on them. So we've found the IONetworkInterface and will 
        // get its parent controller by asking for it specifically.
        
        // IORegistryEntryGetParentEntry retains the returned object, so release it when we're done with it.
        kernResult = IORegistryEntryGetParentEntry(intfService,
												   kIOServicePlane,
												   &controllerService);
		
        if (KERN_SUCCESS != kernResult) {
            printf("IORegistryEntryGetParentEntry returned 0x%08x\n", kernResult);
        }
        else {
            // Retrieve the MAC address property from the I/O Registry in the form of a CFData
            MACAddressAsCFData = IORegistryEntryCreateCFProperty(controllerService,
																 CFSTR(kIOMACAddress),
																 kCFAllocatorDefault,
																 0);
            if( MACAddressAsCFData)
			{
				UInt8 tempMac[ kIOEthernetAddressSize];
				
                // Get the raw bytes of the MAC address from the CFData
                CFDataGetBytes(MACAddressAsCFData, CFRangeMake(0, kIOEthernetAddressSize), tempMac);
                CFRelease(MACAddressAsCFData);
				
				if( tempMac[ 5] + 256*tempMac[ 4] > MACAddress[ 5] + 256*MACAddress[ 4])
				{
					MACAddress[0] = tempMac[ 0];
					MACAddress[1] = tempMac[ 1];
					MACAddress[2] = tempMac[ 2];
					MACAddress[3] = tempMac[ 3];
					MACAddress[4] = tempMac[ 4];
					MACAddress[5] = tempMac[ 5];
				}
            }
			
            // Done with the parent Ethernet controller object so we release it.
            (void) IOObjectRelease(controllerService);
        }
        
        // Done with the Ethernet interface object so we release it.
        (void) IOObjectRelease(intfService);
    }
        
    return kernResult;
}

static NSString* getMacAddress( void)
{
    kern_return_t	kernResult = KERN_SUCCESS; // on PowerPC this is an int (4 bytes)
/*
 *	error number layout as follows (see mach/error.h and IOKit/IOReturn.h):
 *
 *	hi		 		       lo
 *	| system(6) | subsystem(12) | code(14) |
 */

    io_iterator_t	intfIterator;
    UInt8			MACAddress[kIOEthernetAddressSize];
	NSString		*result = nil;
	
    kernResult = FindEthernetInterfaces(&intfIterator);
    
    if (KERN_SUCCESS != kernResult)
	{
        printf("FindEthernetInterfaces returned 0x%08x\n", kernResult);
    }
    else
	{
        kernResult = GetMACAddress(intfIterator, MACAddress, sizeof(MACAddress));
        
        if (KERN_SUCCESS != kernResult)
		{
            printf("GetMACAddress returned 0x%08x\n", kernResult);
        }
		else
		{
			result = [NSString stringWithFormat: @"%02x:%02x:%02x:%02x:%02x:%02x", MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]];
		}
    }
    
    (void) IOObjectRelease(intfIterator);	// Release the iterator.
    
    return result;
}

static NSString* getMacAddressNumber( void)
{
    kern_return_t	kernResult = KERN_SUCCESS; // on PowerPC this is an int (4 bytes)
    /*
     *	error number layout as follows (see mach/error.h and IOKit/IOReturn.h):
     *
     *	hi		 		       lo
     *	| system(6) | subsystem(12) | code(14) |
     */
    
    io_iterator_t	intfIterator;
    UInt8			MACAddress[kIOEthernetAddressSize];
	NSString		*result = nil;
	
    kernResult = FindEthernetInterfaces(&intfIterator);
    
    if (KERN_SUCCESS != kernResult)
	{
        printf("FindEthernetInterfaces returned 0x%08x\n", kernResult);
    }
    else
	{
        kernResult = GetMACAddress(intfIterator, MACAddress, sizeof(MACAddress));
        
        if (KERN_SUCCESS != kernResult)
		{
            printf("GetMACAddress returned 0x%08x\n", kernResult);
            result = @"0";
        }
		else
		{
			result = [NSString stringWithFormat: @"%d%d%d%d%d%d", MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]];
		}
    }
    
    (void) IOObjectRelease(intfIterator);	// Release the iterator.
    
    return result;
}

@implementation DCMObject

@synthesize pixelDataIsDecoded = _decodePixelData;
@synthesize transferSyntax;
@synthesize specificCharacterSet;
@synthesize attributes, isSequence;

+ (BOOL)isDICOM:(NSData *)data{
	//int position = 128;
	if( [data length] < 132) return NO;
	unsigned char *string = (unsigned char *)[data bytes];
	//unsigned char *string2 = string + 128;
	//NSLog(@"dicom at 128: %@" , [NSString  stringWithUTF8String:string2 length:4]);
	if (string[128] == 'D' && string[129] == 'I'&& string[130] == 'C' && string[131] == 'M')
		return YES;
	return NO;
}

+ (NSString *)rootUID{
	return rootUID;
}

+ (NSString *)implementationClassUID{
	return [NSString stringWithFormat:@"%@.%@.1", rootUID, uidQualifier];
}

+ (NSString *)implementationVersionName{
	return [NSString stringWithFormat:@"%@%@", implementationName, softwareVersion];
}

+ (id)dcmObject{
	return [[[DCMObject alloc] init] autorelease];
}

+ (BOOL)anonymizeContentsOfFile:(NSString *)file  tags:(NSArray *)tags  writingToFile:(NSString *)destination
{
	DCMObject *object = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
	
	[object removePrivateTags];
	
	//get rid of some other tags containing addresses and phone numbers
	if ([object attributeValueWithName:@"InstitutionAddress"])
		[object setAttributeValues:[NSMutableArray array] forName:@"InstitutionAddress"];
	if ([object attributeValueWithName:@"PatientsAddress"])
		[object setAttributeValues:[NSMutableArray array] forName:@"PatientsAddress"];
	if ([object attributeValueWithName:@"PatientsTelephoneNumbers"])
		[object setAttributeValues:[NSMutableArray array] forName:@"PatientsTelephoneNumbers"];
	
	for (NSArray* tagArray in tags) {
		DCMAttributeTag* tag = [tagArray objectAtIndex:0];
		
		id value = nil;
		if ([tagArray count] > 1)
			value = [tagArray objectAtIndex:1];
		
	//	NSLog(@"anonymizing %@, was %@", [tag name], [[object attributeForTag:tag] valuesAsString]);
		
		if ([tag.name isEqualToString: @"StudyInstanceUID"]) {
			DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:tag vr: tag.vr values: [NSMutableArray arrayWithObject: value]];
			[[object attributes] setObject:attr forKey: tag.stringValue];
		} else
			[object anonymizeAttributeForTag:tag replacingWith:value];
		
		//NSLog( [value description] );
		if ([tag.name isEqualToString: @"PatientID"])
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"OtherPatientIDs"] replacingWith:value];
			
		if ([tag.name isEqualToString: @"InstanceCreationDate"]) {
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"ContentDate"] replacingWith:value];
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionDate"] replacingWith:value];
		}
		
		if ([tag.name isEqualToString: @"InstanceCreationTime"]) {
			NSLog(@"InstanceCreationTime");
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"ContentTime"] replacingWith:value];
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionTime"] replacingWith:value];
		}
		
		if ([tag.name isEqualToString: @"AcquisitionDatetime"] ) {
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionDate"] replacingWith:value];
			[object anonymizeAttributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionTime"] replacingWith:value];
		}
	}
	
	if (DCMDEBUG)
		NSLog(@"TransferSyntax: %@", object.transferSyntax );
	
//	[object newStudyInstanceUID];
//	[object newSeriesInstanceUID];
//	[object newSOPInstanceUID];

	DCMTransferSyntax *ts = object.transferSyntax;
	if (!ts.isExplicit ) ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	return [object  writeToFile:destination withTransferSyntax:ts quality: DCMLosslessQuality atomically:YES];
}

+ (id)secondaryCaptureObjectFromTemplate:(DCMObject *)object{
	//NSLog(@"Secondary capture");
	DCMObject *scObject = [[object copy] autorelease];
	NSMutableDictionary *attrs = [scObject attributes];
	NSMutableArray *keysToRemove = [NSMutableArray array];

	for ( NSString *key in attrs ) {
		DCMAttribute *attr = [attrs objectForKey:key];
		int element;
		if (attr) {
			if ( attr.attrTag.group == 0x0002 ) {
				//keep all metaheaders
			}
			else if ( attr.attrTag.group == 0x0008 ) {
				//keep these
				element = attr.attrTag.element;
				switch (element) {
					case 0x0005:
					case 0x0020:
					case 0x0030:
					case 0x0080:
					case 0x0081:
					case 0x0082:
					case 0x0090:
					case 0x0092:
					case 0x0094:
					case 0x0096:
					case 0x0116:
					case 0x0201:
					case 0x1010:
					case 0x1030:
					case 0x1040:
					case 0x1048:
					case 0x1049:
					case 0x1050:
					case 0x1052:
					case 0x1060:
					case 0x1062:
					case 0x1080:
					case 0x1084:
					case 0x1100:
					case 0x1110:
					case 0x1120:
					case 0x1125:
					case 0x2218:
					case 0x2220:
					case 0x2228:
					case 0x2229:
					case 0x2230:
							break;
					default: [keysToRemove addObject:key]; 
				}
			}
			else if ( attr.attrTag.group == 0x0010) {
				//keep these
				element = attr.attrTag.element;
				switch (element) {
					case 0x0010:
					case 0x0020:
					case 0x0021:
					case 0x0030:
					case 0x0032:
					case 0x0040:
					case 0x0050:
					case 0x0101:
					case 0x0102:
					case 0x1000:
					case 0x1001:
					case 0x1005:
					case 0x1010:
					case 0x1020:
					case 0x1030:
					case 0x1040:
					case 0x1060:
					case 0x1080:
					case 0x1081:
					case 0x1090:
					case 0x2000:
					case 0x2110:
					case 0x2150:
					case 0x2152:
					case 0x2154:
					case 0x2160:
					case 0x2180:
					case 0x21A0:
					case 0x21B0:
					case 0x21C0:
					case 0x21D0:
					case 0x21F0:
					case 0x4000:
							break;
					default: [keysToRemove addObject:key]; 
				}
			}
			else if ( attr.attrTag.group == 0x0020 ) {
				//keep these
				element = attr.attrTag.element;
				switch (element) {
					case 0x000D:
					case 0x0010:
					case 0x1070:
					case 0x1200:
					case 0x1202:
					case 0x1204:
					case 0x1206:
					case 0x1208:					
						break;
					default: [keysToRemove addObject:key]; 
				}

			}
			else	
				[keysToRemove addObject:key];
		} //if


		
	} //while 
	//attributes to add
	[attrs removeObjectsForKeys:keysToRemove];
	DCMAttributeTag *SOPClassUIDTag = [DCMAttributeTag tagWithName:@"SOPClassUID"];
	NSMutableArray *SOPClassUIDValue = [NSMutableArray arrayWithObject:DCM_SecondaryCaptureImageStorage];
	DCMAttribute *SOPClassUIDAttr = [DCMAttribute attributeWithAttributeTag:SOPClassUIDTag  vr: SOPClassUIDTag.vr  values:SOPClassUIDValue];
	[attrs setObject:SOPClassUIDAttr forKey:@"SOPClassUID"];
	NSMutableArray *mediaStorageSOPClassUIDValue = [NSMutableArray arrayWithObject:DCM_SecondaryCaptureImageStorage];
	DCMAttributeTag *mediaStorageSOPClassUIDTag = [DCMAttributeTag tagWithName:@"MediaStorageSOPClassUID"];
	DCMAttribute *mediaStorageSOPClassUIDAttr = [DCMAttribute attributeWithAttributeTag:mediaStorageSOPClassUIDTag  vr:[mediaStorageSOPClassUIDTag vr]  values:mediaStorageSOPClassUIDValue];
	[attrs setObject:mediaStorageSOPClassUIDAttr forKey:@"MediaStorageSOPClassUID"];
	
	//DCMAttributeTag *SOPClassUIDTag = [DCMAttributeTag tagWithName:@"SOPClassUID"];
	
	DCMAttributeTag *scDeviceIDTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceID"];
	NSMutableArray *scDeviceIDValue = [NSMutableArray arrayWithObject:  [DCMObject MACAddress]];
	DCMAttribute *scDeviceIDAttr = [DCMAttribute attributeWithAttributeTag:scDeviceIDTag  vr: scDeviceIDTag.vr  values:scDeviceIDValue];
	[attrs setObject:scDeviceIDAttr forKey:@"SecondaryCaptureDeviceID"];
	
	DCMAttributeTag *scManufacturerTag = [DCMAttributeTag tagWithName:@"Manufacturer"];
	NSMutableArray *scManufacturerValue = [NSMutableArray arrayWithObject:  @"Horos"];
	DCMAttribute *scManufacturerAttr = [DCMAttribute attributeWithAttributeTag:scManufacturerTag  vr: scManufacturerTag.vr  values:scManufacturerValue];
	[attrs setObject:scManufacturerAttr forKey:@"Manufacturer"];
	
	DCMAttributeTag *scDeviceManufacturerTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceManufacturer"];
	NSMutableArray *scDeviceManufacturerValue = [NSMutableArray arrayWithObject:@"Horos"];
	DCMAttribute *scDeviceManufacturerAttr = [DCMAttribute attributeWithAttributeTag:scDeviceManufacturerTag  vr: scDeviceManufacturerTag.vr values:scDeviceManufacturerValue];
	[attrs setObject:scDeviceManufacturerAttr forKey:@"SecondaryCaptureDeviceManufacturer"];
	
	DCMAttributeTag *scDeviceModelTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceManufacturersModelName"];
	NSMutableArray *scDeviceModelValue = [NSMutableArray arrayWithObject:@"Horos"];
	DCMAttribute *scDeviceModelAttr = [DCMAttribute attributeWithAttributeTag:scDeviceModelTag  vr: scDeviceModelTag.vr values:scDeviceModelValue];
	[attrs setObject:scDeviceModelAttr forKey:@"SecondaryCaptureDeviceManufacturersModelName"];
	
	DCMAttributeTag *scDeviceSoftwareTag = [DCMAttributeTag tagWithName:@"SecondaryCaptureDeviceSoftwareVersions"];
	NSMutableArray *scDeviceSoftwareValue = [NSMutableArray arrayWithObject: @"3.8"];
	DCMAttribute *scDeviceSoftwareAttr = [DCMAttribute attributeWithAttributeTag:scDeviceSoftwareTag  vr: scDeviceSoftwareTag.vr values:scDeviceSoftwareValue];
	[attrs setObject:scDeviceSoftwareAttr forKey:@"SecondaryCaptureDeviceSoftwareVersions"];
	
	DCMAttributeTag *scDateTag = [DCMAttributeTag tagWithName:@"DateofSecondaryCapture"];
	NSMutableArray *scDateValue = [NSMutableArray arrayWithObject:[DCMCalendarDate date]];
	DCMAttribute *scDateAttr = [DCMAttribute attributeWithAttributeTag:scDateTag  vr: scDateTag.vr values:scDateValue];
	[attrs setObject:scDateAttr forKey:@"DateofSecondaryCapture"];
	
	DCMAttributeTag *scTimeTag = [DCMAttributeTag tagWithName:@"TimeofSecondaryCapture"];
	NSMutableArray *scTimeValue = [NSMutableArray arrayWithObject:[DCMCalendarDate date]];
	DCMAttribute *scTimeAttr = [DCMAttribute attributeWithAttributeTag:scTimeTag  vr: scTimeTag.vr values:scTimeValue];
	[attrs setObject:scTimeAttr forKey:@"TimeofSecondaryCapture"];
	
	DCMAttributeTag *modalityTag = [DCMAttributeTag tagWithName:@"Modality"];
	NSMutableArray *modalityValue = [NSMutableArray arrayWithObject:@"SC"];
	DCMAttribute *modalityAttr = [DCMAttribute attributeWithAttributeTag:modalityTag  vr: modalityTag.vr values:modalityValue];
	[attrs setObject:modalityAttr forKey:@"Modality"];
	
	[scObject newSeriesInstanceUID];
	[scObject newSOPInstanceUID];
	[scObject updateMetaInformationWithTransferSyntax: scObject.transferSyntax aet:@"OsiriX"];
	return scObject;
}

+ (id)secondaryCaptureObjectWithBitDepth:(int)bitDepth  samplesPerPixel:(int)spp numberOfFrames:(int)nff{
	DCMObject *scObject = [[[DCMObject alloc] init] autorelease];
	NSString *abstractSyntax;
	//NSLog(@"Number Frames for SC: %d", nff);
	if (nff > 1) {
		if	(spp > 1)
			abstractSyntax = [DCMAbstractSyntaxUID multiframeTrueColorSecondaryCaptureImageStorage];
		else if (bitDepth < 8)
			abstractSyntax = [DCMAbstractSyntaxUID multiframeSingleBitSecondaryCaptureImageStorage];
		else if (bitDepth == 8)
			abstractSyntax = [DCMAbstractSyntaxUID multiframeGrayscaleByteSecondaryCaptureImageStorage];
		else
			abstractSyntax = [DCMAbstractSyntaxUID multiframeGrayscaleWordSecondaryCaptureImageStorage];
	}
	else
		abstractSyntax = [DCMAbstractSyntaxUID secondaryCaptureImageStorage];
	//secondary capture tags	
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:abstractSyntax] forName:@"SOPClassUID"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:abstractSyntax] forName:@"MediaStorageSOPClassUID"];	
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: @"Horos"]  forName:@"Manufacturer"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: [DCMObject MACAddress]]  forName:@"SecondaryCaptureDeviceID"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: @"Horos"]  forName:@"SecondaryCaptureDeviceManufacturer"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: @"Horos"]  forName:@"SecondaryCaptureDeviceManufacturersModelName"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: @"3.8"]  forName:@"SecondaryCaptureDeviceSoftwareVersions"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: [DCMCalendarDate date]]  forName:@"DateofSecondaryCapture"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: [DCMCalendarDate date]]  forName:@"TimeofSecondaryCapture"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject: @"SC"]  forName:@"Modality"];
	//[scObject setAttributeValues:[NSMutableArray arrayWithObject:@"SC"]  forName:@"Modality"];
	//new UIDs
	[scObject newStudyInstanceUID];
	[scObject newSeriesInstanceUID];
	[scObject newSOPInstanceUID];
	
	[scObject updateMetaInformationWithTransferSyntax: [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] aet:@"osirix"];
	//Patient Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
	[scObject setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
	//Study Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"StudyID"];
	[scObject setAttributeValues:[NSMutableArray array] forName:@"StudyDescription"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"StudyDate"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"StudyTime"];
	//Series Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"SeriesDescription"];
	[scObject setAttributeValues:[NSMutableArray array] forName:@"SeriesNumber"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"SeriesDate"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"SeriesTime"];
	//Instance Tags  leave these tags empty
	[scObject setAttributeValues:[NSMutableArray array] forName:@"InstanceNumber"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"AcquisitionDate"];
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"AcquisitionTime"];
	// pixel Data info
	/*
	[scObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:nff]] forName:@"NumberofFrames"];

SamplesperPixel
PhotometricInterpretation
PlanarConfiguration
Rows
Columns
PixelSpacing
BitsAllocated
BitsStored
HighBit
PixelRepresentation
	*/
	

	[scObject updateMetaInformationWithTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] aet:@"Horos"];
	return scObject;


}

+ (id)objectWithData:(NSData *)data decodingPixelData:(BOOL)decodePixelData{
	return [[[DCMObject alloc] initWithData:data decodingPixelData:decodePixelData] autorelease];
}

+ (id)objectWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData{
	
	return [[[DCMObject alloc] initWithContentsOfFile:file decodingPixelData:decodePixelData] autorelease];
}

+ (id)objectWithContentsOfURL:(NSURL *)aURL decodingPixelData:(BOOL)decodePixelData{
		return [[[DCMObject alloc] initWithContentsOfURL:aURL decodingPixelData:decodePixelData] autorelease];
}
 + (id)objectWithObject:(DCMObject *)object{
	return [[[DCMObject alloc] initWithObject:object] autorelease];
}

+ (NSString*) globallyUniqueString
{
    NSString *s = nil;
    @synchronized( rootUID)
    {
        globallyUnique++;
        if( macAddress == nil) {
            macAddress = [getMacAddressNumber() retain];
        }
        
        NSNumber *vd = [NSNumber numberWithUnsignedLongLong: 100. * [NSDate timeIntervalSinceReferenceDate]];
        s = [NSString stringWithFormat: @"%@%@%d", macAddress, vd, globallyUnique];
    }
	return s;
}

+ (NSString*) MACAddress
{
	return [NSString stringWithFormat: @"MAC:%@", getMacAddress()];
}
		
- (id)initWithData:(NSData *)data decodingPixelData:(BOOL)decodePixelData{
	DCMDataContainer *container = [DCMDataContainer dataContainerWithData:data];
	int offset = 0;
	if (DCMDEBUG)
			NSLog(@"start byteOffset: %d", offset);
	if (DCMDEBUG)
		NSLog(@"Container length:%d  offet:%d", [container length],[container offset]);
	return [self  initWithDataContainer:container lengthToRead:[container length] - [container offset] byteOffset:&offset characterSet:nil decodingPixelData:decodePixelData];

}

- (id)initWithData:(NSData *)data transferSyntax:(DCMTransferSyntax *)syntax{
	DCMDataContainer *container = [DCMDataContainer dataContainerWithData:data transferSyntax:syntax];
	int offset = 0;
	return [self initWithDataContainer:container lengthToRead:[container length] byteOffset:&offset characterSet:nil decodingPixelData:NO];
}

- (id)initWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData{
	if([[NSFileManager defaultManager] fileExistsAtPath:file] == NO) return nil;
	NSData *aData = [NSData dataWithContentsOfMappedFile:file];
	return [self initWithData:aData decodingPixelData:decodePixelData] ;
}

- (id)initWithContentsOfURL:(NSURL *)aURL decodingPixelData:(BOOL)decodePixelData{
	NSData *aData = [NSData dataWithContentsOfURL:aURL];
	return [self initWithData:aData decodingPixelData:decodePixelData] ;
}

- (id)initWithDataContainer:(DCMDataContainer *)data lengthToRead:(int)lengthToRead byteOffset:(int*)byteOffset characterSet:(DCMCharacterSet *)characterSet decodingPixelData:(BOOL)decodePixelData{
	if (self = [super init])
	{
		_decodePixelData = decodePixelData;
		sharedTagDictionary = [DCMTagDictionary sharedTagDictionary];
		sharedTagForNameDictionary = [DCMTagForNameDictionary sharedTagForNameDictionary];
		attributes = [[NSMutableDictionary dictionary] retain];
		if (characterSet)
			specificCharacterSet = [characterSet retain];
		else
			specificCharacterSet = [[DCMCharacterSet alloc] initWithCode:@"ISO_IR 100"];
		transferSyntax = [[data transferSyntaxForDataset] retain];
		DCMDataContainer *dicomData;
		dicomData = [data retain];
			
		*byteOffset = [self readDataSet:dicomData lengthToRead:lengthToRead byteOffset:byteOffset];
		
		if (*byteOffset == 0xFFFFFFFF)
        {
            [self autorelease];
			self = nil;
		}
		if (DCMDEBUG)
			NSLog(@"end readDataSet byteOffset: %d", *byteOffset);
		[dicomData release];
			//NSLog(@"DCMObject end init: %f", -[timestamp  timeIntervalSinceNow]); 
	}

	return self;
}

- (id)initWithObject:(DCMObject *)object
{
	if (self = [super init])
	{
		specificCharacterSet = [[object specificCharacterSet] copy];
		attributes = [[object attributes] mutableCopy];
		transferSyntax = [[object transferSyntax] copy];
		_decodePixelData = [object pixelDataIsDecoded];
	}
	return self;
}

- (id)init
{
	if (self = [super init])
	{
		sharedTagDictionary = [DCMTagDictionary sharedTagDictionary];
		sharedTagForNameDictionary = [DCMTagForNameDictionary sharedTagForNameDictionary];
		attributes = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[DCMObject allocWithZone:zone] initWithObject:self];
}

- (void) dealloc
{
	[specificCharacterSet release];
	[attributes release];
	[transferSyntax release];
	[super dealloc];
}

- (int)readDataSet:(DCMDataContainer *)dicomData lengthToRead:(int)lengthToRead byteOffset:(int *)byteOffset
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL readingMetaHeader = NO;
	int endMetaHeaderPosition = 0;					
	BOOL undefinedLength = lengthToRead == 0xFFFFFFFF;	
	int endByteOffset= (undefinedLength) ? 0xFFFFFFFF : *byteOffset + lengthToRead - 1;
	BOOL isExplicit = [[dicomData transferSyntaxInUse] isExplicit];
	unsigned dicomDataLength = [dicomData length];
	BOOL forImplicitUseOW = NO;
	
	BOOL pixelRepresentationIsSigned = NO;
	int previousByteOffset = -1;
    
	@try
	{
		while ((undefinedLength || *byteOffset < endByteOffset))
		{
            if( previousByteOffset != -1 && previousByteOffset ==  *byteOffset)
            {
                NSLog( @"***** DCMObject readDataSet previousByteOffset ==  *byteOffset");
                break;
            }
            previousByteOffset = *byteOffset;
            
			NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
            
            @try
            {
                if (DCMDEBUG)
                    NSLog( @"byteOffset:%d, endByteOffset:%d", *byteOffset, endByteOffset);
                
                int group = [self getGroup:dicomData];
                int element = [self getElement:dicomData];
                
                if (group > 0x0002)
                {
                    //NSLog(@"start reading dataset");
                    [dicomData startReadingDataSet];
                }
                
                else if (transferSyntax != nil && group == 0x0002 && element == 0x0010)
                {
                    //workaround for extra Transfer Syntax element in some Conquest files
                    [dicomData startReadingDataSet];
                }
                
                isExplicit = [[dicomData transferSyntaxInUse] isExplicit];
                //NSLog(@"DCMObject readTag: %f", -[timestamp  timeIntervalSinceNow]);
                DCMAttributeTag *tag = [[[DCMAttributeTag alloc] initWithGroup:group element:element] autorelease];
                *byteOffset+=4;
                
                const char *tagUTF8 = [tag.stringValue UTF8String];
                
                if (DCMDEBUG)
                    NSLog(@"Tag: %@  group: 0x%4000x  word 0x%4000x", tag.description, group, element);
                    // "FFFE,E00D" == Item Delimitation Item
                if (strcmp(tagUTF8, "FFFE,E00D") == 0)
                {
                    // Read and discard value length
                    [dicomData nextUnsignedLong];
                    *byteOffset+=4;
                    if (DCMDEBUG)
                        NSLog(@"ItemDelimitationItem");
                    break;
                    //return *byteOffset;	// stop now, since we must have been called to read an item's dataset
                }
                
                // "FFFE,E000" == Item 
                else if (strcmp(tagUTF8, "FFFE,E000") == 0)
                {
                    // this is bad ... there shouldn't be Items here since they should
                    // only be found during readNewSequenceAttribute()
                    // however, try to work around Philips bug ...
                    long vl = [dicomData nextUnsignedLong];		// always implicit VR form for items and delimiters
                    *byteOffset+=4;
                    if (DCMDEBUG)
                        NSLog(@"Ignoring bad Item at %d  %@ VL=<0x%x", *byteOffset, tag.stringValue, (unsigned int) vl);
                    // let's just ignore it for now
                    //continue;
                }
                // get tag Values
                else
                {
                // get vr

                    NSString *vr = nil;
                    long vl = 0;
                    if (isExplicit) 
                    {
                        vr = [dicomData nextStringWithLength:2];
                        if (DCMDEBUG)
                            NSLog(@"Explicit VR %@", vr);
                        *byteOffset+=2;
                        if (!vr)
                            vr = [tag vr];
                        else
                        {
//#ifdef NDEBUG
//#else
//                            if( [tag.vr isEqualToString: vr] == NO && [tag.vr isEqualToString: @"UN"] == NO)
//                                NSLog( @"%@ versus %@", tag.vr, vr);
//#endif
                            tag.vr = vr;
                        }
                    }
                    
                    //implicit
                    else
                    {
                        vr = tag.vr;
                        if (!vr)
                            vr = @"UN";
                        if ([vr isEqualToString:@"US/SS/OW"])
                            vr = @"OW";
                        // set VR for Pixel Description depenedent tags. Can be either  US or SS depending on Pixel Description
                        if ([vr isEqualToString:@"US/SS"]) {
                        if ( pixelRepresentationIsSigned)
                                vr = @"SS";
                            else 
                                vr = @"US";
                        }
                        if (DCMDEBUG)
                            NSLog(@"Implicit VR %@", vr);	


                    }
                    //if (DCMDEBUG)
                    //	NSLog(@"byteoffset after vr %d, VR:%@",*byteOffset,  vr, vl);
                //  ****** get length *********
                    if (isExplicit)
                    {
                        if ([DCMValueRepresentation isShortValueLengthVR:vr])
                        {
                            vl = [dicomData nextUnsignedShort];
                            *byteOffset+=2;
                        }
                        else
                        {
                            [dicomData nextUnsignedShort];	// reserved bytes
                            vl = [dicomData nextUnsignedLong];
                            *byteOffset+=6;
                        }
                    }
                    else
                    {
                        vl = [dicomData nextUnsignedLong];
                        *byteOffset += 4;
                    }
                    if (DCMDEBUG)
                        NSLog(@"Tag: %@, length: %ld", [tag description], vl);
                    //if (DCMDEBUG)
                    //	NSLog(@"byteoffset after length %d, VR:%@  length:%d",*byteOffset,  vr, vl);
                    
                    // generate Attributes
                    DCMAttribute *attr = nil;
                    
                    //sequence attribute
                    if( [DCMValueRepresentation isSequenceVR:vr] || ([DCMValueRepresentation  isUnknownVR:vr] && vl == 0xFFFFFFFF))
                    {
                        attr = (DCMAttribute *) [[[DCMSequenceAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
                        *byteOffset = [self readNewSequenceAttribute:attr dicomData:dicomData byteOffset:byteOffset lengthToRead:(int)vl specificCharacterSet:specificCharacterSet];
                    } 
                    // "7FE0,0010" == PixelData
                    else if (strcmp(tagUTF8, "7FE0,0010") == 0 && tag.isPrivate == NO)
                    {
                        attr = (DCMPixelDataAttribute *) [[[DCMPixelDataAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag 
                        vr:(NSString *)vr 
                        length:(long) vl 
                        data:(DCMDataContainer *)dicomData 
                        specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
                        transferSyntax:[dicomData transferSyntaxForDataset]
                        dcmObject:self
                        decodeData:_decodePixelData] autorelease];
                        
                        *byteOffset += vl;
                    }
                    else if (vl != 0xFFFFFFFF) // && vl != 0 ANR 2009
                    {
                        if ([self isNeededAttribute:(char *)tagUTF8])
                            attr = [[[DCMAttribute alloc] initWithAttributeTag:tag 
                                vr:vr 
                                length: vl 
                                data:dicomData 
                                specificCharacterSet:specificCharacterSet
                                isExplicit:[dicomData isExplicitTS]
                                forImplicitUseOW:forImplicitUseOW] autorelease];
                        else
                        {
                            attr = nil;
                            [dicomData skipLength:(int)vl];
                        }
                        *byteOffset += vl;
                        if (DCMDEBUG)
                            NSLog(@"byteOffset %d attr %@", *byteOffset, [attr description]);
                    }
                    
                    if (DCMDEBUG)
                        NSLog(@"Attr: %@", [attr description]);
                    
                    //add attr to attributes
                    if (attr)
                        CFDictionarySetValue((CFMutableDictionaryRef)attributes, [tag stringValue], attr);
                        
                    // 0002,0000 = MetaElementGroupLength
                    if (strcmp(tagUTF8, "0002,0000") == 0)
                    {
                        readingMetaHeader = YES;
                        if (DCMDEBUG)
                            NSLog(@"metaheader length : %d", [[attr value] intValue]);
                        endMetaHeaderPosition = [[attr value] intValue] + *byteOffset;
                        [dicomData startReadingMetaHeader];
                    }
                    //0002,0010 == TransferSyntaxUID
                    else if (strcmp(tagUTF8, "0002,0010") == 0  
                        && transferSyntax == nil)  //some conquest files have the transfer Syntax twice. Need to ignore to second one
                    {
                        DCMTransferSyntax *ts = [[[DCMTransferSyntax alloc] initWithTS:[attr value]] autorelease];
                        [transferSyntax release];
                        transferSyntax = [ts retain];
                        [dicomData setTransferSyntaxForDataset:ts];
                    }
                    
                    //0008,0005 == SpecificCharacterSet
                    else if (strcmp(tagUTF8, "0008,0005") == 0)
                    {
                        [specificCharacterSet release];
                        specificCharacterSet = [[DCMCharacterSet alloc] initWithCode: [[attr values] componentsJoinedByString:@"\\"]];
                    }
                    
                    /*
                    if (readingMetaHeader && (*byteOffset >= endMetaHeaderPosition)) {
                        if (DCMDEBUG)
                            NSLog(@"End reading Metaheader. Metaheader position: %d, byteOffset: %d", endMetaHeaderPosition, *byteOffset);
                        readingMetaHeader = NO;
                        [dicomData startReadingDataSet];
                    }
                    */

                }
            }
            @catch (NSException *e)
            {
                NSLog( @"***** DCMObject readDataSet exception: %@", e);
                break;
            }
            @finally {
                [subPool release];
            }
			
			if( dicomDataLength <= [dicomData position])
				*byteOffset = endByteOffset;
		}
		[transferSyntax release];
		transferSyntax = [[dicomData transferSyntaxForDataset] retain];
	}
	
	@catch (NSException *e)
	{
		NSLog(@"Error reading data for dicom object: %@", e);
		
		*byteOffset = 0xFFFFFFFF;
	}
	@finally {
        [pool release];
    }
	
	return *byteOffset;
}

- (int) readNewSequenceAttribute:(DCMAttribute *)attr dicomData:(DCMDataContainer *)dicomData byteOffset:(int *)byteOffset lengthToRead:(int)lengthToRead specificCharacterSet:(DCMCharacterSet *)aSpecificCharacterSet{

	BOOL undefinedLength = lengthToRead == 0xFFFFFFFF;
	int endByteOffset = (undefinedLength) ? 0xFFFFFFFF : *byteOffset+lengthToRead-1;
	NSException *myException;
	@try {
		if (DCMDEBUG)
			NSLog(@"Read newSequence:%@  lengthtoRead:%d byteOffset:%d, characterSet: %@", [attr description], lengthToRead, *byteOffset, [aSpecificCharacterSet characterSet] );
		while (undefinedLength || *byteOffset < endByteOffset)
        {
			NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
            
            @try {
                int itemStartOffset=*byteOffset;
                int group = [self getGroup:dicomData];
                int element = [self getElement:dicomData];
                DCMAttributeTag *tag = [[[DCMAttributeTag alloc]  initWithGroup:group element:element] autorelease];
                *byteOffset+=4;
                
                long vl = [dicomData nextUnsignedLong];		// always implicit VR form for items and delimiters
                *byteOffset+=4;
    //System.err.println(byteOffset+" "+tag+" VL=<0x"+Long.toHexString(vl)+">");
                if ([tag.stringValue isEqualToString:[sharedTagForNameDictionary objectForKey:@"SequenceDelimitationItem"]]) {
                    if (DCMDEBUG)
                        NSLog(@"SequenceDelimitationItem");
    //System.err.println("readNewSequenceAttribute: SequenceDelimitationItem");
                    break;
                }
                else if ([tag.stringValue isEqualToString:[sharedTagForNameDictionary objectForKey:@"Item"]]) {
                    if (DCMDEBUG)
                        NSLog(@"New Item");
                    DCMObject *object = [[[[self class] alloc] initWithDataContainer:dicomData lengthToRead:(int)vl byteOffset:byteOffset characterSet:specificCharacterSet decodingPixelData:NO] autorelease];
                    object.isSequence = YES;
                    [(DCMSequenceAttribute *)attr  addItem:object offset:itemStartOffset];
                    if (DCMDEBUG)
                        NSLog(@"end New Item");
                }
                else {
                    myException = [NSException exceptionWithName:@"DCM Bad Tag"  reason:@"(not Item or Sequence Delimiter) in Sequence at byte offset " userInfo:nil];
                    [myException raise];
                }
            }
            @catch( NSException *e) {
                NSLog( @"%@", e);
//                break; // Horos bug #210 provided to OP, but OP stopped responding to email
            }
            @finally {
                [subPool release];
            }
		}
		
		
	} @catch( NSException *localException) {
		NSLog(@"Error");
		*byteOffset = -1;
	}
		return *byteOffset;
	
	
}

- (DCMAttribute *) newAttributeForAttributeTag:(DCMAttributeTag *)tag 
			vr:(NSString *)vr 
			length:(int) vl 
			data:(DCMDataContainer *)dicomData 
			specificCharacterSet:(DCMCharacterSet *)specificCharacterSet
			isExplicit:(BOOL) explicit
			forImplicitUseOW:(BOOL)forImplicitUseOW {

	DCMAttribute *a = nil;
	return a;
}

//Dicom Parsing
- (int)getGroup:(DCMDataContainer *)dicomData {
	int group = [dicomData nextUnsignedShort];
	return group;
}

- (int)getElement:(DCMDataContainer *)dicomData {
	int element = [dicomData nextUnsignedShort];
	return element;
}

- (int)length:(DCMDataContainer *)dicomData {
	int length = 0;
	return length;
}

- (NSString *)getvr:(DCMDataContainer *)dicomData forTag:(DCMAttributeTag *)tag isExplicit:(BOOL)isExplicit {
/*
	if (isExplicit) {
		//char vr[2] = 
	}
	else{
	}
*/
	NSString *vr = @"";
	return vr;
}

- (NSMutableArray *)getValues:(DCMDataContainer *)dicomData {
	NSMutableArray *values = [NSMutableArray array];
	return values;
}

- (NSString *)description
{
	NSString *description = @"";
	NSArray *keys = [[attributes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for ( NSString *key in keys ) {
		//NSLog(@"key: %@", key);
		DCMAttribute *attr = [attributes objectForKey:key];
		description = [NSString stringWithFormat:@"%@ \n%@", description, attr.description];
	}
	return description;
}

- (NSString *)readableDescription
{
	NSString *description = @"";
	NSArray *keys = [[attributes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for ( NSString *key in keys ) {
		//NSLog(@"key: %@", key);
		DCMAttribute *attr = [attributes objectForKey:key];
		description = [NSString stringWithFormat:@"%@ \n%@", description, attr.readableDescription];
	}
	return description;
}

- (void)removeMetaInformation {
	NSMutableArray *keysToRemove = [NSMutableArray array];
	for ( NSString *key in attributes ) {
		DCMAttribute *attr = [attributes objectForKey:key];
		if ( attr.attrTag.group == 0x0002 )
			[keysToRemove addObject:key];
	 }
	[attributes removeObjectsForKeys:keysToRemove];
}

- (void)updateMetaInformationWithTransferSyntax: (DCMTransferSyntax *)ts aet:(NSString *)aet{
/*
	mandatory attributes:
		FileMetaInformationVersion
		MediaStorageSOPClassUID
		MediaStorageSOPInstanceUID
		TransferSyntaxUID
		ImplementationClassUID
		SourceApplicationEntityTitle
		groupLengthTag
		
*/
	int gl = 0;

	// FileMetaInformationVersion
	DCMAttributeTag *tag = [[DCMAttributeTag alloc] initWithName:@"FileMetaInformationVersion"];
	DCMAttribute *attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	char bytes[2];
	bytes[0] = 0x00;
	bytes[1] = 0x01;
	NSData *data = [NSData dataWithBytes:bytes length:2];
	[attr addValue:data];
	[attributes setObject:attr forKey:[tag stringValue]];
	gl += attr.paddedLength;
	gl += (4+4+4);
	if (DCMDEBUG)
		NSLog(@"padded Length: %ld  group length: %d", attr.paddedLength, gl);
	[attr release];
	[tag release];
	
	//should already have MediaStorageClassUID and InstanceUID
	if ([self attributeWithName:@"MediaStorageSOPClassUID"]){
		gl += (4+2+2);
		gl += [[self attributeWithName:@"MediaStorageSOPClassUID"] paddedLength];
	}
	//need to copy SOPCLassUID"
	else{
		NSString *sopClassUID = [self attributeValueWithName:@"SOPClassUID"];
		if (sopClassUID) {
			tag = [[[DCMAttributeTag alloc] initWithName:@"MediaStorageSOPClassUID"] autorelease];
			attr = [[[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
			[attr addValue:sopClassUID];
			[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
			gl += attr.paddedLength;
			gl += (4+2+2);
		}
	}
	
	if ([self attributeWithName:@"MediaStorageSOPInstanceUID"]){
		gl += (4+2+2);
		gl += [[self attributeWithName:@"MediaStorageSOPInstanceUID"] paddedLength];
	}	//need to copy SOPInstanceUID"
	else{
		NSString *sopInstanceUID = [self attributeValueWithName:@"SOPInstanceUID"];
		if (sopInstanceUID) {
			tag = [[[DCMAttributeTag alloc] initWithName:@"MediaStorageSOPInstanceUID"] autorelease];
			attr = [[[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
			[attr addValue:sopInstanceUID];
			[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
			gl += attr.paddedLength;
			gl += (4+2+2);
		}
	}


	//TransferSyntaxUID
	tag = [[DCMAttributeTag alloc] initWithName:@"TransferSyntaxUID"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:[ts transferSyntax]];
	[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
	gl += attr.paddedLength;
	gl += (4+2+2);

	[attr release];
	[tag release];
	
	//ImplementationClassUID
	tag = [[DCMAttributeTag alloc] initWithName:@"ImplementationClassUID"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:rootUID];
	[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
	gl += attr.paddedLength;
	gl += (4+2+2);

	[attr release];
	[tag release];
	
	//ImplementationVersionName
	tag = [[DCMAttributeTag alloc] initWithName:@"ImplementationVersionName"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:@"OSIRIX001"];
	[attributes setObject:attr forKey:[(DCMAttributeTag *)tag stringValue]];
	gl += attr.paddedLength;
	gl += (4+2+2);
	[attr release];
	[tag release];
	
	
	//SourceApplicationEntityTitle
	if (aet) {
		tag = [[DCMAttributeTag alloc] initWithName:@"SourceApplicationEntityTitle"];
		attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
		[attr addValue:aet];
		[attributes setObject:attr forKey: tag.stringValue];
		[attr release];
		[tag release];
	}

	attr = [attributes objectForKey:[sharedTagForNameDictionary objectForKey:@"SourceApplicationEntityTitle"]];
	if (attr) {
		gl += (4+2+2);	// 1 fixed EVR short-length-form elements
		gl += attr.paddedLength;
	}
	
			//groupLengthTag
	tag = [[DCMAttributeTag alloc] initWithName:@"MetaElementGroupLength"];
	attr = [[DCMAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag];
	[attr addValue:[NSNumber numberWithInt:gl]];
	[attributes setObject:attr forKey: tag.stringValue];

	[attr release];
	[tag release];
}

- (DCMAttribute *)attributeForTag:(DCMAttributeTag *)tag{
    DCMAttribute* result = [attributes objectForKey: tag.stringValue];
    return result;
}

- (DCMAttribute *)attributeWithName:(NSString *)name{
	return [self attributeForTag:[DCMAttributeTag tagWithName:name]];
}

- (id)attributeValueWithName:(NSString *)name{
    id value = [[self attributeForTag:[DCMAttributeTag tagWithName:name]] value];
    return value;
}

- (id)attributeValueForKey:(NSString *)key{
	return [[attributes objectForKey:key] value];
}

- (NSArray *)attributeArrayWithName:(NSString *)name{
	return [[self attributeForTag:[DCMAttributeTag tagWithName:name]] values];
}

- (NSArray *)attributeArrayForKey:(NSString *)key{
    return [[attributes objectForKey:key] values];
}

- (void)setAttribute:(DCMAttribute *)attr{
	[attributes setObject:attr  forKey:[(DCMAttributeTag *)[attr attrTag] stringValue]];
}

- (void)addAttributeValue:(id)value forName:(NSString *)name
{
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:name];
	
	if( tag)
	{
		DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:(DCMAttributeTag *)tag];
		if ([attributes objectForKey:[tag stringValue]])
			[[attributes objectForKey:[tag stringValue]] addValue:value];
		else
		{
			[attr addValue:value];
			[attributes setObject:attr forKey: tag.stringValue];
		}
	}
	else
		NSLog( @"*** tagname not found in dictionary: %@", name);
}

- (void)setAttributeValues:(NSMutableArray *)values forName:(NSString *)name
{
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:name];
	if( tag)
	{
		DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:(DCMAttributeTag *)tag];
		attr.values = values;
		[attributes setObject:attr forKey: tag.stringValue];
	}
	else
		NSLog( @"*** tagname not found in dictionary: %@", name);
}

//write Data

- (void)removeGroupLengths{
	NSMutableArray *keysToRemove = [NSMutableArray array];
	for ( NSString *key in attributes ) {
		DCMAttribute *attr = [attributes objectForKey:key];
		//remove all group lengths except for Metaheader group
		if ([(DCMAttributeTag *)[attr attrTag] element] == 0x0000 && [(DCMAttributeTag *)[attr attrTag] group] != 0x0002) {
			if (DCMDEBUG)
				NSLog(@"Remove %@", attr.description);
			[keysToRemove addObject:key];
		}
	}
	
	[attributes removeObjectsForKeys:keysToRemove];
	
		//dataset trailing padding
	//[attributes removeObjectForKey:@"FFFC,FFFC"];
}

- (void)removePrivateTags{
	NSMutableArray *keysToRemove = [NSMutableArray array];
	for ( NSString *key in attributes ) {
		DCMAttribute *attr = [attributes objectForKey:key];
		//remove all group lengths except for Metaheader group
		if ( attr.attrTag.group % 2 != 0 ) {
			if (DCMDEBUG)
				NSLog(@"Remove Private Tag %@", [attr description]);
			[keysToRemove addObject:key];
		}
	}
	[attributes removeObjectsForKeys:keysToRemove];
}

- (void)removePlanarAndRescaleAttributes{
	[attributes removeObjectForKey:[[DCMAttributeTag tagWithName:@"RescaleSlope"] stringValue]];
	[attributes removeObjectForKey:[[DCMAttributeTag tagWithName:@"RescaleIntercept"] stringValue]];;
	[attributes removeObjectForKey:[[DCMAttributeTag tagWithName:@"PlanarConfiguration"] stringValue]];;
}


- (void)anonymizeAttributeForTag:(DCMAttributeTag *)tag replacingWith:(id)aValue{
	DCMAttribute *attr = [attributes objectForKey: tag.stringValue];
	//Add attr is aValue exists create attr if absent and add new value
	if (aValue && !attr) {
		attr = [DCMAttribute attributeWithAttributeTag:(DCMAttributeTag *)tag];
		[attr addValue:aValue];
		[attributes setObject:attr forKey: tag.stringValue];
	}
	
	/*change data if attribute exists.
	Will not change UIDs or metaheader tags
	  Change will depend on vr.  Change date to 1/1/2000.  Change strings to  something.  change numbers to 0.
	  
	*/
	// NSLog(@"anonymizeAttributeForTag:%@  aValue%@", tag, aValue);
//	if ([(DCMAttributeTag *)[attr attrTag] isEquaToTag:[DCMAttributeTag tagWithName:@"PatientsSex"]])
//		[attr setValues:[NSMutableArray array]];
//	if ([(DCMAttributeTag *)[attr attrTag] isEquaToTag:[DCMAttributeTag tagWithName:@"PatientsBirthDate"]])
//		[attr setValues:[NSMutableArray array]];
//	else
	if ( attr && tag.group != 0x0002 && ![tag.vr isEqualToString:@"UI"]) {
		const char *chars = [tag.vr UTF8String];
		int vr = chars[0]<<8 | chars[1];
		NSMutableArray *values = attr.values;
		id newValue = nil;
		NSString *format = nil;
		for ( int index = 0 ; index < [values count]; index++)
		{
			id value = [values objectAtIndex: index];
			
			switch (vr)
			{
					//NSNumbers
				case DCM_AT:	//Attribute Tag 16bit unsigned integer 
				case DCM_UL:	//unsigned Long            
				case DCM_SL:	//signed long
				case DCM_FL:	//floating point Single 4 bytes fixed
				case DCM_FD:	//double floating point 8 bytes fixed
				case DCM_US:   //unsigned short
				case DCM_SS:	//signed short
					newValue = [NSNumber numberWithInt:0];
					break;
					//calendar dates
				case DCM_DA:	format = @"%Y%m%d";
				case DCM_TM:	if (!format)
								format = @"%H%M%S";
				case DCM_DT:	if (!format)
								format = @"%Y%m%d%H%M%S";
					newValue = [DCMCalendarDate dateWithYear:[value yearOfCommonEra] month:[value monthOfYear] day:1 hour:12 minute:00 second:00 timeZone:[value timeZone]];
					if (![aValue isKindOfClass:[DCMCalendarDate class]])
                    {
						if (aValue && [aValue isMemberOfClass:[NSCalendarDate class]])
							aValue = [DCMCalendarDate dateWithString:[aValue descriptionWithCalendarFormat:format] calendarFormat:format];
						else
                            aValue = nil;
                    }
					break;
				/*		
				case SQ:	//Sequence of items
						//shouldn't get here
						break;
				*/
				
						//NSData  make zeroed NSData of length of old NSData
				case DCM_UN:	//unknown
				case DCM_OB:	//other Byte byte string not little/big endian sensitive
				case DCM_OW:	//other word 16bit word
					newValue = [NSMutableData dataWithLength:[(NSData *)value length]];
				break;
					//NUmber strings	
				case DCM_SH:	//short string	
				case DCM_DS:	//Decimal String  representing floating point number 16 byte max
				case DCM_IS:	//Integer String 12 bytes max
					newValue =  @"0";
				break;
					//Age string					
				case DCM_AS:	//Age String Format mmmM,dddD,nnnY ie 018Y
					newValue = @"000Y";
				break;
					//code string
				case DCM_CS:	//Code String   16 byte max
					newValue = @"0000";
				break;
				case DCM_AE:	//Application Entity  String 16bytes max
				case DCM_LO:	//Character String 64 char max
				case DCM_LT:	//Long Text 10240 char Max
				case DCM_PN:	//Person Name string
				case DCM_ST:	//short Text 1024 char max
				case DCM_UI:    //String for UID             
				case DCM_UT:	//unlimited text
				case DCM_QQ: 	
					//newValue = @"XXXXXXX";
					//Patient ID are unique whene anonymized. but same for each ID
					/*
					else if ([[attr attrTag] isEquaToTag:[DCMAttributeTag tagWithName:@"PatientID"]])
					{
						newValue = @"";
					}
					*/
					newValue = [self anonymizeString:[values objectAtIndex:index]];
				break;
	 		}
			
			if (aValue)
			{
				if (DCMDEBUG)
					NSLog(@"Anonymize Values: %@ to value: %@", attr.description, [aValue description]);
				[values replaceObjectAtIndex:index withObject:aValue];
			}
			else
			{
				if (DCMDEBUG)
					NSLog(@"Anonymize Values: %@ to value: %@", attr.description, [newValue description]);
                
                if( newValue == nil)
                    newValue = [NSNull null];
				[values replaceObjectAtIndex:index withObject:newValue];
			}
		}	
		
	}

}

- (NSString *)anonymizeString:(NSString *)string
{
	int root = 0;
	int i = 0;
	int value = 0;
	char newChar = 0;
	char x;
	int length = (int)[string length];
	char newString[length];
	const char *chars = [string UTF8String];
	while (i < length) {
		root +=  chars[i];
		value = root * length * chars[i];
		x = value%65;
		switch(x) {
			case 0: newChar = '0';
				break;
			case 1: newChar = '1';
				break;
			case 2: newChar = '2';
				break;
			case 3: newChar = '3';
				break;
			case 4: newChar = '4';
				break;
			case 5: newChar = '5';
				break;
			case 6: newChar = '6';
			break;
			case 7: newChar = '7';
			break;
			case 8: newChar = '8';
			break;
			case 9: newChar = '9';
			break;
			case 10: newChar = 'a';
			break;
			case 11: newChar = 'b';
			break;
			case 12: newChar = 'c';
			break;
			case 13: newChar = 'd';
			break;
			case 14: newChar = 'e';
			break;
			case 15: newChar = 'f';
			break;
			case 16: newChar = 'g';
			break;
			case 17: newChar = 'h';
			break;
			case 18: newChar = 'i';
			break;
			case 19: newChar = 'j';
			break;
			case 20: newChar = 'k';
			break;
			case 21: newChar = 'l';
			break;
			case 22: newChar = 'm';
			break;
			case 23: newChar = 'n';
			break;
			case 24: newChar = 'o';
			break;
			case 25: newChar = 'p';
			break;
			case 26: newChar = 'q';
			break;
			case 27: newChar = 'r';
			break;
			case 28: newChar = 's';
			break;
			case 29: newChar = 't';
			break;
			case 30: newChar = 'u';
			break;
			case 31: newChar = 'v';
			break;
			case 32: newChar = 'w';
			break;
			case 33: newChar = 'x';
			break;
			case 34: newChar = 'y';
			break;
			case 35: newChar = 'z';
			break;
			case 36: newChar = 'A';
			break;
			case 37: newChar = 'B';
			break;
			case 38: newChar = 'C';
			break;
			case 39: newChar = 'D';
			break;
			case 40: newChar = 'E';
			break;
			case 41: newChar = 'F';
			break;
			case 42: newChar = 'G';
			break;
			case 43: newChar = 'H';
			break;
			case 44: newChar = 'I';
			break;
			case 45: newChar = 'J';
			break;
			case 46: newChar = 'K';
			break;
			case 47: newChar = 'L';
			break;
			case 48: newChar = 'M';
			break;
			case 49: newChar = 'N';
			break;
			case 50: newChar = 'O';
			break;
			case 51: newChar = 'P';
			break;
			case 52: newChar = 'Q';
			break;
			case 53: newChar = 'R';
			break;
			case 54: newChar = 'S';
			break;
			case 55: newChar = 'T';
			break;
			case 56: newChar = 'U';
			break;
			case 57: newChar = 'V';
			break;
			case 58: newChar = 'W';
			break;
			case 59: newChar = 'X';
			break;
			case 60: newChar = 'Y';
			break;
			case 61: newChar = 'Z';
			break;
			case 62: newChar = '.';
			break;
			case 63: newChar = ',';
			break;
			case 64: newChar = '^';
			break;
			case 65: newChar = '~';
			break;
		}
		newString[i++] = newChar;
	}
	NSData *data = [NSData dataWithBytes:newString length:length];
	return [[[NSString alloc] initWithData:data encoding:[specificCharacterSet encoding]] autorelease];
}

+ (NSString*) newStudyInstanceUID
{
	NSString *uidSuffix = [DCMObject globallyUniqueString];
    
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"1", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	if( [uid length] > 64)
    {
        NSLog( @"------ warning newSeriesInstanceUID.length > 64 : %@", uid);
		uid = [uid substringToIndex:64];
    }
	
    return uid;
}

- (void)newStudyInstanceUID
{
	NSString *uid = [DCMObject newStudyInstanceUID];
	
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"StudyInstanceUID"];
	NSMutableArray *attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:tag vr: tag.vr values:attrValues];
	[attributes setObject:attr forKey: tag.stringValue];
}

+ (NSString*) newSeriesInstanceUID
{
	NSString *uidSuffix = [DCMObject globallyUniqueString];
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"2", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	if( [uid length] > 64)
    {
        NSLog( @"------ warning newSeriesInstanceUID.length > 64 : %@", uid);
		uid = [uid substringToIndex:64];
    }
    
    return uid;
}

- (void)newSeriesInstanceUID
{
	NSString *uid = [DCMObject newSeriesInstanceUID];
    
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"SeriesInstanceUID"];
	NSMutableArray *attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute *attr = [DCMAttribute attributeWithAttributeTag:tag vr: tag.vr values:attrValues];
	[attributes setObject:attr forKey: tag.stringValue];
}

- (void)newSOPInstanceUID
{
	NSString *uidSuffix = [DCMObject globallyUniqueString];	
	
	NSArray *uidValues = [NSArray arrayWithObjects:rootUID, @"3", uidSuffix, nil];
	NSString *uid = [uidValues componentsJoinedByString:@"."];
	if( [uid length] > 64)
		uid = [uid substringToIndex:64];
	//NSLog(@"SOPInstanceUID: %@  length: %d", uid, [uid length]);
	DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"SOPInstanceUID"];
	NSMutableArray *attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute *sopAttr = [DCMAttribute attributeWithAttributeTag:tag vr: tag.vr values:attrValues];
	if (DCMDEBUG)
		NSLog(@"New SOP tag: %@ attr: %@", tag.description, sopAttr.description);
	[attributes setObject:sopAttr  forKey: tag.stringValue];
	
	DCMAttributeTag *mediaTag = [DCMAttributeTag tagWithName:@"MediaStorageSOPInstanceUID"];
	attrValues = [NSMutableArray arrayWithObject:uid];
	DCMAttribute  *mediaAttr = [DCMAttribute attributeWithAttributeTag:mediaTag vr:[mediaTag vr] values:attrValues];
	[attributes setObject:mediaAttr forKey: mediaTag.stringValue];
}
		
- (void)setCharacterSet:(DCMCharacterSet *)characterSet{
	//NSLog(@"set Charcter Set: %@", [characterSet description]);
	[specificCharacterSet release];
	specificCharacterSet = [characterSet retain];
	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
	for ( NSString *key in sortedKeys ) {
		DCMAttribute *attr = [attributes objectForKey:key];
		if (attr)
			[attr setCharacterSet:specificCharacterSet];
	}
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts  asDICOM3:(BOOL)flag
{
	return [self writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts AET:@"OSIRIX"  asDICOM3:(BOOL)flag];
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts AET:(NSString *)aet  asDICOM3:(BOOL)flag
{
	return [self writeToDataContainer: container withTransferSyntax: ts AET: aet  asDICOM3: flag implicitForPixelData: NO];
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts AET:(NSString *)aet  asDICOM3:(BOOL)flag implicitForPixelData: (BOOL) ipd
{
	if (!ts)
		ts = transferSyntax;
	
	DCMTransferSyntax *explicitTS = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	[container setTransferSyntaxForDataset:ts];	
	
	NSException *exception;
	BOOL status = YES;
		
	[self removeGroupLengths];
	
	//need to convert PixelData TransferSyntax
	DCMAttributeTag *pixelData = [DCMAttributeTag tagWithName:@"PixelData"];
	DCMPixelDataAttribute *pixelDataAttr = (DCMPixelDataAttribute *)[attributes objectForKey:[pixelData stringValue]];
	
	//if we have the attr and the conversion failed stop
//	if(ipd == NO && pixelDataAttr && ![pixelDataAttr convertToTransferSyntax: transferSyntax quality:DCMLosslessQuality])
	if( pixelDataAttr && ![pixelDataAttr convertToTransferSyntax: transferSyntax quality:DCMLosslessQuality])
	{
		NSLog(@"Could not convert pixel Data to %@", transferSyntax.description);
		return NO;
	}
	
	if (flag)
	{
		[self updateMetaInformationWithTransferSyntax:ts aet:aet];
		[container addPremable];
	}

	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	for(NSString *key in sortedKeys)
	{
		DCMAttribute *attr = [attributes objectForKey:key];
		if (attr)
		{
			if (flag && ([(DCMAttributeTag *)[attr attrTag] group] == 0x0002))
			{
				[container setUseMetaheaderTS:YES];
				if (![attr writeToDataContainer:container withTransferSyntax:explicitTS])
				{
					exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data", [attr description]] userInfo:nil];
					[exception raise];
				}
			}
			else
			{
				[container setUseMetaheaderTS: NO];
				
//				if( ipd && attr.group == 0x7FE0 && attr.element == 0x0010)
//					[attr writeToDataContainer:container withTransferSyntax: explicitTS];
//				else
				if (![attr writeToDataContainer:container withTransferSyntax: ts])
				{
					exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data with syntax:%@", [attr description], [ts transferSyntax]] userInfo:nil];
					[exception raise];
				}			
			}
		}
	}
	
	return status;
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality asDICOM3:(BOOL)flag{
	return [self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			strippingGroupLengthLength:YES];
}

- (BOOL)writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			strippingGroupLengthLength:(BOOL)stripGroupLength{
	return [self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			AET:@"OSIRIX"
			strippingGroupLengthLength:(BOOL)stripGroupLength];
	}
			

- (BOOL)writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:(BOOL)flag
			AET:(NSString *)aet 
			strippingGroupLengthLength:(BOOL)stripGroupLength
	{
			
	if (ts == nil)
		ts = transferSyntax;
	DCMTransferSyntax *explicitTS = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
	
	NSException *exception = nil;
	BOOL status = YES;
	
	@try
	{
	//routine for Files
	if (stripGroupLength)
		[self removeGroupLengths];
	
	//need to convert PixelData TransferSyntax
	DCMAttributeTag *pixelDataTag = [DCMAttributeTag tagWithName:@"PixelData"];
	DCMPixelDataAttribute *pixelDataAttr = (DCMPixelDataAttribute *)[attributes objectForKey:[pixelDataTag stringValue]];

	//if we have the attr and the conversion failed stop	
	if (pixelDataAttr && ![pixelDataAttr convertToTransferSyntax: ts quality:quality]) {
		NSLog(@"Could not convert pixel Data to %@", ts.description);
		status = NO;
		//return NO;
	}
	[container setTransferSyntaxForDataset:ts];	
	if (DCMDEBUG)
		NSLog(@"Writing DICOM Object with syntax:%@", ts.description);
	//writing Dicom has preamble and metaheader.  Neither for dataset
	if (flag) {
		if (DCMDEBUG)
			NSLog(@"updateMetaInformation newTransferSyntax:%@", ts.description);
		[self updateMetaInformationWithTransferSyntax:ts aet:aet];
		[container addPremable];
	}
	
	//set character set if necessary
	if (!specificCharacterSet && [self attributeValueWithName:@"SpecificCharacterSet"])
		[self setCharacterSet: [[[DCMCharacterSet alloc] initWithCode:[self attributeValueWithName:@"SpecificCharacterSet"]] autorelease]];

	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	for ( NSString *key in sortedKeys)
	{
		//if (DCMDEBUG)
		//	NSLog(@"key:%@ %@", key, NSStringFromClass([key class]));
		DCMAttribute *attr = [attributes objectForKey:key];
		if (attr)
		{
			//skip metaheader for dataset
			if( attr.attrTag.group == 0x0002)
			{
				if ( flag)
				{
					[container setUseMetaheaderTS:YES];
					if (![attr writeToDataContainer:container withTransferSyntax:explicitTS])
					{
						exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data", [attr description]] userInfo:nil];
						[exception raise];
					}
				}
			}
			else
			{
				[container setUseMetaheaderTS:NO];
				
				if( attr.attrTag.group == 0x0008 && attr.attrTag.element == 0x0005)
				{
					[specificCharacterSet release];
					
					if( [[attr values] count] > 1) // DCMFramework doesn't support multi-encoded string when writing -> switch for UTF-8
					{
						specificCharacterSet = [[DCMCharacterSet alloc] initWithCode: @"ISO_IR 192"];
						attr.values = [NSMutableArray arrayWithObject: @"ISO_IR 192"];
					}
					else
						specificCharacterSet = [[DCMCharacterSet alloc] initWithCode: [[attr values] componentsJoinedByString:@"\\"]];
				}
				
				[attr setCharacterSet: specificCharacterSet];
				
				if( ![attr writeToDataContainer: container withTransferSyntax: ts])
				{
					exception = [NSException exceptionWithName:@"DCMWriteDataError" reason:[NSString stringWithFormat:@"Cannot write %@ to data with syntax:%@", [attr description], [ts transferSyntax]] userInfo:nil];
					[exception raise];
				}
			}
		}
	}
	
	}
	
	@catch( NSException *e)
	{
			NSLog(@"Exception:%@ reason:%@", [e name], [e reason]);
		status =  NO;
	}
	
	return status;	
}


- (BOOL)writeToDataContainer:(DCMDataContainer *)container withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality{
	return [self writeToDataContainer:container withTransferSyntax:ts quality:quality asDICOM3:YES];
}

- (BOOL)writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality atomically:(BOOL)flag{
	return [self writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:@"OSIRIX" atomically:(BOOL)flag];
}

- (BOOL)writeToFile:(NSString *)path withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:(NSString *)aet atomically:(BOOL)flag
{
	BOOL status = NO;
	@try {		
		DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
		//if ([self writeToDataContainer:container withTransferSyntax:ts quality:quality]) {
			if ([self writeToDataContainer:(DCMDataContainer *)container 
					withTransferSyntax:(DCMTransferSyntax *)ts 
					quality:(int)quality 
					asDICOM3:YES
					AET:(NSString *)aet
					strippingGroupLengthLength:YES]) {
			status =  [[container dicomData] writeToFile:path atomically:flag];
		}
		else
			status  = NO;
		
	} @catch( NSException *localException) {
		NSLog(@"Writing to %@ failed", path);
		status = NO;
	}
	
		return status;
}


- (BOOL)writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality atomically:(BOOL)flag {
	return [self writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:@"OSIRIX" atomically:(BOOL)flag];
}

- (BOOL)writeToURL:(NSURL *)aURL withTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality AET:(NSString *)aet atomically:(BOOL)flag{
	BOOL status = NO;
	@try {
	DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
	//if ([self writeToDataContainer:container withTransferSyntax:ts quality:quality])
	if ([self writeToDataContainer:(DCMDataContainer *)container 
					withTransferSyntax:(DCMTransferSyntax *)ts 
					quality:(int)quality 
					asDICOM3:YES
					AET:(NSString *)aet
					strippingGroupLengthLength:YES]) 
		status =  [[container dicomData] writeToURL:aURL atomically:flag];
	else
		status =  NO;
	} @catch( NSException *localException) {
		
	}
		return status;
}

//This is for creatina a dataset for sending. Need to strip FileMetaData first.

- (NSData *)writeDatasetWithTransferSyntax:(DCMTransferSyntax *)ts quality:(int)quality{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
	NSData *data;
	@try {
	if ([self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:(DCMTransferSyntax *)ts 
			quality:(int)quality 
			asDICOM3:NO
			strippingGroupLengthLength:YES]) 
				// retain data to avoid autorelease
				data = [[container dicomData] retain];
	else
		data = nil; 
	}
    @catch( NSException *localException) {
		data = nil;
	}
	@finally {
        [pool release];
    }
    
	[data autorelease];
	return data;

}

//subclasses can overide to just pick out certain attributes and speed up 
- (BOOL)isNeededAttribute:(char *)tagString{
	return YES;
}

- (NSXMLNode *)xmlNode{
	NSXMLNode *myNode;

	NSMutableArray *elements = [NSMutableArray array];

	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	for  ( NSString *key in sortedKeys ) {
		DCMAttribute *attr = [attributes objectForKey:key];
		if (attr) 
			[elements addObject:[attr xmlNode]];
		
	}
	
	myNode = [NSXMLNode elementWithName:@"item" children:elements attributes:nil];
	return myNode;
}

- (NSXMLDocument *)xmlDocument
{
	NSXMLElement *rootElement = [[[NSXMLElement alloc] initWithName:@"DICOMObject"] autorelease];
	NSMutableArray *mutableKeys = [NSMutableArray arrayWithArray:[attributes allKeys]];
	NSArray *sortedKeys = [mutableKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	for ( NSString *key in sortedKeys)
	{
		DCMAttribute *attr = [attributes objectForKey:key];
		if (attr)
		{
			[rootElement addChild:[attr xmlNode]];
		}
		
	}
		
	NSXMLDocument *xmlDocument = [[[NSXMLDocument alloc] initWithRootElement:rootElement] autorelease];
	NSError *error = nil;
	if(![xmlDocument validateAndReturnError:&error])
	NSLog(@"xml Document erorr:\n%@", [error description]);
	return xmlDocument;
}

//accessing frequent sequences
- (NSArray *)referencedSeriesSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"ReferencedSeriesSequence"] sequenceItems];
}

- (NSArray *)referencedImageSequenceForObject:(DCMObject *)object{
	return [(DCMSequenceAttribute *)[object attributeWithName:@"ReferencedImageSequence"] sequenceItems];
}

//Structured Report Object
+(id)objectWithCodeValue:(NSString *)codeValue  
			codingSchemeDesignator:(NSString *)codingSchemeDesignator  
			codeMeaning:(NSString *)codeMeaning{
	DCMObject *dcmObject = [DCMObject  dcmObject];

	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codeValue] forName:@"CodeValue"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codingSchemeDesignator] forName:@"CodingSchemeDesignator"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:codeMeaning] forName:@"CodeMeaning"];

	return dcmObject;
		
}

@end
