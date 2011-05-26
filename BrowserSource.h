//
//  BrowserSource.h
//  OsiriX
//
//  Created by Alessandro Volz on 06.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DicomDatabase, ImageAndTextCell;

enum { BrowserSourceTypeDefault, BrowserSourceTypeLocal, BrowserSourceTypeRemote, BrowserSourceTypeDicom, BrowserSourceTypeOther };

@interface BrowserSource : NSObject {
	NSInteger _type;
	NSString* _location;
	NSString* _description;
	NSDictionary* _dictionary;
//	NSView* _extraView;
}

+(id)browserSourceForLocalPath:(NSString*)path;
+(id)browserSourceForLocalPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary;
+(id)browserSourceForAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary;
+(id)browserSourceForDicomNodeAtAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary;

@property(readonly) NSInteger type;
@property(retain) NSString* location;
@property(retain) NSString* description;
@property(retain) NSDictionary* dictionary;
//@property(retain) NSView* extraView;

-(BOOL)isEqualToSource:(BrowserSource*)other;
-(NSComparisonResult)compare:(BrowserSource*)other;

-(DicomDatabase*)database;

-(void)willDisplayCell:(ImageAndTextCell*)cell;

-(BOOL)isRemovable;
-(NSString*)toolTip;

@end
