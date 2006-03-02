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




#import "DICOMQueryStudyRoot.h"
#import "PMStudyRootQueryInformationModel.h"
//#import "PMAttributeList.h"
//#import "PMPersonNameAttribute.h"
//#import "PMSpecificCharacterSet.h"
//#import "PMAttributeTag.h"
//#import "PMQueryTreeModel.h"
//#import "DICOMPersonNameAttribute.h"
//#import "PMDirectoryRecord.h"
#import "MutableArrayCategory.h"
#import "AppController.h"
//#import "dicomFile.h"

extern NSString *QUERYCHARACTERSET;




@implementation DICOMQueryStudyRoot

- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort{
	if (self = [super initWithCallingAET:myAET calledAET:theirAET  hostName:host  port:tcpPort]){ 
		//Class StudyRoot = NSClassFromString(@"com.pixelmed.query.StudyRootQueryInformationModel");
		Class StudyRoot = NSClassFromString(@"DICOMQueryManager");
		queryModel = [StudyRoot newWithSignature:@"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)", hostname, port, calledAET, callingAET,0];
		//NSLog(@"class %@", NSStringFromClass(StudyRoot));
		//NSLog(@"model %@",NSStringFromClass([queryModel class]));
		
		
	}
	return self;
}

- (void)dealloc{
	[filterList release];
	[queryList release];
}

- (void)addFilter:(NSString *)filter forTag:(NSString *)tag{
		NSBundle *bundle = [NSBundle mainBundle];    
        NSString *path = [bundle pathForResource:@"dicomDictionary" ofType:@"plist"];
		if( path == 0L) NSLog(@"Cannot find dicomDictionary");
        NSDictionary *dd = [[[NSDictionary alloc] initWithContentsOfFile:path] retain];
		[self addFilter:filter forDescription:[[dd objectForKey:tag] objectForKey:@"Description"]];
}

- (void)addFilter:(NSString *)filter forDescription:(NSString *)description{
	//NSLog (@"Filter %@ description %@", filter, description);
	[filters setObject:filter forKey:description];

}

- (BOOL)performQuery{
	/*
	Possible Attributes for Query
		Patient Level:  PatientName, PatientID, PatientBirthDate, PatientSex, PatientAge
		Study Level: StudyID, StudyDescription, Modalities in Study, Modality, StudyDate, StudyTime, StudyInstanceUID
		Series Level:SeriesDescription, SeriesNumber, SeriesDate, SeriesTime, SeriesInstanceUID
		Instance Level: InstanceNumber, ContentDate, ContentTime, ImageType, NUmberOfRame SOPInstanceUID
		other: SpecificCharacterSet, SOPClassUID
	*/
			//NSLog(@"tags count %d", [tags count]);

	NSMutableDictionary *javaNameDictionary = [NSMutableDictionary dictionaryWithObjects:javaNames forKeys:keys];	
	NSMutableDictionary *tagDictionary = [NSMutableDictionary dictionaryWithObjects:tags forKeys:keys];	
	NSArray *descriptions = [filters allKeys];

	filterList = [[NSClassFromString(@"com.pixelmed.dicom.AttributeList") alloc] init];
	//NSLog(@"filterList");
	//PMSpecificCharacterSet *specificCharacterSet = [[[NSClassFromString(SpecificCharacterSet) alloc] init] autorelease];
	//NSLog(@"character set %@", NSStringFromClass([specificCharacterSet class]));
	NSEnumerator *enumerator = [tagDictionary keyEnumerator];
	NSString *key;
	/*
	PMAttributeTag *aTag = [tagDictionary objectForKey:@"SpecificCharacterSet"];
	PMAttribute *scsAttr = [NSClassFromString([javaNameDictionary objectForKey:@"SpecificCharacterSet"]) newWithSignature:@"(Lcom/pixelmed/dicom/AttributeTag;)",aTag];
	[scsAttr addStringValue:(NSString *)QUERYCHARACTERSET];
	[filterList put:aTag :scsAttr];
	id specificCharacterSet =  [NSClassFromString(@"com.pixelmed.dicom.SpecificCharacterSetExtension") newWithSignature:@"([Lcom/pixelmed/dicom/Attribute;", scsAttr];
	*/
	while (key = [enumerator nextObject]) {
		//NSLog(@"key %@", key);
		//PMAttributeTag *tag;
		//PMAttribute *attr;
		
		tag = [tagDictionary objectForKey:key];
		/*
		if ([key isEqualToString:@"PatientsName"]){
			//Class SpecificCharacterSet = NSClassFromString(@"com.pixelmed.dicom.SpecificCharacterSet");
			id specificCharacterSet = [NSClassFromString(@"com.pixelmed.dicom.SpecificCharacterSet") newWithSignature:@"([Ljava/lang/String;", [scsAttr getStringValues]];
			NSLog(@"character set %@", NSStringFromClass([specificCharacterSet class]));
			attr = [NSClassFromString([javaNameDictionary objectForKey:key]) newWithSignature:@"(Lcom/pixelmed/dicom/AttributeTag;Lcom/pixelmed/dicom/SpecificCharacterSet;)",tag, specificCharacterSet];
		}
		else
		*/
			attr = [NSClassFromString([javaNameDictionary objectForKey:key]) newWithSignature:@"(Lcom/pixelmed/dicom/AttributeTag;)",tag];
		//NSLog(@"class %@", NSStringFromClass([attr class]));
		[filterList put:tag :attr];
		if ([descriptions containsString:key]) {	
			[attr addStringValue:(NSString *)[filters objectForKey:key]];
		}
		 //[filterList put:aTag :scsAttr];

	}
	NS_DURING
	tree = [[queryModel performHierarchicalQuery:filterList] retain];
	[self createQueryList];
	NS_HANDLER
		return NO;
	NS_ENDHANDLER

	return YES;
}

- (BOOL)performRetrieveWithValue:(NSString *)value forTag:(NSString *)tag{
	//NSLog(@"performRetrieveforTag %@", value);
	NSBundle *bundle = [NSBundle mainBundle];    
	NSString *path = [bundle pathForResource:@"dicomDictionary" ofType:@"plist"];
	if( path == 0L) NSLog(@"Cannot find dicomDictionary");
	NSDictionary *dd = [[[NSDictionary alloc] initWithContentsOfFile:path] retain];	
	[self performRetrieveWithValue:value forDescription:[[dd objectForKey:tag] objectForKey:@"Description"]];
}



- (BOOL)performRetrieveWithAttributeList:(id)attrList atLevel:(NSString*)description{
/*
	com.pixelmed.network.MoveSOPClassSCU.MoveSOPClassSCU
( 
String hostname,
String port,
String calledAETitle,
String callingAETitle,
String moveDestination,
String affectedSOPClass,
AttributeList identifier,
int debugLevel

) 
throws DicomNetworkException, DicomException, IOException

SOPClass.StudyRootQueryRetrieveInformationModelMove
*/
	NSString *studyRootQRInformationModelMove = @"1.2.840.10008.5.1.4.1.2.2.2";
	//PMAttributeTag *tag = [NSClassFromString(AttributeTag) newWithSignature:@"(II)", QueryRetrieveLevelTag];
	//PMAttribute *attr = [NSClassFromString(@"DICOMCodeStringAttribute") newWithSignature:@"(Lcom/pixelmed/dicom/AttributeTag;)",tag];
	
	if ([description isEqualToString:@"StudyInstanceUID"])
		[attr addStringValue:@"STUDY"];
	else if ([description isEqualToString:@"SeriesInstanceUID"])
		[attr addStringValue:@"SERIES"];
	else
		[attr addStringValue:@"IMAGE"];
	
	//[attrList put:tag :attr];
	//Class MoveSCU = NSClassFromString(@"com.pixelmed.network.MoveSOPClassSCU");
	//Class MoveSCU = NSClassFromString(@"com.pixelmed.network.DICOMMoveSCU");
	//NSLog(@"list: %@", [attrList toString]);	
	NS_DURING	
	id	moveSCU = [MoveSCU newWithSignature:@"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/pixelmed/dicom/AttributeList;I)", hostname,port, calledAET, callingAET,callingAET,studyRootQRInformationModelMove,attrList,0];
	//NSLog(@"class %@", NSStringFromClass(MoveSCU));
	//NSLog(@"model %@", NSStringFromClass([moveSCU class]));
	NS_HANDLER
		NSLog(@"MoveSCU failed");
		return NO;
	NS_ENDHANDLER
	
	return YES;
}

- (id)queryRoot{
	return [tree getRoot];
}

-(NSArray *)queryList{
	return queryList;
}

- (void)createQueryList{
	//NSLog(@"Create Query");
	PMDirectoryRecord *root = [tree getRoot];
	id children = [root children];
	PMDirectoryRecord *child;	
	if (queryList)
		[queryList release];
	queryList = [[NSMutableArray array] retain];
	//NSLog(@"root %@ children %@", NSStringFromClass([root class]), NSStringFromClass([children class]));
	while ([children hasMoreElements]) {
		//NSLog(@"list count %d" ,[queryList count]);	
		child = [children nextElement];
		[queryList addObject:[self createRecord:child]];
					
	}
	//NSLog(@"query count %d" ,[queryList count]);

}

- (void) sortQueryList:(NSArray *)sortDescriptors{
	[queryList sortUsingDescriptors:sortDescriptors];
}

// create Records for StudyList from Java Directory Records
- (NSDictionary *)createRecord:(PMDirectoryRecord *)directoryRecord{
	
	NSMutableDictionary *record = [NSMutableDictionary dictionary];
	PMAttributeList *attrList = [directoryRecord getAllAttributesReturnedInIdentifier];
	//NSLog(@"attrList %@", [attrList toString]);
	PMAttribute *patient = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientNameTag]];
	PMAttribute *patientID = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", PatientIDTag]];
	PMAttribute *modality = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ModalityTag]];
	PMAttribute *modalitiesInStudy = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", ModalitiesInStudyTag]];
	PMAttribute *description = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyDescriptionTag]];
	PMAttribute *attr = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyDateTag]];
	PMAttribute *attrTime = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", StudyTimeTag]];
	PMAttribute *specificCharacterSet = [attrList get:[NSClassFromString(AttributeTag) newWithSignature:@"(II)", SpecificCharacterSetTag]];
	//NSLog(@"Attr");
	NSCalendarDate *date  = [NSCalendarDate 
    dateWithString:[attr getSingleStringValueOrEmptyString]
    calendarFormat:@"%Y%m%d"];
	NSCalendarDate *time  = [NSCalendarDate 
    dateWithString:[attrTime getSingleStringValueOrEmptyString]
    calendarFormat:@"%H%M%S"];
	//NSLog(@"date time");
	//add objects individually in case one is nil
	if ([patient getSingleStringValueOrEmptyString] );
		[record setObject:[patient getSingleStringValueOrEmptyString] forKey:@"Patient"];
	if ([patientID getSingleStringValueOrEmptyString])
		[record setObject:[patientID getSingleStringValueOrEmptyString] forKey:@"Patient ID"];
	//sometimes Modlaity is used sometime Modalities in study. Try both
	if ([modality getSingleStringValueOrEmptyString])
		[record setObject:[modality getSingleStringValueOrEmptyString] forKey:@"Modality"];
	else if ([modalitiesInStudy getSingleStringValueOrEmptyString])
		[record setObject:[modalitiesInStudy getSingleStringValueOrEmptyString] forKey:@"Modality"];
	if ([description getSingleStringValueOrEmptyString])
		[record setObject:[description getSingleStringValueOrEmptyString] forKey:@"Description"];
	if (date)
		[record setObject:date forKey:@"Study Date"];
	if (time)
		[record setObject:time forKey:@"Study Time"];
	[record setObject:directoryRecord forKey:@"Directory Record"];
	//NSLog(@"End create REcord");
	return record;
}

@end
