//
//  O2DicomPredicateEditor.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 06.12.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface O2DicomPredicateEditor : NSPredicateEditor {
@private
    BOOL _inited, _inValidateEditing, _dbMode;
}

@property(nonatomic) BOOL dbMode;

@end

