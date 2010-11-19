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

#import "WebPortalData.h"


@interface WebPortalPages : NSObject

@end


@interface ArrayTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


@interface DateTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


@interface AlbumTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end


@interface UserTransformer : WebPortalProxyObjectTransformer
+(id)create;
@end