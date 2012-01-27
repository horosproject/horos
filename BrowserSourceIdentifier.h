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
	BrowserSourceIdentifierTypeDefault,
	BrowserSourceIdentifierTypeLocal,
	BrowserSourceIdentifierTypeRemote,
	BrowserSourceIdentifierTypeDicom,
	BrowserSourceIdentifierTypeOther
};
typedef NSInteger BrowserSourceIdentifierType;


@interface BrowserSourceIdentifier : NSObject {
	BrowserSourceIdentifierType _type;
	NSString* _location;
	NSString* _description;
	NSDictionary* _dictionary;
//	NSView* _extraView;
}

+(id)browserSourceIdentifierForLocalPath:(NSString*)path;
+(id)browserSourceIdentifierForLocalPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary;
+(id)browserSourceIdentifierForAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary;
+(id)browserSourceIdentifierForDicomNodeAtAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary;

@property(readonly) BrowserSourceIdentifierType type;
@property(retain) NSString* location;
@property(retain) NSString* description;
@property(retain) NSDictionary* dictionary;
//@property(retain) NSView* extraView;

-(BOOL)isEqualToSourceIdentifier:(BrowserSourceIdentifier*)other;
-(NSComparisonResult)compare:(BrowserSourceIdentifier*)other;

-(DicomDatabase*)database;

-(void)willDisplayCell:(PrettyCell*)cell;

-(BOOL)isVolatile; // like bonjour sources, CD/DVDs, ...
-(BOOL)isReadOnly;
-(NSString*)toolTip;

-(NSInteger)subtypeForSorting;

@end
