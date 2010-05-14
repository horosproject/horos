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


/** \brief Window Controller for creating smart albums
*
* Window Controller for creating Smart albums
*/

#import <AppKit/AppKit.h>

@interface SmartWindowController : NSWindowController {
	
	IBOutlet	NSTextField		*albumNameField;
	IBOutlet	NSBox			*filterBox;
	NSMutableArray				*subviews;
	NSMutableArray				*criteria;
	BOOL						editSqlQuery;
	BOOL						firstTime;
	NSTimer						*sqlQueryTimer;
	NSString					*previousSqlString;
}

- (IBAction)editSqlString:(id) sender;
- (void)removeSubview:(id)sender; /**< Removes a subView representing a smart filter predicate. */
- (void)addSubview:(id)sender; /**< Add a subview for creating a new subpredicate. */
- (void)drawSubviews;  /**< Redraws the subviews */

- (void)updateRemoveButtons; /**< Disables the remove button if only one subview remains */

- (void)createCriteria; /**< Create the smart album criteria */
- (NSMutableArray *)criteria; /**< Array of subpredicates used to make the smart album predicate */
- (NSString *)albumTitle;  /**< Smart album title */
/** Return a date that corresponds to date earlier than today.
*  Value can be: searchWithinToday, searchWithinLast2Days, searchWithinLastWeek, searchWithinLast2Weeks,
*   searchWithinLastMonth, searchWithinLast2Months, searchWithinLast3Months, searchWithinLastYear
*/
- (NSCalendarDate *)dateBeforeNow:(int)value; 
//- (BOOL)madeCriteria;  /**< Checks to see if the criteria has been made. */
- (BOOL) editSqlQuery;
- (NSString*) sqlQueryString;

@end
