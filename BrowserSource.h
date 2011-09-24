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

#import <Cocoa/Cocoa.h>


@class DicomDatabase, PrettyCell;

enum {
	BrowserSourceTypeDefault,
	BrowserSourceTypeLocal,
	BrowserSourceTypeRemote,
	BrowserSourceTypeDicom,
	BrowserSourceTypeOther
};
typedef NSInteger BrowserSourceType;


@interface BrowserSource : NSObject {
	BrowserSourceType _type;
	NSString* _location;
	NSString* _description;
	NSDictionary* _dictionary;
//	NSView* _extraView;
}

+(id)browserSourceForLocalPath:(NSString*)path;
+(id)browserSourceForLocalPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary;
+(id)browserSourceForAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary;
+(id)browserSourceForDicomNodeAtAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary;

@property(readonly) BrowserSourceType type;
@property(retain) NSString* location;
@property(retain) NSString* description;
@property(retain) NSDictionary* dictionary;
//@property(retain) NSView* extraView;

-(BOOL)isEqualToSource:(BrowserSource*)other;
-(NSComparisonResult)compare:(BrowserSource*)other;

-(DicomDatabase*)database;

-(void)willDisplayCell:(PrettyCell*)cell;

-(BOOL)isVolatile; // like bonjour sources, CD/DVDs, ...
-(BOOL)isReadOnly;
-(NSString*)toolTip;

-(NSInteger)subtypeForSorting;

@end
