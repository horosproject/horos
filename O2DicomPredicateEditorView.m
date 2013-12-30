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

#import "O2DicomPredicateEditorView.h"
#import "O2DicomPredicateEditor.h"

#import "O2DicomPredicateEditorCodeStrings.h"
#import "O2DicomPredicateEditorDCMAttributeTag.h"

#import "O2DicomPredicateEditorPopUpButton.h"
#import "O2DicomPredicateEditorDatePicker.h"
#import "O2DicomPredicateEditorFormatters.h"

#import "N2Operators.h"
#import "N2Debug.h"
#import "N2CustomTitledPopUpButtonCell.h"
#import "NS(Attributed)String+Geometrics.h"
#import "NSString+N2.h"
#import "DCMTagDictionary.h"
#import "DCMAttribute.h"

#import <objc/runtime.h>

static NSMutableArray* tagsCache = nil;
static NSMutableArray* menuItemsCache = nil;

@interface NSComparisonPredicate (OsiriX)

- (id)collection;
- (id)constantValue;
- (NSString*)function;
- (NSString*)keyPath;
- (NSString*)variable;
- (NSArray*)arguments;

@end

@implementation O2DicomPredicateEditorView

@synthesize tagsSortKey = _tagsSortKey;

@synthesize tag = _tag;
@synthesize operator = _operator;
@synthesize stringValue = _stringValue;
@synthesize numberValue = _numberValue;
@synthesize dateValue = _dateValue;
@synthesize within = _within;
@synthesize codeStringTag = _codeStringTag;

static const NSInteger O2DicomPredicateEditorSortTagsByName = 0;
static const NSInteger O2DicomPredicateEditorSortTagsByTag = 1;

typedef NSInteger O2TimeTag;
enum /*typedef NS_ENUM(NSInteger, O2TimeTag)*/ { // these values are runtime only, you can change them without consequences, keep them negative so you won't risk reusing NSPredicateOperatorType values
    O2Today = -1,
    O2Yesterday = -2,
    O2Within = -3,
    O21Hour = -4,
    O26Hours = -5,
    O212Hours = -6,
    O21Day = O2Today,
    O22Days = -7,
    O21Week = -8,
    O21Month = -9,
    O22Months = -10,
    O23Months = -11,
    O21Year = 12,
    O2DayBeforeYesterday = -13,
};

static NSString* const O2VarToday = @"NSDATE_TODAY";
static NSString* const O2VarYesterday = @"NSDATE_YESTERDAY";
static NSString* const O2Var1Hour = @"NSDATE_LASTHOUR";
static NSString* const O2Var6Hours = @"NSDATE_LAST6HOURS";
static NSString* const O2Var12Hours = @"NSDATE_LAST12HOURS";
static NSString* const O2Var1Day = @"NSDATE_TODAY"; // O2VarToday
static NSString* const O2Var2Days = @"NSDATE_2DAYS";
static NSString* const O2Var1Week = @"NSDATE_WEEK";
static NSString* const O2Var1Month = @"NSDATE_MONTH";
static NSString* const O2Var2Months = @"NSDATE_2MONTHS";
static NSString* const O2Var3Months = @"NSDATE_3MONTHS";
static NSString* const O2Var1Year = @"NSDATE_YEAR";
#define LegacyTimeKey(str) [str substringFromIndex:7]
#define UnLegacyTimeKey(str) [@"NSDATE_" stringByAppendingString:str]

+ (NSArray*)timeKeys {
    NSArray* timeKeys = nil;
    if (!timeKeys)
        timeKeys = [[NSArray alloc] initWithObjects: O2Var1Hour, O2Var6Hours, O2Var12Hours, O2Var1Day, O2Var2Days, O2Var1Week, O2Var1Month, O2Var2Months, O2Var3Months, O2Var1Year, nil];
    return timeKeys;
}

+ (NSArray*)legacyTimeKeys {
    NSMutableArray* legacyTimeKeys = nil;
    if (!legacyTimeKeys) {
        legacyTimeKeys = [[NSMutableArray alloc] init];
        for (NSString* key in [self timeKeys])
            [legacyTimeKeys addObject:LegacyTimeKey(key)];
    }
    
    return legacyTimeKeys;
}

+ (O2TimeTag)timeTagFromKey:(NSString*)key {
    if ([key isEqualToString:O2Var1Day])
        return O21Day;
    if ([key isEqualToString:O2Var2Days])
        return O22Days;
    if ([key isEqualToString:O2Var1Week])
        return O21Week;
    if ([key isEqualToString:O2Var1Month])
        return O21Month;
    if ([key isEqualToString:O2Var2Months])
        return O22Months;
    if ([key isEqualToString:O2Var3Months])
        return O23Months;
    if ([key isEqualToString:O2Var1Year])
        return O21Year;
    if ([key isEqualToString:O2Var1Hour])
        return O21Hour;
    if ([key isEqualToString:O2Var6Hours])
        return O26Hours;
    if ([key isEqualToString:O2Var12Hours])
        return O212Hours;
    
    return 0;
}

+ (NSString*)timeKeyFromTag:(O2TimeTag)tk {
    switch (tk) {
        case O21Day:
            return O2Var1Day; break;
        case O22Days:
            return O2Var2Days; break;
        case O21Week:
            return O2Var1Week; break;
        case O21Month:
            return O2Var1Month; break;
        case O22Months:
            return O2Var2Months; break;
        case O23Months:
            return O2Var3Months; break;
        case O21Year:
            return O2Var1Year; break;
        case O21Hour:
            return O2Var1Hour; break;
        case O26Hours:
            return O2Var6Hours; break;
        case O212Hours:
            return O2Var12Hours; break;
        case O2Yesterday:
            return O2VarYesterday;
        case O2DayBeforeYesterday:
            return O2Var2Days;
        case O2Within:
            return nil;
    }
    
    return nil;
}

#ifndef OF
#define OF 0x4F46
#endif

typedef NSUInteger O2ValueRepresentation;
enum /*typedef NS_ENUM(NSUInteger, O2ValueRepresentation)*/ {
    O2AE = DCM_AE,
    O2AS = DCM_AS,
//    O2AT = AT,
    O2CS = DCM_CS,
    O2DA = DCM_DA,
    O2DS = DCM_DS,
    O2DT = DCM_DT,
    O2FL = DCM_FL,
    O2FD = DCM_FD,
    O2IS = DCM_IS,
    O2LO = DCM_LO,
    O2LT = DCM_LT,
//    O2OB = OB,
//    O2OF = OF,
//    O2OW = OW,
    O2PN = DCM_PN,
    O2SH = DCM_SH,
    O2SL = DCM_SL,
//    O2SQ = SQ,
    O2SS = DCM_SS,
    O2ST = DCM_ST,
    O2TM = DCM_TM,
    O2UI = DCM_UI,
    O2UL = DCM_UL,
//    O2UN = UN,
    O2US = DCM_US,
    O2UT = DCM_UT
};

+ (O2ValueRepresentation)valueRepresentationFromVR:(NSString*)vr {
    if (!vr) return 0;
    const char* cvr = vr.UTF8String;
    if (!strcmp(cvr, "AE")) return DCM_AE;
    if (!strcmp(cvr, "AS")) return DCM_AS;
    if (!strcmp(cvr, "AT")) return DCM_AT;
    if (!strcmp(cvr, "CS")) return DCM_CS;
    if (!strcmp(cvr, "DA")) return DCM_DA;
    if (!strcmp(cvr, "DS")) return DCM_DS;
    if (!strcmp(cvr, "DT")) return DCM_DT;
    if (!strcmp(cvr, "FL")) return DCM_FL;
    if (!strcmp(cvr, "FD")) return DCM_FD;
    if (!strcmp(cvr, "IS")) return DCM_IS;
    if (!strcmp(cvr, "LO")) return DCM_LO;
    if (!strcmp(cvr, "LT")) return DCM_LT;
    if (!strcmp(cvr, "OB")) return DCM_OB;
    if (!strcmp(cvr, "OF")) return DCM_OF;
    if (!strcmp(cvr, "OW")) return DCM_OW;
    if (!strcmp(cvr, "PN")) return DCM_PN;
    if (!strcmp(cvr, "SH")) return DCM_SH;
    if (!strcmp(cvr, "SL")) return DCM_SL;
    if (!strcmp(cvr, "SQ")) return DCM_SQ;
    if (!strcmp(cvr, "SS")) return DCM_SS;
    if (!strcmp(cvr, "ST")) return DCM_ST;
    if (!strcmp(cvr, "TM")) return DCM_TM;
    if (!strcmp(cvr, "UI")) return DCM_UI;
    if (!strcmp(cvr, "UL")) return DCM_UL;
    if (!strcmp(cvr, "UN")) return DCM_UN;
    if (!strcmp(cvr, "US")) return DCM_US;
    if (!strcmp(cvr, "UT")) return DCM_UT;
    return 0;
}

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        NSMenuItem* mi;
        NSMenu* menu;
        
        // tags pop-up
        
        _tagsPopUp = [[O2DicomPredicateEditorPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _tagsPopUp.bezelStyle = NSRoundRectBezelStyle;
        [_tagsPopUp.cell setControlSize:NSSmallControlSize];
        _tagsPopUp.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _tagsPopUp.autoenablesItems = NO;
        _tagsPopUp.noSelectionLabel = NSLocalizedString(@"Select a Tag...", nil);
        _tagsPopUp.n2mode = YES;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_observePopUpButtonWillPopUpNotification:) name:NSPopUpButtonWillPopUpNotification object:_tagsPopUp];
        
        menu = _tagsPopUp.contextualMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        menu.delegate = self;
        mi = [menu addItemWithTitle:NSLocalizedString(@"Sort by Description", nil) action:@selector(_contextualMenuSortTags:) keyEquivalent:@""];
        mi.tag = O2DicomPredicateEditorSortTagsByName;
        mi.target = self;
        mi = [menu addItemWithTitle:NSLocalizedString(@"Sort by Tag", nil) action:@selector(_contextualMenuSortTags:) keyEquivalent:@""];
        mi.tag = O2DicomPredicateEditorSortTagsByTag;
        mi.target = self;
        
        menu = _tagsPopUp.menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        menu.delegate = self;
        menu.autoenablesItems = NO;
        
        if( !menuItemsCache)
        {
            menuItemsCache = [[NSMutableArray alloc] init];
            for (DCMAttributeTag* tag in self.tags) {
                NSString* title = nil;
                if ([tag isKindOfClass:[O2DicomPredicateEditorDCMAttributeTag class]])
                    title = [tag description];
                else title = [NSString stringWithFormat:@"(%04x,%04x) %@", tag.group, tag.element, [[self class] _transformTagName:tag.name]];
                
                NSMenuItem* mi = [menu addItemWithTitle:title action:nil keyEquivalent:@""]; // @selector(_setTag:)
                
                mi.representedObject = tag;
                mi.tag = [[self class] tagForTag:tag];
                
                [menuItemsCache addObject:mi];
            }
            
            [menuItemsCache sortUsingComparator:^NSComparisonResult(NSMenuItem* mi1, NSMenuItem* mi2) {
                if (mi1.isEnabled != mi2.isEnabled) {
                    if (!mi1.isEnabled)
                        return NSOrderedDescending;
                    else return NSOrderedAscending;
                }
                
                DCMAttributeTag* obj1 = mi1.representedObject;
                DCMAttributeTag* obj2 = mi2.representedObject;
                
                if (!obj1)
                    if (!obj2)
                        return NSOrderedSame;
                    else return NSOrderedAscending;
                    else if (!obj2)
                        return NSOrderedDescending;
                
                // by tag
                if (_tagsSortKey == O2DicomPredicateEditorSortTagsByTag) {
                    long t1 = [[self class] tagForTag:obj1];
                    long t2 = [[self class] tagForTag:obj2];
                    if (t1 < t2)
                        return NSOrderedAscending;
                    if (t1 > t2)
                        return NSOrderedDescending;
                }
                
                // by name
                return [[[self class] _transformTagName:obj1.name] caseInsensitiveCompare:[[self class] _transformTagName:obj2.name]];
            }];
        }
        
        _menuItems = [[NSMutableArray alloc] initWithArray:menuItemsCache copyItems:YES];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            for (DCMAttributeTag* tag in self.tags)
                if ([tag.vr isEqualToString:@"CS"]) {
                    NSDictionary* csd = [O2DicomPredicateEditorCodeStrings codeStringsForTag:tag];
                    if (!csd.count && [[[self class] _transformTagName:tag.name] isEqualToString:tag.name])
                        DLog(@"Warning: no known values for %@", tag);
                }
        });

        
        //        NSLog(@"ascadfasf %@", [_tagsPopUp exposedBindings]);
        [_tagsPopUp bind:@"selectedTag" toObject:self withKeyPath:@"selectedTag" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSValidatesImmediatelyBindingOption]];

        [self _observePopUpButtonWillPopUpNotification:nil];

        // operators pop-up
        
        _operatorsPopUp = [[O2DicomPredicateEditorPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _operatorsPopUp.bezelStyle = NSRoundRectBezelStyle;
        [_operatorsPopUp.cell setControlSize:NSSmallControlSize];
        _operatorsPopUp.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _operatorsPopUp.autoenablesItems = NO;
        
        menu = _operatorsPopUp.menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        
        // for strings: NSContainsPredicateOperatorType, NSBeginsWithPredicateOperatorType, NSEndsWithPredicateOperatorType, NSEqualToPredicateOperatorType
        mi = [menu addItemWithTitle:NSLocalizedString(@"contains", nil) action:nil keyEquivalent:@""];
        mi.tag = NSContainsPredicateOperatorType;
        mi = [menu addItemWithTitle:NSLocalizedString(@"begins with", nil) action:nil keyEquivalent:@""];
        mi.tag = NSBeginsWithPredicateOperatorType;
        mi = [menu addItemWithTitle:NSLocalizedString(@"ends with", nil) action:nil keyEquivalent:@""];
        mi.tag = NSEndsWithPredicateOperatorType;
        
        // for dates: O2EqualsToToday, O2EqualsToYesterday, NSLessThanComparison, NSGreaterThanComparison, O2Within, NSEqualToPredicateOperatorType
        mi = [menu addItemWithTitle:NSLocalizedString(@"is today", nil) action:nil keyEquivalent:@""];
        mi.tag = O2Today;
        mi = [menu addItemWithTitle:NSLocalizedString(@"is yesterday", nil) action:nil keyEquivalent:@""];
        mi.tag = O2Yesterday;
        mi = [menu addItemWithTitle:NSLocalizedString(@"is day before yesterday", nil) action:nil keyEquivalent:@""];
        mi.tag = O2DayBeforeYesterday;
        mi = [menu addItemWithTitle:NSLocalizedString(@"is before", nil) action:nil keyEquivalent:@""];
        mi.tag = NSLessThanOrEqualToPredicateOperatorType;
        mi = [menu addItemWithTitle:NSLocalizedString(@"is after", nil) action:nil keyEquivalent:@""];
        mi.tag = NSGreaterThanOrEqualToPredicateOperatorType;
        mi = [menu addItemWithTitle:NSLocalizedString(@"is within", nil) action:nil keyEquivalent:@""];
        mi.tag = O2Within;
        
        // multi-purpose
        mi = [menu addItemWithTitle:NSLocalizedString(@"is", nil) action:nil keyEquivalent:@""];
        mi.tag = NSEqualToPredicateOperatorType;
        
        mi = [menu addItemWithTitle:NSLocalizedString(@"is not", nil) action:nil keyEquivalent:@""];
        mi.tag = NSNotEqualToPredicateOperatorType;
        
        [_operatorsPopUp bind:@"selectedTag" toObject:self withKeyPath:@"operator" options:nil];
        
        // string value field
        
        _stringValueTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [_stringValueTextField.cell setControlSize:NSSmallControlSize];
        _stringValueTextField.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        
        [_stringValueTextField bind:@"value" toObject:self withKeyPath:@"stringValue" options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                               [NSNumber numberWithBool:YES], NSContinuouslyUpdatesValueBindingOption,
                                                                                               NSLocalizedString(@"empty", nil), NSNullPlaceholderBindingOption, nil]];
        
        // number value field
        
        _numberValueTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [_numberValueTextField.cell setControlSize:NSSmallControlSize];
        _numberValueTextField.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        
        [_numberValueTextField bind:@"value" toObject:self withKeyPath:@"numberValue" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSContinuouslyUpdatesValueBindingOption]];
        
        // date picker
        
        _datePicker = [[O2DicomPredicateEditorDatePicker alloc] initWithFrame:NSZeroRect];
        [_datePicker.cell setControlSize:NSSmallControlSize];
        _datePicker.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _datePicker.datePickerElements = NSYearMonthDayDatePickerElementFlag;
        
        [_datePicker bind:@"value" toObject:self withKeyPath:@"dateValue" options:nil];
        
        // time picker
        
        _timePicker = [[O2DicomPredicateEditorDatePicker alloc] initWithFrame:NSZeroRect];
        [_timePicker.cell setControlSize:NSSmallControlSize];
        _timePicker.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _timePicker.datePickerElements = NSHourMinuteDatePickerElementFlag;
        
        [_timePicker bind:@"value" toObject:self withKeyPath:@"dateValue" options:nil];
        
        // datetime picker
        
        _dateTimePicker = [[O2DicomPredicateEditorDatePicker alloc] initWithFrame:NSZeroRect];
        [_dateTimePicker.cell setControlSize:NSSmallControlSize];
        _dateTimePicker.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _dateTimePicker.datePickerElements = NSYearMonthDayDatePickerElementFlag|NSHourMinuteDatePickerElementFlag;
        
        [_dateTimePicker bind:@"value" toObject:self withKeyPath:@"dateValue" options:nil];
        
        // within pop-up
        
        _withinPopUp = [[O2DicomPredicateEditorPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _withinPopUp.bezelStyle = NSRoundRectBezelStyle;
        [_withinPopUp.cell setControlSize:NSSmallControlSize];
        _withinPopUp.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _withinPopUp.autoenablesItems = NO;
        
        menu = _withinPopUp.menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        
        //        mi = [menu addItemWithTitle:NSLocalizedString(@"the last day", nil) action:nil keyEquivalent:@""]; // this choice ("is within" "the last day") is removed because it's already covered by the "is today" item
        //        mi.tag = O21Day;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 2 days", nil) action:nil keyEquivalent:@""];
        mi.tag = O22Days;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 7 days", nil) action:nil keyEquivalent:@""];
        mi.tag = O21Week;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 31 days", nil) action:nil keyEquivalent:@""];
        mi.tag = O21Month;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 2 months", nil) action:nil keyEquivalent:@""];
        mi.tag = O22Months;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 3 months", nil) action:nil keyEquivalent:@""];
        mi.tag = O23Months;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last year", nil) action:nil keyEquivalent:@""];
        mi.tag = O21Year;
        [menu addItem:[NSMenuItem separatorItem]];
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last hour", nil) action:nil keyEquivalent:@""];
        mi.tag = O21Hour;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 6 hours", nil) action:nil keyEquivalent:@""];
        mi.tag = O26Hours;
        mi = [menu addItemWithTitle:NSLocalizedString(@"the last 12 hours", nil) action:nil keyEquivalent:@""];
        mi.tag = O212Hours;
        
        [_withinPopUp bind:@"selectedTag" toObject:self withKeyPath:@"within" options:nil];
        
        // code string (CS) pop-up
        
        _codeStringPopUp = [[O2DicomPredicateEditorPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _codeStringPopUp.bezelStyle = NSRoundRectBezelStyle;
        [_codeStringPopUp.cell setControlSize:NSSmallControlSize];
        _codeStringPopUp.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _codeStringPopUp.autoenablesItems = NO;
        
        menu = _codeStringPopUp.menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

        [_codeStringPopUp bind:@"selectedTag" toObject:self withKeyPath:@"codeStringTag" options:nil];

        // is
        
        _isLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
        [_isLabel.cell setControlSize:NSSmallControlSize];
        _isLabel.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        _isLabel.stringValue = NSLocalizedString(@"is", nil);
        _isLabel.bordered = NO;
        _isLabel.bezeled = NO;
        _isLabel.drawsBackground = NO;
        _isLabel.editable = NO;
        
        // ...
        
        [self addObserver:self forKeyPath:@"selectedTag" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"tag" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"operator" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"stringValue" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"numberValue" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"dateValue" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"within" options:NSKeyValueObservingOptionInitial context:[self class]];
        [self addObserver:self forKeyPath:@"codeStringTag" options:NSKeyValueObservingOptionInitial context:[self class]];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    [self removeObserver:self forKeyPath:@"codeStringTag"];
    [self removeObserver:self forKeyPath:@"within"];
    [self removeObserver:self forKeyPath:@"dateValue"];
    [self removeObserver:self forKeyPath:@"numberValue"];
    [self removeObserver:self forKeyPath:@"stringValue"];
    [self removeObserver:self forKeyPath:@"operator"];
    [self removeObserver:self forKeyPath:@"tag"];
    [self removeObserver:self forKeyPath:@"selectedTag"];
    
    [_tagsPopUp release];
    [_operatorsPopUp release];
    [_stringValueTextField release];
    [_numberValueTextField release];
    [_datePicker release];
    [_timePicker release];
    [_dateTimePicker release];
    [_withinPopUp release];
    [_codeStringPopUp release];
    [_isLabel release];
    
    [_menuItems release];
    
    self.tag = nil;
    
    self.tags = nil;
    
    self.dateValue = nil;
    self.numberValue = nil;
    self.stringValue = nil;
    
    // TODO memory leaking... this dealloc is never called...
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
//    NSLog(@"%X observeValueForKeyPath: %@ -> %@", (int)self, keyPath, [self valueForKeyPath:keyPath]);
    
    if (object == self)
    {
        if ([keyPath isEqualToString:@"tag"] || [keyPath isEqualToString:@"operator"] || [keyPath isEqualToString:@"codeStringTag"])
            [self review];

        if ([keyPath isEqualToString:@"tag"]) {
            switch ([[self class] valueRepresentationFromVR:self.tag.vr]) {
                case DCM_SH:
                case DCM_LO:
                case DCM_ST:
                case DCM_LT:
                case DCM_UT:
                case DCM_AE:
                case DCM_AS:
                case DCM_PN:
                case DCM_UI:
                case DCM_IS:
//                case DCM_CS:
                case DCM_DS: {
                    if (![self.stringValue isKindOfClass:[NSString class]])
                        self.stringValue = [NSString string];
                } break;
                    
                case DCM_CS: {
                    self.codeStringTag = 1;
                    self.stringValue = [NSString string];
                } break;
                    
                case DCM_SS:
                case DCM_SL:
                case DCM_US:
                case DCM_UL:
                case DCM_FL:
                case DCM_FD: {
                    if (![self.numberValue isKindOfClass:[NSNumber class]])
                        self.numberValue = [NSNumber numberWithInt:0];
                } break;
                    
                case DCM_DA:
                case DCM_TM:
                case DCM_DT: {
                    if (![self.dateValue isKindOfClass:[NSDate class]])
                        self.dateValue = [NSDate date];
                } break;
            }
            
//            [self review];
        }
        
        if ([keyPath isEqualToString:@"operator"])
            if (self.operator == O2Within)
                self.within = O26Hours;

        [self resizeSubviewsWithOldSize:self.bounds.size];
        
        [self.editor reloadPredicate];
    }
}


- (O2DicomPredicateEditor*)editor {
    for (id view = self; view; view = [view superview])
        if ([view isKindOfClass:[O2DicomPredicateEditor class]])
            return view;
    return nil;
}

//#pragma mark Tags

+ (NSString*)_transformTagName:(NSString*)name {
    if ([name hasPrefix:@"RETIRED_"])
        name = [[name substringFromIndex:8] stringByAppendingString:NSLocalizedString(@" (retired)", nil)];
    if ([name hasPrefix:@"ACR_NEMA_"])
        name = [name substringFromIndex:9];
    if ([name hasPrefix:@"2C_"])
        name = [name substringFromIndex:3];
    return name;
}

+ (NSInteger)tagForTag:(DCMAttributeTag*)tag {
    return (tag.group<<16)|tag.element;
}

- (void) setTags:(NSArray *)tags
{
    NSLog( @"We should not be here");
}

- (NSArray*)tags {
    if (!tagsCache) {
        tagsCache = [[NSMutableArray alloc] init];
        
        // common DICOM tags
        for (NSString* dcmTagsKey in [[DCMTagDictionary sharedTagDictionary] allKeys]) {
            DCMAttributeTag* tag = [DCMAttributeTag tagWithTagString:dcmTagsKey];
            O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];
            if (!tag.isPrivate && tag.group != 0x0000 && ((tag.group&0xfff0) != 0xfff0) && vr != DCM_SQ && vr != DCM_OW && vr != DCM_OF && vr != DCM_OB && vr != DCM_UN)
                [tagsCache addObject:tag];
        }

        int i = 0, g = 0x0001; // we use group 0x0001 which is private
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"PN" name:@"name" description:NSLocalizedString(@"Patient Name", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LO" name:@"patientID" description:NSLocalizedString(@"Patient ID", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"CS" name:@"modality" description:NSLocalizedString(@"Modality", nil) cskey:@"Modality"]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"DT" name:@"date" description:NSLocalizedString(@"Study Date", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"SH" name:@"id" description:NSLocalizedString(@"Study ID", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LO" name:@"studyName" description:NSLocalizedString(@"Study Description", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"PN" name:@"referringPhysician" description:NSLocalizedString(@"Referring Physician", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"PN" name:@"performingPhysician" description:NSLocalizedString(@"Performing Physician", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LO" name:@"institutionName" description:NSLocalizedString(@"Institution", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"CS" name:@"stateText" description:NSLocalizedString(@"Study Status", nil) cskey:@"OsiriX StudyStatus"]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"DT" name:@"dateAdded" description:NSLocalizedString(@"Date Added", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"DT" name:@"dateOpened" description:NSLocalizedString(@"Date Opened", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LT" name:@"comment" description:NSLocalizedString(@"Comments", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LT" name:@"comment2" description:NSLocalizedString(@"Comments 2", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LT" name:@"comment3" description:NSLocalizedString(@"Comments 3", nil)]];
        [tagsCache addObject:[O2DicomPredicateEditorDCMAttributeTag tagWithGroup:g element:++i vr:@"LT" name:@"comment4" description:NSLocalizedString(@"Comments 4", nil)]];
    }
    
    return tagsCache;
}

- (DCMAttributeTag*)tagWithGroup:(int)group element:(int)element {
    for (DCMAttributeTag* tag in self.tags)
        if (tag.group == group && tag.element == element)
            return tag;
    return nil;
}

- (DCMAttributeTag*)tagWithKeyPath:(NSString*)keyPath {
    for (DCMAttributeTag* tag in self.tags)
        if ([tag.name isEqualToString:keyPath])
            return tag;
    return nil;
}

+ (NSSet*)keyPathsForValuesAffectingSelectedTag {
    return [NSSet setWithObject:@"tag"];
}

- (void)setSelectedTag:(NSInteger)tag {
    self.tag = [self tagWithGroup:tag>>16 element:tag&0xffff];
}

- (NSInteger)selectedTag {
    return [[self class] tagForTag:self.tag];
}

- (void)_contextualMenuSortTags:(NSMenuItem*)sender {
    _tagsSortKey = sender.tag;
}

//- (void)sortTagsMenu {
//    NSMenu* menu = _tagsPopUp.menu;
//    
//    NSArray* mis = [menu.itemArray sortedArrayUsingComparator:^NSComparisonResult(NSMenuItem* mi1, NSMenuItem* mi2) {
//        if (mi1.isEnabled != mi2.isEnabled) {
//            if (!mi1.isEnabled)
//                return NSOrderedDescending;
//            else return NSOrderedAscending;
//        }
//        
//        DCMAttributeTag* obj1 = mi1.representedObject;
//        DCMAttributeTag* obj2 = mi2.representedObject;
//        
//        if (!obj1)
//            if (!obj2)
//                return NSOrderedSame;
//            else return NSOrderedAscending;
//            else if (!obj2)
//                return NSOrderedDescending;
//        
//        // by tag
//        if (_tagsSortKey == O2DicomPredicateEditorSortTagsByTag) {
//            long t1 = [[self class] tagForTag:obj1];
//            long t2 = [[self class] tagForTag:obj2];
//            if (t1 < t2)
//                return NSOrderedAscending;
//            if (t1 > t2)
//                return NSOrderedDescending;
//        }
//        
//        // by name
//        return [[[self class] _transformTagName:obj1.name] caseInsensitiveCompare:[[self class] _transformTagName:obj2.name]];
//    }];
//    
//    NSInteger stag = [_tagsPopUp selectedTag];
//    NSDictionary* binding = [_tagsPopUp infoForBinding:@"selectedTag"];
//    [_tagsPopUp unbind:@"selectedTag"];
//    
//    [menu removeAllItems];
//    for (NSMenuItem *mi in mis)
//        [menu addItem: mi];
//    
//    if (binding)
//        [_tagsPopUp bind:@"selectedTag" toObject:[binding valueForKey:NSObservedObjectKey] withKeyPath:[binding valueForKey:NSObservedKeyPathKey] options:[binding objectForKey:NSOptionsKey]];
//    else if (stag != -1)
//        [_tagsPopUp selectItemWithTag:stag];
//}

- (void)_observePopUpButtonWillPopUpNotification:(NSNotification*)notification {
    
    NSInteger stag = [_tagsPopUp selectedTag];
    NSDictionary* binding = [_tagsPopUp infoForBinding:@"selectedTag"];
    [_tagsPopUp unbind:@"selectedTag"];
    
    [_tagsPopUp.menu removeAllItems];
    for (NSMenuItem* mi in _menuItems)
        if (![[self editor] inited] || [mi.representedObject isKindOfClass:[O2DicomPredicateEditorDCMAttributeTag class]] == [self.editor dbMode]) {
            [_tagsPopUp.menu addItem:mi];
    }
    
    if (binding)
        [_tagsPopUp bind:@"selectedTag" toObject:[binding valueForKey:NSObservedObjectKey] withKeyPath:[binding valueForKey:NSObservedKeyPathKey] options:[binding objectForKey:NSOptionsKey]];
    else if (stag != -1)
        [_tagsPopUp selectItemWithTag:stag];
    
    if ([self.editor dbMode])
        _tagsSortKey = O2DicomPredicateEditorSortTagsByTag;
}

- (void)menuWillOpen:(NSMenu*)menu {
    if (menu == _tagsPopUp.contextualMenu) {
        for (NSMenuItem* mi in menu.itemArray) {
            mi.enabled = (mi.tag != _tagsSortKey);
            mi.state = (mi.tag == _tagsSortKey)? NSOnState : NSOffState;
        }
    }
}

/*- (void)menuNeedsUpdate:(NSMenu*)menu {
    if (menu == _tagsPopUp.menu) {
        BOOL somethingIsAvailable = NO;
        for (NSMenuItem* mi in menu.itemArray)
            if (!mi.isHidden) {
                somethingIsAvailable = YES;
                break;
            }
        if (!somethingIsAvailable) {
            [_tagsPopUpKeysCatcher setStringValue:@""];
            [self filterItemsWithWords:nil];
        }
        [self performSelector:@selector(_focusTagsPopUpFilterTextField:) withObject:menu afterDelay:0.01 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
}

- (void)_focusTagsPopUpFilterTextField:(NSMenu*)menu {
    NSWindow* menuWindow = [[NSApp windows] lastObject]; // this is the NSCalbonMenuWindow instance
    if ([menuWindow.className isEqualToString:@"NSCarbonMenuWindow"]) {
        // this is a hack - the NSTextField will never be drawn by the NSCarbonMenuWindow, but somehow it's still receiving keyboard events
        [menuWindow.contentView addSubview:_tagsPopUpKeysCatcher];
        [menuWindow makeFirstResponder:_tagsPopUpKeysCatcher];
    }
}*/

//#pragma mark Operators

- (void)setAvailableOperators:(NSNumber*)first, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableSet* oops = [NSMutableSet set];
    
    va_list args;
    va_start(args, first);
    for (NSNumber* arg = first; arg; arg = va_arg(args, NSNumber*))
        [oops addObject:arg];
    va_end(args);
    
//    NSLog(@"Available Operators -> %@", oops);
    
    NSMenuItem* firstItem = nil;
    for (NSMenuItem* mi in _operatorsPopUp.itemArray) {
        mi.hidden = ![oops containsObject:[NSNumber numberWithInteger:mi.tag]];
        if (!firstItem && !mi.isHidden)
            firstItem = mi;
    }
    
    if (_operatorsPopUp.selectedTag != self.operator && [oops containsObject:[NSNumber numberWithInteger:self.operator]]) // fix the selection
        [_operatorsPopUp selectItemWithTag:self.operator];
    if (![oops containsObject:[NSNumber numberWithInteger:_operatorsPopUp.selectedTag]]) // invalid selection... select a valid item
        [_operatorsPopUp selectItem:firstItem];
    if (self.operator != _operatorsPopUp.selectedTag) // fix the bound value
        self.operator = _operatorsPopUp.selectedTag;
}

/*- (void)setOperator:(NSInteger)type {
 [_operatorsPopUp selectItemWithTag:type];
 
 [self resizeSubviewsWithOldSize:self.bounds.size];
 }*/




//#pragma mark -----

//+ (NSDateFormatter*)dateFormatter {
//    static NSDateFormatter* formatter = nil;
//    if (!formatter) {
//        formatter = [[NSDateFormatter alloc] init];
//        formatter.timeStyle = NSDateFormatterNoStyle;
//        formatter.dateStyle = NSDateFormatterShortStyle;
//    }
//    
//    return formatter;
//}

+ (NSFormatter*)integerFormatter {
    static NSNumberFormatter* formatter = nil;
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.maximumFractionDigits = 0;
    }
    
    return formatter;
}

+ (NSFormatter*)decimalFormatter {
    static NSNumberFormatter* formatter = nil;
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    
    return formatter;
}

+ (NSFormatter*)integersFormatter {
    static O2DicomPredicateEditorMultiplicityFormatter* formatter = nil;
    if (!formatter) {
        formatter = [[O2DicomPredicateEditorMultiplicityFormatter alloc] init];
        formatter.monoFormatter = [[self class] decimalFormatter];
    }
    
    return formatter;
}

+ (NSFormatter*)decimalsFormatter {
    static O2DicomPredicateEditorMultiplicityFormatter* formatter = nil;
    if (!formatter) {
        formatter = [[O2DicomPredicateEditorMultiplicityFormatter alloc] init];
        formatter.monoFormatter = [[self class] integerFormatter];
    }
    
    return formatter;
}

+ (NSFormatter*)ageFormatter {
    static O2DicomPredicateEditorAgeStringFormatter* formatter = nil;
    if (!formatter)
        formatter = [[O2DicomPredicateEditorAgeStringFormatter alloc] init];
    return formatter;
}


- (NSArray*)views {
    NSMutableArray* views = [NSMutableArray arrayWithObject:_tagsPopUp];
    
    DCMAttributeTag* tag = self.tag;
    O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];

#define N(x) [NSNumber numberWithInteger:x]
    
    switch (vr) {
        case DCM_SH:
        case DCM_LO:
        case DCM_ST:
        case DCM_LT:
        case DCM_UT:
        case DCM_AE: // TODO: should be more restrictive for AE
        case DCM_PN:
        case DCM_UI:  {
            [views addObject:_operatorsPopUp];
            [self setAvailableOperators: N(NSContainsPredicateOperatorType), N(NSBeginsWithPredicateOperatorType), N(NSEndsWithPredicateOperatorType), N(NSEqualToPredicateOperatorType), N(NSNotEqualToPredicateOperatorType), nil];
            _stringValueTextField.formatter = nil;
            [views addObject:_stringValueTextField];
        } break;
            
        case DCM_IS: {
            [views addObject:_isLabel];
            [self setAvailableOperators: N(NSEqualToPredicateOperatorType), nil];
            _stringValueTextField.formatter = [[self class] integersFormatter];
            [views addObject:_stringValueTextField];
        } break;
            
        case DCM_SS:
        case DCM_SL:
        case DCM_US:
        case DCM_UL: {
            [views addObject:_isLabel];
            [self setAvailableOperators: N(NSEqualToPredicateOperatorType), nil];
            _numberValueTextField.formatter = [[self class] integerFormatter];
            [views addObject:_numberValueTextField];
        } break;
            
        case DCM_DS: {
            [views addObject:_isLabel];
            [self setAvailableOperators: N(NSEqualToPredicateOperatorType), nil];
            _stringValueTextField.formatter = [[self class] decimalsFormatter];
            [views addObject:_stringValueTextField];
        } break;
            
        case DCM_FL:
        case DCM_FD: {
            [views addObject:_isLabel];
            [self setAvailableOperators: N(NSEqualToPredicateOperatorType), nil];
            _numberValueTextField.formatter = [[self class] decimalFormatter];
            [views addObject:_numberValueTextField];
        } break;
            
        case DCM_AS: {
            [views addObject:_isLabel];
            [self setAvailableOperators: N(NSEqualToPredicateOperatorType), nil];
            _stringValueTextField.formatter = [[self class] ageFormatter];
            [views addObject:_stringValueTextField];
        } break;
            
        case DCM_DA: {
            [views addObject:_operatorsPopUp];
            [self setAvailableOperators: N(O2Today), N(O2Yesterday), N(O2DayBeforeYesterday), N(NSLessThanOrEqualToPredicateOperatorType), N(NSGreaterThanOrEqualToPredicateOperatorType), N(O2Within), N(NSEqualToPredicateOperatorType), nil]; // TODO: add 'is between'
            switch (self.operator) {
                case NSLessThanOrEqualToPredicateOperatorType:
                case NSGreaterThanOrEqualToPredicateOperatorType:
                case NSEqualToPredicateOperatorType:
                    [views addObject:_datePicker];
                    break;
                case O2Within:
                    [views addObject:_withinPopUp];
                default:
                    break;
            }
        } break;
            
        case DCM_TM: {
            [views addObject:_operatorsPopUp];
            [self setAvailableOperators: N(NSLessThanOrEqualToPredicateOperatorType), N(NSGreaterThanOrEqualToPredicateOperatorType), N(NSEqualToPredicateOperatorType), nil];
            switch (self.operator) {
                case NSLessThanOrEqualToPredicateOperatorType:
                case NSGreaterThanOrEqualToPredicateOperatorType:
                case NSEqualToPredicateOperatorType:
                    [views addObject:_timePicker];
                    break;
                default:
                    break;
            }
        } break;
            
        case DCM_DT: {
            [views addObject:_operatorsPopUp];
            [self setAvailableOperators: N(O2Today), N(O2Yesterday), N(O2DayBeforeYesterday), N(NSLessThanOrEqualToPredicateOperatorType), N(NSGreaterThanOrEqualToPredicateOperatorType), N(O2Within), N(NSEqualToPredicateOperatorType), nil]; // TODO: add 'is between'
            switch (self.operator) {
                case NSLessThanOrEqualToPredicateOperatorType:
                case NSGreaterThanOrEqualToPredicateOperatorType:
                case NSEqualToPredicateOperatorType:
                    [views addObject:_dateTimePicker];
                    break;
                case O2Within:
                    [views addObject:_withinPopUp];
                default:
                    break;
            }
        } break;
            
        case DCM_CS: {
            [views addObject:_isLabel];
//            [views addObject:_operatorsPopUp];
//            [self setAvailableOperators: N(NSContainsPredicateOperatorType), N(NSBeginsWithPredicateOperatorType), N(NSEndsWithPredicateOperatorType), N(NSEqualToPredicateOperatorType), N(NSNotEqualToPredicateOperatorType), nil];
            // .. popup
            [_codeStringPopUp.menu removeAllItems];
            NSDictionary* dic = [O2DicomPredicateEditorCodeStrings codeStringsForTag:self.tag];
            NSInteger i = 0;
            for (NSString* k in dic) {
                NSString* t = nil;
                if ([k isKindOfClass:[NSString class]] && ![k isEqualToString:[dic objectForKey:k]] && [[dic objectForKey:k] length] < 80)
                    t = [NSString stringWithFormat:NSLocalizedString(@"%@, %@", nil), k, [dic objectForKey:k]];
                else t = [dic objectForKey:k];
                if (![t isKindOfClass:[NSString class]])
                    t = [(id)t stringValue];
                NSMenuItem* mi = [_codeStringPopUp.menu addItemWithTitle:t action:nil keyEquivalent:@""];
                mi.tag = ++i;
            }
            // if there are items, show the popup
            if (i)
                [views addObject:_codeStringPopUp];
            // add custom-value menu item
            //                [_codeStringPopUp.menu addItem:[NSMenuItem separatorItem]];
            NSMenuItem* mi = [_codeStringPopUp.menu addItemWithTitle:NSLocalizedString(@"user-defined", nil) action:nil keyEquivalent:@""];
            mi.tag = ++i;
            mi.representedObject =_stringValueTextField;
            
            [_codeStringPopUp selectItemWithTag:_codeStringTag];
            
            if (_codeStringTag == i) {
                _stringValueTextField.formatter = nil;
                [views addObject:_stringValueTextField];
            }
        } break;
    }
    
#undef N
    
    return views;
}


- (void)review {
    if (_reviewing)
        return;

    _reviewing = YES;

    NSArray* views = nil;
    
    @try {
        views = [self views];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        _reviewing = NO;
    }
    
    /*if ([_valueTextField.formatter isKindOfClass:[NSNumberFormatter class]]) {
     if (![self.value isKindOfClass:[NSNumber class]])
     self.value = [NSNumber numberWithInteger:0];*/
    
    // show/hide
    
    for (NSView* subview in [[self.subviews copy] autorelease])
        [subview removeFromSuperview];

    NSView* p = nil;
    for (NSView* subview in views) {
        if (subview.superview != self)
            [self addSubview:subview];
        [p setNextKeyView:subview];
        p = subview;
    }
    
//    [p setNextKeyView:[self nextKeyView]];
    
    /*NSView* pview = nil;
    for (NSView* view in views) {
        [pview setNextResponder:view];
        pview = view;
    }*/
    
    [self resizeSubviewsWithOldSize:self.bounds.size];
}

- (double)matchForPredicate:(id)predicate {
//    NSLog(@"matchForPredicate: %@", predicate);

    if ([predicate isKindOfClass:[NSComparisonPredicate class]])
        @try {
//            NSExpression* eleft = [predicate leftExpression];
//            NSExpression* eright = [predicate rightExpression];
            NSPredicateOperatorType otype = [predicate predicateOperatorType];

            DCMAttributeTag* tag = [self tagWithKeyPath:[predicate keyPath]];
            O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];
            
            if (!vr || vr == DCM_UN)
                return 0; // we cannot handle tags of unknown type
            
            switch (vr) {
                case DCM_CS: {
                    if ((otype == NSEqualToPredicateOperatorType || otype == NSContainsPredicateOperatorType) &&
                        [predicate constantValue])
                        return 1; // is
                } break;
                    
                case DCM_SH:
                case DCM_LO:
                case DCM_ST:
                case DCM_LT:
                case DCM_UT:
                case DCM_AE:
                case DCM_PN:
//                case DCM_CS:
                case DCM_UI: /* TODO: should be more restrictive for AE */ {
                    switch (otype) {
                        case NSContainsPredicateOperatorType:
                        case NSBeginsWithPredicateOperatorType:
                        case NSEndsWithPredicateOperatorType:
                        case NSEqualToPredicateOperatorType:
                        case NSNotEqualToPredicateOperatorType:
                            return 1;
                        default: break;
                    }
                } break;
                    
                case DCM_AS:
                case DCM_IS:
                case DCM_DS:
                case DCM_SS:
                case DCM_SL:
                case DCM_US:
                case DCM_UL:
                case DCM_FL:
                case DCM_FD: {
                    if (otype == NSEqualToPredicateOperatorType)
                        return 1;
                } break;
                    
                case DCM_DA:
                case DCM_DT: {
                    if (otype == NSGreaterThanOrEqualToPredicateOperatorType && [[predicate constantValue] isKindOfClass:[NSDate class]])
                        return 1; // is after DATE
                    if (otype == NSGreaterThanOrEqualToPredicateOperatorType && ([[[self class] timeKeys] containsObject:[predicate variable]] || ([[predicate function] isEqualToString:@"castObject:toType:"] && [[[[predicate arguments] objectAtIndex:1] constantValue] isEqual:@"NSDate"] && [[[self class] legacyTimeKeys] containsObject:[[[predicate arguments] objectAtIndex:0] variable]])))
                        return 1; // is today & is within
                    if (otype == NSLessThanOrEqualToPredicateOperatorType && [[predicate constantValue] isKindOfClass:[NSDate class]])
                        return 1; // is before
                    if (otype == NSBetweenPredicateOperatorType && 
                        [[[[predicate collection] objectAtIndex:0] variable] isEqualToString:O2VarYesterday] &&
                        [[[[predicate collection] objectAtIndex:1] variable] isEqualToString:O2VarToday]) // match "KeyPath between {NSDATE_YESTERDAY, NSDATE_TODAY}" for Yesterday
                        return 1; // is yesterday
                    if (otype == NSBetweenPredicateOperatorType &&
                        ([[[[predicate collection] objectAtIndex:0] variable] isEqualToString:O2Var2Days]) &&
                        ([[[[predicate collection] objectAtIndex:1] variable] isEqualToString:O2VarYesterday])) // match "KeyPath between {NSDATE_2DAYS, NSDATE_YESTERDAY}" for Yesterday
                        return 1; // is day before yesterday
                    if (otype == NSEqualToPredicateOperatorType && [[predicate constantValue] isKindOfClass:[NSDate class]])
                        return 1; // is
                } break;
                    
                case DCM_TM: {
                    if (otype == NSLessThanOrEqualToPredicateOperatorType && [[predicate constantValue] isKindOfClass:[NSDate class]])
                        return 1; // is before
                    if (otype == NSGreaterThanOrEqualToPredicateOperatorType && [[predicate constantValue] isKindOfClass:[NSDate class]])
                        return 1; // is after
                    if (otype == NSEqualToPredicateOperatorType && [[predicate constantValue] isKindOfClass:[NSDate class]])
                        return 1; // is
                } break;
            }
            
        } @catch (...) {
        }
    
    if ([predicate isKindOfClass:[NSCompoundPredicate class]] && [predicate compoundPredicateType] == NSAndPredicateType)
        @try {
            NSArray* subpredicates = [predicate subpredicates];
//            if (subpredicates.count > 1) {
                // subpredicates must be of same KeyPath
                NSString* keyPath = nil;
                for (id p in subpredicates)
                    if ([p isKindOfClass:[NSComparisonPredicate class]]) {
                        if (keyPath && ![[p keyPath] isEqualToString:keyPath]) { // subpredicates must have the same keyPath
                            keyPath = nil; break;
                        } else keyPath = [p keyPath];
                    } else { // subpredicates must all be comparisons
                        keyPath = nil; break;
                    };
                
                DCMAttributeTag* tag = [self tagWithKeyPath:keyPath];
                O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];

                NSComparisonPredicate* sp0 = [subpredicates objectAtIndex:0];
                NSComparisonPredicate* sp1 = [subpredicates objectAtIndex:1];
                
                // match old "DA_KeyPath >= $NSDATE_YESTERDAY AND DA_KeyPath <= $NSDATE_TODAY" for "KeyPath between {NSDATE_YESTERDAY, NSDATE_TODAY}"
                if ((vr == DCM_DA || vr == DCM_DT) &&
                    subpredicates.count == 2 &&
                    sp0.predicateOperatorType == NSGreaterThanOrEqualToPredicateOperatorType && [sp0.variable isEqualToString:O2VarYesterday] &&
                    sp1.predicateOperatorType == NSLessThanOrEqualToPredicateOperatorType && [sp1.variable isEqualToString:O2VarToday])
                    return 1;
            
                // match old "DA_KeyPath >= $NSDATE_2DAYS AND DA_KeyPath <= $NSDATE_YESTERDAY" for "KeyPath between {NSDATE_YESTERDAY, NSDATE_TODAY}"
                if ((vr == DCM_DA || vr == DCM_DT) &&
                subpredicates.count == 2 &&
                sp0.predicateOperatorType == NSGreaterThanOrEqualToPredicateOperatorType && [sp0.variable isEqualToString:O2Var2Days] &&
                sp1.predicateOperatorType == NSLessThanOrEqualToPredicateOperatorType && [sp1.variable isEqualToString:O2VarYesterday])
                return 1;
            
                // match "LT_KeyPath != '' AND LT_KeyPath != nil"
                if ((vr == DCM_SH || vr == DCM_LO || vr == DCM_ST || vr == DCM_LT || vr == DCM_UT || vr == DCM_AE || vr == DCM_PN || vr == DCM_UI) &&
                    subpredicates.count == 2 &&
                    sp0.predicateOperatorType == NSNotEqualToPredicateOperatorType && sp1.predicateOperatorType == NSNotEqualToPredicateOperatorType &&
                    [sp0.constantValue isEqualToString:@""] && sp1.constantValue == nil)
                    return 1;
//            } else
//                return 0.1;
        } @catch (...) {
        }
    
    if ([predicate isKindOfClass:[NSPredicate class]] && [[predicate predicateFormat] isEqualToString:@"TRUEPREDICATE"])
        return 0.6;
    
    return 0;
}

/*+ (NSSet*)keyPathsForValuesAffectingPredicate {
    return [NSSet setWithObjects: @"tag", @"operator", @"value", @"within", nil];
}*/

- (void)setPredicate:(id)predicate {
//    NSLog(@"setPredicate: %@", predicate);
    
    if ([predicate isKindOfClass:[NSPredicate class]] && [[predicate predicateFormat] isEqualToString:@"TRUEPREDICATE"]) {
        [self setTag:nil];
        return;
    }
    
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        DCMAttributeTag* tag = [self tagWithKeyPath:[predicate keyPath]];
        O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];

        NSPredicateOperatorType otype = [predicate predicateOperatorType];
//        NSExpression* eright = [predicate rightExpression];
        
        [self setTag:tag];
        
        switch (vr) {
            case DCM_SH:
            case DCM_LO:
            case DCM_ST:
            case DCM_LT:
            case DCM_UT:
            case DCM_AE:
            case DCM_PN:
            case DCM_UI:
//            case DCM_CS:
            case DCM_AS: {
                [self setOperator:[predicate predicateOperatorType]];
                [self setStringValue:[predicate constantValue]];
            } break;
                
            case DCM_IS:
            case DCM_DS: {
                [self setOperator:[predicate predicateOperatorType]];
                id value = [predicate constantValue];
                if ([value isKindOfClass:[NSNumber class]])
                    [self setStringValue:[value stringValue]];
                else if ([value isKindOfClass:[NSString class]])
                    [self setStringValue:value];
            } break;
                
            case DCM_SS:
            case DCM_SL:
            case DCM_US:
            case DCM_UL:
            case DCM_FL:
            case DCM_FD: {
                [self setOperator:[predicate predicateOperatorType]];
                id value = [predicate constantValue];
                if ([value isKindOfClass:[NSNumber class]])
                    [self setNumberValue:value];
                else if ([value isKindOfClass:[NSString class]])
                    [self setNumberValue:[NSNumber numberWithDouble:[value doubleValue]]];
            } break;
                
            case DCM_DA:
            case DCM_DT: {
                if (otype == NSGreaterThanOrEqualToPredicateOperatorType && ([predicate variable] || [predicate function])) {
                    if ([[predicate variable] isEqualToString:O2VarToday] || [[[[predicate arguments] objectAtIndex:0] variable] isEqualToString:LegacyTimeKey(O2VarToday)])
                        [self setOperator:O2Today];
                    else {
                        [self setOperator:O2Within];
                        O2TimeTag tt = [[self class] timeTagFromKey:[predicate variable]];
                        if (!tt) tt = [[self class] timeTagFromKey:UnLegacyTimeKey([[[predicate arguments] objectAtIndex:0] variable])];
                        [self setWithin:tt];
                    }
                } else if (otype == NSBetweenPredicateOperatorType && [[[[predicate collection] objectAtIndex:0] variable] isEqualToString:O2VarYesterday] && [[[[predicate collection] objectAtIndex:1] variable] isEqualToString:O2VarToday]) { // yesterday
                    [self setOperator:O2Yesterday];
                } else if (otype == NSBetweenPredicateOperatorType && [[[[predicate collection] objectAtIndex:0] variable] isEqualToString:O2Var2Days] && [[[[predicate collection] objectAtIndex:1] variable] isEqualToString:O2VarYesterday]) { // day before yesterday
                    [self setOperator:O2DayBeforeYesterday];
                } else if ([[predicate constantValue] isKindOfClass:[NSDate class]]) {
                    [self setOperator:otype];
                    [self setDateValue:[predicate constantValue]];
                } else
                    [NSException raise:NSGenericException format:@"Unexpected comparison for DA tag: %@", predicate];
            } break;
            
            case DCM_TM: {
                [self setOperator:[predicate predicateOperatorType]];
                [self setDateValue:[predicate constantValue]];
            } break;
                
            case DCM_CS: {
                [self setCodeStringTag:[self tagForCodeString:[predicate constantValue]]];
                if ([[predicate constantValue] isKindOfClass:[NSString class]]) {
                    id v = [predicate constantValue];
                    if (![v isKindOfClass:[NSString class]])
                        v = [v stringValue];
                    [self setStringValue:nil];
                }
            } break;
        }
    }
    
    if ([predicate isKindOfClass:[NSCompoundPredicate class]] && [predicate compoundPredicateType] == NSAndPredicateType) {
        NSArray* subpredicates = [predicate subpredicates];
        DCMAttributeTag* tag = [self tagWithKeyPath:[[subpredicates objectAtIndex:0] keyPath]];
        O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];
        
        [self setTag:tag];
        
        NSComparisonPredicate* sp0 = [subpredicates objectAtIndex:0];
        NSComparisonPredicate* sp1 = [subpredicates objectAtIndex:1];
        
        // match old "DA_KeyPath >= $NSDATE_YESTERDAY AND DA_KeyPath <= $NSDATE_TODAY" for "KeyPath between {NSDATE_YESTERDAY, NSDATE_TODAY}"
        if ((vr == DCM_DA || vr == DCM_DT) &&
            subpredicates.count == 2 &&
            sp0.predicateOperatorType == NSGreaterThanOrEqualToPredicateOperatorType && [[sp0 variable] isEqualToString:O2VarYesterday] &&
            sp1.predicateOperatorType == NSLessThanOrEqualToPredicateOperatorType && [[sp1 variable] isEqualToString:O2VarToday])
            [self setOperator:O2Yesterday];
        
        if ((vr == DCM_DA || vr == DCM_DT) &&
            subpredicates.count == 2 &&
            sp0.predicateOperatorType == NSGreaterThanOrEqualToPredicateOperatorType && [[sp0 variable] isEqualToString:O2Var2Days] &&
            sp1.predicateOperatorType == NSLessThanOrEqualToPredicateOperatorType && [[sp1 variable] isEqualToString:O2VarYesterday])
            [self setOperator:O2DayBeforeYesterday];
        
        // match "LT_KeyPath != '' AND LT_KeyPath != nil"
        if ((vr == DCM_SH || vr == DCM_LO || vr == DCM_ST || vr == DCM_LT || vr == DCM_UT || vr == DCM_AE || vr == DCM_PN || vr == DCM_UI) &&
            sp0.predicateOperatorType == NSNotEqualToPredicateOperatorType && sp1.predicateOperatorType == NSNotEqualToPredicateOperatorType &&
            [sp0.constantValue isEqualToString:@""] && sp1.constantValue == nil) {
            [self setOperator:NSNotEqualToPredicateOperatorType];
            [self setStringValue:@""];
        }

    }
}

+ (NSSet*)keyPathsForValuesAffectingPredicate {
    return [NSSet setWithObjects: @"tag", @"operator", @"stringValue", @"numberValue", @"dateValue", @"within", @"codeStringTag", nil];
}

- (NSPredicate*)predicate {
    DCMAttributeTag* tag = self.tag;
    O2ValueRepresentation vr = [[self class] valueRepresentationFromVR:tag.vr];
    
    NSExpression* tagNameExpression = [NSExpression expressionForKeyPath:tag.name];
    
    switch (vr) {
        case DCM_SH:
        case DCM_LO:
        case DCM_ST:
        case DCM_LT:
        case DCM_UT:
        case DCM_AE:
        case DCM_PN:
//        case DCM_CS:
        case DCM_UI:
        case DCM_AS: {
            if (self.stringValue.length)
                return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                          rightExpression:[NSExpression expressionForConstantValue:self.stringValue]
                                                                 modifier:NSDirectPredicateModifier
                                                                     type:self.operator
                                                                  options:NSCaseInsensitivePredicateOption];
            else
                return [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
                                                                           [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                                                                              rightExpression:[NSExpression expressionForConstantValue:@""]
                                                                                                                     modifier:NSDirectPredicateModifier
                                                                                                                         type:self.operator
                                                                                                                      options:NSCaseInsensitivePredicateOption],
                                                                           [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                                                                              rightExpression:[NSExpression expressionForConstantValue:nil]
                                                                                                                     modifier:NSDirectPredicateModifier
                                                                                                                         type:self.operator
                                                                                                                      options:NSCaseInsensitivePredicateOption],
                                                                           nil]];
        } break;
            
            
        case DCM_DS:
        case DCM_IS: {
            return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                      rightExpression:[NSExpression expressionForConstantValue:self.stringValue]
                                                             modifier:NSDirectPredicateModifier
                                                                 type:self.operator
                                                              options:NSCaseInsensitivePredicateOption];
        }
            
        case DCM_SS:
        case DCM_SL:
        case DCM_US:
        case DCM_UL:
        case DCM_FL:
        case DCM_FD: {
            return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                      rightExpression:[NSExpression expressionForConstantValue:self.numberValue]
                                                             modifier:NSDirectPredicateModifier
                                                                 type:self.operator
                                                              options:NSCaseInsensitivePredicateOption];
        }
    
        case DCM_DA:
        case DCM_DT: {
            switch (self.operator) {
                case O2Today:
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForVariable:O2VarToday]
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:NSGreaterThanOrEqualToPredicateOperatorType
                                                                      options:0];
                case O2Yesterday:
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForAggregate:[NSArray arrayWithObjects: [NSExpression expressionForVariable:O2VarYesterday], [NSExpression expressionForVariable:O2VarToday], nil]] // TODO: is this coredata compatible?
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:NSBetweenPredicateOperatorType
                                                                      options:0];
                case O2DayBeforeYesterday:
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForAggregate:[NSArray arrayWithObjects: [NSExpression expressionForVariable:O2Var2Days], [NSExpression expressionForVariable:O2VarYesterday], nil]] // TODO: is this coredata compatible?
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:NSBetweenPredicateOperatorType
                                                                      options:0];
                case NSLessThanOrEqualToPredicateOperatorType:
                case NSGreaterThanOrEqualToPredicateOperatorType:
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForConstantValue:self.dateValue]
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:self.operator
                                                                      options:0];
                case O2Within: {
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForVariable:[[self class] timeKeyFromTag:self.within]]
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:NSGreaterThanOrEqualToPredicateOperatorType
                                                                      options:0];
                } break;
                case NSEqualToPredicateOperatorType: {
                    NSDateComponents* dc = [NSCalendar.currentCalendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self.dateValue];
                    NSDate* from = [NSCalendar.currentCalendar dateFromComponents:dc];
                    dc = [[[NSDateComponents alloc] init] autorelease];
                    dc.day = 1;
                    NSDate* to = [NSCalendar.currentCalendar dateByAddingComponents:dc toDate:from options:NSWrapCalendarComponents];
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForAggregate:[NSArray arrayWithObjects: [NSExpression expressionForConstantValue:from], [NSExpression expressionForConstantValue:to], nil]] // TODO: is this coredata compatible?
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:NSBetweenPredicateOperatorType
                                                                      options:0];
                } break;
            } // switch DA operator
        } break;
            
        case DCM_TM: {
            switch (self.operator) {
                case NSLessThanOrEqualToPredicateOperatorType:
                case NSGreaterThanOrEqualToPredicateOperatorType:
                case NSEqualToPredicateOperatorType:
                    return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                              rightExpression:[NSExpression expressionForConstantValue:self.dateValue]
                                                                     modifier:NSDirectPredicateModifier
                                                                         type:self.operator
                                                                      options:0];
            }
        } break;
            
        case DCM_CS: {
            return [NSComparisonPredicate predicateWithLeftExpression:tagNameExpression
                                                      rightExpression:[NSExpression expressionForConstantValue:[self codeStringForTag:self.codeStringTag]]
                                                             modifier:NSDirectPredicateModifier
                                                                 type:NSContainsPredicateOperatorType //NSEqualToPredicateOperatorType
                                                              options:0];
        } break;
    }
    
    return [NSPredicate predicateWithValue:YES];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
    NSRect bounds = self.bounds;
    NSRect frame = NSZeroRect;
    static const CGFloat kSeparatorWidth = 5;
    
    frame.origin.x = 0;
    
    //    NSLog(@"sf");
    for (id view in self.subviews) {
        frame = NSMakeRect(frame.origin.x, 0, 0, 0);
        if ([view isKindOfClass:[NSPopUpButton class]] || [view isKindOfClass:[NSDatePicker class]]) {
            [view sizeToFit]; frame.size = NSMakeSize([view frame].size.width, bounds.size.height);
        } else if ([view isKindOfClass:[NSTextField class]] && ![view isEditable]) {
            frame.size = NSMakeSize([[view stringValue] sizeWithAttributes:[NSDictionary dictionaryWithObject:[view font] forKey:NSFontAttributeName]].width+4, bounds.size.height-3);
            frame.origin.y += 0;
        } else
            frame.size = NSMakeSize(150, bounds.size.height);
        
        //        NSLog(@"%@ %@ frame: %@", [view className], [view respondsToSelector:@selector(title)]? [view title] : nil, NSStringFromRect(frame));
        
        //        if (subview == self.subviews.lastObject)
        //            if (frame.origin.x+frame.wi)
        
        [view setFrame:frame];
        
        frame.origin.x += frame.size.width+kSeparatorWidth;
    }
}

/*- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    // [NSBezierPath strokeRect:self.bounds];
}*/

- (NSInteger)tagForCodeString:(NSString*)str {
    NSDictionary* dic = [O2DicomPredicateEditorCodeStrings codeStringsForTag:self.tag];
    if (!dic)
        return 0;
    
    NSInteger i = [dic.allKeys indexOfObject:str];
    
    if (i == NSNotFound) return dic.count+1;
    
    return i+1;
}

- (NSString*)codeStringForTag:(NSInteger)cst {
    NSDictionary* dic = [O2DicomPredicateEditorCodeStrings codeStringsForTag:self.tag];
    
    if (cst > 0 && dic.count >= cst)
        return [dic.allKeys objectAtIndex:cst-1];
    
    return [self stringValue];
}


@end


@implementation NSComparisonPredicate (OsiriX)

- (id)collection {
    if (self.leftExpression.expressionType == NSAggregateExpressionType) return self.leftExpression.collection;
    if (self.rightExpression.expressionType == NSAggregateExpressionType) return self.rightExpression.collection;
    return nil;
}

- (id)constantValue {
    if (self.leftExpression.expressionType == NSConstantValueExpressionType) return self.leftExpression.constantValue;
    if (self.rightExpression.expressionType == NSConstantValueExpressionType) return self.rightExpression.constantValue;
    return nil;
}

- (NSString *)function {
    if (self.leftExpression.expressionType == NSFunctionExpressionType) return self.leftExpression.function;
    if (self.rightExpression.expressionType == NSFunctionExpressionType) return self.rightExpression.function;
    return nil;
}

- (NSString *)keyPath {
    if (self.leftExpression.expressionType == NSKeyPathExpressionType) return self.leftExpression.keyPath;
    if (self.rightExpression.expressionType == NSKeyPathExpressionType) return self.rightExpression.keyPath;
    return nil;
}

- (NSString *)variable {
    if (self.leftExpression.expressionType == NSVariableExpressionType) return self.leftExpression.variable;
    if (self.rightExpression.expressionType == NSVariableExpressionType) return self.rightExpression.variable;
    return nil;
}

- (NSArray*)arguments {
    if (self.leftExpression.expressionType == NSFunctionExpressionType) return self.leftExpression.arguments;
    if (self.rightExpression.expressionType == NSFunctionExpressionType) return self.rightExpression.arguments;
    return nil;
}

@end

