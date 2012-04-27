//
//  O2ScreensPrefsView.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 03.04.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface O2ScreensPrefsView : NSControl {
    NSMutableArray* _records;
    id /*_hoveringRecord, */_activeRecord;
}

@end
