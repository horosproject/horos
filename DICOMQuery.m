/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DICOMQuery.h"
//#import "PMQueryTreeModel.h"
//#import "PMAttributeTag.h"

@implementation DICOMQuery

- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort{
	if (self = [super init]) {
		callingAET = [myAET retain];
		calledAET = [theirAET retain];
		hostname = [host retain];
		port = [tcpPort retain];
		filters = [[NSMutableDictionary alloc] init];
		
		keys = [[NSArray arrayWithObjects:
		@"PatientsName", 
		@"PatientID", 
		@"PatientsBirthDate", 
		@"PatientsSex",
		@"PatientsAge", 		
		@"StudyID", 
		@"StudyDescription",
		
		@"ModalitiesInStudy", 
		@"Modality",
		@"StudyDate", 
		@"StudyTime", 
		@"StudyInstanceUID", 
		
		@"SeriesDescription", 
		@"SeriesNumber",
		@"SeriesDate", 
		@"SeriesTime", 
		@"SeriesInstanceUID", 
		
		@"InstanceNumber",
		@"ContentDate", 
		@"ContentTime", 
		@"ImageType", 
		
		//@"NumberOfFrames", 
		@"SOPInstanceUID", 
		
		@"SpecificCharacterSet", 
		@"SOPClassUID", 
		
		nil] retain];
		
	javaNames =  [[NSArray arrayWithObjects:
		@"DICOMPersonNameAttribute",					//pt name
		@"DICOMShortStringAttribute",					//pt ID
		@"DICOMDateAttribute",							//pt BD
		@"DICOMCodeStringAttribute",		//pt sex
		@"DICOMAgeStringAttribute",		//pt age		
		@"DICOMShortStringAttribute",		//study ID
		@"DICOMLongStringAttribute",		//study description
		
		@"DICOMCodeStringAttribute",		//modalities
		@"DICOMCodeStringAttribute",		//modality
		@"DICOMDateAttribute",			//study date
		@"DICOMTimeAttribute",			//study Time
		@"DICOMUniqueIdentifierAttribute",  //study UID
		
		@"DICOMLongStringAttribute",		//Series description
		@"DICOMIntegerStringAttribute",  //series Number
		@"DICOMDateAttribute",			//series date
		@"DICOMTimeAttribute",			//series Time
		@"DICOMUniqueIdentifierAttribute",  //seriesUID 
		
		@"DICOMIntegerStringAttribute",   //instance number
		@"DICOMDateAttribute",			//contentDate
		@"DICOMTimeAttribute",			//content Time
		@"DICOMCodeStringAttribute",		//Image Type
		
	//	@"com.pixelmed.dicom.IntegerStringAttribute",   //Number of Frames
		@"com.pixelmed.dicom.UniqueIdentifierAttribute",  //Instance UID
		
		@"DICOMCodeStringAttribute",		//specific Character set
		@"DICOMUniqueIdentifierAttribute", //Class UID
		
		nil] retain];
		//NSLog(@"javaNAme count %d", [javaNames count]);
	//	PMAttributeTag *aTag = [NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientNameTag]; 
	//	NSLog(@"tag %@",NSStringFromClass( [aTag class]))
	
	tags = [[NSArray arrayWithObjects:
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientNameTag], 
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientIDTag], 
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientBDTag], 
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientSexTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientAgeTag],		
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyIDTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyDescriptionTag],
		
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ModalitiesInStudyTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ModalityTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyDateTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyTimeTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyInstanceUIDTag],
		
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SeriesDescriptionTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SeriesNumberTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SeriesDateTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SeriesTimeTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SeriesInstanceUIDTag],
			
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", InstanceNumberTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ContentDateTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ContentTimeTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ImageTypeTag],
	
		//[NSClassFromString(AttributeTag) newWithSignature:@"(II)", NumberOfFramesTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SOPInstanceUIDTag],
		
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SpecificCharacterSetTag],
		[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SOPClassUIDTag],
		
		nil] retain];

	}
	return self;
}

- (void)dealloc{
	[callingAET release];
	[calledAET release];
	[hostname release];
	[port release];
	[filters release];
	[queryModel release];
	[tags release];
	[keys release];
	[javaNames release];
	[tree release];
}

- (void)addFilter:(NSString *)filter forTag:(NSString *)tag{
}
- (void)addFilter:(NSString *)filter forDescription:(NSString *)description{
}
- (BOOL)performQuery{
	return NO;
}

- (BOOL)performRetrieveWithValue:(NSString *)value forTag:(NSString *)tag{
	return NO;
}

- (BOOL)performRetrieveWithAttributeList:(id)attrList atLevel:(NSString*)description{
	return NO;
}
- (id)queryRoot{
	return nil;
}
@end
