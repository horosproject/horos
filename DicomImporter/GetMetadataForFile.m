#include <CoreFoundation/CoreFoundation.h>


#include <CoreFoundation/CFPlugInCOM.h>
#include <CoreServices/CoreServices.h>
#include <Foundation/Foundation.h>
#include <stdio.h>
#include <unistd.h>
#include <OsiriX/DCM.h>

/* ================================== CONDUIT IMPLEMENTATION  ================================== */

/* === (1) First,  update PLUGIN_ID with a unique GUUID for your
 *         importer obtained by running uuidgen
 */

#define PLUGIN_ID    CFUUIDCreateFromString(kCFAllocatorDefault,CFSTR("5EB7A96E-AFF6-435C-BE69-07AAE5C63EEE"))


/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */



// -----------------------------------------------------------------------------
//	Get metadata attributes from file
//
// This function's job is to extract useful information your file format supports
// and return it as a dictionary
// -----------------------------------------------------------------------------

Boolean GetMetadataForFile(void *thisInterface,
			   CFMutableDictionaryRef attributes,
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
        /* Pull any available metadata from the file at the specified path */
        /* Return the attribute keys and attribute values in the dict */
        /* Return TRUE if successful, FALSE if there was no data provided */
    Boolean success=NO;
    NSAutoreleasePool *pool;
	DCMObject *dcmObject;
        // Don't assume that there is an autorelease pool around the calling of this function.
    pool = [[NSAutoreleasePool alloc] init];
		// load the document at the specified location
	//NSLog(@"Dicom Importer");

	dcmObject = [[DCMObject alloc] initWithContentsOfFile:(NSString *)pathToFile decodingPixelData:NO];
	//if ((NSString *)contentTypeUTI == @"public.dcm"){
		
	if (dcmObject) {
		//NSLog(@"Have Dicom File");
		//if ([(NSString *)pathToFile hasSuffix:@"dcm"]) {
			[(NSMutableDictionary *)attributes setObject:@"public.dcm"
			forKey:(NSString *)kMDItemContentType];
		//}
		//Patient Attrs
			DCMAttribute *attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"PatientsName"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_PatientsName"];
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"PatientID"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_PatientID"];
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"PatientsSex"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_PatientsSex"];
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"PatientsAge"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_PatientsAge"];
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"PatientsBirthDate"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:(NSDate *)[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriXPatientsBirthDate"];
									
									
			//Study Attrs						
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"StudyDescription"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_StudyDescription"];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"StudyID"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_StudyID"];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"StudyDate"]];
			if (attr) {
				NSCalendarDate *date = [attr value];
				NSCalendarDate *time =  [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"StudyTime"]] value];
				//descriptionWithCalendarFormat:timeZone:locale:
				NSCalendarDate *fullDate = [NSCalendarDate dateWithYear:[date yearOfCommonEra]  month:[date monthOfYear] day:[date dayOfMonth] hour:[time hourOfDay] minute:[time minuteOfHour] second:[time secondOfMinute] timeZone:nil];
				[(NSMutableDictionary *)attributes setObject:(NSDate *)fullDate
									forKey:(NSString *)@"com_rossetantoine_osiriX_StudyDate"];
			}
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"StudyInstanceUID"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_StudyInstanceUID"];
									
			//Series Attrs						
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SeriesDescription"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_SeriesDescription"];
			
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SeriesInstanceUID"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_SeriesInstanceUID"];
			
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SeriesNumber"]];
			if (attr) {
				int seriesNumber = [[attr value] intValue];
				[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:seriesNumber]
									forKey:(NSString *)@"com_rossetantoine_osiriX_SeriesNumber"];
			}
			
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SeriesDate"]];
			if (attr) {
				NSCalendarDate *date = [attr value];
				NSCalendarDate *time =  [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SeriesTime"]] value];
				//descriptionWithCalendarFormat:timeZone:locale:
				NSCalendarDate *fullDate = [NSCalendarDate dateWithYear:[date yearOfCommonEra]  month:[date monthOfYear] day:[date dayOfMonth] hour:[time hourOfDay] minute:[time minuteOfHour] second:[time secondOfMinute] timeZone:nil];
				[(NSMutableDictionary *)attributes setObject:(NSDate *)fullDate
									forKey:(NSString *)@"com_rossetantoine_osiriX_SeriesDate"];
			}
									
														
			// Image Attrs																					
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Rows"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)kMDItemPixelHeight];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Columns"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)kMDItemPixelWidth];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"PhotometricInterpretation"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)kMDItemColorSpace];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"BitsStored"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)kMDItemBitsPerSample];
			
			
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionDate"]];
			if (attr) {
				NSCalendarDate *date = [attr value];
				NSCalendarDate *time =  [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"AcquisitionTime"]] value];
				//descriptionWithCalendarFormat:timeZone:locale:
				NSCalendarDate *fullDate = [NSCalendarDate dateWithYear:[date yearOfCommonEra]  month:[date monthOfYear] day:[date dayOfMonth] hour:[time hourOfDay] minute:[time minuteOfHour] second:[time secondOfMinute] timeZone:nil];
				[(NSMutableDictionary *)attributes setObject:(NSDate *)fullDate
									forKey:(NSString *)@"com_rossetantoine_osiriX_SOPInstanceUID"];
				//Maybe try kMDItemContentCreationDate
			}
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"InstanceNumber"]];
			if (attr) {
				int instanceNumber = [[attr value] intValue];
				[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:instanceNumber]
									forKey:(NSString *)@"com_rossetantoine_osiriX_AcquisitionDate"];
			}
			
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SOPInstanceUID"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_SOPInstanceUID"];
									
			//General Attrs
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"InstitutionName"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_InstitutionName"];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Modality"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_Modality"];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"ReferringPhysiciansName"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_ReferringPhysiciansName"];
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"RPerformingPhysiciansName"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)@"com_rossetantoine_osiriX_PerformingPhysiciansName"];
									
			
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"TransferSyntaxUID"]];
			if (attr) {
				DCMTransferSyntax *ts = [[DCMTransferSyntax alloc] initWithTS:[attr value]];
				
				[(NSMutableDictionary *)attributes setObject:[ts name]
									forKey:(NSString *)@"com_rossetantoine_osiriX_TransferSyntax"];
				[ts release];
			}
															
									
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"Manufacturer"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)kMDItemAcquisitionMake];
			attr = [dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"ManufacturersModelName"]];
			if (attr)
				[(NSMutableDictionary *)attributes setObject:[attr value]
									forKey:(NSString *)kMDItemAcquisitionModel];


			// return YES so that the attributes are imported
			success=YES;
			



			[dcmObject release];
		}
	//}
		
	    [pool release];
    return success;
}

